export 'web_speech_recognition_stub.dart'
    if (dart.library.js_interop) 'web_speech_recognition_web.dart';

/// Tarayıcı `SpeechRecognitionResultList` parçalarını tek akıcı metinde
/// birleştirir (test edilebilir saf işlev).
String combineWebSpeechSegments(
  List<({String transcript, bool isFinal})> segments,
) {
  final buf = StringBuffer();
  for (final seg in segments) {
    final part = seg.transcript.trim();
    if (part.isEmpty) continue;
    if (buf.isNotEmpty) buf.write(' ');
    buf.write(part);
  }
  return buf.toString();
}
