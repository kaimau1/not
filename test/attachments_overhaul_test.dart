import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/presentation/editor/attachment_actions.dart';
import 'package:notlar/features/notes/presentation/editor/attachment_strip.dart';
import 'package:notlar/features/notes/presentation/editor/note_images.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('resolveRenamedAttachmentName uzantıyı korur ve boş adı reddeder', () {
    expect(
      resolveRenamedAttachmentName('  yeni_rapor  ', 'eski.pdf'),
      'yeni_rapor.pdf',
    );
    expect(resolveRenamedAttachmentName('ozel.txt', 'eski.pdf'), 'ozel.txt');
    expect(resolveRenamedAttachmentName('   ', 'eski.pdf'), isEmpty);
  });

  test('attachmentActionsFor üç yüzeyde de yeniden adlandırmayı sunar', () {
    const a = Attachment(
      id: 'a1',
      kind: AttachmentKind.pdf,
      fileName: 'belge.pdf',
      mimeType: 'application/pdf',
    );
    for (final s in [
      AttachmentSurface.strip,
      AttachmentSurface.floating,
      AttachmentSurface.pinned,
    ]) {
      final actions = attachmentActionsFor(
        a,
        s,
        const AttachmentCaps(rename: true),
      );
      expect(actions, contains(AttachmentAction.rename), reason: s.name);
    }
  });

  testWidgets(
    'ek yeniden adlandırma penceresi uzantıyı koruyarak ad döndürür',
    (tester) async {
      String? renamed;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('tr'),
          home: Scaffold(
            body: Builder(
              builder: (ctx) => TextButton(
                onPressed: () async {
                  renamed = await showRenameAttachmentSheet(
                    ctx,
                    currentName: 'fatura_2026.pdf',
                  );
                },
                child: const Text('ADLANDIR'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('ADLANDIR'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('attachment-rename-input')),
        'kira_makbuzu',
      );
      await tester.tap(find.byKey(const ValueKey('attachment-rename-save')));
      await tester.pumpAndSettle();
      expect(renamed, 'kira_makbuzu.pdf');
    },
  );

  testWidgets('2+ ek varken alt şeritte "Tümü" açılır ve tüm ekleri listeler', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final sp = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(sp)],
    );
    addTearDown(container.dispose);

    Attachment? renamedTarget;
    final items = [
      const Attachment(
        id: 'a1',
        kind: AttachmentKind.pdf,
        fileName: 'bir.pdf',
        mimeType: 'application/pdf',
        sizeBytes: 2048,
      ),
      const Attachment(
        id: 'a2',
        kind: AttachmentKind.text,
        fileName: 'iki.txt',
        mimeType: 'text/plain',
        text: 'not metni',
      ),
    ];

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('tr'),
          home: Scaffold(
            body: AttachmentStrip(
              attachments: items,
              onRemove: (_) {},
              expanded: true,
              onToggle: () {},
              onRename: (a) => renamedTarget = a,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final allBtn = find.byKey(const ValueKey('strip-all-attachments'));
    expect(allBtn, findsOneWidget);
    await tester.tap(allBtn);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('all-attachments-item-a1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('all-attachments-item-a2')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('all-attachments-rename-a1')));
    await tester.pumpAndSettle();
    expect(renamedTarget?.id, 'a1');
  });

  testWidgets(
    'yüzen ek araç çubuğunda S/M/L boyut, yatay hiza ve paylaşım çalışır',
    (tester) async {
      tester.view.physicalSize = const Size(420, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      Attachment latest = const Attachment(
        id: 'g1',
        kind: AttachmentKind.text,
        fileName: 'metin.txt',
        mimeType: 'text/plain',
        text: 'örnek içerik',
        x: 0.0,
        pageY: 20,
        displayWidth: 0.5,
      );
      Attachment? shared;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('tr'),
            home: Scaffold(
              body: NotePageCanvas(
                minHeight: 600,
                images: [latest],
                onRemove: (_) {},
                onChanged: (next) => setState(() => latest = next),
                onShare: (a) => shared = a,
                onRename: (_) {},
                child: const SizedBox(width: 420, height: 600),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('page-image-g1')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('floating-size-s')));
      await tester.pumpAndSettle();
      expect(latest.displayWidth, closeTo(0.35, 0.001));

      await tester.tap(find.byKey(const ValueKey('floating-align')));
      await tester.pumpAndSettle();
      expect(latest.x, closeTo((1 - 0.35) / 2, 0.01));

      await tester.tap(find.byKey(const ValueKey('floating-share')));
      await tester.pumpAndSettle();
      expect(shared?.id, 'g1');
    },
  );
}
