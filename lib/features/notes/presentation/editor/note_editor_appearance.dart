part of 'note_editor_screen.dart';

/// Görünüm: renk, kâğıt, zemin görseli; sil/temizle.
///
/// F9.3: editör konu başına bölündü; durum (alanlar) [_NoteEditorScreenState]da kalır.
extension _EditorAppearance on _NoteEditorScreenState {
  /// Palet düğmesi: zemin rengi ve renkli çerçeve seçimi. İkisi ayrı alanlar —
  /// renkli zeminli bir nota farklı renkte çerçeve verilebilir (madde 4).
  // Yazı tipi ve boyutu artık BİÇİM ÇUBUĞUNDA (alt çubuktaki "Aa"): palet
  // sayfasının içine gömülüyken bulunamıyordu ve boyut ancak hazır adımlardan
  // seçilebiliyordu. Çubukta yazı tipi tek dokunuş, boyut ise sürüklendikçe
  // canlı değişiyor (bkz. format_bar.dart).

  Future<void> _showColorSheet() async {
    final note = _note;
    if (note == null) return;
    _dismissKeyboard();
    final l10n = context.l10n;
    final target = await showAppSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: _colorLeading(
                note.color,
                frame: false,
                custom: note.customColor,
              ),
              title: Text(l10n.backgroundColor),
              onTap: () => Navigator.pop(sheetContext, 'bg'),
            ),
            // ÇERÇEVE GERİ GELDİ (kullanıcı isteği 2026-10-20) — yalnız ana
            // ekran kartında çizilir; alt satır bunu söyler.
            ListTile(
              leading: _colorLeading(
                note.frameColor,
                frame: true,
                custom: note.customFrameColor,
              ),
              title: Text(l10n.frameColor),
              subtitle: Text(l10n.frameColorInfo),
              onTap: () => Navigator.pop(sheetContext, 'frame'),
            ),
            // Zemin görseli renk seçiminin yanında: ikisi de "notun zemini".
            ListTile(
              leading: const Icon(Icons.wallpaper),
              title: Text(l10n.noteBackgroundImage),
              onTap: () => Navigator.pop(sheetContext, 'image'),
            ),
          ],
        ),
      ),
    );
    if (target == null || !mounted) return;
    if (target == 'image') {
      await _showBackgroundSheet();
      return;
    }
    final frame = target == 'frame';
    // Editörde şerit CANLI çalışır: dokunulan renk anında uygulanır ve şerit
    // açık kalır (Keep davranışı). Çerçeve editörde çizilmediği için onun
    // sonucu ana ekrana dönünce kartta görünür.
    await showNoteColorPicker(
      context,
      frame: frame,
      current: frame ? note.frameColor : note.color,
      currentCustom: frame ? note.customFrameColor : note.customColor,
      onChanged: (picked) {
        if (!mounted) return;
        _mutate(
          (n) => frame
              ? n.copyWith(
                  frameColor: picked.color,
                  customFrameColor: picked.custom,
                  clearCustomFrameColor: picked.custom == null,
                )
              : n.copyWith(
                  color: picked.color,
                  customColor: picked.custom,
                  clearCustomColor: picked.custom == null,
                ),
          immediate: true,
        );
      },
    );
  }

  /// DEFTER GÖRÜNÜMÜ (F3.5): kâğıt deseni gövdenin arkasında, satır
  /// aralığı gövde metninin satır yüksekliği.
  Widget _withPaper(Note note, TextStyle bodyStyle, Widget child) {
    if (!note.paged) return child;
    return NotebookPaper(
      style: note.archivePaper,
      gap: _paperGap(bodyStyle),
      scroll: _pageScroll,
      // Çizgili desenlerde satırları içerik çizer (bkz. [_withRuledLines]);
      // belge notunun tuvali yok, orada ızgara kalır.
      contentRuled: !note.type.isPageNoteType,
      child: child,
    );
  }

  /// Defter satır aralığı = gövdenin GERÇEK satır yüksekliği. Sistem yazı
  /// ölçeği de hesaba girer (eskiden girmiyordu: büyük yazı ayarında
  /// çizgiler yazıdan sık kalıyordu).
  double _paperGap(TextStyle bodyStyle) =>
      MediaQuery.textScalerOf(context).scale(bodyStyle.fontSize ?? 16) *
      (bodyStyle.height ?? 1.45);

  /// Çizgili defterde satır çizgileri sayfa içeriğinin İÇİNDE, her metin
  /// satırının altına çizilir (bkz. [RuledLines]).
  Widget _withRuledLines(Note note, TextStyle bodyStyle, Widget child) {
    if (!note.paged || !note.archivePaper.ruled) return child;
    final dashed = note.archivePaper == ArchivePaper.dashed;
    return RuledLines(
      gap: _paperGap(bodyStyle),
      color: Theme.of(context).colorScheme.outlineVariant.withValues(
        alpha: dashed ? 0.7 : 0.55,
      ),
      dashed: dashed,
      // Kaydırma alanının alt dolgusu (bkz. [_buildCanvas]).
      extraBottom: 96,
      child: child,
    );
  }

  /// Defter görünümünün kâğıt deseni: önizlemeli döşemeler, dokunuş ANINDA
  /// uygulanır ve levha açık kalır (bkz. [NotebookPaperPicker]).
  Future<void> _pickPaper() async {
    final note = _note;
    if (note == null) return;
    await showAppSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NotebookPaperPicker(
                initial: note.archivePaper,
                onChanged: (picked) {
                  if (!mounted) return;
                  _mutate(
                    (n) => n.copyWith(archivePaper: picked),
                    immediate: true,
                  );
                },
              ),
              // SATIR ARALIĞI (geliştirme raporu D1): dokunuş anında
              // uygulanır, levha açık kalır.
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: StatefulBuilder(
                  builder: (context, setSheetState) {
                    final l10n = context.l10n;
                    final current = _note?.lineSpacing ?? 1;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.lineSpacing,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 8),
                        SegmentedButton<double>(
                          key: const ValueKey('line-spacing'),
                          showSelectedIcon: false,
                          segments: [
                            ButtonSegment(
                              value: 1,
                              label: Text(l10n.lineSpacingNormal),
                            ),
                            ButtonSegment(
                              value: Note.lineSpacingWide,
                              label: Text(l10n.lineSpacingWide),
                            ),
                            ButtonSegment(
                              value: Note.lineSpacingWider,
                              label: Text(l10n.lineSpacingWider),
                            ),
                          ],
                          selected: {current},
                          onSelectionChanged: (v) {
                            if (!mounted) return;
                            _mutate(
                              (n) => n.copyWith(lineSpacing: v.first),
                              immediate: true,
                            );
                            setSheetState(() {});
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Notun ZEMİN görselini içeriğin ARKASINA serer.
  ///
  /// Görsel görünüm alanına sabitlenir (sayfa kaydırılırken kaymaz): duvar
  /// kâğıdı gibi durur, metin üstünde okunur kalsın diye opaklığı nottan
  /// gelir ve zeminin üstüne notun kendi rengiyle bir örtü çekilir.
  Widget _withBackground(Note note, Attachment? image, Widget child) {
    if (image == null) return child;
    final provider = _backgroundProvider(image);
    if (provider == null) return child;
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: Opacity(
            opacity: note.backgroundOpacity.clamp(0.05, 1),
            child: Image(image: provider, fit: BoxFit.cover),
          ),
        ),
        child,
      ],
    );
  }

  ImageProvider? _backgroundProvider(Attachment image) {
    // Önbellekli varlık denetimi + ekran genişliğine sınırlı decode: zemin
    // 1600 px'e kadar saklanıyor, tam boy bitmap'i bellekte tutmak boşuna.
    final targetWidth =
        (MediaQuery.sizeOf(context).width *
                MediaQuery.devicePixelRatioOf(context))
            .round();
    if (localFileExists(image.localPath)) {
      return ResizeImage(FileImage(File(image.localPath)), width: targetWidth);
    }
    if (image.downloadUrl.isNotEmpty) {
      return ResizeImage(
        CachedNetworkImageProvider(image.downloadUrl),
        width: targetWidth,
      );
    }
    return null;
  }

  /// Zemin görseli sayfası: seç / değiştir / kırp / görünürlük / kaldır.
  ///
  /// Kullanıcı isteği: "not zeminini seçilen bir fotoğraf yapma seçeneği
  /// olsun; koyarken kesme, üzerine yazı yazma, şeffaflığını değiştirme
  /// olsun ve sonradan da ayarlanabilsin."
  Future<void> _showBackgroundSheet() async {
    final note = _note;
    if (note == null) return;
    _dismissKeyboard();
    final l10n = context.l10n;
    await showAppSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          final current = _note;
          if (current == null) return const SizedBox.shrink();
          final image = current.backgroundImageId == null
              ? null
              : current.attachments
                    .where((a) => a.id == current.backgroundImageId)
                    .firstOrNull;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.noteBackgroundImage,
                    style: Theme.of(sheetContext).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  if (image != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: 120,
                        width: double.infinity,
                        child: _backgroundProvider(image) == null
                            ? const SizedBox.shrink()
                            : Image(
                                image: _backgroundProvider(image)!,
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.opacity,
                          size: 18,
                          color: Theme.of(sheetContext)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                        Expanded(
                          child: Slider(
                            value: current.backgroundOpacity.clamp(0.05, 1),
                            min: 0.05,
                            onChanged: (value) {
                              _mutate(
                                (n) => n.copyWith(backgroundOpacity: value),
                              );
                              setSheetState(() {});
                            },
                            onChangeEnd: (value) => _mutate(
                              (n) => n.copyWith(backgroundOpacity: value),
                              immediate: true,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 44,
                          child: Text(
                            '%${(current.backgroundOpacity * 100).round()}',
                            textAlign: TextAlign.end,
                            style: Theme.of(sheetContext).textTheme.labelMedium,
                          ),
                        ),
                      ],
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.crop),
                      title: Text(l10n.crop),
                      onTap: () async {
                        Navigator.pop(sheetContext);
                        await _cropBackground(image);
                      },
                    ),
                  ],
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.image_outlined),
                    title: Text(
                      image == null
                          ? l10n.chooseBackgroundImage
                          : l10n.changeBackgroundImage,
                    ),
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      await _pickBackgroundImage();
                    },
                  ),
                  if (image != null)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.hide_image_outlined),
                      title: Text(l10n.removeBackgroundImage),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _removeBackgroundImage(image);
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Zemin için görsel seçer: seçim → KIRPMA → ek olarak kaydet.
  Future<void> _pickBackgroundImage() async {
    final Uint8List bytes;
    final String name;
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 2400,
      maxHeight: 2400,
    );
    if (file == null) return;
    bytes = await file.readAsBytes();
    name = file.name;
    final repo = _attachments;
    if (repo == null) return;
    try {
      final attachment = await repo.prepareImage(
        noteId: widget.noteId,
        bytes: bytes,
        fileName: name,
      );
      final previous = _note?.backgroundImageId;
      _mutate(
        (n) => n.copyWith(
          attachments: [
            for (final a in n.attachments)
              if (a.id != previous) a,
            attachment,
          ],
          backgroundImageId: attachment.id,
        ),
        immediate: true,
      );
      if (!mounted) return;
      // Yerleştirirken kırpma: kullanıcı hangi bölgenin zemin olacağını seçer.
      await _cropBackground(attachment);
    } on FileTooLargeException catch (e) {
      if (mounted) _showSnack(_tooLargeMessage(e));
    } catch (e) {
      if (mounted) _showSnack(context.l10n.attachmentFailed('$e'));
    }
  }

  Future<void> _cropBackground(Attachment image) async {
    final provider = _backgroundProvider(image);
    if (provider == null) return;
    final aspect =
        (image.width ?? 1) /
        ((image.height ?? 1) == 0 ? 1 : (image.height ?? 1));
    final rect = await Navigator.of(context).push<Rect>(
      MaterialPageRoute(
        builder: (_) =>
            ImageCropScreen(image: provider, aspect: aspect <= 0 ? 1 : aspect),
      ),
    );
    if (rect == null || !mounted) return;
    await _cropImage(image, rect);
  }

  void _removeBackgroundImage(Attachment image) {
    _mutate(
      (n) => n.copyWith(
        attachments: [
          for (final a in n.attachments)
            if (a.id != image.id) a,
        ],
        clearBackgroundImage: true,
      ),
      immediate: true,
    );
    // Baytlar HEMEN silinmez: normal ek silmeyle aynı erteleme (bkz.
    // _pendingAttachmentDeletes). Anında silinince "Geri al" bozuk
    // (senkronsuz) bir kayda dönüyordu.
    _pendingAttachmentDeletes.add(image);
  }

  Widget _colorLeading(NoteColor color, {required bool frame, int? custom}) {
    final swatch = custom != null ? Color(custom) : NoteColors.swatch(color);
    final none = custom == null && color == NoteColor.none;
    return Container(
      width: 28,
      height: 28,
      decoration: frame && !none
          ? BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: swatch, width: 4),
            )
          : BoxDecoration(color: swatch, shape: BoxShape.circle),
      child: none
          ? const Icon(Icons.format_color_reset_outlined, size: 16)
          : null,
    );
  }

  void _delete() {
    // Açık olan notun deposu: paylaşılan notu çöpe atmak sahibin
    // koleksiyonundaki dokümanı işaretler (bkz. [NoteEditorScreen.ownerId]).
    final repo = _notesRepo;
    final note = _note;
    if (repo == null || note == null) return;
    _deleted = true;
    repo.softDelete(note.id);
    Navigator.of(context).pop();
  }

  /// Notun içeriğini (gövde + liste öğeleri) onay alarak temizler;
  /// başlık, etiketler ve ekler yerinde kalır.
  Future<void> _clearContent() async {
    final note = _note;
    if (note == null) return;
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.clearNote),
        content: Text(l10n.clearNoteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.clearNote),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false)) return;
    _bodyController.clear();
    _mutate((n) => n.copyWith(body: '', items: const []), immediate: true);
  }
}
