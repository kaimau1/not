import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/auth/presentation/guest_backup_card.dart';

void main() {
  final now = DateTime(2026, 10, 19);
  test('misafir hatırlatması yalnız anonim hesapta, N nottan sonra', () {
    expect(
      shouldShowGuestReminder(anonymous: true, noteCount: 3, now: now),
      isTrue,
    );
    expect(
      shouldShowGuestReminder(anonymous: true, noteCount: 2, now: now),
      isFalse,
    );
    expect(
      shouldShowGuestReminder(anonymous: false, noteCount: 50, now: now),
      isFalse,
    );
  });

  test('"Sonra" süresi bitince kart geri gelir', () {
    expect(
      shouldShowGuestReminder(
        anonymous: true,
        noteCount: 5,
        now: now,
        snoozedUntil: now.add(const Duration(days: 1)),
      ),
      isFalse,
    );
    expect(
      shouldShowGuestReminder(
        anonymous: true,
        noteCount: 5,
        now: now,
        snoozedUntil: now.subtract(const Duration(minutes: 1)),
      ),
      isTrue,
    );
  });
}
