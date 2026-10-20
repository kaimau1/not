import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:uuid/uuid.dart';

import '../../../app/router.dart';
import '../../../core/error_log.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/utils/youtube.dart';
import '../../folders/data/folders_repository.dart';
import '../../folders/domain/note_folder.dart';
import '../presentation/capture_mode_sheet.dart';
import '../presentation/notes_providers.dart';
import '../presentation/share_target_sheet.dart';
import '../domain/attachment.dart';
import '../domain/note.dart';
import '../domain/note_item.dart';
import '../domain/note_type.dart';
import 'attachment_repository.dart';
import 'note_package.dart';
import 'note_share.dart';
import 'notes_repository.dart';
import 'pdf_edit.dart';
import 'video_frame.dart';
import 'web_video.dart';

/// Paylaş menüsünden gelen içerikleri nota çevirir: başka bir uygulamada
/// Paylaşılan dosyanın hangi ek türü olduğunu söyler; `null` ise dosya değil
/// metindir ve notun gövdesine yazılır.
///
/// Karar MIME'a göre verilir, uzantıya göre DEĞİL: eklenti dosyayı cihaza
/// kopyalarken adı sağlayıcının `_display_name` sütunundan alıyor ve bu ad
/// Drive/Gmail gibi kaynaklarda uzantısız gelebiliyor. Uzantıya bakan sürüm o
/// dosyaları sessizce atlıyordu — paylaşım hiç not oluşturmuyor, yalnızca
/// uygulama açılıyordu. Uzantı yalnızca MIME boşsa yedek ölçüt.
AttachmentKind? shareAttachmentKind(SharedMediaFile f) {
  final mime = (f.mimeType ?? '').toLowerCase();
  final ext = p.extension(f.path).toLowerCase();
  if (mime == 'application/pdf' || ext == '.pdf') return AttachmentKind.pdf;
  if (mime.contains('presentationml') || ext == '.pptx') {
    return AttachmentKind.slide;
  }
  if (mime.startsWith('image/') || f.type == SharedMediaType.image) {
    return AttachmentKind.image;
  }
  // Galeriden/kameradan paylaşılan video (kullanıcı isteği 2026-10-11:
  // "video paylaş seçeneklerinde çıkmamız lazım" — manifestte video/*).
  if (mime.startsWith('video/') || f.type == SharedMediaType.video) {
    return AttachmentKind.video;
  }
  // SES DOSYASI (kullanıcı isteği 2026-10-17: "sonradan eklenmiş ses
  // dosyalarının transkripti"): sohbet uygulamasının sesli mesajı ya da
  // ses kaydedicinin dosyası. Eklenti sesi `file` türüyle verir; MIME yoksa
  // uzantı yedek ölçüt.
  if (mime.startsWith('audio/') || _audioExtensions.contains(ext)) {
    return AttachmentKind.audio;
  }
  return null;
}

const _audioExtensions = {
  '.mp3', '.m4a', '.aac', '.wav', '.ogg', '.oga', '.opus', '.flac', '.amr',
};

/// "Paylaş → Notlar" denince metin/link ve .txt/.md dosyaları gövde olur,
/// görsel/PDF/sunum ek olarak yüklenir ve editör açılır. Dashboard bu
/// provider'ı ayakta tutar.
final shareIntakeProvider = Provider<void>((ref) {
  if (kIsWeb || !Platform.isAndroid) return;

  Future<void> handle(List<SharedMediaFile> files) async {
    if (files.isEmpty) return;
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;

    // receive_sharing_intent yalnız SEND'i değil ACTION_VIEW'ı da yakalıyor:
    // widget/kısayol "notlar://voice" ile uygulamayı açtığında bu bağlantı
    // paylaşılan bir URL sanılıp gövdesi "notlar://voice" olan çöp not
    // oluşturuluyordu. Kendi şemamız paylaşım değil, derin bağlantıdır —
    // router zaten işliyor (notlar://new kısayolları da bu yüzden korunur).
    // Dosya paylaşımı türe göre ayrılır: düz metin GÖVDEYE yazılır (ek olarak
    // eklenseydi içeriği notta görünmezdi), PDF/sunum eke gider.
    //
    // Diskten YALNIZ eklentinin kopyaladığı önbellek dizini okunur: paylaşım
    // "yolu" aslında gönderen uygulamanın kontrolündeki bir metin. Kötü
    // niyetli bir uygulama text/plain ile kendi seçtiği bir yol gönderirse
    // (ör. bu uygulamanın secure storage XML'i) içerik nota okunup buluta
    // senkronlanırdı. receive_sharing_intent gerçek dosya paylaşımlarını her
    // zaman önce kendi önbelleğine kopyalar; onun dışındaki her yol metindir.
    final cachePath = (await getTemporaryDirectory()).path;
    bool safeToRead(String path) {
      try {
        return p.isWithin(cachePath, path);
      } catch (_) {
        return false;
      }
    }

    // NOT PAKETİ (.notpaket) önce denenir: başka bir Not kullanıcısının
    // gönderdiği dosya ham bir ek değil, notun KENDİSİdir — ekleri, sayfa
    // notları, çizimleri, balonları ve görünümüyle birlikte açılır.
    // Eşleşirse buradan çıkılır; aynı dosya ayrıca eke çevrilmemeli.
    for (final f in files) {
      if (!f.path.toLowerCase().endsWith(NotePackage.fileExtension)) continue;
      if (!safeToRead(f.path)) continue;
      try {
        final package = readNotePackage(await File(f.path).readAsBytes());
        final noteId = await NoteShare.import(
          package,
          notes: repo,
          attachments: ref.read(attachmentRepositoryProvider),
        );
        unawaited(ReceiveSharingIntent.instance.reset());
        try {
          unawaited(ref.read(routerProvider).pushNote(noteRoutePath(noteId)));
        } catch (e) {
          ErrorLog.record('share-intake-open', e);
        }
        return;
      } catch (_) {
        // Bozuk ya da bize ait olmayan bir .notpaket: aşağıdaki normal
        // paylaşım yolu devam etsin (dosya yine de bir ek olabilir).
      }
    }

    final bodyParts = <String>[];
    final docs = <SharedMediaFile>[];
    for (final f in files) {
      // receive_sharing_intent yalnız SEND'i değil ACTION_VIEW'ı da yakalıyor:
      // widget/kısayol "notlar://voice" ile uygulamayı açtığında bu bağlantı
      // paylaşılan bir URL sanılıp gövdesi "notlar://voice" olan çöp not
      // oluşturuluyordu. Kendi şemamız paylaşım değil, derin bağlantıdır —
      // router zaten işliyor (notlar://new kısayolları da bu yüzden korunur).
      if (f.path.trimLeft().startsWith('notlar://')) continue;
      if (shareAttachmentKind(f) != null) {
        docs.add(f);
        continue;
      }
      // Arşiv dosyası (paket filtresi yüzünden buraya kadar gelen ama not
      // paketi ÇIKMAYAN bir zip) metin sayılmaz: ikili baytları gövdeye
      // yazmak okunamaz bir çöp not üretirdi.
      final lower = f.path.toLowerCase();
      if (lower.endsWith('.zip') ||
          lower.endsWith(NotePackage.fileExtension)) {
        continue;
      }
      // Metin girdisi iki şey olabilir: paylaşılan yazının KENDİSİ ya da bir
      // .txt dosyasının YOLU — eklenti ikisini de aynı alanda veriyor.
      // Önbellekteyse (yani gerçekten eklentinin kopyaladığı bir dosyaysa)
      // içeriği okunur, değilse metnin kendisidir.
      try {
        final file = File(f.path);
        // readAsString DEĞİL: UTF-8 olmayan bir .txt (Windows-1254/ANSI
        // Türkçe'de hâlâ yaygın) FormatException atıyor ve paylaşım tek
        // içerikse not hiç oluşmuyordu. allowMalformed geçersiz baytları
        // U+FFFD ile değiştirir — metnin okunur kısmı kurtulur.
        bodyParts.add(
          safeToRead(f.path) && file.existsSync()
              ? utf8.decode(await file.readAsBytes(), allowMalformed: true)
              : f.path,
        );
      } catch (_) {
        // Okunamayan dosya notu engellemesin.
      }
    }
    if (bodyParts.isEmpty && docs.isEmpty) {
      // İşlenmeyen içerik eklentide asılı kalmasın: reset edilmezse uygulama
      // tekrar öne gelince aynı çöp girdi yeniden değerlendiriliyordu.
      unawaited(ReceiveSharingIntent.instance.reset());
      return;
    }

    // Gövde TEK yazımda: createNote + ayrı updateFields arasında doküman bir
    // an boş kalıyor ve o anki akış anlık görüntüsünde not süzgeçten
    // düşebiliyordu (bkz. NotesRepository.createNote yorumu).
    var body = bodyParts.join('\n').trim();
    // YOUTUBE paylaşımı (YouTube uygulaması bağlantıyı METİN olarak
    // paylaşır): bağlantı oynatılabilir bir video ekine dönüşür. Metin
    // yalnız bağlantıdan ibaretse gövdeye yazılmaz — kart zaten onu taşır.
    final youTubeUrl = firstYouTubeUrl(body);
    if (youTubeUrl != null && body.replaceFirst(youTubeUrl, '').trim().isEmpty) {
      body = '';
    }
    // BELGE paylaşımında (PDF/sunum) YENİ not kipi SORULUR — uygulama içindeki
    // "PDF ekle not al" akışının aynı kartları (kullanıcı isteği 2026-09-05).
    final docKind = body.isEmpty && docs.isNotEmpty
        ? shareAttachmentKind(docs.first)
        : null;
    final asksMode =
        docKind == AttachmentKind.pdf || docKind == AttachmentKind.slide;

    // **HEDEF SORULUR: YENİ NOT MU, VAR OLAN NOT MU?** (kullanıcı isteği
    // 2026-09-29: "PDF açmak istediğimde Notlar ana sayfası açılıp ister eski
    // bir notuma ekleme istersem yeni not oluşturma seçenekleri gelsin").
    // Önce ANA SAYFA: paylaşım hangi ekrandayken gelirse gelsin kullanıcı
    // notlarının önünde karar verir. Levha uygulamanın gezinme ağacında
    // açılır; gezgin henüz yoksa (çok erken soğuk başlatma) soru sorulmaz ve
    // eski varsayılan davranış işler (yeni not).
    final router = ref.read(routerProvider);
    await _showHome(router);
    final sheetContext = router.routerDelegate.navigatorKey.currentContext;
    ShareDestination? destination;
    if (sheetContext != null && sheetContext.mounted) {
      // Soğuk başlatmada notlar henüz gelmemiş olabilir: "var olan not"
      // listesi boş açılmasın diye ilk anlık görüntü kısa süre beklenir.
      try {
        await ref
            .read(notesStreamProvider.future)
            .timeout(const Duration(seconds: 3));
      } catch (_) {
        // Gelmezse liste eldekiyle açılır; yeni not yolu etkilenmez.
      }
      if (!sheetContext.mounted) return;
      final folders =
          ref.read(foldersStreamProvider).value ?? const <NoteFolder>[];
      final suppressed = ref.read(suppressedFolderIdsProvider);
      final notes = [
        for (final n in ref.read(notesStreamProvider).value ?? const <Note>[])
          if (n.folderId == null || !suppressed.contains(n.folderId)) n,
      ];
      destination = await showShareTargetSheet(
        sheetContext,
        incoming: ShareIncoming(
          text: body,
          files: [
            for (final f in docs)
              (name: p.basename(f.path), kind: shareAttachmentKind(f)!),
            if (youTubeUrl != null)
              (name: 'YouTube', kind: AttachmentKind.video),
          ],
        ),
        notes: notes,
        folderNames: {for (final f in folders) f.id: f.name},
        askMode: asksMode,
        newNoteLabel: !asksMode
            ? null
            : docKind == AttachmentKind.slide
            ? sheetContext.l10n.newSlidesNote
            : sheetContext.l10n.newPdfNote,
      );
      // Levha kapatıldı: paylaşımdan not oluşturulmaz (boş not bırakmayalım).
      if (destination == null) {
        unawaited(ReceiveSharingIntent.instance.reset());
        return;
      }
    }

    final targetId = destination?.noteId;
    if (targetId != null) {
      await _addToExistingNote(
        ref,
        repo,
        targetId,
        body,
        docs,
        safeToRead,
        youTubeUrl: youTubeUrl,
      );
      unawaited(ReceiveSharingIntent.instance.reset());
      return;
    }

    final choice = destination?.choice;
    // Balonlu kip: editör üstte sayfa, altta o sayfanın notu olacak şekilde
    // açılır ve belgenin üzerine balon bırakılabilir. Klasik kipte belge
    // sıradan bir ek olur (kullanıcı isteği 2026-08-08: "notlarda açıp aynı
    // şekilde düzenlemeye devam edebilmek").
    final docType = docKind == AttachmentKind.slide
        ? NoteType.slides
        : NoteType.pdf;
    final type = choice != null
        ? (asksMode && choice.mode == CaptureMode.bubbles
              ? docType
              : NoteType.text)
        // Soru sorulamadı (gezgin yok): tek belge yine belge notu açar.
        : (body.isEmpty && docs.length == 1
              ? switch (shareAttachmentKind(docs.first)) {
                  AttachmentKind.pdf => NoteType.pdf,
                  AttachmentKind.slide => NoteType.slides,
                  _ => NoteType.text,
                }
              : NoteType.text);
    // Levhada yazılan ad hem notun başlığı hem de balonlu kipte üretilen
    // belgenin dosya adı olur (bkz. capture_mode_sheet.dart). TEK yazımda.
    final id = await repo.createNote(
      type,
      body: body,
      title: choice?.noteTitle ?? '',
    );

    final prepared = await _prepareAttachments(
      ref,
      noteId: id,
      noteType: type,
      docs: docs,
      safeToRead: safeToRead,
      youTubeUrl: youTubeUrl,
    );
    if (prepared.isNotEmpty) {
      // Zaman aşımı ŞART: dönen Future sunucu onayını bekliyor ve
      // çevrimdışıyken hiç tamamlanmıyor. Yazım o durumda da yerel
      // önbelleğe ANINDA düşmüştür — beklediğimiz tek şey editör açılmadan
      // önce o düşüşün gerçekleşmesi.
      await repo
          .updateFieldsAndWait(id, {
            'attachments': FieldValue.arrayUnion([
              for (final a in prepared) a.toMap(),
            ]),
          })
          .timeout(const Duration(seconds: 3), onTimeout: () {})
          .catchError((Object _) {});
    }

    // Aynı içerik uygulama tekrar öne gelince yeniden işlenmesin.
    unawaited(ReceiveSharingIntent.instance.reset());
    try {
      unawaited(router.pushNote(noteRoutePath(id)));
    } catch (e) {
      ErrorLog.record('share-intake-open', e);
    }
  }

  // Uygulama paylaşımla soğuk başlatıldıysa ilk içerik; açıkken gelenler
  // için akış dinlenir.
  ReceiveSharingIntent.instance
      .getInitialMedia()
      .then(handle)
      .catchError((Object _) {});
  final sub = ReceiveSharingIntent.instance.getMediaStream().listen(
    handle,
    onError: (Object _) {},
  );
  ref.onDispose(sub.cancel);
});

/// Paylaşım gelince ANA SAYFA açılır (kullanıcı isteği 2026-09-29). Zaten
/// oradaysak bir şey yapılmaz; değilsek geçiş animasyonu bitene dek beklenir
/// — levha kapanan editörün üstünde açılıp onunla birlikte gitmesin.
Future<void> _showHome(GoRouter router) async {
  try {
    final path = router.routerDelegate.currentConfiguration.uri.path;
    if (path == '/' || path.isEmpty || path == '/login') return;
    router.go('/');
    await Future<void>.delayed(const Duration(milliseconds: 380));
  } catch (_) {
    // Yönlendirici hazır değilse levha yine bulunduğu yerde açılır.
  }
}

/// Paylaşılan dosyaları eke çevirir (yükleme kuyruğuna hazır). Hem yeni not
/// hem VAR OLAN not yolu kullanır — dosyanın nota nasıl oturduğu aynı kalsın.
Future<List<Attachment>> _prepareAttachments(
  Ref ref, {
  required String noteId,
  required NoteType noteType,
  required List<SharedMediaFile> docs,
  required bool Function(String path) safeToRead,
  String? youTubeUrl,
}) async {
  final attachRepo = ref.read(attachmentRepositoryProvider);
  if (attachRepo == null) return const [];
  final webVideo = youTubeUrl == null ? null : webVideoAttachment(youTubeUrl);
  // Hazırlanan ekler ÖNCE toplanır, sonra TEK yazımda gider.
  //
  // KÖK NEDEN (kullanıcı 2026-08-16: "3 resim gönderdim 2'si geldi"):
  // eskiden döngünün her turunda ayrı bir `updateFields` (arrayUnion)
  // ateşleniyordu ve HİÇBİRİ beklenmiyordu. Son yazım daha yoldayken
  // editör açılıyor, editör de kendi anlık görüntüsünü (henüz 2 ekli) geri
  // yazınca son ek siliniyordu. Tek arrayUnion'da böyle bir aralık yok.
  final prepared = <Attachment>[];
  if (webVideo != null) {
    // Başlık beklenir ama kısa (4 sn tavan): gelmezse "YouTube" kalır.
    final title = await fetchYouTubeTitle(webVideo.webUrl);
    prepared.add(
      title == null
          ? webVideo.copyWith(displayWidth: 0.6)
          : webVideo.copyWith(fileName: title, displayWidth: 0.6),
    );
  }
  for (final file in docs) {
    try {
      // Ek dosyaları da aynı kurala tabi: önbellek dışındaki bir yolu
      // (sahte MIME ile işaretlenmiş keyfi bir dosyayı) eke çevirme.
      if (!safeToRead(file.path)) continue;
      final kind = shareAttachmentKind(file)!;
      // VİDEO baytları belleğe OKUNMAZ (yüzlerce MB olabilir): dosya
      // eklentinin önbelleğinden doğrudan uygulamanın ek klasörüne kopyalanır.
      // Cihazda kalır, buluta gitmez (bkz. prepareVideo).
      if (kind == AttachmentKind.video) {
        prepared.add(
          await attachRepo.prepareVideo(
            noteId: noteId,
            sourcePath: file.path,
            duration: await VideoFrame.duration(file.path),
          ),
        );
        continue;
      }
      // Ses de belleğe okunmadan kopyalanır; adı ve türü korunur.
      if (kind == AttachmentKind.audio) {
        prepared.add(
          await attachRepo.prepareAudioFile(
            noteId: noteId,
            sourcePath: file.path,
            fileName: p.basename(file.path),
          ),
        );
        continue;
      }
      final bytes = await File(file.path).readAsBytes();
      var name = p.basename(file.path);
      // Ad uzantısız geldiyse (bkz. shareAttachmentKind) türün uzantısı
      // eklenir; yoksa ek uzantısız kaydedilir ve dışa aktarılınca açılmaz.
      if (p.extension(name).isEmpty) {
        name += switch (kind) {
          AttachmentKind.pdf => '.pdf',
          AttachmentKind.slide => '.pptx',
          _ => '.jpg',
        };
      }
      // NOTLAR'IN ÜRETTİĞİ PAYLAŞIM PDF'i: balon/çizim verisi dosyanın
      // içinde ek olarak geliyor. Damga katmanı sökülür ve veriler ekin
      // kendi alanlarına konur — balonlar gönderendeki gibi taşınabilir,
      // renklenebilir, silinebilir olur. Sıradan bir PDF'te `restored`
      // null döner ve dosya olduğu gibi eklenir.
      final restored = kind == AttachmentKind.pdf
          ? await PdfEdit.readSharedPdfInBackground(bytes)
          : null;
      final docBytes = restored == null
          ? bytes
          : restored['bytes'] as Uint8List;
      final attachment = switch (kind) {
        AttachmentKind.pdf => await attachRepo.preparePdf(
          noteId: noteId,
          bytes: docBytes,
          fileName: name,
        ),
        AttachmentKind.slide => await attachRepo.prepareSlide(
          noteId: noteId,
          bytes: bytes,
          fileName: name,
        ),
        _ => await attachRepo.prepareImage(
          noteId: noteId,
          bytes: bytes,
          fileName: name,
        ),
      };
      // Balonlar/çizimler ekin alanlarına: not artık gönderendeki gibi
      // düzenlenebilir (bkz. yukarıdaki `restored`).
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
      // KLASİK metin notunda PDF de SAYFAYA yerleşir (kullanıcı isteği
      // 2026-09-06): uygulama içinden eklenen PDF ile paylaşımdan gelen
      // PDF aynı yere düşsün. Konum yazılmaz — tuval sayfa genişliğini
      // bildiği ilk karede boş bir yere kendisi oturtur (bkz. packSlot).
      // Belge (balonlu) notunda PDF notun KENDİSİdir; oraya konmaz.
      prepared.add(
        kind == AttachmentKind.pdf && noteType == NoteType.text
            ? stored.copyWith(onPage: true)
            : stored,
      );
    } catch (_) {
      // Tek dosya okunamazsa/çok büyükse not yine oluşsun.
    }
  }
  return prepared;
}

/// Paylaşılanı VAR OLAN nota ekler ve notu açar.
///
/// * Dosyalar notun eklerine KATILIR (var olanlara dokunulmaz; bulutta
///   arrayUnion, yerel notta listenin sonu — bkz. `appendAttachments`).
/// * Metin, notun türüne göre oturur: liste notunda her satır YENİ MADDE,
///   arşiv defterinde yeni bir metin girdisi, diğerlerinde gövdenin sonuna
///   yeni paragraf.
Future<void> _addToExistingNote(
  Ref ref,
  NotesRepository repo,
  String noteId,
  String body,
  List<SharedMediaFile> docs,
  bool Function(String path) safeToRead, {
  String? youTubeUrl,
}) async {
  final notes = ref.read(notesStreamProvider).value ?? const <Note>[];
  Note? target;
  for (final n in notes) {
    if (n.id == noteId) target = n;
  }
  if (target == null) return;

  if (body.isNotEmpty) {
    final fields = appendSharedText(target, body, newId: _uuid.v4);
    if (fields.isNotEmpty) {
      await repo
          .updateFieldsAndWait(noteId, fields)
          .timeout(const Duration(seconds: 3), onTimeout: () {})
          .catchError((Object _) {});
    }
  }

  final prepared = await _prepareAttachments(
    ref,
    noteId: noteId,
    noteType: target.type,
    docs: docs,
    safeToRead: safeToRead,
    youTubeUrl: youTubeUrl,
  );
  if (prepared.isNotEmpty) {
    await repo
        .appendAttachments(noteId, prepared)
        .timeout(const Duration(seconds: 3), onTimeout: () {})
        .catchError((Object _) {});
  }

  try {
    unawaited(ref.read(routerProvider).pushNote(noteRoutePath(noteId)));
  } catch (e) {
    ErrorLog.record('share-intake-open', e);
  }
}

const _uuid = Uuid();

/// Paylaşılan METNİN var olan nota nasıl yazılacağı (saf, testli): yazılacak
/// alanlar döner.
///
/// * Liste (madde / sıralı) notunda her dolu satır yeni madde olur; sondaki
///   BOŞ maddeler (yeni listenin boş satırı) atlanır ki yeni maddeler boşluğun
///   altına düşmesin.
/// * Arşiv defterinde metin, "Metinler" sayfasına yeni bir girdi.
/// * Diğerlerinde gövdenin sonuna, bir boş satırla ayrılmış paragraf.
Map<String, Object> appendSharedText(
  Note note,
  String text, {
  required String Function() newId,
}) {
  final clean = text.trim();
  if (clean.isEmpty) return const {};
  switch (note.type) {
    case NoteType.checklist:
    case NoteType.ordered:
      final items = [...note.items];
      while (items.isNotEmpty &&
          items.last.text.trim().isEmpty &&
          !items.last.checked) {
        items.removeLast();
      }
      for (final line in clean.split('\n')) {
        final t = line.trim();
        if (t.isEmpty) continue;
        items.add(NoteItem(id: newId(), text: t));
      }
      return {
        'items': [for (final i in items) i.toMap()],
      };
    case NoteType.archive:
      return {
        'items': [
          for (final i in note.items) i.toMap(),
          NoteItem(id: newId(), text: clean).toMap(),
        ],
      };
    case NoteType.text:
    case NoteType.pdf:
    case NoteType.slides:
      final current = note.body.trimRight();
      return {'body': current.isEmpty ? clean : '$current\n\n$clean'};
  }
}
