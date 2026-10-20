/// Arşiv defterinin **kâğıt deseni** (kullanıcı isteği 2026-09-01: "arşiv
/// defterine tema seçenekleri olmalı çizgili kareli, düz kağıt şeklinde").
///
/// Desen defterin KENDİ kaydında durur (`Note.archivePaper`), genel bir ayar
/// değil: aynı kullanıcının fatura defteri kareli, günlüğü çizgili olabilir.
/// Kâğıdın RENGİ ayrı bir şey — o notun rengiyle (`Note.color`) geliyor;
/// burada yalnız üstüne çizilen desen seçiliyor.
enum ArchivePaper {
  /// Klasik çizgili defter (varsayılan): yatay satır çizgileri + kenar payı.
  lined('lined'),

  /// Kesikli çizgili defter (2026-10-20, "kesikli çizgi çekme gibi"):
  /// çizgili ile aynı satırlar, kesik kesik ve biraz daha silik.
  dashed('dashed'),

  /// Kareli (matematik) defter.
  grid('grid'),

  /// Noktalı (bullet journal) kâğıt.
  dots('dots'),

  /// Düz kâğıt: desen yok, yalnız cilt gölgesi.
  plain('plain'),

  /// Sarı bloknot (legal pad): sıcak sarı zemin, çizgiler ve çift kenar
  /// çizgisi (2026-10-20, "kâğıt tipine yenilikler lazım").
  legal('legal'),

  /// Milimetrik kâğıt: her satır aralığı dört ince kareye bölünür, satır
  /// çizgileri belirgin — çizim ve tablo için.
  engineering('engineering'),

  /// İzometrik nokta kâğıdı: noktalar üçgen örgüde (her satır yarım adım
  /// kayık) — kroki ve üç boyutlu çizim için.
  isometric('isometric');

  const ArchivePaper(this.id);

  /// Kayda yazılan kimlik. Ada bağlanmaz: enum adı değişse bile eski
  /// defterler aynı deseni açar.
  final String id;

  /// Tanınmayan kimlik (ileride eklenmiş bir deseni bilmeyen bu sürüm)
  /// çizgiliye düşer — desensiz bir defter "bozuk" görünürdü.
  static ArchivePaper fromId(String? id) {
    for (final paper in values) {
      if (paper.id == id) return paper;
    }
    return ArchivePaper.lined;
  }

  /// Satır çizgileri YAZIYA OTURAN desenler (2026-10-20, "defter modunda
  /// çizgilerle yazılar üst üste geliyor"): bunlarda çizgiler sabit bir
  /// ızgaradan değil, sayfadaki her metin satırının altından çizilir
  /// (bkz. `RuledLines`). Kareli/noktalı desenler serbest ızgara kalır.
  bool get ruled =>
      this == ArchivePaper.lined ||
      this == ArchivePaper.legal ||
      this == ArchivePaper.dashed;
}
