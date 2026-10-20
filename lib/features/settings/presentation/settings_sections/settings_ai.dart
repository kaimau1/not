part of '../settings_screen.dart';

/// Dahili AI durumu: kendi anahtarı varsa "sınırsız", premium'sa "premium",
/// değilse bugünkü kalan ücretsiz hak gösterilir.
class _BuiltInAiStatus extends ConsumerWidget {
  const _BuiltInAiStatus();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final hasKey = (ref.watch(activeApiKeyProvider).value ?? '').isNotEmpty;
    final premium = ref.watch(premiumProvider).value ?? false;
    final remaining = ref.watch(freeAiRemainingProvider);

    final (icon, text) = hasKey
        // Kendi anahtarı varsa hesap türü fark etmez: maliyet kullanıcıda,
        // sınır yok. Yerel hesap uyarısı bu durumda yanıltıcı olurdu.
        ? (Icons.key, l10n.aiBuiltInByok)
        : ref.watch(isAnonymousProvider)
        ? (Icons.phonelink_lock_outlined, l10n.localAccountInfo)
        : premium
        ? (Icons.workspace_premium_outlined, l10n.aiBuiltInPremium(remaining))
        : (Icons.bolt_outlined, l10n.aiBuiltInRemaining(remaining));

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      // Satır artık Premium sayfasına götürüyor: kota/puan farkının ne
      // kazandırdığı hiçbir yerde anlatılmıyordu (premium çalışması).
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => context.push('/premium'),
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
            Icon(Icons.chevron_right, size: 16, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

/// AI bölümündeki form alanlarının ORTAK görünümü.
///
/// Genel tema alanları yalnız dolgu rengiyle çiziyor (kenarlık yok); kâğıt
/// temada o dolgu kart zeminiyle neredeyse aynı olduğundan açılır listeler ve
/// anahtar kutusu "sayfaya dağılmış yazılar" gibi duruyordu. Burada görünür
/// kenarlık + tek tip iç boşluk verilir, alanların nerede başlayıp bittiği
/// belli olur.
InputDecoration _aiFieldDecoration(
  BuildContext context, {
  required String label,
  String? hint,
}) {
  final scheme = Theme.of(context).colorScheme;
  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    filled: true,
    fillColor: scheme.surface,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    border: border(scheme.outlineVariant),
    enabledBorder: border(scheme.outlineVariant),
    focusedBorder: border(scheme.primary, 1.6),
  );
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
    final provider = ref.read(activeProviderProvider);
    try {
      final valid = await ref.read(geminiServiceProvider).validateKey(key);
      if (!valid) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.apiKeyInvalid)));
        return;
      }
      await ref.read(apiKeyStoreProvider).save(provider, key);
      _invalidateKeys(provider);
      _controller.clear();
      messenger.showSnackBar(SnackBar(content: Text(l10n.apiKeyValid)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _removeKey() async {
    final provider = ref.read(activeProviderProvider);
    await ref.read(apiKeyStoreProvider).clear(provider);
    _invalidateKeys(provider);
  }

  /// Anahtar değişince model listesi de tazelenmeli: katalog anahtarla
  /// çekiliyor, eski liste yanlış sağlayıcıya ait kalırdı.
  void _invalidateKeys(AiProvider provider) {
    ref.invalidate(activeApiKeyProvider);
    ref.invalidate(providerApiKeyProvider(provider));
    ref.invalidate(availableModelsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = ref.watch(activeProviderProvider);
    final storedKey = ref.watch(activeApiKeyProvider).value;
    final hasKey = storedKey != null && storedKey.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<AiProvider>(
          initialValue: provider,
          isExpanded: true,
          decoration: _aiFieldDecoration(context, label: l10n.aiProvider),
          items: [
            for (final option in AiProvider.values)
              DropdownMenuItem(
                value: option,
                child: Text(
                  option.freeTier
                      ? '${option.label} · ${l10n.freeTierBadge}'
                      : option.label,
                ),
              ),
          ],
          onChanged: (value) {
            if (value == null) return;
            ref.read(activeProviderProvider.notifier).set(value);
            // Sağlayıcı değişti: anahtar ve model listesi o sağlayıcıya ait
            // olmalı, önceki sağlayıcının önbelleği gösterilmemeli.
            _controller.clear();
            _invalidateKeys(value);
          },
        ),
        const SizedBox(height: 8),
        Text(
          l10n.aiProviderInfo,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        // Sağlayıcı bloğu ile anahtar bloğu arasına ayırıcı: ikisi arka arkaya
        // duran metin yığını gibi okunuyordu.
        const SizedBox(height: 14),
        const Divider(height: 1),
        const SizedBox(height: 14),
        if (hasKey)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Chip(
                  avatar: const Icon(Icons.key, size: 16),
                  label: Text('${provider.label}: ${l10n.apiKeySavedBadge}'),
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
          decoration: _aiFieldDecoration(
            context,
            label: '${provider.label} · ${l10n.apiKeyFieldLabel}',
            // İpucu sağlayıcının anahtar biçimi: yanlış sağlayıcıya
            // yapıştırıldığında kullanıcı hatayı beklemeden görür.
            hint: provider.keyHint,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.geminiApiKeyInfo,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: () => launchUrl(
              Uri.parse(provider.keyUrl),
              mode: LaunchMode.externalApplication,
            ),
            icon: const Icon(Icons.open_in_new, size: 18),
            label: Text(l10n.getApiKey),
          ),
        ),
        const SizedBox(height: 4),
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
        const SizedBox(height: 10),
        const Divider(height: 1),
        const _AiDiagnosticsTile(),
      ],
    );
  }
}

/// Dahili AI'ın son ham hataları. Kullanıcıya gösterilen mesajlar sadeleştirilmiş
/// olduğundan ("şu an yanıt veremiyor"), gerçek neden yalnız burada görünür.
class _AiDiagnosticsTile extends StatefulWidget {
  const _AiDiagnosticsTile();

  @override
  State<_AiDiagnosticsTile> createState() => _AiDiagnosticsTileState();
}

class _AiDiagnosticsTileState extends State<_AiDiagnosticsTile> {
  @override
  Widget build(BuildContext context) {
    final entries = AiDiagnostics.entries;
    final scheme = Theme.of(context).colorScheme;
    return _ExpandTile(
      title: Text(context.l10n.aiDiagnostics),
      subtitle: Text(
        entries.isEmpty
            ? context.l10n.aiDiagnosticsEmpty
            : context.l10n.aiDiagnosticsCount(entries.length),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      onExpansionChanged: (_) => setState(() {}),
      children: [
        for (final e in entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: SelectableText(
              e,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        if (entries.isNotEmpty)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () => setState(AiDiagnostics.clear),
              icon: const Icon(Icons.delete_outline, size: 18),
              label: Text(context.l10n.clear),
            ),
          ),
      ],
    );
  }
}

/// Model seçimi: **satır + tam boy seçim levhası**.
///
/// KÖK NEDEN (kullanıcı üç kez bildirdi, 2026-08-09: "ayarlarda model seçim
/// ekranını 3. kez yazıyorum, hâlâ değişen bir şey yok"): burada beş tane
/// `DropdownButtonFormField` alt alta duruyordu. Her biri sağlayıcının
/// ONLARCA modelini iki satırlık (ad + gerekçe) öğelerle listeliyor; telefonda
/// açılan menü ekranı kaplıyor, aranan model ancak uzun uzun kaydırarak
/// bulunuyor ve beş kutu üst üste gelince bölüm bir duvara dönüşüyordu.
///
/// Şimdi her kullanım alanı TEK SATIR: solda işin adı, altında o an seçili
/// model. Dokununca arama kutulu, "Önerilen" ve "Diğer" diye ayrılmış bir
/// levha açılır — model adı yazılarak bulunur, seçilince levha kapanır.
Widget _modelPickerTile({
  required BuildContext context,
  required String label,
  required List<AiModel> models,
  required String? value,
  required String autoLabel,
  required String recommendedLabel,
  required ValueChanged<String?> onChanged,
  bool allowShowAll = false,
}) {
  final scheme = Theme.of(context).colorScheme;
  // Kayıtlı model artık listede yoksa (kaldırılmış olabilir ya da sağlayıcı
  // değişmiş olabilir) yine göster; zincir zaten çalışan bir modele düşer.
  final items = value != null && !models.any((m) => m.id == value)
      ? [AiModel(id: value, label: value), ...models]
      : models;
  final current = value == null
      ? autoLabel
      : _ModelSelectors._friendlyModel(
          items.firstWhere(
            (m) => m.id == value,
            orElse: () => AiModel(id: value, label: value),
          ),
        );
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final picked = await showAppSheet<_ModelChoice>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            showDragHandle: true,
            builder: (_) => _ModelPickerSheet(
              title: label,
              models: items,
              value: value,
              autoLabel: autoLabel,
              recommendedLabel: recommendedLabel,
              allowShowAll: allowShowAll,
            ),
          );
          if (picked != null) onChanged(picked.id);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      current,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.expand_more, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Levhadan dönen seçim. `null` DEĞERİ "Otomatik" demek olduğu için levhanın
/// "iptal" ile "otomatik"i ayırt edebilmesi gerekiyor — sarmalayıcı tip bunu
/// sağlar (iptalde levha null döner, "Otomatik"te `_ModelChoice(null)`).
class _ModelChoice {
  const _ModelChoice(this.id);

  final String? id;
}

/// Model seçim levhası: arama + "Önerilen" / "Diğer" grupları.
class _ModelPickerSheet extends ConsumerStatefulWidget {
  const _ModelPickerSheet({
    required this.title,
    required this.models,
    required this.value,
    required this.autoLabel,
    required this.recommendedLabel,
    this.allowShowAll = false,
  });

  final String title;
  final List<AiModel> models;
  final String? value;
  final String autoLabel;
  final String recommendedLabel;

  /// "Tümünü göster" anahtarı çizilsin mi? Yalnız METİN seçicisinde: orada
  /// liste uygulamanın kullandığı sohbet modelleriyle sınırlı, kullanıcı
  /// sağlayıcısında ne varsa görmek isteyebilir (kullanıcı isteği
  /// 2026-08-09: "tüm modeller çekilmeli"). Seslendirme seçicisi zaten
  /// kendi türünü gösteriyor.
  final bool allowShowAll;

  @override
  ConsumerState<_ModelPickerSheet> createState() => _ModelPickerSheetState();
}

class _ModelPickerSheetState extends ConsumerState<_ModelPickerSheet> {
  final _search = TextEditingController();
  String _query = '';
  bool _showAll = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(AiModel m) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return m.id.toLowerCase().contains(q) ||
        m.label.toLowerCase().contains(q) ||
        _ModelSelectors._friendlyModel(m).toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    // "Tümünü göster" açıksa katalogtaki HER model listelenir (aynı
    // önbellekten gelir, ikinci bir ağ isteği yok).
    final source = _showAll
        ? (ref.watch(allModelsProvider).value ?? widget.models)
        : widget.models;
    final shown = [
      for (final m in source)
        if (_matches(m)) m,
    ];
    final recommended = [
      for (final m in shown)
        if (m.recommended) m,
    ];
    final others = [
      for (final m in shown)
        if (!m.recommended) m,
    ];

    // `RadioListTile.groupValue`/`onChanged` KULLANILMAZ (kullanımdan kalktı):
    // seçili değer ve geri çağrı dıştaki [RadioGroup]'tan gelir — dil
    // seçicisiyle aynı desen.
    Widget tile(AiModel m) => RadioListTile<String?>(
      value: m.id,
      dense: true,
      title: Row(
        children: [
          Flexible(
            child: Text(
              _ModelSelectors._friendlyModel(m),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (m.recommended) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                widget.recommendedLabel,
                style: TextStyle(
                  fontSize: 10,
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: m.note == null ? null : Text(m.note!),
    );

    Widget header(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              widget.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v.trim()),
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(Icons.search, size: 20),
                hintText: l10n.aiModelSearch,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          if (widget.allowShowAll)
            SwitchListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              title: Text(l10n.aiModelShowAll),
              subtitle: Text(l10n.aiModelShowAllInfo),
              value: _showAll,
              onChanged: (v) => setState(() => _showAll = v),
            ),
          Flexible(
            child: RadioGroup<String?>(
              groupValue: widget.value,
              onChanged: (v) => Navigator.pop(context, _ModelChoice(v)),
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 12),
                children: [
                  RadioListTile<String?>(
                    value: null,
                    dense: true,
                    title: Text(widget.autoLabel),
                    subtitle: Text(l10n.aiModelAutoInfo),
                  ),
                  if (recommended.isNotEmpty) ...[
                    header(widget.recommendedLabel),
                    for (final m in recommended) tile(m),
                  ],
                  if (others.isNotEmpty) ...[
                    header(l10n.aiModelOthers),
                    for (final m in others) tile(m),
                  ],
                  if (shown.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(child: Text(l10n.aiModelNoMatch)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
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
    // Anahtarı olmayanlarda da gösterilir: `availableModels()` anahtar yoksa
    // uygulamanın yerleşik tercih listesini döndürüyor ve dahili (Firebase)
    // yol da seçilen modeli uyguluyor. Eskiden buradaki anahtar koşulu
    // seçiciyi anahtarsız kullanıcıdan tamamen gizliyordu.
    //
    // Liste önbellekli sağlayıcıdan (availableModelsProvider) izlenir; inline
    // FutureBuilder her rebuild'de yeni bir future kurup bölümü boşaltıp
    // yeniden doldurduğu için ayarlar sayfası zıplıyordu (madde 3).
    final models =
        ref.watch(availableModelsProvider).value ?? const <AiModel>[];
    if (models.isEmpty) return const SizedBox.shrink();
    final selected = ref.watch(aiTaskModelsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final task in AiTask.values) ...[
          _modelPickerTile(
            context: context,
            label: _taskLabel(l10n, task),
            models: models,
            value: selected[task],
            autoLabel: l10n.aiModelAuto,
            recommendedLabel: l10n.recommendedModel,
            allowShowAll: true,
            onChanged: (v) =>
                ref.read(aiTaskModelsProvider.notifier).set(task, v),
          ),
        ],
        const SizedBox(height: 4),
        Text(
          l10n.aiModelsInfo,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  static String _taskLabel(AppLocalizations l10n, AiTask task) =>
      switch (task) {
        AiTask.general => l10n.aiModelChat,
        AiTask.document => l10n.aiModelDocument,
        AiTask.podcast => l10n.aiModelPodcast,
        AiTask.translate => l10n.aiModelTranslate,
        AiTask.voice => l10n.aiModelVoice,
      };

  /// Ham model kimliği yerine okunur ad: "gemini-3.5-flash" → "3.5 Flash".
  /// Sağlayıcı bir görünen ad verdiyse (OpenAI/Anthropic veriyor) o kullanılır;
  /// yalnızca Gemini gibi ham kimlik dönen sağlayıcılarda güzelleştirilir.
  static String _friendlyModel(AiModel model) {
    if (model.label != model.id) return model.label;
    var name = model.id.replaceFirst('gemini-', '').replaceAll('-preview', '');
    final lower = name.toLowerCase();
    final hint = lower.contains('flash-lite')
        ? 'en hızlı'
        : lower.contains('flash')
        ? 'hızlı'
        : lower.contains('pro')
        ? 'en güçlü'
        : lower.contains('live')
        ? 'canlı ses'
        : null;
    // "3.5-flash" → "3.5 Flash": tire boşluk olur, parçalar büyük harfle başlar.
    name = name
        .split('-')
        .map((p) => p.isEmpty ? p : '${p[0].toUpperCase()}${p.substring(1)}')
        .join(' ');
    return hint == null ? name : '$name — $hint';
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
          Wrap(
            spacing: 8,
            children: [
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
              // Ayar ile ekran birbirine bağlansın: brifing buradan da açılır.
              ActionChip(
                avatar: const Icon(Icons.wb_sunny_outlined, size: 16),
                label: Text(context.l10n.openBriefing),
                onPressed: () => context.push('/briefing'),
              ),
            ],
          ),
      ],
    );
  }
}

/// AI alanındaki anahtar satırlarının ORTAK biçimi.
///
/// Dördü de ayrı ayrı `SwitchListTile` kuruyordu: başlıklar gövde punto,
/// açıklamalar aynı puntoda ve tam genişlikte olduğundan satırlar birbirine
/// karışıyor, hangi açıklamanın hangi anahtara ait olduğu okunmuyordu
/// (kullanıcı: "ai kısmında görünüm bozuk ve karışık"). Tek yerde: başlık
/// vurgulu, açıklama küçük ve soluk, anahtar sağda hizalı.
class _AiSwitchTile extends StatelessWidget {
  const _AiSwitchTile({
    required this.title,
    required this.info,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String info;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    info,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.3,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

class _AutoTagSwitch extends ConsumerWidget {
  const _AutoTagSwitch();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return _AiSwitchTile(
      title: l10n.autoTagSetting,
      info: l10n.autoTagSettingInfo,
      value: ref.watch(autoTagProvider),
      onChanged: (value) => ref.read(autoTagProvider.notifier).set(value),
    );
  }
}

class _AutoTitleSwitch extends ConsumerWidget {
  const _AutoTitleSwitch();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return _AiSwitchTile(
      title: l10n.autoTitleSetting,
      info: l10n.autoTitleSettingInfo,
      value: ref.watch(autoTitleProvider),
      onChanged: (value) => ref.read(autoTitleProvider.notifier).set(value),
    );
  }
}

/// Sesli asistan yanıtını yüksek sesle okusun mu? (Asistan panelindeki
/// "sustur" düğmesiyle aynı anahtar.)
class _AssistantVoiceSwitch extends ConsumerWidget {
  const _AssistantVoiceSwitch();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return _AiSwitchTile(
      title: l10n.assistantVoiceSetting,
      info: l10n.assistantVoiceSettingInfo,
      value: ref.watch(assistantVoiceProvider),
      onChanged: (value) =>
          ref.read(assistantVoiceProvider.notifier).set(value),
    );
  }
}

class _AiSkipCheckedSwitch extends ConsumerWidget {
  const _AiSkipCheckedSwitch();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return _AiSwitchTile(
      title: l10n.aiSkipCheckedSetting,
      info: l10n.aiSkipCheckedInfo,
      value: ref.watch(aiSkipCheckedProvider),
      onChanged: (value) => ref.read(aiSkipCheckedProvider.notifier).set(value),
    );
  }
}

/// Model seçimi ve API anahtarı, katlanır "Gelişmiş" bölümünde: çoğu
/// kullanıcının hiç dokunmayacağı teknik ayarlar günlük ayarları boğmasın.
class _AdvancedAiSection extends ConsumerWidget {
  const _AdvancedAiSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return _ExpandTile(
      // Üstteki boşluk ŞART: içeriğin ilk çocuğu, etiketi kutunun ÜSTÜNE
      // taşan bir form alanı (sağlayıcı açılır listesi). Boşluksuzken o
      // etiket başlığın alt satırının üstüne biniyor ve bölüm "bozuk ve
      // karışık" görünüyordu.
      childrenPadding: const EdgeInsets.only(top: 14, bottom: 8),
      leading: const Icon(Icons.tune),
      title: Text(l10n.aiAdvanced),
      subtitle: Text(
        l10n.aiAdvancedInfo,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      children: const [
        _GeminiKeyEditor(),
        SizedBox(height: 14),
        _ModelSelectors(),
      ],
    );
  }
}
