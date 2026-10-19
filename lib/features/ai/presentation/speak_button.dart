import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/utils/speech_output.dart';
import '../data/speech_service.dart';

/// Bir metni sesli okutan düğme. Okurken duraklat/durdur olur ve ilerlemeyi
/// gösterir. Uygulamadaki her "sesli oku" noktası bunu kullanır — sesli
/// özet, belge okuma, çeviri — böylece davranış tek yerde tanımlı kalır.
/// Motor (cihaz / yapay zekâ) ayardan gelir (bkz. [SpeechService]).
class SpeakButton extends ConsumerWidget {
  const SpeakButton({super.key, required this.text, this.label});

  final String text;

  /// Boşsa yalnız ikon gösterilir (dar yerler için).
  final String? label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final speech = ref.watch(speechProvider);
    final controller = ref.read(speechProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    // Bu metin okunuyor mu ayırt edilemez (denetleyici tek metin okur), bu
    // yüzden etkin durum genel duruma bakar: aynı anda tek okuma zaten var.
    final active = speech.isActive;

    Future<void> onTap() async {
      if (speech.state == SpeechState.speaking) {
        await controller.pause();
      } else if (speech.state == SpeechState.paused) {
        await controller.resume();
      } else {
        await controller.speak(text);
      }
    }

    final icon = switch (speech.state) {
      SpeechState.speaking => Icons.pause,
      SpeechState.paused => Icons.play_arrow,
      SpeechState.idle => Icons.volume_up_outlined,
    };
    final title = switch (speech.state) {
      SpeechState.speaking => l10n.speechPause,
      SpeechState.paused => l10n.speechResume,
      SpeechState.idle => label ?? l10n.speechPlay,
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label == null)
          IconButton(tooltip: title, icon: Icon(icon), onPressed: onTap)
        else
          TextButton.icon(
            icon: Icon(icon, size: 18),
            label: Text(title),
            onPressed: onTap,
          ),
        if (active) ...[
          IconButton(
            tooltip: l10n.speechStop,
            icon: const Icon(Icons.stop),
            color: scheme.error,
            onPressed: controller.stop,
          ),
          // İlerleme: uzun metinlerde nerede olduğunu göstermezsek okuma
          // donmuş gibi hissettiriyor.
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              value: speech.progress == 0 ? null : speech.progress,
              strokeWidth: 2.5,
            ),
          ),
        ],
      ],
    );
  }
}
