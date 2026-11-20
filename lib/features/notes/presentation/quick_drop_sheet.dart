import 'dart:async';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/utils/firestore_size.dart' show sameFirestoreValue;
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/delayed_spinner.dart';
import '../../../core/widgets/sheet_keyboard.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../../ai/data/ai_gate.dart';
import '../../ai/data/decisions/decision_flag.dart';
import '../../ai/data/decisions/decision_models.dart';
import '../../ai/data/decisions/decision_profiles.dart';
import '../../ai/data/decisions/decision_service.dart';
import '../../ai/data/gemini_service.dart';
import '../../settings/settings_providers.dart';
import '../data/notes_repository.dart';
import '../data/quick_entry_memory.dart';
import '../domain/note.dart';
import '../domain/note_item.dart';
import '../domain/note_type.dart';
import '../domain/quick_drop.dart';
import '../domain/quick_entry.dart';
import 'note_link_ui.dart' show showNotePicker;
import 'quick_entry_bar.dart';

/// Son eklenen hedef notlar (en yenisi başta) — levha açılınca seçili gelir.
final quickDropRecentProvider =
    NotifierProvider<QuickDropRecentNotifier, List<String>>(
      QuickDropRecentNotifier.new,
    );

class QuickDropRecentNotifier extends Notifier<List<String>> {
  static const _key = 'quick_drop_recent';
  static const maxEntries = 6;

  @override
  List<String> build() =>
      ref.watch(sharedPreferencesProvider).getStringList(_key) ?? const [];

  void remember(String noteId) {
    final next = [
      noteId,
      for (final id in state)
        if (id != noteId) id,
    ].take(maxEntries).toList();
    state = next;
    ref.read(sharedPreferencesProvider).setStringList(_key, next);
  }
}

/// Eklenebilecek notlar: yazı ve liste notları (çöpte/arşivde/kilitli
/// olmayan; sayfalı yazı notu hariç — sayfa seçimi ister). Sıra: son
/// kullanılan hedefler, sonra iğneliler, sonra en son değişenler.
List<Note> quickDropCandidates(Iterable<Note> notes, List<String> recent) {
  final ok = [
    for (final n in notes)
      if (n.deletedAt == null &&
          n.archivedAt == null &&
          !n.locked &&
          (n.type == NoteType.checklist ||
              n.type == NoteType.ordered ||
              (n.type == NoteType.text && !n.paged && n.textPages.isEmpty)) &&
          n.displayTitle.trim().isNotEmpty)
        n,
  ];
  int rank(Note n) {
    final r = recent.indexOf(n.id);
    if (r >= 0) return r;
    return n.pinned ? 100 : 200;
  }

  DateTime at(Note n) =>
      n.updatedAt ?? n.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
  ok.sort((a, b) {
    final c = rank(a).compareTo(rank(b));
    return c != 0 ? c : at(b).compareTo(at(a));
  });
  return ok;
}

/// [note]a [content] eklenince yazılacak alanlar ve bildirim sayısı.
/// Liste notunda içerik maddelere ayrılır (alışveriş listesinde kelime
/// kelime, cümleli listede yalnız virgülle); yazı notunda sona satır eklenir.
/// Eklenecek bir şey yoksa `fields` boştur.
({Map<String, dynamic> fields, int added}) quickDropFields(
  Note note,
  String content, {
  required String locale,
  QuickEntryMemory memory = const QuickEntryMemory(),
  String Function()? newId,
}) {
  // Art arda söylenenler ("süt al bir de faturayı öde") ayrı madde/satır.
  final text = quickDropSeparate(content.trim());
  if (text.isEmpty) return (fields: const {}, added: 0);
  if (note.type == NoteType.text) {
    final lines = [
      for (final l in text.split(', '))
        if (l.trim().isNotEmpty) l.trim(),
    ];
    final joined = text.contains(', ') && lines.length > 1
        ? lines.join('\n')
        : content.trim();
    final body = note.body.trimRight();
    return (
      fields: {'body': body.isEmpty ? joined : '$body\n$joined'},
      added: joined.split('\n').length,
    );
  }
  final parsed = _parseIntoList(note, text, locale, memory);
  final plan = planDropIntoList([
    for (final i in note.items) (text: i.text, checked: i.checked),
  ], parsed.items);
  final added =
      plan.texts.length + plan.uncheck.length + plan.requantify.length;
  if (added == 0) return (fields: const {}, added: 0);
  final id = newId ?? () => const Uuid().v4();
  final items = <NoteItem>[
    for (var i = 0; i < note.items.length; i++)
      // Boş yer tutucu satır (yeni listenin tek boş maddesi) atılır.
      if (note.items[i].text.trim().isNotEmpty || note.items.length > 1)
        note.items[i].copyWith(
          text: plan.requantify[i],
          checked: plan.uncheck.contains(i) ? false : null,
        ),
    for (final t in plan.texts) NoteItem(id: id(), text: t),
  ];
  return (
    fields: {
      'items': [for (final i in items) i.toMap()],
    },
    added: added,
  );
}

QuickParse _parseIntoList(
  Note note,
  String text,
  String locale,
  QuickEntryMemory memory,
) => quickDropListParser(
  note,
  locale: locale,
  memory: memory,
).parse(text, flush: true);

/// Liste notuna eklemenin ayrıştırıcısı (alışverişe benziyorsa market
/// sözlüğü + notun kendi maddeleri + hızlı ekle hafızası). Kurulumu pahalı
/// (~2200 kelimelik sözlük): önizleme satırı hedef başına BİR kez kurar.
QuickParser quickDropListParser(
  Note note, {
  required String locale,
  QuickEntryMemory memory = const QuickEntryMemory(),
}) {
  final grocery = looksLikeGrocery(note.displayTitle, [
    for (final i in note.items) i.text,
  ], locale);
  final lex = buildQuickLexicon(
    locale: locale,
    grocery: grocery,
    learned: memory.all('drop'),
    extra: [
      for (final i in note.items)
        if (i.text.trim().isNotEmpty) quickBaseName(i.text),
    ],
  );
  return buildQuickParser(lex, memory: memory, phrasesOnly: !grocery);
}

/// HE-2 önizleme satırı (17K §4.2, "→ Market listesi · süt, ekmek (2
/// madde)"): [content] [note]a eklenince NOTA GİRECEKLER — liste notunda
/// yeni, yeniden açılan ve miktarı değişen maddeler; yazı notunda eklenecek
/// satırlar. Hiçbir şey yazmaz; [quickDropFields] ile aynı ayrıştırma.
/// Boş = eklenecek yeni bir şey yok (hepsi zaten notta).
List<String> quickDropPreview(
  Note note,
  String content, {
  required QuickParser Function() parser,
}) {
  final text = quickDropSeparate(content.trim());
  if (text.isEmpty) return const [];
  if (note.type == NoteType.text) {
    final lines = [
      for (final l in text.split(', '))
        if (l.trim().isNotEmpty) l.trim(),
    ];
    return lines.length > 1 ? lines : [content.trim()];
  }
  final plan = planDropIntoList([
    for (final i in note.items) (text: i.text, checked: i.checked),
  ], parser().parse(text, flush: true).items);
  return [
    ...plan.texts,
    for (final i in plan.uncheck) plan.requantify[i] ?? note.items[i].text,
    for (final e in plan.requantify.entries)
      if (!plan.uncheck.contains(e.key)) e.value,
  ];
}

/// DA-14: [content] liste notuna eklenince yapılacak BULANIK yazım
/// düzeltmeleri (yazılan → düzeltilen). Tam eşleşme, harf düzleştirme ve
/// öğretilmiş düzeltme dahil değil (yalnız [QuickHow.fuzzy]).
List<({String typed, String fixed})> quickDropFixes(
  Note note,
  String content, {
  required String locale,
  QuickEntryMemory memory = const QuickEntryMemory(),
}) {
  if (note.type == NoteType.text) return const [];
  final text = quickDropSeparate(content.trim());
  if (text.isEmpty) return const [];
  return [
    for (final i in _parseIntoList(note, text, locale, memory).items)
      if (i.corrected && i.typed.isNotEmpty) (typed: i.typed, fixed: i.name),
  ];
}

/// [memory] + Decisions'ın geri çevirdiği düzeltmeler (yalnız bu ekleme;
/// kalıcı hafızaya YAZILMAZ — K5).
QuickEntryMemory quickDropVetoed(
  QuickEntryMemory memory,
  Iterable<({String typed, String fixed})> vetoed,
) => vetoed.isEmpty
    ? memory
    : QuickEntryMemory(
        kinds: memory.kinds,
        rejected: {
          ...memory.rejected,
          for (final v in vetoed) '${quickAscii(v.typed)}>${quickAscii(v.fixed)}',
        },
      );

/// Hızlı eklemenin GERİ ALINMASI (H10, 2026-11-17): eski kopyayı körlemesine
/// geri yazmak, ekleme ile geri al arasında nota yapılan değişikliği (başka
/// cihaz, ortak kişi, editör) siliyordu. Yalnız bu eklemenin dokunduğu şey
/// geri alınır: eklenen maddeler çıkar; değiştirdiği madde HÂLÂ yazdığı
/// hâldeyse eskisine döner. Yazı notunda eklenen son satırlar, gövde hâlâ
/// yazılanla başlıyorsa çıkarılır. Geri alınacak bir şey kalmadıysa boş.
Map<String, dynamic> quickDropUndoFields({
  required Note before,
  required Note current,
  required Map<String, dynamic> written,
}) {
  if (before.type == NoteType.text) {
    final w = written['body'];
    if (w is! String) return const {};
    final now = current.body;
    if (!now.startsWith(w)) return const {};
    return {'body': before.body + now.substring(w.length)};
  }
  final raw = written['items'];
  if (raw is! List) return const {};
  final wrote = {
    for (final m in raw)
      if (m is Map) (m['id'] as String?) ?? '': Map<String, dynamic>.from(m),
  };
  final old = {for (final i in before.items) i.id: i};
  var changed = false;
  final items = <NoteItem>[];
  for (final i in current.items) {
    final w = wrote[i.id];
    if (!old.containsKey(i.id)) {
      // Bu eklemenin maddesi (kimliği eskide yok) → çıkar.
      if (w != null) {
        changed = true;
        continue;
      }
      items.add(i);
      continue;
    }
    final o = old[i.id]!;
    if (w != null &&
        !sameFirestoreValue(o.toMap(), w) &&
        sameFirestoreValue(i.toMap(), w)) {
      changed = true;
      items.add(o);
    } else {
      items.add(i);
    }
  }
  if (!changed) return const {};
  return {
    'items': [for (final i in items) i.toMap()],
  };
}

/// **HIZLI EKLE** levhasını açar.
Future<void> showQuickDropSheet(BuildContext context) => showAppSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  constraints: const BoxConstraints(maxWidth: 640),
  builder: (_) => const SheetInsetPadding(child: QuickDropSheet()),
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
  const QuickDropSheet({super.key});

  @override
  ConsumerState<QuickDropSheet> createState() => _QuickDropSheetState();
}

/// Levhanın durumu: hedef not, eklenecek içerik, başa baş kalanlar ve
/// "kullanıcıya sor" işareti.
@immutable
class _Drop {
  const _Drop({
    this.id,
    this.content = '',
    this.ties = const [],
    this.ask = false,
  });

  final String? id;
  final String content;
  final List<String> ties;
  final bool ask;

  @override
  bool operator ==(Object other) =>
      other is _Drop &&
      other.id == id &&
      other.content == content &&
      other.ask == ask &&
      listEquals(other.ties, ties);

  @override
  int get hashCode => Object.hash(id, content, ask, Object.hashAll(ties));
}

enum _Phase { idle, counting, thinking }

/// "Yeni not" çipinin hedef kimliği (gerçek not kimliğiyle çakışmaz).
const _kNewId = '\u0000new';

class _QuickDropSheetState extends ConsumerState<QuickDropSheet>
    with SingleTickerProviderStateMixin {
  final _focus = FocusNode();
  final _bar = GlobalKey<QuickEntryBarState>();
  late final List<Note> _candidates;
  late final QuickParser _idle = QuickParser(QuickLexicon());

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
    // Bekleme süresi (hareket değil): tepki için iki saniye.
    duration: const Duration(seconds: 2),
  )..addStatusListener(_onCountStatus);

  @override
  void initState() {
    super.initState();
    _candidates = quickDropCandidates(
      ref.read(notesStreamProvider).value ?? const <Note>[],
      ref.read(quickDropRecentProvider),
    );
    _state.addListener(_onState);
    _state.value = _Drop(id: _candidates.isEmpty ? null : _candidates.first.id);
    if (ref.read(quickDropKeyboardProvider)) focusAfterRouteOpens(this, _focus);
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
    final enabled = (st.id != null || _toNewNote) && content.isNotEmpty;
    final next = (enabled, st.id == null && st.ask);
    if (next != _addLabel.value) _addLabel.value = next;
  }

  /// HE-2 önizleme satırı: Ekle'ye basmadan neyin nereye gideceği.
  String _previewLine(AppLocalizations l10n, _Drop st) {
    final content = st.content.trim();
    if (content.isEmpty) return _toNewNote ? '' : l10n.quickDropTarget;
    if (_toNewNote) return l10n.quickDropPreviewText(l10n.newNoteShort, content);
    final note = _noteOf(st.id);
    if (note == null) return l10n.quickDropTarget;
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
    if (items.isEmpty) return l10n.quickDropNothingNew(title);
    if (note.type == NoteType.text) {
      return l10n.quickDropPreviewText(title, items.join(', '));
    }
    return l10n.quickDropPreviewItems(title, items.join(', '), items.length);
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

  void _onText(String text) {
    _stopCountdown();
    _resolve(text);
  }

  void _resolve(String text) {
    final parsed = parseDropTarget(text, [
      for (final n in _candidates) n.displayTitle,
    ]);
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
    _resolve(_bar.currentState?.text ?? '');
    final st = _state.value;
    final parsed = _parsed;
    if (st.content.trim().isEmpty || parsed == null) return;
    if (_toNewNote) {
      now ? _apply(resolve: false) : _startCountdown();
      return;
    }
    // "… ekle" dendi ama ad çözülmedi ya da başa baş: kullanıcı bir not
    // adlandırdı, tahminle başka nota eklenmez.
    final named = st.ask || (parsed.command && parsed.index == null);
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
      _startCountdown();
    }
  }

  bool get _aiUsable =>
      ref.read(quickDropAiProvider) &&
      ref.read(aiAvailabilityProvider) == AiAvailability.ready;

  Future<void> _askAi() async {
    final st = _state.value;
    final text = _bar.currentState?.text ?? '';
    final pool = st.ties.isNotEmpty
        ? [
            for (final n in _candidates)
              if (st.ties.contains(n.id)) n,
          ]
        : _candidates.take(40).toList();
    _phase.value = _Phase.thinking;
    // DA-1 (plan_decisions_api): Decisions `choice` önce (bayrak açıksa);
    // emin → uygula, orta → seçili gelir ama sorulur, değilse eski yol.
    // Gölge kipte eski yol AYNEN, karar yalnız günlüğe.
    final decisions = ref.read(decisionServiceProvider);
    final mode = decisions.modeOf(DecisionFeature.dropTarget);
    final titles = [for (final n in pool) n.displayTitle];
    final decided = mode == DecisionMode.off
        ? null
        : decideDropTarget(decisions, text, titles);
    if (mode == DecisionMode.live) {
      final d = await decided;
      if (!mounted || _phase.value != _Phase.thinking) return;
      final i = d?.index;
      if (d != null && i != null && d.outcome != DecisionOutcome.no) {
        final yes = d.outcome == DecisionOutcome.yes;
        _phase.value = _Phase.idle;
        _state.value = _Drop(
          id: pool[i].id,
          // Başa başta ad zaten ayıklandı; yalnız "ad çözülmedi"de sondaki
          // adı çıkar.
          content: st.ties.isEmpty
              ? stripDropTargetWords(st.content, titles[i])
              : st.content,
          ask: !yes,
        );
        if (yes) _startCountdown();
        return;
      }
    }
    ({int index, String content})? hit;
    try {
      hit = await ref
          .read(geminiServiceProvider)
          .pickDropTarget(text, [for (final n in pool) n.displayTitle])
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      hit = null;
    }
    if (mode == DecisionMode.shadow) {
      final old = hit?.index;
      unawaited(
        decided!.then(
          (d) => DecisionService.logShadow(
            DecisionFeature.dropTarget,
            'old=${old ?? '-'} new=${d?.index ?? '-'} '
            '${d?.outcome.name ?? 'none'} agree=${d?.index == old}',
          ),
        ),
      );
    }
    // Kullanıcı bu arada çipe dokunduysa ya da yazdıysa karar onun.
    if (!mounted || _phase.value != _Phase.thinking) return;
    _phase.value = _Phase.idle;
    if (hit == null) {
      _state.value = _Drop(
        id: st.ties.isEmpty ? st.id : null,
        content: st.content,
        ties: st.ties,
        ask: true,
      );
      return;
    }
    final note = pool[hit.index];
    _state.value = _Drop(
      id: note.id,
      content: _trustedContent(hit.content, text) ?? st.content,
    );
    _startCountdown();
  }

  /// Yapay zekânın içeriği ancak kullanıcının söylediği kelimelerden
  /// oluşuyorsa kullanılır (uydurma/yeniden yazma eklenmesin).
  static String? _trustedContent(String ai, String said) {
    final words = quickAscii(said).split(RegExp(r'[^a-z0-9]+')).toSet();
    final got = [
      for (final w in quickAscii(ai).split(RegExp(r'[^a-z0-9]+')))
        if (w.isNotEmpty) w,
    ];
    if (got.isEmpty || !got.every(words.contains)) return null;
    return ai.trim();
  }

  void _startCountdown() {
    _phase.value = _Phase.counting;
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
    final note = _noteOf(st.id);
    final repo = ref.read(notesRepositoryProvider);
    if (_toNewNote && repo != null && st.content.trim().isNotEmpty) {
      final body = st.content.trim();
      final messenger = ScaffoldMessenger.of(context);
      final l10n = context.l10n;
      unawaited(
        repo.createNote(NoteType.text, body: body).then((id) {
          ref.read(quickDropRecentProvider.notifier).remember(id);
        }),
      );
      Navigator.of(context).pop();
      messenger
        ..hideCurrentSnackBar()
        ..showMessage(l10n.quickDropSavedNew);
      return;
    }
    if (note == null || repo == null || st.content.trim().isEmpty) return;
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
                onSelected: (p) => ref.read(p.notifier).toggle(),
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
              focusNode: _focus,
              hint: l10n.quickDropHint,
              autoListen: autoMic,
              // Levha açılışı (+ klavye) bitince: tanıyıcı animasyonlarla
              // aynı karelerde açılmasın (S56, 2026-11-19).
              autoListenDelay: keyboard
                  ? AppMotion.medium + AppMotion.long
                  : AppMotion.medium,
              onRawChanged: _onText,
              onRawSubmitted: (_) => _apply(),
              // "Söyle, eklensin": konuşma bitince kısa geri sayımla eklenir.
              onSpeechEnd: _onSpeechEnd,
              // "… bitti" dendi: geri sayım beklemeden hemen eklenir.
              onDoneWord: () => _onSpeechEnd(now: true),
              onItems: (_) {},
            ),
            // DURUM SATIRI, boyu SABİT (levha zıplamasın): nereye / hangi
            // not? / soruyorum / ekleniyor + Bekle.
            SizedBox(
              height: AppSpace.xxl,
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
                      return Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: st.ask
                            ? Text(
                                l10n.quickDropWhich,
                                key: const ValueKey('quick-drop-ask'),
                                style: text.meta.copyWith(
                                  color: scheme.primary,
                                  fontWeight: AppWeight.strong,
                                ),
                              )
                            // HE-2 önizleme: tuşta yalnız bu Text kurulur.
                            : Text(
                                _previewLine(l10n, st),
                                key: const ValueKey('quick-drop-preview'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: text.meta,
                              ),
                      );
                  }
                },
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
                onPressed: add.$1 ? _apply : null,
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
