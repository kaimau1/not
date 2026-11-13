import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/connectivity.dart';
import 'package:notlar/features/ai/presentation/ai_sheet.dart';
import 'package:notlar/features/auth/presentation/account_required.dart';
import 'package:notlar/features/auth/presentation/auth_providers.dart';
import 'package:notlar/features/folders/data/folders_repository.dart';
import 'package:notlar/features/folders/domain/note_folder.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/dashboard_screen.dart'
    show pendingUploadsBarLabel;
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// DENEYIM F79.6 (4)(5): çevrimdışı hâller önceden söylenir.
void main() {
  final l10n = lookupAppLocalizations(const Locale('tr'));

  group('F79.6 (4) AI levhası çevrimdışı', () {
    late SharedPreferences prefs;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });
    final note = Note(
      id: 'n1',
      type: NoteType.text,
      title: 'Başlık',
      body: 'Biraz metin',
      updatedAt: DateTime(2026, 11, 13),
    );

    Future<void> open(WidgetTester tester, {required bool offline}) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            isAnonymousProvider.overrideWithValue(false),
            isOfflineProvider.overrideWithValue(offline),
            notesStreamProvider.overrideWith((ref) => Stream.value([note])),
            foldersStreamProvider.overrideWith(
              (ref) => Stream.value(const <NoteFolder>[]),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('tr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showAiSheet(context, note),
                  child: const Text('aç'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('aç'));
      await tester.pumpAndSettle();
    }

    bool locked(WidgetTester tester) =>
        tester.widget<AiStatusDim>(find.byType(AiStatusDim)).locked;

    testWidgets('çevrimdışı: kart görünür, araçlar kilitli', (tester) async {
      await open(tester, offline: true);
      expect(find.byKey(const ValueKey('ai-offline-card')), findsOneWidget);
      expect(find.text(l10n.aiOfflineTitle), findsOneWidget);
      expect(locked(tester), isTrue);
    });

    testWidgets('bağlıyken kart yok, araçlar açık', (tester) async {
      await open(tester, offline: false);
      expect(find.byKey(const ValueKey('ai-offline-card')), findsNothing);
      expect(locked(tester), isFalse);
    });
  });

  group('F79.6 (5) bekleyen ek şeridi', () {
    String label({
      int pending = 2,
      int failed = 0,
      bool needsDrive = false,
      bool offline = false,
    }) => pendingUploadsBarLabel(
      l10n,
      pending: pending,
      failed: failed,
      needsDrive: needsDrive,
      offline: offline,
    );

    test('bağlıyken "yükleniyor"', () {
      expect(label(), l10n.pendingUploads(2));
    });

    test('çevrimdışıyken "yükleniyor" demez', () {
      expect(label(offline: true), l10n.pendingUploadsOffline(2));
      expect(label(offline: true), isNot(l10n.pendingUploads(2)));
    });

    test('çevrimdışı hatadan önce gelir (deneme düşmesi beklenen şey)', () {
      expect(label(offline: true, failed: 1), l10n.pendingUploadsOffline(2));
    });

    test('Drive bağlantısı bekliyorsa o söylenir', () {
      expect(label(needsDrive: true, offline: true), l10n.driveWaiting(2));
    });
  });
}
