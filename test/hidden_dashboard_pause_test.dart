import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// F22.5 (AKICILIK_PLANI): editör telefonda tam ekran açıkken altta kalan
/// pano `TickerMode` kapalı kurulur → Riverpod 3 aboneliğini DURAKLATIR ve
/// türetilmiş süzgeç (`filteredNotesProvider` deseni) not akışının her
/// olayında yeniden HESAPLANMAZ; görünür olunca bir kez yetişir. Bu davranış
/// bozulursa (ör. süzgeci oturum boyu dinleyen bir servis eklenirse) her
/// otomatik kayıtta gizli pano tüm listeyi yeniden süzer/sıralar.
void main() {
  testWidgets('gizli (TickerMode kapalı) dinleyici türetilmişi hesaplatmaz', (
    tester,
  ) async {
    final source = NotifierProvider<_Counter, int>(_Counter.new);
    var computed = 0;
    final derived = Provider<int>((ref) {
      computed++;
      return ref.watch(source) * 2;
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);
    var visible = true;
    late StateSetter setOuter;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: StatefulBuilder(
          builder: (context, setState) {
            setOuter = setState;
            return TickerMode(
              enabled: visible,
              child: Consumer(
                builder: (context, ref, _) => Text(
                  '${ref.watch(derived)}',
                  textDirection: TextDirection.ltr,
                ),
              ),
            );
          },
        ),
      ),
    );
    expect(computed, 1);
    setOuter(() => visible = false);
    await tester.pump();
    for (var i = 1; i <= 5; i++) {
      container.read(source.notifier).set(i);
      await tester.pump();
    }
    expect(computed, 1, reason: 'gizliyken olay başına hesap yok');
    setOuter(() => visible = true);
    await tester.pump();
    expect(computed, 2, reason: 'görünür olunca tek yetişme');
    expect(find.text('10'), findsOneWidget);
  });
}

class _Counter extends Notifier<int> {
  @override
  int build() => 0;

  void set(int v) => state = v;
}
