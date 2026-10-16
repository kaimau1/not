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

  testWidgets('"+" paneli: Metin/Liste FAB\'ın hemen üstünde, panel kısa', (
    tester,
  ) async {
    // Kullanıcı bulgusu 2026-10-15: "not ekle menüsü neredeyse tüm ekranı
    // kaplıyor; en çok kullanılan metin notu, liste notu çok yukarıda
    // kalıyor, bulması ve başlatması çok zor".
    final link = LayerLink();
    var youTube = 0;
    final created = <NoteType>[];
    await tester.pumpWidget(
      host(
        Scaffold(
          body: Align(
            alignment: Alignment.bottomRight,
            child: CompositedTransformTarget(
              link: link,
              child: QuickAddFab(
                anchor: link,
                onCreate: created.add,
                onHandwriting: () {},
                onVoiceCapture: () {},
                onVideoNote: () {},
                onPhotoNote: () {},
                onScanNote: () {},
                onPdfNote: () {},
                onImageNote: () {},
                onSlidesNote: () {},
                onQrNote: () {},
                onGalleryVideo: () {},
                onYouTube: () => youTube++,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    final fab = tester.getRect(find.byType(FloatingActionButton).last);
    final text = tester.getRect(find.text('Metin notu'));
    final list = tester.getRect(find.text('Liste'));
    final ordered = tester.getRect(find.text('Sıralı liste'));
    // Birincil üçlü yan yana ve PANELİN EN ALTINDA (FAB'a en yakın).
    expect(text.center.dy, closeTo(list.center.dy, 1));
    expect(list.center.dy, closeTo(ordered.center.dy, 1));
    expect(text.center.dx, lessThan(list.center.dx));
    expect(fab.top - text.bottom, lessThan(60));

    // Kapalı hâlde panel KISA: ekranın yarısından az (eskiden ~%70).
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    final frequent = tester.getRect(find.text('SIK KULLANDIKLARIN'));
    expect(fab.top - frequent.top, lessThan(screen.height / 2));
    // Sık kullanılanlar birincil satırın ÜSTÜNDE; ilk gün sesli not başta.
    expect(
      tester.getRect(find.text('Sesli not')).center.dy,
      lessThan(text.center.dy),
    );
    // Geri kalanı "Tümü" ardında.
    expect(find.text('YouTube videosu'), findsNothing);
    expect(find.text('Foto çek not al'), findsNothing);

    await tester.tap(find.text('Tümü'));
    await tester.pumpAndSettle();
    expect(find.text('ÇEK VE KAYDET'), findsOneWidget);
    expect(find.text('DOSYADAN'), findsOneWidget);
    expect(find.text('Galeriden video'), findsOneWidget);
    // Açılınca da birincil düğmeler yerinde (FAB'ın yanında) kalır.
    expect(
      tester.getRect(find.text('Metin notu')).center.dy,
      closeTo(text.center.dy, 1),
    );

    await tester.ensureVisible(find.text('YouTube videosu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('YouTube videosu'));
    await tester.pumpAndSettle();
    expect(youTube, 1);
    expect(
      find.text('SIK KULLANDIKLARIN'),
      findsNothing,
      reason: 'seçince panel kapanır',
    );

    // Metin notu tek dokunuş.
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Metin notu'));
    await tester.pumpAndSettle();
    expect(created, [NoteType.text]);
  });

  test('sık kullanılanlar sayaca göre, eşitlikte menü sırasıyla', () {
    QuickAddOption o(String key, QuickAddGroup g) =>
        QuickAddOption(key, g, Icons.add, key, () {}, Colors.black);
    final options = [
      o('text', QuickAddGroup.primary),
      o('voice', QuickAddGroup.capture),
      o('photo', QuickAddGroup.capture),
      o('pdf', QuickAddGroup.files),
      o('youtube', QuickAddGroup.files),
    ];
    expect(
      [for (final x in frequentQuickAdd(options, const {}, count: 3)) x.key],
      ['voice', 'photo', 'pdf'],
    );
    expect(
      [
        for (final x in frequentQuickAdd(options, const {
          'youtube': 5,
          'pdf': 2,
          'text': 99,
        }, count: 3))
          x.key,
      ],
      ['youtube', 'pdf', 'voice'],
      reason: 'birincil (metin) zaten altta — sık kullanılanlara girmez',
    );
  });
}
