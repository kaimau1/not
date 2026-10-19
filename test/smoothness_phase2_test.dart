import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/stable_value.dart';
import 'package:notlar/core/widgets/frame_loop.dart';
import 'package:notlar/features/folders/data/folder_order.dart';
import 'package:notlar/features/folders/data/folders_repository.dart';
import 'package:notlar/features/folders/domain/note_folder.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_similarity.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/notes_providers.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Faz 2 (akıcılık) korumaları: F2.1 türetilmiş sağlayıcıların değer
/// kararlılığı, F2.2 kare döngüsü, F2.5 kopya taramasının sayısal yolu.
void main() {
  group('F2.1 türetilmiş sağlayıcılar ilgisiz yayında uyanmaz', () {
    late StreamController<List<Note>> notes;
    late ProviderContainer c;

    const visible = Note(
      id: 'a',
      type: NoteType.text,
      title: 'Görünen',
      body: 'gövde',
      tags: ['iş'],
      folderId: 'f1',
    );
    const loose = Note(id: 'b', type: NoteType.text, title: 'Serbest');
    final archived = Note(
      id: 'c',
      type: NoteType.text,
      title: 'Arşivde',
      archivedAt: DateTime(2026, 10, 1),
    );

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      notes = StreamController<List<Note>>();
      c = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          notesStreamProvider.overrideWith((ref) => notes.stream),
          foldersStreamProvider.overrideWith(
            (ref) => Stream.value(const [
              NoteFolder(id: 'f1', name: 'İş', ownerId: 'me'),
            ]),
          ),
        ],
      );
      addTearDown(c.dispose);
      addTearDown(notes.close);
    });

    Future<void> emit(List<Note> list) async {
      notes.add(list);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
    }

    test('arşivdeki notun yazımı ana ekranı/çipleri/rafı uyandırmaz', () async {
      final counts = <String, int>{};
      void count(String key) => counts[key] = (counts[key] ?? 0) + 1;
      c.listen(filteredNotesProvider, (_, _) => count('filtered'));
      c.listen(allTagsProvider, (_, _) => count('tags'));
      c.listen(folderNoteCountsProvider, (_, _) => count('folders'));
      c.listen(folderNotesProvider('f1'), (_, _) => count('folder'));
      c.listen(hiddenFolderIdsProvider, (_, _) => count('hidden'));
      await emit([visible, loose, archived]);
      expect(c.read(filteredNotesProvider).requireValue.map((n) => n.id), [
        'b',
      ]);
      counts.clear();

      // Arşivdeki not değişti (yeni örnek), diğerleri AYNI örnek.
      await emit([visible, loose, archived.copyWith(title: 'Arşivde 2')]);
      expect(counts, isEmpty);

      // Ana ekrandaki not değişince ana ekran uyanır, ötekiler uyumaz.
      await emit([visible, loose.copyWith(title: 'Serbest 2'), archived]);
      expect(counts, {'filtered': 1});
    });
  });

  group('stable_value', () {
    test('StableBox içerik aynıysa önceki örneği döndürür', () {
      final box = StableBox<List<String>>();
      final first = box.keep(['a', 'b'], sameValues);
      expect(identical(box.keep(['a', 'b'], sameValues), first), isTrue);
      expect(box.keep(['a'], sameValues), ['a']);
    });

    test('sameInstances kimliğe bakar', () {
      const n = Note(id: 'x', type: NoteType.text);
      expect(sameInstances([n], [n]), isTrue);
      expect(sameInstances([n], [n.copyWith(title: 't')]), isFalse);
      expect(sameMap({'a': 1}, {'a': 1}), isTrue);
      expect(sameSet({'a'}, {'a'}), isTrue);
      expect(sameSet({'a'}, {'b'}), isFalse);
    });
  });

  group('F2.2 FrameLoop', () {
    testWidgets('her kare bir adım; ölçek 60 Hz karesine göre', (tester) async {
      final scales = <double>[];
      final loop = FrameLoop(scales.add)..start();
      await tester.pump(); // başlangıç karesi: adım yok
      await tester.pump(const Duration(microseconds: 16667));
      await tester.pump(const Duration(microseconds: 8333)); // 120 Hz karesi
      loop.stop();
      await tester.pump(const Duration(milliseconds: 16));
      expect(scales.length, 2);
      expect(scales[0], closeTo(1.0, 0.01));
      expect(scales[1], closeTo(0.5, 0.01));
      loop.dispose();
    });
  });

  group('F2.5 sayısal trigram', () {
    test('kodlar sıralı ve tekil', () {
      final codes = trigramCodes('ababab');
      expect(codes, [...codes]..sort());
      expect(codes.toSet().length, codes.length);
    });
  });

  test('F2.4 arka plan servisleri ana ekranın build\'inde izlenmez', () {
    final src = File(
      'lib/features/notes/presentation/dashboard_screen.dart',
    ).readAsStringSync();
    for (final p in const [
      'uploadQueueProvider',
      'reminderServiceProvider',
      'premiumProvider',
      'shareIntakeProvider',
      'deepLinkHandlerProvider',
    ]) {
      expect(src.contains('ref.watch($p)'), isFalse, reason: p);
    }
    expect(
      File('lib/app/app_services.dart').readAsStringSync(),
      contains('premiumProvider'),
    );
  });
}
