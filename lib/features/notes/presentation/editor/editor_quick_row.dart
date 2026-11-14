import '../../../../app/window_class.dart';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/app_icons.dart';
import '../../../../core/l10n_ext.dart';
import '../../../../core/personalize.dart';
import '../../../../core/widgets/customizable.dart';
import '../../../../core/widgets/keyboard_snap.dart';
import '../../../../core/utils/rich_text.dart';
import 'auto_spell.dart';
import 'quick_row_editor.dart';
import 'format_bar.dart' show FormatTarget;
import 'format_menu.dart';

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
    this.penOn = false,
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
    this.onAttach,
    this.onColor,
    this.onColorPick,
    this.favoriteColor,
    this.fit = false,
    this.target,
  });

  /// Biçimin yazılacağı alan (editörün `_formatTargetN`'i). Verilirse
  /// imleçteki/seçimdeki ETKİN biçimlerin düğmeleri basılı görünür (kalın,
  /// eğik, altı çizili, vurgu, renk, başlık).
  final ValueListenable<FormatTarget?>? target;

  /// true = sığan düğmeler satırda, kalanı ⋮ menüsünde (geniş web);
  /// false = hepsi yatay kayar, ⋮ yalnız Düzenle (telefon/tablet).
  final bool fit;

  /// "Ekle" levhası (görsel, dosya, kamera… tek yerde).
  final VoidCallback? onAttach;

  /// Renk: dokun = seçime/yazıya FAVORİ renk, basılı tut = renk seçici
  /// (seçilen favori olur). [favoriteColor] düğmenin altındaki çizgi.
  final VoidCallback? onColor;
  final VoidCallback? onColorPick;
  final Color? favoriteColor;

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

  /// Kalem kipi açık: düğme dolgulu; tekrar basınca kip KAPANIR (kullanıcı
  /// isteği 2026-11-08).
  final bool penOn;
  final VoidCallback? onPenSettings;
  final VoidCallback onReminder;

  @override
  State<EditorQuickRow> createState() => _EditorQuickRowState();
}

class _EditorQuickRowState extends State<EditorQuickRow> {
  // ETKİN BİÇİM BASILI (kullanıcı isteği 2026-11-13: "üst hızlı paneldeki
  // butonlar aktifken — kırmızı yazma, bold — aktif görülmeli; kendi yeri
  // de"): biçim şeridiyle aynı hesap ([activeRichFormats]); yalnız sonuç
  // DEĞİŞİNCE bu satır yeniden çizilir, editör kurulmaz.
  RichMark _mark = RichMark.none;
  RichHeading _heading = RichHeading.normal;
  FormatTarget? _watched;

  @override
  void initState() {
    super.initState();
    widget.target?.addListener(_onTarget);
    _onTarget();
  }

  @override
  void didUpdateWidget(EditorQuickRow old) {
    super.didUpdateWidget(old);
    if (old.target != widget.target) {
      old.target?.removeListener(_onTarget);
      widget.target?.addListener(_onTarget);
      _onTarget();
    }
  }

  @override
  void dispose() {
    widget.target?.removeListener(_onTarget);
    _watched?.controller.removeListener(_refresh);
    super.dispose();
  }

  void _onTarget() {
    final t = widget.target?.value;
    if (!identical(t?.controller, _watched?.controller)) {
      _watched?.controller.removeListener(_refresh);
      t?.controller.addListener(_refresh);
    }
    _watched = t;
    _refresh();
  }

  void _refresh() {
    final c = _watched?.controller;
    final mark = c == null ? RichMark.none : activeRichFormats(c);
    final heading = c == null ? RichHeading.normal : activeRichHeading(c);
    if (mark == _mark && heading == _heading) return;
    _mark = mark;
    _heading = heading;
    if (mounted) setState(() {});
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
      bool on = false,
    }) => Customizable(
      id: UiItem.quickRow(key),
      child: Tooltip(
        message: tip,
        child: InkResponse(
          key: ValueKey('quick-row-$key'),
          radius: 20,
          onTap: onTap,
          onLongPress: onLong,
          child: Container(
            height: 40,
            decoration: on
                ? BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  )
                : null,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: label == null ? 10 : 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: on
                        ? scheme.onPrimaryContainer
                        : scheme.onSurfaceVariant,
                  ),
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
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    // Düğmeler TEK listede: dar ekranda yatay kayar, [fit] verilince sığan
    // kadarı satırda, kalanı ⋮ menüsünde (kullanıcı isteği 2026-11-09:
    // "webte alan geniş, hızlı menü değil direkt butonlar olsun; fazlası ve
    // Düzenle 3 noktada"). null = ayraç (yalnız kayan satırda çizilir).
    _QuickEntry plain(
      String key,
      IconData icon,
      String tip,
      VoidCallback? on, {
      bool active = false,
    }) => _QuickEntry(
      key,
      icon,
      tip,
      on,
      button(key, icon, tip, on, on: active),
    );
    final m = _mark;
    final entries = <_QuickEntry?>[
      if (widget.onPen != null) ...[
        _QuickEntry(
          'pen',
          Icons.draw_outlined,
          l10n.quickRowPen,
          widget.onPen,
          button(
            'pen',
            Icons.draw_outlined,
            l10n.quickRowPen,
            widget.onPen,
            onLong: widget.onPenSettings,
            on: widget.penOn,
          ),
        ),
        null,
      ],
      plain(
        'bullet',
        Icons.format_list_bulleted_rounded,
        l10n.quickRowBullet,
        widget.onBullet,
      ),
      if (widget.onCheckbox != null)
        plain(
          'checkbox',
          Icons.check_box_outlined,
          l10n.checkboxToggle,
          widget.onCheckbox,
        ),
      plain(
        'heading',
        Icons.title_rounded,
        l10n.quickRowHeading,
        widget.onHeading,
        active: _heading == RichHeading.h1,
      ),
      if (widget.onSubheading != null)
        plain(
          'subheading',
          Icons.short_text_rounded,
          l10n.quickRowSubheading,
          widget.onSubheading,
          active: _heading == RichHeading.h2,
        ),
      if (widget.onItalic != null)
        plain(
          'italic',
          Icons.format_italic_rounded,
          l10n.quickRowItalic,
          widget.onItalic,
          active: m.italic,
        ),
      if (widget.onUnderline != null)
        plain(
          'underline',
          Icons.format_underlined_rounded,
          l10n.quickRowUnderline,
          widget.onUnderline,
          active: m.underline,
        ),
      if (widget.onHighlight != null)
        plain(
          'highlight',
          Icons.border_color_outlined,
          l10n.quickRowHighlight,
          widget.onHighlight,
          active: m.highlight != null,
        ),
      if (widget.onSpell != null)
        _QuickEntry(
          'spell',
          Icons.spellcheck_rounded,
          AutoSpell.enabled.value
              ? l10n.quickRowSpellOn
              : l10n.quickRowSpellOff,
          widget.onSpell,
          _spellButton(l10n, scheme),
        ),
      if (widget.onPackage != null)
        _QuickEntry(
          'package',
          Icons.view_agenda_outlined,
          widget.packageHint ? l10n.notePackageHint : l10n.quickRowPackage,
          widget.onPackage,
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
        ),
      if (widget.onAttach != null)
        plain(
          'attach',
          Icons.add_circle_outline_rounded,
          l10n.quickRowAttach,
          widget.onAttach,
        ),
      plain(
        'bold',
        Icons.format_bold_rounded,
        l10n.quickRowBold,
        widget.onBold,
        active: m.bold,
      ),
      if (widget.onColor != null)
        _QuickEntry(
          'color',
          Icons.format_color_text_rounded,
          l10n.quickRowColor,
          widget.onColor,
          _colorButton(l10n, scheme),
        ),
      null,
      plain(
        'photo',
        Icons.add_photo_alternate_outlined,
        l10n.quickRowPhoto,
        widget.onPhoto,
      ),
      if (widget.onCamera != null)
        plain(
          'camera',
          Icons.photo_camera_outlined,
          l10n.quickRowCamera,
          widget.onCamera,
        ),
      plain(
        'file',
        Icons.attach_file_rounded,
        l10n.quickRowFile,
        widget.onFile,
      ),
      if (widget.onScan != null)
        plain(
          'scan',
          Icons.document_scanner_outlined,
          l10n.quickRowScan,
          widget.onScan,
        ),
      null,
      plain(
        'reminder',
        Icons.alarm_add_outlined,
        l10n.quickRowReminder,
        widget.onReminder,
      ),
      if (widget.onDate != null)
        plain('date', Icons.today_outlined, l10n.quickRowDate, widget.onDate),
      if (widget.onDictation != null)
        plain(
          'dictation',
          AppIcons.dictation,
          l10n.quickRowDictation,
          widget.onDictation,
        ),
    ];
    final divider = Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: scheme.outlineVariant,
    );
    Widget more(List<_QuickEntry> overflow) => PopupMenuButton<VoidCallback>(
      key: const ValueKey('quick-row-more'),
      tooltip: MaterialLocalizations.of(context).showMenuTooltip,
      icon: Icon(
        Icons.more_vert_rounded,
        size: 20,
        color: scheme.onSurfaceVariant,
      ),
      onSelected: (run) => run(),
      itemBuilder: (_) => [
        for (final e in overflow)
          PopupMenuItem<VoidCallback>(
            value: e.onTap,
            enabled: e.onTap != null,
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(e.icon, size: 20),
              title: Text(e.tip),
            ),
          ),
        if (overflow.isNotEmpty) const PopupMenuDivider(),
        // SATIRI DÜZENLE (2026-11-09: ⋮ içinde): düzenleme modunu açar —
        // gizli/eklenebilir düğmeler çerçeveli görünür.
        PopupMenuItem<VoidCallback>(
          key: const ValueKey('quick-row-customize'),
          // Eski "aç-düzenle-kaydet" kipi yerine anında uygulanan levha
          // (kullanıcı isteği 2026-11-13, bkz. [showQuickRowEditor]).
          value: () => unawaited(showQuickRowEditor(context)),
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.tune_rounded, size: 20),
            title: Text(l10n.quickRowCustomize),
          ),
        ),
      ],
    );
    return RepaintBoundary(
      child: _HintGlow(
        hint: widget.hint,
        onHinted: widget.onHinted,
        reduceMotion: reduceMotion,
        child: ListenableBuilder(
          listenable: Personalize.listenable,
          builder: (context, _) {
            // Düzenleme modunda gizliler de çerçeveli görünmeli: hepsi kayan
            // satırda.
            if (!widget.fit || Personalize.editing) {
              return Row(
                key: const ValueKey('editor-quick-row'),
                children: [
                  Flexible(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final e in entries) e?.widget ?? divider,
                        ],
                      ),
                    ),
                  ),
                  more(const []),
                ],
              );
            }
            final shown = [
              for (final e in entries)
                if (e != null && Customizable.shows(UiItem.quickRow(e.key))) e,
            ];
            return LayoutBuilder(
              builder: (context, box) {
                // ponytail: düğme başına ~44 dp sabit pay (⋮ için 48 ayrılır);
                // ölçüm yok — dar düğmeler biraz boşluk bırakır.
                final room = ((box.maxWidth - 48) / 44).floor().clamp(0, 99);
                return Row(
                  key: const ValueKey('editor-quick-row'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final e in shown.take(room)) e.widget,
                    more(shown.skip(room).toList()),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _spellButton(AppLocalizations l10n, ColorScheme scheme) =>
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
      );

  Widget _colorButton(AppLocalizations l10n, ColorScheme scheme) =>
      Customizable(
        id: UiItem.quickRow('color'),
        child: Tooltip(
          message: l10n.quickRowColor,
          child: InkResponse(
            key: const ValueKey('quick-row-color'),
            radius: 20,
            onTap: widget.onColor,
            onLongPress: widget.onColorPick,
            child: Container(
              height: 40,
              width: 40,
              decoration: _mark.color != null
                  ? BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    )
                  : null,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.format_color_text_rounded,
                    size: 20,
                    color: _mark.color != null
                        ? scheme.onPrimaryContainer
                        : scheme.onSurfaceVariant,
                  ),
                  Container(
                    width: 18,
                    height: 4,
                    margin: const EdgeInsets.only(top: 1),
                    decoration: BoxDecoration(
                      color: widget.favoriteColor ?? scheme.error,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

/// Hızlı satırın bir düğmesi: satırdaki hâli ([widget]) ve ⋮ menüsündeki
/// karşılığı (simge + açıklama).
class _QuickEntry {
  const _QuickEntry(this.key, this.icon, this.tip, this.onTap, this.widget);
  final String key;
  final IconData icon;
  final String tip;
  final VoidCallback? onTap;
  final Widget widget;
}

/// Satırın İLK GÖRÜNÜŞÜNDEKİ kısa parlama ("burada yeni bir şey var").
///
/// Ayrı yaprak (F60.S5): eskiden parlama satırın kendi durumuydu — 1,4 sn
/// sonra sönerken BÜTÜN satır (≈ 250 widget) yazmanın ortasında yeniden
/// kuruluyordu. Burada yalnız zemin kutusu kurulur; [child] aynı örnek.
/// Satır klavyeden önce görünmeden kurulduğu için (bkz. [KeyboardSwitch])
/// parlama kurulunca değil GÖRÜNÜNCE başlar (`TickerMode`).
class _HintGlow extends StatefulWidget {
  const _HintGlow({
    required this.hint,
    required this.onHinted,
    required this.reduceMotion,
    required this.child,
  });

  final bool hint;
  final VoidCallback? onHinted;
  final bool reduceMotion;
  final Widget child;

  @override
  State<_HintGlow> createState() => _HintGlowState();
}

class _HintGlowState extends State<_HintGlow>
    with SingleTickerProviderStateMixin {
  /// 1 = parlak, 0 = sönük. Yalnız BOYAMAYI sürer ([CustomPaint.painter]'ın
  /// `repaint`'i): sönerken kare başına ne kurulum ne yerleşim — satır üst
  /// çubuğun `LayoutBuilder`'ı altında, oradaki her `setState` çubuğu
  /// yeniden dizilmek üzere işaretler.
  late final AnimationController _light = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  bool _started = false;
  Timer? _fade;

  /// `TickerMode` DİNLENİR, bağımlılık kurulmaz: satır görünür olunca
  /// parlama kurulumsuz başlar (bağımlılık her klavye geçişinde bu öğeyi
  /// yeniden kurduruyordu — S17).
  ValueListenable<TickerModeData>? _ticker;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ticker = TickerMode.getValuesNotifier(context);
    if (!identical(ticker, _ticker)) {
      _ticker?.removeListener(_maybeStart);
      _ticker = ticker..addListener(_maybeStart);
    }
    _maybeStart();
  }

  void _maybeStart() {
    if (_started || !widget.hint || !mounted) return;
    if (!(_ticker?.value.enabled ?? true)) return;
    _started = true;
    widget.onHinted?.call();
    _light.value = 1;
    _fade = Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      if (widget.reduceMotion) {
        _light.value = 0;
      } else {
        unawaited(_light.animateBack(0, curve: Curves.easeOut));
      }
    });
  }

  @override
  void dispose() {
    _ticker?.removeListener(_maybeStart);
    _fade?.cancel();
    _light.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _GlowPainter(_light, Theme.of(context).colorScheme.primary),
    child: widget.child,
  );
}

class _GlowPainter extends CustomPainter {
  _GlowPainter(this.light, this.color) : super(repaint: light);

  final Animation<double> light;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final t = light.value;
    if (t <= 0) return;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(20)),
      Paint()..color = color.withValues(alpha: 0.12 * t),
    );
  }

  @override
  bool shouldRepaint(_GlowPainter old) =>
      old.light != light || old.color != color;
}

/// Klavye açıkken [open], kapalıyken [closed]. Yalnız bu yaprak klavye
/// boşluğuna bağlı (MediaQuery bölümü); hazır verilen alt ağaçlar aynı örnek
/// olduğundan animasyon karelerinde alt ağaç yeniden kurulmaz.
///
/// [editing] verilirse TABLETTE (en kısa kenar ≥ 600 dp, web değil) klavye
/// boşluğu 0 iken de alan odaktaysa [open] gösterilir (kullanıcı bulgusu
/// 2026-11-08: "tablette üst hızlı menü gelmiyor" — yüzen/ayrık sanal klavye
/// ve fiziksel klavye ekranın altını kaplamaz, inset hep 0 kalıyordu).
class KeyboardSwitch extends StatefulWidget {
  const KeyboardSwitch({
    super.key,
    required this.open,
    this.closed,
    this.editing,
    this.onlyWhileEditing = false,
    this.pauseHidden = false,
  });

  /// Gizliyken [open]'ın animasyonları dursun ve ilk görünüşü bilsin
  /// (`TickerMode`) — yalnız hızlı satır ister (parlama). Geri al / gizlenen
  /// düğmelerde sarmalayıcı yok: her klavye geçişinde 2 kurulum (S17).
  final bool pauseHidden;

  final Widget open;
  final Widget? closed;
  final ValueListenable<bool>? editing;

  /// [open] YALNIZ [editing] doğruyken (klavye açık olsa da): başlığı üst
  /// çubukta duran notta başlık alanı düzenlenirken çubuk yerinde kalır
  /// (2026-11-14). Anahtar hep aynı örnek — kurulum/önden kurma bozulmaz.
  final bool onlyWhileEditing;

  @override
  State<KeyboardSwitch> createState() => _KeyboardSwitchState();
}

/// **İKİ ALT AĞAÇ DA KURULU KALIR** (ölçüm 2026-11-10, "klavye açılıp
/// kapanırken titriyor"): eskiden her klavye açılışında [open] (hızlı satır:
/// ~20 düğme, ipucu, düzenleme çerçevesi) sıfırdan kuruluyor, kapanışta
/// sökülüp [closed] yeniden kuruluyordu — ağaç şekli değişiyordu. Artık
/// [open] İLK açılışta bir kez kurulur, sonra ikisi de yerinde durur; yalnız
/// görünen değişir (Offstage). Kasma kontrol listesi madde 4.
class _KeyboardSwitchState extends State<KeyboardSwitch> {
  bool _built = false;

  /// **[open] KLAVYEDEN ÖNCE KURULUR** (F60.S5). Eskiden ilk klavye
  /// karesinde kuruluyordu: hızlı satır ≈ 230 widget — klavye animasyonunun
  /// TAM BAŞINDA tek pahalı kare (ölçüm: o kare 320 kurulum, sonrakiler 87).
  /// Artık not açılışı durulunca ([_kIdle]) ya da bir alana odaklanınca
  /// (klavye birkaç kare sonra gelir) görünmeden kurulur; klavyenin ilk
  /// karesi yalnız görüneni değiştirir.
  static const _kIdle = Duration(milliseconds: 900);
  Timer? _idle;

  @override
  void initState() {
    super.initState();
    _idle = Timer(_kIdle, _prebuild);
    widget.editing?.addListener(_onEditing);
  }

  @override
  void didUpdateWidget(KeyboardSwitch old) {
    super.didUpdateWidget(old);
    if (old.editing != widget.editing) {
      old.editing?.removeListener(_onEditing);
      widget.editing?.addListener(_onEditing);
    }
  }

  @override
  void dispose() {
    _idle?.cancel();
    widget.editing?.removeListener(_onEditing);
    super.dispose();
  }

  /// Odak değişti: görünen taraf yeniden seçilir (dinleyici bu öğede —
  /// araya `ValueListenableBuilder` koymak her klavye geçişinde +1 kurulum,
  /// S17). Odak geldiyse [open] odak karesini ağırlaştırmadan, bir SONRAKİ
  /// karede kurulur.
  void _onEditing() {
    if (mounted) setState(() {});
    if (_built || widget.editing?.value != true) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _prebuild());
    WidgetsBinding.instance.scheduleFrame();
  }

  void _prebuild() {
    _idle?.cancel();
    _idle = null;
    if (!mounted || _built) return;
    setState(() => _built = true);
  }

  Widget _pick(bool showOpen) {
    if (showOpen) _built = true;
    return Stack(
      children: [
        Offstage(
          offstage: !showOpen,
          // Görünmeyen taraf animasyon sürmez; ilk görünüşü bekleyenler
          // (satırın parlaması) buradan öğrenir.
          child: !widget.pauseHidden
              ? (_built ? widget.open : const SizedBox.shrink())
              : TickerMode(
                  enabled: showOpen,
                  child: _built ? widget.open : const SizedBox.shrink(),
                ),
        ),
        Offstage(
          offstage: showOpen,
          child: widget.closed ?? const SizedBox.shrink(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = KeyboardInset.openOf(context);
    final e = widget.editing;
    final win = WindowClass.of(context);
    final tablet = e != null && win.touchFirst && !win.compactDevice;
    final on = e?.value ?? false;
    if (widget.onlyWhileEditing && e != null) {
      return _pick(on && (keyboard || tablet));
    }
    return _pick(keyboard || (tablet && on));
  }
}
