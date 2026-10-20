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
    utf8Length(path) + 1 + 32 + _mapSize(fields);

int estimateValueBytes(Object? v) => switch (v) {
  null || bool() => 1,
  String s => utf8Length(s) + 1,
  num() || Timestamp() || DateTime() || FieldValue() => 8,
  GeoPoint() => 16,
  List l => l.fold(0, (total, e) => total + estimateValueBytes(e)),
  Map m => _mapSize(m),
  _ => 8,
};

int _mapSize(Map<dynamic, dynamic> m) {
  var total = 0;
  for (final e in m.entries) {
    total += utf8Length(e.key.toString()) + 1;
    total += estimateValueBytes(e.value);
  }
  return total;
}

/// [s]'nin UTF-8 bayt uzunluğu — kopya AYIRMADAN (F6.1: tahmin her kayıtta
/// koşuyor; `utf8.encode` transkript gibi uzun metinleri her seferinde
/// kopyalıyordu). Eşleşmemiş vekil karakter `utf8.encode` gibi 3 bayt sayılır.
int utf8Length(String s) {
  var n = 0;
  final len = s.length;
  for (var i = 0; i < len; i++) {
    final c = s.codeUnitAt(i);
    if (c < 0x80) {
      n += 1;
    } else if (c < 0x800) {
      n += 2;
    } else if (c >= 0xD800 &&
        c <= 0xDBFF &&
        i + 1 < len &&
        (s.codeUnitAt(i + 1) & 0xFC00) == 0xDC00) {
      n += 4;
      i++;
    } else {
      n += 3;
    }
  }
  return n;
}

/// Firestore biçimindeki iki değer (harita/dizi/ilkel) içerikçe aynı mı
/// (F6.1). Değişmeyen ek listesini yeniden yazmamak için: eskiden listenin
/// tamamı her kayıtta `jsonEncode` + SHA-1'den geçiyordu (300 çizgi × 200
/// noktalı notta ~50 ms); bu karşılaştırma ayırmasız, ilk farkta durur
/// (~1 ms). Zaman damgası `==` ile; `FieldValue` gibi eşitliği kimlikle
/// olan değerler "farklı" sayılır — yanılgı yalnız fazladan yazım yönünde.
bool sameFirestoreValue(Object? a, Object? b) {
  if (identical(a, b)) return true;
  if (a is List) {
    if (b is! List || a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!sameFirestoreValue(a[i], b[i])) return false;
    }
    return true;
  }
  if (a is Map) {
    if (b is! Map || a.length != b.length) return false;
    for (final e in a.entries) {
      final other = b[e.key];
      if (other == null && !b.containsKey(e.key)) return false;
      if (!sameFirestoreValue(e.value, other)) return false;
    }
    return true;
  }
  return a == b;
}

/// Firestore biçimindeki değerin DERİN kopyası. [sameFirestoreValue] ile
/// karşılaştırılacak "son yazılan" kayıt kopya olmalı: çizim sürerken
/// etkin çizginin nokta listesi YERİNDE büyüyor (`InkController`) — aynı
/// liste örneği saklansaydı büyümüş liste "değişmedi" görünür, yazım
/// atlanırdı.
Object? copyFirestoreValue(Object? v) => switch (v) {
  List l => [for (final e in l) copyFirestoreValue(e)],
  Map m => <String, dynamic>{
    for (final e in m.entries) e.key.toString(): copyFirestoreValue(e.value),
  },
  _ => v,
};
