/// Web DIŞINDA tarayıcı konuşma tanıması yok (bkz. device_speech_web.dart).
bool webSpeechAvailable() => false;

Future<bool> webMicPermissionGranted() async => false;

Stream<({String? text, double? level})> webSpeechListen(String locale) =>
    const Stream.empty();

Future<void> webSpeechStop() async {}
