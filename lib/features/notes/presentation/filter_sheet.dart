import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../folders/data/folders_repository.dart';
import '../../folders/domain/note_folder.dart';
import '../../folders/presentation/folder_sheets.dart';
import 'notes_providers.dart';

/// Süz levhası — eski çip barının yerini alır.
///
/// ESKİDEN: ekranın üstünde dokuz artı çip yan yana dururdu (süzgeç türleri +
/// klasörler + etiketler); hangisinin açık olduğu ancak renkten anlaşılıyor,
/// listeyi görmek için ayrıca kaydırmak gerekiyordu. Ayrıca "hangi çip
/// görünsün" diye ikinci bir ayar katmanı vardı — süzmek için önce süzgeci
/// göstermek gerekiyordu.
///
/// ŞİMDİ: tek "Süz" düğmesi, tek levha, dört bölüm. Ana ekranda yalnız
/// UYGULANMIŞ süzgeçler kaldırılabilir çip olarak görünür.
Future<void> showFilterSheet(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  ),
  constraints: BoxConstraints(
    maxHeight: MediaQuery.sizeOf(context).height * 0.76,
  ),
  builder: (_) => const _FilterSheet(),
);

/// Ana ekranda bir süzgeç uygulanmış mı? "Süz" düğmesinin vurgusu ve
/// levhadaki "Sıfırla" bunun üstünden karar verir.
int appliedFilterCount(WidgetRef ref) {
  var count = 0;
  if (ref.watch(noteFilterProvider) != NoteFilter.all) count++;
  if (ref.watch(selectedFolderProvider) != null) count++;
  if (ref.watch(selectedTagProvider) != null) count++;
  // Sıralama sayıya KATILMAZ: her zaman bir sıralama seçilidir, "süzgeç
  // uygulandı" balonunda göstermek yanıltıcı olurdu.
  return count;
}

void resetFilters(WidgetRef ref) {
  ref.read(noteFilterProvider.notifier).set(NoteFilter.all);
  ref.read(selectedFolderProvider.notifier).set(null);
  ref.read(selectedTagProvider.notifier).set(null);
}

/// Ana ekrandaki süzgeç satırı: "Süz" düğmesi + YALNIZ uygulanmış süzgeçler.
///
/// Eski çip barı tüm seçenekleri sürekli gösteriyordu; burada ekranda yer
/// kaplayan tek şey kullanıcının gerçekten açtığı süzgeç.
class DashboardFilterRow extends ConsumerWidget {
  const DashboardFilterRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final count = appliedFilterCount(ref);
    final filter = ref.watch(noteFilterProvider);
    final folderId = ref.watch(selectedFolderProvider);
    final tag = ref.watch(selectedTagProvider);
    final folderName = folderId == null
        ? null
        : (ref.watch(foldersStreamProvider).value ?? const <NoteFolder>[])
              .where((f) => f.id == folderId)
              .map((f) => f.name)
              .firstOrNull;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Row(
        children: [
          Material(
            color: count > 0 ? scheme.secondaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => showFilterSheet(context),
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: count > 0
                        ? Colors.transparent
                        : scheme.outlineVariant,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.tune, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      l10n.filterSheetTitle,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (count > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: scheme.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // ÖNCE uygulanmış süzgeçler (kaldırılabilir), SONRA favori
                  // kısayolları. Sıra bilinçli: ekranda ne olduğunu anlatan
                  // çip, henüz basılmamış kısayoldan önce gelir.
                  if (filter != NoteFilter.all)
                    _AppliedChip(
                      label: filterLabel(l10n, filter),
                      onRemove: () => ref
                          .read(noteFilterProvider.notifier)
                          .set(NoteFilter.all),
                    ),
                  if (folderName != null)
                    _AppliedChip(
                      label: folderName,
                      onRemove: () =>
                          ref.read(selectedFolderProvider.notifier).set(null),
                    ),
                  if (tag != null)
                    _AppliedChip(
                      label: tag,
                      onRemove: () =>
                          ref.read(selectedTagProvider.notifier).set(null),
                    ),
                  ...favoriteFilterChips(context, ref),
                ],
              ),
            ),
          ),
          // Izgara ⇄ liste. İkon HEDEFİ gösterir (ızgaradayken "liste"
          // simgesi): düğmeler bulunulan hâli değil basınca olacağı anlatır.
          Tooltip(
            message: l10n.viewToggle,
            child: SizedBox(
              width: 36,
              height: 36,
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => ref.read(noteListViewProvider.notifier).toggle(),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: Icon(
                      ref.watch(noteListViewProvider)
                          ? Icons.grid_view
                          : Icons.view_agenda_outlined,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Süz" düğmesinin sağındaki kısayol çipleri.
///
/// Süz levhasında yıldızlanan seçenekler burada tek dokunuşluk çip olur:
/// dokunmak süzgeci uygular. ZATEN UYGULANMIŞ olan çizilmez — solundaki
/// kaldırılabilir çip onu zaten gösteriyor, ikisi yan yana aynı etiketi iki
/// kez yazardı.
///
/// **Kullanıcının KENDİ ETİKETLERİ varsayılan olarak burada** (istek
/// 2026-08-08: "Süz'ün yanında benim eklediklerim varsayılan ekli olsun").
/// Eskiden etiketin çip olarak görünmesi için önce Süz levhasından
/// yıldızlanması gerekiyordu; oysa etiketler zaten kullanıcının kendi
/// eklediği şeyler — ayrıca "favorile" adımı istemek gereksiz bir kapıydı.
/// Yıldızlananlar önce gelir (kullanıcı sırayı böyle seçmiş), kalan etiketler
/// arkadan; yinelenen çizilmez.
List<Widget> favoriteFilterChips(BuildContext context, WidgetRef ref) {
  final favorites = ref.watch(favoriteFiltersProvider);
  final l10n = context.l10n;
  final filter = ref.watch(noteFilterProvider);
  final folderId = ref.watch(selectedFolderProvider);
  final tag = ref.watch(selectedTagProvider);
  final sort = ref.watch(noteSortProvider);
  final revealHidden = ref.watch(hiddenFoldersRevealedProvider);
  final folders = [
    for (final f
        in ref.watch(foldersStreamProvider).value ?? const <NoteFolder>[])
      if (!f.hidden || revealHidden) f,
  ];
  final tags = ref.watch(allTagsProvider);

  final chips = <Widget>[];
  for (final token in favorites) {
    final parts = token.split(':');
    if (parts.length < 2) continue;
    final value = parts.sublist(1).join(':');
    switch (parts.first) {
      case 'filter':
        final f = NoteFilter.values.where((v) => v.name == value).firstOrNull;
        if (f == null || f == NoteFilter.all || filter == f) continue;
        chips.add(
          _FavoriteChip(
            label: filterLabel(l10n, f),
            onTap: () => ref.read(noteFilterProvider.notifier).set(f),
          ),
        );
      case 'folder':
        // Silinmiş (ya da gizlenmiş) klasörün jetonu ÇÖZÜLEMEZ ve çizilmez;
        // ayrı bir temizlik gerekmez.
        final folder = folders.where((f) => f.id == value).firstOrNull;
        if (folder == null || folderId == folder.id) continue;
        chips.add(
          _FavoriteChip(
            label: folder.name,
            icon: Icons.folder_outlined,
            onTap: () =>
                ref.read(selectedFolderProvider.notifier).set(folder.id),
          ),
        );
      case 'tag':
        if (!tags.contains(value) || tag == value) continue;
        chips.add(
          _FavoriteChip(
            label: '#$value',
            onTap: () => ref.read(selectedTagProvider.notifier).set(value),
          ),
        );
      case 'sort':
        final s = NoteSort.values.where((v) => v.name == value).firstOrNull;
        if (s == null || sort == s) continue;
        chips.add(
          _FavoriteChip(
            label: sortLabel(l10n, s),
            icon: Icons.swap_vert,
            onTap: () => ref.read(noteSortProvider.notifier).set(s),
          ),
        );
    }
  }

  // Yıldızlanmamış etiketler: kullanıcının kendi eklediği her etiket tek
  // dokunuşla süzgeç olur. Zaten uygulanmış olan ve yukarıda favori olarak
  // çizilmiş olan atlanır.
  final favoriteTags = {
    for (final token in favorites)
      if (token.startsWith('tag:')) token.substring(4),
  };
  for (final name in tags) {
    if (name == tag || favoriteTags.contains(name)) continue;
    chips.add(
      _FavoriteChip(
        label: '#$name',
        onTap: () => ref.read(selectedTagProvider.notifier).set(name),
      ),
    );
  }
  return chips;
}

class _FavoriteChip extends StatelessWidget {
  const _FavoriteChip({required this.label, required this.onTap, this.icon});

  final String label;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 6),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon ?? Icons.star,
                  size: 14,
                  color: scheme.primary,
                ),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppliedChip extends StatelessWidget {
  const _AppliedChip({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 6),
      child: Material(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onRemove,
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.close, size: 16, color: scheme.onPrimaryContainer),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterSheet extends ConsumerWidget {
  const _FilterSheet();

  /// Süzgeç türlerinin simgeleri: salt metin çipleri birbirine karışıyordu,
  /// simge göz gezdirirken tutamak veriyor ("0'dan tasarım" isteği).
  static IconData _filterIcon(NoteFilter f) => switch (f) {
    NoteFilter.all => Icons.apps,
    NoteFilter.text => Icons.notes,
    NoteFilter.checklist => Icons.check_box_outlined,
    NoteFilter.ordered => Icons.format_list_numbered_rounded,
    NoteFilter.pinned => Icons.push_pin_outlined,
    NoteFilter.starred => Icons.star_outline,
    NoteFilter.reminded => Icons.alarm,
    NoteFilter.locked => Icons.lock_outline,
    NoteFilter.others => Icons.category_outlined,
  };

  static IconData _sortIcon(NoteSort s) => switch (s) {
    NoteSort.manual => Icons.pan_tool_alt_outlined,
    NoteSort.updated => Icons.history,
    NoteSort.created => Icons.fiber_new_outlined,
    NoteSort.title => Icons.sort_by_alpha,
    NoteSort.color => Icons.palette_outlined,
    NoteSort.active => Icons.local_fire_department_outlined,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final filter = ref.watch(noteFilterProvider);
    final folderId = ref.watch(selectedFolderProvider);
    final tag = ref.watch(selectedTagProvider);
    final sort = ref.watch(noteSortProvider);
    // Gizli klasörler yalnız o oturumda açıldıysa listelenir — levhada
    // görünen bir klasör adı, gizli notların varlığını ele verirdi.
    final revealHidden = ref.watch(hiddenFoldersRevealedProvider);
    final folders = [
      for (final f
          in ref.watch(foldersStreamProvider).value ?? const <NoteFolder>[])
        if (!f.hidden || revealHidden) f,
    ];
    final tags = ref.watch(allTagsProvider);
    final appliedCount = appliedFilterCount(ref);
    final favorites = ref.watch(favoriteFiltersProvider);
    final favoritesNotifier = ref.read(favoriteFiltersProvider.notifier);

    return SingleChildScrollView(
      // Alt boşluk sistem gezinme çubuğunu (geri/ana sayfa) hesaba katar:
      // useSafeArea levhanın ALTINI korumaz, son bölüm çubuğun arkasında
      // kalıyordu.
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        20 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.filterSheetTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (appliedCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$appliedCount',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: scheme.onPrimary,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (appliedCount > 0)
                TextButton.icon(
                  onPressed: () => resetFilters(ref),
                  icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                  label: Text(l10n.filterReset),
                ),
              // "Bitti": levhayı kapatmanın görünür yolu. Aşağı sürüklemek ya
              // da dışarı dokunmak da kapatır ama levha ekranı doldurduğunda
              // ikisi de akla gelmiyordu.
              FilledButton.tonal(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                child: Text(l10n.close),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _Section(
            icon: Icons.style_outlined,
            title: l10n.filterSectionStatus,
            child: _OptionWrap(
              children: [
                for (final f in NoteFilter.values)
                  _Option(
                    label: filterLabel(l10n, f),
                    icon: _filterIcon(f),
                    selected: filter == f,
                    onTap: () => ref.read(noteFilterProvider.notifier).set(f),
                    // "Tümü" favorilenemez: süzgeci KALDIRAN seçenek, ana
                    // ekranda çip olarak durmasının anlamı yok.
                    favorite: f == NoteFilter.all
                        ? null
                        : favorites.contains(filterFavoriteToken(f)),
                    onToggleFavorite: () =>
                        favoritesNotifier.toggle(filterFavoriteToken(f)),
                  ),
              ],
            ),
          ),

          // Bölüm klasör YOKKEN de görünür: "+ Yeni klasör" ile klasör
          // doğrudan buradan da oluşturulabilir. Seçili klasör çipinde ⋮
          // düğmesi klasör YÖNETİMİNİ (yeniden adlandır / gizle / sil) açar —
          // eski girişi (çip barına uzun basış) bar silinince kaybolmuştu ve
          // klasör yönetimi tamamen erişilmez kalmıştı. Uzun basış da çalışır.
          _Section(
            icon: Icons.folder_outlined,
            title: l10n.filterSectionFolder,
            child: _OptionWrap(
              children: [
                for (final f in folders)
                  _Option(
                    label: f.name,
                    icon: f.iconData,
                    selected: folderId == f.id,
                    // Seçili klasöre tekrar dokunmak seçimi KALDIRIR: levhada
                    // ayrı bir "hepsi" satırı olmadan da geri dönülebilsin.
                    onTap: () => ref
                        .read(selectedFolderProvider.notifier)
                        .set(folderId == f.id ? null : f.id),
                    onLongPress: () => showFolderActionsSheet(context, ref, f),
                    onManage: folderId == f.id
                        ? () => showFolderActionsSheet(context, ref, f)
                        : null,
                    favorite: favorites.contains(folderFavoriteToken(f.id)),
                    onToggleFavorite: () =>
                        favoritesNotifier.toggle(folderFavoriteToken(f.id)),
                  ),
                _Option(
                  label: l10n.newFolder,
                  icon: Icons.add,
                  selected: false,
                  outlined: true,
                  onTap: () async {
                    final id = await showFolderEditorDialog(context, ref);
                    // Yeni klasör hemen süzgeç olarak da seçilir: kullanıcı
                    // "oluştu mu" diye aramasın, boş klasörünü görsün.
                    if (id != null) {
                      ref.read(selectedFolderProvider.notifier).set(id);
                    }
                  },
                ),
              ],
            ),
          ),

          if (tags.isNotEmpty)
            _Section(
              icon: Icons.tag,
              title: l10n.filterSectionTag,
              child: _OptionWrap(
                children: [
                  for (final t in tags)
                    _Option(
                      label: t,
                      icon: Icons.tag,
                      selected: tag == t,
                      onTap: () => ref
                          .read(selectedTagProvider.notifier)
                          .set(tag == t ? null : t),
                      favorite: favorites.contains(tagFavoriteToken(t)),
                      onToggleFavorite: () =>
                          favoritesNotifier.toggle(tagFavoriteToken(t)),
                    ),
                ],
              ),
            ),

          _Section(
            icon: Icons.swap_vert,
            title: l10n.filterSectionSort,
            // Elle sıralama kipi sıralama bölümünün İÇİNDE: sıralamayı arayan
            // kullanıcı zaten burada. Yalnız süzgeçsiz görünümde anlamlı
            // (alt kümede sıra bozulur), o yüzden koşullu.
            trailing: appliedCount == 0
                ? IconButton(
                    tooltip: l10n.reorderNotes,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.open_with, size: 18),
                    onPressed: () {
                      ref.read(noteSortProvider.notifier).set(NoteSort.manual);
                      ref.read(reorderModeProvider.notifier).set(true);
                      Navigator.pop(context);
                    },
                  )
                : null,
            child: _OptionWrap(
              children: [
                for (final s in NoteSort.values)
                  _Option(
                    label: sortLabel(l10n, s),
                    icon: _sortIcon(s),
                    selected: sort == s,
                    onTap: () => ref.read(noteSortProvider.notifier).set(s),
                    favorite: favorites.contains(sortFavoriteToken(s)),
                    onToggleFavorite: () =>
                        favoritesNotifier.toggle(sortFavoriteToken(s)),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 10),
          // Yıldız ipucu: çipin sonundaki yıldızın ne işe yaradığı bir kez
          // yazılı olmalı, yoksa süs sanılıyor. Sıralama ipucuyla birlikte
          // levhanın dibinde, içerikten sonra.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.star, size: 13, color: scheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l10n.filterFavoriteHint,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.filterSheetSortHint,
            style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// Süzgeç türünün yerelleştirilmiş etiketi (eski çip barından taşındı).
String filterLabel(AppLocalizations l10n, NoteFilter filter) => switch (filter) {
  NoteFilter.all => l10n.filterAll,
  NoteFilter.text => l10n.filterText,
  NoteFilter.checklist => l10n.filterChecklist,
  NoteFilter.ordered => l10n.filterOrdered,
  NoteFilter.pinned => l10n.filterPinned,
  NoteFilter.starred => l10n.filterStarred,
  NoteFilter.reminded => l10n.filterReminded,
  NoteFilter.locked => l10n.filterLocked,
  NoteFilter.others => l10n.filterOthers,
};

String sortLabel(AppLocalizations l10n, NoteSort sort) => switch (sort) {
  NoteSort.manual => l10n.sortManual,
  NoteSort.updated => l10n.sortUpdated,
  NoteSort.created => l10n.sortCreated,
  NoteSort.title => l10n.sortTitle,
  NoteSort.color => l10n.sortColor,
  NoteSort.active => l10n.sortActive,
};

/// Bölüm kartı: simgeli başlık + içerik, yumuşak zeminli tek blok.
///
/// Eski levha bölümleri yalnız minik BÜYÜK HARF etiketlerle ayırıyordu;
/// kenarlıklı çipler ekranı çizgi kalabalığına çeviriyordu. Kart zemini
/// bölümü tek bakışta gruplarken çiplerin kenarlıksız (tonal) kalmasına
/// izin veriyor — uygulamanın not kartlarıyla aynı dil.
class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: scheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _OptionWrap extends StatelessWidget {
  const _OptionWrap({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) =>
      Wrap(spacing: 8, runSpacing: 8, children: children);
}

class _Option extends StatelessWidget {
  const _Option({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.favorite,
    this.onToggleFavorite,
    this.onLongPress,
    this.onManage,
    this.outlined = false,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  /// Dolu ise seçili çipte ⋮ görünür (klasör yönetimi girişi).
  final VoidCallback? onManage;

  /// "+ Yeni klasör" gibi eylem çipleri: dolgusuz, kesikli görünüm yerine
  /// ince kenarlık.
  final bool outlined;

  /// null = bu seçenek favorilenemez. Dolu ise çipin sonunda yıldız çıkar.
  final bool? favorite;
  final VoidCallback? onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final star = favorite;
    // Seçili çip dolgun (primary), seçilmemiş tonal — kenarlık çizgisi yok:
    // eski tasarımda her çipin kenarlığı levhayı tel kafese çeviriyordu.
    final background = selected
        ? scheme.primary
        : outlined
        ? Colors.transparent
        : scheme.surfaceContainerHigh;
    final foreground = selected ? scheme.onPrimary : scheme.onSurface;
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          height: 38,
          padding: EdgeInsetsDirectional.only(
            start: 12,
            end: (star == null && onManage == null) ? 12 : 4,
          ),
          decoration: outlined
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: scheme.outlineVariant),
                )
              : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: selected ? scheme.onPrimary : scheme.primary,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: foreground,
                ),
              ),
              // Yıldız çipin İÇİNDE ayrı bir dokunma hedefi: etikete dokunmak
              // süzgeci uygular, yıldıza dokunmak favorilere ekler/çıkarır.
              if (star != null)
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: onToggleFavorite,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      star ? Icons.star : Icons.star_border,
                      size: 15,
                      color: selected
                          ? scheme.onPrimary
                          : star
                          ? scheme.primary
                          : scheme.onSurfaceVariant.withValues(alpha: 0.45),
                    ),
                  ),
                ),
              if (onManage != null)
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: onManage,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.more_vert,
                      size: 16,
                      color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
