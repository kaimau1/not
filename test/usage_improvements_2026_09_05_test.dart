import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:notlar/core/l10n_ext.dart';
import 'package:notlar/core/utils/relative_time.dart';
import 'package:notlar/core/widgets/empty_state.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_stats.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/note_card.dart';
import 'package:notlar/features/notes/presentation/note_grid.dart';
import 'package:notlar/features/notes/presentation/notes_providers.dart';
import 'package:notlar/features/notes/presentation/trash_screen.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 2026-09-05 kullanım turunun yeni davranışları.
void main() {
  group('NoteStats', () {
    test('kelime ve karakter sayar, biçim işaretlerini saymaz', () {
      const note = Note(
        id: 'n',
        type: NoteType.text,
        title: '**Alışveriş**',
        body: 'iki kelime',
      );
      final stats = NoteStats.of(note);
      // "Alışveriş" + "iki" + "kelime" = 3; ** işaretleri sayılmaz.
      expect(stats.words, 3);
      expect(stats.characters, 'Alışverişikikelime'.length);
    });

    test('maddeleri ve işaretlileri ayrı sayar', () {
      const note = Note(
        id: 'n',
        type: NoteType.checklist,
        items: [
          NoteItem(id: '1', text: 'süt', checked: true),
          NoteItem(id: '2', text: 'ekmek'),
          NoteItem(id: '3', text: '   '), // boş madde sayılmaz
        ],
      );
      final stats = NoteStats.of(note);
      expect(stats.items, 2);
      expect(stats.checkedItems, 1);
    });

    test('okuma süresi dakikada 200 kelime, boş notta sıfır', () {
      const empty = Note(id: 'n', type: NoteType.text);
      expect(NoteStats.of(empty).readMinutes, 0);

      final long = Note(
        id: 'n',
        type: NoteType.text,
        body: List.filled(450, 'kelime').join(' '),
      );
      expect(NoteStats.of(long).readMinutes, 3);
    });
  });

  group('relativeTimeLabel', () {
    late AppLocalizations l10n;

    setUpAll(() async {
      l10n = await AppLocalizations.delegate.load(const Locale('tr'));
    });

    final now = DateTime(2026, 9, 5, 12);

    test('bir dakikadan yakın "az önce"', () {
      expect(
        relativeTimeLabel(l10n, now.add(const Duration(seconds: 30)), now: now),
        l10n.relativeJustNow,
      );
    });

    test('gelecek ve geçmiş ayrı biçimler kullanır', () {
      expect(
        relativeTimeLabel(l10n, now.add(const Duration(hours: 3)), now: now),
        l10n.relativeInHours(3),
      );
      expect(
        relativeTimeLabel(l10n, now.subtract(const Duration(days: 2)), now: now),
        l10n.relativeAgoDays(2),
      );
    });

    test('60 dakikanın altı dakika, 24 saatin altı saat', () {
      expect(
        relativeTimeLabel(l10n, now.add(const Duration(minutes: 45)), now: now),
        l10n.relativeInMinutes(45),
      );
      expect(
        relativeTimeLabel(l10n, now.add(const Duration(hours: 23)), now: now),
        l10n.relativeInHours(23),
      );
    });
  });

  group('trashDaysLeft', () {
    final now = DateTime(2026, 9, 5, 12);

    test('yeni silinen not 30 gün taşır', () {
      final note = Note(id: 'n', type: NoteType.text, deletedAt: now);
      expect(trashDaysLeft(note, now: now), 30);
    });

    test('süresi dolmuş not 0 döner (bugün gidiyor)', () {
      final note = Note(
        id: 'n',
        type: NoteType.text,
        deletedAt: now.subtract(const Duration(days: 31)),
      );
      expect(trashDaysLeft(note, now: now), 0);
    });

    test('silinme zamanı bilinmeyen notta null', () {
      const note = Note(id: 'n', type: NoteType.text);
      expect(trashDaysLeft(note), isNull);
    });
  });

  group('SearchHistoryNotifier', () {
    Future<ProviderContainer> container() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final c = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('tek harflik sorgu kaydedilmez', () async {
      final c = await container();
      c.read(searchHistoryProvider.notifier).remember('a');
      expect(c.read(searchHistoryProvider), isEmpty);
    });

    test('aynı sorgu kopyalanmaz, başa taşınır', () async {
      final c = await container();
      final notifier = c.read(searchHistoryProvider.notifier);
      notifier.remember('fatura');
      notifier.remember('proje');
      notifier.remember('FATURA');
      expect(c.read(searchHistoryProvider), ['FATURA', 'proje']);
    });

    test('en fazla maxEntries kayıt tutulur, en eskisi düşer', () async {
      final c = await container();
      final notifier = c.read(searchHistoryProvider.notifier);
      for (var i = 0; i < SearchHistoryNotifier.maxEntries + 3; i++) {
        notifier.remember('sorgu$i');
      }
      final history = c.read(searchHistoryProvider);
      expect(history.length, SearchHistoryNotifier.maxEntries);
      expect(history.first, 'sorgu${SearchHistoryNotifier.maxEntries + 2}');
      expect(history, isNot(contains('sorgu0')));
    });

    test('forget yalnız o kaydı siler', () async {
      final c = await container();
      final notifier = c.read(searchHistoryProvider.notifier);
      notifier.remember('bir');
      notifier.remember('iki');
      notifier.forget('bir');
      expect(c.read(searchHistoryProvider), ['iki']);
    });
  });

  group('SelectedNoteIdsNotifier.selectAll', () {
    ProviderContainer container() {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      return c;
    }

    test('boş seçimde görünen notların tamamını seçer', () {
      final c = container();
      c.read(selectedNoteIdsProvider.notifier).selectAll(['a', 'b']);
      expect(c.read(selectedNoteIdsProvider), {'a', 'b'});
    });

    test('hepsi zaten seçiliyse seçimi kaldırır', () {
      final c = container();
      final notifier = c.read(selectedNoteIdsProvider.notifier);
      notifier.selectAll(['a', 'b']);
      notifier.selectAll(['a', 'b']);
      expect(c.read(selectedNoteIdsProvider), isEmpty);
    });

    test('kısmi seçimde tamamlar (kaldırmaz)', () {
      final c = container();
      final notifier = c.read(selectedNoteIdsProvider.notifier);
      notifier.toggle('a');
      notifier.selectAll(['a', 'b', 'c']);
      expect(c.read(selectedNoteIdsProvider), {'a', 'b', 'c'});
    });
  });

  group('formatNoteDate önbelleği', () {
    setUpAll(() async {
      // Uygulamada tarih sembollerini `flutter_localizations` yüklüyor;
      // çıplak testte elle yüklenmeli.
      await initializeDateFormatting('tr');
      await initializeDateFormatting('en');
    });

    test('dil değişince tarih yeni dilde biçimlenir', () {
      clearNoteDateFormatCache();
      final date = DateTime(2025, 7, 5);
      Intl.defaultLocale = 'tr';
      final turkish = formatNoteDate(date);
      Intl.defaultLocale = 'en';
      final english = formatNoteDate(date);
      Intl.defaultLocale = null;
      clearNoteDateFormatCache();
      // Aynı anahtar iki dilde AYNI dizgiyi döndürseydi önbellek dili
      // takmış olurdu; Temmuz iki dilde farklı kısaltılır.
      expect(turkish, isNot(english));
    });
  });

  _balancedGridTests();

  group('EmptyState eylemi', () {
    testWidgets('onAction verilmezse düğme çizilmez', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(icon: Icons.folder, title: 'boş'),
          ),
        ),
      );
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('onAction verilirse düğme çizilir ve çalışır', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.folder,
              title: 'boş',
              actionLabel: 'Metin notu',
              onAction: () => tapped++,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Metin notu'));
      expect(tapped, 1);
    });
  });
}

/// Deterministik sütun ataması (ana ekran + klasör + arşiv): hiçbir kart
/// düşmez, tekrarlanmaz, sıra sütun içinde korunur.
void _balancedGridTests() {
  group('balancedColumnAssignment', () {
    final notes = [
      for (var i = 0; i < 7; i++)
        Note(id: 'n$i', type: NoteType.text, body: 'gövde $i'),
    ];

    test('her kart tam bir kez, sütun sayısı kadar sütun', () {
      final buckets = balancedColumnAssignment(notes, 3, 100);
      expect(buckets, hasLength(3));
      final all = [for (final b in buckets) ...b]..sort();
      expect(all, [for (var i = 0; i < notes.length; i++) i]);
      for (final b in buckets) {
        expect(b, [...b]..sort());
      }
    });
  });
}
