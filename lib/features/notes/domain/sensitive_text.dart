import '../../../core/utils/search_fold.dart';
import 'note.dart';

/// **KARTTA HASSAS İÇERİK** (geliştirme raporu 2026-10-20, B1: "Şifreler
/// notunun içeriği herkesin görebileceği kartta").
///
/// İki düzey, ikisi de YALNIZ GÖSTERİM — saklanan metin değişmez:
/// * Parola notu ([isCredentialNote]): başlıkta ya da içerikte parola
///   sözcüğü geçen not. Kartta içerik hiç çizilmez; "kilitle" önerilir.
/// * Öbür notlarda uzun numaralar ([maskSensitiveNumbers]): IBAN ve kart
///   numarası son dört hanesi dışında `•` ile çizilir.

/// Parola sözcükleri — KATLANMIŞ metinde aranır (ş → s, İ → i; bkz.
/// [foldForSearch]). Harf/rakam komşusu olmayan tam sözcük: "pinterest",
/// "sifreleme" eşleşmesin diye sonda da sınır var.
final _credentialWord = RegExp(
  r'(?<![\p{L}\p{N}])(sifre|sifreler|sifrem|sifresi|parola|parolam|parolasi|'
  r'password|passwd|passcode|pin|pin kodu)(?![\p{L}\p{N}])',
  unicode: true,
);

/// IBAN: iki harf + iki rakam + 10-30 harf/rakam (4'lü gruplar boşluklu
/// da yazılabilir).
final _iban = RegExp(
  r'(?<![\p{L}\p{N}])[A-Za-z]{2}\d{2}(?:[ ]?[A-Za-z0-9]){10,30}(?![\p{L}\p{N}])',
  unicode: true,
);

/// Kart numarası: 13-19 rakam, arada tek boşluk ya da tire olabilir.
/// Telefon (10-11 hane) bilerek dışarıda: kartta numarası görünen kişi
/// notu sık, zararsız ve kullanıcı onu görmek istiyor.
final _cardNumber = RegExp(r'(?<!\d)\d(?:[ -]?\d){12,18}(?!\d)');

/// Notun başlığında ya da içeriğinde parola sözcüğü geçiyor mu?
bool isCredentialNote(Note note) {
  if (_hasCredentialWord(note.title)) return true;
  if (_hasCredentialWord(note.body)) return true;
  for (final item in note.items) {
    if (_hasCredentialWord(item.text)) return true;
  }
  return false;
}

bool _hasCredentialWord(String text) =>
    text.isNotEmpty && _credentialWord.hasMatch(foldForSearch(text));

/// IBAN ve kart numaralarının son dört hanesi dışını `•` ile örter.
/// Boşluk/tire korunur (metnin biçimi ve satır kırılımı değişmesin).
String maskSensitiveNumbers(String text) {
  if (text.length < 13) return text;
  var out = text.replaceAllMapped(_iban, (m) {
    final s = m[0]!;
    // Çoğu rakam olan dizi IBAN sayılır (düz sözcük ya da kod değil):
    // ülke kodu + kontrol + son dört görünür.
    if (s.replaceAll(RegExp(r'\D'), '').length < 10) return s;
    return _maskKeeping(s, keepStart: 4, keepEnd: 4);
  });
  out = out.replaceAllMapped(
    _cardNumber,
    (m) => _maskKeeping(m[0]!, keepStart: 0, keepEnd: 4),
  );
  return out;
}

/// Başta [keepStart], sonda [keepEnd] harf/rakam görünür; aradaki
/// harf/rakamlar `•` olur, ayırıcılar kalır.
String _maskKeeping(String s, {required int keepStart, required int keepEnd}) {
  final total = s.runes.where(_isAlnum).length;
  final buf = StringBuffer();
  var seen = 0;
  for (final r in s.runes) {
    if (!_isAlnum(r)) {
      buf.writeCharCode(r);
      continue;
    }
    final visible = seen < keepStart || seen >= total - keepEnd;
    buf.write(visible ? String.fromCharCode(r) : '•');
    seen++;
  }
  return buf.toString();
}

bool _isAlnum(int r) =>
    (r >= 0x30 && r <= 0x39) ||
    (r >= 0x41 && r <= 0x5A) ||
    (r >= 0x61 && r <= 0x7A);
