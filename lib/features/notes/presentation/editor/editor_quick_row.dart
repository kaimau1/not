import 'package:flutter/material.dart';

import '../../../../core/l10n_ext.dart';

/// **YAZARKEN ÜSTTE HIZLI İŞLEV SATIRI** (kullanıcı isteği 2026-11-08):
/// klavye açıkken üst çubukta tarih/etiket satırının yerinde — biçim (kalın,
/// madde imi, onay kutusu, başlık), ek (fotoğraf, dosya), kalem (dokun = kalem
/// kipi, basılı tut = kalem ayarları) ve hatırlatıcı. Yatay kayar.
///
/// Hafif: durumsuz, alt ağacı sabit; editör yalnız klavye açılıp kapanınca
/// (oturduğunda) bunu tarih satırıyla değiştirir — tuş başına kurulmaz.
class EditorQuickRow extends StatelessWidget {
  const EditorQuickRow({
    super.key,
    required this.onBold,
    required this.onBullet,
    required this.onCheckbox,
    required this.onHeading,
    required this.onPhoto,
    required this.onFile,
    required this.onPen,
    required this.onPenSettings,
    required this.onReminder,
  });

  final VoidCallback onBold;
  final VoidCallback onBullet;

  /// null = bu not türünde yok (liste notu zaten kutulu).
  final VoidCallback? onCheckbox;
  final VoidCallback onHeading;
  final VoidCallback onPhoto;
  final VoidCallback onFile;
  final VoidCallback? onPen;
  final VoidCallback? onPenSettings;
  final VoidCallback onReminder;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    Widget button(
      String key,
      IconData icon,
      String tip,
      VoidCallback? onTap, {
      VoidCallback? onLong,
    }) => Tooltip(
      message: tip,
      child: InkResponse(
        key: ValueKey('quick-row-$key'),
        radius: 20,
        onTap: onTap,
        onLongPress: onLong,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 20, color: scheme.onSurfaceVariant),
        ),
      ),
    );
    final divider = Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: scheme.outlineVariant,
    );
    return RepaintBoundary(
      child: SingleChildScrollView(
        key: const ValueKey('editor-quick-row'),
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            button(
              'bold',
              Icons.format_bold_rounded,
              l10n.quickRowBold,
              onBold,
            ),
            button(
              'bullet',
              Icons.format_list_bulleted_rounded,
              l10n.quickRowBullet,
              onBullet,
            ),
            if (onCheckbox != null)
              button(
                'checkbox',
                Icons.check_box_outlined,
                l10n.checkboxToggle,
                onCheckbox,
              ),
            button(
              'heading',
              Icons.title_rounded,
              l10n.quickRowHeading,
              onHeading,
            ),
            divider,
            button(
              'photo',
              Icons.add_photo_alternate_outlined,
              l10n.quickRowPhoto,
              onPhoto,
            ),
            button(
              'file',
              Icons.attach_file_rounded,
              l10n.quickRowFile,
              onFile,
            ),
            if (onPen != null)
              button(
                'pen',
                Icons.draw_outlined,
                l10n.quickRowPen,
                onPen,
                onLong: onPenSettings,
              ),
            divider,
            button(
              'reminder',
              Icons.alarm_add_outlined,
              l10n.quickRowReminder,
              onReminder,
            ),
          ],
        ),
      ),
    );
  }
}

/// Klavye açıkken [open], kapalıyken [closed]. Yalnız bu yaprak klavye
/// boşluğuna bağlı (MediaQuery bölümü); hazır verilen alt ağaçlar aynı örnek
/// olduğundan animasyon karelerinde alt ağaç yeniden kurulmaz.
class KeyboardSwitch extends StatelessWidget {
  const KeyboardSwitch({super.key, required this.open, this.closed});

  final Widget open;
  final Widget? closed;

  @override
  Widget build(BuildContext context) =>
      MediaQuery.viewInsetsOf(context).bottom > 0
      ? open
      : (closed ?? const SizedBox.shrink());
}
