import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/l10n_ext.dart';
import '../features/notes/data/notes_repository.dart';
import '../features/notes/domain/note_type.dart';
import '../features/notes/presentation/notes_providers.dart';
import 'router.dart';

/// **UYGULAMA KOMUTLARI** — gezinme rayı, klavye kısayolları ve boş sağ
/// panel aynı işleri (yeni not, arama, bölüm değiştirme) yapıyor; üç yerde
/// üç ayrı kopya olmasın diye burada toplandı.
///
/// Kullanıcı isteği 2026-09-22: "tablet gibi geniş ekranlı cihazlarda
/// kullanımını baştan tasarlamalıyız, onlara özel özellikler getirmeliyiz."
/// Fareli/klavyeli tablet, web ve Windows'ta kısayollar bu dosyadan gelir.

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
  inbox('/inbox', Icons.move_to_inbox_outlined, Icons.move_to_inbox),
  ai('/ai', Icons.auto_awesome_outlined, Icons.auto_awesome),
  reminders('/reminders', Icons.alarm_outlined, Icons.alarm),
  archive('/archive', Icons.archive_outlined, Icons.archive),
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
      AppSection.inbox => l10n.inboxTitle,
      AppSection.ai => l10n.aiHubTitle,
      AppSection.reminders => l10n.remindersTitle,
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

/// Yeni not oluşturup AÇ — rayın "+" düğmesi, Ctrl+N ve boş sağ panelin
/// düğmeleri. Ana ekranda seçili klasör varsa not oraya doğar (hızlı ekle
/// menüsüyle aynı kural).
Future<void> createAndOpenNote(
  WidgetRef ref,
  GoRouter router, {
  NoteType type = NoteType.text,
}) async {
  final repo = ref.read(notesRepositoryProvider);
  if (repo == null) return;
  final id = await repo.createNote(
    type,
    folderId: ref.read(selectedFolderProvider),
  );
  openSection(router, AppSection.notes);
  await router.pushNote(noteRoutePath(id));
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
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): () =>
            createAndOpenNote(ref, router),
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
        for (final (i, section) in AppSection.values.indexed)
          SingleActivator(_digitKeys[i], alt: true): () =>
              openSection(router, section),
      },
      child: child,
    );
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
