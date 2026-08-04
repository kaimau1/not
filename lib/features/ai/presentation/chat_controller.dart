import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/tr_datetime.dart';
import '../../notes/data/notes_repository.dart';
import '../data/ai_history.dart';
import '../data/assistant_service.dart';
import '../data/gemini_service.dart';

/// Notlarla sohbetin durumu — TEK yerde tutulur.
///
/// Sohbet artık iki yerde birden görünüyor: Yapay Zeka sayfasındaki kart
/// (soru orada başlar) ve tam ekran sohbet. İkisi aynı geçmişi paylaşmasa
/// kullanıcı "tam ekran"a geçince yazdıkları kaybolurdu; bu yüzden geçmiş
/// ekranın kendi `State`inden çıkarılıp sağlayıcıya taşındı.
class ChatState {
  const ChatState({this.turns = const [], this.busy = false});

  final List<ChatTurn> turns;
  final bool busy;

  ChatState copyWith({List<ChatTurn>? turns, bool? busy}) =>
      ChatState(turns: turns ?? this.turns, busy: busy ?? this.busy);
}

final chatProvider = NotifierProvider<ChatController, ChatState>(
  ChatController.new,
);

class ChatController extends Notifier<ChatState> {
  @override
  ChatState build() => const ChatState();

  void clear() => state = const ChatState();

  /// Kullanıcı sorusunu gönderir ve yanıtı geçmişe ekler.
  ///
  /// Hata metinleri PARAMETRE olarak geliyor: denetleyicinin `BuildContext`i
  /// yok, yerelleştirmeyi çağıran ekran çözer.
  /// [historyLabel] "SON İŞLEMLER" listesine yazılacak ad ("Soru"). Metnin
  /// KENDİSİ yazılmaz — geçmişte kişisel veri tutulmuyor (bkz. AiHistory).
  Future<void> send(
    String text, {
    required String noApiKeyText,
    required String Function(String) errorText,
    String? historyLabel,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.busy) return;
    state = state.copyWith(
      turns: [...state.turns, ChatTurn(isUser: true, text: trimmed)],
      busy: true,
    );
    try {
      final notes = ref.read(notesStreamProvider).value ?? const [];
      final assistant = ref.read(assistantServiceProvider);
      String? createdNoteId;
      final reply = await ref
          .read(geminiServiceProvider)
          .assistantChat(
            notesContext: assistant.buildNotesContext(notes),
            history: List.of(state.turns),
            onToolCall: (name, args) async {
              final result = await assistant.execute(name, args);
              if (name != 'delete_note' && result['noteId'] is String) {
                createdNoteId = result['noteId'] as String;
              }
              return result;
            },
          );
      await _ensureReminder(createdNoteId, trimmed);
      _addReply(reply);
      // Yalnız BAŞARILI iş geçmişe girer: hata alan bir istek "yapılan iş"
      // değil, kullanıcı onu zaten ekranda gördü.
      if (historyLabel != null) {
        ref.read(aiHistoryProvider.notifier).record(historyLabel);
      }
    } on GeminiException catch (e) {
      _addReply(e.isAuthError ? noApiKeyText : errorText(e.message));
    } catch (e) {
      _addReply(errorText('$e'));
    } finally {
      state = state.copyWith(busy: false);
    }
  }

  void _addReply(String text) {
    state = state.copyWith(
      turns: [...state.turns, ChatTurn(isUser: false, text: text)],
    );
  }

  /// Güvenlik ağı: "yarın 9'a diş randevusu notu ekle" gibi cümlelerde model
  /// notu oluşturup `reminderAt`'i doldurmayı atlayabiliyor (alan şemada
  /// isteğe bağlı). Model kurmadıysa zaman kullanıcının kendi cümlesinden
  /// YERELDE çıkarılır — hatırlatıcı modelin keyfine kalmaz, ekstra API
  /// çağrısı da olmaz. Sesli asistandaki ağın aynısı; ayrıştırıcı şimdilik
  /// yalnız Türkçe, diğer dillerde null döner ve davranış eskisi gibi kalır.
  Future<void> _ensureReminder(String? noteId, String source) async {
    if (noteId == null) return;
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;
    final note = await repo.watchNote(noteId).first;
    if (note == null || note.reminderAt != null) return;
    final when = parseTurkishDateTime(source);
    if (when != null) repo.setReminder(noteId, when);
  }
}
