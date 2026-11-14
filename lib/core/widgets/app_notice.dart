import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_design.dart';
import '../../app/theme/app_tokens.dart';
import 'undo_snackbar.dart' show snackBarBottomObstacle;

/// Geçici bildirimin türü — sırayı ve dokunuş davranışını belirler.
enum AppNoticeKind {
  /// Bir kez çıkan ipucu. Yalnız şerit BOŞKEN çıkar (başka bildirimin önüne
  /// geçmez), dokunuşu ENGELLEMEZ, ekrana ilk dokunuşta kalkar.
  tip,

  /// Acelesi olmayan duyuru ("Yenilikler"). Şerit boşalana dek BEKLER.
  announce,

  /// Az önce olan şeyin iletisi (kaydedildi, silindi + Geri al, hata).
  /// EN YENİ KAZANIR: görünen bildirimin yerine geçer.
  message,
}

/// Tek bir geçici bildirim.
@immutable
class AppNoticeData {
  const AppNoticeData({
    required this.text,
    this.kind = AppNoticeKind.message,
    this.details = const [],
    this.icon,
    this.actionLabel,
    this.onAction,
    this.duration = const Duration(seconds: 4),
  }) : assert((actionLabel == null) == (onAction == null));

  final String text;
  final AppNoticeKind kind;

  /// Başlığın altındaki kısa satırlar (duyuru maddeleri).
  final List<String> details;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Duration duration;
}

/// **BİLDİRİM ŞERİDİ** (P62 ortak dil, docs/plan_tasarim_A.md §5): ipucu,
/// ileti, "Geri al" ve duyuruların TEK kapısı. Aynı anda EN ÇOK BİR bildirim
/// görünür; kurallar [AppNoticeKind]'da.
///
/// Çizen: [AppNoticeHost] (uygulamanın tepesinde tek tane). İSKELET: henüz
/// `app.dart`a bağlı değil; eski yollar (`TipOnce`, `showMessage`,
/// `timedSnackBar`, `showUndoSnackBar`) plandaki pakette buraya taşınacak.
class AppNoticeController extends ChangeNotifier {
  AppNoticeData? _current;
  final _waiting = Queue<AppNoticeData>();
  Timer? _timer;

  AppNoticeData? get current => _current;

  /// Bildirimi gösterir ya da sıraya alır. false = gösterilmedi (ipucu,
  /// şerit doluydu) — çağıran ipucunu "gösterildi" SAYMAZ.
  bool show(AppNoticeData data) {
    final shown = _current;
    switch (data.kind) {
      case AppNoticeKind.tip:
        if (shown != null) return false;
      case AppNoticeKind.announce:
        if (shown != null) {
          _waiting.add(data);
          return true;
        }
      case AppNoticeKind.message:
        // Yarıda kesilen duyuru kaybolmaz: sıranın başına döner.
        if (shown != null && shown.kind == AppNoticeKind.announce) {
          _waiting.addFirst(shown);
        }
    }
    _set(data);
    return true;
  }

  /// Görünen bildirimi kaldırır (sırada bekleyen varsa o gelir). [only]
  /// verilirse yalnız o bildirim görünüyorsa/bekliyorsa.
  void dismiss([AppNoticeData? only]) {
    if (only != null && !identical(only, _current)) {
      _waiting.remove(only);
      return;
    }
    if (_current == null) return;
    _set(_waiting.isEmpty ? null : _waiting.removeFirst());
  }

  void _set(AppNoticeData? data) {
    _timer?.cancel();
    _current = data;
    _timer = data == null ? null : Timer(data.duration, dismiss);
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Uygulamanın tek bildirim şeridi.
final appNotice = AppNoticeController();

/// [child]'ın (Navigator) üstünde bildirim şeridini çizer: ekranın DİBİNDE,
/// klavyenin ve dibe yapışık panelin ([snackBarBottomObstacle]) üstünde,
/// en çok [maxWidth] genişlikte, ortada. Levha/diyalog da altında kalır.
///
/// [child] bu widget yüzünden yeniden KURULMAZ: bildirim değişince yalnız
/// şerit kurulur (kasma listesi madde 3, 7).
class AppNoticeHost extends StatelessWidget {
  const AppNoticeHost({super.key, required this.child, this.controller});

  final Widget child;

  /// Varsayılan [appNotice].
  final AppNoticeController? controller;

  static const double maxWidth = 480;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      child,
      _NoticeLane(controller: controller ?? appNotice),
    ],
  );
}

class _NoticeLane extends StatelessWidget {
  const _NoticeLane({required this.controller});

  final AppNoticeController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final data = controller.current;
      // Engel yüksekliği bildirim KURULURKEN okunur (dinlenmez: değer
      // dizilim sırasında yazılıyor — bkz. snackBarBottomObstacle).
      final lift = math.max(
        MediaQuery.viewInsetsOf(context).bottom,
        snackBarBottomObstacle.value,
      );
      final enter = AppMotion.of(context, AppMotion.short);
      return Positioned(
        left: AppSpace.m,
        right: AppSpace.m,
        bottom: lift + MediaQuery.paddingOf(context).bottom + AppSpace.m,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppNoticeHost.maxWidth),
            child: AnimatedSwitcher(
              duration: enter,
              reverseDuration: AppMotion.exitOf(enter),
              switchInCurve: AppMotion.curveOf(context, AppMotion.enter),
              switchOutCurve: AppMotion.curveOf(context, AppMotion.exit),
              // Yalnız boyama: solma + kendi boyunun dörtte biri kadar kayma.
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween(
                    begin: const Offset(0, 0.25),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: data == null
                  ? const SizedBox.shrink()
                  : _NoticeCard(
                      key: ObjectKey(data),
                      data: data,
                      controller: controller,
                    ),
            ),
          ),
        ),
      );
    },
  );
}

class _NoticeCard extends StatefulWidget {
  const _NoticeCard({super.key, required this.data, required this.controller});

  final AppNoticeData data;
  final AppNoticeController controller;

  @override
  State<_NoticeCard> createState() => _NoticeCardState();
}

class _NoticeCardState extends State<_NoticeCard> {
  bool get _tip => widget.data.kind == AppNoticeKind.tip;

  @override
  void initState() {
    super.initState();
    // İpucu ekranın HERHANGİ bir yerine ilk dokunuşta kalkar; dokunuşu
    // tüketmez (alttaki düğme yine çalışır) — bkz. tips.dart, 2026-11-09.
    if (_tip) GestureBinding.instance.pointerRouter.addGlobalRoute(_onPointer);
  }

  void _onPointer(PointerEvent event) {
    if (event is PointerDownEvent) widget.controller.dismiss(widget.data);
  }

  @override
  void dispose() {
    if (_tip) {
      GestureBinding.instance.pointerRouter.removeGlobalRoute(_onPointer);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = AppText.of(theme);
    final data = widget.data;
    final ink = scheme.onInverseSurface;
    final icon = data.icon ?? (_tip ? Icons.lightbulb_outline : null);
    final card = Semantics(
      container: true,
      liveRegion: true,
      child: DecoratedBox(
        decoration: AppSurface.floating(theme, color: scheme.inverseSurface),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.m),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsetsDirectional.only(
                  start: AppSpace.l,
                  end: data.actionLabel == null ? AppSpace.l : AppSpace.xs,
                  top: AppSpace.s,
                  bottom: AppSpace.s,
                ),
                child: Row(
                  children: [
                    if (icon != null) ...[
                      Icon(
                        icon,
                        size: AppIconSize.s,
                        color: scheme.inversePrimary,
                      ),
                      const SizedBox(width: AppSpace.s),
                    ],
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpace.xs,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data.text,
                              style:
                                  (data.details.isEmpty
                                          ? text.body
                                          : text.label)
                                      .copyWith(color: ink),
                            ),
                            for (final line in data.details)
                              Text(
                                '• $line',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: text.body.copyWith(color: ink),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (data.actionLabel != null)
                      TextButton(
                        key: const ValueKey('notice-action'),
                        style: TextButton.styleFrom(
                          foregroundColor: scheme.inversePrimary,
                        ),
                        onPressed: () {
                          widget.controller.dismiss(data);
                          data.onAction!();
                        },
                        child: Text(data.actionLabel!),
                      ),
                  ],
                ),
              ),
              // Kalan süre: eylemli bildirimde dipte incelen çizgi (kullanıcı
              // bulgusu 2026-10-17). Yalnız boyama (ölçek), dizilim yok.
              if (data.actionLabel != null)
                TweenAnimationBuilder<double>(
                  key: const ValueKey('notice-countdown'),
                  tween: Tween(begin: 1, end: 0),
                  duration: data.duration,
                  builder: (context, value, child) => Transform.scale(
                    scaleX: value,
                    alignment: AlignmentDirectional.centerStart,
                    child: child,
                  ),
                  child: ColoredBox(
                    color: scheme.inversePrimary,
                    child: const SizedBox(height: AppSpace.xxs),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    return _tip ? IgnorePointer(child: card) : card;
  }
}
