part of 'note_editor_screen.dart';

extension _EditorActionsExtra on _NoteEditorScreenState {
  /// Not metnini (+ görselleri) PDF/Word'e aktarma ekranı.
  void _openNotesExport(Note current) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PdfExportScreen(
          note: current,
          // Sayfa ölçüleri: görseller dışa aktarmada da nottaki yerlerinde
          // çıksın.
          layout: () {
            final box = _pageBox();
            if (box == null) return null;
            return (
              bodyTop: _bodyTop,
              pageWidth: box.size.width,
              pageHeight: box.size.height,
            );
          }(),
        ),
      ),
    );
  }

  /// Notu sesli okur. Kilitli notta ayrıca doğrulama yok — editör zaten
  /// açılırken doğruluyor.
  ///
  /// **BELGE notunda notun kendi metni yetmez** (kullanıcı bulgusu
  /// 2026-08-08: "PDF sesli oku çalışmıyor"): PDF/sunum notunun düz metni
  /// SAYFA NOTLARIDIR ve çoğu notta boştur — okuma ekranı "okunabilir metin
  /// çıkmadı" diyip duruyordu. Artık belgenin KENDİ metni de okunuyor; sayfa
  /// notları varsa önce onlar gider (kullanıcının kendi yazdığı önce).
  Future<void> _listen() async {
    final note = _note;
    if (note == null) return;
    final text = await noteSpeechText(
      note,
      ref.read(attachmentRepositoryProvider),
    );
    if (!mounted) return;
    if (text.trim().isEmpty) {
      _showSnack(context.l10n.transcriptEmpty);
      return;
    }
    unawaited(ref.read(speechProvider.notifier).speak(text));
  }

  /// Not kilidi: kilitlemede E2EE anahtarı hazırlanır, kilidi kaldırmada
  /// kimlik doğrulanır ve şifreli zarf çözülmüş gövdeyle kalıcı silinir.
  Future<void> _toggleLock() async {
    final note = _note;
    if (note == null) return;
    if (note.locked) {
      final ok = await authenticateForNote(context.l10n.unlockAuthReason);
      if (!ok) return;
      _mutate(
        (n) => n.decryptWithKey(NoteE2eeSession.key).copyWith(locked: false),
        immediate: true,
      );
      return;
    }
    final ok = await ensureNoteE2eeKeyForLock(context.l10n.unlockAuthReason);
    if (!ok) return;
    _mutate(
      (n) => n.decryptWithKey(NoteE2eeSession.key).copyWith(locked: true),
      immediate: true,
    );
  }

  void _toggleArchive() {
    final note = _note;
    if (note == null) return;
    final archived = note.archivedAt != null;
    _mutate(
      (n) => archived
          ? n.copyWith(clearArchivedAt: true)
          : n.copyWith(archivedAt: DateTime.now(), clearExpiresAt: true),
      immediate: true,
    );
    if (!archived && note.expiresAt != null) {
      _notesRepo?.updateFields(widget.noteId, {'expiresAt': null});
    }
    if (!archived) _closeEditor(() => Navigator.of(context).pop());
  }

  /// Sürüm geçmişi (F4.2): seçilen sürüme dönmeden önce bugünkü hâl de
  /// sürüm olarak saklanır — dönüş de geri alınabilir.
  Future<void> _openHistory() async {
    // PL6 kapısı: kilitliyse geçmiş yerine Pro ekranı (satır menüde kalır).
    if (!ref.read(proFeatureProvider(ProFeature.versionHistory))) {
      openProScreen(context);
      return;
    }
    final repo = _notesRepo;
    final note = _note;
    if (repo == null || note == null) return;
    _flushPending(_titleController);
    _flushPending(_bodyController);
    final version = await showNoteHistorySheet(context, repo, note.id);
    if (version == null || !mounted) return;
    final current = _note ?? note;
    await repo.saveVersion(current, reason: 'restore');
    if (!mounted) return;
    final restored = version.applyTo(current);
    _titleController.text = restored.title;
    _bodyController.text = restored.body;
    _mutate((_) => restored, immediate: true);
    _showSnack(context.l10n.versionRestored);
  }

  /// Metni (OCR/döküm) notun gövdesine ya da liste öğelerine ekler.
  /// Markdown işaretleri temizlenir — model istenmese de **kalın**/# üretiyor.
  void _appendText(String raw) => _appendPlainText(stripMarkdown(raw));

  /// Metni OLDUĞU GİBİ (Markdown temizliği yapmadan) nota ekler. QR içeriği
  /// gibi makine verisinde temizlik zararlı: `#` ile başlayan bir satır ya da
  /// `*` taşıyan bir adres bozulurdu.
  void _appendPlainText(String text) {
    final note = _note;
    if (note == null || text.trim().isEmpty) return;
    if (note.type == NoteType.text) {
      final combined = note.body.trim().isEmpty
          ? text.trim()
          : '${note.body}\n\n${text.trim()}';
      _bodyController.text = combined;
      _mutate((n) => n.copyWith(body: combined), immediate: true);
    } else {
      const uuid = Uuid();
      final lines = [
        for (final line in text.split('\n'))
          if (line.trim().isNotEmpty) _parseListLine(line).text,
      ];
      _mutate((n) {
        // Listede sonda hep boş bir "yeni öğe" satırı bekler. Yeni maddeler
        // onun ARKASINA eklenince o boş satır ortada kalıyordu; eklemeden
        // önce sondaki boşlar atılır. Dikte ve AI ekleme aynı yoldan
        // geçtiğinden ikisi de düzelir.
        final kept = [...n.items];
        while (kept.isNotEmpty && kept.last.text.trim().isEmpty) {
          kept.removeLast();
        }
        return n.copyWith(
          items: [
            ...kept,
            for (final line in lines) NoteItem(id: uuid.v4(), text: line),
          ],
        );
      }, immediate: true);
    }
  }

  /// Liste maddesinden görev (TAKVIM F50.3): görev levhası maddenin metniyle
  /// açılır, tamamlanma iki yönlü eşlenir.
  void _makeTask(Note note, NoteItem item) {
    final text = item.text.trim();
    if (text.isEmpty) return;
    unawaited(
      showTaskEditor(
        context,
        initialTitle: text,
        noteId: note.id,
        noteItemId: item.id,
      ),
    );
  }

  /// "+" → Takvime ekle: önce gün, sonra saat (vazgeçilirse tüm gün), sonra
  /// nota bağlı etkinlik levhası — başlık notun, ayrıntılar orada değişir.
  Future<void> _addToCalendar(Note note) async {
    final now = DateTime.now();
    final day = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 10),
    );
    if (day == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: (now.hour + 1) % 24, minute: 0),
    );
    if (!mounted) return;
    unawaited(
      showEventEditor(
        context,
        day: day,
        start: time == null
            ? null
            : DateTime(day.year, day.month, day.day, time.hour, time.minute),
        linkNoteId: note.id,
        initialTitle: note.displayTitle.trim(),
      ),
    );
  }
}
