/// **GERİ BİLDİRİM GÖNDER** (PLAN §1.5 PL15, 16K §8): Ayarlar → Hakkında'daki
/// satır e-posta uygulamasını `mailto:` ile açar. Gövdeye YALNIZ uygulama
/// sürümü, derleme numarası, platform ve işletim sistemi sürümü yazılır —
/// kişisel veri (ad, e-posta, not içeriği, cihaz kimliği) YOK
/// (`test/feedback_mail_test.dart` bekçisi).
///
/// Crashlytics bu işte EKLENMEDİ: çökme raporu anahtarı zaten var
/// (`crash_reporting.dart`); yeni Firebase projesi kurulunca Play'de açılır.
library;

import 'play_build.dart';

/// Destek adresi — TEK SABİT. Şimdilik gizlilik metnindeki iletişim adresi
/// (`PRIVACY_POLICY.md` son satır). Sabah bakılacak: Play için ayrı destek
/// adresi açılacaksa yalnız burası (ve gizlilik metni) değişir.
const String kSupportEmail = 'hekimasistanitr@gmail.com';

/// E-posta gövdesinin teknik bilgi bloğu. [osVersion] boş olabilir (web).
String feedbackTechInfo({
  required String version,
  required String buildNumber,
  required String platform,
  String osVersion = '',
  bool play = PlayBuild.enabled,
}) {
  final os = osVersion.trim();
  return [
    'Sürüm / Version: $version ($buildNumber)${play ? ' · Play' : ''}',
    'Platform: $platform${os.isEmpty ? '' : ' · $os'}',
  ].join('\n');
}

/// `mailto:` adresi. `Uri(queryParameters:)` boşluğu `+` yapar ve çoğu
/// e-posta uygulaması onu olduğu gibi gösterir; bu yüzden `%20` ile elle.
Uri feedbackMailUri({
  required String subject,
  required String prompt,
  required String techInfo,
  String to = kSupportEmail,
}) {
  final body = '$prompt\n\n\n\n—\n$techInfo\n';
  return Uri.parse(
    'mailto:$to'
    '?subject=${Uri.encodeComponent(subject)}'
    '&body=${Uri.encodeComponent(body)}',
  );
}
