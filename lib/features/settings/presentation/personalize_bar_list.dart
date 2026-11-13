import 'package:flutter/material.dart';

import '../../../core/app_icons.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/personalize.dart';

/// NOT ALT ÇUBUĞUNUN DÜZENİ (kullanıcı isteği 2026-11-13: "alt paneldeki
/// tüm butonlar değiştirilebilsin, kişi istediğini koyabilsin, istediğini
/// çıkarabilsin; bunu da ayarlarda yapılabilen seçenekler geniş olsun").
///
/// İki grup (soldaki araç kapsülü, sağdaki AI/ses kapsülü); her satırda
/// tutamaçla SÜRÜKLE-SIRALA ve anahtarla GÖSTER/GİZLE. Varsayılanda gizli
/// gelen düğmeler (geri al, yinele, hatırlatıcı, fotoğraf, kamera, tara,
/// renk, paylaş) aynı listede kapalı durur — açınca çubuğa girer.
///
/// Satırdaki ok düğmeyi ÖBÜR kapsüle taşır (P50): her düğme iki kapsülde de
/// durabilir, yalnız kılığı değişir.
///
/// Altında ÜST ÇUBUK grubu (P20 M8): aynı satır, kapsül oku yok.
///
/// Değişiklik hemen kaydedilir ([Personalize.update]); düzenleme modu açıksa
/// taslak da aynı değişikliği alır.
class PersonalizeBarList extends StatelessWidget {
  const PersonalizeBarList({super.key});

  /// Bir düğmenin ayardaki simgesi ve adı (çubuktakiyle aynı).
  static (IconData, String) describe(AppLocalizations l10n, String id) =>
      switch (id) {
        UiItem.barFormat => (Icons.text_format, l10n.formatTitle),
        UiItem.barAdd => (Icons.add, l10n.addAttachment),
        UiItem.barPen => (Icons.draw_outlined, l10n.quickRowPen),
        UiItem.barSearch => (Icons.search, l10n.noteSearchTitle),
        UiItem.barAttachments => (Icons.attach_file, l10n.uiItemAttachments),
        UiItem.barCheckbox => (Icons.check_box_outlined, l10n.checkboxToggle),
        UiItem.barSelect => (Icons.select_all, l10n.select),
        UiItem.barUndo => (Icons.undo, l10n.undo),
        UiItem.barRedo => (Icons.redo, l10n.redo),
        UiItem.barReminder => (Icons.alarm_add_outlined, l10n.quickRowReminder),
        UiItem.barPhoto => (
          Icons.add_photo_alternate_outlined,
          l10n.quickRowPhoto,
        ),
        UiItem.barCamera => (Icons.photo_camera_outlined, l10n.quickRowCamera),
        UiItem.barScan => (Icons.document_scanner_outlined, l10n.quickRowScan),
        UiItem.barColor => (AppIcons.color, l10n.color),
        UiItem.barShare => (Icons.share_outlined, l10n.share),
        UiItem.barAi => (Icons.auto_awesome, l10n.aiTitle),
        UiItem.barDictation => (AppIcons.dictation, l10n.liveDictation),
        UiItem.barVoiceRecord => (AppIcons.voiceRecord, l10n.recordAudio),
        UiItem.topHome => (Icons.home_outlined, l10n.goHome),
        UiItem.topSync => (Icons.cloud_done_outlined, l10n.uiItemSync),
        UiItem.topUndo => (Icons.undo, l10n.undo),
        UiItem.topPin => (Icons.push_pin_outlined, l10n.pin),
        UiItem.topFullscreen => (Icons.fullscreen_rounded, l10n.noteFullscreen),
        _ => (Icons.circle_outlined, id),
      };

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Personalize.prefs,
    builder: (context, _) {
      final l10n = context.l10n;
      final prefs = Personalize.prefs.value;
      final sides = prefs.barSides;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _GroupLabel(l10n.personalizeBarLeft),
          _ReorderGroup(
            groupKey: 'left',
            ids: sides.left,
            right: false,
            onReorder: (ids) =>
                Personalize.update((p) => p.copyWith(barOrder: ids)),
          ),
          const SizedBox(height: 8),
          _GroupLabel(l10n.personalizeBarRight),
          _ReorderGroup(
            groupKey: 'right',
            ids: sides.right,
            right: true,
            onReorder: (ids) =>
                Personalize.update((p) => p.copyWith(aiOrder: ids)),
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              key: const ValueKey('personalize-bar-reset'),
              icon: const Icon(Icons.restart_alt_rounded),
              label: Text(l10n.personalizeBarReset),
              onPressed: () => Personalize.update(_resetBar),
            ),
          ),
          _GroupLabel(l10n.personalizeBarTop),
          _ReorderGroup(
            groupKey: 'top',
            ids: UiPrefs.orderOf(UiItem.topDefault, prefs.topOrder),
            onReorder: (ids) =>
                Personalize.update((p) => p.copyWith(topOrder: ids)),
          ),
        ],
      );
    },
  );

  /// Yalnız alt çubuğun sırası ve görünürlüğü varsayılana döner.
  static UiPrefs _resetBar(UiPrefs p) {
    var next = p.copyWith(barOrder: const [], aiOrder: const []);
    for (final id in [...UiItem.barLeftDefault, ...UiItem.barRightDefault]) {
      next = next.withVisible(id, !UiItem.optIn.contains(id));
    }
    return next;
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 4, 4, 2),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelMedium
          ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
    ),
  );
}

class _ReorderGroup extends StatelessWidget {
  const _ReorderGroup({
    required this.groupKey,
    required this.ids,
    this.right,
    required this.onReorder,
  });

  final String groupKey;
  final List<String> ids;

  /// Bu grup sağ kapsül mü — satırdaki "taşı" düğmesi öbür tarafa yollar.
  /// null: kapsülsüz grup (üst çubuk), ok yok.
  final bool? right;
  final ValueChanged<List<String>> onReorder;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final prefs = Personalize.prefs.value;
    return ReorderableListView(
      key: ValueKey('personalize-bar-$groupKey'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      // onReorderItem: hedef indeks çıkarılan öğeye göre düzeltilmiş gelir.
      onReorderItem: (from, to) {
        final next = List.of(ids);
        final id = next.removeAt(from);
        next.insert(to, id);
        onReorder(next);
      },
      children: [
        for (var i = 0; i < ids.length; i++)
          Builder(
            key: ValueKey('bar-row-${ids[i]}'),
            builder: (context) {
              final id = ids[i];
              final (icon, label) = PersonalizeBarList.describe(l10n, id);
              final on = prefs.shows(id);
              return SwitchListTile(
                key: ValueKey('bar-switch-$id'),
                contentPadding: const EdgeInsetsDirectional.only(end: 4),
                dense: true,
                value: on,
                onChanged: (v) =>
                    Personalize.update((p) => p.withVisible(id, v)),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: on ? null : TextStyle(color: scheme.outline),
                      ),
                    ),
                    // ÖBÜR KAPSÜLE TAŞI (P50): gruplar alt alta — ok yönü
                    // düğmenin gideceği grubu gösterir.
                    if (right case final right?)
                      IconButton(
                        key: ValueKey('bar-move-$id'),
                        visualDensity: VisualDensity.compact,
                        tooltip: right
                            ? l10n.personalizeBarMoveLeft
                            : l10n.personalizeBarMoveRight,
                        icon: Icon(
                          right
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          color: scheme.outline,
                        ),
                        onPressed: () => Personalize.update(
                          (p) => p.withBarSide(id, right: !right),
                        ),
                      ),
                  ],
                ),
                secondary: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ReorderableDragStartListener(
                      index: i,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          Icons.drag_indicator,
                          semanticLabel: l10n.reorderHandle,
                          color: scheme.outline,
                        ),
                      ),
                    ),
                    Icon(icon, color: on ? scheme.primary : scheme.outline),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
