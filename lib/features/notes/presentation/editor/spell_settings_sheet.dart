import 'package:flutter/material.dart';

import '../../../../core/l10n_ext.dart';
import 'auto_spell.dart';
import 'spell_learned_screen.dart';

/// Hızlı satırdaki yazım düzelt düğmesine BASILI TUT: otomatik düzelt ve
/// ÖĞRENEN düzeltme anahtarları, öğrenilenleri silme (2026-11-08).
Future<void> showSpellSettings(
  BuildContext context,
) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  builder: (sheet) {
    final l10n = sheet.l10n;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ValueListenableBuilder<bool>(
              valueListenable: AutoSpell.enabled,
              builder: (_, on, _) => SwitchListTile(
                key: const ValueKey('spell-enabled'),
                secondary: const Icon(Icons.spellcheck_rounded),
                title: Text(l10n.spellAutoTitle),
                subtitle: Text(l10n.spellAutoSubtitle),
                value: on,
                onChanged: (_) => AutoSpell.toggle(),
              ),
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
                  ?..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text(l10n.spellForgotten)));
              },
            ),
          ],
        ),
      ),
    );
  },
);
