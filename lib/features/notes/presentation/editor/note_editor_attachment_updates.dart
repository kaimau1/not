part of 'note_editor_screen.dart';

extension _EditorAttachmentUpdates on _NoteEditorScreenState {
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
    final byId = {
      for (final a in updated) a.id: _withLiveTable(_withLiveInk(a)),
    };
    _mutate(
      (n) => n.copyWith(
        attachments: [for (final a in n.attachments) byId[a.id] ?? a],
      ),
      immediate: true,
    );
  }

  /// **BAYAT MÜREKKEP KORUMASI** (OTURTMA F60.1): eke çizgi kökü kurmadığı
  /// için bölme/kutu eski çizgi listeli eki tutar; oradan gelen mürekkep
  /// DIŞI değişiklik (sayfa çevirme, balon, boy) o listeyi geri yazıp
  /// çizgileri silmesin. Elindeki liste tam o bayat listeyse çağıranın
  /// mürekkeple işi yoktur: güncel çizgiler korunur.
  Attachment _withLiveInk(Attachment updated) {
    final stale = _staleInk[updated.id];
    if (stale == null || !identical(updated.ink, stale)) return updated;
    final live = _note?.attachments
        .where((a) => a.id == updated.id)
        .firstOrNull;
    return live == null ? updated : updated.copyWith(ink: live.ink);
  }

  /// Eke çizilen çizgi (sabit bölme, gömülü belge): SAF değişiklik — çizgi
  /// kendi katmanında zaten ekranda, kök kurulmaz ve kayıt debounce'ludur
  /// (çizgi başına tam editör kurulumu + anında tam kayıt B5'ti). Yalnız
  /// mürekkep alınır; ekin diğer alanları nottaki güncel hâlinden.
  void _updateAttachmentInk(Attachment updated) {
    _mutate(
      (n) => n.copyWith(
        attachments: [
          for (final a in n.attachments)
            if (a.id == updated.id) a.copyWith(ink: updated.ink) else a,
        ],
      ),
      inkOnly: true,
    );
  }

  /// **BAYAT TABLO KORUMASI** ([_withLiveInk]'in tablo karşılığı): tablo
  /// içeriği kök kurulmadan ilerlediği için tuval (taşı, boyutlandır,
  /// görünüm) eski içerikli eki tutar; oradan gelen düzen değişikliği
  /// hücreleri geri yazmasın. Elindeki yapı tam o bayat yapıysa güncel
  /// içerik (yazı, yapı, oran) korunur.
  Attachment _withLiveTable(Attachment updated) {
    final stale = _staleTable[updated.id];
    if (stale == null || !identical(updated.extras, stale.extras)) {
      return updated;
    }
    final live = _note?.attachments
        .where((a) => a.id == updated.id)
        .firstOrNull;
    return live == null
        ? updated
        : updated.copyWith(
            text: live.text,
            sizeBytes: live.sizeBytes,
            extras: live.extras,
            width: live.width,
            height: live.height,
          );
  }

  /// Tablo kutusundan gelen İÇERİK (hücreler, yapı, oran): kök kurulmaz
  /// ([_mutate] `tableOnly`), kayıt debounce'lu; ekin düzen alanları
  /// nottaki güncel hâlinden.
  void _updateTableContent(Attachment fromBox) {
    _mutate(
      (n) => n.copyWith(
        attachments: [
          for (final a in n.attachments)
            if (a.id == fromBox.id)
              a.copyWith(
                text: fromBox.text,
                sizeBytes: fromBox.sizeBytes,
                extras: fromBox.extras,
                width: fromBox.width,
                height: fromBox.height,
              )
            else
              a,
        ],
      ),
      tableOnly: true,
    );
  }

  void _updateAttachment(Attachment updated) {
    updated = _withLiveTable(_withLiveInk(updated));
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

}
