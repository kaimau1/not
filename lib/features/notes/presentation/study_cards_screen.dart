import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../../ai/data/gemini_service.dart';
import '../data/notes_repository.dart';
import '../domain/note.dart';
import '../domain/study_card.dart';
import 'note_link_ui.dart' show noteLinkLabel;

/// Bugün tekrar edilecek kartlar (F18.19): bütün notlardan, kilitli ve
/// çöptekiler hariç.
List<({Note note, StudyCard card})> dueCards(
  Iterable<Note> notes,
  DateTime now,
) => [
  for (final n in notes)
    if (!n.locked && n.deletedAt == null)
      for (final c in n.cards)
        if (c.isDue(now)) (note: n, card: c),
];

/// "Bugünün kartları" ekranı: soru → "Cevabı göster" → Tekrar/Zor/İyi/Kolay.
class StudyCardsScreen extends ConsumerStatefulWidget {
  const StudyCardsScreen({super.key});

  @override
  ConsumerState<StudyCardsScreen> createState() => _StudyCardsScreenState();
}

class _StudyCardsScreenState extends ConsumerState<StudyCardsScreen> {
  bool _revealed = false;
  int _done = 0;

  void _grade(Note note, StudyCard card, CardGrade grade) {
    final reviewed = reviewCard(card, grade, DateTime.now());
    ref.read(notesRepositoryProvider)?.updateFields(note.id, {
      'cards': [
        for (final c in note.cards) (c.id == card.id ? reviewed : c).toMap(),
      ],
    });
    setState(() {
      _revealed = false;
      _done++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final notes = ref.watch(notesStreamProvider).value ?? const <Note>[];
    final due = dueCards(notes, DateTime.now());
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.studyCardsTitle)),
      body: due.isEmpty
          ? EmptyState(
              icon: Icons.style_outlined,
              title: _done > 0 ? l10n.studyCardsDone : l10n.studyCardsEmpty,
              subtitle: l10n.studyCardsEmptyInfo,
            )
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.studyCardsLeft(due.length),
                      style: theme.textTheme.labelLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      noteLinkLabel(due.first.note, l10n.remindersUntitled),
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SelectableText(
                                  due.first.card.question,
                                  style: theme.textTheme.titleLarge,
                                ),
                                if (_revealed) ...[
                                  const Divider(height: 32),
                                  SelectableText(
                                    due.first.card.answer,
                                    style: theme.textTheme.bodyLarge,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (!_revealed)
                      FilledButton(
                        key: const ValueKey('study-reveal'),
                        onPressed: () => setState(() => _revealed = true),
                        child: Text(l10n.studyCardsReveal),
                      )
                    else
                      Row(
                        children: [
                          for (final g in CardGrade.values) ...[
                            Expanded(
                              child: OutlinedButton(
                                key: ValueKey('study-grade-${g.name}'),
                                onPressed: () =>
                                    _grade(due.first.note, due.first.card, g),
                                child: Text(
                                  switch (g) {
                                    CardGrade.again => l10n.studyGradeAgain,
                                    CardGrade.hard => l10n.studyGradeHard,
                                    CardGrade.good => l10n.studyGradeGood,
                                    CardGrade.easy => l10n.studyGradeEasy,
                                  },
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            if (g != CardGrade.easy) const SizedBox(width: 6),
                          ],
                        ],
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

/// Nottan kart üret (editör ⋮): AI üretir, kullanıcı onaylar, nota yazılır.
Future<void> generateCardsForNote(
  BuildContext context,
  WidgetRef ref,
  Note note,
) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  messenger.showMessage(l10n.studyCardsGenerating);
  List<({String q, String a})> made;
  try {
    made = await ref.read(geminiServiceProvider).generateStudyCards(note);
  } on GeminiException catch (e) {
    messenger.showMessage(e.message);
    return;
  } catch (e) {
    messenger.showMessage(l10n.studyCardsFailed);
    return;
  }
  if (made.isEmpty) {
    messenger.showMessage(l10n.studyCardsFailed);
    return;
  }
  if (!context.mounted) return;
  final ok = await showAppSheet<bool>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              l10n.studyCardsPreview(made.length),
              style: Theme.of(ctx).textTheme.titleMedium,
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final c in made)
                  ListTile(title: Text(c.q), subtitle: Text(c.a)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.studyCardsSave),
            ),
          ),
        ],
      ),
    ),
  );
  if (ok != true) return;
  final stamp = DateTime.now().microsecondsSinceEpoch;
  final cards = [
    ...note.cards,
    for (var i = 0; i < made.length; i++)
      StudyCard(id: 'c$stamp$i', question: made[i].q, answer: made[i].a),
  ];
  ref.read(notesRepositoryProvider)?.updateFields(note.id, {
    'cards': [for (final c in cards) c.toMap()],
  });
  messenger.showMessage(l10n.studyCardsSaved(made.length));
}
