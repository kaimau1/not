part of 'items_editor.dart';

/// İşaretli maddenin soluklaştırma oranı (eski satır opaklığı 0.55).
///
/// 0.55 → 0.8 (F15.6, 2026-10-31): 0.55'te üstü çizili madde metni açık
/// temada ~2,8:1'e düşüyordu (WCAG 4,5:1). Üstü çizgi + soluk ton "bitti"
/// demeye yine yetiyor.
const double _kCheckedDim = NoteCheckColors.checkedDim;

/// [color]ın alfasını [factor] ile çarpar — katmansız solma.
Color _dimmed(Color color, double factor) =>
    color.withValues(alpha: color.a * factor);

/// Madde satırının kurulumu: satır, bağlam menüsü, seçim çubuğu (C1, 2026-10-20: ItemsEditor konu dosyalarına bölündü).
extension _ItemsRow on ItemsEditorState {
  /// Öğe metni seçim araç çubuğu. Varsayılan araçlar (kes/kopyala/yapıştır ve
  /// "Tümünü seç") olduğu gibi korunur — böylece bir satırın metninin TAMAMI
  /// seçilebilir (madde 8; eskiden "Tümünü seç" seçim yerine panoya kopyalıyor,
  /// gerçek seçim ise kaldırılmıştı). Ayrıca ayrı bir "Tüm notu kopyala"
  /// seçeneği eklenir (alanlar arası gerçek seçim mümkün olmadığından tüm
  /// notu panoya almak için pratik karşılık).
  Widget _contextMenu(
    BuildContext context,
    EditableTextState editableState,
    NoteItem item,
  ) {
    final spell = spellContextMenu(context, editableState);
    if (spell != null) return spell;
    final l10n = context.l10n;
    final controller = _controllerFor(item);
    void commit() => _updateText(item, controller.logicalText);
    final own = [
      ContextMenuButtonItem(
        label: l10n.copyWholeNote,
        onPressed: () {
          editableState.hideToolbar();
          _copyAll();
        },
      ),
    ];
    final external = widget.selectionMenu;
    if (external != null) {
      return external(editableState, controller, commit, own);
    }
    final buttonItems = arrangeSelectionMenu(
      // Kes/Kopyala temiz-metin sürümü: varsayılanlar biçim işaretlerini ve
      // sarma çapalarını panoya HAM yazıyordu (gövdeyle aynı gerekçe).
      platform: cleanClipboardMenuItems(editableState),
      afterClipboard: [
        // Biçim (kalın/italik/altı çizili/renk) — gövde metniyle aynı yol.
        if (!editableState.textEditingValue.selection.isCollapsed)
          ContextMenuButtonItem(
            label: l10n.formatMenu,
            onPressed: () {
              editableState.hideToolbar();
              showFormatSheet(
                context,
                controller: controller,
                onApplied: commit,
              );
            },
          ),
      ],
      trailing: own,
    );
    return NoteSelectionToolbar(
      editableState: editableState,
      formatController: controller,
      onFormatCommit: commit,
      buttonItems: buttonItems,
    );
  }

  /// Düz çizimin (bkz. [_LazyItemField]) karşılayamadığı madde: ipucu, görsel
  /// çevresinde sarma, ek çipi, dokununca açılan bağlantı/damga/kaynak.
  bool _needsRealField(NoteItem item) {
    final text = item.text;
    return debugEagerItemFields ||
        text.trim().isEmpty ||
        // Yalnız metne SARILAN kutu gerçek alan ister; tam genişlik tablo/
        // görsel satırı bütünüyle iter (2026-11-24: yüzen tablolu 380
        // maddelik notta her madde gerçek alan kuruluyordu → donma).
        _inlineFloats ||
        widget.videoTimestamps ||
        text.contains('📎') ||
        text.contains('📖') ||
        // Bağlantının (e-posta, alan adı, şema) hepsinde nokta var; regex'siz ön süzgeç.
        (text.contains('.') && findLinks(text).isNotEmpty);
  }

  Widget _itemRow(NoteItem item, {bool draggable = false}) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final controller = _controllerFor(item);
    final plainStyle =
        widget.textStyle ?? theme.textTheme.bodyLarge ?? const TextStyle();
    // ARA BAŞLIK (bkz. [NoteItem.header]): kalın, biraz büyük, notun vurgu
    // renginde; kutucuk/numara yok.
    final baseStyle = item.header
        ? plainStyle.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: (plainStyle.fontSize ?? 16) * 1.15,
            color: _accent?.accent ?? plainStyle.color,
          )
        : plainStyle;
    // Numaralı listede de işaretli madde soluk + üstü çizili (numara yerine
    // ✓ — bkz. [itemOrderNumber]).
    final checked = item.checked && !item.header;
    final textAlign = !item.header
        ? TextAlign.start
        : switch (item.align) {
            NoteItem.alignCenter => TextAlign.center,
            NoteItem.alignEnd => TextAlign.end,
            _ => TextAlign.start,
          };
    final selected = _selected.contains(item.id);
    // Odak durumu SATIRIN KENDİ dinleyicisinden gelir (bkz. [_focusFlags]).
    _focusFor(item);
    final focusFlag = _focusFlagFor(item.id);

    // Sürükleme tutamacı YALNIZ "Seç" modunda görünür.
    //
    // Normalde her satırın başında duran 6 nokta yer kaplıyor, metni içeri
    // itiyor ve ne işe yaradığı görünmüyordu (sürüklemek için ayrıca uzun
    // basmak gerekiyordu). Seç modu zaten "satırlarla toplu iş yap" kipi;
    // sıralama da oraya taşındı. Orada uzun basış SEÇİM demek olduğundan
    // tutamaç gecikmesiz sürükler (ReorderableDragStartListener) ve seçim
    // jestlerinin DIŞINDA durur — üstüne dokunmak öğeyi seçmez.
    //
    // **HİZA** (kullanıcı bulgusu 2026-09-01: "işaretli yer hizasız oluyor
    // seç aktifken"): tutamaç yalnız SÜRÜKLENEBİLİR satırlarda vardı, ama
    // seçim kipinde ekranda sürüklenemeyen satırlar da duruyor —
    // checklist'in İŞARETLİ maddeleri listenin dışında, footer'da çiziliyor
    // (bkz. [build] → `checkedItems`) ve iki sütun kipinde hiçbir satır
    // sürüklenmiyor. Tutamacı olmayan satırın seçim yuvarlağı 22 dp solda
    // kalıyor, aynı ekranda iki farklı sol kenar oluyordu. Artık seçim
    // kipinde yuva HER satırda ayrılır; sürüklenemeyen satırda boş kalır.
    final Widget? dragHandle = !_showHandles
        ? null
        : SizedBox(
            width: ItemsEditorState._kHandleWidth,
            child: !draggable
                ? null
                : GestureDetector(
                    // Tutamağa dokunmak SEÇMEZ (satırın seçim dokunuşu
                    // dışında kalır); sürükleme dinleyicisi etkilenmez.
                    onTap: () {},
                    // Dizin [_RowSlot]'tan: yer değişince yalnız bu kurulur.
                    child: Builder(
                      builder: (context) => ReorderableDragStartListener(
                        index: _RowSlot.of(context)?.reorderIndex ?? 0,
                        child: Icon(
                          Icons.drag_indicator,
                          size: ItemsEditorState._kHandleIcon,
                          color: scheme.onSurfaceVariant.withValues(
                            alpha: AppAlpha.muted,
                          ),
                        ),
                      ),
                    ),
                  ),
          );

    // Sol bölge (kutucuk/numara/seçim yuvarlağı); jestleri satırda
    // sarılır (bkz. [rowBody]).
    //
    // **SEÇİM YUVARLAĞI** (kullanıcı bulgusu 2026-10-20: "maddeler seçilirken
    // yuvarlağın üzerine tıklayınca seçilmiyor gibi, yazının üzerine
    // tıklarsam seçiliyor"). KÖK NEDEN: dokunuşu yalnız 22 dp'lik SİMGE
    // alıyordu — çevresindeki dolgu ve üst pay hit-test'e girmiyordu
    // (varsayılan `deferToChild`), parmak yuvarlağın kenarına düşünce dokunuş
    // boşa gidiyordu. Bölge artık OPAK ve üst payı da kapsıyor (bkz.
    // `leadingTop` sarmalayıcısı); seçim kipinde satırın kalanı da seçer
    // (bkz. [rowBody]).
    final leading = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_selectionMode)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            // Seçim anında yuvarlak kısa bir "dolma" yapar — dokunuşun
            // alındığı parmağın altında görünsün.
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: Tween<double>(begin: 0.6, end: 1).animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                key: ValueKey(selected),
                size: 22,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ),
          )
        else if (item.header)
          // Ara başlık: kutucuk yerinde soluk bir işaret — yazı maddelerle
          // aynı hizada başlar, uzun basış menüsü (maddeye çevir) bulunur.
          SizedBox(
            key: ValueKey('item-header-${item.id}'),
            width: 40,
            height: 18,
            child: Icon(
              Icons.segment,
              size: AppIconSize.s,
              color: (_accent?.accent ?? scheme.onSurfaceVariant).withValues(
                alpha: AppAlpha.muted,
              ),
            ),
          )
        else if (widget.showCheckboxes)
          // Tık anında kutu kısa bir "zıplama" yapar — dokunuşun
          // alındığını parmağın altında gösterir (bkz. [_CheckPop]).
          _CheckPop(
            value: item.checked,
            child: Checkbox(
              value: item.checked,
              // Ekran okuyucu: madde metni + durum (F15.2) — kutu adsızdı.
              semanticLabel: item.text.trim().isEmpty
                  ? context.l10n.itemEmptyLabel
                  : stripRichMarkers(item.text).trim(),
              // Soluk işaretli kutu (satır katmanı yok — bkz. [_kCheckedDim]).
              // Renk KARTLA AYNI kural (bkz. [NoteCheckColors]): renkli notta
              // notun koyu tonu, renksizde temanın vurgusu.
              fillColor: checked
                  ? WidgetStatePropertyAll(
                      NoteCheckColors.checked(scheme, _accent?.accent),
                    )
                  : null,
              checkColor: _accent == null
                  ? null
                  : NoteCheckColors.mark(
                      scheme,
                      _accent!.accent,
                      _accent!.background,
                    ),
              side: checked
                  ? BorderSide.none
                  : (_accent?.accent == null
                        ? null
                        : BorderSide(color: _accent!.accent!, width: 2)),
              // Kutunun KENDİ kutusu 48 dp'lik dokunma hedefinden 40 dp'ye
              // iner: 48 dp'lik kutu ilk satırın ortasından her zaman daha
              // aşağıda kalıyordu (bkz. [leadingTop] — "madde kutuları
              // yazıdan biraz altta" kök nedeni). 40 dp hem hizalanabiliyor
              // hem de dokunulabilir bir hedef olarak kalıyor.
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              // Defterde kutu tek satırın bandına sığar (24 dp), çizgilerin
              // arasında durur.
              visualDensity: widget.paperLines
                  ? const VisualDensity(horizontal: -4, vertical: -4)
                  : null,
              // Boş satırın kutusu PASİF: dokunulunca hiçbir şey olmadığını
              // görmek, işaretlenip alta düşen boş bir maddeyi geri almaktan
              // iyidir (bkz. _toggleItem). Zaten işaretliyse etkin kalır ki
              // eski notlardaki boş işaretli satır geri alınabilsin.
              onChanged: (item.text.trim().isEmpty && !item.checked)
                  ? null
                  : (value) => _toggleItem(item, value),
            ),
          )
        else if (checked)
          // NUMARALI LİSTEDE İŞARETLİ (kullanıcı bulgusu 2026-11-16): numara
          // yerine ✓; dokununca işaret kalkar ve madde yeniden numaralanır.
          Semantics(
            button: true,
            label: context.l10n.itemUncheck,
            child: InkResponse(
              key: ValueKey('item-done-${item.id}'),
              radius: 20,
              onTap: () => _toggleItem(item, false),
              child: SizedBox(
                width: 40,
                height: 24,
                child: Icon(
                  Icons.check_rounded,
                  size: AppIconSize.m,
                  color: NoteCheckColors.checked(scheme, _accent?.accent),
                ),
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            // Numara [_RowSlot]'tan: yer değişince yalnız bu metin kurulur.
            child: Builder(
              builder: (context) => Text(
                '${_RowSlot.of(context)?.orderNumber ?? 0}.',
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          ),
      ],
    );

    // **KUTUCUK/NUMARA HİZASI** (kullanıcı bulgusu: "madde boxları tam
    // hizalı değil, biraz altta kalıyor yazıdan").
    //
    // KÖK NEDEN: satır `CrossAxisAlignment.start` ile diziliyor (çok satırlı
    // maddede kutu İLK satıra hizalanmalı, satırın ortasına değil) ve kutuya
    // sabit 4 dp'lik bir üst pay veriliyordu. Oysa iki öğenin yüksekliği
    // farklı: `TextField`in ilk satırının ortası `contentPadding.top` (10) +
    // satır yüksekliğinin yarısı kadar aşağıda, `Checkbox`ın ortası ise kendi
    // kutusunun (48 dp) yarısı kadar. 16 punto yazıda bu 19.6'ya karşı 24 dp
    // demek — kutu her zaman yaklaşık 4 dp AŞAĞIDA kalıyordu ve sabit pay
    // farkı büyütüyordu.
    //
    // Çözüm iki parçalı: kutunun kendi kutusu 40 dp'ye indirildi (yukarıda)
    // ve üst pay artık SABİT değil, "ilk satırın ortası − öğenin yarısı"
    // olarak HESAPLANIYOR. Yazı tipi/boyutu ve sistem yazı ölçeği değişince
    // hiza kendiliğinden korunur.
    final fontSize = MediaQuery.textScalerOf(context)
        .scale(baseStyle.fontSize ?? 16);
    // `height` verilmemişse yazı tipinin kendi satır yüksekliği geçerli;
    // Roboto ve benzerlerinde bu ~1.2 katıdır.
    final lineHeight = fontSize * (baseStyle.height ?? 1.2);
    // TextField `contentPadding: vertical` [fieldPad] ile kuruluyor (aşağıya
    // bak). Defter görünümünde dolgu YOK: madde satırı tam satır sayısı ×
    // çizgi aralığı, maddeler defterdeki gibi ARDIŞIK çizgilere yazılır
    // (yarım satır dolguda her maddenin arasında boş bir bant kalıyordu).
    final fieldPad = widget.paperLines ? 0.0 : 10.0;
    final firstLineCenter = fieldPad + lineHeight / 2;
    final leadingHeight = _selectionMode
        ? 22.0
        : item.header
        ? 18.0
        : (widget.showCheckboxes
              ? (widget.paperLines ? 24.0 : 40.0)
              : (checked ? 24.0 : lineHeight));
    final leadingTop = math.max(0.0, firstLineCenter - leadingHeight / 2);
    // **TUTAMAÇ HİZASI** (kullanıcı bulgusu 2026-09-01, ekran görüntüsüyle:
    // "6 nokta ile seçim işareti hâlâ hizasız").
    //
    // KÖK NEDEN: bir önceki tur tutamacın YUVASINI her satırda ayırdı (sol
    // kenarlar hizalandı) ama tutamacın kendisi satırın Row'una DOĞRUDAN
    // konuyordu. Satır `CrossAxisAlignment.start` ile diziliyor, yani 20
    // dp'lik simge satırın en üstüne yapışıyor; yanındaki seçim yuvarlağı
    // ise [leadingTop] kadar aşağıda. İkisi aynı satırda ama farklı
    // yükseklikte duruyordu — kullanıcının gördüğü hizasızlık buydu.
    //
    // Çözüm yuvarlağınkiyle AYNI hesap: "ilk satırın ortası − simgenin
    // yarısı". Yazı tipi/boyutu ve sistem yazı ölçeği değişse de ikisi
    // birlikte kayar.
    final handleTop = math.max(
      0.0,
      firstLineCenter - ItemsEditorState._kHandleIcon / 2,
    );

    // Seçim kipinde satırın HER YERİ seçer (sağdaki boş pay dahil).
    // Sarmalayıcı koşulsuz — ağacın şekli kiple değişirse TextField'ın
    // state'i sıfırlanır. İçteki dokunuşlar (yuvarlak, metin) önce kazanır;
    // tutamaç kendi dokunuşunu yutar ki sürüklemeye dokunmak seçmesin.
    // Opaklık YALNIZ seçim kipinde: normalde satırın boş yerleri arkadaki
    // yüzen görsellere dokunuşu geçirmeye devam etsin.
    Widget rowBody(bool focused) => GestureDetector(
      behavior: _selectionMode
          ? HitTestBehavior.opaque
          : HitTestBehavior.deferToChild,
      onTap: _selectionMode ? () => _toggleSelection(item) : null,
      child: _DividerReveal(
        raw: item.divider,
        color: (_accent?.accent ?? scheme.primary).withValues(
          alpha: kItemDividerAccentAlpha,
        ),
        child: _selectedBackdrop(
          selected,
          scheme,
          Padding(
            // Tutamak hep görünürken (web/tablet) soldaki 12 dp boşluğa
            // yerleşir: yazı neredeyse yerinde kalır.
            padding: EdgeInsetsDirectional.only(
              start: _pinHandles && !_selectionMode ? 2 : 12,
              end: 2,
            ),
            // İşaretli satırın soluk hâli KATMANSIZ: yazı, kutucuk ve yıldız
            // kendi renklerinde soluk çizilir (bkz. [_kCheckedDim]).
            //
            // KÖK NEDEN (kullanıcı bulgusu 2026-10-30: "işaretli öğesi çok
            // olanlarda daha fazla kasma — açıkken, açılıp kapanırken,
            // kaydırırken"): satır `AnimatedOpacity(0.55)` ile sarılıydı; 1'den
            // küçük opaklık KALICI bir `OpacityLayer` demek, yani her işaretli
            // madde her karede ayrı bir saveLayer ile rasterleşiyordu. 80
            // işaretli maddede kaydırma ve not geçişi kare başına 80 katman
            // birleştiriyordu. Solma artık rengin alfasında, bedeli sıfır.
            child: Stack(
              children: [
                Row(
                  // Çok satırlı maddelerde kutucuk/numara artık tüm satır
                  // yüksekliğine göre ORTALANMIYOR, ilk satıra hizalanıyor
                  // (kullanıcı isteği). Üst pay [leadingTop] ile HESAPLANIR — bkz.
                  // orada anlatılan hiza kök nedeni.
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (dragHandle != null)
                      Padding(
                        padding: EdgeInsets.only(top: handleTop),
                        child: dragHandle,
                      ),
                    // Sol bölgenin jestleri. Uzun basış SATIR MENÜSÜNÜ açar (yıldız,
                    // seç, sil): metin alanına uzun basmak Android'in kendi metin
                    // seçimini açtığı için madde jestleri buraya bağlandı, ikisi
                    // çakışmaz. Seçim kipinde dokunuş ve uzun basış doğrudan seçer.
                    // OPAK ve üst payı da kapsar (bkz. [leading] kök neden notu).
                    // Builder: menü satırın KENDİ kutusunu bulsun (F12.7 —
                    // hedef madde vurgulanır, menü maddenin altında açılır).
                    Builder(
                      builder: (leadContext) => _itemRightClick(
                        item,
                        anchor: leadContext,
                        child: GestureDetector(
                          behavior: _selectionMode
                              ? HitTestBehavior.opaque
                              : HitTestBehavior.deferToChild,
                          onLongPressStart: (details) {
                            if (_selectionMode) {
                              _toggleSelection(item);
                            } else {
                              _showItemMenu(
                                item,
                                details.globalPosition,
                                anchor: leadContext,
                              );
                            }
                          },
                          onTap: _selectionMode
                              ? () => _toggleSelection(item)
                              : null,
                          child: Padding(
                            padding: EdgeInsets.only(top: leadingTop),
                            child: leading,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      // Seçim modunda metne dokunmak düzenlemeye değil seçime gider.
                      // Basılı tutmaya devam → madde seçimi (F60.S6); sarmalayıcı
                      // koşulsuz (ağaç şekli kiple değişmez).
                      child: _HoldToSelect(
                        enabled: !_selectionMode,
                        onText: () => _holdSelectText(item),
                        onHold: () => _holdSelect(item),
                        child: _itemRightClick(
                          item,
                          child: GestureDetector(
                            onTap: _selectionMode
                                ? () => _toggleSelection(item)
                                : null,
                            child: AbsorbPointer(
                              absorbing: _selectionMode,
                              child: _wrapped(
                                controller,
                                baseStyle,
                                textTop: fieldPad,
                                // **ÜSTÜ ÇİZİLİ GEÇİŞ** (kullanıcı isteği 2026-09-22:
                                // "liste maddeleri tıklanma geçiş animasyonu"). Çizgi
                                // eskiden anında beliriyordu; artık çizginin ve yazının
                                // rengi soluk hâle AKAR. `end` yalnız verildiği için ilk
                                // kurulumda animasyon oynamaz (eski işaretli madde açılışta
                                // yeniden çizilmez), yalnız DEĞİŞİMDE oynar.
                                TweenAnimationBuilder<double>(
                                  tween: Tween<double>(end: checked ? 1 : 0),
                                  duration: _kStrikeDuration,
                                  curve: AppMotion.emphasized,
                                  builder: (context, strike, _) {
                                    // Solma AnimatedOpacity'e bırakıldı (aşağıya bak);
                                    // burada alfa verilirse iki kez soluyor.
                                    final dim = 1 - (1 - _kCheckedDim) * strike;
                                    final fieldStyle = strike == 0
                                        ? baseStyle
                                        : baseStyle.copyWith(
                                            decoration:
                                                TextDecoration.lineThrough,
                                            decorationColor:
                                                Color.lerp(
                                                  Colors.transparent,
                                                  scheme.onSurfaceVariant,
                                                  strike,
                                                )!.withValues(
                                                  alpha: strike * _kCheckedDim,
                                                ),
                                            decorationThickness: 1 + strike,
                                            color: _dimmed(
                                              Color.lerp(
                                                baseStyle.color ??
                                                    scheme.onSurface,
                                                scheme.onSurfaceVariant,
                                                strike,
                                              )!,
                                              dim,
                                            ),
                                          );
                                    // Dokunuşun konumu tutulur (etiket önizlemesi,
                                    // bkz. _tapAttachmentTag); sarmalayıcı HEP ağaçta.
                                    // Gömülü yazı çip olarak çizilir (gövdeyle aynı).
                                    final field = _LazyItemField(
                                      controller: controller,
                                      focusNode: _focusFor(item),
                                      style: fieldStyle,
                                      textAlign: textAlign,
                                      strut: wrapStrutStyle(fieldStyle),
                                      verticalPad: fieldPad,
                                      maxLines: widget.expandItems || focused
                                          ? null
                                          : 1,
                                      eager: _needsRealField(item),
                                      field: AttachmentTagChips(
                                        controller: controller,
                                        looks: widget.tagLooks,
                                        done: item.checked,
                                        child: _tapPoint.wrap(
                                          // Klavyenin otomatik düzeltmesi uygulamanın
                                          // kipine bağlı (gövdeyle aynı, 2026-11-25).
                                          ValueListenableBuilder<bool>(
                                            valueListenable: AutoSpell.enabled,
                                            builder: (_, autoFix, _) =>
                                                TextField(
                                                  controller: controller,
                                                  focusNode: _focusFor(item),
                                                  autocorrect: autoFix,
                                                  onChanged: (_) => _updateText(
                                                    item,
                                                    controller.logicalText,
                                                  ),
                                                  contextMenuBuilder:
                                                      (
                                                        context,
                                                        editableState,
                                                      ) => _contextMenu(
                                                        context,
                                                        editableState,
                                                        item,
                                                      ),
                                                  contentInsertionConfiguration:
                                                      widget.contentInsertion,
                                                  // Varsayılan "next" davranışı odağı metin dışı bir
                                                  // öğeye taşıyıp klavyeyi kapatıp açıyordu;
                                                  // onEditingComplete onu bastırır, odak doğrudan
                                                  // yeni öğeye geçer.
                                                  onEditingComplete: () =>
                                                      _enterAt(item),
                                                  textInputAction:
                                                      TextInputAction.next,
                                                  // EK ETİKETİNE DOKUNUNCA ÖNİZLEME — gövdedekiyle
                                                  // aynı kural (bkz. note_editor_screen `bodyField`):
                                                  // düzenlenebilir alanda span'e tanıyıcı bağlanamaz
                                                  // (dokunuş imleci taşımak için EditableText'e
                                                  // gider), bu yüzden dokunuştan SONRA imlecin
                                                  // nereye düştüğüne bakılır.
                                                  onTap: () {
                                                    _tapAttachmentTag(
                                                      controller,
                                                      context,
                                                    );
                                                    // Altı çizili kelime: öneri menüsü (Y-4).
                                                    showSpellMenuAfterTap(
                                                      editableTextBelow(
                                                        context,
                                                      ),
                                                    );
                                                  },
                                                  // Tam göster modunda satır sarılıp büyür; "dokununca
                                                  // aç" modunda odaklanınca açılır, aksi hâlde tek satır.
                                                  maxLines:
                                                      widget.expandItems ||
                                                          focused
                                                      ? null
                                                      : 1,
                                                  // Sarma planı bu stille hesaplanır; TextField'ın örtük
                                                  // varsayılanına bırakılırsa ölçüm ile çizim ayrışır ve
                                                  // satırlar yanlış kırılır (M3 varsayılanı bodyLarge).
                                                  style: fieldStyle,
                                                  textAlign: textAlign,
                                                  // Satır yüksekliği çıpası gövdeyle aynı yerden
                                                  // gelir (bkz. [wrapStrutStyle]): ölçüm ile çizim
                                                  // ayrışmasın.
                                                  strutStyle: wrapStrutStyle(
                                                    fieldStyle,
                                                  ),
                                                  decoration: InputDecoration(
                                                    // Boş maddenin ipucu "Madde yaz" (F12.7):
                                                    // altındaki "+ Yeni öğe" düğmesiyle aynı
                                                    // adı taşıyınca iki "Yeni öğe" görünüyordu.
                                                    hintText: item.header
                                                        ? l10n.itemHeaderHint
                                                        : l10n.itemEmptyHint,
                                                    filled: false,
                                                    border: InputBorder.none,
                                                    isDense: true,
                                                    contentPadding:
                                                        EdgeInsets.symmetric(
                                                          vertical: fieldPad,
                                                        ),
                                                  ),
                                                ),
                                          ),
                                          // Damgaya/etikete dokunmak klavyeyi açmaz.
                                          focusNode: _focusFor(item),
                                          keepsKeyboardClosed: (global) =>
                                              linkAtPoint(
                                                editable: editableTextBelow(
                                                  context,
                                                ),
                                                displayText: controller.text,
                                                global: global,
                                                timestamps:
                                                    widget.videoTimestamps &&
                                                    widget.onVideoTimestamp !=
                                                        null,
                                                tagNames:
                                                    widget.onAttachmentTag ==
                                                        null
                                                    ? const []
                                                    : widget.attachmentNames,
                                              ),
                                        ),
                                      ),
                                    );
                                    // Tek satır kipinde taşan metnin "devamı var"
                                    // göstergesi: TextField kırpar ama üç nokta koyamaz
                                    // (kaydırılabilir alan), kullanıcı metnin bittiğini
                                    // sanıyordu. Taşma ölçülür, taşıyorsa alanın hemen
                                    // sağına "…" konur; odaklanınca satır zaten açılır.
                                    //
                                    // KÖK NEDEN (imleç görünmüyordu) — ağacın ŞEKLİ
                                    // odakla DEĞİŞMEMELİ: eskiden odaksızken
                                    // `LayoutBuilder > Row > Expanded > TextField`,
                                    // odaklanınca çıplak `TextField` dönüyordu. Dokunuş
                                    // odağı verir, gelen yeniden çizimde alanın öğesi
                                    // BAŞKA bir konuma düştüğü için TextField'ın state'i
                                    // (ve içindeki EditableText) sıfırdan kuruluyordu;
                                    // yeni state odağı ZATEN almış bir düğümle açıldığı
                                    // için "odak değişti" olayı hiç gelmiyor ve imlecin
                                    // yanıp sönme zamanlayıcısı başlamıyordu — imleç
                                    // ancak ilk harfte beliriyordu. Yalnız "tam göster"
                                    // (odaktan bağımsız) sarmalayıcıyı belirler; odak
                                    // artık yalnız "…"in görünürlüğünü değiştirir.
                                    if (widget.expandItems) return field;
                                    return LayoutBuilder(
                                      builder: (context, constraints) {
                                        final overflowing =
                                            !focused &&
                                            constraints.maxWidth.isFinite &&
                                            _overflowsLine(
                                              context,
                                              item.id,
                                              controller.text,
                                              fieldStyle,
                                              constraints.maxWidth,
                                            );
                                        return Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.baseline,
                                          textBaseline: TextBaseline.alphabetic,
                                          children: [
                                            Expanded(child: field),
                                            if (overflowing)
                                              Text(
                                                '…',
                                                style: fieldStyle.copyWith(
                                                  color:
                                                      scheme.onSurfaceVariant,
                                                ),
                                              ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // YILDIZ ARTIK DÜĞME DEĞİL, İŞARET (kullanıcı isteği 2026-08-30:
                    // "yıldızla tuşu maddeler için yerleşimi kötü, basılı tutunca
                    // gelsin"). Eskiden satır odaklanınca boş bir yıldız düğmesi
                    // beliriyor, metni daraltıyor ve silme "x"ini içeri itiyordu —
                    // yazarken satır her odakta yatayda oynuyordu. Yıldızlama sol
                    // bölgeye uzun basınca açılan menüde ([_showItemMenu]); burada
                    // yalnız YILDIZLI satırın işareti durur (dokununca kalkar).
                    // Hatırlatıcı çipi İLK YAZI SATIRININ ORTASINA hizalı
                    // (kullanıcı isteği 2026-11-08: "satırdaki yazıyla tam hizalı
                    // olmalı" — satırın tepesine yapışıyordu). Çip sabit 22 dp.
                    if (!_selectionMode && widget.lineTrailing != null)
                      Padding(
                        padding: EdgeInsets.only(
                          top: math.max(0.0, firstLineCenter - 11),
                        ),
                        child: widget.lineTrailing!(item),
                      ),
                    if (!_selectionMode && item.starred)
                      IconButton(
                        tooltip: l10n.unstar,
                        icon: const Icon(Icons.star, size: AppIconSize.s),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 26,
                          height: 34,
                        ),
                        color: checked
                            ? _dimmed(scheme.tertiary, _kCheckedDim)
                            : scheme.tertiary,
                        onPressed: () => _toggleStar(item),
                      ),
                    // SİL "x" (2026-10-30 ikinci tur: "madde silme butonu
                    // kaybolmuş"): odaklı maddede HEP görünür, ama SABİT ve dar
                    // bir sütunda (40 → 28 dp) — odak değişince satırın genişliği
                    // değişmez, yazı itilmez. Düğme sütunun içinde yüzer.
                    const SizedBox(width: ItemsEditorState._kTrailingWidth),
                  ],
                ),
                if (focused && !_selectionMode)
                  PositionedDirectional(
                    end: 0,
                    // İlk satırın ortasına hizalı (kutucukla aynı çizgide).
                    // 2026-11-01 (kullanıcı isteği: "silme x'ini 2 punto küçült,
                    // hitbox'ını da daralt"): simge 20 → 18, dokunma alanı
                    // 30×36 → 24×28 — yazının sonuna dokunurken madde kazara
                    // silinmesin.
                    top: math.max(0.0, firstLineCenter - 14),
                    // WEB'DE × İŞLEMİYORDU (kullanıcı bulgusu 2026-11-10): fare
                    // basışı "alan dışı" sayılıp odağı düşürüyor, × bırakmadan
                    // önce kayboluyordu (dokunmatikte alan dışı odağı bırakmaz).
                    // Bölge alanın parçası sayılır: basış odağı korur.
                    child: TextFieldTapRegion(
                      child: IconButton(
                        key: ValueKey('item-remove-${item.id}'),
                        tooltip: l10n.removeItem,
                        icon: const Icon(Icons.close, size: AppIconSize.s),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: ItemsEditorState._kTrailingWidth - 4,
                          height: 28,
                        ),
                        style: const ButtonStyle(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                        onPressed: () => _removeItem(item),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    return KeyedSubtree(
      key: ValueKey(item.id),
      // Yer değiştirme geçişi: eski yerinde katlanıp kaybolur, yeni yerinde
      // açılarak belirir (bkz. [_CheckMove]). Sarmalayıcı KOŞULSUZ — ağacın
      // şekli evreye göre değişseydi TextField'ın state'i sıfırlanırdı.
      child: _CheckMove(
        phase: _movePhase(item.id),
        child: _floatRow(
          id: item.id,
          // Görsel maddenin ilk satırından aşağıda başlıyorsa satır kaymaz;
          // yalnız o hizadaki satırlar sarılır (bkz. `_wrapped`). İç dolgu
          // (`fieldPad`) iki katmanın sınırında ölü bölge bırakmasın diye eklenir.
          inlineBelow:
              fieldPad + ItemsEditorState.itemLineHeight(context, baseStyle),
          // Satırın metne AYRILAMAYAN payı: yatay dolgu + tutamaç + kutucuk/
          // numara + sil düğmesinin yeri. Sarma kararı bu pay düşülerek
          // verilmeli (bkz. _FloatRow.reserved).
          reserved:
              ItemsEditorState._kRowPadding +
              (_showHandles ? ItemsEditorState._kHandleWidth : 0) -
              (_pinHandles && !_selectionMode ? 10 : 0) +
              ItemsEditorState._kLeadingWidth +
              ItemsEditorState._kTrailingWidth,
          // Odak DEĞİŞİMİ yalnız bu satırı yeniden çizer (bkz. [_focusFlags]).
          // Sarmalayıcı KOŞULSUZ duruyor: ağacın şekli odakla değişemez —
          // değişirse TextField'ın state'i sıfırdan kurulur ve imleç ilk harfe
          // kadar yanıp sönmez (aşağıdaki kök neden notu).
          ValueListenableBuilder<bool>(
            valueListenable: focusFlag,
            builder: (context, focused, _) => rowBody(focused),
          ),
        ),
      ),
    );
  }

  /// Ekranın dibine demirlenmiş Bento madde seçim çubuğu (Overlay çocuğu).
  Widget _selectionBar(BuildContext context) {
    final selectedItems = [
      for (final i in _items)
        if (_selected.contains(i.id)) i,
    ];
    return _ItemSelectionBar(
      selectedCount: _selected.length,
      totalCount: _items.length,
      showCheckboxes: widget.showCheckboxes,
      allSelected: _items.isNotEmpty && _selected.length == _items.length,
      allChecked:
          selectedItems.isNotEmpty && selectedItems.every((i) => i.checked),
      allPackaged:
          selectedItems.isNotEmpty &&
          selectedItems.every((i) => i.package.isNotEmpty),
      canRangeSelect: _canRangeSelect,
      onExit: _exitSelection,
      onSelectAll: _toggleSelectAll,
      onRangeSelect: _rangeSelect,
      onInvert: _invertSelection,
      onCheck: _checkSelected,
      onCopy: _copySelected,
      onCopyAndCheck: _copyAndCheckSelected,
      onBatchFormat: _batchApplyFormat,
      onBatchHeader: _batchToggleHeader,
      onBatchDivider: _batchToggleDivider,
      onPackage: togglePackage,
      onDelete: _deleteSelected,
    );
  }

  /// Seçili satırın zemini; seçili değilse EK düzen nesnesi kurulmaz.
  Widget _selectedBackdrop(bool selected, ColorScheme scheme, Widget child) =>
      selected
      ? DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.primaryContainer.withValues(alpha: AppAlpha.soft),
            borderRadius: BorderRadius.circular(AppRadius.m),
          ),
          child: child,
        )
      : child;
}
