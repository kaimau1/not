import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/diagnostics.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';

/// Faz 9 (PERFORMANS_TOPARLAMA_PLANI.md): teşhis sayaçları.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('F9.2 açık not akışı sayacı editör kapanınca düşer', () async {
    expect(Diagnostics.enabled, isTrue); // testler hata ayıklama kipinde
    final c = ProviderContainer(
      overrides: [notesRepositoryProvider.overrideWithValue(null)],
    );
    addTearDown(c.dispose);
    final before = Diagnostics.openNoteStreams;
    final sub = c.listen(noteStreamProvider('n1'), (_, _) {});
    expect(Diagnostics.openNoteStreams, before + 1);
    sub.close();
    await Future<void>.delayed(Duration.zero);
    expect(Diagnostics.openNoteStreams, before);
    expect(
      Diagnostics.summary(thumbBytes: 1 << 20),
      contains('Kart küçük resmi: 1.0 MB'),
    );
  });
}
