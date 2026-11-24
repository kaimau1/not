import 'dart:math' as math;

export 'web_speech_recognition_stub.dart'
    if (dart.library.js_interop) 'web_speech_recognition_web.dart';

/// İki konuşma parçası arasındaki yinelenen kuyruk-baş çakışmasını temizler.
///
/// Chrome Web Speech API sürekli modda veya yeniden başlangıçta önceki
/// segmentin son 1–8 kelimesini yeni segmentin başına kopyalayabiliyor.
String combineWebSpeechPrefixAndCurrent(String prefix, String current) {
  final a = prefix.trim();
  final b = current.trim();
  if (a.isEmpty) return b;
  if (b.isEmpty) return a;
  final al = a.toLowerCase();
  final bl = b.toLowerCase();
  if (bl.startsWith(al)) return b;
  if (al.endsWith(bl)) return a;

  final wordsA = a.split(RegExp(r'\s+'));
  final wordsB = b.split(RegExp(r'\s+'));
  final maxOverlap = math.min(8, math.min(wordsA.length, wordsB.length));
  var overlap = 0;
  for (var k = maxOverlap; k >= 1; k--) {
    var matched = true;
    for (var i = 0; i < k; i++) {
      if (wordsA[wordsA.length - k + i].toLowerCase() !=
          wordsB[i].toLowerCase()) {
        matched = false;
        break;
      }
    }
    if (matched) {
      overlap = k;
      break;
    }
  }
  if (overlap == 0) return '$a $b';
  final tail = wordsB.skip(overlap).join(' ');
  return tail.isEmpty ? a : '$a $tail';
}

/// Tarayıcı `SpeechRecognitionResultList` parçalarını tek akıcı metinde
/// birleştirir (test edilebilir saf işlev).
String combineWebSpeechSegments(
  List<({String transcript, bool isFinal})> segments,
) {
  var combined = '';
  for (final seg in segments) {
    final part = seg.transcript.trim();
    if (part.isEmpty) continue;
    combined = combineWebSpeechPrefixAndCurrent(combined, part);
  }
  return combined;
}
