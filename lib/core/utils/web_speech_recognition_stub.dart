bool get isWebSpeechAvailable => false;

Stream<({String? text, double? level})> listenWebSpeech({
  String locale = 'tr-TR',
}) => const Stream.empty();

Future<void> stopWebSpeech() async {}
