/// Web-dışı platformlarda derlenen gövde: hiçbir yerden çağrılmamalı
/// (çağıran taraf zaten `kIsWeb` ile korur), ama koşullu import dalı
/// derlenebilir olsun diye burada da bir imza olmalı.
String createBlobUrl(List<int> bytes, String mimeType) {
  throw UnsupportedError('createBlobUrl yalnız web\'de kullanılabilir.');
}
