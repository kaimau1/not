import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/app_icons.dart';
import '../../../../core/l10n_ext.dart';
import '../../../../core/personalize.dart';
import '../../../../core/widgets/customizable.dart';
import 'auto_spell.dart';

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
    this.onSubheading,
    this.onSpell,
    this.onPackage,
    this.packageHint = false,
    this.onItalic,
    this.onUnderline,
    this.onHighlight,
    this.onDictation,
    this.onSpellSettings,
    this.onCamera,
    this.onDate,
    this.onScan,
  });

  /// Yazım düzelt düğmesine basılı tut: ayarlar (öğrenme, sıfırla).
  final VoidCallback? onSpellSettings;

  /// Kamera ile fotoğraf, bugünün tarihi/saati, belge tarama (2026-11-08:
  /// "hızlı menüye daha işe yarar şeyler koy").
  final VoidCallback? onCamera;
  final VoidCallback? onDate;
  final VoidCallback? onScan;

  /// Ara başlık: satırı alt başlık yapar (metin modu; 2026-11-08).
  final VoidCallback? onSubheading;

  /// Yazım düzelt aç/kapa; durum [AutoSpell.enabled]'dan okunur.
  final VoidCallback? onSpell;

  /// Seçimi / uzun yazıyı NOT PAKETİNE al; [packageHint] = uzun yazı var,
  /// düğme ipucuyla vurgulanır.
  final VoidCallback? onPackage;
  final bool packageHint;

  // Sonradan eklenebilenler ([UiItem.optIn]).
  final VoidCallback? onItalic;
  final VoidCallback? onUnderline;
  final VoidCallback? onHighlight;
  final VoidCallback? onDictation;

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
            // SAYFAYA KALEMLE YAZ başta; YALNIZ SİMGE (kullanıcı isteği
            // 2026-11-08 ikinci tur: "uzun yazı, sadece kalem işareti
            // olmalı" — yazı bütün satırı kaplıyordu). Açıklama ipucunda;
            // basılı tut = kalem ayarları.
            if (widget.onPen != null) ...[
              button(
                'pen',
                Icons.draw_outlined,
                l10n.quickRowPen,
                widget.onPen,
                onLong: widget.onPenSettings,
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
            if (widget.onSubheading != null)
              button(
                'subheading',
                Icons.short_text_rounded,
                l10n.quickRowSubheading,
                widget.onSubheading,
              ),
            if (widget.onItalic != null)
              button(
                'italic',
                Icons.format_italic_rounded,
                l10n.quickRowItalic,
                widget.onItalic,
              ),
            if (widget.onUnderline != null)
              button(
                'underline',
                Icons.format_underlined_rounded,
                l10n.quickRowUnderline,
                widget.onUnderline,
              ),
            if (widget.onHighlight != null)
              button(
                'highlight',
                Icons.border_color_outlined,
                l10n.quickRowHighlight,
                widget.onHighlight,
              ),
            if (widget.onSpell != null)
              ValueListenableBuilder<bool>(
                valueListenable: AutoSpell.enabled,
                builder: (context, on, _) => Customizable(
                  id: UiItem.quickRow('spell'),
                  child: Tooltip(
                    message: on ? l10n.quickRowSpellOn : l10n.quickRowSpellOff,
                    child: InkResponse(
                      key: const ValueKey('quick-row-spell'),
                      radius: 20,
                      onTap: widget.onSpell,
                      onLongPress: widget.onSpellSettings,
                      child: Container(
                        height: 32,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: on ? scheme.secondaryContainer : null,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.spellcheck_rounded,
                          size: 20,
                          color: on
                              ? scheme.onSecondaryContainer
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (widget.onPackage != null)
              Stack(
                clipBehavior: Clip.none,
                children: [
                  button(
                    'package',
                    Icons.view_agenda_outlined,
                    widget.packageHint
                        ? l10n.notePackageHint
                        : l10n.quickRowPackage,
                    widget.onPackage,
                  ),
                  // UZUN YAZIDA İPUCU: küçük nokta (kullanıcı isteği).
                  if (widget.packageHint)
                    PositionedDirectional(
                      top: 8,
                      end: 6,
                      child: IgnorePointer(
                        child: Container(
                          key: const ValueKey('quick-row-package-hint'),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            divider,
            button(
              'photo',
              Icons.add_photo_alternate_outlined,
              l10n.quickRowPhoto,
              widget.onPhoto,
            ),
            if (widget.onCamera != null)
              button(
                'camera',
                Icons.photo_camera_outlined,
                l10n.quickRowCamera,
                widget.onCamera,
              ),
            button(
              'file',
              Icons.attach_file_rounded,
              l10n.quickRowFile,
              widget.onFile,
            ),
            if (widget.onScan != null)
              button(
                'scan',
                Icons.document_scanner_outlined,
                l10n.quickRowScan,
                widget.onScan,
              ),
            divider,
            button(
              'reminder',
              Icons.alarm_add_outlined,
              l10n.quickRowReminder,
              widget.onReminder,
            ),
            if (widget.onDate != null)
              button(
                'date',
                Icons.today_outlined,
                l10n.quickRowDate,
                widget.onDate,
              ),
            if (widget.onDictation != null)
              button(
                'dictation',
                AppIcons.dictation,
                l10n.quickRowDictation,
                widget.onDictation,
              ),
            // SATIRI DÜZENLE: düzenleme modunu açar — gizli/eklenebilir
            // düğmeler çerçeveli görünür, dokununca eklenir/çıkar.
            Tooltip(
              message: l10n.quickRowCustomize,
              child: InkResponse(
                key: const ValueKey('quick-row-customize'),
                radius: 20,
                onTap: Personalize.startEditing,
                child: SizedBox(
                  width: 36,
                  height: 40,
                  child: Icon(
                    Icons.tune_rounded,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
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
///
/// [editing] verilirse TABLETTE (en kısa kenar ≥ 600 dp, web değil) klavye
/// boşluğu 0 iken de alan odaktaysa [open] gösterilir (kullanıcı bulgusu
/// 2026-11-08: "tablette üst hızlı menü gelmiyor" — yüzen/ayrık sanal klavye
/// ve fiziksel klavye ekranın altını kaplamaz, inset hep 0 kalıyordu).
class KeyboardSwitch extends StatelessWidget {
  const KeyboardSwitch({
    super.key,
    required this.open,
    this.closed,
    this.editing,
  });

  final Widget open;
  final Widget? closed;
  final ValueListenable<bool>? editing;

  @override
  Widget build(BuildContext context) {
    final idle = closed ?? const SizedBox.shrink();
    if (MediaQuery.viewInsetsOf(context).bottom > 0) return open;
    final e = editing;
    if (e == null || kIsWeb || MediaQuery.sizeOf(context).shortestSide < 600) {
      return idle;
    }
    return ValueListenableBuilder<bool>(
      valueListenable: e,
      builder: (_, on, _) => on ? open : idle,
    );
  }
}
