import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../core/utils/pcm_wav.dart';
import '../../ai/data/api_key_store.dart';
import '../../ai/data/assistant_service.dart';
import '../../ai/data/gemini_service.dart';
import '../../ai/data/live_dictation_session.dart';
import '../data/notes_repository.dart';
import '../domain/note_type.dart';

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

  /// Gemini API anahtarı varsa konuşmanın canlı dökümü buraya akar ve
  /// panelde anlık gösterilir.
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
  }) =>
      VoiceAssistantState(
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

/// Sesli hızlı not, ekran değiştirmeden ana sayfada çalışır: kayıt sürerken
/// (anahtar varsa) konuşma canlı yazıya dökülür; bitince ses asistana gider
/// ve uygun not (metin/liste, gerekirse hatırlatıcılı) kendiliğinden oluşur.
///
/// İki ses yolu vardır:
/// - Anahtar VARSA: mikrofon 16 kHz PCM akışı olarak açılır; aynı akış hem
///   Gemini Live dikte oturumuna (canlı döküm) gider hem bellekte biriktirilir
///   ve bitişte WAV'a sarılıp asistana verilir — tek kayıt, iki iş.
/// - Anahtar YOKSA: m4a dosyasına kaydedilir (canlı döküm olmaz), bitişte
///   dosya asistana gider.
class VoiceAssistantController extends Notifier<VoiceAssistantState> {
  AudioRecorder? _recorder;
  StreamSubscription<Uint8List>? _micSub;
  StreamSubscription<Amplitude>? _ampSub;
  Timer? _ticker;
  LiveDictationSession? _dictation;
  final _pcm = BytesBuilder();
  final _live = StringBuffer();
  String? _filePath;
  bool _liveMode = false;

  @override
  VoiceAssistantState build() => const VoiceAssistantState();

  bool get _busy =>
      state.phase == VoiceAssistantPhase.recording ||
      state.phase == VoiceAssistantPhase.processing;

  /// Kaydı başlatır. [micPermissionDeniedText] izin yoksa hata panelinde
  /// gösterilir (l10n çağırandan gelir; controller context taşımaz).
  Future<void> start({required String micPermissionDeniedText}) async {
    if (_busy) return;
    _pcm.clear();
    _live.clear();
    _filePath = null;
    _liveMode = false;
    state = const VoiceAssistantState(phase: VoiceAssistantPhase.recording);
    try {
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

      final apiKey = await ref.read(apiKeyStoreProvider).read();
      if (apiKey != null && apiKey.isNotEmpty) {
        _liveMode = true;
        // Mikrofonu HEMEN başlat: dikte oturumu kurulurken (birkaç yüz ms)
        // konuşulan ilk kelimeler kaçmasın diye ses anında _pcm'de birikir.
        // Bağlantı beklemeden akış açıldığından döküm de daha erken başlar
        // (madde 11 — "ilk kelimeyi kaçırıyor, geç gösteriyor").
        final micStream = await recorder.startStream(
          const RecordConfig(
            encoder: AudioEncoder.pcm16bits,
            sampleRate: 16000,
            numChannels: 1,
          ),
        );
        _micSub = micStream.listen((chunk) {
          _pcm.add(chunk);
          _dictation?.sendAudio(chunk);
        });
        // Dikte oturumunu arka planda bağla; kayıt zaten akıyor. Bağlanınca o
        // ana dek biriken sesi topluca gönder ki ilk kelimeler de dökülsün.
        // Oturum kurulamazsa sessizce canlı döküm olmadan devam edilir.
        final dictation = LiveDictationSession(
          onTranscript: (text) {
            _live.write(text);
            state = state.copyWith(liveTranscript: _live.toString());
          },
          onError: (_) {},
        );
        unawaited(
          dictation.connect(apiKey).then((_) {
            // Kayıt bu arada bittiyse (teardown) oturumu boşuna tutma.
            if (_recorder == null) {
              dictation.close();
              return;
            }
            dictation.sendAudio(_pcm.toBytes());
            _dictation = dictation;
          }).catchError((_) => dictation.close()),
        );
      } else {
        final dir = await getTemporaryDirectory();
        _filePath = p.join(
          dir.path,
          'asistan_${DateTime.now().millisecondsSinceEpoch}.m4a',
        );
        await recorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000),
          path: _filePath!,
        );
      }

      _ampSub = recorder
          .onAmplitudeChanged(const Duration(milliseconds: 200))
          .listen((a) {
        // dBFS: 0 en yüksek, -50 ve altı sessizlik sayılır.
        final level = ((a.current + 50) / 50).clamp(0.0, 1.0);
        state = state.copyWith(level: level);
      });
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        state =
            state.copyWith(elapsed: state.elapsed + const Duration(seconds: 1));
      });
    } catch (e) {
      await _teardownMic();
      state = VoiceAssistantState(
        phase: VoiceAssistantPhase.error,
        message: e.toString(),
      );
    }
  }

  /// Kaydı bitirir ve asistana gönderir. Çok kısa kayıtlar (yanlışlıkla
  /// dokunma) sessizce iptal edilir; false döner ki arayüz ipucu gösterebilsin.
  Future<bool> finish({
    required String nothingHeardText,
    required String savedText,
    required String noApiKeyText,
  }) async {
    if (state.phase != VoiceAssistantPhase.recording) return true;
    if (state.elapsed < const Duration(seconds: 1) && _live.isEmpty) {
      await cancel();
      return false;
    }
    final liveTranscript = _live.toString();
    state = state.copyWith(
      phase: VoiceAssistantPhase.processing,
      level: 0,
    );
    try {
      final (bytes, mimeType) = await _collectAudio();
      await _teardownMic();

      final service = ref.read(geminiServiceProvider);
      final assistant = ref.read(assistantServiceProvider);
      final notes = ref.read(notesStreamProvider).value ?? const [];
      String? resultNoteId;
      String reply;
      try {
        // Tek çağrı: ses doğrudan asistana gider (ayrı transkripsiyon yok).
        reply = await service.assistantVoiceNote(
          notesContext: assistant.buildNotesContext(notes),
          audioBytes: bytes,
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
        // bırakabiliyor. Elde canlı döküm varsa ve oluşan not boşsa, notu
        // konuşma metniyle doldur (ekstra API çağrısı yok).
        final createdId = resultNoteId;
        if (createdId != null && liveTranscript.trim().isNotEmpty) {
          final repo = ref.read(notesRepositoryProvider);
          final created = await repo?.watchNote(createdId).first;
          if (repo != null && created != null && created.isEmpty) {
            repo.updateFields(createdId, {'body': liveTranscript.trim()});
          }
        }
      } on GeminiException catch (e) {
        // Asistan başarısız olursa eski yol: canlı döküm zaten varsa onu,
        // yoksa toplu transkripsiyonu düz not olarak kaydet.
        final transcript = liveTranscript.trim().isNotEmpty
            ? liveTranscript.trim()
            : (await service.transcribeAudio(bytes, mimeType)).trim();
        if (transcript.isEmpty) throw StateError(nothingHeardText);
        final repo = ref.read(notesRepositoryProvider);
        if (repo == null) {
          throw StateError(e.isAuthError ? noApiKeyText : e.message);
        }
        final id = await repo.createNote(NoteType.text);
        repo.updateFields(id, {'body': transcript});
        resultNoteId = id;
        reply = savedText;
      }

      state = VoiceAssistantState(
        phase: VoiceAssistantPhase.done,
        message: reply,
        noteId: resultNoteId,
      );
    } on GeminiException catch (e) {
      state = VoiceAssistantState(
        phase: VoiceAssistantPhase.error,
        message: e.isAuthError ? noApiKeyText : e.message,
      );
    } catch (e) {
      state = VoiceAssistantState(
        phase: VoiceAssistantPhase.error,
        message: e.toString(),
      );
    }
    return true;
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

  /// Kayıt yoluna göre asistana gidecek (ses, mimeType) çiftini toplar.
  Future<(Uint8List, String)> _collectAudio() async {
    if (_liveMode) {
      await _micSub?.cancel();
      _micSub = null;
      try {
        await _recorder?.stop();
      } catch (_) {}
      return (pcmToWav(_pcm.takeBytes(), sampleRate: 16000), 'audio/wav');
    }
    final path = await _recorder?.stop();
    final file = File(path ?? _filePath ?? '');
    final bytes = await file.readAsBytes();
    file.delete().ignore();
    return (bytes, 'audio/mp4');
  }

  Future<void> _teardownMic() async {
    _ticker?.cancel();
    _ticker = null;
    await _ampSub?.cancel();
    _ampSub = null;
    await _micSub?.cancel();
    _micSub = null;
    try {
      final path = await _recorder?.stop();
      // İptalde dosya yolu kaydı varsa artık dosyayı temizle.
      if (path != null) File(path).delete().ignore();
    } catch (_) {}
    _recorder?.dispose();
    _recorder = null;
    await _dictation?.close();
    _dictation = null;
  }
}
