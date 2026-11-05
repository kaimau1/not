import 'package:file_selector/file_selector.dart';

// ponytail: Android tablette başka uygulamadan sürükleme motorda yok; yerel
// DragAndDropPermissions köprüsü istenirse burada.
void Function() listenFileDrops(void Function(List<XFile> files) onDrop) =>
    () {};
