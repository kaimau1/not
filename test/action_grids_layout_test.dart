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

  testWidgets('"+" paneli üç sütunlu büyük düğmelerle açılır', (tester) async {
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
                onQrNote: () {},
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Üç sütun: metin / liste / sıralı liste ilk satırda yan yana durur.
    final text = tester.getRect(find.text('Metin notu'));
    final list = tester.getRect(find.text('Liste'));
    final ordered = tester.getRect(find.text('Sıralı liste'));
    expect(text.center.dy, closeTo(list.center.dy, 1));
    expect(list.center.dy, closeTo(ordered.center.dy, 1));
    expect(text.center.dx, lessThan(list.center.dx));
    expect(list.center.dx, lessThan(ordered.center.dx));

    // Dördüncü seçenek bir alt satıra iner (3 sütun, tek satır değil).
    expect(
      tester.getRect(find.text('Sesli not')).center.dy,
      greaterThan(text.center.dy),
    );

    // Panel ekrandan taşmaz.
    final width = tester.view.physicalSize.width / tester.view.devicePixelRatio;
    expect(text.left, greaterThanOrEqualTo(0));
    expect(tester.getRect(find.text('Sıralı liste')).right, lessThan(width));
  });
}
