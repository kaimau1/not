import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/constants.dart';

/// Gemini 3.5 Live Translate ile tek yönlü canlı çeviri oturumu.
/// Mikrofon sesi (16 kHz PCM) [sendAudio] ile akıtılır; model konuşmayı
/// [targetLanguageCode] diline çevirip 24 kHz PCM ses + transkript döner.
/// Girdi zaten hedef dildeyse model sessiz kalır (echoTargetLanguage=false) —
/// iki oturum paralel çalıştırılarak tam çift yönlü çeviri elde edilir.
class LiveTranslateSession {
  LiveTranslateSession({
    required this.targetLanguageCode,
    required this.onAudio,
    required this.onInputTranscript,
    required this.onOutputTranscript,
    required this.onError,
  });

  final String targetLanguageCode;
  final void Function(Uint8List pcm24k) onAudio;
  final void Function(String text) onInputTranscript;
  final void Function(String text) onOutputTranscript;
  final void Function(Object error) onError;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  final _setupCompleted = Completer<void>();
  bool _closed = false;

  Future<void> connect(String apiKey) async {
    final uri = Uri.parse('${AppConstants.geminiLiveWsUrl}?key=$apiKey');
    _channel = WebSocketChannel.connect(uri);
    await _channel!.ready;

    _sub = _channel!.stream.listen(
      _handleMessage,
      onError: (Object e) {
        if (!_setupCompleted.isCompleted) _setupCompleted.completeError(e);
        if (!_closed) onError(e);
      },
      onDone: () {
        if (!_setupCompleted.isCompleted) {
          _setupCompleted
              .completeError(StateError('Bağlantı beklenmedik şekilde kapandı'));
        }
      },
    );

    _channel!.sink.add(jsonEncode({
      'setup': {
        'model': 'models/${AppConstants.geminiLiveTranslateModel}',
        'generationConfig': {
          'responseModalities': ['AUDIO'],
          'translationConfig': {
            'targetLanguageCode': targetLanguageCode,
            'echoTargetLanguage': false,
          },
        },
        'inputAudioTranscription': <String, dynamic>{},
        'outputAudioTranscription': <String, dynamic>{},
      },
    }));

    await _setupCompleted.future.timeout(const Duration(seconds: 15));
  }

  void _handleMessage(dynamic raw) {
    try {
      final text = raw is String ? raw : utf8.decode(raw as List<int>);
      final message = jsonDecode(text) as Map<String, dynamic>;

      if (message.containsKey('setupComplete')) {
        if (!_setupCompleted.isCompleted) _setupCompleted.complete();
        return;
      }

      final serverContent = message['serverContent'] as Map<String, dynamic>?;
      if (serverContent == null) return;

      final inputTranscription =
          serverContent['inputTranscription'] as Map<String, dynamic>?;
      final inputText = inputTranscription?['text'] as String?;
      if (inputText != null && inputText.isNotEmpty) {
        onInputTranscript(inputText);
      }

      final outputTranscription =
          serverContent['outputTranscription'] as Map<String, dynamic>?;
      final outputText = outputTranscription?['text'] as String?;
      if (outputText != null && outputText.isNotEmpty) {
        onOutputTranscript(outputText);
      }

      final modelTurn = serverContent['modelTurn'] as Map<String, dynamic>?;
      final parts = modelTurn?['parts'] as List<dynamic>? ?? const [];
      for (final part in parts) {
        final inline = (part as Map<String, dynamic>)['inlineData']
            as Map<String, dynamic>?;
        final data = inline?['data'] as String?;
        if (data != null) onAudio(base64Decode(data));
      }
    } catch (e) {
      if (!_closed) onError(e);
    }
  }

  /// 16 kHz, 16-bit, mono PCM parçası gönderir.
  void sendAudio(Uint8List pcm16k) {
    final channel = _channel;
    if (channel == null || _closed) return;
    channel.sink.add(jsonEncode({
      'realtimeInput': {
        'audio': {
          'data': base64Encode(pcm16k),
          'mimeType': 'audio/pcm;rate=16000',
        },
      },
    }));
  }

  Future<void> close() async {
    _closed = true;
    await _sub?.cancel();
    await _channel?.sink.close();
    _channel = null;
  }
}
