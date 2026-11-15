import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/app_icons.dart';
import '../../../../core/l10n_ext.dart';
import '../../../../core/personalize.dart';
import '../../../../core/widgets/customize_board.dart';

/// Hızlı satırın (yazarken üstte) bütün düğmeleri: kimlik, simge, kısa ad.
/// Sıra satırdakiyle aynı.
List<({String key, IconData icon, String label})> quickRowCatalog(
  AppLocalizations l10n,
) => [
  (key: 'pen', icon: Icons.draw_outlined, label: l10n.quickRowShortPen),
  (
    key: 'bullet',
    icon: Icons.format_list_bulleted_rounded,
    label: l10n.quickRowBullet,
  ),
  (key: 'checkbox', icon: Icons.check_box_outlined, label: l10n.checkboxToggle),
  (key: 'heading', icon: Icons.title_rounded, label: l10n.quickRowShortHeading),
  (
    key: 'subheading',
    icon: Icons.short_text_rounded,
    label: l10n.quickRowSubheading,
  ),
  (
    key: 'italic',
    icon: Icons.format_italic_rounded,
    label: l10n.quickRowItalic,
  ),
  (
    key: 'underline',
    icon: Icons.format_underlined_rounded,
    label: l10n.quickRowUnderline,
  ),
  (
    key: 'highlight',
    icon: Icons.border_color_outlined,
    label: l10n.quickRowHighlight,
  ),
  (
    key: 'spell',
    icon: Icons.spellcheck_rounded,
    label: l10n.quickRowShortSpell,
  ),
  (
    key: 'package',
    icon: Icons.view_agenda_outlined,
    label: l10n.quickRowPackage,
  ),
  (
    key: 'attach',
    icon: Icons.add_circle_outline_rounded,
    label: l10n.quickRowAttach,
  ),
  (key: 'bold', icon: Icons.format_bold_rounded, label: l10n.quickRowBold),
  (
    key: 'color',
    icon: Icons.format_color_text_rounded,
    label: l10n.quickRowShortColor,
  ),
  (
    key: 'photo',
    icon: Icons.add_photo_alternate_outlined,
    label: l10n.quickRowPhoto,
  ),
  (
    key: 'camera',
    icon: Icons.photo_camera_outlined,
    label: l10n.quickRowCamera,
  ),
  (key: 'file', icon: Icons.attach_file_rounded, label: l10n.quickRowFile),
  (
    key: 'scan',
    icon: Icons.document_scanner_outlined,
    label: l10n.quickRowScan,
  ),
  (
    key: 'reminder',
    icon: Icons.alarm_add_outlined,
    label: l10n.quickRowReminder,
  ),
  (key: 'date', icon: Icons.today_outlined, label: l10n.quickRowDate),
  (key: 'dictation', icon: AppIcons.dictation, label: l10n.quickRowDictation),
];

/// **HIZLI MENÜYÜ DÜZENLE** (kullanıcı isteği 2026-11-13: "hızlı menü
/// kaybolduysa düzen menüsünde de görülmüyor"; "düzen menüsü daha kullanıcı
/// dostu olmalı — aç, düzenle, kaydet değil, yeni modern bir tasarım").
///
/// Eski yol: ⋮ → düzenleme kipi → satırda çerçeveli düğmelere dokun →
/// Kaydet; satır görünmezse (klavye kapalı, hepsi gizli) geri getirmenin yolu
/// yoktu. Yeni yol: iki grup ("Menüde" / "Eklenebilir") karo; dokun = taşı,
/// değişiklik ANINDA kaydedilir, üstte canlı önizleme. Hem ⋮'den hem
/// Ayarlar → Kişiselleştir'den açılır.
Future<void> showQuickRowEditor(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scroll) => QuickRowEditor(scrollController: scroll),
      ),
    );

class QuickRowEditor extends StatelessWidget {
  const QuickRowEditor({super.key, this.scrollController, this.inline = false});

  final ScrollController? scrollController;

  /// Kişiselleştir ekranında kart içinde (başlıksız, kaydırmasız).
  final bool inline;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ListenableBuilder(
      listenable: Personalize.listenable,
      builder: (context, _) {
        final prefs = Personalize.prefs.value;
        final catalog = quickRowCatalog(l10n);
        final byKey = {for (final e in catalog) e.key: e};
        // Kullanıcı sırası (P63 PB2): [UiPrefs.quickOrder].
        final order = UiPrefs.orderOf([
          for (final e in catalog) e.key,
        ], prefs.quickOrder);
        final shown = [
          for (final k in order)
            if (prefs.shows(UiItem.quickRow(k))) k,
        ];
        final body = <Widget>[
          if (!inline) ...[
            Text(l10n.quickRowEditTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpace.xs),
          ],
          Text(
            l10n.quickRowEditInfo,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpace.m),
          // CANLI ÖNİZLEME panonun şeridi: satır yazarken nasıl görünecek;
          // sürükle = sırala.
          KeyedSubtree(
            key: const ValueKey('quick-row-editor-preview'),
            child: CustomizeBoard(
              entries: [
                for (final k in order)
                  (id: k, icon: byKey[k]!.icon, label: byKey[k]!.label),
              ],
              shown: shown,
              onToggle: (k, on) => Personalize.update(
                (p) => p.withVisible(UiItem.quickRow(k), on),
              ),
              onReorder: (from, to) {
                final moved = List.of(shown);
                moved.insert(to, moved.removeAt(from));
                final rest = [
                  for (final k in order)
                    if (!shown.contains(k)) k,
                ];
                Personalize.update(
                  (p) => p.copyWith(quickOrder: [...moved, ...rest]),
                );
              },
              onReset: () => Personalize.update((p) {
                var next = p.copyWith(quickOrder: const []);
                for (final e in catalog) {
                  final id = UiItem.quickRow(e.key);
                  next = next.withVisible(id, !UiItem.optIn.contains(id));
                }
                return next;
              }),
              shownLabel: l10n.quickRowEditShown,
              availableLabel: l10n.quickRowEditAvailable,
              emptyLabel: l10n.quickRowEditEmpty,
              resetLabel: l10n.quickRowEditReset,
              keyPrefix: 'quick-row-edit-',
            ),
          ),
        ];
        if (inline) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: body,
          );
        }
        return ListView(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(
            AppSpace.l,
            0,
            AppSpace.l,
            AppSpace.l + MediaQuery.paddingOf(context).bottom,
          ),
          children: body,
        );
      },
    );
  }
}
