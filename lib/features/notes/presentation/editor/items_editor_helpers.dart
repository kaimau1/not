part of 'items_editor.dart';

const kUncheckRestoreWindow = Duration(seconds: 30);

/// İşareti KALKAN öğenin listeye geri gireceği konum.
///
/// İki farklı niyet aynı hareketle yapılıyor: (a) yanlışlıkla işaretleyip
/// hemen geri alma — öğe eski sırasında kalmalı, (b) gerçekten tamamlanmış bir
/// işi sonradan yeniden açma — öğe sıranın sonuna girmeli. Aradaki tek fark
/// GEÇEN SÜREdir; [kUncheckRestoreWindow] içinde geri alınan öğe eski
/// konumuna döner, sonrası işaretsizlerin sonuna eklenir (eski davranış).
///
/// [uncheckedCount] öğe listeden çıkarıldıktan SONRAKİ işaretsiz sayısıdır:
/// hem sonuna ekleme hem de hatırlanan konumun üst sınırı odur (arada başka
/// öğeler silinmiş olabilir).
int uncheckRestoreIndex({
  required int uncheckedCount,
  int? rememberedIndex,
  Duration? sinceChecked,
}) {
  if (rememberedIndex == null ||
      sinceChecked == null ||
      sinceChecked > kUncheckRestoreWindow) {
    return uncheckedCount;
  }
  return rememberedIndex.clamp(0, uncheckedCount);
}

/// Madde listesini "işaretsizler önce, işaretliler sonra" düzenine getirir;
/// iki blok da kendi içindeki sırayı KORUR (kararlı bölme).
///
/// KÖK NEDEN (kullanıcı: "madde sıralamasını değiştiremiyorum iptal oluyor",
/// "yeni öğe alta eklenmiyor / yanlış yere gidiyor"): editörün bütün konum
/// hesabı "işaretsizler listenin başında" DEĞİŞMEZİNE dayanıyordu ama bu
/// değişmez hiçbir yerde ZORLANMIYORDU — yalnızca umuluyordu. Bozulması da
/// kolay: bir madde işaretlendiğinde görünüm animasyonu bitene kadar (220 ms)
/// öğe listede YERİNDE kalır ve o hâliyle bir kez kaydedilir; kullanıcı o
/// aralıkta editörden çıkarsa nota "işaretli madde ortada" diye yazılır.
/// Aynı şey başka cihazdan/eski sürümden gelen ya da yapay zekânın kurduğu
/// listelerde de olabiliyor.
///
/// Değişmez bozulunca iki şey birden kırılıyordu:
/// - "Yeni öğe" `_checkedStart`e giriyordu; o da artık ilk işaretlinin (yani
///   listenin ORTASININ) konumuydu → madde yanlış yere düşüyordu.
/// - Sürükle-sırala, ekrandaki satır sırasını `_items` sırasıyla BİREBİR
///   eşleşiyor sayıyordu → sürüklenen satır yerine başka bir madde taşınıyor,
///   kullanıcıya sıralama "tutmuyor / geri alınıyor" gibi görünüyordu.
///
/// Artık liste dışarıdan her benimsendiğinde buradan geçiyor (bozuk kayıt
/// açılışta onarılır) ve konum hesapları da düzene GÜVENMİYOR (bkz.
/// `_ItemsEditorState._uncheckedInsertIndex`, `_reorder`).
List<NoteItem> normalizeItems(List<NoteItem> items) {
  var seenChecked = false;
  var ordered = true;
  for (final item in items) {
    if (item.checked) {
      seenChecked = true;
    } else if (seenChecked) {
      ordered = false;
      break;
    }
  }
  if (ordered) return List.of(items);
  return [
    for (final i in items)
      if (!i.checked) i,
    for (final i in items)
      if (i.checked) i,
  ];
}

/// Sürükleyerek sıralarken parmağın konumuna göre kare başına kaç piksel
/// kaydırılacağı. Negatif = yukarı, pozitif = aşağı, 0 = kaydırma yok.
///
/// [top] ve [bottom] görünür sayfa kutusunun ekran koordinatlarıdır. Parmak
/// [band] kadarlık kenar şeridine girdikçe kaydırma hızlanır; şeridin dışında
/// kaydırma durur. Ayrı bir işlev: kenar mantığı widget kurmadan sınanabilsin.
double reorderAutoScrollStep({
  required double pointerY,
  required double top,
  required double bottom,
  double band = 88,
  double maxStep = 14,
}) {
  // Kutu banttan darsa (çok kısa liste) bant kutunun yarısına iner; yoksa üst
  // ve alt bantlar örtüşür ve parmak nerede olursa olsun kaydırma tetiklenir.
  final effective = math.min(band, (bottom - top) / 2);
  if (effective <= 0) return 0;
  if (pointerY < top + effective) {
    return -maxStep *
        ((top + effective - pointerY) / effective).clamp(0.0, 1.0);
  }
  if (pointerY > bottom - effective) {
    return maxStep *
        ((pointerY - (bottom - effective)) / effective).clamp(0.0, 1.0);
  }
  return 0;
}


extension ItemsEditorOps on ItemsEditorState {
  /// [target] bu editörün satırlarından biriyse metni O SATIRA, imlecin
  /// yerine ekler ve nota işler; değilse false döner (çağıran gövdeye yazar).
  ///
  /// Sesli yakalama gibi akışlar odağı düşürdüğü için hedefi çağıran taşır
  /// (editör en son odaklanan alanı zaten biliyor — `_formatTarget`).
  bool insertTextAtCaret(TextEditingController target, String text) {
    for (final entry in _controllers.entries) {
      if (!identical(entry.value, target)) continue;
      final index = _items.indexWhere((i) => i.id == entry.key);
      if (index < 0) return false;
      final controller = entry.value;
      final logical = controller.logicalText;
      final selection = controller.selection;
      final caret = selection.isValid
          ? wrapToLogicalOffset(controller.text, selection.baseOffset)
          : logical.length;
      final result = insertAtCaret(logical, caret, text);
      if (result.text == logical) return true;
      controller.setLogical(result.text, result.caret);
      _updateText(_items[index], result.text);
      return true;
    }
    return false;
  }

  /// İmleç bir EK ETİKETİNİN üstüne düştüyse çağıranı haberdar eder.
  /// Konum önce mantıksal metne çevrilir: alanın metni sarma çapaları
  /// taşıyabiliyor ve çapalar sayılırsa etiketin sınırları kayardı.
  void _tapAttachmentTag(
    WrapTextController controller,
    BuildContext fieldContext,
  ) {
    final selection = controller.selection;
    if (!selection.isValid) return;
    // VİDEO ZAMAN DAMGASI (bkz. video_time.dart): notta video varken
    // "1:23"e dokunmak videoyu oraya sarar — gövdeyle aynı kural.
    final onTime = widget.onVideoTimestamp;
    if (onTime != null && widget.videoTimestamps) {
      final seconds = tappedVideoTimestamp(
        displayText: controller.text,
        selection: selection,
        editable: editableTextBelow(fieldContext),
        tapGlobal: _tapPoint.last,
      );
      if (seconds != null) {
        onTime(seconds);
        return;
      }
    }
    // BAĞLANTIYA DOKUNUŞ (2026-10-28): gövdeyle aynı kural — okurken açar,
    // yazarken önerir.
    final link = tappedLink(
      displayText: controller.text,
      editable: editableTextBelow(fieldContext),
      tapGlobal: _tapPoint.last,
    );
    if (link != null) {
      editableTextBelow(fieldContext)?.hideToolbar();
      handleLinkTap(
        context,
        link,
        editing: _tapPoint.wasFocused,
        onEmbedVideo: widget.onEmbedVideo,
      );
      return;
    }
    final onTag = widget.onAttachmentTag;
    if (onTag == null || widget.attachmentNames.isEmpty) return;
    // Etiketin İÇİNE dokunuş; sınırdaysa dokunuşun KONUMU etiketin
    // kutusunda mı ona bakılır (bkz. tappedAttachmentTag — son harfe
    // dokunmak imleci sınıra koyuyor, önizleme açılmıyordu).
    final editable = editableTextBelow(fieldContext);
    final tag = tappedAttachmentTag(
      logicalText: controller.logicalText,
      logicalCaret: wrapToLogicalOffset(controller.text, selection.baseOffset),
      displayText: controller.text,
      selection: selection,
      names: widget.attachmentNames,
      editable: editable,
      tapGlobal: _tapPoint.last,
    );
    if (tag == null) return;
    // Önizleme açılırken dokunuşun açtığı Yapıştır menüsü kalmasın.
    editable?.hideToolbar();
    onTag(tag.fileName);
  }


  void _commit() {
    // Silinen satırların taşma ölçümü sonsuza dek yaşamasın (bkz.
    // [_overflowsLine]); ölçüm satır sayısından çoksa bayatlar ayıklanır.
    if (_overflowCache.length > _items.length) {
      final live = {for (final i in _items) i.id};
      _overflowCache.removeWhere((id, _) => !live.contains(id));
    }
    widget.onChanged(List.of(_items));
  }

  bool _overflowsLine(
    BuildContext context,
    String id,
    String text,
    TextStyle style,
    double maxWidth,
  ) {
    final fontSize = style.fontSize ?? 0;
    final cached = _overflowCache[id];
    if (cached != null &&
        cached.text == text &&
        cached.width == maxWidth &&
        cached.fontSize == fontSize) {
      return cached.value;
    }
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final value = painter.width > maxWidth - 14;
    painter.dispose();
    _overflowCache[id] = (
      text: text,
      width: maxWidth,
      fontSize: fontSize,
      value: value,
    );
    return value;
  }


  /// Satırın TAMAMINI (tutamaç + kutucuk + metin + sil düğmesi) görselin
  /// yanına kaydırır. Yalnız metni sarmak yetmiyordu: kutucuk ve tutamaç
  /// satırın sol başında durduğundan görselin ALTINDA kalıyordu.
  ///
  /// [reserved] satırın metne ayrılamayan payıdır; sarma kararı bu pay
  /// düşülerek verilir (bkz. [_FloatRow.reserved]).
  ///
  /// KÖK NEDEN (kullanıcı: "yeni öğe görselin yanına ilk defa eklendiğinde
  /// yanıp sönen imleç çıkmıyor") — sarmalayıcı eskiden `floats.isEmpty`
  /// olduğunda HİÇ kurulmuyordu. Bantlar çalışma anında doluyor (tuval
  /// görsellerin yerini ilk çizimden SONRA ölçüp bildiriyor, görsel eklenip
  /// silinince de değişiyor): o anda satırın ağacına araya bir katman girip
  /// çıkıyor, TextField başka bir konuma düşüyor ve state'i (içindeki
  /// EditableText ile birlikte) SIFIRDAN kuruluyordu. Yeni state odağı zaten
  /// almış bir düğümle açıldığı için "odak değişti" olayı gelmiyor, imlecin
  /// yanıp sönme zamanlayıcısı hiç başlamıyordu — imleç ancak ilk harfte
  /// beliriyordu. (Aynı kök neden 2026-08-06'da odak için bulunmuştu; kural
  /// odakla sınırlı değil: ağacın ŞEKLİ çalışma anında hiç değişmemeli.)
  ///
  /// Bant yokken bedel sıfır: [_FloatRow] boş bant listesinde ölçüm bile
  /// planlamaz, yalnız 0 dolgulu bir [Padding] çizer.
  Widget _floatRow(
    Widget child, {
    String? id,
    double reserved = 0,
    bool pushOnly = false,
    double? inlineBelow,
  }) {
    final pageBox = widget.pageBox;
    if (pageBox == null) return child;
    return _FloatRow(
      floats: _floatsL,
      pageBox: pageBox,
      reserved: reserved,
      pushOnly: pushOnly,
      inlineBelow: inlineBelow,
      registry: _floatRowStates,
      initial: id == null ? null : (_pads[id] ?? _padOfNeighbour(id)),
      onMeasured: id == null ? null : (pad) => _pads[id] = pad,
      child: child,
    );
  }

  /// **MADDE SİLİNİNCE YAZILAR TABLONUN ÜSTÜNE BİNİYOR** (kullanıcı bulgusu
  /// 2026-11-24, ekran görüntüsü: "tablo varken bir madde sildiğimde tüm
  /// yazılar üstüne biniyor, tablo yokmuş gibi"). KÖK NEDEN: satırlar
  /// önbellekten AYNI örnekle döndüğü için ([_cachedItemRow]) silinen
  /// maddenin altındakiler yukarı kayınca kurulmuyor, `_FloatRow` da yalnız
  /// kurulunca ya da bant değişince ölçüyordu. Bant (tablo) yerinde durunca
  /// kayan satırlar eski dolgularıyla kalıyor; tablonun altına itilmiş satır
  /// silinince yerine gelenler itmesiz kalıp tablonun üstüne biniyordu.
  /// Artık liste kurulduktan sonra geometrisi (yükseklik, madde sırası)
  /// değiştiyse bandı olan satırlar yukarıdan aşağı yeniden ölçülür. Bant
  /// yoksa bedel sıfır; yazarken (yükseklik aynı) ölçüm yok.
  void _queueLayoutCheck() {
    if (_layoutCheckQueued || widget.pageBox == null) return;
    if (_floatsL.value.isEmpty) {
      _layoutSig = null;
      return;
    }
    _layoutCheckQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _layoutCheckQueued = false;
      if (!mounted) return;
      final box = context.findRenderObject();
      if (box is! RenderBox || !box.hasSize) return;
      final sig = (
        box.size.height,
        Object.hashAll([for (final i in _items) Object.hash(i.id, i.checked)]),
      );
      if (sig == _layoutSig) return;
      _layoutSig = sig;
      _remeasureRows();
    });
  }

  /// Satırları SAYFADAKİ sırayla (yukarıdan aşağı) ölçer: üstteki satırın
  /// bu karedeki kayması alttakine `_FrameShifts` ile geçer.
  void _remeasureRows() {
    final page = widget.pageBox?.call();
    if (page == null) return;
    final rows = <(double, _FloatRowState)>[];
    for (final s in _floatRowStates) {
      final b = s.mounted ? s.context.findRenderObject() : null;
      if (b is! RenderBox || !b.hasSize || !b.attached) continue;
      rows.add((b.localToGlobal(Offset.zero, ancestor: page).dy, s));
    }
    rows.sort((a, b) => a.$1.compareTo(b.$1));
    for (final (_, s) in rows) {
      s._measure();
    }
  }

  /// Yeni satırın başlangıç tahmini: bir üstündeki maddenin kaydırması
  /// (aynı görselin bandındaysa birebir doğrudur).
  ({double start, double end, double top})? _padOfNeighbour(String id) {
    final index = _items.indexWhere((i) => i.id == id);
    if (index <= 0) return null;
    return _pads[_items[index - 1].id];
  }

  /// Madde alanını sarma denetleyicisinin ölçümüne bağlar.
  ///
  /// **İKİ KATMANLI SARMA** (kullanıcı bulgusu 2026-11-02, ekran görüntüsü:
  /// "üstte alan varken alt satırlar sığmadığı için hepsi sağa kaydırılmış;
  /// üstte sığan kısımlar görselin üzerinde olmalı, sığmayanlar sağa
  /// kayabilir"). Görsel maddenin İLK satırına değiyorsa satırın TAMAMI
  /// (kutucukla birlikte) [_FloatRow] ile yana kayar. Görsel maddenin İÇİNDE,
  /// ilk satırından aşağıda başlıyorsa satır kaymaz: o görsel alanın kendi
  /// sarma planına verilir ve yalnız görselin hizasına düşen satırlar
  /// girintilenir. Bir görseli iki katmandan YALNIZ biri işler — eskiden
  /// ikisi aynı bantla girinti basınca metin kutucuktan kopuyordu.
  /// [WrapFieldMeasure.minTop] ile [_FloatRow.inlineBelow] aynı ölçüyü (bir
  /// satır boyu) kullanır; alanın metni satırın tepesinden aşağıda
  /// başladığından "ikisi birden" durumu oluşamaz.
  Widget _wrapped(
    WrapTextController controller,
    TextStyle style,
    Widget field,
  ) {
    final pageBox = widget.pageBox;
    if (pageBox == null) return field;
    return WrapFieldMeasure(
      controller: controller,
      style: style,
      floats: const [],
      // Bant değişince yalnız ölçer; alan ve satır kurulmaz.
      floatsListenable: _floatsL,
      minTop: ItemsEditorState.itemLineHeight(context, style),
      pageBox: pageBox,
      child: field,
    );
  }


  String? itemIdForController(TextEditingController controller) {
    for (final entry in _controllers.entries) {
      if (identical(entry.value, controller)) return entry.key;
    }
    return null;
  }

  /// Maddenin alt çizgi TÜRÜ ('' = yok); madde yoksa null.
  String? dividerKindOf(String id) {
    final item = _items.where((i) => i.id == id).firstOrNull;
    if (item == null) return null;
    return ItemDivider.parse(item.divider)?.kind ?? '';
  }

  /// Maddenin TAM çizgi biçimi (tür + renk + kalınlık; P63 PBT — tepsinin
  /// seçili hücresi rengini/kalınlığını da göstersin). Çizgi yoksa null.
  ItemDivider? dividerOf(String id) {
    final item = _items.where((i) => i.id == id).firstOrNull;
    return item == null ? null : ItemDivider.parse(item.divider);
  }

  /// Biçim panelinin alt çizgi sırası (bkz. [_setDivider]).
  void setDividerOf(String id, String kind) {
    final item = _items.where((i) => i.id == id).firstOrNull;
    if (item != null) _setDivider(item, kind);
  }

  Future<void> editDividerStyleOf(String id) async {
    final item = _items.where((i) => i.id == id).firstOrNull;
    if (item != null) await _editDividerStyle(item);
  }

  /// [global] noktasının DİKEYDE düştüğü madde (jest katmanı, bkz.
  /// `ink_gestures.dart`): satırın metin alanının üst/alt sınırı.
  String? itemIdAt(Offset global) {
    String? best;
    var bestDistance = double.infinity;
    for (final entry in _focusNodes.entries) {
      final box = entry.value.rowContext?.findRenderObject();
      if (box is! RenderBox || !box.attached || !box.hasSize) continue;
      final top = box.localToGlobal(Offset.zero).dy;
      final bottom = top + box.size.height;
      final distance = global.dy < top
          ? top - global.dy
          : global.dy > bottom
          ? global.dy - bottom
          : 0.0;
      if (distance < bestDistance) {
        bestDistance = distance;
        best = entry.key;
      }
    }
    return bestDistance <= 12 ? best : null;
  }

  /// Jestle işaretle / işareti kaldır.
  void toggleCheckedOf(String id) {
    final item = _items.where((i) => i.id == id).firstOrNull;
    if (item == null || item.text.trim().isEmpty) return;
    _toggleItem(item, !item.checked);
  }

  /// Jestle sil (geri alma editörün notu saklamasıyla).
  void removeItemOf(String id) {
    final item = _items.where((i) => i.id == id).firstOrNull;
    if (item == null) return;
    _focusNodes[id]?.unfocus();
    _removeItem(item);
  }

  /// Maddenin İŞARETLİ metni (yoksa null).
  String? itemTextOf(String id) =>
      _items.where((i) => i.id == id).firstOrNull?.text;

  /// Maddenin metnini dışarıdan değiştirir (jestle yazım düzeltme).
  void replaceItemText(String id, String text) {
    final item = _items.where((i) => i.id == id).firstOrNull;
    if (item == null) return;
    _controllers[id]?.setLogical(text, text.length);
    _updateText(item, text);
  }

  /// Maddeye odaklanır ve imleci sonuna koyar (dışarıdan eklenen madde —
  /// ör. alt çubuğun ☑ düğmesi gövde satırını maddeye çevirdiğinde).
  void focusItem(String id) {
    final item = _items.where((i) => i.id == id).firstOrNull;
    if (item == null) return;
    final controller = _controllerFor(item);
    _focusFor(item).requestFocus();
    controller.selection = TextSelection.collapsed(
      offset: controller.text.length,
    );
  }

  /// Maddeyi ODAKLAMADAN görünür yapar (klavye açılmaz) — ana ekran
  /// şeridinden satır görevine gelince. Satır kurulmamışsa sessizce geçer.
  ///
  /// Liste TEMBEL kuruluyor: ekran dışındaki satırın bağlamı yok. O zaman
  /// kaydırıcı satırın tahmini yerine atlatılır (sıra / madde sayısı), bir
  /// kare beklenir ve satır kurulunca hizalanır — en çok 4 deneme.
  Future<void> revealItem(String id) async {
    for (var attempt = 0; attempt < 4; attempt++) {
      if (!mounted) return;
      final ctx = _focusNodes[id]?.rowContext;
      if (ctx != null && ctx.mounted) {
        await Scrollable.ensureVisible(
          ctx,
          alignment: 0.3,
          duration: const Duration(milliseconds: 280),
          curve: AppMotion.emphasized,
        );
        return;
      }
      final index = _items.indexWhere((i) => i.id == id);
      if (index < 0) return;
      ScrollPosition? position;
      // En yakın GERÇEKTEN kayan ata: liste çoğu kipte sayfanın kaydırıcısı
      // içinde kendisi kaymayan (uzunluğu 0) bir Scrollable.
      for (final node in _focusNodes.values) {
        final row = node.rowContext;
        if (row == null || !row.mounted) continue;
        var scrollable = Scrollable.maybeOf(row);
        while (scrollable != null) {
          final p = scrollable.position;
          if (p.axis == Axis.vertical &&
              p.hasContentDimensions &&
              p.maxScrollExtent > p.minScrollExtent) {
            position = p;
            break;
          }
          scrollable = Scrollable.maybeOf(scrollable.context);
        }
        break;
      }
      if (position == null || !position.hasContentDimensions) return;
      final fraction = index / math.max(1, _items.length - 1);
      position.jumpTo(
        (position.minScrollExtent +
                (position.maxScrollExtent - position.minScrollExtent) *
                    fraction)
            .clamp(position.minScrollExtent, position.maxScrollExtent),
      );
      await WidgetsBinding.instance.endOfFrame;
    }
  }

  /// Not içi aramanın eşleşmesi bir madde alanındaysa (bkz. [searchFields])
  /// o maddeyi görünür yapar; düz çizimde alanın bağlamı olmadığı için
  /// editörün kendi kaydırması boşa düşüyordu. Madde değilse false.
  bool revealFocus(FocusNode focus) {
    for (final e in _focusNodes.entries) {
      if (identical(e.value, focus)) {
        unawaited(revealItem(e.key));
        return true;
      }
    }
    return false;
  }

  /// **ONAY KUTUSUNU KALDIR**: maddeyi listeden çıkarır ve metnini döner
  /// (çağıran gövdeye yazar). Madde yoksa null.
  String? takeItem(String id) {
    final index = _items.indexWhere((i) => i.id == id);
    if (index < 0) return null;
    final text = _items[index].text;
    _focusNodes[id]?.unfocus();
    _removeItem(_items[index]);
    return text;
  }

  /// Başlıktaki klavye "İleri" tuşu buraya düşer (liste notunda gövde alanı
  /// yok): ilk işaretsiz maddeye odaklanır, hiç madde yoksa yeni açar.
  void focusFirstItem() {
    for (final item in _items) {
      if (!item.checked) {
        _focusFor(item).requestFocus();
        return;
      }
    }
    _addItem();
  }

  /// "Yeni öğe" düğmesiyle öğe ekler; işaretsizlerin SONUNA girer — düğme
  /// zaten işaretsiz bloğun hemen altında durur.
  ///
  /// KÖK NEDEN (kullanıcı ekran görüntüsü 2026-09-23: listenin sonunda boş
  /// bir "Yeni öğe" satırı ve hemen altında "+ Yeni öğe" düğmesi): düğme her
  /// dokunuşta YENİ bir boş öğe açıyordu. Boş öğeye yazmadan başka yere
  /// dokunan ya da düğmeye iki kez basan kullanıcıda boş satırlar birikiyor,
  /// kayda da boş öğe olarak gidiyordu.
  ///
  /// SINIR 1 DEĞİL 3 (kullanıcı isteği 2026-09-26: "1'den fazla yeni boş öğe
  /// eklenebilmeli, max 3 tane"): tek boş öğe sınırı, önceden birkaç satır
  /// açıp sonra sırayla doldurmak isteyeni engelliyordu. İşaretsizlerin
  /// sonunda üst üste [kMaxTrailingEmptyItems] boş öğe varsa YENİSİ açılmaz,
  /// ilk boş olana odaklanılır — birikme yine sınırlı.
  /// "+ Yeni öğe" düğmesi. F12.7: düğme GİZLENMEZ — art arda en çok
  /// [kMaxTrailingEmptyItems] boş madde açılabilmesi kullanıcı kararı
  /// (2026-09-26); tekrar, boş maddenin ipucunun ayrı adıyla ("Madde yaz")
  /// giderildi.
  Widget _addItemButton(AppLocalizations l10n) => TextButton.icon(
    key: const ValueKey('items-add-button'),
    // Kutucuklarla aynı renk (bkz. [_accent]).
    style: _accent?.accent == null
        ? null
        : TextButton.styleFrom(foregroundColor: _accent!.accent),
    onPressed: _addItem,
    icon: const Icon(Icons.add, size: AppIconSize.m),
    label: Text(l10n.newItemHint),
  );


  Widget _packagedRow(List<NoteItem> list, int index, Widget row) {
    final item = list[index];
    final pkg = item.package;
    if (pkg.isEmpty) return row;
    final first = index == 0 || list[index - 1].package != pkg;
    if (_openPackage != pkg) {
      if (!first) return SizedBox.shrink(key: ValueKey('pkg-${item.id}'));
      final members = [
        for (var k = index; k < list.length && list[k].package == pkg; k++)
          list[k],
      ];
      return KeyedSubtree(
        key: ValueKey('pkg-${item.id}'),
        // Kapalı paket de yüzen kutuların ALTINA iner (kullanıcı bulgusu
        // 2026-11-23: tablo paket etiketinin üstüne biniyordu).
        child: _floatRow(
          NotePackagePill(
            text: members.map((m) => stripRichMarkers(m.text)).join('  ·  '),
            count: members.length,
            onTap: () => _setOpenPackage(pkg),
            onUnpack: () => unpackGroup(pkg),
          ),
          id: 'pkg-${item.id}',
          pushOnly: true,
        ),
      );
    }
    final scheme = Theme.of(context).colorScheme;
    return KeyedSubtree(
      key: ValueKey('pkg-${item.id}'),
      child: TapRegion(
        groupId: kNotePackageTapGroup,
        onTapOutside: (_) => _setOpenPackage(null),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: BorderDirectional(
              start: BorderSide(color: scheme.primary, width: 2),
            ),
          ),
          child: first
              ? Stack(
                  children: [
                    row,
                    PositionedDirectional(
                      top: 0,
                      end: 0,
                      child: NotePackageUnpackButton(
                        onPressed: () => unpackGroup(pkg),
                      ),
                    ),
                  ],
                )
              : row,
        ),
      ),
    );
  }

  @visibleForTesting
  bool mergeIntoPrevious(String id) {
    final index = _items.indexWhere((i) => i.id == id);
    if (index <= 0) return false;
    final controller = _controllers[id];
    if (controller == null) return false;
    final selection = controller.selection;
    if (!selection.isValid || !selection.isCollapsed) return false;
    if (wrapToLogicalOffset(controller.text, selection.baseOffset) != 0) {
      return false;
    }
    final current = _items[index];
    final previous = _items[index - 1];
    if (widget.showCheckboxes && previous.checked != current.checked) {
      return false;
    }
    final caret = previous.text.length;
    final joined = previous.text + current.text;
    unawaited(AppHaptics.tick());
    // Odak ÖNCE üst maddeye geçer: silinen satırla birlikte odak (ve
    // klavye) bir kare için kaybolmasın.
    _focusFor(previous).requestFocus();
    _items[index - 1] = previous.copyWith(text: joined);
    _controllerFor(_items[index - 1]).setLogical(joined, caret);
    _removeItem(current);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final merged = _items.where((i) => i.id == previous.id).firstOrNull;
      if (merged == null) return;
      final c = _controllerFor(merged);
      if (c.logicalText == joined) c.setLogical(joined, caret);
    });
    return true;
  }


  void _disposeRowFor(String id) {
    final controller = _controllers.remove(id);
    if (controller != null) {
      widget.onFieldDisposed?.call(controller);
      controller.dispose();
    }
    // Düğüm satır ağaçtan inince (sonraki kare) atılır. HEMEN atılırsa
    // odaktaki satırda odak bir an "hiç kimsede" kalır; çerçeve yeni odağın
    // bütün ata zincirini kirli sayar, her ata kendine bağlı bütün `Focus`'ları
    // (40 maddede ~110 widget) yeniden kurdururdu (2026-11-15 madde kasması).
    final node = _focusNodes.remove(id);
    if (node != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => node.dispose());
    }
    _focusFlags.remove(id)?.dispose();
  }

  /// Sürükle-bırak sonucu. Gelen indeksler EKRANDAKİ (sürüklenebilir) listeye
  /// aittir; [_items] ise işaretli ve "yerleşmekte olan" öğeleri de taşır.
  ///
  /// KÖK NEDEN (kullanıcı: "sıralamayı değiştiremiyorum iptal oluyor"):
  /// eskiden bu iki indeks BİREBİR aynı sayılıyordu ("işaretsizler _items'ın
  /// başında" değişmezine dayanarak). Değişmez bozulduğu anda (bkz.
  /// [normalizeItems]) sürüklenen satır yerine listedeki BAŞKA bir madde
  /// taşınıyordu: ekranda sürüklenen satır eski yerine geri dönüyor, hareket
  /// "iptal oldu" gibi görünüyordu. Artık eşleme öğenin kendisi üzerinden
  /// yapılır ve görünmeyen öğeler kendi konumlarında kalır.

  bool _isVisibleRow(NoteItem item) =>
      !widget.showCheckboxes || !_placedAsChecked(item);

  /// Sürüklenebilir listenin gösterdiği öğeler — `itemBuilder` ile AYNI sıra.
  List<NoteItem> _visibleItems() => [
    for (final i in _items)
      if (_isVisibleRow(i)) i,
  ];

  /// Tek öğe satırı. [reorderIndex] verilirse satır sürüklenebilir;
  /// footer'daki işaretli öğelerde tutamak yoktur (sıraları zaten sabit).
  /// [orderNumber] sıralı listede gösterilen numaradır.
  /// Satır widget'larının önbelleği: madde kimliği → (anahtar, widget).
  ///
  /// KÖK NEDEN (kasma — "kasma birikip artıyor"): liste `shrinkWrap: true` ile
  /// bir `SingleChildScrollView`'ın içinde. `ShrinkWrappingViewport` kendi
  /// boyunu bulmak için BÜTÜN çocukları kurmak zorunda, yani 60 maddelik bir
  /// notta ekranda 8 satır görünse bile 60 `TextField` + 60 `EditableText`
  /// **her build'de** yeniden kuruluyor ve yeniden yerleşiyordu. Editörün her
  /// yeniden kurulumunun bedeli madde sayısıyla doğru orantılıydı.
  ///
  /// Çözüm önbellek: girdileri değişmemiş satır için AYNI widget örneği
  /// döndürülür. Flutter `updateChild`te birebir aynı widget'ı görünce alt
  /// ağacı hiç kurmaz — ve kurulmayan bir `RenderObject` "kirli"
  /// işaretlenmediği için `layout()` da erken döner. Yani hem yeniden kurulum
  /// hem yerleşim kalkar.
  ///
  /// Yan etki (bilerek): `_FloatRow.build` içindeki kare-sonu ölçüm planlaması
  /// da yalnız satır GERÇEKTEN değiştiğinde kuruluyor; eskiden her build'de
  /// satır sayısı kadar geri çağrı sıraya giriyordu.
  ///
  /// TUZAK: önbellekteki widget ESKİ `NoteItem` örneğini kapanışlarında
  /// tutuyor. Güvenli, çünkü satır geri çağrılarının hepsi (`_updateText`,
  /// `_toggleItem`, `_removeItem`, `_insertAfter`, `_toggleSelection`) öğeyi
  /// KİMLİĞİYLE arıyor, nesne kimliğiyle değil.
  /// Satır düzeyi girdiler değişmediyse önbellekten döndürür.
  ///
  /// Satırın listedeki YERİ (sürükleme dizini, sıra numarası) anahtarda
  /// DEĞİL: [_RowSlot] ile dışarıdan verilir (P20 M1 — bir madde yer
  /// değiştirince arkasındaki bütün satırlar yeniden kuruluyordu, S3/S4).
  Widget _cachedItemRow(NoteItem item, {int? reorderIndex, int? orderNumber}) {
    // Kayıt (record) yapısal eşitlik kullanır — hash çakışması yok, yani
    // bayat satır dönme riski de yok.
    final key = (
      item.text,
      item.checked,
      item.starred,
      // KÖK NEDEN (kullanıcı bulgusu 2026-10-20: "alta çizgi çek çalışmıyor,
      // defterde kararsız"): ayırıcı anahtarda yoktu — satır önbellekten
      // ESKİ hâliyle dönüyordu, çizgi ancak başka bir şey satırı yeniden
      // kurunca beliriyordu.
      item.divider,
      item.header,
      item.align,
      item.package,
      reorderIndex != null,
      _selected.contains(item.id),
      _movePhase(item.id),
    );
    final hit = _rowCache[item.id];
    final Widget row;
    if (hit != null && hit.$1 == key) {
      row = hit.$2;
    } else {
      row = _itemRow(item, draggable: reorderIndex != null);
      _rowCache[item.id] = (key, row);
    }
    // Yuva da AYNI örnek döner (satır ve yeri değişmediyse): liste her
    // kurulduğunda 40 maddenin yuvası ve altı yeniden kurulmasın — tek
    // maddedeki değişiklik yalnız o satırı kursun (2026-11-15 madde kasması).
    final slot = _slotCache[item.id];
    if (slot != null &&
        identical(slot.child, row) &&
        slot.reorderIndex == reorderIndex &&
        slot.orderNumber == orderNumber) {
      return slot;
    }
    return _slotCache[item.id] = _RowSlot(
      key: ValueKey('slot-${item.id}'),
      reorderIndex: reorderIndex,
      orderNumber: orderNumber,
      child: row,
    );
  }

  /// Satırın yer değiştirme evresi (bkz. [_CheckMove]).
  _MovePhase _movePhase(String id) {
    if (_settling.containsKey(id)) return _MovePhase.leaving;
    if (_arriving.contains(id)) return _MovePhase.arriving;
    return _MovePhase.idle;
  }

}


/// Madde satırının kutusu, [overlay]in koordinatlarında: [anchor] satırın
/// sol bölgesinin bağlamı, en yakın [RenderFlex] atası satırın kendisi
/// (bkz. `items_editor_row.dart`). Bulunamazsa null (menü parmağın yerinde).
@visibleForTesting
Rect? itemMenuRowRect(BuildContext? anchor, RenderBox overlay) {
  if (anchor == null || !anchor.mounted) return null;
  final row = anchor.findAncestorRenderObjectOfType<RenderFlex>();
  if (row == null || !row.hasSize || !row.attached) return null;
  final topLeft = row.localToGlobal(Offset.zero, ancestor: overlay);
  return topLeft & row.size;
}

/// Üstü çizili geçişin süresi (bkz. `_itemRow`).
const _kStrikeDuration = Duration(milliseconds: 260);


/// "+ Yeni öğe" ile üst üste açılabilecek en çok boş öğe (bkz.
/// [ItemsEditorState._addItem]).
const int kMaxTrailingEmptyItems = 3;

/// [items]in SONUNDA üst üste duran boş (yalnız boşluk içeren) öğe sayısı.
int trailingEmptyCount(List<NoteItem> items) {
  var count = 0;
  for (var i = items.length - 1; i >= 0; i--) {
    if (items[i].text.trim().isNotEmpty) break;
    count++;
  }
  return count;
}
