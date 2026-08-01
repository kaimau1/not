import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../core/utils/speech_output.dart';
import '../../../core/utils/tr_datetime.dart';
import '../../ai/data/assistant_service.dart';
import '../../ai/data/gemini_service.dart';
import '../data/attachment_repository.dart';
import '../data/device_speech.dart';
import '../data/notes_repository.dart';
import '../domain/note_type.dart';
import 'notes_providers.dart';

/// Sesli Not Asistanı'nın o anki evresi. Ana sayfadaki büyük düğme ve
/// alttaki durum paneli bu evreye göre çizilir.
enum VoiceAssistantPhase { idle, recording, processing, done, error }

class VoiceAssistantState {
  const VoiceAssistantState({
    this.phase = VoiceAssistantPhase.idle,
    this.elapsed = Duration.zero,
    this.level = 0,
    this.liveTranscript = '',
    this.message = '',
    this.noteId,
  });

  final VoiceAssistantPhase phase;
  final Duration elapsed;

  /// Anlık ses seviyesi 0–1; düğme halkası bununla büyür (ses algılandığı
  /// buradan görülür).
  final double level;

  /// Konuşmanın canlı dökümü; panelde anlık gösterilir.
  final String liveTranscript;

  /// done: asistanın yanıtı; error: hata metni.
  final String message;

  /// Asistanın oluşturduğu/güncellediği notun id'si ("Notu aç" için).
  final String? noteId;

  VoiceAssistantState copyWith({
    VoiceAssistantPhase? phase,
    Duration? elapsed,
    double? level,
    String? liveTranscript,
    String? message,
    String? noteId,
  }) => VoiceAssistantState(
    phase: phase ?? this.phase,
    elapsed: elapsed ?? this.elapsed,
    level: level ?? this.level,
    liveTranscript: liveTranscript ?? this.liveTranscript,
    message: message ?? this.message,
    noteId: noteId ?? this.noteId,
  );
}

final voiceAssistantProvider =
    NotifierProvider<VoiceAssistantController, VoiceAssistantState>(
      VoiceAssistantController.new,
    );

/// Sesli hızlı not, ekran değiştirmeden ana sayfada çalışır.
///
/// Asıl yol cihazın YERLEŞİK konuşma tanımasıdır: konuşma cihazda anlık
/// metne çevrilir ve asistana yalnızca kısa METİN gider. Bunun üç faydası
/// var: (1) ses göndermeye göre çok daha az token harcanır, (2) tanıma
/// ücretsizdir, (3) elde her zaman bir döküm bulunduğundan asistan notu boş
/// bıraksa bile not doldurulabilir — "oluşturdum diyor ama not yok"
/// sorununun kökü buydu (döküm yalnızca API anahtarı olanlarda vardı).
///
/// Yerleşik tanıma yoksa (Windows) ses kaydedilip asistana gönderilir.
class VoiceAssistantController extends Notifier<VoiceAssistantState> {
  AudioRecorder? _recorder;
  StreamSubscription<({String? text, double? level})>? _speechSub;
  StreamSubscription<Amplitude>? _ampSub;
  Timer? _ticker;
  String _transcript = '';
  String? _filePath;

  /// Okunmuş ama henüz kullanılmamış ses kaydının yolu. AI yolu başarılıysa
  /// [finish] sonunda silinir, düşerse nota ek olarak eklenir.
  String? _audioPath;
  bool _useSpeech = false;

  @override
  VoiceAssistantState build() => const VoiceAssistantState();

  bool get _busy =>
      state.phase == VoiceAssistantPhase.recording ||
      state.phase == VoiceAssistantPhase.processing;

  /// Kaydı başlatır. [micPermissionDeniedText] izin yoksa hata panelinde
  /// gösterilir (l10n çağırandan gelir; controller context taşımaz).
  Future<void> start({
    required String micPermissionDeniedText,
    required String genericErrorText,
  }) async {
    if (_busy) return;
    _transcript = '';
    _filePath = null;
    _audioPath = null;
    state = const VoiceAssistantState(phase: VoiceAssistantPhase.recording);
    try {
      _useSpeech = await DeviceSpeech.isAvailable();
      if (_useSpeech) {
        // İzin yokken SpeechRecognizer sormadan sessizce düşer; önce iste.
        if (!await DeviceSpeech.ensureMicPermission()) {
          await _teardownMic();
          state = VoiceAssistantState(
            phase: VoiceAssistantPhase.error,
            message: micPermissionDeniedText,
          );
          return;
        }
        _speechSub = DeviceSpeech.listen().listen(
          (event) {
            final text = event.text;
            if (text != null) {
              // Tekrarlar köprü katmanında temizlendi (bkz. DeviceSpeech).
              _transcript = text;
              state = state.copyWith(liveTranscript: text);
            }
            final level = event.level;
            if (level != null) state = state.copyWith(level: level);
          },
          onError: (Object _) {
            // Tanıma düşse de biriken metin korunur; "Bitir" ile not oluşur.
          },
        );
      } else {
        await _startRecording(micPermissionDeniedText);
        if (state.phase == VoiceAssistantPhase.error) return;
      }
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        state = state.copyWith(
          elapsed: state.elapsed + const Duration(seconds: 1),
        );
      });
    } catch (_) {
      await _teardownMic();
      state = VoiceAssistantState(
        phase: VoiceAssistantPhase.error,
        message: genericErrorText,
      );
    }
  }

  /// Yerleşik tanıma yoksa: ses dosyaya kaydedilir, bitişte asistana gider.
  Future<void> _startRecording(String micPermissionDeniedText) async {
    final recorder = AudioRecorder();
    _recorder = recorder;
    if (!await recorder.hasPermission()) {
      await _teardownMic();
      state = VoiceAssistantState(
        phase: VoiceAssistantPhase.error,
        message: micPermissionDeniedText,
      );
      return;
    }
    final dir = await getTemporaryDirectory();
    _filePath = p.join(
      dir.path,
      'asistan_${DateTime.now().millisecondsSinceEpoch}.m4a',
    );
    await recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000),
      path: _filePath!,
    );
    _ampSub = recorder
        .onAmplitudeChanged(const Duration(milliseconds: 200))
        .listen((a) {
          // dBFS: 0 en yüksek, -50 ve altı sessizlik sayılır.
          state = state.copyWith(
            level: ((a.current + 50) / 50).clamp(0.0, 1.0),
          );
        });
  }

  /// Kaydı bitirir ve asistana gönderir. Çok kısa kayıtlar (yanlışlıkla
  /// dokunma) sessizce iptal edilir; false döner ki arayüz ipucu gösterebilsin.
  /// [genericErrorText] beklenmeyen hatalarda ham istisna metni yerine
  /// gösterilir (kullanıcıya "Exception: ..." dökülmesin).
  Future<bool> finish({
    required String nothingHeardText,
    required String savedText,
    required String noApiKeyText,
    required String genericErrorText,
  }) async {
    if (state.phase != VoiceAssistantPhase.recording) return true;
    if (state.elapsed < const Duration(seconds: 1) && _transcript.isEmpty) {
      await cancel();
      return false;
    }
    state = state.copyWith(phase: VoiceAssistantPhase.processing, level: 0);
    try {
      // Yerleşik tanımada son sonucun gelmesi için kısa bir an bekle.
      Uint8List? audio;
      String? mimeType;
      if (_useSpeech) {
        await DeviceSpeech.stop();
        await Future<void>.delayed(const Duration(milliseconds: 300));
      } else {
        final collected = await _collectAudio();
        audio = collected.$1;
        mimeType = collected.$2;
      }
      final transcript = _transcript.trim();
      await _teardownMic();

      if (_useSpeech && transcript.isEmpty) {
        state = VoiceAssistantState(
          phase: VoiceAssistantPhase.error,
          message: nothingHeardText,
        );
        return true;
      }

      final service = ref.read(geminiServiceProvider);
      final assistant = ref.read(assistantServiceProvider);
      final notes = ref.read(notesStreamProvider).value ?? const [];
      String? resultNoteId;
      String reply;
      try {
        reply = await service.assistantVoiceNote(
          notesContext: assistant.buildNotesContext(notes),
          transcript: transcript.isEmpty ? null : transcript,
          audioBytes: audio,
          mimeType: mimeType,
          onToolCall: (name, args) async {
            final result = await assistant.execute(name, args);
            if (name != 'delete_note' && result['noteId'] is String) {
              resultNoteId = result['noteId'] as String;
            }
            return result;
          },
        );

        // Güvenlik ağı: model notu oluşturduğunu söyleyip içeriği eksik
        // bırakabiliyor. Döküm elde olduğundan (yerleşik tanımada her zaman)
        // boş kalan not konuşma metniyle doldurulur — ekstra API çağrısı yok.
        final createdId = resultNoteId;
        if (createdId != null && transcript.isNotEmpty) {
          final repo = ref.read(notesRepositoryProvider);
          final created = await repo?.watchNote(createdId).first;
          if (repo != null && created != null) {
            if (created.isEmpty) {
              repo.updateFields(createdId, {'body': transcript});
            }
            // İkinci güvenlik ağı: "yarın sabah 9'da toplantım var" gibi
            // BİLDİRİM cümlelerinde model reminderAt'i doldurmayı atlıyordu
            // (alan şemada isteğe bağlı). Model kurmadıysa zaman dökümden
            // yerelde çıkarılır — hatırlatıcı modelin keyfine kalmaz.
            if (created.reminderAt == null) {
              final when = parseTurkishDateTime(transcript);
              if (when != null) repo.setReminder(createdId, when);
            }
          }
        }
      } on GeminiException catch (e) {
        // AI hiç çalışmıyor olabilir (anahtar yok + dahili AI kapalı + kota
        // bitti). Kayıt yine de KAYBOLMAZ: döküm varsa düz not olur, yoksa
        // ses kaydı nota EK olarak eklenir. Eskiden burada yeniden AI'a
        // (transcribeAudio) gidiliyordu — AI ölüyken o çağrı da patlıyor ve
        // konuşma tümden yok oluyordu; kökü buydu.
        final audioPath = _audioPath;
        if (transcript.isEmpty && audioPath == null) {
          throw StateError(nothingHeardText);
        }
        final repo = ref.read(notesRepositoryProvider);
        if (repo == null) {
          throw StateError(e.isAuthError ? noApiKeyText : e.message);
        }
        final id = await repo.createNote(NoteType.text);
        if (transcript.isNotEmpty) {
          repo.updateFields(id, {'body': transcript});
          // AI hiç çalışmasa da hatırlatıcı kurulur: zaman ayrıştırması
          // yerelde yapılıyor, modele ihtiyaç yok.
          final when = parseTurkishDateTime(transcript);
          if (when != null) repo.setReminder(id, when);
        } else {
          final attachments = ref.read(attachmentRepositoryProvider);
          if (attachments == null) {
            throw StateError(e.isAuthError ? noApiKeyText : e.message);
          }
          final attachment = await attachments.prepareAudio(
            noteId: id,
            sourcePath: audioPath!,
            duration: state.elapsed,
          );
          // prepareAudio kaynağı kendi klasörüne TAŞIR; artık silinmemeli.
          _audioPath = null;
          repo.updateFields(id, {
            'attachments': [attachment.toMap()],
          });
        }
        resultNoteId = id;
        reply = savedText;
      }

      state = VoiceAssistantState(
        phase: VoiceAssistantPhase.done,
        message: reply,
        noteId: resultNoteId,
      );
      _speakReply(reply);
      // İşin ilgili olduğu not varsa ana ekran ona kaydırıp vurgular:
      // asistan "ekledim" diyor ama hangi nota eklediği görünmüyordu.
      final focusId = resultNoteId;
      if (focusId != null) {
        ref.read(focusedNoteProvider.notifier).focus(focusId);
      }
    } on GeminiException catch (e) {
      state = VoiceAssistantState(
        phase: VoiceAssistantPhase.error,
        message: e.isAuthError ? noApiKeyText : e.message,
      );
    } on StateError catch (e) {
      // Bilinçli fırlatılan Türkçe mesajlar ("konuşma algılanmadı" vb.).
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
    // Nota eklenmediyse geçici kayıt burada temizlenir (her yoldan geçilir).
    final leftover = _audioPath;
    _audioPath = null;
    if (leftover != null) File(leftover).delete().ignore();
    return true;
  }

  /// Asistanın YANITINI sesli okur — yalnız telefonda.
  ///
  /// Önce yalnız soru cümleleri okunuyordu; oysa asıl gereken tam tersiymiş:
  /// kullanıcı bir şey SORDUĞUNDA (ör. "markette ne alacaktım?") asistan
  /// cevabı üretiyor ama sessiz kalıyordu — eller meşgulken asistanın bütün
  /// anlamı buydu. Artık her yanıt okunur.
  ///
  /// Masaüstü/web sessiz kalır (kullanıcı isteği: "sadece ve sadece mobilde
  /// konuşsun"); orada ekran zaten göz önünde ve ortam paylaşımlı olabilir.
  void _speakReply(String reply) {
    final text = reply.trim();
    if (text.isEmpty) return;
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return;
    final language = Intl.getCurrentLocale().split(RegExp('[-_]')).first;
    unawaited(
      ref
          .read(speechOutputProvider.notifier)
          .speak(text, languageCode: language),
    );
  }

  /// Kaydı iptal eder, hiçbir şey gönderilmez.
  Future<void> cancel() async {
    await _teardownMic();
    state = const VoiceAssistantState();
  }

  /// done/error panelini kapatır.
  void dismiss() {
    if (_busy) return;
    state = const VoiceAssistantState();
  }

  /// Kaydı okur. Dosya BURADA silinmez: AI düşerse aynı kayıt nota ek olarak
  /// eklenecek ([_audioPath]); iş bittiğinde [finish] artanı temizler.
  Future<(Uint8List, String)> _collectAudio() async {
    final path = await _recorder?.stop();
    final file = File(path ?? _filePath ?? '');
    final bytes = await file.readAsBytes();
    _audioPath = file.path;
    return (bytes, 'audio/mp4');
  }

  Future<void> _teardownMic() async {
    _ticker?.cancel();
    _ticker = null;
    await _ampSub?.cancel();
    _ampSub = null;
    await _speechSub?.cancel();
    _speechSub = null;
    try {
      final path = await _recorder?.stop();
      // İptalde dosya yolu kaydı varsa artık dosyayı temizle.
      if (path != null) File(path).delete().ignore();
    } catch (_) {}
    _recorder?.dispose();
    _recorder = null;
  }
}
