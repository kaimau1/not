import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/rich_text.dart';
import 'archive_paper.dart';
import 'attachment.dart';
import 'note_item.dart';
import 'note_type.dart';
import 'page_notes.dart';

/// Renk belirteci — tema tarafında gerçek renklere çözülür.
/// Notun zemin rengi. Sıra ve tonlar Keep'in paletiyle aynı (kullanıcı
/// isteği): mercandan tebeşire, sıcaktan soğuğa.
///
/// **İlk beş kimlik ASLA değişmez** (`red`, `amber`, `green`, `blue`,
/// `purple`): Firestore'da bu dizgilerle kayıtlı notlar var. Yeni tonlar
/// yeni kimliklerle eklendi; eski sürüm bilmediği bir kimliği görürse
/// [fromId] onu varsayılana düşürür — not kaybı olmaz, yalnız rengi solar.
enum NoteColor {
  none('default'),
  red('red'),
  peach('peach'),
  amber('amber'),
  green('green'),
  sage('sage'),
  blue('blue'),
  storm('storm'),
  purple('purple'),
  blossom('blossom'),
  clay('clay'),
  chalk('chalk');

  const NoteColor(this.id);

  final String id;

  static NoteColor fromId(String? id) => NoteColor.values.firstWhere(
    (c) => c.id == id,
    orElse: () => NoteColor.none,
  );
}

/// Metne gömülü bir ek bağı: `📎 <label>` etiketi hangi eke gider.
/// Bkz. `Note.tagLinks`.
class NoteTagLink {
  const NoteTagLink({required this.label, required this.attachmentId});

  /// Metinde görünen etiket yazısı (kullanıcının seçtiği kelime/cümle).
  final String label;

  /// Bağlandığı ekin kimliği. Ek silinirse bağ yetim kalır ve okuyan taraf
  /// onu yok sayar — bağı temizlemek için ayrıca yazım gerekmesin diye.
  final String attachmentId;

  factory NoteTagLink.fromMap(Map<String, dynamic> map) => NoteTagLink(
    label: map['label'] as String? ?? '',
    attachmentId: map['attachmentId'] as String? ?? '',
  );

  Map<String, dynamic> toMap() => {
    'label': label,
    'attachmentId': attachmentId,
  };
}

/// Notun bir SAYFASI (bkz. [Note.textPages]). Etkin sayfanın girdisi boştur;
/// içeriği notun kendi gövdesinde/maddelerindedir.
class NoteTextPage {
  const NoteTextPage({required this.id, this.body = '', this.items = const []});

  /// '' = ilk sayfa (eski, bölümsüz görseller ona aittir).
  final String id;
  final String body;
  final List<NoteItem> items;

  NoteTextPage copyWith({String? id, String? body, List<NoteItem>? items}) =>
      NoteTextPage(
        id: id ?? this.id,
        body: body ?? this.body,
        items: items ?? this.items,
      );

  factory NoteTextPage.fromMap(Map<String, dynamic> map) => NoteTextPage(
    id: map['id'] as String? ?? '',
    body: map['body'] as String? ?? '',
    items: [
      for (final raw in (map['items'] as List<dynamic>? ?? const []))
        NoteItem.fromMap(Map<String, dynamic>.from(raw as Map)),
    ],
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'body': body,
    'items': [for (final i in items) i.toMap()],
  };
}

class AiSummary {
  const AiSummary({required this.text, required this.model, this.createdAt});

  final String text;
  final String model;
  final DateTime? createdAt;

  factory AiSummary.fromMap(Map<String, dynamic> map) => AiSummary(
    text: map['text'] as String? ?? '',
    model: map['model'] as String? ?? '',
    createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
  );

  Map<String, dynamic> toMap() => {
    'text': text,
    'model': model,
    'createdAt': createdAt != null
        ? Timestamp.fromDate(createdAt!)
        : FieldValue.serverTimestamp(),
  };
}

/// Eski sürümün `text`e düşürdüğü belge notunu geri yükseltir.
///
/// KÖK NEDEN: eski sürüm `type` alanını KOŞULSUZ yazıyor ve tanımadığı
/// `pdf`/`slides` kimliğini [NoteType.fromId] ile `text`e düşürüp öyle GERİ
/// KAYDEDİYOR. O andan sonra not yeni sürümde de düz metin notu olarak
/// açılırdı: sayfa notları dokümanda DURUR ama arayüzden erişilemez —
/// pratikte kalıcı kayıp. Eski sürümü düzeltmek mümkün olmadığından telafi
/// okuma tarafında yapılıyor.
///
/// Ölçüt dar tutuldu: SAYFA NOTU olan VE belge eki taşıyan bir "text" notu
/// başka türlü oluşmaz. Yalnız PDF eki olan düz metin notu meşrudur, ona
/// dokunulmaz.
///
/// [classicDocument]: kullanıcı belge notunu BİLEREK klasik görünüme aldıysa
/// (bkz. [Note.classicDocument]) onarım yapılmaz — yoksa not her açılışta
/// balonluya geri dönerdi.
NoteType repairNoteType(
  NoteType stored, {
  required List<String?> attachmentKinds,
  required bool hasPageNotes,
  bool classicDocument = false,
}) {
  if (stored != NoteType.text || !hasPageNotes || classicDocument) {
    return stored;
  }
  for (final kind in attachmentKinds) {
    if (kind == AttachmentKind.pdf.id) return NoteType.pdf;
    if (kind == AttachmentKind.slide.id) return NoteType.slides;
  }
  return stored;
}

/// Bir not — tüm içerik tek Firestore dokümanında tutulur (atomik ve
/// offline dostu). İkili veriler (görsel/PDF) Storage'dadır.
class Note {
  const Note({
    required this.id,
    required this.type,
    this.title = '',
    this.body = '',
    this.items = const [],
    this.pageNotes = const {},
    this.updatedBy = '',
    this.attachments = const [],
    this.tags = const [],
    this.folderId,
    this.color = NoteColor.none,
    this.frameColor = NoteColor.none,
    this.pinned = false,
    this.starred = false,
    this.locked = false,
    this.fontFamily,
    this.fontScale = 1,
    this.textOpacity = 1,
    this.titleFontFamily,
    this.titleFontScale = 1,
    this.titleTextOpacity = 1,
    this.backgroundImageId,
    this.backgroundOpacity = 0.35,
    this.listColumns = 1,
    this.classicDocument = false,
    this.archivePages = const [],
    this.archivePaper = ArchivePaper.lined,
    this.archiveGeneralName = '',
    this.tagLinks = const [],
    this.textPages = const [],
    this.activePage = '',
    this.orderIndex = 0,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.archivedAt,
    this.reminderAt,
    this.aiSummary,
    this.localOnly = false,
  });

  final String id;
  final NoteType type;
  final String title;

  /// Yalnızca [NoteType.text] için kullanılır.
  final String body;

  /// Yalnızca liste tiplerinde kullanılır; sıra = dizi indeksi.
  final List<NoteItem> items;

  /// [NoteType.pdf] notlarında SAYFA BAŞINA tutulan notlar.
  /// Anahtar `"<ekId>#<sayfaKimliği>"` (bkz. `page_notes.dart`).
  ///
  /// Neden [body]/[items] değil: gövde tek bir akış, maddeler ise SIRALI bir
  /// liste — ikisi de "3. sayfanın notu" diye adreslenemez. Firestore'da
  /// LİSTE değil HARİTA olarak durur; liste olsaydı araya sayfa eklemek tüm
  /// indeksleri kaydırır ve iki cihazın aynı anda yazması listenin tamamını
  /// çakıştırırdı, harita anahtarları ise birbirinden bağımsız birleşir.
  ///
  /// **TUZAK — silinen sayfa notu boş dizgi olarak yazılır, anahtar
  /// KALDIRILMAZ.** Belgeler `set(..., merge: true)` ile güncelleniyor ve
  /// merge haritaları DERİN birleştirir: anahtar haritadan düşürülürse
  /// Firestore'daki eski değer olduğu gibi kalır, yani kullanıcının sildiği
  /// not not sonraki açılışta geri gelirdi (renk/şeffaflık alanlarındaki aynı
  /// tuzağın haritalı hâli). Boş dizgi taşıyan anahtar "notu yok" demektir.
  final Map<String, String> pageNotes;

  /// Notu SON YAZAN kişinin uid'i. Yalnız PAYLAŞILAN klasörlerde anlamlı:
  /// "bu değişikliği ben mi yaptım, karşı taraf mı" sorusunun tek yanıtı
  /// (kullanıcı isteği 2026-09-04: "paylaşılan notlarda karşı taraf … bir
  /// notta değişiklik yaptığında bildirim gelmeli"). Kendi yazdığım
  /// değişiklik bana bildirim/rozet ÜRETMEZ.
  ///
  /// Kayda depo katmanı yazar (bkz. `NotesRepository.editorUid`), [toMap]
  /// DEĞİL: notun kendisi kimin yazdığını bilmez, yazan bilir. Eski
  /// kayıtlarda boş — o zaman "kimin yazdığı bilinmiyor" sayılır ve
  /// bildirime girer (kayıp bildirim, yanlış sessizlikten iyidir).
  final String updatedBy;

  final List<Attachment> attachments;

  /// Serbest etiketler ("iş", "ev"...). '#' işareti olmadan saklanır.
  final List<String> tags;

  /// Notun bağlı olduğu klasörün id'si (null = klasörsüz). Klasörler
  /// users/{uid}/folders koleksiyonunda tutulur.
  final String? folderId;
  final NoteColor color;

  /// Kartın/edit ekranının çevresine çizilen renkli çerçeve. [NoteColor.none]
  /// = çerçeve yok (yalnız ince varsayılan kenarlık). Zemin renginden
  /// ([color]) bağımsızdır: renkli zemin + farklı renkli çerçeve olabilir.
  final NoteColor frameColor;
  final bool pinned;

  /// Yıldızlı (favori) not: filtre çubuğundaki "Yıldızlı" süzgeciyle
  /// kolayca bulunur.
  final bool starred;

  /// Kilitli not: kart içeriği gizlenir, açmak biyometrik doğrulama ister;
  /// arama yalnızca başlıkta yapılır ve AI bağlamlarına dahil edilmez.
  final bool locked;

  /// Notun kendi yazı tipi: null = uygulama varsayılanı, 'serif' = kitap,
  /// 'monospace' = daktilo. Sistemde HER ZAMAN bulunan genel aileler seçildi;
  /// indirilen bir yazı tipi çevrimdışı açılan notta eksik kalırdı.
  final String? fontFamily;

  /// Notun kendi yazı boyutu çarpanı (1 = varsayılan). Ayarlardaki genel
  /// ölçekten AYRIDIR: bu tek nota özeldir (uzun bir belgeyi küçültmek,
  /// alışveriş listesini büyütmek).
  final double fontScale;

  /// Not metninin opaklığı (0.3–1). 1 = tam koyu. Soluk yazı, tamamlanmış ya
  /// da arka plana itilmek istenen notları renk değiştirmeden geri plana
  /// alır. Taban 0.3'tür: daha soluğunda kullanıcı yazdığını göremez ve
  /// ayarı geri bulamaz.
  final double textOpacity;

  /// Başlığın KENDİ yazı tipi / boyutu / opaklığı.
  ///
  /// Eskiden başlık gövdeyle aynı üç değerden besleniyordu: gövdeyi büyütmek
  /// başlığı da büyütüyor, başlığı büyütmek gövdeyi de büyütüyordu — biçim
  /// çubuğu hangi alandayken kullanılırsa kullanılsın sonuç ikisine birden
  /// gidiyordu. Artık biçim çubuğu ODAKTAKİ alana yazar.
  ///
  /// Eski notlarda bu alanlar kayıtta YOK: [Note.fromDoc] onları gövdenin
  /// değerinden devralır, böylece mevcut notların görünümü birebir korunur.
  final String? titleFontFamily;
  final double titleFontScale;
  final double titleTextOpacity;

  /// Notun ZEMİN görseli: [attachments] içindeki bir görselin id'si.
  ///
  /// Ayrı bir alanda değil ekler listesinde durur; yükleme kuyruğu, silme,
  /// yedek ve çevrimdışı kopya mantığı olduğu gibi yeniden kullanılır. Zemin
  /// görseli sayfada YÜZMEZ ve ek şeridinde görünmez (editör onu id'ye göre
  /// ayıklar).
  final String? backgroundImageId;

  /// Zemin görselinin görünürlüğü (0.05–1). Varsayılan bilerek düşük: tam
  /// opak bir fotoğrafın üstünde not okunmuyor.
  final double backgroundOpacity;

  /// Liste notunun KAÇ SÜTUNDA gösterileceği: 1 (varsayılan) ya da 2.
  ///
  /// Kullanıcı isteği 2026-08-16: "liste modunda 2 kolon modu". Kısa maddeli
  /// uzun listelerde (alışveriş, yapılacaklar) tek sütun ekranın sağ yarısını
  /// boş bırakıp listeyi gereksiz uzatıyor.
  ///
  /// Not BAŞINA saklanır, genel ayar değil: aynı kullanıcının bir notu
  /// tek satırlık maddelerden, başka bir notu paragraf uzunluğunda
  /// maddelerden oluşabiliyor ve ikincisi iki sütunda okunmaz hâle gelir.
  final int listColumns;

  /// Belge (PDF/sunum) notu KLASİK görünüme alındı mı?
  ///
  /// Kullanıcı isteği 2026-10-15: "balonlu mod ve normal ek arasında hızlı
  /// geçiş, düzenler kaydedilsin". Geçiş notun TİPİNİ değiştirir (pdf/slides
  /// ⇄ text) ve hiçbir veriyi silmez: balonlar, vurgular, çizimler ve sayfa
  /// notları ekte/notta kalır; klasik düzen (belgenin sayfadaki yeri,
  /// boyutu, sayfası) da ekte durur. Geri dönünce ikisi de olduğu gibi gelir.
  ///
  /// Bu bayrak YALNIZ [repairNoteType]'ı durdurur: sayfa notu taşıyan bir
  /// "text" notu eski sürüm onarımında belge notuna geri yükseltiliyordu —
  /// klasik görünüm her açılışta kendiliğinden balonluya dönerdi.
  final bool classicDocument;

  /// Arşiv defterinin ELLE açılmış sayfaları (sıralı, adlarıyla).
  ///
  /// Türe göre dolan sayfalar (Görseller / Videolar / Belgeler / Metinler)
  /// burada DURMAZ — onlar her arşivde vardır ve dilden geldikleri için
  /// kayda yazılmaları uygulamanın dili değişince adları dondururdu.
  /// Burada yalnız kullanıcının kendi verdiği adlar tutulur; girdiler
  /// `Attachment.section` / `NoteItem.section` ile bu adlara bağlanır.
  final List<String> archivePages;

  /// Arşiv defterinin KÂĞIT DESENİ (çizgili / kareli / noktalı / düz).
  /// Defter başına saklanır — bkz. [ArchivePaper].
  final ArchivePaper archivePaper;

  /// Defterin İLK sayfasının (bölümsüz girdilerin toplandığı sayfa) ADI.
  /// Boş = uygulamanın dilinden gelen "Genel".
  ///
  /// Neden ayrı bir alan: ilk sayfanın girdileri bölüm adı TAŞIMAZ (boş
  /// `section`) ve öksüz kalmış girdiler de oraya düşer (bkz.
  /// `archiveOnPage`). Sayfaya gerçek bir ad verilseydi bütün o girdilerin
  /// yeniden etiketlenmesi gerekirdi; ad yalnız GÖRÜNENDİR, girdilerin
  /// bağlanma kuralı değişmez.
  final String archiveGeneralName;

  /// Metnin İÇİNE gömülmüş ek bağları: hangi ETİKET METNİ hangi eke gider.
  ///
  /// Kullanıcı isteği 2026-08-16: "o yazıya PDF gömülür, o yazının altı
  /// çizilir kırmızı vurgulanır, tıklayınca PDF önizlemede açılır". Yani
  /// bağın taşıyıcısı DOSYA ADI değil, kullanıcının kendi yazdığı kelime
  /// ("uygulaması") olmalı.
  ///
  /// **Neden metinde gizli kimlik yok**: satır içi biçim işaretleri
  /// (rich_text.dart) metinde durup görünmez çiziliyor ve bu, imleç/seçim
  /// konumlarının denetleyicinin metniyle birebir örtüşmesi gereken çok
  /// hassas bir sözleşme. Ek bağı için ikinci bir gizli karakter sınıfı daha
  /// eklemek o sözleşmeyi yeniden riske atardı. Bunun yerine metinde yalnız
  /// GÖRÜNÜR bir ataç (📎) ile etiketin kendisi durur; hangi eke gittiği
  /// burada yazar.
  ///
  /// Liste (harita değil): etiket metni kullanıcının yazdığı serbest bir
  /// dize ve nokta içerebiliyor — Firestore'da harita ANAHTARI yapmak alan
  /// yolu kurallarına takılırdı.
  final List<NoteTagLink> tagLinks;

  /// NOTUN SAYFALARI (kullanıcı isteği 2026-10-11: "bir nota yeni sayfa
  /// ekleme"). Boş = tek sayfalı not (eski notların hepsi).
  ///
  /// KARAR — ETKİN sayfanın içeriği [body]/[items]'ta yaşar, listedeki
  /// karşılığı boş tutulur. Editörün, AI'ın, dikte ve biçim çubuğunun hepsi
  /// `body`yi düzenliyor; sayfa geçişi yalnız İÇERİKLERİ YER DEĞİŞTİRİR
  /// (bkz. `note_pages.dart` → [switchTextPage]) ve bu yollardan hiçbirinin
  /// sayfayı bilmesi gerekmez. Sayfaya ait görseller `Attachment.section`
  /// = sayfa kimliğiyle işaretlenir; İLK sayfanın kimliği her zaman ''
  /// (eski görseller zaten bölümsüz).
  final List<NoteTextPage> textPages;

  /// Etkin sayfanın kimliği ('' = ilk sayfa). Bkz. [textPages].
  final String activePage;
  final double orderIndex;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  /// Arşivlenen notlar dashboard'da görünmez; Arşiv ekranından erişilir.
  final DateTime? archivedAt;

  /// Doluysa bu tarihte yerel bildirim planlanır.
  final DateTime? reminderAt;
  final AiSummary? aiSummary;

  /// **YALNIZ BU CİHAZDA** (kullanıcı isteği 2026-09-26: "senkronizasyon
  /// kapatma nota özel"). Not Firestore'da DEĞİL, cihazdaki yerel depoda
  /// yaşar (bkz. `LocalNotesStore`); başka cihazlara gitmez, ekleri buluta
  /// yüklenmez. Kayda YAZILMAZ — notun nerede durduğunu belirten bir özellik,
  /// içeriğin parçası değil ([toMap]'te yok).
  final bool localOnly;

  /// "Boş" not sessizce silinebilir (editör kapanışı + arka plan temizliği).
  /// Hatırlatıcısı olan not boş SAYILMAZ: "sadece alarm" için metinsiz not
  /// bırakmak meşru bir kullanım — silinirse kurulu hatırlatıcı da kaybolur.
  bool get isEmpty =>
      title.trim().isEmpty &&
      body.trim().isEmpty &&
      items.every((i) => i.text.trim().isEmpty) &&
      // Sayfa notu yazılmış bir belge notu boş SAYILMAZ — belgesi silinmiş
      // olsa bile. Burada BİLEREK [hasPageNotes] kullanılmıyor: o yalnız
      // MEVCUT eklerin notlarını sayıyor, oysa arka plan temizliği "boş"
      // gördüğü notu SESSİZCE siler. Kullanıcı belgeyi değiştirmek için
      // silmiş olabilir; yazdıkları o aralıkta yok edilmemeli. Görünürde boş
      // kalan notu kullanıcı listeden kendisi silebilir.
      pageNotes.values.every((v) => v.trim().isEmpty) &&
      // Diğer sayfalarda yazı varsa not boş değil (etkin sayfa boş olsa da).
      textPages.every(
        (p) =>
            p.body.trim().isEmpty &&
            p.items.every((i) => i.text.trim().isEmpty),
      ) &&
      attachments.isEmpty &&
      reminderAt == null;

  /// MEVCUT eklerin sayfa notu var mı? (Boş dizgiler sayılmaz; belgesi
  /// silinmiş eskiden kalma anahtarlar sayılmaz.)
  bool get hasPageNotes {
    if (pageNotes.isEmpty) return false;
    for (final attachment in attachments) {
      for (final entry in pageNotes.entries) {
        if (entry.value.trim().isEmpty) continue;
        if (isPageNoteKeyOf(entry.key, attachment.id)) return true;
      }
    }
    return false;
  }

  /// [attachment]'in [pageNumber] sayfası için kayıtlı not (yoksa boş dizgi).
  String pageNote(Attachment attachment, int pageNumber) =>
      pageNotes[pageNoteKey(attachment, pageNumber)] ?? '';

  /// [attachment]'in [pageNumber] sayfasının notunu değiştirmiş kopya.
  ///
  /// Boş metin anahtarı SİLMEZ, boş dizgi yazar: `set(merge: true)` derin
  /// birleştirmede eksik anahtarı "değişmedi" sayar (bkz. [pageNotes]).
  Note withPageNote(Attachment attachment, int pageNumber, String text) =>
      copyWith(
        pageNotes: {...pageNotes, pageNoteKey(attachment, pageNumber): text},
      );

  /// AI'ya gönderilecek düz metin temsili. Satır içi biçim işaretleri
  /// (`**kalın**` gibi) SÖKÜLÜR: modele, sesli okumaya ve paylaşıma giden
  /// metinde işaretlerin işi yok (bkz. rich_text.dart).
  /// Başlığın GÖSTERİM hâli: satır içi biçim işaretleri sökülmüş.
  ///
  /// Başlık da artık biçimlendirilebiliyor (kullanıcı: "sadece başlığın
  /// boyutunu ayarlayamıyorum"); işaretler yalnız editörde, görünmez olarak
  /// yaşar. Kart, çöp kutusu, paylaşım, brifing gibi her yerde bu getter
  /// kullanılır.
  String get displayTitle => stripRichMarkers(title);

  /// [skipChecked] true ise TAMAMLANMIŞ maddeler metne katılmaz.
  ///
  /// Kullanıcı isteği 2026-08-16: "ai analiz işaretli öğeleri de analiz
  /// ediyor". Yapılacaklar listesinde işaretli madde BİTMİŞ iştir; analiz ve
  /// özet onları da sayınca "alışveriş yapılmalı" gibi zaten yapılmış işleri
  /// eylem maddesi olarak geri veriyordu. Paylaşım/dışa aktarma yolları
  /// varsayılanı (false) kullanır — orada işaretli madde GÖRÜNMELİ.
  String toPlainText({bool skipChecked = false}) {
    final buffer = StringBuffer();
    if (title.trim().isNotEmpty) buffer.writeln(stripRichMarkers(title).trim());
    // SAYFALI NOT: her sayfa sırayla, aralarında boş satır (bkz.
    // [textPages] — etkin sayfanın içeriği gövdede).
    final pageContents = textPages.isEmpty
        ? [(body, items)]
        : [
            for (final p in textPages)
              p.id == activePage ? (body, items) : (p.body, p.items),
          ];
    void writePages(void Function(String body, List<NoteItem> items) write) {
      for (var i = 0; i < pageContents.length; i++) {
        if (i > 0) buffer.writeln();
        write(pageContents[i].$1, pageContents[i].$2);
      }
    }

    switch (type) {
      case NoteType.text:
        writePages((body, items) {
          if (body.trim().isNotEmpty) buffer.writeln(body);
          // Karışık içerik: metin notuna eklenen checklist maddeleri de dahil.
          for (final item in items) {
            if (item.text.trim().isEmpty) continue;
            if (skipChecked && item.checked) continue;
            buffer.writeln('- [${item.checked ? 'x' : ' '}] ${item.text}');
          }
        });
      case NoteType.checklist:
        // Liste notunun da serbest metni olabilir (madde listesinin üstünde
        // duran açıklama); dışa aktarmada kaybolmamalı.
        writePages((body, items) {
          if (body.trim().isNotEmpty) buffer.writeln(body);
          for (final item in items) {
            if (skipChecked && item.checked) continue;
            buffer.writeln('- [${item.checked ? 'x' : ' '}] ${item.text}');
          }
        });
      case NoteType.ordered:
        writePages((body, items) {
          if (body.trim().isNotEmpty) buffer.writeln(body);
          var number = 0;
          for (final item in items) {
            if (skipChecked && item.checked) continue;
            buffer.writeln('${++number}. ${item.text}');
          }
        });
      case NoteType.archive:
        // Arşiv defterinin metni: açıklama + metin girdileri. Ekler
        // (görsel/belge) düz metne dökülemez; başlıkları paylaşım/dışa
        // aktarmada zaten ek listesi olarak görünür.
        if (body.trim().isNotEmpty) buffer.writeln(body);
        for (final item in items) {
          if (item.text.trim().isEmpty) continue;
          buffer.writeln(item.text);
        }
      case NoteType.pdf:
      case NoteType.slides:
        // PDF/sunum notunun metni SAYFA NOTLARIDIR. Sayfa numarası olmadan
        // gönderilirse paylaşılan metin de AI bağlamı da hangi notun hangi
        // sayfaya ait olduğunu kaybeder; başlık işareti dile bağlı olmayan
        // `#3` biçiminde (ekranda görünen "Sayfa 3" başlığı l10n'den gelir).
        if (body.trim().isNotEmpty) buffer.writeln(body);
        buffer.write(pageNotesText());
    }
    return stripRichMarkers(buffer.toString().trim());
  }

  /// Sayfa notlarının düz metin dökümü: her ek için sayfa sırasına dizilmiş,
  /// `#<sayfa>` başlıklı bloklar. Sayfası çözülemeyen (silinmiş sayfaya ait)
  /// notlar atlanır — bkz. [orderedPageNotes].
  String pageNotesText() {
    final buffer = StringBuffer();
    for (final attachment in attachments) {
      for (final entry in orderedPageNotes(
        attachment: attachment,
        pageNotes: pageNotes,
      )) {
        buffer
          ..writeln('#${entry.page}')
          ..writeln(entry.text.trim());
      }
    }
    return buffer.toString();
  }

  /// AI ile "geliştir/düzelt" için notun İÇERİĞİ — başlık ve liste işaretleri
  /// (`- [ ]`, `[x]`, numara) OLMADAN, her satır bir öğe/paragraf. Round-trip'te
  /// (not → metin → AI → not) başlığın öğeye, onay kutusu/numara işaretlerinin
  /// öğe metnine sızmasını engeller — bu yüzden başlık+işaret taşıyan
  /// [toPlainText]'ten ayrı tutulur.
  /// [skipChecked] true ise işaretli (tamamlanmış) maddeler İÇERİĞE KATILMAZ —
  /// AI düzeltme/çevirisine yalnız işaretsiz maddeler gider; tamamlananlar
  /// değiştirilmeden yerinde korunur ("işaretlilere karışma" isteği).
  ///
  /// Satır içi biçim işaretleri burada da sökülür: AI'ya işaretli metin
  /// gitseydi dönen metinde işaretler bozulur ya da çoğalırdı.
  String toContentText({bool skipChecked = false}) {
    bool include(NoteItem item) =>
        item.text.trim().isNotEmpty && !(skipChecked && item.checked);
    return stripRichMarkers(switch (type) {
      NoteType.text => [
        if (body.trim().isNotEmpty) body.trim(),
        // Karışık içerik: metin notundaki checklist maddeleri de içeriğe girer.
        for (final item in items)
          if (include(item)) item.text.trim(),
      ].join('\n'),
      NoteType.checklist || NoteType.ordered || NoteType.archive => [
        if (body.trim().isNotEmpty) body.trim(),
        for (final item in items)
          if (include(item)) item.text.trim(),
      ].join('\n'),
      // PDF notunda AI'ya giden içerik sayfa notlarıdır; `#<sayfa>` başlığı
      // BURADA da durur, çünkü "geliştir/çevir" sonucu sayfalara geri
      // dağıtılabilmeli — başlıksız dönen metinde hangi paragrafın hangi
      // sayfaya ait olduğu kaybolurdu.
      NoteType.pdf || NoteType.slides => [
        if (body.trim().isNotEmpty) body.trim(),
        pageNotesText().trim(),
      ].where((s) => s.isNotEmpty).join('\n'),
    });
  }

  Note copyWith({
    NoteType? type,
    String? title,
    String? body,
    List<NoteItem>? items,
    Map<String, String>? pageNotes,
    List<Attachment>? attachments,
    List<String>? tags,
    String? folderId,
    bool clearFolderId = false,
    NoteColor? color,
    NoteColor? frameColor,
    bool? pinned,
    bool? starred,
    bool? locked,
    String? fontFamily,
    bool clearFontFamily = false,
    double? fontScale,
    double? textOpacity,
    String? titleFontFamily,
    bool clearTitleFontFamily = false,
    double? titleFontScale,
    double? titleTextOpacity,
    String? backgroundImageId,
    bool clearBackgroundImage = false,
    double? backgroundOpacity,
    int? listColumns,
    bool? classicDocument,
    List<String>? archivePages,
    ArchivePaper? archivePaper,
    String? archiveGeneralName,
    List<NoteTagLink>? tagLinks,
    List<NoteTextPage>? textPages,
    String? activePage,
    double? orderIndex,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
    DateTime? archivedAt,
    bool clearArchivedAt = false,
    DateTime? reminderAt,
    bool clearReminderAt = false,
    AiSummary? aiSummary,
    bool? localOnly,
  }) => Note(
    id: id,
    type: type ?? this.type,
    title: title ?? this.title,
    body: body ?? this.body,
    items: items ?? this.items,
    pageNotes: pageNotes ?? this.pageNotes,
    attachments: attachments ?? this.attachments,
    tags: tags ?? this.tags,
    folderId: clearFolderId ? null : (folderId ?? this.folderId),
    color: color ?? this.color,
    frameColor: frameColor ?? this.frameColor,
    pinned: pinned ?? this.pinned,
    starred: starred ?? this.starred,
    locked: locked ?? this.locked,
    fontFamily: clearFontFamily ? null : (fontFamily ?? this.fontFamily),
    fontScale: fontScale ?? this.fontScale,
    textOpacity: textOpacity ?? this.textOpacity,
    titleFontFamily: clearTitleFontFamily
        ? null
        : (titleFontFamily ?? this.titleFontFamily),
    titleFontScale: titleFontScale ?? this.titleFontScale,
    titleTextOpacity: titleTextOpacity ?? this.titleTextOpacity,
    backgroundImageId: clearBackgroundImage
        ? null
        : (backgroundImageId ?? this.backgroundImageId),
    backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
    listColumns: listColumns ?? this.listColumns,
    classicDocument: classicDocument ?? this.classicDocument,
    archivePages: archivePages ?? this.archivePages,
    archivePaper: archivePaper ?? this.archivePaper,
    archiveGeneralName: archiveGeneralName ?? this.archiveGeneralName,
    tagLinks: tagLinks ?? this.tagLinks,
    textPages: textPages ?? this.textPages,
    activePage: activePage ?? this.activePage,
    orderIndex: orderIndex ?? this.orderIndex,
    createdAt: createdAt,
    updatedAt: updatedAt,
    deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    archivedAt: clearArchivedAt ? null : (archivedAt ?? this.archivedAt),
    reminderAt: clearReminderAt ? null : (reminderAt ?? this.reminderAt),
    aiSummary: aiSummary ?? this.aiSummary,
    localOnly: localOnly ?? this.localOnly,
    // Parametresi YOK: "kim yazdı" kaydın bir olgusu, çağıranın seçimi
    // değil — kopyada da olduğu gibi taşınır (bkz. [updatedBy]).
    updatedBy: updatedBy,
  );

  factory Note.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      Note.fromMap(
        doc.id,
        doc.data() ?? const <String, dynamic>{},
        pending: doc.metadata.hasPendingWrites,
      );

  /// Firestore biçimindeki kayıttan not (belge ya da yerel depo — bkz.
  /// `LocalNotesStore`). [pending]: yazım sunucuya ulaşmadı (tarihsiz
  /// kayıtta zaman ŞİMDİ sayılır, aşağıdaki gerekçe).
  factory Note.fromMap(
    String id,
    Map<String, dynamic> map, {
    bool pending = false,
    bool localOnly = false,
  }) {
    // Sunucuya ULAŞMAMIŞ yazımlarda `serverTimestamp()` yerel kopyada NULL
    // okunur. Tarihsiz not, "Son düzenlenen" sıralamasında en eskiye ("DAHA
    // ÖNCE" kovasına) düşüyor ve listenin en dibinde beliriyordu; ağ hızına
    // göre kimi zaman anında doğru yere gelip kimi zaman gelmediğinden not
    // "bazen oluşuyor bazen oluşmuyor" gibi görünüyordu. Bekleyen yazımda
    // zaman ŞİMDİ kabul edilir — sunucu damgası geldiğinde gerçek değerle
    // değişir. (Yalnız bekleyen yazımda: eski kayıtların tarihi uydurulmaz.)
    final localNow = pending ? DateTime.now() : null;
    // GERİYE DÖNÜK ONARIM: eski sürüm `type` alanını KOŞULSUZ yazıyor ve
    // tanımadığı `pdf`/`slides` kimliğini `text`e düşürüp öyle geri
    // kaydediyor. O andan sonra not yeni sürümde de düz metin notu olarak
    // açılır, sayfa notları dokümanda DURUR ama arayüzden erişilemez —
    // pratikte kalıcı kayıp. Belgesi ve sayfa notu olan bir "text" notu
    // aslında bir belge notudur; tipi geri yükseltiliyor.
    final storedType = NoteType.fromId(map['type'] as String?);
    final rawAttachments = (map['attachments'] as List<dynamic>? ?? const []);
    final rawPageNotes =
        (map['pageNotes'] as Map<dynamic, dynamic>? ?? const {});
    final type = repairNoteType(
      storedType,
      attachmentKinds: [
        for (final raw in rawAttachments) (raw as Map)['kind']?.toString(),
      ],
      hasPageNotes: rawPageNotes.isNotEmpty,
      classicDocument: map['classicDocument'] == true,
    );
    return Note(
      id: id,
      localOnly: localOnly,
      type: type,
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      items: [
        for (final raw in (map['items'] as List<dynamic>? ?? const []))
          NoteItem.fromMap(Map<String, dynamic>.from(raw as Map)),
      ],
      pageNotes: {
        for (final e
            in (map['pageNotes'] as Map<dynamic, dynamic>? ?? const {}).entries)
          e.key.toString(): e.value?.toString() ?? '',
      },
      attachments: [
        for (final raw in (map['attachments'] as List<dynamic>? ?? const []))
          // noteId ile: ekin yerel yolu cihazda türetilir, belgeden okunmaz.
          Attachment.fromMap(Map<String, dynamic>.from(raw as Map), noteId: id),
      ],
      tags: [
        for (final tag in (map['tags'] as List<dynamic>? ?? const []))
          tag.toString(),
      ],
      folderId: map['folderId'] as String?,
      color: NoteColor.fromId(map['color'] as String?),
      frameColor: NoteColor.fromId(map['frameColor'] as String?),
      pinned: map['pinned'] as bool? ?? false,
      starred: map['starred'] as bool? ?? false,
      locked: map['locked'] as bool? ?? false,
      fontFamily: map['fontFamily'] as String?,
      fontScale: (map['fontScale'] as num?)?.toDouble() ?? 1,
      textOpacity: (map['textOpacity'] as num?)?.toDouble() ?? 1,
      // GEÇİŞ: başlık alanları eklenmeden önce yazılmış notlarda kayıtta yok.
      // Gövdenin değerini devralırlar — eski notlar bugüne kadar nasıl
      // görünüyorsa öyle kalır, ayrışma ilk düzenlemeden sonra başlar.
      // `containsKey`: başlığın yazı tipi BİLEREK null olabilir (varsayılan
      // yazı tipi) ve bu "hiç yazılmamış"tan farklıdır.
      titleFontFamily: map.containsKey('titleFontFamily')
          ? map['titleFontFamily'] as String?
          : map['fontFamily'] as String?,
      titleFontScale:
          (map['titleFontScale'] as num?)?.toDouble() ??
          (map['fontScale'] as num?)?.toDouble() ??
          1,
      titleTextOpacity:
          (map['titleTextOpacity'] as num?)?.toDouble() ??
          (map['textOpacity'] as num?)?.toDouble() ??
          1,
      backgroundImageId: map['backgroundImageId'] as String?,
      backgroundOpacity: (map['backgroundOpacity'] as num?)?.toDouble() ?? 0.35,
      // 1 ve 2 dışındaki bir değer (ileride eklenecek bir sütun sayısını
      // bilmeyen bu sürüm) tek sütuna düşer — çizim yolu ikiden fazlasını
      // yerleştiremez.
      listColumns: (map['listColumns'] as num?)?.toInt() == 2 ? 2 : 1,
      classicDocument: map['classicDocument'] == true,
      archivePages: [
        for (final p in (map['archivePages'] as List<dynamic>? ?? const []))
          p.toString(),
      ],
      archivePaper: ArchivePaper.fromId(map['archivePaper'] as String?),
      archiveGeneralName: map['archiveGeneralName'] as String? ?? '',
      tagLinks: [
        for (final raw in (map['tagLinks'] as List<dynamic>? ?? const []))
          NoteTagLink.fromMap(Map<String, dynamic>.from(raw as Map)),
      ],
      textPages: [
        for (final raw in (map['textPages'] as List<dynamic>? ?? const []))
          NoteTextPage.fromMap(Map<String, dynamic>.from(raw as Map)),
      ],
      activePage: map['activePage'] as String? ?? '',
      orderIndex: (map['orderIndex'] as num?)?.toDouble() ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? localNow,
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? localNow,
      updatedBy: map['updatedBy'] as String? ?? '',
      deletedAt: (map['deletedAt'] as Timestamp?)?.toDate(),
      archivedAt: (map['archivedAt'] as Timestamp?)?.toDate(),
      reminderAt: (map['reminderAt'] as Timestamp?)?.toDate(),
      aiSummary: map['aiSummary'] is Map
          ? AiSummary.fromMap(
              Map<String, dynamic>.from(map['aiSummary'] as Map),
            )
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'type': type.id,
    'title': title,
    'body': body,
    'items': [for (final i in items) i.toMap()],
    // Yalnız doluysa yazılır: PDF olmayan notların şemasında bu alan hiç
    // oluşmaz. Dolduğunda anahtarlar tek tek birleşir — merge derin
    // birleştirdiği için başka cihazın yazdığı BAŞKA sayfanın notu ezilmez.
    if (pageNotes.isNotEmpty) 'pageNotes': pageNotes,
    'attachments': [for (final a in attachments) a.toMap()],
    'tags': tags,
    'folderId': folderId,
    'color': color.id,
    'frameColor': frameColor.id,
    'pinned': pinned,
    'starred': starred,
    'locked': locked,
    // Varsayılandan farklıysa yazılır: eski notların şeması büyümez.
    if (fontFamily != null) 'fontFamily': fontFamily,
    // TUZAK — bu ikisi KOŞULSUZ yazılır. Belgeler `set(..., merge: true)` ile
    // güncelleniyor: alan haritada yoksa Firestore'daki ESKİ değer olduğu gibi
    // kalır. Koşullu yazıldıklarında kullanıcı şeffaflığı %100'e (ya da boyutu
    // %100'e) geri çektiğinde alan haritadan düşüyor, kayıtta eski değer
    // duruyor ve not yeniden açıldığında ayar geri geliyordu.
    'fontScale': fontScale,
    'textOpacity': textOpacity,
    // Başlık alanları da KOŞULSUZ yazılır (yukarıdaki merge tuzağının aynısı).
    // Yazı tipi null da yazılır: başlık, gövde başka bir yazı tipindeyken
    // varsayılana dönebilmeli — koşullu yazılsa eski değer kayıtta kalırdı.
    'titleFontFamily': titleFontFamily,
    'titleFontScale': titleFontScale,
    'titleTextOpacity': titleTextOpacity,
    // Zemin görseli KALDIRILABİLİR olmalı: merge yazımında alan haritada
    // yoksa eski değer kalır, bu yüzden null da açıkça yazılır.
    'backgroundImageId': backgroundImageId,
    'backgroundOpacity': backgroundOpacity,
    // HER ZAMAN yazılır (koşullu değil): notlar `set(merge: true)` ile
    // kaydediliyor, yani atlanmış bir anahtar SİLİNMEZ — koşullu yazılsaydı
    // iki sütundan tek sütuna dönmek kayda hiç yansımaz ve not her açılışta
    // yine iki sütunlu gelirdi.
    'listColumns': listColumns,
    // HER ZAMAN yazılır (merge tuzağı): balonluya geri dönüş bayrağı
    // indirebilmeli.
    'classicDocument': classicDocument,
    // HER ZAMAN yazılır: son özel sayfayı silmek `set(merge: true)` ile
    // ancak boş dizi yazılarak kayda geçer.
    'archivePages': archivePages,
    // HER ZAMAN yazılır (yukarıdaki merge tuzağı): desen varsayılana
    // (çizgili) DÖNDÜRÜLEBİLMELİ; koşullu yazılsaydı kayıtta eski desen
    // kalır ve defter her açılışta yine kareli gelirdi.
    'archivePaper': archivePaper.id,
    // HER ZAMAN yazılır (merge tuzağı): ad SİLİNEBİLMELİ — boş dize
    // "Genel"e dönmek demek.
    'archiveGeneralName': archiveGeneralName,
    // HER ZAMAN yazılır (`archivePages` ile aynı gerekçe: merge yazımda
    // atlanan anahtar silinmez, son bağı kaldırmak kayda yansımazdı).
    'tagLinks': [for (final l in tagLinks) l.toMap()],
    // HER ZAMAN yazılır (merge yazımda eksik alan "değişmedi" sayılır —
    // son sayfa silinince liste boşalmalı).
    'textPages': [for (final p in textPages) p.toMap()],
    'activePage': activePage,
    'orderIndex': orderIndex,
    'createdAt': createdAt != null
        ? Timestamp.fromDate(createdAt!)
        : FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
    'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
    'archivedAt': archivedAt != null ? Timestamp.fromDate(archivedAt!) : null,
    'reminderAt': reminderAt != null ? Timestamp.fromDate(reminderAt!) : null,
    'aiSummary': aiSummary?.toMap(),
  };
}
