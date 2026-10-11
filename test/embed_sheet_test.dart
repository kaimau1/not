import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/presentation/editor/embed_sheet.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// Gömme yeniden tasarımı: tek levhada yeni ekle (PDF/görsel/video/YouTube)
/// + nottaki ekler; gömülü yazının önizleme kartı.
void main() {
  const pdf = Attachment(
    id: 'p',
    kind: AttachmentKind.pdf,
    fileName: 'rapor.pdf',
    mimeType: 'application/pdf',
  );

  Widget host(void Function(BuildContext) onTap) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('tr'),
    home: Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () => onTap(context),
            child: const Text('aç'),
          ),
        ),
      ),
    ),
  );

  testWidgets('seçici: yeni video seçeneği ve var olan ek döner', (
    tester,
  ) async {
    EmbedPick? result;
    await tester.pumpWidget(
      host((context) async {
        result = await showEmbedPicker(
          context,
          label: 'kelime',
          attachments: const [pdf],
        );
      }),
    );
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();
    expect(find.textContaining('kelime'), findsOneWidget);
    expect(find.byKey(const ValueKey('embed-new-video')), findsOneWidget);
    expect(find.byKey(const ValueKey('embed-new-youtube')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('embed-new-video')));
    await tester.pumpAndSettle();
    expect(result?.create, 'video');

    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('embed-existing-p')));
    await tester.pumpAndSettle();
    expect(result?.attachment?.id, 'p');
  });

  testWidgets('önizleme kartı: değiştir ve kaldır düğmeleri çalışır', (
    tester,
  ) async {
    var unlinked = false;
    var replaced = false;
    const image = Attachment(
      id: 'g',
      kind: AttachmentKind.image,
      fileName: 'g.jpg',
      mimeType: 'image/jpeg',
    );
    await tester.pumpWidget(
      host(
        (context) => showEmbedPreview(
          context,
          attachment: image,
          label: 'kelime',
          onOpen: () {},
          onReplace: () => replaced = true,
          onUnlink: () => unlinked = true,
        ),
      ),
    );
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();
    expect(find.text('kelime'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('embed-replace')));
    await tester.pumpAndSettle();
    expect(replaced, isTrue);
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('embed-unlink')));
    await tester.pumpAndSettle();
    expect(unlinked, isTrue);
  });
}
