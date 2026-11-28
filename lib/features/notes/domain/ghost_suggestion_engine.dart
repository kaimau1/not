import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/quick_entry_memory.dart';
import 'list_mode.dart';
import 'note.dart';
import 'note_item.dart';
import 'quick_entry.dart';
import 'quick_suggestion_sanitizer.dart';
import 'smart_list.dart';

/// Hayalet önerinin neden önerildiğini açıklayan kısa etiket türü.
enum GhostSuggestionReason {
  /// Kullanıcının satın alma aralığı dolmuş ürün (`memory.predictDue`).
  overdue,

  /// Listede zaten bulunan bir ürünle sık eşleşen tamamlayıcı ürün.
  pairing,

  /// Kullanıcının bu kipte sık eklediği temizlenmiş ürün.
  frequent,

  /// Şablon / rutin bağlamından gelen eksik temel madde.
  essential,
}

/// **HAYALET ÖNERİ (KURAL 1 — YALNIZ GEÇİCİ UI VERİSİ)**
///
/// Kalıcı [NoteItem] modeline `isGhost` alanı EKLENMEZ. Hayalet öneriler yalnız
/// UI katmanında üretilir; kullanıcı dokunduğunda [toNoteItem] ile gerçek bir
/// [NoteItem] oluşturulur ve nota eklenir.
@immutable
class GhostSuggestion {
  const GhostSuggestion({
    required this.id,
    required this.text,
    required this.reason,
    this.category = '',
    this.quantity,
    this.unit = '',
    this.pairedWith,
  });

  /// 24 saatlik gizleme anahtarı olarak da kullanılan normalize kimlik.
  final String id;
  final String text;
  final GhostSuggestionReason reason;
  final String category;
  final double? quantity;
  final String unit;
  final String? pairedWith;

  /// Dokunulduğunda gerçek kalıcı [NoteItem] üretir.
  NoteItem toNoteItem(String itemId) => NoteItem(
    id: itemId,
    text: text,
    category: category,
    quantity: quantity,
    unit: unit,
  );

  @override
  bool operator ==(Object other) =>
      other is GhostSuggestion &&
      other.id == id &&
      other.text == text &&
      other.reason == reason &&
      other.category == category;

  @override
  int get hashCode => Object.hash(id, text, reason, category);
}

/// **HAYALET ÖNERİ MOTORU (0 KREDİ, TAMAMEN YEREL)** (Faz 3):
///
/// Aktif liste kipine ve içeriğine bakarak 2–3 eksik önerisi üretir.
/// Kilitli notlar için ASLA öneri üretmez.
abstract final class GhostSuggestionEngine {
  static const prefsKey = 'ghost_dismissed_v1';
  static const dismissTtl = Duration(hours: 24);

  /// Alışveriş tamamlayıcı eşleşme sözlüğü (normalize anahtar → öneriler).
  static const Map<String, List<String>> _shoppingPairingsTr = {
    'makarna': ['Salça', 'Rendelenmiş peynir', 'Zeytinyağı'],
    'spagetti': ['Salça', 'Zeytinyağı'],
    'cay': ['Şeker', 'Limon'],
    'kahve': ['Süt', 'Şeker'],
    'turk kahvesi': ['Şeker'],
    'yumurta': ['Ekmek', 'Domates', 'Tereyağı'],
    'menemen': ['Domates', 'Biber', 'Yumurta'],
    'ekmek': ['Peynir', 'Tereyağı', 'Zeytin'],
    'sut': ['Yumurta', 'Yulaf'],
    'domates': ['Salatalık', 'Biber', 'Maydanoz'],
    'salatalik': ['Domates', 'Limon'],
    'tavuk': ['Pirinç', 'Baharat', 'Soğan'],
    'kiyma': ['Soğan', 'Salça', 'Sarımsak'],
    'pilav': ['Tereyağı', 'Şehriye'],
    'pirinc': ['Tereyağı', 'Şehriye'],
    'corba': ['Limon', 'Ekmek'],
    'pasta': ['Un', 'Yumurta', 'Kabartma tozu'],
    'kek': ['Un', 'Yumurta', 'Süt', 'Kabartma tozu'],
    'tost': ['Kaşar peyniri', 'Sucuk', 'Ekmek'],
    'pasta_en': ['Tomato sauce', 'Olive oil'],
  };

  static const Map<String, List<String>> _shoppingPairingsEn = {
    'pasta': ['Tomato sauce', 'Olive oil', 'Parmesan'],
    'coffee': ['Milk', 'Sugar'],
    'tea': ['Sugar', 'Lemon'],
    'eggs': ['Bread', 'Butter', 'Tomatoes'],
    'bread': ['Butter', 'Cheese'],
    'milk': ['Eggs', 'Oats'],
    'tomatoes': ['Cucumber', 'Onion'],
    'chicken': ['Rice', 'Garlic', 'Onion'],
  };

  static const _packingEssentialsTr = [
    'Şarj aleti',
    'Pasaport / Kimlik',
    'Diş fırçası',
    'İlaçlar',
    'Kulaklık',
    'Yedek kıyafet',
  ];

  static const _packingEssentialsEn = [
    'Phone charger',
    'Passport / ID',
    'Toothbrush',
    'Medications',
    'Headphones',
    'Spare clothes',
  ];

  static const _routineMorningTr = [
    'Su iç',
    '5 dk esneme',
    'Günün 3 hedefini seç',
    'Vitamin al',
  ];
  static const _routineEveningTr = [
    '15 dk kitap oku',
    'Yarını planla',
    'Ekranı kapat',
    'Günlük özet yaz',
  ];
  static const _routineWeekendTr = [
    'Haftalık plan yap',
    'Yürüyüşe çık',
    'Evi toparla',
  ];

  static const _routineMorningEn = [
    'Drink water',
    '5 min stretch',
    'Pick top 3 priorities',
    'Take vitamins',
  ];
  static const _routineEveningEn = [
    'Read 15 min',
    'Plan tomorrow',
    'Screen-free wind down',
  ];
  static const _routineWeekendEn = [
    'Weekly review',
    'Go for a walk',
    'Tidy up workspace',
  ];

  /// 24 saat içinde gizlenmiş öneri anahtarlarını okur (süresi dolanları eler).
  static Set<String> loadDismissed(SharedPreferences? prefs, {DateTime? now}) {
    if (prefs == null) return const {};
    final raw = prefs.getString(prefsKey);
    if (raw == null || raw.isEmpty) return const {};
    final current = (now ?? DateTime.now()).millisecondsSinceEpoch;
    final cutoff = current - dismissTtl.inMilliseconds;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final active = <String>{};
      map.forEach((k, v) {
        if (v is num && v.toInt() >= cutoff) active.add(k);
      });
      return active;
    } catch (_) {
      return const {};
    }
  }

  /// Bir hayalet öneriyi 24 saatliğine gizler (ve süresi dolanları budar).
  static Future<void> dismiss(
    SharedPreferences? prefs,
    String suggestionId, {
    DateTime? now,
  }) async {
    if (prefs == null || suggestionId.isEmpty) return;
    final current = (now ?? DateTime.now()).millisecondsSinceEpoch;
    final cutoff = current - dismissTtl.inMilliseconds;
    final map = <String, int>{};
    final raw = prefs.getString(prefsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        decoded.forEach((k, v) {
          if (v is num && v.toInt() >= cutoff) map[k] = v.toInt();
        });
      } catch (_) {}
    }
    map[suggestionId] = current;
    await prefs.setString(prefsKey, jsonEncode(map));
  }

  /// Aktif not için 0 krediyle en fazla [maxCount] (varsayılan 3) hayalet
  /// öneri üretir. Kilitli notta veya arşiv/çöpte daima boş döner.
  static List<GhostSuggestion> generate(
    Note note, {
    required QuickEntryMemory memory,
    String locale = 'tr',
    Set<String> dismissedKeys = const {},
    DateTime? now,
    int maxCount = 3,
  }) {
    if (note.locked || note.deletedAt != null || note.archivedAt != null) {
      return const [];
    }
    final existing = <String>{
      for (final item in note.items)
        if (!item.header && item.text.trim().isNotEmpty)
          quickItemKey(item.text),
    };
    final out = <GhostSuggestion>[];
    final seen = <String>{...existing};

    bool tryAdd(
      String rawText, {
      required GhostSuggestionReason reason,
      String? pairedWith,
    }) {
      if (out.length >= maxCount) return false;
      final clean = QuickSuggestionSanitizer.cleanItem(rawText);
      if (clean == null) return false;
      final key = quickItemKey(clean);
      if (key.isEmpty || seen.contains(key)) return false;
      final dismissKey = '${note.listMode.name}:$key';
      if (dismissedKeys.contains(dismissKey) || dismissedKeys.contains(key)) {
        return false;
      }
      seen.add(key);
      var category = '';
      if (note.listMode == ListMode.shopping) {
        final aisle =
            memory.itemGroups[key] ?? groceryLexicon(locale).groupOf(clean);
        if (aisle >= 0) category = aisleCategoryKey(aisle) ?? '';
      }
      out.add(
        GhostSuggestion(
          id: dismissKey,
          text: clean,
          reason: reason,
          category: category,
          pairedWith: pairedWith,
        ),
      );
      return true;
    }

    final isTr = locale.toLowerCase().startsWith('tr');

    switch (note.listMode) {
      case ListMode.shopping:
        // 1. Öncelik: satın alma aralığı dolmuş ürünler (predictDue).
        for (final kind in const ['smart:market', 'b:shopping']) {
          for (final d in memory.predictDue(kind, now: now, maxItems: 4)) {
            tryAdd(d.name, reason: GhostSuggestionReason.overdue);
          }
        }
        // 2. Öncelik: listedeki ürünlerle eşleşen tamamlayıcılar.
        final pairings = isTr ? _shoppingPairingsTr : _shoppingPairingsEn;
        for (final item in note.items) {
          if (item.header || item.text.trim().isEmpty) continue;
          final k = quickItemKey(item.text);
          final candidates = pairings[k];
          if (candidates == null) continue;
          for (final c in candidates) {
            if (tryAdd(
              c,
              reason: GhostSuggestionReason.pairing,
              pairedWith: item.text.trim(),
            )) {
              break; // Her mevcut ürün için en fazla 1 eşleşme öne çıksın.
            }
          }
        }
        // 3. Öncelik: temizlenmiş sık eklenen alışveriş ürünleri.
        for (final kind in const ['smart:market', 'b:shopping']) {
          for (final name in memory.top(kind, count: 8, min: 2)) {
            tryAdd(name, reason: GhostSuggestionReason.frequent);
          }
        }

      case ListMode.template:
        final essentials = isTr ? _packingEssentialsTr : _packingEssentialsEn;
        final kind = smartListKindFromId(note.listKind);
        final memKey = kind != SmartListKind.generic
            ? 'smart:${kind.name}'
            : 'mode:template';
        for (final name in memory.top(memKey, count: 6, min: 2)) {
          tryAdd(name, reason: GhostSuggestionReason.frequent);
        }
        for (final e in essentials) {
          tryAdd(e, reason: GhostSuggestionReason.essential);
        }

      case ListMode.routine:
        final slot = note.contextTimeSlot != ContextTimeSlot.any
            ? note.contextTimeSlot
            : _slotForTime(now ?? DateTime.now());
        final seeds = switch (slot) {
          ContextTimeSlot.morning =>
            isTr ? _routineMorningTr : _routineMorningEn,
          ContextTimeSlot.evening =>
            isTr ? _routineEveningTr : _routineEveningEn,
          ContextTimeSlot.weekend =>
            isTr ? _routineWeekendTr : _routineWeekendEn,
          ContextTimeSlot.any => isTr ? _routineMorningTr : _routineMorningEn,
        };
        for (final name in memory.top('smart:habits', count: 6, min: 2)) {
          tryAdd(name, reason: GhostSuggestionReason.frequent);
        }
        for (final s in seeds) {
          tryAdd(s, reason: GhostSuggestionReason.essential);
        }

      case ListMode.project:
      case ListMode.general:
        // Genel ve proje listelerinde yalnız kullanıcı geçmişinde gerçekten
        // sık tekrar eden, bu kiple uyumlu temiz öğeler önerilir (gürültü yok).
        final modeKey = note.listMode == ListMode.project
            ? 'mode:project'
            : 'drop';
        for (final name in memory.top(modeKey, count: 6, min: 2)) {
          if (QuickSuggestionSanitizer.isCompatibleWithMode(
            name,
            mode: note.listMode,
            locale: locale,
          )) {
            tryAdd(name, reason: GhostSuggestionReason.frequent);
          }
        }
    }

    return out;
  }

  static ContextTimeSlot _slotForTime(DateTime t) {
    if (t.weekday == DateTime.saturday || t.weekday == DateTime.sunday) {
      return ContextTimeSlot.weekend;
    }
    if (t.hour >= 5 && t.hour < 12) return ContextTimeSlot.morning;
    if (t.hour >= 18 || t.hour < 2) return ContextTimeSlot.evening;
    return ContextTimeSlot.any;
  }
}
