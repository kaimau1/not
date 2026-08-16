import 'package:flutter/material.dart';

import '../../../../core/l10n_ext.dart';

/// Not editörünün ⋮ menüsü — İKİ SÜTUNLU levha.
///
/// **Neden açılır menü değil** (kullanıcı ekran görüntüsü 2026-08-09: "bu 3
/// nokta alanı düzenlenmeli"): menü on maddelik tek sütunlu bir `PopupMenu`
/// idi ve ekranın yarısından fazlasını, notun tam ortasına inen bir sütun
/// hâlinde kaplıyordu; alttaki maddeler (Ayarlar, Sil) sayfanın dibine kadar
/// uzuyor, "Paylaş" ile "Sil" arasında dört madde fark oluyordu. Ana ekrandaki
/// kart menüsü ([showNoteActionsSheet]) aynı işi çoktandır iki sütunlu bir
/// levhada yapıyor; editör de artık aynı dili konuşuyor: hepsi tek bakışta
/// görünür, levha yarı yükseklikte kalır ve iki yüzey birbirine benzer.
///
/// Dönen değer seçilen eylemin anahtarıdır; iptalde null.
Future<String?> showNoteEditorMenu(
  BuildContext context, {
  required bool pinned,
  required bool starred,
  required bool locked,
  required bool archived,
  required bool isList,
  required bool twoColumns,
  required bool hasFloatingImages,
  required bool hasAttachments,
}) {
  final l10n = context.l10n;
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    // Büyük yazı ölçeğinde ızgara varsayılan tavanı aşabilir; kaydırma ağı.
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        child: _MenuGrid(
          l10n: l10n,
          pinned: pinned,
          starred: starred,
          locked: locked,
          archived: archived,
          isList: isList,
          twoColumns: twoColumns,
          hasFloatingImages: hasFloatingImages,
          hasAttachments: hasAttachments,
        ),
      ),
    ),
  );
}

class _MenuGrid extends StatelessWidget {
  const _MenuGrid({
    required this.l10n,
    required this.pinned,
    required this.starred,
    required this.locked,
    required this.archived,
    required this.isList,
    required this.twoColumns,
    required this.hasFloatingImages,
    required this.hasAttachments,
  });

  final AppLocalizations l10n;
  final bool pinned;
  final bool starred;
  final bool locked;
  final bool archived;

  /// Not LİSTE tipinde mi (checklist / sıralı)? Listeye özgü maddeler
  /// (metne çevir, sütun sayısı, maddeleri sırala) yalnız o zaman çizilir —
  /// metin notunda ölü madde durmasın.
  final bool isList;

  /// Liste iki sütunda mı gösteriliyor (bkz. `Note.listColumns`).
  final bool twoColumns;

  /// Notta SAYFADA YÜZEN (metnin arasına konmuş) görsel var mı? "Görselleri
  /// eke dönüştür" maddesi yalnız o zaman anlamlı.
  final bool hasFloatingImages;

  /// Notun herhangi bir eki var mı? "Arşiv defterine kopyala" yalnız o zaman
  /// anlamlı — kopyalanacak dosya yoksa madde ölü durur.
  final bool hasAttachments;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // (anahtar, etiket, simge) — sıra sık kullanımdan seyreğe.
    final actions = <(String, String, IconData)>[
      (
        'pin',
        pinned ? l10n.unpin : l10n.pin,
        pinned ? Icons.push_pin : Icons.push_pin_outlined,
      ),
      (
        'star',
        starred ? l10n.unstar : l10n.star,
        starred ? Icons.star : Icons.star_outline,
      ),
      // LİSTEYE ÖZGÜ maddeler (kullanıcı istekleri 2026-08-16). Hepsi
      // yerel ve anında: hiçbiri model çağırmaz.
      if (isList) ...[
        ('toText', l10n.convertToText, Icons.notes_outlined),
        ('sortItems', l10n.sortItems, Icons.sort),
        (
          'columns',
          twoColumns ? l10n.listOneColumn : l10n.listTwoColumns,
          twoColumns ? Icons.view_agenda_outlined : Icons.view_column_outlined,
        ),
      ] else
        ('toList', l10n.convertToList, Icons.checklist),
      // Metin içi görselleri TOPLUCA ek şeridine indirir (kullanıcı isteği
      // 2026-08-16: "metin içi görselleri eke dönüştürme butonu"). Görsel
      // görsel yapılabiliyordu (görselin kendi menüsündeki "Ek yap") ama on
      // görselli bir notta bu on ayrı işlem demekti.
      if (hasFloatingImages)
        ('imagesToFiles', l10n.imagesToAttachments, Icons.attach_file),
      // NOT İÇİ ARAMA (kullanıcı isteği 2026-08-16). Ana ekrandaki arama
      // notlar ARASINDA çalışıyor; bu, tek notun içine bakar.
      ('search', l10n.noteSearchTitle, Icons.manage_search),
      // Ekleri bir arşiv defterine KOPYALAR (kullanıcı isteği 2026-08-16):
      // kaynak not silinse bile kopya sağlam kalır.
      if (hasAttachments)
        ('toArchive', l10n.archiveCopyHere, Icons.inventory_2_outlined),
      ('share', l10n.share, Icons.share_outlined),
      // "PDF olarak dışa aktar" DEĞİL: belge notlarında çıktı balonlu PDF de
      // olabiliyor, metin notlarında Word de üretiliyor. Etiket artık yolu
      // değil işi anlatıyor (bkz. not editöründeki `_export`).
      ('export', l10n.exportTitle, Icons.ios_share_outlined),
      ('listen', l10n.listenToNote, Icons.headphones_outlined),
      (
        'lock',
        locked ? l10n.unlockNote : l10n.lockNote,
        locked ? Icons.lock_open_outlined : Icons.lock_outline,
      ),
      (
        'archive',
        archived ? l10n.unarchive : l10n.archive,
        archived ? Icons.unarchive_outlined : Icons.archive_outlined,
      ),
      ('clear', l10n.clearNote, Icons.backspace_outlined),
      ('settings', l10n.settings, Icons.settings_outlined),
    ];

    Widget tile(
      String action,
      String label,
      IconData icon, {
      bool danger = false,
    }) {
      final color = danger ? scheme.error : scheme.onSurface;
      return Material(
        color: danger
            ? scheme.errorContainer.withValues(alpha: 0.4)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.pop(context, action),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              children: [
                Icon(icon, size: 22, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: color),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // İki sütun: 16 kenar dolgusu + 8 sütun aralığı.
        final cellWidth = (constraints.maxWidth - 40) / 2;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (action, label, icon) in actions)
                    SizedBox(
                      width: cellWidth,
                      child: tile(action, label, icon),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Yıkıcı işlem tek başına, tam genişlikte ve uyarı renginde.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: tile(
                'delete',
                l10n.delete,
                Icons.delete_outline,
                danger: true,
              ),
            ),
          ],
        );
      },
    );
  }
}
