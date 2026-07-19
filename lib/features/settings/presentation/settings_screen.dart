import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/utils/speech_output.dart';
import '../../ai/data/ai_gate.dart';
import '../../ai/data/api_key_store.dart';
import '../../ai/data/gemini_service.dart';
import '../../auth/data/account_service.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../gmail/data/gmail_auth.dart';
import '../../notes/data/notes_repository.dart';
import '../../notes/domain/note.dart';
import '../data/permissions_service.dart';
import '../settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            // Alt boşluk sistem gezinme çubuğunu da içerir; "Çıkış yap"
            // telefonun gezinme düğmelerinin altında kalmasın.
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              16 + MediaQuery.paddingOf(context).bottom + 48,
            ),
            children: [
              _SectionTitle(l10n.settingsAppearance),
              const _ThemeSelector(),
              const SizedBox(height: 12),
              const _FontScaleSlider(),
              const _ExpandListItemsSwitch(),
              const _DarkScheduleEditor(),
              const SizedBox(height: 24),
              _SectionTitle(l10n.voiceAssistantTitle),
              const _VoiceModeSelector(),
              _SpeechVoiceSelector(
                language: 'tr',
                title: l10n.speechVoiceTurkish,
              ),
              _SpeechVoiceSelector(
                language: 'en',
                title: l10n.speechVoiceEnglish,
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  l10n.speechVoiceAutoInfo,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const _SpeechRateSlider(),
              const SizedBox(height: 24),
              if (const PermissionsService().isSupported) ...[
                _SectionTitle(l10n.permissionsTitle),
                const _PermissionsSection(),
                const SizedBox(height: 24),
              ],
              _SectionTitle(l10n.settingsAi),
              const _BuiltInAiStatus(),
              const _GeminiKeyEditor(),
              const SizedBox(height: 12),
              const _ModelSelectors(),
              const SizedBox(height: 12),
              const _BriefingEditor(),
              const _AutoTagSwitch(),
              const SizedBox(height: 24),
              _SectionTitle(l10n.settingsGmail),
              const _GmailSection(),
              const SizedBox(height: 24),
              _SectionTitle(l10n.account),
              const _AccountSection(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          letterSpacing: 1.1,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

/// Uygulamanın düzgün çalışması için gereken izinleri gösterir ve ister.
/// Sistem ayarından dönüldüğünde (resume) durum kendiliğinden tazelenir.
class _PermissionsSection extends ConsumerStatefulWidget {
  const _PermissionsSection();

  @override
  ConsumerState<_PermissionsSection> createState() =>
      _PermissionsSectionState();
}

class _PermissionsSectionState extends ConsumerState<_PermissionsSection>
    with WidgetsBindingObserver {
  bool? _mic;
  bool? _notifications;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Kullanıcı sistem izin ekranından dönünce yeni durumu göster.
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final service = ref.read(permissionsServiceProvider);
    final mic = await service.micGranted();
    final notifications = await service.notificationsGranted();
    if (mounted) {
      setState(() {
        _mic = mic;
        _notifications = notifications;
      });
    }
  }

  Future<void> _requestMic() async {
    final service = ref.read(permissionsServiceProvider);
    final ok = await service.requestMic();
    // İstek dönüşü false ise izin kalıcı reddedilmiş olabilir; kullanıcının
    // elle açabilmesi için sistem ayarına yönlendir.
    if (!ok) await service.openAppSettings();
    await _refresh();
  }

  Future<void> _requestNotifications() async {
    final service = ref.read(permissionsServiceProvider);
    final ok = await service.requestNotifications();
    if (!ok) await service.openAppSettings();
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final service = ref.read(permissionsServiceProvider);
    return Column(
      children: [
        _PermissionTile(
          icon: Icons.mic_none,
          title: l10n.permMic,
          subtitle: l10n.permMicInfo,
          granted: _mic,
          onAction: _requestMic,
        ),
        _PermissionTile(
          icon: Icons.notifications_none,
          title: l10n.permNotifications,
          subtitle: l10n.permNotificationsInfo,
          granted: _notifications,
          onAction: _requestNotifications,
        ),
        // Pil muafiyeti durumu güvenilir okunamadığından her zaman "Ayarları
        // aç" gösterir; kullanıcı uygulamayı pil kısıtlamasından muaf tutar.
        _PermissionTile(
          icon: Icons.battery_saver_outlined,
          title: l10n.permBattery,
          subtitle: l10n.permBatteryInfo,
          granted: null,
          actionLabel: l10n.permOpenSettings,
          onAction: service.openBatterySettings,
        ),
      ],
    );
  }
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.granted,
    required this.onAction,
    this.actionLabel,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  /// true = verildi, false = reddedildi, null = durum okunamıyor (muafiyet).
  final bool? granted;
  final Future<void> Function() onAction;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isGranted = granted == true;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: scheme.onSurfaceVariant),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (isGranted)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 18,
                  color: Colors.green.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  context.l10n.permGranted,
                  style: TextStyle(color: Colors.green.shade600, fontSize: 12),
                ),
              ],
            )
          else
            FilledButton.tonal(
              onPressed: onAction,
              child: Text(actionLabel ?? context.l10n.permGrant),
            ),
        ],
      ),
    );
  }
}

class _ThemeSelector extends ConsumerWidget {
  const _ThemeSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final choice = ref.watch(themeChoiceProvider);
    // Dört seçenek dar ekrana sığmayabilir; taşma yerine yatay kaydırma.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<AppThemeChoice>(
        segments: [
          ButtonSegment(
            value: AppThemeChoice.system,
            label: Text(l10n.themeSystem),
            icon: const Icon(Icons.brightness_auto_outlined),
          ),
          ButtonSegment(
            value: AppThemeChoice.light,
            label: Text(l10n.themeLight),
            icon: const Icon(Icons.light_mode_outlined),
          ),
          ButtonSegment(
            value: AppThemeChoice.dark,
            label: Text(l10n.themeDark),
            icon: const Icon(Icons.dark_mode_outlined),
          ),
          ButtonSegment(
            value: AppThemeChoice.paper,
            label: Text(l10n.themePaper),
            icon: const Icon(Icons.menu_book_outlined),
          ),
        ],
        selected: {choice},
        onSelectionChanged: (selection) =>
            ref.read(themeChoiceProvider.notifier).set(selection.first),
      ),
    );
  }
}

/// Sesli Not Asistanı düğmesinin kullanım şekli: basılı tut (varsayılan)
/// veya bas-başlat / bas-bitir.
class _VoiceModeSelector extends ConsumerWidget {
  const _VoiceModeSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final mode = ref.watch(voiceButtonModeProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.voiceModeSetting),
        const SizedBox(height: 8),
        SegmentedButton<VoiceButtonMode>(
          segments: [
            ButtonSegment(
              value: VoiceButtonMode.hold,
              label: Text(l10n.voiceModeHold),
              icon: const Icon(Icons.touch_app_outlined),
            ),
            ButtonSegment(
              value: VoiceButtonMode.tap,
              label: Text(l10n.voiceModeTap),
              icon: const Icon(Icons.play_circle_outline),
            ),
          ],
          selected: {mode},
          onSelectionChanged: (selection) =>
              ref.read(voiceButtonModeProvider.notifier).set(selection.first),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.voiceModeInfo,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _FontScaleSlider extends ConsumerWidget {
  const _FontScaleSlider();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scale = ref.watch(fontScaleProvider);
    return Row(
      children: [
        const Icon(Icons.format_size, size: 18),
        const SizedBox(width: 8),
        Text(l10n.fontSize),
        Expanded(
          child: Slider(
            value: scale,
            min: 0.85,
            max: 1.4,
            divisions: 11,
            label: '${(scale * 100).round()}%',
            onChanged: (value) =>
                ref.read(fontScaleProvider.notifier).set(value),
          ),
        ),
        Text('${(scale * 100).round()}%'),
      ],
    );
  }
}

class _ExpandListItemsSwitch extends ConsumerWidget {
  const _ExpandListItemsSwitch();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(l10n.expandListItems),
      subtitle: Text(l10n.expandListItemsInfo),
      value: ref.watch(expandListItemsProvider),
      onChanged: (value) =>
          ref.read(expandListItemsProvider.notifier).set(value),
    );
  }
}

/// Bir dilin sesli okuma sesi. Yalnız Türkçe ve İngilizce kullanıcıya
/// sorulur; kalan diller otomatik erkek sesiyle okunur. Liste cihazdan gelir
/// (kurulu TTS motoruna göre değişir), bu yüzden sabit katalog tutulmuyor.
class _SpeechVoiceSelector extends ConsumerStatefulWidget {
  const _SpeechVoiceSelector({required this.language, required this.title});

  final String language;
  final String title;

  @override
  ConsumerState<_SpeechVoiceSelector> createState() =>
      _SpeechVoiceSelectorState();
}

class _SpeechVoiceSelectorState extends ConsumerState<_SpeechVoiceSelector> {
  List<SpeechVoice>? _voices;
  SpeechVoice? _selected;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final controller = ref.read(speechOutputProvider.notifier);
    final voices = await controller.voices(language: widget.language);
    final selected = await controller.selectedVoice(widget.language);
    if (!mounted) return;
    setState(() {
      _voices = voices;
      _selected = selected;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final voices = _voices;
    if (voices == null) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(widget.title),
        trailing: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (voices.isEmpty) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(widget.title),
        subtitle: Text(l10n.speechNoVoices),
      );
    }
    final current = _selected;
    final value = current != null && voices.any((v) => v.id == current.id)
        ? current.id
        : null;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(widget.title),
      trailing: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 190),
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          hint: Text(l10n.speechSystemDefault),
          items: [
            for (final voice in voices)
              DropdownMenuItem(
                value: voice.id,
                child: Text(
                  voice.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (id) async {
            final picked = voices.firstWhere((v) => v.id == id);
            final controller = ref.read(speechOutputProvider.notifier);
            await controller.setVoice(widget.language, picked);
            if (!mounted) return;
            setState(() => _selected = picked);
            // Seçilen ses hemen duyulsun: adından anlaşılmıyor.
            await controller.speak(
              widget.language == 'en'
                  ? 'This is the selected voice.'
                  : 'Seçilen ses bu.',
              languageCode: widget.language,
            );
          },
        ),
      ),
    );
  }
}

class _SpeechRateSlider extends ConsumerStatefulWidget {
  const _SpeechRateSlider();

  @override
  ConsumerState<_SpeechRateSlider> createState() => _SpeechRateSliderState();
}

class _SpeechRateSliderState extends ConsumerState<_SpeechRateSlider> {
  double? _rate;

  @override
  void initState() {
    super.initState();
    ref.read(speechOutputProvider.notifier).rate().then((value) {
      if (mounted) setState(() => _rate = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final rate = _rate;
    if (rate == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(context.l10n.speechRate),
          Expanded(
            child: Slider(
              value: rate,
              min: 0.2,
              max: 1,
              divisions: 8,
              label: '${(rate * 2).toStringAsFixed(1)}x',
              onChanged: (value) => setState(() => _rate = value),
              onChangeEnd: (value) =>
                  ref.read(speechOutputProvider.notifier).setRate(value),
            ),
          ),
        ],
      ),
    );
  }
}

class _DarkScheduleEditor extends ConsumerWidget {
  const _DarkScheduleEditor();

  String _format(int minutes) =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';

  Future<void> _pick(
    BuildContext context,
    WidgetRef ref, {
    required bool isStart,
  }) async {
    final schedule = ref.read(darkScheduleProvider);
    final current = isStart ? schedule.startMinutes : schedule.endMinutes;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
    );
    if (time == null) return;
    final minutes = time.hour * 60 + time.minute;
    ref
        .read(darkScheduleProvider.notifier)
        .update(
          startMinutes: isStart ? minutes : null,
          endMinutes: isStart ? null : minutes,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final schedule = ref.watch(darkScheduleProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.darkSchedule),
          subtitle: Text(l10n.darkScheduleInfo),
          value: schedule.enabled,
          onChanged: (value) =>
              ref.read(darkScheduleProvider.notifier).update(enabled: value),
        ),
        if (schedule.enabled)
          Row(
            children: [
              const SizedBox(width: 4),
              ActionChip(
                avatar: const Icon(Icons.dark_mode_outlined, size: 16),
                label: Text(_format(schedule.startMinutes)),
                onPressed: () => _pick(context, ref, isStart: true),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward, size: 14),
              ),
              ActionChip(
                avatar: const Icon(Icons.light_mode_outlined, size: 16),
                label: Text(_format(schedule.endMinutes)),
                onPressed: () => _pick(context, ref, isStart: false),
              ),
            ],
          ),
      ],
    );
  }
}

/// Dahili AI durumu: kendi anahtarı varsa "sınırsız", premium'sa "premium",
/// değilse bugünkü kalan ücretsiz hak gösterilir.
class _BuiltInAiStatus extends ConsumerWidget {
  const _BuiltInAiStatus();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final hasKey = (ref.watch(geminiApiKeyProvider).value ?? '').isNotEmpty;
    final premium = ref.watch(premiumProvider).value ?? false;
    final remaining = ref.watch(freeAiRemainingProvider);

    final (icon, text) = hasKey
        ? (Icons.key, l10n.aiBuiltInByok)
        : premium
        ? (Icons.workspace_premium_outlined, l10n.aiBuiltInPremium)
        : (Icons.bolt_outlined, l10n.aiBuiltInRemaining(remaining));

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: scheme.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _GeminiKeyEditor extends ConsumerStatefulWidget {
  const _GeminiKeyEditor();

  @override
  ConsumerState<_GeminiKeyEditor> createState() => _GeminiKeyEditorState();
}

class _GeminiKeyEditorState extends ConsumerState<_GeminiKeyEditor> {
  final _controller = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _validateAndSave() async {
    final key = _controller.text.trim();
    if (key.isEmpty) return;
    setState(() => _busy = true);
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final valid = await ref.read(geminiServiceProvider).validateKey(key);
      if (!valid) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.apiKeyInvalid)));
        return;
      }
      await ref.read(apiKeyStoreProvider).save(key);
      ref.invalidate(geminiApiKeyProvider);
      _controller.clear();
      messenger.showSnackBar(SnackBar(content: Text(l10n.apiKeyValid)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _removeKey() async {
    await ref.read(apiKeyStoreProvider).clear();
    ref.invalidate(geminiApiKeyProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final storedKey = ref.watch(geminiApiKeyProvider).value;
    final hasKey = storedKey != null && storedKey.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasKey)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Chip(
                  avatar: const Icon(Icons.key, size: 16),
                  label: Text('${l10n.geminiApiKey}: ${l10n.apiKeySavedBadge}'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _removeKey,
                  child: Text(l10n.removeApiKey),
                ),
              ],
            ),
          ),
        TextField(
          controller: _controller,
          obscureText: true,
          decoration: InputDecoration(
            labelText: l10n.geminiApiKey,
            hintText: l10n.geminiApiKeyHint,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.geminiApiKeyInfo,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        FilledButton.tonalIcon(
          onPressed: _busy ? null : _validateAndSave,
          icon: _busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check_circle_outline),
          label: Text(l10n.validateAndSave),
        ),
      ],
    );
  }
}

/// Kullanım alanı başına Gemini model seçimi. "Otomatik" = uygulamanın
/// kendi sıralı zinciri; belirli model seçilirse o ilk sırada denenir.
class _ModelSelectors extends ConsumerWidget {
  const _ModelSelectors();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final hasKey = (ref.watch(geminiApiKeyProvider).value ?? '').isNotEmpty;
    if (!hasKey) return const SizedBox.shrink();

    return FutureBuilder<List<String>>(
      future: ref.read(geminiServiceProvider).availableModels(),
      builder: (context, snapshot) {
        final models = snapshot.data ?? const <String>[];
        if (models.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _modelDropdown(
              label: l10n.aiModelChat,
              models: models,
              value: ref.watch(chatModelProvider),
              autoLabel: l10n.aiModelAuto,
              onChanged: (v) => ref.read(chatModelProvider.notifier).set(v),
            ),
            const SizedBox(height: 10),
            _modelDropdown(
              label: l10n.aiModelVoice,
              models: models,
              value: ref.watch(voiceModelProvider),
              autoLabel: l10n.aiModelAuto,
              onChanged: (v) => ref.read(voiceModelProvider.notifier).set(v),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.aiModelsInfo,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _modelDropdown({
    required String label,
    required List<String> models,
    required String? value,
    required String autoLabel,
    required ValueChanged<String?> onChanged,
  }) {
    // Kayıtlı model artık listede yoksa (kaldırılmış olabilir) yine göster;
    // zincir zaten çalışan bir modele düşer.
    final items = value != null && !models.contains(value)
        ? [value, ...models]
        : models;
    return DropdownButtonFormField<String?>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: [
        DropdownMenuItem<String?>(value: null, child: Text(autoLabel)),
        for (final m in items)
          DropdownMenuItem<String?>(value: m, child: Text(m)),
      ],
      onChanged: onChanged,
    );
  }
}

class _BriefingEditor extends ConsumerWidget {
  const _BriefingEditor();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(briefingSettingsProvider);
    final time =
        '${(settings.minutes ~/ 60).toString().padLeft(2, '0')}:${(settings.minutes % 60).toString().padLeft(2, '0')}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.briefingSetting),
          subtitle: Text(l10n.briefingSettingInfo),
          value: settings.enabled,
          onChanged: (value) => ref
              .read(briefingSettingsProvider.notifier)
              .update(enabled: value),
        ),
        if (settings.enabled)
          ActionChip(
            avatar: const Icon(Icons.schedule, size: 16),
            label: Text(time),
            onPressed: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(
                  hour: settings.minutes ~/ 60,
                  minute: settings.minutes % 60,
                ),
              );
              if (picked != null) {
                ref
                    .read(briefingSettingsProvider.notifier)
                    .update(minutes: picked.hour * 60 + picked.minute);
              }
            },
          ),
      ],
    );
  }
}

class _AutoTagSwitch extends ConsumerWidget {
  const _AutoTagSwitch();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(l10n.autoTagSetting),
      subtitle: Text(l10n.autoTagSettingInfo),
      value: ref.watch(autoTagProvider),
      onChanged: (value) => ref.read(autoTagProvider.notifier).set(value),
    );
  }
}

class _GmailSection extends ConsumerStatefulWidget {
  const _GmailSection();

  @override
  ConsumerState<_GmailSection> createState() => _GmailSectionState();
}

class _GmailSectionState extends ConsumerState<_GmailSection> {
  bool _busy = false;

  Future<void> _toggle(bool connected) async {
    setState(() => _busy = true);
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final auth = ref.read(gmailAuthProvider);
      if (connected) {
        await auth.disconnect();
      } else {
        await auth.connect();
      }
      ref.invalidate(gmailConnectedProvider);
      ref.invalidate(gmailAccountEmailProvider);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.genericError(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final connected = ref.watch(gmailConnectedProvider);
    final accountEmail = ref.watch(gmailAccountEmailProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.gmailInfo,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (connected) ...[
              Chip(
                avatar: Icon(
                  Icons.check_circle,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                label: Text(
                  accountEmail == null || accountEmail.isEmpty
                      ? l10n.gmailConnected
                      : accountEmail,
                ),
              ),
              TextButton(
                onPressed: _busy ? null : () => _toggle(false),
                child: Text(l10n.gmailChangeAccount),
              ),
              TextButton(
                onPressed: _busy ? null : () => _toggle(true),
                child: Text(l10n.disconnectGmail),
              ),
            ] else
              FilledButton.tonalIcon(
                onPressed: _busy ? null : () => _toggle(false),
                icon: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.link),
                label: Text(l10n.connectGmail),
              ),
          ],
        ),
      ],
    );
  }
}

/// Tüm notları (arşiv dahil, çöp hariç) tek JSON dosyası olarak dışa
/// aktarıp paylaşım sayfasını açar. Ek dosyaları bulutta kaldığından
/// yalnızca adları ve bağlantıları yazılır.
class _BackupButton extends ConsumerWidget {
  const _BackupButton();

  Map<String, dynamic> _exportNote(Note n) => {
    'id': n.id,
    'type': n.type.id,
    'title': n.title,
    'body': n.body,
    'items': [
      for (final i in n.items) {'text': i.text, 'checked': i.checked},
    ],
    'tags': n.tags,
    'color': n.color.id,
    'pinned': n.pinned,
    'locked': n.locked,
    'createdAt': n.createdAt?.toIso8601String(),
    'updatedAt': n.updatedAt?.toIso8601String(),
    'archivedAt': n.archivedAt?.toIso8601String(),
    'reminderAt': n.reminderAt?.toIso8601String(),
    'attachments': [
      for (final a in n.attachments)
        {'fileName': a.fileName, 'kind': a.kind.name, 'url': a.downloadUrl},
    ],
  };

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final notes = ref.read(notesStreamProvider).value;
    if (notes == null) return;
    try {
      final payload = const JsonEncoder.withIndent('  ').convert({
        'app': 'notlar',
        'exportedAt': DateTime.now().toIso8601String(),
        'noteCount': notes.length,
        'notes': [for (final n in notes) _exportNote(n)],
      });
      final now = DateTime.now();
      final stamp =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}';
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/notlar-yedek-$stamp.json');
      await file.writeAsString(payload);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], subject: 'Notlar yedeği'),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.genericError(e.toString()))),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton.icon(
      icon: const Icon(Icons.file_download_outlined),
      label: Text(context.l10n.exportBackup),
      onPressed: () => _export(context, ref),
    );
  }
}

class _AccountSection extends ConsumerWidget {
  const _AccountSection();

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteAccount),
        content: Text(l10n.deleteAccountWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.deleteAccountConfirm),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false) || !context.mounted) return;

    // Silme sürerken kapatılamayan bir bekleme göstergesi.
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    final navigator = Navigator.of(context, rootNavigator: true);
    try {
      await ref.read(accountServiceProvider).deleteAccountAndData();
      // Başarıda auth durumu değişir; router login ekranına yönlendirir.
      navigator.pop();
    } catch (e) {
      navigator.pop();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l10n.genericError(e.toString()))),
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final user = ref.watch(authStateProvider).value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (user != null)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundImage: user.photoURL != null
                  ? NetworkImage(user.photoURL!)
                  : null,
              child: user.photoURL == null
                  ? const Icon(Icons.person_outline)
                  : null,
            ),
            title: Text(user.displayName ?? ''),
            subtitle: Text(user.email ?? ''),
          ),
        TextButton.icon(
          icon: const Icon(Icons.logout),
          label: Text(l10n.signOut),
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: Text(l10n.signOut),
                content: Text(l10n.signOutConfirm),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: Text(l10n.cancel),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: Text(l10n.signOut),
                  ),
                ],
              ),
            );
            if (confirmed ?? false) {
              await ref.read(authRepositoryProvider).signOut();
            }
          },
        ),
        TextButton.icon(
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          icon: const Icon(Icons.delete_forever_outlined),
          label: Text(l10n.deleteAccount),
          onPressed: () => _deleteAccount(context, ref),
        ),
        const SizedBox(height: 16),
        // Verinin sahibi kullanıcı: tüm notlar tek dosyada dışa aktarılır.
        const _BackupButton(),
        // Hukuki şeffaflık: gizlilik politikası + açık kaynak lisansları.
        TextButton.icon(
          icon: const Icon(Icons.privacy_tip_outlined),
          label: Text(l10n.privacyPolicyTitle),
          onPressed: () => context.push('/privacy'),
        ),
        TextButton.icon(
          icon: const Icon(Icons.description_outlined),
          label: Text(l10n.licensesTitle),
          onPressed: () =>
              showLicensePage(context: context, applicationName: l10n.appName),
        ),
      ],
    );
  }
}
