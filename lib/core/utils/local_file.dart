import 'dart:io';

import 'package:path/path.dart' as p;

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

/// Uygulama destek klasörü — main() açılışta doldurur (web'de null kalır).
///
/// Ekin cihazdaki yolu BURADAN TÜRETİLİR, artık Firestore'a yazılmaz:
/// mutlak yerel yol (Windows'ta gerçek kullanıcı adını içerir) buluta
/// senkronlanıyordu ve başka cihazda zaten anlamsızdı. Depo katmanı da aynı
/// kalıpla yazar (bkz. AttachmentRepository._store):
/// `<base>/attachments/<noteId>/<ekId>_<dosyaAdı>`.
String? appSupportPath;

/// [noteId] içindeki [attachmentId] ekinin cihazdaki beklenen yolu; taban
/// bilinmiyorsa (web, testler) ya da kimlikler boşsa ''.
String derivedAttachmentPath({
  required String noteId,
  required String attachmentId,
  required String fileName,
}) {
  final base = appSupportPath;
  if (base == null || noteId.isEmpty || attachmentId.isEmpty) return '';
  return p.join(
    base,
    'attachments',
    noteId,
    '${attachmentId}_${p.basename(fileName)}',
  );
}
