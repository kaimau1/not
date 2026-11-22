import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/a11y/min_tap_target.dart';
import '../../../core/a11y/motion.dart';
import '../../../core/app_icons.dart';
import '../../../app/theme/app_design.dart';
import '../../../app/theme/app_tokens.dart';
import 'voice_level_wave.dart';

/// Dinlemenin KİPİ: sesli yakalama (yapay zekâ levhası) ya da doğrudan
/// yazdırma (editördeki canlı dikte).
///
/// İKİ ALAN TEK GÖRÜNÜM (kullanıcı isteği 2026-10-20: "AI dinleme alanı ile
/// normal dinleme alanı aynı görünümde olsun ama farkı ayırt edilebilsin,
/// daha güzel bir alan olsun"). Eskiden levha başlıklı, dalga çubuklu bir
/// kart; dikte ise düz bir bilgi şeridiydi — aynı işin iki yabancı yüzü.
/// Artık ikisi de aynı parçalardan kurulur ([ListeningBadge], başlık +
/// [ListeningModeTag], [VoiceLevelWave], süre); fark RENK ve SİMGEDE:
/// yapay zekâ yıldızlı ve iki renkli geçişli, doğrudan yazım düz mikrofon.
enum ListeningMode { ai, dictation }

/// Kipin vurgu rengi (rozet, dalga, etiket).
Color listeningAccent(ColorScheme scheme, ListeningMode mode) =>
    mode == ListeningMode.ai ? scheme.tertiary : scheme.primary;

/// Dinleme alanının solundaki yuvarlak rozet; dinlerken çevresinde nabız
/// halkası atar.
class ListeningBadge extends StatefulWidget {
  const ListeningBadge({
    super.key,
    required this.mode,
    required this.active,
    this.size = 40,
  });

  final ListeningMode mode;
  final bool active;
  final double size;

  @override
  State<ListeningBadge> createState() => _ListeningBadgeState();
}

/// Rozet nabzının bir döngüsü.
const Duration _kPulsePeriod = Duration(milliseconds: 1400);

/// Nabız halkasının en büyük ölçek artışı ve başlangıç saydamlığı; hareket
/// azaltılmışken halka durur, sabit [_kPulseRest] opak kalır.
const double _kPulseGrow = 0.35, _kPulseAlpha = 0.28, _kPulseRest = 0.2;

class _ListeningBadgeState extends State<ListeningBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: _kPulsePeriod,
  );
  bool _motion = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _motion = motionOf(context);
    _sync();
  }

  @override
  void didUpdateWidget(ListeningBadge old) {
    super.didUpdateWidget(old);
    _sync();
  }

  /// Nabız yalnız dinlerken ve hareket açıkken döner.
  void _sync() {
    final run = widget.active && _motion;
    if (run && !_pulse.isAnimating) {
      _pulse.repeat();
    } else if (!run && _pulse.isAnimating) {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ai = widget.mode == ListeningMode.ai;
    final accent = listeningAccent(scheme, widget.mode);
    final size = widget.size;
    final core = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.active ? null : scheme.surfaceContainerHighest,
        gradient: widget.active
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: ai
                    ? [scheme.primary, scheme.tertiary]
                    : [accent, accent],
              )
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            AppIcons.dictation,
            size: size * 0.5,
            color: widget.active ? scheme.onPrimary : scheme.onSurfaceVariant,
          ),
          if (ai)
            Positioned(
              right: size * 0.12,
              top: size * 0.1,
              child: Icon(
                Icons.auto_awesome,
                size: size * 0.3,
                color: widget.active ? scheme.onPrimary : accent,
              ),
            ),
        ],
      ),
    );
    return RepaintBoundary(
      child: SizedBox(
        width: size,
        height: size,
        child: AnimatedBuilder(
          animation: _pulse,
          child: core,
          builder: (context, child) {
            final t = _pulse.value;
            final alpha = _motion ? _kPulseAlpha * (1 - t) : _kPulseRest;
            return Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                if (widget.active)
                  Transform.scale(
                    scale: 1 + _kPulseGrow * t,
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent.withValues(alpha: alpha),
                      ),
                    ),
                  ),
                child!,
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Kip etiketinin simgesi.
const double _kTagIcon = 12;

/// Küçük kip etiketi ("Yapay zekâ" / "Doğrudan yazım").
class ListeningModeTag extends StatelessWidget {
  const ListeningModeTag({super.key, required this.mode});

  final ListeningMode mode;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final accent = listeningAccent(scheme, mode);
    final ai = mode == ListeningMode.ai;
    return Container(
      key: ValueKey('listening-mode-${mode.name}'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.s,
        vertical: AppSpace.xxs,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: AppAlpha.pressed),
        borderRadius: BorderRadius.circular(AppRadius.s),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            ai ? Icons.auto_awesome : Icons.keyboard_alt_outlined,
            size: _kTagIcon,
            color: accent,
          ),
          const SizedBox(width: AppSpace.xs),
          Flexible(
            child: Text(
              ai ? l10n.listeningModeAi : l10n.listeningModeDictation,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.of(
                Theme.of(context),
              ).meta.copyWith(fontWeight: AppWeight.strong, color: accent),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dinlerken süren saniye sayacı ("0:07"); [start] anından itibaren kendi
/// zamanlayıcısıyla ilerler — çağıran ekran her saniye yeniden kurulmaz.
class ListeningClock extends StatefulWidget {
  const ListeningClock({
    super.key,
    required this.start,
    required this.active,
    this.style,
  });

  final DateTime start;
  final bool active;
  final TextStyle? style;

  @override
  State<ListeningClock> createState() => _ListeningClockState();
}

class _ListeningClockState extends State<ListeningClock> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(ListeningClock old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    if (widget.active && _timer == null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else if (!widget.active) {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // SANİYE BAŞINA DİZİLME YOK (2026-11-17, S46 CI kök nedeni): eskiden her
  // saniye `Text` değişiyor, kartın satırı yeniden diziliyordu (dikte
  // boyunca saniyede ~22 RenderObject; CI'da gerçek saniye geçince S46
  // `kart_acik_fazla_dizilme` 0 → 22). Artık kutu boyu yalnız hane sayısıyla
  // (tablo rakamları: her rakam aynı genişlikte) değişir; saniye değişince
  // yalnız yeniden BOYANIR.
  @override
  Widget build(BuildContext context) {
    final d = DateTime.now().difference(widget.start);
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    final text = '$m:${s.toString().padLeft(2, '0')}';
    final style = (widget.style ?? AppText.of(Theme.of(context)).label)
        .copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
    final dir = Directionality.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    // Kalıp: aynı hane sayısında sıfırlar → boy saniyeyle değişmez.
    final template = text.replaceAll(RegExp(r'\d'), '0');
    final measure = TextPainter(
      text: TextSpan(text: template, style: style),
      textDirection: dir,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    final size = measure.size;
    measure.dispose();
    return Semantics(
      label: text,
      excludeSemantics: true,
      child: CustomPaint(
        size: size,
        painter: _ClockPainter(text, style, dir, scaler),
      ),
    );
  }
}

class _ClockPainter extends CustomPainter {
  _ClockPainter(this.text, this.style, this.dir, this.scaler);

  final String text;
  final TextStyle style;
  final TextDirection dir;
  final TextScaler scaler;

  @override
  void paint(Canvas canvas, Size size) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: dir,
      textScaler: scaler,
      maxLines: 1,
    )..layout(maxWidth: size.width + 1);
    tp.paint(
      canvas,
      Offset(dir == TextDirection.rtl ? size.width - tp.width : 0, 0),
    );
    tp.dispose();
  }

  @override
  bool shouldRepaint(_ClockPainter old) =>
      old.text != text ||
      old.style != style ||
      old.dir != dir ||
      old.scaler != scaler;
}

/// Kartın en geniş hâli: tablette/webde ortalı durur, telefonda etkisiz.
const double _kCardMaxWidth = 560;

/// Sessizlik geri sayımı çizgisinin kalınlığı (yuvası HEP ayrılmış).
const double _kSilenceBar = 2;

/// Dinleme alanının ORTAK KABUĞU (P63 PB5): editörün dikte kartı ve sesli not
/// levhasının bütün evreleri (dinleme, işleniyor, hata, gözden geçirme) AYNI
/// yüzen yüzeyde — `AppSurface.floating`, kenar çizgisi kip rengi × soft;
/// bulanık gölge yok. En çok 560 dp, ortalı.
class ListeningSurface extends StatelessWidget {
  const ListeningSurface({
    super.key,
    required this.mode,
    required this.child,
    this.surfaceKey,
  });

  final ListeningMode mode;
  final Widget child;

  /// Yüzeyin kendisinin (en sınırlı kutu) anahtarı — ölçen testler için.
  final Key? surfaceKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = listeningAccent(theme.colorScheme, mode);
    final radius = BorderRadius.circular(AppRadius.xl);
    return Align(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _kCardMaxWidth),
        child: DecoratedBox(
          key: surfaceKey,
          decoration: AppSurface.floating(theme, radius: AppRadius.xl).copyWith(
            border: Border.all(color: accent.withValues(alpha: AppAlpha.soft)),
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Material(type: MaterialType.transparency, child: child),
          ),
        ),
      ),
    );
  }
}

/// Kartın BAŞLIK SATIRI — dinleme kartı ve gözden geçirme evresi tek bileşen:
/// rozet · başlık + (alt satırda) kip etiketi + alt yazı · süre · düğmeler.
/// [silence] ve [silenceHint] verilirse geri sayım başlayınca alt yazı
/// [silenceHint] olur (yalnız o metin yeniden kurulur).
class ListeningHeader extends StatelessWidget {
  const ListeningHeader({
    super.key,
    required this.mode,
    required this.active,
    required this.title,
    required this.subtitle,
    required this.clock,
    this.trailing = const [],
    this.silence,
    this.silenceHint,
  });

  final ListeningMode mode;
  final bool active;
  final String title;
  final String subtitle;
  final Widget clock;
  final List<Widget> trailing;
  final ValueListenable<double>? silence;
  final String? silenceHint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = AppText.of(theme);
    final accent = listeningAccent(theme.colorScheme, mode);
    final meta = text.meta;
    Widget sub(String s, {bool alert = false}) => Text(
      s,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: alert
          ? meta.copyWith(color: accent, fontWeight: AppWeight.medium)
          : meta,
    );
    final hint = silenceHint;
    final quiet = silence;
    final hasSub = subtitle.isNotEmpty || (hint != null && quiet != null);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            ListeningBadge(mode: mode, active: active),
            const SizedBox(width: AppSpace.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.rowTitle.copyWith(fontWeight: AppWeight.strong),
                  ),
                  const SizedBox(height: AppSpace.xxs),
                  ListeningModeTag(mode: mode),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.s),
            clock,
            if (trailing.isNotEmpty) ...[
              const SizedBox(width: AppSpace.xxs),
              ...trailing,
            ],
          ],
        ),
        if (hasSub) ...[
          const SizedBox(height: AppSpace.xs),
          hint == null || quiet == null
              ? sub(subtitle)
              // Yalnız bu metin kurulur (yoklama 250 ms'de bir).
              : ValueListenableBuilder<double>(
                  valueListenable: quiet,
                  builder: (_, v, _) =>
                      sub(v > 0 ? hint : subtitle, alert: v > 0),
                ),
        ],
      ],
    );
  }
}

/// Dinleme alanının ORTAK KARTI — editörün doğrudan yazdırma şeridi ve
/// yapay zekâ ile sesli not levhası AYNI kartı kullanır.
///
/// KÖK NEDEN (kullanıcı isteği 2026-10-20: "AI sesli not ile doğrudan yazım
/// ekranları hâlâ farklı, ortak bir ekranda olmalılar; AI ses ekranı çok
/// büyük, doğrudan not ekranı çok küçük, ikisinin arasında bir şey olsun").
/// Parçalar ortaktı ama YERLEŞİMLER ayrıydı: levha başlık + 74-210 px döküm
/// + 40 px dalga + 54 px tam genişlik düğme + ipucu (~330 px), şerit ise tek
/// satırdı (~56 px; dalga 40 px'e sıkışmış). Artık tek yerleşim: üstte
/// rozet + başlık/kip + süre, altta TAM GENİŞLİK dalga ve yanında eylem
/// düğmesi (~120 px). Yapay zekâ kipinde arada döküm durur ([body]) —
/// doğrudan yazımda yazı zaten notun içine akıyor.
///
/// P63 PB5: dalga GERÇEK ses düzeyini izler ([level]; düzey olayı kartı
/// kurmaz, yalnız dalga boyanır); sessizlik geri sayımı dalganın altında,
/// yuvası hep ayrılmış — kart dinleme boyunca boy değiştirmez.
class ListeningCard extends StatelessWidget {
  const ListeningCard({
    super.key,
    required this.mode,
    required this.active,
    required this.title,
    required this.subtitle,
    required this.clock,
    required this.action,
    this.trailing = const [],
    this.body,
    this.level,
    this.silence,
    this.silenceHint,
  });

  final ListeningMode mode;

  /// Mikrofon şu an açık mı (rozet nabzı, dalga).
  final bool active;
  final String title;
  final String subtitle;

  /// Sağ üstteki süre.
  final Widget clock;

  /// Dalganın yanındaki ana düğme (Bitir / Başla / Basılı tut).
  final Widget action;

  /// Başlık satırının sağındaki küçük düğmeler (komutlar, kip değiştir…).
  final List<Widget> trailing;

  /// Başlık ile dalga arasındaki içerik (yapay zekâ kipinde canlı döküm).
  final Widget? body;

  /// Ses düzeyi 0–1 (null: düzey bilinmiyor, dalga yine yaşar).
  final ValueListenable<double>? level;

  /// Sessizlik geri sayımı 0–1 (null: çizgi yok, yuva yine ayrılmış).
  final ValueListenable<double>? silence;

  /// Sayım başlayınca alt yazı (null: alt yazı değişmez — çağıran yönetir).
  final String? silenceHint;

  @override
  Widget build(BuildContext context) {
    final accent = listeningAccent(Theme.of(context).colorScheme, mode);
    final quiet = silence;
    return ListeningSurface(
      surfaceKey: ValueKey('listening-card-${mode.name}'),
      mode: mode,
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.m),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListeningHeader(
              mode: mode,
              active: active,
              title: title,
              subtitle: subtitle,
              clock: clock,
              trailing: trailing,
              silence: silence,
              silenceHint: silenceHint,
            ),
            if (body != null) ...[const SizedBox(height: AppSpace.s), body!],
            const SizedBox(height: AppSpace.s),
            Row(
              children: [
                Expanded(
                  child: VoiceLevelWave(
                    active: active,
                    color: accent,
                    level: level,
                  ),
                ),
                const SizedBox(width: AppSpace.m),
                action,
              ],
            ),
            const SizedBox(height: AppSpace.xs),
            SizedBox(
              height: _kSilenceBar,
              child: quiet == null
                  ? null
                  : ValueListenableBuilder<double>(
                      valueListenable: quiet,
                      builder: (context, v, _) => AnimatedOpacity(
                        opacity: active && v > 0 ? 1 : 0,
                        duration: AppMotion.of(context, AppMotion.quick),
                        child: LinearProgressIndicator(
                          key: const ValueKey('voice-silence-bar'),
                          value: v,
                          minHeight: _kSilenceBar,
                          color: accent,
                          borderRadius: BorderRadius.circular(AppRadius.hair),
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

/// Kartın ana düğmesi: hap biçimli, simge + kısa etiket. Dinlerken kırmızı
/// "Bitir" (kayıt durumu — kaçırılamayacak gösterge); beklerken kipin
/// renginde "Başla" / "Basılı tut".
class ListeningActionButton extends StatelessWidget {
  const ListeningActionButton({
    super.key,
    required this.listening,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final bool listening;
  final String label;
  final IconData? icon;

  /// null: düğme dokunuşu kendi işlemez (basılı-tut kipinde dokunuşu
  /// çevreleyen `Listener` alır) ama ETKİN görünür.
  final VoidCallback? onPressed;

  /// Hap yüksekliği.
  static const double height = 44;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = listening ? scheme.error : scheme.primaryContainer;
    final foreground = listening ? scheme.onError : scheme.onPrimaryContainer;
    return SizedBox(
      height: height,
      child: FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          disabledBackgroundColor: background,
          disabledForegroundColor: foreground,
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.l),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: AppWeight.strong),
        ),
        icon: Icon(
          icon ?? (listening ? Icons.stop_rounded : AppIcons.dictation),
          size: AppIconSize.m,
        ),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

/// Başlık düğmesinin görünen boyu (dokunma alanı 48).
const double _kHeaderButton = 34;

/// Kartın başlık satırındaki küçük simge düğmesi (34 dp): üç düğme + süre
/// dar telefonda başlığı ezmesin.
class ListeningHeaderButton extends StatelessWidget {
  const ListeningHeaderButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.iconSize = AppIconSize.m,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final double iconSize;

  @override
  // Görünüm 34 dp kalır; dokunma/ekran okuyucu alanı 48 dp (F15.4).
  Widget build(BuildContext context) => MinTapTarget(
    child: IconButton(
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(
        width: _kHeaderButton,
        height: _kHeaderButton,
      ),
      // M3 simge düğmesi 48 dp'lik dokunma kutusuna büyür; sıkı satırda
      // üç düğme 144 dp yiyip başlığı eziyordu.
      style: const ButtonStyle(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
      iconSize: iconSize,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      icon: Icon(icon),
      onPressed: onPressed,
    ),
  );
}
