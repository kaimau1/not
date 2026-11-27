import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/settings/data/prefs_sync.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ayar senkronu planı (F4.5)', () {
    test('ilk eşitlemede bulut kazanır, bulutta olmayan yerel yüklenir', () {
      final plan = planPrefsSync(
        local: {'font_scale': 1.0, 'auto_tag': true},
        snapshot: null,
        remote: {'font_scale': 1.35},
      );
      expect(plan.apply, {'font_scale': 1.35});
      expect(plan.push, {'auto_tag': true});
      expect(plan.snapshot, {'font_scale': 1.35, 'auto_tag': true});
    });

    test('yerelde değişen buluta gider, bulutta değişen yerele iner', () {
      final plan = planPrefsSync(
        local: {'auto_tag': false, 'auto_title': true},
        snapshot: {'auto_tag': true, 'auto_title': true},
        remote: {'auto_tag': true, 'auto_title': false},
      );
      expect(plan.push, {'auto_tag': false});
      expect(plan.apply, {'auto_title': false});
      expect(plan.snapshot, {'auto_tag': false, 'auto_title': false});
      expect(plan.remove, isEmpty);
    });

    test(
      'tema, parlaklık, gece programı ve zemin tercihleri cihazlara özeldir',
      () {
        expect(kSyncedPrefKeys, isNot(contains('theme_mode')));
        expect(kSyncedPrefKeys, isNot(contains('theme_family')));
        expect(kSyncedPrefKeys, isNot(contains('theme_brightness')));
        expect(kSyncedPrefKeys, isNot(contains('dark_schedule_enabled')));
        expect(kSyncedPrefKeys, isNot(contains('dark_schedule_start')));
        expect(kSyncedPrefKeys, isNot(contains('dark_schedule_end')));
        expect(kSyncedPrefKeys, isNot(contains('dashboard_bg_apply_notes')));
      },
    );

    test('değişiklik yoksa hiçbir şey yazılmaz', () {
      final plan = planPrefsSync(
        local: {
          'user_templates_v1': '[]',
          'x': ['a'],
        },
        snapshot: {
          'user_templates_v1': '[]',
          'x': ['a'],
        },
        remote: {
          'user_templates_v1': '[]',
          'x': ['a'],
        },
      );
      expect(plan.apply, isEmpty);
      expect(plan.push, isEmpty);
      expect(plan.remove, isEmpty);
    });

    test('yerelde silinen anahtar buluttan da silinir, geri dirilmez', () {
      final plan = planPrefsSync(
        local: const {},
        snapshot: {'model_tts': 'm1'},
        remote: {'model_tts': 'm1'},
      );
      expect(plan.remove, {'model_tts'});
      expect(plan.apply, isEmpty);
      expect(plan.snapshot.containsKey('model_tts'), isFalse);
    });
  });

  // Tablet bulgusu 2026-11-07: web'in yazdığı 1.0 buluttan int geliyordu;
  // setInt'le kaydedilince getDouble çöküyor, Ayarlar gri ekran.
  test('ondalık tercih buluttan int gelse de double yazılır', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await writeLocalPref(prefs, 'font_scale', 1);
    expect(prefs.getDouble('font_scale'), 1.0);
    await writeLocalPref(prefs, 'dark_schedule_start', 480);
    expect(prefs.getInt('dark_schedule_start'), 480);
  });
}
