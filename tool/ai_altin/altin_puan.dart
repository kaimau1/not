// AI-S0 (PLAN §1.6): Türkçe altın örnek seti — saf puanlama (Flutter'sız).
//
// Set dosyaları `tool/ai_altin/set/*.json`. Her dosya bir ana yetenek (A1…A8,
// çalışma kartları, günün özeti); her örnek bir girdi ve makinece denetlenen
// ölçütler taşır. Her ölçüt 1 puan; örnek puanı = geçen / toplam. Canlı
// koşucu `altin_kos_test.dart`, yapısal bekçi `test/ai_altin_set_test.dart`.
//
// Ölçütler kaba ama tekrarlanabilir: amaç "değişiklikten önce/sonra"
// karşılaştırması (AI-S3…S10), mutlak kalite notu değil. `beklenen` alanı
// insan okuru içindir (puana girmez).
import 'dart:convert';
import 'dart:io';

/// Koşucunun tanıdığı işlevler ve her birinin ZORUNLU girdi alanları.
const altinIslevler = <String, List<String>>{
  // A1 Notlarına sor
  'assistantChat': ['notlar', 'soru'],
  'chatAboutNote': ['not', 'soru'],
  'askAboutNoteText': ['not', 'soru'],
  // A2 Kayıttan not (döküm sonrası özet + yapılacaklar)
  'transcriptSummary': ['dokum'],
  // A3 Konuş, gerisini o yapsın
  'assistantVoiceNote': ['cumle'],
  // A4 Belgeye sor
  'summarizeDocumentText': ['belge', 'dosyaAdi'],
  'askDocument': ['belge', 'soru'],
  // A5 Fotoğraftan yapılı not (cihaz OCR çıktısı → yapı)
  'structureOcr': ['ocr'],
  // A6 Yazıyı iyileştir
  'rewriteText': ['metin', 'talimat'],
  'translateText': ['metin', 'hedefDil'],
  // A7 Özet
  'summarizeNote': ['not'],
  // A8 Sessiz düzen
  'generateTitle': ['not'],
  'suggestTags': ['not'],
  // Çalışma kartları
  'generateStudyCards': ['not'],
  // Günün özeti
  'composeBriefing': ['veri'],
};

/// Bilinen ölçüt anahtarları ve değer türleri.
const altinOlcutler = <String, Type>{
  'icermeli': List, // hepsi geçmeli (büyük/küçük harf duyarsız)
  'birini_icermeli': List, // en az biri
  'icermemeli': List, // hiçbiri geçmemeli (uydurma/sızıntı denetimi)
  'en_az_karakter': int,
  'en_cok_karakter': int,
  'en_cok_oran': num, // çıktı uzunluğu ≤ oran × girdi uzunluğu
  'en_az_madde': int, // "-", "*", "•" ya da "1." ile başlayan satır
  'dizi_en_az': int, // liste çıktısı (etiket, kart) en az
  'dizi_en_cok': int,
  'arac': String, // A3/A1: beklenen araç çağrısı adı
  'arac_yok': bool, // hiçbir araç çağrılmamalı
  'dil': String, // "tr" | "en"
};

/// Yetenek kimlikleri — set bunların hepsini kapsamalı.
const altinYetenekler = [
  'A1', 'A2', 'A3', 'A4', 'A5', 'A6', 'A7', 'A8', 'KART', 'OZET', //
];

/// Bir set dosyası.
class AltinSet {
  AltinSet(this.yetenek, this.ad, this.islev, this.ornekler);

  factory AltinSet.fromJson(Map<String, dynamic> j) => AltinSet(
    j['yetenek'] as String,
    j['ad'] as String,
    j['islev'] as String?,
    [
      for (final o in j['ornekler'] as List)
        AltinOrnek.fromJson(o as Map<String, dynamic>, j['islev'] as String?),
    ],
  );

  final String yetenek;
  final String ad;

  /// Dosya geneli işlev (örnek kendi `islev`iyle ezebilir).
  final String? islev;
  final List<AltinOrnek> ornekler;
}

class AltinOrnek {
  AltinOrnek(this.id, this.islev, this.girdi, this.olcut, this.beklenen);

  factory AltinOrnek.fromJson(Map<String, dynamic> j, String? islev) =>
      AltinOrnek(
        j['id'] as String,
        (j['islev'] as String?) ?? islev ?? '',
        (j['girdi'] as Map).cast<String, dynamic>(),
        (j['olcut'] as Map).cast<String, dynamic>(),
        (j['beklenen'] as String?) ?? '',
      );

  final String id;
  final String islev;
  final Map<String, dynamic> girdi;
  final Map<String, dynamic> olcut;
  final String beklenen;

  /// Oran ölçütünün paydası: girdideki en uzun metin.
  int get girdiUzunlugu {
    var n = 0;
    void walk(Object? v) {
      if (v is String && v.length > n) n = v.length;
      if (v is Map) v.values.forEach(walk);
      if (v is List) v.forEach(walk);
    }

    walk(girdi);
    return n;
  }
}

/// `tool/ai_altin/set` altındaki bütün setler (ada göre sıralı).
List<AltinSet> altinSetleriOku([String dir = 'tool/ai_altin/set']) {
  final files =
      Directory(dir)
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  return [
    for (final f in files)
      AltinSet.fromJson(
        jsonDecode(f.readAsStringSync()) as Map<String, dynamic>,
      ),
  ];
}

/// Türkçe büyük/küçük harf katlama (I→ı, İ→i) + şapka düşürme.
String altinKatla(String s) => s
    .replaceAll('I', 'ı')
    .replaceAll('İ', 'i')
    .toLowerCase()
    .replaceAll('â', 'a')
    .replaceAll('î', 'i')
    .replaceAll('û', 'u');

/// Bir koşu çıktısı: metin + (liste döndüren işlevlerde) öğeler + araçlar.
class AltinCikti {
  const AltinCikti(this.metin, {this.dizi, this.araclar = const []});

  final String metin;
  final List<String>? dizi;

  /// Çağrılan araçlar: (ad, argümanlar).
  final List<(String, Map<String, dynamic>)> araclar;

  /// İçerik denetimleri metin + araç argümanları üstünde yapılır (A3'te
  /// asıl iş araç çağrısındadır).
  String get aranan => [
    metin,
    ...?dizi,
    for (final (ad, args) in araclar) '$ad ${jsonEncode(args)}',
  ].join('\n');
}

/// Tek ölçütün sonucu.
typedef AltinSonuc = ({String olcut, bool gecti, String ayrinti});

/// [cikti]yı [ornek] ölçütleriyle puanlar.
List<AltinSonuc> altinPuanla(AltinOrnek ornek, AltinCikti cikti) {
  final out = <AltinSonuc>[];
  final hay = altinKatla(cikti.aranan);
  final len = cikti.metin.trim().length;
  void add(String o, bool ok, [String d = '']) =>
      out.add((olcut: o, gecti: ok, ayrinti: d));

  for (final MapEntry(:key, :value) in ornek.olcut.entries) {
    switch (key) {
      case 'icermeli':
        for (final w in (value as List).cast<String>()) {
          add('icermeli:$w', hay.contains(altinKatla(w)));
        }
      case 'birini_icermeli':
        final ws = (value as List).cast<String>();
        add(
          'birini_icermeli:${ws.join("|")}',
          ws.any((w) => hay.contains(altinKatla(w))),
        );
      case 'icermemeli':
        for (final w in (value as List).cast<String>()) {
          add('icermemeli:$w', !hay.contains(altinKatla(w)));
        }
      case 'en_az_karakter':
        add(key, len >= (value as int), '$len');
      case 'en_cok_karakter':
        add(key, len <= (value as int), '$len');
      case 'en_cok_oran':
        final base = ornek.girdiUzunlugu;
        add(key, base > 0 && len <= (value as num) * base, '$len/$base');
      case 'en_az_madde':
        final n = altinMaddeSayisi(cikti.metin);
        add(key, n >= (value as int), '$n');
      case 'dizi_en_az':
        final n = cikti.dizi?.length ?? 0;
        add(key, n >= (value as int), '$n');
      case 'dizi_en_cok':
        final n = cikti.dizi?.length ?? 0;
        add(key, n <= (value as int), '$n');
      case 'arac':
        final names = [for (final (ad, _) in cikti.araclar) ad];
        add('arac:$value', names.contains(value), names.join(','));
      case 'arac_yok':
        if (value == true) add(key, cikti.araclar.isEmpty);
      case 'dil':
        add('dil:$value', altinDilUyar(cikti.metin, value as String));
    }
  }
  return out;
}

/// Madde satırı sayısı.
int altinMaddeSayisi(String s) => s
    .split('\n')
    .where((l) => RegExp(r'^\s*([-*•]|\d+[.)])\s+\S').hasMatch(l))
    .length;

/// Kaba dil denetimi: Türkçe'ye özgü harf/sözcük var mı.
bool altinDilUyar(String s, String dil) {
  final t = ' ${altinKatla(s)} ';
  final tr =
      RegExp('[çğışöü]').hasMatch(t) ||
      RegExp(r'\s(ve|bir|bu|için|ile)\s').hasMatch(t);
  final en = RegExp(r'\s(the|and|is|of|to)\s').hasMatch(t);
  return switch (dil) {
    'tr' => tr,
    'en' => en && !RegExp('[ğış]').hasMatch(t),
    _ => false,
  };
}

/// Örnek puanı (0–1).
double altinOrnekPuani(List<AltinSonuc> s) =>
    s.isEmpty ? 0 : s.where((r) => r.gecti).length / s.length;
