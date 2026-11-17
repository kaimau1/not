import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Levhanın klavye payı (kullanıcı bulgusu 2026-11-06: "yeni etkinlik butonu
/// basıldığında açılırken ciddi kasma"). KÖK NEDEN: levha `viewInsets`'i
/// KENDİ build'inde okuyordu; klavye animasyonunun her karesinde bütün form
/// yeniden kuruluyordu. Burada yalnız bu ince dolgu yeniden kurulur, [child]
/// aynı örnek olduğundan dokunulmaz.
///
/// [extra] klavye payına eklenen sabit alt boşluktur (eski `16 + inset`
/// kalıbı). [floorViewPadding] doğruysa pay en az gezinme çubuğu kadardır
/// (klavye kapalıyken çubuk levhanın altını örtmesin).
class SheetInsetPadding extends StatelessWidget {
  const SheetInsetPadding({
    super.key,
    required this.child,
    this.extra = 0,
    this.floorViewPadding = false,
  });

  final Widget child;
  final double extra;
  final bool floorViewPadding;

  @override
  Widget build(BuildContext context) {
    var bottom = MediaQuery.viewInsetsOf(context).bottom;
    if (floorViewPadding) {
      bottom = math.max(bottom, MediaQuery.viewPaddingOf(context).bottom);
    }
    return Padding(
      padding: EdgeInsets.only(bottom: bottom + extra),
      child: child,
    );
  }
}

/// [focus]u levhanın/rotanın AÇILIŞ ANİMASYONU BİTİNCE ister. `autofocus`
/// klavyeyi levha kayarken açıyordu: iki animasyon (levha + klavye) aynı
/// karelerde yarışıp arkadaki ekranı her karede yeniden yerleştiriyordu.
/// `initState`ten çağrılır.
void focusAfterRouteOpens(State state, FocusNode focus) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!state.mounted) return;
    final animation = ModalRoute.of(state.context)?.animation;
    if (animation == null || animation.isCompleted) {
      focus.requestFocus();
      return;
    }
    void listener(AnimationStatus s) {
      if (s != AnimationStatus.completed) return;
      animation.removeStatusListener(listener);
      if (state.mounted) focus.requestFocus();
    }

    animation.addStatusListener(listener);
  });
}
