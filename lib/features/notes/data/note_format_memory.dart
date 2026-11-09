import 'package:shared_preferences/shared_preferences.dart';

/// **SON KULLANILAN YAZI BOYUTU / TİPİ** (F56.3, 2026-11-09 — Keep
/// yorumlarındaki şikâyet: "her yeni notta yazı boyutunu baştan ayarlıyorum").
///
/// Kullanıcı bir notun GÖVDESİNİN (başlığın değil, seçili aralığın değil)
/// yazı boyutunu ya da tipini değiştirince cihazda saklanır; yeni metin ve
/// liste notu bu değerlerle doğar. Varsayılana dönünce (boyut 1, tip yok)
/// hafıza da silinir. Cihaz tercihi: Firestore'a yazılmaz.
class NoteFormatMemory {
  NoteFormatMemory._();

  static const _kScale = 'note_last_font_scale';
  static const _kFamily = 'note_last_font_family';

  static SharedPreferences? _prefs;

  /// Yeni notun gövde yazı boyutu (1 = varsayılan).
  static double fontScale = 1;

  /// Yeni notun gövde yazı tipi (null = tema varsayılanı).
  static String? fontFamily;

  static void attach(SharedPreferences prefs) {
    _prefs = prefs;
    final s = prefs.getDouble(_kScale);
    fontScale = s != null && s > 0.4 && s < 4 ? s : 1;
    fontFamily = prefs.getString(_kFamily);
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

  static void rememberFamily(String? family) {
    fontFamily = family;
    final p = _prefs;
    if (p == null) return;
    if (family == null) {
      p.remove(_kFamily);
    } else {
      p.setString(_kFamily, family);
    }
  }

  /// Test için: hafızayı sıfırla.
  static void resetForTest() {
    _prefs = null;
    fontScale = 1;
    fontFamily = null;
  }
}
