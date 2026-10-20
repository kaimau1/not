part of 'note_editor_screen.dart';

/// Dikte, sesli yakalama ve imlece metin ekleme.
///
/// F9.3: editör konu başına bölündü; durum (alanlar) [_NoteEditorScreenState]da kalır.
extension _EditorVoice on _NoteEditorScreenState {
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

  bool get _dictating => _dictation != null;

  /// Sade mikrofon: dikteyi başlatır, açıksa bitirir.
  Future<void> _toggleDictation() async {
    if (_dictating) {
      await _stopDictation();
      return;
    }
    final l10n = context.l10n;
    // Yerleşik tanıma yoksa (web) canlı yazma mümkün değil: kullanıcı
    // düğmeye basınca hiçbir şey olmasın diye ses levhasına düşülür —
    // orada konuşma kaydedilip topluca yazıya dökülür.
    if (!await DeviceSpeech.isAvailable()) {
      if (mounted) await _captureVoice();
      return;
    }
    if (!await DeviceSpeech.ensureMicPermission()) {
      if (mounted) _showSnack(l10n.micPermissionDenied);
      return;
    }
    if (!mounted) return;

    // Hedef alan + imleç konumu ŞİMDİ dondurulur. Alan odaklı değilse
    // (kullanıcı nota hiç dokunmadan mikrofona bastı) gövdenin sonuna
    // yazılır ve odak gövdeye verilir — imleç gözle görülür bir yerde olsun.
    var target = _formatTarget;
    if (target == null) {
      _bodyFocus.requestFocus();
      target = _formatTarget;
    }
    final controller = target?.controller ?? _bodyController;
    final selection = controller.selection;
    _dictationTarget = target;
    _dictationAt = selection.isValid
        ? wrapToLogicalOffset(controller.text, selection.baseOffset)
        : controller.logicalText.length;
    _dictationLength = 0;
    _dictationShown = '';

    // Dinlemenin yaşam döngüsü (sessizlikte bitiş, yerli kapanış, üst
    // sınır) levhayla ORTAK oturumda (bkz. VoiceListenSession).
    late final VoiceListenSession session;
    session = VoiceListenSession(
      autoStop: () => ref.read(voiceAutoStopProvider),
      preferOffline: ref.read(voiceOfflineProvider),
      gate: SilenceGate(afterSpeech: ref.read(voiceSilenceProvider).duration),
      onText: (text) {
        if (mounted && identical(_dictation, session)) {
          _writeDictationAtCaret(text);
        }
      },
      // Sessizlik ya da yerli kapanış bir hata değil, bitiştir: yazılan
      // metin zaten notta.
      onEnd: (_) => unawaited(_stopDictation()),
      onError: (message) {
        unawaited(_stopDictation());
        if (mounted) _showSnack(message);
      },
    );
    _update(() {
      _dictation = session;
      _dictationStart = DateTime.now();
    });
    session.start();
  }

  /// Dikteyi bitirir: akış kapatılır, şerit iner, metin olduğu gibi kalır.
  Future<void> _stopDictation() async {
    final sub = _dictation;
    if (sub == null) return;
    _dictation = null;
    _dictationTarget = null;
    _dictationLength = 0;
    _dictationShown = '';
    await sub.cancel();
    await DeviceSpeech.stop();
    // Son sözler beklemede kalmasın: yazım sırasında kayıt gecikmeliydi
    // (yukarıya bak), dikte biterken bir kez kesinleştirilir. `_saveNow`
    // denetleyici ile not arasındaki farkı yazan hazır yol.
    unawaited(_saveNow());
    if (mounted) _update(() {});
  }

  /// Tanınan TAM metni hedef alandaki dikte aralığına yazar.
  ///
  /// Aralığın iki yanına, ancak GEREKİYORSA, birer boşluk konur — cümlenin
  /// ortasına konuşan kullanıcının sözü kelimeye yapışmasın ([insertAtCaret]
  /// ile aynı kural). İmleç her zaman yazılan sözün SONUNDA kalır.
  void _writeDictationAtCaret(String spoken) {
    if (spoken.trim().isEmpty) return;
    final target = _dictationTarget;
    final controller = target?.controller ?? _bodyController;
    final logical = controller.logicalText;
    // Gelen metin ÖNCE yazılanla birleştirilir: satır sonları boşluğa iner ve
    // kısalan (geri giden) sonuç yok sayılır — kullanıcı yazdığı cümlenin
    // bölünüp yeniden birleştiğini görmesin (bkz. [dictationMerge]).
    final merged = dictationMerge(_dictationShown, spoken);
    if (merged == _dictationShown) return;
    _dictationShown = merged;
    // AKILLI KOMUTLAR: birleştirme HAM metin üstünde yapılır (geriye gitmeme
    // kuralı silme komutunu yutmasın), komutlar sonra uygulanır — "son
    // kelimeyi sil" söylenince aralık kısalır, yazma yine en sondan sürer.
    var written = merged;
    if (ref.read(voiceSmartCommandsProvider)) {
      final outcome = applyVoiceCommands(merged);
      written = outcome.text;
      if (outcome.stop) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => unawaited(_stopDictation()),
        );
      }
    }
    // Yazma kuralının kendisi saf bir işlevde (sınanabilsin diye). Komutlar
    // her şeyi sildiyse ("hepsini sil") aralık boşaltılır — dictationReplace
    // boş parçada metne dokunmaz.
    final start = _dictationAt.clamp(0, logical.length);
    final result = written.trim().isEmpty
        ? (
            text: logical.replaceRange(
              start,
              (start + _dictationLength).clamp(start, logical.length),
              '',
            ),
            caret: start,
            length: 0,
          )
        : dictationReplace(logical, _dictationAt, _dictationLength, written);
    final text = result.text;
    if (text == logical) return;
    _dictationLength = result.length;
    controller.setLogical(text, result.caret);
    // **KAYIT YAZMAKLA AYNI YOLDAN, GECİKMELİ.** Tanıyıcı saniyede birkaç kez
    // olay gönderiyor; alanın kendi `commit`i (gövde/başlık) `immediate: true`
    // ile yazdığından her olay ayrı bir Firestore yazımı olurdu — konuşurken
    // ağı ve kotayı boşuna yakan, üstelik kasan bir yol. Klavyeden yazarken
    // izlenen yol da bu değil: `TextField.onChanged` gecikmeli `_mutate`
    // çağırıyor. Madde satırı ise zaten kendi gecikmeli yolundan geçer
    // (ItemsEditor.onChanged), o yüzden orada alanın `commit`i kullanılır.
    if (identical(controller, _bodyController)) {
      _mutate((n) => n.copyWith(body: text));
    } else if (identical(controller, _titleController)) {
      _mutate((n) => n.copyWith(title: text));
    } else {
      target?.commit();
    }
  }

  /// Sesle yakalama: ortak levhayı açar, dönen metni seçilen eyleme göre işler.
  ///
  /// ESKİDEN dikte doğrudan gövdeye canlı yazıyordu; kullanıcı yanlış tanınan
  /// bir cümleyi ancak nottan silerek düzeltebiliyordu. Artık metin önce
  /// levhada gözden geçiriliyor, nota yalnız onaylanan hâli giriyor.
  ///
  /// Dönen metin İMLECİN yerine girer (bkz. [_insertTextAtCaret]).
  Future<void> _captureVoice() async {
    final result = await showVoiceCaptureSheet(
      context,
      target: VoiceCaptureTarget.editor,
    );
    if (result == null || !mounted) return;

    // "başlık X olsun" söylendiyse notun başlığı olur (açıkça istendiği için
    // var olan başlığın yerine geçer).
    final spokenTitle = result.title;
    if (spokenTitle != null) {
      _titleController.text = spokenTitle;
      _mutate((n) => n.copyWith(title: spokenTitle), immediate: true);
    }

    // Dökümü yapılamamış konuşma (anahtar yok / kota / ağ): kayıt nota SES EKİ
    // olarak girer — yapay zekâ çalışmasa da konuşma kaybolmaz.
    final audioPath = result.audioPath;
    if (audioPath != null) {
      await _attachVoiceAudio(audioPath, result.audioDuration);
      if (!mounted) return;
      if (result.text.trim().isNotEmpty) _insertTextAtCaret(result.text);
      return;
    }

    final instruction = voiceCaptureInstruction(result.action);
    if (instruction == null) {
      _insertTextAtCaret(result.text);
      return;
    }

    final l10n = context.l10n;
    _aiTaskN.value = l10n.aiThinking;
    try {
      final text = await ref
          .read(geminiServiceProvider)
          .rewriteText(result.text, instruction);
      if (!mounted) return;
      _insertTextAtCaret(text.trim().isEmpty ? result.text : text.trim());
    } on GeminiException catch (e) {
      if (mounted) _showSnack(e.isAuthError ? l10n.aiNoApiKey : e.message);
    } catch (e) {
      if (mounted) _showSnack(l10n.aiError(e.toString()));
    } finally {
      if (mounted) _aiTaskN.value = null;
    }
  }

  /// Sesli yakalama levhasından dönen (dökümü yapılamamış) kaydı nota ek olarak
  /// bağlar. Yol levhadan devralınır: burada kullanılmazsa dosya silinir.
  Future<void> _attachVoiceAudio(String path, Duration duration) async {
    final repo = _attachments;
    if (repo == null) {
      File(path).delete().ignore();
      return;
    }
    try {
      final attachment = await repo.prepareAudio(
        noteId: widget.noteId,
        sourcePath: path,
        duration: duration,
      );
      _mutate(
        (n) => n.copyWith(attachments: [...n.attachments, attachment]),
        immediate: true,
      );
    } on FileTooLargeException catch (e) {
      File(path).delete().ignore();
      if (mounted) _showSnack(_tooLargeMessage(e));
    } catch (e) {
      File(path).delete().ignore();
      if (mounted) _showSnack(context.l10n.attachmentFailed('$e'));
    }
  }
}
