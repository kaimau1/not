import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'diagnostics.dart';

/// F27.1 (AKICILIK_PLANI, K4): platform kanalı sayacı — kanal başına giden /
/// gelen ileti sayısı ve bayt. Yalnız [Diagnostics.enabled] (hata ayıklama /
/// profil) derlemede kurulur; release'te bu dosya ağaçtan atılır.
///
/// Okuma: profil derlemesine bağlı VM servisinden
/// `ext.notlar.channels` (`reset=true` sayaçları sıfırlar) — bkz.
/// `tool/perf/vmsvc.py` `VM.channels()`.
class ChannelStats {
  int outCount = 0;
  int outBytes = 0;
  int inCount = 0;
  int inBytes = 0;

  Map<String, int> toJson() => {
    'outCount': outCount,
    'outBytes': outBytes,
    'inCount': inCount,
    'inBytes': inBytes,
  };
}

/// Varsayılan ileticiyi saran sayaç.
class CountingBinaryMessenger implements BinaryMessenger {
  CountingBinaryMessenger(this._inner);

  final BinaryMessenger _inner;
  final Map<String, ChannelStats> stats = {};

  ChannelStats _of(String channel) =>
      stats.putIfAbsent(channel, ChannelStats.new);

  void reset() => stats.clear();

  /// En çok bayt taşıyan [limit] kanal (giden + gelen).
  List<MapEntry<String, ChannelStats>> top([int limit = 10]) {
    final list = stats.entries.toList()
      ..sort(
        (a, b) => (b.value.outBytes + b.value.inBytes).compareTo(
          a.value.outBytes + a.value.inBytes,
        ),
      );
    return list.take(limit).toList();
  }

  @override
  Future<void> handlePlatformMessage(
    String channel,
    ByteData? data,
    PlatformMessageResponseCallback? callback,
  ) =>
      // ignore: deprecated_member_use
      _inner.handlePlatformMessage(channel, data, callback);

  @override
  Future<ByteData?>? send(String channel, ByteData? message) {
    final s = _of(channel);
    s.outCount += 1;
    s.outBytes += message?.lengthInBytes ?? 0;
    final reply = _inner.send(channel, message);
    return reply?.then((r) {
      s.inBytes += r?.lengthInBytes ?? 0;
      return r;
    });
  }

  @override
  void setMessageHandler(String channel, MessageHandler? handler) {
    if (handler == null) {
      _inner.setMessageHandler(channel, null);
      return;
    }
    _inner.setMessageHandler(channel, (data) {
      final s = _of(channel);
      s.inCount += 1;
      s.inBytes += data?.lengthInBytes ?? 0;
      return handler(data);
    });
  }
}

/// Sayaçlı ileticiyle kurulan bağlama. `main` yalnız [Diagnostics.enabled]
/// iken bunu çağırır.
class ChannelCountingBinding extends WidgetsFlutterBinding {
  static CountingBinaryMessenger? messenger;

  static WidgetsBinding ensureInitialized() {
    if (messenger == null) {
      ChannelCountingBinding();
      developer.registerExtension('ext.notlar.channels', (_, params) async {
        final m = messenger!;
        final body = jsonEncode({
          for (final e in m.top(1 << 20)) e.key: e.value.toJson(),
        });
        if (params['reset'] == 'true') m.reset();
        return developer.ServiceExtensionResponse.result(body);
      });
    }
    return WidgetsBinding.instance;
  }

  @override
  BinaryMessenger createBinaryMessenger() {
    assert(Diagnostics.enabled);
    return messenger = CountingBinaryMessenger(super.createBinaryMessenger());
  }
}

/// Ayarlar → Hakkında teşhis satırı için kısa özet (en çok konuşan 3 kanal).
String channelSummary() {
  final m = ChannelCountingBinding.messenger;
  if (m == null) return '';
  String kb(int b) => (b / 1024).toStringAsFixed(0);
  return m
      .top(3)
      .map(
        (e) =>
            '${e.key.split('/').last}: ${e.value.outCount}↑'
            '${e.value.inCount}↓ ${kb(e.value.outBytes + e.value.inBytes)} KB',
      )
      .join(' · ');
}

/// Testler için.
@visibleForTesting
void debugResetChannelCounter() => ChannelCountingBinding.messenger = null;
