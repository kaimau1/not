part of 'note_editor_screen.dart';

mixin _NoteEditorFields on ConsumerState<NoteEditorScreen> {
  /// Salt okunur: yalnız okuma yetkili paylaşım (`?ro=1`) YA DA bu sürüm
  /// eski kalmış (F1.5 — `config/app.minClient`): eski istemci notu
  /// kaydedip yeni sürümün verisini bozmasın.
  bool get _readOnly => widget.readOnly || ref.read(updateRequiredProvider);

  /// Açık not (P20 F64.2): dar dinleyiciler ([NoteSlice]) bunu dinler.
  final _noteN = LateSafeValue<Note?>(null);

  Note? get _note => _noteN.value;
  set _note(Note? v) => _noteN.value = v;

  void Function() _stopFileDrops = () {};

  /// (geri alınabilir, yinelenebilir) — üst çubuktaki düğmeler bunu dinler;
  /// yığın değişince kök kurulmaz (P20 M3).
  final _undoN = LateSafeValue<(bool, bool)>((false, false));

  /// En son çizilen ek sayısı — artışı yakalamak için (silme yanıp sönmez).
  int? _lastAttachmentCount;

  /// Akıllı liste üst şeridi önbelleği: düz madde ekle/sil işlemlerinde
  /// (özellikle `ListMode.general`) başlık ağacı yeniden kurulmaz (S50 bütçesi).
  (Object, Widget)? _modeHeaderCache;

  /// Ek sayısı arttıysa rozeti iki kez yakar.
  /// Denetleyicilerin en son beslendiği not ve tema parlaklığı (bkz.
  /// build'deki besleme bloğu).
  Note? _fedNote;

  bool? _fedDark;

  /// LİSTE notunda serbest metin alanı açık mı? (Kullanıcı isteği: "liste
  /// notlarına metin notu ekleme seçeneği lazım.") Notun gövdesi doluysa alan
  /// zaten görünür; bu bayrak, gövde BOŞKEN alanı açık tutar.
  bool _listBodyOpen = false;

  /// Ek şeridi BU ekranda açıldı mı (alt çubuktaki ataç / şeridin başlığı)?
  /// Öyleyse geri önce şeridi kapatır ([BackCloses]). Kalıcı tercihle zaten
  /// açık gelen şerit geri tuşunu yakalamaz — her not çıkışı iki geri
  /// istemesin.
  bool _stripOpenedHere = false;

  /// Not makul bir sürede gelmedi (bkz. initState'teki koruma).
  bool _loadFailed = false;

  /// Bu editör kilitli not açıkken FLAG_SECURE tutuyor mu (`AppLockSecureScope`).
  bool _secureHeld = false;

  Timer? _loadGuard;

  /// Başlık da biçimlendirilebilir (kullanıcı: "sadece başlığın boyutunu
  /// ayarlayamıyorum, tüm sayfa büyüyor"): seçili başlık metnine boyut,
  /// şeffaflık, kalın... uygulanabilsin diye gövdeyle AYNI denetleyiciyi
  /// kullanır. Sarma çapası yok (başlıkta yüzen görsel olmaz), yalnız biçim
  /// işaretlerinin görünmez çizimi ve imleç düzeltmesi için gerekli.
  final _titleController = WrapTextController();

  final _titleFocus = FocusNode();

  /// Gövde: kayan görsellerin etrafından akan metin için özel denetleyici.
  /// `.text` çapa karakterleri içerebilir — nota giden gövde her zaman
  /// `.logicalText` üzerinden okunur (bkz. text_wrap.dart).
  final _bodyController = WrapTextController();

  final _bodyFieldKey = GlobalKey();

  final _bodyFocus = FocusNode();

  /// Gövdeye yapılan son dokunuşun konumu (etiket önizlemesi, bkz.
  /// [_tappedEmbed]).
  final _bodyTapPoint = TapPointTracker();

  /// Gömülü yazıların çip görünümü (etiket adı → türün simgesi/rengi);
  /// her `build`de nottan yeniden çıkarılır.
  Map<String, TagLook> _tagLooks = const {};

  /// KÖK NEDEN (ölçüldü): `dispose()` içinde `ref` kullanmak bu Riverpod
  /// sürümünde "Using ref when a widget is about to or has been unmounted is
  /// unsafe" hatası atar — atılan istisna yüzünden editörden ÇIKARKEN çalışan
  /// her şey sessizce ölüyordu: boş notun silinmesi, otomatik etiket/başlık,
  /// sürmekte olan sesli notun kaydı. Bu yüzden gereken bağımlılıklar her
  /// build'de alanlara alınır; `dispose` yalnız bu alanları kullanır.
  NotesRepository? _notesRepo;

  AttachmentRepository? _attachmentRepo;

  /// Süren DOSYA işinin adı (kopyalama, yapıştırma, ek hazırlama).
  ///
  /// KÖK NEDEN (kullanıcı bulgusu 2026-08-10: "görüntü kopyalanırken veya
  /// başka bir şey yüklenirken sessizlik var, yüklenme dönencesi lazım"):
  /// pano işleri ancak BİTİNCE bir SnackBar gösteriyordu. Büyük bir görselin
  /// baytlarını okumak (bulut kopyasında: indirmek) saniyeler sürebiliyor ve o
  /// süre boyunca ekranda hiçbir iz yoktu — kullanıcı düğmeye basmadığını
  /// sanıp tekrar basıyordu.
  final _busyTaskN = ValueNotifier<String?>(null);

  /// (+) menüsünden gelen ve not yüklenmeden çalıştırılamayan açılış
  /// niyetleri; not gelir gelmez bir kez çalıştırılır.
  bool _pendingDraw = false;

  bool _pendingSeparateDrawing = false;

  bool _pendingVoice = false;

  bool _pendingDictation = false;

  bool _pendingVideo = false;

  bool _pendingPhoto = false;

  String? _pendingRevealItem;

  String? _pendingFind;

  bool _pendingScan = false;

  bool _pendingPdf = false;

  bool _pendingSlides = false;

  bool _pendingGalleryVideo = false;

  bool _pendingYouTube = false;

  bool _pendingTranscribe = false;

  bool _pendingAudioFile = false;

  /// Alışveriş kipinde reyon gruplama açık mı (yerel ValueNotifier: editör
  /// kökünü yeniden kurmaz).
  final _shopGroupedN = ValueNotifier<bool>(true);

  /// Proje kipinde 3 maddelik Odak Modu açık mı.
  final _projectFocusN = ValueNotifier<bool>(false);

  /// Proje kipinde elle seçilen odak madde kimlikleri (en çok 3).
  final _projectFocusIdsN = ValueNotifier<Set<String>>(const {});

  /// Genel kipte "Alışveriş/Rutin kipine geç?" önerisi kapatıldı mı.
  final _modeNudgeDismissedN = ValueNotifier<bool>(false);

  /// Kural 1: 24 saatliğine kapatılmış geçici hayalet öneri anahtarları (UI-only).
  final _ghostDismissedN = ValueNotifier<Set<String>>(const {});

  /// Yeni ek hazırlarken kullanılacak depo: paylaşılan notta SAHİBİN yolu.
  ///
  /// KÖK NEDEN (kullanıcı bulgusu 2026-10-17: "eklerin paylaşımında sorun",
  /// "web tarafında eksikler"): ek ekleyen yolların hepsi ana depoyu
  /// (`users/{BEN}/…`) kullanıyordu. Cihazda zararsızdı (önce yerel kopya,
  /// kuyruk sonra sahibin yoluna yükler) ama WEB'de `_store` baytları HEMEN
  /// Storage'a yazıyor — paylaşılan nota web'den eklenen dosya ekleyenin
  /// kendi yoluna gidiyor, not sahibi ve öbür ortak çalışanlar onu hiç
  /// okuyamıyordu (kural reddi). Her çağrıda taze okunur: Drive bağlanınca
  /// ana depo değişiyor.
  AttachmentRepository? get _attachments {
    final base = ref.read(attachmentRepositoryProvider);
    final owner = widget.ownerId;
    return owner == null ? base : base?.forOwner(owner);
  }

  /// Gövde metninin sayfa tepesinden uzaklığı (başlık + çip satırının altı).
  /// Görseller bunun üzerine çıkamaz; sarma hesabı da buna göre yapılır.
  ///
  /// [ValueNotifier] (P46, bütçe S18): ölçüm ilk kareden SONRA gelir; eskiden
  /// kök `setState` ile yazılıyor, editörün tamamı ikinci karede baştan
  /// kuruluyordu (not açma geçişinin ikinci karesi 786 kurulum). Değeri yalnız
  /// tuval okur — yalnız o kurulur.
  final _bodyTopN = ValueNotifier<double>(0);

  double get _bodyTop => _bodyTopN.value;

  final _bodyTopKey = GlobalKey();

  /// Az önce BU EKRANDA eklenen ve sayfada yüzen ek — tuval onu seçip
  /// görünüm anahtarını ipucuyla gösterir (bkz.
  /// [NotePageCanvas.placementHintId]); gösterilince temizlenir.
  String? _placementHintId;

  /// Üst çubuğun başlığı: başlık alanı oraya taşındıysa (bkz.
  /// [_titleInBar]) dolu, değilse null (tarih gösterilir). `build` içinde
  /// gövdeyi kurarken yazılır, aynı build'deki AppBar okur.
  Widget? _barTitle;

  /// Biçim paneli en az bir kez açıldı mı: alt çubuk panelden DÖNERKEN
  /// süzülerek belirir ([_barReturn]); notun ilk açılışında oynamaz.
  bool _barSwapped = false;

  /// Başlık bloğunun yüksekliğini ölçüp [_bodyTop]'u tazeler. Yükseklik
  /// yalnız başlık/çipler değişince oynar (sarma onu etkilemez), bu yüzden
  /// ölçüm yakınsar ve tek bildirimde durur.
  /// Bu kare için başlık ölçümü zaten sıraya girdi mi. Editörün build'i bir
  /// karede birden çok kez koşabiliyor (klavye açılışı, odak, tema); her
  /// kuruluşta ayrı bir kare-sonu geri çağrısı biriktirmenin anlamı yok,
  /// hepsi aynı yüksekliği ölçer.
  bool _bodyTopScheduled = false;

  /// Tuvaldeki görsellerin sayfa uzayındaki bantları. Gövde metni ve liste
  /// maddeleri bunları [WrapFieldMeasure] ile kendi uzaylarına çevirip
  /// etrafından akar.
  List<FloatBox> _floats = const [];

  /// Sayfa içeriğinin kökü — alanların konumu buna göre ölçülür.
  final _pageKey = GlobalKey();

  /// [_floats]in dinlenebilir eşi: bant değişimi editörü KURMAZ.
  final _floatsN = ValueNotifier<List<FloatBox>>(const []);

  // ---- Biçim çubuğu ---------------------------------------------------

  /// Biçim çubuğu açık mı (alt çubuktaki "Aa" düğmesi açıp kapatır).
  /// Kip notifier'da (P20 M5): panel, alt çubuk ve geri tuşu dar dinler;
  /// aç/kapa kökü kurmaz.
  final _formatOpenN = ValueNotifier<bool>(false);

  bool get _formatBarOpen => _formatOpenN.value;
  set _formatBarOpen(bool v) => _formatOpenN.value = v;

  /// Panel: kip + hedef alan (etkin biçim vurgusu hedefin imlecinden).
  late final Listenable _formatPanelL = Listenable.merge([
    _formatOpenN,
    _formatTargetN,
    _findOpenN,
  ]);

  /// Geri tuşu kuralı (PopScope) biçim kipini ve aramayı dinler.
  late final Listenable _popL = Listenable.merge([_formatOpenN, _findOpenN]);

  /// Yazma sürüyor mu (alt çubuk gizleme, bkz. [TypingBarHide]). Yalnız bu
  /// bildirici değişir: ekran setState ile yeniden kurulmaz.
  final _typingN = ValueNotifier<bool>(false);

  Timer? _typingTimer;

  /// Duraklamasız art arda yazılan değişiklik sayısı (bkz. [_noteTyping]).
  int _typedBurst = 0;

  /// Gizlenme gecikmesi sayacı (bkz. [typingBarHideDelayProvider]): yazma
  /// kesintisiz sürerse dolunca çubuk iner; duraklama ([_typingTimer]) iptal
  /// eder.
  Timer? _hideTimer;

  /// Son tuştan beri [_kStillTyping] geçmediyse etkin: gizlenme gecikmesi
  /// dolduğunda yazma HÂLÂ sürüyor mu (birkaç harf yazıp duran kullanıcının
  /// çubuğu, durduktan sonra inmesin).
  Timer? _recentKey;

  /// Alt çubuğun renkli/temalı/defter nottaki tonu (F75.3, K-D6): notun koyu
  /// tonu ve sayfa rengi; sade notta [_barInk] null → çubuk temanın
  /// renklerinde. Build'de [_chrome]'dan beslenir (yeni sağlayıcı yok).
  Color? _barInk;

  Color _barPage = Colors.transparent;

  late EditorChromePalette _chrome;

  /// Zemin görselinin 24 px'ten çıkarılmış renk/parlaklık tonu (önbellekli);
  /// zemin görseli yokken hiçbir iş yapmaz, bütçeye maliyeti sıfırdır.
  BgImageTone? _bgTone;

  String? _bgToneKey;

  /// Çubuğun yazacağı alan: en son odaklanan metin alanı (gövde ya da bir
  /// liste maddesi). Çubuğun kendisi odak İSTEMEDİĞİ için bu değer düğmeye
  /// basıldığında hâlâ geçerlidir (bkz. FormatBar).
  FormatTarget? _formatTarget;

  /// [_formatTarget]in dinlenebilir eşi: alt çubuktaki etkin biçim rozetleri
  /// ([ActiveFormatBadges]) odak değişimini editörü yeniden kurmadan izler.
  final _formatTargetN = ValueNotifier<FormatTarget?>(null);

  /// Çubuğun hedefi BAŞLIK mı? Başlığın kendi yazı tipi/boyutu/opaklığı var
  /// (bkz. Note.titleFontScale): çubuk hangi alan odaktaysa ONA yazar, yoksa
  /// başlığı büyütmek gövdeyi de büyütüyordu.
  bool get _titleIsTarget => _formatTarget?.controller == _titleController;

  /// Biçim panelinin hedefi bir MADDE alanıysa o maddenin kimliği.
  String? get _formatItemId {
    final controller = _formatTarget?.controller;
    if (controller == null ||
        identical(controller, _bodyController) ||
        _titleIsTarget) {
      return null;
    }
    return _itemsEditorKey.currentState?.itemIdForController(controller);
  }

  /// F22.2 (KARAR 2026-11-03): ~2 sn boşluk, aralıksız yazımda en geç
  /// 10 sn (2026-11-17: 2 sn / 20 sn, [SaveCadence]). Her kayıt FlutterFire'da TÜM koleksiyonu ana iş parçacığında
  /// yeniden kodlatıyor (K3) — 0,5 sn / 3 sn'de yazarken saniyede bir blok
  /// demekti. Çıkış kapılarında (kapanış, arka plan, `inactive`) bekleyen
  /// kayıt hemen yazılır ([_saveNow]); bedel: uygulama öldürülürse en çok
  /// ~10 sn'lik yazı.
  final _debouncer = Debouncer(
    delay: SaveCadence.delay,
    maxWait: SaveCadence.maxWait,
  );

  /// Lite: bekleyen içeriğin diskteki günlüğe yazılma tiki (bulut yazımından
  /// SIK; bkz. [_mutate], `lite_sync.dart`).
  final _journalDebouncer = Debouncer(
    delay: SaveCadence.delay,
    maxWait: SaveCadence.maxWait,
  );

  /// Lite aralığı bu editörde kuruldu mu ([_debouncer] süreleri uzatıldı).
  bool _liteArmed = false;

  /// Lite: değişiklik buluta henüz gitmedi (bulut simgesi "bekliyor" der).
  final _liteHeldN = ValueNotifier<bool>(false);

  /// Otomatik kayıt istemci saatiyle yazıldı mı (F22.3): kapanışta bir kez
  /// sunucu zamanı damgalanır ki sıralama/okunmamış hesabı cihaz saatine
  /// bağlı kalmasın.
  bool _clientStamped = false;

  /// ÜÇ YÖNLÜ BİRLEŞTİRMENİN TABANI (F4.1): bu editörün sunucuyla en son
  /// ORTAK gördüğü içerik. Başkasından gelen değişiklik yerelde henüz
  /// kaydedilmemiş yazıyla bu tabana göre birleştirilir (bkz. text_merge).
  String _baseTitle = '';

  String _baseBody = '';

  List<NoteItem> _baseItems = const [];

  ProviderSubscription<AsyncValue<Note?>>? _sub;

  bool _deleted = false;

  /// Bu oturumda çalışma sayacı işlendi mi (bkz. [noteActivityProvider]).
  bool _workCounted = false;

  /// Yeni boş not odağı bir kez denendi (bkz. `_focusIfNewEmptyNote`).
  bool _newNoteFocused = false;

  /// Madde editörünün durumu: başlıktaki klavye "İleri" tuşu liste notunda
  /// ilk maddeye odaklanabilsin diye GlobalKey. Karışık ve saf liste dalları
  /// aynı anahtarı kullanır — tip değişiminde (metin+madde ↔ liste) State
  /// korunur; madde listesi zaten didUpdateWidget'ta senkronlanıyor.
  final _itemsEditorKey = GlobalKey<ItemsEditorState>();

  /// Üst çubuk sırası (P20 M8, [UiPrefs.topOrder]). Kök YALNIZ sıra
  /// değişince kurulur — gizle/göster her öğenin kendi [Customizable]'ında.
  late List<String> _topOrder;

  /// Editör ne zamandır açık (bkz. [_setStateAfterOpening]).
  final _openedFor = Stopwatch()..start();

  /// Geçiş sonuna ertelenmiş bir yeniden çizim bekliyor mu.
  bool _redrawAfterOpening = false;

  /// Biçim paneli açıkken klavye geriyle kapandı mı (bkz. [ImeHideDetector]).
  final _imeHide = ImeHideDetector();

  /// F26.3 (bkz. [sortHeldNoteIdsProvider]); dispose'da `ref` yok.
  SortHeldNoteIdsNotifier? _sortHold;

  /// F68.1 (bkz. [heldNotePreviewProvider]); dispose'da `ref` yok.
  HeldNotePreviewNotifier? _previewHold;

  NavigatorState? _rootNavigator;

  // ---- Geri alma ------------------------------------------------------

  /// Değişiklikten ÖNCEKİ not anlık görüntüleri (bkz. note_undo.dart).
  final _undoStack = NoteUndoStack();

  /// Geri alma uygulanırken true: geri alınan durum yeniden yığına girmesin.
  bool _restoring = false;

  bool get _canUndo => _undoStack.canUndo;

  bool get _canRedo => _undoStack.canRedo;

  /// Kök kurulmadan mürekkebi ilerleyen eklerin, widget ağacının ELİNDEKİ
  /// (bayat) çizgi listesi — bkz. [_updateAttachmentInk], [_withLiveInk].
  /// Kök her kurulduğunda ağaç tazelenir, kayıt boşalır.
  final Map<String, List<InkStroke>> _staleInk = {};

  /// Kök kurulmadan içeriği ilerleyen TABLOLARIN, ağacın elindeki (bayat)
  /// eki — bkz. [_updateTableContent], [_withLiveTable]. Kök kurulunca
  /// boşalır.
  final Map<String, Attachment> _staleTable = {};

  // ---- Ekler ----------------------------------------------------------

  /// Görsel eklenmeden hemen önce ölçülen imleç yüksekliği (sayfa uzayı, dp).
  ///
  /// Ölçüm görsel gelince YAPILAMAZ: (+) menüsü açılırken klavye kapatılır ve
  /// odak düşer, galeri/kamera ise ekranı tümüyle terk eder. Bu yüzden değer
  /// menü açılmadan, klavyeden yapıştırılmadan ya da kısayol basılmadan ÖNCE
  /// alınıp burada saklanır. null = ölçülemedi (yığma yerleşimine düşülür).
  double? _caretPageY;

  /// Sayfa tuvalinin kaydırma denetleyicisi. Yeni görselin GÖRÜNEN alana
  /// düşmesi için gerekiyor (bkz. [_placeNewImage]).
  final _pageScroll = ScrollController();

  // ---- Not içi CANLI arama (bkz. NoteFindBar) ------------------------------

  /// Arama çubuğu açık mı — üst çubuğun ALTINDA ayrı bir satır (kullanıcı
  /// isteği 2026-11-16: "arama üst menünün altında yeni bir satırda
  /// oluşsun; klavye üzerinde alt panelin yerini alması olmaz"). Bildirici:
  /// aç/kapa kökü kurmaz (kullanıcı bulgusu "arama açılırken kasma" —
  /// eskiden kök setState + alt çubuk söküp yerine çubuk kuruluyordu).
  final _findOpenN = ValueNotifier<bool>(false);

  bool get _findOpen => _findOpenN.value;
  set _findOpen(bool v) => _findOpenN.value = v;

  /// Metin/liste notunda kalem kipi mi (belge notunun kalemi kendi bölmesinde).
  bool get _pagePen => _penMode && !(_note?.type.isPageNoteType ?? false);

  /// Editör yandaki bölmede mi (K32; bkz. [SecondNotePane])?
  bool get _secondary => SecondNotePane.maybeOf(context) != null;

  /// Eşleşmeler ve odak (F9.3): çubuk bunu dar builder'la dinler.
  final _find = NoteFindController();

  bool _findRefreshQueued = false;

  /// BAĞLAMA KİPİ: seçilmiş ama henüz bir yazıya bağlanmamış ek.
  ///
  /// Kullanıcı isteği 2026-08-16: "ek gömmede ters olarak da çalışmalı, yani
  /// önce eki seçip sonra metni seçme de olmalı". İlk sürüm yalnız tek yönü
  /// destekliyordu (önce yazıyı seç, sonra eki). İki yön de meşru: elinde
  /// dosya varken nereye koyacağına sonra karar vermek de olağan.
  ///
  /// Kip açıkken alt çubukta bir şerit durur ("… bağlanacak yazıyı seç") ve
  /// hem o şeritteki düğme hem de metin seçim menüsü bağlamayı bitirir.
  Attachment? _pendingEmbed;

  /// Jest kipi (bkz. note_editor_gestures.dart): maddelere jest ya da
  /// "Buraya bağla"da daire çizme.
  _GestureMode _gestureMode = _GestureMode.off;

  /// Maddeye çizilen jestin izi (bkz. `_trackGestureDown`).
  int _contentPointers = 0;

  int? _gesturePointer;

  List<Offset> _gesturePoints = [];

  Duration? _gestureStartedAt;

  Duration? _gestureMovedAt;

  double? _gestureScrollStart;

  TextSelection? _gestureSelectionStart;

  /// Etkin metin alanında en son yapılmış DOLU (boş olmayan) seçim ve o
  /// seçimin ait olduğu alan.
  ///
  /// **KÖK NEDEN (kullanıcı bulgusu 2026-08-18: "buraya bağla çalışmıyor,
  /// basıyorum bağlanmıyor").** `_finishPendingEmbed` seçimi doğrudan
  /// `_bodyController.selection`'dan okuyordu; oysa şeritteki düğmeye dokunmak
  /// gövde alanının DIŞINA dokunmaktır: `EditableText` odağı düşürüp seçimi
  /// imlece ÇÖKERTİYOR (`isCollapsed`). Bağlama sessizce iptal ediliyor,
  /// kullanıcıya yeniden "yazıyı seç" diyen aynı bildirim çıkıyordu — dışarıdan
  /// "hiçbir şey olmuyor" gibi görünen tam olarak buydu.
  ///
  /// **İKİNCİ TUR (kullanıcı bulgusu: "buraya bağla çalışmıyor HÂLÂ; basınca
  /// hiçbir şey olmuyor, 'bağla' yazısı kalmaya devam ediyor").** İlk çözüm
  /// ([TextFieldTapRegion] + yedek seçim) tek bir alanı, GÖVDEYİ varsayıyordu
  /// ve yedeğe düşemediği her durumda düğme SESSİZCE geri dönüyordu — kip
  /// açık kalıyor, kullanıcı aynı düğmeye tekrar tekrar basıyordu. Üç kapı
  /// birden kapatıldı:
  /// 1. Seçim artık **etkin alandan** hatırlanıyor (gövde, başlık ya da bir
  ///    MADDE satırı — bkz. [_setFormatTarget]); liste notunda da bağlanır.
  /// 2. Şeride PARMAK DEĞDİĞİ AN seçim yedekleniyor
  ///    ([_PendingEmbedBanner.onPointerDown]) — odak/seçim düşse bile bir kare
  ///    önce elimizde.
  /// 3. Seçim hiçbir yoldan bulunamazsa düğme artık SESSİZ KALMIYOR: etiket
  ///    imlecin yerine (yoksa metnin sonuna) dosya adıyla yazılır — yani
  ///    "Metne ekle"nin ilk günkü davranışı. Basmak HER ZAMAN bir sonuç üretir
  ///    ve kip kapanır.
  TextSelection? _lastSelection;

  FormatTarget? _lastSelectionTarget;

  /// Levha açılırken alınan seçim anlık görüntüsü (bkz. [_showAttachMenu]).
  TextSelection? _selectionSnapshot;

  /// Nottan çıkarılan ama BAYTLARI henüz silinmemiş ekler.
  ///
  /// Dosya eskiden ek nottan çıkarılır çıkarılmaz siliniyordu; "Geri al" ile
  /// geri gelen ek bu yüzden boş bir yer tutucu olurdu. Silme editörden
  /// çıkarken yapılır: o an nota geri dönmemiş olanlar gerçekten gider.
  final _pendingAttachmentDeletes = <Attachment>[];

  /// Klavyenin en son ÖLÇÜLEN yüksekliği. Klavye kapalıyken de saklanır:
  /// odak alındığı anda klavye daha açılmamış olur ama nereye kaydıracağımızı
  /// bilmek için yüksekliğini bilmek gerekir (bkz. [_revealCaret]).
  double _keyboardMemory = _NoteEditorScreenState._kKeyboardGuess;

  /// Klavye boşluğunun YERLEŞİME GİRMİŞ hâli ([KeyboardSnap] gövdeye bunu
  /// veriyor). Sıfırsa klavye ya kapalı ya da hareket hâlinde: o durumda
  /// klavyenin kapladığı yer sayfanın yerleşiminde HENÜZ yoktur.
  double _keyboardInset = 0;

  double _canvasBaseWidth = 0;

  double _canvasBaseHeight = 0;

  /// O anki build'de kurulmuş tuval ağacı ve kurulduğu taban yükseklik.
  ///
  /// Klavye animasyonu boyunca gövdenin kısıtı her karede değişiyor ve
  /// `LayoutBuilder` yeniden koşuyor; taban yükseklik aynı kaldığı sürece
  /// BİREBİR AYNI widget örneği döndürülür ve Flutter alt ağacı hiç kurmaz.
  /// Her editör build'inde temizlenir — bayat ağaç bir kare bile yaşamaz.
  Widget? _canvasCache;

  double _canvasCacheHeight = -1;

  /// Belge notunda bir BALONA yazılıyor: editörün alt çubuğu gizlenir.
  bool _immersiveBubble = false;

  /// PDF/sunum sayfasının ÜZERİNE yazma kipi (alt çubuktaki kalem düğmesi).
  /// Tam ekrana geçmeden bölmede çizim yapılır; kip açıkken tek parmak çizer,
  /// iki parmak gezinir (kullanıcı isteği 2026-08-08).
  bool _penMode = false;

  NoteFullscreenNotifier? _fullscreenNotifier;

  late final OpenNoteIdsNotifier _openNotes;

  /// Yeni not kapanınca ana ekran kartını odaklamak için (dispose'da `ref` yok).
  late final FocusedNoteNotifier _focusNote;

  /// Metin/liste notunun sayfa üstü el yazısı (bkz. [PageInkStack]).
  InkController? _pageInkCtl;

  /// Bu oturumda sayfaya çizilen çizgi sayısı (kalem ipuçlarının sırası).
  int _penStrokes = 0;

  /// Notun bir metin alanı (gövde, madde, başlık) odakta mı — tablette
  /// klavye boşluğu olmadan da hızlı satırı göstermek için
  /// ([KeyboardSwitch.editing]). Yalnız odak değişince güncellenir.
  final _fieldFocusedN = ValueNotifier<bool>(false);

  /// Bu editörün rota kapsamı (her kurulumda tazelenir).
  FocusScopeNode? _routeScope;

  /// Alt çubuğun ⋯ (taşma) düğmesi (U6); bölmedeki ikinci editörle
  /// çakışmasın diye örneğe ait.
  final _barMoreKey = GlobalKey(debugLabel: 'editor-bar-more');

  /// Bu not girişinde hızlı satır vurgusu gösterildi mi (bkz. [EditorQuickRow]).
  bool _quickRowHinted = false;

  /// Bu açılışta ipucuna bakıldı mı (bkz. [_maybeShowTip]).
  bool _tipChecked = false;

  /// Balonlu görünümden sabite göç bir kez bakıldı mı (bkz. [_retireBubbleView]).
  bool _bubbleRetireChecked = false;

  final _titleGeneratingN = ValueNotifier<bool>(false);

  // ── ÜSTE SABİTLİ MEDYA ("üstte video/resim, altta not") ────────────────

  /// Görsel sabitleme bölgesinin üstündeyken true: "Bırak" şeridi görünür.
  bool _pinHover = false;

  /// Bir görsel taşınıyor: tepedeki hedef şerit (soluk) görünür (F13.6).
  bool _pinDrag = false;

  // ── VİDEO ZAMAN DAMGALARI ─────────────────────────────────────────────
  //
  // Kullanıcı isteği 2026-10-16: "videolarda altta dk sn notu YouTube'daki
  // gibi, tıklayınca video o dk sn'ye gider; tersi de: video akarken
  // kenarda 'bu dakikaya not al' düğmesi madde ekler ya da metne dk sn
  // yazar ve not alanına odaklar".

  /// Nottaki oynatıcıların buluşma noktası (bkz. video_time.dart).
  final _videoHub = NoteVideoHub();

  // ————————————————————————————————————————————————————————————————
  // CANLI DİKTE — "sesle yazma"
  //
  // Kullanıcı isteği 2026-09-01: "mikrofon işareti direk sesle yazma olsun,
  // hemen yanına da AI anımsatacak farklı bir mikrofon butonu koyalım, bu da
  // şuanki durum olsun; sesle yazma çok pratik ve doğru olmalı, kişinin
  // imlecinin olduğu yere yazmalı."
  //
  // Alt çubuktaki İKİ mikrofon tam olarak bu ayrım:
  //  * `mic` (sade)      → BURASI: klavye gibi davranır, konuşulan söz
  //    imlecin olduğu yere anında yazılır, levha açılmaz, yapay zekâ
  //    çağrılmaz, kota harcanmaz.
  //  * `mic + parıltı`   → [_captureVoice]: eski davranış. Metin önce
  //    levhada gözden geçirilir, istenirse özetlenir/maddelere bölünür.
  //
  // **Neden "sil ve yeniden yaz"**: tanıyıcı her olayda o ana kadarki TAM
  // metni gönderir (bkz. DeviceSpeech.listen) ve söylenen bir kelimeyi
  // sonradan DÜZELTEBİLİR ("bir" → "birkaç"). Gelen parçayı imlece eklemek
  // metni ikizler; bu yüzden dikte boyunca yazdığımız aralık ([_dictationAt],
  // [_dictationLength]) hatırlanır ve her olayda o aralık yenisiyle
  // DEĞİŞTİRİLİR. Kullanıcının dikte sırasında elle yazdığı harfler aralığın
  // dışında kaldığı için korunur.
  /// Canlı dikte denetleyicisi (son kelime boşaltma, duraklat/devam, TR/EN
  /// dil değişimi ve parça geri alma — bkz. [DictationController]).
  DictationController? _dictationCtl;

  /// Notun içinde süren SESLİ NOT kaydı (alt şeritteki hap; bkz.
  /// [VoiceRecordPanel], `_recordAudio`).
  VoiceNoteRecorder? _voiceRecorder;
}
