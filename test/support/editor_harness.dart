import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/app/theme/app_palette.dart';
import 'package:notlar/app/theme/app_theme.dart';
import 'package:notlar/core/app_update.dart';
import 'package:notlar/core/utils/firestore_size.dart';
import 'package:notlar/features/auth/presentation/auth_providers.dart';
import 'package:notlar/features/folders/data/folders_repository.dart';
import 'package:notlar/features/notes/data/attachment_repository.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/presentation/editor/note_editor_screen.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tam editörü Firebase'siz kuran ORTAK düzenek (OTURTMA F59.1). Bütçe
/// testleri (`perf_budget_test.dart`) ve kabuk testleri aynı kurulumu
/// kullanır: sayılan şey süre değil SAYI (kurulum, kayıt, bayt).

/// Sahne boyunca widget türü başına yeniden kurulum sayar.
class BuildCounter {
  final counts = <String, int>{};

  void start() {
    counts.clear();
    debugOnRebuildDirtyWidget = (e, _) {
      final name = e.widget.runtimeType.toString();
      counts[name] = (counts[name] ?? 0) + 1;
    };
  }

  void stop() => debugOnRebuildDirtyWidget = null;

  int of(String type) => counts[type] ?? 0;
}

/// Editörün kayıtlarını sayan sahte depo: `updateNote` Firestore'a gitmez,
/// çağrı sayısı ve yazılacak belgenin tahmini boyu tutulur.
class CountingNotesRepository extends NotesRepository {
  CountingNotesRepository() : super(FakeFirebaseFirestore(), 'u');

  int updateNoteCalls = 0;
  int bytesWritten = 0;

  /// Son kaydedilen not (veri kaybı denetimi için).
  Note? lastSaved;

  @override
  Future<void> updateNote(Note note, {bool clientTime = false}) {
    updateNoteCalls++;
    bytesWritten += estimateValueBytes(note.toMap());
    lastSaved = note;
    return Future.value();
  }

  @override
  Future<void> updateFields(String noteId, Map<String, dynamic> fields) =>
      Future.value();

  void resetCounts() {
    updateNoteCalls = 0;
    bytesWritten = 0;
  }
}

/// Telefon penceresinde (varsayılan 412×915, üst 30 / alt 48 sistem payı)
/// tam [NoteEditorScreen] kurar. [repo] verilirse editör ona kaydeder.
/// [home] verilirse editör yerine o kurulur (editörü rota olarak açıp
/// kapatan testler: `editor_leak_test.dart`). [overrides] yukarıdakilere
/// eklenir (onları yeniden geçersiz kılma).
Future<ProviderContainer> pumpEditor(
  WidgetTester tester,
  Note note, {
  Size size = const Size(412, 915),
  NotesRepository? repo,
  Widget? home,
  List<Override> overrides = const [],
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = const FakeViewPadding(top: 30, bottom: 48);
  tester.view.viewPadding = const FakeViewPadding(top: 30, bottom: 48);
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    // Firebase'siz sağlayıcılar yeniden denemesin (bekleyen zamanlayıcı).
    retry: (_, _) => null,
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      currentUidProvider.overrideWithValue(null),
      updateRequiredProvider.overrideWithValue(false),
      notesRepositoryProvider.overrideWithValue(repo),
      attachmentRepositoryProvider.overrideWithValue(null),
      foldersRepositoryProvider.overrideWithValue(null),
      noteStreamProvider(note.id).overrideWith((ref) => Stream.value(note)),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.of(ThemeFamily.sage, Brightness.light),
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home ?? NoteEditorScreen(noteId: note.id),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 500));
  return container;
}

/// Editörü kapatır; gecikmeli işleri (kayıt, ipucu) testin sonunda bitsin.
Future<void> endEditor(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 30));
}
