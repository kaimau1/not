import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../domain/note.dart';

/// [source]'tan [select] ile seçilen dilim değişince yalnız bu alt ağaç
/// kurulur (OTURTMA F64.2, P20). Dilim dışı alan değişince `setState` YOK;
/// kaynak `null` olursa son değer korunur.
class NoteSlice<T> extends StatefulWidget {
  const NoteSlice({
    super.key,
    required this.source,
    required this.select,
    required this.builder,
    this.equals,
  });

  final ValueListenable<Note?> source;
  final T Function(Note note) select;

  /// null → `==`.
  final bool Function(T a, T b)? equals;
  final Widget Function(BuildContext context, T value) builder;

  @override
  State<NoteSlice<T>> createState() => _NoteSliceState<T>();
}

class _NoteSliceState<T> extends State<NoteSlice<T>> {
  T? _value;
  bool _has = false;

  @override
  void initState() {
    super.initState();
    _read();
    widget.source.addListener(_onChange);
  }

  @override
  void didUpdateWidget(NoteSlice<T> old) {
    super.didUpdateWidget(old);
    if (old.source != widget.source) {
      old.source.removeListener(_onChange);
      widget.source.addListener(_onChange);
    }
    // Seçici değişmiş olabilir; üst kurulum bizi zaten yeniden kuruyor.
    _read();
  }

  @override
  void dispose() {
    widget.source.removeListener(_onChange);
    super.dispose();
  }

  /// Dilim değiştiyse true.
  bool _read() {
    final note = widget.source.value;
    if (note == null) return false;
    final next = widget.select(note);
    if (_has) {
      final same = widget.equals?.call(_value as T, next) ?? _value == next;
      if (same) return false;
    }
    _value = next;
    _has = true;
    return true;
  }

  void _onChange() {
    if (_read() && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) =>
      _has ? widget.builder(context, _value as T) : const SizedBox.shrink();
}

/// `ValueNotifier` gibi, ama `dispose` SONRASI yazım sessizce saklanır
/// (bildirim yok, istisna yok): editörün `dispose`'u ve geç geri çağrılar
/// (`_saveNow`, akış, yükleme sonu) `_note`'u hâlâ yazıp okuyabiliyor.
class LateSafeValue<T> extends ChangeNotifier implements ValueListenable<T> {
  LateSafeValue(this._value);

  T _value;
  bool _disposed = false;

  @override
  T get value => _value;
  set value(T v) {
    if (_value == v) return;
    _value = v;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
