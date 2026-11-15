import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/sheet_keyboard.dart';
import '../../../core/widgets/undo_snackbar.dart';
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
  final text = content.trim();
  if (text.isEmpty) return (fields: const {}, added: 0);
  if (note.type == NoteType.text) {
    final body = note.body.trimRight();
    return (fields: {'body': body.isEmpty ? text : '$body\n$text'}, added: 1);
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
/// çözülür ("market: süt", "alışveriş listesine süt ekle" — bkz.
/// [parseDropTarget]); çözülemezse seçili çip (son kullanılan not) geçerlidir.
/// Model/kota kullanmaz.
class QuickDropSheet extends ConsumerStatefulWidget {
  const QuickDropSheet({super.key});

  @override
  ConsumerState<QuickDropSheet> createState() => _QuickDropSheetState();
}

class _QuickDropSheetState extends ConsumerState<QuickDropSheet> {
  final _focus = FocusNode();
  final _bar = GlobalKey<QuickEntryBarState>();
  late final List<Note> _candidates;
  late final QuickParser _idle = QuickParser(QuickLexicon());

  /// Elle seçilen hedef (çipe dokunuldu); null = metinden/sondan.
  String? _chosenId;

  /// (hedef not kimliği, eklenecek içerik) — yalnız bu değişince alt kısım
  /// kurulur.
  final _state = ValueNotifier<(String?, String)>((null, ''));

  @override
  void initState() {
    super.initState();
    _candidates = quickDropCandidates(
      ref.read(notesStreamProvider).value ?? const <Note>[],
      ref.read(quickDropRecentProvider),
    );
    _state.value = (_candidates.isEmpty ? null : _candidates.first.id, '');
    if (ref.read(quickDropKeyboardProvider)) focusAfterRouteOpens(this, _focus);
  }

  @override
  void dispose() {
    _focus.dispose();
    _state.dispose();
    super.dispose();
  }

  void _onText(String text) {
    final parsed = parseDropTarget(text, [
      for (final n in _candidates) n.displayTitle,
    ]);
    final fromText = parsed.index == null
        ? null
        : _candidates[parsed.index!].id;
    final id =
        fromText ??
        _chosenId ??
        (_candidates.isEmpty ? null : _candidates.first.id);
    final next = (id, parsed.content);
    if (next != _state.value) _state.value = next;
  }

  void _choose(Note note) {
    _chosenId = note.id;
    _state.value = (note.id, _state.value.$2);
  }

  Note? _noteOf(String? id) {
    for (final n in _candidates) {
      if (n.id == id) return n;
    }
    return null;
  }

  void _apply() {
    _onText(_bar.currentState?.text ?? '');
    final (id, content) = _state.value;
    final note = _noteOf(id);
    final repo = ref.read(notesRepositoryProvider);
    if (note == null || repo == null || content.trim().isEmpty) return;
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
    Navigator.of(context).pop();
    if (result.fields.isEmpty) {
      messenger.showMessage(l10n.quickDropNothingNew(title));
      return;
    }
    // Geri al: yalnız dokunulan alan eski hâline yazılır.
    final undo = note.type == NoteType.text
        ? <String, dynamic>{'body': note.body}
        : <String, dynamic>{
            'items': [for (final i in note.items) i.toMap()],
          };
    messenger
      ..hideCurrentSnackBar()
      ..showMessage(
        note.type == NoteType.text
            ? l10n.quickDropAddedText(title)
            : l10n.quickDropAdded(result.added, title),
        action: SnackBarAction(
          label: l10n.undo,
          onPressed: () => repo.updateFields(note.id, undo),
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
              // "Söyle, eklensin": konuşma kendiliğinden bitince eklenir.
              onSpeechEnd: _apply,
              onItems: (_) {},
            ),
            Text(l10n.quickDropTarget, style: text.meta),
            SizedBox(
              height: AppSpace.xxxl + AppSpace.m,
              child: ValueListenableBuilder<(String?, String)>(
                valueListenable: _state,
                builder: (context, state, _) {
                  // Seçili hedef hep başta görünür.
                  final shown = [
                    ?_noteOf(state.$1),
                    for (final n in _candidates.take(12))
                      if (n.id != state.$1) n,
                  ];
                  return ListView.separated(
                    key: const ValueKey('quick-drop-targets'),
                    scrollDirection: Axis.horizontal,
                    itemCount: shown.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: AppSpace.s),
                    itemBuilder: (context, i) {
                      final n = shown[i];
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
                          showCheckmark: false,
                          selected: n.id == state.$1,
                          onSelected: (_) => _choose(n),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpace.s),
            ValueListenableBuilder<(String?, String)>(
              valueListenable: _state,
              builder: (context, state, _) => FilledButton.icon(
                key: const ValueKey('quick-drop-add'),
                onPressed: state.$1 == null || state.$2.trim().isEmpty
                    ? null
                    : _apply,
                icon: const Icon(Icons.add),
                label: Text(
                  state.$2.trim().isEmpty
                      ? l10n.quickDropAdd
                      : '${l10n.quickDropAdd} · ${state.$2.trim()}',
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
