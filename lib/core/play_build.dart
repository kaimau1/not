/// **PLAY DERLEMESİ BAYRAĞI** (PLAN §1.5 PL1, 16K rapor E1–E3, §2.6, §4.5).
///
/// `--dart-define=NOTLAR_PLAY=true` ile derlenen sürüm Google Play'e gider;
/// bayraksız derleme (kişisel APK, web) BUGÜNKÜ GİBİ davranır. Bütün Play
/// kapıları YALNIZ burada; özellik dosyaları bu sabitleri okur. Değerler
/// `const` olduğundan Play derlemesinde kapalı dallar Dart ağacından düşer.
///
/// Yerel (Gradle) tarafı — `ACCESS_BACKGROUND_LOCATION` izninin, ONNX yerel
/// kütüphanesinin ve `gmail.readonly` kapsamının pakette/onay ekranında hiç
/// görünmemesi — bu bayrakla OLMAZ; yapılacaklar `docs/play_hazirlik.md`'de.
abstract final class PlayBuild {
  /// Play derlemesi mi.
  static const bool enabled = bool.fromEnvironment('NOTLAR_PLAY');

  /// E1: GitHub Release'ten kendini güncelleme (Play dışı kurulum yönlendirmesi
  /// Play politikasına aykırı). Play'de güncellemeyi mağaza yapar.
  static const bool selfUpdate = !enabled;

  /// E2: Gmail okuma (`gmail.readonly` "kısıtlı" kapsam → yıllık CASA denetimi).
  static const bool gmail = !enabled;

  /// E3: konum hatırlatıcısı (arka plan konumu beyanı + video ister).
  static const bool placeReminders = !enabled;

  /// §2.6: Antalia cihaz içi Türkçe ses (ONNX, ~11 MB yerel kütüphane + model).
  static const bool antaliaVoice = !enabled;

  /// §4.5: YouTube oynatıcısından çıkınca kendiliğinden küçük pencere (PiP).
  /// Elle PiP düğmesi kalır.
  static const bool youtubeAutoPip = !enabled;

  // ── PLAN §1.6 AI-S1 "Play'den kalkanlar" (KARAR kullanıcı 2026-11-17):
  // kişisel APK'da AYNEN kalır, Play derlemesinde gizlenir. E-postadan not
  // (`GeminiService.fromEmail`) Gmail ekranında olduğundan [gmail] kapısıyla
  // zaten gizli.

  /// Podcast (`podcastScript`): belgeyi AI ile anlatıya çevirme + ses dosyası
  /// olarak dışa aktarma. Belgeyi cihaz sesiyle okuma ücretsiz, kalır.
  static const bool aiPodcast = !enabled;

  /// Gemini seslendirme (`TtsEngine.gemini`, `speech`). Cihaz sesi kalır.
  static const bool aiVoice = !enabled;

  /// Video → not (`noteFromVideo`) ve video not satırını AI ile toparlama
  /// (`videoNoteExcerpt`; AI'sız altyazı/transkript kesiti kalır).
  static const bool videoNote = !enabled;
}
