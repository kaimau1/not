import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/note_colors.dart';
import '../../../../core/l10n_ext.dart';
import '../../../../core/utils/note_fonts.dart';
import '../../../../core/utils/rich_text.dart';
import '../../../../core/widgets/color_palette.dart';
import 'format_menu.dart';
import 'text_wrap.dart';

/// Klavyenin hemen üstünde duran biçim çubuğu.
///
/// Neden alt sayfa değil de SABİT çubuk: biçim, yazarken kullanılan bir şey.
/// Seçim menüsünden açılan bir sayfa her seferinde (seç → menü → sayfa →
/// düğme) dört adım demekti ve yazı tipi/boyut palet sayfasının içine gömülü
/// olduğundan bulunamıyordu. Çubuk açıkken düğmeler tek dokunuş.
///
/// KRİTİK — ODAK: çubuktaki hiçbir öğe odak istemez
/// (`Focus(canRequestFocus: false, descendantsAreFocusable: false)` +
/// [TextFieldTapRegion]). Aksi hâlde düğmeye dokunmak metin alanının odağını
/// düşürür, odakla birlikte SEÇİM de gider ve biçim uygulanacak metin
/// kalmazdı.
///
/// YÜKSEKLİK (v1.0.175): çubuk dört satırdı (biçimler + yazı tipi çipleri +
/// boyut + şeffaflık); klavye de açıkken nota kala kala ekranın beşte biri
/// kalıyordu. Artık İKİ satır: yazı tipleri açılır menüye girdi, boyut ve
/// şeffaflık ise TEK kaydırıcıyı paylaşıyor (baştaki düğme hangisini
/// sürüklediğini değiştirir).
class FormatBar extends StatefulWidget {
  const FormatBar({
    super.key,
    required this.onFormat,
    required this.onClearFormat,
    required this.onRemoveFormat,
    required this.fontFamily,
    required this.fontScale,
    required this.textOpacity,
    required this.hasSelection,
    required this.onFontChanged,
    required this.onScaleChanged,
    required this.onScaleEnd,
    required this.onOpacityChanged,
    required this.onOpacityEnd,
    required this.onClose,
    this.target,
    this.onPageStyle,
    this.onHeading,
  });

  /// Satırı başlık / alt başlık / düz metin yapar (bkz. [setLineHeading]).
  /// null ise menü çizilmez.
  final ValueChanged<RichHeading>? onHeading;

  /// SAYFA görünümü (zemin rengi, çerçeve rengi, zemin görseli) levhasını açar.
  ///
  /// Buraya taşındı (kullanıcı isteği 2026-08-10: "sayfa rengi ve yanındaki
  /// kısımları biçim menüsüne al"): renk "Ekle" levhasının en altında, PDF/ses
  /// /QR gibi EK ekleyen maddelerin arasında duruyordu — orada aranan bir şey
  /// değil, sayfanın görünümüne ait bir ayar. Biçim çubuğu zaten "bu not nasıl
  /// görünsün" düğmelerinin toplandığı yer; renk de oraya ait. null ise düğme
  /// hiç çizilmez.
  final VoidCallback? onPageStyle;

  /// Çubuğun yazdığı alan. Yalnız AKTİF BİÇİM vurgusu için gerekli: imleç ya
  /// da seçim değiştikçe hangi düğmenin basılı duracağı buradan hesaplanır
  /// (bkz. [activeRichFormats]). null ise hiçbir düğme vurgulanmaz.
  final FormatTarget? target;

  /// Biçim düğmesine basıldı: seçime uygula (seçim yoksa imlece kutu aç).
  final void Function(RichFormat format, {int? colorIndex}) onFormat;

  /// Seçimdeki tüm biçimleri siler.
  final VoidCallback onClearFormat;

  /// Paletteki "Kaldır": YALNIZ o biçmi (yazı rengi ya da vurgu) düşürür.
  final ValueChanged<RichFormat> onRemoveFormat;

  final String? fontFamily;
  final double fontScale;

  /// Not metninin opaklığı (0.3–1.0).
  final double textOpacity;

  /// O an metin SEÇİLİ mi? Seçiliyken boyut/şeffaflık yalnız seçime uygulanır
  /// ve bu yüzden sürüklerken sayfa canlı değişmez (değişse kullanıcı hangi
  /// metnin etkileneceğini göremezdi).
  final bool Function() hasSelection;

  final ValueChanged<String?> onFontChanged;

  /// Sürükleme SIRASINDA (canlı önizleme) ve bırakınca (kalıcı kayıt).
  final ValueChanged<double> onScaleChanged;
  final ValueChanged<double> onScaleEnd;
  final ValueChanged<double> onOpacityChanged;
  final ValueChanged<double> onOpacityEnd;

  final VoidCallback onClose;

  @override
  State<FormatBar> createState() => _FormatBarState();
}

/// Tek kaydırıcının o an neyi sürüklediği.
enum _SliderMode { size, opacity }

class _FormatBarState extends State<FormatBar> {
  _SliderMode _mode = _SliderMode.size;

  /// Boyut/şeffaflık satırı açık mı (kullanıcı isteği 2026-10-20: "yazı
  /// boyutu satırı da açılır kapanır olsun"). Varsayılan KAPALI — panel tek
  /// satır kalır, yazıya yer kalır. Oturum boyunca hatırlanır.
  static bool _sizeRowOpen = false;

  /// Sürüklerken canlı önizlemenin seyreltilmesi (kullanıcı bulgusu
  /// 2026-10-20: "biçim panelindeki değişiklikler kasıyor"): her kaydırıcı
  /// olayı bütün notu yeni boyla yeniden dizdiriyordu (uzun notta kare
  /// başına onlarca ms). Önizleme en çok 70 ms'de bir uygulanır; bırakınca
  /// son değer kesin yazılır.
  Timer? _liveTimer;
  double? _liveValue;

  /// İmleçte/seçimde etkin olan biçimler; düğme vurgusu bundan çizilir.
  RichMark _active = RichMark.none;

  /// İmlecin satırının başlık düzeyi (menü düğmesinin vurgusu).
  RichHeading _heading = RichHeading.normal;

  @override
  void initState() {
    super.initState();
    _watchTarget(null);
  }

  @override
  void didUpdateWidget(covariant FormatBar old) {
    super.didUpdateWidget(old);
    if (old.target?.controller != widget.target?.controller) {
      _watchTarget(old.target);
    }
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    widget.target?.controller.removeListener(_refreshActive);
    super.dispose();
  }

  /// Denetleyici değişince aboneliği taşı. TextEditingController hem metin
  /// hem SEÇİM değişiminde bildirir; imleci oynatmak da vurguyu tazeler.
  void _watchTarget(FormatTarget? old) {
    old?.controller.removeListener(_refreshActive);
    widget.target?.controller.addListener(_refreshActive);
    // initState/didUpdateWidget'ın arkasından zaten bir build geliyor;
    // setState'siz atama yeterli (ve initState'te setState yasak).
    _active = _computeActive();
    _heading = _computeHeading();
  }

  RichHeading _computeHeading() {
    final controller = widget.target?.controller;
    return controller == null
        ? RichHeading.normal
        : activeRichHeading(controller);
  }

  RichMark _computeActive() {
    final controller = widget.target?.controller;
    return controller == null ? RichMark.none : activeRichFormats(controller);
  }

  void _refreshActive() {
    if (!mounted) return;
    final next = _computeActive();
    final heading = _computeHeading();
    // Her tuş vuruşunda değil, vurgu GERÇEKTEN değişince çiz.
    if (next != _active || heading != _heading) {
      setState(() {
        _active = next;
        _heading = heading;
      });
    }
  }

  /// Sürükleme sürerken parmağın değeri. Seçim varken sayfa değişmediği için
  /// kaydırıcı yalnız buradan beslenir — yoksa topuz parmağın altında donardı.
  double? _drag;

  double get _value =>
      _drag ??
      (_mode == _SliderMode.size ? widget.fontScale : widget.textOpacity);

  double get _min => _mode == _SliderMode.size ? 0.7 : 0.3;
  double get _max => _mode == _SliderMode.size ? 2.0 : 1.0;

  void _onChanged(double value) {
    setState(() => _drag = value);
    // Canlı önizleme yalnız NOT GENELİNDE: seçim varken değişiklik bırakınca
    // ve yalnız seçime uygulanır.
    if (widget.hasSelection()) return;
    _liveValue = value;
    _liveTimer ??= Timer(const Duration(milliseconds: 70), _flushLive);
  }

  void _flushLive() {
    _liveTimer = null;
    final value = _liveValue;
    _liveValue = null;
    if (value == null || !mounted) return;
    if (_mode == _SliderMode.size) {
      widget.onScaleChanged(value);
    } else {
      widget.onOpacityChanged(value);
    }
  }

  void _onChangeEnd(double value) {
    _liveTimer?.cancel();
    _liveTimer = null;
    _liveValue = null;
    // Seçime uygulandıysa topuz BIRAKILDIĞI yerde kalır: not geneli
    // değişmediği için sıfırlansa kaydırıcı %100'e geri zıplar ve kullanıcı
    // az önce ne uyguladığını göremezdi.
    setState(() => _drag = widget.hasSelection() ? value : null);
    if (_mode == _SliderMode.size) {
      widget.onScaleEnd(value);
    } else {
      widget.onOpacityEnd(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final sizeMode = _mode == _SliderMode.size;
    return TextFieldTapRegion(
      child: Focus(
        canRequestFocus: false,
        descendantsAreFocusable: false,
        child: Material(
          color: scheme.surfaceContainerHigh,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Divider(
                height: 1,
                color: scheme.outlineVariant.withValues(alpha: 0.5),
              ),
              // 1. satır: karakter biçimleri + yazı tipi menüsü.
              //
              // KÖK NEDEN (kullanıcı bulgusu 2026-09-23: "biçim menüsüne el
              // at"): satırın TAMAMI yatay kayıyordu ve "kapat" oku en
              // sondaydı. Renk ve yazı tipi düğmeleri de IconButton'ın 48 dp
              // kutusunu kullandığından satır ~480 dp tutuyor, 411 dp'lik
              // telefonda kapat düğmesi EKRAN DIŞINDA kalıyordu — çubuğu
              // kapatmak için önce sağa kaydırmak gerektiği hiçbir yerde
              // belli değildi. Artık kapat sağda SABİT, bütün düğmeler aynı
              // 42×40 kutuda ve kayan kısım sağ kenarda solarak "devamı var"
              // der.
              SizedBox(
                height: 40,
                child: Row(
                  children: [
                    Expanded(
                      child: ShaderMask(
                        blendMode: BlendMode.dstIn,
                        shaderCallback: (rect) => LinearGradient(
                          colors: const [
                            Colors.white,
                            Colors.white,
                            Colors.transparent,
                          ],
                          stops: [
                            0,
                            ((rect.width - 18) / rect.width).clamp(0.0, 1.0),
                            1,
                          ],
                        ).createShader(rect),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              const SizedBox(width: 8),
                              if (widget.onHeading != null)
                                _HeadingMenu(
                                  current: _heading,
                                  onPick: widget.onHeading!,
                                ),
                              _Btn(
                                icon: Icons.format_bold,
                                tooltip: l10n.formatBold,
                                active: _active.bold,
                                onTap: () => widget.onFormat(RichFormat.bold),
                              ),
                              _Btn(
                                icon: Icons.format_italic,
                                tooltip: l10n.formatItalic,
                                active: _active.italic,
                                onTap: () => widget.onFormat(RichFormat.italic),
                              ),
                              _Btn(
                                icon: Icons.format_underlined,
                                tooltip: l10n.formatUnderline,
                                active: _active.underline,
                                onTap: () =>
                                    widget.onFormat(RichFormat.underline),
                              ),
                              const SizedBox(width: 8),
                              _ColorPicker(
                                icon: Icons.format_color_text,
                                tooltip: l10n.formatTextColor,
                                removeLabel: l10n.formatRemove,
                                activeIndex: _active.color,
                                onPick: (i) => widget.onFormat(
                                  RichFormat.color,
                                  colorIndex: i,
                                ),
                                onRemove: () =>
                                    widget.onRemoveFormat(RichFormat.color),
                              ),
                              _ColorPicker(
                                icon: Icons.format_color_fill,
                                tooltip: l10n.formatHighlight,
                                removeLabel: l10n.formatRemove,
                                filled: true,
                                activeIndex: _active.highlight,
                                onPick: (i) => widget.onFormat(
                                  RichFormat.highlight,
                                  colorIndex: i,
                                ),
                                onRemove: () =>
                                    widget.onRemoveFormat(RichFormat.highlight),
                              ),
                              const SizedBox(width: 8),
                              // Biçimi temizle: seçimdeki (ya da imlecin bulunduğu
                              // parçadaki) her biçim tek dokunuşta gider — düğmeleri
                              // tek tek geri basmak gerekmez. Biçimsiz metinde SOLUK
                              // ve tıklanamaz: eskiden her zaman etkin görünüyor ama
                              // çoğu zaman hiçbir şey yapmıyordu, kullanıcı da
                              // düğmenin çalışıp çalışmadığını anlayamıyordu.
                              _Btn(
                                icon: Icons.format_clear,
                                tooltip: l10n.formatClear,
                                onTap: _active.isEmpty
                                    ? null
                                    : widget.onClearFormat,
                              ),
                              const SizedBox(width: 4),
                              // Boyut/şeffaflık satırının aç/kapası.
                              _Btn(
                                key: const ValueKey('format-size-row'),
                                icon: Icons.format_size,
                                tooltip: l10n.noteTextSize,
                                active: _sizeRowOpen,
                                onTap: () => setState(
                                  () => _sizeRowOpen = !_sizeRowOpen,
                                ),
                              ),
                              _FontMenu(
                                family: widget.fontFamily,
                                onChanged: widget.onFontChanged,
                              ),
                              // Sayfa görünümü (zemin/çerçeve rengi, zemin görseli):
                              // metin biçimlerinden ince bir çizgiyle ayrılır — biri
                              // SEÇİME, öteki SAYFANIN tamamına uygulanır.
                              if (widget.onPageStyle != null) ...[
                                const SizedBox(width: 4),
                                SizedBox(
                                  height: 24,
                                  child: VerticalDivider(
                                    width: 9,
                                    thickness: 1,
                                    color: scheme.outlineVariant,
                                  ),
                                ),
                                _Btn(
                                  icon: Icons.palette_outlined,
                                  tooltip: l10n.color,
                                  onTap: widget.onPageStyle,
                                ),
                              ],
                              const SizedBox(width: 18),
                            ],
                          ),
                        ),
                      ),
                    ),
                    _Btn(
                      icon: Icons.keyboard_arrow_down,
                      tooltip: l10n.close,
                      onTap: widget.onClose,
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
              // 2. satır: TEK kaydırıcı — baştaki düğme boyut ile şeffaflık
              // arasında geçiş yapar. Sürüklerken metin anında değişir
              // (kaydırıcı sayfanın altında sabit durduğu için parmağın
              // altından kaçmaz); seçim varsa değişiklik bırakınca seçime iner.
              if (_sizeRowOpen)
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 12, 2),
                child: Row(
                  children: [
                    // ADI YAZILI düğme: yalnız damla ikonu koyunca şeffaflık
                    // ayarını "bilmeyen asla bulamıyordu". Düğme hem o an
                    // neyin sürüklendiğini söyler hem de dokununca ötekine
                    // geçer.
                    Tooltip(
                      message: sizeMode
                          ? l10n.noteTextOpacity
                          : l10n.noteTextSize,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        icon: Icon(
                          sizeMode ? Icons.text_fields : Icons.opacity,
                          size: 18,
                        ),
                        label: Text(
                          sizeMode ? l10n.noteTextSize : l10n.noteTextOpacity,
                          style: const TextStyle(fontSize: 12),
                        ),
                        onPressed: () => setState(() {
                          _drag = null;
                          _mode = sizeMode
                              ? _SliderMode.opacity
                              : _SliderMode.size;
                        }),
                      ),
                    ),
                    Expanded(
                      child: Slider(
                        value: _value.clamp(_min, _max),
                        min: _min,
                        max: _max,
                        onChanged: _onChanged,
                        onChangeEnd: _onChangeEnd,
                      ),
                    ),
                    SizedBox(
                      width: 44,
                      child: Text(
                        '%${(_value * 100).round()}',
                        textAlign: TextAlign.end,
                        style: Theme.of(context).textTheme.labelMedium,
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

/// Yazı tipi seçimi: çipler satır kaplıyordu, artık açılır menü. Her satır
/// KENDİ yazı tipiyle yazılır — seçmeden önce nasıl duracağı görünür.
class _FontMenu extends StatelessWidget {
  const _FontMenu({required this.family, required this.onChanged});

  final String? family;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopupMenuButton<String>(
      tooltip: l10n.noteFont,
      // null bir menü değeri "iptal" ile karışıyor; varsayılan için boş dize.
      onSelected: (value) => onChanged(value.isEmpty ? null : value),
      icon: const Icon(Icons.font_download_outlined, size: 22),
      // Öbür düğmelerle AYNI kutu (42×40): IconButton'ın 48 dp'si satırı
      // taşırıyordu.
      style: _compactStyle(),
      itemBuilder: (context) => [
        for (final font in kNoteFonts)
          PopupMenuItem<String>(
            value: font.id ?? '',
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: (font.id ?? '') == (family ?? '')
                      ? const Icon(Icons.check, size: 18)
                      : null,
                ),
                Expanded(
                  child: Text(
                    noteFontLabel(
                      font.id,
                      defaultLabel: l10n.noteFontDefault,
                      serifLabel: l10n.noteFontSerif,
                      monoLabel: l10n.noteFontMono,
                    ),
                    style: applyNoteFont(
                      const TextStyle(fontSize: 15),
                      font.id,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Biçim şeridi düğmesi: 42×40 kutu, r12.
///
/// IconButton'ın kendi 48×48 kutusu şeritte yan yana yedi düğmeyi dar ekranda
/// taşırıyordu; sabit ölçü hem sığdırır hem alt bardaki araç segmentleriyle
/// aynı yuvarlaklığı verir.
class _Btn extends StatelessWidget {
  const _Btn({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String tooltip;

  /// null ise düğme SOLUK ve tıklanamaz (yapacak işi yok).
  final VoidCallback? onTap;

  /// İmleçteki/seçimdeki biçim bu düğmeninki mi — basılı görünür.
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onTap != null;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: active ? scheme.primaryContainer : null,
            borderRadius: BorderRadius.circular(12),
          ),
          width: 42,
          height: 40,
          child: Icon(
            icon,
            size: 22,
            color: active
                ? scheme.onPrimaryContainer
                : enabled
                ? null
                : scheme.onSurface.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }
}

/// Renk düğmesi: dokununca paletten seçtirir (menü, odak istemez).
///
/// **Palet yeniden yazıldı** (kullanıcı bulgusu 2026-08-09: "biçim alanında
/// işaretlediğim şeyler tam olarak doğru değil; seçiyorum geri bırakamıyorum,
/// çalıştığını anlayamıyorum, iptal etmek ve yapmak zor"). Üç eksik vardı:
/// 1. **Geri dönüş yoktu.** Rengi kaldırmanın tek yolu paletten AYNI rengi
///    ikinci kez seçmekti; hiçbir yerde yazmıyordu. Artık paletin başında
///    kendi "Kaldır" düğmesi var (bkz. [removeRichFormat]).
/// 2. **Hangi renk seçili görünmüyordu.** Palet dizisi hepsini eşit
///    gösteriyordu; şimdi etkin renk TİKLİ ve kalın halkalı.
/// 3. **Uygulandı mı belli değildi.** Şeritteki düğme zaten renk şeridi
///    çiziyordu ama menü kapanınca göz oraya gitmiyordu; tik menünün
///    içindeyken de aynı bilgiyi verir.
class _ColorPicker extends StatelessWidget {
  const _ColorPicker({
    required this.icon,
    required this.tooltip,
    required this.removeLabel,
    required this.onPick,
    required this.onRemove,
    this.filled = false,
    this.activeIndex,
  });

  final IconData icon;
  final String tooltip;

  /// "Kaldır" düğmesinin etiketi (ipucu + erişilebilirlik).
  final String removeLabel;
  final ValueChanged<int> onPick;

  /// Biçmi tümüyle düşürür.
  final VoidCallback onRemove;
  final bool filled;

  /// İmleçteki/seçimdeki renk indeksi (1..n), yoksa null. Dolu olduğunda
  /// düğme basılı çizilir ve ikonun altına o rengin şeridi konur — hangi
  /// rengin uygulandığı menüyü açmadan görünsün.
  final int? activeIndex;

  @override
  Widget build(BuildContext context) {
    final palette = NoteColors.richPalette;
    final scheme = Theme.of(context).colorScheme;
    final index = activeIndex;
    // Palet dışında kalan indeks (eski nottan gelen) rengi çizdirmez ama
    // düğme yine basılı görünür — biçim gerçekten orada.
    final color = isCustomRichColor(index)
        ? Color(index!)
        : index != null && index >= 1 && index <= palette.length
        ? palette[index - 1]
        : null;
    return PopupMenuButton<int>(
      tooltip: tooltip,
      icon: index == null
          ? Icon(icon, size: 22)
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: scheme.onPrimaryContainer),
                const SizedBox(height: 2),
                Container(
                  width: 18,
                  height: 3,
                  decoration: BoxDecoration(
                    color: color ?? scheme.onPrimaryContainer,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
      style: _compactStyle(
        background: index == null ? null : scheme.primaryContainer,
      ),
      // 0 = "Kaldır" (palet indeksleri 1'den başlar, çakışma yok);
      // -1 = tam palet levhası (özel renk ARGB olarak döner).
      onSelected: (value) async {
        if (value == 0) {
          onRemove();
        } else if (value == -1) {
          final picked = await showColorPaletteSheet(
            context,
            title: tooltip,
            current: color,
          );
          if (picked != null) onPick(picked.toARGB32() | 0xFF000000);
        } else {
          onPick(value);
        }
      },
      itemBuilder: (menuContext) => [
        PopupMenuItem<int>(
          enabled: false,
          height: 44,
          child: Row(
            children: [
              // "Kaldır" HER ZAMAN görünür (biçim yokken de): düğmenin
              // yerinin sabit olması, "bir renk verdim, nasıl geri alırım"
              // sorusunun cevabını her açılışta aynı yerde tutar.
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 12),
                child: Tooltip(
                  message: removeLabel,
                  child: InkWell(
                    onTap: () => Navigator.pop(menuContext, 0),
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: scheme.outline, width: 2),
                      ),
                      child: Icon(
                        Icons.format_color_reset,
                        size: 16,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
              for (var i = 0; i < palette.length; i++)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 10),
                  child: InkWell(
                    onTap: () => Navigator.pop(menuContext, i + 1),
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: filled
                            ? palette[i].withValues(alpha: 0.45)
                            : Colors.transparent,
                        border: Border.all(
                          color: palette[i],
                          width: index == i + 1 ? 4 : 3,
                        ),
                      ),
                      // Seçili renk TİKLİ: hangisinin uygulandığı menüde de
                      // görünsün.
                      child: index == i + 1
                          ? Icon(Icons.check, size: 15, color: palette[i])
                          : null,
                    ),
                  ),
                ),
              // TAM PALET: hazır tonlar + özel renk (bkz. color_palette.dart).
              Tooltip(
                message: menuContext.l10n.paletteMore,
                child: InkWell(
                  key: const ValueKey('format-palette-more'),
                  onTap: () => Navigator.pop(menuContext, -1),
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [
                          Color(0xFFE57373),
                          Color(0xFFFFD54F),
                          Color(0xFF81C784),
                          Color(0xFF64B5F6),
                          Color(0xFF9575CD),
                          Color(0xFFE57373),
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.palette_outlined,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Biçim çubuğunun uygulayacağı hedef: o an odaklı metin alanı.
///
/// Gövde ve her liste maddesi ayrı denetleyici kullanıyor; çubuk hangisine
/// yazacağını bilmeli. Odak değiştikçe editör burayı tazeler.
@immutable
class FormatTarget {
  const FormatTarget({
    required this.controller,
    required this.focusNode,
    required this.commit,
  });

  final WrapTextController controller;

  /// Alanın odak düğümü: biçim uygulandıktan sonra odak (ve klavye) geri
  /// verilir — kullanıcı yazmaya kaldığı yerden devam eder.
  final FocusNode focusNode;

  /// Metin değişince notu kaydeden geri çağrı (programlı değişiklikte
  /// TextField'ın `onChanged`'i çalışmaz).
  final VoidCallback commit;
}

/// Açılır menü düğmelerini (renk, yazı tipi) şeridin [_Btn] ölçüsüne indirir.
ButtonStyle _compactStyle({Color? background}) => IconButton.styleFrom(
  backgroundColor: background,
  fixedSize: const Size(42, 40),
  minimumSize: const Size(42, 40),
  padding: EdgeInsets.zero,
  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
);

/// **BAŞLIK menüsü** (kullanıcı isteği 2026-09-23: "başlık ve alt başlık").
/// İmlecin satırı büyük başlık / alt başlık / düz metin olur. Satır zaten
/// başlıksa düğme basılı görünür ve o düzey menüde tiklidir.
class _HeadingMenu extends StatelessWidget {
  const _HeadingMenu({required this.current, required this.onPick});

  final RichHeading current;
  final ValueChanged<RichHeading> onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final active = current != RichHeading.normal;
    String label(RichHeading h) => switch (h) {
      RichHeading.h1 => l10n.formatHeading1,
      RichHeading.h2 => l10n.formatHeading2,
      RichHeading.normal => l10n.formatNormalText,
    };
    double size(RichHeading h) => switch (h) {
      RichHeading.h1 => 20,
      RichHeading.h2 => 17,
      RichHeading.normal => 14,
    };
    return PopupMenuButton<RichHeading>(
      tooltip: l10n.formatHeading,
      style: _compactStyle(
        background: active ? scheme.primaryContainer : null,
      ),
      icon: Icon(
        Icons.title,
        size: 22,
        color: active ? scheme.onPrimaryContainer : null,
      ),
      onSelected: onPick,
      itemBuilder: (context) => [
        for (final h in RichHeading.values)
          PopupMenuItem<RichHeading>(
            value: h,
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: h == current
                      ? const Icon(Icons.check, size: 18)
                      : null,
                ),
                Text(
                  label(h),
                  style: TextStyle(
                    fontSize: size(h),
                    fontWeight: h == RichHeading.normal
                        ? FontWeight.w400
                        : FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// **ETKİN BİÇİMLER — PANEL KAPALIYKEN** (kullanıcı isteği 2026-10-20: "bold
/// italik vb. altta nelerin aktif olduğu görülsün, biçim paneli haricinde").
/// Alt çubuktaki Biçim düğmesinin yanında, imlecin/seçimin üzerindeki
/// biçimleri küçük rozetlerle gösterir; hiçbiri yoksa yer kaplamaz.
///
/// Hedef alan [target] üzerinden izlenir (odak her satırda değiştiği için
/// editörün tamamını yeniden kurmadan), denetleyici yalnız rozetler
/// GERÇEKTEN değişince çizdirir.
class ActiveFormatBadges extends StatefulWidget {
  const ActiveFormatBadges({super.key, required this.target});

  final ValueListenable<FormatTarget?> target;

  @override
  State<ActiveFormatBadges> createState() => _ActiveFormatBadgesState();
}

class _ActiveFormatBadgesState extends State<ActiveFormatBadges> {
  WrapTextController? _controller;
  RichMark _mark = RichMark.none;
  RichHeading _heading = RichHeading.normal;

  @override
  void initState() {
    super.initState();
    widget.target.addListener(_retarget);
    _retarget();
  }

  @override
  void dispose() {
    widget.target.removeListener(_retarget);
    _controller?.removeListener(_refresh);
    super.dispose();
  }

  void _retarget() {
    final next = widget.target.value?.controller;
    if (next == _controller) return;
    _controller?.removeListener(_refresh);
    _controller = next?..addListener(_refresh);
    _refresh();
  }

  void _refresh() {
    if (!mounted) return;
    final c = _controller;
    final mark = c == null ? RichMark.none : activeRichFormats(c);
    final heading = c == null ? RichHeading.normal : activeRichHeading(c);
    if (mark != _mark || heading != _heading) {
      setState(() {
        _mark = mark;
        _heading = heading;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = NoteColors.richPalette;
    Color? resolve(int? index) {
      if (index == null) return null;
      if (isCustomRichColor(index)) return Color(index);
      if (index < 1 || index > palette.length) return scheme.primary;
      return palette[index - 1];
    }

    Widget letter(String text, {TextStyle? style}) => Padding(
      padding: const EdgeInsetsDirectional.only(end: 2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            height: 1.2,
            color: scheme.onPrimaryContainer,
          ).merge(style),
        ),
      ),
    );

    Widget dot(Color color, {bool filled = true}) => Padding(
      padding: const EdgeInsetsDirectional.only(end: 2),
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? color.withValues(alpha: 0.6) : null,
          border: Border.all(color: color, width: 2),
        ),
      ),
    );

    final badges = <Widget>[
      if (_heading != RichHeading.normal)
        letter(
          _heading == RichHeading.h1 ? 'H1' : 'H2',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      if (_mark.bold)
        letter('B', style: const TextStyle(fontWeight: FontWeight.w800)),
      if (_mark.italic)
        letter('I', style: const TextStyle(fontStyle: FontStyle.italic)),
      if (_mark.underline)
        letter(
          'U',
          style: const TextStyle(decoration: TextDecoration.underline),
        ),
      if (_mark.color != null) dot(resolve(_mark.color)!, filled: false),
      if (_mark.highlight != null) dot(resolve(_mark.highlight)!),
    ];
    if (badges.isEmpty) return const SizedBox.shrink();
    return Semantics(
      container: true,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: 2, end: 4),
        child: Row(mainAxisSize: MainAxisSize.min, children: badges),
      ),
    );
  }
}
