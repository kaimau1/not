import '../l10n_ext.dart';

/// Bir zamanı ŞİMDİYE GÖRE okunur kılar: "az önce", "2 sa sonra",
/// "3 gün önce".
///
/// NEDEN: hatırlatıcı listesi zamanları yalnız mutlak biçimde yazıyordu
/// ("5 Eylül 2026, Cuma 14:30"). Kullanıcının aslında sorduğu soru "ne zaman?"
/// değil "ne kadar kaldı?" — mutlak tarihi okuyup bugünün tarihiyle kafadan
/// çıkarmak gerekiyordu. Mutlak tarih KALDI (satırın alt yazısı), göreli
/// etiket onun yanına eklendi.
///
/// Sınırlar bilerek kaba: 60 sn altı "az önce", 60 dk altı dakika, 24 sa altı
/// saat, ötesi gün. Hafta/ay yok — hatırlatıcılarda o uzaklıkta mutlak tarih
/// zaten daha okunur.
String relativeTimeLabel(AppLocalizations l10n, DateTime target, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final diff = target.difference(reference);
  final seconds = diff.inSeconds;
  if (seconds.abs() < 60) return l10n.relativeJustNow;
  final future = seconds > 0;
  final minutes = diff.inMinutes.abs();
  if (minutes < 60) {
    return future ? l10n.relativeInMinutes(minutes) : l10n.relativeAgoMinutes(minutes);
  }
  final hours = diff.inHours.abs();
  if (hours < 24) {
    return future ? l10n.relativeInHours(hours) : l10n.relativeAgoHours(hours);
  }
  final days = diff.inDays.abs();
  return future ? l10n.relativeInDays(days) : l10n.relativeAgoDays(days);
}
