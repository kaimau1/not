import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/web_speech_recognition.dart';
import 'package:notlar/features/notes/data/voice_listen_session.dart';
import 'package:notlar/features/notes/presentation/editor/dictation_controller.dart';
import 'package:notlar/features/notes/presentation/editor/format_bar.dart';
import 'package:notlar/features/notes/presentation/editor/text_wrap.dart';

class _FakeSession extends VoiceListenSession {
  _FakeSession({
    required super.onText,
    required super.onEnd,
    required super.autoStop,
    required super.locale,
    super.preferOffline,
    super.onError,
    super.onUnavailable,
    super.gate,
    this.onStopEmit,
  }) : super(useDevice: false);

  final String? onStopEmit;
  bool stopped = false;

  @override
  void start() {}

  @override
  Future<void> stop() async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    if (onStopEmit != null) {
      onText(onStopEmit!);
    }
    stopped = true;
  }

  @override
  Future<void> cancel() async {}
}

void main() {
  test('combineWebSpeechPrefixAndCurrent ve combineWebSpeechSegments kuyruk tekrarını siler', () {
    expect(
      combineWebSpeechPrefixAndCurrent(
        'bugün hava çok güzel',
        'çok güzel görünüyor',
      ),
      'bugün hava çok güzel görünüyor',
    );
    expect(
      combineWebSpeechPrefixAndCurrent('merhaba dünya', 'merhaba dünya'),
      'merhaba dünya',
    );
    expect(
      combineWebSpeechSegments([
        (transcript: 'birinci parça', isFinal: true),
        (transcript: 'birinci parça ikinci parça', isFinal: true),
        (transcript: 'üçüncü', isFinal: false),
      ]),
      'birinci parça ikinci parça üçüncü',
    );
  });

  testWidgets(
    'DictationController: stop() sırasında gelen son kelime düşmez ve AI adayı döner',
    (tester) async {
      final ctl = WrapTextController(text: '');
      final focus = FocusNode();
      addTearDown(ctl.dispose);
      addTearDown(focus.dispose);
      final target = FormatTarget(
        controller: ctl,
        focusNode: focus,
        commit: () {},
      );

      _FakeSession? latest;
      final dc = DictationController(
        resolveTarget: () => target,
        fallbackController: () => ctl,
        isItemTarget: (_, _) => false,
        openItemAfter: (_) => null,
        onCommit: (_, _, _) {},
        onRevealCaret: () {},
        smartCommands: () => true,
        autoStop: () => true,
        preferOffline: () => false,
        silenceAfter: () => const Duration(seconds: 4),
        onError: (_) {},
        onUnavailable: (_) {},
        sessionFactory:
            ({
              required locale,
              required autoStop,
              required preferOffline,
              required gate,
              required onText,
              required onEnd,
              required onError,
              required onUnavailable,
            }) {
              return latest = _FakeSession(
                locale: locale,
                autoStop: autoStop,
                preferOffline: preferOffline,
                gate: gate,
                onText: onText,
                onEnd: onEnd,
                onError: onError,
                onUnavailable: onUnavailable,
                onStopEmit: 'merhaba bugün test son kelime',
              );
            },
      );
      addTearDown(dc.dispose);

      dc.start(initialLocale: 'tr-TR');
      dc.handleRecognizedText('merhaba bugün test');
      expect(ctl.logicalText, 'Merhaba bugün test');

      final stopFuture = dc.stop();
      await tester.pump(const Duration(milliseconds: 25));
      final candidate = await stopFuture;
      expect(latest?.stopped, isTrue);
      expect(ctl.logicalText, 'Merhaba bugün test son kelime');
      expect(candidate, isNotNull);
      expect(candidate!.spoken, 'Merhaba bugün test son kelime');
      expect(dc.isActive, isFalse);
    },
  );

  testWidgets(
    'DictationController: duraklat/devam, dil değişimi ve parça geri alma',
    (tester) async {
      final ctl = WrapTextController(text: '');
      final focus = FocusNode();
      addTearDown(ctl.dispose);
      addTearDown(focus.dispose);
      final target = FormatTarget(
        controller: ctl,
        focusNode: focus,
        commit: () {},
      );

      final localesSeen = <String>[];
      final dc = DictationController(
        resolveTarget: () => target,
        fallbackController: () => ctl,
        isItemTarget: (_, _) => false,
        openItemAfter: (_) => null,
        onCommit: (_, _, _) {},
        onRevealCaret: () {},
        smartCommands: () => true,
        autoStop: () => false,
        preferOffline: () => false,
        silenceAfter: () => const Duration(seconds: 4),
        onError: (_) {},
        onUnavailable: (_) {},
        sessionFactory:
            ({
              required locale,
              required autoStop,
              required preferOffline,
              required gate,
              required onText,
              required onEnd,
              required onError,
              required onUnavailable,
            }) {
              localesSeen.add(locale);
              return _FakeSession(
                locale: locale,
                autoStop: autoStop,
                preferOffline: preferOffline,
                gate: gate,
                onText: onText,
                onEnd: onEnd,
                onError: onError,
                onUnavailable: onUnavailable,
              );
            },
      );
      addTearDown(dc.dispose);

      dc.start(initialLocale: 'tr-TR');
      dc.handleRecognizedText('birinci cümle nokta koy');
      final pauseFuture = dc.pause();
      await tester.pump(const Duration(milliseconds: 25));
      await pauseFuture;
      expect(dc.isPaused, isTrue);
      expect(ctl.logicalText, 'Birinci cümle.');

      dc.resume();
      expect(dc.isListening, isTrue);
      dc.handleRecognizedText('ikinci cümle');
      expect(ctl.logicalText, 'Birinci cümle. İkinci cümle');

      final localeFuture = dc.toggleLocale();
      await tester.pump(const Duration(milliseconds: 25));
      await localeFuture;
      expect(dc.locale, 'en-US');
      expect(dc.localeShortLabel, 'EN');
      expect(localesSeen, ['tr-TR', 'tr-TR', 'en-US']);

      // Etkin/dolu parça yokken undo bir önceki öbeği (" ikinci cümle") kaldırır.
      expect(dc.undoLastChunk(), isTrue);
      expect(ctl.logicalText, 'Birinci cümle.');
    },
  );
}
