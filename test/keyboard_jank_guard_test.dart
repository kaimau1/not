import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/presentation/editor/editor_quick_row.dart';
import 'package:notlar/features/notes/presentation/editor/note_editor_screen.dart';

/// **KLAVYE / YAZMA KASMASI BEKÇİSİ** (ölçüm 2026-11-10, kullanıcı: "son
/// güncellemelerden sonra klavye açılıp kapanırken titriyor, genel
/// yavaşlık"). A/B (11-06 tabanı → 11-09): yazarken UI işi ×3,3, klavye
/// aç/kapa +%65. İki kök neden; ikisi de burada kilitli.
void main() {
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
