import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/services.dart';
import 'package:web/web.dart' as web;

/// **WEB'DE CANLI DİKTE** (kullanıcı bulgusu 2026-11-20: "webte sesle yazma
/// kullanılamıyor"). Tarayıcının Web Speech API'si (Chrome/Edge/Safari:
/// `SpeechRecognition`, çoğunda `webkitSpeechRecognition`). Android
/// köprüsüyle aynı sözleşme: her olayda o ana kadarki TAM metin.
///
/// Tarayıcı sürekli kipte bile bir süre sonra (ya da sessizlikte) tanımayı
/// kendiliğinden bitirir; durdurulmadıysa yeniden başlatılır, önceki metin
/// önek olarak korunur. Sessizlikte bitiş kararı [VoiceListenSession]da.
JSFunction? _ctor() {
  for (final name in const ['SpeechRecognition', 'webkitSpeechRecognition']) {
    final v = globalContext.getProperty<JSAny?>(name.toJS);
    if (v != null && v.typeofEquals('function')) return v as JSFunction;
  }
  return null;
}

extension type _Recognizer._(JSObject _) implements JSObject {
  external set lang(String v);
  external set continuous(bool v);
  external set interimResults(bool v);
  external set onresult(JSFunction? f);
  external set onerror(JSFunction? f);
  external set onend(JSFunction? f);
  external set onspeechstart(JSFunction? f);
  external set onspeechend(JSFunction? f);
  external void start();
  external void stop();
  external void abort();
}

extension type _ResultEvent._(JSObject _) implements JSObject {
  external _ResultList get results;
}

extension type _ResultList._(JSObject _) implements JSObject {
  external int get length;
  external _Result item(int index);
}

extension type _Result._(JSObject _) implements JSObject {
  external int get length;
  external _Alternative item(int index);
}

extension type _Alternative._(JSObject _) implements JSObject {
  external String get transcript;
}

extension type _ErrorEvent._(JSObject _) implements JSObject {
  external String get error;
}

bool webSpeechAvailable() => _ctor() != null;

/// Mikrofon izni ZATEN verilmiş mi (izin kutusu açmadan). Tarayıcı
/// sorgulamayı desteklemiyorsa false: kendiliğinden dinleme başlamaz,
/// kullanıcı mikrofona basınca tarayıcı sorar.
Future<bool> webMicPermissionGranted() async {
  try {
    final status = await web.window.navigator.permissions
        .query({'name': 'microphone'}.jsify()! as JSObject)
        .toDart;
    return status.state == 'granted';
  } catch (_) {
    return false;
  }
}

_WebListen? _current;

Stream<({String? text, double? level})> webSpeechListen(String locale) {
  _current?.cancel();
  final listen = _WebListen(locale);
  _current = listen;
  return listen.controller.stream;
}

Future<void> webSpeechStop() async => _current?.stop();

String _join(String a, String b) {
  if (a.isEmpty) return b.trimLeft();
  if (b.isEmpty) return a;
  return '${a.trimRight()} ${b.trimLeft()}';
}

class _WebListen {
  _WebListen(this.locale) {
    controller = StreamController<({String? text, double? level})>(
      onListen: _start,
      onCancel: cancel,
    );
  }

  final String locale;
  late final StreamController<({String? text, double? level})> controller;
  _Recognizer? _rec;
  String _prefix = '';
  String _text = '';
  bool _stopping = false;
  bool _heard = false;
  bool _fatal = false;
  int _quickEnds = 0;
  DateTime _startedAt = DateTime.now();

  void _emit(({String? text, double? level}) e) {
    if (!controller.isClosed) controller.add(e);
  }

  void _fail(String code, String message) {
    _fatal = true;
    if (!controller.isClosed) {
      controller.addError(PlatformException(code: code, message: message));
    }
  }

  void _start() {
    final ctor = _ctor();
    if (ctor == null) {
      _fail('speech_unavailable', 'Bu tarayıcı konuşma tanımayı desteklemiyor');
      return;
    }
    final rec = _Recognizer._(ctor.callAsConstructor<JSObject>());
    rec
      ..lang = locale
      ..continuous = true
      ..interimResults = true
      ..onresult = ((JSObject e) {
        final results = (e as _ResultEvent).results;
        final buf = StringBuffer();
        for (var i = 0; i < results.length; i++) {
          final r = results.item(i);
          if (r.length > 0) buf.write(r.item(0).transcript);
        }
        final text = _join(_prefix, buf.toString());
        if (text.trim().isEmpty) return;
        _heard = true;
        _text = text;
        _emit((text: text, level: 0.7));
      }).toJS
      ..onspeechstart = ((JSObject _) => _emit((text: null, level: 0.6))).toJS
      ..onspeechend = ((JSObject _) => _emit((text: null, level: 0.0))).toJS
      ..onerror = ((JSObject e) {
        switch ((e as _ErrorEvent).error) {
          case 'no-speech':
          case 'aborted':
            // Sessizlik: bitişte yeniden başlatılır (ya da hiç konuşulmadıysa
            // "uzun süre konuşma yok" ile kapanır, bkz. onend).
            break;
          case 'not-allowed':
          case 'service-not-allowed':
            _fail('speech_permission', 'Mikrofon izni verilmedi');
          case 'audio-capture':
            _fail('speech_unavailable', 'Mikrofon bulunamadı');
          case 'network':
            _fail(
              'speech_unavailable',
              'Tarayıcının konuşma tanıması internete ulaşamadı',
            );
          case 'language-not-supported':
            _fail('speech_unavailable', 'Bu dil tarayıcıda tanınmıyor');
          default:
            _fail('speech_error', 'Konuşma tanıma hatası');
        }
      }).toJS
      ..onend = ((JSObject _) {
        _rec = null;
        if (_stopping || _fatal || controller.isClosed) {
          unawaited(controller.close());
          return;
        }
        // Hiç konuşulmadan bitti (tarayıcının sessizlik süresi): Android'deki
        // gibi dinleme kapanır.
        if (!_heard) {
          _fail('speech_idle', 'Uzun süre konuşma algılanmadı, dinleme durduruldu');
          unawaited(controller.close());
          return;
        }
        // Art arda hemen biten oturumlar: döngüye girme.
        final quick =
            DateTime.now().difference(_startedAt) < const Duration(seconds: 1);
        _quickEnds = quick ? _quickEnds + 1 : 0;
        if (_quickEnds >= 3) {
          _fail('speech_error', 'Konuşma tanıma tekrar tekrar başarısız oldu');
          unawaited(controller.close());
          return;
        }
        _prefix = _text;
        _start();
      }).toJS;
    _rec = rec;
    _startedAt = DateTime.now();
    try {
      rec.start();
    } catch (_) {
      _fail('speech_unavailable', 'Konuşma tanıma başlatılamadı');
    }
  }

  /// Son sonucu bekleyerek bitirir (tarayıcı son metni `onend`den önce
  /// gönderir).
  void stop() {
    _stopping = true;
    final rec = _rec;
    if (rec == null) {
      unawaited(controller.close());
      return;
    }
    try {
      rec.stop();
    } catch (_) {}
  }

  void cancel() {
    _stopping = true;
    if (identical(_current, this)) _current = null;
    final rec = _rec;
    _rec = null;
    if (rec != null) {
      try {
        rec.abort();
      } catch (_) {}
    }
  }
}
