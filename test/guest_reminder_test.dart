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

  test('"Sonra"dan sonra şerit; 5 ve 20 notu geçince bir kez tam kart', () {
    expect(
      guestReminderMode(anonymous: true, noteCount: 2, laterAtCount: 1),
      GuestReminderMode.strip,
    );
    expect(
      guestReminderMode(anonymous: true, noteCount: 5, laterAtCount: 1),
      GuestReminderMode.full,
    );
    // 5'te yeniden "Sonra" → 20'ye kadar şerit.
    expect(
      guestReminderMode(anonymous: true, noteCount: 12, laterAtCount: 5),
      GuestReminderMode.strip,
    );
    expect(
      guestReminderMode(anonymous: true, noteCount: 20, laterAtCount: 5),
      GuestReminderMode.full,
    );
    // 20'den sonra hep şerit.
    expect(
      guestReminderMode(anonymous: true, noteCount: 300, laterAtCount: 21),
      GuestReminderMode.strip,
    );
  });
}
