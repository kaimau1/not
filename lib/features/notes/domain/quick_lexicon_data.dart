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
      'Domates, Salatalık, Soğan, Kuru soğan, Yeşil soğan, Taze soğan, Arpacık soğan, Mor soğan, Patates, '
      'Limon, Misket limonu, Muz, Elma, Yeşil elma, Kırmızı elma, Armut, Maydanoz, Dereotu, Nane, Roka, Marul, Kıvırcık, '
      'Göbek marul, Yedikule marulu, Akdeniz yeşilliği, Ispanak, Pazı, Semizotu, Tere, Kuzu kulağı, Reyhan, Fesleğen, Kekik, Biberiye, '
      'Havuç, Kabak, Sakız kabağı, Bal kabağı, Patlıcan, Kemer patlıcan, Bostan patlıcan, Biber, Sivri biber, Çarliston biber, Dolmalık biber, '
      'Kapya biber, Kırmızı biber, Yeşil biber, Acı biber, Kıl biber, Jalapeno, Sarımsak, Taze sarımsak, Zencefil, Zerdeçal kökü, '
      'Brokoli, Karnabahar, Lahana, Kırmızı lahana, Beyaz lahana, Brüksel lahanası, Kara lahana, '
      'Pırasa, Kereviz, Turp, Kırmızı turp, Siyah turp, Beyaz turp, Pancar, Kırmızı pancar, Şalgam, Enginar, Bamya, Bezelye, Fasulye, '
      'Taze fasulye, Börülce, Barbunya, Bakla, Mısır, Süt mısır, Mantar, Kültür mantarı, İstiridye mantarı, '
      'Avokado, Kuşkonmaz, Balkabağı, Tatlı patates, Yer elması, Asma yaprağı, Ebegümeci, Radika, Hardal otu, '
      'Portakal, Sıkmalık portakal, Mandalina, Greyfurt, Çilek, Kiraz, Vişne, Kayısı, Şeftali, '
      'Nektarin, Erik, Yeşil erik, Mürdüm eriği, Üzüm, Çekirdeksiz üzüm, Siyah üzüm, Karpuz, Kavun, İncir, Nar, Ayva, Kivi, Ananas, '
      'Mango, Hindistan cevizi, Böğürtlen, Ahududu, Yaban mersini, Dut, Karadut, Hurma, Medine hurması, '
      'Trabzon hurması, Muşmula, Yenidünya, Kestane, Meyve, Sebze, Yeşillik, '
      'Salata malzemesi, Cherry domates, Çeri domates, Salkım domates, Köy domatesi, Pembe domates, Çengelköy salatalık, Turşuluk salatalık, '
      'Kızılcık, Alıç, İğde, Çarkıfelek, Ejder meyvesi, Papaya, Lime',
  QuickAisle.bakery:
      'Ekmek, Tam buğday ekmeği, Kepekli ekmek, Çavdar ekmeği, Köy ekmeği, Ekşi mayalı ekmek, Mısır ekmeği, Trabzon ekmeği, '
      'Tost ekmeği, Sandviç ekmeği, Hamburger ekmeği, Hot dog ekmeği, Baget ekmek, Ciabatta, Lavaş, Bazlama, Pide, Ramazan pidesi, '
      'Simit, Susamlı simit, Poğaça, Peynirli poğaça, Patatesli poğaça, Açma, Börek, Su böreği, Kol böreği, Sigara böreği, '
      'Kruvasan, Çörek, Tahinli çörek, Ay çöreği, Galeta, Grissini, Etimek, Peksimet, Yufka, '
      'Baklavalık yufka, Kadayıf, Tel kadayıf, Güllaç, Milföy, Milföy hamuru, Kek, Pasta, Pandispanya, Kurabiye, Bayat ekmek, Tortilla, '
      'Pizza hamuru, Lahmacun hamuru, Mantı hamuru, Erişte hamuru, Maya, Yaş maya, Kuru maya, İnstant maya, Tartolet',
  QuickAisle.breakfast:
      'Süt, Tam yağlı süt, Yarım yağlı süt, Yağsız süt, Günlük süt, Keçi sütü, Yumurta, Organik yumurta, Bıldırcın yumurtası, '
      'Peynir, Beyaz peynir, Tam yağlı beyaz peynir, Kaşar, Kaşar peyniri, Taze kaşar, '
      'Eski kaşar, Kars kaşarı, Tulum peyniri, İzmir tulum, Erzincan tulum, Lor, Lor peyniri, Çökelek, Labne, Krem peynir, '
      'Mozzarella, Burrata, Parmesan, Cheddar, Hellim, Dil peyniri, Örgü peyniri, Çeçil peyniri, Mihaliç peyniri, Van otlu peynir, '
      'Ezine peyniri, Süzme peynir, Üçgen peynir, Ricotta, Mascarpone, Keçi peyniri, Rokfor, '
      'Yoğurt, Süzme yoğurt, Köy yoğurdu, Probiyotik yoğurt, Meyveli yoğurt, Ayran, '
      'Kefir, Tereyağı, Tuzsuz tereyağı, Köy tereyağı, Margarin, Kaymak, Krema, Sıvı krema, Krem şanti, Ekşi krema, '
      'Zeytin, Siyah zeytin, Yeşil zeytin, Kırma zeytin, Çizik zeytin, Sele zeytini, Biberli zeytin, '
      'Bal, Çiçek balı, Çam balı, Petek bal, Reçel, Çilek reçeli, Vişne reçeli, Gül reçeli, İncir reçeli, Ayva reçeli, '
      'Kayısı reçeli, Portakal reçeli, Marmelat, Pekmez, Üzüm pekmezi, Keçiboynuzu pekmezi, Dut pekmezi, '
      'Tahin, Tahin pekmez, Helva, Tahin helvası, Yaz helvası, Fındık ezmesi, '
      'Fıstık ezmesi, Badem ezmesi, Çikolata kreması, Kakaolu fındık kreması, '
      'Sucuk, Kangal sucuk, Parmak sucuk, Salam, Sosis, Pastırma, Çemensiz pastırma, Jambon, Füme et, '
      'Hindi füme, Tavuk jambon, Kavurma, Mısır gevreği, Yulaf, Yulaf ezmesi, Müsli, Granola, '
      'Laktozsuz süt, Badem sütü, Yulaf sütü, Soya sütü, Hindistan cevizi sütü, Süt tozu, Menemen malzemesi, Krep karışımı, Pankek karışımı',
  QuickAisle.meat:
      'Tavuk, Tavuk göğsü, Tavuk fileto, Tavuk but, Tavuk kalça, Tavuk kanat, Tavuk baget, Bütün tavuk, Köy tavuğu, '
      'Tavuk pirzola, Tavuk kıyma, Tavuk ciğer, Tavuk taşlık, Tavuk şiş, Tavuk döner, '
      'Hindi, Hindi göğsü, Hindi but, Hindi kıyma, Ördek, '
      'Kıyma, Dana kıyma, Az yağlı kıyma, Orta yağlı kıyma, Kuzu kıyma, Kuşbaşı, Dana kuşbaşı, Kuzu kuşbaşı, '
      'Biftek, Antrikot, Bonfile, Kontrfile, T-bone, Ribeye, Dana eti, Kuzu eti, Sote et, Tas kebaplık et, '
      'Pirzola, Kuzu pirzola, Dana pirzola, Kuzu incik, Kuzu but, Kuzu kol, Kuzu gerdan, Kaburga, Dana kaburga, Dana rosto, '
      'Ciğer, Dana ciğer, Kuzu ciğer, Böbrek, Yürek, Köfte, İnegöl köfte, Kasap köfte, '
      'Köftelik kıyma, Döner, Et döner, Pastırmalık et, İlikli kemik, '
      'Balık, Somon, Somon fileto, Levrek, Çipura, Hamsi, İstavrit, '
      'Palamut, Lüfer, Çinekop, Mezgit, Alabalık, Ton balığı, Sardalya, Uskumru, Barbun, Tekir, Kalkan, Dil balığı, '
      'Karides, Çimçim karides, Jumbo karides, Kalamar, Midye, Ahtapot, İstiridye, Et, Kemik suyu, Kemik, İşkembe, Sakatat, Kokoreç',
  QuickAisle.pantry:
      'Un, Tam buğday unu, Çavdar unu, Glutensiz un, Badem unu, Mısır unu, Pirinç unu, Nohut unu, '
      'Şeker, Toz şeker, Küp şeker, Esmer şeker, Pudra şekeri, Hindistan cevizi şekeri, Stevia, Tatlandırıcı, '
      'Tuz, Kaya tuzu, Deniz tuzu, İyotlu tuz, Himalaya tuzu, Sofra tuzu, '
      'Pirinç, Baldo pirinç, Osmancık pirinç, Yasemin pirinç, Basmati pirinç, Siyah pirinç, Esmer pirinç, Kırık pirinç, '
      'Bulgur, Pilavlık bulgur, Köftelik bulgur, Esmer bulgur, Firik bulguru, Siyez bulguru, '
      'Makarna, Spagetti, Penne, Burgu makarna, Kelebek makarna, Lazanya, Erişte, Mantı, Şehriye, Arpa şehriye, Tel şehriye, Kuskus, Tarhana, '
      'Mercimek, Kırmızı mercimek, Yeşil mercimek, Sarı mercimek, Beluga mercimek, Nohut, Kuru fasulye, Dermason fasulye, '
      'Barbunya fasulye, Maş fasulyesi, Börülce, Bakla, İrmik, Nişasta, Mısır nişastası, Buğday nişastası, '
      'Galeta unu, Panko, Kabartma tozu, Vanilya, Şekerli vanilin, Karbonat, Kakao, Damla çikolata, Kuvertür çikolata, '
      'Zeytinyağı, Sızma zeytinyağı, Riviera zeytinyağı, Ayçiçek yağı, Sıvı yağ, Mısırözü yağı, Fındık yağı, Kanola yağı, Avokado yağı, '
      'Susam yağı, Hindistan cevizi yağı, Sade yağ, Sirke, Elma sirkesi, Üzüm sirkesi, Balzamik sirke, Beyaz sirke, Pirinç sirkesi, Nar ekşisi, Limon suyu, '
      'Salça, Domates salçası, Biber salçası, Acı biber salçası, Tatlı biber salçası, Ketçap, Mayonez, Hardal, Dijon hardal, Soya sosu, '
      'Acı sos, Barbekü sos, Ranch sos, Sezar sos, Pesto sos, Teriyaki sos, Makarna sosu, Napoliten sos, Domates sosu, Domates püresi, Konserve domates, '
      'Konserve, Konserve mısır, Konserve bezelye, Konserve fasulye, Konserve nohut, Konserve ton balığı, Turşu, Salatalık turşusu, Lahana turşusu, '
      'Kornişon, Jalapeno turşusu, Közlenmiş biber, Közlenmiş patlıcan, Zeytin ezmesi, Kapari, Kurutulmuş domates, '
      'Karabiber, Tane karabiber, Pul biber, İsot, Kırmızı toz biber, Tatlı toz biber, Acı toz biber, '
      'Kimyon, Sumak, Köri, Zerdeçal, Tarçın, Çubuk tarçın, Karanfil, Yenibahar, Defne yaprağı, Kişniş, '
      'Kuru nane, Kuru kekik, Dağ kekiği, Biberiye, Fesleğen, Reyhan, Mahlep, Çöven, Muskat, Kakule, Safran, Vanilya çubuğu, '
      'Sarımsak tozu, Soğan tozu, Zencefil tozu, Kajun baharatı, Tavuk baharatı, Köfte harcı, Susam, Kavrulmuş susam, '
      'Çörek otu, Haşhaş, Keten tohumu, Chia, Kinoa, Karabuğday, Greçka, Yulaf unu, Amarant, '
      'Hazır çorba, Mercimek çorbası, Tarhana çorbası, Bulyon, Tavuk suyu, Et suyu, Sebze bulyon, Noodle, Hazır makarna, Hazır puding, Krem karamel, Jelatin, '
      'Kuru üzüm, Sarı üzüm, Kuru kayısı, Gün kurusu, Kuru incir, Kuru erik, Kuru dut, Kuru yaban mersini, Turna yemişi, '
      'Ceviz, Ceviz içi, Fındık, Kavrulmuş fındık, Çiğ fındık, Badem, Çiğ badem, Antep fıstığı, Siirt fıstığı, Kaju, Yer fıstığı, Çam fıstığı, Leblebi, Sarı leblebi, Beyaz leblebi, Kuruyemiş, '
      'Çekirdek, Kabak çekirdeği, Ay çekirdeği, Hindistan cevizi rendesi, '
      'Tane mısır, Patlak mısır, Mısır patlağı',
  QuickAisle.drinks:
      'Su, Damacana su, Pet su, Şişe su, Bebek suyu, Maden suyu, Soda, Sade soda, Meyveli soda, Limonlu soda, Kola, Diyet kola, Gazoz, Portakallı gazoz, '
      'Meyve suyu, Portakal suyu, Vişne suyu, Elma suyu, Şeftali suyu, Kayısı suyu, Ananas suyu, Nar suyu, Domates suyu, Limonata, '
      'Soğuk çay, Buzlu çay, Şeftalili soğuk çay, Limonlu soğuk çay, Enerji içeceği, İzotonik içecek, Sporcu içeceği, Şalgam suyu, Acılı şalgam, Boza, '
      'Çay, Siyah çay, Demlik poşet çay, Süzen poşet çay, Tomurcuk çay, Earl Grey, Kaçak çay, '
      'Yeşil çay, Yaseminli yeşil çay, Beyaz çay, Bitki çayı, Ihlamur, Papatya çayı, Adaçayı, Kuşburnu, Rezene çayı, Melisa çayı, Hibiskus, Mate çayı, Rooibos, '
      'Nane limon, Zencefilli çay, Kış çayı, Form çayı, Detoks çayı, '
      'Kahve, Türk kahvesi, Dibek kahvesi, Menengiç kahvesi, Filtre kahve, Çekirdek kahve, Granül kahve, Hazır kahve, 3ü1 arada, 2si1 arada, '
      'Espresso, Kapsül kahve, Soğuk kahve, Latte, Cappuccino, Mocha, Matcha, '
      'Sıcak çikolata, Salep, Sahlep, Kakaolu süt, Çikolatalı süt, Çilekli süt, '
      'Bira, Şarap, Kırmızı şarap, Beyaz şarap, Rakı, Votka, Cin, Viski, Tonik, '
      'Buz, Süt kreması, Kahve kreması, Kahve şurubu',
  QuickAisle.snacks:
      'Çikolata, Bitter çikolata, Sütlü çikolata, Beyaz çikolata, Antep fıstıklı çikolata, Fındıklı çikolata, Madlen çikolata, '
      'Gofret, Çikolatalı gofret, Fındıklı gofret, Bisküvi, Petibör, Bebe bisküvisi, Yulaflı bisküvi, Kremalı bisküvi, '
      'Kraker, Tuzlu kraker, Susamlı kraker, Peynirli kraker, Cips, Patates cipsi, Mısır cipsi, Tortilla cips, Çubuk kraker, Patlamış mısır, '
      'Şekerleme, Naneli şeker, Akide şekeri, Sakız, Lokum, Güllü lokum, Fıstıklı lokum, Cezerye, Pestil, Köme, '
      'Jelibon, Marshmallow, Bonbon, Bar, Protein bar, Granola bar, Müsli bar, Meyve barı, Hurma bar, '
      'Kuru meyve, Çıtır nohut, Pirinç patlağı, Dondurma, Külah dondurma, Magnum, Puding, Sütlaç, Kazandibi, Supangle, Profiterol, Magnolya, '
      'Tatlı, Baklava, Şöbiyet, Künefe, Waffle, Brownie, Muffin, Kek dilimi, Kruvasan, Atıştırmalık, Kuruyemiş bar',
  QuickAisle.frozen:
      'Dondurulmuş bezelye, Dondurulmuş mısır, Dondurulmuş sebze, Dondurulmuş brokoli, Dondurulmuş fasulye, Dondurulmuş bamya, '
      'Dondurulmuş enginar, Dondurulmuş böğürtlen, Dondurulmuş çilek, Dondurulmuş vişne, Dondurulmuş frambuaz, '
      'Dondurulmuş pizza, Dondurulmuş patates, Parmak patates, Elma dilim patates, Soğan halkası, Kroket, '
      'Dondurulmuş börek, Su böreği, Sigara böreği, Çiğ börek, Lahmacun, Pide, Mantı, Kayseri mantısı, '
      'Dondurulmuş mantı, Dondurulmuş köfte, İnegöl köfte, Burger köftesi, Nugget, Tavuk nugget, Şinitzel, Tavuk schnitzel, Çıtır tavuk, '
      'Balık kroket, Balık fileto, Dondurulmuş karides, Dondurulmuş kalamar, Dondurulmuş somon, '
      'Dondurulmuş meyve, Dondurulmuş ıspanak, Garnitür, Buz küpü, Hazır yemek, Dondurulmuş falafel, Edamame',
  QuickAisle.cleaning:
      'Deterjan, Çamaşır deterjanı, Sıvı deterjan, Toz deterjan, Kapsül deterjan, Renkli deterjanı, Beyaz deterjanı, Siyahlar için deterjan, Yünlü deterjanı, '
      'Yumuşatıcı, Konsantre yumuşatıcı, Çamaşır parfümü, Çamaşır suyu, Oksijenli çamaşır suyu, Leke çıkarıcı, Kireç önleyici, '
      'Bulaşık deterjanı, Bulaşık sıvısı, Bulaşık tableti, Bulaşık kapsülü, '
      'Bulaşık makinesi tableti, Bulaşık makinesi tuzu, Parlatıcı, Makine temizleyici, Makine kokusu, '
      'Bulaşık süngeri, Sünger, Bulaşık teli, Bulaşık fırçası, Çelik tel, '
      'Yüzey temizleyici, Arap sabunu, Ahşap temizleyici, Parke temizleyici, Fayans temizleyici, '
      'Cam temizleyici, Banyo temizleyici, Duşakabin spreyi, Mutfak temizleyici, Yağ çözücü, Ocak temizleyici, Fırın temizleyici, '
      'Kireç çözücü, Pas çözücü, Tuvalet temizleyici, Klozet bloğu, Lavabo açıcı, '
      'Sıvı sabun, Köpük sabun, El sabunu, Kalıp sabun, Sabun, Dezenfektan, Yüzey dezenfektanı, Kolonya, Limon kolonyası, El dezenfektanı, '
      'Çöp torbası, Çöp poşeti, Büyük boy çöp poşeti, Orta boy çöp poşeti, Küçük boy çöp poşeti, Büzgülü çöp poşeti, '
      'Buzdolabı poşeti, Streç film, Alüminyum folyo, Pişirme kağıdı, Yağlı kağıt, Kek kapsülü, '
      'Kağıt havlu, Tuvalet kağıdı, Peçete, Masa peçetesi, Kağıt mendil, Cep mendili, Kutu mendil, Islak mendil, '
      'Temizlik bezi, Mikrofiber bez, Cam bezi, Yer bezi, Toz bezi, Sarı bez, '
      'Paspas, Mop, Yedek mop ucu, Vileda, Süpürge, Faraş, Eldiven, Bulaşık eldiveni, Lateks eldiven, '
      'Oda kokusu, Bambu çubuklu oda kokusu, Sinek ilacı, Böcek ilacı, Karınca ilacı, Güve tableti, Naftalin, Nem alıcı',
  QuickAisle.home:
      'Pil, Kalem pil, İnce pil, Saat pili, Şarjlı pil, 9V pil, Ampul, LED ampul, Tasarruflu ampul, Gece lambası, '
      'Kibrit, Çakmak, Ocak çakmağı, Mum, Kokulu mum, Tealight mum, '
      'Bant, Koli bandı, Çift taraflı bant, Elektrik bandı, Maskeleme bandı, Yapıştırıcı, Japon yapıştırıcı, Silikon, '
      'Makas, Maket bıçağı, Uzatma kablosu, Priz, Üçlü priz, Akım korumalı priz, Poşet, Alışveriş çantası, Pazar arabası, '
      'Saklama kabı, Cam saklama kabı, Vakumlu poşet, Kavanoz, Kavanoz kapağı, '
      'Kürdan, Pipet, Çöp şiş, Mangal teli, Plastik bardak, Plastik tabak, Karton bardak, Karton tabak, Plastik çatal, '
      'Mangal kömürü, Çıra, Tutuşturucu, Buz torbası, Termofor, '
      'Ütü suyu, Ütü bezi, Askı, Elbise askısı, Mandal, Çamaşır ipi, Çamaşır sepeti, Kilitli poşet, '
      'Defter, Kalem, Şarj kablosu, Çiçek toprağı, Torf, Saksı, Bitki besini, Ayakkabı boyası, Ayakkabı çekeceği, Terlik',
  QuickAisle.personal:
      'Şampuan, Kepek şampuanı, Dökülme karşıtı şampuan, Kuru şampuan, Saç kremi, Saç maskesi, Saç yağı, Argan yağı, '
      'Duş jeli, Banyo köpüğü, Vücut peelingi, Diş macunu, Beyazlatıcı diş macunu, Hassas diş macunu, Diş fırçası, Elektrikli diş fırçası başlığı, Diş ipi, '
      'Ağız gargarası, Ağız bakım suyu, Dil temizleyici, '
      'Deodorant, Roll-on, Stick deodorant, Parfüm, Vücut spreyi, Kolonya, '
      'Tıraş köpüğü, Tıraş jeli, Tıraş bıçağı, Jilet, Tıraş losyonu, Tıraş sonrası balsam, Ağda, Ağda bandı, Tüy dökücü krem, '
      'Ped, Hijyenik ped, Gece pedi, Günlük ped, Tampon, Pamuk, Kulak çubuğu, Makyaj pamuğu, Disk pamuk, '
      'El kremi, Yüz kremi, Göz kremi, Gece kremi, Nemlendirici, Güneş kremi, Güneş sütü, Bronzlaştırıcı, Vücut losyonu, Vücut yağı, Dudak kremi, Vazelin, '
      'Makyaj temizleyici, Misel su, Yüz yıkama jeli, Yüz temizleme köpüğü, Tonik, Serum, C vitamini serumu, Hyaluronik asit, Peeling, Yüz maskesi, Kağıt maske, '
      'Saç boyası, Oksidan, Saç jölesi, Saç köpüğü, Saç spreyi, Wax, Tarak, Saç fırçası, Toka, Tel toka, Lastik toka, '
      'Tırnak makası, Törpü, Cımbız, Oje, Aseton, El dezenfektanı, '
      'Yara bandı, Sargı bezi, Gazlı bez, Ağrı kesici, Vitamin, Multivitamin, C vitamini, D vitamini, Magnezyum, Ateş ölçer, Prezervatif, Kayganlaştırıcı, '
      'Lens solüsyonu, Lens kabı, Banyo lifi, Kese, Havlu, Yüz havlusu, Terlik, Kulak tıkacı',
  QuickAisle.baby:
      'Bebek bezi, Yenidoğan bezi, Külot bez, Mayo bez, Islak havlu, Saf su mendili, Bebek maması, Kavanoz maması, Kaşık maması, Devam sütü, Formül mama, '
      'Bebek bisküvisi, Bebek suyu, Bebek çayı, Rezene çayı, '
      'Bebek şampuanı, Bebek vücut şampuanı, Bebek sabunu, Bebek yağı, Bebek losyonu, Pişik kremi, Bebek pudrası, Bebek güneş kremi, '
      'Biberon, Biberon emziği, Biberon fırçası, Emzik, Emzik zinciri, Alıştırma bardağı, Bebek kaşığı, Mama kabı, '
      'Önlük, Mama önlüğü, Müslin bez, Ağız mendili, Alt açma örtüsü, Kirli bez torbası, '
      'Bebek deterjanı, Bebek yumuşatıcısı, Leke çıkarıcı, Diş kaşıyıcı, Burun aspiratörü, Bebek tırnak makası, Bebek mendili',
  QuickAisle.pet:
      'Kedi maması, Yavru kedi maması, Kısır kedi maması, Köpek maması, Yavru köpek maması, '
      'Kedi kumu, Bentonit kum, Silika kum, Pelet kum, Yaş mama, Konserve mama, Kuru mama, Ödül maması, Kedi maltı, '
      'Kuş yemi, Muhabbet kuşu yemi, Kanarya yemi, Balık yemi, Kaplumbağa yemi, Kemirgen yemi, Talaş, '
      'Tasma, Göğüs tasması, Gezdirme kayışı, Mama kabı, Su pınarı filtresi, Kedi otu, Pire damlası, İç parazit tableti, Kedi oyuncağı, Tırmalama tahtası, Dışkı torbası',
};

const Map<QuickAisle, String> kQuickLexiconEn = {
  QuickAisle.produce:
      'Tomatoes, Tomato, Cherry tomatoes, Cucumber, Cucumbers, Onion, Onions, Red onion, Spring onions, Green onions, Shallots, Potatoes, Potato, '
      'Lemon, Lemons, Lime, Limes, Bananas, Banana, Apples, Apple, Green apple, Pears, Pear, Parsley, Dill, '
      'Mint, Basil, Cilantro, Coriander, Rocket, Arugula, Lettuce, Romaine lettuce, Iceberg lettuce, Spinach, Kale, Swiss chard, Watercress, Carrots, '
      'Carrot, Zucchini, Courgette, Eggplant, Aubergine, Peppers, Bell pepper, Red pepper, Green pepper, Yellow pepper, '
      'Chili, Jalapeno, Garlic, Ginger, Turmeric root, Broccoli, Cauliflower, Cabbage, Red cabbage, Brussels sprouts, Leek, Celery, '
      'Radish, Beetroot, Beets, Turnip, Artichoke, Okra, Peas, Snow peas, Green beans, Corn, Sweetcorn, Mushrooms, Button mushrooms, Portobello, Avocado, '
      'Asparagus, Pumpkin, Butternut squash, Sweet potato, Oranges, Orange, Tangerines, Mandarin, Grapefruit, '
      'Strawberries, Cherries, Sour cherries, Apricots, Peaches, Nectarines, Plums, Grapes, Red grapes, Green grapes, Watermelon, '
      'Melon, Cantaloupe, Honeydew, Figs, Pomegranate, Quince, Kiwi, Pineapple, Mango, Coconut, Blackberries, '
      'Raspberries, Blueberries, Cranberries, Dates, Persimmon, Dragon fruit, Papaya, Fruit, Vegetables, Salad, Fresh herbs, Herbs',
  QuickAisle.bakery:
      'Bread, Wholemeal bread, Whole wheat bread, Sourdough bread, Rye bread, White bread, Multigrain bread, Toast bread, Buns, Burger buns, Hot dog buns, '
      'Bagels, Tortillas, Wraps, Pita, Pitta bread, Flatbread, Lavash, Croissants, Brioche, Rolls, Baguette, Ciabatta, Focaccia, '
      'Cake, Cupcakes, Muffins, Cookies, Biscuits, Pastry, Puff pastry, Phyllo dough, Pizza dough, Breadsticks, Croutons, Yeast, Active dry yeast',
  QuickAisle.breakfast:
      'Milk, Whole milk, Semi-skimmed milk, Skim milk, Lactose-free milk, Eggs, Free-range eggs, Cheese, Feta, Cheddar, Mozzarella, Burrata, Parmesan, Cream cheese, '
      'Cottage cheese, Ricotta, Mascarpone, Halloumi, Gouda, Brie, Camembert, Goat cheese, Blue cheese, Swiss cheese, Sliced cheese, '
      'Yogurt, Greek yogurt, Plain yogurt, Fruit yogurt, Butter, Unsalted butter, Salted butter, Margarine, Cream, Heavy cream, '
      'Sour cream, Whipped cream, Olives, Black olives, Green olives, Honey, Jam, Strawberry jam, Apricot jam, Marmalade, Peanut butter, Almond butter, '
      'Hazelnut spread, Nutella, Tahini, Molasses, Sausages, Salami, Ham, Turkey breast, Bacon, Smoked salmon, Cereal, Cornflakes, '
      'Oats, Oatmeal, Rolled oats, Porridge, Muesli, Granola, Pancake mix, Almond milk, Oat milk, Soy milk, Coconut milk, Kefir, Ayran',
  QuickAisle.meat:
      'Chicken, Chicken breast, Chicken thighs, Chicken wings, Chicken drumsticks, Whole chicken, Chicken tenders, Ground chicken, '
      'Turkey, Ground turkey, Duck, Ground beef, Minced meat, Mince, Beef, Steak, Ribeye, Sirloin, Tenderloin, Beef stew meat, Roast beef, '
      'Lamb, Lamb chops, Lamb leg, Ground lamb, Pork, Pork chops, Pork belly, Ribs, Meatballs, Burger patties, Liver, '
      'Fish, Salmon, Salmon fillet, Tuna, Sea bass, Sea bream, Cod, Haddock, Tilapia, Trout, Mackerel, Sardines, Anchovies, '
      'Shrimp, Prawns, Mussels, Clams, Calamari, Squid, Octopus, Crab, Meat, Bone broth',
  QuickAisle.pantry:
      'Flour, All-purpose flour, Whole wheat flour, Almond flour, Cornmeal, Sugar, White sugar, Brown sugar, Powdered sugar, Icing sugar, Honey, Maple syrup, Stevia, '
      'Salt, Sea salt, Kosher salt, Himalayan salt, Rice, Jasmine rice, Basmati rice, Brown rice, Arborio rice, Bulgur, Quinoa, Couscous, '
      'Pasta, Spaghetti, Penne, Fusilli, Macaroni, Lasagna sheets, Noodles, Ramen, Egg noodles, '
      'Lentils, Red lentils, Green lentils, Chickpeas, Beans, Black beans, Kidney beans, White beans, Pinto beans, Semolina, '
      'Cornstarch, Baking powder, Baking soda, Vanilla extract, Cocoa powder, Chocolate chips, '
      'Olive oil, Extra virgin olive oil, Sunflower oil, Vegetable oil, Canola oil, Coconut oil, Sesame oil, Avocado oil, '
      'Vinegar, Apple cider vinegar, Balsamic vinegar, White vinegar, Rice vinegar, Pomegranate molasses, Lemon juice, '
      'Tomato paste, Tomato puree, Canned tomatoes, Crushed tomatoes, Ketchup, Mayonnaise, Mustard, Dijon mustard, Soy sauce, Teriyaki sauce, '
      'Hot sauce, Sriracha, BBQ sauce, Pesto, Pasta sauce, Marinara sauce, Alfredo sauce, Salad dressing, '
      'Canned corn, Canned peas, Canned tuna, Canned beans, Pickles, Pickled cucumbers, Olives, Capers, Sun-dried tomatoes, Roasted peppers, '
      'Black pepper, Peppercorns, Paprika, Smoked paprika, Chili flakes, Cayenne pepper, Chili powder, '
      'Cumin, Curry powder, Turmeric, Cinnamon, Nutmeg, Cloves, Cardamom, Coriander, Oregano, Thyme, Rosemary, Bay leaves, Garlic powder, Onion powder, Sesame seeds, '
      'Chia seeds, Flaxseed, Pumpkin seeds, Sunflower seeds, Stock cubes, Chicken broth, Beef broth, Vegetable broth, Soup, Canned soup, '
      'Raisins, Dried apricots, Dried figs, Dried cranberries, Prunes, Walnuts, Hazelnuts, '
      'Almonds, Pistachios, Cashews, Peanuts, Pecans, Macadamia, Nuts, Trail mix, Seeds, Popcorn, Breadcrumbs, Panko',
  QuickAisle.drinks:
      'Water, Bottled water, Still water, Sparkling water, Mineral water, Tonic water, Soda, Cola, Diet cola, Ginger ale, Lemonade, '
      'Juice, Orange juice, Apple juice, Cranberry juice, Pineapple juice, Grape juice, Tomato juice, Smoothie, '
      'Iced tea, Energy drink, Sports drink, Kombucha, Coconut water, '
      'Tea, Black tea, Green tea, White tea, Herbal tea, Chamomile tea, Peppermint tea, Earl Grey, Matcha, '
      'Coffee, Ground coffee, Coffee beans, Instant coffee, Espresso, Coffee capsules, Decaf coffee, Cold brew, Iced coffee, '
      'Hot chocolate, Chocolate milk, Beer, Craft beer, Wine, Red wine, White wine, Sparkling wine, Cider, Ice, Coffee creamer',
  QuickAisle.snacks:
      'Chocolate, Dark chocolate, Milk chocolate, White chocolate, Chocolate bar, Biscuits, Cookies, Digestive biscuits, Crackers, Water crackers, '
      'Chips, Potato chips, Tortilla chips, Crisps, Pretzels, Popcorn, Rice cakes, '
      'Candy, Gum, Chewing gum, Gummies, Marshmallows, Mints, Sweets, '
      'Protein bars, Granola bars, Energy bars, Cereal bars, Fruit snacks, Dried fruit, Ice cream, Gelato, Popsicles, Pudding, Yogurt cup, Cake, Brownies, Dessert, Snacks',
  QuickAisle.frozen:
      'Frozen peas, Frozen corn, Frozen vegetables, Frozen broccoli, Frozen green beans, Frozen mixed veggies, '
      'Frozen pizza, Frozen fries, French fries, Hash browns, Tater tots, Onion rings, '
      'Nuggets, Chicken nuggets, Chicken tenders, Fish fingers, Fish sticks, Frozen salmon, Frozen shrimp, '
      'Frozen berries, Frozen strawberries, Frozen blueberries, Frozen mango, Frozen spinach, Frozen dumplings, Frozen waffles, Frozen meals, Ready meals, Ice cubes',
  QuickAisle.cleaning:
      'Detergent, Laundry detergent, Liquid detergent, Laundry pods, Fabric softener, Stain remover, Bleach, Color catcher, '
      'Dish soap, Dishwasher tablets, Dishwasher pods, Dishwasher salt, Rinse aid, Sponges, '
      'Sponge, Scourer, Steel wool, Dish brush, Surface cleaner, All-purpose cleaner, Wood cleaner, Floor cleaner, Glass cleaner, Bathroom cleaner, '
      'Toilet cleaner, Toilet gel, Drain cleaner, Descaler, Degreaser, Oven cleaner, Hand soap, Liquid soap, Bar soap, Soap, Disinfectant, Hand sanitizer, '
      'Trash bags, Bin bags, Garbage bags, Freezer bags, Sandwich bags, Cling film, Plastic wrap, Aluminium foil, Aluminum foil, '
      'Baking paper, Parchment paper, Paper towels, Kitchen roll, Toilet paper, Napkins, Tissues, Facial tissues, Wet wipes, Disinfecting wipes, '
      'Cleaning cloths, Microfiber cloths, Mop, Mop refill, Broom, Dustpan, Rubber gloves, Latex gloves, Air freshener, Bug spray',
  QuickAisle.home:
      'Batteries, AA batteries, AAA batteries, Button batteries, Light bulbs, LED bulbs, Matches, Lighter, Candles, Scented candles, '
      'Tape, Duct tape, Packing tape, Masking tape, Glue, Super glue, Scissors, Utility knife, Extension cord, Power strip, '
      'Food containers, Storage containers, Mason jars, Vacuum bags, Toothpicks, Skewers, Straws, Paper cups, Paper plates, Plastic cutlery, Charcoal, Lighter fluid, '
      'Hangers, Clothespins, Laundry basket, Zip bags, Ziploc bags, Notebook, Pens, Charging cable, Potting soil, Plant food, Shoe polish',
  QuickAisle.personal:
      'Shampoo, Dry shampoo, Conditioner, Hair mask, Hair oil, Shower gel, Body wash, Body scrub, '
      'Toothpaste, Toothbrush, Electric toothbrush heads, Dental floss, Mouthwash, '
      'Deodorant, Antiperspirant, Perfume, Cologne, Body mist, Shaving foam, Shaving gel, Razor, Razors, Razor blades, Aftershave, '
      'Pads, Sanitary pads, Pantyliners, Tampons, Menstrual cup, Cotton pads, Cotton swabs, Q-tips, '
      'Hand cream, Face cream, Eye cream, Moisturizer, Sunscreen, Sunblock, Body lotion, Lip balm, Petroleum jelly, '
      'Makeup remover, Micellar water, Face wash, Facial cleanser, Toner, Vitamin C serum, Face mask, Sheet mask, '
      'Hair dye, Hair gel, Hair spray, Hair wax, Comb, Hairbrush, Hair ties, Hair clips, '
      'Nail clippers, Nail file, Tweezers, Nail polish, Nail polish remover, '
      'Band-aids, Plasters, Bandages, Painkillers, Vitamins, Vitamin D, Vitamin C, Magnesium, Thermometer, Condoms, Contact lens solution, Loofah, Towels, Earplugs',
  QuickAisle.baby:
      'Diapers, Nappies, Swim diapers, Baby wipes, Water wipes, Baby food, Baby puree pouches, Formula, Infant formula, Baby cereal, '
      'Baby shampoo, Baby wash, Baby lotion, Baby oil, Diaper cream, Rash cream, Baby powder, '
      'Baby bottle, Bottle brush, Pacifier, Dummy, Sippy cup, Bibs, Burp cloths, Changing pad, Diaper bags, Baby detergent, Teether, Nasal aspirator',
  QuickAisle.pet:
      'Cat food, Kitten food, Dog food, Puppy food, Cat litter, Clumping litter, Wet food, Canned food, Dry food, Kibble, Treats, Cat treats, Dog treats, '
      'Bird seed, Fish food, Hamster food, Leash, Collar, Harness, Food bowl, Pet shampoo, Flea treatment, Catnip, Poop bags, Scratching post',
};
