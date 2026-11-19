import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/ai/data/ai_gate.dart';
import 'package:notlar/features/ai/data/gemini_service.dart';
import 'package:notlar/features/ai/presentation/ai_chat_screen.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeGemini implements GeminiService {
  final calls = <String>[];

  @override
  Future<String> chatAboutNote({
    required Note note,
    required List<({Uint8List bytes, String mimeType, String fileName})>
    attachments,
    required List<ChatTurn> history,
  }) async {
    calls.add('qa:${history.last.text}');
    return 'yanıt';
  }

  @override
  Future<String> brainstormAboutNote({
    required Note note,
    required List<ChatTurn> history,
    String? focusHeading,
  }) async {
    calls.add('bs:${history.last.text}');
    return 'fikir';
  }

  @override
  Future<List<String>> outlineNote(Note note) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// AI-S2 eki (PLAN §1.6 A1): notla sohbette öneri çipleri — Ana hat · Fikir
/// ver · Eksikleri bul. Sohbet boşken görünür; "Fikir ver" beyin fırtınası
/// kipinde, öteki ikisi soru-cevapta sorulur.
void main() {
  Future<_FakeGemini> pump(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final fake = _FakeGemini();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          aiAvailabilityProvider.overrideWithValue(AiAvailability.ready),
          geminiServiceProvider.overrideWithValue(fake),
        ],
        child: const MaterialApp(
          locale: Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AiChatScreen(
            note: Note(id: 'n', type: NoteType.text, title: 'Gezi planı'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return fake;
  }

  testWidgets('üç öneri çipi; Ana hat soru-cevapta sorulur, çipler kalkar', (
    tester,
  ) async {
    final fake = await pump(tester);
    expect(find.text('Ana hat'), findsOneWidget);
    expect(find.text('Fikir ver'), findsOneWidget);
    expect(find.text('Eksikleri bul'), findsOneWidget);
    await tester.tap(find.text('Ana hat'));
    await tester.pumpAndSettle();
    expect(fake.calls.single, startsWith('qa:'));
    expect(find.text('yanıt'), findsOneWidget);
    expect(find.text('Ana hat'), findsNothing);
  });

  testWidgets('Fikir ver beyin fırtınası kipine geçip sorar', (tester) async {
    final fake = await pump(tester);
    await tester.tap(find.text('Fikir ver'));
    await tester.pumpAndSettle();
    expect(fake.calls.single, startsWith('bs:'));
    expect(find.text('fikir'), findsOneWidget);
  });
}
