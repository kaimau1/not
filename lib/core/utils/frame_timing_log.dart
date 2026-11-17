import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// **UYGULAMA İÇİ HIZ GÜNLÜĞÜ** (PLAN §1.5 PL12, 16K §2.7): son [capacity]
/// karenin build/raster sürelerini tutar; Ayarlar → Hakkında'daki teşhis
/// satırı özetini (ortanca/p90, takılan kare) gösterir. Kablosuz, günlük
/// kullanımdan gerçek sayı.
///
/// Yalnız profil derlemesinde ya da `--dart-define=NOTLAR_HIZ_GUNLUGU=true`
/// (beta) ile açık. [enabled] derleme sabiti: kişisel release APK'da
/// [start] hiçbir şey kaydetmez (`addTimingsCallback` çağrılmaz) → sıfır
/// maliyet.
abstract final class FrameTimingLog {
  static const bool enabled =
      kProfileMode || bool.fromEnvironment('NOTLAR_HIZ_GUNLUGU');

  /// Tutulan kare sayısı (120 Hz'de ~5 sn kesintisiz çizim).
  static const int capacity = 600;

  // Halka tampon: [_build] ve [_raster] mikrosaniye.
  static final _build = Int32List(capacity);
  static final _raster = Int32List(capacity);
  static int _next = 0;
  static int _count = 0;
  static bool _started = false;

  /// Kayıtlı mı (bekçi testi için).
  static bool get started => _started;

  /// Uygulama başında bir kez. [enabled] değilse hiçbir şey yapmaz.
  static void start() {
    if (!enabled || _started) return;
    _started = true;
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
  }

  static void _onTimings(List<FrameTiming> timings) {
    for (final t in timings) {
      add(t.buildDuration.inMicroseconds, t.rasterDuration.inMicroseconds);
    }
  }

  /// Bir kare ekler (geri çağırma ve test).
  @visibleForTesting
  static void add(int buildUs, int rasterUs) {
    _build[_next] = buildUs;
    _raster[_next] = rasterUs;
    _next = (_next + 1) % capacity;
    if (_count < capacity) _count++;
  }

  @visibleForTesting
  static void reset() {
    _next = 0;
    _count = 0;
  }

  /// Kare bütçesi (µs): ekranın yenileme hızından; bilinmiyorsa 60 Hz.
  static int budgetUs() {
    final views = SchedulerBinding.instance.platformDispatcher.views;
    final hz = views.isEmpty ? 0.0 : views.first.display.refreshRate;
    return (1e6 / (hz >= 30 ? hz : 60)).round();
  }

  /// Teşhis satırı. Kayıt yoksa boş.
  static String summary({int? budget}) {
    if (_count == 0) return '';
    final s = FrameTimingSummary.of(
      _build.sublist(0, _count),
      _raster.sublist(0, _count),
      budgetUs: budget ?? budgetUs(),
    );
    return s.line;
  }
}

/// Son karelerin özeti. Takılan kare: build ya da raster bütçeyi aştı
/// (iki iş paralel koşar; biri aşınca kare kaçar).
@immutable
class FrameTimingSummary {
  const FrameTimingSummary({
    required this.frames,
    required this.buildP50,
    required this.buildP90,
    required this.rasterP50,
    required this.rasterP90,
    required this.janky,
    required this.budgetUs,
  });

  factory FrameTimingSummary.of(
    List<int> buildUs,
    List<int> rasterUs, {
    required int budgetUs,
  }) {
    var janky = 0;
    for (var i = 0; i < buildUs.length; i++) {
      if (buildUs[i] > budgetUs || rasterUs[i] > budgetUs) janky++;
    }
    return FrameTimingSummary(
      frames: buildUs.length,
      buildP50: _pct(buildUs, 50),
      buildP90: _pct(buildUs, 90),
      rasterP50: _pct(rasterUs, 50),
      rasterP90: _pct(rasterUs, 90),
      janky: janky,
      budgetUs: budgetUs,
    );
  }

  final int frames;
  final int buildP50;
  final int buildP90;
  final int rasterP50;
  final int rasterP90;
  final int janky;
  final int budgetUs;

  /// En yakın sıra yöntemi.
  static int _pct(List<int> values, int p) {
    if (values.isEmpty) return 0;
    final sorted = [...values]..sort();
    final rank = ((p / 100) * sorted.length).ceil() - 1;
    return sorted[rank.clamp(0, sorted.length - 1)];
  }

  static String _ms(int us) => (us / 1000).toStringAsFixed(1);

  /// Teşhis satırı (yalnız profil/beta; yerelleştirilmez, Diagnostics gibi).
  String get line =>
      'Hız günlüğü (son $frames kare, bütçe ${_ms(budgetUs)} ms): '
      'build ${_ms(buildP50)}/${_ms(buildP90)} · '
      'raster ${_ms(rasterP50)}/${_ms(rasterP90)} ms (ortanca/p90) · '
      'takılan $janky (%${(janky * 100 / frames).toStringAsFixed(1)})';
}
