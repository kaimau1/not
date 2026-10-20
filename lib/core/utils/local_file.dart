import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;

/// build() sıcak yolundaki dosya-varlığı denetimleri için süreç ömürlü
/// önbellek.
///
/// Kart ızgarası her karede ek başına `File(...).existsSync()` çağırıyordu —
/// kaydırma sırasında kart × ek sayısı kadar senkron sistem çağrısı demek.
/// YALNIZ VAR OLAN dosyalar önbelleğe alınır:
/// - Var olan bir ek dosyası uygulama ömründe ancak ek silinirken kaybolur;
///   silen yol [forgetLocalFile] çağırır.
/// - VAR OLMAYAN dosya yalnız KISA süre ([_missingTtlMs]) önbellekte (F6.9):
///   buluttan inmemiş ekler (yeni cihaz, "yalnız metin" senkron kipi) için
///   kart/editör her çizimde ve bekleyen yüklemeler her not yayınında
///   senkron sistem çağrısı yapıyordu. Bayat negatif kayıt "görsel
///   görünmüyor" demek: dosyayı yazan yol [forgetLocalFile] çağırır, toplu
///   indirme `localFilesRevisionProvider`ı artırınca hepsi düşer
///   ([forgetMissingLocalFiles]).
final _existsCache = <String>{};

/// Yol → "yok" görüldüğü an (ms).
final _missingCache = <String, int>{};
const _missingTtlMs = 2000;

/// Önbelleğin üst sınırı: yalnız POZİTİF sonuçlar saklanıyor ve girdi sayısı
/// pratikte ek sayısıyla sınırlı, ama uzun oturumda (çok not açıp kapatan
/// kullanıcı) sınırsız büyümesin.
const _maxExistsCache = 512;

bool localFileExists(String path) {
  if (path.isEmpty) return false;
  // Web'de gerçek bir dosya sistemi yok — `dart:io File` çağrısı platforma
  // göre ya `false` döner ya da istisna fırlatır (kullanıcı bulgusu:
  // "masaüstünde webte görseller/PDF görüntülenemiyor, balonlu mod
  // çalışmıyor" — görsel/PDF/balon katmanlarının HEPSİ altta bu fonksiyona
  // dayanıyor, bkz. attachment_strip.dart, note_images.dart,
  // image_viewer.dart, pdf_viewer_screen.dart). Web'de yerel yol zaten hiç
  // yazılmıyor (`appSupportPath` null kalır, bkz. bu dosyanın altı), o
  // yüzden erken `false` hem doğru hem güvenli.
  if (kIsWeb) return false;
  if (_existsCache.contains(path)) return true;
  final now = DateTime.now().millisecondsSinceEpoch;
  final missingAt = _missingCache[path];
  if (missingAt != null && now - missingAt < _missingTtlMs) return false;
  if (File(path).existsSync()) {
    _missingCache.remove(path);
    if (_existsCache.length >= _maxExistsCache) _existsCache.clear();
    _existsCache.add(path);
    return true;
  }
  if (_missingCache.length >= _maxExistsCache) _missingCache.clear();
  _missingCache[path] = now;
  return false;
}

/// Dosyayı silen YA DA yazan yol, önbellekteki kaydı düşürmeli.
void forgetLocalFile(String path) {
  _existsCache.remove(path);
  _missingCache.remove(path);
}

/// Bütün "yok" kayıtları düşer (toplu indirme bitti — bkz.
/// `LocalFilesRevision.bump`).
void forgetMissingLocalFiles() => _missingCache.clear();

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
