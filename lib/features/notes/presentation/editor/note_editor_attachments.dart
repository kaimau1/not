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
      AttachmentKind.text ||
      AttachmentKind.audio ||
      AttachmentKind.slide => 0.8,
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
      if (mounted) _showSnack(context.l10n.attachmentFailed('$e'));
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
        final use = await _askFileUse(kind);
        if (use == null || !mounted) return;
        for (final f in same) {
          if (!mounted) return;
          await _addImageBytes(
            await f.readAsBytes(),
            nameOf(f).split(RegExp(r'[\\/]')).last,
            asFile: use == _FileUse.attach,
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
        final use = await _askFileUse(kind);
        if (use == null || !mounted) return;
        await handOff(
          [same.first],
          use == _FileUse.transcribe
              ? _transcribeFile
              : kind == PickedFileKind.video
              ? _addVideoFromGallery
              : _pickAudioFile,
        );
    }
  }

  /// "Dosya ekle"de seçilen dosyayla ne yapılacağı (görsel: sayfaya / ek
  /// olarak; ses-video: ek olarak / metne dök). İptalde null.
  Future<_FileUse?> _askFileUse(PickedFileKind kind) {
    final l10n = context.l10n;
    final image = kind == PickedFileKind.image;
    final options = <(_FileUse, IconData, String, String)>[
      if (image) ...[
        (
          _FileUse.page,
          Icons.image_outlined,
          l10n.addImage,
          l10n.addImageOnPageSubtitle,
        ),
        (
          _FileUse.attach,
          Icons.attachment_outlined,
          l10n.addImageAsFile,
          l10n.addImageAsFileSubtitle,
        ),
      ] else ...[
        (
          _FileUse.attach,
          kind == PickedFileKind.video
              ? Icons.video_library_outlined
              : Icons.library_music_outlined,
          kind == PickedFileKind.video
              ? l10n.addVideoFromGallery
              : l10n.addAudioFile,
          l10n.fileUseAttachInfo,
        ),
        (
          _FileUse.transcribe,
          Icons.subtitles_outlined,
          l10n.transcribeFile,
          l10n.transcribeFileSubtitle,
        ),
      ],
    ];
    return showAppSheet<_FileUse>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (use, icon, title, info) in options)
              ListTile(
                leading: Icon(icon),
                title: Text(title),
                subtitle: Text(info),
                onTap: () => Navigator.pop(sheetContext, use),
              ),
          ],
        ),
      ),
    );
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
      if (mounted) _showSnack(l10n.attachmentFailed('$e'));
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
        if (mounted) _showSnack(l10n.scanFailed('$e'));
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
        if (mounted) _showSnack(l10n.attachmentFailed('$e'));
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
      displayText: _bodyController.text,
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

  /// Metne gömülü ek etiketini AÇAR.
  ///
  /// [editing] false ise ÖNİZLEME: görsel/belge salt okunur açılır (çizim,
  /// kırpma, döndürme düğmeleri çizilmez). true ise DÜZENLEME: aynı ekranlar
  /// düzenleme geri çağrılarıyla açılır. Kullanıcının istediği ayrım tam
  /// olarak bu — "tıklayınca önizlemesi açılır, bir butonla da düzenleme".
  void _openAttachmentTag(Attachment attachment, {required bool editing}) {
    if (attachment.isUnsupported) {
      showUnsupportedAttachmentDialog(context);
      return;
    }
    // Metin eki (transkript) dosyasız: okuma ekranında açılır.
    if (attachment.kind == AttachmentKind.text) {
      unawaited(_openTranscript(attachment));
      return;
    }
    // Drive'daki ek bu cihaza henüz inmediyse ŞİMDİ indirilir, sonra açılır
    // (bkz. drive_ui.dart — arka plan kuyruğunu beklemesin).
    if (!localFileExists(attachment.localPath) &&
        attachment.isInDrive &&
        !attachment.isUploaded) {
      if (kIsWeb) {
        // Web: Drive'dan belleğe (F4.4) — `blob:` adresiyle yeniden açılır.
        resolveWebDriveAttachment(context, ref, attachment).then((resolved) {
          if (resolved != null && mounted) {
            _openAttachmentTag(resolved, editing: editing);
          }
        });
        return;
      }
      fetchAttachmentNow(context, ref, attachment).then((ok) {
        if (ok && mounted) _openAttachmentTag(attachment, editing: editing);
      });
      return;
    }
    if (!localFileExists(attachment.localPath) &&
        !attachment.isUploaded &&
        !attachment.isWebVideo) {
      _showSnack(context.l10n.attachmentNotSynced);
      return;
    }
    if (attachment.kind == AttachmentKind.image) {
      openImageViewer(
        context,
        attachment,
        editing ? _updateAttachment : (_) {},
        onCrop: editing ? _cropImage : null,
        onRotate: editing ? _rotateImage : null,
        // Nottaki BÜTÜN görseller (sayfadakiler + şerittekiler) galeri olur:
        // tam ekranda yana kaydırarak hepsinde gezilir.
        gallery: [
          for (final a in (_note?.attachments ?? const <Attachment>[]))
            if (a.kind == AttachmentKind.image) a,
        ],
      );
      return;
    }
    Navigator.of(context).push(
      MediaRoute<void>(
        builder: (_) => switch (attachment.kind) {
          AttachmentKind.pdf => PdfViewerScreen(
            attachment: attachment,
            onChanged: editing ? _updateAttachment : null,
          ),
          AttachmentKind.slide => SlideViewerScreen(
            attachment: attachment,
            onChanged: editing ? _updateAttachment : null,
          ),
          AttachmentKind.video => VideoViewerScreen(attachment: attachment),
          // Ses ekinin görüntüleyicisi yok; şeritteki oynatıcıdan çalınır.
          // Metin eki yukarıda kendi ekranına gider; dal yalnız bütünlük için.
          AttachmentKind.audio ||
          AttachmentKind.text ||
          AttachmentKind.unknown => ImageViewerScreen(attachment: attachment),
          AttachmentKind.image => ImageViewerScreen(attachment: attachment),
        },
      ),
    );
  }

  /// Ada göre eki bulup ÖNİZLEMEDE açar (madde satırından gelen dokunuş).
  /// Ad hem bağ etiketi hem dosya adı olabilir — çözüm [_NoteEditorScreenState._attachmentForTag]'te.
  void _openTagByName(String name) {
    final note = _note;
    if (note == null) return;
    final attachment = _NoteEditorScreenState._attachmentForTag(note, name);
    if (attachment != null) _showEmbedPreviewFor(attachment, name);
  }

  /// "+ Ekle" levhasından gelen gömme akışı.
  ///
  /// Seçim VARSA seçici o yazı için açılır ve sonuç doğrudan ona gömülür.
  /// Seçim yoksa önce NE gömüleceği seçilir, sonra bağlama kipine geçilir
  /// (kullanıcı yazıyı sonra seçer — istenen "ters" yön).
  Future<void> _embedAttachmentFlow() async {
    final note = _note;
    if (note == null) return;
    // Levha açılırken alınan anlık görüntü: klavye kapanınca seçim daralmış
    // olabilir (bkz. [_showAttachMenu]).
    final snapshot = _selectionSnapshot;
    final logical = _bodyController.logicalText;
    if (snapshot != null && snapshot.isValid && !snapshot.isCollapsed) {
      final start = wrapToLogicalOffset(
        _bodyController.text,
        snapshot.start,
      ).clamp(0, logical.length);
      final end = wrapToLogicalOffset(
        _bodyController.text,
        snapshot.end,
      ).clamp(start, logical.length);
      final range = trimmedRange(logical, start, end);
      if (range != null) {
        await _embedRange(range.start, range.end);
        return;
      }
    }
    final chosen = await _pickEmbedTarget(label: '');
    if (chosen == null || !mounted) return;
    _startPendingEmbed(chosen);
  }

  /// Gömme seçicisi + gerekiyorsa YENİ eki oluşturma. Yeni ek şeride girer
  /// (gömülü dosya sayfayı kalabalıklaştırmasın); seçilen/oluşan eki döner.
  Future<Attachment?> _pickEmbedTarget({required String label}) async {
    final note = _note;
    if (note == null) return null;
    final pick = await showEmbedPicker(
      context,
      label: label,
      attachments: note.attachments,
    );
    if (pick == null || !mounted) return null;
    if (pick.attachment != null) return pick.attachment;
    switch (pick.create) {
      case 'pdf':
        const group = XTypeGroup(
          label: 'PDF',
          extensions: ['pdf'],
          mimeTypes: ['application/pdf'],
        );
        final files = await DocPicker.pickMany(
          group,
          chooserTitle: context.l10n.pickPdfTitle,
        );
        if (files.isEmpty || !mounted) return null;
        return _addPdfFile(files.first, asFile: true);
      case 'image':
        final file = await ImagePicker().pickImage(
          source: ImageSource.gallery,
          maxWidth: 2400,
          maxHeight: 2400,
        );
        if (file == null || !mounted) return null;
        return _addImageBytes(
          await file.readAsBytes(),
          file.name,
          asFile: true,
        );
      case 'video':
        return _addVideoFromGallery(asFile: true);
      case 'youtube':
        return _addYouTube(asFile: true);
    }
    return null;
  }

  /// Gövdedeki [start]–[end] aralığına (mantıksal metin) gömer: önce seçici.
  Future<void> _embedRange(int start, int end) async {
    final logical = _bodyController.logicalText;
    final range = trimmedRange(logical, start, end);
    if (range == null) return;
    final label = logical.substring(range.start, range.end);
    final chosen = await _pickEmbedTarget(label: label);
    if (chosen == null || !mounted) return;
    // Seçici açıkken metin değişmiş olabilir (dikte, eşitleme): aralık hâlâ
    // AYNI yazıyı gösteriyorsa gömülür, yoksa imlece dosya adıyla.
    final now = _bodyController.logicalText;
    if (range.end <= now.length &&
        now.substring(range.start, range.end) == label) {
      _applyEmbed(
        label: label,
        attachment: chosen,
        start: range.start,
        end: range.end,
      );
    } else {
      _insertTagAtCaret(chosen);
    }
  }

  /// Gömülü yazıya dokununca: YERİNDE önizleme kartı (tam ekrana atlamaz).
  void _showEmbedPreviewFor(Attachment attachment, String label) {
    _dismissKeyboard();
    final editable =
        attachment.kind == AttachmentKind.pdf ||
        attachment.kind == AttachmentKind.image;
    showEmbedPreview(
      context,
      attachment: attachment,
      label: label,
      onOpen: () => _openAttachmentTag(attachment, editing: false),
      onEdit: editable
          ? () => _openAttachmentTag(attachment, editing: true)
          : null,
      onChanged: _updateAttachment,
      onReplace: () => unawaited(_replaceEmbed(label)),
      onUnlink: () => _unlinkEmbed(label),
    );
  }

  /// Gömülü yazının bağladığı eki DEĞİŞTİRİR (yazı aynı kalır).
  Future<void> _replaceEmbed(String label) async {
    final chosen = await _pickEmbedTarget(label: label);
    if (chosen == null || !mounted) return;
    _mutate(
      (n) => n.copyWith(
        tagLinks: [
          for (final l in n.tagLinks)
            if (l.label != label) l,
          NoteTagLink(label: label, attachmentId: chosen.id),
        ],
      ),
      immediate: true,
    );
    _showSnack(context.l10n.attachmentTagInserted);
  }

  /// GÖMMEYİ KALDIRIR: yazı kalır, ataç ve bağ gider (gövde + maddeler).
  void _unlinkEmbed(String label) {
    final body = removeAttachmentTags(_bodyController.logicalText, label);
    if (body != _bodyController.logicalText) {
      _bodyController.setLogical(body, body.length);
    }
    _mutate(
      (n) => n.copyWith(
        body: body,
        items: [
          for (final i in n.items)
            i.text.contains(attachmentTagFor(label))
                ? i.copyWith(text: removeAttachmentTags(i.text, label))
                : i,
        ],
        tagLinks: [
          for (final l in n.tagLinks)
            if (l.label != label) l,
        ],
      ),
      immediate: true,
    );
    _showSnack(context.l10n.embedRemoved);
  }

  /// Seçili aralığı etikete çevirir ve bağı nota yazar.
  ///
  /// [target] verilirse etiket O ALANA yazılır (madde satırı, başlık); alanın
  /// metni nota kendi `commit`'iyle geçer. Verilmezse gövdeye yazılır ve metin
  /// ile bağ TEK yazımda kaydedilir.
  void _applyEmbed({
    required String label,
    required Attachment attachment,
    required int start,
    required int end,
    FormatTarget? target,
  }) {
    final controller = target?.controller ?? _bodyController;
    final logical = controller.logicalText;
    // Aralığın iki ucundaki boşluklar etikete girmez ve YUTULMAZ (bkz.
    // [trimmedRange]); etiketin kendisi de kırpılmış hâlidir.
    final range = trimmedRange(logical, start, end);
    if (range != null) {
      start = range.start;
      end = range.end;
      label = logical.substring(start, end);
    }
    // Yazı ZATEN bir etiketse (yeniden gömme) ikinci ataç eklenmez, yalnız
    // bağ değişir.
    final alreadyTagged =
        start >= kAttachmentTagPrefix.length &&
        logical.substring(start - kAttachmentTagPrefix.length, start) ==
            kAttachmentTagPrefix;
    // Metne yalnız ATAÇ eklenir; seçilen yazı olduğu gibi kalır.
    final tagged = alreadyTagged ? label : '$kAttachmentTagPrefix$label';
    final text = logical.replaceRange(start, end, tagged);
    controller.setLogical(text, start + tagged.length);
    // Aynı etiket ikinci kez bağlanırsa eskisi değişir, çoğalmaz.
    List<NoteTagLink> links(Note note) => [
      for (final l in note.tagLinks)
        if (l.label != label) l,
      NoteTagLink(label: label, attachmentId: attachment.id),
    ];
    if (identical(controller, _bodyController)) {
      _mutate(
        (n) => n.copyWith(body: text, tagLinks: links(n)),
        immediate: true,
      );
    } else {
      // Alanın kendi kaydı önce koşar (madde metnini nota yazan tek yol o),
      // bağ ondan sonra eklenir.
      target!.commit();
      _mutate((n) => n.copyWith(tagLinks: links(n)), immediate: true);
    }
    _showSnack(context.l10n.attachmentTagInserted);
  }

  void _rememberTargetSelection() {
    final target = _formatTarget;
    if (target == null) return;
    final selection = target.controller.selection;
    if (selection.isValid && !selection.isCollapsed) {
      _lastSelection = selection;
      _lastSelectionTarget = target;
    }
  }

  /// Bağlama kipini başlatır (ek seçildi, yazı bekleniyor).
  void _startPendingEmbed(Attachment attachment) {
    _update(() => _pendingEmbed = attachment);
    _showSnack(context.l10n.attachmentTagPickText);
  }

  /// Bağlama kipini o anki SEÇİMLE bitirir.
  ///
  /// Seçim üç kaynaktan sırayla aranır ve hiçbiri tutmazsa BİLE bir sonuç
  /// üretilir (bkz. [_lastSelection] — "basıyorum hiçbir şey olmuyor" kök
  /// nedeni):
  /// 1. **Etkin alanın canlı seçimi** — şerit [TextFieldTapRegion] içinde
  ///    olduğu için dokunmak odağı düşürmez, seçim çoğu zaman burada durur.
  /// 2. **Hatırlanan son dolu seçim** — odak yine de düştüyse (donanım
  ///    klavyesi, sistem geri jesti, alanın yeniden kurulması) yedek devreye
  ///    girer; hangi alandan geldiği de saklandığı için madde satırları da
  ///    çalışır.
  /// 3. **İmleç** — seçim yoksa etiket imlecin yerine dosya adıyla yazılır.
  ///
  /// Her üç yolda da kip KAPANIR: şeritte asılı kalan bir "bağla" yazısı,
  /// kullanıcının gördüğü asıl hataydı.
  void _finishPendingEmbed() {
    final attachment = _pendingEmbed;
    if (attachment == null) return;
    var target = _formatTarget;
    var selection = target?.controller.selection;
    final liveIsUsable =
        selection != null && selection.isValid && !selection.isCollapsed;
    if (!liveIsUsable) {
      target = _lastSelectionTarget;
      selection = _lastSelection;
    }
    final controller = target?.controller;
    var label = '';
    var start = 0;
    var end = 0;
    if (controller != null &&
        selection != null &&
        selection.isValid &&
        !selection.isCollapsed) {
      final logical = controller.logicalText;
      start = wrapToLogicalOffset(
        controller.text,
        selection.start,
      ).clamp(0, logical.length);
      end = wrapToLogicalOffset(
        controller.text,
        selection.end,
      ).clamp(start, logical.length);
      label = logical.substring(start, end).trim();
    }
    _update(() => _pendingEmbed = null);
    // Bağlandı: yedek seçim tüketildi, ikinci bir "Buraya bağla" aynı yazıyı
    // yeniden bağlamasın.
    _lastSelection = null;
    _lastSelectionTarget = null;
    if (label.isEmpty) {
      _insertTagAtCaret(attachment);
      return;
    }
    _applyEmbed(
      label: label,
      attachment: attachment,
      start: start,
      end: end,
      target: target,
    );
  }

  /// Seçim bulunamadığında bağlama kipinin ÇIKIŞI: etiket gövdedeki imlecin
  /// yerine (imleç de yoksa metnin sonuna) dosya adıyla yazılır.
  ///
  /// Bu, "Metne ekle"nin ilk günkü davranışı — yani kullanıcının bildiği bir
  /// sonuç. Sessizce hiçbir şey yapmamaktan her koşulda iyidir.
  void _insertTagAtCaret(Attachment attachment) {
    final logical = _bodyController.logicalText;
    final live = _bodyController.selection;
    final caret = live.isValid
        ? wrapToLogicalOffset(
            _bodyController.text,
            live.baseOffset,
          ).clamp(0, logical.length)
        : logical.length;
    _applyEmbed(
      label: attachment.fileName,
      attachment: attachment,
      start: caret,
      end: caret,
    );
  }

  /// SEÇİLİ METNE bir ek gömer (kullanıcı isteği 2026-08-16: "o yazıya PDF
  /// gömülür, o yazının altı çizilir kırmızı vurgulanır, tıklayınca PDF
  /// önizlemede açılır").
  ///
  /// Seçilen kelimenin başına ataç konur ve metnin kendisi etiket olur;
  /// hangi eke gittiği nota [Note.tagLinks] olarak yazılır. Metne gizli
  /// kimlik GÖMÜLMEZ — gerekçesi orada.
  ///
  /// [target] verilirse seçim O ALANDA (madde satırı); verilmezse gövdede.
  Future<void> _embedIntoSelection(
    WrapTextController controller, {
    FormatTarget? target,
  }) async {
    final selection = controller.selection;
    if (!selection.isValid || selection.isCollapsed) return;
    final logical = controller.logicalText;
    final start = wrapToLogicalOffset(
      controller.text,
      selection.start,
    ).clamp(0, logical.length);
    final end = wrapToLogicalOffset(
      controller.text,
      selection.end,
    ).clamp(start, logical.length);
    if (target == null) {
      await _embedRange(start, end);
      return;
    }
    final range = trimmedRange(logical, start, end);
    if (range == null) return;
    final label = logical.substring(range.start, range.end);
    final chosen = await _pickEmbedTarget(label: label);
    if (chosen == null || !mounted) return;
    // Seçici açıkken satırın metni değiştiyse (silindi, eşitlendi) gömülmez.
    final now = controller.logicalText;
    if (range.end <= now.length &&
        now.substring(range.start, range.end) == label) {
      _applyEmbed(
        label: label,
        attachment: chosen,
        start: range.start,
        end: range.end,
        target: target,
      );
    }
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
      if (tagged != null) ...[
        ContextMenuButtonItem(
          label: l10n.attachmentTagEdit,
          onPressed: () => run(() => _openAttachmentTag(tagged, editing: true)),
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
      final restored = await PdfEdit.readSharedPdfInBackground(bytes);
      if (!mounted) return null;
      final attachment = await _runBusy(
        context.l10n.attachmentUploading,
        () => repo.preparePdf(
          noteId: widget.noteId,
          bytes: restored == null ? bytes : restored['bytes'] as Uint8List,
          fileName: _documentFileName(file.name, '.pdf'),
        ),
      );
      final stored = restored == null
          ? attachment
          : attachment.copyWith(
              bubbles: [
                for (final e in (restored['b'] as List?) ?? const [])
                  PageBubble.fromMap(Map<String, dynamic>.from(e as Map)),
              ],
              ink: [
                for (final e in (restored['i'] as List?) ?? const [])
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
      if (mounted) _showSnack(context.l10n.attachmentFailed('$e'));
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
      if (mounted) _showSnack(context.l10n.attachmentFailed('$e'));
    }
  }

  Future<void> _recordAudio() async {
    final result = await showAudioRecorderSheet(context);
    if (result == null) return;
    final repo = _attachments;
    if (repo == null) return;
    try {
      final attachment = await repo.prepareAudio(
        noteId: widget.noteId,
        sourcePath: result.path,
        duration: result.duration,
      );
      _mutate(
        (n) => n.copyWith(attachments: [...n.attachments, attachment]),
        immediate: true,
      );
    } on FileTooLargeException catch (e) {
      if (mounted) _showSnack(_tooLargeMessage(e));
    } catch (e) {
      if (mounted) _showSnack(context.l10n.attachmentFailed('$e'));
    }
  }

  Future<void> _addDrawing() async {
    final bytes = await Navigator.of(
      context,
    ).push<Uint8List>(MaterialPageRoute(builder: (_) => const DrawingScreen()));
    if (bytes == null) return;
    await _addImageBytes(bytes, 'cizim.png');
  }

  void _removeAttachment(Attachment attachment) {
    _mutate(
      (n) => n.copyWith(
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
      if (mounted) _showSnack(context.l10n.attachmentFailed('$e'));
    }
  }

  /// Görseli sayfa ile ek şeridi arasında taşır (madde: "resimleri ek olarak
  /// yükleme seçeneği"). Sayfaya dönerken imlecin satırına yerleşir.
  void _setImageAsFile(Attachment image, bool asFile) {
    final note = _note;
    if (note == null) return;
    // PDF'in sayfada olup olmadığını `asFile` DEĞİL `onPage` söyler: eski
    // PDF eklerinin hepsinde `asFile: false` yazılı, anlamını değiştirmek
    // onları bir anda sayfanın ortasına taşırdı (bkz. Attachment.onPage).
    final moved = image.placedOnPage(!asFile);
    _updateAttachment(asFile ? moved : _placeNewImage(moved, note));
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
      if (mounted) _showSnack(context.l10n.attachmentFailed('$e'));
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
      if (mounted) _showSnack(context.l10n.attachmentFailed('$e'));
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
      case 'drawing':
        await _addDrawing();
      case 'audio':
        await _recordAudio();
      case 'video':
        await _addVideo();
      case 'youtube':
        await _addYouTube();
      // 'color' BURADAN KALKTI: sayfa görünümü artık biçim şeridinde
      // (bkz. attach_sheet.dart'taki gerekçe ve [_showColorSheet]).
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

  Future<void> _addVideo() async {
    final repo = _attachments;
    if (repo == null) return;
    final l10n = context.l10n;
    // Manifest'te CAMERA bildirildiği için Android çekim niyetini izin
    // olmadan REDDEDER (image_picker'ın kendisi istemez). İlk açılış
    // tanıtımını atlayan kullanıcıda burada sorulur.
    final perms = ref.read(permissionsServiceProvider);
    if (!await perms.cameraGranted() && !await perms.requestCamera()) {
      if (mounted) _showSnack(l10n.permCameraInfo);
      return;
    }
    if (!mounted) return;
    try {
      final picked = await ImagePicker().pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(
          seconds: _NoteEditorScreenState._maxVideoSeconds,
        ),
      );
      if (picked == null || !mounted) return;
      final attachment = await repo.prepareVideo(
        noteId: widget.noteId,
        sourcePath: picked.path,
        duration: Duration.zero,
      );
      // Video da görsel gibi SAYFAYA yerleşir (imlecin satırına) ve olduğu
      // yerde oynatılır; "Ek olarak taşı" ile şeride alınabilir.
      _mutate(
        (n) => n.copyWith(
          attachments: [...n.attachments, _placeNewImage(attachment, n)],
        ),
        immediate: true,
      );
      if (mounted) _showSnack(l10n.videoLocalOnly);
    } catch (e) {
      if (mounted) _showSnack(l10n.attachmentFailed('$e'));
    }
  }

  Future<Attachment?> _addVideoFromGallery({bool asFile = false}) async {
    final repo = _attachments;
    if (repo == null) return null;
    final l10n = context.l10n;
    try {
      // "+ → Dosya ekle"de seçilmiş video varsa galeri sorulmaz (F3.2).
      final picked =
          DocPicker.takePreselected(_NoteEditorScreenState._videoExtensions)
              ?.first ??
          await ImagePicker().pickVideo(source: ImageSource.gallery);
      if (picked == null || !mounted) return null;
      final attachment = await repo.prepareVideo(
        noteId: widget.noteId,
        sourcePath: picked.path,
        duration: await VideoFrame.duration(picked.path),
      );
      if (!mounted) return null;
      Attachment? added;
      _mutate((n) {
        added = asFile
            ? attachment.copyWith(asFile: true)
            : _placeNewImage(attachment, n);
        return n.copyWith(attachments: [...n.attachments, added!]);
      }, immediate: true);
      _showSnack(l10n.videoLocalOnly);
      return added;
    } catch (e) {
      if (mounted) _showSnack(l10n.attachmentFailed('$e'));
    }
    return null;
  }

  /// YOUTUBE videosu: bağlantı sorulur (panoda YouTube bağlantısı varsa hazır
  /// gelir), video dosyasız bir ek olarak sayfaya yerleşir ve gömülü
  /// oynatıcıda (resim içinde resim destekli) oynar. Başlık arka planda
  /// YouTube'dan alınır; gelmezse ek "YouTube" adıyla kalır.
  Future<Attachment?> _addYouTube({bool asFile = false}) async {
    final l10n = context.l10n;
    String initial = '';
    try {
      final clip = await Clipboard.getData(Clipboard.kTextPlain);
      initial = firstYouTubeUrl(clip?.text ?? '') ?? '';
    } catch (_) {
      // Pano okunamazsa alan boş açılır.
    }
    if (!mounted) return null;
    final url = await showDialog<String>(
      context: context,
      builder: (context) => _YouTubeLinkDialog(initial: initial),
    );
    if (url == null || !mounted) return null;
    final attachment = webVideoAttachment(url);
    if (attachment == null) {
      _showSnack(l10n.youTubeInvalidLink);
      return null;
    }
    Attachment? added;
    _mutate((n) {
      // Görsel gibi imlecin satırına (16:9 kutu); büyütmek köşe
      // tutamağıyla. Genişliği burada büyütmek, konumu dar kutuya göre
      // hesaplanmış kutuyu sayfa kenarından taşırırdı.
      added = asFile
          ? attachment.copyWith(asFile: true)
          : _placeNewImage(attachment, n);
      return n.copyWith(attachments: [...n.attachments, added!]);
    }, immediate: true);
    // Başlık arka planda gelir; ek hemen kullanılabilir.
    unawaited(() async {
      final title = await fetchYouTubeTitle(attachment.webUrl);
      if (title == null || !mounted) return;
      final current = _note?.attachments.where((a) => a.id == attachment.id);
      if (current == null || current.isEmpty) return;
      _updateAttachment(current.first.copyWith(fileName: title));
    }());
    return added;
  }

  /// **TRANSKRİPT** — ekin metne dökümünü açar (kullanıcı isteği
  /// 2026-10-17). [target] bir metin ekiyse doğrudan okunur; ses/video/
  /// görselse kayıtlı transkripti açılır, yoksa döküm başlar ve bitince nota
  /// METİN EKİ olarak kaydedilir. Ekrandan seçilen parça nota eklenir.
  Future<void> _openTranscript(
    Attachment target, {
    bool autoInsert = false,
  }) async {
    final note = _note;
    if (note == null) return;
    _dismissKeyboard();
    final Attachment? source;
    final Attachment? existing;
    if (target.kind == AttachmentKind.text) {
      existing = target;
      source = note.attachments
          .where((a) => a.id == target.transcriptOf)
          .firstOrNull;
    } else {
      source = target;
      existing = Transcripts.of(note.attachments, target);
    }
    final suffix = context.l10n.transcriptFileSuffix;
    final readOnly = _readOnly;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => TranscriptScreen(
          source: source,
          transcript: existing,
          autoInsert: autoInsert,
          onSave: readOnly
              ? null
              : (text, saved) {
                  if (!mounted) return null;
                  // Ekran açıkken başka cihaz/geri al eki değiştirmiş olabilir:
                  // nottaki GÜNCEL kayıt esas alınır.
                  final current = saved == null
                      ? null
                      : _note?.attachments
                            .where((a) => a.id == saved.id)
                            .firstOrNull;
                  if (current != null) {
                    final updated = Transcripts.withText(current, text);
                    _updateAttachment(updated);
                    return updated;
                  }
                  if (source == null) return null;
                  final created = Transcripts.create(
                    source,
                    text,
                    fileSuffix: suffix,
                  );
                  _mutate(
                    (n) => n.copyWith(attachments: [...n.attachments, created]),
                    immediate: true,
                  );
                  return created;
                },
          onInsert: readOnly
              ? null
              : (text) {
                  if (mounted) _appendText(text);
                },
          onCreateNote: (text) =>
              _createNoteFromTranscript(text, source ?? target),
          onDelete: readOnly
              ? null
              : (a) {
                  if (mounted) _removeAttachment(a);
                },
        ),
      ),
    );
  }

  /// Transkriptten YENİ metin notu: başlık kaynağın adı, gövde seçilen metin,
  /// klasör bu notunki.
  Future<void> _createNoteFromTranscript(String text, Attachment media) async {
    if (!mounted) return;
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null || text.trim().isEmpty) return;
    final name = media.isWebVideo
        ? media.fileName
        : media.fileName.replaceAll(RegExp(r'\.[A-Za-z0-9]{1,5}$'), '');
    final title = context.l10n.transcriptNoteTitle(name);
    final id = await repo.createNote(
      NoteType.text,
      title: title,
      body: text.trim(),
      folderId: _note?.folderId,
    );
    if (mounted) unawaited(context.pushNote(noteRoutePath(id)));
  }

  /// **SES DOSYASI EKLE** — cihazdaki MP3/M4A/WAV... nota ses eki olur
  /// (kayıt yolundan ayrı: adı korunur, türü dosyadan okunur).
  Future<Attachment?> _pickAudioFile() async {
    final repo = _attachments;
    if (repo == null) return null;
    final l10n = context.l10n;
    final picked = await DocPicker.pickOne(
      const XTypeGroup(
        label: 'audio',
        mimeTypes: ['audio/*'],
        extensions: [
          'mp3',
          'm4a',
          'aac',
          'wav',
          'ogg',
          'opus',
          'flac',
          'amr',
          'webm',
        ],
      ),
      chooserTitle: l10n.addAudioFile,
    );
    if (picked == null || !mounted) return null;
    try {
      final attachment = await _runBusy(
        context.l10n.attachmentUploading,
        () => repo.prepareAudioFile(
          noteId: widget.noteId,
          sourcePath: picked.path,
          fileName: picked.name,
        ),
      );
      if (!mounted) return null;
      _mutate(
        (n) => n.copyWith(attachments: [...n.attachments, attachment]),
        immediate: true,
      );
      return attachment;
    } on FileTooLargeException catch (e) {
      if (mounted) _showSnack(_tooLargeMessage(e));
    } catch (e) {
      if (mounted) _showSnack(l10n.attachmentFailed('$e'));
    }
    return null;
  }

  /// **DOSYAYI METNE DÖK** — ses, video ya da görsel seçilir, nota ek olarak
  /// girer ve transkript ekranı açılır; metin bitince nota da yazılır
  /// ("onları nota dönüştürme"). Görsel sayfaya değil şeride konur: gövdeye
  /// gelen metin görselin etrafından akmasın.
  Future<void> _transcribeFile() async {
    final repo = _attachments;
    if (repo == null) return;
    final l10n = context.l10n;
    final picked = await DocPicker.pickOne(
      const XTypeGroup(
        label: 'media',
        mimeTypes: ['audio/*', 'video/*', 'image/*'],
        extensions: [
          'mp3',
          'm4a',
          'aac',
          'wav',
          'ogg',
          'opus',
          'flac',
          'amr',
          'webm',
          'mp4',
          'mov',
          'mkv',
          '3gp',
          'jpg',
          'jpeg',
          'png',
          'webp',
          'heic',
        ],
      ),
      chooserTitle: l10n.transcriptPickTitle,
    );
    if (picked == null || !mounted) return;
    final kind = _NoteEditorScreenState._mediaKindOf(
      picked.name.isEmpty ? picked.path : picked.name,
    );
    if (kind == null) {
      _showSnack(l10n.transcriptUnsupportedFile);
      return;
    }
    try {
      final Attachment attachment;
      switch (kind) {
        case AttachmentKind.audio:
          attachment = await repo.prepareAudioFile(
            noteId: widget.noteId,
            sourcePath: picked.path,
            fileName: picked.name,
          );
        case AttachmentKind.video:
          attachment = (await repo.prepareVideo(
            noteId: widget.noteId,
            sourcePath: picked.path,
            duration: await VideoFrame.duration(picked.path),
          )).copyWith(asFile: true);
        default:
          attachment = (await repo.prepareImage(
            noteId: widget.noteId,
            bytes: await picked.readAsBytes(),
            fileName: picked.name.isEmpty ? 'gorsel.jpg' : picked.name,
          )).copyWith(asFile: true);
      }
      if (!mounted) return;
      _mutate(
        (n) => n.copyWith(attachments: [...n.attachments, attachment]),
        immediate: true,
      );
      await _openTranscript(attachment, autoInsert: true);
    } on FileTooLargeException catch (e) {
      if (mounted) _showSnack(_tooLargeMessage(e));
    } catch (e) {
      if (mounted) _showSnack(l10n.attachmentFailed('$e'));
    }
  }

  /// Videodan (görüntü + ses) detaylı not çıkarır ve gövdeye ekler.
  Future<void> _videoToNote(Attachment video) async {
    final repo = _attachments;
    if (repo == null) return;
    final l10n = context.l10n;
    // Satır içi gönderim sınırı: büyük video istekte reddediliyor ve hata
    // dakikalar sonra geliyordu. Sınır ÖNCEDEN, anlaşılır biçimde söylenir.
    //
    // BOYUT OKUMADAN ÖNCE (bellek — 2026-10-17): eskiden video TAMAMEN
    // belleğe okunup sonra ölçülüyordu; 300 MB'lık bir kayıt, yalnız "çok
    // büyük" demek için 300 MB ayırıyor, düşük bellekli telefonda uygulamayı
    // öldürebiliyordu. Dosyanın boyu diskten okunur.
    const maxInlineBytes = GeminiService.maxInlineMediaBytes;
    final onDisk = localFileExists(video.localPath)
        ? await File(video.localPath).length()
        : video.sizeBytes;
    if (!mounted) return;
    if (onDisk > maxInlineBytes) {
      _showSnack(l10n.videoTooBigForAi(onDisk ~/ (1024 * 1024)));
      return;
    }
    final bytes = await repo.readBytes(video);
    if (!mounted) return;
    if (bytes == null) {
      _showSnack(l10n.attachmentNotSynced);
      return;
    }
    if (bytes.length > maxInlineBytes) {
      _showSnack(l10n.videoTooBigForAi(bytes.length ~/ (1024 * 1024)));
      return;
    }
    await _runAi(l10n.videoToNoteRunning, () async {
      final text = stripMarkdown(
        await ref
            .read(geminiServiceProvider)
            .noteFromVideo(bytes, video.mimeType),
      ).trim();
      if (!mounted || text.isEmpty) return;
      // Sonuç doğrudan nota YAZILMAZ: önce geniş inceleme sayfasında görülür,
      // istenirse biçimi (düz metin/madde/sıralı) değiştirilip nota eklenir
      // ya da yeni not olarak açılır.
      await showAiResultSheet(
        context,
        title: l10n.videoToNote,
        text: text,
        onInsert: _appendText,
        onCreateNote: _createNoteFromText,
      );
    });
  }

  // ---- Arayüz ---------------------------------------------------------

  /// PDF sayfa yöneticisi: sil / döndür / sırala.
  ///
  /// Düzenleme yeni bir PDF BAYTI üretir (bkz. `data/pdf_edit.dart`); dosya
  /// aynı ek kimliğiyle yeniden yazılır ve `Attachment.pageIds` yeni düzene
  /// göre güncellenir — sayfa notları böylece sayfalarıyla BİRLİKTE taşınır.
  Future<void> _editPdfPages(Attachment doc, int pageCount) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PdfPagesScreen(
            attachment: doc,
            pageCount: pageCount,
            onApply: (order, rotations) =>
                _applyPdfEdits(doc, pageCount, order, rotations),
            onBurnInk: () => _burnPdfInk(doc),
          ),
        ),
      );

  Future<void> _applyPdfEdits(
    Attachment doc,
    int pageCount,
    List<int> order,
    Map<int, int> rotations,
  ) => _runPdfEdit(doc, (bytes) async {
    var out = bytes;
    // ÖNCE döndürme: indeksler ESKİ düzene göre verildi, sıralama sonrası
    // uygulanırsa yanlış sayfalar döner.
    final byTurns = <int, List<int>>{};
    rotations.forEach((page, turns) {
      if (turns % 4 != 0) (byTurns[turns % 4] ??= []).add(page);
    });
    for (final entry in byTurns.entries) {
      out = await PdfEdit.rotatePagesInBackground(
        out,
        pageIndexes: entry.value,
        quarterTurns: entry.key,
      );
    }
    // SİLME ile SIRALAMA ayrı yollar: silme YERİNDE çalışır ve belgenin kendi
    // annotation'larını korur, sıralama ise sayfaları kopyaladığı için onları
    // kaybeder. Sıra değişmediyse ucuz ve kayıpsız olanı seçilir.
    final identityOrder = [for (var i = 0; i < pageCount; i++) i];
    // BOŞ SAYFA eklenmişse "yalnız silindi" kısayolu geçersizdir: yeni sayfa
    // ancak sıralama yolundan (yeniden kurma) doğar.
    final hasBlank = order.contains(PdfEdit.blankPage);
    final onlyDeleted =
        !hasBlank &&
        order.length < pageCount &&
        [for (final i in order) i].toString() ==
            [
              for (final i in identityOrder)
                if (order.contains(i)) i,
            ].toString();
    if (hasBlank || order.length != pageCount || !onlyDeleted) {
      if (onlyDeleted) {
        out = await PdfEdit.deletePagesInBackground(out, [
          for (final i in identityOrder)
            if (!order.contains(i)) i,
        ]);
      } else {
        out = await PdfEdit.reorderPagesInBackground(out, order);
      }
    }
    // Sayfa kimlikleri: önce SOMUTLAŞTIRILIR (bugüne kadar boş tutuluyordu),
    // sonra yeni düzene göre yeniden dizilir. Notların anahtarlarına
    // dokunulmaz — bu yüzden 3. sayfanın notu, o sayfa nereye giderse oraya
    // gider ve silinen sayfanın notu kayıtta kalır.
    // Boş sayfaya KENDİ kimliği verilir (uuid): kimliksiz bırakılsaydı
    // ondan sonraki sayfaların notları bir kayardı.
    final ids = reorderPageIds(
      materializePageIds(doc, pageCount),
      order,
      blankId: (_) => const Uuid().v4(),
    );
    return (bytes: out, pageIds: ids);
  });

  /// El yazısını belgenin İÇİNE gömer: paylaşılan PDF'te de görünsün.
  ///
  /// Gömme sonrası ekin `ink` alanı BOŞALTILIR — yoksa çizim hem belgede hem
  /// katmanda olur ve üst üste iki kez görünürdü.
  Future<void> _burnPdfInk(Attachment doc) => _runPdfEdit(
    doc,
    (bytes) async {
      final out = await PdfEdit.burnInkInBackground(bytes, doc.ink);
      return (bytes: out, pageIds: null);
    },
    clearInk: true,
    successMessage: true,
  );

  /// PDF düzenleme yollarının ortak gövdesi: baytları oku, işle, dosyayı
  /// yeniden yaz, eki güncelle.
  Future<void> _runPdfEdit(
    Attachment doc,
    Future<({Uint8List bytes, List<String>? pageIds})> Function(Uint8List)
    work, {
    bool clearInk = false,
    bool successMessage = false,
  }) async {
    final repo = _attachmentRepo;
    if (repo == null) return;
    try {
      final bytes = await repo.readBytes(doc);
      if (bytes == null) {
        if (mounted) _showSnack(context.l10n.attachmentNotSynced);
        return;
      }
      final result = await work(bytes);
      final stored = await repo.replaceDocumentBytes(
        noteId: widget.noteId,
        attachment: clearInk ? doc.copyWith(ink: const []) : doc,
        bytes: result.bytes,
        pageIds: result.pageIds,
      );
      if (!mounted) return;
      // Dosya AYNI yola yeniden yazıldı; pdfrx'in ve Flutter'ın önbellekleri
      // yolu anahtar olarak kullandığından temizlenmezse eski belge
      // gösterilmeye devam ederdi (kırpma yolundaki aynı gerekçe).
      PaintingBinding.instance.imageCache
        ..clear()
        ..clearLiveImages();
      _updateAttachment(stored);
      if (successMessage) _showSnack(context.l10n.pdfInkBurned);
    } on FileTooLargeException catch (e) {
      if (mounted) _showSnack(_tooLargeMessage(e));
    } catch (e) {
      if (mounted) _showSnack(context.l10n.pdfEditFailed('$e'));
    }
  }
}

/// "Dosya ekle"de seçilen dosyanın kullanımı (bkz. `_askFileUse`).
enum _FileUse { page, attach, transcribe }
