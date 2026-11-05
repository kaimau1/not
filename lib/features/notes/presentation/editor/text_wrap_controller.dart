part of 'text_wrap.dart';

// F18.23: WrapTextController text_wrap.dart'tan taşındı (davranış aynı).

/// Gövde alanının denetleyicisi: kullanıcının yazdığı metni (mantıksal) ve
/// ekranda dizilen metni (çapalı) birbirine çevirir.
///
/// Kayan görsel yokken plan kimliktir ve denetleyici sıradan bir
/// [TextEditingController] gibi davranır (IME'nin oluşturma aralığı dahil
/// hiçbir şeye dokunulmaz) — sarma yalnız görsel varken devreye girer.
class WrapTextController extends TextEditingController {
  WrapTextController({super.text});

  List<double> _widths = const [];
  List<FloatBox> _floats = const [];
  RichTextTheme? _rich;
  TextStyle? _style;
  double _columnWidth = 0;
  double _textScale = 1.0;
  TextDirection _direction = TextDirection.ltr;

  /// Notun ek dosya adları — metne gömülü ek etiketlerini (bkz.
  /// attachment_tag.dart) bulup kırmızı çizmek için. Ölçüm yolu da AYNI
  /// listeyi kullanır: renk ve alt çizgi satır genişliğini değiştirmediği
  /// için ölçüm ile çizim ayrışmaz, ama iki taraf aynı işlevden geçsin diye
  /// yine de her ikisine verilir.
  List<String> _attachmentNames = const [];

  set attachmentNames(List<String> value) {
    if (_attachmentNames.length == value.length &&
        _attachmentNames.join('\u0000') == value.join('\u0000')) {
      return;
    }
    _attachmentNames = value;
    // Yalnız ÇİZİM değişti (renk/alt çizgi); satır kırılımı aynı kaldığı için
    // yeniden dizmeye gerek yok — span önbelleği düşürülüp yeniden çizilir.
    _spanCache = null;
    notifyListeners();
  }

  /// Metindeki ek etiketlerinin adları (imleç konumundan hangi eke
  /// bakılacağını çağıran bulur).
  List<String> get attachmentNames => _attachmentNames;

  /// Etiket adı → ekin türünün rengi. Doluysa etiketler ÇİP kipinde çizilir
  /// (ataç saydam, ad türün renginde — çipi ve rozeti alanı saran
  /// `AttachmentTagChips` boyar). Boşsa eski görünüm (kırmızı, altı çizili):
  /// alanın üstünde boyayıcı yoksa çip de olmaz.
  Map<String, Color> _tagChipColors = const {};

  set tagChipColors(Map<String, Color> value) {
    if (mapEquals(_tagChipColors, value)) return;
    _tagChipColors = value;
    // Yalnız renk değişti; satır kırılımı aynı (bkz. [attachmentNames]).
    _spanCache = null;
    notifyListeners();
  }

  Map<String, Color> get tagChipColors => _tagChipColors;

  /// Notta VİDEO var mı: varsa metindeki "1:23" gibi zaman damgaları
  /// bağlantı renginde çizilir (bkz. video_time.dart). Yalnız çizim değişir;
  /// satır kırılımı aynı kalır.
  bool _videoTimestamps = false;

  set videoTimestamps(bool value) {
    if (_videoTimestamps == value) return;
    _videoTimestamps = value;
    _spanCache = null;
    _scanText = null;
    notifyListeners();
  }

  bool get videoTimestamps => _videoTimestamps;

  /// Nota yazılacak, çapasız gövde metni.
  String get logicalText => stripWrapAnchors(text);

  /// Biçimlendirmenin çizim ayarları (renk paleti + işaret rengi). Tema
  /// bağımlı olduğu için dışarıdan verilir; değişince dizgi tazelenir çünkü
  /// kalın/italik metnin genişliği satır kırılımını etkiler.
  set richTheme(RichTextTheme? value) {
    if (_rich == value) return;
    _rich = value;
    if (_floats.isNotEmpty && _style != null && _columnWidth > 0) {
      _reflowKeepingSelection();
    }
  }

  /// Mantıksal metni ve imleç/seçim konumunu birlikte yazar (biçim uygulama).
  ///
  /// [extent] verilirse seçim KORUNUR: biçim uygulanan metin seçili kalır ve
  /// kullanıcı üst üste iki biçim verebilir (kalın + renk).
  void setLogical(String logical, int caret, [int? extent]) =>
      _reflow(logical, caret, extent);

  /// Metni değiştirmeden yeniden dizer; imleç VE seçim olduğu gibi kalır.
  ///
  /// KÖK NEDEN (v1.0.168): burası eskiden imleci topluyordu. Yazı tipi/boyut
  /// değişmek ya da bir görselin taşınması dizgiyi tazeliyor, tazeleme de
  /// kullanıcının seçimini siliyordu — sarma çapası bulunan bir notta metin
  /// seçmek imkânsızdı ("yazı tipi değiştiğinde sayfada yazıları seçemiyorum").
  void _reflowKeepingSelection() {
    final base = selection.baseOffset;
    final extent = selection.extentOffset;
    _reflow(
      logicalText,
      wrapToLogicalOffset(text, base < 0 ? text.length : base),
      extent < 0 || extent == base ? null : wrapToLogicalOffset(text, extent),
    );
  }

  /// Tamponda hiç dolgu yok (sarma kapalı) — sıradan bir denetleyici gibi.
  bool get isPlain => _widths.isEmpty;

  /// Kullanıcının gördüğü metni değiştirmeden dizgi girdilerini günceller
  /// (görsel taşınınca/boyutlanınca ya da sütun genişliği değişince).
  /// Girdiler aynıysa hiçbir şey yapmaz — her build'de çağrılabilir.
  void updateLayout({
    required List<FloatBox> floats,
    required TextStyle style,
    required double columnWidth,
    double textScaleFactor = 1.0,
    TextDirection direction = TextDirection.ltr,
  }) {
    if (_columnWidth == columnWidth &&
        _textScale == textScaleFactor &&
        _style == style &&
        _direction == direction &&
        sameFloatList(_floats, floats)) {
      return;
    }
    _floats = floats;
    _style = style;
    _columnWidth = columnWidth;
    _textScale = textScaleFactor;
    _direction = direction;
    _reflowKeepingSelection();
  }

  /// Mantıksal metni doğrudan yazar (AI sonucu, geri alma, not yükleme...).
  @override
  set text(String newText) {
    clearPendingFormat();
    _reflow(newText, newText.length);
  }

  // ---- Bekleyen biçim ---------------------------------------------------

  /// Seçim yokken biçim düğmesine basıldığında metne DOKUNULMAZ; biçim burada
  /// bekler ve bir sonraki yazılan metin işaretlerin İÇİNE girer.
  ///
  /// KÖK NEDEN (kullanıcı: "yine biçim verirken işaretler çıkıyor… boşluğa
  /// veya satır sonuna yapınca"): eskiden metne boş kutu (`~~`, `__`) yazılıp
  /// imleç arasına konuyordu. İçine bir şey yazılmazsa o işaretler notta ham
  /// markdown olarak kalıyordu; üstelik gizleme kalıbı (`_emptyBoxPattern`)
  /// yalnız `****`/`==:==` gibi kutuları tanıdığı için italik ve altı çizili
  /// kutuları EKRANDA da görünüyordu. Kutuyu hiç yazmamak hem çöpü bitiriyor
  /// hem de kalıbı genişletip `__init__` gibi gerçek metni kırpma riskini
  /// doğurmuyor.
  /// BİRDEN ÇOK biçim aynı anda bekleyebilir (kullanıcı: "biçim alanı
  /// Keep'teki gibi olmalı… birden çok açılabilmeli, açılanlarla yazmaya
  /// devam etmeli"). Keep'te B, I ve U aynı anda basılı kalır ve yazılan
  /// metin üçünü birden alır. Ekleme sırası KORUNUR (LinkedHashMap): önce
  /// basılan biçim dışta sarar, böylece işaretler düzgün iç içe geçer.
  final Map<RichFormat, int?> _pending = {};
  int? _pendingAt;

  bool get hasPendingFormat => _pending.isNotEmpty;

  /// Bekleyen biçimler — şerit hangi düğmeyi "basılı" göstereceğini buradan
  /// da okur (metinden gelen biçimlerin YANINDA).
  Map<RichFormat, int?> get pendingFormats => Map.unmodifiable(_pending);

  /// Biçmi bekleyenlere ekler, zaten bekliyorsa KALDIRIR (aç/kapa).
  ///
  /// İmleç yer değiştirmişse önceki bekleyenler düşer: bekleme "buradan
  /// itibaren yazılacak metin" demektir, imleç taşınınca niyet de biter.
  void togglePendingFormat(RichFormat format, int? index) {
    // Aç/kapa kararı flush'tan ÖNCE verilir: flush bekleyenleri temizlediği
    // için sonra bakılsaydı kapatılan biçim yeniden açılırdı.
    final wasPending =
        _pending.containsKey(format) && _pending[format] == index;
    final carry = <RichFormat, int?>{..._pending};
    if (wasPending) {
      carry.remove(format);
    } else {
      carry[format] = index;
    }
    // KOŞU ORTASINDA biçim değişimi (Word'de "kalın yaz, kalını kapat, düz
    // devam et"): o ana kadar yazılmış metin ÖNCE işaretlerine kavuşur, imleç
    // kutunun DIŞINA çıkar, KALAN biçimler yeni koşuda sürer. Yoksa kapatılan
    // biçim yazılan metne hiç uygulanmaz — kullanıcı "kalın yazamıyorum" derdi.
    if (pendingRange != null) {
      flushPendingFormat(caretOutside: true);
    }
    final caret = selection.baseOffset;
    _pending
      ..clear()
      ..addAll(carry);
    _pendingAt = caret;
    _pendingEnd = caret;
    // Şerit denetleyiciyi dinliyor: basış ANINDA düğme yanmalı
    // ("basınca direkt aktifleştiği belli olmalı").
    notifyListeners();
  }

  /// Bekleyen biçimleri [formats] ile DEĞİŞTİRİR (aç/kapa değil): boş
  /// satırda başlık düzeyi seçmek (bkz. `applyRichHeading`). Boş küme
  /// beklemeyi kaldırır. Süren koşu önce metne yazılır.
  void setPendingFormats(Map<RichFormat, int?> formats) {
    if (pendingRange != null) flushPendingFormat(caretOutside: true);
    _pending
      ..clear()
      ..addAll(formats);
    if (formats.isEmpty) {
      _pendingAt = null;
      _pendingEnd = null;
    } else {
      _pendingAt = selection.baseOffset;
      _pendingEnd = selection.baseOffset;
    }
    notifyListeners();
  }

  void clearPendingFormat() {
    if (_pending.isEmpty && _pendingAt == null) return;
    _pending.clear();
    _pendingAt = null;
    _pendingEnd = null;
  }

  /// Koşunun O ANA KADAR yazılmış son ucu ([_pendingAt] başı, bu sonu).
  ///
  /// İmleç koşunun dışına taşındığında (kullanıcı metnin başka bir yerine
  /// dokundu) sarılacak aralık buradan okunur; yoksa o ana kadar yazılmış
  /// metin biçimsiz kalırdı.
  int? _pendingEnd;

  /// Bekleyen biçimin CANLI aralığı: `[başlangıç, imleç)`. Bu aralık tamponda
  /// İŞARETSİZ durur ama EKRANDA biçimli çizilir (bkz. [buildTextSpan]).
  ///
  /// KULLANICI İSTEĞİ ("kalın butonuna basıp kalın yazamıyorum... Word'deki
  /// gibi olmalı"): eskiden yazılan harfler işaretler tampona girene kadar DÜZ
  /// görünüyor, biçim ancak kelime bitince beliriyordu. Artık biçim basılır
  /// basılmaz ekranda: tampona hiç dokunulmadan, yalnız çizim stiliyle.
  (int, int)? get pendingRange {
    final at = _pendingAt;
    if (_pending.isEmpty || at == null) return null;
    final sel = selection;
    if (!sel.isValid || !sel.isCollapsed) return null;
    final caret = sel.baseOffset;
    if (at < 0 || caret <= at || at > text.length || caret > text.length) {
      return null;
    }
    return (at, caret);
  }

  /// Bekleyen biçimlerin birikmiş hâli (canlı önizlemenin stili).
  RichMark get pendingMark {
    var mark = RichMark.none;
    for (final entry in _pending.entries) {
      mark = mark.applied(entry.key, entry.value);
    }
    return mark;
  }

  /// Bekleyen biçimi metne YAZAR — koşu BİTTİĞİNDE.
  ///
  /// Çağrı yerleri: alan odaktan çıkıyor, imleç koşunun dışına taşındı, biçim
  /// kümesi değişti ya da not kaydediliyor. Yazacak bir şey yoksa yalnız
  /// beklemeyi düşürür.
  /// [caretOutside] true ise imleç KAPANIŞ işaretlerinin ARDINA konur.
  /// Biçmi KAPATAN kullanıcı bunu ister: "kalın yaz, kalını kapat, düz devam
  /// et"te imleç kutunun içinde kalsaydı sonraki metin de kalın olurdu.
  void flushPendingFormat({bool caretOutside = false}) {
    final wrapped = _wrapRun(value, caretOutside: caretOutside);
    if (wrapped != null) {
      super.value = _snapped(wrapped);
      clearPendingFormat();
      notifyListeners();
    } else {
      clearPendingFormat();
    }
  }

  /// Koşuyu (`[_pendingAt, imleç)`) işaretlerin içine alır.
  ///
  /// KÖK NEDEN — TAMPONA KOŞU BOYUNCA HİÇ DOKUNULMAZ (2026-08-07 / 12. tur;
  /// kullanıcı: "yine markdownlar çıkıyor, kalın butonuna basıp kalın
  /// yazamıyorum"):
  ///
  /// Sarma önce "IME oluşturma aralığı bitti" anında, sonra KELİME SINIRINDA
  /// yapılıyordu. İkisi de aynı hataya düşüyor: Gboard bir koşu boyunca kendi
  /// metin modelini tutar ve oluşturma aralığını arada bir kapatıp yeniden
  /// açar (otomatik düzeltme, tahmin, imleç güncellemesi, boşluk sonrası
  /// yeniden açılış). Tampona o anlarda işaret sokmak klavyenin konumlarını
  /// KAYDIRIR; Gboard bir sonraki tuşta bayat konumuna yazınca işaretler
  /// metnin ortasına dağılır ve EŞİ KALMAYAN işaret ham markdown olarak
  /// çizilir (`richSpans` eşleşmeyen işareti düz karakter sayar).
  ///
  /// Artık işaret, kullanıcı koşuyu BİTİRENE kadar hiç yazılmaz — yazdığı
  /// metin ekranda [pendingRange] sayesinde zaten biçimli görünür. Yani
  /// tamponda koşu başına TEK müdahale kalır ve o da klavyenin koşuyu
  /// bıraktığı andan sonradır.
  /// [endOverride] verilirse koşunun sonu ORADAN okunur. Koşuyu bitiren olay
  /// imleci koşunun DIŞINA taşımış olabilir (kullanıcı metnin ilerisine
  /// dokundu); o zaman gelen imleç koşunun sonu DEĞİLDİR ve aradaki metin
  /// yanlışlıkla biçimin içine alınırdı.
  TextEditingValue? _wrapRun(
    TextEditingValue next, {
    int? endOverride,
    bool caretOutside = false,
  }) {
    final at = _pendingAt;
    if (_pending.isEmpty || at == null) return null;
    if (at < 0 || at > next.text.length) return null;
    // Koşunun sonu: imleç hâlâ koşunun içindeyse oradan, dışına taşındıysa
    // en son bilinen uçtan (bkz. [_pendingEnd]).
    final caret = next.selection.baseOffset;
    final inRun =
        next.selection.isCollapsed && caret > at && caret <= next.text.length;
    final end = endOverride ?? (inRun ? caret : (_pendingEnd ?? at));
    if (end <= at || end > next.text.length) return null;
    final typed = next.text.substring(at, end);
    if (typed.isEmpty) return null;
    // Bekleyenler İÇ İÇE sarılır; önce basılan en DIŞTA kalır.
    //
    // KÖK NEDEN — SATIR SONU koşuyu BÖLER (2026-08-07 / 14. tur): biçim
    // kalıbı satır sonuyla eşleşmiyor (`dotAll: false` — biçim satırda başlar,
    // satırda biter). Koşu içinde Enter'a basılıp devam edildiğinde
    // `**abc\ndef**` yazılıyordu; hiçbir eşleşme çıkmadığı için İKİ işaret de
    // ham markdown olarak çiziliyor ve nota öyle kaydediliyordu. Her satır
    // parçası artık AYRI sarılır: `**abc**\n**def**`.
    //
    // KÖK NEDEN — KELİME SINIRI: italik (`_`) ve altı çizili (`~`) işaretleri
    // kalıpta "iki yanında harf/rakam olmasın" şartı taşıyor, ama YAZAN taraf
    // bunu denetlemiyordu. Kelimenin ortasından başlayan bir koşu
    // `_ilk_sonrasi` üretiyor, kalıp eşleştiremiyor ve alt çizgiler ham
    // görünüyordu. Sarma artık gereken yerde kelime sınırına GENİŞLER.
    final needsBoundary = _pending.keys.any(richFormatNeedsWordBoundary);
    var from = at;
    var to = end;
    if (needsBoundary) {
      while (from > 0 && isRichWordChar(next.text[from - 1])) {
        from--;
      }
      while (to < next.text.length && isRichWordChar(next.text[to])) {
        to++;
      }
    }
    final segment = next.text.substring(from, to);
    final wrapped = StringBuffer();
    var suffixLength = 0;
    final lines = segment.split('\n');
    for (var i = 0; i < lines.length; i++) {
      if (i > 0) wrapped.write('\n');
      final line = lines[i];
      // Boş satır sarılmaz: `****` boş kutusu üretmenin âlemi yok.
      if (line.isEmpty) continue;
      var body = line;
      var suffixOfLine = 0;
      for (final entry in _pending.entries.toList().reversed) {
        final marker = entry.key.marker;
        final index = entry.value;
        final prefix = richFormatTakesIndex(entry.key) && index != null
            ? '$marker${richIndexToken(index)}:'
            : marker;
        body = '$prefix$body$marker';
        suffixOfLine += marker.length;
      }
      wrapped.write(body);
      // İmleç eşlemesi SON satırın sonekine bakar: imleç koşunun sonunda,
      // yani son satırın kapanış işaretlerinin önünde/ardında durur. Solunda
      // kalan bütün işaretler `grown` içinde toplanır.
      if (i == lines.length - 1) suffixLength = suffixOfLine;
    }
    final body = wrapped.toString();
    if (body == segment) return null;
    // Kaydırma: koşunun İÇİNE giren toplam işaret uzunluğu.
    final grown = body.length - segment.length;
    // İmleç bütün kapanış işaretlerinin ÖNÜNDE durur: koşu bittiği için
    // gerekmez ama kullanıcı aynı yerden yazmaya devam ederse metin kutunun
    // dışına düşmesin (Keep davranışı). Biçim KAPATILDIĞINDA tam tersi
    // gerekir: imleç kutunun dışına çıkar.
    final movedSelection = _shiftOffset(
      next.selection,
      at: from,
      end: to,
      prefixLength: grown - suffixLength,
      suffixLength: suffixLength,
      caretOutside: caretOutside,
    );
    return TextEditingValue(
      text: next.text.replaceRange(from, to, body),
      selection: movedSelection,
    );
  }

  /// Sarma sonrası imleci/seçimi yeni metne taşır: koşudan ÖNCEKİ konumlar
  /// yerinde kalır, koşunun İÇİ önek kadar, SONRASI önek+sonek kadar kayar.
  static TextSelection _shiftOffset(
    TextSelection selection, {
    required int at,
    required int end,
    required int prefixLength,
    required int suffixLength,
    bool caretOutside = false,
  }) {
    int move(int o) {
      if (o <= at) return o;
      if (o < end) return o + prefixLength;
      if (o == end) {
        return o + prefixLength + (caretOutside ? suffixLength : 0);
      }
      return o + prefixLength + suffixLength;
    }

    final base = selection.baseOffset;
    if (base < 0) {
      // Geçersiz seçim: metin DEĞİŞTİ ama imleç -1 kalırsa alana odak
      // dönünce imlecin yeri belirsiz olur. Sarmanın sonuna konur.
      return TextSelection.collapsed(
        offset: end + prefixLength + (caretOutside ? suffixLength : 0),
      );
    }
    final extent = selection.extentOffset < 0 ? base : selection.extentOffset;
    return TextSelection(baseOffset: move(base), extentOffset: move(extent));
  }

  /// Yeni bir değer gelirken koşunun durumunu günceller; koşu BİTTİYSE
  /// işaretleri yazar.
  ///
  /// Koşu SÜRÜYOR sayılması için değişimin imleçte yapılmış saf bir
  /// ekleme/silme olması gerekir: metin uzunluğundaki değişim ile imlecin
  /// hareketi BİREBİR aynı olmalı. Bu ölçüt, "kullanıcı yazmaya devam etti"
  /// ile "kullanıcı başka bir yere dokundu / uzağa yapıştırdı" durumlarını
  /// ayırır — ayırmasaydı metnin ilerisine dokunmak aradaki bütün metni
  /// koşunun içine alır ve hepsi kalın olurdu.
  TextEditingValue? _trackPendingRun(TextEditingValue next) {
    final at = _pendingAt;
    if (_pending.isEmpty || at == null) return null;
    final caret = next.selection.baseOffset;
    final end = _pendingEnd ?? at;
    // SAF DÜZENLEME: metin uzunluğundaki değişim ile imlecin hareketi BİREBİR
    // aynıysa kullanıcı imlecin olduğu yerde yazıyor ya da siliyor demektir.
    // (İmleç koşunun başının ALTINA da inebilir — geri silme; koşu oradan
    // yeniden başlar.)
    final lengthDelta = next.text.length - text.length;
    final caretDelta = caret - end;
    final isEdit =
        next.selection.isCollapsed &&
        caret >= 0 &&
        caret <= next.text.length &&
        lengthDelta == caretDelta;
    if (isEdit) {
      // Koşu sürüyor: tampona DOKUNULMAZ, yalnız uç güncellenir. (Geri silme
      // de buraya düşer; koşu kısalır ama biçim niyeti yaşamaya devam eder.)
      //
      // İmleç koşunun BAŞININ altına inerse (kullanıcı yazdıklarını silip
      // daha da geriye gitti) koşu ORADAN yeniden başlar: yoksa uç bir daha
      // başlangıcı geçemez, `_wrapRun` hep null döner ve düğme yanık dururken
      // yazılan metin düz kaydedilirdi.
      if (caret < at) _pendingAt = caret;
      _pendingEnd = caret;
      return null;
    }
    // Koşu bitti. Metin de değiştiyse (uzağa yapıştırma, toplu silme) sarma
    // güvenle yapılamaz: niyet düşer ve yazılan metin biçimsiz kalır —
    // yanlış yere işaret sokup eşi olmayan ham markdown üretmekten yeğdir.
    if (end <= at || end > text.length || next.text != text) {
      clearPendingFormat();
      return null;
    }
    final wrapped = _wrapRun(
      TextEditingValue(text: text, selection: next.selection),
      endOverride: end,
    );
    clearPendingFormat();
    return wrapped;
  }

  @override
  set value(TextEditingValue newValue) {
    final wrapped = _trackPendingRun(newValue);
    if (wrapped != null) newValue = wrapped;
    if (_floats.isEmpty) {
      // Sarma yokken tampon kullanıcının metnidir; IME dokunulmadan geçer —
      // yalnız imleç görünmez işaretin ortasına düşerse kenara çekilir ve
      // işareti silen geri-silme gerçek karaktere yönlendirilir.
      _widths = const [];
      final fixed = _markerDelete(text, newValue);
      if (fixed != null) {
        super.value = fixed;
        return;
      }
      super.value = _snapped(_collapsed(text, newValue));
      return;
    }
    var logical = stripWrapAnchors(newValue.text);
    final rawBase = newValue.selection.baseOffset < 0
        ? newValue.text.length
        : newValue.selection.baseOffset;
    final rawExtent = newValue.selection.extentOffset < 0
        ? rawBase
        : newValue.selection.extentOffset;
    var caret = wrapToLogicalOffset(newValue.text, rawBase);
    // Seçim (uzun basıp metin işaretleme) çapalı tamponda da korunur; yalnız
    // imleç taşınırsa extent null kalır.
    int? extent = rawExtent == rawBase
        ? null
        : wrapToLogicalOffset(newValue.text, rawExtent);
    // SATIR BAŞINDA GERİ SİLME: imleç satır başı dolgusunun hemen ardındadır,
    // dolayısıyla geri silme gerçek metni değil DOLGUYU siler. Eski hâlinde
    // dolgu bir sonraki dizgide yeniden konuyor, kullanıcıya "silme satır
    // başında duruyor, üst satıra geçmiyor" gibi görünüyordu. Mantıksal metin
    // hiç değişmeden tampon kısaldıysa niyet açıktır: ÖNCEKİ karakteri sil
    // (satır başındaki karakter satır sonu ise satırlar birleşir).
    if (logical == logicalText &&
        newValue.text.length < text.length &&
        caret > 0) {
      logical = logical.replaceRange(caret - 1, caret, '');
      caret--;
      extent = null;
    }
    // GÖRÜNMEZ BİÇİM İŞARETLERİ: imleç işaretin ortasına düşerse kullanıcıya
    // "imleç kıpırdamıyor / geri silme çalışmıyor" gibi görünür (silinen şey
    // görünmeyen bir yıldızdır). Konum gerçek bir karakterin sınırına, gidilen
    // yöne doğru çekilir.
    if (extent == null) {
      // Görünmez işareti silen geri-silme, metnin kendisine yönlendirilir
      // (sarmasız yoldaki [_markerDelete] ile aynı gerekçe).
      final oldLogical = logicalText;
      if (logical.length == oldLogical.length - 1 &&
          isMarkerOffset(oldLogical, caret)) {
        final fixed = deleteThroughMarkers(oldLogical, caret + 1);
        if (fixed != null) {
          _reflow(fixed.text, fixed.caret);
          return;
        }
      }
      if (logical.length < oldLogical.length) {
        final collapsed = collapseEmptyMarkersAt(logical, caret);
        logical = collapsed.text;
        caret = collapsed.caret;
      }
      final previous = wrapToLogicalOffset(
        text,
        selection.baseOffset < 0 ? 0 : selection.baseOffset,
      );
      caret = snapOutOfMarkers(logical, caret, backward: caret < previous);
    }
    _reflow(logical, caret, extent);
  }

  /// Silmeden sonra imlecin iki yanında BOŞ işaret çifti kaldıysa toplar.
  ///
  /// Biçimli bir kelimenin son harfi silinince geriye iç içe boş işaretler
  /// kalıyor; hiçbiri eşleşmediğinden düz metin gibi çiziliyor ve kullanıcı
  /// sildikçe yeni işaretler beliriyormuş gibi görünüyordu.
  TextEditingValue _collapsed(String oldText, TextEditingValue newValue) {
    if (newValue.text.length >= oldText.length) return newValue;
    final selection = newValue.selection;
    if (!selection.isValid || !selection.isCollapsed) return newValue;
    final result = collapseEmptyMarkersAt(newValue.text, selection.baseOffset);
    if (result.text == newValue.text) return newValue;
    return TextEditingValue(
      text: result.text,
      selection: TextSelection.collapsed(offset: result.caret),
    );
  }

  /// Geri silme GÖRÜNMEZ bir işareti mi sildi? Öyleyse silme metnin kendisine
  /// yönlendirilir (bkz. [deleteThroughMarkers]); değilse null döner ve
  /// düzenleyicinin kendi silmesi geçerli kalır.
  TextEditingValue? _markerDelete(String oldText, TextEditingValue newValue) {
    final selection = newValue.selection;
    if (!selection.isValid || !selection.isCollapsed) return null;
    if (newValue.text.length != oldText.length - 1) return null;
    final deleted = selection.baseOffset;
    if (!isMarkerOffset(oldText, deleted)) return null;
    final fixed = deleteThroughMarkers(oldText, deleted + 1);
    if (fixed == null) return null;
    return TextEditingValue(
      text: fixed.text,
      selection: TextSelection.collapsed(offset: fixed.caret),
    );
  }

  /// Sarma KAPALIYKEN imleci görünmez işaretlerin dışına çeker (sarma açıkken
  /// aynı iş [value] içinde, çapasız uzayda yapılır).
  TextEditingValue _snapped(TextEditingValue newValue) {
    final selection = newValue.selection;
    if (!selection.isValid || !selection.isCollapsed) return newValue;
    final previous = value.selection.baseOffset;
    final caret = snapOutOfMarkers(
      newValue.text,
      selection.baseOffset,
      backward: previous >= 0 && selection.baseOffset < previous,
    );
    if (caret == selection.baseOffset) return newValue;
    return newValue.copyWith(
      selection: TextSelection.collapsed(offset: caret),
      // Oluşturma aralığı (IME) kaydırılan imleçle tutarsız kalır.
      composing: TextRange.empty,
    );
  }

  /// Son sarma planının önbelleği.
  ///
  /// KÖK NEDEN (kasma — "görsel ekleyince sayfaya kasma artıyor"nun çözdürme
  /// fırtınası kapatıldıktan sonra KALAN yarısı): [planTextWrap] satır satır
  /// ilerlerken her turda TAM bir `TextPainter.layout` + tam biçim ayrıştırması
  /// yapıyor — maliyeti O(satır × metin). Bu, yalnız yazarken değil `set
  /// value`yu tetikleyen HER ŞEYDE (imleci taşımak, metne dokunmak, seçim
  /// değişimi) koşuyordu; oysa plan yalnız METİN ya da yerleşim girdileri
  /// değişince değişir. İmleç hareketinde artık hiç hesaplanmıyor.
  String? _planKeyLogical;
  TextStyle? _planKeyStyle;
  double _planKeyWidth = 0;
  double _planKeyScale = 1;
  TextDirection? _planKeyDirection;
  RichTextTheme? _planKeyRich;
  List<FloatBox>? _planKeyFloats;
  WrapPlan? _planCache;

  WrapPlan _planFor(String logical, TextStyle style) {
    if (_planCache != null &&
        _planKeyLogical == logical &&
        _planKeyStyle == style &&
        _planKeyWidth == _columnWidth &&
        _planKeyScale == _textScale &&
        _planKeyDirection == _direction &&
        _planKeyRich == _rich &&
        _planKeyFloats != null &&
        sameFloatList(_planKeyFloats!, _floats)) {
      return _planCache!;
    }
    // Yalnız METİN değişti ve değişiklik görselin bandının altında (önekin
    // ötesinde): önek aynen kalır, yeniden ölçülmez (bkz. [reuseWrapPlan]).
    // Uzun bir notun görselin altındaki kısmına yazmak artık tuş başına
    // dizgi yapmıyor.
    final previous = _planCache;
    final previousLogical = _planKeyLogical;
    final sameInputs =
        previous != null &&
        previousLogical != null &&
        _planKeyStyle == style &&
        _planKeyWidth == _columnWidth &&
        _planKeyScale == _textScale &&
        _planKeyDirection == _direction &&
        _planKeyRich == _rich &&
        _planKeyFloats != null &&
        sameFloatList(_planKeyFloats!, _floats);
    final plan =
        (sameInputs
            ? reuseWrapPlan(previous, previousLogical, logical)
            : null) ??
        planTextWrap(
          logical: logical,
          style: style,
          columnWidth: _columnWidth,
          floats: _floats,
          textScaleFactor: _textScale,
          direction: _direction,
          rich: _rich,
        );
    _planKeyLogical = logical;
    _planKeyStyle = style;
    _planKeyWidth = _columnWidth;
    _planKeyScale = _textScale;
    _planKeyDirection = _direction;
    _planKeyRich = _rich;
    // Bantlar YERİNDE değişebiliyor (görsel sürüklenirken aynı liste
    // güncelleniyor); kopyası saklanır, yoksa önbellek bayat kalır.
    _planKeyFloats = List.of(_floats);
    _planCache = plan;
    return plan;
  }

  void _reflow(String logical, int logicalCaret, [int? logicalExtent]) {
    final style = _style;
    // Aynı değeri yeniden yazmak seçim katmanını (tutamaklar, araç çubuğu)
    // yeniden kurar: boyut kaydırıcısı sürüklenirken her karede tazelenen
    // dizgi, tutamakların TİTREMESİNE yol açıyordu. Değişen bir şey yoksa
    // dokunma.
    if (style == null || _columnWidth <= 0 || _floats.isEmpty) {
      _widths = const [];
      final caret = logicalCaret.clamp(0, logical.length);
      final extent = logicalExtent?.clamp(0, logical.length);
      _write(
        TextEditingValue(
          text: logical,
          selection: extent == null || extent == caret
              ? TextSelection.collapsed(offset: caret)
              : TextSelection(baseOffset: caret, extentOffset: extent),
        ),
      );
      return;
    }
    final plan = _planFor(logical, style);
    _widths = plan.widths;
    final caret = wrapToDisplayOffset(
      plan.display,
      logicalCaret.clamp(0, logical.length),
    );
    final extent = logicalExtent == null
        ? null
        : wrapToDisplayOffset(
            plan.display,
            logicalExtent.clamp(0, logical.length),
          );
    _write(
      TextEditingValue(
        text: plan.display,
        selection: extent == null || extent == caret
            ? TextSelection.collapsed(offset: caret)
            : TextSelection(baseOffset: caret, extentOffset: extent),
      ),
    );
  }

  /// Pencereli yazımda karşı denetleyiciden gelen değer (bkz. `BodyWindow`):
  /// imleç/işaret düzeltmeleri kaynakta yapıldı, burada yinelenmez.
  void mirrorValue(TextEditingValue next) => super.value = next;

  /// Pencere denetleyicisi notun görünüş girdilerini alır.
  void copyLooksFrom(WrapTextController other) {
    _rich = other._rich;
    _attachmentNames = other._attachmentNames;
    _tagChipColors = other._tagChipColors;
    _videoTimestamps = other._videoTimestamps;
    _spanCache = null;
    _scanText = null;
  }

  /// Pencere dışındaki parçanın span'i: alanın kendi çizim yolu.
  InlineSpan tileSpan(String text, TextStyle? style, Color linkColor) =>
      _paragraphSpan(text, const [], style, linkColor);

  /// Değer gerçekten değiştiyse yazar (bkz. [_reflow] içindeki not).
  void _write(TextEditingValue next) {
    if (next.text == value.text && next.selection == value.selection) return;
    super.value = next;
  }

  /// "Metin düz mü" taramasının önbelleği. buildTextSpan her çizimde çağrılır
  /// ve klavye açılış animasyonu boyunca AYNI metin için kare başına tam
  /// findLinks + stripRichMarkers taraması yapıyordu ("klavye açılırken
  /// kasma"nın bir parçası). Metin değişmediyse sonuç yeniden kullanılır.
  String? _scanText;

  /// Sadelik taraması ek adlarına da bağlı: aynı metin, ek listesi değişince
  /// etiketli hâle gelebilir (dosya sonradan eklendi) ya da etiketini
  /// kaybedebilir (dosya silindi).
  String? _scanNamesKey;
  bool _scanHasLink = false;
  bool _scanHasMarker = false;
  bool _scanHasTag = false;
  bool _scanHasTime = false;

  /// Üretilmiş span ağacının önbelleği.
  ///
  /// KÖK NEDEN (kasma): `buildTextSpan` HER ÇİZİMDE çağrılıyor ve metinde bir
  /// tane bile biçim işareti varsa `richSpans` tüm metni özyinelemeli olarak
  /// gezip yüzlerce `TextSpan` üretiyordu. Önbellek yalnız "metin düz mü"
  /// sorusunu kapsıyordu; asıl pahalı iş her karede yeniden yapılıyordu.
  /// Girdiler değişmediyse AYNI ağaç döndürülür.
  String? _spanKeyText;
  TextStyle? _spanKeyStyle;
  Color? _spanKeyLinkColor;
  RichTextTheme? _spanKeyRich;
  List<double>? _spanKeyWidths;
  TextSpan? _spanCache;

  TextSpan _cachedSpan(
    String text,
    List<double> widths,
    TextStyle? style,
    Color? linkColor,
  ) {
    if (_spanCache != null &&
        _spanKeyText == text &&
        _spanKeyStyle == style &&
        _spanKeyLinkColor == linkColor &&
        _spanKeyRich == _rich &&
        identical(_spanKeyWidths, widths)) {
      return _spanCache!;
    }
    final span = _paragraphSpan(text, widths, style, linkColor);
    _spanKeyText = text;
    _spanKeyStyle = style;
    _spanKeyLinkColor = linkColor;
    _spanKeyRich = _rich;
    _spanKeyWidths = widths;
    _spanCache = span;
    return span;
  }

  // ---- PARAGRAF ÖNBELLEĞİ -------------------------------------------------
  //
  // KÖK NEDEN (kullanıcı 2026-10-16: "program genelinde yazı yazarken FPS
  // düşüşü"): yukarıdaki önbellek yalnız AYNI metni kapsıyordu; her tuş
  // vuruşu metni değiştirdiği için bütün metin baştan ayrıştırılıyordu
  // (biçim işaretleri, bağlantı kalıbı, ek etiketleri). Ölçüm (test ortamı):
  // 10.000 karakter tuş başına ~7,5 ms, 30.000 karakter ~20 ms.
  //
  // Biçim işaretleri, bağlantılar, ek etiketleri ve zaman damgaları SATIR
  // SONUNU AŞMAZ (bkz. rich_text `_formatPattern`); yani her paragrafın
  // span'i yalnız kendi metnine bağlıdır. Paragraflar ayrı önbelleklenir:
  // tuşta yalnız DÜZENLENEN paragraf yeniden ayrıştırılır.

  /// Paragraf metni (+ dolgu genişlikleri) → span.
  final _paraSpans = <String, InlineSpan>{};

  /// Paragraf önbelleğini geçersiz kılan girdiler (stil, renk, tema, ek
  /// adları…). Liste/harita alanları yalnız GERÇEKTEN değişince yeni nesne
  /// olur (bkz. setter'lar) — kimlikle karşılaştırmak yeterli.
  Object? _paraSpansEnv;

  TextSpan _paragraphSpan(
    String text,
    List<double> widths,
    TextStyle? style,
    Color? linkColor,
  ) {
    final env = (
      style,
      linkColor,
      _rich,
      _attachmentNames,
      _tagChipColors,
      _videoTimestamps,
    );
    if (env != _paraSpansEnv) {
      _paraSpans.clear();
      _paraSpansEnv = env;
    }
    final paragraphs = text.split('\n');
    final children = <InlineSpan>[];
    var anchorIndex = 0;
    for (var i = 0; i < paragraphs.length; i++) {
      final p = paragraphs[i];
      if (p.isNotEmpty) {
        var anchors = 0;
        if (widths.isNotEmpty) {
          for (var c = 0; c < p.length; c++) {
            if (p.codeUnitAt(c) == _kWrapAnchorCode) anchors++;
          }
        }
        final own = anchors == 0
            ? const <double>[]
            : widths.sublist(
                math.min(anchorIndex, widths.length),
                math.min(anchorIndex + anchors, widths.length),
              );
        anchorIndex += anchors;
        final key = own.isEmpty ? p : '$p\u0000${own.join(',')}';
        children.add(
          _paraSpans[key] ??= buildWrapSpan(
            p,
            own,
            style,
            linkColor: linkColor,
            rich: _rich,
            attachmentNames: _attachmentNames,
            tagChipColors: _tagChipColors.isEmpty ? null : _tagChipColors,
            videoTimestamps: _videoTimestamps,
          ),
        );
      }
      if (i < paragraphs.length - 1) children.add(const TextSpan(text: '\n'));
    }
    // Silinen/değişen paragrafların bayat girdileri birikmesin.
    if (_paraSpans.length > paragraphs.length * 2 + 64) {
      final live = paragraphs.toSet();
      _paraSpans.removeWhere((key, _) {
        final cut = key.indexOf('\u0000');
        return !live.contains(cut < 0 ? key : key.substring(0, cut));
      });
    }
    return TextSpan(style: style, children: children);
  }

  /// Paragraf → "neler var" bitleri (bkz. [_scanPlainness]): 1 bağlantı,
  /// 2 biçim işareti, 4 ek etiketi, 8 zaman damgası.
  final _paraFlags = <String, int>{};
  Object? _paraFlagsEnv;

  int _flagsOf(String p) {
    if (p.isEmpty) return 0;
    return _paraFlags[p] ??=
        (findLinks(p).isNotEmpty ? 1 : 0) |
        (stripRichMarkers(p) != p ? 2 : 0) |
        (findAttachmentTags(p, _attachmentNames).isNotEmpty ? 4 : 0) |
        (_videoTimestamps && findVideoTimestamps(p).isNotEmpty ? 8 : 0);
  }

  void _scanPlainness() {
    final namesKey = _attachmentNames.join('\u0000');
    if (_scanText == text && _scanNamesKey == namesKey) return;
    _scanText = text;
    _scanNamesKey = namesKey;
    final env = (namesKey, _videoTimestamps);
    if (env != _paraFlagsEnv) {
      _paraFlags.clear();
      _paraFlagsEnv = env;
    }
    // Paragraf başına önbellekli tarama (bkz. [_paragraphSpan]).
    final paragraphs = text.split('\n');
    var flags = 0;
    for (final p in paragraphs) {
      flags |= _flagsOf(p);
    }
    if (_paraFlags.length > paragraphs.length * 2 + 64) {
      final live = paragraphs.toSet();
      _paraFlags.removeWhere((key, _) => !live.contains(key));
    }
    _scanHasLink = flags & 1 != 0;
    _scanHasMarker = flags & 2 != 0;
    _scanHasTag = flags & 4 != 0;
    _scanHasTime = flags & 8 != 0;
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    // Yazarken (IME oluşturma aralığı açıkken) span'e dokunulmaz: klavyenin
    // altı çizili öneri bölgesi bizim ürettiğimiz parçalarda kayardı. Metin
    // oturunca link rengi zaten gelir.
    final composing = withComposing && value.isComposingRangeValid;
    final linkColor = composing ? null : Theme.of(context).colorScheme.primary;
    TextSpan span;
    if (_widths.isEmpty) {
      // Biçim işareti ya da bağlantı yoksa üst sınıfın span'i kullanılır
      // (IME davranışı olduğu gibi kalsın).
      _scanPlainness();
      //
      // **EK ETİKETİ DE SADELİĞİ BOZAR** (kullanıcı bulgusu 2026-09-01:
      // "ataç işareti geliyor ama … altı çizilmiyor"). Kısayol yalnız
      // bağlantıya ve biçim işaretine bakıyordu; "📎 rapor.pdf" gibi bir
      // metinde ikisi de yok, dolayısıyla üst sınıfın DÜZ span'i dönüyor ve
      // etiket kırmızı/altı çizili HİÇ çizilmiyordu — yalnız madde
      // satırlarında değil, gövdede de.
      if ((linkColor == null ||
              (!_scanHasLink && !_scanHasTag && !_scanHasTime)) &&
          !_scanHasMarker) {
        span = super.buildTextSpan(
          context: context,
          style: style,
          withComposing: withComposing,
        );
      } else {
        span = _cachedSpan(text, const [], style, linkColor);
      }
    } else {
      // Oluşturma aralığı (IME altı çizgisi) sarma sırasında atlanır: çapalar
      // aralığın konumunu kaydırır ve altı çizili bölge yanlış yere düşer.
      span = _cachedSpan(text, _widths, style, linkColor);
    }
    return _withScopePreview(
      _withSearchHits(_withPendingPreview(span, style), style),
      style,
    );
  }

  // ---- Biçim kapsamı önizlemesi ------------------------------------------

  (int, int)? _scopePreview;
  Color _scopePreviewColor = const Color(0x22000000);

  /// Biçim panelinin KAPSAMI (Kelime / Satır / Tümü) ekranda soluk zeminle
  /// gösterilir (kullanıcı bulgusu 2026-11-05: "metin satır kelime seçimi
  /// hâlâ doğru düzgün çalışmıyor"): kapsam seçimi geçici olduğu için hangi
  /// parçanın biçimleneceği hiç görünmüyordu, düğme "çalışmıyor" sanılıyordu.
  /// Yalnız ÇİZİM: metne, seçime, IME'ye dokunulmaz. [range] TAMPON
  /// konumları; null kaldırır.
  void setScopePreview((int, int)? range, {Color? color}) {
    if (_disposed) return;
    if (range == _scopePreview &&
        (color == null || color == _scopePreviewColor)) {
      return;
    }
    _scopePreview = range;
    if (color != null) _scopePreviewColor = color;
    notifyListeners();
  }

  TextSpan _withScopePreview(TextSpan span, TextStyle? style) {
    final range = _scopePreview;
    if (range == null) return span;
    final (start, end) = range;
    if (start < 0 || end > text.length || end <= start) return span;
    final out = restyleRange(
      span,
      start,
      end,
      (current) => (current ?? style ?? const TextStyle()).copyWith(
        backgroundColor: _scopePreviewColor,
      ),
    );
    return out is TextSpan ? out : span;
  }

  // ---- Not içi arama vurgusu ---------------------------------------------

  List<(int, int)> _searchHits = const [];
  int _searchCurrent = -1;
  Color _searchHitColor = const Color(0x66FFD54F);
  Color _searchCurrentColor = const Color(0xFFFFB300);

  /// Not içi aramanın vurguları (kullanıcı isteği 2026-09-26: "not içi
  /// aramada sayfada canlı aranmalı"). [hits] TAMPON konumlarıdır (bkz.
  /// `TextSearchIndex`); [current] o an odaklanan eşleşmenin sırası (-1 =
  /// bu alanda değil). Yalnız ÇİZİM değişir: metne, imlece, geri alma
  /// yığınına dokunulmaz.
  void setSearchHighlights(
    List<(int, int)> hits, {
    int current = -1,
    required Color hitColor,
    required Color currentColor,
  }) {
    if (_disposed || (_searchHits.isEmpty && hits.isEmpty)) return;
    _searchHits = hits;
    _searchCurrent = current;
    _searchHitColor = hitColor;
    _searchCurrentColor = currentColor;
    notifyListeners();
  }

  /// Madde silinince denetleyicisi atılır; arama çubuğu o sırada açıksa
  /// vurgusunu temizlemeye çalışabilir — atılmış bildiriciye dokunulmaz.
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void clearSearchHighlights() {
    if (_disposed || _searchHits.isEmpty) return;
    _searchHits = const [];
    _searchCurrent = -1;
    notifyListeners();
  }

  TextSpan _withSearchHits(TextSpan span, TextStyle? style) {
    final hits = _searchHits;
    if (hits.isEmpty) return span;
    InlineSpan out = span;
    final length = text.length;
    // Tavan: binlerce eşleşmede her biri span ağacını baştan gezer; ekranda
    // zaten bir kaçı görünür. Odaktaki eşleşme her zaman boyanır.
    const limit = 400;
    for (var i = 0; i < hits.length; i++) {
      if (i >= limit && i != _searchCurrent) continue;
      final (start, end) = hits[i];
      if (start < 0 || end > length || end <= start) continue;
      final color = i == _searchCurrent ? _searchCurrentColor : _searchHitColor;
      out = restyleRange(
        out,
        start,
        end,
        (current) => (current ?? style ?? const TextStyle()).copyWith(
          backgroundColor: color,
        ),
      );
    }
    return out is TextSpan ? out : span;
  }

  /// BEKLEYEN biçimin canlı önizlemesi: koşunun aralığı ekranda biçimli
  /// çizilir, tampona hiç dokunulmadan (bkz. [pendingRange]).
  ///
  /// Önizleme çizim uzayında yapılır; sarma çapalı tamponda da aynı uzay
  /// geçerlidir (çapalar gerçek karakterlerdir, uzunluk korunur).
  TextSpan _withPendingPreview(TextSpan span, TextStyle? style) {
    final range = pendingRange;
    if (range == null) return span;
    final palette = _rich?.palette ?? const <Color>[];
    final mark = pendingMark;
    final restyled = restyleRange(
      span,
      range.$1,
      range.$2,
      (current) =>
          markStyle(
            current ?? style ?? const TextStyle(),
            mark,
            palette,
            background: _rich?.background,
          ),
    );
    return restyled is TextSpan ? restyled : span;
  }
}
