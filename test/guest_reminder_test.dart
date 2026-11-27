import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/auth/presentation/guest_backup_card.dart';

void main() {
  test('misafir giriş kartı anonim hesapta ilk açılıştan itibaren tam', () {
    expect(
      guestReminderMode(anonymous: true, noteCount: 3),
      GuestReminderMode.full,
    );
    // Hiç not yokken de görünür: giriş yolu ilk karede bulunsun.
    expect(
      guestReminderMode(anonymous: true, noteCount: 0),
      GuestReminderMode.full,
    );
    expect(
      guestReminderMode(anonymous: false, noteCount: 50, laterAtCount: 0),
      GuestReminderMode.none,
    );
  });

  test('"Sonra"dan sonra şerit; 3, 12 ve 25 notu geçince bir kez tam kart', () {
    expect(
      guestReminderMode(anonymous: true, noteCount: 2, laterAtCount: 1),
      GuestReminderMode.strip,
    );
    expect(
      guestReminderMode(anonymous: true, noteCount: 3, laterAtCount: 1),
      GuestReminderMode.full,
    );
    // 3'te yeniden "Sonra" → 12'ye kadar şerit.
    expect(
      guestReminderMode(anonymous: true, noteCount: 8, laterAtCount: 3),
      GuestReminderMode.strip,
    );
    expect(
      guestReminderMode(anonymous: true, noteCount: 12, laterAtCount: 3),
      GuestReminderMode.full,
    );
    // 25'ten sonra hep şerit.
    expect(
      guestReminderMode(anonymous: true, noteCount: 300, laterAtCount: 25),
      GuestReminderMode.strip,
    );
  });
}
