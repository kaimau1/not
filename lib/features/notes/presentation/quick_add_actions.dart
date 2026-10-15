import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart' show FieldValue;
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/utils/doc_picker.dart';
import '../../settings/data/permissions_service.dart';
import '../data/attachment_repository.dart';
import '../data/document_scan.dart';
import '../data/note_share.dart';
import '../data/notes_repository.dart';
import '../data/scan/scan_pdf.dart';
import '../data/scan/scan_title.dart';
import '../data/video_frame.dart';
import '../domain/note.dart';
import '../domain/note_templates.dart';
import 'note_template_sheet.dart';
import '../domain/note_type.dart';
import 'capture_mode_sheet.dart';
import 'image_prepare_screen.dart';
import 'notes_providers.dart';
import 'qr_scan_screen.dart';
import 'scan_review_screen.dart';

/// **SAĞ ALTTAKİ YÜZEN "+" DÜĞMESİNİN ARDINDAKİ İŞ.**
///
/// On bir oluşturma akışı (metin/madde, el yazısı, sesli, görüntülü, foto,
/// belge tarama, PDF, görsel, sunum, QR) burada YAŞAR; [QuickAddFab] yalnız
/// menüyü çizer.
///
/// NİYE ORTAK: bu akışlar ana ekranın kendi durumunun içinde yazılmıştı ve
/// klasörün kendi sayfasındaki "+" düğmesi onlara ulaşamadığı için YALNIZ boş
/// bir metin notu açabiliyordu (kullanıcı bulgusu 2026-08-29: "klasör
/// içlerindeki ekle butonu sadece metin notu açıyor, ana sayfadaki ekle ile
/// aynı olmalı"). Kopyalamak yerine tek kaynağa taşındı: iki ekran da aynı
/// menüyü ve aynı davranışı alır, biri düzeldiğinde ikisi birden düzelir.
///
/// Bağlayan ekran üç şeyi söyler: notun doğacağı klasör ([quickAddFolderId]),
/// notun nasıl açılacağı ([openNewNote]) ve — varsa — arama kutusunun nasıl
/// temizleneceği ([clearQuickAddSearchBox]).
mixin QuickAddActions<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  /// Oluşturulan not bu klasöre doğar; null = klasörsüz.
  ///
  /// Ana ekran seçili klasör süzgecini, klasör sayfası kendi klasörünü verir.
  String? get quickAddFolderId;

  /// Yeni not oluşturuldu: ekranda AÇ. Ana ekran GoRouter yolunu kullanır,
  /// klasör sayfası da aynısını yapar — ama açılış ekranın kendi işidir.
  Future<void> openNewNote(String id, {String query = '', NoteType? type});

  /// Arama kutusu olan ekran (ana ekran) bunu ezer: yeni not, yazılı bir
  /// arama yüzünden listeden elenmesin. Arama kutusu olmayan ekranda iş yok.
  void clearQuickAddSearchBox() {}

  void showQuickAddSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// **ŞABLONDAN NOT** (kullanıcı isteği 2026-09-26: "modlar, alışveriş
  /// listesi gibi"). Galeri + önizleme levhası açılır; [template] verilirse
  /// galeri atlanır, doğrudan o şablonun önizlemesi gelir (2026-09-29:
  /// maddeler not oluşmadan seçilir/eklenir). Not başlığı ve içeriğiyle TEK
  /// yazımda doğar, o anki klasöre düşer.
  Future<void> createFromTemplate([NoteTemplate? template]) async {
    final content = await showNoteTemplateSheet(context, initial: template);
    if (content == null || !mounted) return;
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;
    final id = await repo.createNote(
      content.type,
      title: content.title,
      body: content.body,
      items: content.items,
      folderId: quickAddFolderId,
    );
    await openNewNote(id, type: content.type);
  }

  Future<void> createNote(NoteType type) async {
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;
    // Klasör TEK yazımda: createNote + ayrı updateFields arasında doküman bir
    // an klasörsüz/boş kalıyordu (bkz. NotesRepository.createNote yorumu).
    final id = await repo.createNote(
      type,
      folderId: quickAddFolderId,
    );
    await openNewNote(id, type: type);
    // Dönüşte notu GİZLEYECEK süzgeçler temizlenir — hızlı yakalama satırında
    // çözülen kök neden ("Yıldızlı"/etiket/arama açıkken yeni not listede hiç
    // görünmüyordu) FAB yolunda açık kalmıştı. Klasör süzgeci kalır (not o
    // klasöre doğdu); boş bırakılıp silinen not için süzgeçlere dokunulmaz.
    if (!mounted) return;
    // Kısa bekleme ŞART: push future'ı POP anında tamamlanır, editörün son
    // yazımı ise dispose'daki _saveNow'da (çıkış animasyonundan sonra) düşer.
    // Hemen bakılsaydı hızlı yazıp çıkan kullanıcının notu akışta hâlâ boş
    // görünür ve süzgeçler temizlenmezdi — düzeltmenin hedeflediği senaryo.
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    final kept = ref.read(notesStreamProvider).value ?? const <Note>[];
    final survives = kept.any((n) => n.id == id && !n.isEmpty);
    if (!survives) return;
    if (ref.read(noteFilterProvider) != NoteFilter.all) {
      ref.read(noteFilterProvider.notifier).set(NoteFilter.all);
    }
    if (ref.read(selectedTagProvider) != null) {
      ref.read(selectedTagProvider.notifier).set(null);
    }
    if (ref.read(searchQueryProvider).trim().isNotEmpty) {
      clearQuickAddSearchBox();
      ref.read(searchQueryProvider.notifier).set('');
    }
  }


  /// El yazısı modu: not oluşturulur ve editör doğrudan çizim tuvalini
  /// açarak başlar; çizim nota görsel eki olarak kaydedilir.
  Future<void> createHandwritingNote() async {
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;
    final id = await repo.createNote(NoteType.text);
    final folderId = quickAddFolderId;
    if (folderId != null) repo.updateFields(id, {'folderId': folderId});
    await openNewNote(id, query: '?draw=1');
  }

  /// Sesli not modu (Keep'teki gibi): not oluşturulur, editör açılır açılmaz
  /// ses kaydı başlar ve konuşma dökümü nota canlı yazılır; bitişte ses
  /// m4a eki olarak nota bağlanır.
  Future<void> createVoiceCaptureNote() async {
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;
    final id = await repo.createNote(NoteType.text);
    final folderId = quickAddFolderId;
    if (folderId != null) repo.updateFields(id, {'folderId': folderId});
    await openNewNote(id, query: '?voice=1');
  }

  /// **SESLE YAZ** — yapay zekâsız, levhasız dikte notu.
  ///
  /// Kullanıcı isteği 2026-09-01: "sesle yazma çok pratik ve doğru olmalı…
  /// ana ekrandaki ses butonunu da güncelle." Ana ekranın sade mikrofonu
  /// boş bir metin notu açar ve dikteyi hemen başlatır: konuşulan söz
  /// doğrudan nota düşer, arada gözden geçirme levhası yoktur.
  Future<void> createDictationNote() async {
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;
    final id = await repo.createNote(NoteType.text);
    final folderId = quickAddFolderId;
    if (folderId != null) repo.updateFields(id, {'folderId': folderId});
    await openNewNote(id, query: '?dictate=1');
  }

  /// Görüntülü not: kamera açılır, video YALNIZCA cihazda saklanır (buluta
  /// yüklenmez).
  ///
  /// **Balonlu kip** (kullanıcı isteği 2026-08-09: "belge tara not al,
  /// görüntülü not al, foto çek not al — bunlarda da balonlu mod olmalı"):
  /// balon/vurgu/el yazısı bir SAYFANIN üzerinde yaşar, videonun sayfası yok.
  /// Bu yüzden balonlu kipte videodan KARELER alınıp belge SAYFALARINA
  /// dönüştürülür ve video nota ek olarak bağlı kalır — hem üzerine
  /// işaretlenebilir görüntüler hem de kaydın kendisi elde durur.
  ///
  /// Kare SAYISI kaydın uzunluğuna göre seçilir (bkz. [VideoFrame.sample]):
  /// tek kapak karesi, videodan alınan notu videonun ilk saniyesine
  /// hapsediyordu.
  Future<void> createVideoNote() async {
    // Kapak karesi yalnız Android'de çıkarılabiliyor: masaüstünde seçenek hiç
    // SORULMAZ — sorup sonra sessizce klasiğe düşmek, seçimi yok saymak olurdu.
    final choice = VideoFrame.supported
        ? await _askCaptureMode(context.l10n.newVideoNote)
        : const CaptureChoice(mode: CaptureMode.classic, noteTitle: '');
    if (choice == null || !mounted) return;
    if (choice.mode == CaptureMode.classic) {
      await _openBlankNote(
        NoteType.text,
        query: '?video=1',
        title: choice.noteTitle,
      );
      return;
    }
    final l10n = context.l10n;
    final perms = ref.read(permissionsServiceProvider);
    if (!await perms.cameraGranted() && !await perms.requestCamera()) {
      if (mounted) showQuickAddSnack(l10n.permCameraInfo);
      return;
    }
    if (!mounted) return;
    final picked = await ImagePicker().pickVideo(source: ImageSource.camera);
    if (picked == null || !mounted) return;
    // Kare çıkarmak (uzun videoda birkaç saniye) sessiz beklemesin.
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(SnackBar(content: Text(l10n.videoFramesExtracting)));
    final frames = await VideoFrame.sample(picked.path);
    if (!mounted) return;
    messenger.hideCurrentSnackBar();
    if (frames.isEmpty) {
      // Kare çıkarılamadı: kip sessizce düşürülmez, klasik nota bağlanır ki
      // çekilen video kaybolmasın.
      showQuickAddSnack(l10n.videoFrameFailed);
      await _openBlankNote(
        NoteType.text,
        query: '?video=1',
        title: choice.noteTitle,
      );
      return;
    }
    await _buildPageNote(
      pageBytes: frames,
      fallbackName: l10n.docNameVideo,
      noteTitle: choice.noteTitle,
      extraVideoPath: picked.path,
    );
  }

  /// "Foto çek not al": fotoğraf makinesi açılır. Klasik kipte kare nota
  /// gömülür ve kullanıcı hemen yazmaya başlar; balonlu kipte kare bir belge
  /// sayfası olur ve üzerine balon/vurgu/kalem konabilir.
  Future<void> createPhotoNote() async {
    final choice = await _askCaptureMode(context.l10n.newPhotoNote);
    if (choice == null || !mounted) return;
    if (choice.mode == CaptureMode.classic) {
      await _openBlankNote(
        NoteType.text,
        query: '?photo=1',
        title: choice.noteTitle,
      );
      return;
    }
    final l10n = context.l10n;
    final perms = ref.read(permissionsServiceProvider);
    if (!await perms.cameraGranted() && !await perms.requestCamera()) {
      if (mounted) showQuickAddSnack(l10n.permCameraInfo);
      return;
    }
    if (!mounted) return;
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 2400,
      maxHeight: 2400,
    );
    if (picked == null || !mounted) return;
    // Fotoğraf da belgeye girmeden önce düzeltilir (madde 2'nin aynısı):
    // yamuk ya da yan çekilmiş bir kare, not kurulduktan sonra düzeltilemiyor.
    final prepared = await ImagePrepareScreen.open(context, [picked.path]);
    if (prepared == null || prepared.isEmpty || !mounted) return;
    await _buildPageNoteFromPaths(
      prepared,
      fallbackName: l10n.docNamePhoto,
      noteTitle: choice.noteTitle,
    );
  }

  /// "Belge tara not al": belge tarayıcı açılır (kenar tespiti + perspektif
  /// düzeltme).
  ///
  /// Klasik kipte tarama EDİTÖRDE yapılır ve sayfalar sıradan görsel/PDF eki
  /// olur. Balonlu kipte tarama burada yapılır ve sonuç doğrudan bir BELGE
  /// notudur: sayfa başına not, balon, vurgu ve kalem hazır gelir.
  Future<void> createScanNote() async {
    // Belge tarayıcı yoksa (masaüstü) balonlu kip kurulamaz: seçenek
    // sorulmaz, editördeki eski yol (fotoğraflardan tarama) açılır.
    final choice = DocumentScan.supported
        ? await _askCaptureMode(context.l10n.newScanNote)
        : const CaptureChoice(mode: CaptureMode.classic, noteTitle: '');
    if (choice == null || !mounted) return;
    if (choice.mode == CaptureMode.classic) {
      await _openBlankNote(
        NoteType.text,
        query: '?scan=1',
        title: choice.noteTitle,
      );
      return;
    }
    final l10n = context.l10n;
    final perms = ref.read(permissionsServiceProvider);
    if (!await perms.cameraGranted() && !await perms.requestCamera()) {
      if (mounted) showQuickAddSnack(l10n.permCameraInfo);
      return;
    }
    if (!mounted) return;
    List<String>? pages;
    try {
      pages = await DocumentScan.scanPages();
    } catch (e) {
      if (mounted) showQuickAddSnack(l10n.scanFailed('$e'));
      return;
    }
    if (pages == null || pages.isEmpty || !mounted) return;
    // İnceleme ekranı zaten kırpma/döndürme/filtre veriyor ve tek aranabilir
    // PDF üretebiliyor: balonlu kipin istediği belge tam olarak o.
    final result = await ScanReviewScreen.open(context, pages);
    if (result == null || !mounted) return;
    final pdfBytes = result.pdfBytes;
    if (pdfBytes != null) {
      await _createPageNoteWithPdf(
        pdfBytes,
        // `.pdf` uzantısı aşağıda ekleniyor; ad uzantısız verilir.
        fallbackName: p.basenameWithoutExtension(
          scanFileName(result.title, DateTime.now()),
        ),
        noteTitle: choice.noteTitle,
      );
      return;
    }
    final paths = result.imagePaths ?? const <String>[];
    if (paths.isEmpty) return;
    await _buildPageNoteFromPaths(
      paths,
      fallbackName: l10n.docNameScan,
      noteTitle: choice.noteTitle,
    );
  }

  /// "PDF ekle not al": dosya seçici gelir, seçilen belge notun içine gömülür.
  ///
  /// Balonlu kipte ekran ÜSTTE sayfa ALTTA o sayfanın notu olacak şekilde
  /// ikiye bölünür; klasik kipte PDF sıradan bir ek olur ve not düz metin
  /// notudur. Seçim iptal edilirse boş not çıkışta kendiliğinden silinir.
  Future<void> createPdfNote() async {
    final choice = await _askCaptureMode(context.l10n.newPdfNote);
    if (choice == null || !mounted) return;
    await _openBlankNote(
      choice.mode == CaptureMode.bubbles ? NoteType.pdf : NoteType.text,
      query: '?pdf=1',
      title: choice.noteTitle,
    );
  }

  /// "Görsel ekle not al": seçilen görseller TEK BELGEYE (PDF) dizilir ve
  /// PDF notunun aynısı açılır.
  ///
  /// Neden yeni bir not TİPİ değil (kullanıcı isteği 2026-08-08: "PDF not al
  /// modu güzel, aynı şekilde görsel notu modu yapalım"): görsel notunun
  /// istediği HER ŞEY — sayfa başına not, balon, vurgu, ok, el yazısı, sayfa
  /// ekle/sil, paylaşım, dışa aktarma — PDF notunda zaten var ve tek kopya
  /// hâlinde çalışıyor. Görseller belgeye çevrilince bunların hepsi bedava
  /// gelir; ayrı bir tip açmak aynı ekranların ikinci bir kopyasını
  /// (ve ikinci bir hata kaynağını) doğururdu.
  Future<void> createImageNote() async {
    final choice = await _askCaptureMode(context.l10n.newImageNote);
    if (choice == null || !mounted) return;
    final l10n = context.l10n;
    final group = XTypeGroup(
      label: context.l10n.exportImages,
      extensions: ['jpg', 'jpeg', 'png', 'webp'],
      mimeTypes: ['image/jpeg', 'image/png', 'image/webp'],
    );
    final files = await DocPicker.pickMany(group);
    if (files.isEmpty || !mounted) return;
    // Kırp/döndür ADIMI (kullanıcı isteği 2026-08-09): görseller belgeye
    // dizilmeden ya da nota eklenmeden önce burada düzeltilir.
    final prepared = await ImagePrepareScreen.open(context, [
      for (final f in files) f.path,
    ]);
    if (prepared == null || prepared.isEmpty || !mounted) return;
    if (choice.mode == CaptureMode.classic) {
      await _createImageAttachmentNote(prepared, choice.noteTitle);
      return;
    }
    await _buildPageNoteFromPaths(
      prepared,
      fallbackName: l10n.docNameImage,
      noteTitle: choice.noteTitle,
    );
  }

  /// "Sunum ekle not al": PDF yolunun slayt eşi.
  Future<void> createSlidesNote() async {
    final choice = await _askCaptureMode(context.l10n.newSlidesNote);
    if (choice == null || !mounted) return;
    await _openBlankNote(
      choice.mode == CaptureMode.bubbles ? NoteType.slides : NoteType.text,
      query: '?slides=1',
      title: choice.noteTitle,
    );
  }

  /// "Galeriden video": var olan bir videodan not. Video notun üstüne
  /// sabitlenir, not altında yazılır (bkz. editördeki `startGalleryVideo`).
  /// Seçim iptal edilirse boş not çıkışta kendiliğinden silinir.
  Future<void> createGalleryVideoNote() =>
      _openBlankNote(NoteType.text, query: '?gvideo=1');

  /// "YouTube videosu": bağlantı sorulur (panoda varsa hazır gelir), video
  /// notun üstüne sabitlenir ve izlerken altına not alınır.
  Future<void> createYouTubeNote() =>
      _openBlankNote(NoteType.text, query: '?youtube=1');

  /// İçerikten not alan seçeneklerin ortak ilk adımı: **balonlu mu klasik mi**
  /// (önizlemeli levha — bkz. `capture_mode_sheet.dart`).
  Future<CaptureChoice?> _askCaptureMode(String title) =>
      showCaptureModeSheet(context, title: title);

  /// Boş bir not kurup editörü [query] açılış niyetiyle açar (klasör süzgeci
  /// varsa nota da yazılır). Altı yakalama yolunun ortak kuyruğu.
  ///
  /// [title] yakalama levhasında yazılan addır (boş olabilir): klasik kipte
  /// de kullanılır, böylece "başlığı önce yaz" alışkanlığı iki kipte de aynı
  /// çalışır.
  Future<void> _openBlankNote(
    NoteType type, {
    String query = '',
    String title = '',
  }) async {
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;
    final id = await repo.createNote(
      type,
      folderId: quickAddFolderId,
    );
    if (title.isNotEmpty) repo.updateFields(id, {'title': title});
    await openNewNote(id, query: query);
  }

  /// Görselleri TEK BELGEYE dizip balonlu (sayfa notlu) bir not kurar.
  ///
  /// Belgenin adı [noteTitle]'dan gelir; boşsa [fallbackName] kullanılır
  /// (bkz. `capture_mode_sheet.dart` — dosya adı kök nedeni).
  Future<void> _buildPageNoteFromPaths(
    List<String> paths, {
    required String fallbackName,
    required String noteTitle,
  }) async {
    if (paths.isEmpty) return;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(SnackBar(content: Text(l10n.imageNotePreparing)));
    try {
      final bytes = await ScanPdf.build(paths);
      if (!mounted) return;
      messenger.hideCurrentSnackBar();
      await _createPageNoteWithPdf(
        bytes,
        fallbackName: fallbackName,
        noteTitle: noteTitle,
      );
    } catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.genericError('$e'))));
    }
  }

  /// Baytları belge sayfası olarak taşıyan PDF notunu kurar.
  Future<void> _buildPageNote({
    required List<Uint8List> pageBytes,
    required String fallbackName,
    required String noteTitle,
    String? extraVideoPath,
  }) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(SnackBar(content: Text(l10n.imageNotePreparing)));
    try {
      // ScanPdf yol bekliyor: baytlar geçici dosyaya yazılır ve iş bitince
      // silinir (önbellekte kalıcı kopya bırakma).
      final dir = await getTemporaryDirectory();
      final paths = <String>[];
      for (var i = 0; i < pageBytes.length; i++) {
        final file = File(
          p.join(
            dir.path,
            'kare_${DateTime.now().microsecondsSinceEpoch}$i.jpg',
          ),
        );
        await file.writeAsBytes(pageBytes[i]);
        paths.add(file.path);
      }
      final bytes = await ScanPdf.build(paths);
      for (final path in paths) {
        File(path).delete().ignore();
      }
      if (!mounted) return;
      messenger.hideCurrentSnackBar();
      await _createPageNoteWithPdf(
        bytes,
        fallbackName: fallbackName,
        noteTitle: noteTitle,
        extraVideoPath: extraVideoPath,
      );
    } catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.genericError('$e'))));
    }
  }

  /// PDF baytlarından balonlu not: tek yazımda tip + klasör + ek.
  ///
  /// Neden yeni bir not TİPİ değil (kullanıcı isteği 2026-08-08: "PDF not al
  /// modu güzel, aynı şekilde görsel notu modu yapalım"): balonlu kipin
  /// istediği HER ŞEY — sayfa başına not, balon, vurgu, ok, el yazısı, sayfa
  /// ekle/sil, paylaşım, dışa aktarma — PDF notunda zaten var ve tek kopya
  /// hâlinde çalışıyor. Görüntüler belgeye çevrilince bunların hepsi bedava
  /// gelir; ayrı bir tip açmak aynı ekranların ikinci bir kopyasını (ve ikinci
  /// bir hata kaynağını) doğururdu.
  Future<void> _createPageNoteWithPdf(
    Uint8List pdfBytes, {
    required String fallbackName,
    required String noteTitle,
    String? extraVideoPath,
  }) async {
    final repo = ref.read(notesRepositoryProvider);
    final attachments = ref.read(attachmentRepositoryProvider);
    if (repo == null || attachments == null) return;
    final l10n = context.l10n;
    try {
      final id = await repo.createNote(
        NoteType.pdf,
        folderId: quickAddFolderId,
      );
      final maps = <Map<String, dynamic>>[];
      // Belgenin adı NOTUN BAŞLIĞI (bkz. capture_mode_sheet.dart). Başlık
      // boşsa YAKALAMA KİPİNİN MENÜ ETİKETİ değil, kısa bir BELGE adı
      // kullanılır (kullanıcı bulgusu 2026-08-18: belgeler "PDF ekle not al",
      // "Görsel ekle not al" diye adlanıyordu — bkz. [documentBaseName]).
      final attachment = await attachments.preparePdf(
        noteId: id,
        bytes: pdfBytes,
        fileName: '${safePdfBaseName(noteTitle) ?? fallbackName}.pdf',
      );
      maps.add(attachment.toMap());
      // Görüntülü notta kaydın kendisi de nota bağlanır: sayfa yalnız kapak
      // karesi, asıl içerik video.
      if (extraVideoPath != null) {
        final video = await attachments.prepareVideo(
          noteId: id,
          sourcePath: extraVideoPath,
          duration: Duration.zero,
        );
        maps.add(video.copyWith(asFile: true).toMap());
      }
      repo.updateFields(id, {
        'attachments': FieldValue.arrayUnion(maps),
        if (noteTitle.isNotEmpty) 'title': noteTitle,
      });
      if (!mounted) return;
      await openNewNote(id);
    } catch (e) {
      if (mounted) showQuickAddSnack(l10n.genericError('$e'));
    }
  }

  /// Klasik görsel notu: seçilen görseller sıradan ek olarak nota girer.
  Future<void> _createImageAttachmentNote(
    List<String> paths,
    String noteTitle,
  ) async {
    final repo = ref.read(notesRepositoryProvider);
    final attachments = ref.read(attachmentRepositoryProvider);
    if (repo == null || attachments == null) return;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(SnackBar(content: Text(l10n.imageNotePreparing)));
    try {
      final id = await repo.createNote(
        NoteType.text,
        folderId: quickAddFolderId,
      );
      // Görseller SAYFAYA yerleşir, ek şeridine değil (kullanıcı isteği
      // 2026-08-09: "görsel eklendiğinde direk ekrana"). Konum burada
      // veriliyor: alansız bırakılan ekler sayfanın aynı noktasında üst üste
      // biniyordu. Genişlik ekrandan tahmin edilir — düzen oranlı olduğu için
      // gerçek sayfa biraz farklı olsa da sıralama korunur.
      const pageWidth = 360.0;
      const displayWidth = 0.86;
      var top = 96.0;
      final maps = <Map<String, dynamic>>[];
      for (final path in paths) {
        final attachment = await attachments.prepareImage(
          noteId: id,
          bytes: await File(path).readAsBytes(),
          fileName: p.basename(path),
        );
        maps.add(
          attachment
              .copyWith(x: 0.06, pageY: top, displayWidth: displayWidth)
              .toMap(),
        );
        final aspect =
            (attachment.width != null &&
                attachment.height != null &&
                attachment.height! > 0)
            ? attachment.width! / attachment.height!
            : 1.0;
        top += pageWidth * displayWidth / aspect + 16;
      }
      repo.updateFields(id, {
        'attachments': FieldValue.arrayUnion(maps),
        if (noteTitle.isNotEmpty) 'title': noteTitle,
      });
      if (!mounted) return;
      messenger.hideCurrentSnackBar();
      await openNewNote(id);
    } catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.genericError('$e'))));
    }
  }

  /// QR kod okur ve içeriğini yeni bir nota yazar. Not tarama BAŞARILI olunca
  /// oluşturulur — iptal edilirse ortada boş not kalmaz.
  Future<void> createQrNote() async {
    final l10n = context.l10n;
    final perms = ref.read(permissionsServiceProvider);
    if (!await perms.cameraGranted() && !await perms.requestCamera()) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.permCameraInfo)));
      }
      return;
    }
    if (!mounted) return;
    final code = await openQrScanner(context);
    if (code == null || !mounted) return;
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;
    final id = await repo.createNote(NoteType.text);
    final folderId = quickAddFolderId;
    repo.updateFields(id, {
      'body': code,
      // Null-aware eleman: klasör süzgeci yoksa anahtar hiç yazılmaz.
      'folderId': ?folderId,
    });
    await openNewNote(id);
  }
}
