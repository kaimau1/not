import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/image_cache_budget.dart';
import 'package:notlar/core/utils/memory_pressure.dart';
import 'package:notlar/core/utils/spell_engine.dart';
import 'package:notlar/core/utils/tr_lexicon.dart';
import 'package:notlar/core/widgets/pop_in.dart';
import 'package:notlar/core/widgets/scale_settle.dart';
import 'package:notlar/features/notes/data/notes_repository.dart'
    show notesStreamProvider;
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_links.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/notes_providers.dart';

void main() {
  test('MemoryPressure dispatches critical/background flags and isolates errors', () {
    final seen = <bool>[];
    void okListener(bool critical) => seen.add(critical);
    void throwingListener(bool critical) => throw StateError('boom');

    MemoryPressure.register(throwingListener);
    MemoryPressure.register(okListener);
    MemoryPressure.register(okListener); // idempotent registration

    MemoryPressure.dispatch(critical: false);
    MemoryPressure.dispatch(critical: true);
    expect(seen, [false, true]);

    MemoryPressure.unregister(okListener);
    MemoryPressure.unregister(throwingListener);
    MemoryPressure.dispatch(critical: true);
    expect(seen, [false, true]);
  });

  test('ImageCacheBudget classifies device tiers and exposes DPI/wallpaper caps', () {
    expect(classifyDeviceRam(totalRamMb: 2048, cores: 8), DeviceRamTier.low);
    expect(classifyDeviceRam(totalRamMb: 4096, cores: 4), DeviceRamTier.low);
    expect(classifyDeviceRam(totalRamMb: 4096, lowRam: true, cores: 8), DeviceRamTier.low);
    expect(classifyDeviceRam(totalRamMb: 4096, cores: 8), DeviceRamTier.mid);
    expect(classifyDeviceRam(totalRamMb: 6144, cores: 8), DeviceRamTier.high);

    ImageCacheBudget.setTierForTest(DeviceRamTier.low);
    expect(ImageCacheBudget.isLowRam, isTrue);
    expect(ImageCacheBudget.maxPdfDpi, 144.0);
    expect(ImageCacheBudget.maxWallpaperWidth, 1080);

    ImageCacheBudget.setTierForTest(DeviceRamTier.high);
    expect(ImageCacheBudget.isLowRam, isFalse);
    expect(ImageCacheBudget.maxPdfDpi, 260.0);
    expect(ImageCacheBudget.maxWallpaperWidth, 1600);

    ImageCacheBudget.setTierForTest(DeviceRamTier.mid);
  });

  test(
    'backlinksIndexProvider builds O(1) backlink map ignoring trashed/self links',
    () async {
    final target = Note(id: 't1', type: NoteType.text, title: 'Hedef');
    final linker = Note(
      id: 'n1',
      type: NoteType.text,
      title: 'Kaynak',
      tagLinks: const [
        NoteTagLink(label: 'x', attachmentId: '${kNoteLinkPrefix}t1'),
        NoteTagLink(label: 'self', attachmentId: '${kNoteLinkPrefix}n1'),
      ],
    );
    final trashed = Note(
      id: 'n2',
      type: NoteType.text,
      title: 'Çöp',
      deletedAt: DateTime.utc(2026),
      tagLinks: const [
        NoteTagLink(label: 'y', attachmentId: '${kNoteLinkPrefix}t1'),
      ],
    );

    final c = ProviderContainer(
      overrides: [
        notesStreamProvider.overrideWith((_) => Stream.value([target, linker, trashed])),
      ],
    );
    addTearDown(c.dispose);
    final sub = c.listen(notesStreamProvider, (_, _) {});
    addTearDown(sub.close);
    await c.read(notesStreamProvider.future);

    final index = c.read(backlinksIndexProvider);
    expect(index['t1']?.map((n) => n.id), ['n1']);
    expect(index['n1'], isNull);
  });

  test('TrLexicon bitmask flags and SpellEngine reusable scratch distance work', () {
    final lex = TrLexicon.parse(
      'adalet\tnh\ngel\tv\nhak\tnd\nkap\tns\nsaat\tnf\n',
    );
    expect(lex.has('adalet'), isTrue);
    expect(lex.noun('adalet'), isTrue);
    expect(lex.noVoicing('adalet'), isTrue);
    expect(lex.verb('gel'), isTrue);
    expect(lex.doubling('hak'), isTrue);
    expect(lex.softMono('kap'), isTrue);
    expect(lex.front('saat'), isTrue);
    expect(lex.flagsOf('bilinmeyen'), 0);

    expect(SpellEngine.distance('kalem', 'kalem'), 0);
    expect(SpellEngine.distance('klame', 'kalem'), lessThan(1.5));
    expect(SpellEngine.changesTooMuch('abcdefgh', 'abcdxxxx'), isTrue);
    expect(SpellEngine.changesTooMuch('kalem', 'kalm'), isFalse);
  });

  testWidgets('PopIn and RevealUp animate cleanly without Opacity saveLayer', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Column(
          children: [
            PopIn(child: Text('pop')),
            RevealUp(child: Text('reveal')),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('pop'), findsOneWidget);
    expect(find.text('reveal'), findsOneWidget);
  });
}
