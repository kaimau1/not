import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../notes/data/shared_note_activity.dart';
import '../../notes/presentation/shared_notes_screen.dart';
import '../data/inbox_repository.dart';
import 'inbox_screen.dart';

/// Birleşik ekranın sekmeleri.
enum SharedHubTab { inbox, shared }

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
/// Eskiden iki ayrı kapı vardı: ⋮ menüsünde "Gelen notlar" (gönderilen
/// kopyalar — kabul/ret) ve klasör şeridinin SONUNDA "Benimle
/// paylaşılanlar" çipi (ortak, canlı notlar). İkisi de "bana gelen not"
/// ama yerleri ayrı olduğu için biri hep gözden kaçıyordu. Artık ana ekranın
/// üst çubuğunda tek düğme (rozetli) ve tek ekranda iki sekme.
class SharedHubScreen extends ConsumerWidget {
  const SharedHubScreen({super.key, this.initialTab});

  /// null → bekleyen gelen not varsa Gelen, yoksa yeni ortak not varsa
  /// Paylaşılanlar, ikisi de yoksa Gelen.
  final SharedHubTab? initialTab;

  static Future<void> open(BuildContext context, {SharedHubTab? tab}) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SharedHubScreen(initialTab: tab),
        ),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final inboxCount = ref.watch(
      inboxNotesProvider.select((s) => s.value?.length ?? 0),
    );
    final unread = ref.watch(sharedNoteUnreadProvider.select((s) => s.length));
    final start =
        initialTab ??
        (inboxCount == 0 && unread > 0
            ? SharedHubTab.shared
            : SharedHubTab.inbox);
    return DefaultTabController(
      length: 2,
      initialIndex: start.index,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.sharedHubTitle),
          actions: const [SharedMarkAllReadButton()],
          bottom: TabBar(
            tabs: [
              Tab(
                key: const ValueKey('hub-tab-inbox'),
                child: _TabLabel(label: l10n.sharedHubInbox, count: inboxCount),
              ),
              Tab(
                key: const ValueKey('hub-tab-shared'),
                child: _TabLabel(label: l10n.sharedWithMe, count: unread),
              ),
            ],
          ),
        ),
        body: const TabBarView(children: [InboxList(), SharedNotesBody()]),
      ),
    );
  }
}

class _TabLabel extends StatelessWidget {
  const _TabLabel({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        if (count > 0) ...[
          const SizedBox(width: 6),
          HubCountBadge(count: count, color: scheme.error),
        ],
      ],
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
          fontSize: 10.5,
          height: 1.2,
          fontWeight: FontWeight.w700,
          color: scheme.onError,
        ),
      ),
    );
  }
}

/// Ana ekranın üst çubuğundaki "Gelen ve paylaşılanlar" düğmesi; köşesinde
/// bekleyen/yeni not sayısı.
class SharedHubButton extends ConsumerWidget {
  const SharedHubButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final count = ref.watch(sharedHubBadgeProvider);
    return Tooltip(
      message: context.l10n.sharedHubTitle,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Material(
                color: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  key: const ValueKey('home-shared-hub'),
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => SharedHubScreen.open(context),
                  child: Icon(
                    count > 0
                        ? Icons.mark_email_unread_outlined
                        : Icons.move_to_inbox_outlined,
                    size: 22,
                    color: count > 0 ? scheme.primary : scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            if (count > 0)
              PositionedDirectional(
                top: -5,
                end: -5,
                child: IgnorePointer(
                  child: HubCountBadge(count: count, color: scheme.error),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
