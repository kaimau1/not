import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore belge boyutu TAHMİNİ (F1.6). Belge sınırı 1 MiB; çizim
/// noktaları, balonlar, transkriptler ve sayfa notları tek belgede durduğu
/// için not bu sınıra yaklaşabiliyor ve sunucu yazımı reddediyor.
///
/// Kurallar Firestore'un "Storage size calculations" belgesindeki gibi:
/// metin = UTF-8 bayt + 1, sayı/zaman = 8, bool/null = 1, harita anahtarı =
/// UTF-8 bayt + 1, dizi/harita = öğelerinin toplamı. Belge adı ve 32 baytlık
/// ek yük de eklenir. Kesin değil, uyarı için yeterince yakın.
int estimateFirestoreBytes(Map<String, dynamic> fields, {String path = ''}) =>
    utf8.encode(path).length + 1 + 32 + _mapSize(fields);

int estimateValueBytes(Object? v) => switch (v) {
  null || bool() => 1,
  String s => utf8.encode(s).length + 1,
  num() || Timestamp() || DateTime() || FieldValue() => 8,
  GeoPoint() => 16,
  List l => l.fold(0, (total, e) => total + estimateValueBytes(e)),
  Map m => _mapSize(m),
  _ => 8,
};

int _mapSize(Map<dynamic, dynamic> m) {
  var total = 0;
  for (final e in m.entries) {
    total += utf8.encode(e.key.toString()).length + 1;
    total += estimateValueBytes(e.value);
  }
  return total;
}
