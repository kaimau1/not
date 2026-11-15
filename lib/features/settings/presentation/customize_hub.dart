import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/app_icons.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/menu_layout.dart';
import '../../../core/personalize.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/customize_board.dart';
import '../../../core/widgets/undo_snackbar.dart' show showAppMessage;
import '../../../core/a11y/chip_roles.dart';
import '../../notes/presentation/add_catalog.dart';
import '../../notes/presentation/editor/quick_row_editor.dart';
import '../../notes/presentation/editor/video_transport.dart' show SeekIcon;
import '../../notes/presentation/quick_add_fab.dart'
    show favoriteTemplateOptions, quickAddMenuId;
import '../../notes/data/user_templates.dart'
    show favoriteTemplatesProvider, userTemplatesProvider;
import '../settings_providers.dart';
import 'personalize_bar_list.dart';
import 'personalize_screen.dart' show PersonalizeModuleSwitches;

/// **DÜZEN MERKEZİ** (P63 PB2, plan_tasarim_B §1.2): bütün düzenlenebilir
/// yüzeyler tek kılıkta — üstte yüzey çipleri, altında o yüzeyin
/// [CustomizeBoard]'u. Değişiklik ANINDA kaydedilir (P50). İki yerde aynı
/// parçalar: düzen modu şeridindeki "Sırala" levhası ([showCustomizeHub]) ve
/// Ayarlar → Kişiselleştir ekranı (yüzeyler alt alta, bkz.
/// `PersonalizeScreen`).
enum CustomizeSurface {
  bottomBar,
  topBar,
  quickRow,
  addPanel,
  attach,
  home,
  video,
  pinned,
  pen,
  modules,
}

/// Levha açılırken seçili yüzey: yönlendirici konumu + klavye. Not rotası →
/// alt çubuk (klavye açıksa hızlı satır), öbürleri → ana ekran.
CustomizeSurface surfaceFor(String location, {required bool keyboard}) {
  if (!location.contains('/note/')) return CustomizeSurface.home;
  return keyboard ? CustomizeSurface.quickRow : CustomizeSurface.bottomBar;
}

/// Yüzeyin adı ve simgesi.
(String, IconData) surfaceLabel(AppLocalizations l10n, CustomizeSurface s) =>
    switch (s) {
      CustomizeSurface.bottomBar => (
        l10n.customizeSurfaceBottomBar,
        Icons.space_bar_rounded,
      ),
      CustomizeSurface.topBar => (
        l10n.customizeSurfaceTopBar,
        Icons.web_asset_rounded,
      ),
      CustomizeSurface.quickRow => (
        l10n.customizeSurfaceQuickRow,
        Icons.keyboard_alt_outlined,
      ),
      CustomizeSurface.addPanel => (
        l10n.customizeSurfaceAddPanel,
        Icons.add_circle_outline,
      ),
      CustomizeSurface.attach => (l10n.addAttachment, Icons.add_box_outlined),
      CustomizeSurface.home => (l10n.personalizeHome, Icons.home_outlined),
      CustomizeSurface.video => (
        l10n.personalizeVideo,
        Icons.ondemand_video_rounded,
      ),
      CustomizeSurface.pinned => (
        l10n.customizeSurfacePinned,
        Icons.vertical_split_outlined,
      ),
      CustomizeSurface.pen => (l10n.customizeSurfacePen, Icons.draw_outlined),
      CustomizeSurface.modules => (
        l10n.personalizeModules,
        Icons.extension_outlined,
      ),
    };

/// Sabit ek çubuğunun gizlenebilen düğmeleri ([UiItem.pinned] anahtarları;
/// varsayılan hepsi görünür — Y10).
List<CustomizeEntry> pinnedCatalog(AppLocalizations l10n) => [
  (
    id: UiItem.pinned('side'),
    icon: Icons.swap_horiz_rounded,
    label: l10n.pinnedSideToggle,
  ),
  (
    id: UiItem.pinned('fullscreen'),
    icon: Icons.fullscreen_rounded,
    label: l10n.fullscreen,
  ),
  (
    id: UiItem.pinned('bubble'),
    icon: Icons.chat_bubble_outline_rounded,
    label: l10n.bubbleAdd,
  ),
  (id: UiItem.pinned('link'), icon: Icons.link, label: l10n.copyVideoLink),
  (
    id: UiItem.pinned('unpin'),
    icon: Icons.vertical_align_bottom,
    label: l10n.viewModeFloatingHint,
  ),
  (
    id: UiItem.pinned('pen'),
    icon: Icons.draw_outlined,
    label: l10n.pinnedPenWrite,
  ),
];

/// Tepside gizlenebilen kalemler ([UiItem.penTool]; tükenmez ve silgi
/// gizlenemez — `PenTray._tools`).
List<CustomizeEntry> penCatalog(AppLocalizations l10n) => [
  (id: UiItem.penTool('lasso'), icon: Icons.gesture, label: l10n.inkLasso),
  (
    id: UiItem.penTool('shapes'),
    icon: Icons.category_outlined,
    label: l10n.inkShapes,
  ),
  (
    id: UiItem.penTool('fountain'),
    icon: Icons.edit_outlined,
    label: l10n.penFountain,
  ),
  (id: UiItem.penTool('marker'), icon: Icons.brush, label: l10n.penMarker),
  (
    id: UiItem.penTool('highlighter'),
    icon: Icons.border_color_outlined,
    label: l10n.penHighlighter,
  ),
];

/// Düzen merkezini levhada açar ("Sırala"). Klavye kapatılır.
Future<void> showCustomizeHub(
  BuildContext context, {
  CustomizeSurface initial = CustomizeSurface.bottomBar,
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  return showAppSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 640),
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scroll) =>
          CustomizeHub(initial: initial, scrollController: scroll),
    ),
  );
}

/// Yüzey çipleri + seçili yüzeyin panosu.
class CustomizeHub extends StatefulWidget {
  const CustomizeHub({
    super.key,
    this.initial = CustomizeSurface.bottomBar,
    this.scrollController,
  });

  final CustomizeSurface initial;
  final ScrollController? scrollController;

  @override
  State<CustomizeHub> createState() => _CustomizeHubState();
}

class _CustomizeHubState extends State<CustomizeHub> {
  late CustomizeSurface _surface = widget.initial;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      controller: widget.scrollController,
      padding: EdgeInsets.fromLTRB(
        AppSpace.l,
        0,
        AppSpace.l,
        AppSpace.l + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final s in CustomizeSurface.values)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: AppSpace.s),
                  child: Builder(
                    builder: (context) {
                      final (label, icon) = surfaceLabel(l10n, s);
                      return radioChip(
                        ChoiceChip(
                          key: ValueKey('customize-surface-${s.name}'),
                          avatar: Icon(icon, size: AppIconSize.s),
                          label: Text(label),
                          selected: s == _surface,
                          onSelected: (_) => setState(() => _surface = s),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.m),
        CustomizeSurfacePanel(
          key: ValueKey('customize-panel-${_surface.name}'),
          surface: _surface,
        ),
      ],
    );
  }
}

/// Bir yüzeyin düzenleyicisi (pano; yüzeye özgü ek seçicilerle).
class CustomizeSurfacePanel extends ConsumerWidget {
  const CustomizeSurfacePanel({super.key, required this.surface});

  final CustomizeSurface surface;

  @override
  Widget build(BuildContext context, WidgetRef ref) => switch (surface) {
    CustomizeSurface.bottomBar => const PersonalizeBarList(top: false),
    CustomizeSurface.topBar => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PersonalizeBarList(bottom: false),
        _VisibilityBoard(entries: _topExtras(context.l10n)),
      ],
    ),
    CustomizeSurface.quickRow => const QuickRowEditor(inline: true),
    CustomizeSurface.addPanel => const _AddPanelBoard(),
    CustomizeSurface.attach => const _AttachBoard(),
    CustomizeSurface.home => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _VisibilityBoard(entries: _homeItems(context.l10n)),
        const SizedBox(height: AppSpace.s),
        _PrefSwitch(
          key: const ValueKey('home-calendar-strip'),
          title: context.l10n.homeCalendarStrip,
          value: ref.watch(homeCalendarStripProvider),
          onChanged: (v) => ref.read(homeCalendarStripProvider.notifier).set(v),
        ),
        _PrefSwitch(
          key: const ValueKey('home-quick-capture'),
          title: context.l10n.quickCaptureRowSetting,
          subtitle: context.l10n.quickCaptureRowInfo,
          value: ref.watch(quickCaptureRowProvider),
          onChanged: (v) => ref.read(quickCaptureRowProvider.notifier).set(v),
        ),
      ],
    ),
    CustomizeSurface.video => const _VideoPanel(),
    CustomizeSurface.pinned => _VisibilityBoard(
      entries: pinnedCatalog(context.l10n),
    ),
    CustomizeSurface.pen => _VisibilityBoard(entries: penCatalog(context.l10n)),
    CustomizeSurface.modules => const PersonalizeModuleSwitches(),
  };

  static List<CustomizeEntry> _topExtras(AppLocalizations l10n) => [
    (id: UiItem.editorDate, icon: Icons.schedule, label: l10n.uiItemDate),
    (
      id: UiItem.topCollab,
      icon: Icons.person_add_alt_1_outlined,
      label: l10n.collaborators,
    ),
    (id: UiItem.editorTags, icon: Icons.sell_outlined, label: l10n.moduleTags),
  ];

  static List<CustomizeEntry> _homeItems(AppLocalizations l10n) => [
    (
      id: UiItem.homeAccount,
      icon: Icons.account_circle_outlined,
      label: l10n.account,
    ),
    (id: UiItem.homeAi, icon: Icons.auto_awesome, label: l10n.aiHubTitle),
    (id: UiItem.homeFilter, icon: Icons.tune, label: l10n.filterSheetTitle),
    (id: UiItem.homeMic, icon: AppIcons.dictation, label: l10n.liveDictation),
  ];
}

/// Sırasız yüzey: yalnız göster/gizle. Karo anahtarı `ui-chip-<kimlik>`
/// (eski görünürlük çiplerinin anahtarı — testler ve alışkanlık).
class _VisibilityBoard extends StatelessWidget {
  const _VisibilityBoard({required this.entries});

  final List<CustomizeEntry> entries;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListenableBuilder(
      listenable: Personalize.prefs,
      builder: (context, _) {
        final prefs = Personalize.prefs.value;
        return CustomizeBoard(
          entries: entries,
          shown: [
            for (final e in entries)
              if (prefs.shows(e.id)) e.id,
          ],
          onToggle: (id, on) =>
              Personalize.update((p) => p.withVisible(id, on)),
          shownLabel: l10n.customizeShown,
          availableLabel: l10n.quickRowEditAvailable,
          emptyLabel: l10n.quickRowEditEmpty,
          keyPrefix: 'ui-chip-',
        );
      },
    );
  }
}

/// "+" paneli: gizleme `Personalize`, sıra `MenuLayouts`. Panelin "Menüyü
/// düzenle"si de buraya açılır (2026-11-15; eski panel içi düzenleyicinin
/// kuralları burada): öğeler panelle aynı (favori şablonlar dahil), SON
/// GÖRÜNÜR öğe gizlenemez, sıra GRUBUN İÇİNDE değişir (panel gruplu çizilir,
/// gruplar arası taşıma anlamsız), "Varsayılana dön" yalnız bu panoyu sıfırlar.
class _AddPanelBoard extends ConsumerWidget {
  const _AddPanelBoard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    ref
      ..watch(favoriteTemplatesProvider)
      ..watch(userTemplatesProvider);
    final favorites = favoriteTemplateOptions(context, ref);
    final all = [
      for (final m in addCatalog(l10n, AddContext.newNote)) ...[
        if (m.id == 'template')
          for (final f in favorites)
            (id: f.key, group: f.group, icon: f.icon, label: f.label),
        (id: m.id, group: m.group, icon: m.icon, label: m.label),
      ],
    ];
    return ListenableBuilder(
      listenable: Listenable.merge([Personalize.prefs, MenuLayouts.layouts]),
      builder: (context, _) {
        final prefs = Personalize.prefs.value;
        // Kullanıcı sırası, panel gibi gruplu (grup içinde kullanıcı sırası).
        final sorted = MenuLayouts.of(quickAddMenuId).sorted(all, (e) => e.id);
        final catalog = [
          for (final g in AddGroup.values)
            for (final e in sorted)
              if (e.group == g) e,
        ];
        final groupOf = {for (final e in catalog) e.id: e.group};
        final shown = [
          for (final e in catalog)
            if (prefs.shows(UiItem.quickAdd(e.id))) e.id,
        ];
        return CustomizeBoard(
          entries: [
            for (final e in catalog) (id: e.id, icon: e.icon, label: e.label),
          ],
          shown: shown,
          onToggle: (id, on) {
            if (!on && shown.length <= 1) {
              showAppMessage(context, l10n.quickAddKeepOne);
              return;
            }
            Personalize.update((p) => p.withVisible(UiItem.quickAdd(id), on));
          },
          onReorder: (from, to) {
            final id = shown[from];
            final g = groupOf[id];
            final inGroup = [
              for (final s in shown)
                if (groupOf[s] == g) s,
            ];
            // Hedef, taşınan öğeden sonra kalan listede kendi grubundan önce
            // gelen öğe sayısı: grup dışına bırakılırsa grubun ucuna oturur.
            final rest = [...shown]..removeAt(from);
            final toG = rest.take(to).where((s) => groupOf[s] == g).length;
            final cur = MenuLayouts.of(quickAddMenuId);
            MenuLayouts.set(
              quickAddMenuId,
              MenuLayout(
                hidden: cur.hidden,
                quick: cur.quick,
                order: reorderShown(
                  [for (final e in catalog) e.id],
                  inGroup,
                  inGroup.indexOf(id),
                  toG,
                ),
              ),
            );
          },
          onReset: () {
            Personalize.update(
              (p) => p.copyWith(
                hidden: {
                  for (final h in p.hidden)
                    if (!h.startsWith(UiItem.quickAdd(''))) h,
                },
              ),
            );
            MenuLayouts.set(quickAddMenuId, const MenuLayout());
          },
          resetLabel: l10n.personalizeReset,
          shownLabel: l10n.customizeShown,
          availableLabel: l10n.quickRowEditAvailable,
          emptyLabel: l10n.quickRowEditEmpty,
          keyPrefix: 'quickadd-board-',
        );
      },
    );
  }
}

/// "Ekle" levhası: gizleme + [UiPrefs.attachOrder].
class _AttachBoard extends StatelessWidget {
  const _AttachBoard();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListenableBuilder(
      listenable: Personalize.prefs,
      builder: (context, _) {
        final prefs = Personalize.prefs.value;
        final all = addCatalog(l10n, AddContext.inNote);
        final order = UiPrefs.orderOf([
          for (final e in all) e.id,
        ], prefs.attachOrder);
        final byId = {for (final e in all) e.id: e};
        final entries = [
          for (final id in order)
            (id: id, icon: byId[id]!.icon, label: byId[id]!.label),
        ];
        final shown = [
          for (final id in order)
            if (prefs.shows(UiItem.attach(id))) id,
        ];
        return CustomizeBoard(
          entries: entries,
          shown: shown,
          onToggle: (id, on) =>
              Personalize.update((p) => p.withVisible(UiItem.attach(id), on)),
          onReorder: (from, to) => Personalize.update(
            (p) =>
                p.copyWith(attachOrder: reorderShown(order, shown, from, to)),
          ),
          onReset: () => Personalize.update((p) {
            var next = p.copyWith(attachOrder: const []);
            for (final id in order) {
              next = next.withVisible(UiItem.attach(id), true);
            }
            return next;
          }),
          shownLabel: l10n.customizeShown,
          availableLabel: l10n.quickRowEditAvailable,
          emptyLabel: l10n.quickRowEditEmpty,
          resetLabel: l10n.personalizeReset,
          keyPrefix: 'attach-board-',
        );
      },
    );
  }
}

/// Görünenler içinde [from] → [to] (çıkarılmış dizin); gizliler TAM sırada
/// yerinde kalır. Dönen liste yüzeyin bütün kimlikleri, yeni sırada.
List<String> reorderShown(
  List<String> order,
  List<String> shown,
  int from,
  int to,
) {
  final moved = List.of(shown);
  moved.insert(to, moved.removeAt(from));
  final shownSet = shown.toSet();
  final it = moved.iterator;
  return [
    for (final id in order)
      if (shownSet.contains(id)) (it..moveNext()).current else id,
  ];
}

class _VideoPanel extends StatelessWidget {
  const _VideoPanel();

  static List<CustomizeEntry> _items(AppLocalizations l10n) => [
    (id: UiItem.videoSpeed, icon: Icons.speed_rounded, label: l10n.videoSpeed),
    (
      id: UiItem.videoTime,
      icon: Icons.timer_outlined,
      label: l10n.uiItemVideoTime,
    ),
    (
      id: UiItem.videoNoteAt,
      icon: Icons.more_time,
      label: l10n.videoNoteAtTime,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    Widget seekRow({
      required String label,
      required bool forward,
      required int value,
      required void Function(int) onSelected,
    }) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SeekIcon(seconds: value, forward: forward),
            const SizedBox(width: AppSpace.s),
            Text(label, style: theme.textTheme.labelLarge),
          ],
        ),
        const SizedBox(height: AppSpace.xs),
        Wrap(
          spacing: AppSpace.xs,
          runSpacing: AppSpace.xs,
          children: [
            for (final s in UiPrefs.seekChoices)
              radioChip(
                ChoiceChip(
                  key: ValueKey('seek-${forward ? 'fwd' : 'back'}-$s'),
                  label: Text(l10n.secondsShort(s)),
                  selected: value == s,
                  visualDensity: VisualDensity.compact,
                  onSelected: (_) => onSelected(s),
                ),
              ),
          ],
        ),
      ],
    );
    return ListenableBuilder(
      listenable: Personalize.prefs,
      builder: (context, _) {
        final prefs = Personalize.prefs.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _VisibilityBoard(entries: _items(l10n)),
            const SizedBox(height: AppSpace.l),
            seekRow(
              label: l10n.videoSeekBack,
              forward: false,
              value: prefs.seekBack,
              onSelected: (s) =>
                  Personalize.update((p) => p.copyWith(seekBack: s)),
            ),
            const SizedBox(height: AppSpace.m),
            seekRow(
              label: l10n.videoSeekForward,
              forward: true,
              value: prefs.seekForward,
              onSelected: (s) =>
                  Personalize.update((p) => p.copyWith(seekForward: s)),
            ),
          ],
        );
      },
    );
  }
}

/// Yüzeyin kendi tercihine bağlı anahtar (takvim şeridi, hızlı yakalama).
class _PrefSwitch extends StatelessWidget {
  const _PrefSwitch({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile(
    contentPadding: EdgeInsets.zero,
    dense: true,
    title: Text(title, style: Theme.of(context).textTheme.labelLarge),
    subtitle: subtitle == null ? null : Text(subtitle!),
    value: value,
    onChanged: onChanged,
  );
}
