import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/l10n_ext.dart';
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
    required this.onQrNote,
  });

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
              // YAZ: boş bir not açan üç seçenek. Tam genişlik satır, çünkü
              // en sık kullanılanlar bunlar ve ızgarada üçü de aynı boyda
              // küçük kutulara dönüşüp gözde ayırt edilemiyordu.
              writeOptions: [
                (
                  Icons.notes,
                  context.l10n.newTextNote,
                  () => widget.onCreate(NoteType.text),
                ),
                (
                  Icons.check_box_outlined,
                  context.l10n.newChecklist,
                  () => widget.onCreate(NoteType.checklist),
                ),
                (
                  Icons.format_list_numbered_rounded,
                  context.l10n.newOrderedList,
                  () => widget.onCreate(NoteType.ordered),
                ),
              ],
              // YAKALA: hepsi bir İÇERİKTEN not üretir (ses, fotoğraf, tarama,
              // el yazısı, video, QR). Bölüm başlığı bunu açıkça söylüyor —
              // kullanıcı "Fotoğraflı not"un fotoğrafı nereye koyduğunu
              // denemeden anlamıyordu.
              captureOptions: [
                (
                  Icons.graphic_eq,
                  context.l10n.newVoiceCapture,
                  widget.onVoiceCapture,
                ),
                (
                  Icons.photo_camera_outlined,
                  context.l10n.newPhotoNote,
                  widget.onPhotoNote,
                ),
                if (DocumentScan.available)
                  (
                    Icons.document_scanner_outlined,
                    context.l10n.newScanNote,
                    widget.onScanNote,
                  ),
                (
                  Icons.picture_as_pdf_outlined,
                  context.l10n.newPdfNote,
                  widget.onPdfNote,
                ),
                (
                  Icons.draw_outlined,
                  context.l10n.newHandwriting,
                  widget.onHandwriting,
                ),
                (
                  Icons.videocam_outlined,
                  context.l10n.newVideoNote,
                  widget.onVideoNote,
                ),
                if (qrScanSupported)
                  (
                    Icons.qr_code_scanner,
                    context.l10n.qrScanTitle,
                    widget.onQrNote,
                  ),
              ],
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

/// Menü açıkken arka planı bulanıklaştıran tam ekran katman. Bulanıklık
/// birden bindirilmez: 180 ms'de yumuşakça girer ki sayfa "donmuş" gibi
/// görünmesin. Sistemde "hareketi azalt" açıksa anında tam bulanıklık.
class _BlurBarrier extends StatelessWidget {
  const _BlurBarrier();

  static const _sigma = 10.0;
  static const _dim = 0.18;

  @override
  Widget build(BuildContext context) {
    final animate = !MediaQuery.disableAnimationsOf(context);
    if (!animate) return _layer(1);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      builder: (context, t, _) => _layer(t),
    );
  }

  Widget _layer(double t) => BackdropFilter(
    filter: ImageFilter.blur(sigmaX: _sigma * t, sigmaY: _sigma * t),
    child: ColoredBox(color: Colors.black.withValues(alpha: _dim * t)),
  );
}

/// Yeni not tipleri paneli: üç sütunlu, iri dokunma hedefli düğme ızgarası.
///
/// Ölçüler: panel en çok 360 dp (küçük ekranda ekran genişliği - 24), her
/// hücre 84 dp yüksek — simge + iki satıra kadar etiket sığar, dokunma hedefi
/// Material'ın 48 dp alt sınırının rahat üstünde kalır.
class _QuickAddPanel extends StatefulWidget {
  const _QuickAddPanel({
    required this.writeOptions,
    required this.captureOptions,
    required this.onSelected,
  });

  /// (simge, etiket, işlem) üçlüleri — boş not açanlar.
  final List<(IconData, String, VoidCallback)> writeOptions;

  /// (simge, etiket, işlem) üçlüleri — içerikten not üretenler.
  final List<(IconData, String, VoidCallback)> captureOptions;

  /// Seçilen işlemi paneli kapatarak çalıştırır.
  final void Function(VoidCallback action) onSelected;

  @override
  State<_QuickAddPanel> createState() => _QuickAddPanelState();
}

class _QuickAddPanelState extends State<_QuickAddPanel>
    with SingleTickerProviderStateMixin {
  static const _columns = 3;
  static const _cellHeight = 64.0;
  static const _gap = 8.0;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Panel genişliği ekranla sınırlı: geniş ekranda 360 dp'de durur,
    // telefonda kenarlardan 12 dp boşluk bırakır.
    final width = math.min(360.0, MediaQuery.sizeOf(context).width - 24);
    final cellWidth = (width - 24 - _gap * (_columns - 1)) / _columns;

    final l10n = context.l10n;
    final panel = Material(
      color: scheme.surface,
      elevation: 8,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel(l10n.quickAddWrite),
            for (final (icon, label, action) in widget.writeOptions)
              _WriteRow(
                icon: icon,
                label: label,
                onTap: () => widget.onSelected(action),
              ),
            const SizedBox(height: 6),
            Divider(height: 1, color: scheme.outlineVariant),
            _SectionLabel(l10n.quickAddCapture),
            Wrap(
              spacing: _gap,
              runSpacing: _gap,
              children: [
                for (final (icon, label, action) in widget.captureOptions)
                  SizedBox(
                    width: cellWidth,
                    height: _cellHeight,
                    child: _PanelButton(
                      icon: icon,
                      label: label,
                      onTap: () => widget.onSelected(action),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );

    final sized = SizedBox(width: width, child: panel);
    // Erişilebilirlik: sistemde "hareketi azalt" açıksa animasyon yok.
    if (MediaQuery.disableAnimationsOf(context)) return sized;
    // Panel "+" düğmesinden büyüyerek açılır: ölçek + solma, sağ-alt köşeden.
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
          scale: 0.85 + 0.15 * curve.value,
          alignment: Alignment.bottomRight,
          child: inner,
        ),
      ),
    );
  }
}

/// Panel bölüm başlığı (YAZ / YAKALA…).
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}

/// YAZ bölümünün tam genişlik satırı.
class _WriteRow extends StatelessWidget {
  const _WriteRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: SizedBox(
          height: 44,
          child: Row(
            children: [
              const SizedBox(width: 4),
              Icon(icon, size: 20, color: scheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
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

/// Panel hücresi: üstte simge, altında etiket. Tonal zemin dokunulabilir
/// olduğunu belli eder (düz metin düğmeler "başlık" gibi okunuyordu).
class _PanelButton extends StatelessWidget {
  const _PanelButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

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
              Icon(icon, size: 21, color: scheme.onSurfaceVariant),
              const SizedBox(height: 6),
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
