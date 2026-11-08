/// **BİLDİRİM ÖNEM DÜZEYİ** (kullanıcı isteği 2026-11-08): hatırlatıcı
/// başına az / orta / sık / acil. Tekrar sıklığı DEĞİL; ses ve görünüm farkı
/// — her düzey ayrı Android bildirim kanalı (kanalın önemi kurulduktan sonra
/// değişmez, o yüzden düzey = kanal):
/// - az: sessiz, yalnız bildirim alanında,
/// - orta: normal ses, açılır pencere yok,
/// - sık: sesli ve ekranın üstünde öne çıkar (eski tek kanalın davranışı),
/// - acil: tam ekran + en yüksek öncelik (alarm kategorisi).
///
/// Kayıtta dize: notta `reminderLevel` (Note.extras), görevde `level`.
/// Boş dize = [high]: düzey seçilmeden kurulmuş eski hatırlatıcılar eskisi
/// gibi çalar.
enum ReminderLevel {
  low('low', 'reminders_low'),
  normal('normal', 'reminders_normal'),
  high('', 'reminders'),
  urgent('urgent', 'reminders_urgent');

  const ReminderLevel(this.id, this.channelId);

  /// Kayıttaki değer.
  final String id;

  /// Android bildirim kanalı ([high] eski `reminders` kanalı).
  final String channelId;

  static ReminderLevel parse(String? id) => switch (id) {
    'low' => low,
    'normal' => normal,
    'urgent' => urgent,
    _ => high,
  };
}
