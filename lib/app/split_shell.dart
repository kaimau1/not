import 'dart:async';
import 'dart:ui' show DisplayFeatureType;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/l10n_ext.dart';
import '../core/utils/immersive.dart';
import '../features/notes/presentation/dashboard_screen.dart';
import '../features/settings/settings_providers.dart';
import 'app_commands.dart';

/// Ana-detay düzenine geçiş genişliği — İÇERİK alanının genişliği (geniş
/// ekranda gezinme rayı düşülmüş hâli, bkz. AppFrame).
///
/// 900 → 840 (2026-09-22, geniş ekran tasarımı): Material 3'ün "geniş"
/// pencere sınıfı. Ray eklenince 1024 dp'lik yatay tabletin içerik alanı
/// ~940'a iniyor; 900 sınırı küçük tabletleri tek panele düşürme riskine
/// çok yakındı. 840'ta liste (260–380) + editör (≥ 360) hâlâ sığıyor. Dikey
/// tablet (~800) ve telefon tek panelde kalır.
const double kSplitBreakpoint = 840;

/// **NOT AÇIKKEN** ana-detay sınırı (kullanıcı isteği 2026-11-02: "tablet
/// modunda not açılınca direkt ekranı kapladı; soldaki dashboard en soldaki
/// menünün yerine gelsin, tek sütunluk olsun, menü gizlensin"). Not açıkken
/// ray çekmeceye döner (bkz. AppFrame) ve liste tek sütuna iner; dikey tablet
/// (~800 dp) ve açık katlanabilir (~670 dp) de listeyle notu yan yana
/// gösterebilir: 260 dp liste + ≥ 380 dp not.
const double kNoteSplitBreakpoint = 640;

/// Konum bir not/defter ekranı mı (kabuğun içinden açılmış)?
bool isNoteLocation(String path) =>
    path.startsWith('/note/') || path.startsWith('/notebook/');

/// Liste kabuğun sol panelinde mi çizilecek? [width] kabuğun genişliği.
///
/// Not açık olsun olmasın aynı sınır (2026-11-02): not yokken sol panel tam
/// genişliğe yayılır, not açılınca daralır. Liste hep AYNI örnek kalır —
/// eskiden not yokken `/` rotası ikinci bir örnek kuruyordu, not açılıp
/// kapanınca arama/kaydırma sıfırlanıyordu.
bool splitActiveFor(double width) => width >= kNoteSplitBreakpoint;

/// Kabuğun ŞU AN listeyi sol panelde çizip çizmediği ve listenin tek sütun
/// olup olmadığı. `/` rotası buna bakar: etkinken liste zaten solda, rota
/// hiçbir şey çizmez.
class SplitScope extends InheritedWidget {
  const SplitScope({
    super.key,
    required this.active,
    required this.singleColumn,
    required super.child,
  });

  final bool active;

  /// Sol paneldeki liste tek sütun çizilsin (not açık).
  final bool singleColumn;

  static SplitScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SplitScope>();

  static bool activeOf(BuildContext context) =>
      maybeOf(context)?.active ?? false;

  @override
  bool updateShouldNotify(SplitScope oldWidget) =>
      active != oldWidget.active || singleColumn != oldWidget.singleColumn;
}

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
  bool updateShouldNotify(DashboardPaneScope oldWidget) =>
      singleColumn != oldWidget.singleColumn ||
      anchorNoteId != oldWidget.anchorNoteId;
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

class _SplitShellState extends ConsumerState<SplitShell> {
  /// Sürükleme sürerken kullanılan geçici genişlik.
  ///
  /// Sürüklemenin her karesinde provider'ı güncelleyip SharedPreferences'a
  /// yazmak diske I/O bindiriyordu; ayraç parmağın/farenin gerisinde
  /// kalıyordu ("çok zor ve yavaş"). Artık sürükleme yerel setState ile akar,
  /// kalıcı kayıt yalnızca BIRAKINCA bir kez yapılır.
  double? _dragWidth;

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
    final total = MediaQuery.sizeOf(context).width;
    final router = GoRouter.of(context);
    return ListenableBuilder(
      listenable: router.routerDelegate,
      builder: (context, _) {
        final location = currentLocation(router);
        final noteOpen = isNoteLocation(location);
        if (location.startsWith('/note/')) {
          _lastNoteId = location.substring('/note/'.length);
        }
        if (!splitActiveFor(total)) {
          return SplitScope(
            active: false,
            singleColumn: false,
            child: widget.child,
          );
        }
        // Pencere daralınca saklanan genişlik sağ panele yer bırakmayabilir.
        final maxPane = (total - _minNoteDetailWidth).clamp(
          _minListPaneWidth,
          double.infinity,
        );
        // KATLANABİLİR (2026-11-02): dikey menteşe varsa ayraç menteşeye
        // oturur — liste bir yarıda, not öbür yarıda; hiçbir şey kıvrımın
        // altında kalmaz. Kullanıcı sürüklerse onun seçimi geçerli.
        final hinge = verticalHingeOf(context);
        final hingeWidth = hinge == null || _dragWidth != null
            ? null
            : hinge.center.dx - _dividerWidth / 2;
        // Not yokken liste TAM genişlik (sağda yer tutucu yok — kullanıcı
        // isteği 2026-11-02). Aynı sol panel örneği genişler: arama, süzgeç
        // ve kaydırma not açılıp kapanınca korunur.
        final double stored = ref.watch(notePaneWidthProvider);
        final double noteWidth = _dragWidth ?? hingeWidth ?? stored;
        final paneWidth = noteOpen
            ? noteWidth.clamp(_minListPaneWidth, maxPane)
            : null;
        // Açık not yokken liste gizlenmez: gizli liste + boş sağ panel,
        // kullanıcıya hiçbir şey göstermeyen bir ekran olurdu.
        final collapsed =
            (ref.watch(listPaneCollapsedProvider) ||
                ref.watch(noteFullscreenProvider)) &&
            noteOpen;
        return SplitScope(
          active: true,
          singleColumn: noteOpen,
          child: _split(context, paneWidth, maxPane, collapsed, noteOpen),
        );
      },
    );
  }

  Widget _split(
    BuildContext context,
    double? notePaneWidth,
    double maxPane,
    bool collapsed,
    bool noteOpen,
  ) {
    return Scaffold(
      // Not yokken liste kabuğun TAM genişliği (ray düşülmüş hâli; pencere
      // genişliği değil — LayoutBuilder).
      body: LayoutBuilder(
        builder: (context, box) {
          final paneWidth = notePaneWidth ?? box.maxWidth;
          return Row(
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
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeInOutCubic,
                child: SizedBox(
                  width: paneWidth,
                  child: DashboardPaneScope(
                    singleColumn: noteOpen,
                    anchorNoteId: _lastNoteId,
                    child: const DashboardScreen(),
                  ),
                ),
                builder: (context, open, pane) => ClipRect(
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
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
                    final raw = globalX - _dividerWidth / 2;
                    final over = (_minListPaneWidth - raw).clamp(0.0, 200.0);
                    final wasArmed = _armed;
                    setState(() {
                      _overPull = over;
                      _dragWidth = raw.clamp(_minListPaneWidth, maxPane);
                    });
                    if (_armed != wasArmed) HapticFeedback.mediumImpact();
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
                ),
              Expanded(
                child: Stack(
                  children: [
                    widget.child,
                    if (_overPull > 0)
                      PositionedDirectional(
                        start: 12,
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
        duration: const Duration(milliseconds: 150),
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
const double _dividerWidth = 16;

/// Sürüklenebilir ayraç. [onDrag] imlecin MUTLAK x konumunu verir (delta
/// değil); nedeni SplitShell'deki nota bakılabilir.
class _PaneDivider extends StatefulWidget {
  const _PaneDivider({required this.onDrag, required this.onDragEnd});

  final void Function(double globalX) onDrag;
  final VoidCallback onDragEnd;

  @override
  State<_PaneDivider> createState() => _PaneDividerState();
}

class _PaneDividerState extends State<_PaneDivider> {
  bool _hovering = false;
  bool _dragging = false;

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
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: active ? 4 : 1,
              color: active ? scheme.primary : scheme.outlineVariant,
            ),
          ),
        ),
      ),
    );
  }
}
