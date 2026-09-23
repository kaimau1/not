import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../notes/data/note_shares_repository.dart';
import '../../notes/presentation/notes_providers.dart';
import '../../notes/presentation/shared_notes_screen.dart';
import '../data/folder_activity.dart';
import '../data/folders_repository.dart';
import '../domain/note_folder.dart';
import 'folder_screen.dart';
import 'folder_sheets.dart';

/// **ANA EKRANDAKİ KLASÖR KAROSU.**
///
/// Kullanıcı isteği 2026-08-18: "klasör dashboard'ta bir not gibi yer kaplar
/// ama görüntüsü klasör gibidir."
///
/// 2026-09-23 YENİDEN ÇİZİM (kullanıcı: "klasörlerin görünümünden memnun
/// değilim"): eskiden her karo aynı bej blok + sekmeydi; altı klasör yan
/// yana tek bir renk duvarı oluyordu. Artık sade bir kart ve klasörü
/// TANITAN renkli bir simge kutusu (bkz. [NoteFolder.accent]) — renk ve
/// simge bakışta ayırt ettiriyor, zemin notların arasında bağırmıyor.
///
/// Dokunmak klasörün kendi sayfasını açar ([FolderScreen]); uzun basmak
/// yönetim levhasını (yeniden adlandır / renk / gizle / sil).
class FolderTile extends ConsumerWidget {
  const FolderTile({super.key, required this.folder});

  final NoteFolder folder;

  /// Karonun sabit yüksekliği. Not kartları içeriğe göre uzuyor; klasörler
  /// eşit boyda kalır — ızgaranın ilk satırı düzgün bir raf gibi görünsün.
  static const double height = 76;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
    return _FolderTileBody(
      accent: folder.accent,
      icon: folder.iconData,
      name: folder.name,
      count: count,
      unread: unread,
      hidden: folder.hidden,
      shared: folder.isShared,
      onTap: () => FolderScreen.open(context, folder.id),
      onLongPress: () => showFolderActionsSheet(context, ref, folder),
    );
  }
}

/// **BİR ARKADAŞIN BENİMLE PAYLAŞTIĞI KLASÖR** — [FolderTile]'ın ikizi.
/// Köşedeki kişi simgesi "bu benim değil, paylaşılan" ayrımını yapar. Uzun
/// basış YOK: paylaşımı yönetme yetkisi yalnız sahipte.
class SharedFolderTile extends ConsumerWidget {
  const SharedFolderTile({super.key, required this.share});

  final SharedFolderRef share;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
    return _FolderTileBody(
      accent: folderAccent(share.folderId),
      icon: share.iconData,
      name: share.name,
      count: count,
      unread: unread,
      shared: true,
      onTap: () =>
          FolderScreen.open(context, share.folderId, ownerId: share.ownerId),
    );
  }
}

/// Karonun ortak gövdesi: renkli simge kutusu + ad + not sayısı.
class _FolderTileBody extends StatelessWidget {
  const _FolderTileBody({
    required this.accent,
    required this.icon,
    required this.name,
    required this.count,
    required this.onTap,
    this.unread = 0,
    this.hidden = false,
    this.shared = false,
    this.onLongPress,
  });

  final Color accent;
  final IconData icon;
  final String name;
  final int count;
  final int unread;
  final bool hidden;
  final bool shared;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: FolderTile.height,
      child: Material(
        color: scheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    FolderIconBox(accent: accent, icon: icon, size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                context.l10n.folderNoteCount(count),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                              if (shared) ...[
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.people_alt_outlined,
                                  size: 13,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ],
                              if (hidden) ...[
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.visibility_off_outlined,
                                  size: 13,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (unread > 0) FolderUnreadBadge(count: unread),
            ],
          ),
        ),
      ),
    );
  }
}

/// Klasörün renkli simge kutusu — karoda, çipte ve Klasörler sayfasında
/// aynı imza. Zemin vurgunun açık tonu, simge vurgunun kendisi: hem açık
/// hem koyu temada okunur.
class FolderIconBox extends StatelessWidget {
  const FolderIconBox({
    super.key,
    required this.accent,
    required this.icon,
    this.size = 40,
  });

  final Color accent;
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: dark ? 0.28 : 0.18),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(icon, size: size * 0.52, color: accent),
    );
  }
}

/// "Yeni klasör" karosu — klasör rafının sonunda durur.
///
/// Klasör oluşturma eskiden yalnız Süz levhasının içindeydi; klasör artık bir
/// süzgeç değil bir YER olduğu için girişi de durduğu yerde olmalı.
class NewFolderTile extends ConsumerWidget {
  const NewFolderTile({super.key, this.height = FolderTile.height});

  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: height,
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
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
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.create_new_folder_outlined,
                  size: 22,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    context.l10n.newFolder,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
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
    final count = ref
        .watch(folderNotesProvider(folder.id))
        .maybeWhen(data: (notes) => notes.length, orElse: () => 0);
    return _ChipShell(
      accent: folder.accent,
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
      accent: folderAccent(share.folderId),
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

/// **BENİMLE PAYLAŞILAN NOTLAR** çipi — ortak notlar (bkz. [NoteShare])
/// klasör değil ama aynı rafta durur: "başkasının bana açtığı şeyler" tek
/// yerde toplansın. Paylaşılan not yoksa hiç çizilmez; şeritte ölü bir çip
/// kalmasın.
class SharedNotesChip extends ConsumerWidget {
  const SharedNotesChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(
      sharedNotesWithMeProvider.select((s) => s.value?.length ?? 0),
    );
    if (count == 0) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 6),
      child: _ChipShell(
        accent: scheme.primary,
        icon: Icons.people_alt_outlined,
        label: context.l10n.sharedWithMe,
        count: count,
        onTap: () => SharedNotesScreen.open(context),
      ),
    );
  }
}

/// "Yeni klasör" çipi — şeridin sonunda.
class NewFolderChip extends ConsumerWidget {
  const NewFolderChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _ChipShell(
      subtle: true,
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

/// Çiplerin ortak gövdesi: tek yerde biçim, her yerde aynı görünüm.
///
/// 2026-09-23 (kullanıcı: "klasörlerin görünümünden memnun değilim"): çipler
/// eskiden dolgun bej bloklardı ve şerit, notlardan daha çok göze
/// batıyordu. Artık sade konturlu hap + klasörün RENGİNDE küçük simge
/// kutusu: şerit sakinleşti, klasörler renkle ayırt ediliyor.
class _ChipShell extends StatelessWidget {
  const _ChipShell({
    required this.icon,
    required this.label,
    required this.onTap,
    this.accent,
    this.count,
    this.trailingIcon,
    this.subtle = false,
    this.onLongPress,
  });

  /// Simge kutusunun rengi; null ise simge kutusuz, soluk çizilir.
  final Color? accent;
  final IconData icon;
  final String label;
  final int? count;
  final IconData? trailingIcon;

  /// "Yeni klasör" gibi eylem çipi: zeminsiz, yalnız kontur.
  final bool subtle;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurfaceVariant;
    final accent = this.accent;
    return Material(
      color: subtle ? Colors.transparent : scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: subtle ? 1 : 0.6),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            accent == null ? 10 : 4,
            0,
            10,
            0,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (accent != null)
                FolderIconBox(accent: accent, icon: icon, size: 24)
              else
                Icon(icon, size: 17, color: muted),
              const SizedBox(width: 7),
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
                    fontWeight: FontWeight.w500,
                    color: subtle ? muted : scheme.onSurface,
                  ),
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 6),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: muted,
                  ),
                ),
              ],
              if (trailingIcon != null) ...[
                const SizedBox(width: 5),
                Icon(trailingIcon, size: 13, color: muted),
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
