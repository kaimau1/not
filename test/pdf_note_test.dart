import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/domain/page_notes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notlar/features/notes/presentation/editor/pdf_note_pane.dart';
import 'package:notlar/features/notes/presentation/editor/slide_note_pane.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// "PDF ekle not al" not tipi: PDF notun İÇİNE gömülü, ekran iki bölme —
/// ÜSTTE sayfa, ALTTA O SAYFANIN notu (2026-08-07 / 9. tur kararları).
///
/// Burada kilitlenen davranışlar:
///  1. Not PER SAYFA tutulur; sayfa çevrilince alandaki not da değişir.
///  2. Sayfa notu SAYFA KİMLİĞİNE bağlanır, sayfa NUMARASINA değil — sayfa
///     silme/sıralama geldiğinde notlar kaymasın.
///  3. Silinen sayfa notu boş dizgi olarak KALIR (Firestore merge tuzağı).
///  4. Yeni tip eski sürümü kırmaz: bilinmeyen tip düz metne düşer.
void main() {
  Attachment pdf({String id = 'a1', List<String> pageIds = const []}) =>
      Attachment(
        id: id,
        kind: AttachmentKind.pdf,
        fileName: 'ders.pdf',
        mimeType: 'application/pdf',
        pageIds: pageIds,
      );

  group('not tipi', () {
    test('pdf ve slides kimlikleri çözülür', () {
      expect(NoteType.fromId('pdf'), NoteType.pdf);
      expect(NoteType.fromId('slides'), NoteType.slides);
    });

    test('bilinmeyen tip düz metne düşer — eski sürümde not kaybolmaz', () {
      expect(NoteType.fromId('mindmap'), NoteType.text);
      expect(NoteType.fromId(null), NoteType.text);
    });

    test('belge tipleri sayfa notu tutar, diğerleri tutmaz', () {
      // İkisi de aynı veri modelini ve aynı iki bölmeli ekranı kullanır;
      // editör dalı bu bayrağa bakar.
      expect(NoteType.pdf.isPageNoteType, isTrue);
      expect(NoteType.slides.isPageNoteType, isTrue);
      expect(NoteType.text.isPageNoteType, isFalse);
      expect(NoteType.checklist.isPageNoteType, isFalse);
      expect(NoteType.ordered.isPageNoteType, isFalse);
    });
  });

  group('sayfa kimliği', () {
    test('kimlik atanmamış ekte numaradan türetilir', () {
      expect(pageIdFor(pdf(), 3), 'p3');
      expect(pageNoteKey(pdf(), 3), 'a1#p3');
    });

    test('kimlik atanmış ekte listeden okunur', () {
      final a = pdf(pageIds: ['x', 'y', 'z']);
      expect(pageIdFor(a, 2), 'y');
      expect(pageNoteKey(a, 2), 'a1#y');
    });

    test('sayfa sıralanınca notlar sayfayla BİRLİKTE taşınır', () {
      // 1-2-3 iken 3. sayfaya yazılan not, sayfalar 3-1-2 sırasına
      // getirildiğinde artık 1. sayfanın notudur — anahtar değişmez.
      final before = pdf(pageIds: ['x', 'y', 'z']);
      final after = pdf(pageIds: ['z', 'x', 'y']);
      final key = pageNoteKey(before, 3);
      expect(key, 'a1#z');
      expect(pageNoteKey(after, 1), key);
    });

    test('silinen sayfanın kimliği numaraya ÇEVRİLMEZ', () {
      // Kimlik listesi varken listede olmayan kimlik = silinmiş sayfa.
      // Numaraya çevrilseydi o notun içeriği başka bir sayfanın üstüne düşerdi.
      final a = pdf(pageIds: ['x', 'z']);
      expect(pageNumberOfId(a, 'y'), isNull);
      expect(pageNumberOfId(a, 'p2'), isNull);
      expect(pageNumberOfId(a, 'z'), 2);
    });
  });

  group('Note.pageNotes', () {
    final attachment = pdf();
    final note = Note(id: 'n1', type: NoteType.pdf, attachments: [attachment]);

    test('sayfa notu yazılır ve aynı sayfadan okunur', () {
      final next = note.withPageNote(attachment, 3, 'üçüncü sayfa');
      expect(next.pageNote(attachment, 3), 'üçüncü sayfa');
      expect(next.pageNote(attachment, 4), '');
      expect(next.pageNotes, {'a1#p3': 'üçüncü sayfa'});
    });

    test('silinen not BOŞ DİZGİ olarak kalır, anahtar düşmez', () {
      // KÖK NEDEN: belgeler `set(merge: true)` ile yazılıyor ve merge
      // haritaları derin birleştirir; anahtar haritadan çıkarılsaydı
      // Firestore'daki eski değer kalır, silinen not geri gelirdi.
      final written = note.withPageNote(attachment, 2, 'silinecek');
      final cleared = written.withPageNote(attachment, 2, '');
      expect(cleared.pageNotes.containsKey('a1#p2'), isTrue);
      expect(cleared.pageNotes['a1#p2'], '');
      expect(cleared.pageNote(attachment, 2), '');
    });

    test('iki farklı belgenin aynı numaralı sayfaları karışmaz', () {
      final other = pdf(id: 'a2');
      final next = note
          .withPageNote(attachment, 1, 'birinci belge')
          .withPageNote(other, 1, 'ikinci belge');
      expect(next.pageNote(attachment, 1), 'birinci belge');
      expect(next.pageNote(other, 1), 'ikinci belge');
    });

    test('sayfa notu olan not BOŞ sayılmaz (temizlik silmesin)', () {
      // Ek YOK: notu boşluktan çıkaran tek şey sayfa notunun kendisi olsun.
      // (Belge silinip notlar kalabilir; arka plan temizliği onları silmemeli.)
      const bare = Note(id: 'n1', type: NoteType.pdf);
      expect(bare.isEmpty, isTrue);
      final written = bare.withPageNote(attachment, 1, 'not');
      expect(written.isEmpty, isFalse);
      // `hasPageNotes` ile `isEmpty` BİLEREK farklı sorular soruyor:
      // birincisi "GÖSTERİLECEK not var mı" (yalnız mevcut eklerinki),
      // ikincisi "sessizce silinebilir mi" (hiçbir yazı yoksa). Belgesi
      // silinmiş bir notun yazıları gösterilmez ama temizlik de onu yok
      // edemez — kullanıcı listeden kendisi siler.
      expect(written.hasPageNotes, isFalse);
      expect(written.copyWith(attachments: [attachment]).hasPageNotes, isTrue);
      // Yalnız boş dizgiler kaldıysa not yine boştur.
      expect(written.withPageNote(attachment, 1, '').isEmpty, isTrue);
    });

    test('toMap: boşken alan hiç yazılmaz, doluyken harita olarak yazılır', () {
      expect(note.toMap().containsKey('pageNotes'), isFalse);
      final written = note.withPageNote(attachment, 1, 'not');
      expect(written.toMap()['pageNotes'], isA<Map<String, String>>());
      expect(written.toMap()['pageNotes'], {'a1#p1': 'not'});
    });
  });

  group('orderedPageNotes', () {
    test('sayfa sırasına dizer, boşları eler', () {
      final a = pdf();
      final notes = {'a1#p3': 'üç', 'a1#p1': 'bir', 'a1#p2': '  '};
      final ordered = orderedPageNotes(attachment: a, pageNotes: notes);
      expect(ordered.map((e) => e.page).toList(), [1, 3]);
      expect(ordered.first.text, 'bir');
    });

    test('başka ekin notlarını almaz', () {
      final ordered = orderedPageNotes(
        attachment: pdf(),
        pageNotes: {'a2#p1': 'öteki'},
      );
      expect(ordered, isEmpty);
    });

    test('toPlainText sayfa numarasını korur', () {
      final a = pdf();
      final note = Note(
        id: 'n1',
        type: NoteType.pdf,
        title: 'Ders',
        attachments: [a],
        pageNotes: const {'a1#p2': 'ikinci', 'a1#p1': 'birinci'},
      );
      expect(note.toPlainText(), 'Ders\n#1\nbirinci\n#2\nikinci');
    });
  });

  group('PdfNotePane', () {
    /// Belgesi cihazda da bulutta da olmayan ek: görüntüleyici kurulmaz ama
    /// sayfa çubuğu ve not alanı çalışmalı (kullanıcı senkronu beklemeden
    /// notunu yazabilsin).
    Future<void> pump(
      WidgetTester tester, {
      required Note Function() noteOf,
      required Attachment attachment,
      required void Function(int page, String text) onChanged,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: PdfNotePane(
              noteOf: noteOf,
              attachment: attachment,
              onPageNoteChanged: onChanged,
              onAttachmentChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('sayfa çevrilince ALT BÖLME o sayfanın notunu gösterir', (
      tester,
    ) async {
      final attachment = pdf();
      var note = Note(
        id: 'n1',
        type: NoteType.pdf,
        attachments: [attachment],
        pageNotes: const {'a1#p1': 'birinci sayfa', 'a1#p2': 'ikinci sayfa'},
      );
      await pump(
        tester,
        noteOf: () => note,
        attachment: attachment,
        onChanged: (page, text) =>
            note = note.withPageNote(attachment, page, text),
      );

      expect(find.text('birinci sayfa'), findsOneWidget);
      expect(find.text('Sayfa 1'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pump();

      // Alt bölmenin YERİ sabit, İÇERİĞİ sayfayla değişir.
      expect(find.text('ikinci sayfa'), findsOneWidget);
      expect(find.text('birinci sayfa'), findsNothing);
      expect(find.text('Sayfa 2'), findsOneWidget);
    });

    testWidgets('yazılan metin O ANKİ sayfaya gider, sonraki sayfaya taşmaz', (
      tester,
    ) async {
      final attachment = pdf();
      var note = Note(id: 'n1', type: NoteType.pdf, attachments: [attachment]);
      await pump(
        tester,
        noteOf: () => note,
        attachment: attachment,
        onChanged: (page, text) =>
            note = note.withPageNote(attachment, page, text),
      );

      await tester.enterText(find.byType(TextField), 'birinci not');
      await tester.pump();
      expect(note.pageNote(attachment, 1), 'birinci not');

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'ikinci not');
      await tester.pump();

      // KÖK NEDEN kilidi: sayfa değişiminde ÖNCE eski sayfanın notu
      // kesinleşir. Ters sırada son tuş vuruşları yeni sayfaya yapışırdı.
      expect(note.pageNote(attachment, 1), 'birinci not');
      expect(note.pageNote(attachment, 2), 'ikinci not');
    });

    testWidgets('toplu görünüm açılır, başlığa dokunmak o sayfaya götürür', (
      tester,
    ) async {
      final attachment = pdf();
      var note = Note(
        id: 'n1',
        type: NoteType.pdf,
        attachments: [attachment],
        pageNotes: const {'a1#p1': 'birinci sayfa', 'a1#p4': 'dorduncu sayfa'},
      );
      await pump(
        tester,
        noteOf: () => note,
        attachment: attachment,
        onChanged: (page, text) =>
            note = note.withPageNote(attachment, page, text),
      );

      await tester.tap(find.byIcon(Icons.subject));
      await tester.pumpAndSettle();

      // Tek akış: notu OLAN sayfalar, sayfa numarası başlıklı, sırayla.
      expect(find.text('Tüm sayfa notları'), findsOneWidget);
      expect(find.text('Sayfa 1'), findsOneWidget);
      expect(find.text('Sayfa 4'), findsOneWidget);
      expect(find.text('birinci sayfa'), findsOneWidget);
      expect(find.text('dorduncu sayfa'), findsOneWidget);

      await tester.tap(find.text('Sayfa 4'));
      await tester.pumpAndSettle();

      // Pano dönen sayfaya gitti ve alt bölme o sayfanın notunu gösteriyor.
      expect(find.text('Sayfa 4'), findsOneWidget);
      expect(find.text('dorduncu sayfa'), findsOneWidget);
      expect(find.text('birinci sayfa'), findsNothing);
    });

    testWidgets('toplu görünümde düzenlenen not doğru sayfaya yazılır', (
      tester,
    ) async {
      final attachment = pdf();
      var note = Note(
        id: 'n1',
        type: NoteType.pdf,
        attachments: [attachment],
        pageNotes: const {'a1#p1': 'bir', 'a1#p3': 'uc'},
      );
      await pump(
        tester,
        noteOf: () => note,
        attachment: attachment,
        onChanged: (page, text) =>
            note = note.withPageNote(attachment, page, text),
      );

      await tester.tap(find.byIcon(Icons.subject));
      await tester.pumpAndSettle();

      await tester.enterText(find.text('uc'), 'uc duzeltildi');
      await tester.pump();

      expect(note.pageNote(attachment, 3), 'uc duzeltildi');
      expect(note.pageNote(attachment, 1), 'bir');
    });

    testWidgets('sayfa notu yokken toplu görünüm boş durumu gösterir', (
      tester,
    ) async {
      final attachment = pdf();
      await pump(
        tester,
        noteOf: () =>
            Note(id: 'n1', type: NoteType.pdf, attachments: [attachment]),
        attachment: attachment,
        onChanged: (_, _) {},
      );
      await tester.tap(find.byIcon(Icons.subject));
      await tester.pumpAndSettle();
      expect(find.textContaining('Henüz sayfa notu yok'), findsOneWidget);
    });

    testWidgets('ilk sayfada "önceki" düğmesi pasiftir', (tester) async {
      final attachment = pdf();
      await pump(
        tester,
        noteOf: () =>
            Note(id: 'n1', type: NoteType.pdf, attachments: [attachment]),
        attachment: attachment,
        onChanged: (_, _) {},
      );
      final back = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.chevron_left),
          matching: find.byType(IconButton),
        ),
      );
      expect(back.onPressed, isNull);
    });
  });

  group('SlideNotePane', () {
    Attachment slide({String id = 'a1'}) => Attachment(
      id: id,
      kind: AttachmentKind.slide,
      fileName: 'sunum.pptx',
      mimeType:
          'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    );

    /// Sunum baytları OKUNAMAZ (ek deposu yok): üst bölme "açılamadı" der ama
    /// not tarafı çalışmalı — PDF sürümündeki kuralın aynısı.
    Future<void> pump(
      WidgetTester tester, {
      required Note Function() noteOf,
      required Attachment attachment,
      required void Function(int page, String text) onChanged,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            locale: const Locale('tr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SlideNotePane(
                noteOf: noteOf,
                attachment: attachment,
                onPageNoteChanged: onChanged,
                onAttachmentChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('slayt notu PDF ile AYNI veri modelini kullanır', (
      tester,
    ) async {
      final attachment = slide();
      var note = Note(
        id: 'n1',
        type: NoteType.slides,
        attachments: [attachment],
        pageNotes: const {'a1#p1': 'birinci slayt', 'a1#p2': 'ikinci slayt'},
      );
      await pump(
        tester,
        noteOf: () => note,
        attachment: attachment,
        onChanged: (page, text) =>
            note = note.withPageNote(attachment, page, text),
      );

      expect(find.text('birinci slayt'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pump();

      // Alt bölmenin YERİ sabit, İÇERİĞİ slaytla değişir.
      expect(find.text('ikinci slayt'), findsOneWidget);
      expect(find.text('birinci slayt'), findsNothing);

      await tester.enterText(find.byType(TextField), 'duzeltildi');
      await tester.pump();
      expect(note.pageNote(attachment, 2), 'duzeltildi');
      expect(note.pageNote(attachment, 1), 'birinci slayt');
    });

    testWidgets('toplu görünüm slaytlarda da açılır', (tester) async {
      final attachment = slide();
      var note = Note(
        id: 'n1',
        type: NoteType.slides,
        attachments: [attachment],
        pageNotes: const {'a1#p3': 'ucuncu slayt'},
      );
      await pump(
        tester,
        noteOf: () => note,
        attachment: attachment,
        onChanged: (page, text) =>
            note = note.withPageNote(attachment, page, text),
      );
      await tester.tap(find.byIcon(Icons.subject));
      await tester.pumpAndSettle();
      expect(find.text('Sayfa 3'), findsOneWidget);
      expect(find.text('ucuncu slayt'), findsOneWidget);
    });
  });
}
