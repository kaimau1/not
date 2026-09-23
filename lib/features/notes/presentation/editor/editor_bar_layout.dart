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
///  1. sağdaki üç düğmeyi 48 → 44 dp'ye, aralarını 6 → 4 dp'ye indirir;
///  2. Paylaş'ı, sonra Ara'yı kapsülden çıkarır — ikisi de ⋮ menüsünde
///     zaten duruyor, yani hiçbir iş erişilemez hâle gelmez.
typedef EditorBarPlan = ({double button, double gap, bool search, bool share});

/// Kapsüldeki bir segmentin kenarı ve aralığı (editördeki `_kToolSegment`).
const double kEditorBarSegment = 40;
const double _segmentGap = 3;

/// Kapsülün iç dolgusu (3 + 3) ve çerçevesi (1 + 1).
const double _pillChrome = 8;

/// "Ekler (n)" düğmesinin yaklaşık genişliği (simge + sayı + dolgu).
const double _attachmentsWidth = 52;

/// Belge notundaki kalem düğmesi + ardındaki boşluk.
const double _penWidth = 46 + 8;

/// Kapsül ile sağdaki düğmeler arasındaki boşluk.
const double _pillGap = 8;

EditorBarPlan planEditorBar({
  required double width,
  required int fixedSegments,
  required bool attachments,
  required bool pen,
}) {
  double need(double button, double gap, int optional) {
    final n = fixedSegments + optional;
    final pill =
        _pillChrome +
        n * kEditorBarSegment +
        (n - 1).clamp(0, n) * _segmentGap +
        (attachments ? _attachmentsWidth + _segmentGap : 0);
    return pill + _pillGap + (pen ? _penWidth : 0) + 3 * button + 2 * gap;
  }

  const steps = [
    (48.0, 6.0, 2),
    (44.0, 4.0, 2),
    (44.0, 4.0, 1),
    (44.0, 4.0, 0),
  ];
  for (final (button, gap, optional) in steps) {
    if (need(button, gap, optional) <= width) {
      return (
        button: button,
        gap: gap,
        search: optional >= 1,
        share: optional >= 2,
      );
    }
  }
  // Hiçbiri sığmadı (çok dar pencere): en sıkı plan; kapsül kendi içinde
  // kayar.
  return (button: 44.0, gap: 4.0, search: false, share: false);
}
