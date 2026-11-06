import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/l10n_ext.dart';

/// Basılı tutarken yatay kaymanın seçtiği durak: her [step] dp bir klasör,
/// uçlarda durur (sarmaz — parmağın neredeyse orada olduğu tahmin edilsin).
int folderIndexForDrag(int start, double dx, int count, {double step = 36}) {
  if (count <= 0) return 0;
  return (start + (dx / step).truncate()).clamp(0, count - 1);
}

/// **KLASÖR DÜĞMESİ** (kullanıcı isteği 2026-11-06: "klasörler için alta bir
/// klasör butonu; basınca klasörler sayfası açılır, basılı tutarken hafif
/// kaydırarak klasörler arası geçiş").
///
/// Dokun → [onOpen] (Klasörler ekranı). Basılı tut → düğmenin üstünde
/// klasör adları şeridi belirir; parmağı sağa/sola kaydırdıkça seçim kayar
/// (her adımda hafif titreşim), bırakınca [onSelect] o klasörü açar.
/// Durak 0 = "Tümü" (`null`).
class FolderHoldButton extends StatefulWidget {
  const FolderHoldButton({
    super.key,
    required this.stops,
    required this.currentId,
    required this.onOpen,
    required this.onSelect,
  });

  /// (kimlik, ad); ilki `(null, "Tümü")`.
  final List<(String?, String)> stops;
  final String? currentId;
  final VoidCallback onOpen;
  final ValueChanged<String?> onSelect;

  @override
  State<FolderHoldButton> createState() => _FolderHoldButtonState();
}

class _FolderHoldButtonState extends State<FolderHoldButton> {
  int? _index;
  int _start = 0;

  int get _currentIndex {
    final i = widget.stops.indexWhere((s) => s.$1 == widget.currentId);
    return i < 0 ? 0 : i;
  }

  void _begin(LongPressStartDetails _) {
    HapticFeedback.mediumImpact();
    setState(() {
      _start = _currentIndex;
      _index = _start;
    });
  }

  void _move(LongPressMoveUpdateDetails d) {
    final next = folderIndexForDrag(
      _start,
      d.offsetFromOrigin.dx,
      widget.stops.length,
    );
    if (next != _index) {
      HapticFeedback.selectionClick();
      setState(() => _index = next);
    }
  }

  void _end(LongPressEndDetails _) {
    final i = _index;
    setState(() => _index = null);
    if (i != null && i != _currentIndex) widget.onSelect(widget.stops[i].$1);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final index = _index;
    final current = widget.stops.isEmpty ? null : widget.stops[_currentIndex];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (index != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              key: const ValueKey('folder-hold-strip'),
              elevation: 3,
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < widget.stops.length; i++)
                      if ((i - index).abs() <= 2)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: i == index
                                ? scheme.primaryContainer
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            widget.stops[i].$2,
                            style: TextStyle(
                              fontWeight: i == index
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: i == index
                                  ? scheme.onPrimaryContainer
                                  : scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ),
        Semantics(
          button: true,
          label: l10n.allFolders,
          hint: l10n.folderHoldHint,
          child: GestureDetector(
            key: const ValueKey('folder-hold-button'),
            onLongPressStart: widget.stops.length > 1 ? _begin : null,
            onLongPressMoveUpdate: widget.stops.length > 1 ? _move : null,
            onLongPressEnd: widget.stops.length > 1 ? _end : null,
            child: FloatingActionButton.small(
              heroTag: 'folderHold',
              // İpucu YOK: Tooltip basılı tutmayı kendisi yakalar, kaydırarak
              // klasör seçme hiç başlamazdı (ad Semantics'te).
              onPressed: widget.onOpen,
              child: Icon(
                current?.$1 == null ? Icons.folder_outlined : Icons.folder,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
