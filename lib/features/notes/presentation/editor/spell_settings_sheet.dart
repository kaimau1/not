import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/l10n_ext.dart';
import '../../../../core/widgets/undo_snackbar.dart';
import 'auto_spell.dart';
import 'spell_learned_screen.dart';

/// Hızlı satırdaki yazım düzelt düğmesine BASILI TUT: yazım denetimi kipi
/// (Y-4: Kapalı / Yalnız göster / Otomatik düzelt), ÖĞRENEN düzeltme
/// anahtarı, öğrenilenleri silme (2026-11-08).
Future<void> showSpellSettings(
  BuildContext context, {
  VoidCallback? onReviewNote,
}) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  builder: (sheet) {
    final l10n = sheet.l10n;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpace.m),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SpellModePicker(
              key: ValueKey('spell-mode'),
              inset: AppSpace.l,
            ),
            if (onReviewNote != null)
              ListTile(
                key: const ValueKey('spell-review-note'),
                leading: const Icon(Icons.fact_check_outlined),
                title: Text(l10n.spellReviewNoteOption),
                onTap: () {
                  Navigator.pop(sheet);
                  onReviewNote();
                },
              ),
            ValueListenableBuilder<bool>(
              valueListenable: AutoSpell.learning,
              builder: (_, on, _) => SwitchListTile(
                key: const ValueKey('spell-learning'),
                secondary: const Icon(Icons.psychology_outlined),
                title: Text(l10n.spellLearnTitle),
                subtitle: Text(
                  '${l10n.spellLearnSubtitle}\n'
                  '${l10n.spellLearnedCount(AutoSpell.memory.learnedCount)}',
                ),
                isThreeLine: true,
                value: on,
                onChanged: AutoSpell.setLearning,
              ),
            ),
            ListTile(
              key: const ValueKey('spell-open-learned'),
              leading: const Icon(Icons.list_alt_outlined),
              title: Text(l10n.spellLearnedTitle),
              onTap: () {
                Navigator.pop(sheet);
                SpellLearnedScreen.open(context);
              },
            ),
            ListTile(
              key: const ValueKey('spell-forget'),
              leading: const Icon(Icons.delete_sweep_outlined),
              title: Text(l10n.spellForget),
              onTap: () {
                AutoSpell.forget();
                Navigator.pop(sheet);
                ScaffoldMessenger.maybeOf(context)
                    ?.showMessage(l10n.spellForgotten);
              },
            ),
          ],
        ),
      ),
    );
  },
);

/// **YAZIM DENETİMİ KİPİ** (Y-4, 17K §3.3): Kapalı / Yalnız göster /
/// Otomatik düzelt. Hızlı satırdaki düğme yalnız otomatik ↔ göster arasında
/// geçer; kapatmak buradan (levha ve Ayarlar → Kalem, yazım ve ekran).
class SpellModePicker extends StatefulWidget {
  const SpellModePicker({super.key, this.inset = 0});

  /// Yatay iç boşluk (levhada liste satırlarıyla hizalı, Ayarlar'da 0).
  final double inset;

  @override
  State<SpellModePicker> createState() => _SpellModePickerState();
}

class _SpellModePickerState extends State<SpellModePicker> {
  @override
  void initState() {
    super.initState();
    // Ayarlar not açılmadan açılabilir: kayıtlı kip yüklensin.
    unawaited(AutoSpell.load());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    ButtonSegment<SpellMode> seg(SpellMode m, String label) => ButtonSegment(
      value: m,
      label: Text(label, maxLines: 1, softWrap: false),
    );
    return ValueListenableBuilder<SpellMode>(
      valueListenable: AutoSpell.mode,
      builder: (context, mode, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: widget.inset),
            leading: const Icon(Icons.spellcheck_rounded),
            title: Text(l10n.spellModeTitle),
            subtitle: Text(l10n.spellModeInfo),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              widget.inset,
              0,
              widget.inset,
              AppSpace.s,
            ),
            child: SegmentedButton<SpellMode>(
              showSelectedIcon: false,
              segments: [
                seg(SpellMode.off, l10n.spellModeOff),
                seg(SpellMode.show, l10n.spellModeShow),
                seg(SpellMode.auto, l10n.spellModeAuto),
              ],
              selected: {mode},
              onSelectionChanged: (s) => AutoSpell.setMode(s.single),
            ),
          ),
          if (mode != SpellMode.off)
            ValueListenableBuilder<bool>(
              valueListenable: AutoSpell.checkDone,
              builder: (_, on, _) => SwitchListTile(
                key: const ValueKey('spell-check-done'),
                contentPadding: EdgeInsets.symmetric(horizontal: widget.inset),
                title: Text(l10n.spellCheckDoneTitle),
                subtitle: Text(l10n.spellCheckDoneSubtitle),
                value: on,
                onChanged: AutoSpell.setCheckDone,
              ),
            ),
        ],
      ),
    );
  }
}
