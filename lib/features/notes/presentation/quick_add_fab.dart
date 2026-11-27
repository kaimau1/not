import '../../../core/widgets/sheet_header.dart';

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/menu_layout.dart';
import '../../../core/personalize.dart';
import '../../../core/widgets/customizable.dart';
import '../data/document_scan.dart';
import '../data/user_templates.dart';
import '../domain/note_templates.dart';
import '../domain/note_type.dart';
import '../../settings/presentation/customize_hub.dart'
    show CustomizeSurface, showCustomizeHub;
import 'add_catalog.dart';
import 'qr_scan_screen.dart' show qrScanSupported;
import 'quick_add_actions.dart';
import '../../../core/widgets/press_scale.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/haptics.dart';

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
              onEdit: () {
                _close();
                if (!mounted) return;
                unawaited(
                  showCustomizeHub(
                    this.context,
                    initial: CustomizeSurface.addPanel,
                  ),
                );
              },
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
      // Belge + QR tek karoda (bkz. addCatalog); yalnız biri varsa eski yol.
      'scan': DocumentScan.available && qrScanSupported
          ? a.createScanOrQrNote
          : a.createScanNote,
      'qr': a.createQrNote,
      'file': a.createFromFile,
      'youtube': a.createYouTubeNote,
      'ordered': () => a.createNote(NoteType.ordered),
      'quickdrop': a.openQuickDrop,
      'draw': a.createHandwritingNote,
      'drawing': a.createDrawingNote,
      'template': a.createFromTemplate,
      'smartlist': a.createSmartList,
      'archive': a.createNotebook,
    };
    // FAVORİ ŞABLONLAR (kullanıcı isteği 2026-11-05: "favori şablonlar ekle
    // menüsünde görünür, en çok 4"): şablon bölümünün başına girer; bölüm
    // ızgarası karo sayısına göre kendini dizer. Eski sabit "Alışveriş
    // listesi" karosu artık varsayılan favori (bkz. FavoriteTemplatesNotifier).
    final favorites = favoriteTemplateOptions(context, a.ref, a);
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
          AppHaptics.heavy();
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
            duration: AppMotion.of(context, AppMotion.short),
            curve: AppMotion.curveOf(context, AppMotion.emphasized),
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
class _BlurBarrier extends StatefulWidget {
  const _BlurBarrier();

  @override
  State<_BlurBarrier> createState() => _BlurBarrierState();
}

class _BlurBarrierState extends State<_BlurBarrier>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AppMotion.quick,
  );
  late final Animation<double> _curved = CurvedAnimation(
    parent: _c,
    curve: AppMotion.standard,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(
      context,
    ).colorScheme.scrim.withValues(alpha: AppAlpha.scrim);
    if (MediaQuery.disableAnimationsOf(context)) {
      return ColoredBox(color: color);
    }
    return FadeTransition(
      opacity: _curved,
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
    required this.onEdit,
    required this.fit,
  });

  final List<QuickAddOption> options;

  /// "Menüyü düzenle": paneli kapatıp düzen merkezini açar.
  final VoidCallback onEdit;

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
    duration: AppMotion.medium,
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    // Kişiselleştirme (gizlenen seçenekler), sıra ve düzenleme modu: panel
    // açıkken değişirse hemen yansır.
    listenable: _panelListenable,
    builder: (context, _) => _build(context),
  );

  Widget _build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = AppTokens.fromTheme(theme);
    // Kullanıcı sırası (bilinmeyen/yeni seçenek grubunun sonunda).
    final options = MenuLayouts.of(quickAddMenuId)
        .sorted(widget.options, (o) => o.key);

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
      color: tokens.card,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        side: BorderSide(color: tokens.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        // Büyük yazı ölçeğinde/kısa ekranda panel ekranı aşmasın: kayar.
        constraints: BoxConstraints(maxHeight: widget.fit.maxHeight),
        // Kayınca da ilk görünen ÜST: birincil satır orada (2026-11-19).
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.m - 2,
            AppSpace.s,
            AppSpace.m - 2,
            AppSpace.m - 2,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // "Menüyü düzenle" (F60.S10) → düzen merkezinin "+" panosu.
              // Uygulama geneli düzenleme modunda karolar zaten düzenlenir:
              // düğme yer tutmaz.
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: editing
                    ? const SizedBox.shrink()
                    : IconButton(
                        key: const ValueKey('quick-add-edit'),
                        tooltip: l10n.menuEdit,
                        visualDensity: VisualDensity.compact,
                        iconSize: AppIconSize.m,
                        icon: Icon(Icons.tune, color: scheme.onSurfaceVariant),
                        onPressed: widget.onEdit,
                      ),
              ),
              // BİRİNCİL: büyük, dolgulu — PANELİN EN ÜSTÜNDE (kullanıcı
              // isteği 2026-11-19: "alttaki metin liste maddeyi üste taşı").
              Row(
                children: [
                  for (var i = 0; i < primary.length; i++) ...[
                    if (i > 0) const SizedBox(width: AppSpace.xs + 2),
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
              if (sections.isNotEmpty && primary.isNotEmpty)
                const SizedBox(height: AppSpace.xs),
              for (final section in sections) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.xs,
                    AppSpace.xs,
                    AppSpace.xs,
                    AppSpace.xs + 2,
                  ),
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
                const SizedBox(height: AppSpace.xs + 2),
              ],
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
    // Saydamlık hızlı gelir; ölçek "+" düğmesinden taşmadan, vurgulu
    // yavaşlamayla yumuşakça oturur.
    final fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.55, curve: AppMotion.standard),
    );
    final settle = CurvedAnimation(
      parent: _controller,
      curve: AppMotion.enter,
    );
    return FadeTransition(
      opacity: fade,
      child: AnimatedBuilder(
        animation: settle,
        child: sized,
        builder: (context, inner) => Transform.scale(
          scale: 0.90 + 0.10 * settle.value,
          alignment: Alignment.bottomRight,
          child: inner,
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
                Icon(option.icon, size: AppIconSize.l, color: scheme.onPrimaryContainer),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    option.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: scheme.onPrimaryContainer,
                      fontWeight: AppWeight.strong,
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
/// [a] null = yalnız ad/simge gerekir (düzen merkezinin "+" panosu).
List<QuickAddOption> favoriteTemplateOptions(
  BuildContext context,
  WidgetRef ref, [
  QuickAddActions? a,
]) {
  final l10n = context.l10n;
  final users = ref.read(userTemplatesProvider);
  final out = <QuickAddOption>[];
  for (final key in ref.read(favoriteTemplatesProvider)) {
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
          () => a?.createFromTemplate(t),
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
          () => a?.createFromTemplate(null, u),
        ),
      );
    }
  }
  return out;
}
