import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/auth/presentation/guest_backup_card.dart';

void main() {
  final now = DateTime(2026, 10, 19);
  test('misafir giriş kartı anonim hesapta ilk açılıştan itibaren', () {
    expect(
      shouldShowGuestReminder(anonymous: true, noteCount: 3, now: now),
      isTrue,
    );
    // Hiç not yokken de görünür: giriş yolu ilk karede bulunsun.
    expect(
      shouldShowGuestReminder(anonymous: true, noteCount: 0, now: now),
      isTrue,
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
