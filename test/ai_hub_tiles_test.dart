import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/ai/data/ai_gate.dart';
import 'package:notlar/features/ai/presentation/ai_hub_screen.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Yapay Zeka sayfasındaki "NOTLARIN ÜZERİNDE" bölümü.
///
/// KULLANICI BİLDİRDİ: "2 kutu var, not asistanı ve günlük brifing" — dört
/// iş kutusunun tamamı görünmüyordu. Bu test kutuların GERÇEKTEN çizildiğini
/// (ve dördünün de erişilebilir olduğunu) doğrular; ekranda görünmemesi
/// çizim değil YERLEŞİM sorunuysa buradan anlaşılır.
void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Future<void> pumpHub(WidgetTester tester, {List<Note> notes = const []}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          // Firestore'a inen sağlayıcılar testte kurulamaz; ekranın
          // OKUDUĞU türetilmiş değerler doğrudan veriliyor.
          aiUnlimitedProvider.overrideWithValue(false),
          freeAiRemainingProvider.overrideWithValue(30),
          aiDailyLimitProvider.overrideWithValue(30),
          notesStreamProvider.overrideWith((ref) => Stream.value(notes)),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('tr'),
          home: const AiHubScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('dört iş kutusunun dördü de çizilir', (tester) async {
    // Uzun ekran: kutular görünür alanın altında kalıp "yok" sanılmasın.
    tester.view.physicalSize = const Size(1080, 3600);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await pumpHub(tester);
    final l10n = await AppLocalizations.delegate.load(const Locale('tr'));

    expect(find.text(l10n.aiOnYourNotes), findsOneWidget);
    expect(find.text(l10n.aiTaskWeekSummary), findsOneWidget);
    expect(find.text(l10n.aiTaskTagUntagged), findsOneWidget);
    expect(find.text(l10n.aiTaskSuggestTitles), findsOneWidget);
    expect(find.text(l10n.aiTaskDuplicates), findsOneWidget);
  });

  testWidgets('kopya kutusu kaydırılarak erişilebilir (dar ekran)', (
    tester,
  ) async {
    // Gerçek telefon yüksekliği: kutular ilk ekranda görünmeyebilir ama
    // listede OLMALI ve kaydırınca gelmeli.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await pumpHub(tester);
    final l10n = await AppLocalizations.delegate.load(const Locale('tr'));

    await tester.scrollUntilVisible(
      find.text(l10n.aiTaskDuplicates),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text(l10n.aiTaskDuplicates), findsOneWidget);
  });
}
