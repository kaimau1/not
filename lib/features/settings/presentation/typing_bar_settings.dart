import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n_ext.dart';
import '../settings_providers.dart';

/// **YAZARKEN ALT ÇUBUĞU GİZLE — ayarları** (F60.S7, kullanıcı isteği
/// 2026-11-11: "yazarken alt panelin gizlenip gösterilmesi ayarlanabilir
/// olsun, kapatılabilsin; ne zaman kapanacak, kaç sn sonra açılacak — 0,1 sn
/// adımlı kaydırıcı").
///
/// Anahtar ([hideBarWhileTypingProvider]) + iki kaydırıcı (0–5 sn, 0,1 adım):
/// gizlenme gecikmesi ([typingBarHideDelayProvider]) ve yeniden görünme
/// gecikmesi ([typingBarShowDelayProvider]). Üçü de cihaz tercihi; anahtar
/// kapalıyken kaydırıcılar pasif.
class TypingBarSettings extends ConsumerWidget {
  const TypingBarSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final enabled = ref.watch(hideBarWhileTypingProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          key: const ValueKey('hide-bar-typing-switch'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.hideBarWhileTyping),
          subtitle: Text(l10n.hideBarWhileTypingInfo),
          value: enabled,
          onChanged: (value) =>
              ref.read(hideBarWhileTypingProvider.notifier).set(value),
        ),
        _DelaySlider(
          sliderKey: const ValueKey('typing-bar-hide-delay'),
          title: l10n.typingBarHideDelay,
          info: l10n.typingBarHideDelayInfo,
          provider: typingBarHideDelayProvider,
          enabled: enabled,
        ),
        _DelaySlider(
          sliderKey: const ValueKey('typing-bar-show-delay'),
          title: l10n.typingBarShowDelay,
          info: l10n.typingBarShowDelayInfo,
          provider: typingBarShowDelayProvider,
          enabled: enabled,
        ),
      ],
    );
  }
}

class _DelaySlider extends ConsumerStatefulWidget {
  const _DelaySlider({
    required this.sliderKey,
    required this.title,
    required this.info,
    required this.provider,
    required this.enabled,
  });

  final Key sliderKey;
  final String title;
  final String info;
  final NotifierProvider<TypingBarDelayNotifier, int> provider;
  final bool enabled;

  @override
  ConsumerState<_DelaySlider> createState() => _DelaySliderState();
}

class _DelaySliderState extends ConsumerState<_DelaySlider> {
  /// Sürüklenirken geçici değer (saniyenin onda biri); tercih bırakınca
  /// yazılır — her adımda diske yazılmaz.
  int? _dragging;

  static int _toTenths(double seconds) => (seconds * 10).round();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final int tenths = _dragging ?? ref.watch(widget.provider);
    // "1,2 sn" / "1.2 s": ondalık ayracı dile göre.
    final label = l10n.secondsValue(
      NumberFormat(
        '0.0',
        Localizations.localeOf(context).toLanguageTag(),
      ).format(tenths / 10),
    );
    final muted = widget.enabled ? null : theme.disabledColor;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: theme.textTheme.bodyLarge?.copyWith(color: muted),
                ),
              ),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: muted ?? theme.colorScheme.primary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          Text(
            widget.info,
            style: theme.textTheme.bodySmall?.copyWith(
              color: muted ?? theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Slider(
            key: widget.sliderKey,
            value: tenths / 10,
            max: TypingBarDelayNotifier.maxTenths / 10,
            divisions: TypingBarDelayNotifier.maxTenths,
            label: label,
            onChanged: widget.enabled
                ? (value) => setState(() => _dragging = _toTenths(value))
                : null,
            onChangeEnd: widget.enabled
                ? (value) {
                    ref.read(widget.provider.notifier).set(_toTenths(value));
                    setState(() => _dragging = null);
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
