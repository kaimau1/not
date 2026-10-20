import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../../core/constants.dart';
import '../../../../core/l10n_ext.dart';
import '../../../../core/widgets/app_sheet.dart';

/// Ses kaydı alt sayfası. Kayıt biterse (path, süre) döner; iptalde null.
Future<({String path, Duration duration})?> showAudioRecorderSheet(
  BuildContext context,
) => showAppSheet<({String path, Duration duration})>(
  context: context,
  isDismissible: false,
  enableDrag: false,
  builder: (_) => const _AudioRecorderSheet(),
);

class _AudioRecorderSheet extends StatefulWidget {
  const _AudioRecorderSheet();

  @override
  State<_AudioRecorderSheet> createState() => _AudioRecorderSheetState();
}

class _AudioRecorderSheetState extends State<_AudioRecorderSheet> {
  final _recorder = AudioRecorder();
  Timer? _ticker;
  Duration _elapsed = Duration.zero;
  String? _path;
  String? _error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      if (!await _recorder.hasPermission()) {
        if (mounted) setState(() => _error = context.l10n.micPermissionDenied);
        return;
      }
      final dir = await getTemporaryDirectory();
      _path = p.join(
        dir.path,
        'kayit_${DateTime.now().millisecondsSinceEpoch}.m4a',
      );
      await _recorder.start(
        // Konuşma için 96 kbps stereo israftı (dakikada ~720 KB). Tek kanal
        // 32 kbps / 22.05 kHz ses notunda duyulur fark yaratmaz ama dosyayı
        // ~6 katı küçültür — Firebase Storage kotası ve mobil veri buna
        // gidiyordu (ölçüt: [AppConstants.audioBitRate]).
        const RecordConfig(
          bitRate: AppConstants.audioBitRate,
          sampleRate: AppConstants.audioSampleRate,
          numChannels: 1,
        ),
        path: _path!,
      );
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _elapsed += const Duration(seconds: 1));
        // Üst sınır: levha açık unutulursa mikrofon + kodlayıcı süresiz
        // çalışmasın; o ana kadarki kayıt KAYDEDİLEREK kapanır.
        if (_elapsed >= const Duration(minutes: 10)) _stop(save: true);
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  /// Yeniden giriş kilidi: geri tuşu artık _stop'a bağlı ve _stop async —
  /// hızlı iki geri basışı iki uçuşta _stop = iki Navigator.pop demekti,
  /// ikincisi ALTTAKİ editörü kapatıyordu.
  bool _stopping = false;

  Future<void> _stop({required bool save}) async {
    if (_stopping) return;
    _stopping = true;
    _ticker?.cancel();
    try {
      final path = await _recorder.stop();
      if (!mounted) return;
      if (save && path != null) {
        Navigator.pop(context, (path: path, duration: _elapsed));
      } else {
        if (path != null) File(path).delete().ignore();
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  String _format(Duration d) =>
      '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    // Sistem geri tuşu/jesti: `isDismissible: false` yalnız bariyer
    // dokunuşunu engeller, GERİ tuşu levhayı yine kapatıyordu — dakikalarca
    // süren kayıt tek yanlış jestle onaysız çöpe gidiyordu. Geri artık
    // "durdur ve KAYDET" gibi davranır: yanlışlıkla kaydedilen ek tek
    // dokunuşla silinebilir, kaybolan kayıt geri gelmez.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_error != null) {
          Navigator.pop(context);
        } else {
          _stop(save: true);
        }
      },
      child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_error != null) ...[
              Text(_error!, style: TextStyle(color: scheme.error)),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.close),
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mic, color: scheme.error),
                  const SizedBox(width: 8),
                  Text(
                    _format(_elapsed),
                    style: Theme.of(
                      context,
                    ).textTheme.headlineSmall?.copyWith(fontFeatures: const []),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                l10n.recording,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: () => _stop(save: false),
                    child: Text(l10n.cancel),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () => _stop(save: true),
                    icon: const Icon(Icons.stop),
                    label: Text(l10n.stopAndSave),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      ),
    );
  }
}
