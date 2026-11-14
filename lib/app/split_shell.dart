import 'dart:async';
import 'dart:math' show max;
import 'dart:ui' show DisplayFeatureType;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/l10n_ext.dart';
import 'theme/app_tokens.dart';
import '../core/utils/immersive.dart';
import '../features/notes/presentation/dashboard_screen.dart';
import '../features/notes/presentation/editor/note_editor_screen.dart';
import '../features/settings/settings_providers.dart';
import 'app_commands.dart';
import 'second_note.dart';
import 'window_class.dart';
import '../core/haptics.dart';

export 'window_class.dart'
    show
        kSplitBreakpoint,
        kNoteSplitBreakpoint,
        kPortraitListBreakpoint,
        splitActiveFor;

/// Konum bir not/defter ekranı mı (kabuğun içinden açılmış)?
bool isNoteLocation(String path) =>
    path.startsWith('/note/') || path.startsWith('/notebook/');

bool listAutoHidesFor(Size window, {required bool hasHinge}) =>
    !hasHinge &&
    window.width < kPortraitListBreakpoint &&
    window.height > window.width;

/// ☰ ile bu not için listeyi açtı (konum); başka notta geçersiz.
final listPeekLocationProvider = NotifierProvider<_ListPeek, String?>(
  _ListPeek.new,
);

class _ListPeek extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? location) => state = location;
}

/// Ctrl+\ ve ☰: kendiliğinden çekilen listede yalnız bu not için, başka yerde
/// kalıcı tercih (odak modu).
void toggleNoteListPane(BuildContext context, WidgetRef ref) {
  final location = currentLocation(GoRouter.of(context));
  final auto = listAutoHidesFor(
    MediaQuery.sizeOf(context),
    hasHinge: verticalHingeOf(context) != null,
  );
  if (auto && isNoteLocation(location)) {
    final peek = ref.read(listPeekLocationProvider.notifier);
    peek.set(ref.read(listPeekLocationProvider) == location ? null : location);
    return;
  }
  ref.read(listPaneCollapsedProvider.notifier).toggle();
}

/// Kabuğun ŞU AN listeyi sol panelde çizip çizmediği ve listenin tek sütun
/// olup olmadığı. `/` rotası buna bakar: etkinken liste zaten solda, rota
/// hiçbir şey çizmez.
class SplitScope extends InheritedWidget {
  const SplitScope({
    super.key,
    required this.active,
    required this.singleColumn,
    this.listHidden = false,
    this.listAutoHides = false,
    this.twoNotesFit = false,
    required super.child,
  });

  final bool active;

  /// Sol paneldeki liste tek sütun çizilsin (not açık).
  final bool singleColumn;

  /// Not açık ve liste şu an gizli (tam ekran, odak modu, dikey tablet).
  final bool listHidden;

  /// Liste bu pencerede kendiliğinden çekiliyor (bkz. [listAutoHidesFor]).
  final bool listAutoHides;

  /// Not açık ve yanına ikinci not sığıyor (K32; yalnız dokunuş anında
  /// okunur — bildirim KONUSU değil, kimse buna göre yeniden kurulmaz).
  final bool twoNotesFit;

  static SplitScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SplitScope>();

  static bool activeOf(BuildContext context) =>
      maybeOf(context)?.active ?? false;

  @override
  bool updateShouldNotify(SplitScope oldWidget) =>
      active != oldWidget.active ||
      singleColumn != oldWidget.singleColumn ||
      listHidden != oldWidget.listHidden ||
      listAutoHides != oldWidget.listAutoHides;
}

/// Bu genişliğin altındaki liste bölmesi "dar" (F67.3): şeritler gizli,
/// arama hapı kısa, mikrofon yok (bkz. DashboardScreen).
const double kNarrowListPane = 420;

/// Sol paneldeki listeye "tek sütun çiz" der (bkz. DashboardScreen).
class DashboardPaneScope extends InheritedWidget {
  const DashboardPaneScope({
    super.key,
    required this.singleColumn,
    this.anchorNoteId,
    required super.child,
  });

  final bool singleColumn;

  /// Sütun sayısı değişince listenin gözden kaçırmaması gereken not: açılan
  /// not ya da az önce kapatılan not (kaldığın karta dönüş).
  final String? anchorNoteId;

  static DashboardPaneScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DashboardPaneScope>();

  static bool singleColumnOf(BuildContext context) =>
      maybeOf(context)?.singleColumn ?? false;

  @override
  // Çapa yalnız sütun kipi değişirken okunur (DashboardScreen
  // `didChangeDependencies`). Tek başına değişince (açık nottan başka nota
  // geçiş) bildirilmez: bütün pano boşuna kuruluyordu (F68.2, bütçe S12b).
  bool updateShouldNotify(DashboardPaneScope oldWidget) =>
      singleColumn != oldWidget.singleColumn;
}

/// Not açıkken sol listenin varsayılan genişliği (tek sütun kart).
const double _defaultNotePaneWidth = 320;

/// Not açıkken sol panel genişliği — liste kipindekinden AYRI saklanır:
/// tek sütunluk dar liste ile geniş ızgara aynı tercihi paylaşamaz.
final notePaneWidthProvider = NotifierProvider<NotePaneWidthNotifier, double>(
  NotePaneWidthNotifier.new,
);

class NotePaneWidthNotifier extends Notifier<double> {
  static const _key = 'note_pane_width';

  @override
  double build() =>
      ref.watch(sharedPreferencesProvider).getDouble(_key) ??
      _defaultNotePaneWidth;

  void set(double value) {
    state = value;
    ref.read(sharedPreferencesProvider).setDouble(_key, value);
  }
}

const double _minListPaneWidth = 260;

/// Notun en dar hâli (bkz. [kNoteSplitBreakpoint]); ayraç sona kadar itilip
/// editör görünmez hâle gelmesin.
const double _minNoteDetailWidth = 380;

/// Pencerede DİKEY bir menteşe/kıvrım (katlanabilir telefon açık, kitap
/// gibi tutulmuş) varsa onun alanı; yoksa `null`. Yatay kıvrım (masa üstü
/// duruşu) yan yana düzeni etkilemez.
Rect? verticalHingeOf(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  for (final f in MediaQuery.displayFeaturesOf(context)) {
    if (f.type == DisplayFeatureType.cutout) continue;
    final b = f.bounds;
    // Dikey: kıvrım ekranın boyunca uzanır ve iki yanda yer kalır.
    final vertical = b.height >= size.height * 0.9 && b.width < size.width / 4;
    if (vertical && b.left > 0 && b.right < size.width) return b;
  }
  return null;
}

/// **ODAK MODU** — liste paneli gizli mi (kullanıcı isteği 2026-09-22,
/// geniş ekran tasarımı). Uzun bir notu yazarken ya da PDF'in yanında not
/// alırken listenin kapladığı üçte bir ekran geri kazanılır. Ray'daki
/// düğme ve Ctrl+\ ile açılıp kapanır; tercih kalıcıdır.
final listPaneCollapsedProvider = boolPref(
  'list_pane_collapsed',
  defaultValue: false,
);

/// **NOT TAM EKRAN** (kullanıcı isteği 2026-11-02: "üç parçalı görünümde not
/// tam ekran olmuyor"): ray ve liste geçici olarak kalkar, sistem çubukları
/// gizlenir. Kalıcı değil: not kapanınca biter (bkz. editörün `dispose`u).
final noteFullscreenProvider = NotifierProvider<NoteFullscreenNotifier, bool>(
  NoteFullscreenNotifier.new,
);

class NoteFullscreenNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) {
    if (!ref.mounted || value == state) return;
    state = value;
    unawaited(value ? ImmersiveNote.enter() : ImmersiveNote.exit());
  }
}

/// Geniş ekranda solda not listesi, sağda açık not gösterir.
///
/// **Dar ekranda hiçbir şey değişmez** — [child] tek başına döner, yani telefon
/// davranışı birebir korunur. Bu, düzenin tüm riskini geniş ekrana hapseder.
///
/// URL'ler olduğu gibi kalır (`/` ve `/note/:id`), böylece derin bağlantılar ve
/// tarayıcı geri tuşu bozulmaz.
///
/// Sağ panel HER ZAMAN [child]'ı çizer. Önceki sürüm burada
/// `state.matchedLocation.startsWith('/note/')` ile karar veriyordu ama
/// ShellRoute builder'ına KABUK rotasının eşleşmesi geliyor, alt rotanın tam
/// yolu değil — koşul hiç tutmuyor, not açılsa da sağ panel yer tutucuda
/// kalıyordu. Yer tutucuyu artık `/` rotasının kendisi üretiyor (bkz. router).
class SplitShell extends ConsumerStatefulWidget {
  const SplitShell({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<SplitShell> createState() => _SplitShellState();
}

class _SplitShellState extends ConsumerState<SplitShell>
    with SingleTickerProviderStateMixin {
  /// **NOTTAN GERİ DÖNÜŞ GEÇİŞİ** (kullanıcı bulgusu 2026-11-13: "tablette
  /// nottan geri yapıp ana sayfaya dönerken animasyon eksik"). Bölünmüş
  /// düzende not kapanınca liste tek karede tam genişliğe atlıyordu (rota
  /// geçişi yok: aynı kabuk). Artık liste kısa bir solma + kayma ile gelir.
  /// YALNIZ BOYAMA (FadeTransition + SlideTransition = FractionalTranslation):
  /// boy/yerleşim canlandırılmaz, ağaç şekli sabit (CLAUDE kasma listesi 4, 6).
  late final AnimationController _back = AnimationController(
    vsync: this,
    duration: AppMotion.medium,
    value: 1,
  );
  late final Animation<double> _backCurve = CurvedAnimation(
    parent: _back,
    curve: AppMotion.enter,
  );
  late final Animation<Offset> _backSlide = Tween<Offset>(
    begin: const Offset(0.04, 0),
    end: Offset.zero,
  ).animate(_backCurve);
  late final Animation<double> _backFade = Tween<double>(
    begin: 0.35,
    end: 1,
  ).animate(_backCurve);
  bool _wasNoteOpen = false;

  /// **KAPANIŞTA BÖLME YERİNDE BEKLER** (P59, kullanıcı 2026-11-14: "web'de ve
  /// tablette nottan listeye dönüşte animasyon yok"). KÖK NEDEN: rota `/`
  /// olur olmaz sağ bölme sıfır genişliğe iniyordu — notun çıkış geçişi
  /// (rotanın kendi geçişi) sıfır genişlikte oynuyor, görünmüyordu. Artık
  /// geçiş süresince düzen eski hâlinde kalır (not bölmesinde kayarak/solarak
  /// çıkar), sonra liste TEK ADIMDA tam genişliğe geçer ve [_back] solması
  /// oynar. Boy canlandırılmaz (kasma listesi 6), ağaç şekli sabit.
  Timer? _closing;

  /// Rotanın geri dönüş geçişiyle aynı (MaterialRoute 300 ms).
  static const _kCloseHold = AppMotion.medium;

  @override
  void dispose() {
    _closing?.cancel();
    _back.dispose();
    super.dispose();
  }

  /// Sürükleme sürerken kullanılan geçici genişlik.
  ///
  /// Sürüklemenin her karesinde provider'ı güncelleyip SharedPreferences'a
  /// yazmak diske I/O bindiriyordu; ayraç parmağın/farenin gerisinde
  /// kalıyordu ("çok zor ve yavaş"). Artık sürükleme yerel setState ile akar,
  /// kalıcı kayıt yalnızca BIRAKINCA bir kez yapılır.
  double? _dragWidth;

  /// Yandaki not ayracı sürüklenirken geçici pay (bkz. [_dragWidth]).
  double? _dragFraction;

  /// Yandaki bölmenin widget'ı AYNI örnek kalır: kabuk klavye karelerinde
  /// (dış Scaffold boyu) yeniden kurulduğunda yeni örnek yandaki editörü
  /// her karede kuruyordu (S27 klavye: 24 gövde kurulumu → 0).
  SecondNote? _paneFor;
  Widget? _pane;

  Widget _secondPane(SecondNote second) {
    if (!identical(second, _paneFor)) {
      _paneFor = second;
      _pane = SecondNotePane(
        close: ref.read(secondNoteProvider.notifier).close,
        child: NoteEditorScreen(
          key: ValueKey('note-${second.id}'),
          noteId: second.id,
          ownerId: second.ownerId,
          readOnly: second.readOnly,
        ),
      );
    }
    return _pane!;
  }

  /// Son açık notun kimliği: not kapanınca liste o karta döner.
  String? _lastNoteId;

  /// **ÇEKEREK TAM EKRAN** (kullanıcı isteği 2026-11-02: "tam ekran yapmak
  /// çok daha kolay olsun; sürükleyici sola doğru azıcık zorlayınca tam
  /// ekrana geçilebilsin — görseli sabitlemedeki basılı tut-bırak gibi").
  /// Ayraç listenin en dar hâlinden sola itildikçe liste lastik gibi biraz
  /// daha daralır; [_kFullscreenPull] aşılınca ipucu "Bırak: tam ekran" olur
  /// ve bırakınca not tam ekrana geçer. Eşiğin gerisinde bırakılırsa hiçbir
  /// şey olmaz (yalnız genişlik ayarı).
  double _overPull = 0;
  bool get _armed => _overPull >= _kFullscreenPull;

  @override
  Widget build(BuildContext context) {
    final router = GoRouter.of(context);
    return ListenableBuilder(
      listenable: router.routerDelegate,
      builder: (context, _) {
        final location = currentLocation(router);
        final routeNoteOpen = isNoteLocation(location);
        final animated = !MediaQuery.disableAnimationsOf(context);
        if (routeNoteOpen) {
          _closing?.cancel();
          _closing = null;
        } else if (_wasNoteOpen) {
          if (animated && splitActiveFor(MediaQuery.sizeOf(context))) {
            _closing = Timer(_kCloseHold, () {
              if (!mounted) return;
              setState(() => _closing = null);
              _back.forward(from: 0);
            });
          } else if (animated) {
            _back.forward(from: 0);
          }
        }
        _wasNoteOpen = routeNoteOpen;
        // Kapanış geçişi sürerken düzen "not açık" kalır.
        final noteOpen = routeNoteOpen || _closing != null;
        final primaryId = location.startsWith('/note/')
            ? location.substring('/note/'.length)
            : null;
        if (primaryId != null) _lastNoteId = primaryId;
        // YANDAKİ NOT (K32): birincil kapanınca (kapanış geçişi bitince) ya
        // da birincil yandaki nota geçince bölme kapanır — aynı not iki
        // editörde açık kalmaz (`text_merge` yankı çakışması).
        final second = ref.watch(secondNoteProvider);
        final secondLive = second != null && noteOpen && second.id != primaryId;
        if (second != null && !secondLive) {
          scheduleMicrotask(() {
            if (mounted) ref.read(secondNoteProvider.notifier).close();
          });
        }
        if (!splitActiveFor(MediaQuery.sizeOf(context))) {
          return SplitScope(
            active: false,
            singleColumn: false,
            child: widget.child,
          );
        }
        return LayoutBuilder(
          builder: (context, box) => _layout(
            context,
            box,
            location: location,
            noteOpen: noteOpen,
            second: secondLive ? second : null,
          ),
        );
      },
    );
  }

  Widget _layout(
    BuildContext context,
    BoxConstraints box, {
    required String location,
    required bool noteOpen,
    required SecondNote? second,
  }) {
    final total = MediaQuery.sizeOf(context).width;
    // Pencere daralınca saklanan genişlik sağ panele yer bırakmayabilir.
    final maxPane = (total - _minNoteDetailWidth).clamp(
      _minListPaneWidth,
      double.infinity,
    );
    // KATLANABİLİR (2026-11-02): dikey menteşe varsa ayraç menteşeye
    // oturur — liste bir yarıda, not öbür yarıda; hiçbir şey kıvrımın
    // altında kalmaz. Kullanıcı sürüklerse onun seçimi geçerli.
    final hinge = verticalHingeOf(context);
    // LİSTE SAĞDA (F67.9): genişlik pencerenin sağ kenarından ölçülür.
    final right = ref.watch(listPaneRightProvider);
    final hingeWidth = hinge == null || _dragWidth != null
        ? null
        : (right ? total - hinge.center.dx : hinge.center.dx) -
              _dividerWidth / 2;
    // Not yokken liste TAM genişlik (sağda yer tutucu yok — kullanıcı
    // isteği 2026-11-02). Aynı sol panel örneği genişler: arama, süzgeç
    // ve kaydırma not açılıp kapanınca korunur.
    final double stored = ref.watch(notePaneWidthProvider);
    final double noteWidth = _dragWidth ?? hingeWidth ?? stored;
    // Açık not yokken liste gizlenmez: gizli liste + boş sağ panel,
    // kullanıcıya hiçbir şey göstermeyen bir ekran olurdu.
    final window = MediaQuery.sizeOf(context);
    final listWidth = noteWidth.clamp(_minListPaneWidth, maxPane);
    // İKİ NOT (K32 karar 4): üçü sığmıyorsa liste kendiliğinden çekilir —
    // dikey tabletteki ☰ "göz atma" düzeni aynen.
    final twoNotes = twoNoteLayoutFor(
      content: box.maxWidth,
      list: listWidth,
      landscape: window.width > window.height,
      secondOpen: second != null,
    );
    final twoOnly = twoNotes == TwoNoteLayout.twoOnly;
    final autoHides =
        listAutoHidesFor(window, hasHinge: hinge != null) || twoOnly;
    final fullscreen = ref.watch(noteFullscreenProvider);
    final peeking = ref.watch(listPeekLocationProvider) == location;
    final collapsed =
        (ref.watch(listPaneCollapsedProvider) ||
            fullscreen ||
            (autoHides && !peeking)) &&
        noteOpen;
    // Tam ekranda ve ☰ göz atmada yandaki not GİZLENİR (Offstage, State
    // korunur); sığmıyorsa hiç kurulmaz (editör dispose'ta kaydeder).
    final showSecond =
        twoNotes != TwoNoteLayout.off && !fullscreen && !(twoOnly && peeking);
    // **GİZLİ LİSTE KAPANIŞ DÜZENİNDE BEKLER** (ölçüm 2026-11-10, dikey
    // tablet: not kapanışında 108 ms'lik kare — LAYOUT 85 ms). Liste not
    // açıkken gizliyken de DAR ve tek sütun tutuluyordu; not kapanınca
    // tam genişliğe, çok sütuna geçip bütün kartları yeniden kuruyordu.
    // Kendiliğinden gizlenen (dikey tablet, animasyonsuz) liste gizliyken
    // tam genişlikte kalır: kapanışta hiçbir şey yeniden dizilmez. ☰ ile
    // açılınca daralır. Odak/tam ekran (yatay, 240 ms daralma) eskisi gibi
    // dar kalır — daralırken tam genişlik kırpılmış görünmesin.
    final listNarrow = noteOpen && !(collapsed && autoHides);
    final paneWidth = listNarrow ? listWidth : null;
    return SplitScope(
      active: true,
      singleColumn: noteOpen,
      listHidden: collapsed,
      listAutoHides: autoHides && noteOpen,
      twoNotesFit:
          noteOpen &&
          twoNotesFit(
            content: box.maxWidth,
            landscape: window.width > window.height,
          ),
      child: _split(
        context,
        box,
        paneWidth,
        maxPane,
        collapsed,
        noteOpen,
        listNarrow: listNarrow,
        animate: !autoHides,
        right: right,
        second: twoNotes == TwoNoteLayout.off ? null : second,
        showSecond: showSecond,
      ),
    );
  }

  Widget _split(
    BuildContext context,
    BoxConstraints box,
    double? notePaneWidth,
    double maxPane,
    bool collapsed,
    bool noteOpen, {
    required bool listNarrow,
    required bool animate,
    required bool right,
    required SecondNote? second,
    required bool showSecond,
  }) {
    final total = MediaQuery.sizeOf(context).width;
    // Liste sağdaysa Row ters dizilir; çocuk SIRASI aynı kalır — liste ve
    // not State'i yön değişince korunur.
    final ambient = Directionality.of(context);
    final rowDirection = right
        ? (ambient == TextDirection.ltr ? TextDirection.rtl : TextDirection.ltr)
        : ambient;
    return Scaffold(
      // **KLAVYEDE KABUK KISALMAZ** (tablet bulgusu 2026-11-09, ekran
      // görüntüsü: yazarken soldaki ev/klasör/mikrofon/+ düğmeleri listenin
      // üstüne çıkıyordu). KÖK NEDEN: bu Scaffold gövdeyi klavye kadar
      // kısaltıyordu — listenin `removeViewInsets` sarması boşa düşüyordu,
      // çünkü kısalma ondan ÖNCE oluyordu. Klavye boşluğunu her bölme kendisi
      // verir: editör [KeyboardSnap] ile, liste hiç (not açıkken klavye
      // notun), defter kendi Scaffold'uyla.
      resizeToAvoidBottomInset: false,
      // Not yokken liste kabuğun TAM genişliği (ray düşülmüş hâli; pencere
      // genişliği değil — LayoutBuilder).
      body: Builder(
        builder: (context) {
          final paneWidth = notePaneWidth ?? box.maxWidth;
          // Not alanı (liste ve ayracı düşülmüş); yandaki not bunun payı.
          final noteArea =
              box.maxWidth - (collapsed ? 0 : paneWidth + _dividerWidth);
          final split = noteArea - _dividerWidth;
          final double fraction =
              _dragFraction ?? ref.watch(secondNoteFractionProvider);
          final secondWidth = (split * fraction)
              .clamp(
                kSecondNoteMinWidth,
                max(kSecondNoteMinWidth, split - kSecondNoteMinWidth),
              )
              .toDouble();
          return Row(
            textDirection: rowDirection,
            children: [
              // ShellRoute sol paneli rota değişse de aynı konumda tuttuğu için
              // DashboardScreen'in State'i korunur — not değiştirince liste
              // başa sarmaz.
              //
              // ODAK MODUNDA liste ağaçtan ÇIKARILMAZ, yalnız genişliği sıfıra
              // akar: ağaçtan çıksaydı kaydırma konumu ve arama kutusu sıfırlanırdı.
              // Liste hep kendi genişliğinde ölçülür (SizedBox), yalnız
              // görünen kısmı daralır — ızgara her karede yeniden dizilmez.
              TweenAnimationBuilder<double>(
                tween: Tween<double>(end: collapsed ? 0 : 1),
                // Dikey tablette not açılış geçişiyle üst üste binmesin: not
                // alanı her karede yeniden yerleşirdi (F44.7).
                duration: animate
                    ? const Duration(milliseconds: 240)
                    : Duration.zero,
                curve: Curves.easeInOutCubic,
                child: SizedBox(
                  width: paneWidth,
                  child: DashboardPaneScope(
                    singleColumn: listNarrow,
                    anchorNoteId: _lastNoteId,
                    // Not açıkken klavye NOTUN: liste daralıp düğmeleri
                    // kartların üstüne itmesin (tablet bulgusu 2026-11-07).
                    // Sarma HEP var (ağaç şekli sabit, liste State'i korunur).
                    child: MediaQuery.removeViewInsets(
                      context: context,
                      removeBottom: noteOpen,
                      child: FadeTransition(
                        opacity: _backFade,
                        child: SlideTransition(
                          position: _backSlide,
                          textDirection: rowDirection,
                          child: const DashboardScreen(),
                        ),
                      ),
                    ),
                  ),
                ),
                builder: (context, open, pane) => ClipRect(
                  child: Align(
                    // Ayraç tarafına yaslı: liste dış kenara doğru çekilir.
                    alignment: right
                        ? AlignmentDirectional.centerStart
                        : AlignmentDirectional.centerEnd,
                    // Lastik: en dar hâlden sonra itiş görünür daralma verir
                    // (çekişin üçte biri kadar), liste yeniden dizilmez.
                    widthFactor:
                        open *
                        (1 - (_overPull / 3) / paneWidth).clamp(0.5, 1.0),
                    // Ağaç şekli sabit (Offstage hep var): State korunur.
                    child: Offstage(offstage: open == 0, child: pane),
                  ),
                ),
              ),
              if (noteOpen && !collapsed)
                _PaneDivider(
                  // Delta DEĞİL mutlak konum: fare bir karede birden çok sürükleme
                  // olayı üretebiliyor ve hepsi build'de yakalanmış aynı eski
                  // genişliğe eklendiğinden yalnız sonuncusu işe yarıyordu — panel
                  // farenin gerisinde kalıyordu. İmlecin x'ini doğrudan kullanmak
                  // kare zamanlamasından tamamen bağımsız.
                  onDrag: (globalX) {
                    final raw =
                        (right ? box.maxWidth - globalX : globalX) -
                        _dividerWidth / 2;
                    final over = (_minListPaneWidth - raw).clamp(0.0, 200.0);
                    final wasArmed = _armed;
                    setState(() {
                      _overPull = over;
                      _dragWidth = raw.clamp(_minListPaneWidth, maxPane);
                    });
                    if (_armed != wasArmed) AppHaptics.heavy();
                  },
                  onDragEnd: () {
                    if (_armed) {
                      setState(() {
                        _overPull = 0;
                        _dragWidth = null;
                      });
                      ref.read(noteFullscreenProvider.notifier).set(true);
                      return;
                    }
                    _overPull = 0;
                    final width = _dragWidth;
                    if (width != null) {
                      ref.read(notePaneWidthProvider.notifier).set(width);
                    }
                    setState(() => _dragWidth = null);
                  },
                  // Çift tık: varsayılan genişlik (kalıcı tercih de).
                  onReset: () => ref
                      .read(notePaneWidthProvider.notifier)
                      .set(_defaultNotePaneWidth),
                  // Uzun bas: listeyi öbür yana al (F67.9).
                  onMoveSide: () =>
                      ref.read(listPaneRightProvider.notifier).set(!right),
                  moveSideLabel: right
                      ? context.l10n.listPaneMoveLeft
                      : context.l10n.listPaneMoveRight,
                ),
              Expanded(
                child: Stack(
                  children: [
                    widget.child,
                    if (_overPull > 0)
                      PositionedDirectional(
                        start: right ? null : 12,
                        end: right ? 12 : null,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: _FullscreenPullHint(
                            progress: (_overPull / _kFullscreenPull).clamp(
                              0,
                              1,
                            ),
                            armed: _armed,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // YANDAKİ NOT (K32): iki çocuk HEP var (ağaç şekli sabit, kasma
              // listesi 4); genişlik tek adımda değişir (animasyon yok, 6).
              // İç gezgin YOK: editör doğrudan gömülür, alt sayfaları
              // kabuğun gezginine açılır.
              SizedBox(
                width: showSecond ? _dividerWidth : 0,
                child: showSecond
                    ? _PaneDivider(
                        onDrag: (globalX) {
                          final w = right
                              ? globalX - (total - box.maxWidth)
                              : total - globalX;
                          setState(
                            () => _dragFraction =
                                ((w - _dividerWidth / 2) / split).clamp(
                                  0.3,
                                  0.7,
                                ),
                          );
                        },
                        onDragEnd: () {
                          final f = _dragFraction;
                          if (f != null) {
                            ref
                                .read(secondNoteFractionProvider.notifier)
                                .set(f);
                          }
                          setState(() => _dragFraction = null);
                        },
                        onReset: () => ref
                            .read(secondNoteFractionProvider.notifier)
                            .set(0.5),
                      )
                    : null,
              ),
              SizedBox(
                width: showSecond ? secondWidth : 0,
                child: Offstage(
                  offstage: !showSecond,
                  child: second == null
                      ? const SizedBox.shrink()
                      : _secondPane(second),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Tam ekrana geçmek için ayracın en dar hâlden SOLA itilmesi gereken pay.
const double _kFullscreenPull = 56;

/// Ayraç itilirken notun sol kenarında beliren ipucu: dolan halka + "Tam
/// ekran için çek" → eşikte "Bırak: tam ekran".
class _FullscreenPullHint extends StatelessWidget {
  const _FullscreenPullHint({required this.progress, required this.armed});

  final double progress;
  final bool armed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return IgnorePointer(
      child: AnimatedContainer(
        key: const ValueKey('fullscreen-pull-hint'),
        duration: AppMotion.of(context, AppMotion.quick),
        padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
        decoration: BoxDecoration(
          color: armed
              ? scheme.primary
              : scheme.inverseSurface.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 2.5,
                    color: armed ? scheme.onPrimary : scheme.onInverseSurface,
                  ),
                  Icon(
                    Icons.fullscreen_rounded,
                    size: 14,
                    color: armed ? scheme.onPrimary : scheme.onInverseSurface,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              armed ? l10n.fullscreenPullRelease : l10n.fullscreenPullHint,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: armed ? scheme.onPrimary : scheme.onInverseSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ayracın tutma genişliği. Çizgi ince görünür ama 16 px'lik alandan
/// yakalanır — 1 px'lik çizgiyi fareyle tutmak zor olurdu.
// Parmakla tutulabilsin (tablet bulgusu 2026-11-09: "sol paneli parmakla
// genişletebilmeliyim"): 16 dp'lik görünmez şerit parmağa dar geliyordu.
const double _dividerWidth = 24;

/// Sürüklenebilir ayraç. [onDrag] imlecin MUTLAK x konumunu verir (delta
/// değil); nedeni SplitShell'deki nota bakılabilir.
class _PaneDivider extends StatefulWidget {
  const _PaneDivider({
    required this.onDrag,
    required this.onDragEnd,
    required this.onReset,
    this.onMoveSide,
    this.moveSideLabel,
  });

  /// Uzun basış menüsünün tek maddesi: listeyi öbür yana al (yoksa menü yok).
  final VoidCallback? onMoveSide;
  final String? moveSideLabel;

  final void Function(double globalX) onDrag;
  final VoidCallback onDragEnd;

  /// Çift tık: varsayılan genişliğe dön.
  final VoidCallback onReset;

  @override
  State<_PaneDivider> createState() => _PaneDividerState();
}

class _PaneDividerState extends State<_PaneDivider> {
  bool _hovering = false;
  bool _dragging = false;

  Future<void> _sideMenu(Offset at) async {
    final label = widget.moveSideLabel;
    if (label == null) return;
    final picked = await showMenu<bool>(
      context: context,
      position: RelativeRect.fromLTRB(at.dx, at.dy, at.dx, at.dy),
      items: [
        PopupMenuItem(
          key: const ValueKey('list-pane-side'),
          value: true,
          child: Text(label),
        ),
      ],
    );
    if (picked == true) widget.onMoveSide?.call();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = _hovering || _dragging;
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onDoubleTap: widget.onReset,
        onLongPressStart: (d) => unawaited(_sideMenu(d.globalPosition)),
        // Fare: sağ tık aynı menü.
        onSecondaryTapUp: (d) => unawaited(_sideMenu(d.globalPosition)),
        // Fare imleci pikselden piksele atlar; `pan` yerine yatay sürükleme
        // kullanmak dikey kaydırmayı ayraca kaptırmamak için.
        onHorizontalDragStart: (_) => setState(() => _dragging = true),
        onHorizontalDragUpdate: (d) => widget.onDrag(d.globalPosition.dx),
        onHorizontalDragEnd: (_) {
          setState(() => _dragging = false);
          widget.onDragEnd();
        },
        child: SizedBox(
          width: _dividerWidth,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedContainer(
                duration: AppMotion.of(context, AppMotion.quick),
                width: active ? 4 : 1,
                color: active ? scheme.primary : scheme.outlineVariant,
              ),
              // TUTAMAK: ayracın sürüklenebildiği görünsün (dokunmatik
              // ekranda fare imleci değişimi yok).
              Container(
                width: 6,
                height: 40,
                decoration: BoxDecoration(
                  color: active ? scheme.primary : scheme.outline,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
