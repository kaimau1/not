import '../../../core/utils/firestore_size.dart';

/// **AĞIR ALANLAR AYRI BELGEDE** (F3.13, 2026-10-19).
///
/// Çizim (mürekkep), balonlar ve PDF işaretleri bir ekin içinde binlerce
/// noktaya varabiliyor; hepsi notun belgesinde durunca ana ekranın akışı her
/// notun bu yükünü indiriyor, bellekte tutuyor ve belge 1 MiB sınırına
/// yaklaşıyordu. Ağır kısmı [kHeavySplitBytes]ı aşan not BÖLÜNÜR:
///  * ana belge: ekler bu anahtarlar SÖKÜLMÜŞ hâlde + `heavyRef: true`,
///  * `notes/{id}/heavy/data`: `{attachments: {ekId: {ink, bubbles,
///    pdfMarks}}}`.
/// Küçük notlar hiç bölünmez (eski davranış birebir).
///
/// Okumada birleştirme EK KİMLİĞİYLE yapılır ve ağır belgede kaydı olan ek
/// için ağır belge kazanır; olmayan ek (ör. eski bir sürümün satır içi
/// yazdığı) satır içi değerini korur — hiçbir yolda veri düşmez.
const kHeavyAttachmentKeys = ['ink', 'bubbles', 'pdfMarks'];

/// Ağır kısım bu eşiği aşınca not bölünür. 2026-10-20 (F7.3, kullanıcı
/// kararı) 96 KB → 16 KB: altındaki notların çizim/balon/işaretleri ana
/// ekran akışında ayrıştırılıp oturum boyu bellekte duruyordu. Bölünmüş
/// biçimi v2+ istemciler okur; veri sürümü artmaz. Bölünmüş not bir daha
/// birleşmez (`heavyRef` kalır).
const kHeavySplitBytes = 16 * 1024;

/// Ağır belgenin alt koleksiyonu ve belge kimliği.
const kHeavyCollection = 'heavy';
const kHeavyDocId = 'data';

/// "Düzenliyor" nabızlarının alt koleksiyonu (F4.1, `note_presence.dart`).
/// Not silinirken ağır belge ve sürümlerle birlikte gider (F5.4).
const kPresenceCollection = 'presence';

/// Ek haritalarının ağır kısmının bayt tahmini.
int heavyBytesOf(List<Map<String, dynamic>> attachments) {
  var total = 0;
  for (final a in attachments) {
    for (final key in kHeavyAttachmentKeys) {
      final value = a[key];
      if (value != null) total += estimateValueBytes(value);
    }
  }
  return total;
}

/// Ek haritalarını hafif listeye ve ek kimliği → ağır alanlar haritasına
/// ayırır. Ağır alanı olmayan ek ağır haritaya girmez.
({List<Map<String, dynamic>> light, Map<String, Map<String, dynamic>> heavy})
splitAttachmentMaps(List<Map<String, dynamic>> attachments) {
  final light = <Map<String, dynamic>>[];
  final heavy = <String, Map<String, dynamic>>{};
  for (final a in attachments) {
    final id = a['id'] as String? ?? '';
    final part = <String, dynamic>{
      for (final key in kHeavyAttachmentKeys)
        if (a.containsKey(key)) key: a[key],
    };
    light.add({
      for (final e in a.entries)
        if (!kHeavyAttachmentKeys.contains(e.key)) e.key: e.value,
    });
    if (id.isNotEmpty && part.isNotEmpty) heavy[id] = part;
  }
  return (light: light, heavy: heavy);
}

/// Ana belgenin haritasına ağır belgeyi işler (yeni harita döner). [heavy]
/// null ise (henüz gelmedi / yok) ana harita olduğu gibi döner.
Map<String, dynamic> mergeHeavy(
  Map<String, dynamic> main,
  Map<String, dynamic>? heavy,
) {
  final parts = heavy?['attachments'];
  if (parts is! Map) return main;
  final raw = main['attachments'];
  if (raw is! List) return main;
  return {
    ...main,
    'attachments': [
      for (final a in raw)
        if (a is Map)
          switch (parts[a['id']]) {
            final Map part => {...Map<String, dynamic>.from(a), ...part},
            _ => Map<String, dynamic>.from(a),
          }
        else
          a,
    ],
  };
}
