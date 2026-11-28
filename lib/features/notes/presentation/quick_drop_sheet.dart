import 'dart:async';
import 'dart:convert';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
import '../../folders/data/folders_repository.dart';
import '../../folders/domain/note_folder.dart';
import '../../settings/settings_providers.dart';
import '../data/notes_repository.dart';
import '../data/quick_entry_memory.dart';
import '../domain/context_highlight.dart';
import '../domain/inline_item_parser.dart';
import '../domain/list_mode.dart';
import '../domain/note.dart';
import '../domain/note_item.dart';
import '../domain/note_type.dart';
import '../domain/quick_drop.dart';
import '../domain/quick_entry.dart';
import '../domain/smart_lexicon_v2.dart';
import '../domain/smart_list.dart';
import '../domain/smart_target_router.dart';
import '../domain/text_item_extractor.dart';
import 'note_card.dart' show openNoteRoute;
import 'notes_providers.dart' show focusedNoteProvider;
import 'quick_drop_target_picker.dart';
import 'quick_entry_bar.dart';
import 'text_extract_sheet.dart';

part 'quick_drop_parser.dart';

/// Son eklenen hedef notlar (en yenisi başta) — bağlam puanını besler.
/// HE-5: saat dilimi + haftanın günü bazlı bağlam puanı da burada tutulur.
final quickDropRecentProvider =
    NotifierProvider<QuickDropRecentNotifier, List<String>>(
      QuickDropRecentNotifier.new,
    );

/// **HIZLI EKLE v3** — sadeleştirilmiş panel + güven skorlu hedef tahmini +
/// çoklu niyet dağıtımı + "Hızlı Not" gelen kutusu.
///
/// Ana odakta yalnız 3 öğe vardır:
/// 1. Giriş alanı (yazarken `#` / `!` satır içi önerisi + canlı NL çipleri)
/// 2. Otomatik tahmin edilen dokunulabilir hedef çipi (veya çoklu dağıtım çipleri)
/// 3. Ekle düğmesi.
class QuickDropSheet extends ConsumerStatefulWidget {
  const QuickDropSheet({super.key, this.initialText = ''});

  /// Alana yazılı gelen metin (HE-3: paylaşım, seçim menüsü, derin bağlantı).
  final String initialText;

  static const countdown = Duration(seconds: 2);
  static final commandCountdown = AppMotion.long + AppMotion.medium; // 720 ms

  @override
  ConsumerState<QuickDropSheet> createState() => _QuickDropSheetState();
}

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
    this.tags = const [],
    this.urgent = false,
    this.newSmartListKind,
    this.confidence = 0,
    this.inlineChips = const [],
  });

  final String? id;
  final String content;
  final List<String> ties;
  final bool ask;
  final DateTime? reminderAt;
  final DateTime? calendarDay;
  final List<MultiIntentSegment> multi;
  final List<String> tags;
  final bool urgent;
  final SmartListKind? newSmartListKind;
  final double confidence;
  final List<InlineParsedChip> inlineChips;

  @override
  bool operator ==(Object other) =>
      other is _Drop &&
      other.id == id &&
      other.content == content &&
      other.ask == ask &&
      other.reminderAt == reminderAt &&
      other.calendarDay == calendarDay &&
      other.urgent == urgent &&
      other.newSmartListKind == newSmartListKind &&
      other.confidence == confidence &&
      listEquals(other.ties, ties) &&
      listEquals(other.multi, multi) &&
      listEquals(other.tags, tags) &&
      listEquals(other.inlineChips, inlineChips);

  @override
  int get hashCode => Object.hash(
    id,
    content,
    ask,
    reminderAt,
    calendarDay,
    urgent,
    newSmartListKind,
    confidence,
    Object.hashAll(ties),
    Object.hashAll(multi),
    Object.hashAll(tags),
    Object.hashAll(inlineChips),
  );
}

enum _Phase { idle, counting, thinking }

/// "Yeni not" hedef kimliği.
const _kNewId = '\u0000new';

/// "Yeni akıllı liste" komut hedef kimliği.
const _kSmartListId = '\u0000smart';

/// Düşük güvenli eklemelerin düştüğü "Hızlı Not" klasörü hedef kimliği.
const _kQuickInboxId = '\u0000quick_inbox';

class _QuickDropSheetState extends ConsumerState<QuickDropSheet>
    with SingleTickerProviderStateMixin {
  final _focus = FocusNode();
  final _bar = GlobalKey<QuickEntryBarState>();
  List<Note> _candidates = const [];
  ProviderSubscription<AsyncValue<List<Note>>>? _notesSub;
  late final QuickParser _idle = QuickParser(QuickLexicon());
  String _locale = PlatformDispatcher.instance.locale.languageCode;

  /// Elle seçilen hedef (hedef seçiciden seçildi); null = otomatik tahmin.
  String? _chosenId;

  /// Kullanıcı çoklu dağıtımı "Tek notta birleştir" ile kapattı mı?
  bool _multiMerged = false;

  /// Kullanıcının çoklu dağıtımda elle değiştirdiği/kaldırdığı dilimler.
  List<MultiIntentSegment>? _editedMulti;

  /// Son çözümleme (konuşma sonunda karar için).
  QuickDropTarget? _parsed;

  final _state = ValueNotifier<_Drop>(const _Drop(id: _kQuickInboxId));
  final _phase = ValueNotifier<_Phase>(_Phase.idle);
  final _targets = ValueNotifier<_Drop>(const _Drop(id: _kQuickInboxId));
  final _addLabel = ValueNotifier<(bool, bool)>((false, false));

  /// Metin içinde `#` veya `!` yazıldığında tetiklenen satır içi öneri durumu.
  final _inlineTrigger = ValueNotifier<({String sigil, String query})?>(null);

  /// Yalnız ayrıştırılmış çipler gerçekten değiştiğinde güncellenir (S56 bütçesi).
  final _inlineChipsN = ValueNotifier<List<InlineParsedChip>>(const []);

  /// Yapıştırılan uzun metinden ayıklanabilecek madde sayısı (0 = gösterme).
  final _extractPasteN = ValueNotifier<int>(0);

  QuickParser? _previewParser;
  Note? _previewNote;

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
    final initialTarget = _candidates.isEmpty ? _kNewId : _kQuickInboxId;
    _state.value = _Drop(id: initialTarget);
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
      if (wasEmpty != fresh.isEmpty) setState(() {});
      final current = _bar.currentState?.text ?? widget.initialText;
      if (current.isNotEmpty) {
        _resolve(current);
      } else {
        final nextId = _defaultEmptyTargetId;
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

  String get _defaultEmptyTargetId =>
      _chosenId ?? (_candidates.isEmpty ? _kNewId : _kQuickInboxId);

  bool get _toNewNote =>
      (_candidates.isEmpty && !_toSmartList && !_toQuickInbox) ||
      _state.value.id == _kNewId;

  bool get _toSmartList => _state.value.id == _kSmartListId;

  bool get _toQuickInbox => _state.value.id == _kQuickInboxId;

  /// Günün saatine veya kullanım bağlamına göre öne çıkan tek liste.
  Note? _contextualHighlightNote() {
    if (_candidates.isEmpty) return null;
    final now = DateTime.now();
    final scores = ref.read(quickDropRecentProvider.notifier).contextScores(now);
    return ContextHighlightEngine.topHighlight(
      [for (final n in _candidates) if (!n.isQuickInbox) n],
      now: now,
      contextBoost: scores,
    );
  }

  void _onState() {
    final st = _state.value;
    final targets = _Drop(
      id: st.id,
      ties: st.ties,
      multi: st.multi,
      newSmartListKind: st.newSmartListKind,
    );
    if (targets != _targets.value) _targets.value = targets;
    final content = st.content.trim();
    final enabled =
        (st.id != null ||
            _toNewNote ||
            _toSmartList ||
            _toQuickInbox ||
            st.multi.isNotEmpty) &&
        (content.isNotEmpty || _toSmartList || st.multi.isNotEmpty);
    final nextChips = st.multi.length >= 2
        ? const <InlineParsedChip>[]
        : st.inlineChips;
    if (!listEquals(nextChips, _inlineChipsN.value)) {
      _inlineChipsN.value = nextChips;
    }
    final next = (enabled, st.id == null && st.ask);
    if (next != _addLabel.value) _addLabel.value = next;
  }

  String _smartKindTitle(AppLocalizations l10n, SmartListKind kind) =>
      switch (kind) {
        SmartListKind.shopping => l10n.tplShoppingName,
        SmartListKind.packing => l10n.smartListPacking,
        SmartListKind.pharmacy => l10n.smartListPharmacy,
        SmartListKind.stationery => l10n.smartListStationery,
        SmartListKind.hardware => l10n.smartListHardware,
        SmartListKind.camping => l10n.smartListCamping,
        SmartListKind.baby => l10n.smartListBaby,
        SmartListKind.sport => l10n.smartListSport,
        SmartListKind.moving => l10n.smartListMoving,
        SmartListKind.cleaning => l10n.smartListCleaning,
        SmartListKind.habits => l10n.smartListHabits,
        SmartListKind.workout => l10n.smartListWorkout,
        SmartListKind.gifts => l10n.smartListGifts,
        SmartListKind.watchlist => l10n.smartListWatchlist,
        SmartListKind.event => l10n.smartListEvent,
        SmartListKind.expense => l10n.smartListExpense,
        SmartListKind.generic => l10n.smartListGeneric,
      };

  ({String text, bool ready}) _previewInfo(AppLocalizations l10n, _Drop st) {
    final modSuffix = [
      if (st.urgent) '!',
      for (final tag in st.tags) '#$tag',
    ].join(' ');
    String withMods(String base) =>
        modSuffix.isEmpty ? base : '$base · $modSuffix';

    final content = st.content.trim();
    if (_toSmartList && st.newSmartListKind != null) {
      final title = _smartKindTitle(l10n, st.newSmartListKind!);
      return (
        text: withMods(content.isEmpty ? title : '$title · $content'),
        ready: true,
      );
    }
    if (st.multi.isNotEmpty) {
      final summary = [
        for (final m in st.multi)
          '${m.isQuickInbox ? l10n.quickInboxFolderName : (_noteOf(m.noteId)?.displayTitle.trim() ?? l10n.quickInboxFolderName)} · ${m.content}',
      ].join(' + ');
      return (
        text: withMods(l10n.quickDropPreviewMulti(summary, st.multi.length)),
        ready: true,
      );
    }
    if (content.isEmpty) {
      return (text: _toNewNote ? '' : l10n.quickDropTarget, ready: false);
    }
    if (st.calendarDay != null) {
      final day = DateFormat.MMMMEEEEd(l10n.localeName).format(st.calendarDay!);
      return (
        text: withMods(l10n.quickDropPreviewCalendar(day, content)),
        ready: true,
      );
    }
    if (st.reminderAt != null) {
      final when = DateFormat.MMMd(
        l10n.localeName,
      ).add_Hm().format(st.reminderAt!);
      return (
        text: withMods(l10n.quickDropPreviewReminder(when, content)),
        ready: true,
      );
    }
    if (_toNewNote) {
      return (
        text: withMods(l10n.quickDropPreviewText(l10n.newNoteShort, content)),
        ready: true,
      );
    }
    if (_toQuickInbox) {
      return (
        text: withMods(
          l10n.quickDropPreviewText(l10n.quickInboxFolderName, content),
        ),
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
        text: withMods(l10n.quickDropPreviewText(title, items.join(', '))),
        ready: true,
      );
    }
    return (
      text: withMods(
        l10n.quickDropPreviewItems(title, items.join(', '), items.length),
      ),
      ready: true,
    );
  }

  void _pickMyself() {
    if (_phase.value != _Phase.thinking) return;
    _phase.value = _Phase.idle;
    final st = _state.value;
    _state.value = _Drop(
      id: st.ties.isEmpty ? (st.id ?? _kQuickInboxId) : null,
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
    _addLabel.dispose();
    _phase.dispose();
    _inlineTrigger.dispose();
    _inlineChipsN.dispose();
    _extractPasteN.dispose();
    super.dispose();
  }

  void _updateInlineTrigger(String rawText) {
    final m = RegExp(
      r'(?:^|\s)([#!])([a-zA-Z0-9çğıöşüÇĞİÖŞÜ_-]{0,20})$',
    ).firstMatch(rawText);
    final next = m == null ? null : (sigil: m.group(1)!, query: m.group(2)!);
    if (next != _inlineTrigger.value) _inlineTrigger.value = next;
  }

  void _completeInlineToken(String completion) {
    final cur = _bar.currentState?.text ?? '';
    final replaced = cur.replaceFirst(
      RegExp(r'(^|\s)[#!][a-zA-Z0-9çğıöşüÇĞİÖŞÜ_-]{0,20}$'),
      '\${1}$completion ',
    );
    // RegExp replacement with Dart replaceFirstMapped so group 1 is preserved.
    final next = cur.replaceFirstMapped(
      RegExp(r'(^|\s)[#!][a-zA-Z0-9çğıöşüÇĞİÖŞÜ_-]{0,20}$'),
      (m) => '${m.group(1)}$completion ',
    );
    assert(replaced.isNotEmpty || next.isNotEmpty);
    _bar.currentState?.setText(next);
    _focus.requestFocus();
  }

  List<String> _matchingTags(String query) {
    final q = quickAscii(query);
    final notes = ref.read(notesStreamProvider).value ?? const <Note>[];
    final counts = <String, int>{};
    for (final n in notes) {
      if (n.deletedAt != null || n.archivedAt != null || n.locked) continue;
      for (final t in n.tags) {
        if (q.isEmpty || quickAscii(t).startsWith(q)) {
          counts[t] = (counts[t] ?? 0) + 1;
        }
      }
    }
    final list = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return [for (final e in list.take(6)) e.key];
  }

  void _resolve(String rawText) {
    _updateInlineTrigger(rawText);
    if (rawText.length >= 80 || rawText.contains('\n')) {
      final count = TextItemExtractor.isExtractablePaste(rawText)
          ? TextItemExtractor.extractLocal(
              rawText,
              mode: _noteOf(_state.value.id)?.listMode ?? ListMode.general,
              locale: _locale,
            ).length
          : 0;
      final nextCount = count >= 2 ? count : 0;
      if (_extractPasteN.value != nextCount) _extractPasteN.value = nextCount;
    } else if (_extractPasteN.value != 0) {
      _extractPasteN.value = 0;
    }
    final mods = extractQuickDropModifiers(rawText);
    final text = mods.text;
    final tags = mods.tags;
    final urgent = mods.urgent;

    if (text.trim().isEmpty) {
      _editedMulti = null;
      _multiMerged = false;
      _parsed = null;
      final next = _Drop(
        id: _defaultEmptyTargetId,
        tags: tags,
        urgent: urgent,
      );
      if (next != _state.value) _state.value = next;
      return;
    }

    // 1) Yeni akıllı liste komutu: "yeni bavul listesi: pasaport, şarj"
    if (_chosenId == null || _chosenId == _kSmartListId) {
      final smartCmd = parseNewSmartListCommand(text);
      if (smartCmd != null) {
        _parsed = (
          index: null,
          content: smartCmd.content,
          ties: const [],
          command: true,
        );
        final next = _Drop(
          id: _kSmartListId,
          content: smartCmd.content,
          tags: tags,
          urgent: urgent,
          newSmartListKind: smartCmd.kind,
          confidence: 1.0,
        );
        if (next != _state.value) _state.value = next;
        return;
      }
    }

    // 2) Takvim günü komutu: "… bugüne / yarına ekle"
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
          tags: tags,
          urgent: urgent,
          confidence: 0.95,
        );
        if (next != _state.value) _state.value = next;
        return;
      }
    }

    final contextBoost = ref
        .read(quickDropRecentProvider.notifier)
        .contextScores();

    // 3) Tek nefeste çoklu niyet dağıtımı (kullanıcı elle birleştirmediyse).
    if (_chosenId == null && !_multiMerged) {
      final segments = MultiIntentSplitter.split(
        text,
        _candidates,
        locale: _locale,
        contextBoost: contextBoost,
      );
      if (segments.length >= 2) {
        final effectiveSegments = _editedMulti ?? segments;
        _parsed = (
          index: null,
          content: text.trim(),
          ties: const [],
          command: true,
        );
        final next = _Drop(
          id: effectiveSegments.first.isQuickInbox
              ? _kQuickInboxId
              : effectiveSegments.first.noteId,
          content: text.trim(),
          multi: effectiveSegments,
          tags: tags,
          urgent: urgent,
          confidence: effectiveSegments.first.confidence,
        );
        if (next != _state.value) _state.value = next;
        return;
      }
    }

    // 4) Tek hedef akıllı yönlendirme (güven skorlu + "Hızlı Not" yedeği).
    final route = SmartTargetRouter.route(
      text,
      _candidates,
      locale: _locale,
      contextBoost: contextBoost,
    );
    final titles = [for (final n in _candidates) n.displayTitle];
    _parsed = parseDropTarget(text, titles);

    // Kullanıcı elle hedef seçtiyse o hedefi koru.
    if (_chosenId != null) {
      final targetNote = _noteOf(_chosenId);
      final mode = targetNote?.listMode ?? ListMode.general;
      final inline = InlineItemParser.parse(
        route.content,
        mode: mode,
        locale: _locale,
        learnedGroups: ref.read(quickEntryMemoryProvider).itemGroups,
      );
      final next = _Drop(
        id: _chosenId,
        content: route.content,
        tags: tags,
        urgent: urgent,
        confidence: 1.0,
        inlineChips: inline.chips,
      );
      if (next != _state.value) _state.value = next;
      return;
    }

    if (route.ties.isNotEmpty) {
      final next = _Drop(
        content: route.content,
        ties: route.ties,
        ask: true,
        tags: tags,
        urgent: urgent,
        confidence: route.confidence,
      );
      if (next != _state.value) _state.value = next;
      return;
    }

    if (!route.isQuickInbox && route.noteId != null) {
      final targetNote = _noteOf(route.noteId);
      final mode = targetNote?.listMode ?? ListMode.general;
      final inline = InlineItemParser.parse(
        route.content,
        mode: mode,
        locale: _locale,
        learnedGroups: ref.read(quickEntryMemoryProvider).itemGroups,
      );
      final next = _Drop(
        id: route.noteId,
        content: route.content,
        tags: tags,
        urgent: urgent,
        confidence: route.confidence,
        inlineChips: inline.chips,
      );
      if (next != _state.value) _state.value = next;
      return;
    }

    // Düşük güvenli / eşleşmeyen içerik:
    // Açık saatli hatırlatıcı varsa (ör. "yarın 9'da dişçi") hatırlatıcılı
    // yeni not; yoksa "Hızlı Not" klasörüne (veya hiç not yoksa yeni nota).
    if (!dropNamesUnknownTarget(text) && route.content.trim().isNotEmpty) {
      final reminder = parseSpokenDateTime(
        route.content,
        languageCode: _locale,
      );
      if (reminder != null) {
        final next = _Drop(
          id: _kNewId,
          content: route.content,
          reminderAt: reminder,
          tags: tags,
          urgent: urgent,
          confidence: 0.85,
        );
        if (next != _state.value) _state.value = next;
        return;
      }
    }

    final inline = InlineItemParser.parse(
      route.content,
      locale: _locale,
      learnedGroups: ref.read(quickEntryMemoryProvider).itemGroups,
    );
    final fallbackTarget = _candidates.isEmpty ? _kNewId : _kQuickInboxId;
    final next = _Drop(
      id: fallbackTarget,
      content: route.content,
      tags: tags,
      urgent: urgent,
      confidence: route.confidence,
      inlineChips: inline.chips,
    );
    if (next != _state.value) _state.value = next;
  }

  void _onText(String text) {
    _stopCountdown();
    _editedMulti = null;
    _resolve(text);
  }

  void _choose(Note note) => _chooseId(note.id);

  void _chooseId(String id) {
    _stopCountdown();
    if (_phase.value == _Phase.thinking) _phase.value = _Phase.idle;
    _chosenId = id;
    _multiMerged = true;
    _editedMulti = null;
    final cur = _state.value;
    final targetNote = _noteOf(id);
    final inline = InlineItemParser.parse(
      cur.content,
      mode: targetNote?.listMode ?? ListMode.general,
      locale: _locale,
      learnedGroups: ref.read(quickEntryMemoryProvider).itemGroups,
    );
    _state.value = _Drop(
      id: id,
      content: cur.content,
      tags: cur.tags,
      urgent: cur.urgent,
      newSmartListKind: id == _kSmartListId ? cur.newSmartListKind : null,
      confidence: 1.0,
      inlineChips: inline.chips,
    );
  }

  Future<void> _openTargetPicker() async {
    _stopCountdown();
    final st = _state.value;
    final choice = await showQuickDropTargetPicker(
      context,
      candidates: _candidates,
      selectedNoteId: st.id,
      quickInboxSelected: st.id == _kQuickInboxId,
      newNoteSelected: st.id == _kNewId,
    );
    if (choice == null || !mounted) return;
    switch (choice) {
      case QuickDropTargetQuickInbox():
        _chooseId(_kQuickInboxId);
      case QuickDropTargetNewNote():
        _chooseId(_kNewId);
      case QuickDropTargetNote(:final note):
        _choose(note);
    }
  }

  Future<void> _retargetMultiSegment(int index) async {
    final cur = _state.value.multi;
    if (index < 0 || index >= cur.length) return;
    final seg = cur[index];
    final choice = await showQuickDropTargetPicker(
      context,
      candidates: _candidates,
      selectedNoteId: seg.noteId,
      quickInboxSelected: seg.isQuickInbox,
    );
    if (choice == null || !mounted) return;
    final updated = [...cur];
    switch (choice) {
      case QuickDropTargetQuickInbox():
        updated[index] = MultiIntentSegment(
          noteId: null,
          isQuickInbox: true,
          content: seg.content,
          confidence: 1.0,
        );
      case QuickDropTargetNewNote():
        _chooseId(_kNewId);
        return;
      case QuickDropTargetNote(:final note):
        updated[index] = MultiIntentSegment(
          noteId: note.id,
          isQuickInbox: note.isQuickInbox,
          content: seg.content,
          confidence: 1.0,
        );
    }
    _editedMulti = updated;
    final st = _state.value;
    _state.value = _Drop(
      id: updated.first.isQuickInbox ? _kQuickInboxId : updated.first.noteId,
      content: st.content,
      multi: updated,
      tags: st.tags,
      urgent: st.urgent,
      confidence: st.confidence,
    );
  }

  void _removeMultiSegment(int index) {
    final cur = _state.value.multi;
    if (index < 0 || index >= cur.length) return;
    final updated = [...cur]..removeAt(index);
    final st = _state.value;
    if (updated.isEmpty) {
      _editedMulti = null;
      _bar.currentState?.clear();
      return;
    }
    if (updated.length == 1) {
      final only = updated.single;
      _editedMulti = null;
      _multiMerged = true;
      _chosenId = only.isQuickInbox ? _kQuickInboxId : only.noteId;
      _state.value = _Drop(
        id: _chosenId,
        content: only.content,
        tags: st.tags,
        urgent: st.urgent,
        confidence: only.confidence,
      );
      return;
    }
    _editedMulti = updated;
    _state.value = _Drop(
      id: updated.first.isQuickInbox ? _kQuickInboxId : updated.first.noteId,
      content: st.content,
      multi: updated,
      tags: st.tags,
      urgent: st.urgent,
      confidence: st.confidence,
    );
  }

  void _mergeMultiIntoSingle() {
    _multiMerged = true;
    _editedMulti = null;
    final st = _state.value;
    final targetId = st.multi.isNotEmpty
        ? (st.multi.first.isQuickInbox
              ? _kQuickInboxId
              : (st.multi.first.noteId ?? _kQuickInboxId))
        : _kQuickInboxId;
    _chooseId(targetId);
  }

  // ── Konuşma bitti: geri sayım / yapay zekâ / sor ──────────────────────

  void _onSpeechEnd({bool now = false}) {
    final said = _bar.currentState?.text ?? '';
    _resolve(said);
    final st = _state.value;
    final parsed = _parsed;
    if (st.content.trim().isEmpty && st.multi.isEmpty) return;
    final quick = (parsed?.command ?? false) || endsWithAddCommand(said);
    if (_toNewNote || _toQuickInbox || st.multi.isNotEmpty) {
      // Ad söylenip bulunamadıysa (ör. "hatalar notuna ekle") önce AI veya sor.
      final namedUnknown =
          (parsed?.command ?? false) &&
          parsed?.index == null &&
          dropNamesUnknownTarget(said);
      if (namedUnknown && _chosenId == null) {
        if (_aiUsable) {
          unawaited(_askAi());
          return;
        }
        _state.value = _Drop(content: st.content, ask: true);
        return;
      }
      now ? _apply(resolve: false) : _startCountdown(quick: quick);
      return;
    }
    final named =
        st.ask ||
        ((parsed?.command ?? false) &&
            parsed?.index == null &&
            dropNamesUnknownTarget(said));
    if (named && _chosenId == null) {
      if (_aiUsable) {
        unawaited(_askAi());
        return;
      }
      if (st.ties.isEmpty) {
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
          id: st.ties.isEmpty ? (st.id ?? _kQuickInboxId) : null,
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
        : _candidates.where((n) => !n.isQuickInbox).take(40).toList();
    _phase.value = _Phase.thinking;
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
            id: grocery?.id ?? _kQuickInboxId,
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
            id: reminder != null ? _kNewId : _kQuickInboxId,
            content: st.content,
            reminderAt: reminder,
            ask: true,
          );
          return;
        case CaptureRouteIntent.note:
          _state.value = _Drop(
            id: _kQuickInboxId,
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
      id: st.ties.isEmpty ? (st.id ?? _kQuickInboxId) : null,
      content: st.content,
      ties: st.ties,
      ask: true,
    );
  }

  Note? _firstGroceryNote() {
    for (final n in _candidates) {
      if (n.type == NoteType.text || n.isQuickInbox) continue;
      if (n.listMode == ListMode.shopping ||
          smartListKindFromId(n.listKind) == SmartListKind.shopping ||
          looksLikeGrocery(n.displayTitle, [
            for (final i in n.items) i.text,
          ], _locale)) {
        return n;
      }
    }
    return null;
  }

  void _startCountdown({bool quick = false}) {
    _phase.value = _Phase.counting;
    _count.duration = quick
        ? QuickDropSheet.commandCountdown
        : QuickDropSheet.countdown;
    unawaited(_count.forward(from: 0));
    _checkFixes();
  }

  ({String key, List<({String typed, String fixed})> fixes})? _vetoed;

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

  Note? _noteOf(String? id) {
    if (id == null || id.startsWith('\u0000')) return null;
    for (final n in ref.read(notesStreamProvider).value ?? const <Note>[]) {
      if (n.id == id) return n;
    }
    for (final n in _candidates) {
      if (n.id == id) return n;
    }
    return null;
  }

  void _finishAfterApply({required bool keepOpen}) {
    if (keepOpen) {
      _bar.currentState?.clear();
      _chosenId = null;
      _multiMerged = false;
      _editedMulti = null;
      _parsed = null;
      _vetoed = null;
      _inlineTrigger.value = null;
      _state.value = _Drop(id: _defaultEmptyTargetId);
      _focus.requestFocus();
      return;
    }
    Navigator.of(context).pop();
  }

  /// "Hızlı Not" klasöründeki yuvarlanan checklist notuna yazar; yoksa klasörü
  /// ve notu tek seferde oluşturur.
  Future<Note?> _writeToQuickInbox({
    required NotesRepository repo,
    required FoldersRepository? foldersRepo,
    required List<NoteFolder> existingFolders,
    required List<Note> existingNotes,
    required String folderTitle,
    required String content,
    required String locale,
    required QuickEntryMemory memory,
    required List<String> tags,
    required bool urgent,
  }) async {
    String? folderId;
    for (final f in existingFolders) {
      if (f.isQuickInbox) {
        folderId = f.id;
        break;
      }
    }
    if (folderId == null && foldersRepo != null) {
      folderId = await foldersRepo.ensureQuickInboxFolder(
        name: folderTitle,
        existingFolders: existingFolders,
      );
    }
    Note? inboxNote;
    for (final n in existingNotes) {
      if (n.deletedAt != null || n.archivedAt != null || n.locked) continue;
      if (n.isQuickInbox && (folderId == null || n.folderId == folderId)) {
        inboxNote = n;
        break;
      }
    }
    if (inboxNote != null) {
      final res = quickDropFields(
        inboxNote,
        content,
        locale: locale,
        memory: memory,
      );
      final fields = Map<String, dynamic>.from(res.fields);
      if (tags.isNotEmpty) {
        fields['tags'] = {...inboxNote.tags, ...tags}.toList();
      }
      if (urgent && !inboxNote.urgent) fields['urgent'] = true;
      if (fields.isNotEmpty) repo.updateFields(inboxNote.id, fields);
      return inboxNote;
    }
    final stub = Note(
      id: '',
      type: NoteType.checklist,
      title: folderTitle,
      folderId: folderId,
      isQuickInbox: true,
    );
    final res = quickDropFields(stub, content, locale: locale, memory: memory);
    final rawItems = res.fields['items'] as List? ?? const [];
    final items = [
      for (final m in rawItems)
        if (m is Map<String, dynamic>) NoteItem.fromMap(m),
    ];
    final id = await repo.createRichNote(
      NoteType.checklist,
      title: folderTitle,
      items: items,
      tags: tags,
      urgent: urgent,
      folderId: folderId,
      listMode: ListMode.general,
      isQuickInbox: true,
    );
    return Note(
      id: id,
      type: NoteType.checklist,
      title: folderTitle,
      items: items,
      folderId: folderId,
      isQuickInbox: true,
    );
  }

  void _openNoteSafely(BuildContext navContext, Note note) {
    if (!navContext.mounted) return;
    if (GoRouter.maybeOf(navContext) == null) return;
    unawaited(openNoteRoute(navContext, note));
  }

  void _apply({bool resolve = true}) {
    _stopCountdown();
    if (resolve && _editedMulti == null) _resolve(_bar.currentState?.text ?? '');
    final st = _state.value;
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;
    final foldersRepo = ref.read(foldersRepositoryProvider);
    final existingFolders =
        ref.read(foldersStreamProvider).value ?? const <NoteFolder>[];
    final existingNotes =
        ref.read(notesStreamProvider).value ?? const <Note>[];
    final focusNotifier = ref.read(focusedNoteProvider.notifier);
    final recentNotifier = ref.read(quickDropRecentProvider.notifier);
    final keepOpen = ref.read(quickDropKeepOpenProvider);
    final navContext = Navigator.of(context).context;

    // 1) Yeni akıllı liste komutu: "yeni bavul listesi: pasaport, şarj"
    if (_toSmartList && st.newSmartListKind != null) {
      final kind = st.newSmartListKind!;
      final l10n = context.l10n;
      final title = _smartKindTitle(l10n, kind);
      final messenger = ScaffoldMessenger.of(context);
      final raw = st.content.trim();
      final listId = smartListKindId(kind);
      final List<NoteItem> items;
      if (raw.isEmpty) {
        items = const [];
      } else {
        final stub = Note(
          id: '',
          type: NoteType.checklist,
          title: title,
          listKind: listId,
          listMode: listModeFromLegacyKind(listId),
        );
        final res = quickDropFields(
          stub,
          raw,
          locale: l10n.localeName,
          memory: ref.read(quickEntryMemoryProvider),
        );
        final rawItems = res.fields['items'] as List? ?? const [];
        items = [
          for (final m in rawItems)
            if (m is Map<String, dynamic>) NoteItem.fromMap(m),
        ];
      }
      unawaited(
        repo
            .createRichNote(
              NoteType.checklist,
              title: title,
              items: items,
              tags: st.tags,
              urgent: st.urgent,
              listKind: listId,
              listMode: listModeFromLegacyKind(listId),
              resetSchedule: defaultResetScheduleForLegacyKind(listId),
            )
            .then((id) {
              recentNotifier.remember(id);
              focusNotifier.focus(id);
            }),
      );
      _finishAfterApply(keepOpen: keepOpen);
      messenger
        ..hideCurrentSnackBar()
        ..showMessage(l10n.quickListSaved(title));
      return;
    }

    // 2) Çoklu niyet dağıtımı (her dilim kendi hedefine veya Hızlı Not'a).
    if (st.multi.isNotEmpty) {
      final l10n = context.l10n;
      final memory = ref.read(quickEntryMemoryProvider);
      final messenger = ScaffoldMessenger.of(context);
      final container = ProviderScope.containerOf(context, listen: false);
      final applied = <({Note before, Map<String, dynamic> written})>[];
      final inboxSegments = <String>[];
      for (final m in st.multi) {
        if (m.isQuickInbox) {
          inboxSegments.add(m.content);
          continue;
        }
        final target = _noteOf(m.noteId);
        if (target == null) continue;
        final res = quickDropFields(
          target,
          m.content,
          locale: l10n.localeName,
          memory: memory,
        );
        final fields = Map<String, dynamic>.from(res.fields);
        if (st.tags.isNotEmpty) {
          fields['tags'] = {...target.tags, ...st.tags}.toList();
        }
        if (st.urgent) fields['urgent'] = true;
        if (fields.isEmpty) continue;
        repo.updateFields(target.id, fields);
        recentNotifier.remember(target.id);
        applied.add((before: target, written: fields));
      }
      if (inboxSegments.isNotEmpty) {
        unawaited(
          _writeToQuickInbox(
            repo: repo,
            foldersRepo: foldersRepo,
            existingFolders: existingFolders,
            existingNotes: existingNotes,
            folderTitle: l10n.quickInboxFolderName,
            content: inboxSegments.join(', '),
            locale: l10n.localeName,
            memory: memory,
            tags: st.tags,
            urgent: st.urgent,
          ),
        );
      }
      if (applied.isNotEmpty) {
        focusNotifier.focus(applied.first.before.id);
      }
      _finishAfterApply(keepOpen: keepOpen);
      final totalTargets = applied.length + (inboxSegments.isNotEmpty ? 1 : 0);
      if (totalTargets == 0) return;
      void undoAll() {
        final live =
            container.read(notesStreamProvider).value ?? const <Note>[];
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
          l10n.quickDropAddedMulti(totalTargets),
          action: applied.isNotEmpty
              ? SnackBarAction(label: l10n.undo, onPressed: undoAll)
              : null,
        );
      return;
    }

    // 3) Takvim günü komutu
    final calendarDay = st.calendarDay;
    final calendar = ref.read(calendarRepositoryProvider);
    if (calendarDay != null &&
        calendar != null &&
        st.content.trim().isNotEmpty) {
      final body = st.content.trim();
      final messenger = ScaffoldMessenger.of(context);
      final l10n = context.l10n;
      final key = dayKey(calendarDay);
      unawaited(
        (st.tags.isNotEmpty || st.urgent
                ? repo.createRichNote(
                    NoteType.text,
                    body: body,
                    tags: st.tags,
                    urgent: st.urgent,
                  )
                : repo.createNote(NoteType.text, body: body))
            .then((id) {
              calendar.linkNoteToDay(key, id);
              recentNotifier.remember(id);
              focusNotifier.focus(id);
            }),
      );
      _finishAfterApply(keepOpen: keepOpen);
      messenger
        ..hideCurrentSnackBar()
        ..showMessage(
          l10n.quickDropSavedCalendar(
            DateFormat.MMMMd(l10n.localeName).format(calendarDay),
          ),
        );
      return;
    }

    // 4) Yeni not / hatırlatıcılı yeni not
    if (_toNewNote && st.content.trim().isNotEmpty) {
      final body = st.content.trim();
      final reminderAt = st.reminderAt;
      final messenger = ScaffoldMessenger.of(context);
      final l10n = context.l10n;
      unawaited(
        (st.tags.isNotEmpty || st.urgent
                ? repo.createRichNote(
                    NoteType.text,
                    body: body,
                    reminderAt: reminderAt,
                    tags: st.tags,
                    urgent: st.urgent,
                  )
                : repo.createNote(
                    NoteType.text,
                    body: body,
                    reminderAt: reminderAt,
                  ))
            .then((id) {
              recentNotifier.remember(id);
              focusNotifier.focus(id);
            }),
      );
      _finishAfterApply(keepOpen: keepOpen);
      messenger
        ..hideCurrentSnackBar()
        ..showMessage(
          reminderAt != null
              ? l10n.quickDropSavedReminder
              : l10n.quickDropSavedNew,
        );
      return;
    }

    // 5) "Hızlı Not" klasörü (Kural 4: mutlaka "Hızlı Not'a eklendi · Aç" snackbar'ı)
    if (_toQuickInbox && st.content.trim().isNotEmpty) {
      final l10n = context.l10n;
      final messenger = ScaffoldMessenger.of(context);
      final memory = ref.read(quickEntryMemoryProvider);
      final futureNote = _writeToQuickInbox(
        repo: repo,
        foldersRepo: foldersRepo,
        existingFolders: existingFolders,
        existingNotes: existingNotes,
        folderTitle: l10n.quickInboxFolderName,
        content: st.content.trim(),
        locale: l10n.localeName,
        memory: memory,
        tags: st.tags,
        urgent: st.urgent,
      );
      _finishAfterApply(keepOpen: keepOpen);
      unawaited(
        futureNote.then((inboxNote) {
          messenger
            ..hideCurrentSnackBar()
            ..showMessage(
              l10n.quickDropAddedQuickInbox,
              action: inboxNote == null
                  ? null
                  : SnackBarAction(
                      label: l10n.quickDropOpen,
                      onPressed: () => _openNoteSafely(navContext, inboxNote),
                    ),
            );
        }),
      );
      return;
    }

    // 6) Mevcut belirli not
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
    final fields = Map<String, dynamic>.from(result.fields);
    if (st.tags.isNotEmpty) {
      final merged = {...note.tags, ...st.tags}.toList();
      if (merged.length != note.tags.length) fields['tags'] = merged;
    }
    if (st.urgent && !note.urgent) fields['urgent'] = true;
    final title = note.displayTitle.trim();
    final messenger = ScaffoldMessenger.of(context);
    if (fields.isNotEmpty) {
      repo.updateFields(note.id, fields);
      recentNotifier.remember(note.id);
      focusNotifier.focus(note.id);
    }
    final container = ProviderScope.containerOf(context, listen: false);
    _finishAfterApply(keepOpen: keepOpen);
    if (fields.isEmpty) {
      messenger.showMessage(l10n.quickDropNothingNew(title));
      return;
    }
    void undo() {
      Note? current;
      for (final n
          in container.read(notesStreamProvider).value ?? const <Note>[]) {
        if (n.id == note.id) current = n;
      }
      final undoF = quickDropUndoFields(
        before: note,
        current: current ?? note,
        written: fields,
      );
      if (undoF.isNotEmpty) repo.updateFields(note.id, undoF);
    }

    messenger
      ..hideCurrentSnackBar()
      ..showMessage(
        note.type == NoteType.text && result.added <= 1
            ? l10n.quickDropAddedText(title)
            : l10n.quickDropAdded(result.added, title),
        action: SnackBarAction(label: l10n.undo, onPressed: undo),
      );
  }

  Future<void> _openPasteExtract() async {
    final raw = _bar.currentState?.text ?? '';
    if (raw.trim().isEmpty) return;
    _stopCountdown();
    final targetNote = _noteOf(_state.value.id);
    final mode = targetNote?.listMode ?? ListMode.general;
    final learned = ref.read(quickEntryMemoryProvider).itemGroups;
    final extracted = await showTextExtractSheet(
      context,
      ref,
      initialText: raw,
      mode: mode,
      learnedGroups: learned,
      noteLocked: targetNote?.locked ?? false,
    );
    if (extracted == null || extracted.isEmpty || !mounted) return;

    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final navContext = Navigator.of(context).context;
    final keepOpen = ref.read(quickDropKeepOpenProvider);

    if (targetNote != null && !targetNote.locked) {
      if (targetNote.type == NoteType.text) {
        final lines = [for (final i in extracted) i.text].join('\n');
        final body = targetNote.body.trim().isEmpty
            ? lines
            : '${targetNote.body.trimRight()}\n$lines';
        repo.updateFields(targetNote.id, {'body': body});
      } else {
        repo.updateFields(targetNote.id, {
          'items': [
            for (final i in [...targetNote.items, ...extracted]) i.toMap(),
          ],
        });
      }
      ref.read(focusedNoteProvider.notifier).focus(targetNote.id);
      _extractPasteN.value = 0;
      _finishAfterApply(keepOpen: keepOpen);
      messenger
        ..hideCurrentSnackBar()
        ..showMessage(
          l10n.quickDropAdded(extracted.length, targetNote.displayTitle.trim()),
        );
      return;
    }

    // Hedef belirsizse Kural 4 uyumlu şekilde "Hızlı Not" gelen kutusuna ekle.
    final foldersRepo = ref.read(foldersRepositoryProvider);
    final existingFolders =
        ref.read(foldersStreamProvider).value ?? const <NoteFolder>[];
    final existingNotes =
        ref.read(notesStreamProvider).value ?? const <Note>[];
    final folderTitle = l10n.quickInboxFolderName;
    String? folderId;
    for (final f in existingFolders) {
      if (f.isQuickInbox) {
        folderId = f.id;
        break;
      }
    }
    if (folderId == null && foldersRepo != null) {
      folderId = await foldersRepo.ensureQuickInboxFolder(
        name: folderTitle,
        existingFolders: existingFolders,
      );
    }
    Note? inboxNote;
    for (final n in existingNotes) {
      if (n.deletedAt != null || n.archivedAt != null || n.locked) continue;
      if (n.isQuickInbox && (folderId == null || n.folderId == folderId)) {
        inboxNote = n;
        break;
      }
    }
    Note opened;
    if (inboxNote != null) {
      final merged = [...inboxNote.items, ...extracted];
      repo.updateFields(inboxNote.id, {
        'items': [for (final i in merged) i.toMap()],
      });
      opened = inboxNote.copyWith(items: merged);
    } else {
      final id = await repo.createRichNote(
        NoteType.checklist,
        title: folderTitle,
        items: extracted,
        folderId: folderId,
        listMode: ListMode.general,
        isQuickInbox: true,
      );
      opened = Note(
        id: id,
        type: NoteType.checklist,
        title: folderTitle,
        items: extracted,
        folderId: folderId,
        isQuickInbox: true,
      );
    }
    if (!mounted) return;
    _extractPasteN.value = 0;
    _finishAfterApply(keepOpen: keepOpen);
    messenger
      ..hideCurrentSnackBar()
      ..showMessage(
        l10n.quickDropAddedQuickInbox,
        action: SnackBarAction(
          label: l10n.quickDropOpen,
          onPressed: () => _openNoteSafely(navContext, opened),
        ),
      );
  }

  ({IconData icon, String label}) _targetBadgeFor(
    AppLocalizations l10n,
    _Drop st,
  ) {
    if (st.id == _kSmartListId && st.newSmartListKind != null) {
      return (
        icon:
            kSmartKindSpecs[st.newSmartListKind!]?.icon ??
            Icons.auto_awesome_outlined,
        label: _smartKindTitle(l10n, st.newSmartListKind!),
      );
    }
    if (st.id == _kNewId) {
      return (icon: Icons.add, label: l10n.newNoteShort);
    }
    if (st.id == _kQuickInboxId || st.id == null) {
      return (icon: Icons.bolt_outlined, label: l10n.quickInboxFolderName);
    }
    final note = _noteOf(st.id);
    if (note == null) {
      return (icon: Icons.bolt_outlined, label: l10n.quickInboxFolderName);
    }
    final icon = switch (note.listMode) {
      ListMode.shopping => Icons.shopping_cart_outlined,
      ListMode.routine => Icons.repeat_rounded,
      ListMode.template => Icons.checklist_rtl_outlined,
      ListMode.project => Icons.flag_outlined,
      ListMode.general =>
        note.type == NoteType.text
            ? Icons.notes_outlined
            : Icons.check_box_outlined,
    };
    return (icon: icon, label: note.displayTitle.trim());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = AppTokens.fromTheme(theme);
    final text = AppText.of(theme);
    final autoMic = ref.watch(quickDropMicProvider);
    final keyboard = ref.watch(quickDropKeyboardProvider);
    final ai = ref.watch(quickDropAiProvider);
    final keepOpen = ref.watch(quickDropKeepOpenProvider);
    final contextNote = _contextualHighlightNote();

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.l, 0, AppSpace.l, AppSpace.l),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpace.xs),
                  child: Icon(
                    Icons.bolt_rounded,
                    size: AppIconSize.s,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.s),
              Expanded(
                child: Text(l10n.quickDropTitle, style: text.sheetTitle),
              ),
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
                  CheckedPopupMenuItem(
                    key: const ValueKey('quick-drop-keep-open'),
                    value: quickDropKeepOpenProvider,
                    checked: keepOpen,
                    child: Text(l10n.quickDropKeepOpen),
                  ),
                ],
              ),
            ],
          ),
          if (_candidates.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.s),
              child: Text(
                l10n.quickDropNoNotesNew,
                key: const ValueKey('quick-drop-no-notes'),
                style: text.meta.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          QuickEntryBar(
            key: _bar,
            parser: _idle,
            raw: true,
            initialText: widget.initialText,
            focusNode: _focus,
            hint: l10n.quickDropHint,
            autoListen: autoMic,
            autoListenDelay: keyboard
                ? AppMotion.medium + AppMotion.long
                : AppMotion.medium,
            onListeningChanged: (on) {
              if (on) _stopCountdown();
            },
            onRawChanged: _onText,
            onRawSubmitted: (_) => _apply(),
            onSpeechEnd: _onSpeechEnd,
            onDoneWord: () => _onSpeechEnd(now: true),
            onAddWord: _onSpeechEnd,
            onItems: (_) {},
          ),
          // Satır içi `#` / `!` tetiklendiğinde görünen bağlamsal öneri şeridi.
          ValueListenableBuilder<({String sigil, String query})?>(
            valueListenable: _inlineTrigger,
            builder: (context, trig, _) {
              if (trig == null) return const SizedBox.shrink();
              final suggestions = trig.sigil == '!'
                  ? [
                      ('!acil', l10n.quickDropPriorityUrgent),
                      ('!yüksek', l10n.quickDropPriorityHigh),
                      ('!orta', l10n.quickDropPriorityMedium),
                      ('!düşük', l10n.quickDropPriorityLow),
                    ].where(
                      (p) =>
                          trig.query.isEmpty ||
                          quickAscii(p.$1).contains(quickAscii(trig.query)),
                    )
                  : [for (final t in _matchingTags(trig.query)) ('#$t', '#$t')];
              if (suggestions.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: AppSpace.xs),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    key: const ValueKey('quick-drop-inline-suggestions'),
                    children: [
                      for (final (token, label) in suggestions) ...[
                        ActionChip(
                          label: Text(label),
                          visualDensity: VisualDensity.compact,
                          onPressed: () => _completeInlineToken(token),
                        ),
                        const SizedBox(width: AppSpace.xs),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
          // Durum / önizleme satırı (sabit yükseklik — zıplama yok).
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
                      final title = _toQuickInbox
                          ? l10n.quickInboxFolderName
                          : (_noteOf(st.id)?.displayTitle.trim() ?? '');
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
          // Sadeleştirilmiş hedef alanı: tek dokunulabilir tahmin çipi
          // (veya çoklu dağıtım önizleme çipleri).
          ValueListenableBuilder<_Drop>(
            valueListenable: _targets,
            builder: (context, st, _) {
              if (st.multi.length >= 2) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpace.s),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        key: const ValueKey('quick-drop-multi-chips'),
                        spacing: AppSpace.xs,
                        runSpacing: AppSpace.xs,
                        children: [
                          for (var i = 0; i < st.multi.length; i++)
                            InputChip(
                              key: ValueKey('quick-drop-multi-$i'),
                              avatar: Icon(
                                st.multi[i].isQuickInbox
                                    ? Icons.bolt_outlined
                                    : Icons.subdirectory_arrow_right_rounded,
                                size: AppIconSize.xs,
                              ),
                              label: Text(
                                '${st.multi[i].isQuickInbox ? l10n.quickInboxFolderName : (_noteOf(st.multi[i].noteId)?.displayTitle.trim() ?? l10n.quickInboxFolderName)}: ${st.multi[i].content}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onPressed: () => _retargetMultiSegment(i),
                              onDeleted: () => _removeMultiSegment(i),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.xs),
                      ActionChip(
                        key: const ValueKey('quick-drop-merge-single'),
                        avatar: const Icon(
                          Icons.merge_type_rounded,
                          size: AppIconSize.xs,
                        ),
                        label: Text(l10n.quickDropMergeSingle),
                        visualDensity: VisualDensity.compact,
                        onPressed: _mergeMultiIntoSingle,
                      ),
                    ],
                  ),
                );
              }

              final badge = _targetBadgeFor(l10n, st);
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.s),
                child: Wrap(
                  key: const ValueKey('quick-drop-targets'),
                  spacing: AppSpace.xs,
                  runSpacing: AppSpace.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Otomatik tahmin edilen ana hedef çipi (dokununca seçici açılır).
                    GestureDetector(
                      key: const ValueKey('quick-drop-target-chip'),
                      behavior: HitTestBehavior.opaque,
                      onTap: _openTargetPicker,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer.withValues(
                            alpha: 0.72,
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: scheme.primary.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpace.m,
                            vertical: AppSpace.xs,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                badge.icon,
                                size: AppIconSize.xs,
                                color: scheme.onPrimaryContainer,
                              ),
                              const SizedBox(width: AppSpace.xs),
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 220,
                                ),
                                child: Text(
                                  l10n.quickDropTargetLabel(badge.label),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: text.meta.copyWith(
                                    color: scheme.onPrimaryContainer,
                                    fontWeight: AppWeight.medium,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpace.xxs),
                              Icon(
                                Icons.arrow_drop_down_rounded,
                                size: AppIconSize.s,
                                color: scheme.onPrimaryContainer,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Başa baş kalan adaylar varsa yalnız o 2–3 aday gösterilir.
                    for (final tieId in st.ties)
                      if (_noteOf(tieId) case final tieNote?)
                        ChoiceChip(
                          key: ValueKey('quick-drop-target-${tieNote.id}'),
                          label: Text(
                            tieNote.displayTitle.trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          selected: st.id == tieNote.id,
                          showCheckmark: false,
                          onSelected: (_) => _choose(tieNote),
                        ),
                    // Girdi boşken günün saatine uyan tek bağlamsal öneri çipi.
                    if (_state.value.content.isEmpty &&
                        contextNote != null &&
                        st.id != contextNote.id)
                      ActionChip(
                        key: const ValueKey('quick-drop-context-chip'),
                        avatar: Icon(
                          Icons.schedule_outlined,
                          size: AppIconSize.xs,
                          color: scheme.primary,
                        ),
                        label: Text(
                          l10n.quickDropContextNow(
                            contextNote.displayTitle.trim(),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        side: BorderSide(color: tokens.hairline),
                        onPressed: () => _choose(contextNote),
                      ),
                  ],
                ),
              );
            },
          ),
          // Uzun yapıştırılan metin algılandığında "Metinden N madde ayıkla" hapı.
          ValueListenableBuilder<int>(
            valueListenable: _extractPasteN,
            builder: (context, count, _) {
              if (count < 2) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.s),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: ActionChip(
                    key: const ValueKey('quick-drop-extract-paste'),
                    avatar: Icon(
                      Icons.playlist_add_check_rounded,
                      size: AppIconSize.xs,
                      color: scheme.primary,
                    ),
                    label: Text(l10n.textExtractPasteBanner(count)),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => unawaited(_openPasteExtract()),
                  ),
                ),
              );
            },
          ),
          // Satır içi ayrıştırılmış canlı çipler (miktar / fiyat / tarih / öncelik).
          ValueListenableBuilder<List<InlineParsedChip>>(
            valueListenable: _inlineChipsN,
            builder: (context, chips, _) {
              if (chips.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.s),
                child: Wrap(
                  key: const ValueKey('quick-drop-inline-chips'),
                  spacing: AppSpace.xs,
                  runSpacing: AppSpace.xs,
                  children: [
                    for (final chip in chips)
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: scheme.secondaryContainer.withValues(
                            alpha: 0.7,
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpace.s,
                            vertical: AppSpace.xxs,
                          ),
                          child: Text(
                            chip.label,
                            style: text.badge.copyWith(
                              color: scheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          ValueListenableBuilder<(bool, bool)>(
            valueListenable: _addLabel,
            builder: (context, add, _) => FilledButton.icon(
              key: const ValueKey('quick-drop-add'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(kMinInteractiveDimension),
                shape: const StadiumBorder(),
              ),
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
      ),
    );
  }
}
