import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_design.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/a11y/min_tap_target.dart';
import '../../../core/app_icons.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/press_scale.dart';
import '../../../core/widgets/sheet_header.dart';
import '../../../core/widgets/toggle_pop.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../../ai/data/attachment_text_index.dart';
import '../../folders/data/folder_order.dart';
import '../../folders/data/folders_repository.dart';
import '../../folders/domain/note_folder.dart';
import '../../settings/settings_providers.dart';
import '../data/notes_repository.dart';
import '../domain/note.dart';
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
Future<void> showFilterSheet(BuildContext context) => showAppSheet<void>(
  context: context,
  isScrollControlled: true,
  // ÖBÜR MENÜLER GİBİ M3 TUTAMAĞI (kullanıcı bulgusu 2026-11-27): tutamaktan
  // aşağı çekince kapanır; ✕ ve geri de kapatır.
  showDragHandle: true,
  // Geniş ekranda ortada, en çok 560 dp (KT-2): yalnız maxHeight
  // verilince M3'ün genişlik sınırı kalkıyor, levha 1240 px'e yayılıyordu.
  constraints: BoxConstraints(
    maxHeight: MediaQuery.sizeOf(context).height * 0.85,
    maxWidth: kSheetMaxWidth,
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
      ? (ref.watch(sharedFolderRefsProvider).value ?? const <SharedFolderRef>[])
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = AppText.of(theme);
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
            padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
            child: AnimatedSize(
              duration: AppMotion.of(context, AppMotion.short),
              curve: AppMotion.curveOf(context, AppMotion.emphasized),
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
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(AppRadius.s),
                        border: Border.all(color: scheme.primary, width: 1.4),
                      )
                    : null,
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.s),
                    onTap: () => showFilterSheet(context),
                    child: !active
                        ? Icon(
                            Icons.tune,
                            size: AppIconSize.s,
                            color: scheme.onSurfaceVariant,
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(width: AppSpace.s),
                              Flexible(
                                child: Text(
                                  label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: text.meta.copyWith(
                                    fontWeight: AppWeight.strong,
                                    color: scheme.onPrimaryContainer,
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
                                    horizontal: AppSpace.xs + 1,
                                    vertical: AppSpace.s,
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    size: AppIconSize.xs,
                                    color: scheme.onPrimaryContainer,
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
      padding: const EdgeInsets.fromLTRB(AppSpace.m, AppSpace.s, AppSpace.m, 0),
      child: SizedBox(
        height: 36,
        child: ListView(scrollDirection: Axis.horizontal, children: chips),
      ),
    );
  }
}

/// Görünüm kartı (F11.4 → 2026-11-27 YENİDEN TASARIM, kullanıcı isteği:
/// "süz ve sıraların tasarımı diğer menülere benzemiyor, güzel değil").
/// Not ⋮ menüsüyle aynı dil: beyaz grup kartı, yeşil bölüm adı, dolgulu
/// karolar. Izgara ⇄ liste iki yatay karo (seçili = dolu birincil); aç-kapa
/// seçenekleri iki sütunlu karolar (açık = yumuşak birincil + ✓).
class _ViewModeSection extends ConsumerWidget {
  const _ViewModeSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final list = ref.watch(noteListViewProvider);
    void set(bool wantList) {
      if (wantList != ref.read(noteListViewProvider)) {
        AppHaptics.tick();
        ref.read(noteListViewProvider.notifier).toggle();
      }
    }

    final shared = ref.watch(homeShowSharedProvider);
    final toggles = <Widget>[
      // KLASÖR SATIRI (⋮ menüsünden buraya, 2026-11-10).
      _FilterTile(
        key: const ValueKey('view-toggle-folder-strip'),
        kind: _TileKind.toggle,
        label: l10n.homeFolderStripShort,
        icon: Icons.folder_outlined,
        selected: !ref.watch(homeFolderStripHiddenProvider),
        onTap: () {
          AppHaptics.tick();
          ref.read(homeFolderStripHiddenProvider.notifier).toggle();
        },
      ),
      // TAKVİM ŞERİDİ (Zemin levhasında da var; burası kısayol).
      _FilterTile(
        key: const ValueKey('view-toggle-calendar-strip'),
        kind: _TileKind.toggle,
        label: l10n.homeCalendarStripShort,
        icon: Icons.calendar_view_week_outlined,
        selected: ref.watch(homeCalendarStripProvider),
        onTap: () {
          AppHaptics.tick();
          ref
              .read(homeCalendarStripProvider.notifier)
              .set(!ref.read(homeCalendarStripProvider));
        },
      ),
      // KARTTA GÖRSEL / EK (kullanıcı isteği 2026-10-23): Ayarlar'daki
      // "Kartta görünenler"in kısayolu.
      _FilterTile(
        kind: _TileKind.toggle,
        label: l10n.cardShowMediaShort,
        icon: Icons.image_outlined,
        selected: ref.watch(cardShowMediaProvider),
        onTap: () {
          AppHaptics.tick();
          ref.read(cardShowMediaProvider.notifier).toggle();
        },
      ),
      _FilterTile(
        kind: _TileKind.toggle,
        label: l10n.cardShowFilesShort,
        icon: Icons.attach_file,
        selected: ref.watch(cardShowFilesProvider),
        onTap: () {
          AppHaptics.tick();
          ref.read(cardShowFilesProvider.notifier).toggle();
        },
      ),
      // "Tümü" açıkken: klasör başlıkları altında grupla (D4).
      if (ref.watch(showAllNotesProvider))
        _FilterTile(
          kind: _TileKind.toggle,
          label: l10n.groupByFolder,
          icon: Icons.folder_copy_outlined,
          selected: ref.watch(allNotesGroupByFolderProvider),
          onTap: () {
            AppHaptics.tick();
            ref.read(allNotesGroupByFolderProvider.notifier).toggle();
          },
        ),
      _FilterTile(
        kind: _TileKind.toggle,
        label: l10n.homeShowSharedShort,
        icon: AppIcons.shared,
        selected: shared,
        onTap: () {
          AppHaptics.tick();
          ref.read(homeShowSharedProvider.notifier).toggle();
        },
      ),
      // "Paylaşılanlar altta" KALKTI (kullanıcı isteği 2026-11-28:
      // "paylaşılanların kendine ait bir yeri var; altta/üstte gibi
      // seçenekleri kaldıralım").
    ];
    return _Card(
      children: [
        _Title(l10n.viewToggle),
        Semantics(
          container: true,
          child: Row(
            key: const ValueKey('filter-view-mode'),
            spacing: AppSpace.s,
            children: [
              Expanded(
                child: _FilterTile(
                  key: const ValueKey('filter-view-grid'),
                  label: l10n.viewGrid,
                  icon: Icons.grid_view_rounded,
                  selected: !list,
                  horizontal: true,
                  onTap: () => set(false),
                ),
              ),
              Expanded(
                child: _FilterTile(
                  key: const ValueKey('filter-view-list'),
                  label: l10n.viewList,
                  icon: Icons.view_agenda_outlined,
                  selected: list,
                  horizontal: true,
                  onTap: () => set(true),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.s),
        _TileGrid(columns: 2, horizontal: true, children: toggles),
      ],
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
    NoteFilter.all => Icons.apps_rounded,
    NoteFilter.text => Icons.notes_rounded,
    NoteFilter.checklist => Icons.check_box_outlined,
    NoteFilter.ordered => Icons.format_list_numbered_rounded,
    NoteFilter.pinned => Icons.push_pin_outlined,
    NoteFilter.starred => Icons.star_outline_rounded,
    NoteFilter.reminded => Icons.alarm_rounded,
    NoteFilter.locked => Icons.lock_outline_rounded,
    NoteFilter.others => Icons.folder_off_outlined,
  };

  static IconData _sortIcon(NoteSort s) => switch (s) {
    NoteSort.manual => Icons.pan_tool_alt_outlined,
    NoteSort.updated => Icons.history_rounded,
    NoteSort.created => Icons.fiber_new_outlined,
    NoteSort.title => Icons.sort_by_alpha_rounded,
    NoteSort.color => AppIcons.color,
    NoteSort.active => Icons.local_fire_department_outlined,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = AppTokens.fromTheme(theme);
    final text = AppText.of(theme);
    final filter = ref.watch(noteFilterProvider);
    final tag = ref.watch(selectedTagProvider);
    final sort = ref.watch(noteSortProvider);
    final tags = ref.watch(allTagsProvider);
    final appliedCount = appliedFilterCount(ref);
    void setFilter(NoteFilter f) {
      AppHaptics.tick();
      ref.read(noteFilterProvider.notifier).set(f);
    }

    void setTag(String? t) {
      AppHaptics.tick();
      ref.read(selectedTagProvider.notifier).set(t);
    }

    void reset() {
      AppHaptics.tick();
      resetFilters(ref);
    }

    Widget filterTile(NoteFilter f) => _FilterTile(
      label: filterLabel(l10n, f),
      icon: _filterIcon(f),
      selected: filter == f,
      onTap: () => setFilter(f),
    );

    Widget hairline() => Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.s),
      child: Divider(height: 1, color: tokens.hairline),
    );

    // TUTAMAK LEVHANIN KENDİSİNDE (kullanıcı bulgusu 2026-11-27: "üstteki
    // tutamacından tutup aşağı çekip kapatamıyorum, sadece geri tuşuyla
    // kapanıyor"). KÖK NEDEN: eski kapsül `SingleChildScrollView`un İÇİNDE
    // çiziliyordu; sürükleme levhaya değil kaydırmaya gidiyordu. Artık öbür
    // menüler gibi M3 tutamağı ([showAppSheet] `showDragHandle`) + kaydırma
    // dışında sabit başlık: tutamaktan ya da başlıktan aşağı çekince kapanır.
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(
            title: l10n.homeViewMenu,
            padding: const EdgeInsetsDirectional.only(
              start: AppSpace.l,
              end: AppSpace.s,
            ),
            badge: appliedCount > 0
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.s,
                      vertical: AppSpace.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      '$appliedCount',
                      style: text.badge.copyWith(color: scheme.onPrimary),
                    ),
                  )
                : null,
            actions: [
              if (appliedCount > 0)
                TextButton.icon(
                  onPressed: reset,
                  icon: const Icon(
                    Icons.filter_alt_off_outlined,
                    size: AppIconSize.s,
                  ),
                  label: Text(l10n.filterReset),
                ),
            ],
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.l,
                0,
                AppSpace.l,
                AppSpace.m,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _ViewModeSection(),
                  const SizedBox(height: AppSpace.s),
                  // TÜR, DURUM, ETİKET, SIRALAMA TEK KARTTA (not ⋮ menüsü
                  // gibi): gruplar arasında ince ayırıcı.
                  _Card(
                    children: [
                      _Title(l10n.filterSheetTitle),
                      _SubLabel(l10n.filterSectionType),
                      _TileGrid(
                        columns: 4,
                        children: [for (final f in _typeFilters) filterTile(f)],
                      ),
                      const SizedBox(height: AppSpace.s),
                      _SubLabel(l10n.filterSectionStatus),
                      _TileGrid(
                        columns: 3,
                        children: [
                          for (final f in NoteFilter.values)
                            if (!_typeFilters.contains(f)) filterTile(f),
                        ],
                      ),
                      // **KLASÖR BÖLÜMÜ BURADA YOK** (kullanıcı isteği
                      // 2026-08-18: "şu an etiketle klasör aynı şey"). Klasör
                      // ana ekranda karosu olan bir YER; etiket sıcak tonlu
                      // haplarla saf etiket olarak burada kalır (Y5).
                      if (tags.isNotEmpty) ...[
                        hairline(),
                        _Title(l10n.filterSectionTag),
                        Wrap(
                          spacing: AppSpace.s,
                          runSpacing: AppSpace.s,
                          children: [
                            for (final t in tags)
                              _FilterTile(
                                kind: _TileKind.tag,
                                label: t,
                                icon: Icons.tag_rounded,
                                selected: tag == t,
                                horizontal: true,
                                onTap: () => setTag(tag == t ? null : t),
                                // **ETİKET YÖNETİMİ**: uzun basınca yeniden
                                // adlandır / sil.
                                onLongPress: () => _manageTag(context, ref, t),
                              ),
                          ],
                        ),
                      ],
                      hairline(),
                      _Title(
                        l10n.filterSectionSort,
                        // Elle sıralama kipi sıralama bölümünün İÇİNDE: yalnız
                        // süzgeçsiz görünümde anlamlı.
                        trailing: appliedCount == 0
                            ? TextButton.icon(
                                key: const ValueKey('filter-manual-reorder'),
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                ),
                                icon: const Icon(
                                  Icons.open_with_rounded,
                                  size: AppIconSize.xs,
                                ),
                                label: Text(l10n.reorderNotesManually),
                                onPressed: () {
                                  AppHaptics.tick();
                                  ref
                                      .read(noteSortProvider.notifier)
                                      .set(NoteSort.manual);
                                  ref
                                      .read(reorderModeProvider.notifier)
                                      .set(true);
                                  Navigator.pop(context);
                                },
                              )
                            : null,
                      ),
                      _TileGrid(
                        columns: 3,
                        children: [
                          for (final s in NoteSort.values)
                            _FilterTile(
                              label: sortLabel(l10n, s),
                              icon: _sortIcon(s),
                              selected: sort == s,
                              onTap: () {
                                AppHaptics.tick();
                                ref.read(noteSortProvider.notifier).set(s);
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.s),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.xs,
                    ),
                    child: Text(
                      tags.isEmpty
                          ? l10n.filterSheetSortHint
                          : '${l10n.filterSheetSortHint} '
                                '${l10n.tagLongPressHint}',
                      style: text.meta,
                    ),
                  ),
                ],
              ),
            ),
          ),
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
            padding: const EdgeInsets.fromLTRB(
              AppSpace.xl,
              0,
              AppSpace.xl,
              AppSpace.s,
            ),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                '${l10n.tagManageTitle}: $tag',
                style: AppText.of(Theme.of(sheetContext)).sheetTitle,
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
          const SizedBox(height: AppSpace.s),
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

/// Grup kartı — not ⋮ menüsündeki kartın aynısı ([AppSurface.sheetCard]).
class _Card extends StatelessWidget {
  const _Card({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: AppSurface.sheetCard(Theme.of(context)),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.s,
        AppSpace.xxs,
        AppSpace.s,
        AppSpace.s,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    ),
  );
}

/// Bölüm adı — not menüsünün grup başlığıyla aynı (`AppText.section`).
class _Title extends StatelessWidget {
  const _Title(this.text, {this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpace.xs,
      AppSpace.xxs,
      AppSpace.xs,
      AppSpace.xs,
    ),
    child: SizedBox(
      height: trailing == null ? null : AppSpace.xxxl,
      child: Row(
        children: [
          Expanded(child: SectionLabel(text)),
          ?trailing,
        ],
      ),
    ),
  );
}

/// Kartın içindeki küçük alt ad ("Tür", "Durum").
class _SubLabel extends StatelessWidget {
  const _SubLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpace.xs,
      0,
      AppSpace.xs,
      AppSpace.xs,
    ),
    child: Text(
      text,
      style: AppText.of(Theme.of(context)).meta
          .copyWith(fontWeight: AppWeight.strong),
    ),
  );
}

/// Boş hücre bırakmayan karo ızgarası (not menüsünün `_buildTileGrid`
/// kuralı): tam satırlar [columns] sütun dikey karo; son satır 1–2 öğeyse
/// yatay karolar tam genişliğe yayılır.
class _TileGrid extends StatelessWidget {
  const _TileGrid({
    required this.columns,
    required this.children,
    this.horizontal = false,
  });

  final int columns;
  final List<Widget> children;

  /// Bütün karolar yatay (simge solda, ad yanında).
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final rows = <List<Widget>>[];
    for (var i = 0; i < children.length; i += columns) {
      final end = i + columns;
      rows.add(
        children.sublist(i, end > children.length ? children.length : end),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.s,
      children: [
        for (final r in rows)
          Row(
            spacing: AppSpace.s,
            children: [
              for (final c in r)
                Expanded(
                  child: _TileShape(
                    horizontal: horizontal || r.length <= 2,
                    child: c,
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

/// Izgaradaki karoya "dikey mi yatay mı" bilgisini taşır.
class _TileShape extends InheritedWidget {
  const _TileShape({required this.horizontal, required super.child});

  final bool horizontal;

  static bool? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_TileShape>()?.horizontal;

  @override
  bool updateShouldNotify(_TileShape old) => old.horizontal != horizontal;
}

/// Karo rolleri:
/// - [choice]: tek seçimli süzgeç/sıralama — seçili = dolu birincil (not
///   menüsündeki "açık" karo gibi)
/// - [toggle]: görünüm aç/kapa — açık = yumuşak birincil + ✓
/// - [tag]: sıcak tonlu etiket (Y5: etiket renkli kalır)
enum _TileKind { choice, toggle, tag }

class _FilterTile extends StatelessWidget {
  const _FilterTile({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.onLongPress,
    this.kind = _TileKind.choice,
    this.horizontal,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  /// Etiket karosunda "yönet" menüsünü açar (yeniden adlandır / sil).
  final VoidCallback? onLongPress;
  final _TileKind kind;

  /// null = ızgaranın verdiği biçim (yoksa dikey).
  final bool? horizontal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = AppTokens.fromTheme(theme);
    final text = AppText.of(theme);
    final isHorizontal = horizontal ?? _TileShape.of(context) ?? false;
    final idle = theme.brightness == Brightness.dark
        ? scheme.surfaceContainerHigh
        : scheme.surfaceContainer;

    final Color background;
    final Color foreground;
    final Color iconColor;
    switch (kind) {
      case _TileKind.choice:
        background = selected ? scheme.primary : idle;
        foreground = selected ? scheme.onPrimary : scheme.onSurface;
        iconColor = selected ? scheme.onPrimary : scheme.primary;
      case _TileKind.toggle:
        background = selected ? scheme.primaryContainer : idle;
        foreground = selected ? scheme.onPrimaryContainer : scheme.onSurface;
        iconColor = selected ? scheme.primary : scheme.onSurfaceVariant;
      case _TileKind.tag:
        background = selected
            ? scheme.secondary
            : tokens.resolvedWarmTint(scheme);
        foreground = selected ? scheme.onSecondary : scheme.onSurface;
        iconColor = selected ? scheme.onSecondary : scheme.secondary;
    }
    final labelStyle = text.meta.copyWith(
      color: foreground,
      fontWeight: selected ? AppWeight.strong : AppWeight.medium,
    );
    final glyph = Icon(icon, size: AppIconSize.m, color: iconColor);
    final Widget body;
    if (isHorizontal) {
      body = ConstrainedBox(
        constraints: const BoxConstraints(minHeight: kMinInteractiveDimension),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.m,
            vertical: AppSpace.xs,
          ),
          child: Row(
            mainAxisSize: kind == _TileKind.tag
                ? MainAxisSize.min
                : MainAxisSize.max,
            spacing: AppSpace.s,
            children: [
              TogglePop(on: selected, child: glyph),
              Flexible(
                fit: kind == _TileKind.tag ? FlexFit.loose : FlexFit.tight,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: labelStyle,
                ),
              ),
              if (kind == _TileKind.toggle)
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: AppIconSize.s,
                  color: selected ? scheme.primary : tokens.hairline,
                ),
            ],
          ),
        ),
      );
    } else {
      body = ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 58),
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.xs),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpace.xs,
            children: [
              TogglePop(on: selected, child: glyph),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: labelStyle,
              ),
            ],
          ),
        ),
      );
    }
    final isToggle = kind == _TileKind.toggle;
    // Seçili mi ekran okuyucuya da söylenir; dokunma alanı ≥ 48 dp.
    return Semantics(
      button: true,
      selected: isToggle ? null : selected,
      toggled: isToggle ? selected : null,
      child: PressScale(
        child: AnimatedContainer(
          duration: AppMotion.of(context, AppMotion.quick),
          curve: AppMotion.curveOf(context, AppMotion.emphasized),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(AppRadius.m),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.m),
              onTap: onTap,
              onLongPress: onLongPress,
              child: body,
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = AppTokens.fromTheme(theme);
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: AppSpace.xs + 2),
      child: Material(
        color: selected ? scheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.s),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.s),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.m - 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.s),
              border: Border.all(
                color: selected
                    ? tokens.resolvedAccentBorder(scheme)
                    : scheme.outlineVariant,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected ? Icons.image_search : Icons.image_search_outlined,
                  size: AppIconSize.xs,
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpace.xs + 2),
                Text(
                  l10n.searchAttachments,
                  style: AppText.of(theme).label.copyWith(
                    color: selected
                        ? scheme.onPrimaryContainer
                        : scheme.onSurface,
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
