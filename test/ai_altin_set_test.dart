// AI-S0 (PLAN §1.6) BEKÇİSİ: Türkçe altın setin yapısı (anahtarsız).
//
// Set `tool/ai_altin/set/*.json`, puanlama `tool/ai_altin/altin_puan.dart`,
// canlı koşu `tool/ai_altin/altin_kos_test.dart` (GEMINI_API_KEY ister).
// Burada model çağrılmaz: her yetenek var mı, 10–20 örnek mi, kimlikler
// tekil mi, işlev ve girdi alanları koşucuyla uyumlu mu, ölçütler bilinen
// türde mi — ve puanlayıcı sentetik çıktılarda doğru mu.
import 'package:flutter_test/flutter_test.dart';

import '../tool/ai_altin/altin_puan.dart';

void main() {
  final sets = altinSetleriOku();

  test('her ana yetenek tek dosyada, 10–20 örnek', () {
    expect(
      sets.map((s) => s.yetenek).toList()..sort(),
      [...altinYetenekler]..sort(),
    );
    for (final s in sets) {
      expect(s.ad.trim(), isNotEmpty, reason: s.yetenek);
      expect(
        s.ornekler.length,
        inInclusiveRange(10, 20),
        reason: '${s.yetenek} örnek sayısı',
      );
    }
  });

  test('kimlikler tekil ve yetenek önekli', () {
    final ids = <String>{};
    for (final s in sets) {
      for (final o in s.ornekler) {
        expect(o.id, startsWith('${s.yetenek}-'));
        expect(ids.add(o.id), isTrue, reason: 'çift kimlik ${o.id}');
      }
    }
  });

  test('işlev koşucuda var, zorunlu girdi alanları dolu', () {
    for (final s in sets) {
      for (final o in s.ornekler) {
        final need = altinIslevler[o.islev];
        expect(need, isNotNull, reason: '${o.id}: işlev "${o.islev}"');
        for (final k in need!) {
          final v = o.girdi[k];
          expect(v, isNotNull, reason: '${o.id}: girdi.$k yok');
          if (v is String) expect(v.trim(), isNotEmpty, reason: o.id);
          if (v is List) expect(v, isNotEmpty, reason: o.id);
        }
        expect(o.beklenen.trim(), isNotEmpty, reason: '${o.id}: beklenen');
      }
    }
  });

  test('ölçütler bilinen anahtar ve türde, her örnekte en az bir', () {
    for (final s in sets) {
      for (final o in s.ornekler) {
        expect(o.olcut, isNotEmpty, reason: o.id);
        for (final MapEntry(:key, :value) in o.olcut.entries) {
          final type = altinOlcutler[key];
          expect(type, isNotNull, reason: '${o.id}: bilinmeyen ölçüt $key');
          final ok = switch (type) {
            const (List) =>
              value is List &&
                  value.isNotEmpty &&
                  value.every((e) => e is String && e.trim().isNotEmpty),
            const (int) => value is int && value >= 0,
            const (num) => value is num && value > 0,
            const (String) => value is String && value.isNotEmpty,
            const (bool) => value is bool,
            _ => false,
          };
          expect(ok, isTrue, reason: '${o.id}: $key=$value');
        }
        if (o.olcut['dil'] case final String dil) {
          expect(['tr', 'en'], contains(dil), reason: o.id);
        }
        // Araç ölçütü yalnız araç çağırabilen işlevlerde anlamlı.
        if (o.olcut.containsKey('arac')) {
          expect(
            ['assistantChat', 'assistantVoiceNote'],
            contains(o.islev),
            reason: o.id,
          );
        }
        // Liste ölçütü yalnız liste döndüren işlevlerde.
        if (o.olcut.containsKey('dizi_en_az') ||
            o.olcut.containsKey('dizi_en_cok')) {
          expect(
            ['suggestTags', 'generateStudyCards'],
            contains(o.islev),
            reason: o.id,
          );
        }
      }
    }
  });

  group('puanlayıcı', () {
    AltinOrnek ornek(Map<String, dynamic> olcut) =>
        AltinOrnek('T-01', 'summarizeNote', {'not': 'x' * 100}, olcut, 'b');

    test('içerik: Türkçe büyük/küçük harf duyarsız', () {
      final s = altinPuanla(
        ornek({
          'icermeli': ['İstanbul', 'ışık'],
          'icermemeli': ['ankara'],
          'birini_icermeli': ['yok', 'IŞIK'],
        }),
        const AltinCikti('ISTANBUL değil, İSTANBUL ve IŞIK'),
      );
      expect(s.every((r) => r.gecti), isTrue, reason: '$s');
    });

    test('uzunluk, oran, madde, dil', () {
      final s = altinPuanla(
        ornek({
          'en_az_karakter': 10,
          'en_cok_karakter': 60,
          'en_cok_oran': 0.5,
          'en_az_madde': 2,
          'dil': 'tr',
        }),
        const AltinCikti('- süt al\n- faturayı öde\nbitti'),
      );
      expect(s.every((r) => r.gecti), isTrue, reason: '$s');
      final uzun = altinPuanla(
        ornek({'en_cok_oran': 0.1, 'dil': 'en'}),
        AltinCikti('çok uzun bir özet ${'a' * 50}'),
      );
      expect(uzun.where((r) => r.gecti), isEmpty);
    });

    test('liste ve araç çağrısı; argümanlar içerik denetimine girer', () {
      final s = altinPuanla(
        ornek({
          'dizi_en_az': 1,
          'dizi_en_cok': 3,
          'arac': 'create_task',
          'icermeli': ['dişçi'],
        }),
        const AltinCikti(
          'Tamam, ekledim.',
          dizi: ['a', 'b'],
          araclar: [
            ('create_task', {'title': 'Dişçi', 'at': '10:00'}),
          ],
        ),
      );
      expect(s.every((r) => r.gecti), isTrue, reason: '$s');
      final yok = altinPuanla(
        ornek({'arac_yok': true}),
        const AltinCikti('x', araclar: [('create_note', {})]),
      );
      expect(altinOrnekPuani(yok), 0);
    });

    test('örnek puanı = geçen / toplam', () {
      final s = altinPuanla(
        ornek({
          'icermeli': ['a', 'zzz'],
        }),
        const AltinCikti('a'),
      );
      expect(altinOrnekPuani(s), 0.5);
    });
  });
}
