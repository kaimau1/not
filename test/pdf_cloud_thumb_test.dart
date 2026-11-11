import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/data/attachment_thumb.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/presentation/note_card_media.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// F65.5: PDF'in ilk sayfa önizlemesi de buluta (Storage `thumbs/`) gider;
/// dosyası bu cihazda olmayan kart (web, diğer cihaz) indirmeden çizer.
void main() {
  test('önizleme görsel VE PDF için üretilir', () {
    expect(wantsCloudThumb(AttachmentKind.image), isTrue);
    expect(wantsCloudThumb(AttachmentKind.pdf), isTrue);
    expect(wantsCloudThumb(AttachmentKind.video), isFalse);
    expect(wantsCloudThumb(AttachmentKind.audio), isFalse);
  });

  testWidgets('dosyası olmayan PDF kartı bulut önizlemesini çizer', (
    tester,
  ) async {
    const pdf = Attachment(
      id: 'p1',
      kind: AttachmentKind.pdf,
      fileName: 'rapor.pdf',
      mimeType: 'application/pdf',
      driveId: 'd1',
      thumbUrl: 'https://example.invalid/thumbs/p1.jpg',
    );
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('tr'),
        home: Scaffold(
          body: SizedBox(
            width: 240,
            child: CardDocumentCover(document: pdf, bubbleCount: 0),
          ),
        ),
      ),
    );
    expect(find.byType(CachedNetworkImage), findsOneWidget);
  });
}
