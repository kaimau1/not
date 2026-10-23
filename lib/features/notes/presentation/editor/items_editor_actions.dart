part of 'items_editor.dart';

/// Madde işleri: uzun basış menüsü, ayırıcı, yıldız, çoklu seçim, kopyala/sil, sırala (C1).
extension _ItemsActions on ItemsEditorState {
  /// Satıra UZUN BASINCA açılan menü: yıldızla, seç, sil.
  ///
  /// KULLANICI İSTEĞİ 2026-08-30 ("yıldızla tuşu maddeler için yerleşimi kötü,
  /// basılı tutunca gelsin"): yıldız düğmesi her odaklanan satırda beliriyor,
  /// metni daraltıyor ve silme düğmesini içeri itiyordu. Satır işleri artık
  /// tek bir menüde toplandı; satırın kendisinde yalnız YILDIZLI olanın
  /// işareti ve odaklıyken silme "x"i duruyor.
  ///
  /// Menü parmağın bastığı yerde açılır — uzun basışın nereden geldiği
  /// böylece görünür olur.
  Future<void> _showItemMenu(NoteItem item, Offset globalPosition) async {
    final l10n = context.l10n;
    final overlay = Overlay.of(context).context.findRenderObject();
    if (overlay is! RenderBox || !overlay.hasSize) return;
    final position = RelativeRect.fromRect(
      globalPosition & const Size(1, 1),
      Offset.zero & overlay.size,
    );
    PopupMenuItem<_ItemAction> entry(
      _ItemAction value,
      IconData icon,
      String label,
    ) => PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          // Uzun etiket ("Alta noktalı çizgi") dar menüde taşmasın.
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );

    final choice = await showMenu<_ItemAction>(
      context: context,
      position: position,
      items: [
        entry(
          _ItemAction.star,
          item.starred ? Icons.star : Icons.star_outline,
          item.starred ? l10n.unstar : l10n.star,
        ),
        entry(_ItemAction.select, Icons.checklist, l10n.select),
        // Madde ALTINA ayırıcı çizgi (kullanıcı isteği 2026-10-20: "satır
        // aralarına çizgi çekme, kesikli çizgi çekme").
        entry(
          _ItemAction.dividerSolid,
          Icons.horizontal_rule,
          l10n.itemDividerSolid,
        ),
        entry(
          _ItemAction.dividerDashed,
          Icons.more_horiz,
          l10n.itemDividerDashed,
        ),
        entry(
          _ItemAction.dividerDotted,
          Icons.linear_scale,
          l10n.itemDividerDotted,
        ),
        // ÇİZGİ AYARLARI (kullanıcı isteği 2026-10-23: "çizgi rengi ve
        // özelliklerini ayarlama"): tür, renk, kalınlık; çizgi yoksa düz
        // çizgiyle açılır.
        entry(_ItemAction.dividerStyle, Icons.tune, l10n.dividerSettings),
        if (item.divider.isNotEmpty)
          entry(
            _ItemAction.dividerNone,
            Icons.format_strikethrough,
            l10n.itemDividerRemove,
          ),
        if (widget.onMoveToPage != null)
          entry(
            _ItemAction.moveToPage,
            Icons.drive_file_move_outline,
            l10n.itemMoveToPage,
          ),
        entry(_ItemAction.delete, Icons.delete_outline, l10n.removeItem),
      ],
    );
    if (!mounted || choice == null) return;
    switch (choice) {
      case _ItemAction.star:
        _toggleStar(item);
      case _ItemAction.select:
        _toggleSelection(item);
      case _ItemAction.delete:
        _removeItem(item);
      case _ItemAction.dividerSolid:
        _setDivider(item, NoteItem.dividerSolid);
      case _ItemAction.dividerDashed:
        _setDivider(item, NoteItem.dividerDashed);
      case _ItemAction.dividerDotted:
        _setDivider(item, NoteItem.dividerDotted);
      case _ItemAction.dividerStyle:
        await _editDividerStyle(item);
      case _ItemAction.dividerNone:
        _setDivider(item, '');
      case _ItemAction.moveToPage:
        // Önce satırdaki yazı nota işlensin: taşınan madde son hâliyle gitsin.
        _commit();
        widget.onMoveToPage?.call(
          _items.where((i) => i.id == item.id).firstOrNull ?? item,
        );
    }
  }

  /// Maddenin altındaki ayırıcı çizgiyi değiştirir; aynı tür yeniden
  /// seçilirse kaldırır.
  ///
  /// Tür değişince çizginin RENGİ ve KALINLIĞI korunur; yeni çizgi son
  /// kullanılan renk/kalınlıkla gelir ([ItemDividerMemory]).
  void _setDivider(NoteItem target, String divider) {
    final index = _items.indexWhere((i) => i.id == target.id);
    if (index < 0) return;
    final current = ItemDivider.parse(_items[index].divider);
    final String next;
    if (divider.isEmpty || current?.kind == divider) {
      next = '';
    } else {
      next =
          (current?.copyWith(kind: divider) ?? ItemDividerMemory.fresh(divider))
              .encode();
    }
    _update(() => _items[index] = _items[index].copyWith(divider: next));
    _commit();
  }

  /// Çizgi ayarları levhası: tür/renk/kalınlık; "tüm çizgilere uygula"
  /// listedeki bütün ayırıcıları aynı biçime çeker.
  Future<void> _editDividerStyle(NoteItem target) async {
    final current =
        ItemDivider.parse(target.divider) ??
        ItemDividerMemory.fresh(NoteItem.dividerSolid);
    final choice = await showItemDividerSheet(context, initial: current);
    if (!mounted || choice == null) return;
    final style = choice.style;
    final encoded = style?.encode() ?? '';
    _update(() {
      for (var i = 0; i < _items.length; i++) {
        final item = _items[i];
        if (item.id == target.id) {
          _items[i] = item.copyWith(divider: encoded);
        } else if (choice.applyAll &&
            style != null &&
            item.divider.isNotEmpty) {
          // Diğer çizgilerin TÜRÜ değil biçimi (renk, kalınlık) ve tür de
          // eşitlenir: "hepsi aynı görünsün" isteği.
          _items[i] = item.copyWith(divider: encoded);
        }
      }
    });
    _commit();
  }

  /// Maddenin yıldızını çevirir (kullanıcı isteği 2026-08-16).
  ///
  /// İşaretlemenin ([_toggleItem]) aksine satırın YERİNİ değiştirmez:
  /// yıldız bir durum değil bir etiket, listeyi kendiliğinden yeniden
  /// dizmesi kullanıcının elle verdiği sırayı bozardı. Sıraya yansıması
  /// isteniyorsa ⋮ → "Maddeleri sırala" → "Önce yıldızlılar" kullanılır.
  void _toggleStar(NoteItem target) {
    final index = _items.indexWhere((i) => i.id == target.id);
    if (index < 0) return;
    _update(() {
      _items[index] = _items[index].copyWith(starred: !_items[index].starred);
    });
    _commit();
  }

  /// İşaretli tüm öğeleri tek seferde siler (madde 18 — Keep'teki gibi
  /// tek tek silmeye gerek kalmaz).
  void _deleteChecked() {
    final removed = [
      for (final i in _items)
        if (i.checked) i,
    ];
    if (removed.isEmpty) return;
    _update(
      () => _items = [
        for (final i in _items)
          if (!i.checked) i,
      ],
    );
    for (final item in removed) {
      _disposeRowFor(item.id);
      _checkedFrom.remove(item.id);
    }
    _commit();
  }

  void _toggleSelection(NoteItem item) {
    if (!_selectionMode) FocusManager.instance.primaryFocus?.unfocus();
    _update(() {
      if (!_selected.remove(item.id)) _selected.add(item.id);
    });
    _syncBar();
  }

  /// Seçili maddeleri TOPLUCA işaretler; hepsi zaten işaretliyse işareti
  /// kaldırır (seçim çubuğu, yalnız kutucuklu listede). Boş madde
  /// işaretlenmez — tekli kutucukla aynı kural (bkz. [_toggleItem]).
  void _checkSelected() {
    final targets = [
      for (final i in _items)
        if (_selected.contains(i.id) && i.text.trim().isNotEmpty) i,
    ];
    if (targets.isEmpty) return;
    final check = targets.any((i) => !i.checked);
    _exitSelection();
    for (final item in targets) {
      if (item.checked != check) _toggleItem(item, check);
    }
  }

  /// Tümünü seç / seçimi bırak. Çubuk artık altta sabit olduğundan uzun
  /// listede tek dokunuşla hepsini kopyalamak mümkün.
  void _toggleSelectAll() {
    _update(() {
      if (_selected.length == _items.length) {
        _selected.clear();
      } else {
        _selected
          ..clear()
          ..addAll(_items.map((i) => i.id));
      }
    });
    _syncBar();
  }

  /// Seçili maddeleri liste sırasıyla panoya kopyalar. Metinler
  /// [stripRichMarkers]'tan geçer: biçimli madde panoya `**süt al**` diye
  /// işaretli gitmesin (Note.toPlainText ile aynı kural).
  Future<void> _copySelected() async {
    // Paylaşımla aynı düzen (bkz. itemsCopyText): `[ ]` yerine ☐/☑, tek
    // maddede yalnız metin.
    final text = itemsCopyText([
      for (final item in _items)
        if (_selected.contains(item.id)) item,
    ], checkboxes: widget.showCheckboxes);
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    _exitSelection();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showMessage(context.l10n.copied);
  }

  void _deleteSelected() {
    final removed = [
      for (final i in _items)
        if (_selected.contains(i.id)) i,
    ];
    if (removed.isEmpty) return;
    _update(() {
      _items = [
        for (final i in _items)
          if (!_selected.contains(i.id)) i,
      ];
      _selected.clear();
      _selectMode = false;
    });
    _syncBar();
    for (final item in removed) {
      _disposeRowFor(item.id);
    }
    _commit();
  }

  /// Tüm not içeriğini panoya kopyalar ("Tümünü seç" seçeneği — ayrı
  /// TextField'lar arası gerçek seçim mümkün olmadığından pratik karşılığı).
  ///
  /// [ItemsEditor.wholeNoteText] verildiyse o kullanılır: "Tüm notu kopyala"
  /// başlığı ve serbest gövde metnini de içermeli — eskiden yalnız maddeler
  /// kopyalanıyor, karışık notta üstteki paragraf sessizce düşüyordu.
  Future<void> _copyAll() async {
    String text;
    final whole = widget.wholeNoteText?.call();
    if (whole != null && whole.trim().isNotEmpty) {
      text = whole.trim();
    } else {
      text = itemsCopyText(_items, checkboxes: widget.showCheckboxes);
    }
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showMessage(context.l10n.allCopied);
    }
  }
}
