import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/presentation/viewers/ink_layer.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// Tablet bulgusu 2026-11-07: kalem kipi kapanınca sayfa katmanı genişliğinden
/// kısa kalıyor, kare tuval o boya sıkışıp çizim dikeyde basılıyordu.
void main() {
  testWidgets('kısa katmanda da tuval kare (çizim basılmaz)', (tester) async {
    final ink = InkController(initial: const [], onChanged: (_) {});
    addTearDown(ink.dispose);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('tr'),
        home: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 400,
            height: 250,
            child: InkPageLayer(controller: ink, page: 1, uniform: true),
          ),
        ),
      ),
    );
    final paint = find.descendant(
      of: find.byType(InkPageLayer),
      matching: find.byType(CustomPaint),
    );
    expect(tester.getSize(paint.first), const Size(400, 400));
  });
}
