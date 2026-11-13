import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/widgets/keyboard_snap.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';

import 'support/editor_harness.dart';

/// **ALT PANEL TİTREMESİ ÖZEL TESTİ** (P55, kullanıcı 2026-11-13: "alt panel
/// hâlâ titriyor — ona özel test yaptır").
///
/// Klavye kare kare sürülür; her karede editörün alt çubuğunun alt kenarı
/// ölçülür. KIRMIZI:
/// * ileri-geri salınım (açılırken aşağı, kapanırken yukarı tek kare bile),
/// * olması gereken yerden (klavyenin üstü ya da gezinme çubuğunun üstü)
///   1 px'ten fazla sapma,
/// * klavye durduktan sonraki oturma karelerinde 1 px'ten fazla kıpırtı.
///
/// Gerçek klavyenin biçimleri: düz açılış/kapanış, YARIDA dönen hareket,
/// klavye yarıda durup yeniden yükselir (oturma zamanlayıcısı arada gövdeyi
/// dizer). Telefon ve tablet (yatay/dikey) düzenleri.
///
/// **ANDROID < 35 MOTOR MODELİ** (cihaz izi 2026-11-13, Mi Note 10 Lite, API
/// 31, 3 düğmeli gezinme): Flutter motoru klavye ANİMASYONU sürerken IME
/// boşluğundan gezinme çubuğunu DÜŞER (`ImeSyncDeferringInsetsCallback
/// .onProgress`, `excludedInsets`), animasyon BİTİNCE tam değeri verir:
/// 18 → 79 → … → 253,1 → 300,7 (son adım = gezinme çubuğu 47,3). Video:
/// klavyenin görünen üst kenarı her karede bildirilen + 47,3. Çubuk
/// bildirilen değere oturunca açılış/kapanış boyunca öneri şeridinin
/// ALTINDA kalıyor, sonda birden beliriyordu — kullanıcının "titreme"si.
const _nav = 48.0;

List<double> _ease(double from, double to, int frames) => [
  for (var i = 1; i <= frames; i++)
    from + (to - from) * Curves.fastOutSlowIn.transform(i / frames),
];

/// Bir klavye hareketi: kareler + sonunda kaç ms hareketsiz beklenir.
typedef _Leg = ({List<double> frames, int holdMs});

final _scenarios = <String, List<_Leg>>{
  'düz aç/kapa': [
    (frames: _ease(0, 300, 18), holdMs: 400),
    (frames: _ease(300, 0, 16), holdMs: 400),
  ],
  'yarıda dönen': [
    (frames: _ease(0, 300, 18).take(8).toList(), holdMs: 0),
    (frames: _ease(_ease(0, 300, 18)[7], 0, 10), holdMs: 400),
  ],
  'yarıda durup yeniden yükselen': [
    (frames: _ease(0, 260, 16), holdMs: 220),
    (frames: _ease(260, 300, 6), holdMs: 400),
    (frames: _ease(300, 0, 16), holdMs: 400),
  ],
};

/// Klavyenin GERÇEK yüksekliğinden motorun bildirdiği değer: Android < 35
/// modelinde animasyon karelerinde gezinme çubuğu düşülür, son (oturma)
/// karesi tamdır.
double _reported(double real, {required bool android31, required bool last}) =>
    android31 && !last ? (real - _nav).clamp(0.0, double.infinity) : real;

Note _note(String kind) {
  final base = Note(
    id: 'n',
    type: NoteType.text,
    title: 'Not',
    body: List.generate(30, (i) => 'Satır $i').join('\n'),
  );
  return switch (kind) {
    'sabit PDF' => base.copyWith(
      attachments: const [
        Attachment(
          id: 'p',
          kind: AttachmentKind.pdf,
          fileName: 'b.pdf',
          mimeType: 'application/pdf',
          width: 600,
          height: 800,
          pinHeight: 300,
        ),
      ],
    ),
    _ => base,
  };
}

void main() {
  const layouts = {
    'telefon': Size(412, 915),
    'tablet yatay': Size(1280, 800),
    'tablet dikey': Size(800, 1280),
  };
  for (final MapEntry(key: layout, value: size) in layouts.entries) {
    for (final (kind, android31) in [
      ('metin', false),
      ('sabit PDF', false),
      ('metin, Android<35 motoru', true),
      ('sabit PDF, Android<35 motoru', true),
    ]) {
      testWidgets('$layout, $kind: alt çubuk her karede yerinde, salınım '
          've 1 px üstü sıçrama yok', (tester) async {
        KeyboardInset.navExcludedWhileAnimating = android31;
        addTearDown(() => KeyboardInset.navExcludedWhileAnimating = false);
        await pumpEditor(tester, _note(kind.split(',').first), size: size);
        tester.takeException();
        for (var i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.tap(find.textContaining('Satır 3').last);
        await tester.pump(const Duration(milliseconds: 16));
        await tester.pump(const Duration(milliseconds: 150));
        final bar = find.byType(BottomAppBar);
        double edge() => tester.getRect(bar).bottom;
        final failures = <String>[];
        for (final MapEntry(key: name, value: legs) in _scenarios.entries) {
          var inset = 0.0;
          var last = edge();
          for (final leg in legs) {
            for (final (i, next) in leg.frames.indexed) {
              final rising = next > inset;
              inset = next;
              // Bacağın son karesi motorun "animasyon bitti" karesi (yalnız
              // klavye orada duruyorsa; yarıda dönende sonraki bacak sürer).
              final reported = _reported(
                inset,
                android31: android31,
                last: i == leg.frames.length - 1 && leg.holdMs > 0,
              );
              tester.view.viewInsets = FakeViewPadding(bottom: reported);
              tester.view.padding = FakeViewPadding(
                top: 30,
                bottom: (_nav - reported).clamp(0.0, _nav),
              );
              await tester.pump(const Duration(milliseconds: 16));
              tester.takeException();
              final y = edge();
              final want = size.height - (inset > _nav ? inset : _nav);
              if ((y - want).abs() > 1) {
                failures.add(
                  '$name: klavye ${inset.toStringAsFixed(1)} → çubuk $y, '
                  'olması gereken $want',
                );
              }
              if (rising ? y > last + 1e-6 : y < last - 1e-6) {
                failures.add('$name: salınım $last → $y');
              }
              last = y;
            }
            // Klavye durdu: oturma zamanlayıcısı gövdeyi dizer; çubuk
            // kıpırdamaz.
            for (var t = 0; t < leg.holdMs; t += 16) {
              await tester.pump(const Duration(milliseconds: 16));
              tester.takeException();
              final y = edge();
              if ((y - last).abs() > 1) {
                failures.add('$name: oturmada sıçrama $last → $y');
              }
              last = y;
            }
          }
        }
        expect(failures, isEmpty, reason: failures.join('\n'));
        await endEditor(tester);
      });
    }
  }
}
