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
    if (location.startsWith('/reminders')) return AppSection.calendar;
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

/// Kısayolların tek listesi — hem bağlama hem de yardım penceresi buradan
/// okur; biri değişip öbürü eski kalmasın.
List<({String keys, String label})> shortcutHelpRows(BuildContext context) {
  final l10n = context.l10n;
  return [
    (keys: 'Ctrl + N', label: l10n.newNoteShort),
    (keys: 'Ctrl + K', label: l10n.shortcutSearch),
    (keys: 'Ctrl + \\', label: l10n.shortcutToggleList),
    (keys: 'Ctrl + ,', label: l10n.settings),
    (keys: 'Alt + 1…8', label: l10n.shortcutSections),
    (keys: 'Alt + Home', label: l10n.goHome),
    (keys: 'Ctrl + Shift + F', label: l10n.shortcutFullscreen),
    (keys: 'Esc', label: l10n.shortcutEscape),
    (keys: 'Alt + ↑ / ↓', label: l10n.shortcutAdjacentNote),
    (keys: 'Alt + ← / →', label: l10n.shortcutSwitchFolder),
    (keys: 'Ctrl + ${l10n.shortcutMouseWheel}', label: l10n.shortcutGridColumns),
    (keys: 'Ctrl + A', label: l10n.shortcutSelectAll),
    (keys: 'Delete', label: l10n.shortcutDeleteSelected),
    // Web'de Ctrl+W tarayıcı sekmesini kapatır; sayfaya hiç ulaşmaz.
    if (!kIsWeb) (keys: 'Ctrl + W', label: l10n.shortcutCloseNote),
    (keys: 'Ctrl + /', label: l10n.shortcutHelp),
  ];
}

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
    return CallbackShortcuts(
      bindings: {
        if (selecting) ...{
          const SingleActivator(LogicalKeyboardKey.keyA, control: true): () =>
              homeDoors?.selectAllVisible(),
          const SingleActivator(LogicalKeyboardKey.delete): () =>
              homeDoors?.deleteSelection(),
        },
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): () =>
            createAndOpenNote(context, ref, router),
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): () {
          openSection(router, AppSection.notes);
          ref.read(searchFocusRequestProvider.notifier).request();
        },
        const SingleActivator(LogicalKeyboardKey.comma, control: true): () =>
            openSection(router, AppSection.settings),
        const SingleActivator(LogicalKeyboardKey.backslash, control: true):
            onToggleList,
        const SingleActivator(LogicalKeyboardKey.slash, control: true): () =>
            showShortcutsHelp(context),
        const SingleActivator(LogicalKeyboardKey.arrowUp, alt: true): () =>
            openAdjacentNote(router, -1),
        const SingleActivator(LogicalKeyboardKey.arrowDown, alt: true): () =>
            openAdjacentNote(router, 1),
        const SingleActivator(LogicalKeyboardKey.keyW, control: true): () =>
            closeOpenNote(router),
        const SingleActivator(LogicalKeyboardKey.home, alt: true): () =>
            goHome(ref, router),
        for (final (i, section) in AppSection.values.indexed)
          SingleActivator(_digitKeys[i], alt: true): () =>
              openSection(router, section),
      },
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: (_, event) => _folderKey(event, router, context),
        child: child,
      ),
    );
  }

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
            splitActiveFor(MediaQuery.sizeOf(context).width));
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
