import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/editor/ai_result_sheet.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// AI çıktısı nota YAZILMADAN önce inceleme sayfasında görünür; biçim
/// (düz metin / madde / sıralı) değiştirilebilir, sonra eklenir.
void main() {
  Future<void> openSheet(
    WidgetTester tester, {
    required void Function(String) onInsert,
    void Function(String, {NoteType? asType})? onCreateNote,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showAiResultSheet(
                  context,
                  title: 'Videodan not',
                  text: 'birinci satir\nikinci satir',
                  onInsert: onInsert,
                  onCreateNote:
                      onCreateNote ?? (t, {NoteType? asType}) {},
                ),
                child: const Text('ac'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ac'));
    await tester.pumpAndSettle();
  }

  testWidgets('sonuc once sayfada gorunur, nota yazilmaz', (tester) async {
    var inserted = '';
    await openSheet(tester, onInsert: (t) => inserted = t);
    // Metin duzenlenebilir alanda duruyor; heniz hicbir sey eklenmedi.
    expect(find.text('birinci satir\nikinci satir'), findsOneWidget);
    expect(inserted, isEmpty);

    await tester.tap(find.text('Nota ekle'));
    await tester.pumpAndSettle();
    expect(inserted, 'birinci satir\nikinci satir');
  });

  testWidgets('madde/sirali bicimi metni donusturur', (tester) async {
    var inserted = '';
    await openSheet(tester, onInsert: (t) => inserted = t);

    await tester.tap(find.text('Liste'));
    await tester.pumpAndSettle();
    expect(find.text('- birinci satir\n- ikinci satir'), findsOneWidget);

    // Siraliya gecince eski isaretler ustune binmez.
    await tester.tap(find.text('Sıralı'));
    await tester.pumpAndSettle();
    expect(find.text('1. birinci satir\n2. ikinci satir'), findsOneWidget);

    await tester.tap(find.text('Nota ekle'));
    await tester.pumpAndSettle();
    expect(inserted, '1. birinci satir\n2. ikinci satir');
  });

  testWidgets('yeni not secilen tiple acilir', (tester) async {
    NoteType? createdType;
    await openSheet(
      tester,
      onInsert: (_) {},
      onCreateNote: (t, {NoteType? asType}) => createdType = asType,
    );
    await tester.tap(find.text('Liste'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yeni not olarak'));
    await tester.pumpAndSettle();
    expect(createdType, NoteType.checklist);
  });
}
