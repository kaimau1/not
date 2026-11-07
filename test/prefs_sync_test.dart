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
        local: {'theme_mode': 'dark', 'auto_title': true},
        snapshot: {'theme_mode': 'light', 'auto_title': true},
        remote: {'theme_mode': 'light', 'auto_title': false},
      );
      expect(plan.push, {'theme_mode': 'dark'});
      expect(plan.apply, {'auto_title': false});
      expect(plan.snapshot, {'theme_mode': 'dark', 'auto_title': false});
      expect(plan.remove, isEmpty);
    });

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
    await writeLocalPref(prefs, 'briefing_minutes', 480);
    expect(prefs.getInt('briefing_minutes'), 480);
  });
}
