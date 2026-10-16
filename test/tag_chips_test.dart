import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/attachment_tag.dart';
import 'package:notlar/core/utils/link_text.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/editor/embed_sheet.dart';
import 'package:notlar/features/notes/presentation/editor/tag_chips.dart';
import 'package:notlar/features/notes/presentation/editor/text_wrap.dart';

/// Gömülü yazının ÇİP görünümü (kullanıcı isteği 2026-10-15: "ek gömmenin
/// tüm akışı ve görüntüsü yenilenmeli").
void main() {
  const red = Color(0xFFD32F2F);

  group('linkSpans çip kipi', () {
    test('ataç saydam, ad türün renginde, alt çizgi YOK', () {
      final text = 'bak ${attachmentTagFor('rapor')} sonra';
      final spans = linkSpans(
        text,
        const TextStyle(color: Colors.black),
        Colors.blue,
        attachmentNames: const ['rapor'],
        tagChipColors: const {'rapor': red},
      );
      final tag = spans[1] as TextSpan;
      final prefix = tag.children![0] as TextSpan;
      final label = tag.children![1] as TextSpan;
      expect(prefix.text, kAttachmentTagPrefix);
      expect(prefix.style?.color?.a, 0);
      expect(label.text, 'rapor');
      expect(label.style?.color, red);
      expect(label.style?.decoration, isNot(TextDecoration.underline));
      // Çizilen metin ham metinle BİREBİR aynı (konumlar kaymaz).
      expect(TextSpan(children: spans).toPlainText(), text);
    });

    test('renk verilmeyen ad eski görünümde kalır (kırmızı, altı çizili)', () {
      final spans = linkSpans(
        attachmentTagFor('x.pdf'),
        const TextStyle(),
        Colors.blue,
        attachmentNames: const ['x.pdf'],
        tagChipColors: const {'başka': red},
      );
      final tag = spans.single as TextSpan;
      final label = tag.children![1] as TextSpan;
      expect(label.style?.decoration, TextDecoration.underline);
    });
  });

  test('türün görünümü: bağ etiketi dosya adını ezer, koyu temada açılır', () {
    const pdf = Attachment(
      id: 'p',
      kind: AttachmentKind.pdf,
      fileName: 'rapor.pdf',
      mimeType: 'application/pdf',
    );
    const video = Attachment(
      id: 'v',
      kind: AttachmentKind.video,
      fileName: 'v.mp4',
      mimeType: 'video/mp4',
    );
    const note = Note(
      id: 'n',
      type: NoteType.text,
      attachments: [pdf, video],
      tagLinks: [NoteTagLink(label: 'rapor.pdf', attachmentId: 'v')],
    );
    final looks = embedTagLooks(note);
    expect(looks['v.mp4']?.icon, Icons.videocam_outlined);
    expect(looks['rapor.pdf']?.icon, Icons.videocam_outlined);
    expect(
      embedTagLooks(note, dark: true)['v.mp4']!.color.computeLuminance(),
      greaterThan(looks['v.mp4']!.color.computeLuminance()),
    );
    expect(embedTagLooks(const Note(id: 'e', type: NoteType.text)), isEmpty);
  });

  testWidgets('alanın üstüne çip ve türün rozeti çizilir', (tester) async {
    final controller = WrapTextController()
      ..text = 'bak ${attachmentTagFor('rapor')} sonra'
      ..attachmentNames = const ['rapor']
      ..tagChipColors = const {'rapor': red};
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AttachmentTagChips(
            controller: controller,
            looks: const {'rapor': TagLook(Icons.picture_as_pdf_outlined, red)},
            child: TextField(controller: controller, maxLines: null),
          ),
        ),
      ),
    );
    final box = tester.renderObject(
      find
          .descendant(
            of: find.byType(AttachmentTagChips),
            matching: find.byType(CustomPaint),
          )
          .first,
    );
    expect(
      box,
      paints
        ..rrect(color: red.withValues(alpha: 0.10))
        ..rrect(color: red.withValues(alpha: 0.5))
        ..rrect(color: red),
    );
  });

  testWidgets('ilk gömmede alan YENİDEN KURULMAZ (odak/klavye korunur)', (
    tester,
  ) async {
    final controller = WrapTextController()..text = 'kelime';
    addTearDown(controller.dispose);
    final focus = FocusNode();
    addTearDown(focus.dispose);
    Widget host(Map<String, TagLook> looks) => MaterialApp(
      home: Scaffold(
        body: AttachmentTagChips(
          controller: controller,
          looks: looks,
          child: TextField(controller: controller, focusNode: focus),
        ),
      ),
    );
    await tester.pumpWidget(host(const {}));
    focus.requestFocus();
    await tester.pump();
    final state = tester.state(find.byType(EditableText));
    await tester.pumpWidget(
      host(const {'kelime': TagLook(Icons.image_outlined, red)}),
    );
    expect(identical(tester.state(find.byType(EditableText)), state), isTrue);
    expect(focus.hasFocus, isTrue);
  });
}
