part of 'items_editor.dart';

extension ItemsEditorBuildOps on ItemsEditorState {
  void _toggleItem(NoteItem target, bool? value) {
    final index = _items.indexWhere((i) => i.id == target.id);
    if (index < 0) return;
    final wasChecked = _items[index].checked;
    final nowChecked = value ?? false;
    // Metni BOŞ öğe işaretlenemez: yeni açılan "Yeni öğe" satırının kutusuna
    // yanlışlıkla dokunmak, içi boş bir maddeyi işaretlilerin arasına
    // indiriyordu — ne silinebilir bir iş, ne okunur bir satır. İşareti geri
    // almak da gerekmesin diye kutucuk hiç tepki vermez.
    if (nowChecked && _items[index].text.trim().isEmpty) return;
    // Ara başlık işaretlenmez (kutucuğu da yok; toplu işaret buraya düşer).
    if (nowChecked && _items[index].header) return;

    // Kural 2 (Rutin kipi): madde yerinde kalır (alta düşmez / silinmez) ve
    // doneDays tek gerçek kaynak olarak güncellenir.
    if (_keepCheckedInPlace) {
      final todayKey = isoDayKeyOf(DateTime.now());
      final current = _items[index];
      final hasToday = current.isDoneOn(todayKey);
      NoteItem updated;
      if (nowChecked && !hasToday) {
        updated = current.toggledDoneDay(todayKey);
      } else if (!nowChecked && hasToday) {
        updated = current.toggledDoneDay(todayKey);
      } else {
        updated = current.copyWith(checked: nowChecked);
      }
      _update(() {
        _items[index] = updated;
        _rowCache.remove(target.id);
      });
      _commit();
      if (wasChecked != nowChecked) {
        widget.onItemChecked?.call(updated, nowChecked);
      }
      return;
    }

    if (nowChecked && !wasChecked) {
      // Eski sıra ŞİMDİ saklanmalı: işaret anında öğe listede yer değiştirir.
      _checkedFrom[target.id] = (index: index, at: DateTime.now());
    }
    _update(() {
      _items[index] = _items[index].copyWith(checked: nowChecked);
      _settling[target.id] = wasChecked;
    });
    _commit();
    if (wasChecked != nowChecked) widget.onItemChecked?.call(target, nowChecked);
    Future<void>.delayed(ItemsEditorState._settleDuration, () {
      if (!mounted) return;
      _update(() {
        _settling.remove(target.id);
        final current = _items.indexWhere((i) => i.id == target.id);
        if (current < 0) return;
        _arriving.add(target.id);
        final item = _items.removeAt(current);
        if (item.checked) {
          _items.insert(_checkedStart, item);
          return;
        }
        final memory = _checkedFrom.remove(item.id);
        _items.insert(
          _uncheckedInsertIndex(
            uncheckRestoreIndex(
              uncheckedCount: _uncheckedCount,
              rememberedIndex: memory?.index,
              sinceChecked: memory == null
                  ? null
                  : DateTime.now().difference(memory.at),
            ),
          ),
          item,
        );
      });
      _commit();
      Future<void>.delayed(_CheckMove.arriveDuration, () {
        if (!mounted || !_arriving.remove(target.id)) return;
        _update(() {});
      });
    });
  }

  /// Klavyenin Enter/"İleri" tuşu: imleç maddenin SONUNDAYSA altına boş
  /// madde açar; ORTASINDAYSA maddeyi imleçten böler — sağdaki kısım yeni
  /// maddeye geçer ve imleç onun başına konur (kullanıcı isteği 2026-10-28:
  /// "cümlenin arasında enter yapılınca oradan itibaren bölüp yeni madde
  /// yapmalı"). İmleç başta ve madde doluysa üstüne boş madde açılır.
  void _enterAt(NoteItem target) {
    final index = _items.indexWhere((i) => i.id == target.id);
    final controller = _controllers[target.id];
    if (index < 0 || controller == null || !controller.selection.isValid) {
      _insertAfter(target);
      return;
    }
    final logical = controller.logicalText;
    final start = wrapToLogicalOffset(
      controller.text,
      controller.selection.start,
    ).clamp(0, logical.length);
    final end = wrapToLogicalOffset(
      controller.text,
      controller.selection.end,
    ).clamp(start, logical.length);
    final (:before, :after) = splitRichText(logical, start, end);
    // Paketin SON maddesi boşken Enter: paketten çıkar (listelerdeki gibi);
    // yeni madde açılmaz.
    if (logical.trim().isEmpty && target.package.isNotEmpty) {
      final nextIsSame =
          index + 1 < _items.length &&
          _items[index + 1].package == target.package;
      if (!nextIsSame) {
        _update(() {
          _items[index] = _items[index].copyWith(package: '');
          _rowCache.remove(target.id);
        });
        _commit();
        return;
      }
    }
    if (after.isEmpty) {
      if (end != start) {
        // Sona kadar seçili metin Enter'la silinir (yazılan Enter gibi).
        controller.setLogical(before, before.length);
        _updateText(target, before);
      }
      _insertAfter(target);
      return;
    }
    if (stripRichMarkers(before).trim().isEmpty) {
      // Baştan Enter: madde aşağı kayar, üstüne boş madde açılır; imleç
      // yerinde kalır (Keep ve kelime işlemcilerdeki gibi).
      final blank = NoteItem(id: ItemsEditorState._uuid.v4(), text: '');
      _update(() => _items.insert(index, blank));
      _commit();
      return;
    }
    final current = _items[index];
    // Paketin içinden bölünen parça pakette kalır.
    final next = NoteItem(
      id: ItemsEditorState._uuid.v4(),
      text: after.trimLeft(),
      package: current.checked ? '' : current.package,
    );
    _update(() {
      _items[index] = current.copyWith(text: before.trimRight());
      // İşaretli maddeden bölünen parça işaretsizlerin sonuna girer
      // ("işaretsizler başta" değişmezi, bkz. [_insertAfter]).
      final at = (widget.showCheckboxes && !_keepCheckedInPlace && current.checked)
          ? _uncheckedInsertIndex(_uncheckedCount)
          : index + 1;
      _items.insert(at, next);
    });
    controller.setLogical(before.trimRight(), before.trimRight().length);
    _commit();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final nextController = _controllerFor(next);
      _focusFor(next).requestFocus();
      nextController.selection = const TextSelection.collapsed(offset: 0);
    });
  }

  /// **DİKTEDE "YENİ MADDE"** (kullanıcı bulgusu 2026-11-19): [controller]'ın
  /// maddesinin altına TEK boş madde açar (Enter ile aynı kural) ve onun
  /// alanını döndürür — dikte orada sürer. Madde bu editörde değilse null.
  ///
  /// KÖK NEDEN: dikte "yeni madde" komutunun ürettiği `\n`'i eski maddenin
  /// alanına yazıp alanın `commit`ini çağırıyordu; [_updateText] satır
  /// sonunu yapıştırma sayıp maddeyi BÖLÜYORDU. Dikte hâlâ eski alana
  /// yazdığından tanıyıcının HER ara sonucu yeniden bölünüp yeni madde
  /// açıyordu (bir cümle → 20+ madde).
  ({WrapTextController controller, FocusNode focus, VoidCallback commit})?
  openItemAfterController(TextEditingController controller) {
    final id = itemIdForController(controller);
    if (id == null) return null;
    final after = _items.where((i) => i.id == id).firstOrNull;
    if (after == null) return null;
    final item = _insertAfter(after);
    if (item == null) return null;
    final c = _controllerFor(item);
    return (
      controller: c,
      focus: _focusFor(item),
      commit: () => _updateText(item, c.logicalText),
    );
  }

  /// **LİSTEDE MADDE SEÇİLMEDEN DİKTE** (kullanıcı bulgusu 2026-11-26:
  /// "maddeye tıklamazsam liste notunda normal metin ekliyor, madde olarak
  /// eklemesi lazım"): işaretsizlerin sonundaki boş madde (ara başlık
  /// değil) varsa o, yoksa sona yeni madde açılır; alanı döner ve odaklanır.
  /// Seçim kipinde null (dokunuşlar seçime gider).
  ({WrapTextController controller, FocusNode focus, VoidCallback commit})?
  openItemAtEnd() {
    if (_selectionMode) return null;
    final open = [
      for (final i in _items)
        if (!widget.showCheckboxes || _keepCheckedInPlace || !i.checked) i,
    ];
    NoteItem item;
    if (open.isNotEmpty && open.last.text.trim().isEmpty && !open.last.header) {
      item = open.last;
    } else {
      // "+ Yeni öğe" ([_addItem]) ile aynı: paketsiz, işaretsizlerin sonu.
      item = NoteItem(id: ItemsEditorState._uuid.v4(), text: '');
      _update(
        () => _items.insert(
          _keepCheckedInPlace
              ? _items.length
              : _uncheckedInsertIndex(_uncheckedCount),
          item,
        ),
      );
      _commit();
    }
    final c = _controllerFor(item);
    final focus = _focusFor(item);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      focus.requestFocus();
      c.selection = TextSelection.collapsed(offset: c.text.length);
    });
    return (
      controller: c,
      focus: focus,
      commit: () => _updateText(item, c.logicalText),
    );
  }

  NoteItem? _insertAfter(NoteItem after) {
    final index = _items.indexWhere((i) => i.id == after.id);
    if (index < 0) return null;
    // NOT PAKETİ AÇIKKEN Enter / yeni madde paketin içinde kalır (kullanıcı
    // bulgusu 2026-11-08: "yeni madde ekleyince paket iptal oluyor" — yeni
    // satır paketsiz açılıp paketi ikiye bölüyor, odak dışarı kaçıyordu).
    final item = NoteItem(
      id: ItemsEditorState._uuid.v4(),
      text: '',
      package: after.checked ? '' : after.package,
    );
    // İşaretli maddeden (footer bloğu) Enter: yeni İŞARETSİZ öğe işaretli
    // bloğun ortasına giremez — "işaretsizler _items'ın başında" değişmezi
    // bozulur ve sürükle-sırala görünenden BAŞKA öğeyi taşırdı. Yeni öğe
    // işaretsizlerin sonuna girer.
    final at = (widget.showCheckboxes && !_keepCheckedInPlace && after.checked)
        ? _uncheckedInsertIndex(_uncheckedCount)
        : index + 1;
    _update(() => _items.insert(at, item));
    _commit();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusFor(item).requestFocus();
    });
    return item;
  }

  /// Alışveriş reyon gruplarını [ItemsEditor.aisleOrder] sırasına göre kurar.
  /// Tüm satır mutasyonları Kural 5 gereği `item.id` ile yapılır.
  List<Widget> _buildShoppingAisleChildren(
    BuildContext context,
    List<NoteItem> listItems,
    Set<int> collapsed,
    double stylusGutter,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final isTr = l10n.localeName.startsWith('tr');
    final buckets = <int, List<NoteItem>>{};
    final blankTail = <NoteItem>[];
    for (final item in listItems) {
      if (item.header) continue;
      if (item.text.trim().isEmpty) {
        blankTail.add(item);
        continue;
      }
      final aisle = resolveItemAisle(
        item,
        locale: l10n.localeName,
        learnedGroups: widget.learnedGroups,
      );
      (buckets[aisle] ??= <NoteItem>[]).add(item);
    }

    final customOrder = widget.aisleOrder;
    final orderedKeys = <int>[
      if (customOrder != null)
        for (final a in customOrder)
          if (buckets.containsKey(a)) a,
      for (var i = 0; i < kShopAisles.length; i++)
        if (buckets.containsKey(i) &&
            (customOrder == null || !customOrder.contains(i)))
          i,
      if (buckets.containsKey(kOtherAisleIndex)) kOtherAisleIndex,
    ];

    final out = <Widget>[];
    for (final aisleIdx in orderedKeys) {
      final group = buckets[aisleIdx]!;
      final meta = shopAisleMetaOfIndex(aisleIdx);
      final isCollapsed = collapsed.contains(aisleIdx);
      out.add(
        _floatRow(
          reserved: ItemsEditorState._kButtonRowWidth,
          pushOnly: true,
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              14,
              AppSpace.s,
              8 + stylusGutter,
              AppSpace.xxs,
            ),
            child: InkWell(
              key: ValueKey('aisle-header-$aisleIdx'),
              borderRadius: BorderRadius.circular(AppRadius.s),
              onTap: () {
                final next = {..._collapsedAisles.value};
                if (!next.add(aisleIdx)) next.remove(aisleIdx);
                _collapsedAisles.value = next;
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.xs,
                  vertical: AppSpace.xs,
                ),
                child: Row(
                  children: [
                    Icon(meta.icon, size: AppIconSize.s, color: meta.color),
                    const SizedBox(width: AppSpace.s),
                    Text(
                      meta.label(isTr: isTr),
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: AppWeight.strong,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: AppSpace.xs),
                    Text(
                      '(${group.length})',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      isCollapsed
                          ? Icons.expand_more_rounded
                          : Icons.expand_less_rounded,
                      size: AppIconSize.s,
                      color: scheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      if (!isCollapsed) {
        for (final item in group) {
          out.add(_cachedItemRow(item));
        }
      }
    }
    for (final blank in blankTail) {
      out.add(_cachedItemRow(blank));
    }
    return out;
  }

  Widget _buildItemsEditor(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final showChecks = widget.showCheckboxes;
    _accent = NoteAccent.maybeOf(context);
    // Satır önbelleğinin liste düzeyi girdileri (bkz. [_rowCache]).
    _syncRowCache(theme, l10n);
    _queueLayoutCheck();
    // Ek listesi değişince (ek silindi/eklendi) etiketin kırmızı çizilip
    // çizilmeyeceği değişir. Satır ÖNBELLEKTEN gelebildiği için besleme
    // `_controllerFor`a bırakılamaz: denetleyici zaten var olan satırlarda o
    // işlev hiç çağrılmaz. Setter aynı listede hiçbir şey yapmaz.
    final chipColors = widget._tagChipColors;
    for (final controller in _controllers.values) {
      controller.attachmentNames = widget.attachmentNames;
      controller.tagChipColors = chipColors;
      controller.videoTimestamps = widget.videoTimestamps;
    }

    // Checklist'te işaretli öğeler sürüklenebilir listenin DIŞINDA, footer'da
    // ayrı bir blok olarak durur (Keep'in "tamamlananlar" bölümü gibi).
    // Rutin kipinde (_keepCheckedInPlace) ve Proje Odak kipinde işaretliler
    // footer bloğunda ayrılmaz.
    var checkedItems = (showChecks && !_keepCheckedInPlace && !_isProjectFocused)
        ? [
            for (final i in _items)
              if (_placedAsChecked(i)) i,
          ]
        : const <NoteItem>[];
    // Sürüklenebilir liste ile [_reorder]'ın eşlemesi AYNI süzgeçten geçmeli.
    var listItems = _visibleItems();
    if (_isProjectFocused) {
      final focusSet = resolveProjectFocusIds(
        listItems,
        manualFocusIds: widget.focusIds,
      );
      listItems = [
        for (final item in listItems)
          if (focusSet.contains(item.id) || item.text.trim().isEmpty) item,
      ];
    }
    // Yalnız ÖNEK kurulur: sürükleme dizinleri [_reorder]'ın eşlemesiyle örtüşür.
    final checkedCount = checkedItems.length;
    final checkedHidden = math.max(0, checkedCount - _checkedShown);
    if (checkedHidden > 0) {
      checkedItems = checkedItems.sublist(0, _checkedShown);
    }
    var budget = _rowBudget;
    // BÜTÇE GÖRÜNENİ KARŞILADIYSA BÜYÜME BİTER (kullanıcı bulgusu
    // 2026-11-24: "notlar açılırken kasma"). KÖK NEDEN: bütçe TÜM madde
    // sayısına (374 işaretli dahil) doğru büyüyordu; işaretliler 10'ar
    // gösterildiği için ekrana yeni satır gelmediği hâlde liste ~45 kare
    // boyunca her karede baştan kuruluyordu (kare başına ~150 kurulum).
    if (budget != null && budget >= listItems.length + checkedItems.length) {
      _rowBudget = budget = null;
    }
    if (budget != null) {
      if (listItems.length > budget) listItems = listItems.sublist(0, budget);
      final left = budget - listItems.length;
      if (checkedItems.length > left) {
        checkedItems = checkedItems.sublist(0, left);
      }
    }

    // "Yeni öğe" LİSTENİN İÇİNDE, işaretsizlerin hemen altında (eski yeri).
    // Bir tur ekranın dibinde yüzen bir düğmeye alınmıştı; oradaki alt paneli
    // (ek şeridi + alt çubuk) örttüğü için geri kondu — kullanıcı isteği
    // 2026-08-09: "seç burada olsun, yeni öğe eski yerinde". "Seç" ise alt
    // çubuğun segmenti oldu (bkz. [startSelection]); footer'da tekrarlanmaz.
    final stylusGutter = StylusGutter.endOf(context);
    final addButton = _floatRow(
      reserved: ItemsEditorState._kButtonRowWidth,
      // DÜĞME SATIRI YANA GEÇMEZ, ALTA İNER (kullanıcı bulgusu 2026-08-10:
      // "yeni öğe + yazısı resimlerin altında kalıyor, görsel çok büyüyünce
      // oluyor"): yana kaydırma kararı metne kalan yere bakıyordu ve düğme
      // satırının metni yok — küçülemeyen 280 dp'lik sabit bir blok. Görselin
      // bandına değen her durumda satır görselin ALTINA iner; böylece düğme
      // görselin altında kalamaz, ölçüm bir piksel şaşsa bile.
      pushOnly: true,
      Padding(
        // Yüzen kalem düğmesinin altında kalmasın (P78 KT-15).
        padding: EdgeInsetsDirectional.only(start: 8, end: 8 + stylusGutter),
        child: LayoutBuilder(
          builder: (context, addRow) => Row(
          children: [
            // **SATIRIN TAMAMI "YENİ MADDE"** (kullanıcı isteği 2026-11-01:
            // "madde eklemenin hitbox'ını artır, aynı satırda çok daha
            // sağına tıklanırsa da yeni madde eklensin"). Düğme yalnız yazısı
            // kadardı; satırın boş sağı artık aynı işi yapar (sağdaki
            // ek düğmesine kadar).
            Expanded(
              child: GestureDetector(
                key: const ValueKey('items-add-row'),
                behavior: HitTestBehavior.opaque,
                // Erişilebilirlikte tek düğme ("Yeni madde") kalsın; satırın
                // boş kısmı yalnız dokunma kolaylığı.
                excludeFromSemantics: true,
                onTap: _addItem,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: _addItemButton(l10n),
                  ),
                ),
              ),
            ),
            // ARA BAŞLIK (kullanıcı isteği 2026-11-05): maddeleri gruplayan
            // kutucuksuz satır; uzun basış menüsünden de çevrilebilir.
            // Dar satırda yalnız simge (yazı "Yeni madde"yi taşırırdı).
            if (addRow.maxWidth < 340)
                  IconButton(
                      key: const ValueKey('items-add-header'),
                      tooltip: l10n.itemAddHeader,
                      visualDensity: VisualDensity.compact,
                      color: _accent?.accent,
                      onPressed: addHeader,
                      icon: const Icon(Icons.title, size: AppIconSize.s),
                    )
            else
                  TextButton.icon(
                      key: const ValueKey('items-add-header'),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: _accent?.accent,
                      ),
                      onPressed: addHeader,
                      icon: const Icon(Icons.title, size: AppIconSize.s),
                      label: Text(l10n.itemAddHeader),
                    ),
            if (widget.addRowTrailing != null) widget.addRowTrailing!,
          ],
        ),
        ),
      ),
    );

    // STRETCH, start DEĞİL: `_FloatRow` kesişmeyi KENDİ genişliğinden ölçüyor
    // (bkz. [_FloatRowState._measure]). `start` hizalamada düğme satırı yalnız
    // düğme kadar genişti, yani sayfanın sağ yarısındaki bir görselle hiç
    // kesişmiyor görünüyor ve satır olduğu yerde kalıyordu. Tam genişlikte
    // ölçülünce satırın gerçekten hangi görselin bandında olduğu doğru çıkar.
    final footer = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        addButton,
        if (widget.ghostSection != null) widget.ghostSection!,
        // SİL BLOĞUN BAŞINDA (F38.4): en altta "İşaretlileri göster"in de
        // altındaydı; 10 satır + ek şeridi kaydırmadan ulaşılmıyordu.
        if (checkedItems.isNotEmpty)
          _floatRow(
            reserved: ItemsEditorState._kButtonRowWidth,
            pushOnly: true,
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                16,
                4,
                8 + stylusGutter,
                0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SectionLabel(
                      l10n.checkedHeader(checkedCount),
                      color: NoteAccent.maybeOf(context)?.accent,
                    ),
                  ),
                  Tooltip(
                    message: l10n.deleteChecked(checkedCount),
                    child: TextButton.icon(
                      key: const ValueKey('items-delete-checked'),
                      onPressed: _deleteChecked,
                      icon: const Icon(Icons.delete_sweep_outlined, size: AppIconSize.m),
                      label: Text(l10n.delete),
                      style: TextButton.styleFrom(
                        foregroundColor: scheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        // ÖNBELLEKTEN (kullanıcı bulgusu 2026-10-28: "maddeleri okundu
        // işaretleyince donma kasma"): işaretli blok `_itemRow` ile her
        // kurulumda BAŞTAN kuruluyordu — çok işaretli maddeli notta her tuş,
        // her işaret ve görsel eklenince bütün üstü çizili satırlar (metin
        // alanı, taşma ölçümü, sarma ölçümü) yeniden kuruluyordu.
        for (final item in checkedItems) _cachedItemRow(item),
        if (checkedHidden > 0 || _checkedShown > ItemsEditorState._kCheckedStep)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 2, 12, 0),
            child: Wrap(
              spacing: 4,
              children: [
                if (checkedHidden > 0)
                  TextButton.icon(
                    key: const ValueKey('items-show-more-checked'),
                    onPressed: () =>
                        _update(() => _checkedShown += ItemsEditorState._kCheckedStep),
                    icon: const Icon(Icons.expand_more, size: AppIconSize.m),
                    label: Text(l10n.showMoreChecked(checkedHidden)),
                  ),
                if (_checkedShown > ItemsEditorState._kCheckedStep)
                  TextButton.icon(
                    key: const ValueKey('items-hide-checked'),
                    onPressed: () =>
                        _update(() => _checkedShown = ItemsEditorState._kCheckedStep),
                    icon: const Icon(Icons.expand_less, size: AppIconSize.m),
                    label: Text(l10n.hideMoreChecked),
                  ),
              ],
            ),
          ),
        if (widget.footer != null) widget.footer!,
      ],
    );

    // İKİ SÜTUN: sürüklenebilir liste yerine iki paralel sütun. Maddeler
    // yarı yarıya bölünür (soldaki ilk yarı, sağdaki ikinci yarı) — soldan
    // sağa dizilseydi göz her maddede satır atlamak zorunda kalır, "1 2 / 3 4"
    // düzeni basılı bir listeye hiç benzemezdi.
    //
    // Satırların KENDİSİ aynı `_itemRow`: onay kutusu, yıldız, biçimli metin,
    // uzun basma menüsü ve seçim kipi tek sütundakiyle birebir aynı çalışır.
    // Yalnız sürükleme tutamağı yok (bkz. [ItemsEditor.columns]).
    if (widget.columns == 2 && !_isGroupedShopping) {
      final half = (listItems.length + 1) ~/ 2;
      final columns = <Widget>[
        for (final range in [
          (start: 0, end: half),
          (start: half, end: listItems.length),
        ])
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = range.start; i < range.end; i++)
                  _cachedItemRow(
                    listItems[i],
                    orderNumber: itemOrderNumber(listItems, i),
                  ),
              ],
            ),
          ),
      ];
      final grid = ListView(
        padding: EdgeInsets.only(bottom: _selectionMode ? 152 : 96),
        shrinkWrap: widget.shrinkWrap,
        physics: widget.shrinkWrap
            ? const NeverScrollableScrollPhysics()
            : null,
        children: [
          if (widget.header != null) widget.header!,
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: columns),
          footer,
        ],
      );
      return PopScope(
        canPop: !_selectionMode,
        onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !BackCloses.handling(context)) _exitSelection();
        },
        child: OverlayPortal(
          controller: _barController,
          overlayChildBuilder: _selectionBar,
          child: grid,
        ),
      );
    }

    // ALIŞVERİŞ REYON GRUPLAMASI (Kural 5: ID tabanlı satır mutasyonu,
    // yerel ValueNotifier ile daraltılabilir başlıklar, sürükleme kapalı).
    if (_isGroupedShopping) {
      final groupedList = ValueListenableBuilder<Set<int>>(
        valueListenable: _collapsedAisles,
        builder: (context, collapsed, _) => ListView(
          padding: EdgeInsets.only(bottom: _selectionMode ? 152 : 96),
          shrinkWrap: widget.shrinkWrap,
          addAutomaticKeepAlives: !widget.shrinkWrap,
          physics: widget.shrinkWrap
              ? const NeverScrollableScrollPhysics()
              : null,
          children: [
            if (widget.header != null) widget.header!,
            ..._buildShoppingAisleChildren(
              context,
              listItems,
              collapsed,
              stylusGutter,
            ),
            footer,
          ],
        ),
      );
      return PopScope(
        canPop: !_selectionMode,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && !BackCloses.handling(context)) _exitSelection();
        },
        child: OverlayPortal(
          controller: _barController,
          overlayChildBuilder: _selectionBar,
          child: groupedList,
        ),
      );
    }

    // TUTAMAÇ YOKKEN DÜZ LİSTE (P20 M1, S3/S4). `SliverReorderableList` her
    // satırı DİZİN içeren bir GlobalKey ile sarar (`_ReorderableItemGlobalKey`):
    // bir madde işaretlenip alta inince ya da araya madde girince arkadaki
    // bütün satırların öğesi ATILIP baştan kuruluyordu (30 maddede 23 satır).
    // Sürükleme yalnız tutamaçtan başlıyor (buildDefaultDragHandles: false),
    // tutamaç yalnız [_showHandles]'ta var → onsuz düz `ListView`; çocuklar
    // anahtarlı ([_RowSlot]) olduğu için yer değişince öğe korunur.
    // ponytail: tutamaçlı kipte (tablet/web, Seç) 23 kalır; sıralama orada lazım.
    final list = !_showHandles
        ? ListView(
            padding: EdgeInsets.only(bottom: _selectionMode ? 152 : 96),
            shrinkWrap: widget.shrinkWrap,
            // shrinkWrap'te (editör: dış kaydırma görünümünün içinde) BÜTÜN
            // satırlar zaten kurulu, canlı tutma sarmalayıcısı (satır başına
            // 4 widget) her liste kurulumunda boşuna yeniden kuruluyordu.
            addAutomaticKeepAlives: !widget.shrinkWrap,
            physics: widget.shrinkWrap
                ? const NeverScrollableScrollPhysics()
                : null,
            children: [
              if (widget.header != null) widget.header!,
              for (var i = 0; i < listItems.length; i++)
                _packagedRow(
                  listItems,
                  i,
                  _cachedItemRow(
                    listItems[i],
                    orderNumber: itemOrderNumber(listItems, i),
                  ),
                ),
              footer,
            ],
          )
        : ReorderableListView.builder(
      // Alt dolgu, altta sabit duran seçim çubuğunun son maddeyi örtmemesi
      // için seçim modunda büyür.
      padding: EdgeInsets.only(bottom: _selectionMode ? 152 : 96),
      buildDefaultDragHandles: false,
      shrinkWrap: widget.shrinkWrap,
      physics: widget.shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      header: widget.header,
      footer: footer,
      itemCount: listItems.length,
      // İşaretsizler _items'ın başında tutulduğundan (bkz. _checkedStart)
      // buradaki index'ler _items index'leriyle birebir örtüşür.
      onReorderItem: _reorder,
      onReorderStart: (_) => _reordering = true,
      onReorderEnd: (_) {
        _reordering = false;
        _stopAutoScroll();
        // Sürükleme sırasında ertelenen dış güncelleme varsa şimdi uygulanır
        // (bkz. [_adoptIncomingItems]). `_reorder` bu çağrıdan ÖNCE koştuğu
        // için kullanıcının taşıması kaybolmaz: yeni sıra zaten kaydedildi,
        // gelen liste ondan farklıysa gerçekten dışarıdan bir değişiklik var
        // demektir.
        if (_adoptDeferred) {
          _adoptDeferred = false;
          _adoptIncomingItems();
        }
      },
      itemBuilder: (context, index) => _packagedRow(
        listItems,
        index,
        _cachedItemRow(
          listItems[index],
          reorderIndex: index,
          orderNumber: itemOrderNumber(listItems, index),
        ),
      ),
    );

    // Kenar kaydırması yalnız shrinkWrap kipinde elle yürütülür; normal kipte
    // ReorderableListView'ın kendi otomatik kaydırıcısı zaten çalışıyor.
    final scrollableList = widget.shrinkWrap
        ? Listener(
            onPointerMove: (event) => _autoScrollTo(event.position),
            onPointerUp: (_) => _stopAutoScroll(),
            onPointerCancel: (_) => _stopAutoScroll(),
            child: list,
          )
        : list;

    // Seçim çubuğu ekranın dibinde, kaydırmadan bağımsız bir katmanda durur:
    // liste nerede olursa olsun "Kopyala" hep parmağın altındadır.
    //
    // Geri tuşu seçim kipini KAPATIR, notu değil: kullanıcı yanlışlıkla seçim
    // moduna girince telefonun geri tuşu editörden atıyordu. Aynı kural ana
    // ekranda da geçerli (bkz. dashboard_screen).
    return PopScope(
      canPop: !_selectionMode,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !BackCloses.handling(context)) _exitSelection();
      },
      child: OverlayPortal(
        controller: _barController,
        overlayChildBuilder: _selectionBar,
        child: scrollableList,
      ),
    );
  }


}
