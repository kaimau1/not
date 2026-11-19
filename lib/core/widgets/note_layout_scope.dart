import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import '../l10n_ext.dart';
import '../personalize.dart';

/// **TÜMÜNE / YALNIZ BU NOTA** (kullanıcı isteği 2026-11-19): menü düzenini
/// (hızlı satır, alt çubuk) düzenlerken değişikliğin nereye yazılacağı.
/// "Yalnız bu nota" açık notun kendi düzenini açar (genel düzenin kopyası),
/// "Tümüne uygula" ya da "Bu notun özelleştirmesini sıfırla" onu siler —
/// not genel düzene döner. Açık not yoksa (Ayarlar) hiçbir şey çizmez.
///
/// Kayıt [Personalize.setNoteOwnLayout]; düzenleme yerleri
/// [Personalize.updateLayout] ile yazar.
class NoteLayoutScopeBar extends StatelessWidget {
  const NoteLayoutScopeBar({super.key, this.compact = false});

  /// Dar açılır menü (alt çubuk ⋯, 280 dp): kısa etiketler.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (Personalize.activeNote == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: Personalize.noteOverride,
      builder: (context, _) {
        final own = Personalize.noteHasOwnLayout;
        return Column(
          key: const ValueKey('note-layout-scope'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<bool>(
              showSelectedIcon: false,
              style: compact
                  ? const ButtonStyle(visualDensity: VisualDensity.compact)
                  : null,
              segments: [
                ButtonSegment(
                  value: false,
                  label: Text(
                    l10n.layoutScopeAll,
                    key: const ValueKey('note-layout-scope-all'),
                    maxLines: 1,
                    softWrap: false,
                  ),
                ),
                ButtonSegment(
                  value: true,
                  label: Text(
                    l10n.layoutScopeNote,
                    key: const ValueKey('note-layout-scope-note'),
                    maxLines: 1,
                    softWrap: false,
                  ),
                ),
              ],
              selected: {own},
              onSelectionChanged: (s) => Personalize.setNoteOwnLayout(s.first),
            ),
            const SizedBox(height: AppSpace.xs),
            Text(
              own ? l10n.layoutScopeInfoNote : l10n.layoutScopeInfoAll,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (own)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  key: const ValueKey('note-layout-scope-reset'),
                  onPressed: () => Personalize.setNoteOwnLayout(false),
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: Text(l10n.layoutScopeReset),
                ),
              ),
          ],
        );
      },
    );
  }
}
