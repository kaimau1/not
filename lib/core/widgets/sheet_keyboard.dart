import 'package:flutter/widgets.dart';

/// Levhanın klavye payı (kullanıcı bulgusu 2026-11-06: "yeni etkinlik butonu
/// basıldığında açılırken ciddi kasma"). KÖK NEDEN: levha `viewInsets`'i
/// KENDİ build'inde okuyordu; klavye animasyonunun her karesinde bütün form
/// yeniden kuruluyordu. Burada yalnız bu ince dolgu yeniden kurulur, [child]
/// aynı örnek olduğundan dokunulmaz.
class SheetInsetPadding extends StatelessWidget {
  const SheetInsetPadding({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: child,
  );
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
