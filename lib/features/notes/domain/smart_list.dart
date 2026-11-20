/// **AKILLI LİSTE — TÜR VE GRUP** (kullanıcı isteği 2026-11-16: "otomatik
/// tek tip şablon olsun; kişinin söylediklerine göre şablon türü
/// belirlensin — alışveriş listesi, bavul listesi vesaire. Alışverişte kasap,
/// meyve sebze, bakliyat ayrı toplansın ki reyona girince rahat alışveriş
/// yapsın; aynısı kıyafetler için de olabilir").
///
/// Saf Dart: tür tanıma ([smartKindFromPhrase], [smartKindOf]), bavul
/// sözlüğü ([kPackingLexiconTr]/[kPackingLexiconEn]) ve sıralama ([smartRank]).
/// Market reyonları `quick_lexicon_data.dart`'ta (grup 0–99); bavul grupları
/// [kPackingGroupBase]'den başlar. Alt başlık YOK (kullanıcı kararı
/// 2026-11-16): gruplama maddelerin SIRASIYLA yapılır.
library;

import 'quick_entry.dart';

enum SmartListKind { generic, shopping, packing }

/// Bavul grupları, hazırlanma sırasıyla. Sözlükteki grup numarası
/// [kPackingGroupBase] + sıra.
enum PackingGroup { docs, clothes, care, health, tech }

const kPackingGroupBase = 200;

bool isGroceryGroup(int g) => g >= 0 && g < 100;

bool isPackingGroup(int g) =>
    g >= kPackingGroupBase && g < kPackingGroupBase + 100;

/// Bavul sözlüğü (Türkçe). Biçim market sözlüğüyle aynı: grup başına
/// virgüllü tek dize, ilk harf büyük. Kişisel bakım maddelerinin bir kısmı
/// market sözlüğünde de var — onlar türü belirlemez (bkz. [smartKindOf]).
const Map<PackingGroup, String> kPackingLexiconTr = {
  PackingGroup.docs:
      'Kimlik, Pasaport, Vize, Ehliyet, Bilet, Uçak bileti, Biniş kartı, '
      'Otel rezervasyonu, Seyahat sigortası, Nakit, Kredi kartı, Cüzdan, '
      'Anahtar, Araç ruhsatı',
  PackingGroup.clothes:
      'Tişört, Gömlek, Bluz, Pantolon, Kot pantolon, Şort, Etek, Elbise, '
      'Kazak, Hırka, Sweatshirt, Mont, Ceket, Yağmurluk, İç çamaşırı, Çorap, '
      'Pijama, Mayo, Bikini, Şapka, Bere, Atkı, Eldiven, Kemer, Ayakkabı, '
      'Spor ayakkabı, Terlik, Sandalet, Bot, Takım elbise, Kravat, Eşofman, '
      'Tayt, Güneş gözlüğü, Plaj havlusu',
  PackingGroup.care:
      'Diş fırçası, Diş macunu, Diş ipi, Şampuan, Saç kremi, Duş jeli, '
      'Deodorant, Parfüm, Güneş kremi, Nemlendirici, Tıraş makinesi, '
      'Tıraş köpüğü, Jilet, Tarak, Saç fırçası, Saç kurutma makinesi, '
      'Makyaj çantası, Kontakt lens, Lens solüsyonu, Tırnak makası, '
      'Islak mendil, Havlu',
  PackingGroup.health:
      'İlaçlar, Ağrı kesici, Ateş düşürücü, Yara bandı, Mide ilacı, '
      'Alerji ilacı, Reçeteli ilaçlar, Sivrisinek kovucu, Maske, Termometre, '
      'Vitamin, El dezenfektanı',
  PackingGroup.tech:
      'Telefon, Şarj aleti, Telefon şarjı, Powerbank, Priz adaptörü, '
      'Kulaklık, Kablolar, Şarj kablosu, Laptop, Bilgisayar, Tablet, Kamera, '
      'Hafıza kartı, Kitap, Uzatma kablosu, Saat',
};

const Map<PackingGroup, String> kPackingLexiconEn = {
  PackingGroup.docs:
      'ID card, Passport, Visa, Driving licence, Tickets, Plane ticket, '
      'Boarding pass, Hotel booking, Travel insurance, Cash, Credit card, '
      'Wallet, Keys',
  PackingGroup.clothes:
      'T-shirt, Shirt, Blouse, Trousers, Jeans, Shorts, Skirt, Dress, '
      'Sweater, Cardigan, Hoodie, Coat, Jacket, Raincoat, Underwear, Socks, '
      'Pyjamas, Swimsuit, Bikini, Hat, Beanie, Scarf, Gloves, Belt, Shoes, '
      'Trainers, Slippers, Sandals, Boots, Suit, Tie, Tracksuit, Leggings, '
      'Sunglasses, Beach towel',
  PackingGroup.care:
      'Toothbrush, Toothpaste, Dental floss, Shampoo, Conditioner, '
      'Shower gel, Deodorant, Perfume, Sunscreen, Moisturiser, Razor, '
      'Shaving foam, Comb, Hairbrush, Hair dryer, Make-up bag, '
      'Contact lenses, Lens solution, Nail clippers, Wet wipes, Towel',
  PackingGroup.health:
      'Medicines, Painkillers, Plasters, Stomach medicine, Allergy pills, '
      'Prescription medicines, Insect repellent, Face masks, Thermometer, '
      'Vitamins, Hand sanitiser',
  PackingGroup.tech:
      'Phone, Charger, Phone charger, Power bank, Plug adapter, Headphones, '
      'Cables, Charging cable, Laptop, Tablet, Camera, Memory card, Book, '
      'Extension lead, Watch',
};

/// Dilin bavul sözlüğü (uygulama dili önce, sonra öbürü — market sözlüğü
/// gibi iki dilde de tanır).
Iterable<(String, int)> packingEntries(String locale) sync* {
  final tr = locale.startsWith('tr');
  for (final data
      in tr
          ? [kPackingLexiconTr, kPackingLexiconEn]
          : [kPackingLexiconEn, kPackingLexiconTr]) {
    for (final e in data.entries) {
      for (final item in e.value.split(',')) {
        final t = item.trim();
        if (t.isNotEmpty) yield (t, kPackingGroupBase + e.key.index);
      }
    }
  }
}

final Map<String, QuickLexicon> _packingCache = {};

/// Yalnız bavul maddelerini tanıyan sözlük (sıralama ve tür için; dil başına
/// bir kez kurulur — yalnız okunur, değiştirilmez).
QuickLexicon packingLexicon(String locale) =>
    _packingCache[locale.startsWith('tr') ? 'tr' : 'en'] ??= () {
      final lex = QuickLexicon();
      for (final (text, group) in packingEntries(locale)) {
        lex.add(text, group: group);
      }
      return lex;
    }();

const _packingWords = {
  'bavul',
  'valiz',
  'tatil',
  'seyahat',
  'yolculuk',
  'kamp',
  'gezi',
  'packing',
  'luggage',
  'suitcase',
  'trip',
  'travel',
  'holiday',
  'vacation',
};

const _shoppingWords = {
  'alisveris',
  'market',
  'bakkal',
  'pazar',
  'manav',
  'shopping',
  'grocery',
  'groceries',
};

/// Türü adlandıran sözcüğün ardından gelebilenler ("bavul LİSTESİ",
/// "tatil İÇİN", "market ALIŞVERİŞİ").
const _kindMarkers = {
  'listesi',
  'listem',
  'liste',
  'list',
  'cantasi',
  'icin',
  'alisverisi',
  'for',
};

/// Yazılan/söylenen öbek liste TÜRÜNÜ mü adlandırıyor ("bavul listesi",
/// "alışveriş listesi", "market", "tatil için"). Öyleyse madde değil başlık
/// sayılır. En çok üç kelime; madde gibi duran uzun cümle tür değildir.
SmartListKind? smartKindFromPhrase(String text) {
  final words = [
    for (final w in quickAscii(text).split(RegExp(r'[^a-z0-9]+')))
      if (w.isNotEmpty) w,
  ];
  if (words.isEmpty || words.length > 3) return null;
  final core = [
    for (final w in words)
      if (!_kindMarkers.contains(w)) w,
  ];
  if (core.length != 1) return null;
  // Tek başına "liste" türü adlandırmaz; işaretçisiz tek kelime ancak tür
  // sözcüğüyse.
  final w = core.single;
  if (_packingWords.contains(w)) return SmartListKind.packing;
  if (_shoppingWords.contains(w)) return SmartListKind.shopping;
  return null;
}

/// Not BAŞLIĞI türü söylüyor mu ("Bavul listesi", "Antalya tatili", "Market
/// listesi", "Kamp malzemeleri"): başlık kelimelerinden biri tür sözcüğü ya
/// da onun ekli hâliyse o tür; yoksa null (maddelere bakılır). Bavul önce:
/// "tatil alışverişi" bavul listesidir.
SmartListKind? smartKindOfTitle(String title) {
  if (_titleHas(title, _packingWords)) return SmartListKind.packing;
  if (_titleHas(title, _shoppingWords)) return SmartListKind.shopping;
  return null;
}

/// Başlık bir alışveriş listesini adlandırıyor mu ("Market listesi",
/// "Haftalık alışveriş", "Marketten"); bavul sözcüğüne bakılmaz.
bool titleSaysShopping(String title) => _titleHas(title, _shoppingWords);

/// Tür sözcüğünün ardından gelebilen ekler (ASCII). Kaba kök bulucu
/// (`quickStem`) burada fazla açgözlü: "pazartesi" → "pazar".
const _titleSuffixes = {
  'i', 'u', 'si', 'su', 'a', 'e', 'ya', 'ye', 'na', 'ne', //
  'im', 'um', 'in', 'un', 'imiz', 'umuz', //
  'de', 'da', 'te', 'ta', 'den', 'dan', 'ten', 'tan', //
  'deki', 'daki', 'teki', 'taki', 'nda', 'nde', //
  'ler', 'lar', 'leri', 'lari', 'lerim', 'larim', 'lik', 'ligi', 'ci',
};

// Tür sözcüğü ya da EKLİ hâli (ön ek değil): "tatili", "bavulum",
// "marketten" tutar; "pazartesi", "kampanya", "marketing" tutmaz.
bool _titleHas(String title, Set<String> kinds) {
  for (final w in quickAscii(title).split(RegExp(r'[^a-z0-9]+'))) {
    if (w.length < 3) continue;
    for (final k in kinds) {
      if (w == k ||
          (w.startsWith(k) && _titleSuffixes.contains(w.substring(k.length)))) {
        return true;
      }
    }
  }
  return false;
}

/// Maddelerden tür: yalnız TEK türe ait maddeler sayılır (şampuan hem
/// markette hem bavulda — karar vermez). Eşitlikte alışveriş (en yaygın
/// kullanım); hiç ipucu yoksa düz liste.
SmartListKind smartKindOf(Iterable<({bool grocery, bool packing})> items) {
  var g = 0;
  var p = 0;
  for (final i in items) {
    if (i.grocery && !i.packing) g++;
    if (i.packing && !i.grocery) p++;
  }
  if (p > g) return SmartListKind.packing;
  if (g > 0) return SmartListKind.shopping;
  return SmartListKind.generic;
}

/// Sıralama anahtarı: türün kendi grupları önce (reyon/bavul sırası), öbür
/// türün grupları sonra, tanınmayan en sonda (ekleme sırası korunur — bkz.
/// [quickSortByGroup]). [grocery]: market reyonu (yoksa -1), [packing]: bavul
/// grubu (yoksa -1).
int smartRank(
  SmartListKind kind, {
  required int grocery,
  required int packing,
}) {
  final g = isGroceryGroup(grocery) ? grocery : -1;
  final p = isPackingGroup(packing) ? packing - kPackingGroupBase : -1;
  if (kind == SmartListKind.packing) {
    if (p >= 0) return p;
    if (g >= 0) return 100 + g;
  } else {
    if (g >= 0) return g;
    if (p >= 0) return 100 + p;
  }
  return -1;
}
