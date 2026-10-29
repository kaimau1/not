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
              style: styled(
                theme.textTheme.titleMedium,
              ).copyWith(color: scheme.onSurface),
            ),
            const SizedBox(height: 6),
            Text.rich(
              TextSpan(
                children: richSpans(
                  l10n.appearancePreviewBody,
                  styled(
                    theme.textTheme.bodyMedium,
                  ).copyWith(color: scheme.onSurface),
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
                    style: styled(
                      theme.textTheme.bodyMedium,
                    ).copyWith(color: scheme.onSurfaceVariant),
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

class _ThemeSelector extends ConsumerWidget {
  const _ThemeSelector();

  /// TEMA KARTLARI (kullanıcı isteği 2026-09-26, ekran görüntüsü): eski
  /// seçici dört ETİKETSİZ simgeydi — telefon genişliğinde etiketler sığmadığı
  /// için düşüyordu ve "kitap" simgesinin Kağıt tema olduğu anlaşılmıyordu.
  /// Artık her seçenek küçük bir ÖNİZLEME (o temanın zemini, kartı ve yazı
  /// rengi) + altında adı; seçili kart birincil renkle çerçevelenir.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final choice = ref.watch(themeChoiceProvider);
    final font = ref.watch(appFontProvider);
    final light = AppTheme.light(font: font).colorScheme;
    final dark = AppTheme.dark(font: font).colorScheme;
    final paper = AppTheme.paper(font: font).colorScheme;
    final offWhite = AppTheme.offWhite(font: font).colorScheme;
    final options = <(AppThemeChoice, String, List<ColorScheme>)>[
      (AppThemeChoice.system, l10n.themeSystem, [light, dark]),
      (AppThemeChoice.light, l10n.themeLight, [light]),
      (AppThemeChoice.dark, l10n.themeDark, [dark]),
      (AppThemeChoice.offWhite, l10n.themeOffWhite, [offWhite]),
      (AppThemeChoice.paper, l10n.themePaper, [paper]),
    ];
    return Row(
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _ThemeCard(
              label: options[i].$2,
              schemes: options[i].$3,
              selected: choice == options[i].$1,
              onTap: () =>
                  ref.read(themeChoiceProvider.notifier).set(options[i].$1),
            ),
          ),
        ],
      ],
    );
  }
}

/// Tek tema seçeneği: mini önizleme + ad. [schemes] iki tane ise (Sistem)
/// önizleme ortadan açık/koyu ikiye bölünür.
class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.label,
    required this.schemes,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final List<ColorScheme> schemes;
  final bool selected;
  final VoidCallback onTap;

  Widget _preview(ColorScheme c) => ColoredBox(
    color: c.surface,
    child: Padding(
      padding: const EdgeInsets.all(6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 22, height: 4, color: c.onSurface),
              const SizedBox(height: 4),
              Container(
                width: 30,
                height: 3,
                color: c.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 3),
              Container(width: 18, height: 3, color: c.primary),
            ],
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              height: 62,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? scheme.primary : scheme.outlineVariant,
                  width: selected ? 2.5 : 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Row(
                      children: [
                        for (final c in schemes) Expanded(child: _preview(c)),
                      ],
                    ),
                    if (selected)
                      Positioned(
                        right: 4,
                        top: 4,
                        child: CircleAvatar(
                          radius: 8,
                          backgroundColor: scheme.primary,
                          child: Icon(
                            Icons.check,
                            size: 11,
                            color: scheme.onPrimary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? scheme.primary : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
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
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
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
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
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
                      const TextStyle(fontSize: 15.5),
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
                ChoiceChip(
                  label: Text(_fontScaleLabel(l10n, value)),
                  selected: value == step,
                  onSelected: (_) =>
                      ref.read(fontScaleProvider.notifier).setStep(value),
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
      ],
    );
  }
}

/// Yazı tipi seçme levhası: katalog ÖBEKLENMİŞ (sade / kitap / daktilo /
/// el yazısı) ve her satır kendi yazı tipiyle yazılıyor.
Future<void> _showAppFontSheet(BuildContext context, WidgetRef ref) {
  final l10n = context.l10n;
  String groupLabel(NoteFontGroup group) => switch (group) {
    NoteFontGroup.sans => l10n.fontGroupSans,
    NoteFontGroup.serif => l10n.fontGroupSerif,
    NoteFontGroup.mono => l10n.fontGroupMono,
    NoteFontGroup.hand => l10n.fontGroupHand,
  };
  return showAppSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) {
      final scheme = Theme.of(sheetContext).colorScheme;
      return Consumer(
        builder: (context, ref, _) {
          final current = ref.watch(appFontProvider);
          return ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Text(
                  l10n.appFontSetting,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              for (final group in NoteFontGroup.values) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                  child: Text(
                    groupLabel(group),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                for (final font in kCatalogFonts)
                  if (font.group == group)
                    ListTile(
                      dense: true,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      selected: font.id == current,
                      title: Text(
                        font.id == kAppDefaultFont
                            ? '${font.label} · ${l10n.appFontDefaultSuffix}'
                            : font.label,
                        // Satır aynı zamanda ÖRNEK: seçmeden önce nasıl
                        // duracağı görünür.
                        style: applyNoteFont(
                          const TextStyle(fontSize: 16),
                          font.id,
                        ),
                      ),
                      trailing: font.id == current
                          ? Icon(Icons.check, size: 20, color: scheme.primary)
                          : null,
                      onTap: () =>
                          ref.read(appFontProvider.notifier).set(font.id!),
                    ),
              ],
            ],
          );
        },
      );
    },
  );
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
