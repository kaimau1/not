part of 'note_editor_screen.dart';

/// **OKUNURLUK — NOTUN İÇİ ZEMİNE GÖRE** (kullanıcı bulgusu 2026-11-04: "not
/// arka plan rengini değiştirince bazen yazı rengi sabit kaldığı için okuma
/// zorluğu oluyor"). Not zemini temanın yazısıyla okunmuyorsa
/// (`NoteColors.inkThemeFor` — açık temada koyu özel renk ya da tersi)
/// editör ZIT temayla çizilir: build notun zeminini hesaplayınca o temayı
/// burada saklar ve ağacı `Theme` ile sarar. Bu dosyada (ve parçalarında)
/// ekranın KENDİ bağlamından tema okuyan her yer `Theme.of` yerine bunu
/// kullanır — yoksa build içinde hesaplanan yazı stili (gövde, başlık, işaret
/// rengi) dış temada kalırdı. Başka bağlamlar (alt widget'lar) zaten sarılan
/// temanın altında, `Theme.of` ile doğru temayı görür.
/// Üst çubuk saydam olduğu için durum çubuğu simgesi sayfanın renginden seçilir.
SystemUiOverlayStyle _statusBarFor(Color page) {
  final dark = ThemeData.estimateBrightnessForColor(page) == Brightness.dark;
  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
    statusBarBrightness: dark ? Brightness.dark : Brightness.light,
  );
}

final _editorInk = Expando<ThemeData>('editorInk');

ThemeData _themeOf(BuildContext context) =>
    _editorInk[context] ?? Theme.of(context);

/// Otomatik kaydın sessizlik süresi ve aralıksız yazımdaki üst sınırı
/// (F22.2, KARAR 2026-11-03; 2026-11-17 senkron maliyeti S2: üst sınır
/// 10 → 20 sn). Çalışma anında `config/app` ile uzaktan değişebilir:
/// [SaveCadence].
const kEditorSaveDelay = SaveCadence.defaultDelay;
const kEditorSaveMaxWait = SaveCadence.defaultMaxWait;

/// İki madde listesi EKRANDA aynı mı? Yalnız madde METNİ değiştiyse aynı
/// sayılır: o metni satırın kendi denetleyicisi zaten çiziyor.
///
/// KÖK NEDEN (yazarken kasma) — editörün saf-yazım kısayolu ([_sameVisual])
/// eskiden madde listelerini `identical` ile karşılaştırıyordu. Bir maddeye
/// yazmak `ItemsEditor` üzerinden HER TUŞTA yeni bir liste nesnesi üretir,
/// dolayısıyla `identical` hep false çıkıyor ve kısayol yalnız gövde/başlık
/// alanında işliyordu: LİSTE notunda her harf, editörün 3700 satırlık
/// build'ini (sayfa tuvali, çipler, ek şeridi, bütün satırlar) yeniden
/// kuruyordu.
///
/// Metin dışındaki her fark (sayı, sıra, kimlik, işaret) görünürdür. Metnin
/// DOLULUĞU da öyle: `Note.isEmpty` menü girdilerini ve ipucunu etkiliyor.
@visibleForTesting
bool sameItemsVisually(List<NoteItem> a, List<NoteItem> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    final x = a[i];
    final y = b[i];
    if (x.id != y.id ||
        x.checked != y.checked ||
        // Yıldız satırda bir simge çiziyor: değişimi "görünmez" sayılırsa
        // yalnız `ItemsEditor`ın kendi setState'i onu gösterir, kart
        // önizlemesi ve dışa aktarma bayat kalırdı.
        x.starred != y.starred ||
        // Madde altı ayırıcı çizgi de satırda çiziliyor.
        x.divider != y.divider ||
        // Ara başlık kutucuksuz, kalın çizilir.
        x.header != y.header ||
        x.align != y.align ||
        // Paket satırları özet hapına toplar (bkz. NoteItem.package).
        x.package != y.package ||
        !sameNoteItemStructuredFields(x, y) ||
        !sameNoteItemExtras(x.extras, y.extras) ||
        isBlankText(x.text) != isBlankText(y.text)) {
      return false;
    }
  }
  return true;
}

/// İki not EKRANDA aynı mı çizilir?
///
/// KÖK NEDEN (kasma — "yeni öğe eklemesem bile kasma devam ediyor"):
/// Firestore'un gecikme telafisi, editörün KENDİ kaydını da anında bir anlık
/// görüntü olarak geri gönderir. Akış dinleyicisi bunu koşulsuz `setState`
/// ile karşılıyordu, yani yazarken (debounce 0,5 sn / en geç 3 sn) düzenli
/// aralıklarla editörün tamamı — sayfa tuvali, sarma ölçümü, bütün madde
/// satırları — boşuna yeniden kuruluyordu. Yankıda çizimi değiştiren hiçbir
/// şey olmadığı için bu karşılaştırma o build'i tümden atlar.
///
/// Metnin KENDİSİ bilerek dışarıda: onu satırların/alanların kendi
/// denetleyicileri çiziyor (bkz. [sameItemsVisually]). Eklerde de yalnız
/// YERLEŞİMİ ve durumu etkileyen alanlar bakılır.
@visibleForTesting
/// TAHSİSSİZ "boş mu" denetimi.
///
/// KÖK NEDEN (GC baskısı): `text.trim().isEmpty` her çağrıda yeni bir dizgi
/// ayırıyor. Bu denetim HER TUŞ VURUŞUNDA madde sayısı kadar koşuyordu; 50
/// maddelik bir notta tuş başına 100 gereksiz dizgi. Tek başına takılma
/// yaratmaz, ama kare bütçesini diğer maliyetlerle birlikte aşırıyordu.
bool isBlankText(String s) {
  for (var i = 0; i < s.length; i++) {
    final c = s.codeUnitAt(i);
    // Boşluk, sekme, satır sonu ve NBSP — `trim()`in kırptığı yaygın küme.
    if (c != 0x20 && c != 0x09 && c != 0x0A && c != 0x0D && c != 0xA0) {
      return false;
    }
  }
  return true;
}

bool sameRenderedNote(Note a, Note b) {
  if (identical(a, b)) return true;
  if (!sameItemsVisually(a.items, b.items)) return false;
  if (a.type != b.type ||
      a.pageInk.length != b.pageInk.length ||
      // Sayfa geçişi/ekleme çubuğu ve tuvali değiştirir (Note.textPages).
      a.activePage != b.activePage ||
      a.textPages.length != b.textPages.length ||
      a.lineSpacing != b.lineSpacing ||
      a.color != b.color ||
      a.frameColor != b.frameColor ||
      a.customColor != b.customColor ||
      a.customFrameColor != b.customFrameColor ||
      a.pinned != b.pinned ||
      a.starred != b.starred ||
      a.urgent != b.urgent ||
      a.locked != b.locked ||
      a.folderId != b.folderId ||
      a.fontFamily != b.fontFamily ||
      a.fontScale != b.fontScale ||
      a.textOpacity != b.textOpacity ||
      a.titleFontFamily != b.titleFontFamily ||
      a.titleFontScale != b.titleFontScale ||
      a.titleTextOpacity != b.titleTextOpacity ||
      a.backgroundImageId != b.backgroundImageId ||
      a.backgroundOpacity != b.backgroundOpacity ||
      a.theme != b.theme ||
      // Defter görünümü ve kâğıt deseni (bkz. `_sameVisual` kök neden notu).
      a.listKind != b.listKind ||
      a.listMode != b.listMode ||
      a.resetSchedule != b.resetSchedule ||
      !_sameInts(a.resetCustomDays, b.resetCustomDays) ||
      a.lastResetAt != b.lastResetAt ||
      a.contextTimeSlot != b.contextTimeSlot ||
      a.isQuickInbox != b.isQuickInbox ||
      a.paged != b.paged ||
      a.archivePaper != b.archivePaper ||
      a.orderIndex != b.orderIndex ||
      a.deletedAt != b.deletedAt ||
      a.archivedAt != b.archivedAt ||
      a.reminderAt != b.reminderAt ||
      a.expiresAt != b.expiresAt ||
      a.updatedAt != b.updatedAt ||
      a.aiSummary != b.aiSummary ||
      a.title != b.title ||
      // Gövdenin DOLULUĞU tuval ipucunu ve gövde alanının varlığını belirler.
      isBlankText(a.body) != isBlankText(b.body)) {
    return false;
  }
  if (a.tags.length != b.tags.length) return false;
  for (var i = 0; i < a.tags.length; i++) {
    if (a.tags[i] != b.tags[i]) return false;
  }
  // Sayfa notları çizimi ETKİLER (PDF notunun alt bölmesi ve kart önizlemesi).
  // Metnin kendisi burada karşılaştırılır — gövdeden farklı olarak sayfa notu
  // alanı sayfa değişiminde yeniden doldurulduğu için "denetleyici zaten
  // ekranda" muafiyeti geçerli değil.
  if (a.pageNotes.length != b.pageNotes.length) return false;
  for (final entry in a.pageNotes.entries) {
    if (b.pageNotes[entry.key] != entry.value) return false;
  }
  if (a.attachments.length != b.attachments.length) return false;
  for (var i = 0; i < a.attachments.length; i++) {
    final x = a.attachments[i];
    final y = b.attachments[i];
    if (x.id != y.id ||
        x.kind != y.kind ||
        x.floatsOnPage != y.floatsOnPage ||
        // Sayfaya gömülü PDF'in GÖRÜNEN durumu: sayfa numarası, görüntü
        // döndürmesi ve yer imleri kutuyu değiştirir (bkz. PdfPageBox).
        x.pdfPage != y.pdfPage ||
        x.pdfTurns != y.pdfTurns ||
        !_sameInts(x.pdfMarks, y.pdfMarks) ||
        x.x != y.x ||
        x.pageY != y.pageY ||
        x.y != y.y ||
        x.displayWidth != y.displayWidth ||
        x.width != y.width ||
        x.height != y.height ||
        x.downloadUrl != y.downloadUrl ||
        x.fileName != y.fileName ||
        // Üste sabitleme/bölme yüksekliği ve YouTube bağlantısı da çizimi
        // değiştirir — sayılmasaydı sabitlenen görsel ekranda yerinde kalırdı.
        x.pinHeight != y.pinHeight ||
        x.webUrl != y.webUrl ||
        x.section != y.section ||
        // Sabit/sayfadaki belge kutusu balonları da çizer (bkz. PdfPageBox).
        x.bubblesHidden != y.bubblesHidden ||
        // Görselin altındaki açıklama ve sesin dalgası da kutuda çizilir.
        x.caption != y.caption ||
        !_sameInts(x.wave, y.wave) ||
        !_sameBubbles(x.bubbles, y.bubbles) ||
        !identical(x.ink, y.ink)) {
      return false;
    }
  }
  return true;
}

/// Balonların GÖRÜNEN hâli aynı mı (her anlık görüntü yeni liste kurduğu
/// için kimlik değil içerik karşılaştırılır).
bool _sameBubbles(List<PageBubble> a, List<PageBubble> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    final x = a[i];
    final y = b[i];
    if (x.id != y.id ||
        x.page != y.page ||
        x.x != y.x ||
        x.y != y.y ||
        x.title != y.title ||
        x.text != y.text ||
        x.color != y.color ||
        x.size != y.size ||
        x.collapsed != y.collapsed ||
        x.starred != y.starred ||
        x.urgent != y.urgent ||
        x.plain != y.plain ||
        x.rects.length != y.rects.length) {
      return false;
    }
  }
  return true;
}

/// İki sayı listesi aynı mı (yer imleri gibi kısa listeler için).
bool _sameInts(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Bir liste satırının başındaki işaretleri ayıklar: madde imi (-, •, *),
/// numara (1. / 1)) ve onay kutusu ([ ], [x]). Onay kutusu doluysa
/// [checked] true döner. AI çıktısı / yapıştırılan metin nota geri
/// uygulanırken bu işaretlerin öğe metnine sızmasını engeller (madde 1:
/// "notların başına çift parantez ve çarpılı durum ekliyor").
({String text, bool checked}) _parseListLine(String line) {
  var s = line.trim();
  s = s.replaceFirst(RegExp(r'^[-•*]\s+'), '');
  s = s.replaceFirst(RegExp(r'^\d+[.)]\s+'), '');
  var checked = false;
  final box = RegExp(r'^\[\s*([xX])?\s*\]\s*').firstMatch(s);
  if (box != null) {
    checked = box.group(1) != null;
    s = s.substring(box.end);
  }
  return (text: s.trim(), checked: checked);
}


/// Üst çubuk başlığının boşluğu (F38.2): tarih sayfa metninin sol kenarında.
/// Geri oku yokken 16 dp (derin bağlantı, web yenileme); geniş bölmede okuma
/// sütununa hizalı. [hasLeading]: solda 56 dp düğme var.
/// Üst çubuktaki düzenleme tarihi, KISA (kullanıcı isteği 2026-11-05: "üst
/// alanda sadeleşme" — "5 Kas 2026 13:…" dar çubukta kesiliyordu): bugün
/// yalnız saat, bu yıl gün + ay + saat, daha eskisi gün + ay + yıl.
String editorBarDate(DateTime at, DateTime now) {
  if (at.year == now.year && at.month == now.month && at.day == now.day) {
    return DateFormat('HH:mm').format(at);
  }
  if (at.year == now.year) return DateFormat('d MMM HH:mm').format(at);
  return DateFormat('d MMM y').format(at);
}

double editorTitleSpacing(double paneWidth, {required bool hasLeading}) {
  final textLeft = readingMargin(paneWidth) + 16;
  return hasLeading ? math.max(0, textLeft - kToolbarHeight) : textLeft;
}

/// Okuma sütununun bölme içindeki kenar boşluğu; dar ekranda 0.
double readingMargin(double paneWidth) =>
    paneWidth > kReadingWidth ? (paneWidth - kReadingWidth) / 2 : 0.0;

/// Testte geniş web hızlı satır yolunu açar (`kIsWeb` testte hep false).
@visibleForTesting
bool debugWideWebQuickRow = false;

/// [title]'ı yalnız başta [spacing] (sonda en çok 16 dp) payla sarar; bkz.
/// AppBar'daki `titleSpacing: 0` notu.
Widget? _titleWithSpacing(double spacing, Widget? title) => title == null
    ? null
    : Padding(
        padding: EdgeInsetsDirectional.only(
          start: spacing,
          end: math.min(spacing, 16),
        ),
        child: title,
      );


/// Başlık üst çubuktayken (`_barTitle`) klavye açılınca `KeyboardSwitch` onu
/// `Offstage` yapar; aynı karede sağdaki düğmeler gizlenince `NavigationToolbar`
/// orta yuvayı genişletir ve gizli `titleField` (`LayoutBuilder` + `TextField`)
/// gereksiz yere kurulurdu (S17). Gizliyken son görünür üst sınırı korur;
/// görünür olunca güncel genişliği alır.
class _HoldOffstageWidth extends SingleChildRenderObjectWidget {
  const _HoldOffstageWidth({required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderHoldOffstageWidth();
}

class _RenderHoldOffstageWidth extends RenderProxyBox {
  double? _lastWidth;

  bool get _isOffstage {
    var cur = parent;
    for (var i = 0; i < 6 && cur != null; i++) {
      if (cur is RenderOffstage) return cur.offstage;
      cur = cur.parent;
    }
    return false;
  }

  BoxConstraints _stabilize(
    BoxConstraints constraints, {
    required bool record,
  }) {
    final hidden = _isOffstage;
    if (!hidden) {
      if (record && constraints.hasBoundedWidth) {
        _lastWidth = constraints.maxWidth;
      }
      return constraints;
    }
    final last = _lastWidth;
    if (last == null || !constraints.hasBoundedWidth) return constraints;
    final held = math.min(constraints.maxWidth, last);
    if (held < constraints.minWidth) return constraints;
    return constraints.copyWith(maxWidth: held);
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      super.computeDryLayout(_stabilize(constraints, record: false));

  @override
  void performLayout() {
    final c = _stabilize(constraints, record: true);
    if (child != null) {
      child!.layout(c, parentUsesSize: true);
      size = constraints.constrain(child!.size);
    } else {
      size = constraints.smallest;
    }
  }
}

/// Webde alt çubuğa fare tıklaması metin alanının "dışarı tıklaması"
/// sayılmasın (tablo hücresi düzenlemeden çıkıyordu); telefonda ağaca ek
/// widget girmez — dokunmatikte bu kural yok.
Widget _webTextTapRegion(Widget child) =>
    kIsWeb ? TextFieldTapRegion(child: child) : child;
