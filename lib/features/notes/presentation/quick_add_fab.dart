import '../../../core/widgets/sheet_header.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/menu_layout.dart';
import '../../../core/personalize.dart';
import '../../../core/widgets/customizable.dart';
import '../data/user_templates.dart';
import '../domain/note_templates.dart';
import '../domain/note_type.dart';
import 'add_catalog.dart';
import 'quick_add_actions.dart';
import '../../../core/widgets/press_scale.dart';

/// "+" düğmesi: dokununca tek panel açılır — bütün seçenekler gruplu ve TEK
/// dokunuşla (bkz. [_QuickAddPanel]). Basılı tutmak da açar.
///
/// Panel bir Overlay katmanında, düğmeye demirlenmiş olarak gösterilir:
/// - Böylece açılınca yerinde büyüyüp üstteki sesli asistan düğmesini
///   ittirmez, konum kaymaz (madde 3).
/// - Tam ekran bir bariyer, sayfanın herhangi bir yerine dokununca menüyü
///   kapatır — tekrar "+" basmaya gerek kalmaz (madde 12). Bariyer aynı
///   zamanda arka planı BULANIKLAŞTIRIR: menü açıkken göz seçeneklere gider,
///   arkadaki not duvarı dikkat dağıtmaz.
/// Panel şu an açık mı — ana ekranın PopScope'u okur.
///
/// Panel ve ana ekran AYNI rotada iki ayrı PopScope kuruyor; Flutter geri
/// tuşunda rotadaki TÜM PopScope geri çağrılarını çalıştırdığı için tek geri
/// hem paneli hem seçim modunu birden kapatıyordu. Ana ekran bunu okuyup
/// sırayı panele bırakır.
final quickAddPanelOpen = ValueNotifier(false);

/// "+" menüsünün SIRA kaydının kimliği ([MenuLayouts]; F60.S10). Gizleme
/// eskisi gibi `Personalize`'da (`UiItem.quickAdd`) — Ayarlar'daki
/// kişiselleştirme ve eklentiler aynı kaydı okumaya devam eder.
const quickAddMenuId = 'home.quickAdd';

/// Panelin dinlediği iki kayıt: gizleme (Personalize) ve sıra (MenuLayouts).
/// TEK örnek: her build'de yeni birleşik dinlenebilir kurulmasın.
final Listenable _panelListenable = Listenable.merge([
  Personalize.listenable,
  MenuLayouts.layouts,
]);

class QuickAddFab extends StatefulWidget {
  const QuickAddFab({
    super.key,
    required this.anchor,
    required this.actions,
    this.onVoiceCapture,
    this.inRail = false,
    this.beforeAction,
  });

  /// Menünün demirlendiği nokta. Dashboard bunu mikrofon + "+" sütununun
  /// TAMAMINI saracak şekilde verir; menü sütunun tepesinden açılır ve
  /// mikrofon düğmesinin üstünü örtmez.
  final LayerLink anchor;

  /// Oluşturma akışlarının sahibi (ana ekran). Dokunuş anında okunur: rayın
  /// düğmesi ana ekrandan önce kurulur; yoksa panel açılmaz.
  final QuickAddActions? Function() actions;

  /// Sesli not. Ana ekranın kendi TEK mikrofonu var (F3.1) — orada null;
  /// klasör sayfasında menünün birincil satırında durur.
  final VoidCallback? onVoiceCapture;

  /// Rayda (K3): küçük düğme, panel düğmenin SAĞINDA tepeden açılır, Esc
  /// kapatır.
  final bool inRail;

  /// Seçilen iş başlamadan önce (ray: bölümden notlara dön).
  final VoidCallback? beforeAction;

  @override
  State<QuickAddFab> createState() => _QuickAddFabState();
}

class _QuickAddFabState extends State<QuickAddFab> {
  OverlayEntry? _entry;

  bool get _open => _entry != null;

  void _close() {
    _entry?.remove();
    _entry = null;
    quickAddPanelOpen.value = false;
    if (mounted) setState(() {});
  }

  /// PANEL EKRANA SIĞSIN (kullanıcı bulgusu 2026-11-02: "tablette artı menüsü
  /// sola taşıyor"): panel "+"nın sağına hizalı ve 380 dp; ana-detayda liste
  /// paneli 260 dp'ye kadar daraldığından düğme ekranın solunda kalabiliyor.
  /// Taşan kadar sağa kaydırılır, yüksekliği de düğmenin üstündeki alanla
  /// sınırlanır. Saf hesap: [quickAddPanelFit].
  ({double width, double dx, double maxHeight}) _panelFit() {
    final overlay = Overlay.of(context).context;
    final fab = context.findRenderObject()! as RenderBox;
    final box = overlay.findRenderObject()! as RenderBox;
    final rect = fab.localToGlobal(Offset.zero, ancestor: box) & fab.size;
    if (widget.inRail) {
      return (
        width: math.min(380.0, box.size.width - rect.right - 24),
        dx: 0.0,
        maxHeight: math.max(160.0, box.size.height - rect.top - 12),
      );
    }
    return quickAddPanelFit(
      screen: box.size,
      fabRight: rect.right,
      fabTop: rect.top,
      topInset: MediaQuery.paddingOf(overlay).top,
    );
  }

  void _openMenu() {
    final actions = widget.actions();
    if (actions == null) return;
    final rail = widget.inRail;
    _entry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Masaüstü: klavye odağı panelde, Esc kapatır.
          if (rail)
            Focus(
              autofocus: true,
              onKeyEvent: (_, event) {
                if (event is! KeyDownEvent ||
                    event.logicalKey != LogicalKeyboardKey.escape) {
                  return KeyEventResult.ignored;
                }
                _close();
                return KeyEventResult.handled;
              },
              child: const SizedBox.shrink(),
            ),
          // Dışarı dokununca kapanan tam ekran bariyer; arka planı bulanık
          // yapar ve hafifçe karartır.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _close,
              child: const _BlurBarrier(),
            ),
          ),
          // Seçenekler "+" düğmesinin hemen üstüne demirlenir (layout'u
          // değiştirmez, sesli asistan düğmesi yerinden oynamaz).
          CompositedTransformFollower(
            link: widget.anchor,
            targetAnchor: Alignment.topRight,
            followerAnchor: rail ? Alignment.topLeft : Alignment.bottomRight,
            offset: rail ? const Offset(12, 0) : Offset(_panelFit().dx, -12),
            child: _QuickAddPanel(
              options: _options(context, actions),
              onSelected: _select,
              fit: _panelFit(),
            ),
          ),
          // Bulanıklığın ÜSTÜnde duran keskin "×" kopyası: bariyer tüm sayfayı
          // (dolayısıyla asıl "+" düğmesini de) bulanıklaştırdığından, düğme
          // bozuk görünmesin diye aynı yere net bir eş konur. Dokunuşu menüyü
          // kapatır — asıl düğmenin davranışının aynısı.
          // Hizalama alttan-ORTA: bağlantı noktası tüm düğme sütununu sarar ve
          // sütun kendi içinde ortalanmıştır (sağa dayamak 14 px kaydırırdı).
          CompositedTransformFollower(
            link: widget.anchor,
            targetAnchor: Alignment.bottomCenter,
            followerAnchor: Alignment.bottomCenter,
            child: _fab(
              heroTag: 'add-fab-open',
              tooltip: context.l10n.close,
              onPressed: _close,
              child: Transform.rotate(
                angle: math.pi / 4, // + → ×
                child: const Icon(Icons.add),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_entry!);
    quickAddPanelOpen.value = true;
    setState(() {});
  }

  /// Menüdeki BÜTÜN seçenekler. Anahtar kişiselleştirmenin (`UiItem.quickAdd`)
  /// kalıcı kimliğidir. Ad/simge/grup TEK listeden ([addCatalog]) gelir.
  List<QuickAddOption> _options(BuildContext context, QuickAddActions a) {
    final actions = <String, VoidCallback?>{
      'text': () => a.createNote(NoteType.text),
      'checklist': () => a.createNote(NoteType.checklist),
      'voice': widget.onVoiceCapture,
      'photo': a.createPhotoNote,
      'video': a.createVideoNote,
      'scan': a.createScanNote,
      'qr': a.createQrNote,
      'file': a.createFromFile,
      'youtube': a.createYouTubeNote,
      'ordered': () => a.createNote(NoteType.ordered),
      'draw': a.createHandwritingNote,
      'drawing': a.createDrawingNote,
      'template': a.createFromTemplate,
      'archive': a.createNotebook,
    };
    // FAVORİ ŞABLONLAR (kullanıcı isteği 2026-11-05: "favori şablonlar ekle
    // menüsünde görünür, en çok 4"): şablon bölümünün başına girer; bölüm
    // ızgarası karo sayısına göre kendini dizer. Eski sabit "Alışveriş
    // listesi" karosu artık varsayılan favori (bkz. FavoriteTemplatesNotifier).
    final favorites = favoriteTemplateOptions(context, a);
    final out = <QuickAddOption>[];
    for (final m in addCatalog(context.l10n, AddContext.newNote)) {
      if (m.id == 'template') out.addAll(favorites);
      if (actions[m.id] case final action?) {
        out.add(QuickAddOption(m.id, m.group, m.icon, m.label, m.info, action));
      }
    }
    return out;
  }

  void _select(VoidCallback action) {
    _close();
    widget.beforeAction?.call();
    action();
  }

  /// Rayda küçük ve ikincil ton (K3: birincil kapı kalem), ana ekranda tam boy.
  Widget _fab({
    required String heroTag,
    required String tooltip,
    required VoidCallback onPressed,
    required Widget child,
  }) {
    if (!widget.inRail) {
      return FloatingActionButton(
        heroTag: heroTag,
        tooltip: tooltip,
        onPressed: onPressed,
        child: child,
      );
    }
    final scheme = Theme.of(context).colorScheme;
    return SizedBox.square(
      dimension: 48,
      child: FloatingActionButton(
        heroTag: heroTag,
        tooltip: tooltip,
        elevation: 0,
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onPressed: onPressed,
        child: child,
      ),
    );
  }

  @override
  void dispose() {
    _entry?.remove();
    _entry = null;
    // Panel açıkken ekran kapanırsa bayrak takılı kalmasın.
    quickAddPanelOpen.value = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // FAB'ın onLongPress'i yok: uzun basış dıştaki GestureDetector'a düşer
    // (InkWell uzun basışı sahiplenmediğinden çakışma olmaz).
    //
    // PopScope: panel bir Overlay katmanı, rota DEĞİL — sistem geri tuşu
    // Navigator'a gidiyor ve panel açıkken geri basmak paneli bırakıp
    // UYGULAMADAN çıkıyordu. Geri artık önce paneli kapatır.
    final button = PopScope(
      canPop: !_open,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: GestureDetector(
        onLongPress: () {
          HapticFeedback.mediumImpact();
          if (!_open) _openMenu();
        },
        child: _fab(
          heroTag: 'add-fab',
          tooltip: l10n.quickAddTooltip,
          // Dokunmak tip menüsünü açar (metin/madde/sıralı/el yazısı); açıkken
          // tekrar dokunmak kapatır.
          onPressed: _open ? _close : _openMenu,
          child: AnimatedRotation(
            turns: _open ? 0.125 : 0, // + → × dönüşü
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutBack,
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
    if (!widget.inRail) return button;
    // Ray iç gezginlerin üstünde: PopScope sistem geri tuşuna denk gelmez.
    return BackButtonListener(
      onBackButtonPressed: () async {
        if (!_open) return false;
        _close();
        return true;
      },
      child: button,
    );
  }
}

/// Menü açıkken arka planı KARARTAN tam ekran katman.
///
/// BULANIKLIK KALDIRILDI (kullanıcı bulgusu 2026-10-15: "kasma"): tam ekran
/// `BackdropFilter` arkadaki not duvarının (onlarca görsel kart) her
/// karesini GPU'da yeniden bulanıklaştırıyordu; açılış animasyonu boyunca
/// sigma her karede değiştiği için önbelleğe de alınamıyordu. Düşük uçlu
/// cihazda menü açılırken takılma buradandı. Karartma (saydamlık) aynı
/// odaklamayı neredeyse bedavaya verir.
class _BlurBarrier extends StatelessWidget {
  const _BlurBarrier();

  static const _dim = 0.32;

  @override
  Widget build(BuildContext context) {
    final color = Colors.black.withValues(alpha: _dim);
    if (MediaQuery.disableAnimationsOf(context)) {
      return ColoredBox(color: color);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      builder: (context, t, child) => Opacity(opacity: t, child: child),
      child: ColoredBox(color: color),
    );
  }
}

/// Menüdeki tek seçenek. [key] kalıcı kimlik (kişiselleştirme).
@immutable
class QuickAddOption {
  const QuickAddOption(
    this.key,
    this.group,
    this.icon,
    this.label,
    this.info,
    this.action,
  );

  final String key;
  final AddGroup group;
  final IconData icon;
  final String label;
  final String? info;
  final VoidCallback action;
}

/// Yeni not paneli — TEK PANEL, TEK DOKUNUŞ (kullanıcı isteği 2026-10-20:
/// "artı menüsü düzeni").
///
/// F3.2'de panel dört KAPIYDI (Kamera · Dosya ekle · Şablon + Metin/Liste);
/// her kapı ayrı bir levha açıyor, fotoğraf ya da dosya için iki adım
/// gerekiyordu ve levhada ne olduğu panelden görünmüyordu. Şimdi bütün
/// seçenekler panelde, başlıklı gruplar hâlinde, dört sütunlu ızgarada.
/// Aşağıdan yukarı, başparmağın olduğu yerden okunur:
///  1. En altta, FAB'ın hemen üstünde büyük düğmeler: Metin · Liste · Sıralı.
///  2. Yukarı doğru not içi Ekle levhasıyla AYNI sıra (F41.2): Kalem · Kamera ·
///     Dosya ve bağlantı · Ses · Şablon.
/// Gizlenen seçenek yer kaplamaz; boş kalan grup başlığıyla birlikte düşer.
/// "+" panelinin ekrana sığan ölçüsü: [dx] panelin sağa kayması, düğmenin
/// sağ kenarı panele yetmiyorsa. Kenarda 12 dp boşluk kalır.
({double width, double dx, double maxHeight}) quickAddPanelFit({
  required Size screen,
  required double fabRight,
  required double fabTop,
  double topInset = 0,
}) {
  const margin = 12.0;
  final width = math.min(380.0, screen.width - margin * 2);
  return (
    width: width,
    dx: math.max(0, width + margin - fabRight),
    maxHeight: math.max(160, fabTop - margin * 2 - topInset),
  );
}

class _QuickAddPanel extends StatefulWidget {
  const _QuickAddPanel({
    required this.options,
    required this.onSelected,
    required this.fit,
  });

  final List<QuickAddOption> options;

  /// Ekrana sığan ölçü (bkz. [quickAddPanelFit]).
  final ({double width, double dx, double maxHeight}) fit;

  /// Seçilen işlemi paneli kapatarak çalıştırır.
  final void Function(VoidCallback action) onSelected;

  @override
  State<_QuickAddPanel> createState() => _QuickAddPanelState();
}

class _QuickAddPanelState extends State<_QuickAddPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// MENÜ DÜZEN KİPİ (F60.S10): panelin içinde, karolar yerine satırlar —
  /// göz (gizle/göster) + tutamaç (sırala). Yerel durum: kök ekranı
  /// yeniden kurmaz.
  bool _arranging = false;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    // Kişiselleştirme (gizlenen seçenekler), sıra ve düzenleme modu: panel
    // açıkken değişirse hemen yansır.
    listenable: _panelListenable,
    builder: (context, _) => _build(context),
  );

  Widget _build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    // Kullanıcı sırası (bilinmeyen/yeni seçenek grubunun sonunda).
    final options = MenuLayouts.of(quickAddMenuId)
        .sorted(widget.options, (o) => o.key);

    if (_arranging) {
      return _wrap(
        context,
        _QuickAddArranger(
          options: options,
          maxHeight: widget.fit.maxHeight,
          onDone: () => setState(() => _arranging = false),
        ),
      );
    }

    // Gizlenen seçenek panelde yer kaplamaz; DÜZENLEME MODUNDA hepsi
    // görünür (gizliler soluk) ve dokunmak gizle/göster yapar.
    final editing = Personalize.editing;
    final prefs = Personalize.current;
    bool shown(QuickAddOption o) =>
        editing || prefs.shows(UiItem.quickAdd(o.key));
    List<QuickAddOption> of(AddGroup g) => [
      for (final o in options)
        if (o.group == g && shown(o)) o,
    ];
    final primary = of(AddGroup.write);
    // Panel başparmaktan yukarı okunur: grup sırası tersten yazılır.
    final sections = [
      for (final g in AddGroup.values.reversed)
        if (g != AddGroup.write && of(g).isNotEmpty) (group: g, options: of(g)),
    ];

    Widget cell(QuickAddOption o, {bool wide = false}) => Customizable(
      id: UiItem.quickAdd(o.key),
      badgeInset: 6,
      child: AddTile(
        key: ValueKey('quick-add-${o.key}'),
        icon: o.icon,
        label: o.label,
        tooltip: o.info,
        wide: wide,
        onTap: () => widget.onSelected(o.action),
      ),
    );

    final panel = Material(
      color: scheme.surface,
      elevation: 8,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        // Büyük yazı ölçeğinde/kısa ekranda panel ekranı aşmasın: kayar.
        constraints: BoxConstraints(maxHeight: widget.fit.maxHeight),
        child: SingleChildScrollView(
          reverse: true,
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // "Menüyü düzenle" (F60.S10). Uygulama geneli düzenleme
              // modunda karolar zaten düzenlenir: düğme yer tutmaz.
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: editing
                    ? const SizedBox.shrink()
                    : IconButton(
                        key: const ValueKey('quick-add-edit'),
                        tooltip: l10n.menuEdit,
                        visualDensity: VisualDensity.compact,
                        iconSize: 20,
                        icon: Icon(Icons.tune, color: scheme.onSurfaceVariant),
                        onPressed: () => setState(() => _arranging = true),
                      ),
              ),
              for (final section in sections) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
                  // Tek bölüm başlığı (F39.6): renk yalnız simgelerde.
                  child: SectionLabel(
                    addGroupTitle(l10n, section.group),
                    key: ValueKey('quick-section-${section.group.name}'),
                  ),
                ),
                AddTileGrid(
                  count: section.options.length,
                  tile: (i, wide) => cell(section.options[i], wide: wide),
                ),
                const SizedBox(height: 6),
              ],
              if (sections.isNotEmpty && primary.isNotEmpty)
                const SizedBox(height: 4),
              // BİRİNCİL: büyük, dolgulu, FAB'ın hemen üstünde.
              Row(
                children: [
                  for (var i = 0; i < primary.length; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    Expanded(
                      child: Customizable(
                        id: UiItem.quickAdd(primary[i].key),
                        badgeInset: 6,
                        child: _PrimaryButton(
                          key: ValueKey('quick-add-${primary[i].key}'),
                          option: primary[i],
                          onTap: () => widget.onSelected(primary[i].action),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );

    return _wrap(context, panel);
  }

  /// Genişlik + açılış hareketi (normal ve düzen kipinde aynı).
  Widget _wrap(BuildContext context, Widget panel) {
    final sized = SizedBox(width: widget.fit.width, child: panel);
    if (MediaQuery.disableAnimationsOf(context)) return sized;
    // Saydamlık hızlı ve düz gelir; ölçek ise "+" düğmesinden YAYLI
    // açılır (hafifçe taşıp yerine oturur — iOS menülerinin açılışı).
    final fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.6, curve: Curves.easeOut),
    );
    final spring = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    return FadeTransition(
      opacity: fade,
      child: AnimatedBuilder(
        animation: spring,
        child: sized,
        builder: (context, inner) => Transform.scale(
          scale: 0.86 + 0.14 * spring.value,
          alignment: Alignment.bottomRight,
          child: inner,
        ),
      ),
    );
  }
}

/// "+" MENÜSÜNÜ DÜZENLE (F60.S10, kullanıcı isteği 2026-11-11: "not ekle
/// menüsünde her buton düzenlenebilir olmalı; gizle, göster, yer değiştir").
///
/// Menü düzenleyicisinin ([ActionMenu] "Menüyü düzenle") aynı deseni: satır
/// başına göz (gizle/göster) + sürükleme tutamacı; panelle aynı gruplar,
/// panelle aynı sırada (başparmaktan yukarı). Sıra grubun İÇİNDE değişir —
/// panel gruplu çizildiğinden gruplar arası taşıma anlamsız olurdu.
/// Değişiklik ANINDA kaydedilir (gizleme `Personalize`, sıra `MenuLayouts`);
/// "Bitti" yalnız kipten çıkar. Son görünür seçenek gizlenemez.
class _QuickAddArranger extends StatelessWidget {
  const _QuickAddArranger({
    required this.options,
    required this.maxHeight,
    required this.onDone,
  });

  /// Kullanıcı sırasındaki BÜTÜN seçenekler (gizliler dahil).
  final List<QuickAddOption> options;
  final double maxHeight;
  final VoidCallback onDone;

  static String _id(QuickAddOption o) => UiItem.quickAdd(o.key);

  /// [group] içinde [from] → [to]; tam sıra (bütün gruplar) kaydedilir.
  void _reorder(AddGroup group, int from, int to) {
    final inGroup = [
      for (final o in options)
        if (o.group == group) o.key,
    ];
    inGroup.insert(to, inGroup.removeAt(from));
    final moved = inGroup.iterator;
    final order = [
      for (final o in options)
        if (o.group == group) (moved..moveNext()).current else o.key,
    ];
    final cur = MenuLayouts.of(quickAddMenuId);
    MenuLayouts.set(
      quickAddMenuId,
      MenuLayout(hidden: cur.hidden, quick: cur.quick, order: order),
    );
  }

  static void _reset() {
    Personalize.update(
      (p) => p.copyWith(
        hidden: {
          for (final h in p.hidden)
            if (!h.startsWith(UiItem.quickAdd(''))) h,
        },
      ),
    );
    MenuLayouts.set(quickAddMenuId, const MenuLayout());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    // Kayıt (taslak değil): bu düzenleyici doğrudan kaydeder.
    final prefs = Personalize.prefs.value;
    final visibleCount = options.where((o) => prefs.shows(_id(o))).length;

    Widget row(QuickAddOption o, int index) {
      final shown = prefs.shows(_id(o));
      final locked = shown && visibleCount <= 1;
      final faded = scheme.onSurfaceVariant.withValues(alpha: 0.5);
      return ListTile(
        key: ValueKey('quick-edit-row-${o.key}'),
        dense: true,
        contentPadding: const EdgeInsetsDirectional.only(start: 8),
        leading: Icon(o.icon, size: 20, color: shown ? scheme.primary : faded),
        title: Text(
          o.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: shown ? null : faded),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              key: ValueKey('quick-edit-eye-${o.key}'),
              tooltip: locked
                  ? l10n.quickAddKeepOne
                  : shown
                  ? l10n.customizeHideItem
                  : l10n.customizeShowItem,
              icon: Icon(
                shown
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: locked
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      Personalize.update((p) => p.withVisible(_id(o), !shown));
                    },
            ),
            ReorderableDragStartListener(
              key: ValueKey('quick-edit-handle-${o.key}'),
              index: index,
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.drag_handle),
              ),
            ),
          ],
        ),
      );
    }

    final groups = [
      for (final g in AddGroup.values.reversed)
        (
          group: g,
          options: [
            for (final o in options)
              if (o.group == g) o,
          ],
        ),
    ].where((e) => e.options.isNotEmpty);

    return Material(
      color: scheme.surface,
      elevation: 8,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: SingleChildScrollView(
                // Panel gibi başparmaktan yukarı: açılınca alt uç görünür.
                reverse: true,
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(6, 0, 6, 2),
                      child: Text(
                        l10n.menuEdit,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
                      child: Text(
                        l10n.quickAddEditHint,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    for (final g in groups) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 6, 4, 2),
                        child: SectionLabel(addGroupTitle(l10n, g.group)),
                      ),
                      ReorderableListView(
                        key: ValueKey('quick-edit-group-${g.group.name}'),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        buildDefaultDragHandles: false,
                        onReorderItem: (from, to) =>
                            _reorder(g.group, from, to),
                        children: [
                          for (var i = 0; i < g.options.length; i++)
                            row(g.options[i], i),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
              child: Row(
                children: [
                  TextButton(
                    key: const ValueKey('quick-edit-reset'),
                    onPressed: _reset,
                    child: Text(l10n.personalizeReset),
                  ),
                  const Spacer(),
                  FilledButton(
                    key: const ValueKey('quick-edit-done'),
                    onPressed: onDone,
                    child: Text(l10n.reorderDone),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Birincil düğme (Metin / Liste): dolgulu, büyük, simge + yazı ÜST ÜSTE.
class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({super.key, required this.option, required this.onTap});

  final QuickAddOption option;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Basınca hafifçe çöker (bkz. PressScale).
    return PressScale(
      scale: 0.95,
      child: Material(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 70,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(option.icon, size: 24, color: scheme.onPrimaryContainer),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    option.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Favori şablonların "+" karoları (en çok 4; bkz.
/// [FavoriteTemplatesNotifier]). Silinmiş kendi şablonum atlanır.
List<QuickAddOption> favoriteTemplateOptions(
  BuildContext context,
  QuickAddActions a,
) {
  final l10n = context.l10n;
  final users = a.ref.read(userTemplatesProvider);
  final out = <QuickAddOption>[];
  for (final key in a.ref.read(favoriteTemplatesProvider)) {
    final id = key.substring(2);
    if (key.startsWith('b:')) {
      final t = NoteTemplate.values.where((t) => t.key == id).firstOrNull;
      if (t == null) continue;
      out.add(
        QuickAddOption(
          'fav-$key',
          AddGroup.template,
          t.icon,
          t.label(l10n),
          t.description(l10n),
          () => a.createFromTemplate(t),
        ),
      );
    } else if (key.startsWith('u:')) {
      final u = users.where((u) => u.id == id).firstOrNull;
      if (u == null) continue;
      out.add(
        QuickAddOption(
          'fav-$key',
          AddGroup.template,
          switch (u.type) {
            NoteType.checklist => Icons.checklist,
            NoteType.ordered => Icons.format_list_numbered,
            _ => Icons.bookmark_outline,
          },
          u.name.isEmpty ? l10n.remindersUntitled : u.name,
          null,
          () => a.createFromTemplate(null, u),
        ),
      );
    }
  }
  return out;
}
