import 'dart:convert';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/editor/pdf_page_box.dart';
import 'package:notlar/features/notes/presentation/viewers/ink_layer.dart';
import 'package:notlar/features/notes/presentation/viewers/ink_tools.dart';

import 'support/editor_harness.dart';

/// **AKICILIK BÜTÇESİ** (OTURTMA F59.2, senaryolar Ek A). Sayılan şey süre
/// değil SAYI (kök kurulum, kayıt): makineden bağımsız. Bütçeler
/// `perf_budget/budgets.json`'da; mandal kuralı orada.
///
/// PDF'i çizdirmek pdfium ister (testte yok): kalem katmanı kurulmaz, ama
/// kutuya verilen [InkController] gerçek olanıdır — çizgi ona işlenir, yol
/// (denetleyici → bölme/tuval → editör → depo) cihazdakiyle aynıdır.
final Map<String, dynamic> _budgets =
    jsonDecode(File('test/perf_budget/budgets.json').readAsStringSync())
        as Map<String, dynamic>;

int _budget(String scenario, String key) =>
    (_budgets[scenario] as Map<String, dynamic>)[key] as int;

const _pdf = Attachment(
  id: 'p',
  kind: AttachmentKind.pdf,
  fileName: 'belge.pdf',
  mimeType: 'application/pdf',
  width: 600,
  height: 800,
);

Note _noteWith(Attachment a) => Note(
  id: 'n',
  type: NoteType.text,
  title: 'Başlık',
  body: 'yazı',
  attachments: [a],
);

final _pinnedPdf = _pdf.copyWith(pinHeight: 300);
final _embeddedPdf = _pdf.copyWith(onPage: true);

void _stylusDevice() {
  InkToolMemory.autoStylus = true;
  InkToolMemory.stylusEver = true;
  addTearDown(() => InkToolMemory.stylusEver = false);
}

InkController _inkOf(WidgetTester tester) =>
    tester.widget<PdfPageBox>(find.byType(PdfPageBox)).ink!;

int _pointer = 100;

/// Kalemle tek çizgi (katmanın yaptığı çağrılar) + 300 ms.
Future<void> _stroke(WidgetTester tester, InkController c, int i) async {
  const size = Size(300, 400);
  final p = _pointer++;
  final y = 20.0 + i * 12;
  c.pointerDown(
    1,
    Offset(20, y),
    size,
    pointer: p,
    kind: PointerDeviceKind.stylus,
  );
  c.pointerMove(1, Offset(80, y + 4), size, pointer: p);
  c.pointerMove(1, Offset(140, y + 8), size, pointer: p);
  c.pointerUp(pointer: p, kind: PointerDeviceKind.stylus);
  await tester.pump(const Duration(milliseconds: 300));
}

List<InkStroke> _savedInk(CountingNotesRepository repo) =>
    repo.lastSaved!.attachments.single.ink;

/// S6/S7 gövdesi: 10 çizgi → kök kurulum ve kayıt sayısı; sonra tuzak
/// (başka nedenle kök kurulumu çizgileri silmez) ve kapanışta veri kaybı yok.
Future<void> _tenStrokes(
  WidgetTester tester,
  String scenario,
  Attachment pdf,
) async {
  _stylusDevice();
  final repo = CountingNotesRepository();
  await pumpEditor(tester, _noteWith(pdf), repo: repo);
  final ink = _inkOf(tester);
  repo.resetCounts();
  final counter = BuildCounter()..start();
  addTearDown(counter.stop);

  for (var i = 0; i < 10; i++) {
    await _stroke(tester, ink, i);
  }
  // Kayıt gecikmesi (2 sn) dolsun.
  await tester.pump(const Duration(seconds: 3));
  final roots = counter.of('NoteEditorScreen');
  final saves = repo.updateNoteCalls;
  counter.stop();
  // ignore: avoid_print
  print('$scenario: kök kurulum $roots, updateNote $saves');
  expect(ink.ink, hasLength(10));
  expect(saves, greaterThan(0), reason: 'mürekkep kaydedilmeli');
  expect(_savedInk(repo), hasLength(10));
  expect(roots, lessThanOrEqualTo(_budget(scenario, 'kok_kurulum')));
  expect(saves, lessThanOrEqualTo(_budget(scenario, 'update_note')));

  // TUZAK 1: kök kurulmadığı için kutunun elindeki ek BAYAT (en çok ilk
  // çizgiyi bilir). Kutudan gelen mürekkep dışı değişiklik (sayfa çevirme)
  // o bayat listeyi geri yazıp çizgileri silmez.
  final stale = tester.widget<PdfPageBox>(find.byType(PdfPageBox));
  expect(stale.attachment.ink.length, lessThan(10));
  counter.start();
  stale.onChanged(stale.attachment.copyWith(pdfPage: 2));
  await tester.pump(const Duration(milliseconds: 300));
  counter.stop();
  expect(repo.lastSaved!.attachments.single.pdfPage, 2);
  expect(_savedInk(repo), hasLength(10));
  // TUZAK 2: başka nedenle gelen kök kurulumu (sayfa değişti) çizgileri ne
  // siler ne denetleyiciyi yeniler.
  expect(counter.of('NoteEditorScreen'), greaterThan(0));
  expect(identical(_inkOf(tester), ink), isTrue);
  expect(ink.ink, hasLength(10));
  expect(
    tester.widget<PdfPageBox>(find.byType(PdfPageBox)).attachment.ink,
    hasLength(10),
  );

  // KAPANIŞ: bekleyen (debounce'taki) çizgi not kapanırken yazılır.
  await _stroke(tester, ink, 10);
  expect(_savedInk(repo), hasLength(10), reason: 'henüz bekliyor');
  await endEditor(tester);
  expect(_savedInk(repo), hasLength(11));
}

void main() {
  test('her bütçenin nedeni yazılı (mandal kuralı)', () {
    for (final e in _budgets.entries) {
      if (e.key.startsWith('_')) continue;
      final neden = (e.value as Map<String, dynamic>)['neden'];
      expect(neden, isA<String>(), reason: e.key);
      expect((neden as String).trim(), isNotEmpty, reason: e.key);
    }
  });

  testWidgets('S6: sabit PDF\'e 10 çizgi — kök kurulum ve kayıt bütçesi', (
    tester,
  ) async {
    await _tenStrokes(tester, 'S6', _pinnedPdf);
  });

  testWidgets('S7: gömülü PDF\'e 10 çizgi — kök kurulum ve kayıt bütçesi', (
    tester,
  ) async {
    await _tenStrokes(tester, 'S7', _embeddedPdf);
  });
}
