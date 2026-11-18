import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/settings/data/prefs_sync.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// U1 (2026-11-18): ana ekran jest hedefleri — kayıt biçimi, varsayılanlar,
/// eski "sağa kaydırınca takvim" kaydının korunması ve ayar senkronu.
void main() {
  const folders = (kind: HomeGestureKind.folders, id: null);

  test('kayıt biçimi gidiş-dönüş', () {
    for (final t in <HomeGestureTarget>[
      folders,
      (kind: HomeGestureKind.calendar, id: null),
      (kind: HomeGestureKind.none, id: null),
      (kind: HomeGestureKind.note, id: 'n1'),
      (kind: HomeGestureKind.folder, id: 'f:2'),
    ]) {
      expect(parseHomeGesture(encodeHomeGesture(t), folders), t);
    }
  });

  test('bozuk ya da kimliksiz kayıt varsayılana düşer', () {
    expect(parseHomeGesture(null, folders), folders);
    expect(parseHomeGesture('', folders), folders);
    expect(parseHomeGesture('uydurma', folders), folders);
    expect(parseHomeGesture('note', folders), folders);
    expect(parseHomeGesture('folder:', folders), folders);
    // Kimlik gerekmeyen türde fazlalık atılır.
    expect(parseHomeGesture('calendar:x', folders), (
      kind: HomeGestureKind.calendar,
      id: null,
    ));
  });

  Future<ProviderContainer> container(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(c.dispose);
    return c;
  }

  test(
    'varsayılanlar bugünkü davranış: çekiş klasörler, sağa takvim',
    () async {
      final c = await container({});
      expect(c.read(homePullGestureProvider).kind, HomeGestureKind.folders);
      expect(
        c.read(homeSwipeRightGestureProvider).kind,
        HomeGestureKind.calendar,
      );
    },
  );

  test('eski "sağa kaydırınca takvim" kapalıysa hiçbiri', () async {
    final c = await container({kSwipeLeftCalendarKey: false});
    expect(c.read(homeSwipeRightGestureProvider).kind, HomeGestureKind.none);
  });

  test('seçim kaydedilir ve eşitlenen ayarlarda', () async {
    final c = await container({});
    c.read(homePullGestureProvider.notifier).set((
      kind: HomeGestureKind.note,
      id: 'abc',
    ));
    final prefs = c.read(sharedPreferencesProvider);
    expect(prefs.getString(kHomePullGestureKey), 'note:abc');
    expect(kSyncedPrefKeys, contains(kHomePullGestureKey));
    expect(kSyncedPrefKeys, contains(kHomeSwipeRightGestureKey));
  });
}
