import '../core/app_icons.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/l10n_ext.dart';
import '../features/folders/domain/note_folder.dart';
import '../features/folders/presentation/shared_folder_home.dart';
import '../features/notes/data/notes_repository.dart';
import '../features/notes/domain/note_type.dart';
import '../features/notes/presentation/notes_providers.dart';
import '../features/notes/presentation/quick_add_actions.dart';
import 'router.dart';
import 'split_shell.dart'
    show isNoteLocation, noteFullscreenProvider, splitActiveFor;

/// **UYGULAMA KOMUTLARI** — gezinme rayı, klavye kısayolları ve boş sağ
/// panel aynı işleri (yeni not, arama, bölüm değiştirme) yapıyor; üç yerde
/// üç ayrı kopya olmasın diye burada toplandı.
///
/// Kullanıcı isteği 2026-09-22: "tablet gibi geniş ekranlı cihazlarda
/// kullanımını baştan tasarlamalıyız, onlara özel özellikler getirmeliyiz."
/// Fareli/klavyeli tablet ve web'de kısayollar bu dosyadan gelir.

/// Arama kutusuna odak İSTEĞİ. Ana ekran bu sayacı dinler ve kendi
/// kutusuna odaklanır; sayaç (bool değil) — aynı istek art arda iki kez
/// gelirse ikincisi de duyulsun.
final searchFocusRequestProvider = NotifierProvider<_Counter, int>(
  _Counter.new,
);

class _Counter extends Notifier<int> {
  @override
  int build() => 0;

  void request() => state++;
}

/// Rayın bölümleri. Sıra rayın ve Alt+1…8 kısayollarının sırasıdır.
///
/// Klasörler ve Gelen notlar 2026-09-22'de eklendi (kullanıcı: "eklensin").
enum AppSection {
  notes('/', Icons.sticky_note_2_outlined, Icons.sticky_note_2),
  folders('/folders', Icons.folder_outlined, Icons.folder),
  inbox('/inbox', AppIcons.inbox, AppIcons.inboxSelected),
  ai('/ai', Icons.auto_awesome_outlined, Icons.auto_awesome),
  // Takvim, Hatırlatıcılar'ın yerine (TAKVIM_PLANI K5): hatırlatıcılar
  // takvimde görünür, liste takvimin çubuğundan açılır.
  calendar('/calendar', Icons.calendar_month_outlined, Icons.calendar_month),
  archive('/archive', AppIcons.archive, AppIcons.archiveSelected),
  trash('/trash', Icons.delete_outline, Icons.delete),
  settings('/settings', Icons.settings_outlined, Icons.settings);

  const AppSection(this.path, this.icon, this.selectedIcon);

  final String path;
  final IconData icon;
  final IconData selectedIcon;

  String label(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      AppSection.notes => l10n.navNotes,
      AppSection.folders => l10n.foldersTitle,
      AppSection.inbox => l10n.sharedHubTitle,
      AppSection.ai => l10n.aiHubTitle,
      AppSection.calendar => l10n.calendarTitle,
      AppSection.archive => l10n.archiveTitle,
      AppSection.trash => l10n.trashTitle,
      AppSection.settings => l10n.settings,
    };
  }

  /// Bir konumun hangi bölüme ait olduğu. Not/defter ekranları notlar
  /// bölümünün içindedir; sohbet ve brifing yapay zekânın.
  static AppSection? of(String location) {
    if (location == '/' ||
        location.startsWith('/note/') ||
        location.startsWith('/notebook/')) {
      return AppSection.notes;
    }
    if (location.startsWith('/ai') ||
        location.startsWith('/chat') ||
        location.startsWith('/briefing')) {
      return AppSection.ai;
    }
    if (location.startsWith('/reminders') || location.startsWith('/tasks')) {
      return AppSection.calendar;
    }
    if (location.startsWith('/settings') ||
        location.startsWith('/privacy') ||
        location.startsWith('/premium')) {
      return AppSection.settings;
    }
    for (final s in AppSection.values) {
      if (s != AppSection.notes && location.startsWith(s.path)) return s;
    }
    return null;
  }
}

/// Yönlendiricinin ŞU ANKİ konumu — imperatif push'lar DAHİL.
///
/// TUZAK: `currentConfiguration.uri` yalnız son `go` konumunu verir; üstüne
/// push'lanmış ekranı (ör. notların üstündeki Arşiv) görmez. En üstteki
/// eşleşmenin durumu (`router.state`) ikisini de kapsıyor.
String currentLocation(GoRouter router) => router.state.uri.path;

/// Bir bölüme geç.
///
/// Notlar bölümüne dönüş, yığını SİLMEZ (`go('/')` yerine geri çıkılır):
/// geniş ekranda sağ panelde açık duran not, ayarlara bakıp dönünce
/// kapanmış olmasın. Diğer bölümler notların ÜSTÜNE tek katman olarak
/// açılır; bölümden bölüme geçiş o katmanı DEĞİŞTİRİR (yığın büyümez), bu
/// sayede ekranların kendi geri düğmeleri de çalışmaya devam eder.
void openSection(GoRouter router, AppSection section) {
  final here = AppSection.of(currentLocation(router));
  if (section == AppSection.notes) {
    var guard = 0;
    while (AppSection.of(currentLocation(router)) != AppSection.notes &&
        router.canPop() &&
        guard++ < 8) {
      router.pop();
    }
    if (AppSection.of(currentLocation(router)) != AppSection.notes) {
      router.go('/');
    }
    return;
  }
  if (here == section) return;
  if (here == AppSection.notes || here == null) {
    router.push(section.path);
  } else {
    router.pushReplacement(section.path);
  }
}

/// **ANA SAYFAYA DÖN** (F28.3): her ekrandan tek dokunuşla `/`. Yığın
/// TEMİZLENİR (`go`); açık not editörü sökülürken kaydını kendisi yazar
/// (dispose'ta flush). Tam ekran kipi de kapanır ki liste gizli kalmasın.
void goHome(WidgetRef ref, GoRouter router) {
  ref.read(noteFullscreenProvider.notifier).set(false);
  router.go('/');
}

/// Dar web'de üst "Ana sayfa" çubuğu açık mı (telefonda kapalı — yalnız web).
/// Testte değiştirilebilir.
bool homeBarOnNarrow = kIsWeb;

/// **Ana ekranın dışarıdan çağrılan kapıları** (K3, F44.5): oluşturma akışları,
/// süzgeç ve seçim ana ekranın State'inde; ray ve kısayollar onun üstünde.
abstract interface class HomeDoors {
  QuickAddActions get quickAddActions;
  void dictateNote();
  void captureVoiceNote();

  /// Yana çekişle aynı durak sırası (+1 sonraki, -1 önceki).
  void cycleFolder(int direction);
  void selectAllVisible();
  void deleteSelection();
}

/// Kurulu ana ekran; dar↔geniş geçişinde yenisi bindirir (bkz. dispose'u).
HomeDoors? homeDoors;

/// Yeni not oluşturup AÇ — rayın kalemi ve Ctrl+N. Ana ekranda seçili klasör
/// varsa not oraya doğar (hızlı ekle menüsüyle aynı kural); paylaşılan klasör
/// açıksa SAHİBİN koleksiyonuna (F43.2).
Future<void> createAndOpenNote(
  BuildContext context,
  WidgetRef ref,
  GoRouter router, {
  NoteType type = NoteType.text,
}) async {
  final shared = ref.read(selectedSharedFolderProvider);
  if (shared != null) {
    openSection(router, AppSection.notes);
    final role = sharedFolderRefOf(ref, shared)?.role ?? FolderRole.both;
    return createInSharedFolder(context, ref, shared, role);
  }
  final repo = ref.read(notesRepositoryProvider);
  if (repo == null) return;
  final id = await repo.createNote(
    type,
    folderId: ref.read(selectedFolderProvider),
  );
  openSection(router, AppSection.notes);
  await router.pushNote(noteRoutePath(id));
}

/// Açık notun listede [step] kadar ötesindeki notu açar (Alt+↑ / Alt+↓):
/// ana ekranın o an GÖRÜNEN sırasıyla (süzgeç/arama dahil, bkz.
/// [visibleNoteOrder]). Yığın büyümesin diye açık notun YERİNE geçer.
/// ponytail: kilitli notlar atlanır (açmak kimlik doğrulaması ister —
/// karttan açılır).
void openAdjacentNote(GoRouter router, int step) {
  final segments = Uri.parse(currentLocation(router)).pathSegments;
  if (segments.length != 2 || segments.first != 'note') return;
  final order = [
    for (final n in visibleNoteOrder)
      if (!n.locked || n.id == segments[1]) n,
  ];
  final i = order.indexWhere((n) => n.id == segments[1]);
  final j = i + step;
  if (i < 0 || j < 0 || j >= order.length) return;
  router.pushReplacement(noteRoutePath(order[j].id));
}

/// Açık notu (ve üstüne açılmış notları) kapatıp ana ekrana döner (Ctrl+W).
/// `popRoute` sistem geri tuşunun yolu: editörün PopScope'u (kayıt sürerken
/// önce kaydı bitir) atlanmaz; geri çevrilirse döngü durur.
Future<void> closeOpenNote(GoRouter router) async {
  var guard = 0;
  while (isNoteLocation(currentLocation(router)) && guard++ < 8) {
    // Derin bağlantıyla (web adresi) açılan notun altında ana sayfa yok.
    if (!router.canPop()) {
      router.go('/');
      return;
    }
    final before = currentLocation(router);
    await router.routerDelegate.popRoute();
    if (currentLocation(router) == before) return;
  }
}

/// Kısayol kimlikleri — tablo ([kAppShortcuts]) ile bağlama ([AppShortcuts])
/// arasındaki tek anahtar.
enum AppShortcutId {
  newNote,
  search,
  toggleList,
  settings,
  sections,
  home,
  fullscreen,
  escape,
  adjacentNote,
  switchFolder,
  gridColumns,
  selectAll,
  deleteSelected,
  closeNote,
  help,
}

/// **KISAYOLLARIN TEK TABLOSU** (DENEYIM F80.3d, OTURTMA F67.7): hem bağlama
/// ([AppShortcuts]) hem yardım penceresi (Ctrl+/) BURADAN üretilir; tuş
/// yazısı [describeShortcut] ile tuşun kendisinden çıkar — elle liste yok.
/// `elsewhere`: başka yerde bağlı (Esc `app.dart`, tam ekran kabukta,
/// Alt+←/→ [AppShortcuts] içindeki klasör dinleyicisi, Ctrl+tekerlek
/// ızgarada); yardımda yine görünür. `test/shortcut_table_test.dart` eşler.
typedef AppShortcutRow = ({
  AppShortcutId id,
  List<SingleActivator> keys,
  bool elsewhere,
});

final List<AppShortcutRow> kAppShortcuts = [
  _row(AppShortcutId.newNote, [_ctrl(LogicalKeyboardKey.keyN)]),
  _row(AppShortcutId.search, [_ctrl(LogicalKeyboardKey.keyK)]),
  _row(AppShortcutId.toggleList, [_ctrl(LogicalKeyboardKey.backslash)]),
  _row(AppShortcutId.settings, [_ctrl(LogicalKeyboardKey.comma)]),
  _row(AppShortcutId.sections, [
    for (final k in _digitKeys) SingleActivator(k, alt: true),
  ]),
  _row(AppShortcutId.home, [
    const SingleActivator(LogicalKeyboardKey.home, alt: true),
  ]),
  _row(AppShortcutId.fullscreen, [
    const SingleActivator(LogicalKeyboardKey.keyF, control: true, shift: true),
  ], elsewhere: true),
  _row(AppShortcutId.escape, [
    const SingleActivator(LogicalKeyboardKey.escape),
  ], elsewhere: true),
  _row(AppShortcutId.adjacentNote, [
    const SingleActivator(LogicalKeyboardKey.arrowUp, alt: true),
    const SingleActivator(LogicalKeyboardKey.arrowDown, alt: true),
  ]),
  _row(AppShortcutId.switchFolder, [
    const SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true),
    const SingleActivator(LogicalKeyboardKey.arrowRight, alt: true),
  ], elsewhere: true),
  // Ctrl + fare tekerleği: tuş değil, yazısı yardımda dile göre.
  _row(AppShortcutId.gridColumns, const [], elsewhere: true),
  _row(AppShortcutId.selectAll, [_ctrl(LogicalKeyboardKey.keyA)]),
  _row(AppShortcutId.deleteSelected, [
    const SingleActivator(LogicalKeyboardKey.delete),
  ]),
  // Web'de Ctrl+W tarayıcı sekmesini kapatır; sayfaya hiç ulaşmaz.
  if (!kIsWeb) _row(AppShortcutId.closeNote, [_ctrl(LogicalKeyboardKey.keyW)]),
  _row(AppShortcutId.help, [_ctrl(LogicalKeyboardKey.slash)]),
];

AppShortcutRow _row(
  AppShortcutId id,
  List<SingleActivator> keys, {
  bool elsewhere = false,
}) => (id: id, keys: keys, elsewhere: elsewhere);

SingleActivator _ctrl(LogicalKeyboardKey key) =>
    SingleActivator(key, control: true);

/// Tuş birleşiminin yardımda okunan yazısı: "Ctrl + N", "Alt + ↑ / ↓",
/// "Alt + 1…8". Değiştiriciler ilk tuştan alınır (satırdakiler ortak).
String describeShortcut(List<SingleActivator> keys) {
  if (keys.isEmpty) return '';
  final first = keys.first;
  final mods = [
    if (first.control) 'Ctrl',
    if (first.alt) 'Alt',
    if (first.shift) 'Shift',
    if (first.meta) 'Meta',
  ];
  String name(LogicalKeyboardKey k) => switch (k) {
    LogicalKeyboardKey.arrowUp => '↑',
    LogicalKeyboardKey.arrowDown => '↓',
    LogicalKeyboardKey.arrowLeft => '←',
    LogicalKeyboardKey.arrowRight => '→',
    LogicalKeyboardKey.escape => 'Esc',
    LogicalKeyboardKey.home => 'Home',
    LogicalKeyboardKey.delete => 'Delete',
    _ => k.keyLabel.toUpperCase(),
  };
  final names = [for (final k in keys) name(k.trigger)];
  final tail = names.length > 2
      ? '${names.first}…${names.last}'
      : names.join(' / ');
  return [...mods, tail].join(' + ');
}

String _shortcutLabel(BuildContext context, AppShortcutId id) {
  final l10n = context.l10n;
  return switch (id) {
    AppShortcutId.newNote => l10n.newNoteShort,
    AppShortcutId.search => l10n.shortcutSearch,
    AppShortcutId.toggleList => l10n.shortcutToggleList,
    AppShortcutId.settings => l10n.settings,
    AppShortcutId.sections => l10n.shortcutSections,
    AppShortcutId.home => l10n.goHome,
    AppShortcutId.fullscreen => l10n.shortcutFullscreen,
    AppShortcutId.escape => l10n.shortcutEscape,
    AppShortcutId.adjacentNote => l10n.shortcutAdjacentNote,
    AppShortcutId.switchFolder => l10n.shortcutSwitchFolder,
    AppShortcutId.gridColumns => l10n.shortcutGridColumns,
    AppShortcutId.selectAll => l10n.shortcutSelectAll,
    AppShortcutId.deleteSelected => l10n.shortcutDeleteSelected,
    AppShortcutId.closeNote => l10n.shortcutCloseNote,
    AppShortcutId.help => l10n.shortcutHelp,
  };
}

/// Yardım penceresinin satırları — [kAppShortcuts]'tan üretilir.
List<({String keys, String label})> shortcutHelpRows(BuildContext context) => [
  for (final row in kAppShortcuts)
    (
      keys: row.id == AppShortcutId.gridColumns
          ? 'Ctrl + ${context.l10n.shortcutMouseWheel}'
          : describeShortcut(row.keys),
      label: _shortcutLabel(context, row.id),
    ),
];

Future<void> showShortcutsHelp(BuildContext context) => showDialog<void>(
  context: context,
  builder: (dialogContext) {
    final theme = Theme.of(dialogContext);
    final scheme = theme.colorScheme;
    return AlertDialog(
      icon: const Icon(Icons.keyboard_outlined),
      title: Text(dialogContext.l10n.keyboardShortcuts),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        // Liste uzadı (F44.5): kısa pencerede kaydırılır, taşmaz.
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final row in shortcutHelpRows(dialogContext))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(child: Text(row.label)),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: scheme.outlineVariant),
                        ),
                        child: Text(
                          row.keys,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(dialogContext.l10n.close),
        ),
      ],
    );
  },
);

/// Uygulama geneli klavye kısayolları. Odağın içinde olduğu her ekranda
/// çalışır; metin alanına yazarken de (Ctrl birleşimleri yazıyla çakışmaz).
class AppShortcuts extends ConsumerWidget {
  const AppShortcuts({
    super.key,
    required this.child,
    required this.onToggleList,
  });

  final Widget child;

  /// Liste panelini gizle/göster — yalnız ana-detay düzeninde anlamlı; çerçeve
  /// verir.
  final VoidCallback onToggleList;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = GoRouter.of(context);
    // Seçim yokken bağlanmaz: metin alanının kısayolları kökte, Ctrl+A ve
    // Delete burada yutulursa yazarken çalışmaz.
    final selecting = ref.watch(
      selectedNoteIdsProvider.select((ids) => ids.isNotEmpty),
    );
    final actions = <AppShortcutId, VoidCallback>{
      if (selecting) ...{
        AppShortcutId.selectAll: () => homeDoors?.selectAllVisible(),
        AppShortcutId.deleteSelected: () => homeDoors?.deleteSelection(),
      },
      AppShortcutId.newNote: () => createAndOpenNote(context, ref, router),
      AppShortcutId.search: () {
        openSection(router, AppSection.notes);
        ref.read(searchFocusRequestProvider.notifier).request();
      },
      AppShortcutId.settings: () => openSection(router, AppSection.settings),
      AppShortcutId.toggleList: onToggleList,
      AppShortcutId.help: () => showShortcutsHelp(context),
      AppShortcutId.closeNote: () => closeOpenNote(router),
      AppShortcutId.home: () => goHome(ref, router),
    };
    return CallbackShortcuts(
      // Tablodan üretilir (F80.3d): yardımda görünen her tuş burada bağlı.
      bindings: {
        for (final row in kAppShortcuts)
          if (!row.elsewhere)
            for (final (i, key) in row.keys.indexed)
              key: ?_actionFor(row.id, i, actions, router),
      },
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: (_, event) => _folderKey(event, router, context),
        child: child,
      ),
    );
  }

  /// Tablodaki satırın [index]'inci tuşunun işi; seçim yokken Ctrl+A/Delete
  /// bağlanmaz (metin alanının kendi kısayolu çalışsın).
  static VoidCallback? _actionFor(
    AppShortcutId id,
    int index,
    Map<AppShortcutId, VoidCallback> actions,
    GoRouter router,
  ) => switch (id) {
    AppShortcutId.sections => () =>
        openSection(router, AppSection.values[index]),
    AppShortcutId.adjacentNote => () =>
        openAdjacentNote(router, index == 0 ? -1 : 1),
    _ => actions[id],
  };

  /// Alt+←/→ klasör geçişi (F44.5). Yazarken GEÇMEZ (Option+ok macOS'ta kelime
  /// atlar), liste görünmüyorsa olay tarayıcıya kalır (Alt+← geri).
  KeyEventResult _folderKey(
    KeyEvent event,
    GoRouter router,
    BuildContext context,
  ) {
    if (event is! KeyDownEvent || !HardwareKeyboard.instance.isAltPressed) {
      return KeyEventResult.ignored;
    }
    final step = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowLeft => -1,
      LogicalKeyboardKey.arrowRight => 1,
      _ => 0,
    };
    final location = currentLocation(router);
    final listVisible =
        location == '/' ||
        (isNoteLocation(location) &&
            splitActiveFor(MediaQuery.sizeOf(context)));
    final doors = homeDoors;
    final typing =
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<EditableText>() !=
        null;
    if (step == 0 || !listVisible || doors == null || typing) {
      return KeyEventResult.ignored;
    }
    doors.cycleFolder(step);
    return KeyEventResult.handled;
  }
}

const _digitKeys = [
  LogicalKeyboardKey.digit1,
  LogicalKeyboardKey.digit2,
  LogicalKeyboardKey.digit3,
  LogicalKeyboardKey.digit4,
  LogicalKeyboardKey.digit5,
  LogicalKeyboardKey.digit6,
  LogicalKeyboardKey.digit7,
  LogicalKeyboardKey.digit8,
];
