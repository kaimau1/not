import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/data/voice_listen_session.dart';
import 'package:notlar/features/notes/presentation/listening_visuals.dart';

/// Tablet bulgusu 2026-11-13 ("sesle yazma çalışmıyor ama ses kaydı
/// çalışıyor"): yerli taraf hiçbir tanıyıcıyı hazır edemezse
/// `speech_unavailable` gönderir; oturum bunu hata değil "kayıt yoluna geç"
/// diye çağırana iletir. Geri çağrı verilmemişse eski hata yolu sürer.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const events = EventChannel('dev.kaimau.notlar/speech');

  void mockError(String code) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(
          events,
          MockStreamHandler.inline(
            onListen: (args, sink) => sink.error(code: code, message: 'yok'),
          ),
        );
  }

  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(events, null),
  );

  test('speech_unavailable onUnavailable\'a gider, onError\'a değil', () async {
    mockError('speech_unavailable');
    String? unavailable;
    String? error;
    final session = VoiceListenSession(
      onText: (_) {},
      onEnd: (_) {},
      autoStop: () => false,
      onError: (m) => error = m,
      onUnavailable: (m) => unavailable = m,
    )..start();
    await Future<void>.delayed(Duration.zero);
    await session.cancel();
    expect(unavailable, 'yok');
    expect(error, isNull);
  });

  test('geri çağrı yoksa speech_unavailable hata olarak kalır', () async {
    mockError('speech_unavailable');
    String? error;
    final session = VoiceListenSession(
      onText: (_) {},
      onEnd: (_) {},
      autoStop: () => false,
      onError: (m) => error = m,
    )..start();
    await Future<void>.delayed(Duration.zero);
    await session.cancel();
    expect(error, 'yok');
  });

  // Kasma bekçisi: sürekli boyanan dalga ve nabız rozeti kendi katmanında
  // (yoksa dikte açıkken her kare editör gövdesi de yeniden boyanır).
  testWidgets('dinleme animasyonları kendi boyama katmanında', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Column(
          children: [
            ListeningWaveform(active: true, color: Colors.red),
            ListeningBadge(mode: ListeningMode.dictation, active: true),
          ],
        ),
      ),
    );
    for (final type in [ListeningWaveform, ListeningBadge]) {
      expect(
        find.descendant(
          of: find.byType(type),
          matching: find.byType(RepaintBoundary),
        ),
        findsWidgets,
        reason: '$type',
      );
    }
  });
}
