import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/app/app.dart';

/// YAZI BOYUTU VE YAZI TİPİ HER TELEFONDA AYNI (kullanıcı isteği 2026-08-07:
/// "yazı boyutu ve fontumuz tüm telefonlarda sabit olmalı sadece uygulama
/// içerisinden değiştirilebilmeli").
///
/// İki ayrı kaynak var, ikisi de burada kilitleniyor:
///  - Sistemin yazı ölçeği / "kalın metin" ayarı → [fixedTypography] bunları
///    uygulamanın kendi değerleriyle DEĞİŞTİRİR.
///  - Yazı tipi → Inter Tight APK'ya gömülü; `google_fonts` dosyayı
///    varlıklarda bulamazsa ağdan indirmeye çalışır ve indiremediğinde metin
///    CİHAZIN fontuyla çizilir (telefondan telefona değişen görünüm).
void main() {
  Future<MediaQueryData> pump(
    WidgetTester tester, {
    required MediaQueryData system,
    required double fontScale,
  }) async {
    late MediaQueryData inner;
    await tester.pumpWidget(
      MediaQuery(
        data: system,
        child: Builder(
          builder: (context) => fixedTypography(
            context,
            Builder(
              builder: (inner_) {
                inner = MediaQuery.of(inner_);
                return const SizedBox.shrink();
              },
            ),
            fontScale,
          ),
        ),
      ),
    );
    return inner;
  }

  testWidgets('sistem yazı ölçeği yok sayılır, uygulamanınki geçer', (
    tester,
  ) async {
    final data = await pump(
      tester,
      // Telefonun "en büyük yazı" ayarı.
      system: const MediaQueryData(textScaler: TextScaler.linear(2.5)),
      fontScale: 1,
    );
    // ÇARPILMAZ: sonuç 2.5 değil, uygulamanın kendi ölçeği.
    expect(data.textScaler.scale(10), 10);
  });

  testWidgets('uygulama içi yazı boyutu tek söz sahibi', (tester) async {
    final data = await pump(
      tester,
      system: const MediaQueryData(textScaler: TextScaler.linear(0.5)),
      fontScale: 1.4,
    );
    expect(data.textScaler.scale(10), closeTo(14, 0.001));
  });

  testWidgets('sistemin "kalın metin" ayarı uygulamayı kalınlaştırmaz', (
    tester,
  ) async {
    final data = await pump(
      tester,
      system: const MediaQueryData(boldText: true),
      fontScale: 1,
    );
    expect(data.boldText, isFalse);
  });

  test('Inter Tight dosyaları gömülü ve pubspec\'te bildirilmiş', () {
    // Dosya adı `google_fonts`un aradığı kalıpta olmak ZORUNDA
    // (`InterTight-<Ağırlık>.ttf`); adı değişirse paket sessizce indirmeye
    // döner ve çevrimdışı cihazda sistem fontuna düşer.
    final pubspec = File('pubspec.yaml').readAsStringSync();
    for (final weight in const ['Regular', 'Medium']) {
      final path = 'assets/google_fonts/InterTight-$weight.ttf';
      expect(File(path).existsSync(), isTrue, reason: '$path yok');
      expect(
        pubspec,
        contains(path),
        reason: '$path pubspec varlıklarında yok',
      );
    }
  });
}
