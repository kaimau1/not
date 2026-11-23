import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:flutter/widgets.dart';

/// Masaüstü web çalışma alanının açıldığı en küçük genişlik.
/// Altında (< 960 dp) dar/tablet/mobil kabuk aynen korunur.
const double kWebWorkspaceBreakpoint = 960;

/// Genişletilmiş masaüstü kenar çubuğu genişliği.
const double kWebSidebarExpandedWidth = 256;

/// Sıkıştırılmış (ikon rıhtımı) kenar çubuğu genişliği.
const double kWebSidebarCompactWidth = 72;

/// Not açıkken dahi yan kenar çubuğunun rıhtımlı kalabildiği pencere genişliği.
const double kWebSidebarAutoCollapseWidth = 1280;

const double _kMinWebWorkspaceHeight = 500;

/// Yalnızca testlerde masaüstü web kabuğunu zorlamak veya kapatmak için.
@visibleForTesting
bool? webWorkspaceOverride;

/// Pencere masaüstü web çalışma alanını açmalı mı?
/// Android telefon/tabletler ve VM widget testleri (`kIsWeb == false`) bundan
/// etkilenmez.
bool isDesktopWebWindow(Size size) =>
    (webWorkspaceOverride ?? kIsWeb) &&
    size.width >= kWebWorkspaceBreakpoint &&
    size.height >= _kMinWebWorkspaceHeight;

/// Alt widget'lara masaüstü web kabuğunun aktifliğini ve kenar çubuğu durumunu
/// taşır (`DashboardScreen`, ayırıcı ve şerit çakışmalarını buradan okur).
class WebWorkspaceScope extends InheritedWidget {
  const WebWorkspaceScope({
    super.key,
    required this.active,
    required this.sidebarExpanded,
    this.onToggleSidebar,
    required super.child,
  });

  final bool active;
  final bool sidebarExpanded;
  final VoidCallback? onToggleSidebar;

  static bool activeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WebWorkspaceScope>()?.active ??
      false;

  static bool sidebarExpandedOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<WebWorkspaceScope>()
          ?.sidebarExpanded ??
      false;

  static WebWorkspaceScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WebWorkspaceScope>();

  @override
  bool updateShouldNotify(WebWorkspaceScope oldWidget) =>
      active != oldWidget.active ||
      sidebarExpanded != oldWidget.sidebarExpanded ||
      onToggleSidebar != oldWidget.onToggleSidebar;
}
