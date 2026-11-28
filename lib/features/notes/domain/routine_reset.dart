import 'list_mode.dart';
import 'note.dart';
import 'note_item.dart';
import 'note_type.dart';

/// Rutin / alışkanlık listelerinin dönemsel tik sıfırlama motoru.
///
/// Kural 2 (Tek Gerçek Kaynak): sıfırlama yalnızca `item.checked` işaretini
/// temizler; tüm maddeler ve `item.doneDays` geçmişi aynen korunur. `streakCount`
/// deterministik olarak `doneDays` üzerinden hesaplandığı için sıfırlama seriyi
/// asla bozmaz.
class RoutineResetEngine {
  RoutineResetEngine._();

  /// [note] için [now] anının içinde bulunduğu dönemin başlangıcı (yerel 00:00).
  /// Sıfırlama kapalıysa ya da not rutin kipinde değilse `null` döner.
  static DateTime? currentPeriodStart(Note note, DateTime now) {
    if (note.type != NoteType.checklist ||
        note.listMode != ListMode.routine ||
        note.resetSchedule == ResetSchedule.none) {
      return null;
    }
    final today = DateTime(now.year, now.month, now.day);
    return switch (note.resetSchedule) {
      ResetSchedule.none => null,
      ResetSchedule.daily => today,
      ResetSchedule.weekly => today.subtract(
        Duration(days: today.weekday - DateTime.monday),
      ),
      ResetSchedule.customDays => _mostRecentCustomDay(
        today,
        note.resetCustomDays,
      ),
    };
  }

  static DateTime _mostRecentCustomDay(DateTime today, List<int> customDays) {
    final valid = {
      for (final d in customDays)
        if (d >= DateTime.monday && d <= DateTime.sunday) d,
    };
    if (valid.isEmpty) return today;
    for (var offset = 0; offset < 7; offset++) {
      final candidate = today.subtract(Duration(days: offset));
      if (valid.contains(candidate.weekday)) return candidate;
    }
    return today;
  }

  /// Maddenin [periodStart] veya sonrasında tamamlandığı kayıtlı mı?
  static bool _isCompletedInPeriod(NoteItem item, DateTime periodStart) {
    for (var i = item.doneDays.length - 1; i >= 0; i--) {
      final d = parseIsoDayKeyLocal(item.doneDays[i]);
      if (d == null) continue;
      if (!d.isBefore(periodStart)) return true;
      break;
    }
    return false;
  }

  /// [note] yeni bir sıfırlama dönemine geçmiş ve sıfırlanmayı bekleyen
  /// işaretli maddeler taşıyor mu?
  ///
  /// Kilitli, silinmiş, arşivlenmiş veya zaten bu dönemde sıfırlanmış notlar
  /// atlanır. Ayrıca bu dönem içinde tamamlandığı `doneDays` ile kanıtlanan
  /// maddeler asla sıfırlanmaz (çoklu cihaz / yeni oluşturulan rutin koruması).
  static bool needsReset(Note note, DateTime now) {
    if (note.locked || note.deletedAt != null || note.archivedAt != null) {
      return false;
    }
    final periodStart = currentPeriodStart(note, now);
    if (periodStart == null) return false;
    if (note.lastResetAt != null && !note.lastResetAt!.isBefore(periodStart)) {
      return false;
    }
    return note.items.any(
      (i) => !i.header && i.checked && !_isCompletedInPeriod(i, periodStart),
    );
  }

  /// [note] içindeki önceki dönemden kalan tikleri kaldırır; tüm maddeleri ve
  /// `doneDays` geçmişini korur, `lastResetAt` alanını dönem başlangıcına çeker.
  static Note resetNote(Note note, DateTime now) {
    final periodStart = currentPeriodStart(note, now);
    if (periodStart == null) return note;
    final items = [
      for (final i in note.items)
        if (!i.header && i.checked && !_isCompletedInPeriod(i, periodStart))
          i.copyWith(checked: false)
        else
          i,
    ];
    return note.copyWith(items: items, lastResetAt: periodStart);
  }

  /// Sıfırlanması gereken notları süzüp `NotesRepository.batchUpdateEach` için
  /// saf alan güncellemesi haritası kurar (`lastResetAt` [DateTime] döner; depo
  /// katmanı Firestore `Timestamp`'a çevirir).
  static List<({Note note, DateTime periodStart, List<NoteItem> items})>
  dueResets(Iterable<Note> notes, DateTime now) {
    final out = <({Note note, DateTime periodStart, List<NoteItem> items})>[];
    for (final note in notes) {
      if (!needsReset(note, now)) continue;
      final periodStart = currentPeriodStart(note, now)!;
      final updated = resetNote(note, now);
      out.add((note: note, periodStart: periodStart, items: updated.items));
    }
    return out;
  }
}
