import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n_ext.dart';
import '../personalize.dart';
import '../tips.dart';
import '../../app/theme/app_tokens.dart';
import '../haptics.dart';

/// Kişiselleştirilebilir bir alan/düğme (bkz. `Personalize`).
///
/// Normalde: öğe görünürse [child], gizliyse [hidden] (varsayılan: hiçbir
/// şey — yer de kaplamaz).
///
/// DÜZENLEME MODUNDA: öğe gizli olsa da çizilir (soluk), köşesinde göz
/// rozeti durur ve öğenin KENDİ işi çalışmaz — dokunmak gizle/göster yapar
/// ve hemen kaydedilir (P50). Böylece kullanıcı ekranın kendisinde neyi görmek
/// istediğini seçer; ayar düğmeleri ekranda kalıcı yer kaplamaz.
///
/// Tercihi KENDİ dinler (P20): eskiden `StatelessWidget` + `ListenableBuilder`
/// — öğe başına iki kurulum; editörün ilk karesinde 11 öğe = 11 boşa kurulum.
class Customizable extends StatefulWidget {
  const Customizable({
    super.key,
    required this.id,
    required this.child,
    this.hidden = const SizedBox.shrink(),
    this.badgeInset = 0,
  });

  final String id;
  final Widget child;
  final Widget hidden;

  /// Rozetin köşeden içeri payı (sıkı yerleşimde taşmasın diye).
  final double badgeInset;

  /// Düzenleme modunda değilken [id] görünür mü — kurulumda okunur.
  static bool shows(String id) => Personalize.current.shows(id);

  /// SARMALAYICISIZ yuva: düzen modunda [Customizable] (çerçeve), normal
  /// kipte çıplak [child] ya da hiçbir şey. Kurulum sayısı sıkı yerler için
  /// (sabit ek çubuğu, video denetimi — klavye geçiş karesi bütçesi S17):
  /// normal kipte araya öğe girmez. ÇAĞIRAN Personalize'ı dinlemeli (mod ve
  /// görünürlük değişince yeniden kurulmalı).
  static Widget slot(String id, Widget child) {
    if (Personalize.editing) return Customizable(id: id, child: child);
    return shows(id) ? child : const SizedBox.shrink();
  }

  @override
  State<Customizable> createState() => _CustomizableState();
}

class _CustomizableState extends State<Customizable> {
  @override
  void initState() {
    super.initState();
    Personalize.listenable.addListener(_changed);
  }

  @override
  void dispose() {
    Personalize.listenable.removeListener(_changed);
    super.dispose();
  }

  void _changed() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final id = widget.id;
    final visible = Personalize.current.shows(id);
    if (!Personalize.editing) return visible ? widget.child : widget.hidden;
    return CustomizeFrame(
      visible: visible,
      inset: widget.badgeInset,
      onTap: () {
        AppHaptics.tick();
        Personalize.toggle(id);
      },
      child: widget.child,
    );
  }
}

/// Rozetin çapı ve simgesi (belirteç ölçeğinin altında — adlandırılmış).
const double _badgeSize = 20;
const double _badgeIcon = 12;

/// Gizli öğenin kesikli çerçevesinde çizgi (= boşluk) boyu.
const double _dash = 4;

/// Düzenleme modundaki çerçeve: görünür öğe ince birincil yıkama + çizgi,
/// gizli öğe soluk içerik + KESİKLİ çizgi; köşede göz rozeti (SB4).
/// İçeriğin dokunuşları KAPALI (dokunuş gizle/göster yapar). Mod açılınca
/// çerçeve ve rozet solarak belirir; dokunuşta rozet küçükten büyür.
/// Titreme/sallanma yok (plan_tasarim_B §1.2).
class CustomizeFrame extends StatefulWidget {
  const CustomizeFrame({
    super.key,
    required this.visible,
    required this.onTap,
    required this.child,
    this.inset = 0,
  });

  final bool visible;
  final VoidCallback onTap;
  final Widget child;
  final double inset;

  @override
  State<CustomizeFrame> createState() => _CustomizeFrameState();
}

class _CustomizeFrameState extends State<CustomizeFrame>
    with TickerProviderStateMixin {
  late final AnimationController _appear = AnimationController(vsync: this);
  late final AnimationController _pop = AnimationController(
    vsync: this,
    value: 1,
  );
  late final Animation<double> _scale = Tween<double>(
    begin: 0.85,
    end: 1,
  ).animate(_pop);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _appear.duration = AppMotion.of(context, AppMotion.short);
    _pop.duration = AppMotion.of(context, AppMotion.instant);
    if (_appear.status == AnimationStatus.dismissed) _appear.forward();
  }

  @override
  void didUpdateWidget(CustomizeFrame old) {
    super.didUpdateWidget(old);
    if (old.visible != widget.visible) _pop.forward(from: 0);
  }

  @override
  void dispose() {
    _appear.dispose();
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final visible = widget.visible;
    final inset = widget.inset;
    return Semantics(
      button: true,
      toggled: visible,
      label: visible ? l10n.customizeHideItem : l10n.customizeShowItem,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            IgnorePointer(
              child: AnimatedOpacity(
                duration: AppMotion.of(context, AppMotion.quick),
                opacity: visible ? 1 : AppAlpha.disabled,
                child: widget.child,
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: FadeTransition(
                  opacity: _appear,
                  child: visible
                      ? DecoratedBox(
                          decoration: BoxDecoration(
                            color: scheme.primary.withValues(
                              alpha: AppAlpha.hairline,
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.m),
                            border: Border.all(
                              color: scheme.primary.withValues(
                                alpha: AppAlpha.muted,
                              ),
                            ),
                          ),
                        )
                      : CustomPaint(painter: _DashedFrame(scheme.outline)),
                ),
              ),
            ),
            PositionedDirectional(
              top: inset - AppSpace.xs,
              end: inset - AppSpace.xs,
              child: IgnorePointer(
                child: FadeTransition(
                  opacity: _appear,
                  child: ScaleTransition(
                    scale: _scale,
                    child: Container(
                      width: _badgeSize,
                      height: _badgeSize,
                      decoration: BoxDecoration(
                        color: visible ? scheme.primary : scheme.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: visible ? scheme.primary : scheme.outline,
                        ),
                      ),
                      child: Icon(
                        visible ? Icons.visibility : Icons.visibility_off,
                        size: _badgeIcon,
                        color: visible ? scheme.onPrimary : scheme.outline,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gizli öğenin kesikli, yuvarlak köşeli çerçevesi: TEK `drawPoints`
/// (`paintItemDivider` kalıbı — çizgi parçası başına ayrı çağrı yok).
class _DashedFrame extends CustomPainter {
  const _DashedFrame(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(AppRadius.m),
    ).deflate(0.5);
    final points = <Offset>[];
    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += _dash * 2) {
        final a = metric.getTangentForOffset(d)?.position;
        final b = metric
            .getTangentForOffset(math.min(d + _dash, metric.length))
            ?.position;
        if (a != null && b != null) {
          points
            ..add(a)
            ..add(b);
        }
      }
    }
    canvas.drawPoints(
      ui.PointMode.lines,
      points,
      Paint()
        ..color = color
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_DashedFrame old) => old.color != color;
}

/// Uygulamanın TEPESİNDEKİ düzenleme modu şeridi: mod açıkken bütün
/// ekranların üstünde durur ve içeriği aşağı iter (hiçbir şeyi örtmez).
/// Dokunuşlar anında kaydedilir; "Geri al" modun açıldığı ana döner,
/// "Sırala" sıralama yerini ([onReorder]) açar, "Bitti" modu kapatır (P50 —
/// eskiden Vazgeç/Kaydet'li taslaktı).
///
/// Hareket (plan_tasarim_B §1.2, kasma md. 6): şerit YUVASI tek adımda açılır
/// ve kapanır (boy animasyonu yok); yalnız içerik yukarıdan kayıp solarak
/// gelir, kapanışta aynı yoldan gider, bitince yuva tek adımda kapanır.
class CustomizeModeHost extends StatefulWidget {
  const CustomizeModeHost({super.key, required this.child, this.onReorder});

  final Widget child;

  /// Şeritteki "Sırala" düğmesi; null = düğme çizilmez.
  final VoidCallback? onReorder;

  @override
  State<CustomizeModeHost> createState() => _CustomizeModeHostState();
}

class _CustomizeModeHostState extends State<CustomizeModeHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(vsync: this);

  /// Yuva açık mı (mod açık ya da çıkış hareketi sürüyor).
  bool _open = Personalize.editing;

  /// Son çizilen taslak: çıkış hareketinde şerit son hâliyle gider.
  UiPrefs? _last = Personalize.draft.value;

  @override
  void initState() {
    super.initState();
    Personalize.listenable.addListener(_changed);
    if (_open) _motion.value = 1;
  }

  @override
  void dispose() {
    Personalize.listenable.removeListener(_changed);
    _motion.dispose();
    super.dispose();
  }

  void _changed() {
    final draft = Personalize.draft.value;
    if (draft != null) {
      final opening = !_open || _motion.status == AnimationStatus.reverse;
      setState(() {
        _open = true;
        _last = draft;
      });
      if (opening) {
        _motion.duration = AppMotion.of(context, AppMotion.short);
        _motion.forward(from: 0);
        _tipOnce();
      }
      return;
    }
    if (!_open || _motion.status == AnimationStatus.reverse) return;
    // Çıkış: içerik gider, yuva hareket bitince tek adımda kapanır.
    setState(() {});
    _motion.duration = AppMotion.of(context, AppMotion.quick);
    _motion.reverse().whenCompleteOrCancel(() {
      if (mounted && !Personalize.editing) setState(() => _open = false);
    });
  }

  /// İlk girişte bir kez: "Dokun: gizle/göster · Sırala: yerini değiştir"
  /// (var olan ipucu hunisi; bildirim şeridi ağaçta yoksa sayılmaz).
  Future<void> _tipOnce() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted || !Personalize.editing) return;
      TipOnce.show(
        context,
        prefs,
        TipOnce.customizeMode,
        context.l10n.customizeHint,
        sessionLimit: false,
      );
    } catch (_) {
      // Tercih deposu yok (test düzeneği): ipucu atlanır.
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = Personalize.draft.value ?? _last;
    final open = _open && draft != null;
    return Column(
      children: [
        // AĞAÇ ŞEKLİ SABİT: mod açılınca uygulamanın ağacı (Navigator dahil)
        // başka bir ebeveynin altına taşınsaydı yeniden kurulur, açık ekranlar
        // kaybolurdu. Şerit yuvası kapalıyken boş kutu.
        if (open)
          _CustomizeStrip(
            motion: _motion,
            hiddenCount: draft.hidden.where((h) => !h.startsWith('+')).length,
            dirty: Personalize.dirty,
            live: Personalize.editing,
            onReorder: widget.onReorder,
          )
        else
          const SizedBox.shrink(),
        // **EKRAN BOYU ŞERİDİN ALTINDAKİ ALAN** (kullanıcı bulgusu
        // 2026-11-01: "ekranı düzenle açılınca ekran alta kayıyor, alttaki
        // butonlar görülmüyor"). KÖK NEDEN: şerit içeriği aşağı itiyor
        // ama `MediaQuery.size` hâlâ TAM ekranı söylüyordu; not açılış
        // geçişi (note_open_route) sayfayı o boyla çiziyor, editörün alt
        // çubuğu şerit kadar ekranın dışına taşıyordu. Boy artık bu alanın
        // kendisi — `MediaQuery.sizeOf` okuyan her yer doğru ölçer. Ağaç
        // şekli mod açık/kapalı aynı (LayoutBuilder hep burada).
        Expanded(
          child: LayoutBuilder(
            // Tek MediaQuery: `removePadding(context:)` burada DIŞTAKİ
            // (tam ekran) veriyi okuyup boyu geri yazardı.
            builder: (context, box) => MediaQuery(
              data: MediaQuery.of(context)
                  .removePadding(removeTop: open)
                  .copyWith(size: open ? box.biggest : null),
              child: widget.child,
            ),
          ),
        ),
      ],
    );
  }
}

/// Şeridin içerik boyu (üst güvenli alanın altında).
const double _stripHeight = 48;

/// Giriş/çıkışta içeriğin kendi boyuna göre kayma payı.
const double _slide = 0.25;

class _CustomizeStrip extends StatelessWidget {
  const _CustomizeStrip({
    required this.motion,
    required this.hiddenCount,
    required this.dirty,
    required this.live,
    required this.onReorder,
  });

  final AnimationController motion;
  final int hiddenCount;
  final bool dirty;

  /// false = çıkış hareketi: düğmeler dokunulmaz.
  final bool live;
  final VoidCallback? onReorder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final top = MediaQuery.paddingOf(context).top;
    final fg = scheme.onInverseSurface;
    final line = fg.withValues(alpha: AppAlpha.pressed);
    final curve = CurvedAnimation(
      parent: motion,
      curve: AppMotion.curveOf(context, AppMotion.enter),
      reverseCurve: AppMotion.curveOf(context, AppMotion.exit),
    );
    final hidden = hiddenCount;
    return Material(
      key: const ValueKey('customize-strip'),
      color: scheme.inverseSurface,
      shape: Border(bottom: BorderSide(color: line)),
      child: SizedBox(
        height: top + _stripHeight,
        child: ClipRect(
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              top: top,
              start: AppSpace.m,
              end: AppSpace.xs,
            ),
            child: FadeTransition(
              opacity: curve,
              // Kayma boyun ÇEYREĞİ (plan tam boy diyordu — sapma): tam
              // boyda ilk karelerde düğme şeridin kırpığının dışında kalıyor,
              // mod açılır açılmaz basılan "Bitti"/"Geri al" kaçıyordu.
              child: AnimatedBuilder(
                animation: curve,
                builder: (context, child) => FractionalTranslation(
                  translation: Offset(0, (curve.value - 1) * _slide),
                  child: child,
                ),
                child: IgnorePointer(
                  ignoring: !live,
                  child: Row(
                    children: [
                      Icon(Icons.tune_rounded, size: AppIconSize.s, color: fg),
                      const SizedBox(width: AppSpace.s),
                      // Başlık + hap boş alanın TAMAMINI alır (eskiden
                      // Flexible + Spacer yarı yarıya bölüşüyordu, küçük
                      // telefonda "Düzenlem…" kesiliyordu). Yine sığmazsa
                      // kısa etiket; tam ad hep semantikte.
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              key: const ValueKey('customize-title'),
                              child: Semantics(
                                label: l10n.customizeModeTitle,
                                excludeSemantics: true,
                                child: LayoutBuilder(
                                  builder: (context, box) {
                                    final style = theme.textTheme.labelLarge
                                        ?.copyWith(
                                          color: fg,
                                          fontWeight: AppWeight.strong,
                                        );
                                    final full = l10n.customizeModeTitle;
                                    final tp = TextPainter(
                                      text: TextSpan(text: full, style: style),
                                      maxLines: 1,
                                      textDirection: Directionality.of(context),
                                      textScaler: MediaQuery.textScalerOf(
                                        context,
                                      ),
                                    )..layout();
                                    final fits = tp.width <= box.maxWidth;
                                    tp.dispose();
                                    return Text(
                                      fits
                                          ? full
                                          : l10n.customizeModeTitleShort,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: style,
                                    );
                                  },
                                ),
                              ),
                            ),
                            if (hidden > 0) ...[
                              const SizedBox(width: AppSpace.s),
                              // Şerit Navigator'ın ÜSTÜNDE: Overlay yok, ipucu
                              // balonu (Tooltip) kurulamaz — ad Semantics'te.
                              Semantics(
                                key: const ValueKey('customize-hidden-count'),
                                label: l10n.customizeHiddenCount(hidden),
                                excludeSemantics: true,
                                child: DecoratedBox(
                                  decoration: ShapeDecoration(
                                    color: line,
                                    shape: const StadiumBorder(),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpace.s,
                                      vertical: AppSpace.xxs,
                                    ),
                                    child: Text(
                                      '$hidden',
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(color: fg),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      TextButton(
                        key: const ValueKey('customize-undo'),
                        style: TextButton.styleFrom(
                          foregroundColor: fg,
                          disabledForegroundColor: fg.withValues(
                            alpha: AppAlpha.disabled,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: dirty ? Personalize.revert : null,
                        child: Text(l10n.undo),
                      ),
                      if (onReorder != null)
                        IconButton(
                          key: const ValueKey('customize-reorder'),
                          color: fg,
                          visualDensity: VisualDensity.compact,
                          onPressed: onReorder,
                          icon: Icon(
                            Icons.swap_vert_rounded,
                            size: AppIconSize.m,
                            semanticLabel: l10n.reorderHandle,
                          ),
                        ),
                      const SizedBox(width: AppSpace.xs),
                      FilledButton(
                        key: const ValueKey('customize-done'),
                        style: FilledButton.styleFrom(
                          backgroundColor: scheme.inversePrimary,
                          foregroundColor: scheme.onPrimaryContainer,
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: Personalize.done,
                        child: Text(l10n.customizeDone),
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
