import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/rich_text.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'archive_template.dart';
import 'note_type.dart';

/// **HAZIR NOT MODLARI / ŞABLONLARI** (kullanıcı isteği 2026-09-26: "modlar,
/// alışveriş listesi gibi sen düşün ekle").
///
/// Her şablon bir not TİPİ + başlık + içerik üretir; not tek yazımda dolu
/// doğar (bkz. `NotesRepository.createNote`). Listeler (alışveriş, seyahat,
/// yapılacaklar) gerçek madde listesidir — işaretlenen madde alta iner,
/// "işaretlileri sil" çalışır; yazı şablonları defterdeki sayfa
/// şablonlarının (2026-09-23) aynı başlık biçimini kullanır, yeni bir biçim
/// türü yok.
///
/// 2026-09-29 GENİŞLETME (kullanıcı: "listeler şablonlar olmamış, daha
/// düzgün, gelişmiş özellikler olmalı"): şablonlar KATEGORİLİ
/// ([TemplateCategory]), liste şablonlarının ÖNERİ GRUPLARI var
/// ([templateSuggestions] — alışverişte manav/kahvaltılık/temizlik…), not
/// oluşmadan önce içerik ÖNİZLENİP DÜZENLENİYOR (bkz.
/// `note_template_sheet.dart`) ve kullanıcı kendi notunu şablon olarak
/// saklayabiliyor (bkz. `user_templates.dart`).
enum NoteTemplate {
  shopping,
  todo,
  travel,
  habits,
  cleaning,
  moving,
  gifts,
  watchlist,
  workout,
  weekly,
  goals,
  expense,
  meeting,
  journal,
  recipe,
  reading,
}

/// Şablon galerisinin bölümleri.
enum TemplateCategory { lists, planning, writing }

/// Şablondan doğacak notun içeriği.
typedef NoteTemplateContent = ({
  NoteType type,
  String title,
  String body,
  List<String> items,
});

extension NoteTemplateInfo on NoteTemplate {
  /// Kalıcı kimlik (son kullanılanlar listesinde saklanır). Enum adı:
  /// sıralama değişse de bozulmaz.
  String get key => name;

  TemplateCategory get category => switch (this) {
    NoteTemplate.shopping ||
    NoteTemplate.travel ||
    NoteTemplate.habits ||
    NoteTemplate.cleaning ||
    NoteTemplate.moving ||
    NoteTemplate.gifts ||
    NoteTemplate.watchlist ||
    NoteTemplate.workout => TemplateCategory.lists,
    NoteTemplate.todo ||
    NoteTemplate.weekly ||
    NoteTemplate.goals ||
    NoteTemplate.expense => TemplateCategory.planning,
    NoteTemplate.meeting ||
    NoteTemplate.journal ||
    NoteTemplate.recipe ||
    NoteTemplate.reading => TemplateCategory.writing,
  };

  String label(AppLocalizations l10n) => switch (this) {
    NoteTemplate.shopping => l10n.tplShoppingName,
    NoteTemplate.todo => l10n.archiveTemplateTodo,
    NoteTemplate.travel => l10n.tplTravelName,
    NoteTemplate.habits => l10n.tplHabitsName,
    NoteTemplate.cleaning => l10n.tplCleaningName,
    NoteTemplate.moving => l10n.tplMovingName,
    NoteTemplate.gifts => l10n.tplGiftsName,
    NoteTemplate.watchlist => l10n.tplWatchlistName,
    NoteTemplate.workout => l10n.tplWorkoutName,
    NoteTemplate.goals => l10n.tplGoalsName,
    NoteTemplate.meeting => l10n.archiveTemplateMeeting,
    NoteTemplate.journal => l10n.archiveTemplateJournal,
    NoteTemplate.recipe => l10n.tplRecipeName,
    NoteTemplate.weekly => l10n.tplWeeklyName,
    NoteTemplate.expense => l10n.archiveTemplateExpense,
    NoteTemplate.reading => l10n.archiveTemplateReading,
  };

  String description(AppLocalizations l10n) => switch (this) {
    NoteTemplate.shopping => l10n.tplShoppingDesc,
    NoteTemplate.todo => l10n.tplTodoDesc,
    NoteTemplate.travel => l10n.tplTravelDesc,
    NoteTemplate.habits => l10n.tplHabitsDesc,
    NoteTemplate.cleaning => l10n.tplCleaningDesc,
    NoteTemplate.moving => l10n.tplMovingDesc,
    NoteTemplate.gifts => l10n.tplGiftsDesc,
    NoteTemplate.watchlist => l10n.tplWatchlistDesc,
    NoteTemplate.workout => l10n.tplWorkoutDesc,
    NoteTemplate.goals => l10n.tplGoalsDesc,
    NoteTemplate.meeting => l10n.tplMeetingDesc,
    NoteTemplate.journal => l10n.tplJournalDesc,
    NoteTemplate.recipe => l10n.tplRecipeDesc,
    NoteTemplate.weekly => l10n.tplWeeklyDesc,
    NoteTemplate.expense => l10n.tplExpenseDesc,
    NoteTemplate.reading => l10n.tplReadingDesc,
  };

  IconData get icon => switch (this) {
    NoteTemplate.shopping => Icons.shopping_cart_outlined,
    NoteTemplate.todo => Icons.task_alt,
    NoteTemplate.travel => Icons.luggage_outlined,
    NoteTemplate.habits => Icons.repeat,
    NoteTemplate.cleaning => Icons.cleaning_services_outlined,
    NoteTemplate.moving => Icons.local_shipping_outlined,
    NoteTemplate.gifts => Icons.card_giftcard,
    NoteTemplate.watchlist => Icons.movie_outlined,
    NoteTemplate.workout => Icons.fitness_center,
    NoteTemplate.goals => Icons.flag_outlined,
    NoteTemplate.meeting => Icons.groups_outlined,
    NoteTemplate.journal => Icons.wb_sunny_outlined,
    NoteTemplate.recipe => Icons.restaurant_menu,
    NoteTemplate.weekly => Icons.view_week_outlined,
    NoteTemplate.expense => Icons.payments_outlined,
    NoteTemplate.reading => Icons.menu_book_outlined,
  };

  /// Şablonun rengi — levhadaki simge kutusu (klasör renk dilinin aynısı).
  Color get accent => switch (this) {
    NoteTemplate.shopping => const Color(0xFF6DA84C),
    NoteTemplate.todo => const Color(0xFF4F8FD6),
    NoteTemplate.travel => const Color(0xFF2FA392),
    NoteTemplate.habits => const Color(0xFF3FA37A),
    NoteTemplate.cleaning => const Color(0xFF3B9BC4),
    NoteTemplate.moving => const Color(0xFFB8864B),
    NoteTemplate.gifts => const Color(0xFFD65C7A),
    NoteTemplate.watchlist => const Color(0xFF6C6FD1),
    NoteTemplate.workout => const Color(0xFFE07A3A),
    NoteTemplate.goals => const Color(0xFFC9A227),
    NoteTemplate.meeting => const Color(0xFF8E74D0),
    NoteTemplate.journal => const Color(0xFFD9982B),
    NoteTemplate.recipe => const Color(0xFFE0685C),
    NoteTemplate.weekly => const Color(0xFF7D8799),
    NoteTemplate.expense => const Color(0xFFD06A95),
    NoteTemplate.reading => const Color(0xFF4F8FD6),
  };
}

/// Liste şablonunun ÖNERİ GRUBU: başlık + madde önerileri. Önizleme
/// adımında çip olarak durur; dokunulan öneri listeye girer.
typedef TemplateSuggestionGroup = ({String label, List<String> items});

/// Liste şablonlarının hazır öneri grupları (kullanıcı isteği 2026-09-29:
/// "daha gelişmiş"). Alışveriş listesinin beş maddesi herkes için yanlıştı —
/// artık varsayılan maddeler küçük kalıyor, gerisi reyon reyon ÖNERİ.
/// Grubu olmayan şablon boş liste döner.
List<TemplateSuggestionGroup> templateSuggestions(
  NoteTemplate template,
  AppLocalizations l10n,
) => switch (template) {
  NoteTemplate.shopping => [
    (label: l10n.tplShopProduce, items: _split(l10n.tplShopProduceItems)),
    (label: l10n.tplShopBreakfast, items: _split(l10n.tplShopBreakfastItems)),
    (label: l10n.tplShopPantry, items: _split(l10n.tplShopPantryItems)),
    (label: l10n.tplShopCleaning, items: _split(l10n.tplShopCleaningItems)),
    (label: l10n.tplShopPersonal, items: _split(l10n.tplShopPersonalItems)),
  ],
  NoteTemplate.travel => [
    (label: l10n.tplTravelDocs, items: _split(l10n.tplTravelDocsItems)),
    (label: l10n.tplTravelClothes, items: _split(l10n.tplTravelClothesItems)),
    (label: l10n.tplTravelCare, items: _split(l10n.tplTravelCareItems)),
    (label: l10n.tplTravelTech, items: _split(l10n.tplTravelTechItems)),
  ],
  _ => const [],
};

/// Virgülle ayrılmış çeviri listesini maddelere böler.
List<String> _split(String csv) => [
  for (final s in csv.split(','))
    if (s.trim().isNotEmpty) s.trim(),
];

/// Şablonun içeriği; tarih ve gün adları uygulamanın dilinde.
NoteTemplateContent buildNoteTemplate(
  NoteTemplate template,
  AppLocalizations l10n, {
  DateTime? now,
}) {
  final today = now ?? DateTime.now();
  final locale = l10n.localeName;
  final date = DateFormat.yMMMMEEEEd(locale).format(today);
  final shortDate = DateFormat.MMMMd(locale).format(today);
  TemplateLine h(String t) => (text: t, heading: RichHeading.h2);
  TemplateLine p(String t) => (text: t, heading: RichHeading.normal);
  NoteTemplateContent text(String title, List<TemplateLine> lines) => (
    type: NoteType.text,
    title: title,
    body: buildTemplateText(lines),
    items: const [],
  );
  NoteTemplateContent list(String title, List<String> items) => (
    type: NoteType.checklist,
    title: title,
    body: '',
    items: items,
  );
  return switch (template) {
    NoteTemplate.shopping => list(
      l10n.tplShoppingName,
      _split(l10n.tplShoppingItems),
    ),
    NoteTemplate.todo => list('${l10n.archiveTemplateTodo} · $shortDate', const []),
    NoteTemplate.travel => list(
      l10n.tplTravelName,
      _split(l10n.tplTravelItems),
    ),
    NoteTemplate.habits => list(
      '${l10n.tplHabitsName} · $shortDate',
      _split(l10n.tplHabitsItems),
    ),
    NoteTemplate.cleaning => list(
      l10n.tplCleaningName,
      _split(l10n.tplCleaningItems),
    ),
    NoteTemplate.moving => list(
      l10n.tplMovingName,
      _split(l10n.tplMovingItems),
    ),
    NoteTemplate.gifts => list(l10n.tplGiftsName, _split(l10n.tplGiftsItems)),
    NoteTemplate.watchlist => list(l10n.tplWatchlistName, const []),
    NoteTemplate.workout => list(
      '${l10n.tplWorkoutName} · $shortDate',
      _split(l10n.tplWorkoutItems),
    ),
    NoteTemplate.goals => text('${l10n.tplGoalsName} · ${today.year}', [
      h(l10n.tplGoalsYear),
      p('☐ '),
      h(l10n.tplGoalsMonth),
      p('☐ '),
      h(l10n.tplGoalsWeek),
      p('☐ '),
      h(l10n.tplGoalsWhy),
      p(''),
    ]),
    NoteTemplate.meeting => text('${l10n.archiveTemplateMeeting} · $shortDate', [
      h(l10n.tplMeetingAttendees),
      p('• '),
      h(l10n.tplMeetingAgenda),
      p('1. '),
      h(l10n.tplMeetingDecisions),
      p('• '),
      h(l10n.tplMeetingActions),
      p('☐ '),
    ]),
    NoteTemplate.journal => text(date, [
      h(l10n.tplJournalHow),
      p(''),
      h(l10n.tplJournalGrateful),
      p('• '),
      h(l10n.tplJournalTomorrow),
      p('• '),
    ]),
    NoteTemplate.recipe => text(l10n.tplRecipeName, [
      p(l10n.tplRecipeMeta),
      h(l10n.tplRecipeIngredients),
      p('• '),
      h(l10n.tplRecipeSteps),
      p('1. '),
      h(l10n.tplRecipeNotes),
      p(''),
    ]),
    NoteTemplate.weekly => () {
      // Bu haftanın pazartesisinden pazarına, gün adları dilde.
      final monday = DateTime(
        today.year,
        today.month,
        today.day,
      ).subtract(Duration(days: today.weekday - DateTime.monday));
      final day = DateFormat.EEEE(locale);
      final dm = DateFormat.MMMd(locale);
      return text(
        '${l10n.tplWeeklyName} · ${dm.format(monday)}',
        [
          for (var i = 0; i < 7; i++) ...[
            h(
              '${day.format(monday.add(Duration(days: i)))} · '
              '${dm.format(monday.add(Duration(days: i)))}',
            ),
            p('• '),
          ],
        ],
      );
    }(),
    NoteTemplate.expense => text(
      '${l10n.archiveTemplateExpense} · ${DateFormat.yMMMM(locale).format(today)}',
      [p(l10n.tplExpenseColumns), p(''), p(''), h(l10n.tplExpenseTotal)],
    ),
    NoteTemplate.reading => text(l10n.archiveTemplateReading, [
      h(l10n.tplReadingSource),
      p(''),
      h(l10n.tplReadingSummary),
      p(''),
      h(l10n.tplReadingQuotes),
      p('“ ”'),
      h(l10n.tplReadingThoughts),
      p(''),
    ]),
  };
}
