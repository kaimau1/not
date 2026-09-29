import 'package:flutter/material.dart';

import '../../../core/l10n_ext.dart';

/// Bir İÇERİKTEN (fotoğraf, tarama, video, görsel, PDF, sunum) not alırken
/// notun hangi biçimde açılacağı.
enum CaptureMode {
  /// **Balonlu**: içerik bir BELGE sayfasına dönüşür; üstte sayfa, altta o
  /// sayfanın notu. Sayfanın üzerine balon bırakılır, metin vurgulanır, kalemle
  /// yazılır. (PDF/sunum notunun düzeni.)
  bubbles,

  /// **Klasik**: sıradan bir metin notu; içerik notun içine ek olarak girer.
  classic,
}

/// Levhadan dönen seçim: hangi kip ve (isteğe bağlı) notun adı.
@immutable
class CaptureChoice {
  const CaptureChoice({required this.mode, required this.noteTitle});

  final CaptureMode mode;

  /// Kullanıcının yazdığı başlık; boş olabilir.
  final String noteTitle;
}

/// Not tipi seçildiğinde çıkan İKİ SEÇENEKLİ levha — her seçeneğin küçük bir
/// ÖRNEK ÖNİZLEMESİ var (kullanıcı isteği 2026-08-09: "bu tür not seçenekleri
/// seçildiğinde 2 seçenek çıkmalı ve örnek ön izlemeleri olmalı; 1.si yeni
/// balonlu tip, 2.si eski usul — hepsi için, slayt ve PDF içinde geçerli").
///
/// Önizlemeler ÇİZİLİR (varlık dosyası yok): tema renklerini kullandıkları
/// için açık/koyu/kağıt temada da doğru görünürler ve APK'yı büyütmezler.
///
/// **BAŞLIK ALANI** (kullanıcı isteği 2026-08-09: "balonlu notlarda notun
/// başlığı olmalı, oluşturulan yeni PDF'ye ad olarak verilmeli"): balonlu
/// kipte fotoğraflar/görseller YENİ bir PDF'e diziliyor ve o belgeye şimdiye
/// dek yakalama kipinin adı veriliyordu — ana ekran "Foto çek not al.pdf",
/// "Görsel ekle not al.pdf" diye sıralanıyor, notlar birbirinden ayırt
/// edilemiyordu. Ad artık burada, kip seçilmeden önce, tek satırda alınır:
/// hem notun başlığı hem de üretilen belgenin dosya adı olur. Boş bırakmak
/// serbest — eski davranışa (varsayılan ad) düşülür.
///
/// İptalde null döner — çağıran hiçbir şey oluşturmaz.
Future<CaptureChoice?> showCaptureModeSheet(
  BuildContext context, {
  required String title,
}) => showModalBottomSheet<CaptureChoice>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (sheetContext) => Padding(
    // Klavye açılınca levha yukarı kalkar; başlık alanı örtülmesin.
    padding: EdgeInsets.only(
      bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
    ),
    child: _CaptureModeSheet(title: title),
  ),
);

class _CaptureModeSheet extends StatefulWidget {
  const _CaptureModeSheet({required this.title});

  final String title;

  @override
  State<_CaptureModeSheet> createState() => _CaptureModeSheetState();
}

class _CaptureModeSheetState extends State<_CaptureModeSheet> {
  final _titleController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _pick(CaptureMode mode) => Navigator.pop(
    context,
    CaptureChoice(mode: mode, noteTitle: _titleController.text.trim()),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final title = widget.title;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                isDense: true,
                labelText: l10n.captureNoteTitle,
                hintText: l10n.captureNoteTitleHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              l10n.captureModeQuestion,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            CaptureModeCards(onPick: _pick),
          ],
        ),
      ),
    );
  }
}

/// Balonlu / klasik kip kartları, YAN YANA — karar tek bakışta verilsin diye
/// önizlemeler karşılaştırmalı duruyor. Hem bu levha hem de paylaşımla gelen
/// belgenin hedef levhası (bkz. `share_target_sheet.dart`) kullanır.
class CaptureModeCards extends StatelessWidget {
  const CaptureModeCards({super.key, required this.onPick});

  final ValueChanged<CaptureMode> onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _ModeCard(
            title: l10n.captureModeBubbles,
            info: l10n.captureModeBubblesInfo,
            preview: const _BubblePreview(),
            badge: l10n.captureModeNew,
            onTap: () => onPick(CaptureMode.bubbles),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ModeCard(
            title: l10n.captureModeClassic,
            info: l10n.captureModeClassicInfo,
            preview: const _ClassicPreview(),
            onTap: () => onPick(CaptureMode.classic),
          ),
        ),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.info,
    required this.preview,
    required this.onTap,
    this.badge,
  });

  final String title;
  final String info;
  final Widget preview;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final badgeText = badge;
    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Önizleme sabit oranda: iki kart aynı boyda kalsın.
              AspectRatio(
                aspectRatio: 0.86,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: preview,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (badgeText != null) ...[
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                info,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Balonlu düzenin önizlemesi: üstte belge sayfası + üzerinde iki balon ve bir
/// vurgu, altta o sayfanın not alanı.
class _BubblePreview extends StatelessWidget {
  const _BubblePreview();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CustomPaint(
      painter: _PreviewPainter(
        bubbles: true,
        ink: scheme.onSurfaceVariant,
        page: scheme.surfaceContainerHighest,
        accent: const Color(0xFFFFC107),
        highlight: const Color(0xFFEF5350),
      ),
      size: Size.infinite,
    );
  }
}

/// Klasik düzenin önizlemesi: sayfada bir görsel/ek kutusu ve altında düz
/// metin satırları.
class _ClassicPreview extends StatelessWidget {
  const _ClassicPreview();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CustomPaint(
      painter: _PreviewPainter(
        bubbles: false,
        ink: scheme.onSurfaceVariant,
        page: scheme.surfaceContainerHighest,
        accent: scheme.primary,
        highlight: scheme.primary,
      ),
      size: Size.infinite,
    );
  }
}

/// İki önizlemeyi de çizen tek boyayıcı. Ölçüler ORANSAL: kart hangi boyda
/// olursa olsun aynı görünür.
class _PreviewPainter extends CustomPainter {
  const _PreviewPainter({
    required this.bubbles,
    required this.ink,
    required this.page,
    required this.accent,
    required this.highlight,
  });

  final bool bubbles;
  final Color ink;
  final Color page;
  final Color accent;
  final Color highlight;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final line = Paint()
      ..color = ink.withValues(alpha: 0.45)
      ..strokeWidth = h * 0.018
      ..strokeCap = StrokeCap.round;

    void textLine(double y, double from, double to) =>
        canvas.drawLine(Offset(w * from, h * y), Offset(w * to, h * y), line);

    if (bubbles) {
      // Üst bölme: belge sayfası (yüksekliğin %58'i).
      final doc = Rect.fromLTWH(0, 0, w, h * 0.58);
      canvas.drawRRect(
        RRect.fromRectAndRadius(doc, Radius.circular(h * 0.03)),
        Paint()..color = page,
      );
      for (var i = 0; i < 5; i++) {
        textLine(0.10 + i * 0.085, 0.12, i.isEven ? 0.86 : 0.7);
      }
      // Vurgulu satır + ona bağlı ok (asıl ürününde de böyle).
      final hl = Rect.fromLTWH(w * 0.12, h * 0.257, w * 0.42, h * 0.05);
      canvas.drawRRect(
        RRect.fromRectAndRadius(hl, Radius.circular(h * 0.012)),
        Paint()..color = highlight.withValues(alpha: 0.3),
      );
      canvas.drawLine(
        Offset(w * 0.72, h * 0.44),
        Offset(w * 0.42, h * 0.30),
        Paint()
          ..color = highlight.withValues(alpha: 0.65)
          ..strokeWidth = h * 0.012,
      );
      // İki balon: biri kapalı tutamaç, biri küçük kart.
      canvas.drawCircle(
        Offset(w * 0.75, h * 0.45),
        h * 0.035,
        Paint()..color = highlight,
      );
      final card = Rect.fromLTWH(w * 0.5, h * 0.06, w * 0.42, h * 0.13);
      canvas.drawRRect(
        RRect.fromRectAndRadius(card, Radius.circular(h * 0.02)),
        Paint()..color = accent,
      );
      // Alt bölme: sayfanın notu.
      final notes = Rect.fromLTWH(0, h * 0.63, w, h * 0.37);
      canvas.drawRRect(
        RRect.fromRectAndRadius(notes, Radius.circular(h * 0.03)),
        Paint()..color = ink.withValues(alpha: 0.08),
      );
      for (var i = 0; i < 3; i++) {
        textLine(0.71 + i * 0.09, 0.08, i == 2 ? 0.6 : 0.9);
      }
      return;
    }

    // Klasik: sayfanın içine oturan tek bir ek kutusu + düz metin.
    final image = Rect.fromLTWH(w * 0.08, h * 0.06, w * 0.84, h * 0.4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(image, Radius.circular(h * 0.025)),
      Paint()..color = page,
    );
    // Kutunun içinde küçük bir "görsel" işareti (dağ + güneş).
    canvas.drawCircle(
      Offset(w * 0.28, h * 0.16),
      h * 0.035,
      Paint()..color = accent.withValues(alpha: 0.75),
    );
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.14, h * 0.42)
        ..lineTo(w * 0.4, h * 0.2)
        ..lineTo(w * 0.62, h * 0.42)
        ..close(),
      Paint()..color = ink.withValues(alpha: 0.35),
    );
    for (var i = 0; i < 5; i++) {
      textLine(0.56 + i * 0.09, 0.08, i.isEven ? 0.9 : 0.68);
    }
  }

  @override
  bool shouldRepaint(_PreviewPainter old) =>
      old.bubbles != bubbles ||
      old.ink != ink ||
      old.page != page ||
      old.accent != accent ||
      old.highlight != highlight;
}
