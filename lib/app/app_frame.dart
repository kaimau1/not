import '../features/auth/presentation/account_required.dart';
import '../features/auth/presentation/auth_providers.dart';
import 'dart:async';
import 'dart:ui' show DisplayFeature;

import '../core/app_icons.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/l10n_ext.dart';
import '../core/personalize.dart';
import '../core/widgets/customizable.dart';
import '../features/ai/data/ai_gate.dart';
import '../features/folders/data/folder_activity.dart';
import '../features/folders/domain/note_folder.dart';
import '../features/folders/presentation/shared_folder_home.dart';
import '../features/friends/presentation/friends_screen.dart';
import '../features/notes/presentation/notes_providers.dart';
import '../features/notes/presentation/quick_add_fab.dart';
import '../features/settings/settings_providers.dart';
import 'app_commands.dart';
import 'router.dart' show kOutsideShellNotePrefix;
import 'split_shell.dart';
import '../core/utils/web_ready.dart';

/// Gezinme rayının belirdiği genişlik (Material 3 "orta" pencere sınıfı):
/// tablet dikey, katlanabilir açık, web penceresi. Altında —
/// telefonda — hiçbir şey değişmez.
const double kRailBreakpoint = 600;

/// DAR RAYIN genişliği (kullanıcı isteği 2026-11-02: "tablette soldaki menü
/// daraltılmalı, çok yer kaplıyor"): Material'in 80 dp'si yerine 64, etiket
/// yok — adı ipucunda. Kendiliğinden etiketli açılış da 1280 → 1600.
const double kRailWidth = 64;

/// Rayın bölümleri: "Gelen ve paylaşılanlar" RAYDA YOK (aynı istek: "geleni
/// oradan çıkar, zaten ana ekranda var" — ana ekranın "Gelen" çipi).
final List<AppSection> railSections = [
  for (final s in AppSection.values)
    if (s != AppSection.inbox) s,
];

/// Rayın kendiliğinden ETİKETLİ (geniş) açıldığı genişlik. Kullanıcı elle
/// daraltıp genişletirse o seçim kalıcıdır (bkz. [railExtendedProvider]).
const double kRailAutoExtendBreakpoint = 1600;

/// Ray bu yükseklikten kısa pencerede çizilmez: yatay tutulan TELEFON 600 dp
/// genişliği aşıyor ama 360–420 dp yüksekliğe altı bölüm + düğmeler sığmıyor.
/// Telefonun davranışı yatayda da aynen korunur.
const double _minRailHeight = 500;

/// Ray elle genişletildi/daraltıldı mı? `null` = genişliğe göre otomatik.
final railExtendedProvider = NotifierProvider<RailExtendedNotifier, bool?>(
  RailExtendedNotifier.new,
);

class RailExtendedNotifier extends Notifier<bool?> {
  static const _key = 'rail_extended';

  @override
  bool? build() => ref.watch(sharedPreferencesProvider).getBool(_key);

  void set(bool value) {
    state = value;
    ref.read(sharedPreferencesProvider).setBool(_key, value);
  }
}

/// Gezinme rayı görünüyor mu? Rayın yanındaki ekranlar, rayda zaten duran
/// kapıları (Yapay Zekâ, Hatırlatıcılar, Arşiv, Çöp, Ayarlar, Yeni not)
/// kendi menülerinde TEKRARLAMASIN diye okur (F11.8).
class AppRailScope extends InheritedWidget {
  const AppRailScope({super.key, this.docked = true, required super.child});

  /// Ray gerçekten ekranda mı. Not açıkken ray çekmeceye döner, tam ekranda
  /// gizlidir: o durumda "rayda zaten var" diye menüden düşen kapılar (Ayarlar
  /// dahil) menüde KALMALI (F28.5: web'de ⋮ menüsünde Ayarlar yoktu).
  final bool docked;

  static bool visible(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<AppRailScope>()
          ?.docked ??
      false;

  @override
  bool updateShouldNotify(AppRailScope oldWidget) =>
      docked != oldWidget.docked;
}

/// **GENİŞ EKRAN ÇERÇEVESİ** — kullanıcı isteği 2026-09-22: "not
/// uygulamasının tablet gibi geniş ekranlı cihazlarda kullanımını baştan
/// tasarlamalıyız, onlara özel özellikler getirmeliyiz".
///
/// Oturum açıkken HER ekranı sarar (bkz. router'daki dış ShellRoute):
/// * Geniş ekranda solda kalıcı bir **gezinme rayı** — Notlar, Yapay Zekâ,
///   Hatırlatıcılar, Arşiv, Çöp, Ayarlar tek dokunuşta; tepesinde "Yeni not",
///   altında liste panelini gizleme, kişiler, kısayollar. Telefonda bu
///   bölümler ⋮ menüsünün içinde; geniş ekranda gizlemek yeri boşa harcıyordu.
/// * Her genişlikte **klavye kısayolları** (bkz. [AppShortcuts]) — fareli/
///   klavyeli tablet ve web için.
///
/// Dar ekranda [child] olduğu gibi döner; telefonun görünümü birebir aynı.
class AppFrame extends ConsumerWidget {
  const AppFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Oturum açık, ilk anlamlı ekran: web açılış katmanı kalkar (F10.6).
    signalWebReady();
    final size = MediaQuery.sizeOf(context);
    final showRail = _railFits(size);
    void toggleList() => toggleNoteListPane(context, ref);

    final fullscreen = ref.watch(noteFullscreenProvider);
    Widget content = child;
    if (showRail) {
      content = _RailFrame(
        showListToggle: size.width >= kSplitBreakpoint,
        fullscreen: fullscreen,
        child: child,
      );
    }
    if (!showRail && homeBarOnNarrow) {
      content = _NarrowHomeBar(child: content);
    }
    return AppShortcuts(
      onToggleList: toggleList,
      // Kısayollar odak ağacından geçer; hiçbir şey odaklı değilken (ayarlar
      // ekranı yeni açıldı) de çalışsınlar diye çerçeve kendisi odak alır.
      child: Focus(autofocus: true, skipTraversal: true, child: content),
    );
  }
}

/// Üst çubuğu [HomeInBar] ile 🏠 taşıyan konumlar (K5): buralarda şerit çizilmez.
/// Yeni bölüm ekranı: çubuğu [HomeInBar] ile sar + buraya yaz (test tarar).
const kHomeInBarLocations = [
  '/settings',
  '/personalize',
  '/privacy',
  '/guide',
  '/gmail',
  '/premium',
  '/ai',
  '/chat',
  '/briefing',
  '/cards',
  '/reminders',
  '/archive',
  '/trash',
  '/folders',
  '/inbox',
  '/note/',
  '/notebook/',
  '$kOutsideShellNotePrefix/',
];

bool hasHomeInBar(String location) =>
    kHomeInBarLocations.any(location.startsWith);

/// **Dar web'de üst çubuğun en solunda 🏠** (K5, F44.2). Çubuğun kendi geri oku
/// ve başlığı olduğu gibi kalır; [appBar] kalan genişliğe oturur. Telefon
/// uygulamasında ve rayın göründüğü pencerede [appBar]ın kendisi çizilir.
class HomeInBar extends ConsumerWidget implements PreferredSizeWidget {
  const HomeInBar({super.key, required this.appBar});

  final PreferredSizeWidget appBar;

  @override
  Size get preferredSize => appBar.preferredSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!homeBarOnNarrow || _railFits(MediaQuery.sizeOf(context))) return appBar;
    // Saydam: üst çubuğun zemini iskeleyle aynı (not rengi dahil).
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
          child: IconButton(
            key: const ValueKey('narrow-home'),
            tooltip: '${context.l10n.goHome} (Alt+Home)',
            icon: const Icon(Icons.home_outlined),
            onPressed: () => goHome(ref, GoRouter.of(context)),
          ),
        ),
        Expanded(child: appBar),
      ],
    );
  }
}

bool _railFits(Size window) =>
    window.width >= kRailBreakpoint && window.height >= _minRailHeight;

/// Dar web'de üst çubuğu olmayan ekranın üstünde ince çubuk: "Ana sayfaya dön"
/// (F28.3, K5). Çubuklu ekranlarda 🏠 çubuğun içinde ([HomeInBar]). Telefon
/// uygulamasında kapalı.
class _NarrowHomeBar extends ConsumerWidget {
  const _NarrowHomeBar({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = GoRouter.of(context);
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: router.routerDelegate,
      builder: (context, _) {
        final location = currentLocation(router);
        if (location == '/' || hasHomeInBar(location)) return child;
        final top = MediaQuery.paddingOf(context).top;
        return Column(
          children: [
            Material(
              color: scheme.surfaceContainerLow,
              child: Padding(
                padding: EdgeInsets.only(top: top),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    key: const ValueKey('narrow-home'),
                    onPressed: () => goHome(ref, router),
                    icon: const Icon(Icons.home_outlined, size: 18),
                    label: Text(context.l10n.goHome),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 36),
                      foregroundColor: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: child,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Ray + içerik. **Not açıkken ray ÇEKMECE olur** (kullanıcı isteği
/// 2026-11-02: "not açılınca soldaki dashboard en soldaki menünün yerine
/// gelsin, menü gizlensin, oradan çekilip açılan bir çekmece olsun"): sol
/// kenarda ince bir tutamak kalır; dokununca ya da kenardan sağa çekince ray
/// notun üstüne kayar. Liste rayın yerine geçer (bkz. kNoteSplitBreakpoint).
///
/// Ağaç şekli sabit (ray yuvası hep var, yalnız genişliği değişir): not
/// açılıp kapanırken ve tam ekrana geçerken içerik YENİDEN KURULMAZ.
class _RailFrame extends StatefulWidget {
  const _RailFrame({
    required this.showListToggle,
    required this.fullscreen,
    required this.child,
  });

  final bool showListToggle;
  final bool fullscreen;
  final Widget child;

  @override
  State<_RailFrame> createState() => _RailFrameState();
}

class _RailFrameState extends State<_RailFrame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drawer = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );

  /// Açık çekmece Esc'i alsın diye odak onda (çerçevenin kökü zaten odaklı,
  /// `autofocus` yetmiyor).
  final _drawerFocus = FocusNode(debugLabel: 'rail-drawer');

  /// Tam ekrandan çıkış jestinin sağa çekiş miktarı.
  double _exitPull = 0;

  @override
  void initState() {
    super.initState();
    _drawer.addStatusListener((status) {
      if (status == AnimationStatus.forward) _drawerFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _drawer.dispose();
    _drawerFocus.dispose();
    super.dispose();
  }

  void _close() {
    _drawerFocus.unfocus();
    unawaited(_drawer.reverse());
  }

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final router = GoRouter.of(context);
    return ListenableBuilder(
      listenable: router.routerDelegate,
      builder: (context, _) {
        final noteOpen = isNoteLocation(currentLocation(router));
        final docked = !widget.fullscreen && !noteOpen;
        if (docked && _drawer.value > 0) _drawer.value = 0;
        final canDrawer = noteOpen && !widget.fullscreen;
        return Stack(
          children: [
            Row(
              children: [
                if (docked)
                  _AppRail(showListToggle: widget.showListToggle)
                else
                  const SizedBox.shrink(),
                if (docked)
                  const VerticalDivider(width: 1, thickness: 1)
                else
                  const SizedBox.shrink(),
                Expanded(
                  // İçerik, pencerenin değil KENDİ alanının boyunu "ekran"
                  // sanmalı: ana-detay kararı (kSplitBreakpoint), sütun sayısı
                  // ve dar ekran kısayolları hep `MediaQuery.sizeOf` okuyor.
                  child: LayoutBuilder(
                    builder: (context, box) {
                      final window = MediaQuery.of(context);
                      // Menteşe/kıvrım PENCERE koordinatında gelir; içerik
                      // rayın sağından başlıyorsa kaydırılır (katlanabilir,
                      // bkz. verticalHingeOf).
                      final dx = rtl ? 0.0 : window.size.width - box.maxWidth;
                      return MediaQuery(
                        data: window.copyWith(
                          size: box.biggest,
                          displayFeatures: [
                            for (final f in window.displayFeatures)
                              DisplayFeature(
                                bounds: f.bounds.shift(Offset(-dx, 0)),
                                type: f.type,
                                state: f.state,
                              ),
                          ],
                        ),
                        // Rayın yanındaki ekran, kenar çentiği/sistem payını
                        // ikinci kez uygulamasın — o kenarı ray karşılıyor.
                        child: MediaQuery.removePadding(
                          context: context,
                          removeLeft: docked && !rtl,
                          removeRight: docked && rtl,
                          child: AppRailScope(docked: docked, child: widget.child),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            // TAM EKRANDAN ÇIKIŞ (2026-11-02): ayraçla sola çekip girilen tam
            // ekrandan sol kenardan sağa çekerek çıkılır — aynı jestin tersi.
            if (noteOpen && widget.fullscreen)
              PositionedDirectional(
                start: 0,
                top: 0,
                bottom: 0,
                width: 18,
                child: GestureDetector(
                  key: const ValueKey('fullscreen-exit-edge'),
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragStart: (_) => _exitPull = 0,
                  onHorizontalDragUpdate: (d) =>
                      _exitPull += rtl ? -d.delta.dx : d.delta.dx,
                  onHorizontalDragEnd: (d) {
                    final v = d.primaryVelocity ?? 0;
                    if (_exitPull > 56 || (rtl ? v < -300 : v > 300)) {
                      HapticFeedback.mediumImpact();
                      ProviderScope.containerOf(context)
                          .read(noteFullscreenProvider.notifier)
                          .set(false);
                    }
                  },
                ),
              ),
            if (canDrawer) ...[
              // Kenardan çekme + görünür tutamak.
              PositionedDirectional(
                start: 0,
                top: 0,
                bottom: 0,
                width: 14,
                child: GestureDetector(
                  key: const ValueKey('rail-drawer-edge'),
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragUpdate: (d) {
                    final delta = (rtl ? -d.delta.dx : d.delta.dx) / 240;
                    _drawer.value = (_drawer.value + delta).clamp(0, 1);
                  },
                  onHorizontalDragEnd: (d) {
                    final v = d.primaryVelocity ?? 0;
                    final open = rtl ? v < -200 : v > 200;
                    if (open || _drawer.value > 0.4) {
                      _drawer.forward();
                    } else {
                      _drawer.reverse();
                    }
                  },
                ),
              ),
              _DrawerHandle(onTap: _drawer.forward),
              AnimatedBuilder(
                animation: _drawer,
                builder: (context, _) {
                  final t = Curves.easeOutCubic.transform(_drawer.value);
                  if (t == 0) return const SizedBox.shrink();
                  final scheme = Theme.of(context).colorScheme;
                  // Açık çekmece geri tuşunu ve Esc'i önce kendisi alır.
                  return BackButtonListener(
                    onBackButtonPressed: () async {
                      _close();
                      return true;
                    },
                    child: CallbackShortcuts(
                      bindings: {
                        const SingleActivator(LogicalKeyboardKey.escape):
                            _close,
                      },
                      child: Focus(
                        focusNode: _drawerFocus,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: GestureDetector(
                                onTap: _close,
                                child: ColoredBox(
                                  color: Colors.black.withValues(
                                    alpha: 0.32 * t,
                                  ),
                                ),
                              ),
                            ),
                            PositionedDirectional(
                              start: 0,
                              top: 0,
                              bottom: 0,
                              child: FractionalTranslation(
                                translation: Offset(
                                  (rtl ? 1 : -1) * (1 - t),
                                  0,
                                ),
                                child: Material(
                                  elevation: 8,
                                  color: scheme.surfaceContainerLow,
                                  borderRadius:
                                      const BorderRadiusDirectional.horizontal(
                                        end: Radius.circular(20),
                                      ).resolve(Directionality.of(context)),
                                  clipBehavior: Clip.antiAlias,
                                  child: _AppRail(
                                    showListToggle: false,
                                    forceExtended: true,
                                    onNavigate: _close,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Çekmecenin sol kenardaki küçük tutamağı: notun yazısını örtmesin diye
/// ince ve soluk; dokunulabilir alanı 48 dp.
class _DrawerHandle extends StatelessWidget {
  const _DrawerHandle({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PositionedDirectional(
      start: 0,
      top: 0,
      bottom: 0,
      child: Center(
        child: Semantics(
          button: true,
          label: context.l10n.railExpand,
          child: Tooltip(
            message: context.l10n.railExpand,
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                key: const ValueKey('rail-drawer-handle'),
                onTap: onTap,
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(12),
                ),
                child: SizedBox(
                  width: 20,
                  height: 72,
                  child: Center(
                    child: Container(
                      width: 5,
                      height: 44,
                      decoration: BoxDecoration(
                        color: scheme.outline.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppRail extends ConsumerWidget {
  const _AppRail({
    required this.showListToggle,
    this.forceExtended = false,
    this.onNavigate,
  });

  /// Çekmece hâli: hep etiketli.
  final bool forceExtended;

  /// Bir bölüme gidilince (çekmeceyi kapatmak için).
  final VoidCallback? onNavigate;

  /// Liste panelini gizle/göster düğmesi yalnız ana-detay düzeninde
  /// ([kSplitBreakpoint] üstü) anlamlı.
  final bool showListToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = GoRouter.of(context);
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final extended =
        forceExtended ||
        (ref.watch(railExtendedProvider) ?? width >= kRailAutoExtendBreakpoint);
    void go(VoidCallback action) {
      onNavigate?.call();
      action();
    }

    final collapsed = ref.watch(listPaneCollapsedProvider);
    // Paylaşılan KLASÖRLERDE okunmamış hareket — geniş ekranda/web'de klasör
    // şeridi solda kalabalıkta kayboluyordu (kullanıcı bulgusu 2026-10-17:
    // "yeni bir şey geldiğinde anlaşılmıyor"). Ortak notlar artık Gelen ve
    // paylaşılanlar bölümünde sayılıyor.
    final sharedUnread = ref.watch(sharedUnreadTotalProvider);
    final aiLocked = ref.watch(aiAvailabilityProvider) != AiAvailability.ready;

    return ColoredBox(
      color: scheme.surfaceContainerLow,
      child: SafeArea(
        right: false,
        // KAYDIRILABİLİR: sekiz bölüm + alt düğmeler küçük tabletin yatayına
        // (~600 dp boy) sığmıyor. Yer varken düğmeler dibe yaslanır
        // (minHeight + IntrinsicHeight), yetmezse ray bütünüyle kayar.
        child: LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: box.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    Expanded(
                      // Konum imperatif push'larla da değişir; ray yönlendiricinin
                      // kendisini dinler (ShellRoute builder'ı alt rotanın tam yolunu
                      // vermiyor — bkz. SplitShell notu).
                      child: ListenableBuilder(
                        listenable: router.routerDelegate,
                        builder: (context, _) {
                          final section = AppSection.of(
                            currentLocation(router),
                          );
                          final index = railSections.indexOf(
                            section ?? AppSection.inbox,
                          );
                          return NavigationRail(
                            backgroundColor: Colors.transparent,
                            extended: extended,
                            minWidth: kRailWidth,
                            minExtendedWidth: 200,
                            labelType: NavigationRailLabelType.none,
                            selectedIndex: index < 0 ? null : index,
                            groupAlignment: -0.85,
                            // "Notlar" = ana sayfa (K4): açık not da kapanır,
                            // Alt+Home ile aynı. Ayrı 🏠 düğmesi kalktı.
                            onDestinationSelected: (i) => go(
                              () => railSections[i] == AppSection.notes
                                  ? goHome(ref, router)
                                  : openSection(router, railSections[i]),
                            ),
                            leading: Padding(
                              padding: const EdgeInsets.only(
                                top: 8,
                                bottom: 12,
                              ),
                              child: _RailDoors(
                                extended: extended,
                                // Çekmecede yalnız kalem: not açıkken mikrofon
                                // ve "+" listenin altında duruyor.
                                penOnly: forceExtended,
                                onNavigate: onNavigate,
                              ),
                            ),
                            destinations: [
                              for (final s in railSections)
                                NavigationRailDestination(
                                  // Etiketsiz dar rayda ad ipucunda.
                                  icon: Tooltip(
                                    message: s.label(context),
                                    child: Badge(
                                      isLabelVisible:
                                          s == AppSection.folders &&
                                          sharedUnread > 0,
                                      label: Text(
                                        sharedUnread > kFolderBadgeMax
                                            ? '$kFolderBadgeMax+'
                                            : '$sharedUnread',
                                      ),
                                      // Yapay zekâ kapalıysa kilit (F44.6): web'de
                                      // dahili AI kapalıyken de görünür olsun.
                                      child: Icon(
                                        s == AppSection.ai && aiLocked
                                            ? Icons.lock_outline
                                            : s.icon,
                                      ),
                                    ),
                                  ),
                                  selectedIcon: Icon(s.selectedIcon),
                                  label: Text(s.label(context)),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        // İki grup (F44.1): kişiler + yardım · rayın ve
                        // listenin görünümü.
                        children: [
                          _RailAction(
                            extended: extended,
                            icon: AppIcons.friends,
                            label: l10n.friendsTitle,
                            locked: ref.watch(isAnonymousProvider),
                            onPressed: () => go(
                              () => openFriendsScreenOrExplain(context, ref),
                            ),
                          ),
                          _RailAction(
                            extended: extended,
                            icon: Icons.keyboard_outlined,
                            label: l10n.keyboardShortcuts,
                            shortcut: 'Ctrl+/',
                            onPressed: () => showShortcutsHelp(context),
                          ),
                          if (showListToggle || !forceExtended)
                            SizedBox(
                              width: extended ? 200 : kRailWidth,
                              child: const Divider(
                                height: 9,
                                indent: 14,
                                endIndent: 14,
                              ),
                            ),
                          if (showListToggle)
                            _RailAction(
                              extended: extended,
                              selected: collapsed,
                              icon: collapsed
                                  ? Icons.view_sidebar
                                  : Icons.view_sidebar_outlined,
                              label: collapsed
                                  ? l10n.listPaneShow
                                  : l10n.listPaneHide,
                              shortcut: 'Ctrl+\\',
                              onPressed: () => ref
                                  .read(listPaneCollapsedProvider.notifier)
                                  .toggle(),
                            ),
                          if (!forceExtended)
                            _RailAction(
                              extended: extended,
                              icon: extended ? Icons.menu_open : Icons.menu,
                              label: extended
                                  ? l10n.railCollapse
                                  : l10n.railExpand,
                              onPressed: () => ref
                                  .read(railExtendedProvider.notifier)
                                  .set(!extended),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// **Yeni not kapıları tek yerde** (K3, F44.1): kalem (doğrudan metin notu),
/// altında mikrofon ve "+" paneli. Ray görünürken ana ekranın sağ altındaki
/// düğmeler çizilmez. İşin kendisi ana ekranda ([homeDoors]).
class _RailDoors extends ConsumerStatefulWidget {
  const _RailDoors({
    required this.extended,
    required this.penOnly,
    this.onNavigate,
  });

  final bool extended;
  final bool penOnly;
  final VoidCallback? onNavigate;

  @override
  ConsumerState<_RailDoors> createState() => _RailDoorsState();
}

class _RailDoorsState extends ConsumerState<_RailDoors> {
  final _addLink = LayerLink();

  /// Bölümdeysek önce notlara döner, sonra ana ekranın kapısını çağırır.
  void _atHome(void Function(HomeDoors doors) action) {
    openSection(GoRouter.of(context), AppSection.notes);
    final doors = homeDoors;
    if (doors != null) return action(doors);
    // Derin bağlantı: altta ana ekran yoktu, bu kare kuruluyor.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final late = homeDoors;
      if (late != null) action(late);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final router = GoRouter.of(context);
    final shared = ref.watch(selectedSharedFolderProvider);
    // Paylaşılan klasörde not sahibin koleksiyonuna doğar: salt okunurda
    // düğme yok, mikrofon ve "+" paneli burada çizilmez (F43.2).
    final canWrite =
        shared == null ||
        (sharedFolderRefOf(ref, shared)?.role ?? FolderRole.both).canWrite;
    void newNote() {
      widget.onNavigate?.call();
      unawaited(createAndOpenNote(context, ref, router));
    }

    final pen = !canWrite
        ? const SizedBox.shrink()
        : widget.extended
        ? FloatingActionButton.extended(
            key: const ValueKey('rail-new-note'),
            heroTag: 'rail-new-note',
            elevation: 0,
            tooltip: '${l10n.newNoteShort} (Ctrl+N)',
            onPressed: newNote,
            icon: const Icon(Icons.edit_outlined),
            label: Text(l10n.newNoteShort),
          )
        : FloatingActionButton(
            key: const ValueKey('rail-new-note'),
            heroTag: 'rail-new-note',
            elevation: 0,
            tooltip: '${l10n.newNoteShort} (Ctrl+N)',
            onPressed: newNote,
            child: const Icon(Icons.edit_outlined),
          );
    if (widget.penOnly || shared != null) return pen;

    final others = <Widget>[
      Customizable(
        id: UiItem.homeMic,
        child: Tooltip(
          message: l10n.voiceMicTooltipDictate,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Material(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                key: const ValueKey('home-mic'),
                borderRadius: BorderRadius.circular(14),
                onTap: () => _atHome((d) => d.dictateNote()),
                onLongPress: () => _atHome((d) => d.captureVoiceNote()),
                child: Icon(
                  AppIcons.dictation,
                  size: 24,
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
        ),
      ),
      CompositedTransformTarget(
        link: _addLink,
        child: QuickAddFab(
          anchor: _addLink,
          actions: () => homeDoors?.quickAddActions,
          inRail: true,
          beforeAction: () => openSection(router, AppSection.notes),
        ),
      ),
    ];
    const gap = SizedBox.square(dimension: 8);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        pen,
        gap,
        // Geniş rayda yan yana (dikey yer harcamasın), dar rayda alt alta.
        widget.extended
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [others[0], gap, others[1]],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [others[0], gap, others[1]],
              ),
      ],
    );
  }
}

/// Rayın altındaki yardımcı düğme: dar rayda yalnız simge (etiket ipucunda),
/// geniş rayda simge + etiket — yukarıdaki bölümlerle aynı hizada.
class _RailAction extends StatelessWidget {
  const _RailAction({
    required this.extended,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.shortcut,
    this.selected = false,
    this.locked = false,
  });

  /// Misafirde hesap ister (F43.5): simgede kilit.
  final bool locked;
  final bool extended;
  final IconData icon;
  final String label;
  final String? shortcut;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tooltip = shortcut == null ? label : '$label ($shortcut)';
    final scheme = Theme.of(context).colorScheme;
    final glyph = locked
        ? Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon),
              const Positioned(
                right: -6,
                top: -4,
                child: AccountLockBadge(size: 14),
              ),
            ],
          )
        : Icon(icon);
    if (!extended) {
      return SizedBox(
        width: kRailWidth,
        child: Center(
          child: IconButton(
            tooltip: tooltip,
            isSelected: selected,
            icon: glyph,
            onPressed: onPressed,
          ),
        ),
      );
    }
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 200,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
          child: TextButton.icon(
            style: TextButton.styleFrom(
              alignment: AlignmentDirectional.centerStart,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              foregroundColor: selected
                  ? scheme.primary
                  : scheme.onSurfaceVariant,
            ),
            onPressed: onPressed,
            icon: glyph,
            label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
      ),
    );
  }
}
