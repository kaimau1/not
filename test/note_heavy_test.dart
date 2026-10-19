import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_heavy.dart';

/// F3.13: ağır alanlar (çizim, balon, PDF işaretleri) ayrı belgede.
void main() {
  final attachments = [
    {
      'id': 'a',
      'kind': 'pdf',
      'fileName': 'x.pdf',
      'ink': [
        {'p': List.filled(40, 1)},
      ],
      'bubbles': [
        {'t': 'balon'},
      ],
      'text': 'transkript aranabilir kalır',
    },
    {'id': 'b', 'kind': 'image', 'fileName': 'y.jpg'},
  ];

  test('bölme: ağır anahtarlar ayrılır, metin ana belgede kalır', () {
    final split = splitAttachmentMaps(attachments);
    expect(split.light.first.containsKey('ink'), isFalse);
    expect(split.light.first.containsKey('bubbles'), isFalse);
    expect(split.light.first['text'], 'transkript aranabilir kalır');
    expect(split.heavy.keys, ['a'], reason: 'ağırı olmayan ek girmez');
  });

  test('birleştirme bölmenin tersidir; ağır belge yoksa ana olduğu gibi', () {
    final split = splitAttachmentMaps(attachments);
    final main = {'type': 'pdf', 'attachments': split.light};
    final merged = mergeHeavy(main, {'attachments': split.heavy});
    expect(merged['attachments'], attachments);
    expect(identical(mergeHeavy(main, null), main), isTrue);
  });

  test('ağır belgede kaydı olmayan ekin satır içi değeri korunur', () {
    final merged = mergeHeavy(
      {
        'attachments': [
          {
            'id': 'yeni',
            'ink': ['eski sürüm satır içi yazdı'],
          },
        ],
      },
      const {'attachments': <String, dynamic>{}},
    );
    expect((merged['attachments'] as List).first['ink'], isNotEmpty);
  });

  test('hafif not: heavyMissing; yüklenince değil', () {
    final light = Note.fromMap('n', {'type': 'text', 'heavyRef': true});
    expect(light.heavyMissing, isTrue);
    final full = Note.fromMap('n', {
      'type': 'text',
      'heavyRef': true,
    }, heavyLoaded: true);
    expect(full.heavyMissing, isFalse);
    expect(full.toMap()['heavyRef'], isTrue);
  });

  test('eşik: küçük çizim bölünmez, büyük bölünür', () {
    expect(heavyBytesOf(attachments), lessThan(kHeavySplitBytes));
    final big = [
      {
        'id': 'a',
        'ink': [
          for (var i = 0; i < 4000; i++) {'p': List.filled(10, 1.5)},
        ],
      },
    ];
    expect(heavyBytesOf(big), greaterThan(kHeavySplitBytes));
  });
}
