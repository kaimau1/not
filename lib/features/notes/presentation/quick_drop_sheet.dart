import 'dart:async';
import 'dart:convert';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/utils/calendar_day_command.dart';
import '../../../core/utils/firestore_size.dart' show sameFirestoreValue;
import '../../../core/utils/spoken_datetime.dart' show parseSpokenDateTime;
import '../../../core/widgets/delayed_spinner.dart';
import '../../../core/widgets/sheet_keyboard.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../../ai/data/ai_policy.dart';
import '../../ai/data/decisions/decision_flag.dart';
import '../../ai/data/decisions/decision_models.dart';
import '../../ai/data/decisions/decision_profiles.dart';
import '../../ai/data/decisions/decision_service.dart';
import '../../ai/presentation/ai_consent_sheet.dart';
import '../../calendar/data/calendar_repository.dart';
import '../../calendar/domain/day_key.dart';
import '../../settings/settings_providers.dart';
import '../data/notes_repository.dart';
import '../data/quick_entry_memory.dart';
import '../domain/note.dart';
import '../domain/note_item.dart';
import '../domain/note_type.dart';
import '../domain/quick_drop.dart';
import '../domain/quick_entry.dart';
import '../domain/smart_list.dart';
import 'note_link_ui.dart' show showNotePicker;
import 'quick_entry_bar.dart';

part 'quick_drop_parser.dart';

/// Son eklenen hedef notlar (en yenisi başta) — levha açılınca seçili gelir.
/// HE-5: saat dilimi + haftanın günü bazlı bağlam puanı da burada tutulur.
final quickDropRecentProvider =
    NotifierProvider<QuickDropRecentNotifier, List<String>>(
      QuickDropRecentNotifier.new,
    );

/// **HIZLI EKLE** (kullanıcı isteği 2026-11-15: "ekranda bir buton olur;
/// basınca hem yazma hem dinleme açılır, kişinin isteğine göre biri
/// kapatılabilir; yazarım, söylerim, şu nota ekle derim, o ekler").
///
/// Tek satır + mikrofon; altında hedef not çipleri. Hedef metinden de
/// çözülür ("market: süt", "… dosyalara ekle" — bkz. [parseDropTarget]);
/// çözülemezse seçili çip (son kullanılan not) geçerlidir.
///
/// 2026-11-16 (kullanıcı bulgusu: konuşma bitince hedefi söylemeden yanlış
/// nota ekliyordu): konuşma bitince HEMEN eklenmez — kısa geri sayım
/// ("“Notlar” notuna ekleniyor… Bekle"); bu arada çipe dokunmak hedefi
/// değiştirir. İki not başa baş kalırsa ya da "… ekle" dendiği hâlde ad
/// bulunamazsa önce yapay zekâya (yalnız başlıklar gider, kapatılabilir),
/// olmazsa kullanıcıya "Hangi nota eklensin?" diye sorulur.
class QuickDropSheet extends ConsumerStatefulWidget {
  const QuickDropSheet({super.key, this.initialText = ''});

  /// Alana yazılı gelen metin (HE-3: paylaşım, seçim menüsü, derin bağlantı).
  /// Elle yazılmış sayılır: kendiliğinden dinleme başlamaz (tanıyıcı ham
  /// kipte alanı baştan yazar, metin silinirdi).
  final String initialText;

  /// Bekleme süresi (hareket değil): komutsuz konuşma bitince tepki için
  /// iki saniye — kullanıcı hedefi söylememiş olabilir.
  static const countdown = Duration(seconds: 2);

  /// "… ekle" / "ad: içerik" gibi AÇIK komutla biten konuşmada (kullanıcı
  /// isteği 2026-11-26: "ekle dediğim zaman çok kısa bir beklemeden sonra
  /// direkt eklemeli"): önizleme satırı görünsün, Bekle'ye yetişilsin.
  static final commandCountdown = AppMotion.long + AppMotion.medium; // 720 ms

  @override
  ConsumerState<QuickDropSheet> createState() => _QuickDropSheetState();
}

/// Levhanın durumu: hedef not, eklenecek içerik, başa baş kalanlar,
/// "kullanıcıya sor" işareti, hatırlatıcı zamanı (HE-4) ve çoklu hedef (HE-5).
@immutable
class _Drop {
  const _Drop({
    this.id,
    this.content = '',
    this.ties = const [],
    this.ask = false,
    this.reminderAt,
    this.calendarDay,
    this.multi = const [],
  });

  final String? id;
  final String content;
  final List<String> ties;
  final bool ask;
  final DateTime? reminderAt;

  /// "… bugüne / 1 ocağa / bir hafta sonrasına ekle": yeni not bu güne bağlanır.
  final DateTime? calendarDay;
  final List<({String id, String content})> multi;

  @override
  bool operator ==(Object other) =>
      other is _Drop &&
      other.id == id &&
      other.content == content &&
      other.ask == ask &&
      other.reminderAt == reminderAt &&
      other.calendarDay == calendarDay &&
      listEquals(other.ties, ties) &&
      listEquals(other.multi, multi);

  @override
  int get hashCode => Object.hash(
    id,
    content,
    ask,
    reminderAt,
    calendarDay,
    Object.hashAll(ties),
    Object.hashAll(multi),
  );
}

enum _Phase { idle, counting, thinking }

/// "Yeni not" çipinin hedef kimliği (gerçek not kimliğiyle çakışmaz).
const _kNewId = '\u0000new';

class _QuickDropSheetState extends ConsumerState<QuickDropSheet>
    with SingleTickerProviderStateMixin {
  final _focus = FocusNode();
  final _bar = GlobalKey<QuickEntryBarState>();
  List<Note> _candidates = const [];
  ProviderSubscription<AsyncValue<List<Note>>>? _notesSub;
  late final QuickParser _idle = QuickParser(QuickLexicon());
  String _locale = PlatformDispatcher.instance.locale.languageCode;
  QuickLexicon? _groceryLex;
  String? _groceryLexLocale;

  /// Elle seçilen hedef (çipe dokunuldu); null = metinden/sondan.
  String? _chosenId;

  /// Son çözümleme (konuşma sonunda karar için).
  QuickDropTarget? _parsed;

  final _state = ValueNotifier<_Drop>(const _Drop());
  final _phase = ValueNotifier<_Phase>(_Phase.idle);

  /// Çip şeridinin girdisi: yalnız hedef + başa baş kalanlar (içerik YOK).
  /// Her tuş içeriği değiştirir; şerit (12 `ChoiceChip`) yalnız hedef
  /// değişince kurulur (S56 yazma bütçesi; kullanıcı bulgusu 2026-11-19
  /// "hızlı ekle açıkken klavye kasıyor").
  final _targets = ValueNotifier<_Drop>(const _Drop());
  final _strip = ScrollController();

  /// Ekle düğmesinin girdisi: etkin mi, "hangi not?" mu. İçerik düğmede
  /// YOK (HE-2: önizleme satırı gösterir) — düğme tuşta kurulmaz (S56).
  final _addLabel = ValueNotifier<(bool, bool)>((false, false));

  /// Önizleme satırının ayrıştırıcısı ve kurulduğu not (not akıştan yeni
  /// kopya gelince yeniden kurulur).
  QuickParser? _previewParser;
  Note? _previewNote;

  /// Konuşma sonrası geri sayım (bitince eklenir).
  late final AnimationController _count = AnimationController(
    vsync: this,
    duration: QuickDropSheet.countdown,
  )..addStatusListener(_onCountStatus);

  @override
  void initState() {
    super.initState();
    final boost = ref.read(quickDropRecentProvider.notifier).contextScores();
    _candidates = quickDropCandidates(
      ref.read(notesStreamProvider).value ?? const <Note>[],
      ref.read(quickDropRecentProvider),
      contextBoost: boost,
    );
    _state.addListener(_onState);
    _state.value = _Drop(id: _candidates.isEmpty ? null : _candidates.first.id);
    // Soğuk açılışta (kısayol/karo/widget) not akışı levhadan birkaç ms sonra
    // gelebilir (H4): aday listesi değiştiyse şeridi ve hedefi tazele.
    _notesSub = ref.listenManual(notesStreamProvider, (_, next) {
      final list = next.value;
      if (list == null || !mounted) return;
      final fresh = quickDropCandidates(
        list,
        ref.read(quickDropRecentProvider),
        contextBoost: ref
            .read(quickDropRecentProvider.notifier)
            .contextScores(),
      );
      final same =
          fresh.length == _candidates.length &&
          [
            for (var i = 0; i < fresh.length; i++)
              fresh[i].id == _candidates[i].id &&
                  fresh[i].displayTitle == _candidates[i].displayTitle,
          ].every((ok) => ok);
      if (same) return;
      final wasEmpty = _candidates.isEmpty;
      _candidates = fresh;
      if (wasEmpty != fresh.isEmpty) {
        setState(() {});
      }
      final current = _bar.currentState?.text ?? widget.initialText;
      if (current.isNotEmpty) {
        _resolve(current);
      } else {
        final nextId = _fallbackId;
        if (_state.value.id != nextId) {
          _state.value = _Drop(id: nextId);
        } else {
          _targets.value = _Drop(id: _state.value.id, ties: _state.value.ties);
        }
      }
    });
    if (widget.initialText.isNotEmpty) _resolve(widget.initialText);
    if (ref.read(quickDropKeyboardProvider)) focusAfterRouteOpens(this, _focus);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = context.l10n.localeName;
    if (next != _locale) {
      _locale = next;
      final current = _bar.currentState?.text ?? widget.initialText;
      if (current.isNotEmpty) _resolve(current);
    }
  }

  void _onState() {
    final st = _state.value;
    final targets = _Drop(id: st.id, ties: st.ties);
    if (targets != _targets.value) {
      _targets.value = targets;
      // Seçilen hedef şeridin BAŞINA geçer: kaydırılmış şerit başa döner
      // ki seçilen çip gözden kaybolmasın.
      if (_strip.hasClients && _strip.offset > 0) {
        unawaited(
          _strip.animateTo(0, duration: AppMotion.short, curve: AppMotion.enter),
        );
      }
    }
    final content = st.content.trim();
    final enabled =
        (st.id != null || _toNewNote || st.multi.isNotEmpty) &&
        content.isNotEmpty;
    final next = (enabled, st.id == null && st.ask);
    if (next != _addLabel.value) _addLabel.value = next;
  }

  /// HE-2/HE-4/HE-5 önizleme satırı: Ekle'ye basmadan neyin nereye gideceği ve
  /// eklenmeye hazır mı (vurgulu gösterim için).
  ({String text, bool ready}) _previewInfo(AppLocalizations l10n, _Drop st) {
    final content = st.content.trim();
    if (content.isEmpty) {
      return (text: _toNewNote ? '' : l10n.quickDropTarget, ready: false);
    }
    if (st.multi.isNotEmpty) {
      final summary = [
        for (final m in st.multi)
          '${_noteOf(m.id)?.displayTitle.trim() ?? ''} · ${m.content}',
      ].join(' + ');
      return (
        text: l10n.quickDropPreviewMulti(summary, st.multi.length),
        ready: true,
      );
    }
    if (st.calendarDay != null) {
      final day = DateFormat.MMMMEEEEd(
        l10n.localeName,
      ).format(st.calendarDay!);
      return (
        text: l10n.quickDropPreviewCalendar(day, content),
        ready: true,
      );
    }
    if (st.reminderAt != null) {
      final when = DateFormat.MMMd(
        l10n.localeName,
      ).add_Hm().format(st.reminderAt!);
      return (
        text: l10n.quickDropPreviewReminder(when, content),
        ready: true,
      );
    }
    if (_toNewNote) {
      return (
        text: l10n.quickDropPreviewText(l10n.newNoteShort, content),
        ready: true,
      );
    }
    final note = _noteOf(st.id);
    if (note == null) return (text: l10n.quickDropTarget, ready: false);
    final title = note.displayTitle.trim();
    final items = quickDropPreview(
      note,
      content,
      parser: () {
        if (!identical(_previewNote, note)) {
          _previewNote = note;
          _previewParser = quickDropListParser(
            note,
            locale: l10n.localeName,
            memory: ref.read(quickEntryMemoryProvider),
          );
        }
        return _previewParser!;
      },
    );
    if (items.isEmpty) {
      return (text: l10n.quickDropNothingNew(title), ready: false);
    }
    if (note.type == NoteType.text) {
      return (
        text: l10n.quickDropPreviewText(title, items.join(', ')),
        ready: true,
      );
    }
    return (
      text: l10n.quickDropPreviewItems(title, items.join(', '), items.length),
      ready: true,
    );
  }

  /// "Ben seçeyim" (HE-2): yapay zekâyı beklemeden kullanıcı çipten seçer.
  void _pickMyself() {
    if (_phase.value != _Phase.thinking) return;
    _phase.value = _Phase.idle;
    final st = _state.value;
    _state.value = _Drop(
      id: st.ties.isEmpty ? st.id : null,
      content: st.content,
      ties: st.ties,
      ask: true,
    );
  }

  @override
  void dispose() {
    _notesSub?.close();
    _count.dispose();
    _focus.dispose();
    _state.dispose();
    _targets.dispose();
    _strip.dispose();
    _addLabel.dispose();
    _phase.dispose();
    super.dispose();
  }

  /// Yazılan yeni metin notu olur (H11): uygun not yok ya da "Yeni not"
  /// çipi seçili.
  bool get _toNewNote => _candidates.isEmpty || _state.value.id == _kNewId;

  String? get _fallbackId =>
      _chosenId ?? (_candidates.isEmpty ? null : _candidates.first.id);

  Note? _firstGroceryNote() {
    for (final n in _candidates) {
      if (n.type != NoteType.text &&
          looksLikeGrocery(n.displayTitle, [
            for (final i in n.items) i.text,
          ], _locale)) {
        return n;
      }
    }
    return null;
  }

  static final _wordSplitRe = RegExp(r'[^a-z0-9]+');

  /// HE-4: varsayılan hedef market listesi değilse ve metinde ≥ 2 bilinen
  /// market ürünü varsa en güncel market listesini kendiliğinden önerir.
  String? _autoGroceryTarget(String content) {
    final fallback = _noteOf(_fallbackId);
    if (fallback != null &&
        fallback.type != NoteType.text &&
        looksLikeGrocery(fallback.displayTitle, [
          for (final i in fallback.items) i.text,
        ], _locale)) {
      return null;
    }
    final groceryNote = _firstGroceryNote();
    if (groceryNote == null) return null;
    final words = [
      for (final w in quickAscii(content).split(_wordSplitRe))
        if (w.length >= 2) w,
    ];
    if (words.length < 2) return null;
    if (_groceryLex == null || _groceryLexLocale != _locale) {
      _groceryLex = buildQuickLexicon(locale: _locale, grocery: true);
      _groceryLexLocale = _locale;
    }
    var hits = 0;
    final seen = <String>{};
    for (final w in words) {
      if (seen.add(w) && _groceryLex!.exact(w) != null) {
        if (++hits >= 2) return groceryNote.id;
      }
    }
    return null;
  }

  void _onText(String text) {
    _stopCountdown();
    _resolve(text);
  }

  void _resolve(String text) {
    // TAKVİM KOMUTU (kullanıcı isteği 2026-11-22): "… bugüne / yarına /
    // 1 ocağa / bir hafta sonrasına ekle" → yeni not o güne bağlanır. Elle
    // başka bir not seçildiyse komut aranmaz (kullanıcının seçimi geçerli).
    if (_chosenId == null || _chosenId == _kNewId) {
      final cmd = parseCalendarDayCommand(text, languageCode: _locale);
      if (cmd != null) {
        _parsed = (
          index: null,
          content: cmd.content,
          ties: const [],
          command: false,
        );
        final next = _Drop(
          id: _kNewId,
          content: cmd.content,
          calendarDay: cmd.day,
        );
        if (next != _state.value) _state.value = next;
        return;
      }
    }
    final titles = [for (final n in _candidates) n.displayTitle];
    // HE-5: tek cümlede birden çok açık hedef ("süt markete, fatura yapılacaklara").
    final multiRaw = parseMultiDropTargets(text, titles);
    if (multiRaw.isNotEmpty) {
      _parsed = (
        index: multiRaw.first.index,
        content: text.trim(),
        ties: const [],
        command: true,
      );
      final next = _Drop(
        id: _candidates[multiRaw.first.index].id,
        content: text.trim(),
        multi: [
          for (final m in multiRaw)
            (id: _candidates[m.index].id, content: m.content),
        ],
      );
      if (next != _state.value) _state.value = next;
      return;
    }
    final parsed = parseDropTarget(text, titles);
    _parsed = parsed;
    final ties = [for (final i in parsed.ties) _candidates[i].id];
    final _Drop next;
    if (parsed.index != null) {
      next = _Drop(id: _candidates[parsed.index!].id, content: parsed.content);
    } else if (ties.isNotEmpty) {
      // Başa baş: elle seçilen aralarındaysa o, değilse sorulur.
      final chosen = ties.contains(_chosenId) ? _chosenId : null;
      next = _Drop(
        id: chosen,
        content: parsed.content,
        ties: ties,
        ask: chosen == null,
      );
    } else if (_chosenId == null &&
        !dropNamesUnknownTarget(text) &&
        parsed.content.trim().isNotEmpty) {
      // HE-4 tek giriş: tarih/saat varsa hatırlatıcılı yeni not; birkaç
      // market maddesi varsa market listesi; değilse son hedef.
      final reminder = parseSpokenDateTime(
        parsed.content,
        languageCode: _locale,
      );
      if (reminder != null) {
        next = _Drop(
          id: _kNewId,
          content: parsed.content,
          reminderAt: reminder,
        );
      } else {
        final groceryId = _autoGroceryTarget(parsed.content);
        next = _Drop(id: groceryId ?? _fallbackId, content: parsed.content);
      }
    } else {
      next = _Drop(id: _fallbackId, content: parsed.content);
    }
    if (next != _state.value) _state.value = next;
  }

  void _choose(Note note) => _chooseId(note.id);

  /// Şeridin başındaki arama (HE-2): uygun notların hepsi, aramalı liste.
  Future<void> _findTarget() async {
    final note = await showNotePicker(
      context,
      notes: _candidates,
      title: context.l10n.quickDropWhich,
    );
    if (note != null && mounted) _choose(note);
  }

  void _chooseId(String id) {
    _stopCountdown();
    if (_phase.value == _Phase.thinking) _phase.value = _Phase.idle;
    _chosenId = id;
    _state.value = _Drop(id: id, content: _state.value.content);
  }

  // ── Konuşma bitti: geri sayım / yapay zekâ / sor ──────────────────────

  /// [now]: kullanıcı "bitti" dedi — hedef belliyse geri sayım yok.
  void _onSpeechEnd({bool now = false}) {
    final said = _bar.currentState?.text ?? '';
    _resolve(said);
    final st = _state.value;
    final parsed = _parsed;
    if (st.content.trim().isEmpty || parsed == null) return;
    // Açık komutla bitti ("… ekle", "yarına ekle", "ad: içerik"): kısa bekleme.
    final quick = parsed.command || endsWithAddCommand(said);
    if (_toNewNote) {
      now ? _apply(resolve: false) : _startCountdown(quick: quick);
      return;
    }
    // "… ekle" dendi ama ad çözülmedi ya da başa baş: kullanıcı bir not
    // adlandırdı ("… hatalar notuna ekle"), tahminle başka nota eklenmez.
    // Ad söylenmediyse ("süt ekle") seçili nota gider (2026-11-26).
    final named =
        st.ask ||
        (parsed.command &&
            parsed.index == null &&
            dropNamesUnknownTarget(said));
    if (named && _chosenId == null) {
      if (_aiUsable) {
        unawaited(_askAi());
        return;
      }
      if (st.ties.isEmpty) {
        // Yapay zekâ yok: son kullanılan not seçili kalır ama SORULUR.
        _state.value = _Drop(id: st.id, content: st.content, ask: true);
      }
      return;
    }
    if (st.id == null) return;
    if (now) {
      _apply(resolve: false);
    } else {
      _startCountdown(quick: quick);
    }
  }

  bool get _aiUsable {
    if (!ref.read(quickDropAiProvider) || ref.read(aiTurnedOffProvider)) {
      return false;
    }
    final decisions = ref.read(decisionServiceProvider);
    return decisions.mayHaveBackend &&
        (decisions.modeOf(DecisionFeature.dropTarget) == DecisionMode.live ||
            decisions.modeOf(DecisionFeature.captureRoute) ==
                DecisionMode.live);
  }

  Future<void> _askAi() async {
    final st = _state.value;
    final text = _bar.currentState?.text ?? '';
    if (!ref.read(aiConsentProvider)) {
      final accepted = await ensureAiConsent(context, ref);
      if (!mounted) return;
      if (!accepted) {
        _state.value = _Drop(
          id: st.ties.isEmpty ? st.id : null,
          content: st.content,
          ties: st.ties,
          ask: true,
        );
        return;
      }
    }
    final pool = st.ties.isNotEmpty
        ? [
            for (final n in _candidates)
              if (st.ties.contains(n.id)) n,
          ]
        : _candidates.take(40).toList();
    _phase.value = _Phase.thinking;
    // D2 (Decisions API): emin → uygula, orta → seçili gelir ama sorulur;
    // belirsizse ve bağ yokken D3 (captureRoute) niyet yönlendiricisi sorulur.
    final decisions = ref.read(decisionServiceProvider);
    if (decisions.modeOf(DecisionFeature.dropTarget) == DecisionMode.live &&
        pool.isNotEmpty) {
      final titles = [for (final n in pool) n.displayTitle];
      final d = await decideDropTarget(decisions, text, titles);
      if (!mounted || _phase.value != _Phase.thinking) return;
      final i = d?.index;
      if (d != null && i != null && d.outcome != DecisionOutcome.no) {
        _phase.value = _Phase.idle;
        final yes = d.outcome == DecisionOutcome.yes;
        _state.value = _Drop(
          id: pool[i].id,
          content: st.ties.isEmpty
              ? stripDropTargetWords(st.content, titles[i])
              : st.content,
          ask: !yes,
        );
        if (yes) _startCountdown(quick: true);
        return;
      }
    }
    if (st.ties.isEmpty &&
        decisions.modeOf(DecisionFeature.captureRoute) == DecisionMode.live) {
      final intent = await decideCaptureRoute(decisions, text);
      if (!mounted || _phase.value != _Phase.thinking) return;
      _phase.value = _Phase.idle;
      switch (intent) {
        case CaptureRouteIntent.shopping:
          final grocery = _firstGroceryNote();
          _state.value = _Drop(
            id: grocery?.id ?? _kNewId,
            content: st.content,
            ask: true,
          );
          return;
        case CaptureRouteIntent.todo:
        case CaptureRouteIntent.event:
          final reminder = parseSpokenDateTime(
            st.content,
            languageCode: _locale,
          );
          _state.value = _Drop(
            id: _kNewId,
            content: st.content,
            reminderAt: reminder,
            ask: true,
          );
          return;
        case CaptureRouteIntent.note:
          _state.value = _Drop(
            id: _kNewId,
            content: st.content,
            ask: true,
          );
          return;
        case CaptureRouteIntent.append:
        case CaptureRouteIntent.unknown:
          break;
      }
    } else {
      _phase.value = _Phase.idle;
    }
    _state.value = _Drop(
      id: st.ties.isEmpty ? st.id : null,
      content: st.content,
      ties: st.ties,
      ask: true,
    );
  }

  /// [quick]: açık komutla bitti ([commandCountdown]).
  void _startCountdown({bool quick = false}) {
    _phase.value = _Phase.counting;
    _count.duration = quick
        ? QuickDropSheet.commandCountdown
        : QuickDropSheet.countdown;
    unawaited(_count.forward(from: 0));
    _checkFixes();
  }

  /// DA-14: geri sayımın geri çevirdiği düzeltmeler (hedef|içerik için).
  ({String key, List<({String typed, String fixed})> fixes})? _vetoed;

  /// DA-14 (bayrak `spellFixOk`): bulanık yazım düzeltmeleri geri sayım
  /// İÇİNDE tek çağrıda doğrulanır; "yazım hatası değil" denenler bu
  /// eklemede uygulanmaz (yazılan kelime kalır). Yanıt geri sayımdan sonra
  /// gelirse yok sayılır (K2: görünen eklemeyi zıplatmaz).
  // ponytail: Enter/"bitti" ile anında eklemede doğrulama yok; geri sayım yeter.
  void _checkFixes() {
    _vetoed = null;
    final decisions = ref.read(decisionServiceProvider);
    final mode = decisions.modeOf(DecisionFeature.spellFixOk);
    final st = _state.value;
    final note = _noteOf(st.id);
    if (mode == DecisionMode.off || note == null || note.locked) return;
    final fixes = quickDropFixes(
      note,
      st.content,
      locale: context.l10n.localeName,
      memory: ref.read(quickEntryMemoryProvider),
    );
    if (fixes.isEmpty) return;
    final key = '${st.id}|${st.content}';
    unawaited(
      decideSpellFixes(decisions, fixes, [
        for (final i in note.items) i.text,
      ]).then((bad) {
        if (mode == DecisionMode.shadow) {
          DecisionService.logShadow(
            DecisionFeature.spellFixOk,
            'fixes=${fixes.length} veto=${bad?.length ?? '-'}',
          );
          return;
        }
        if (bad == null || bad.isEmpty || !mounted) return;
        _vetoed = (key: key, fixes: [for (final i in bad) fixes[i]]);
      }),
    );
  }

  void _stopCountdown() {
    if (_phase.value != _Phase.counting) return;
    _count.stop();
    _count.value = 0;
    _phase.value = _Phase.idle;
  }

  void _onCountStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed &&
        _phase.value == _Phase.counting &&
        mounted) {
      _phase.value = _Phase.idle;
      _apply(resolve: false);
    }
  }

  /// Notun GÜNCEL hâli (H10): aday listesi levha AÇILIRKEN alınmış kopyadır;
  /// levha açıkken not değiştiyse (başka cihaz, ortak kişi) eklemeyi o
  /// kopyaya yapıp alanın tamamını yazmak değişikliği siliyordu.
  Note? _noteOf(String? id) {
    if (id == null) return null;
    for (final n in ref.read(notesStreamProvider).value ?? const <Note>[]) {
      if (n.id == id) return n;
    }
    for (final n in _candidates) {
      if (n.id == id) return n;
    }
    return null;
  }

  /// [resolve]: metni yeniden çöz (Enter/Ekle); geri sayım ve yapay zekâ
  /// sonucunu ezmemek için onlarda false.
  void _apply({bool resolve = true}) {
    _stopCountdown();
    if (resolve) _resolve(_bar.currentState?.text ?? '');
    final st = _state.value;
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;
    // HE-5 çoklu hedef: her hedef not güncel hâlinden güncellenir, tek Geri Al.
    if (st.multi.isNotEmpty) {
      final l10n = context.l10n;
      final memory = ref.read(quickEntryMemoryProvider);
      final messenger = ScaffoldMessenger.of(context);
      final container = ProviderScope.containerOf(context, listen: false);
      final applied = <({Note before, Map<String, dynamic> written})>[];
      for (final m in st.multi) {
        final target = _noteOf(m.id);
        if (target == null) continue;
        final res = quickDropFields(
          target,
          m.content,
          locale: l10n.localeName,
          memory: memory,
        );
        if (res.fields.isEmpty) continue;
        repo.updateFields(target.id, res.fields);
        ref.read(quickDropRecentProvider.notifier).remember(target.id);
        applied.add((before: target, written: res.fields));
      }
      Navigator.of(context).pop();
      if (applied.isEmpty) return;
      void undoAll() {
        final live = container.read(notesStreamProvider).value ?? const <Note>[];
        for (final entry in applied) {
          Note? current;
          for (final n in live) {
            if (n.id == entry.before.id) current = n;
          }
          final fields = quickDropUndoFields(
            before: entry.before,
            current: current ?? entry.before,
            written: entry.written,
          );
          if (fields.isNotEmpty) repo.updateFields(entry.before.id, fields);
        }
      }

      messenger
        ..hideCurrentSnackBar()
        ..showMessage(
          l10n.quickDropAddedMulti(applied.length),
          action: SnackBarAction(label: l10n.undo, onPressed: undoAll),
        );
      return;
    }
    final calendarDay = st.calendarDay;
    final calendar = ref.read(calendarRepositoryProvider);
    if (calendarDay != null && calendar != null && st.content.trim().isNotEmpty) {
      final body = st.content.trim();
      final messenger = ScaffoldMessenger.of(context);
      final l10n = context.l10n;
      final key = dayKey(calendarDay);
      unawaited(
        repo.createNote(NoteType.text, body: body).then((id) {
          calendar.linkNoteToDay(key, id);
          ref.read(quickDropRecentProvider.notifier).remember(id);
        }),
      );
      Navigator.of(context).pop();
      messenger
        ..hideCurrentSnackBar()
        ..showMessage(
          l10n.quickDropSavedCalendar(
            DateFormat.MMMMd(l10n.localeName).format(calendarDay),
          ),
        );
      return;
    }
    if (_toNewNote && st.content.trim().isNotEmpty) {
      final body = st.content.trim();
      final reminderAt = st.reminderAt;
      final messenger = ScaffoldMessenger.of(context);
      final l10n = context.l10n;
      unawaited(
        repo
            .createNote(NoteType.text, body: body, reminderAt: reminderAt)
            .then((id) {
              ref.read(quickDropRecentProvider.notifier).remember(id);
            }),
      );
      Navigator.of(context).pop();
      messenger
        ..hideCurrentSnackBar()
        ..showMessage(
          reminderAt != null
              ? l10n.quickDropSavedReminder
              : l10n.quickDropSavedNew,
        );
      return;
    }
    final note = _noteOf(st.id);
    if (note == null || st.content.trim().isEmpty) return;
    final content = st.content;
    final l10n = context.l10n;
    final veto = _vetoed;
    final memory = quickDropVetoed(
      ref.read(quickEntryMemoryProvider),
      veto != null && veto.key == '${st.id}|$content' ? veto.fixes : const [],
    );
    final result = quickDropFields(
      note,
      content,
      locale: l10n.localeName,
      memory: memory,
    );
    final title = note.displayTitle.trim();
    final messenger = ScaffoldMessenger.of(context);
    if (result.fields.isNotEmpty) {
      repo.updateFields(note.id, result.fields);
      ref.read(quickDropRecentProvider.notifier).remember(note.id);
    }
    final container = ProviderScope.containerOf(context, listen: false);
    Navigator.of(context).pop();
    if (result.fields.isEmpty) {
      messenger.showMessage(l10n.quickDropNothingNew(title));
      return;
    }
    // Geri al: yalnız bu eklemenin dokunduğu şey (H10); not GÜNCEL hâlinden.
    void undo() {
      Note? current;
      for (final n
          in container.read(notesStreamProvider).value ?? const <Note>[]) {
        if (n.id == note.id) current = n;
      }
      final fields = quickDropUndoFields(
        before: note,
        current: current ?? note,
        written: result.fields,
      );
      if (fields.isNotEmpty) repo.updateFields(note.id, fields);
    }

    messenger
      ..hideCurrentSnackBar()
      ..showMessage(
        note.type == NoteType.text && result.added <= 1
            ? l10n.quickDropAddedText(title)
            : l10n.quickDropAdded(result.added, title),
        action: SnackBarAction(
          label: l10n.undo,
          onPressed: undo,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = AppText.of(theme);
    final autoMic = ref.watch(quickDropMicProvider);
    final keyboard = ref.watch(quickDropKeyboardProvider);
    final ai = ref.watch(quickDropAiProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.l, 0, AppSpace.l, AppSpace.l),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(l10n.quickDropTitle, style: text.sheetTitle),
              ),
              // HE-2 (17K §4.2): üç anahtar (yapay zekâ / klavye / dinle)
              // başlıkta yer kaplamasın — ⚙ arkasında, işaretli menü.
              PopupMenuButton<NotifierProvider<BoolPrefNotifier, bool>>(
                key: const ValueKey('quick-drop-settings'),
                tooltip: l10n.quickDropSettings,
                icon: const Icon(Icons.settings_outlined),
                onSelected: (p) {
                  final next = !ref.read(p);
                  ref.read(p.notifier).toggle();
                  if (p == quickDropKeyboardProvider) {
                    if (next) {
                      _focus.requestFocus();
                    } else {
                      _focus.unfocus();
                    }
                  } else if (p == quickDropMicProvider) {
                    if (next) {
                      _stopCountdown();
                      unawaited(_bar.currentState?.startListening());
                    } else {
                      unawaited(_bar.currentState?.stopListening());
                    }
                  }
                },
                itemBuilder: (_) => [
                  CheckedPopupMenuItem(
                    key: const ValueKey('quick-drop-ai'),
                    value: quickDropAiProvider,
                    checked: ai,
                    child: Text(l10n.quickDropAiToggle),
                  ),
                  CheckedPopupMenuItem(
                    key: const ValueKey('quick-drop-keyboard'),
                    value: quickDropKeyboardProvider,
                    checked: keyboard,
                    child: Text(l10n.quickDropKeyboard),
                  ),
                  CheckedPopupMenuItem(
                    key: const ValueKey('quick-drop-auto-mic'),
                    value: quickDropMicProvider,
                    checked: autoMic,
                    child: Text(l10n.quickDropMicAuto),
                  ),
                ],
              ),
            ],
          ),
          // H11 (17K §4.1): uygun not yokken levha ÇIKMAZ SOKAKTI — yalnız
          // "önce not oluştur" yazıyor, yazma alanı hiç gelmiyordu. Artık
          // alan durur; yazılan YENİ NOT olarak kaydedilir.
          if (_candidates.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.s),
              child: Text(
                l10n.quickDropNoNotesNew,
                key: const ValueKey('quick-drop-no-notes'),
                style: text.meta.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          ...[
            QuickEntryBar(
              key: _bar,
              parser: _idle,
              raw: true,
              initialText: widget.initialText,
              focusNode: _focus,
              hint: l10n.quickDropHint,
              autoListen: autoMic,
              // Levha açılışı (+ klavye) bitince: tanıyıcı animasyonlarla
              // aynı karelerde açılmasın (S56, 2026-11-19).
              autoListenDelay: keyboard
                  ? AppMotion.medium + AppMotion.long
                  : AppMotion.medium,
              onListeningChanged: (on) {
                if (on) _stopCountdown();
              },
              onRawChanged: _onText,
              onRawSubmitted: (_) => _apply(),
              // "Söyle, eklensin": konuşma bitince kısa geri sayımla eklenir.
              onSpeechEnd: _onSpeechEnd,
              // "… bitti" dendi: geri sayım beklemeden hemen eklenir.
              onDoneWord: () => _onSpeechEnd(now: true),
              // "… ekle" + kısa sessizlik: çok kısa geri sayımla eklenir.
              onAddWord: _onSpeechEnd,
              onItems: (_) {},
            ),
            // DURUM SATIRI, boyu SABİT (levha zıplamasın): nereye / hangi
            // not? / soruyorum / ekleniyor + Bekle.
            SizedBox(
              height: AppSpace.xxl,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: ListenableBuilder(
                  listenable: Listenable.merge([_state, _phase]),
                  builder: (context, _) {
                    final st = _state.value;
                    switch (_phase.value) {
                      case _Phase.thinking:
                        // HE-2: hızlı yanıtta hiçbir şey yanıp sönmez; 300 ms
                        // sonra ince ilerleme + "Ben seçeyim" belirir.
                        return DelayedSpinner(
                          child: Row(
                            key: const ValueKey('quick-drop-thinking'),
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.quickDropAsking,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: text.meta,
                                    ),
                                    const SizedBox(height: AppSpace.xs),
                                    const LinearProgressIndicator(minHeight: 2),
                                  ],
                                ),
                              ),
                              TextButton(
                                key: const ValueKey('quick-drop-pick-myself'),
                                onPressed: _pickMyself,
                                child: Text(l10n.quickDropPickMyself),
                              ),
                            ],
                          ),
                        );
                      case _Phase.counting:
                        final title = _noteOf(st.id)?.displayTitle.trim() ?? '';
                        final label = _toNewNote
                            ? l10n.quickDropSavingNew
                            : l10n.quickDropAddingTo(title);
                        return Row(
                          key: const ValueKey('quick-drop-counting'),
                          children: [
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: text.meta.copyWith(
                                      color: scheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpace.xs),
                                  AnimatedBuilder(
                                    animation: _count,
                                    builder: (context, _) =>
                                        LinearProgressIndicator(
                                          value: _count.value,
                                          minHeight: 2,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              key: const ValueKey('quick-drop-wait'),
                              onPressed: _stopCountdown,
                              child: Text(l10n.quickDropWait),
                            ),
                          ],
                        );
                      case _Phase.idle:
                        if (st.ask) {
                          return Text(
                            l10n.quickDropWhich,
                            key: const ValueKey('quick-drop-ask'),
                            style: text.meta.copyWith(
                              color: scheme.primary,
                              fontWeight: AppWeight.strong,
                            ),
                          );
                        }
                        final preview = _previewInfo(l10n, st);
                        // HE-2 önizleme: tuşta yalnız bu Text kurulur.
                        return Text(
                          preview.text,
                          key: const ValueKey('quick-drop-preview'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: preview.ready
                              ? text.meta.copyWith(
                                  color: scheme.primary,
                                  fontWeight: AppWeight.medium,
                                )
                              : text.meta,
                        );
                    }
                  },
                ),
              ),
            ),
            SizedBox(
              height: AppSpace.xxxl + AppSpace.m,
              child: ValueListenableBuilder<_Drop>(
                valueListenable: _targets,
                builder: (context, st, _) {
                  // Seçili hedef hep başta, sonra başa baş kalanlar.
                  final first = [
                    ?_noteOf(st.id),
                    for (final id in st.ties)
                      if (id != st.id) ?_noteOf(id),
                  ];
                  // HE-2: 12 sınırı kalktı — şerit tembel (yalnız görünen
                  // çipler kurulur), uzak not için baştaki arama.
                  final shown = [
                    ...first,
                    for (final n in _candidates)
                      if (!first.contains(n)) n,
                  ];
                  // H11 2. yarı (2026-11-19): "Yeni not" HEP en başta —
                  // yazılan hiçbir nota uymuyorsa tek dokunuşla yeni not.
                  // Uygun not yoksa zaten yeni not olur, çip gereksiz; arama
                  // da (aranacak not yok).
                  final extra = _candidates.isEmpty ? 0 : 2;
                  return ListView.separated(
                    key: const ValueKey('quick-drop-targets'),
                    controller: _strip,
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.zero,
                    itemCount: shown.length + extra,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: AppSpace.s),
                    itemBuilder: (context, i) {
                      if (i == 0 && extra > 0) {
                        return Center(
                          child: ActionChip(
                            key: const ValueKey('quick-drop-search'),
                            avatar: const Icon(
                              Icons.search,
                              size: AppIconSize.xs,
                            ),
                            label: Text(l10n.quickDropFindNote),
                            onPressed: _findTarget,
                          ),
                        );
                      }
                      if (i < extra) {
                        return Center(
                          child: ChoiceChip(
                            key: const ValueKey('quick-drop-target-new'),
                            avatar: const Icon(
                              Icons.add,
                              size: AppIconSize.xs,
                            ),
                            label: Text(l10n.newNoteShort),
                            showCheckmark: false,
                            selected: st.id == _kNewId,
                            onSelected: (_) => _chooseId(_kNewId),
                          ),
                        );
                      }
                      final n = shown[i - extra];
                      final tie = st.ties.contains(n.id);
                      return Center(
                        child: ChoiceChip(
                          key: ValueKey('quick-drop-target-${n.id}'),
                          avatar: Icon(
                            n.type == NoteType.text
                                ? Icons.notes
                                : Icons.check_box_outlined,
                            size: AppIconSize.xs,
                          ),
                          label: Text(
                            n.displayTitle.trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          side: tie && n.id != st.id
                              ? BorderSide(color: scheme.primary)
                              : null,
                          showCheckmark: false,
                          selected: n.id == st.id,
                          onSelected: (_) => _choose(n),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpace.s),
            ValueListenableBuilder<(bool, bool)>(
              valueListenable: _addLabel,
              builder: (context, add, _) => FilledButton.icon(
                key: const ValueKey('quick-drop-add'),
                onPressed: add.$1
                    ? () => _apply(resolve: !_state.value.ask)
                    : null,
                icon: const Icon(Icons.add),
                label: Text(
                  add.$2 ? l10n.quickDropWhich : l10n.quickDropAdd,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
