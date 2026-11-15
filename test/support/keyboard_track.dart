import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/widgets/keyboard_snap.dart';

/// **ALT PANEL × GERÇEKÇİ KLAVYE İZİ** (S47, kullanıcı 2026-11-15: "klavye
/// açılırken bizim alt panel zıplaya zıplaya açılıyor; zaman zaman daha çok
/// ama hep az da olsa var").
///
/// Klavyenin GERÇEK konumu her sistem karesinde (16 ms) düzgün bir eğri;
/// Flutter'a gelen değer ise DÜZENSİZ: Android `onProgress` platform
/// iş parçacığında, Flutter karesi UI iş parçacığında — ikisinin fazı
/// kaydıkça bir Flutter karesine 0, 1 ya da 2 klavye adımı düşer
/// ([pattern]). Android < 35 motorunda animasyon karelerinde gezinme çubuğu
/// boşluktan düşülür, bitiş karesi tamdır (P55); [wiggle] verilirse o
/// sistem karesinde bildirilen değer birkaç dp GERİ oynar (iletim artığı,
/// klavyenin kendisi geri gitmez).
///
/// Her Flutter karesinde alt panelin (BottomAppBar) alt kenarı klavyenin o
/// anki GERÇEK üst kenarıyla karşılaştırılır. Panel saydamsa (kip c)
/// sapma/sıçrama sayılmaz, [PanelTrack.hidden] sayılır.
class PanelTrack {
  /// Panelin klavyeye TERS yönde > 1 px oynadığı kare (açılırken aşağı,
  /// kapanırken yukarı) — gözün "zıplama" dediği.
  int back = 0;

  /// Klavye > 2 px ilerlediği hâlde panelin < 0,5 px kıpırdadığı kare
  /// (takılıp sonra sıçrama = "kademeli").
  int stall = 0;

  /// Panelin kare adımının klavyenin o kareki adımından en büyük farkı
  /// (px): düzgün izlemede ~0, takıl-sıçra harekette büyük.
  double jerk = 0;

  /// Panelin BOYUNUN değiştiği kare (üst kenar alt kenardan bağımsız oynar).
  int resize = 0;

  /// Klavyenin gerçek üst kenarından en büyük / toplam sapma (px).
  double maxDev = 0;
  double sumDev = 0;
  int frames = 0;

  /// Klavye durduktan sonra (oturma) panelin > 1 px oynadığı kare.
  int settle = 0;

  /// Panelin görünmez olduğu hareket karesi (kip c).
  int hidden = 0;

  void add(PanelTrack o) {
    back += o.back;
    stall += o.stall;
    jerk = math.max(jerk, o.jerk);
    resize += o.resize;
    maxDev = math.max(maxDev, o.maxDev);
    sumDev += o.sumDev;
    frames += o.frames;
    settle += o.settle;
    hidden += o.hidden;
  }

  double get meanDev => frames == 0 ? 0 : sumDev / frames;

  Map<String, int> toBudget() => {
    'geri_sicrama': back,
    'takilma': stall,
    'sarsinti_px': jerk.round(),
    'maks_sapma_px': maxDev.round(),
    'ort_sapma_px10': (meanDev * 10).round(),
    'oturma_sicrama': settle,
    'boy_degisimi': resize,
  };

  @override
  String toString() => '${toBudget()} gizli=$hidden (kare $frames)';
}

List<double> _ease(double from, double to, int frames) => [
  for (var i = 1; i <= frames; i++)
    from + (to - from) * Curves.fastOutSlowIn.transform(i / frames),
];

/// Panelin görünürlüğü: atalardaki saydamlıkların çarpımı.
double _alpha(RenderObject ro) {
  var a = 1.0;
  for (RenderObject? p = ro; p != null; p = p.parent) {
    if (p is RenderOpacity) a *= p.opacity;
    if (p is RenderAnimatedOpacity) a *= p.opacity.value;
  }
  return a;
}

/// Editör açık ve gövdeye odaklı (klavye kapalı) iken çağrılır: aç → bekle →
/// kapa → bekle. [nav] gezinme çubuğu (harness 48).
Future<PanelTrack> trackPanel(
  WidgetTester tester, {
  required Size size,
  required bool android31,
  required List<int> pattern,
  double nav = 48,
  double keyboard = 300,
  int openFrames = 18,
  Set<int> wiggle = const {},
}) async {
  final out = PanelTrack();
  final bar = find.byType(BottomAppBar);
  double edge() => tester.getRect(bar).bottom;
  double alpha() => _alpha(tester.renderObject(bar));
  final legs = [
    (real: _ease(0, keyboard, openFrames), holdMs: 400),
    (real: _ease(keyboard, 0, openFrames - 2), holdMs: 400),
  ];
  // Panelin boyu (üst kenar = KeyboardSlide'ın ötelenen çocuğu).
  final top = find
      .descendant(
        of: find.byType(KeyboardSlide),
        matching: find.byType(Padding),
      )
      .first;
  double height() => edge() - tester.getRect(top).top;
  final h0 = height();
  var last = edge();
  var lastReal = 0.0;
  var reportedNow = 0.0;
  var p = 0;
  for (final leg in legs) {
    final n = leg.real.length;
    double reported(int i) {
      final real = leg.real[i];
      var r = android31 && i < n - 1 ? math.max(0.0, real - nav) : real;
      if (wiggle.contains(i) && r > 0) r = math.max(0.0, r - 6);
      return r;
    }

    var d = -1;
    for (var j = 0; d < n - 1; j++) {
      final k = pattern[p++ % pattern.length];
      d = math.min(math.min(d + k, j), n - 1);
      if (d >= 0) reportedNow = reported(d);
      tester.view.viewInsets = FakeViewPadding(bottom: reportedNow);
      tester.view.padding = FakeViewPadding(
        top: 30,
        bottom: (nav - reportedNow).clamp(0.0, nav),
      );
      await tester.pump(const Duration(milliseconds: 16));
      tester.takeException();
      final real = leg.real[math.min(j, n - 1)];
      final y = edge();
      final step = y - last;
      // Klavye gezinme çubuğunun ardındayken (≤ nav) panel yerinde durur.
      final moved = math.max(nav, real) - math.max(nav, lastReal);
      final h = height();
      if ((h - h0).abs() > 1) out.resize++;
      final visible = alpha() > 0.05;
      if (!visible) {
        out.hidden++;
      } else {
        final want = size.height - math.max(nav, real);
        final dev = (y - want).abs();
        out.maxDev = math.max(out.maxDev, dev);
        out.sumDev += dev;
        out.frames++;
        final rising = leg.real.last > leg.real.first;
        if (rising ? step > 1 : step < -1) out.back++;
        if (moved.abs() > 2 && step.abs() < 0.5) out.stall++;
        // Klavyenin kendi adımından sapma (ekranda y aşağı +).
        out.jerk = math.max(out.jerk, (step + moved).abs());
      }
      last = y;
      lastReal = real;
    }
    for (var t = 0; t < leg.holdMs; t += 16) {
      await tester.pump(const Duration(milliseconds: 16));
      tester.takeException();
      final y = edge();
      if ((y - last).abs() > 1 && alpha() > 0.05) out.settle++;
      last = y;
    }
  }
  return out;
}

/// S47 desenleri: düzgün (her kareye bir adım) ve faz kayan iletim (0/1/2;
/// hiçbir kare klavyenin önüne geçmez).
const kRegularPattern = [1];
const kJitterPattern = [1, 0, 2, 1, 1, 0, 2, 1, 0, 2, 1, 1];

/// [KeyboardInset.navExcludedWhileAnimating] testte elle (Android < 35).
void setAndroid31(bool on) => KeyboardInset.navExcludedWhileAnimating = on;
