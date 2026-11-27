part of 'note_images.dart';

/// Görseli tam ekran açar (yoksa "henüz senkronlanmadı" der). Tam ekranda
/// görselin üzerine elle yazılabilir; çizim [onChanged] ile ekin `ink`
/// alanına döner.
void openImageViewer(
  BuildContext context,
  Attachment img,
  ValueChanged<Attachment> onChanged, {
  Future<void> Function(Attachment, Rect)? onCrop,
  Future<Attachment?> Function(Attachment, int)? onRotate,
  List<Attachment> gallery = const [],
  bool startText = false,
}) {
  final hasLocal = localFileExists(img.localPath);
  // Web: Drive'dan inmiş görsel kutuda görünüyor, görüntüleyici de açabilsin.
  final shown = webDriveResolved(img);
  if (!hasLocal && !shown.isUploaded) {
    ScaffoldMessenger.of(context).showMessage(context.l10n.attachmentNotSynced);
    return;
  }
  Navigator.of(context).push(
    MediaRoute<void>(
      builder: (_) => ImageViewerScreen(
        attachment: shown,
        // Tam ekranda yana kaydırarak nottaki diğer görsellere geçilir.
        gallery: [for (final a in gallery) webDriveResolved(a)],
        onChanged: onChanged,
        onCrop: onCrop,
        onRotate: onRotate,
        startText: startText,
      ),
    ),
  );
}

/// Çözdürme genişliğinin YUVARLANDIĞI adım (px). Bkz. [decodeWidthBucket].
const int kDecodeWidthStep = 256;

/// Yüzen ek panelinin tek satıra geçtiği sayfa genişliği (dp, tablet).
const double kWideToolsMinPage = 600;

/// Geniş sayfada yüzen ek panelinin en büyük genişliği (dp).
const double kWideToolsMaxWidth = 620;

/// Sayfada yüzen SES hapının en büyük genişliği (dp).
const double kAudioFloatMaxWidth = 360;

/// Görselin kaç piksel genişliğinde çözdürüleceği — kutunun genişliğinden
/// hesaplanır ama [kDecodeWidthStep]'in katına YUVARLANIR.
///
/// KÖK NEDEN (kullanıcı: "görsel ekleyince sayfaya kasma artıyor", "kasma
/// birikip artıyor sanki"): `cacheWidth` doğrudan `kutuGenişliği × dpr`
/// idi, yani kutu bir piksel bile değişse BAŞKA bir değer çıkıyordu. O değer
/// görsel önbelleğinin anahtarının parçası: her yeni değer için dosya
/// DİSKTEN yeniden çözülüyor ve önbelleğe AYRI bir kopya olarak giriyordu.
///
/// Sonuçları tam olarak kullanıcının tarif ettiği gibi:
/// - Görseli köşesinden boyutlandırmak kare başına bir tam çözdürme demekti.
/// - Aynı görselin onlarca kopyası önbelleği (varsayılan 100 MB) dolduruyor,
///   dolan önbellek başka görselleri atıyor, onlar da yeniden çözülüyordu —
///   yani kasma kullandıkça BİRİKİYORDU.
/// - Anahtar her değiştiğinde kare boşa düşüyor, görsel bir an kayboluyordu.
///
/// 256 px'lik adımlarla boyutlandırma boyunca anahtar sabit kalır (aynı bitmap
/// yeniden kullanılır) ve önbellekte görsel başına birkaç kopya olur. Adım
/// kalitede fark yaratmaz: `BoxFit` zaten ölçekliyor ve yukarı yuvarlandığı
/// için çözünürlük gösterilen boyuttan asla düşük kalmaz.
int? decodeWidthBucket(double boxWidth, double devicePixelRatio) {
  if (!boxWidth.isFinite || boxWidth <= 0) return null;
  final pixels = boxWidth * devicePixelRatio;
  final buckets = (pixels / kDecodeWidthStep).ceil();
  return math.max(1, buckets) * kDecodeWidthStep;
}

/// [provider]'ı [logicalWidth] mantıksal pikselde gösterilecek kadar çözdürür
/// (F5.2): genişlik [decodeWidthBucket] kovasına yuvarlanır, görsel ondan
/// küçükse büyütülmez. KÖK NEDEN: 12 MP'lik bir fotoğraf tam çözünürlükte
/// ~48 MB bitmap demek — çoklu seçimin 52 px'lik küçük resim şeridi ya da
/// birkaç PPTX slaytı düşük RAM'li telefonda yüzlerce MB tutuyordu.
ImageProvider boundedImage(
  ImageProvider provider,
  double logicalWidth,
  double devicePixelRatio,
) => ResizeImage.resizeIfNeeded(
  decodeWidthBucket(logicalWidth, devicePixelRatio),
  null,
  provider,
);

/// Metin notunda görselleri (el yazısı çizimleri dahil — onlar da görsel
/// ektir) ve videoları TÜM SAYFA üzerinde serbest katman olarak gösterir:
/// video da görsel gibi taşınır/boyutlandırılır ve olduğu yerde oynar
/// ([_VideoBox]). [child]
/// (başlık + gövde metni) normal akışında durur, görseller üstünde yüzer ve
/// sayfayla birlikte kayar. Görsel metnin sağına/soluna, sayfanın istenen
/// yerine sürüklenebilir; kalan alana metin yazılır ("çerçeve içi" küçük
/// tuvalin kaldırdığı sınır).
///
/// Konum: yatay [Attachment.x] (sayfa genişliği oranı), dikey
/// [Attachment.pageY] (sayfa tepesinden dp — sayfa yüksekliği metinle
/// değiştiğinden oran değil mutlak değer). Sayfa, en alttaki görseli
/// kapsayacak kadar uzar; görsel aşağı sürüklendikçe büyür.
/// İpucunun oturacağı yükseklik: gövdenin ilk satırı ([bodyTop]), onu kesen
/// görsel bantlarının altına itilmiş hâli.
///
/// Bantlar yukarıdan aşağı taranır ve tek geçiş yeter: ipucu her itilişte
/// aşağı gider, itildikten sonra o bandı bir daha kesemez, sıradaki bantlar
/// ise zaten daha aşağıdadır. Kesişme yoksa sonuç [bodyTop]'tur — yani
/// görselsiz notta ipucu her zamanki yerinde kalır.
@visibleForTesting
double hintTopFor(List<FloatBox> floats, double bodyTop, double lineHeight) {
  final sorted = [...floats]..sort((a, b) => a.top.compareTo(b.top));
  var y = bodyTop;
  for (final f in sorted) {
    if (f.top < y + lineHeight && y < f.bottom) {
      // SATIRA OTURT: metin sürekli değil, SATIR SATIR akar — imleç bandın
      // bittiği dp'ye değil, bandı geçen İLK SATIRIN başına iner (sarma planı
      // da tam olarak bunu yapar, bkz. planTextWrap). Yuvarlanmazsa ipucu bir
      // satırın altında kalan bir farkla imlecin üstünde/altında görünür —
      // kullanıcının "ipucu ile imleç farklı yerlerde" dediği fark budur.
      y = lineHeight > 0
          ? bodyTop + ((f.bottom - bodyTop) / lineHeight).ceil() * lineHeight
          : f.bottom;
    }
  }
  return y;
}

/// İpucunun ilk satırda SOLDAN ne kadar içeride başlayacağı (dp).
///
/// KÖK NEDEN (kullanıcı bulgusu 2026-08-16, ekran görüntüsü: "Not... yazısı
/// ile imleç farklı yerlerde, imlecin yeri doğru"): ipucu görselin ALTINA
/// itiliyordu ([hintTopFor]), oysa METİN görselin YANINDAN akıyor — imleç de
/// ilk satırda, görselin sağında duruyordu. İpucu ile imleç iki ayrı yerde
/// görününce not boşken kullanıcı nereye yazacağını göremiyordu.
///
/// Artık ipucu metnin kuralını izler: ilk satırda görselin sağında kullanılır
/// genişlik kalıyorsa ipucu O SATIRDA, görselin sağından başlar; kalmıyorsa
/// (sarma eşiği — bkz. `text_wrap.dart`) eskisi gibi görselin altına iner.
///
/// [columnWidth] metin sütununun genişliği. Dönen değer soldaki dolgudur —
/// üst konum yine [hintTopFor]'dan gelir ve dolgu sıfırdan büyükse o üst konum
/// [bodyTop]'ta kalır.
///
/// DOLGU BURADA HESAPLANMAZ, SARMA PLANINDAN OKUNUR ([wrapLineIndents]).
/// Eskiden buradaki ayrı hesap `left > 0` olan her görseli "sağ kenarda"
/// sayıyordu; ORTADA duran bir görselde plan metni görselin SAĞINA akıtırken
/// ipucu kendini ALTINA indiriyordu (kullanıcı bulgusu 2026-08-30: "imleç
/// kaymıyor ama ipucu başka yerde hâlâ"). Aynı dikiş üçüncü kez patladığı için
/// karar tek kaynağa bağlandı.
({double top, double left}) hintPlacement(
  List<FloatBox> floats,
  double bodyTop,
  double lineHeight,
  double columnWidth, {
  TextDirection direction = TextDirection.ltr,
  double textScaleFactor = 1.0,
}) {
  if (floats.isEmpty || columnWidth <= 0) return (top: bodyTop, left: 0);
  if (lineHeight <= 0) {
    final indents = wrapLineIndents(
      floats: floats,
      columnWidth: columnWidth,
      top: bodyTop,
      bottom: bodyTop,
      direction: direction,
      textScaleFactor: textScaleFactor,
    );
    if (indents.start >= columnWidth) {
      return (top: hintTopFor(floats, bodyTop, lineHeight), left: 0);
    }
    return (top: bodyTop, left: indents.start);
  }
  var y = bodyTop;
  for (var i = 0; i < 256; i++) {
    final indents = wrapLineIndents(
      floats: floats,
      columnWidth: columnWidth,
      top: y,
      bottom: y + lineHeight,
      direction: direction,
      textScaleFactor: textScaleFactor,
    );
    if (indents.start < columnWidth) {
      return (top: y, left: indents.start);
    }
    y += lineHeight;
  }
  return (top: y, left: 0);
}

extension _NotePageCanvasItems on _NotePageCanvasState {
  void _applyMany(List<Attachment> updated) {
    final many = widget.onChangedMany;
    if (many != null) {
      many(updated);
      return;
    }
    for (final a in updated) {
      widget.onChanged(a);
    }
  }

  /// İşaretli görsellerin GENİŞLİĞİNİ eşitler (kullanıcı isteği 2026-09-05:
  /// "görsel boyutu eşitleme seçeneği olsun"). Yükseklik en-boy oranından
  /// çıktığı için aynı orandaki görseller birebir aynı boyuta gelir.
  void _equalizeSizes() {
    final chosen = _multiSelected;
    if (chosen.length < 2 || _cw <= 0) return;
    final target = equalWidthFrac([
      for (final a in chosen) a.displayWidth ?? _defaultWFrac(_cw),
    ]);
    _applyMany([for (final a in chosen) a.copyWith(displayWidth: target)]);
    _endMulti();
  }

  /// İşaretli görselleri [perRow] sütunlu satırlara SIĞDIRIR: kenarları
  /// birbirine ve sayfanın iki yanına yapışacak şekilde yeniden
  /// boyutlandırılıp dizilir (kullanıcı isteği: "2 ya da 3 görseli bir satıra
  /// sığdır"). Seçim sütun sayısını aşarsa satırlara dengeli bölünür
  /// (6 görsel, 3 sütun → 3 + 3; 2 sütun → 2 + 2 + 2).
  ///
  /// SÜTUN SAYISI KULLANICIDA (2026-09-05 geri bildirimi: "hep 3 sütunlu
  /// yapıyor, 2 sütunlu da olmalı"): eskiden satır başına en çok 3 görsel
  /// sabitti ve altı görsel her zaman 3+3 diziliyordu.
  ///
  /// Blok, seçili görsellerin EN ÜSTTEKİNİN hizasından başlar: kullanıcı
  /// düzenlediği yeri kaybetmesin.
  void _fitRow(int perRow) {
    final chosen = _multiSelected;
    final cw = _cw;
    if (chosen.length < 2 || cw <= 0) return;
    var top = double.infinity;
    for (final img in chosen) {
      final t = _resolve(img, cw).top;
      if (t < top) top = t;
    }
    if (!top.isFinite) top = widget.topLimit + kImageGap;
    final fits = fitRowsLayout(
      aspects: [for (final a in chosen) _aspectOf(a)],
      columnWidth: cw,
      top: math.max(top, widget.topLimit),
      // Satır başına en çok 6: 1/7 genişlik [_minWidthFrac]'ın altına düşer
      // ve tuval genişliği yukarı kırparken görseller birbirine binerdi.
      maxPerRow: perRow.clamp(1, chosen.length).clamp(1, 6),
    );
    _applyMany([
      for (var i = 0; i < chosen.length && i < fits.length; i++)
        chosen[i].copyWith(
          displayWidth: fits[i].widthFrac,
          x: fits[i].leftFrac,
          pageY: fits[i].top,
        ),
    ]);
    _endMulti();
  }

  double _aspectOf(Attachment img) {
    final live = _tableAspect[img.id];
    if (live != null) return live;
    if (img.width == null ||
        img.height == null ||
        img.width! <= 0 ||
        img.height! <= 0) {
      // Metin/ses kutusunun ölçüsü yazılmadıysa (başka cihazdan gelen eski
      // kayıt) kutunun KENDİ oranı — kare varsayımı kâğıdı ezerdi.
      return switch (img.kind) {
        AttachmentKind.text => kTextBoxWidth / kTextBoxHeight,
        AttachmentKind.audio => kAudioBoxWidth / kAudioBoxHeight,
        AttachmentKind.pdf => pdfBoxAspect(1, 1.414, img.pdfTurns),
        AttachmentKind.slide || AttachmentKind.video => 16 / 9,
        _ => 1.0,
      };
    }
    if (img.kind == AttachmentKind.pdf) {
      return pdfBoxAspect(
        img.width!.toDouble(),
        img.height!.toDouble(),
        img.pdfTurns,
      );
    }
    return img.width! / img.height!;
  }

  /// Genişliği yazılmamış görselin varsayılan genişlik oranı.
  ///
  /// Tek görsel sütunun yarısını kaplar. Nota İKİNCİ görsel girdiği anda
  /// varsayılan bir tık daralır: iki görsel araya boşluk da girerek AYNI
  /// SATIRA sığsın (bkz. [packSlot]). 0,5 + 0,5 satıra sığmadığı için ikinci
  /// görsel her seferinde alta iniyordu. BEŞ ve üzeri görselde satıra üç
  /// tane sığar: paylaşımdan gelen bir demet fotoğraf (konum/genişlik
  /// yazılmadan gelirler) düzgün bir ızgaraya otursun.
  double _defaultWFrac(double cw) {
    final count = widget.images.length;
    if (count < 2 || cw <= 0) return 0.5;
    final perRow = count >= 5 ? 3 : 2;
    return (((cw - kImageGap * (perRow - 1)) / perRow) / cw)
        .clamp(_NotePageCanvasState._minWidthFrac, 1.0)
        .toDouble();
  }

  /// Görselin sayfadaki ölçüsü (dp) — canlı boyutlandırma değeri öncelikli.
  ({double w, double h}) _sizeOf(Attachment img, double cw) {
    final wFrac =
        ((_resizeId == img.id && _resizeWFrac != null)
                ? _resizeWFrac!
                : (img.displayWidth ?? _defaultWFrac(cw)))
            .clamp(_NotePageCanvasState._minWidthFrac, 1.0)
            .toDouble();
    final w = cw * wFrac;
    // SES bir HAPTIR (2026-10-28): genişlik ne olursa olsun boyu sabit
    // aralıkta — geniş ekranda tam genişlik ses kartı 150 dp'lik bir blok
    // olmasın, dar kutuda da düğmeler sığsın.
    //
    // 2026-11-13 (tablet bulgusu: "ses kaydının yüzen görünümü çok büyük ve
    // yüksek"): geniş sayfada yarım genişlik 600 dp'lik bir şerit oluyordu —
    // hap en çok [kAudioFloatMaxWidth] geniş, boyu 48–60 dp.
    if (img.kind == AttachmentKind.audio) {
      final aw = math.min(w, kAudioFloatMaxWidth);
      return (w: aw, h: (aw / _aspectOf(img)).clamp(48.0, 60.0).toDouble());
    }
    return (w: w, h: w / _aspectOf(img));
  }

  /// Konumu YAZILMAMIŞ görselin (paylaşımdan gelen, sayfa ölçülmeden eklenen,
  /// eski kayıt) sayfadaki otomatik yeri — kare başına BİR kez hesaplanır.
  ///
  /// KÖK NEDEN (kullanıcı 2026-08-16: "3 resim gönderdim 2'si geldi ve üst
  /// üste geldiler"; yine 2026-09-05: "birden fazla görsel eklendiğinde üst
  /// üste başlıyor"): burada gerçek yüksekliklerle bir DİKEY yığın kuruluyordu
  /// ama sonuç [NotePageCanvas.topLimit]'e kırpılıyordu — başlığın altına
  /// düşen bütün görseller aynı çizgiye çöküyor, yani üst üste biniyordu.
  /// Üstelik yığın hep alta indiği için satırın sağındaki koca boşluk hiç
  /// kullanılmıyordu.
  ///
  /// Artık yerleşim [packSlot] ile yapılır: görsel önce SATIRDA yan yana yer
  /// arar, sığmazsa alta iner ve kullanıcının elle yerleştirdiği görsellerin
  /// üstüne de binmez.
  void _computeAutoSlots(double cw) {
    _cw = cw;
    _autoSlots.clear();
    if (cw <= 0) return;
    final occupied = <Rect>[];
    // Önce kullanıcının yerleştirdiği görseller: otomatik yerleşim onlara
    // çarpmadan boşluk arar.
    for (final img in widget.images) {
      if (_isAuto(img)) continue;
      final r = _resolve(img, cw);
      occupied.add(
        Rect.fromLTWH(r.left, r.top, r.w, r.h + _captionBand(img, r.w)),
      );
    }
    for (final img in widget.images) {
      if (!_isAuto(img)) continue;
      final size = _sizeOf(img, cw);
      final h = size.h + _captionBand(img, size.w);
      final slot = packSlot(
        occupied: occupied,
        columnWidth: cw,
        width: size.w,
        height: h,
        anchorTop: widget.topLimit + kImageGap,
        topLimit: widget.topLimit,
      );
      _autoSlots[img.id] = slot;
      occupied.add(Rect.fromLTWH(slot.left, slot.top, size.w, h));
    }
  }

  /// Konumu hiç yazılmamış görsel mi (yeri otomatik hesaplanır).
  bool _isAuto(Attachment img) => img.pageY == null && img.y == null;

  /// Görselin sayfadaki nihai yerleşimi (dp). Canlı taşıma/boyutlandırma
  /// değerleri öncelikli. Üst sınır 0'a kırpılır; alt sınır yok — sayfa uzar.
  ({double left, double top, double w, double h}) _resolve(
    Attachment img,
    double cw,
  ) {
    final size = _sizeOf(img, cw);
    final w = size.w;
    final auto = _autoSlots[img.id];
    var left = (_moveId == img.id && _moveLeft != null)
        ? _moveLeft!
        : (auto?.left ?? (img.x ?? 0.06) * cw);
    var top = (_moveId == img.id && _moveTop != null)
        ? _moveTop!
        : (auto?.top ??
              img.pageY ??
              (img.y != null
                  ? img.y! * kLegacyCanvasHeight
                  : widget.topLimit + kImageGap));
    left = left.clamp(0.0, (cw - w).clamp(0.0, cw)).toDouble();
    // Başlık/çip bölgesi görsele kapalı: üst sınırın altına inemez.
    if (top < widget.topLimit) top = widget.topLimit;
    return (left: left, top: top, w: w, h: size.h);
  }

  /// [img] DIŞINDAKİ görsellerin sayfa kutuları — yapışma, çarpışma ve
  /// kılavuzlar bunlara göre hesaplanır.
  List<Rect> _othersOf(Attachment img, double cw) {
    final out = <Rect>[];
    for (final other in widget.images) {
      if (other.id == img.id) continue;
      final r = _resolve(other, cw);
      out.add(
        Rect.fromLTWH(r.left, r.top, r.w, r.h + _captionBand(other, r.w)),
      );
    }
    return out;
  }

  /// Görsellerin SAYFA uzayındaki dışlama bantları. Metin alanları kendi
  /// konumlarını ölçüp bunları kendi uzaylarına çevirir (bkz.
  /// [WrapFieldMeasure]). Metnin görsele değmemesi için yatayda 12, dikeyde
  /// 8 dp pay bırakılır.
  List<FloatBox> _floatsFor(double cw) {
    final boxes = <FloatBox>[];
    final textCol = (cw - widget.textLeft * 2).clamp(0.0, cw);
    final minSide = math.max(textCol * 0.35, 72.0);
    for (final img in widget.images) {
      final r = _resolve(img, cw);
      final webControls = (_playingWeb.contains(img.id) && r.w >= 150)
          ? 48.0
          : 0.0;
      final fLeft = r.left - 12;
      final fRight = r.left + r.w + 12;
      final leftSpace = (fLeft - widget.textLeft).clamp(0.0, textCol);
      final rightSpace = ((cw - widget.textLeft) - fRight).clamp(0.0, textCol);
      boxes.add(
        FloatBox(
          top: r.top,
          left: fLeft,
          right: fRight,
          // Açıklama ve yerinde YouTube denetimleri görselin parçası: metin
          // onların da etrafından akar.
          height: r.h + _captionBand(img, r.w) + webControls + 8,
          // Yanında okunur yer bırakmayan kutu (tam genişlik tablo/görsel):
          // liste maddesi onun etrafından BÖLÜNEREK akmaz, bütünüyle altına
          // iner (kullanıcı bulgusu 2026-11-23: "tablo maddeyi bölebiliyor").
          block: math.max(leftSpace, rightSpace) < minSide,
        ),
      );
    }
    return boxes;
  }

  /// İpucunun SAYFA uzayındaki yeri.
  ///
  /// Hesap METİN SÜTUNU uzayında yapılır (bantlar sola/sağa kenar boşluğu
  /// kadar kaydırılır, sütun genişliği iki kenar boşluğu düşülerek verilir) —
  /// sarma planı da tam olarak bu uzayda çalışıyor (bkz. WrapFieldMeasure).
  /// İki hesap ayrı uzaylarda yapılırsa ipucu ile imleç ayrı yerlere düşer.
  ({double top, double left}) _hintPlacement(double cw) {
    final inset = widget.textLeft;
    final place = hintPlacement(
      [
        for (final f in _floatsFor(cw))
          FloatBox(
            top: f.top,
            left: f.left - inset,
            right: f.right - inset,
            height: f.height,
          ),
      ],
      // METİN uzayı: ipucu, alanın kutusuna değil ilk satırın tepesine oturur.
      widget.topLimit + widget.textTop,
      widget.hintLineHeight,
      (cw - inset * 2).clamp(0.0, cw),
      // Okunur genişlik tabanı yazı ölçeğiyle büyüyor; sarma planı da AYNI
      // ölçeği kullanıyor (bkz. WrapFieldMeasure), yoksa büyük yazıda ipucu
      // ile metin yine ayrışır.
      textScaleFactor: MediaQuery.textScalerOf(context).scale(1),
      direction: Directionality.of(context),
    );
    return (top: place.top, left: inset + place.left);
  }

  /// Çoklu seçim işlem çubuğu — ekranın dibinde, kaydırmadan bağımsız.
  Widget _multiToolbar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final keyboard = KeyboardInset.liveOf(context);
    final systemBar = MediaQuery.viewPaddingOf(context).bottom;
    final chosen = _multiSelected;
    return Positioned(
      left: 8,
      right: 8,
      // Klavye yüksekliği gezinme çubuğunu ZATEN içeriyor: ikisini toplamak
      // klavye açıkken çubuğu klavyeden ~48 dp yukarıda asılı bırakıyordu.
      bottom: 8 + (keyboard > systemBar ? keyboard : systemBar),
      child: Material(
        color: scheme.primaryContainer,
        elevation: 6,
        borderRadius: BorderRadius.circular(AppRadius.l),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            children: [
              IconButton(
                tooltip: l10n.cancel,
                visualDensity: _NotePageCanvasState._kBarDensity,
                icon: const Icon(Icons.close, size: AppIconSize.m),
                onPressed: _endMulti,
              ),
              Expanded(
                child: Text(
                  l10n.imagesSelectedCount(chosen.length),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              IconButton(
                tooltip: l10n.selectAllItems,
                visualDensity: _NotePageCanvasState._kBarDensity,
                icon: const Icon(Icons.select_all, size: AppIconSize.m),
                onPressed: () => _redraw(
                  () => _multi
                    ..clear()
                    ..addAll(widget.images.map((i) => i.id)),
                ),
              ),
              IconButton(
                tooltip: l10n.imagesEqualizeSize,
                visualDensity: _NotePageCanvasState._kBarDensity,
                icon: const Icon(Icons.straighten, size: AppIconSize.m),
                onPressed: chosen.length < 2 ? null : _equalizeSizes,
              ),
              // Sığdırma SÜTUN SAYISINI sorar: aynı altı görsel kimi zaman
              // 3+3, kimi zaman 2+2+2 isteniyor.
              PopupMenuButton<int>(
                tooltip: l10n.imagesFitRow,
                enabled: chosen.length >= 2,
                icon: const Icon(
                  Icons.view_column_outlined,
                  size: AppIconSize.m,
                ),
                onSelected: _fitRow,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 2,
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.view_agenda_outlined),
                      title: Text(l10n.imagesFitColumns(2)),
                    ),
                  ),
                  PopupMenuItem(
                    value: 3,
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.view_column_outlined),
                      title: Text(l10n.imagesFitColumns(3)),
                    ),
                  ),
                  PopupMenuItem(
                    value: 4,
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.view_module_outlined),
                      title: Text(l10n.imagesFitColumns(4)),
                    ),
                  ),
                  // Hepsi TEK satıra: seçim kaç taneyse o kadar sütun.
                  PopupMenuItem(
                    value: 99,
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.table_rows_outlined),
                      title: Text(l10n.imagesFitSingleRow),
                    ),
                  ),
                ],
              ),
              IconButton(
                tooltip: l10n.copy,
                visualDensity: _NotePageCanvasState._kBarDensity,
                icon: const Icon(AppIcons.copy, size: AppIconSize.m),
                onPressed: chosen.isEmpty
                    ? null
                    : () {
                        widget.onCopyMany?.call(chosen);
                        _endMulti();
                      },
              ),
              IconButton(
                tooltip: l10n.delete,
                visualDensity: _NotePageCanvasState._kBarDensity,
                icon: const Icon(Icons.delete_outline, size: AppIconSize.m),
                onPressed: chosen.isEmpty
                    ? null
                    : () {
                        for (final img in chosen) {
                          widget.onRemove(img);
                        }
                        _endMulti();
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Görseli sayfanın üzerinde BÜYÜK gösteren geçici katman. Boyut/konum
  /// değiştirmez; herhangi bir yere dokunmak kapatır.
  Widget _preview(BuildContext context, Attachment img, double cw) {
    final scheme = Theme.of(context).colorScheme;
    final aspect =
        (img.width != null &&
            img.height != null &&
            img.width! > 0 &&
            img.height! > 0)
        ? img.width! / img.height!
        : 1.0;
    // Görünür alanın içinde kal: hem genişlik hem yükseklik sınırlanır ki
    // uzun görseller taşmasın.
    final maxW = cw - 16;
    final maxH = widget.minHeight - 32;
    var w = maxW;
    var h = w / aspect;
    if (h > maxH && maxH > 0) {
      h = maxH;
      w = h * aspect;
    }
    // KAPATMA ALANI SAYFANIN TAMAMI (kullanıcı bulgusu 2026-08-10: "görseli
    // ön izlemede açıkça üst ve yanlarına tıklayınca kapanıyor ama altına
    // tıklayınca kapanmıyor"): kutu `Positioned(top: …)` idi ve alt sınırı
    // olmadığı için yalnız GÖRSELİN KENDİ BANDI kadar yer kaplıyordu — o
    // bandın altına düşen dokunuş önizlemeye hiç ulaşmıyor, altındaki sayfaya
    // (metin alanına/boşluğa) gidiyordu. `Positioned.fill` ile katman sayfanın
    // tamamını kapsar: neresine dokunulursa dokunulsun önizleme kapanır ve
    // dokunuş sayfaya SIZMAZ (opaque).
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _closePreview,
        // İç Stack: kart yine yalnız YUKARIDAN konumlanır (alt sınırı yok),
        // yani yüksekliği eskisi gibi serbest kalır — `Padding` kullanılsaydı
        // uzun görselde kalan yer daralıp taşma verirdi.
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              // Önizleme, sayfanın görünen kısmına yakın dursun diye üst sınır
              // görselin bandına göre verilir.
              top: (widget.topLimit + 8).clamp(0.0, double.infinity),
              child: Center(
                child: Material(
                  elevation: 8,
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(AppRadius.l),
                  clipBehavior: Clip.antiAlias,
                  child: SizedBox(
                    width: w,
                    height: h,
                    child: Stack(
                      children: [
                        // Yana kaydırınca nottaki diğer göresele geçilir;
                        // kutu boyutu geçilen görselin oranına göre yenilenir.
                        Positioned.fill(
                          child: widget.images.length < 2
                              ? _boxFor(img, fit: BoxFit.contain)
                              : PageView.builder(
                                  controller: _previewPages,
                                  itemCount: widget.images.length,
                                  onPageChanged: (i) => _redraw(
                                    () => _previewId = widget.images[i].id,
                                  ),
                                  itemBuilder: (context, i) => _boxFor(
                                    widget.images[i],
                                    fit: BoxFit.contain,
                                  ),
                                ),
                        ),
                        Positioned(
                          right: 4,
                          top: 4,
                          child: IconButton(
                            tooltip: context.l10n.close,
                            icon: const Icon(Icons.close, size: AppIconSize.m),
                            color: Colors.white,
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black45,
                            ),
                            onPressed: _closePreview,
                          ),
                        ),
                        // Kaçıncı görselde olduğumuz: kaydırmanın bir sonu
                        // olduğu görünsün.
                        if (widget.images.length > 1)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 6,
                            child: Center(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.black45,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  child: Text(
                                    '${widget.images.indexWhere((a) => a.id == img.id) + 1}'
                                    '/${widget.images.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: AppWeight.strong,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _positioned(BuildContext context, Attachment img, double cw) {
    final scheme = Theme.of(context).colorScheme;
    final editing = _selectedId == img.id;
    final checked = _multiMode && _multi.contains(img.id);
    final moving = _moveId == img.id;
    final r = _resolve(img, cw);
    // Ses hapı yuvarlak uçlu ve çerçevesiz (seçiliyken çerçeve gelir).
    final pill = img.kind == AttachmentKind.audio;
    final radius = BorderRadius.circular(pill ? r.h / 2 : 12);
    return Positioned(
      // Anahtar ölçüm içindir: yerleşim testleri kutunun ekrandaki dikdörtgenini
      // bu anahtarla okur (bkz. test/note_canvas_layout_test.dart).
      key: ValueKey('page-image-${img.id}'),
      left: r.left,
      top: r.top,
      width: r.w,
      height: r.h,
      child: _hoverMenu(
        img,
        editing,
        GestureDetector(
          // Eke sağ tık (masaüstü, F40.8): tek ek menüsü, imlecin yanında.
          onSecondaryTapUp: (d) =>
              unawaited(_contextMenu(img, d.globalPosition)),
          onTap: () => _multiMode ? _toggleMulti(img.id) : _select(img.id),
          // ÇİFT DOKUNUŞ = büyük önizleme, ama YALNIZ görsel SEÇİLİYKEN.
          //
          // KÖK NEDEN (kullanıcı 2026-09-05: "görselleri seçerken gecikme
          // var"): çift dokunuş tanıyıcısı kayıtlıyken tek dokunuşun kararı
          // ikinci dokunuş penceresi (~300 ms) dolmadan VERİLEMEZ — her seçim,
          // her işaretleme o kadar bekliyordu. Tanıyıcı artık yalnız seçili
          // görselde kurulur: seçme ve çoklu seçimde işaretleme ANINDA olur,
          // önizleme de seçtikten sonra çift dokunuşla (ya da her zaman olduğu
          // gibi sağ-alt köşedeki tutamağa dokunarak) hâlâ açılır.
          onDoubleTap: editing && !_multiMode
              ? () => _togglePreview(img.id)
              : null,
          // Taşıma TEK jestte: basılı tut, parmağını kaldırmadan sürükle.
          // (Önce seçip sonra sürüklemek gerekiyordu — kullanımı zordu.)
          // Uzun basma dikey kaydırmayla çakışmaz: sayfa kaydırma anlık
          // sürüklemeyle başlar, taşıma ise basılı tutmayı bekler.
          onLongPressStart: (d) {
            // Çoklu seçim açıkken taşıma kapalı: parmak işaretlemek için
            // geziyor, kazara görsel sürüklenmesin.
            if (_multiMode) {
              _toggleMulti(img.id);
              return;
            }
            AppHaptics.tick();
            if (widget.onPinTop != null) widget.onPinDrag?.call(true);
            _redraw(() {
              _selectedId = img.id;
              _moveId = img.id;
              // Sürükleme başlangıcı ayrı tutulur: _resolve taşıma sırasında
              // canlı değeri döndürdüğü için onu baz almak kaymayı katlardı.
              _moveOriginLeft = r.left;
              _moveOriginTop = r.top;
              _moveLeft = r.left;
              _moveTop = r.top;
            });
          },
          // KENAR ÇARPIŞMASI + KILAVUZ (kullanıcı isteği 2026-09-05): parmağın
          // istediği ham kutu [snapMove]'a verilir; kenarlar sayfaya ve komşulara
          // yapışır, hafif temasta çarpışıp durur, parmak komşunun derinine
          // girmeye devam ederse engel kalkar. Ham konum SAKLANMAZ, her karede
          // sürüklemenin başlangıcından yeniden hesaplanır: yapışmış değer geri
          // beslenseydi görsel kılavuzdan kopamazdı.
          onLongPressMoveUpdate: (d) {
            if (_moveId != img.id) return;
            _setPinZone(
              _pinZoneHit(
                d.globalPosition,
                rawTop: (_moveOriginTop ?? r.top) + d.offsetFromOrigin.dy,
              ),
            );
            final snapped = snapMove(
              rect: Rect.fromLTWH(
                (_moveOriginLeft ?? r.left) + d.offsetFromOrigin.dx,
                (_moveOriginTop ?? r.top) + d.offsetFromOrigin.dy,
                r.w,
                r.h,
              ),
              others: _othersOf(img, cw),
              columnWidth: cw,
              topLimit: widget.topLimit,
            );
            if (_guides.isEmpty && snapped.guides.isNotEmpty) {
              AppHaptics.tick();
            }
            _redraw(() {
              _moveLeft = snapped.left;
              _moveTop = snapped.top;
              _guides = snapped.guides;
            });
          },
          onLongPressEnd: (_) => _commitMove(img, cw),
          onLongPressCancel: () {
            // İptal (ör. jest başka bir tanıyıcıya geçti) sabitleme SAYILMAZ.
            _setPinZone(false);
            _commitMove(img, cw);
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    border: editing || checked
                        ? Border.all(color: scheme.primary, width: 2)
                        : pill
                        ? null
                        : Border.all(
                            color: scheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                  ),
                  // RepaintBoundary: görsel kendi katmanına çizilir. Sayfada
                  // yazarken/kaydırırken imleç ve satırlar sık sık yeniden
                  // çiziliyor; sınır olmadan her seferinde görselin rasterı da
                  // yeniden çiziliyordu (birkaç görselli notta kare bütçesinin
                  // görünür bir dilimi).
                  // SÜRÜKLERKEN YARI SAYDAM (kullanıcı bulgusu 2026-08-10: "notu
                  // sürüklediğinde metin notu resmin altında kalıyor"): görseller
                  // metnin ÜSTÜNE çizilir, metin de onların etrafından akar —
                  // ama akış ancak yeni bantlar ölçülüp uygulandıktan sonra
                  // yerine oturur (ölçüm kare sonunda yapılır). Parmak hızlıysa
                  // görsel arada metnin üstünde duruyor ve altındaki satırlar
                  // tümüyle kayboluyordu. Saydamlık yalnız TAŞIMA sürerken: metin
                  // her an okunur kalır, bırakınca görsel tam opak olur ve sarma
                  // zaten kesin konuma göre hesaplanmıştır.
                  child: Opacity(
                    opacity: moving ? 0.55 : 1,
                    child: RepaintBoundary(
                      child: ClipRRect(
                        borderRadius: radius,
                        child: _boxFor(img),
                      ),
                    ),
                  ),
                ),
              ),
              // Çoklu seçim rozeti: işaretliyse dolu tik, değilse boş halka.
              if (_multiMode)
                Positioned(
                  left: 4,
                  top: 4,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: checked ? scheme.primary : Colors.black45,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: checked
                        ? Icon(Icons.check, size: 14, color: scheme.onPrimary)
                        : null,
                  ),
                ),
              // Sağ-alt köşe tutamağı: serbest boyutlandırma (yalnız seçiliyken).
              if (editing && !_multiMode)
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: GestureDetector(
                    // Köşe tutamağı SÜRÜKLENİYOR ama dokunmak hiçbir şey
                    // yapmıyordu; küçültülmüş bir görseli okumak için ya tam
                    // ekrana gitmek ya da büyütüp sonra geri küçültmek
                    // gerekiyordu. Dokunuş artık BÜYÜK ÖNİZLEME açar: görsel
                    // sayfanın üstünde büyük çizilir, düzen (ve metnin akışı)
                    // hiç değişmez — kapanınca her şey yerli yerinde kalır.
                    onTap: () => _togglePreview(img.id),
                    onPanStart: (_) => _redraw(() {
                      _resizeId = img.id;
                      _resizeWFrac = (img.displayWidth ?? _defaultWFrac(cw))
                          .clamp(_NotePageCanvasState._minWidthFrac, 1.0)
                          .toDouble();
                      _resizeRawFrac = _resizeWFrac;
                    }),
                    // Boyutlandırırken de kılavuz çıkar: sağ kenar sayfanın
                    // kenarına/ortasına, komşunun kenarına ya da komşuyla EŞİT
                    // genişliğe yapışır.
                    onPanUpdate: (d) {
                      final base =
                          _resizeRawFrac ??
                          (img.displayWidth ?? _defaultWFrac(cw));
                      final raw = (base + d.delta.dx / cw)
                          .clamp(_NotePageCanvasState._minWidthFrac, 1.0)
                          .toDouble();
                      final snapped = snapWidth(
                        left: r.left,
                        width: raw * cw,
                        others: _othersOf(img, cw),
                        columnWidth: cw,
                      );
                      if (_guides.isEmpty && snapped.guides.isNotEmpty) {
                        AppHaptics.tick();
                      }
                      _redraw(() {
                        _resizeRawFrac = raw;
                        _resizeWFrac = (snapped.width / cw)
                            .clamp(_NotePageCanvasState._minWidthFrac, 1.0)
                            .toDouble();
                        _guides = snapped.guides;
                      });
                    },
                    onPanEnd: (_) {
                      final f = _resizeWFrac;
                      if (f != null) {
                        widget.onChanged(img.copyWith(displayWidth: f));
                      }
                      _redraw(() {
                        _resizeId = null;
                        _resizeWFrac = null;
                        _resizeRawFrac = null;
                        _guides = const [];
                      });
                    },
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: scheme.onPrimary, width: 2),
                      ),
                      child: Icon(
                        Icons.open_in_full,
                        size: 13,
                        color: scheme.onPrimary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Araç çubuğu seçili görselin hemen altında belirir (sayfa uzun olduğundan
  /// alta sabitlemek görünmez kalabilirdi).
  Widget _toolbar(BuildContext context, Attachment img, double cw) {
    final r = _resolve(img, cw);
    final wFrac =
        ((_resizeId == img.id && _resizeWFrac != null)
                ? _resizeWFrac!
                : (img.displayWidth ?? _defaultWFrac(cw)))
            .clamp(_NotePageCanvasState._minWidthFrac, 1.0)
            .toDouble();
    // OCR ve pano kopyası görsele özgü; videoda ve PDF'te menüde gösterilmez
    // (taşı/boyutlandır/tam ekran/sil ve "Ek olarak taşı" ortak). PDF'in
    // metni kendi kutusundaki menüden sayfa sayfa alınır — dosyanın tamamını
    // OCR'a vermek yanlış araç olurdu (bkz. [PdfPageBox]).
    final isVideo = img.kind == AttachmentKind.video;
    final isPdf = img.kind == AttachmentKind.pdf;
    // Metin ve ses kutusunda görsel işlemleri (OCR, metne dök) anlamsız.
    final isPlain =
        img.kind == AttachmentKind.text || img.kind == AttachmentKind.audio;
    // Geniş sayfada (tablet) panel tek satır ve ekin altında, sayfa boyu
    // değil (bkz. [_ImageTools.wide]).
    final wide = cw >= kWideToolsMinPage;
    final width = wide ? math.min(cw - 16, kWideToolsMaxWidth) : null;
    final left = width == null
        ? 8.0
        : r.left.clamp(8.0, math.max(8.0, cw - 8 - width)).toDouble();
    return Positioned(
      left: left,
      right: width == null ? 8 : null,
      width: width,
      top: r.top + r.h + _captionBand(img, r.w) + 6,
      // Panel seçilen ekin altından süzülerek belirir (her yeni seçimde).
      child: PopIn(
        key: ValueKey('tools-${img.id}'),
        duration: AppMotion.short,
        child: _toolbarBody(context, img, wFrac, isVideo, isPdf, isPlain, wide),
      ),
    );
  }
}
