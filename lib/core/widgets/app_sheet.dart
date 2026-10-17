import 'package:flutter/material.dart';

/// Uygulamanın BÜTÜN alt levhalarının ortak açılış/kapanış hareketi
/// (kullanıcı isteği 2026-10-17: "olmamış hissi"; iPhone gibi akıcılık).
///
/// Flutter'ın varsayılanı 250 ms'lik eski "yavaşlayarak dur" eğrisi: levha
/// kısa ve sert bir hamleyle fırlıyor, son santimde birden duruyordu. Burada
/// M3'ün VURGULU yavaşlama eğrisi (iOS levhalarının "hızlı çık, yumuşak
/// otur" hissi) ve biraz daha uzun bir açılış; kapanış kısa — kullanıcı
/// levhayı kapatınca bekletilmesin.
const kAppSheetAnimation = AnimationStyle(
  duration: Duration(milliseconds: 340),
  reverseDuration: Duration(milliseconds: 220),
  curve: Easing.emphasizedDecelerate,
);

/// [showModalBottomSheet]'in birebir aynısı; yalnız [sheetAnimationStyle]
/// verilmezse [kAppSheetAnimation] kullanır. Uygulamadaki her levha bundan
/// açılır ki hepsi AYNI hareketle gelsin.
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  Color? backgroundColor,
  String? barrierLabel,
  double? elevation,
  ShapeBorder? shape,
  Clip? clipBehavior,
  BoxConstraints? constraints,
  Color? barrierColor,
  bool isScrollControlled = false,
  double scrollControlDisabledMaxHeightRatio = 9.0 / 16.0,
  bool useRootNavigator = false,
  bool isDismissible = true,
  bool enableDrag = true,
  bool? showDragHandle,
  bool useSafeArea = false,
  RouteSettings? routeSettings,
  AnimationController? transitionAnimationController,
  Offset? anchorPoint,
  AnimationStyle? sheetAnimationStyle,
  bool? requestFocus,
}) => showModalBottomSheet<T>(
  context: context,
  builder: builder,
  backgroundColor: backgroundColor,
  barrierLabel: barrierLabel,
  elevation: elevation,
  shape: shape,
  clipBehavior: clipBehavior,
  constraints: constraints,
  barrierColor: barrierColor,
  isScrollControlled: isScrollControlled,
  scrollControlDisabledMaxHeightRatio: scrollControlDisabledMaxHeightRatio,
  useRootNavigator: useRootNavigator,
  isDismissible: isDismissible,
  enableDrag: enableDrag,
  showDragHandle: showDragHandle,
  useSafeArea: useSafeArea,
  routeSettings: routeSettings,
  transitionAnimationController: transitionAnimationController,
  anchorPoint: anchorPoint,
  sheetAnimationStyle: transitionAnimationController != null
      ? null
      : (sheetAnimationStyle ?? kAppSheetAnimation),
  requestFocus: requestFocus,
);
