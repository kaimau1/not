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
    // ÖNCE TEMA ŞERİDİ (2026-10-28): palete basınca altta küçük sayfa
    // önizlemeleri kayar, dokunulan tema ANINDA sayfaya uygulanır (örnek
    // uygulamadaki gibi). Renk/çerçeve/zemin görseli şeridin altındaki
    // satırdan açılır.
    final action = await showNoteThemeSheet(
      context,
      current: note.theme,
      paper: note.paged,
      onTheme: (id) {
        if (!mounted) return;
        _mutate((n) => n.copyWith(theme: id), immediate: true);
      },
      color: note.color,
      customColor: note.customColor,
      onColor: (picked) {
        if (!mounted) return;
        _mutate(
          (n) => n.copyWith(
            color: picked.color,
            customColor: picked.custom,
            clearCustomColor: picked.custom == null,
            theme: '',
          ),
          immediate: true,
        );
      },
    );
    if (action == null || !mounted) return;
    final target = switch (action) {
      NoteAppearanceAction.color => 'bg',
      NoteAppearanceAction.frame => 'frame',
      NoteAppearanceAction.image => 'image',
      NoteAppearanceAction.paper => 'paper',
    };
    if (target == 'paper') {
      await _pickPaper();
      return;
    }
    if (target == 'image') {
      await _showBackgroundSheet();
      return;
    }
    await _pickNoteColor(frame: target == 'frame');
  }

  /// Zemin ya da çerçeve rengi seçici. Not ⋮ → Çerçeve de buraya gelir.
  Future<void> _pickNoteColor({required bool frame}) async {
    final note = _note;
    if (note == null) return;
    _dismissKeyboard();
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
                  // Renk seçilince çizilmiş tema kalkar (yoksa renk
                  // temanın altında görünmezdi).
                  theme: '',
                ),
          immediate: true,
        );
      },
    );
  }

  /// DEFTER GÖRÜNÜMÜ (F3.5): kâğıt deseni ekranın TAMAMININ (üst çubuk +
  /// gövde + alt panel) arkasında, satır aralığı gövde metninin satır
  /// yüksekliği.
  Widget _withPaper(
    Note note,
    TextStyle bodyStyle,
    Widget child, {
    double topChromeHeight = 0,
  }) {
    if (!note.paged) return child;
    return NotebookPaper(
      style: note.archivePaper,
      gap: _paperGap(bodyStyle),
      scroll: _pageScroll,
      topChromeHeight: topChromeHeight,
      // Çizgili desenlerde satırları içerik çizer (bkz. [_withRuledLines]);
      // belge notunun tuvali yok, orada ızgara kalır.
      contentRuled: !note.type.isPageNoteType,
      // Çizgi sayfanın kendi renginden/temasından (TEMA_PLANI F33.1).
      accent: _chrome.paperAccent,
      paperTheme: _chrome.paperTheme,
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
    final line = PaperInks.of(
      _chrome.paperTheme,
      accent: _chrome.paperAccent,
    ).line;
    return RuledLines(
      gap: _paperGap(bodyStyle),
      color: dashed
          ? line.withValues(alpha: (line.a * 1.25).clamp(0, 1))
          : line,
      dashed: dashed,
      // Kaydırma alanının alt dolgusu (bkz. [_buildCanvas]).
      extraBottom: 96,
      child: child,
    );
  }

  /// Çizgili defterde ([ArchivePaper.ruled]) sabit alt panelin arkasında
  /// yatay satır çizgilerini kesintisiz sürdürür.
  Widget _withBottomRuledLines(Note note, TextStyle bodyStyle, Widget child) {
    if (!note.paged || !note.archivePaper.ruled || note.type.isPageNoteType) {
      return child;
    }
    final line = PaperInks.of(
      _chrome.paperTheme,
      accent: _chrome.paperAccent,
    ).line;
    return NotebookRuledBand(
      style: note.archivePaper,
      gap: _paperGap(bodyStyle),
      line: line,
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
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.l,
                  AppSpace.xs,
                  AppSpace.l,
                  AppSpace.l,
                ),
                child: StatefulBuilder(
                  builder: (context, setSheetState) {
                    final l10n = context.l10n;
                    final theme = Theme.of(context);
                    final scheme = theme.colorScheme;
                    final current = _note?.lineSpacing ?? 1;
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(AppRadius.l),
                        border: Border.all(
                          color: scheme.outlineVariant.withValues(
                            alpha: AppAlpha.muted,
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpace.m),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              l10n.lineSpacing,
                              style: AppText.of(theme).label.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: AppSpace.s),
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
                        ),
                      ),
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

  /// Zemin görseli sayfası: hazır renkli zeminler + galeriden seç / kırp /
  /// görünürlük / kaldır.
  ///
  /// Kullanıcı isteği: "not zeminini seçilen bir fotoğraf yapma seçeneği
  /// olsun; koyarken kesme, üzerine yazı yazma, şeffaflığını değiştirme
  /// olsun ve sonradan da ayarlanabilsin" + "nota uygun renkli canlılık katacak
  /// yeni arka plan görselleri".
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
          final theme = Theme.of(sheetContext);
          final scheme = theme.colorScheme;
          final tokens = AppTokens.fromTheme(theme);
          final text = AppText.of(theme);
          final image = current.backgroundImageId == null
              ? null
              : current.attachments
                    .where((a) => a.id == current.backgroundImageId)
                    .firstOrNull;
          final activePresetId = image == null
              ? null
              : DashboardWallpapers.all
                    .where((w) => image.fileName == 'wallpaper_${w.id}.jpg')
                    .map((w) => w.id)
                    .firstOrNull;
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.l,
                0,
                AppSpace.l,
                AppSpace.l,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SheetHeader(
                    title: l10n.noteBackgroundImage,
                    padding: EdgeInsets.zero,
                    actions: [
                      if (image != null)
                        TextButton.icon(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            _removeBackgroundImage(image);
                          },
                          icon: const Icon(
                            Icons.hide_image_outlined,
                            size: AppIconSize.s,
                          ),
                          label: Text(l10n.removeBackgroundImage),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.s),
                  if (image != null) ...[
                    Container(
                      padding: const EdgeInsets.all(AppSpace.m),
                      decoration: AppSurface.sheetCard(theme),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.m),
                            child: SizedBox(
                              height: 112,
                              width: double.infinity,
                              child: _backgroundProvider(image) == null
                                  ? const SizedBox.shrink()
                                  : Image(
                                      image: _backgroundProvider(image)!,
                                      fit: BoxFit.cover,
                                      opacity: AlwaysStoppedAnimation(
                                        current.backgroundOpacity
                                            .clamp(0.05, 1)
                                            .toDouble(),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: AppSpace.s),
                          Row(
                            children: [
                              Icon(
                                Icons.opacity,
                                size: AppIconSize.s,
                                color: scheme.primary,
                              ),
                              Expanded(
                                child: Slider(
                                  value: current.backgroundOpacity.clamp(
                                    0.05,
                                    1,
                                  ),
                                  min: 0.05,
                                  onChanged: (value) {
                                    _mutate(
                                      (n) => n.copyWith(
                                        backgroundOpacity: value,
                                      ),
                                    );
                                    setSheetState(() {});
                                  },
                                  onChangeEnd: (value) => _mutate(
                                    (n) => n.copyWith(backgroundOpacity: value),
                                    immediate: true,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpace.s,
                                  vertical: AppSpace.xxs,
                                ),
                                decoration: BoxDecoration(
                                  color: tokens.resolvedTintSoft(scheme),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.s,
                                  ),
                                ),
                                child: Text(
                                  '%${(current.backgroundOpacity * 100).round()}',
                                  style: text.badge.copyWith(
                                    color: scheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpace.m),
                  ],
                  // Hazır renkli arka plan galerisi.
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpace.m),
                    decoration: AppSurface.sheetCard(theme),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.dashboardBackgroundGallery,
                          style: text.section,
                        ),
                        const SizedBox(height: AppSpace.s),
                        SizedBox(
                          height: 122,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: DashboardWallpapers.all.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: AppSpace.s),
                            itemBuilder: (_, i) {
                              final w = DashboardWallpapers.all[i];
                              final selected = activePresetId == w.id;
                              return PressScale(
                                child: GestureDetector(
                                  key: ValueKey('note-wallpaper-${w.id}'),
                                  onTap: () async {
                                    await _applyPresetWallpaper(w);
                                    if (sheetContext.mounted) {
                                      setSheetState(() {});
                                    }
                                  },
                                  child: SizedBox(
                                    width: 74,
                                    child: Column(
                                      children: [
                                        Container(
                                          height: 92,
                                          padding: const EdgeInsets.all(
                                            AppSpace.xxs,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              AppRadius.m,
                                            ),
                                            border: Border.all(
                                              color: selected
                                                  ? scheme.primary
                                                  : tokens.hairline,
                                              width: selected ? 2.5 : 1,
                                            ),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              AppRadius.s,
                                            ),
                                            child: Stack(
                                              fit: StackFit.expand,
                                              children: [
                                                Image.asset(
                                                  w.asset,
                                                  fit: BoxFit.cover,
                                                  cacheWidth: 240,
                                                ),
                                                if (selected)
                                                  Positioned(
                                                    right: AppSpace.xs,
                                                    top: AppSpace.xs,
                                                    child: CircleAvatar(
                                                      radius: 9,
                                                      backgroundColor:
                                                          scheme.primary,
                                                      child: Icon(
                                                        Icons.check,
                                                        size:
                                                            AppIconSize.xs - 3,
                                                        color: scheme.onPrimary,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: AppSpace.xs),
                                        Text(
                                          w.label(l10n),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: text.meta.copyWith(
                                            fontWeight: selected
                                                ? AppWeight.strong
                                                : AppWeight.medium,
                                            color: selected
                                                ? scheme.primary
                                                : scheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.m),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonalIcon(
                          style: FilledButton.styleFrom(
                            backgroundColor: scheme.primaryContainer,
                            foregroundColor: scheme.onPrimaryContainer,
                          ),
                          onPressed: () async {
                            Navigator.pop(sheetContext);
                            await _pickBackgroundImage();
                          },
                          icon: const Icon(
                            Icons.image_outlined,
                            size: AppIconSize.s,
                          ),
                          label: Text(
                            image == null
                                ? l10n.dashboardBackgroundFromDevice
                                : l10n.changeBackgroundImage,
                          ),
                        ),
                      ),
                      if (image != null) ...[
                        const SizedBox(width: AppSpace.s),
                        OutlinedButton.icon(
                          onPressed: () async {
                            Navigator.pop(sheetContext);
                            await _cropBackground(image);
                          },
                          icon: const Icon(Icons.crop, size: AppIconSize.s),
                          label: Text(l10n.crop),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Hazır renkli arka planı notun zemin görseli olarak ekler.
  Future<void> _applyPresetWallpaper(DashboardWallpaper wallpaper) async {
    final repo = _attachments;
    if (repo == null) return;
    try {
      unawaited(AppHaptics.tick());
      final data = await rootBundle.load(wallpaper.asset);
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      final attachment = await repo.prepareImage(
        noteId: widget.noteId,
        bytes: bytes,
        fileName: 'wallpaper_${wallpaper.id}.jpg',
      );
      if (!mounted) return;
      final previous = _note?.backgroundImageId;
      _mutate(
        (n) => n.copyWith(
          attachments: [
            for (final a in n.attachments)
              if (a.id != previous) a,
            attachment,
          ],
          backgroundImageId: attachment.id,
          backgroundOpacity: wallpaper.defaultOpacity,
        ),
        immediate: true,
      );
    } on FileTooLargeException catch (e) {
      if (mounted) _showSnack(_tooLargeMessage(e));
    } catch (e) {
      if (mounted) {
        _showSnack(
          context.l10n.attachmentFailed(friendlyError(context.l10n, e)),
        );
      }
    }
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
      if (mounted) _showSnack(context.l10n.attachmentFailed(friendlyError(context.l10n, e)));
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

  void _delete() {
    // Açık olan notun deposu: paylaşılan notu çöpe atmak sahibin
    // koleksiyonundaki dokümanı işaretler (bkz. [NoteEditorScreen.ownerId]).
    final repo = _notesRepo;
    final note = _note;
    if (repo == null || note == null) return;
    _deleted = true;
    repo.softDelete(note.id);
    _closeEditor(() => Navigator.of(context).pop());
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
