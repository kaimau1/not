import 'dart:async';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/utils/firestore_size.dart' show sameFirestoreValue;
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/sheet_keyboard.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../../ai/data/ai_gate.dart';
import '../../ai/data/gemini_service.dart';
import '../../settings/settings_providers.dart';
import '../data/notes_repository.dart';
import '../data/quick_entry_memory.dart';
import '../domain/note.dart';
import '../domain/note_item.dart';
import '../domain/note_type.dart';
import '../domain/quick_drop.dart';
import '../domain/quick_entry.dart';
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
  final parsed = buildQuickParser(
    lex,
    memory: memory,
    phrasesOnly: !grocery,
  ).parse(text, flush: true);
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
    _state.value = _Drop(id: _candidates.isEmpty ? null : _candidates.first.id);
    if (ref.read(quickDropKeyboardProvider)) focusAfterRouteOpens(this, _focus);
  }

  @override
  void dispose() {
    _count.dispose();
    _focus.dispose();
    _state.dispose();
    _phase.dispose();
    super.dispose();
  }

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

  void _choose(Note note) {
    _stopCountdown();
    if (_phase.value == _Phase.thinking) _phase.value = _Phase.idle;
    _chosenId = note.id;
    _state.value = _Drop(id: note.id, content: _state.value.content);
  }

  // ── Konuşma bitti: geri sayım / yapay zekâ / sor ──────────────────────

  /// [now]: kullanıcı "bitti" dedi — hedef belliyse geri sayım yok.
  void _onSpeechEnd({bool now = false}) {
    _resolve(_bar.currentState?.text ?? '');
    final st = _state.value;
    final parsed = _parsed;
    if (st.content.trim().isEmpty || parsed == null) return;
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
    ({int index, String content})? hit;
    try {
      hit = await ref
          .read(geminiServiceProvider)
          .pickDropTarget(text, [for (final n in pool) n.displayTitle])
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      hit = null;
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
    if (note == null || repo == null || st.content.trim().isEmpty) return;
    final content = st.content;
    final l10n = context.l10n;
    final memory = ref.read(quickEntryMemoryProvider);
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
              IconButton(
                key: const ValueKey('quick-drop-ai'),
                tooltip: l10n.quickDropAiToggle,
                isSelected: ai,
                icon: const Icon(Icons.auto_awesome_outlined),
                selectedIcon: Icon(Icons.auto_awesome, color: scheme.primary),
                onPressed: () =>
                    ref.read(quickDropAiProvider.notifier).set(!ai),
              ),
              IconButton(
                key: const ValueKey('quick-drop-keyboard'),
                tooltip: l10n.quickDropKeyboard,
                isSelected: keyboard,
                icon: const Icon(Icons.keyboard_outlined),
                selectedIcon: Icon(Icons.keyboard, color: scheme.primary),
                onPressed: () =>
                    ref.read(quickDropKeyboardProvider.notifier).set(!keyboard),
              ),
              IconButton(
                key: const ValueKey('quick-drop-auto-mic'),
                tooltip: l10n.quickDropMicAuto,
                isSelected: autoMic,
                icon: const Icon(Icons.hearing_disabled_outlined),
                selectedIcon: Icon(Icons.hearing, color: scheme.primary),
                onPressed: () =>
                    ref.read(quickDropMicProvider.notifier).set(!autoMic),
              ),
            ],
          ),
          if (_candidates.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.l),
              child: Text(
                l10n.quickDropNoNotes,
                style: text.body.copyWith(color: scheme.onSurfaceVariant),
              ),
            )
          else ...[
            QuickEntryBar(
              key: _bar,
              parser: _idle,
              raw: true,
              focusNode: _focus,
              hint: l10n.quickDropHint,
              autoListen: autoMic,
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
                      return Row(
                        key: const ValueKey('quick-drop-thinking'),
                        children: [
                          const SizedBox.square(
                            dimension: AppIconSize.xs,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: AppSpace.s),
                          Text(l10n.quickDropAsking, style: text.meta),
                        ],
                      );
                    case _Phase.counting:
                      final title = _noteOf(st.id)?.displayTitle.trim() ?? '';
                      return Row(
                        key: const ValueKey('quick-drop-counting'),
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.quickDropAddingTo(title),
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
                            : Text(l10n.quickDropTarget, style: text.meta),
                      );
                  }
                },
              ),
            ),
            SizedBox(
              height: AppSpace.xxxl + AppSpace.m,
              child: ValueListenableBuilder<_Drop>(
                valueListenable: _state,
                builder: (context, st, _) {
                  // Seçili hedef hep başta, sonra başa baş kalanlar.
                  final first = [
                    ?_noteOf(st.id),
                    for (final id in st.ties)
                      if (id != st.id) ?_noteOf(id),
                  ];
                  final shown = [
                    ...first,
                    for (final n in _candidates.take(12))
                      if (!first.contains(n)) n,
                  ];
                  return ListView.separated(
                    key: const ValueKey('quick-drop-targets'),
                    scrollDirection: Axis.horizontal,
                    itemCount: shown.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: AppSpace.s),
                    itemBuilder: (context, i) {
                      final n = shown[i];
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
            ValueListenableBuilder<_Drop>(
              valueListenable: _state,
              builder: (context, st, _) => FilledButton.icon(
                key: const ValueKey('quick-drop-add'),
                onPressed: st.id == null || st.content.trim().isEmpty
                    ? null
                    : _apply,
                icon: const Icon(Icons.add),
                label: Text(
                  st.id == null && st.ask
                      ? l10n.quickDropWhich
                      : st.content.trim().isEmpty
                      ? l10n.quickDropAdd
                      : '${l10n.quickDropAdd} · ${st.content.trim()}',
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
