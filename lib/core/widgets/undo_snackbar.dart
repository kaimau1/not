import 'package:flutter/material.dart';

/// Uygulama genelinde tek, kök ScaffoldMessenger. MaterialApp'e verilir; bu
/// sayede bildirimler go_router sayfa geçişlerinden bağımsız, aynı messenger
/// üzerinde gösterilir (sayaç sıfırlanmaz).
final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

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
  return SnackBar(
    behavior: margin == null ? null : SnackBarBehavior.floating,
    margin: margin,
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
            TweenAnimationBuilder<double>(
              key: const ValueKey('snack-countdown'),
              tween: Tween<double>(begin: 1, end: 0),
              duration: duration,
              onEnd: messenger.hideCurrentSnackBar,
              builder: (context, value, _) => Align(
                alignment: AlignmentDirectional.centerStart,
                child: FractionallySizedBox(
                  widthFactor: value,
                  child: Container(height: 3, color: scheme.inversePrimary),
                ),
              ),
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
    showSnackBar(
      action == null
          ? SnackBar(content: Text(message), duration: duration)
          : timedSnackBar(
              content: Text(message),
              action: action,
              duration: duration,
            ),
    );
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
