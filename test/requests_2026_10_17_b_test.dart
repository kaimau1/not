import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/doc_picker.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/presentation/editor/attachment_strip.dart';
import 'package:notlar/features/notes/presentation/editor/audio_card_box.dart';
import 'package:notlar/features/notes/presentation/editor/pinned_media_pane.dart';
import 'package:notlar/features/notes/presentation/editor/text_page_box.dart';
import 'package:notlar/features/notes/presentation/editor/view_mode_switch.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _app(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('tr'),
  home: Scaffold(body: child),
);

const _text = Attachment(
  id: 't',
  kind: AttachmentKind.text,
  fileName: 'ders.txt',
  mimeType: 'text/plain',
  text: 'Birinci paragraf.\nİkinci paragraf.',
);

const _audio = Attachment(
  id: 'a',
  kind: AttachmentKind.audio,
  fileName: 'kayit.m4a',
  mimeType: 'audio/mp4',
);

/// Kullanıcı istekleri 2026-10-17 (3. tur): dosya seçicide türe göre süzme
/// + Dosya Okuyucu ekosistemi; TXT'de sayfaya gömme / üste sabitleme /
/// balonlu geçiş, bu geçişin olabilecek TÜM türlerde çalışması ve alt ek
/// şeridinde her türde aynı, kolay geçiş.
void main() {
  group('metin ve ses ekinin yeri', () {
    test('şeritte başlar, sayfaya onPage ile gömülür', () {
      expect(_text.stripByDefault, isTrue);
      expect(_text.offPage, isTrue);
      expect(_text.floatsOnPage, isFalse);
      final placed = _text.placedOnPage(true);
      expect(placed.onPage, isTrue);
      expect(placed.floatsOnPage, isTrue);
      expect(placed.placedOnPage(false).offPage, isTrue);
      expect(_audio.placedOnPage(true).floatsOnPage, isTrue);
    });

    test('görsel/videoda yer hâlâ asFile ile', () {
      const image = Attachment(
        id: 'g',
        kind: AttachmentKind.image,
        fileName: 'g.jpg',
        mimeType: 'image/jpeg',
      );
      expect(image.offPage, isFalse);
      expect(image.placedOnPage(false).asFile, isTrue);
      expect(image.placedOnPage(false).floatsOnPage, isFalse);
    });

    test('metin ve ses üste sabitlenir, sunum sabitlenmez', () {
      expect(_text.copyWith(pinHeight: 200).isPinnedTop, isTrue);
      expect(_audio.copyWith(pinHeight: 104).isPinnedTop, isTrue);
      // Sabitken sayfada yüzmez (ikisi birden olmaz).
      expect(
        _text.copyWith(pinHeight: 200, onPage: true).floatsOnPage,
        isFalse,
      );
      const slide = Attachment(
        id: 's',
        kind: AttachmentKind.slide,
        fileName: 's.pptx',
        mimeType: 'application/vnd.ms-powerpoint',
      );
      expect(slide.copyWith(pinHeight: 200).isPinnedTop, isFalse);
    });

    test('metin özeti kararlı ve kayıtta taşınır', () {
      expect(Attachment.digestOf('abc'), Attachment.digestOf('abc'));
      expect(Attachment.digestOf('abc'), isNot(Attachment.digestOf('abd')));
      final doc = const Attachment(
        id: 'p',
        kind: AttachmentKind.pdf,
        fileName: 'ders.pdf',
        mimeType: 'application/pdf',
      ).copyWith(sourceId: 't', sourceDigest: Attachment.digestOf('x'));
      final map = doc.toMap()..remove('createdAt');
      expect(map['sourceDigest'], Attachment.digestOf('x'));
      expect(Attachment.fromMap(map).sourceDigest, Attachment.digestOf('x'));
      // Boşken alan yazılmaz (eski eklerin şeması büyümez).
      expect(_text.toMap().containsKey('sourceDigest'), isFalse);
    });
  });

  group('metnin sayfalanması', () {
    testWidgets('sayfalar metni eksiksiz ve sırayla kapsar', (tester) async {
      final text = List.generate(
        60,
        (i) => 'Paragraf $i: ${'kelime ' * (i % 7 + 3)}',
      ).join('\n');
      late TextPagination pages;
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) {
              pages = TextPagination.of(
                text: text,
                title: 'ders',
                style: DefaultTextStyle.of(
                  context,
                ).style.merge(const TextStyle(fontSize: 11, height: 1.45)),
                page: const Size(260, 338),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
              );
              return const SizedBox();
            },
          ),
        ),
      );
      // Kalan sayfalar boşta bölünür.
      for (var i = 0; i < 50 && !pages.complete; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(pages.complete, isTrue);
      expect(pages.count, greaterThan(1));
      // Sayfalar uç uca eklenince (kırpılan satır sonları dışında) metnin
      // kendisi çıkar — hiçbir satır iki sayfada ya da hiçbir sayfada değil.
      final joined = StringBuffer();
      for (var i = 0; i < pages.count; i++) {
        joined.write(pages.pageText(i));
      }
      expect(joined.toString().replaceAll('\n', ''), text.replaceAll('\n', ''));
    });

    testWidgets('boş metin tek boş sayfadır', (tester) async {
      late TextPagination pages;
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) {
              pages = TextPagination.of(
                text: '',
                title: '',
                style: DefaultTextStyle.of(context).style,
                page: const Size(260, 338),
                padding: EdgeInsets.zero,
              );
              return const SizedBox();
            },
          ),
        ),
      );
      expect(pages.complete, isTrue);
      expect(pages.count, 1);
      expect(pages.pageText(0), '');
    });
  });

  group('sayfadaki metin kutusu', () {
    testWidgets('sayfa çevrilir, kaldığın sayfa nota yazılır', (tester) async {
      final long = List.generate(
        80,
        (i) => 'Satır $i — ders notunun uzun bir cümlesi burada.',
      ).join('\n');
      final changes = <Attachment>[];
      await tester.pumpWidget(
        _app(
          Center(
            child: SizedBox(
              width: 260,
              height: 338,
              child: TextPageBox(
                attachment: _text.copyWith(
                  text: long,
                  width: kTextBoxWidth,
                  height: kTextBoxHeight,
                ),
                onChanged: changes.add,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.textContaining('Satır 0'), findsOneWidget);
      expect(find.textContaining('1 / '), findsOneWidget);
      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      await tester.pumpAndSettle();
      expect(find.textContaining('2 / '), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 700));
      expect(changes.last.pdfPage, 2);
      expect(tester.takeException(), isNull);
    });
  });

  group('ses kartı', () {
    testWidgets('oynatıcı kurulmadan çizilir (tembel)', (tester) async {
      await tester.pumpWidget(
        _app(
          const Center(
            child: SizedBox(
              width: 300,
              height: 84,
              child: AudioCardBox(attachment: _audio),
            ),
          ),
        ),
      );
      expect(find.text('kayit.m4a'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('sabit bölme', () {
    testWidgets('metin tepede okunur, ses tepede çalar', (tester) async {
      await tester.pumpWidget(
        _app(
          PinnedMediaPane(
            media: _text.copyWith(pinHeight: 220),
            onHeightChanged: (_) {},
            onUnpin: () {},
            onOpen: () {},
            child: const SizedBox.expand(),
          ),
        ),
      );
      expect(find.byType(TextReaderView), findsOneWidget);
      expect(find.text('İkinci paragraf.'), findsOneWidget);

      await tester.pumpWidget(
        _app(
          PinnedMediaPane(
            media: _audio.copyWith(pinHeight: 104),
            onHeightChanged: (_) {},
            onUnpin: () {},
            onOpen: () {},
            child: const SizedBox.expand(),
          ),
        ),
      );
      expect(find.byType(AudioCardBox), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    test('varsayılan yükseklikler', () {
      const screen = Size(400, 800);
      expect(defaultPinnedHeight(_audio, screen), 104);
      expect(defaultPinnedHeight(_text, screen), 320);
    });
  });

  group('ek şeridi', () {
    late SharedPreferences prefs;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    testWidgets('her döşemede aynı anahtar ve ⋯ levhası', (tester) async {
      final changes = <(String, AttachmentView)>[];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: _app(
            Align(
              alignment: Alignment.bottomCenter,
              child: AttachmentStrip(
                attachments: const [_text, _audio],
                onRemove: (_) {},
                expanded: true,
                onToggle: () {},
                viewOf: (_) => AttachmentView.attached,
                onSetView: (a, v) => changes.add((a.id, v)),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // İki döşemenin ikisinde de anahtar (metin ve ses — türden bağımsız).
      expect(
        find.byKey(const ValueKey('attachment-view-switch')),
        findsNWidgets(2),
      );
      // Tek dokunuşla tepeye sabitlenir.
      await tester.tap(find.byKey(const ValueKey('view-pinned')).first);
      expect(changes.single, ('t', AttachmentView.pinned));

      // ⋯ → büyük anahtarlı levha; "Yüzen" sayfaya gömer.
      await tester.tap(find.byKey(const ValueKey('strip-more')).last);
      await tester.pumpAndSettle();
      expect(find.text('Nerede dursun?'), findsOneWidget);
      await tester.tap(find.text('Yüzen'));
      await tester.pumpAndSettle();
      expect(changes.last, ('a', AttachmentView.floating));
      expect(tester.takeException(), isNull);
    });
  });

  group('dosya seçici süzgeci', () {
    test('aile joker karakteri tek tek türleri yutar', () {
      const audio = XTypeGroup(
        label: 'audio',
        mimeTypes: ['audio/*'],
        extensions: ['mp3', 'm4a', 'wav'],
      );
      expect(DocPicker.mimeTypesOf(audio), ['audio/*']);
    });

    test('uzantıdan MIME türetilir', () {
      const images = XTypeGroup(label: 'g', extensions: ['jpg', 'png']);
      expect(DocPicker.mimeTypesOf(images).toSet(), {
        'image/jpeg',
        'image/png',
      });
      const unknown = XTypeGroup(label: 'x', extensions: ['xyz']);
      expect(DocPicker.mimeTypesOf(unknown), ['*/*']);
    });
  });
}
