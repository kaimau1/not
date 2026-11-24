import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/app_update.dart';
import 'package:notlar/core/widgets/app_notice.dart';
import 'package:notlar/features/ai/data/ai_gate.dart';
import 'package:notlar/features/ai/data/api_key_store.dart';
import 'package:notlar/features/ai/data/gemini_service.dart';
import 'package:notlar/features/auth/presentation/auth_providers.dart';
import 'package:notlar/features/folders/data/folders_repository.dart';
import 'package:notlar/features/notes/data/attachment_repository.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/editor/format_bar.dart';
import 'package:notlar/features/notes/presentation/editor/note_editor_screen.dart';
import 'package:notlar/features/notes/presentation/editor/page_ink_layer.dart';
import 'package:notlar/features/notes/presentation/editor/pen_tray.dart';
import 'package:notlar/features/notes/presentation/editor/pinned_image_surface.dart';
import 'package:notlar/features/notes/presentation/editor/pinned_media_bar.dart';
import 'package:notlar/features/notes/presentation/editor/pinned_media_pane.dart';
import 'package:notlar/features/notes/presentation/viewers/area_actions.dart';
import 'package:notlar/features/notes/presentation/viewers/ink_layer.dart';
import 'package:notlar/features/notes/presentation/viewers/ink_tools.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

final Uint8List _tinyPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
);

class _FakeGeminiService extends GeminiService {
  _FakeGeminiService() : super(const ApiKeyStore());

  @override
  Future<String> askAboutImage(
    Uint8List bytes,
    String mimeType, {
    String question = '',
  }) async => '**Alan özeti**\n- Birinci madde';
}

void main() {
  Widget wrap(Widget child) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('tr'),
    home: Scaffold(body: child),
  );

  test(
    'computePinnedImageRect uses stored dims and falls back to probedRatio',
    () {
      final stored = computePinnedImageRect(
        const Size(400, 300),
        width: 200,
        height: 100,
        probedRatio: 1.5,
      );
      expect(stored, const Rect.fromLTWH(0, 50, 400, 200));

      final probed = computePinnedImageRect(
        const Size(400, 300),
        width: 0,
        probedRatio: 0.5,
      );
      expect(probed, const Rect.fromLTWH(0, 50, 400, 200));

      expect(computePinnedImageRect(const Size(400, 300)), isNull);
      expect(
        computePinnedImageRect(Size.zero, width: 200, height: 100),
        isNull,
      );
    },
  );

  testWidgets(
    'PinnedImageInkSurface supports pen strokes on dimension-less probed image',
    (tester) async {
      var saved = <InkStroke>[];
      final ink = InkController(
        initial: const [],
        onChanged: (strokes) => saved = strokes,
      );
      ink.setEditing(true);
      addTearDown(ink.dispose);

      await tester.pumpWidget(
        wrap(
          SizedBox(
            width: 320,
            height: 240,
            child: PinnedImageInkSurface(
              strokes: const [],
              revision: 0,
              width: null,
              height: null,
              probedRatio: 0.75,
              activeController: ink,
            ),
          ),
        ),
      );
      await tester.pump();

      final g = await tester.startGesture(const Offset(80, 90));
      await tester.pump();
      await g.moveBy(const Offset(50, 20));
      await tester.pump();
      await g.moveBy(const Offset(40, 15));
      await tester.pump();
      await g.up();
      await tester.pump();

      expect(saved, isNotEmpty);
      expect(ink.ink, isNotEmpty);
    },
  );

  testWidgets('showPinnedSmartActionsSheet invokes tapped action cleanly', (
    tester,
  ) async {
    var ocr = 0;
    var summarize = 0;
    var tasks = 0;
    var area = 0;

    await tester.pumpWidget(
      wrap(
        Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => showPinnedSmartActionsSheet(
                context,
                onOcr: () => ocr++,
                onSummarize: () => summarize++,
                onExtractTasks: () => tasks++,
                onAreaAsk: () => area++,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('pinned-smart-ocr')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('pinned-smart-summarize')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('pinned-smart-tasks')), findsOneWidget);
    expect(find.byKey(const ValueKey('pinned-smart-area-ask')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('pinned-smart-tasks')));
    await tester.pumpAndSettle();

    expect(tasks, 1);
    expect(ocr + summarize + area, 0);
  });

  testWidgets(
    'AreaAskScreen inserts stripped markdown text via onInsertToNote',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      var inserted = '';

      await tester.pumpWidget(
        ProviderScope(
          retry: (_, _) => null,
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            aiAvailabilityProvider.overrideWithValue(AiAvailability.ready),
            geminiServiceProvider.overrideWithValue(_FakeGeminiService()),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('tr'),
            home: AreaAskScreen(
              png: _tinyPng,
              onInsertToNote: (text) => inserted = text,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Sor'));
      await tester.pumpAndSettle();

      final insertBtn = find.byKey(const ValueKey('area-ask-insert'));
      expect(insertBtn, findsOneWidget);

      await tester.ensureVisible(insertBtn);
      await tester.tap(insertBtn);
      await tester.pumpAndSettle();

      expect(inserted, 'Alan özeti\n- Birinci madde');
    },
  );

  testWidgets(
    'editor bottom panels (FormatBar and PenTray) are mutually exclusive',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      InkToolMemory.autoStylus = true;
      const note = Note(
        id: 'n1',
        type: NoteType.text,
        title: 'Test',
        body: 'Merhaba dünya',
      );

      final container = ProviderContainer(
        retry: (_, _) => null,
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          currentUidProvider.overrideWithValue(null),
          updateRequiredProvider.overrideWithValue(false),
          notesRepositoryProvider.overrideWithValue(null),
          attachmentRepositoryProvider.overrideWithValue(null),
          foldersRepositoryProvider.overrideWithValue(null),
          noteStreamProvider('n1').overrideWith((ref) => Stream.value(note)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('tr'),
            builder: (context, child) => AppNoticeHost(child: child!),
            home: const NoteEditorScreen(noteId: 'n1'),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // 1. Open FormatBar -> FormatBar opens, PenTray absent.
      await tester.tap(find.byIcon(Icons.text_format).last);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(FormatBar), findsOneWidget);
      expect(find.byType(PenTray), findsNothing);

      // 2. Stylus touch on PageInkStack triggers _openPen() -> PenTray opens
      // and FormatBar closes cleanly (mutually exclusive).
      final stylus = await tester.startGesture(
        tester.getCenter(find.byType(PageInkStack)),
        kind: PointerDeviceKind.stylus,
      );
      await tester.pump();
      await stylus.moveBy(const Offset(50, 10));
      await tester.pump();
      await stylus.up();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(PenTray), findsOneWidget);
      expect(find.byType(FormatBar), findsNothing);

      // Flush delayed timers inside NoteEditorScreen before teardown.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 6));
    },
  );

  testWidgets(
    'PinnedMediaPane shows smart actions on wide bar and inside more sheet on phone',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      const media = Attachment(
        id: 'img1',
        kind: AttachmentKind.image,
        fileName: 'photo.jpg',
        mimeType: 'image/jpeg',
        width: 800,
        height: 600,
        pinHeight: 220,
      );

      Widget buildPane(double width) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('tr'),
        home: Scaffold(
          body: SizedBox(
            width: width,
            height: 600,
            child: PinnedMediaPane(
              media: media,
              onHeightChanged: (_) {},
              onUnpin: () {},
              onOpen: () {},
              onExtractText: () {},
              onSmartSummarize: () {},
              onSmartTasks: () {},
              onSmartAreaAsk: () {},
              child: const SizedBox.expand(),
            ),
          ),
        ),
      );

      // Phone width (412 dp): smart button stays in ⋮ sheet to protect bar budget.
      await tester.pumpWidget(buildPane(412));
      await tester.pump();
      expect(find.byKey(const ValueKey('pinned-smart-actions')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('pinned-media-menu')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('pinned-sheet-smart-ocr')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('pinned-sheet-smart-summarize')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('pinned-sheet-smart-tasks')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('pinned-sheet-smart-area-ask')),
        findsOneWidget,
      );

      // Wide width (>= 600 dp): quick Smart Actions button sits on the bar.
      await tester.pumpWidget(buildPane(720));
      await tester.pump();
      expect(
        find.byKey(const ValueKey('pinned-smart-actions')),
        findsOneWidget,
      );
    },
  );
}
