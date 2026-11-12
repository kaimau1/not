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
///     yine 48 dp yüksek — bkz. `MinTapTarget`).
///
/// 2026-10-11: sağdaki üç düğme artık AYRI gölgeli kareler değil, TEK vurgu
/// renkli kapsülün segmentleri (bkz. editördeki `_aiCapsule`). [button]
/// segmentin GENİŞLİĞİ (yükseklik soldaki kapsülle aynı, 40 dp), [gap]
/// segmentler arası boşluk.
///
/// 2026-11-12 (F75.1, K-D6): Paylaş kapsülden çıktı (⋮ menüsünün hızlı
/// satırında), yerine KALEM geldi. Kalem sabit bir segment — çağıran
/// `fixedSegments`'e sayar; belge notunun ayrı kalem düğmesi de o segment
/// oldu (eski `pen` girdisi ve `share` alanı kalktı).
typedef EditorBarPlan = ({double button, double gap, bool search});

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

  const steps = [(44.0, 2.0, 1), (40.0, 2.0, 1), (40.0, 2.0, 0), (36.0, 2.0, 0)];
  for (final (button, gap, optional) in steps) {
    if (need(button, gap, optional) <= width) {
      return (button: button, gap: gap, search: optional >= 1);
    }
  }
  // Hiçbiri sığmadı (360 dp + ekli not ya da çok dar pencere): en sıkı plan;
  // kapsül kendi içinde kayar.
  return (button: 36.0, gap: 2.0, search: false);
}
