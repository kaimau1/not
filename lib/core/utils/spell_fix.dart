/// **AI'SIZ TÜRKÇE YAZIM DÜZELTME** (kullanıcı isteği 2026-11-08): saf
/// kurallar — sözlük yok. Cihazın yazım denetçisi (Android) bunun üstüne
/// kelime önerisi verir (bkz. `auto_spell.dart`).
///
/// * Sık yazım hataları ([_common]): "herşey" → "her şey", "yanlız" →
///   "yalnız", "tabiki" → "tabii ki"…
/// * Konuşma ağzı "-yo" → "-yor" ("geliyo" → "geliyor").
/// * Bitişik soru eki ayrılır ("gelirmisin" → "gelir misin").
/// * Cümle başı büyük harf (Türkçe i → İ).
/// * Noktalamadan önceki boşluk silinir ("kelime ," → "kelime,").
library;

/// Türkçe büyük harf (i → İ, ı → I).
String trUpper(String s) =>
    s.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase();

String _trCapitalize(String w) =>
    w.isEmpty ? w : trUpper(w.substring(0, 1)) + w.substring(1);

const _common = <String, String>{
  'herşey': 'her şey',
  'birşey': 'bir şey',
  'hiçbirşey': 'hiçbir şey',
  'birsürü': 'bir sürü',
  'hergün': 'her gün',
  'birgün': 'bir gün',
  'herzaman': 'her zaman',
  'herkez': 'herkes',
  'pekçok': 'pek çok',
  'birkez': 'bir kez',
  'yada': 'ya da',
  'yinede': 'yine de',
  'şuan': 'şu an',
  'şuanda': 'şu anda',
  'yanlız': 'yalnız',
  'yalnış': 'yanlış',
  'malesef': 'maalesef',
  'maalesefki': 'maalesef ki',
  'tabiki': 'tabii ki',
  'orjinal': 'orijinal',
  'deyil': 'değil',
  'diil': 'değil',
  'eşortman': 'eşofman',
  'yapıcam': 'yapacağım',
  'gelicem': 'geleceğim',
  'gidicem': 'gideceğim',
  'edicem': 'edeceğim',
  'bakıcam': 'bakacağım',
  'alıcam': 'alacağım',
  'napıyorsun': 'ne yapıyorsun',
  'tşk': 'teşekkürler',
  'tşkler': 'teşekkürler',
  'slm': 'selam',
  'mrb': 'merhaba',
  'klavuz': 'kılavuz',
  'süpriz': 'sürpriz',
  'sürpiz': 'sürpriz',
  'herhalde': 'herhâlde',
  'yanlızca': 'yalnızca',
  'antreman': 'antrenman',
  'ünvan': 'unvan',
  'traş': 'tıraş',
  'meyva': 'meyve',
  'kiprik': 'kirpik',
  'hoşçakal': 'hoşça kal',
  // --- Y-3 (2026-11-20): elle derlenmiş yaygın yanlışlar. Anahtar HİÇBİR
  // bağlamda doğru yazım değildir; bağlama bağlı olanlar [kContextFixes]'te.
  // Bitişik yazılan "her/bir/hiç/ne/o/bu" öbekleri.
  'hiçkimse': 'hiç kimse',
  'herbir': 'her bir',
  'herbiri': 'her biri',
  'heryer': 'her yer',
  'heryerde': 'her yerde',
  'heryere': 'her yere',
  'heryerden': 'her yerden',
  'herşeyi': 'her şeyi',
  'herşeyin': 'her şeyin',
  'herşeye': 'her şeye',
  'herşeyden': 'her şeyden',
  'herşeyde': 'her şeyde',
  'birşeyi': 'bir şeyi',
  'birşeyler': 'bir şeyler',
  'birşeye': 'bir şeye',
  'birşeyden': 'bir şeyden',
  'birşeyin': 'bir şeyin',
  'hiçbirşeyi': 'hiçbir şeyi',
  'hiçbirşeye': 'hiçbir şeye',
  'hiçbirşekilde': 'hiçbir şekilde',
  'birşekilde': 'bir şekilde',
  'herhangibirşey': 'herhangi bir şey',
  'bişey': 'bir şey',
  'bişeyler': 'bir şeyler',
  'bişeyi': 'bir şeyi',
  'bişi': 'bir şey',
  'bisürü': 'bir sürü',
  'birsüre': 'bir süre',
  'birtane': 'bir tane',
  'birdaha': 'bir daha',
  'birkere': 'bir kere',
  'birtek': 'bir tek',
  'birsonraki': 'bir sonraki',
  'birönceki': 'bir önceki',
  'biryerde': 'bir yerde',
  'biryere': 'bir yere',
  'birzaman': 'bir zaman',
  'birgece': 'bir gece',
  'birhafta': 'bir hafta',
  'birsaat': 'bir saat',
  'bikaç': 'birkaç',
  'hergece': 'her gece',
  'hersabah': 'her sabah',
  'herakşam': 'her akşam',
  'herhafta': 'her hafta',
  'heray': 'her ay',
  'heryıl': 'her yıl',
  'herdefa': 'her defa',
  'herseferinde': 'her seferinde',
  'herzamanki': 'her zamanki',
  'hergünkü': 'her günkü',
  'herneyse': 'her neyse',
  'herhangibir': 'herhangi bir',
  'herhangibiri': 'herhangi biri',
  'herkeze': 'herkese',
  'herkezin': 'herkesin',
  'herkezi': 'herkesi',
  'herkezden': 'herkesten',
  'okadar': 'o kadar',
  'bukadar': 'bu kadar',
  'şukadar': 'şu kadar',
  'nekadar': 'ne kadar',
  'nezaman': 'ne zaman',
  'neoldu': 'ne oldu',
  'nevar': 'ne var',
  'nediyorsun': 'ne diyorsun',
  'nedemek': 'ne demek',
  'neyapıyorsun': 'ne yapıyorsun',
  'neyapalım': 'ne yapalım',
  'neyapayım': 'ne yapayım',
  'naptın': 'ne yaptın',
  'napıyosun': 'ne yapıyorsun',
  'napıcam': 'ne yapacağım',
  'napcam': 'ne yapacağım',
  'napıcaz': 'ne yapacağız',
  'napalım': 'ne yapalım',
  'nebilim': 'ne bileyim',
  'nebileyim': 'ne bileyim',
  'kimbilir': 'kim bilir',
  'öbürgün': 'öbür gün',
  'şuanki': 'şu anki',
  'şuanlık': 'şu anlık',
  'şuana': 'şu ana',
  'şuandan': 'şu andan',
  'haftaiçi': 'hafta içi',
  'haftasonu': 'hafta sonu',
  'haftasonları': 'hafta sonları',
  'aysonu': 'ay sonu',
  'yılsonu': 'yıl sonu',
  // Kalıp sözler.
  'hoşgeldin': 'hoş geldin',
  'hoşgeldiniz': 'hoş geldiniz',
  'hoşbulduk': 'hoş bulduk',
  'hoşçakalın': 'hoşça kalın',
  'sağol': 'sağ ol',
  'sağolun': 'sağ olun',
  'sağolsun': 'sağ olsun',
  'sağolasın': 'sağ olasın',
  'kolaygelsin': 'kolay gelsin',
  'geçmişolsun': 'geçmiş olsun',
  'afiyetolsun': 'afiyet olsun',
  'iyiakşamlar': 'iyi akşamlar',
  'iyigeceler': 'iyi geceler',
  'iyigünler': 'iyi günler',
  'iyiyolculuklar': 'iyi yolculuklar',
  'iyiçalışmalar': 'iyi çalışmalar',
  'teşekkürederim': 'teşekkür ederim',
  'teşekkürediyorum': 'teşekkür ediyorum',
  'ricaederim': 'rica ederim',
  'özürdilerim': 'özür dilerim',
  'meraketme': 'merak etme',
  'kusurabakma': 'kusura bakma',
  // Bitişik "de/da" ve "ki".
  'hemde': 'hem de',
  'genede': 'gene de',
  'veyada': 'veya da',
  'şimdide': 'şimdi de',
  'bazende': 'bazen de',
  'gibide': 'gibi de',
  'gerçektende': 'gerçekten de',
  'bunuda': 'bunu da',
  'onuda': 'onu da',
  'şunuda': 'şunu da',
  'benide': 'beni de',
  'senide': 'seni de',
  'onada': 'ona da',
  'banada': 'bana da',
  'sanada': 'sana da',
  'bizede': 'bize de',
  'sizede': 'size de',
  'yokda': 'yok da',
  'demekki': 'demek ki',
  'iyiki': 'iyi ki',
  'öyleki': 'öyle ki',
  'şöyleki': 'şöyle ki',
  'yeterki': 'yeter ki',
  'dediki': 'dedi ki',
  'diyorki': 'diyor ki',
  'tabiiki': 'tabii ki',
  'neyseki': 'neyse ki',
  'biliyorumki': 'biliyorum ki',
  'düşünüyorumki': 'düşünüyorum ki',
  'görüyorumki': 'görüyorum ki',
  'sanıyorumki': 'sanıyorum ki',
  'umarımki': 'umarım ki',
  'eminimki': 'eminim ki',
  'anladımki': 'anladım ki',
  'gördümki': 'gördüm ki',
  'baktımki': 'baktım ki',
  'çünki': 'çünkü',
  // Bitişik soru eki (genel kural [questionSplit]; sık olanlar açıkça).
  'olurmu': 'olur mu',
  'varmı': 'var mı',
  'yokmu': 'yok mu',
  'değilmi': 'değil mi',
  'deilmi': 'değil mi',
  'diilmi': 'değil mi',
  'tamammı': 'tamam mı',
  'öylemi': 'öyle mi',
  'geldimi': 'geldi mi',
  'bittimi': 'bitti mi',
  'oldumu': 'oldu mu',
  'doğrumu': 'doğru mu',
  'iyimi': 'iyi mi',
  'hazırmı': 'hazır mı',
  'güzelmi': 'güzel mi',
  'mümkünmü': 'mümkün mü',
  'nasılmı': 'nasıl mı',
  'gerekiyormu': 'gerekiyor mu',
  'gördünmü': 'gördün mü',
  'duydunmu': 'duydun mu',
  'yaptınmı': 'yaptın mı',
  'aldınmı': 'aldın mı',
  'geldinmi': 'geldin mi',
  'gittinmi': 'gittin mi',
  'anladınmı': 'anladın mı',
  'gelecekmi': 'gelecek mi',
  'olacakmı': 'olacak mı',
  'varmıydı': 'var mıydı',
  'yokmuydu': 'yok muydu',
  'bumu': 'bu mu',
  'şumu': 'şu mu',
  'omu': 'o mu',
  'benmi': 'ben mi',
  'senmi': 'sen mi',
  'bizmi': 'biz mi',
  'sizmi': 'siz mi',
  'onlarmı': 'onlar mı',
  // "değil" ağızları.
  'deil': 'değil',
  'diyil': 'değil',
  'deilim': 'değilim',
  'diilim': 'değilim',
  // Sık yanlış yazılan kelimeler.
  'acaip': 'acayip',
  'ahçı': 'aşçı',
  'alalade': 'alelade',
  'ambülans': 'ambulans',
  'aperatif': 'aperitif',
  'apartıman': 'apartman',
  'ameliyet': 'ameliyat',
  'antranör': 'antrenör',
  'arbade': 'arbede',
  'atelye': 'atölye',
  'avokat': 'avukat',
  'ayakabı': 'ayakkabı',
  'ayrıyeten': 'ayrıca',
  'ayrıyetten': 'ayrıca',
  'aydat': 'aidat',
  'bezelya': 'bezelye',
  'bilgisiyar': 'bilgisayar',
  'bilimum': 'bilumum',
  'birlikde': 'birlikte',
  'büsküvi': 'bisküvi',
  'çukulata': 'çikolata',
  'çikulata': 'çikolata',
  'cimnastik': 'jimnastik',
  'cumuriyet': 'cumhuriyet',
  'cüsdan': 'cüzdan',
  'çamışır': 'çamaşır',
  'çerçive': 'çerçeve',
  'cilet': 'jilet',
  'dedorant': 'deodorant',
  'detarjan': 'deterjan',
  'deterjen': 'deterjan',
  'dinazor': 'dinozor',
  'döküman': 'doküman',
  'domatez': 'domates',
  'eczahane': 'eczane',
  'egzos': 'egzoz',
  'eksoz': 'egzoz',
  'eksersiz': 'egzersiz',
  'eylence': 'eğlence',
  'elbete': 'elbette',
  'elektirik': 'elektrik',
  'emflasyon': 'enflasyon',
  'entellektüel': 'entelektüel',
  'enterasan': 'enteresan',
  'interesan': 'enteresan',
  'fanile': 'fanila',
  'fasülye': 'fasulye',
  'fermüar': 'fermuar',
  'ferribot': 'feribot',
  'filitre': 'filtre',
  'fotoraf': 'fotoğraf',
  'fütbol': 'futbol',
  'gardrop': 'gardırop',
  'gerçekden': 'gerçekten',
  'hakkaten': 'hakikaten',
  'hakketen': 'hakikaten',
  'hastahane': 'hastane',
  'istasiyon': 'istasyon',
  'kahfaltı': 'kahvaltı',
  'kavaltı': 'kahvaltı',
  'kahfe': 'kahve',
  'karnıbahar': 'karnabahar',
  'katolog': 'katalog',
  'kılasör': 'klasör',
  'komedin': 'komidin',
  'kordinasyon': 'koordinasyon',
  'kordinatör': 'koordinatör',
  'karavat': 'kravat',
  'kuafor': 'kuaför',
  'kütüpane': 'kütüphane',
  'laboratuar': 'laboratuvar',
  'mağza': 'mağaza',
  'makina': 'makine',
  'malasef': 'maalesef',
  'maalasef': 'maalesef',
  'mayanez': 'mayonez',
  'maydonoz': 'maydanoz',
  'meşkul': 'meşgul',
  'meyvası': 'meyvesi',
  'meyvalar': 'meyveler',
  'meyvayı': 'meyveyi',
  'mönü': 'menü',
  'motorsiklet': 'motosiklet',
  'mozayik': 'mozaik',
  'muayne': 'muayene',
  'muhayene': 'muayene',
  'muhakak': 'muhakkak',
  'nargila': 'nargile',
  'pahallı': 'pahalı',
  'pantalon': 'pantolon',
  'parföm': 'parfüm',
  'pisikoloji': 'psikoloji',
  'pisikolog': 'psikolog',
  'profösör': 'profesör',
  'proğram': 'program',
  'prosödür': 'prosedür',
  'rağman': 'rağmen',
  'randevü': 'randevu',
  'restorant': 'restoran',
  'rezarvasyon': 'rezervasyon',
  'salatlık': 'salatalık',
  'sandaviç': 'sandviç',
  'sandiviç': 'sandviç',
  'sandelye': 'sandalye',
  'sikorta': 'sigorta',
  'stajer': 'stajyer',
  'şarz': 'şarj',
  'şöför': 'şoför',
  'tamamiyle': 'tamamıyla',
  'televüzyon': 'televizyon',
  'teşekür': 'teşekkür',
  'teşekürler': 'teşekkürler',
  'teşşekür': 'teşekkür',
  'tirbüşon': 'tirbuşon',
  'tiren': 'tren',
  'tualet': 'tuvalet',
  'ünüversite': 'üniversite',
  'vantülatör': 'vantilatör',
  'vejeteryan': 'vejetaryen',
  'yalnışlıkla': 'yanlışlıkla',
  'yanlızlık': 'yalnızlık',
  'yourt': 'yoğurt',
};

/// **BAĞLAMA BAĞLI** yanlışlar (Y-3): anahtar başka anlamda DOĞRU yazımdır
/// ("bende var" / "ben de geldim", "oda" / "o da"). Otomatik UYGULANMAZ;
/// yalnız altı çizili denetimde öneri olarak çıkar (17K §3.3: yanlış
/// düzeltme güveni yok eder).
const kContextFixes = <String, String>{
  'bende': 'ben de',
  'sende': 'sen de',
  'oda': 'o da',
  'bizde': 'biz de',
  'sizde': 'siz de',
  'onlarda': 'onlar da',
  'bunlarda': 'bunlar da',
  'sonrada': 'sonra da',
  'öncede': 'önce de',
  'bugünde': 'bugün de',
  'yarında': 'yarın da',
  'dünde': 'dün de',
  'birde': 'bir de',
  'kimde': 'kim de',
  'nede': 'ne de',
  'tabi': 'tabii',
  'hala': 'hâlâ',
  'demi': 'de mi',
  'dami': 'da mı',
  'yanı': 'yani',
  'bi': 'bir',
  'nerde': 'nerede',
  'burda': 'burada',
  'orda': 'orada',
  'şurda': 'şurada',
  'nası': 'nasıl',
  'sora': 'sonra',
  'şöle': 'şöyle',
  'böle': 'böyle',
  'öle': 'öyle',
  'naber': 'ne haber',
};

/// Bağlama bağlı öneri (küçük harf); yoksa null.
String? contextualFix(String w) => kContextFixes[w];

const _questionSuffixes = [
  'misiniz', 'mısınız', 'musunuz', 'müsünüz', //
  'miyiz', 'mıyız', 'muyuz', 'müyüz', //
  'misin', 'mısın', 'musun', 'müsün', //
  'miyim', 'mıyım', 'muyum', 'müyüm', //
  'midir', 'mıdır', 'mudur', 'müdür',
];

final _letters = RegExp(r'[\p{L}]+$', unicode: true);

/// Tek kelimenin düzeltilmiş hâli (değişiklik yoksa aynısı). Büyük harfle
/// başlayan kelimenin baş harfi korunur; tamamı büyükse dokunulmaz (kısaltma).
String fixTurkishWord(String word) {
  if (word.length < 2 || trUpper(word) == word) return word;
  final cap = word[0] != word[0].toLowerCase();
  var w = cap ? word[0].toLowerCase() + word.substring(1) : word;
  final common = _common[w];
  if (common != null) {
    w = common;
  } else if (RegExp(r'(iyo|ıyo|uyo|üyo)$').hasMatch(w) && w.length > 4) {
    w = '${w}r';
  } else {
    for (final s in _questionSuffixes) {
      if (w.length >= s.length + 3 && w.endsWith(s)) {
        w = '${w.substring(0, w.length - s.length)} $s';
        break;
      }
    }
  }
  return cap ? _trCapitalize(w) : w;
}

/// Cümle başı mı: [start] öncesinde yalnız boşluk varsa ve ondan önce satır
/// başı ya da . ! ? geliyorsa.
bool _sentenceStart(String text, int start) {
  var i = start - 1;
  while (i >= 0 && text[i] == ' ') {
    i--;
  }
  if (i < 0) return true;
  return '\n.!?'.contains(text[i]);
}

/// Kullanıcı [caret]'ten hemen önce bir sınır karakteri (boşluk, noktalama,
/// satır sonu) yazdı: önündeki kelime ve noktalama düzeltilir. Değişiklik
/// yoksa null; varsa [start, end) aralığı [text] ile değişir. [fixWord]:
/// kelime kuralı (yazım motoru kelimeye kendisi karar verince kimlik işlevi).
({int start, int end, String text})? spellFixAt(
  String text,
  int caret, {
  String Function(String) fixWord = fixTurkishWord,
}) {
  if (caret < 2 || caret > text.length) return null;
  final boundary = text[caret - 1];
  if (!' \n.,;:!?'.contains(boundary)) return null;
  // "kelime ," → "kelime,"
  var spaceBefore = false;
  var wordEnd = caret - 1;
  if (',.;:!?'.contains(boundary) && text[caret - 2] == ' ') {
    spaceBefore = true;
    wordEnd = caret - 2;
  }
  final m = _letters.firstMatch(text.substring(0, wordEnd));
  if (m == null) {
    return spaceBefore
        ? (start: caret - 2, end: caret, text: boundary)
        : null;
  }
  final start = m.start;
  // Bağlantı, e-posta, sayıya yapışık kelime: dokunma (önünde boşluk, satır
  // başı, açılan tırnak/parantez ya da biçim işareti olmalı).
  final before = start == 0 ? ' ' : text[start - 1];
  if (!' \n("\'«“*_~='.contains(before)) {
    return spaceBefore
        ? (start: caret - 2, end: caret, text: boundary)
        : null;
  }
  final word = m.group(0)!;
  var fixed = fixWord(word);
  if (_sentenceStart(text, start)) fixed = _trCapitalize(fixed);
  if (fixed == word && !spaceBefore) return null;
  return (start: start, end: caret, text: fixed + boundary);
}

/// Satır/madde bitti (Enter, yeni madde): baş harf büyük, en az üç kelimelik
/// ve harfle biten satırın sonuna nokta.
String finalizeLine(String line) {
  final t = line.trimRight();
  if (t.isEmpty) return line;
  var out = t;
  final lead = RegExp(r'^(\s*)([\p{Ll}])', unicode: true).firstMatch(out);
  if (lead != null) {
    out = out.replaceRange(lead.start + lead.group(1)!.length, lead.end,
        trUpper(lead.group(2)!));
  }
  final words = out.trim().split(RegExp(r'\s+')).length;
  if (words >= 3 && RegExp(r'\p{L}$', unicode: true).hasMatch(out)) {
    out = '$out.';
  }
  return out + line.substring(t.length);
}

/// BAŞLIK düzeltmesi (kullanıcı isteği 2026-11-08: "başlıklarda AI'sız oto
/// düzeltme — kelimelerin ilk harfi büyür"): [spellFixAt] kuralları + biten
/// kelimenin baş harfi büyük (Türkçe i → İ). Tamamı büyük kelime (kısaltma)
/// ve bağlantı/e-posta parçası olduğu gibi kalır.
({int start, int end, String text})? titleFixAt(
  String text,
  int caret, {
  String Function(String) fixWord = fixTurkishWord,
}) {
  final base = spellFixAt(text, caret, fixWord: fixWord);
  var t = text;
  var c = caret;
  if (base != null) {
    t = text.replaceRange(base.start, base.end, base.text);
    c = base.start + base.text.length;
  }
  if (c < 2) return base;
  final boundary = t[c - 1];
  if (!' \n.,;:!?'.contains(boundary)) return base;
  var i = c - 1;
  if (',.;:!?'.contains(boundary) && i > 0 && t[i - 1] == ' ') i--;
  final end = i;
  final letter = RegExp(r'\p{L}', unicode: true);
  while (i > 0 && letter.hasMatch(t[i - 1])) {
    i--;
  }
  if (i == end) return base;
  final before = i == 0 ? ' ' : t[i - 1];
  if (!' \n("\'«“*_~='.contains(before)) return base;
  final first = t[i];
  final up = trUpper(first);
  if (up == first) return base;
  final from = base?.start ?? i;
  final out = t.replaceRange(i, i + 1, up);
  final start = from < i ? from : i;
  final endOut = c;
  return (
    start: start,
    end: start + (text.length - out.length) + (endOut - start),
    text: out.substring(start, endOut),
  );
}
