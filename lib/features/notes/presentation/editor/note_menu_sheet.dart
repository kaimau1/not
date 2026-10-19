import 'package:flutter/material.dart';

import '../../../../core/l10n_ext.dart';
import '../../../../core/widgets/action_menu_sheet.dart';
import '../../../../core/widgets/app_sheet.dart';

/// Not editörünün ⋮ menüsü — hızlı satır + başlıklı gruplar (bkz.
/// [ActionMenu], 2026-10-11). Eskiden İKİ SÜTUNLU tek ızgaraydı.
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
  bool paged = false,
  required bool locked,
  required bool archived,
  required bool isList,
  required bool twoColumns,
  required bool hasFloatingImages,
  required bool hasAttachments,
  bool? localOnly,
  bool? bubbleView,
  bool canTemplate = false,
  bool canRemoveParts = false,
}) {
  final l10n = context.l10n;
  return showAppSheet<String>(
    context: context,
    showDragHandle: true,
    // Büyük yazı ölçeğinde ızgara varsayılan tavanı aşabilir; kaydırma ağı.
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        child: _MenuGrid(
          l10n: l10n,
          pinned: pinned,
          paged: paged,
          locked: locked,
          archived: archived,
          isList: isList,
          twoColumns: twoColumns,
          hasFloatingImages: hasFloatingImages,
          hasAttachments: hasAttachments,
          localOnly: localOnly,
          bubbleView: bubbleView,
          canTemplate: canTemplate,
          canRemoveParts: canRemoveParts,
        ),
      ),
    ),
  );
}

class _MenuGrid extends StatelessWidget {
  const _MenuGrid({
    required this.l10n,
    required this.pinned,
    this.paged = false,
    required this.locked,
    required this.archived,
    required this.isList,
    required this.twoColumns,
    required this.hasFloatingImages,
    required this.hasAttachments,
    this.localOnly,
    this.bubbleView,
    this.canTemplate = false,
    this.canRemoveParts = false,
  });

  /// Notta HEM serbest metin HEM madde listesi var: "Listeyi kaldır" /
  /// "Metni kaldır" gösterilir (kullanıcı isteği 2026-10-16).
  final bool canRemoveParts;

  /// null = notta görünümü değişebilecek belge yok; true = balonlu
  /// görünümde (geçiş klasiğe), false = klasikte (geçiş balonluya).
  final bool? bubbleView;

  /// "Şablon olarak kaydet" gösterilsin mi (bkz. `canSaveAsTemplate`).
  final bool canTemplate;

  /// null = özellik yok (web ya da başkasının notu); true = not yalnız bu
  /// cihazda (bkz. `toggleNoteLocalOnly`).
  final bool? localOnly;

  final AppLocalizations l10n;
  final bool pinned;

  /// Defter görünümü açık mı (F3.5).
  final bool paged;
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
    // 2026-10-11 YENİDEN DÜZEN (bkz. [ActionMenu]). Üst çubukta ve alt
    // çubukta zaten AÇIKÇA duran işler burada tekrar edilmez: "Sabitle" üst
    // çubukta (raptiye), Biçim/Ekle/Seç alt çubukta. Ara ve Paylaş alt
    // çubuktan dar ekranda düşebildiği için (bkz. planEditorBar) burada da
    // kalır. Hesap makinesi üst çubuktan buraya geldi: üst çubuk notun
    // DURUMUNA (geri al, sabitle, ortak çalışan) ayrıldı.
    return ActionMenu(
      quick: [
        // TOPARLAMA (kullanıcı isteği 2026-10-17: "tekrarlar düzelsin"):
        // "Kopyala", "Arkadaşa gönder" ve "Dışa aktar" bu menüden kalktı —
        // üçü de Paylaş levhasında (Kopyala · Arkadaşa · Dışa aktar) tek
        // dokunuşla duruyor. Menüde aynı işin iki kapısı kafa karıştırıyordu.
        MenuAction('share', l10n.share, Icons.share_outlined),
        MenuAction('search', l10n.noteSearchTitle, Icons.manage_search),
        MenuAction(
          'calculator',
          l10n.calculatorTitle,
          Icons.calculate_outlined,
        ),
      ],
      sections: [
        MenuSection(l10n.menuSectionContent, [
          // DEFTER GÖRÜNÜMÜ (F3.5): kâğıt deseni + hep görünen sayfa çubuğu.
          MenuAction(
            'paged',
            paged ? l10n.notebookViewOff : l10n.notebookViewOn,
            Icons.menu_book_outlined,
            selected: paged,
          ),
          if (paged)
            MenuAction('paper', l10n.archivePaper, Icons.texture),
          // BALONLU ⇄ KLASİK görünüm (kullanıcı isteği 2026-10-15).
          if (bubbleView != null)
            MenuAction(
              'docView',
              bubbleView! ? l10n.docViewToClassic : l10n.docViewToBubbles,
              bubbleView!
                  ? Icons.view_agenda_outlined
                  : Icons.chat_bubble_outline,
            ),
          // LİSTEYE ÖZGÜ maddeler (kullanıcı istekleri 2026-08-16).
          if (isList) ...[
            MenuAction('toText', l10n.convertToText, Icons.notes_outlined),
            MenuAction('sortItems', l10n.sortItems, Icons.sort),
            MenuAction(
              'columns',
              twoColumns ? l10n.listOneColumn : l10n.listTwoColumns,
              twoColumns
                  ? Icons.view_agenda_outlined
                  : Icons.view_column_outlined,
            ),
          ] else
            MenuAction('toList', l10n.convertToList, Icons.checklist),
          // KARIŞIK İÇERİKTE bir bölümü kaldır (kullanıcı isteği
          // 2026-10-16: "liste veya metin kısımlarını kaldırabilme, ikisi de
          // varken"). Geri alınabilir.
          if (canRemoveParts) ...[
            MenuAction(
              'removeList',
              l10n.removeListPart,
              Icons.playlist_remove_rounded,
            ),
            MenuAction(
              'removeText',
              l10n.removeTextPart,
              Icons.format_clear_rounded,
            ),
          ],
          // Metin içi görselleri TOPLUCA ek şeridine indirir.
          if (hasFloatingImages)
            MenuAction(
              'imagesToFiles',
              l10n.imagesToAttachments,
              Icons.attach_file,
            ),
          MenuAction('clear', l10n.clearNote, Icons.backspace_outlined),
        ]),
        MenuSection(l10n.menuSectionCopy, [
          MenuAction(
            'duplicate',
            l10n.duplicateNote,
            Icons.library_add_outlined,
          ),
          // KENDİ ŞABLONUM (kullanıcı isteği 2026-09-29).
          if (canTemplate)
            MenuAction(
              'saveTemplate',
              l10n.saveAsTemplate,
              Icons.bookmark_add_outlined,
            ),
          // Ekleri bir arşiv defterine KOPYALAR (kullanıcı isteği 2026-08-16).
          if (hasAttachments)
            MenuAction(
              'toArchive',
              l10n.archiveCopyHere,
              Icons.inventory_2_outlined,
            ),
        ]),
        MenuSection(l10n.menuSectionTools, [
          MenuAction('listen', l10n.listenToNote, Icons.headphones_outlined),
          MenuAction('stats', l10n.noteStatsTitle, Icons.insights_outlined),
          // EKRANI DÜZENLE (kullanıcı isteği 2026-10-16): düzenleme modunu
          // doğrudan buradan açar — çubuktaki düğmelere dokunarak gizle/göster.
          MenuAction('customize', l10n.noteMenuCustomize, Icons.tune_rounded),
          MenuAction('settings', l10n.settings, Icons.settings_outlined),
        ]),
        MenuSection(l10n.menuSectionProtect, [
          MenuAction(
            'archive',
            archived ? l10n.unarchive : l10n.archive,
            archived ? Icons.unarchive_outlined : Icons.archive_outlined,
          ),
          MenuAction(
            'lock',
            locked ? l10n.unlockNote : l10n.lockNote,
            locked ? Icons.lock_open_outlined : Icons.lock_outline,
          ),
          // NOTA ÖZEL SENKRON (kullanıcı isteği 2026-09-26).
          if (localOnly != null)
            MenuAction(
              'localOnly',
              localOnly! ? l10n.localOnlyTurnOff : l10n.localOnlyTurnOn,
              localOnly! ? Icons.cloud_sync_outlined : Icons.cloud_off_outlined,
            ),
        ]),
      ],
      danger: MenuAction('delete', l10n.delete, Icons.delete_outline),
    );
  }
}
