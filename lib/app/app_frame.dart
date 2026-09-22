import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/l10n_ext.dart';
import '../features/friends/presentation/friends_screen.dart';
import '../features/inbox/data/inbox_repository.dart';
import '../features/settings/settings_providers.dart';
import 'app_commands.dart';
import 'split_shell.dart';

/// Gezinme rayının belirdiği genişlik (Material 3 "orta" pencere sınıfı):
/// tablet dikey, katlanabilir açık, web ve Windows penceresi. Altında —
/// telefonda — hiçbir şey değişmez.
const double kRailBreakpoint = 600;

/// Rayın kendiliğinden ETİKETLİ (geniş) açıldığı genişlik. Kullanıcı elle
/// daraltıp genişletirse o seçim kalıcıdır (bkz. [railExtendedProvider]).
const double kRailAutoExtendBreakpoint = 1280;

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
///   klavyeli tablet, web ve Windows için.
///
/// Dar ekranda [child] olduğu gibi döner; telefonun görünümü birebir aynı.
class AppFrame extends ConsumerWidget {
  const AppFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.sizeOf(context);
    final showRail =
        size.width >= kRailBreakpoint && size.height >= _minRailHeight;
    void toggleList() => ref.read(listPaneCollapsedProvider.notifier).toggle();

    Widget content = child;
    if (showRail) {
      final rtl = Directionality.of(context) == TextDirection.rtl;
      content = Row(
        children: [
          _AppRail(showListToggle: size.width >= kSplitBreakpoint),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(
            // İçerik, pencerenin değil KENDİ alanının boyunu "ekran" sanmalı:
            // ana-detay kararı (kSplitBreakpoint), sütun sayısı ve dar ekran
            // kısayolları hep `MediaQuery.sizeOf` okuyor. Ray yer kaplarken
            // pencere genişliğine bakmak, listenin yanındaki editörü
            // [kSplitBreakpoint]'in söz verdiğinden dar bırakırdı.
            child: LayoutBuilder(
              builder: (context, box) => MediaQuery(
                data: MediaQuery.of(context).copyWith(size: box.biggest),
                // Rayın yanındaki ekran, kenar çentiği/sistem payını ikinci
                // kez uygulamasın — o kenarı ray zaten karşılıyor.
                child: MediaQuery.removePadding(
                  context: context,
                  removeLeft: !rtl,
                  removeRight: rtl,
                  child: child,
                ),
              ),
            ),
          ),
        ],
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

class _AppRail extends ConsumerWidget {
  const _AppRail({required this.showListToggle});

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
        ref.watch(railExtendedProvider) ?? width >= kRailAutoExtendBreakpoint;
    final collapsed = ref.watch(listPaneCollapsedProvider);
    final inboxCount = ref.watch(
      inboxNotesProvider.select((a) => a.value?.length ?? 0),
    );

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
                          return NavigationRail(
                            backgroundColor: Colors.transparent,
                            extended: extended,
                            minExtendedWidth: 220,
                            labelType: extended
                                ? NavigationRailLabelType.none
                                : NavigationRailLabelType.all,
                            selectedIndex: section?.index,
                            groupAlignment: -0.85,
                            onDestinationSelected: (i) =>
                                openSection(router, AppSection.values[i]),
                            leading: Padding(
                              padding: const EdgeInsets.only(
                                top: 8,
                                bottom: 12,
                              ),
                              child: extended
                                  ? FloatingActionButton.extended(
                                      heroTag: 'rail-new-note',
                                      elevation: 0,
                                      onPressed: () =>
                                          createAndOpenNote(ref, router),
                                      icon: const Icon(Icons.edit_outlined),
                                      label: Text(l10n.newNoteShort),
                                    )
                                  : FloatingActionButton(
                                      heroTag: 'rail-new-note',
                                      elevation: 0,
                                      tooltip: '${l10n.newNoteShort} (Ctrl+N)',
                                      onPressed: () =>
                                          createAndOpenNote(ref, router),
                                      child: const Icon(Icons.edit_outlined),
                                    ),
                            ),
                            destinations: [
                              for (final s in AppSection.values)
                                NavigationRailDestination(
                                  // Gelen notlarda bekleyen sayısı: rayda göz önünde
                                  // dursun, menüye girmeden görülsün.
                                  icon: Badge(
                                    isLabelVisible:
                                        s == AppSection.inbox && inboxCount > 0,
                                    label: Text('$inboxCount'),
                                    child: Icon(s.icon),
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
                            icon: Icons.people_alt_outlined,
                            label: l10n.friendsTitle,
                            onPressed: () =>
                                openFriendsScreenOrExplain(context, ref),
                          ),
                          _RailAction(
                            extended: extended,
                            icon: Icons.keyboard_outlined,
                            label: l10n.keyboardShortcuts,
                            shortcut: 'Ctrl+/',
                            onPressed: () => showShortcutsHelp(context),
                          ),
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
        width: 80,
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
        width: 220,
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
