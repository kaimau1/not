import 'dart:async';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../l10n/generated/app_localizations_en.dart';
import '../../../l10n/generated/app_localizations_tr.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../folders/data/folders_repository.dart';
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
/// Yalnızca hesap başına bir kez (`starterNotesSeededKeyFor`) ve not/klasör
/// listesi gerçekten boşken üretilir; mevcut kullanıcıların verisine dokunmaz.
const kStarterNotesSeededKey = 'starter_notes_seeded_v1';

String starterNotesSeededKeyFor(String? uid) =>
    (uid == null || uid.isEmpty)
    ? kStarterNotesSeededKey
    : '${kStarterNotesSeededKey}_$uid';

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
        listKind: 'shopping',
        title: l10n.starterShoppingTitle,
        tags: const ['shopping'],
        orderIndex: -now.millisecondsSinceEpoch.toDouble(),
        items: const [
          NoteItem(
            id: 's1',
            text: 'Milk (2 lt)',
            extras: {'q': 2, 'u': 'lt', 'g': 2},
          ),
          NoteItem(
            id: 's2',
            text: 'Tomatoes (1 kg)',
            extras: {'q': 1, 'u': 'kg', 'g': 0},
          ),
          NoteItem(
            id: 's3',
            text: 'Sourdough bread (1 adet)',
            extras: {'q': 1, 'u': 'adet', 'g': 1},
          ),
          NoteItem(
            id: 's4',
            text: 'Eggs (12 adet)',
            extras: {'q': 12, 'u': 'adet', 'g': 2},
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
      listKind: 'shopping',
      title: l10n.starterShoppingTitle,
      tags: const ['alışveriş'],
      orderIndex: -now.millisecondsSinceEpoch.toDouble(),
      items: const [
        NoteItem(
          id: 's1',
          text: 'Süt (2 lt)',
          extras: {'q': 2, 'u': 'lt', 'g': 2},
        ),
        NoteItem(
          id: 's2',
          text: 'Domates (1 kg)',
          extras: {'q': 1, 'u': 'kg', 'g': 0},
        ),
        NoteItem(
          id: 's3',
          text: 'Ekşi maya ekmek (1 adet)',
          extras: {'q': 1, 'u': 'adet', 'g': 1},
        ),
        NoteItem(
          id: 's4',
          text: 'Yumurta (15 adet)',
          extras: {'q': 15, 'u': 'adet', 'g': 2},
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
  String key = kStarterNotesSeededKey,
}) async {
  if (prefs.getBool(key) ?? false) return false;
  await prefs.setBool(key, true);
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
  final uid = ref.watch(currentUidProvider);
  final seedKey = starterNotesSeededKeyFor(uid);
  if (prefs.getBool(seedKey) ?? false) return;
  final repo = ref.watch(notesRepositoryProvider);
  if (repo == null) return;
  final notes = ref.watch(notesStreamProvider).value;
  final folders = ref.watch(foldersStreamProvider).value;
  if (notes == null || folders == null) return;
  final locale = ref.read(localeProvider);
  final lang =
      locale?.languageCode ?? PlatformDispatcher.instance.locale.languageCode;
  unawaited(
    seedStarterNotesIfNeeded(
      prefs: prefs,
      hasExistingNotes: notes.isNotEmpty || folders.isNotEmpty,
      saveNote: repo.updateNote,
      english: lang != 'tr',
      key: seedKey,
    ),
  );
});
