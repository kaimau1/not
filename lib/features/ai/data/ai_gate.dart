import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../settings/settings_providers.dart';
import 'api_key_store.dart';
import 'gemini_service.dart' show GeminiException;

/// Premium durumu: `users/{uid}` dokümanındaki `premiumUntil` alanı
/// gelecekte bir tarihse kullanıcı premium'dur. Şimdilik alan konsoldan
/// (test için) yazılır; Play Billing entegre olunca satın alma doğrulaması
/// bu alanı sunucu tarafında güncelleyecek.
final premiumProvider = StreamProvider<bool>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(false);
  return FirebaseFirestore.instance
      .collection(AppConstants.usersCollection)
      .doc(uid)
      .snapshots()
      .map((doc) {
        final until = (doc.data()?['premiumUntil'] as Timestamp?)?.toDate();
        return until != null && until.isAfter(DateTime.now());
      });
});

/// AI kullanımının "sınırsız" olup olmadığı: kendi Gemini anahtarını girenler
/// (BYOK, dahili kapıdan hiç geçmez) veya premium kullanıcılar sınırsızdır.
/// Ücretsiz kullanıcıda günlük hak sınırlıdır — bu yüzden otomatik üretilen AI
/// içerikleri (e-posta taraması, öneriler, brifing) onlarda kotayı boşa
/// harcamamak için otomatik değil yalnızca düğmeyle çalışır (bkz. DailyCache).
final aiUnlimitedProvider = Provider<bool>((ref) {
  final hasKey = (ref.watch(geminiApiKeyProvider).value ?? '').isNotEmpty;
  final premium = ref.watch(premiumProvider).value ?? false;
  return hasKey || premium;
});

/// Kota tüketildikçe artan sayaç; Ayarlar'daki "kalan hak" satırını tazeler.
final aiQuotaVersionProvider = NotifierProvider<AiQuotaVersionNotifier, int>(
  AiQuotaVersionNotifier.new,
);

class AiQuotaVersionNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

/// Bugün kalan ücretsiz dahili AI hakkı (yalnızca gösterim için).
final freeAiRemainingProvider = Provider<int>((ref) {
  ref.watch(aiQuotaVersionProvider);
  return ref.watch(aiGateProvider).remainingToday();
});

final aiGateProvider = Provider<AiGate>((ref) => AiGate(ref));

/// Dahili AI kapısı: kendi anahtarını girenler bu kapıdan hiç geçmez
/// (GeminiService anahtar varken REST yolunu kullanır). Anahtarsız
/// kullanıcıda premium serbesttir; değilse günlük ücretsiz hak tüketilir.
///
/// Not: sayaç cihaz yerelindedir (SharedPreferences). Play sürümünde
/// sunucu tarafı doğrulama (App Check + Cloud Functions) eklenecek.
class AiGate {
  AiGate(this._ref);

  final Ref _ref;

  static String _todayKey() {
    final now = DateTime.now();
    return 'ai_free_used_${now.year}-${now.month}-${now.day}';
  }

  int _usedToday() =>
      _ref.read(sharedPreferencesProvider).getInt(_todayKey()) ?? 0;

  /// Bugünkü günlük hak: premium'da [AppConstants.premiumDailyAiCalls],
  /// değilse [AppConstants.freeDailyAiCalls].
  int _dailyLimit() => (_ref.read(premiumProvider).value ?? false)
      ? AppConstants.premiumDailyAiCalls
      : AppConstants.freeDailyAiCalls;

  int remainingToday() {
    final remaining = _dailyLimit() - _usedToday();
    return remaining < 0 ? 0 : remaining;
  }

  /// Dahili AI çağrısı öncesi çağrılır; hak yoksa [GeminiException] fırlatır.
  /// Premium de "sınırsız" değil — dahili AI projenin faturasından ödendiği
  /// için premium'a da günlük tavan uygulanır (kendi anahtarını girenler muaf,
  /// çünkü GeminiService anahtar varken bu kapıya hiç gelmez).
  Future<void> consume() async {
    final premium = _ref.read(premiumProvider).value ?? false;
    final prefs = _ref.read(sharedPreferencesProvider);
    final used = prefs.getInt(_todayKey()) ?? 0;
    final limit = premium
        ? AppConstants.premiumDailyAiCalls
        : AppConstants.freeDailyAiCalls;
    if (used >= limit) {
      throw GeminiException(
        premium
            ? 'Bugünlük premium AI hakkın ($limit) doldu. Yarın yenilenir; '
                  "dilersen Ayarlar'dan kendi Gemini anahtarını girerek "
                  'sınırsız kullanabilirsin.'
            : 'Bugünlük ücretsiz AI hakkın doldu. Yarın yenilenir; dilersen '
                  "Ayarlar'dan kendi Gemini anahtarını girebilir veya "
                  "Premium'a geçebilirsin.",
      );
    }
    await prefs.setInt(_todayKey(), used + 1);
    _ref.read(aiQuotaVersionProvider.notifier).bump();
  }
}
