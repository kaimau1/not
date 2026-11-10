import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/editor/pdf_page_box.dart';
import 'package:notlar/features/notes/presentation/viewers/ink_layer.dart';
import 'package:notlar/features/notes/presentation/viewers/ink_pen.dart';
import 'package:notlar/features/notes/presentation/viewers/ink_tools.dart';

import 'support/editor_harness.dart';

/// **TEK ARAÇ DURUMU** (OTURTMA F60.S4 + F63.2, KALEM K4). Kullanıcı bulgusu
/// (2026-11-09): "ek gömülüyken silgi seçili olduğu hâlde kalem yazıyor".
/// KÖK: her [InkController] aracı KURULUMDA `InkToolMemory`'den kopyalıyordu;
/// tepsi yalnız sayfa denetleyicisini sürdüğünden ekin denetleyicisi silgiyi,
/// rengi, kalınlığı hiç görmüyordu.
///
/// PDF'i çizdirmek pdfium ister (testte yok): kutuya verilen denetleyici
/// gerçek olanıdır, dokunuşlar ona katmanın yaptığı çağrılarla işlenir
/// (`perf_budget_test` S6/S7 ile aynı yol).
const _size = Size(300, 400);

/// Sayfa 1'de yatay çizgi (y = 0,25).
const _seed = InkStroke(
  page: 1,
  color: 0xFF000000,
  width: 0.01,
  points: [0.1, 0.25, 0.3, 0.25, 0.5, 0.25],
);

final _pdf = Attachment(
  id: 'p',
  kind: AttachmentKind.pdf,
  fileName: 'belge.pdf',
  mimeType: 'application/pdf',
  width: 600,
  height: 800,
  ink: const [_seed],
);

Note _noteWith(Attachment a) => Note(
  id: 'n',
  type: NoteType.text,
  title: 'Başlık',
  body: 'yazı',
  attachments: [a],
);

int _pointer = 500;

/// Kalemle [_seed]'i kesen dikey dokunuş ([y] verilirse o yükseklikte yatay
/// çizgi — tohumdan uzak).
void _pen(InkController c, {double? y}) {
  final p = _pointer++;
  final from = y == null ? const Offset(90, 80) : Offset(30, y);
  final to = y == null ? const Offset(90, 120) : Offset(150, y);
  c.pointerDown(1, from, _size, pointer: p, kind: PointerDeviceKind.stylus);
  c.pointerMove(1, Offset.lerp(from, to, 0.5)!, _size, pointer: p);
  c.pointerMove(1, to, _size, pointer: p);
  c.pointerUp(pointer: p, kind: PointerDeviceKind.stylus);
}

InkController _docInk(WidgetTester tester) =>
    tester.widget<PdfPageBox>(find.byType(PdfPageBox)).ink!;

/// Editörü kalem görülmüş cihazda kurar; sayfa denetleyicisini (tepsinin
/// sürdüğü) döndürür.
Future<InkController> _open(WidgetTester tester, Attachment pdf) async {
  InkToolMemory.reset();
  InkToolMemory.stylusEver = true;
  addTearDown(InkToolMemory.reset);
  await pumpEditor(tester, _noteWith(pdf), repo: CountingNotesRepository());
  return tester.widget<InkPageLayer>(find.byType(InkPageLayer).first).controller;
}

void main() {
  setUp(InkToolMemory.reset);

  test('silgi bir denetleyicide seçilir, öbürü de siler (not paketi dahil)', () {
    final tray = InkController(initial: const [], onChanged: (_) {});
    final other = InkController(initial: const [_seed], onChanged: (_) {})
      ..setEditing(true);
    tray.setEraser(true);
    expect(other.eraser, isTrue);
    _pen(other);
    expect(other.ink, isEmpty, reason: 'dokunulan çizgi silinir, yenisi yok');
    // Kaleme dönünce öbürü de yazar; renk ve kalınlık da ortak.
    tray
      ..setPen(InkPen.marker)
      ..setColor(const Color(0xFFE53935))
      ..setWidth(9);
    _pen(other, y: 300);
    expect(other.ink, hasLength(1));
    expect(other.pen, InkPen.marker);
    expect(other.ink.single.color, tray.penColor.toARGB32());
    expect(other.ink.single.width, closeTo(9 / _size.width, 1e-9));
    tray.dispose();
    other.dispose();
  });

  test('araç değişimi öbür denetleyicinin dinleyicisine de ulaşır', () {
    final a = InkController(initial: const [], onChanged: (_) {});
    final b = InkController(initial: const [], onChanged: (_) {});
    var seen = 0;
    b.addListener(() => seen++);
    a.setEraser(true);
    expect(seen, greaterThan(0));
    a.dispose();
    b.dispose();
  });

  test('yeni oturum (açık denetleyici yok) kalemle başlar, silgiyle değil', () {
    final a = InkController(initial: const [], onChanged: (_) {})
      ..setEraser(true);
    a.dispose();
    final b = InkController(initial: const [], onChanged: (_) {});
    expect(b.eraser, isFalse);
    b.dispose();
  });

  test('etkin yüzey = son dokunulan denetleyici; kapanınca bırakılır', () {
    final a = InkController(initial: const [], onChanged: (_) {})
      ..setEditing(true);
    final b = InkController(initial: const [], onChanged: (_) {})
      ..setEditing(true);
    _pen(a, y: 100);
    expect(InkController.active, same(a));
    _pen(b, y: 100);
    expect(InkController.active, same(b));
    b.dispose();
    expect(InkController.active, isNull);
    a.dispose();
  });

  for (final (name, pdf) in [
    ('sabit', _pdf.copyWith(pinHeight: 300)),
    ('gömülü', _pdf.copyWith(onPage: true)),
  ]) {
    testWidgets('tepside silgi → $name PDF\'e kalem: çizgi artmaz, silinir', (
      tester,
    ) async {
      final page = await _open(tester, pdf);
      final doc = _docInk(tester);
      expect(identical(page, doc), isFalse);
      expect(doc.ink, hasLength(1));
      page.setEraser(true);
      _pen(doc);
      await tester.pump(const Duration(milliseconds: 300));
      expect(doc.ink, isEmpty);
      await endEditor(tester);
    });

    testWidgets('tepside renk → $name PDF\'e çizilen çizgi yeni renkte', (
      tester,
    ) async {
      final page = await _open(tester, pdf);
      final doc = _docInk(tester);
      page.setColor(const Color(0xFF1E88E5));
      _pen(doc, y: 300);
      await tester.pump(const Duration(milliseconds: 300));
      expect(doc.ink, hasLength(2));
      expect(doc.ink.last.color, 0xFF1E88E5);
      await endEditor(tester);
    });
  }

  testWidgets('tepsinin geri al/yinelesi son dokunulan yüzeyde çalışır', (
    tester,
  ) async {
    final page = await _open(tester, _pdf.copyWith(pinHeight: 300));
    final doc = _docInk(tester);
    // Kalem sayfaya değer: kalem kipi açılır, tepsi gelir.
    final at = tester.getCenter(find.byType(InkPageLayer).first);
    final pen = await tester.startGesture(at, kind: PointerDeviceKind.stylus);
    await pen.moveBy(const Offset(40, 6));
    await pen.moveBy(const Offset(40, 6));
    await pen.up();
    await tester.pump(const Duration(milliseconds: 400));
    expect(page.ink, hasLength(1));
    // Sonra sabit PDF'e bir çizgi: etkin yüzey PDF.
    _pen(doc, y: 300);
    await tester.pump(const Duration(milliseconds: 400));
    expect(doc.ink, hasLength(2));
    // Kapsülü aç (önce ilk seferki ipucu kalksın), geri al'a dokun.
    await tester.pump(const Duration(seconds: 6));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byKey(const ValueKey('pen-dock-peek')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const ValueKey('pen-tray-undo')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(doc.ink, hasLength(1), reason: 'geri al PDF\'teki çizgiyi aldı');
    expect(page.ink, hasLength(1), reason: 'sayfadaki çizgi yerinde');
    await endEditor(tester);
  });
}
