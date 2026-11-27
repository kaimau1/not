part of '../settings_screen.dart';

/// Cihaz sesiyle KISA bir deneme okur.
///
/// Hız/ton kaydırıcıları eskiden sessizdi: kullanıcı değeri değiştiriyor ama
/// nasıl duyulduğunu ancak bir notu açıp okutarak öğreniyordu (kullanıcı
/// isteği 2026-08-09: "hızı tonu sesi tipi seçince test sesi gelmeli").
/// Cihaz TTS'i yerel ve bedava — burada kota kaygısı yok.
void _previewDeviceVoice(BuildContext context, WidgetRef ref) {
  final language = Localizations.localeOf(context).languageCode;
  unawaited(
    ref
        .read(speechProvider.notifier)
        .preview(
          SpeechOutputController.voiceSample(language),
          languageCode: language,
        ),
  );
}

class _SpeechRateSlider extends ConsumerStatefulWidget {
  const _SpeechRateSlider();

  @override
  ConsumerState<_SpeechRateSlider> createState() => _SpeechRateSliderState();
}

class _SpeechRateSliderState extends ConsumerState<_SpeechRateSlider> {
  late double _rate;

  @override
  void initState() {
    super.initState();
    _rate = SpeechOutputController.readRateSync(
      ref.read(sharedPreferencesProvider),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rate = _rate;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(context.l10n.speechRate)),
          Expanded(
            flex: 2,
            child: Slider(
              value: rate,
              min: 0.2,
              divisions: 8,
              label: '${(rate * 2).toStringAsFixed(1)}x',
              onChanged: (value) => setState(() => _rate = value),
              onChangeEnd: (value) async {
                await ref.read(speechOutputProvider.notifier).setRate(value);
                if (context.mounted) _previewDeviceVoice(context, ref);
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Yabancı diller (Türkçe dışı) için ayrı okuma hızı: çeviri seslendirmesi,
/// İngilizce/Almanca vb. sesli okuma bu hızı kullanır. Motorlar yabancı dili
/// Türkçe'ye göre hızlı okuyabildiğinden ayrı, genelde daha düşük tutulur.
class _ForeignSpeechRateSlider extends ConsumerStatefulWidget {
  const _ForeignSpeechRateSlider();

  @override
  ConsumerState<_ForeignSpeechRateSlider> createState() =>
      _ForeignSpeechRateSliderState();
}

class _ForeignSpeechRateSliderState
    extends ConsumerState<_ForeignSpeechRateSlider> {
  late double _rate;

  @override
  void initState() {
    super.initState();
    _rate = SpeechOutputController.readForeignRateSync(
      ref.read(sharedPreferencesProvider),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rate = _rate;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(context.l10n.speechRateForeign)),
          Expanded(
            flex: 2,
            child: Slider(
              value: rate,
              min: 0.2,
              divisions: 8,
              label: '${(rate * 2).toStringAsFixed(1)}x',
              onChanged: (value) => setState(() => _rate = value),
              onChangeEnd: (value) async {
                await ref
                    .read(speechOutputProvider.notifier)
                    .setForeignRate(value);
                // Yabancı hız İNGİLİZCE örnekle denenir: Türkçe cümleyi
                // Türkçe hızla okur, ayarın etkisi duyulmazdı.
                if (!context.mounted) return;
                unawaited(
                  ref
                      .read(speechProvider.notifier)
                      .preview(
                        SpeechOutputController.voiceSample('en'),
                        languageCode: 'en',
                      ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Sesin TONU (perde): aynı ses daha kalın ya da daha ince okur.
///
/// Ayarlarda YOKTU (kullanıcı isteği 2026-08-09: "eksik ayar varsa
/// eklenmeli"). Motorların kabul ettiği aralık 0,5–2,0; 1,0 sesin kendi tonu.
class _SpeechPitchSlider extends ConsumerStatefulWidget {
  const _SpeechPitchSlider();

  @override
  ConsumerState<_SpeechPitchSlider> createState() => _SpeechPitchSliderState();
}

class _SpeechPitchSliderState extends ConsumerState<_SpeechPitchSlider> {
  late double _pitch;

  @override
  void initState() {
    super.initState();
    _pitch = SpeechOutputController.readPitchSync(
      ref.read(sharedPreferencesProvider),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pitch = _pitch;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(context.l10n.speechPitch)),
          Expanded(
            flex: 2,
            child: Slider(
              value: pitch,
              min: 0.5,
              max: 2,
              divisions: 6,
              label: pitch.toStringAsFixed(1),
              onChanged: (value) => setState(() => _pitch = value),
              // Kaydırırken DEĞİL bırakınca yazılır: her karede motor ayarı
              // yeniden kurmak sesi tutukluyor (madde 9 — kasma olmamalı).
              onChangeEnd: (value) async {
                await ref.read(speechOutputProvider.notifier).setPitch(value);
                if (context.mounted) _previewDeviceVoice(context, ref);
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// **Seslendirme — tek blok.** Okuma işini kim yapacak (cihazın yerleşik sesi
/// mi, yapay zekâ mı), hangi modelle ve hangi sesle: hepsi burada.
///
/// KÖK NEDEN (kullanıcı isteği 2026-08-09: "ai ve cihaz seçimleri tek yerden
/// yapılabilmesi, ses seçimleri tek menüde olmalı"): motor seçimi bir satırda,
/// yapay zekâ sesi başka bir satırda, CİHAZ sesleri ise uygulamanın diline
/// göre iki-üç ayrı açılır listede duruyordu. "Sesi değiştireyim" diyen
/// kullanıcı hangi kutunun hangi motorun sesini seçtiğini ayırt edemiyordu.
/// Artık seçilen motora göre TEK bir ses seçimi görünür; cihaz sesleri de tek
/// menüde (dil seç → ses seç) toplanır.
class _VoiceSection extends ConsumerWidget {
  const _VoiceSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpace.s),
        Text(
          l10n.ttsEngineDeviceInfo,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 6),
        ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.record_voice_over_outlined),
            title: Text(l10n.speechVoicePickerTitle),
            subtitle: Text(l10n.speechVoiceAutoInfo),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showAppSheet<void>(
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              builder: (_) => const _VoicePickerSheet(),
            ),
        ),
      ],
    );
  }
}

/// Cihaz seslerinin TEK menüsü: üstte dil seçimi, altında o dilin sesleri.
/// Seçilen ses hemen O DİLDE bir örnek cümle okur — ad ("tr-tr-x-ama#male_1")
/// tek başına hiçbir şey anlatmıyor.
class _VoicePickerSheet extends ConsumerStatefulWidget {
  const _VoicePickerSheet();

  @override
  ConsumerState<_VoicePickerSheet> createState() => _VoicePickerSheetState();
}

class _VoicePickerSheetState extends ConsumerState<_VoicePickerSheet> {
  late List<String> _languages;
  String? _language;
  List<SpeechVoice>? _voices;
  SpeechVoice? _selected;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_language != null) return;
    _languages = _voiceLanguages(context);
    _language = _languages.isEmpty ? 'tr' : _languages.first;
    _load();
  }

  Future<void> _load() async {
    final language = _language!;
    setState(() => _voices = null);
    final controller = ref.read(speechOutputProvider.notifier);
    final voices = await controller.voices(language: language);
    final selected = await controller.selectedVoice(language);
    if (!mounted || _language != language) return;
    setState(() {
      _voices = voices;
      _selected = selected;
    });
  }

  Future<void> _pick(SpeechVoice voice) async {
    final language = _language!;
    final controller = ref.read(speechOutputProvider.notifier);
    await controller.setVoice(language, voice);
    if (!mounted) return;
    setState(() => _selected = voice);
    // Örnek cümle SEÇİLEN DİLDEDİR: yabancı sese Türkçe cümle okutmak ne
    // telaffuzu ne tınıyı gösteriyordu.
    await ref
        .read(speechProvider.notifier)
        .preview(
          SpeechOutputController.voiceSample(language),
          languageCode: language,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final voices = _voices;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.speechVoicePickerTitle,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: AppWeight.strong),
            ),
            const SizedBox(height: 10),
            if (_languages.length > 1)
              Wrap(
                spacing: 8,
                children: [
                  for (final code in _languages)
                    radioChip(ChoiceChip(
                      label: Text(languageLabel(code)),
                      selected: _language == code,
                      onSelected: (_) {
                        if (_language == code) return;
                        setState(() => _language = code);
                        _load();
                      },
                    )),
                ],
              ),
            const SizedBox(height: 6),
            // Yükseklik sınırlı: uzun ses listesi levhayı ekranın dışına
            // taşırmasın, kendi içinde kaysın.
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.5,
              ),
              child: voices == null
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: DelayedSpinner()),
                    )
                  : voices.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(l10n.speechNoVoices),
                    )
                  : RadioGroup<String>(
                      groupValue: _selected?.id,
                      onChanged: (id) {
                        final voice = voices
                            .where((v) => v.id == id)
                            .firstOrNull;
                        if (voice != null) _pick(voice);
                      },
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: voices.length,
                        itemBuilder: (context, i) => RadioListTile<String>(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          value: voices[i].id,
                          title: Text(
                            voices[i].name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(voices[i].locale),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
