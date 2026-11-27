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

part 'pinned_media_pane_parts.dart';
part 'pinned_media_pane_sheet.dart';

/// Sabit bölmenin yüksekliği bu sınırlar arasında kalır (dp / oran).
const double kPinnedMinHeight = 96;
const double kPinnedMaxFraction = 0.7;

/// Ayraç bu yüksekliğin altına çekilip bırakılırsa medya sayfaya geri döner.
const double kPinnedUnpinHeight = 72;

/// Klavye açıkken bölmenin altında notun yazılan satırına kalan en az yer.
const double kPinnedNoteMinHeight = 72;

/// Klavye açıkken medyanın görünür penceresinin en az yüksekliği.
const double kPinnedVisibleFloor = 56;


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
  void _redraw([VoidCallback? fn]) => setState(fn ?? () {});
  /// Sabit görselin üstündeki balonların denetleyicisi (bkz.
  /// [PinnedMediaPane.bubbleDoc]); aç/kapa durumu yazılmaz — görselin
  /// uzayındaki kopya belgeye geri yazılamaz, okuma için yeter.
  BubbleController? _imageBubbles;

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
  Offset? _doubleTapAt;
  late final AnimationController _fling = AnimationController.unbounded(
    vsync: this,
  )..addListener(() => _imageScroll.to(_fling.value));
  final _imageScroll = FitScroll();
  String? _probedFor;
  double? _probedRatio;
  double? _fitTarget;

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

  @override
  Widget build(BuildContext context) => _buildPinnedPane(context);
}

