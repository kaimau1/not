import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../data/notes_repository.dart';
import '../domain/note.dart';
import 'notes_providers.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/undo_snackbar.dart';

/// Kopya notlar levhası — Yapay Zeka sayfasındaki "Kopyaları temizle".
///
/// Toplu silme YOK demedik ama tek düğmeyle her şeyi çöpe atmıyoruz: kümeler
/// önce GÖSTERİLİR, kullanıcı hangisinin gerçekten kopya olduğunu görür.
/// Benzerlik ölçümü yerel ve yaklaşık (bkz. note_similarity.dart); körlemesine
/// silmek yanlış eşleşmede veri kaybı demek olurdu. Silinenler çöp kutusuna
/// gider (30 gün geri alınabilir), kalıcı silme değil.
Future<void> showDuplicatesSheet(BuildContext context) =>
    showAppSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.8,
      ),
      builder: (_) => const _DuplicatesSheet(),
    );

class _DuplicatesSheet extends ConsumerWidget {
  const _DuplicatesSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final groups = ref.watch(duplicateNotesProvider);

    if (groups.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.done_all, size: 40, color: scheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(l10n.aiTaskDuplicatesInfo(0), textAlign: TextAlign.center),
          ],
        ),
      );
    }

    // Silinecekler: her kümenin İLKİ (en eski) korunur.
    final removable = [for (final group in groups) ...group.skip(1)];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.duplicatesTitle,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.duplicatesHint,
                style: TextStyle(
                  fontSize: 12.5,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Flexible(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            itemCount: groups.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) =>
                _GroupCard(group: groups[index], scheme: scheme),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                icon: const Icon(Icons.delete_sweep_outlined, size: 20),
                label: Text(l10n.duplicatesDeleteAll),
                onPressed: () {
                  final repo = ref.read(notesRepositoryProvider);
                  if (repo == null) return;
                  final ids = [for (final note in removable) note.id];
                  for (final id in ids) {
                    repo.softDelete(id);
                  }
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      timedSnackBar(
                        content: Text(l10n.duplicatesDone(ids.length)),
                        // Toplu silmede yanlış eşleşme en pahalı hata:
                        // çöpten tek tek çıkarmak yerine tek dokunuş.
                        action: SnackBarAction(
                          label: l10n.undo,
                          onPressed: () {
                            for (final id in ids) {
                              repo.restore(id);
                            }
                          },
                        ),
                      ),
                    );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Tek bir kopya kümesi: ilk satır korunacak not, altındakiler silinecekler.
class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.group, required this.scheme});

  final List<Note> group;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < group.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  i == 0 ? Icons.push_pin_outlined : Icons.delete_outline,
                  size: 16,
                  color: i == 0 ? scheme.primary : scheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    group[i].displayTitle.trim().isNotEmpty
                        ? group[i].displayTitle
                        : group[i].toPlainText().replaceAll('\n', ' '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: i == 0
                          ? scheme.onSurface
                          : scheme.onSurfaceVariant,
                      decoration: i == 0 ? null : TextDecoration.lineThrough,
                    ),
                  ),
                ),
                if (i == 0) ...[
                  const SizedBox(width: 8),
                  Text(
                    l10n.duplicatesKeepBadge,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: scheme.primary,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
