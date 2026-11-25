import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/sheet_header.dart';
import '../../notes/data/scan/scan_ocr.dart';
import '../../notes/domain/note_item.dart';
import '../data/receipt_ocr_parser.dart';
import '../domain/shop_aisles.dart';
import 'shop_budget_bar.dart';

@immutable
class ShopReceiptApplyResult {
  const ShopReceiptApplyResult({required this.storeId, required this.matches});

  final String storeId;
  final List<ReceiptItemMatch> matches;
}

/// Fiş fotoğrafından cihaz içi ML Kit OCR ile liste ürünlerinin fiyatını
/// tek dokunuşla güncelleme levhası ($0 AI maliyeti).
Future<ShopReceiptApplyResult?> showShopReceiptSheet(
  BuildContext context, {
  required List<NoteItem> items,
  Future<String> Function(String path)? ocrRunner,
}) => showAppSheet<ShopReceiptApplyResult>(
  context: context,
  isScrollControlled: true,
  builder: (_) => _ShopReceiptSheet(
    items: items,
    ocrRunner: ocrRunner ?? ScanOcr.recognizeImageText,
  ),
);

class _ShopReceiptSheet extends StatefulWidget {
  const _ShopReceiptSheet({required this.items, required this.ocrRunner});

  final List<NoteItem> items;
  final Future<String> Function(String path) ocrRunner;

  @override
  State<_ShopReceiptSheet> createState() => _ShopReceiptSheetState();
}

class _ShopReceiptSheetState extends State<_ShopReceiptSheet> {
  final _picker = ImagePicker();
  bool _scanning = false;
  ReceiptParseResult? _parsed;
  List<ReceiptItemMatch> _matches = const [];
  List<bool> _selected = const [];
  String _storeId = '';

  Future<void> _pickAndScan(ImageSource source) async {
    final file = await _picker.pickImage(source: source, imageQuality: 90);
    if (file == null || !mounted) return;
    setState(() => _scanning = true);
    try {
      final text = await widget.ocrRunner(file.path);
      if (!mounted) return;
      final parsed = parseTurkishReceipt(text);
      final matches = matchReceiptToList(parsed.lines, widget.items);
      setState(() {
        _parsed = parsed;
        _matches = matches;
        _selected = List<bool>.filled(matches.length, true);
        _storeId = parsed.storeId;
        _scanning = false;
      });
    } catch (_) {
      if (mounted) setState(() => _scanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = AppText.of(theme);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.78,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(title: l10n.shopReceiptTitle),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.l,
              0,
              AppSpace.l,
              AppSpace.m,
            ),
            child: Wrap(
              spacing: AppSpace.s,
              runSpacing: AppSpace.s,
              children: [
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: Text(l10n.shopReceiptCamera),
                  onPressed: _scanning
                      ? null
                      : () => _pickAndScan(ImageSource.camera),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(l10n.shopReceiptGallery),
                  onPressed: _scanning
                      ? null
                      : () => _pickAndScan(ImageSource.gallery),
                ),
              ],
            ),
          ),
          if (_scanning)
            const Padding(
              padding: EdgeInsets.all(AppSpace.xl),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_parsed != null) ...[
            if (_storeId.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.l),
                child: Text(
                  '${l10n.shopStoreLabel}: ${shopStoreLabel(_storeId)} · ${l10n.shopReceiptMatched(_matches.length)}',
                  style: text.section,
                ),
              ),
            if (_matches.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSpace.l),
                child: Text(
                  l10n.shopReceiptNoMatches,
                  style: text.body.copyWith(color: scheme.onSurfaceVariant),
                ),
              )
            else ...[
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _matches.length,
                  itemBuilder: (_, i) {
                    final m = _matches[i];
                    return CheckboxListTile(
                      value: _selected[i],
                      title: Text(m.itemText, style: text.rowTitle),
                      subtitle: Text(
                        '${m.receiptLine.rawName} → ${ShopBudgetBar.formatTl(m.receiptLine.price)} ₺',
                        style: text.meta,
                      ),
                      onChanged: (v) =>
                          setState(() => _selected[i] = v ?? true),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.l,
                  AppSpace.s,
                  AppSpace.l,
                  AppSpace.l,
                ),
                child: FilledButton(
                  key: const ValueKey('shop-receipt-apply'),
                  onPressed: () {
                    final chosen = [
                      for (var i = 0; i < _matches.length; i++)
                        if (_selected[i]) _matches[i],
                    ];
                    Navigator.pop(
                      context,
                      ShopReceiptApplyResult(
                        storeId: _storeId,
                        matches: chosen,
                      ),
                    );
                  },
                  child: Text(l10n.shopReceiptApply),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
