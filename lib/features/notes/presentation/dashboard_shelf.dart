part of 'dashboard_screen.dart';

/// Klasör rafı: şerit ve karo görünümü (C1).
extension _DashShelf on _DashboardScreenState {
  /// Ana ekranın tepesindeki **klasör rafı**: her klasör bir karo, sonda
  /// "Yeni klasör". Karolar not kartlarıyla AYNI sütun düzenini kullanır ki
  /// raf ızgaranın devamı gibi dursun, ayrı bir bölüm gibi değil.
  ///
  /// Gizli klasörler yalnız o oturumda açığa çıkarıldıysa çizilir — karonun
  /// adı bile gizli notların varlığını ele verirdi.
  Widget _folderShelf(int columns, {String? selectedFolderId}) {
    // Kullanıcının KLASÖR SIRASI (Ayarlar → Notlar → Klasör sırası; bkz.
    // FolderSort). Gizli klasörler yalnız açığa çıkarıldıysa.
    final folders = ref.watch(visibleOrderedFoldersProvider);
    if (selectedFolderId != null) {
      return _folderStrip(folders, selectedFolderId: selectedFolderId);
    }
    // **YER SORUNU** (kullanıcı isteği 2026-08-18: "klasörler ana ekranda çok
    // fazla yer kaplıyor, farklı bir çözüm bulalım"): karo rafı üç klasörde
    // bir 92 px'lik satır açıyor ve notlar ekranın altına iniyordu. Varsayılan
    // artık TEK SATIRLIK yatay çip şeridi (~40 px, kaç klasör olursa olsun);
    // karo görünümü tek dokunuşla geri gelir ve tercih hatırlanır (bkz.
    // [folderShelfExpandedProvider]).
    if (!ref.watch(folderShelfExpandedProvider)) {
      return _folderStrip(folders);
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
              // Ortak notlar artık üst çubuktaki "Gelen ve paylaşılanlar"
              // düğmesinde (bkz. SharedHubButton).
              const Padding(
                padding: EdgeInsetsDirectional.only(start: 12),
                child: AllNotesChip(),
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
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
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
  Widget _folderStrip(List<NoteFolder> folders, {String? selectedFolderId}) {
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
    return SliverToBoxAdapter(
      child: SizedBox(
        height: FolderChip.stripHeight,
        child: Row(
          children: [
            Expanded(
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
                children: [
                  // "Tümü" en başta (kullanıcı isteği 2026-10-20).
                  const AllNotesChip(),
                  const SizedBox(width: 6),
                  for (final share in hotShared) ...[
                    SharedFolderChip(
                      key: ValueKey('shared-chip-${share.folderId}'),
                      share: share,
                    ),
                    const SizedBox(width: 6),
                  ],
                  for (final folder in ordered) ...[
                    _EnsureVisible(
                      key: ValueKey('folder-chip-${folder.id}'),
                      active: folder.id == selectedFolderId,
                      child: FolderChip(
                        folder: folder,
                        selected: folder.id == selectedFolderId,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  for (final share in calmShared) ...[
                    SharedFolderChip(
                      key: ValueKey('shared-chip-${share.folderId}'),
                      share: share,
                    ),
                    const SizedBox(width: 6),
                  ],
                  const NewFolderChip(),
                ],
              ),
            ),
            // Karo görünümüne geçiş: klasörleri bir arada görmek isteyen
            // kullanıcı için kapı açık kalsın.
            IconButton(
              tooltip: context.l10n.folderShelfExpand,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.unfold_more, size: 18),
              onPressed: () =>
                  ref.read(folderShelfExpandedProvider.notifier).toggle(),
            ),
          ],
        ),
      ),
    );
  }
}
