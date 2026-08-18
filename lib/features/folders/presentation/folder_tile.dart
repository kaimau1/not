import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../notes/presentation/notes_providers.dart';
import '../data/folders_repository.dart';
import '../domain/note_folder.dart';
import 'folder_screen.dart';
import 'folder_sheets.dart';

/// **ANA EKRANDAKİ KLASÖR KAROSU.**
///
/// Kullanıcı isteği 2026-08-18: "klasör dashboard'ta bir not gibi yer kaplar
/// ama görüntüsü klasör gibidir." Karo not kartıyla aynı ızgarada, aynı
/// genişlikte durur; ama kart değil KLASÖRDÜR — üstünde sekmesi olan bir
/// kağıt cebi gibi çizilir ve içindeki not sayısını söyler.
///
/// Dokunmak klasörün kendi sayfasını açar ([FolderScreen]); uzun basmak
/// yönetim levhasını (yeniden adlandır / gizle / sil).
class FolderTile extends ConsumerWidget {
  const FolderTile({super.key, required this.folder});

  final NoteFolder folder;

  /// Karonun sabit yüksekliği. Not kartları içeriğe göre uzuyor; klasörler
  /// eşit boyda kalır — ızgaranın ilk satırı düzgün bir raf gibi görünsün.
  static const double height = 92;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final count = ref
        .watch(folderNotesProvider(folder.id))
        .maybeWhen(data: (notes) => notes.length, orElse: () => 0);
    return SizedBox(
      height: height,
      child: Material(
        color: scheme.secondaryContainer,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(6),
          topRight: Radius.circular(14),
          bottomLeft: Radius.circular(14),
          bottomRight: Radius.circular(14),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => FolderScreen.open(context, folder.id),
          onLongPress: () => showFolderActionsSheet(context, ref, folder),
          child: Stack(
            children: [
              // Klasör SEKMESİ: karoyu "kart" olmaktan çıkaran tek çizgi.
              Positioned(
                left: 0,
                top: 0,
                child: Container(
                  width: 46,
                  height: 12,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.55),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(6),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 20, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          folder.iconData,
                          size: 20,
                          color: scheme.onSecondaryContainer,
                        ),
                        if (folder.hidden) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.visibility_off_outlined,
                            size: 14,
                            color: scheme.onSecondaryContainer.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ],
                        const Spacer(),
                        Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSecondaryContainer.withValues(
                              alpha: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      folder.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// **BİR ARKADAŞIN BENİMLE PAYLAŞTIĞI KLASÖR** — [FolderTile]'ın ikizi.
///
/// Kullanıcı isteği 2026-08-18: "ortak notlar klasörü kişiler bağlanır
/// notları ortak görür." Görsel olarak neredeyse aynı, tek fark sekmenin
/// rengi ve köşedeki kişi rozeti — kullanıcı bakışta "bu benim değil,
/// paylaşılan" ayrımını yapabilsin. Uzun basış YOK: paylaşımı kaldırma
/// yetkisi yalnız sahipte (bkz. `showFolderActionsSheet`), burada tek eylem
/// açmak.
class SharedFolderTile extends ConsumerWidget {
  const SharedFolderTile({super.key, required this.share});

  final SharedFolderRef share;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final icon = NoteFolder.iconChoices[share.icon] ?? Icons.folder_outlined;
    final count = ref
        .watch(
          sharedFolderNotesProvider((
            ownerId: share.ownerId,
            folderId: share.folderId,
          )),
        )
        .maybeWhen(data: (notes) => notes.length, orElse: () => 0);
    return SizedBox(
      height: FolderTile.height,
      child: Material(
        color: scheme.tertiaryContainer,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(6),
          topRight: Radius.circular(14),
          bottomLeft: Radius.circular(14),
          bottomRight: Radius.circular(14),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => FolderScreen.open(
            context,
            share.folderId,
            ownerId: share.ownerId,
          ),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                child: Container(
                  width: 46,
                  height: 12,
                  decoration: BoxDecoration(
                    color: scheme.tertiary.withValues(alpha: 0.55),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(6),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: Icon(
                  Icons.people_alt_outlined,
                  size: 14,
                  color: scheme.onTertiaryContainer.withValues(alpha: 0.7),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 20, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(icon, size: 20, color: scheme.onTertiaryContainer),
                        const Spacer(),
                        Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: scheme.onTertiaryContainer.withValues(
                              alpha: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      share.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: scheme.onTertiaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Yeni klasör" karosu — klasör rafının sonunda durur.
///
/// Klasör oluşturma eskiden yalnız Süz levhasının içindeydi; klasör artık bir
/// süzgeç değil bir YER olduğu için girişi de durduğu yerde olmalı.
class NewFolderTile extends ConsumerWidget {
  const NewFolderTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: FolderTile.height,
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () async {
            final id = await showFolderEditorDialog(context, ref);
            // Yeni klasör hemen açılır: kullanıcı "oluştu mu" diye aramasın.
            if (id != null && context.mounted) {
              await FolderScreen.open(context, id);
            }
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.create_new_folder_outlined,
                size: 22,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(height: 6),
              Text(
                context.l10n.newFolder,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
