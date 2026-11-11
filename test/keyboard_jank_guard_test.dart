import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/editor/editor_quick_row.dart';
import 'package:notlar/features/notes/presentation/editor/note_editor_screen.dart';
import 'support/editor_harness.dart';

/// Klavye hareketinin kareleri (dp): yavaş başlar (ilk kareler gezinme
/// çubuğu payının — 48 dp — ALTINDA: `padding.bottom` o karelerde erir),
/// hızlanır, yavaşlayarak oturur.
List<double> _keyboardFrames({double height = 300, int frames = 18}) => [
  for (var i = 1; i <= frames; i++)
    height * Curves.fastOutSlowIn.transform(i / frames),
];

/// Bir karede olanlar: toplam widget kurulumu, bunun EDİTÖRÜN İÇİNDE kalanı
/// (gerisi çerçevenin kendi işi: kök `MediaQuery`, metin seçim tutamağının
/// her klavye karesinde tazelenen katmanı — `EditableText.didChangeMetrics`),
/// yeniden dizilmek üzere işaretlenen yerleşim sınırları, alt çubuğun
/// ekrandaki alt kenarı.
typedef _Frame = ({
  double inset,
  int builds,
  int editorBuilds,
  List<String> layouts,
  double bar,
});

/// Klavyeyi tam editörde kare kare süren düzenek (F60.S5).
class _KeyboardRig {
  _KeyboardRig(this.tester);
  final WidgetTester tester;
  final _marks = <String>[];

  Future<_Frame> frame(double inset, {int ms = 16}) async {
    tester.view.viewInsets = FakeViewPadding(bottom: inset);
    // Android: alt sistem payı klavye yükseldikçe erir.
    tester.view.padding = FakeViewPadding(
      top: 30,
      bottom: (48 - inset).clamp(0.0, 48.0),
    );
    final print = debugPrint;
    _marks.clear();
    debugPrint = (String? m, {int? wrapWidth}) {
      const head = 'markNeedsLayout() called for ';
      if (m != null && m.startsWith(head)) {
        _marks.add(m.substring(head.length).split('#').first);
      }
    };
    debugPrintMarkNeedsLayoutStacks = true;
    final rebuilt = <Element>{};
    debugOnRebuildDirtyWidget = (e, _) => rebuilt.add(e);
    try {
      await tester.pump(Duration(milliseconds: ms));
    } finally {
      debugOnRebuildDirtyWidget = null;
      debugPrintMarkNeedsLayoutStacks = false;
      debugPrint = print;
    }
    bool inEditor(Element e) {
      var inside = false;
      e.visitAncestorElements((a) {
        inside = a.widget is NoteEditorScreen;
        return !inside;
      });
      return inside;
    }

    return (
      inset: inset,
      builds: rebuilt.length,
      editorBuilds: rebuilt.where((e) => e.mounted && inEditor(e)).length,
      layouts: List.of(_marks),
      bar: tester.getRect(find.byType(BottomAppBar)).bottom,
    );
  }
}

final _typed = Note(
  id: 'n',
  type: NoteType.text,
  title: 'Not',
  body: List.generate(30, (i) => 'Satır $i').join('\n'),
);

int _budget(String key) =>
    ((jsonDecode(File('test/perf_budget/budgets.json').readAsStringSync())
                as Map<String, dynamic>)['S17']
            as Map<String, dynamic>)[key]
        as int;

/// Klavyeyi [note] açıkken 3 kez açıp kapatır; konumu her karede, sayıları
/// `budgets.json` S17'nin [key] önekli girdileriyle sınar.
Future<void> _keyboardScene(
  WidgetTester tester,
  Note note, {
  required String name,
  String key = '',
}) async {
  await pumpEditor(tester, note);
  // pdfrx'in hata kutusu (testte pdfium yok) testi düşürmesin.
  tester.takeException();
  // Açılış sonrası gecikmeli işler bitsin (ölçüme karışmasın).
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.tap(find.textContaining('Satır 3').last);
  await tester.pump(const Duration(milliseconds: 16));
  await tester.pump(const Duration(milliseconds: 150));
  final rig = _KeyboardRig(tester);
  const screen = 915.0, nav = 48.0;
  final up = _keyboardFrames();
  final down = [...up.reversed.skip(1), 0.0];
  // Kareler üç türdür:
  // * GEÇİŞ: klavyenin göründüğü ilk kare (üst çubukta tarih ↔ hızlı satır)
  //   ve kapanışın ilk/son karesi (gövde tam boya döner; satır ↔ tarih).
  //   Çevrim başına birer kez; bir şeyler dizilir.
  // * HAREKET: aradaki bütün kareler — yalnız klavyeyi dinleyen yapraklar
  //   kurulur, HİÇBİR ŞEY dizilmez.
  final first = <_Frame>[];
  final switching = <_Frame>[];
  final moving = <_Frame>[];
  for (var cycle = 0; cycle < 3; cycle++) {
    for (final seq in [up, down]) {
      var last = double.nan;
      for (final (i, inset) in seq.indexed) {
        final f = await rig.frame(inset);
        tester.takeException();
        final edge =
            (seq == up && i == 0) ||
            (seq == down && (i == 0 || i == seq.length - 1));
        (cycle == 0 && seq == up && i == 0
                ? first
                : edge
                ? switching
                : moving)
            .add(f);
        // Çubuğun dibi: klavye gezinme çubuğundan alçaksa onun üstü,
        // değilse klavyenin üstü — HER KAREDE (gecikme/çift hareket yok).
        expect(
          f.bar,
          moreOrLessEquals(screen - (inset > nav ? inset : nav)),
          reason: 'tur $cycle, klavye ${inset.toStringAsFixed(1)}',
        );
        if (!last.isNaN) {
          // Tekdüze: açılırken hep yukarı, kapanırken hep aşağı.
          expect(
            seq == up ? f.bar <= last : f.bar >= last,
            isTrue,
            reason: 'geri sıçrama: $last → ${f.bar}',
          );
        }
        last = f.bar;
      }
      // Oturma (140 ms sonra, klavye durmuşken): hareket karesi değil.
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));
    }
  }
  _Frame worst(List<_Frame> l) =>
      l.reduce((a, b) => a.builds >= b.builds ? a : b);
  final editorWorst = moving
      .map((f) => f.editorBuilds)
      .reduce((a, b) => a > b ? a : b);
  final laidOut = {for (final f in moving) ...f.layouts};
  // ignore: avoid_print
  print(
    'S17 $name: ilk kare ${first.single.builds} kurulum; geçiş karesi en çok '
    '${worst(switching).builds}; hareket karesi en çok '
    '${worst(moving).builds} (klavye '
    '${worst(moving).inset.toStringAsFixed(0)}), editör içi $editorWorst, '
    'dizilen $laidOut',
  );
  expect(first.single.builds, lessThanOrEqualTo(_budget('${key}ilk_kare_kurulum')));
  expect(
    worst(switching).builds,
    lessThanOrEqualTo(_budget('${key}gecis_karesi_kurulum')),
  );
  expect(
    worst(moving).builds,
    lessThanOrEqualTo(_budget('${key}hareket_karesi_kurulum')),
  );
  expect(
    editorWorst,
    lessThanOrEqualTo(_budget('${key}hareket_karesi_editor_ici')),
  );
  expect(
    laidOut.length,
    lessThanOrEqualTo(_budget('${key}hareket_dizilen_sinir')),
    reason: '$laidOut',
  );
  tester.takeException();
  await endEditor(tester);
}

/// **KLAVYE / YAZMA KASMASI BEKÇİSİ** (ölçüm 2026-11-10, kullanıcı: "son
/// güncellemelerden sonra klavye açılıp kapanırken titriyor, genel
/// yavaşlık"). A/B (11-06 tabanı → 11-09): yazarken UI işi ×3,3, klavye
/// aç/kapa +%65. İki kök neden; ikisi de burada kilitli.
void main() {
  // F60.S5 (kullanıcı 2026-11-11: "klavye açılırken alt paneldeki titreme
  // kasmayı kökünden çöz, tekrar yaşanmayacak şekilde"). İki ölçü:
  // TİTREME = alt çubuğun alt kenarı her karede klavyenin üst kenarında değil
  // (geri sıçrama, gecikme); KASMA = hareket karelerinde kurulan widget ve
  // yeniden dizilen sınır sayısı.
  testWidgets('klavye açılıp kapanırken alt çubuk her karede klavyenin '
      'üstünde; hareket kareleri bütçede, hiçbir şey dizilmez (S17)', (
    tester,
  ) async {
    await _keyboardScene(tester, _typed, name: 'metin');
    expect(tester.binding.transientCallbackCount, 0);
  });

  // Sabit medya: klavyenin evresi (açılıyor/kapanıyor) eskiden bütün bölmeyi
  // animasyonun ortasında yeniden kuruyordu (çevrim başına 4 × ≈ 230).
  testWidgets('sabit PDF\'li notta da: konum tekdüze, hareket kareleri '
      'bütçede (S17)', (tester) async {
    await _keyboardScene(
      tester,
      _typed.copyWith(
        attachments: const [
          Attachment(
            id: 'p',
            kind: AttachmentKind.pdf,
            fileName: 'belge.pdf',
            mimeType: 'application/pdf',
            width: 600,
            height: 800,
            pinHeight: 300,
          ),
        ],
      ),
      name: 'sabit PDF',
      key: 'sabit_pdf_',
    );
  });

  testWidgets('KeyboardSwitch: hızlı satır bir kez kurulur, klavye kapanınca '
      'sökülmez', (tester) async {
    var inits = 0;
    Widget app(double inset) => MaterialApp(
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(viewInsets: EdgeInsets.only(bottom: inset)),
          // Scaffold DEĞİL: gövdesinden klavye boşluğunu siler (editörde
          // anahtar üst çubukta).
          child: Material(
            child: KeyboardSwitch(
              open: _InitCounter(onInit: () => inits++),
              closed: const Text('tarih'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpWidget(app(0));
    expect(inits, 0, reason: 'klavye hiç açılmadan kurulmaz');
    expect(find.text('tarih'), findsOneWidget);
    await tester.pumpWidget(app(300));
    expect(inits, 1);
    expect(find.text('tarih'), findsNothing);
    for (var i = 0; i < 3; i++) {
      await tester.pumpWidget(app(0));
      await tester.pumpWidget(app(280));
    }
    expect(inits, 1, reason: 'her açılışta yeniden kurulmamalı');
  });

  testWidgets('TypingBarHide: gizle/göster animasyonu gövdeyi kare kare '
      'yeniden DİZDİRMEZ (en çok 2 yerleşim)', (tester) async {
    final hidden = ValueNotifier<bool>(false);
    var layouts = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (_, _) {
                    layouts++;
                    return const SizedBox.expand();
                  },
                ),
              ),
              TypingBarHide(
                hidden: hidden,
                enabled: true,
                child: const SizedBox(height: 120, width: 300),
              ),
            ],
          ),
        ),
      ),
    );
    final before = layouts;
    hidden.value = true;
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    hidden.value = false;
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(layouts - before, lessThanOrEqualTo(2));
    hidden.dispose();
  });
}

class _InitCounter extends StatefulWidget {
  const _InitCounter({required this.onInit});
  final VoidCallback onInit;

  @override
  State<_InitCounter> createState() => _InitCounterState();
}

class _InitCounterState extends State<_InitCounter> {
  @override
  void initState() {
    super.initState();
    widget.onInit();
  }

  @override
  Widget build(BuildContext context) => const Text('hızlı satır');
}
