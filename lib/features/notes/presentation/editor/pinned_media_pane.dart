import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable, kIsWeb;
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../app/window_class.dart';
import '../../../../core/l10n_ext.dart';
import '../../../../core/tips.dart';
import '../../../../core/personalize.dart';
import '../../../../core/widgets/after_route_transition.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/keyboard_snap.dart';
import '../../../../core/widgets/customizable.dart';
import '../../../../core/widgets/sheet_header.dart';
import '../../../../core/widgets/sheet_tile.dart';
import '../../../../core/widgets/wheel_scroll_viewer.dart';
import '../../data/scan/scan_pdf.dart';
import '../../domain/attachment.dart';
import '../../domain/note_table.dart';
import '../drive_ui.dart';
import '../viewers/image_luma.dart';
import '../viewers/ink_tools.dart' show InkToolMemory;
import '../viewers/pen_policy.dart';
import 'pinned_image_surface.dart';
import 'pinned_media_bar.dart';
import 'pinned_side.dart';
import '../viewers/bubble_layer.dart';
import '../viewers/ink_layer.dart';
import '../viewers/pdf_read_style.dart';
import 'note_images.dart';
import 'attachment_actions.dart';
import 'audio_card_box.dart';
import 'pdf_page_box.dart';
import 'slide_page_box.dart';
import 'table_page_box.dart';
import 'text_page_box.dart';
import 'video_hub_scope.dart';
import 'video_transport.dart';
import '../../../../core/haptics.dart';

export 'pinned_media_bar.dart' show kPinnedBarHeight;

/// Sabit bölmenin yüksekliği bu sınırlar arasında kalır (dp / oran).
const double kPinnedMinHeight = 96;
const double kPinnedMaxFraction = 0.7;

/// Ayraç bu yüksekliğin altına çekilip bırakılırsa medya sayfaya geri döner.
const double kPinnedUnpinHeight = 72;

/// Klavye açıkken bölmenin altında notun yazılan satırına kalan en az yer.
const double kPinnedNoteMinHeight = 72;

/// Klavye açıkken medyanın görünür penceresinin en az yüksekliği.
const double kPinnedVisibleFloor = 56;

/// Bölmenin en büyük yüksekliği.
///
/// KÖK NEDEN (kullanıcı bulgusu 2026-10-19: "video sabitken klavye
/// açıldığında video yukarı itiliyor biraz"): sınır, O ANKİ yüksekliğin
/// %70'iydi. Klavye oturunca gövde klavye kadar kısalıyor, sınır da onunla
/// birlikte düşüyordu — bölme büzülüyor, video küçülüp yukarı kayıyor, çubuk
/// zıplıyordu. Artık oran klavyesiz (en büyük görülen) yükseklikten alınır;
/// klavye açıkken bölme YERİNDE kalır, yalnız not satırına
/// [kPinnedNoteMinHeight] kalmayacaksa küçülür.
double pinnedMaxHeight({required double available, required double stable}) {
  final byFraction = stable * kPinnedMaxFraction;
  final byRoom = available - kPinnedBarHeight - kPinnedNoteMinHeight;
  final max = byFraction < byRoom ? byFraction : byRoom;
  return max < kPinnedMinHeight ? kPinnedMinHeight : max;
}

/// Yeni sabitlenen medyanın ilk yüksekliği: ekran genişliğinde medyanın kendi
/// oranı, ekranın %45'ini geçmeden. Oranı bilinmeyen video 16:9 sayılır.
double defaultPinnedHeight(Attachment media, Size screen) {
  // Ses: oynatıcı kartı kadar; metin: okunacak kadar (ekranın %40'ı).
  if (media.kind == AttachmentKind.audio) return 104;
  if (media.kind == AttachmentKind.text) {
    return (screen.height * 0.4).clamp(kPinnedMinHeight, screen.height * 0.5);
  }
  final w = (media.width ?? 0).toDouble();
  final h = (media.height ?? 0).toDouble();
  final pdf = media.kind == AttachmentKind.pdf;
  final ratio = w > 0 && h > 0
      ? (pdf ? 1 / pdfBoxAspect(w, h, media.pdfTurns) : h / w)
      : (media.kind == AttachmentKind.video ||
                media.kind == AttachmentKind.slide
            ? 9 / 16
            : pdf
            ? 1.41
            : 3 / 4);
  final natural = screen.width * ratio;
  // Belge okunacak kadar uzun açılır (A4 sayfa ekranın yarısında bile
  // okunur); görsel/video ekranın %45'ini geçmez.
  // 2026-11-21: görsel de ekranın yarısına kadar (kullanıcı: "fazla
  // daraltmasın").
  final max = screen.height * (pdf || media.kind == AttachmentKind.image
      ? 0.5
      : 0.45);
  return natural.clamp(
    kPinnedMinHeight,
    max < kPinnedMinHeight ? kPinnedMinHeight : max,
  );
}

/// **ÜSTTE MEDYA, ALTTA NOT** (kullanıcı isteği 2026-10-11).
///
/// Görsel ya da video notun tepesinde SABİT durur, not ([child]) altında
/// kendi başına kayar — video izlerken ya da bir görsele bakarken yazmak
/// için. Bölme ile not arasındaki AYRAÇ sürüklenerek boyutlanır (bırakınca
/// [onHeightChanged] kaydeder); ayraç en alta değil en ÜSTE, bölmeyi
/// kapatacak kadar çekilirse ya da medya basılı tutulup nota doğru aşağı
/// sürüklenirse medya sayfaya geri döner ([onUnpin]).
class PinnedMediaPane extends StatefulWidget {
  const PinnedMediaPane({
    super.key,
    required this.media,
    required this.onHeightChanged,
    required this.onUnpin,
    required this.onOpen,
    required this.child,
    this.onCopyLink,
    this.onCopy,
    this.onExtractText,
    this.onChanged,
    this.onTableChanged,
    this.onInkChanged,
    this.viewSwitch,
    this.sheetViewSwitch,
    this.onPenOff,
    this.onPenOn,
    this.shrinkToFit = false,
    this.onShrinkToFitChanged,
    this.onCaption,
    this.onNoteAt,
    this.bubbleDoc,
    this.onRemove,
    this.onSaveAs,
    this.onShare,
    this.onTranscribe,
    this.onPdfNote,
    this.onInsertToNote,
    this.onSmartSummarize,
    this.onSmartTasks,
    this.onSmartAreaAsk,
    this.onImmersiveChanged,
    this.penActive = false,
    this.fill = false,
    this.side = PinnedSide.top,
    this.onCycleSide,
    this.onSelectSide,
  });

  /// Editörün kalem kipi açık: sabit PDF'in üstüne doğrudan yazılır
  /// (kullanıcı isteği 2026-11-08). Kapalıyken bölmenin çubuğundaki kalem
  /// düğmesi aynı katmanı yalnız bu bölme için açar. Düğme iki durumda da
  /// görünür ve açık durumu gösterir (bkz. `_togglePen`).
  final bool penActive;

  /// Çubuğun kalem düğmesi AÇARKEN editörün NORMAL kalem kipini açar
  /// (kullanıcı isteği 2026-11-21: "PDF'de kalem basınca panel değişmesin,
  /// bizim normal kalem özellikleri açılsın"). null ise bölme eski usul
  /// kendi hızlı kalemini açar ([_penTools]).
  final VoidCallback? onPenOn;

  /// **DARALTINCA KÜÇÜLSÜN MÜ** (kullanıcı isteği 2026-11-21: "görselde
  /// yukarı sürükleyince görsel küçülüyor, PDF'te küçülmüyor — tutarsız;
  /// PDF'teki güzel ama iki seçenek de olsun, not başına, varsayılan
  /// PDF'teki gibi"). false (varsayılan): medya bölmenin GENİŞLİĞİNE oturur,
  /// boyu taşarsa dikeyde kayar. true: medya bölmeye sığacak kadar küçülür.
  final bool shrinkToFit;

  /// ⋮ menüsündeki anahtar; null ise anahtar yok.
  final ValueChanged<bool>? onShrinkToFitChanged;

  /// YAN YERLEŞİM (2026-11-09): medya bölmenin TAMAMINI kaplar (not öbür
  /// sütunda, [child] boş); çubuktan boy sürüklenmez.
  final bool fill;

  /// Şu anki yerleşim (çubuktaki düğmenin simgesi).
  final PinnedSide side;

  /// Üst → sol → sağ geçişi; null = düğme yok (dar ekran).
  final VoidCallback? onCycleSide;

  /// Doğrudan yerleşim seçimi (⋮ levhasındaki Üstte / Solda / Sağda).
  final ValueChanged<PinnedSide>? onSelectSide;

  /// Balon yazma kartı açıldı/kapandı: editör kendi alt çubuğunu gizler
  /// (bölme de alttaki notu gizleyip medyayı klavyeye kadar uzatır — bkz.
  /// [_PinnedMediaPaneState._writing]).
  final ValueChanged<bool>? onImmersiveChanged;

  /// Sabit PDF'te SEÇİLEN YAZIDAN NOT (kullanıcı isteği 2026-11-03): basılı
  /// tutup seçilen yazı "Not al" ile sayfa + satır + alıntı olarak nota
  /// girer (bkz. [PdfPageBox.onNoteFromSelection]). null ise seçim kapalı.
  final void Function(int page, int? line, String quote)? onPdfNote;

  /// Eki panoya kopyalar: yüzen ve şeritle aynı liste (cihaz turu 2026-11-05).
  final VoidCallback? onCopy;

  /// Görseldeki yazıyı çıkarır (OCR).
  final VoidCallback? onExtractText;

  /// Akıllı işlemler: alan seçimi / yapay zekâ sonucunu nota ekler.
  final ValueChanged<String>? onInsertToNote;

  /// Sabit görsel/PDF akıllı özet çıkarımı.
  final VoidCallback? onSmartSummarize;

  /// Sabit görsel/PDF içeriğinden yapılacak madde çıkarımı.
  final VoidCallback? onSmartTasks;

  /// Sabit görsel/PDF alan seçip yapay zekâya sorma; null ise PDF'te
  /// etkin sayfa yakalama yolu kullanılır.
  final VoidCallback? onSmartAreaAsk;

  /// Sabit görselin/videonun TRANSKRİPTİ (metne dök / kayıtlıysa aç).
  final VoidCallback? onTranscribe;

  /// Eki nottan kaldırır (geri al ile döner) — çubuğun ⋮ menüsünde.
  ///
  /// Kullanıcı bulgusu 2026-10-16: "video sabitken kaldırmak ayarı yok,
  /// gömülü hale getirmek gerekiyor" — sabit bölmede yalnız simgeli görünüm
  /// anahtarı vardı; silmek için önce sayfaya almak, sonra seçip panelden
  /// silmek gerekiyordu. Menü YAZILI: Sayfaya göm · Alta ek olarak · Kaldır.
  final VoidCallback? onRemove;

  /// EKİ FARKLI KAYDET (2026-10-17). null ise menüde yok.
  final VoidCallback? onSaveAs;

  /// Eki sistem paylaşımıyla gönderir (TUTARLILIK F36.4 — kullanıcı
  /// listesi: "ekleri paylaş seçeneği ek menüsünde ve gömülmüş ek menüsünde
  /// olsun"; şerit ve yüzen görselde vardı, sabit bölmede yoktu).
  final VoidCallback? onShare;

  /// GÖRSELDEN TÜRETİLMİŞ balonlu belge (bkz. `Attachment.sourceId`).
  /// Kullanıcı isteği 2026-10-16: "balonludan üste sabitlemeye alınca da
  /// balonlar görülsün ama göster/gizlesi olsun". Görsel balonluya alınınca
  /// balonlar A4 sayfadaki belgede yaşar; sabitlenen ise görselin kendisi.
  /// Balonlar görselin uzayına geri taşınıp ([unplaceBubbles]) üstünde salt
  /// okunur çizilir; çubukta göster/gizle (gizlilik belgede saklanır,
  /// [onChanged] ile yazılır). PDF'in kendi kutusu balonları zaten çizer.
  final Attachment? bubbleDoc;

  final Attachment media;
  final ValueChanged<double> onHeightChanged;
  final VoidCallback onUnpin;

  /// Tam ekran (görsel görüntüleyici / video oynatıcı).
  final VoidCallback onOpen;

  final Widget child;

  /// YouTube ekinin bağlantısını panoya yazar — ayraç çubuğunda düğme.
  final VoidCallback? onCopyLink;

  /// Sabitli PDF'in sayfa/yer imi/döndürme değişiklikleri (bkz.
  /// [PdfPageBox.onChanged]).
  final ValueChanged<Attachment>? onChanged;

  /// Tablo içeriği (hücreler): kök kurulmadan kaydedilir; null = tablo salt
  /// okunur (salt okunur not).
  final ValueChanged<Attachment>? onTableChanged;

  /// Belgenin üstüne çizilen çizgi (yalnız `ink` değişir). Ayrı: editör bunu
  /// kök kurmadan, gecikmeli kaydeder. null ise [onChanged]'e düşer.
  final ValueChanged<Attachment>? onInkChanged;

  /// Görünüm anahtarı (Sabit / Yüzen / Ek — bkz. `AttachmentViewSwitch`):
  /// GENİŞ çubukta çubuğun sağında, dar çubukta ⋮ levhasında (bkz.
  /// [sheetViewSwitch]). null ise eski "sayfaya geri koy" düğmesi.
  final Widget? viewSwitch;

  /// DAR çubukta anahtar ⋮ levhasının başında durur (K-O6): levhanın
  /// bağlamıyla kurulur ki seçim levhayı da kapatsın. null ise [viewSwitch].
  final Widget? Function(BuildContext sheet)? sheetViewSwitch;

  /// Bölmenin kalem düğmesi kalemi KAPATTI ve editörün kalem kipi açıktı
  /// ([penActive]): editör kendi kipini de kapatır (tam senkron, P49).
  final VoidCallback? onPenOff;

  /// Görsel açıklamasını yazar (⋮, bant).
  final VoidCallback? onCaption;

  /// "Bu ana not al" (yalnız video): ayraç çubuğunda yazılı düğme.
  final VoidCallback? onNoteAt;

  @override
  State<PinnedMediaPane> createState() => _PinnedMediaPaneState();
}

class _PinnedMediaPaneState extends State<PinnedMediaPane>
    with TickerProviderStateMixin {
  /// Sabit görselin üstündeki balonların denetleyicisi (bkz.
  /// [PinnedMediaPane.bubbleDoc]); aç/kapa durumu yazılmaz — görselin
  /// uzayındaki kopya belgeye geri yazılamaz, okuma için yeter.
  BubbleController? _imageBubbles;

  List<PageBubble> _mappedBubbles(Attachment doc) => unplaceBubbles(
    doc.bubbles,
    ScanPdf.imageFrameOnPage(widget.media.width ?? 0, widget.media.height ?? 0),
  );

  BubbleController? _bubblesFor(Attachment? doc) {
    if (doc == null || doc.bubbles.isEmpty) return null;
    return _imageBubbles ??= BubbleController(
      initial: _mappedBubbles(doc),
      hidden: doc.bubblesHidden,
      onChanged: (_) {},
    );
  }

  /// SABİT GÖRSELE BALON (kullanıcı isteği 2026-11-05: "sabitleme ile
  /// balonlu modu birleştir, tek mod sabitleme olsun, orada balon ekleme
  /// olabilir"). Balonlu görünüm kalktı; görselin balonları görselin KENDİ
  /// ekinde (`page: 1`, görüntüleyicideki "görsel üstüne metin"le aynı veri)
  /// yaşar. İlk düzenlemede görselden türetilmiş eski belgenin balonları
  /// görselin uzayına taşınıp ([_mappedBubbles]) görsele yazılır.
  ///
  /// SABİT KİPİN TEK DAVRANIŞI (kullanıcı bulgusu 2026-11-05: "balonlar
  /// taşınamıyor, düzenlenemiyor; uzun basış metin tanıma yapıyor"):
  /// yazılabilir notta balonlar HEP düzenlenebilir — tutamaç basılı tutulup
  /// taşınır, okuma kartında Düzenle çıkar; iki parmak ya da çift dokunuş
  /// yakınlaştırır. Yeni balon YALNIZ çubuktaki "Balon ekle" menüsünden
  /// (Balon / Açık metin) açılan bırakma kipinde dokunarak eklenir;
  /// basılı tutmak görseldeki yazıyı seçmeye açar (kullanıcı kararı
  /// 2026-11-05).
  BubbleController? _ownBubbles;

  /// Dokunarak bırakma kipi (denetleyicinin `adding` değeri — araç
  /// kartındaki "Bitti" de kapatır).
  bool get _bubbleEdit => _ownBubbles?.adding ?? false;

  bool get _canEditBubbles =>
      widget.media.kind == AttachmentKind.image && widget.onChanged != null;

  /// Sabit PDF'in "Balon ekle" kipi: düğme bu çubukta, kip belge kutusunda
  /// (bkz. [PdfPageBox.addingBubbles]).
  final _pdfAdding = ValueNotifier<bool>(false);

  /// Belge kutusunun denetimleri bu çubukta (2026-11-07: kutunun üstündeki
  /// gri sayfa şeridi kaldırıldı — bkz. [PdfBoxBar]).
  final _pdfBar = PdfBoxBar();

  /// Bölmenin kendi kalem düğmesi (editörün kalem kipi kapalıyken).
  bool _ownPen = false;
  InkController? _ink;

  /// Kalem katmanı PDF'in üstünde mi. Kalemsiz cihazda (hiç kalem
  /// görülmedi) otomatik algı katmanı kurulmaz: basılı tutup metin seçme
  /// ("Not al") parmakta çalışmaya devam eder; kalem düğmesiyle açılır.
  ///
  /// BALON BIRAKMA KİPİNDE KALEM KAPALI (kullanıcı bulgusu 2026-11-22: "kalem
  /// açıkken balon eklenemiyor, kalem yazıyor"): sabit PDF'te "Balon ekle"
  /// açılınca kalem katmanı kalkar, dokunuş balonu/metni bırakır; "Bitti"
  /// ile kalem kaldığı yerden döner.
  bool get _penOn =>
      widget.onChanged != null &&
      ((widget.media.kind == AttachmentKind.pdf && !_pdfAdding.value) ||
          _inkableImage) &&
      _policy.layerActive;

  /// Ekte kayıtlı piksel ölçüsü ya da yoklanan oran varsa görsel dikdörtgeni
  /// hesaplanabilir (kalem/balon ölçüsüz görsellerde de çalışır).
  bool get _hasImageBounds =>
      ((widget.media.width ?? 0) > 0 && (widget.media.height ?? 0) > 0) ||
      _mediaRatio != null;

  /// SABİT GÖRSELE KALEM (F63.3): ölçüsü ya da yoklanan oranı bilinen görsel.
  /// Balon bırakma kipinde kalem kapalı — dokunuş balon bırakır.
  bool get _inkableImage =>
      widget.media.kind == AttachmentKind.image &&
      _hasImageBounds &&
      !_bubbleEdit;

  /// Görselin çizim katmanı (görselin dikdörtgeninde, yakınlaştırma
  /// dönüşümünün içinde).
  Widget _imageInkLayer() => PinnedImageInkSurface(
    strokes: _shownInk,
    revision: _ink?.revision ?? 0,
    width: widget.media.width,
    height: widget.media.height,
    probedRatio: _mediaRatio,
    activeController: _penOn ? _inkFor(widget.media) : null,
  );

  /// **YAZILAR KAYBOLUP GERİ GELİYORDU** (kullanıcı bulgusu 2026-11-21):
  /// kalem kapalıyken katman [widget.media]'nın çizgilerini boyuyordu; editör
  /// eke yazılan çizgide kökü kurmadığı (F60.1) için o liste BAYAT — son
  /// çizilenler kök yeniden kurulana dek görünmüyordu. Denetleyici varsa ve
  /// ekin listesi dışarıdan değişmediyse (tam ekran, geri al, başka cihaz)
  /// denetleyicinin güncel çizgileri boyanır.
  List<InkStroke> get _shownInk {
    final c = _ink;
    if (c == null || !identical(widget.media.ink, _inkSeen)) {
      return widget.media.ink;
    }
    return c.ink;
  }

  /// Kalem kuralı tek yerde ([PenPolicy], F63.1).
  PenPolicy get _policy => PenPolicy.resolve(
    surface: PenSurface.pinnedDoc,
    penMode: _explicitPen,
    autoStylus: InkToolMemory.autoStylus,
    stylusEver: InkToolMemory.stylusEver,
    penOnly: InkToolMemory.penOnly,
  );

  /// Kalem kipi (editörün ya da bölmenin): parmak da çizer. Değilse ve
  /// yüzen düğme "kalem yazar" diyorsa YALNIZ kalem çizer, parmak kaydırır
  /// (kullanıcı bulgusu 2026-11-09: "sabitken yazı yazamıyorum").
  bool get _explicitPen => widget.penActive || _ownPen;

  void _onStylusToggle() {
    // Yüzen düğme "kalem dokunur"a geçti: bölmenin kendi kalemi de kapanır
    // (eskiden açık kalıyor, kalem yine yazıyordu).
    if (!InkToolMemory.autoStylus) _ownPen = false;
    if (mounted) setState(() {});
  }

  /// Denetleyiciye en son verilen/denetleyiciden en son gelen çizgi listesi
  /// (kimlik): yalnız DIŞARIDAN gelen değişiklik işlenir.
  List<InkStroke>? _inkSeen;
  bool _inkPenOnly = false;

  /// Çizim denetleyicisi ekle bağlı; ek değişince yenilenir.
  ///
  /// **SABİT PDF'E YAZILMIYORDU** (cihazda doğrulandı 2026-11-10: kalem kipi
  /// açılıyor ama ne kalem ne parmak iz bırakıyordu). KÖK: denetleyici hiç
  /// düzenleme kipine alınmıyordu — `InkPageLayer` `IgnorePointer(ignoring:
  /// !editing)` ile bütün dokunuşları yok sayıyordu. Ayrıca "yalnız kalem"
  /// kurulumdaki kopyadan okunuyordu (kalem gövdede görülünce bölme habersiz:
  /// parmak yazabiliyordu) ve tam ekranda/geri alda değişen çizgiler
  /// alınmıyordu (bir sonraki çizgi eski listeyi kaydedip onları siliyordu).
  InkController _inkFor(Attachment a) {
    var c = _ink;
    if (c == null) {
      c = _ink = InkController(
        initial: a.ink,
        // [_inkSeen] burada GÜNCELLENMEZ — bkz. aşağıdaki "SİLGİYE BASINCA
        // YAZILAR KAYBOLUYORDU".
        onChanged: (strokes) {
          (widget.onInkChanged ?? widget.onChanged)?.call(
            widget.media.copyWith(ink: strokes),
          );
        },
      )..setEditing(true);
      _inkSeen = a.ink;
      _inkPenOnly = c.penOnly;
      // İlk kalem dokunuşu "yalnız kalem"i açınca kaydırma kuralı da
      // hemen değişsin (dragDevices bu bölmenin build'inde).
      c.addListener(() {
        if (c!.penOnly != _inkPenOnly && mounted) {
          _inkPenOnly = c.penOnly;
          setState(() {});
        }
      });
    }
    // **SİLGİYE BASINCA YAZILAR KAYBOLUYORDU** (kullanıcı bulgusu
    // 2026-11-13: "kalemle yazdım, silgiye basınca yazılar kayboluyor,
    // tekrar basınca geri geliyor"). KÖK: editör eke yazılan çizgide kökü
    // kurmaz (F60.1, `_updateAttachmentInk`) — bu bölmenin [widget.media]'sı
    // ESKİ çizgi listesini tutar. [_inkSeen] çizimde denetleyicinin listesine
    // çekiliyordu; sonraki herhangi bir yeniden çizimde (silgi, kalem
    // düğmesi) eski liste "dışarıdan gelen değişiklik" sanılıp denetleyiciye
    // geri yazılıyor, çizgiler siliniyordu; kök kurulunca geri geliyordu.
    // Artık yalnız EKİN KENDİ listesi kimlik değiştirince (tam ekran, geri
    // al, başka cihaz) işlenir; içerik aynıysa `replace` zaten bir şey yapmaz.
    if (!identical(a.ink, _inkSeen)) {
      _inkSeen = a.ink;
      if (!c.drawing) c.replace(a.ink);
    }
    c.allowedKinds = _policy.allowedKinds;
    return c;
  }

  /// Sabit PDF'in bırakma kipinde açık metin mi (bkz. [PdfPageBox.addingPlain]).
  final _pdfPlain = ValueNotifier<bool>(false);

  /// **BALON YAZILIYOR** (kullanıcı bulgusu 2026-11-05: "balon yazarken
  /// sayfa aşırı daralıyor; alttaki not alanı gizlensin, balon yazı alanı
  /// klavyenin üzerine yerleşsin"): yazma kartı açıkken ayraç çubuğu ve
  /// alttaki not ağaçta kalır ama GÖRÜNMEZ ve yer kaplamaz; medya bölmenin
  /// tamamını alır, kart onun dibinde — klavyenin hemen üstünde.
  bool _writing = false;

  /// Bir kare canlandırmasız (bkz. [_setWriting]).
  bool _snapWindow = false;

  bool _takeSnap() {
    if (!_snapWindow) return false;
    _snapWindow = false;
    return true;
  }

  void _setWriting(bool value) {
    if (_writing == value) return;
    void apply() {
      if (!mounted || _writing == value) return;
      // Yazma bitince pencere yerine ATLAR: tam boydan canlandırılırsa
      // geri gelen çubuk + not bir an taşardı.
      _snapWindow = !value;
      setState(() => _writing = value);
      widget.onImmersiveChanged?.call(value);
    }

    // Yazma kartı bunu kare SONUNDA bildirir (bkz. BubbleDock._setDockOpen):
    // o an doğrudan uygulanır. Kurulum sırasında gelirse kare sonuna.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) => apply());
      WidgetsBinding.instance.ensureVisualUpdate();
    } else {
      apply();
    }
  }

  bool get _canEditPdfBubbles =>
      widget.media.kind == AttachmentKind.pdf && widget.onChanged != null;

  BubbleController _ownController() => _ownBubbles ??= _withLuma(BubbleController(
    initial: widget.media.bubbles.isNotEmpty
        ? widget.media.bubbles
        : (widget.bubbleDoc == null
              ? const []
              : _mappedBubbles(widget.bubbleDoc!)),
    hidden: widget.media.bubbles.isNotEmpty
        ? widget.media.bubblesHidden
        : (widget.bubbleDoc?.bubblesHidden ?? widget.media.bubblesHidden),
    onChanged: (list) => widget.onChanged?.call(
      widget.media.copyWith(
        bubbles: list,
        bubblesHidden: _ownBubbles?.hidden ?? widget.media.bubblesHidden,
      ),
    ),
    onHiddenChanged: (hidden) => widget.onChanged?.call(
      widget.media.copyWith(
        bubblesHidden: hidden,
        bubbles: _ownBubbles?.bubbles ?? widget.media.bubbles,
      ),
    ),
  )
    ..addListener(_onOwnBubbles)
    ..onEditingChanged = _setWriting);

  /// Koyu görselde yeni metin/balon açık renkle doğsun (bkz. [ImageLuma]).
  BubbleController _withLuma(BubbleController c) {
    final provider = widget.media.kind == AttachmentKind.image
        ? attachmentImageProvider(widget.media)
        : null;
    if (provider == null) return c;
    final id = widget.media.id;
    unawaited(
      ImageLuma.load(provider).then((l) {
        if (l != null && identical(_ownBubbles, c) && widget.media.id == id) {
          c.lumaAt = l.at;
        }
      }),
    );
    return c;
  }

  /// Kip/gizlilik/balon sayısı çubuktaki düğmeleri değiştirir.
  bool? _lastAdding;
  (bool, bool)? _lastBar;
  void _onOwnBubbles() {
    final own = _ownBubbles;
    if (own == null || !mounted) return;
    final adding = own.adding;
    final bar = (own.hidden, own.bubbles.isEmpty);
    if (adding == _lastAdding && bar == _lastBar) return;
    final closed = _lastAdding == true && !adding;
    _lastAdding = adding;
    _lastBar = bar;
    if (closed) own.save();
    setState(() {});
  }

  /// "Balon ekle" menüsünden seçilen tür ([plain]: açık metin) ile bırakma
  /// kipini açar; kip açıkken düğme kipi kapatır.
  void _startAdding({required bool plain}) {
    if (_canEditBubbles) {
      _ownController()
        ..setPlainMode(plain)
        ..setAdding(true);
    } else if (_canEditPdfBubbles) {
      _pdfPlain.value = plain;
      _pdfAdding.value = true;
    }
  }

  void _stopAdding() {
    if (_canEditBubbles) {
      _ownBubbles?.setAdding(false);
    } else {
      _pdfAdding.value = false;
    }
  }

  /// Sabit görselde çift dokunuş: sığdırılmışken dokunulan yer 2,5 kat
  /// büyür, yakınken geri sığar (PDF kutusuyla aynı).
  Offset? _doubleTapAt;
  void _toggleImageZoom() {
    // Bütün görsel kipindeyken çift dokunuş genişliğe oturmaya döner.
    if (_wholeImage) {
      setState(() => _wholeImage = false);
      _imageZoom.value = Matrix4.identity();
      return;
    }
    if (_imageZoomed) {
      _imageZoom.value = Matrix4.identity();
      return;
    }
    final at = _doubleTapAt;
    if (at == null) return;
    const scale = 2.5;
    _imageZoom.value = Matrix4.identity()
      ..translateByDouble(-at.dx * (scale - 1), -at.dy * (scale - 1), 0, 1)
      ..scaleByDouble(scale, scale, 1, 1);
  }

  /// Görselin üstündeki katman: yazılabilir notta görselin KENDİ
  /// (düzenlenebilir) denetleyicisi, salt okunurda eski türetilmiş belgenin
  /// balonları.
  BubbleController? _layerBubbles() {
    if (_canEditBubbles) return _ownController();
    return _bubblesFor(widget.bubbleDoc);
  }

  /// Sabit görselde iki parmakla yakınlaştırma; balonlar görselle birlikte
  /// büyür (katman dönüşümün içinde).
  final _imageZoom = TransformationController();
  bool _imageZoomed = false;

  /// **UZAKLAŞTIRMA** (kullanıcı isteği 2026-11-21: "görselde zoom out da
  /// yapılabilmeli, şu an yalnız yakınlaşıyor"): genişliğe oturan uzun
  /// görselde iki parmakla uzaklaşınca BÜTÜN görsel bölmeye sığar (kaydırma
  /// yok); orada yakınlaşınca ya da çift dokununca genişliğe oturmaya döner.
  /// Basamaklar: bütün görsel ↔ genişliğe otur ↔ yakın.
  bool _wholeImage = false;

  /// Kıstırmanın parmak oranı (InteractiveViewer, sınır payı sıfırken
  /// ölçeği 1'in altına indirmez; uzaklaşma isteği buradan okunur) ve
  /// başladığı andaki ölçek.
  double _pinch = 1;
  double _pinchFrom = 1;

  void _onImageZoomStart(ScaleStartDetails _) {
    _pinch = 1;
    _pinchFrom = _imageZoom.value.getMaxScaleOnAxis();
    _pinchStartH = _dragHeight;
    _resizing = false;
    _fling.stop();
  }

  /// Kıstırma başındaki bölme boyu ve bölme boyunun canlı değişip
  /// değişmediği (bkz. [_onImageZoomEnd]).
  double _pinchStartH = 0;
  bool _resizing = false;

  /// **TEK TANIYICI** (kullanıcı bulgusu 2026-11-22, v1.2.115: "iki parmak
  /// zoom yapamıyorum, sabit görselde zoom in/out olmuyor"): genişliğe oturan
  /// görselde dikey kaydırma ayrı bir `onVerticalDrag` tanıyıcısıydı; İLK
  /// parmak kaydırma eşiğini geçince arenayı o kazanıyor, ikinci parmak
  /// gelince ölçek tanıyıcısı çoktan kaybetmiş oluyordu → kıstırma hiç
  /// çalışmıyordu. Artık tek parmak kaydırma da `InteractiveViewer`ın ölçek
  /// tanıyıcısından gelir (pan kapalıyken de güncelleme bildiriyor).
  void _onImageZoomUpdate(ScaleUpdateDetails d) {
    if (d.pointerCount >= 2) {
      _pinch = d.scale;
      final atFit = _pinchFrom <= 1.01;
      // UZAKLAŞ = BÖLME CANLI KÜÇÜLÜR (görsel bütün hâliyle sığar);
      // bütün kipte yakınlaşma bölmeyi büyütür.
      if (_fitsWidth && (_wholeImage || (atFit && d.scale < 0.97))) {
        final h = (_pinchStartH * d.scale).clamp(
          kPinnedMinHeight,
          math.max(kPinnedMinHeight, math.min(_dragMax, _dragNatural)),
        ).toDouble();
        setState(() {
          if (!_wholeImage) {
            _wholeImage = true;
            _imageScroll.offset = 0;
            _imageZoom.value = Matrix4.identity();
          }
          _resizing = true;
          _live = h;
        });
      }
      return;
    }
    if (_imageScrolls) _imageScroll.by(-d.focalPointDelta.dy);
  }

  /// Kıstırma bitince: canlı boy kaydedilir (ayraç sürüklemeyle aynı yol);
  /// tavana varan bütün görsel genişliğe oturmaya döner. Tek parmak
  /// kaydırmada ivme.
  void _onImageZoomEnd(ScaleEndDetails d) {
    final pinch = _pinch;
    _pinch = 1;
    if (_resizing) {
      _resizing = false;
      final h = _live ?? _dragHeight;
      final cap = math.min(_dragMax, _dragNatural);
      final widen = pinch > 1 && h >= cap * 0.98;
      setState(() {
        _live = null;
        if (widen) _wholeImage = false;
      });
      widget.onHeightChanged(_clamp(widen ? cap : h, _dragMax));
      return;
    }
    final v = -d.velocity.pixelsPerSecond.dy;
    if (_imageScrolls && d.pointerCount <= 1 && v.abs() >= 60) {
      unawaited(
        _fling.animateWith(
          ClampingScrollSimulation(position: _imageScroll.offset, velocity: v),
        ),
      );
    }
  }

  /// Genişliğe oturan görselin kaydırma İVMESİ (kullanıcı bulgusu
  /// 2026-11-22: "görsel kaydırılırken takılıyor, akıcı kaymıyor"): parmak
  /// kalkınca konum sürtünmeli benzetimle süzülür (liste kaydırması gibi).
  late final AnimationController _fling = AnimationController.unbounded(
    vsync: this,
  )..addListener(() => _imageScroll.to(_fling.value));


  void _onImageZoom() {
    final zoomed = _imageZoom.value.getMaxScaleOnAxis() > 1.01;
    if (zoomed != _imageZoomed && mounted) {
      setState(() => _imageZoomed = zoomed);
    }
  }

  /// Dokunuş başladığında açık balon / bırakma kipi var mıydı? Varsa
  /// dokunuş onu kapatır, tam ekran görüntüleyiciyi AÇMAZ.
  bool _tapBusy = false;

  @override
  void initState() {
    super.initState();
    Personalize.listenable.addListener(_onPersonalize);
    _imageZoom.addListener(_onImageZoom);
    _watcher.stage.addListener(_onStage);
    _onStage();
    InkToolMemory.autoStylusListenable.addListener(_onStylusToggle);
    _pdfAdding.addListener(_onPdfAdding);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      TipOnce.showDeferred(
        context,
        TipOnce.pinnedSplitResize,
        () => context.l10n.tipPinnedSplitResize,
        icon: Icons.drag_indicator_rounded,
      );
      if (widget.media.kind == AttachmentKind.pdf ||
          widget.media.kind == AttachmentKind.image) {
        TipOnce.showDeferred(
          context,
          TipOnce.pinnedSmartActions,
          () => context.l10n.tipPinnedSmartActions,
          icon: Icons.auto_awesome_outlined,
        );
      }
    });
  }

  /// Balon bırakma kipi değişince kalem katmanı kurulur/kalkar ([_penOn]).
  /// Belge kutusu değeri kendi kurulumu sırasında da yazabilir: o an
  /// setState kare sonuna ertelenir.
  void _onPdfAdding() {
    if (!mounted) return;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    } else {
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(PinnedMediaPane old) {
    super.didUpdateWidget(old);
    if (old.media.id != widget.media.id) {
      _ink?.dispose();
      _ink = null;
      _inkSeen = null;
      _ownPen = false;
      _imageScroll.offset = 0;
      _wholeImage = false;
    }
    final doc = widget.bubbleDoc;
    if (doc != null) {
      _imageBubbles
        ?..replace(_mappedBubbles(doc))
        ..syncHidden(doc.bubblesHidden);
    }
    if (old.media.id != widget.media.id) {
      _ownBubbles?.save();
      _ownBubbles?.dispose();
      _ownBubbles = null;
      _lastAdding = null;
      _lastBar = null;
      _pdfAdding.value = false;
      _imageZoom.value = Matrix4.identity();
      _setWriting(false);
    } else if (!_bubbleEdit && widget.media.bubbles.isNotEmpty) {
      _ownBubbles
        ?..replace(widget.media.bubbles)
        ..syncHidden(widget.media.bubblesHidden);
    }
  }

  @override
  void dispose() {
    Personalize.listenable.removeListener(_onPersonalize);
    InkToolMemory.autoStylusListenable.removeListener(_onStylusToggle);
    _ink?.dispose();
    _ownBubbles?.save();
    _ownBubbles?.dispose();
    _imageBubbles?.dispose();
    _pdfAdding.dispose();
    _keyboardN.dispose();
    _watcher.dispose();
    _slide.dispose();
    _dy.dispose();
    _pdfBar.dispose();
    _pdfPlain.dispose();
    // Ağaç kilitliyken üst ekranın setState'i çağrılmaz: kare sonuna.
    final immersive = widget.onImmersiveChanged;
    if (_writing && immersive != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => immersive(false));
    }
    _fling.dispose();
    _imageZoom.dispose();
    _imageScroll.dispose();
    super.dispose();
  }

  /// Görselin bölmede `contain` ile çizildiği dikdörtgen (balonlar ve mürekkep
  /// onun oranlı uzayında). Ekte piksel ölçüsü yoksa yoklanan oran kullanılır.
  Rect? _imageRect(Size box) => computePinnedImageRect(
    box,
    width: widget.media.width,
    height: widget.media.height,
    probedRatio: _mediaRatio,
  );

  /// Görselin üstündeki balon katmanı (görselin `contain` dikdörtgeninde).
  Widget _imageBubbleLayer(BubbleController bubbles) => LayoutBuilder(
    builder: (context, box) {
      final rect = _imageRect(box.biggest);
      if (rect == null) return const SizedBox.shrink();
      final own = identical(bubbles, _ownBubbles);
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fromRect(
            rect: rect,
            child: BubblePageLayer(
              controller: bubbles,
              page: 1,
              readOnly: !own,
            ),
          ),
        ],
      );
    },
  );

  /// Görsel genişliğe oturma kipinde dikey kaydırma (bkz. [_fitWidthImage]).
  final _imageScroll = FitScroll();

  /// Genişliğe oturan görsel parmakla/fareyle kayar mı: yakınken pan,
  /// kalem parmakla çizerken çizim kazanır.
  bool get _imageScrolls =>
      _fitsWidth &&
      !_wholeImage &&
      !_imageZoomed &&
      (!_penOn || _policy.fingerScrolls);

  bool get _fitsWidth =>
      widget.media.kind == AttachmentKind.image &&
      !widget.shrinkToFit &&
      !widget.fill &&
      _mediaRatio != null;

  /// **GÖRSEL GENİŞLİĞE OTURUR** ([PinnedMediaPane.shrinkToFit] kapalı):
  /// görsel bölmenin genişliğinde doğal boyuyla dizilir, bölme daha kısaysa
  /// dikeyde kayar (PDF'teki gibi). Balon/çizim katmanları aynı kutuda —
  /// `contain` dikdörtgeni kutunun kendisi olur, koordinatlar bozulmaz.
  ///
  /// TEK widget (keyboard_jank_guard S17: klavye geçiş karesinde medya
  /// alt ağacı yeniden kuruluyor, bütçede pay yok): kaydırıcı widget yerine
  /// kaydırmayı boyamada uygulayan bir kutu ([FitWidthBox]); sürükleme
  /// medyanın VAR OLAN jest algılayıcısında.
  Widget _fitWidthImage(bool isImage, Widget child) {
    if (!_fitsWidth) return child;
    return FitWidthBox(
      key: ValueKey('pinned-image-scroll-${widget.media.id}'),
      ratio: _mediaRatio!,
      whole: _wholeImage,
      scroll: _imageScroll,
      // Kaydırma yalnız ötelemeyi değiştirir: görsel + çizim + balon
      // katmanı kendi katmanında kalır, her karede yeniden boyanmaz.
      child: RepaintBoundary(child: child),
    );
  }

  /// **PDF KÜÇÜLEREK SIĞAR** ([PinnedMediaPane.shrinkToFit] açık): sayfa bir
  /// sayfa boyunda dizilir, bölme kısaysa bütün sayfa görünecek kadar
  /// küçültülerek boyanır (isabet testi dönüşümden geçer: kalem ve balon
  /// doğru yere düşer). Kapalıyken (varsayılan) dokunulmaz.
  Widget _shrinkPdf(Widget child) {
    final ratio = _mediaRatio;
    if (!widget.shrinkToFit || ratio == null) return child;
    return LayoutBuilder(
      builder: (context, box) {
        if (!box.maxHeight.isFinite || box.maxWidth <= 0) return child;
        final natural = box.maxWidth * ratio;
        return FittedBox(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: box.maxWidth,
            height: math.max(natural, box.maxHeight),
            child: child,
          ),
        );
      },
    );
  }

  /// Görsel + balonlar iki parmakla yakınlaşır; yakınken tek parmak gezdirir.
  Widget _zoomable({required bool enabled, required Widget child}) {
    if (!enabled) return child;
    return WheelScrollViewer(
      controller: _imageZoom,
      panEnabled: _imageZoomed,
      // Bütün görsel kipinde iki parmak içeriği değil BÖLMEYİ büyütür.
      scaleEnabled: !_wholeImage,
      onInteractionStart: _onImageZoomStart,
      onInteractionUpdate: _onImageZoomUpdate,
      onInteractionEnd: _onImageZoomEnd,
      child: child,
    );
  }

  /// Ayraç sürüklenirken canlı yükseklik (ham — sınırlanmamış).
  double? _live;

  /// Medya basılı tutulup aşağı sürüklenirken parmağın yer değiştirmesi.
  double _pullDown = 0;
  bool _pulling = false;

  double _clamp(double h, double max) => h.clamp(
    kPinnedMinHeight,
    max < kPinnedMinHeight ? kPinnedMinHeight : max,
  );

  /// Klavyesiz yükseklik — klavye kapalıyken ölçülen yükseklik; genişlik
  /// değişince sıfırlanır (yönelim, pencere). Bkz. [pinnedMaxHeight].
  double _stableWidth = -1;
  double _stableHeight = 0;

  double _stable(BoxConstraints c) {
    if (c.maxWidth != _stableWidth) {
      _stableWidth = c.maxWidth;
      _stableHeight = 0;
    }
    if (!c.maxHeight.isFinite) return _stableHeight;
    // Klavye yokken gerçek değişimleri (ek şeridi açıldı, pencere) izler;
    // klavye açıkken en büyük görülen kalır.
    if (!_keyboard.open || c.maxHeight > _stableHeight) {
      _stableHeight = c.maxHeight;
    }
    return _stableHeight;
  }

  /// Klavye ekranda mı ve tam boy tahmini (bkz. [_watcher]; `open`
  /// kapanırken de true — boy klavye BİTİNCE geri döner).
  ///
  /// BİLDİRİCİ, `setState` değil (F60.S5): eskiden her değişimde BÜTÜN bölme
  /// (medya, çubuk düğmeleri, ipuçları ≈ 230 widget) klavye animasyonunun
  /// ortasında yeniden kuruluyordu — çevrim başına 4 kez. Yalnız medyanın
  /// görünür penceresi dinler (bkz. [build] içindeki dinleyici).
  final _keyboardN = ValueNotifier<KeyboardPhase>((open: false, estimate: 0));
  KeyboardPhase get _keyboard => _keyboardN.value;

  /// **BOY TEK ADIMDA, HAREKET BOYAMADA** (P49; kullanıcı 2026-11-12: "sabit
  /// ek varken klavye açılırken hem sabit ek paneli hem klavye kasıyor").
  ///
  /// KÖK NEDEN: pencerenin BOYU 260 ms boyunca kare kare değişiyordu
  /// (`KeyboardClipWindow`): bölmenin sütunu ve altındaki editör gövdesi her
  /// karede yeniden diziliyordu (kasma listesi §6). Artık pencerenin
  /// yerleşim boyu ([_laid]) yalnız klavye GÖRÜNDÜĞÜ ve BİTTİĞİ karede
  /// değişir; aradaki yumuşak geçiş [_dy] kadar boyamada: pencere kırpması,
  /// küçülme ölçeği ve alttaki çubuk + notun kayması (`Flow`, yerleşim yok).
  /// Kapanırken (klavye inerken) boy hiç değişmez, yalnız [_dy] büyür.
  /// Aşama kurulumsuz izlenir ([KeyboardStageWatcher]): klavye karelerinde
  /// bölmede HİÇBİR widget kurulmaz.
  final _watcher = KeyboardStageWatcher();
  bool _closing = false;

  /// Pencerenin yerleşim boyu (−1: henüz yerleşmedi) ve medyanın tam boyu.
  double _laid = -1;
  double _full = 0;

  /// Görünen boy − yerleşim boyu (dp); boyama katmanları bunu dinler.
  final _dy = ValueNotifier<double>(0);
  double _dyFrom = 0;
  double _dyTo = 0;
  late final AnimationController _slide = AnimationController(vsync: this)
    ..addListener(
      () => _dy.value =
          _dyFrom +
          (_dyTo - _dyFrom) * AppMotion.enter.transform(_slide.value),
    );
  late final _shift = _ShiftFlow(_dy);

  void _onStage() {
    final stage = _watcher.stage.value;
    _keyboardN.value = (open: stage.open, estimate: stage.estimate);
    if (stage.closing != _closing) {
      _closing = stage.closing;
      if (_laid >= 0) _retarget(_laid, animate: true);
    }
  }

  /// Yerleşim boyu [laid] oldu: görünen boy olduğu yerden hedefe kayar.
  void _retarget(double laid, {required bool animate}) {
    final first = _laid < 0;
    final from = first ? 0.0 : _laid + _dy.value - laid;
    _laid = laid;
    final to = _closing ? math.max(0.0, _full - laid) : 0.0;
    if (first || !animate || (from - to).abs() < 0.5) {
      _slide.stop();
      _dyFrom = _dyTo = to;
      _dy.value = to;
      return;
    }
    if (_slide.isAnimating && to == _dyTo) return;
    _dyFrom = from;
    _dyTo = to;
    _slide
      ..duration = AppMotion.of(context, AppMotion.short)
      ..forward(from: 0);
  }

  /// **KLAVYE AÇILINCA MEDYA KÜÇÜLMEZ** (kullanıcı bulgusu 2026-10-20:
  /// "görsel/video/PDF sabitken klavye açılınca odak kayması, görselin boyut
  /// değiştirmesi; zıplatmadan düzgün akış").
  ///
  /// KÖK NEDEN: gövde klavye OTURDUKTAN sonra tek seferde kısalıyor (bkz.
  /// KeyboardSnap), bölmenin sınırı da onunla birlikte düşüyordu: görsel
  /// bir karede küçülüp yukarı zıplıyor, not alanı sıçrıyor, imleç yeniden
  /// kaydırılıyordu. Artık medya klavyesiz boyunda yerleşir ve hiç yeniden
  /// ölçülmez; yer gerekiyorsa yalnız GÖRÜNÜR PENCERESİ, klavyeyle aynı anda
  /// ve yumuşakça daralır — alttaki çubuk ve not üstüne kayar gibi örter.
  /// Klavye kapanırken pencere aynı yoldan geri açılır.
  double _visibleHeight(
    BuildContext context, {
    required double layout,
    required double available,
    required double stable,
  }) {
    if (!_keyboard.open) return layout;
    // KISA PENCERE + KLAVYE (F67.4: yatay tablet 640 − 300): medya en küçük
    // penceresinde, yazı alanı ≥ 200 dp kalsın.
    final window = MediaQuery.sizeOf(context);
    if (WindowClass.fromSize(
          Size(window.width, window.height - _keyboard.estimate),
          web: kIsWeb,
        ).height ==
        WindowHeight.short) {
      return math.min(layout, kPinnedVisibleFloor);
    }
    // Gövde henüz kısalmadıysa (klavye açılıyor) kalacak yer tahminle
    // hesaplanır; kısaldıysa gerçek ölçü zaten elde.
    //
    // ZIPLAMA (kullanıcı bulgusu 2026-10-20: "klavye açılınca çubuk önce
    // yukarı gidiyor, sonra hafif alta iniyor"): klavye kapalıyken alt
    // çubuğun altında gezinme çubuğu payı var, oturunca yok (bkz.
    // KeyboardSlide) — gövde klavyenin TAMAMI kadar değil, gezinme payı
    // EKSİK kısalıyor. Tahmin de o kadar eksik düşülmeli; yoksa pencere önce
    // pay kadar fazla daralıp oturunca geri açılıyordu.
    final settled = stable - available > 40;
    final nav = MediaQueryData.fromView(View.of(context)).viewPadding.bottom;
    final room = settled
        ? available
        : available - math.max(0.0, _keyboard.estimate - nav);
    final fit = room - kPinnedBarHeight - kPinnedNoteMinHeight;
    return math.min(layout, math.max(kPinnedVisibleFloor, fit));
  }

  /// Videonun yükseklik/genişlik oranı; bilinmiyorsa (YouTube, ölçüsü
  /// henüz gelmemiş dosya) 16:9.
  static double _videoRatio(Attachment media) {
    final w = (media.width ?? 0).toDouble();
    final h = (media.height ?? 0).toDouble();
    return w > 0 && h > 0 ? h / w : 9 / 16;
  }

  /// **HER EK VİDEO GİBİ OTURUR** (kullanıcı isteği 2026-11-05: "tüm
  /// eklerde YouTube videoları gibi kolay oto sığdırma, sabitlendiğinde"):
  /// medyanın bölme genişliğindeki doğal boyu için oran (yükseklik /
  /// genişlik). Video ve sunum ölçüsüz de 16:9; görsel ölçüsü biliniyorsa;
  /// PDF ilk sayfanın oranı (döndürme dahil). Metin ve seste null (doğal
  /// boy yok).
  /// Bölmenin oranı: ekte kayıtlıysa o, ölçüsüz görselde yoklanan oran
  /// ([probeImageRatio]; gelene dek null = sınırsız, eski davranış).
  double? get _mediaRatio {
    final known = _fitRatio(widget.media);
    if (known != null) return known;
    if (widget.media.kind != AttachmentKind.image) return null;
    if (_probedFor != widget.media.id) _probeRatio();
    return _probedFor == widget.media.id ? _probedRatio : null;
  }

  String? _probedFor;
  double? _probedRatio;

  void _probeRatio() {
    final media = widget.media;
    _probedFor = media.id;
    _probedRatio = null;
    unawaited(
      probeImageRatio(media).then((r) {
        if (!mounted || r == null || _probedFor != media.id) return;
        // Uç oranlar (şerit/panorama hatası) sınır koymasın.
        if (r < 0.05 || r > 20) return;
        setState(() => _probedRatio = r);
      }),
    );
  }

  static double? _fitRatio(Attachment media) {
    final w = (media.width ?? 0).toDouble();
    final h = (media.height ?? 0).toDouble();
    final known = w > 0 && h > 0;
    return switch (media.kind) {
      AttachmentKind.video => _videoRatio(media),
      AttachmentKind.slide => known ? h / w : 9 / 16,
      AttachmentKind.image => known ? h / w : null,
      AttachmentKind.pdf =>
        known ? 1 / pdfBoxAspect(w, h, media.pdfTurns) : null,
      _ => null,
    };
  }

  /// Ayraçtaki tutamağa dokunuş: bölme medyanın doğal boyuna oturur
  /// (sınırı aşarsa sınıra). Son çizimde [_fitTarget] hesaplanır.
  double? _fitTarget;

  void _fit() {
    final target = _fitTarget;
    if (target == null) return;
    widget.onHeightChanged(target);
  }

  bool get _unpinArmed =>
      (_live != null && _live! < kPinnedUnpinHeight) ||
      (_pulling && _pullDown > 96);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isVideo = widget.media.kind == AttachmentKind.video;
    final isPdf = widget.media.kind == AttachmentKind.pdf;
    final isText = widget.media.kind == AttachmentKind.text;
    final isAudio = widget.media.kind == AttachmentKind.audio;
    // Zamanlı medya: denetim çubuğu ve ilerleme çizgisi (video + ses).
    final timed = isVideo || isAudio;
    final background = isVideo ? Colors.black : scheme.surfaceContainerHigh;
    // BİR KEZ KURULUR (P49): medya, çubuk ve not `build`'de kurulur; klavye
    // gövdeyi kısaltıp `LayoutBuilder` yeniden koşunca AYNI örnekler döner,
    // alt ağaçlar yeniden kurulmaz (S17 geçiş karesi).
    //
    // NOT AÇILIŞI HAFİF (kullanıcı bulgusu 2026-10-20: "notu açarken ufak
    // donma"): oynatıcı/belge görüntüleyicisi rota geçişi bitince kurulur
    // (bkz. AfterRouteTransition).
    final media = RepaintBoundary(
      child: AfterRouteTransition(
        placeholder: ColoredBox(color: background),
        child: _media(context),
      ),
    );
    // Yazarken not AĞAÇTA kalır (durumu, imleci korunur) ama yer kaplamaz
    // ve çizilmez; çubuk kalkar.
    final lower = RepaintBoundary(
      child: Column(
        children: [
          if (!_writing) _bar(context, timed: timed),
          Expanded(child: Offstage(offstage: _writing, child: widget.child)),
        ],
      ),
    );
    final layout = LayoutBuilder(
      builder: (context, constraints) {
        final stable = _stable(constraints);
        // Sürükleme sınırı O ANKİ yerden (klavye açıksa notun satırı kalsın);
        // medyanın YERLEŞİM boyu ise klavyesiz yükseklikten — klavye açılınca
        // medya yeniden ölçülmez (bkz. [_visibleHeight]).
        final max = pinnedMaxHeight(
          available: constraints.maxHeight,
          stable: stable,
        );
        final layoutMax = pinnedMaxHeight(available: stable, stable: stable);
        final live = _live;
        // VİDEO EKRANA TAM OTURUR (kullanıcı isteği 2026-10-20: "16:9
        // alanında sağda solda boşluk kalmayacak şekilde"): bölme videonun
        // genişlikteki doğal boyunu AŞMAZ — saklı yükseklik ondan büyükse
        // (eski sabitleme, başka ekran) yanlarda kara pay kalıyordu.
        // 2026-11-05: görsel ve sunum da aynı kuralla — yanlarda boş pay
        // kalmaz. PDF bölmede genişliğe oturup dikeyde kaydığından sınır
        // değil, yalnız "Sığdır" hedefi (bir sayfa boyu).
        final ratio = _mediaRatio;
        final capped = ratio != null && !isPdf;
        final natural = capped
            ? constraints.maxWidth * ratio
            : double.infinity;
        _fitTarget = ratio == null
            ? null
            : _clamp(constraints.maxWidth * ratio, layoutMax);
        // Sürüklerken bölme sınırın altına da iner (geri bırakma hissi);
        // bırakınca sınıra oturur ya da sayfaya döner.
        // Yanda: medya sütunun tamamı; klavye açılınca yeniden ölçülmez,
        // yalnız pencere kırpılır (bkz. KeyboardClipWindow).
        final fillFull = math.max(
          0.0,
          math.max(stable, constraints.maxHeight) - kPinnedBarHeight,
        );
        final height = widget.fill
            ? fillFull
            : live != null
            ? live.clamp(0.0, max < kPinnedMinHeight ? kPinnedMinHeight : max)
            : _clamp(math.min(widget.media.pinHeight, natural), layoutMax);
        // Evreye bağlı: pencere dinleyicisinde, o anki evreyle hesaplanır.
        double visible() => widget.fill
            ? math.max(0.0, constraints.maxHeight - kPinnedBarHeight)
            : live != null
            ? height
            : _visibleHeight(
                context,
                layout: height,
                available: constraints.maxHeight,
                stable: stable,
              );
        // Canlandırmasız kare yalnız bu kurulumun İLK çizimi içindir.
        var snap = _takeSnap();
        // Balon yazılırken medya bölmenin TAMAMI (bkz. [_writing]).
        final writing = _writing && constraints.maxHeight.isFinite;
        _dragHeight = height;
        _dragMax = max;
        _dragNatural = natural;
        return Column(
          children: [
            ValueListenableBuilder<KeyboardPhase>(
              valueListenable: _keyboardN,
              child: media,
              builder: (_, _, media) {
                // Balon yazılırken medya bölmenin TAMAMI (bkz. [_writing]).
                final full = writing ? constraints.maxHeight : height;
                final laid = writing ? full : math.min(full, visible());
                _full = full;
                _retarget(laid, animate: live == null && !writing && !snap);
                snap = false;
                return SizedBox(
                  key: const ValueKey('pinned-media-window'),
                  height: laid,
                  child: OverflowBox(
                    alignment: Alignment.topCenter,
                    minHeight: full,
                    maxHeight: full,
                    child: ClipRect(
                      clipper: _WindowClip(laid, _dy),
                      child: ColoredBox(
                        color: background,
                        child: Flow(
                          delegate: _FitFlow(
                            laid: laid,
                            full: full,
                            dy: _dy,
                            // Görsel/video/sunum klavye açılınca KIRPILMAZ,
                            // küçülür (kullanıcı isteği 2026-10-20); metin,
                            // belge ve ses kartı okunur kalsın diye kırpılır.
                            shrink: !isText && !isPdf && !isAudio,
                          ),
                          children: [media!],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            Expanded(
              child: Flow(delegate: _shift, children: [lower]),
            ),
          ],
        );
      },
    );
    return layout;
  }

  /// Bölmenin içi: türüne göre okuyucu / oynatıcı / belge / görsel.
  Widget _media(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final isVideo = widget.media.kind == AttachmentKind.video;
    final isPdf = widget.media.kind == AttachmentKind.pdf;
    final isText = widget.media.kind == AttachmentKind.text;
    final isAudio = widget.media.kind == AttachmentKind.audio;
    final isSlide = widget.media.kind == AttachmentKind.slide;
    final isImage = widget.media.kind == AttachmentKind.image;
                return isText && isNoteTable(widget.media)
                    // TABLO SABİT BÖLMEDE (kullanıcı isteği 2026-11-23:
                    // "görsel gibi sabitlenebilir"): bölme genişliğinde,
                    // dikeyde kayar, hücreleri burada da yazılır.
                    ? SingleChildScrollView(
                        key: ValueKey('pinned-table-${widget.media.id}'),
                        padding: const EdgeInsets.all(AppSpace.m),
                        child: TablePageBox(
                          attachment: widget.media,
                          onChanged: widget.onTableChanged ?? (_) {},
                          onRemove: widget.onRemove,
                          editable: widget.onTableChanged != null,
                        ),
                      )
                    : isText
                    // METİN (2026-10-17): kaydırılan, seçilebilen kâğıt. Basılı
                    // tutmak metni SEÇER (görseldeki "aşağı çekip bırak"
                    // jesti yok) — bölmeden çıkış anahtardan/menüden.
                    ? TextReaderView(
                        key: ValueKey('pinned-text-${widget.media.id}'),
                        attachment: widget.media,
                      )
                    : isAudio
                    // SES: oynatıcı kartı; ±sn, hız ve "Not al" çubukta.
                    ? AudioCardBox(
                        key: ValueKey('pinned-audio-${widget.media.id}'),
                        attachment: widget.media,
                        noteAtButton: false,
                      )
                    : isSlide
                    // SUNUM (2026-10-17): slayt çevrilebilen kutu; bölmeden
                    // çıkış görünüm anahtarından.
                    ? WebDriveGate(
                        attachment: widget.media,
                        builder: (_, shown) => SlidePageBox(
                          key: ValueKey('pinned-slide-${widget.media.id}'),
                          attachment: shown,
                          onChanged: widget.onChanged ?? (_) {},
                        ),
                      )
                    : isPdf
                    // Belge kutusu kendi jestlerini kullanır (yatay kaydırma
                    // sayfa çevirir, çubuğu sayfa atlar); bölmeden çıkış
                    // görünüm anahtarından.
                    //
                    // OKUMA KİPİ (kullanıcı isteği 2026-11-03: "kitabını
                    // okurken güzel kullanışlı bir not uygulaması"): sayfa
                    // bölmenin GENİŞLİĞİNE oturur (yanlarda boşluk yok, yazı
                    // büyük), boyu taşarsa dikeyde kayar; yazı basılı
                    // tutularak seçilir → "Not al".
                    ? ColoredBox(
                        color: PdfReadStyle.of(context).background,
                        child: _shrinkPdf(WebDriveGate(
                          attachment: widget.media,
                          // KALEMLE YAZARKEN kalem sayfayı kaydırmaz (çizer);
                          // parmak kaydırır ("yalnız kalem" açıksa).
                          builder: (_, shown) => ScrollConfiguration(
                            behavior: ScrollConfiguration.of(context).copyWith(
                              dragDevices: !_penOn
                                  ? null
                                  : {
                                      PointerDeviceKind.mouse,
                                      PointerDeviceKind.trackpad,
                                      if (_policy.fingerScrolls)
                                        PointerDeviceKind.touch,
                                    },
                            ),
                            child: PdfPageBox(
                            ink: _penOn ? _inkFor(shown) : null,
                            key: ValueKey('pinned-pdf-${widget.media.id}'),
                            attachment: _penOn || identical(_shownInk, shown.ink)
                                ? shown
                                : shown.copyWith(ink: _shownInk),
                            onChanged: widget.onChanged ?? (_) {},
                            // Balonludan sabite alınan belge balonlarıyla
                            // görünür; çubukta göster/gizle.
                            showBubbles: true,
                            editBubbles: widget.onChanged != null,
                            addingBubbles: _pdfAdding,
                            addingPlain: _pdfPlain,
                            onBubbleWriting: _setWriting,
                            fitWidth: true,
                            externalBar: _pdfBar,
                            onNoteFromSelection: widget.onPdfNote,
                            onInsertToNote: widget.onInsertToNote,
                          ),
                          ),
                        )),
                      )
                    : GestureDetector(
                        onTap: isVideo
                            ? null
                            : () {
                                // Tutamaca dokunuş balonu açtıysa (kart şimdi
                                // açık) görüntüleyici açılmaz.
                                if (_ownBubbles?.openBubble != null &&
                                    !_tapBusy) {
                                  return;
                                }
                                if (_tapBusy) {
                                  // Görselin dışındaki boşluk da açık kartı
                                  // kapatır (katmanınki yalnız görselde).
                                  final own = _ownBubbles;
                                  if (own != null && !own.adding) {
                                    own.collapseAll();
                                  }
                                  return;
                                }
                                widget.onOpen();
                              },
                        // ÇİFT DOKUNUŞ = YAKINLAŞTIR (kullanıcı kararı
                        // 2026-11-05; PDF kutusu ve görüntüleyiciyle aynı).
                        onDoubleTapDown: isImage
                            ? (d) => _doubleTapAt = d.localPosition
                            : null,
                        onDoubleTap: isImage ? _toggleImageZoom : null,
                        // Genişliğe oturan görselde dikey kaydırma (bkz.
                        // [_fitWidthImage]).
                        // Dikey kaydırma burada DEĞİL: ölçek tanıyıcısında
                        // (bkz. [_onImageZoomUpdate]) — ayrı sürükleme
                        // tanıyıcısı iki parmağı engelliyordu.
                        // BASILI TUT = METİN SEÇİMİ (kullanıcı kararı
                        // 2026-11-05: "basılı tutmak metin seçimini açsın,
                        // balon sadece butonla eklensin"): yazılabilir
                        // görselde görseldeki yazı tanınıp seçilebilir
                        // ekranda açılır. Salt okunurda eski jest: aşağı
                        // çekip bırakınca sayfaya geri koyar.
                        onLongPress: widget.onExtractText == null
                            ? null
                            : () {
                                if (_bubbleEdit) return;
                                AppHaptics.tick();
                                widget.onExtractText!();
                              },
                        onLongPressStart: widget.onExtractText != null
                            ? null
                            : (_) {
                                AppHaptics.tick();
                                setState(() {
                                  _pulling = true;
                                  _pullDown = 0;
                                });
                              },
                        onLongPressMoveUpdate: widget.onExtractText != null
                            ? null
                            : (d) => setState(
                                () => _pullDown = d.offsetFromOrigin.dy,
                              ),
                        onLongPressEnd: widget.onExtractText != null
                            ? null
                            : (_) {
                                final unpin = _unpinArmed;
                                setState(() {
                                  _pulling = false;
                                  _pullDown = 0;
                                });
                                if (unpin) widget.onUnpin();
                              },
                        onLongPressCancel: widget.onExtractText != null
                            ? null
                            : () => setState(() {
                                _pulling = false;
                                _pullDown = 0;
                              }),
                        onSecondaryTapUp: (d) =>
                            unawaited(_showContextMenu(d.globalPosition)),
                        // Durum parmak İNERKEN okunur: tutamaca dokunuş balonu
                        // parmak kalkınca açar, `onTapDown` ise ondan SONRA
                        // gelebiliyor (kartı hemen kapatırdı).
                        child: Listener(
                          onPointerDown: (_) {
                            final own = _ownBubbles;
                            _tapBusy =
                                own != null &&
                                (own.adding || own.openBubble != null);
                          },
                          child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _fitWidthImage(isImage, _zoomable(
                              enabled: isImage,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  ColoredBox(
                                    color: isVideo
                                        ? Colors.black
                                        : scheme.surfaceContainerHigh,
                                    child: Transform.translate(
                                      offset: Offset(
                                        0,
                                        _pulling ? _pullDown.clamp(0, 140) : 0,
                                      ),
                                      child: Opacity(
                                        opacity: _pulling ? 0.6 : 1,
                                        child: NoteMediaBox(
                                          // Ek değişince (başka medya
                                          // sabitlenince) oynatıcı da
                                          // yenilensin.
                                          key: ValueKey(widget.media.id),
                                          attachment: widget.media,
                                          fit: BoxFit.contain,
                                          // Çizim görselin dikdörtgeninde,
                                          // aşağıdaki katmanda (F63.3).
                                          imageInk: !isImage,
                                          inlineWebVideo: true,
                                          showWebTitle: true,
                                          // Denetim bölmenin çubuğunda.
                                          videoControls: false,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (!isVideo && !_pulling)
                                    if (_layerBubbles() case final bubbles?)
                                      _imageBubbleLayer(bubbles),
                                  if (isImage &&
                                      !_pulling &&
                                      (_penOn || _shownInk.isNotEmpty))
                                    _imageInkLayer(),
                                ],
                              ),
                            )),
                            // Parmak çizerken (kalem kipi, "yalnız kalem"
                            // kapalı) iki parmak yakınlaştırır/kaydırır:
                            // dokunuşları çizim üstlendiği için dönüşümü bu
                            // katman uygular. Sarmalamaz (ağaç şekli sabit).
                            if (isImage && _penOn && !_policy.fingerScrolls)
                              InkNavLayer(
                                enabled: true,
                                controller: _inkFor(widget.media),
                                getMatrix: () => _imageZoom.value,
                                setMatrix: (m) => _imageZoom.value = m,
                                minScale: 1,
                                maxScale: 4,
                                clampToBounds: true,
                                child: const SizedBox.expand(),
                              )
                            else
                              const SizedBox.shrink(),
                            if (widget.media.caption.isNotEmpty &&
                                !_pulling &&
                                !_imageZoomed)
                              Align(
                                alignment: Alignment.bottomCenter,
                                child: ColoredBox(
                                  color: scheme.surfaceContainerHigh,
                                  child: AttachmentCaptionBand(
                                    text: widget.media.caption,
                                    onTap: widget.onCaption,
                                  ),
                                ),
                              ),
                            // Yazma kartı kendini yalnız bir balon
                            // düzenlenirken çizer (okuma kartında "Düzenle").
                            if (_canEditBubbles && _ownBubbles != null) ...[
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: BubbleDock(controller: _ownBubbles!),
                              ),
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: ValueListenableBuilder<bool>(
                                  valueListenable:
                                      _ownBubbles!.addingListenable,
                                  builder: (context, adding, _) => adding
                                      ? BubbleToolbar(controller: _ownBubbles!)
                                      : const SizedBox.shrink(),
                                ),
                              ),
                            ],
                            if (_unpinArmed)
                              PinnedUnpinHint(label: l10n.unpinMediaRelease),
                          ],
                        ),
                        ),
                      );
  }

  /// Sürüklemenin tabanı: son yerleşimde hesaplanan boy ve sınırlar (çubuk
  /// `build`'de bir kez kurulduğu için kapanışla taşınmaz).
  double _dragHeight = 0;
  double _dragMax = 0;
  double _dragNatural = double.infinity;

  /// AYRAÇ ÇUBUĞU: dikey sürükleme bölmeyi boyutlar; düğmeler de BURADA
  /// (kullanıcı bulgusu 2026-10-11: medyanın üstüne konan düğmeler YouTube
  /// oynatıcısının kendi sağ üst düğmeleriyle üst üste geliyordu). Çubuk
  /// medyanın DIŞINDA, hiçbir şeyi örtmez.
  Widget _bar(BuildContext context, {required bool timed}) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
              key: const ValueKey('pinned-media-bar'),
              behavior: HitTestBehavior.opaque,
              onVerticalDragStart: widget.fill
                  ? null
                  : (_) => setState(() => _live = _dragHeight),
              onVerticalDragUpdate: widget.fill
                  ? null
                  : (d) =>
                        setState(() => _live = (_live ?? _dragHeight) + d.delta.dy),
              onVerticalDragEnd: widget.fill ? null : (_) {
                final raw = _live ?? _dragHeight;
                setState(() => _live = null);
                if (raw < kPinnedUnpinHeight) {
                  widget.onUnpin();
                } else {
                  widget.onHeightChanged(_clamp(math.min(raw, _dragNatural), _dragMax));
                }
              },
              onVerticalDragCancel: () => setState(() => _live = null),
              child: Container(
                height: kPinnedBarHeight,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: PdfReadStyle.barColor(scheme),
                  border: Border(
                    top: PdfReadStyle.barLine(scheme),
                    bottom: BorderSide(color: AppTokens.of(context).hairline),
                  ),
                ),
                // Dar ekranda önce süre yazısı, sonra "Not al" yazısı, en
                // son bağlantı düğmesi düşer — denetimler ve anahtar kalır.
                child: LayoutBuilder(
                  builder: (context, bar) => Stack(
                    children: [
                      _barRow(context, bar.maxWidth),
                      // Videonun ilerlemesi çubuğun üst kenarında ince çizgi.
                      if (timed)
                        Positioned(
                          left: 0,
                          right: 0,
                          top: 0,
                          child: IgnorePointer(
                            child: VideoProgressLine(video: widget.media),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
  }

  /// Küçültme (bütün sığdır) denetimi bu ekte var mı.
  bool get _canShrink =>
      widget.onShrinkToFitChanged != null &&
      !widget.fill &&
      (widget.media.kind == AttachmentKind.image ||
          widget.media.kind == AttachmentKind.pdf);

  /// Düğmenin gösterdiği durum: kalıcı ayar ([PinnedMediaPane.shrinkToFit])
  /// ya da iki parmakla uzaklaştırılmış "bütün görsel" kipi ([_wholeImage]) —
  /// ikisi görünüşte aynı şey (görsel bölmeye bütün sığar).
  bool get _shrinkActive => widget.shrinkToFit || _wholeImage;

  /// Düğme: açıkken (ayar ya da kıstırma) genişliğe oturmaya döner; kapalıyken
  /// ayarı açar.
  void _toggleShrink() {
    if (_shrinkActive) {
      if (_wholeImage) setState(() => _wholeImage = false);
      if (widget.shrinkToFit) widget.onShrinkToFitChanged?.call(false);
    } else {
      widget.onShrinkToFitChanged?.call(true);
    }
  }

  /// Son çizilen çubuk genişliği: döndür düğmesi çubukta mı menüde mi.
  double _barWidth = 0;
  bool get _rotateInMenu => _barWidth < 430;

  /// **ÇUBUK DÜZENİ** (P49; OTURTMA F65.1, KARAR K-O6 — kullanıcı
  /// 2026-11-12: "sabit ek tasarımı, tuşları, özellikleri baştan").
  ///
  /// DAR çubuk (telefon, < 600 dp) en çok beş denetim: ⛶ · [oynatma] ·
  /// tutamak · birincil iş ("Not al") · ✏ · ⋮. Görünüm anahtarı, balon, yer
  /// imi, belge menüsü ve ek işleri TEK ⋮ levhasında ([_openSheet]) — hiçbiri
  /// silinmedi. GENİŞ çubukta (tablet/web) anahtar, balon ve yer imi çubukta
  /// da durur. Yanda en dar bölmede (< 220 dp) ⛶ ve "Not al" da levhaya iner.
  bool get _wideBar => _barWidth >= 600;
  bool get _tinyBar => _barWidth < 220;

  /// Bu eke kalemle yazılabilir mi (yazılabilir not; PDF ya da ölçüsü/oranı
  /// bilinen görsel).
  bool get _canPen =>
      widget.onChanged != null &&
      (widget.media.kind == AttachmentKind.pdf ||
          (widget.media.kind == AttachmentKind.image && _hasImageBounds));

  VoidCallback? get _effectiveAreaAsk =>
      widget.onSmartAreaAsk ??
      (widget.media.kind == AttachmentKind.pdf
          ? () => unawaited(_pdfBar.openAreaActions())
          : null);

  bool get _hasSmartActions =>
      widget.onExtractText != null ||
      widget.onSmartSummarize != null ||
      widget.onSmartTasks != null ||
      _effectiveAreaAsk != null;

  Future<void> _openSmartActions() => showPinnedSmartActionsSheet(
    context,
    onOcr: widget.onExtractText,
    onSummarize: widget.onSmartSummarize,
    onExtractTasks: widget.onSmartTasks,
    onAreaAsk: _effectiveAreaAsk,
  );

  /// **PANELDEKİ KALEM ↔ YÜZEN DÜĞME TAM SENKRON** (P49 (b)).
  ///
  /// KÖK NEDEN: düğme yalnız `!penActive` iken çiziliyordu — yüzen düğme
  /// editörün kalem kipini açınca paneldeki KAYBOLUYORDU; kalemli cihazda ise
  /// `autoStylus` açık olduğundan `_policy.layerActive` zaten `true` idi ve
  /// düğmeye basınca normal kalem tepsisi açılmak yerine otomatik kalem
  /// kapanıyordu. Artık editör `onPenOn` verdiyse kapalıyken HEP editörün
  /// normal kalem tepsisini açar, açıkken kapatır; tek başına (test/gömülü)
  /// kullanıldığında bölmenin kendi hızlı kalemini açıp kapatır.
  void _togglePen() {
    if (widget.onPenOn != null) {
      if (!widget.penActive) {
        if (!InkToolMemory.autoStylus) InkToolMemory.saveAutoStylus(true);
        widget.onPenOn!();
        return;
      }
      widget.onPenOff?.call();
      if (_ownPen) setState(() => _ownPen = false);
      return;
    }
    final on = _policy.layerActive;
    setState(() => _ownPen = !on);
    if (on) {
      if (widget.penActive) widget.onPenOff?.call();
      if (InkToolMemory.stylusEver && InkToolMemory.autoStylus) {
        InkToolMemory.saveAutoStylus(false);
      }
    } else if (!InkToolMemory.autoStylus) {
      InkToolMemory.saveAutoStylus(true);
    }
  }

  /// **HIZLI KALEM** (P49 (c): "paneldeki kalem açılınca silgili hızlı kalem
  /// menüsü"). Bölmenin kendi kalemi açıkken (editörün kalem tepsisi yokken)
  /// çubuğun solu kalem araçlarına döner: silgi · hızlı renkler · geri al ·
  /// yinele · kalem ayarları. Araç seçimi ortak (`InkToolMemory`).
  bool get _penTools => _ownPen && !widget.penActive && _canPen;

  Widget _penQuickTools(BuildContext context) => PinnedPenQuickTools(
    ink: _inkFor(widget.media),
    wideBar: _wideBar,
  );

  static String _sideLabel(AppLocalizations l10n, PinnedSide side) =>
      switch (side) {
        PinnedSide.top => l10n.pinnedSideTop,
        PinnedSide.left => l10n.pinnedSideLeft,
        PinnedSide.right => l10n.pinnedSideRight,
      };

  static IconData _sideIcon(PinnedSide side) => switch (side) {
    PinnedSide.top => Icons.horizontal_split_outlined,
    PinnedSide.left => Icons.vertical_split_outlined,
    PinnedSide.right => Icons.vertical_split,
  };

  Widget _barRow(BuildContext context, double width) {
    _barWidth = width;
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final isVideo = widget.media.kind == AttachmentKind.video;
    final isAudio = widget.media.kind == AttachmentKind.audio;
    final isPdf = widget.media.kind == AttachmentKind.pdf;
    final timed = isVideo || isAudio;
    final wide = _wideBar;
    final tiny = _tinyBar;
    final tools = _penTools;
    // 1,3× YAZIDA TAŞMA (P42 kalanı): yazılı düğmelerin eşiği yazı ölçeğiyle
    // büyür — büyük yazıda yazı düşer, simge kalır.
    final room = width / MediaQuery.textScalerOf(context).scale(1);
    final noteAtLabel = timed ? room >= 430 : room >= 330;
    // PDF'te "Not al" o anki SAYFAYA not açar (zamanlı medyada o ANA).
    final noteAtIcon = isPdf ? Icons.edit_note : Icons.more_time;
    final noteAtTooltip = isPdf ? l10n.pdfNoteAtPage : l10n.videoNoteAtTime;
    final penSelected = widget.onPenOn != null
        ? _explicitPen
        : _policy.layerActive;
    return Row(
      children: [
        // ÜST / SOL / SAĞ (geniş ekranda, 2026-11-09).
        if (widget.onCycleSide != null)
          _pinnedItem(
            'side',
            PinnedBarButton(
              key: const ValueKey('pinned-side'),
              tooltip: '${_sideLabel(l10n, widget.side)} — ${l10n.pinnedSideToggle}',
              icon: _sideIcon(widget.side),
              onPressed: widget.onCycleSide!,
            ),
          ),
        if (tools)
          _penQuickTools(context)
        else ...[
          // Sesin tam ekranı yok (kart kendisi oynatıcı).
          if (!isAudio && !tiny)
            _pinnedItem(
              'fullscreen',
              PinnedBarButton(
                key: const ValueKey('pinned-fullscreen'),
                tooltip: l10n.fullscreen,
                icon: Icons.fullscreen,
                onPressed: widget.onOpen,
              ),
            ),
          // DARALTINCA KÜÇÜLSÜN ÇUBUKTA, SOLDA (kullanıcı isteği 2026-11-22;
          // eskiden yalnız ⋮ levhasındaydı). Açıkken dolu simge + yumuşak
          // zemin; iki parmakla uzaklaştırıp görseli bütün sığdırınca da yanar.
          if (_canShrink && !tiny)
            _pinnedItem(
              'shrink',
              PinnedBarButton(
                key: const ValueKey('pinned-shrink'),
                tooltip: l10n.pinnedShrinkToFit,
                icon: _shrinkActive ? Icons.fit_screen : Icons.fit_screen_outlined,
                selected: _shrinkActive,
                tonal: true,
                onPressed: _toggleShrink,
              ),
            ),
          // VİDEO DENETİMİ (kullanıcı isteği 2026-10-16): ±10 sn ve
          // oynat/durdur medyanın HEMEN ALTINDA — oynatıcının
          // üstünü örtmez. Ses de aynı çubuğu kullanır (2026-10-17).
          if (timed)
            VideoTransportControls(
              video: widget.media,
              showTime: room >= 500,
              showSpeed: room >= 400,
              // Çubukta < 430 dp'de sığmaz (⋮ taşıyordu): orada menüde
              // (bkz. [_rotateInMenu]; cihaz turu 2026-11-05).
              showRotate: width >= 430,
            ),
          // Geniş çubukta yer imi (dar çubukta ⋮ levhasında).
          if (isPdf)
            ListenableBuilder(
              listenable: _pdfBar,
              builder: (context, _) => Row(
                mainAxisSize: MainAxisSize.min,
                children: _pdfBar.buildControls(context, width),
              ),
            ),
        ],
        if (widget.fill)
          const Spacer()
        else
          Expanded(
            child: Semantics(
              label: l10n.pinnedMediaResize,
              onTap: _fitTarget == null ? null : _fit,
              // TUTAMAĞA DOKUN = SIĞDIR: bölme medyanın doğal boyuna oturur
              // (sürükleme ayrı jest, çubuğun kendisinde). Yalnız boş orta
              // alan — düğmelerin dokunuşu gecikmez.
              child: GestureDetector(
                key: const ValueKey('pinned-media-fit'),
                behavior: HitTestBehavior.opaque,
                onTap: _fitTarget == null ? null : _fit,
                child: Tooltip(
                  message: _fitTarget == null ? '' : l10n.pinnedMediaFit,
                  child: Center(
                    child: Container(
                      width: _live != null ? 48 : 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _live != null
                            ? scheme.primary
                            : scheme.onSurfaceVariant.withValues(
                                alpha: AppAlpha.disabled,
                              ),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        // BİRİNCİL İŞ: "Not al". Kişiselleştirmede gizlenebilir (bkz.
        // UiItem.videoNoteAt).
        if (!tools && !tiny && widget.onNoteAt != null)
          Customizable(
            id: UiItem.videoNoteAt,
            child: noteAtLabel
                ? Padding(
                    padding: const EdgeInsets.only(right: AppSpace.xs),
                    child: TextButton.icon(
                      key: const ValueKey('pinned-note-at'),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        minimumSize: Size.zero,
                        backgroundColor: scheme.primaryContainer.withValues(
                          alpha: AppAlpha.strong,
                        ),
                        foregroundColor: scheme.onPrimaryContainer,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpace.s,
                          vertical: AppSpace.xs,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                      onPressed: widget.onNoteAt,
                      icon: Icon(noteAtIcon, size: AppIconSize.s),
                      label: Text(l10n.videoNoteAtTimeShort),
                    ),
                  )
                : IconButton(
                    key: const ValueKey('pinned-note-at'),
                    tooltip: noteAtTooltip,
                    visualDensity: VisualDensity.compact,
                    iconSize: AppIconSize.m,
                    color: scheme.primary,
                    icon: Icon(noteAtIcon),
                    onPressed: widget.onNoteAt,
                  ),
          ),
        // BALON EKLE: geniş çubukta menü düğmesi; dar çubukta levhada. Bırakma
        // kipi açıkken HER genişlikte ✓ (kipi kapatır). Görselde kip burada,
        // PDF'te belge kutusunda.
        // "T" düğmesi kaldırıldı (kullanıcı isteği 2026-11-12): Açık metin
        // balon menüsünde; gizle/göster de orada.
        // BALON DÜĞMESİ DAR ÇUBUKTA DA (kullanıcı isteği 2026-11-13: "sabit
        // panelin altında balon butonu olmalı"): yalnız en dar bölmede
        // (< 220 dp) ⋮ levhasında kalır.
        if (_canEditBubbles && !tools && (!tiny || _bubbleEdit))
          _pinnedItem('bubble', _addBubbleButton(context, active: _bubbleEdit))
        else if (_canEditPdfBubbles && !tools)
          _pinnedItem(
            'bubble',
            ValueListenableBuilder<bool>(
              valueListenable: _pdfAdding,
              builder: (context, adding, _) => !tiny || adding
                  ? _addBubbleButton(context, active: adding)
                  : const SizedBox.shrink(),
            ),
          ),
        if (!_hasSheet &&
            (!isVideo || width >= 360) &&
            widget.onCopyLink != null &&
            widget.media.isWebVideo)
          _pinnedItem(
            'link',
            PinnedBarButton(
              tooltip: l10n.copyVideoLink,
              icon: Icons.link,
              onPressed: widget.onCopyLink!,
            ),
          ),
        if (!tools && wide && _hasSmartActions)
          _pinnedItem(
            'smart',
            PinnedBarButton(
              key: const ValueKey('pinned-smart-actions'),
              tooltip: l10n.pinnedSmartActions,
              icon: Icons.auto_awesome_outlined,
              onPressed: () => unawaited(_openSmartActions()),
            ),
          ),
        if (widget.viewSwitch case final viewSwitch? when wide && !tools)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.xxs),
            child: viewSwitch,
          )
        else if (widget.viewSwitch == null && !hasMenu)
          _pinnedItem(
            'unpin',
            PinnedBarButton(
              tooltip: l10n.viewModeFloatingHint,
              icon: Icons.vertical_align_bottom,
              onPressed: widget.onUnpin,
            ),
          ),
        // ÜZERİNE YAZ (kullanıcı isteği 2026-11-08): sabit belgeye/görsele
        // doğrudan kalemle yazılır (bkz. [_togglePen]).
        // EDİTÖRDE YOK (kullanıcı isteği 2026-11-22: "alt panelde zaten kalem
        // varsa görsel/PDF sabit panelinde kaleme ihtiyaç yok"): bölme
        // editörün normal kalemini kullanıyorsa ([PinnedMediaPane.onPenOn])
        // kalem alt çubuktan açılır; düğme yalnız bölmenin kendi hızlı
        // kalemi için kalır.
        if (_canPen && widget.onPenOn == null)
          _pinnedItem(
            'pen',
            PinnedBarButton(
              key: const ValueKey('pinned-pen'),
              tooltip: l10n.pinnedPenWrite,
              icon: penSelected ? Icons.draw : Icons.draw_outlined,
              selected: penSelected,
              tonal: true,
              onPressed: _togglePen,
            ),
          ),
        if (_hasSheet)
          PinnedBarButton(
            key: const ValueKey('pinned-media-menu'),
            tooltip: l10n.more,
            icon: Icons.more_vert,
            onPressed: () => unawaited(_openSheet()),
          ),
      ],
    );
  }

  /// Balon göster/gizle (balon varsa): görselde denetleyicide, PDF'te ekte.
  ({bool hidden, VoidCallback flip})? _bubbleToggle() {
    if (_canEditBubbles) {
      final own = _ownController();
      if (own.bubbles.isEmpty) return null;
      return (hidden: own.hidden, flip: () => own.setHidden(!own.hidden));
    }
    final a = widget.media;
    if (!_canEditPdfBubbles || a.bubbles.isEmpty) return null;
    return (
      hidden: a.bubblesHidden,
      flip: () =>
          widget.onChanged?.call(a.copyWith(bubblesHidden: !a.bubblesHidden)),
    );
  }

  /// **BALON EKLE MENÜSÜ** (kullanıcı bulgusu 2026-11-05: "açık metin
  /// yazma kısmını bulamadım"): tür seçimi eskiden yalnız bırakma kipinin
  /// araç kartındaydı ve kip basılı tutmakla atlanınca kart hiç
  /// görünmüyordu. 2026-11-19'dan beri düğme menü AÇMAZ: tek dokunuşla
  /// bırakma kipi açılır, tür (Balon | Metin) kipin araç kartında seçilir;
  /// kip açıkken düğme ✓ olur ve kipi kapatır. Dar çubukta aynısı ⋮
  /// levhasının "Balonlar" bölümünde.
  Widget _addBubbleButton(BuildContext context, {required bool active}) {
    final l10n = context.l10n;
    if (active) {
      return PinnedBarButton(
        key: const ValueKey('pinned-add-bubble'),
        tooltip: l10n.bubbleAddDone,
        icon: Icons.check,
        selected: true,
        tonal: true,
        onPressed: _stopAdding,
      );
    }
    // TEK DOKUNUŞ = BIRAKMA KİPİ (kullanıcı bulgusu 2026-11-19: "balona
    // tıklıyorum, önce Balon mu metin mi diye soruyor; içeride yine
    // soruyor — baştaki soru gereksiz"). Tür seçimi yalnız bırakma kipinin
    // araç kartında (Balon | Metin bölmesi); kip son seçilen türle açılır.
    // Gizle/göster balon varken yanındaki göz düğmesinde (görüntüleyici
    // balon çubuğuyla aynı).
    final toggle = _bubbleToggle();
    // Doğrudan IconButton (ara `PinnedBarButton` yok): klavye açılış karesinin
    // kurulum bütçesi (S17 sabit görsel/PDF) eski menü düğmesiyle aynı kalsın.
    final add = IconButton(
      key: const ValueKey('pinned-add-bubble'),
      tooltip: l10n.bubbleAdd,
      visualDensity: VisualDensity.compact,
      iconSize: AppIconSize.m,
      icon: const Icon(Icons.add_comment_outlined),
      onPressed: () => _startAdding(plain: _lastPlain),
    );
    if (toggle == null) return add;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        add,
        PinnedBarButton(
          key: const ValueKey('pinned-bubbles-toggle'),
          tooltip: toggle.hidden ? l10n.bubblesShow : l10n.bubblesHide,
          icon: toggle.hidden
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          selected: toggle.hidden,
          onPressed: toggle.flip,
        ),
      ],
    );
  }

  /// Bırakma kipinin son türü (araç kartında değişebilir).
  bool get _lastPlain => _canEditBubbles
      ? _ownController().plainMode
      : _pdfPlain.value;

  /// Ek işleri verilmiş mi (salt okunurda kaldır/paylaş yok).
  bool get hasMenu =>
      widget.onRemove != null ||
      widget.onTranscribe != null ||
      widget.onSaveAs != null ||
      widget.onShare != null;

  /// ⋮ levhasında gösterilecek bir şey var mı.
  bool get _hasSheet =>
      hasMenu ||
      _hasSmartActions ||
      widget.media.kind == AttachmentKind.pdf ||
      widget.viewSwitch != null ||
      widget.sheetViewSwitch != null ||
      widget.onSelectSide != null ||
      (!_wideBar && (_canEditBubbles || _canEditPdfBubbles)) ||
      (_tinyBar &&
          (widget.media.kind != AttachmentKind.audio ||
              widget.onNoteAt != null));

  void _run(AttachmentAction action) {
    switch (action) {
      case AttachmentAction.open:
        widget.onOpen();
      case AttachmentAction.rotate:
        VideoHubScope.maybeOf(context)?.rotate(widget.media.id);
      case AttachmentAction.caption:
        widget.onCaption?.call();
      case AttachmentAction.copyLink:
        widget.onCopyLink?.call();
      case AttachmentAction.copy:
        widget.onCopy?.call();
      case AttachmentAction.extractText:
        widget.onExtractText?.call();
      case AttachmentAction.transcribe:
        widget.onTranscribe?.call();
      case AttachmentAction.share:
        widget.onShare?.call();
      case AttachmentAction.saveAs:
        widget.onSaveAs?.call();
      case AttachmentAction.remove:
        widget.onRemove?.call();
      case _:
        break;
    }
  }

  List<AttachmentAction> _actions(AttachmentSurface surface) =>
      attachmentActionsFor(
        widget.media,
        surface,
        AttachmentCaps(
          rotate: _rotateInMenu,
          caption: widget.onCaption != null,
          transcribe: widget.onTranscribe != null,
          extractText: widget.onExtractText != null,
          copy: widget.onCopy != null,
          share: widget.onShare != null,
          saveAs: widget.onSaveAs != null,
          copyLink: widget.onCopyLink != null,
          remove: widget.onRemove != null,
        ),
      );

  /// Eke sağ tık (masaüstü, F40.8): aynı liste, imlecin yanında.
  Future<void> _showContextMenu(Offset global) async {
    final action = await showAttachmentContextMenu(
      context,
      global,
      _actions(AttachmentSurface.contextMenu),
    );
    if (action != null && mounted) _run(action);
  }

  /// **TEK ⋮ LEVHASI** (P49 (a), kullanıcı 2026-11-12: "⋮ ile sayfalara göz
  /// at menüleri tek ⋮ menüde; kart düğmesi bizim stilde, yer açılır").
  ///
  /// Eskiden çubukta iki ayrı açılır menü vardı (belge menüsü + ek menüsü),
  /// yanlarında görünüm anahtarı ve balon düğmesi: telefonda 10 denetim.
  /// Şimdi hepsi tek levhada, uygulamanın karolarıyla (DENEYIM §2.3):
  /// Görünüm anahtarı · Balonlar · PDF (sayfalara göz at, yer imi…) · ek
  /// işleri (tek katalog, bkz. [attachmentActionsFor]) · Kaldır. Seçim
  /// levhayı kapatır, iş kapandıktan SONRA koşar.
  /// Sabit ek çubuğunun gizlenebilen düğmesi (P63 PB7, [UiItem.pinned]):
  /// varsayılan GÖRÜNÜR (Y10: ⋮'e inmez); düzen modunda çerçeveli, normal
  /// kipte kullanıcı gizlediyse yer kaplamaz. Anahtarlar düzen merkezindeki
  /// `pinnedCatalog` ile aynı.
  /// Normal kipte araya öğe girmez (S17 geçiş karesi); kayıt değişince
  /// bölme [_onPersonalize] ile yeniden kurulur.
  static Widget _pinnedItem(String key, Widget child) =>
      Customizable.slot(UiItem.pinned(key), child);

  /// Düzen modu / görünürlük değişti (seyrek): çubuk yeni hâliyle kurulur.
  void _onPersonalize() {
    if (mounted) setState(() {});
  }

  Future<void> _openSheet() async {
    final run = await showAppSheet<VoidCallback>(
      context: context,
      isScrollControlled: true,
      // Tutup aşağı çekerek kapatılır (kullanıcı isteği 2026-11-14).
      showDragHandle: true,
      builder: _sheet,
    );
    if (run != null && mounted) run();
  }

  Widget _sheet(BuildContext sheet) {
    final theme = Theme.of(sheet);
    final scheme = theme.colorScheme;
    final tokens = AppTokens.fromTheme(theme);
    final text = AppText.of(theme);
    final l10n = sheet.l10n;
    final media = widget.media;
    final wide = _wideBar;
    void pick(VoidCallback run) => Navigator.pop(sheet, run);
    Widget tile(String key, IconData icon, String label, VoidCallback run) =>
        SheetTile.tile(
          key: ValueKey(key),
          icon: icon,
          label: label,
          onTap: () => pick(run),
        );
    Widget section(String label) => Padding(
      padding: const EdgeInsets.only(top: AppSpace.l, bottom: AppSpace.s),
      child: SectionLabel(label),
    );

    final kindIcon = switch (media.kind) {
      AttachmentKind.pdf => Icons.picture_as_pdf_outlined,
      AttachmentKind.image => Icons.image_outlined,
      AttachmentKind.video => Icons.play_circle_outline,
      AttachmentKind.audio => Icons.audiotrack_outlined,
      AttachmentKind.slide => Icons.slideshow_outlined,
      AttachmentKind.text => Icons.description_outlined,
      AttachmentKind.unknown => Icons.attach_file_outlined,
    };
    final subtitle = switch (media.kind) {
      AttachmentKind.pdf when _pdfBar.ready && _pdfBar.pageCount > 0 =>
        '${l10n.cardKindPdf} · ${_pdfBar.page} / ${_pdfBar.pageCount}',
      AttachmentKind.pdf => l10n.cardKindPdf,
      AttachmentKind.image
          when (media.width ?? 0) > 0 && (media.height ?? 0) > 0 =>
        '${media.width} × ${media.height}',
      _ => null,
    };

    final viewSwitch = widget.sheetViewSwitch?.call(sheet) ?? widget.viewSwitch;
    final canShrink =
        widget.onShrinkToFitChanged != null &&
        !widget.fill &&
        (media.kind == AttachmentKind.image ||
            media.kind == AttachmentKind.pdf);
    final bubbles = !wide && (_canEditBubbles || _canEditPdfBubbles);
    final toggle = _bubbleToggle();
    final document = media.kind == AttachmentKind.pdf
        ? _pdfBar.menuActions(sheet)
        : const <PdfMenuAction>[];
    final actions = _actions(AttachmentSurface.pinned);
    final others = [
      // En dar bölmede çubuktan inenler.
      if (_tinyBar && media.kind != AttachmentKind.audio)
        tile(
          'pinned-action-open',
          Icons.fullscreen,
          l10n.fullscreen,
          widget.onOpen,
        ),
      if (_tinyBar && widget.onNoteAt != null)
        tile(
          'pinned-action-note-at',
          media.kind == AttachmentKind.pdf ? Icons.edit_note : Icons.more_time,
          media.kind == AttachmentKind.pdf
              ? l10n.pdfNoteAtPage
              : l10n.videoNoteAtTime,
          widget.onNoteAt!,
        ),
      for (final action in actions)
        if (action != AttachmentAction.remove)
          Builder(
            key: ValueKey('pinned-action-${action.name}'),
            builder: (context) {
              final look = attachmentActionLook(context, action);
              return SheetTile.tile(
                icon: look.icon,
                label: look.label,
                onTap: () => pick(() => _run(action)),
              );
            },
          ),
    ];
    final grouped =
        _hasSmartActions ||
        viewSwitch != null ||
        widget.onSelectSide != null ||
        canShrink ||
        bubbles ||
        document.isNotEmpty;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.l,
        0,
        AppSpace.l,
        AppSpace.l,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.m),
                ),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(
                    kindIcon,
                    size: AppIconSize.m,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      media.fileName.isEmpty ? l10n.more : media.fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.sheetTitle,
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.meta,
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (viewSwitch != null) ...[
            const SizedBox(height: AppSpace.l),
            DecoratedBox(
              decoration: BoxDecoration(
                color: tokens.card,
                borderRadius: BorderRadius.circular(AppRadius.l),
                border: Border.all(color: tokens.hairline),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.m),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionLabel(l10n.viewModeTitle),
                    const SizedBox(height: AppSpace.s),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: viewSwitch,
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (widget.onSelectSide != null) ...[
            const SizedBox(height: AppSpace.s),
            DecoratedBox(
              key: const ValueKey('pinned-sheet-side'),
              decoration: BoxDecoration(
                color: tokens.card,
                borderRadius: BorderRadius.circular(AppRadius.l),
                border: Border.all(color: tokens.hairline),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.m),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionLabel(l10n.pinnedSideTitle),
                    const SizedBox(height: AppSpace.s),
                    Row(
                      children: [
                        for (final (i, target) in PinnedSide.values.indexed) ...[
                          if (i > 0) const SizedBox(width: AppSpace.s),
                          Expanded(
                            child: Semantics(
                              button: true,
                              selected: target == widget.side,
                              label: _sideLabel(l10n, target),
                              child: Material(
                                key: ValueKey(
                                  'pinned-side-pick-${target.name}',
                                ),
                                color: target == widget.side
                                    ? scheme.primaryContainer
                                    : scheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.m,
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.m,
                                  ),
                                  onTap: () =>
                                      pick(() => widget.onSelectSide!(target)),
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      minHeight: kMinInteractiveDimension,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpace.xs,
                                        vertical: AppSpace.xs,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            _sideIcon(target),
                                            size: AppIconSize.s,
                                            color: target == widget.side
                                                ? scheme.onPrimaryContainer
                                                : scheme.onSurfaceVariant,
                                          ),
                                          const SizedBox(width: AppSpace.xs),
                                          Flexible(
                                            child: Text(
                                              _sideLabel(l10n, target),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: text.label.copyWith(
                                                color: target == widget.side
                                                    ? scheme.onPrimaryContainer
                                                    : scheme.onSurface,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          // Düğme çubukta (solda); levhada yalnız çubuk ona yer vermezse.
          if (canShrink && _tinyBar) ...[
            const SizedBox(height: AppSpace.s),
            Material(
              color: tokens.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.m),
                side: BorderSide(color: tokens.hairline),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                key: const ValueKey('pinned-action-shrink'),
                onTap: () => pick(_toggleShrink),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.m,
                    vertical: AppSpace.s,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _shrinkActive
                            ? Icons.fit_screen
                            : Icons.fit_screen_outlined,
                        size: AppIconSize.m,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: AppSpace.m),
                      Expanded(
                        child: Text(
                          l10n.pinnedShrinkToFit,
                          style: text.label,
                        ),
                      ),
                      IgnorePointer(
                        child: Switch(
                          value: _shrinkActive,
                          onChanged: (_) {},
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          if (_hasSmartActions) ...[
            section(l10n.pinnedSmartActions),
            SheetTileGrid(
              children: [
                if (widget.onExtractText != null)
                  tile(
                    'pinned-sheet-smart-ocr',
                    Icons.document_scanner_outlined,
                    l10n.pinnedSmartOcr,
                    widget.onExtractText!,
                  ),
                if (widget.onSmartSummarize != null)
                  tile(
                    'pinned-sheet-smart-summarize',
                    Icons.summarize_outlined,
                    l10n.pinnedSmartSummarize,
                    widget.onSmartSummarize!,
                  ),
                if (widget.onSmartTasks != null)
                  tile(
                    'pinned-sheet-smart-tasks',
                    Icons.checklist_rtl_outlined,
                    l10n.pinnedSmartTasks,
                    widget.onSmartTasks!,
                  ),
                if (_effectiveAreaAsk != null)
                  tile(
                    'pinned-sheet-smart-area-ask',
                    Icons.crop_free_outlined,
                    l10n.pinnedSmartAreaAsk,
                    _effectiveAreaAsk!,
                  ),
              ],
            ),
          ],
          if (bubbles) ...[
            section(l10n.bubblesOverviewTitle),
            SheetTileGrid(
              children: [
                // Tür (Balon | Metin) bırakma kipinin araç kartında —
                // burada ikinci kez sorulmaz (kullanıcı bulgusu 2026-11-19).
                tile(
                  'pinned-add-bubble-note',
                  Icons.add_comment_outlined,
                  l10n.bubbleAdd,
                  () => _startAdding(plain: _lastPlain),
                ),
                if (toggle != null)
                  tile(
                    'pinned-bubbles-toggle',
                    toggle.hidden
                        ? Icons.speaker_notes_off_outlined
                        : Icons.chat_bubble_outline,
                    toggle.hidden ? l10n.bubblesShow : l10n.bubblesHide,
                    toggle.flip,
                  ),
              ],
            ),
          ],
          if (document.isNotEmpty) ...[
            section(l10n.cardKindPdf),
            SheetTileGrid(
              children: [
                for (final a in document)
                  tile('pinned-pdf-${a.id}', a.icon, a.label, a.run),
              ],
            ),
          ],
          if (others.isNotEmpty) ...[
            if (grouped)
              section(l10n.more)
            else
              const SizedBox(height: AppSpace.m),
            SheetTileGrid(children: others),
          ],
          if (actions.contains(AttachmentAction.remove)) ...[
            const SizedBox(height: AppSpace.l),
            Builder(
              builder: (context) {
                final look = attachmentActionLook(
                  context,
                  AttachmentAction.remove,
                );
                return DestructiveRow(
                  key: const ValueKey('pinned-action-remove'),
                  icon: look.icon,
                  label: look.label,
                  onTap: () => pick(() => _run(AttachmentAction.remove)),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

/// Alt parçayı (çubuk + not) [dy] kadar aşağıda boyar — yerleşim yok.
class _ShiftFlow extends FlowDelegate {
  _ShiftFlow(this.dy) : super(repaint: dy);

  final ValueListenable<double> dy;

  @override
  BoxConstraints getConstraintsForChild(int i, BoxConstraints constraints) =>
      BoxConstraints.tight(constraints.biggest);

  @override
  void paintChildren(FlowPaintingContext context) => context.paintChild(
    0,
    transform: Matrix4.translationValues(0, dy.value, 0),
  );

  @override
  bool shouldRepaint(_ShiftFlow oldDelegate) => oldDelegate.dy != dy;
}

/// Medyayı tam boyunda ([full]) yerleştirir; [shrink] ise görünen boya
/// (`laid + dy`) sığacak kadar küçülterek boyar (üst ortadan).
class _FitFlow extends FlowDelegate {
  _FitFlow({
    required this.laid,
    required this.full,
    required this.dy,
    required this.shrink,
  }) : super(repaint: dy);

  final double laid;
  final double full;
  final ValueListenable<double> dy;
  final bool shrink;

  @override
  BoxConstraints getConstraintsForChild(int i, BoxConstraints constraints) =>
      BoxConstraints.tight(constraints.biggest);

  @override
  void paintChildren(FlowPaintingContext context) {
    final scale = !shrink || full <= 0
        ? 1.0
        : ((laid + dy.value) / full).clamp(0.0, 1.0);
    final width = context.size.width;
    context.paintChild(
      0,
      transform: Matrix4.identity()
        ..translateByDouble(width * (1 - scale) / 2, 0, 0, 1)
        ..scaleByDouble(scale, scale, 1, 1),
    );
  }

  @override
  bool shouldRepaint(_FitFlow oldDelegate) =>
      oldDelegate.laid != laid ||
      oldDelegate.full != full ||
      oldDelegate.shrink != shrink ||
      oldDelegate.dy != dy;
}

/// Pencerenin görünen kısmı: üstten `laid + dy` (boyama; [dy] değişince
/// yeniden kırpılır, yerleşim yok).
class _WindowClip extends CustomClipper<Rect> {
  _WindowClip(this.laid, this.dy) : super(reclip: dy);

  final double laid;
  final ValueListenable<double> dy;

  @override
  Rect getClip(Size size) => Rect.fromLTWH(
    0,
    0,
    size.width,
    (laid + dy.value).clamp(0.0, size.height),
  );

  @override
  bool shouldReclip(_WindowClip oldClipper) =>
      oldClipper.laid != laid || oldClipper.dy != dy;
}
