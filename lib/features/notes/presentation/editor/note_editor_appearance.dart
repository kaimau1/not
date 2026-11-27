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
    await showAppearanceStudio(
      context,
      contextMode: AppearanceContext.note,
      initialTab: AppearanceTab.background,
      noteBridge: NoteAppearanceBridge(
        readNote: () => _note ?? note,
        onTheme: (id) {
          if (!mounted) return;
          _mutate(
            (n) => n.copyWith(
              theme: id,
              color: id.isNotEmpty ? NoteColor.none : null,
              clearCustomColor: id.isNotEmpty,
            ),
            immediate: true,
          );
        },
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
        onFrame: (picked) {
          if (!mounted) return;
          _mutate(
            (n) => n.copyWith(
              frameColor: picked.color,
              customFrameColor: picked.custom,
              clearCustomFrameColor: picked.custom == null,
            ),
            immediate: true,
          );
        },
        onPresetWallpaper: _applyPresetWallpaper,
        onPickImage: _pickBackgroundImage,
        onRemoveImage: () async {
          final current = _note;
          final bgId = current?.backgroundImageId;
          if (current == null || bgId == null) return;
          final bg = current.attachments.where((a) => a.id == bgId).firstOrNull;
          if (bg != null) {
            _removeBackgroundImage(bg);
          } else {
            _mutate(
              (n) => n.copyWith(clearBackgroundImage: true),
              immediate: true,
            );
          }
        },
        onCropImage: () async {
          final current = _note;
          final bgId = current?.backgroundImageId;
          if (current == null || bgId == null) return;
          final bg = current.attachments.where((a) => a.id == bgId).firstOrNull;
          if (bg != null) await _cropBackground(bg);
        },
        onBgOpacity: (value) {
          if (!mounted) return;
          _mutate((n) => n.copyWith(backgroundOpacity: value), immediate: true);
        },
        onPaper: (paper) {
          if (!mounted) return;
          _mutate((n) => n.copyWith(archivePaper: paper), immediate: true);
        },
        onLineSpacing: (spacing) {
          if (!mounted) return;
          _mutate((n) => n.copyWith(lineSpacing: spacing), immediate: true);
        },
        onPaged: (paged) {
          if (!mounted) return;
          _mutate((n) => n.copyWith(paged: paged), immediate: true);
        },
        onUseHomeBackground: () {
          if (!mounted) return;
          final current = _note;
          final bgId = current?.backgroundImageId;
          final bg = current != null && bgId != null
              ? current.attachments.where((a) => a.id == bgId).firstOrNull
              : null;
          _mutate(
            (n) => n.copyWith(
              theme: '',
              color: NoteColor.none,
              clearCustomColor: true,
              clearBackgroundImage: true,
              attachments: bg == null
                  ? null
                  : [
                      for (final a in n.attachments)
                        if (a.id != bg.id) a,
                    ],
            ),
            immediate: true,
          );
        },
      ),
    );
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
                              style: AppText.of(theme).label
                                  .copyWith(color: scheme.onSurfaceVariant),
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
      if (mounted) {
        _showSnack(
          context.l10n.attachmentFailed(friendlyError(context.l10n, e)),
        );
      }
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
