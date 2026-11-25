import 'dart:async';
import 'dart:ui' show DisplayFeature;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/haptics.dart';
import '../../core/l10n_ext.dart';
import '../app_commands.dart' show currentLocation;
import '../app_frame.dart';
import '../split_shell.dart';
import '../theme/app_design.dart' show AppSwipe;
import '../theme/app_tokens.dart';
import 'web_workspace_scope.dart';
import 'web_workspace_sidebar.dart';

const double _kWorkspaceDrawerPull = 240;

/// Masaüstü web çalışma alanı çerçevesi (`>= 960 dp`, `kIsWeb`).
///
/// Solda rıhtımlı kenar çubuğunu (`WebWorkspaceSidebar`), sağda bölünmüş/tekli
/// içerik alanını ve alt widget'lar için [AppRailScope] ile [WebWorkspaceScope]
/// kapsayıcılarını kurar. Android ve tablet düzenlerine dokunmaz.
class WebWorkspaceFrame extends ConsumerStatefulWidget {
  const WebWorkspaceFrame({
    super.key,
    required this.showListToggle,
    required this.fullscreen,
    required this.child,
  });

  final bool showListToggle;
  final bool fullscreen;
  final Widget child;

  @override
  ConsumerState<WebWorkspaceFrame> createState() => _WebWorkspaceFrameState();
}

class _WebWorkspaceFrameState extends ConsumerState<WebWorkspaceFrame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drawer = AnimationController(
    vsync: this,
    duration: AppMotion.short,
  );
  final _drawerFocus = FocusNode(debugLabel: 'web-workspace-drawer');
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

  void _closeDrawer() {
    _drawerFocus.unfocus();
    unawaited(_drawer.reverse());
  }

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final router = GoRouter.of(context);
    final tokens = AppTokens.of(context);
    return ListenableBuilder(
      listenable: router.routerDelegate,
      builder: (context, _) {
        final noteOpen = isNoteLocation(currentLocation(router));
        final windowWidth = MediaQuery.sizeOf(context).width;
        final docked =
            !widget.fullscreen &&
            (!noteOpen || windowWidth >= kWebSidebarAutoCollapseWidth);
        if (docked && _drawer.value > 0) _drawer.value = 0;
        final canDrawer = !widget.fullscreen && !docked;
        final pref = ref.watch(railExtendedProvider);
        final sidebarExpanded = noteOpen ? (pref ?? false) : (pref ?? true);
        void toggleSidebar() =>
            ref.read(railExtendedProvider.notifier).set(!sidebarExpanded);

        return Stack(
          children: [
            Row(
              children: [
                if (docked)
                  WebWorkspaceSidebar(
                    extended: sidebarExpanded,
                    showListToggle: widget.showListToggle,
                    forceExtended: false,
                    onToggleExtended: toggleSidebar,
                  )
                else
                  const SizedBox.shrink(),
                if (docked)
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: tokens.hairline,
                  )
                else
                  const SizedBox.shrink(),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, box) {
                      final windowSize = MediaQuery.sizeOf(context);
                      final features = MediaQuery.displayFeaturesOf(context);
                      final padding = MediaQuery.paddingOf(context);
                      final base =
                          context
                              .getInheritedWidgetOfExactType<MediaQuery>()
                              ?.data ??
                          MediaQueryData.fromView(View.of(context));
                      final dx = rtl ? 0.0 : windowSize.width - box.maxWidth;
                      return MediaQuery(
                        data: base.copyWith(
                          size: box.biggest,
                          padding: padding,
                          displayFeatures: [
                            for (final f in features)
                              DisplayFeature(
                                bounds: f.bounds.shift(Offset(-dx, 0)),
                                type: f.type,
                                state: f.state,
                              ),
                          ],
                        ),
                        child: MediaQuery.removePadding(
                          context: context,
                          removeLeft: docked && !rtl,
                          removeRight: docked && rtl,
                          child: AppRailScope(
                            docked: docked,
                            child: WebWorkspaceScope(
                              active: true,
                              sidebarExpanded: docked && sidebarExpanded,
                              onToggleSidebar: toggleSidebar,
                              child: Semantics(
                                container: true,
                                child: widget.child,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
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
                    if (AppSwipe.commits(
                      dragged: _exitPull,
                      extent: _kWorkspaceDrawerPull,
                      velocity: rtl ? -v : v,
                    )) {
                      AppHaptics.heavy();
                      ref.read(noteFullscreenProvider.notifier).set(false);
                    }
                  },
                ),
              ),
            if (canDrawer) ...[
              PositionedDirectional(
                start: 0,
                top: 0,
                bottom: 0,
                width: 14,
                child: GestureDetector(
                  key: const ValueKey('rail-drawer-edge'),
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragUpdate: (d) {
                    final delta =
                        (rtl ? -d.delta.dx : d.delta.dx) /
                        _kWorkspaceDrawerPull;
                    _drawer.value = (_drawer.value + delta).clamp(0, 1);
                  },
                  onHorizontalDragEnd: (d) {
                    final v = d.primaryVelocity ?? 0;
                    if (AppSwipe.commits(
                      dragged: _drawer.value * _kWorkspaceDrawerPull,
                      extent: _kWorkspaceDrawerPull,
                      velocity: rtl ? -v : v,
                      fraction: AppSwipe.drawerCommitFraction,
                    )) {
                      _drawer.forward();
                    } else {
                      _drawer.reverse();
                    }
                  },
                ),
              ),
              _WorkspaceDrawerHandle(onTap: _drawer.forward),
              AnimatedBuilder(
                animation: _drawer,
                builder: (context, _) {
                  final t = AppMotion.emphasized.transform(_drawer.value);
                  if (t == 0) return const SizedBox.shrink();
                  final scheme = Theme.of(context).colorScheme;
                  return BackButtonListener(
                    onBackButtonPressed: () async {
                      _closeDrawer();
                      return true;
                    },
                    child: CallbackShortcuts(
                      bindings: {
                        const SingleActivator(LogicalKeyboardKey.escape):
                            _closeDrawer,
                      },
                      child: Focus(
                        focusNode: _drawerFocus,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: GestureDetector(
                                onTap: _closeDrawer,
                                child: ColoredBox(
                                  color: Colors.black.withValues(
                                    alpha: AppAlpha.scrim * t,
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
                                        end: Radius.circular(AppRadius.xl),
                                      ).resolve(Directionality.of(context)),
                                  clipBehavior: Clip.antiAlias,
                                  child: WebWorkspaceSidebar(
                                    extended: true,
                                    showListToggle: false,
                                    forceExtended: true,
                                    onNavigate: _closeDrawer,
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

class _WorkspaceDrawerHandle extends StatelessWidget {
  const _WorkspaceDrawerHandle({required this.onTap});

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
                  right: Radius.circular(AppRadius.m),
                ),
                child: SizedBox(
                  width: 20,
                  height: 72,
                  child: Center(
                    child: Container(
                      width: 5,
                      height: 44,
                      decoration: BoxDecoration(
                        color: scheme.outline.withValues(alpha: AppAlpha.muted),
                        borderRadius: BorderRadius.circular(AppRadius.xs),
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
