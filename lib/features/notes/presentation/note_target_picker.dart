import '../../../app/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../data/notes_repository.dart';
import '../domain/note.dart';
import 'note_card.dart';
import '../../../core/widgets/press_scale.dart';

/// **"NOTA EKLE" SEÇİCİSİ** (2026-11-08, yeniden kullanılabilir): bir metnin
/// (Gmail'de seçilen kısım, ileride paylaşılan yazı…) HANGİ NOTA gideceğini
/// seçtirir. Tek ekran: en üstte boş YENİ not kartı, altında bütün notların
/// KÜÇÜLTÜLMÜŞ asıl kartları ([NoteCard], yalnız görsel — dokunuş seçer).
///
/// Sonuç [NoteTarget]: `note == null` → yeni not; aksi hâlde o nota ekle.
/// İptal (geri) → null.
class NoteTarget {
  const NoteTarget.newNote() : note = null;
  const NoteTarget.existing(Note this.note);
  final Note? note;
}

Future<NoteTarget?> showNoteTargetPicker(
  BuildContext context, {
  String? preview,
  String? excludeId,
}) => Navigator.of(context).push<NoteTarget>(
  MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => NoteTargetPicker(preview: preview, excludeId: excludeId),
  ),
);

class NoteTargetPicker extends ConsumerWidget {
  const NoteTargetPicker({super.key, this.preview, this.excludeId});

  /// Eklenecek metnin başı (yeni not kartında gösterilir).
  final String? preview;
  final String? excludeId;

  /// Kart genişliği (mantıksal); hücreye sığacak kadar küçültülür.
  static const _cardWidth = 190.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final notes = [
      for (final n in ref.watch(notesStreamProvider).value ?? const <Note>[])
        if (n.id != excludeId &&
            n.deletedAt == null &&
            n.archivedAt == null &&
            !n.locked)
          n,
    ]..sort(
        (a, b) => (b.updatedAt ?? DateTime(0)).compareTo(
          a.updatedAt ?? DateTime(0),
        ),
      );
    final text = (preview ?? '').trim();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.addToNoteTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Material(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.l),
              child: InkWell(
                key: const ValueKey('target-new-note'),
                borderRadius: BorderRadius.circular(AppRadius.l),
                onTap: () =>
                    Navigator.of(context).pop(const NoteTarget.newNote()),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(Icons.add, color: scheme.onPrimaryContainer),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.addToNewNote,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(color: scheme.onPrimaryContainer),
                            ),
                            if (text.isNotEmpty)
                              Text(
                                text,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: scheme.onPrimaryContainer,
                                    ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: notes.isEmpty
                ? Center(child: Text(l10n.addToNoteEmpty))
                : GridView.builder(
                    key: const ValueKey('target-grid'),
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 130,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 0.8,
                        ),
                    itemCount: notes.length,
                    itemBuilder: (context, i) {
                      final n = notes[i];
                      // Basma tepkisi (F78.4): ana ekran kartıyla aynı.
                      return PressScale(
                        key: ValueKey('target-${n.id}'),
                        child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () =>
                            Navigator.of(context).pop(NoteTarget.existing(n)),
                        // Kart asıl boyutunda kurulur, hücreye küçültülür;
                        // dokunuşlar kartın değil hücrenin.
                        child: IgnorePointer(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.m),
                            child: FittedBox(
                              fit: BoxFit.fitWidth,
                              alignment: Alignment.topCenter,
                              child: SizedBox(
                                width: _cardWidth,
                                child: NoteCard(note: n, showFolder: false),
                              ),
                            ),
                          ),
                        ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
