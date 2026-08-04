/// Bayt sayısını insan okuyabilir kısa metne çevirir ("48,2 MB").
///
/// Tek yerde: depolama tavanı hem editör uyarısında hem Ayarlar'daki
/// göstergede aynı biçimde görünmeli.
library;

const int _kb = 1024;
const int _mb = 1024 * 1024;
const int _gb = 1024 * 1024 * 1024;

/// [bytes] için "12 KB" / "48,2 MB" / "2 GB" biçiminde metin.
///
/// Ondalık AYIRICI virgüldür: uygulamanın taban dili Türkçe ve sayı diğer
/// dillerin çoğunda da virgülle yazılıyor. Tam sayı çıkan değerlerde ondalık
/// hiç yazılmaz ("2 GB", "50 MB") — tavanlar hep yuvarlak sayılar.
String formatBytes(int bytes) {
  if (bytes < 0) return '0 KB';
  final (value, unit) = switch (bytes) {
    >= _gb => (bytes / _gb, 'GB'),
    >= _mb => (bytes / _mb, 'MB'),
    _ => (bytes / _kb, 'KB'),
  };
  // KB'de ondalık gereksiz gürültü (küçük ekler zaten "0,4 MB" değil "412 KB"
  // olarak okunuyor).
  if (unit == 'KB') return '${value.round()} KB';
  final rounded = (value * 10).round() / 10;
  final text = rounded == rounded.roundToDouble()
      ? rounded.round().toString()
      : rounded.toStringAsFixed(1).replaceAll('.', ',');
  return '$text $unit';
}
