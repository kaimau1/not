import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/settings_providers.dart';

/// Yapay zekânın SON yaptığı işler — Yapay Zeka sayfasındaki "SON İŞLEMLER".
///
/// Neden cihazda ve neden bu kadar az: amaç bir denetim kaydı değil,
/// "az önce ne yaptırmıştım" sorusuna cevap. Bu yüzden yalnız işin ADI ve
/// zamanı tutulur — soru metni, not içeriği ya da model yanıtı YAZILMAZ
/// (kişisel veri hafızaya girmez). Firestore'a gitmez: cihaz başına anlamlı
/// bir liste, senkronlanacak bir veri değil.
class AiHistoryEntry {
  const AiHistoryEntry({required this.label, required this.at});

  /// Kullanıcıya görünen iş adı ("Not özeti", "Sesli not", "Soru").
  final String label;
  final DateTime at;

  /// prefs biçimi: `ISO8601|etiket`. Etikette `|` olabileceği için ilk
  /// ayraçtan bölünür.
  static AiHistoryEntry? decode(String raw) {
    final split = raw.indexOf('|');
    if (split <= 0) return null;
    final at = DateTime.tryParse(raw.substring(0, split));
    if (at == null) return null;
    return AiHistoryEntry(label: raw.substring(split + 1), at: at);
  }

  String encode() => '${at.toIso8601String()}|$label';
}

/// Tutulan en fazla kayıt. Beşi ekranda görünüyor; birkaç fazlası, bir kayıt
/// silinince listenin boşalmaması için.
const int kAiHistoryMax = 10;

final aiHistoryProvider =
    NotifierProvider<AiHistoryNotifier, List<AiHistoryEntry>>(
      AiHistoryNotifier.new,
    );

class AiHistoryNotifier extends Notifier<List<AiHistoryEntry>> {
  static const prefsKey = 'ai_history';

  @override
  List<AiHistoryEntry> build() {
    final raw =
        ref.watch(sharedPreferencesProvider).getStringList(prefsKey) ??
        const <String>[];
    return [
      for (final entry in raw) ?AiHistoryEntry.decode(entry),
    ];
  }

  /// Bir AI işi tamamlandı. En yeni kayıt başa gelir.
  void record(String label) {
    final entry = AiHistoryEntry(label: label, at: DateTime.now());
    final next = [entry, ...state].take(kAiHistoryMax).toList();
    state = next;
    ref.read(sharedPreferencesProvider).setStringList(prefsKey, [
      for (final e in next) e.encode(),
    ]);
  }

  void clear() {
    state = const [];
    ref.read(sharedPreferencesProvider).remove(prefsKey);
  }
}
