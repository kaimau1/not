import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// **FİZİKSEL KLAVYE** (tablet bulgusu 2026-11-07: "fiziksel klavye
/// algılanmayabiliyor ve sanal klavye açılıyor"). Android harf klavyesinin
/// takılıp çıkarılmasını bildirir (bkz. MainActivity `hasHardKeyboard`);
/// takılıyken sanal klavye hiçbir alanda açılmaz, ⌨ düğmesi
/// ([toggleSoft]) isteyince açar. Tuş girişi her durumda çalışır: alan
/// yine bağlanır, yalnız giriş türü `none` gider (Flutter'ın özel
/// [TextInputControl] yolu).
abstract final class HardKeyboard {
  static const _channel = MethodChannel('dev.kaimau.notlar/keyboard');

  /// Harf klavyesi takılı.
  static final present = ValueNotifier<bool>(false);

  /// Klavye takılıyken kullanıcı sanal klavyeyi istedi.
  static final softWanted = ValueNotifier<bool>(false);

  static final _hidden = _NoSoftKeyboard();
  static final _softWatch = _SoftClosedWatch();

  static Future<void> init() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    _ensureHooked();
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'changed') report(call.arguments == true);
      return null;
    });
    try {
      _set(await _channel.invokeMethod<bool>('present') ?? false);
    } on PlatformException {
      // Klavye yok sayılır: sanal klavye eskisi gibi açılır.
    } on MissingPluginException {
      // Test/eski kabuk.
    }
  }

  static void _ensureHooked() {
    if (_hooked) return;
    _hooked = true;
    HardwareKeyboard.instance.addHandler(_onKey);
    WidgetsBinding.instance.addObserver(_softWatch);
  }

  /// Takılıyken gelen son tuş (sanal klavye kapalıyken tuş = fiziksel).
  static DateTime? _lastKey;
  static Timer? _recheck;
  static bool _hooked = false;

  /// Bu süre içinde tuşa basıldıysa "klavye çıktı" bildirimi yok sayılır.
  @visibleForTesting
  static const sleepGrace = Duration(minutes: 15);

  @visibleForTesting
  static DateTime Function() clock = DateTime.now;

  static bool _onKey(KeyEvent event) {
    if (present.value && !softWanted.value) _lastKey = clock();
    return false;
  }

  /// Yerelden gelen durum. **UYKU KORUMASI** (tablet bulgusu 2026-11-09:
  /// "fiziksel klavyeyle yazarken kaleme geçip parmakla metne basınca sanal
  /// klavye açılıyor, sürekli tekrarlıyor"): Bluetooth klavye boşta uyuyunca
  /// Android onu ÇIKARILDI bildiriyor, tuşa basınca yeniden takılıyor —
  /// sanal klavye her seferinde açılıp kapanıyordu. Son tuştan beri
  /// [sleepGrace] geçmeden gelen "çıktı" yok sayılır; süre dolunca yerel
  /// durum yeniden sorulur.
  @visibleForTesting
  static void report(bool value) {
    _ensureHooked();
    _recheck?.cancel();
    final last = _lastKey;
    if (!value && present.value && last != null) {
      final left = sleepGrace - clock().difference(last);
      if (left > Duration.zero) {
        _recheck = Timer(left, () async {
          _lastKey = null;
          try {
            report(await _channel.invokeMethod<bool>('present') ?? false);
          } catch (_) {
            report(false);
          }
        });
        return;
      }
    }
    _set(value);
  }

  /// Son görülen klavye payı (fiziksel piksel), bkz. [_SoftClosedWatch].
  static double _lastInset = 0;

  /// **⌨ DURUMU SANAL KLAVYEYİ İZLER** (P78 KT-18, tablet turu 2026-11-18:
  /// "iki kez bastım, açılmadı"): sistem GERİ'si sanal klavyeyi kapatınca
  /// [softWanted] açık kalıyor, sonraki ⌨ onu KAPATIYORDU. İstenmiş klavye
  /// açıkken pay sıfıra inerse istek düşer.
  static void _onInset(double inset) {
    if (present.value && softWanted.value && _lastInset > 0 && inset == 0) {
      softWanted.value = false;
      _apply();
    }
    _lastInset = inset;
  }

  @visibleForTesting
  static void resetForTest() {
    _recheck?.cancel();
    _lastKey = null;
    _lastInset = 0;
    present.value = false;
    softWanted.value = false;
    clock = DateTime.now;
    if (_hooked) {
      HardwareKeyboard.instance.removeHandler(_onKey);
      WidgetsBinding.instance.removeObserver(_softWatch);
      _hooked = false;
    }
  }

  static void _set(bool value) {
    if (present.value == value) return;
    present.value = value;
    if (!value) softWanted.value = false;
    _apply();
  }

  /// ⌨: sanal klavyeyi aç/kapat (yalnız fiziksel klavye takılıyken anlamlı).
  static void toggleSoft() {
    softWanted.value = !softWanted.value;
    _apply();
  }

  static void _apply() {
    if (present.value && !softWanted.value) {
      TextInput.setInputControl(_hidden);
    } else {
      TextInput.restorePlatformInputControl();
    }
    // Açık alan giriş türünü bağlanırken bildirir: yeni türle yeniden
    // bağlansın diye odağı bir kare bırakıp geri alır (imleç denetleyicide
    // kalır).
    final focus = FocusManager.instance.primaryFocus;
    if (focus?.context?.findAncestorStateOfType<EditableTextState>() == null) {
      return;
    }
    focus!.unfocus();
    WidgetsBinding.instance
      ..addPostFrameCallback((_) => focus.requestFocus())
      ..scheduleFrame();
  }
}

/// Klavye payını izler (yalnız sayı karşılaştırır; kurulum yok).
class _SoftClosedWatch with WidgetsBindingObserver {
  @override
  void didChangeMetrics() {
    final dispatcher = WidgetsBinding.instance.platformDispatcher;
    final view = dispatcher.implicitView ?? dispatcher.views.firstOrNull;
    if (view != null) HardKeyboard._onInset(view.viewInsets.bottom);
  }
}

/// Görünmez giriş denetimi: platform alanı bağlı kalır (tuşlar gelir), ama
/// sanal klavye açılmaz.
class _NoSoftKeyboard with TextInputControl {}
