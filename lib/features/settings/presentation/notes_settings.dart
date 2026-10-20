import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/utils/device_storage.dart';
import '../../../core/utils/format_bytes.dart';
import '../../folders/data/folder_order.dart';
import '../../folders/presentation/folder_sheets.dart';
import '../../notes/presentation/capture_mode_sheet.dart';
import '../../notes/presentation/filter_sheet.dart' show sortLabel;
import '../settings_providers.dart';
import '../../notes/presentation/notes_providers.dart';

/// **AYARLAR → NOTLAR VE KLASÖRLER** (kullanıcı isteği 2026-09-26: "eksik
/// ayarların düzenlenmesi").
///
/// Ana ekranın davranışını belirleyen tercihlerin hiçbiri Ayarlar'da yoktu:
/// sütun sayısı yalnız iki parmak yakınlaştırmayla, ızgara/liste yalnız
/// süzgeç satırındaki küçük düğmeyle, klasör rafının biçimi yalnız rafın
/// köşesindeki okla, sıralama yalnız Süz levhasında değişiyordu — bunları
/// bilmeyen kullanıcı hiç bulamıyordu. Yeni gelen yana kaydırma ve klasör
/// sırası da burada. Asıl kısayollar YERİNDE KALDI; burası hepsinin tek
/// adresi.

/// Başlık + seçenek çipleri: ayar satırlarının ortak biçimi.
class _ChoiceRow<T> extends StatelessWidget {
  const _ChoiceRow({
    required this.title,
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelected,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleSmall),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final v in values)
                ChoiceChip(
                  label: Text(label(v)),
                  selected: v == selected,
                  onSelected: (_) => onSelected(v),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Ana ekranda yana kaydırınca ne arasında gezilir (bkz. [SwipeMode]).
class SwipeModeSetting extends ConsumerWidget {
  const SwipeModeSetting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return _ChoiceRow<SwipeMode>(
      title: l10n.swipeModeTitle,
      values: SwipeMode.values,
      selected: ref.watch(swipeModeProvider),
      label: (m) => swipeModeLabel(context, m),
      onSelected: (m) => ref.read(swipeModeProvider.notifier).set(m),
    );
  }
}

String swipeModeLabel(BuildContext context, SwipeMode mode) {
  final l10n = context.l10n;
  return switch (mode) {
    SwipeMode.folders => l10n.swipeModeFolders,
    SwipeMode.filters => l10n.swipeModeFilters,
    SwipeMode.both => l10n.swipeModeBoth,
    SwipeMode.off => l10n.swipeModeOff,
  };
}

/// Klasör sırası: ölçüt + "elle sırala" levhası.
class FolderOrderSetting extends ConsumerWidget {
  const FolderOrderSetting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.folderOrderTitle,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              TextButton.icon(
                onPressed: () => showFolderOrderSheet(context),
                icon: const Icon(Icons.swap_vert, size: 18),
                label: Text(l10n.folderReorder),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FolderSortChoice(
            value: ref.watch(folderSortProvider),
            onChanged: (v) => ref.read(folderSortProvider.notifier).set(v),
          ),
        ],
      ),
    );
  }
}

/// Notların sıralaması (Süz levhasındakiyle aynı tercih).
class NoteSortSetting extends ConsumerWidget {
  const NoteSortSetting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return _ChoiceRow<NoteSort>(
      title: l10n.sortBy,
      values: NoteSort.values,
      selected: ref.watch(noteSortProvider),
      label: (s) => sortLabel(l10n, s),
      onSelected: (s) => ref.read(noteSortProvider.notifier).set(s),
    );
  }
}

/// Izgara / liste ve sütun sayısı.
class NoteLayoutSetting extends ConsumerWidget {
  const NoteLayoutSetting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final list = ref.watch(noteListViewProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ChoiceRow<bool>(
          title: l10n.noteViewSetting,
          values: const [false, true],
          selected: list,
          label: (v) => v ? l10n.noteViewList : l10n.noteViewGrid,
          onSelected: (v) => ref.read(noteListViewProvider.notifier).set(v),
        ),
        // Sütun sayısı yalnız IZGARADA anlamlı.
        if (!list)
          _ChoiceRow<int>(
            title: l10n.gridColumnsSetting,
            subtitle: l10n.gridColumnsInfo,
            values: const [0, 1, 2, 3, 4],
            selected: ref.watch(gridColumnsProvider),
            label: (v) => v == 0 ? l10n.gridColumnsAuto : '$v',
            onSelected: (v) => ref.read(gridColumnsProvider.notifier).set(v),
          ),
        _ChoiceRow<bool>(
          title: l10n.folderShelfSetting,
          values: const [false, true],
          selected: ref.watch(folderShelfExpandedProvider),
          label: (v) => v ? l10n.folderShelfTiles : l10n.folderShelfStrip,
          onSelected: (v) =>
              ref.read(folderShelfExpandedProvider.notifier).set(v),
        ),
      ],
    );
  }
}

/// İçerikten (fotoğraf, tarama, PDF…) not alırken varsayılan kip (F3.8).
class CaptureModeSetting extends ConsumerStatefulWidget {
  const CaptureModeSetting({super.key});

  @override
  ConsumerState<CaptureModeSetting> createState() => _CaptureModeSettingState();
}

class _CaptureModeSettingState extends ConsumerState<CaptureModeSetting> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    ref.watch(prefsRevisionProvider);
    final prefs = ref.watch(sharedPreferencesProvider);
    final stored = prefs.getString(captureModeDefaultKey);
    return _ChoiceRow<String>(
      title: l10n.captureModeSetting,
      subtitle: l10n.captureModeSettingInfo,
      values: [CaptureMode.bubbles.name, CaptureMode.classic.name, 'ask'],
      selected: stored ?? 'ask',
      label: (v) => v == CaptureMode.bubbles.name
          ? l10n.captureModeBubbles
          : v == CaptureMode.classic.name
          ? l10n.captureModeClassic
          : l10n.captureModeAsk,
      onSelected: (v) {
        prefs.setString(captureModeDefaultKey, v);
        setState(() {});
      },
    );
  }
}

/// **BU CİHAZDA** — uygulamanın kapladığı yer ve önbelleği temizleme (bkz.
/// [DeviceStorage]).
class DeviceStorageSection extends StatefulWidget {
  const DeviceStorageSection({super.key});

  @override
  State<DeviceStorageSection> createState() => _DeviceStorageSectionState();
}

class _DeviceStorageSectionState extends State<DeviceStorageSection> {
  late Future<DeviceStorageUsage?> _usage = measureDeviceStorage();
  bool _clearing = false;

  Future<void> _clear() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _clearing = true);
    final freed = await clearDeviceCaches();
    if (!mounted) return;
    setState(() {
      _clearing = false;
      _usage = measureDeviceStorage();
    });
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(l10n.deviceStorageCleared(formatBytes(freed)))),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: FutureBuilder<DeviceStorageUsage?>(
        future: _usage,
        builder: (context, snapshot) {
          final usage = snapshot.data;
          Widget line(String label, int? bytes, {bool bold = false}) =>
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: bold
                            ? theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              )
                            : theme.textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      bytes == null ? '…' : formatBytes(bytes),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: bold ? FontWeight.w700 : null,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.deviceStorageTitle, style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              if (snapshot.connectionState == ConnectionState.done &&
                  usage == null)
                Text(
                  l10n.deviceStorageUnavailable,
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                )
              else ...[
                line(l10n.deviceStorageAttachments, usage?.attachments),
                line(l10n.deviceStorageDatabase, usage?.database),
                line(l10n.deviceStorageCache, usage?.cache),
                line(l10n.deviceStorageAi, usage?.aiCache),
                const Divider(height: 12),
                line(l10n.deviceStorageTotal, usage?.total, bold: true),
                const SizedBox(height: 6),
                Text(
                  l10n.deviceStorageInfo,
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _clearing || usage == null ? null : _clear,
                  icon: _clearing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cleaning_services_outlined, size: 18),
                  label: Text(l10n.deviceStorageClear),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
