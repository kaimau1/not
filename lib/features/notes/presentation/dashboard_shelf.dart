part of 'dashboard_screen.dart';

/// Klasör rafı: şerit ve karo görünümü (C1).
extension _DashShelf on _DashboardScreenState {
  /// Ana ekranın tepesindeki **klasör rafı**: her klasör bir karo, sonda
  /// "Yeni klasör". Karolar not kartlarıyla AYNI sütun düzenini kullanır ki
  /// raf ızgaranın devamı gibi dursun, ayrı bir bölüm gibi değil.
  ///
  /// Gizli klasörler yalnız o oturumda açığa çıkarıldıysa çizilir — karonun
  /// adı bile gizli notların varlığını ele verirdi.
  Widget _folderShelf(
    int columns, {
    String? selectedFolderId,
    bool hubSelected = false,
    SharedFolderKey? sharedFolder,
  }) {
    // Kullanıcının KLASÖR SIRASI (Ayarlar → Notlar → Klasör sırası; bkz.
    // FolderSort). Gizli klasörler yalnız açığa çıkarıldıysa.
    final folders = ref.watch(visibleOrderedFoldersProvider);
    // "Gelen" seçiliyken de şerit (klasör seçiliyken olduğu gibi): çip
    // vurgulu görünsün, karo rafı notların yerini kaplamasın.
    if (selectedFolderId != null || hubSelected || sharedFolder != null) {
      return SliverToBoxAdapter(
        child: _folderStrip(
          folders,
          selectedFolderId: selectedFolderId,
          sharedFolder: sharedFolder,
        ),
      );
    }
    // **YER SORUNU** (kullanıcı isteği 2026-08-18: "klasörler ana ekranda çok
    // fazla yer kaplıyor, farklı bir çözüm bulalım"): karo rafı üç klasörde
    // bir 92 px'lik satır açıyor ve notlar ekranın altına iniyordu. Varsayılan
    // artık TEK SATIRLIK yatay çip şeridi (~40 px, kaç klasör olursa olsun);
    // karo görünümü tek dokunuşla geri gelir ve tercih hatırlanır (bkz.
    // [folderShelfExpandedProvider]).
    if (!ref.watch(folderShelfExpandedProvider)) {
      return SliverToBoxAdapter(child: _folderStrip(folders));
    }
    // **PAYLAŞILAN klasörler AYNI RAFTA** (kullanıcı isteği 2026-08-18:
    // "ortak notlar klasörü kişiler bağlanır notları ortak görür"). Kendi
    // klasörlerimden SONRA gelirler — kendi düzenim önce, arkadaşlarımınki
    // sonra; iki liste ayrı kaynaktan geldiği için gizli klasör süzgeci
    // burada geçerli değil (paylaşılan bir klasör asla "benim gizli
    // klasörüm" olamaz).
    final shared = ref.watch(sharedFolderRefsProvider).value ?? const [];
    final total = folders.length + shared.length;
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsetsDirectional.only(start: 12),
                child: AllNotesChip(),
              ),
              // Gelen ve paylaşılanlar: Tümü'nün yanında (2026-10-31).
              if (!ref.watch(sharedHubFolderProvider).hidden)
                const Padding(
                  padding: EdgeInsetsDirectional.only(start: 6),
                  child: SharedHubChip(),
                ),
              const Spacer(),
              TextButton.icon(
                onPressed: () =>
                    ref.read(folderShelfExpandedProvider.notifier).toggle(),
                icon: const Icon(Icons.unfold_less, size: 18),
                label: Text(context.l10n.folderShelfCollapse),
              ),
            ],
          ),
        ),
        _folderGrid(columns, folders, shared, total),
      ],
    );
  }

  /// Klasör rafının KARO (açık) hâli — bkz. [_folderShelf].
  Widget _folderGrid(
    int columns,
    List<NoteFolder> folders,
    List<SharedFolderRef> shared,
    int total,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(kGridInset, 8, kGridInset, 4),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: kGridGap,
          crossAxisSpacing: kGridGap,
          mainAxisExtent: FolderTile.height,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index == total) return const NewFolderTile();
          if (index < folders.length) {
            final folder = folders[index];
            return FolderTile(
              key: ValueKey('folder-${folder.id}'),
              folder: folder,
            );
          }
          final share = shared[index - folders.length];
          return SharedFolderTile(
            key: ValueKey('shared-folder-${share.folderId}'),
            share: share,
          );
        }, childCount: total + 1),
      ),
    );
  }

  /// Klasör rafının KOMPAKT (varsayılan) hâli: tek satır, yatay kaydırılan
  /// çipler. Yükseklik klasör sayısından BAĞIMSIZ — asıl kazanç bu.
  Widget _folderStrip(
    List<NoteFolder> folders, {
    String? selectedFolderId,
    SharedFolderKey? sharedFolder,
  }) {
    _maybeGridSwipeTip(folders);
    final shared = ref.watch(sharedFolderRefsProvider).value ?? const [];
    // YENİ HAREKET ÖNE (kullanıcı bulgusu 2026-10-17: "paylaşılanlarda yeni
    // bir şey geldiğinde anlaşılmıyor"): okunmamışı olan paylaşılan
    // klasörler şeridin SONUNDAydı — birkaç klasörden sonra ekran dışında
    // kalıyor, rozet görünmüyordu. Okunmamış varsa en başa geçerler.
    // ORTAK NOTLAR çipi şeritten kalktı (2026-10-17: "gelen ve paylaşılan
    // notları birleştir, tek alandan yönetilsin") — üst çubuktaki rozetli
    // "Gelen ve paylaşılanlar" düğmesinde (bkz. SharedHubButton).
    final hotShared = [
      for (final share in shared)
        if (ref.watch(
              folderUnreadProvider((
                ownerId: share.ownerId,
                folderId: share.folderId,
              )),
            ) >
            0)
          share,
    ];
    final calmShared = [
      for (final share in shared)
        if (!hotShared.contains(share)) share,
    ];
    // BOŞ KLASÖRLER SONA (geliştirme raporu B3: "Genel 0", "Borç 0" şeridin
    // başında yer kaplıyordu); çip ayrıca soluk (bkz. FolderChip). Sayılar
    // yalnız BOŞ KÜMEYİ izleyen seçimle okunur (virgüllü kimlikler) — her
    // not yazımında şerit yeniden dizilmesin.
    final emptyKey = ref.watch(
      folderNoteCountsProvider.select(
        (m) => [
          for (final f in folders)
            if ((m[f.id] ?? 0) == 0) f.id,
        ].join(','),
      ),
    );
    final empty = emptyKey.split(',').toSet();
    final ordered = emptyFoldersLast(folders, ref.watch(folderSortProvider), {
      for (final f in folders) f.id: empty.contains(f.id) ? 0 : 1,
    });
    final hub = ref.watch(sharedHubFolderProvider);
    final hubOn = ref.watch(sharedHubOnHomeProvider);
    Widget sharedChip(SharedFolderRef share) {
      final selected =
          sharedFolder?.folderId == share.folderId &&
          sharedFolder?.ownerId == share.ownerId;
      return _EnsureVisible(
        key: ValueKey('shared-chip-${share.folderId}'),
        active: selected,
        child: SharedFolderChip(share: share, selected: selected),
      );
    }

    // Bir klasörün içinde miyiz (kendi, Gelen ya da paylaşılan)?
    final inFolder =
        selectedFolderId != null || hubOn || sharedFolder != null;
    return KeyedSubtree(
      key: const ValueKey('home-folder-strip'),
      child: SizedBox(
        // 48 dp: baştaki "Ana sayfa" düğmesi tam dokunma yüksekliği alsın;
        // çiplerin kendisi yine 32 dp (dikey dolgu 8 + 8).
        height: FolderChip.stripHeight + 8,
        child: Row(
          children: [
            // ANA SAYFAYA DÖN (kullanıcı isteği 2026-11-06: "klasörlerde ana
            // menüye dön düğmesi olmalı, kaydırmayı bilmeyen ne yapacak"):
            // klasör içindeyken şeridin başında SABİT — kaydırılınca
            // kaybolmasın.
            //
            // 2026-11-07: ana sayfada da YERİNDE (dolu = "buradasın"):
            // yalnız klasör içindeyken çizilince her giriş/çıkışta bütün
            // şerit 56 dp sağa-sola sıçrıyordu.
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 8),
              child: inFolder
                  ? IconButton.filledTonal(
                      key: const ValueKey('home-strip-go-home'),
                      tooltip: context.l10n.goHome,
                      icon: const Icon(Icons.home_outlined, size: 20),
                      onPressed: () {
                        ref.read(selectedFolderProvider.notifier).set(null);
                        ref
                            .read(selectedSharedFolderProvider.notifier)
                            .set(null);
                        ref.read(sharedHubOnHomeProvider.notifier).set(false);
                        unawaited(HapticFeedback.selectionClick());
                      },
                    )
                  : IconButton.filled(
                      key: const ValueKey('home-strip-at-home'),
                      tooltip: context.l10n.goHome,
                      isSelected: true,
                      icon: const Icon(Icons.home, size: 20),
                      onPressed: _backToTop,
                    ),
            ),
            Expanded(
              child: ListView(
                scrollDirection: Axis.horizontal,
                // Ekran dışındaki seçili çip kurulu olmalı, yoksa ortalanamaz
                // (F39.3). Çipler ucuz.
                scrollCacheExtent: const ScrollCacheExtent.pixels(3000),
                padding: const EdgeInsets.fromLTRB(kGridInset, 8, 4, 8),
                children: [
                  // "Tümü" en başta (kullanıcı isteği 2026-10-20).
                  _EnsureVisible(
                    active:
                        selectedFolderId == null &&
                        !hubOn &&
                        sharedFolder == null,
                    child: const AllNotesChip(),
                  ),
                  const SizedBox(width: 5),
                  for (final share in hotShared) ...[
                    sharedChip(share),
                    const SizedBox(width: 5),
                  ],
                  // GELEN varsayılan olarak Tümü'nün yanında (2026-10-31); yeri
                  // Klasör sırası levhasından değişir (2026-11-02).
                  for (final folder in withSharedHub(
                    ordered,
                    hub,
                    hub.order ?? 0,
                  ))
                    if (folder.id != kSharedHubFolderId) ...[
                      _EnsureVisible(
                        key: ValueKey('folder-chip-${folder.id}'),
                        active: folder.id == selectedFolderId,
                        child: FolderChip(
                          folder: folder,
                          selected: folder.id == selectedFolderId,
                        ),
                      ),
                      const SizedBox(width: 5),
                    ] else if (!hub.hidden) ...[
                      _EnsureVisible(
                        active: hubOn,
                        child: const SharedHubChip(),
                      ),
                      const SizedBox(width: 5),
                    ],
                  for (final share in calmShared) ...[
                    sharedChip(share),
                    const SizedBox(width: 5),
                  ],
                  const NewFolderChip(),
                ],
              ),
            ),
            // TÜM KLASÖRLER düğmesi kalktı (2026-11-06): baştaki "Tümü"
            // çipi artık Klasörler ekranını açıyor (kullanıcı isteği).
          ],
        ),
      ),
    );
  }

  /// İLK IZGARA + KLASÖR (F14.6): ekranı yana kaydırmak klasörler (ya da
  /// süzgeçler) arasında gezer ama görünmez. Klasör ilk kez varken bir kez.
  void _maybeGridSwipeTip(List<NoteFolder> folders) {
    if (_gridTipChecked) return;
    final mode = ref.read(swipeModeProvider);
    if (mode == SwipeMode.off || ref.read(noteListViewProvider)) return;
    if (mode == SwipeMode.folders && folders.isEmpty) return;
    _gridTipChecked = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      TipOnce.show(
        context,
        ref.read(sharedPreferencesProvider),
        TipOnce.gridSwipe,
        mode == SwipeMode.filters
            ? context.l10n.tipGridSwipeFilters
            : context.l10n.tipGridSwipeFolders,
      );
    });
  }
}
