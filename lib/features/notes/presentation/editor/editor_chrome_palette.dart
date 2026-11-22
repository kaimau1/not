import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../app/theme/note_colors.dart';
import '../../../../app/theme/note_themes.dart';
import '../../../../core/utils/color_contrast.dart';
import '../../domain/archive_paper.dart';
import '../../domain/note.dart';
import 'notebook_paper.dart';

/// Zemin görselinin üst, alt, genel ve baskın renk tonu.
///
/// Görsel 24 px genişliğe küçültülüp BİR KEZ çözülür ve bellekte tutulur
/// (bkz. `ImageLuma`): üst çubuk, sayfa çubuğu ve alt kapsüller görselin
/// gerçek rengine ve parlaklığına uyum sağlar, düğmeler koyu/açık/karmaşık
/// fotoğraflarda kaybolmaz.
@immutable
class BgImageTone {
  const BgImageTone({
    required this.topColor,
    required this.bottomColor,
    required this.overallColor,
    required this.accentColor,
  });

  final Color topColor;
  final Color bottomColor;
  final Color overallColor;
  final Color accentColor;

  static final LinkedHashMap<String, BgImageTone> _cache =
      LinkedHashMap<String, BgImageTone>();
  static const int _maxCache = 32;

  static BgImageTone? cached(String key) => _cache[key];

  @visibleForTesting
  static void seedCache(String key, BgImageTone tone) => _put(key, tone);

  @visibleForTesting
  static void clearCache() => _cache.clear();

  static void _put(String key, BgImageTone tone) {
    _cache.remove(key);
    _cache[key] = tone;
    while (_cache.length > _maxCache) {
      _cache.remove(_cache.keys.first);
    }
  }

  /// [provider]'ı 24 px genişlikte çözüp [BgImageTone] çıkarır; hata olursa null.
  static Future<BgImageTone?> load(String key, ImageProvider provider) async {
    final hit = _cache[key];
    if (hit != null) return hit;
    try {
      final base = provider is ResizeImage ? provider.imageProvider : provider;
      final small = ResizeImage(base, width: 24);
      final stream = small.resolve(ImageConfiguration.empty);
      final completer = Completer<ui.Image?>();
      late final ImageStreamListener listener;
      listener = ImageStreamListener(
        (info, _) {
          if (!completer.isCompleted) completer.complete(info.image.clone());
          stream.removeListener(listener);
        },
        onError: (_, _) {
          if (!completer.isCompleted) completer.complete(null);
          stream.removeListener(listener);
        },
      );
      stream.addListener(listener);
      final image = await completer.future;
      if (image == null) return null;
      final data = await image.toByteData();
      final w = image.width;
      final h = image.height;
      image.dispose();
      if (data == null || w == 0 || h == 0) return null;

      final topEnd = math.max(1, (h * 0.18).ceil());
      final bottomStart = math.min(h - 1, (h * 0.78).floor());

      var tr = 0.0, tg = 0.0, tb = 0.0, tn = 0;
      var br = 0.0, bg = 0.0, bb = 0.0, bn = 0;
      var ar = 0.0, ag = 0.0, ab = 0.0, an = 0;
      var cr = 0.0, cg = 0.0, cb = 0.0, cw = 0.0;

      for (var y = 0; y < h; y++) {
        for (var x = 0; x < w; x++) {
          final off = (y * w + x) * 4;
          final r = data.getUint8(off) / 255.0;
          final g = data.getUint8(off + 1) / 255.0;
          final b = data.getUint8(off + 2) / 255.0;
          ar += r;
          ag += g;
          ab += b;
          an++;
          if (y < topEnd) {
            tr += r;
            tg += g;
            tb += b;
            tn++;
          }
          if (y >= bottomStart) {
            br += r;
            bg += g;
            bb += b;
            bn++;
          }
          final maxC = math.max(r, math.max(g, b));
          final minC = math.min(r, math.min(g, b));
          final sat = maxC - minC;
          if (sat > 0.08) {
            final weight = sat * sat;
            cr += r * weight;
            cg += g * weight;
            cb += b * weight;
            cw += weight;
          }
        }
      }

      Color avg(double r, double g, double b, int n) => n == 0
          ? const Color(0xFF808080)
          : Color.from(
              alpha: 1,
              red: (r / n).clamp(0.0, 1.0),
              green: (g / n).clamp(0.0, 1.0),
              blue: (b / n).clamp(0.0, 1.0),
            );

      final overall = avg(ar, ag, ab, an);
      final accent = cw > 0.001
          ? Color.from(
              alpha: 1,
              red: (cr / cw).clamp(0.0, 1.0),
              green: (cg / cw).clamp(0.0, 1.0),
              blue: (cb / cw).clamp(0.0, 1.0),
            )
          : overall;
      final tone = BgImageTone(
        topColor: avg(tr, tg, tb, tn),
        bottomColor: avg(br, bg, bb, bn),
        overallColor: overall,
        accentColor: accent,
      );
      _put(key, tone);
      return tone;
    } catch (_) {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is BgImageTone &&
      other.topColor == topColor &&
      other.bottomColor == bottomColor &&
      other.overallColor == overallColor &&
      other.accentColor == accentColor;

  @override
  int get hashCode =>
      Object.hash(topColor, bottomColor, overallColor, accentColor);
}

/// Editör üst alanı, sayfa çubuğu, alt çubuk kapsülleri ve kâğıt çizgilerinin
/// tek kaynaktan hesaplanan uyumlu renk paleti.
///
/// Kural: defter görünümünde ([Note.paged]), çizilmiş temalarda ([Note.theme]),
/// renkli notlarda ve arka plan görsellerinde üst alan + sayfa çubuğu + alt
/// panel sayfayla tam görsel uyum taşır; her düğme ve etiket WCAG AA (≥ 4,5:1)
/// okunurluk sınırında kalır.
@immutable
class EditorChromePalette {
  const EditorChromePalette({
    required this.baseBackground,
    required this.pageSurface,
    required this.statusBarGround,
    required this.inkTheme,
    required this.effectiveTheme,
    required this.noteAccent,
    required this.barInk,
    required this.barPage,
    required this.chromeSeeThrough,
    required this.topBarPills,
    required this.topBarIconColor,
    required this.topPillFill,
    required this.topPillBorder,
    required this.topPillInk,
    required this.pageBarFill,
    required this.pageBarBorder,
    required this.pageBarAccent,
    required this.pageBarIcon,
    required this.pageBarPillFill,
    required this.toolCapsuleFill,
    required this.toolCapsuleBorder,
    required this.aiCapsuleFill,
    required this.aiCapsuleBorder,
    required this.aiIconColor,
    required this.dividerColor,
    required this.paperTheme,
    required this.paperAccent,
  });

  /// `ColorFade` arka plan rengi (`legalTint` hariç — sarı bloknot tonu tam
  /// ekran [NotebookPaper] tarafından TEK KEZ çizilir).
  final Color baseBackground;

  /// Sayfanın görsel zemin rengi (`legalTint` bir kez bindirilmiş).
  final Color pageSurface;

  /// Durum çubuğu simge parlaklığı hesabı için üst bant rengi.
  final Color statusBarGround;

  /// Dış temanın yazısı zeminde okunmuyorsa zıt tema; yoksa null.
  final ThemeData? inkTheme;

  /// Editörün içi için geçerli tema (`inkTheme ?? outerTheme`).
  final ThemeData effectiveTheme;

  /// `NoteAccent` vurgusu (kartla aynı kural).
  final Color? noteAccent;

  /// Alt çubuk düğme/kapsül mürekkebi; sade notta null.
  final Color? barInk;

  /// Alt çubuğun etkin zemin rengi (ör. etkin ses düğmesinin simgesi).
  final Color barPage;

  /// Alt çubuk şeffaf mı (defter kâğıdı, çizilmiş tema ya da zemin görseli)?
  final bool chromeSeeThrough;

  /// Üst çubuk düğmeleri zemin görselinde kaybolmasın diye yumuşak kapsülde mi?
  final bool topBarPills;
  final Color topBarIconColor;
  final Color topPillFill;
  final Color topPillBorder;
  final Color topPillInk;

  final Color pageBarFill;
  final Color pageBarBorder;
  final Color pageBarAccent;
  final Color pageBarIcon;
  final Color pageBarPillFill;

  final Color toolCapsuleFill;
  final Color toolCapsuleBorder;
  final Color aiCapsuleFill;
  final Color? aiCapsuleBorder;
  final Color aiIconColor;

  /// Gövde ile alt panel arasındaki ince çizgi; çizgili defterde null (alt
  /// bandın ilk kâğıt çizgisi zaten oradadır).
  final Color? dividerColor;

  /// Defter çizgilerinin parlaklık teması ve vurgu rengi.
  final ThemeData paperTheme;
  final Color? paperAccent;

  /// Orta tonlu fotoğraf zeminini okunur kapsül yüzeyine nazikçe çeker (tonu
  /// koruyarak yazı/simge kontrastını garanti altına alır).
  static Color _readableSurface(Color ground, ThemeData theme) {
    final card = AppTokens.fromTheme(theme).card;
    final ink = theme.colorScheme.onSurface;
    if (contrastRatio(ink, ground) >= 6.5) return ground;
    for (var t = 0.25; t <= 0.85; t += 0.15) {
      final candidate = Color.lerp(ground, card, t)!;
      if (contrastRatio(ink, candidate) >= 6.5) return candidate;
    }
    return Color.lerp(ground, card, 0.85)!;
  }

  /// Yarı saydam kapsülün arkasında fotoğrafın en zor pikseli (koyu kapsülde
  /// saf beyaz, açık kapsülde saf siyah) varken bile [ink]'in ≥ [min] kontrast
  /// taşımasını garanti eder.
  static Color _readableOnTranslucent(
    Color ink,
    Color translucentFill, {
    required Color backing,
    required bool worstPhoto,
    double min = NoteColors.minTextContrast,
  }) {
    if (!worstPhoto) {
      return readableOn(
        ink,
        Color.alphaBlend(translucentFill, backing),
        min: min,
      );
    }
    final dark =
        ThemeData.estimateBrightnessForColor(
          Color.alphaBlend(translucentFill, const Color(0xFF808080)),
        ) ==
        Brightness.dark;
    final worst = dark ? Colors.white : Colors.black;
    final surface = Color.alphaBlend(translucentFill, worst);
    return readableOn(ink, surface, min: min);
  }

  /// [note] ve dış tema için tüm editör kromu renklerini tek seferde çözer.
  factory EditorChromePalette.resolve({
    required ThemeData outerTheme,
    required Note note,
    required bool hasBgImage,
    BgImageTone? bgTone,
  }) {
    final darkOuter = outerTheme.brightness == Brightness.dark;
    final baseBackground = NoteColors.noteSurfaceIn(outerTheme, note);
    final pageSurface = NoteColors.effectiveSurfaceIn(outerTheme, note);
    final noteTheme = NoteThemes.byId(note.theme);
    final themed = noteTheme != null;
    final legal = note.paged && note.archivePaper == ArchivePaper.legal;
    final bgOpacity = note.backgroundOpacity.clamp(0.05, 1.0);

    final themeTop = themed ? noteTheme.palette(darkOuter).top : baseBackground;
    final pageTop = legal
        ? Color.alphaBlend(NoteColors.legalTint, themeTop)
        : themeTop;

    final topGround = hasBgImage && bgTone != null
        ? Color.alphaBlend(
            bgTone.topColor.withValues(alpha: bgOpacity),
            pageTop,
          )
        : pageTop;
    final bottomGround = hasBgImage && bgTone != null
        ? Color.alphaBlend(
            bgTone.bottomColor.withValues(alpha: bgOpacity),
            pageSurface,
          )
        : pageSurface;
    final overallGround = hasBgImage && bgTone != null
        ? Color.alphaBlend(
            bgTone.overallColor.withValues(alpha: bgOpacity),
            pageSurface,
          )
        : pageSurface;

    final inkTheme = NoteColors.inkThemeFor(outerTheme, overallGround);
    final effectiveTheme = inkTheme ?? outerTheme;
    final scheme = effectiveTheme.colorScheme;
    final noteAccent = NoteColors.noteInkIn(outerTheme, note);
    final seeThrough = note.paged || themed || hasBgImage;

    // ── Düz (defter dışı, temasız, görselsiz) not: var olan kurallar birebir.
    if (!seeThrough) {
      final pageBarSurface = Color.alphaBlend(
        (noteAccent ?? scheme.onSurface).withValues(alpha: AppAlpha.hairline),
        pageSurface,
      );
      final pageBarFill = pageBarSurface.withValues(alpha: AppAlpha.strong);
      final pageBarComp = Color.alphaBlend(pageBarFill, pageSurface);
      var pageBarAccent = noteAccent ?? scheme.primary;
      pageBarAccent = readableOn(
        pageBarAccent,
        Color.alphaBlend(
          pageBarAccent.withValues(alpha: AppAlpha.pressed),
          pageBarComp,
        ),
      );
      final topIcon = noteAccent != null
          ? Color.lerp(scheme.onSurface, noteAccent, 0.45)!
          : scheme.onSurface;
      return EditorChromePalette(
        baseBackground: baseBackground,
        pageSurface: pageSurface,
        statusBarGround: topGround,
        inkTheme: inkTheme,
        effectiveTheme: effectiveTheme,
        noteAccent: noteAccent,
        barInk: noteAccent,
        barPage: pageSurface,
        chromeSeeThrough: false,
        topBarPills: false,
        topBarIconColor: topIcon,
        topPillFill: Colors.transparent,
        topPillBorder: Colors.transparent,
        topPillInk: topIcon,
        pageBarFill: pageBarFill,
        pageBarBorder: pageBarAccent.withValues(alpha: AppAlpha.soft),
        pageBarAccent: pageBarAccent,
        pageBarIcon: noteAccent ?? scheme.onSurface,
        pageBarPillFill: pageBarAccent.withValues(alpha: AppAlpha.pressed),
        toolCapsuleFill: noteAccent == null
            ? scheme.surface
            : Color.alphaBlend(
                noteAccent.withValues(alpha: AppAlpha.hairline),
                pageSurface,
              ),
        toolCapsuleBorder:
            noteAccent?.withValues(alpha: AppAlpha.pressed) ??
            scheme.outlineVariant,
        aiCapsuleFill: noteAccent == null
            ? scheme.primaryContainer
            : Color.alphaBlend(
                noteAccent.withValues(alpha: AppAlpha.pressed),
                pageSurface,
              ),
        aiCapsuleBorder: null,
        aiIconColor: noteAccent ?? scheme.onPrimaryContainer,
        dividerColor:
            noteAccent?.withValues(alpha: AppAlpha.soft) ??
            scheme.outlineVariant.withValues(alpha: AppAlpha.muted),
        paperTheme: effectiveTheme,
        paperAccent: noteAccent,
      );
    }

    // ── Defter, çizilmiş tema ya da zemin görseli: sayfayla tam uyum.
    final bottomTheme = hasBgImage
        ? (NoteColors.inkThemeFor(outerTheme, bottomGround) ?? effectiveTheme)
        : effectiveTheme;
    final bottomScheme = bottomTheme.colorScheme;
    final chromeBase = _readableSurface(
      hasBgImage ? bottomGround : pageSurface,
      bottomTheme,
    );

    // Zemin görselinde baskın renk canlıysa vurgu ondan türetilir; yoksa notun
    // kendi rengi/teması ya da uygulama temasının ana rengi.
    final photoSeed = hasBgImage && bgTone != null
        ? (HSLColor.fromColor(bgTone.accentColor).saturation > 0.12
              ? bgTone.accentColor
              : bottomScheme.primary)
        : null;
    final hasCustomTint = noteAccent != null || photoSeed != null;
    final seedInk = noteAccent ?? photoSeed ?? bottomScheme.primary;

    final toolOpaque = Color.alphaBlend(
      (hasCustomTint ? seedInk : bottomScheme.onSurface).withValues(
        alpha: AppAlpha.hairline,
      ),
      chromeBase,
    );
    final aiOpaque = Color.alphaBlend(
      seedInk.withValues(alpha: AppAlpha.pressed),
      chromeBase,
    );
    final toolFill = toolOpaque.withValues(alpha: AppAlpha.strong);
    final aiFill = aiOpaque.withValues(alpha: AppAlpha.strong);

    // En zor yüzeyler (iç içe sayfa hapı: toolFill + %12 vurgu; AI kapsülü;
    // fotoğrafta en kötü siyah/beyaz piksel) üzerinde ≥ 4,5:1 garantisi.
    final toolWorst = hasBgImage
        ? Color.alphaBlend(
            toolFill,
            ThemeData.estimateBrightnessForColor(toolOpaque) == Brightness.dark
                ? Colors.white
                : Colors.black,
          )
        : Color.alphaBlend(toolFill, pageSurface);
    final aiWorst = hasBgImage
        ? Color.alphaBlend(
            aiFill,
            ThemeData.estimateBrightnessForColor(aiOpaque) == Brightness.dark
                ? Colors.white
                : Colors.black,
          )
        : Color.alphaBlend(aiFill, pageSurface);

    // İki adımlı sabitleme: vurgu önce AI kapsülünde, sonra kendi %12 hap
    // dolgusuyla birleşmiş sayfa çubuğunda ≥ 4,5:1'e oturur.
    var resolvedAccent = readableOn(seedInk, aiWorst);
    for (var pass = 0; pass < 2; pass++) {
      final pillSurface = Color.alphaBlend(
        resolvedAccent.withValues(alpha: AppAlpha.pressed),
        toolWorst,
      );
      resolvedAccent = readableOn(resolvedAccent, pillSurface);
    }
    resolvedAccent = readableOn(resolvedAccent, toolWorst);
    resolvedAccent = readableOn(resolvedAccent, aiWorst);

    final barInk = hasCustomTint ? resolvedAccent : null;
    final pageBarIcon = hasCustomTint
        ? resolvedAccent
        : _readableOnTranslucent(
            bottomScheme.onSurface,
            toolFill,
            backing: pageSurface,
            worstPhoto: hasBgImage,
          );
    final aiIcon = hasCustomTint
        ? resolvedAccent
        : _readableOnTranslucent(
            bottomScheme.onPrimaryContainer,
            aiFill,
            backing: pageSurface,
            worstPhoto: hasBgImage,
          );

    // Üst alan (AppBar): zemin görselinde üst şeridin kendi tonunda yarı
    // saydam haplar; görselsizde doğrudan sayfanın/çizgilerin üstünde net
    // uyumlu mürekkep.
    final topTheme = hasBgImage
        ? (NoteColors.inkThemeFor(outerTheme, topGround) ?? effectiveTheme)
        : effectiveTheme;
    final topScheme = topTheme.colorScheme;
    final topBase = hasBgImage
        ? _readableSurface(topGround, topTheme)
        : topGround;
    final topPillFill = hasBgImage
        ? topBase.withValues(alpha: AppAlpha.strong)
        : Colors.transparent;
    final topAccent = noteAccent != null
        ? _readableOnTranslucent(
            noteAccent,
            hasBgImage ? topPillFill : pageTop,
            backing: pageTop,
            worstPhoto: hasBgImage,
          )
        : null;
    final topInkSeed = hasBgImage
        ? (topAccent != null
              ? Color.lerp(topScheme.onSurface, topAccent, 0.35)!
              : topScheme.onSurface)
        : (barInk != null
              ? Color.lerp(scheme.onSurface, barInk, 0.45)!
              : scheme.onSurface);
    final topIconColor = hasBgImage
        ? _readableOnTranslucent(
            topInkSeed,
            topPillFill,
            backing: pageTop,
            worstPhoto: true,
          )
        : readableOn(topInkSeed, pageTop);

    final vividPhotoSeed =
        hasBgImage &&
            bgTone != null &&
            HSLColor.fromColor(bgTone.accentColor).saturation > 0.12
        ? bgTone.accentColor
        : null;
    final effectiveNoteAccent =
        noteAccent ??
        (vividPhotoSeed != null
            ? readableOn(vividPhotoSeed, overallGround)
            : null);
    final paperAccent = effectiveNoteAccent != null
        ? readableOn(effectiveNoteAccent, overallGround)
        : null;
    final ruledBand =
        note.paged && note.archivePaper.ruled && !note.type.isPageNoteType;
    final Color? dividerColor = ruledBand
        ? null
        : (note.paged
              ? PaperInks.of(effectiveTheme, accent: paperAccent).line
              : (barInk?.withValues(alpha: AppAlpha.soft) ??
                    bottomScheme.outlineVariant.withValues(
                      alpha: AppAlpha.muted,
                    )));

    return EditorChromePalette(
      baseBackground: baseBackground,
      pageSurface: pageSurface,
      statusBarGround: topGround,
      inkTheme: inkTheme,
      effectiveTheme: effectiveTheme,
      noteAccent: effectiveNoteAccent,
      barInk: barInk,
      barPage: chromeBase,
      chromeSeeThrough: true,
      topBarPills: hasBgImage,
      topBarIconColor: topIconColor,
      topPillFill: topPillFill,
      topPillBorder: hasBgImage
          ? topIconColor.withValues(alpha: AppAlpha.soft)
          : Colors.transparent,
      topPillInk: topIconColor,
      pageBarFill: toolFill,
      pageBarBorder: resolvedAccent.withValues(alpha: AppAlpha.soft),
      pageBarAccent: resolvedAccent,
      pageBarIcon: pageBarIcon,
      pageBarPillFill: resolvedAccent.withValues(alpha: AppAlpha.pressed),
      toolCapsuleFill: toolFill,
      toolCapsuleBorder: hasCustomTint
          ? resolvedAccent.withValues(alpha: AppAlpha.soft)
          : bottomScheme.outlineVariant.withValues(alpha: AppAlpha.strong),
      aiCapsuleFill: aiFill,
      aiCapsuleBorder: resolvedAccent.withValues(alpha: AppAlpha.soft),
      aiIconColor: aiIcon,
      dividerColor: dividerColor,
      paperTheme: effectiveTheme,
      paperAccent: paperAccent,
    );
  }
}

/// Zemin görseli açıkken üst çubuktaki düğme/başlıkların görselde kaybolmasını
/// önleyen hafif kapsül: yalnız BOYAMA katmanında 40 dp yüksekliğinde yuvarlak
/// arka plan çizer; çocuğun 48 dp dokunma alanı ve yerleşimi değişmez.
class EditorTopPill extends StatelessWidget {
  const EditorTopPill({
    super.key,
    required this.fill,
    required this.border,
    required this.child,
    this.circle = false,
  });

  final Color fill;
  final Color border;
  final Widget child;
  final bool circle;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _TopPillPainter(fill: fill, border: border, circle: circle),
    child: child,
  );
}

class _TopPillPainter extends CustomPainter {
  const _TopPillPainter({
    required this.fill,
    required this.border,
    required this.circle,
  });

  final Color fill;
  final Color border;
  final bool circle;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final fillPaint = Paint()..color = fill;
    final strokePaint = Paint()
      ..color = border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    if (circle) {
      final diameter = math.min(size.width, size.height) - AppSpace.s;
      if (diameter <= 0) return;
      final center = size.center(Offset.zero);
      final radius = diameter / 2;
      canvas
        ..drawCircle(center, radius, fillPaint)
        ..drawCircle(center, radius, strokePaint);
      return;
    }
    final insetY = size.height > AppSpace.xxxl ? AppSpace.xs : AppSpace.xxs;
    final rect = Rect.fromLTRB(
      AppSpace.xxs,
      insetY,
      size.width - AppSpace.xxs,
      size.height - insetY,
    );
    if (rect.width <= 0 || rect.height <= 0) return;
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(rect.height / 2),
    );
    canvas
      ..drawRRect(rrect, fillPaint)
      ..drawRRect(rrect, strokePaint);
  }

  @override
  bool shouldRepaint(_TopPillPainter old) =>
      old.fill != fill || old.border != border || old.circle != circle;
}
