import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/ai/data/ai_cache.dart';

void main() {
  late Directory dir;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('ai_cache_test');
    AiCache.overrideDir = dir;
  });

  tearDown(() {
    AiCache.overrideDir = null;
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  test('yazılan çıktı aynı anahtarla geri okunur', () async {
    final key = AiCache.keyFor('podcast_full', 'belge metni');
    expect(await AiCache.read(key), isNull);
    await AiCache.write(key, 'üretilmiş podcast metni');
    expect(await AiCache.read(key), 'üretilmiş podcast metni');
  });

  test('girdi değişince anahtar da değişir', () {
    expect(
      AiCache.keyFor('podcast_full', 'a'),
      isNot(AiCache.keyFor('podcast_full', 'b')),
    );
  });

  test('aynı girdi farklı iş için ayrı anahtar üretir', () {
    // Tam podcast ile özet podcast aynı belgeden üretiliyor; anahtar türü
    // ayırmasaydı biri diğerinin yerine servis edilirdi.
    expect(
      AiCache.keyFor('podcast_full', 'belge'),
      isNot(AiCache.keyFor('podcast_summary', 'belge')),
    );
  });

  test('tür ve girdi sınırı karışmaz', () {
    // Düz birleştirmede ('ab','c') ile ('a','bc') aynı dizgiyi verirdi.
    expect(AiCache.keyFor('ab', 'c'), isNot(AiCache.keyFor('a', 'bc')));
  });

  test('budama sınırı aşınca en eskiyi atar, yenileri korur', () async {
    // Dosyalar sıraya göre eskiden yeniye damgalanıyor; budama en eski
    // olanları atmalı, yeniyi değil.
    for (var i = 0; i < AiCache.maxEntries + 5; i++) {
      final file = File('${dir.path}/entry_$i.txt')..writeAsStringSync('$i');
      file.setLastModifiedSync(DateTime(2026).add(Duration(days: i)));
    }
    await AiCache.prune(dir);

    final remaining = dir
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .toSet();
    expect(remaining.length, AiCache.maxEntries);
    expect(remaining.contains('entry_0.txt'), isFalse, reason: 'en eski gitmeli');
    expect(
      remaining.contains('entry_${AiCache.maxEntries + 4}.txt'),
      isTrue,
      reason: 'en yeni durmalı',
    );
  });

  test('sınırın altındayken hiçbir şey silinmez', () async {
    for (var i = 0; i < 3; i++) {
      File('${dir.path}/k_$i.txt').writeAsStringSync('$i');
    }
    await AiCache.prune(dir);
    expect(dir.listSync().whereType<File>().length, 3);
  });
}
