import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/calc.dart';

void main() {
  group('evaluateExpression', () {
    test('dört işlem ve öncelik', () {
      expect(evaluateExpression('2+3×4'), 14);
      expect(evaluateExpression('20−8÷2'), 16);
      expect(evaluateExpression('(2+3)×4'), 20);
      expect(evaluateExpression('10/4'), 2.5);
    });

    test('ondalık virgül ve nokta', () {
      expect(evaluateExpression('12,5×2'), 25);
      expect(evaluateExpression('1.5+1,5'), 3);
    });

    test('yüzde: önek ve sonek', () {
      expect(evaluateExpression('200×%10'), closeTo(20, 1e-9));
      expect(evaluateExpression('200×10%'), closeTo(20, 1e-9));
      expect(evaluateExpression('50%'), closeTo(0.5, 1e-9));
    });

    test('negatif ve boşluklar', () {
      expect(evaluateExpression('-5+3'), -2);
      expect(evaluateExpression(' 2 + 2 '), 4);
      expect(evaluateExpression('3×(-2)'), -6);
    });

    test('geçersiz ifadeler null döner', () {
      expect(evaluateExpression('2+'), isNull);
      expect(evaluateExpression('(2+3'), isNull);
      expect(evaluateExpression('abc'), isNull);
      expect(evaluateExpression('5/0'), isNull);
      expect(evaluateExpression(''), isNull);
    });
  });

  group('formatCalcResult', () {
    test('tam sayılar kesirsiz', () {
      expect(formatCalcResult(14), '14');
      expect(formatCalcResult(-3), '-3');
    });

    test('ondalıklar virgüllü ve sıfırsız', () {
      expect(formatCalcResult(2.5), '2,5');
      expect(formatCalcResult(0.1 + 0.2), '0,3');
    });
  });
}
