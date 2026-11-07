import 'dart:io';

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

  static Future<void> init() async {
    if (kIsWeb || !Platform.isAndroid) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'changed') _set(call.arguments == true);
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

/// Görünmez giriş denetimi: platform alanı bağlı kalır (tuşlar gelir), ama
/// sanal klavye açılmaz.
class _NoSoftKeyboard with TextInputControl {}
