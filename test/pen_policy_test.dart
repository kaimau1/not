import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/presentation/viewers/pen_policy.dart';

/// **KALEM KURALI DOĞRULUK TABLOSU** (OTURTMA F63.1). Tablo BUGÜNKÜ davranışla
/// yazıldı (2026-11-10): kural tek yere taşınırken davranış değişmez. Sapma
/// istenirse önce bu tablo değişir.
const _stylus = {PointerDeviceKind.stylus, PointerDeviceKind.invertedStylus};
const _all = {
  PointerDeviceKind.stylus,
  PointerDeviceKind.invertedStylus,
  PointerDeviceKind.touch,
  PointerDeviceKind.mouse,
};

/// Beklenen (yerel kopyaların 2026-11-10'daki hâli, yüzey yüzey).
({Set<PointerDeviceKind>? kinds, bool active, bool toggle}) _expected(
  PenSurface s, {
  required bool pen,
  required bool auto,
  required bool ever,
}) => switch (s) {
  // note_editor_flow._syncPageInkKinds + StylusToggleOverlay.visible
  PenSurface.page => (
    kinds: pen ? _all : (auto ? _stylus : const {}),
    active: true,
    toggle: ever,
  ),
  // pinned_media_pane._penOn / _inkFor
  PenSurface.pinnedDoc => (
    kinds: pen ? null : _stylus,
    active: pen || (auto && ever),
    toggle: ever,
  ),
  // note_images._docInkFor
  PenSurface.embeddedDoc => (kinds: _stylus, active: auto && ever, toggle: ever),
  // note_package build
  PenSurface.package => (kinds: pen ? null : _stylus, active: true, toggle: false),
  PenSurface.viewer => (kinds: null, active: pen, toggle: false),
  PenSurface.drawing => (kinds: null, active: true, toggle: false),
};

void main() {
  test('6 yüzey × kip × yüzen düğme × kalem görüldü × yalnız kalem', () {
    const bools = [false, true];
    for (final s in PenSurface.values) {
      for (final pen in bools) {
        for (final auto in bools) {
          for (final ever in bools) {
            for (final only in bools) {
              final why = '$s kip=$pen yazar=$auto görüldü=$ever yalnız=$only';
              final p = PenPolicy.resolve(
                surface: s,
                penMode: pen,
                autoStylus: auto,
                stylusEver: ever,
                penOnly: only,
              );
              final e = _expected(s, pen: pen, auto: auto, ever: ever);
              expect(p.allowedKinds, e.kinds, reason: why);
              expect(p.layerActive, e.active, reason: why);
              expect(p.showFloatingToggle, e.toggle, reason: why);
              // Parmak ancak katman kuruluyken, türü kabul ediliyorken ve
              // "yalnız kalem" kapalıyken çizer; yoksa kaydırır.
              final draws =
                  e.active &&
                  !only &&
                  (e.kinds == null ||
                      e.kinds!.contains(PointerDeviceKind.touch));
              expect(p.fingerScrolls, !draws, reason: why);
            }
          }
        }
      }
    }
  });

  test('KALEM_PLANI kuralları', () {
    PenPolicy r(
      PenSurface s, {
      bool pen = false,
      bool auto = true,
      bool ever = true,
      bool only = true,
    }) => PenPolicy.resolve(
      surface: s,
      penMode: pen,
      autoStylus: auto,
      stylusEver: ever,
      penOnly: only,
    );
    // 1: kalem kipi açık + kalem görülmüş ("yalnız kalem") → parmak çizmez.
    expect(r(PenSurface.page, pen: true).fingerScrolls, isTrue);
    expect(r(PenSurface.pinnedDoc, pen: true).fingerScrolls, isTrue);
    // 2: kalemsiz cihazda kalem düğmesi PARMAĞI çizdirir.
    final phone = r(PenSurface.page, pen: true, ever: false, only: false);
    expect(phone.fingerScrolls, isFalse);
    expect(phone.showFloatingToggle, isFalse);
    // …ve otomatik katman yok: basılı tut seçim parmakta.
    expect(r(PenSurface.pinnedDoc, ever: false).layerActive, isFalse);
    expect(r(PenSurface.embeddedDoc, ever: false).layerActive, isFalse);
    // 3: yüzen düğme "dokunur" → kip kapalıyken hiçbir yüzeyde kalem çizmez.
    expect(r(PenSurface.page, auto: false).allowedKinds, isEmpty);
    expect(r(PenSurface.pinnedDoc, auto: false).layerActive, isFalse);
    expect(r(PenSurface.embeddedDoc, auto: false).layerActive, isFalse);
  });

  test('yerel kural kopyası yok: allowedKinds yalnız PenPolicy\'den atanır', () {
    final offenders = <String>[];
    final assign = RegExp(r'allowedKinds\s*=[^=]');
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (!assign.hasMatch(line)) continue;
        // Kuralın kendisi; "daire çizerek göm" kipinde sayfa kapalı (const {}).
        if (line.toLowerCase().contains('policy') ||
            line.contains('const {};')) {
          continue;
        }
        offenders.add('${f.path}:${i + 1}: ${line.trim()}');
      }
    }
    expect(offenders, isEmpty);
  });
}
