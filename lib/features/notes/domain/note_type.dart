/// Not tipleri: düz metin, alışveriş/kontrol listesi, sıralı (numaralı) liste,
/// PDF notu ("PDF ekle not al" — üstte sayfa, altta O SAYFANIN notu) ve aynı
/// modun SLAYT sürümü ("Sunum ekle not al").
///
/// **Kimlikler ASLA değişmez**: Firestore'da bu dizgilerle kayıtlı notlar var.
/// Yeni tip eklemek eski sürümü kırmaz — [fromId] tanımadığı kimliği [text]'e
/// düşürür, yani eski sürümde PDF notu düz metin notu gibi açılır (başlık ve
/// ekler yerinde durur, sayfa notları görünmez ama SİLİNMEZ: eski sürüm o
/// alanı hiç yazmadığı için `set(merge: true)` onu olduğu gibi bırakır).
enum NoteType {
  text('text'),
  checklist('checklist'),
  ordered('ordered'),
  pdf('pdf'),
  slides('slides'),

  /// **Arşiv defteri** — kendi sayfaları olan, içine belge/görsel KOPYASI
  /// alan uzun soluklu not (kullanıcı isteği 2026-08-16: "arşiv özelliği
  /// önemli notları belgeleri toplayan bir klasör… oraya kopya oluşturur").
  ///
  /// Sıradan notlardan farkı: içerik "gövde metni" değil, SAYFALARA
  /// dağıtılmış girdilerdir. Sayfaların bir kısmı türe göre kendiliğinden
  /// dolar (Görseller / Videolar / Belgeler / Metinler), bir kısmını
  /// kullanıcı açar (bkz. `Note.archivePages`).
  ///
  /// Eklenen dosya PAYLAŞILMAZ, KOPYALANIR: kaynak not silinse bile
  /// arşivdeki kopya sağlam kalır (kullanıcının açık tercihi).
  archive('archive');

  const NoteType(this.id);

  final String id;

  static NoteType fromId(String? id) => NoteType.values.firstWhere(
    (t) => t.id == id,
    orElse: () => NoteType.text,
  );

  /// Belge (PDF/sunum) gömülü, SAYFA BAŞINA not tutulan tipler. İkisi de aynı
  /// veri modelini (`Note.pageNotes`) ve aynı iki bölmeli ekranı kullanır;
  /// yalnız üst bölmedeki görüntüleyici ayrışır.
  bool get isPageNoteType => this == NoteType.pdf || this == NoteType.slides;
}
