import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/rich_text.dart';
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
NoteType repairNoteType(
  NoteType stored, {
  required List<String?> attachmentKinds,
  required bool hasPageNotes,
}) {
  if (stored != NoteType.text || !hasPageNotes) return stored;
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
    this.orderIndex = 0,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.archivedAt,
    this.reminderAt,
    this.aiSummary,
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
  final double orderIndex;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  /// Arşivlenen notlar dashboard'da görünmez; Arşiv ekranından erişilir.
  final DateTime? archivedAt;

  /// Doluysa bu tarihte yerel bildirim planlanır.
  final DateTime? reminderAt;
  final AiSummary? aiSummary;

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

  String toPlainText() {
    final buffer = StringBuffer();
    if (title.trim().isNotEmpty) buffer.writeln(stripRichMarkers(title).trim());
    switch (type) {
      case NoteType.text:
        if (body.trim().isNotEmpty) buffer.writeln(body);
        // Karışık içerik: metin notuna eklenen checklist maddeleri de dahil.
        for (final item in items) {
          if (item.text.trim().isEmpty) continue;
          buffer.writeln('- [${item.checked ? 'x' : ' '}] ${item.text}');
        }
      case NoteType.checklist:
        // Liste notunun da serbest metni olabilir (madde listesinin üstünde
        // duran açıklama); dışa aktarmada kaybolmamalı.
        if (body.trim().isNotEmpty) buffer.writeln(body);
        for (final item in items) {
          buffer.writeln('- [${item.checked ? 'x' : ' '}] ${item.text}');
        }
      case NoteType.ordered:
        if (body.trim().isNotEmpty) buffer.writeln(body);
        for (var i = 0; i < items.length; i++) {
          buffer.writeln('${i + 1}. ${items[i].text}');
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
      NoteType.checklist || NoteType.ordered => [
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
    double? orderIndex,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
    DateTime? archivedAt,
    bool clearArchivedAt = false,
    DateTime? reminderAt,
    bool clearReminderAt = false,
    AiSummary? aiSummary,
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
    orderIndex: orderIndex ?? this.orderIndex,
    createdAt: createdAt,
    updatedAt: updatedAt,
    deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    archivedAt: clearArchivedAt ? null : (archivedAt ?? this.archivedAt),
    reminderAt: clearReminderAt ? null : (reminderAt ?? this.reminderAt),
    aiSummary: aiSummary ?? this.aiSummary,
  );

  factory Note.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data() ?? const <String, dynamic>{};
    // Sunucuya ULAŞMAMIŞ yazımlarda `serverTimestamp()` yerel kopyada NULL
    // okunur. Tarihsiz not, "Son düzenlenen" sıralamasında en eskiye ("DAHA
    // ÖNCE" kovasına) düşüyor ve listenin en dibinde beliriyordu; ağ hızına
    // göre kimi zaman anında doğru yere gelip kimi zaman gelmediğinden not
    // "bazen oluşuyor bazen oluşmuyor" gibi görünüyordu. Bekleyen yazımda
    // zaman ŞİMDİ kabul edilir — sunucu damgası geldiğinde gerçek değerle
    // değişir. (Yalnız bekleyen yazımda: eski kayıtların tarihi uydurulmaz.)
    final pending = doc.metadata.hasPendingWrites;
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
    );
    return Note(
      id: doc.id,
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
          Attachment.fromMap(
            Map<String, dynamic>.from(raw as Map),
            noteId: doc.id,
          ),
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
      orderIndex: (map['orderIndex'] as num?)?.toDouble() ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? localNow,
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? localNow,
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
