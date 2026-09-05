import 'package:flutter/material.dart';

import '../../../core/l10n_ext.dart';
import 'filter_sheet.dart' show sortLabel;
import 'notes_providers.dart';

/// Sıralama ölçütü menüsü — ana ekranın süzgeç levhasındaki listenin kısa
/// hâli. [NoteSort.manual] YOK: elle sıralama ana ekranın sürükle-bırak
/// kipiyle kurulur, klasör/arşiv sayfalarında o kip çalışmıyor.
///
/// Klasör ekranından çıkarıldı ki arşiv de aynı menüyü kullansın: iki ayrı
/// kopya iki ayrı davranış demekti.
class NoteSortMenu extends StatelessWidget {
  const NoteSortMenu({super.key, required this.current, required this.onPick});

  final NoteSort current;
  final ValueChanged<NoteSort> onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopupMenuButton<NoteSort>(
      tooltip: l10n.sortBy,
      icon: const Icon(Icons.sort),
      initialValue: current,
      onSelected: onPick,
      itemBuilder: (context) => [
        for (final sort in NoteSort.values)
          if (sort != NoteSort.manual)
            PopupMenuItem<NoteSort>(
              value: sort,
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: sort == current
                        ? const Icon(Icons.check, size: 18)
                        : null,
                  ),
                  Expanded(child: Text(sortLabel(l10n, sort))),
                ],
              ),
            ),
      ],
    );
  }
}
