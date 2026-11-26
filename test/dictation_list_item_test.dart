import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/data/device_speech.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';

import 'support/editor_harness.dart';

/// KULLANICI BULGUSU 2026-11-19 (iki ekran görüntüsü): kontrol listesi
/// maddesine dikte ederken "yeni madde" denince madde çoğaldı — komuttan
/// sonraki HER ara sonuç ayrı madde oldu ("Olarak geçmiş ve." / "… ve son."
/// / "… son yeni." …). Kök neden: komutun `\n`'i eski maddenin alanına
/// yazılıp maddenin `commit`i çağrılıyordu; madde editörü satır sonunu
/// yapıştırma sayıp böldü, dikte eski alanda kaldığından her ara sonuçta
/// yeniden böldü.
void main() {
  testWidgets('dikte "yeni madde": tam 2 madde (dolu + devam eden)', (
    tester,
  ) async {
    const events = EventChannel('dev.kaimau.notlar/speech');
    const system = MethodChannel('dev.kaimau.notlar/system');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    MockStreamHandlerEventSink? sink;
    messenger
      ..setMockStreamHandler(
        events,
        MockStreamHandler.inline(
          onListen: (_, s) {
            sink = s;
          },
        ),
      )
      ..setMockMethodCallHandler(system, (_) async => null);
    DeviceSpeech.debugAvailable = true;
    addTearDown(() {
      DeviceSpeech.debugAvailable = null;
      messenger
        ..setMockStreamHandler(events, null)
        ..setMockMethodCallHandler(system, null);
    });
    const note = Note(
      id: 'd1',
      type: NoteType.checklist,
      title: 'Kanallarım',
      items: [NoteItem(id: 'a', text: '')],
    );
    final repo = CountingNotesRepository();
    await pumpEditor(tester, note, repo: repo, size: const Size(1200, 800));
    await tester.tap(find.byType(TextField).at(1));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byTooltip('Dikte').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(sink, isNotNull, reason: 'dikte başlamadı');

    const first = 'Olarak geçmiş ve son yeni dosyaları';
    for (final t in const [
      'Olarak geçmiş',
      'Olarak geçmiş ve',
      first,
      '$first yeni madde',
      '$first yeni madde birleştirme',
      '$first yeni madde birleştirme yani',
      '$first yeni madde birleştirme yani tek menüde',
    ]) {
      sink!.success({'text': t});
      await tester.pump(const Duration(milliseconds: 120));
    }
    await tester.tap(find.byKey(const ValueKey('dictation-stop')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump(const Duration(seconds: 3));

    final texts = [for (final i in repo.lastSaved!.items) i.text];
    expect(texts, [first, 'Birleştirme yani tek menüde']);
    await endEditor(tester);
  });

  // KULLANICI BULGUSU 2026-11-26: "sesle yazarken maddeye tıklamazsam madde
  // liste olanlarda normal metin ekliyor, normal madde olarak eklemesi
  // lazım" — madde seçilmeden başlayan dikte gövdeye (düz metin) yazıyordu.
  for (final type in const [NoteType.checklist, NoteType.ordered]) {
    for (final trailingEmpty in const [false, true]) {
      testWidgets('madde seçilmeden dikte → madde (${type.name}, '
          'sonda boş madde: $trailingEmpty)', (tester) async {
        const events = EventChannel('dev.kaimau.notlar/speech');
        const system = MethodChannel('dev.kaimau.notlar/system');
        final messenger =
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
        MockStreamHandlerEventSink? sink;
        messenger
          ..setMockStreamHandler(
            events,
            MockStreamHandler.inline(
              onListen: (_, s) {
                sink = s;
              },
            ),
          )
          ..setMockMethodCallHandler(system, (_) async => null);
        DeviceSpeech.debugAvailable = true;
        addTearDown(() {
          DeviceSpeech.debugAvailable = null;
          messenger
            ..setMockStreamHandler(events, null)
            ..setMockMethodCallHandler(system, null);
        });
        final note = Note(
          id: 'd2',
          type: type,
          title: 'Market',
          items: [
            const NoteItem(id: 'a', text: 'süt'),
            if (trailingEmpty) const NoteItem(id: 'b', text: ''),
          ],
        );
        final repo = CountingNotesRepository();
        await pumpEditor(tester, note, repo: repo, size: const Size(1200, 800));
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.tap(find.byTooltip('Dikte').first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(sink, isNotNull, reason: 'dikte başlamadı');
        for (final t in const [
          'ekmek',
          'ekmek yeni madde',
          'ekmek yeni madde yumurta',
        ]) {
          sink!.success({'text': t});
          await tester.pump(const Duration(milliseconds: 120));
        }
        await tester.tap(find.byKey(const ValueKey('dictation-stop')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump(const Duration(seconds: 3));

        final saved = repo.lastSaved!;
        expect(saved.body.trim(), isEmpty, reason: 'gövdeye düz metin yok');
        expect(
          [for (final i in saved.items) i.text],
          ['süt', 'Ekmek', 'Yumurta'],
        );
        if (trailingEmpty) expect(saved.items[1].id, 'b');
        await endEditor(tester);
      });
    }
  }
}
