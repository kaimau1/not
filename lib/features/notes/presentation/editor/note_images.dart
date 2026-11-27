import '../../../../app/theme/app_tokens.dart';
import '../../../../app/theme/fixed_colors.dart';
import '../../../../core/app_icons.dart';

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/l10n_ext.dart';
import '../../../../core/personalize.dart';
import '../../../../core/widgets/customizable.dart';
import '../../../../core/widgets/keyboard_snap.dart';
import '../../../../core/widgets/pop_in.dart';
import '../../../../core/utils/local_file.dart';
import '../../../../core/utils/video_time.dart';
import '../../../../core/widgets/undo_snackbar.dart';
import '../../data/video_frame.dart';
import '../../domain/attachment.dart';
import '../../domain/note_table.dart';
import '../drive_ui.dart';
import '../note_card_media.dart' show VideoPoster;
import '../viewers/image_viewer.dart';
import '../viewers/ink_layer.dart';
import 'page_ink_layer.dart' show InkExclusionZone;
import '../viewers/ink_tools.dart' show InkToolMemory;
import '../viewers/pen_policy.dart';
import '../viewers/pdf_viewer_screen.dart';
import '../../../../core/utils/youtube.dart';
import '../viewers/video_viewer.dart';
import '../viewers/youtube_viewer.dart';
import 'image_layout.dart';
import 'audio_card_box.dart';
import 'pdf_page_box.dart';
import '../viewers/slide_viewer_screen.dart';
import 'slide_page_box.dart';
import 'table_page_box.dart';
import 'text_page_box.dart';
import 'text_wrap.dart';
import 'video_hub_scope.dart';
import 'video_transport.dart';
import 'attachment_actions.dart';
import 'attachment_status.dart';
import 'view_mode_switch.dart';
import '../../../../core/widgets/smooth_routes.dart';
import '../../../../core/haptics.dart';

part 'note_video_boxes.dart';
part 'note_image_tools.dart';
part 'note_image_caption.dart';
part 'note_media_box.dart';
part 'note_image_canvas_items.dart';

class NotePageCanvas extends StatefulWidget {
  const NotePageCanvas({
    super.key,
    required this.images,
    required this.child,
    required this.minHeight,
    required this.onRemove,
    required this.onChanged,
    this.onInkChanged,
    this.onCrop,
    this.onRotate,
    this.onExtractText,
    this.onCopy,
    this.onCopyMany,
    this.onChangedMany,
    this.onVideoToNote,
    this.onTranscribe,
    this.onSaveAs,
    this.onShare,
    this.onRename,
    this.onPinTop,
    this.onPinHover,
    this.onPinDrag,
    this.onViewChange,
    this.onEmbed,
    this.onTapEmpty,
    this.placementHintId,
    this.onPlacementHintShown,
    this.topLimit = 0,
    this.onFloats,
    this.hint,
    this.hintLineHeight = 0,
    this.textTop = 0,
    this.textLeft = 0,
    this.readOnly = false,
    this.onTableChanged,
  });

  final List<Attachment> images;

  /// Sayfa içeriği (başlık, çipler, gövde metni). Görseller bunun üstünde.
  final Widget child;

  /// Görsellerin inebileceği en üst nokta (dp) — başlık ve çip satırının
  /// altı. Görsel başlığın üzerine hiç çıkamaz. Gövde metninin ilk satırının
  /// tepesi de burasıdır ([hint] bu noktadan aşağı itilir).
  final double topLimit;

  /// [topLimit] ile gövde metninin İLK SATIRININ tepesi arasındaki boşluk
  /// (dp) — alanın `contentPadding.top`u. İpucu metnin ilk satırıyla AYNI
  /// çizgide durmalı; bu pay geçilmezse ipucu bir yerde, imleç başka yerde
  /// görünür (kullanıcı bulgusu 2026-08-16 ve yine 2026-08-30).
  final double textTop;

  /// Gövde metninin SOL kenarı (dp) — alanın sayfa kenarından boşluğu.
  /// İpucu, metnin sütununda konumlanır: bantlar sayfa uzayında ölçülüyor,
  /// sarma planı ise sütun uzayında çalışıyor. Bu pay geçilmezse ipucu, metnin
  /// başladığı yerin bir kenar boşluğu KADAR sağında durur.
  final double textLeft;

  /// Salt okunur not: tablo hücreleri yazılmaz (bkz. [TablePageBox]).
  final bool readOnly;

  /// Tablo İÇERİĞİ (hücre, yapı, oran) — kök kurulmadan kaydedilir; yoksa
  /// [onChanged].
  final ValueChanged<Attachment>? onTableChanged;

  /// Boş gövdenin ipucu metni ("Not yaz…"), tuval üzerinde konumlandırılır.
  ///
  /// KÖK NEDEN: ipucu metin değil dekorasyondur — sarma motoru onu görselin
  /// etrafından akıtamaz, sabit yerinde durur ve üste sürüklenen görselin
  /// altında kaybolur. Eskiden görsel bir satır aşağı ZORLANARAK çözülüyordu;
  /// kullanıcı görseli en üste koyamıyordu. Artık görsel serbest, ipucu iner.
  final Widget? hint;

  /// İpucu satırının yüksekliği (dp) — hangi görsellerin ipucunu kestiği
  /// bu bantla ölçülür.
  final double hintLineHeight;

  /// Görsellerin SAYFA üzerinde kapladığı bantları bildirir; metin bunların
  /// etrafından akar (bkz. text_wrap.dart). Konumlar sayfanın (bu tuvalin
  /// [child]'ının) sol-üst köşesine göredir.
  final ValueChanged<List<FloatBox>>? onFloats;

  /// Sayfanın en az yüksekliği (görünür alan — boş nota da tam sayfa tuval).
  final double minHeight;

  final ValueChanged<Attachment> onRemove;
  final ValueChanged<Attachment> onChanged;

  /// Gömülü belgenin üstüne çizilen çizgi (yalnız `ink` değişir). Ayrı:
  /// editör bunu kök kurmadan, gecikmeli kaydeder. null ise [onChanged].
  final ValueChanged<Attachment>? onInkChanged;

  /// Birden çok eki TEK yazımda günceller ("satıra sığdır", "boyutları
  /// eşitle"). null ise ekler tek tek [onChanged]'e verilir — o zaman her ek
  /// ayrı bir kayıt ve ayrı bir geri-al adımı olur.
  final ValueChanged<List<Attachment>>? onChangedMany;

  /// Tam ekranda seçilen kırpma alanını uygular (bkz. [ImageViewerScreen]).
  final Future<void> Function(Attachment, Rect)? onCrop;

  /// Görseli 90°'nin katıyla döndürüp KALICI olarak yeniden yazacak taraf
  /// ([onCrop] ile aynı gerekçe: dosyayı yeniden yazmak ek deposu ve not
  /// kimliği ister, ikisi de bu katmanda yok). null ise döndürme düğmesi
  /// çizilmez.
  final Future<Attachment?> Function(Attachment, int)? onRotate;
  final Future<void> Function(Attachment)? onExtractText;

  /// Görseli panoya kopyalar; null ise menüde görünmez.
  final ValueChanged<Attachment>? onCopy;

  /// ÇOKLU seçimde: seçilen eklerin tamamını panoya alır (kullanıcı isteği
  /// 2026-08-09: "görsellerde çoklu seçim ve kopyalama"). null ise çoklu
  /// seçim girişi hiç gösterilmez.
  final ValueChanged<List<Attachment>>? onCopyMany;

  /// Videodan AI ile not çıkarır; yalnız video ekinin menüsünde görünür.
  final ValueChanged<Attachment>? onVideoToNote;

  /// Görselin/videonun transkripti (bkz. `TranscriptScreen`); PDF'te yok.
  final ValueChanged<Attachment>? onTranscribe;

  /// Eki FARKLI KAYDET (dosyası olan her tür; YouTube bağlantısında yok).
  final ValueChanged<Attachment>? onSaveAs;

  /// Eki paylaş (gömülü ek menüsü).
  final ValueChanged<Attachment>? onShare;

  /// Ek adını düzenle (yüzen menü / sağ tık).
  final ValueChanged<Attachment>? onRename;

  /// **ÜSTE SABİTLE** (kullanıcı isteği 2026-10-11: "üstte video/resim, altta
  /// not — görseli sürükleyerek"): basılı tutup sürüklenen görsel ekranın
  /// TEPESİNE (sayfanın görünen üst kenarına) bırakılınca çağrılır; görsel
  /// sayfadan kalkar, notun üstündeki sabit bölmeye geçer. null = kapalı.
  final ValueChanged<Attachment>? onPinTop;

  /// Sürüklenen görsel sabitleme bölgesine girdi/çıktı — editör o sırada
  /// ekranın tepesinde "Bırak: üste sabitle" şeridini gösterir.
  final ValueChanged<bool>? onPinHover;

  /// Bir görsel taşınmaya başladı (true) / bıraktı (false). Editör taşıma
  /// boyunca tepede hedef şeridi gösterir — sabitleme jesti görünür olsun,
  /// "Bırak: üste sabitle" etiketi de yalnız o sırada ekran okuyucuya
  /// girsin (F13.6).
  final ValueChanged<bool>? onPinDrag;

  /// Görünüm anahtarı (Sabit / Yüzen / Balonlu — bkz. view_mode_switch.dart)
  /// seçili ekin araç panelinde; null ise anahtar çizilmez.
  final void Function(Attachment, AttachmentView)? onViewChange;

  /// Görünüm anahtarının yanındaki "Yazıya göm" (bkz.
  /// [AttachmentViewSwitch.onEmbed]); null ise düğme çizilmez.
  final ValueChanged<Attachment>? onEmbed;

  /// Boş alana dokununca (seçili görsel yokken) çağrılır — editör bununla
  /// gövde metnine odaklanır ("aşağıya dokun, yazmaya başla" davranışı).
  final VoidCallback? onTapEmpty;

  /// **YENİ EKİN YERLEŞİM İPUCU** (kullanıcı isteği 2026-11-03: "bir ek
  /// eklendiğinde nereye yerleşeceğinin sorulması — eklendiğinde ayar
  /// menüsünün gösterilmesi ve odaklanması, kişiye ipucu"). Az önce eklenen
  /// ekin kimliği: katman onu SEÇER (araç paneli açılır) ve paneldeki görünüm
  /// anahtarını (Sabit / Yüzen / Balonlu / Ek) parlayan çerçeve + tek satır
  /// açıklamayla öne çıkarır. Gösterilince [onPlacementHintShown].
  final String? placementHintId;
  final VoidCallback? onPlacementHintShown;

  @override
  State<NotePageCanvas> createState() => _NotePageCanvasState();
}

class _NotePageCanvasState extends State<NotePageCanvas> {
  void _redraw([VoidCallback? fn]) => setState(fn ?? () {});
  String? _selectedId;

  /// Yerleşim ipucu gösterilen ek (bkz. [NotePageCanvas.placementHintId]);
  /// seçim değişince/düşünce kalkar.
  String? _hintId;

  /// Son işlenen ipucu kimliği — aynı ek için ikinci kez açılmasın.
  String? _hintHandled;

  /// Gömülü belgelerin kalem katmanı (2026-11-09: "gömülüyken yazdıklarım
  /// sayfaya gidiyor, PDF'e gitmiyor"). Yüzen düğme "kalem yazar" derken
  /// kalem belgenin ÜSTÜNE yazar; sayfa katmanı o kutuya dokunmaz
  /// ([InkExclusionZone]).
  final Map<String, InkController> _docInk = {};

  /// Denetleyiciye en son verilen / ondan en son gelen çizgi listesi
  /// (kimlik): çizgi kökü kurmadığından (F60.1) `widget.images` bayat
  /// kalabilir — yalnız DIŞARIDAN gelen yeni liste işlenir, yoksa tuvalin
  /// kendi kurulumu (ör. yüzen kalem düğmesi) çizgileri geri alırdı.
  final Map<String, List<InkStroke>> _docInkSeen = {};

  InkController? _docInkFor(Attachment a) {
    // Kalemsiz cihazda katman yok: basılı tutup seçme parmakta kalır.
    final policy = PenPolicy.resolve(
      surface: PenSurface.embeddedDoc,
      penMode: false,
      autoStylus: InkToolMemory.autoStylus,
      stylusEver: InkToolMemory.stylusEver,
      penOnly: InkToolMemory.penOnly,
    );
    if (!policy.layerActive) return null;
    // setEditing(true) (2026-11-10, cihazda doğrulandı): eksikken katman
    // `IgnorePointer` ile kalemi de yok sayıyordu — gömülü PDF'e yazılmıyordu.
    final c = _docInk[a.id] ??= InkController(
      initial: a.ink,
      onChanged: (strokes) {
        // En güncel ek kaydı üzerine yazılır (sayfa çevrildi, balon eklendi).
        final live = widget.images.where((i) => i.id == a.id).firstOrNull;
        // `_docInkSeen` burada güncellenmez: kök kurulmadığı için elimizdeki
        // ek ESKİ listeyi tutar; ona çekilen kayıt bir sonraki çizimde eski
        // listeyi geri yazıp çizgileri siliyordu (bkz. PinnedMediaPane
        // `_inkFor`, kullanıcı bulgusu 2026-11-13).
        (widget.onInkChanged ?? widget.onChanged)(
          (live ?? a).copyWith(ink: strokes),
        );
      },
    )..setEditing(true);
    // Tam ekranda/geri alda değişen çizgiler (içerik aynıysa işlem yok).
    if (!identical(a.ink, _docInkSeen[a.id])) {
      _docInkSeen[a.id] = a.ink;
      if (!c.drawing) c.replace(a.ink);
    }
    c.allowedKinds = policy.allowedKinds;
    return c;
  }

  void _onStylusToggle() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _takePlacementHint();
    InkToolMemory.autoStylusListenable.addListener(_onStylusToggle);
  }

  @override
  void didUpdateWidget(NotePageCanvas old) {
    super.didUpdateWidget(old);
    _takePlacementHint();
  }

  void _takePlacementHint() {
    final id = widget.placementHintId;
    if (id == null || id == _hintHandled) return;
    if (!widget.images.any((a) => a.id == id)) return;
    _hintHandled = id;
    // Kurulum/güncelleme sırasında: setState değil doğrudan yazılır (bu
    // karenin build'i zaten gelecek).
    _selectedId = id;
    _hintId = id;
    final shown = widget.onPlacementHintShown;
    if (shown != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => shown());
    }
  }

  /// Seçili ekin araç paneli. "Dışarıya dokunuldu mu" kararı panelin
  /// GERÇEK dikdörtgeninden verilir (bkz. build'deki Listener).
  ///
  /// KÖK NEDEN (kullanıcı bulgusu 2026-10-16, ekran görüntüsü: "sil, 3 nokta
  /// vs basılmıyor"): panelin alanı sabit 64 dp sayılıyordu; görünüm anahtarı
  /// panelin ÜSTÜNE ikinci satır olarak gelince panel ~110 dp'ye uzadı ve alt
  /// satırdaki kaydırıcı/tam ekran/sil/⋮ "dışarısı" sayıldı — parmak inerken
  /// seçim düşüyor, panel kalkıyor, dokunuş boşa gidiyordu. Üst satır
  /// (anahtar) 64 dp'nin içinde kaldığı için o çalışıyordu.
  final _toolbarKey = GlobalKey(debugLabel: 'page-media-tools');

  /// Taşıma sırasındaki canlı sol/üst (dp); bırakınca kaydedilir.
  String? _moveId;
  double? _moveLeft;
  double? _moveTop;

  /// Sürüklemenin başladığı yer — parmağın toplam yer değiştirmesi buna
  /// eklenir (canlı değere eklemek hareketi katlardı).
  double? _moveOriginLeft;
  double? _moveOriginTop;

  /// Sayfada YERİNDE oynayan YouTube ekleri (kullanıcı bulgusu 2026-10-11:
  /// "basınca ayrı bir video sayfası açılıyor, direkt o alanda
  /// oynatılabilmeli"). Oynarken WebView dokunuşları yutar; kutunun
  /// köşesindeki "durdur" düğmesi oynatıcıyı kapatıp kutuyu yeniden
  /// taşınabilir yapar.
  final _playingWeb = <String>{};

  /// Tablonun CANLI oranı (kutunun ölçtüğü gerçek boy): tablo uzayınca kutu
  /// kök kurulmadan büyür (kayıt [NotePageCanvas.onTableChanged]'le gider).
  final _tableAspect = <String, double>{};

  void _setTableAspect(String id, double aspect) {
    final old = _tableAspect[id];
    if (old != null && (old - aspect).abs() < 0.0005) return;
    if (!mounted) return;
    setState(() => _tableAspect[id] = aspect);
    // Bantlar AYNI turda (kullanıcı bulgusu 2026-11-23: "tablo maddelerin
    // üstüne biniyor, satır eklerken titreme"): eskiden tuval önce kendini
    // kuruyor, bantları bir SONRAKİ karede bildiriyordu — tablo o arada
    // maddelerin üstüne taşıyordu. Kutu ve maddeler artık aynı karede kayar.
    final cb = widget.onFloats;
    if (cb == null || _cw <= 0) return;
    final next = _floatsFor(_cw);
    if (_lastFloats != null && sameFloatList(_lastFloats!, next)) return;
    _lastFloats = next;
    _floatTimer?.cancel();
    cb(next);
  }

  /// Parmak şu an sabitleme bölgesinde mi (bkz. [NotePageCanvas.onPinTop]).
  bool _inPinZone = false;

  /// Sabitleme bölgesi: kaydırılan sayfanın GÖRÜNEN üst kenarından bu kadar
  /// dp (parmağın ekrandaki yeri ölçülür — sayfa aşağı kaydırılmışken de
  /// ekranın tepesine sürüklemek yeter).
  static const double _pinZoneHeight = 56;

  void _setPinZone(bool value) {
    if (_inPinZone == value) return;
    _inPinZone = value;
    if (value) AppHaptics.heavy();
    widget.onPinHover?.call(value);
  }

  /// Görsel izin verilen en üst noktanın ([NotePageCanvas.topLimit]) bu
  /// kadar ötesine ZORLANINCA sabitleme bölgesi sayılır.
  static const double _pinOverPull = 36;

  /// Sabitleme bölgesi mi: parmak ekranın tepesinde YA DA görsel yukarı doğru
  /// başlığın üstüne zorlanıyor ([rawTop] = parmağın istediği, kırpılmamış
  /// üst kenar).
  ///
  /// Kullanıcı bulgusu 2026-10-11: "sabitlemek için görseli en üst ortaya
  /// getirmek gerekiyor, zor". Görsel başlığın altında DURDUĞU için (üste
  /// çıkamaz) parmak ekranın tepesine kadar gitmek zorundaydı. Artık nerede
  /// olursa olsun yukarı doğru biraz zorlamak yeter; yatay konum önemsiz.
  bool _pinZoneHit(Offset global, {required double rawTop}) {
    if (widget.onPinTop == null) return false;
    if (rawTop < widget.topLimit - _pinOverPull) return true;
    final scrollable = Scrollable.maybeOf(context);
    final box = scrollable?.context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return false;
    final top = box.localToGlobal(Offset.zero).dy;
    return global.dy < top + _pinZoneHeight;
  }

  /// Sürükleme bitince yeni konumu kaydeder ve canlı değerleri temizler.
  void _commitMove(Attachment img, double cw) {
    if (_moveId != img.id) return;
    widget.onPinDrag?.call(false);
    if (_inPinZone) {
      _setPinZone(false);
      setState(() {
        _moveId = null;
        _moveLeft = null;
        _moveTop = null;
        _moveOriginLeft = null;
        _moveOriginTop = null;
        _guides = const [];
        _selectedId = null;
      });
      widget.onPinTop?.call(img);
      return;
    }
    final nl = _moveLeft;
    final nt = _moveTop;
    if (nl != null && nt != null) {
      widget.onChanged(img.copyWith(x: nl / cw, pageY: nt));
    }
    setState(() {
      _moveId = null;
      _moveLeft = null;
      _moveTop = null;
      _moveOriginLeft = null;
      _moveOriginTop = null;
      _guides = const [];
    });
  }

  /// Boyutlandırma sırasındaki canlı genişlik oranı; bırakınca kaydedilir.
  String? _resizeId;
  double? _resizeWFrac;

  /// Parmağın YAPIŞMA UYGULANMAMIŞ genişliği. Kılavuza oturan değer geri
  /// beslenirse yapışma hareketi "yiyor": parmak ilerlerken genişlik aynı
  /// kilitli değerden hesaplandığı için görsel kılavuzdan bir türlü
  /// kopamıyordu. Ham değer ayrı birikir, ekrana yapışmış hâli çizilir.
  double? _resizeRawFrac;

  /// Taşıma/boyutlandırma sırasında çizilen hizalama çizgileri.
  List<AlignGuide> _guides = const [];

  /// Son yerleşimde ölçülen sayfa genişliği (dp) — çoklu seçim çubuğu gibi
  /// LayoutBuilder dışında kalan yerler oranları buradan çevirir.
  double _cw = 0;

  /// Konumu yazılmamış görsellerin bu karede hesaplanan yerleri (ek kimliği →
  /// sol/üst, dp). Her yerleşimde bir kez kurulur; [_resolve] buradan okur.
  final _autoSlots = <String, ({double left, double top})>{};

  static const double _minWidthFrac = 0.15;

  /// Çoklu seçim çubuğundaki düğmelerin sıkıştırması: altı simge ve seçim
  /// sayacı 360 dp'lik bir ekrana yan yana sığmalı.
  static const _kBarDensity = VisualDensity(horizontal: -4, vertical: -2);

  void _select(String id) => setState(() {
    _selectedId = _selectedId == id ? null : id;
    _hintId = null;
  });

  // ── AÇIKLAMA ────────────────────────────────────────────────────────────
  /// Açıklaması yerinde düzenlenen görsel (null = yok) ve yazılan taslak:
  /// taslak satır atladıkça bant uzar, metin aşağı akar.
  String? _hoverId;
  String? _captionEditId;
  String _captionDraft = '';
  final _captionMeasures = <String, _CaptionMeasure>{};

  /// Görselin ALTINDAKİ açıklama bandının yüksekliği (0 = açıklama yok).
  /// Sarma, sayfa boyu, çarpışma ve araç paneli bunu görselin boyuna ekler.
  double _captionBand(Attachment img, double w) {
    if (img.kind != AttachmentKind.image) return 0;
    final editing = _captionEditId == img.id;
    final text = editing ? _captionDraft : img.caption.trim();
    if (!editing && text.isEmpty) return 0;
    final measure = _captionMeasures.putIfAbsent(img.id, _CaptionMeasure.new);
    return kCaptionGap +
        measure.heightOf(text, w - 4, MediaQuery.textScalerOf(context)) +
        2;
  }

  void _startCaption(Attachment img) {
    AppHaptics.tick();
    setState(() {
      _selectedId = null;
      _captionEditId = img.id;
      _captionDraft = img.caption;
    });
  }

  void _draftCaption(String text) {
    final id = _captionEditId;
    if (id == null) return;
    final img = widget.images.where((a) => a.id == id).firstOrNull;
    if (img == null) return;
    final w = _sizeOf(img, _cw).w;
    final before = _captionBand(img, w);
    _captionDraft = text;
    // Yalnız satır sayısı değişince yeniden yerleşim (her harfte değil).
    if (_captionBand(img, w) != before) setState(() {});
  }

  void _commitCaption(Attachment img, String text) {
    final next = text.trim();
    setState(() {
      if (_captionEditId == img.id) _captionEditId = null;
    });
    final current = widget.images.where((a) => a.id == img.id).firstOrNull;
    if (current != null && current.caption != next) {
      widget.onChanged(current.copyWith(caption: next));
    }
  }

  Widget _caption(BuildContext context, Attachment img, double cw) {
    final r = _resolve(img, cw);
    final editing = _captionEditId == img.id;
    return Positioned(
      key: ValueKey('image-caption-${img.id}'),
      left: r.left + 2,
      top: r.top + r.h + kCaptionGap,
      width: (r.w - 4).clamp(1.0, cw),
      child: Opacity(
        opacity: _moveId == img.id ? 0.55 : 1,
        child: _ImageCaption(
          caption: img.caption,
          editing: editing,
          onStartEdit: () => _startCaption(img),
          onDraft: _draftCaption,
          onCommit: (text) => _commitCaption(img, text),
        ),
      ),
    );
  }

  void _deselect() {
    if (_selectedId != null) {
      setState(() {
        _selectedId = null;
        _hintId = null;
      });
    }
  }

  // ── ÇOKLU SEÇİM ─────────────────────────────────────────────────────────
  // Sayfadaki görseller tek tek seçilip ⋮ menüsünden kopyalanabiliyordu ama
  // ikisini birden almanın yolu yoktu (kullanıcı isteği 2026-08-09).
  // "Görselleri seç" tek görselin araç panelinden açılır; sonrasında her
  // dokunuş bir görseli işaretler, işlem çubuğu ekranın dibinde durur.

  /// Çoklu seçim açık mı ve hangi ekler işaretli.
  final _multi = <String>{};
  bool _multiMode = false;

  /// İşlem çubuğunu ekranın DİBİNE demirleyen katman (madde listesindeki
  /// seçim çubuğuyla aynı desen — sayfa nerede olursa olsun görünür).
  final _multiBar = OverlayPortalController();

  void _startMulti(String id) {
    setState(() {
      _multiMode = true;
      _selectedId = null;
      _multi
        ..clear()
        ..add(id);
    });
    if (!_multiBar.isShowing) _multiBar.show();
  }

  void _toggleMulti(String id) {
    setState(() {
      if (!_multi.remove(id)) _multi.add(id);
    });
    if (_multi.isEmpty) _endMulti();
  }

  void _endMulti() {
    setState(() {
      _multiMode = false;
      _multi.clear();
    });
    if (_multiBar.isShowing) _multiBar.hide();
  }

  /// İşaretli ekler — sayfa sırasıyla.
  List<Attachment> get _multiSelected => [
    for (final img in widget.images)
      if (_multi.contains(img.id)) img,
  ];

  /// Toplu düzen değişikliğini yazar: varsa tek yazım, yoksa tek tek.

  /// Büyük önizlemede duran görselin kimliği (null = kapalı).
  ///
  /// Önizleme SAYFA DÜZENİNE dokunmaz: görselin `displayWidth`/konumu
  /// değişmez, dolayısıyla metnin sarması da değişmez. Yalnızca üstte,
  /// geçici bir katmanda büyük çizilir.
  String? _previewId;

  /// Önizlemedeki yatay kaydırma denetleyicisi (kullanıcı isteği 2026-09-05:
  /// "birden fazla görsel olduğunda tam ekran ve ön izlemede kaydırarak
  /// diğer görsele geçme olsun"). Yalnız önizleme AÇIKKEN yaşar.
  PageController? _previewPages;

  void _togglePreview(String id) {
    if (_previewId == id) {
      _closePreview();
      return;
    }
    final index = widget.images.indexWhere((a) => a.id == id);
    _previewPages?.dispose();
    _previewPages = PageController(initialPage: index < 0 ? 0 : index);
    setState(() => _previewId = id);
  }

  void _closePreview() {
    if (_previewId == null) return;
    _previewPages?.dispose();
    _previewPages = null;
    setState(() => _previewId = null);
  }

  @override
  void dispose() {
    InkToolMemory.autoStylusListenable.removeListener(_onStylusToggle);
    for (final c in _docInk.values) {
      c.dispose();
    }
    _previewPages?.dispose();
    _floatTimer?.cancel();
    super.dispose();
  }

  Attachment? _previewOf(List<Attachment> images) {
    final id = _previewId;
    if (id == null) return null;
    for (final img in images) {
      if (img.id == id) return img;
    }
    return null;
  }

  /// Görselin en-boy oranı (bilinmiyorsa kare sayılır).
  ///
  /// PDF kutusunda GÖRÜNTÜ döndürmesi de hesaba katılır: 90°/270°'de sayfa
  /// yan yatar, kutu da onunla birlikte yatmalı (bkz. [pdfBoxAspect]).

  void _reportFloats(double cw) {
    final cb = widget.onFloats;
    if (cb == null) return;
    final next = _floatsFor(cw);
    // SÜRÜKLERKEN/BOYUTLANDIRIRKEN bantlar parmak DURUNCA bildirilir.
    //
    // KÖK NEDEN (kullanıcı 2026-10-16: "görseller sürüklenirken aşırı
    // kasma"): taşımanın HER KARESİ yeni bant üretiyor, bildirim de editörün
    // TAMAMINI `setState` ile yeniden kuruyor ve gövde metnini baştan
    // sarıyordu — saniyede 60 kez tam editör build'i + sarma planı. Taşınan
    // görsel zaten yarı saydam (altındaki metin okunur); metin parmak bir an
    // durunca ya da bırakınca yerine akar.
    final live = _moveId != null || _resizeId != null;
    if (_lastFloats != null && sameFloatList(_lastFloats!, next)) {
      // Bırakıldı ama son bant hâlâ zamanlayıcıda bekliyor: hemen ver.
      if (!live && (_floatTimer?.isActive ?? false)) {
        _floatTimer!.cancel();
        _deliverFloats(cb, next);
      }
      return;
    }
    _lastFloats = next;
    _floatTimer?.cancel();
    if (live) {
      _floatTimer = Timer(const Duration(milliseconds: 160), () {
        if (mounted) cb(next);
      });
      return;
    }
    _deliverFloats(cb, next);
  }

  /// Ölçüm build sırasında yapılır; bildirimi kare sonuna erteleriz ki
  /// gövde denetleyicisi build içinde setState tetiklemesin.
  void _deliverFloats(ValueChanged<List<FloatBox>> cb, List<FloatBox> next) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) cb(next);
    });
  }

  List<FloatBox>? _lastFloats;
  Timer? _floatTimer;

  /// Fareyle üstüne gelince köşede ⋮ (masaüstü, F40.8): seçmeden aynı menü.
  Widget _hoverMenu(Attachment img, bool selected, Widget box) => MouseRegion(
    onEnter: (_) {
      if (_hoverId != img.id) setState(() => _hoverId = img.id);
    },
    onExit: (_) {
      if (_hoverId == img.id) setState(() => _hoverId = null);
    },
    child: Stack(
      fit: StackFit.expand,
      children: [
        box,
        if (_hoverId == img.id && !selected && !_multiMode)
          PositionedDirectional(
            end: 4,
            top: 4,
            child: Builder(
              builder: (context) => IconButton.filledTonal(
                key: const ValueKey('page-image-hover-menu'),
                tooltip: context.l10n.attachmentActions,
                visualDensity: VisualDensity.compact,
                iconSize: AppIconSize.s,
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  final at = (context.findRenderObject()! as RenderBox)
                      .localToGlobal(Offset.zero);
                  unawaited(_contextMenu(img, at));
                },
              ),
            ),
          ),
      ],
    ),
  );

  Future<void> _contextMenu(Attachment img, Offset global) async {
    final web = img.isWebVideo;
    final action = await showAttachmentContextMenu(
      context,
      global,
      attachmentActionsFor(
        img,
        AttachmentSurface.contextMenu,
        AttachmentCaps(
          open: img.kind != AttachmentKind.audio,
          addText: true,
          caption: true,
          transcribe:
              widget.onTranscribe != null &&
              (img.kind == AttachmentKind.audio ||
                  img.kind == AttachmentKind.video ||
                  img.kind == AttachmentKind.image),
          extractText: widget.onExtractText != null,
          videoToNote: widget.onVideoToNote != null,
          copy: widget.onCopy != null,
          share: widget.onShare != null,
          saveAs: widget.onSaveAs != null && !web,
          remove: true,
        ),
      ),
    );
    if (action == null || !mounted) return;
    switch (action) {
      case AttachmentAction.open:
        _openViewer(img);
      case AttachmentAction.addText:
        _openViewer(img, startText: true);
      case AttachmentAction.caption:
        _startCaption(img);
      case AttachmentAction.transcribe:
        widget.onTranscribe?.call(img);
      case AttachmentAction.extractText:
        final ocr = widget.onExtractText?.call(img);
        if (ocr != null) unawaited(ocr);
      case AttachmentAction.videoToNote:
        widget.onVideoToNote?.call(img);
      case AttachmentAction.copy || AttachmentAction.copyLink:
        widget.onCopy?.call(img);
      case AttachmentAction.share:
        widget.onShare?.call(img);
      case AttachmentAction.saveAs:
        widget.onSaveAs?.call(img);
      case AttachmentAction.remove:
        widget.onRemove(img);
      case _:
        break;
    }
  }

  void _openViewer(Attachment img, {bool startText = false}) {
    // Metnin "tam ekranı" okuma ekranıdır; sesin ayrı ekranı yok (kart
    // kendisi oynatıcı).
    if (img.kind == AttachmentKind.text) {
      widget.onTranscribe?.call(img);
      return;
    }
    if (img.kind == AttachmentKind.audio) return;
    if (img.kind == AttachmentKind.pdf) {
      Navigator.of(context).push(
        MediaRoute<void>(
          builder: (_) => PdfViewerScreen(
            attachment: img,
            initialPage: img.pdfPage,
            onPageChanged: (p) => widget.onChanged(img.copyWith(pdfPage: p)),
            onChanged: widget.onChanged,
            startText: startText,
          ),
        ),
      );
      return;
    }
    if (img.kind == AttachmentKind.video) {
      Navigator.of(context).push(
        MediaRoute<void>(builder: (_) => VideoViewerScreen(attachment: img)),
      );
      return;
    }
    if (img.kind == AttachmentKind.slide) {
      Navigator.of(context).push(
        MediaRoute<void>(
          builder: (_) =>
              SlideViewerScreen(attachment: img, onChanged: widget.onChanged),
        ),
      );
      return;
    }
    openImageViewer(
      context,
      img,
      widget.onChanged,
      onCrop: widget.onCrop,
      onRotate: widget.onRotate,
      gallery: widget.images,
      startText: startText,
    );
  }

  /// Ekin türüne göre sayfa kutusu içeriği: görsele [_ImageBox], videoya
  /// yerinde oynayan [_VideoBox]. Videonun doğal boyutu ekte yoksa ilk
  /// çözümde kalıcılaştırılır (oran 1:1 varsayılanında kalmasın).
  Widget _boxFor(Attachment a, {BoxFit fit = BoxFit.cover}) {
    // TABLO (2026-11-23): hücreleri sayfada yazılan kutu; büyük önizlemede
    // salt görüntü.
    if (isNoteTable(a)) {
      return TablePageBox(
        attachment: a,
        onChanged: widget.onTableChanged ?? widget.onChanged,
        onRemove: () => widget.onRemove(a),
        onAspect: fit == BoxFit.cover
            ? (aspect) => _setTableAspect(a.id, aspect)
            : null,
        editable: fit == BoxFit.cover && !widget.readOnly,
      );
    }
    // SAYFAYA GÖMÜLÜ METİN (2026-10-17): sayfası çevrilen kâğıt kutusu; ⤢
    // okuma ekranını açar (bkz. TextPageBox).
    if (a.kind == AttachmentKind.text) {
      return TextPageBox(
        attachment: a,
        onChanged: widget.onChanged,
        swipeToTurn: fit == BoxFit.cover,
        onOpen: widget.onTranscribe == null
            ? null
            : () => widget.onTranscribe!(a),
      );
    }
    // SAYFADAKİ SES: oynatıcı kartı (zaman damgaları onu sarar).
    if (a.kind == AttachmentKind.audio) {
      return AudioCardBox(attachment: a, noteAtButton: fit == BoxFit.cover);
    }
    // SAYFAYA GÖMÜLÜ PDF: görselin kutusunun belge karşılığı — sayfası
    // çevrilebilir, yer imi konur, tam ekrana geçer (bkz. [PdfPageBox]).
    if (a.kind == AttachmentKind.pdf) {
      return WebDriveGate(
        attachment: a,
        builder: (_, shown) => InkExclusionZone(
          enabled: InkToolMemory.autoStylus,
          child: PdfPageBox(
            attachment: shown,
            onChanged: widget.onChanged,
            // Büyük önizlemede de sayfa çevrilebilir (önizleme okumak için
            // açılıyor) ama YATAY KAYDIRMA orada nottaki diğer eke geçiyor;
            // sayfa yalnız çubuğun oklarıyla değişir.
            swipeToTurn: fit == BoxFit.cover,
            ink: _docInkFor(shown),
          ),
        ),
      );
    }
    // SAYFAYA GÖMÜLÜ SUNUM (2026-10-17): slaytı çevrilebilen kutu.
    if (a.kind == AttachmentKind.slide) {
      return WebDriveGate(
        attachment: a,
        builder: (_, shown) => SlidePageBox(
          attachment: shown,
          onChanged: widget.onChanged,
          swipeToTurn: fit == BoxFit.cover,
        ),
      );
    }
    return NoteMediaBox(
      attachment: a,
      fit: fit,
      inlineWebVideo: true,
      noteAtButton: fit == BoxFit.cover,
      showWebTitle: fit == BoxFit.contain || _selectedId == a.id,
      webPlaying: _playingWeb.contains(a.id),
      onWebPlay: () => setState(() => _playingWeb.add(a.id)),
      onSize: (a.width == null || a.height == null)
          ? (s) => widget.onChanged(
              a.copyWith(width: s.width.round(), height: s.height.round()),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Seçili ek sayfadan ayrıldıysa (sabitlendi, balonluya alındı, silindi)
    // seçim de düşer — yoksa görünmeyen bir seçim geri tuşunu bir kez
    // yutardı (bkz. aşağıdaki PopScope).
    final selected0 = _selectedId;
    if (selected0 != null && !widget.images.any((a) => a.id == selected0)) {
      _selectedId = null;
    }
    if (widget.images.isEmpty) {
      // Son görsel silinince bantların BOŞALDIĞI da bildirilmeli — yoksa
      // metin, artık var olmayan bir görselin etrafından akmaya devam eder.
      _reportFloats(0);
      // Görsel yokken katmanın görsel maliyeti olmasın; dokun-odaklan kalır.
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: widget.onTapEmpty,
        child: PageMinHeight(minHeight: widget.minHeight, child: widget.child),
      );
    }
    // Geri tuşu önce ÖNİZLEMEYİ, sonra görsel seçimini kapatır; not ancak
    // ikisi de kapalıyken kapanır (madde: "geri butonu direk anasayfaya
    // dönmesin bu tür durumlarda").
    return PopScope(
      canPop: _previewId == null && _selectedId == null && !_multiMode,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_previewId != null) {
          _closePreview();
        } else if (_multiMode) {
          _endMulti();
        } else {
          _deselect();
        }
      },
      child: OverlayPortal(
        controller: _multiBar,
        overlayChildBuilder: _multiToolbar,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cw = constraints.maxWidth;
            // Otomatik yerleşim bu karede BİR kez kurulur; aşağıdaki bütün
            // _resolve çağrıları aynı sonucu okur.
            _computeAutoSlots(cw);
            _reportFloats(cw);
            // Sayfa en alttaki görseli (+ araç çubuğu payı) kapsayacak kadar uzar.
            var maxBottom = 0.0;
            for (final img in widget.images) {
              final r = _resolve(img, cw);
              // Seçiliyken altında iki satırlık araç paneli durur; sayfa onu
              // da kapsamalı (yoksa dipteki görselin paneli sayfadan taşar ve
              // taşan kısmı dokunuş almaz).
              final pad = img.id == _selectedId ? _toolbarEstimate + 12 : 72;
              final bottom = r.top + r.h + _captionBand(img, r.w) + pad;
              if (bottom > maxBottom) maxBottom = bottom;
            }
            final selected = _selectedId;
            Attachment? selectedImg;
            for (final img in widget.images) {
              if (img.id == selected) selectedImg = img;
            }
            final previewImg = _previewOf(widget.images);
            // Görsel araç paneli, görselin/panelin DIŞINA düşen her dokunuşta
            // kapanır. Alttaki GestureDetector yalnız "boş alan" dokunuşlarını
            // görüyordu: metin alanına dokunmak alanın kendisine gittiğinden
            // panel açık kalıyordu ("resmin üzerine tıklanmayınca panel
            // kapanmıyor"). Listener jestleri YUTMAZ — dokunuş hem paneli
            // kapatır hem hedefine (ör. metin alanına odak) gider.
            final imgForDismiss = selectedImg;
            final content = Stack(
              clipBehavior: Clip.none,
              children: [
                // İçerik: boş alana dokununca önce seçim kalkar, seçim yoksa
                // gövdeye odaklanılır (dokunuş metin alanına da düşer).
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    if (_selectedId != null) {
                      _deselect();
                    } else {
                      widget.onTapEmpty?.call();
                    }
                  },
                  child: PageMinHeight(
                    minHeight: maxBottom > widget.minHeight
                        ? maxBottom
                        : widget.minHeight,
                    child: widget.child,
                  ),
                ),
                // İpucu görsellerin ALTINDA çizilir: zaten kesişmeyecek yere
                // konuyor, dokunuşu da yutmamalı (boş alana dokun → gövdeye odak).
                if (widget.hint != null)
                  Builder(
                    builder: (context) {
                      // İpucu metnin ilk satırıyla AYNI yere oturur: görselin
                      // yanında yer varsa yanına, yoksa altına (bkz.
                      // [hintPlacement]).
                      final place = _hintPlacement(cw);
                      return PositionedDirectional(
                        start: place.left,
                        end: widget.textLeft,
                        top: place.top,
                        child: IgnorePointer(child: widget.hint!),
                      );
                    },
                  ),
                for (final img in widget.images) _positioned(context, img, cw),
                // Açıklamalar görselin hemen altında (sayfa düzeninin parçası).
                for (final img in widget.images)
                  if (_captionBand(img, _resolve(img, cw).w) > 0)
                    _caption(context, img, cw),
                // YERİNDE OYNAYAN YouTube'un "durdur" düğmesi kutunun SOL ÜST
                // köşesinin DIŞINDA (oynatıcının kendi düğmelerini örtmesin);
                // tuvalin kendi katmanında ki dokunuş kutunun sınırına takılmasın.
                for (final img in widget.images)
                  if (_playingWeb.contains(img.id))
                    Builder(
                      builder: (context) {
                        final r = _resolve(img, cw);
                        return Positioned(
                          left: r.left - 14,
                          top: r.top - 14,
                          child: Material(
                            color: Theme.of(context).colorScheme.inverseSurface,
                            shape: const CircleBorder(),
                            elevation: 2,
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () =>
                                  setState(() => _playingWeb.remove(img.id)),
                              child: Padding(
                                padding: const EdgeInsets.all(5),
                                child: Icon(
                                  Icons.close,
                                  size: AppIconSize.xs,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onInverseSurface,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                // Oynayan YouTube'un DENETİMİ (±10 sn, oynat/durdur) kutunun
                // HEMEN ALTINDA, dışında — oynatıcının kendi çubuğunu örtmez.
                for (final img in widget.images)
                  if (_playingWeb.contains(img.id))
                    Builder(
                      builder: (context) {
                        final r = _resolve(img, cw);
                        if (r.w < 150) return const SizedBox.shrink();
                        return Positioned(
                          left: r.left,
                          width: r.w,
                          top: r.top + r.h + 4,
                          child: Center(
                            child: Material(
                              key: ValueKey('web-video-controls-${img.id}'),
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHigh,
                              elevation: 2,
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: VideoTransportControls(
                                  video: img,
                                  iconSize: AppIconSize.m,
                                  showTime: r.w >= 260,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                // Oynayan YouTube'un "Bu ana not al" düğmesi SAĞ ÜST köşenin
                // dışında (durdur düğmesinin simetriği) — oynatıcının kendi
                // düğmelerini örtmez.
                for (final img in widget.images)
                  if (_playingWeb.contains(img.id))
                    Builder(
                      builder: (context) {
                        final hub = VideoHubScope.maybeOf(context);
                        if (hub == null || hub.onNoteAt == null) {
                          return const SizedBox.shrink();
                        }
                        final r = _resolve(img, cw);
                        return Positioned(
                          right: (cw - r.left - r.w - 10).clamp(0.0, cw),
                          top: r.top - 14,
                          child: _NoteAtChip(
                            onTap: () {
                              final source = hub.sourceFor(img.id);
                              if (source != null) hub.noteAt(source);
                            },
                          ),
                        );
                      },
                    ),
                // Hizalama kılavuzları görsellerin ÜSTÜNDE: taşınan görsel
                // çizgiyi kapatırsa hizalama görünmez olurdu.
                if (_guides.isNotEmpty)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _GuidePainter(
                          guides: _guides,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                if (selectedImg != null) _toolbar(context, selectedImg, cw),
                // Büyük önizleme en üstte: sayfa ölçüleriyle oynamadığı için
                // metnin sarması olduğu gibi kalır.
                if (previewImg != null) _preview(context, previewImg, cw),
              ],
            );
            // Listener HER ZAMAN ağaçta (seçim yokken boş geçer).
            //
            // KÖK NEDEN (2026-10-11, "görseli sürükleyerek üste sabitle"
            // üzerinde çalışırken bulundu): Listener eskiden yalnız seçim
            // VARKEN sarılıyordu. Seçili olmayan görsele basılı tutunca
            // `onLongPressStart` seçimi açıyor → içerik bu karede Listener'a
            // sarılıyor → Stack'in altındaki bütün ağaç (görselin jest
            // tanıyıcısı dahil) yeniden kuruluyor ve süren sürükleme kopuyordu:
            // "basılı tut, sürükle" ancak görsel ÖNCEDEN seçiliyse çalışıyordu.
            Rect? imageRect;
            Rect? toolbarRect;
            if (imgForDismiss != null) {
              final r = _resolve(imgForDismiss, cw);
              // Tutamaklar köşelerden taşar, panel görselin altında tam genişlik
              // bir bant: ikisinin de dışı "dışarısı" sayılır.
              imageRect = Rect.fromLTWH(
                r.left - 24,
                r.top - 24,
                r.w + 48,
                r.h + 48,
              );
              // Yedek: panel henüz çizilmediyse (ilk kare) tahmini bant.
              toolbarRect = Rect.fromLTWH(
                0,
                r.top + r.h + _captionBand(imgForDismiss, r.w) + 6,
                cw,
                _toolbarEstimate,
              );
            }
            return Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (event) {
                if (imageRect == null || toolbarRect == null) return;
                final p = event.localPosition;
                if (imageRect.contains(p)) return;
                if (_toolbarHit(event.position) ?? toolbarRect.contains(p)) {
                  return;
                }
                _deselect();
              },
              child: content,
            );
          },
        ),
      ),
    );
  }

  /// Araç panelinin tahmini yüksekliği (iki satır: görünüm + araçlar).
  static const double _toolbarEstimate = 124;

  /// [global] noktası araç panelinin ÇİZİLMİŞ dikdörtgeninde mi; panel
  /// ölçülemiyorsa null (çağıran tahmini banda bakar).
  bool? _toolbarHit(Offset global) {
    final box = _toolbarKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return null;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    // Kenarda birkaç dp pay: parmak panelin çizgisine denk gelirse de içeride.
    return rect.inflate(6).contains(global);
  }

  Widget _toolbarBody(
    BuildContext context,
    Attachment img,
    double wFrac,
    bool isVideo,
    bool isPdf,
    bool isPlain,
    bool wide,
  ) {
    return _ImageTools(
      wide: wide,
      attachment: img,
      key: _toolbarKey,
      placementHint: _hintId == img.id,
      wFrac: wFrac,
      minWidthFrac: _minWidthFrac,
      onWidthChanged: (v) => setState(() {
        _resizeId = img.id;
        _resizeWFrac = v;
      }),
      onWidthEnd: (v) {
        widget.onChanged(img.copyWith(displayWidth: v));
        setState(() {
          _resizeId = null;
          _resizeWFrac = null;
        });
      },
      onExtractText: widget.onExtractText == null || isVideo || isPdf || isPlain
          ? null
          : () => widget.onExtractText!(img),
      // ÜSTÜNE YAZI (2026-11-09): görsel ve PDF'te tek dokunuş.
      onAddText:
          img.kind == AttachmentKind.image || img.kind == AttachmentKind.pdf
          ? () => _openViewer(img, startText: true)
          : null,
      // YouTube ekinin kopyası BAĞLANTISIDIR (kullanıcı bulgusu
      // 2026-10-11: "videoların bağlantı adresi kopyalanmıyor" — menüde
      // video için kopyalama hiç yoktu).
      onCopy: widget.onCopy == null || (isVideo && !img.isWebVideo)
          ? null
          : () => widget.onCopy!(img),
      onOpenExternal: img.isWebVideo
          ? () => launchUrl(
              Uri.parse(img.webUrl),
              mode: LaunchMode.externalApplication,
            )
          : null,
      onSelectMany: widget.onCopyMany == null || widget.images.length < 2
          ? null
          : () => _startMulti(img.id),
      // YouTube ekinin dosyası yok — videodan not çıkarmak mümkün değil.
      onVideoToNote: widget.onVideoToNote == null || !isVideo || img.isWebVideo
          ? null
          : () => widget.onVideoToNote!(img),
      onTranscribe:
          widget.onTranscribe == null ||
              isPdf ||
              img.kind == AttachmentKind.text
          ? null
          : () => widget.onTranscribe!(img),
      // GÖRÜNÜM ANAHTARI panelin üst satırında: Sabit / Yüzen / Balonlu
      // (eskiden menüde "Üste sabitle", PDF'te "Balonlu görünüm").
      viewSwitch: widget.onViewChange == null || availableViews(img).length < 2
          ? null
          : AttachmentViewSwitch(
              current: AttachmentView.floating,
              available: availableViews(img),
              onChanged: (view) {
                _deselect();
                widget.onViewChange!(img, view);
              },
              onEmbed: widget.onEmbed == null
                  ? null
                  : () {
                      _deselect();
                      widget.onEmbed!(img);
                    },
            ),
      onSaveAs: widget.onSaveAs == null || img.isWebVideo
          ? null
          : () => widget.onSaveAs!(img),
      onShare: widget.onShare == null ? null : () => widget.onShare!(img),
      onRename: widget.onRename == null ? null : () => widget.onRename!(img),
      onAlign: () {
        final curX = img.x ?? 0.0;
        final center = ((1.0 - wFrac) / 2).clamp(0.0, 1.0);
        final right = (1.0 - wFrac).clamp(0.0, 1.0);
        final nextX = curX < 0.12
            ? center
            : curX < right - 0.08
            ? right
            : 0.0;
        widget.onChanged(img.copyWith(x: nextX));
      },
      onFullscreen: img.kind == AttachmentKind.audio
          ? null
          : () => _openViewer(img),
      // Görsele açıklama (altyazı) — yalnız görselde.
      onCaption: img.kind == AttachmentKind.image
          ? () => _startCaption(img)
          : null,
      hasCaption: img.caption.isNotEmpty,
      onRemove: () => widget.onRemove(img),
    );
  }
}
