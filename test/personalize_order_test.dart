import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/personalize.dart';

/// P63 PBT: hızlı satır ve Ekle levhası sırası tercih alanları (henüz hiçbir
/// ekran okumaz; PB7 bağlar).
void main() {
  test('gidiş-dönüş: quickOrder/attachOrder korunur, eşitlik kapsar', () {
    const p = UiPrefs(quickOrder: ['bold', 'pen'], attachOrder: ['photo']);
    final back = UiPrefs.fromJson(jsonDecode(jsonEncode(p.toJson())));
    expect(back.quickOrder, ['bold', 'pen']);
    expect(back.attachOrder, ['photo']);
    expect(back, p);
    expect(back.hashCode, p.hashCode);
    expect(p == p.copyWith(quickOrder: ['pen', 'bold']), isFalse);
    expect(p == p.copyWith(attachOrder: const []), isFalse);
  });

  test('eski kayıt (alan yok) aynen okunur; boşsa toJson yazmaz', () {
    final old = UiPrefs.fromJson(const {'hidden': <String>[], 'seekBack': 5});
    expect(old.quickOrder, isEmpty);
    expect(old.attachOrder, isEmpty);
    expect(old.seekBack, 5);
    final json = const UiPrefs().toJson();
    expect(json.containsKey('quickOrder'), isFalse);
    expect(json.containsKey('attachOrder'), isFalse);
  });

  test('bilinmeyen kimlik orderOf ile atlanır', () {
    final p = UiPrefs.fromJson(const {
      'quickOrder': ['yok', 'bold', 'bold', 'pen'],
    });
    expect(UiPrefs.orderOf(const ['pen', 'bold', 'spell'], p.quickOrder), [
      'bold',
      'pen',
      'spell',
    ]);
  });

  test('yeni kimlikler', () {
    expect(UiItem.pinned('play'), 'pinned.play');
    expect(UiItem.penTool('marker'), 'pen.tool.marker');
  });
}
