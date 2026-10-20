import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/firestore_size.dart';
import 'package:notlar/core/utils/image_cache_budget.dart';
import 'package:notlar/core/utils/prefs_footprint.dart';
import 'package:notlar/features/ai/data/semantic_search.dart';
import 'package:notlar/features/notes/data/pdf/pdf_page_render.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/domain/note_heavy.dart';
import 'package:notlar/features/notes/presentation/note_card_media.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Faz 7 (PERFORMANS_TOPARLAMA_PLANI.md): RAM ayak izi.
void main() {
  group('F7.1 kart küçük resimleri', () {
    setUp(CardThumbs.clear);
    tearDown(CardThumbs.clear);

    test('bellekteki baytlar bütçeyi aşınca en eskiler düşer', () async {
      const mb = 1024 * 1024;
      for (var i = 0; i < 5; i++) {
        await CardThumbs.debugGet('k$i', () async => Uint8List(2 * mb));
        await Future<void>.delayed(Duration.zero);
      }
      expect(CardThumbs.memoryBytes, lessThanOrEqualTo(6 * mb));
      expect(CardThumbs.memoryBytes, greaterThan(0));
      CardThumbs.clearMemory();
      expect(CardThumbs.memoryBytes, 0);
    });

    test('tek başına bütçeyi aşan son resim yine tutulur', () async {
      await CardThumbs.debugGet('big', () async => Uint8List(7 << 20));
      await Future<void>.delayed(Duration.zero);
      expect(CardThumbs.memoryBytes, 7 << 20);
    });

    test('PDF kapağı JPEG kodlanır (BGRA → JPEG)', () {
      final pixels = Uint8List(4 * 4 * 4)..fillRange(0, 64, 0xFF);
      final jpeg = encodeBgraJpeg((
        pixels: pixels,
        width: 4,
        height: 4,
        quality: 80,
      ));
      expect(jpeg.sublist(0, 2), [0xFF, 0xD8]);
    });
  });

  group('F7.2 çizim noktaları Float32List', () {
    test('kayıttan okunan çizgi tipli dizide; yazımda düz liste', () {
      final stroke = InkStroke.fromMap({
        'p': 1,
        'c': 0xFF000000,
        'w': 0.004,
        'd': [0.1, 0.2, 0.3, 0.4],
      });
      expect(stroke.points, isA<Float32List>());
      final d = stroke.toMap()['d'] as List;
      expect(d, isNot(isA<Float32List>()));
      expect(d.length, 4);
      for (var i = 0; i < 4; i++) {
        expect(d[i], closeTo([0.1, 0.2, 0.3, 0.4][i], 1e-7));
      }
      // Yeniden okuma aynı değeri verir (yuvarlama bir kez olur).
      final again = InkStroke.fromMap(stroke.toMap());
      expect(again.points, stroke.points);
    });

    test('çizim sürerken oluşturulan çizgi büyüyebilir kalır', () {
      final stroke = InkStroke(page: 1, color: 0, width: 1, points: [0, 0]);
      stroke.points.addAll([0.5, 0.5]);
      expect(stroke.points.length, 4);
    });

    test('son yazım kopyası kutusuz ve içerikçe aynı', () {
      final map = InkStroke.fromMap({
        'd': [0.25, 0.5],
      }).toMap();
      final copy = copyFirestoreValue(map) as Map;
      expect(copy['d'], isA<Float64List>());
      expect(sameFirestoreValue(map, copy), isTrue);
      final growing = <double>[0.1, 0.2];
      final growingCopy = copyFirestoreValue(growing);
      growing.add(0.3);
      expect(sameFirestoreValue(growing, growingCopy), isFalse);
    });
  });

  test('F7.3 bölme eşiği 16 KB: ~20 KB çizimli not bölünür', () {
    final attachments = [
      {
        'id': 'a',
        'ink': [
          {'d': List.filled(2600, 0.123)},
        ],
      },
    ];
    expect(kHeavySplitBytes, 16 * 1024);
    expect(heavyBytesOf(attachments), greaterThan(kHeavySplitBytes));
  });

  test('F7.4 tercih ayak izi en büyük anahtarları sıralar', () async {
    SharedPreferences.setMockInitialValues({
      'small': 'x',
      'big': 'y' * 1000,
      'list': ['ab', 'cd'],
      'flag': true,
    });
    final prefs = await SharedPreferences.getInstance();
    final f = prefsFootprint(prefs, top: 2);
    expect(f.largest.first.key, 'big');
    expect(f.largest.length, 2);
    expect(f.totalChars, greaterThan(1000));
  });

  test('F7.5 silinen notların vektörleri budanır', () {
    final provider = Provider<SemanticIndex>(SemanticIndex.new);
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final index = c.read(provider)
      ..debugPut('a')
      ..debugPut('b')
      ..debugPut('c');
    index.pruneTo({'a', 'c', 'z'});
    expect(index.cachedVectorCount, 2);
  });

  test('F7.6 düşük RAM cihazda görsel önbellek yarıya iner', () {
    final cache = ImageCache();
    ImageCacheBudget.applyTo(cache, lowMemory: false);
    expect(cache.maximumSizeBytes, 100 << 20);
    ImageCacheBudget.applyTo(cache, lowMemory: true);
    expect(cache.maximumSizeBytes, 50 << 20);
    expect(cache.maximumSize, 500);
  });
}
