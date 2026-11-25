import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/spoken_datetime.dart';
import '../../../core/utils/spoken_repeat.dart';
import '../../ai/data/speech_service.dart';
import '../../settings/settings_providers.dart';
import '../data/notes_repository.dart';
import '../domain/note_type.dart';
import 'notes_providers.dart';

/// Sesli Not Asistanı'nın o anki evresi.
enum VoiceAssistantPhase { idle, processing, done, error }

class VoiceAssistantState {
  const VoiceAssistantState({
    this.phase = VoiceAssistantPhase.idle,
    this.transcript = '',
    this.message = '',
    this.noteId,
  });

  final VoiceAssistantPhase phase;
  final String transcript;
  final String message;
  final String? noteId;

  VoiceAssistantState copyWith({String? message, String? noteId}) =>
      VoiceAssistantState(
        phase: phase,
        transcript: transcript,
        message: message ?? this.message,
        noteId: noteId ?? this.noteId,
      );
}

final voiceAssistantProvider =
    NotifierProvider<VoiceAssistantController, VoiceAssistantState>(
      VoiceAssistantController.new,
    );

/// Sesli not dökümünden cihaz içinde anında not ve hatırlatıcı kurar
/// (sıfır AI maliyeti, Türkçe tarih/saat/tekrar ayrıştırıcısı ile).
class VoiceAssistantController extends Notifier<VoiceAssistantState> {
  @override
  VoiceAssistantState build() => const VoiceAssistantState();

  bool get _busy => state.phase == VoiceAssistantPhase.processing;

  Future<void> composeFromTranscript(
    String text, {
    required String nothingHeardText,
    required String savedText,
    required String Function(Object error) describeError,
    required String genericErrorText,
    String? historyLabel,
  }) async {
    if (_busy) return;
    final transcript = text.trim();
    if (transcript.isEmpty) {
      state = VoiceAssistantState(
        phase: VoiceAssistantPhase.error,
        message: nothingHeardText,
      );
      return;
    }
    state = VoiceAssistantState(
      phase: VoiceAssistantPhase.processing,
      transcript: transcript,
    );
    try {
      final repo = ref.read(notesRepositoryProvider);
      if (repo == null) {
        throw StateError(genericErrorText);
      }
      final id = await repo.createNote(NoteType.text);
      repo.updateFields(id, {'body': transcript});
      final when = parseSpokenDateTimeNow(transcript);
      if (when != null) {
        repo.setReminder(id, when, repeat: spokenRepeatOrNull(transcript, when));
      }
      state = VoiceAssistantState(
        phase: VoiceAssistantPhase.done,
        message: savedText,
        noteId: id,
        transcript: transcript,
      );
      _speakReply(savedText);
      ref.read(focusedNoteProvider.notifier).focus(id);
    } on StateError catch (e) {
      state = VoiceAssistantState(
        phase: VoiceAssistantPhase.error,
        message: e.message.toString(),
      );
    } catch (_) {
      state = VoiceAssistantState(
        phase: VoiceAssistantPhase.error,
        message: genericErrorText,
      );
    }
  }

  void _speakReply(String reply) {
    final text = reply.trim();
    if (text.isEmpty) return;
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return;
    if (!ref.read(assistantVoiceProvider)) return;
    final language = Intl.getCurrentLocale().split(RegExp('[-_]')).first;
    unawaited(
      ref.read(speechProvider.notifier).speak(text, languageCode: language),
    );
  }

  Future<String?> convertTranscriptToNote({required String createdText}) async {
    final text = state.transcript.trim();
    if (text.isEmpty) return null;
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return null;
    final id = await repo.createNote(NoteType.text);
    repo.updateFields(id, {'body': text});
    final when = parseSpokenDateTimeNow(text);
    if (when != null) {
      repo.setReminder(id, when, repeat: spokenRepeatOrNull(text, when));
    }
    state = state.copyWith(noteId: id, message: createdText);
    ref.read(focusedNoteProvider.notifier).focus(id);
    return id;
  }

  void dismiss() {
    if (_busy) return;
    state = const VoiceAssistantState();
  }
}
