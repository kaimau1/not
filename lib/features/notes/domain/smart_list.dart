/// **AKILLI LİSTE — TÜR VE GRUP** (kullanıcı isteği 2026-11-16: "otomatik
/// tek tip şablon olsun; kişinin söylediklerine göre şablon türü
/// belirlensin — alışveriş listesi, bavul listesi vesaire. Alışverişte kasap,
/// meyve sebze, bakliyat ayrı toplansın ki reyona girince rahat alışveriş
/// yapsın; aynısı kıyafetler için de olabilir").
///
/// Saf Dart: tür tanıma ([smartKindFromPhrase], [smartKindOf],
/// [detectNoteListKind]), bavul + AL-3 ek tür sözlükleri (eczane, kırtasiye,
/// hırdavat, kamp, bebek, spor) ve sıralama ([smartRank],
/// [sortItemsBySmartGroup]). Market reyonları `quick_lexicon_data.dart`'ta
/// (grup 0–99); bavul grupları [kPackingGroupBase]'den başlar. Alt başlık YOK
/// (kullanıcı kararı 2026-11-16): gruplama maddelerin SIRASIYLA yapılır.
library;

import 'note.dart';
import 'note_item.dart';
import 'quick_entry.dart';
import 'quick_lexicon_data.dart';
import 'smart_lexicon_v2.dart';

enum SmartListKind {
  generic,
  shopping,
  packing,
  pharmacy,
  stationery,
  hardware,
  camping,
  baby,
  sport,
  moving,
  cleaning,
  habits,
  workout,
  gifts,
  watchlist,
  event,
  expense,
}

/// Kalıcı `Note.listKind` kimliği (null = sıradan/genel liste).
String? smartListKindId(SmartListKind kind) =>
    kind == SmartListKind.generic ? null : kind.name;

SmartListKind smartListKindFromId(String? id) {
  if (id == null || id.isEmpty) return SmartListKind.generic;
  for (final k in SmartListKind.values) {
    if (k.name == id) return k;
  }
  return SmartListKind.generic;
}

/// Bavul grupları, hazırlanma sırasıyla. Sözlükteki grup numarası
/// [kPackingGroupBase] + sıra.
enum PackingGroup { docs, clothes, care, health, tech }

const kPackingGroupBase = 200;
const kExtraGroupBase = 300;

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

/// AL-3 ek tür sözlükleri (Türkçe): her tür kendi alt gruplarıyla (liste
/// sırası = grup sırası).
const Map<SmartListKind, List<String>> kExtraListLexiconsTr = {
  SmartListKind.pharmacy: [
    'Ağrı kesici, Ateş düşürücü, Antibiyotik, Reçete, Mide ilacı, '
        'Alerji ilacı, Öksürük şurubu, Boğaz pastili, Burun spreyi, Göz damlası',
    'Vitamin, D vitamini, C vitamini, Magnezyum, Demir, Omega 3, Probiyotik',
    'Yara bandı, Sargı bezi, Gazlı bez, Tentürdiyot, Oksijenli su, '
        'Antiseptik krem, Yanık kremi, Termometre, Tansiyon aleti, Pamuk, Maske',
  ],
  SmartListKind.stationery: [
    'Defter, Kareli defter, Çizgili defter, Bloknot, A4 kağıt, Dosya, '
        'Klasör, Poşet dosya, Yapışkan not, Ajanda',
    'Kurşun kalem, Tükenmez kalem, Uçlu kalem, Kalem ucu, Fosforlu kalem, '
        'Keçeli kalem, Kuru boya, Pastel boya, Sulu boya, Silgi, Kalemtıraş',
    'Cetvel, Pergel, Makas, Yapıştırıcı, Pritt, Bant, Zımba, Ataç, '
        'Kalemlik, Sırt çantası, Beslenme çantası, Suluk',
  ],
  SmartListKind.hardware: [
    'Tornavida, Pense, İngiliz anahtarı, Çekiç, Metre, Su terazisi, '
        'Maket bıçağı, Matkap, Matkap ucu, Alyan anahtarı, Testere',
    'Vida, Çivi, Dübel, Somun, Pul, Klips, Kablo bağı, Silikon, '
        'Japon yapıştırıcı, Elektrik bandı, Koli bandı, Teflon bant',
    'Ampul, LED ampul, Priz, Üçlü priz, Uzatma kablosu, Pil, Sigorta, '
        'Boya, Fırça, Rulo, Zımpara, Tiner, Eldiven',
  ],
  SmartListKind.camping: [
    'Çadır, Çadır kazığı, Uyku tulumu, Mat, Şişme mat, Kamp yastığı, '
        'Tente, Hamak, Kamp sandalyesi, Kamp masası',
    'Kamp ocağı, Tüp, Çakmak, Kibrit, Termos, Kamp tenceresi, Çakı, '
        'Matara, Su bidonu, Çöp poşeti, Soğutucu çanta',
    'Kafa lambası, El feneri, Fener pili, Powerbank, Pusula, Düdük, '
        'İlk yardım çantası, Sivrisinek kovucu, Yağmurluk, Polar, İp',
  ],
  SmartListKind.baby: [
    'Bebek bezi, Islak mendil, Alt açma örtüsü, Pişik kremi, Bebek yağı, '
        'Bebek şampuanı, Kirli bez torbası',
    'Biberon, Emzik, Mama, Formül mama, Su termosu, Mama önlüğü, '
        'Bebek kaşığı, Alıştırma bardağı, Atıştırmalık',
    'Yedek zıbın, Yedek tulum, Çorap, Şapka, Müslin örtü, Battaniye, '
        'Oyuncak, Kanguru, Bebek arabası, Ateş ölçer',
  ],
  SmartListKind.sport: [
    'Spor ayakkabı, Şort, Tayt, Spor tişört, Spor çorap, Spor sütyeni, '
        'Eşofman, Yedek kıyafet, Terlik',
    'Spor havlusu, Matara, Protein shaker, Protein tozu, Duş jeli, '
        'Deodorant, Kirli çamaşır torbası, Asma kilit',
    'Kulaklık, Akıllı saat, Nabız bandı, Eldiven, Direnç bandı, Atlama ipi, '
        'Yoga matı, Köpük rulo',
  ],
};

const Map<SmartListKind, List<String>> kExtraListLexiconsEn = {
  SmartListKind.pharmacy: [
    'Painkillers, Fever medicine, Antibiotics, Prescription, Antacid, '
        'Allergy pills, Cough syrup, Throat lozenges, Nasal spray, Eye drops',
    'Vitamins, Vitamin D, Vitamin C, Magnesium, Iron, Omega 3, Probiotics',
    'Plasters, Bandage, Gauze, Antiseptic cream, Burn gel, Thermometer, '
        'Cotton pads, Face masks',
  ],
  SmartListKind.stationery: [
    'Notebook, Notepad, A4 paper, Folder, Binder, Sticky notes, Planner',
    'Pencil, Pen, Mechanical pencil, Highlighter, Markers, Coloured pencils, '
        'Eraser, Sharpener',
    'Ruler, Compass, Scissors, Glue stick, Tape, Stapler, Paperclips, '
        'Pencil case, Backpack, Lunch box, Water bottle',
  ],
  SmartListKind.hardware: [
    'Screwdriver, Pliers, Wrench, Hammer, Tape measure, Spirit level, '
        'Utility knife, Drill, Drill bits, Allen key, Saw',
    'Screws, Nails, Wall plugs, Nuts, Washers, Cable ties, Silicone, '
        'Superglue, Electrical tape, Packing tape',
    'Light bulb, LED bulb, Socket, Extension lead, Batteries, Paint, '
        'Paintbrush, Roller, Sandpaper, Work gloves',
  ],
  SmartListKind.camping: [
    'Tent, Tent pegs, Sleeping bag, Sleeping mat, Camping pillow, Tarp, '
        'Hammock, Camping chair, Camping table',
    'Camp stove, Gas canister, Lighter, Matches, Thermos, Camping pot, '
        'Pocket knife, Water bottle, Rubbish bags, Cooler bag',
    'Headlamp, Torch, Spare batteries, Power bank, Compass, Whistle, '
        'First aid kit, Insect repellent, Raincoat, Fleece, Rope',
  ],
  SmartListKind.baby: [
    'Nappies, Diapers, Wet wipes, Changing mat, Nappy cream, Baby oil, '
        'Baby shampoo, Nappy bags',
    'Baby bottle, Pacifier, Dummy, Formula, Baby food, Thermos, Bib, '
        'Baby spoon, Sippy cup, Snacks',
    'Spare onesie, Spare outfit, Baby socks, Baby hat, Muslin cloth, '
        'Blanket, Toy, Baby carrier, Pram, Thermometer',
  ],
  SmartListKind.sport: [
    'Trainers, Running shoes, Shorts, Leggings, Gym t-shirt, Sports socks, '
        'Sports bra, Tracksuit, Spare clothes, Flip flops',
    'Gym towel, Water bottle, Protein shaker, Protein powder, Shower gel, '
        'Deodorant, Laundry bag, Padlock',
    'Headphones, Smartwatch, Heart rate strap, Gym gloves, Resistance band, '
        'Jump rope, Yoga mat, Foam roller',
  ],
};

/// Dilin bavul sözlüğü (uygulama dili önce, sonra öbürü — market sözlüğü
/// gibi iki dilde de tanır).
Iterable<(String, int)> packingEntries(String locale) sync* {
  final tr = locale.startsWith('tr');
  final spec = kSmartKindSpecs[SmartListKind.packing];
  if (spec != null) {
    final seen = <String>{};
    for (final first in [tr, !tr]) {
      for (var g = 0; g < spec.groups.length; g++) {
        for (final item in spec.groups[g].items(isTr: first)) {
          final key = quickAscii(item);
          if (key.isNotEmpty && seen.add(key)) {
            yield (item, kPackingGroupBase + g);
          }
        }
      }
    }
    return;
  }
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

/// AL-3 / v2: [kind] türü için sözlük girdileri (grup numarası
/// [kExtraGroupBase] + tür/alt-grup sırası).
Iterable<(String, int)> extraListEntries(
  SmartListKind kind,
  String locale,
) sync* {
  final tr = locale.startsWith('tr');
  final base = kExtraGroupBase + kind.index * 10;
  final spec = kSmartKindSpecs[kind];
  if (spec != null &&
      kind != SmartListKind.shopping &&
      kind != SmartListKind.packing) {
    final seen = <String>{};
    for (final first in [tr, !tr]) {
      for (var g = 0; g < spec.groups.length; g++) {
        for (final item in spec.groups[g].items(isTr: first)) {
          final key = quickAscii(item);
          if (key.isNotEmpty && seen.add(key)) {
            yield (item, base + g);
          }
        }
      }
    }
    return;
  }
  for (final data
      in tr
          ? [kExtraListLexiconsTr, kExtraListLexiconsEn]
          : [kExtraListLexiconsEn, kExtraListLexiconsTr]) {
    final groups = data[kind];
    if (groups == null) continue;
    for (var g = 0; g < groups.length; g++) {
      for (final item in groups[g].split(',')) {
        final t = item.trim();
        if (t.isNotEmpty) yield (t, base + g);
      }
    }
  }
}

final Map<String, QuickLexicon> _packingCache = {};
final Map<String, QuickLexicon> _groceryCache = {};
final Map<(SmartListKind, String), QuickLexicon> _kindLexCache = {};

/// Yalnız bavul maddelerini tanıyan sözlük (sıralama ve tür için).
QuickLexicon packingLexicon(String locale) {
  final lang = locale.startsWith('tr') ? 'tr' : 'en';
  return _packingCache[lang] ??= () {
    final lex = QuickLexicon();
    for (final (text, group) in packingEntries(locale)) {
      lex.add(text, group: group);
    }
    return lex;
  }();
}

QuickLexicon _groceryLex(String locale) {
  final lang = locale.startsWith('tr') ? 'tr' : 'en';
  return _groceryCache[lang] ??= () {
    final lex = QuickLexicon();
    final tr = lang == 'tr';
    for (final data
        in tr
            ? [kQuickLexiconTr, kQuickLexiconEn]
            : [kQuickLexiconEn, kQuickLexiconTr]) {
      for (final e in data.entries) {
        for (final item in e.value.split(',')) {
          lex.add(item, group: e.key.index);
        }
      }
    }
    return lex;
  }();
}

/// [kind] türüne özel sözlük (AL-2/AL-3/v2 sıralama ve grup çözümü).
QuickLexicon lexiconForSmartKind(SmartListKind kind, String locale) {
  if (kind == SmartListKind.shopping) return _groceryLex(locale);
  if (kind == SmartListKind.packing) return packingLexicon(locale);
  if (kind == SmartListKind.generic) return QuickLexicon();
  final lang = locale.startsWith('tr') ? 'tr' : 'en';
  return _kindLexCache[(kind, lang)] ??= () {
    final lex = QuickLexicon();
    for (final (text, group) in extraListEntries(kind, locale)) {
      lex.add(text, group: group);
    }
    return lex;
  }();
}

const _packingWords = {
  'bavul',
  'valiz',
  'tatil',
  'seyahat',
  'yolculuk',
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
  'supermarket',
};

const _pharmacyWords = {
  'eczane',
  'ecza',
  'ilac',
  'ilaclar',
  'saglik',
  'pharmacy',
  'medicine',
  'medicines',
  'firstaid',
  'health',
};

const _stationeryWords = {
  'kirtasiye',
  'okul',
  'ofis',
  'stationery',
  'school',
  'office',
};

const _hardwareWords = {
  'hirdavat',
  'tamirat',
  'tamir',
  'nalbur',
  'alet',
  'hardware',
  'tools',
  'repair',
  'diy',
};

const _campingWords = {'kamp', 'dogayuruyusu', 'camping', 'camp', 'outdoor'};

const _babyWords = {'bebek', 'baby', 'diaper', 'nursery'};

const _sportWords = {
  'spor',
  'gym',
  'fitness',
  'workout',
  'antreman',
  'antrenman',
  'egzersiz',
  'exercise',
};

const _movingWords = {
  'tasinma',
  'nakliye',
  'evtasima',
  'moving',
  'relocation',
  'move',
};

const _cleaningWords = {
  'temizlik',
  'evtemizligi',
  'cleaning',
  'chores',
  'housework',
};

const _habitWords = {
  'aliskanlik',
  'rutin',
  'rutinim',
  'habit',
  'habits',
  'routine',
  'dailyroutine',
};

const _giftWords = {
  'hediye',
  'hediyeler',
  'gift',
  'gifts',
  'presents',
  'present',
};

const _watchlistWords = {
  'izlenecekler',
  'izlenecek',
  'film',
  'dizi',
  'watchlist',
  'movies',
  'shows',
};

const _eventWords = {
  'etkinlik',
  'parti',
  'davet',
  'dogumgunu',
  'kutlama',
  'piknik',
  'party',
  'event',
  'birthday',
  'picnic',
  'celebration',
};

const _expenseWords = {
  'butce',
  'harcama',
  'harcamalar',
  'gider',
  'giderler',
  'fatura',
  'faturalar',
  'budget',
  'expense',
  'expenses',
  'bills',
};

/// Türü adlandıran sözcüğün ardından gelebilenler ("bavul LİSTESİ",
/// "tatil İÇİN", "market ALIŞVERİŞİ", "ecza DOLABI").
const _kindMarkers = {
  'listesi',
  'listem',
  'liste',
  'list',
  'cantasi',
  'canta',
  'bag',
  'dolabi',
  'icin',
  'alisverisi',
  'malzemeleri',
  'ekipman',
  'ekipmani',
  'ekipmanlari',
  'esyalari',
  'plani',
  'planim',
  'plan',
  'planner',
  'programi',
  'program',
  'takibi',
  'takip',
  'tracker',
  'checklist',
  'routine',
  'schedule',
  'planning',
  'kit',
  'ideas',
  'fikirleri',
  'for',
  'ev',
  'home',
};

/// Yazılan/söylenen öbek liste TÜRÜNÜ mü adlandırıyor ("bavul listesi",
/// "alışveriş listesi", "eczane", "kamp listesi", "taşınma planı"). Öyleyse
/// madde değil başlık sayılır. En çok üç kelime; madde gibi duran uzun cümle
/// tür değildir.
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
  final w = core.single;
  if (_packingWords.contains(w)) return SmartListKind.packing;
  if (_shoppingWords.contains(w)) return SmartListKind.shopping;
  if (_pharmacyWords.contains(w)) return SmartListKind.pharmacy;
  if (_stationeryWords.contains(w)) return SmartListKind.stationery;
  if (_hardwareWords.contains(w)) return SmartListKind.hardware;
  if (_campingWords.contains(w)) return SmartListKind.camping;
  if (_babyWords.contains(w)) return SmartListKind.baby;
  if (_movingWords.contains(w)) return SmartListKind.moving;
  if (_cleaningWords.contains(w)) return SmartListKind.cleaning;
  if (_habitWords.contains(w)) return SmartListKind.habits;
  if (_giftWords.contains(w)) return SmartListKind.gifts;
  if (_watchlistWords.contains(w)) return SmartListKind.watchlist;
  if (_eventWords.contains(w)) return SmartListKind.event;
  if (_expenseWords.contains(w)) return SmartListKind.expense;
  if (_sportWords.contains(w)) {
    // "antrenman" / "workout" / "exercise" → workout, "spor çantası" / "gym bag" → sport.
    if (w == 'workout' ||
        w == 'exercise' ||
        w == 'antrenman' ||
        w == 'antreman') {
      return SmartListKind.workout;
    }
    if (words.contains('cantasi') ||
        words.contains('canta') ||
        words.contains('bag')) {
      return SmartListKind.sport;
    }
    if (w == 'spor' && words.length == 1) return SmartListKind.sport;
    return SmartListKind.sport;
  }
  return null;
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

/// Tüm 16 akıllı tür arasında maddelerden en iyi türü bulur (v2).
///
/// Önce alışveriş/bavul özel kontrolü (tek türe özgü maddelerle karar),
/// ardından bütün ek türlerde ≥ 2 eşleşme ile en yüksek puanlı tür seçilir.
SmartListKind detectSmartKindFromItems(
  Iterable<String> itemTexts, {
  required String locale,
}) {
  final texts = [
    for (final t in itemTexts)
      if (t.trim().isNotEmpty) t.trim(),
  ];
  if (texts.isEmpty) return SmartListKind.generic;
  final gLex = _groceryLex(locale);
  final pLex = packingLexicon(locale);
  var gOnly = 0;
  var pOnly = 0;
  for (final t in texts) {
    final g = gLex.groupOf(t) >= 0;
    final p = pLex.groupOf(t) >= 0;
    if (g && !p) gOnly++;
    if (p && !g) pOnly++;
  }
  var bestKind = SmartListKind.generic;
  var bestHits = 1;
  for (final kind in SmartListKind.values) {
    if (kind == SmartListKind.generic ||
        kind == SmartListKind.shopping ||
        kind == SmartListKind.packing) {
      continue;
    }
    final lex = lexiconForSmartKind(kind, locale);
    var hits = 0;
    for (final t in texts) {
      if (lex.groupOf(t) >= 0) hits++;
    }
    if (hits > bestHits) {
      bestHits = hits;
      bestKind = kind;
    }
  }
  if (bestHits >= 2 && bestHits >= gOnly && bestHits >= pOnly) {
    return bestKind;
  }
  if (pOnly > gOnly) return SmartListKind.packing;
  if (gOnly > 0) return SmartListKind.shopping;
  return SmartListKind.generic;
}

/// Bir notun akıllı liste türünü bulur (AL-2 + v2): önce kayıtlı
/// `note.listKind`, yoksa başlık öbeği (`smartKindFromPhrase`), yoksa
/// maddelerin eşleşmesi.
SmartListKind detectNoteListKind(Note note, {required String locale}) {
  final saved = smartListKindFromId(note.listKind);
  if (saved != SmartListKind.generic) return saved;
  final fromTitle = smartKindFromPhrase(note.displayTitle);
  if (fromTitle != null) return fromTitle;
  return detectSmartKindFromItems([
    for (final i in note.items)
      if (!i.header && i.text.trim().isNotEmpty) i.text,
  ], locale: locale);
}

/// Sıralama anahtarı: türün kendi grupları önce (reyon/bavul sırası), öbür
/// türün grupları sonra, tanınmayan en sonda (ekleme sırası korunur — bkz.
/// [quickSortByGroup]). [grocery]: market reyonu (yoksa -1), [packing]: bavul
/// grubu (yoksa -1).
int smartRank(
  SmartListKind kind, {
  required int grocery,
  required int packing,
  int extra = -1,
}) {
  final g = isGroceryGroup(grocery) ? grocery : -1;
  final p = isPackingGroup(packing) ? packing - kPackingGroupBase : -1;
  if (kind == SmartListKind.packing) {
    if (p >= 0) return p;
    if (g >= 0) return 100 + g;
    return -1;
  }
  if (kind != SmartListKind.shopping && kind != SmartListKind.generic) {
    if (extra >= 0) return extra;
    if (g >= 0) return 500 + g;
    if (p >= 0) return 600 + p;
    return -1;
  }
  if (g >= 0) return g;
  if (p >= 0) return 100 + p;
  return -1;
}

/// AL-2: editörde bir listenin maddelerini (alt başlık eklemeden) reyon /
/// grup sırasına dizer. İşaretliler sonda kalır, aynı gruptaki maddelerin
/// kendi sırası korunur; AL-4 [learnedGroups] kişisel kategori eşlemeleri
/// sözlüğün önüne geçer.
List<NoteItem> sortItemsBySmartGroup(
  List<NoteItem> items, {
  required SmartListKind kind,
  required String locale,
  Map<String, int> learnedGroups = const {},
}) {
  if (items.length < 2) return items;
  final effectiveKind = kind == SmartListKind.generic
      ? SmartListKind.shopping
      : kind;
  final gLex = _groceryLex(locale);
  final pLex = packingLexicon(locale);
  final extraLex =
      effectiveKind != SmartListKind.shopping &&
          effectiveKind != SmartListKind.packing
      ? lexiconForSmartKind(effectiveKind, locale)
      : null;

  int rankOf(NoteItem item) {
    final key = quickItemKey(item.text);
    final learned = learnedGroups[key];
    if (learned != null) return learned;
    return smartRank(
      effectiveKind,
      grocery: gLex.groupOf(item.text),
      packing: pLex.groupOf(item.text),
      extra: extraLex?.groupOf(item.text) ?? -1,
    );
  }

  final unchecked = <NoteItem>[];
  final checked = <NoteItem>[];
  for (final i in items) {
    if (i.checked && !i.header) {
      checked.add(i);
    } else {
      unchecked.add(i);
    }
  }
  final sortedUnchecked = quickSortByGroup(unchecked, rankOf);
  return [...sortedUnchecked, ...checked];
}

/// AL-2: mevcut bir listeye yeni [added] maddeleri eklerken (tür belliyse)
/// aynı reyon/gruptaki son işaretsiz maddenin hemen arkasına yerleştirir;
/// eşleşen grup yoksa işaretsizlerin sonuna (işaretlilerden önce) koyar.
List<NoteItem> insertItemsBySmartGroup(
  List<NoteItem> existing,
  List<NoteItem> added, {
  required SmartListKind kind,
  required String locale,
  Map<String, int> learnedGroups = const {},
}) {
  if (added.isEmpty) return existing;
  if (kind == SmartListKind.generic) return [...existing, ...added];
  final gLex = _groceryLex(locale);
  final pLex = packingLexicon(locale);
  final extraLex =
      kind != SmartListKind.shopping && kind != SmartListKind.packing
      ? lexiconForSmartKind(kind, locale)
      : null;

  int rankOf(NoteItem item) {
    final key = quickItemKey(item.text);
    final learned = learnedGroups[key];
    if (learned != null) return learned;
    return smartRank(
      kind,
      grocery: gLex.groupOf(item.text),
      packing: pLex.groupOf(item.text),
      extra: extraLex?.groupOf(item.text) ?? -1,
    );
  }

  final out = [...existing];
  for (final item in added) {
    final r = rankOf(item);
    var insertAt = -1;
    if (r >= 0) {
      for (var i = 0; i < out.length; i++) {
        if (!out[i].checked && !out[i].header && rankOf(out[i]) == r) {
          insertAt = i + 1;
        }
      }
    }
    if (insertAt < 0) {
      // Son işaretsiz maddeden hemen sonra (işaretli blok en sondaysa onun
      // önüne, liste karışık/tamamen işaretsizse en sona).
      final lastUnchecked = out.lastIndexWhere((i) => !i.checked && !i.header);
      insertAt = lastUnchecked >= 0 ? lastUnchecked + 1 : out.length;
    }
    out.insert(insertAt, item);
  }
  return out;
}
