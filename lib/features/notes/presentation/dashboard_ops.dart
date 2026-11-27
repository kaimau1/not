part of 'dashboard_screen.dart';

extension _DashboardOps on _DashboardScreenState {
  /// [searching] ızgaranın GECİKTİRİLMİŞ arama durumudur (hücre sarmalayıcısı
  /// da onunla değişir): anlık sorguyla kurulunca ilk harfte kartlar iki kez
  /// kuruluyordu — önce tuşta, sonra gecikme dolup sarmalayıcı değişince
  /// (P46, bütçe S21: harf başına 114 → 57).
  Widget _cachedCard(
    Note note, {
    required bool searching,
    DateTime? calendarDay,
  }) {
    final hit = _cardCache[note.id];
    if (hit != null &&
        identical(hit.$1, note) &&
        hit.$2 == searching &&
        hit.$3 == calendarDay) {
      return hit.$4;
    }
    final card = NoteCard(
      note: note,
      calendarDay: calendarDay,
      liveQuery: searching ? _liveQuery : null,
      frame: (child, {required focused, required open}) => _FocusHalo(
        focused: focused,
        open: open,
        noteId: note.id,
        child: child,
      ),
    );
    _cardCache[note.id] = (note, searching, calendarDay, card);
    return card;
  }

  void _holdNarrowCache(String segmentKey) {
    _freshSegment = segmentKey;
    _cacheWiden?.cancel();
    _cacheWiden = Timer(AppMotion.medium + AppMotion.short, () {
      _freshSegment = null;
      _cacheTick.value++;
    });
  }

  /// Silinmiş/ekrandan çıkmış notların kartlarını önbellekten düşürür.
  void _pruneCardCache(List<Note> visible) {
    if (_cardCache.length <= visible.length + 32) return;
    final ids = {for (final n in visible) n.id};
    _cardCache.removeWhere((id, _) => !ids.contains(id));
  }

  /// Ana ekranın süzgeçsiz hâli mi: özet yalnız bu görünümün karşılığı (F25.2).
  bool _isDefaultHome({required bool searchActive}) =>
      !searchActive &&
      ref.read(noteFilterProvider) == NoteFilter.all &&
      ref.read(selectedTagProvider) == null &&
      ref.read(selectedFolderProvider) == null &&
      ref.read(selectedSharedFolderProvider) == null;

  /// Ana ekran mikrofon widget'ının isteği varsa sesli not levhasını açar
  /// (tek seferlik — bayrak take ile tüketilir).
  void _maybeAutostartVoice() {
    if (!mounted) return;
    // Widget/kısayol da ana ekran mikrofonuyla AYNI levhayı açar (eskiden
    // ayrı bir asistan kaydı başlatıyordu — sadeleştirme 2026-10-19).
    if (ref.read(voiceAutostartProvider.notifier).take()) {
      unawaited(_captureVoiceNote());
    }
  }

  /// HE-3: uygulama dışından (`notlar://ekle`) gelen hızlı ekle isteği —
  /// levha gelen metinle açılır (tek seferlik, [quickDropRequestProvider]).
  void _maybeOpenQuickDrop() {
    if (!mounted) return;
    final text = ref.read(quickDropRequestProvider.notifier).take();
    if (text != null) unawaited(showQuickDropSheet(context, text: text));
  }

  ///
  /// YALNIZ TEPEDE BAŞLAYAN SÜRÜKLEME (KT-22, tablet turu 2026-11-18):
  /// aşağıdan başlayıp tepeye çarpan uzun bir kaydırmanın kalan aşırı
  /// kaydırması da çekiş sayılıyor, listeyi başa alan kullanıcıya klasör
  /// menüsü açılıp sonraki dokunuşu yutuyordu. Yenile-çek gibi: parmak
  /// liste ZATEN tepedeyken değdiyse çekiş kurulur ([_pullArmed]).
  void _trackFolderPull(ScrollNotification n) {
    final m = n.metrics;
    if (n is ScrollStartNotification) {
      _pullArmed = m.pixels <= m.minScrollExtent + 1;
    }
    var pull = _folderPull.value;
    if (n is OverscrollNotification) {
      if (n.dragDetails != null &&
          n.overscroll < 0 &&
          _pullArmed &&
          _pullGestureAllowed()) {
        pull -= n.overscroll;
      }
    } else if (n is ScrollUpdateNotification) {
      if (n.dragDetails == null) {
        pull = 0;
      } else if (m.pixels < m.minScrollExtent) {
        pull = _pullArmed && _pullGestureAllowed()
            ? m.minScrollExtent - m.pixels
            : 0;
      } else if (pull > 0) {
        // Çekip geri itti: mesafe azalır.
        pull = (pull - (n.scrollDelta ?? 0)).clamp(0, double.infinity);
      }
    } else if (n is ScrollEndNotification) {
      final open = pull >= _DashboardScreenState._kFolderPullDistance;
      _setFolderPull(0);
      if (open) _runHomeGesture(ref.read(homePullGestureProvider));
      return;
    }
    _setFolderPull(pull);
  }

  void _setFolderPull(double pull) {
    final before =
        _folderPull.value >= _DashboardScreenState._kFolderPullDistance;
    final after = pull >= _DashboardScreenState._kFolderPullDistance;
    if (after && !before) unawaited(AppHaptics.tick());
    if (_folderPull.value != pull) _folderPull.value = pull;
  }

  /// Klasör düğmesinin görünmediği kiplerde (seçim, paylaşılan klasör,
  /// arama, sıralama, kart sürükleme) çekiş menü açmaz.
  bool _folderPullAllowed() =>
      ref.read(selectedNoteIdsProvider).isEmpty &&
      !ref.read(reorderModeProvider) &&
      _dragNoteId == null &&
      ref.read(selectedSharedFolderProvider) == null &&
      ref.read(searchQueryProvider).trim().isEmpty;

  /// Aşağı çekiş göstergesi yalnız jestin bir hedefi varken (U1).
  bool _pullGestureAllowed() =>
      _folderPullAllowed() &&
      ref.read(homePullGestureProvider).kind != HomeGestureKind.none;

  /// **JEST HEDEFİ** (U1, kullanıcı isteği 2026-11-18): üstten çekiş ve
  /// Tümü'de sağa çekiş Ayarlar → Notlar'da seçilen yere gider. Hedef not ya
  /// da klasör silinmişse kısa bir uyarı (sessiz kalmaz).
  void _runHomeGesture(HomeGestureTarget target, {bool fromSwipe = false}) {
    if (!mounted) return;
    switch (target.kind) {
      case HomeGestureKind.none:
        return;
      case HomeGestureKind.folders:
        _openFolderMenu();
      case HomeGestureKind.calendar:
        AppHaptics.tick();
        unawaited(
          context.push(fromSwipe ? '/calendar?from=swipe' : '/calendar'),
        );
      case HomeGestureKind.note:
        final note = _gestureNote(target.id);
        if (note == null) {
          showQuickAddSnack(context.l10n.homeGestureMissing);
          return;
        }
        AppHaptics.tick();
        unawaited(openNoteRoute(context, note));
      case HomeGestureKind.folder:
        final name = _gestureFolderName(target.id);
        if (name == null) {
          showQuickAddSnack(context.l10n.homeGestureMissing);
          return;
        }
        _selectFolderFromHold(target.id);
    }
  }

  Note? _gestureNote(String? id) =>
      (ref.read(notesStreamProvider).value ?? const <Note>[])
          .where((n) => n.id == id && n.deletedAt == null)
          .firstOrNull;

  String? _gestureFolderName(String? id) => ref
      .read(visibleOrderedFoldersProvider)
      .where((f) => f.id == id)
      .firstOrNull
      ?.name;

  /// Çekiş kenarında görünen hedef adı (F39.3 etiketiyle aynı yer).
  String? _gestureLabel(HomeGestureTarget target) {
    final l10n = context.l10n;
    return switch (target.kind) {
      HomeGestureKind.none => null,
      HomeGestureKind.folders => l10n.homeGestureFolders,
      HomeGestureKind.calendar => l10n.calendarTitle,
      HomeGestureKind.note => switch (_gestureNote(target.id)) {
        final n? => noteLinkLabel(n, l10n.remindersUntitled),
        null => null,
      },
      HomeGestureKind.folder => _gestureFolderName(target.id),
    };
  }

  void _openFolderMenu() {
    if (!mounted || !_folderPullAllowed()) return;
    unawaited(
      openFolderMenu(
        context,
        stops: _folderStops(ref),
        currentId: _currentStopId(ref),
        onOpen: () => unawaited(context.push('/folders')),
        onSelect: _selectFolderFromHold,
        // Ekle / sırala · sil menünün içinden; iş bitince menü yeniden açılır
        // (kullanıcı o ekranda kalır, yeni sıra/klasör hemen görünür).
        onNewFolder: () => unawaited(
          showFolderEditorDialog(context, ref).then((_) => _openFolderMenu()),
        ),
        onEditFolders: () => unawaited(
          showFolderOrderSheet(context).then((_) => _openFolderMenu()),
        ),
      ),
    );
  }

  /// Telefon ↔ geniş ekran geçişinde (F18.11) önceki örneğin kaldığı yere
  /// döner — yalnız AYNI bölümdeyse. İçerik henüz ölçülmediyse bir kare daha
  /// beklenir (en çok birkaç kez).
  void _restoreScroll([int tries = 0, double? lastExtent]) {
    if (!mounted || !_gridScroll.hasClients) return;
    final positions = _gridScroll.positions.toList();
    if (positions.length != 1) return;
    final p = positions.single;
    final extent = p.maxScrollExtent;
    final target = DashboardScrollMemory.restoreOffset(_segmentKey, extent);
    if (target == null) return;
    p.jumpTo(target.clamp(0.0, extent));
    // KÖK NEDEN (cihaz turu 2026-11-05, telefonu çevirince liste tepeye
    // atlıyordu): tembel listede maxScrollExtent ilk karelerde yalnız kurulan
    // kartlardan TAHMİN; oran o küçük tahmine uygulanınca liste başa yakın
    // kalıyordu. Tahmin oturana dek aynı oran yeniden uygulanır.
    if (tries < 8 && extent != lastExtent) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _restoreScroll(tries + 1, extent),
      );
    }
  }

  /// [noteId]'nin kartı kuruluysa (kaydırma önbelleğinde) görünür alana
  /// kaydırır. Kartlar `ValueKey(note.id)` ile sarılı (dashboard_slivers).
  Element? _cardElement(String noteId) {
    final key = ValueKey(noteId);
    Element? found;
    void visit(Element e) {
      if (found != null) return;
      if (e.widget.key == key) {
        found = e;
        return;
      }
      e.visitChildren(visit);
    }

    context.visitChildElements(visit);
    return found;
  }

  /// Odaklanan notun kartı TEMBEL listede henüz kurulmadıysa (kaydırma
  /// payının dışında) `_FocusHalo` kendini kaydıramaz: liste, notun görünür
  /// sıradaki yerine ORANLA atlatılır; kart kurulunca hale kendini ortalar.
  /// Not görünümde yoksa (başka klasör/süzgeç dışı) sessizce hiçbir şey.
  void _revealFocused(String noteId, [int tries = 0]) {
    if (!mounted || !_gridScroll.hasClients || tries > 6) return;
    if (ref.read(focusedNoteProvider) != noteId) return;
    if (_cardElement(noteId) != null) return;
    final notes = ref.read(filteredNotesProvider).value ?? const <Note>[];
    final i = notes.indexWhere((n) => n.id == noteId);
    final positions = _gridScroll.positions.toList();
    if (i < 0 || positions.length != 1) return;
    final p = positions.single;
    // ponytail: oran tahmini (bölüm/sütun dağılımı yok sayılır); tembel
    // uzunluk tahmini oturdukça birkaç karede düzelir.
    p.jumpTo(
      (p.maxScrollExtent * i / math.max(1, notes.length - 1)).clamp(
        0.0,
        p.maxScrollExtent,
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _revealFocused(noteId, tries + 1),
    );
  }

  void _revealCard(String noteId) {
    if (!mounted) return;
    final card = _cardElement(noteId);
    if (card == null) return;
    Scrollable.ensureVisible(
      card,
      alignment: 0.3,
      duration: AppMotion.medium,
      curve: AppMotion.emphasized,
    );
  }

  /// Izgarayı tepeye döndürür. `animateTo` birden çok konumla çalışır
  /// (bkz. [_gridScroll]).
  /// Geniş ekranda sağda açık not varsa kapatıp `/`'a döner (🏠 şeridi).
  bool _closeOpenNote() {
    final router = GoRouter.of(context);
    if (!isNoteLocation(currentLocation(router))) return false;
    goHome(ref, router);
    return true;
  }

  void _backToTop() {
    if (!_gridScroll.hasClients) return;
    _gridScroll.animateTo(
      0,
      duration: const Duration(milliseconds: 320),
      curve: AppMotion.emphasized,
    );
  }

  Future<void> _toggleHiddenFolders() async {
    final l10n = context.l10n;
    final revealed = ref.read(hiddenFoldersRevealedProvider);
    if (revealed) {
      ref.read(hiddenFoldersRevealedProvider.notifier).set(false);
      // Gizli bir klasör o an seçiliyse süzgeç bırakılır; aksi hâlde ekran
      // artık ulaşılamayan bir klasörde boş kalırdı.
      final selected = ref.read(selectedFolderProvider);
      if (selected != null &&
          ref.read(hiddenFolderIdsProvider).contains(selected)) {
        ref.read(selectedFolderProvider.notifier).set(null);
      }
      if (!mounted) return;
      showQuickAddSnack(l10n.hiddenFoldersHiddenAgain);
      return;
    }
    if (!await authenticateForNote(l10n.hiddenFolderAuthReason)) return;
    ref.read(hiddenFoldersRevealedProvider.notifier).set(true);
    if (!mounted) return;
    showQuickAddSnack(l10n.hiddenFoldersShown);
  }
  // Sıralama seçici alt sayfası (_pickSort) kaldırıldı: sıralama artık Süz
  // levhasının SIRALAMA bölümünde, süzgeçlerle aynı yerde.

  /// Ana ekranı yatay çekince (madde 1) aktif görünümü sonraki/önceki
  /// durağa taşır: Tümü → notu olan durum süzgeçleri → etiketler. [direction]
  /// +1 sonraki, -1 önceki. Durakların kuralı saf bir işlevde ve ölçülüyor
  /// (bkz. [nextSwipeStop]).
  ///
  /// **KLASÖRLER GEZİDE** (kullanıcı isteği 2026-09-26: "sağ sol
  /// kaydırmada klasörler arası geçiş"). 2026-08-18'de çıkarılmışlardı;
  /// neyin gezileceği artık Ayarlar → Notlar'da seçiliyor (bkz. [SwipeMode],
  /// varsayılan: klasörler). Sıra, kullanıcının klasör sırasıdır (bkz.
  /// `visibleOrderedFoldersProvider`).
  /// Tümü görünümünde sağa çekiş (geri yön) takvimi açar (2026-11-06).
  bool _swipeOpensCalendar(int direction) => swipeOpensCalendar(
    enabled:
        ref.read(homeSwipeRightGestureProvider).kind != HomeGestureKind.none,
    direction: direction,
    atAllNotes:
        ref.read(selectedFolderProvider) == null &&
        ref.read(selectedSharedFolderProvider) == null &&
        !ref.read(sharedHubOnHomeProvider) &&
        ref.read(selectedTagProvider) == null &&
        ref.read(noteFilterProvider) == NoteFilter.all,
  );

  void _cycleFilterFolder(int direction) {
    if (_swipeOpensCalendar(direction)) {
      _runHomeGesture(
        ref.read(homeSwipeRightGestureProvider),
        fromSwipe: true,
      );
      return;
    }
    final stop = _swipeStop(direction);
    if (stop == null) return;
    // Geçiş animasyonunun yönünü çekiş yönüne göre ayarla (madde 2).
    _swipeForward = direction > 0;
    // Paylaşılan klasör de bir durak (K8), kendi klasör gibi.
    final sharedStop = _sharedStopOf(stop.folderId);
    if (sharedStop != null) {
      openFolder(context, sharedStop.folderId, ownerId: sharedStop.ownerId);
      AppHaptics.tick();
      return;
    }
    ref.read(selectedSharedFolderProvider.notifier).set(null);
    if (stop.folderId == kSharedHubFolderId) {
      showSharedHubOnHome(context, toggle: false);
      AppHaptics.tick();
      return;
    }
    ref.read(sharedHubOnHomeProvider.notifier).set(false);
    ref.read(selectedFolderProvider.notifier).set(stop.folderId);
    ref.read(noteFilterProvider.notifier).set(stop.filter);
    ref.read(selectedTagProvider.notifier).set(stop.tag);
    AppHaptics.tick();
  }

  /// Klasör düğmesinden seçim: süzgeçsiz o klasör (Tümü = null).
  void _selectFolderFromHold(String? folderId) {
    _swipeForward = true;
    if (folderId == kSharedHubFolderId) {
      showSharedHubOnHome(context, toggle: false);
      AppHaptics.tick();
      return;
    }
    ref.read(selectedSharedFolderProvider.notifier).set(null);
    ref.read(sharedHubOnHomeProvider.notifier).set(false);
    ref.read(selectedFolderProvider.notifier).set(folderId);
    ref.read(noteFilterProvider.notifier).set(NoteFilter.all);
    ref.read(selectedTagProvider.notifier).set(null);
    AppHaptics.tick();
  }

  SharedFolderRef? _sharedStopOf(String? stopId) => stopId == null
      ? null
      : (ref.read(sharedFolderRefsProvider).value ?? const <SharedFolderRef>[])
            .where((s) => sharedFolderStopId(s) == stopId)
            .firstOrNull;

  /// Çekişin kenarında görünen sonraki durağın adı (F39.3); durak yoksa null.
  String? _swipeStopLabel(int direction) {
    if (_swipeOpensCalendar(direction)) {
      return _gestureLabel(ref.read(homeSwipeRightGestureProvider));
    }
    final stop = _swipeStop(direction);
    if (stop == null) return null;
    final l10n = context.l10n;
    if (stop.folderId == kSharedHubFolderId) {
      final hub = ref.read(sharedHubFolderProvider);
      return hub.name.isEmpty ? l10n.sharedHubShort : hub.name;
    }
    final sharedStop = _sharedStopOf(stop.folderId);
    if (sharedStop != null) return sharedStop.name;
    if (ref.read(swipeModeProvider) == SwipeMode.filters) {
      return stop.tag != null
          ? '#${stop.tag}'
          : stop.filter == NoteFilter.all
          ? l10n.allNotesChip
          : filterLabel(l10n, stop.filter);
    }
    final id = stop.folderId;
    if (id == null) return l10n.allNotesChip;
    for (final f in ref.read(visibleOrderedFoldersProvider)) {
      if (f.id == id) return f.name;
    }
    return null;
  }

  /// Çekiş kenarında hedefin simgesi (takvim, klasör, paylaşılan, süzgeç).
  IconData? _swipeStopIcon(int direction) {
    if (_swipeOpensCalendar(direction)) {
      return switch (ref.read(homeSwipeRightGestureProvider).kind) {
        HomeGestureKind.calendar => Icons.calendar_month_outlined,
        HomeGestureKind.folders => Icons.folder_outlined,
        HomeGestureKind.folder => Icons.folder_outlined,
        HomeGestureKind.note => Icons.sticky_note_2_outlined,
        HomeGestureKind.none => null,
      };
    }
    final stop = _swipeStop(direction);
    if (stop == null) return null;
    if (stop.folderId == kSharedHubFolderId) {
      final hub = ref.read(sharedHubFolderProvider);
      return hub.icon.isEmpty ? AppIcons.inbox : hub.iconData;
    }
    if (_sharedStopOf(stop.folderId) != null) {
      return AppIcons.shared;
    }
    if (ref.read(swipeModeProvider) == SwipeMode.filters) {
      if (stop.tag != null) return Icons.label_outline;
      return stop.filter == NoteFilter.all
          ? Icons.notes_rounded
          : Icons.filter_list_rounded;
    }
    return stop.folderId == null
        ? Icons.notes_rounded
        : Icons.folder_outlined;
  }

  HomeSwipeStop? _swipeStop(int direction) {
    final suppressed = ref.read(suppressedFolderIdsProvider);
    final notes = [
      for (final n in ref.read(notesStreamProvider).value ?? const <Note>[])
        if (n.archivedAt == null &&
            !n.isEmpty &&
            !suppressed.contains(n.folderId))
          n,
    ];
    final mode = ref.read(swipeModeProvider);
    final hub = ref.read(sharedHubFolderProvider);
    final folderIds = [
      // Şeritle AYNI sıra: boş klasörler sonda (B3).
      for (final f in emptyFoldersLast(
        ref.read(visibleOrderedFoldersProvider),
        ref.read(folderSortProvider),
        ref.read(folderNoteCountsProvider),
      ))
        f.id,
    ];
    // Paylaşılanlar şeritteki sırayla: okunmamışı olan başta, kalanı sonda.
    final shares =
        ref.read(sharedFolderRefsProvider).value ?? const <SharedFolderRef>[];
    bool hot(SharedFolderRef s) =>
        ref.read(
          folderUnreadProvider((ownerId: s.ownerId, folderId: s.folderId)),
        ) >
        0;
    final selectedShared = ref.read(selectedSharedFolderProvider);
    return nextHomeSwipeStop(
      mode: mode,
      notes: notes,
      // GELEN de bir durak (2026-11-02), gizli değilse şeritteki yerinde.
      folderIds: [
        for (final s in shares)
          if (hot(s)) sharedFolderStopId(s),
        ...hub.hidden
            ? folderIds
            : withSharedHub(folderIds, kSharedHubFolderId, hub.order ?? 0),
        for (final s in shares)
          if (!hot(s)) sharedFolderStopId(s),
      ],
      folderId: mode == SwipeMode.filters
          ? ref.read(selectedFolderProvider)
          : selectedShared != null
          ? '${selectedShared.ownerId}/${selectedShared.folderId}'
          : ref.read(sharedHubOnHomeProvider)
          ? kSharedHubFolderId
          : ref.read(selectedFolderProvider),
      filter: ref.read(noteFilterProvider),
      tag: ref.read(selectedTagProvider),
      direction: direction,
    );
  }

  /// Bir bölümde (sabitliler / diğerleri) notu basılı tutup sürükleyince
  /// (madde 1) çağrılır: [draggedId] notunu [toIndex] konumuna taşır ve yeni
  /// sırayı kalıcılaştırır. Elle sıra görünsün diye sıralama ölçütü manuel'e
  /// alınır.

  /// Sürüklenen not "silmeye hazır" çöp hedefine bırakıldı (F60.S9).
  ///
  /// Bırakma kartın `onDragEnd`'inden ÖNCE gelir: önizlenen sıra burada
  /// atılır ki [_endCardDrag] çöpe giden notun sürükleme yolunu "yeni sıra"
  /// diye kaydetmesin. Silme olağan yoldan: kilitli not doğrulama ister,
  /// kart küçülüp solar ([leavingNotesProvider]), geri al çubuğu çıkar.
  Future<void> _trashDraggedNote(String id) async {
    _hoverRetry?.cancel();
    _dragOrder = null;
    _dragOriginal = null;
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;
    final l10n = context.l10n;
    final note = _selectedNotes({id}).firstOrNull;
    if (note == null) return;
    if (note.locked && !await authenticateForNote(l10n.unlockAuthReason)) {
      return;
    }
    if (!mounted) return;
    if (ref.read(selectedNoteIdsProvider).contains(id)) {
      ref.read(selectedNoteIdsProvider.notifier).toggle(id);
    }
    await ref.read(leavingNotesProvider.notifier).leave([id], () {
      repo.softDelete(id);
    });
    if (!mounted) return;
    showUndoSnackBar(
      context,
      message: l10n.noteDeleted,
      undoLabel: l10n.undo,
      onUndo: () => repo.restore(id),
    );
  }

  /// Yeni notu açar. DÖNÜŞTEKİ vurgu artık burada değil, editörün
  /// kapanışında (bkz. [NotesRepository.lastCreatedId]): hangi yoldan doğarsa
  /// doğsun yeni not odaklanır, boş atılan notta vurgu olmaz.
  Future<void> _openNew(String id, {String query = '', NoteType? type}) async {
    if (!mounted) return;
    await context.pushNote(noteRoutePath(id, query: query));
  }

  /// Ana ekranda (hızlı yakalama satırı ya da sesli yakalama) not oluşturuldu:
  /// kullanıcı GÖRSÜN.
  ///
  /// KÖK NEDEN (kullanıcı: "kaydet dememe rağmen not oluşturmuyor"): not
  /// gerçekte oluşuyordu ama ekranda HİÇBİR ŞEY değişmiyordu — yeni not
  /// sabitlenmiş notların altındaki bölüme, çoğu zaman görünür alanın dışına
  /// düşüyor, satır da sessizce temizleniyordu; kullanıcı kaydın kaybolduğunu
  /// sanıyordu. Artık kart vurgulanıp görünür alana kaydırılır ve tek dokunuşla
  /// açılabilen bir bildirim çıkar.
  /// İKİNCİ KÖK NEDEN (kullanıcı: "bazen oluşuyor bazen oluşmuyor"): açık bir
  /// SÜZGEÇ ya da arama, yeni notu listeden eliyordu. Yeni not sade bir metin
  /// notudur: "Yıldızlı" süzgeci, bir etiket seçimi ya da yazılı bir arama
  /// varken hiçbirine uymaz ve ekranda hiç belirmez — kullanıcı için bu,
  /// notun oluşmamasıyla aynı şey. Notu gizleyecek süzgeçler kaydın hemen
  /// ardından temizlenir (klasör süzgeci KALIR: not zaten o klasöre doğuyor).
  void _afterQuickCapture(String id) {
    if (!mounted) return;
    final l10n = context.l10n;
    if (ref.read(noteFilterProvider) != NoteFilter.all) {
      ref.read(noteFilterProvider.notifier).set(NoteFilter.all);
    }
    if (ref.read(selectedTagProvider) != null) {
      ref.read(selectedTagProvider.notifier).set(null);
    }
    if (ref.read(searchQueryProvider).trim().isNotEmpty) {
      _searchController.clear();
      ref.read(searchQueryProvider.notifier).set('');
    }
    ref.read(focusedNoteProvider.notifier).focus(id);
    // Geri sayımla kendiliğinden kapanır (bildirim şeridi).
    ScaffoldMessenger.of(context).showMessage(
      l10n.assistantNoteCreated,
      action: SnackBarAction(
        label: l10n.openNote,
        onPressed: () => _openNew(id),
      ),
    );
  }

  /// Sağ alttaki asistan düğmesi: ortak dinleme levhasını açar ve seçilen
  /// eyleme göre notu kurar.
  ///
  /// Levha, Ayarlar'daki "basılı tut / bas-başlat" tercihine kendi içinde
  /// uyar; bu yüzden düğme TEK DOKUNUŞLA açılıyor. Tasarım "basılı tutunca
  /// açılsın" diyordu ama o zaman bas-başlat'ı seçmiş kullanıcı ana ekranda
  /// yine basılı tutmak zorunda kalırdı — ayar anlamsızlaşırdı.
  Future<void> _captureVoiceNote() async {
    final l10n = context.l10n;
    final result = await showVoiceCaptureSheet(
      context,
      target: VoiceCaptureTarget.dashboard,
    );
    if (result == null || !mounted) return;
    if (result.action == VoiceCaptureAction.dictate) {
      await _dictateNote();
      return;
    }

    // "Asistan oluştursun": notu döküme bakarak asistan kurar — başlık,
    // maddeler ve HATIRLATICI çıkarır (bkz. voice_assistant.dart).
    // Ses eki yolunda (döküm yapılamadı) bu çip zaten gösterilmez; yine de
    // gelirse aşağıdaki düz akış çalışır — kayıt kaybolmasın.
    if (result.action == VoiceCaptureAction.compose &&
        result.audioPath == null &&
        result.audioBytes == null) {
      await ref
          .read(voiceAssistantProvider.notifier)
          .composeFromTranscript(
            // Söylenen başlık asistana metnin başında verilir; notu o kurar.
            result.title == null
                ? result.text
                : '${l10n.noteTitleLabel}: ${result.title}\n${result.text}',
            nothingHeardText: l10n.voiceNothingHeard,
            savedText: l10n.voiceNoteSaved,
            describeError: (e) => aiErrorText(l10n, e),
            genericErrorText: l10n.assistantGenericError,
            historyLabel: l10n.aiHistoryVoiceNote,
          );
      return;
    }

    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;

    final text = result.text;

    // TEK yazımda kur: createNote + ayrı updateFields arasında doküman bir an
    // boş/süzgeçsiz kalıyor ve o anki akış görüntüsünde listeden düşebiliyordu
    // (hızlı yakalama satırında çözülen kök neden burada açık kalmıştı).
    final asList = result.action == VoiceCaptureAction.asList;
    final folderId = ref.read(selectedFolderProvider);
    final id = await repo.createNote(
      asList ? NoteType.checklist : NoteType.text,
      title: result.title ?? '',
      body: asList ? '' : (text.trim().isNotEmpty ? text : ''),
      folderId: folderId,
    );
    if (asList) {
      repo.updateFields(id, {
        'items': [
          for (final line in text.split('\n'))
            if (line.trim().isNotEmpty)
              // Şemanın anahtarı 'checked' ('done' yabancı alan olarak
              // kalıyordu; fromMap onu hiç okumuyor).
              {'id': const Uuid().v4(), 'text': line.trim(), 'checked': false},
        ],
      });
    }
    // Dökümü yapılamamış konuşma: kayıt nota SES EKİ olarak girer, böylece
    // yapay zekâ hiç çalışmasa da konuşma kaybolmaz.
    if (result.audioPath != null || result.audioBytes != null) {
      await _attachVoiceAudio(
        id,
        result.audioPath,
        result.audioBytes,
        result.audioMime,
        result.audioDuration,
      );
    }
    if (!mounted) return;
    _afterQuickCapture(id);
  }

  /// Ana ekran mikrofonunun dokunuşu: doğrudan yazdır (boş not, söz nota).
  Future<void> _dictateNote() {
    TipOnce.show(
      context,
      ref.read(sharedPreferencesProvider),
      TipOnce.homeMicHold,
      context.l10n.tipHomeMicHold,
    );
    return createDictationNote();
  }

  /// Sesli yakalamadan dönen ses kaydını yeni nota ek olarak bağlar.
  Future<void> _attachVoiceAudio(
    String noteId,
    String? path,
    Uint8List? bytes,
    String? mime,
    Duration duration,
  ) async {
    final attachments = ref.read(attachmentRepositoryProvider);
    final repo = ref.read(notesRepositoryProvider);
    if (attachments == null || repo == null) {
      if (!kIsWeb && path != null && path.isNotEmpty) {
        File(path).delete().ignore();
      }
      return;
    }
    try {
      final attachment = bytes != null
          ? await attachments.prepareAudioBytes(
              noteId: noteId,
              bytes: bytes,
              duration: duration,
              mimeTypeHint: mime,
            )
          : await attachments.prepareAudio(
              noteId: noteId,
              sourcePath: path!,
              duration: duration,
            );
      repo.updateFields(noteId, {
        'attachments': [attachment.toMap()],
      });
    } catch (e) {
      if (!kIsWeb && path != null && path.isNotEmpty) {
        File(path).delete().ignore();
      }
      if (mounted) showQuickAddSnack(context.l10n.attachmentFailed(friendlyError(context.l10n, e)));
    }
  }

  /// Ana ekran zemini: **renk → desen → görsel** (üçü de isteğe bağlı, üst
  /// üste binebilirler — bkz. `dashboard_background_sheet.dart`).
  List<Widget> _dashboardBackground(WidgetRef ref) =>
      buildAppBackgroundLayers(context, ref);
}
