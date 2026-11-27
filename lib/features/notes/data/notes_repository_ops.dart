part of 'notes_repository.dart';

extension NotesRepositoryOps on NotesRepository {
  /// Açılışta: önceki oturumda buluta ulaşmadan kalmış editör içeriğini
  /// yazar. Bulutta artık olmayan / çöpe atılmış nota dokunulmaz (silinen
  /// not geri gelmesin); okunamayan girdi sonraki açılışta yeniden denenir.
  Future<int> recoverJournal() async {
    final entries =
        journal?.rawEntries() ?? webJournal?.rawEntries() ?? const {};
    if (entries.isEmpty) return 0;
    var written = 0;
    for (final e in entries.entries.toList()) {
      try {
        final snap = await _notes.doc(e.key).get();
        final data = snap.data();
        if (data == null || data['deletedAt'] != null) {
          journal?.remove(e.key);
          webJournal?.remove(e.key);
          continue;
        }
        unawaited(updateNote(Note.fromMap(e.key, e.value)));
        written++;
      } catch (err, st) {
        ErrorLog.record('lite-journal', err, st);
      }
    }
    return written;
  }

  /// ARTIMLI ayrıştırma: her snapshot'ta yalnız değişen dokümanlar
  /// `Note.fromDoc`tan geçer. Editörde yazarken 3 sn'de bir snapshot düşer;
  /// eskiden her seferinde TÜM koleksiyon (items + attachments + zaman
  /// damgaları) yeniden ayrıştırılıyordu — maliyet nota değil koleksiyona
  /// orantılıydı. Önbellek akış (dolayısıyla oturum/uid) başına birdir;
  /// ilk snapshot'ta tüm dokümanlar "added" olarak gelir ve haritayı doldurur.
  ///
  /// [delta] (S1, `config/app.syncDeltaListen`; VARSAYILAN AÇIK, `false` kapatır): liste
  /// önbellekten, sunucudan yalnız değişenler — bkz. [NotesDeltaFeed].
  /// Kapalıyken aşağıdaki sorgu bugünkü gibi sunucudan dinlenir.
  Stream<List<Note>> watchNotes({bool delta = false, NotesDeltaFeed? feed}) {
    final cache = <String, Note>{};
    void apply(QuerySnapshot<Map<String, dynamic>> snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.removed) {
          cache.remove(change.doc.id);
        } else {
          cache[change.doc.id] = Note.fromDoc(change.doc);
        }
      }
    }

    final Stream<List<Note>> cloud;
    if (delta || feed != null) {
      NotesRepository.lastFeed = feed ??= NotesDeltaFeed(_notes);
      cloud = feed.events().map((e) {
        if (e.reset) cache.clear();
        apply(e.snapshot);
        return cache.values.toList();
      });
    } else {
      cloud = _notes.where('deletedAt', isNull: true).snapshots().map((
        snapshot,
      ) {
        apply(snapshot);
        return cache.values.toList();
      });
    }
    return _withLocal(cloud, (List<Note> cloudNotes) {
      final store = local;
      if (store == null || store.isEmpty) {
        return [...cloudNotes]..sort(NotesRepository._compare);
      }
      // Aynı kimlik iki yerde (senkron kapatılırken bir an) → YEREL kazanır.
      final localNotes = store.notes();
      final ids = {for (final n in localNotes) n.id};
      return [
        ...localNotes,
        for (final n in cloudNotes)
          if (!ids.contains(n.id)) n,
      ]..sort(NotesRepository._compare);
    });
  }

  /// **TEK BİR KLASÖRÜN notları.** [watchNotes]'un dar kapsamlı ikizi.
  ///
  /// KÖK NEDEN (paylaşılan klasör "Missing or insufficient permissions"
  /// veriyordu — kullanıcı bulgusu 2026-08-18): paylaşılan klasör ekranı
  /// sahibin notlarını [watchNotes] ile, yani KOLEKSİYONUN TAMAMINI
  /// isteyerek okuyordu. Firestore'da bir liste sorgusu, sonuçları kurala
  /// göre AYIKLAMAZ; kural sonuçtaki HER doküman için geçmiyorsa sorgunun
  /// TAMAMI reddedilir. Kural ise erişimi yalnız "paylaşılan klasöre ait"
  /// notlara veriyor (bkz. firestore.rules) — sahibin öbür notları sorguya
  /// girdiği an istek çöküyordu ve ekran hep hata gösteriyordu.
  ///
  /// Sorgu `folderId`ye daraltılınca sonuçtaki her doküman kuralın kapsamına
  /// girer ve izin verilir.
  ///
  /// Çöp kutusu süzgeci SUNUCUDA DEĞİL istemcide: tek eşitlik süzgeci
  /// otomatik tek-alan indeksiyle karşılanır, ikinci bir süzgeç eklemek
  /// bileşik indeks sorusunu açardı (bu depoda `firestore.indexes.json`
  /// bilerek boş). Klasör başına not sayısı küçük olduğundan ayıklama
  /// istemcide ucuz.
  ///
  /// Ayrıştırma [watchNotes] gibi ARTIMLI (F6.7): her anlık görüntüde
  /// klasörün bütün notları yeniden ayrıştırılıyordu.
  Stream<List<Note>> watchFolderNotes(String folderId) {
    final cache = _IncrementalNotes();
    return _notes
        .where('folderId', isEqualTo: folderId)
        .snapshots()
        .map((snapshot) {
          final notes = [
            for (final n in cache.apply(snapshot))
              if (n.deletedAt == null) n,
          ];
          notes.sort(NotesRepository._compare);
          return notes;
        });
  }

  /// Çöp kutusu: yalnız silinmiş belgeler sorgulanır (F6.7 — eskiden
  /// KOLEKSİYONUN TAMAMI dinlenip istemcide ayıklanıyordu; eşitsizlik
  /// süzgecini [purgeOldTrash] de kullanıyor, tek alan indeksi otomatik).
  /// `deletedAt` hep istemci saatiyle yazılır (sunucu damgası değil), yerel
  /// önbellekte de hemen eşleşir.
  Stream<List<Note>> watchTrash() {
    final cache = _IncrementalNotes();
    return _withLocal(
      _notes
          .where('deletedAt', isGreaterThan: Timestamp(0, 0))
          .snapshots()
          .map(cache.apply),
      (List<Note> cloudTrash) {
        final localTrash = local?.notes(deleted: true) ?? const <Note>[];
        final ids = {for (final n in localTrash) n.id};
        final notes = [
          ...localTrash,
          for (final n in cloudTrash)
            if (n.deletedAt != null && !ids.contains(n.id)) n,
        ];
        notes.sort((a, b) {
          final aTime = a.deletedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bTime = b.deletedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bTime.compareTo(aTime);
        });
        return notes;
      },
    );
  }

  /// **F3.5 GÖÇÜ**: eski defterler (`type: archive`) sayfalı not olur
  /// (bkz. `notebookToPagedNote`). Editör de açılışta çevirir; bu, hiç
  /// açılmayan defterleri de çevirir ki liste/arama/dışa aktarma tek modeli
  /// görsün. Döner: çevrilen defter sayısı.
  Future<int> migrateNotebooks() async {
    var count = 0;
    final snapshot = await _notes
        .where('type', isEqualTo: NoteType.archive.id)
        .get();
    for (final doc in snapshot.docs) {
      final note = Note.fromMap(doc.id, doc.data());
      await updateNote(
        notebookToPagedNote(note, pageId: (_) => NotesRepository._uuid.v4()),
      );
      count++;
    }
    final store = local;
    if (store != null) {
      for (final e in store.rawEntries().entries) {
        final note = Note.fromMap(e.key, e.value, localOnly: true);
        if (note.type != NoteType.archive) continue;
        await updateNote(
          notebookToPagedNote(note, pageId: (_) => NotesRepository._uuid.v4()),
        );
        count++;
      }
    }
    return count;
  }

  /// Bir etiketi TÜM notlarda yeniden adlandırır. Aynı ada sahip bir etiket
  /// zaten varsa ikisi BİRLEŞİR (küme mantığı — bir notta aynı etiket iki kez
  /// duramaz).
  ///
  /// NEDEN: etiketler yalnız notlardan türetiliyordu; yazım hatasıyla açılmış
  /// bir etiketi ("prjeler") düzeltmenin tek yolu onu taşıyan HER notu tek tek
  /// açıp elle değiştirmekti. Etiket düzeni bu yüzden bozuluyordu.
  ///
  /// [notes] çağıranın elindeki liste: depo zaten canlı akışı besliyor, ikinci
  /// bir sunucu okuması yapmaya gerek yok (çevrimdışıyken de çalışır).
  Future<void> renameTag(List<Note> notes, String from, String to) async {
    final target = to.trim();
    if (target.isEmpty || target == from) return;
    for (final note in notes) {
      if (!note.tags.contains(from)) continue;
      final next = <String>[];
      for (final tag in note.tags) {
        final mapped = tag == from ? target : tag;
        if (!next.contains(mapped)) next.add(mapped);
      }
      await updateFieldsAndWait(note.id, {'tags': next});
    }
  }

  /// Etiketi TÜM notlardan kaldırır. Notlar silinmez, yalnız etiket düşer.
  Future<void> deleteTag(List<Note> notes, String tag) async {
    for (final note in notes) {
      if (!note.tags.contains(tag)) continue;
      await updateFieldsAndWait(note.id, {
        'tags': [
          for (final t in note.tags)
            if (t != tag) t,
        ],
      });
    }
  }

  void hardDelete(String noteId) {
    if (isLocal(noteId)) {
      local!.remove(noteId);
      return;
    }
    _deleteCloudCopy(noteId);
  }

  /// Notun buluttaki HER şeyi: belge + alt koleksiyonlar. Alt koleksiyon
  /// belgeyle silinmez (Firestore) — ağır belge, sürümler (F4.2, notun
  /// METNİNİ taşır) ve "düzenliyor" nabızları ayrıca gider. Kalıcı silme ve
  /// "yalnız bu cihaz"a alma ORTAK yolu (F5.4: ikincisi sürümleri bulutta
  /// bırakıyordu).
  void _deleteCloudCopy(String noteId) {
    unawaited(_notes.doc(noteId).delete());
    unawaited(_heavyDoc(noteId).delete().catchError((Object _) {}));
    for (final sub in [
      _versions(noteId),
      _notes.doc(noteId).collection(kPresenceCollection),
      // Mürekkep v2 bant belgeleri (F61.4).
      _notes.doc(noteId).collection(kInkCollection),
    ]) {
      unawaited(
        sub.get().then((snap) {
          for (final doc in snap.docs) {
            unawaited(doc.reference.delete().catchError((Object _) {}));
          }
        }, onError: (Object _) {}),
      );
    }
  }

  /// Notu Storage'daki ekleriyle birlikte kalıcı siler (çöp ekranındaki
  /// "kalıcı sil" ve otomatik çöp boşaltma kullanır).
  Future<void> deleteNotePermanently(Note note) async {
    // Ek silmeleri paralel: sıralı bekleyiş, çok ekli notlarda (çöp boşaltma
    // açılışta çalıştığı için) ilk senkronla yarışan uzun bir ağ kuyruğu
    // oluşturuyordu.
    final deleteDrive = driveFileDeleter;
    await Future.wait([
      for (final attachment in note.attachments)
        if (attachment.storagePath.isNotEmpty)
          FirebaseStorage.instance
              .ref(attachment.storagePath)
              .delete()
              .catchError((Object _) {}),
      // Google Drive kopyası (bkz. drive_store.dart). Drive bağlı değilse
      // dosya Drive'da kalır — yalnız yer kaplar.
      for (final attachment in note.attachments)
        if (attachment.isInDrive && deleteDrive != null)
          deleteDrive(attachment.driveId).catchError((Object _) {}),
      for (final attachment in note.attachments) deleteThumb(attachment),
    ]);
    // Cihazdaki ek klasörü de gitsin: yalnız bulut temizliği, her kalıcı
    // silmede `<destek>/attachments/<noteId>/` altında yetim dosya bırakıyor
    // ve büyük PDF/görsellerle görünmez bir disk sızıntısına dönüşüyordu.
    // ASYNC G/Ç: purgeOldTrash açılışta koşuyor; senkron listeleme/silme çok
    // ekli çöpte açılış karesini kilitlerdi.
    final base = appSupportPath;
    if (base != null) {
      final dir = Directory(p.join(base, 'attachments', note.id));
      try {
        if (await dir.exists()) {
          await for (final f in dir.list()) {
            forgetLocalFile(f.path);
          }
          await dir.delete(recursive: true);
        }
      } catch (_) {
        // Dosya kilitli/erişilemez olabilir (Windows'ta açık görüntüleyici);
        // silme bir sonraki kalıcı silmede yeniden denenir, veri riski yok.
      }
    }
    // Not başına menü düzeni (yerel tercih) de silinir.
    Personalize.forgetNote(note.id);
    hardDelete(note.id);
  }

  /// Çöp kutusunda [NotesRepository.trashRetention] süresini doldurmuş notları ekleriyle
  /// birlikte kalıcı siler. Her uygulama açılışında çağrılır.
  ///
  /// Süre 24 SAATTEN 30 GÜNE çıkarıldı (kullanıcı isteği): bir haftalık
  /// tatilden dönen kullanıcı yanlışlıkla sildiği notu bulamıyordu. Depolama
  /// bedeli önemsiz — silinen notlar zaten ana listede görünmüyor.
  Future<void> purgeOldTrash() async {
    final cutoff = Timestamp.fromDate(
      DateTime.now().subtract(NotesRepository.trashRetention),
    );
    for (final note in local?.notes(deleted: true) ?? const <Note>[]) {
      final deleted = note.deletedAt;
      if (deleted != null && deleted.isBefore(cutoff.toDate())) {
        await deleteNotePermanently(note);
      }
    }
    final snapshot = await _notes.where('deletedAt', isLessThan: cutoff).get();
    for (final doc in snapshot.docs) {
      await deleteNotePermanently(Note.fromDoc(doc));
    }
  }

  /// Boş kalıp unutulmuş notları siler. Şu an editörde yazılıyor olabilecek
  /// taze notlara dokunmaz: not [openEditorNoteIds] içinde OLMAMALI ve son
  /// düzenlemesi 2 dakikadan eski olmalı.
  ///
  /// Açık not koruması sonradan eklendi: kullanıcı yeni nota yazmaya
  /// başladığında doküman bir süre boş kalır (ilk kayıt henüz yapılmamıştır);
  /// o sırada silinmesi, editörün sonraki merge'lü yazımı dokümanı yeniden
  /// yaratsa bile klasör/renk/sıra gibi alanları sıfırlıyordu.
  Future<void> cleanupEmptyNotes(List<Note> notes) async {
    final cutoff = DateTime.now().subtract(const Duration(minutes: 2));
    for (final note in notes) {
      if (openEditorNoteIds.contains(note.id)) continue;
      if (note.locked || note.extras.containsKey('e2ee')) continue;
      final updated = note.updatedAt;
      if (note.isEmpty && updated != null && updated.isBefore(cutoff)) {
        try {
          await _deleteIfStillEmpty(note.id, cutoff);
        } catch (_) {
          // Çevrimdışı (transaction ağ ister) ya da geçici hata: not kalır,
          // sonraki turda yeniden denenir. Kalıcı silmede aceleye yer yok.
        }
      }
    }
  }

  /// Boş-not kararı bayat bir anlık görüntüyle verilmiş olabilir: başka
  /// cihaz notu TAM BU SIRADA doldurduysa düz `delete()` içerikli notu
  /// kalıcı götürürdü (çöpe bile uğramadan). Transaction sunucudaki güncel
  /// hâli okuyup "hâlâ boş ve eski" önkoşulunu doğrular; koşul bozulduysa
  /// silme sessizce vazgeçer.
  Future<void> _deleteIfStillEmpty(String noteId, DateTime cutoff) async {
    if (isLocal(noteId)) {
      final note = local!.note(noteId);
      final updated = note?.updatedAt;
      if (note != null &&
          !note.locked &&
          !note.extras.containsKey('e2ee') &&
          note.isEmpty &&
          updated != null &&
          updated.isBefore(cutoff)) {
        local!.remove(noteId);
      }
      return;
    }
    await _firestore.runTransaction((tx) async {
        final ref = _notes.doc(noteId);
        final snapshot = await tx.get(ref);
        if (!snapshot.exists) return;
        final note = Note.fromDoc(snapshot);
        final updated = note.updatedAt;
        if (note.locked ||
            note.extras.containsKey('e2ee') ||
            !note.isEmpty ||
            updated == null ||
            !updated.isBefore(cutoff)) {
          return;
        }
        tx.delete(ref);
      });
  }
}
