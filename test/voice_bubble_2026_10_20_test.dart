import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:notlar/features/ai/data/ai_gate.dart';
import 'package:notlar/features/ai/presentation/ai_hub_screen.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/presentation/listening_visuals.dart';
import 'package:notlar/features/notes/presentation/notes_providers.dart';
import 'package:notlar/features/notes/presentation/viewers/bubble_layer.dart';
import 'package:notlar/features/notes/presentation/viewers/pdf_selection_bar.dart';
import 'package:notlar/features/notes/presentation/viewers/pdf_viewer_screen.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kullanıcı listesi 2026-10-20 (ikinci tur): AI sesli not AI menüsünde,
/// iki dinleme alanı tek orta boy kart, PDF/balon kasması, premium balon.
void main() {
  Widget app(Widget home) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    locale: const Locale('tr'),
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: home),
  );

  group('ortak dinleme kartı', () {
    testWidgets('doğrudan yazım kartı ORTA boyda (eski şerit ~56 px, eski '
        'levha ~330 px)', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        app(
          Align(
            alignment: Alignment.bottomCenter,
            child: ListeningCard(
              mode: ListeningMode.dictation,
              active: true,
              title: 'Dinliyorum...',
              subtitle: 'Konuştukça imlecin olduğu yere yazılır',
              clock: const Text('0:02'),
              action: ListeningActionButton(
                listening: true,
                label: 'Bitir',
                onPressed: () {},
              ),
            ),
          ),
        ),
      );
      final height = tester
          .getSize(find.byKey(const ValueKey('listening-card-dictation')))
          .height;
      expect(height, inInclusiveRange(90, 150));
      // Tam genişlik dalga + yanında yazılı "Bitir".
      expect(find.byType(ListeningWaveform), findsOneWidget);
      expect(find.text('Bitir'), findsOneWidget);
    });

    testWidgets('yapay zekâ kartı aynı yerleşim + döküm; levhanın yarısını '
        'kaplamaz', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        app(
          Align(
            alignment: Alignment.bottomCenter,
            child: ListeningCard(
              mode: ListeningMode.ai,
              active: true,
              title: 'Dinliyorum...',
              subtitle: 'Türkçe · noktalama otomatik',
              clock: const Text('0:05'),
              body: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: 40,
                  maxHeight: 120,
                ),
                child: const Text('Bir iki üç dört beş altı yedi sekiz'),
              ),
              action: ListeningActionButton(
                listening: true,
                label: 'Bitir',
                onPressed: () {},
              ),
            ),
          ),
        ),
      );
      final height = tester
          .getSize(find.byKey(const ValueKey('listening-card-ai')))
          .height;
      expect(height, inInclusiveRange(130, 260));
      expect(find.text('Yapay zekâ'), findsOneWidget);
    });
  });

  group('balon teması', () {
    test('eski amber varsayılan YENİ varsayılanla çizilir; veri değişmez', () {
      const legacy = PageBubble(id: 'a', page: 1, x: 0.5, y: 0.5);
      expect(legacy.color, BubbleController.legacyDefault);
      expect(
        BubbleController.displayColor(legacy),
        const Color(BubbleController.defaultColor),
      );
      // Vurgu ve açık metin kendi renginde kalır.
      const highlight = PageBubble(
        id: 'b',
        page: 1,
        x: 0.5,
        y: 0.5,
        rects: [PageBubbleRect(0, 0, 1, 0.1)],
      );
      expect(
        BubbleController.displayColor(highlight),
        const Color(BubbleController.legacyDefault),
      );
      // Palette sarı yok, başı yeni varsayılan.
      expect(BubbleController.palette.first, BubbleController.defaultColor);
      expect(
        BubbleController.palette,
        isNot(contains(BubbleController.legacyDefault)),
      );
    });
  });

  group('PDF katmanları', () {
    testWidgets('pdfrx metin seçimi kapalı, sayfa katmanı aynı boyda '
        'YENİDEN KURULMAZ', (tester) async {
      await tester.pumpWidget(app(const SizedBox()));
      final context = tester.element(find.byType(SizedBox));
      final selection = PdfSelectionState();
      final bubbles = BubbleController(initial: const [], onChanged: (_) {});
      addTearDown(bubbles.dispose);
      final params = pdfLayerParams(
        selection: selection,
        bubbles: bubbles,
        editable: true,
      );
      expect(params.textSelectionParams?.enabled, isFalse);
      // Test ortamı Android: görüntüleyici odak çalmaz (balonun yazı alanı
      // odağını kaybetmesin).
      expect(params.keyHandlerParams.canRequestFocus, isFalse);

      final page = _FakePage(1);
      final builder = params.pageOverlaysBuilder!;
      final first = builder(context, const Rect.fromLTWH(0, 0, 300, 400), page);
      // Kaydırma: konum değişir, boy aynı (kayan nokta artığıyla).
      final scrolled = builder(
        context,
        const Rect.fromLTWH(0, -120.37, 300.0000001, 400),
        page,
      );
      expect(identical(first.single, scrolled.single), isTrue);
      // Yakınlaştırma: boy değişti → yeni katman.
      final zoomed = builder(
        context,
        const Rect.fromLTWH(0, 0, 450, 600),
        page,
      );
      expect(identical(first.single, zoomed.single), isFalse);
    });
  });

  group('Yapay Zekâ ekranı', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    testWidgets('AI ile sesli not EN ÜSTTE; dokunuş ana ekranda ortak '
        'levhayı ister', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final router = GoRouter(
        initialLocation: '/ai',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) =>
                const Scaffold(body: Text('ana-ekran')),
          ),
          GoRoute(
            path: '/ai',
            builder: (context, state) => const AiHubScreen(),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            aiUnlimitedProvider.overrideWithValue(false),
            freeAiRemainingProvider.overrideWithValue(30),
            aiDailyLimitProvider.overrideWithValue(30),
            notesStreamProvider.overrideWith(
              (ref) => Stream.value(const <Note>[]),
            ),
          ],
          child: MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('tr'),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final voice = find.byKey(const ValueKey('ai-hub-voice-note'));
      expect(voice, findsOneWidget);
      // Asistanın soru kutusundan ÖNCE.
      expect(
        tester.getTopLeft(voice).dy,
        lessThan(tester.getTopLeft(find.byType(TextField).first).dy),
      );

      final container = ProviderScope.containerOf(
        tester.element(find.byType(AiHubScreen)),
      );
      await tester.tap(voice);
      await tester.pumpAndSettle();
      expect(find.text('ana-ekran'), findsOneWidget);
      expect(container.read(voiceAutostartProvider), isTrue);
    });
  });
}

class _FakePage implements PdfPage {
  _FakePage(this.pageNumber);

  @override
  final int pageNumber;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
