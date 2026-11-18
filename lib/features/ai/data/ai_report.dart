import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error_log.dart';

final aiReportServiceProvider = Provider<AiReportService>(
  (ref) => const AiReportService(),
);

/// Sorunlu AI çıktısı bildirimi (Google Play üretken AI politikası; PLAN
/// §1.5 PL3 b).
///
/// KİŞİSEL VERİ GÖNDERİLMEZ (PL3, KVKK): eskiden yanıt METNİ
/// `users/{uid}/aiReports`a yazılıyordu — yanıt notun içeriğinden türediği
/// için bu, not içeriğinin sessizce sunucuya kopyalanması demekti. Artık
/// yalnız cihazdaki hata günlüğüne ([ErrorLog]; kendiliğinden hiçbir yere
/// gitmez, Ayarlar → Hakkında → "Hata günlüğünü paylaş" ile kullanıcı
/// gönderir) NEREDEN geldiği ve uzunluğu yazılır, metnin kendisi yazılmaz.
class AiReportService {
  const AiReportService();

  /// Günlük kaydının kaynağı (dışa aktarımda arama için).
  static const logSource = 'ai-report';

  void report({required String content, required String source}) {
    ErrorLog.record(logSource, 'source=$source len=${content.length}');
  }
}
