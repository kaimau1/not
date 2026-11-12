part of 'note_editor_screen.dart';

/// Video, YouTube, döküm ve PDF sayfa düzenleme (F18.23'te note_editor_attachments.dart'tan taşındı).
extension _EditorVideo on _NoteEditorScreenState {
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
      if (mounted) _showSnack(l10n.attachmentFailed(friendlyError(l10n, e)));
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
      if (mounted) _showSnack(l10n.attachmentFailed(friendlyError(l10n, e)));
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
    final added = _embedWebVideo(url, asFile: asFile);
    if (added == null) _showSnack(l10n.youTubeInvalidLink);
    return added;
  }

  /// YouTube bağlantısını dosyasız video eki olarak nota koyar (imlecin
  /// satırına; [asFile] ise ek şeridine) ve başlığını arka planda alır.
  /// Bağlantı YouTube videosu değilse null.
  Attachment? _embedWebVideo(String url, {bool asFile = false}) {
    final attachment = webVideoAttachment(url);
    if (attachment == null) return null;
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

  /// **BAĞLANTIDAN "NOTA GÖM"** (kullanıcı isteği 2026-10-29): yazıdaki
  /// YouTube bağlantısına dokunup "Nota göm" denince video notun ÜSTÜNE
  /// sabitlenir (zaman damgaları onu sarar). Aynı video notta zaten varsa
  /// ikincisi eklenmez, var olan sabitlenir.
  void _embedLinkedVideo(String url) {
    final note = _note;
    if (note == null || _readOnly || note.type.isPageNoteType) return;
    final id = youTubeVideoId(url);
    if (id == null) return;
    final media =
        note.attachments
            .where((a) => a.isWebVideo && youTubeVideoId(a.webUrl) == id)
            .firstOrNull ??
        _embedWebVideo(url);
    if (media == null || !mounted) return;
    if (media.pinHeight <= 0) _pinMediaTop(media);
  }

  /// **YAPIŞTIRILAN YOUTUBE BAĞLANTISI GÖMÜLÜR** (kullanıcı isteği
  /// 2026-10-28: "direkt YouTube linkini yazıya yapıştırarak videoyu
  /// gömme"). Gövdeye TEK SEFERDE giren parça (yapıştırma — yazarken harf
  /// harf gelir) yalnız bir YouTube adresiyse video imlecin satırına gömülür;
  /// bağlantı yazıda kalır. Aynı video notta zaten varsa ikinci kez gömülmez.
  /// Bildirimdeki "Geri al" gömmeyi kaldırır.
  void _maybeEmbedPastedVideo(String before, String after) {
    final note = _note;
    if (note == null || _readOnly || note.type.isPageNoteType) return;
    final inserted = pastedYouTubeUrl(before, after);
    if (inserted == null) return;
    final id = youTubeVideoId(inserted);
    final exists = note.attachments.any(
      (a) => a.isWebVideo && youTubeVideoId(a.webUrl) == id,
    );
    if (exists) return;
    final added = _embedWebVideo(inserted);
    if (added == null || !mounted) return;
    final l10n = context.l10n;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showMessage(
        l10n.youTubeEmbedded,
        action: SnackBarAction(
          label: l10n.undo,
          onPressed: () => _removeAttachment(added),
        ),
      );
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
    // .md eki (P54b): başlık `# başlık` (yoksa dosya adı), "transkript" değil;
    // okunur metnin başındaki aynı satır gövdede tekrar etmez.
    final markdown = isMarkdownFile(media.fileName, mime: media.mimeType);
    final title = markdown
        ? markdownTitle(media.fileName, media.text)
        : context.l10n.transcriptNoteTitle(name);
    final id = await repo.createNote(
      NoteType.text,
      title: title,
      body: (markdown ? markdownBodyWithoutTitle(text, title) : text).trim(),
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
      if (mounted) _showSnack(l10n.attachmentFailed(friendlyError(l10n, e)));
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
      if (mounted) _showSnack(l10n.attachmentFailed(friendlyError(l10n, e)));
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
      if (!mounted) return;
      // Web'de izole yok, iş ana iş parçacığında sürer: gösterge şart (F10.1).
      final result = await _runBusy(
        context.l10n.pdfEditWorking,
        () => work(bytes),
      );
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
      if (mounted) {
        _showSnack(context.l10n.pdfEditFailed(friendlyError(context.l10n, e)));
      }
    }
  }
}
