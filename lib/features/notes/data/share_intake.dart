import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../../../app/router.dart';
import '../../../core/l10n_ext.dart';
import '../presentation/capture_mode_sheet.dart';
import '../domain/attachment.dart';
import '../domain/note_type.dart';
import 'attachment_repository.dart';
import 'note_package.dart';
import 'note_share.dart';
import 'notes_repository.dart';
import 'pdf_edit.dart';

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
  return null;
}

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
        ReceiveSharingIntent.instance.reset();
        try {
          ref.read(routerProvider).push(noteRoutePath(noteId));
        } catch (_) {}
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
      ReceiveSharingIntent.instance.reset();
      return;
    }

    // Gövde TEK yazımda: createNote + ayrı updateFields arasında doküman bir
    // an boş kalıyor ve o anki akış anlık görüntüsünde not süzgeçten
    // düşebiliyordu (bkz. NotesRepository.createNote yorumu).
    final body = bodyParts.join('\n').trim();
    // BELGE paylaşımında (PDF/sunum) not kipi SORULUR — uygulama içindeki
    // "PDF ekle not al" akışının aynı levhası (kullanıcı isteği 2026-09-05:
    // "seçenek olarak açılıp ya PDF ekle not al ile ya da direkt ek olarak
    // ekle seçeneği ile not başlatabilmeli"). Eskiden karar sessizce
    // veriliyordu: tek belge her zaman balonlu belge notu, birden çok belge
    // her zaman düz metin notu — kullanıcının söz hakkı yoktu.
    final docKind = body.isEmpty && docs.isNotEmpty
        ? shareAttachmentKind(docs.first)
        : null;
    final asksMode =
        docKind == AttachmentKind.pdf || docKind == AttachmentKind.slide;
    // Levha uygulamanın gezinme ağacında açılır. Paylaşımla SOĞUK başlatmada
    // gezgin henüz kurulmamış olabilir; o zaman soru sorulmaz ve eski
    // varsayılan davranış işler.
    final sheetContext = asksMode
        ? ref.read(routerProvider).routerDelegate.navigatorKey.currentContext
        : null;
    CaptureChoice? choice;
    if (sheetContext != null && sheetContext.mounted) {
      choice = await showCaptureModeSheet(
        sheetContext,
        title: docKind == AttachmentKind.slide
            ? sheetContext.l10n.newSlidesNote
            : sheetContext.l10n.newPdfNote,
      );
      // Levha kapatıldı: paylaşımdan not oluşturulmaz (boş not bırakmayalım).
      if (choice == null) {
        ReceiveSharingIntent.instance.reset();
        return;
      }
    }
    // Balonlu kip: editör üstte sayfa, altta o sayfanın notu olacak şekilde
    // açılır ve belgenin üzerine balon bırakılabilir. Klasik kipte belge
    // sıradan bir ek olur (kullanıcı isteği 2026-08-08: "notlarda açıp aynı
    // şekilde düzenlemeye devam edebilmek").
    final docType = docKind == AttachmentKind.slide
        ? NoteType.slides
        : NoteType.pdf;
    final type = choice != null
        ? (choice.mode == CaptureMode.bubbles ? docType : NoteType.text)
        // Soru sorulamadı (gezgin yok): tek belge yine belge notu açar.
        : (body.isEmpty && docs.length == 1
              ? switch (shareAttachmentKind(docs.first)) {
                  AttachmentKind.pdf => NoteType.pdf,
                  AttachmentKind.slide => NoteType.slides,
                  _ => NoteType.text,
                }
              : NoteType.text);
    final id = await repo.createNote(type, body: body);
    // Levhada yazılan ad hem notun başlığı hem de balonlu kipte üretilen
    // belgenin dosya adı olur (bkz. capture_mode_sheet.dart).
    final noteTitle = choice?.noteTitle ?? '';
    if (noteTitle.isNotEmpty) repo.updateFields(id, {'title': noteTitle});

    final attachRepo = ref.read(attachmentRepositoryProvider);
    if (attachRepo != null) {
      // Hazırlanan ekler ÖNCE toplanır, sonra TEK yazımda gider.
      //
      // KÖK NEDEN (kullanıcı 2026-08-16: "3 resim gönderdim 2'si geldi"):
      // eskiden döngünün her turunda ayrı bir `updateFields` (arrayUnion)
      // ateşleniyordu ve HİÇBİRİ beklenmiyordu. Son yazım daha yoldayken
      // aşağıdaki `push` editörü açıyor, editör de kendi anlık görüntüsünü
      // (henüz 2 ekli) geri yazınca son ek siliniyordu. Tek arrayUnion'da
      // böyle bir aralık yok; ayrıca `await` ile editör açılmadan önce
      // yazımın gittiği garanti.
      final prepared = <Attachment>[];
      for (final file in docs) {
        try {
          // Ek dosyaları da aynı kurala tabi: önbellek dışındaki bir yolu
          // (sahte MIME ile işaretlenmiş keyfi bir dosyayı) eke çevirme.
          if (!safeToRead(file.path)) continue;
          final bytes = await File(file.path).readAsBytes();
          final kind = shareAttachmentKind(file)!;
          var name = p.basename(file.path);
          // Ad uzantısız geldiyse (bkz. kindOf) türün uzantısı eklenir; yoksa
          // ek uzantısız kaydedilir ve dışa aktarıldığında açılmaz.
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
              noteId: id,
              bytes: docBytes,
              fileName: name,
            ),
            AttachmentKind.slide => await attachRepo.prepareSlide(
              noteId: id,
              bytes: bytes,
              fileName: name,
            ),
            _ => await attachRepo.prepareImage(
              noteId: id,
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
          prepared.add(stored);
        } catch (_) {
          // Tek dosya okunamazsa/çok büyükse not yine oluşsun.
        }
      }
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
    }

    // Aynı içerik uygulama tekrar öne gelince yeniden işlenmesin.
    ReceiveSharingIntent.instance.reset();
    try {
      ref.read(routerProvider).push(noteRoutePath(id));
    } catch (_) {}
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
