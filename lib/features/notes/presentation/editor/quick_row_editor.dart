import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/app_icons.dart';
import '../../../../core/l10n_ext.dart';
import '../../../../core/personalize.dart';

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
        final all = quickRowCatalog(l10n);
        final shown = [
          for (final e in all)
            if (prefs.shows(UiItem.quickRow(e.key))) e,
        ];
        final available = [
          for (final e in all)
            if (!prefs.shows(UiItem.quickRow(e.key))) e,
        ];
        void set(String key, bool on) =>
            Personalize.update((p) => p.withVisible(UiItem.quickRow(key), on));
        Widget group(String title, int count) => Padding(
          padding: const EdgeInsets.only(top: AppSpace.m, bottom: AppSpace.s),
          child: Text(
            '$title · $count',
            style: theme.textTheme.labelLarge?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        );
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
          // CANLI ÖNİZLEME: satır yazarken nasıl görünecek.
          Container(
            key: const ValueKey('quick-row-editor-preview'),
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.s),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(AppRadius.l),
            ),
            child: shown.isEmpty
                ? Center(
                    child: Text(
                      l10n.quickRowEditEmpty,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final e in shown)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpace.s,
                            ),
                            child: Icon(
                              e.icon,
                              size: AppIconSize.m,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
          group(l10n.quickRowEditShown, shown.length),
          Wrap(
            spacing: AppSpace.s,
            runSpacing: AppSpace.s,
            children: [
              for (final e in shown)
                _Tile(
                  key: ValueKey('quick-row-edit-${e.key}'),
                  icon: e.icon,
                  label: e.label,
                  inMenu: true,
                  onTap: () => set(e.key, false),
                ),
            ],
          ),
          group(l10n.quickRowEditAvailable, available.length),
          Wrap(
            spacing: AppSpace.s,
            runSpacing: AppSpace.s,
            children: [
              for (final e in available)
                _Tile(
                  key: ValueKey('quick-row-edit-${e.key}'),
                  icon: e.icon,
                  label: e.label,
                  inMenu: false,
                  onTap: () => set(e.key, true),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.m),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              key: const ValueKey('quick-row-edit-reset'),
              onPressed: () => Personalize.update((p) {
                var next = p;
                for (final e in all) {
                  final id = UiItem.quickRow(e.key);
                  next = next.withVisible(id, !UiItem.optIn.contains(id));
                }
                return next;
              }),
              icon: const Icon(Icons.restart_alt_rounded),
              label: Text(l10n.quickRowEditReset),
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

/// Bir düğme karosu: menüdeyse dolu zemin + "−", değilse çerçeve + "+".
class _Tile extends StatelessWidget {
  const _Tile({
    super.key,
    required this.icon,
    required this.label,
    required this.inMenu,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool inMenu;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = inMenu ? scheme.onSecondaryContainer : scheme.onSurfaceVariant;
    return Material(
      color: inMenu ? scheme.secondaryContainer : scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.m),
        side: inMenu
            ? BorderSide.none
            : BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.m,
            AppSpace.s,
            AppSpace.s,
            AppSpace.s,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: AppIconSize.s, color: fg),
              const SizedBox(width: AppSpace.s),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(color: fg),
              ),
              const SizedBox(width: AppSpace.xs),
              Icon(
                inMenu
                    ? Icons.remove_circle_outline_rounded
                    : Icons.add_circle_outline_rounded,
                size: AppIconSize.xs,
                color: inMenu ? fg : scheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
