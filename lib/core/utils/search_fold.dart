/// **TÜRKÇE/AKSAN DUYARSIZ ARAMA KATLAMASI** (F1.8, 2026-10-19).
///
/// Dart'ın `toLowerCase`'i dil bilmez: 'I'yı 'i' yapar ('ı' değil), 'İ'yi
/// İKİ karakterlik "i̇"ye çevirir. Sonuç: 'ılık' araması 'ILIK SU'yu
/// bulmuyordu, 'alisveris' 'alışveriş'i hiç bulmuyordu. Arama yapan her
/// yer iki tarafa da (metin + sorgu) bunu uygular.
///
/// Eşleme 1:1 KOD BİRİMİ: çıktı girdiyle aynı uzunlukta, aynı konumdaki
/// karakter — katlanmış metinde bulunan indeks özgün metinde de doğrudur
/// (vurgulama, not içi bul).
String foldForSearch(String s) {
  final units = s.codeUnits;
  List<int>? out;
  for (var i = 0; i < units.length; i++) {
    final c = units[i];
    final f = _fold(c);
    if (f != c) {
      out ??= List<int>.of(units);
      out[i] = f;
    }
  }
  return out == null ? s : String.fromCharCodes(out);
}

int _fold(int c) {
  // ASCII hızlı yol.
  if (c < 0x80) {
    return c >= 0x41 && c <= 0x5A ? c + 0x20 : c;
  }
  final mapped = _table[c];
  if (mapped != null) return mapped;
  // Öbür harfler: küçük harf karşılığı TEK kod birimiyse o, değilse kendisi
  // (uzunluk korunsun).
  final lower = String.fromCharCode(c).toLowerCase();
  return lower.length == 1 ? lower.codeUnitAt(0) : c;
}

const _i = 0x69, _s = 0x73, _g = 0x67, _u = 0x75, _o = 0x6F, _c = 0x63;
const _a = 0x61;

const _table = <int, int>{
  0x0130: _i, // İ
  0x0131: _i, // ı
  0x015E: _s, 0x015F: _s, // Ş ş
  0x011E: _g, 0x011F: _g, // Ğ ğ
  0x00DC: _u, 0x00FC: _u, // Ü ü
  0x00D6: _o, 0x00F6: _o, // Ö ö
  0x00C7: _c, 0x00E7: _c, // Ç ç
  0x00C2: _a, 0x00E2: _a, // Â â
  0x00CE: _i, 0x00EE: _i, // Î î
  0x00DB: _u, 0x00FB: _u, // Û û
};
