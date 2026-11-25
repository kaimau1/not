import 'dart:async';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../l10n/generated/app_localizations_en.dart';
import '../../../l10n/generated/app_localizations_tr.dart';
import '../../settings/settings_providers.dart';
import '../domain/note.dart';
import '../domain/note_item.dart';
import '../domain/note_type.dart';
import 'notes_repository.dart';

/// Faz 4 — **İlk 60 saniye "Vay Be" başlangıç notları** (PLAN §7.3):
/// Yepyeni boş hesapta 2 etkileşimli örnek not hazır gelir:
///  1. `🛒 Örnek Market Listesi` (3 reyonlu, hemen Mağaza Kipi'ni denetir)
///  2. `⚡ Hızlı Başlangıç` (sesle ekle, belge tara, defterde çiz)
///
/// Yalnızca cihazda bir kez (`kStarterNotesSeededKey`) ve not listesi gerçekten
/// boşken üretilir; mevcut kullanıcıların verisine asla dokunmaz.
const kStarterNotesSeededKey = 'starter_notes_seeded_v1';

/// Yalnızca gerçek uygulama başlangıcında (`main.dart`) açılır; birim/widget
/// testlerinde boş hesap varsayımı bozulmasın diye varsayılan kapalıdır.
abstract final class StarterNotesConfig {
  static bool allowAutoSeed = false;
}

List<Note> buildStarterNotes({bool english = false}) {
  final now = DateTime.now();
  final l10n = english ? AppLocalizationsEn() : AppLocalizationsTr();
  if (english) {
    return [
      Note(
        id: 'starter_shopping',
        type: NoteType.checklist,
        title: l10n.starterShoppingTitle,
        tags: const ['shopping'],
        orderIndex: -now.millisecondsSinceEpoch.toDouble(),
        items: const [
          NoteItem(
            id: 's1',
            text: '2 L milk',
            extras: {'q': 2, 'u': 'lt', 'g': 'dairy'},
          ),
          NoteItem(
            id: 's2',
            text: '1 kg tomatoes',
            extras: {'q': 1, 'u': 'kg', 'g': 'produce'},
          ),
          NoteItem(
            id: 's3',
            text: 'Sourdough bread',
            extras: {'q': 1, 'u': 'adet', 'g': 'bakery'},
          ),
          NoteItem(
            id: 's4',
            text: '12 eggs',
            extras: {'q': 12, 'u': 'adet', 'g': 'dairy'},
          ),
        ],
      ),
      Note(
        id: 'starter_welcome',
        type: NoteType.checklist,
        title: l10n.starterWelcomeTitle,
        orderIndex: -(now.millisecondsSinceEpoch - 1000).toDouble(),
        items: const [
          NoteItem(
            id: 'w1',
            text: 'Tap Store Mode above your shopping list for one-hand aisles & budget',
          ),
          NoteItem(
            id: 'w2',
            text: 'Try the mic button on home to dictate notes & reminders in seconds',
          ),
          NoteItem(
            id: 'w3',
            text: 'Scan a document or annotate any PDF with your pen',
          ),
        ],
      ),
    ];
  }
  return [
    Note(
      id: 'starter_shopping',
      type: NoteType.checklist,
      title: l10n.starterShoppingTitle,
      tags: const ['alışveriş'],
      orderIndex: -now.millisecondsSinceEpoch.toDouble(),
      items: const [
        NoteItem(
          id: 's1',
          text: '2 lt süt',
          extras: {'q': 2, 'u': 'lt', 'g': 'sut'},
        ),
        NoteItem(
          id: 's2',
          text: '1 kg domates',
          extras: {'q': 1, 'u': 'kg', 'g': 'manav'},
        ),
        NoteItem(
          id: 's3',
          text: '1 adet ekşi maya ekmek',
          extras: {'q': 1, 'u': 'adet', 'g': 'firin'},
        ),
        NoteItem(
          id: 's4',
          text: '15 adet yumurta',
          extras: {'q': 15, 'u': 'adet', 'g': 'sut'},
        ),
      ],
    ),
    Note(
      id: 'starter_welcome',
      type: NoteType.checklist,
      title: l10n.starterWelcomeTitle,
      orderIndex: -(now.millisecondsSinceEpoch - 1000).toDouble(),
      items: const [
        NoteItem(
          id: 'w1',
          text: 'Market listesinde üstteki Mağaza Kipi ile reyon ve bütçeni tek elle yönet',
        ),
        NoteItem(
          id: 'w2',
          text: 'Ana ekrandaki mikrofonla sesli not ve hatırlatıcı ekle',
        ),
        NoteItem(
          id: 'w3',
          text: 'Belge tara veya PDF üstüne kalemle doğrudan not al',
        ),
      ],
    ),
  ];
}

/// Hesap ilk kez boş açıldığında başlangıç notlarını bir defalık üretir.
Future<bool> seedStarterNotesIfNeeded({
  required SharedPreferences prefs,
  required bool hasExistingNotes,
  required Future<void> Function(Note note) saveNote,
  bool english = false,
}) async {
  if (prefs.getBool(kStarterNotesSeededKey) ?? false) return false;
  await prefs.setBool(kStarterNotesSeededKey, true);
  if (hasExistingNotes) return false;
  for (final note in buildStarterNotes(english: english)) {
    await saveNote(note);
  }
  return true;
}

/// Oturum açıkken ilk gerçek not anlık görüntüsünde (boşsa) başlangıç notlarını
/// tek seferlik ekler (`AppServices` kademeli başlangıcından çağrılır).
final starterNotesSeederProvider = Provider<void>((ref) {
  if (!StarterNotesConfig.allowAutoSeed) return;
  final prefs = ref.read(sharedPreferencesProvider);
  if (prefs.getBool(kStarterNotesSeededKey) ?? false) return;
  final repo = ref.watch(notesRepositoryProvider);
  if (repo == null) return;
  final notesAsync = ref.watch(notesStreamProvider);
  final notes = notesAsync.value;
  if (notes == null) return;
  final locale = ref.read(localeProvider);
  final lang =
      locale?.languageCode ?? PlatformDispatcher.instance.locale.languageCode;
  unawaited(
    seedStarterNotesIfNeeded(
      prefs: prefs,
      hasExistingNotes: notes.isNotEmpty,
      saveNote: repo.updateNote,
      english: lang != 'tr',
    ),
  );
});
