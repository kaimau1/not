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
  final hasKey = (ref.watch(activeApiKeyProvider).value ?? '').isNotEmpty;
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

/// Bugün kalan ücretsiz dahili AI puanı (yalnızca gösterim için).
final freeAiRemainingProvider = Provider<int>((ref) {
  ref.watch(aiQuotaVersionProvider);
  return ref.watch(aiGateProvider).remainingToday();
});

/// Bir isteğin kaç puana mal olduğunu içeriğinden hesaplar.
///
/// Maliyet çağrı yerlerinde elle belirtilmez: her yeni AI özelliği doğru
/// puanı geçmeyi unutabilirdi. Bunun yerine gönderilen içerik (ek dosya
/// türü + metin uzunluğu) tek yerde ölçülür — faturayı asıl büyüten şey de
/// zaten bu.
class AiCost {
  AiCost._();

  static int forContents(List<Map<String, dynamic>> contents) {
    var points = 1;
    var chars = 0;
    for (final content in contents) {
      for (final part in content['parts'] as List<dynamic>? ?? const []) {
        if (part is! Map) continue;
        final text = part['text'];
        if (text is String) chars += text.length;
        final inline = part['inline_data'] ?? part['inlineData'];
        if (inline is Map) {
          final mime = (inline['mime_type'] ?? inline['mimeType'] ?? '')
              .toString()
              .toLowerCase();
          points += mime.startsWith('image/')
              ? AppConstants.aiPointsPerImage
              : AppConstants.aiPointsPerDocument;
        }
      }
    }
    return points + chars ~/ AppConstants.aiCharsPerPoint;
  }
}

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

  static String _today() {
    final now = DateTime.now();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '${now.year}-$m-$d';
  }

  static String _prefsKey(String day) => 'ai_points_used_$day';

  int _usedToday() =>
      _ref.read(sharedPreferencesProvider).getInt(_prefsKey(_today())) ?? 0;

  /// Bugünkü günlük puan: premium'da [AppConstants.premiumDailyAiPoints],
  /// değilse [AppConstants.freeDailyAiPoints].
  int _dailyLimit() => (_ref.read(premiumProvider).value ?? false)
      ? AppConstants.premiumDailyAiPoints
      : AppConstants.freeDailyAiPoints;

  int remainingToday() {
    final remaining = _dailyLimit() - _usedToday();
    return remaining < 0 ? 0 : remaining;
  }

  /// Dahili AI çağrısı öncesi çağrılır; [cost] puanı kalmadıysa
  /// [GeminiException] fırlatır. Premium de "sınırsız" değil — dahili AI
  /// projenin faturasından ödendiği için premium'a da günlük tavan uygulanır
  /// (kendi anahtarını girenler muaf, çünkü GeminiService anahtar varken bu
  /// kapıya hiç gelmez).
  ///
  /// Sayaç Firestore'da `users/{uid}` altında tutulur: cihaz yereli
  /// (SharedPreferences) uygulama verisi silinince sıfırlanıyor ve her cihaz
  /// kendi hakkını sayıyordu. Cihaz yereli yine yazılır — çevrimdışıyken ve
  /// oturum yokken kapının tümden açılmaması için yedek sayaçtır.
  Future<void> consume([int cost = 1]) async {
    final premium = _ref.read(premiumProvider).value ?? false;
    final limit = premium
        ? AppConstants.premiumDailyAiPoints
        : AppConstants.freeDailyAiPoints;
    final day = _today();
    final prefs = _ref.read(sharedPreferencesProvider);
    final uid = _ref.read(currentUidProvider);

    var used = prefs.getInt(_prefsKey(day)) ?? 0;
    if (uid != null) {
      final remote = await _consumeRemote(uid, day, cost, limit);
      // Sunucu sayacı okunabildiyse o esastır (cihazlar arası ortak).
      if (remote == _remoteDenied) _throwOut(premium, limit);
      if (remote != null) used = remote - cost;
    }
    if (used + cost > limit) _throwOut(premium, limit);
    await prefs.setInt(_prefsKey(day), used + cost);
    _ref.read(aiQuotaVersionProvider.notifier).bump();
  }

  static const int _remoteDenied = -1;

  static Never _throwOut(bool premium, int limit) => throw GeminiException(
    premium
        ? 'Bugünlük premium AI puanın ($limit) doldu. Yarın yenilenir; '
              "dilersen Ayarlar'dan kendi Gemini anahtarını girerek "
              'sınırsız kullanabilirsin.'
        : 'Bugünlük ücretsiz AI puanın doldu. Yarın yenilenir; dilersen '
              "Ayarlar'dan kendi Gemini anahtarını girebilir veya "
              "Premium'a geçebilirsin.",
  );

  /// Sunucu sayacını işlemle (transaction) artırır ve YENİ toplamı döndürür.
  /// Ağ yoksa/işlem başarısızsa null döner — kapı o zaman cihaz yerelindeki
  /// yedek sayaçla çalışır (AI zaten ağsız çalışmadığı için bu yol nadirdir).
  Future<int?> _consumeRemote(String uid, String day, int cost, int limit) async {
    final doc = FirebaseFirestore.instance
        .collection(AppConstants.usersCollection)
        .doc(uid);
    try {
      return await FirebaseFirestore.instance
          .runTransaction<int>((tx) async {
            final snap = await tx.get(doc);
            final usage = snap.data()?['aiUsage'] as Map<String, dynamic>?;
            // Gün değiştiyse sayaç sıfırdan başlar.
            final used = usage?['day'] == day
                ? (usage?['points'] as num?)?.toInt() ?? 0
                : 0;
            final next = used + cost;
            // Tavan aşılıyorsa sayaç ARTIRILMAZ ve çağırana "reddedildi"
            // bildirilir; sayacın kendisini döndürmek, yerel yedek kontrolün
            // hakkı geçirmesine yol açıyordu.
            if (next > limit) return _remoteDenied;
            tx.set(doc, {
              'aiUsage': {'day': day, 'points': next},
            }, SetOptions(merge: true));
            return next;
          })
          .timeout(const Duration(seconds: 8));
    } on Object {
      return null;
    }
  }
}
