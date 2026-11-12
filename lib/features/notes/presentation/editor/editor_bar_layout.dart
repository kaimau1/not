/// Editörün alt çubuğunun GENİŞLİĞE göre planı.
///
/// KÖK NEDEN (kullanıcı bulgusu 2026-09-23: "alt alanı biraz düzenle, hafif
/// taşmalar var"): çubuk sabit ölçülerle kuruluyordu — araç kapsülü (Biçim,
/// Ekle, Seç, Ara, Paylaş, Ekler) + üç 48 dp'lik yuvarlak düğme + kenar
/// payları, 411 dp'lik bir telefonda bile sınırdaydı (408 dp). 393 dp'lik
/// telefonda ya da nota ek girince kapsül yatay kaydırmaya düşüyor ve sağ
/// kenarı düğmelerin altında KESİK görünüyordu (kapsülün çerçevesi yarım
/// kalıyordu). Kaydırma "son çare" diye yazılmıştı ama çoğu telefonda ilk
/// çareydi.
///
/// Artık plan önce sığdırmayı dener, taşma yerine sırayla:
///  1. sağdaki üç düğmeyi 44 → 40 dp'ye indirir;
///  2. Ara'yı kapsülden çıkarır — ⋮ menüsünde zaten duruyor, yani hiçbir iş
///     erişilemez hâle gelmez;
///  3. sağdaki düğmeleri 36 dp'ye indirir (393 dp + ekli not; dokunma alanı
///     yine 48 dp yüksek — bkz. `MinTapTarget`);
///  4. Kalem'i çıkarır (360 dp + ekli metin notu) — klavye açıkken hızlı
///     satırda duruyor; eski yerleşimdeki düğmeler (☑/Seç, Ekler) kalır.
///
/// 2026-10-11: sağdaki üç düğme artık AYRI gölgeli kareler değil, TEK vurgu
/// renkli kapsülün segmentleri (bkz. editördeki `_aiCapsule`). [button]
/// segmentin GENİŞLİĞİ (yükseklik soldaki kapsülle aynı, 40 dp), [gap]
/// segmentler arası boşluk.
///
/// 2026-11-12 (F75.1, K-D6): Paylaş kapsülden çıktı (⋮ menüsünün hızlı
/// satırında), yerine KALEM geldi; belge notunun ayrı kalem düğmesi de o
/// segment oldu (`share` alanı kalktı). `pen` girdisi "kalem isteniyor mu",
/// plandaki [pen] "sığdı mı" — çağıran kalemi `fixedSegments`'e SAYMAZ.
typedef EditorBarPlan = ({double button, double gap, bool search, bool pen});

/// Kapsüldeki bir segmentin kenarı ve aralığı (editördeki `_kToolSegment`).
const double kEditorBarSegment = 40;
const double kEditorBarSegmentGap = 3;

/// Kapsülün iç dolgusu (3 + 3) ve çerçevesi (1 + 1).
const double _pillChrome = 8;

/// "Ekler (n)" düğmesinin yaklaşık genişliği (simge + sayı + dolgu).
const double _attachmentsWidth = 52;

/// Kapsül ile sağdaki düğmeler arasındaki boşluk.
const double _pillGap = 8;

/// Sağdaki AI kapsülünün iç dolgusu (3 + 3) ve çerçevesi (1 + 1).
const double _aiChrome = 8;

EditorBarPlan planEditorBar({
  required double width,
  required int fixedSegments,
  required bool attachments,
  bool pen = true,
  int aiButtons = 3,
}) {
  double need(double button, double gap, int optional) {
    final n = fixedSegments + optional;
    final pill =
        _pillChrome +
        n * kEditorBarSegment +
        (n - 1).clamp(0, n) * kEditorBarSegmentGap +
        (attachments ? _attachmentsWidth + kEditorBarSegmentGap : 0);
    // Kişiselleştirmede gizlenen AI düğmeleri yer tutmaz; hiçbiri yoksa
    // kapsülün kendisi de çizilmez.
    return pill +
        _pillGap +
        (aiButtons > 0
            ? _aiChrome + aiButtons * button + (aiButtons - 1) * gap
            : 0);
  }

  // (düğme, boşluk, Ara, Kalem)
  const steps = [
    (44.0, 2.0, true, true),
    (40.0, 2.0, true, true),
    (40.0, 2.0, false, true),
    (36.0, 2.0, false, true),
    (40.0, 2.0, false, false),
    (36.0, 2.0, false, false),
  ];
  for (final (button, gap, search, keepPen) in steps) {
    final withPen = pen && keepPen;
    if (need(button, gap, (search ? 1 : 0) + (withPen ? 1 : 0)) <= width) {
      return (button: button, gap: gap, search: search, pen: withPen);
    }
  }
  // Hiçbiri sığmadı (çok dar pencere): en sıkı plan; kapsül kendi içinde
  // kayar.
  return (button: 36.0, gap: 2.0, search: false, pen: false);
}
