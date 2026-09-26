import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:notlar/core/utils/rich_text.dart';
import 'package:notlar/features/notes/domain/note_templates.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// Hazır not şablonları (kullanıcı isteği 2026-09-26: "modlar, alışveriş
/// listesi gibi").
void main() {
  late AppLocalizations l10n;
  setUpAll(() async {
    await initializeDateFormatting('tr');
    l10n = lookupAppLocalizations(const Locale('tr'));
  });

  final monday = DateTime(2026, 9, 28); // pazartesi

  test('alışveriş listesi: madde listesi, hazır maddeler', () {
    final c = buildNoteTemplate(NoteTemplate.shopping, l10n, now: monday);
    expect(c.type, NoteType.checklist);
    expect(c.title, 'Alışveriş listesi');
    expect(c.items, ['Ekmek', 'Süt', 'Yumurta', 'Meyve', 'Sebze']);
  });

  test('yapılacaklar tarihli ve boş', () {
    final c = buildNoteTemplate(NoteTemplate.todo, l10n, now: monday);
    expect(c.type, NoteType.checklist);
    expect(c.title, contains('28 Eylül'));
    expect(c.items, isEmpty);
  });

  test('haftalık plan yedi gün başlığı taşır', () {
    final c = buildNoteTemplate(
      NoteTemplate.weekly,
      l10n,
      now: DateTime(2026, 10, 1), // çarşamba → hafta 28 Eylül'de başlar
    );
    expect(c.type, NoteType.text);
    final plain = stripRichMarkers(c.body);
    for (final day in ['Pazartesi', 'Salı', 'Çarşamba', 'Pazar']) {
      expect(plain, contains(day));
    }
    expect(c.title, contains('28 Eyl'));
  });

  test('her şablon içerik üretir', () {
    for (final t in NoteTemplate.values) {
      final c = buildNoteTemplate(t, l10n, now: monday);
      expect(c.title, isNotEmpty, reason: '$t');
      expect(c.body.isNotEmpty || c.type == NoteType.checklist, isTrue);
      expect(t.label(l10n), isNotEmpty);
      expect(t.description(l10n), isNotEmpty);
    }
  });
}
