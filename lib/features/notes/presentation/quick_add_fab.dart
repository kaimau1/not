import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/l10n_ext.dart';
import '../../settings/settings_providers.dart';
import '../data/document_scan.dart';
import '../domain/note_type.dart';
import 'qr_scan_screen.dart';

/// "+" düğmesi: dokununca yeni not tipleri ÜÇ SÜTUNLU büyük düğme panelinde
/// belirir (metin / liste / sıralı liste / el yazısı / sesli / görüntülü /
/// fotoğraf / belge tarama / QR). Basılı tutmak da aynı paneli açar.
///
/// Panel neden böyle: seçenekler eskiden sağ kenara dizilmiş, her biri
/// ayrı bir baloncuk etiketi taşıyan mini FAB'lardı. Sekiz seçenek ekranın
/// tamamı boyunca uzayıp dağınık görünüyor, dokunma hedefleri küçük kalıyor ve
/// etiketler notların üzerine biniyordu. Izgara hepsini tek bir toparlanmış
/// kartta, iri ve okunur düğmeler hâlinde toplar.
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
    required this.onCreate,
    required this.onHandwriting,
    required this.onVoiceCapture,
    required this.onVideoNote,
    required this.onPhotoNote,
    required this.onScanNote,
    required this.onPdfNote,
    required this.onImageNote,
    required this.onSlidesNote,
    required this.onQrNote,
    this.onGalleryVideo,
    this.onYouTube,
    this.onTemplate,
    this.onShopping,
  });

  /// Galerideki bir videodan not (kamera değil — var olan video).
  final VoidCallback? onGalleryVideo;

  /// YouTube bağlantısından not: video notun üstüne sabitli açılır.
  final VoidCallback? onYouTube;

  /// Şablon levhasını açar (bkz. `QuickAddActions.createFromTemplate`).
  final VoidCallback? onTemplate;

  /// Doğrudan "Alışveriş listesi" şablonu — en sık istenen mod tek dokunuşta.
  final VoidCallback? onShopping;

  /// Menünün demirlendiği nokta. Dashboard bunu mikrofon + "+" sütununun
  /// TAMAMINI saracak şekilde verir; menü sütunun tepesinden açılır ve
  /// mikrofon düğmesinin üstünü örtmez.
  final LayerLink anchor;

  final void Function(NoteType type) onCreate;
  final VoidCallback onHandwriting;

  /// Keep tarzı sesli not: ses kaydı + canlı döküm birlikte.
  final VoidCallback onVoiceCapture;

  /// Görüntülü not: kamera açılır, video yalnızca cihazda saklanır.
  final VoidCallback onVideoNote;

  /// "Foto çek not al": kamera açılır, çekilen fotoğraf yeni notun içine
  /// gömülür ve editör yazmaya hazır açılır.
  final VoidCallback onPhotoNote;

  /// "Belge tara not al": belge tarayıcı açılır (kenar tespiti + perspektif
  /// düzeltme), düzeltilmiş sayfalar yeni notun içine girer.
  final VoidCallback onScanNote;

  /// "PDF ekle not al": dosya seçici açılır, seçilen PDF yeni notun içine
  /// gömülür ve sayfa başına not tutulan iki bölmeli ekran açılır.
  final VoidCallback onPdfNote;

  /// "Görsel ekle not al": seçilen görseller TEK BELGEYE dizilir ve PDF
  /// notunun aynısı açılır — üstte görsel, altta o görselin notu; üzerine
  /// balon, vurgu, ok ve el yazısı konabilir (kullanıcı isteği 2026-08-08:
  /// "PDF not al modu güzel, aynı şekilde görsel notu modu yapalım").
  final VoidCallback onImageNote;

  /// "Sunum ekle not al": PDF yolunun slayt eşi (üstte slayt, altta o slaydın
  /// notu).
  final VoidCallback onSlidesNote;

  /// QR kod okuyup içeriğini yeni nota yazar.
  final VoidCallback onQrNote;

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

  /// Menüdeki BÜTÜN seçenekler, gruplarıyla. Anahtar kullanım sayacının
  /// (bkz. [_QuickAddPanel] — sık kullanılanlar) kalıcı kimliğidir.
  List<QuickAddOption> _options(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return [
      // YAZ — en sık kullanılanlar; FAB'ın HEMEN ÜSTÜNDE büyük düğmeler.
      QuickAddOption(
        'text',
        QuickAddGroup.primary,
        Icons.notes,
        l10n.newTextNote,
        () => widget.onCreate(NoteType.text),
        scheme.primary,
      ),
      QuickAddOption(
        'checklist',
        QuickAddGroup.primary,
        Icons.check_box_outlined,
        l10n.newChecklist,
        () => widget.onCreate(NoteType.checklist),
        scheme.primary,
      ),
      QuickAddOption(
        'ordered',
        QuickAddGroup.primary,
        Icons.format_list_numbered_rounded,
        l10n.newOrderedList,
        () => widget.onCreate(NoteType.ordered),
        scheme.primary,
      ),
      // ÇEK VE KAYDET — kamera, mikrofon, kalem.
      QuickAddOption(
        'voice',
        QuickAddGroup.capture,
        Icons.graphic_eq,
        l10n.newVoiceCapture,
        widget.onVoiceCapture,
        scheme.tertiary,
      ),
      QuickAddOption(
        'photo',
        QuickAddGroup.capture,
        Icons.photo_camera_outlined,
        l10n.newPhotoNote,
        widget.onPhotoNote,
        scheme.tertiary,
      ),
      QuickAddOption(
        'video',
        QuickAddGroup.capture,
        Icons.videocam_outlined,
        l10n.newVideoNote,
        widget.onVideoNote,
        scheme.tertiary,
      ),
      if (DocumentScan.available)
        QuickAddOption(
          'scan',
          QuickAddGroup.capture,
          Icons.document_scanner_outlined,
          l10n.newScanNote,
          widget.onScanNote,
          scheme.tertiary,
        ),
      QuickAddOption(
        'draw',
        QuickAddGroup.capture,
        Icons.draw_outlined,
        l10n.newHandwriting,
        widget.onHandwriting,
        scheme.tertiary,
      ),
      if (qrScanSupported)
        QuickAddOption(
          'qr',
          QuickAddGroup.capture,
          Icons.qr_code_scanner,
          l10n.qrScanTitle,
          widget.onQrNote,
          scheme.tertiary,
        ),
      // DOSYADAN — cihazdaki/web'deki içerik.
      QuickAddOption(
        'image',
        QuickAddGroup.files,
        Icons.photo_library_outlined,
        l10n.quickAddImage,
        widget.onImageNote,
        scheme.secondary,
      ),
      QuickAddOption(
        'pdf',
        QuickAddGroup.files,
        Icons.picture_as_pdf_outlined,
        l10n.quickAddPdf,
        widget.onPdfNote,
        scheme.secondary,
      ),
      QuickAddOption(
        'slides',
        QuickAddGroup.files,
        Icons.slideshow_outlined,
        l10n.quickAddSlides,
        widget.onSlidesNote,
        scheme.secondary,
      ),
      if (widget.onGalleryVideo case final onGalleryVideo?)
        QuickAddOption(
          'gvideo',
          QuickAddGroup.files,
          Icons.video_library_outlined,
          l10n.quickAddGalleryVideo,
          onGalleryVideo,
          scheme.secondary,
        ),
      if (widget.onYouTube case final onYouTube?)
        QuickAddOption(
          'youtube',
          QuickAddGroup.files,
          Icons.smart_display_outlined,
          l10n.quickAddYouTube,
          onYouTube,
          scheme.secondary,
        ),
      // DİĞER YAZ — şablonlar ve defter.
      if (widget.onShopping case final onShopping?)
        QuickAddOption(
          'shopping',
          QuickAddGroup.more,
          Icons.shopping_cart_outlined,
          l10n.tplShoppingName,
          onShopping,
          scheme.primary,
        ),
      if (widget.onTemplate case final onTemplate?)
        QuickAddOption(
          'template',
          QuickAddGroup.more,
          Icons.dashboard_customize_outlined,
          l10n.fromTemplate,
          onTemplate,
          scheme.primary,
        ),
      QuickAddOption(
        'archive',
        QuickAddGroup.more,
        Icons.inventory_2_outlined,
        l10n.archiveNotebook,
        () => widget.onCreate(NoteType.archive),
        scheme.primary,
      ),
    ];
  }

  void _select(VoidCallback action) {
    _close();
    action();
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
            duration: const Duration(milliseconds: 160),
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

/// Menü seçeneğinin grubu.
enum QuickAddGroup {
  /// Metin / liste / sıralı liste — FAB'ın hemen üstünde büyük düğmeler.
  primary,

  /// Kamera, mikrofon, kalem.
  capture,

  /// Dosyadan (görsel, PDF, sunum, video, YouTube).
  files,

  /// Şablonlar ve defter.
  more,
}

/// Menüdeki tek seçenek. [key] kalıcı kimlik (kullanım sayacı).
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

/// Sık kullanılanlar satırının seçimi (saf, test edilir): birincil olmayan
/// seçenekler kullanım sayısına göre; eşitlikte menüdeki sırayla.
List<QuickAddOption> frequentQuickAdd(
  List<QuickAddOption> options,
  Map<String, int> usage, {
  int count = 4,
}) {
  final candidates = [
    for (final o in options)
      if (o.group != QuickAddGroup.primary) o,
  ];
  final order = {for (var i = 0; i < candidates.length; i++) candidates[i]: i};
  candidates.sort((a, b) {
    final byUse = (usage[b.key] ?? 0).compareTo(usage[a.key] ?? 0);
    return byUse != 0 ? byUse : order[a]!.compareTo(order[b]!);
  });
  return candidates.take(count).toList();
}

/// Yeni not paneli.
///
/// YENİDEN DÜZEN (kullanıcı bulgusu 2026-10-15: "not ekle menüsü neredeyse
/// tüm ekranı kaplıyor; en çok kullanılan metin notu, liste notu çok yukarıda
/// kalıyor, bulması ve başlatması çok zor"). Panel YUKARIDAN aşağı değil,
/// AŞAĞIDAN yukarı okunur — başparmağın olduğu yerden:
///  1. En altta, FAB'ın hemen üstünde BÜYÜK üç düğme: Metin · Liste · Sıralı.
///  2. Onun üstünde SIK KULLANDIKLARIN: en çok seçilen üç işlem (sayaç
///     cihazda tutulur; ilk gün Sesli not, Fotoğraf, Video çek) ve "Tümü"
///     düğmesi.
///  3. "Tümü" açılınca geri kalanlar üstte, gruplarıyla (Çek ve kaydet ·
///     Dosyadan · Şablon ve defter) belirir.
/// Kapalı hâli ~190 dp: ekranın dörtte biri (eskiden ~%70'i).
class _QuickAddPanel extends StatefulWidget {
  const _QuickAddPanel({required this.options, required this.onSelected});

  final List<QuickAddOption> options;

  /// Seçilen işlemi paneli kapatarak çalıştırır.
  final void Function(VoidCallback action) onSelected;

  @override
  State<_QuickAddPanel> createState() => _QuickAddPanelState();
}

class _QuickAddPanelState extends State<_QuickAddPanel>
    with SingleTickerProviderStateMixin {
  static const _usageKey = 'quick_add_usage';

  /// "Tümü" açık mı — oturum boyunca hatırlanır (her açılışta yeniden
  /// açtırmasın).
  static bool _expandedMemory = false;

  late bool _expanded = _expandedMemory;
  Map<String, int> _usage = const {};
  SharedPreferences? _prefs;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  )..forward();

  @override
  void initState() {
    super.initState();
    try {
      _prefs = ProviderScope.containerOf(
        context,
        listen: false,
      ).read(sharedPreferencesProvider);
      final raw = _prefs?.getString(_usageKey);
      if (raw != null) {
        _usage = {
          for (final e in (jsonDecode(raw) as Map<String, dynamic>).entries)
            e.key: (e.value as num).toInt(),
        };
      }
    } catch (_) {
      // Sağlayıcısız ağaç (testler) ya da bozuk kayıt: varsayılan sıra.
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _pick(QuickAddOption option) {
    final next = {..._usage, option.key: (_usage[option.key] ?? 0) + 1};
    try {
      _prefs?.setString(_usageKey, jsonEncode(next));
    } catch (_) {}
    widget.onSelected(option.action);
  }

  void _toggleExpanded() {
    setState(() => _expanded = !_expanded);
    _expandedMemory = _expanded;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final size = MediaQuery.sizeOf(context);
    final width = math.min(380.0, size.width - 24);
    const gap = 6.0;
    const columns = 4;
    final cell = (width - 20 - gap * (columns - 1)) / columns;

    final primary = [
      for (final o in widget.options)
        if (o.group == QuickAddGroup.primary) o,
    ];
    final frequent = frequentQuickAdd(widget.options, _usage, count: 3);

    Widget grid(List<QuickAddOption> items) => Wrap(
      spacing: gap,
      runSpacing: gap,
      children: [
        for (final o in items)
          SizedBox(
            width: cell,
            height: 64,
            child: _PanelButton(
              key: ValueKey('quick-add-${o.key}'),
              icon: o.icon,
              label: o.label,
              accent: o.color,
              onTap: () => _pick(o),
            ),
          ),
      ],
    );

    List<QuickAddOption> group(QuickAddGroup g) => [
      for (final o in widget.options)
        if (o.group == g) o,
    ];

    final expandedPart = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(l10n.quickAddCapture, color: scheme.tertiary),
        grid(group(QuickAddGroup.capture)),
        _SectionLabel(l10n.quickAddImport, color: scheme.secondary),
        grid(group(QuickAddGroup.files)),
        _SectionLabel(l10n.quickAddMore, color: scheme.primary),
        grid(group(QuickAddGroup.more)),
        const SizedBox(height: 6),
        Divider(height: 1, color: scheme.outlineVariant),
        const SizedBox(height: 4),
      ],
    );

    final panel = Material(
      color: scheme.surface,
      elevation: 8,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: size.height * 0.72),
        child: SingleChildScrollView(
          // TERS: içerik taşarsa kaydırma ALTTAN başlar — birincil düğmeler
          // her zaman FAB'ın yanında görünür kalır.
          reverse: true,
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedSize(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                alignment: Alignment.bottomCenter,
                child: _expanded
                    ? expandedPart
                    : const SizedBox(width: double.infinity),
              ),
              _SectionLabel(l10n.quickAddFrequent, color: scheme.outline),
              Row(
                children: [
                  for (final o in frequent) ...[
                    SizedBox(
                      width: cell,
                      height: 64,
                      child: _PanelButton(
                        key: ValueKey('quick-frequent-${o.key}'),
                        icon: o.icon,
                        label: o.label,
                        accent: o.color,
                        onTap: () => _pick(o),
                      ),
                    ),
                    const SizedBox(width: gap),
                  ],
                  SizedBox(
                    width: cell,
                    height: 64,
                    child: _PanelButton(
                      key: const ValueKey('quick-add-more'),
                      icon: _expanded ? Icons.expand_more : Icons.apps,
                      label: _expanded ? l10n.quickAddLess : l10n.quickAddAll,
                      accent: scheme.onSurfaceVariant,
                      onTap: _toggleExpanded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // BİRİNCİL: büyük, dolgulu, FAB'ın hemen üstünde.
              Row(
                children: [
                  for (var i = 0; i < primary.length; i++) ...[
                    if (i > 0) const SizedBox(width: gap),
                    Expanded(
                      child: _PrimaryButton(
                        key: ValueKey('quick-add-${primary[i].key}'),
                        option: primary[i],
                        onTap: () => _pick(primary[i]),
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

    final sized = SizedBox(width: width, child: panel);
    if (MediaQuery.disableAnimationsOf(context)) return sized;
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    return FadeTransition(
      opacity: curve,
      child: AnimatedBuilder(
        animation: curve,
        child: sized,
        builder: (context, inner) => Transform.scale(
          scale: 0.9 + 0.1 * curve.value,
          alignment: Alignment.bottomRight,
          child: inner,
        ),
      ),
    );
  }
}

/// Birincil düğme (Metin / Liste / Sıralı): dolgulu, büyük, simge + yazı yan
/// yana değil ÜST ÜSTE — dar ekranda üçü yan yana sığsın.
class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({super.key, required this.option, required this.onTap});

  final QuickAddOption option;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
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
    );
  }
}

/// Panel bölüm başlığı (YAZ / ÇEK VE KAYDET / DOSYADAN).
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {this.color});

  final String text;

  /// Bölümün rengi — hücre simgeleriyle aynı (yaz = birincil, çek =
  /// üçüncül, dosyadan = ikincil): bölümler okunmadan da ayırt edilsin.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 12,
            decoration: BoxDecoration(
              color: color ?? muted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: muted,
              ),
            ),
          ),
        ],
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
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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
                    height: 1.15,
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
