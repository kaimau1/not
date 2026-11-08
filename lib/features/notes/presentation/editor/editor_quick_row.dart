import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/l10n_ext.dart';
import '../../../../core/personalize.dart';
import '../../../../core/widgets/customizable.dart';

/// **YAZARKEN ÜSTTE HIZLI İŞLEV SATIRI** (kullanıcı isteği 2026-11-08):
/// klavye açıkken üst çubukta tarih/etiket satırının yerinde — biçim (kalın,
/// madde imi, onay kutusu, başlık), ek (fotoğraf, dosya), kalem (dokun = kalem
/// kipi, basılı tut = kalem ayarları) ve hatırlatıcı. Yatay kayar.
///
/// Hafif: durumsuz, alt ağacı sabit; editör yalnız klavye açılıp kapanınca
/// (oturduğunda) bunu tarih satırıyla değiştirir — tuş başına kurulmaz.
///
/// 2026-11-08: klavye açıkken üst çubuğun TAMAMI bu satır + geri al/yinele;
/// her düğme düzenleme modunda gizlenip gösterilir ([UiItem.quickRow]).
/// "Kalemle yaz" başta, yazılı. [hint]: nota girişte satır ilk göründüğünde
/// bir kez hafifçe vurgulanır (aynı not içinde tekrar değil).
class EditorQuickRow extends StatefulWidget {
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
    this.hint = false,
    this.onHinted,
  });

  /// true = ilk görünüşte vurgula; vurgu başlayınca [onHinted] çağrılır.
  final bool hint;
  final VoidCallback? onHinted;

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
  State<EditorQuickRow> createState() => _EditorQuickRowState();
}

class _EditorQuickRowState extends State<EditorQuickRow> {
  bool _glow = false;
  Timer? _fade;

  @override
  void initState() {
    super.initState();
    if (!widget.hint) return;
    widget.onHinted?.call();
    _glow = true;
    _fade = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _glow = false);
    });
  }

  @override
  void dispose() {
    _fade?.cancel();
    super.dispose();
  }

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
      String? label,
    }) => Customizable(
      id: UiItem.quickRow(key),
      child: Tooltip(
        message: tip,
        child: InkResponse(
          key: ValueKey('quick-row-$key'),
          radius: 20,
          onTap: onTap,
          onLongPress: onLong,
          child: SizedBox(
            height: 40,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: label == null ? 10 : 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 20, color: scheme.onSurfaceVariant),
                  if (label != null) ...[
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
    final divider = Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: scheme.outlineVariant,
    );
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return RepaintBoundary(
      child: AnimatedContainer(
        duration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 600),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: _glow
              ? scheme.primary.withValues(alpha: 0.12)
              : scheme.primary.withValues(alpha: 0),
          borderRadius: BorderRadius.circular(20),
        ),
        child: SingleChildScrollView(
        key: const ValueKey('editor-quick-row'),
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // SAYFAYA KALEMLE YAZ başta ve yazılı (kullanıcı isteği
            // 2026-11-08); basılı tut = kalem ayarları.
            if (widget.onPen != null) ...[
              button(
                'pen',
                Icons.draw_outlined,
                l10n.quickRowPen,
                widget.onPen,
                onLong: widget.onPenSettings,
                label: l10n.quickRowPen,
              ),
              divider,
            ],
            button(
              'bold',
              Icons.format_bold_rounded,
              l10n.quickRowBold,
              widget.onBold,
            ),
            button(
              'bullet',
              Icons.format_list_bulleted_rounded,
              l10n.quickRowBullet,
              widget.onBullet,
            ),
            if (widget.onCheckbox != null)
              button(
                'checkbox',
                Icons.check_box_outlined,
                l10n.checkboxToggle,
                widget.onCheckbox,
              ),
            button(
              'heading',
              Icons.title_rounded,
              l10n.quickRowHeading,
              widget.onHeading,
            ),
            divider,
            button(
              'photo',
              Icons.add_photo_alternate_outlined,
              l10n.quickRowPhoto,
              widget.onPhoto,
            ),
            button(
              'file',
              Icons.attach_file_rounded,
              l10n.quickRowFile,
              widget.onFile,
            ),
            divider,
            button(
              'reminder',
              Icons.alarm_add_outlined,
              l10n.quickRowReminder,
              widget.onReminder,
            ),
          ],
        ),
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
