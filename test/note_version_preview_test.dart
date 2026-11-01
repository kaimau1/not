import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note_version.dart';

/// Cihaz turu 2026-11-01: sürüm önizlemesi biçim işaretlerini ham gösteriyordu.
void main() {
  test('önizleme biçim işaretlerini göstermez', () {
    final v = NoteVersion(
      id: '1',
      at: DateTime(2026, 11, 1),
      reason: 'open',
      by: '',
      title: '',
      body: '%%1:##5:**Birinci satır**##%%\nikinci',
      items: const [],
      textPages: const [],
    );
    expect(v.preview, 'Birinci satır');
  });
}
