import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/services.dart';

import 'web_speech_recognition.dart';

JSFunction? _speechCtor() {
  try {
    final s = globalContext.getProperty<JSAny?>('SpeechRecognition'.toJS);
    if (s != null && s.isA<JSFunction>()) return s as JSFunction;
    final ws = globalContext.getProperty<JSAny?>(
      'webkitSpeechRecognition'.toJS,
    );
    if (ws != null && ws.isA<JSFunction>()) return ws as JSFunction;
    return null;
  } catch (_) {
    return null;
  }
}

JSObject? _activeRecognition;
bool _stopping = false;

bool get isWebSpeechAvailable => _speechCtor() != null;

JSAny? _itemAt(JSObject list, int index) {
  if (list.has('item')) {
    return list.callMethod<JSAny?>('item'.toJS, index.toJS);
  }
  return list.getProperty<JSAny?>(index.toString().toJS);
}

String _combineWithPrefix(String prefix, String current) =>
    combineWebSpeechPrefixAndCurrent(prefix, current);

/// Web Speech API (`SpeechRecognition` / `webkitSpeechRecognition`) üzerinden
/// canlı dikte akışı. Desteklenmeyen veya izin reddedilen tarayıcılarda
/// `speech_unavailable` hatası yayınlar; [VoiceListenSession] ses kaydı
/// yoluna düşer.
Stream<({String? text, double? level})> listenWebSpeech({
  String locale = 'tr-TR',
}) {
  final ctor = _speechCtor();
  if (ctor == null) {
    return Stream.error(
      PlatformException(
        code: 'speech_unavailable',
        message: 'SpeechRecognition unavailable',
      ),
    );
  }

  late final StreamController<({String? text, double? level})> controller;
  var closed = false;
  var fatal = false;
  var committedPrefix = '';
  var sessionText = '';
  var latestFull = '';
  var emptyRestarts = 0;

  void finishStream() {
    if (closed) return;
    closed = true;
    _activeRecognition = null;
    if (!controller.isClosed) unawaited(controller.close());
  }

  void startRecognition() {
    if (closed || _stopping) {
      finishStream();
      return;
    }
    try {
      final rec = ctor.callAsConstructor<JSObject>();
      _activeRecognition = rec;
      rec.setProperty('continuous'.toJS, true.toJS);
      rec.setProperty('interimResults'.toJS, true.toJS);
      rec.setProperty('lang'.toJS, locale.toJS);

      rec.setProperty(
        'onresult'.toJS,
        ((JSObject event) {
          if (closed) return;
          try {
            final resultsAny = event.getProperty<JSAny?>('results'.toJS);
            if (resultsAny == null || !resultsAny.isA<JSObject>()) return;
            final results = resultsAny as JSObject;
            final lenAny = results.getProperty<JSAny?>('length'.toJS);
            final len = lenAny != null && lenAny.isA<JSNumber>()
                ? (lenAny as JSNumber).toDartInt
                : 0;
            final segments = <({String transcript, bool isFinal})>[];
            for (var i = 0; i < len; i++) {
              final resAny = _itemAt(results, i);
              if (resAny == null || !resAny.isA<JSObject>()) continue;
              final resObj = resAny as JSObject;
              final isFinalAny = resObj.getProperty<JSAny?>('isFinal'.toJS);
              final isFinal =
                  isFinalAny != null &&
                  isFinalAny.isA<JSBoolean>() &&
                  (isFinalAny as JSBoolean).toDart;
              final altAny = _itemAt(resObj, 0);
              if (altAny == null || !altAny.isA<JSObject>()) continue;
              final altObj = altAny as JSObject;
              final textAny = altObj.getProperty<JSAny?>('transcript'.toJS);
              final transcript = textAny != null && textAny.isA<JSString>()
                  ? (textAny as JSString).toDart
                  : '';
              segments.add((transcript: transcript, isFinal: isFinal));
            }
            sessionText = combineWebSpeechSegments(segments);
            if (sessionText.isNotEmpty) {
              emptyRestarts = 0;
              latestFull = _combineWithPrefix(committedPrefix, sessionText);
              controller.add((text: latestFull, level: 0.45));
            }
          } catch (_) {}
        }).toJS,
      );

      rec.setProperty(
        'onerror'.toJS,
        ((JSObject event) {
          if (closed || fatal) return;
          final errAny = event.getProperty<JSAny?>('error'.toJS);
          final err = errAny != null && errAny.isA<JSString>()
              ? (errAny as JSString).toDart
              : 'unknown';
          if (err == 'no-speech') return;
          if (err == 'aborted' && _stopping) {
            finishStream();
            return;
          }
          const unavailableErrors = {
            'not-allowed',
            'service-not-allowed',
            'audio-capture',
            'language-not-supported',
          };
          if (unavailableErrors.contains(err) ||
              (err == 'network' && latestFull.isEmpty)) {
            fatal = true;
            controller.addError(
              PlatformException(code: 'speech_unavailable', message: err),
            );
            finishStream();
            return;
          }
          fatal = true;
          controller.addError(
            PlatformException(code: 'speech_error', message: err),
          );
          finishStream();
        }).toJS,
      );

      rec.setProperty(
        'onend'.toJS,
        ((JSAny? _) {
          if (closed || fatal) return;
          if (_stopping || !controller.hasListener) {
            finishStream();
            return;
          }
          if (sessionText.isEmpty) {
            emptyRestarts++;
            // Konuşma DUYULDUKTAN sonra düşünme arası uzun olabilir: tarayıcı
            // birkaç saniyelik sessizlikte tanıyıcıyı kapatıyor, 3 boş
            // yeniden başlatmada (~20 sn) dikte sessizce bitiyordu
            // (2026-11-27). Duyulduysa çok daha uzun sabredilir; bitişi
            // sessizlikte otomatik durdurma ve en uzun süre belirler.
            final limit = latestFull.isEmpty ? 3 : 40;
            if (emptyRestarts >= limit) {
              if (latestFull.isEmpty) {
                controller.addError(
                  PlatformException(
                    code: 'speech_unavailable',
                    message: 'speech_ended_empty',
                  ),
                );
              }
              finishStream();
              return;
            }
          } else {
            committedPrefix = latestFull;
            sessionText = '';
          }
          Future<void>.microtask(startRecognition);
        }).toJS,
      );

      rec.callMethod<JSAny?>('start'.toJS);
    } catch (e) {
      if (!closed && !controller.isClosed) {
        if (latestFull.isEmpty) {
          controller.addError(
            PlatformException(
              code: 'speech_unavailable',
              message: e.toString(),
            ),
          );
        }
      }
      finishStream();
    }
  }

  controller = StreamController<({String? text, double? level})>(
    onListen: () {
      _stopping = false;
      startRecognition();
    },
    onCancel: () async {
      await stopWebSpeech();
      finishStream();
    },
  );
  return controller.stream;
}

Future<void> stopWebSpeech() async {
  _stopping = true;
  final rec = _activeRecognition;
  _activeRecognition = null;
  if (rec == null) return;
  try {
    rec.callMethod<JSAny?>('stop'.toJS);
  } catch (_) {}
}
