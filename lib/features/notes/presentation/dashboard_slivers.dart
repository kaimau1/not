part of 'dashboard_screen.dart';

/// Not ızgarasının dilimleri: bölümler, boş durum, sürükleyerek sıralama (C1).
extension _DashSlivers on _DashboardScreenState {
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
    if (notes.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: searchActive
              ? EmptyState(
                  icon: Icons.search_off,
                  title: l10n.emptySearch,
                  // Aramada sonuç yoksa anlamsal aramayı hatırlat: kelimesi
                  // geçmeyen ama konusu tutan not orada bulunuyor.
                  subtitle: ref.read(semanticSearchEnabledProvider)
                      ? null
                      : l10n.emptySearchSemanticHint,
                )
              : EmptyState(
                  icon: Icons.sticky_note_2_outlined,
                  title: l10n.emptyNotes,
                  subtitle: l10n.emptyNotesHint,
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
        !ref.read(showAllNotesProvider) &&
        ref.read(selectedTagProvider) == null;

    /// Liste görünümü: tek sütun, kompakt satır. Sürükle-sırala BURADA yok —
    /// o mod ızgaraya özgü (hücre genişliğiyle çalışıyor); liste görünümünde
    /// ⋮ menüsündeki sıralama maddesi zaten görünmüyor.
    Widget rows(List<Note> items) => SliverList.separated(
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
                      child: NoteListRow(
                        note: note,
                        selected: selected,
                        selectionActive: selectionActive,
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

    Widget grid(List<Note> section) {
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
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
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
        // kartın bağlamını bulmaya yarar. Consumer + select: vurgu değişince
        // tüm dashboard değil yalnız ilgili hücre yeniden çizilir.
        final card = Consumer(
          builder: (context, cellRef, _) {
            final focused = cellRef.watch(
              focusedNoteProvider.select((id) => id == note.id),
            );
            return _FocusHalo(
              focused: focused,
              noteId: note.id,
              child: _cachedCard(note, query),
            );
          },
        );
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
          // Seçim KAPALIYKEN sade davranış: uzun basış seçer.
          if (!selectionActive || !manualReorderAllowed) {
            return KeyedSubtree(
              key: ValueKey(note.id),
              child: GestureDetector(onLongPress: select, child: card),
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

    // Başlık metni ZATEN büyük harfli anahtarlardan gelir; kodda
    // `toUpperCase()` çağırmıyoruz — Türkçe'de "Etiket" → "ETIKET" olur
    // (noktasız I), Dart'ın büyük harfe çevirmesi yerel ayar tanımıyor.
    Widget header(String text, int count) => SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
        child: Row(
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Divider(
                height: 1,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              l10n.sectionNoteCount(count),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );

    const gridPadding = EdgeInsets.symmetric(horizontal: 12);

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
