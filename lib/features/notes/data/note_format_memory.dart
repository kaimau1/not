import 'package:shared_preferences/shared_preferences.dart';

/// **SON KULLANILAN YAZI BOYUTU** (F56.3, 2026-11-09 — Keep
/// yorumlarındaki şikâyet: "her yeni notta yazı boyutunu baştan ayarlıyorum").
///
/// Kullanıcı bir notun GÖVDESİNİN (başlığın değil, seçili aralığın değil)
/// yazı boyutunu değiştirince cihazda saklanır; yeni metin ve liste notu bu
/// boyutla doğar. Varsayılana dönünce (boyut 1) hafıza da silinir. Cihaz
/// tercihi: Firestore'a yazılmaz.
///
/// YAZI TİPİ HATIRLANMAZ (kullanıcı kararı 2026-11-22): notun içinde seçilen
/// tip yalnız o nota aittir, her yeni not varsayılan tiple doğar. Varsayılanı
/// değiştirmek isteyen Ayarlar → Görünüm'deki uygulama yazı tipini seçer.
/// Eski sürümlerin sakladığı tip [attach]'te silinir.
class NoteFormatMemory {
  NoteFormatMemory._();

  static const _kScale = 'note_last_font_scale';
  static const _kFamily = 'note_last_font_family';
  static const _kColor = 'note_favorite_text_color';

  /// Hızlı satırın Renk düğmesinin FAVORİ yazı rengi (2026-11-09): palet
  /// sırası (1 = kırmızı, varsayılan) ya da özel renk ARGB'si (bkz.
  /// `isCustomRichColor`). Basılı tutup seçilen renk favori olur.
  static int favoriteColor = 1;

  static SharedPreferences? _prefs;

  /// Yeni notun gövde yazı boyutu (1 = varsayılan).
  static double fontScale = 1;

  static void attach(SharedPreferences prefs) {
    _prefs = prefs;
    final s = prefs.getDouble(_kScale);
    fontScale = s != null && s > 0.4 && s < 4 ? s : 1;
    // Eski sürümün "son yazı tipi" hafızası: artık kullanılmıyor.
    if (prefs.containsKey(_kFamily)) prefs.remove(_kFamily);
    favoriteColor = prefs.getInt(_kColor) ?? 1;
  }

  static void rememberFavoriteColor(int index) {
    favoriteColor = index;
    _prefs?.setInt(_kColor, index);
  }

  static void rememberScale(double value) {
    if (value <= 0.4 || value >= 4) return;
    fontScale = value;
    final p = _prefs;
    if (p == null) return;
    if ((value - 1).abs() < 0.001) {
      p.remove(_kScale);
    } else {
      p.setDouble(_kScale, value);
    }
  }

  /// Test için: hafızayı sıfırla.
  static void resetForTest() {
    _prefs = null;
    fontScale = 1;
    favoriteColor = 1;
  }
}
