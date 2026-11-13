import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/doc_picker.dart';
import 'package:notlar/core/utils/markdown.dart';
import 'package:notlar/features/notes/data/attachment_save.dart';
import 'package:notlar/features/notes/data/import_service.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/file_use_sheet.dart';
import 'package:notlar/features/notes/presentation/viewers/transcript_screen.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// P54 (kullanıcı 2026-11-12: ".md desteklenmeli notlarda"): .md dosyası
/// her giriş yolunda nota/ek olarak okunur gelir.
void main() {
  test('md dosyası adından ya da MIME türünden tanınır', () {
    expect(isMarkdownFile('Notlar.MD'), isTrue);
    expect(isMarkdownFile('a.markdown'), isTrue);
    expect(isMarkdownFile('/cache/dosya', mime: 'text/x-markdown'), isTrue);
    expect(isMarkdownFile('a.txt', mime: 'text/plain'), isFalse);
  });

  test('okunur görünüm: başlık, madde, onay kutusu, bağlantı, satır içi', () {
    const md = '# Başlık\n'
        '- [ ] süt\n'
        '- [x] ekmek\n'
        '* madde **kalın** ve __alt__\n'
        '> alıntı\n'
        'Bkz. [site](https://a.b) ve `kod`';
    expect(
      markdownReadable(md),
      'Başlık\n'
      '☐ süt\n'
      '☑ ekmek\n'
      '• madde kalın ve alt\n'
      'alıntı\n'
      'Bkz. site (https://a.b) ve kod',
    );
  });

  test('taslak: işaretsiz onay listesi liste notu olur', () {
    final d = markdownNoteDraft('alisveris.md', '# Market\n- [ ] süt\n- [ ] yumurta')!;
    expect(d.type, NoteType.checklist);
    expect(d.title, 'Market');
    expect(d.items, ['süt', 'yumurta']);
    expect(d.text, '☐ süt\n☐ yumurta');
  });

  test('taslak: işaretli madde kaybolmasın diye metin notu (☑ korunur)', () {
    final d = markdownNoteDraft('x.md', '- [x] bitti\n- [ ] kaldı')!;
    expect(d.type, NoteType.text);
    expect(d.title, 'x');
    expect(d.body, '☑ bitti\n☐ kaldı');
  });

  test('taslak: düz metin notu, satır içi biçim uygulamanın işaretine döner', () {
    final d = markdownNoteDraft('a.md', '# T\n\nmerhaba __dünya__ *ince*')!;
    expect(d.type, NoteType.text);
    expect(d.body, 'merhaba **dünya** _ince_');
    expect(d.text, d.body);
  });

  test('not içi ek: .md metin eki olur, adı .md kalır', () {
    final a = markdownAttachment('plan.md', utf8.encode('# Plan\n- bir'));
    expect(a.kind, AttachmentKind.text);
    expect(a.fileName, 'plan.md');
    expect(a.mimeType, 'text/markdown');
    expect(a.text, '# Plan\n- bir');
    expect(saveAsFileName(a), 'plan.md');
  });

  test('dosya seçici (Android + web) .md kabul ediyor', () {
    expect(PickedFileKind.allExtensions, containsAll(['md', 'markdown']));
    final mimes = DocPicker.mimeTypesOf(
      XTypeGroup(extensions: PickedFileKind.allExtensions),
    );
    expect(mimes, contains('text/markdown'));
  });

  test('Android "birlikte aç" .md dosyalarında Notlar çıkar', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final viewFilters = RegExp(
      r'<intent-filter>(?:(?!</intent-filter>).)*?action\.VIEW(?:(?!</intent-filter>).)*?</intent-filter>',
      dotAll: true,
    ).allMatches(manifest).map((m) => m[0]!).toList();
    bool has(String s) => viewFilters.any((f) => f.contains(s));
    expect(has('android:mimeType="text/markdown"'), isTrue);
    expect(has('android:mimeType="text/x-markdown"'), isTrue);
    expect(has(r'.*\\.md"'), isTrue);
  });

  test('P54b: .md\'den yeni not başlığı # başlık, yoksa dosya adı', () {
    expect(markdownTitle('plan.md', '\n# Haftalık plan\n- bir'), 'Haftalık plan');
    expect(markdownTitle('yapilacak.markdown', '- bir'), 'yapilacak');
    expect(markdownTitle('a.md', 'düz yazı\n# sonra'), 'a');
  });

  test('P54b: yeni not gövdesi başlık satırını tekrar etmez', () {
    expect(markdownBodyWithoutTitle('Plan\nbir\niki', 'Plan'), 'bir\niki');
    expect(markdownBodyWithoutTitle('bir\niki', 'Plan'), 'bir\niki');
  });

  testWidgets('P54b: .md okuma ekranının başlığı dosya adı, "Transkript" değil', (
    tester,
  ) async {
    final a = markdownAttachment('plan.md', utf8.encode('# Plan\n- bir'));
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('tr'),
          home: TranscriptScreen(transcript: a, onCreateNote: (_) async {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final appBar = find.byType(AppBar);
    expect(
      find.descendant(of: appBar, matching: find.text('plan.md')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: appBar, matching: find.text('Markdown')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: appBar, matching: find.text('Transkript')),
      findsNothing,
    );
  });
}
