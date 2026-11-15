import 'package:flutter/material.dart';

import '../../../core/app_icons.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/personalize.dart';
import '../../../core/widgets/customize_board.dart';
import '../../../app/theme/app_tokens.dart';
import 'customize_hub.dart' show reorderShown;

/// NOT ALT ÇUBUĞUNUN DÜZENİ (kullanıcı isteği 2026-11-13: "alt paneldeki
/// tüm butonlar değiştirilebilsin, kişi istediğini koyabilsin, istediğini
/// çıkarabilsin; bunu da ayarlarda yapılabilen seçenekler geniş olsun").
///
/// İki grup (soldaki araç kapsülü, sağdaki AI/ses kapsülü); her grup bir
/// [CustomizeBoard]: önizleme şeridinde SÜRÜKLE-SIRALA, karoyla GÖSTER/GİZLE
/// (P63 PB2 — eskiden anahtarlı satır listesi). Varsayılanda gizli
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
  const PersonalizeBarList({super.key, this.bottom = true, this.top = true});

  /// Alt çubuğun iki kapsülü (+ varsayılana dön) çizilsin mi.
  final bool bottom;

  /// Üst çubuk grubu çizilsin mi.
  final bool top;

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
          if (bottom) ...[
            _GroupLabel(l10n.personalizeBarLeft),
            _BarGroup(
              groupKey: 'left',
              ids: sides.left,
              right: false,
              onReorder: (ids) =>
                  Personalize.update((p) => p.copyWith(barOrder: ids)),
            ),
            const SizedBox(height: AppSpace.s),
            _GroupLabel(l10n.personalizeBarRight),
            _BarGroup(
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
          ],
          if (top) ...[
            _GroupLabel(l10n.personalizeBarTop),
            _BarGroup(
              groupKey: 'top',
              ids: UiPrefs.orderOf(UiItem.topDefault, prefs.topOrder),
              onReorder: (ids) =>
                  Personalize.update((p) => p.copyWith(topOrder: ids)),
            ),
          ],
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.m),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}

/// Bir kapsülün (ya da üst çubuğun) panosu: karo = göster/gizle, önizleme
/// şeridinde sürükle = sırala; kapsüllü grupta karonun okuyla öbür kapsüle
/// taşı (P50 — "uzun bas" ek kısayol değil, ok düğmesi kalır).
class _BarGroup extends StatelessWidget {
  const _BarGroup({
    required this.groupKey,
    required this.ids,
    this.right,
    required this.onReorder,
  });

  final String groupKey;

  /// Grubun BÜTÜN düğmeleri (gizliler dahil), kullanıcı sırasıyla.
  final List<String> ids;

  /// Bu grup sağ kapsül mü — karodaki "taşı" düğmesi öbür tarafa yollar.
  /// null: kapsülsüz grup (üst çubuk), ok yok.
  final bool? right;
  final ValueChanged<List<String>> onReorder;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final prefs = Personalize.prefs.value;
    final shown = [
      for (final id in ids)
        if (prefs.shows(id)) id,
    ];
    final right = this.right;
    return KeyedSubtree(
      key: ValueKey('personalize-bar-$groupKey'),
      child: CustomizeBoard(
        entries: [
          for (final id in ids)
            if (PersonalizeBarList.describe(l10n, id) case (
              final icon,
              final label,
            ))
              (id: id, icon: icon, label: label),
        ],
        shown: shown,
        onToggle: (id, on) => Personalize.update((p) => p.withVisible(id, on)),
        onReorder: (from, to) => onReorder(reorderShown(ids, shown, from, to)),
        shownLabel: l10n.customizeShown,
        availableLabel: l10n.quickRowEditAvailable,
        emptyLabel: l10n.quickRowEditEmpty,
        keyPrefix: 'bar-switch-',
        trailingOf: right == null
            ? null
            // ÖBÜR KAPSÜLE TAŞI (P50): gruplar alt alta — ok yönü düğmenin
            // gideceği grubu gösterir.
            : (id) => IconButton(
                key: ValueKey('bar-move-$id'),
                visualDensity: VisualDensity.compact,
                tooltip: right
                    ? l10n.personalizeBarMoveLeft
                    : l10n.personalizeBarMoveRight,
                iconSize: AppIconSize.s,
                icon: Icon(
                  right
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  color: scheme.outline,
                ),
                onPressed: () =>
                    Personalize.update((p) => p.withBarSide(id, right: !right)),
              ),
      ),
    );
  }
}
