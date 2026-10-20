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
    final scheme = Theme.of(context).colorScheme;
    final frame = NoteColors.noteFrame(note);
    final title = note.title.trim();
    final preview = stripRichMarkers(note.toPlainText()).trim();
    return Material(
      color: NoteColors.noteSurface(context, note),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: frame ?? scheme.outlineVariant.withValues(alpha: 0.5),
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
                  Icon(Icons.push_pin, size: 13, color: scheme.primary),
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
                  fontSize: 11.5,
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
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
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
          feedback: Material(
            color: Colors.transparent,
            child: Opacity(
              opacity: 0.9,
              child: SizedBox(width: cellWidth, child: feedback),
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
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          Icon(Icons.search, size: 19, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
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
                hintText: semantic ? l10n.semanticSearchHint : l10n.searchHint,
                hintStyle: TextStyle(
                  fontSize: 13.5,
                  color: scheme.onSurfaceVariant,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
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
          _SemanticToggle(
            on: semantic,
            onTap: () =>
                ref.read(semanticSearchEnabledProvider.notifier).toggle(),
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
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.recentSearches,
                style: TextStyle(
                  fontSize: 11,
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
                  style: const TextStyle(fontSize: 11),
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

class _SemanticToggle extends StatelessWidget {
  const _SemanticToggle({required this.on, required this.onTap});

  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
    required this.noteId,
    required this.child,
  });

  final bool focused;
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
          border: Border.all(color: Colors.transparent, width: 2),
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
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
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

/// İki parmak "sıkıştırma" hareketini ARENAYA GİRMEDEN ölçen sarmalayıcı.
///
/// KÖK NEDEN (kullanıcı 2026-08-08: ana ekranda iki parmakla sütun değişimi
/// çalışmıyordu): eskiden bir `GestureDetector.onScaleUpdate` kullanılıyordu.
/// O tanıyıcı, altındaki kaydırma görünümünün dikey sürükleme tanıyıcısıyla
/// AYNI jest arenasında yarışır ve sürükleme İLK parmakta kabul edildiği için
/// çoğu zaman önce kazanır — ikinci parmak indiğinde iş işten geçmiş olur.
///
/// `Listener` arenaya hiç girmez: işaretçileri sessizce dinler, kaydırmayı
/// bozmaz ve iki parmak arasındaki uzaklık yeterince değişince haber verir.
/// (Aynı çözüm PDF metin seçim katmanında da kullanılıyor.)
class _PinchColumns extends StatefulWidget {
  const _PinchColumns({
    required this.child,
    required this.onStart,
    required this.onScale,
  });

  final Widget child;

  /// İkinci parmak indi: çağıran o anki sütun sayısını taban alır.
  final VoidCallback onStart;

  /// Taban uzaklığa göre O ANKİ oran (>1 = parmaklar açılıyor).
  /// **true dönerse bir adım atıldı** ve taban uzaklık şimdiki değere
  /// çekilir; yoksa oran eşiğin üstünde kaldığı sürece her karede bir adım
  /// daha atılır ve tek jestte en uca fırlanırdı.
  final bool Function(double scale) onScale;

  @override
  State<_PinchColumns> createState() => _PinchColumnsState();
}

class _PinchColumnsState extends State<_PinchColumns> {
  final _points = <int, Offset>{};

  /// İki parmak indiği andaki uzaklık; oran buna göre ölçülür. Çağıran bir
  /// adım attığında sıfırlanır ki aynı jestle 1 → 4 arası gezilebilsin.
  double _base = 0;

  void _recompute() {
    if (_points.length != 2) {
      _base = 0;
      return;
    }
    final values = _points.values.toList();
    final distance = (values[0] - values[1]).distance;
    if (_base == 0) {
      if (distance < 24) return; // parmaklar üst üste: ölçüm anlamsız
      _base = distance;
      widget.onStart();
      return;
    }
    if (widget.onScale(distance / _base)) _base = distance;
  }

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: (e) {
      _points[e.pointer] = e.position;
      _recompute();
    },
    onPointerMove: (e) {
      if (!_points.containsKey(e.pointer)) return;
      _points[e.pointer] = e.position;
      _recompute();
    },
    onPointerUp: (e) {
      _points.remove(e.pointer);
      _base = 0;
    },
    onPointerCancel: (e) {
      _points.remove(e.pointer);
      _base = 0;
    },
    child: widget.child,
  );
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
            child: Icon(icon, size: 24, color: scheme.onPrimaryContainer),
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
        icon: Icons.archive_outlined,
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
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
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
