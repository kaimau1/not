part of '../settings_screen.dart';

/// Uygulama dili. Dil adları kendi dillerinde yazılır ("English"), yoksa
/// dilini bilmediği bir arayüzde doğru satırı bulamayan kullanıcı sıkışır.
/// Dil seçimi.
///
/// Az sayıda dilde radyo listesi en hızlı yol; liste büyüyünce (hedef 100+)
/// aynı düzen kullanılamaz — ayarlar sayfası yüz satırla dolar ve kullanıcı
/// kendi dilini kaydırarak arar. Bu yüzden eşiği aşınca ARAMALI bir alt
/// sayfaya geçilir. İki ayrı ekran yazmak yerine eşik konuldu: dört dilde
/// arama kutusu göstermek de gereksiz sürtünmedir.
class _LanguageSelector extends ConsumerWidget {
  const _LanguageSelector();

  /// Üzerinde aramalı sayfaya geçilen dil sayısı.
  static const _inlineLimit = 8;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 'system' yer tutucu: RadioGroup null'ı "seçim yok" saydığından sistem
    // seçeneği null değerle temsil edilemez.
    const system = 'system';
    final languages = supportedLanguages;
    final selected = ref.watch(localeProvider)?.toLanguageTag();
    final current = selected ?? system;

    if (languages.length > _inlineLimit) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(context.l10n.settingsLanguage),
        subtitle: Text(
          selected == null
              ? context.l10n.languageSystem
              : languageLabel(selected),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _pick(context, ref, languages, selected),
      );
    }

    return RadioGroup<String>(
      groupValue: current,
      onChanged: (value) =>
          ref.read(localeProvider.notifier).set(value == system ? null : value),
      child: Column(
        children: [
          RadioListTile<String>(
            contentPadding: EdgeInsets.zero,
            dense: true,
            value: system,
            title: Text(context.l10n.languageSystem),
          ),
          for (final entry in languages.entries)
            RadioListTile<String>(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: entry.key,
              title: Text(entry.value),
            ),
        ],
      ),
    );
  }

  Future<void> _pick(
    BuildContext context,
    WidgetRef ref,
    Map<String, String> languages,
    String? selected,
  ) async {
    final choice = await showAppSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) =>
          _LanguageSheet(languages: languages, selected: selected),
    );
    if (choice == null) return;
    ref.read(localeProvider.notifier).set(choice == 'system' ? null : choice);
  }
}

class _LanguageSheet extends StatefulWidget {
  const _LanguageSheet({required this.languages, required this.selected});

  final Map<String, String> languages;
  final String? selected;

  @override
  State<_LanguageSheet> createState() => _LanguageSheetState();
}

class _LanguageSheetState extends State<_LanguageSheet> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Arama hem dilin KENDİ adında hem de kodunda yapılır: kullanıcı
  /// "日本語" yazamıyorsa "ja" yazabilmeli. Büyük/küçük harf ve Türkçe
  /// ı/I/aksan farkı yok sayılır (F1.8: "turkce" → "Türkçe").
  bool _matches(MapEntry<String, String> entry) {
    if (_query.isEmpty) return true;
    final q = foldForSearch(_query);
    return foldForSearch(entry.value).contains(q) ||
        foldForSearch(entry.key).contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final matches = widget.languages.entries.where(_matches).toList();
    return Padding(
      // Klavye açılınca liste kısalsın, arama kutusu klavyenin altında kalmasın.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.75,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _controller,
                autofocus: true,
                onChanged: (value) => setState(() => _query = value.trim()),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: l10n.settingsLanguage,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  if (_query.isEmpty)
                    ListTile(
                      title: Text(l10n.languageSystem),
                      trailing: widget.selected == null
                          ? const Icon(Icons.check)
                          : null,
                      onTap: () => Navigator.pop(context, 'system'),
                    ),
                  for (final entry in matches)
                    ListTile(
                      title: Text(entry.value),
                      subtitle: Text(entry.key),
                      trailing: entry.key == widget.selected
                          ? const Icon(Icons.check)
                          : null,
                      onTap: () => Navigator.pop(context, entry.key),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Görünüm ayarlarının CANLI örneği: seçilen tema, yazı tipi ve yazı boyutu
/// gerçek bir notun görünümünde birlikte gösterilir.
///
/// Kullanıcı isteği 2026-08-16: "görünüm ayarlarına örnek metin". Eskiden tek
/// satırlık bir yazı boyutu önizlemesi vardı ([_TypographySection] içinde) ve
/// yalnız BOYUTU gösteriyordu; başlığın gövdeden ne kadar büyük olduğu, satır
/// içi biçimlerin (kalın, vurgu, altı çizili) seçilen yazı tipinde nasıl
/// durduğu, madde satırlarının nasıl göründüğü ancak notu açınca anlaşılıyordu.
///
/// Önizleme gerçek çizim yollarını kullanır — [richSpans] ile satır içi
/// biçimler, [applyNoteFont] ile yazı tipi, not paleti ile renkler. Kendi
/// başına bir "örnek görünüm" çizilseydi ayarların gerçek sonucundan
/// ayrışırdı.
class _AppearancePreview extends ConsumerWidget {
  const _AppearancePreview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final font = ref.watch(appFontProvider);
    final step = nearestFontScaleStep(ref.watch(fontScaleProvider));

    TextStyle styled(TextStyle? base) =>
        applyNoteFont(base ?? const TextStyle(), font);

    // Örneğin KENDİSİ sistem yazı ölçeğinden muaf; ayarın kendi kademesini
    // uygular ([_TypographySection]'daki önizlemeyle aynı gerekçe: seçici
    // büyüyünce satır taşıyordu).
    return MediaQuery.withNoTextScaling(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.appearancePreviewNoteTitle,
              textScaler: TextScaler.linear(step.scale),
              style: styled(theme.textTheme.titleMedium)
                  .copyWith(color: scheme.onSurface),
            ),
            const SizedBox(height: 6),
            Text.rich(
              TextSpan(
                children: richSpans(
                  l10n.appearancePreviewBody,
                  styled(theme.textTheme.bodyMedium)
                      .copyWith(color: scheme.onSurface),
                  palette: NoteColors.richPalette,
                  markerColor: const Color(0x00000000),
                ),
              ),
              textScaler: TextScaler.linear(step.scale),
            ),
            const SizedBox(height: 8),
            // Madde satırı: liste notlarının görünümü de yazı tipinden
            // etkileniyor, örnek onu da kapsamalı.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_box_outlined,
                  size: 16 * step.scale,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.appearancePreviewItem,
                    textScaler: TextScaler.linear(step.scale),
                    style: styled(theme.textTheme.bodyMedium)
                        .copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector();

  @override
  Widget build(BuildContext context) => const ThemeChoiceGrid();
}

/// Uzun bir ayar alanının içindeki küçük bölüm başlığı (Tema, Kartlar ve
/// listeler…). Aramada gizlenir (başlığı/anahtar kelimesi yok): arama tek
/// tek satırları getirir.
class _SubHeader extends StatelessWidget {
  const _SubHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 14, 0, 8),
    child: Text(
      text,
      style: sectionLabelStyle(context),
    ),
  );
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
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        // AKILLI DİNLEME (2026-10-19): sesli yakalama levhasındaki iki
        // anahtarın kalıcı karşılığı.
        SwitchListTile(
          key: const ValueKey('settings-voice-autostop'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.voiceAutoStop),
          subtitle: Text(l10n.voiceAutoStopInfo),
          value: ref.watch(voiceAutoStopProvider),
          onChanged: (v) => ref.read(voiceAutoStopProvider.notifier).set(v),
        ),
        // Bekleme süresi: yalnız "Sessizlikte bitir" açıkken anlamlı.
        if (ref.watch(voiceAutoStopProvider))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(child: Text(l10n.voiceSilenceLabel)),
                SegmentedButton<VoiceSilence>(
                  key: const ValueKey('settings-voice-silence'),
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                  ),
                  segments: [
                    ButtonSegment(
                      value: VoiceSilence.short,
                      label: Text(l10n.voiceSilenceShort),
                    ),
                    ButtonSegment(
                      value: VoiceSilence.normal,
                      label: Text(l10n.voiceSilenceNormal),
                    ),
                    ButtonSegment(
                      value: VoiceSilence.long,
                      label: Text(l10n.voiceSilenceLong),
                    ),
                  ],
                  selected: {ref.watch(voiceSilenceProvider)},
                  onSelectionChanged: (selection) => ref
                      .read(voiceSilenceProvider.notifier)
                      .set(selection.first),
                ),
              ],
            ),
          ),
        // İnternetsiz tanıma yalnız cihaz tanıması olan yerde (Android).
        if (!kIsWeb && Platform.isAndroid)
          SwitchListTile(
            key: const ValueKey('settings-voice-offline'),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.voiceOffline),
            subtitle: Text(l10n.voiceOfflineInfo),
            value: ref.watch(voiceOfflineProvider),
            onChanged: (v) => ref.read(voiceOfflineProvider.notifier).set(v),
          ),
        SwitchListTile(
          key: const ValueKey('settings-voice-smart'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.voiceSmartCommands),
          subtitle: Text(l10n.voiceSmartCommandsInfo),
          value: ref.watch(voiceSmartCommandsProvider),
          onChanged: (v) =>
              ref.read(voiceSmartCommandsProvider.notifier).set(v),
        ),
      ],
    );
  }
}

/// Yazı boyutu çarpanı.
///
/// KÖK NEDEN (kaydırıcı parmağın altından kaçıyordu): `fontScaleProvider`
/// `app.dart`'ta TÜM uygulamanın `textScaler`'ını sürüyor. Her `onChanged`
/// anında yazılınca Ayarlar'ın kendisi de yeniden boyutlanıyor: kaydırıcının
/// ÜSTÜNDEKİ satırlar uzayıp kısaldığı için kaydırıcı dikeyde kayıyor, "%100"
/// → "%95" etiketi daraldığı için de yatayda. İki önlem birlikte gerekiyor:
///  1. gerçek ayar yalnız parmak KALKINCA yazılır (`onChangeEnd`); sürüklerken
///     değer yerelde tutulur, böylece hiçbir şey yeniden akmaz,
///  2. denetimin kendisi ölçekten muaf (`withNoTextScaling`) ve yüzde etiketi
///     sabit genişlikte — yoksa yazılan değer denetimi kendi altından kaydırır.
/// Canlı geri bildirim kaybolmasın diye altta sabit yükseklikte bir önizleme
/// satırı sürüklenen değerle ölçeklenir (yüksekliği sabit olduğundan
/// büyümesi üstteki kaydırıcıyı oynatmaz).

/// TİPOGRAFİ TEK BLOKTA: yazı tipi + yazı boyutu + ORTAK önizleme.
///
/// KÖK NEDEN (kullanıcı: "ayarlarda font seçimi vs çok dağınık"): Görünüm
/// alanı iki ayrı kartla açılıyordu ve ikincisi katalogdaki **19 yazı tipini
/// çip çip ekrana seriyordu** — tek başına dört-beş satır kaplayan, altındaki
/// bütün ayarları (liste, hızlı not, kart önizlemesi, zemin, koyu tema
/// zamanlaması) aşağı iten bir duvar. Üstelik her iki kartın da kendi
/// önizlemesi/açıklaması vardı; "yazı" ile ilgili tek bir iş iki yere
/// bölünmüştü.
///
/// Artık tek satır: yazı tipi bir SATIR (seçilen adı kendi yazı tipiyle
/// gösterir, dokununca öbeklenmiş bir levha açar), yazı boyutu dört kademe,
/// altta ikisini birlikte gösteren tek önizleme.
class _TypographySection extends ConsumerWidget {
  const _TypographySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final font = ref.watch(appFontProvider);
    final step = nearestFontScaleStep(ref.watch(fontScaleProvider));
    final bodyStyle = theme.textTheme.bodyMedium;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.text_fields, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(l10n.appFontSetting)),
          ],
        ),
        const SizedBox(height: 8),
        // Yazı tipi satırı: seçili ad KENDİ yazı tipiyle yazılır.
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showAppFontSheet(context, ref),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    font,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: applyNoteFont(
                      const TextStyle(fontSize: 16),
                      font,
                    ).copyWith(color: scheme.onSurface),
                  ),
                ),
                Icon(
                  Icons.unfold_more,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.format_size, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(l10n.fontSize)),
          ],
        ),
        const SizedBox(height: 8),
        // Seçicinin KENDİSİ ölçeklenmez: "Çok büyük" seçildiğinde düğmelerin
        // de büyümesi satırı taşırıyordu. Önizleme ölçeği kendi uygular.
        MediaQuery.withNoTextScaling(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final value in FontScaleStep.values)
                radioChip(
                  ChoiceChip(
                    label: Text(_fontScaleLabel(l10n, value)),
                    selected: value == step,
                    onSelected: (_) =>
                        ref.read(fontScaleProvider.notifier).setStep(value),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // ORTAK önizleme: seçilen yazı tipi VE boyut birlikte görünür.
        // Kutu en büyük kademeye göre boyutlanır ki seçim değişince
        // yüksekliği zıplamasın.
        MediaQuery.withNoTextScaling(
          child: SizedBox(
            height:
                (bodyStyle?.fontSize ?? 14) * FontScaleStep.xlarge.scale * 1.6,
            width: double.infinity,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                l10n.fontSizePreview,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textScaler: TextScaler.linear(step.scale),
                style: applyNoteFont(
                  bodyStyle ?? const TextStyle(),
                  font,
                ).copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.appFontInfo,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        // F15.1 — varsayılan KAPALI: yazı boyutu tüm telefonlarda sabit
        // (2026-08-07 kararı). Açıkken sistem ölçeği ve kalın metin geçer.
        SwitchListTile(
          key: const ValueKey('settings-follow-system-text'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.followSystemTextScale),
          subtitle: Text(l10n.followSystemTextScaleInfo),
          value: ref.watch(followSystemTextScaleProvider),
          onChanged: (v) =>
              ref.read(followSystemTextScaleProvider.notifier).set(v),
        ),
      ],
    );
  }
}

/// Yazı tipi seçme levhası — TEMA LEVHASI gibi (bkz. `showThemePickerSheet`):
/// alçak, perdesiz; her seçenek KENDİ yazı tipiyle "Aa" önizlemesi gösterir,
/// dokunulan tip anında uygulanır, üstteki ekran canlı değişir. "Vazgeç"
/// açılıştaki tipe döner.
Future<void> _showAppFontSheet(BuildContext context, WidgetRef ref) {
  preloadRemainingNoteFonts();
  final before = ref.read(appFontProvider);
  final scroll = ScrollController(
    initialScrollOffset: math.max(
      0,
      (kCatalogFonts.indexWhere((f) => f.id == before) - 1) * 88.0,
    ),
  );
  return showAppSheet<void>(
    context: context,
    barrierColor: Colors.transparent,
    showDragHandle: true,
    builder: (sheetContext) {
      final l10n = sheetContext.l10n;
      return Consumer(
        builder: (context, ref, _) {
          final current = ref.watch(appFontProvider);
          return SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 8, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.appFontSetting,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        if (current != before)
                          TextButton(
                            key: const ValueKey('font-sheet-revert'),
                            onPressed: () {
                              ref.read(appFontProvider.notifier).set(before);
                              Navigator.pop(context);
                            },
                            child: Text(l10n.cancel),
                          ),
                        FilledButton.tonal(
                          key: const ValueKey('font-sheet-done'),
                          onPressed: () => Navigator.pop(context),
                          child: Text(l10n.ok),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 104,
                    child: ListView.separated(
                      key: const ValueKey('font-sheet-list'),
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      controller: scroll,
                      itemCount: kCatalogFonts.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, i) => SizedBox(
                        width: 80,
                        child: _FontChoiceCard(
                          key: ValueKey('font-sheet-${kCatalogFonts[i].id}'),
                          font: kCatalogFonts[i],
                          selected: kCatalogFonts[i].id == current,
                          onTap: () => ref
                              .read(appFontProvider.notifier)
                              .set(kCatalogFonts[i].id!),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  ).whenComplete(scroll.dispose);
}

/// Tek yazı tipi seçeneği: kendi yazı tipiyle "Aa" + ad ([ThemeChoiceCard]'ın
/// çerçevesiyle aynı).
class _FontChoiceCard extends StatelessWidget {
  const _FontChoiceCard({
    super.key,
    required this.font,
    required this.selected,
    required this.onTap,
  });

  final NoteFontOption font;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: font.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              height: 62,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? scheme.primary : scheme.outlineVariant,
                  width: selected ? 2.5 : 1,
                ),
              ),
              child: Text(
                'Aa',
                style: applyNoteFont(
                  TextStyle(fontSize: 26, color: scheme.onSurface),
                  font.id,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              font.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: selected ? AppWeight.strong : FontWeight.w500,
                color: selected ? scheme.primary : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Yazı boyutu kademelerinin görünen adları.
///
/// KÖK NEDEN — eskiden 0.85–1.4 arası sürekli bir KAYDIRICIydı: "%107" gibi
/// hatırlanmayan değerler seçilebiliyor, iki cihazda aynı boyutu tutturmak
/// imkânsız oluyordu (kullanıcı isteği 2026-08-07). Kademeler tek dokunuşla
/// seçiliyor ve her cihazda aynı dört görünümü veriyor. Kaydırıcı döneminden
/// kalan değer en yakın kademede görünür — kimsenin boyutu güncellemede
/// kendiliğinden değişmez.
String _fontScaleLabel(AppLocalizations l10n, FontScaleStep step) =>
    switch (step) {
      FontScaleStep.small => l10n.fontSizeSmall,
      FontScaleStep.medium => l10n.fontSizeMedium,
      FontScaleStep.large => l10n.fontSizeLarge,
      FontScaleStep.xlarge => l10n.fontSizeXLarge,
    };

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
              actionChip(
                ActionChip(
                  avatar: const Icon(Icons.dark_mode_outlined, size: 16),
                  label: Text(_format(schedule.startMinutes)),
                  onPressed: () => _pick(context, ref, isStart: true),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward, size: 14),
              ),
              actionChip(
                ActionChip(
                  avatar: const Icon(Icons.light_mode_outlined, size: 16),
                  label: Text(_format(schedule.endMinutes)),
                  onPressed: () => _pick(context, ref, isStart: false),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// **KARTTA GÖRÜNENLER** satırı (F14.2, 2026-10-31): kaç anahtarın açık
/// olduğunu söyler, dokununca canlı kart örnekli alt levhayı açar.
class CardElementsRow extends ConsumerWidget {
  const CardElementsRow({super.key});

  static final _switches = <NotifierProvider<BoolPrefNotifier, bool>>[
    cardRichPreviewProvider,
    cardHideSensitiveProvider,
    cardShowProgressProvider,
    cardShowCheckedProvider,
    cardShowMoreCountProvider,
    cardShowStatusIconsProvider,
    cardShowTagProvider,
    cardShowDateProvider,
    cardShowMediaProvider,
    cardShowFilesProvider,
    cardShowFolderProvider,
    cardShowPaperProvider,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final on = _switches.where(ref.watch).length;
    return ListTile(
      key: const ValueKey('settings-card-elements'),
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.view_agenda_outlined),
      title: Text(l10n.cardElementsHeader),
      subtitle: Text(l10n.cardElementsSummary(on, _switches.length)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => showAppSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => const CardElementsSheet(),
      ),
    );
  }
}

/// Kart anahtarlarının levhası: üstte SABİT canlı kart örneği (anahtar
/// değişince aynı anda değişir — kart sağlayıcıları izliyor), altında
/// kaydırılan anahtarlar.
class CardElementsSheet extends ConsumerWidget {
  const CardElementsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final sample = Note(
      id: 'card-elements-preview',
      type: NoteType.checklist,
      title: l10n.cardElementsSampleTitle,
      items: [
        for (var i = 0; i < 6; i++)
          NoteItem(
            id: 'p$i',
            text: l10n.cardElementsSampleItem(i + 1),
            checked: i < 2,
          ),
      ],
      tags: [l10n.cardElementsSampleTag],
      pinned: true,
      createdAt: now,
      updatedAt: now,
    );
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              l10n.cardElementsHeader,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          // Örnek kart: dokunulmaz (açacak gerçek not yok).
          Container(
            key: const ValueKey('card-elements-preview'),
            color: scheme.surfaceContainerLow,
            padding: const EdgeInsets.symmetric(vertical: 12),
            alignment: Alignment.center,
            child: SizedBox(
              width: 200,
              child: IgnorePointer(child: NoteCard(note: sample)),
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                16 + MediaQuery.paddingOf(context).bottom,
              ),
              children: [
                const _CardRichPreviewSwitch(),
                const _CardHideSensitiveSwitch(),
                _PrefSwitch(
                  key: const ValueKey('settings-card-progress'),
                  provider: cardShowProgressProvider,
                  icon: Icons.linear_scale,
                  title: l10n.cardShowProgress,
                  subtitle: l10n.cardShowProgressInfo,
                ),
                _PrefSwitch(
                  key: const ValueKey('settings-card-checked'),
                  provider: cardShowCheckedProvider,
                  icon: Icons.check_box_outlined,
                  title: l10n.cardShowChecked,
                  subtitle: l10n.cardShowCheckedInfo,
                ),
                _PrefSwitch(
                  provider: cardShowMoreCountProvider,
                  icon: Icons.more_horiz,
                  title: l10n.cardShowMoreCount,
                ),
                _PrefSwitch(
                  provider: cardShowStatusIconsProvider,
                  icon: Icons.push_pin_outlined,
                  title: l10n.cardShowStatusIcons,
                  subtitle: l10n.cardShowStatusIconsInfo,
                ),
                _PrefSwitch(
                  provider: cardShowTagProvider,
                  icon: Icons.tag,
                  title: l10n.cardShowTag,
                ),
                _PrefSwitch(
                  provider: cardShowDateProvider,
                  icon: Icons.schedule,
                  title: l10n.cardShowDate,
                ),
                _PrefSwitch(
                  provider: cardShowMediaProvider,
                  icon: Icons.image_outlined,
                  title: l10n.cardShowMedia,
                ),
                _PrefSwitch(
                  provider: cardShowFilesProvider,
                  icon: Icons.attach_file,
                  title: l10n.cardShowFiles,
                  subtitle: l10n.cardShowFilesInfo,
                ),
                _PrefSwitch(
                  provider: cardShowFolderProvider,
                  icon: Icons.folder_outlined,
                  title: l10n.cardShowFolder,
                  subtitle: l10n.cardShowFolderInfo,
                ),
                _PrefSwitch(
                  provider: cardShowPaperProvider,
                  icon: AppIcons.notebook,
                  title: l10n.cardShowPaper,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
