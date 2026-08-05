import 'dart:io';

/// build() sıcak yolundaki dosya-varlığı denetimleri için süreç ömürlü
/// önbellek.
///
/// Kart ızgarası her karede ek başına `File(...).existsSync()` çağırıyordu —
/// kaydırma sırasında kart × ek sayısı kadar senkron sistem çağrısı demek.
/// YALNIZ VAR OLAN dosyalar önbelleğe alınır:
/// - Var olan bir ek dosyası uygulama ömründe ancak ek silinirken kaybolur;
///   silen yol [forgetLocalFile] çağırır.
/// - VAR OLMAYAN dosya önbelleğe alınmaz ki indirme/kopyalama bitince ilk
///   yeniden çizimde görünsün (negatif önbellek bayat kalırdı).
final _existsCache = <String>{};

bool localFileExists(String path) {
  if (path.isEmpty) return false;
  if (_existsCache.contains(path)) return true;
  if (File(path).existsSync()) {
    _existsCache.add(path);
    return true;
  }
  return false;
}

/// Dosyayı silen yol, önbellekteki "var" kaydını da düşürmeli.
void forgetLocalFile(String path) => _existsCache.remove(path);
