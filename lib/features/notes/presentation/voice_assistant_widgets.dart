import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/utils/speech_output.dart';
import '../../../core/widgets/countdown_bar.dart';
import '../../settings/settings_providers.dart';
import 'voice_assistant.dart';

/// Ana sayfadaki büyük Sesli Not Asistanı düğmesi. Ayara göre iki davranış:
/// - Basılı tut (varsayılan): bastığın sürece dinler, bırakınca not oluşur.
/// - Bas-başlat: dokununca başlar, tekrar dokununca biter.
/// Kayıt sırasında halka ses seviyesiyle büyür ve süre düğmenin içinde akar —
/// çalıştığı ve sesi duyduğu buradan bellidir.
class VoiceAssistantButton extends ConsumerWidget {
  const VoiceAssistantButton({super.key});

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _start(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    HapticFeedback.mediumImpact();
    await ref
        .read(voiceAssistantProvider.notifier)
        .start(
          micPermissionDeniedText: l10n.micPermissionDenied,
          genericErrorText: l10n.assistantGenericError,
        );
  }

  Future<void> _finish(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    HapticFeedback.mediumImpact();
    final ok = await ref
        .read(voiceAssistantProvider.notifier)
        .finish(
          nothingHeardText: l10n.voiceNothingHeard,
          savedText: l10n.voiceNoteSaved,
          noApiKeyText: l10n.aiNoApiKey,
          genericErrorText: l10n.assistantGenericError,
        );
    if (!ok && context.mounted) _showSnack(context, l10n.voiceTooShort);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final assistant = ref.watch(voiceAssistantProvider);
    final mode = ref.watch(voiceButtonModeProvider);
    final hold = mode == VoiceButtonMode.hold;
    final recording = assistant.phase == VoiceAssistantPhase.recording;
    final processing = assistant.phase == VoiceAssistantPhase.processing;

    // Kayıtta düğme ses seviyesiyle nefes alır: 68 → 84 px arası.
    final size = recording ? 68.0 + 16.0 * assistant.level : 68.0;

    final String minutes = (assistant.elapsed.inMinutes).toString();
    final String seconds = (assistant.elapsed.inSeconds % 60)
        .toString()
        .padLeft(2, '0');

    final Widget inner = processing
        ? const Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(strokeWidth: 3),
          )
        : recording
        ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.mic, size: 26, color: scheme.onErrorContainer),
              Text(
                '$minutes:$seconds',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onErrorContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          )
        // Boşta ikonun altında "Asistan" yazar: editördeki dikte mikrofonuyla
        // karışmasın — bu düğme not YARATAN yapay zekâ asistanıdır.
        : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.mic_none, size: 24, color: scheme.onPrimaryContainer),
              Text(
                l10n.voiceAssistantBadge,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onPrimaryContainer,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );

    final button = Semantics(
      button: true,
      label: l10n.voiceAssistantTitle,
      child: GestureDetector(
        // Bas-başlat modunda dokunuş başlatır/bitirir; basılı-tut modunda
        // düz dokunuş yalnızca ipucu gösterir (kayıt uzun basışla).
        onTap: processing
            ? null
            : recording
            // Kayıt sürerken (widget'tan da başlamış olabilir) dokunuş her
            // modda bitirir — durdurmak sezgisel kalsın.
            ? () => _finish(context, ref)
            : hold
            ? () => _showSnack(context, l10n.voiceHoldHint)
            : () => _start(context, ref),
        onLongPressStart: hold && !processing
            ? (_) => _start(context, ref)
            : null,
        onLongPressEnd: hold && !processing
            ? (_) => _finish(context, ref)
            : null,
        onLongPressCancel: hold && !processing
            ? () => ref.read(voiceAssistantProvider.notifier).cancel()
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: recording ? scheme.errorContainer : scheme.primaryContainer,
            border: Border.all(
              color: recording
                  ? scheme.error
                  : scheme.primary.withValues(alpha: 0.4),
              width: recording ? 2.5 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (recording ? scheme.error : scheme.primary).withValues(
                  alpha: recording ? 0.35 : 0.2,
                ),
                blurRadius: recording ? 18 : 8,
                spreadRadius: recording ? 2 : 0,
              ),
            ],
          ),
          child: Center(child: inner),
        ),
      ),
    );

    // Sabit kutu: düğme nefes alırken FAB sütunundaki diğer öğeler zıplamasın.
    return Tooltip(
      message: hold ? l10n.voiceHoldHint : l10n.voiceTapHint,
      child: SizedBox(width: 84, height: 84, child: Center(child: button)),
    );
  }
}

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
        if (on) ref.read(speechOutputProvider.notifier).stop();
      },
    );
  }
}

/// Ana sayfanın altında asistanın ne yaptığını gösteren durum paneli:
/// kayıt (süre + canlı döküm), işleme, sonuç ("Notu aç") ve hata.
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
      VoiceAssistantPhase.recording => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.graphic_eq, size: 18, color: scheme.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.voiceListening,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              // Bas-başlat akışı: kaydı bu "Bitir" ile durdur (widget'tan
              // başlamış olsa da mikrofon düğmesine gitmeye gerek yok).
              TextButton(onPressed: notifier.cancel, child: Text(l10n.cancel)),
              const SizedBox(width: 4),
              FilledButton.tonalIcon(
                onPressed: () => notifier.finish(
                  nothingHeardText: l10n.voiceNothingHeard,
                  savedText: l10n.voiceNoteSaved,
                  noApiKeyText: l10n.aiNoApiKey,
                  genericErrorText: l10n.assistantGenericError,
                ),
                icon: const Icon(Icons.check, size: 18),
                label: Text(l10n.voiceFinish),
              ),
            ],
          ),
          Text(
            l10n.voiceCaptureHint,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          if (assistant.liveTranscript.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              l10n.voiceHeardLive,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            // Canlı döküm: son satırlar görünür kalsın diye ters kaydırma.
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 96),
              child: SingleChildScrollView(
                reverse: true,
                child: Text(
                  assistant.liveTranscript,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ],
        ],
      ),
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
                    context.push('/note/${assistant.noteId}');
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
          if (assistant.noteId == null && assistant.liveTranscript.isNotEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 30, top: 4),
              child: FilledButton.tonalIcon(
                onPressed: () async {
                  final id = await notifier.convertTranscriptToNote(
                    createdText: l10n.assistantNoteCreated,
                  );
                  if (id == null || !context.mounted) return;
                  notifier.dismiss();
                  context.push('/note/$id');
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
    // çubuğuyla görünür (kullanıcı "çok uzun kalıyor" dedi). Kayıt/işleme
    // sürerken çubuk yok — o durumlar kullanıcı eylemiyle biter.
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
        color: assistant.phase == VoiceAssistantPhase.recording
            ? scheme.errorContainer.withValues(alpha: 0.95)
            : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        elevation: 3,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: assistant.phase == VoiceAssistantPhase.recording
                  ? scheme.error.withValues(alpha: 0.4)
                  : scheme.outlineVariant.withValues(alpha: 0.5),
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
