import 'dart:async';
import 'dart:ui' show DisplayFeature;

import '../core/app_icons.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/l10n_ext.dart';
import '../features/folders/data/folder_activity.dart';
import '../features/friends/presentation/friends_screen.dart';
import '../features/settings/settings_providers.dart';
import 'app_commands.dart';
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
  const AppRailScope({super.key, required super.child});

  static bool visible(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppRailScope>() != null;

  @override
  bool updateShouldNotify(AppRailScope oldWidget) => false;
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
    final showRail =
        size.width >= kRailBreakpoint && size.height >= _minRailHeight;
    void toggleList() => ref.read(listPaneCollapsedProvider.notifier).toggle();

    final fullscreen = ref.watch(noteFullscreenProvider);
    Widget content = child;
    if (showRail) {
      content = _RailFrame(
        showListToggle: size.width >= kSplitBreakpoint,
        fullscreen: fullscreen,
        child: child,
      );
    }
    return AppShortcuts(
      onToggleList: toggleList,
      // Kısayollar odak ağacından geçer; hiçbir şey odaklı değilken (ayarlar
      // ekranı yeni açıldı) de çalışsınlar diye çerçeve kendisi odak alır.
      child: Focus(autofocus: true, skipTraversal: true, child: content),
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
                          child: AppRailScope(child: widget.child),
                        ),
                      );
                    },
                  ),
                ),
              ],
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
                            onDestinationSelected: (i) =>
                                go(() => openSection(router, railSections[i])),
                            leading: Padding(
                              padding: const EdgeInsets.only(
                                top: 8,
                                bottom: 12,
                              ),
                              child: extended
                                  ? FloatingActionButton.extended(
                                      heroTag: 'rail-new-note',
                                      elevation: 0,
                                      onPressed: () => go(
                                        () => createAndOpenNote(ref, router),
                                      ),
                                      icon: const Icon(Icons.edit_outlined),
                                      label: Text(l10n.newNoteShort),
                                    )
                                  : FloatingActionButton(
                                      heroTag: 'rail-new-note',
                                      elevation: 0,
                                      tooltip: '${l10n.newNoteShort} (Ctrl+N)',
                                      onPressed: () => go(
                                        () => createAndOpenNote(ref, router),
                                      ),
                                      child: const Icon(Icons.edit_outlined),
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
                                      child: Icon(s.icon),
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
                        children: [
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
                          _RailAction(
                            extended: extended,
                            icon: AppIcons.friends,
                            label: l10n.friendsTitle,
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
  });

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
    if (!extended) {
      return SizedBox(
        width: kRailWidth,
        child: Center(
          child: IconButton(
            tooltip: tooltip,
            isSelected: selected,
            icon: Icon(icon),
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
            icon: Icon(icon),
            label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
      ),
    );
  }
}
