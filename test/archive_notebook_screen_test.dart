import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/rich_text.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/archive_paper.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/archive_note_screen.dart';
import 'package:notlar/features/notes/presentation/editor/format_bar.dart';
import 'package:notlar/features/notes/presentation/editor/note_images.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// **DEFTERİN EKRANI** (kullanıcı isteği 2026-09-01: "metin yazamıyorum,
/// yazmak için bu alan açılıyor — direk sayfaya yazılabilmeli… sayfa
/// geçişinde yeni sayfa ekle çıkmadan oto geçiş olmalı").
///
/// Kayıt katmanı (Firestore) testte yok: `notesRepositoryProvider` null'a
/// çekiliyor, yani yazma yolları sessizce boşa çıkıyor. Buradaki soru
/// zaten yazmanın KAYDI değil (onu `archiveWriteText` testleri ölçüyor),
/// ekranda YAZILABİLİR bir sayfa olup olmadığı.
void main() {
  /// Sayfanın YAZI ALANI. `find.byType(TextField).first` yetmiyor: başlık
  /// çubuğunda defterin adı, sayfanın tepesinde de sayfa başlığı birer
  /// alan — "ilk alan" 2026-09-04'ten beri defterin ADI.
  final pageWriter = find.descendant(
    of: find.byType(NotePageCanvas),
    matching: find.byType(TextField),
  );

  Future<void> pumpNotebook(WidgetTester tester, Note note) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notesRepositoryProvider.overrideWith((ref) => null),
          noteStreamProvider(note.id).overrideWith((ref) => Stream.value(note)),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('tr'),
          home: ArchiveNoteScreen(noteId: note.id),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Note notebook({
    List<String> pages = const [],
    List<NoteItem> items = const [],
    List<Attachment> attachments = const [],
    ArchivePaper paper = ArchivePaper.lined,
  }) => Note(
    id: 'n1',
    type: NoteType.archive,
    title: 'Defter',
    archivePages: pages,
    archivePaper: paper,
    items: items,
    attachments: attachments,
  );

  testWidgets('sayfanın kendisi bir yazı alanıdır (diyalog yok)', (
    tester,
  ) async {
    await pumpNotebook(tester, notebook());

    // Açık sayfada doğrudan yazılabilen bir alan var ve ipucu onu söylüyor.
    expect(find.text('Bu sayfaya yaz…'), findsOneWidget);
    await tester.enterText(pageWriter, 'ilk cümle');
    await tester.pump();
    expect(find.text('ilk cümle'), findsOneWidget);
    // Yazmak için hiçbir diyalog açılmadı.
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('var olan yazı sayfada AÇIK gelir (okumak için dokunmak yok)', (
    tester,
  ) async {
    await pumpNotebook(
      tester,
      notebook(
        items: const [NoteItem(id: 'w', text: 'eski yazı')],
      ),
    );
    expect(find.text('eski yazı'), findsOneWidget);
  });

  testWidgets('defterin sonunda BOŞ YAPRAK var — ileri ok onu açar', (
    tester,
  ) async {
    await pumpNotebook(tester, notebook(pages: ['Faturalar']));

    // Genel + Faturalar + boş yaprak: ileri ok son sayfada da etkin.
    expect(find.text('Genel'), findsWidgets);
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();
    expect(find.text('Faturalar'), findsWidgets);

    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();
    // Boş yaprak: adı hazır ("Sayfa 3"), ama sayfa daha kayda geçmedi —
    // "yeni sayfa ekle" diyalogu da açılmadı.
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Sayfa 3'), findsWidgets);

    // Yapraktan sonrası yok: ileri ok artık kapalı.
    final next = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.chevron_right),
        matching: find.byType(IconButton),
      ),
    );
    expect(next.onPressed, isNull);
  });

  testWidgets('HER sayfanın başlığı yerinde düzenlenir (ilk sayfa dahil)', (
    tester,
  ) async {
    // Kullanıcı isteği 2026-09-02: "sayfa başlığını direk üzerine tıklayarak
    // yazıp değiştirebilmeliyim". Eskiden ilk sayfanın başlığı düz yazıydı.
    await pumpNotebook(tester, notebook(pages: ['Faturalar']));
    // DEFTERİN adı (başlık çubuğu) + sayfa başlığı + yazı alanı: üç alan.
    // Defterin adı 2026-09-04'te eklendi (kullanıcı isteği: "ana sayfada
    // başlık hep arşiv defteri oluyor, değiştirilebilir olmalı").
    expect(find.byType(TextField), findsNWidgets(3));
    expect(find.text('Genel'), findsWidgets);

    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNWidgets(3));
    expect(find.text('Faturalar'), findsWidgets);
  });

  testWidgets('ilk sayfanın adı kullanıcının verdiği addır', (tester) async {
    final note = notebook().copyWith(archiveGeneralName: 'Günlük');
    await pumpNotebook(tester, note);
    expect(find.text('Günlük'), findsWidgets);
    expect(find.text('Genel'), findsNothing);
  });

  testWidgets('"Yeni sayfa" sayfayı GERÇEKTEN açar (yazmadan da)', (
    tester,
  ) async {
    // KÖK NEDEN (kullanıcı bulgusu 2026-09-04: "sadece 2 sayfa
    // açabiliyorum, sayfaya bir şey yazmazsam sayfa oluşmuyor, yeni sayfa
    // desem bile açılmıyor"): komut sayfayı AÇMIYOR, yalnız defterin
    // sonundaki boş yaprağa gidiyordu — hiçbir görünür etkisi olmadan.
    final saved = <Note>[];
    final note = notebook();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notesRepositoryProvider.overrideWith(
            (ref) => _RecordingRepo(saved.add),
          ),
          noteStreamProvider(note.id).overrideWith((ref) => Stream.value(note)),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('tr'),
          home: ArchiveNoteScreen(noteId: note.id),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yeni sayfa'));
    await tester.pumpAndSettle();
    // Şablon levhası (2026-09-23): boş sayfa eski davranış.
    await tester.tap(find.text('Boş sayfa'));
    await tester.pumpAndSettle();

    expect(saved, isNotEmpty);
    expect(saved.last.archivePages, ['Sayfa 2']);
  });

  testWidgets('şablonla açılan sayfa şablonun ADINI ve yazısını taşır', (
    tester,
  ) async {
    final saved = <Note>[];
    final note = notebook();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notesRepositoryProvider.overrideWith(
            (ref) => _RecordingRepo(saved.add),
          ),
          noteStreamProvider(note.id).overrideWith((ref) => Stream.value(note)),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('tr'),
          home: ArchiveNoteScreen(noteId: note.id),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yeni sayfa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Toplantı'));
    await tester.pumpAndSettle();

    expect(saved.last.archivePages, ['Toplantı']);
    final writing = archivePageText(saved.last, 'Toplantı');
    expect(writing, isNotNull);
    expect(stripRichMarkers(writing!.text), contains('Gündem'));
  });

  testWidgets('SAYFA GENEL BAKIŞI ızgarada bütün yaprakları gösterir', (
    tester,
  ) async {
    // Kullanıcı isteği 2026-09-04: "sayfaları toplu görebileceğim bir buton
    // olmalı."
    await pumpNotebook(
      tester,
      notebook(
        pages: ['Seyahat'],
        items: const [
          NoteItem(id: 'a', text: 'genel yazı'),
          NoteItem(id: 'b', text: 'seyahat yazısı', section: 'Seyahat'),
        ],
      ),
    );
    await tester.tap(find.byIcon(Icons.grid_view_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Sayfalar'), findsOneWidget);
    // İki yaprak da ızgarada, önizleme yazılarıyla.
    expect(find.text('genel yazı'), findsWidgets);
    expect(find.text('seyahat yazısı'), findsWidgets);
  });

  testWidgets('arama kutusunda METİN/ANLAM seçimi var', (tester) async {
    // Kullanıcı isteği 2026-09-04: "tüm defterde arama yapabileceğim bir
    // alan olmalı hem anlamsal hem metin olarak."
    await pumpNotebook(tester, notebook());
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    expect(find.text('Metin'), findsOneWidget);
    expect(find.text('Anlam'), findsOneWidget);
  });

  testWidgets('kâğıt deseni menüden seçilir', (tester) async {
    await pumpNotebook(tester, notebook());
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(find.text('Kâğıt'), findsOneWidget);

    await tester.tap(find.text('Kâğıt'));
    await tester.pumpAndSettle();
    // Dört desen de örnek karesiyle listelenir.
    expect(find.text('Çizgili'), findsOneWidget);
    expect(find.text('Kareli'), findsOneWidget);
    expect(find.text('Noktalı'), findsOneWidget);
    expect(find.text('Düz'), findsOneWidget);
  });

  testWidgets('"+" levhasında görsel, PDF ve sunum var; metin diyalogu yok', (
    tester,
  ) async {
    await pumpNotebook(tester, notebook());
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // Eskiden telefonda yalnız galeri açılabiliyordu: PDF ve sunum eklemek
    // defterde HİÇ mümkün değildi (kullanıcı isteği 2026-09-01).
    expect(find.text('Görsel ekle'), findsOneWidget);
    expect(find.text('PDF ekle'), findsOneWidget);
    expect(find.text('Slayt ekle'), findsOneWidget);
  });

  testWidgets('sayfayı KAYDIRMAK boş yaprağa geçirir (diyalog yok)', (
    tester,
  ) async {
    await pumpNotebook(tester, notebook());
    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();

    // "Yeni sayfa ekle" diyalogu çıkmadan boş yaprağa geçildi; yaprağın
    // üstünde de yazı alanı var (yazınca sayfa kayda geçer).
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Bu sayfaya yaz…'), findsWidgets);
    expect(find.text('Sayfa 2'), findsWidgets);
  });

  testWidgets('yazarken gelen kayıt güncellemesi yazılanı SİLMEZ', (
    tester,
  ) async {
    // KÖK NEDEN sınıfı: alan kaydı 600 ms geciktiriyor ve kayıt her yazımda
    // akıştan geri dönüyor. Gelen metin koşulsuz uygulansaydı imleç satır
    // başına atlar, henüz kaydedilmemiş son harfler de silinirdi.
    final note = notebook();
    final stream = StreamController<Note?>.broadcast();
    addTearDown(stream.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notesRepositoryProvider.overrideWith((ref) => null),
          noteStreamProvider(note.id).overrideWith((ref) => stream.stream),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('tr'),
          home: ArchiveNoteScreen(noteId: note.id),
        ),
      ),
    );
    stream.add(
      note.copyWith(
        items: const [NoteItem(id: 'w', text: 'eski')],
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(pageWriter, 'yeni yazı');
    await tester.pump();
    // Kayıt henüz yazılmadan (600 ms geciktiriliyor) BAŞKA bir cihazın
    // yazımı akıştan geliyor.
    stream.add(
      note.copyWith(
        items: const [NoteItem(id: 'w', text: 'uzaktan gelen')],
      ),
    );
    // Akış olayı bir sonraki mikro görevde düşüyor: tek `pump` yetmiyor.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(
      find.text('yeni yazı'),
      findsOneWidget,
      reason: 'Kullanıcının yazdığı metin akıştan gelenle EZİLMEMELİ',
    );
  });

  testWidgets('arama defterin TAMAMINDA çalışır, sonuç sayfasını söyler', (
    tester,
  ) async {
    await pumpNotebook(
      tester,
      notebook(
        pages: ['Faturalar', 'Seyahat'],
        items: const [
          NoteItem(id: 'g', text: 'genel sayfadaki fatura notu'),
          NoteItem(
            id: 's',
            text: 'uçuş bileti',
            title: 'Bilet',
            section: 'Seyahat',
          ),
        ],
      ),
    );

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    // Arama alanı BAŞLIK çubuğunda: sayfanın yazı alanıyla karışmasın.
    await tester.enterText(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(TextField),
      ),
      'bilet',
    );
    await tester.pumpAndSettle();

    // Açık sayfa Genel; sonuç başka sayfada olsa da bulunur ve hangi
    // sayfada olduğu yazar.
    expect(find.text('Bilet'), findsOneWidget);
    expect(find.text('Seyahat'), findsWidgets);
    expect(find.text('genel sayfadaki fatura notu'), findsNothing);
  });

  testWidgets('yazı alanı kâğıdın çizgilerini KAPATMAZ (dolgu kapalı)', (
    tester,
  ) async {
    // KÖK NEDEN (kullanıcı bulgusu 2026-09-02: "arşiv defterinde sayfa
    // çizgileri kayboluyor"): uygulamanın `InputDecorationTheme`i
    // `filled: true` — alan kâğıdın üstüne kendi opak dikdörtgenini boyuyor
    // ve altındaki çizgileri siliyordu. Ekran görüntüsünde çizgiler tam da
    // alanın bittiği yerde başlıyordu.
    await pumpNotebook(tester, notebook());
    for (final field in tester.widgetList<TextField>(find.byType(TextField))) {
      expect(
        field.decoration?.filled,
        isFalse,
        reason: 'Defterdeki alanlar kâğıdın üstüne opak kutu boyamamalı',
      );
    }
  });

  testWidgets('BİÇİM çubuğu defterde de var', (tester) async {
    // Kullanıcı isteği 2026-09-02: "biçim ayarları vs burada da olmalı".
    await pumpNotebook(tester, notebook());
    expect(find.byType(FormatBar), findsNothing);

    await tester.tap(find.byIcon(Icons.text_format));
    await tester.pumpAndSettle();
    expect(find.byType(FormatBar), findsOneWidget);
  });

  testWidgets('sayfadaki görsel TUVALDE yüzer (metin etrafından akar)', (
    tester,
  ) async {
    // Kullanıcı isteği 2026-09-02: "görsel eklendiğinde normal not sayfamız
    // gibi metin etrafından akabilmeli, yeri değiştirilebilmeli".
    await pumpNotebook(
      tester,
      notebook(
        attachments: [
          Attachment(
            id: 'foto',
            kind: AttachmentKind.image,
            fileName: 'foto.jpg',
            mimeType: 'image/jpeg',
            x: 0.04,
            pageY: 8,
            displayWidth: 0.32,
          ),
        ],
      ),
    );
    // Tuval kuruldu: görsel sayfanın üstünde yüzen bir katman olarak duruyor
    // (editördeki gövdeyle aynı widget).
    expect(find.byType(NotePageCanvas), findsWidgets);
    // Dosya listesinde İKİNCİ kez görünmüyor.
    expect(find.text('foto.jpg'), findsNothing);
  });

  testWidgets('alt çubuk DAR ekrana sığar (taşma yok)', (tester) async {
    // Kullanıcı bulgusu 2026-09-02: "alt kısım sığmıyor". Çubukta beş düğme
    // ve sayfa adı var; taşma bir çizim hatası olarak testte patlar.
    tester.view.physicalSize = const Size(320 * 3, 640 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await pumpNotebook(tester, notebook(pages: ['Faturalar']));
    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.text_format), findsOneWidget);
    expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
  });
}


/// Yazımları YAKALAYAN sahte depo: testte Firestore yok, ama "sayfa gerçekten
/// kayda geçti mi" sorusunun tek yanıtı yazılan kayıt.
class _RecordingRepo implements NotesRepository {
  _RecordingRepo(this.onWrite);

  final void Function(Note) onWrite;

  @override
  Future<void> updateNote(Note note) async => onWrite(note);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
