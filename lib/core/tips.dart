import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'widgets/app_notice.dart';

/// **BİR KEZ ÇIKAN İPUÇLARI** (F14.6, 2026-10-31; plandaki öneri uygulandı:
/// dört jest + oturumda en fazla bir ipucu).
///
/// Uygulamada en az on görünmez jest var (madde çizme, PDF'e basılı tutma,
/// medyayı yukarı sürükleme, ızgarada yana kaydırma…). İpucu, iş İLK KEZ
/// mümkün olduğunda bağlamında tek satır çıkar; gösterilenler CİHAZDA
/// tutulur (hesaba bağlı değil — her cihazda bir kez görmek doğru), Ayarlar
/// → "İpuçlarını yeniden göster" hepsini sıfırlar.
///
/// Oturum sınırı: kullanıcı aynı açılışta art arda ipucu görmesin. Az önce
/// OLAN bir şeyi açıklayan bildirim (kalem tuvali açtı) sınırı aşabilir —
/// [TipOnce.show] `sessionLimit: false`.
abstract final class TipOnce {
  static const prefsKey = 'tips_shown';

  /// Liste notu ilk açıldı: madde jestleri.
  static const listGestures = 'list_gestures';

  /// İlk PDF/sunum notu: basılı tut → balon.
  static const pdfBubble = 'pdf_bubble';

  /// Notta ilk görsel: yukarı sürükle → üste sabitle.
  static const mediaPin = 'media_pin';

  /// Üste sabit PDF: yazıya basılı tut → "Not al" (2026-11-03).
  static const pdfReadNote = 'pdf_read_note';

  /// İlk ızgara + klasör: ekranı yana kaydır → klasörler arası.
  static const gridSwipe = 'grid_swipe';

  /// Kalem metin notunda el yazısı tuvalini açtı (F14.4).
  static const stylusCanvas = 'stylus_canvas';

  /// Arama kutusundaki "Anlam" anahtarı ilk kez göründü (F14.4).
  static const semanticSearch = 'semantic_search';

  /// Ana ekran mikrofonu: basılı tut → AI sesli not (K7, rozet kalktı).
  static const homeMicHold = 'home_mic_hold';

  /// Yazarken alt çubuk ilk kez gizlendi (2026-11-08).
  static const typingBarHide = 'typing_bar_hide';

  /// KALEM İPUÇLARI (kullanıcı isteği 2026-11-08: "kalem özellikleri için
  /// ipuçları eklensin"): kip açılınca, ilk çizgilerden sonra sırayla.
  static const penToggle = 'pen_toggle';
  static const penShapeHold = 'pen_shape_hold';
  static const penEraserHold = 'pen_eraser_hold';

  /// Kalem kipi PARMAKLA açıldı (telefon, F63.5): tek parmak çizer, iki
  /// parmak kaydırır.
  static const penTwoFinger = 'pen_two_finger';

  static bool _sessionUsed = false;

  /// Bu ipucu gösterilmeli mi? (Gösterilmemiş ve — sınırlıysa — bu
  /// oturumda başka ipucu çıkmamış.)
  static bool due(
    SharedPreferences prefs,
    String id, {
    bool sessionLimit = true,
  }) {
    if (sessionLimit && _sessionUsed) return false;
    return !(prefs.getStringList(prefsKey) ?? const []).contains(id);
  }

  /// Gösterildi say (kalıcı) ve oturum hakkını kullan.
  static void markShown(SharedPreferences prefs, String id) {
    _sessionUsed = true;
    final shown = {...?prefs.getStringList(prefsKey), id};
    prefs.setStringList(prefsKey, shown.toList()..sort()).ignore();
  }

  /// İpucunu gerekiyorsa bildirim şeridinde ([appNotice]) gösterir. true =
  /// gösterildi. ÜSTTE, DOKUNUŞ GEÇİRGEN, ilk dokunuşta kalkar (kullanıcı
  /// bulgusu 2026-11-08: "bazı ipuçları tıklanabilir butonları kapatıyor").
  ///
  /// Şerit ağaçta yoksa ipucu "gösterildi" SAYILMAZ. Şerit doluysa (başka
  /// bildirim görünüyor — ör. kalem kipi iletisi ile iki parmak ipucu aynı
  /// anda) false döner ve ipucu ERTELENİR: şerit boşalınca hâlâ gerekiyorsa
  /// çıkar, o zaman sayılır (P62 PA5). Tek erteleme yeri: yenisi eskisinin
  /// yerine geçer.
  static bool show(
    BuildContext context,
    SharedPreferences prefs,
    String id,
    String text, {
    bool sessionLimit = true,
    Duration duration = const Duration(seconds: 5),
  }) {
    if (!due(prefs, id, sessionLimit: sessionLimit)) return false;
    if (!appNotice.hosted) return false;
    bool tryShow() {
      final shown = appNotice.show(
        AppNoticeData(text: text, kind: AppNoticeKind.tip, duration: duration),
      );
      if (shown) markShown(prefs, id);
      return shown;
    }

    _cancelDeferred();
    if (tryShow()) return true;
    void retry() {
      if (appNotice.current != null) return;
      _cancelDeferred();
      if (appNotice.hosted && due(prefs, id, sessionLimit: sessionLimit)) {
        tryShow();
      }
    }

    _deferred = retry;
    appNotice.addListener(retry);
    return false;
  }

  static VoidCallback? _deferred;

  static void _cancelDeferred() {
    final d = _deferred;
    if (d == null) return;
    _deferred = null;
    appNotice.removeListener(d);
  }

  /// Ayarlar → "İpuçlarını yeniden göster".
  static Future<void> resetAll(SharedPreferences prefs) async {
    _sessionUsed = false;
    await prefs.remove(prefsKey);
  }

  /// Testler arası oturum sınırını sıfırlar.
  @visibleForTesting
  static void resetSession() {
    _sessionUsed = false;
    _cancelDeferred();
  }
}
