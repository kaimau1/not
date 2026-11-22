import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/app/theme/app_palette.dart';
import 'package:notlar/app/theme/app_theme.dart';
import 'package:notlar/app/theme/note_themes.dart';
import 'package:notlar/core/utils/color_contrast.dart';
import 'package:notlar/core/utils/note_fonts.dart';
import 'package:notlar/features/notes/domain/archive_paper.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/editor/editor_chrome_palette.dart';
import 'package:notlar/features/notes/presentation/editor/notebook_paper.dart';

import 'support/editor_harness.dart';

void main() {
  setUpAll(disableFontRuntimeFetching);
  tearDown(BgImageTone.clearCache);

  group('EditorChromePalette — kontrast ve tam tema uyumu', () {
    void expectChromeReadable(
      EditorChromePalette chrome,
      String label, {
      bool testWorstPhotoBacking = false,
    }) {
      // Yarı saydam kapsülü gerçek arka planla (ya da fotoğraf için en kötü
      // siyah ve beyaz piksellerle) karıştırıp kontrastı doğrula.
      final backings = testWorstPhotoBacking
          ? const [Colors.black, Colors.white]
          : [chrome.pageSurface];
      for (final bg in backings) {
        final pageBarBg = Color.alphaBlend(chrome.pageBarFill, bg);
        final pagePillBg = Color.alphaBlend(chrome.pageBarPillFill, pageBarBg);
        final toolBg = Color.alphaBlend(chrome.toolCapsuleFill, bg);
        final aiBg = Color.alphaBlend(chrome.aiCapsuleFill, bg);
        expect(
          contrastRatio(chrome.pageBarIcon, pageBarBg),
          greaterThanOrEqualTo(4.5),
          reason: '$label sayfa çubuğu simgesi ($bg)',
        );
        expect(
          contrastRatio(chrome.pageBarAccent, pagePillBg),
          greaterThanOrEqualTo(4.5),
          reason: '$label sayfa hapı ($bg)',
        );
        if (chrome.barInk != null) {
          expect(
            contrastRatio(chrome.barInk!, toolBg),
            greaterThanOrEqualTo(4.5),
            reason: '$label sol araç kapsülü ($bg)',
          );
        }
        expect(
          contrastRatio(chrome.aiIconColor, aiBg),
          greaterThanOrEqualTo(4.5),
          reason: '$label sağ AI kapsülü ($bg)',
        );
        if (chrome.topBarPills) {
          final topBg = Color.alphaBlend(chrome.topPillFill, bg);
          expect(
            contrastRatio(chrome.topPillInk, topBg),
            greaterThanOrEqualTo(4.5),
            reason: '$label üst çubuk hapı ($bg)',
          );
        } else {
          expect(
            contrastRatio(chrome.topBarIconColor, chrome.statusBarGround),
            greaterThanOrEqualTo(4.5),
            reason: '$label üst çubuk simgesi',
          );
        }
      }
    }

    test(
      'tüm 8 not teması × açık/koyu × çizgili/bloknot okunur ve temayla uyumlu',
      () {
        for (final brightness in Brightness.values) {
          final outer = AppTheme.of(ThemeFamily.sage, brightness);
          for (final t in NoteThemes.all) {
            for (final paper in [ArchivePaper.lined, ArchivePaper.legal]) {
              final note = Note(
                id: 'n',
                type: NoteType.checklist,
                paged: true,
                archivePaper: paper,
                theme: t.id,
              );
              final chrome = EditorChromePalette.resolve(
                outerTheme: outer,
                note: note,
                hasBgImage: false,
              );
              expect(chrome.chromeSeeThrough, isTrue);
              expect(chrome.barInk, isNotNull, reason: '${t.id} $brightness');
              expect(chrome.dividerColor, isNull, reason: 'çizgili bant var');
              expectChromeReadable(chrome, '${t.id} $brightness ${paper.id}');
            }
          }
        }
      },
    );

    test('tüm 11 hazır renk + uç özel renkler × açık/koyu okunur', () {
      for (final brightness in Brightness.values) {
        final outer = AppTheme.of(ThemeFamily.sage, brightness);
        for (final c in NoteColor.values) {
          if (c == NoteColor.none) continue;
          for (final paper in [
            ArchivePaper.lined,
            ArchivePaper.legal,
            ArchivePaper.grid,
          ]) {
            final note = Note(
              id: 'n',
              type: NoteType.text,
              paged: true,
              archivePaper: paper,
              color: c,
            );
            final chrome = EditorChromePalette.resolve(
              outerTheme: outer,
              note: note,
              hasBgImage: false,
            );
            expect(chrome.barInk, isNotNull);
            expectChromeReadable(chrome, '$c $brightness ${paper.id}');
          }
        }
        // Açıkta kapkara, koyuda bembeyaz özel renk.
        for (final custom in const [
          0xFF000000,
          0xFFFFFFFF,
          0xFF1A0B1F,
          0xFFFFE57F,
        ]) {
          final note = Note(
            id: 'n',
            type: NoteType.text,
            paged: true,
            archivePaper: ArchivePaper.legal,
            customColor: custom,
          );
          final chrome = EditorChromePalette.resolve(
            outerTheme: outer,
            note: note,
            hasBgImage: false,
          );
          expectChromeReadable(
            chrome,
            'custom#${custom.toRadixString(16)} $brightness',
          );
        }
      }
    });

    test(
      'tüm 20 uygulama teması × açık/koyu × çizgili/kareli/bloknot okunur',
      () {
        for (final family in ThemeFamily.values) {
          for (final brightness in Brightness.values) {
            final outer = AppTheme.of(family, brightness);
            for (final paper in [
              ArchivePaper.lined,
              ArchivePaper.grid,
              ArchivePaper.legal,
            ]) {
              final note = Note(
                id: 'n',
                type: NoteType.checklist,
                paged: true,
                archivePaper: paper,
              );
              final chrome = EditorChromePalette.resolve(
                outerTheme: outer,
                note: note,
                hasBgImage: false,
              );
              expectChromeReadable(chrome, '$family $brightness ${paper.id}');
            }
          }
        }
      },
    );

    test('arka plan görseli: koyu, açık, orta gri ve iki tonlu fotoğrafta düğmeler kaybolmaz', () {
      final scenarios = <(String, Brightness, BgImageTone, double)>[
        (
          'açık temada koyu fotoğraf',
          Brightness.light,
          const BgImageTone(
            topColor: Color(0xFF0E1117),
            bottomColor: Color(0xFF141820),
            overallColor: Color(0xFF11151C),
            accentColor: Color(0xFF3E6BA8),
          ),
          0.9,
        ),
        (
          'koyu temada parlak beyaz fotoğraf',
          Brightness.dark,
          const BgImageTone(
            topColor: Color(0xFFF6F7F9),
            bottomColor: Color(0xFFEFF2F5),
            overallColor: Color(0xFFF3F5F8),
            accentColor: Color(0xFF5A8FB8),
          ),
          0.9,
        ),
        (
          'orta gri karmaşık fotoğraf',
          Brightness.light,
          const BgImageTone(
            topColor: Color(0xFF7B7B7B),
            bottomColor: Color(0xFF757575),
            overallColor: Color(0xFF787878),
            accentColor: Color(0xFF808080),
          ),
          0.85,
        ),
        (
          'üstü parlak gökyüzü, altı koyu orman',
          Brightness.light,
          const BgImageTone(
            topColor: Color(0xFFDCEEFF),
            bottomColor: Color(0xFF142416),
            overallColor: Color(0xFF3B5A42),
            accentColor: Color(0xFF2E7D32),
          ),
          0.85,
        ),
      ];

      for (final (name, brightness, tone, opacity) in scenarios) {
        final outer = AppTheme.of(ThemeFamily.sage, brightness);
        final note = Note(
          id: 'n',
          type: NoteType.checklist,
          paged: true,
          backgroundImageId: 'bg1',
          backgroundOpacity: opacity,
        );
        final chrome = EditorChromePalette.resolve(
          outerTheme: outer,
          note: note,
          hasBgImage: true,
          bgTone: tone,
        );
        expect(chrome.topBarPills, isTrue, reason: name);
        expect(chrome.chromeSeeThrough, isTrue, reason: name);
        expectChromeReadable(chrome, name, testWorstPhotoBacking: true);
      }

      // Üstü parlak, altı koyu fotoğrafta üst bant açık, alt kapsül koyu kalır.
      final split = EditorChromePalette.resolve(
        outerTheme: AppTheme.of(ThemeFamily.sage, Brightness.light),
        note: const Note(
          id: 'n',
          type: NoteType.checklist,
          paged: true,
          backgroundImageId: 'bg1',
          backgroundOpacity: 0.9,
        ),
        hasBgImage: true,
        bgTone: const BgImageTone(
          topColor: Color(0xFFEAF4FF),
          bottomColor: Color(0xFF0E1A10),
          overallColor: Color(0xFF203024),
          accentColor: Color(0xFF2E7D32),
        ),
      );
      expect(
        ThemeData.estimateBrightnessForColor(split.statusBarGround),
        Brightness.light,
      );
      expect(
        ThemeData.estimateBrightnessForColor(split.barPage),
        Brightness.dark,
      );
      expect(split.noteAccent, isNotNull);
      expect(split.paperAccent, isNotNull);
    });
  });

  group('Defter ekranı widget entegrasyonu', () {
    testWidgets(
      'çizilmiş tema (sakura) + çizgili defter: üst/alt çizgiler ve gül tonu',
      (tester) async {
        final note = Note(
          id: 'n',
          type: NoteType.checklist,
          title: 'Bahar',
          paged: true,
          theme: NoteThemes.sakura,
          updatedAt: DateTime(2026, 11, 22, 21, 5),
          items: const [NoteItem(id: '1', text: 'madde 1')],
        );
        await pumpEditor(tester, note);
        expect(
          find.ancestor(
            of: find.byType(Scaffold),
            matching: find.byType(NotebookPaper),
          ),
          findsOneWidget,
        );
        expect(
          find.ancestor(
            of: find.byType(BottomAppBar),
            matching: find.byType(NotebookRuledBand),
          ),
          findsOneWidget,
        );
        final pageBarColor =
            (tester
                        .widget<DecoratedBox>(
                          find.byKey(const ValueKey('page-bar-surface')),
                        )
                        .decoration
                    as BoxDecoration)
                .color!;
        // Sakura pembe tonu: kırmızı kanal yeşilden baskın.
        expect(pageBarColor.r, greaterThan(pageBarColor.g));
        await endEditor(tester);
        await tester.pump();
      },
    );

    testWidgets(
      'kareli defter + mavi not: tam ekran ızgara, ayrı alt satır bandı yok',
      (tester) async {
        const note = Note(
          id: 'n',
          type: NoteType.text,
          title: 'Kareli',
          paged: true,
          archivePaper: ArchivePaper.grid,
          color: NoteColor.blue,
        );
        await pumpEditor(tester, note);
        expect(
          find.ancestor(
            of: find.byType(Scaffold),
            matching: find.byType(NotebookPaper),
          ),
          findsOneWidget,
        );
        // Kareli kâğıtta ızgara zaten tam ekran çizildiği için ek NotebookRuledBand yok.
        expect(find.byType(NotebookRuledBand), findsNothing);
        final toolColor =
            (tester
                        .widget<DecoratedBox>(
                          find.byKey(const ValueKey('editor-tool-capsule')),
                        )
                        .decoration
                    as BoxDecoration)
                .color!;
        expect(toolColor.b, greaterThan(toolColor.r));
        await endEditor(tester);
        await tester.pump();
      },
    );

    testWidgets(
      'arka plan görselinde üst çubuk düğmeleri koruyucu kapsülde çizilir',
      (tester) async {
        final dir = Directory.systemTemp.createTempSync('notlar_bg_test');
        addTearDown(() => dir.deleteSync(recursive: true));
        final pngFile = File('${dir.path}/dark.png');
        final bytes = await tester.runAsync(() async {
          final rec = ui.PictureRecorder();
          final canvas = Canvas(rec);
          canvas.drawRect(
            const Rect.fromLTWH(0, 0, 8, 8),
            Paint()..color = const Color(0xFF101824),
          );
          final img = await rec.endRecording().toImage(8, 8);
          final data = await img.toByteData(format: ui.ImageByteFormat.png);
          img.dispose();
          return data!.buffer.asUint8List();
        });
        pngFile.writeAsBytesSync(bytes ?? Uint8List(0));
        final note = Note(
          id: 'n',
          type: NoteType.checklist,
          title: 'Görselli Defter',
          paged: true,
          backgroundImageId: 'bg1',
          backgroundOpacity: 0.85,
          updatedAt: DateTime(2026, 11, 22, 21, 5),
          attachments: [
            Attachment(
              id: 'bg1',
              kind: AttachmentKind.image,
              fileName: 'dark.png',
              mimeType: 'image/png',
              localPath: pngFile.path,
            ),
          ],
          items: const [NoteItem(id: '1', text: 'madde 1')],
        );
        await pumpEditor(tester, note);
        expect(
          find.byKey(const ValueKey('editor-top-actions-pill')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('editor-top-title-pill')),
          findsOneWidget,
        );
        expect(
          tester.widget<BottomAppBar>(find.byType(BottomAppBar)).color,
          Colors.transparent,
        );
        await endEditor(tester);
        await tester.pump();
      },
    );

    test('NotebookPaperPainter üst bantta yatay çizgileri çizer', () {
      final rec = ui.PictureRecorder();
      final canvas = Canvas(rec);
      final painter = NotebookPaperPainter(
        style: ArchivePaper.legal,
        line: const Color(0x447B5F06),
        margin: const Color(0x66923B33),
        spine: const Color(0x17000000),
        gap: 24,
        topBand: 82,
        contentRuled: true,
      );
      painter.paint(canvas, const Size(400, 800));
      rec.endRecording().dispose();
      // Hata vermeden çizildi; shouldRepaint topBand değişimini algılar.
      final changed = NotebookPaperPainter(
        style: ArchivePaper.legal,
        line: const Color(0x447B5F06),
        margin: const Color(0x66923B33),
        spine: const Color(0x17000000),
        gap: 24,
        topBand: 40,
        contentRuled: true,
      );
      expect(changed.shouldRepaint(painter), isTrue);
    });
  });
}
