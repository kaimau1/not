import '../../../../core/widgets/back_closes.dart';
import '../../../../app/theme/fixed_colors.dart';
import '../../../../core/app_icons.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/note_colors.dart';
import '../../../../core/a11y/color_names.dart';
import '../../../../core/l10n_ext.dart';
import '../../../../core/utils/note_fonts.dart';
import '../../../../core/utils/rich_text.dart';
import '../../../../core/utils/sentence_select.dart';
import '../../../../core/widgets/color_palette.dart';
import 'format_menu.dart';
import 'text_wrap.dart';

/// Klavyenin hemen üstünde duran biçim paneli.
///
/// **İKİNCİ KEZ SIFIRDAN** (kullanıcı isteği 2026-10-28: "biçim menüsü
/// üzerine sıfırdan çalış, baştan tasarla, her yönü yerleşim kullanım
/// değiştirebilirsin"). 2026-10-20 sürümü tek satırdı ama en sık işlerin
/// (başlık, renk) hepsi bir TEPSİ arkasındaydı: başlık için iki, renk için
/// iki dokunuş, renk tepsisi de iki satır yer kaplıyordu. Yeni panel ÜÇ SABİT
/// SIRA; sık işlerin hepsi TEK dokunuş:
///  1. **Stil** — Metin · Başlık · Alt başlık hapları + B · I · U.
///  2. **Renk** — solda yazı rengi / vurgu anahtarı (her birinin altında
///     etkin renk şeridi), yanında 5 ton + tam palet + kaldır.
///  3. **Yazı** — yazı tipi tepsisi (Aa), boyut − %100 +, temizle, kapat.
///
/// F12.5 (2026-10-31): "Tümüne uygula" kalktı — kapsam "Tümü" aynı işi
/// yapıyordu (Tümü seçiliyken her biçim alanın tamamına işler); "Sayfa
/// rengi" kalktı — sayfa görünümünün tek kapısı üst çubuktaki palet (F12.6,
/// kullanıcı kararı). Kapsam sırası elle seçim VARKEN gizlenir: seçim zaten
/// kapsamdır.
/// Yalnız yazı tipi listesi ve ince ayar kaydırıcıları (boyut, şeffaflık)
/// panelin ÜSTÜNDE açılan tepside; menü katmanı yok, metin örtülmez.
///
/// KRİTİK — ODAK: çubuktaki hiçbir öğe odak istemez
/// (`Focus(canRequestFocus: false, descendantsAreFocusable: false)` +
/// [TextFieldTapRegion]). Aksi hâlde düğmeye dokunmak metin alanının odağını
/// düşürür, odakla birlikte SEÇİM de gider ve biçim uygulanacak metin
/// kalmazdı. Tepsiler de menü rotası açmadığından seçim hiç bozulmaz.
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
    this.onHeading,
    this.dividerKind,
    this.onDivider,
    this.onDividerStyle,
  });

  /// **ALT ÇİZGİ** (kullanıcı isteği 2026-10-30: "alta çizgi ekle'yi biçim
  /// menüsüne taşıyalım"): hedef bir MADDEYSE onun ayırıcı türü ('' = yok);
  /// null ise sıra çizilmez (gövde/başlık). Aynı türe basmak kaldırır.
  final String? dividerKind;
  final ValueChanged<String>? onDivider;
  final VoidCallback? onDividerStyle;

  /// Satırı başlık / alt başlık / düz metin yapar (bkz. [setLineHeading]).
  /// null ise başlık düğmesi çizilmez (notun başlık alanı zaten başlık).
  final ValueChanged<RichHeading>? onHeading;

  /// Çubuğun yazdığı alan. Yalnız AKTİF BİÇİM vurgusu için gerekli: imleç ya
  /// da seçim değiştikçe hangi düğmenin basılı duracağı buradan hesaplanır
  /// (bkz. [activeRichFormats]). null ise hiçbir düğme vurgulanmaz.
  final FormatTarget? target;

  /// Biçim düğmesine basıldı: seçime uygula (seçim yoksa imlece kutu aç).
  final void Function(RichFormat format, {int? colorIndex}) onFormat;

  /// Seçimdeki tüm biçimleri siler.
  final VoidCallback onClearFormat;

  /// Renk satırındaki "Kaldır": YALNIZ o biçmi (yazı rengi ya da vurgu)
  /// düşürür.
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

/// Panelin ÜSTÜNDE açılan tepsi (2026-11-05: renk ve çizgi tepside — panel
/// iki sıraya indi). Stil ve kapsam tepsisi YOK: haplara basmak sırayla
/// geçer (kullanıcı isteği 2026-11-05, bkz. [_FormatBarState._cycleScope]).
enum _Tray { none, font, color, divider }

/// Renk satırının yazdığı biçim: yazı rengi mi, vurgu mu.
enum _ColorMode { text, highlight }

/// Kaydırıcının sürüklediği değer.
enum _Slide { size, opacity }

/// Boyut adımı (− / + düğmeleri) ve sınırlar — kaydırıcıyla aynı aralık.
const _kScaleStep = 0.1;
const _kScaleMin = 0.7;
const _kScaleMax = 2.0;

/// Biçimin İMLEÇ boşken neye uygulanacağı (kullanıcı bulgusu 2026-10-30:
/// "bir yazıyı değiştirmek işkence, tek tek seçmek gerekiyor, tek satıra
/// boyut vermek zor, maddelerde seçim zor"). Panelin üst sırasında seçilir
/// ve oturum boyu hatırlanır: "Satır" seçiliyken imleci bir satıra koyup
/// B / renk / boyut +'ya basmak o satırın TAMAMINA işler — elle seçim yok.
enum FormatScope { caret, word, line, all }

/// [scope]'a göre imleçten genişletilmiş seçim; değişiklik yoksa null
/// (imleç kipi, zaten seçili metin, boş kapsam). [text] denetleyicinin
/// görüntü metni (sarma çapaları satır sonu değil — `\n`e güvenilir).
TextSelection? scopeSelection(
  String text,
  TextSelection selection,
  FormatScope scope,
) {
  if (scope == FormatScope.caret || !selection.isValid) return null;
  if (!selection.isCollapsed || text.isEmpty) return null;
  final caret = selection.baseOffset.clamp(0, text.length);
  var start = caret;
  var end = caret;
  switch (scope) {
    case FormatScope.caret:
      return null;
    case FormatScope.word:
      while (start > 0 && isRichWordChar(text[start - 1])) {
        start--;
      }
      while (end < text.length && isRichWordChar(text[end])) {
        end++;
      }
    case FormatScope.line:
      start = caret == 0 ? 0 : text.lastIndexOf('\n', caret - 1) + 1;
      final next = text.indexOf('\n', caret);
      end = next < 0 ? text.length : next;
    case FormatScope.all:
      start = 0;
      end = text.length;
  }
  if (end <= start) return null;
  return TextSelection(baseOffset: start, extentOffset: end);
}

class _FormatBarState extends State<FormatBar> {
  /// Oturum boyu hatırlanan kapsam (panel her açılışta sıfırlanmasın).
  static FormatScope _lastScope = FormatScope.caret;
  FormatScope _scope = _lastScope;

  _Tray _tray = _Tray.none;
  _ColorMode _colorMode = _ColorMode.text;

  /// Sürüklerken canlı önizlemenin seyreltilmesi (kullanıcı bulgusu
  /// 2026-10-20: "biçim panelindeki değişiklikler kasıyor"): her kaydırıcı
  /// olayı bütün notu yeni boyla yeniden dizdiriyordu (uzun notta kare
  /// başına onlarca ms). Önizleme en çok 70 ms'de bir uygulanır; bırakınca
  /// son değer kesin yazılır.
  Timer? _liveTimer;
  double? _liveValue;
  _Slide? _liveSlide;

  /// Sürükleme sürerken (ya da seçime uygulandıktan sonra) parmağın değeri.
  /// Seçim varken sayfa değişmediği için kaydırıcı yalnız buradan beslenir
  /// — yoksa topuz parmağın altında donardı.
  final Map<_Slide, double> _drag = {};

  /// İmleçte/seçimde etkin olan biçimler; düğme vurgusu bundan çizilir.
  RichMark _active = RichMark.none;

  /// İmlecin satırının başlık düzeyi.
  RichHeading _heading = RichHeading.normal;

  /// Kullanıcı ELLE metin seçti mi (kapsamın GEÇİCİ seçimi sayılmaz). Seçim
  /// varken kapsam düğmesi "Seçim" der: seçim zaten kapsamdır (F12.5).
  bool _manualSelection = false;

  bool _computeManualSelection() {
    final selection = widget.target?.controller.selection;
    if (selection == null || !selection.isValid || selection.isCollapsed) {
      return false;
    }
    return _scopedSelection == null;
  }

  @override
  void initState() {
    super.initState();
    _watchTarget(null);
  }

  @override
  void didUpdateWidget(covariant FormatBar old) {
    super.didUpdateWidget(old);
    if (old.target?.controller != widget.target?.controller) {
      _clearPreviewLater(old.target?.controller);
      _watchTarget(old.target);
      // Başka alana geçildi: seçime uygulanmış kaydırıcı değeri artık o
      // alanın değil.
      _drag.clear();
      _scopedSelection = null;
      _scopeCaret = null;
    }
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    widget.target?.controller.removeListener(_refreshActive);
    _clearPreviewLater(widget.target?.controller);
    super.dispose();
  }

  /// Önizlemeyi bir kare SONRA kaldırır: dispose/didUpdateWidget ağaç
  /// kilitliyken koşar, denetleyici bildirimi alanı yeniden kurdurmaya
  /// çalışırdı. Atılmış denetleyici kendini korur.
  static void _clearPreviewLater(WrapTextController? controller) {
    if (controller == null) return;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => controller.setScopePreview(null),
    );
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
    _manualSelection = _computeManualSelection();
    // Önizleme bildirimi build'den sonra (initState/didUpdateWidget içinde
    // denetleyiciyi dinleyen alan yeniden kurulamaz).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncPreview();
    });
  }

  /// Kapsamın kapsayacağı parça ekranda soluk zeminle görünür (bkz.
  /// [WrapTextController.setScopePreview]). İmleç kipinde, elle seçimde ve
  /// biçim uygulanırken (geçici seçim açık) önizleme yok.
  void _syncPreview() {
    final controller = widget.target?.controller;
    if (controller == null) return;
    final selection = controller.selection;
    final range = _scopedSelection != null
        ? null
        : scopeSelection(controller.text, selection, _scope);
    controller.setScopePreview(
      range == null ? null : (range.start, range.end),
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.16),
    );
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
    final manual = _computeManualSelection();
    // Her tuş vuruşunda değil, vurgu GERÇEKTEN değişince çiz.
    if (next != _active || heading != _heading || manual != _manualSelection) {
      setState(() {
        _active = next;
        _heading = heading;
        _manualSelection = manual;
      });
    }
    _syncPreview();
  }

  /// **KAPSAM SEÇİMİ GEÇİCİ** (kullanıcı bulgusu 2026-11-05: "imleç kelime
  /// satır doğru çalışmıyor"). KÖK NEDEN: kapsam seçildiği anda kelime/satır
  /// SEÇİLİ kalıyordu; biçim işaretleri seçimi kaydırınca seçim "elle
  /// seçim" sanılıyor (kapsam sırası gizlenip panel zıplıyor, sonraki
  /// kapsamlar o seçime takılıyor), yazmaya devam eden kullanıcı da seçili
  /// kelimeyi SİLİYORDU. Artık kapsam yalnız biçim UYGULANIRKEN imleçten
  /// açılır, iş bitince imleç aynı göreli yere döner: seçim hiç kalmaz.
  /// [_scopedSelection] o an açık geçici seçim (kaydırıcı sürüklenirken
  /// sürer), [_scopeCaret] dönülecek imleç.
  TextSelection? _scopedSelection;
  int? _scopeCaret;

  /// İmleç boşsa seçimi kapsama genişletir; açtığı (ya da hâlâ açık olan)
  /// geçici seçimi döndürür — elle seçimde ve İmleç kapsamında null.
  TextSelection? _applyScopeTracked() {
    final controller = widget.target?.controller;
    if (controller == null) return null;
    final open = _scopedSelection;
    if (open != null) {
      if (controller.selection == open) return open;
      // Başka bir şey seçimi değiştirdi: geçici seçim bitti.
      _scopedSelection = null;
      _scopeCaret = null;
    }
    final selection = controller.selection;
    if (!selection.isValid || !selection.isCollapsed) return null;
    final next = scopeSelection(controller.text, selection, _scope);
    if (next == null) return null;
    _scopeCaret = selection.baseOffset;
    _scopedSelection = next;
    // Geçici seçim çift dokunuş sanılıp cümleye büyütülmesin (bkz.
    // [withoutSentenceExpansion]).
    withoutSentenceExpansion(() => controller.selection = next);
    return next;
  }

  void _applyScope() => _applyScopeTracked();

  /// İş bitti: geçici seçim imlece döner. Biçim işaretleri seçimi
  /// kaydırdıysa imleç yeni aralıkta aynı göreli yere konur.
  void _releaseScope(TextSelection? before) {
    final controller = widget.target?.controller;
    final caret = _scopeCaret;
    _scopedSelection = null;
    _scopeCaret = null;
    if (controller == null || before == null || caret == null) return;
    final after = controller.selection;
    var offset = caret;
    if (after.isValid && !after.isCollapsed) {
      final relative = (caret - before.start).clamp(
        0,
        before.end - before.start,
      );
      offset = (after.start + relative).clamp(after.start, after.end);
    } else if (after.isValid) {
      offset = after.baseOffset;
    }
    controller.selection = TextSelection.collapsed(
      offset: offset.clamp(0, controller.text.length),
    );
  }

  /// Kapsamlı biçim işi: seçim geçici olarak genişler, iş koşar, imleç
  /// geri döner.
  void _scoped(VoidCallback action) {
    final before = _applyScopeTracked();
    action();
    _releaseScope(before);
    _syncPreview();
  }

  /// **KAPSAM SIRAYLA GEÇER** (kullanıcı isteği 2026-11-05: "yeni bir seçim
  /// ekranı açılmasına gerek yok, butona basarak sırayla geçsin"): İmleç →
  /// Kelime → Satır → Tümü → İmleç. Elle seçim varken ilk basış seçimi
  /// bırakır (imleç seçimin ucunda) ve son kapsama döner — eskiden düğme
  /// "Seçim"de kilitli kalıyor, kapsam değiştirilemiyordu.
  void _cycleScope() {
    final controller = widget.target?.controller;
    final selection = controller?.selection;
    if (_manualSelection &&
        controller != null &&
        selection != null &&
        selection.isValid) {
      controller.selection = TextSelection.collapsed(
        offset: selection.extentOffset,
      );
      return;
    }
    const order = FormatScope.values;
    setState(() {
      _scope = _lastScope = order[(order.indexOf(_scope) + 1) % order.length];
      _tray = _Tray.none;
    });
    _syncPreview();
  }

  /// **STİL SIRAYLA GEÇER** (kullanıcı isteği 2026-11-05): Metin → Başlık →
  /// Alt başlık → Metin; tepsi açılmaz.
  void _cycleHeading() {
    final next = switch (_heading) {
      RichHeading.normal => RichHeading.h1,
      RichHeading.h1 => RichHeading.h2,
      RichHeading.h2 => RichHeading.normal,
    };
    setState(() => _tray = _Tray.none);
    widget.onHeading?.call(next);
  }

  void _toggleTray(_Tray tray) =>
      setState(() => _tray = _tray == tray ? _Tray.none : tray);

  double _value(_Slide slide) =>
      _drag[slide] ??
      (slide == _Slide.size ? widget.fontScale : widget.textOpacity);

  void _onSlide(_Slide slide, double value) {
    if (!_drag.containsKey(slide)) _applyScope();
    setState(() => _drag[slide] = value);
    // Canlı önizleme yalnız NOT GENELİNDE: seçim varken değişiklik bırakınca
    // ve yalnız seçime uygulanır.
    if (widget.hasSelection()) return;
    if (_liveSlide != null && _liveSlide != slide) _flushLive();
    _liveSlide = slide;
    _liveValue = value;
    _liveTimer ??= Timer(const Duration(milliseconds: 70), _flushLive);
  }

  void _flushLive() {
    _liveTimer?.cancel();
    _liveTimer = null;
    final value = _liveValue;
    final slide = _liveSlide;
    _liveValue = null;
    _liveSlide = null;
    if (value == null || slide == null || !mounted) return;
    if (slide == _Slide.size) {
      widget.onScaleChanged(value);
    } else {
      widget.onOpacityChanged(value);
    }
  }

  void _onSlideEnd(_Slide slide, double value) {
    final scoped = _applyScopeTracked();
    _liveTimer?.cancel();
    _liveTimer = null;
    _liveValue = null;
    _liveSlide = null;
    // Seçime uygulandıysa topuz BIRAKILDIĞI yerde kalır: not geneli
    // değişmediği için sıfırlansa kaydırıcı %100'e geri zıplar ve kullanıcı
    // az önce ne uyguladığını göremezdi.
    setState(() {
      if (widget.hasSelection()) {
        _drag[slide] = value;
      } else {
        _drag.remove(slide);
      }
    });
    if (slide == _Slide.size) {
      widget.onScaleEnd(value);
    } else {
      widget.onOpacityEnd(value);
    }
    _releaseScope(scoped);
  }

  /// − / + düğmesi: boyutu bir adım değiştirip HEMEN uygular (seçim varsa
  /// seçime, yoksa nota — kaydırıcıyı bırakmakla aynı yol).
  void _stepScale(int direction) {
    final scoped = _applyScopeTracked();
    // SEÇİME (kapsamla seçilmiş satıra) boyut: satır içi kademelerde bir
    // adım — not genelindeki %10'luk adım kademeye yuvarlanınca ilk basış
    // hiçbir şey yapmıyordu.
    if (widget.hasSelection()) {
      final controller = widget.target?.controller;
      final index =
          (controller == null ? null : activeRichFormats(controller).size) ??
          kRichSizeDefault;
      final next = (index + direction).clamp(1, kRichSizeSteps.length);
      final value = kRichSizeSteps[next - 1];
      setState(() => _drag[_Slide.size] = value);
      widget.onScaleEnd(value);
      _releaseScope(scoped);
      return;
    }
    final current = _value(_Slide.size);
    final next = ((current / _kScaleStep).round() + direction) * _kScaleStep;
    _onSlideEnd(
      _Slide.size,
      double.parse(next.clamp(_kScaleMin, _kScaleMax).toStringAsFixed(2)),
    );
  }

  /// Etkin yazı rengi / vurgu indeksinin ekrandaki rengi (yoksa null).
  static Color? _resolve(int? index) {
    final palette = NoteColors.richPalette;
    if (index == null) return null;
    if (isCustomRichColor(index)) return Color(index);
    if (index < 1 || index > palette.length) return null;
    return palette[index - 1];
  }

  String _scopeLabel(AppLocalizations l10n) => _manualSelection
      ? l10n.formatScopeSelection
      : switch (_scope) {
          FormatScope.caret => l10n.formatScopeCaret,
          FormatScope.word => l10n.formatScopeWord,
          FormatScope.line => l10n.formatScopeLine,
          FormatScope.all => l10n.formatScopeAll,
        };

  String _headingLabel(AppLocalizations l10n) => switch (_heading) {
    RichHeading.h1 => l10n.formatStyleH1,
    RichHeading.h2 => l10n.formatStyleH2,
    _ => l10n.formatStyleText,
  };

  /// Açık tepsinin içeriği (panelin ÜSTÜNDE).
  Widget _trayContent(BuildContext context) {
    final l10n = context.l10n;
    final highlightMode = _colorMode == _ColorMode.highlight;
    return switch (_tray) {
      _Tray.none => const SizedBox(width: double.infinity),
      _Tray.font => _FontTray(
        family: widget.fontFamily,
        onFont: widget.onFontChanged,
        size: _value(_Slide.size),
        opacity: _value(_Slide.opacity),
        onSlide: _onSlide,
        onSlideEnd: _onSlideEnd,
      ),
      // RENK: soldaki anahtar neyin boyanacağını seçer (yazı / vurgu); tepsi
      // açık kalır — art arda renk denenebilir.
      _Tray.color => _PanelRow(
        children: [
          _ModeSwitch(
            mode: _colorMode,
            textColor: _resolve(_active.color),
            highlightColor: _resolve(_active.highlight),
            onChanged: (mode) => setState(() => _colorMode = mode),
          ),
          const _Gap(),
          Expanded(
            child: _ColorRow(
              key: ValueKey('format-colors-$_colorMode'),
              keyPrefix: highlightMode ? 'format-highlight' : 'format-color',
              label: highlightMode
                  ? l10n.formatHighlight
                  : l10n.formatTextColor,
              activeIndex: highlightMode ? _active.highlight : _active.color,
              filled: highlightMode,
              onPick: (i) => _scoped(
                () => widget.onFormat(
                  highlightMode ? RichFormat.highlight : RichFormat.color,
                  colorIndex: i,
                ),
              ),
              onRemove: () => _scoped(
                () => widget.onRemoveFormat(
                  highlightMode ? RichFormat.highlight : RichFormat.color,
                ),
              ),
            ),
          ),
        ],
      ),
      _Tray.divider => _DividerRow(
        kind: widget.dividerKind ?? '',
        onPick: (k) => widget.onDivider?.call(k),
        onStyle: widget.onDividerStyle,
      ),
    };
  }

  /// **İKİ SIRA + AÇILIR TEPSİLER** (kullanıcı isteği 2026-11-05: "biçim
  /// panelinde küçülme, açılır pencereler olsun; çok satır var çok yer
  /// kaplıyor"). Eskiden kapsam + (çizgi) + stil + renk + yazı = dört-beş
  /// sıra (~180 dp) klavyenin üstünde notu örtüyordu. Şimdi:
  ///  1. Stil ▾ · B · I · U · Renk ▾
  ///  2. Kapsam ▾ · Aa · A− · %100 · A+ · temizle · (çizgi) · kapat
  /// Stil, renk, kapsam, çizgi ve yazı tipi panelin ÜSTÜNDE açılan tepside
  /// (menü rotası yok — odak ve klavye yerinde kalır, bkz. sınıf belgesi).
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final size = _value(_Slide.size);
    final divider = Divider(
      height: 1,
      color: scheme.outlineVariant.withValues(alpha: 0.4),
    );
    return BackCloses(
      open: _tray != _Tray.none,
      onClose: () => setState(() => _tray = _Tray.none),
      child: TextFieldTapRegion(
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
              // TEPSİ panelin ÜSTÜNDE: göz yazıdan çok uzaklaşmaz, alttaki
              // sıralar parmağın altında oynamaz.
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                alignment: Alignment.bottomCenter,
                child: _tray == _Tray.none
                    ? const SizedBox(width: double.infinity)
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [_trayContent(context), divider],
                      ),
              ),
              // 1. SIRA — STİL ▾ · B · I · U · RENK ▾
              _PanelRow(
                children: [
                  if (widget.onHeading != null) ...[
                    Expanded(
                      flex: 5,
                      child: _MenuChip(
                        key: const ValueKey('format-style-menu'),
                        open: false,
                        cycles: true,
                        tooltip: l10n.formatStyleMenu,
                        onTap: _cycleHeading,
                        child: Text(
                          _headingLabel(l10n),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: _heading == RichHeading.normal
                                ? FontWeight.w500
                                : FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const _Gap(),
                  ],
                  _Btn(
                    key: const ValueKey('format-bold'),
                    flex: 3,
                    icon: Icons.format_bold,
                    tooltip: l10n.formatBold,
                    active: _active.bold,
                    onTap: () => _scoped(() => widget.onFormat(RichFormat.bold)),
                  ),
                  _Btn(
                    key: const ValueKey('format-italic'),
                    flex: 3,
                    icon: Icons.format_italic,
                    tooltip: l10n.formatItalic,
                    active: _active.italic,
                    onTap: () => _scoped(() => widget.onFormat(RichFormat.italic)),
                  ),
                  _Btn(
                    key: const ValueKey('format-underline'),
                    flex: 3,
                    icon: Icons.format_underlined,
                    tooltip: l10n.formatUnderline,
                    active: _active.underline,
                    onTap: () =>
                        _scoped(() => widget.onFormat(RichFormat.underline)),
                  ),
                  const _Gap(),
                  Expanded(
                    flex: 4,
                    child: _MenuChip(
                      key: const ValueKey('format-color-menu'),
                      open: _tray == _Tray.color,
                      tooltip: l10n.formatTextColor,
                      onTap: () => _toggleTray(_Tray.color),
                      child: _ColorGlyph(
                        text: _resolve(_active.color),
                        highlight: _resolve(_active.highlight),
                      ),
                    ),
                  ),
                ],
              ),
              divider,
              // 2. SIRA — KAPSAM ▾ · yazı tipi · boyut − / + · temizle ·
              // (çizgi) · kapat.
              _PanelRow(
                children: [
                  Expanded(
                    flex: 2,
                    child: _MenuChip(
                      key: const ValueKey('format-scope-menu'),
                      open: false,
                      cycles: true,
                      tooltip: l10n.formatScopeHint,
                      onTap: _cycleScope,
                      child: Text(
                        _scopeLabel(l10n),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12.5),
                      ),
                    ),
                  ),
                  _Btn(
                    key: const ValueKey('format-font'),
                    icon: Icons.text_fields,
                    tooltip: l10n.formatFontPanel,
                    open: _tray == _Tray.font,
                    onTap: () => _toggleTray(_Tray.font),
                  ),
                  _Btn(
                    key: const ValueKey('format-size-down'),
                    icon: Icons.text_decrease,
                    tooltip: l10n.formatSizeDown,
                    onTap: size <= _kScaleMin + 0.001
                        ? null
                        : () => _stepScale(-1),
                  ),
                  // "%100" tek başına ne olduğunu söylemiyordu (F12.5):
                  // üstte küçük "Boyut", ekran okuyucu "Boyut %100" okur.
                  Semantics(
                    label: l10n.formatSizeValue((size * 100).round()),
                    excludeSemantics: true,
                    child: SizedBox(
                      width: 44,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.formatSizeLabel,
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                            softWrap: false,
                            style: TextStyle(
                              fontSize: 9.5,
                              height: 1.1,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            '%${(size * 100).round()}',
                            key: const ValueKey('format-size-value'),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  _Btn(
                    key: const ValueKey('format-size-up'),
                    icon: Icons.text_increase,
                    tooltip: l10n.formatSizeUp,
                    onTap: size >= _kScaleMax - 0.001
                        ? null
                        : () => _stepScale(1),
                  ),
                  // Biçimi temizle: biçimsiz metinde SOLUK ve tıklanamaz —
                  // düğmenin işe yarayıp yaramadığı görünür.
                  _Btn(
                    key: const ValueKey('format-clear'),
                    icon: Icons.format_clear,
                    tooltip: l10n.formatClear,
                    onTap: _active.isEmpty && _scope == FormatScope.caret
                        ? null
                        : () => _scoped(widget.onClearFormat),
                  ),
                  // Maddenin ALT ÇİZGİSİ (yalnız madde hedefinde).
                  if (widget.dividerKind != null)
                    _Btn(
                      key: const ValueKey('format-divider-menu'),
                      icon: Icons.horizontal_rule,
                      tooltip: l10n.itemMenuLine,
                      active: widget.dividerKind!.isNotEmpty,
                      open: _tray == _Tray.divider,
                      onTap: () => _toggleTray(_Tray.divider),
                    ),
                  SizedBox(
                    height: 26,
                    child: VerticalDivider(
                      width: 7,
                      thickness: 1,
                      color: scheme.outlineVariant,
                    ),
                  ),
                  _Btn(
                    key: const ValueKey('format-close'),
                    icon: Icons.keyboard_arrow_down,
                    tooltip: l10n.close,
                    onTap: widget.onClose,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}

/// Tepsi açan hap: yazı + ▾ (açıkken ▴ ve kenarlık). Odak istemez.
class _MenuChip extends StatelessWidget {
  const _MenuChip({
    super.key,
    required this.open,
    required this.tooltip,
    required this.onTap,
    required this.child,
    this.cycles = false,
  });

  final bool open;

  /// Basış tepsi açmaz, SIRADAKİ değere geçer: ▾ yerine ⇅ simgesi.
  final bool cycles;
  final String tooltip;
  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onTap != null;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        expanded: cycles ? null : open,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Material(
            color: open ? scheme.primaryContainer : scheme.surfaceContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: open ? scheme.primary : scheme.outlineVariant,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Container(
                height: 36,
                padding: const EdgeInsetsDirectional.only(start: 8, end: 2),
                child: DefaultTextStyle.merge(
                  style: TextStyle(
                    color: enabled
                        ? (open ? scheme.onPrimaryContainer : scheme.onSurface)
                        : scheme.onSurface.withValues(alpha: 0.5),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Center(child: child)),
                      if (enabled)
                        Icon(
                          cycles
                              ? Icons.unfold_more_rounded
                              : open
                              ? Icons.arrow_drop_up_rounded
                              : Icons.arrow_drop_down_rounded,
                          size: cycles ? 16 : 20,
                          color: scheme.onSurfaceVariant,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Renk hapının simgesi: "A" altında etkin yazı rengi, yanında vurgu
/// kalemi altında etkin vurgu — hangi rengin işlediği tek bakışta.
class _ColorGlyph extends StatelessWidget {
  const _ColorGlyph({required this.text, required this.highlight});

  final Color? text;
  final Color? highlight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget stripe(Color? color) => Container(
      width: 16,
      height: 3,
      margin: const EdgeInsets.only(top: 1),
      decoration: BoxDecoration(
        color: color ?? scheme.outlineVariant,
        borderRadius: BorderRadius.circular(2),
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.format_color_text, size: 17),
            stripe(text),
          ],
        ),
        const SizedBox(width: 6),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.border_color_outlined, size: 16),
            stripe(highlight),
          ],
        ),
      ],
    );
  }
}

/// Maddenin alt çizgisi: düz · kesikli · noktalı + ayar (bkz.
/// [FormatBar.dividerKind]).
class _DividerRow extends StatelessWidget {
  const _DividerRow({
    required this.kind,
    required this.onPick,
    required this.onStyle,
  });

  final String kind;
  final ValueChanged<String> onPick;
  final VoidCallback? onStyle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    Widget swatch(String value, String tooltip) {
      final selected = kind == value;
      return Expanded(
        child: Tooltip(
          message: tooltip,
          child: InkWell(
            key: ValueKey('format-divider-$value'),
            borderRadius: BorderRadius.circular(10),
            onTap: () => onPick(value),
            child: Ink(
              height: 32,
              decoration: BoxDecoration(
                color: selected ? scheme.secondaryContainer : null,
                borderRadius: BorderRadius.circular(10),
              ),
              child: CustomPaint(
                painter: _DividerSwatchPainter(
                  value,
                  selected
                      ? scheme.onSecondaryContainer
                      : scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 42,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            Text(
              l10n.itemMenuLine,
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(width: 8),
            swatch('solid', l10n.itemDividerSolid),
            swatch('dashed', l10n.itemDividerDashed),
            swatch('dotted', l10n.itemDividerDotted),
            if (onStyle != null)
              IconButton(
                key: const ValueKey('format-divider-style'),
                tooltip: l10n.dividerSettings,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.tune, size: 20),
                onPressed: onStyle,
              ),
          ],
        ),
      ),
    );
  }
}

/// Çizgi türü örneği: ortadan geçen ince çizgi.
class _DividerSwatchPainter extends CustomPainter {
  _DividerSwatchPainter(this.kind, this.color);

  final String kind;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final y = size.height / 2;
    const inset = 10.0;
    final (dash, gap) = switch (kind) {
      'dashed' => (6.0, 4.0),
      'dotted' => (0.5, 4.0),
      _ => (size.width, 0.0),
    };
    for (var x = inset; x < size.width - inset; x += dash + gap) {
      final end = math.min(x + dash, size.width - inset);
      canvas.drawLine(Offset(x, y), Offset(end, y), paint);
    }
  }

  @override
  bool shouldRepaint(_DividerSwatchPainter old) =>
      old.kind != kind || old.color != color;
}

/// Panelin bir sırası: sabit yükseklik, yan pay.
class _PanelRow extends StatelessWidget {
  const _PanelRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 46,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(children: children),
    ),
  );
}

class _Gap extends StatelessWidget {
  const _Gap();

  @override
  Widget build(BuildContext context) => const SizedBox(width: 6);
}

/// Sıra düğmesi: satıra EŞİT payla yayılır (Expanded), en fazla 52 dp.
/// [open]: tepsisi açık (kenarlık); [active]: biçim imleçte etkin (dolu
/// zemin).
class _Btn extends StatelessWidget {
  const _Btn({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.active = false,
    this.open = false,
    this.flex = 1,
  });

  final IconData icon;
  final String tooltip;

  /// null ise düğme SOLUK ve tıklanamaz (yapacak işi yok).
  final VoidCallback? onTap;
  final bool active;
  final bool open;

  /// Sıradaki pay (stil hapları ile aynı sırada daha büyük verilir).
  final int flex;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onTap != null;
    final fg = active
        ? scheme.onPrimaryContainer
        : enabled
        ? scheme.onSurface
        : scheme.onSurface.withValues(alpha: 0.35);
    return Expanded(
      flex: flex,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 52),
          child: Tooltip(
            message: tooltip,
            child: Semantics(
              button: true,
              selected: active || open,
              // Etkin/açık durum YUMUŞAK geçer (2026-10-28, "biçim menüsü
              // daha yumuşak"): zemin ve simge rengi ~200 ms'de karışır.
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: active ? 1 : (open ? 0.5 : 0)),
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                builder: (context, t, _) => InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: onTap,
                  child: Ink(
                    width: double.infinity,
                    height: 38,
                    decoration: BoxDecoration(
                      color: t <= 0
                          ? null
                          : open && !active
                          ? scheme.surfaceContainerHighest.withValues(
                              alpha: t * 2,
                            )
                          : scheme.primaryContainer.withValues(alpha: t),
                      borderRadius: BorderRadius.circular(12),
                      border: open
                          ? Border.all(color: scheme.primary, width: 1.5)
                          : null,
                    ),
                    child: Icon(icon, size: 22, color: fg),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Seçilebilir hap (paragraf stili, yazı tipi). Odak istemez.
class _Chip extends StatelessWidget {
  const _Chip({
    super.key,
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Seçim yumuşak geçer: zemin, kenar ve yazı rengi birlikte karışır.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: selected ? 1 : 0),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        builder: (context, t, child) => Material(
          color: Color.lerp(
            scheme.surfaceContainer,
            scheme.primaryContainer,
            t,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Color.lerp(scheme.outlineVariant, scheme.primary, t)!,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              alignment: Alignment.center,
              child: DefaultTextStyle.merge(
                style: TextStyle(
                  color: Color.lerp(
                    scheme.onSurface,
                    scheme.onPrimaryContainer,
                    t,
                  ),
                ),
                child: child!,
              ),
            ),
          ),
        ),
        child: child,
      ),
    );
  }
}

/// Renk sırasının hedef anahtarı: "A" (yazı rengi) ve vurgu kalemi. Her
/// birinin altındaki şerit o an etkin rengini gösterir.
class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({
    required this.mode,
    required this.textColor,
    required this.highlightColor,
    required this.onChanged,
  });

  final _ColorMode mode;
  final Color? textColor;
  final Color? highlightColor;
  final ValueChanged<_ColorMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    Widget segment(
      _ColorMode value,
      IconData icon,
      String tooltip,
      Color? stripe,
    ) {
      final selected = mode == value;
      return Tooltip(
        message: tooltip,
        child: InkWell(
          key: ValueKey('format-mode-${value.name}'),
          borderRadius: BorderRadius.circular(10),
          onTap: () => onChanged(value),
          child: Ink(
            width: 40,
            height: 36,
            decoration: BoxDecoration(
              color: selected ? scheme.primaryContainer : null,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 19,
                  color: selected
                      ? scheme.onPrimaryContainer
                      : scheme.onSurfaceVariant,
                ),
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  width: 18,
                  height: 3,
                  decoration: BoxDecoration(
                    color: stripe ?? scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          segment(
            _ColorMode.text,
            Icons.format_color_text,
            l10n.formatTextColor,
            textColor,
          ),
          segment(
            _ColorMode.highlight,
            Icons.border_color_outlined,
            l10n.formatHighlight,
            highlightColor,
          ),
        ],
      ),
    );
  }
}

/// Tepsinin kabı: aynı iç pay, panelden ince çizgiyle ayrık.
class _TrayBox extends StatelessWidget {
  const _TrayBox({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: child,
    );
  }
}

/// Renk sırası: [Kaldır] + hazır tonlar + tam palet, eşit bölünmüş — dar
/// ekranda da son düğme (tam palet) kenara taşmaz.
class _ColorRow extends StatelessWidget {
  const _ColorRow({
    super.key,
    required this.keyPrefix,
    required this.label,
    required this.activeIndex,
    required this.filled,
    required this.onPick,
    required this.onRemove,
  });

  final String keyPrefix;
  final String label;
  final int? activeIndex;
  final bool filled;
  final ValueChanged<int> onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final palette = NoteColors.richPalette;
    // Dairelerin ADI (F12.5): beşi de "Yazı rengi" diye okunuyordu.
    final names = richPaletteNames(l10n);
    final index = activeIndex;
    final custom = isCustomRichColor(index) ? Color(index!) : null;

    Widget slot(Widget child) => Expanded(child: Center(child: child));

    Widget circle({
      required Key key,
      required String tooltip,
      required VoidCallback onTap,
      Color? fill,
      Gradient? gradient,
      Color? border,
      double borderWidth = 2,
      Widget? child,
    }) => Tooltip(
      message: tooltip,
      child: InkWell(
        key: key,
        customBorder: const CircleBorder(),
        onTap: onTap,
        // Dokunma alanı 36 dp; görünen daire 28.
        child: SizedBox(
          width: 36,
          height: 36,
          child: Center(
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: fill,
                gradient: gradient,
                border: border == null
                    ? null
                    : Border.all(color: border, width: borderWidth),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );

    return Row(
      children: [
        for (var i = 0; i < palette.length; i++)
          slot(
            circle(
              key: ValueKey('$keyPrefix-${i + 1}'),
              tooltip: i < names.length ? '$label: ${names[i]}' : label,
              onTap: () => onPick(i + 1),
              fill: filled ? palette[i].withValues(alpha: 0.45) : palette[i],
              border: filled ? palette[i] : null,
              borderWidth: index == i + 1 ? 3.5 : 2,
              child: index == i + 1
                  ? Icon(
                      Icons.check,
                      size: 16,
                      color: filled ? palette[i] : Colors.white,
                    )
                  : null,
            ),
          ),
        // TAM PALET: hazır tonlar + özel renk (bkz. color_palette.dart).
        // Özel renk etkinse düğme o renkle dolu ve tikli.
        slot(
          circle(
            key: ValueKey('$keyPrefix-palette'),
            tooltip: l10n.paletteMore,
            onTap: () async {
              final picked = await showColorPaletteSheet(
                context,
                title: label,
                current: custom ?? _FormatBarState._resolve(index),
              );
              if (picked != null) onPick(picked.toARGB32() | 0xFF000000);
            },
            fill: custom,
            gradient: custom != null
                ? null
                : FixedColors.rainbowSweep,
            child: Icon(
              custom != null ? Icons.check : AppIcons.color,
              size: 15,
              color: custom != null ? FixedColors.inkOn(custom) : Colors.white,
            ),
          ),
        ),
        // KALDIR — hep aynı yerde (biçim yokken soluk): "renk verdim, nasıl
        // geri alırım" sorusunun cevabı her açılışta aynı yerde.
        slot(
          circle(
            key: ValueKey('$keyPrefix-remove'),
            tooltip: l10n.formatRemove,
            onTap: onRemove,
            border: scheme.outline,
            borderWidth: 1.5,
            child: Icon(
              Icons.format_color_reset,
              size: 15,
              color: index == null
                  ? scheme.onSurfaceVariant.withValues(alpha: 0.5)
                  : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

/// YAZI TİPİ tepsisi: yazı tipleri (her biri kendi yazı tipiyle yazılı,
/// yatay kayar) + boyut ve şeffaflık için ince ayar kaydırıcıları.
class _FontTray extends StatelessWidget {
  const _FontTray({
    required this.family,
    required this.onFont,
    required this.size,
    required this.opacity,
    required this.onSlide,
    required this.onSlideEnd,
  });

  final String? family;
  final ValueChanged<String?> onFont;
  final double size;
  final double opacity;
  final void Function(_Slide slide, double value) onSlide;
  final void Function(_Slide slide, double value) onSlideEnd;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final current = family ?? '';
    preloadRemainingNoteFonts();
    return _TrayBox(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: kNoteFonts.length,
              separatorBuilder: (_, _) => const SizedBox(width: 2),
              itemBuilder: (context, i) {
                final font = kNoteFonts[i];
                return _Chip(
                  key: ValueKey('format-font-${font.id ?? 'default'}'),
                  selected: (font.id ?? '') == current,
                  onTap: () => onFont(font.id),
                  child: Text(
                    noteFontLabel(
                      font.id,
                      defaultLabel: l10n.noteFontDefault,
                      serifLabel: l10n.noteFontSerif,
                      monoLabel: l10n.noteFontMono,
                    ),
                    style: applyNoteFont(
                      const TextStyle(fontSize: 14.5),
                      font.id,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          _SliderRow(
            key: const ValueKey('format-size-slider'),
            icon: Icons.format_size,
            label: l10n.noteTextSize,
            value: size,
            min: _kScaleMin,
            max: _kScaleMax,
            onChanged: (v) => onSlide(_Slide.size, v),
            onChangeEnd: (v) => onSlideEnd(_Slide.size, v),
          ),
          _SliderRow(
            key: const ValueKey('format-opacity-slider'),
            icon: Icons.opacity,
            label: l10n.noteTextOpacity,
            value: opacity,
            min: 0.3,
            max: 1.0,
            onChanged: (v) => onSlide(_Slide.opacity, v),
            onChangeEnd: (v) => onSlideEnd(_Slide.opacity, v),
          ),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final IconData icon;
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 38,
      child: Row(
        children: [
          Tooltip(
            message: label,
            child: SizedBox(
              width: 28,
              child: Icon(icon, size: 19, color: scheme.onSurfaceVariant),
            ),
          ),
          SizedBox(
            width: 78,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
          Expanded(
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
              onChangeEnd: onChangeEnd,
            ),
          ),
          SizedBox(
            width: 42,
            child: Text(
              '%${(value * 100).round()}',
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
        ],
      ),
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
