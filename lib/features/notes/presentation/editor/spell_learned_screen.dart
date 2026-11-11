import 'package:flutter/material.dart';

import '../../../../core/l10n_ext.dart';
import 'auto_spell.dart';

/// **ÖĞRENİLEN YAZIMLAR** (kullanıcı isteği 2026-11-08: "öğrenilenler
/// ayarlarda bir menüde görülebilmeli, kişi oraya elle `yanlış → doğru`
/// ekleyebilmeli"). Liste [SpellMemory.fixes]; elle eklenen ilk görüşte
/// uygulanır. Silme o düzeltmeyi unutur. v2 (Faz 70): üstte "otomatik
/// düzelt" ve "yalnız kurallar" anahtarları; altta reddedilen düzeltme
/// çiftleri ve dokunulmayan kelimeler — çipi silmek yeniden açar.
class SpellLearnedScreen extends StatefulWidget {
  const SpellLearnedScreen({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const SpellLearnedScreen()));

  @override
  State<SpellLearnedScreen> createState() => _SpellLearnedScreenState();
}

class _SpellLearnedScreenState extends State<SpellLearnedScreen> {
  final _from = TextEditingController();
  final _to = TextEditingController();
  final _fromFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Hafıza henüz yüklenmediyse (editör hiç açılmadı) yükle.
    AutoSpell.load().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _from.dispose();
    _to.dispose();
    _fromFocus.dispose();
    super.dispose();
  }

  void _add() {
    final from = _from.text.trim();
    final to = _to.text.trim();
    if (from.isEmpty || to.isEmpty) return;
    setState(() => AutoSpell.memory.addManualFix(from, to));
    AutoSpell.changed();
    _from.clear();
    _to.clear();
    _fromFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final fixes = AutoSpell.memory.fixList();
    final rejected = AutoSpell.memory.rejected.toList()..sort();
    final keep = AutoSpell.memory.keep.toList()..sort();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.spellLearnedTitle)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              l10n.spellLearnedInfo,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: AutoSpell.enabled,
            builder: (_, on, _) => SwitchListTile(
              key: const ValueKey('spell-learned-auto'),
              title: Text(l10n.spellAutoTitle),
              value: on,
              onChanged: (_) => AutoSpell.toggle(),
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: AutoSpell.rulesOnly,
            builder: (_, on, _) => SwitchListTile(
              key: const ValueKey('spell-learned-rules-only'),
              title: Text(l10n.spellRulesOnlyTitle),
              subtitle: Text(l10n.spellRulesOnlySubtitle),
              value: on,
              onChanged: AutoSpell.setRulesOnly,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const ValueKey('spell-add-from'),
                    controller: _from,
                    focusNode: _fromFocus,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      labelText: l10n.spellLearnedWrong,
                      isDense: true,
                      border: const OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(Icons.arrow_forward, size: 18),
                ),
                Expanded(
                  child: TextField(
                    key: const ValueKey('spell-add-to'),
                    controller: _to,
                    decoration: InputDecoration(
                      labelText: l10n.spellLearnedRight,
                      isDense: true,
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _add(),
                  ),
                ),
                IconButton(
                  key: const ValueKey('spell-add'),
                  tooltip: l10n.spellLearnedAdd,
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: _add,
                ),
              ],
            ),
          ),
          if (fixes.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.spellLearnedEmpty,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ),
          for (final f in fixes)
            ListTile(
              key: ValueKey('spell-fix-${f.from}'),
              dense: true,
              title: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: f.from,
                      style: TextStyle(
                        color: scheme.error,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const TextSpan(text: '  →  '),
                    TextSpan(
                      text: f.to,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              subtitle: Text(l10n.spellLearnedSeen(f.count)),
              trailing: IconButton(
                tooltip: l10n.delete,
                icon: const Icon(Icons.delete_outline),
                onPressed: () {
                  setState(() => AutoSpell.memory.removeFix(f.from));
                  AutoSpell.changed();
                },
              ),
            ),
          ..._chips(l10n.spellRejectedTitle, rejected),
          ..._chips(l10n.spellLearnedKept, keep),
        ],
      ),
    );
  }

  /// Reddedilen çiftler (`a>b`, "a → b" diye gösterilir) ya da dokunulmaz
  /// kelimeler; çipi silmek yeniden açar.
  List<Widget> _chips(String title, List<String> keys) => [
    if (keys.isNotEmpty) ...[
      const Divider(),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Text(title, style: Theme.of(context).textTheme.titleSmall),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final k in keys)
              InputChip(
                label: Text(k.replaceFirst('>', ' → ')),
                onDeleted: () {
                  setState(() => AutoSpell.memory.unreject(k));
                  AutoSpell.changed();
                },
              ),
          ],
        ),
      ),
    ],
  ];
}
