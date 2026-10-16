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

/// Ana ekran kartının medya önizlemesi.
///
/// KULLANICI BULGUSU (2026-10-15): "notlarda video veya resim olduğunda
/// dashboard'da görülmüyor; video, PDF, balonlu mod için düzenli, anlaşılır
/// ve ayırt edilebilir bir görüntü olmalı". Üste sabitli YouTube videosu
/// olan not kartta yalnız başlıktan ibaretti; video eki hiç çizilmiyordu.
void main() {
  const youtube = Attachment(
    id: 'yt',
    kind: AttachmentKind.video,
    fileName: 'Ön kol hareketleri',
    mimeType: 'video/youtube',
    webUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    pinHeight: 220,
  );
  const image = Attachment(
    id: 'img',
    kind: AttachmentKind.image,
    fileName: 'a.jpg',
    mimeType: 'image/jpeg',
  );
  const video = Attachment(
    id: 'vid',
    kind: AttachmentKind.video,
    fileName: 'v.mp4',
    mimeType: 'video/mp4',
  );
  const pdf = Attachment(
    id: 'pdf',
    kind: AttachmentKind.pdf,
    fileName: 'rapor.pdf',
    mimeType: 'application/pdf',
    bubbles: [
      PageBubble(id: 'b1', page: 1, x: .2, y: .2, text: 'bak'),
      PageBubble(id: 'b2', page: 2, x: .5, y: .5, text: 'düzelt'),
    ],
  );
  const audio = Attachment(
    id: 'aud',
    kind: AttachmentKind.audio,
    fileName: 'kayit.m4a',
    mimeType: 'audio/mp4',
  );

  group('CardMediaPlan', () {
    test('üste sabitli medya kartın KAPAĞI olur, öbürleri karo', () {
      final plan = CardMediaPlan.of(
        const Note(
          id: 'n',
          type: NoteType.text,
          attachments: [image, youtube, video],
        ),
      );
      expect(plan.hero?.id, 'yt');
      expect([for (final a in plan.strip) a.id], ['img', 'vid']);
    });

    test('tek görsel/video kapak olur; çok görselde kapak yok, karolar var', () {
      expect(
        CardMediaPlan.of(
          const Note(id: 'n', type: NoteType.text, attachments: [video]),
        ).hero?.id,
        'vid',
      );
      final many = CardMediaPlan.of(
        const Note(id: 'n', type: NoteType.text, attachments: [image, video]),
      );
      expect(many.hero, isNull);
      expect(many.strip, hasLength(2));
    });

    test('balonlu (belge) not: belge kartı + balon sayısı', () {
      final plan = CardMediaPlan.of(
        const Note(id: 'n', type: NoteType.pdf, attachments: [pdf, video]),
      );
      expect(plan.documentNote, isTrue);
      expect(plan.heroDocument?.id, 'pdf');
      // Belge notunda video kapak OLMAZ (belge önde), karo olur.
      expect(plan.hero, isNull);
      expect([for (final a in plan.strip) a.id], ['vid']);
      expect(plan.bubbleCount, 2);
      // Balonlu notun belgesi KAPAK olur (kartın tepesinde, kenardan
      // kenara); sıradan notun belge eki kapak olmaz.
      expect(plan.cover?.id, 'pdf');
      expect(
        CardMediaPlan.of(
          const Note(id: 'n', type: NoteType.text, attachments: [pdf]),
        ).cover,
        isNull,
      );
    });

    test('ses ve zemin görseli', () {
      final plan = CardMediaPlan.of(
        const Note(
          id: 'n',
          type: NoteType.text,
          attachments: [image, audio],
          backgroundImageId: 'img',
        ),
      );
      expect(plan.hero, isNull, reason: 'zemin görseli ek sayılmaz');
      expect(plan.audioCount, 1);
      expect(plan.isEmpty, isFalse);
    });

    test('kart yükseklik tahmini medyayı sayar', () {
      const base = Note(id: 'n', type: NoteType.text, title: 'Başlık');
      final withVideo = Note(
        id: 'n',
        type: NoteType.text,
        title: 'Başlık',
        attachments: const [youtube],
      );
      expect(
        estimateNoteCardHeight(withVideo, 190) -
            estimateNoteCardHeight(base, 190),
        greaterThan(90),
      );
    });
  });

  group('NoteCard', () {
    late SharedPreferences prefs;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    Future<void> pump(WidgetTester tester, Note note) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('tr'),
            home: Scaffold(
              body: SizedBox(width: 200, child: NoteCard(note: note)),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('sabitli YouTube videosu kartta kapak olarak görünür', (
      tester,
    ) async {
      await pump(
        tester,
        Note(
          id: 'n',
          type: NoteType.text,
          title: 'Boş Not Başlığı',
          attachments: const [youtube],
          updatedAt: DateTime(2026, 10, 15),
        ),
      );
      expect(find.byType(CardHeroMedia), findsOneWidget);
      expect(find.text('Ön kol hareketleri'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('balonlu PDF notu rozetle ayırt edilir', (tester) async {
      await pump(
        tester,
        Note(
          id: 'n',
          type: NoteType.pdf,
          title: 'Rapor',
          attachments: const [pdf],
          updatedAt: DateTime(2026, 10, 15),
        ),
      );
      expect(find.text('BALONLU PDF'), findsOneWidget);
      expect(find.text('rapor.pdf'), findsOneWidget);
      expect(find.text('2 balon'), findsOneWidget);
      expect(tester.takeException(), isNull);
      // Belge kapağı başlığın ÜSTÜNDE (2026-10-15 toparlaması: belge
      // sayfa notlarının altında küçük bir kutuda kalıyordu).
      expect(find.byType(CardDocumentCover), findsOneWidget);
      expect(
        tester.getTopLeft(find.byType(CardDocumentCover)).dy,
        lessThan(tester.getTopLeft(find.text('Rapor')).dy),
      );
    });
  });
}
