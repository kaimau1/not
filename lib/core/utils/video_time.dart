/// Notun içindeki VİDEO ZAMAN DAMGALARI (YouTube yorumlarındaki gibi
/// "1:23", "12:05", "1:02:33").
///
/// Kullanıcı isteği 2026-10-16: "videolarda altta dk sn notu, YouTube'daki
/// gibi; ona tıklayınca video o dk sn'ye gider". Damga metnin İÇİNDE düz yazı
/// olarak durur (kopyalama, dışa aktarma, arama hep onu görür); yalnız notta
/// bir video varken bağlantı gibi çizilir ve dokununca videoyu oraya sarar.
library;

import 'package:flutter/foundation.dart';

/// Metindeki bir zaman damgası: `[start, end)` aralığı ve saniye karşılığı.
typedef VideoTimestamp = ({int start, int end, int seconds});

/// `s:dd:ss` ya da `d:ss` — saat 0-99, dakika/saniye 00-59. Rakama ya da
/// iki noktaya YAPIŞIK eşleşme sayılmaz: "10:30:45:12" gibi bir seri numarası,
/// "v1.2:30" ya da "12:345" damga değildir.
final RegExp _timestampPattern = RegExp(
  r'(?<![\d:.,/])(?:(\d{1,2}):([0-5]\d):([0-5]\d)|(\d{1,3}):([0-5]\d))(?![\d:]|[.,]\d)',
);

/// Metindeki bütün zaman damgaları, soldan sağa.
List<VideoTimestamp> findVideoTimestamps(String text) {
  if (!text.contains(':')) return const [];
  final out = <VideoTimestamp>[];
  for (final m in _timestampPattern.allMatches(text)) {
    final int seconds;
    if (m.group(1) != null) {
      seconds =
          int.parse(m.group(1)!) * 3600 +
          int.parse(m.group(2)!) * 60 +
          int.parse(m.group(3)!);
    } else {
      seconds = int.parse(m.group(4)!) * 60 + int.parse(m.group(5)!);
    }
    out.add((start: m.start, end: m.end, seconds: seconds));
  }
  return out;
}

/// [offset] konumundaki damga (imleç damganın İÇİNDE ya da tam sınırında);
/// yoksa null.
VideoTimestamp? videoTimestampAt(String text, int offset) {
  for (final t in findVideoTimestamps(text)) {
    if (offset >= t.start && offset <= t.end) return t;
    if (t.start > offset) break;
  }
  return null;
}

/// Damga yazımı: YouTube gibi baştaki sıfırsız — "0:07", "1:23", "1:02:03".
String formatVideoTimestamp(Duration d) {
  final total = d.isNegative ? 0 : d.inSeconds;
  final h = total ~/ 3600;
  final m = (total % 3600) ~/ 60;
  final s = (total % 60).toString().padLeft(2, '0');
  return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$s' : '$m:$s';
}

/// Satıra damga ekler (bkz. editörün "Bu ana not al" düğmesi): imlecin
/// bulunduğu satır BOŞSA damga oraya yazılır, doluysa satırın SONUNA yeni bir
/// satır açılır. İmleç bilinmiyorsa ([caret] < 0) metnin sonuna. Dönen imleç
/// damganın ve ardındaki boşluğun hemen sonrası — kullanıcı yazmaya devam
/// eder.
({String text, int caret}) insertTimestampLine(
  String text,
  int caret,
  String stamp,
) {
  final at = caret < 0 || caret > text.length ? text.length : caret;
  var lineStart = at == 0 ? 0 : text.lastIndexOf('\n', at - 1) + 1;
  var lineEnd = text.indexOf('\n', at);
  if (lineEnd < 0) lineEnd = text.length;
  final line = text.substring(lineStart, lineEnd);
  final insert = '$stamp ';
  if (line.trim().isEmpty) {
    final next = text.replaceRange(lineStart, lineEnd, insert);
    return (text: next, caret: lineStart + insert.length);
  }
  final next = text.replaceRange(lineEnd, lineEnd, '\n$insert');
  return (text: next, caret: lineEnd + 1 + insert.length);
}

/// Bir oynatıcının not tarafına açtığı yüz: konumu okunur, oraya sarılır;
/// videonun altındaki DENETİM ÇUBUĞU (oynat/durdur, ±10 sn — bkz.
/// `VideoTransportBar`) da buradan sürer.
abstract class VideoTimeSource {
  /// Oynatıcının çaldığı ekin kimliği.
  String get attachmentId;

  /// O anki konum; okunamazsa null.
  Future<Duration?> position();

  /// Konuma sarar ve OYNATIR (damgaya dokunan izlemek ister).
  Future<void> seekTo(Duration position);

  /// Oynatma durumu ya da konum değişince uyanır (denetim çubuğu dinler).
  /// Varsayılan: hiç uyanmaz (durumunu bildiremeyen oynatıcı).
  Listenable get changes => _silent;

  /// Oynuyor mu (bilinmiyorsa false).
  bool get isPlaying => false;

  /// Bilinen son konum ve videonun süresi (bilinmiyorsa null) — çubuktaki
  /// "1:23 / 4:56" yazısı için; okuma maliyeti yok.
  Duration? get lastPosition => null;
  Duration? get duration => null;

  Future<void> play() async {}
  Future<void> pause() async {}

  /// Konumu [delta] kadar kaydırır (±10 sn); oynama durumu DEĞİŞMEZ.
  Future<void> seekBy(Duration delta) async {}

  /// Oynatma hızı (1 = normal) — bkz. [kVideoSpeeds].
  double get speed => 1;
  Future<void> setSpeed(double value) async {}
}

/// Hız düğmesinin dolaştığı değerler (dokundukça sıradakine geçer).
const kVideoSpeeds = <double>[1, 1.25, 1.5, 2, 0.5, 0.75];

/// [current]'tan sonraki hız.
double nextVideoSpeed(double current) {
  final i = kVideoSpeeds.indexOf(current);
  return kVideoSpeeds[(i + 1) % kVideoSpeeds.length];
}

/// "1.5×", "2×", "0.75×".
String formatVideoSpeed(double speed) {
  final text = speed == speed.roundToDouble()
      ? speed.toStringAsFixed(0)
      : speed.toString();
  return '$text×';
}

final Listenable _silent = ValueNotifier<int>(0);

/// [delta] kadar kaydırılmış konum, videonun sınırlarına kıstırılmış.
Duration shiftedPosition(Duration from, Duration delta, Duration? duration) {
  var target = from + delta;
  if (target.isNegative) target = Duration.zero;
  if (duration != null && duration > Duration.zero && target > duration) {
    target = duration;
  }
  return target;
}

/// Notun içindeki oynatıcıların buluşma noktası (editör başına bir tane).
///
/// Oynatıcılar ağaçta kuruldukça kendilerini kaydeder ([register]); not
/// tarafı damgaya dokununca ya da "Bu ana not al"a basınca buradan sorar.
/// Kayıtlı oynatıcısı OLMAYAN video (ör. YouTube kapağı, henüz oynatılmadı)
/// için [requestStart] kullanılır: kutusu isteği dinler ve oynatıcıyı o
/// saniyeden kurar.
class NoteVideoHub {
  final _sources = <VideoTimeSource>[];

  /// En son etkileşilen (oynatılan/sarılan) oynatıcı önce gelir.
  VideoTimeSource? _recent;

  /// Kayıtlı oynatıcısı olmayan videoya "şu saniyeden başla" isteği.
  /// `serial` aynı saniyeye ikinci istekte de dinleyiciyi uyandırır.
  final startRequest = _StartRequestNotifier();

  /// Oynatıcı kaydolunca/ayrılınca artar — denetim çubuğu oynatıcısını
  /// buradan bulur (oynatıcı kutudan SONRA, kendi hazır olunca kaydolur).
  final revision = ValueNotifier<int>(0);

  void register(VideoTimeSource source) {
    _sources.remove(source);
    _sources.add(source);
    revision.value++;
  }

  void unregister(VideoTimeSource source) {
    if (!_sources.remove(source)) return;
    if (identical(_recent, source)) _recent = null;
    revision.value++;
  }

  /// Oynatıcı kullanıcı tarafından oynatıldı/sarıldı: damgalar ÖNCE ona
  /// gider (notta birden çok video varken "izlediğim video" sezgisi).
  void touch(VideoTimeSource source) {
    if (_sources.contains(source)) _recent = source;
  }

  /// [attachmentId]'nin oynatıcısı (yoksa null).
  VideoTimeSource? sourceFor(String attachmentId) {
    for (final s in _sources.reversed) {
      if (s.attachmentId == attachmentId) return s;
    }
    return null;
  }

  /// Damganın gideceği oynatıcı: son etkileşilen, yoksa [preferId]'ninki,
  /// yoksa en son kurulan.
  VideoTimeSource? target({String? preferId}) {
    final recent = _recent;
    if (recent != null && _sources.contains(recent)) return recent;
    if (preferId != null) {
      final preferred = sourceFor(preferId);
      if (preferred != null) return preferred;
    }
    return _sources.isEmpty ? null : _sources.last;
  }

  /// [seconds] null = bağlantının kendi başlangıcı ("oynat" düğmesi).
  void requestStart(String attachmentId, int? seconds) {
    startRequest.request(attachmentId, seconds);
  }

  /// "Bu ana not al" (videonun kenarındaki düğme): editör bunu kurar; düğme
  /// konumu okuyup buraya verir.
  void Function(String attachmentId, Duration position)? onNoteAt;

  /// [source]'un o anki konumuna not açar. Konum okunamazsa false.
  Future<bool> noteAt(VideoTimeSource source) async {
    final callback = onNoteAt;
    if (callback == null) return false;
    final position = await source.position();
    if (position == null) return false;
    touch(source);
    callback(source.attachmentId, position);
    return true;
  }

  void dispose() {
    startRequest.dispose();
    revision.dispose();
  }
}

/// [NoteVideoHub.startRequest]'in bildiricisi.
class _StartRequestNotifier
    extends ValueNotifier<({String id, int? seconds, int serial})?> {
  _StartRequestNotifier() : super(null);

  var _serial = 0;

  void request(String id, int? seconds) =>
      value = (id: id, seconds: seconds, serial: ++_serial);
}
