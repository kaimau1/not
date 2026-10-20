import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:notlar/features/notes/presentation/editor/note_images.dart';

/// Not sayfasındaki görsel tuvalinin YERLEŞİMİ.
///
/// KÖK NEDEN (kullanıcı 2026-09-05: "birden fazla görsel eklendiğinde üst üste
/// başlıyor"): konumu yazılmamış görsellerin yeri `topLimit`e kırpılıyordu ve
/// başlığın altına düşen bütün görseller aynı çizgiye çöküyordu. Bu takım o
/// çökmeyi ve satırın sağındaki boşluğun kullanılmamasını kilitler.
void main() {
  Attachment image(String id, {int w = 100, int h = 100}) => Attachment(
    id: id,
    kind: AttachmentKind.image,
    fileName: '$id.jpg',
    mimeType: 'image/jpeg',
    width: w,
    height: h,
  );

  Future<void> pumpCanvas(
    WidgetTester tester,
    List<Attachment> images, {
    double topLimit = 0,
    ValueChanged<List<Attachment>>? onChangedMany,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 800,
            child: NotePageCanvas(
              images: images,
              minHeight: 800,
              topLimit: topLimit,
              onRemove: (_) {},
              onChanged: (_) {},
              onChangedMany: onChangedMany,
              onCopyMany: (_) {},
              child: const SizedBox(width: 400, height: 400),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Rect boxOf(WidgetTester tester, String id) =>
      tester.getRect(find.byKey(ValueKey('page-image-$id')));

  /// Görsele TEK dokunuş. Kutuda çift dokunuş tanıyıcısı da var (büyük
  /// önizleme): tek dokunuşun kararı ancak çift dokunuş süresi dolunca
  /// verilir, o yüzden saat ilerletilir.
  Future<void> tapImage(WidgetTester tester, String id) async {
    await tester.tap(find.byKey(ValueKey('page-image-$id')));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  }

  testWidgets('konumsuz iki görsel yan yana durur, üst üste binmez', (
    tester,
  ) async {
    await pumpCanvas(tester, [image('a'), image('b')]);
    final a = boxOf(tester, 'a');
    final b = boxOf(tester, 'b');
    expect(a.overlaps(b), isFalse);
    // Aynı satırda: ikincisi birincinin SAĞINDA.
    expect(b.top, a.top);
    expect(b.left, greaterThan(a.left));
  });

  testWidgets('başlık bandı yüksekken bile görseller çakışmaz', (tester) async {
    // Asıl bug: 8 dp'den başlayan yığın topLimit'e kırpılınca hepsi aynı
    // noktaya biniyordu. Yatık (geniş) görsellerde ikinci görselin yığındaki
    // yeri de topLimit'in üstünde kalıyordu.
    await pumpCanvas(tester, [
      image('a', w: 200),
      image('b', w: 200),
      image('c', w: 200),
    ], topLimit: 160);
    final boxes = [
      boxOf(tester, 'a'),
      boxOf(tester, 'b'),
      boxOf(tester, 'c'),
    ];
    for (final box in boxes) {
      expect(box.top, greaterThanOrEqualTo(160));
    }
    for (var i = 0; i < boxes.length; i++) {
      for (var j = i + 1; j < boxes.length; j++) {
        expect(
          boxes[i].overlaps(boxes[j]),
          isFalse,
          reason: '$i ve $j çakıştı: ${boxes[i]} / ${boxes[j]}',
        );
      }
    }
  });

  testWidgets('elle yerleştirilmiş görselin üstüne otomatik yerleşim binmez', (
    tester,
  ) async {
    final placed = image('yerlesik').copyWith(x: 0, pageY: 0, displayWidth: 0.5);
    await pumpCanvas(tester, [placed, image('yeni')]);
    expect(boxOf(tester, 'yerlesik').overlaps(boxOf(tester, 'yeni')), isFalse);
  });

  testWidgets('konumu yazılı görsel oranlarının verdiği yerde durur', (
    tester,
  ) async {
    final fixed = image('sabit').copyWith(x: 0.25, pageY: 120, displayWidth: 0.5);
    await pumpCanvas(tester, [fixed]);
    final box = boxOf(tester, 'sabit');
    expect(box.left, closeTo(100, 0.5));
    expect(box.top, closeTo(120, 0.5));
    expect(box.width, closeTo(200, 0.5));
  });

  testWidgets('çoklu seçimde "satıra sığdır" görselleri sayfaya yayar', (
    tester,
  ) async {
    // Kullanıcı isteği: "görselleri seçip sığdır deyince kenarlarını
    // yapıştırarak, sağ kenara da yapışacak şekilde muntazam sığdırsın".
    List<Attachment>? applied;
    final images = [image('a'), image('b'), image('c')];
    await pumpCanvas(tester, images, onChangedMany: (v) => applied = v);

    // Bir görseli seç → araç panelinin ⋮ menüsünden çoklu seçimi aç.
    await tapImage(tester, 'a');
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Görselleri seç'));
    await tester.pumpAndSettle();
    // Kalan ikisini de işaretle.
    await tapImage(tester, 'b');
    await tapImage(tester, 'c');
    await tester.tap(find.byIcon(Icons.view_column_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3 sütun'));
    await tester.pumpAndSettle();

    expect(applied, isNotNull);
    expect(applied!.length, 3);
    var left = 0.0;
    for (final a in applied!) {
      expect(a.displayWidth, closeTo(1 / 3, 0.0001));
      expect(a.x, closeTo(left, 0.0001));
      left += a.displayWidth!;
      // Hepsi aynı satırda.
      expect(a.pageY, applied!.first.pageY);
    }
    // Son görselin sağ kenarı sayfanın sağ kenarına yapışır.
    expect(left, closeTo(1, 0.0001));
  });

  testWidgets('çoklu seçimde "boyutları eşitle" ortak genişlik yazar', (
    tester,
  ) async {
    List<Attachment>? applied;
    final images = [
      image('a').copyWith(x: 0, pageY: 0, displayWidth: 0.2),
      image('b').copyWith(x: 0.5, pageY: 300, displayWidth: 0.4),
    ];
    await pumpCanvas(tester, images, onChangedMany: (v) => applied = v);

    await tapImage(tester, 'a');
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Görselleri seç'));
    await tester.pumpAndSettle();
    await tapImage(tester, 'b');
    await tester.tap(find.byIcon(Icons.straighten));
    await tester.pumpAndSettle();

    expect(applied, isNotNull);
    expect(applied!.length, 2);
    for (final a in applied!) {
      expect(a.displayWidth, closeTo(0.3, 0.0001));
    }
  });

  testWidgets('sığdırma SÜTUN SAYISI seçilebilir: 2 sütun → 3 satır', (
    tester,
  ) async {
    // Kullanıcı geri bildirimi 2026-09-05: "hep 3 sütunlu yapıyor, 2 sütunlu
    // da olmalı". Altı görsel 2 sütun seçilince 2 + 2 + 2 dizilmeli.
    List<Attachment>? applied;
    final images = [for (final id in 'abcdef'.split('')) image(id)];
    await pumpCanvas(tester, images, onChangedMany: (v) => applied = v);

    await tapImage(tester, 'a');
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Görselleri seç'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.select_all));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.view_column_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2 sütun'));
    await tester.pumpAndSettle();

    expect(applied, isNotNull);
    expect(applied!.length, 6);
    for (final a in applied!) {
      expect(a.displayWidth, closeTo(0.5, 0.0001));
    }
    // Üç ayrı satır, her satırda iki görsel.
    final rows = applied!.map((a) => a.pageY).toSet();
    expect(rows.length, 3);
    expect(applied![0].x, closeTo(0, 0.0001));
    expect(applied![1].x, closeTo(0.5, 0.0001));
    expect(applied![1].pageY, applied![0].pageY);
    expect(applied![2].pageY, isNot(applied![0].pageY));
  });

  testWidgets('"tek satıra sığdır" seçimi tek satırda dizer', (tester) async {
    List<Attachment>? applied;
    final images = [for (final id in 'abcd'.split('')) image(id)];
    await pumpCanvas(tester, images, onChangedMany: (v) => applied = v);

    await tapImage(tester, 'a');
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Görselleri seç'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.select_all));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.view_column_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tek satıra sığdır'));
    await tester.pumpAndSettle();

    expect(applied!.length, 4);
    for (final a in applied!) {
      expect(a.displayWidth, closeTo(0.25, 0.0001));
      expect(a.pageY, applied!.first.pageY);
    }
  });

  testWidgets('görsel seçimi ANINDA olur (çift dokunuş beklenmez)', (
    tester,
  ) async {
    // KÖK NEDEN (kullanıcı 2026-09-05: "görselleri seçerken gecikme var"):
    // seçili olmayan görselde çift dokunuş tanıyıcısı kayıtlıyken tek
    // dokunuşun kararı ~300 ms bekliyordu. Artık tanıyıcı yalnız SEÇİLİ
    // görselde kurulur.
    await pumpCanvas(tester, [image('a'), image('b')]);
    await tester.tap(find.byKey(const ValueKey('page-image-a')));
    // Saat İLERLETİLMEDEN tek kare: araç paneli çıkmış olmalı.
    await tester.pump();
    expect(find.byType(Slider), findsOneWidget);
  });

  testWidgets('çoklu seçim çubuğu DAR ekrana sığar (taşma yok)', (
    tester,
  ) async {
    // Çubuk yedi denetim taşıyor (kapat, sayaç, tümünü seç, eşitle, sığdır,
    // kopyala, sil). 360 dp'lik bir telefonda taşarsa Flutter sarı-siyah
    // şerit çizer; test taşmayı istisna olarak yakalar.
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final images = [for (final id in 'abcdef'.split('')) image(id)];
    await pumpCanvas(tester, images);
    await tapImage(tester, 'a');
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Görselleri seç'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.select_all));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.view_column_outlined), findsOneWidget);
  });

  testWidgets('paylaşımdan gelen altı konumsuz görsel 3\u00d72 ızgara olur', (
    tester,
  ) async {
    // Paylaşım yolunda ekler konumsuz ve genişliksiz geliyor (bkz.
    // share_intake): tuval hepsini kendisi diziyor. Beş ve üzerinde satıra
    // üç görsel sığar.
    final images = [for (final id in 'abcdef'.split('')) image(id)];
    await pumpCanvas(tester, images);
    final boxes = {for (final a in images) a.id: boxOf(tester, a.id)};
    // Çakışma yok.
    final ids = images.map((a) => a.id).toList();
    for (var i = 0; i < ids.length; i++) {
      for (var j = i + 1; j < ids.length; j++) {
        expect(boxes[ids[i]]!.overlaps(boxes[ids[j]]!), isFalse);
      }
    }
    // İki satır, her satırda üç görsel.
    final rows = boxes.values.map((r) => r.top).toSet();
    expect(rows.length, 2);
    for (final top in rows) {
      expect(boxes.values.where((r) => r.top == top).length, 3);
    }
  });
}
