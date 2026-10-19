import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/speech_output.dart';
import '../../../core/utils/spoken_datetime.dart';
import '../../ai/data/ai_history.dart';
import '../../ai/data/assistant_service.dart';
import '../../settings/settings_providers.dart';
import '../../ai/data/gemini_service.dart';
import '../data/notes_repository.dart';
import '../domain/note_type.dart';
import 'notes_providers.dart';

/// Sesli Not Asistanı'nın o anki evresi. Ana sayfanın altındaki durum
/// paneli bu evreye göre çizilir.
enum VoiceAssistantPhase { idle, processing, done, error }

class VoiceAssistantState {
  const VoiceAssistantState({
    this.phase = VoiceAssistantPhase.idle,
    this.transcript = '',
    this.message = '',
    this.noteId,
  });

  final VoiceAssistantPhase phase;

  /// Asistana verilen döküm. done evresinde de saklanır: asistan konuşulanı
  /// "not değil" sayıp hiçbir şey oluşturmadığında kullanıcı panelden "yine
  /// de nota dönüştür" diyebilsin (bkz. [VoiceAssistantController.convertTranscriptToNote]).
  final String transcript;

  /// done: asistanın yanıtı; error: hata metni.
  final String message;

  /// Asistanın oluşturduğu/güncellediği notun id'si ("Notu aç" için).
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

/// Sesli not levhasındaki "AI not": dökümden asistan notu kurar — başlık,
/// maddeler ve HATIRLATICI çıkarır.
///
/// SADELEŞTİRME (2026-10-19): bu sınıf eskiden mikrofonu KENDİSİ açıyordu
/// (widget'tan başlayan "bas-başlat" oturumu, kendi tanıma aboneliği,
/// web'de kendi ses kaydı, kendi süre sınırı). Aynı işi yapan sesli not
/// levhasıyla ikiz bir dinleme koduydu; "sessizlikte bitsin" düzeltmesi
/// buraya hiç ulaşmamıştı. Artık dinleme yalnız levhada
/// (`VoiceListenSession`), widget da levhayı açıyor; burada kalan tek iş
/// elde hazır METİNLE notu kurmak. Asıl değer içindeki güvenlik ağlarında:
/// model boş not kurarsa dökümle doldurma, hatırlatıcıyı yerelde çözme
/// (`parseSpokenDateTimeNow`), yapay zekâ tümden ölüyken düz nota düşme.
class VoiceAssistantController extends Notifier<VoiceAssistantState> {
  @override
  VoiceAssistantState build() => const VoiceAssistantState();

  bool get _busy => state.phase == VoiceAssistantPhase.processing;

  /// Levhadan gelen dökümle notu asistana kurdurur. [historyLabel] verilirse
  /// iş bitince "SON İŞLEMLER"e yazılır (yalnız ad, konuşma metni DEĞİL —
  /// bkz. AiHistory).
  Future<void> composeFromTranscript(
    String text, {
    required String nothingHeardText,
    required String savedText,
    required String noApiKeyText,
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
      final service = ref.read(geminiServiceProvider);
      final assistant = ref.read(assistantServiceProvider);
      final notes = ref.read(notesStreamProvider).value ?? const [];
      String? resultNoteId;
      String reply;
      try {
        reply = await service.assistantVoiceNote(
          notesContext: assistant.buildNotesContext(notes),
          transcript: transcript,
          onToolCall: (name, args) async {
            // Sesli akış eller serbest çalışır, onay kutusu gösterilemez;
            // yıkıcı silme burada HİÇ çalışmaz (sohbette onayla çalışıyor).
            // Not içeriğinden gelen bir "talimat" modeli kandırsa bile sesli
            // yoldan not silinemez.
            if (name == 'delete_note') {
              return {
                'status': 'error',
                'message':
                    'Sesli akışta not silinmez; silme sohbetten onayla yapılır',
              };
            }
            final result = await assistant.execute(name, args);
            if (result['noteId'] is String) {
              resultNoteId = result['noteId'] as String;
            }
            return result;
          },
        );
      } catch (e) {
        // AI hiç çalışmıyor olabilir (anahtar yok + dahili AI kapalı + kota
        // bitti). Konuşma yine de KAYBOLMAZ: döküm düz not olur. Eskiden burada yeniden AI'a
        // (transcribeAudio) gidiliyordu — AI ölüyken o çağrı da patlıyor ve
        // konuşma tümden yok oluyordu; kökü buydu.
        //
        // HER hata yakalanır (yalnız GeminiException değil): anahtarsız
        // kullanıcıda ağ/eklenti kaynaklı başka istisnalar da çıkabiliyor ve o
        // yollarda not HİÇ oluşmuyordu — "AI olmasa dahi not oluşmalı".
        // Asistan ZATEN bir not kurduysa yedek yol İKİNCİ bir not kurmaz:
        // araç çağrısı başarılı olup çağrı sonraki turda düşerse (ağ hatası,
        // 6 tur sınırı) aynı konuşmadan iki not oluşuyordu. Notun içeriği
        // eksikse aşağıdaki güvenlik ağı zaten dökümle dolduruyor.
        if (resultNoteId == null) {
          final failure = e is GeminiException
              ? (e.isAuthError ? noApiKeyText : e.message)
              : genericErrorText;
          final repo = ref.read(notesRepositoryProvider);
          if (repo == null) {
            throw StateError(failure);
          }
          final id = await repo.createNote(NoteType.text);
          repo.updateFields(id, {'body': transcript});
          // AI hiç çalışmasa da hatırlatıcı kurulur: zaman ayrıştırması
          // yerelde yapılıyor, modele ihtiyaç yok.
          final when = parseSpokenDateTimeNow(transcript);
          if (when != null) repo.setReminder(id, when);
          resultNoteId = id;
        }
        reply = savedText;
      }

      // Güvenlik ağı: model notu oluşturduğunu söyleyip içeriği eksik
      // bırakabiliyor. Döküm elde olduğundan boş kalan not konuşma metniyle doldurulur — ekstra API çağrısı yok.
      //
      // AI çağrısının TRY'ından ÇIKARILDI: yedek yol artık her hatayı
      // yakalıyor ve burası o try'ın içindeyken kendi hatası (Firestore
      // okuması) yedeği tetikleyip İKİNCİ bir not oluşturabilirdi. Kendi
      // try'ında ve yutulan hatayla: güvenlik ağı çalışmazsa not yine durur.
      try {
        final createdId = resultNoteId;
        if (createdId != null) {
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
              final when = parseSpokenDateTimeNow(transcript);
              if (when != null) repo.setReminder(createdId, when);
            }
          }
        }
      } catch (_) {}

      state = VoiceAssistantState(
        phase: VoiceAssistantPhase.done,
        message: reply,
        noteId: resultNoteId,
        transcript: transcript,
      );
      if (historyLabel != null) {
        ref.read(aiHistoryProvider.notifier).record(historyLabel);
      }
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
    // Ayarlardan (ya da panelin "sustur" düğmesinden) kapatılabilir.
    if (!ref.read(assistantVoiceProvider)) return;
    final language = Intl.getCurrentLocale().split(RegExp('[-_]')).first;
    unawaited(
      ref
          .read(speechOutputProvider.notifier)
          .speak(text, languageCode: language),
    );
  }

  /// Konuşulanı DÜZ NOT olarak kaydeder — asistan not oluşturmadığında.
  ///
  /// Asistan "bu bir yapılacak ya da alışveriş listesi değil" deyip elini
  /// kolunu sallayarak dönebiliyor; konuşan kişi için ise o cümle çoğu zaman
  /// yine de saklanmaya değer. Bu yol modele HİÇ gitmez: eldeki döküm
  /// doğrudan nota yazılır (zaman geçiyorsa hatırlatıcı da yerelde kurulur).
  /// Oluşan notun id'si döner, yoksa null.
  Future<String?> convertTranscriptToNote({required String createdText}) async {
    final text = state.transcript.trim();
    if (text.isEmpty) return null;
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return null;
    final id = await repo.createNote(NoteType.text);
    repo.updateFields(id, {'body': text});
    final when = parseSpokenDateTimeNow(text);
    if (when != null) repo.setReminder(id, when);
    state = state.copyWith(noteId: id, message: createdText);
    ref.read(focusedNoteProvider.notifier).focus(id);
    return id;
  }

  /// done/error panelini kapatır.
  void dismiss() {
    if (_busy) return;
    state = const VoiceAssistantState();
  }
}
