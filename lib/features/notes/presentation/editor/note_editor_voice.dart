part of 'note_editor_screen.dart';

/// Dikte, sesli yakalama ve imlece metin ekleme.
///
/// F9.3: editör konu başına bölündü; durum (alanlar) [_NoteEditorScreenState]da kalır.
extension _EditorVoice on _NoteEditorScreenState {
  /// GÜN EKLE (kullanıcı isteği 2026-11-23: "otomatik bugünün tarihini
  /// ekler, 22/11/2026 şeklinde"): imleçteki alana — açık tablo hücresi,
  /// madde ya da gövde — bugünün tarihi `gg/aa/yyyy`.
  void _insertDay() => _insertAtCaretOrCell(
    DateFormat('dd/MM/yyyy').format(DateTime.now()),
  );

  /// Gövde/madde odakta değilse ve son yazılan yer bir tablo hücresiyse
  /// metin o hücreye girer; değilse [_insertTextAtCaret].
  void _insertAtCaretOrCell(String text) {
    final typingNote = _formatTarget?.focusNode.hasFocus ?? false;
    if (!typingNote && NoteTableFocus.insert(text)) return;
    _insertTextAtCaret(text);
  }

  /// Metni İMLECİN OLDUĞU YERE ekler; imleç bilinmiyorsa notun sonuna.
  ///
  /// KULLANICI BULGUSU 2026-08-30: "not içerisindeki sesli yazma butonu nota
  /// ekle dendiğinde imlecin olduğu yere eklemiyor, en başa metin notu olarak
  /// ekliyor." [_appendPlainText] metni gövdenin SONUNA, boş satır bırakarak
  /// yığıyordu — kullanıcı cümlenin ortasında konuşup devam edemiyordu.
  ///
  /// Hedef alan en son ODAKLANAN alandır ([_formatTarget]); levha açılırken
  /// odak düştüğü için canlı odağa bakmak yetmez. Başlık hedefse metin yine
  /// gövdeye gider (dikte başlığa yazılmaz).
  void _insertTextAtCaret(String raw) {
    final text = stripMarkdown(raw).trim();
    if (text.isEmpty) return;
    final note = _note;
    if (note == null) return;
    final target = _formatTarget?.controller;
    // Liste maddesinde yazılıyorsa metin O SATIRA girer (satırın notu
    // güncellemesi de editörün kendi yolundan geçsin).
    if (target != null &&
        target != _bodyController &&
        target != _titleController &&
        (_itemsEditorKey.currentState?.insertTextAtCaret(target, text) ??
            false)) {
      return;
    }
    // Gövde alanı yoksa (saf liste notu) ya da imleç hiç konmamışsa eski
    // davranış: metin nota eklenir.
    final hasBody = note.type == NoteType.text || note.body.trim().isNotEmpty;
    final selection = _bodyController.selection;
    if (!hasBody || !selection.isValid) {
      _appendPlainText(text);
      return;
    }
    final logical = _bodyController.logicalText;
    final result = insertAtCaret(
      logical,
      wrapToLogicalOffset(_bodyController.text, selection.baseOffset),
      text,
    );
    if (result.text == logical) return;
    _bodyController.setLogical(result.text, result.caret);
    _mutate((n) => n.copyWith(body: result.text), immediate: true);
  }

  bool get _dictating => _dictationCtl?.isActive ?? false;

  DictationController _ensureDictationController() =>
      _dictationCtl ??= DictationController(
        resolveTarget: () {
          var target = _formatTarget;
          if (target == null) {
            _bodyFocus.requestFocus();
            target = _formatTarget;
          }
          return target;
        },
        fallbackController: () => _bodyController,
        isItemTarget: _dictationIntoItem,
        openItemAfter: (c) {
          final next = _itemsEditorKey.currentState?.openItemAfterController(c);
          if (next == null) return null;
          return FormatTarget(
            controller: next.controller,
            focusNode: next.focus,
            commit: next.commit,
          );
        },
        onCommit: _commitDictation,
        onRevealCaret: _revealCaretSoon,
        smartCommands: () => ref.read(voiceSmartCommandsProvider),
        autoStop: () => ref.read(voiceAutoStopProvider),
        preferOffline: () => ref.read(voiceOfflineProvider),
        silenceAfter: () => ref.read(voiceSilenceProvider).duration,
        onError: (message) {
          if (mounted) {
            _update(() {});
            _showSnack(message);
          }
        },
        onUnavailable: (message) {
          if (!mounted) return;
          _update(() {});
          _showSnack(message);
          unawaited(_captureVoice());
        },
        onSaveNow: () => unawaited(_saveNow()),
      );

  /// Sade mikrofon: dikteyi başlatır, açıksa bitirir.
  Future<void> _toggleDictation() async {
    if (_dictating) {
      await _stopDictation();
      return;
    }
    if (_micBusyElsewhere()) return;
    final l10n = context.l10n;
    if (!await DeviceSpeech.isAvailable()) {
      if (mounted) await _captureVoice();
      return;
    }
    if (!await DeviceSpeech.ensureMicPermission()) {
      if (mounted) _showSnack(l10n.micPermissionDenied);
      return;
    }
    if (!mounted) return;
    // Alt paneller üst üste binmesin: dikte açılınca biçim ve kalem kapanır.
    if (_formatBarOpen) _formatBarOpen = false;
    final closePen = _penMode;
    TipOnce.show(
      context,
      ref.read(sharedPreferencesProvider),
      TipOnce.voiceCommands,
      l10n.tipVoiceCommands,
      icon: AppIcons.dictation,
    );
    final initialLocale = Localizations.localeOf(context).languageCode == 'en'
        ? 'en-US'
        : 'tr-TR';
    final ctl = _ensureDictationController();
    ctl.start(initialLocale: initialLocale);
    _update(() {
      if (closePen) _penMode = false;
    });
  }

  /// Dikteyi bitirir: ÖNCE son sonucun akıştan gelmesini bekler, ardından
  /// şeridi kapatır.
  Future<void> _stopDictation() async {
    final ctl = _dictationCtl;
    if (ctl == null || !ctl.isActive) return;
    await ctl.stop(offerFix: false);
    if (mounted) _update(() {});
  }

  /// Dikte yazımını kaydeder (yazım sırasındaki debouncer'dan beslenir).
  void _commitDictation(
    FormatTarget? target,
    WrapTextController controller,
    String text,
  ) {
    if (identical(controller, _bodyController)) {
      _mutate((n) => n.copyWith(body: text));
    } else if (identical(controller, _titleController)) {
      _mutate((n) => n.copyWith(title: text));
    } else {
      target?.commit();
    }
  }

  /// Dikte bir LİSTE MADDESİNE mi yazıyor (gövde/başlık değil).
  bool _dictationIntoItem(FormatTarget? target, WrapTextController c) =>
      target != null &&
      !identical(c, _bodyController) &&
      !identical(c, _titleController) &&
      _itemsEditorKey.currentState?.itemIdForController(c) != null;

  /// Sesle yakalama: ortak levhayı açar, dönen metni imlecin yerine ekler.
  Future<void> _captureVoice() async {
    final result = await showVoiceCaptureSheet(
      context,
      target: VoiceCaptureTarget.editor,
    );
    if (result == null || !mounted) return;

    final spokenTitle = result.title;
    if (spokenTitle != null) {
      _titleController.text = spokenTitle;
      _mutate((n) => n.copyWith(title: spokenTitle), immediate: true);
    }

    if (result.audioPath != null || result.audioBytes != null) {
      await _attachVoiceAudio(
        result.audioPath,
        result.audioBytes,
        result.audioMime,
        result.audioDuration,
      );
      if (!mounted) return;
      if (result.text.trim().isNotEmpty) _insertTextAtCaret(result.text);
      return;
    }

    if (result.text.trim().isNotEmpty) {
      _insertTextAtCaret(result.text);
    }
  }

  /// Sesli yakalama levhasından dönen (dökümü yapılamamış) kaydı nota ek olarak
  /// bağlar. Yol levhadan devralınır: burada kullanılmazsa dosya silinir.
  Future<void> _attachVoiceAudio(
    String? path,
    Uint8List? bytes,
    String? mime,
    Duration duration,
  ) async {
    final repo = _attachments;
    if (repo == null) {
      if (!kIsWeb && path != null && path.isNotEmpty) {
        File(path).delete().ignore();
      }
      return;
    }
    try {
      final attachment = bytes != null
          ? await repo.prepareAudioBytes(
              noteId: widget.noteId,
              bytes: bytes,
              duration: duration,
              mimeTypeHint: mime,
            )
          : await repo.prepareAudio(
              noteId: widget.noteId,
              sourcePath: path!,
              duration: duration,
            );
      _mutate(
        (n) => n.copyWith(attachments: [...n.attachments, attachment]),
        immediate: true,
      );
    } on FileTooLargeException catch (e) {
      if (!kIsWeb && path != null && path.isNotEmpty) {
        File(path).delete().ignore();
      }
      if (mounted) _showSnack(_tooLargeMessage(e));
    } catch (e) {
      if (!kIsWeb && path != null && path.isNotEmpty) {
        File(path).delete().ignore();
      }
      if (mounted) {
        _showSnack(
          context.l10n.attachmentFailed(friendlyError(context.l10n, e)),
        );
      }
    }
  }
}
