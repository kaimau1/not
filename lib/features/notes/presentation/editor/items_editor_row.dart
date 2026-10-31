part of 'items_editor.dart';

/// İşaretli maddenin soluklaştırma oranı (eski satır opaklığı 0.55).
const double _kCheckedDim = 0.55;

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
    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: editableState.contextMenuAnchors,
      buttonItems: buttonItems,
    );
  }

  Widget _itemRow(NoteItem item, {int? reorderIndex, int? orderNumber}) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final controller = _controllerFor(item);
    final baseStyle =
        widget.textStyle ?? theme.textTheme.bodyLarge ?? const TextStyle();
    final checked = widget.showCheckboxes && item.checked;
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
    final Widget? dragHandle = !_selectionMode
        ? null
        : SizedBox(
            width: ItemsEditorState._kHandleWidth,
            child: reorderIndex == null
                ? null
                : GestureDetector(
                    // Tutamağa dokunmak SEÇMEZ (satırın seçim dokunuşu
                    // dışında kalır); sürükleme dinleyicisi etkilenmez.
                    onTap: () {},
                    child: ReorderableDragStartListener(
                      index: reorderIndex,
                      child: Icon(
                        Icons.drag_indicator,
                        size: ItemsEditorState._kHandleIcon,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
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
        else if (widget.showCheckboxes)
          // Tık anında kutu kısa bir "zıplama" yapar — dokunuşun
          // alındığını parmağın altında gösterir (bkz. [_CheckPop]).
          _CheckPop(
            value: item.checked,
            child: Checkbox(
              value: item.checked,
              // Soluk işaretli kutu (satır katmanı yok — bkz. [_kCheckedDim]).
              fillColor: checked
                  ? WidgetStatePropertyAll(
                      _dimmed(scheme.primary, _kCheckedDim),
                    )
                  : null,
              side: checked ? BorderSide.none : null,
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
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '${orderNumber ?? 0}.',
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(color: scheme.onSurfaceVariant),
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
        : (widget.showCheckboxes
              ? (widget.paperLines ? 24.0 : 40.0)
              : lineHeight);
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
      child: CustomPaint(
        foregroundPainter: item.divider.isEmpty
            ? null
            : _ItemDividerPainter(
                item.divider,
                scheme.primary.withValues(alpha: 0.75),
              ),
        child: Container(
          color: selected
              ? scheme.primaryContainer.withValues(alpha: 0.4)
              : null,
          padding: const EdgeInsetsDirectional.only(start: 12, end: 2),
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
                  builder: (leadContext) => GestureDetector(
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
                Expanded(
                  // Seçim modunda metne dokunmak düzenlemeye değil seçime gider.
                  child: GestureDetector(
                    onTap: _selectionMode ? () => _toggleSelection(item) : null,
                    child: AbsorbPointer(
                      absorbing: _selectionMode,
                      child: _wrapped(
                        controller,
                        baseStyle,
                        // **ÜSTÜ ÇİZİLİ GEÇİŞ** (kullanıcı isteği 2026-09-22:
                        // "liste maddeleri tıklanma geçiş animasyonu"). Çizgi
                        // eskiden anında beliriyordu; artık çizginin ve yazının
                        // rengi soluk hâle AKAR. `end` yalnız verildiği için ilk
                        // kurulumda animasyon oynamaz (eski işaretli madde açılışta
                        // yeniden çizilmez), yalnız DEĞİŞİMDE oynar.
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(end: checked ? 1 : 0),
                          duration: _kStrikeDuration,
                          curve: Curves.easeOutCubic,
                          builder: (context, strike, _) {
                            // Solma AnimatedOpacity'e bırakıldı (aşağıya bak);
                            // burada alfa verilirse iki kez soluyor.
                            final dim = 1 - (1 - _kCheckedDim) * strike;
                            final fieldStyle = strike == 0
                                ? baseStyle
                                : baseStyle.copyWith(
                                    decoration: TextDecoration.lineThrough,
                                    decorationColor: Color.lerp(
                                      Colors.transparent,
                                      scheme.onSurfaceVariant,
                                      strike,
                                    )!.withValues(alpha: strike * _kCheckedDim),
                                    decorationThickness: 1 + strike,
                                    color: _dimmed(
                                      Color.lerp(
                                        baseStyle.color ?? scheme.onSurface,
                                        scheme.onSurfaceVariant,
                                        strike,
                                      )!,
                                      dim,
                                    ),
                                  );
                            // Dokunuşun konumu tutulur (etiket önizlemesi,
                            // bkz. _tapAttachmentTag); sarmalayıcı HEP ağaçta.
                            // Gömülü yazı çip olarak çizilir (gövdeyle aynı).
                            final field = AttachmentTagChips(
                              controller: controller,
                              looks: widget.tagLooks,
                              child: _tapPoint.wrap(
                                TextField(
                                  controller: controller,
                                  focusNode: _focusFor(item),
                                  onChanged: (_) =>
                                      _updateText(item, controller.logicalText),
                                  contextMenuBuilder:
                                      (context, editableState) => _contextMenu(
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
                                  onEditingComplete: () => _enterAt(item),
                                  textInputAction: TextInputAction.next,
                                  // EK ETİKETİNE DOKUNUNCA ÖNİZLEME — gövdedekiyle
                                  // aynı kural (bkz. note_editor_screen `bodyField`):
                                  // düzenlenebilir alanda span'e tanıyıcı bağlanamaz
                                  // (dokunuş imleci taşımak için EditableText'e
                                  // gider), bu yüzden dokunuştan SONRA imlecin
                                  // nereye düştüğüne bakılır.
                                  onTap: () =>
                                      _tapAttachmentTag(controller, context),
                                  // Tam göster modunda satır sarılıp büyür; "dokununca
                                  // aç" modunda odaklanınca açılır, aksi hâlde tek satır.
                                  maxLines: widget.expandItems || focused
                                      ? null
                                      : 1,
                                  // Sarma planı bu stille hesaplanır; TextField'ın örtük
                                  // varsayılanına bırakılırsa ölçüm ile çizim ayrışır ve
                                  // satırlar yanlış kırılır (M3 varsayılanı bodyLarge).
                                  style: fieldStyle,
                                  // Satır yüksekliği çıpası gövdeyle aynı yerden
                                  // gelir (bkz. [wrapStrutStyle]): ölçüm ile çizim
                                  // ayrışmasın.
                                  strutStyle: wrapStrutStyle(fieldStyle),
                                  decoration: InputDecoration(
                                    // Boş maddenin ipucu "Madde yaz" (F12.7):
                                    // altındaki "+ Yeni öğe" düğmesiyle aynı
                                    // adı taşıyınca iki "Yeni öğe" görünüyordu.
                                    hintText: l10n.itemEmptyHint,
                                    filled: false,
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: fieldPad,
                                    ),
                                  ),
                                ),
                                // Damgaya/etikete dokunmak klavyeyi açmaz.
                                focusNode: _focusFor(item),
                                keepsKeyboardClosed: (global) => linkAtPoint(
                                  editable: editableTextBelow(context),
                                  displayText: controller.text,
                                  global: global,
                                  timestamps:
                                      widget.videoTimestamps &&
                                      widget.onVideoTimestamp != null,
                                  tagNames: widget.onAttachmentTag == null
                                      ? const []
                                      : widget.attachmentNames,
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
                                          color: scheme.onSurfaceVariant,
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
                // YILDIZ ARTIK DÜĞME DEĞİL, İŞARET (kullanıcı isteği 2026-08-30:
                // "yıldızla tuşu maddeler için yerleşimi kötü, basılı tutunca
                // gelsin"). Eskiden satır odaklanınca boş bir yıldız düğmesi
                // beliriyor, metni daraltıyor ve silme "x"ini içeri itiyordu —
                // yazarken satır her odakta yatayda oynuyordu. Yıldızlama sol
                // bölgeye uzun basınca açılan menüde ([_showItemMenu]); burada
                // yalnız YILDIZLI satırın işareti durur (dokununca kalkar).
                if (!_selectionMode && item.starred)
                  IconButton(
                    tooltip: l10n.unstar,
                    icon: const Icon(Icons.star, size: 18),
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
                top: math.max(0.0, firstLineCenter - 18),
                child: IconButton(
                  key: ValueKey('item-remove-${item.id}'),
                  tooltip: l10n.removeItem,
                  icon: const Icon(Icons.close, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: ItemsEditorState._kTrailingWidth + 2,
                    height: 36,
                  ),
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                  onPressed: () => _removeItem(item),
                ),
              ),
          ],
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
          // Satırın metne AYRILAMAYAN payı: yatay dolgu + tutamaç + kutucuk/
          // numara + sil düğmesinin yeri. Sarma kararı bu pay düşülerek
          // verilmeli (bkz. _FloatRow.reserved).
          reserved:
              ItemsEditorState._kRowPadding +
              (_selectionMode ? ItemsEditorState._kHandleWidth : 0) +
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

  /// Ekranın dibine demirlenmiş seçim çubuğu (Overlay çocuğu). Klavye
  /// açıkken onun üstüne çıkar; sistem gezinme çubuğunun altında kalmaz.
  Widget _selectionBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    // `MediaQuery.of` DEĞİL: o, MediaQuery'nin HERHANGİ bir alanı değişince
    // (yönelim, metin ölçeği, erişilebilirlik…) çubuğu yeniden kurar. Çubuğun
    // ihtiyacı yalnız iki ölçü.
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final systemBar = MediaQuery.viewPaddingOf(context).bottom;
    final allSelected = _items.isNotEmpty && _selected.length == _items.length;
    final hasSelection = _selected.isNotEmpty;
    // Toplu işaret: seçilenlerin hepsi işaretliyse "işareti kaldır".
    final selectedItems = [
      for (final i in _items)
        if (_selected.contains(i.id)) i,
    ];
    final allChecked =
        selectedItems.isNotEmpty && selectedItems.every((i) => i.checked);
    return Positioned(
      left: 8,
      right: 8,
      // Klavye yüksekliği gezinme çubuğunu ZATEN içeriyor: ikisini toplamak
      // klavye açıkken çubuğu klavyeden ~48 dp yukarıda asılı bırakıyordu.
      bottom: 8 + (keyboard > systemBar ? keyboard : systemBar),
      child: Material(
        color: scheme.primaryContainer,
        elevation: 6,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            children: [
              IconButton(
                tooltip: l10n.cancel,
                icon: const Icon(Icons.close, size: 20),
                onPressed: _exitSelection,
              ),
              Expanded(
                child: Text(
                  l10n.itemsSelected(_selected.length),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              IconButton(
                tooltip: l10n.selectAllItems,
                icon: Icon(
                  allSelected ? Icons.deselect : Icons.select_all,
                  size: 20,
                ),
                onPressed: _items.isEmpty ? null : _toggleSelectAll,
              ),
              // TOPLU İŞARET (2026-10-20, "madde seçimi mantığı"): seçili
              // maddeleri tek dokunuşla işaretle / işareti kaldır.
              if (widget.showCheckboxes)
                IconButton(
                  tooltip: allChecked
                      ? l10n.uncheckSelectedItems
                      : l10n.checkSelectedItems,
                  icon: Icon(
                    allChecked ? Icons.remove_done : Icons.done_all,
                    size: 20,
                  ),
                  onPressed: hasSelection ? _checkSelected : null,
                ),
              IconButton(
                tooltip: l10n.copy,
                icon: const Icon(Icons.copy_outlined, size: 20),
                onPressed: hasSelection ? _copySelected : null,
              ),
              // KOPYALA + İŞARETLE (kullanıcı isteği 2026-10-30): alışveriş
              // listesinden aldıklarını panoya alıp tek dokunuşla kapatmak.
              if (widget.showCheckboxes)
                IconButton(
                  key: const ValueKey('items-copy-check'),
                  tooltip: l10n.copyAndCheckSelectedItems,
                  icon: const Icon(Icons.library_add_check_outlined, size: 20),
                  onPressed: hasSelection ? _copyAndCheckSelected : null,
                ),
              IconButton(
                tooltip: l10n.delete,
                icon: const Icon(Icons.delete_outline, size: 20),
                color: scheme.error,
                onPressed: hasSelection ? _deleteSelected : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
