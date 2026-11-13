import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app/theme/app_tokens.dart';

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

  /// İpucunu gerekiyorsa en yakın messenger'da tek satır gösterir. true =
  /// gösterildi.
  static bool show(
    BuildContext context,
    SharedPreferences prefs,
    String id,
    String text, {
    bool sessionLimit = true,
    Duration duration = const Duration(seconds: 5),
  }) {
    if (!due(prefs, id, sessionLimit: sessionLimit)) return false;
    // ÜSTTE, DOKUNUŞ GEÇİRGEN (kullanıcı bulgusu 2026-11-08: "bazı ipuçları
    // tıklanabilir butonları kapatıyor — gömülü eklerin menüsünde"): eskiden
    // alttaki SnackBar ekin menüsünü/alt çubuğu 5 sn örtüyor, dokunuşu da
    // yutuyordu. Artık ekranın tepesinde, IgnorePointer: alttaki düğmeye
    // dokunuş geçer; ilk dokunuşta ipucu kalkar.
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return false;
    markShown(prefs, id);
    _current?.remove();
    late final OverlayEntry entry;
    var removed = false;
    void remove() {
      if (removed) return;
      removed = true;
      if (identical(_current, entry)) _current = null;
      entry.remove();
    }

    entry = OverlayEntry(
      builder: (context) => _TipBanner(
        key: ValueKey('tip-$id'),
        text: text,
        duration: duration,
        onDone: remove,
      ),
    );
    _current = entry;
    overlay.insert(entry);
    return true;
  }

  static OverlayEntry? _current;

  /// Ayarlar → "İpuçlarını yeniden göster".
  static Future<void> resetAll(SharedPreferences prefs) async {
    _sessionUsed = false;
    await prefs.remove(prefsKey);
  }

  /// Testler arası oturum sınırını sıfırlar.
  @visibleForTesting
  static void resetSession() => _sessionUsed = false;
}

/// Üstteki ipucu şeridi: belirir, [duration] sonra ya da ilk dokunuşta
/// kalkar. Dokunuşu ENGELLEMEZ (Listener translucent + IgnorePointer).
class _TipBanner extends StatefulWidget {
  const _TipBanner({
    super.key,
    required this.text,
    required this.duration,
    required this.onDone,
  });

  final String text;
  final Duration duration;
  final VoidCallback onDone;

  @override
  State<_TipBanner> createState() => _TipBannerState();
}

class _TipBannerState extends State<_TipBanner> {
  bool _visible = false;
  bool _closing = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
    _timer = Timer(widget.duration, _close);
    // EKRANIN HERHANGİ BİR YERİNE ilk dokunuşta kalkar (2026-11-09 düzeltme:
    // eskiden yalnız şeridin kendi kutusundaki dokunuş kaldırıyordu — şeridin
    // Listener'ı yalnız kendi alanında isabet alır). Genel yol dokunuşu
    // TÜKETMEZ; alttaki düğme yine çalışır.
    GestureBinding.instance.pointerRouter.addGlobalRoute(_onPointer);
  }

  void _onPointer(PointerEvent event) {
    if (event is PointerDownEvent) _close();
  }

  @override
  void dispose() {
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_onPointer);
    // Zamanlayıcı ağaçla gider (testlerde bekleyen zamanlayıcı kalmasın).
    _timer?.cancel();
    super.dispose();
  }

  void _close() {
    if (!mounted || _closing) return;
    _closing = true;
    setState(() => _visible = false);
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 220), widget.onDone);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final top = MediaQuery.paddingOf(context).top;
    return Positioned(
      left: 12,
      right: 12,
      top: top + 8,
      child: IgnorePointer(
          child: AnimatedOpacity(
            opacity: _visible ? 1 : 0,
            duration: AppMotion.of(context, AppMotion.short),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Material(
                  color: scheme.inverseSurface,
                  elevation: 4,
                  borderRadius: BorderRadius.circular(AppRadius.m),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 18,
                          color: scheme.inversePrimary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.text,
                            style: TextStyle(color: scheme.onInverseSurface),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
    );
  }
}
