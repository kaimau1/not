import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/l10n_ext.dart';
import '../../domain/attachment.dart';

/// PDF ve slayt görüntüleyicilerinin ortak **not balonu** katmanı.
///
/// Kullanıcı belgenin istediği noktasına balon bırakır ve içine yazar; balon
/// açılıp kapanır, sürüklenerek taşınır, istenildiği kadar eklenir. Böylece
/// belgenin üzerinde "ne yapacağım" planı kurulabilir — çizimden farkı
/// aranabilir/düzenlenebilir METİN olması.
///
/// Balonlar PDF dosyasına GÖMÜLMEZ: sayfa oranlı (0–1) konumla [PageBubble]
/// listesinde durur ve [onChanged] ile üst katmana (ek → not → Firestore)
/// verilir — çizim katmanıyla (`InkController`) birebir aynı yol.
class BubbleController extends ChangeNotifier {
  BubbleController({required List<PageBubble> initial, required this.onChanged})
    : _bubbles = [...initial];

  /// Balonlar değişince güncel listeyle çağrılır (kaydetme).
  final ValueChanged<List<PageBubble>> onChanged;

  static const _uuid = Uuid();

  /// Yeni balonun varsayılan rengi ve seçilebilecek renkler. Konu ayırmak
  /// için: sarı "not", kırmızı "düzelt", yeşil "tamam", mavi "soru".
  static const palette = <int>[
    0xFFFFC107,
    0xFFEF5350,
    0xFF66BB6A,
    0xFF42A5F5,
    0xFFAB47BC,
  ];

  List<PageBubble> _bubbles;
  List<PageBubble> get bubbles => _bubbles;

  /// "Balon ekle" kipi açık mı? Açıkken sayfaya dokunmak o noktaya balon
  /// bırakır; kapalıyken sayfa normal okunur/kaydırılır ve yalnız var olan
  /// balonlar dokunuşa yanıt verir.
  bool adding = false;

  /// Yeni bırakılacak balonun rengi.
  int color = palette.first;

  /// Az önce eklenen balon: katman onu açık ve klavyesi odaklanmış getirir
  /// (kullanıcı balonu bırakır bırakmaz yazmaya başlasın).
  String? justAdded;

  bool _dirty = false;

  void setAdding(bool value) {
    if (adding == value) return;
    adding = value;
    notifyListeners();
  }

  void setColor(int value) {
    color = value;
    notifyListeners();
  }

  /// Dışarıdan gelen listeyi benimser (tam ekranda balon eklenip panoya
  /// dönüldüğünde). İÇERİK karşılaştırılır: her anlık görüntü yeni bir liste
  /// nesnesi kurduğu için kimlik karşılaştırması sonsuz tazelemeye yol açar.
  void replace(List<PageBubble> next) {
    if (_sameContent(_bubbles, next)) return;
    _bubbles = [...next];
    notifyListeners();
  }

  static bool _sameContent(List<PageBubble> a, List<PageBubble> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id ||
          a[i].page != b[i].page ||
          a[i].x != b[i].x ||
          a[i].y != b[i].y ||
          a[i].text != b[i].text ||
          a[i].color != b[i].color ||
          a[i].collapsed != b[i].collapsed) {
        return false;
      }
    }
    return true;
  }

  /// [page] sayfasının balonları (çizim gibi sayfa başına süzülür).
  List<PageBubble> forPage(int page) => [
    for (final b in _bubbles)
      if (b.page == page) b,
  ];

  void add(int page, double x, double y) {
    final bubble = PageBubble(
      id: _uuid.v4(),
      page: page,
      x: x.clamp(0.0, 1.0),
      y: y.clamp(0.0, 1.0),
      color: color,
    );
    _bubbles = [..._bubbles, bubble];
    justAdded = bubble.id;
    // Tek balon bırakıp arka arkaya on tane daha bırakmak isteyen azdır:
    // ekleme kipi bırakıldıktan sonra kapanır, kullanıcı yazısına odaklanır.
    adding = false;
    _dirty = true;
    notifyListeners();
    save();
  }

  void update(PageBubble bubble) {
    final index = _bubbles.indexWhere((b) => b.id == bubble.id);
    if (index < 0) return;
    _bubbles = [..._bubbles]..[index] = bubble;
    _dirty = true;
    notifyListeners();
  }

  /// Metin yazımı gibi sık değişimlerde [update] yalnız belleği tazeler;
  /// kaydetme (Firestore yazımı) balon kapanınca/odak düşünce buradan olur.
  void save() {
    if (!_dirty) return;
    _dirty = false;
    onChanged(_bubbles);
  }

  void remove(String id) {
    _bubbles = [
      for (final b in _bubbles)
        if (b.id != id) b,
    ];
    _dirty = true;
    if (justAdded == id) justAdded = null;
    notifyListeners();
    save();
  }

  void toggleCollapsed(String id) {
    final index = _bubbles.indexWhere((b) => b.id == id);
    if (index < 0) return;
    final bubble = _bubbles[index];
    _bubbles = [..._bubbles]..[index] = bubble.copyWith(
      collapsed: !bubble.collapsed,
    );
    if (justAdded == id) justAdded = null;
    _dirty = true;
    notifyListeners();
    save();
  }

  /// Boş kalmış balonları atar — kullanıcı balon bırakıp hiçbir şey yazmadan
  /// çıkarsa sayfada anlamsız bir nokta kalmasın.
  void dropEmpty() {
    final kept = [
      for (final b in _bubbles)
        if (b.text.trim().isNotEmpty) b,
    ];
    if (kept.length != _bubbles.length) {
      _bubbles = kept;
      _dirty = true;
      notifyListeners();
    }
    save();
  }
}

/// Tek bir sayfanın üzerindeki balonlar. Sayfa katmanı olarak
/// (`pageOverlaysBuilder` / `Positioned.fill`) kurulur.
///
/// **Dokunuşu YUTMAZ:** ekleme kipi kapalıyken katmanın kendisi saydamdır,
/// yalnız balonların kendisi dokunuş alır — sayfa kaydırma/yakınlaştırma
/// bozulmaz. Ekleme kipinde ise tam sayfa bir dokunuş yakalayıcı devreye
/// girer (kullanıcı zaten "bir yere balon bırakacağım" derdinde).
class BubblePageLayer extends StatelessWidget {
  const BubblePageLayer({
    super.key,
    required this.controller,
    required this.page,
    this.readOnly = false,
  });

  final BubbleController controller;
  final int page;

  /// Salt görüntüleme (pano/küçük önizleme): balonlar görünür ve açılıp
  /// kapanır ama düzenlenmez/taşınmaz.
  final bool readOnly;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final bubbles = controller.forPage(page);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            if (controller.adding && !readOnly)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (d) => controller.add(
                    page,
                    d.localPosition.dx / size.width,
                    d.localPosition.dy / size.height,
                  ),
                  child: ColoredBox(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.06),
                  ),
                ),
              ),
            for (final bubble in bubbles)
              _Bubble(
                key: ValueKey(bubble.id),
                controller: controller,
                bubble: bubble,
                pageSize: size,
                readOnly: readOnly,
                autofocus: controller.justAdded == bubble.id,
              ),
          ],
        );
      },
    ),
  );
}

class _Bubble extends StatefulWidget {
  const _Bubble({
    super.key,
    required this.controller,
    required this.bubble,
    required this.pageSize,
    required this.readOnly,
    required this.autofocus,
  });

  final BubbleController controller;
  final PageBubble bubble;
  final Size pageSize;
  final bool readOnly;
  final bool autofocus;

  @override
  State<_Bubble> createState() => _BubbleState();
}

class _BubbleState extends State<_Bubble> {
  late final TextEditingController _text = TextEditingController(
    text: widget.bubble.text,
  );
  final _focus = FocusNode();

  /// Açık balonun genişliği: sayfanın %62'si ama 260 px'i geçmez. Dar
  /// telefonda okunur, geniş tablette sayfayı kapatmaz.
  static const _maxWidth = 260.0;
  static const _pinSize = 28.0;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      // Odak düşünce yazılan metin kalıcılaşır (her tuşta Firestore'a
      // yazmamak için: `update` belleği, `save` diski tazeler).
      if (!_focus.hasFocus) widget.controller.save();
    });
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focus.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(_Bubble old) {
    super.didUpdateWidget(old);
    // Dışarıdan (senkron) değişen metni benimse — kullanıcı o an yazmıyorsa.
    if (widget.bubble.text != _text.text && !_focus.hasFocus) {
      _text.text = widget.bubble.text;
    }
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  double get _width =>
      (widget.pageSize.width * 0.62).clamp(140.0, _maxWidth).toDouble();

  /// Balonun sol-üst köşesinin sayfadaki piksel konumu. Uç noktası (x,y)
  /// sayfanın sağ/alt kenarına yakınsa kart içeri alınır ki taşmasın.
  Offset _topLeft(double width, {required bool collapsed}) {
    final point = Offset(
      widget.bubble.x * widget.pageSize.width,
      widget.bubble.y * widget.pageSize.height,
    );
    if (collapsed) {
      return point - const Offset(_pinSize / 2, _pinSize / 2);
    }
    final maxLeft = widget.pageSize.width - width;
    final left = maxLeft <= 0 ? 0.0 : (point.dx - width / 2).clamp(0.0, maxLeft);
    return Offset(left, point.dy + _pinSize / 2);
  }

  void _drag(Offset delta) {
    if (widget.readOnly) return;
    final b = widget.bubble;
    widget.controller.update(
      b.copyWith(
        x: (b.x + delta.dx / widget.pageSize.width).clamp(0.0, 1.0),
        y: (b.y + delta.dy / widget.pageSize.height).clamp(0.0, 1.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bubble = widget.bubble;
    final color = Color(bubble.color);
    if (bubble.collapsed) {
      final at = _topLeft(_pinSize, collapsed: true);
      return Positioned(
        left: at.dx,
        top: at.dy,
        child: GestureDetector(
          onTap: () => widget.controller.toggleCollapsed(bubble.id),
          onPanUpdate: (d) => _drag(d.delta),
          onPanEnd: (_) => widget.controller.save(),
          child: Tooltip(
            message: bubble.text,
            child: Container(
              width: _pinSize,
              height: _pinSize,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(color: Color(0x40000000), blurRadius: 4),
                ],
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                size: 15,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      );
    }

    final width = _width;
    final at = _topLeft(width, collapsed: false);
    final scheme = Theme.of(context).colorScheme;
    return Positioned(
      left: at.dx,
      top: at.dy,
      width: width,
      child: Material(
        color: color.withValues(alpha: 0.96),
        elevation: 3,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 2, 4, 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Başlık şeridi tutamaçtır: buradan sürüklenerek taşınır,
              // gövdeye dokunmak yazmayı açar (sürükleme yazmayı bozmaz).
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanUpdate: (d) => _drag(d.delta),
                onPanEnd: (_) => widget.controller.save(),
                child: Row(
                  children: [
                    const Icon(
                      Icons.drag_indicator,
                      size: 16,
                      color: Colors.black54,
                    ),
                    const Spacer(),
                    if (!widget.readOnly)
                      _iconButton(
                        icon: Icons.palette_outlined,
                        tooltip: context.l10n.color,
                        onPressed: () => _pickColor(context),
                      ),
                    _iconButton(
                      icon: Icons.close_fullscreen,
                      tooltip: context.l10n.bubbleCollapse,
                      onPressed: () =>
                          widget.controller.toggleCollapsed(bubble.id),
                    ),
                    if (!widget.readOnly)
                      _iconButton(
                        icon: Icons.delete_outline,
                        tooltip: context.l10n.delete,
                        onPressed: () => widget.controller.remove(bubble.id),
                      ),
                  ],
                ),
              ),
              if (widget.readOnly)
                Padding(
                  padding: const EdgeInsets.fromLTRB(2, 2, 4, 2),
                  child: Text(
                    bubble.text,
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                )
              else
                TextField(
                  controller: _text,
                  focusNode: _focus,
                  maxLines: null,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                  cursorColor: scheme.onSurface,
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: context.l10n.bubbleHint,
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: Colors.black38,
                    ),
                  ),
                  onChanged: (value) =>
                      widget.controller.update(bubble.copyWith(text: value)),
                  onTapOutside: (_) {
                    _focus.unfocus();
                    widget.controller.save();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    icon: Icon(icon, size: 16, color: Colors.black54),
    visualDensity: VisualDensity.compact,
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
  );

  Future<void> _pickColor(BuildContext context) async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 12,
            children: [
              for (final argb in BubbleController.palette)
                GestureDetector(
                  onTap: () => Navigator.pop(sheetContext, argb),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Color(argb),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.bubble.color == argb
                            ? Colors.black
                            : Colors.black26,
                        width: widget.bubble.color == argb ? 3 : 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked == null) return;
    widget.controller
      ..update(widget.bubble.copyWith(color: picked))
      ..save();
  }
}

/// Görüntüleyicinin alt çubuğuna konan balon araç çubuğu: ekleme kipi
/// düğmesi, renk seçimi ve kısa bir ipucu.
class BubbleToolbar extends StatelessWidget {
  const BubbleToolbar({super.key, required this.controller});

  final BubbleController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
          child: Row(
            children: [
              for (final argb in BubbleController.palette)
                GestureDetector(
                  onTap: () => controller.setColor(argb),
                  child: Container(
                    width: 26,
                    height: 26,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Color(argb),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: controller.color == argb
                            ? scheme.onSurface
                            : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                  ),
                ),
              const Spacer(),
              Flexible(
                child: Text(
                  context.l10n.bubbleTapToPlace,
                  textAlign: TextAlign.end,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
