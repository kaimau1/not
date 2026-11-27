part of 'note_editor_screen.dart';

extension _EditorMediaLinks on _NoteEditorScreenState {
  /// Eki SAYFAYA (yüzen) alır: sabitse bölmeden iner, şeritteyse sayfaya
  /// konur. Sayfada önceden bir yeri varsa oraya döner.
  void _floatOnPage(Attachment a) {
    final note = _note;
    if (note == null) return;
    final latest = note.attachments.where((x) => x.id == a.id).firstOrNull ?? a;
    var next = latest.pinHeight > 0
        ? latest.copyWith(pinHeight: -latest.pinHeight)
        : latest;
    if (next.offPage) {
      final moved = next.placedOnPage(true);
      next = moved.x != null || moved.pageY != null
          ? moved
          : _placeNewImage(moved, note);
    }
    if (identical(next, latest)) return;
    _updateAttachment(next);
    AppHaptics.tick();
  }

  /// GÖRSEL → BALONLU: görsel tek sayfalık bir belgeye çevrilir (yakalama
  /// levhasındaki "balonlu" kipin yolu — bkz. `ScanPdf`), üstündeki çizim
  /// ve balonlar belgeye taşınır. Belge görsele bağlıdır
  /// ([Attachment.sourceId]): klasiğe dönünce gizlenir, yeniden balonluya
  /// alınınca AYNI belge (balonlarıyla) geri gelir.
  Future<void> _imageToBubbles(Attachment image) async {
    final note = _note;
    if (note == null) return;
    final existing = note.attachments
        .where((a) => a.kind == AttachmentKind.pdf && a.sourceId == image.id)
        .firstOrNull;
    if (existing != null) {
      _switchToBubbles(existing);
      return;
    }
    final repo = _attachments;
    if (repo == null) return;
    final l10n = context.l10n;
    _showSnack(l10n.imageNotePreparing);
    File? temp;
    try {
      var path = image.localPath;
      if (!localFileExists(path)) {
        final bytes = await repo.readBytes(image);
        if (bytes == null) {
          if (mounted) _showSnack(l10n.attachmentNotSynced);
          return;
        }
        final dir = await getTemporaryDirectory();
        temp = File(
          '${dir.path}${Platform.pathSeparator}balon_'
          '${DateTime.now().microsecondsSinceEpoch}.img',
        );
        await temp.writeAsBytes(bytes);
        path = temp.path;
      }
      final pdfBytes = await ScanPdf.build([path]);
      if (!mounted) return;
      final dot = image.fileName.lastIndexOf('.');
      final base = dot > 0 ? image.fileName.substring(0, dot) : image.fileName;
      final pdf = await repo.preparePdf(
        noteId: widget.noteId,
        bytes: pdfBytes,
        fileName: '${base.isEmpty ? 'gorsel' : base}.pdf',
      );
      if (!mounted) return;
      final w = image.width ?? 0;
      final h = image.height ?? 0;
      final frame = ScanPdf.imageFrameOnPage(w, h);
      final hasFrame = w > 0 && h > 0;
      final derived = pdf.copyWith(
        sourceId: image.id,
        ink: hasFrame ? placeInk(image.ink, frame) : const [],
        bubbles: hasFrame ? placeBubbles(image.bubbles, frame) : const [],
      );
      _mutate(
        (n) => n.copyWith(attachments: [...n.attachments, derived]),
        immediate: true,
      );
      ScaffoldMessenger.of(context).hideMessage();
      _switchToBubbles(derived);
    } on FileTooLargeException catch (e) {
      if (mounted) _showSnack(_tooLargeMessage(e));
    } catch (e) {
      if (mounted) _showSnack(l10n.genericError(friendlyError(l10n, e)));
    } finally {
      temp?.delete().ignore();
    }
  }

  /// METİN → BALONLU (kullanıcı isteği 2026-10-17: "txt dosyaları da ...
  /// balonlu mod geçişi"): metin ekinden A4 sayfalı bir belge üretilir
  /// (notun PDF dışa aktarımıyla aynı dizgi — Türkçe yazı tipi gömülü) ve
  /// görseldeki gibi kaynağa bağlanır ([Attachment.sourceId]): klasikte
  /// gizlenir, yeniden balonluya alınınca AYNI belge balonlarıyla gelir.
  /// Metin sonradan düzenlendiyse ([Attachment.sourceDigest] tutmuyor) belge
  /// aynı kimlikle YENİDEN dizilir — balonlar ve sayfa notları korunur.
  Future<void> _textToBubbles(Attachment textAttachment) async {
    final note = _note;
    if (note == null) return;
    final repo = _attachments;
    if (repo == null) return;
    final l10n = context.l10n;
    final existing = note.attachments
        .where(
          (a) =>
              a.kind == AttachmentKind.pdf && a.sourceId == textAttachment.id,
        )
        .firstOrNull;
    final digest = Attachment.digestOf(textAttachment.text);
    if (existing != null && existing.sourceDigest == digest) {
      _switchToBubbles(existing);
      return;
    }
    _showSnack(l10n.textToBubblesPreparing);
    try {
      final dot = textAttachment.fileName.lastIndexOf('.');
      final base = dot > 0
          ? textAttachment.fileName.substring(0, dot)
          : textAttachment.fileName;
      final pdfBytes = await NotePdf.build(
        title: base,
        content: textAttachment.text,
      );
      if (!mounted) return;
      final Attachment derived;
      if (existing == null) {
        final pdf = await repo.preparePdf(
          noteId: widget.noteId,
          bytes: pdfBytes,
          fileName: '${base.isEmpty ? 'metin' : base}.pdf',
        );
        derived = pdf.copyWith(
          sourceId: textAttachment.id,
          sourceDigest: digest,
        );
      } else {
        final replaced = await repo.replaceDocumentBytes(
          noteId: widget.noteId,
          attachment: existing,
          bytes: pdfBytes,
        );
        derived = replaced.copyWith(sourceDigest: digest);
      }
      if (!mounted) return;
      _mutate(
        (n) => n.copyWith(
          attachments: existing == null
              ? [...n.attachments, derived]
              : [
                  for (final a in n.attachments)
                    if (a.id == existing.id) derived else a,
                ],
        ),
        immediate: true,
      );
      ScaffoldMessenger.of(context).hideMessage();
      _switchToBubbles(derived);
    } on FileTooLargeException catch (e) {
      if (mounted) _showSnack(_tooLargeMessage(e));
    } catch (e) {
      if (mounted) _showSnack(l10n.genericError(friendlyError(l10n, e)));
    }
  }

  /// Sabit bölmedeki videonun "Bu ana not al" düğmesi.
  /// Sabit videonun ⤢ düğmesi: GERÇEK tam ekran, KALDIĞI YERDEN.
  ///
  /// Kullanıcı bulgusu 2026-10-19: "video sabitken tam ekran yapma seçeneği
  /// yok". Düğme oynatıcı ekranını açıyordu ama video baştan başlıyor, ekran
  /// dikey ve çubuklu kalıyordu. Artık küçük oynatıcının konumu okunur, o
  /// durdurulur, tam ekran o andan açılır; kapanınca küçük oynatıcı tam
  /// ekranda kalınan yere sarılır ve oynuyorsa oynamayı sürdürür.
  Future<void> _openPinnedVideoFullscreen(Attachment video) async {
    // Dosyası henüz bu cihazda olmayan video için eski yol (indirme/uyarı).
    if (!video.isWebVideo && !localFileExists(video.localPath)) {
      _openAttachmentTag(video, editing: true);
      return;
    }
    final source = _videoHub.sourceFor(video.id);
    final wasPlaying = source?.isPlaying ?? false;
    final at = await source?.position();
    await source?.pause();
    if (!mounted) return;
    Duration? end;
    await Navigator.of(context).push(
      MediaRoute<void>(
        builder: (_) => VideoViewerScreen(
          attachment: video,
          start: at,
          fullscreen: true,
          onClose: (position) => end = position,
        ),
      ),
    );
    final back = end;
    // Küçük oynatıcı tam ekran açıkken yeniden kurulmuş olabilir: güncelini al.
    final latest = _videoHub.sourceFor(video.id);
    if (!mounted || latest == null) return;
    if (back != null) await latest.seekTo(back);
    if (wasPlaying) await latest.play();
  }

  Future<void> _noteAtPinned(Attachment video) async {
    final source = _videoHub.sourceFor(video.id);
    if (source == null || !await _videoHub.noteAt(source)) {
      if (mounted) _showSnack(context.l10n.videoTimeUnknown);
    }
  }

  /// Damgaya dokunuldu: video oraya sarılır. Oynatıcısı açık olan video
  /// (son oynatılan, yoksa sabitli olan) önce gelir; hiçbiri açık değilse
  /// sabit/sayfadaki YouTube kutusu o saniyeden başlar, o da yoksa video
  /// tam ekranda o andan açılır.
  void _seekVideoTo(int seconds) {
    final note = _note;
    if (note == null) return;
    final media = [
      for (final a in note.attachments)
        if (a.kind == AttachmentKind.video || a.kind == AttachmentKind.audio) a,
    ];
    if (media.isEmpty) return;
    AppHaptics.tick();
    final pinned = media.where((a) => _inPinnedPane(note, a)).firstOrNull;
    final source = _videoHub.target(preferId: pinned?.id);
    if (source != null) {
      _videoHub.touch(source);
      unawaited(source.seekTo(Duration(seconds: seconds)));
      return;
    }
    final videos = [
      for (final a in media)
        if (a.kind == AttachmentKind.video) a,
    ];
    // Yalnız ŞERİTTE duran ses var (oynatıcı kartı çizili değil): ses
    // tepeye sabitlenir ve kart kurulunca o saniyeye sarılır — damgaya
    // dokunan dinlemek ister, sesin nerede çalacağını aramasın.
    if (videos.isEmpty) {
      final audio = media.first;
      if (_readOnly || note.type.isPageNoteType) return;
      _pinMediaTop(audio);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final pinnedSource = _videoHub.sourceFor(audio.id);
        if (pinnedSource == null) return;
        _videoHub.touch(pinnedSource);
        unawaited(pinnedSource.seekTo(Duration(seconds: seconds)));
      });
      return;
    }
    final pinnedVideo = pinned?.kind == AttachmentKind.video ? pinned : null;
    final inPage =
        pinnedVideo ??
        videos.where((a) => a.isWebVideo && a.floatsOnPage).firstOrNull;
    if (inPage != null && inPage.isWebVideo) {
      _videoHub.requestStart(inPage.id, seconds);
      return;
    }
    final video = pinnedVideo ?? videos.first;
    Navigator.of(context).push(
      MediaRoute<void>(
        builder: (_) => VideoViewerScreen(
          attachment: video,
          start: Duration(seconds: seconds),
          onNoteAt: _readOnly
              ? null
              : (position) => _noteAtVideoTime(video.id, position),
        ),
      ),
    );
  }

  /// "Bu ana not al": liste notunda (ya da odak bir maddedeyken) damgalı
  /// YENİ MADDE açılır; metinde imlecin satırına (boşsa) ya da altına yeni
  /// satıra damga yazılır. Her iki durumda odak oraya gider, klavye açılır.
  void _noteAtVideoTime(String attachmentId, Duration position) {
    final note = _note;
    if (note == null || _readOnly) return;
    final stamp = formatVideoTimestamp(position);
    AppHaptics.tick();
    final target = _formatTarget?.controller;
    final itemsState = _itemsEditorKey.currentState;
    final isList =
        note.type == NoteType.checklist || note.type == NoteType.ordered;
    final focusedItem =
        target != null &&
        target != _bodyController &&
        target != _titleController;
    if (itemsState != null && (focusedItem || (isList && !_listBodyOpen))) {
      itemsState.addItemWithText('$stamp ', after: focusedItem ? target : null);
      return;
    }
    final logical = _bodyController.logicalText;
    final selection = _bodyController.selection;
    final caret = selection.isValid
        ? wrapToLogicalOffset(_bodyController.text, selection.extentOffset)
        : -1;
    final result = insertTimestampLine(logical, caret, stamp);
    _bodyController.setLogical(result.text, result.caret);
    _mutate((n) => n.copyWith(body: result.text), immediate: true);
    if (!_bodyFocus.hasFocus) _bodyFocus.requestFocus();
    _revealCaretSoon();
  }

  // ── PDF OKUMA NOTU (kullanıcı isteği 2026-11-03) ──────────────────────
  //
  // "Okurken not almak çok kolay ve pratik olmalı — YouTube'da dakika
  // kaydetmek gibi": sabit (ya da sayfadaki) PDF'te basılı tutup seçilen
  // yazı "Not al" ile nota "📖 s.12 · 5. satır “alıntı”" satırı olarak
  // girer, imleç satırın sonunda — kullanıcı yorumunu yazmaya devam eder.
  // Referansa dokunmak belgeyi o sayfaya döndürür (bkz. [_goToPdfPage]).

  /// PDF'ten nota satır ekler: [quote] boşsa yalnız sayfa referansı
  /// (bölme çubuğundaki "Not al" — o anki sayfa).
  void _noteAtPdf({required int page, int? line, String quote = ''}) {
    final note = _note;
    if (note == null || _readOnly) return;
    final text = pdfNoteLine(
      page: page,
      line: line,
      quote: quote,
      turkish: Localizations.localeOf(context).languageCode == 'tr',
    );
    AppHaptics.tick();
    final target = _formatTarget?.controller;
    final itemsState = _itemsEditorKey.currentState;
    final isList =
        note.type == NoteType.checklist || note.type == NoteType.ordered;
    final focusedItem =
        target != null &&
        target != _bodyController &&
        target != _titleController;
    if (itemsState != null && (focusedItem || (isList && !_listBodyOpen))) {
      itemsState.addItemWithText('$text ', after: focusedItem ? target : null);
      return;
    }
    final logical = _bodyController.logicalText;
    final selection = _bodyController.selection;
    final caret = selection.isValid
        ? wrapToLogicalOffset(_bodyController.text, selection.extentOffset)
        : -1;
    final result = insertTimestampLine(logical, caret, text);
    _bodyController.setLogical(result.text, result.caret);
    _mutate((n) => n.copyWith(body: result.text), immediate: true);
    if (!_bodyFocus.hasFocus) _bodyFocus.requestFocus();
    _revealCaretSoon();
  }

  /// Referansın gideceği belge: üste sabit PDF, yoksa sayfadaki ilk PDF.
  Attachment? _pdfForRefs(Note note) =>
      note.attachments
          .where((a) => a.kind == AttachmentKind.pdf && a.isPinnedTop)
          .firstOrNull ??
      note.attachments
          .where((a) => a.kind == AttachmentKind.pdf && !a.offPage)
          .firstOrNull;

  /// Gövdede dokunulan PDF referansı; notta PDF yoksa null.
  PdfPageRef? _tappedPdfRef(EditableTextState? editable) {
    final note = _note;
    if (note == null || _pdfForRefs(note) == null) return null;
    return tappedPdfRef(
      displayText: _bodyField.text,
      selection: _bodyController.selection,
      editable: editable,
      tapGlobal: _bodyTapPoint.last,
    );
  }

}
