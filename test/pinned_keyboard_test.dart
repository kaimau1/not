import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/presentation/editor/pinned_media_pane.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// Kullanıcı bulgusu 2026-10-19: "video sabitken klavye açıldığında video
/// yukarı itiliyor biraz". Sınır o anki yükseklikten alındığı için klavye
/// oturunca bölme büzülüyordu.
void main() {
  test('klavyesiz: eski sınır (%70)', () {
    expect(pinnedMaxHeight(available: 800, stable: 800), closeTo(560, 0.01));
  });

  test('klavye açık: bölme YERİNDE kalır, not satırına yer bırakır', () {
    // Eskiden 0.7 × 480 = 336'ya düşerdi; 380 dp'lik video küçülürdü.
    final max = pinnedMaxHeight(available: 480, stable: 800);
    expect(max, 480 - kPinnedBarHeight - kPinnedNoteMinHeight);
    expect(max, greaterThan(480 * kPinnedMaxFraction));
  });

  test('çok dar alanda bile en küçük yükseklik korunur', () {
    expect(pinnedMaxHeight(available: 150, stable: 800), kPinnedMinHeight);
  });

  // P49 (kullanıcı 2026-11-12: "sabit ek varken klavye açılırken hem sabit
  // ek paneli hem klavye kasıyor"). KÖK NEDEN: pencerenin BOYU 260 ms kare
  // kare değişiyor, alttaki not her karede yeniden diziliyordu (kasma
  // listesi §6). Boy tek adımda değişir; hareket yalnız boyamada.
  testWidgets('klavye: pencerenin boyu TEK ADIMDA değişir, çubuk boyamada '
      'kayar; kapanırken boy klavye bitene dek değişmez', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('tr'),
        home: Scaffold(
          resizeToAvoidBottomInset: false,
          body: PinnedMediaPane(
            media: const Attachment(
              id: 'g',
              kind: AttachmentKind.image,
              fileName: 'g.jpg',
              mimeType: 'image/jpeg',
              width: 100,
              height: 200,
              pinHeight: 500,
            ),
            onHeightChanged: (_) {},
            onUnpin: () {},
            onOpen: () {},
            child: const Text('not gövdesi'),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
    final window = find.byKey(const ValueKey('pinned-media-window'));
    final bar = find.byKey(const ValueKey('pinned-media-bar'));
    double laid() => tester.getSize(window).height;
    double barTop() => tester.getTopLeft(bar).dy;
    expect(laid(), 500);
    expect(barTop(), 500);

    Future<void> keyboard(double inset) async {
      tester.view.viewInsets = FakeViewPadding(bottom: inset);
      await tester.pump(const Duration(milliseconds: 16));
    }

    // AÇILIŞ: ilk karede boy hedefe iner; sonraki karelerde DEĞİŞMEZ.
    await keyboard(20);
    final open = laid();
    expect(open, lessThan(500));
    final tops = <double>[barTop()];
    for (final inset in [80.0, 160.0, 240.0, 300.0, 300.0]) {
      await keyboard(inset);
      expect(laid(), open, reason: 'açılırken boy kare kare değişmemeli');
      tops.add(barTop());
    }
    // Çubuk eski yerinden yenisine YUMUŞAKÇA kayar (boyama).
    expect(tops.first, greaterThan(open));
    for (var i = 1; i < tops.length; i++) {
      expect(tops[i], lessThanOrEqualTo(tops[i - 1]));
    }
    await tester.pump(const Duration(milliseconds: 400));
    expect(barTop(), open);

    // KAPANIŞ: klavye inerken boy AYNI, çubuk boyamada aşağı kayar.
    await keyboard(280);
    await keyboard(200);
    expect(laid(), open);
    await keyboard(120);
    await keyboard(40);
    expect(laid(), open, reason: 'kapanırken boy klavye bitene dek aynı');
    expect(barTop(), greaterThan(open));
    await tester.pump(const Duration(milliseconds: 400));
    expect(barTop(), 500);
    // BİTTİ: boy tek adımda geri döner, görünen yer değişmez.
    await keyboard(0);
    expect(laid(), 500);
    expect(barTop(), 500);
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.binding.transientCallbackCount, 0);
  });
}
