import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/spell_learn.dart';
import 'package:notlar/core/widgets/ctrl_wheel_zoom.dart';
import 'package:notlar/features/notes/data/voice_listen_session.dart';
import 'package:notlar/features/notes/presentation/editor/auto_spell.dart';
import 'package:notlar/features/notes/presentation/editor/spell_underline.dart';
import 'package:notlar/features/notes/presentation/editor/text_wrap.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kullanıcı istekleri 2026-11-27: seçim menüsünde yazım önerisi, web'de
/// dikte akışı kapanınca oturumun bitmesi, Ctrl + tekerlek yazı boyutu.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('seçim menüsünde doğrusu (spellFixItems)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      AutoSpell.memory = SpellMemory();
      AutoSpell.mode.value = SpellMode.show;
      AutoSpell.beginNote();
      SpellMarks.debugReset();
    });
    tearDown(() {
      AutoSpell.mode.value = SpellMode.off;
      SpellMarks.debugReset();
    });

    testWidgets(
      'altı çizili kelime seçiliyken öneri gelir, dokununca düzelir',
      (tester) async {
        final c = WrapTextController(text: 'bir kalwm aldım');
        addTearDown(c.dispose);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: TextField(controller: c)),
          ),
        );
        final m = SpellMarks.acquire(c);
        addTearDown(m.release);
        for (var i = 0; i < 20; i++) {
          await tester.pump(Duration.zero);
        }
        expect(m.marks.single.word, 'kalwm');
        final state = tester.state<EditableTextState>(
          find.byType(EditableText),
        );

        // İmleç (seçim yok): olağan menüye eklenmez (yazım menüsü açılır).
        c.selection = const TextSelection.collapsed(offset: 6);
        expect(spellFixItems(state), isEmpty);

        // Basılı tutma kelimeyi seçer: öneri olağan menünün başına.
        c.selection = const TextSelection(baseOffset: 4, extentOffset: 9);
        final items = spellFixItems(state);
        expect(items.map((e) => e.label), contains('kalem'));
        items.firstWhere((e) => e.label == 'kalem').onPressed!();
        expect(c.text, 'bir kalem aldım');

        // Seçim altı çizili kelimenin dışına taşıyorsa öneri yok.
        c.text = 'bir kalwm aldım';
        for (var i = 0; i < 20; i++) {
          await tester.pump(SpellMarks.pause);
        }
        c.selection = const TextSelection(baseOffset: 0, extentOffset: 9);
        expect(spellFixItems(state), isEmpty);
        await tester.pump(const Duration(seconds: 5));
      },
    );
  });

  group('dikte akışı kapanınca oturum biter', () {
    const events = EventChannel('dev.kaimau.notlar/speech');
    tearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(events, null),
    );

    test('tanıyıcı akışı kendiliğinden kapatırsa onEnd(closed)', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(
            events,
            MockStreamHandler.inline(
              onListen: (args, sink) {
                sink.success({'text': 'merhaba'});
                sink.endOfStream();
              },
            ),
          );
      VoiceListenEnd? ended;
      final session = VoiceListenSession(
        onText: (_) {},
        onEnd: (r) => ended = r,
        autoStop: () => false,
      )..start();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(ended, VoiceListenEnd.closed);
      await session.cancel();
    });
  });

  testWidgets('Ctrl + tekerlek yakınlaştırır, Ctrl\'siz tekerlek dokunmaz', (
    tester,
  ) async {
    final zooms = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: CtrlWheelZoom(
          onZoom: zooms.add,
          child: ListView(
            children: [for (var i = 0; i < 50; i++) Text('satır $i')],
          ),
        ),
      ),
    );
    final center = tester.getCenter(find.byType(ListView));
    final pointer = TestPointer(1, PointerDeviceKind.mouse);

    await tester.sendEventToBinding(pointer.hover(center));
    await tester.sendEventToBinding(pointer.scroll(const Offset(0, 40)));
    await tester.pump();
    expect(zooms, isEmpty);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendEventToBinding(pointer.scroll(const Offset(0, -40)));
    await tester.sendEventToBinding(pointer.scroll(const Offset(0, 40)));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(zooms, [1, -1]);
  });
}
