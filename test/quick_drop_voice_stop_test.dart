import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/ai/data/ai_gate.dart';
import 'package:notlar/features/notes/data/device_speech.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/quick_drop_sheet.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/editor_harness.dart' show CountingNotesRepository;

class _Repo extends CountingNotesRepository {
  final writes = <String, Map<String, dynamic>>{};

  @override
  Future<void> updateFields(String noteId, Map<String, dynamic> fields) {
    writes[noteId] = fields;
    return Future.value();
  }
}

/// Sesle "dur / bekle" (KARAR PLAN 1.0b P5, 2026-11-20): konuşma bitince
/// geri sayım başlar ama mikrofon açık kalır; "dur" geri sayımı durdurur,
/// devam eden konuşma içeriğe eklenir ve yeni sessizlikte yeniden sayılır.
void main() {
  const events = EventChannel('dev.kaimau.notlar/speech');
  const system = MethodChannel('dev.kaimau.notlar/system');
  MockStreamHandlerEventSink? sink;
  var listens = 0;

  final market = Note(
    id: 'm',
    type: NoteType.checklist,
    title: 'Market listesi',
    updatedAt: DateTime(2026, 11, 20),
    items: const [NoteItem(id: '1', text: 'Ekmek')],
  );

  setUp(() {
    sink = null;
    listens = 0;
    DeviceSpeech.debugAvailable = true;
    DeviceSpeech.debugMicGranted = true;
  });

  tearDown(() {
    DeviceSpeech.debugAvailable = null;
    DeviceSpeech.debugMicGranted = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockStreamHandler(events, null)
      ..setMockMethodCallHandler(system, null);
  });

  Future<_Repo> open(WidgetTester tester) async {
    // Sahte tanıyıcı test GÖVDESİNDE (bkz. ortam_ci.md test tuzakları).
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockStreamHandler(
        events,
        MockStreamHandler.inline(
          onListen: (_, s) {
            listens++;
            sink = s;
          },
        ),
      )
      ..setMockMethodCallHandler(system, (_) async => null);
    SharedPreferences.setMockInitialValues({
      'quick_drop_keyboard': false,
      'quick_drop_mic': true,
    });
    final prefs = await SharedPreferences.getInstance();
    final repo = _Repo();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          notesStreamProvider.overrideWith((ref) => Stream.value([market])),
          notesRepositoryProvider.overrideWithValue(repo),
          aiAvailabilityProvider.overrideWithValue(AiAvailability.needsKey),
        ],
        child: MaterialApp(
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Consumer(
            builder: (context, ref, _) {
              ref.watch(notesStreamProvider);
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => showQuickDropSheet(context),
                    child: const Text('aç'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();
    expect(listens, 1, reason: 'levha kendiliğinden dinlemeli');
    return repo;
  }

  Future<void> say(WidgetTester tester, String text) async {
    sink!.success({'text': text});
    await tester.pump();
    await tester.pump();
  }

  /// Sessizlik bitişinin yerine: yerli taraf oturumu kapattı (aynı onEnd
  /// yolu; gerçek sessizlik kapısı gerçek saatle çalışır).
  Future<void> silence(WidgetTester tester) async {
    sink!.error(code: 'speech_idle', message: 'idle');
    await tester.pump();
    await tester.pump();
  }

  final counting = find.byKey(const ValueKey('quick-drop-counting'));
  final heard = find.byKey(const ValueKey('quick-entry-heard'));

  testWidgets('"dur" geri sayımı durdurur, eklenmez, mikrofon kapanır', (
    tester,
  ) async {
    final repo = await open(tester);
    await say(tester, 'süt yumurta');
    await silence(tester);
    expect(counting, findsOneWidget);
    expect(heard, findsOneWidget, reason: 'geri sayımda dinleme sürer');
    await say(tester, 'süt yumurta dur');
    expect(counting, findsNothing);
    expect(heard, findsNothing, reason: 'dinleme bitti');
    expect(find.text('süt yumurta'), findsOneWidget, reason: '"dur" yazılmaz');
    await tester.pump(const Duration(seconds: 3));
    expect(repo.writes, isEmpty);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('geri sayımda konuşma sürerse içeriğe eklenir, yeniden sayılır', (
    tester,
  ) async {
    final repo = await open(tester);
    await say(tester, 'süt');
    await silence(tester);
    expect(counting, findsOneWidget);
    // Yalnız noktalama düzeltmesi geri sayımı bozmaz.
    await say(tester, 'Süt.');
    expect(counting, findsOneWidget);
    await say(tester, 'Süt. yumurta');
    expect(counting, findsNothing, reason: 'konuşma sürüyor');
    await silence(tester);
    expect(counting, findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(repo.writes.keys, ['m']);
    final items = [
      for (final m in repo.writes['m']!['items'] as List) (m as Map)['text'],
    ];
    expect(items, containsAll(['Ekmek', 'Süt', 'Yumurta']));
    await tester.pumpWidget(const SizedBox());
  });
}
