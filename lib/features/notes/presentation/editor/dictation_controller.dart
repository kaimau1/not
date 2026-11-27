import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/haptics.dart';
import '../../../../core/utils/dictation_tidy.dart';
import '../../../../core/utils/speech_output.dart' show SpeechOutputController;
import '../../../../core/utils/voice_commands.dart';
import '../../data/device_speech.dart';
import '../../data/voice_listen_session.dart';
import 'format_bar.dart';
import 'text_wrap.dart';

/// Canlı diktenin yaşam evresi.
enum DictationPhase { idle, listening, paused, stopping }

/// Son dikte parçasının sonradan yapay zekâyla düzeltilebilmesi için anlık
/// konum özeti.
typedef DictationFixCandidate = ({
  FormatTarget? target,
  WrapTextController controller,
  int at,
  String spoken,
});

/// Bir dikte öbeğinin geri alınabilir kaydı.
@immutable
class DictationChunkRecord {
  const DictationChunkRecord({
    required this.target,
    required this.controller,
    required this.at,
    required this.length,
    required this.insertedText,
  });

  final FormatTarget? target;
  final WrapTextController controller;
  final int at;
  final int length;
  final String insertedText;
}

typedef DictationSessionFactory = VoiceListenSession Function({
  required String locale,
  required bool Function() autoStop,
  required bool preferOffline,
  required SilenceGate gate,
  required void Function(String text) onText,
  required void Function(VoiceListenEnd reason) onEnd,
  required void Function(String message) onError,
  required void Function(String message) onUnavailable,
});

/// Editör canlı dikte denetleyicisi: ses oturumu, son kelime boşaltma ([stop]),
/// duraklat/devam et, TR/EN dil geçişi ve parça geri alma tek noktada yönetilir.
class DictationController extends ChangeNotifier {
  DictationController({
    required this.resolveTarget,
    required this.fallbackController,
    required this.isItemTarget,
    required this.openItemAfter,
    required this.onCommit,
    required this.onRevealCaret,
    required this.smartCommands,
    required this.autoStop,
    required this.preferOffline,
    required this.silenceAfter,
    required this.onError,
    required this.onUnavailable,
    this.onSaveNow,
    DictationSessionFactory? sessionFactory,
  }) : _sessionFactory = sessionFactory ?? _defaultSessionFactory;

  final FormatTarget? Function() resolveTarget;
  final WrapTextController Function() fallbackController;
  final bool Function(FormatTarget? target, WrapTextController c) isItemTarget;
  final FormatTarget? Function(WrapTextController c) openItemAfter;
  final void Function(
    FormatTarget? target,
    WrapTextController controller,
    String text,
  )
  onCommit;
  final VoidCallback onRevealCaret;
  final bool Function() smartCommands;
  final bool Function() autoStop;
  final bool Function() preferOffline;
  final Duration Function() silenceAfter;
  final void Function(String message) onError;
  final void Function(String message) onUnavailable;
  final VoidCallback? onSaveNow;
  final DictationSessionFactory _sessionFactory;

  static VoiceListenSession _defaultSessionFactory({
    required String locale,
    required bool Function() autoStop,
    required bool preferOffline,
    required SilenceGate gate,
    required void Function(String text) onText,
    required void Function(VoiceListenEnd reason) onEnd,
    required void Function(String message) onError,
    required void Function(String message) onUnavailable,
  }) => VoiceListenSession(
    locale: locale,
    autoStop: autoStop,
    preferOffline: preferOffline,
    // Editör diktesi: Android 13+ otomatik noktalama + büyük harf.
    punctuate: true,
    gate: gate,
    onText: onText,
    onEnd: onEnd,
    onError: onError,
    onUnavailable: onUnavailable,
  );

  final ValueNotifier<double> level = ValueNotifier<double>(0);
  final ValueNotifier<double> silence = ValueNotifier<double>(0);

  VoiceListenSession? _session;
  DictationPhase _phase = DictationPhase.idle;
  String _locale = 'tr-TR';

  /// Dikte başladığı dil (yazım dili); dil düğmesi bununla İngilizce
  /// arasında gidip gelir.
  String _primaryLocale = 'tr-TR';
  DateTime _startedAt = DateTime.now();

  FormatTarget? _target;
  int _at = 0;
  int _length = 0;
  String _shown = '';
  int _line = 0;
  String _preview = '';
  VoiceCommand? _lastCommand;
  int _commandCount = 0;

  final List<DictationChunkRecord> _undoStack = [];
  bool _disposed = false;

  DictationPhase get phase => _phase;
  bool get isActive => _phase != DictationPhase.idle;
  bool get isListening => _phase == DictationPhase.listening;
  bool get isPaused => _phase == DictationPhase.paused;
  bool get isStopping => _phase == DictationPhase.stopping;
  String get locale => _locale;
  String get localeShortLabel => _locale.startsWith('en') ? 'EN' : 'TR';
  DateTime get startedAt => _startedAt;
  String get previewText => _preview;
  VoiceCommand? get lastCommand => _lastCommand;
  bool get canUndo => _undoStack.isNotEmpty || _length > 0;

  void _syncMeters() {
    final s = _session;
    if (s == null) return;
    level.value = s.level.value;
    silence.value = s.silence.value;
  }

  /// Dikteyi başlatır. [initialLocale] belirtilmezse mevcut dil korunur.
  void start({String? initialLocale}) {
    if (_disposed || isActive) return;
    if (initialLocale != null && initialLocale.isNotEmpty) {
      _locale = initialLocale;
      _primaryLocale = initialLocale;
    }
    _startedAt = DateTime.now();
    _undoStack.clear();
    _preview = '';
    _lastCommand = null;
    _commandCount = 0;
    _openSessionAtCurrentTarget();
  }

  void _openSessionAtCurrentTarget() {
    final target = resolveTarget();
    final controller = target?.controller ?? fallbackController();
    final selection = controller.selection;
    final logical = controller.logicalText;
    final rawAt = selection.isValid
        ? wrapToLogicalOffset(controller.text, selection.baseOffset)
        : logical.length;
    _target = target;
    _at = rawAt.clamp(0, logical.length);
    _length = 0;
    _shown = '';
    _line = 0;

    final session = _sessionFactory(
      locale: _locale,
      autoStop: autoStop,
      preferOffline: preferOffline(),
      gate: SilenceGate(afterSpeech: silenceAfter()),
      onText: _onSessionText,
      onEnd: (_) => unawaited(stop()),
      onError: (msg) => unawaited(_failStop(msg)),
      onUnavailable: (msg) => unawaited(_unavailableStop(msg)),
    );
    _detachMeters();
    _session = session;
    session.level.addListener(_syncMeters);
    session.silence.addListener(_syncMeters);
    _phase = DictationPhase.listening;
    notifyListeners();
    onRevealCaret();
    session.start();
  }

  void _detachMeters() {
    final prev = _session;
    if (prev == null) return;
    prev.level.removeListener(_syncMeters);
    prev.silence.removeListener(_syncMeters);
  }

  Future<void> _failStop(String message) async {
    await stop(offerFix: false);
    if (!_disposed) onError(message);
  }

  Future<void> _unavailableStop(String message) async {
    await stop(offerFix: false);
    if (!_disposed) onUnavailable(message);
  }

  /// Etkin oturumdan gelen metni işler; [DictationPhase.stopping] sırasında
  /// son tanıma sonucu da kabul edilir ki son kelimeler düşmesin.
  @visibleForTesting
  void handleRecognizedText(String spoken) => _onSessionText(spoken);

  void _onSessionText(String spoken) {
    if (_disposed) return;
    if (_phase != DictationPhase.listening &&
        _phase != DictationPhase.stopping) {
      return;
    }
    if (spoken.trim().isEmpty) return;

    final target = _target;
    final controller = target?.controller ?? fallbackController();
    final logical = controller.logicalText;

    final merged = dictationMerge(_shown, spoken);
    if (merged == _shown) return;
    _shown = merged;

    var written = merged;
    final smart = smartCommands();
    if (smart) {
      final outcome = applyVoiceCommands(merged);
      written = outcome.text;
      if (outcome.commands > _commandCount) {
        _commandCount = outcome.commands;
        _lastCommand = outcome.last;
        AppHaptics.tick();
      } else if (outcome.commands < _commandCount) {
        _commandCount = outcome.commands;
      }
      if (outcome.stop && _phase == DictationPhase.listening) {
        WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(stop()));
      }
    }

    if (isItemTarget(target, controller)) {
      final lines = written.split('\n');
      if (lines.length <= _line) return;
      var t = target;
      var c = controller;
      while (lines.length - 1 > _line) {
        _replaceRange(t, c, _tidyLine(c, lines[_line], smart));
        final next = openItemAfter(c);
        if (next == null) break;
        t = next;
        c = next.controller;
        _target = t;
        _at = 0;
        _length = 0;
        _line++;
      }
      final line = lines[_line];
      _replaceRange(
        t,
        c,
        smart
            ? _tidyLine(c, line, smart)
            : (_line > 0 ? capitalizeTurkishFirst(line) : line),
      );
      _updatePreview(written);
      onRevealCaret();
      return;
    }

    final start = _at.clamp(0, logical.length);
    // Cihaz içi temizlik (dolgu sesi, noktalama, soru eki, cümle başı):
    // akıllı sesli not açıkken; her olayda ham metinden baştan.
    if (smart) {
      written = tidyDictation(written, before: logical.substring(0, start));
    }
    final result = written.trim().isEmpty
        ? (
            text: logical.replaceRange(
              start,
              (start + _length).clamp(start, logical.length),
              '',
            ),
            caret: start,
            length: 0,
          )
        : dictationReplace(logical, start, _length, written);
    final text = result.text;
    if (text == logical) return;
    _at = start;
    _length = result.length;
    controller.setLogical(text, result.caret);
    onCommit(target, controller, text);
    _updatePreview(written);
    onRevealCaret();
  }

  /// Liste maddesine yazılacak satırın temizliği: madde başıysa büyür,
  /// sondaki tek nokta atılır ([tidyDictation] `item`).
  String _tidyLine(WrapTextController c, String line, bool smart) {
    if (!smart) return line;
    final logical = c.logicalText;
    final at = _at.clamp(0, logical.length);
    return tidyDictation(line, before: logical.substring(0, at), item: true);
  }

  void _replaceRange(
    FormatTarget? target,
    WrapTextController controller,
    String piece,
  ) {
    final logical = controller.logicalText;
    final start = _at.clamp(0, logical.length);
    final result = piece.trim().isEmpty
        ? (
            text: logical.replaceRange(
              start,
              (start + _length).clamp(start, logical.length),
              '',
            ),
            caret: start,
            length: 0,
          )
        : dictationReplace(logical, start, _length, piece);
    final text = result.text;
    if (text == logical) return;
    _at = start;
    _length = result.length;
    controller.setLogical(text, result.caret);
    onCommit(target, controller, text);
  }

  void _updatePreview(String raw) {
    final single = raw.replaceAll('\n', ' ').trim();
    final trimmed = single.length > 52
        ? '…${single.substring(single.length - 51)}'
        : single;
    if (trimmed != _preview) {
      _preview = trimmed;
      notifyListeners();
    }
  }

  void _pushCurrentChunk() {
    final target = _target;
    final controller = target?.controller ?? fallbackController();
    final logical = controller.logicalText;
    final start = _at.clamp(0, logical.length);
    final end = (_at + _length).clamp(start, logical.length);
    if (end <= start) return;
    _undoStack.add(
      DictationChunkRecord(
        target: target,
        controller: controller,
        at: start,
        length: end - start,
        insertedText: logical.substring(start, end),
      ),
    );
  }

  /// Dinlemeyi duraklatır; önce son kelimenin gelmesini bekler.
  Future<void> pause() async {
    if (_disposed || _phase != DictationPhase.listening) return;
    final s = _session;
    _phase = DictationPhase.stopping;
    notifyListeners();
    if (s != null) await s.stop();
    if (_disposed || _phase != DictationPhase.stopping) return;
    _detachMeters();
    _pushCurrentChunk();
    _session = null;
    _at = 0;
    _length = 0;
    _shown = '';
    _line = 0;
    level.value = 0;
    silence.value = 0;
    _phase = DictationPhase.paused;
    notifyListeners();
  }

  /// Duraklatılmış dikteyi aynı notta kaldığı yerden sürdürür.
  void resume() {
    if (_disposed || _phase != DictationPhase.paused) return;
    _openSessionAtCurrentTarget();
  }

  /// Ana dil (yazım dili) ↔ İngilizce konuşma dilini değiştirir.
  Future<void> toggleLocale() async {
    if (_disposed || !isActive) return;
    final nextLocale = SpeechOutputController.alternateSpeechLocale(
      _locale,
      _primaryLocale,
    );
    final wasListening = _phase == DictationPhase.listening;
    if (wasListening) {
      await pause();
    }
    _locale = nextLocale;
    if (wasListening && _phase == DictationPhase.paused) {
      resume();
    } else {
      notifyListeners();
    }
  }

  /// Son konuşulan öbeği nottan geri alır.
  bool undoLastChunk() {
    if (_disposed || !isActive) return false;
    DictationChunkRecord? record;
    if (_length > 0) {
      final t = _target;
      final c = t?.controller ?? fallbackController();
      final logical = c.logicalText;
      final s = _at.clamp(0, logical.length);
      final e = (_at + _length).clamp(s, logical.length);
      if (e > s) {
        record = DictationChunkRecord(
          target: t,
          controller: c,
          at: s,
          length: e - s,
          insertedText: logical.substring(s, e),
        );
      }
      _at = s;
      _length = 0;
      _shown = '';
      _line = 0;
    } else if (_undoStack.isNotEmpty) {
      record = _undoStack.removeLast();
    }
    if (record == null) return false;

    final logical = record.controller.logicalText;
    final start = record.at.clamp(0, logical.length);
    final end = (record.at + record.length).clamp(start, logical.length);
    if (end <= start) return false;
    final next = logical.replaceRange(start, end, '');
    record.controller.setLogical(next, start);
    onCommit(record.target, record.controller, next);
    _preview = '';
    notifyListeners();
    onSaveNow?.call();
    return true;
  }

  /// Dikteyi bitirir: önce son sonucun akıştan gelmesini bekler (`session.stop`),
  /// ardından tüm durum temizlenir ve varsa AI düzeltme adayı döndürülür.
  Future<DictationFixCandidate?> stop({bool offerFix = true}) async {
    if (_disposed || !isActive) return null;
    if (_phase == DictationPhase.stopping) return null;
    final s = _session;
    _phase = DictationPhase.stopping;
    notifyListeners();
    if (s != null) {
      await s.stop();
    }
    if (_disposed) return null;

    _detachMeters();
    DictationFixCandidate? candidate;
    if (offerFix) {
      final target = _target;
      final controller = target?.controller ?? fallbackController();
      final logical = controller.logicalText;
      final start = _at.clamp(0, logical.length);
      final end = (_at + _length).clamp(start, logical.length);
      if (end > start) {
        final spoken = logical.substring(start, end);
        if (spoken.trim().length >= 12) {
          candidate = (
            target: target,
            controller: controller,
            at: start,
            spoken: spoken,
          );
        }
      }
    }

    _session = null;
    _phase = DictationPhase.idle;
    _target = null;
    _at = 0;
    _length = 0;
    _shown = '';
    _line = 0;
    _preview = '';
    _lastCommand = null;
    _commandCount = 0;
    _undoStack.clear();
    level.value = 0;
    silence.value = 0;
    onSaveNow?.call();
    notifyListeners();
    return candidate;
  }

  /// Ekran kapanırken bekletmeden keser.
  void cancelImmediate() {
    _detachMeters();
    _session?.cancel();
    _session = null;
    if (_phase != DictationPhase.idle) {
      unawaited(DeviceSpeech.stop());
    }
    _phase = DictationPhase.idle;
    _target = null;
    _at = 0;
    _length = 0;
    _shown = '';
    _line = 0;
    _preview = '';
    _undoStack.clear();
    level.value = 0;
    silence.value = 0;
  }

  @override
  void dispose() {
    _disposed = true;
    cancelImmediate();
    level.dispose();
    silence.dispose();
    super.dispose();
  }
}
