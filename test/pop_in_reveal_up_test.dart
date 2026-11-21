import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/widgets/pop_in.dart';
import 'package:notlar/core/widgets/scale_settle.dart';

import 'support/editor_harness.dart';

class _CountingChild extends StatelessWidget {
  const _CountingChild({required this.onBuild});
  final VoidCallback onBuild;

  @override
  Widget build(BuildContext context) {
    onBuild();
    return const SizedBox(width: 48, height: 24);
  }
}

void main() {
  testWidgets(
    'T9 (K-37): PopIn animasyonu boyunca çocuk 1 kez kurulur, Opacity yerine FadeTransition kullanılır',
    (tester) async {
      var childBuilds = 0;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(),
            child: PopIn(child: _CountingChild(onBuild: () => childBuilds++)),
          ),
        ),
      );

      expect(childBuilds, 1);
      expect(find.byType(Opacity), findsNothing);
      expect(find.byType(FadeTransition), findsOneWidget);
      final render = tester.renderObject(find.byType(FadeTransition));
      expect(render, isA<RenderAnimatedOpacity>());

      // 15 ara kare (15 × 16 ms = 240 ms):
      // ÖNCE: TweenAnimationBuilder + Opacity + Transform.translate + Transform.scale = 4 × 15 = 60 kurulum
      // SONRA: AnimatedBuilder + tek Transform = 2 × 15 = 30 kurulum (Opacity=0, FadeTransition=0, çocuk=0).
      final counter = BuildCounter()..start();
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      counter.stop();

      expect(childBuilds, 1);
      expect(counter.of('Opacity'), 0);
      expect(counter.of('FadeTransition'), 0);
      final totalBuilds = counter.counts.values.fold<int>(0, (a, b) => a + b);
      expect(totalBuilds, lessThanOrEqualTo(30));

      await tester.pumpAndSettle();
      expect(childBuilds, 1);
      expect(
        tester.allRenderObjects.whereType<RenderOpacity>(),
        isEmpty,
        reason: 'RenderOpacity yerine FadeTransition (RenderAnimatedOpacity) kullanılır',
      );
      expect(
        tester.allRenderObjects.whereType<RenderAnimatedOpacity>().toSet(),
        hasLength(1),
      );
    },
  );

  testWidgets(
    'T9 (K-37): RevealUp animasyonu boyunca çocuk 1 kez kurulur, Opacity yerine FadeTransition kullanılır',
    (tester) async {
      var childBuilds = 0;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(),
            child: RevealUp(
              child: _CountingChild(onBuild: () => childBuilds++),
            ),
          ),
        ),
      );

      expect(childBuilds, 1);
      expect(find.byType(Opacity), findsNothing);
      expect(find.byType(FadeTransition), findsOneWidget);
      final render = tester.renderObject(find.byType(FadeTransition));
      expect(render, isA<RenderAnimatedOpacity>());

      // 17 ara kare (17 × 16 ms = 272 ms):
      // ÖNCE: TweenAnimationBuilder + Opacity + Transform.translate = 3 × 17 = 51 kurulum
      // SONRA: AnimatedBuilder + Transform = 2 × 17 = 34 kurulum (Opacity=0, FadeTransition=0, çocuk=0).
      final counter = BuildCounter()..start();
      for (var i = 0; i < 17; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      counter.stop();

      expect(childBuilds, 1);
      expect(counter.of('Opacity'), 0);
      expect(counter.of('FadeTransition'), 0);
      final totalBuilds = counter.counts.values.fold<int>(0, (a, b) => a + b);
      expect(totalBuilds, lessThanOrEqualTo(34));

      await tester.pumpAndSettle();
      expect(childBuilds, 1);
      expect(
        tester.allRenderObjects.whereType<RenderOpacity>(),
        isEmpty,
        reason: 'RenderOpacity yerine FadeTransition (RenderAnimatedOpacity) kullanılır',
      );
      expect(
        tester.allRenderObjects.whereType<RenderAnimatedOpacity>().toSet(),
        hasLength(1),
      );
    },
  );

  testWidgets(
    'T9 (K-37): hareketi azalt (motionOf=false) ve PopIn(animate:false) doğrudan çocuğu döndürür',
    (tester) async {
      var popBuilds = 0;
      var revealBuilds = 0;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Column(
              children: [
                PopIn(child: _CountingChild(onBuild: () => popBuilds++)),
                RevealUp(child: _CountingChild(onBuild: () => revealBuilds++)),
              ],
            ),
          ),
        ),
      );

      expect(popBuilds, 1);
      expect(revealBuilds, 1);
      expect(find.byType(FadeTransition), findsNothing);
      expect(find.byType(Opacity), findsNothing);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(),
            child: PopIn(
              animate: false,
              child: _CountingChild(onBuild: () => popBuilds++),
            ),
          ),
        ),
      );

      expect(find.byType(FadeTransition), findsNothing);
      expect(find.byType(Opacity), findsNothing);
    },
  );
}
