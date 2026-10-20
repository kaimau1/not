import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pasteboard/pasteboard.dart';

import '../../../../core/l10n_ext.dart';
import '../../../../core/widgets/undo_snackbar.dart';
import '../../../ai/data/gemini_service.dart';
import '../../../../core/widgets/app_sheet.dart';

/// Seçilen alan yakalandıktan sonra çıkan levha: **panoya kopyala** ya da
/// **yapay zekâya sor** (kullanıcı seçimi).
///
/// Levha yakalanan görüntünün önizlemesiyle açılır: yanlış yeri seçen
/// kullanıcı, işlemi yapmadan önce görür ve kapatıp yeniden seçer.
Future<void> showAreaActions(BuildContext context, Uint8List png) =>
    showAppSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) => _AreaActionsSheet(png: png),
    );

class _AreaActionsSheet extends StatelessWidget {
  const _AreaActionsSheet({required this.png});

  final Uint8List png;

  Future<void> _copy(BuildContext context) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    var ok = true;
    try {
      await Pasteboard.writeImage(png);
    } catch (_) {
      // Sistem panosuna görsel yazmak her platformda yok (bkz. ek kopyalama).
      ok = false;
    }
    navigator.pop();
    messenger
      ..hideCurrentSnackBar()
      ..showMessage(ok ? l10n.areaCopied : l10n.areaCaptureFailed);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.areaAskTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: Image.memory(png, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: () => _copy(context),
              icon: const Icon(Icons.copy_outlined),
              label: Text(l10n.areaCopyImage),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () {
                // Navigator ÖNCE alınır: levha kapandıktan sonra bu
                // `context` ağaçtan kalkmış olur.
                final navigator = Navigator.of(context);
                navigator.pop();
                navigator.push(
                  MaterialPageRoute<void>(
                    builder: (_) => AreaAskScreen(png: png),
                  ),
                );
              },
              icon: const Icon(Icons.auto_awesome),
              label: Text(l10n.areaAskAi),
            ),
          ],
        ),
      ),
    );
  }
}

/// Seçilen alanı yapay zekâya soran ekran.
///
/// Soru BOŞ bırakılabilir: varsayılan yönerge formülü/metni olduğu gibi
/// çıkarıp açıklamak ve bir problem varsa çözmek üzerine (bkz.
/// [GeminiService.askAboutImage]) — kullanıcının bu özellikten beklediği ilk
/// şey tam olarak bu.
class AreaAskScreen extends ConsumerStatefulWidget {
  const AreaAskScreen({super.key, required this.png});

  final Uint8List png;

  @override
  ConsumerState<AreaAskScreen> createState() => _AreaAskScreenState();
}

class _AreaAskScreenState extends ConsumerState<AreaAskScreen> {
  final _question = TextEditingController();
  bool _loading = false;
  String? _answer;
  String? _error;

  @override
  void dispose() {
    _question.dispose();
    super.dispose();
  }

  Future<void> _ask() async {
    setState(() {
      _loading = true;
      _answer = null;
      _error = null;
    });
    try {
      final service = ref.read(geminiServiceProvider);
      final text = await service.askAboutImage(
        widget.png,
        'image/png',
        question: _question.text,
      );
      if (mounted) setState(() => _answer = text.trim());
    } on GeminiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.areaAskTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: Image.memory(widget.png, fit: BoxFit.contain),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _question,
            minLines: 1,
            maxLines: 3,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _loading ? null : _ask(),
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: l10n.ask,
              helperText: l10n.areaAskHint,
              helperMaxLines: 3,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _loading ? null : _ask,
            icon: const Icon(Icons.auto_awesome),
            label: Text(l10n.areaAskRun),
          ),
          const SizedBox(height: 16),
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (_error != null)
            Text(
              _error!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          if (_answer != null) ...[
            SelectableText(_answer!, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () => _copyAnswer(_answer!),
                icon: const Icon(Icons.copy_outlined),
                label: Text(l10n.copy),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _copyAnswer(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showMessage(context.l10n.copied);
  }
}
