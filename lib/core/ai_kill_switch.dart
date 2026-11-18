import 'package:flutter/foundation.dart';

/// **AI ACİL KAPATMA** (PLAN §1.5 PL2, 16K §5.3): `config/app.aiKillSwitch`.
///
/// `true` yazılınca istemci bütün AI çağrılarını ağa çıkmadan reddeder
/// ("AI geçici olarak kapalı"); alan yoksa / okunamazsa `false` (bugünkü
/// davranış). Ayrı okuma YOK: değer `config/app`'i zaten dinleyen
/// [saveCadenceSyncProvider] dinleyicisinden gelir. İstemci bu belgeye
/// YAZMAZ (kural: herkes okur, istemci yazamaz).
///
/// Sunucu tarafı değil: eski istemciyi ya da isteği doğrudan atanı durdurmaz;
/// sunucu korumaları `docs/play_hazirlik.md` "AI korumaları".
abstract final class AiKillSwitch {
  static const field = 'aiKillSwitch';

  /// Şu anki değer; arayüz ve AI kapısı dinler.
  static final active = ValueNotifier<bool>(false);

  /// `config/app` anlık görüntüsünden uygular (yalnız tam `true` kapatır).
  static void apply(Map<String, dynamic>? data) {
    active.value = data?[field] == true;
  }

  @visibleForTesting
  static void debugReset() => active.value = false;
}
