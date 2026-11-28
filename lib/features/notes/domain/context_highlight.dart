import 'list_mode.dart';
import 'note.dart';
import 'note_type.dart';

/// **GÜNÜN SAATİNE GÖRE BAĞLAMSAL ÖNE ÇIKARMA MOTORU** (Faz 3):
///
/// Kullanıcının `contextTimeSlot` (`morning`, `evening`, `weekend`) ayarı veya
/// kullanım geçmişi (`contextBoost` puanları) ile mevcut gün/saat dilimi
/// eşleşen notları belirler. Kilitli, arşivlenmiş veya çöp kutusundaki notları
/// ASLA öne çıkarmaz.
abstract final class ContextHighlightEngine {
  /// Verilen an için etkin gün/saat dilimlerini döndürür.
  /// Hafta sonunda hem `weekend` hem de saatine göre `morning`/`evening`
  /// etkin olabilir.
  static Set<ContextTimeSlot> activeSlots(DateTime now) {
    final slots = <ContextTimeSlot>{};
    if (now.weekday == DateTime.saturday || now.weekday == DateTime.sunday) {
      slots.add(ContextTimeSlot.weekend);
    }
    if (now.hour >= 5 && now.hour < 12) {
      slots.add(ContextTimeSlot.morning);
    } else if (now.hour >= 18 && now.hour <= 23) {
      slots.add(ContextTimeSlot.evening);
    }
    return slots;
  }

  /// Notun şu anki zaman dilimiyle doğrudan eşleşip eşleşmediği.
  static bool matchesNow(Note note, DateTime now) {
    if (!_eligible(note)) return false;
    if (note.contextTimeSlot == ContextTimeSlot.any) return false;
    return activeSlots(now).contains(note.contextTimeSlot);
  }

  /// Ana ekran kartlarında "Şimdi" rozeti gösterilecek not kimlikleri (en çok
  /// [maxHighlighted] adet; ana duvarı boğmaz).
  static Set<String> highlightedNoteIds(
    List<Note> notes, {
    DateTime? now,
    Map<String, int> contextBoost = const {},
    int maxHighlighted = 2,
  }) {
    final t = now ?? DateTime.now();
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    final scored = <({String id, double score, DateTime updatedAt})>[];
    for (final note in notes) {
      if (!_eligible(note)) continue;
      final score = _scoreNote(note, t, contextBoost[note.id] ?? 0);
      if (score >= 1.0) {
        scored.add((
          id: note.id,
          score: score,
          updatedAt: note.updatedAt ?? epoch,
        ));
      }
    }
    scored.sort((a, b) {
      final c = b.score.compareTo(a.score);
      if (c != 0) return c;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return {for (final s in scored.take(maxHighlighted)) s.id};
  }

  /// Hızlı Ekle boş hâlinde öne çıkarılacak en uygun tek bağlam notunu seçer.
  static Note? topHighlight(
    List<Note> notes, {
    DateTime? now,
    Map<String, int> contextBoost = const {},
  }) {
    final t = now ?? DateTime.now();
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    Note? best;
    var bestScore = 0.0;
    for (final note in notes) {
      if (!_eligible(note)) continue;
      final score = _scoreNote(note, t, contextBoost[note.id] ?? 0);
      final noteTime = note.updatedAt ?? epoch;
      final bestTime = best?.updatedAt ?? epoch;
      if (score >= 1.0 &&
          (score > bestScore ||
              (score == bestScore && best != null && noteTime.isAfter(bestTime)))) {
        best = note;
        bestScore = score;
      }
    }
    return best;
  }

  static bool _eligible(Note note) {
    if (note.locked || note.deletedAt != null || note.archivedAt != null) {
      return false;
    }
    if (note.displayTitle.trim().isEmpty) return false;
    return true;
  }

  static double _scoreNote(Note note, DateTime now, int boost) {
    var score = 0.0;
    final active = activeSlots(now);
    if (note.contextTimeSlot != ContextTimeSlot.any &&
        active.contains(note.contextTimeSlot)) {
      score += 3.0;
      // Rutin notta henüz tamamlanmamış maddeler varsa daha anlamlı.
      if (note.listMode == ListMode.routine &&
          note.items.any((i) => !i.header && !i.checked)) {
        score += 1.0;
      }
    } else if (note.type == NoteType.checklist &&
        note.listMode == ListMode.shopping &&
        active.contains(ContextTimeSlot.weekend) &&
        note.items.any((i) => !i.header && !i.checked)) {
      // Hafta sonu açık alışveriş listesine hafif destek.
      score += 1.2;
    }
    if (boost >= 3) {
      score += 1.5 + (boost.clamp(3, 12) * 0.1);
    }
    return score;
  }
}
