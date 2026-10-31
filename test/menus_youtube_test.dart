import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/youtube.dart';
import 'package:notlar/features/notes/data/web_video.dart';
import 'package:notlar/features/notes/presentation/editor/attach_sheet.dart';
import 'package:notlar/features/notes/presentation/editor/note_images.dart';
import 'package:notlar/features/notes/presentation/editor/note_menu_sheet.dart';
import 'package:notlar/features/notes/presentation/editor/pinned_media_pane.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// Kullanıcı istekleri 2026-10-11: YouTube başlığı/bağlantısı, küçük
/// oynatıcıda ölçek, menülerin yeniden düzeni, "Yeni sayfa"nın yeri.
void main() {
  Widget host(Widget child) => ProviderScope(
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('tr'),
      home: child,
    ),
  );

  group('YouTube', () {
    test('dar kutuda oynatıcı sanal genişlikte kurulup küçültülür', () {
      final html = youTubeEmbedHtml('dQw4w9WgXcQ');
      expect(html, contains('var MIN=$kYouTubeMinCssWidth'));
      expect(html, contains('scale('));
      expect(html, contains("addEventListener('resize'"));
      // Ölçek eşiği ayarlanabilir.
      expect(
        youTubeEmbedHtml('dQw4w9WgXcQ', minCssWidth: 360),
        contains('var MIN=360'),
      );
    });

    testWidgets('başlık yalnız istenince (seçiliyken) kapağın üstünde', (
      tester,
    ) async {
      final video = webVideoAttachment(
        'https://youtu.be/dQw4w9WgXcQ',
        title: '4 hafta içinde büyük kollar',
      )!;
      Widget box(bool show) => host(
        Scaffold(
          body: SizedBox(
            width: 300,
            height: 170,
            child: NoteMediaBox(attachment: video, showWebTitle: show),
          ),
        ),
      );
      await tester.pumpWidget(box(false));
      expect(find.text('4 hafta içinde büyük kollar'), findsNothing);
      await tester.pumpWidget(box(true));
      expect(find.text('4 hafta içinde büyük kollar'), findsOneWidget);

      // Başlık henüz gelmediyse ("YouTube" yer tutucusu) şerit çizilmez.
      final untitled = webVideoAttachment('https://youtu.be/dQw4w9WgXcQ')!;
      await tester.pumpWidget(
        host(
          Scaffold(
            body: SizedBox(
              width: 300,
              height: 170,
              child: NoteMediaBox(attachment: untitled, showWebTitle: true),
            ),
          ),
        ),
      );
      expect(find.byKey(const ValueKey('web-video-title')), findsNothing);
    });

    testWidgets('sabit bölmenin çubuğunda "Bağlantıyı kopyala"', (
      tester,
    ) async {
      var copied = 0;
      final video = webVideoAttachment(
        'https://youtu.be/dQw4w9WgXcQ',
      )!.copyWith(pinHeight: 200);
      await tester.pumpWidget(
        host(
          Scaffold(
            body: PinnedMediaPane(
              media: video,
              onHeightChanged: (_) {},
              onUnpin: () {},
              onOpen: () {},
              onCopyLink: () => copied++,
              child: const Text('not'),
            ),
          ),
        ),
      );
      await tester.tap(find.byTooltip('Bağlantıyı kopyala'));
      expect(copied, 1);
    });
  });

  group('Menüler', () {
    testWidgets('Ekle levhası simge ızgarası; "Yeni sayfa" artık yok', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(411 * 3, 891 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        host(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showAttachSheet(context),
                child: const Text('aç'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('aç'));
      await tester.pumpAndSettle();

      expect(find.text('Yeni sayfa'), findsNothing);
      expect(find.text('YAKALA — İÇERİKTEN NOT OLUŞTURUR'), findsNothing);
      // 2026-10-20: üç bölüm (Not içeriği · Dosya ve bağlantı · Kamera ve
      // kayıt); PDF/Slayt/Ses dosyası/Galeriden video/Görseli ek olarak/
      // Dosyayı metne dök tek "Dosya ekle"de.
      expect(find.text('Dosya ve bağlantı'), findsOneWidget);
      expect(find.text('Kamera ve kayıt'), findsOneWidget);
      for (final gone in [
        'PDF ekle',
        'Slayt ekle',
        'Görseli ek olarak yükle',
        'Ses dosyası ekle',
        'Galeriden video',
        'Dosyayı metne dök',
      ]) {
        expect(find.text(gone), findsNothing, reason: gone);
      }

      // Izgara: "Dosya ekle", "Görsel ekle", "YouTube videosu" aynı satırda.
      final a = tester.getRect(find.text('Dosya ekle'));
      final b = tester.getRect(find.text('Görsel ekle'));
      final c = tester.getRect(find.text('YouTube videosu'));
      expect(a.top, closeTo(b.top, 20));
      expect(b.top, closeTo(c.top, 20));
      expect(a.center.dx, lessThan(b.center.dx));
      expect(b.center.dx, lessThan(c.center.dx));

      // Levhanın tamamı kaydırmadan görünür: "YouTube videosu" ekranda.
      final yt = tester.getRect(find.text('YouTube videosu'));
      expect(yt.bottom, lessThan(891));
    });

    testWidgets('editör ⋮: hızlı satır + gruplar; sabitle çubukta kaldı', (
      tester,
    ) async {
      String? picked;
      await tester.pumpWidget(
        host(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  picked = await showNoteEditorMenu(
                    context,
                    pinned: false,
                    locked: false,
                    archived: false,
                    isList: false,
                    twoColumns: false,
                    hasFloatingImages: false,
                    hasAttachments: false,
                  );
                },
                child: const Text('aç'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('aç'));
      await tester.pumpAndSettle();

      // Hızlı satır (F12.1): Yıldızla · Klasöre taşı · Sürüm geçmişi ·
      // Sesli dinle — aynı yükseklikte, bu sırayla.
      final quick = [
        for (final id in ['star', 'folder', 'history', 'listen'])
          tester.getRect(find.byKey(ValueKey('menu-quick-$id'))),
      ];
      for (var i = 1; i < quick.length; i++) {
        expect(quick[i].top, closeTo(quick[0].top, 1));
        expect(quick[i - 1].center.dx, lessThan(quick[i].center.dx));
      }
      // Alt çubukta duran Paylaş / Notta ara hızlı satırda yok; çubuktan
      // düştüklerinde (burada çubuk bilgisi verilmedi) Araçlar'da.
      expect(find.byKey(const ValueKey('menu-quick-share')), findsNothing);
      expect(find.byKey(const ValueKey('menu-quick-search')), findsNothing);
      expect(find.byKey(const ValueKey('menu-tile-share')), findsOneWidget);
      expect(find.byKey(const ValueKey('menu-tile-search')), findsOneWidget);
      expect(find.byKey(const ValueKey('menu-tile-calculator')), findsOneWidget);

      // Grup başlıkları — kart ⋮ ile aynı adlar (F12.2).
      for (final title in [
        'Düzenle',
        'Kopyala',
        'Araçlar',
        'Koruma ve depolama',
      ]) {
        expect(find.text(title), findsOneWidget, reason: title);
      }
      expect(find.text('İçeriği temizle'), findsOneWidget);
      // Üst çubukta açıkça duran "Sabitle" burada tekrar etmez.
      expect(find.text('Sabitle'), findsNothing);
      // Editörde eksik olan işler eklendi.
      expect(find.text('Notu çoğalt'), findsOneWidget);
      // Ekran/ayar en altta, Sil'in ALTINDA ince satır.
      final delete = tester.getRect(find.byKey(const ValueKey('menu-tile-delete')));
      for (final id in ['customize', 'settings']) {
        final r = tester.getRect(find.byKey(ValueKey('menu-footer-$id')));
        expect(r.top, greaterThan(delete.bottom), reason: id);
      }

      await tester.tap(find.byKey(const ValueKey('menu-tile-calculator')));
      await tester.pumpAndSettle();
      expect(picked, 'calculator');
    });
  });
}
