import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/l10n_ext.dart';
import '../../../../core/widgets/undo_snackbar.dart' show showAppMessage;
import '../../data/table_export.dart';
import '../../domain/attachment.dart';
import '../../domain/note_table.dart';
import 'table_page_box.dart';

/// **TABLO TAM EKRAN** (kullanıcı isteği 2026-11-23: "görsel gibi
/// sabitlenebilir, ek olarak taşınabilir, serbest olabilir"): tablo ek
/// şeridinde (ek görünümü) ya da yazıya gömülü etiketken buradan açılır ve
/// yazılır; sayfadaki/bölmedeki tablo da ⤢ ile buraya gelir. Hücreler
/// sayfadaki kutuyla aynı ([TablePageBox]); üstte paylaş (görsel/PDF/Word).
class TableScreen extends StatefulWidget {
  const TableScreen({
    super.key,
    required this.attachment,
    required this.onChanged,
    this.onRemove,
    this.onClosed,
    this.readOnly = false,
  });

  final Attachment attachment;

  /// Tablo içeriği (editörde kök kurulmadan kaydedilir).
  final ValueChanged<Attachment> onChanged;
  final VoidCallback? onRemove;

  /// Ekran kapanınca (son yazı [onChanged]'den geçtikten SONRA): editör
  /// sayfadaki kopyayı bir kez tazeler.
  final VoidCallback? onClosed;
  final bool readOnly;

  @override
  State<TableScreen> createState() => _TableScreenState();
}

class _TableScreenState extends State<TableScreen> {
  late Attachment _latest = widget.attachment;

  @override
  void dispose() {
    widget.onClosed?.call();
    super.dispose();
  }

  Future<void> _share(TableExportKind kind) async {
    final table = NoteTable.of(_latest);
    if (table == null) return;
    final failed = context.l10n.tableShareFailed;
    try {
      await TableExport.share(table, title: _latest.fileName, kind: kind);
    } catch (_) {
      if (mounted) showAppMessage(context, failed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.attachment.fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          PopupMenuButton<TableExportKind>(
            key: const ValueKey('table-screen-share'),
            tooltip: l10n.share,
            icon: const Icon(Icons.share_outlined),
            onSelected: (kind) => unawaited(_share(kind)),
            itemBuilder: (context) => [
              for (final (kind, icon, label) in [
                (
                  TableExportKind.image,
                  Icons.image_outlined,
                  l10n.tableShareImage,
                ),
                (
                  TableExportKind.pdf,
                  Icons.picture_as_pdf_outlined,
                  l10n.tableSharePdf,
                ),
                (
                  TableExportKind.word,
                  Icons.description_outlined,
                  l10n.tableShareWord,
                ),
              ])
                PopupMenuItem(
                  value: kind,
                  child: Row(
                    children: [
                      Icon(icon),
                      const SizedBox(width: AppSpace.m),
                      Text(label),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpace.l),
          child: Center(
            child: ConstrainedBox(
              // Geniş ekranda tablo okunur ölçekte kalsın.
              constraints: const BoxConstraints(maxWidth: kTableRefWidth * 2),
              child: TablePageBox(
                attachment: widget.attachment,
                editable: !widget.readOnly,
                onChanged: (a) {
                  _latest = a;
                  widget.onChanged(a);
                },
                onRemove: widget.onRemove == null
                    ? null
                    : () {
                        widget.onRemove!();
                        Navigator.of(context).maybePop();
                      },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
