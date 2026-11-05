part of 'note_editor_screen.dart';

/// Ekler: görsel/PDF/sunum/ses/video ekleme, etiket gömme, seçim menüleri, kopyala/yapıştır, kırp/döndür, döküm, PDF düzenleme.
///
/// F9.3: editör konu başına bölündü; durum (alanlar) [_NoteEditorScreenState]da kalır.
extension _EditorAttachments on _NoteEditorScreenState {
  /// Yeni görselin sayfadaki başlangıç yeri ve boyu.
  ///
  /// Görsel YAZILAN SATIRA girer: eskiden sayfanın en üstüne ya da son görselin
  /// altına konuyordu, yani kullanıcı görseli her seferinde metnin yanına elle
  /// sürüklemek zorundaydı. İmleç ölçülemediyse (menüden gelmeyen akışlar, boş
  /// not) eski davranışa — mevcut içeriğin altına — düşülür. Boyut küçük (%32)
  /// başlar; tam genişlik metni tümüyle aşağı iterdi.
  Attachment _placeNewImage(Attachment placed, Note note) {
    // METİN ve SES kutusunun kendi ölçüsü yok: sayfadaki kutunun oranı ekte
    // saklanır (metin kâğıt sayfası 1:1,3, ses oynatıcı kartı ~3,6:1) ki
    // tuvalin bütün oran hesapları (sarma, yerleşim, boyutlandırma)
    // görseldeki gibi çalışsın (bkz. text_page_box.dart, audio_card_box.dart).
    final image = placed.width != null && placed.height != null
        ? placed
        : switch (placed.kind) {
            AttachmentKind.text => placed.copyWith(
              width: kTextBoxWidth,
              height: kTextBoxHeight,
            ),
            AttachmentKind.audio => placed.copyWith(
              width: kAudioBoxWidth,
              height: kAudioBoxHeight,
            ),
            // Sunum 16:9 başlar; kutu ilk slaydı açınca gerçek oranı yazar
            // (bkz. SlidePageBox).
            AttachmentKind.slide => placed.copyWith(width: 1600, height: 900),
            _ => placed,
          };
    // PDF kutusu GENİŞ başlar: 0,32 genişlikte bir sayfada yazı okunmuyor,
    // kullanıcı her belgeyi elle büyütmek zorunda kalıyordu. Görselde 0,32
    // kalıyor — satıra üç görsel sığsın (bkz. packSlot). Metin okunacak,
    // ses kartı da düğmeleri sığacak kadar geniş başlar.
    final width = switch (image.kind) {
      AttachmentKind.pdf => 0.6,
      AttachmentKind.text || AttachmentKind.slide => 0.8,
      // Ses HAPI satırı boydan boya kaplar (örnek uygulamadaki sesli not).
      AttachmentKind.audio => 1.0,
      _ => 0.32,
    };
    final pageWidth = _pageBox()?.size.width ?? 0;
    // SAYFA HENÜZ ÖLÇÜLMEDİ: dp hesabı yapılamaz, konum YAZILMAZ. Tuval
    // genişliği bildiği ilk karede görseli boş bir yere kendisi oturtur
    // (bkz. [packSlot]).
    //
    // KÖK NEDEN (kullanıcı 2026-09-05: "birden fazla görsel eklendiğinde üst
    // üste başlıyor"): burada eski görsellerin ALTI `pageWidth * displayWidth
    // / oran` ile ölçülüyordu. Ölçüm yokken `pageWidth` 0 olduğu için her
    // görselin "altı" kendi tepesine eşitleniyor, yeni görsel bir öncekinin
    // 16 dp altına — yani pratikte ÜSTÜNE — düşüyordu. Paylaşımdan gelen ve
    // çoklu seçimle eklenen görseller tam bu yoldan geçiyor.
    // SAYFALI NOT: görsel ETKİN sayfaya aittir (bkz. Note.textPages).
    final section = note.activePage;
    if (pageWidth <= 0) {
      return image.copyWith(displayWidth: width, section: section);
    }

    Rect boxOf(Attachment a) {
      final aspect = (a.width != null && a.height != null && a.height! > 0)
          ? a.width! / a.height!
          : 1.0;
      final w = pageWidth * (a.displayWidth ?? 0.5);
      return Rect.fromLTWH(
        (a.x ?? 0.06) * pageWidth,
        a.pageY ?? (a.y != null ? a.y! * kLegacyCanvasHeight : 0),
        w,
        w / aspect,
      );
    }

    // İmleç yoksa GÖRÜNEN alanın tepesi (kullanıcı isteği 2026-08-09: "görsel
    // eklendiğinde direk ekrana"). Eskiden ölçüm olmayan yollarda görsel var
    // olan bütün eklerin ALTINA yığılıyordu — uzun bir notta bu, ekranın
    // metrelerce aşağısı demekti: görsel eklenince ekranda hiçbir şey
    // değişmiyor, kullanıcı "eklenmedi" sanıyordu.
    final visibleTop = _pageScroll.hasClients ? _pageScroll.offset + 24 : null;
    final anchor = _caretPageY ?? visibleTop ?? (_bodyTop + 24);
    final aspect =
        (image.width != null && image.height != null && image.height! > 0)
        ? image.width! / image.height!
        : 1.0;
    final w = pageWidth * width;
    // Yeni görsel önce SATIRDA yan yana yer arar (0,32 genişlikle satıra üç
    // görsel sığar), yer kalmayınca alta iner — hiçbirinin üstüne binmez.
    final slot = packSlot(
      occupied: [
        for (final a in note.attachments)
          // Konumu yazılmamış ekler tuvalde zaten otomatik yerleşiyor;
          // onların dp kutusu burada bilinemez.
          if (a.floatsOnPage &&
              a.section == note.activePage &&
              (a.pageY != null || a.y != null))
            boxOf(a),
      ],
      columnWidth: pageWidth,
      width: w,
      height: w / aspect,
      anchorTop: anchor,
      topLimit: _bodyTop,
    );
    var top = slot.top;
    // Sayfanın altına taşmasın: içerik yüksekliğini aşarsa oraya sabitlenir.
    final pageHeight = _pageBox()?.size.height;
    if (pageHeight != null && top > pageHeight) top = pageHeight;
    return image.copyWith(
      x: slot.left / pageWidth,
      pageY: top,
      displayWidth: width,
      section: section,
    );
  }

  /// [asFile] true ise görsel sayfaya yerleşmez, alt şeritte dosya eki olur.
  /// Eklenen eki döner (gömme akışı onu seçili yazıya bağlar).
  Future<Attachment?> _addImageBytes(
    Uint8List bytes,
    String fileName, {
    bool asFile = false,
  }) async {
    final repo = _attachments;
    if (repo == null) return null;
    try {
      // Sıkıştırma + diske yazma büyük fotoğrafta saniyeler sürüyor ve o süre
      // boyunca ekranda hiçbir iz yoktu (bkz. [_busyTaskN]).
      final attachment = await _runBusy(
        context.l10n.attachmentUploading,
        () => repo.prepareImage(
          noteId: widget.noteId,
          bytes: bytes,
          fileName: fileName,
        ),
      );
      if (!mounted) return null;
      Attachment? added;
      _mutate((n) {
        added = asFile
            ? attachment.copyWith(asFile: true)
            : _placeNewImage(attachment, n);
        return n.copyWith(attachments: [...n.attachments, added!]);
      }, immediate: true);
      return added;
    } on FileTooLargeException catch (e) {
      if (mounted) _showSnack(_tooLargeMessage(e));
    } catch (e) {
      // Yalnız FileTooLargeException yakalanıyordu; başka her hata (web'de
      // dosya sistemi yok, disk dolu, izin reddi) yukarı kaçıp await'i
      // tamamlanmadan bırakıyordu → ekran donmuş görünüyor, mesaj çıkmıyordu.
      if (mounted) _showSnack(context.l10n.attachmentFailed(friendlyError(context.l10n, e)));
    }
    return null;
  }

  /// [asFile] true ise seçilen görsel sayfaya değil ek şeridine girer.
  ///
  /// **ÇOKLU SEÇİM** (kullanıcı isteği 2026-08-09: "aynı anda birden fazla ek
  /// yüklenebilsin"): seçici tek dosyayla sınırlıydı; beş fotoğraf eklemek
  /// için "Ekle → Görsel" yolunu beş kez yürümek gerekiyordu. Seçilenler
  /// SIRAYLA eklenir (paralel değil): her ek notu yazıyor ve sayfadaki yerini
  /// bir öncekine göre hesaplıyor (bkz. [_placeNewImage]) — aynı anda
  /// koşsalardı hepsi aynı noktaya biner, üstelik büyük görsellerin
  /// sıkıştırması aynı anda belleğe yığılırdı.
  Future<void> _pickImage({bool asFile = false}) async {
    // Boyut tavanı platform tarafında uygulanır: 48 MP'lik bir fotoğrafın
    // ~20 MB'ı ana izoleye okunup sıkıştırma izolesine kopyalanıyordu;
    // ek zaten 1600 px'e küçültülüyor (bkz. _compressImage), kalite kaybı yok.
    final files = await ImagePicker().pickMultiImage(
      maxWidth: 2400,
      maxHeight: 2400,
    );
    for (final file in files) {
      if (!mounted) return;
      await _addImageBytes(await file.readAsBytes(), file.name, asFile: asFile);
    }
  }

  /// **TEK "DOSYA EKLE"** (2026-10-20): her desteklenen dosya tek seçiciden;
  /// tür uzantıdan. Görsel sayfaya yerleşir; PDF, sunum, ses ve video kendi
  /// yollarına seçici SORULMADAN verilir ([DocPicker.preselect]). HEIC
  /// görsel PNG'ye çevrilir.
  Future<void> _attachAnyFile() async {
    final l10n = context.l10n;
    final files = await DocPicker.pickMany(
      XTypeGroup(
        label: l10n.quickAddFile,
        extensions: PickedFileKind.allExtensions,
        mimeTypes: [
          'image/*',
          'video/*',
          'audio/*',
          'application/pdf',
          DocPicker.byExtension['pptx']!,
        ],
      ),
      chooserTitle: l10n.quickAddFile,
    );
    await _attachFiles(files);
  }

  /// Seçilen ya da açık nota bırakılan dosyalar (F41.4): tür tanınır, gerekirse
  /// ortak levha ([showFileUseSheet]) sorar.
  Future<void> _attachFiles(List<XFile> files) async {
    final l10n = context.l10n;
    if (files.isEmpty || !mounted) return;
    String nameOf(XFile f) => f.name.isEmpty ? f.path : f.name;
    final kind = PickedFileKind.of(nameOf(files.first));
    if (kind == null) {
      _showSnack(l10n.quickAddFileUnsupported);
      return;
    }
    var same = [
      for (final f in files)
        if (PickedFileKind.of(nameOf(f)) == kind) f,
    ];
    Future<void> handOff(
      List<XFile> pick,
      Future<Object?> Function() flow,
    ) async {
      DocPicker.preselect(pick);
      try {
        await flow();
      } finally {
        DocPicker.takePreselected();
      }
    }

    switch (kind) {
      case PickedFileKind.image:
        same = await normalizeHeicImages(same);
        if (same.isEmpty) {
          if (mounted) _showSnack(l10n.quickAddFileUnsupported);
          return;
        }
        // Ek levhası sadeleşti (2026-10-20): "Görseli ek olarak yükle" ayrı
        // giriş değil, burada sorulur.
        final use = await _askFileUse(kind, same);
        if (use == null || !mounted) return;
        for (final f in same) {
          if (!mounted) return;
          await _addImageBytes(
            await f.readAsBytes(),
            nameOf(f).split(RegExp(r'[\\/]')).last,
            asFile: use == FileUse.imageFile,
          );
        }
      case PickedFileKind.pdf:
        await handOff(same, _pickPdf);
      case PickedFileKind.slides:
        await handOff([same.first], _pickSlide);
      case PickedFileKind.video:
      case PickedFileKind.audio:
        // "Ses dosyası ekle", "Galeriden video" ve "Dosyayı metne dök" ayrı
        // girişler değil: tür tanınır, ne yapılacağı sorulur.
        final use = await _askFileUse(kind, same);
        if (use == null || !mounted) return;
        await handOff(
          [same.first],
          use == FileUse.transcribe
              ? _transcribeFile
              : kind == PickedFileKind.video
              ? _addVideoFromGallery
              : _pickAudioFile,
        );
    }
  }

  /// "Dosya ekle"de seçilen dosyayla ne yapılacağı (görsel: sayfaya / ek
  /// olarak; ses-video: ek olarak / metne dök). İptalde null.
  Future<FileUse?> _askFileUse(PickedFileKind kind, List<XFile> files) async {
    final choice = await showFileUseSheet(
      context,
      kind: kind,
      inNote: true,
      names: [
        for (final f in files) (f.name.isEmpty ? f.path : f.name).split(RegExp(r'[\\/]')).last,
      ],
    );
    return choice?.use;
  }

  /// "Foto çek not al": kamerayla fotoğraf çekip nota gömer. Çekilen fotoğraf
  /// sıradan bir görsel ektir — sayfada sürüklenir, boyutlandırılır, üzerine
  /// yazılır ve "Metni al" ile OCR edilebilir.
  Future<void> _takePhoto() async {
    final l10n = context.l10n;
    // Manifest'te CAMERA bildirildiği için Android çekim niyetini izin
    // olmadan REDDEDER (bkz. _addVideo).
    final perms = ref.read(permissionsServiceProvider);
    if (!await perms.cameraGranted() && !await perms.requestCamera()) {
      if (mounted) _showSnack(l10n.permCameraInfo);
      return;
    }
    if (!mounted) return;
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxWidth: 2400,
        maxHeight: 2400,
      );
      if (picked == null) return;
      await _addImageBytes(await picked.readAsBytes(), picked.name);
    } catch (e) {
      if (mounted) _showSnack(l10n.attachmentFailed(friendlyError(l10n, e)));
    }
  }

  /// "Belge tara": kamerayla belge tarar. Sayfalar önce İNCELEME ekranından geçer (köşe düzeltme, filtre,
  /// döndürme — dosya-okuyucu projesinden taşınan boru hattı) ve sonuç ya
  /// **tek aranabilir PDF eki** ya da düzeltilmiş görsel ekleri olur.
  ///
  /// Görsel yolunda tarama bitince "yazılar da tanınsın mı?" sorulur; evet
  /// denirse sayfalar OCR'lanıp metin notun gövdesine yazılır. Soru sessizce
  /// atlanmıyor: OCR sayfa başına birkaç saniye sürüyor ve AI kotasından
  /// yiyor. (PDF yolunda soruya gerek yok: metin katmanı cihazda, ücretsiz.)
  Future<void> _scanDocument() async {
    final l10n = context.l10n;
    List<String>? pages;
    if (DocumentScan.supported) {
      // Manifest'te CAMERA bildirildiği için Android çekim niyetini izin
      // olmadan REDDEDER (bkz. _takePhoto).
      final perms = ref.read(permissionsServiceProvider);
      if (!await perms.cameraGranted() && !await perms.requestCamera()) {
        if (mounted) _showSnack(l10n.permCameraInfo);
        return;
      }
      if (!mounted) return;
      try {
        pages = await DocumentScan.scanPages();
      } catch (e) {
        if (mounted) _showSnack(l10n.scanFailed(friendlyError(l10n, e)));
        return;
      }
    } else {
      _showSnack(l10n.scanUnsupported);
      return;
    }
    if (pages == null || pages.isEmpty || !mounted) return;

    final result = await ScanReviewScreen.open(context, pages);
    if (result == null || !mounted) return;

    final pdfBytes = result.pdfBytes;
    if (pdfBytes != null) {
      final repo = _attachments;
      if (repo == null) return;
      try {
        final attachment = await _runBusy(
          context.l10n.attachmentUploading,
          () => repo.preparePdf(
            noteId: widget.noteId,
            bytes: pdfBytes,
            fileName: scanFileName(result.title, DateTime.now()),
          ),
        );
        _mutate(
          (n) => n.copyWith(attachments: [...n.attachments, attachment]),
          immediate: true,
        );
        if (mounted) _showSnack(l10n.scanPdfAdded);
      } on FileTooLargeException catch (e) {
        if (mounted) _showSnack(_tooLargeMessage(e));
      } catch (e) {
        if (mounted) _showSnack(l10n.attachmentFailed(friendlyError(l10n, e)));
      }
      return;
    }

    // Görsel yolu: sayfa baytları bir kez okunur — hem eke hem (istenirse)
    // OCR'a aynı baytlar gider, dosya iki kez okunmaz.
    final pageBytes = <Uint8List>[];
    for (final path in result.imagePaths ?? const <String>[]) {
      final bytes = await DocumentScan.readPage(path);
      if (bytes != null) pageBytes.add(bytes);
    }
    if (pageBytes.isEmpty) {
      if (mounted) _showSnack(l10n.scanFailed('—'));
      return;
    }
    for (var i = 0; i < pageBytes.length; i++) {
      if (!mounted) return;
      await _addImageBytes(pageBytes[i], 'tarama-${i + 1}.jpg');
    }
    if (!mounted) return;
    _showSnack(l10n.scanPagesAdded(pageBytes.length));

    final wantsText = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.scanTextTitle),
        content: Text(l10n.scanTextBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.scanImageOnly),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.scanRecognizeText),
          ),
        ],
      ),
    );
    if (wantsText != true || !mounted) return;
    await _runAi(l10n.scanRecognizing, () async {
      final service = ref.read(geminiServiceProvider);
      for (final bytes in pageBytes) {
        final text = stripMarkdown(
          await service.extractTextFromImage(bytes, 'image/jpeg'),
        ).trim();
        if (!mounted) return;
        if (text.isNotEmpty) _appendText(text);
      }
    });
  }

  /// QR/barkod okur (kameradan ya da galerideki bir fotoğraftan) ve okunan
  /// metni notun içine ekler.
  Future<void> _scanQr() async {
    final l10n = context.l10n;
    final perms = ref.read(permissionsServiceProvider);
    if (!await perms.cameraGranted() && !await perms.requestCamera()) {
      if (mounted) _showSnack(l10n.permCameraInfo);
      return;
    }
    if (!mounted) return;
    final code = await openQrScanner(context);
    if (code == null || !mounted) return;
    _appendPlainText(code);
  }

  // Gövdenin imleç altındaki bağlantı/etiket sorguları seçim menüsünün
  // ortak kurucusuna taşındı (bkz. [_selectionMenu]) — madde satırları da
  // aynı yolu kullanıyor.

  /// Gövdede DOKUNULAN etiket (imleç etiketin İÇİNDE — sınırlar hariç, bkz.
  /// [attachmentTagInside]) ve bağlı olduğu ek.
  ///
  /// Sınırda (son harfin sağ yarısı) dokunuşun KONUMUNA bakılır — bkz.
  /// [tappedAttachmentTag].
  ({String label, Attachment attachment})? _tappedEmbed(
    EditableTextState? editable,
  ) {
    final note = _note;
    final selection = _bodyController.selection;
    if (note == null || !selection.isValid || !selection.isCollapsed) {
      return null;
    }
    final tag = tappedAttachmentTag(
      logicalText: _bodyController.logicalText,
      logicalCaret: wrapToLogicalOffset(
        _bodyController.text,
        selection.baseOffset,
      ),
      displayText: _bodyField.text,
      selection: selection,
      names: _bodyController.attachmentNames,
      editable: editable,
      tapGlobal: _bodyTapPoint.last,
    );
    if (tag == null) return null;
    final attachment = _NoteEditorScreenState._attachmentForTag(
      note,
      tag.fileName,
    );
    if (attachment == null) return null;
    return (label: tag.fileName, attachment: attachment);
  }

  /// Gövdenin seçim menüsü (bkz. [_selectionMenu]).
  Widget _bodyContextMenu(BuildContext menuContext, EditableTextState state) =>
      _selectionMenu(
        state,
        _bodyController,
        commit: () => _mutate(
          (n) => n.copyWith(body: _bodyController.logicalText),
          immediate: true,
        ),
      );

  /// GÖVDE ve MADDE SATIRLARININ ortak seçim menüsü (kullanıcı bulgusu
  /// 2026-10-15: "metin seçim mantığı ve kalitesi düzeltilmeli" — madde
  /// satırında ek gömme, etiket önizleme ve bağlantıyı aç hiç yoktu; sıra
  /// için bkz. [arrangeSelectionMenu]).
  ///
  /// [target] madde satırında alanın kendisi (gömme oraya yazılır); gövdede
  /// null. [trailing] alanın kendi ek seçenekleri (Tüm notu kopyala).
  Widget _selectionMenu(
    EditableTextState state,
    WrapTextController controller, {
    required VoidCallback commit,
    FormatTarget? target,
    List<ContextMenuButtonItem> trailing = const [],
  }) {
    final l10n = context.l10n;
    final selection = state.textEditingValue.selection;
    final hasSelection = selection.isValid && !selection.isCollapsed;
    final note = _note;
    final logical = controller.logicalText;
    final caret = selection.isValid
        ? wrapToLogicalOffset(
            controller.text,
            selection.baseOffset,
          ).clamp(0, logical.length)
        : -1;
    final url = caret < 0 ? null : linkAt(logical, caret);
    final tagLabel = caret < 0 || note == null
        ? null
        : attachmentTagAt(logical, caret, controller.attachmentNames);
    final tagged = tagLabel == null
        ? null
        : _NoteEditorScreenState._attachmentForTag(note!, tagLabel);
    final linkedNote = tagLabel == null || note == null
        ? null
        : noteLinkTarget(note, tagLabel);
    void run(VoidCallback action) {
      state.hideToolbar();
      action();
    }

    final leading = <ContextMenuButtonItem>[
      // BAĞLAMA KİPİ açıksa ilk madde odur: kullanıcı yazıyı yeni seçti,
      // yapacağı tek iş bağlamak.
      if (_pendingEmbed != null && hasSelection)
        ContextMenuButtonItem(
          label: l10n.attachmentTagLinkHere,
          onPressed: () => run(_finishPendingEmbed),
        ),
      // İmleç bir EK ETİKETİNİN üstündeyse önizleme birinci iş.
      if (tagged != null)
        ContextMenuButtonItem(
          label: l10n.attachmentTagPreview,
          onPressed: () => run(() => _showEmbedPreviewFor(tagged, tagLabel!)),
        ),
      if (linkedNote != null)
        ContextMenuButtonItem(
          label: l10n.noteLinkOpen,
          onPressed: () =>
              run(() => _openLinkedNote(linkedNote, editing: false)),
        ),
      if (url != null)
        ContextMenuButtonItem(
          label: l10n.openLink,
          onPressed: () => run(() {
            openLink(url).then((opened) {
              if (!opened && mounted) _showSnack(l10n.linkOpenFailed);
            });
          }),
        ),
    ];
    final afterClipboard = <ContextMenuButtonItem>[
      // Biçim: seçili metne kalın/italik/altı çizili/renk uygular. Giriş
      // noktası SEÇİM çubuğu — biçim zaten "şu metne" uygulanır.
      if (hasSelection)
        ContextMenuButtonItem(
          label: l10n.formatMenu,
          onPressed: () => run(
            () => showFormatSheet(
              context,
              controller: controller,
              onApplied: commit,
            ),
          ),
        ),
      // SEÇİLİ YAZIYA EK GÖM: seçim varsa ve o seçim zaten bir etiket değilse.
      if (hasSelection && tagged == null && !_readOnly)
        ContextMenuButtonItem(
          label: l10n.attachmentTagEmbed,
          onPressed: () => run(
            () => unawaited(_embedIntoSelection(controller, target: target)),
          ),
        ),
      // NOTA BAĞLA (F18.16): seçili yazı ya da imleç (başlık yazılır).
      if (tagged == null && linkedNote == null && !_readOnly)
        ContextMenuButtonItem(
          label: l10n.noteLinkAction,
          onPressed: () =>
              run(() => unawaited(_linkToNote(controller, target: target))),
        ),
      if (linkedNote != null)
        ContextMenuButtonItem(
          label: l10n.embedRemove,
          onPressed: () => run(() => _unlinkEmbed(tagLabel!)),
        ),
      if (tagged != null) ...[
        ContextMenuButtonItem(
          label: l10n.attachmentTagEdit,
          onPressed: () => run(() => _openAttachmentTag(tagged, editing: true)),
        ),
        ContextMenuButtonItem(
          label: l10n.copyAttachment,
          onPressed: () => run(() => unawaited(_copyAttachment(tagged))),
        ),
        ContextMenuButtonItem(
          label: l10n.embedRemove,
          onPressed: () => run(() => _unlinkEmbed(tagLabel!)),
        ),
      ],
    ];
    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: state.contextMenuAnchors,
      buttonItems: arrangeSelectionMenu(
        // Kes/Kopyala temiz-metin sürümleri: varsayılanlar panoya biçim
        // işaretlerini (`**`, `%%1:`) ve görünmez sarma çapalarını HAM
        // yazıyordu — dışarı yapıştıran kullanıcı çöp görüyordu.
        platform: cleanClipboardMenuItems(state),
        leading: leading,
        afterClipboard: afterClipboard,
        trailing: trailing,
      ),
    );
  }

  /// Madde satırının seçim menüsü: gövdeyle aynı kurucu, gömme o satıra.
  Widget _itemSelectionMenu(
    EditableTextState state,
    WrapTextController controller,
    VoidCallback commit,
    List<ContextMenuButtonItem> own,
  ) => _selectionMenu(
    state,
    controller,
    commit: commit,
    target: FormatTarget(
      controller: controller,
      focusNode: state.widget.focusNode,
      commit: commit,
    ),
    trailing: own,
  );

  /// **ÇOKLU SEÇİM** (kullanıcı isteği 2026-08-09: "aynı anda birden fazla ek
  /// yüklenebilsin"): seçilen belgeler sırayla eklenir; biri hata verse
  /// (tavanı aşan dosya, okunamayan içerik) kalanlar yine girer.
  Future<void> _pickPdf() async {
    const group = XTypeGroup(
      label: 'PDF',
      extensions: ['pdf'],
      mimeTypes: ['application/pdf'],
    );
    final files = await DocPicker.pickMany(
      group,
      chooserTitle: context.l10n.pickPdfTitle,
    );
    for (final file in files) {
      if (!mounted) return;
      await _addPdfFile(file);
    }
  }

  /// [asFile] true ise PDF sayfaya konmaz, ek şeridinde durur (gömme
  /// akışı). Eklenen eki döner.
  Future<Attachment?> _addPdfFile(XFile file, {bool asFile = false}) async {
    final bytes = await file.readAsBytes();
    // PDF sıkıştırılamaz (görsel ve ses küçültülüyor, bu küçültülemiyor) —
    // büyük dosya Firebase Storage kotasına doğrudan gider. Engellemek yerine
    // boyutu söyleyip kullanıcıya soruyoruz.
    if (bytes.length > AppConstants.largeAttachmentWarnBytes && mounted) {
      final mb = (bytes.length / (1024 * 1024)).toStringAsFixed(1);
      final proceed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(context.l10n.largeAttachmentTitle),
          content: Text(context.l10n.largeAttachmentBody(mb)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(context.l10n.ok),
            ),
          ],
        ),
      );
      if (proceed != true) return null;
    }
    if (!mounted) return null;
    final repo = _attachments;
    if (repo == null) return null;
    try {
      // Başka bir Not kullanıcısının gönderdiği "balonlu PDF" ise damga
      // katmanı sökülür ve balonlar/çizimler DÜZENLENEBİLİR olarak geri
      // yüklenir (bkz. PdfEdit.readSharedPdf). Sıradan PDF'te null döner.
      // Okuma da göstergenin İÇİNDE: web'de izole yok, büyük PDF'te ana iş
      // parçacığında sürer (F10.1).
      Map<String, dynamic>? restored;
      final attachment = await _runBusy(
        context.l10n.attachmentUploading,
        () async {
          restored = await PdfEdit.readSharedPdfInBackground(bytes);
          return repo.preparePdf(
            noteId: widget.noteId,
            bytes: restored == null ? bytes : restored!['bytes'] as Uint8List,
            fileName: _documentFileName(file.name, '.pdf'),
          );
        },
      );
      final shared = restored;
      final stored = shared == null
          ? attachment
          : attachment.copyWith(
              bubbles: [
                for (final e in (shared['b'] as List?) ?? const [])
                  PageBubble.fromMap(Map<String, dynamic>.from(e as Map)),
              ],
              ink: [
                for (final e in (shared['i'] as List?) ?? const [])
                  InkStroke.fromMap(Map<String, dynamic>.from(e as Map)),
              ],
            );
      Attachment? added;
      _mutate((n) {
        added = asFile ? stored : _placePdf(stored, n);
        return n.copyWith(attachments: [...n.attachments, added!]);
      }, immediate: true);
      return added;
    } on FileTooLargeException catch (e) {
      if (mounted) _showSnack(_tooLargeMessage(e));
    } catch (e) {
      if (mounted) _showSnack(context.l10n.attachmentFailed(friendlyError(context.l10n, e)));
    }
    return null;
  }

  /// Balonlu (belge) notta duran belgenin dosya adı: **notun başlığı**;
  /// başlık boşsa dosyanın KENDİ adı + "notlar" (bkz. [documentBaseName]).
  ///
  /// Klasik metin notunda ek sıradan bir dosyadır ve adı DEĞİŞTİRİLMEZ —
  /// kullanıcı oraya bilinen adıyla bir dosya koydu, yeniden adlandırmak
  /// onu kaybettirirdi.
  String _documentFileName(String originalName, String extension) {
    final note = _note;
    if (note == null ||
        (note.type != NoteType.pdf && note.type != NoteType.slides)) {
      return originalName;
    }
    final base = documentBaseName(
      noteTitle: note.displayTitle,
      originalName: originalName,
      notesSuffix: context.l10n.docNameNotesSuffix,
    );
    return '$base$extension';
  }

  Future<void> _pickSlide() async {
    const group = XTypeGroup(
      label: 'Sunum',
      extensions: ['pptx'],
      // Android dosya seçici uzantı yerine MIME'a bakar; yalnız `extensions`
      // verilirse PowerPoint dosyaları soluk (seçilemez) görünür.
      mimeTypes: [
        'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      ],
    );
    final file = await DocPicker.pickOne(
      group,
      chooserTitle: context.l10n.pickSlidesTitle,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    // Sunum sıkıştırılamaz; PDF gibi büyük dosya doğrudan Storage kotasına
    // gider. Engellemek yerine boyutu söyleyip kullanıcıya soruyoruz.
    if (bytes.length > AppConstants.largeAttachmentWarnBytes && mounted) {
      final mb = (bytes.length / (1024 * 1024)).toStringAsFixed(1);
      final proceed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(context.l10n.largeAttachmentTitle),
          content: Text(context.l10n.largeAttachmentBody(mb)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(context.l10n.ok),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }
    if (!mounted) return;
    final repo = _attachments;
    if (repo == null) return;
    try {
      final attachment = await _runBusy(
        context.l10n.attachmentUploading,
        () => repo.prepareSlide(
          noteId: widget.noteId,
          bytes: bytes,
          fileName: _documentFileName(file.name, '.pptx'),
        ),
      );
      _mutate(
        (n) => n.copyWith(attachments: [...n.attachments, attachment]),
        immediate: true,
      );
    } on FileTooLargeException catch (e) {
      if (mounted) _showSnack(_tooLargeMessage(e));
    } catch (e) {
      if (mounted) _showSnack(context.l10n.attachmentFailed(friendlyError(context.l10n, e)));
    }
  }

  /// **SESLİ NOT NOTUN İÇİNDE** (2026-10-28): kayıt örten levhada değil,
  /// alt şeritteki hapta sürer ([VoiceRecordPanel]) — kullanıcı kayıt
  /// sürerken yazmaya devam eder. Bitince ses YAZILAN SATIRA dalgasıyla
  /// birlikte hap olarak girer ([_placeNewImage]).
  Future<void> _recordAudio() async {
    if (_voiceRecorder != null) return;
    // Tek mikrofon: dikte açıksa önce kapanır (son açan alır — bkz. HAFIZA).
    if (_dictating) await _stopDictation();
    if (!mounted) return;
    final recorder = VoiceNoteRecorder()
      ..onLimit = () => unawaited(_finishVoiceRecording());
    _update(() => _voiceRecorder = recorder);
    final error = await recorder.start(context);
    if (error == null) return;
    if (identical(_voiceRecorder, recorder)) {
      _update(() => _voiceRecorder = null);
    }
    recorder.dispose();
    _showSnack(error);
  }

  /// Kaydı bitirir ([keep] false ise atar) ve sesi nota ekler.
  Future<void> _finishVoiceRecording({bool keep = true}) async {
    final recorder = _voiceRecorder;
    if (recorder == null) return;
    if (!keep) {
      await recorder.cancel();
      if (mounted) _update(() => _voiceRecorder = null);
      recorder.dispose();
      return;
    }
    final result = await recorder.stop();
    if (mounted) _update(() => _voiceRecorder = null);
    recorder.dispose();
    if (result == null || !mounted) return;
    // Yanlışlıkla açılıp hemen kapanan kayıt (yarım saniyeden kısa) nota
    // boş bir hap bırakmasın.
    if (result.duration < const Duration(milliseconds: 600)) {
      File(result.path).delete().ignore();
      return;
    }
    final repo = _attachments;
    if (repo == null) return;
    try {
      final attachment = await repo.prepareAudio(
        noteId: widget.noteId,
        sourcePath: result.path,
        duration: result.duration,
      );
      if (!mounted) return;
      final recorded = attachment.copyWith(
        wave: result.wave,
        width: kAudioBoxWidth,
        height: kAudioBoxHeight,
      );
      _mutate(
        (n) => n.copyWith(
          attachments: [
            ...n.attachments,
            // Belge notunun sayfa tuvali yok: orada ses ek şeridinde durur.
            if (n.type.isPageNoteType)
              recorded
            else
              _placeNewImage(recorded.copyWith(onPage: true), n),
          ],
        ),
        immediate: true,
      );
    } on FileTooLargeException catch (e) {
      if (mounted) _showSnack(_tooLargeMessage(e));
    } catch (e) {
      if (mounted) _showSnack(context.l10n.attachmentFailed(friendlyError(context.l10n, e)));
    }
  }

  void _removeAttachment(Attachment attachment) {
    // Eke gömülü yazılar da çözülür (kullanıcı bulgusu 2026-10-30: "gömülü
    // ek altan silinse dahi gömülü kelimede hâlâ ek varmış gibi görüntü
    // kalıyor"): ataç ve bağ gider, yazı kalır. Geri al hepsini getirir
    // (notun tamamı saklanır).
    final note = _note;
    final labels = <String>{
      if (note != null) ...[
        for (final l in note.tagLinks)
          if (l.attachmentId == attachment.id && l.label.isNotEmpty) l.label,
        if (!note.attachments.any(
          (a) => a.id != attachment.id && a.fileName == attachment.fileName,
        ))
          attachment.fileName,
      ],
    };
    String untag(String text) {
      var out = text;
      for (final label in labels) {
        out = removeAttachmentTags(out, label);
      }
      return out;
    }

    final body = untag(_bodyController.logicalText);
    if (body != _bodyController.logicalText) {
      _bodyController.setLogical(body, body.length);
    }
    _mutate(
      (n) => n.copyWith(
        body: body,
        items: [
          for (final i in n.items)
            untag(i.text) == i.text ? i : i.copyWith(text: untag(i.text)),
        ],
        tagLinks: [
          for (final l in n.tagLinks)
            if (l.attachmentId != attachment.id) l,
        ],
        attachments: [
          for (final a in n.attachments)
            if (a.id != attachment.id) a,
        ],
      ),
      immediate: true,
    );
    _pendingAttachmentDeletes.add(attachment);
  }

  /// Editör kapanırken: nota geri dönmemiş eklerin baytlarını siler.
  void _flushAttachmentDeletes() {
    final note = _note;
    for (final attachment in _pendingAttachmentDeletes) {
      final restored =
          note != null && note.attachments.any((a) => a.id == attachment.id);
      if (restored) continue;
      _attachmentRepo?.deleteFromStorage(attachment).ignore();
      if (attachment.localPath.isNotEmpty) {
        File(attachment.localPath).delete().ignore();
        forgetLocalFile(attachment.localPath);
      }
    }
    _pendingAttachmentDeletes.clear();
  }

  /// Eki kopyalar: uygulama içi ek panosuna alır ve mümkünse sistem panosuna
  /// da yazar (görsel baytları Android/iOS/web'de, dosya yolu masaüstünde).
  ///
  /// Uygulama içi pano şart: sistem panosunun PDF/sunum/ses için karşılığı yok
  /// ve görselde bile ekin çizimi ile boyutu taşınmaz (bkz.
  /// attachment_clipboard.dart).
  Future<void> _copyAttachment(Attachment attachment) =>
      _copyAttachments([attachment]);

  /// Bir ya da daha çok eki panoya alır (kullanıcı isteği 2026-08-09:
  /// "görsellerde çoklu seçim ve kopyalama").
  ///
  /// Uygulama içi pano hepsini taşır; SİSTEM panosu ise tek görsel taşıyabilir
  /// (masaüstünde dosya listesi mümkün). Çoklu seçimde bu yüzden sisteme
  /// yalnız ilk görsel yazılır — uygulama içi yapıştırma hepsini getirir.
  Future<void> _copyAttachments(List<Attachment> attachments) async {
    if (attachments.isEmpty) return;
    final l10n = context.l10n;
    ref.read(attachmentClipboardProvider.notifier).copyAll(attachments);
    // YouTube ekinin dosyası yok: sistem panosuna BAĞLANTISI yazılır
    // (kullanıcı bulgusu 2026-10-11: "videoların bağlantı adresi
    // kopyalanmıyor" — eskiden yalnız uygulama içi panoya giriyordu,
    // başka uygulamaya yapıştırılacak bir şey yoktu).
    final links = [
      for (final a in attachments)
        if (a.isWebVideo) a.webUrl,
    ];
    if (links.isNotEmpty && links.length == attachments.length) {
      await Clipboard.setData(ClipboardData(text: links.join('\n')));
      if (mounted) _showSnack(l10n.videoLinkCopied);
      return;
    }
    final repo = _attachments;
    final attachment = attachments.first;
    try {
      // Baytları okumak (bulut kopyasında: indirmek) uzun sürebilir; şeritte
      // canlı gösterge dursun (bkz. [_busyTaskN]).
      await _runBusy(l10n.attachmentCopying, () async {
        if (attachment.kind == AttachmentKind.image) {
          final bytes = await repo?.readBytes(attachment);
          if (bytes != null) await Pasteboard.writeImage(bytes);
        }
      });
    } catch (_) {
      // Sistem panosuna yazmak her platformda mümkün değil (ör. masaüstünde
      // görsel yazımı yok). Uygulama içi kopya yine de alındı; kullanıcıya
      // hata göstermek yanıltıcı olurdu.
    }
    if (mounted) _showSnack(l10n.attachmentCopied);
  }

  /// Panodaki eki bu nota kopyalar (baytlar yeniden yazılır, yeni kimlik alır).
  /// Ayrı çizim ekranı → PNG → sayfaya yerleşen görsel eki.
  Future<void> _addDrawing() async {
    final bytes = await Navigator.of(
      context,
    ).push<Uint8List>(MaterialPageRoute(builder: (_) => const DrawingScreen()));
    if (bytes == null || !mounted) return;
    await _addImageBytes(bytes, 'cizim.png');
  }

  Future<void> _pasteAttachment() async {
    final sources = ref.read(attachmentClipboardProvider);
    final repo = _attachments;
    if (sources.isEmpty || repo == null) return;
    try {
      // Baytların yeniden yazılması saniyeler sürebilir: gösterge şeritte
      // dursun, kullanıcı düğmenin çalıştığını görsün (bkz. [_busyTaskN]).
      await _runBusy(context.l10n.attachmentUploading, () async {
        // SIRAYLA: her kopya sayfadaki yerini bir öncekine göre hesaplıyor
        // (bkz. [_placeNewImage]); aynı anda koşsalardı üst üste binerlerdi.
        for (final source in sources) {
          final copy = await repo.duplicate(
            noteId: widget.noteId,
            source: source,
          );
          if (!mounted) return;
          _mutate(
            (n) => n.copyWith(
              attachments: [
                ...n.attachments,
                if (copy.floatsOnPage) _placeNewImage(copy, n) else copy,
              ],
            ),
            immediate: true,
          );
        }
      });
    } on FileTooLargeException catch (e) {
      if (mounted) _showSnack(_tooLargeMessage(e));
    } on AttachmentMissingException {
      if (mounted) _showSnack(context.l10n.attachmentNotSynced);
    } catch (e) {
      if (mounted) _showSnack(context.l10n.attachmentFailed(friendlyError(context.l10n, e)));
    }
  }

  /// Yeni eklenen PDF'in yeri: klasik metin notunda SAYFAYA yerleşir (görsel
  /// gibi — kullanıcı isteği 2026-09-06), belge notunda ise notun kendi
  /// belgesidir ve şeritte/bölmede kalır.
  Attachment _placePdf(Attachment pdf, Note note) {
    if (note.type.isPageNoteType) return pdf;
    return _placeNewImage(pdf.copyWith(onPage: true), note);
  }

  /// Bir eki (görsel) yeni değerleriyle (genişlik/hiza) değiştirir — kullanıcı
  /// görseli notta elle boyutlandırıp hizalayınca çağrılır.
  /// Birden çok eki TEK yazımda günceller (tuvalde "satıra sığdır" ve
  /// "boyutları eşitle"): altı görseli tek tek yazmak altı kayıt ve altı
  /// geri-al adımı üretiyordu.
  void _updateAttachments(List<Attachment> updated) {
    if (updated.isEmpty) return;
    final byId = {for (final a in updated) a.id: a};
    _mutate(
      (n) => n.copyWith(
        attachments: [for (final a in n.attachments) byId[a.id] ?? a],
      ),
      immediate: true,
    );
  }

  void _updateAttachment(Attachment updated) {
    _mutate(
      (n) => n.copyWith(
        attachments: [
          for (final a in n.attachments)
            if (a.id == updated.id) updated else a,
        ],
      ),
      immediate: true,
    );
  }

  /// Görseli KALICI olarak kırpar (tam ekrandaki kırpma ekranından gelir).
  /// [frac] görsel oranında (0–1) seçilen alan.
  Future<void> _cropImage(Attachment image, Rect frac) async {
    final repo = _attachments;
    if (repo == null) return;
    try {
      final cropped = await repo.cropImage(
        noteId: widget.noteId,
        attachment: image,
        left: frac.left,
        top: frac.top,
        right: frac.right,
        bottom: frac.bottom,
      );
      // Dosya AYNI yola yeniden yazıldı; Flutter'ın görsel önbelleği yolu
      // anahtar olarak kullandığından temizlenmezse eski (kırpılmamış) hâl
      // gösterilmeye devam ederdi. Tek tek atmak yetmiyor: not tuvali
      // `cacheWidth` ile sardığından anahtar `ResizeImage`, `FileImage` değil.
      // ponytail: kırpma seyrek bir işlem, önbelleği tümden atmak yeterince
      // ucuz — anahtar eşlemesini elle kurmak buna değmez.
      PaintingBinding.instance.imageCache
        ..clear()
        ..clearLiveImages();
      _updateAttachment(cropped);
    } on FileTooLargeException catch (e) {
      if (mounted) _showSnack(_tooLargeMessage(e));
    } on AttachmentMissingException {
      if (mounted) _showSnack(context.l10n.cropFailed);
    } catch (e) {
      if (mounted) _showSnack(context.l10n.attachmentFailed(friendlyError(context.l10n, e)));
    }
  }

  /// Görseli KALICI olarak 90°'nin katıyla döndürür (tam ekrandaki döndür
  /// düğmesinden gelir). [quarterTurns] pozitif = saat yönü.
  ///
  /// Kırpmayla ([_cropImage]) aynı gerekçeler: aynı yola yeniden yazılan
  /// dosya için görsel önbelleği temizlenir, yoksa eski (dönmemiş) hâl
  /// gösterilmeye devam eder.
  /// Döndürülen eki geri döndürür ki tam ekran görüntüleyici KAPANMADAN
  /// kendini tazeleyebilsin (kullanıcı bulgusu 2026-08-16: "her döndürme
  /// işleminden sonra düzenleme ekranı kapanıyor"). Hata durumunda null.
  Future<Attachment?> _rotateImage(Attachment image, int quarterTurns) async {
    final repo = _attachments;
    if (repo == null) return null;
    try {
      final turned = await repo.rotateImage(
        noteId: widget.noteId,
        attachment: image,
        quarterTurns: quarterTurns,
      );
      PaintingBinding.instance.imageCache
        ..clear()
        ..clearLiveImages();
      _updateAttachment(turned);
      return turned;
    } on FileTooLargeException catch (e) {
      if (mounted) _showSnack(_tooLargeMessage(e));
    } on AttachmentMissingException {
      if (mounted) _showSnack(context.l10n.rotateFailed);
    } catch (e) {
      if (mounted) _showSnack(context.l10n.attachmentFailed(friendlyError(context.l10n, e)));
    }
    return null;
  }

  /// "Ekle" levhası: TEK sayfa, iki sütunlu ızgara (bkz. attach_sheet.dart).
  /// Eski iki katmanlı yapı (küçük açılır menü + ayrı "tüm ekler" levhası)
  /// kaldırıldı; her seçenek tek dokunuşla görünür.
  Future<void> _showAttachMenu() async {
    // İmleç ölçümü klavye kapatılmadan ÖNCE alınır: eklenecek görsel yazılan
    // satıra gitsin (odak düşünce ölçüm imkânsız).
    _rememberCaret();
    // SEÇİM DE anlık görüntüye alınır: levha açılırken klavye kapatılıyor ve
    // odak düşünce seçim daralabiliyor ("Yazıya ek göm" seçili yazıyı
    // kullanır — bkz. [_embedAttachmentFlow]).
    _selectionSnapshot = _bodyController.selection;
    _dismissKeyboard();
    final copied = ref.read(attachmentClipboardProvider);
    final action = await showAttachSheet(
      context,
      pageNote: _note?.type.isPageNoteType ?? false,
      // Gömme seçicisi yeni ek de ekleyebildiği için eki olmayan notta da
      // anlamlı (gömme yeniden tasarımı, 2026-10-11).
      canEmbed: !(_note?.type.isPageNoteType ?? false),
      // Birden çok ek kopyalandıysa ad yerine sayı yazılır.
      copiedAttachmentName: copied.isEmpty
          ? null
          : copied.length == 1
          ? copied.first.fileName
          : context.l10n.attachmentsCopiedCount(copied.length),
    );
    if (!mounted) return;
    switch (action) {
      // Karışık içerik: her not tipinde HEM serbest metin HEM madde listesi
      // eklenebilir (bkz. attach_sheet.dart — eskiden tipe göre yalnız biri
      // gösteriliyordu ve kullanıcı "liste ekle seçeneği yok" diyordu).
      case 'embed-attachment':
        await _embedAttachmentFlow();
      case 'new-page':
        _addPage();
      case 'list-item':
        _addChecklistItem();
      case 'text-block':
        // Metin notunda gövde ZATEN görünür; yalnız odaklanmak yeter.
        // Liste notunda gövde alanı gizliyse önce açılır.
        if (!_listBodyOpen) _update(() => _listBodyOpen = true);
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _bodyFocus.requestFocus(),
        );
      case 'image':
        await _pickImage();
      case 'paste-attachment':
        await _pasteAttachment();
      case 'camera':
        await _takePhoto();
      case 'scan':
        await _scanDocument();
      case 'qr':
        await _scanQr();
      // PDF, sunum, ses dosyası, galeriden video, görseli ek olarak ve
      // dosyayı metne dök TEK girişte (2026-10-20, bkz. attach_sheet.dart).
      case 'any-file':
        await _attachAnyFile();
      // Çizim: ayrı tuvalde çizilip GÖRSEL olarak gömülür (kullanıcı isteği
      // 2026-11-02 — kalem kipi varken de). Sayfaya el yazısı ayrı seçenek.
      case 'drawing':
        await _addDrawing();
      case 'handwriting':
        _openPen();
      case 'audio':
        await _recordAudio();
      case 'video':
        await _addVideo();
      case 'youtube':
        await _addYouTube();
      // 'color' BURADAN KALKTI: sayfa görünümünün TEK kapısı üst çubuktaki
      // palet (F12.6, kullanıcı kararı 2026-10-31; bkz. [_showColorSheet]).
    }
  }

  /// Resmin araç çubuğundaki "Metni al" düğmesi: görseldeki metni çıkarır
  /// (OCR) ve nota ekler (madde 3). AI sayfasına girmeden doğrudan resimden
  /// erişilir; sonuç [_appendText] ile gövdeye/öğelere eklenir.
  /// **Metni tanı** — görseldeki yazıyı ortak tanıma ekranında açar.
  ///
  /// KÖK NEDEN (kullanıcı bulgusu 2026-08-09: "not içi metni tanı dendiğinde
  /// direkt tüm metni nota kopyalıyor, böyle olmaz — yine metni tanı ekranı
  /// gelmeli"): bu yol modele gidip dönen metni SORMADAN notun gövdesine
  /// ekliyordu. Kullanıcı yalnız bir telefon numarası isterken notun altına
  /// sayfanın tamamı düşüyor, üstelik her seferinde AI puanı yanıyordu.
  /// Artık [TextRecognizeScreen] açılır: metin cihazda tanınır, kullanıcı
  /// harf harf seçer ve kopyalar ya da "Nota ekle" der.
  ///
  /// ML Kit'in olmadığı yerde (masaüstü) eski model yolu KORUNUR — özellik
  /// büsbütün kaybolmasın.
  Future<void> _ocrImage(Attachment image) async {
    final repo = _attachments;
    if (repo == null) return;
    final l10n = context.l10n;
    if (ScanOcr.supported) {
      final path = await recognizableImagePath(image, repo);
      if (!mounted) return;
      if (path == null) {
        _showSnack(l10n.attachmentNotSynced);
        return;
      }
      final inserted = await Navigator.of(context).push<String>(
        MaterialPageRoute<String>(
          builder: (_) => TextRecognizeScreen(
            imagePath: path,
            imageWidth: image.width ?? 0,
            imageHeight: image.height ?? 0,
            title: image.fileName,
            canInsert: true,
          ),
        ),
      );
      if (!mounted || inserted == null || inserted.trim().isEmpty) return;
      _appendText(inserted.trim());
      return;
    }
    final bytes = await repo.readBytes(image);
    if (!mounted) return;
    if (bytes == null) {
      _showSnack(l10n.attachmentNotSynced);
      return;
    }
    await _runAi(l10n.aiThinking, () async {
      final service = ref.read(geminiServiceProvider);
      final text = stripMarkdown(
        await service.extractTextFromImage(bytes, image.mimeType),
      ).trim();
      if (!mounted || text.isEmpty) return;
      _appendText(text);
    });
  }

  // ---- Arayüz ---------------------------------------------------------

}

