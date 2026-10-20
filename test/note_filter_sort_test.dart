import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/folders/data/folders_repository.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/notes_providers.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Süz levhasıyla gelen yeni süzgeçler (Alarmlı, Kilitli) ve yeni sıralama
/// (Renk). Üçü de veri katmanında YOKTU, tasarım istediği için eklendi.
void main() {
  final notes = [
    Note(
      id: 'alarmli',
      type: NoteType.text,
      title: 'Toplantı',
      reminderAt: DateTime(2026, 8, 10, 9),
      color: NoteColor.blue,
      updatedAt: DateTime(2026, 8),
    ),
    const Note(
      id: 'kilitli',
      type: NoteType.text,
      title: 'Şifreler',
      locked: true,
      color: NoteColor.red,
    ),
    Note(
      id: 'sade',
      type: NoteType.text,
      title: 'Serbest',
      updatedAt: DateTime(2026, 8, 3),
    ),
    Note(
      id: 'renksiz-yeni',
      type: NoteType.text,
      title: 'Yeni',
      updatedAt: DateTime(2026, 8, 4),
    ),
  ];

  Future<ProviderContainer> ready() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        notesStreamProvider.overrideWith((ref) => Stream.value(notes)),
        foldersStreamProvider.overrideWith((ref) => Stream.value(const [])),
      ],
    );
    addTearDown(c.dispose);
    // Dinlenmeyen StreamProvider yükleme durumunda kalır, `.future` tamamlanmaz.
    for (final p in [notesStreamProvider, foldersStreamProvider]) {
      final sub = c.listen(p, (_, _) {}, fireImmediately: true);
      addTearDown(sub.close);
    }
    await c.read(notesStreamProvider.future);
    await c.read(foldersStreamProvider.future);
    return c;
  }

  List<String> ids(ProviderContainer c) =>
      c.read(filteredNotesProvider).requireValue.map((n) => n.id).toList();

  test('Alarmlı süzgeci yalnız hatırlatıcısı olanı bırakır', () async {
    final c = await ready();
    c.read(noteFilterProvider.notifier).set(NoteFilter.reminded);
    expect(ids(c), ['alarmli']);
  });

  test('Kilitli süzgeci yalnız kilitli notu bırakır', () async {
    final c = await ready();
    c.read(noteFilterProvider.notifier).set(NoteFilter.locked);
    expect(ids(c), ['kilitli']);
  });

  test('Renk sıralamasında renksizler SONA düşer', () async {
    final c = await ready();
    c.read(noteSortProvider.notifier).set(NoteSort.color);
    final order = ids(c);
    // Renkliler önce (kırmızı, mavi — NoteColor sırası), renksizler sonda.
    expect(order.take(2).toSet(), {'kilitli', 'alarmli'});
    expect(order.skip(2).toList(), ['renksiz-yeni', 'sade']);
  });

  // "En çok çalışılan": sayaç cihaz yerelde tutulur (noteActivityProvider),
  // notu açmak/düzenlemek bir puan ekler. Sayacı olmayan notlar sona düşer ve
  // kendi aralarında son güncellenene göre dizilir.
  test('En çok çalışılan sıralaması sayaca göre dizer', () async {
    final c = await ready();
    final activity = c.read(noteActivityProvider.notifier);
    activity
      ..touch('sade')
      ..touch('sade')
      ..touch('kilitli');
    c.read(noteSortProvider.notifier).set(NoteSort.active);
    final order = ids(c);
    expect(order.take(2).toList(), ['sade', 'kilitli']);
    // Hiç dokunulmamış ikisi: yeni güncellenen önce.
    expect(order.skip(2).toList(), ['renksiz-yeni', 'alarmli']);
  });

  test('sayaç kalıcıdır (yeniden okunur)', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    ProviderContainer make() {
      final c = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(c.dispose);
      return c;
    }

    make().read(noteActivityProvider.notifier).touch('a');
    expect(make().read(noteActivityProvider)['a'], 1);
  });

  bucketTests();

  test('renk eşitse güncelleme tarihi belirler', () async {
    final c = await ready();
    c.read(noteSortProvider.notifier).set(NoteSort.color);
    final order = ids(c);
    // İki renksiz not: yeni olan önce.
    expect(order.indexOf('renksiz-yeni'), lessThan(order.indexOf('sade')));
  });
}

/// Tarih kovaları: ana ekranda SABİT / BUGÜN / BU HAFTA / DAHA ÖNCE başlıkları
/// bu bölümlemeden geliyor. Sınır GÜN farkıyla hesaplanır, saat farkıyla değil.
void bucketTests() {
  Note at(String id, DateTime? when) =>
      Note(id: id, type: NoteType.text, title: id, updatedAt: when);

  final now = DateTime(2026, 8, 4, 14, 30);
  Map<NoteBucket, List<String>> run(List<Note> notes) => {
    for (final (bucket, list) in dateBuckets(notes, now))
      bucket: [for (final n in list) n.id],
  };

  test('bugün: aynı takvim günü, saat ne olursa olsun', () {
    final r = run([
      at('sabah', DateTime(2026, 8, 4, 0, 1)),
      at('aksam', DateTime(2026, 8, 4, 23, 59)),
    ]);
    expect(r[NoteBucket.today], ['sabah', 'aksam']);
  });

  test('dün 23:59 bugüne SAYILMAZ (saat farkı 31 dakika olsa da)', () {
    final r = run([at('dun', DateTime(2026, 8, 3, 23, 59))]);
    expect(r[NoteBucket.today], isEmpty);
    expect(r[NoteBucket.thisWeek], ['dun']);
  });

  test('7 günün sınırı: 6 gün önce hafta, 7 gün önce daha önce', () {
    final r = run([
      at('sinirda', DateTime(2026, 7, 29, 12)),
      at('disarida', DateTime(2026, 7, 28, 12)),
    ]);
    expect(r[NoteBucket.thisWeek], ['sinirda']);
    expect(r[NoteBucket.earlier], ['disarida']);
  });

  test('tarihsiz not en eskiye düşer', () {
    final r = run([at('tarihsiz', null)]);
    expect(r[NoteBucket.earlier], ['tarihsiz']);
  });
}
