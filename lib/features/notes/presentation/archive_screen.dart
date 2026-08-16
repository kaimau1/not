import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/widgets/empty_state.dart';
import 'note_card.dart';
import 'notes_providers.dart';

/// Arşivlenen notlar. Karta dokununca editör açılır; menüden arşivden
/// çıkarılabilir veya silinebilir.
class ArchiveScreen extends ConsumerWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final archived = ref.watch(archivedNotesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.archiveTitle)),
      body: archived.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline,
          title: l10n.genericError(e.toString()),
        ),
        data: (notes) {
          if (notes.isEmpty) {
            return EmptyState(
              icon: Icons.archive_outlined,
              title: l10n.archiveEmpty,
            );
          }
          // ANA EKRANLA AYNI KART (kullanıcı bulgusu 2026-08-16: "arşivdeki
          // notlar açılmıyor, aynı formatta açılmalı"). Burada notlar tek
          // satırlık `ListTile`larla listeleniyordu: içerik önizlemesi,
          // renk, ek rozeti ve kart menüsü yoktu, dokunma hedefi de ana
          // ekrandakinden başkaydı. Artık aynı `NoteCard` — açılış yolu,
          // kilit denetimi ve arşiv defterine yönlendirme dahil her şey ana
          // ekrandakiyle birebir aynı koddan geçiyor.
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: notes.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: NoteCard(note: notes[index]),
            ),
          );
        },
      ),
    );
  }
}
