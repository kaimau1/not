part of '../settings_screen.dart';

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

/// **EK İÇERİĞİNDE ARAMA** (kullanıcı isteği 2026-09-04: "anlamsal arama
/// görsel ve pdf'leri de arayabilir, seçenek olarak sunmalıyız").
///
/// Varsayılan KAPALI: açmak bir kerelik tarama bedeli demek (PDF ayrıştırma
/// + cihaz-içi OCR) — bkz. attachment_text_index.dart.
class _AttachmentSearchSwitch extends ConsumerWidget {
  const _AttachmentSearchSwitch();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(l10n.searchAttachments),
      subtitle: Text(l10n.searchAttachmentsInfo),
      value: ref.watch(attachmentSearchProvider),
      onChanged: (value) =>
          ref.read(attachmentSearchProvider.notifier).set(value),
    );
  }
}

/// "Dosyaları Dosya Okuyucu ile seç" — yalnız kardeş uygulama kuruluyken
/// görünür (bkz. `DocPicker`).
class _FileAppSwitch extends StatefulWidget {
  const _FileAppSwitch();

  @override
  State<_FileAppSwitch> createState() => _FileAppSwitchState();
}

class _FileAppSwitchState extends State<_FileAppSwitch> {
  bool _installed = false;
  bool _value = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final installed = await DocPicker.fileAppInstalled();
    final value = await DocPicker.useFileApp();
    if (!mounted) return;
    setState(() {
      _installed = installed;
      _value = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_installed) return const SizedBox.shrink();
    final l10n = context.l10n;
    return SwitchListTile(
      key: const ValueKey('settings-file-app'),
      contentPadding: EdgeInsets.zero,
      secondary: const Icon(Icons.folder_special_outlined),
      title: Text(l10n.fileAppPickerTitle),
      subtitle: Text(l10n.fileAppPickerInfo),
      value: _value,
      onChanged: (value) {
        setState(() => _value = value);
        DocPicker.setUseFileApp(value);
      },
    );
  }
}

/// **PAYLAŞILAN KLASÖR BİLDİRİMLERİ** (kullanıcı isteği 2026-09-04:
/// "ayarlardan kapatılabilir olarak"). Kapatmak yalnız telefon bildirimini
/// susturur; ana ekrandaki rozet çalışmaya devam eder.
class _SharedNotificationsSwitch extends ConsumerWidget {
  const _SharedNotificationsSwitch();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(l10n.sharedNotifications),
      subtitle: Text(l10n.sharedNotificationsInfo),
      value: ref.watch(sharedNotificationsProvider),
      onChanged: (value) =>
          ref.read(sharedNotificationsProvider.notifier).set(value),
    );
  }
}

/// **ADIMLA BULUNABİLİRİM** (F1.1). Değişince dizin kaydı hemen tazelenir:
/// kapatınca `userSearch` belgesi o an silinir (bir sonraki açılışı
/// beklemez).
class _DiscoverableSwitch extends ConsumerWidget {
  const _DiscoverableSwitch();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(l10n.discoverable),
      subtitle: Text(l10n.discoverableInfo),
      value: ref.watch(discoverableProvider),
      onChanged: (value) {
        ref.read(discoverableProvider.notifier).set(value);
        ref
            .read(friendsRepositoryProvider)
            ?.syncOwnDirectoryEntry(discoverable: value)
            .catchError((Object _) {});
      },
    );
  }
}

class _QuickCaptureRowSwitch extends ConsumerWidget {
  const _QuickCaptureRowSwitch();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(l10n.quickCaptureRowSetting),
      subtitle: Text(l10n.quickCaptureRowInfo),
      value: ref.watch(quickCaptureRowProvider),
      onChanged: (value) =>
          ref.read(quickCaptureRowProvider.notifier).set(value),
    );
  }
}

/// Ana ekrandaki kartlarda satır içi biçim (renk, vurgu, kalın, altı çizili)
/// çizilsin mi? Varsayılan açık; kapatan kullanıcı düz metin önizlemeye döner.
class _CardRichPreviewSwitch extends ConsumerWidget {
  const _CardRichPreviewSwitch();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(l10n.cardRichPreview),
      subtitle: Text(l10n.cardRichPreviewInfo),
      value: ref.watch(cardRichPreviewProvider),
      onChanged: (value) =>
          ref.read(cardRichPreviewProvider.notifier).set(value),
    );
  }
}

/// Kartlarda hassas içeriği gizle (B1): parola notu kartta içeriksiz,
/// IBAN/kart numarası örtülü.
class _CardHideSensitiveSwitch extends ConsumerWidget {
  const _CardHideSensitiveSwitch();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(l10n.cardHideSensitive),
      subtitle: Text(l10n.cardHideSensitiveInfo),
      value: ref.watch(cardHideSensitiveProvider),
      onChanged: (value) =>
          ref.read(cardHideSensitiveProvider.notifier).set(value),
    );
  }
}

/// Kullanılan bulut depolama alanı: "12,4 MB / 50 MB kullanıldı" + çubuk.
///
/// Tavan olmadan lifetime paketinin maliyeti öngörülemiyordu; tavan konunca
/// kullanıcının nerede olduğunu görebileceği bir yer de gerekti — "ek
/// eklenemiyor" hatasını ilk kez yükleme anında görmek kötü bir sürpriz.
class _StorageUsage extends ConsumerWidget {
  const _StorageUsage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    // Uygulama bulutunun tavanı YALNIZ ekler oraya gidiyorsa (web) anlamlı:
    // Drive kipinde kota Drive'ın (bkz. AttachmentSyncTile), misafir
    // hesapta ekler buluta hiç çıkmıyor.
    if (ref.watch(attachmentSyncModeProvider) != AttachmentSyncMode.storage) {
      return const SizedBox.shrink();
    }
    final premium = ref.watch(premiumProvider).value ?? false;
    final quota = premium
        ? AppConstants.maxPremiumStorageBytes
        : AppConstants.maxFreeStorageBytes;
    final used = ref.watch(storageUsedBytesProvider);
    final ratio = (used / quota).clamp(0.0, 1.0);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(l10n.storageUsage),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: scheme.surfaceContainerHighest,
              // Doluya yaklaşınca uyarı rengi: çubuğun kendisi zaten
              // okunuyorsa ayrıca metin okumaya gerek kalmasın.
              color: ratio >= 0.9 ? scheme.error : scheme.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(l10n.storageUsageValue(formatBytes(used), formatBytes(quota))),
        ],
      ),
    );
  }
}

/// Eklerin buluta otomatik yüklenmesi için boyut sınırı seçici.
/// Sınırı aşan dosyalar cihazda kalır (not metni yine senkronlanır).
class _SyncLimitSelector extends ConsumerWidget {
  const _SyncLimitSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final value = ref.watch(syncLimitMbProvider);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(l10n.syncLimitTitle),
      subtitle: Text(l10n.syncLimitInfo),
      trailing: DropdownButton<int>(
        value: SyncLimitMbNotifier.options.contains(value) ? value : 25,
        items: [
          for (final mb in SyncLimitMbNotifier.options)
            DropdownMenuItem(
              value: mb,
              child: Text(mb == 0 ? l10n.syncLimitUnlimited : '$mb MB'),
            ),
        ],
        onChanged: (v) {
          if (v != null) ref.read(syncLimitMbProvider.notifier).set(v);
        },
      ),
    );
  }
}

/// Tek tercihli aç/kapa satırı (kartta görünen öğeler gibi aynı biçimli
/// anahtarlar için ortak).
class _PrefSwitch extends ConsumerWidget {
  const _PrefSwitch({
    super.key,
    required this.provider,
    required this.title,
    this.subtitle,
    this.icon,
  });

  final NotifierProvider<BoolPrefNotifier, bool> provider;
  final String title;
  final String? subtitle;
  final IconData? icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      secondary: icon == null ? null : Icon(icon, size: 20),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      value: ref.watch(provider),
      onChanged: (value) => ref.read(provider.notifier).set(value),
    );
  }
}
