import 'package:flutter/material.dart';

/// TEMADAN BAĞIMSIZ, KASITLI renkler (F16.3, 2026-10-31).
///
/// Arayüz rengi (yüzey, yazı, vurgu) `ColorScheme`/`NoteColors`'tan gelir.
/// Burada yalnız temaya göre DEĞİŞMEMESİ gerekenler durur — her biri neden
/// sabit olduğunu söyler. Yeni sabit renk gerekiyorsa önce şemaya bak;
/// gerçekten sabitse buraya ekle, dosyaya `Color(0x…)` yazma.
abstract final class FixedColors {
  /// "Özel renk" dairesinin gökkuşağı halkası: renk seçicinin kendisi, tema
  /// rengi olamaz (dört yerde ayrı ayrı yazılıydı).
  static const rainbowSweep = SweepGradient(
    colors: [
      Color(0xFFE57373),
      Color(0xFFFFD54F),
      Color(0xFF81C784),
      Color(0xFF64B5F6),
      Color(0xFF9575CD),
      Color(0xFFE57373),
    ],
  );

  /// YouTube'un marka kırmızısı (oynat simgesi, rozet).
  static const youtubeRed = Color(0xFFFF0000);

  /// Ek türlerinin renkleri: etiket çipi, ek rozeti, kart satırı aynı türü
  /// aynı renkte gösterir. Koyu temada çağıran açar (`Color.lerp` beyaza).
  static const kindPdf = Color(0xFFD32F2F);
  static const kindImage = Color(0xFF00897B);
  static const kindVideo = Color(0xFF7B1FA2);
  static const kindWebVideo = Color(0xFFAD1457);
  static const kindSlide = Color(0xFFEF6C00);
  static const kindAudio = Color(0xFF1565C0);
  static const kindText = Color(0xFF6D4C41);
  static const kindUnknown = Color(0xFF757575);

  /// Fotoğraf/video üstündeki koyu geçiş: altta yazı okunsun diye. Medya
  /// her temada aynı göründüğü için sabit.
  static const scrimBottom = [Color(0x00000000), Color(0xB3000000)];
  static const scrimTop = [Color(0xCC000000), Color(0x00000000)];

  /// Renkli bir dairenin üstündeki simge/yazı rengi: açık renkte koyu,
  /// koyu renkte beyaz (renk seçicilerde aynı kural dört yerde yazılıydı).
  static Color inkOn(Color background) =>
      background.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;
}
