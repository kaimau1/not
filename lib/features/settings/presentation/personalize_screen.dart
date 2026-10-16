import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/personalize.dart';
import '../../notes/presentation/editor/attach_sheet.dart'
    show attachSheetCatalog;
import '../../notes/presentation/editor/video_transport.dart' show SeekIcon;
import '../../notes/presentation/quick_add_fab.dart' show quickAddCatalog;
import '../../notes/presentation/viewers/bubble_layer.dart' show BubbleLook;
import '../settings_providers.dart';

/// **KİŞİSELLEŞTİR** ekranı — bütün kişisel düzen TEK menüde.
///
/// Kullanıcı isteği 2026-10-16: "bütün alanlar bir eklenti gibi açılıp
/// kapatılabilsin; not ekleme alanı özelleştirilebilsin, hangilerinin
/// görüneceği seçilsin; bu düzenlemeler bir menü üzerinden yapılmalı, ekranda
/// ayar düğmesi olarak yer kaplamamalı — bir düzenleme modu olsun".
///
/// İki yol aynı kayda yazar (bkz. `Personalize`):
///  1. Buradaki seçiciler — değişiklik anında kaydedilir.
///  2. "Düzenleme modunu başlat": ekranlara dönülür, öğelere dokunarak
///     gizle/göster yapılır, üstteki şeritten Kaydet.
///
/// Sonuç [Navigator.pop] ile 'edit' döner: ayarlar ekranı da kapanır ki
/// kullanıcı doğrudan düzenleyeceği ekrana insin.
class PersonalizeScreen extends StatelessWidget {
  const PersonalizeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.personalizeTitle),
        actions: [
          IconButton(
            key: const ValueKey('personalize-reset'),
            tooltip: l10n.personalizeReset,
            icon: const Icon(Icons.restart_alt_rounded),
            onPressed: () => _confirmReset(context),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: Personalize.listenable,
        builder: (context, _) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                14,
                8,
                14,
                24 + MediaQuery.paddingOf(context).bottom,
              ),
              children: const [
                _EditModeCard(),
                SizedBox(height: 14),
                _ModulesSection(),
                _EditorSection(),
                _QuickAddSection(),
                _AttachSection(),
                _VideoSection(),
                _HomeSection(),
                _BubblesSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.personalizeReset),
        content: Text(l10n.personalizeResetConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.personalizeReset),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    Personalize.reset();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.personalizeResetDone)));
  }
}

/// Ekranın başındaki büyük kart: düzenleme modunu başlatır.
class _EditModeCard extends StatelessWidget {
  const _EditModeCard();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final editing = Personalize.editing;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primaryContainer,
            scheme.tertiaryContainer.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.surface.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.touch_app_outlined,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.customizeStartTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              l10n.customizeStartInfo,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onPrimaryContainer.withValues(alpha: 0.85),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton.icon(
                key: const ValueKey('personalize-start-edit'),
                onPressed: editing
                    ? null
                    : () {
                        Personalize.startEditing();
                        Navigator.of(context).pop('edit');
                      },
                icon: Icon(editing ? Icons.check : Icons.edit_outlined),
                label: Text(
                  editing ? l10n.customizeActive : l10n.customizeStart,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bölüm başlığı + isteğe bağlı açıklama + içerik kartı.
class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.child,
    this.info,
  });

  final String title;
  final IconData icon;
  final String? info;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      // Material (DecoratedBox DEĞİL): içindeki anahtar satırları
      // (ListTile) zeminlerini ve dokunma dalgalarını en yakın Material'a
      // çizer; renkli bir DecoratedBox onları örterdi.
      child: Material(
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.7)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: scheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              if (info != null) ...[
                const SizedBox(height: 4),
                Text(
                  info!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Görünürlük çipleri: seçili = görünür.
class _VisibilityChips extends StatelessWidget {
  const _VisibilityChips({required this.items});

  final List<({String id, IconData icon, String label})> items;

  @override
  Widget build(BuildContext context) {
    final prefs = Personalize.prefs.value;
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final item in items)
          Builder(
            builder: (context) {
              final on = prefs.shows(item.id);
              // Gizli öğe AÇIKÇA gizli görünsün: üstü çizili göz + soluk
              // yazı (yalnız zemin tonu farkı gözden kaçıyordu).
              return FilterChip(
                key: ValueKey('ui-chip-${item.id}'),
                avatar: Icon(
                  on ? item.icon : Icons.visibility_off_outlined,
                  size: 16,
                  color: on ? null : scheme.outline,
                ),
                label: Text(
                  item.label,
                  style: on
                      ? null
                      : TextStyle(
                          color: scheme.outline,
                          decoration: TextDecoration.lineThrough,
                        ),
                ),
                selected: on,
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
                onSelected: (on) =>
                    Personalize.update((p) => p.withVisible(item.id, on)),
              );
            },
          ),
      ],
    );
  }
}

class _ModulesSection extends StatelessWidget {
  const _ModulesSection();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final prefs = Personalize.prefs.value;
    final modules = <(UiModule, IconData, String, String)>[
      (UiModule.ai, Icons.auto_awesome, l10n.moduleAi, l10n.moduleAiInfo),
      (
        UiModule.voice,
        Icons.mic_none_rounded,
        l10n.moduleVoice,
        l10n.moduleVoiceInfo,
      ),
      (
        UiModule.video,
        Icons.smart_display_outlined,
        l10n.moduleVideo,
        l10n.moduleVideoInfo,
      ),
      (
        UiModule.documents,
        Icons.picture_as_pdf_outlined,
        l10n.moduleDocuments,
        l10n.moduleDocumentsInfo,
      ),
      (
        UiModule.scan,
        Icons.document_scanner_outlined,
        l10n.moduleScan,
        l10n.moduleScanInfo,
      ),
      (
        UiModule.drawing,
        Icons.draw_outlined,
        l10n.moduleDrawing,
        l10n.moduleDrawingInfo,
      ),
      (
        UiModule.templates,
        Icons.dashboard_customize_outlined,
        l10n.moduleTemplates,
        l10n.moduleTemplatesInfo,
      ),
      (
        UiModule.tags,
        Icons.sell_outlined,
        l10n.moduleTags,
        l10n.moduleTagsInfo,
      ),
      (
        UiModule.collaboration,
        Icons.people_alt_outlined,
        l10n.moduleCollaboration,
        l10n.moduleCollaborationInfo,
      ),
    ];
    return _Section(
      title: l10n.personalizeModules,
      icon: Icons.extension_outlined,
      info: l10n.personalizeModulesInfo,
      child: Column(
        children: [
          for (final (module, icon, title, info) in modules)
            Builder(
              builder: (context) {
                final state = prefs.moduleState(module);
                return SwitchListTile(
                  key: ValueKey('module-${module.id}'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  secondary: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: (state == false ? scheme.outline : scheme.primary)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      size: 19,
                      color: state == false ? scheme.outline : scheme.primary,
                    ),
                  ),
                  title: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    state == null ? '$info · ${l10n.moduleMixed}' : info,
                  ),
                  value: state != false,
                  onChanged: (on) =>
                      Personalize.update((p) => p.withModule(module, on)),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _EditorSection extends StatelessWidget {
  const _EditorSection();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: [
        _Section(
          title: l10n.personalizeEditorBar,
          icon: Icons.space_bar_rounded,
          info: l10n.personalizeChipsInfo,
          child: _VisibilityChips(
            items: [
              (
                id: UiItem.barFormat,
                icon: Icons.text_format,
                label: l10n.formatTitle,
              ),
              (id: UiItem.barAdd, icon: Icons.add, label: l10n.addAttachment),
              (
                id: UiItem.barSelect,
                icon: Icons.select_all,
                label: l10n.select,
              ),
              (
                id: UiItem.barSearch,
                icon: Icons.search,
                label: l10n.noteSearchTitle,
              ),
              (
                id: UiItem.barShare,
                icon: Icons.share_outlined,
                label: l10n.share,
              ),
              (
                id: UiItem.barAttachments,
                icon: Icons.attach_file,
                label: l10n.uiItemAttachments,
              ),
              (id: UiItem.barAi, icon: Icons.auto_awesome, label: l10n.aiTitle),
              (
                id: UiItem.barVoiceAi,
                icon: Icons.mic_none,
                label: l10n.voiceCaptureAi,
              ),
              (
                id: UiItem.barDictation,
                icon: Icons.mic,
                label: l10n.liveDictation,
              ),
            ],
          ),
        ),
        _Section(
          title: l10n.personalizeEditorTop,
          icon: Icons.web_asset_rounded,
          child: _VisibilityChips(
            items: [
              (
                id: UiItem.editorDate,
                icon: Icons.schedule,
                label: l10n.uiItemDate,
              ),
              (
                id: UiItem.topSync,
                icon: Icons.cloud_done_outlined,
                label: l10n.uiItemSync,
              ),
              (id: UiItem.topUndo, icon: Icons.undo, label: l10n.undo),
              (
                id: UiItem.topCollab,
                icon: Icons.person_add_alt_1_outlined,
                label: l10n.collaborators,
              ),
              (
                id: UiItem.topPin,
                icon: Icons.push_pin_outlined,
                label: l10n.pin,
              ),
              (
                id: UiItem.editorTags,
                icon: Icons.sell_outlined,
                label: l10n.moduleTags,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickAddSection extends StatelessWidget {
  const _QuickAddSection();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _Section(
      title: l10n.personalizeQuickAdd,
      icon: Icons.add_circle_outline,
      info: l10n.personalizeChipsInfo,
      child: _VisibilityChips(
        items: [
          for (final m in quickAddCatalog(l10n))
            (id: UiItem.quickAdd(m.key), icon: m.icon, label: m.label),
          (
            id: UiItem.quickAddFrequent,
            icon: Icons.history_rounded,
            label: l10n.uiItemFrequent,
          ),
        ],
      ),
    );
  }
}

class _AttachSection extends StatelessWidget {
  const _AttachSection();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _Section(
      title: l10n.personalizeAttachSheet,
      icon: Icons.add_box_outlined,
      info: l10n.personalizeChipsInfo,
      child: _VisibilityChips(
        items: [
          for (final e in attachSheetCatalog(l10n))
            (id: UiItem.attach(e.id), icon: e.icon, label: e.label),
        ],
      ),
    );
  }
}

class _VideoSection extends StatelessWidget {
  const _VideoSection();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final prefs = Personalize.prefs.value;
    Widget seekRow({
      required String label,
      required bool forward,
      required int value,
      required void Function(int) onSelected,
    }) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SeekIcon(seconds: value, forward: forward, size: 22),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final s in UiPrefs.seekChoices)
              ChoiceChip(
                key: ValueKey('seek-${forward ? 'fwd' : 'back'}-$s'),
                label: Text(l10n.secondsShort(s)),
                selected: value == s,
                visualDensity: VisualDensity.compact,
                onSelected: (_) => onSelected(s),
              ),
          ],
        ),
      ],
    );
    return _Section(
      title: l10n.personalizeVideo,
      icon: Icons.ondemand_video_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          seekRow(
            label: l10n.videoSeekBack,
            forward: false,
            value: prefs.seekBack,
            onSelected: (s) =>
                Personalize.update((p) => p.copyWith(seekBack: s)),
          ),
          const SizedBox(height: 14),
          seekRow(
            label: l10n.videoSeekForward,
            forward: true,
            value: prefs.seekForward,
            onSelected: (s) =>
                Personalize.update((p) => p.copyWith(seekForward: s)),
          ),
          const SizedBox(height: 14),
          _VisibilityChips(
            items: [
              (
                id: UiItem.videoSpeed,
                icon: Icons.speed_rounded,
                label: l10n.videoSpeed,
              ),
              (
                id: UiItem.videoTime,
                icon: Icons.timer_outlined,
                label: l10n.uiItemVideoTime,
              ),
              (
                id: UiItem.videoNoteAt,
                icon: Icons.more_time,
                label: l10n.videoNoteAtTime,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Ana ekran tercihleri (Görünüm alanındakilerle AYNI kayıt — iki giriş).
class _HomeSection extends ConsumerWidget {
  const _HomeSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    Widget tile(
      Key key,
      String title,
      String info,
      bool value,
      ValueChanged<bool> onChanged,
    ) => SwitchListTile(
      key: key,
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(info),
      value: value,
      onChanged: onChanged,
    );
    return _Section(
      title: l10n.personalizeHome,
      icon: Icons.home_outlined,
      child: Column(
        children: [
          tile(
            const ValueKey('home-quick-capture'),
            l10n.quickCaptureRowSetting,
            l10n.quickCaptureRowInfo,
            ref.watch(quickCaptureRowProvider),
            (v) => ref.read(quickCaptureRowProvider.notifier).set(v),
          ),
          tile(
            const ValueKey('home-rich-preview'),
            l10n.cardRichPreview,
            l10n.cardRichPreviewInfo,
            ref.watch(cardRichPreviewProvider),
            (v) => ref.read(cardRichPreviewProvider.notifier).set(v),
          ),
          tile(
            const ValueKey('home-expand-items'),
            l10n.expandListItems,
            l10n.expandListItemsInfo,
            ref.watch(expandListItemsProvider),
            (v) => ref.read(expandListItemsProvider.notifier).set(v),
          ),
        ],
      ),
    );
  }
}

class _BubblesSection extends StatelessWidget {
  const _BubblesSection();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _Section(
      title: l10n.personalizeBubbles,
      icon: Icons.chat_bubble_outline_rounded,
      child: ValueListenableBuilder<double>(
        valueListenable: BubbleLook.scale,
        builder: (context, scale, _) => Row(
          children: [
            Text(
              l10n.bubbleSizeSetting,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Expanded(
              child: Slider(
                key: const ValueKey('bubble-scale-slider'),
                value: scale,
                min: BubbleLook.min,
                max: BubbleLook.max,
                divisions: ((BubbleLook.max - BubbleLook.min) / 0.05).round(),
                label: '${(scale * 100).round()}%',
                onChanged: BubbleLook.setScale,
              ),
            ),
            SizedBox(
              width: 44,
              child: Text(
                '${(scale * 100).round()}%',
                textAlign: TextAlign.end,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
