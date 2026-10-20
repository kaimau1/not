import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences'ın kabaca bellek ayak izi (F7.4). Açılışta
/// `getInstance` BÜTÜN anahtarları belleğe alır; büyük değer buraya değil
/// dosyaya yazılmalı (ör. ek metni indeksi, F6.3). Yalnız hata ayıklama
/// derlemesinde günlüğe yazılır.
({int totalChars, List<MapEntry<String, int>> largest}) prefsFootprint(
  SharedPreferences prefs, {
  int top = 5,
}) {
  final sizes = <String, int>{};
  for (final key in prefs.getKeys()) {
    sizes[key] = key.length + _charsOf(prefs.get(key));
  }
  final sorted = sizes.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return (
    totalChars: sizes.values.fold(0, (a, b) => a + b),
    largest: sorted.take(top).toList(),
  );
}

int _charsOf(Object? value) => switch (value) {
  String s => s.length,
  List l => l.fold(0, (sum, e) => sum + '$e'.length),
  null => 0,
  _ => 8,
};
