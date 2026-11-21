import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/l10n_ext.dart';
import 'filter_sheet.dart' show sortLabel;
import 'notes_providers.dart';

/// Sıralama ölçütü menüsü — ana ekranın süzgeç levhasındaki listenin kısa
/// hâli. [NoteSort.manual] YOK: elle sıralama ana ekranın sürükle-bırak
/// kipiyle kurulur, klasör/arşiv sayfalarında o kip çalışmıyor.
///
/// Klasör ekranından çıkarıldı ki arşiv de aynı menüyü kullansın: iki ayrı
/// kopya iki ayrı davranış demekti.
/// [NoteSortMenu]'nün sıralamadan önceki ek satırı (ör. Arşiv özeti).
class NoteMenuExtra {
  const NoteMenuExtra({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

/// Ek satır verilirse ([extras]) menü ekranın ⋮ menüsü olur (F79.4, D19:
/// üst çubukta Ara + ⋮): önce ek satırlar, çizgi, "Sıralama" başlığı altında
/// ölçütler.
class NoteSortMenu extends StatelessWidget {
  const NoteSortMenu({
    super.key,
    required this.current,
    required this.onPick,
    this.extras = const [],
  });

  final NoteSort current;
  final ValueChanged<NoteSort> onPick;
  final List<NoteMenuExtra> extras;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final asMore = extras.isNotEmpty;
    return PopupMenuButton<Object>(
      tooltip: asMore ? l10n.more : l10n.sortBy,
      icon: Icon(asMore ? Icons.more_vert : Icons.sort),
      initialValue: current,
      onSelected: (value) {
        if (value is NoteSort) onPick(value);
        if (value is NoteMenuExtra) value.onTap();
      },
      itemBuilder: (context) {
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        return [
          for (final extra in extras)
            PopupMenuItem<Object>(
              value: extra,
              child: Row(
                children: [
                  Icon(extra.icon, size: AppIconSize.m, color: scheme.primary),
                  const SizedBox(width: AppSpace.m),
                  Expanded(child: Text(extra.label)),
                ],
              ),
            ),
          if (asMore) ...[
            const PopupMenuDivider(height: 1),
            PopupMenuItem<Object>(
              enabled: false,
              height: 32,
              child: Text(l10n.sortBy, style: AppText.of(theme).meta),
            ),
          ],
          for (final sort in NoteSort.values)
            if (sort != NoteSort.manual)
              PopupMenuItem<Object>(
                value: sort,
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      child: sort == current
                          ? Icon(
                              Icons.check,
                              size: AppIconSize.s,
                              color: scheme.primary,
                            )
                          : null,
                    ),
                    Expanded(
                      child: Text(
                        sortLabel(l10n, sort),
                        style: sort == current
                            ? TextStyle(
                                color: scheme.primary,
                                fontWeight: AppWeight.strong,
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
        ];
      },
    );
  }
}
