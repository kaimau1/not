import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Belge seçimi — Android'de **uygulama seçiciyle**.
///
/// KÖK NEDEN (kullanıcı bulgusu 2026-08-09: "belge seçileceği zaman bu sayfa
/// açılıyor, dosya tarayıcısını seçebilmeliyim"): `file_selector` Android'de
/// `ACTION_OPEN_DOCUMENT` kullanır. O niyeti yalnızca sistemin belge arayüzü
/// (DocumentsUI) karşılar; açılan çekmecede ancak bir *DocumentsProvider*
/// yazmış olan sağlayıcılar (cihaz deposu, Drive, OneDrive) görünür.
/// Telefonun kendi dosya yöneticisi uygulaması oraya hiç düşmez, dolayısıyla
/// seçilemezdi.
///
/// Buradaki yol `ACTION_GET_CONTENT`i `Intent.createChooser` ile açar: sıradan
/// bir "hangi uygulamayla?" seçimi olur — DocumentsUI listede KALIR, yanına
/// dosya yöneticileri, galeri ve bulut istemcileri gelir.
///
/// Dönüş her platformda [XFile]: çağıranlar `path` / `name` / `readAsBytes`
/// bekliyor ve Android tarafı seçilen içeriği önbelleğe kopyalayıp gerçek bir
/// yol veriyor (içerik URI izni yalnız o niyet boyunca geçerli — kopyalanmazsa
/// dosya bir sonraki karede okunamaz hâle gelirdi).
///
/// Köprü bulunamaz ya da hiçbir uygulama niyeti karşılamazsa sessizce
/// `file_selector`a düşülür: özellik kaybolmaz, yalnız eski çekmece açılır.
abstract final class DocPicker {
  static const _channel = MethodChannel('dev.kaimau.notlar/system');

  static bool get _useChooser => !kIsWeb && Platform.isAndroid;

  /// Tek belge seçtirir; iptalde null.
  static Future<XFile?> pickOne(
    XTypeGroup group, {
    String? chooserTitle,
  }) async {
    final files = await _pick(group, multiple: false, title: chooserTitle);
    return files.isEmpty ? null : files.first;
  }

  /// Birden çok belge seçtirir; iptalde boş liste.
  static Future<List<XFile>> pickMany(
    XTypeGroup group, {
    String? chooserTitle,
  }) => _pick(group, multiple: true, title: chooserTitle);

  static Future<List<XFile>> _pick(
    XTypeGroup group, {
    required bool multiple,
    String? title,
  }) async {
    if (_useChooser) {
      try {
        final raw = await _channel.invokeListMethod<Object?>('pickDocuments', {
          'mimeTypes': _mimeTypes(group),
          'multiple': multiple,
          'title': title,
        });
        if (raw != null) {
          return [
            for (final entry in raw)
              if (entry is Map && entry['path'] is String)
                XFile(entry['path'] as String, name: entry['name'] as String?),
          ];
        }
      } on PlatformException {
        // Seçiciyi karşılayan uygulama yok ya da köprü meşgul: eski yola düş.
      } on MissingPluginException {
        // Eski bir kurulumda (köprüsüz APK) çalışıyoruz.
      }
    }
    if (multiple) return openFiles(acceptedTypeGroups: [group]);
    final file = await openFile(acceptedTypeGroups: [group]);
    return file == null ? const [] : [file];
  }

  /// Niyete konacak MIME türleri. Grup MIME vermediyse uzantılardan türetilir;
  /// hiçbiri yoksa `*/*` (süzgeçsiz) — süzgeç uydurmak, seçilebilecek dosyayı
  /// gizlemekten iyidir.
  static List<String> _mimeTypes(XTypeGroup group) {
    final mimes = {...?group.mimeTypes};
    for (final ext in group.extensions ?? const <String>[]) {
      final mime = _byExtension[ext.toLowerCase()];
      if (mime != null) mimes.add(mime);
    }
    return mimes.isEmpty ? const ['*/*'] : mimes.toList();
  }

  static const _byExtension = <String, String>{
    'pdf': 'application/pdf',
    'txt': 'text/plain',
    'md': 'text/plain',
    'json': 'application/json',
    'docx':
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'pptx':
        'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
    'gif': 'image/gif',
  };
}
