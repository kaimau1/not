import '../../../core/widgets/sheet_header.dart';
import '../../../core/app_icons.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../../ai/data/attachment_text_index.dart';
import '../../settings/settings_providers.dart';
import '../../folders/data/folder_order.dart';
import '../../folders/data/folders_repository.dart';
import '../../folders/domain/note_folder.dart';
import '../data/notes_repository.dart';
import '../domain/note.dart';
import 'notes_providers.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/a11y/min_tap_target.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/widgets/confirm_dialog.dart';

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
Future<void> showFilterSheet(BuildContext context) =>
    showAppSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      // TUTAMAK YOK (2026-11-10, kullanıcı: "üstte ölü boşluk var"): M3
      // tutamağı başlığın üstünde ~48 dp boş şerit açıyordu; levha yine
      // aşağı sürüklenerek ve ✕ ile kapanır.
      showDragHandle: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
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
  if (ref.watch(selectedSharedFolderProvider) != null) count++;
  if (ref.watch(selectedTagProvider) != null) count++;
  // Sıralama sayıya KATILMAZ: her zaman bir sıralama seçilidir, "süzgeç
  // uygulandı" balonunda göstermek yanıltıcı olurdu.
  return count;
}

void resetFilters(WidgetRef ref) {
  ref.read(noteFilterProvider.notifier).set(NoteFilter.all);
  ref.read(selectedFolderProvider.notifier).set(null);
  ref.read(selectedSharedFolderProvider.notifier).set(null);
  ref.read(selectedTagProvider.notifier).set(null);
  ref.read(sharedHubOnHomeProvider.notifier).set(false);
}

/// Uygulanmış süzgeçlerin ekranda okunacak adları (tür, klasör, #etiket).
List<String> appliedFilterLabels(BuildContext context, WidgetRef ref) {
  final l10n = context.l10n;
  final filter = ref.watch(noteFilterProvider);
  final folderId = ref.watch(selectedFolderProvider);
  final tag = ref.watch(selectedTagProvider);
  final shared = ref.watch(selectedSharedFolderProvider);
  // GELEN ADI (kullanıcı bulgusu 2026-11-07: "Gelen klasörü üstte filtre
  // ismi olarak görülmüyor"): Gelen `selectedFolderProvider` değil ayrı
  // bayrak (`sharedHubOnHomeProvider`); başka klasörlerin adı Süz düğmesinde
  // görünürken Gelen'inki görünmüyordu.
  final hubOn = ref.watch(sharedHubOnHomeProvider);
  final hubName = hubOn
      ? ref.watch(sharedHubFolderProvider.select((f) => f.name))
      : null;
  final folderName = hubOn
      ? (hubName == null || hubName.isEmpty ? l10n.sharedHubShort : hubName)
      : shared != null
      ? (ref.watch(sharedFolderRefsProvider).value ??
                const <SharedFolderRef>[])
            .where((s) => s.folderId == shared.folderId)
            .map((s) => s.name)
            .firstOrNull
      : folderId == null
      ? null
      : (ref.watch(foldersStreamProvider).value ?? const <NoteFolder>[])
            .where((f) => f.id == folderId)
            .map((f) => f.name)
            .firstOrNull;
  return [
    if (filter != NoteFilter.all) filterLabel(l10n, filter),
    ?folderName,
    if (tag != null) '#$tag',
  ];
}

/// **SÜZ DÜĞMESİ ARAMA KUTUSUNUN SAĞINDA** (kullanıcı isteği 2026-10-20:
/// "süz yazısı tek satır kaplıyor, kaplamasın; süzgeç seçildiğinde süz
/// yazısının yerine gelsin ve bir renk veya çerçeveyle belli olsun; üstteki
/// arama yerinin sağına gelebilir").
///
/// ESKİDEN: arama çubuğunun altında ayrı bir satır — solda "Süz", yanında
/// uygulanmış süzgeç çipleri, sağda görünüm anahtarı. Süzgeç yokken satır
/// yalnız bir düğme için ekranın bir şeridini yiyordu.
///
/// ŞİMDİ: arama kutusunun İÇİNDE, AI anahtarının sağında. Süzgeç yokken
/// yalnız simge; uygulanınca simgenin yerini süzgecin ADI alır (birden çoksa
/// "Görevler +1"), dolu zemin + vurgu çerçevesiyle. Sondaki × hepsini
/// kaldırır, ada dokunmak levhayı açar.
class HomeFilterButton extends ConsumerWidget {
  const HomeFilterButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final labels = appliedFilterLabels(context, ref);
    final active = labels.isNotEmpty;
    final label = !active
        ? l10n.filterSheetTitle
        : labels.length == 1
        ? labels.first
        : '${labels.first} +${labels.length - 1}';
    // Görünüm 34 dp; dokunma/ekran okuyucu alanı 48 dp (F15.4).
    return MinTapTarget(
      child: Tooltip(
        message: active
            ? '${l10n.filterSheetTitle}: ${labels.join(', ')}'
            : l10n.filterSheetTitle,
        child: Semantics(
          button: true,
          selected: active,
          // excludeSemantics içteki InkWell'in eylemini de siliyordu: ekran
          // okuyucuyla Süz AÇILAMIYORDU.
          onTap: () => showFilterSheet(context),
          label: active
              ? '${l10n.filterSheetTitle}: ${labels.join(', ')}'
              : l10n.filterSheetTitle,
          excludeSemantics: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              alignment: AlignmentDirectional.centerEnd,
              // Boyut geçişi AnimatedSize'ta (kırparak); kutunun kendi
              // kısıtı ANİMASYONSUZ — kısıtı canlandırmak geçiş boyunca
              // içeriği dar kutuya sıkıştırıp taşırıyordu.
              child: Container(
                key: const ValueKey('home-filter-button'),
                height: 34,
                constraints: BoxConstraints(
                  minWidth: 34,
                  maxWidth: active ? 118 : 34,
                ),
                // Pasifken DÜZ simge (kutusuz, 2026-11-06); süzgeç varken
                // vurgulu hap.
                decoration: active
                    ? BoxDecoration(
                        color: scheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: scheme.primary, width: 1.5),
                      )
                    : null,
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(9),
                    onTap: () => showFilterSheet(context),
                    child: !active
                        ? Icon(
                            Icons.tune,
                            size: 18,
                            color: scheme.onSurfaceVariant,
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: AppWeight.strong,
                                    color: scheme.onSecondaryContainer,
                                  ),
                                ),
                              ),
                              // × hepsini kaldırır; ada dokunmak levhayı açar.
                              InkResponse(
                                key: const ValueKey('home-filter-clear'),
                                radius: 16,
                                onTap: () => resetFilters(ref),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 8,
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    size: 15,
                                    color: scheme.onSecondaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Arama çubuğunun altındaki şerit: yalnız arama yazılıyken "ek içeriğinde
/// de ara" çipi.
///
/// YILDIZLI KISAYOLLAR KALKTI (kullanıcı isteği 2026-10-20: "Yıldızlı
/// filtresi satır kaplıyor, oradan çıkar, normal Süz'ün içine koy"): Süz
/// levhasında yıldızlanan seçenekler burada ayrı bir satır açıyordu. Süzgeç
/// artık yalnız Süz levhasından (Durum → Yıldızlı) seçilir; uygulanan süzgeç
/// zaten arama kutusundaki Süz düğmesinde adıyla görünür.
///
/// Süz düğmesi ve uygulanmış süzgeç arama kutusuna taşındı (bkz.
/// [HomeFilterButton]); görünüm anahtarı Süz levhasına. Şeritte çizilecek bir
/// şey yoksa SIFIR yer kaplar.
class DashboardFilterRow extends ConsumerWidget {
  const DashboardFilterRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searching = ref.watch(searchQueryProvider).trim().isNotEmpty;
    final chips = [
      // **EK İÇERİĞİNDE DE ARA** (kullanıcı isteği 2026-09-04:
      // "anlamsal arama görsel ve pdf'leri de arayabilir, seçenek olarak
      // sunmalıyız"). Yalnız ARAMA YAZILIYKEN görünür: aramanın kapsamını
      // değiştiren bir seçenek, arama yokken anlamsız bir çip olurdu.
      if (searching)
        _AttachmentScopeChip(
          selected: ref.watch(attachmentSearchProvider),
          onTap: () => ref
              .read(attachmentSearchProvider.notifier)
              .set(!ref.read(attachmentSearchProvider)),
        ),
    ];
    if (chips.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: SizedBox(
        height: 36,
        child: ListView(scrollDirection: Axis.horizontal, children: chips),
      ),
    );
  }
}

/// Görünüm bölümü (F11.4; SIKI YENİDEN YAZIM 2026-11-10, kullanıcı isteği:
/// "klasör satırı, takvim satırı gizleme gösterme gibi seçenekleri görünüm ve
/// süz ekranına koy, daha kompakt olsun"). Izgara ⇄ liste segmentli düğme;
/// aç-kapa seçenekleri artık 48 dp'lik anahtar SATIRLARI değil, aynı çip
/// akışında işaretli çipler — yedi satır yerine iki-üç sıra.
class _ViewModeSection extends ConsumerWidget {
  const _ViewModeSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final list = ref.watch(noteListViewProvider);
    void set(bool wantList) {
      if (wantList != ref.read(noteListViewProvider)) {
        ref.read(noteListViewProvider.notifier).toggle();
      }
    }

    final shared = ref.watch(homeShowSharedProvider);
    return _Section(
      icon: Icons.grid_view,
      title: l10n.viewToggle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<bool>(
            key: const ValueKey('filter-view-mode'),
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: false,
                icon: const Icon(Icons.grid_view, size: 18),
                label: Text(l10n.viewGrid),
              ),
              ButtonSegment(
                value: true,
                icon: const Icon(Icons.view_agenda_outlined, size: 18),
                label: Text(l10n.viewList),
              ),
            ],
            selected: {list},
            onSelectionChanged: (v) => set(v.first),
          ),
          const SizedBox(height: 8),
          _OptionWrap(
            children: [
              // KLASÖR SATIRI (⋮ menüsünden buraya, 2026-11-10).
              _Option(
                key: const ValueKey('view-toggle-folder-strip'),
                toggle: true,
                label: l10n.homeFolderStripShort,
                icon: Icons.folder_outlined,
                selected: !ref.watch(homeFolderStripHiddenProvider),
                onTap: () =>
                    ref.read(homeFolderStripHiddenProvider.notifier).toggle(),
              ),
              // TAKVİM ŞERİDİ (Zemin levhasında da var; burası kısayol).
              _Option(
                key: const ValueKey('view-toggle-calendar-strip'),
                toggle: true,
                label: l10n.homeCalendarStripShort,
                icon: Icons.calendar_view_week_outlined,
                selected: ref.watch(homeCalendarStripProvider),
                onTap: () => ref
                    .read(homeCalendarStripProvider.notifier)
                    .set(!ref.read(homeCalendarStripProvider)),
              ),
              // KARTTA GÖRSEL / EK (kullanıcı isteği 2026-10-23): Ayarlar'daki
              // "Kartta görünenler"in kısayolu.
              _Option(
                toggle: true,
                label: l10n.cardShowMediaShort,
                icon: Icons.image_outlined,
                selected: ref.watch(cardShowMediaProvider),
                onTap: () => ref.read(cardShowMediaProvider.notifier).toggle(),
              ),
              _Option(
                toggle: true,
                label: l10n.cardShowFilesShort,
                icon: Icons.attach_file,
                selected: ref.watch(cardShowFilesProvider),
                onTap: () => ref.read(cardShowFilesProvider.notifier).toggle(),
              ),
              // "Tümü" açıkken: klasör başlıkları altında grupla (D4).
              if (ref.watch(showAllNotesProvider))
                _Option(
                  toggle: true,
                  label: l10n.groupByFolder,
                  icon: Icons.folder_copy_outlined,
                  selected: ref.watch(allNotesGroupByFolderProvider),
                  onTap: () =>
                      ref.read(allNotesGroupByFolderProvider.notifier).toggle(),
                ),
              _Option(
                toggle: true,
                label: l10n.homeShowSharedShort,
                icon: AppIcons.shared,
                selected: shared,
                onTap: () => ref.read(homeShowSharedProvider.notifier).toggle(),
              ),
              if (shared)
                _Option(
                  toggle: true,
                  label: l10n.homeSharedAtBottomShort,
                  icon: Icons.vertical_align_bottom,
                  selected: ref.watch(homeSharedAtBottomProvider),
                  onTap: () =>
                      ref.read(homeSharedAtBottomProvider.notifier).toggle(),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// TÜR süzgeçleri (notun yapısı) — DURUM'dan ayrı satır (F11.4).
const _typeFilters = [
  NoteFilter.all,
  NoteFilter.text,
  NoteFilter.checklist,
  NoteFilter.ordered,
];

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
    NoteFilter.others => Icons.folder_off_outlined,
  };

  static IconData _sortIcon(NoteSort s) => switch (s) {
    NoteSort.manual => Icons.pan_tool_alt_outlined,
    NoteSort.updated => Icons.history,
    NoteSort.created => Icons.fiber_new_outlined,
    NoteSort.title => Icons.sort_by_alpha,
    NoteSort.color => AppIcons.color,
    NoteSort.active => Icons.local_fire_department_outlined,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final filter = ref.watch(noteFilterProvider);
    final tag = ref.watch(selectedTagProvider);
    final sort = ref.watch(noteSortProvider);
    final tags = ref.watch(allTagsProvider);
    final appliedCount = appliedFilterCount(ref);
    void setFilter(NoteFilter f) => ref.read(noteFilterProvider.notifier).set(f);
    void setTag(String? t) => ref.read(selectedTagProvider.notifier).set(t);
    void reset() => resetFilters(ref);

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
          SheetHeader(
            title: l10n.homeViewMenu,
            padding: const EdgeInsets.only(left: 4, top: 6),
            badge: appliedCount > 0
                ? Container(
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
                        fontWeight: AppWeight.strong,
                        color: scheme.onPrimary,
                      ),
                    ),
                  )
                : null,
            // ✕ levhayı kapatmanın görünür yolu (F16.2: eskiden "Kapat" hapı).
            // Aşağı sürüklemek ya da dışarı dokunmak da kapatır ama levha
            // ekranı doldurduğunda ikisi de akla gelmiyordu.
            actions: [
              if (appliedCount > 0)
                TextButton.icon(
                  onPressed: reset,
                  icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                  label: Text(l10n.filterReset),
                ),
            ],
          ),
          const SizedBox(height: 2),

          const _ViewModeSection(),

          // TÜR ve DURUM AYRI SATIR (F11.4) ama TEK KARTTA (2026-11-10,
          // sıkılaştırma): iki başlık kartı yerine satır başında küçük ad.
          _Section(
            icon: Icons.filter_alt_outlined,
            title: l10n.filterSheetTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _OptionWrap(
                  children: [
                    _RowLabel(l10n.filterSectionType),
                    for (final f in _typeFilters)
                      _Option(
                        label: filterLabel(l10n, f),
                        icon: _filterIcon(f),
                        selected: filter == f,
                        onTap: () => setFilter(f),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                _OptionWrap(
                  children: [
                    _RowLabel(l10n.filterSectionStatus),
                    for (final f in NoteFilter.values)
                      if (!_typeFilters.contains(f))
                        _Option(
                          label: filterLabel(l10n, f),
                          icon: _filterIcon(f),
                          selected: filter == f,
                          onTap: () => setFilter(f),
                        ),
                  ],
                ),
              ],
            ),
          ),

          // **KLASÖR BÖLÜMÜ BURADAN KALKTI** (kullanıcı isteği 2026-08-18:
          // "şu an etiketle klasör aynı şey"). Klasör bir süzgeç olduğu
          // sürece etiketin ikizinden başka bir şey değildi: ikisi de listeyi
          // daraltıyordu. Klasör artık ana ekranda karosu olan bir YER
          // (bkz. `FolderTile` / `FolderScreen`); oluşturma, yönetme ve içine
          // girme oradan yapılır. Etiket saf etiket olarak burada kalır.
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
                      onTap: () => setTag(tag == t ? null : t),
                      // **ETİKET YÖNETİMİ**: etiketler yalnız notlardan
                      // türetiliyordu; yazım hatasıyla açılmış bir etiketi
                      // düzeltmenin tek yolu onu taşıyan HER notu açmaktı.
                      onLongPress: () => _manageTag(context, ref, t),
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
            // ✥ simgesi yerine METİNLİ düğme (F11.4): "Notları sırala"
            // simgesi açıklamasızdı.
            trailing: appliedCount == 0
                ? MinTapTarget(child: TextButton.icon(
                    key: const ValueKey('filter-manual-reorder'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.open_with, size: 16),
                    label: Text(l10n.reorderNotesManually),
                    onPressed: () {
                      ref.read(noteSortProvider.notifier).set(NoteSort.manual);
                      ref.read(reorderModeProvider.notifier).set(true);
                      Navigator.pop(context);
                    },
                  ))
                : null,
            child: _OptionWrap(
              children: [
                for (final s in NoteSort.values)
                  _Option(
                    label: sortLabel(l10n, s),
                    icon: _sortIcon(s),
                    selected: sort == s,
                    onTap: () => ref.read(noteSortProvider.notifier).set(s),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 2),
          Text(
            l10n.filterSheetSortHint,
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              l10n.tagLongPressHint,
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

/// Etiket "yönet" menüsü: yeniden adlandır / sil. İkisi de TÜM notlara
/// uygulanır (bkz. [NotesRepository.renameTag] / [NotesRepository.deleteTag]).
Future<void> _manageTag(BuildContext context, WidgetRef ref, String tag) async {
  final l10n = context.l10n;
  final action = await showAppSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                '${l10n.tagManageTitle}: $tag',
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: Text(l10n.tagRename),
            onTap: () => Navigator.pop(sheetContext, 'rename'),
          ),
          ListTile(
            leading: Icon(
              Icons.delete_outline,
              color: Theme.of(sheetContext).colorScheme.error,
            ),
            title: Text(l10n.tagDelete),
            onTap: () => Navigator.pop(sheetContext, 'delete'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (action == null || !context.mounted) return;
  final repo = ref.read(notesRepositoryProvider);
  if (repo == null) return;
  // Depo zaten canlı akışı besliyor; ikinci bir sunucu okuması yapılmaz.
  final notes = ref.read(notesStreamProvider).value ?? const <Note>[];
  final messenger = ScaffoldMessenger.of(context);

  if (action == 'rename') {
    final controller = TextEditingController(text: tag);
    final next = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.tagRename),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: l10n.tagRenameHint),
          onSubmitted: (v) => Navigator.pop(dialogContext, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
    controller.dispose();
    if (next == null || next.trim().isEmpty || next.trim() == tag) return;
    // Seçili etiket yeniden adlandırılıyorsa süzgeç yeni ada taşınır, yoksa
    // ekran "hiç not yok" gösterirdi.
    if (ref.read(selectedTagProvider) == tag) {
      ref.read(selectedTagProvider.notifier).set(next.trim());
    }
    await repo.renameTag(notes, tag, next.trim());
    messenger
      ..hideCurrentSnackBar()
      ..showMessage(l10n.tagRenamed);
    return;
  }

  final confirmed = await showConfirmDialog(
    context,
    title: l10n.tagDelete,
    message: l10n.tagDeleteConfirm(tag),
    confirmLabel: l10n.delete,
    destructive: true,
  );
  if (!confirmed) return;
  if (ref.read(selectedTagProvider) == tag) {
    ref.read(selectedTagProvider.notifier).set(null);
  }
  await repo.deleteTag(notes, tag);
  messenger
    ..hideCurrentSnackBar()
    ..showMessage(l10n.tagDeleted);
}

/// Süzgeç türünün yerelleştirilmiş etiketi (eski çip barından taşındı).
String filterLabel(AppLocalizations l10n, NoteFilter filter) =>
    switch (filter) {
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
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.l),
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
                  style: sectionLabelStyle(context),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 6),
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
      Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: children,
      );
}

/// Çip satırının başındaki küçük ad ("Tür", "Durum").
class _RowLabel extends StatelessWidget {
  const _RowLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(start: 2, end: 2),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}

class _Option extends StatelessWidget {
  const _Option({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.onLongPress,
    this.toggle = false,
  });

  /// Aç-kapa seçeneği (görünüm): seçiliyken simgenin yerinde ✓, ekran
  /// okuyucuya "açık/kapalı" söylenir.
  final bool toggle;

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  /// Etiket çipinde "yönet" menüsünü açar (yeniden adlandır / sil); diğer
  /// seçeneklerde null.
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Seçili çip dolgun (primary), seçilmemiş tonal — kenarlık çizgisi yok:
    // eski tasarımda her çipin kenarlığı levhayı tel kafese çeviriyordu.
    final background = selected ? scheme.primary : scheme.surfaceContainerHigh;
    final foreground = selected ? scheme.onPrimary : scheme.onSurface;
    // Görünüm 38 dp; dokunma/ekran okuyucu alanı 48 dp (F15.4). Seçili mi
    // ekran okuyucuya da söylenir.
    return MinTapTarget(
      child: Semantics(
        selected: toggle ? null : selected,
        toggled: toggle ? selected : null,
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            onLongPress: onLongPress,
            child: Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      toggle && selected ? Icons.check : icon,
                      size: 16,
                      color: selected ? scheme.onPrimary : scheme.primary,
                    ),
                    const SizedBox(width: 6),
                  ],
                  // Büyük yazıda (F15.1) uzun ad çipi taşırmasın: kısalır.
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: foreground,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Aramanın KAPSAM çipi: ek içeriği (PDF metni + görsel OCR) de taransın mı.
///
/// Uygulanmış süzgeç çipiyle aynı boy, ama "kaldır" çarpısı yok: bu bir
/// süzgeç değil, aramanın nereye baktığını söyleyen bir anahtar.
class _AttachmentScopeChip extends StatelessWidget {
  const _AttachmentScopeChip({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 6),
      child: Material(
        color: selected ? scheme.secondaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? Colors.transparent : scheme.outlineVariant,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected ? Icons.image_search : Icons.image_search_outlined,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  l10n.searchAttachments,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
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
