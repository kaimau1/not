import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/data/reminder_service.dart';

void main() {
  // Sabit referans: "bugün" testin koştuğu güne göre kaymasın.
  final now = DateTime(2026, 7, 27, 14, 30);

  test('bugünkü hatırlatıcı "Bugün" der', () {
    expect(
      reminderTimePrefix(DateTime(2026, 7, 27, 9), now: now),
      'Bugün 09:00',
    );
  });

  test('yarınki hatırlatıcı "Yarın" der', () {
    expect(
      reminderTimePrefix(DateTime(2026, 7, 28, 9), now: now),
      'Yarın 09:00',
    );
  });

  test('daha uzağı tarihle söylenir', () {
    expect(
      reminderTimePrefix(DateTime(2026, 8, 3, 18, 5), now: now),
      '3 Ağu 18:05',
    );
  });

  // Asıl bug: "yarın saat 9" diye kurulan hatırlatıcı ERTESİ GÜN çaldığında
  // hâlâ "yarın" diyordu. Aynı hedef zaman, bir gün sonraki referans.
  test('yarın kurulan hatırlatıcı o gün gelince "Bugün" der', () {
    final target = DateTime(2026, 7, 28, 9);
    expect(reminderTimePrefix(target, now: now), 'Yarın 09:00');
    expect(
      reminderTimePrefix(target, now: DateTime(2026, 7, 28, 8, 59)),
      'Bugün 09:00',
    );
  });

  // ── BİLDİRİM METİNLERİNİN DİLİ ────────────────────────────────────────
  // 2026-09-05 taraması: bildirim metinleri koda Türkçe gömülüydü; arayüzü
  // başka dile alan kullanıcı her sabah Türkçe bildirim alıyordu. Servisin
  // BuildContext'i yok, çeviriler doğrudan delegeden yükleniyor.

  test('seçili dilde çeviri yüklenir', () async {
    final l10n = await loadNotificationL10n(const Locale('en'));
    expect(l10n.localeName, 'en');
    expect(l10n.dateToday, 'Today');
  });

  test('desteklenmeyen dilde şablon dile (Türkçe) düşülür', () async {
    final l10n = await loadNotificationL10n(const Locale('xx'));
    expect(l10n.dateToday, 'Bugün');
  });

  test('çeviri verilince önek o dilde yazılır', () async {
    final l10n = await loadNotificationL10n(const Locale('en'));
    expect(
      reminderTimePrefix(DateTime(2026, 7, 27, 9), now: now, l10n: l10n),
      'Today 09:00',
    );
    expect(
      reminderTimePrefix(DateTime(2026, 7, 28, 9), now: now, l10n: l10n),
      'Tomorrow 09:00',
    );
  });
}
