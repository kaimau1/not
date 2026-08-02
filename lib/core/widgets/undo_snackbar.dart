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
  final scheme = Theme.of(context).colorScheme;
  final messenger =
      rootScaffoldMessengerKey.currentState ?? ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        // Sağda mikrofon/"+" düğmeleri için yer bırakılır: bildirim onların
        // ÜSTÜne çıkmak yerine SOLUNDA, ekranın dibinde durur. (width ile
        // margin birlikte kullanılamaz; konumu margin belirler.)
        margin: const EdgeInsetsDirectional.only(start: 12, end: 88, bottom: 12),
        // ScaffoldMessenger'ın kendi zamanlayıcısı bu süre dolunca bildirimi
        // kapatır — sayfa değişse de sayaç bu süreden bağımsız sıfırlanmaz.
        duration: duration,
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(child: Text(message)),
            const SizedBox(width: 12),
            // Kalan süre: "Geri al"ın hemen yanında küçük dairesel gösterge.
            // Kapatmayı da BU gösterge yapar: ScaffoldMessenger'ın kendi
            // zamanlayıcısı bazı durumlarda (ör. erişilebilirlik modu)
            // hiç başlamıyor ve bildirim ekranda kalıyordu.
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 1, end: 0),
              duration: duration,
              onEnd: messenger.hideCurrentSnackBar,
              builder: (context, value, _) => SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  value: value,
                  strokeWidth: 2,
                  color: scheme.inversePrimary,
                  backgroundColor: scheme.inversePrimary.withValues(
                    alpha: 0.25,
                  ),
                ),
              ),
            ),
          ],
        ),
        action: SnackBarAction(label: undoLabel, onPressed: onUndo),
      ),
    );
}
