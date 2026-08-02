/// Dil kodu → dilin KENDİ yazımıyla adı.
///
/// Neden kendi yazımıyla: Japonca konuşan biri listede "Japanese" değil
/// "日本語" arar. Uygulamanın o anki dili ne olursa olsun kullanıcı kendi
/// dilini tanıyabilmeli.
///
/// ⚠️ **SINIR — buraya rastgele dil eklenemez.** Flutter'ın hazır
/// `GlobalMaterialLocalizations`/`GlobalCupertinoLocalizations` çevirileri
/// olmayan bir yerel ayar eklenirse uygulama o dilde ÇALIŞMA ANINDA hata
/// verir (tarih seçici, metin seçim menüsü gibi yerleşik bileşenlerin metni
/// yoktur). Aşağıdaki liste bilerek Flutter'ın desteklediği kümeyle sınırlı.
/// Ötesine geçmek, Material/Cupertino için elle `LocalizationsDelegate`
/// yazmak demektir — ayrı ve büyük bir iş.
///
/// Bu harita ARB dosyalarından BAĞIMSIZDIR: burada bir dilin bulunması onu
/// desteklenen yapmaz. Desteklenen diller tek kaynaktan gelir —
/// `AppLocalizations.supportedLocales`, yani `lib/l10n/*.arb` dosyaları
/// (bkz. `supportedLanguages`). Burası yalnızca "adı ne yazılacak" sorusunu
/// yanıtlar; çevirisi üretilmemiş bir dil listede hiç görünmez.
library;

const languageNames = <String, String>{
  'af': 'Afrikaans',
  'am': 'አማርኛ',
  'ar': 'العربية',
  'as': 'অসমীয়া',
  'az': 'Azərbaycanca',
  'be': 'Беларуская',
  'bg': 'Български',
  'bn': 'বাংলা',
  'bs': 'Bosanski',
  'ca': 'Català',
  'cs': 'Čeština',
  'cy': 'Cymraeg',
  'da': 'Dansk',
  'de': 'Deutsch',
  'el': 'Ελληνικά',
  'en': 'English',
  'es': 'Español',
  'et': 'Eesti',
  'eu': 'Euskara',
  'fa': 'فارسی',
  'fi': 'Suomi',
  'fil': 'Filipino',
  'fr': 'Français',
  'gl': 'Galego',
  'gsw': 'Schwiizerdütsch',
  'gu': 'ગુજરાતી',
  'he': 'עברית',
  'hi': 'हिन्दी',
  'hr': 'Hrvatski',
  'hu': 'Magyar',
  'hy': 'Հայերեն',
  'id': 'Bahasa Indonesia',
  'is': 'Íslenska',
  'it': 'Italiano',
  'ja': '日本語',
  'ka': 'ქართული',
  'kk': 'Қазақша',
  'km': 'ខ្មែរ',
  'kn': 'ಕನ್ನಡ',
  'ko': '한국어',
  'ky': 'Кыргызча',
  'lo': 'ລາວ',
  'lt': 'Lietuvių',
  'lv': 'Latviešu',
  'mk': 'Македонски',
  'ml': 'മലയാളം',
  'mn': 'Монгол',
  'mr': 'मराठी',
  'ms': 'Bahasa Melayu',
  'my': 'မြန်မာ',
  'nb': 'Norsk bokmål',
  'ne': 'नेपाली',
  'nl': 'Nederlands',
  'no': 'Norsk',
  'or': 'ଓଡ଼ିଆ',
  'pa': 'ਪੰਜਾਬੀ',
  'pl': 'Polski',
  'ps': 'پښتو',
  'pt': 'Português',
  'ro': 'Română',
  'ru': 'Русский',
  'si': 'සිංහල',
  'sk': 'Slovenčina',
  'sl': 'Slovenščina',
  'sq': 'Shqip',
  'sr': 'Српски',
  'sv': 'Svenska',
  'sw': 'Kiswahili',
  'ta': 'தமிழ்',
  'te': 'తెలుగు',
  'th': 'ไทย',
  'tl': 'Tagalog',
  'tr': 'Türkçe',
  'uk': 'Українська',
  'ur': 'اردو',
  'uz': 'Oʻzbekcha',
  'vi': 'Tiếng Việt',
  'zh': '中文',
  'zu': 'IsiZulu',
};

/// Sağdan sola yazılan diller. Flutter yönü yerel ayardan kendisi çıkarır;
/// bu liste, RTL'ye özel davranması gereken yerler (ör. elle çizilen tuval
/// yerleşimleri) için gerekir.
const rtlLanguages = <String>{'ar', 'fa', 'he', 'ps', 'ur'};

/// Bölge varyantı olan kodlarda ('pt_BR') taban dili döndürür.
String baseLanguage(String code) =>
    code.split(RegExp('[_-]')).first.toLowerCase();

/// [code] için görünen ad; katalogda yoksa kodun kendisi (liste hiç boş
/// satır göstermez).
String languageLabel(String code) =>
    languageNames[code] ?? languageNames[baseLanguage(code)] ?? code;
