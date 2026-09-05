import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../notes/presentation/notes_providers.dart';
import '../data/folder_activity.dart';
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
    // PAYLAŞILAN klasörde okunmamış hareket rozeti (kullanıcı isteği
    // 2026-09-04). Paylaşılmamış klasörde karşı taraf yok — hiç sorulmaz.
    final unread = folder.isShared
        ? ref.watch(
            folderUnreadProvider((
              ownerId: folder.ownerId,
              folderId: folder.id,
            )),
          )
        : 0;
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
              if (unread > 0) FolderUnreadBadge(count: unread),
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
    final unread = ref.watch(
      folderUnreadProvider((
        ownerId: share.ownerId,
        folderId: share.folderId,
      )),
    );
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
              if (unread > 0)
                FolderUnreadBadge(count: unread)
              else
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


/// **KOMPAKT KLASÖR ÇİPİ** — kullanıcı isteği 2026-08-18: "klasörler ana
/// ekranda çok fazla yer kaplıyor, farklı bir çözüm bulalım."
///
/// [FolderTile]'ın (92 px'lik karo) yatay şeritteki karşılığı: simge + ad +
/// not sayısı, ~36 px yüksekliğinde. Aynı eylemler — dokun aç, uzun bas
/// yönet — böylece iki görünüm arasında öğrenilen şey değişmez.
class FolderChip extends ConsumerWidget {
  const FolderChip({super.key, required this.folder});

  final NoteFolder folder;

  /// Şeridin yüksekliği; kaydırma alanının sabit kalması için tek yerde.
  static const double stripHeight = 40;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final count = ref
        .watch(folderNotesProvider(folder.id))
        .maybeWhen(data: (notes) => notes.length, orElse: () => 0);
    return _ChipShell(
      background: scheme.secondaryContainer,
      foreground: scheme.onSecondaryContainer,
      icon: folder.iconData,
      label: folder.name,
      count: count,
      trailingIcon: folder.hidden ? Icons.visibility_off_outlined : null,
      onTap: () => FolderScreen.open(context, folder.id),
      onLongPress: () => showFolderActionsSheet(context, ref, folder),
    );
  }
}

/// Paylaşılan klasörün çipi — [SharedFolderTile]'ın şerit hâli.
class SharedFolderChip extends ConsumerWidget {
  const SharedFolderChip({super.key, required this.share});

  final SharedFolderRef share;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    // Yalnız YAZMA yetkisinde not listesi okunamaz (kural reddeder); sayı
    // sorulmaz, yerine ortak klasör rozeti yeter.
    final count = share.role.canRead
        ? ref
              .watch(
                sharedFolderNotesProvider((
                  ownerId: share.ownerId,
                  folderId: share.folderId,
                )),
              )
              .maybeWhen(data: (notes) => notes.length, orElse: () => 0)
        : null;
    return _ChipShell(
      background: scheme.tertiaryContainer,
      foreground: scheme.onTertiaryContainer,
      icon: share.iconData,
      label: share.name,
      count: count,
      trailingIcon: Icons.people_alt_outlined,
      onTap: () => FolderScreen.open(
        context,
        share.folderId,
        ownerId: share.ownerId,
      ),
    );
  }
}

/// "Yeni klasör" çipi — şeridin sonunda.
class NewFolderChip extends ConsumerWidget {
  const NewFolderChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return _ChipShell(
      background: Colors.transparent,
      foreground: scheme.onSurfaceVariant,
      border: scheme.outlineVariant,
      icon: Icons.create_new_folder_outlined,
      label: context.l10n.newFolder,
      onTap: () async {
        final id = await showFolderEditorDialog(context, ref);
        if (id != null && context.mounted) {
          await FolderScreen.open(context, id);
        }
      },
    );
  }
}

/// Üç çipin ortak gövdesi: tek yerde biçim, üç yerde aynı görünüm.
class _ChipShell extends StatelessWidget {
  const _ChipShell({
    required this.background,
    required this.foreground,
    required this.icon,
    required this.label,
    required this.onTap,
    this.count,
    this.trailingIcon,
    this.border,
    this.onLongPress,
  });

  final Color background;
  final Color foreground;
  final Color? border;
  final IconData icon;
  final String label;
  final int? count;
  final IconData? trailingIcon;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: border == null
            ? BorderSide.none
            : BorderSide(color: border!),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17, color: foreground),
              const SizedBox(width: 6),
              // Uzun klasör adları şeridi ele geçirmesin: çip en fazla
              // 150 px, ad taşarsa kısalır.
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 150),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: foreground,
                  ),
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 6),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: foreground.withValues(alpha: 0.75),
                  ),
                ),
              ],
              if (trailingIcon != null) ...[
                const SizedBox(width: 5),
                Icon(
                  trailingIcon,
                  size: 13,
                  color: foreground.withValues(alpha: 0.75),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


/// **OKUNMAMIŞ ROZETİ** — klasör karosunun sağ ÜST köşesinde duran, klasik
/// Android bildirim sayacı (kullanıcı isteği 2026-09-04: "o klasör
/// simgesinin sağ üstünde 1, 2 gibi rakam yazabilir").
///
/// Tavanı [kFolderBadgeMax]: iki haneden sonrası karoyu kaplar ve zaten
/// "çok" demenin başka bir yolu yok.
class FolderUnreadBadge extends StatelessWidget {
  const FolderUnreadBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = count > kFolderBadgeMax ? '$kFolderBadgeMax+' : '$count';
    return Positioned(
      top: 4,
      right: 4,
      child: Container(
        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
        padding: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: scheme.error,
          borderRadius: BorderRadius.circular(9),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            height: 1.1,
            fontWeight: FontWeight.w700,
            color: scheme.onError,
          ),
        ),
      ),
    );
  }
}
