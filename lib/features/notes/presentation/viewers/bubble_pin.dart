part of 'bubble_layer.dart';

/// Tutamacın kare boyu (yazısız balon).
const _pinSize = 28.0;

/// Başlıklı tutamacın en geniş hâli — 12 karakterlik başlık sığar.
const _pinChipMaxWidth = 150.0;

/// Tutamacın noktaya göre yerleşimi: [below] gövde noktanın ALTINA mı
/// açılıyor, [left] noktanın SOLUNA mı.
typedef _PinPlace = ({bool below, bool left});

/// Tutamaç bir KONUŞMA BALONUDUR: sivri köşesi balonun noktasında durur,
/// gövdesi o köşeden açılır (kullanıcı isteği 2026-10-15: "balon görüntüsü
/// baştan yenilenmeli"). Eski yuvarlak tutamaç noktanın TAM ÜSTÜNE
/// ortalanıyordu; işaret ettiği kelimeyi kapatıyor, hangi noktayı
/// gösterdiği de belli olmuyordu.
///
/// Serbest balonun gövdesi noktanın ÜSTÜNDE (harita iğnesi gibi); vurgunun
/// gövdesi ise vurgulanan satırın ALTINDA — yoksa işaretlenen yazının
/// üstünü kapatırdı. Sayfanın kenarına yakın tutamaç ters yöne döner.
_PinPlace _pinPlacement(PageBubble bubble, Size page, [double scale = 1]) {
  final x = bubble.x * page.width;
  final y = bubble.y * page.height;
  final title = bubble.title.trim();
  final width =
      (title.isEmpty
          ? _pinSize
          : math.min(_pinChipMaxWidth, 34 + title.characters.length * 7.2)) *
      scale;
  final room = (_pinSize + 8) * scale;
  return (
    below: bubble.isHighlight ? y <= page.height - room : y < room,
    left: x + width > page.width - 2 && x >= width,
  );
}

/// Tutamacın ekrandaki boy çarpanı: genel tercih ([BubbleLook.scale]) ×
/// balonun kendi boyu ([PageBubble.size]). Açık metinde 1 — orada boy
/// yazının puntosudur, tutamaç yok.
double _pinScaleOf(PageBubble bubble, double scale) =>
    bubble.plain ? 1 : (scale * bubble.size).clamp(0.5, 4.0).toDouble();

/// Balon renginin üstünde okunan yazı/simge rengi. Sabit siyah, koyu
/// renklerde (indigo, kahve, mor) okunmuyordu.
Color _inkOn(Color color) =>
    color.computeLuminance() > 0.36 ? Colors.black87 : Colors.white;

/// Yazılmış bir balonun SALT OKUNUR hâli — sayfanın üzerinde, tutamacın
/// yanında.
///
/// Kullanıcı isteği (2026-08-08): "not yazıldıktan sonra küçük simgesine
/// tıklandığında sadece not orada balon olarak görülsün, düzenleme için
/// Düzenle butonu olsun." Okumak için klavye açmak (ve içeriği ekranın öbür
/// ucundaki karta taşımak) gereksizdi.
///
/// **Görünüm yeniden yazıldı (2026-10-15).** Kart artık tutamacın ÜSTÜNE
/// binmez (tutamaç noktanın hangi yanına açıldıysa kart öbür yanında
/// başlar); balonun rengi üstte ince bir şerit, başlık kalın, yazı rahat
/// satır aralığıyla; eylemler altta YAZILI düğmeler — "Düzenle" bir simgenin
/// arkasına saklanmıyor.
class _BubbleReadCard extends StatelessWidget {
  const _BubbleReadCard({
    required this.controller,
    required this.bubble,
    required this.pageSize,
    required this.readOnly,
    this.scale = 1,
  });

  final BubbleController controller;
  final PageBubble bubble;
  final Size pageSize;
  final bool readOnly;

  /// Genel balon boyu ([BubbleLook.scale]): kartın genişliği ve yazısı da
  /// onunla büyür (büyük balon tercih eden okumayı da büyük ister).
  final double scale;

  @override
  Widget build(BuildContext context) {
    // Dar tutulur: kart okunan satırın yanında durmalı, sayfayı örtmemeli.
    final width = math.min(pageSize.width * 0.74, 280.0 * scale);
    final pinScale = _pinScaleOf(bubble, scale);
    final anchor = Offset(
      bubble.x * pageSize.width,
      bubble.y * pageSize.height,
    );
    final left = (anchor.dx - 16)
        .clamp(0.0, math.max(0.0, pageSize.width - width))
        .toDouble();
    // Sayfanın alt yarısındaki balonun kartı YUKARI açılır: aşağı açılsa
    // sayfanın dışına taşardı.
    final below = anchor.dy < pageSize.height * 0.55;
    // Tutamaç noktanın hangi yanında duruyor? Kart onun üstüne binmesin.
    final pinBelow =
        !bubble.plain && _pinPlacement(bubble, pageSize, pinScale).below;
    const gap = 6.0;
    final pin = _pinSize * pinScale + gap + 2;
    final card = _card(context);
    return Positioned(
      left: left,
      width: width,
      top: below ? anchor.dy + (pinBelow ? pin : gap) : null,
      bottom: below
          ? null
          : math.max(0.0, pageSize.height - anchor.dy) + (pinBelow ? gap : pin),
      child: scale == 1
          ? card
          : MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(
                  MediaQuery.textScalerOf(context).scale(1) * scale,
                ),
              ),
              child: card,
            ),
    );
  }

  /// **Görünüm yenilendi (2026-10-20, "daha premium").** Kart nötr bir
  /// yüzey: balonun rengi yalnız başlığın yanındaki küçük bir noktada —
  /// eskiden üstteki renkli şerit sarı balonda sayfanın üstünde fosforlu bir
  /// bant gibi duruyordu. İnce kenar çizgisi + yumuşak gölge, rahat iç boşluk;
  /// eylemler ince bir ayırıcının altında.
  Widget _card(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final color = BubbleController.displayColor(bubble);
    final title = bubble.title.trim();
    final text = bubble.text.trim();
    final muted = scheme.onSurfaceVariant;
    return Material(
      color: scheme.surface,
      elevation: 6,
      shadowColor: Colors.black38,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.7)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4, right: 8),
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title.isNotEmpty)
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                      if (text.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: title.isEmpty ? 0 : 4),
                          child: Text(
                            text,
                            maxLines: 10,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1.4,
                              color: title.isEmpty
                                  ? scheme.onSurface
                                  : scheme.onSurface.withValues(alpha: 0.82),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (bubble.urgent)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.priority_high_rounded,
                      size: 16,
                      color: scheme.error,
                    ),
                  ),
                if (bubble.starred)
                  Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: Icon(
                      Icons.star_rounded,
                      size: 17,
                      color: Colors.amber[700],
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Divider(
              height: 1,
              color: scheme.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 2, 4, 2),
            child: Row(
              children: [
                // Ok yalnız VURGULU balonda var: serbest balonun bağlanacağı
                // bir metin yok, düğme de anlamsız olurdu.
                if (!readOnly && bubble.isHighlight)
                  _action(
                    icon: bubble.arrow ? Icons.north_east : Icons.block,
                    tooltip: bubble.arrow
                        ? l10n.bubbleArrowHide
                        : l10n.bubbleArrowShow,
                    color: muted,
                    onPressed: () => controller.toggleArrow(bubble.id),
                  ),
                const Spacer(),
                // KOPYALA (F13.1, 2026-10-31): balon yazısı eskiden hiçbir
                // yoldan panoya alınamıyordu. Salt okunur belgede de var.
                if (bubbleShareLine(bubble).isNotEmpty)
                  _action(
                    key: const ValueKey('bubble-read-copy'),
                    icon: Icons.copy_outlined,
                    tooltip: l10n.bubbleCopy,
                    color: muted,
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.maybeOf(context);
                      await Clipboard.setData(
                        ClipboardData(text: bubbleShareLine(bubble)),
                      );
                      messenger
                        ?..hideCurrentSnackBar()
                        ..showMessage(l10n.copied);
                    },
                  ),
                if (!readOnly)
                  TextButton.icon(
                    key: const ValueKey('bubble-read-edit'),
                    onPressed: controller.beginEdit,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      minimumSize: const Size(0, 32),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: Text(l10n.bubbleEditShort),
                  ),
                _action(
                  icon: Icons.close,
                  tooltip: l10n.bubbleCollapse,
                  color: muted,
                  onPressed: controller.collapseAll,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _action({
    Key? key,
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback onPressed,
  }) => IconButton(
    key: key,
    tooltip: tooltip,
    onPressed: onPressed,
    visualDensity: VisualDensity.compact,
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
    icon: Icon(icon, size: 17, color: color),
  );
}

/// Balon tutamaçlarının GENEL boy tercihi (cihaz başına, bütün belgelerde).
///
/// Kullanıcı isteği 2026-10-16: "balonların boyutu ayarlanabilir olsun".
/// Telefonda 28 dp'lik tutamaç kimine küçük (bulunmuyor), kimine büyük
/// (yazıyı örtüyor). Tek balonun boyu yazma kartındaki −/+ ile
/// ([PageBubble.size]), hepsininki balon bırakma kartındaki −/+ ile
/// buradan ayarlanır; ikisi çarpılır.
class BubbleLook {
  BubbleLook._();

  static const double min = 0.7;
  static const double max = 2.0;
  static const double step = 0.15;

  static final scale = ValueNotifier<double>(1);

  static SharedPreferences? _prefs;
  static const _key = 'bubble_pin_scale';

  /// Uygulama açılışında (main) bir kez: kayıtlı tercih okunur.
  static void attach(SharedPreferences prefs) {
    _prefs = prefs;
    scale.value = (prefs.getDouble(_key) ?? 1).clamp(min, max).toDouble();
  }

  static void setScale(double value) {
    final next = value.clamp(min, max).toDouble();
    if ((next - scale.value).abs() < 0.001) return;
    scale.value = next;
    _prefs?.setDouble(_key, next);
  }
}

/// "Basılı tut → balon bırak" dinleyicisi (bkz. [BubblePageLayer.longPressAdd]).
///
/// **Jest tanıyıcısı DEĞİL, `Listener`**: sayfanın tamamını kaplayan bir uzun
/// basış tanıyıcısı HER dokunuşta arenaya girer ve süresi dolunca kazanıp
/// belgenin kaydırma/yakınlaştırma tanıyıcılarını elerdi (PdfSelectLayer'daki
/// gerekçenin aynısı). Dinleyici arenaya girmez: süre zamanlayıcıyla ölçülür,
/// parmak kayarsa ya da ikinci parmak inerse iptal olur. Fare dinlenmez —
/// masaüstünde basılı tutup sürüklemek metin seçimidir.
class _LongPressDrop extends StatefulWidget {
  const _LongPressDrop({required this.onDrop});

  final ValueChanged<Offset> onDrop;

  static const delay = Duration(milliseconds: 450);
  static const slop = 18.0;

  @override
  State<_LongPressDrop> createState() => _LongPressDropState();
}

class _LongPressDropState extends State<_LongPressDrop> {
  final _pointers = <int>{};
  Timer? _timer;
  int? _pointer;
  Offset _start = Offset.zero;

  void _cancel() {
    _timer?.cancel();
    _timer = null;
    _pointer = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _up(PointerEvent e) {
    _pointers.remove(e.pointer);
    if (e.pointer == _pointer) _cancel();
  }

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: (e) {
      if (e.kind == PointerDeviceKind.mouse) return;
      _pointers.add(e.pointer);
      if (_pointers.length > 1) {
        _cancel();
        return;
      }
      _pointer = e.pointer;
      _start = e.localPosition;
      _timer?.cancel();
      _timer = Timer(_LongPressDrop.delay, () {
        final at = _start;
        _cancel();
        if (mounted) widget.onDrop(at);
      });
    },
    onPointerMove: (e) {
      if (e.pointer == _pointer &&
          (e.localPosition - _start).distance > _LongPressDrop.slop) {
        _cancel();
      }
    },
    onPointerUp: _up,
    onPointerCancel: _up,
    child: const SizedBox.expand(),
  );
}

/// Balonu (kart ya da tutamaç) **basılı tutup sürüklenebilir** yapan sarmalayıcı.
///
/// Neden `GestureDetector` değil `RawGestureDetector`: `GestureDetector` uzun
/// basış SÜRESİNİ dışarı açmıyor ve Flutter'ın varsayılanı 500 ms — kullanıcı
/// "hâlâ çok zor sürükleniyor" derken tarif ettiği şey buydu. Burada süre
/// 220 ms; yarım saniye beklemek yerine "tut ve taşı" tek akışta oluyor.
///
/// Uzun basış arenayı kazandığı an pdfrx'in kaydırma/ölçek tanıyıcıları
/// elenir, yani sayfa altta kaymaz — ayrıca bir pan kilidine gerek yoktur.
class BubbleDragArea extends StatefulWidget {
  const BubbleDragArea({
    super.key,
    required this.child,
    required this.onDragStart,
    required this.onDragDelta,
    required this.onDragEnd,
    this.onTap,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback onDragStart;
  final ValueChanged<Offset> onDragDelta;
  final VoidCallback onDragEnd;
  final VoidCallback? onTap;
  final bool enabled;

  static const _pressDuration = Duration(milliseconds: 220);

  @override
  State<BubbleDragArea> createState() => _BubbleDragAreaState();
}

class _BubbleDragAreaState extends State<BubbleDragArea> {
  /// Son bildirilen TOPLAM kayma. **STATE'te durmak zorunda.**
  ///
  /// KÖK NEDEN (2026-08-08 kullanıcı bulgusu: "sürüklemeye başladığım anda
  /// kenarlara fırlıyor, kontrolsüz hareket ediyor"): bu değer `build()`
  /// içinde YEREL bir değişkendi. Taşıma sırasında her hareket denetleyiciyi
  /// güncelliyor, o da katmanı yeniden kuruyor ve `build()` yeniden koştuğu
  /// için değişken SIFIRLANIYORDU. Bir sonraki olayda fark, kare farkı yerine
  /// jestin BAŞINDAN itibaren toplam kayma olarak uygulanıyor ve balon
  /// parmaktan kat kat hızlı fırlıyordu.
  Offset _last = Offset.zero;

  // ── ANINDA DOKUNUŞ ────────────────────────────────────────────────────
  // KÖK NEDEN (kullanıcı bulgusu 2026-10-30, balonlu mod): dokunuş arenada
  // `TapGestureRecognizer` ile alınıyordu; alttaki görüntüleyicinin ÇİFT
  // dokunuş (yakınlaştırma) tanıyıcısı aynı arenada olduğundan tek dokunuş
  // ancak çift dokunuş süresi (~300 ms) dolunca kabul ediliyor, balon
  // gecikmeyle açılıyordu (açık balonu kapatmadaki gecikmenin aynısı — bkz.
  // `TapToCollapse`). Dokunuş artık ham işaretçiden: taşımanın uzun basışından
  // ([BubbleDragArea._pressDuration]) KISA, kıpırdamayan bir basış.
  int? _tapPointer;
  Offset _tapDown = Offset.zero;
  DateTime _tapAt = DateTime.fromMillisecondsSinceEpoch(0);
  bool _dragged = false;

  static const _maxTap = Duration(milliseconds: 200);

  void _onPointerDown(PointerDownEvent e) {
    if (_tapPointer != null) {
      _tapPointer = -1; // ikinci parmak: dokunuş değil
      return;
    }
    _tapPointer = e.pointer;
    _tapDown = e.position;
    _tapAt = DateTime.now();
    _dragged = false;
  }

  void _onPointerUp(PointerUpEvent e) {
    final pointer = _tapPointer;
    _tapPointer = null;
    if (pointer != e.pointer || _dragged) return;
    if ((e.position - _tapDown).distance > kTouchSlop) return;
    if (DateTime.now().difference(_tapAt) > _maxTap) return;
    widget.onTap?.call();
  }

  Widget _quickTap(Widget child) => widget.onTap == null
      ? child
      : Listener(
          onPointerDown: _onPointerDown,
          onPointerUp: _onPointerUp,
          onPointerCancel: (_) => _tapPointer = null,
          child: child,
        );

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return _quickTap(
        widget.onTap == null
            ? widget.child
            : ColoredBox(color: Colors.transparent, child: widget.child),
      );
    }
    return _quickTap(
      RawGestureDetector(
        behavior: HitTestBehavior.opaque,
        gestures: <Type, GestureRecognizerFactory>{
          LongPressGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
                () => LongPressGestureRecognizer(
                  duration: BubbleDragArea._pressDuration,
                ),
                (instance) => instance
                  ..onLongPressStart = (_) {
                    _last = Offset.zero;
                    _dragged = true;
                    widget.onDragStart();
                  }
                  ..onLongPressMoveUpdate = (d) {
                    widget.onDragDelta(d.offsetFromOrigin - _last);
                    _last = d.offsetFromOrigin;
                  }
                  ..onLongPressEnd = (_) {
                    _last = Offset.zero;
                    widget.onDragEnd();
                  }
                  ..onLongPressCancel = () {
                    _last = Offset.zero;
                    widget.onDragEnd();
                  },
              ),
        },
        child: widget.child,
      ),
    );
  }
}

/// Sayfadaki TUTAMAÇ: kapalıysa nokta ya da başlık etiketi, açıksa aynı
/// tutamacın vurgulanmış hâli. İçerik burada DEĞİL — [BubbleDock]'ta.
class _BubblePin extends StatefulWidget {
  const _BubblePin({
    super.key,
    required this.controller,
    required this.bubble,
    required this.pageSize,
    required this.readOnly,
    this.scale = 1,
  });

  final BubbleController controller;
  final PageBubble bubble;
  final Size pageSize;
  final bool readOnly;

  /// Genel balon boyu ([BubbleLook.scale]).
  final double scale;

  @override
  State<_BubblePin> createState() => _BubblePinState();
}

class _BubblePinState extends State<_BubblePin>
    with SingleTickerProviderStateMixin {
  /// Sürüklerken parmağın balonu "kaldırdığı" hissi.
  bool _lifted = false;

  /// Taşıma sırasında biriken kayma — YALNIZ burada durur ve tek bir
  /// `Transform.translate`i besler.
  ///
  /// KÖK NEDEN (2026-08-08 kullanıcı bulgusu: "sürükleme çalışıyor ama
  /// parmağımdan geride kalıyor, yavaş geliyor"): her hareket
  /// `controller.update` çağırıyordu; o da `notifyListeners` ile sayfanın
  /// BÜTÜN balon katmanını — vurgu boyaması, vurgu dokunma alanları, öbür
  /// tutamaçlar — yeniden kuruyordu. Kare başına bir tam yeniden kurulum,
  /// parmağın gerisinde kalmak demek. Artık model taşıma BİTİNCE bir kez
  /// yazılır; hareket sırasında yalnız bu değer değişir ve tek bir widget
  /// tazelenir.
  final _drag = ValueNotifier<Offset>(Offset.zero);

  /// ACİL balonun yanıp sönmesi. Denetleyici YALNIZ gerektiğinde koşar:
  /// sayfadaki her balon için sürekli dönen bir animasyon, kare kare yeniden
  /// boyama demek olurdu (kasma).
  AnimationController? _blink;

  @override
  void initState() {
    super.initState();
    _syncBlink();
  }

  @override
  void didUpdateWidget(_BubblePin old) {
    super.didUpdateWidget(old);
    _syncBlink();
  }

  @override
  void dispose() {
    _blink?.dispose();
    _drag.dispose();
    super.dispose();
  }

  void _syncBlink() {
    final wanted = widget.bubble.urgent;
    if (wanted && _blink == null) {
      _blink = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 700),
      )..repeat(reverse: true);
    } else if (!wanted && _blink != null) {
      _blink!.dispose();
      _blink = null;
    }
  }

  void _dragStart() {
    if (widget.readOnly) return;
    HapticFeedback.mediumImpact();
    setState(() => _lifted = true);
    widget.controller.setDragging(widget.bubble.id);
  }

  void _dragMove(Offset delta) {
    if (widget.readOnly || !_lifted) return;
    _drag.value += delta;
    // Vurguya giden ok da parmakla birlikte uzasın/yönelsin: yalnız ok
    // katmanı dinliyor, denetleyici uyandırılmıyor (bkz. dragDelta).
    widget.controller.dragDelta.value = _drag.value;
  }

  void _dragEnd() {
    if (!_lifted) return;
    final moved = _drag.value;
    _drag.value = Offset.zero;
    widget.controller.dragDelta.value = Offset.zero;
    setState(() => _lifted = false);
    final b = widget.bubble;
    widget.controller
      ..update(
        b.copyWith(
          x: (b.x + moved.dx / widget.pageSize.width).clamp(0.0, 1.0),
          y: (b.y + moved.dy / widget.pageSize.height).clamp(0.0, 1.0),
        ),
      )
      ..setDragging(null)
      ..save();
  }

  /// Kapalı balon `widget.bubble`den okunur. AÇIK balon [BubbleController]'dan
  /// canlı okunur: başlık/metin yazılırken denetleyici dinleyicileri
  /// uyandırmaz (kasma), yalnız `revision` sayacını artırır — böylece sayfadaki
  /// etiket harf harf güncellenirken öbür balonlar hiç tazelenmez.
  @override
  Widget build(BuildContext context) => widget.bubble.collapsed
      ? _pin(context, widget.bubble)
      : ValueListenableBuilder<int>(
          valueListenable: widget.controller.revision,
          builder: (context, _, _) => _pin(
            context,
            widget.controller.byId(widget.bubble.id) ?? widget.bubble,
          ),
        );

  Widget _pin(BuildContext context, PageBubble bubble) {
    // Tutamaç YARI SAYDAM: sayfanın üstünde duruyor ve altındaki yazının
    // okunmasını engellememeli (kullanıcı isteği 2026-08-08 — "yarı saydam,
    // yazının arkasında kalan balon"). Taşınırken ve açıkken tam opak olur:
    // o an ilgilenilen balon net görünmeli.
    final opaque = _lifted || !bubble.collapsed;
    final page = widget.pageSize;
    // BOY (kullanıcı isteği 2026-10-16): tutamaç sivri köşesinin ETRAFINDA
    // ölçeklenir — işaret ettiği nokta yerinde kalır. Ölçek bir dönüşüm:
    // yerleşim ve dokunma alanı (RenderTransform isabeti dönüşümle
    // hesaplar) birlikte büyür, gövdenin ölçüsünü bilmek gerekmez.
    final pinScale = _pinScaleOf(bubble, widget.scale);
    final point = Offset(bubble.x * page.width, bubble.y * page.height);
    // AÇIK METİN ALANI: tutamaç yerine yazının kendisi çizilir.
    // Boyutlanırken model henüz yazılmadı: geçici çarpan burada uygulanır.
    final Widget child;
    double? left;
    double? top;
    double? right;
    double? bottom;
    var origin = Alignment.center;
    if (bubble.plain) {
      final shown = _resizeSize == null
          ? bubble
          : bubble.copyWith(size: _resizeSize);
      child = _plainText(context, shown, Color(bubble.color));
      left = point.dx.clamp(0.0, (page.width - 60).clamp(0.0, double.infinity));
      top = point.dy.clamp(0.0, (page.height - 20).clamp(0.0, double.infinity));
      origin = Alignment.topLeft;
    } else {
      // Sivri köşe NOKTADA: gövde oradan sağa/sola, yukarı/aşağı açılır.
      // Sağ/alt kenardan yerleştirmek gövdenin genişliğini bilmeyi
      // gerektirmez (etiket uzunluğu başlığa göre değişiyor).
      final place = _pinPlacement(bubble, page, pinScale);
      child = _marker(bubble, place, opaque);
      if (place.left) {
        right = page.width - point.dx;
      } else {
        left = point.dx;
      }
      if (place.below) {
        top = point.dy;
      } else {
        bottom = page.height - point.dy;
      }
      origin = Alignment(place.left ? 1 : -1, place.below ? -1 : 1);
    }
    final blink = _blink;
    // Taşıma sırasında YALNIZ bu dönüşüm tazelenir: `child` bir kez kurulur ve
    // parmak boyunca aynı kalır (bkz. [_drag]).
    return Positioned(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      child: ValueListenableBuilder<Offset>(
        valueListenable: _drag,
        builder: (context, offset, child) =>
            Transform.translate(offset: offset, child: child),
        child: AnimatedScale(
          scale: (_lifted ? 1.2 : 1) * pinScale,
          alignment: origin,
          duration: const Duration(milliseconds: 120),
          // Ekran okuyucu (F4.7): balonun yazısı okunur, çift dokunuş açar.
          child: Semantics(
            button: true,
            label: _semanticLabel(context, bubble),
            onTap: () => widget.controller.openOnly(bubble.id),
            excludeSemantics: true,
            child: BubbleDragArea(
              enabled: !widget.readOnly,
              onTap: () => widget.controller.openOnly(bubble.id),
              onDragStart: _dragStart,
              onDragDelta: _dragMove,
              onDragEnd: _dragEnd,
              // `Tooltip` YOK: kendi uzun basış tanıyıcısını arenaya sokup
              // taşımayla yarışıyordu ("çok zor sürükleniyor"). Notun tamamı
              // zaten dokununca açılan okuma balonunda görünüyor.
              child: blink == null
                  ? child
                  : FadeTransition(
                      opacity: Tween<double>(
                        begin: 1,
                        end: 0.35,
                      ).animate(blink),
                      child: child,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  static String _semanticLabel(BuildContext context, PageBubble bubble) {
    final text = [
      bubble.title.trim(),
      bubble.text.trim(),
    ].where((t) => t.isNotEmpty).join('. ');
    return text.isEmpty
        ? context.l10n.bubbleSemanticsEmpty
        : context.l10n.bubbleSemantics(text);
  }

  /// Konuşma balonu biçimli tutamaç (bkz. [_pinPlacement]).
  ///
  /// Gölge BULANIKSIZ (yalnız 1.5 px aşağı kaydırılmış koyu bir kopya):
  /// sayfadaki her tutamaç için bulanıklık maskesi çizmek, çok balonlu
  /// sayfalarda kaydırmanın takılmasının paylarından biriydi. Bulanık gölge
  /// yalnız TAŞINAN tek balonda var — "kaldırdım" hissi için.
  Widget _marker(PageBubble bubble, _PinPlace place, bool opaque) {
    final base = BubbleController.displayColor(bubble);
    final ink = _inkOn(base);
    final title = bubble.title.trim();
    final open = !bubble.collapsed;
    const round = Radius.circular(13);
    const tip = Radius.circular(3);
    final radius = BorderRadius.only(
      topLeft: place.below && !place.left ? tip : round,
      topRight: place.below && place.left ? tip : round,
      bottomLeft: !place.below && !place.left ? tip : round,
      bottomRight: !place.below && place.left ? tip : round,
    );
    final empty = bubble.text.trim().isEmpty;
    // Yazısız VURGU: işaret metnin kendisinde, tutamaç küçük ve sessiz.
    final quiet = bubble.isHighlight && empty && title.isEmpty;
    // **PREMİUM GÖRÜNÜM** (2026-10-20): düz, doygun dolgu yerine üstten
    // hafif aydınlanan iki tonlu bir yüzey ve beyaz ince çerçeve — kâğıdın
    // üstünde basılı bir etiket gibi. Açık balon siyah kalın çerçeve yerine
    // kendi renginde YUMUŞAK bir halka taşır (bulanıksız yayılma: ucuz).
    final top = Color.lerp(base, Colors.white, 0.16)!;
    final alpha = opaque ? 1.0 : 0.85;
    final decoration = BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          top.withValues(alpha: alpha),
          base.withValues(alpha: alpha),
        ],
      ),
      borderRadius: radius,
      border: Border.all(
        color: Colors.white.withValues(alpha: open ? 1 : 0.92),
        width: open ? 2 : 1.5,
      ),
      boxShadow: [
        if (open)
          BoxShadow(color: base.withValues(alpha: 0.32), spreadRadius: 3.5),
        BoxShadow(
          color: Colors.black.withValues(alpha: _lifted ? 0.32 : 0.18),
          offset: Offset(0, _lifted ? 3 : 1.5),
          blurRadius: _lifted ? 6 : 0,
        ),
      ],
    );
    final icon = bubble.urgent
        ? Icons.priority_high_rounded
        : bubble.starred
        ? Icons.star_rounded
        : empty
        ? (bubble.isHighlight ? Icons.format_color_text : Icons.edit_rounded)
        : Icons.notes_rounded;
    if (title.isEmpty) {
      final size = quiet ? 20.0 : _pinSize;
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: decoration,
        child: Icon(icon, size: quiet ? 12 : 16, color: ink),
      );
    }
    return Container(
      constraints: const BoxConstraints(
        maxWidth: _pinChipMaxWidth,
        minHeight: 26,
      ),
      padding: const EdgeInsets.fromLTRB(9, 4, 10, 4),
      decoration: decoration,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (bubble.urgent || bubble.starred)
            Padding(
              padding: const EdgeInsets.only(right: 3),
              child: Icon(
                bubble.urgent
                    ? Icons.priority_high_rounded
                    : Icons.star_rounded,
                size: 14,
                color: ink,
              ),
            ),
          Flexible(
            child: Text(
              bubble.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                height: 1.15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
                color: ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Paint tarzı AÇIK METİN: balonun yazısı sayfanın üstünde doğrudan
  /// görünür — kutu yok, tutamaç yok.
  ///
  /// Sayfa fotoğraf da olabildiği için yazı **çift çizilir**: önce koyu bir
  /// dış hat (stroke), üstüne balonun kendi rengi. Tek renkli düz yazı açık
  /// bir zeminde (beyaz kâğıt, parlak gökyüzü) okunmuyordu; dış hat her
  /// zeminde okunur kılar ve gölgenin aksine yazıyı bulanıklaştırmaz.
  ///
  /// Boş metin, üzerine dokunulabilecek bir hedef bırakmak için yer tutucu
  /// gösterir; yoksa yeni bırakılan boş bir metin alanı görünmez olur ve
  /// kullanıcı onu bir daha açamazdı.
  Widget _plainText(BuildContext context, PageBubble bubble, Color color) {
    final text = bubble.text.trim();
    final empty = text.isEmpty;
    final fontSize = bubble.fontSize;
    // **VARSAYILAN YAZI BİÇİMİ** (kullanıcı isteği 2026-08-18: "yazı formatı
    // varsayılan yazı formatı olmalı"): kendi kalınlığını (w600) dayatmak
    // yerine temanın gövde biçimi devralınır — uygulamanın/notun seçili yazı
    // tipi neyse açık metin de onunla yazılır.
    final base = Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    final style = base.copyWith(
      fontSize: fontSize,
      height: 1.2,
      // KALIN/İTALİK (kullanıcı isteği: "metin kutusunu geliştirme"): biçim
      // balonun kendi alanlarından geliyor, varsayılan hâli eski davranışın
      // aynısı (bkz. [PageBubble.bold]).
      fontWeight: bubble.bold ? FontWeight.w700 : FontWeight.normal,
      fontStyle: bubble.italic ? FontStyle.italic : FontStyle.normal,
      color: color,
    );
    final align = switch (bubble.align) {
      1 => TextAlign.center,
      2 => TextAlign.right,
      _ => TextAlign.left,
    };
    // DOLGU: fotoğrafın/taranmış sayfanın karışık zemininde dış hat bile
    // yetmiyordu; dolgu yazının arkasına düz bir zemin koyar.
    final fill = bubble.fill == 0 ? null : Color(bubble.fill);
    // Dış hat yazının ZIDDI: siyah yazının çevresi beyaz, beyaz yazının
    // çevresi siyah. Sabit koyu dış hat, siyah varsayılanla birlikte yazıyı
    // kendi gölgesinde kaybediyordu.
    final outline = color.computeLuminance() < 0.5
        ? Colors.white.withValues(alpha: 0.85)
        : Colors.black.withValues(alpha: 0.7);
    final framed = empty || _lifted || _resizing;
    final body = Container(
      constraints: BoxConstraints(maxWidth: math.max(120, fontSize * 16)),
      padding: fill == null
          ? const EdgeInsets.symmetric(horizontal: 4, vertical: 2)
          : EdgeInsets.symmetric(horizontal: fontSize * 0.35, vertical: 4),
      decoration: (framed || fill != null)
          ? BoxDecoration(
              color: fill,
              // Boşken (taşınırken, boyutlanırken) ince bir çerçeve: alanın
              // nerede olduğu ve nereye kadar uzandığı görünsün.
              border: framed
                  ? Border.all(color: color.withValues(alpha: 0.8))
                  : null,
              borderRadius: BorderRadius.circular(4),
            )
          : null,
      child: empty
          ? Text(
              context.l10n.bubblePlainHint,
              textAlign: align,
              style: style.copyWith(
                color: color.withValues(alpha: 0.75),
                fontStyle: FontStyle.italic,
              ),
            )
          // Dolgu varken DIŞ HAT çizilmez: zemin zaten okunurluğu sağlıyor,
          // dış hat dolgunun üstünde gereksiz bir kalınlık bırakıyordu.
          : fill != null
          ? Text(text, textAlign: align, style: style)
          : Stack(
              children: [
                Text(
                  text,
                  textAlign: align,
                  style: style.copyWith(
                    foreground: Paint()
                      ..style = PaintingStyle.stroke
                      ..strokeWidth = math.max(2, fontSize / 6)
                      ..color = outline,
                  ),
                ),
                Text(text, textAlign: align, style: style),
              ],
            ),
    );
    if (widget.readOnly) return body;
    // **BOYUT TUTAMACI (Paint'teki gibi)**: yazının sağ alt köşesinde küçük
    // bir kulp; sürüklendikçe yazı büyür/küçülür. Yalnız AÇIK (seçili) metin
    // alanında çizilir — sayfadaki her yazının yanında sürekli duran bir kulp
    // belgeyi okunmaz hâle getirirdi.
    if (bubble.collapsed && !_resizing) return body;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        body,
        Positioned(
          right: -9,
          bottom: -9,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            // Boş `onTap`/`onLongPress` bilerek burada: üstteki
            // [BubbleDragArea] aynı iki jesti dinliyor ve kulba 220 ms basılı
            // tutmak balonu TAŞIMAYA başlatırdı. Arenaya çocuk olarak giren
            // tanıyıcı önce eklendiği için kazanır; kulp yalnız boyutlandırır.
            onTap: () {},
            onLongPress: () {},
            onPanStart: (_) => setState(() => _resizing = true),
            onPanUpdate: (d) => _resizeBy(bubble, d.delta),
            onPanEnd: (_) => _resizeEnd(),
            onPanCancel: _resizeEnd,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: outline, width: 1.5),
              ),
              child: const Icon(
                Icons.open_in_full,
                size: 12,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Boyut tutamacı şu an sürükleniyor mu (çerçeve bu sırada görünür kalır).
  bool _resizing = false;

  /// Sürükleme sırasında biriken çarpan; parmak bırakılınca bir kez yazılır.
  ///
  /// Taşımadaki kök nedenin aynısı (bkz. [_drag]): her karede `update` çağırmak
  /// sayfadaki bütün balon katmanını yeniden kurar ve kulp parmağın gerisinde
  /// kalır. Model YALNIZ bitişte yazılır.
  double? _resizeSize;

  void _resizeBy(PageBubble bubble, Offset delta) {
    final current = _resizeSize ?? bubble.size;
    // Çapraz hareketin ikisi de büyütür: sağa VE aşağı çekmek Paint'te
    // kutuyu büyütür. 90 px sürükleme ≈ bir kat büyüme.
    final next = (current + (delta.dx + delta.dy) / 90)
        .clamp(PageBubble.minSize, PageBubble.maxSize)
        .toDouble();
    if (next == current) return;
    setState(() => _resizeSize = next);
  }

  void _resizeEnd() {
    final next = _resizeSize;
    setState(() {
      _resizing = false;
      _resizeSize = null;
    });
    if (next == null) return;
    widget.controller
      ..update(widget.bubble.copyWith(size: next))
      ..save();
  }
}
