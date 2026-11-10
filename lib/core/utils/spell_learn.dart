/// **KİŞİSEL YAZIM HAFIZASI v2** (Faz 70). Saf Dart; kararı
/// `spell_engine.dart` verir, bu dosya yalnız VERİYİ tutar:
///
/// * [SpellMemory.words]: kullanıcının yazdığı kelimeler (sıklık); notlardan
///   gelen sözlük [SpellMemory.seeded] (kaydedilmez). Üç kez görülen kelime
///   "bilinir" ve otomatik düzeltilmez.
/// * [SpellMemory.fixes]: kullanıcının öğrettiği `yanlış → doğru`; iki kez
///   görülünce (ya da elle eklenince / otomatik düzeltmenin yerine yazılınca)
///   uygulanır.
/// * [SpellMemory.rejected]: kullanıcının geri aldığı ya da değiştirdiği
///   OTOMATİK düzeltme çiftleri (`yazılan>düzeltilen`) — bir daha uygulanmaz.
/// * [SpellMemory.keep]: hiç düzeltilmeyecek kelimeler (v1'in "geri alınan"
///   listesi buraya taşınır).
///
/// v1 dosyası ("c" harf karışıklıkları, sayaçlı düzeltmeler) [SpellMemory.decode]'da
/// göçer; karışıklık ağırlıkları atılır.
library;

import 'dart:convert';
import 'dart:math' as math;

/// Kelime Han yazısı mı (Çince: bulanık düzeltme yok).
bool isCjk(String w) => RegExp(r'\p{Script=Han}', unicode: true).hasMatch(w);

/// Kelime İngilizce mi görünüyor — cihaz denetçisinin dili için.
bool looksEnglish(String w) {
  final l = w.toLowerCase();
  if (RegExp('[çğıöşü]').hasMatch(l)) return false;
  if (!RegExp(r'^[a-z]+$').hasMatch(l)) return false;
  if (kCommonEnglish.contains(l)) return true;
  return RegExp(r'(w|q|x|th|ee|oo|ck|sh|ght|tion)').hasMatch(l);
}

/// Türkçe küçük harf (I → ı, İ → i).
String trLower(String s) =>
    s.replaceAll('I', 'ı').replaceAll('İ', 'i').toLowerCase();

class SpellMemory {
  SpellMemory();

  static const maxWords = 5000;
  static const maxFixes = 600;

  /// Kelime → görülme sayısı (küçük harf).
  final Map<String, int> words = {};

  /// Yanlış → (doğru, kaç kez).
  final Map<String, (String, int)> fixes = {};

  /// Reddedilen otomatik düzeltmeler: `yazılan>düzeltilen` (küçük harf).
  final Set<String> rejected = {};

  /// Hiç düzeltilmeyecek kelimeler (küçük harf).
  final Set<String> keep = {};

  /// Notlardan gelen sözlük (kaydedilmez, her açılışta yeniden kurulur).
  final Map<String, int> seeded = {};

  /// v1 dosyasından göçtü mü (yükleyen eskisini `.v1` olarak saklar).
  bool fromV1 = false;

  Map<int, List<String>>? _byLength;

  bool get isEmpty =>
      words.isEmpty && fixes.isEmpty && rejected.isEmpty && keep.isEmpty;

  int get learnedCount => fixes.length;

  /// Kelimenin toplam sıklığı (yazılan + notlardaki + yerleşik).
  int frequency(String w) {
    final l = trLower(w);
    var n = (words[l] ?? 0) + (seeded[l] ?? 0);
    if (kCommonTurkish.contains(l) || kCommonEnglish.contains(l)) n += 3;
    return n;
  }

  /// Bilinen kelime: dokunulmaz. Yalnız yazılmış kelime üç kez görülünce
  /// bilinir — iki kez aynı yazım hatası sözlüğe girmesin.
  bool known(String w) => frequency(w) >= 3 || keep.contains(trLower(w));

  void addWord(String w, [int by = 1]) {
    final l = trLower(w);
    if (l.length < 2 || l.length > 30) return;
    final had = words.containsKey(l);
    words[l] = (words[l] ?? 0) + by;
    if (!had) _byLength = null;
    if (words.length > maxWords) _pruneWords();
  }

  void _pruneWords() {
    final sorted = words.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    for (final e in sorted.take(words.length - maxWords * 3 ~/ 4)) {
      words.remove(e.key);
    }
    _byLength = null;
  }

  /// Notların metninden sözlük ([seedCounts] arka planda sayar).
  void seed(Map<String, int> counts) {
    seeded
      ..clear()
      ..addAll(counts);
    _byLength = null;
  }

  /// Uzunluğu [len] olan bütün sözlük kelimeleri (bulanık arama kovası).
  List<String> bucket(int len) {
    final byLen = _byLength ??= () {
      final m = <int, List<String>>{};
      final all = <String>{
        ...words.keys,
        ...seeded.keys,
        ...kCommonTurkish,
        ...kCommonEnglish,
      };
      for (final w in all) {
        m.putIfAbsent(w.length, () => []).add(w);
      }
      return m;
    }();
    return byLen[len] ?? const [];
  }

  /// Uygulanacak öğretilmiş düzeltme (iki kez görülen ya da onaylanan).
  String? learned(String from) {
    final f = fixes[trLower(from)];
    return f != null && f.$2 >= 2 ? f.$1 : null;
  }

  /// Kullanıcı [from] yazıp kendisi [to] yaptı. [confirmed]: tek seferde
  /// uygulanacak kadar açık (elle eklendi ya da otomatik düzeltmenin yerine
  /// yazıldı). Başka bir doğru öğrenilirse eskisinin yerine geçer.
  void learnFix(String from, String to, {bool confirmed = false}) {
    final f = trLower(from.trim());
    final t = to.trim();
    if (f.isEmpty || t.isEmpty || f == trLower(t)) return;
    rejected.remove('$f>${trLower(t)}');
    keep.remove(f);
    final old = fixes[f];
    final n = old != null && old.$1 == t ? old.$2 + 1 : 1;
    fixes[f] = (t, confirmed ? math.max(n, 2) : n);
    if (fixes.length > maxFixes) {
      final weakest = fixes.entries.reduce(
        (a, b) => a.value.$2 <= b.value.$2 ? a : b,
      );
      fixes.remove(weakest.key);
    }
    for (final w in t.split(' ')) {
      addWord(w);
    }
  }

  /// ELLE EKLENEN düzeltme (Ayarlar → Öğrenilen yazımlar): ilk görüşte
  /// uygulanır.
  void addManualFix(String from, String to) {
    learnFix(from, to, confirmed: true);
    for (final w in to.trim().split(' ')) {
      addWord(w, 2);
    }
  }

  void removeFix(String from) => fixes.remove(trLower(from));

  /// Ayarlar listesi: sık olan önce.
  List<({String from, String to, int count})> fixList() => [
    for (final e in fixes.entries)
      (from: e.key, to: e.value.$1, count: e.value.$2),
  ]..sort((a, b) => b.count.compareTo(a.count));

  /// Otomatik [from] → [to] düzeltmesi reddedildi (geri alındı ya da
  /// kullanıcı değiştirdi): bir daha uygulanmaz.
  void rejectPair(String from, String to) {
    final f = trLower(from);
    final t = trLower(to);
    rejected.add('$f>$t');
    final fix = fixes[f];
    if (fix != null && trLower(fix.$1) == t) fixes.remove(f);
    if (rejected.length > maxFixes) rejected.remove(rejected.first);
  }

  bool isRejected(String from, String to) =>
      rejected.contains('${trLower(from)}>${trLower(to)}');

  /// Ayarlardan: reddedilen çifti (`a>b`) ya da dokunulmaz kelimeyi
  /// yeniden açar.
  void unreject(String key) {
    rejected.remove(key);
    keep.remove(key);
  }

  Map<String, Object?> toJson() => {
    'v': 2,
    'w': words,
    'f': {
      for (final e in fixes.entries) e.key: [e.value.$1, e.value.$2],
    },
    'r': rejected.toList(),
    'k': keep.toList(),
  };

  String encode() => jsonEncode(toJson());

  /// v2 ya da v1 dosyası; bozuksa boş hafıza.
  static SpellMemory decode(String? raw) {
    final m = SpellMemory();
    if (raw == null || raw.isEmpty) return m;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      (j['w'] as Map?)?.forEach((k, v) => m.words['$k'] = (v as num).toInt());
      if (j['v'] == 2) {
        (j['f'] as Map?)?.forEach((k, v) {
          final l = v as List;
          m.fixes['$k'] = ('${l[0]}', (l[1] as num).toInt());
        });
        for (final r in (j['r'] as List?) ?? const []) {
          m.rejected.add('$r');
        }
        for (final r in (j['k'] as List?) ?? const []) {
          m.keep.add('$r');
        }
      } else {
        // v1: {yanlış: {doğru: sayı}} → en güçlü doğru; "r" (geri alınan
        // kelimeler) → keep; "c" (harf karışıklıkları) atılır.
        m.fromV1 = true;
        (j['f'] as Map?)?.forEach((k, v) {
          String? to;
          var n = 0;
          (v as Map).forEach((t, c) {
            if ((c as num).toInt() > n) (to, n) = ('$t', c.toInt());
          });
          if (to != null) m.fixes['$k'] = (to!, n);
        });
        for (final r in (j['r'] as List?) ?? const []) {
          m.keep.add('$r');
        }
      }
    } catch (_) {
      // Bozuk dosya: boş hafızayla devam.
      return SpellMemory();
    }
    return m;
  }
}

/// Metinlerden kelime sayımı (notlardan sözlük). Arka planda (`compute`)
/// koşacak kadar saf; en çok [limit] kelime tutulur.
Map<String, int> seedCounts(List<String> texts, {int limit = 8000}) {
  final counts = <String, int>{};
  final re = RegExp(r'[\p{L}]{2,30}', unicode: true);
  var chars = 0;
  for (final t in texts) {
    chars += t.length;
    if (chars > 3000000) break; // 3 MB üstü: yeter.
    for (final m in re.allMatches(t)) {
      final w = trLower(m.group(0)!);
      if (isCjk(w) && w.length > 4) continue;
      counts[w] = (counts[w] ?? 0) + 1;
    }
  }
  if (counts.length <= limit) return counts;
  final sorted = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return Map.fromEntries(sorted.take(limit));
}

/// Yerleşik sık Türkçe kelimeler (başlangıç sözlüğü — kişisel sözlük
/// büyüdükçe önemi azalır).
const kCommonTurkish = <String>{
  'acaba',
  'açık',
  'ad',
  'adres',
  'ağaç',
  'ahmet',
  'akşam',
  'al',
  'alan',
  'alarm',
  'alındı',
  'alış',
  'alışveriş',
  'altı',
  'altında',
  'ama',
  'amaç',
  'an',
  'ana',
  'anahtar',
  'anda',
  'anne',
  'ara',
  'araba',
  'arada',
  'aralık',
  'arasında',
  'arkadaş',
  'artık',
  'aslında',
  'ay',
  'aynı',
  'az',
  'baba',
  'bakım',
  'bakmak',
  'banka',
  'bana',
  'bazen',
  'bazı',
  'başka',
  'başla',
  'başladı',
  'başlık',
  'bekle',
  'belge',
  'ben',
  'benim',
  'beni',
  'bile',
  'bilgi',
  'bilgisayar',
  'bir',
  'biraz',
  'birlikte',
  'bitti',
  'biz',
  'bize',
  'bizim',
  'boş',
  'bu',
  'bugün',
  'bunu',
  'bunlar',
  'burada',
  'büyük',
  'cuma',
  'cumartesi',
  'çalış',
  'çalışıyor',
  'çalışma',
  'çarşamba',
  'çay',
  'çek',
  'çekme',
  'çık',
  'çocuk',
  'çok',
  'çünkü',
  'da',
  'daha',
  'dakika',
  'de',
  'değil',
  'değişti',
  'defter',
  'devam',
  'diğer',
  'diye',
  'doğru',
  'dosya',
  'dolayı',
  'durum',
  'düzelt',
  'düzeltme',
  'düzeltmeler',
  'ekmek',
  'eksik',
  'ekle',
  'eklendi',
  'el',
  'en',
  'erken',
  'eski',
  'et',
  'ev',
  'evet',
  'fakat',
  'fatura',
  'fazla',
  'fiyat',
  'gece',
  'geç',
  'gel',
  'geldi',
  'gelecek',
  'geliyor',
  'gelir',
  'gerek',
  'gerekiyor',
  'geri',
  'git',
  'gitti',
  'gibi',
  'gidiyor',
  'göre',
  'görev',
  'gör',
  'gün',
  'güncel',
  'güzel',
  'hafta',
  'hala',
  'hangi',
  'hasta',
  'hatırla',
  'hatırlatma',
  'hava',
  'hayır',
  'hazır',
  'hem',
  'hemen',
  'hep',
  'her',
  'hesap',
  'hızlı',
  'hiç',
  'için',
  'içinde',
  'iki',
  'ile',
  'ilk',
  'iptal',
  'iş',
  'işte',
  'iste',
  'istiyor',
  'iyi',
  'kadar',
  'kağıt',
  'kalan',
  'kalem',
  'kapı',
  'kaydet',
  'kayıt',
  'kendi',
  'kez',
  'kim',
  'kitap',
  'kolay',
  'kolu',
  'kontrol',
  'kötü',
  'kullan',
  'kullanıcı',
  'liste',
  'madde',
  'mail',
  'market',
  'mesaj',
  'mı',
  'mi',
  'mu',
  'mü',
  'nasıl',
  'ne',
  'neden',
  'nerede',
  'not',
  'notlar',
  'o',
  'oda',
  'okul',
  'olan',
  'olarak',
  'olacak',
  'oldu',
  'olmalı',
  'olsun',
  'on',
  'once',
  'onu',
  'onlar',
  'orada',
  'otomatik',
  'ödeme',
  'önce',
  'önemli',
  'öyle',
  'para',
  'pazar',
  'pazartesi',
  'perşembe',
  'proje',
  'randevu',
  'saat',
  'sabah',
  'sadece',
  'salı',
  'sağa',
  'sana',
  'sanki',
  'sen',
  'sende',
  'senin',
  'sev',
  'sil',
  'sipariş',
  'sonra',
  'son',
  'sorun',
  'su',
  'süt',
  'şey',
  'şimdi',
  'şu',
  'tablo',
  'tamam',
  'tam',
  'tarih',
  'telefon',
  'toplantı',
  'tüm',
  'uygulama',
  'uzun',
  've',
  'var',
  'veya',
  'ver',
  'yalnız',
  'yani',
  'yap',
  'yapıldı',
  'yapılıyor',
  'yapılacak',
  'yapıyor',
  'yapmak',
  'yarın',
  'yaz',
  'yazı',
  'yazılım',
  'yazım',
  'yemek',
  'yeni',
  'yer',
  'yeter',
  'yeterli',
  'yine',
  'yok',
  'yol',
  'yorum',
  'yukarı',
  'zaman',
  'zor',
};

/// Yerleşik sık İngilizce kelimeler.
const kCommonEnglish = <String>{
  'about',
  'after',
  'again',
  'all',
  'also',
  'always',
  'and',
  'any',
  'are',
  'back',
  'because',
  'been',
  'before',
  'being',
  'best',
  'better',
  'book',
  'both',
  'but',
  'buy',
  'call',
  'can',
  'check',
  'come',
  'could',
  'day',
  'did',
  'does',
  'done',
  'down',
  'each',
  'email',
  'even',
  'every',
  'file',
  'find',
  'first',
  'fix',
  'for',
  'from',
  'get',
  'give',
  'good',
  'great',
  'had',
  'has',
  'have',
  'help',
  'her',
  'here',
  'him',
  'his',
  'home',
  'how',
  'idea',
  'into',
  'just',
  'know',
  'last',
  'later',
  'like',
  'list',
  'little',
  'long',
  'look',
  'make',
  'many',
  'meeting',
  'more',
  'most',
  'much',
  'must',
  'need',
  'never',
  'new',
  'next',
  'not',
  'note',
  'notes',
  'now',
  'only',
  'other',
  'our',
  'out',
  'over',
  'people',
  'please',
  'project',
  'read',
  'really',
  'remember',
  'right',
  'same',
  'say',
  'see',
  'send',
  'should',
  'some',
  'something',
  'still',
  'such',
  'take',
  'task',
  'than',
  'thank',
  'thanks',
  'that',
  'the',
  'their',
  'them',
  'then',
  'there',
  'these',
  'they',
  'thing',
  'things',
  'think',
  'this',
  'those',
  'time',
  'today',
  'tomorrow',
  'two',
  'under',
  'until',
  'update',
  'use',
  'very',
  'want',
  'was',
  'way',
  'week',
  'well',
  'were',
  'what',
  'when',
  'where',
  'which',
  'while',
  'who',
  'why',
  'will',
  'with',
  'work',
  'would',
  'write',
  'year',
  'yes',
  'you',
  'your',
};
