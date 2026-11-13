part of 'dashboard_screen.dart';

/// Not ızgarasının dilimleri: bölümler, boş durum, sürükleyerek sıralama (C1).
/// Bölüm başlığının çizgisi en çok okuma genişliğine uzanır (F39.1).
const double kSectionHeaderMaxWidth = 760;

/// Bu genişlikte ve üstünde bölüm çizgisi ÇİZİLMEZ (DENEYIM F80.3a, D22):
/// geniş ızgarada 760 dp'de biten çizgi kartların ortasında kesiliyordu
/// (`masaustu-ana.png`); başlık + sayı tek başına yeter.
const double kSectionLineHideWidth = 840;

/// Bölüm başlığı: sayı başlığın yanında, çizgi sonra (F39.1). Masaüstünde sayı
/// başlıktan ~1800 px uzağa düşüyordu.
class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader({super.key, required this.text, required this.count});

  final String text;
  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Ölçü başlığın KENDİ genişliği: bölünmüş görünümün dar liste
    // bölmesinde çizgi kalır, yalnız geniş ızgarada düşer.
    return LayoutBuilder(
      builder: (context, constraints) => _build(
        context,
        scheme,
        hideLine: constraints.maxWidth >= kSectionLineHideWidth,
      ),
    );
  }

  Widget _build(
    BuildContext context,
    ColorScheme scheme, {
    required bool hideLine,
  }) {
    return Padding(
      // Üst 8 (2026-11-09, 14'tü): üstteki takvim/klasör şeridiyle arada
      // boş bant kalıyordu.
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: kSectionHeaderMaxWidth),
          child: Row(
            children: [
              // Flexible OLMAZ: boş alan Expanded çizgiyle yarı yarıya bölünür.
              SectionLabel(text),
              const SizedBox(width: 6),
              Text(
                '· $count',
                semanticsLabel: context.l10n.sectionNoteCount(count),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              // Ağaç şekli sabit: genişte çizginin yerinde boş kutu.
              Expanded(
                child: hideLine
                    ? const SizedBox(height: 1)
                    : Divider(height: 1, color: scheme.outlineVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ana ekran boşken tek satır + tek eylem (F39.5): neden boş, ne yapılır.
class HomeEmptyNotes extends ConsumerWidget {
  const HomeEmptyNotes({
    super.key,
    required this.searchActive,
    required this.onClearSearch,
    required this.onNewNote,
  });

  final bool searchActive;
  final VoidCallback onClearSearch;
  final VoidCallback onNewNote;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    if (searchActive) {
      return EmptyState(
        icon: Icons.search_off,
        title: l10n.emptySearch,
        subtitle: l10n.emptySearchHint,
        actionLabel: l10n.clearSearch,
        actionIcon: Icons.close,
        onAction: onClearSearch,
      );
    }
    if (ref.watch(noteFilterProvider) != NoteFilter.all ||
        ref.watch(selectedTagProvider) != null) {
      return EmptyState(
        icon: Icons.filter_alt_off_outlined,
        title: l10n.emptyFilter,
        subtitle: l10n.emptyFilterHint,
        actionLabel: l10n.clearFilter,
        actionIcon: Icons.close,
        onAction: () {
          ref.read(noteFilterProvider.notifier).set(NoteFilter.all);
          ref.read(selectedTagProvider.notifier).set(null);
        },
      );
    }
    final inFolder = ref.watch(selectedFolderProvider) != null;
    return EmptyState(
      icon: Icons.sticky_note_2_outlined,
      title: inFolder ? l10n.emptyFolderTitle : l10n.emptyNotes,
      subtitle: inFolder ? l10n.emptyFolderHint : l10n.emptyNotesHint,
      // Hiç not yokken tek, davetkâr eylem (F74.6, D23): "+" panelindeki
      // Metin notunun aynısı — yeni iş yok.
      actionLabel: inFolder ? l10n.newNoteAction : l10n.emptyNotesFirstAction,
      actionIcon: inFolder ? null : Icons.edit_outlined,
      onAction: onNewNote,
    );
  }
}

extension _DashSlivers on _DashboardScreenState {
  /// "Gelen" süzgeci açıkken (bkz. [sharedHubOnHomeProvider]) not ızgarasının
  /// yerine gelen kopyalar + benimle paylaşılan notlar. Ayrı ekranla aynı
  /// içerik ([sharedHubSlivers]); boşsa klasörün boş hâli gibi tek mesaj.
  List<Widget> _hubSlivers(
    BuildContext context,
    int columns,
    double cellWidth,
  ) {
    final slivers = sharedHubSlivers(
      context,
      ref,
      columns: columns,
      cellWidth: cellWidth,
    );
    if (slivers.isNotEmpty) return slivers;
    final l10n = context.l10n;
    return [
      SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyState(
          icon: AppIcons.inbox,
          title: l10n.sharedHubEmpty,
          subtitle: l10n.sharedHubEmptyHint,
        ),
      ),
    ];
  }

  List<Widget> _buildNoteSlivers(
    BuildContext context,
    List<Note> notes,
    int columns, {
    required double cellWidth,
    required bool selectionActive,
    required bool searchActive,
    required bool reorderEnabled,
  }) {
    final l10n = context.l10n;
    // Ekrandaki sıra: rows()/grid() bölümleri çizdikçe doldurur (bkz.
    // [visibleNoteOrder]).
    final order = <Note>[];
    visibleNoteOrder = order;
    if (notes.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: HomeEmptyNotes(
            searchActive: searchActive,
            onClearSearch: () {
              _searchController.clear();
              ref.read(searchQueryProvider.notifier).set('');
            },
            onNewNote: () => unawaited(createNote(NoteType.text)),
          ),
        ),
      ];
    }

    // **ARAMA SONUÇ SAYISI**: "aradığım şey kaç notta var" sorusunun cevabı
    // hiçbir yerde yoktu; kullanıcı kartları saymak zorundaydı.
    final countHeader = <Widget>[
      if (searchActive)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                l10n.searchResultCount(notes.length),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
    ];

    _pruneCardCache(notes);
    final pinned = [
      for (final n in notes)
        if (n.pinned) n,
    ];
    final others = [
      for (final n in notes)
        if (!n.pinned) n,
    ];

    final query = ref.read(searchQueryProvider).trim();
    // Kartların canlı vurgusu (F21.6): kurulum sırasında yazılır — tembel
    // hücreler yerleşimde kurulduğu için orada yazmak dinleyen kesitlerde
    // yerleşim içinde setState olurdu.
    if (_liveQuery.value != query) _liveQuery.value = query;
    // [reorderEnabled] çağırandan gelir: sürükle-sırala artık ⋮ → "Notları
    // sırala" ile açılan AYRI bir moddur ([reorderModeProvider]). Eskiden
    // kalıcı olarak açıktı ve uzun basış sürüklemeyi başlatıyordu; seçmek
    // isteyen kullanıcı kartı kazara taşıyordu. Mod dışında uzun basış
    // her zaman SEÇER.

    final listView = ref.watch(noteListViewProvider);

    // Elle taşımanın anlamlı olduğu görünüm: süzgeçsiz, aramasız, tam liste.
    // (Aynı koşul ⋮ menüsündeki "Notları sırala" maddesinde de var.)
    final manualReorderAllowed =
        !searchActive &&
        ref.read(noteFilterProvider) == NoteFilter.all &&
        ref.read(selectedFolderProvider) == null &&
        ref.read(selectedSharedFolderProvider) == null &&
        !ref.read(showAllNotesProvider) &&
        ref.read(selectedTagProvider) == null;

    /// Liste görünümü: tek sütun, kompakt satır. Sürükle-sırala BURADA yok —
    /// o mod ızgaraya özgü (hücre genişliğiyle çalışıyor); liste görünümünde
    /// ⋮ menüsündeki sıralama maddesi zaten görünmüyor.
    Widget rows(List<Note> items) {
      order.addAll(items);
      return SliverList.separated(
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 2),
        itemBuilder: (context, index) {
          final note = items[index];
          // ANAHTAR ŞART: anahtarsız satırlarda bir not silinince ya da sıra
          // değişince `_FocusHaloState` YANLIŞ nota bağlanır — vurgu başka
          // satırda yanıp söner ve state boşuna taşınır. Izgarada zaten var,
          // liste görünümünde eksikti.
          //
          // RepaintBoundary: tek satırın vurgusu değişince görünen listenin
          // TAMAMI yeniden boyanıyordu.
          return KeyedSubtree(
            key: ValueKey(note.id),
            child: RepaintBoundary(
              child: Consumer(
                builder: (context, cellRef, _) {
                  final focused = cellRef.watch(
                    focusedNoteProvider.select((id) => id == note.id),
                  );
                  final selected = cellRef.watch(
                    selectedNoteIdsProvider.select((s) => s.contains(note.id)),
                  );
                  return _FocusHalo(
                    focused: focused,
                    open: _isOpenNote(cellRef, note.id),
                    noteId: note.id,
                    child: _SwipeActions(
                      note: note,
                      enabled: !selectionActive,
                      onPin: () => _swipePin(note),
                      onArchive: () => _swipeArchive(note),
                      child: GestureDetector(
                        onLongPress: () => cellRef
                            .read(selectedNoteIdsProvider.notifier)
                            .toggle(note.id),
                        child: HoldRingArea(
                          icon: Icons.check_rounded,
                          child: NoteListRow(
                            note: note,
                            selected: selected,
                            selectionActive: selectionActive,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      );
    }

    Widget grid(List<Note> section) {
      order.addAll(section);
      // Sürükleme sürerken ızgara ÖNİZLENEN sırayı çizer (bkz.
      // [_startCardDrag]) — kullanıcı notun nereye düşeceğini canlı görür.
      // Uzunluk denetimi: akış sürükleme ortasında yeni bir liste
      // yayınlarsa bayat önizlemeye düşmeyelim.
      final preview = _dragOrder;
      final items =
          (preview != null &&
              preview.length == section.length &&
              _dragNoteId != null &&
              section.any((n) => n.id == _dragNoteId))
          ? preview
          : section;
      // SIRALAMA MODU AYRI BİR IZGARA ÇİZER: eşit yükseklikte kompakt karolar.
      //
      // KÖK NEDEN (kullanıcı: "not sıralama sorunlu, yan yana koyamıyorum,
      // otomatik dizilmeli"): mod normal masonry ızgarayı kullanıyordu ve
      // orada kart yüksekliği içeriğe göre değişir. Masonry her kartı O AN en
      // kısa sütuna atar; iki notu yan yana getirmek, aralarındaki bütün
      // kartların yüksekliklerinin denk gelmesine bağlıydı — kullanıcının
      // seçtiği sıra ile ekranda oluşan yerleşim tutmuyor, kartların arasında
      // koca boşluklar kalıyordu (4. ekran görüntüsü). Eşit karolarda n.
      // sıradaki not HER ZAMAN (n ~/ sütun, n % sütun) hücresine düşer:
      // sürüklerken görülen önizleme ile bırakınca oluşan sıra birebir aynı.
      if (reorderEnabled) {
        return SliverGrid.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: kGridGap,
            crossAxisSpacing: kGridGap,
            mainAxisExtent: _kReorderTileHeight,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final note = items[index];
            final tile = _ReorderTile(note: note, order: index + 1);
            return _ReorderableNoteCell(
              key: ValueKey(note.id),
              noteId: note.id,
              cellWidth: cellWidth,
              inSection: (id) => items.any((n) => n.id == id),
              onDragStart: () => _startCardDrag(note.id, items),
              onHover: () => _previewCardDrop(index),
              onDragEnd: _endCardDrag,
              feedback: SizedBox(
                width: cellWidth,
                height: _kReorderTileHeight,
                child: tile,
              ),
              child: tile,
            );
          },
        );
      }
      // Tek bir kart hücresi. İki yerleşim (deterministik sütunlar ve tembel
      // masonry) AYNI hücreyi kullanır: sürükle-sırala, seçim ve odak vurgusu
      // davranışı ikisinde de birebir aynı kalsın.
      Widget cell(BuildContext context, int index) {
        final note = items[index];
        // Asistanın dokunduğu not: kart kısa süre vurgulanır ve görünür alana
        // kaydırılır (bkz. focusedNoteProvider). Anahtar, kaydırma için
        // kartın bağlamını bulmaya yarar. Hale kartın İÇİNDEN çizilir
        // ([NoteCard.frame]): odak/açık not kartın tek aboneliğinde, hücrede
        // ayrı Consumer yok (F21.4) — vurgu değişince yalnız o kart kurulur.
        final card = _cachedCard(note, searching: searchActive);
        void select() =>
            ref.read(selectedNoteIdsProvider.notifier).toggle(note.id);
        // Olağan hâl: uzun basış toplu seçime girer. SEÇİLİ bir kartta ise
        // İKİNCİ uzun basış sürüklemeyi başlatır (kullanıcı isteği
        // 2026-08-09: "basılı tutup notu seçince, tekrar basılı tutarsak
        // sıralama için sürüklenebilsin") — böylece ayrı bir sıralama moduna
        // girmeden tek not yerinden alınıp taşınabilir. Süzgeç/arama açıkken
        // kapalı: alt kümede taşımak asıl sırayı bozar (⋮ menüsündeki
        // sıralama maddesi de aynı gerekçeyle o hâlde gizleniyor).
        if (!reorderEnabled) {
          // Süzgeç/arama açıkken: uzun basış yalnız seçer (alt kümede taşımak
          // asıl sırayı bozar).
          if (!manualReorderAllowed) {
            return KeyedSubtree(
              key: ValueKey(note.id),
              // Dolum halkası her uzun basışta (2026-11-09: "jestlerde dolum
              // efekti yok" — yalnız elle sıralamada çiziliyordu).
              child: GestureDetector(
                onLongPress: select,
                child: HoldRingArea(icon: Icons.check_rounded, child: card),
              ),
            );
          }
          // BASILI TUT = DOĞRUDAN SÜRÜKLE (kullanıcı isteği 2026-11-08:
          // "dashboarda not üstüne basılı tutunca direkt sürükleyebilmeli ve
          // yerini değiştirebilmeliyim"). Kart oynamadan bırakılırsa uzun
          // basışın eski işi (seçim) yapılır; sıra kaydedilmez.
          if (!selectionActive) {
            return _ReorderableNoteCell(
              key: ValueKey(note.id),
              noteId: note.id,
              cellWidth: cellWidth,
              inSection: (id) => items.any((n) => n.id == id),
              onDragStart: () => _startCardDrag(note.id, items),
              onHover: () => _previewCardDrop(index),
              onDragEnd: () => _endCardDrag(select),
              onDragUpdate: (d) => _dragTravel += d.delta.distance,
              feedback: SizedBox(
                width: cellWidth,
                child: NoteCard(note: note, highlightQuery: query),
              ),
              child: card,
            );
          }
          // Seçim AÇIKKEN her hücre bir BIRAKMA HEDEFİ olur; sürüklemeyi
          // yalnız SEÇİLİ kart başlatır.
          //
          // KÖK NEDEN (kullanıcı bulgusu 2026-08-09: "tekrar basılı tutup
          // sürükleme doğru çalışmıyor"): önce yalnız seçili kart
          // `_ReorderableNoteCell` ile sarılıyordu. `DragTarget` de o
          // sarmalayıcının içinde olduğundan seçilmemiş kartlar hedef
          // DEĞİLDİ — sürüklenen kartı bırakacak yer yoktu, jest hiçbir şey
          // yapmadan bitiyordu. Artık hedef hepsi, sürükleyen seçili olan.
          return KeyedSubtree(
            key: ValueKey(note.id),
            child: Consumer(
              builder: (context, cellRef, _) {
                final isSelected = cellRef.watch(
                  selectedNoteIdsProvider.select((s) => s.contains(note.id)),
                );
                return _ReorderableNoteCell(
                  noteId: note.id,
                  cellWidth: cellWidth,
                  draggable: isSelected,
                  onLongPress: select,
                  inSection: (id) => items.any((n) => n.id == id),
                  onDragStart: () => _startCardDrag(note.id, items),
                  onHover: () => _previewCardDrop(index),
                  onDragEnd: _endCardDrag,
                  feedback: SizedBox(
                    width: cellWidth,
                    child: NoteCard(note: note, highlightQuery: query),
                  ),
                  child: card,
                );
              },
            ),
          );
        }
        return _ReorderableNoteCell(
          key: ValueKey(note.id),
          noteId: note.id,
          cellWidth: cellWidth,
          inSection: (id) => items.any((n) => n.id == id),
          onDragStart: () => _startCardDrag(note.id, items),
          onHover: () => _previewCardDrop(index),
          onDragEnd: _endCardDrag,
          feedback: SizedBox(
            width: cellWidth,
            child: NoteCard(note: note, highlightQuery: query),
          ),
          child: card,
        );
      }

      // TEMBEL deterministik ızgara (bkz. [sliverBalancedNoteColumns]):
      // eskiden bölümün bütün kartları tek kutuda kuruluyordu.
      return sliverBalancedNoteColumns(
        items: items,
        columns: columns,
        cellWidth: cellWidth,
        cell: cell,
      );
    }

    // BÖLÜM BAŞLIĞI uygulamanın TEK bölüm başlığıyla aynı (TUTARLILIK
    // F36.7): cümle düzeni, `SectionLabel` stili. Eskiden büyük harfli
    // anahtarlar ("SABİT", "BU HAFTA") + kendi 12/0,4 aralıklı stiliyle
    // levhalardaki "Düzenle", "Not içeriği" başlıklarından ayrı bir dil
    // konuşuyordu (TERİMLER: "bölüm başlığı cümle düzeninde").
    Widget header(String text, int count) => SliverToBoxAdapter(
      child: HomeSectionHeader(text: text, count: count),
    );

    const gridPadding = EdgeInsets.symmetric(horizontal: kGridInset);

    // Tarih kovaları yalnız "Son düzenlenen" sıralamasında anlamlı: kullanıcı
    // Başlık ya da Renk sıralamasını seçtiyse "BUGÜN" başlığı altındaki sıra
    // tarihe göre olmaz, başlık yalan söyler. O modlarda tek akış kalır.
    //
    // SIRALAMA MODUNDA da kapalı: kartlar yalnız kendi bölümlerinin içinde
    // taşınabiliyor (bkz. `inSection`), yani "BUGÜN" ile "DAHA ÖNCE" arasına
    // hiçbir not geçemezdi — kullanıcı taşımayı deneyip tutmayınca sıralamayı
    // bozuk sanıyordu. Modda tek liste (sabitliler + gerisi) kalır.
    final bucketsActive =
        !reorderEnabled && ref.read(noteSortProvider) == NoteSort.updated;

    // **"TÜMÜ" KLASÖRE GÖRE** (geliştirme raporu D4): klasördeki notlar ana
    // ekrana karıştığı için kartlar klasör başlıkları altında; sıra
    // kullanıcının klasör sırası, klasörsüzler en sonda. Arama sürerken
    // yok (sonuçlar tek akış, kartta klasör rozeti var).
    if (!searchActive &&
        ref.read(showAllNotesProvider) &&
        ref.read(selectedFolderProvider) == null &&
        ref.watch(allNotesGroupByFolderProvider)) {
      final folders = ref.read(visibleOrderedFoldersProvider);
      final byFolder = <String?, List<Note>>{};
      for (final n in others) {
        (byFolder[n.folderId] ??= []).add(n);
      }
      final groups = <(String, List<Note>)>[
        (l10n.sectionPinnedShort, pinned),
        for (final f in folders)
          if (byFolder[f.id] case final list?) (f.name, list),
        // Klasörsüzler + klasörü listede olmayanlar (silinmiş klasör):
        // hiçbir not gruplamada kaybolmasın.
        (
          l10n.archiveNoFolder,
          [
            for (final e in byFolder.entries)
              if (!folders.any((f) => f.id == e.key)) ...e.value,
          ],
        ),
      ];
      return [
        for (final (label, list) in groups)
          if (list.isNotEmpty) ...[
            header(label, list.length),
            SliverPadding(
              padding: gridPadding,
              sliver: listView ? rows(list) : grid(list),
            ),
          ],
      ];
    }

    if (!bucketsActive) {
      if (pinned.isEmpty || others.isEmpty) {
        return [
          ...countHeader,
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          SliverPadding(
            padding: gridPadding,
            sliver: listView ? rows(notes) : grid(notes),
          ),
        ];
      }
      return [
        ...countHeader,
        header(l10n.sectionPinnedShort, pinned.length),
        SliverPadding(
          padding: gridPadding,
          sliver: listView ? rows(pinned) : grid(pinned),
        ),
        header(l10n.sectionOthers, others.length),
        SliverPadding(
          padding: gridPadding,
          sliver: listView ? rows(others) : grid(others),
        ),
      ];
    }

    final buckets = <(String, List<Note>)>[
      (l10n.sectionPinnedShort, pinned),
      for (final (label, list) in dateBuckets(others, DateTime.now()))
        (
          switch (label) {
            NoteBucket.today => l10n.sectionToday,
            NoteBucket.thisWeek => l10n.sectionThisWeek,
            NoteBucket.earlier => l10n.sectionEarlier,
          },
          list,
        ),
    ];

    return [
      ...countHeader,
      // Boş kova hiç çizilmez — başlık tek başına duran bir çizgi olurdu.
      for (final (label, list) in buckets)
        if (list.isNotEmpty) ...[
          header(label, list.length),
          SliverPadding(
            padding: gridPadding,
            sliver: listView ? rows(list) : grid(list),
          ),
        ],
    ];
  }
}

/// Kart, editörde EN ÜSTTE açık not mu? `select`: not değişince yalnız eski
/// ve yeni açık notun hücresi yeniden çizilir (kart önbelleği, F2.1, durur).
bool _isOpenNote(WidgetRef ref, String id) => ref.watch(
  openNoteIdsProvider.select((ids) => ids.isNotEmpty && ids.last == id),
);
