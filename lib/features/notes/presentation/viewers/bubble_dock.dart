part of 'bubble_layer.dart';

/// YAZMA kartı: açık balonun içeriği, KLAVYENİN hemen üstünde.
///
/// Yalnız düzenleme kipinde görünür ([BubbleController.editMode]); okumak için
/// sayfanın üzerindeki balon yeter (bkz. `_BubbleReadCard`).
///
/// Neden sayfada değil (kullanıcı isteği 2026-08-08, kendi önerisi): kart sayfa
/// koordinatındayken klavye açılınca görünür alan yarıya iniyor ve sayfanın alt
/// yarısındaki kart klavyenin ALTINDA kalıyordu. Kart görüntüleyicinin ALT
/// kenarına demirlendi: `Scaffold` klavye kadar daraldığı için kart her zaman
/// klavyenin hemen üstünde, yazının aktığı yerde duruyor — parmağın ve gözün
/// gittiği yer orası ("2.ss'teki alana al"). Üstte durduğu sürümde göz sayfanın
/// bir ucundan öbürüne gidip geliyordu.
///
/// Başlık alanı şeridin İÇİNDE ve GENİŞ: eski kompakt şeritte beş simgeyle
/// yan yanaydı ve dar sayfada birkaç piksele iniyordu ("başlık kısmı hiç
/// görülmüyor"). Başlığın yanında yalnız YAZILI "Bitti" var; renk, yıldız,
/// ünlem ve silme altta HEP GÖRÜNEN bir araç satırında (2026-10-15'e kadar
/// "⋮" düğmesinin arkasındaydı ve bulunmuyordu).
///
/// **Eylemler neden menü/levha DEĞİL** (kullanıcı bulgusu 2026-08-08:
/// "balondaki yazıyı düzenlerken 3 noktaya basınca klavye kapanıyor,
/// kullanımı bozuyor"): `PopupMenuButton` bir ROTA iter; itilen rota kendi
/// odak kapsamını alır, `TextField` odağı düşer, klavye kapanır ve menü
/// kapanınca geri gelmez — üstelik odak düşünce `editing` false olduğu için
/// gizlenen çubuklar geri gelip ekran zıplıyordu. Renk seçici de aynı sebeple
/// (modal levha) kartın içine alındı. Satır `TextFieldTapRegion` +
/// `ExcludeFocus` içinde: hiçbir düğme odağı istemez, yazı alanı odakta kalır.
class BubbleDock extends StatefulWidget {
  const BubbleDock({
    super.key,
    required this.controller,
    this.readOnly = false,
    this.bottomPadding = 0,
  });

  final BubbleController controller;
  final bool readOnly;

  /// Kartın altına eklenecek sistem payı (tam ekran görüntüleyicide telefon
  /// gezinme çubuğu). Pano bölmesinde 0'dır — orası ekranın dibi değil.
  final double bottomPadding;

  @override
  State<BubbleDock> createState() => _BubbleDockState();
}

class _BubbleDockState extends State<BubbleDock> {
  final _title = TextEditingController();
  final _text = TextEditingController();
  final _titleFocus = FocusNode();
  final _textFocus = FocusNode();

  /// Alanları hangi balon için doldurduk? Balon değişince (başka bir
  /// tutamaca dokunuldu) alanlar yeniden yüklenir.
  String? _loadedId;

  /// Renk şeridi açık mı? (Araç satırındaki renk dairesi açar.)
  bool _colors = false;

  /// Açık metin alanının DOLGU şeridi açık mı (bkz. [PageBubble.fill]).
  bool _fills = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_sync);
    for (final focus in [_titleFocus, _textFocus]) {
      focus.addListener(() {
        final focused = _titleFocus.hasFocus || _textFocus.hasFocus;
        if (!focused) widget.controller.save();
      });
    }
    _sync();
  }

  /// Yazma kartı AÇIK mı (balon açık + düzenleme kipi) — bölmeyi sadeleştiren
  /// "yazma kipi" ([BubbleController.setEditing]) buna bağlıdır.
  ///
  /// KÖK NEDEN (kullanıcı bulgusu 2026-10-16: "balona yazarken odak sorunu,
  /// klavye kayması"): kip eskiden yazı alanının ODAĞINA bağlıydı. Odak her
  /// gidip geldiğinde (sayfaya dokunmak, renk şeridi, başlıktan metne geçiş
  /// sırasında bir kare) editörün başlığı, alt çubuğu ve sayfa çubuğu
  /// gizlenip geri geliyor, bütün bölme yeniden yerleşip kayıyordu. Artık kip
  /// kartın görünürlüğüne bağlı: kart açılınca BİR KEZ sadeleşir, "Bitti"
  /// ile BİR KEZ geri gelir; arada odak ne yaparsa yapsın yerleşim sabit.
  bool _dockOpen = false;

  void _setDockOpen(bool open) {
    if (_dockOpen == open) return;
    _dockOpen = open;
    // Denetleyici bildirimi sırasında (ya da initState'te) üst ekranın
    // setState'i çağrılmasın: kare sonuna ertelenir.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.controller.setEditing(_dockOpen);
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  /// Odağın en son İSTENDİĞİ balon. Okuma kartından "Düzenle"ye geçişte
  /// alanlar zaten aynı balonla dolu olduğundan ([_loadedId]) eski kod erken
  /// dönüyor ve ODAK HİÇ İSTENMİYORDU — kart açılıyor ama klavye gelmiyor,
  /// kullanıcı alana ayrıca dokunmak zorunda kalıyordu.
  String? _focusedFor;

  @override
  void dispose() {
    widget.controller.removeListener(_sync);
    _title.dispose();
    _text.dispose();
    _titleFocus.dispose();
    _textFocus.dispose();
    super.dispose();
  }

  void _sync() {
    final open = widget.controller.openBubble;
    final editMode = widget.controller.editMode;
    _setDockOpen(open != null && editMode && !widget.readOnly);
    if (open == null) {
      _focusedFor = null;
      if (_loadedId != null) {
        _loadedId = null;
        _titleFocus.unfocus();
        _textFocus.unfocus();
      }
      return;
    }
    if (open.id != _loadedId) {
      _loadedId = open.id;
      _title.text = open.title;
      _text.text = open.text;
      // Başka bir balona geçildi: açık kalan eylem satırı yeni balona ait
      // sanılmasın.
      _colors = false;
      _fills = false;
      _focusedFor = null;
    }
    if (!editMode) {
      _focusedFor = null;
      return;
    }
    // Düzenlemeye açıldı (yeni balon, okuma kartından "Düzenle", listeden
    // düzenle): klavye hazır gelir, imleç metnin SONUNDA. Her balon için
    // BİR KEZ — sonraki bildirimler (yazdıkça) odağı yerinden oynatmaz.
    if (widget.readOnly || _focusedFor == open.id) return;
    _focusedFor = open.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _titleFocus.hasFocus || _textFocus.hasFocus) return;
      _text.selection = TextSelection.collapsed(offset: _text.text.length);
      _textFocus.requestFocus();
    });
  }

  /// Kartın yüksekliğini denetleyiciye bildirir: görüntüleyici belgeyi
  /// kaydırıp açık balonu kartın ÜSTÜNDE kalan alanın ortasına alıyor
  /// ("tıklanan balon klavye ile ekranın üstü arasında ortalanmalı").
  void _reportHeight() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final height = _cardKey.currentContext?.size?.height ?? 0;
      if ((widget.controller.dockHeight.value - height).abs() > 1) {
        widget.controller.dockHeight.value = height;
      }
    });
  }

  final _cardKey = GlobalKey();

  void _close() {
    final open = widget.controller.openBubble;
    _titleFocus.unfocus();
    _textFocus.unfocus();
    if (open != null) widget.controller.setCollapsed(open.id, true);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final bubble = widget.controller.openBubble;
      if (bubble == null || !widget.controller.editMode) {
        if (widget.controller.dockHeight.value != 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) widget.controller.dockHeight.value = 0;
          });
        }
        return const SizedBox.shrink();
      }
      _reportHeight();
      final color = bubble.plain
          ? Color(bubble.color)
          : BubbleController.displayColor(bubble);
      final scheme = Theme.of(context).colorScheme;
      final l10n = context.l10n;
      final hintStyle = TextStyle(
        fontSize: 14,
        color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
      );
      // **YAZMA ALANI YENİLENDİ** (kullanıcı isteği 2026-10-16: "yazma
      // düzenleme alanı tamamen görsel yenilensin"): başlık satırı balonun
      // rengine boyalı bir şerit (renkli rozet + başlık + Bitti), yazı alanı
      // yumuşak dolgulu bir kutu (sohbet yazma kutusu gibi; kutunun boş
      // yerine dokunmak da alana odaklanır), araçlar altta. Kart klavyenin
      // hemen üstünde ve klavyeyle KARE KARE birlikte kayar
      // ([_KeyboardFollow]) — eskiden klavye animasyonu boyunca klavyenin
      // ARKASINDA kalıp, klavye durunca yukarı sıçrıyordu.
      final onColor =
          ThemeData.estimateBrightnessForColor(color) == Brightness.dark
          ? Colors.white
          : Colors.black87;
      // **PREMİUM GÖRÜNÜM** (kullanıcı isteği 2026-10-20: "sarı balon teması
      // hiç güzel değil, göz yoruyor"): başlık şeridi artık balonun rengine
      // BOYANMIYOR — sarı balonda kartın tepesi sarı bir bant oluyordu. Kart
      // nötr yüzey + ince kenar; balonun rengi yalnız soldaki küçük rozette.
      return _KeyboardFollow(
        child: Padding(
          padding: EdgeInsets.fromLTRB(8, 6, 8, 8 + widget.bottomPadding),
          child: Material(
            key: _cardKey,
            color: scheme.surface,
            elevation: 8,
            shadowColor: Colors.black38,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.7),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 8, 2),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color.lerp(color, Colors.white, 0.18)!,
                              color,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          bubble.plain
                              ? Icons.text_fields_rounded
                              : bubble.isHighlight
                              ? Icons.border_color_rounded
                              : Icons.chat_bubble_rounded,
                          size: 15,
                          color: onColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: widget.readOnly
                            ? Text(
                                bubble.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _titleStyle,
                              )
                            : TextField(
                                key: const ValueKey('bubble-dock-title'),
                                controller: _title,
                                focusNode: _titleFocus,
                                maxLines: 1,
                                maxLength: PageBubble.maxTitle,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                textInputAction: TextInputAction.next,
                                // Başlıkta Enter metne geçer — klavye
                                // kapanıp açılmaz.
                                onSubmitted: (_) => _textFocus.requestFocus(),
                                style: _titleStyle,
                                cursorColor: scheme.onSurface,
                                decoration: InputDecoration(
                                  isDense: true,
                                  filled: false,
                                  counterText: '',
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  border: InputBorder.none,
                                  hintText: l10n.bubbleTitleHint,
                                  hintStyle: hintStyle,
                                ),
                                onChanged: (value) => widget.controller
                                    .updateTitle(bubble.id, value),
                              ),
                      ),
                      // "Bitti" YAZILI ve hep görünür: eski kapat simgesi
                      // (⤡) neyin kapandığını anlatmıyordu.
                      TextFieldTapRegion(
                        child: ExcludeFocus(
                          child: FilledButton.icon(
                            key: const ValueKey('bubble-dock-done'),
                            onPressed: _close,
                            style: FilledButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              minimumSize: const Size(0, 34),
                            ),
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: Text(l10n.bubbleDone),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 6, 10, 2),
                  child: widget.readOnly
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(bubble.text, style: _bodyStyle),
                        )
                      : GestureDetector(
                          // Kutunun boş yerine dokunmak da yazmaya başlatır:
                          // tek satırlık alanın dışına (kutunun dolgusuna)
                          // dokunan parmak eskiden boşa gidiyordu.
                          behavior: HitTestBehavior.translucent,
                          onTap: () {
                            if (!_textFocus.hasFocus) {
                              _textFocus.requestFocus();
                            }
                          },
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerHighest.withValues(
                                alpha: 0.6,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                              child: TextField(
                                key: const ValueKey('bubble-dock-text'),
                                controller: _text,
                                focusNode: _textFocus,
                                maxLines: 6,
                                minLines: 2,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                keyboardType: TextInputType.multiline,
                                style: _bodyStyle,
                                cursorColor: scheme.onSurface,
                                // İmleç alanın içinde kaydırılırken kartın
                                // üstünde boşluk bırakılmaz.
                                scrollPadding: EdgeInsets.zero,
                                decoration: InputDecoration(
                                  isDense: true,
                                  filled: false,
                                  contentPadding: EdgeInsets.zero,
                                  border: InputBorder.none,
                                  hintText: l10n.bubbleHint,
                                  hintStyle: hintStyle,
                                ),
                                onChanged: (value) => widget.controller
                                    .updateText(bubble.id, value),
                              ),
                            ),
                          ),
                        ),
                ),
                if (!widget.readOnly) _toolRow(context, bubble),
                if (_colors && !widget.readOnly) _colorStrip(bubble),
                if (_fills && bubble.plain && !widget.readOnly)
                  _fillStrip(bubble),
                if (widget.readOnly) const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      );
    },
  );

  static const _titleStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
  );
  static const _bodyStyle = TextStyle(fontSize: 14, height: 1.35);

  /// Araç düğmesi: küçük, odak İSTEMEYEN simge düğmesi.
  ///
  /// `ExcludeFocus` + `TextFieldTapRegion`: dokunuş yazı alanının odağını
  /// düşürmez — klavye açık kalır (bkz. sınıf açıklaması).
  Widget _barButton(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool selected = false,
    Color? color,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return TextFieldTapRegion(
      child: ExcludeFocus(
        child: IconButton(
          tooltip: tooltip.isEmpty ? null : tooltip,
          onPressed: onPressed,
          isSelected: selected,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          style: selected
              ? IconButton.styleFrom(backgroundColor: scheme.secondaryContainer)
              : null,
          icon: Icon(
            icon,
            size: 19,
            color:
                color ??
                (selected
                    ? scheme.onSecondaryContainer
                    : scheme.onSurfaceVariant),
          ),
        ),
      ),
    );
  }

  /// Renk, yıldız, acil, (vurguda) ok, (açık metinde) biçim ve silme.
  ///
  /// **HEP GÖRÜNÜR** (2026-10-15 yenilemesi): eskiden "⋮" düğmesinin
  /// arkasındaydı ve çoğu kullanıcı yıldızın, rengin, silmenin nerede
  /// olduğunu bulamıyordu. Satır kartın İÇİNDE, odak istemeyen düğmelerden
  /// oluşur — menü/levha rotası klavyeyi kapatıyordu (bkz. sınıf açıklaması).
  Widget _toolRow(BuildContext context, PageBubble bubble) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    // Düğmeler YATAY KAYAR, Sil sabit sağda: açık metin alanında biçim
    // düğmeleri ve boy düğmeleriyle satır dar telefona sığmıyordu.
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 0, 6, 4),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: _tools(context, bubble, l10n, scheme)),
            ),
          ),
          _barButton(
            context,
            icon: Icons.delete_outline,
            tooltip: l10n.delete,
            color: scheme.error,
            onPressed: () {
              _titleFocus.unfocus();
              _textFocus.unfocus();
              widget.controller.remove(bubble.id);
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _tools(
    BuildContext context,
    PageBubble bubble,
    AppLocalizations l10n,
    ColorScheme scheme,
  ) => [
    // Renk: balonun kendi rengiyle dolu bir daire — şeridi açar.
    TextFieldTapRegion(
      child: ExcludeFocus(
        child: IconButton(
          key: const ValueKey('bubble-color-toggle'),
          tooltip: l10n.color,
          onPressed: () => setState(() {
            _colors = !_colors;
            if (_colors) _fills = false;
          }),
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          icon: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Color(bubble.color),
              shape: BoxShape.circle,
              border: Border.all(
                color: _colors ? scheme.primary : scheme.outlineVariant,
                width: _colors ? 2.5 : 1.5,
              ),
            ),
          ),
        ),
      ),
    ),
    _barButton(
      context,
      icon: bubble.starred ? Icons.star_rounded : Icons.star_border_rounded,
      tooltip: l10n.bubbleStar,
      selected: bubble.starred,
      color: bubble.starred ? Colors.amber[800] : null,
      onPressed: () => widget.controller.toggleStar(bubble.id),
    ),
    _barButton(
      context,
      icon: Icons.priority_high_rounded,
      tooltip: l10n.bubbleUrgent,
      selected: bubble.urgent,
      color: bubble.urgent ? scheme.error : null,
      onPressed: () => widget.controller.toggleUrgent(bubble.id),
    ),
    // Ok yalnız VURGULU balonda: serbest balonun bağlanacağı metin yok.
    if (bubble.isHighlight)
      _barButton(
        context,
        icon: bubble.arrow ? Icons.north_east : Icons.block,
        tooltip: bubble.arrow ? l10n.bubbleArrowHide : l10n.bubbleArrowShow,
        onPressed: () => widget.controller.toggleArrow(bubble.id),
      ),
    // **METİN KUTUSU BİÇİMİ** — yalnız AÇIK METİN alanında (normal
    // balonun yazısı kartın içinde duruyor, sayfada değil; orada
    // kalın/hiza/dolgu bir şey ifade etmez).
    if (bubble.plain) ...[
      _barButton(
        context,
        icon: Icons.format_bold,
        tooltip: l10n.formatBold,
        selected: bubble.bold,
        onPressed: () => widget.controller
          ..update(bubble.copyWith(bold: !bubble.bold))
          ..save(),
      ),
      _barButton(
        context,
        icon: Icons.format_italic,
        tooltip: l10n.formatItalic,
        selected: bubble.italic,
        onPressed: () => widget.controller
          ..update(bubble.copyWith(italic: !bubble.italic))
          ..save(),
      ),
      // Hiza tek düğmeyle DÖNER (sol → orta → sağ): kartta üç ayrı
      // düğmeye yer yok, simge de o an hangi hizada olduğunu gösterir.
      _barButton(
        context,
        icon: switch (bubble.align) {
          1 => Icons.format_align_center,
          2 => Icons.format_align_right,
          _ => Icons.format_align_left,
        },
        tooltip: switch (bubble.align) {
          1 => l10n.bubbleTextAlignCenter,
          2 => l10n.bubbleTextAlignRight,
          _ => l10n.bubbleTextAlignLeft,
        },
        selected: bubble.align != 0,
        onPressed: () => widget.controller
          ..update(bubble.copyWith(align: (bubble.align + 1) % 3))
          ..save(),
      ),
      _barButton(
        context,
        icon: Icons.format_color_fill,
        tooltip: l10n.bubbleTextFill,
        selected: _fills,
        onPressed: () => setState(() {
          _fills = !_fills;
          if (_fills) _colors = false;
        }),
      ),
    ],
    // BOY (kullanıcı isteği 2026-10-16: "balonların boyutu
    // ayarlanabilir olsun"): normal balonda tutamaç, açık metinde yazı
    // büyür/küçülür. Değer nota yazılır, her cihazda aynı.
    _barButton(
      context,
      icon: Icons.zoom_out_rounded,
      tooltip: l10n.bubbleSmaller,
      onPressed: () => widget.controller.stepSize(bubble.id, -1),
    ),
    SizedBox(
      width: 34,
      child: Text(
        '${(bubble.size * 100).round()}%',
        key: const ValueKey('bubble-size-label'),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: scheme.onSurfaceVariant,
        ),
      ),
    ),
    _barButton(
      context,
      icon: Icons.zoom_in_rounded,
      tooltip: l10n.bubbleLarger,
      onPressed: () => widget.controller.stepSize(bubble.id, 1),
    ),
  ];

  /// Renk şeridi: modal levha yerine kartın içinde yatay bir sıra (levha da
  /// rota iterek klavyeyi kapatıyordu).
  Widget _colorStrip(PageBubble bubble) => TextFieldTapRegion(
    child: ExcludeFocus(
      child: SizedBox(
        height: 38,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(right: 8),
          children: [
            // Açık metin alanı kendi paletini kullanır (siyah/beyaz dahil) —
            // tutamaç renkleri bir YAZI için doğru seçenekler değil.
            for (final argb
                in bubble.plain
                    ? BubbleController.plainPalette
                    : BubbleController.palette)
              GestureDetector(
                key: ValueKey('bubble-color-$argb'),
                onTap: () => widget.controller
                  ..update(bubble.copyWith(color: argb))
                  ..save(),
                child: Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Color(argb),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: bubble.color == argb
                          ? Theme.of(context).colorScheme.onSurface
                          : Colors.black26,
                      width: bubble.color == argb ? 3 : 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );

  /// Açık metin alanının DOLGU şeridi: yazının arkasına konan zemin rengi.
  /// İlk seçenek "dolgu yok" (eski, dış hatlı çizim).
  Widget _fillStrip(PageBubble bubble) => TextFieldTapRegion(
    child: ExcludeFocus(
      child: SizedBox(
        height: 38,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(right: 8),
          children: [
            for (final argb in BubbleController.fillPalette)
              GestureDetector(
                key: ValueKey('bubble-fill-$argb'),
                onTap: () => widget.controller
                  ..update(bubble.copyWith(fill: argb))
                  ..save(),
                child: Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: argb == 0 ? null : Color(argb),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: bubble.fill == argb
                          ? Theme.of(context).colorScheme.onSurface
                          : Colors.black26,
                      width: bubble.fill == argb ? 3 : 1,
                    ),
                  ),
                  child: argb == 0
                      ? Tooltip(
                          message: context.l10n.bubbleTextFillNone,
                          child: const Icon(
                            Icons.format_color_reset,
                            size: 14,
                            color: Colors.black45,
                          ),
                        )
                      : null,
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

/// "Balon bırak" kipinin araç kartı: kip (balon / açık metin), renk, ipucu ve
/// YAZILI bir "Bitti". Yalnız ekleme kipinde görünür.
///
/// **2026-10-15 yenilemesi:** tek satırlık eski çubukta kip düğmeleri,
/// palet ve ipucu yan yana sıkışıyordu; dar telefonda ipucu iki harfe
/// iniyor, kipten nasıl çıkılacağı da görünmüyordu (çıkış yalnız sağ üstteki
/// küçük simgedeydi). Şimdi iki satır: üstte ne yapılacağı + Bitti, altta
/// kip ve renkler.
class BubbleToolbar extends StatelessWidget {
  const BubbleToolbar({super.key, required this.controller});

  final BubbleController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final plain = controller.plainMode;
        final selected = plain ? controller.plainColor : controller.color;
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: Material(
              color: scheme.surface,
              elevation: 6,
              shadowColor: Colors.black54,
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 6, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.touch_app_outlined,
                          size: 18,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            plain
                                ? l10n.bubblePlainTapToPlace
                                : l10n.bubbleTapToPlace,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        TextButton(
                          key: const ValueKey('bubble-toolbar-done'),
                          onPressed: () => controller.setAdding(false),
                          child: Text(l10n.bubbleDone),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // KİP SEÇİMİ EN BAŞTA VE ETİKETLİ (kullanıcı bulgusu
                        // 2026-08-16: "paint tarzı metin balonu eklemeyi
                        // bulamadım").
                        SegmentedButton<bool>(
                          showSelectedIcon: false,
                          style: SegmentedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          segments: [
                            ButtonSegment(
                              value: false,
                              icon: const Icon(
                                Icons.chat_bubble_outline,
                                size: 16,
                              ),
                              label: Text(l10n.bubbleModeBubble),
                            ),
                            ButtonSegment(
                              value: true,
                              icon: const Icon(Icons.text_fields, size: 16),
                              label: Text(l10n.bubblePlainModeShort),
                            ),
                          ],
                          selected: {plain},
                          onSelectionChanged: (selection) =>
                              controller.setPlainMode(selection.first),
                        ),
                        // Palet KİPE GÖRE değişir: balon tutamacının renkleri
                        // ile açık metnin renkleri ayrı listeler (açık metnin
                        // başı siyah — bkz. [BubbleController.plainPalette]).
                        Expanded(
                          child: SizedBox(
                            height: 36,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.only(left: 6),
                              children: [
                                for (final argb
                                    in plain
                                        ? BubbleController.plainPalette
                                        : BubbleController.palette)
                                  GestureDetector(
                                    onTap: () => plain
                                        ? controller.setPlainColor(argb)
                                        : controller.setColor(argb),
                                    child: Container(
                                      width: 26,
                                      height: 26,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 3,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Color(argb),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: selected == argb
                                              ? scheme.onSurface
                                              // Beyaz renk beyaz zeminde
                                              // kaybolmasın.
                                              : scheme.outlineVariant,
                                          width: selected == argb ? 3 : 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        // BÜTÜN balonların boyu (cihaz tercihi — bkz.
                        // [BubbleLook]). Tek balonunki yazma kartında.
                        if (!plain) const _GlobalSizeButtons(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Balon bırakma kartındaki genel boy düğmeleri: − 100% +.
class _GlobalSizeButtons extends StatelessWidget {
  const _GlobalSizeButtons();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder<double>(
      valueListenable: BubbleLook.scale,
      builder: (context, scale, _) {
        Widget button(IconData icon, String tooltip, double delta, Key key) =>
            IconButton(
              key: key,
              tooltip: tooltip,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 30, minHeight: 32),
              iconSize: 18,
              onPressed:
                  (delta < 0
                      ? scale <= BubbleLook.min
                      : scale >= BubbleLook.max)
                  ? null
                  : () => BubbleLook.setScale(scale + delta),
              icon: Icon(icon),
            );
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            button(
              Icons.zoom_out_rounded,
              l10n.bubbleAllSmaller,
              -BubbleLook.step,
              const ValueKey('bubble-global-smaller'),
            ),
            Text(
              '${(scale * 100).round()}%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
            button(
              Icons.zoom_in_rounded,
              l10n.bubbleAllLarger,
              BubbleLook.step,
              const ValueKey('bubble-global-larger'),
            ),
          ],
        );
      },
    );
  }
}

/// Balonlu panonun alt çubuğundaki balon düğmeleri: belirgin "Balon"
/// (bırakma kipini açar; açıkken "Bitti" olur) ve sayılı balon listesi.
///
/// Eskiden ikisi de görüntüleyicinin SAĞ ÜST köşesinde, belgenin üstüne
/// binen iki küçük yuvarlak simgeydi (2026-10-15: "genel hatlar tamamen
/// yenilenmeli"); ne işe yaradıkları anlaşılmıyor, belgeyi de kapatıyordu.
/// Yalnız bu küçük satır denetleyiciyi dinler — belge yeniden kurulmaz.
class BubbleBarActions extends StatelessWidget {
  const BubbleBarActions({
    super.key,
    required this.controller,
    required this.onOpenList,
    this.compact = false,
  });

  final BubbleController controller;
  final VoidCallback onOpenList;

  /// Dar ekranda "Balon" yazısı düşer, yalnız simge kalır.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final adding = controller.adding;
        final count = controller.bubbles.length;
        // Göster/gizle düğmesi de çubuktayken (balon varken) telefonda
        // "Balon" yazısı düşer — sayfa sayacı kesilmesin.
        final compact =
            this.compact ||
            (count > 0 && MediaQuery.sizeOf(context).width < 400);
        final style = FilledButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14),
          minimumSize: const Size(0, 36),
        );
        final icon = Icon(
          adding ? Icons.check : Icons.add_comment_outlined,
          size: 18,
        );
        void toggle() => controller.setAdding(!adding);
        final Widget add = compact
            ? (adding
                  ? FilledButton(onPressed: toggle, style: style, child: icon)
                  : FilledButton.tonal(
                      onPressed: toggle,
                      style: style,
                      child: icon,
                    ))
            : (adding
                  ? FilledButton.icon(
                      onPressed: toggle,
                      style: style,
                      icon: icon,
                      label: Text(l10n.bubbleDone),
                    )
                  : FilledButton.tonalIcon(
                      onPressed: toggle,
                      style: style,
                      icon: icon,
                      label: Text(l10n.bubbleModeBubble),
                    ));
        final hidden = controller.hidden;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tooltip(
              key: const ValueKey('bubble-add'),
              message: adding ? l10n.bubbleAddDone : l10n.bubbleAdd,
              child: add,
            ),
            // GÖSTER / GİZLE (kullanıcı isteği 2026-10-16). Balon yoksa
            // gizlenecek bir şey de yok — düğme çizilmez.
            if (count > 0)
              IconButton(
                key: const ValueKey('bubble-visibility'),
                tooltip: hidden ? l10n.bubblesShow : l10n.bubblesHide,
                visualDensity: VisualDensity.compact,
                isSelected: hidden,
                onPressed: () => controller.setHidden(!hidden),
                icon: Icon(
                  hidden
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            IconButton(
              tooltip: l10n.bubblesOverviewTitle,
              visualDensity: VisualDensity.compact,
              onPressed: onOpenList,
              icon: Badge(
                isLabelVisible: count > 0,
                label: Text('$count'),
                child: const Icon(Icons.forum_outlined),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Çocuğunu KLAVYENİN ÜSTÜNDE tutar: çocuğun alt kenarı klavyenin arkasına
/// düşüyorsa (ekranın gövdesi henüz kısalmadıysa) aradaki fark kadar yukarı
/// KAYDIRARAK çizer. Yalnız boyama ve isabet testi kayar — yerleşim yok.
///
/// KÖK NEDEN (kullanıcı bulgusu 2026-10-16: "balona yazarken klavye
/// kayması"): not editörü klavye açılırken gövdeyi bilerek animasyon
/// boyunca tam boyda tutar ve klavye DURUNCA tek seferde kısaltır (bkz.
/// `KeyboardSnap` — kasma çözümü). Gövdenin dibindeki yazma kartı bu yüzden
/// klavye açılırken ~400 ms klavyenin arkasında kalıyor, sonra birden
/// yukarı sıçrıyordu; yazılan ilk harfler görünmüyordu. Kart artık
/// klavyeyle kare kare birlikte yükselir; gövde oturunca fark sıfırlanır,
/// görünür hiçbir sıçrama olmaz. Klavyeyi zaten gövdeden düşen tam ekran
/// görüntüleyicilerde fark hep sıfırdır (etkisiz).
class _KeyboardFollow extends StatelessWidget {
  const _KeyboardFollow({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Bağımlılık YALNIZ bu küçük sarmalayıcıda: klavye karelerinde kartın
    // kendisi yeniden kurulmaz, yalnız çizim kayması güncellenir.
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    final view = View.of(context);
    final height = view.physicalSize.height / view.devicePixelRatio;
    // Sistem GEZİNME ÇUBUĞU da bir engel sayılır (kullanıcı ekran görüntüsü
    // 2026-10-20: yazma kipinde editörün alt çubuğu gizlenince bölme ekranın
    // dibine iniyor, kartın araç satırı telefonun geri/ana sayfa
    // düğmelerinin ALTINDA kalıyordu). Kart en az çubuğun üstünde durur.
    final keyboard = math.max(
      math.max(inset, view.viewInsets.bottom / view.devicePixelRatio),
      view.viewPadding.bottom / view.devicePixelRatio,
    );
    return _KeyboardFollowBox(keyboardTop: height - keyboard, child: child);
  }
}

class _KeyboardFollowBox extends SingleChildRenderObjectWidget {
  const _KeyboardFollowBox({required this.keyboardTop, super.child});

  /// Klavyenin üst kenarı (pencerenin tepesinden, mantıksal piksel).
  final double keyboardTop;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderKeyboardFollow(keyboardTop);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderKeyboardFollow renderObject,
  ) => renderObject.keyboardTop = keyboardTop;
}

class _RenderKeyboardFollow extends RenderProxyBox {
  _RenderKeyboardFollow(this._keyboardTop);

  double _keyboardTop;
  set keyboardTop(double value) {
    if (value == _keyboardTop) return;
    _keyboardTop = value;
    markNeedsPaint();
  }

  /// Son çizimdeki yukarı kayma (dp).
  double _shift = 0;

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) return;
    final bottom = localToGlobal(Offset(0, size.height)).dy;
    _shift = math.max(0.0, bottom - _keyboardTop);
    context.paintChild(child, offset.translate(0, -_shift));
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final child = this.child;
    if (child == null) return false;
    if (!size.contains(position.translate(0, _shift))) return false;
    final hit = result.addWithPaintOffset(
      offset: Offset(0, -_shift),
      position: position,
      hitTest: (result, transformed) =>
          child.hitTest(result, position: transformed),
    );
    if (hit) result.add(BoxHitTestEntry(this, position));
    return hit;
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    transform.translateByDouble(0, -_shift, 0, 1);
  }
}
