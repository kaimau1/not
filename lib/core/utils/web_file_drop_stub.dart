import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Android: başka uygulamadan (tablet bölünmüş ekran, fare) sürüklenen
/// dosyalar. Flutter motoru Android'de sürükle-bırakı Dart'a taşımıyor;
/// `MainActivity` pencereye `OnDragListener` kurar, üstte gezinmeyi
/// (`hover`) ve bırakılan dosyaların önbellek kopyalarını (`files`) bu
/// kanaldan bildirir.
const _channel = MethodChannel('dev.kaimau.notlar/drop');

void Function() listenFileDrops(
  void Function(List<XFile> files) onDrop, {
  void Function(bool hovering)? onHover,
}) {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return () {};
  _channel.setMethodCallHandler((call) async {
    switch (call.method) {
      case 'hover':
        onHover?.call(call.arguments == true);
      case 'files':
        onHover?.call(false);
        final list = (call.arguments as List<Object?>? ?? const [])
            .whereType<Map<Object?, Object?>>()
            .map(
              (m) => XFile(
                m['path']! as String,
                name: m['name'] as String?,
                mimeType: m['mime'] as String?,
              ),
            )
            .toList();
        if (list.isNotEmpty) onDrop(list);
    }
    return null;
  });
  return () => _channel.setMethodCallHandler(null);
}
