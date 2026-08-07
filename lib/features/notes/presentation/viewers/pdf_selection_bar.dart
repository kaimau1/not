import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../../core/l10n_ext.dart';
import '../../../../core/utils/pdf_copy_text.dart';
import '../../data/pdf/selection_rects.dart';
import '../../domain/attachment.dart';
import 'bubble_layer.dart';

/// PDF metin seçiminin DURUMU — tam ekran görüntüleyici ile not panosunun
/// bölmesi aynı davranışı paylaşsın diye ayrı bir denetleyici.
///
/// Neden `setState` değil `ValueNotifier`: seçim her parmak hareketinde
/// değişiyor. Ekran durumunda tutulsaydı her olayda `PdfViewerParams` ve
/// bütün sayfa katmanları yeniden kurulurdu — kullanıcının bildirdiği
/// kasmanın (2026-08-08 "bu sistem kasma sorunu oluşturmamalı") en büyük
/// kaynağı buydu. Şimdi yalnız seçim çubuğu ve pan kilidi bu değeri dinliyor.
class PdfSelectionState {
  PdfSelectionState();

  /// Seçili metin ve hangi sayfada olduğu (0 = seçim yok).
  final ValueNotifier<String> text = ValueNotifier<String>('');
  final ValueNotifier<int> page = ValueNotifier<int>(0);

  /// Sürükleyerek seçim ŞU AN sürüyor mu? True iken görüntüleyicinin pan'ı
  /// kilitlenir (sürükleme sayfayı kaydırmasın).
  final ValueNotifier<bool> selecting = ValueNotifier<bool>(false);

  /// Seçimin sayfa oranına çevrilmiş dikdörtgenleri (vurgu için hazır).
  List<PageBubbleRect> rects = const [];

  void set({
    required String value,
    required int pageNumber,
    required List<PdfRect> pdfRects,
    required PdfPage source,
  }) {
    rects = normalizedPageRects(
      pdfRects,
      pageWidth: source.width,
      pageHeight: source.height,
    );
    text.value = value;
    page.value = value.isEmpty ? 0 : pageNumber;
  }

  void clear() {
    rects = const [];
    text.value = '';
    page.value = 0;
  }

  void dispose() {
    text.dispose();
    page.dispose();
    selecting.dispose();
  }
}

/// Seçim varken sayfanın altında beliren çubuk: **Vurgula · Not ekle ·
/// Kopyala**.
///
/// "Vurgula" ve "Not ekle" aynı şeyi üretir — dikdörtgenleri taşıyan bir
/// [PageBubble] — yalnız ikincisi kartı açık getirip klavyeyi hazırlar
/// (bkz. `BubbleController.addHighlight`). Vurgu ile balonun tek veri modeli
/// olması kullanıcı isteğiydi: vurguya dokununca notu açılıyor.
class PdfSelectionBar extends StatelessWidget {
  const PdfSelectionBar({
    super.key,
    required this.selection,
    required this.bubbles,
    this.compact = false,
  });

  final PdfSelectionState selection;
  final BubbleController bubbles;

  /// Pano bölmesi gibi dar alanlarda etiketler düşer, yalnız simge kalır.
  final bool compact;

  Future<void> _copy(BuildContext context) async {
    // Ham seçim değil TEMİZ metin kopyalanır: pdfium'un satır sonları ve
    // görünmez karakterleri panoya taşınmasın.
    final text = cleanPdfCopyText(selection.text.value);
    if (text.isEmpty) return;
    final message = context.l10n.pdfSelectCopied(text.length);
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    selection.clear();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _highlight({required bool open}) {
    final page = selection.page.value;
    if (page == 0 || selection.rects.isEmpty) return;
    HapticFeedback.selectionClick();
    bubbles.addHighlight(page: page, rects: selection.rects, open: open);
    selection.clear();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String>(
    valueListenable: selection.text,
    builder: (context, text, _) {
      if (text.trim().isEmpty) return const SizedBox.shrink();
      return Center(
        child: Material(
          color: Colors.black.withValues(alpha: 0.80),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _action(
                  context,
                  icon: Icons.border_color,
                  label: context.l10n.pdfHighlight,
                  onPressed: () => _highlight(open: false),
                ),
                _action(
                  context,
                  icon: Icons.add_comment_outlined,
                  label: context.l10n.pdfHighlightWithNote,
                  onPressed: () => _highlight(open: true),
                ),
                _action(
                  context,
                  icon: Icons.copy,
                  label: context.l10n.copy,
                  onPressed: () => _copy(context),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  Widget _action(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) => compact
      ? IconButton(
          tooltip: label,
          onPressed: onPressed,
          icon: Icon(icon, color: Colors.white, size: 20),
          visualDensity: VisualDensity.compact,
        )
      : TextButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, color: Colors.white, size: 18),
          label: Text(label, style: const TextStyle(color: Colors.white)),
        );
}
