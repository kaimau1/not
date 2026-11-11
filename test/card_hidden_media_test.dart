import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/note_card.dart';
import 'package:notlar/features/notes/presentation/note_card_media.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// F60.S8: kartta görsel/video önizlemesi gizliyken ek "yokmuş gibi"
/// durmasın; tek satır yazıyla anılsın. Görünürken özet çıkmaz.
void main() {
  const youtube = Attachment(
    id: 'yt',
    kind: AttachmentKind.video,
    fileName: 'Ön kol hareketleri',
    mimeType: 'video/youtube',
    webUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
  );
  const img = Attachment(
    id: 'i1',
    kind: AttachmentKind.image,
    fileName: 'a.jpg',
    mimeType: 'image/jpeg',
  );
  const img2 = Attachment(
    id: 'i2',
    kind: AttachmentKind.image,
    fileName: 'b.jpg',
    mimeType: 'image/jpeg',
  );

  late SharedPreferences prefs;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Future<void> pump(
    WidgetTester tester,
    Note note, {
    String lang = 'tr',
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale(lang),
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(width: 300, child: NoteCard(note: note)),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Note mk({
    bool hidden = false,
    List<Attachment> atts = const [youtube, img, img2],
    String? bg,
  }) => Note(
    id: 'n',
    type: NoteType.text,
    title: 'Not',
    body: 'metin',
    attachments: atts,
    cardMediaHidden: hidden,
    backgroundImageId: bg,
  );

  group('CardHiddenMedia', () {
    test('görünürken özet yok; gizliyken sayar; zemin görseli sayılmaz', () {
      expect(
        CardHiddenMedia.of(mk(), showVisuals: true, showFiles: true).isEmpty,
        isTrue,
      );
      final h = CardHiddenMedia.of(
        mk(hidden: true),
        showVisuals: true,
        showFiles: true,
      );
      expect((h.youtube, h.images, h.videos), (1, 2, 0));
      final bg = CardHiddenMedia.of(
        mk(hidden: true, atts: const [img], bg: 'i1'),
        showVisuals: true,
        showFiles: true,
      );
      expect(bg.isEmpty, isTrue);
    });
  });

  testWidgets('gizliyken YouTube + görsel özeti görünür', (tester) async {
    await pump(tester, mk(hidden: true));
    expect(find.text('YouTube videosu · 2 görsel'), findsOneWidget);
  });

  testWidgets('tek YouTube: başlığı eklenir; İngilizce', (tester) async {
    await pump(tester, mk(hidden: true, atts: const [youtube]), lang: 'en');
    expect(find.text('YouTube video · Ön kol hareketleri'), findsOneWidget);
  });

  testWidgets('görsel görünürken özet çıkmaz', (tester) async {
    await pump(tester, mk());
    expect(find.textContaining('YouTube videosu'), findsNothing);
    expect(find.textContaining('görsel'), findsNothing);
  });

  testWidgets('Kartta görünenler: görseller kapalıysa özet çıkar', (
    tester,
  ) async {
    await prefs.setBool('card_show_media', false);
    await pump(tester, mk());
    expect(find.text('YouTube videosu · 2 görsel'), findsOneWidget);
  });
}
