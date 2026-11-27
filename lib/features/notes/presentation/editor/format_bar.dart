import '../../../../core/widgets/back_closes.dart';
import '../../../../app/theme/fixed_colors.dart';
import '../../../../core/app_icons.dart';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/note_colors.dart';
import '../../../../core/a11y/color_names.dart';
import '../../../../core/l10n_ext.dart';
import '../../../../core/tips.dart';
import '../../../../core/utils/font_downloads.dart';
import '../../../../core/utils/note_fonts.dart';
import '../../../../core/utils/rich_text.dart';
import '../../../../core/utils/sentence_select.dart';
import '../../../../core/widgets/color_palette.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../domain/note_item.dart';
import '../divider_kind_picker.dart';
import 'format_menu.dart';
import 'text_wrap.dart';

part 'format_bar_widgets.dart';

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
    this.dividerStyle,
    this.onDivider,
    this.onDividerStyle,
  });

  /// **ALT ÇİZGİ** (kullanıcı isteği 2026-10-30: "alta çizgi ekle'yi biçim
  /// menüsüne taşıyalım"): hedef bir MADDEYSE onun ayırıcı türü ('' = yok);
  /// null ise sıra çizilmez (gövde/başlık). Aynı türe basmak kaldırır.
  final String? dividerKind;

  /// Hedef maddenin TAM çizgi biçimi (renk + kalınlık; P63 PB6): tepsideki
  /// örnekler onu taşır. null = çizgi yok ya da bilinmiyor.
  final ItemDivider? dividerStyle;
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
/// (imleç kipi, zaten seçili metin, boş kapsam).
///
/// Hem satır sarma çapalarını (`\uFFFC`/`\u2060`) hem de rich işaretlerini
/// (`**`, `_`, `~`, `%%k:`, `##k:` vb.) aşarak DÜZ metin uzayında çalışır.
TextSelection? scopeSelection(
  String text,
  TextSelection selection,
  FormatScope scope,
) {
  if (scope == FormatScope.caret || !selection.isValid) return null;
  if (!selection.isCollapsed || text.isEmpty) return null;
  final kind = switch (scope) {
    FormatScope.caret => null,
    FormatScope.word => RichScopeKind.word,
    FormatScope.line => RichScopeKind.line,
    FormatScope.all => RichScopeKind.all,
  };
  if (kind == null) return null;
  final logical = stripWrapAnchors(text);
  final logicalCaret = wrapToLogicalOffset(
    text,
    selection.baseOffset.clamp(0, text.length),
  );
  final range = richScopeRange(logical, logicalCaret, kind);
  if (range == null) return null;
  final start = kind == RichScopeKind.all
      ? 0
      : wrapToDisplayOffset(text, range.start).clamp(0, text.length);
  final end = kind == RichScopeKind.all
      ? text.length
      : wrapToDisplayOffset(text, range.end).clamp(start, text.length);
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      TipOnce.showDeferred(
        context,
        TipOnce.formatScope,
        () => context.l10n.tipFormatScope,
        icon: Icons.text_format_rounded,
      );
    });
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
      _scopePlainCaret = null;
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
      color: Theme.of(context).colorScheme.primary.withValues(alpha: AppAlpha.soft),
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
  /// sürer), [_scopePlainCaret] dönülecek düz metin imleci.
  TextSelection? _scopedSelection;
  int? _scopePlainCaret;

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
      _scopePlainCaret = null;
    }
    final selection = controller.selection;
    if (!selection.isValid || !selection.isCollapsed) return null;
    final next = scopeSelection(controller.text, selection, _scope);
    if (next == null) return null;
    final logicalCaret = wrapToLogicalOffset(
      controller.text,
      selection.baseOffset.clamp(0, controller.text.length),
    );
    _scopePlainCaret = logicalToPlainOffset(
      controller.logicalText,
      logicalCaret,
    );
    _scopedSelection = next;
    // Geçici seçim çift dokunuş sanılıp cümleye büyütülmesin (bkz.
    // [withoutSentenceExpansion]).
    withoutSentenceExpansion(() => controller.selection = next);
    return next;
  }

  void _applyScope() => _applyScopeTracked();

  /// İş bitti: geçici seçim imlece döner. Biçim işaretleri ya da sarma çapaları
  /// metin uzunluğunu değiştirse bile imleç DÜZ metindeki aynı karakterde kalır.
  void _releaseScope(TextSelection? before) {
    final controller = widget.target?.controller;
    final plainCaret = _scopePlainCaret;
    _scopedSelection = null;
    _scopePlainCaret = null;
    if (controller == null || before == null || plainCaret == null) return;
    final logicalPos = plainToLogicalOffset(
      controller.logicalText,
      plainCaret,
      preferEnd: plainCaret > 0,
    );
    final displayOffset = wrapToDisplayOffset(controller.text, logicalPos);
    withoutSentenceExpansion(() {
      controller.selection = TextSelection.collapsed(
        offset: displayOffset.clamp(0, controller.text.length),
      );
    });
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

  double _value(_Slide slide) {
    final dragged = _drag[slide];
    if (dragged != null) return dragged;
    if (slide == _Slide.size) {
      final inlineSize = _active.size;
      if (inlineSize != null &&
          (widget.hasSelection() || _scope != FormatScope.caret)) {
        return kRichSizeSteps[(inlineSize - 1).clamp(
          0,
          kRichSizeSteps.length - 1,
        )];
      }
      return widget.fontScale;
    }
    final inlineOpacity = _active.opacity;
    if (inlineOpacity != null &&
        (widget.hasSelection() || _scope != FormatScope.caret)) {
      return kRichOpacitySteps[(inlineOpacity - 1).clamp(
        0,
        kRichOpacitySteps.length - 1,
      )];
    }
    return widget.textOpacity;
  }

  void _resetScale() {
    final scoped = _applyScopeTracked();
    setState(() => _drag.remove(_Slide.size));
    widget.onScaleEnd(1.0);
    _releaseScope(scoped);
  }

  void _handleClearFormat() {
    _scoped(() {
      final controller = widget.target?.controller;
      if (controller != null &&
          controller.hasPendingFormat &&
          !widget.hasSelection()) {
        controller.clearPendingFormat();
      }
      widget.onClearFormat();
    });
    if (_drag.isNotEmpty) {
      setState(_drag.clear);
    }
  }

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
        style: widget.dividerStyle,
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = AppTokens.fromTheme(theme);
    final text = AppText.of(theme);
    final l10n = context.l10n;
    final size = _value(_Slide.size);
    final hairline = Divider(height: 1, color: tokens.hairline);
    return BackCloses(
      open: _tray != _Tray.none,
      onClose: () => setState(() => _tray = _Tray.none),
      child: TextFieldTapRegion(
        child: Focus(
          canRequestFocus: false,
          descendantsAreFocusable: false,
          child: Material(
            color: scheme.surfaceContainerLow,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                hairline,
                // TEPSİ panelin ÜSTÜNDE: boy TEK ADIMDA değişir (S44: eski
                // AnimatedSize gövdeyi 14 kare yeniden diziyordu).
                if (_tray != _Tray.none) ...[_trayContent(context), hairline],
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.s,
                    vertical: AppSpace.xs,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1. SIRA — STİL ⇅ · [B I U] · RENK ▾
                      SizedBox(
                        height: 44,
                        child: Row(
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
                                    style: text.label.copyWith(
                                      fontWeight: _heading == RichHeading.normal
                                          ? AppWeight.medium
                                          : AppWeight.strong,
                                    ),
                                  ),
                                ),
                              ),
                              const _Gap(),
                            ],
                            // B · I · U tek yumuşak kapsülde
                            Expanded(
                              flex: 9,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: scheme.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.m,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpace.xxs),
                                  child: Row(
                                    children: [
                                      _Btn(
                                        key: const ValueKey('format-bold'),
                                        icon: Icons.format_bold,
                                        tooltip: l10n.formatBold,
                                        active: _active.bold,
                                        onTap: () => _scoped(
                                          () =>
                                              widget.onFormat(RichFormat.bold),
                                        ),
                                      ),
                                      _Btn(
                                        key: const ValueKey('format-italic'),
                                        icon: Icons.format_italic,
                                        tooltip: l10n.formatItalic,
                                        active: _active.italic,
                                        onTap: () => _scoped(
                                          () => widget.onFormat(
                                            RichFormat.italic,
                                          ),
                                        ),
                                      ),
                                      _Btn(
                                        key: const ValueKey('format-underline'),
                                        icon: Icons.format_underlined,
                                        tooltip: l10n.formatUnderline,
                                        active: _active.underline,
                                        onTap: () => _scoped(
                                          () => widget.onFormat(
                                            RichFormat.underline,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const _Gap(),
                            Expanded(
                              flex: 5,
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
                      ),
                      const SizedBox(height: AppSpace.xs),
                      // 2. SIRA — KAPSAM ⇅ · Aa · [A− %100 A+] · temizle ·
                      // (çizgi) · kapat
                      LayoutBuilder(
                        builder: (context, box) {
                        // Geniş ekranda (web/tablet) kapsam seçici satırı
                        // doldurmasın (kullanıcı 2026-11-24): sabit en,
                        // artan boşluk kapat düğmesinden önce.
                        final wide = box.maxWidth > 560;
                        Widget scopeSlot(Widget chip) => wide
                            ? SizedBox(width: 140, child: chip)
                            : Expanded(flex: 3, child: chip);
                        return SizedBox(
                        height: 44,
                        child: Row(
                          children: [
                            scopeSlot(
                              _MenuChip(
                                key: const ValueKey('format-scope-menu'),
                                open: false,
                                cycles: true,
                                tooltip: l10n.formatScopeHint,
                                onTap: _cycleScope,
                                child: Text(
                                  _scopeLabel(l10n),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: text.meta.copyWith(
                                    color: scheme.onSurface,
                                    fontWeight: AppWeight.medium,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpace.xs),
                            _IconBtn(
                              key: const ValueKey('format-font'),
                              icon: Icons.text_fields,
                              tooltip: l10n.formatFontPanel,
                              open: _tray == _Tray.font,
                              onTap: () => _toggleTray(_Tray.font),
                            ),
                            const SizedBox(width: AppSpace.xs),
                            // Birleşik boyut kapsülü: A− · %100 · A+
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.m,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpace.xxs),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _IconBtn(
                                      key: const ValueKey('format-size-down'),
                                      icon: Icons.text_decrease,
                                      tooltip: l10n.formatSizeDown,
                                      compact: true,
                                      onTap: size <= _kScaleMin + 0.001
                                          ? null
                                          : () => _stepScale(-1),
                                    ),
                                    Semantics(
                                      label: l10n.formatSizeValue(
                                        (size * 100).round(),
                                      ),
                                      excludeSemantics: true,
                                      child: InkWell(
                                        key: const ValueKey(
                                          'format-size-reset',
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.s,
                                        ),
                                        onTap:
                                            (size - 1.0).abs() < 0.001 &&
                                                _active.size == null
                                            ? null
                                            : _resetScale,
                                        child: SizedBox(
                                          width: 42,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                l10n.formatSizeLabel,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: text.badge.copyWith(
                                                  color:
                                                      scheme.onSurfaceVariant,
                                                  fontWeight: AppWeight.medium,
                                                  height: 1.0,
                                                ),
                                              ),
                                              Text(
                                                '%${(size * 100).round()}',
                                                key: const ValueKey(
                                                  'format-size-value',
                                                ),
                                                textAlign: TextAlign.center,
                                                maxLines: 1,
                                                style: text.badge.copyWith(
                                                  color: scheme.onSurface,
                                                  height: 1.1,
                                                  fontFeatures: const [
                                                    FontFeature.tabularFigures(),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    _IconBtn(
                                      key: const ValueKey('format-size-up'),
                                      icon: Icons.text_increase,
                                      tooltip: l10n.formatSizeUp,
                                      compact: true,
                                      onTap: size >= _kScaleMax - 0.001
                                          ? null
                                          : () => _stepScale(1),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpace.xs),
                            // Biçimi temizle: biçimsiz metinde soluk ve kapalı.
                            _IconBtn(
                              key: const ValueKey('format-clear'),
                              icon: Icons.format_clear,
                              tooltip: l10n.formatClear,
                              onTap:
                                  _active.isEmpty &&
                                      _scope == FormatScope.caret &&
                                      !widget.hasSelection() &&
                                      !(widget
                                              .target
                                              ?.controller
                                              .hasPendingFormat ??
                                          false)
                                  ? null
                                  : _handleClearFormat,
                            ),
                            // Maddenin ALT ÇİZGİSİ (yalnız madde hedefinde).
                            if (widget.dividerKind != null)
                              _IconBtn(
                                key: const ValueKey('format-divider-menu'),
                                icon: Icons.horizontal_rule,
                                tooltip: l10n.itemMenuLine,
                                active: widget.dividerKind!.isNotEmpty,
                                open: _tray == _Tray.divider,
                                onTap: () => _toggleTray(_Tray.divider),
                              ),
                            if (wide) const Spacer(),
                            SizedBox(
                              height: AppSpace.xxl,
                              child: VerticalDivider(
                                width: AppSpace.s,
                                thickness: 1,
                                color: tokens.hairline,
                              ),
                            ),
                            _IconBtn(
                              key: const ValueKey('format-close'),
                              icon: Icons.keyboard_arrow_down_rounded,
                              tooltip: l10n.close,
                              onTap: widget.onClose,
                            ),
                          ],
                        ),
                      );
                        },
                      ),
                      // 3. SIRA — HİZA (yalnız hizalanabilen hedefte: tablo
                      // hücresi, kullanıcı isteği 2026-11-23).
                      if (widget.target?.align case final align?) ...[
                        const SizedBox(height: AppSpace.xs),
                        SizedBox(
                          height: 44,
                          child: ValueListenableBuilder<TextAlign>(
                            valueListenable: align,
                            builder: (context, value, _) => DecoratedBox(
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.m,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpace.xxs),
                                child: Row(
                                  children: [
                                    for (final (a, icon, tip) in [
                                      (
                                        TextAlign.start,
                                        Icons.format_align_left_rounded,
                                        l10n.itemAlignStart,
                                      ),
                                      (
                                        TextAlign.center,
                                        Icons.format_align_center_rounded,
                                        l10n.itemAlignCenter,
                                      ),
                                      (
                                        TextAlign.end,
                                        Icons.format_align_right_rounded,
                                        l10n.itemAlignEnd,
                                      ),
                                    ])
                                      _Btn(
                                        key: ValueKey('format-align-${a.name}'),
                                        icon: icon,
                                        tooltip: tip,
                                        active: value == a,
                                        onTap: () => align.value = a,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

