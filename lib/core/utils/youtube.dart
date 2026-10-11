/// YouTube bağlantılarını tanır ve gömülü oynatıcının ihtiyaç duyduğu
/// adresleri üretir. Saf işlevler (ağ yok) — testlerde doğrudan sınanır.
library;

/// Kimlik 11 karakter: harf, rakam, `-` ve `_`.
final _idPattern = RegExp(r'^[A-Za-z0-9_-]{11}$');

/// Metindeki İLK YouTube bağlantısı (paylaşılan metin çoğu zaman "başlık +
/// bağlantı" biçimindedir). Yoksa null.
final _urlInText = RegExp(
  r'(?:https?://)?(?:www\.|m\.|music\.)?(?:youtube\.com|youtu\.be|youtube-nocookie\.com)/[^\s<>"]+',
  caseSensitive: false,
);

/// [url] bir YouTube videosunu gösteriyorsa video kimliği; değilse null.
///
/// Tanınan biçimler: `youtu.be/ID`, `youtube.com/watch?v=ID`,
/// `/shorts/ID`, `/live/ID`, `/embed/ID`, `/v/ID`, `m.` ve `music.`
/// alt alanları. Kanal/oynatma listesi bağlantıları video değildir → null.
String? youTubeVideoId(String url) {
  var text = url.trim();
  if (text.isEmpty) return null;
  if (!text.contains('://')) text = 'https://$text';
  final uri = Uri.tryParse(text);
  if (uri == null) return null;
  final host = uri.host.toLowerCase();
  String? id;
  if (host == 'youtu.be') {
    id = uri.pathSegments.isEmpty ? null : uri.pathSegments.first;
  } else if (host == 'youtube.com' ||
      host.endsWith('.youtube.com') ||
      host == 'youtube-nocookie.com' ||
      host.endsWith('.youtube-nocookie.com')) {
    final segs = uri.pathSegments;
    if (segs.isNotEmpty && segs.first == 'watch') {
      id = uri.queryParameters['v'];
    } else if (segs.length >= 2 &&
        const {'shorts', 'live', 'embed', 'v', 'e'}.contains(segs.first)) {
      id = segs[1];
    }
  }
  if (id == null || !_idPattern.hasMatch(id)) return null;
  return id;
}

/// Metnin içindeki ilk YouTube VİDEO bağlantısı; yoksa null.
String? firstYouTubeUrl(String text) {
  for (final m in _urlInText.allMatches(text)) {
    // Cümle sonundaki noktalama bağlantıya dahil değildir.
    final url = m.group(0)!.replaceFirst(RegExp(r'[).,;!?]+$'), '');
    if (youTubeVideoId(url) != null) return url;
  }
  return null;
}

/// Videonun başlangıç saniyesi (`t=90`, `t=1m30s`, `start=90`); yoksa 0.
int youTubeStartSeconds(String url) {
  var text = url.trim();
  if (!text.contains('://')) text = 'https://$text';
  final uri = Uri.tryParse(text);
  if (uri == null) return 0;
  final raw = uri.queryParameters['t'] ?? uri.queryParameters['start'];
  if (raw == null || raw.isEmpty) return 0;
  final plain = int.tryParse(raw.replaceAll('s', ''));
  if (plain != null) return plain;
  final m = RegExp(r'^(?:(\d+)h)?(?:(\d+)m)?(?:(\d+)s)?$').firstMatch(raw);
  if (m == null) return 0;
  int part(int i) => int.tryParse(m.group(i) ?? '') ?? 0;
  return part(1) * 3600 + part(2) * 60 + part(3);
}

/// Kanonik izleme adresi (paylaşım/tarayıcıda açma için).
String youTubeWatchUrl(String id) => 'https://www.youtube.com/watch?v=$id';

/// Kapak görseli (oturum açmadan, API anahtarı olmadan erişilebilir).
String youTubeThumbnailUrl(String id) =>
    'https://i.ytimg.com/vi/$id/hqdefault.jpg';

/// Gömülü oynatıcının HTML'i.
///
/// TUZAK: YouTube gömülü oynatıcısı "Referer"ı olmayan isteği reddediyor
/// (Hata 152/153 — "video oynatıcı yapılandırma hatası"). YouTube'un
/// WebView kuralı: uygulama kendini `https://<paket-adı>` Referer'ıyla
/// tanıtır. Sayfa bu yüzden doğrudan `loadRequest` ile değil, o taban
/// adresle (`loadHtmlString(baseUrl: youTubeEmbedOrigin)`) yüklenir; iframe
/// da aynı kökeni `origin` parametresiyle bildirir.
///
/// **KÜÇÜK KUTUDA ÖLÇEK** (kullanıcı bulgusu 2026-10-11: "çok küçük halde
/// oynatılırken YouTube kendi butonları aşırı yer kaplıyor"): YouTube'un
/// mobil denetimleri CSS pikselinde SABİT boyutludur — 290 dp'lik kutuda
/// ortadaki dev duraklat simgesi, CC ve logo videoyu kaplıyordu. Pencere
/// [minCssWidth]'ten darsa iframe o genişlikte kurulup `scale()` ile
/// küçültülür: denetimler kutuyla ORANTILI küçülür, video aynı kalır.
/// Geniş pencerede (tam ekran oynatıcı) ölçek 1 — hiçbir şey değişmez.
String youTubeEmbedHtml(
  String id, {
  int start = 0,
  int minCssWidth = kYouTubeMinCssWidth,
}) {
  final params = <String, String>{
    'autoplay': '1',
    'playsinline': '1',
    'rel': '0',
    'modestbranding': '1',
    // Tam ekran düğmesi WebView'da özel görünüm köprüsü ister; onun yerine
    // ekranın kendi yatay/PiP düzeni var.
    'fs': '0',
    'enablejsapi': '1',
    'origin': youTubeEmbedOrigin,
    if (start > 0) 'start': '$start',
  };
  final query = params.entries
      .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
      .join('&');
  return '''<!DOCTYPE html>
<html><head>
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
<style>html,body{margin:0;padding:0;height:100%;background:#000;overflow:hidden}
iframe{position:absolute;top:0;left:0;width:100%;height:100%;border:0;transform-origin:0 0}</style>
</head><body>
<iframe id="player" src="https://www.youtube-nocookie.com/embed/$id?$query"
 allow="autoplay; encrypted-media; picture-in-picture; fullscreen"
 referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
<script>
(function(){
  var MIN=$minCssWidth, f=document.getElementById('player');
  function fit(){
    var w=window.innerWidth, h=window.innerHeight;
    if(!w||!h) return;
    var s=w<MIN?w/MIN:1;
    f.style.width=(w/s)+'px';
    f.style.height=(h/s)+'px';
    f.style.transform=s<1?'scale('+s+')':'none';
  }
  window.addEventListener('resize',fit);
  fit();
})();
</script>
</body></html>''';
}

/// Gömülü oynatıcının "sanal" en dar genişliği (CSS px): daha dar kutuda
/// oynatıcı bu genişlikte kurulup küçültülür (bkz. [youTubeEmbedHtml]).
const kYouTubeMinCssWidth = 480;

/// Gömülü sayfanın kökeni = uygulamanın paket adı (bkz. [youTubeEmbedHtml]).
const youTubeEmbedOrigin = 'https://dev.kaimau.notlar';
