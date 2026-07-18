import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/constants.dart';

/// Gemini Live ile canlı dikte oturumu: mikrofon sesi (16 kHz PCM)
/// [sendAudio] ile akıtılır, konuşmanın dökümü [onTranscript] ile parça
/// parça gelir. Live Translate modelinin girdi transkripsiyonu kullanılır;
/// hedef dil Türkçe ve echoTargetLanguage kapalı olduğundan Türkçe
/// konuşmada model ses üretmez, üretse de ses çıktısı yok sayılır —
/// yalnızca döküm akar.
class LiveDictationSession {
  LiveDictationSession({
    required this.onTranscript,
    required this.onError,
  });

  final void Function(String text) onTranscript;
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
            'targetLanguageCode': 'tr',
            'echoTargetLanguage': false,
          },
        },
        'inputAudioTranscription': <String, dynamic>{},
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
      final inputTranscription =
          serverContent?['inputTranscription'] as Map<String, dynamic>?;
      final inputText = inputTranscription?['text'] as String?;
      if (inputText != null && inputText.isNotEmpty) {
        onTranscript(inputText);
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
