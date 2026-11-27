part of 'dashboard_screen.dart';

/// Sabit başlık (arama çubuğu + süzgeç çipleri) ile kayan not ızgarası
/// arasındaki sınır çizgisi.
///
/// Liste tepedeyken görünmez: sayfa duruyorken bir çizgi çekmek gereksiz bir
/// bölme yaratır. Kaydırma başlar başlamaz belirir ve altına yumuşak bir gölge
/// düşürür — kartlar artık başlığın "ALTINDAN" geçtiği belli olur
/// (bkz. [_DashboardScreenState._gridScrolled]).
class _HeaderSeparator extends StatelessWidget {
  const _HeaderSeparator({required this.scrolled});

  final ValueNotifier<bool> scrolled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder<bool>(
      valueListenable: scrolled,
      builder: (context, on, _) => AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 1,
        margin: const EdgeInsets.only(top: 4),
        decoration: BoxDecoration(
          color: on ? scheme.outlineVariant : Colors.transparent,
          boxShadow: on
              ? [
                  BoxShadow(
                    color: scheme.shadow.withValues(alpha: AppAlpha.pressed),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ]
              : const [],
        ),
      ),
    );
  }
}

/// Sıralama modundaki karonun sabit yüksekliği. Eşit karo = önceden bilinen
/// hücre: sürüklerken görülen önizleme ile bırakınca oluşan yerleşim aynı.
const double _kReorderTileHeight = 104;

/// Sıralama modunun kompakt not karosu: renk, başlık, kısa önizleme ve sıra
/// numarası. Tam kartın kendisi kullanılmaz — içeriğe göre uzayan kart eşit
/// hücreye sığmaz, sığdırmak için kırpılınca da okunmaz olurdu.
class _ReorderTile extends StatelessWidget {
  const _ReorderTile({required this.note, required this.order});

  final Note note;

  /// Kartın bölümdeki 1 tabanlı sırası: taşırken "kaçıncı sıraya gitti"
  /// sorusunun cevabı ekranda dursun.
  final int order;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final frame = NoteColors.noteFrame(note, dark: dark);
    final title = note.title.trim();
    final preview = stripRichMarkers(note.toPlainText()).trim();
    final surface = NoteColors.noteSurface(context, note);
    // Sayı ve raptiye de yazıyla aynı okunur temadan (bkz. NoteInkScope).
    final scheme =
        (NoteColors.inkThemeFor(Theme.of(context), surface) ?? Theme.of(context))
            .colorScheme;
    final radius = AppTokens.of(context).cardRadius;
    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(radius),
      // Koyu özel renkte yazı zemine göre döner (bkz. NoteInkScope).
      child: NoteInkScope(
        background: surface,
        child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color:
                frame ??
                NoteColors.noteInk(context, note)?.withValues(alpha: 0.16) ??
                AppTokens.of(context).hairline,
            width: frame != null ? 2.5 : 1,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (note.pinned) ...[
                  Icon(
                    Icons.push_pin,
                    size: 13,
                    color: NoteColors.noteInk(context, note) ?? scheme.secondary,
                  ),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    title.isEmpty ? preview : title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: AppWeight.strong,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '$order',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: AppWeight.strong,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                title.isEmpty ? '' : preview,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.25,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            Row(
              children: [
                Icon(
                  Icons.drag_indicator,
                  size: 15,
                  color: scheme.onSurfaceVariant,
                ),
                const Spacer(),
                if (note.attachmentsWithoutBackground.isNotEmpty)
                  Icon(
                    Icons.attach_file,
                    size: 13,
                    color: scheme.onSurfaceVariant,
                  ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }
}

/// Bir not kartını basılı tutup sürükleyerek yeniden sıralamayı sağlayan
/// sarmalayıcı. Sıralama modunda ([reorderModeProvider]) ve seçim kipinde
/// SEÇİLİ kartlarda kullanılır: uzun basış sürüklemeyi başlatır, parmak
/// gezdikçe üst katman sırayı CANLI önizler ([onHover]), parmak kalkınca
/// görünen sıra kaydedilir ([onDragEnd]). Sürükleme aynı bölümle sınırlıdır
/// ([inSection]) — sabitliler ile diğerleri karışmaz.
///
/// Sürüklenemeyen hücreler yalnız BIRAKMA HEDEFİDİR; onlarda uzun basış
/// seçim yapar ([onLongPress]).
class _ReorderableNoteCell extends StatelessWidget {
  const _ReorderableNoteCell({
    super.key,
    required this.noteId,
    required this.cellWidth,
    required this.inSection,
    required this.onDragStart,
    required this.onHover,
    required this.onDragEnd,
    required this.feedback,
    required this.child,
    this.draggable = true,
    this.onLongPress,
    this.onDragUpdate,
    this.onHoverLeave,
  });

  /// Sürüklenen kart bu hücreden ÇIKTI (P56: itilen kartın kilidi açılır).
  final VoidCallback? onHoverLeave;

  /// Sürüklenen parmağın her adımı (yol ölçümü: hiç oynamadı mı?).
  final DragUpdateCallback? onDragUpdate;

  final String noteId;
  final double cellWidth;
  final bool Function(String draggedId) inSection;

  /// Bu karttan sürükleme başladı.
  final VoidCallback onDragStart;

  /// Sürüklenen kart BU hücrenin üzerinde: üst katman sırayı önizler.
  final VoidCallback onHover;

  /// Parmak kalktı (kabul edilsin edilmesin): görünen sıra kaydedilir.
  final VoidCallback onDragEnd;
  final Widget feedback;
  final Widget child;

  /// Bu hücre sürüklenebilir mi? false ise yalnız BIRAKMA HEDEFİ olur —
  /// seçim kipinde yalnız seçili kart taşınır, ötekiler hedeftir.
  final bool draggable;

  /// Sürüklenemeyen hücrede uzun basış (seçime al/çıkar).
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = AppTokens.of(context);
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) =>
          details.data != noteId && inSection(details.data),
      // Parmak bu hücrenin üzerine geldi: sıra CANLI önizlenir. Bırakma
      // (`onAccept`) beklenmez — kullanıcı sonucu sürüklerken görmeli.
      onMove: (_) => onHover(),
      onLeave: (_) => onHoverLeave?.call(),
      onAcceptWithDetails: (_) {},
      builder: (context, candidate, rejected) {
        final hovering = candidate.isNotEmpty;
        // Üzerine bırakılmak üzere olan hücre vurgulanır; kenarlık HER ZAMAN
        // 2 px (saydam) — kalınlığı değiştirmek yerleşimi oynatırdı.
        final framed = AnimatedContainer(
          duration: AppMotion.short,
          curve: AppMotion.standard,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(tokens.cardRadius + 2),
            border: Border.all(
              color: hovering ? scheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: child,
        );
        if (!draggable) {
          return GestureDetector(
            onLongPress: onLongPress,
            child: HoldRingArea(icon: Icons.check_rounded, child: framed),
          );
        }
        return LongPressDraggable<String>(
          data: noteId,
          onDragStarted: onDragStart,
          onDragUpdate: onDragUpdate,
          // Nereye bırakılırsa bırakılsın (kartın üstü, boşluk, ekran dışı)
          // önizlenen sıra kaydedilir; kullanıcı zaten onu görüyordu.
          //
          // KÖK NEDEN (F60.S12, "çöp işareti ekranda kalıyor"): `onDragEnd`
          // Flutter'da yalnız hücre HÂLÂ bağlıyken çağrılır. Önizleme sırası
          // kartı başka satıra/sütuna taşıyınca hücre yeniden kurulur; kabul
          // edilen bırakmada (çöp, başka kart) sürükleme hiç bitmiyordu.
          // `onDragCompleted`/`onDraggableCanceled` bağlılığa bakmaz ve
          // birbirini dışlar — ikisi birlikte her bırakmayı tam bir kez verir.
          onDragCompleted: onDragEnd,
          onDraggableCanceled: (_, _) => onDragEnd(),
          // Elde tutulan kâğıt (F31.4): büyük gölge + 1,03 + −0,8°, YALNIZ
          // sürüklenen kartta. Hareketi azaltta düz durur.
          // Çöpe yaklaşınca küçülüp hedefe çekilir (F60.S12).
          feedback: TrashPullFeedback(
            child: Transform.rotate(
            angle: motionOf(context) ? -0.8 * math.pi / 180 : 0,
            child: Transform.scale(
              scale: motionOf(context) ? 1.03 : 1,
              child: Material(
                color: Colors.transparent,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(tokens.cardRadius),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.onSurface.withValues(alpha: 0.22),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: SizedBox(width: cellWidth, child: feedback),
                ),
              ),
            ),
          ),
          ),
          // Kart önizlemede zaten YENİ yerinde duruyor; burada soluk bir
          // hayalet bırakmak "gideceği yer" hissini tamamlıyor.
          childWhenDragging: Opacity(opacity: 0.25, child: child),
          // Basılı tutarken dolan halka: dolunca kart elde (2026-11-09).
          child: HoldRingArea(icon: Icons.open_with, child: framed),
        );
      },
    );
  }
}

class _SearchField extends ConsumerWidget {
  const _SearchField({
    this.compact = false,
    this.showFilterInCompact = false,
    required this.controller,
    this.focusNode,
    this.trailing = const [],
  });

  final TextEditingController controller;
  final FocusNode? focusNode;

  /// Kutunun İÇİNDE, sağda duran düğmeler (hesap, ⋮). Kullanıcı isteği
  /// 2026-11-06: "üst arama çubuğu profil ve 3 noktayı da kapsasın, güzel
  /// bir alan olsun" — üç ayrı parça yerine tek hap.
  final List<Widget> trailing;

  /// Dar liste bölmesi (F67.3): AI anahtarı ve süz gizli — ikisi de ⋮'te.
  final bool compact;

  /// Kenar çubuğunda hesap zaten görünürken dar liste bölmesinde Süz
  /// düğmesini doğrudan arama kutusunda tut.
  final bool showFilterInCompact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final query = ref.watch(searchQueryProvider);
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final tokens = AppTokens.fromTheme(theme);
    final text = AppText.of(theme);
    return Container(
        height: 50,
        decoration: BoxDecoration(
          color: tokens.card,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: query.isNotEmpty
                ? tokens.resolvedAccentBorder(scheme)
                : tokens.hairline,
          ),
          boxShadow: tokens.cardShadow,
        ),
        child: Row(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => focusNode?.requestFocus(),
              child: SizedBox(
                height: 50,
                child: Row(
                  children: [
                    const SizedBox(width: AppSpace.m + 2),
                    Icon(
                      Icons.search_rounded,
                      size: AppIconSize.m,
                      color: query.isNotEmpty
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpace.s),
                  ],
                ),
              ),
            ),
            Expanded(
              child: TextField(
                textAlignVertical: TextAlignVertical.center,
                controller: controller,
                focusNode: focusNode,
                onChanged: (value) =>
                    ref.read(searchQueryProvider.notifier).set(value),
                onTapOutside: (_) {
                  ref.read(searchHistoryProvider.notifier).remember(query);
                  focusNode?.unfocus();
                },
                onSubmitted: (value) =>
                    ref.read(searchHistoryProvider.notifier).remember(value),
                textInputAction: TextInputAction.search,
                style: text.label.copyWith(fontWeight: AppWeight.regular),
                decoration: InputDecoration(
                  hintText: l10n.searchHint,
                  hintStyle: text.label.copyWith(
                    fontWeight: AppWeight.regular,
                    color: scheme.onSurfaceVariant,
                  ),
                  border: InputBorder.none,
                  filled: false,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
            if (query.isNotEmpty)
              IconButton(
                tooltip: l10n.close,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close_rounded, size: AppIconSize.s),
                onPressed: () {
                  controller.clear();
                  ref.read(searchQueryProvider.notifier).set('');
                },
              ),
            // SÜZ arama kutusunun sağında (bkz. [HomeFilterButton]);
            // kişiselleştirmede gizlenebilir.
            Offstage(
              offstage: compact && !showFilterInCompact,
              child: const Customizable(
                id: UiItem.homeFilter,
                child: Padding(
                  padding: EdgeInsetsDirectional.only(start: 2),
                  child: HomeFilterButton(),
                ),
              ),
            ),
            ...trailing,
            const SizedBox(width: 4),
          ],
        ),
    );
  }
}

/// Arama kutusunun altındaki "son aramalar" şeridi.
///
/// Boşken hiç yer kaplamaz. Çipe dokunmak sorguyu geri getirir, çipteki ×
/// onu geçmişten siler (yanlış yazılmış ya da bir daha aranmayacak bir
/// sorgu listede kalmasın).
class _RecentSearches extends ConsumerWidget {
  const _RecentSearches({required this.visible, required this.onPick});

  final bool visible;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!visible) return const SizedBox.shrink();
    if (ref.watch(searchQueryProvider).isNotEmpty) {
      return const SizedBox.shrink();
    }
    final history = ref.watch(searchHistoryProvider);
    if (history.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(kGridInset, 2, kGridInset, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.recentSearches,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: AppWeight.strong,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: ref.read(searchHistoryProvider.notifier).clear,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text(
                  l10n.clearRecentSearches,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: history.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final query = history[index];
                return InputChip(
                  label: Text(query, style: const TextStyle(fontSize: 12)),
                  avatar: const Icon(Icons.history, size: 14),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => onPick(query),
                  onDeleted: () =>
                      ref.read(searchHistoryProvider.notifier).forget(query),
                  deleteIcon: const Icon(Icons.close, size: 14),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Asistanın dokunduğu notu görünür alana kaydırıp kısa süre vurgulayan
/// sarmalayıcı.
///
/// Vurgu KARTIN İÇİNE değil çevresine çizilir: kartın kendi kenarlığı/rengi
/// notun ayarı, geçici bir işaret onu değiştirmemeli. Kaydırma yalnız bir kez,
/// vurgu ilk göründüğünde yapılır — kullanıcı sonra elle kaydırırsa kart geri
/// zıplamaz.
class _FocusHalo extends StatefulWidget {
  const _FocusHalo({
    required this.focused,
    this.open = false,
    required this.noteId,
    required this.child,
  });

  final bool focused;

  /// Not sağ panelde AÇIK (geniş ekran): sabit, ince çerçeve — kullanıcı
  /// listede nerede olduğunu görsün. Telefonda liste editörün altında
  /// görünmediğinden fark etmez.
  final bool open;
  final String noteId;
  final Widget child;

  @override
  State<_FocusHalo> createState() => _FocusHaloState();
}

class _FocusHaloState extends State<_FocusHalo>
    with SingleTickerProviderStateMixin {
  bool _scrolled = false;

  /// Çerçevenin YANIP SÖNMESİ: sabit bir kenarlık uzun listede gözden
  /// kaçıyordu (kullanıcı: "notun çerçevesinden hafif yanıp sönmeli").
  /// Nefes alır gibi, göz yormayan bir ritim.
  /// TEMBEL: yalnız ODAKLI kartta kurulur (bkz. [_syncPulse] kök nedeni).
  AnimationController? _pulse;

  AnimationController _ensurePulse() =>
      _pulse ??= AnimationController(vsync: this);

  @override
  void didUpdateWidget(covariant _FocusHalo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focused && !oldWidget.focused) _scrolled = false;
    _maybeScroll();
    _syncPulse();
  }

  /// İlk senkron burada (initState değil): hareketi azalt ayarı
  /// `MediaQuery`den okunur.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeScroll();
    _syncPulse();
  }

  /// KÖK NEDEN (kasma): denetleyici ODAKLANMAMIŞ kartta da yaratılıyordu.
  /// `_FocusHalo` her kartı sarıyor ve kaydırma önbelleği ~130 kartı canlı
  /// tuttuğu için, tek bir notu vurgulamak uğruna 130 `AnimationController` +
  /// 130 `Ticker` kuruluyor, kaydırdıkça sürekli kurulup yıkılıyordu.
  void _syncPulse() {
    if (!widget.focused) {
      // Hiç kurulmadıysa kurma: odaklanmamış kart için denetleyiciye gerek yok.
      _pulse
        ?..stop()
        ..value = 0;
      return;
    }
    final pulse = _ensurePulse();
    // Hareketi azalt: yanıp sönme yok, odak süresince tek, sabit vurgu.
    if (MediaQuery.disableAnimationsOf(context)) {
      pulse
        ..stop()
        ..value = 1;
      return;
    }
    if (pulse.isAnimating) return;
    // Nabız hızı odağı kuran yolun: asistan sakin, yeni not iki kısa nabız
    // (bkz. [FocusedNoteNotifier.focusBrief]).
    pulse.duration = ProviderScope.containerOf(
      context,
      listen: false,
    ).read(focusedNoteProvider.notifier).pulse;
    pulse.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse?.dispose();
    super.dispose();
  }

  /// Kart TAMAMEN görünüyorsa kaydırma yok; değilse ortalanır.
  void _maybeScroll() {
    if (!widget.focused || _scrolled) return;
    _scrolled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = context.findRenderObject();
      if (box is! RenderBox || !box.attached) return;
      final scrollable = Scrollable.maybeOf(context);
      final viewport = RenderAbstractViewport.maybeOf(box);
      if (scrollable == null || viewport == null) return;
      final pixels = scrollable.position.pixels;
      final atTop = viewport.getOffsetToReveal(box, 0).offset;
      final atBottom = viewport.getOffsetToReveal(box, 1).offset;
      if (pixels >= atBottom - 1 && pixels <= atTop + 1) return;
      Scrollable.ensureVisible(
        context,
        alignment: 0.5,
        duration: AppMotion.long,
        curve: AppMotion.emphasized,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (!widget.focused) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.l),
          // Aynı 2 dp: vurgu gelip gidince kart yerinden oynamaz.
          border: Border.all(
            color: widget.open ? scheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: widget.child,
      );
    }
    final pulse = _ensurePulse();
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, child) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.l),
          border: Border.all(
            color: scheme.primary.withValues(alpha: 0.35 + 0.65 * pulse.value),
            width: 2,
          ),
        ),
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// Ana ekranın en üstündeki tek satırlık not girişi.
///
/// Kısa notlar için editöre gitmek gereksiz bir tur: aç, yaz, geri dön.
/// Burada Enter'a basmak notu doğrudan kaydeder ve satır temizlenir; kullanıcı
/// arka arkaya beş not düşecekse ekrandan hiç ayrılmaz.
class _QuickCaptureRow extends ConsumerStatefulWidget {
  const _QuickCaptureRow({
    required this.onCreateChecklist,
    required this.onSaved,
  });

  final VoidCallback onCreateChecklist;

  /// Not oluşturulduktan sonra çağrılır (yeni notun id'si ile): ana ekran
  /// kartı vurgular ve bildirim gösterir.
  final void Function(String noteId) onSaved;

  @override
  ConsumerState<_QuickCaptureRow> createState() => _QuickCaptureRowState();
}

class _QuickCaptureRowState extends ConsumerState<_QuickCaptureRow> {
  final _controller = TextEditingController();
  bool _hasText = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;
    // Satır ÖNCE temizlenir: kayıt ağ üzerinden dönerken kullanıcı ikinci
    // notu yazmaya başlayabilsin, yazdığı harfler ilkinin üstüne binmesin.
    _controller.clear();
    setState(() => _hasText = false);
    // Metin TEK yazımda gider (önce boş not + sonra gövde DEĞİL): iki yazım
    // arasında doküman boş kalıyor ve o ara akışa düşerse not ana ekran
    // süzgecinden eleniyordu — "bazen oluşuyor bazen oluşmuyor"un kaynağı.
    final id = await repo.createNote(
      NoteType.text,
      body: text,
      folderId: ref.read(selectedFolderProvider),
    );
    // Klavye kapanır: not kaydedildi, imleç boş satırda yanıp sönmesin —
    // "kaydettim ama bir şey olmadı" hissinin bir parçası da buydu.
    FocusManager.instance.primaryFocus?.unfocus();
    widget.onSaved(id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(kGridInset, 10, kGridInset, 0),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.m),
          border: Border.all(color: scheme.outlineVariant),
        ),
        padding: const EdgeInsetsDirectional.only(start: 12, end: 6),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                onChanged: (v) {
                  final has = v.trim().isNotEmpty;
                  if (has != _hasText) setState(() => _hasText = has);
                },
                onSubmitted: (_) => _save(),
                textInputAction: TextInputAction.done,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: AppWeight.medium,
                ),
                decoration: InputDecoration(
                  hintText: l10n.quickCaptureHint,
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: scheme.onSurfaceVariant,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (_hasText)
              SizedBox(
                height: 34,
                child: FilledButton.icon(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  icon: const Icon(Icons.check, size: AppIconSize.xs),
                  label: Text(
                    l10n.quickCaptureSave,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: AppWeight.strong,
                    ),
                  ),
                ),
              )
            else
              // Mikrofon buradan KALDIRILDI: sağ altta zaten kalıcı bir sesli
              // yakalama düğmesi var, aynı iş iki yerde duruyordu.
              _QuickCaptureIcon(
                icon: Icons.checklist,
                tooltip: l10n.filterChecklist,
                onTap: widget.onCreateChecklist,
              ),
          ],
        ),
      ),
    );
  }
}

class _QuickCaptureIcon extends StatelessWidget {
  const _QuickCaptureIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: SizedBox(
      width: 34,
      height: 34,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: onTap,
          child: Icon(
            icon,
            size: 19,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    ),
  );
}

/// Ana ekranın ⚡ Hızlı ekle düğmesi (mikrofonun solunda, aynı nötr kare).
class _QuickDropFab extends StatelessWidget {
  const _QuickDropFab();

  // ODAK/İPUCU KATMANSIZ (InkWell + Tooltip değil): ikisi de levha
  // açılıp kapanınca (odak kapsamı, rota) yeniden kuruluyordu — ana ekranın
  // levha aç/kapa bütçeleri (S18/S30/S37/S45) her seferinde +1/+2. Ad
  // Semantics'te, basınca küçülür ([PressScale]); dokunma alanı 48 dp.
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Customizable(
      id: UiItem.homeQuickDrop,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(end: 12),
        child: Semantics(
          button: true,
          label: context.l10n.quickDropTitle,
          excludeSemantics: true,
          child: PressScale(
            scale: 0.92,
            child: GestureDetector(
              key: const ValueKey('home-quick-drop'),
              behavior: HitTestBehavior.opaque,
              onTap: () {
                unawaited(AppHaptics.tick());
                unawaited(showQuickDropSheet(context));
              },
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: _kDashButtonRadius,
                ),
                child: SizedBox.square(
                  dimension: 48,
                  child: Icon(
                    Icons.bolt,
                    size: AppIconSize.l,
                    color: scheme.onSurface,
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

class _AfterFirstFrame extends StatefulWidget {
  const _AfterFirstFrame({required this.child});

  final Widget child;

  @override
  State<_AfterFirstFrame> createState() => _AfterFirstFrameState();
}

class _AfterFirstFrameState extends State<_AfterFirstFrame> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) =>
      _ready ? widget.child : const SizedBox.shrink();
}

class _DashVoiceButton extends StatelessWidget {
  const _DashVoiceButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.onLongPress,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 48,
        height: 48,
        // NÖTR (F74.5): "+" ekranın tek dolu birincil yüzeyi; yanındaki
        // mikrofon onunla yarışmasın. Yer, boy ve davranış aynı.
        child: Material(
          color: scheme.surfaceContainerHigh,
          borderRadius: _kDashButtonRadius,
          child: InkWell(
            borderRadius: _kDashButtonRadius,
            onTap: onTap,
            onLongPress: onLongPress,
            child: Icon(icon, size: AppIconSize.l, color: scheme.onSurface),
          ),
        ),
      ),
    );
  }
}

/// **KAYDIRARAK HIZLI İŞLEM** (kullanıcı isteği 2026-09-23): liste
/// görünümünde satırı sağa çekmek sabitler (ya da sabitlemeyi kaldırır),
/// sola çekmek arşivler — geri alınabilir.
///
/// Yalnız LİSTE görünümünde: ızgarada yatay çekiş süzgeçler arasında
/// geziyor ([_cycleFilterFolder]) ve kartlar sütunlarda yan yana duruyor;
/// orada kartın kendisini çekmek, hangi işin olacağını belirsizleştirirdi.
///
/// `confirmDismiss` işi yapıp FALSE döner: satır yerine geri kayar, notun
/// listeden çıkması (arşiv) ya da sabitlilere taşınması Firestore akışından
/// gelir. `true` dönülseydi akış o kareye yetişmediğinde Flutter "kapatılmış
/// Dismissible hâlâ ağaçta" hatası verirdi.
class _SwipeActions extends StatelessWidget {
  const _SwipeActions({
    required this.note,
    required this.enabled,
    required this.onPin,
    required this.onArchive,
    required this.child,
  });

  final Note note;

  /// Seçim kipinde kapalı: orada çekiş seçimle karışırdı.
  final bool enabled;
  final VoidCallback onPin;
  final VoidCallback onArchive;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    Widget background({
      required AlignmentGeometry alignment,
      required IconData icon,
      required String label,
      required Color color,
      required Color ink,
    }) => Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpace.s,
        vertical: 1,
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.m),
      ),
      alignment: alignment,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: ink, size: AppIconSize.m),
          const SizedBox(width: AppSpace.s),
          Text(
            label,
            style: AppText.of(
              Theme.of(context),
            ).label.copyWith(color: ink, fontWeight: AppWeight.strong),
          ),
        ],
      ),
    );
    return Dismissible(
      key: ValueKey('swipe-${note.id}'),
      direction: enabled ? DismissDirection.horizontal : DismissDirection.none,
      // Yanlışlıkla tetiklenmesin: satırın en az %35'i çekilmeli.
      dismissThresholds: const {
        DismissDirection.startToEnd: 0.35,
        DismissDirection.endToStart: 0.35,
      },
      // Eşik aşılınca tek hafif titreşim (P62 §6.2, K5): bırakınca ne
      // olacağı hissedilsin.
      onUpdate: (d) {
        if (d.reached && !d.previousReached) unawaited(AppHaptics.tick());
      },
      background: background(
        alignment: AlignmentDirectional.centerStart,
        icon: note.pinned ? Icons.push_pin_outlined : Icons.push_pin,
        label: note.pinned ? l10n.unpin : l10n.pin,
        color: scheme.secondaryContainer,
        ink: scheme.onSecondaryContainer,
      ),
      secondaryBackground: background(
        alignment: AlignmentDirectional.centerEnd,
        icon: AppIcons.archive,
        label: l10n.archive,
        // Nötr (K6-1, sabah bakılacak): `tertiary` yalnız yapay zekâ rengi.
        color: scheme.surfaceContainerHighest,
        ink: scheme.onSurface,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onPin();
        } else {
          onArchive();
        }
        return false;
      },
      child: child,
    );
  }
}

/// Bekleyen ek şeridinin metni (F79.6 (5): çevrimdışıyken "yükleniyor"
/// değil "bekliyor"). Öncelik: Drive bağlantısı > bağlantı yok > hata >
/// yükleniyor.
String pendingUploadsBarLabel(
  AppLocalizations l10n, {
  required int pending,
  required int failed,
  required bool needsDrive,
  required bool offline,
}) {
  if (needsDrive) return l10n.driveWaiting(pending);
  if (offline) return l10n.pendingUploadsOffline(pending);
  if (failed > 0) return l10n.pendingUploadsFailed(failed);
  return l10n.pendingUploads(pending);
}

/// **SENKRON BEKLEYEN EKLER** göstergesi (kullanıcı isteği 2026-09-23).
///
/// Çevrimdışı eklenen fotoğraf öbür cihazda görünmüyordu ve bunun nedeni
/// hiçbir yerde yazmıyordu — kullanıcı "senkron bozuk" sanıyordu. Bekleyen
/// ek varken filtre satırının altında ince bir şerit durur; dokununca
/// açıklama çıkar. Hiç bekleyen yokken hiç yer kaplamaz.
///
/// Kendi `Consumer`ı: sayaç her değiştiğinde ana ekranın tamamı yeniden
/// kurulmasın.
class _PendingUploadsBar extends ConsumerWidget {
  const _PendingUploadsBar();

  /// İzin penceresi oturumda en çok bir kez kendiliğinden açılır.
  static bool _autoAsked = false;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pendingUploadsProvider);
    final l10n = context.l10n;
    // Google hesabı ama Drive bağlanmadı: ekler bağlantı bekliyor — şerit
    // bunu söyler ve dokununca bağlar (kullanıcı isteği 2026-10-15).
    final needsDrive = state.needsDrive;
    // KÖK NEDEN (2026-11-06, "ek sürekli bekliyor"): şeride dokunmayan
    // kullanıcının ekleri hiç çıkmıyordu. Bekleyen ek varken izin bir kez
    // kendiliğinden sorulur (reddedilirse şerit kalır, dokununca yine sorar).
    if (needsDrive && !_autoAsked) {
      _autoAsked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) unawaited(connectDrive(context, ref));
      });
    }
    // F79.6 (5): bağlantı yokken "yükleniyor" demek yalandı — "bekliyor,
    // bağlantı gelince yüklenecek" (hata rengi de değil: çevrimdışıyken
    // başarısız deneme beklenen şey). Yalnız metin/simge değişir, boy aynı.
    final offline =
        state.pending > 0 && !needsDrive && ref.watch(isOfflineProvider);
    final failing = state.failed > 0 && !needsDrive && !offline;
    // Görünür / gizli TEK ADIMDA (P62 PA6, R1): eskiden AnimatedSize altta
    // Expanded ızgarayı 200 ms boyunca her karede yeniden diziyordu (S32).
    if (state.pending == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(kGridInset, AppSpace.s, kGridInset, 0),
      child: AppBanner(
        tone: failing ? AppTone.danger : AppTone.attention,
        icon: needsDrive
            ? Icons.add_to_drive_outlined
            : failing || offline
            ? Icons.cloud_off_outlined
            : Icons.cloud_upload_outlined,
        title: pendingUploadsBarLabel(
          l10n,
          pending: state.pending,
          failed: state.failed,
          needsDrive: needsDrive,
          offline: offline,
        ),
        onTap: needsDrive
            ? () => connectDrive(context, ref)
            : () => ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showMessage(l10n.pendingUploadsInfo),
        // Dönen çark YOK (bilerek): bağlantı yokken şerit saatlerce
        // durabilir; sürekli animasyon pili yakardı.
        trailing: Icon(needsDrive ? Icons.link : Icons.info_outline),
      ),
    );
  }
}

/// Yatay şeritteki seçili çipi görünür alana kaydırır: yana çekişle ekran
/// dışındaki bir klasöre gelinince şerit de oraya kayar.
class _EnsureVisible extends StatefulWidget {
  const _EnsureVisible({super.key, required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<_EnsureVisible> createState() => _EnsureVisibleState();
}

class _EnsureVisibleState extends State<_EnsureVisible> {
  @override
  void initState() {
    super.initState();
    if (widget.active) _reveal();
  }

  @override
  void didUpdateWidget(_EnsureVisible oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) _reveal();
  }

  /// EN KISA kaydırma (2026-11-07): çip zaten tümüyle görünüyorsa şerit
  /// KIPIRDAMAZ; taşıyorsa yalnız kenara (+24 dp pay) gelecek kadar kayar.
  /// Eskiden her seçimde ortalanıyordu (`alignment: 0.5`) — yana çekişin her
  /// adımında bütün şerit kayıyordu.
  void _reveal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = context.findRenderObject();
      final position = Scrollable.maybeOf(context)?.position;
      if (box == null || position == null || !position.hasPixels) return;
      final viewport = RenderAbstractViewport.maybeOf(box);
      if (viewport == null) return;
      const margin = 24.0;
      final atStart = viewport.getOffsetToReveal(box, 0).offset - margin;
      final atEnd = viewport.getOffsetToReveal(box, 1).offset + margin;
      final double target;
      if (position.pixels > atStart) {
        target = atStart;
      } else if (position.pixels < atEnd) {
        target = atEnd;
      } else {
        return; // tümüyle görünüyor
      }
      final to = target.clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
      if ((to - position.pixels).abs() < 1) return;
      if (!motionOf(context)) {
        position.jumpTo(to);
        return;
      }
      unawaited(
        position.animateTo(
          to,
          duration: const Duration(milliseconds: 220),
          curve: AppMotion.emphasized,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
