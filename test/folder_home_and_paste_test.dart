import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:notlar/core/utils/youtube.dart';
import 'package:notlar/features/folders/presentation/folder_screen.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/note_card.dart';
import 'package:notlar/features/notes/presentation/notes_providers.dart';
import 'package:notlar/features/settings/settings_providers.dart';

/// 2026-10-28 ikinci tur: klasör = süzgeçli ana ekran, yapıştırılan YouTube
/// bağlantısının algılanması, kartta not başına görsel gizleme.
void main() {
  testWidgets('kendi klasörünü açmak ana ekranı o klasöre süzer', (
    tester,
  ) async {
    late BuildContext ctx;
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    container.read(noteFilterProvider.notifier).set(NoteFilter.values.last);
    container.read(selectedTagProvider.notifier).set('iş');
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              ctx = context;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    await FolderScreen.open(ctx, 'f1');
    await tester.pump();
    expect(container.read(selectedFolderProvider), 'f1');
    // Klasör "sanki süzgeç": öbür süzgeçler bırakılır, klasör tek başına.
    expect(container.read(noteFilterProvider), NoteFilter.all);
    expect(container.read(selectedTagProvider), isNull);
    // Ayrı klasör sayfası AÇILMAZ.
    expect(find.byType(FolderScreen), findsNothing);
  });

  group('yapıştırılan YouTube bağlantısı', () {
    const url = 'https://youtu.be/dQw4w9WgXcQ';
    test('tek seferde giren video adresi yakalanır', () {
      expect(pastedYouTubeUrl('Bak: ', 'Bak: $url'), url);
      expect(pastedYouTubeUrl('', '  $url\n'), url);
      expect(pastedYouTubeUrl('a\nb', 'a\n$url\nb'), url);
    });
    test('yazma, karışık metin ve video olmayan adres yakalanmaz', () {
      expect(pastedYouTubeUrl('$url ', '$url x'), isNull);
      expect(pastedYouTubeUrl('', 'izle $url'), isNull);
      expect(pastedYouTubeUrl('', 'https://youtube.com/@kanal'), isNull);
      expect(pastedYouTubeUrl('', 'https://ornek.com/uzun/bir/adres'), isNull);
    });
  });

  test('kartta görsel önizlemesi not başına gizlenir', () {
    final note = Note(
      id: 'n',
      type: NoteType.text,
      title: 'Tatil',
      attachments: [
        Attachment(
          id: 'g',
          kind: AttachmentKind.image,
          fileName: 'a.jpg',
          mimeType: 'image/jpeg',
          width: 1600,
          height: 1200,
          createdAt: DateTime(2026, 10, 28),
        ),
      ],
    );
    final hidden = note.copyWith(cardMediaHidden: true);
    expect(
      estimateNoteCardHeight(hidden, 180),
      lessThan(estimateNoteCardHeight(note, 180)),
    );
    final map = {...hidden.toMap()}..removeWhere((_, v) => v is FieldValue);
    expect(map['cardMediaHidden'], isTrue);
    expect(Note.fromMap('n', map).cardMediaHidden, isTrue);
    // Geri açmak da yazılır (merge yazımında eski true kalmasın).
    expect(note.toMap()['cardMediaHidden'], isFalse);
  });
}
