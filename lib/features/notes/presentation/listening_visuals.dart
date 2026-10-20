import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../core/l10n_ext.dart';

/// Dinlemenin KİPİ: sesli yakalama (yapay zekâ levhası) ya da doğrudan
/// yazdırma (editördeki canlı dikte).
///
/// İKİ ALAN TEK GÖRÜNÜM (kullanıcı isteği 2026-10-20: "AI dinleme alanı ile
/// normal dinleme alanı aynı görünümde olsun ama farkı ayırt edilebilsin,
/// daha güzel bir alan olsun"). Eskiden levha başlıklı, dalga çubuklu bir
/// kart; dikte ise düz bir bilgi şeridiydi — aynı işin iki yabancı yüzü.
/// Artık ikisi de aynı parçalardan kurulur ([ListeningBadge], başlık +
/// [ListeningModeTag], [ListeningWaveform], süre); fark RENK ve SİMGEDE:
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

class _ListeningBadgeState extends State<ListeningBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _pulse.repeat();
  }

  @override
  void didUpdateWidget(ListeningBadge old) {
    super.didUpdateWidget(old);
    if (widget.active && !_pulse.isAnimating) {
      _pulse.repeat();
    } else if (!widget.active && _pulse.isAnimating) {
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
            Icons.mic,
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
    return SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: _pulse,
        child: core,
        builder: (context, child) {
          final t = _pulse.value;
          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              if (widget.active)
                Transform.scale(
                  scale: 1 + 0.35 * t,
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withValues(alpha: 0.28 * (1 - t)),
                    ),
                  ),
                ),
              child!,
            ],
          );
        },
      ),
    );
  }
}

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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            ai ? Icons.auto_awesome : Icons.keyboard_alt_outlined,
            size: 11,
            color: accent,
          ),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              ai ? l10n.listeningModeAi : l10n.listeningModeDictation,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
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

  @override
  Widget build(BuildContext context) {
    final d = DateTime.now().difference(widget.start);
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return Text(
      '$m:${s.toString().padLeft(2, '0')}',
      style: (widget.style ?? const TextStyle()).copyWith(
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

/// Dinlerken salınan dalga çubukları; durunca alçalıp donar.
///
/// TEK ticker, TEK CustomPaint: ticker bir ValueNotifier'ı besler, yalnız
/// painter yeniden ÇİZER — widget ağacı kare başına kurulmaz. Her çubuğun
/// ölçeği kendi periyodundan (560 + i·41 ms) hesaplanır (kayan dalga).
class ListeningWaveform extends StatefulWidget {
  const ListeningWaveform({
    super.key,
    required this.active,
    required this.color,
    this.idleColor,
    this.height = 48,
    this.bars = 24,
  });

  final bool active;
  final Color color;
  final Color? idleColor;
  final double height;
  final int bars;

  @override
  State<ListeningWaveform> createState() => _ListeningWaveformState();
}

class _ListeningWaveformState extends State<ListeningWaveform>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _elapsed = ValueNotifier<Duration>(Duration.zero);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      if (!widget.active) return;
      _elapsed.value = elapsed;
    });
    if (widget.active) _ticker.start();
  }

  @override
  void didUpdateWidget(ListeningWaveform old) {
    super.didUpdateWidget(old);
    if (widget.active && !_ticker.isActive) {
      _ticker.start();
    } else if (!widget.active && _ticker.isActive) {
      _ticker.stop();
      // Durunca çubuklar bekleme yüksekliğine insin (painter active'e bakar;
      // notifier'ı dürtmek son bir çizim tetikler).
      _elapsed.value = Duration.zero;
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _elapsed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: CustomPaint(
        painter: _WaveformPainter(
          elapsed: _elapsed,
          active: widget.active,
          bars: widget.bars,
          color: widget.active
              ? widget.color
              : widget.idleColor ??
                    Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  _WaveformPainter({
    required this.elapsed,
    required this.active,
    required this.color,
    required this.bars,
  }) : super(repaint: elapsed);

  final ValueListenable<Duration> elapsed;
  final bool active;
  final Color color;
  final int bars;

  /// Dinleme bitince çubuklar %16'ya iner ve durur.
  double _factor(int index) {
    if (!active) return 0.16;
    final period = 560 + index * 41;
    final phase = (elapsed.value.inMilliseconds % period) / period;
    // .32 → 1 → .32 arası yumuşak gidiş geliş.
    return 0.32 + 0.68 * (0.5 - 0.5 * math.cos(2 * math.pi * phase));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final gap = size.width / bars * 0.35;
    final barWidth = (size.width - gap * (bars - 1)) / bars;
    if (barWidth <= 0) return;
    final radius = Radius.circular(math.min(3, barWidth / 2));
    for (var i = 0; i < bars; i++) {
      final height = size.height * _factor(i);
      final left = i * (barWidth + gap);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, (size.height - height) / 2, barWidth, height),
          radius,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.active != active ||
      old.color != color ||
      old.bars != bars ||
      old.elapsed != elapsed;
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
    this.elevation = 0,
  });

  final ListeningMode mode;

  /// Levhada (not/listenin üstünde yüzerken) gölge verilir; editörün
  /// içindeki şeritte düz.
  final double elevation;

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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = listeningAccent(scheme, mode);
    return Material(
      key: ValueKey('listening-card-${mode.name}'),
      color: scheme.surfaceContainerLow,
      elevation: elevation,
      shadowColor: Colors.black45,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: accent.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ListeningBadge(mode: mode, active: active),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      // Kip etiketi ALT satırda, açıklamanın başında: başlık
                      // satırında durunca dar telefonda başlık "D..."ye
                      // iniyordu (sağda süre ve düğmeler de var).
                      Row(
                        children: [
                          Flexible(child: ListeningModeTag(mode: mode)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                clock,
                if (trailing.isNotEmpty) ...[
                  const SizedBox(width: 2),
                  ...trailing,
                ],
              ],
            ),
            if (body != null) ...[const SizedBox(height: 8), body!],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ListeningWaveform(
                    active: active,
                    color: accent,
                    height: 30,
                    bars: 28,
                  ),
                ),
                const SizedBox(width: 12),
                action,
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Kartın ana düğmesi: hap biçimli, simge + kısa etiket. Dinlerken kırmızı
/// "Bitir"; beklerken kipin renginde "Başla" / "Basılı tut".
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = listening ? scheme.error : scheme.primaryContainer;
    final foreground = listening ? scheme.onError : scheme.onPrimaryContainer;
    return SizedBox(
      height: 44,
      child: FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          disabledBackgroundColor: background,
          disabledForegroundColor: foreground,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
        icon: Icon(
          icon ?? (listening ? Icons.stop_rounded : Icons.mic),
          size: 20,
        ),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

/// Kartın başlık satırındaki küçük simge düğmesi (34 dp): üç düğme + süre
/// dar telefonda başlığı ezmesin.
class ListeningHeaderButton extends StatelessWidget {
  const ListeningHeaderButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.iconSize = 20,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final double iconSize;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints.tightFor(width: 34, height: 34),
    // M3 simge düğmesi 48 dp'lik dokunma kutusuna büyür; sıkı satırda
    // üç düğme 144 dp yiyip başlığı eziyordu.
    style: const ButtonStyle(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
    iconSize: iconSize,
    color: Theme.of(context).colorScheme.onSurfaceVariant,
    icon: Icon(icon),
    onPressed: onPressed,
  );
}
