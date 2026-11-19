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
}
