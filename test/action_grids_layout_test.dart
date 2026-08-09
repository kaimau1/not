import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/note_actions_sheet.dart';
import 'package:notlar/features/notes/presentation/quick_add_fab.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// Not işlem menüsü (⋮ / uzun basış) iki sütunlu, "+" paneli üç sütunlu
/// ızgaradır. Bu testler yerleşimi doğrular: Flutter testlerinde taşma
/// (overflow) hata attığından, sığmayan bir ızgara testi kırar.
void main() {
  Widget host(Widget child) => ProviderScope(
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      locale: const Locale('tr'),
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );

  testWidgets('not işlem menüsü iki sütunlu ızgara olarak açılır', (
    tester,
  ) async {
    const note = Note(id: 'n1', type: NoteType.text, title: 'Kitaplık planı');
    await tester.pumpWidget(
      host(
        Scaffold(
          body: Consumer(
            builder: (context, ref, _) => TextButton(
              onPressed: () => showNoteActionsSheet(context, ref, note),
              child: const Text('aç'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();

    // Başlık + tüm işlemler görünür (eskiden "Sil" kaydırma gerektiriyordu).
    expect(find.text('Kitaplık planı'), findsOneWidget);
    for (final label in ['Sabitle', 'Paylaş', 'Kopyala', 'Seç', 'Sil']) {
      expect(find.text(label), findsOneWidget, reason: '$label görünmeli');
    }

    // İki sütun: "Sabitle" ile "Yıldızla" AYNI satırda, yan yana.
    final pin = tester.getRect(find.text('Sabitle'));
    final star = tester.getRect(find.text('Yıldızla'));
    expect(pin.center.dy, closeTo(star.center.dy, 1));
    expect(pin.center.dx, lessThan(star.center.dx));

    // "Sil" tek başına, alt satırda ve tam genişlikte.
    expect(tester.getRect(find.text('Sil')).center.dy, greaterThan(pin.top));
  });

  testWidgets('"+" paneli YAZ satırları + YAKALA ızgarası olarak açılır', (
    tester,
  ) async {
    final link = LayerLink();
    await tester.pumpWidget(
      host(
        Scaffold(
          body: Align(
            alignment: Alignment.bottomRight,
            child: CompositedTransformTarget(
              link: link,
              child: QuickAddFab(
                anchor: link,
                onCreate: (_) {},
                onHandwriting: () {},
                onVoiceCapture: () {},
                onVideoNote: () {},
                onPhotoNote: () {},
                onScanNote: () {},
                onPdfNote: () {},
                onImageNote: () {},
                onSlidesNote: () {},
                onQrNote: () {},
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // YAZ bölümü de ÜÇ SÜTUNLU IZGARA (kullanıcı isteği 2026-08-09: "metin /
    // liste / sıralı liste de grid kart olsun, altrakiler gibi"): iki bölüm
    // arasında iki ayrı düğme dili vardı.
    final text = tester.getRect(find.text('Metin notu'));
    final list = tester.getRect(find.text('Liste'));
    final ordered = tester.getRect(find.text('Sıralı liste'));
    expect(text.center.dy, closeTo(list.center.dy, 1));
    expect(list.center.dy, closeTo(ordered.center.dy, 1));
    expect(text.center.dx, lessThan(list.center.dx));
    expect(list.center.dx, lessThan(ordered.center.dx));

    // Bölüm başlıkları görünür ve YAKALA, YAZ'ın altındadır.
    expect(find.text('YAZ'), findsOneWidget);
    final capture = tester.getRect(
      find.text('YAKALA — İÇERİKTEN NOT OLUŞTURUR'),
    );
    expect(capture.center.dy, greaterThan(ordered.center.dy));

    // YAKALA ızgarası üç sütun: ilk iki yakalama seçeneği yan yana.
    final voice = tester.getRect(find.text('Sesli not'));
    final photo = tester.getRect(find.text('Foto çek not al'));
    expect(voice.center.dy, closeTo(photo.center.dy, 1));
    expect(voice.center.dx, lessThan(photo.center.dx));
    expect(voice.center.dy, greaterThan(capture.center.dy));

    // Panel ekrandan taşmaz.
    final width = tester.view.physicalSize.width / tester.view.devicePixelRatio;
    expect(text.left, greaterThanOrEqualTo(0));
    expect(photo.right, lessThan(width));
  });
}
