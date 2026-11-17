import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../friendly_error.dart';
import 'app_notice.dart';

/// Uygulama genelinde tek, kök ScaffoldMessenger. MaterialApp'e verilir; bu
/// sayede bildirimler go_router sayfa geçişlerinden bağımsız, aynı messenger
/// üzerinde gösterilir (sayaç sıfırlanmaz).
final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Bildirimi klavyenin üstüne çıkaran kenar boşluğu ([base] yoksa temanın
/// varsayılanı). Klavye yoksa [base] aynen döner.
///
/// KÖK NEDEN (cihaz turu 2026-11-05): not ve ana ekran kasmasın diye Scaffold
/// `resizeToAvoidBottomInset: false` (bkz. `KeyboardSnap`); Scaffold bildirimi
/// bu durumda klavyenin ARKASINA koyuyordu: yazarken "Geri al", "Bağlantıyı
/// aç", "AI ile düzelt" hiç görünmüyordu. Bildirimi çizen EN DIŞ Scaffold
/// klavyeyi kendi hesaplıyorsa dokunulmaz (geniş ekran kabuğu, Ayarlar).
EdgeInsetsGeometry? snackBarMarginOverKeyboard([EdgeInsetsGeometry? base]) {
  final lift = math.max(_keyboardLift(), snackBarBottomObstacle.value);
  if (lift <= 0) return base;
  // Temanın (M3) varsayılan boşluğu: 15, 5, 15, 10.
  final start = base ?? const EdgeInsets.fromLTRB(15, 5, 15, 10);
  return start.add(EdgeInsets.only(bottom: lift));
}

double _keyboardLift() {
  final focus = FocusManager.instance.primaryFocus?.context;
  if (focus == null) return 0;
  ScaffoldState? root;
  focus.visitAncestorElements((element) {
    if (element is StatefulElement && element.state is ScaffoldState) {
      root = element.state as ScaffoldState;
    }
    return true;
  });
  if (root?.widget.resizeToAvoidBottomInset != false) return 0;
  // MediaQuery değil: odaktaki alana bağımlılık kurar, klavye kayarken her
  // karede yeniden kurulurdu.
  final view = WidgetsBinding.instance.platformDispatcher.views.first;
  return view.viewInsets.bottom / view.devicePixelRatio;
}

/// **ALTTAKİ ENGEL** (P49 (d), kullanıcı 2026-11-12: "'kalem yazar, parmak
/// dokunur' gibi ipuçları alt kalem panelini KAPATMASIN"): ekranın dibine
/// yapışık bir panel (editörün kalem tepsisi) açıkken yüksekliği burada;
/// bildirimler onun ÜSTÜNDE çıkar. Paneli [SnackBarObstacle] ile sar.
final snackBarBottomObstacle = ValueNotifier<double>(0);

/// Çocuğunun boyunu [snackBarBottomObstacle]'a yazar (dizilimden sonra, ek
/// kare kurmadan); sökülünce siler. Yalnız ekranın DİBİNE yapışık panel için.
class SnackBarObstacle extends SingleChildRenderObjectWidget {
  const SnackBarObstacle({super.key, super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSnackBarObstacle();
}

class _RenderSnackBarObstacle extends RenderProxyBox {
  @override
  void performLayout() {
    super.performLayout();
    final h = size.height;
    if (snackBarBottomObstacle.value != h) {
      // Dinleyicisi yok (değer bildirim kurulurken okunur): dizilim
      // sırasında yazmak güvenli.
      snackBarBottomObstacle.value = h;
    }
  }

  @override
  void detach() {
    snackBarBottomObstacle.value = 0;
    super.detach();
  }
}

/// Silme sonrası kompakt "geri al" bildirimi. Ekranın tümünü kaplamaz; kalan
/// süre "Geri al" düğmesinin hemen yanındaki küçük dairesel göstergede akar ve
/// süre dolunca bildirim KENDİLİĞİNDEN kapanır.
///
/// Bildirim, en yakın değil KÖK ScaffoldMessenger üzerinde gösterilir: böylece
/// başka bir sayfaya geçildiğinde bildirim (ve süre sayacı) sıfırlanmaz, aynı
/// zamanlayıcıyla akmaya devam eder ve süresi dolunca kapanır.
void showUndoSnackBar(
  BuildContext context, {
  required String message,
  required String undoLabel,
  required VoidCallback onUndo,
  Duration duration = const Duration(seconds: 4),
}) {
  // BİLDİRİM ŞERİDİ (P62 PA5): şerit Navigator'ın ÜSTÜNDE — açık levha /
  // diyalog onu örtmez (2026-11-09 levha üstü "Geri al" bulgusu, bekçi
  // `undo_over_sheet_test`), yüzen düğme bölgesine girmez.
  if (appNotice.hosted) {
    rootScaffoldMessengerKey.currentState?.hideCurrentSnackBar();
    appNotice.show(
      AppNoticeData(
        text: message,
        actionLabel: undoLabel,
        onAction: onUndo,
        duration: duration,
      ),
    );
    return;
  }
  final messenger =
      rootScaffoldMessengerKey.currentState ?? ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      timedSnackBar(
        content: Text(message),
        duration: duration,
        action: SnackBarAction(label: undoLabel, onPressed: onUndo),
        // Sağda mikrofon/"+" ve "+"nın solundaki Yapay zekâ düğmesi için yer
        // bırakılır: bildirim onların ÜSTÜne çıkmak yerine SOLUNDA durur.
        margin: const EdgeInsetsDirectional.only(
          start: 12,
          end: 144,
          bottom: 12,
        ),
      ),
    );
}

/// EYLEMLİ (geri al, notu aç…) bildirim — **GERİ SAYIMLA KENDİLİĞİNDEN
/// KAPANIR** ve kalan süre bildirimin DİBİNDE incelen bir şeritte akar.
///
/// KÖK NEDEN (kullanıcı bulgusu 2026-10-17: "bu tür 'metin kaldırıldı' gibi
/// bildirimler sürekli duruyor, bir geri sayımla kapansın"): bu Flutter
/// sürümünde aksiyonlu `SnackBar`ın varsayılanı `persist: true` —
/// ScaffoldMessenger zamanlayıcı KURMUYOR, bildirim elle kapatılana dek
/// ekranda kalıyordu (editörden çıkınca ana ekranda bile). Burada
/// `persist: false` + şeridin kendi bitişi kapatır (messenger zamanlayıcısı
/// erişilebilirlik kipinde hiç başlamayabiliyor). YENİ eylemli bildirim bu
/// yardımcıyla kurulmalı.
SnackBar timedSnackBar({
  required Widget content,
  SnackBarAction? action,
  Duration duration = const Duration(seconds: 5),
  EdgeInsetsGeometry? margin,
}) {
  // Şeritteki bildirimle üst üste binmesin (P62 PA5: P63 çitinde kalan
  // SnackBar'lar).
  appNotice.dismiss();
  final lifted = snackBarMarginOverKeyboard(margin);
  return SnackBar(
    behavior: lifted == null ? null : SnackBarBehavior.floating,
    margin: lifted,
    duration: duration,
    persist: false,
    padding: EdgeInsets.zero,
    clipBehavior: Clip.antiAlias,
    // Eylem düğmesi İÇERİKTE: şerit bildirimin TAM genişliğinde aksın
    // (SnackBar.action içerikle yan yana ayrı bir sütun açıyor).
    content: Builder(
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        final messenger = ScaffoldMessenger.of(context);
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                16,
                action == null ? 14 : 4,
                action == null ? 16 : 6,
                action == null ? 12 : 2,
              ),
              child: Row(
                children: [
                  Expanded(child: content),
                  if (action != null)
                    TextButton(
                      key: const ValueKey('snack-action'),
                      style: TextButton.styleFrom(
                        foregroundColor: scheme.inversePrimary,
                      ),
                      onPressed: () {
                        messenger.hideCurrentSnackBar(
                          reason: SnackBarClosedReason.action,
                        );
                        action.onPressed();
                      },
                      child: Text(action.label),
                    ),
                ],
              ),
            ),
            // K-38: süre boyunca her karede çubuğu yeniden dizen
            // TweenAnimationBuilder yerine saniyede 8 adım, yalnız boyama.
            SteppedCountdown(
              key: const ValueKey('snack-countdown'),
              duration: duration,
              height: 3,
              color: scheme.inversePrimary,
              onEnd: messenger.hideCurrentSnackBar,
            ),
          ],
        );
      },
    ),
  );
}

/// Düz bilgi bildirimi — elle `SnackBar(content: Text(...))` kurmak yerine
/// (F8.3). Eylemliyse [timedSnackBar] (geri sayımla kapanır).
extension AppMessages on ScaffoldMessengerState {
  void showMessage(
    String message, {
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 4),
  }) {
    // Hata bildirimi: ham ayrıntı kopyalanabilsin (F10.4).
    final detail = action == null ? errorDetailFor(message) : null;
    final act =
        action ??
        (detail == null
            ? null
            : SnackBarAction(
                label: detail.label,
                onPressed: () =>
                    Clipboard.setData(ClipboardData(text: detail.raw)),
              ));
    final shown = detail == null ? duration : const Duration(seconds: 6);
    if (appNotice.hosted) {
      hideCurrentSnackBar();
      rootScaffoldMessengerKey.currentState?.hideCurrentSnackBar();
      appNotice.show(
        AppNoticeData(
          text: message,
          actionLabel: act?.label,
          onAction: act?.onPressed,
          duration: shown,
        ),
      );
      return;
    }
    showSnackBar(
      act == null
          ? () {
              final margin = snackBarMarginOverKeyboard();
              return SnackBar(
                content: Text(message),
                duration: shown,
                behavior: margin == null ? null : SnackBarBehavior.floating,
                margin: margin,
              );
            }()
          : timedSnackBar(
              content: Text(message),
              action: act,
              duration: shown,
            ),
    );
  }

  /// "Hazırlanıyor…" gibi iletiyi iş bitince kapatır: messenger'daki
  /// SnackBar ve şeritteki bildirim.
  void hideMessage() {
    hideCurrentSnackBar();
    appNotice.dismiss();
  }
}

/// [AppMessages.showMessage] en yakın messenger'da. `await` sonrası
/// çağrılacaksa messenger'ı ÖNCE alıp onun üzerinde çağır.
void showAppMessage(
  BuildContext context,
  String message, {
  SnackBarAction? action,
  Duration duration = const Duration(seconds: 4),
}) =>
    ScaffoldMessenger.of(context)
        .showMessage(message, action: action, duration: duration);
