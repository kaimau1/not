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

  /// Kareli (matematik) defter.
  grid('grid'),

  /// Noktalı (bullet journal) kâğıt.
  dots('dots'),

  /// Düz kâğıt: desen yok, yalnız cilt gölgesi.
  plain('plain');

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
}
