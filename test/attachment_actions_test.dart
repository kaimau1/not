import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/presentation/editor/attachment_actions.dart';

/// F40.1: tek ek menüsü. Sıra tek yerde; yüzeyler yalnız kendi çubuğunda
/// görünen işi düşürür. F40.2 (K6): eşanlamlı metinler yok.
void main() {
  const image = Attachment(
    id: 'i',
    kind: AttachmentKind.image,
    fileName: 'a.jpg',
    mimeType: 'image/jpeg',
  );
  const video = Attachment(
    id: 'v',
    kind: AttachmentKind.video,
    fileName: 'a.mp4',
    mimeType: 'video/mp4',
  );
  const audio = Attachment(
    id: 's',
    kind: AttachmentKind.audio,
    fileName: 'a.m4a',
    mimeType: 'audio/mp4',
  );
  const youtube = Attachment(
    id: 'y',
    kind: AttachmentKind.video,
    fileName: 'yt',
    mimeType: 'video/mp4',
    webUrl: 'https://youtu.be/x',
  );

  const all = AttachmentCaps(
    viewRow: true,
    edit: true,
    transcribe: true,
    extractText: true,
    videoToNote: true,
    copy: true,
    selectMany: true,
    saveAs: true,
    openExternal: true,
    remove: true,
  );

  test('her görünüm × tür: katalog sırası korunur', () {
    for (final a in [image, video, audio, youtube]) {
      for (final s in AttachmentSurface.values) {
        final list = attachmentActionsFor(a, s, all);
        final sorted = [...list]..sort((x, y) => x.index - y.index);
        expect(list, sorted, reason: '${a.id} ${s.name}');
      }
    }
  });

  test('sıra planla aynı', () {
    expect(attachmentActionsFor(image, AttachmentSurface.strip, all), const [
      AttachmentAction.open,
      AttachmentAction.view,
      AttachmentAction.edit,
      AttachmentAction.transcribe,
      AttachmentAction.extractText,
      AttachmentAction.copy,
      AttachmentAction.selectMany,
      AttachmentAction.share,
      AttachmentAction.saveAs,
      AttachmentAction.remove,
    ]);
  });

  test('açıklama yalnız görselde; yüzende çubukta, sağ tıkta menüde', () {
    const caps = AttachmentCaps(caption: true);
    expect(
      attachmentActionsFor(video, AttachmentSurface.pinned, caps),
      isNot(contains(AttachmentAction.caption)),
    );
    expect(
      attachmentActionsFor(image, AttachmentSurface.pinned, caps),
      contains(AttachmentAction.caption),
    );
    expect(
      attachmentActionsFor(image, AttachmentSurface.floating, caps),
      isNot(contains(AttachmentAction.caption)),
    );
    expect(
      attachmentActionsFor(image, AttachmentSurface.contextMenu, caps),
      contains(AttachmentAction.caption),
    );
    expect(
      attachmentActionsFor(
        image,
        AttachmentSurface.contextMenu,
        const AttachmentCaps(remove: true),
      ),
      contains(AttachmentAction.remove),
    );
  });

  test('çubukta görünen menüde tekrarlanmaz', () {
    final floating = attachmentActionsFor(
      image,
      AttachmentSurface.floating,
      all,
    );
    expect(floating, isNot(contains(AttachmentAction.open)));
    expect(floating, isNot(contains(AttachmentAction.remove)));
    final pinned = attachmentActionsFor(image, AttachmentSurface.pinned, all);
    expect(pinned, isNot(contains(AttachmentAction.open)));
    expect(pinned, contains(AttachmentAction.remove));
  });

  test('türe özgü: YouTube bağlantı, dosya işi yok; ses tam ekran yok', () {
    final yt = attachmentActionsFor(youtube, AttachmentSurface.strip, all);
    expect(
      yt,
      containsAll([AttachmentAction.copyLink, AttachmentAction.openExternal]),
    );
    expect(yt, isNot(contains(AttachmentAction.copy)));
    expect(yt, isNot(contains(AttachmentAction.saveAs)));
    expect(yt, isNot(contains(AttachmentAction.videoToNote)));
    final sound = attachmentActionsFor(audio, AttachmentSurface.strip, all);
    expect(sound, isNot(contains(AttachmentAction.open)));
    expect(
      attachmentActionsFor(video, AttachmentSurface.strip, all),
      contains(AttachmentAction.videoToNote),
    );
    expect(
      attachmentActionsFor(video, AttachmentSurface.strip, all),
      isNot(contains(AttachmentAction.extractText)),
    );
  });

  test('K6: görünüm eşanlamlıları metinlerde yok', () {
    for (final f in ['lib/l10n/app_tr.arb', 'lib/l10n/app_en.arb']) {
      final keys = (jsonDecode(File(f).readAsStringSync()) as Map).keys;
      for (final k in [
        'moveImageToAttachments',
        'unpinMedia',
        'pinnedEmbedOnPage',
        'embedImportToNote',
      ]) {
        expect(keys, isNot(contains(k)), reason: '$f $k');
      }
    }
  });
}
