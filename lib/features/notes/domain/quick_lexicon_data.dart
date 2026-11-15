/// **HAZIR MADDE SÖZLÜĞÜ** (kullanıcı isteği 2026-11-15: "geniş bir sözlük").
///
/// Hızlı giriş ayrıştırıcısının ([QuickParser]) tanıdığı market maddeleri,
/// REYON SIRASIYLA. Elle derlendi (Türkiye'de yaygın market ürünleri +
/// İngilizce karşılıkları); kullanıcının ekledikleri ve şablon önerileri
/// çalışma anında üstüne eklenir (bkz. `buildQuickLexicon`).
///
/// Biçim: reyon başına virgüllü tek dize — yazılacak hâliyle (ilk harf
/// büyük). Çok kelimeli maddeler öbek olarak tanınır ("diş macunu").
library;

/// Reyonlar, markette dolaşma sırasıyla. Sıra numarası maddenin `group`u.
enum QuickAisle {
  produce,
  bakery,
  breakfast,
  meat,
  pantry,
  drinks,
  snacks,
  frozen,
  cleaning,
  home,
  personal,
  baby,
  pet,
}

/// Alışveriş şablonunun ÖNERİ GRUPLARININ (note_templates `templateSuggestions`
/// sırası) karşılık geldiği reyonlar.
const kShoppingSuggestionAisles = [
  QuickAisle.produce,
  QuickAisle.breakfast,
  QuickAisle.meat,
  QuickAisle.pantry,
  QuickAisle.drinks,
  QuickAisle.snacks,
  QuickAisle.frozen,
  QuickAisle.cleaning,
  QuickAisle.personal,
  QuickAisle.baby,
  QuickAisle.pet,
];

const Map<QuickAisle, String> kQuickLexiconTr = {
  QuickAisle.produce:
      'Domates, Salatalık, Soğan, Kuru soğan, Yeşil soğan, Taze soğan, Patates, '
      'Limon, Muz, Elma, Armut, Maydanoz, Dereotu, Nane, Roka, Marul, Kıvırcık, '
      'Göbek marul, Ispanak, Pazı, Semizotu, Tere, Fesleğen, Kekik, Biberiye, '
      'Havuç, Kabak, Patlıcan, Biber, Sivri biber, Çarliston biber, Dolmalık biber, '
      'Kapya biber, Kırmızı biber, Yeşil biber, Acı biber, Sarımsak, Zencefil, '
      'Brokoli, Karnabahar, Lahana, Kırmızı lahana, Beyaz lahana, Brüksel lahanası, '
      'Pırasa, Kereviz, Turp, Pancar, Şalgam, Enginar, Bamya, Bezelye, Fasulye, '
      'Taze fasulye, Börülce, Barbunya, Bakla, Mısır, Mantar, Kültür mantarı, '
      'Avokado, Kuşkonmaz, Balkabağı, Tatlı patates, Yer elması, Asma yaprağı, '
      'Portakal, Mandalina, Greyfurt, Çilek, Kiraz, Vişne, Kayısı, Şeftali, '
      'Nektarin, Erik, Üzüm, Karpuz, Kavun, İncir, Nar, Ayva, Kivi, Ananas, '
      'Mango, Hindistan cevizi, Böğürtlen, Ahududu, Yaban mersini, Dut, Hurma, '
      'Trabzon hurması, Muşmula, Yenidünya, Kestane, Meyve, Sebze, Yeşillik, '
      'Salata malzemesi, Cherry domates, Salkım domates, Köy domatesi',
  QuickAisle.bakery:
      'Ekmek, Tam buğday ekmeği, Kepekli ekmek, Çavdar ekmeği, Köy ekmeği, '
      'Tost ekmeği, Sandviç ekmeği, Hamburger ekmeği, Lavaş, Bazlama, Pide, '
      'Simit, Poğaça, Açma, Börek, Kruvasan, Galeta, Grissini, Yufka, '
      'Baklavalık yufka, Milföy, Kek, Pasta, Kurabiye, Bayat ekmek, Tortilla, '
      'Pizza hamuru, Maya, Yaş maya, Kuru maya',
  QuickAisle.breakfast:
      'Süt, Yumurta, Peynir, Beyaz peynir, Kaşar, Kaşar peyniri, Taze kaşar, '
      'Eski kaşar, Tulum peyniri, Lor, Lor peyniri, Çökelek, Labne, Krem peynir, '
      'Mozzarella, Parmesan, Cheddar, Hellim, Dil peyniri, Örgü peyniri, '
      'Ezine peyniri, Süzme peynir, Yoğurt, Süzme yoğurt, Meyveli yoğurt, Ayran, '
      'Kefir, Tereyağı, Margarin, Kaymak, Krema, Sıvı krema, Krem şanti, Zeytin, '
      'Siyah zeytin, Yeşil zeytin, Bal, Reçel, Çilek reçeli, Vişne reçeli, '
      'Kayısı reçeli, Pekmez, Tahin, Tahin pekmez, Helva, Fındık ezmesi, '
      'Fıstık ezmesi, Çikolata kreması, Sucuk, Salam, Sosis, Pastırma, Jambon, '
      'Hindi füme, Kavurma, Mısır gevreği, Yulaf, Yulaf ezmesi, Müsli, Granola, '
      'Laktozsuz süt, Badem sütü, Yulaf sütü, Soya sütü, Süt tozu, Menemen malzemesi',
  QuickAisle.meat:
      'Tavuk, Tavuk göğsü, Tavuk but, Tavuk kanat, Tavuk baget, Bütün tavuk, '
      'Tavuk pirzola, Tavuk kıyma, Hindi, Hindi göğsü, Kıyma, Dana kıyma, '
      'Kuzu kıyma, Kuşbaşı, Dana kuşbaşı, Kuzu kuşbaşı, Biftek, Antrikot, Bonfile, '
      'Pirzola, Kuzu pirzola, Kuzu incik, Kuzu but, Dana rosto, Ciğer, Köfte, '
      'Köftelik kıyma, Döner, Balık, Somon, Levrek, Çipura, Hamsi, İstavrit, '
      'Palamut, Lüfer, Mezgit, Alabalık, Ton balığı, Sardalya, Uskumru, Karides, '
      'Kalamar, Midye, Et, Kemik suyu, Kemik, İşkembe, Sakatat',
  QuickAisle.pantry:
      'Un, Şeker, Toz şeker, Küp şeker, Esmer şeker, Pudra şekeri, Tuz, Kaya tuzu, '
      'Pirinç, Baldo pirinç, Basmati pirinç, Bulgur, Pilavlık bulgur, Köftelik bulgur, '
      'Makarna, Spagetti, Erişte, Şehriye, Arpa şehriye, Tel şehriye, Kuskus, '
      'Mercimek, Kırmızı mercimek, Yeşil mercimek, Nohut, Kuru fasulye, '
      'İrmik, Nişasta, Mısır nişastası, Mısır unu, '
      'Galeta unu, Kabartma tozu, Vanilya, Karbonat, Kakao, Damla çikolata, '
      'Zeytinyağı, Ayçiçek yağı, Sıvı yağ, Mısırözü yağı, Fındık yağı, '
      'Susam yağı, Sirke, Elma sirkesi, Üzüm sirkesi, Nar ekşisi, Limon suyu, '
      'Salça, Domates salçası, Biber salçası, Ketçap, Mayonez, Hardal, Soya sosu, '
      'Acı sos, Barbekü sos, Makarna sosu, Domates sosu, Domates püresi, '
      'Konserve, Konserve mısır, Konserve bezelye, Konserve ton balığı, Turşu, '
      'Kornişon, Közlenmiş biber, Zeytin ezmesi, Karabiber, Pul biber, Kırmızı toz biber, '
      'Kimyon, Sumak, Köri, Zerdeçal, Tarçın, Karanfil, Yenibahar, Defne yaprağı, '
      'Kuru nane, Kuru kekik, Sarımsak tozu, Soğan tozu, Zencefil tozu, Susam, '
      'Çörek otu, Haşhaş, Keten tohumu, Chia, Kinoa, Karabuğday, Yulaf unu, '
      'Hazır çorba, Bulyon, Tavuk suyu, Et suyu, Noodle, Hazır puding, Jelatin, '
      'Kuru üzüm, Kuru kayısı, Kuru incir, Kuru erik, Ceviz, Fındık, '
      'Badem, Antep fıstığı, Kaju, Yer fıstığı, Çam fıstığı, Leblebi, Kuruyemiş, '
      'Çekirdek, Kabak çekirdeği, Ay çekirdeği, Hindistan cevizi rendesi, '
      'Tane mısır, Patlak mısır',
  QuickAisle.drinks:
      'Su, Damacana su, Maden suyu, Soda, Sade soda, Meyveli soda, Kola, Gazoz, '
      'Meyve suyu, Portakal suyu, Vişne suyu, Elma suyu, Şeftali suyu, Limonata, '
      'Soğuk çay, Buzlu çay, Enerji içeceği, Şalgam suyu, Boza, Çay, Siyah çay, '
      'Yeşil çay, Bitki çayı, Ihlamur, Papatya çayı, Adaçayı, Kuşburnu, Rezene çayı, '
      'Nane limon, Kahve, Türk kahvesi, Filtre kahve, Granül kahve, Hazır kahve, '
      'Espresso, Kapsül kahve, Sıcak çikolata, Salep, Bira, Şarap, Rakı, Tonik, '
      'Buz, Süt kreması, Kahve kreması',
  QuickAisle.snacks:
      'Çikolata, Bitter çikolata, Sütlü çikolata, Gofret, Bisküvi, Kraker, Cips, '
      'Patates cipsi, Mısır cipsi, Çubuk kraker, Patlamış mısır, '
      'Şekerleme, Sakız, Lokum, Jelibon, Bonbon, Bar, Protein bar, Meyve barı, '
      'Kuru meyve, Dondurma, Puding, Sütlaç, Tatlı, Baklava, Atıştırmalık',
  QuickAisle.frozen:
      'Dondurulmuş bezelye, Dondurulmuş mısır, Dondurulmuş sebze, Dondurulmuş pizza, '
      'Dondurulmuş patates, Parmak patates, Dondurulmuş börek, Su böreği, Mantı, '
      'Dondurulmuş mantı, Dondurulmuş köfte, Nugget, Tavuk nugget, Şinitzel, '
      'Balık kroket, Dondurulmuş karides, Dondurulmuş meyve, Dondurulmuş ıspanak, '
      'Garnitür, Buz küpü, Hazır yemek',
  QuickAisle.cleaning:
      'Deterjan, Çamaşır deterjanı, Sıvı deterjan, Toz deterjan, Yumuşatıcı, '
      'Çamaşır suyu, Leke çıkarıcı, Bulaşık deterjanı, Bulaşık tableti, '
      'Bulaşık makinesi tableti, Bulaşık makinesi tuzu, Parlatıcı, Makine temizleyici, '
      'Bulaşık süngeri, Sünger, Bulaşık teli, Bulaşık fırçası, Yüzey temizleyici, '
      'Cam temizleyici, Banyo temizleyici, Mutfak temizleyici, Yağ çözücü, '
      'Kireç çözücü, Tuvalet temizleyici, Lavabo açıcı, Arap sabunu, Sıvı sabun, '
      'El sabunu, Sabun, Dezenfektan, Kolonya, Çöp torbası, Çöp poşeti, '
      'Buzdolabı poşeti, Streç film, Alüminyum folyo, Pişirme kağıdı, Kağıt havlu, '
      'Tuvalet kağıdı, Peçete, Kağıt mendil, Islak mendil, Temizlik bezi, '
      'Mikrofiber bez, Toz bezi, Paspas, Mop, Süpürge, Faraş, Eldiven, '
      'Oda kokusu, Sinek ilacı, Böcek ilacı, Güve tableti',
  QuickAisle.home:
      'Pil, Kalem pil, İnce pil, Ampul, Kibrit, Çakmak, Mum, Bant, Yapıştırıcı, '
      'Makas, Uzatma kablosu, Priz, Poşet, Saklama kabı, Kürdan, Pipet, '
      'Plastik bardak, Plastik tabak, Karton bardak, Mangal kömürü, Çıra, '
      'Buz torbası, Ütü suyu, Askı, Mandal, Kilitli poşet, Defter, Kalem, '
      'Şarj kablosu, Çiçek toprağı, Saksı',
  QuickAisle.personal:
      'Şampuan, Saç kremi, Duş jeli, Diş macunu, Diş fırçası, Diş ipi, '
      'Ağız gargarası, Deodorant, Parfüm, Tıraş köpüğü, Tıraş bıçağı, Tıraş jeli, '
      'Jilet, Ped, Günlük ped, Tampon, Pamuk, Kulak çubuğu, Makyaj pamuğu, '
      'El kremi, Yüz kremi, Nemlendirici, Güneş kremi, Vücut losyonu, Dudak kremi, '
      'Makyaj temizleyici, Yüz yıkama jeli, Maske, Saç boyası, '
      'Saç jölesi, Saç spreyi, Tarak, Toka, Tırnak makası, Oje, Aseton, '
      'Yara bandı, Ağrı kesici, Vitamin, Ateş ölçer, Prezervatif, '
      'Lens solüsyonu, Banyo lifi, Havlu, Terlik',
  QuickAisle.baby:
      'Bebek bezi, Islak havlu, Bebek maması, Mama, Devam sütü, Bebek bisküvisi, '
      'Bebek şampuanı, Bebek yağı, Pişik kremi, Bebek pudrası, Biberon, Emzik, '
      'Alıştırma bardağı, Önlük, Bebek deterjanı, Kavanoz maması, Bebek mendili',
  QuickAisle.pet:
      'Kedi maması, Köpek maması, Kedi kumu, Yaş mama, Kuru mama, Ödül maması, '
      'Kuş yemi, Balık yemi, Tasma, Mama kabı, Kedi otu, Pire damlası',
};

const Map<QuickAisle, String> kQuickLexiconEn = {
  QuickAisle.produce:
      'Tomatoes, Tomato, Cucumber, Onion, Onions, Spring onions, Potatoes, Potato, '
      'Lemon, Lemons, Lime, Bananas, Banana, Apples, Apple, Pears, Parsley, Dill, '
      'Mint, Basil, Cilantro, Rocket, Arugula, Lettuce, Spinach, Kale, Carrots, '
      'Carrot, Zucchini, Courgette, Eggplant, Aubergine, Peppers, Bell pepper, '
      'Chili, Garlic, Ginger, Broccoli, Cauliflower, Cabbage, Leek, Celery, '
      'Radish, Beetroot, Peas, Green beans, Corn, Sweetcorn, Mushrooms, Avocado, '
      'Asparagus, Pumpkin, Sweet potato, Oranges, Orange, Tangerines, Grapefruit, '
      'Strawberries, Cherries, Apricots, Peaches, Plums, Grapes, Watermelon, '
      'Melon, Figs, Pomegranate, Kiwi, Pineapple, Mango, Coconut, Blackberries, '
      'Raspberries, Blueberries, Dates, Fruit, Vegetables, Salad, Herbs',
  QuickAisle.bakery:
      'Bread, Wholemeal bread, Rye bread, Toast bread, Buns, Burger buns, '
      'Bagels, Tortillas, Wraps, Pita, Croissants, Rolls, Baguette, Cake, '
      'Cookies, Pastry, Puff pastry, Pizza dough, Yeast',
  QuickAisle.breakfast:
      'Milk, Eggs, Cheese, Feta, Cheddar, Mozzarella, Parmesan, Cream cheese, '
      'Cottage cheese, Halloumi, Yogurt, Greek yogurt, Butter, Margarine, Cream, '
      'Sour cream, Whipped cream, Olives, Honey, Jam, Marmalade, Peanut butter, '
      'Hazelnut spread, Tahini, Molasses, Sausages, Salami, Ham, Bacon, Cereal, '
      'Oats, Oatmeal, Muesli, Granola, Almond milk, Oat milk, Soy milk, Kefir',
  QuickAisle.meat:
      'Chicken, Chicken breast, Chicken thighs, Chicken wings, Whole chicken, '
      'Turkey, Ground beef, Minced meat, Mince, Beef, Steak, Lamb, Lamb chops, '
      'Pork, Meatballs, Liver, Fish, Salmon, Tuna, Sea bass, Cod, Sardines, '
      'Shrimp, Prawns, Mussels, Calamari, Meat',
  QuickAisle.pantry:
      'Flour, Sugar, Brown sugar, Powdered sugar, Salt, Rice, Bulgur, Pasta, '
      'Spaghetti, Noodles, Couscous, Lentils, Chickpeas, Beans, Semolina, '
      'Cornstarch, Baking powder, Baking soda, Vanilla, Cocoa, Chocolate chips, '
      'Olive oil, Sunflower oil, Vegetable oil, Vinegar, Tomato paste, Ketchup, '
      'Mayonnaise, Mustard, Soy sauce, Hot sauce, Pasta sauce, Canned tomatoes, '
      'Canned corn, Canned tuna, Pickles, Black pepper, Paprika, Chili flakes, '
      'Cumin, Curry, Turmeric, Cinnamon, Oregano, Thyme, Bay leaves, Sesame, '
      'Chia, Quinoa, Stock cubes, Broth, Soup, Raisins, Walnuts, Hazelnuts, '
      'Almonds, Pistachios, Cashews, Peanuts, Nuts, Seeds, Popcorn',
  QuickAisle.drinks:
      'Water, Sparkling water, Soda, Cola, Juice, Orange juice, Apple juice, '
      'Lemonade, Iced tea, Energy drink, Tea, Green tea, Herbal tea, Coffee, '
      'Instant coffee, Ground coffee, Coffee capsules, Hot chocolate, Beer, '
      'Wine, Tonic, Ice',
  QuickAisle.snacks:
      'Chocolate, Dark chocolate, Biscuits, Crackers, Chips, Crisps, Pretzels, '
      'Candy, Gum, Sweets, Protein bars, Granola bars, Ice cream, Pudding, '
      'Dessert, Snacks',
  QuickAisle.frozen:
      'Frozen peas, Frozen corn, Frozen vegetables, Frozen pizza, Frozen fries, '
      'French fries, Nuggets, Fish fingers, Frozen berries, Frozen spinach, '
      'Ice cubes, Ready meals',
  QuickAisle.cleaning:
      'Detergent, Laundry detergent, Fabric softener, Bleach, Stain remover, '
      'Dish soap, Dishwasher tablets, Dishwasher salt, Rinse aid, Sponges, '
      'Sponge, Scourer, Surface cleaner, Glass cleaner, Bathroom cleaner, '
      'Toilet cleaner, Drain cleaner, Hand soap, Soap, Disinfectant, Trash bags, '
      'Bin bags, Freezer bags, Cling film, Aluminium foil, Aluminum foil, '
      'Baking paper, Paper towels, Toilet paper, Napkins, Tissues, Wet wipes, '
      'Cleaning cloths, Mop, Broom, Gloves, Air freshener',
  QuickAisle.home:
      'Batteries, Light bulbs, Matches, Lighter, Candles, Tape, Glue, Scissors, '
      'Food containers, Toothpicks, Straws, Paper cups, Paper plates, Charcoal, '
      'Hangers, Clothespins, Zip bags, Notebook, Pens',
  QuickAisle.personal:
      'Shampoo, Conditioner, Shower gel, Toothpaste, Toothbrush, Dental floss, '
      'Mouthwash, Deodorant, Perfume, Shaving foam, Razor, Razors, Pads, Tampons, '
      'Cotton pads, Cotton swabs, Hand cream, Face cream, Moisturizer, Sunscreen, '
      'Body lotion, Lip balm, Makeup remover, Face wash, Hair dye, Hair gel, '
      'Comb, Nail clippers, Band-aids, Plasters, Painkillers, Vitamins',
  QuickAisle.baby:
      'Diapers, Nappies, Baby wipes, Baby food, Formula, Baby shampoo, Baby oil, '
      'Diaper cream, Baby powder, Bottle, Pacifier',
  QuickAisle.pet:
      'Cat food, Dog food, Cat litter, Wet food, Dry food, Treats, Bird seed, '
      'Fish food',
};
