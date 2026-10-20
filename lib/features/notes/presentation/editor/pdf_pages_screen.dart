import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../../core/l10n_ext.dart';
import '../../../../core/widgets/undo_snackbar.dart';
import '../../data/pdf_edit.dart';
import '../../domain/attachment.dart';
import '../viewers/pdf_page_image.dart';

/// PDF sayfa yöneticisi: sayfaları seç, sil, döndür, sırala.
///
/// Görüntüleme pdfrx'te kalır (küçük resimler de pdfrx çizer); DÜZENLEME
/// `PdfEdit` ile yeni bayt üretir (bkz. `data/pdf_edit.dart`). Bu ekran yalnız
/// KULLANICI PLANINI toplar ve [onApply] ile geri verir — dosya yazma, yükleme
/// ve sayfa kimliği bakımı çağıranda (editörde) yapılır.
///
/// Neden plan döndürüyor da kendisi uygulamıyor: sayfa düzeni değişince
/// `Attachment.pageIds` de yeniden yazılmalı ki sayfa notları sayfalarıyla
/// birlikte taşınsın. O bilgi notta duruyor, bu ekranda değil.
class PdfPagesScreen extends StatefulWidget {
  const PdfPagesScreen({
    super.key,
    required this.attachment,
    required this.pageCount,
    required this.onApply,
    required this.onBurnInk,
  });

  final Attachment attachment;
  final int pageCount;

  /// Kullanıcı planı onayladı. [order] KALAN sayfaların 0 tabanlı ESKİ
  /// indeksleri, yeni sırayla (silinen sayfa listede yoktur).
  /// [rotations] sayfa indeksi → uygulanacak çeyrek tur (0 = dokunma).
  final Future<void> Function(List<int> order, Map<int, int> rotations) onApply;

  /// El yazısını belgeye gömer (paylaşılan PDF'te de görünsün diye).
  final Future<void> Function() onBurnInk;

  @override
  State<PdfPagesScreen> createState() => _PdfPagesScreenState();
}

class _PdfPagesScreenState extends State<PdfPagesScreen> {
  /// Sayfaların O ANKİ sırası: eski (0 tabanlı) indeksler.
  late List<int> _order = [for (var i = 0; i < widget.pageCount; i++) i];

  /// Sayfa indeksi → biriken çeyrek tur.
  final Map<int, int> _rotations = {};

  /// Seçili sayfalar (ESKİ indeks).
  final Set<int> _selected = {};

  bool _busy = false;

  bool get _dirty =>
      _order.contains(PdfEdit.blankPage) ||
      _order.length != widget.pageCount ||
      _rotations.values.any((t) => t % 4 != 0) ||
      // Sıra değişti mi?
      [for (var i = 0; i < _order.length; i++) _order[i] != i].contains(true);

  void _toggle(int page) => setState(() {
    if (!_selected.remove(page)) _selected.add(page);
  });

  void _deleteSelected() {
    if (_selected.isEmpty) return;
    // TÜM sayfaları silmeye izin yok: sayfasız PDF geçersiz bir belgedir
    // (motor da reddeder, kullanıcıya burada söylemek daha erken ve nettir).
    if (_selected.length >= _order.length) {
      showAppMessage(context, context.l10n.pdfCannotDeleteAllPages);
      return;
    }
    setState(() {
      _order = [
        for (final i in _order)
          if (!_selected.contains(i)) i,
      ];
      _selected.clear();
    });
  }

  /// Seçili sayfadan SONRA (seçim yoksa belgenin sonuna) boş bir sayfa
  /// ekler. Kullanıcı isteği 2026-08-08: "boş sayfa ekleme olsun" — belgeye
  /// kendi notunu, çizimini, balonunu koyacağı temiz bir alan.
  void _addBlank() {
    setState(() {
      if (_selected.isEmpty) {
        _order = [..._order, PdfEdit.blankPage];
        return;
      }
      final out = <int>[];
      for (final page in _order) {
        out.add(page);
        if (_selected.contains(page)) out.add(PdfEdit.blankPage);
      }
      _order = out;
      _selected.clear();
    });
  }

  void _rotateSelected() {
    final targets = _selected.isEmpty ? _order : _selected.toList();
    setState(() {
      for (final i in targets) {
        _rotations[i] = ((_rotations[i] ?? 0) + 1) % 4;
      }
    });
  }

  /// Sayfayı KONUMUNA göre taşır.
  ///
  /// Değerine göre (`indexOf`) taşımak boş sayfalarla ÇALIŞMAZ: hepsinin
  /// değeri -1'dir ve ilk bulunanı taşınırdı.
  void _moveAt(int position, int delta) {
    final to = position + delta;
    if (to < 0 || to >= _order.length) return;
    setState(() {
      final page = _order.removeAt(position);
      _order.insert(to, page);
    });
  }

  Future<void> _apply() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.onApply(_order, Map.of(_rotations));
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _burn() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.onBurnInk();
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasInk = widget.attachment.ink.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.pdfEditPages),
        actions: [
          // Boş sayfa ve silme HER ZAMAN görünür (silme eskiden yalnız seçim
          // varken beliriyordu ve bulunamıyordu): seçim yokken sönük durur,
          // ne yapılacağı ipucundan anlaşılır.
          IconButton(
            tooltip: l10n.pdfAddBlankPage,
            onPressed: _busy ? null : _addBlank,
            icon: const Icon(Icons.note_add_outlined),
          ),
          IconButton(
            tooltip: l10n.pdfDeletePages,
            onPressed: (_busy || _selected.isEmpty) ? null : _deleteSelected,
            icon: const Icon(Icons.delete_outline),
          ),
          IconButton(
            tooltip: l10n.pdfRotatePages,
            onPressed: _busy ? null : _rotateSelected,
            icon: const Icon(Icons.rotate_90_degrees_cw_outlined),
          ),
          if (hasInk)
            IconButton(
              tooltip: l10n.pdfBurnInk,
              onPressed: _busy ? null : _burn,
              icon: const Icon(Icons.brush_outlined),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_busy) const LinearProgressIndicator(minHeight: 2),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              // Kullanıcı sayfa notlarının ne olacağını bilmeli: kimlikler
              // sayfayla taşındığı için notlar sayfasını izler, silinen
              // sayfanın notu ise kayıtta kalır ama görünmez.
              l10n.pdfPagesHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: PdfDocumentViewBuilder.file(
              widget.attachment.localPath,
              builder: (context, document) => GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate:
                    const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 160,
                      childAspectRatio: 0.62,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                    ),
                itemCount: _order.length,
                itemBuilder: (context, position) {
                  final page = _order[position];
                  final blank = page == PdfEdit.blankPage;
                  return _PageTile(
                    document: document,
                    // pdfrx 1 tabanlı sayfa numarası bekler.
                    pageNumber: blank ? 0 : page + 1,
                    blank: blank,
                    label: '${position + 1}',
                    selected: !blank && _selected.contains(page),
                    quarterTurns: blank ? 0 : (_rotations[page] ?? 0),
                    // Boş sayfa seçilemez (döndürme/silme onun için anlamsız);
                    // yerini değiştirmek için oklar yine çalışır.
                    onTap: blank ? null : () => _toggle(page),
                    onLeft: position > 0
                        ? () => _moveAt(position, -1)
                        : null,
                    onRight: position < _order.length - 1
                        ? () => _moveAt(position, 1)
                        : null,
                  );
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: FilledButton(
          onPressed: (_busy || !_dirty) ? null : _apply,
          child: Text(l10n.pdfApplyChanges),
        ),
      ),
    );
  }
}

/// Izgaradaki tek sayfa: küçük resim + sıra numarası + taşıma okları.
class _PageTile extends StatelessWidget {
  const _PageTile({
    required this.document,
    required this.pageNumber,
    required this.label,
    required this.selected,
    required this.quarterTurns,
    required this.onTap,
    required this.onLeft,
    required this.onRight,
    this.blank = false,
  });

  final PdfDocument? document;
  final int pageNumber;
  final String label;
  final bool selected;
  final int quarterTurns;

  /// Kaynakta karşılığı olmayan BOŞ sayfa: küçük resim yerine kesik çizgili
  /// bir yer tutucu çizilir.
  final bool blank;
  final VoidCallback? onTap;
  final VoidCallback? onLeft;
  final VoidCallback? onRight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: selected ? scheme.primary : scheme.outlineVariant,
                  width: selected ? 2.5 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Bekleyen döndürme küçük resimde de görünür: kullanıcı
                  // uygulamadan önce sonucu görebilmeli.
                  if (blank)
                    Center(
                      child: Icon(
                        Icons.note_add_outlined,
                        size: 28,
                        color: scheme.outline,
                      ),
                    )
                  else if (document != null)
                    RotatedBox(
                      quarterTurns: quarterTurns,
                      // PdfPageView DEĞİL: sıralama/silme sonrası aynı
                      // kutuya başka sayfa düştüğünde eski görüntüyü
                      // tutuyordu (bkz. PdfPageImage).
                      child: PdfPageImage(
                        document: document!,
                        pageNumber: pageNumber,
                        // Küçük resim: yüksek DPI hem yavaş hem gereksiz
                        // bellek.
                        maximumDpi: 72,
                      ),
                    ),
                  if (selected)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Icon(
                        Icons.check_circle,
                        size: 20,
                        color: scheme.primary,
                      ),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 30,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: context.l10n.archivePrevPage,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  onPressed: onLeft,
                  icon: const Icon(Icons.chevron_left, size: 18),
                ),
                Text(label, style: Theme.of(context).textTheme.labelSmall),
                IconButton(
                  tooltip: context.l10n.archiveNextPage,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  onPressed: onRight,
                  icon: const Icon(Icons.chevron_right, size: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
