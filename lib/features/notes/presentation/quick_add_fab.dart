import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/personalize.dart';
import '../../../core/widgets/customizable.dart';
import '../../../core/widgets/app_sheet.dart';
import '../data/document_scan.dart';
import '../domain/note_templates.dart';
import '../domain/note_type.dart';
import 'quick_add_actions.dart';
import 'qr_scan_screen.dart';
import '../../../core/widgets/press_scale.dart';

/// "+" düğmesi: dokununca dört kapılı panel açılır (Metin/Liste · Kamera ·
/// Dosya ekle · Şablon — bkz. [_QuickAddPanel]). Basılı tutmak da açar.
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

class QuickAddFab extends StatefulWidget {
  const QuickAddFab({
    super.key,
    required this.anchor,
    required this.actions,
    this.onVoiceCapture,
  });

  /// Menünün demirlendiği nokta. Dashboard bunu mikrofon + "+" sütununun
  /// TAMAMINI saracak şekilde verir; menü sütunun tepesinden açılır ve
  /// mikrofon düğmesinin üstünü örtmez.
  final LayerLink anchor;

  /// Oluşturma akışlarının sahibi (ana ekran ya da klasör sayfası).
  final QuickAddActions actions;

  /// Sesli not. Ana ekranın kendi TEK mikrofonu var (F3.1) — orada null;
  /// klasör sayfasında menünün birincil satırında durur.
  final VoidCallback? onVoiceCapture;

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

  void _openMenu() {
    _entry = OverlayEntry(
      builder: (context) => Stack(
        children: [
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
            followerAnchor: Alignment.bottomRight,
            offset: const Offset(0, -12),
            child: _QuickAddPanel(
              options: _options(context),
              onSelected: _select,
              onDoor: _door,
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
            child: FloatingActionButton(
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

  /// Menüdeki BÜTÜN seçenekler, kapılarıyla. Anahtar kişiselleştirmenin
  /// (`UiItem.quickAdd`) kalıcı kimliğidir. Ad/simge/kapı TEK listeden
  /// ([quickAddCatalog]) gelir — Kişiselleştir ekranı da onu okur.
  List<QuickAddOption> _options(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final a = widget.actions;
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
      'shopping': () => a.createFromTemplate(NoteTemplate.shopping),
      'template': a.createFromTemplate,
      'archive': a.createNotebook,
    };
    return [
      for (final m in quickAddCatalog(context.l10n))
        if (actions[m.key] case final action?)
          QuickAddOption(
            m.key,
            m.group,
            m.icon,
            m.label,
            action,
            _doorColor(scheme, m.group),
          ),
    ];
  }

  void _select(VoidCallback action) {
    _close();
    action();
  }

  /// Kapının levhası FAB'ın bağlamından açılır: panel bir Overlay katmanı,
  /// üstünde açılan rota onun ALTINDA kalırdı.
  Future<void> _door(QuickAddGroup group) async {
    final options = _options(context);
    _close();
    final picked = await _showDoorSheet(context, group, options);
    if (picked != null && mounted) picked.action();
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
    return PopScope(
      canPop: !_open,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: GestureDetector(
        onLongPress: () {
          HapticFeedback.mediumImpact();
          if (!_open) _openMenu();
        },
        child: FloatingActionButton(
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

/// Menü seçeneğinin KAPISI (F3.2: "+" menüsü dört kapı).
enum QuickAddGroup {
  /// Metin / liste (klasörde sesli not) — doğrudan, FAB'ın hemen üstünde.
  primary,

  /// Kamera: fotoğraf, video, belge tarama, QR.
  capture,

  /// Dosya ekle: tek seçici (tür dosyadan), YouTube bağlantısı.
  files,

  /// Şablon: şablonlar, alışveriş listesi, sıralı liste, el yazısı, defter.
  more,
}

/// Kapının levhası; seçilen seçenek döner. İçinde tek seçenek kaldıysa
/// (kişiselleştirme) levhasız o döner.
Future<QuickAddOption?> _showDoorSheet(
  BuildContext context,
  QuickAddGroup group,
  List<QuickAddOption> all,
) async {
  final l10n = context.l10n;
  final editing = Personalize.editing;
  final prefs = Personalize.current;
  final visible = [
    for (final o in all)
      if (o.group == group && (editing || prefs.shows(UiItem.quickAdd(o.key))))
        o,
  ];
  if (visible.isEmpty) return null;
  if (visible.length == 1 && !editing) return visible.first;
  final door = _doorOf(l10n, group);
  return showAppSheet<QuickAddOption>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              door.label,
              style: Theme.of(sheetContext).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                const gap = 8.0;
                final columns = visible.length <= 2 ? visible.length : 3;
                final cell =
                    (constraints.maxWidth - gap * (columns - 1)) / columns;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final o in visible)
                      SizedBox(
                        width: cell,
                        height: 84,
                        child: Customizable(
                          id: UiItem.quickAdd(o.key),
                          badgeInset: 6,
                          child: _PanelButton(
                            key: ValueKey('quick-add-${o.key}'),
                            icon: o.icon,
                            label: o.label,
                            accent: o.color,
                            onTap: () => Navigator.pop(sheetContext, o),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}

Color _doorColor(ColorScheme scheme, QuickAddGroup group) => switch (group) {
  QuickAddGroup.capture => scheme.tertiary,
  QuickAddGroup.files => scheme.secondary,
  QuickAddGroup.primary || QuickAddGroup.more => scheme.primary,
};

/// Menüdeki tek seçenek. [key] kalıcı kimlik (kişiselleştirme).
@immutable
class QuickAddOption {
  const QuickAddOption(
    this.key,
    this.group,
    this.icon,
    this.label,
    this.action,
    this.color,
  );

  final String key;
  final QuickAddGroup group;
  final IconData icon;
  final String label;
  final VoidCallback action;
  final Color color;
}

/// Menü seçeneğinin eylemsiz tanımı (bkz. [quickAddCatalog]).
typedef QuickAddMeta = ({
  String key,
  QuickAddGroup group,
  IconData icon,
  String label,
});

/// "+" menüsünün BÜTÜN seçenekleri, kapı ve sıra hâlinde (platformda
/// olmayanlar — belge tarama, QR — hariç). Panel eylemleri bu kimliklere
/// bağlar; Kişiselleştir ekranı aynı listeden gizle/göster seçicisi kurar.
List<QuickAddMeta> quickAddCatalog(AppLocalizations l10n) => [
  (
    key: 'text',
    group: QuickAddGroup.primary,
    icon: Icons.notes,
    label: l10n.newTextNote,
  ),
  (
    key: 'checklist',
    group: QuickAddGroup.primary,
    icon: Icons.check_box_outlined,
    label: l10n.newChecklist,
  ),
  (
    key: 'voice',
    group: QuickAddGroup.primary,
    icon: Icons.graphic_eq,
    label: l10n.newVoiceCapture,
  ),
  (
    key: 'photo',
    group: QuickAddGroup.capture,
    icon: Icons.photo_camera_outlined,
    label: l10n.newPhotoNote,
  ),
  (
    key: 'video',
    group: QuickAddGroup.capture,
    icon: Icons.videocam_outlined,
    label: l10n.newVideoNote,
  ),
  if (DocumentScan.available)
    (
      key: 'scan',
      group: QuickAddGroup.capture,
      icon: Icons.document_scanner_outlined,
      label: l10n.newScanNote,
    ),
  if (qrScanSupported)
    (
      key: 'qr',
      group: QuickAddGroup.capture,
      icon: Icons.qr_code_scanner,
      label: l10n.qrScanTitle,
    ),
  (
    key: 'file',
    group: QuickAddGroup.files,
    icon: Icons.upload_file_outlined,
    label: l10n.quickAddFromDevice,
  ),
  (
    key: 'youtube',
    group: QuickAddGroup.files,
    icon: Icons.smart_display_outlined,
    label: l10n.quickAddYouTube,
  ),
  (
    key: 'template',
    group: QuickAddGroup.more,
    icon: Icons.dashboard_customize_outlined,
    label: l10n.fromTemplate,
  ),
  (
    key: 'shopping',
    group: QuickAddGroup.more,
    icon: Icons.shopping_cart_outlined,
    label: l10n.tplShoppingName,
  ),
  (
    key: 'ordered',
    group: QuickAddGroup.more,
    icon: Icons.format_list_numbered_rounded,
    label: l10n.newOrderedList,
  ),
  (
    key: 'draw',
    group: QuickAddGroup.more,
    icon: Icons.draw_outlined,
    label: l10n.newHandwriting,
  ),
  (
    key: 'archive',
    group: QuickAddGroup.more,
    icon: Icons.inventory_2_outlined,
    label: l10n.archiveNotebook,
  ),
];

/// Kapının menüdeki adı ve simgesi.
({IconData icon, String label}) _doorOf(
  AppLocalizations l10n,
  QuickAddGroup group,
) => switch (group) {
  QuickAddGroup.capture => (
    icon: Icons.photo_camera_outlined,
    label: l10n.quickAddCamera,
  ),
  QuickAddGroup.files => (icon: Icons.attach_file, label: l10n.quickAddFile),
  QuickAddGroup.more => (
    icon: Icons.dashboard_customize_outlined,
    label: l10n.quickAddTemplates,
  ),
  QuickAddGroup.primary => (icon: Icons.add, label: ''),
};

/// Yeni not paneli — DÖRT KAPI (F3.2; eskiden 19 giriş, "Tümü" ızgarası ve
/// sık kullanılanlar satırı vardı). Aşağıdan yukarı, başparmağın olduğu
/// yerden okunur:
///  1. En altta, FAB'ın hemen üstünde büyük düğmeler: Metin · Liste.
///  2. Onun üstünde üç kapı: Kamera · Dosya ekle · Şablon. Kapı, içindeki
///     seçenekleri küçük bir levhada açar; içinde tek seçenek kaldıysa
///     (kişiselleştirme) levhasız doğrudan çalışır.
class _QuickAddPanel extends StatefulWidget {
  const _QuickAddPanel({
    required this.options,
    required this.onSelected,
    required this.onDoor,
  });

  final List<QuickAddOption> options;

  /// Seçilen işlemi paneli kapatarak çalıştırır.
  final void Function(VoidCallback action) onSelected;

  /// Kapıya dokunuldu: panel kapanır, kapının levhası açılır.
  final void Function(QuickAddGroup group) onDoor;

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

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    // Kişiselleştirme (gizlenen seçenekler) ve düzenleme modu: panel açıkken
    // değişirse hemen yansır.
    listenable: Personalize.listenable,
    builder: (context, _) => _build(context),
  );

  Widget _build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final size = MediaQuery.sizeOf(context);
    final width = math.min(380.0, size.width - 24);
    const gap = 6.0;

    // Gizlenen seçenek panelde yer kaplamaz; DÜZENLEME MODUNDA hepsi
    // görünür (gizliler soluk) ve dokunmak gizle/göster yapar.
    final editing = Personalize.editing;
    final prefs = Personalize.current;
    bool shown(QuickAddOption o) =>
        editing || prefs.shows(UiItem.quickAdd(o.key));
    final primary = [
      for (final o in widget.options)
        if (o.group == QuickAddGroup.primary && shown(o)) o,
    ];
    final doors = [
      for (final g in const [
        QuickAddGroup.capture,
        QuickAddGroup.files,
        QuickAddGroup.more,
      ])
        if (widget.options.any((o) => o.group == g && shown(o))) g,
    ];

    final panel = Material(
      color: scheme.surface,
      elevation: 8,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (doors.isNotEmpty)
              Row(
                children: [
                  for (var i = 0; i < doors.length; i++) ...[
                    if (i > 0) const SizedBox(width: gap),
                    Expanded(
                      child: SizedBox(
                        height: 64,
                        child: _PanelButton(
                          key: ValueKey('quick-door-${doors[i].name}'),
                          icon: _doorOf(l10n, doors[i]).icon,
                          label: _doorOf(l10n, doors[i]).label,
                          accent: _doorColor(scheme, doors[i]),
                          onTap: () => widget.onDoor(doors[i]),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            if (doors.isNotEmpty && primary.isNotEmpty)
              const SizedBox(height: 8),
            // BİRİNCİL: büyük, dolgulu, FAB'ın hemen üstünde.
            Row(
              children: [
                for (var i = 0; i < primary.length; i++) ...[
                  if (i > 0) const SizedBox(width: gap),
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
    );

    final sized = SizedBox(width: width, child: panel);
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

/// Panel hücresi: üstte simge, altında etiket. Tonal zemin dokunulabilir
/// olduğunu belli eder (düz metin düğmeler "başlık" gibi okunuyordu).
class _PanelButton extends StatelessWidget {
  const _PanelButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.accent,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Simge yuvarlağının rengi (bölümün rengi).
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 3, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: (accent ?? scheme.onSurfaceVariant).withValues(
                    alpha: 0.14,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: accent ?? scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 5),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSecondaryContainer,
                    height: 1.1,
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
