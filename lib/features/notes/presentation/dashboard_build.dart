part of 'dashboard_screen.dart';

/// KÖK NEDEN (aşağı kaydırırken liste yukarı sıçraması, tarihçe): masonry
/// toplam uzunluğu yerleşmiş kartların ortalamasından TAHMİN ediyordu.
/// 2026-10-16: masonry kalktı (tembel deterministik sütunlar) — pay artık
/// yalnız hızlı kaydırma için.
class _GridScrollView extends CustomScrollView {
  const _GridScrollView({
    super.key,
    super.controller,
    super.physics,
    required super.slivers,
    required this.tick,
    required this.narrow,
  });

  final Listenable tick;
  final bool Function() narrow;

  @override
  StatelessElement createElement() => _GridScrollElement(this);

  @override
  Widget buildViewport(
    BuildContext context,
    ViewportOffset offset,
    AxisDirection axisDirection,
    List<Widget> slivers,
  ) => Viewport(
    axisDirection: axisDirection,
    offset: offset,
    slivers: slivers,
    scrollCacheExtent: ScrollCacheExtent.pixels(
      narrow() ? 250 : _kGridCacheExtent,
    ),
  );
}

class _GridScrollElement extends StatelessElement {
  _GridScrollElement(_GridScrollView super.widget);

  // [tick] ekranın ömrü boyunca aynı nesne: güncellemede yeniden bağlanmaz.
  Listenable get _tick => (widget as _GridScrollView).tick;

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    _tick.addListener(markNeedsBuild);
  }

  @override
  void unmount() {
    _tick.removeListener(markNeedsBuild);
    super.unmount();
  }
}

/// Izgaranın altında bırakılan boşluk: sağ alttaki düğme satırı
/// (mikrofon + "+" yan yana, 56 + alt pay 16 = 72, + 24 nefes payı)
/// ızgaranın ÜSTÜNDE yüzüyor. 2026-10-20 (B2): üç düğmeli sütun tek satıra
/// indi, pay 200 → 96.
///
/// KÖK NEDEN (ana sayfa düzeni, 2026-09-23): boşluk 88 px idi — sütun tek bir
/// FAB'ken yazılmış bir değer. Sütun üç düğmeye çıkınca sağ sütunun son
/// kartının alt yarısı listenin en sonuna kaydırıldığında bile düğmelerin
/// ARKASINDA kalıyordu; kartın altındaki metne/tarihe hiç ulaşılamıyordu.


extension _DashboardBuild on _DashboardScreenState {
  Widget _buildDashboardAppBar(
    AppLocalizations l10n, {
    required bool reorderActive,
    required bool selectionActive,
    required List<String> visibleIds,
    required AsyncValue<List<Note>> notesAsync,
    required bool desktopWeb,
    required bool narrowPane,
    required SharedFolderKey? sharedFolder,
    required bool hubActive,
    required String? selectedFolderId,
    required bool hasHiddenFolders,
    required bool hiddenRevealed,
    required bool hasBackground,
  }) {
    // Sıralama modu: kartlar sürüklenebilir. Moddan
    // çıkmadan başka iş yapılamayacağı için üstte kalıcı
    // ve tek düğmeli bir bar durur.
    if (reorderActive) {
      return
      AppBar(
        leading: IconButton(
          tooltip: l10n.reorderDone,
          icon: const Icon(Icons.close),
          onPressed: () => ref
              .read(reorderModeProvider.notifier)
              .set(false),
        ),
        title: Text(l10n.reorderModeActive),
        actions: [
          TextButton(
            onPressed: () => ref
                .read(reorderModeProvider.notifier)
                .set(false),
            child: Text(l10n.reorderDone),
          ),
          const SizedBox(width: 4),
        ],
        // Modun ne beklediği yazılı: kartın kendisi
        // dokununca AÇILMIYOR, uzun basış gerekiyor —
        // yazmadan bunu ancak deneyerek anlamak gerekiyordu.
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(22),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              l10n.reorderHint,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ),
      );
    }
    if (selectionActive) {
      return
      // Seçim kümesinin KENDİSİ yalnız burada gerekiyor;
      // abonelik bu çubuğa hapsedilir (bkz. yukarıdaki
      // `selectionActive` kök nedeni).
      Consumer(
        builder: (context, ref, _) {
          final selectedIds = ref.watch(
            selectedNoteIdsProvider,
          );
          return AppBar(
            leading: IconButton(
              tooltip: l10n.cancel,
              icon: const Icon(Icons.close),
              onPressed: () => ref
                  .read(selectedNoteIdsProvider.notifier)
                  .clear(),
            ),
            title: Text(
              l10n.selectedCount(selectedIds.length),
            ),
            // Kopyala/arşivle/sil ve diğer tüm not işlemleri
            // seçim yapılınca BURADA toplanır (madde 3): sık
            // kullanılanlar simge, gerisi taşma menüsünde.
            actions: [
              // **TÜMÜNÜ SEÇ** — "hepsini arşivle" gibi
              // en olağan toplu iş için notları tek tek
              // işaretlemek gerekiyordu. Kapsam ekranda
              // GÖRÜNEN notlarla sınırlı: süzgeç/arama
              // açıkken ekran dışındakiler seçilmez.
              IconButton(
                tooltip:
                    selectedIds.length == visibleIds.length
                    ? l10n.selectNone
                    : l10n.selectAll,
                icon: Icon(
                  selectedIds.length == visibleIds.length
                      ? Icons.deselect
                      : Icons.select_all,
                ),
                onPressed: () => ref
                    .read(selectedNoteIdsProvider.notifier)
                    .selectAll(visibleIds),
              ),
              IconButton(
                tooltip: l10n.archive,
                icon: const Icon(AppIcons.archive),
                onPressed: () =>
                    _archiveSelected(selectedIds),
              ),
              IconButton(
                tooltip: l10n.copy,
                icon: const Icon(AppIcons.copy),
                onPressed: () => _copySelected(selectedIds),
              ),
              IconButton(
                tooltip: l10n.deleteSelected,
                icon: const Icon(Icons.delete_outline),
                onPressed: () =>
                    _deleteSelected(selectedIds),
              ),
              IconButton(
                tooltip: l10n.moreActions,
                icon: const Icon(Icons.more_vert),
                onPressed: () =>
                    _openSelectionMenu(selectedIds),
              ),
              const SizedBox(width: 4),
            ],
          );
        },
      );
    }
    if (desktopWeb && !narrowPane) {
      return
      Builder(
        builder: (context) {
          final folders = ref.watch(
            visibleOrderedFoldersProvider,
          );
          final desktopTitle = sharedFolder != null
              ? (sharedFolderRefOf(
                      ref,
                      sharedFolder,
                    )?.name ??
                    l10n.sharedHubShort)
              : hubActive
              ? (() {
                  final hub = ref.watch(
                    sharedHubFolderProvider,
                  );
                  return hub.name.isEmpty
                      ? l10n.sharedHubTitle
                      : hub.name;
                })()
              : selectedFolderId != null
              ? ([
                      for (final f in folders)
                        if (f.id == selectedFolderId) f.name,
                    ].firstOrNull ??
                    l10n.foldersTitle)
              : ref.watch(showAllNotesProvider)
              ? l10n.allNotesChip
              : l10n.navNotes;
          final desktopNoteCount =
              (sharedFolder == null && !hubActive)
              ? notesAsync.value?.length
              : null;
          return WebDashboardHeader(
            title: desktopTitle,
            noteCount: desktopNoteCount,
            scrolled: _gridScrolled,
            searchController: _searchController,
            searchFocus: _searchFocus,
            filterButton: const Customizable(
              id: UiItem.homeFilter,
              child: HomeFilterButton(),
            ),
            showGridControls:
                !selectionActive &&
                !reorderActive &&
                sharedFolder == null &&
                !hubActive,
            onOpenMenu: () => unawaited(
              _openHomeMenu(
                hasHiddenFolders: hasHiddenFolders,
                hiddenRevealed: hiddenRevealed,
              ),
            ),
          );
        },
      );
    }
    return       // KÖK NEDEN (kasma): `keyboardOpen`/`searchExpanded`
      // ekranın ANA build'inde okunuyordu. `viewInsets`
      // klavye animasyonunun HER KARESİNDE değişiyor, yani
      // arama kutusuna dokunmak 250 ms boyunca ızgaranın
      // tamamını 15–30 kez yeniden kurduruyordu. Okuma
      // artık yalnız bu çubuğu kapsıyor.
      ListenableBuilder(
        listenable: _searchFocus,
        builder: (context, _) {
          final searchExpanded =
              _searchFocus.hasFocus &&
              _hasSoftKeyboardInset(context) &&
              WindowClass.of(context).width ==
                  WindowWidth.compact;
          final sidebarHasAccount =
              desktopWeb && AppRailScope.visible(context);
          return AppBar(
            // ZEMİN VARKEN SAYDAM (2026-11-25): görsel
            // durum çubuğundan tarih şeridine kesintisiz;
            // arama hapı zaten kendi zeminini taşıyor.
            // Durum çubuğu simgesi temanın parlaklığından
            // (saydam zeminden tahmin edilirse beyaz olur).
            backgroundColor: hasBackground
                ? Colors.transparent
                : null,
            systemOverlayStyle: hasBackground
                ? statusBarOverZemin(context)
                : null,
            // SOLDA GERİ OKU YOK (kullanıcı bulgusu
            // 2026-11-06: kutu bir sağa bir sola
            // kayıyordu). Sol kenar sabit; aramayı
            // bırakma düğmesi sağda, hesap + ⋮'nin yerinde.
            titleSpacing: 12,
            automaticallyImplyLeading: false,
            // Satırı UÇTAN UCA doldurur (kullanıcı bulgusu
            // 2026-11-09: "webte arama alanının sağında
            // ölü boşluk"): F44.4'ün 720 dp tavanı ve
            // sağdaki fazladan 12 dp kaldırıldı — iki
            // kenar da titleSpacing (12).
            title: SizedBox(
              width: double.infinity,
              child: _SearchField(
                compact: narrowPane,
                showFilterInCompact: sidebarHasAccount,
                controller: _searchController,
                focusNode: _searchFocus,
                // HESAP SİMGESİ ve ⋮ ARTIK KUTUNUN İÇİNDE
                // (kullanıcı isteği 2026-11-06: "üst
                // arama çubuğu profil ve 3 noktayı da
                // kapsasın"). Hesap kişiselleştirmede
                // gizlenebilir (Customizable); ⋮ alt
                // levhayı açar (bkz. [ActionMenu]).
                // Gelen/paylaşılan sayısı avatar
                // rozetinde (F11.1).
                trailing: searchExpanded
                    ? [
                        // TextFieldTapRegion: basış
                        // "alan dışı" sayılırsa odak
                        // pointer-down'da düşer, düğme
                        // kaybolur, dokunuş kutuya geçip
                        // klavyeyi GERİ açardı (bulgu
                        // 2026-11-06).
                        TextFieldTapRegion(
                        child: IconButton(
                          key: const ValueKey(
                            'search-done',
                          ),
                          tooltip: l10n.close,
                          visualDensity:
                              VisualDensity.compact,
                          icon: const Icon(
                            Icons.keyboard_hide_outlined,
                          ),
                          onPressed: _searchFocus.unfocus,
                        ),
                        ),
                      ]
                    : [
                        if (!sidebarHasAccount)
                          const Customizable(
                            id: UiItem.homeAccount,
                            child: AccountAvatarButton(),
                          ),
                        IconButton(
                          tooltip: l10n.more,
                          visualDensity:
                              VisualDensity.compact,
                          icon: const Icon(
                            Icons.more_vert,
                          ),
                          onPressed: () => unawaited(
                            _openHomeMenu(
                              hasHiddenFolders:
                                  hasHiddenFolders,
                              hiddenRevealed:
                                  hiddenRevealed,
                            ),
                          ),
                        ),
                      ],
              ),
            ),
          );
        },
      );
  }

  List<Widget> _buildDashboardGridSlivers(
    BuildContext context, {
    required bool searchActive,
    required bool reorderActive,
    required bool selectionActive,
    required bool hubActive,
    required SharedFolderKey? sharedFolder,
    required bool sharedAtBottom,
    required int columns,
    required double cellWidth,
    required String? selectedFolderId,
    required String query,
    required AsyncValue<List<Note>> notesAsync,
    required double navInset,
  }) => [
                                      // BENİMLE PAYLAŞILANLAR (seçenek,
                                      // varsayılan kapalı — bkz.
                                      // homeShowSharedProvider): kök
                                      // görünümde, kendi notlarımın üstünde.
                                      if (!searchActive &&
                                          !reorderActive &&
                                          !selectionActive &&
                                          !hubActive &&
                                          sharedFolder == null &&
                                          !sharedAtBottom &&
                                          ref.watch(homeShowSharedProvider) &&
                                          ref.watch(noteFilterProvider) ==
                                              NoteFilter.all &&
                                          ref.watch(selectedTagProvider) ==
                                              null &&
                                          ref.watch(selectedFolderProvider) ==
                                              null)
                                        SharedNotesHomeSection(
                                          columns: columns,
                                          cellWidth: cellWidth,
                                        ),
                                      if (sharedFolder == null &&
                                          !hubActive &&
                                          selectedFolderId != null)
                                        SliverToBoxAdapter(
                                          child: FolderHeaderPanel(
                                            onCreateNote: () => unawaited(
                                              createNote(NoteType.text),
                                            ),
                                          ),
                                        ),
                                      if (sharedFolder != null)
                                        ...sharedFolderSlivers(
                                          context,
                                          ref,
                                          folder: sharedFolder,
                                          columns: columns,
                                          cellWidth: cellWidth,
                                          query: query,
                                        )
                                      else if (hubActive)
                                        ..._hubSlivers(
                                          context,
                                          columns,
                                          cellWidth,
                                          query: query,
                                        )
                                      else
                                      ...notesAsync.when(
                                        data: (notes) => [
                                          ..._afterSkeleton(),
                                          // Aynı sarmalayıcı (ve anahtar)
                                          // özette de var: kartlar yeniden
                                          // kurulmaz (F25.2). Anahtarda arama
                                          // durumu (P60, bütçe S21): arama
                                          // başlayınca kart yapısı değişir;
                                          // eski liste yeniden KURULMAZ, atılır
                                          // — yoksa 1600 px paydaki canlı
                                          // kartların hepsi kurulup aynı
                                          // karede dar payla çöpe gidiyordu.
                                          for (final (i, sliver)
                                              in _buildNoteSlivers(
                                                context,
                                                notes,
                                                columns,
                                                cellWidth: cellWidth,
                                                selectionActive:
                                                    selectionActive,
                                                searchActive: searchActive,
                                                reorderEnabled: reorderActive,
                                              ).indexed)
                                            SliverIgnorePointer(
                                              key: ValueKey(
                                                ('notlar', i, searchActive),
                                              ),
                                              ignoring: false,
                                              sliver: SliverRevealFade(
                                                play: _skeletonShown,
                                                sliver: sliver,
                                              ),
                                            ),
                                        ],
                                        // Yüklenirken diskteki özet, dokunuşa
                                        // kapalı (F25.2, home_snapshot.dart);
                                        // yoksa kart İSKELETİ (skeleton.dart).
                                        loading: () {
                                          final snapshot =
                                              _isDefaultHome(
                                                searchActive: searchActive,
                                              )
                                              ? ref.watch(homeSnapshotProvider)
                                              : const <Note>[];
                                          if (snapshot.isEmpty) {
                                            _skeletonShown = true;
                                            return [
                                              SliverToBoxAdapter(
                                                child: NoteGridSkeleton(
                                                  columns: columns,
                                                ),
                                              ),
                                            ];
                                          }
                                          return [
                                            for (final (i, sliver)
                                                in _buildNoteSlivers(
                                                  context,
                                                  snapshot,
                                                  columns,
                                                  cellWidth: cellWidth,
                                                  selectionActive: false,
                                                  searchActive: false,
                                                  reorderEnabled: false,
                                                ).indexed)
                                              SliverIgnorePointer(
                                                key: ValueKey(
                                                  ('notlar', i, false),
                                                ),
                                                sliver: SliverRevealFade(
                                                  play: false,
                                                  sliver: sliver,
                                                ),
                                              ),
                                          ];
                                        },
                                        error: (e, _) => [
                                          SliverFillRemaining(
                                            hasScrollBody: false,
                                            child: ErrorState(error: e),
                                          ),
                                        ],
                                      ),
                                      // Paylaşılanlar ALTTA seçildiyse
                                      // (bkz. homeSharedAtBottomProvider).
                                      if (!searchActive &&
                                          !reorderActive &&
                                          !selectionActive &&
                                          !hubActive &&
                                          sharedFolder == null &&
                                          sharedAtBottom &&
                                          ref.watch(homeShowSharedProvider) &&
                                          ref.watch(noteFilterProvider) ==
                                              NoteFilter.all &&
                                          ref.watch(selectedTagProvider) ==
                                              null &&
                                          ref.watch(selectedFolderProvider) ==
                                              null)
                                        SharedNotesHomeSection(
                                          columns: columns,
                                          cellWidth: cellWidth,
                                        ),
                                      // Listenin sonu düğme sütununun
                                      // ÜSTÜNE çıkabilsin (bkz.
                                      // [_kFabClearance]).
                                      SliverToBoxAdapter(
                                        child: SizedBox(
                                          height: _kFabClearance + navInset,
                                        ),
                                      ),
  ];

  List<Widget> _buildDashboardFloatingOverlays(
    AppLocalizations l10n, {
    required double navInset,
    required bool selectionActive,
    required SharedFolderKey? sharedFolder,
  }) => [
                // Sesli asistan paneli düğmelerin ÜSTÜnde sabit konumda yüzer.
                // Düğmeler floatingActionButton'da kaldığından panel açılıp
                // kapanırken yerinden oynamaz (stabil); yalnız kayıt/işleme/
                // sonuç sırasında görünür, ana sayfanın ortasına yakın.
                // Asistan paneli, "not silindi" bildirimiyle aynı yerleşimi
                // kullanır: düğmelerin ÜSTÜnde değil SOLUNDA, ekranın dibinde.
                // Sağda düğme sütunu kadar boşluk bırakılır.
                PositionedDirectional(
                  start: 8,
                  end: 144,
                  bottom: 16 + navInset,
                  child: const VoiceAssistantPanel(),
                ),
                // SÜRÜKLERKEN ÇÖP KUTUSU (F60.S9): HEP ağaçta, yalnız
                // boyamada belirir — sürükleme başlayınca ağaç şekli
                // değişmez (kasma listesi 4, 6).
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 16 + navInset,
                  child: Center(
                    child: DragTrashTarget(
                      active: _dragNoteId != null,
                      onTrash: _trashDraggedNote,
                    ),
                  ),
                ),
                // ✨ YAPAY ZEKÂ DÜĞMESİ KALKTI (geliştirme raporu B2,
                // 2026-10-20): mikrofon + ✨ + "+" üç ayrı yüzen düğme sağ
                // alttaki kartın yarısını örtüyordu. Yapay Zekâ ⋮ menüsünün
                // hızlı satırında ilk sırada; AI ile sesli not mikrofona basılı
                // tutunca açılır (değişmedi).
                // Düğmeler Scaffold.floatingActionButton yerine BURADA durur:
                // Scaffold bir FAB tanıdığında yüzen bildirimleri ("not
                // silindi") onun ÜSTÜne iter. Düğmeler Stack'te olunca
                // bildirim ekranın dibinde, düğmelerin solunda kalır.
                // YÖNE BAĞLI: sabit `right` sağdan sola dillerde düğmeleri
                // sağda bırakıyor, asistan paneli ise (end: 88) SOLDA yer
                // ayırıyordu — panel düğmelerin üstüne biniyordu.
                // KLASÖR DÜĞMESİ KALKTI (kullanıcı isteği 2026-11-09: "sol
                // alttaki klasörler butonunu kaldır"). Klasör menüsü liste
                // tepedeyken aşağı çekişle ve yan çubuktan açılır.
                PositionedDirectional(
                  end: 16,
                  bottom: 16 + navInset,
                  // DAR LİSTE BÖLMESİNDE ↑ "+"nın SOLUNDA (KT-17, tablet turu
                  // 2026-11-18): üstte dururken yığın 16 + 56 + 10 + 40 =
                  // 122 dp, listenin alt boşluğu ([_kFabClearance]) 96 dp —
                  // listenin sonunda bile son kartın tarih satırı ↑'nın
                  // arkasında kalıyordu. Dar bölmede mikrofon ve ⚡ gizli,
                  // satırda yer var. Aynı `Flex`, yalnız yön değişir: alt
                  // ağaç (FAB'lar, "+" menüsü) yeniden kurulmaz.
                  // Ray durumunu da bu kurucu okur (eskiden ayrı `Builder`):
                  // kurulum sayısı aynı kalır (bütçe S23/S24).
                  child: ValueListenableBuilder<bool>(
                    valueListenable: _narrowPaneN,
                    builder: (context, narrow, _) => Flex(
                    direction: narrow ? Axis.horizontal : Axis.vertical,
                    mainAxisSize: MainAxisSize.min,
                    // "Başa dön" "+"nın tam üstünde: sağa dayalı, küçük
                    // düğme (40) "+"nın (56) ortasına 8 dp payla oturur.
                    // Dar bölmede satırda, ortalı.
                    crossAxisAlignment: narrow
                        ? CrossAxisAlignment.center
                        : CrossAxisAlignment.end,
                    spacing: narrow ? 8 : 10,
                    children: [
                      // **BAŞA DÖN** — yüz notluk bir kitaplıkta en alta
                      // inen kullanıcının tepeye (ve arama kutusuna)
                      // dönmesinin tek yolu aynı yolu geri kaydırmaktı.
                      // Yalnız gerçekten aşağıdayken çıkar; seçim/sıralama
                      // kipinde çıkmaz (o çubuklar zaten sayfayı yönetir).
                      AnimatedSlide(
                        offset: _showBackToTop && !selectionActive
                            ? Offset.zero
                            : const Offset(0, 0.6),
                        duration: const Duration(milliseconds: 180),
                        child: AnimatedOpacity(
                          opacity: _showBackToTop && !selectionActive ? 1 : 0,
                          duration: const Duration(milliseconds: 180),
                          child: IgnorePointer(
                            ignoring: !_showBackToTop || selectionActive,
                            child: Padding(
                              padding: EdgeInsetsDirectional.only(
                                end: narrow ? 0 : 8,
                              ),
                              child: FloatingActionButton.small(
                                heroTag: 'backToTop',
                                tooltip: l10n.scrollToTop,
                                onPressed: _backToTop,
                                child: const Icon(Icons.arrow_upward),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // MİKROFON "+"nın SOLUNDA, aynı satırda (B2): sütun
                      // eskiden iki düğme boyu yükseliyor ve sağ sütunun
                      // son kartını örtüyordu; tek satır 56 dp.
                      //
                      // Ray görünürken kapılar rayda (K3, F44.1).
                      AppRailScope.visible(context)
                            ? const SizedBox.shrink()
                            : sharedFolder != null
                            ? SharedFolderFab(folder: sharedFolder)
                            : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ⚡ HIZLI EKLE (kullanıcı isteği 2026-11-16) —
                          // TEK ÖRNEK: ana ekran kurulsa da kurulmaz.
                          _quickDropFab,
                          // TEK MİKROFON (F3.1) = DOĞRUDAN YAZDIR (kullanıcı
                          // isteği 2026-10-20: "AI sesli notu AI menüsüne
                          // alalım, ana ekrandaki doğrudan yazma olsun").
                          // Eskiden dokunuş SON kullanılan kipi açıyordu; aynı
                          // düğmenin bir gün AI levhası, bir gün dikte açması
                          // tahmin edilemezdi. AI ile sesli not Yapay Zekâ
                          // ekranının en üstünde; basılı tutmak kısayol olarak
                          // onu açar.
                          ValueListenableBuilder<bool>(
                            valueListenable: _narrowPaneN,
                            builder: (_, narrow, mic) =>
                                Offstage(offstage: narrow, child: mic),
                            child: Customizable(
                            id: UiItem.homeMic,
                            child: Padding(
                              padding: const EdgeInsetsDirectional.only(end: 12),
                              child: _DashVoiceButton(
                                key: const ValueKey('home-mic'),
                                tooltip: l10n.voiceMicTooltipDictate,
                                icon: AppIcons.dictation,
                                onTap: _dictateNote,
                                onLongPress: _captureVoiceNote,
                              ),
                            ),
                          ),
                          ),
                          // Keep tarzı açılan "+": metin/madde/sıralı/el yazısı.
                          // Dört kapılı "+" (F3.2). Sesli not menüde YOK:
                          // ana ekranın kendi tek mikrofonu var (F3.1).
                          // "+" menüsü YALNIZ "+"ya demirlenir: mikrofon
                          // yanında, menü onun üstüne inmez.
                          CompositedTransformTarget(
                            link: _fabColumnLink,
                            child: QuickAddFab(
                              anchor: _fabColumnLink,
                              actions: () => this,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  ),
                ),
  ];
}
