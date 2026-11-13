import '../../../app/app_frame.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/app_icons.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';

import '../../../core/l10n_ext.dart';
import '../../notes/data/note_shares_repository.dart';
import '../../notes/data/shared_note_activity.dart';
import '../../../core/widgets/empty_state.dart';
import '../../notes/presentation/note_grid.dart';
import '../../notes/presentation/notes_providers.dart';
import '../../notes/presentation/shared_notes_screen.dart';
import '../data/inbox_repository.dart';
import 'inbox_screen.dart';

/// Ana ekrandaki düğmenin rozeti: kabul bekleyen GELEN notlar + okunmamış
/// (yeni gelen ya da başkasının güncellediği) ORTAK notlar.
final sharedHubBadgeProvider = Provider<int>((ref) {
  final inbox = ref.watch(
    inboxNotesProvider.select((s) => s.value?.length ?? 0),
  );
  final unread = ref.watch(sharedNoteUnreadProvider.select((s) => s.length));
  return inbox + unread;
});

/// **GELEN VE PAYLAŞILANLAR** (kullanıcı isteği 2026-10-17: "gelen ve
/// paylaşılan notları birleştir, tek alandan yönetilsin; bir not geldiğinde
/// üst köşesinde bildirim gibi görülsün").
///
/// TEK LİSTE (kullanıcı isteği 2026-10-31: "Gelen ve benimle paylaşılanlar
/// aynı sekmede görülsün, ayrı ayrı olmasın, sadece kendi etiketleri olsun"):
/// eskiden iki sekme vardı (Gelen · Benimle paylaşılanlar) ve biri hep
/// gözden kaçıyordu. Artık önce kabul bekleyen GELEN kopyalar, ardından
/// ORTAK notlar aynı kaydırmada; her öğenin başında kaynağını söyleyen küçük
/// etiket ([HubSourceTag]: "Gelen" / "Paylaşılan").
class SharedHubScreen extends ConsumerWidget {
  const SharedHubScreen({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => const SharedHubScreen()));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: HomeInBar(appBar: AppBar(
        title: Text(l10n.sharedHubTitle),
        actions: const [SharedMarkAllReadButton()],
      )),
      body: const SharedHubBody(),
    );
  }
}

/// Birleşik listenin gövdesi: gelen kopyalar (liste) + ortak notlar
/// (dengeli ızgara) tek [CustomScrollView]da.
class SharedHubBody extends ConsumerWidget {
  const SharedHubBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inbox = ref.watch(inboxNotesProvider).value ?? const <InboxNote>[];
    final entries = sharedNoteEntries(ref);
    if (inbox.isEmpty && entries.isEmpty) {
      return sharedHubPlaceholder(context, ref);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        const pad = 12.0;
        final columns = (constraints.maxWidth / 220).floor().clamp(2, 6);
        final cellWidth =
            (constraints.maxWidth - pad * 2 - kGridGap * (columns - 1)) / columns;
        return CustomScrollView(
          slivers: [
            ...sharedHubSlivers(
              context,
              ref,
              columns: columns,
              cellWidth: cellWidth,
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        );
      },
    );
  }
}

/// Birleşik liste BOŞKEN ne çizileceği — ayrı ekran ([SharedHubBody]) ve
/// ana ekranın "Gelen" süzgeci aynısını kullanır: yüklenirken iskelet, okuma
/// hatasında (çoğu kez bağlantı yok) hata görünümü + "Tekrar dene", ancak
/// gerçekten boşsa "burada not yok".
///
/// F79.6 (3): ana ekrandaki "Gelen" süzgeci hatada da "burada not yok"
/// diyordu — Gelen dolu olabilir, bu yalandı.
///
/// [skeleton] false: yüklenirken boş alan (ana ekranda dilim
/// `SliverFillRemaining(hasScrollBody: false)` içinde; iskeletin
/// `LayoutBuilder`ı iç boy ölçümünü desteklemez).
Widget sharedHubPlaceholder(
  BuildContext context,
  WidgetRef ref, {
  bool skeleton = true,
}) {
  final l10n = context.l10n;
  final inboxAsync = ref.watch(inboxNotesProvider);
  final sharesAsync = ref.watch(sharedNotesWithMeProvider);
  // Hata ÖNCE: Riverpod 3 akış hatasında kendiliğinden yeniden dener ve o
  // sırada durum "yükleniyor + hata" olur — yükleniyor önce bakılırsa hata
  // hiç görünmez, iskelet sonsuza dek döner.
  final error = inboxAsync.hasError
      ? inboxAsync.error!
      : (sharesAsync.hasError ? sharesAsync.error! : null);
  if (error == null && inboxAsync.isLoading && !inboxAsync.hasValue) {
    return skeleton ? const NoteListSkeleton() : const SizedBox.shrink();
  }
  if (error != null) {
    return ErrorState(
      error: error,
      onRetry: () {
        ref.invalidate(inboxNotesProvider);
        ref.invalidate(sharedNotesWithMeProvider);
      },
    );
  }
  return EmptyState(
    icon: AppIcons.inbox,
    title: l10n.sharedHubEmpty,
    subtitle: l10n.sharedHubEmptyHint,
  );
}

/// Birleşik listenin SLIVER'ları — ayrı ekran ([SharedHubBody]) ve ana
/// ekranın "Gelen" süzgeci (bkz. `sharedHubOnHomeProvider`) aynı içeriği
/// çizer. İkisi de boşsa boş liste döner; boş durumu çağıran seçer.
List<Widget> sharedHubSlivers(
  BuildContext context,
  WidgetRef ref, {
  required int columns,
  required double cellWidth,
  double pad = 12,
}) {
  final l10n = context.l10n;
  final scheme = Theme.of(context).colorScheme;
  final inbox = ref.watch(inboxNotesProvider).value ?? const <InboxNote>[];
  final entries = sharedNoteEntries(ref);
  final unread = ref.watch(sharedNoteUnreadProvider);
  if (inbox.isEmpty && entries.isEmpty) return const [];
  final inboxTag = HubSourceTag(
    key: const ValueKey('hub-tag-inbox'),
    label: l10n.sharedHubTagInbox,
    icon: AppIcons.inbox,
    color: scheme.tertiary,
  );
  final sharedTag = HubSourceTag(
    key: const ValueKey('hub-tag-shared'),
    label: l10n.sharedHubTagShared,
    icon: AppIcons.shared,
    color: scheme.primary,
  );
  return [
    if (inbox.isNotEmpty)
      SliverPadding(
        padding: EdgeInsets.fromLTRB(pad, pad, pad, 0),
        sliver: SliverList.separated(
          itemCount: inbox.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) =>
              InboxCard(note: inbox[index], tag: inboxTag),
        ),
      ),
    if (entries.isNotEmpty)
      SliverPadding(
        padding: EdgeInsets.fromLTRB(pad, pad, pad, 0),
        sliver: sliverBalancedNoteColumns(
          items: [for (final e in entries) e.note],
          columns: columns,
          cellWidth: cellWidth,
          cell: (context, index) {
            final entry = entries[index];
            return SharedNoteCell(
              entry: entry,
              isNew: unread.contains(entry.share.id),
              tag: sharedTag,
            );
          },
        ),
      ),
  ];
}

/// Ana ekranı "Gelen" süzgecine alır (klasör çipiyle aynı davranış — bkz.
/// `openFolder`): öteki süzgeçler bırakılır, ana ekran
/// dışındaysa ana ekrana dönülür. Zaten açıksa kapatır ("Tümü" gibi).
void showSharedHubOnHome(BuildContext context) {
  final container = ProviderScope.containerOf(context, listen: false);
  if (container.read(sharedHubOnHomeProvider)) {
    container.read(sharedHubOnHomeProvider.notifier).set(false);
    return;
  }
  container.read(noteFilterProvider.notifier).set(NoteFilter.all);
  container.read(selectedTagProvider.notifier).set(null);
  container.read(selectedFolderProvider.notifier).set(null);
  container.read(selectedSharedFolderProvider.notifier).set(null);
  if (container.read(showAllNotesProvider)) {
    container.read(showAllNotesProvider.notifier).set(false);
  }
  container.read(sharedHubOnHomeProvider.notifier).set(true);
  final router = GoRouter.maybeOf(context);
  if (router == null) return;
  Navigator.of(context).popUntil((route) => route.settings is Page);
  if (!isSplitShellLocation(router.state.uri.path)) router.go('/');
}

/// Birleşik listede öğenin kaynağı: küçük renkli hap ("Gelen" /
/// "Paylaşılan"). Renk + simge + yazı — yalnız renge dayanmaz.
class HubSourceTag extends StatelessWidget {
  const HubSourceTag({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              height: 1.2,
              fontWeight: AppWeight.strong,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Kırmızı sayı rozeti (düğmenin köşesinde ve sekmelerde).
class HubCountBadge extends StatelessWidget {
  const HubCountBadge({super.key, required this.count, required this.color});

  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 18),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: scheme.surface, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        count > 99 ? '99+' : '$count',
        style: TextStyle(
          fontSize: 11,
          height: 1.2,
          fontWeight: AppWeight.strong,
          color: scheme.onError,
        ),
      ),
    );
  }
}
