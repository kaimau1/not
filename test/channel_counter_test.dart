import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/channel_counter.dart';

class _Fake implements BinaryMessenger {
  final handlers = <String, MessageHandler?>{};

  @override
  Future<void> handlePlatformMessage(
    String channel,
    ByteData? data,
    PlatformMessageResponseCallback? callback,
  ) async {}

  @override
  Future<ByteData?>? send(String channel, ByteData? message) =>
      Future.value(ByteData(5));

  @override
  void setMessageHandler(String channel, MessageHandler? handler) =>
      handlers[channel] = handler;
}

/// F27.1: profil derlemesindeki platform kanalı sayacı.
void main() {
  test('giden/gelen ileti ve bayt kanal başına sayılır', () async {
    final inner = _Fake();
    final m = CountingBinaryMessenger(inner);
    await m.send('flutter/platform', ByteData(10));
    await m.send('flutter/platform', ByteData(2));
    await m.send('plugins.flutter.io/firebase_firestore', ByteData(100));
    var handled = 0;
    m.setMessageHandler('flutter/lifecycle', (data) async {
      handled++;
      return null;
    });
    await inner.handlers['flutter/lifecycle']!(ByteData(7));

    final p = m.stats['flutter/platform']!;
    expect(p.outCount, 2);
    expect(p.outBytes, 12);
    expect(p.inBytes, 10); // iki yanıt × 5 bayt
    final l = m.stats['flutter/lifecycle']!;
    expect((l.inCount, l.inBytes, handled), (1, 7, 1));
    expect(m.top(1).single.key, 'plugins.flutter.io/firebase_firestore');

    m.setMessageHandler('flutter/lifecycle', null);
    expect(inner.handlers['flutter/lifecycle'], isNull);
    m.reset();
    expect(m.stats, isEmpty);
  });

  test('sayaç kurulmadıysa özet boş', () {
    debugResetChannelCounter();
    expect(channelSummary(), '');
  });
}
