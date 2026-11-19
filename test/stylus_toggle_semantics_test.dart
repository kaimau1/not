import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/presentation/editor/stylus_toggle.dart';
import 'package:notlar/features/notes/presentation/viewers/ink_tools.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// KT-25 (tablet turu, P78): uiautomator dökümünde "Kalem yazar" düğümü
/// TÜM EKRANI kaplıyordu — ekran okuyucu ekranın her yerine "Kalem yazar"
/// diyordu. Düğümün kutusu düğmenin kendisi (≤ 56 dp) olmalı.
///
/// 2026-11-19: widget testinde ÜRETİLEMEDİ (düğüm 44×44, üstündekiler
/// etiketsiz kap) — cihaz dökümü ile çelişiyor; bu test bekçi olarak kalır,
/// kök neden cihazda (TalkBack/uiautomator) aranacak.
void main() {
  setUp(InkToolMemory.reset);
  tearDown(InkToolMemory.reset);

  testWidgets('yüzen kalem düğmesinin erişilebilirlik kutusu düğme boyunda', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(640, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('tr'),
        home: Scaffold(body: StylusToggleOverlay(child: SizedBox.expand())),
      ),
    );
    await tester.pumpAndSettle();
    final node = tester.getSemantics(find.bySemanticsLabel('Kalem yazar'));
    final size = node.rect.size;
    expect(size.width, lessThanOrEqualTo(56), reason: '$size');
    expect(size.height, lessThanOrEqualTo(56), reason: '$size');
    handle.dispose();
  });
}
