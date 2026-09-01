import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/archive_paper.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/archive_note_screen.dart';
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
    ArchivePaper paper = ArchivePaper.lined,
  }) => Note(
    id: 'n1',
    type: NoteType.archive,
    title: 'Defter',
    archivePages: pages,
    archivePaper: paper,
    items: items,
  );

  testWidgets('sayfanın kendisi bir yazı alanıdır (diyalog yok)', (
    tester,
  ) async {
    await pumpNotebook(tester, notebook());

    // Açık sayfada doğrudan yazılabilen bir alan var ve ipucu onu söylüyor.
    expect(find.text('Bu sayfaya yaz…'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'ilk cümle');
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

  testWidgets('sayfa başlığı YERİNDE düzenlenir, Genel sayfası sabittir', (
    tester,
  ) async {
    await pumpNotebook(tester, notebook(pages: ['Faturalar']));
    // Genel sayfasının başlığı düz yazı: alan yok (ilk sayfada yalnız yazı
    // alanı var).
    expect(find.byType(TextField), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();
    // İkinci sayfada başlık da bir alan: yazı alanıyla birlikte iki tane.
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('Faturalar'), findsWidgets);
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

    await tester.enterText(find.byType(TextField).first, 'yeni yazı');
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
}
