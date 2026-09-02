import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show PointMode;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../../app/theme/note_colors.dart';
import '../../../core/constants.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/utils/debouncer.dart';
import '../../../core/utils/doc_picker.dart';
import '../../../core/utils/format_bytes.dart';
import '../../../core/utils/local_file.dart';
import '../../ai/data/ai_gate.dart';
import '../../ai/data/gemini_service.dart';
import '../../ai/presentation/ai_sheet.dart';
import '../../settings/data/permissions_service.dart';
import '../data/attachment_repository.dart';
import '../data/notes_repository.dart';
import '../data/scan/scan_ocr.dart';
import '../domain/archive_paper.dart';
import '../domain/attachment.dart';
import '../domain/note.dart';
import '../domain/note_item.dart';
import 'color_picker_sheet.dart';
import 'editor/drawing_screen.dart';
import 'editor/format_bar.dart';
import 'editor/format_menu.dart';
import 'editor/note_images.dart';
import 'editor/text_wrap.dart';
import 'viewers/pdf_viewer_screen.dart';
import 'viewers/slide_viewer_screen.dart';
import 'viewers/video_viewer.dart';

/// **DEFTER** ekranı — sayfaları çevrilen, üstüne DOĞRUDAN yazılan bir arşiv
/// defteri (bkz. [NoteType.archive]).
///
/// **İKİNCİ TUR (kullanıcı isteği 2026-09-01, ekran görüntüsüyle):** "metin
/// yazamıyorum, yazmak için bu alan açılıyor — direk sayfaya yazılabilmeli,
/// görsel eklenebilmeli, PDF eklenebilmeli, slayt eklenebilmeli, sayfa
/// geçişinde 'yeni sayfa ekle' çıkmadan oto geçiş olmalı, defterde tema
/// seçenekleri olmalı (çizgili, kareli, düz)."
///
/// Bir önceki tur defteri sayfalara böldü ama YAZMAYI hâlâ bir diyaloga
/// bağlıyordu: "+ → Metin ekle" bir `AlertDialog` açıyor, kullanıcı oraya
/// yazıyor, "Tamam"a basınca yazı sayfada bir SATIR olarak beliriyordu. Yani
/// ekranda bir defter duruyor ama defterin üstüne yazılamıyordu — bir not
/// uygulamasında yapılabilecek en ters şey.
///
/// **Bu turdaki model.**
///  * Her sayfanın bir **serbest yazı alanı** var: sayfaya dokun, yaz. Yazı
///    kâğıdın çizgilerine oturur ve kendiliğinden kaydedilir (bkz.
///    [_PageWriter]). Diyalog yok.
///  * Sayfaya **görsel / fotoğraf / PDF / sunum** doğrudan eklenir. Eskiden
///    telefonda yalnız GALERİ açılıyordu (`ImagePicker.pickMultiImage`) —
///    yani PDF ve sunum eklemek Android'de HİÇ mümkün değildi.
///  * **Son sayfadan ileri kaydırmak yeni sayfayı açar**: defterin sonunda
///    boş bir yaprak durur, üstüne yazınca (ya da dosya ekleyince) sayfa
///    gerçekten oluşur. Ad sormak için diyalog açılmaz; sayfa adı başlığa
///    dokunularak yerinde değiştirilir.
///    Boş yaprağa yazılmazsa hiçbir şey oluşmaz — yanlışlıkla kaydıran
///    kullanıcı deftere boş sayfalar biriktirmez.
///  * **Kâğıt deseni** seçilebilir: çizgili, kareli, noktalı, düz
///    (bkz. [ArchivePaper], desen defterin kaydında durur).
///
/// Arama defterin TAMAMINDA çalışır ve sonuç hangi sayfadaysa oraya götürür.
///
/// Dosyalar KOPYALANIR (kullanıcının açık tercihi): kaynak not silinse bile
/// defterdeki kopya sağlam kalır. Bedeli, dosyanın depoda iki kez yer
/// kaplaması — bkz. [copyAttachmentsToArchive].
class ArchiveNoteScreen extends ConsumerStatefulWidget {
  const ArchiveNoteScreen({super.key, required this.noteId});

  final String noteId;

  @override
  ConsumerState<ArchiveNoteScreen> createState() => _ArchiveNoteScreenState();
}

/// Defterin bir sayfasındaki tek girdi: ya bir METİN ya da bir DOSYA.
/// İkisi aynı listede akar — sayfa "bir konuya ait her şey" demek.
typedef ArchiveEntry = ({NoteItem? text, Attachment? file});

/// Defterin sayfa adları. İlk eleman her zaman boş dizedir = **Genel**
/// sayfası; kayda YAZILMAZ (uygulamanın dili değişince adı da değişsin).
List<String> archivePageNames(Note note) => ['', ...note.archivePages];

/// [page] sayfasındaki girdiler: önce metinler, sonra dosyalar (kayıttaki
/// sıralarıyla).
///
/// **ÖKSÜZ BÖLÜM GENEL'E DÜŞER.** Sayfası başka bir cihazdan silinmiş (ya da
/// eski bir sürümün yazdığı, artık var olmayan bir bölüme bağlı) girdi hiçbir
/// sayfada görünmezdi — kullanıcı için "belgem kayboldu" demek. Tanınmayan
/// bölüm adı taşıyan her girdi Genel sayfasında listelenir.
List<ArchiveEntry> archiveEntriesOf(Note note, String page) {
  return [
    for (final item in note.items)
      if (archiveOnPage(note, item.section, page)) (text: item, file: null),
    for (final a in note.attachments)
      if (archiveOnPage(note, a.section, page)) (text: null, file: a),
  ];
}

/// [section] bölüm adı taşıyan bir girdi [page] sayfasında görünür mü?
/// Genel sayfası (boş ad) hem bölümsüz hem de ÖKSÜZ girdileri toplar.
bool archiveOnPage(Note note, String section, String page) => page.isEmpty
    ? (section.isEmpty || !note.archivePages.contains(section))
    : section == page;

/// Sayfanın **serbest yazı** girdisi: kullanıcının kâğıdın üstüne yazdığı
/// metin.
///
/// Kayıtta ayrı bir alan DEĞİL, sayfanın ilk sade metin girdisi: başlığı ve
/// bağlı dosyası olmayan ilk [NoteItem]. Böylece eski defterlerin girdileri
/// göç etmeden açılır (ilk sade metin sayfanın yazısı olur, kalanı altta
/// bloklar hâlinde durur) ve yeni bir şema alanı eklemek gerekmez.
///
/// Başlıklı ya da bir dosyaya bağlı girdiler bilerek DIŞARIDA: onlar
/// kullanıcının "şu belgeye ait şu alıntı" diye ayrı ayrı kurduğu bloklar,
/// sayfanın serbest yazısına karışmamalı.
NoteItem? archivePageText(Note note, String page) {
  for (final item in note.items) {
    if (item.title.isEmpty &&
        item.attachmentId.isEmpty &&
        archiveOnPage(note, item.section, page)) {
      return item;
    }
  }
  return null;
}

/// Sayfanın serbest yazısı ve SAYFADA YÜZEN görselleri dışında kalan
/// girdiler (dosya ekleri + başlıklı ya da bir dosyaya bağlı metin blokları).
List<ArchiveEntry> archivePageExtras(Note note, String page) {
  final writing = archivePageText(note, page);
  return [
    for (final entry in archiveEntriesOf(note, page))
      if (entry.file != null
          ? !entry.file!.floatsOnPage
          : (writing == null || entry.text!.id != writing.id))
        entry,
  ];
}

/// Sayfada YÜZEN görsel/videolar — metin bunların etrafından akar ve
/// kullanıcı yerlerini/boyutlarını değiştirebilir (bkz. [NotePageCanvas]).
///
/// Kullanıcı isteği 2026-09-02: "görsel eklendiğinde normal not sayfamız gibi
/// metin etrafından akabilmeli, yeri değiştirilebilmeli". Eski defterlerdeki
/// görseller `asFile: true` ile eklendiği için sayfada yüzmez, alttaki dosya
/// listesinde durur; girdinin ⋮ menüsündeki "Sayfaya yerleştir" onları
/// tuvale taşır.
List<Attachment> archivePageFloats(Note note, String page) => [
  for (final a in note.attachments)
    if (a.floatsOnPage && archiveOnPage(note, a.section, page)) a,
];

/// Defterin ilk sayfasının adı: kullanıcı verdiyse o, yoksa dilden gelen
/// "Genel" ([fallback]).
String archiveGeneralLabel(Note note, String fallback) =>
    note.archiveGeneralName.trim().isEmpty ? fallback : note.archiveGeneralName;

/// Kendiliğinden açılan sayfanın adı: "Sayfa 3" (Genel dahil kaçıncı yaprak
/// olacaksa o). Aynı ad zaten varsa numara ilerletilir — ad, girdileri
/// sayfaya bağlayan ANAHTAR olduğu için iki sayfa aynı adı taşıyamaz.
String archiveAutoPageName(Note note, String Function(int) label) {
  final taken = note.archivePages.toSet();
  var number = note.archivePages.length + 2;
  while (taken.contains(label(number))) {
    number++;
  }
  return label(number);
}

/// Sayfa henüz açılmamışsa (defterin sonundaki boş yaprak) kayda ekler.
/// Genel sayfası (boş ad) hiçbir zaman yazılmaz — adı kayda değil dile ait.
Note archiveWithPage(Note note, String page) =>
    page.isEmpty || note.archivePages.contains(page)
    ? note
    : note.copyWith(archivePages: [...note.archivePages, page]);

/// Sayfanın **serbest yazısını** kayda uygular ve yeni kaydı döndürür.
/// Değişiklik yoksa AYNI [note] örneği döner (çağıran yazımı atlar).
///
/// Kural saf bir işlev, çünkü içinde üç tuzak var ve üçü de testle
/// ölçülüyor:
///  1. **Sayfa yoksa AÇILIR.** Defterin sonundaki boş yaprağa yazmak sayfayı
///     da oluşturur — "yeni sayfa" diyalogu bu yüzden kalktı.
///  2. **İKİZLENME.** İlk harfte girdi henüz kayıtta yok; çağıran o yüzden
///     ürettiği kimliği hatırlıyor (bkz. `_writerIds`). O kimlik kayıtta
///     ZATEN varsa — girdi arada başka bir sayfaya taşınmış olabilir —
///     ikinci bir girdi AÇILMAZ: var olan girdi bu sayfaya taşınıp
///     güncellenir.
///  3. **Boşaltmak SİLER.** Metni tümüyle silen kullanıcı girdiyi de silmiş
///     olur; boş bir girdi defterde görünmez ama aramada ve dışa aktarımda
///     çöp olarak dolaşırdı.
Note archiveWriteText(
  Note note, {
  required String page,
  required String text,
  required String id,
}) {
  final existing = archivePageText(note, page);
  final trimmed = text.trim();
  if (existing == null) {
    if (trimmed.isEmpty) return note;
    final base = archiveWithPage(note, page);
    if (base.items.any((i) => i.id == id)) {
      return base.copyWith(
        items: [
          for (final i in base.items)
            if (i.id == id) i.copyWith(text: text, section: page) else i,
        ],
      );
    }
    return base.copyWith(
      items: [
        ...base.items,
        NoteItem(id: id, text: text, section: page),
      ],
    );
  }
  if (existing.text == text) return note;
  if (trimmed.isEmpty) {
    return note.copyWith(
      items: [
        for (final i in note.items)
          if (i.id != existing.id) i,
      ],
    );
  }
  return note.copyWith(
    items: [
      for (final i in note.items)
        if (i.id == existing.id) i.copyWith(text: text) else i,
    ],
  );
}

class _ArchiveNoteScreenState extends ConsumerState<ArchiveNoteScreen> {
  /// Sayfa numaraları burada; `PageController` kaydırma konumunu tutar.
  late final PageController _pageController = PageController();

  /// O an açık sayfanın numarası (0 = Genel). `PageController.page` yalnız
  /// yerleşimden sonra okunabildiği için ayrıca saklanır.
  int _page = 0;

  final _searchController = TextEditingController();
  bool _searching = false;
  bool _busy = false;

  /// Sayfa adı → o sayfanın serbest yazısı için ÜRETİLEN girdi kimliği.
  ///
  /// İlk harfte girdi henüz kayıtta yok ve iki kayıt arasında Firestore
  /// akışı geri dönmemiş olabiliyor. Kimlik burada tutulmasa ikinci yazım
  /// aynı yazıyı İKİNCİ bir girdi olarak eklerdi (bkz. [_saveWriting]).
  final _writerIds = <String, String>{};

  /// Kaydın ve deponun EN SON hâli — her build'de tazelenir.
  ///
  /// KÖK NEDEN: yazı alanı ağaçtan düşerken bekleyen kaydı yazıyor
  /// ([_PageWriter.dispose] → `Debouncer.flush`). O an ekran da kapanıyor
  /// olabiliyor ve `ref.read` "kapatılmış bir ref" hatası veriyordu — yani
  /// sayfayı kapatırken yazılan SON cümle kaybolurdu. Kayıt yolu artık
  /// `ref`e hiç dokunmuyor, build'de alınmış bu iki değeri kullanıyor.
  Note? _liveNote;
  NotesRepository? _liveRepo;

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    for (final node in _writerFocus.values) {
      node.dispose();
    }
    for (final node in _titleFocus.values) {
      node.dispose();
    }
    for (final controller in _scrolls.values) {
      controller.dispose();
    }
    for (final controller in _writers.values) {
      controller.dispose();
    }
    _styleDebounce.dispose();
    super.dispose();
  }

  String get _query => _searchController.text.trim().toLowerCase();

  NotesRepository? get _repo => _liveRepo;

  String _pageLabel(String name) {
    if (name.isNotEmpty) return name;
    final note = _note;
    final fallback = context.l10n.archiveGeneralPage;
    return note == null ? fallback : archiveGeneralLabel(note, fallback);
  }

  static bool _matches(String text, String query) =>
      text.toLowerCase().contains(query);

  /// Aramanın sonucu: eşleşen girdiler ve her birinin SAYFA numarası.
  ///
  /// **PERFORMANS**: eskiden her SAYFA için defterin bütün girdileri
  /// süzülüyordu (`archiveEntriesOf` sayfa sayısı kadar kez) — yani maliyet
  /// girdi × sayfa idi ve bu, aramada her tuş vuruşunda ödeniyordu. Artık
  /// girdiler bir kez geziliyor, sayfa numarası bölüm adından haritayla
  /// bulunuyor. Sonuç yine SAYFA SIRASINDA gösteriliyor (kararlı sıralama).
  List<({ArchiveEntry entry, int page})> _searchHits(Note note) {
    final query = _query;
    if (query.isEmpty) return const [];
    final names = archivePageNames(note);
    final pageOf = {for (var i = 0; i < names.length; i++) names[i]: i};
    // Tanınmayan (öksüz) bölüm Genel sayfasında listelenir — sayfayı
    // süzen kuralla aynı (bkz. [archiveOnPage]).
    int index(String section) => pageOf[section] ?? 0;
    final hits = [
      for (final item in note.items)
        if (_matches('${item.title}\n${item.text}', query))
          (entry: (text: item, file: null), page: index(item.section)),
      for (final a in note.attachments)
        if (_matches(a.fileName, query))
          (entry: (text: null, file: a), page: index(a.section)),
    ];
    hits.sort((a, b) => a.page.compareTo(b.page));
    return hits;
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Kaydı değiştirir. Değişiklik HER ZAMAN kaydın en son hâline uygulanır
  /// ([_note]), çağıranın elindeki kopyaya değil.
  ///
  /// KÖK NEDEN: sayfa gövdeleri önbelleğe alınıyor (bkz. [_cachedPageBody])
  /// ve önbellekteki satır geri çağrıları ESKİ bir [Note] örneğini
  /// kapanışlarında tutuyor. O kopyanın üstüne yazmak, arada başka bir
  /// sayfaya eklenmiş dosyayı ya da yazılmış satırı geri alırdı. Aynı tuzak
  /// yazarken de vardı: yazı 600 ms'de bir kaydediliyor ve build'in
  /// kapanışındaki kopya bir kayıt geride kalabiliyor.
  Future<void> _mutate(Note Function(Note) change) async {
    final repo = _repo;
    final note = _note;
    if (repo == null || note == null) return;
    await repo.updateNote(change(note));
  }

  /// Kaydın O ANKİ hâli. Yazma akışları build'in kapanışındaki kopyayı değil
  /// bunu kullanır: kullanıcı yazarken kayıt saniyede birden çok kez
  /// güncelleniyor ve bayat bir kopyanın üstüne yazmak arada eklenen bir
  /// dosyayı geri alırdı.
  Note? get _note => _liveNote;

  /// Sayfaya git ama BİR KARE SONRA.
  ///
  /// Yeni sayfa açan akışlar kaydı yazdıktan hemen sonra oraya gitmek ister;
  /// oysa sayfa listesi Firestore akışından geri geldiğinde büyür. Aynı
  /// karede atlanırsa [PageView] henüz o sayfayı tanımıyor ve atlama son
  /// sayfada takılıyor.
  void _goToPageSoon(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _goToPage(index);
    });
  }

  /// Sayfaya git (çevirme animasyonuyla).
  void _goToPage(int index) {
    if (!_pageController.hasClients) {
      setState(() => _page = index);
      return;
    }
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOut,
    );
  }

  // ————————————————————————————————— SAYFA İŞLERİ

  /// Sayfayı yeniden adlandırır; girdilerin bağı da yeni ada taşınır.
  ///
  /// [current] henüz açılmamış bir sayfaysa (defterin sonundaki boş yaprak)
  /// sayfa doğrudan YENİ ADIYLA açılır: başlığa yazmak "bu sayfayı istiyorum"
  /// demektir.
  /// Kayda YAZILDIYSA true döner; ad boş/çakışmışsa false — başlık alanı o
  /// zaman eski ada geri döner (aksi hâlde başlıkta var olmayan bir sayfa
  /// adı yazılı kalırdı).
  Future<bool> _renamePage(String current, String name) async {
    final note = _note;
    if (note == null) return false;
    final trimmed = name.trim();
    if (trimmed.isEmpty ||
        trimmed == current ||
        current.isEmpty ||
        note.archivePages.contains(trimmed)) {
      return false;
    }
    if (!note.archivePages.contains(current)) {
      await _mutate((n) => archiveWithPage(n, trimmed));
      return true;
    }
    await _mutate(
      (n) => n.copyWith(
        archivePages: [
          for (final page in n.archivePages)
            if (page == current) trimmed else page,
        ],
        // Bölüm adı GİRDİNİN üzerinde saklandığı için ad değişince bağlar da
        // taşınmalı; taşınmazsa sayfa boşalır ve girdiler Genel'e düşerdi.
        items: [
          for (final i in n.items)
            if (i.section == current) i.copyWith(section: trimmed) else i,
        ],
        attachments: [
          for (final a in n.attachments)
            if (a.section == current) a.copyWith(section: trimmed) else a,
        ],
      ),
    );
    // Yazı girdisinin kimliği ESKİ adla eşlenmişti; ad değişince taşınır,
    // yoksa aynı sayfaya ikinci bir yazı girdisi açılabilirdi.
    final writerId = _writerIds.remove(current);
    if (writerId != null) _writerIds[trimmed] = writerId;
    return true;
  }

  /// İlk sayfanın (bölümsüz girdilerin sayfası) ADINI değiştirir.
  ///
  /// Girdilere DOKUNULMAZ: ad yalnız görünendir (bkz.
  /// [Note.archiveGeneralName]). Boş ad "Genel"e döner — kullanıcı adı
  /// silerek varsayılana dönebilsin.
  Future<bool> _renameGeneral(String name) async {
    final note = _note;
    if (note == null) return false;
    final trimmed = name.trim();
    if (trimmed == note.archiveGeneralName) return false;
    // Aynı adı taşıyan bir sayfa varsa reddedilir: alt çubuk ve sayfa
    // listesi iki farklı sayfayı aynı adla gösterirdi.
    if (trimmed.isNotEmpty && note.archivePages.contains(trimmed)) return false;
    await _mutate((n) => n.copyWith(archiveGeneralName: trimmed));
    return true;
  }

  /// Sayfayı siler. **Girdiler SİLİNMEZ**, Genel sayfasına taşınır: bir
  /// sayfayı kaldırmak "bu başlığı istemiyorum" demektir, "bu belgeleri
  /// istemiyorum" demek değil.
  Future<void> _deletePage(String name) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.archiveDeletePage),
        content: Text(l10n.archiveDeletePageInfo(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _mutate(
      (n) => n.copyWith(
        archivePages: [
          for (final page in n.archivePages)
            if (page != name) page,
        ],
        items: [
          for (final i in n.items)
            if (i.section == name) i.copyWith(section: '') else i,
        ],
        attachments: [
          for (final a in n.attachments)
            if (a.section == name) a.copyWith(section: '') else a,
        ],
      ),
    );
    _writerIds.remove(name);
    if (mounted) _goToPage(0);
  }

  /// **KÂĞIT levhası**: rengi ve deseni (çizgili / kareli / noktalı / düz).
  ///
  /// Biçim çubuğundaki "sayfa görünümü" düğmesi de buraya çıkar — defterde
  /// sayfanın görünümü kâğıdın kendisidir.
  Future<void> _paperSheet(Note note) async {
    final l10n = context.l10n;
    String label(ArchivePaper paper) => switch (paper) {
      ArchivePaper.lined => l10n.archivePaperLined,
      ArchivePaper.grid => l10n.archivePaperGrid,
      ArchivePaper.dots => l10n.archivePaperDots,
      ArchivePaper.plain => l10n.archivePaperPlain,
    };
    // null = desen seçilmedi; `pickedColor` = renk şeridi istendi.
    const pickedColor = 'color';
    final picked = await showModalBottomSheet<Object>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: NoteColors.surface(sheetContext, note.color),
                ),
                title: Text(sheetContext.l10n.backgroundColor),
                onTap: () => Navigator.pop(sheetContext, pickedColor),
              ),
              const Divider(height: 1),
              // `RadioListTile.groupValue`/`onChanged` KULLANILMAZ
              // (kullanımdan kalktı): seçili değer ve geri çağrı dıştaki
              // [RadioGroup]'tan gelir — ayarlardaki dil seçicisiyle aynı
              // desen.
              RadioGroup<ArchivePaper>(
                groupValue: note.archivePaper,
                onChanged: (value) => Navigator.pop(sheetContext, value),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final paper in ArchivePaper.values)
                      RadioListTile<ArchivePaper>(
                        value: paper,
                        title: Text(label(paper)),
                        // Desenin KENDİSİ örneklenir: adları okumak yerine
                        // bakıp seçmek defterde çok daha hızlı.
                        secondary: SizedBox(
                          width: 44,
                          height: 34,
                          child: _PaperSwatch(
                            paper: paper,
                            color: NoteColors.surface(sheetContext, note.color),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || picked == null) return;
    if (picked == pickedColor) {
      // KÂĞIDIN RENGİ notun rengidir (defterin zeminini zaten o çiziyor):
      // ortak renk şeridi kullanılır, seçim canlı uygulanır.
      await showNoteColorPicker(
        context,
        frame: false,
        current: note.color,
        onChanged: (color) =>
            unawaited(_mutate((n) => n.copyWith(color: color))),
      );
      return;
    }
    if (picked is! ArchivePaper || picked == note.archivePaper) return;
    await _mutate((n) => n.copyWith(archivePaper: picked));
  }

  // ————————————————————————————————— YAZI

  /// Sayfanın serbest yazısını kaydeder (bkz. [archivePageText]).
  ///
  /// Yazı alanı kendi içinde geciktirilmiş kaydediyor ([_PageWriter]); burası
  /// yalnız kaydı günceller. Metin tamamen silinirse girdi de silinir: boş
  /// bir metin girdisi defterde görünmez ama aramada ve dışa aktarımda
  /// çöp olarak dolaşırdı.
  Future<void> _saveWriting(String page, String text) async {
    // BİLEREK `mounted` kontrolü yok: bu çağrı çoğu zaman ekran kapanırken,
    // yazı alanı ağaçtan düşerken geliyor (bkz. [_liveNote]) — o an yazmayı
    // atlamak son cümleyi kaybetmek demek.
    final note = _note;
    final repo = _repo;
    if (note == null || repo == null) return;
    // Kimlik sayfaya göre HATIRLANIR: kural içindeki ikizlenme koruması
    // ancak aynı kimlikle çağrıldığında işe yarar (bkz. [archiveWriteText]).
    final id = _writerIds[page] ??= const Uuid().v4();
    final next = archiveWriteText(note, page: page, text: text, id: id);
    if (identical(next, note)) return;
    // Yazı silindiyse kimlik de bırakılır: sonra yazılan metin YENİ bir
    // girdi olsun (silinen girdinin kimliğini geri diriltmek, başka bir
    // cihazda o kimliği silmiş olan yazımla çakışırdı).
    if (text.trim().isEmpty) _writerIds.remove(page);
    await repo.updateNote(next);
  }

  // ————————————————————————————————— GİRDİ İŞLERİ

  /// **Başlıklı not bloğu** ekler/düzenler (açık sayfaya).
  ///
  /// Sayfanın serbest yazısından AYRI bir şey: başlığı olan ve istenirse bir
  /// dosyaya BAĞLANAN blok (kullanıcı isteği 2026-08-16: "metinler görsel veya
  /// belge ile bağlanabilmeli… hepsinin başlığı ayarlanabilmeli") — bir
  /// alıntının hangi belgeden geldiği defterde kaybolmasın.
  Future<void> _editText(Note note, String page, {NoteItem? existing}) async {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final textController = TextEditingController(text: existing?.text ?? '');
    var linkedId = existing?.attachmentId ?? '';

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final l10n = dialogContext.l10n;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(l10n.archiveAddText),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: titleController,
                    autofocus: existing == null,
                    decoration: InputDecoration(
                      labelText: l10n.archiveEntryTitle,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: textController,
                    maxLines: 8,
                    minLines: 3,
                    decoration: InputDecoration(
                      labelText: l10n.archiveCaptureText,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // BAĞLI DOSYA: defterdeki eklerden biri seçilir. Yeni dosya
                  // yüklemek ayrı bir iş (levhadaki "PDF"/"Görsel"); burada
                  // yalnız VAR OLANA bağlanır, yoksa aynı dosya iki kez
                  // yüklenirdi.
                  DropdownButtonFormField<String>(
                    initialValue: linkedId.isEmpty ? '' : linkedId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: l10n.archiveLinkedFile,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: '',
                        child: Text(l10n.archiveNoLink),
                      ),
                      for (final a in note.attachments)
                        DropdownMenuItem(
                          value: a.id,
                          child: Text(
                            a.fileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (value) =>
                        setDialogState(() => linkedId = value ?? ''),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(l10n.ok),
              ),
            ],
          ),
        );
      },
    );
    final title = titleController.text.trim();
    final text = textController.text.trim();
    titleController.dispose();
    textController.dispose();
    if (saved != true || (text.isEmpty && title.isEmpty)) return;

    await _mutate((n) {
      if (existing != null) {
        return n.copyWith(
          items: [
            for (final i in n.items)
              if (i.id == existing.id)
                i.copyWith(text: text, title: title, attachmentId: linkedId)
              else
                i,
          ],
        );
      }
      // Başlıksız ve bağsız bir blok, sayfanın SERBEST YAZISI ile aynı şey
      // olurdu (bkz. [archivePageText]) — başlık boşsa metnin ilk satırı
      // başlık yapılır ki blok kendi kimliğini korusun.
      final blockTitle = title.isNotEmpty
          ? title
          : text.split('\n').first.trim();
      final base = archiveWithPage(n, page);
      return base.copyWith(
        items: [
          ...base.items,
          NoteItem(
            id: const Uuid().v4(),
            text: text,
            title: blockTitle,
            attachmentId: linkedId,
            section: page,
          ),
        ],
      );
    });
  }

  /// Ekin defterdeki ADINI değiştirir (dosya adı = girdinin başlığı).
  Future<void> _renameAttachment(Attachment attachment) async {
    final name = await _askName(
      title: context.l10n.archiveEntryTitle,
      hint: context.l10n.archiveEntryTitle,
      initial: attachment.fileName,
    );
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty || trimmed == attachment.fileName) return;
    // YALNIZ görünen ad değişir; dosyanın kendisi (yerel yol, depo yolu)
    // olduğu gibi kalır — yeniden adlandırma yükleme kuyruğunu tetiklemesin.
    await _mutate(
      (n) => n.copyWith(
        attachments: [
          for (final a in n.attachments)
            if (a.id == attachment.id) a.copyWith(fileName: trimmed) else a,
        ],
      ),
    );
  }

  /// Tek satırlık ad soran ortak diyalog (ek adı).
  Future<String?> _askName({
    required String title,
    required String hint,
    String initial = '',
  }) async {
    final controller = TextEditingController(text: initial);
    try {
      return await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(hintText: hint),
            onSubmitted: (value) => Navigator.pop(dialogContext, value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(dialogContext.l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, controller.text),
              child: Text(dialogContext.l10n.ok),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  /// Girdiyi BAŞKA bir sayfaya taşır (metin ya da dosya).
  Future<void> _moveEntry(Note note, ArchiveEntry entry) async {
    final names = archivePageNames(note);
    final target = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final name in names)
              ListTile(
                leading: Icon(
                  name.isEmpty
                      ? Icons.auto_stories_outlined
                      : Icons.bookmark_outline,
                ),
                title: Text(_pageLabel(name)),
                onTap: () => Navigator.pop(sheetContext, name),
              ),
          ],
        ),
      ),
    );
    if (target == null) return;
    await _mutate((n) {
      final item = entry.text;
      if (item != null) {
        return n.copyWith(
          items: [
            for (final i in n.items)
              if (i.id == item.id) i.copyWith(section: target) else i,
          ],
        );
      }
      final file = entry.file!;
      return n.copyWith(
        attachments: [
          for (final a in n.attachments)
            if (a.id == file.id) a.copyWith(section: target) else a,
        ],
      );
    });
  }

  /// **Görselden yakala**: ekran görüntüsünü OCR'lar, metni yapay zekâya
  /// düzelttirir, türünü tahmin ettirir ve deftere kaydeder.
  ///
  /// Akış bilerek bu sırada:
  ///  1. **OCR cihazda** ([ScanOcr]) — bedava, çevrimdışı, kotasız.
  ///  2. Metin çıkmadıysa DURULUR: modele boş metin göndermek kotayı boşa
  ///     yakar (görselde yazı yoksa yapılacak bir şey yok).
  ///  3. Model metni düzeltir ve türü söyler ([GeminiService.tidyCapture]);
  ///     tür, defterin var olan sayfalarından biriyse oraya, değilse yeni
  ///     bir sayfa olarak açılır.
  ///  4. Sonuç ONAYA sunulur — model metni değiştirebiliyor ve sayfa açmak
  ///     kalıcı bir karar; sessizce kaydetmek yanlış yere düşen girdilerle
  ///     defteri kirletirdi.
  ///
  /// Görselin kendisi de deftere KOPYALANIR: metin yanlış çıkarsa kaynağa
  /// bakmanın tek yolu odur.
  Future<void> _captureFromImage(Note note, String page) async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return;
    if (!ScanOcr.supported) {
      _snack(context.l10n.imageOcrNone);
      return;
    }
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 2400,
      maxHeight: 2400,
    );
    if (picked == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final lines = await ScanOcr.recognizeImageLines(picked.path);
      final raw = [for (final line in lines) line.text].join('\n').trim();
      if (raw.isEmpty) {
        if (!mounted) return;
        setState(() => _busy = false);
        _snack(context.l10n.imageOcrNone);
        return;
      }
      final tidied = await ref
          .read(geminiServiceProvider)
          .tidyCapture(raw, known: note.archivePages);
      if (!mounted) return;
      setState(() => _busy = false);
      await _confirmCapture(
        note,
        page: page,
        suggestion: tidied,
        imageBytes: await picked.readAsBytes(),
        imageName: picked.name,
      );
    } on GeminiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _snack(e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _snack(context.l10n.aiError('$e'));
    }
  }

  /// Yakalanan metni ve önerilen sayfayı onaya sunar, onaylanırsa kaydeder.
  Future<void> _confirmCapture(
    Note note, {
    required String page,
    required ({String category, String title, String text}) suggestion,
    required Uint8List imageBytes,
    required String imageName,
  }) async {
    final textController = TextEditingController(text: suggestion.text);
    final pageController = TextEditingController(
      text: suggestion.category.isEmpty ? page : suggestion.category,
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final l10n = dialogContext.l10n;
        return AlertDialog(
          title: Text(l10n.archiveCaptureTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: pageController,
                  decoration: InputDecoration(
                    labelText: l10n.archiveCapturePage,
                    helperText: l10n.archiveCapturePageInfo,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: textController,
                  maxLines: 10,
                  minLines: 4,
                  decoration: InputDecoration(
                    labelText: l10n.archiveCaptureText,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.ok),
            ),
          ],
        );
      },
    );
    final text = textController.text.trim();
    final target = pageController.text.trim();
    textController.dispose();
    pageController.dispose();
    if (confirmed != true || text.isEmpty || !mounted) return;

    setState(() => _busy = true);
    Attachment? stored;
    try {
      stored = await ref
          .read(attachmentRepositoryProvider)
          ?.prepareImage(
            noteId: note.id,
            bytes: imageBytes,
            fileName: imageName,
          );
    } catch (_) {
      // Görsel eklenemese de (çok büyük, depo dolu) METİN kaydedilsin:
      // yakalamanın asıl değeri yazıda.
    }
    if (!mounted) return;
    setState(() => _busy = false);
    await _mutate((n) {
      final base = archiveWithPage(n, target);
      return base.copyWith(
        items: [
          ...base.items,
          // Yakalanan metin başlıklı bir BLOK: sayfanın serbest yazısının
          // içine karışmaz (bkz. [archivePageText]).
          NoteItem(
            id: const Uuid().v4(),
            text: text,
            title: suggestion.title.trim().isNotEmpty
                ? suggestion.title.trim()
                : text.split('\n').first.trim(),
            section: target,
          ),
        ],
        attachments: stored == null
            ? base.attachments
            : [
                ...base.attachments,
                stored.copyWith(asFile: true, section: target),
              ],
      );
    });
    if (!mounted) return;
    // Girdi hangi sayfaya düştüyse oraya çevrilir: kullanıcı az önce
    // kaydettiği şeyi görmeli. Model YENİ bir sayfa önerdiyse o sayfa
    // listenin sonuna eklendi.
    final names = [
      '',
      ...note.archivePages,
      if (target.isNotEmpty && !note.archivePages.contains(target)) target,
    ];
    final index = names.indexOf(target);
    _goToPageSoon(index < 0 ? 0 : index);
  }

  // ————————————————————————————————— DOSYA EKLEME

  /// Galeriden (masaüstünde diskten) GÖRSEL seçip açık sayfaya kopyalar.
  Future<void> _addImages(String page) async {
    final files = <({String name, Uint8List bytes})>[];
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      final picked = await ImagePicker().pickMultiImage(
        maxWidth: 2400,
        maxHeight: 2400,
      );
      for (final file in picked) {
        files.add((name: file.name, bytes: await file.readAsBytes()));
      }
    } else {
      const group = XTypeGroup(
        label: 'Görseller',
        extensions: ['jpg', 'jpeg', 'png', 'webp', 'gif'],
      );
      for (final file in await openFiles(acceptedTypeGroups: const [group])) {
        files.add((name: file.name, bytes: await file.readAsBytes()));
      }
    }
    await _storeFiles(page, files);
  }

  /// Kamerayla fotoğraf çekip açık sayfaya koyar.
  Future<void> _takePhoto(String page) async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return;
    // Manifest'te CAMERA bildirildiği için Android çekim niyetini izin
    // olmadan REDDEDER.
    final perms = ref.read(permissionsServiceProvider);
    if (!await perms.cameraGranted() && !await perms.requestCamera()) {
      if (mounted) _snack(context.l10n.permCameraInfo);
      return;
    }
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 2400,
      maxHeight: 2400,
    );
    if (picked == null) return;
    await _storeFiles(page, [
      (name: picked.name, bytes: await picked.readAsBytes()),
    ]);
  }

  /// **PDF ekler** (kullanıcı isteği 2026-09-01: "PDF eklenebilmeli").
  ///
  /// Telefonda [DocPicker] üzerinden: `file_selector`ın Android yolu yalnız
  /// belge sağlayıcılarını gösteriyor, kullanıcının dosya yöneticisi listeye
  /// hiç düşmüyordu (gerekçe orada).
  Future<void> _addPdf(String page) async {
    const group = XTypeGroup(
      label: 'PDF',
      extensions: ['pdf'],
      mimeTypes: ['application/pdf'],
    );
    final files = <({String name, Uint8List bytes})>[];
    for (final file in await DocPicker.pickMany(group)) {
      files.add((name: file.name, bytes: await file.readAsBytes()));
    }
    await _storeFiles(page, files);
  }

  /// **Sunum (pptx) ekler** (kullanıcı isteği 2026-09-01: "slayt
  /// eklenebilmeli").
  Future<void> _addSlide(String page) async {
    const group = XTypeGroup(
      label: 'Sunum',
      extensions: ['pptx'],
      // Android dosya seçici uzantı yerine MIME'a bakar; yalnız `extensions`
      // verilirse PowerPoint dosyaları soluk (seçilemez) görünür.
      mimeTypes: [
        'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      ],
    );
    final file = await DocPicker.pickOne(group);
    if (file == null) return;
    await _storeFiles(page, [
      (name: file.name, bytes: await file.readAsBytes()),
    ]);
  }

  /// **Çizim**: editörün çizim ekranını açar, sonucu sayfaya görsel olarak
  /// koyar (yüzen, sürüklenebilir).
  Future<void> _addDrawing(String page) async {
    final bytes = await Navigator.of(
      context,
    ).push<Uint8List>(MaterialPageRoute(builder: (_) => const DrawingScreen()));
    if (bytes == null) return;
    await _storeFiles(page, [(name: 'cizim.png', bytes: bytes)]);
  }

  /// Seçilen dosyaları türlerine göre hazırlayıp sayfaya ekler.
  ///
  /// Sayfa henüz açılmamışsa (defterin sonundaki boş yaprak) AYNI yazımda
  /// açılır: dosya eklemek de "bu sayfayı istiyorum" demektir.
  Future<void> _storeFiles(
    String page,
    List<({String name, Uint8List bytes})> files,
  ) async {
    // Web'de dosya deposu yok (ek yerel bir kopya olarak hazırlanıyor):
    // eski akış da web'de sessizce çıkıyordu.
    if (kIsWeb || files.isEmpty || !mounted) return;
    final repo = ref.read(attachmentRepositoryProvider);
    final note = _note;
    if (repo == null || note == null) return;

    // Büyük belge (PDF/sunum) sıkıştırılamaz ve doğrudan depo kotasına
    // gider: engellemek yerine boyutu söyleyip kullanıcıya soruluyor.
    final heavy = files.where(
      (f) => f.bytes.length > AppConstants.largeAttachmentWarnBytes,
    );
    if (heavy.isNotEmpty) {
      final mb = (heavy.first.bytes.length / (1024 * 1024)).toStringAsFixed(1);
      final proceed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(dialogContext.l10n.largeAttachmentTitle),
          content: Text(dialogContext.l10n.largeAttachmentBody(mb)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(dialogContext.l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(dialogContext.l10n.ok),
            ),
          ],
        ),
      );
      if (proceed != true || !mounted) return;
    }

    setState(() => _busy = true);
    final added = <Attachment>[];
    FileTooLargeException? tooLarge;
    Object? failure;
    for (final file in files) {
      try {
        final extension = p.extension(file.name).toLowerCase();
        final stored = switch (extension) {
          '.pdf' => await repo.preparePdf(
            noteId: note.id,
            bytes: file.bytes,
            fileName: file.name,
          ),
          '.pptx' => await repo.prepareSlide(
            noteId: note.id,
            bytes: file.bytes,
            fileName: file.name,
          ),
          _ => await repo.prepareImage(
            noteId: note.id,
            bytes: file.bytes,
            fileName: file.name,
          ),
        };
        // **GÖRSEL SAYFADA YÜZER** (kullanıcı isteği 2026-09-02: "görsel
        // eklendiğinde normal not sayfamız gibi metin etrafından
        // akabilmeli, yeri değiştirilebilmeli"): eskiden defterdeki her ek
        // `asFile: true` ile ekleniyor, yani sayfaya değil alttaki dosya
        // listesine giriyordu. Belgeler (PDF/sunum) listede kalır — onlar
        // sayfada gösterilemez.
        final onPage = stored.kind == AttachmentKind.image;
        added.add(
          onPage
              ? _placeOnPage(
                  stored.copyWith(asFile: false, section: page),
                  note,
                  placed: added,
                )
              : stored.copyWith(asFile: true, section: page),
        );
      } on FileTooLargeException catch (e) {
        // Tek dosya tavana takılsa da kalanlar eklensin; sebep sonda
        // söylenir — eskiden hata sessizce yutuluyor, dosya "eklenmiyor"
        // ama neden eklenmediği hiçbir yerde yazmıyordu.
        tooLarge = e;
      } catch (e) {
        failure = e;
      }
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (added.isNotEmpty) {
      await _mutate((n) {
        final base = archiveWithPage(n, page);
        return base.copyWith(attachments: [...base.attachments, ...added]);
      });
    }
    if (!mounted) return;
    if (tooLarge != null) {
      _snack(_tooLargeMessage(tooLarge));
    } else if (failure != null) {
      _snack(context.l10n.attachmentFailed('$failure'));
    }
  }

  String _tooLargeMessage(FileTooLargeException error) {
    if (error is StorageFullException) {
      return context.l10n.storageFull(formatBytes(error.quotaBytes));
    }
    final premium = ref.read(premiumProvider).value ?? false;
    final limitMb =
        (premium
            ? AppConstants.maxPremiumAttachmentBytes
            : AppConstants.maxFreeAttachmentBytes) ~/
        (1024 * 1024);
    return context.l10n.attachmentTooLarge(limitMb);
  }

  Future<void> _removeAttachment(Attachment attachment) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.l10n.delete),
        content: Text(
          dialogContext.l10n.archiveDeleteEntry(attachment.fileName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(dialogContext.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(dialogContext.l10n.delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref
        .read(attachmentRepositoryProvider)
        ?.deleteFromStorage(attachment)
        .catchError((Object _) {});
    await _mutate(
      (n) => n.copyWith(
        attachments: [
          for (final a in n.attachments)
            if (a.id != attachment.id) a,
        ],
      ),
    );
  }

  Future<void> _removeItem(NoteItem item) => _mutate(
    (n) => n.copyWith(
      items: [
        for (final i in n.items)
          if (i.id != item.id) i,
      ],
    ),
  );

  /// Eki kendi görüntüleyicisinde açar. Dosya cihazda yoksa ve buluta da
  /// yüklenmediyse boş bir ekran açmak yerine sebebi söylenir.
  void _open(Attachment attachment) {
    if (attachment.kind == AttachmentKind.audio) return;
    if (!localFileExists(attachment.localPath) && !attachment.isUploaded) {
      _snack(context.l10n.attachmentNotSynced);
      return;
    }
    if (attachment.kind == AttachmentKind.image) {
      openImageViewer(context, attachment, (_) {});
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => switch (attachment.kind) {
          AttachmentKind.pdf => PdfViewerScreen(attachment: attachment),
          AttachmentKind.slide => SlideViewerScreen(attachment: attachment),
          _ => VideoViewerScreen(attachment: attachment),
        },
      ),
    );
  }

  /// Alt çubuktaki "+": sayfaya ne ekleneceğini soran levha.
  ///
  /// **Metin buradan KALKTI**: sayfaya doğrudan yazılıyor (bkz.
  /// [_PageWriter]). Levhada yalnız yazıyla yapılamayan işler duruyor.
  Future<void> _addSheet(Note note, String page) async {
    final l10n = context.l10n;
    final mobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      // Levha KAYDIRILIR: yedi seçenek kısa ekranda (yatay tutulan telefon,
      // küçük pencere) taşıyordu — widget testi taşmayı yakaladı.
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.image_outlined),
                title: Text(l10n.addImage),
                subtitle: Text(_pageLabel(page)),
                onTap: () => Navigator.pop(sheetContext, 'image'),
              ),
              if (mobile)
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: Text(l10n.takePhoto),
                  onTap: () => Navigator.pop(sheetContext, 'camera'),
                ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined),
                title: Text(l10n.addPdf),
                onTap: () => Navigator.pop(sheetContext, 'pdf'),
              ),
              ListTile(
                leading: const Icon(Icons.slideshow_outlined),
                title: Text(l10n.addSlide),
                onTap: () => Navigator.pop(sheetContext, 'slide'),
              ),
              if (mobile)
                ListTile(
                  leading: const Icon(Icons.document_scanner_outlined),
                  title: Text(l10n.archiveCaptureTitle),
                  onTap: () => Navigator.pop(sheetContext, 'capture'),
                ),
              // ÇİZİM de defterde (kullanıcı isteği 2026-09-02: "sanki arşiv
              // defteri farklı bir uygulama gibi, hiçbir özelliğimiz yok
              // orada, hepsi olmalı"): editördeki aynı ekran açılır, sonuç
              // sayfada YÜZEN bir görsel olur.
              ListTile(
                leading: const Icon(Icons.brush_outlined),
                title: Text(l10n.addDrawing),
                onTap: () => Navigator.pop(sheetContext, 'drawing'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.post_add),
                title: Text(l10n.archiveAddText),
                subtitle: Text(l10n.archiveLinkedFile),
                onTap: () => Navigator.pop(sheetContext, 'text'),
              ),
              ListTile(
                leading: const Icon(Icons.library_add_outlined),
                title: Text(l10n.archiveNewPage),
                subtitle: Text(l10n.archiveNewPageHint),
                onTap: () => Navigator.pop(sheetContext, 'page'),
              ),
            ],
          ),
        ),
      ),
    );
    if (action == null || !mounted) return;
    switch (action) {
      case 'image':
        await _addImages(page);
      case 'camera':
        await _takePhoto(page);
      case 'pdf':
        await _addPdf(page);
      case 'slide':
        await _addSlide(page);
      case 'capture':
        await _captureFromImage(note, page);
      case 'drawing':
        await _addDrawing(page);
      case 'text':
        await _editText(note, page);
      case 'page':
        // Diyalog YOK: defterin sonundaki boş yaprağa geçilir, üstüne
        // yazınca sayfa kendiliğinden açılır.
        _goToPage(note.archivePages.length + 1);
    }
  }

  /// Sayfa listesi levhası: uzun defterde sayfa sayfa çevirmek yerine
  /// doğrudan atlamak için (alt çubuktaki "3 / 12" yazısına dokununca).
  Future<void> _pagesSheet(Note note) async {
    final names = archivePageNames(note);
    final picked = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (var i = 0; i < names.length; i++)
              ListTile(
                selected: i == _page,
                leading: CircleAvatar(
                  radius: 14,
                  child: Text('${i + 1}', style: const TextStyle(fontSize: 12)),
                ),
                title: Text(_pageLabel(names[i])),
                subtitle: Text(
                  sheetContext.l10n.archiveEntryCount(
                    archiveEntriesOf(note, names[i]).length,
                  ),
                ),
                onTap: () => Navigator.pop(sheetContext, i),
              ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.add),
              title: Text(sheetContext.l10n.archiveNewPage),
              subtitle: Text(sheetContext.l10n.archiveNewPageHint),
              onTap: () => Navigator.pop(sheetContext, names.length),
            ),
          ],
        ),
      ),
    );
    if (picked != null) _goToPage(picked);
  }

  // ————————————————————————————————— ÇİZİM

  /// Sayfa adı → o sayfanın yazı alanının odağı. Alan sayfanın İÇİNDE
  /// kuruluyor ama boş kâğıda dokunmak (ve ⋮ menüsündeki "yeniden adlandır")
  /// dışarıdan odaklamak istiyor.
  final _writerFocus = <String, FocusNode>{};
  final _titleFocus = <String, FocusNode>{};

  /// Sayfa adı → o sayfanın kaydırma denetleyicisi.
  ///
  /// Yaprağın kendisinde DEĞİL burada duruyor: sayfa gövdeleri önbelleğe
  /// alınıyor (bkz. [_cachedPageBody]) ve gövde denetleyiciyi kapanışında
  /// tutuyor — yaprak ağaçtan düşüp yeniden kurulduğunda yeni bir
  /// denetleyici üretilseydi, önbellekten dönen gövde ARTIK ATILMIŞ olana
  /// bağlı kalır ve sayfa kaydırılamazdı.
  final _scrolls = <String, ScrollController>{};

  /// Sayfa adı → yazı alanının denetleyicisi.
  ///
  /// [WrapTextController]: metnin görsellerin ETRAFINDAN akması ve satır içi
  /// biçim (kalın/renk/vurgu) bu sınıfın işi — gövde metniyle birebir aynı
  /// yol (bkz. text_wrap.dart). Denetleyici ekranda tutulur, alanın kendi
  /// state'inde değil: biçim çubuğu da, sayfa gövdesi önbelleği de aynı
  /// örneğe bakmalı.
  final _writers = <String, WrapTextController>{};

  /// Sayfa adı → o sayfadaki görsellerin kapladığı bantlar (metin bunların
  /// etrafından akar). [NotePageCanvas] ölçer, yazı alanı kullanır.
  final _floats = <String, List<FloatBox>>{};

  /// Sayfa adı → tuvalin kök kutusunun anahtarı (görsel konumları buna göre
  /// ölçülür).
  final _pageKeys = <String, GlobalKey>{};

  /// Sayfa adı → tuvalin EN AZ yüksekliği. Klavye açılınca görünür alan
  /// kısalıyor; en büyük görülen yükseklik saklanır ki tuval klavyenin her
  /// animasyon karesinde yeniden yerleşmesin (editördeki aynı tuzak).
  final _canvasHeights = <String, double>{};

  /// Biçim çubuğu açık mı (alt çubuktaki "Aa" düğmesi açıp kapatır).
  bool _formatBarOpen = false;

  FocusNode _focusFor(Map<String, FocusNode> nodes, String page) =>
      nodes.putIfAbsent(page, FocusNode.new);

  ScrollController _scrollFor(String page) =>
      _scrolls.putIfAbsent(page, ScrollController.new);

  GlobalKey _pageKeyFor(String page) =>
      _pageKeys.putIfAbsent(page, GlobalKey.new);

  /// Sayfanın yazı denetleyicisi; ilk çağrıda kayıttaki metinle kurulur.
  WrapTextController _writerFor(String page, String text) {
    final existing = _writers[page];
    if (existing != null) return existing;
    final controller = WrapTextController(text: text);
    _writers[page] = controller;
    return controller;
  }

  /// Sayfanın tuvalinin kök kutusu ([WrapFieldMeasure] konumları buna göre
  /// çevirir).
  RenderBox? _pageBox(String page) {
    final box = _pageKeys[page]?.currentContext?.findRenderObject();
    return box is RenderBox && box.hasSize ? box : null;
  }

  /// Tuval bantları değişti: yazı alanı metni yeniden kırsın.
  void _applyFloats(String page, List<FloatBox> floats) {
    if (sameFloatList(_floats[page] ?? const [], floats)) return;
    setState(() => _floats[page] = floats);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final async = ref.watch(noteStreamProvider(widget.noteId));
    final note = async.value;
    _liveNote = note;
    _liveRepo = ref.read(notesRepositoryProvider);

    if (note == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.archiveNotebook)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    _syncBodyCache(note, theme);
    final names = archivePageNames(note);
    // Defterin SONUNDA her zaman boş bir yaprak durur: ileri kaydırmak yeni
    // sayfayı açar, "ad ver" diyalogu çıkmaz (kullanıcı isteği 2026-09-01).
    // Yaprak yalnız üstüne bir şey yazılınca/eklenince kayda geçer — boşuna
    // kaydıran kullanıcı deftere boş sayfa biriktirmez.
    final sheets = [
      ...names,
      archiveAutoPageName(note, l10n.archiveAutoPageName),
    ];
    // Sayfa başka cihazdan silinmiş olabilir: numara listenin dışına
    // taşmasın (aksi hâlde PageView boş bir sayfa çizer).
    final page = _page.clamp(0, sheets.length - 1);
    final paper = NoteColors.surface(context, note.color);

    return Scaffold(
      // Zemin, kâğıdın ARKASI: defter masanın üstünde duruyor gibi görünsün
      // diye kâğıttan biraz koyu.
      backgroundColor: Color.alphaBlend(
        scheme.onSurface.withValues(alpha: 0.06),
        paper,
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: _searching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: l10n.archiveSearchHint,
                ),
              )
            : Row(
                children: [
                  const Icon(Icons.menu_book_outlined, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      note.displayTitle.trim().isEmpty
                          ? l10n.archiveNotebook
                          : note.displayTitle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
        actions: [
          IconButton(
            tooltip: _searching ? l10n.close : l10n.archiveSearchHint,
            icon: Icon(_searching ? Icons.close : Icons.search),
            onPressed: () => setState(() {
              _searching = !_searching;
              if (!_searching) _searchController.clear();
            }),
          ),
          if (!_searching)
            PopupMenuButton<String>(
              tooltip: l10n.more,
              onSelected: (value) async {
                switch (value) {
                  case 'paper':
                    await _paperSheet(note);
                  case 'new':
                    _goToPage(names.length);
                  case 'rename':
                    _focusFor(_titleFocus, sheets[page]).requestFocus();
                  case 'delete':
                    await _deletePage(sheets[page]);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(value: 'paper', child: Text(l10n.archivePaper)),
                PopupMenuItem(value: 'new', child: Text(l10n.archiveNewPage)),
                // Genel sayfası kaydın bir parçası değil (adı dilden geliyor):
                // yeniden adlandırılamaz, silinemez. Defterin sonundaki boş
                // yaprak da henüz yok — silinecek bir şey de yok.
                if (page > 0 && page < names.length) ...[
                  PopupMenuItem(
                    value: 'rename',
                    child: Text(l10n.archiveRenamePage),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(l10n.archiveDeletePage),
                  ),
                ],
              ],
            ),
        ],
      ),
      body: _busy
          ? const Center(child: CircularProgressIndicator())
          : (_searching && _query.isNotEmpty)
          ? _searchResults(note)
          : _book(note, names, sheets, paper),
      bottomNavigationBar: (_searching && _query.isNotEmpty)
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // **BİÇİM ÇUBUĞU** (kullanıcı isteği 2026-09-02: "biçim
                // ayarları vs burada da olmalı"): editörün çubuğunun ta
                // kendisi — kalın/italik/altı çizili, yazı ve vurgu rengi,
                // yazı tipi, boyut, şeffaflık ve sayfa görünümü. Defter
                // ayrı bir uygulama değil; aynı motoru kullanıyor.
                if (_formatBarOpen) _formatBar(note),
                _pageBar(note, names, sheets, page),
              ],
            ),
    );
  }

  /// Defterin kendisi: sayfaları çevrilen [PageView].
  Widget _book(
    Note note,
    List<String> names,
    List<String> sheets,
    Color paper,
  ) => PageView.builder(
    controller: _pageController,
    itemCount: sheets.length,
    onPageChanged: (index) {
      // Sayfa çevrilince klavye kapanır: odak ÖNCEKİ sayfanın yazı
      // alanında kalırsa klavye açık kalıyor, üstelik o alanın bekleyen
      // kaydı da (odak gitmediği için) beklemeye devam ediyordu.
      FocusManager.instance.primaryFocus?.unfocus();
      setState(() => _page = index);
    },
    itemBuilder: (context, index) {
      final name = sheets[index];
      final isNew = index >= names.length;
      final generalName = archiveGeneralLabel(
        note,
        context.l10n.archiveGeneralPage,
      );
      return _PageTurn(
        controller: _pageController,
        index: index,
        child: _PageSheet(
          paper: paper,
          style: note.archivePaper,
          scroll: _scrollFor(name),
          writerFocus: _focusFor(_writerFocus, name),
          number: index + 1,
          total: names.length,
          isNew: isNew,
          // BAŞLIK HER SAYFADA YERİNDE DÜZENLENİR (kullanıcı isteği
          // 2026-09-02: "sayfa başlığını direk üzerine tıklayarak yazıp
          // değiştirebilmeliyim") — ilk sayfa dahil. İlk sayfanın adı
          // kayıtta AYRI durur (`Note.archiveGeneralName`): oradaki
          // girdiler bölüm adı taşımıyor, taşısaydı ad değişince hepsinin
          // yeniden etiketlenmesi gerekirdi.
          header: _PageTitleField(
            // Ad değişince alan SIFIRDAN kurulur: eski adla açılmış
            // denetleyici yeni adı göstermezdi.
            key: ValueKey('title-$index-${index == 0 ? generalName : name}'),
            name: index == 0 ? generalName : name,
            hint: context.l10n.archivePageTitleHint,
            focusNode: _focusFor(_titleFocus, name),
            onRename: (value) =>
                index == 0 ? _renameGeneral(value) : _renamePage(name, value),
          ),
          child: _cachedPageBody(note, name),
        ),
      );
    },
  );

  /// Sayfa adı → (imza, gövde). **PERFORMANS** (kullanıcı isteği 2026-09-01:
  /// "performans iyileştirmeleri yapılmalı").
  ///
  /// KÖK NEDEN: defter Firestore akışını dinliyor ve her yazım (yazarken
  /// 600 ms'de bir) bütün ekranı yeniden kuruyor — [PageView] o an ÜÇ sayfayı
  /// canlı tutuyor, yani bir sayfaya yazmak öbür iki sayfanın metin
  /// alanlarını, fotoğraflarını ve menülerini de baştan kuruyordu.
  ///
  /// Çözüm satır önbelleğinin sayfa ölçeğindeki hâli (bkz.
  /// `ItemsEditor._rowCache`): girdileri değişmemiş sayfa için AYNI widget
  /// örneği döndürülür, Flutter da birebir aynı widget'ı görünce alt ağacı
  /// hiç kurmaz ve yerleşimi atlar.
  final _bodyCache = <String, (Object, Widget)>{};

  /// Önbelleği tümden geçersiz kılan SAYFA DÜZEYİ girdiler (tema, desen…).
  Object? _bodyCacheEnv;

  /// Sayfanın girdilerinin EKRANA YANSIYAN özeti. Kayıt her yazımda yeni
  /// nesneler üretiyor (kimlik karşılaştırması işe yaramaz), bu yüzden
  /// içerik bir dizeye yazılıp karşılaştırılıyor.
  String _bodySignature(Note note, String name) {
    final buffer = StringBuffer();
    // SAYFADA YÜZEN görseller: yerleri ve boyutları değişince tuval yeniden
    // kurulmalı (sürüklenen görsel eski yerinde donardı).
    for (final image in archivePageFloats(note, name)) {
      buffer
        ..write('i:')
        ..write(image.id)
        ..write('@')
        ..write(image.x)
        ..write(',')
        ..write(image.pageY)
        ..write(',')
        ..write(image.displayWidth)
        ..write('\n');
    }
    for (final entry in archivePageExtras(note, name)) {
      final item = entry.text;
      if (item != null) {
        buffer
          ..write('t:')
          ..write(item.id)
          ..write('\u0000')
          ..write(item.title)
          ..write('\u0000')
          ..write(item.text)
          ..write('\u0000')
          ..write(item.attachmentId);
      } else {
        final file = entry.file!;
        buffer
          ..write('f:')
          ..write(file.id)
          ..write('\u0000')
          ..write(file.fileName)
          ..write('\u0000')
          ..write(file.sizeBytes)
          ..write('\u0000')
          ..write(file.isUploaded);
      }
      buffer.write('\n');
    }
    return buffer.toString();
  }

  Widget _cachedPageBody(Note note, String name) {
    final writing = archivePageText(note, name);
    // Yazının METNİ de anahtarda: uzaktan gelen değişiklik ekrana yansımalı.
    // (Kullanıcı yazarken alan zaten kendi metnini koruyor — bkz.
    // [_PageWriter.didUpdateWidget].)
    // Bantlar da anahtarda: görsel sürüklenince metnin ETRAFINDAN AKMASI
    // için yazı alanının yeni bantları görmesi gerekiyor (liste yalnız
    // gerçekten değişince yenileniyor — bkz. [_applyFloats]).
    final key = (
      writing?.id,
      writing?.text,
      identityHashCode(_floats[name]),
      _bodySignature(note, name),
    );
    final hit = _bodyCache[name];
    if (hit != null && hit.$1 == key) return hit.$2;
    final body = _pageBody(note, name);
    _bodyCache[name] = (key, body);
    return body;
  }

  /// Tema/desen değiştiyse önbelleği düşürür; silinmiş sayfaların bayat
  /// girdilerini ayıklar.
  void _syncBodyCache(Note note, ThemeData theme) {
    final env = (
      theme.colorScheme,
      note.archivePaper,
      note.fontFamily,
      note.fontScale,
      note.textOpacity,
      context.l10n.localeName,
    );
    if (env != _bodyCacheEnv) {
      _bodyCache.clear();
      _bodyCacheEnv = env;
      return;
    }
    if (_bodyCache.length > note.archivePages.length + 2) {
      final live = {'', ...note.archivePages};
      _bodyCache.removeWhere((name, _) => !live.contains(name));
    }
  }

  /// Bir sayfanın içeriği: serbest yazı alanı + (varsa) dosyalar ve başlıklı
  /// bloklar.
  ///
  /// Bir sayfanın içeriği: **normal not sayfasının ta kendisi** — serbest
  /// yazı alanı, üstünde yüzen görseller, altında dosya ekleri ve başlıklı
  /// bloklar.
  ///
  /// **Kullanıcı isteği 2026-09-02:** "görsel eklendiğinde normal not
  /// sayfamız gibi metin etrafından akabilmeli, yeri değiştirilebilmeli;
  /// şu an sanki arşiv defteri farklı bir uygulama gibi, hiçbir özelliğimiz
  /// yok orada."
  ///
  /// Bu yüzden defter artık kendi çizim yolunu kurmuyor, EDİTÖRÜN yolunu
  /// kullanıyor: görseller [NotePageCanvas] üzerinde yüzer (sürüklenir,
  /// boyutlandırılır, ⋮ menüsünden kırpılır/silinir), yazı alanı
  /// [WrapTextController] + [WrapFieldMeasure] ile metni o görsellerin
  /// etrafından akıtır ve satır içi biçim (kalın/renk/vurgu) aynı motordan
  /// gelir.
  Widget _pageBody(Note note, String name) {
    final extras = archivePageExtras(note, name);
    final writing = archivePageText(note, name);
    final images = archivePageFloats(note, name);
    final controller = _writerFor(name, writing?.text ?? '');
    final scheme = Theme.of(context).colorScheme;
    controller.richTheme = RichTextTheme(
      palette: NoteColors.richPalette,
      markerColor: scheme.onSurfaceVariant.withValues(alpha: 0.45),
    );
    // ÜST DOLGU YOK: desenin başlangıcı ile yazının ilk satırı aynı noktadan
    // başlasın (yoksa çizgiler yazının arasına düşer).
    const padding = EdgeInsetsDirectional.fromSTEB(
      _kGutter,
      0,
      16,
      _kPageBottomGap,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        // Klavye açılınca görünür alan kısalıyor; tuvalin en az yüksekliği
        // EN BÜYÜK görülen değerde tutulur — yoksa klavyenin her karesinde
        // sayfa yeniden yerleşir (editördeki `_stableCanvasHeight` tuzağı).
        final height = math.max(
          _canvasHeights[name] ?? 0,
          constraints.maxHeight,
        );
        _canvasHeights[name] = height;
        return SingleChildScrollView(
          controller: _scrollFor(name),
          child: NotePageCanvas(
            images: images,
            minHeight: height,
            onRemove: _removeAttachment,
            onChanged: _updateAttachment,
            onDetach: (a) => _setImageOnPage(a, false),
            onCopy: null,
            topLimit: 0,
            textTop: 0,
            textLeft: _kGutter,
            onFloats: (floats) => _applyFloats(name, floats),
            // Boş kâğıda dokunmak yazı alanını odaklar (gerçek defterde de
            // sayfanın neresine dokunursan oraya yazarsın).
            onTapEmpty: _focusFor(_writerFocus, name).requestFocus,
            child: KeyedSubtree(
              key: _pageKeyFor(name),
              child: Padding(
                padding: padding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _PageWriter(
                      // Kimlik SAYFA adına bağlı, girdiye değil: ilk harfte
                      // girdi oluşuyor ve kimliğe bağlı olsa alan o anda
                      // sıfırlanıp odağı kaybederdi.
                      key: ValueKey('writer-$name'),
                      controller: controller,
                      text: writing?.text ?? '',
                      hint: context.l10n.archiveWriteHint,
                      // Defterin kendi yazı tipi ve boyutu yazıya da geçer
                      // (biçim çubuğundan değişir).
                      fontFamily: note.fontFamily,
                      fontScale: note.fontScale,
                      textOpacity: note.textOpacity,
                      floats: _floats[name] ?? const [],
                      pageBox: () => _pageBox(name),
                      focusNode: _focusFor(_writerFocus, name),
                      onChanged: (value) => _saveWriting(name, value),
                      onFocused: () => _onWriterFocused(name),
                    ),
                    if (extras.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      for (final entry in extras) _entryTile(note, entry),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Yazı alanı odaklandı: biçim çubuğunun hedefi bu sayfa olsun.
  void _onWriterFocused(String page) {
    if (_formatPage == page) return;
    setState(() => _formatPage = page);
  }

  /// Biçim çubuğunun yazdığı SAYFA (yazı alanı). Sayfa çevrilince odakla
  /// birlikte değişir.
  String? _formatPage;

  /// Biçim çubuğunun hedefi: o an odaklı yazı alanı. Çubuk odak İSTEMEDİĞİ
  /// için (bkz. [FormatBar]) alan odağını korur, seçim de yerinde kalır.
  FormatTarget? _formatTarget() {
    final page = _formatPage;
    final controller = page == null ? null : _writers[page];
    if (page == null || controller == null) return null;
    return FormatTarget(
      controller: controller,
      focusNode: _focusFor(_writerFocus, page),
      commit: () => unawaited(_saveWriting(page, controller.logicalText)),
    );
  }

  /// Biçim düğmesi: seçime uygular (seçim yoksa imlece "bekleyen biçim"
  /// açar) ve metni kaydeder — programlı değişiklikte alanın `onChanged`i
  /// çalışmaz.
  void _runOnWriter(bool Function(WrapTextController) action) {
    final target = _formatTarget();
    if (target == null) return;
    if (action(target.controller)) target.commit();
    if (!target.focusNode.hasFocus) target.focusNode.requestFocus();
    setState(() {});
  }

  /// Kaydırıcılar (boyut/şeffaflık) sürüklenirken kayıt GECİKTİRİLİR: her
  /// karede Firestore'a yazmak boşuna trafik.
  final _styleDebounce = Debouncer();

  void _mutateStyleSoon(Note Function(Note) change) {
    setState(() {});
    _styleDebounce(() => unawaited(_mutate(change)));
  }

  /// Eki kayıtta günceller (taşıma, boyutlandırma, kırpma, ad değişimi).
  void _updateAttachment(Attachment attachment) => unawaited(
    _mutate(
      (n) => n.copyWith(
        attachments: [
          for (final a in n.attachments)
            if (a.id == attachment.id) attachment else a,
        ],
      ),
    ),
  );

  /// Görseli SAYFAYA yerleştirir ([onPage] true) ya da sayfadan alıp dosya
  /// listesine taşır. Sayfaya ilk kez konan görsele bir yer de verilir.
  void _setImageOnPage(Attachment attachment, bool onPage) {
    if (!onPage) {
      _updateAttachment(attachment.copyWith(asFile: true));
      return;
    }
    final note = _note;
    final placed = note == null
        ? attachment.copyWith(asFile: false)
        : _placeOnPage(attachment.copyWith(asFile: false), note);
    _updateAttachment(placed);
  }

  /// Yeni görselin sayfadaki yeri: var olan görsellerin ALTINA, sol kenara
  /// yakın. Ölçüm gerekmez — kullanıcı zaten sürükleyip istediği yere
  /// koyabiliyor; önemli olan üst üste binmemesi.
  Attachment _placeOnPage(
    Attachment image,
    Note note, {
    List<Attachment> placed = const [],
  }) {
    final page = image.section;
    var top = 8.0;
    final width = _pageBox(page)?.size.width ?? 0;
    for (final other in [...archivePageFloats(note, page), ...placed]) {
      if (other.id == image.id || !other.floatsOnPage) continue;
      final aspect =
          (other.width != null && other.height != null && other.height! > 0)
          ? other.width! / other.height!
          : 1.0;
      final bottom =
          (other.pageY ?? 0) + (width * (other.displayWidth ?? 0.32)) / aspect;
      if (bottom + 12 > top) top = bottom + 12;
    }
    return image.copyWith(x: 0.04, pageY: top, displayWidth: 0.32);
  }

  Widget _entryTile(Note note, ArchiveEntry entry) {
    final item = entry.text;
    if (item != null) {
      final linked = item.attachmentId.isEmpty
          ? null
          : note.attachments
                .where((a) => a.id == item.attachmentId)
                .firstOrNull;
      return _TextEntry(
        item: item,
        linked: linked,
        onOpenLinked: linked == null ? null : () => _open(linked),
        onTap: () => _editText(note, item.section, existing: item),
        onMove: () => _moveEntry(note, entry),
        onDelete: () => _removeItem(item),
      );
    }
    final file = entry.file!;
    return _FileEntry(
      attachment: file,
      onTap: () => _open(file),
      onRename: () => _renameAttachment(file),
      onMove: () => _moveEntry(note, entry),
      onDelete: () => _removeAttachment(file),
      // Eski defterlerdeki görseller dosya olarak eklenmişti; buradan
      // sayfaya taşınır ve metin etrafından akmaya başlar.
      onPlaceOnPage: file.kind == AttachmentKind.image
          ? () => _setImageOnPage(file, true)
          : null,
    );
  }

  /// Arama sonuçları: defterin tamamı, sayfa etiketiyle.
  Widget _searchResults(Note note) {
    final hits = _searchHits(note);
    if (hits.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(context.l10n.noteSearchNoHit),
        ),
      );
    }
    final names = archivePageNames(note);
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      itemCount: hits.length,
      itemBuilder: (context, i) {
        final hit = hits[i];
        final item = hit.entry.text;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              item != null
                  ? Icons.notes_outlined
                  : _iconFor(hit.entry.file!.kind),
            ),
            title: Text(
              item != null
                  ? (item.title.isNotEmpty
                        ? item.title
                        : item.text.split('\n').first)
                  : hit.entry.file!.fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(_pageLabel(names[hit.page])),
            onTap: () {
              setState(() {
                _searching = false;
                _searchController.clear();
              });
              // Sayfaya git: PageView bu karede yeniden kurulduğu için
              // atlama bir sonraki kareye bırakılır.
              _goToPageSoon(hit.page);
            },
          ),
        );
      },
    );
  }

  static IconData _iconFor(AttachmentKind kind) => switch (kind) {
    AttachmentKind.image => Icons.image_outlined,
    AttachmentKind.video => Icons.videocam_outlined,
    AttachmentKind.pdf => Icons.picture_as_pdf_outlined,
    AttachmentKind.slide => Icons.slideshow_outlined,
    AttachmentKind.audio => Icons.audiotrack_outlined,
  };

  /// Yapay zekâdan gelen metni açık sayfanın YAZISININ sonuna ekler.
  Future<void> _appendToPage(String page, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final controller = _writers[page];
    final current = controller?.logicalText ?? '';
    final merged = current.trim().isEmpty ? trimmed : '$current\n\n$trimmed';
    controller?.setLogical(merged, merged.length);
    await _saveWriting(page, merged);
  }

  /// Defterin biçim çubuğu — editörünkiyle AYNI widget.
  Widget _formatBar(Note note) => FormatBar(
    target: _formatTarget(),
    onFormat: (format, {int? colorIndex}) =>
        _runOnWriter((c) => applyRichFormat(c, format, colorIndex: colorIndex)),
    onClearFormat: () => _runOnWriter(clearRichFormat),
    onRemoveFormat: (format) =>
        _runOnWriter((c) => removeRichFormat(c, format)),
    fontFamily: note.fontFamily,
    fontScale: note.fontScale,
    textOpacity: note.textOpacity,
    hasSelection: () {
      final selection = _formatTarget()?.controller.selection;
      return selection != null && selection.isValid && !selection.isCollapsed;
    },
    onFontChanged: (family) => unawaited(
      _mutate(
        (n) => family == null
            ? n.copyWith(clearFontFamily: true)
            : n.copyWith(fontFamily: family),
      ),
    ),
    // Sürüklerken gecikmeli kayıt, bırakınca kalıcı.
    onScaleChanged: (value) =>
        _mutateStyleSoon((n) => n.copyWith(fontScale: value)),
    onScaleEnd: (value) =>
        unawaited(_mutate((n) => n.copyWith(fontScale: value))),
    onOpacityChanged: (value) =>
        _mutateStyleSoon((n) => n.copyWith(textOpacity: value)),
    onOpacityEnd: (value) =>
        unawaited(_mutate((n) => n.copyWith(textOpacity: value))),
    // SAYFA GÖRÜNÜMÜ defterde "kâğıt": rengi ve deseni (çizgili/kareli/
    // noktalı/düz) aynı levhada.
    onPageStyle: () => unawaited(_paperSheet(note)),
    onClose: () => setState(() => _formatBarOpen = false),
  );

  /// Alt çubuk: sayfa çevirme okları, konum göstergesi, biçim, yapay zekâ
  /// ve "+".
  ///
  /// Düğmeler DAR: beş düğme ve sayfa adı en dar telefona da sığmalı
  /// (kullanıcı bulgusu 2026-09-02: "alt kısım sığmıyor" — editörün alt
  /// çubuğunda da aynı sıkışma vardı).
  Widget _pageBar(
    Note note,
    List<String> names,
    List<String> sheets,
    int page,
  ) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final isNew = page >= names.length;
    Widget compact({
      required String tooltip,
      required IconData icon,
      required VoidCallback? onPressed,
      bool selected = false,
    }) => IconButton(
      tooltip: tooltip,
      isSelected: selected,
      icon: Icon(icon, size: 22),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 40, height: 40),
      onPressed: onPressed,
    );

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
        child: Row(
          children: [
            compact(
              tooltip: l10n.archivePrevPage,
              icon: Icons.chevron_left,
              onPressed: page > 0 ? () => _goToPage(page - 1) : null,
            ),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _pagesSheet(note),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isNew
                            ? l10n.archiveNewPageLabel
                            : _pageLabel(sheets[page]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        isNew ? sheets[page] : '${page + 1} / ${names.length}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            compact(
              tooltip: l10n.archiveNextPage,
              icon: Icons.chevron_right,
              onPressed: page < sheets.length - 1
                  ? () => _goToPage(page + 1)
                  : null,
            ),
            compact(
              tooltip: l10n.formatTitle,
              icon: Icons.text_format,
              selected: _formatBarOpen,
              onPressed: () => setState(() {
                _formatBarOpen = !_formatBarOpen;
                // Çubuk AÇIK SAYFAYA yazar: kullanıcı hiçbir alana
                // dokunmadan çubuğu açtıysa hedef boş kalır ve düğmeler
                // sessizce hiçbir şey yapmazdı.
                if (_formatBarOpen) _formatPage = sheets[page];
              }),
            ),
            // YAPAY ZEKÂ defterde de (kullanıcı isteği 2026-09-02: "hepsi
            // olmalı"): özetle, soru sor, çevir — editördeki aynı levha.
            // Gelen metin açık sayfanın yazısının sonuna eklenir.
            compact(
              tooltip: l10n.aiTitle,
              icon: Icons.auto_awesome,
              onPressed: () => unawaited(
                showAiSheet(
                  context,
                  note,
                  onAppendText: (text) =>
                      unawaited(_appendToPage(sheets[page], text)),
                ),
              ),
            ),
            const SizedBox(width: 2),
            FloatingActionButton.small(
              heroTag: 'notebook-add',
              tooltip: l10n.archiveAddEntry,
              onPressed: () => _addSheet(note, sheets[page]),
              child: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kâğıdın satır aralığı. Yazı alanının satır yüksekliği de bu: yazı
/// çizgilerin üstüne oturuyor, aralarına düşmüyor (bkz. [_PageWriter]).
const double _kLineGap = 28;

/// Yazının taban punto'su. Satır yüksekliği [_kLineGap] / bu sayı.
const double _kWriteFontSize = 16;

/// Yazının kâğıdın SOL kenarından uzaklığı (kenar payı çizgisinin sağı).
const double _kGutter = 38;

/// Sayfanın altında bırakılan boşluk: yazının altına dokunmak da yazı
/// alanına dokunmak sayılsın (bkz. [NotePageCanvas.onTapEmpty]).
const double _kPageBottomGap = 120;

/// **SAYFA ÇEVİRME.** Sayfa, defterin sırtı (SOL kenar) çevresinde döner.
///
/// [PageView] çocuklarını kendi kaydırmasıyla yatayda kaydırır; burada o
/// kaydırma önce GERİ ALINIR (`Transform.translate`), sonra sayfa sırtından
/// döndürülür. Böylece sayfalar yan yana kaymak yerine üst üste durup çevrilir
/// — istenen "defter" hissini veren şey budur.
///
/// Dönüş 90°'nin biraz altında bırakılır: tam 90°'de sayfa sıfır genişliğe
/// iner ve bir kare için tümüyle kaybolur (göze "takılma" gibi görünür).
class _PageTurn extends StatelessWidget {
  const _PageTurn({
    required this.controller,
    required this.index,
    required this.child,
  });

  final PageController controller;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => AnimatedBuilder(
      animation: controller,
      // `child` sabit: sayfa içeriği her karede değil, yalnız veri değişince
      // kurulur — çevirme animasyonu boyunca yalnız dönüşüm hesaplanır.
      child: RepaintBoundary(child: child),
      builder: (context, child) {
        // Yerleşim bitmeden `page` okunamaz; ilk karede sayfa düz durur.
        final position =
            controller.hasClients && controller.position.haveDimensions
            ? (controller.page ?? controller.initialPage.toDouble())
            : controller.initialPage.toDouble();
        final t = (index - position).clamp(-1.0, 1.0);
        if (t == 0) return child!;
        // TÜMÜYLE ÇEVRİLMİŞ sayfa hiç çizilmez. 90°'ye yakın döndürülmüş
        // yaprak ekranda cilt kenarında ince, açık renkli bir şerit
        // bırakıyordu (kullanıcı bulgusu 2026-09-02: "sayfa düzgün
        // görülmüyor") — üstelik görünmeyen bir sayfayı boyamanın bedeli de
        // boşuna.
        if (t.abs() >= 0.999) return const SizedBox.shrink();
        // Sırt SOLDA — ama sağdan sola yazılan dillerde defter de ters
        // açılır: hem `PageView`ın kaydırma yönü hem de cildin yeri döner.
        final rtl = Directionality.of(context) == TextDirection.rtl;
        final sign = rtl ? -1.0 : 1.0;
        return Transform.translate(
          // PageView'ın kendi kaydırmasını geri al: sayfa yerinde kalsın.
          offset: Offset(-t * constraints.maxWidth * sign, 0),
          child: Transform(
            alignment: rtl ? Alignment.centerRight : Alignment.centerLeft,
            transform: Matrix4.identity()
              // Perspektif: uzaklaşan kenar daralsın, yoksa dönüş düz bir
              // yatay ezilme gibi görünür.
              ..setEntry(3, 2, 0.0012)
              ..rotateY(-t * sign * math.pi / 2 * 0.96),
            child: Opacity(
              // Çevrilen sayfa kenara yaklaştıkça hafifçe soluklaşır: iki
              // sayfa üst üste dururken hangisinin öne geldiği belli olsun.
              // Fazlası kâğıdı camlaştırır, altındaki sayfa okunur hâle gelir.
              opacity: (1 - t.abs() * 0.4).clamp(0.0, 1.0),
              child: child,
            ),
          ),
        );
      },
    ),
  );
}

/// Tek bir defter YAPRAĞI: kâğıt deseni, cilt gölgesi, üstte sayfa başlığı,
/// altta sayfa numarası, ortada kaydırılan içerik.
///
/// Kâğıdın deseni İÇERİKLE BİRLİKTE kayar (bkz. [_PaperPainter]): çizgiler
/// sabit dursaydı sayfa kaydırıldığı anda yazı çizgilerin arasına kayardı.
/// Bu yüzden yaprak, içeriğin kaydırma denetleyicisini dışarıdan alır —
/// denetleyicinin sahibi ekran ([_ArchiveNoteScreenState._scrolls]).
class _PageSheet extends StatelessWidget {
  const _PageSheet({
    required this.paper,
    required this.style,
    required this.header,
    required this.number,
    required this.total,
    required this.isNew,
    required this.scroll,
    required this.writerFocus,
    required this.child,
  });

  final Color paper;
  final ArchivePaper style;
  final Widget header;
  final int number;
  final int total;

  /// Defterin sonundaki HENÜZ AÇILMAMIŞ yaprak mı? Numarası yok (kayıtta da
  /// yok), altında ne yapılacağını söyleyen bir satır var.
  final bool isNew;

  /// İçeriğin kaydırma denetleyicisi. Kâğıdın deseni de bundan besleniyor:
  /// çizgiler yazıyla BİRLİKTE kayar (sabit dursalardı sayfa kaydırılır
  /// kaydırılmaz yazı çizgilerin arasına düşerdi).
  final ScrollController scroll;

  final FocusNode writerFocus;

  /// Sayfanın kaydırılan içeriği (aynı [scroll] denetleyicisini kullanan bir
  /// kaydırma görünümü).
  final Widget child;

  static const _radius = BorderRadius.horizontal(
    left: Radius.circular(4),
    right: Radius.circular(14),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: paper,
          borderRadius: _radius,
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.18),
              blurRadius: 10,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: _radius,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(38, 10, 12, 4),
                child: header,
              ),
              Expanded(
                child: CustomPaint(
                  painter: _PaperPainter(
                    style: style,
                    scroll: scroll,
                    line: scheme.onSurface.withValues(alpha: 0.07),
                    margin: const Color(0xFFC96A6A).withValues(alpha: 0.35),
                    spine: scheme.onSurface.withValues(alpha: 0.10),
                  ),
                  // Desen içerikten bağımsız katman: kaydırmada yalnız o
                  // yeniden boyanır, sayfanın tamamı değil.
                  child: GestureDetector(
                    // Boş kâğıda dokunmak YAZI ALANINI odaklar: gerçek bir
                    // defterde de sayfanın neresine dokunursan oraya
                    // yazarsın. Şeffaf: girdilerin kendi dokunuşları
                    // (görseli aç, bloğu düzenle) çalışmaya devam eder.
                    behavior: HitTestBehavior.translucent,
                    onTap: writerFocus.requestFocus,
                    // Kâğıdın deseni kaydırmada her karede yeniden boyanıyor
                    // (bkz. [_PaperPainter]); sınır olmasaydı içerik de
                    // onunla birlikte boyanırdı.
                    child: RepaintBoundary(child: child),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8, top: 2),
                child: Text(
                  isNew ? context.l10n.archiveNewPageHint : '$number / $total',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kâğıdın deseni: çizgili / kareli / noktalı / düz + cilt gölgesi.
///
/// Desen İÇERİKLE BİRLİKTE kayar: [scroll] verilirse çizgiler kaydırma
/// konumuna göre ötelenir ve yalnızca GÖRÜNEN olanlar çizilir (uzun bir
/// sayfada binlerce çizgi boyamak yerine bir ekran dolusu).
class _PaperPainter extends CustomPainter {
  _PaperPainter({
    required this.style,
    required this.line,
    required this.margin,
    required this.spine,
    this.scroll,
    this.gap = _kLineGap,
  }) : super(repaint: scroll);

  final ArchivePaper style;
  final Color line;
  final Color margin;
  final Color spine;

  /// İçeriğin kaydırma denetleyicisi (null = sabit desen, örnek karesi).
  final ScrollController? scroll;
  final double gap;

  /// Sol kenar boşluğu çizgisinin yeri (içerik dolgusuyla aynı).
  static const double _marginX = 30;

  /// Kaydırma konumu — **`position` DEĞİL `positions`**.
  ///
  /// KÖK NEDEN (widget testinde yakalandı: `'_positions.length == 1'`
  /// doğrulaması paint sırasında patlıyordu): sayfa çevrilirken eski
  /// yaprağın kaydırılabilir alanı henüz sökülmemişken yenisi bağlanıyor,
  /// yani denetleyicinin bir an İKİ konumu oluyor; sayfa ağaçtan düşerken de
  /// HİÇ konumu kalmıyor ama boyacı bir kez daha çiziliyor.
  /// `ScrollController.position` iki durumda da doğrulama hatası veriyor —
  /// yani defterde sayfa çevirmek uygulamayı kırmızı ekrana düşürürdü.
  double get _offset {
    for (final position in scroll?.positions ?? const <ScrollPosition>[]) {
      return position.hasPixels ? position.pixels : 0;
    }
    return 0;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = line
      ..strokeWidth = 1;
    // Kaydırma konumunun aralığa göre ARTANI: desen içerikle birlikte kayar
    // ama her zaman ekranın üstünden başlar.
    final shift = _offset % gap;
    final left = style == ArchivePaper.lined ? _marginX : 12.0;
    switch (style) {
      case ArchivePaper.lined:
        for (var y = gap - shift; y < size.height; y += gap) {
          canvas.drawLine(
            Offset(left, y),
            Offset(size.width - 12, y),
            linePaint,
          );
        }
        canvas.drawLine(
          const Offset(_marginX, 0),
          Offset(_marginX, size.height),
          Paint()
            ..color = margin
            ..strokeWidth = 1.2,
        );
      case ArchivePaper.grid:
        for (var y = gap - shift; y < size.height; y += gap) {
          canvas.drawLine(
            Offset(left, y),
            Offset(size.width - 12, y),
            linePaint,
          );
        }
        for (var x = left; x < size.width - 12; x += gap) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
        }
      case ArchivePaper.dots:
        final dots = <Offset>[];
        for (var y = gap - shift; y < size.height; y += gap) {
          for (var x = left; x < size.width - 12; x += gap) {
            dots.add(Offset(x, y));
          }
        }
        canvas.drawPoints(
          PointMode.points,
          dots,
          Paint()
            ..color = line
            ..strokeWidth = 2.4
            ..strokeCap = StrokeCap.round,
        );
      case ArchivePaper.plain:
        break;
    }
    // Cilt: sol kenarda içeri doğru sönen bir gölge şeridi. Desenden
    // bağımsız — düz kâğıtta da defter olduğu belli olsun.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, 14, size.height),
      Paint()
        ..shader = LinearGradient(
          colors: [spine, spine.withValues(alpha: 0)],
        ).createShader(Rect.fromLTWH(0, 0, 14, size.height)),
    );
  }

  @override
  bool shouldRepaint(_PaperPainter old) =>
      old.style != style ||
      old.line != line ||
      old.margin != margin ||
      old.spine != spine ||
      old.gap != gap;
}

/// Kâğıt deseni seçim levhasındaki küçük örnek kare.
class _PaperSwatch extends StatelessWidget {
  const _PaperSwatch({required this.paper, required this.color});

  final ArchivePaper paper;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: CustomPaint(
        painter: _PaperPainter(
          style: paper,
          gap: 7,
          line: scheme.onSurface.withValues(alpha: 0.25),
          margin: const Color(0xFFC96A6A).withValues(alpha: 0.5),
          spine: scheme.onSurface.withValues(alpha: 0.12),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

/// Sayfa başlığı — YERİNDE düzenlenir.
///
/// Eskiden ad yalnız ⋮ menüsündeki "Sayfayı yeniden adlandır" diyalogundan
/// değişiyordu; sayfa açmak da ayrı bir diyalog istiyordu. Artık başlığa
/// dokunup yazmak yetiyor, defterin sonundaki boş yaprakta ise yazılan ad
/// sayfayı doğrudan AÇIYOR.
class _PageTitleField extends StatefulWidget {
  const _PageTitleField({
    super.key,
    required this.name,
    required this.hint,
    required this.focusNode,
    required this.onRename,
  });

  final String name;
  final String hint;
  final FocusNode focusNode;

  /// Adı kayda yazar; yazılamadıysa (boş ad, çakışan ad) false döner.
  final Future<bool> Function(String) onRename;

  @override
  State<_PageTitleField> createState() => _PageTitleFieldState();
}

class _PageTitleFieldState extends State<_PageTitleField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.name,
  );

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!widget.focusNode.hasFocus) unawaited(_commit());
  }

  /// Adı KAYDA yazar. Boş bırakılan ad yok sayılır: sayfanın adı, girdileri
  /// ona bağlayan anahtar — boş ad "Genel" demek olurdu ve sayfa kaybolurdu.
  Future<void> _commit() async {
    final value = _controller.text.trim();
    if (value.isEmpty || value == widget.name) {
      if (_controller.text != widget.name) _controller.text = widget.name;
      return;
    }
    if (await widget.onRename(value)) return;
    // Ad yazılamadı (aynı adda bir sayfa var): başlıkta var olmayan bir ad
    // yazılı kalmasın.
    if (mounted) _controller.text = widget.name;
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return TextField(
      controller: _controller,
      focusNode: widget.focusNode,
      maxLines: 1,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) {
        unawaited(_commit());
        widget.focusNode.unfocus();
      },
      style: theme.textTheme.titleMedium?.copyWith(
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        isDense: true,
        // Dolgu KAPALI: temanın `filled: true`si kâğıdın üstüne opak bir
        // kutu boyuyor ve çizgileri siliyordu (bkz. [_PageWriter]).
        filled: false,
        contentPadding: EdgeInsets.zero,
        hintText: widget.hint,
        border: const UnderlineInputBorder(),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: scheme.onSurfaceVariant.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }
}

/// **SAYFANIN YAZI ALANI** — defterin üstüne doğrudan yazılan yer.
///
/// Kullanıcı bulgusu 2026-09-01: "metin yazamıyorum, yazmak için bu alan
/// açılıyor — direk sayfaya yazılabilmeli." Eskiden yazmak bir `AlertDialog`
/// açıyordu; artık sayfanın kendisi bir metin alanı.
///
/// * Yazı çizgilere OTURUR: satır yüksekliği kâğıdın satır aralığıyla aynı
///   ([_kLineGap]) ve `forceStrutHeight` ile yazı tipinden bağımsız sabit.
/// * Kayıt GECİKTİRİLİR ([Debouncer]): her harfte Firestore'a yazmak hem
///   kotayı hem pili yakar, üstelik her yazım akıştan geri dönüp ekranı
///   yeniden kuruyor.
/// * Uzaktan gelen metin, alan ODAKTAYKEN ya da bekleyen kayıt varken
///   uygulanmaz — imleç satır başına atlar ya da yazılan son harfler geri
///   alınırdı.
class _PageWriter extends StatefulWidget {
  const _PageWriter({
    super.key,
    required this.controller,
    required this.text,
    required this.hint,
    required this.focusNode,
    required this.floats,
    required this.pageBox,
    required this.onChanged,
    required this.onFocused,
    this.fontFamily,
    this.fontScale = 1,
    this.textOpacity = 1,
  });

  /// Alanın denetleyicisi EKRANDA tutulur (bkz.
  /// [_ArchiveNoteScreenState._writers]): biçim çubuğu da aynı örneğe yazar.
  final WrapTextController controller;

  final String text;
  final String hint;

  /// Defterin yazı tipi / boyut çarpanı / opaklığı (biçim çubuğundan gelir).
  final String? fontFamily;
  final double fontScale;
  final double textOpacity;

  /// Sayfadaki görsellerin bantları — metin bunların etrafından akar.
  final List<FloatBox> floats;

  /// Tuvalin kök kutusu: bantlar sayfa uzayında ölçülüyor, alan kendi metin
  /// uzayına çevirebilsin diye gerekli.
  final RenderBox? Function() pageBox;

  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onFocused;

  @override
  State<_PageWriter> createState() => _PageWriterState();
}

class _PageWriterState extends State<_PageWriter> {
  final _debounce = Debouncer(
    delay: const Duration(milliseconds: 600),
    maxWait: const Duration(seconds: 4),
  );

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  /// Odak gidince bekleyen kayıt HEMEN yazılır: kullanıcı sayfayı çevirmeden
  /// önce yazdığının kaydolduğundan emin olmalı.
  void _onFocusChange() {
    if (widget.focusNode.hasFocus) {
      widget.onFocused();
      return;
    }
    _debounce.flush();
  }

  @override
  void didUpdateWidget(covariant _PageWriter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text == widget.controller.logicalText) return;
    if (widget.focusNode.hasFocus || _debounce.hasPending) return;
    widget.controller.setLogical(widget.text, widget.text.length);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    // Sayfa çevrildiğinde bu alan ağaçtan düşüyor: bekleyen kayıt burada
    // yazılmazsa son yazılanlar KAYBOLURDU. (Denetleyici ekranda kaldığı
    // için burada YOK EDİLMEZ.)
    _debounce.flush();
    _debounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final size = _kWriteFontSize * widget.fontScale;
    final style = TextStyle(
      fontSize: size,
      // Satır yüksekliği kâğıdın çizgi aralığına oranlanır: yazı büyüyünce
      // satır da büyür, ama çizgilerin katı kalır (yazı çizgiye oturur).
      height: (_kLineGap * widget.fontScale) / size,
      fontFamily: widget.fontFamily,
      color: scheme.onSurface.withValues(
        alpha: widget.textOpacity.clamp(0.3, 1.0),
      ),
    );
    final field = TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      maxLines: null,
      minLines: 6,
      keyboardType: TextInputType.multiline,
      textCapitalization: TextCapitalization.sentences,
      style: style,
      // Satır yüksekliği yazı tipinden BAĞIMSIZ sabitlenir: aksi hâlde
      // emoji ya da farklı bir yazı tipi olan satır uzar ve o satırdan sonra
      // yazı kâğıdın çizgilerinden kayardı.
      strutStyle: StrutStyle(
        fontSize: size,
        height: (_kLineGap * widget.fontScale) / size,
        fontFamily: widget.fontFamily,
        forceStrutHeight: true,
      ),
      cursorColor: scheme.primary,
      decoration: InputDecoration(
        isDense: true,
        // **DOLGU KAPALI** (kullanıcı bulgusu 2026-09-02: "arşiv defterinde
        // sayfa çizgileri kayboluyor"): uygulamanın `InputDecorationTheme`i
        // `filled: true` — alan, kâğıdın üstüne KENDİ opak dikdörtgenini
        // boyuyor ve altındaki çizgileri siliyordu. Ekran görüntüsünde
        // çizgiler tam da alanın bittiği yerde başlıyordu.
        filled: false,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        hintText: widget.hint,
        hintStyle: style.copyWith(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.55),
        ),
      ),
      onChanged: (_) =>
          _debounce(() => widget.onChanged(widget.controller.logicalText)),
    );
    // Ölçüm: alanın sayfadaki yerini bulup bantları metin uzayına çevirir —
    // metin görsellerin etrafından böyle akar (gövde metniyle aynı yol).
    return WrapFieldMeasure(
      controller: widget.controller,
      style: style,
      floats: widget.floats,
      pageBox: widget.pageBox,
      child: field,
    );
  }
}

/// Sayfadaki BAŞLIKLI metin bloğu: başlık, gövde, bağlı dosya ve satır
/// menüsü. (Sayfanın serbest yazısı bu değil — bkz. [_PageWriter].)
class _TextEntry extends StatelessWidget {
  const _TextEntry({
    required this.item,
    required this.linked,
    required this.onTap,
    required this.onMove,
    required this.onDelete,
    this.onOpenLinked,
  });

  final NoteItem item;
  final Attachment? linked;
  final VoidCallback onTap;
  final VoidCallback onMove;
  final VoidCallback onDelete;
  final VoidCallback? onOpenLinked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10, top: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.title.isNotEmpty)
                    Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  if (item.text.isNotEmpty)
                    Text(item.text, style: theme.textTheme.bodyMedium),
                  if (linked != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: InkWell(
                        onTap: onOpenLinked,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.link, size: 14, color: scheme.primary),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                linked!.fileName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: scheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            _EntryMenu(onMove: onMove, onDelete: onDelete),
          ],
        ),
      ),
    );
  }
}

/// Sayfadaki DOSYA girdisi.
///
/// **Görsel artık SAYFAYA YAPIŞTIRILMIŞ bir fotoğraf gibi çiziliyor** (52
/// piksellik bir liste simgesi değil): defterin sayfasında bir fotoğraf
/// varsa görülmesi gerekir — küçük kare önizleme "bir dosya var" diyordu
/// ama hangi fotoğraf olduğunu söylemiyordu. Belge/sunum/video ise satır
/// olarak kalır: onların önizlemesi zaten kendi ekranlarında.
class _FileEntry extends StatelessWidget {
  const _FileEntry({
    required this.attachment,
    required this.onTap,
    required this.onRename,
    required this.onMove,
    required this.onDelete,
    this.onPlaceOnPage,
  });

  final Attachment attachment;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onMove;
  final VoidCallback onDelete;

  /// Görseli sayfaya (tuvale) taşır; yalnız görsellerde vardır.
  final VoidCallback? onPlaceOnPage;

  @override
  Widget build(BuildContext context) =>
      attachment.kind == AttachmentKind.image ? _photo(context) : _row(context);

  Widget _photo(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14, top: 2),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Beyaz kenarlık + hafif gölge: kâğıda yapıştırılmış fotoğraf.
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: scheme.shadow.withValues(alpha: 0.18),
                    blurRadius: 6,
                    offset: const Offset(1, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: SizedBox(
                  height: 190,
                  width: double.infinity,
                  child: _thumb(context, scheme, big: true),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(top: 4, start: 2),
                    child: Text(
                      attachment.fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                _EntryMenu(
                  onRename: onRename,
                  onMove: onMove,
                  onDelete: onDelete,
                  onPlaceOnPage: onPlaceOnPage,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10, top: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 52,
                height: 52,
                child: _thumb(context, scheme),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attachment.fileName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    formatBytes(attachment.sizeBytes),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            _EntryMenu(onRename: onRename, onMove: onMove, onDelete: onDelete),
          ],
        ),
      ),
    );
  }

  Widget _thumb(BuildContext context, ColorScheme scheme, {bool big = false}) {
    final icon = Container(
      color: scheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        _ArchiveNoteScreenState._iconFor(attachment.kind),
        size: big ? 48 : 24,
        color: scheme.onSurfaceVariant,
      ),
    );
    if (attachment.kind != AttachmentKind.image) return icon;
    // Çözünürlük GÖSTERİLEN boyuta göre: tam boy bir fotoğrafı belleğe açmak
    // (12 MP ≈ 48 MB) uzun sayfalarda çöküşe kadar gidiyor.
    final cacheWidth = big ? 900 : 156;
    if (localFileExists(attachment.localPath)) {
      return Image.file(
        File(attachment.localPath),
        fit: BoxFit.cover,
        cacheWidth: cacheWidth,
        errorBuilder: (_, _, _) => icon,
      );
    }
    if (attachment.isUploaded) {
      return CachedNetworkImage(
        imageUrl: attachment.downloadUrl,
        fit: BoxFit.cover,
        memCacheWidth: cacheWidth,
        errorWidget: (_, _, _) => icon,
      );
    }
    return icon;
  }
}

/// Girdi satırının ⋮ menüsü: yeniden adlandır (dosya), sayfa değiştir, sil.
class _EntryMenu extends StatelessWidget {
  const _EntryMenu({
    required this.onMove,
    required this.onDelete,
    this.onRename,
    this.onPlaceOnPage,
  });

  final VoidCallback? onRename;
  final VoidCallback onMove;
  final VoidCallback onDelete;

  /// Görseli sayfaya yerleştirir (metin etrafından aksın).
  final VoidCallback? onPlaceOnPage;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 18),
      padding: EdgeInsets.zero,
      tooltip: l10n.more,
      onSelected: (value) => switch (value) {
        'rename' => onRename?.call(),
        'page' => onPlaceOnPage?.call(),
        'move' => onMove(),
        _ => onDelete(),
      },
      itemBuilder: (context) => [
        if (onRename != null)
          PopupMenuItem(value: 'rename', child: Text(l10n.archiveEntryTitle)),
        if (onPlaceOnPage != null)
          PopupMenuItem(value: 'page', child: Text(l10n.archivePlaceOnPage)),
        PopupMenuItem(value: 'move', child: Text(l10n.archiveMoveEntry)),
        PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
      ],
    );
  }
}

/// Bir notun eklerini arşiv defterine **fiziksel kopya** olarak taşır.
///
/// Kullanıcının açık tercihi (2026-08-16): "içeriğindeki belgeleri resimleri
/// kopyalasın kaybolmaması için". Aynı dosyayı paylaşmak (ikinci bir ek
/// kaydının aynı Storage yolunu göstermesi) depodan tasarruf ederdi ama
/// kaynak not silindiğinde dosya da silinirdi — arşivin varlık sebebi tam
/// olarak bunun olmaması.
///
/// Bedeli: dosya Storage'da İKİ KEZ yer kaplar ve ikinci kopya yükleme
/// kuyruğuna girer.
///
/// Döndürdüğü değer kopyalanan ek sayısıdır.
Future<int> copyAttachmentsToArchive({
  required Note source,
  required Note archive,
  required AttachmentRepository attachments,
  required NotesRepository notes,
  String section = '',
}) async {
  final copied = <Attachment>[];
  for (final original in source.attachments) {
    try {
      final bytes = await attachments.readBytes(original);
      if (bytes == null) continue;
      final stored = switch (original.kind) {
        AttachmentKind.pdf => await attachments.preparePdf(
          noteId: archive.id,
          bytes: bytes,
          fileName: original.fileName,
        ),
        AttachmentKind.slide => await attachments.prepareSlide(
          noteId: archive.id,
          bytes: bytes,
          fileName: original.fileName,
        ),
        _ => await attachments.prepareImage(
          noteId: archive.id,
          bytes: bytes,
          fileName: original.fileName,
        ),
      };
      copied.add(stored.copyWith(asFile: true, section: section));
    } catch (_) {
      // Okunamayan/çok büyük ek kalanları düşürmesin.
    }
  }
  if (copied.isEmpty) return 0;
  await notes.updateNote(
    archive.copyWith(attachments: [...archive.attachments, ...copied]),
  );
  return copied.length;
}
