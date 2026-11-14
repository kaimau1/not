import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import '../a11y/motion.dart';

/// Uygulamanın BÜTÜN alt levhalarının ortak açılış/kapanış hareketi
/// (kullanıcı isteği 2026-10-17: "olmamış hissi"; iPhone gibi akıcılık).
///
/// Flutter'ın varsayılanı 250 ms'lik eski "yavaşlayarak dur" eğrisi: levha
/// kısa ve sert bir hamleyle fırlıyor, son santimde birden duruyordu. Burada
/// M3'ün VURGULU yavaşlama eğrisi (iOS levhalarının "hızlı çık, yumuşak
/// otur" hissi) ve biraz daha uzun bir açılış; kapanış kısa — kullanıcı
/// levhayı kapatınca bekletilmesin.
const kAppSheetAnimation = AnimationStyle(
  duration: AppMotion.medium,
  reverseDuration: AppMotion.short,
  curve: AppMotion.enter,
  reverseCurve: AppMotion.exit,
);

/// Hareketi azalt (F34.7): levha kısa ve doğrusal.
const kAppSheetAnimationReduced = AnimationStyle(
  duration: AppMotion.reduced,
  reverseDuration: AppMotion.reduced,
  curve: Curves.linear,
  reverseCurve: Curves.linear,
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
  // DURUM ÇUBUĞUNUN ALTINA GİRMEZ (kullanıcı bulgusu 2026-11-14: uzun not
  // menüsünde ⚙ ve ✕ telefonun üst çubuğuyla çakışıyordu): levha ekranın
  // tepesine dek uzasa da üst güvenli alanda durur.
  bool useSafeArea = true,
  RouteSettings? routeSettings,
  AnimationController? transitionAnimationController,
  Offset? anchorPoint,
  AnimationStyle? sheetAnimationStyle,
  bool? requestFocus,
}) => showModalBottomSheet<T>(
  context: context,
  // ALT GÜVENLİ ALAN HER LEVHADA (kullanıcı bulgusu 2026-11-06: "alt tarafta
  // telefon düğmelerinin altına giriyor"): kenardan kenara Android'de levha
  // gövdesi gezinme çubuğunun arkasına uzanıyordu; düğmeler çubuğun altında
  // kalıyordu. Zemin yine en alta iner, içerik çubuğun üstünde biter. Kendi
  // SafeArea'sı olan levhada çift dolgu olmaz (SafeArea dolguyu tüketir).
  builder: (context) => SafeArea(
    top: false,
    left: false,
    right: false,
    child: Builder(builder: builder),
  ),
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
      : (sheetAnimationStyle ??
            (motionOf(context) ? kAppSheetAnimation : kAppSheetAnimationReduced)),
  requestFocus: requestFocus,
);
