import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart' show Uint8List;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/web_file_drop.dart';
import 'package:notlar/features/notes/data/share_intake.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/presentation/add_catalog.dart';
import 'package:notlar/features/notes/presentation/editor/attach_sheet.dart';
import 'package:notlar/features/notes/presentation/file_use_sheet.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// TUTARLILIK Faz 41: "+" paneli ve Ekle levhası tek katalogdan; dışarıdan gelen
/// dosya aynı akıştan.
void main() {
  late AppLocalizations l10n;
  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('tr'));
  });

  Map<String, AddEntry> byId(AddContext c, {bool web = false}) => {
    for (final e in addCatalog(l10n, c, web: web)) e.id: e,
  };

  test('aynı iş iki yüzeyde aynı ad, simge, grup', () {
    final quick = byId(AddContext.newNote);
    final attach = byId(AddContext.inNote);
    const same = {
      'checklist': 'list-item',
      'draw': 'handwriting',
      'drawing': 'drawing',
      'photo': 'camera',
      'video': 'video',
      'file': 'any-file',
      'youtube': 'youtube',
    };
    same.forEach((q, a) {
      expect(attach[a]!.label, quick[q]!.label, reason: a);
      expect(attach[a]!.icon, quick[q]!.icon, reason: a);
      expect(attach[a]!.group, quick[q]!.group, reason: a);
    });
    // "Metin" tek farklı ad, simge ve grup yine ortak.
    expect(attach['text-block']!.icon, quick['text']!.icon);
    expect(attach['text-block']!.group, quick['text']!.group);
  });

  test('kalem kapıları farkı adında söyler, Kalem grubunda', () {
    final attach = byId(AddContext.inNote);
    expect(attach['handwriting']!.label, 'Sayfaya yaz (kalem)');
    expect(attach['drawing']!.label, 'Ayrı çizim (görsel)');
    expect(attach['handwriting']!.group, AddGroup.pen);
    expect(attach['drawing']!.group, AddGroup.pen);
  });

  test('grup sırası her yüzeyde sabit, ses kaydı Kamera değil Ses', () {
    for (final c in AddContext.values) {
      final order = [for (final e in addCatalog(l10n, c)) e.group.index];
      expect(order, [...order]..sort(), reason: c.name);
    }
    expect(byId(AddContext.inNote)['audio']!.group, AddGroup.sound);
  });

  test('alt küme: not içine özgü olanlar yeni notta yok, tersi de', () {
    final quick = byId(AddContext.newNote);
    final attach = byId(AddContext.inNote);
    expect(quick.keys, containsAll(['text', 'checklist', 'ordered']));
    expect(quick.keys, isNot(contains('image')));
    expect(attach.keys, isNot(contains('template')));
    // Şablon yalnız yeni not işi: levhada başlığı da çıkmaz.
    expect(attach.values.map((e) => e.group), isNot(contains(AddGroup.template)));
  });

  test('web: kamera ve ses kaydı not içinde düşer', () {
    final web = byId(AddContext.inNote, web: true);
    for (final id in ['camera', 'video', 'audio']) {
      expect(web.keys, isNot(contains(id)), reason: id);
    }
  });

  Widget host(Widget child) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    locale: const Locale('tr'),
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );

  testWidgets('Ekle levhası tek karo; belge notunda Yaz grubu yok', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(411 * 3, 891 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    String? picked;
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async => picked = await showAttachSheet(
              context,
              pageNote: true,
              copiedAttachmentName: 'rapor.pdf',
            ),
            child: const Text('aç'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();
    expect(find.text('Yaz'), findsNothing);
    expect(find.text('Kalem'), findsOneWidget);
    expect(find.byType(AddTile), findsWidgets);
    // Yapıştırılacak ekin adı karoda görünür.
    expect(find.text('rapor.pdf'), findsOneWidget);
    // Kalemin uzun adları iki geniş karoya sığar (taşma testi kırardı).
    final long = tester.widget<Text>(find.text('Sayfaya yaz (kalem)'));
    expect(long.maxLines, 2, reason: 'telefonda kesilmesin');
    await tester.tap(find.text('Ayrı çizim (görsel)'));
    await tester.pumpAndSettle();
    expect(picked, 'drawing');
  });

  testWidgets('dosya levhası not içinde başlık sormaz, ek diliyle konuşur', (
    tester,
  ) async {
    FileUseChoice? picked;
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async => picked = await showFileUseSheet(
              context,
              kind: PickedFileKind.image,
              names: const ['g.png'],
              inNote: true,
            ),
            child: const Text('aç'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('file-use-summary')), findsOneWidget);
    expect(find.byKey(const ValueKey('file-use-title')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('file-use-imageFile')));
    await tester.pumpAndSettle();
    expect(picked?.use, FileUse.imageFile);
  });

  test('not içi kullanımlar; web sesinde yeni not seçeneği yok', () {
    expect(fileUsesFor(PickedFileKind.image, inNote: true), [
      FileUse.classic,
      FileUse.imageFile,
    ]);
    expect(fileUsesFor(PickedFileKind.audio, inNote: true, web: true), [
      FileUse.audio,
      FileUse.transcribe,
    ]);
    expect(fileUsesFor(PickedFileKind.audio, web: true), isEmpty);
  });

  test('bırakılan dosya en son açılan yüzeye gider, kapanınca geri döner', () {
    final calls = <String>[];
    final file = [XFile.fromData(Uint8List(1), name: 'a.png')];
    final stopHome = addFileDropHandler((_) => calls.add('ana'));
    final stopNote = addFileDropHandler((_) => calls.add('not'));
    dispatchFileDrop(file);
    expect(calls, ['not']);
    stopNote();
    dispatchFileDrop(file);
    expect(calls, ['not', 'ana']);
    stopHome();
    dispatchFileDrop(file);
    expect(calls, ['not', 'ana']);
  });

  test('paylaşımla gelen yüzen ek ipucuyla açılır, şerit eki açılmaz', () {
    Attachment att(String id, AttachmentKind kind, {bool asFile = false}) =>
        Attachment(
          id: id,
          kind: kind,
          fileName: id,
          mimeType: '',
          asFile: asFile,
        );
    expect(sharePlacementQuery(const []), '');
    expect(
      sharePlacementQuery([att('s', AttachmentKind.audio)]),
      '',
      reason: 'ses sayfada yüzmez',
    );
    expect(
      sharePlacementQuery([
        att('a', AttachmentKind.image),
        att('b', AttachmentKind.image),
        att('c', AttachmentKind.image, asFile: true),
      ]),
      '?place=b',
    );
  });
}
