/// Metin içindeki bağlantıların tek kaynağı: not gövdesinin renklendirilmesi
/// (WrapTextController), uzun basma menüsündeki "Bağlantıyı aç" ve QR
/// sonucunun "link mi" ayrımı hep buradan beslenir. Üç yerde ayrı ayrı yazılan
/// bir kalıp, birinde düzeltilip diğerinde unutulurdu.
library;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Bulunan bağlantının türü. E-posta ayrı tutulur çünkü açılışı farklıdır
/// (`mailto:`) ve **web kalıbından ÖNCE eşleşmesi** gerekir.
///
/// KÖK NEDEN (kullanıcı: "bazı mailler ve internet adresleri eksik yanlış
/// adres işaretine alınıyor"): e-posta kalıbı hiç yoktu. `ali@ornek.com`
/// yazıldığında çıplak alan adı kalıbı `@`'in SAĞINDAKİ `ornek.com`'u
/// yakalıyor, kullanıcı adını dışarıda bırakıyordu. Ekranda adresin yalnız
/// yarısı maviye boyanıyor, tıklanınca da `https://ornek.com` açılıyordu —
/// "yanlış adres işaretine alınıyor" tam olarak buydu.
enum LinkKind { web, email }

/// E-posta: yerel kısım + `@` + alan adı. Alan adının son parçası
/// [_tldPattern] ile aynı listeden gelmez — e-postada `@` zaten güçlü bir
/// işarettir, iki harften uzun her uzantı kabul edilir (kurumsal `.com.tr`,
/// `.k12.tr`, `.edu` hepsi çalışır).
final RegExp _emailPattern = RegExp(
  r"[\w.!#$%&'*+/=?^`{|}~-]+@[\w-]+(?:\.[\w-]+)*\.[a-z]{2,}",
  caseSensitive: false,
);

/// ÇIPLAK alan adında (şemasız, `www.`suz) kabul edilen üst düzey alanlar.
/// Liste BİLEREK sonlu tutuldu: `\w+\.\w+` gibi geniş bir kalıp not içindeki
/// "dosya.txt", "sürüm 1.2", "Ahmet.Yılmaz" gibi metinleri de link sanıp
/// maviye boyardı.
///
/// 2026-08-16'da genişletildi (kullanıcı: "bazı internet adresleri eksik"):
/// eskiden 17 uzantı vardı; Türkiye alt alanları (`org.tr`, `gov.tr`,
/// `edu.tr`, `k12.tr`), yaygın ülke kodları ve yeni nesil uzantılar
/// (`store`, `online`, `blog`, `tech`, …) linke sayılmıyordu.
///
/// **Bilerek DIŞARIDA bırakılanlar**: `at`, `be`, `in`, `is`, `it`, `no`,
/// `to`, `us`, `so`, `my`, `id`, `ma` gibi günlük kelimeyle çakışan iki
/// harfli ülke kodları. Noktadan sonra boşluk unutulmuş bir cümle
/// ("bitti.It happens") bunlarla link sanılırdı. O alan adları `www.` ya da
/// `https://` ile yazılınca ikinci alternatiften zaten yakalanır.
const String _tldPattern =
    'com|net|org|edu|gov|mil|int|info|biz|name|pro|xyz|top|site|online|store|'
    'shop|blog|news|live|life|world|space|website|cloud|tech|dev|app|ai|io|co|'
    'me|tv|fm|cc|gg|link|click|page|wiki|art|design|studio|agency|digital|'
    'media|email|help|team|zone|today|social|video|games|fun|band|press|'
    'academy|school|institute|systems|network|solutions|services|'
    'tr|de|uk|fr|es|nl|ch|se|fi|dk|pl|cz|ru|ua|az|gr|pt|ro|hu|bg|'
    'ca|mx|br|au|nz|jp|kr|cn|sg|th|vn|ph|pk|ir|sa|ae|qa|il|eg|za|ng|ke';

/// Türkiye'nin ikinci düzey alanları: `com.tr`, `org.tr`, `k12.tr`…
/// Kalıbın sonuna eklenir ki `ornek.com.tr` tamamı tek adres sayılsın.
const String _secondLevelSuffix = r'(?:\.(?:com|net|org|edu|gov|bel|k12|av|'
    r'dr|pol|tsk|tel|gen|web|name|info|biz)\.tr)?';

/// Şemalı adresler (http/https), `www.` ile başlayanlar ve bilinen uzantıyla
/// biten çıplak alan adları. E-posta kalıbı ÖNCE gelir: `ali@ornek.com`
/// tümüyle e-posta olarak tüketilsin, sağındaki `ornek.com` ayrı bir web
/// adresi sanılmasın.
///
/// Çıplak alan adının TLD'den önceki son etiketinde en az bir HARF şart
/// (`[\w-]*[a-zçğıöşü][\w-]*`): "sürüm 1.2" ve "saat 14.30" gibi sayı
/// dizileri, uzantı listesinde olmayan bir parça taşısalar bile linke
/// düşmesin diye.
final RegExp _linkPattern = RegExp(
  // 1) e-posta (mailto)
  '${_emailPattern.pattern}'
  // 2) şemalı ya da www. ile başlayan adres
  r'|(?:https?://|www\.)[^\s<>"]+'
  // 3) çıplak alan adı
  r'|\b(?:[\w-]+\.)*'
  r'[\w-]*[a-zA-ZÀ-ÖØ-öø-ÿĀ-ſ][\w-]*'
  '\\.(?:$_tldPattern)'
  '$_secondLevelSuffix'
  r'(?:[/?#][^\s<>"]*)?',
  caseSensitive: false,
);

/// Adresin sonuna yapışan noktalama: "bak https://a.com." cümlesinde son
/// nokta adrese ait değildir.
const String _trailingPunctuation = '.,;:!?"\'';

/// Metindeki bağlantıların konumları (başlangıç, bitiş, adres, tür).
List<({int start, int end, String url, LinkKind kind})> findLinks(String text) {
  final found = <({int start, int end, String url, LinkKind kind})>[];
  for (final match in _linkPattern.allMatches(text)) {
    var end = match.end;
    // Kapanmayan parantez de adrese dahil edilmez: "(bkz. a.com)".
    while (end > match.start) {
      final last = text[end - 1];
      final unbalanced =
          last == ')' && !text.substring(match.start, end).contains('(');
      if (!_trailingPunctuation.contains(last) && !unbalanced) break;
      end--;
    }
    if (end <= match.start) continue;
    final url = text.substring(match.start, end);
    found.add((
      start: match.start,
      end: end,
      url: url,
      kind: url.contains('@') && !url.contains('://')
          ? LinkKind.email
          : LinkKind.web,
    ));
  }
  return found;
}

/// Metnin tamamı tek bir bağlantıysa o adresi, değilse null döndürür.
/// QR sonucu için: okunan kod bir link mi, yoksa düz metin mi?
String? soleLink(String text) {
  final trimmed = text.trim();
  final links = findLinks(trimmed);
  if (links.length != 1) return null;
  final only = links.first;
  return only.start == 0 && only.end == trimmed.length ? only.url : null;
}

/// [offset] konumundaki (ya da hemen bitişiğindeki) bağlantı; yoksa null.
/// İmleç adresin sonuna konduğunda da bulunması için bitiş sınırı dahildir.
String? linkAt(String text, int offset) {
  for (final link in findLinks(text)) {
    if (offset >= link.start && offset <= link.end) return link.url;
  }
  return null;
}

/// Metni düz ve bağlantı parçalarına böler. [linkColor] null ise metin
/// olduğu gibi döner — ÖLÇÜM yolu (TextPainter) rengi umursamaz ve renk/alt
/// çizgi satır genişliğini değiştirmediği için ölçüm ile çizim ayrışmaz.
List<InlineSpan> linkSpans(String text, TextStyle? style, Color? linkColor) {
  if (linkColor == null || text.isEmpty) {
    return [TextSpan(text: text, style: style)];
  }
  final links = findLinks(text);
  if (links.isEmpty) return [TextSpan(text: text, style: style)];

  final linkStyle = (style ?? const TextStyle()).copyWith(
    color: linkColor,
    decoration: TextDecoration.underline,
    decorationColor: linkColor,
  );
  final spans = <InlineSpan>[];
  var cursor = 0;
  for (final link in links) {
    if (link.start > cursor) {
      spans.add(
        TextSpan(text: text.substring(cursor, link.start), style: style),
      );
    }
    spans.add(TextSpan(text: link.url, style: linkStyle));
    cursor = link.end;
  }
  if (cursor < text.length) {
    spans.add(TextSpan(text: text.substring(cursor), style: style));
  }
  return spans;
}

/// Adresi açar: e-posta ise posta uygulaması (`mailto:`), değilse tarayıcı.
/// Şema yoksa https varsayılır (www.x.com, x.com/y). Açılamazsa false döner;
/// çağıran kullanıcıya haber verir.
Future<bool> openLink(String raw) async {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return false;
  final String withScheme;
  if (trimmed.contains('://') || trimmed.startsWith('mailto:')) {
    withScheme = trimmed;
  } else if (trimmed.contains('@')) {
    withScheme = 'mailto:$trimmed';
  } else {
    withScheme = 'https://$trimmed';
  }
  final uri = Uri.tryParse(withScheme);
  if (uri == null) return false;
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
