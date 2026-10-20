import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/note_lock.dart';
import 'package:notlar/features/notes/presentation/lock/pattern_pad.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

void main() {
  group('not kilidi (F4.8)', () {
    test('şifre özetlenir, doğrusu açar, yanlışı açmaz', () {
      final config = createNoteLock(
        NoteLockMethod.password,
        'gizli123',
        iterations: 50,
        random: Random(1),
      );
      expect(config.hash, isNot(contains('gizli')));
      expect(verifyNoteLock(config, 'gizli123'), isTrue);
      expect(verifyNoteLock(config, 'gizli124'), isFalse);
      expect(verifyNoteLock(config, ''), isFalse);
    });

    test('desen de aynı yoldan; JSON gidiş-dönüş korunur', () {
      final secret = patternSecret([0, 1, 2, 5, 8]);
      final config = createNoteLock(
        NoteLockMethod.pattern,
        secret,
        biometric: true,
        iterations: 50,
      );
      final back = NoteLockConfig.fromJson(config.toJson());
      expect(back.method, NoteLockMethod.pattern);
      expect(back.biometric, isTrue);
      expect(verifyNoteLock(back, secret), isTrue);
      expect(verifyNoteLock(back, patternSecret([0, 1, 2, 5])), isFalse);
    });

    test('bozuk ya da sırsız kayıt cihaz kilidine düşer', () {
      expect(NoteLockConfig.fromJson(null).method, NoteLockMethod.device);
      expect(NoteLockConfig.fromJson('{x').method, NoteLockMethod.device);
      expect(
        NoteLockConfig.fromJson('{"method":"password"}').method,
        NoteLockMethod.device,
      );
    });

    test('PBKDF2-HMAC-SHA256 başvuru değerleriyle aynı', () {
      // Python hashlib.pbkdf2_hmac('sha256', b'passwd', b'salt', c, 32).
      expect(
        hashLockSecret('passwd', 'salt', 1),
        'VawEblbjCJ_sFpHCJUS2BflBhSFt3gRl5oudV8INrLw=',
      );
      expect(
        hashLockSecret('passwd', 'salt', 1000),
        '-pwVjmeL_pQYmwsacHoJIWcv3J8R-peIBZad8xLCyO8=',
      );
    });

    testWidgets('desen: atlanan orta nokta kendiliğinden eklenir', (
      tester,
    ) async {
      List<int>? got;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Center(
            child: PatternPad(size: 300, onComplete: (d) => got = d),
          ),
        ),
      );
      final origin = tester.getTopLeft(find.byType(PatternPad));
      // 0 (sol üst) → 2 (sağ üst): 1 aradan eklenmeli; sonra 5, 8.
      final g = await tester.startGesture(origin + const Offset(50, 50));
      await g.moveTo(origin + const Offset(150, 52));
      await g.moveTo(origin + const Offset(250, 50));
      await g.moveTo(origin + const Offset(250, 150));
      await g.moveTo(origin + const Offset(250, 250));
      await g.up();
      await tester.pump();
      expect(got, [0, 1, 2, 5, 8]);
    });
  });
}
