import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router.dart';
import '../../../core/l10n_ext.dart';
import '../../ai/data/speech_service.dart';
import '../../../core/widgets/countdown_bar.dart';
import '../../settings/settings_providers.dart';
import 'voice_assistant.dart';

// Sağ alttaki 68 px'lik "Asistan" düğmesi (VoiceAssistantButton) kaldırıldı:
// ana ekranda yerini 48×48 mikrofon aldı ve o düğme ortak dinleme levhasını
// açıyor (bkz. dashboard_screen.dart / _captureVoiceNote). Kayıt durumu artık
// levhada göründüğü için düğmenin ses seviyesiyle nefes almasına gerek kalmadı.
// Aşağıdaki panel DURUYOR: levhadaki "AI not"un sonucunu (işleniyor, "Notu
// aç", hata) o gösteriyor. Kendi kayıt evresi 2026-10-19'da kalktı — widget
// da artık levhayı açıyor.

/// Asistan panelindeki sustur düğmesi.
///
/// Ayarlardaki "Asistan sesli yanıtlasın" ile AYNI değeri okur/yazar: burada
/// susturulan asistan Ayarlar'da da kapalı görünür. Dokunulduğu anda süren
/// okuma da kesilir — "sustur" düğmesinden beklenen ilk şey budur.
class _AssistantMuteButton extends ConsumerWidget {
  const _AssistantMuteButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = ref.watch(assistantVoiceProvider);
    final l10n = context.l10n;
    return IconButton(
      tooltip: on ? l10n.assistantMute : l10n.assistantUnmute,
      visualDensity: VisualDensity.compact,
      icon: Icon(on ? Icons.volume_up_outlined : Icons.volume_off, size: 20),
      onPressed: () {
        ref.read(assistantVoiceProvider.notifier).toggle();
        if (on) ref.read(speechProvider.notifier).stop();
      },
    );
  }
}

/// Ana sayfanın altında asistanın ne yaptığını gösteren durum paneli:
/// işleme, sonuç ("Notu aç") ve hata.
/// Boşta hiç görünmez.
class VoiceAssistantPanel extends ConsumerWidget {
  const VoiceAssistantPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assistant = ref.watch(voiceAssistantProvider);
    if (assistant.phase == VoiceAssistantPhase.idle) {
      return const SizedBox.shrink();
    }

    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final notifier = ref.read(voiceAssistantProvider.notifier);

    final Widget content = switch (assistant.phase) {
      VoiceAssistantPhase.processing => Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(l10n.voiceProcessing)),
        ],
      ),
      VoiceAssistantPhase.done => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.check_circle_outline, size: 20, color: scheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  assistant.message,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              // Sustur: yanıt okunurken susturur ve AYARDAKİ tercihi
              // değiştirir — ses iki yerden de aynı anahtarla yönetilir.
              const _AssistantMuteButton(),
              if (assistant.noteId != null)
                TextButton(
                  onPressed: () {
                    notifier.dismiss();
                    context.pushNote(noteRoutePath(assistant.noteId!));
                  },
                  child: Text(l10n.openNote),
                ),
              IconButton(
                tooltip: l10n.close,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close, size: 20),
                onPressed: notifier.dismiss,
              ),
            ],
          ),
          // Asistan "bu bir not değil" deyip hiçbir şey oluşturmadıysa
          // konuşulan yine de kaydedilebilsin: karar kullanıcının olsun.
          if (assistant.noteId == null && assistant.transcript.isNotEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 30, top: 4),
              child: FilledButton.tonalIcon(
                onPressed: () async {
                  final id = await notifier.convertTranscriptToNote(
                    createdText: l10n.assistantNoteCreated,
                  );
                  if (id == null || !context.mounted) return;
                  notifier.dismiss();
                  context.pushNote(noteRoutePath(id));
                },
                icon: const Icon(Icons.note_add_outlined, size: 18),
                label: Text(l10n.assistantMakeNote),
              ),
            ),
        ],
      ),
      VoiceAssistantPhase.error => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, size: 20, color: scheme.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              assistant.message,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          IconButton(
            tooltip: l10n.close,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close, size: 20),
            onPressed: notifier.dismiss,
          ),
        ],
      ),
      VoiceAssistantPhase.idle => const SizedBox.shrink(),
    };

    // done/error panelleri kendiliğinden kapansın: kalan süre geri sayım
    // çubuğuyla görünür (kullanıcı "çok uzun kalıyor" dedi). İşleme
    // sürerken çubuk yok.
    final autoDismiss = switch (assistant.phase) {
      VoiceAssistantPhase.done => const Duration(seconds: 6),
      VoiceAssistantPhase.error => const Duration(seconds: 8),
      _ => null,
    };

    // Panel artık FAB sütununda, butonların ÜSTÜnde yüzer (en dipte değil);
    // Scaffold FAB'ı güvenli alanı kendisi hesaba katar. Alttaki 8 px, panel
    // ile mikrofon düğmesi arasını açar.
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        elevation: 3,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              content,
              if (autoDismiss != null) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 6),
                  child: CountdownBar(
                    duration: autoDismiss,
                    onEnd: notifier.dismiss,
                    color: assistant.phase == VoiceAssistantPhase.error
                        ? scheme.error
                        : scheme.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
