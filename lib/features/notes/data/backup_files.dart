import 'package:archive/archive_io.dart';

import 'backup_service.dart';

/// Yedeği doğrudan DOSYAYA akıtan hedef (cihaz; web'de kullanılmaz). Her ek
/// geldiği anda ZIP'e yazılır — yüzlerce MB'lık yedek bellekte birikmez.
class FileBackupSink implements BackupSink {
  FileBackupSink(this.path) {
    _zip.create(path);
  }

  final String path;
  final _zip = ZipFileEncoder();

  @override
  void add(String name, List<int> bytes) =>
      _zip.addArchiveFile(ArchiveFile(name, bytes.length, bytes));

  @override
  Future<void> close() => _zip.close();
}

/// Dosyadaki yedeği TEMBEL açar: girdiler ancak okunduğunda açılır.
Archive openBackupFile(String path) =>
    ZipDecoder().decodeStream(InputFileStream(path));
