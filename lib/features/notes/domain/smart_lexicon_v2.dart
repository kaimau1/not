import 'package:flutter/material.dart';

import 'quick_lexicon_data.dart';
import 'smart_list.dart';

/// Bir akıllı liste türünün alt grubu (etiket, ikon, renk, TR/EN maddeler).
///
/// DİKKAT: `terminology_test.dart` gereği burada `title:`, `label:`,
/// `subtitle:`, `message:` adlarıyla Türkçe metin geçirilmez; `nameTr`/`nameEn`
/// kalıbı kullanılır.
@immutable
class SmartGroupSpec {
  const SmartGroupSpec({
    required this.id,
    required this.nameTr,
    required this.nameEn,
    required this.icon,
    required this.color,
    required this.itemsTr,
    required this.itemsEn,
  });

  final String id;
  final String nameTr;
  final String nameEn;
  final IconData icon;
  final Color color;
  final String itemsTr;
  final String itemsEn;

  String label({required bool isTr}) => isTr ? nameTr : nameEn;

  List<String> items({required bool isTr}) => [
    for (final s in (isTr ? itemsTr : itemsEn).split(','))
      if (s.trim().isNotEmpty) s.trim(),
  ];
}

/// Tek dokunuşla eklenebilen hazır başlangıç paketi.
@immutable
class SmartStarterPack {
  const SmartStarterPack({
    required this.id,
    required this.nameTr,
    required this.nameEn,
    required this.descTr,
    required this.descEn,
    required this.icon,
    required this.itemsTr,
    required this.itemsEn,
    this.extrasByIndex = const {},
  });

  final String id;
  final String nameTr;
  final String nameEn;
  final String descTr;
  final String descEn;
  final IconData icon;
  final List<String> itemsTr;
  final List<String> itemsEn;

  /// Madde dizini → `NoteItem.extras` başlangıç verisi.
  final Map<int, Map<String, dynamic>> extrasByIndex;

  String name({required bool isTr}) => isTr ? nameTr : nameEn;

  String desc({required bool isTr}) => isTr ? descTr : descEn;

  List<String> items({required bool isTr}) => isTr ? itemsTr : itemsEn;
}

/// Bir akıllı liste türünün tüm v2 tanımı (gruplar, sözlük, başlangıç paketleri).
@immutable
class SmartKindSpec {
  const SmartKindSpec({
    required this.kind,
    required this.icon,
    required this.accent,
    required this.nameTr,
    required this.nameEn,
    required this.descTr,
    required this.descEn,
    required this.groups,
    required this.starterPacks,
    this.hasWorkspace = true,
  });

  final SmartListKind kind;
  final IconData icon;
  final Color accent;
  final String nameTr;
  final String nameEn;
  final String descTr;
  final String descEn;
  final List<SmartGroupSpec> groups;
  final List<SmartStarterPack> starterPacks;
  final bool hasWorkspace;

  String name({required bool isTr}) => isTr ? nameTr : nameEn;

  String desc({required bool isTr}) => isTr ? descTr : descEn;
}

// ── Alışveriş ─────────────────────────────────────────────────────────────

const _aisleColors = <QuickAisle, (IconData, Color, String, String)>{
  QuickAisle.produce: (
    Icons.eco_outlined,
    Color(0xFF2E7D32),
    'Manav',
    'Produce',
  ),
  QuickAisle.bakery: (
    Icons.bakery_dining_outlined,
    Color(0xFFD97706),
    'Fırın & Unlu',
    'Bakery',
  ),
  QuickAisle.breakfast: (
    Icons.egg_alt_outlined,
    Color(0xFF0284C7),
    'Süt & Kahvaltılık',
    'Dairy & Breakfast',
  ),
  QuickAisle.meat: (
    Icons.set_meal_outlined,
    Color(0xFFC62828),
    'Kasap & Balık',
    'Meat & Fish',
  ),
  QuickAisle.pantry: (
    Icons.kitchen_outlined,
    Color(0xFF8D6E63),
    'Bakliyat & Kiler',
    'Pantry',
  ),
  QuickAisle.drinks: (
    Icons.local_cafe_outlined,
    Color(0xFF00897B),
    'İçecek',
    'Drinks',
  ),
  QuickAisle.snacks: (
    Icons.cookie_outlined,
    Color(0xFFE65100),
    'Atıştırmalık',
    'Snacks',
  ),
  QuickAisle.frozen: (
    Icons.ac_unit_rounded,
    Color(0xFF1565C0),
    'Dondurulmuş',
    'Frozen',
  ),
  QuickAisle.cleaning: (
    Icons.cleaning_services_outlined,
    Color(0xFF00ACC1),
    'Temizlik',
    'Cleaning',
  ),
  QuickAisle.home: (
    Icons.home_repair_service_outlined,
    Color(0xFF5E35B1),
    'Ev & Gereç',
    'Home',
  ),
  QuickAisle.personal: (
    Icons.spa_outlined,
    Color(0xFFAD1457),
    'Kişisel Bakım',
    'Personal Care',
  ),
  QuickAisle.baby: (
    Icons.child_care_outlined,
    Color(0xFFEC407A),
    'Bebek',
    'Baby',
  ),
  QuickAisle.pet: (
    Icons.pets_outlined,
    Color(0xFF6D4C41),
    'Evcil Hayvan',
    'Pet',
  ),
};

List<SmartGroupSpec> _buildShoppingGroups() => [
  for (final aisle in QuickAisle.values)
    SmartGroupSpec(
      id: 'shop_${aisle.name}',
      nameTr: _aisleColors[aisle]!.$3,
      nameEn: _aisleColors[aisle]!.$4,
      icon: _aisleColors[aisle]!.$1,
      color: _aisleColors[aisle]!.$2,
      itemsTr: kQuickLexiconTr[aisle] ?? '',
      itemsEn: kQuickLexiconEn[aisle] ?? '',
    ),
];

// ── Tüm 16 akıllı tür kataloğu ────────────────────────────────────────────

final Map<SmartListKind, SmartKindSpec> kSmartKindSpecs = {
  SmartListKind.shopping: SmartKindSpec(
    kind: SmartListKind.shopping,
    icon: Icons.shopping_cart_outlined,
    accent: const Color(0xFF6DA84C),
    nameTr: 'Alışveriş listesi',
    nameEn: 'Shopping list',
    descTr: 'Reyonlara göre otomatik dizilim, bütçe ve mağaza kipi',
    descEn: 'Auto-sorted by aisle with budget and store mode',
    groups: _buildShoppingGroups(),
    starterPacks: const [
      SmartStarterPack(
        id: 'shop_weekly',
        nameTr: 'Haftalık temel sepet',
        nameEn: 'Weekly essentials',
        descTr: 'Ekmek, süt, yumurta, sebze ve temel mutfak ürünleri',
        descEn: 'Bread, milk, eggs, fresh produce and staples',
        icon: Icons.shopping_basket_outlined,
        itemsTr: [
          'Ekmek (2)',
          'Süt (2 lt)',
          'Yumurta (15 adet)',
          'Beyaz peynir (500 g)',
          'Yoğurt (1 kg)',
          'Domates (1 kg)',
          'Salatalık (500 g)',
          'Patates (2 kg)',
          'Soğan (1 kg)',
          'Zeytinyağı (1 lt)',
          'Tavuk göğsü (750 g)',
          'Tuvalet kâğıdı',
        ],
        itemsEn: [
          'Bread (2)',
          'Milk (2 lt)',
          'Eggs (15 pcs)',
          'Feta (500 g)',
          'Yogurt (1 kg)',
          'Tomatoes (1 kg)',
          'Cucumber (500 g)',
          'Potatoes (2 kg)',
          'Onions (1 kg)',
          'Olive oil (1 lt)',
          'Chicken breast (750 g)',
          'Toilet paper',
        ],
      ),
      SmartStarterPack(
        id: 'shop_breakfast',
        nameTr: 'Pazar kahvaltısı',
        nameEn: 'Sunday brunch',
        descTr: 'Serpme kahvaltı için peynir, zeytin, simit ve yumurta',
        descEn: 'Fresh bagels, cheeses, olives, eggs and spreads',
        icon: Icons.free_breakfast_outlined,
        itemsTr: [
          'Simit (4 adet)',
          'Beyaz peynir (300 g)',
          'Kaşar peyniri (250 g)',
          'Siyah zeytin (250 g)',
          'Yumurta (6 adet)',
          'Sucuk (250 g)',
          'Domates (500 g)',
          'Salatalık (500 g)',
          'Bal',
          'Kaymak',
          'Çay',
        ],
        itemsEn: [
          'Bagels (4 pcs)',
          'Feta (300 g)',
          'Cheddar (250 g)',
          'Black olives (250 g)',
          'Eggs (6 pcs)',
          'Sausages (250 g)',
          'Tomatoes (500 g)',
          'Cucumber (500 g)',
          'Honey',
          'Cream',
          'Black tea',
        ],
      ),
      SmartStarterPack(
        id: 'shop_clean',
        nameTr: 'Ev ve temizlik yenileme',
        nameEn: 'Home & cleaning refill',
        descTr: 'Deterjan, bulaşık tableti, kâğıt havlu ve poşetler',
        descEn: 'Detergent, dishwasher pods, paper towels and bags',
        icon: Icons.cleaning_services_outlined,
        itemsTr: [
          'Çamaşır deterjanı',
          'Yumuşatıcı',
          'Bulaşık makinesi tableti',
          'Bulaşık süngeri',
          'Yüzey temizleyici',
          'Cam temizleyici',
          'Kağıt havlu',
          'Tuvalet kağıdı',
          'Çöp poşeti',
        ],
        itemsEn: [
          'Laundry detergent',
          'Fabric softener',
          'Dishwasher tablets',
          'Sponges',
          'Surface cleaner',
          'Glass cleaner',
          'Paper towels',
          'Toilet paper',
          'Trash bags',
        ],
      ),
    ],
  ),
  SmartListKind.packing: SmartKindSpec(
    kind: SmartListKind.packing,
    icon: Icons.luggage_outlined,
    accent: const Color(0xFF2FA392),
    nameTr: 'Bavul ve seyahat',
    nameEn: 'Packing & travel',
    descTr: 'El bagajı/valiz ayrımı, güne göre ölçekleme ve sihirbaz',
    descEn: 'Cabin vs checked bag tags, day scaling & trip wizard',
    groups: const [
      SmartGroupSpec(
        id: 'pack_docs',
        nameTr: 'Belgeler ve para',
        nameEn: 'Documents & money',
        icon: Icons.badge_outlined,
        color: Color(0xFF1565C0),
        itemsTr:
            'Kimlik, Pasaport, Vize, Ehliyet, Bilet, Uçak bileti, Otobüs bileti, Biniş kartı, '
            'Otel rezervasyonu, Araç kiralama belgesi, Seyahat sigortası, Yurt dışı çıkış harcı, '
            'Nakit, Döviz, Kredi kartı, Banka kartı, Müze kart, İstanbulkart, Cüzdan, Anahtar, Ev anahtarı, Araç ruhsatı, Aşı kartı',
        itemsEn:
            'ID card, Passport, Visa, Driving licence, Tickets, Plane ticket, Train ticket, Boarding pass, '
            'Hotel booking, Car rental voucher, Travel insurance, Cash, Foreign currency, Credit card, Debit card, '
            'Museum pass, Transit card, Wallet, Keys, House keys, Car registration, Vaccination card',
      ),
      SmartGroupSpec(
        id: 'pack_clothes',
        nameTr: 'Giyim ve ayakkabı',
        nameEn: 'Clothes & footwear',
        icon: Icons.checkroom_outlined,
        color: Color(0xFF2FA392),
        itemsTr:
            'Tişört, Gömlek, Bluz, Kazak, Hırka, Sweatshirt, Polar, Pantolon, Kot pantolon, Kumaş pantolon, '
            'Şort, Etek, Elbise, Mont, Kaban, Trençkot, Ceket, Yağmurluk, Rüzgarlık, '
            'İç çamaşırı, Çorap, Termal içlik, Pijama, Gecelik, Sabahlık, '
            'Mayo, Bikini, Deniz şortu, Pareo, Şapka, Güneş şapkası, Bere, Atkı, Eldiven, Kemer, '
            'Ayakkabı, Spor ayakkabı, Yürüyüş ayakkabısı, Terlik, Parmak arası terlik, Sandalet, Bot, Topuklu ayakkabı, '
            'Takım elbise, Kravat, Eşofman, Tayt, Güneş gözlüğü, Plaj havlusu, Çamaşır torbası, Kirli torbası, Ayakkabı torbası',
        itemsEn:
            'T-shirt, Shirt, Blouse, Sweater, Cardigan, Hoodie, Fleece, Trousers, Jeans, Dress pants, '
            'Shorts, Skirt, Dress, Coat, Overcoat, Trench coat, Jacket, Raincoat, Windbreaker, '
            'Underwear, Socks, Thermal base layer, Pyjamas, Sleepwear, Dressing gown, '
            'Swimsuit, Bikini, Swim trunks, Cover-up, Hat, Sun hat, Beanie, Scarf, Gloves, Belt, '
            'Shoes, Trainers, Walking shoes, Slippers, Flip flops, Sandals, Boots, Dress shoes, '
            'Suit, Tie, Tracksuit, Leggings, Sunglasses, Beach towel, Laundry bag, Shoe bag',
      ),
      SmartGroupSpec(
        id: 'pack_care',
        nameTr: 'Kişisel bakım',
        nameEn: 'Toiletries & care',
        icon: Icons.spa_outlined,
        color: Color(0xFFAD1457),
        itemsTr:
            'Diş fırçası, Seyahat diş fırçası, Diş macunu, Diş ipi, Ağız suyu, Şampuan, Saç kremi, Duş jeli, Sabun, '
            'Deodorant, Parfüm, Güneş kremi, Güneş sonrası losyon, Nemlendirici, Dudak koruyucu, El kremi, '
            'Tıraş makinesi, Tıraş köpüğü, Jilet, Tarak, Saç fırçası, Saç kurutma makinesi, Saç düzleştirici, Toka, '
            'Makyaj çantası, Makyaj temizleme mendili, Pamuk, Kulak çubuğu, Kontakt lens, Lens solüsyonu, Lens kabı, Gözlük kutusu, '
            'Tırnak makası, Cımbız, Islak mendil, Cep mendili, Havlu, Mikrofiber havlu, Seyahat yastığı, Uyku maskesi, Kulak tıkacı',
        itemsEn:
            'Toothbrush, Travel toothbrush, Toothpaste, Dental floss, Mouthwash, Shampoo, Conditioner, Shower gel, Soap, '
            'Deodorant, Perfume, Sunscreen, After-sun lotion, Moisturiser, Lip balm, Hand cream, '
            'Razor, Shaving foam, Comb, Hairbrush, Hair dryer, Hair straightener, Hair ties, '
            'Make-up bag, Makeup wipes, Cotton pads, Cotton swabs, Contact lenses, Lens solution, Lens case, Glasses case, '
            'Nail clippers, Tweezers, Wet wipes, Pocket tissues, Towel, Microfiber towel, Neck pillow, Sleep mask, Earplugs',
      ),
      SmartGroupSpec(
        id: 'pack_health',
        nameTr: 'Sağlık ve ilk yardım',
        nameEn: 'Health & meds',
        icon: Icons.medical_services_outlined,
        color: Color(0xFFC62828),
        itemsTr:
            'İlaçlar, Reçeteli ilaçlar, Ağrı kesici, Ateş düşürücü, Mide ilacı, Bulantı ilacı, İshal ilacı, Alerji ilacı, '
            'Pastil, Burun spreyi, Göz damlası, Yara bandı, Ayak vurması bandı, Antiseptik krem, Yanık kremi, Kas gevşetici krem, '
            'Sivrisinek kovucu, Kaşıntı jeli, Maske, El dezenfektanı, Termometre, Vitamin, Elektrolit tozu',
        itemsEn:
            'Medicines, Prescription medicines, Painkillers, Fever medicine, Stomach medicine, Motion sickness pills, Allergy pills, '
            'Throat lozenges, Nasal spray, Eye drops, Plasters, Blister plasters, Antiseptic cream, Burn gel, Muscle rub, '
            'Insect repellent, Bite relief gel, Face masks, Hand sanitiser, Thermometer, Vitamins, Electrolytes',
      ),
      SmartGroupSpec(
        id: 'pack_tech',
        nameTr: 'Teknoloji ve kablo',
        nameEn: 'Tech & gear',
        icon: Icons.devices_outlined,
        color: Color(0xFF5E35B1),
        itemsTr:
            'Telefon, Şarj aleti, Telefon şarjı, Hızlı şarj başlığı, Powerbank, Priz adaptörü, Evrensel priz dönüştürücü, '
            'Kulaklık, Kablosuz kulaklık, Kulaklık şarj kablosu, Kablolar, Şarj kablosu, Type-C kablo, Lightning kablo, '
            'Laptop, Laptop şarjı, Tablet, E-kitap okuyucu, Kamera, Aksiyon kamerası, Yedek pil, Hafıza kartı, '
            'Selfie çubuğu, Tripod, Kitap, Dergi, Uzatma kablosu, Saat, Akıllı saat şarjı, Sırt çantası, Bel çantası, Asma kilit, Valiz etiketi, Şemsiye, Su matarası',
        itemsEn:
            'Phone, Charger, Phone charger, Fast charger brick, Power bank, Plug adapter, Universal travel adapter, '
            'Headphones, Earbuds, Charging cable, USB-C cable, Lightning cable, Cables, '
            'Laptop, Laptop charger, Tablet, E-reader, Camera, Action camera, Spare batteries, Memory card, '
            'Selfie stick, Tripod, Book, Magazine, Extension lead, Watch, Smartwatch charger, Daypack, Fanny pack, Padlock, Luggage tag, Umbrella, Water bottle',
      ),
    ],
    starterPacks: const [
      SmartStarterPack(
        id: 'pack_weekend',
        nameTr: 'Hafta sonu kaçamağı (2-3 gün)',
        nameEn: 'Weekend getaway (2-3 days)',
        descTr: 'Kabin boy çantaya sığan pratik 3 günlük paket',
        descEn: 'Carry-on ready 3-day city or weekend checklist',
        icon: Icons.weekend_outlined,
        itemsTr: [
          'Kimlik',
          'Cüzdan',
          'Anahtar',
          'Telefon şarjı',
          'Powerbank',
          'Kulaklık',
          'Tişört (3)',
          'Pantolon (2)',
          'İç çamaşırı (4)',
          'Çorap (4)',
          'Pijama',
          'Diş fırçası',
          'Diş macunu',
          'Deodorant',
          'Ağrı kesici',
        ],
        itemsEn: [
          'ID card',
          'Wallet',
          'Keys',
          'Phone charger',
          'Power bank',
          'Headphones',
          'T-shirt (3)',
          'Trousers (2)',
          'Underwear (4)',
          'Socks (4)',
          'Pyjamas',
          'Toothbrush',
          'Toothpaste',
          'Deodorant',
          'Painkillers',
        ],
        extrasByIndex: {
          0: {'pb': 'cabin'},
          1: {'pb': 'cabin'},
          2: {'pb': 'cabin'},
          3: {'pb': 'cabin'},
          4: {'pb': 'cabin'},
          5: {'pb': 'cabin'},
        },
      ),
      SmartStarterPack(
        id: 'pack_beach',
        nameTr: 'Yaz ve plaj tatili',
        nameEn: 'Summer & beach holiday',
        descTr: 'Mayo, güneş kremi, terlik ve yazlık kıyafetler',
        descEn: 'Swimwear, sunscreen, sandals and sunny essentials',
        icon: Icons.beach_access_outlined,
        itemsTr: [
          'Kimlik',
          'Otel rezervasyonu',
          'Mayo (2)',
          'Plaj havlusu',
          'Güneş kremi',
          'Güneş sonrası losyon',
          'Güneş gözlüğü',
          'Şapka',
          'Terlik',
          'Sandalet',
          'Tişört (5)',
          'Şort (3)',
          'Elbise',
          'Sivrisinek kovucu',
          'Su matarası',
          'Powerbank',
        ],
        itemsEn: [
          'ID card',
          'Hotel booking',
          'Swimsuit (2)',
          'Beach towel',
          'Sunscreen',
          'After-sun lotion',
          'Sunglasses',
          'Sun hat',
          'Flip flops',
          'Sandals',
          'T-shirt (5)',
          'Shorts (3)',
          'Dress',
          'Insect repellent',
          'Water bottle',
          'Power bank',
        ],
        extrasByIndex: {
          0: {'pb': 'cabin'},
          1: {'pb': 'cabin'},
          6: {'pb': 'wear'},
          15: {'pb': 'cabin'},
        },
      ),
      SmartStarterPack(
        id: 'pack_intl',
        nameTr: 'Yurt dışı ve uçak yolculuğu',
        nameEn: 'International flight',
        descTr: 'Pasaport, vize, priz dönüştürücü ve kabin konforu',
        descEn: 'Passport, visa, adapter and in-flight comfort',
        icon: Icons.flight_takeoff_outlined,
        itemsTr: [
          'Pasaport',
          'Vize',
          'Uçak bileti',
          'Seyahat sigortası',
          'Döviz',
          'Kredi kartı',
          'Evrensel priz dönüştürücü',
          'Powerbank',
          'Kulaklık',
          'Seyahat yastığı',
          'Uyku maskesi',
          'Kulak tıkacı',
          'Reçeteli ilaçlar',
          'Yedek tişört',
          'Diş fırçası',
        ],
        itemsEn: [
          'Passport',
          'Visa',
          'Plane ticket',
          'Travel insurance',
          'Foreign currency',
          'Credit card',
          'Universal travel adapter',
          'Power bank',
          'Headphones',
          'Neck pillow',
          'Sleep mask',
          'Earplugs',
          'Prescription medicines',
          'T-shirt',
          'Toothbrush',
        ],
        extrasByIndex: {
          0: {'pb': 'cabin'},
          1: {'pb': 'cabin'},
          2: {'pb': 'cabin'},
          3: {'pb': 'cabin'},
          4: {'pb': 'cabin'},
          5: {'pb': 'cabin'},
          7: {'pb': 'cabin'},
          8: {'pb': 'cabin'},
          9: {'pb': 'cabin'},
          12: {'pb': 'cabin'},
        },
      ),
    ],
  ),
  SmartListKind.habits: SmartKindSpec(
    kind: SmartListKind.habits,
    icon: Icons.repeat,
    accent: const Color(0xFF3FA37A),
    nameTr: 'Alışkanlık takibi',
    nameEn: 'Habit tracker',
    descTr: '7 günlük işaretleme, seri sayacı ve 30 günlük ısı haritası',
    descEn: '7-day tracker, streaks and 30-day dot heatmap',
    groups: const [
      SmartGroupSpec(
        id: 'habit_health',
        nameTr: 'Sağlık ve beden',
        nameEn: 'Health & body',
        icon: Icons.favorite_outline,
        color: Color(0xFF2E7D32),
        itemsTr:
            '8 bardak su, 2 litre su iç, 30 dakika yürüyüş, 10 bin adım, Erken yat, Erken uyan, '
            'Şekersiz gün, Vitamin al, İlaçlarını iç, Esneme, Postür kontrolü, Sağlıklı kahvaltı, '
            'Meyve ve sebze ye, Kahveyi azalt, Soğuk duş, Diş ipi kullan',
        itemsEn:
            '8 glasses of water, Drink 2L water, 30 min walk, 10k steps, Sleep early, Wake up early, '
            'No sugar day, Take vitamins, Take medication, Stretch, Posture check, Healthy breakfast, '
            'Eat fruits & veggies, Less coffee, Cold shower, Floss teeth',
      ),
      SmartGroupSpec(
        id: 'habit_mind',
        nameTr: 'Zihin ve odak',
        nameEn: 'Mind & focus',
        icon: Icons.self_improvement_outlined,
        color: Color(0xFF0284C7),
        itemsTr:
            '20 sayfa kitap, Meditasyon, Nefes egzersizi, Günlük yaz, Şükran notu, Ekransız bir saat, '
            'Sabah telefonu elleme, Yeni kelime öğren, Yabancı dil pratiği, Podkast dinle, '
            'Derin odak 45 dk, Yarını planla, Günü değerlendir, Sosyal medyayı sınırla',
        itemsEn:
            'Read 20 pages, Meditation, Breathing exercise, Journal, Gratitude note, 1 hour screen-free, '
            'No phone first 30 min, Learn new words, Language practice, Listen to podcast, '
            'Deep focus 45 min, Plan tomorrow, Evening review, Limit social media',
      ),
      SmartGroupSpec(
        id: 'habit_home',
        nameTr: 'Ev, iş ve düzen',
        nameEn: 'Home & order',
        icon: Icons.home_outlined,
        color: Color(0xFFD97706),
        itemsTr:
            'Yatağı topla, Bulaşığı bitir, 10 dakika toparlan, Masayı düzenle, Çöpleri çıkar, '
            'Bitkileri sula, Harcamalarını yaz, Gelen kutusunu sıfırla, Aileye ara, Evcil hayvanı gezdir',
        itemsEn:
            'Make the bed, Clear dishes, 10 min tidy up, Clear desk, Take out trash, '
            'Water plants, Log expenses, Inbox zero, Call family, Walk the pet',
      ),
    ],
    starterPacks: const [
      SmartStarterPack(
        id: 'habit_morning',
        nameTr: 'Enerjik sabah rutini',
        nameEn: 'Morning routine',
        descTr: 'Su, hareket, kısa okuma ve güne hazırlık',
        descEn: 'Hydrate, move, read and plan your day',
        icon: Icons.wb_sunny_outlined,
        itemsTr: [
          'Yatağı topla',
          '2 bardak su iç',
          '10 dk esneme',
          '20 sayfa kitap',
          'Günün 3 hedefini yaz',
        ],
        itemsEn: [
          'Make the bed',
          'Drink water',
          '10 min stretch',
          'Read 20 pages',
          'Write top 3 goals',
        ],
        extrasByIndex: {
          0: {'ht': 'morning', 'hf': 7},
          1: {'ht': 'morning', 'hf': 7},
          2: {'ht': 'morning', 'hf': 5},
          3: {'ht': 'morning', 'hf': 5},
          4: {'ht': 'morning', 'hf': 5},
        },
      ),
      SmartStarterPack(
        id: 'habit_wellness',
        nameTr: 'Sağlıklı yaşam dengesi',
        nameEn: 'Daily wellness',
        descTr: 'Su, adım, uyku, vitamin ve ekransız akşam',
        descEn: 'Hydration, steps, sleep and screen-free wind-down',
        icon: Icons.spa_outlined,
        itemsTr: [
          '8 bardak su',
          '30 dakika yürüyüş',
          'Vitamin al',
          'Şekersiz gün',
          'Ekransız bir saat',
          'Erken yat',
        ],
        itemsEn: [
          '8 glasses of water',
          '30 min walk',
          'Take vitamins',
          'No sugar day',
          '1 hour screen-free',
          'Sleep early',
        ],
        extrasByIndex: {
          0: {'ht': 'afternoon', 'hf': 7},
          1: {'ht': 'afternoon', 'hf': 5},
          2: {'ht': 'morning', 'hf': 7},
          3: {'ht': 'afternoon', 'hf': 5},
          4: {'ht': 'evening', 'hf': 6},
          5: {'ht': 'evening', 'hf': 6},
        },
      ),
    ],
  ),
  SmartListKind.moving: SmartKindSpec(
    kind: SmartListKind.moving,
    icon: Icons.local_shipping_outlined,
    accent: const Color(0xFFB8864B),
    nameTr: 'Taşınma planı',
    nameEn: 'Moving planner',
    descTr: 'Zaman çizelgesi, oda bazlı koli takibi ve kırılacak etiketi',
    descEn: 'Moving timeline, room box tracker and fragile tags',
    groups: const [
      SmartGroupSpec(
        id: 'move_month',
        nameTr: '1 ay önce · Hazırlık',
        nameEn: '1 month before',
        icon: Icons.calendar_month_outlined,
        color: Color(0xFFB8864B),
        itemsTr:
            'Nakliyeci firmalardan teklif al, Nakliye günü rezervasyonu, Koli ve bant al, Balonlu naylon al, '
            'Streç film al, Keçeli kalem ve etiket al, Fazla eşyaları ayıkla, Kullanılmayanları sat veya bağışla, '
            'Yeni ev ölçümü al, Perde ve halı ölçüsü al, Okul ve iş izni ayarla',
        itemsEn:
            'Get mover quotes, Book moving company, Buy boxes & tape, Buy bubble wrap, '
            'Buy stretch wrap, Buy markers & labels, Declutter items, Donate or sell unused items, '
            'Measure new home rooms, Measure curtains & rugs, Arrange moving day off',
      ),
      SmartGroupSpec(
        id: 'move_week',
        nameTr: '1 hafta önce · Paketleme ve abonelik',
        nameEn: '1 week before',
        icon: Icons.inventory_outlined,
        color: Color(0xFFD97706),
        itemsTr:
            'Mutfak eşyalarını paketle, Kırılacakları sar, Kitap ve belgeleri kolile, Kışlık/yazlık kıyafetleri vakumla, '
            'Kolileri oda adıyla etiketle, Mobilyaları sök, Beyaz eşya bağlantısını kestir, '
            'Elektrik aboneliği başvurusu, Su aboneliği başvurusu, Doğalgaz aboneliği başvurusu, İnternet nakil başvurusu, '
            'Adres değişikliği bildir, Asansör ve site yönetiminden izin al, Buzdolabını çöz ve temizle',
        itemsEn:
            'Pack kitchenware, Wrap fragile items, Box books & documents, Pack seasonal clothes, '
            'Label boxes by room, Disassemble furniture, Disconnect appliances, '
            'Transfer electricity, Transfer water utility, Transfer gas utility, Schedule internet move, '
            'Update mailing address, Reserve building elevator, Defrost & clean fridge',
      ),
      SmartGroupSpec(
        id: 'move_day',
        nameTr: 'Taşınma günü',
        nameEn: 'Moving day',
        icon: Icons.local_shipping_outlined,
        color: Color(0xFFC62828),
        itemsTr:
            'İlk gece çantası hazırla, Değerli eşya ve belgeleri yanına al, Yedek kıyafet ve şarj aleti ayır, '
            'Eski ev sayaç fotoğrafı çek, Eski evi son kez kontrol et, Eski ev temizliğini yap, '
            'Anahtar teslimi, Yeni ev sayaç fotoğrafı çek, Koli sayımını kontrol et, Nakliyeci ödemesini yap, Yatakları kur',
        itemsEn:
            'Pack first-night bag, Keep valuables & documents with you, Set aside chargers & toiletries, '
            'Photo old utility meters, Final walkthrough old home, Clean old place, '
            'Hand over old keys, Photo new utility meters, Check box count, Pay movers, Assemble beds',
      ),
      SmartGroupSpec(
        id: 'move_after',
        nameTr: 'Yeni evde ilk hafta',
        nameEn: 'First week in new home',
        icon: Icons.home_outlined,
        color: Color(0xFF2E7D32),
        itemsTr:
            'Önce açılacak kolileri yerleştir, Kilitleri ve bareli değiştir, İnternet kurulumu, '
            'Beyaz eşya servis kurulumu, E-devlet ikametgâh taşıma, Banka ve kargo adreslerini güncelle, '
            'Aile hekimi kaydını güncelle, Acil çıkış ve vanaları öğren, Komşularla tanış, Boş kolileri topla',
        itemsEn:
            'Unpack open-first boxes, Change door locks, Internet installation, '
            'Appliance hookups, Update official residence address, Update bank & delivery addresses, '
            'Register with local clinic, Locate main water & gas shutoffs, Meet neighbours, Recycle empty boxes',
      ),
    ],
    starterPacks: const [
      SmartStarterPack(
        id: 'move_full',
        nameTr: 'Tam ev taşınma planı',
        nameEn: 'Complete home move',
        descTr: 'Öncesi, abonelikler, taşınma günü ve yeni ev adımları',
        descEn: 'Prep, utilities, moving day and settling-in checklist',
        icon: Icons.home_work_outlined,
        itemsTr: [
          'Nakliyeci ayarla',
          'Koli, bant ve balonlu naylon al',
          'Mutfak kırılacaklarını paketle',
          'Kıyafet ve gardırop kolile',
          'Elektrik, su, doğalgaz aboneliği',
          'İnternet nakil başvurusu',
          'İlk gece çantası hazırla',
          'Sayaçların fotoğrafını çek',
          'Anahtar teslimi',
          'Kilitleri değiştir',
          'İkametgâh ve adres güncelle',
        ],
        itemsEn: [
          'Book movers',
          'Buy boxes, tape & bubble wrap',
          'Pack fragile kitchenware',
          'Pack wardrobe boxes',
          'Transfer electricity, water & gas',
          'Schedule internet transfer',
          'Prepare first-night bag',
          'Photograph utility meters',
          'Hand over old keys',
          'Change door locks',
          'Update official address',
        ],
        extrasByIndex: {
          0: {'mp': 'month', 'mr': 'general'},
          1: {'mp': 'month', 'mr': 'general'},
          2: {'mp': 'week', 'mr': 'kitchen', 'mb': '#1', 'mf': true},
          3: {'mp': 'week', 'mr': 'bedroom', 'mb': '#2'},
          4: {'mp': 'week', 'mr': 'general'},
          5: {'mp': 'week', 'mr': 'study'},
          6: {'mp': 'day', 'mr': 'bedroom', 'mu': true},
          7: {'mp': 'day', 'mr': 'general'},
          8: {'mp': 'day', 'mr': 'general'},
          9: {'mp': 'new_home', 'mr': 'general', 'mu': true},
          10: {'mp': 'new_home', 'mr': 'general'},
        },
      ),
    ],
  ),
  SmartListKind.workout: SmartKindSpec(
    kind: SmartListKind.workout,
    icon: Icons.fitness_center,
    accent: const Color(0xFFE07A3A),
    nameTr: 'Antrenman programı',
    nameEn: 'Workout planner',
    descTr: 'Set × tekrar takibi, ağırlık ve dahili dinlenme sayacı',
    descEn: 'Interactive sets × reps, weight & built-in rest timer',
    groups: const [
      SmartGroupSpec(
        id: 'work_warmup',
        nameTr: 'Isınma ve mobilite',
        nameEn: 'Warm-up & mobility',
        icon: Icons.whatshot_outlined,
        color: Color(0xFFD97706),
        itemsTr: 'Isınma yürüyüşü, Kol çevirme, Kalça mobilite, Jumping jack, İp atlama, Dinamik esneme, Köpük rulo masajı',
        itemsEn: 'Warm-up walk, Arm circles, Hip mobility, Jumping jacks, Jump rope, Dynamic stretch, Foam rolling',
      ),
      SmartGroupSpec(
        id: 'work_upper',
        nameTr: 'Üst vücut',
        nameEn: 'Upper body',
        icon: Icons.fitness_center,
        color: Color(0xFFE07A3A),
        itemsTr:
            'Şınav, Bench press, İncline dumbbell press, Dumbbell fly, Barfiks, Lat pulldown, Seated row, Barbell row, '
            'Omuz pres, Lateral raise, Face pull, Biceps curl, Hammer curl, Triceps dips, Triceps pushdown, Skull crusher',
        itemsEn:
            'Push-ups, Bench press, Incline dumbbell press, Dumbbell fly, Pull-ups, Lat pulldown, Seated row, Barbell row, '
            'Shoulder press, Lateral raise, Face pull, Biceps curl, Hammer curl, Triceps dips, Triceps pushdown, Skull crusher',
      ),
      SmartGroupSpec(
        id: 'work_lower',
        nameTr: 'Alt vücut',
        nameEn: 'Lower body',
        icon: Icons.directions_run_outlined,
        color: Color(0xFF0284C7),
        itemsTr:
            'Squat, Goblet squat, Leg press, Lunge, Bulgarian split squat, Deadlift, Romanian deadlift, '
            'Leg curl, Leg extension, Kalça köprüsü, Hip thrust, Baldır kaldırma, Duvar oturuşu, Step-up',
        itemsEn:
            'Squat, Goblet squat, Leg press, Lunges, Bulgarian split squat, Deadlift, Romanian deadlift, '
            'Leg curl, Leg extension, Glute bridge, Hip thrust, Calf raises, Wall sit, Step-ups',
      ),
      SmartGroupSpec(
        id: 'work_core',
        nameTr: 'Merkez (Core) ve kardiyo',
        nameEn: 'Core & cardio',
        icon: Icons.timer_outlined,
        color: Color(0xFF2E7D32),
        itemsTr:
            'Plank, Yan plank, Mekik, Crunch, Leg raise, Russian twist, Mountain climber, Bicycle crunch, Dead bug, '
            'Koşu, Tempolu yürüyüş, Bisiklet, Eliptik, Kürek çekme, Burpee, HIIT sprint, Esneme ve soğuma',
        itemsEn:
            'Plank, Side plank, Sit-ups, Crunches, Leg raises, Russian twist, Mountain climbers, Bicycle crunch, Dead bug, '
            'Running, Brisk walk, Cycling, Elliptical, Rowing, Burpees, HIIT sprints, Cool-down stretch',
      ),
    ],
    starterPacks: const [
      SmartStarterPack(
        id: 'work_fullbody',
        nameTr: 'Evde tüm vücut (30 dk)',
        nameEn: 'Home full body (30 min)',
        descTr: 'Ekipmansız ısınma, kuvvet ve core setleri',
        descEn: 'No-equipment warm-up, strength and core sets',
        icon: Icons.bolt_outlined,
        itemsTr: [
          'Jumping jack',
          'Squat',
          'Şınav',
          'Lunge',
          'Kalça köprüsü',
          'Plank',
          'Esneme ve soğuma',
        ],
        itemsEn: [
          'Jumping jacks',
          'Squat',
          'Push-ups',
          'Lunges',
          'Glute bridge',
          'Plank',
          'Cool-down stretch',
        ],
        extrasByIndex: {
          0: {'wg': 'warmup', 'ws': 2, 'wr': '45 sn'},
          1: {'wg': 'lower', 'ws': 3, 'wr': '15'},
          2: {'wg': 'upper', 'ws': 3, 'wr': '12'},
          3: {'wg': 'lower', 'ws': 3, 'wr': '10'},
          4: {'wg': 'lower', 'ws': 3, 'wr': '15'},
          5: {'wg': 'core', 'ws': 3, 'wr': '45 sn'},
          6: {'wg': 'stretch', 'ws': 1, 'wr': '5 dk'},
        },
      ),
      SmartStarterPack(
        id: 'work_gym_upper',
        nameTr: 'Salon · Üst vücut günü',
        nameEn: 'Gym · Upper body day',
        descTr: 'Göğüs, sırt, omuz ve kol hareketleri',
        descEn: 'Chest, back, shoulders and arms split',
        icon: Icons.fitness_center,
        itemsTr: [
          'Bench press',
          'Lat pulldown',
          'Omuz pres',
          'Seated row',
          'Lateral raise',
          'Biceps curl',
          'Triceps pushdown',
        ],
        itemsEn: [
          'Bench press',
          'Lat pulldown',
          'Shoulder press',
          'Seated row',
          'Lateral raise',
          'Biceps curl',
          'Triceps pushdown',
        ],
        extrasByIndex: {
          0: {'wg': 'upper', 'ws': 4, 'wr': '10', 'ww': '40 kg'},
          1: {'wg': 'upper', 'ws': 3, 'wr': '12', 'ww': '35 kg'},
          2: {'wg': 'upper', 'ws': 3, 'wr': '10', 'ww': '20 kg'},
          3: {'wg': 'upper', 'ws': 3, 'wr': '12', 'ww': '35 kg'},
          4: {'wg': 'upper', 'ws': 3, 'wr': '15', 'ww': '8 kg'},
          5: {'wg': 'upper', 'ws': 3, 'wr': '12', 'ww': '10 kg'},
          6: {'wg': 'upper', 'ws': 3, 'wr': '12', 'ww': '20 kg'},
        },
      ),
    ],
  ),
  SmartListKind.cleaning: SmartKindSpec(
    kind: SmartListKind.cleaning,
    icon: Icons.cleaning_services_outlined,
    accent: const Color(0xFF3B9BC4),
    nameTr: 'Ev temizliği',
    nameEn: 'Home cleaning',
    descTr: 'Oda oda ve sıklığa göre döngüsel temizlik',
    descEn: 'Room-by-room & daily/weekly/monthly cycles',
    groups: const [
      SmartGroupSpec(
        id: 'clean_kitchen',
        nameTr: 'Mutfak',
        nameEn: 'Kitchen',
        icon: Icons.kitchen_outlined,
        color: Color(0xFF3B9BC4),
        itemsTr:
            'Mutfak tezgâhı, Ocak temizliği, Fırın içi, Davlumbaz filtresi, Buzdolabı rafı, Lavabo ve batarya, '
            'Bulaşık makinesi filtresi, Mikrodalga temizliği, Çöp kovası yıkama, Dolap kapakları, Küçük ev aletleri',
        itemsEn:
            'Wipe counters, Clean stovetop, Clean oven, Range hood filter, Fridge shelves, Sink & faucet, '
            'Dishwasher filter, Clean microwave, Wash trash bin, Cabinet fronts, Wipe appliances',
      ),
      SmartGroupSpec(
        id: 'clean_bath',
        nameTr: 'Banyo ve tuvalet',
        nameEn: 'Bathroom',
        icon: Icons.bathtub_outlined,
        color: Color(0xFF00897B),
        itemsTr:
            'Klozet temizliği, Lavabo ve ayna, Duşakabin camı, Fayans araları, Duş başlığı kireç çözme, '
            'Banyo paspaslarını yıka, Havluları değiştir, Banyo dolabı düzenle, Gider temizliği',
        itemsEn:
            'Scrub toilet, Sink & mirror, Shower glass, Tile grout, Descale showerhead, '
            'Wash bath mats, Change towels, Tidy vanity cabinet, Clear drains',
      ),
      SmartGroupSpec(
        id: 'clean_rooms',
        nameTr: 'Salon ve odalar',
        nameEn: 'Living & bedrooms',
        icon: Icons.bed_outlined,
        color: Color(0xFF5E35B1),
        itemsTr:
            'Toz al, Süpür, Paspas yap, Koltukları süpür, Çarşafları değiştir, Yastık kılıflarını yıka, '
            'Camları sil, Aynaları parlat, Balkon yıkama, Çöpleri çıkar, Kapı kollarını sil, Priz ve anahtarları sil',
        itemsEn:
            'Dust surfaces, Vacuum floors, Mop floors, Vacuum sofa, Change bed sheets, Wash pillowcases, '
            'Clean windows, Polish mirrors, Wash balcony, Take out trash, Wipe door handles, Wipe light switches',
      ),
      SmartGroupSpec(
        id: 'clean_monthly',
        nameTr: 'Aylık ve derin temizlik',
        nameEn: 'Monthly deep clean',
        icon: Icons.event_repeat_outlined,
        color: Color(0xFFD97706),
        itemsTr:
            'Perdeleri yıka, Klima filtresi temizle, Çamaşır makinesi kazan temizliği, Halıları silkele, '
            'Gardırop düzenle, Yatak altını süpür, Petek ve radyatör temizliği, Avize ve lambaları sil',
        itemsEn:
            'Wash curtains, Clean AC filters, Washing machine drum clean, Beat rugs, '
            'Organise wardrobe, Vacuum under bed, Clean radiators, Dust light fixtures',
      ),
    ],
    starterPacks: const [
      SmartStarterPack(
        id: 'clean_weekly_pack',
        nameTr: 'Haftalık hızlı ev temizliği',
        nameEn: 'Weekly home reset',
        descTr: 'Odalara göre 8 temel temizlik adımı',
        descEn: '8 essential weekly tasks across rooms',
        icon: Icons.cleaning_services_outlined,
        itemsTr: [
          'Mutfak tezgâhı ve ocak',
          'Banyo ve lavabo',
          'Toz al',
          'Tüm evi süpür',
          'Paspas yap',
          'Çarşafları değiştir',
          'Çamaşır yıka',
          'Çöpleri çıkar',
        ],
        itemsEn: [
          'Wipe kitchen & stove',
          'Clean bathroom & sink',
          'Dust surfaces',
          'Vacuum all rooms',
          'Mop floors',
          'Change bed sheets',
          'Do laundry',
          'Take out trash',
        ],
        extrasByIndex: {
          0: {'cr': 'kitchen', 'cf': 'weekly'},
          1: {'cr': 'bath', 'cf': 'weekly'},
          2: {'cr': 'living', 'cf': 'weekly'},
          3: {'cr': 'living', 'cf': 'weekly'},
          4: {'cr': 'living', 'cf': 'weekly'},
          5: {'cr': 'bedroom', 'cf': 'weekly'},
          6: {'cr': 'general', 'cf': 'weekly'},
          7: {'cr': 'general', 'cf': 'daily'},
        },
      ),
    ],
  ),
  SmartListKind.gifts: SmartKindSpec(
    kind: SmartListKind.gifts,
    icon: Icons.card_giftcard,
    accent: const Color(0xFFD65C7A),
    nameTr: 'Hediye planlayıcı',
    nameEn: 'Gift planner',
    descTr: 'Kişi, bütçe ve 4 aşamalı durum (Fikir → Alındı → Paket → Verildi)',
    descEn: 'Recipient, budget and 4-stage gift status tracker',
    groups: const [
      SmartGroupSpec(
        id: 'gift_people',
        nameTr: 'Kişiler',
        nameEn: 'Recipients',
        icon: Icons.people_outline,
        color: Color(0xFFD65C7A),
        itemsTr: 'Anne, Baba, Eş, Sevgili, Kardeş, Abla, Abi, Çocuk, Arkadaş, En yakın arkadaş, Öğretmen, İş arkadaşı, Komşu, Bebek',
        itemsEn: 'Mum, Dad, Partner, Sister, Brother, Kids, Friend, Best friend, Teacher, Colleague, Neighbour, Baby',
      ),
      SmartGroupSpec(
        id: 'gift_ideas',
        nameTr: 'Hediye fikirleri',
        nameEn: 'Gift ideas',
        icon: Icons.lightbulb_outline,
        color: Color(0xFFE65100),
        itemsTr:
            'Kitap, Çiçek, Buket, Parfüm, Kol saati, Kulaklık, Kahve makinesi, Termos, Kupa, El yapımı hediye, '
            'Fotoğraf albümü, Çerçeve, Atkı ve bere, Kazak, Çanta, Cüzdan, Mum seti, Hediye çeki, Konser bileti, Spa günü, Takı, Kutu oyunu',
        itemsEn:
            'Book, Flowers, Bouquet, Perfume, Watch, Headphones, Coffee maker, Thermos, Mug, Handmade gift, '
            'Photo album, Picture frame, Scarf & beanie, Sweater, Bag, Wallet, Candle set, Gift card, Concert tickets, Spa voucher, Jewellery, Board game',
      ),
    ],
    starterPacks: const [
      SmartStarterPack(
        id: 'gift_family',
        nameTr: 'Özel gün hediye planı',
        nameEn: 'Special occasion gifts',
        descTr: 'Aile ve yakınlar için fikir ve bütçe taslağı',
        descEn: 'Starter list for family & close friends',
        icon: Icons.card_giftcard,
        itemsTr: [
          'Anne · Çiçek ve fular',
          'Baba · Deri cüzdan',
          'Kardeş · Kitap',
          'Arkadaş · Termos',
        ],
        itemsEn: [
          'Mum · Flowers & scarf',
          'Dad · Leather wallet',
          'Sibling · Book',
          'Friend · Thermos',
        ],
        extrasByIndex: {
          0: {'gr': 'Anne', 'gs': 'idea', 'p': 450.0},
          1: {'gr': 'Baba', 'gs': 'idea', 'p': 600.0},
          2: {'gr': 'Kardeş', 'gs': 'idea', 'p': 250.0},
          3: {'gr': 'Arkadaş', 'gs': 'idea', 'p': 400.0},
        },
      ),
    ],
  ),
  SmartListKind.watchlist: SmartKindSpec(
    kind: SmartListKind.watchlist,
    icon: Icons.movie_outlined,
    accent: const Color(0xFF6C6FD1),
    nameTr: 'İzlenecek ve okunacaklar',
    nameEn: 'Watch & read list',
    descTr: 'Film, dizi, kitap türü, izleme durumu ve 5 yıldız puanlama',
    descEn: 'Movie, series & book types, progress & 5-star ratings',
    groups: const [
      SmartGroupSpec(
        id: 'watch_types',
        nameTr: 'Türler ve öneriler',
        nameEn: 'Formats & ideas',
        icon: Icons.live_tv_outlined,
        color: Color(0xFF6C6FD1),
        itemsTr: 'Bilim kurgu filmi, Polisiye dizi, Belgesel, Roman, Biyografi, Sesli kitap, Animasyon, Klasik film, Podcast serisi, Mini dizi',
        itemsEn: 'Sci-fi movie, Crime series, Documentary, Novel, Biography, Audiobook, Animation, Classic film, Podcast series, Mini-series',
      ),
    ],
    starterPacks: const [
      SmartStarterPack(
        id: 'watch_weekend',
        nameTr: 'Hafta sonu keyfi',
        nameEn: 'Weekend queue',
        descTr: 'Film, dizi, belgesel ve kitap karması',
        descEn: 'Mix of film, series, documentary and book',
        icon: Icons.movie_outlined,
        itemsTr: [
          'Yeni mini dizi',
          'Bilim kurgu filmi',
          'Doğa belgeseli',
          'Akşam romanı',
        ],
        itemsEn: [
          'New mini-series',
          'Sci-fi movie',
          'Nature documentary',
          'Evening novel',
        ],
        extrasByIndex: {
          0: {'wt': 'series', 'ws2': 'queued'},
          1: {'wt': 'movie', 'ws2': 'queued'},
          2: {'wt': 'doc', 'ws2': 'queued'},
          3: {'wt': 'book', 'ws2': 'queued'},
        },
      ),
    ],
  ),
  SmartListKind.expense: SmartKindSpec(
    kind: SmartListKind.expense,
    icon: Icons.payments_outlined,
    accent: const Color(0xFFD06A95),
    nameTr: 'Bütçe ve harcama',
    nameEn: 'Budget & expenses',
    descTr: 'Otomatik tutar toplama, ödenen/kalan hesabı ve kategoriler',
    descEn: 'Auto sum of amounts, paid vs remaining & categories',
    groups: const [
      SmartGroupSpec(
        id: 'exp_bills',
        nameTr: 'Faturalar ve sabitler',
        nameEn: 'Bills & fixed',
        icon: Icons.receipt_long_outlined,
        color: Color(0xFFD06A95),
        itemsTr:
            'Kira, Aidat, Elektrik faturası, Su faturası, Doğalgaz faturası, İnternet faturası, Telefon faturası, '
            'Kredi kartı, Kredi taksiti, Sigorta, Vergi, Abonelikler',
        itemsEn:
            'Rent, HOA fee, Electricity bill, Water bill, Gas bill, Internet bill, Phone bill, '
            'Credit card, Loan payment, Insurance, Taxes, Subscriptions',
      ),
      SmartGroupSpec(
        id: 'exp_daily',
        nameTr: 'Günlük ve yaşam',
        nameEn: 'Daily & lifestyle',
        icon: Icons.account_balance_wallet_outlined,
        color: Color(0xFF00897B),
        itemsTr: 'Market harcaması, Pazar, Kahve ve dışarıda yemek, Yakıt, Ulaşım ve kart, Eczane, Giyim, Spor salonu, Tatil birikimi',
        itemsEn: 'Groceries, Dining out, Coffee, Fuel, Public transit, Pharmacy, Clothing, Gym membership, Savings',
      ),
    ],
    starterPacks: const [
      SmartStarterPack(
        id: 'exp_monthly',
        nameTr: 'Aylık ev bütçesi',
        nameEn: 'Monthly household budget',
        descTr: 'Kira, faturalar, market ve ulaşım kalemleri',
        descEn: 'Rent, utilities, groceries and transport',
        icon: Icons.account_balance_wallet_outlined,
        itemsTr: [
          'Kira',
          'Aidat',
          'Elektrik faturası',
          'Su faturası',
          'Doğalgaz faturası',
          'İnternet faturası',
          'Market harcaması',
          'Ulaşım',
        ],
        itemsEn: [
          'Rent',
          'HOA fee',
          'Electricity bill',
          'Water bill',
          'Gas bill',
          'Internet bill',
          'Groceries',
          'Transport',
        ],
        extrasByIndex: {
          0: {'ec': 'home'},
          1: {'ec': 'home'},
          2: {'ec': 'bills'},
          3: {'ec': 'bills'},
          4: {'ec': 'bills'},
          5: {'ec': 'bills'},
          6: {'ec': 'market'},
          7: {'ec': 'transport'},
        },
      ),
    ],
  ),
  SmartListKind.event: SmartKindSpec(
    kind: SmartListKind.event,
    icon: Icons.celebration_outlined,
    accent: const Color(0xFFE0685C),
    nameTr: 'Etkinlik ve davet',
    nameEn: 'Event & party',
    descTr: 'Kişi sayısına göre ikram ve hazırlık ölçekleyici sihirbaz',
    descEn: 'Guest-count scaler wizard, food, decor & prep checklist',
    groups: const [
      SmartGroupSpec(
        id: 'evt_prep',
        nameTr: 'Davet ve mekân',
        nameEn: 'Invites & venue',
        icon: Icons.mail_outline,
        color: Color(0xFFE0685C),
        itemsTr:
            'Davetli listesi, Davetiye gönder, Mekân veya masa düzeni, Müzik listesi, Fotoğraf köşesi, '
            'Balon ve süsleme, Masa örtüsü, Mumlar, Peçete, Karton tabak, Karton bardak, Çatal bıçak takımı, Çöp poşeti',
        itemsEn:
            'Guest list, Send invitations, Seating & table plan, Music playlist, Photo corner, '
            'Balloons & decor, Tablecloth, Candles, Napkins, Paper plates, Paper cups, Cutlery set, Trash bags',
      ),
      SmartGroupSpec(
        id: 'evt_food',
        nameTr: 'Yiyecek ve içecek',
        nameEn: 'Food & drinks',
        icon: Icons.cake_outlined,
        color: Color(0xFFD97706),
        itemsTr:
            'Doğum günü pastası, Pasta mumu, Kurabiye, Börek, Poğaça, Sandviç, Mezeler, Cips ve kuruyemiş, '
            'Meyve tabağı, Su, Kola ve gazoz, Meyve suyu, Çay, Kahve, Buz',
        itemsEn:
            'Birthday cake, Cake candles, Cookies, Pastries, Sandwiches, Dips & starters, Chips & nuts, '
            'Fruit platter, Water, Soda, Juice, Tea, Coffee, Ice',
      ),
    ],
    starterPacks: const [
      SmartStarterPack(
        id: 'evt_birthday',
        nameTr: 'Doğum günü kutlaması',
        nameEn: 'Birthday celebration',
        descTr: 'Pasta, mum, süsleme, ikram ve müzik hazırlığı',
        descEn: 'Cake, candles, decor, snacks and playlist',
        icon: Icons.cake_outlined,
        itemsTr: [
          'Davetli listesi',
          'Doğum günü pastası',
          'Pasta mumu ve maytap',
          'Balon ve süsleme',
          'Peçete, tabak, bardak',
          'İçecekler ve buz',
          'Atıştırmalık ve kuruyemiş',
          'Müzik listesi',
        ],
        itemsEn: [
          'Guest list',
          'Birthday cake',
          'Cake candles',
          'Balloons & decor',
          'Napkins, plates & cups',
          'Drinks & ice',
          'Snacks & nuts',
          'Music playlist',
        ],
      ),
    ],
  ),
  SmartListKind.pharmacy: SmartKindSpec(
    kind: SmartListKind.pharmacy,
    icon: Icons.local_pharmacy_outlined,
    accent: const Color(0xFFC62828),
    nameTr: 'Eczane ve sağlık',
    nameEn: 'Pharmacy & health',
    descTr: 'İlaçlar, vitaminler ve ilk yardım malzemeleri',
    descEn: 'Medications, vitamins and first-aid supplies',
    groups: const [
      SmartGroupSpec(
        id: 'pharm_meds',
        nameTr: 'İlaçlar ve reçete',
        nameEn: 'Medicines & Rx',
        icon: Icons.medication_outlined,
        color: Color(0xFFC62828),
        itemsTr:
            'Ağrı kesici, Ateş düşürücü, Antibiyotik, Reçete, Mide ilacı, Reflü şurubu, Alerji ilacı, '
            'Öksürük şurubu, Boğaz pastili, Burun spreyi, Deniz suyu spreyi, Göz damlası, Kulak damlası, Kas gevşetici, Soğuk algınlığı ilacı',
        itemsEn:
            'Painkillers, Fever medicine, Antibiotics, Prescription, Antacid, Allergy pills, '
            'Cough syrup, Throat lozenges, Nasal spray, Saline spray, Eye drops, Ear drops, Muscle relaxant, Cold & flu tablets',
      ),
      SmartGroupSpec(
        id: 'pharm_vit',
        nameTr: 'Vitamin ve takviye',
        nameEn: 'Vitamins & supplements',
        icon: Icons.wb_sunny_outlined,
        color: Color(0xFFD97706),
        itemsTr: 'Vitamin, Multivitamin, D vitamini, C vitamini, B12 vitamini, Magnezyum, Demir, Çinko, Omega 3, Probiyotik, Kolajen, Melatonin',
        itemsEn: 'Vitamins, Multivitamin, Vitamin D, Vitamin C, Vitamin B12, Magnesium, Iron, Zinc, Omega 3, Probiotics, Collagen, Melatonin',
      ),
      SmartGroupSpec(
        id: 'pharm_aid',
        nameTr: 'İlk yardım ve bakım',
        nameEn: 'First aid & care',
        icon: Icons.medical_services_outlined,
        color: Color(0xFF00897B),
        itemsTr:
            'Yara bandı, Sargı bezi, Gazlı bez, Flaster, Tentürdiyot, Baticon, Oksijenli su, '
            'Antiseptik krem, Yanık kremi, Güneş yanığı jeli, Termometre, Tansiyon aleti, Pamuk, Maske, Buz aküsü',
        itemsEn:
            'Plasters, Band-aids, Bandage, Gauze, Medical tape, Antiseptic solution, Hydrogen peroxide, '
            'Antiseptic cream, Burn gel, Aloe vera gel, Thermometer, Blood pressure monitor, Cotton pads, Face masks, Ice pack',
      ),
    ],
    starterPacks: const [
      SmartStarterPack(
        id: 'pharm_home',
        nameTr: 'Ev ecza dolabı',
        nameEn: 'Home medicine cabinet',
        descTr: 'Her evde bulunması gereken temel sağlık ürünleri',
        descEn: 'Everyday pain, fever and first-aid essentials',
        icon: Icons.medical_services_outlined,
        itemsTr: [
          'Ağrı kesici',
          'Ateş düşürücü',
          'Yara bandı',
          'Antiseptik krem',
          'Yanık kremi',
          'Gazlı bez ve sargı bezi',
          'Termometre',
          'Boğaz pastili',
          'Deniz suyu spreyi',
        ],
        itemsEn: [
          'Painkillers',
          'Fever medicine',
          'Plasters',
          'Antiseptic cream',
          'Burn gel',
          'Gauze & bandage',
          'Thermometer',
          'Throat lozenges',
          'Saline spray',
        ],
      ),
    ],
  ),
  SmartListKind.stationery: SmartKindSpec(
    kind: SmartListKind.stationery,
    icon: Icons.edit_note_outlined,
    accent: const Color(0xFF4F8FD6),
    nameTr: 'Kırtasiye ve okul',
    nameEn: 'Stationery & school',
    descTr: 'Defter, kalem, çanta ve masa düzeni',
    descEn: 'Notebooks, pens, backpacks and desk supplies',
    groups: const [
      SmartGroupSpec(
        id: 'stat_paper',
        nameTr: 'Defter ve kâğıt',
        nameEn: 'Paper & notebooks',
        icon: Icons.auto_stories_outlined,
        color: Color(0xFF4F8FD6),
        itemsTr:
            'Defter, Kareli defter, Çizgili defter, Çizgisiz defter, Spiralli defter, Bloknot, A4 kağıt, '
            'Dosya, Klasör, Poşet dosya, Telli dosya, Yapışkan not, Ajanda, Planlayıcı, Resim defteri, Fon kartonu',
        itemsEn:
            'Notebook, Grid notebook, Lined notebook, Blank notebook, Spiral notebook, Notepad, A4 paper, '
            'Folder, Binder, Sheet protectors, Sticky notes, Planner, Sketchbook, Construction paper',
      ),
      SmartGroupSpec(
        id: 'stat_pens',
        nameTr: 'Kalem ve boya',
        nameEn: 'Pens & colouring',
        icon: Icons.edit_outlined,
        color: Color(0xFFD97706),
        itemsTr:
            'Kurşun kalem, Tükenmez kalem, Jel kalem, Uçlu kalem, Kalem ucu, Kırmızı kalem, Fosforlu kalem, '
            'Tahta kalemi, Keçeli kalem, Kuru boya, Pastel boya, Sulu boya, Guaj boya, Silgi, Kalemtıraş, Daksil',
        itemsEn:
            'Pencil, Pen, Gel pen, Mechanical pencil, Pencil lead, Red pen, Highlighter, '
            'Whiteboard marker, Markers, Coloured pencils, Crayons, Watercolours, Eraser, Sharpener, Correction tape',
      ),
      SmartGroupSpec(
        id: 'stat_tools',
        nameTr: 'Gereçler ve çanta',
        nameEn: 'Tools & bags',
        icon: Icons.backpack_outlined,
        color: Color(0xFF2E7D32),
        itemsTr:
            'Cetvel, Gönye, Açıölçer, Pergel, Makas, Yapıştırıcı, Pritt, Sıvı yapıştırıcı, Bant, Zımba, Zımba teli, '
            'Ataç, Delgeç, Kalemlik, Sırt çantası, Beslenme çantası, Suluk, Matara, Hesap makinesi, Etiket',
        itemsEn:
            'Ruler, Set square, Protractor, Compass, Scissors, Glue stick, Liquid glue, Tape, Stapler, Staples, '
            'Paperclips, Hole punch, Pencil case, Backpack, Lunch box, Water bottle, Calculator, Name labels',
      ),
    ],
    starterPacks: const [
      SmartStarterPack(
        id: 'stat_school',
        nameTr: 'Okul açılış paketi',
        nameEn: 'Back to school kit',
        descTr: 'Defterler, kalem seti, çanta ve suluk',
        descEn: 'Notebooks, pens, backpack and lunch gear',
        icon: Icons.school_outlined,
        itemsTr: [
          'Kareli defter (3)',
          'Çizgili defter (2)',
          'Kurşun kalem',
          'Uçlu kalem ve uç',
          'Silgi ve kalemtıraş',
          'Kuru boya',
          'Cetvel ve makas',
          'Yapıştırıcı',
          'Kalemlik',
          'Sırt çantası',
          'Suluk',
        ],
        itemsEn: [
          'Grid notebook (3)',
          'Lined notebook (2)',
          'Pencil',
          'Mechanical pencil & lead',
          'Eraser & sharpener',
          'Coloured pencils',
          'Ruler & scissors',
          'Glue stick',
          'Pencil case',
          'Backpack',
          'Water bottle',
        ],
      ),
    ],
  ),
  SmartListKind.hardware: SmartKindSpec(
    kind: SmartListKind.hardware,
    icon: Icons.handyman_outlined,
    accent: const Color(0xFF795548),
    nameTr: 'Tamirat ve hırdavat',
    nameEn: 'Hardware & DIY',
    descTr: 'El aletleri, vida/dübel, elektrik ve boya malzemeleri',
    descEn: 'Tools, fasteners, electrical and paint supplies',
    groups: const [
      SmartGroupSpec(
        id: 'hard_tools',
        nameTr: 'El aletleri',
        nameEn: 'Hand & power tools',
        icon: Icons.build_outlined,
        color: Color(0xFF795548),
        itemsTr:
            'Tornavida, Yıldız tornavida, Düz tornavida, Kontrol kalemi, Pense, Kargaburun, Yankeski, '
            'İngiliz anahtarı, Kurbağacık, Çekiç, Lastik tokmak, Metre, Şerit metre, Su terazisi, '
            'Maket bıçağı, Matkap, Matkap ucu, Şarjlı vidalama, Alyan anahtarı, Testere, Mengene',
        itemsEn:
            'Screwdriver, Phillips screwdriver, Flathead screwdriver, Voltage tester, Pliers, Needle-nose pliers, Wire cutters, '
            'Wrench, Adjustable wrench, Hammer, Rubber mallet, Tape measure, Spirit level, '
            'Utility knife, Drill, Drill bits, Cordless drill, Allen key, Saw, Clamp',
      ),
      SmartGroupSpec(
        id: 'hard_fix',
        nameTr: 'Bağlantı ve yapıştırıcı',
        nameEn: 'Fasteners & adhesives',
        icon: Icons.hardware_outlined,
        color: Color(0xFF64748B),
        itemsTr:
            'Vida, Akıllı vida, Çivi, Beton çivisi, Dübel, Somun, Pul, Klips, Kablo bağı, Kelepçe, '
            'Silikon, Şeffaf silikon, Silikon tabancası, Japon yapıştırıcı, Ahşap tutkalı, Epoksi, '
            'Elektrik bandı, Koli bandı, Tamir bandı, Teflon bant, Çift taraflı bant, WD-40, Pas sökücü',
        itemsEn:
            'Screws, Wood screws, Nails, Wall plugs, Anchors, Nuts, Washers, Cable ties, Hose clamps, '
            'Silicone, Caulk, Glue gun, Superglue, Wood glue, Epoxy, '
            'Electrical tape, Packing tape, Duct tape, Plumber tape, Double-sided tape, WD-40',
      ),
      SmartGroupSpec(
        id: 'hard_elec',
        nameTr: 'Elektrik ve boya',
        nameEn: 'Electrical & paint',
        icon: Icons.format_paint_outlined,
        color: Color(0xFFD97706),
        itemsTr:
            'Ampul, LED ampul, Priz, Üçlü priz, Uzatma kablosu, Anahtar priz, Pil, Sigorta, Klemens, '
            'Boya, İç cephe boyası, Astar, Fırça, Kestirme fırça, Rulo, Boya tavası, Maskeleme bandı, '
            'Zımpara, Alçı, Spatula, Tiner, İş eldiveni, Koruyucu gözlük',
        itemsEn:
            'Light bulb, LED bulb, Socket, Power strip, Extension lead, Light switch, Batteries, Fuse, Wire connectors, '
            'Paint, Primer, Paintbrush, Roller, Paint tray, Masking tape, '
            'Sandpaper, Filler, Putty knife, Paint thinner, Work gloves, Safety glasses',
      ),
    ],
    starterPacks: const [
      SmartStarterPack(
        id: 'hard_basic',
        nameTr: 'Ev tamir temel seti',
        nameEn: 'Home DIY basics',
        descTr: 'Montaj ve küçük tamiratlar için temel malzemeler',
        descEn: 'Essential tools and fasteners for quick repairs',
        icon: Icons.handyman_outlined,
        itemsTr: [
          'Tornavida seti',
          'Pense',
          'Çekiç',
          'Şerit metre',
          'Su terazisi',
          'Vida ve dübel',
          'Elektrik bandı',
          'Japon yapıştırıcı',
          'Kablo bağı',
          'İş eldiveni',
        ],
        itemsEn: [
          'Screwdriver set',
          'Pliers',
          'Hammer',
          'Tape measure',
          'Spirit level',
          'Screws & wall plugs',
          'Electrical tape',
          'Superglue',
          'Cable ties',
          'Work gloves',
        ],
      ),
    ],
  ),
  SmartListKind.camping: SmartKindSpec(
    kind: SmartListKind.camping,
    icon: Icons.cabin_outlined,
    accent: const Color(0xFF2E7D32),
    nameTr: 'Kamp ve doğa',
    nameEn: 'Camping & outdoor',
    descTr: 'Barınma, kamp mutfağı, aydınlatma ve doğa güvenliği',
    descEn: 'Shelter, camp kitchen, lighting and outdoor safety',
    groups: const [
      SmartGroupSpec(
        id: 'camp_shelter',
        nameTr: 'Barınma ve uyku',
        nameEn: 'Shelter & sleep',
        icon: Icons.cabin_outlined,
        color: Color(0xFF2E7D32),
        itemsTr:
            'Çadır, Çadır kazığı, Çadır altı brandası, Uyku tulumu, Mat, Şişme mat, Şişme yatak, Pompa, Kamp yastığı, '
            'Tente, Hamak, Kamp sandalyesi, Kamp masası, Gölgelik',
        itemsEn:
            'Tent, Tent pegs, Footprint tarp, Sleeping bag, Sleeping mat, Air mattress, Pump, Camping pillow, '
            'Tarp, Hammock, Camping chair, Camping table, Canopy',
      ),
      SmartGroupSpec(
        id: 'camp_cook',
        nameTr: 'Kamp mutfağı',
        nameEn: 'Camp kitchen',
        icon: Icons.local_fire_department_outlined,
        color: Color(0xFFE65100),
        itemsTr:
            'Kamp ocağı, Gaz kartuşu, Tüp, Çakmak, Su geçirmez kibrit, Magnezyum çubuk, Termos, Çaydanlık, '
            'Kamp tenceresi, Kamp tavası, Çakı, Kamp bıçağı, Matara, Su bidonu, Çöp poşeti, Soğutucu çanta, Buz aküsü, '
            'Kamp bardağı, Tabak ve çatal, Konserve açacağı, Kahve demleme ekipmanı',
        itemsEn:
            'Camp stove, Gas canister, Lighter, Waterproof matches, Fire starter, Thermos, Kettle, '
            'Camping pot, Skillet, Pocket knife, Camp knife, Water bottle, Water jug, Rubbish bags, Cooler bag, Ice packs, '
            'Camp mug, Mess kit, Can opener, Camp coffee maker',
      ),
      SmartGroupSpec(
        id: 'camp_safety',
        nameTr: 'Aydınlatma ve güvenlik',
        nameEn: 'Light & safety',
        icon: Icons.flashlight_on_outlined,
        color: Color(0xFF0284C7),
        itemsTr:
            'Kafa lambası, Kamp feneri, El feneri, Fener pili, Powerbank, Güneş enerjili şarj, Pusula, Düdük, '
            'İlk yardım çantası, Sivrisinek kovucu, Kene cımbızı, Yağmurluk, Polar, Yedek çorap, Yürüyüş batonu, İp, Paracord, Balta',
        itemsEn:
            'Headlamp, Camp lantern, Torch, Spare batteries, Power bank, Solar charger, Compass, Whistle, '
            'First aid kit, Insect repellent, Tick remover, Raincoat, Fleece, Spare socks, Trekking poles, Rope, Paracord, Hatchet',
      ),
    ],
    starterPacks: const [
      SmartStarterPack(
        id: 'camp_weekend',
        nameTr: 'Hafta sonu çadır kampı',
        nameEn: 'Weekend tent camp',
        descTr: 'Çadır, uyku, ocak ve güvenlik temel listesi',
        descEn: 'Complete weekend camping gear checklist',
        icon: Icons.cabin_outlined,
        itemsTr: [
          'Çadır ve kazıklar',
          'Uyku tulumu',
          'Mat',
          'Kamp sandalyesi',
          'Kamp ocağı ve kartuş',
          'Çakmak',
          'Termos ve su bidonu',
          'Kafa lambası',
          'Powerbank',
          'İlk yardım çantası',
          'Sivrisinek kovucu',
          'Çöp poşeti',
        ],
        itemsEn: [
          'Tent & pegs',
          'Sleeping bag',
          'Sleeping mat',
          'Camping chair',
          'Camp stove & gas',
          'Lighter',
          'Thermos & water jug',
          'Headlamp',
          'Power bank',
          'First aid kit',
          'Insect repellent',
          'Rubbish bags',
        ],
      ),
    ],
  ),
  SmartListKind.baby: SmartKindSpec(
    kind: SmartListKind.baby,
    icon: Icons.child_friendly_outlined,
    accent: const Color(0xFFEC407A),
    nameTr: 'Bebek bakım çantası',
    nameEn: 'Baby bag & care',
    descTr: 'Bez değişimi, beslenme ve yedek kıyafet düzeni',
    descEn: 'Diaper change, feeding and spare outfit tracker',
    groups: const [
      SmartGroupSpec(
        id: 'baby_change',
        nameTr: 'Bez ve bakım',
        nameEn: 'Changing & care',
        icon: Icons.child_care_outlined,
        color: Color(0xFFEC407A),
        itemsTr:
            'Bebek bezi, Islak mendil, Alt açma örtüsü, Pişik kremi, Bebek yağı, Bebek şampuanı, Kirli bez torbası, '
            'Güneş kremi, El temizleme jeli, Ateş ölçer, Burun aspiratörü, Serum fizyolojik',
        itemsEn:
            'Nappies, Diapers, Wet wipes, Changing mat, Nappy cream, Baby oil, Baby shampoo, Nappy bags, '
            'Baby sunscreen, Hand sanitiser, Thermometer, Nasal aspirator, Saline drops',
      ),
      SmartGroupSpec(
        id: 'baby_feed',
        nameTr: 'Beslenme',
        nameEn: 'Feeding',
        icon: Icons.local_drink_outlined,
        color: Color(0xFFD97706),
        itemsTr:
            'Biberon, Yedek biberon, Emzik, Emzik kutusu, Emzik zinciri, Mama, Formül mama, Mama kabı, '
            'Su termosu, Kaynamış soğutulmuş su, Mama önlüğü, Bebek kaşığı, Alıştırma bardağı, Atıştırmalık, Kavanoz mama',
        itemsEn:
            'Baby bottle, Spare bottle, Pacifier, Dummy, Pacifier clip, Formula, Baby food, Formula dispenser, '
            'Thermos, Boiled water, Bib, Baby spoon, Sippy cup, Snacks, Baby puree',
      ),
      SmartGroupSpec(
        id: 'baby_clothes',
        nameTr: 'Kıyafet ve taşıma',
        nameEn: 'Clothes & gear',
        icon: Icons.checkroom_outlined,
        color: Color(0xFF0284C7),
        itemsTr:
            'Yedek zıbın, Yedek tulum, Yedek alt üst takım, Bebek çorap, Bebek şapka, Yelek veya hırka, '
            'Müslin örtü, Ağız mendili, Battaniye, Oyuncak, Diş kaşıyıcı, Kanguru, Bebek arabası, Yağmurluk',
        itemsEn:
            'Spare onesie, Spare sleepsuit, Spare outfit, Baby socks, Baby hat, Cardigan, '
            'Muslin cloth, Burp cloth, Blanket, Toy, Teether, Baby carrier, Pram, Stroller rain cover',
      ),
    ],
    starterPacks: const [
      SmartStarterPack(
        id: 'baby_dayout',
        nameTr: 'Günlük dışarı çıkış çantası',
        nameEn: 'Day-out diaper bag',
        descTr: 'Dışarı çıkarken çantada olması gerekenler',
        descEn: 'Quick essentials before heading out with baby',
        icon: Icons.child_friendly_outlined,
        itemsTr: [
          'Bebek bezi (4)',
          'Islak mendil',
          'Alt açma örtüsü',
          'Pişik kremi',
          'Kirli bez torbası',
          'Yedek zıbın ve tulum',
          'Müslin örtü',
          'Biberon ve mama',
          'Su termosu',
          'Emzik',
          'Oyuncak',
        ],
        itemsEn: [
          'Diapers (4)',
          'Wet wipes',
          'Changing mat',
          'Diaper cream',
          'Diaper bags',
          'Spare onesie & outfit',
          'Muslin cloth',
          'Bottle & formula',
          'Water thermos',
          'Pacifier',
          'Toy',
        ],
      ),
    ],
  ),
  SmartListKind.sport: SmartKindSpec(
    kind: SmartListKind.sport,
    icon: Icons.sports_handball_outlined,
    accent: const Color(0xFF00897B),
    nameTr: 'Spor çantası',
    nameEn: 'Gym & sport bag',
    descTr: 'Kıyafet, duş, takviye ve antrenman ekipmanı',
    descEn: 'Apparel, shower, supplements and gym gear',
    groups: const [
      SmartGroupSpec(
        id: 'sport_wear',
        nameTr: 'Kıyafet ve ayakkabı',
        nameEn: 'Apparel & shoes',
        icon: Icons.checkroom_outlined,
        color: Color(0xFF00897B),
        itemsTr:
            'Spor ayakkabı, Koşu ayakkabısı, Şort, Tayt, Spor tişört, Spor çorap, Spor sütyeni, Eşofman, '
            'Yedek kıyafet, Yedek iç çamaşırı, Terlik, Bone, Yüzücü gözlüğü, Mayo',
        itemsEn:
            'Trainers, Running shoes, Shorts, Leggings, Gym t-shirt, Sports socks, Sports bra, Tracksuit, '
            'Spare clothes, Spare underwear, Flip flops, Swim cap, Goggles, Swimsuit',
      ),
      SmartGroupSpec(
        id: 'sport_care',
        nameTr: 'Duş ve çanta',
        nameEn: 'Shower & hydration',
        icon: Icons.water_drop_outlined,
        color: Color(0xFF0284C7),
        itemsTr:
            'Spor havlusu, Banyo havlusu, Matara, Protein shaker, Protein tozu, BCAA, Kreatin, '
            'Duş jeli, Şampuan, Deodorant, Kirli çamaşır torbası, Asma kilit, Üyelik kartı',
        itemsEn:
            'Gym towel, Bath towel, Water bottle, Protein shaker, Protein powder, BCAA, Creatine, '
            'Shower gel, Shampoo, Deodorant, Laundry bag, Padlock, Gym pass',
      ),
      SmartGroupSpec(
        id: 'sport_gear',
        nameTr: 'Ekipman ve teknoloji',
        nameEn: 'Gear & tech',
        icon: Icons.podcasts_outlined,
        color: Color(0xFF5E35B1),
        itemsTr: 'Kulaklık, Akıllı saat, Nabız bandı, Spor eldiveni, Bileklik, Ağırlık kemeri, Direnç bandı, Atlama ipi, Yoga matı, Köpük rulo',
        itemsEn: 'Headphones, Smartwatch, Heart rate strap, Gym gloves, Wrist wraps, Lifting belt, Resistance band, Jump rope, Yoga mat, Foam roller',
      ),
    ],
    starterPacks: const [
      SmartStarterPack(
        id: 'sport_bag_pack',
        nameTr: 'Standart spor çantası',
        nameEn: 'Standard gym bag',
        descTr: 'Kıyafet, havlu, matara, kulaklık ve duş eşyaları',
        descEn: 'Shoes, towel, water bottle, earbuds & shower gear',
        icon: Icons.fitness_center,
        itemsTr: [
          'Spor ayakkabı',
          'Spor tişört ve şort',
          'Spor çorap',
          'Spor havlusu',
          'Matara',
          'Kulaklık',
          'Asma kilit',
          'Duş jeli ve deodorant',
          'Yedek iç çamaşırı',
          'Kirli torbası',
        ],
        itemsEn: [
          'Trainers',
          'Gym t-shirt & shorts',
          'Sports socks',
          'Gym towel',
          'Water bottle',
          'Headphones',
          'Padlock',
          'Shower gel & deodorant',
          'Spare underwear',
          'Laundry bag',
        ],
      ),
    ],
  ),
};

// ── Seyahat Bavul Planı Üreticisi ─────────────────────────────────────────

enum TripWeather { hot, mild, cold, rainy }

enum TripStyle { beach, city, business, international, camp }

List<({String text, Map<String, dynamic> extras})> generatePackingPlan({
  required int days,
  required TripWeather weather,
  required TripStyle style,
  required bool isTr,
}) {
  final d = days.clamp(1, 21);
  final out = <({String text, Map<String, dynamic> extras})>[];
  void add(String tr, String en, {String bag = 'checked', int? qty}) {
    final base = isTr ? tr : en;
    final text = qty != null && qty > 1 ? '$base ($qty)' : base;
    out.add((
      text: text,
      extras: {
        if (bag != 'checked') 'pb': bag,
        if (qty != null && qty > 1) 'q': qty.toDouble(),
      },
    ));
  }

  // Belgeler ve teknoloji (El bagajı)
  add('Kimlik', 'ID card', bag: 'cabin');
  if (style == TripStyle.international) {
    add('Pasaport', 'Passport', bag: 'cabin');
    add('Vize / Bilet', 'Visa & boarding pass', bag: 'cabin');
    add('Seyahat sigortası', 'Travel insurance', bag: 'cabin');
    add('Evrensel priz dönüştürücü', 'Universal travel adapter', bag: 'cabin');
  } else {
    add('Bilet / Rezervasyon', 'Tickets & booking', bag: 'cabin');
  }
  add('Cüzdan ve nakit', 'Wallet & cash', bag: 'cabin');
  add('Telefon şarjı', 'Phone charger', bag: 'cabin');
  add('Powerbank', 'Power bank', bag: 'cabin');
  add('Kulaklık', 'Headphones', bag: 'cabin');
  if (style == TripStyle.business) {
    add('Laptop ve şarjı', 'Laptop & charger', bag: 'cabin');
    add('Not defteri ve kalem', 'Notebook & pen', bag: 'cabin');
  }

  // Kıyafet (gün sayısına göre ölçekli)
  final pants = (d / 3).ceil().clamp(1, 5);
  add('Tişört', 'T-shirt', qty: d);
  add('İç çamaşırı', 'Underwear', qty: d + 1);
  add('Çorap', 'Socks', qty: d + 1);
  add('Pantolon', 'Trousers', qty: pants);
  add('Pijama', 'Pyjamas');
  add('Spor ayakkabı', 'Trainers', bag: 'wear');

  if (style == TripStyle.business) {
    add('Gömlek', 'Shirt', qty: d.clamp(1, 5));
    add('Ceket / Takım', 'Blazer / Suit');
    add('Klasik ayakkabı', 'Dress shoes');
  }

  if (weather == TripWeather.hot || style == TripStyle.beach) {
    add('Şort', 'Shorts', qty: (d / 2).ceil().clamp(1, 4));
    add('Güneş gözlüğü', 'Sunglasses', bag: 'wear');
    add('Şapka', 'Sun hat');
    add('Güneş kremi', 'Sunscreen');
  }
  if (style == TripStyle.beach) {
    add('Mayo', 'Swimsuit', qty: d >= 4 ? 2 : 1);
    add('Plaj havlusu', 'Beach towel');
    add('Terlik', 'Flip flops');
  }
  if (weather == TripWeather.mild) {
    add('Hırka veya ince ceket', 'Cardigan or light jacket', bag: 'wear');
  }
  if (weather == TripWeather.cold) {
    add('Kazak', 'Sweater', qty: (d / 2).ceil().clamp(1, 4));
    add('Mont', 'Winter coat', bag: 'wear');
    add('Bere, atkı, eldiven', 'Beanie, scarf & gloves');
    if (d >= 3) add('Termal içlik', 'Thermal base layer');
  }
  if (weather == TripWeather.rainy) {
    add('Yağmurluk', 'Raincoat', bag: 'wear');
    add('Şemsiye', 'Umbrella', bag: 'cabin');
    add('Su geçirmez ayakkabı', 'Waterproof shoes');
  }
  if (style == TripStyle.camp) {
    add('Kafa lambası', 'Headlamp', bag: 'cabin');
    add('Sivrisinek kovucu', 'Insect repellent');
    add('Matara', 'Water bottle', bag: 'cabin');
  }

  // Bakım ve sağlık
  add('Diş fırçası ve macunu', 'Toothbrush & toothpaste');
  add('Deodorant', 'Deodorant');
  add('Şampuan / Duş jeli', 'Shampoo & shower gel');
  add('Ağrı kesici ve yara bandı', 'Painkillers & plasters', bag: 'cabin');
  add('Kirli çamaşır torbası', 'Laundry bag');
  return out;
}

// ── Etkinlik / Davet Ölçekleyicisi ────────────────────────────────────────

enum EventStyle { birthday, dinner, picnic }

List<({String text, Map<String, dynamic> extras})> generateEventPlan({
  required int guests,
  required EventStyle style,
  required bool isTr,
}) {
  final g = guests.clamp(2, 100);
  final packs = (g / 8).ceil().clamp(1, 15);
  final drinks = (g / 3).ceil().clamp(1, 35);
  final snacks = (g / 4).ceil().clamp(1, 25);
  final out = <({String text, Map<String, dynamic> extras})>[];

  void add(String tr, String en, {int? qty, String unit = ''}) {
    final base = isTr ? tr : en;
    final qStr = qty != null && qty > 1
        ? (unit.isEmpty ? ' ($qty)' : ' ($qty $unit)')
        : '';
    out.add((
      text: '$base$qStr',
      extras: {
        if (qty != null && qty > 1) 'q': qty.toDouble(),
        if (unit.isNotEmpty) 'u': unit,
      },
    ));
  }

  add('Davetli listesi ($g kişi)', 'Guest list ($g guests)');
  add('Su', 'Water', qty: drinks, unit: isTr ? 'lt' : 'L');
  add(
    'İçecek / Soda',
    'Drinks / Soda',
    qty: drinks,
    unit: isTr ? 'şişe' : 'bottles',
  );
  add('Buz', 'Ice', qty: packs, unit: isTr ? 'paket' : 'bags');
  add('Karton tabak', 'Paper plates', qty: g);
  add('Bardak', 'Cups', qty: g + 4);
  add('Peçete', 'Napkins', qty: packs, unit: isTr ? 'paket' : 'packs');
  add('Çöp poşeti', 'Trash bags');

  switch (style) {
    case EventStyle.birthday:
      add('Doğum günü pastası ($g kişilik)', 'Birthday cake ($g servings)');
      add('Pasta mumu', 'Cake candles');
      add('Balon ve süsleme', 'Balloons & decor');
      add(
        'Kuruyemiş ve cips',
        'Nuts & chips',
        qty: snacks,
        unit: isTr ? 'paket' : 'bags',
      );
      add('Börek / Atıştırmalık', 'Pastries & bites');
      add('Müzik listesi', 'Music playlist');
    case EventStyle.dinner:
      add('Ana yemek malzemesi ($g porsiyon)', 'Main course ($g portions)');
      add('Meze ve salata', 'Starters & salad');
      add('Ekmek', 'Bread', qty: (g / 3).ceil().clamp(1, 15));
      add('Tatlı / Meyve', 'Dessert / Fruit');
      add('Çay ve kahve', 'Tea & coffee');
    case EventStyle.picnic:
      add('Piknik örtüsü', 'Picnic blanket');
      add('Termos ve soğutucu çanta', 'Thermos & cooler bag');
      add('Sandviç / Salata', 'Sandwiches & salad', qty: g);
      add('Meyve', 'Fruit', qty: (g / 3).ceil().clamp(1, 10), unit: 'kg');
      add('Islak mendil', 'Wet wipes', qty: packs);
      add('Sivrisinek kovucu', 'Insect repellent');
  }
  return out;
}
