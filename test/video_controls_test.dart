import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/video_time.dart';

/// F40.5: döndürme merkezde, video başına, dört turda başa döner.
void main() {
  test('rotate: video başına çeyrek tur ve revizyon', () {
    final hub = NoteVideoHub();
    final before = hub.revision.value;
    hub.rotate('a');
    expect(hub.turnsOf('a'), 1);
    expect(hub.turnsOf('b'), 0);
    expect(hub.revision.value, before + 1);
    hub
      ..rotate('a')
      ..rotate('a')
      ..rotate('a');
    expect(hub.turnsOf('a'), 0);
  });
}
