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
        margin: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          color: on ? scheme.outlineVariant : Colors.transparent,
          boxShadow: on
              ? [
                  BoxShadow(
                    color: scheme.shadow.withValues(alpha: 0.12),
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
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '$order',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
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
                if (note.attachments.isNotEmpty)
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
  });

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
          return GestureDetector(onLongPress: onLongPress, child: framed);
        }
        return LongPressDraggable<String>(
          data: noteId,
          onDragStarted: onDragStart,
          // Nereye bırakılırsa bırakılsın (kartın üstü, boşluk, ekran dışı)
          // önizlenen sıra kaydedilir; kullanıcı zaten onu görüyordu.
          onDragEnd: (_) => onDragEnd(),
          onDraggableCanceled: (_, _) => onDragEnd(),
          // Elde tutulan kâğıt (F31.4): büyük gölge + 1,03 + −0,8°, YALNIZ
          // sürüklenen kartta. Hareketi azaltta düz durur.
          feedback: Transform.rotate(
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
          // Kart önizlemede zaten YENİ yerinde duruyor; burada soluk bir
          // hayalet bırakmak "gideceği yer" hissini tamamlıyor.
          childWhenDragging: Opacity(opacity: 0.25, child: child),
          child: framed,
        );
      },
    );
  }
}

class _SearchField extends ConsumerWidget {
  const _SearchField({required this.controller, this.focusNode});

  final TextEditingController controller;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final query = ref.watch(searchQueryProvider);
    final semantic = ref.watch(semanticSearchEnabledProvider);
    final scheme = Theme.of(context).colorScheme;
    // Anlamsal arama ESKİDEN alanın içindeki ✨ düğmesiydi: açık mı kapalı mı
    // olduğu yalnız ikon renginden anlaşılıyor, "akıllı arama" diye bir şeyin
    // varlığı hiç fark edilmiyordu. İki sekmeli segment modu okunur kılıyor.
    //
    // DOKUNMA ALANI (kullanıcı bulgusu 2026-10-29: "arama alanının tıklama
    // hitbox'ı çok dar, tam ortasına basmak gerekiyor"): yoğun TextField
    // yalnız yazı satırı kadar (~18 px) yüksekti; 44 px'lik kutunun üstü,
    // altı ve büyüteç ölü alandı. Artık alan kutuyu dikeyde doldurur ve
    // kutunun kalanına (büyüteç, kenarlar) dokunmak da odağı verir.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => focusNode?.requestFocus(),
      // Arama kutusu kâğıt renginde, ince çizgili (TEMA_PLANI F31.5):
      // zeminin üstünde kart gibi durur.
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppTokens.of(context).card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTokens.of(context).hairline),
        ),
        child: Row(
          children: [
            const SizedBox(width: 10),
            Icon(Icons.search, size: 19, color: scheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                textAlignVertical: TextAlignVertical.center,
                controller: controller,
                focusNode: focusNode,
                onChanged: (value) =>
                    ref.read(searchQueryProvider.notifier).set(value),
                // Alan dışına dokununca odak bırakılır; bar daralır. Sorgu da
                // o anda "son aramalar"a düşer — kullanıcı arama yapıp bir
                // nota geçtiğinde geçmişe yazılmasının doğal anı burası.
                onTapOutside: (_) {
                  ref.read(searchHistoryProvider.notifier).remember(query);
                  focusNode?.unfocus();
                },
                onSubmitted: (value) =>
                    ref.read(searchHistoryProvider.notifier).remember(value),
                textInputAction: TextInputAction.search,
                style: const TextStyle(fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: semantic
                      ? l10n.semanticSearchHint
                      : l10n.searchHint,
                  hintStyle: TextStyle(
                    fontSize: 13.5,
                    color: scheme.onSurfaceVariant,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  // Dikey dolgu alanı 44 px'lik kutu boyunca dokunulur kılar.
                  contentPadding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),
            if (query.isNotEmpty)
              IconButton(
                tooltip: l10n.close,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close, size: 18),
                onPressed: () {
                  controller.clear();
                  ref.read(searchQueryProvider.notifier).set('');
                },
              ),
            // TEK AI ANAHTARI (kullanıcı isteği 2026-10-17: "metin/anlam
            // yazıları çok yer kaplıyor, sadece bir AI işareti olsun, basınca
            // açılıp kapansın — metin ve anlam arasında geçiş"): açıkken dolu
            // vurgu rengi (anlamla arama), kapalıyken soluk çerçeve (metin).
            //
            // YALNIZ ARAMA SIRASINDA (F11.1): odak yokken ve kutu boşken
            // gizli — üst çubukta yer aramaya kalsın, ipucu kesilmesin.
            ListenableBuilder(
              listenable: focusNode ?? const AlwaysStoppedAnimation(0),
              builder: (context, _) =>
                  (focusNode?.hasFocus ?? true) || query.isNotEmpty
                  // TextFieldTapRegion: anahtara dokunmak "alan dışı" sayılıp
                  // odağı düşürmesin — düşürse anahtar dokunuş bitmeden
                  // kaybolurdu.
                  ? TextFieldTapRegion(
                      child: _SemanticToggle(
                        on: semantic,
                        onTap: () => ref
                            .read(semanticSearchEnabledProvider.notifier)
                            .toggle(),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            // SÜZ arama kutusunun sağında (bkz. [HomeFilterButton]);
            // kişiselleştirmede gizlenebilir.
            const Customizable(
              id: UiItem.homeFilter,
              child: Padding(
                padding: EdgeInsetsDirectional.only(start: 2),
                child: HomeFilterButton(),
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
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
                  fontWeight: FontWeight.w700,
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

class _SemanticToggle extends ConsumerStatefulWidget {
  const _SemanticToggle({required this.on, required this.onTap});

  final bool on;
  final VoidCallback onTap;

  @override
  ConsumerState<_SemanticToggle> createState() => _SemanticToggleState();
}

class _SemanticToggleState extends ConsumerState<_SemanticToggle> {
  @override
  void initState() {
    super.initState();
    // NE YAPAR (F14.4): anahtar ilk kez göründüğünde tek satır — "Anlam"
    // tek başına bir şey anlatmıyordu.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      TipOnce.show(
        context,
        ref.read(sharedPreferencesProvider),
        TipOnce.semanticSearch,
        context.l10n.tipSemanticSearch,
        sessionLimit: false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final on = widget.on;
    final onTap = widget.onTap;
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Tooltip(
      message: l10n.semanticSearchToggle,
      child: Semantics(
        toggled: on,
        button: true,
        label: l10n.searchModeMeaning,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: AnimatedContainer(
            key: const ValueKey('search-ai-toggle'),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: on ? scheme.primary : scheme.surface,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: on ? scheme.primary : scheme.outlineVariant,
              ),
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: BorderRadius.circular(9),
                onTap: onTap,
                child: Icon(
                  on ? Icons.auto_awesome : Icons.auto_awesome_outlined,
                  size: 18,
                  color: on ? scheme.onPrimary : scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
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

  AnimationController _ensurePulse() => _pulse ??= AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void didUpdateWidget(covariant _FocusHalo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focused && !oldWidget.focused) _scrolled = false;
    _maybeScroll();
    _syncPulse();
  }

  @override
  void initState() {
    super.initState();
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
    if (!pulse.isAnimating) pulse.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse?.dispose();
    super.dispose();
  }

  void _maybeScroll() {
    if (!widget.focused || _scrolled) return;
    _scrolled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = context.findRenderObject();
      if (box is! RenderBox || !box.attached) return;
      Scrollable.ensureVisible(
        context,
        alignment: 0.3,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (!widget.focused) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
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
          borderRadius: BorderRadius.circular(16),
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
          borderRadius: BorderRadius.circular(12),
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
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: l10n.quickCaptureHint,
                  hintStyle: TextStyle(
                    fontSize: 14.5,
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
                  icon: const Icon(Icons.check, size: 16),
                  label: Text(
                    l10n.quickCaptureSave,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
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

/// İki parmak oranından hedef sütun (F39.2): parmaklar açılınca (oran > 1)
/// kartlar büyür, sütun AZALIR. Her adım için parmak arası en az %25 değişir;
/// tek jestte 1 ↔ 4 arası gezilebilir.
int pinchTargetColumns(int base, double ratio) {
  if (ratio <= 0) return base;
  final steps = (math.log(ratio) / math.log(1.25)).truncate();
  return (base - steps).clamp(
    GridColumnsNotifier.minColumns,
    GridColumnsNotifier.maxColumns,
  );
}

/// **İKİ PARMAK ZOOM** (F39.2): jest boyunca ızgara yalnız ölçeklenir (tek
/// `Transform`, `RepaintBoundary` içinde, yerleşim YOK); hedef sütun köşede
/// küçük simgeyle görünür, bırakınca sütun TEK kez değişir + kısa oturma.
/// Ölçüm (v1.1.680): eskiden her adım tam yerleşim, kare 116–247 ms + "N sütun"
/// bildirimi. Ham [Listener]: jest yarışına girmez, tek parmak etkilenmez.
class PinchColumns extends StatefulWidget {
  const PinchColumns({
    super.key,
    required this.child,
    required this.columns,
    required this.onCommit,
  });

  final Widget child;
  final int columns;
  final ValueChanged<int> onCommit;

  @override
  State<PinchColumns> createState() => _PinchColumnsState();
}

class _PinchColumnsState extends State<PinchColumns>
    with SingleTickerProviderStateMixin {
  final _points = <int, Offset>{};
  final _target = ValueNotifier<int?>(null);
  late final AnimationController _scale = AnimationController.unbounded(
    vsync: this,
    value: 1,
  );
  double _base = 0;
  int _baseColumns = 2;
  Offset _focal = Offset.zero;
  Timer? _hide;

  @override
  void dispose() {
    _hide?.cancel();
    _target.dispose();
    _scale.dispose();
    super.dispose();
  }

  void _move() {
    if (_points.length != 2) return;
    final values = _points.values.toList();
    final distance = (values[0] - values[1]).distance;
    if (_base == 0) {
      if (distance < 24) return; // parmaklar üst üste: oran anlamsız
      _base = distance;
      _baseColumns = widget.columns;
      _focal = (values[0] + values[1]) / 2;
      _hide?.cancel();
      return;
    }
    final ratio = distance / _base;
    // İki parmakla düz kaydırma ızgarayı titretmesin.
    if (motionOf(context) && (ratio - 1).abs() > 0.03) {
      _scale.value = ratio.clamp(0.85, 1.15);
    }
    final target = pinchTargetColumns(_baseColumns, ratio);
    final shown = target == _baseColumns ? null : target;
    if (shown != _target.value) {
      _target.value = shown;
      unawaited(HapticFeedback.selectionClick());
    }
  }

  void _end({required bool commit}) {
    if (_base == 0) return;
    _base = 0;
    final target = _target.value;
    final changed = commit && target != null && target != widget.columns;
    if (changed) widget.onCommit(target);
    if (!changed) _target.value = null;
    _hide?.cancel();
    _hide = Timer(const Duration(milliseconds: 700), () {
      _target.value = null;
    });
    if (!motionOf(context)) {
      _scale.value = 1;
      return;
    }
    // Yeni sütunlarla hafif küçük/büyük başlar, yerine oturur.
    if (changed) _scale.value = target < _baseColumns ? 0.97 : 1.03;
    unawaited(
      _scale.animateTo(1, duration: AppMotion.short, curve: AppMotion.standard),
    );
  }

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: (e) {
      _points[e.pointer] = e.localPosition;
      _move();
    },
    onPointerMove: (e) {
      if (!_points.containsKey(e.pointer)) return;
      _points[e.pointer] = e.localPosition;
      _move();
    },
    onPointerUp: (e) {
      _points.remove(e.pointer);
      _end(commit: true);
    },
    onPointerCancel: (e) {
      _points.remove(e.pointer);
      _end(commit: false);
    },
    child: Stack(
      fit: StackFit.passthrough,
      children: [
        ClipRect(
          child: AnimatedBuilder(
            animation: _scale,
            builder: (context, child) => Transform(
              transform: Matrix4.diagonal3Values(_scale.value, _scale.value, 1),
              origin: _focal,
              child: child,
            ),
            child: RepaintBoundary(child: widget.child),
          ),
        ),
        PositionedDirectional(
          top: 10,
          end: 10,
          child: IgnorePointer(
            child: ValueListenableBuilder<int?>(
              valueListenable: _target,
              builder: (context, count, _) => count == null
                  ? const SizedBox.shrink()
                  : _ColumnsGlyph(count: count),
            ),
          ),
        ),
      ],
    ),
  );
}

/// Köşedeki kısa sütun simgesi: yazısız, N küçük dikey çubuk.
class _ColumnsGlyph extends StatelessWidget {
  const _ColumnsGlyph({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      label: context.l10n.gridColumnsCount(count),
      child: DecoratedBox(
        key: ValueKey('pinch-columns-$count'),
        decoration: BoxDecoration(
          color: tokens.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: tokens.hairline),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < count; i++) ...[
                if (i > 0) const SizedBox(width: 3),
                Container(
                  width: 6,
                  height: 18,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// **YANA KAYDIRARAK KLASÖR GEÇİŞİ** (F39.3): ızgara parmağı izler (tek
/// `Transform`, yeni kurulum yok), açılan kenarda sonraki durağın adı; eşik
/// (%22 genişlik ya da hızlı fiske) aşılınca geçer, aşılmazsa yerine döner.
/// Sonraki klasörün kartları BİLEREK çizilmez: jest sırasında ikinci ızgara
/// kurmak kaydırma bütçesini (AKICILIK) aşar; adı yeter.
class FolderSwipe extends StatefulWidget {
  const FolderSwipe({
    super.key,
    required this.enabled,
    required this.nextLabel,
    required this.onCommit,
    required this.child,
  });

  final bool enabled;

  /// Yön (+1 sonraki, -1 önceki) için durağın adı; yoksa null.
  final String? Function(int direction) nextLabel;
  final ValueChanged<int> onCommit;
  final Widget child;

  @visibleForTesting
  static const commitFraction = 0.22;

  @override
  State<FolderSwipe> createState() => _FolderSwipeState();
}

class _FolderSwipeState extends State<FolderSwipe>
    with SingleTickerProviderStateMixin {
  late final AnimationController _dx = AnimationController.unbounded(
    vsync: this,
  );
  int _direction = 0;
  String? _label;
  double _raw = 0;
  bool _past = false;
  double _labelMax = 140;

  @override
  void dispose() {
    _dx.dispose();
    super.dispose();
  }

  double get _width => (context.size?.width ?? 1).clamp(1, double.infinity);

  /// Fiziksel çekiş → yön (sağdan sola dillerde ters).
  int _directionOf(double dx) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return (rtl ? dx > 0 : dx < 0) ? 1 : -1;
  }

  void _update(DragUpdateDetails d) {
    _raw += d.primaryDelta ?? 0;
    if (_raw == 0) return;
    final direction = _directionOf(_raw);
    if (direction != _direction) {
      _direction = direction;
      _labelMax = _width * 0.36;
      setState(() => _label = widget.nextLabel(direction));
    }
    final limit = _width * 0.4;
    // Durak yoksa lastik: kısa ve dirençli.
    final follow = _label == null ? _raw * 0.25 : _raw;
    if (motionOf(context)) _dx.value = follow.clamp(-limit, limit);
    final past =
        _label != null && _raw.abs() >= _width * FolderSwipe.commitFraction;
    if (past != _past) {
      setState(() => _past = past);
      if (past) unawaited(HapticFeedback.selectionClick());
    }
  }

  void _finish(double velocity) {
    final fling = velocity.abs() >= 300 && velocity.sign == _raw.sign;
    final commit = _label != null && (_past || fling);
    final direction = _direction;
    setState(() {
      _label = null;
      _past = false;
      _direction = 0;
    });
    _raw = 0;
    if (commit) widget.onCommit(direction);
    if (_dx.value != 0) {
      unawaited(
        _dx.animateTo(0, duration: AppMotion.short, curve: AppMotion.standard),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = _label;
    final scheme = Theme.of(context).colorScheme;
    final tokens = AppTokens.of(context);
    final forwardEdge = _direction > 0;
    return GestureDetector(
      // Yatay çekişle filtreler/klasörler arasında gezin; dikey kaydırma
      // CustomScrollView'de kalır, eksenler farklı olduğundan yarışmaz.
      onHorizontalDragStart: widget.enabled ? (_) => _raw = 0 : null,
      onHorizontalDragUpdate: widget.enabled ? _update : null,
      onHorizontalDragEnd: widget.enabled
          ? (d) => _finish(d.primaryVelocity ?? 0)
          : null,
      onHorizontalDragCancel: widget.enabled ? () => _finish(0) : null,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          AnimatedBuilder(
            animation: _dx,
            builder: (context, child) => Transform.translate(
              offset: Offset(_dx.value, 0),
              child: child,
            ),
            child: widget.child,
          ),
          if (label != null)
            PositionedDirectional(
              top: 0,
              bottom: 0,
              start: forwardEdge ? null : 12,
              end: forwardEdge ? 12 : null,
              child: IgnorePointer(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: _labelMax),
                    child: DecoratedBox(
                      key: const ValueKey('swipe-next-label'),
                      decoration: BoxDecoration(
                        color: _past ? scheme.primaryContainer : tokens.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: tokens.hairline),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!forwardEdge)
                              Icon(
                                Icons.arrow_back,
                                size: 16,
                                color: _past
                                    ? scheme.onPrimaryContainer
                                    : scheme.onSurface,
                              ),
                            Flexible(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: Text(
                                  label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(
                                        color: _past
                                            ? scheme.onPrimaryContainer
                                            : scheme.onSurface,
                                      ),
                                ),
                              ),
                            ),
                            if (forwardEdge)
                              Icon(
                                Icons.arrow_forward,
                                size: 16,
                                color: _past
                                    ? scheme.onPrimaryContainer
                                    : scheme.onSurface,
                              ),
                          ],
                        ),
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

/// Ana ekranın sağ alt sütunundaki mikrofon düğmesi: dokunuş doğrudan
/// yazdırır (editörün alt çubuğundaki sade mikrofonla aynı simge), basılı
/// tutmak yapay zekâ ile sesli notu açar.
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
        child: Material(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            onLongPress: onLongPress,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, size: 24, color: scheme.onPrimaryContainer),
                // BASILI TUTMA ROZETİ (F14.4): basılı tutmak AI sesli notu
                // açar ama bu görünmüyordu. Köşedeki küçük ✨ "bu düğmenin
                // bir de AI yüzü var" der (ad ipucu ayrıntıyı söyler).
                if (onLongPress != null)
                  PositionedDirectional(
                    top: 5,
                    end: 5,
                    child: Icon(
                      Icons.auto_awesome,
                      key: const ValueKey('home-mic-ai-badge'),
                      size: 11,
                      color: scheme.primary,
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
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: alignment,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: ink, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: ink, fontWeight: FontWeight.w600),
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
        color: scheme.tertiaryContainer,
        ink: scheme.onTertiaryContainer,
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pendingUploadsProvider);
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    // Google hesabı ama Drive bağlanmadı: ekler bağlantı bekliyor — şerit
    // bunu söyler ve dokununca bağlar (kullanıcı isteği 2026-10-15).
    final needsDrive = state.needsDrive;
    final failing = state.failed > 0 && !needsDrive;
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      alignment: Alignment.topCenter,
      child: state.pending == 0
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.fromLTRB(kGridInset, 6, kGridInset, 0),
              child: Material(
                color: failing
                    ? scheme.errorContainer
                    : scheme.secondaryContainer,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: needsDrive
                      ? () => connectDrive(context, ref)
                      : () => ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showMessage(l10n.pendingUploadsInfo),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          needsDrive
                              ? Icons.add_to_drive_outlined
                              : failing
                              ? Icons.cloud_off_outlined
                              : Icons.cloud_upload_outlined,
                          size: 18,
                          color: failing
                              ? scheme.onErrorContainer
                              : scheme.onSecondaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            needsDrive
                                ? l10n.driveWaiting(state.pending)
                                : failing
                                ? l10n.pendingUploadsFailed(state.failed)
                                : l10n.pendingUploads(state.pending),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: failing
                                  ? scheme.onErrorContainer
                                  : scheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                        // Dönen çark YOK (bilerek): bağlantı yokken şerit
                        // saatlerce durabilir; sürekli animasyon pili yakardı.
                        Icon(
                          needsDrive ? Icons.link : Icons.info_outline,
                          size: 16,
                          color: failing
                              ? scheme.onErrorContainer
                              : scheme.onSecondaryContainer,
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

  void _reveal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Scrollable.ensureVisible(
        context,
        alignment: 0.5,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
