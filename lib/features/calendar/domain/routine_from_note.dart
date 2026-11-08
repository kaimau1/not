import '../../notes/domain/note.dart';
import 'routine.dart';

/// **NOTTAN RUTİN** (2026-11-08): bir notun başlığı rutin adı, maddeleri (yoksa
/// gövdedeki dolu satırlar) rutin adımları olur. Saf; en çok [maxSteps] adım.
({String title, List<RoutineStep> steps}) routineFromNote(
  Note note, {
  int maxSteps = 20,
}) {
  final lines = [
    for (final i in note.items)
      if (i.text.trim().isNotEmpty) i.text.trim(),
  ];
  if (lines.isEmpty) {
    for (final raw in note.body.split('\n')) {
      final t = raw.replaceFirst(RegExp(r'^\s*(?:[-*•]|\d+[.)])\s+'), '').trim();
      if (t.isNotEmpty) lines.add(t);
    }
  }
  final stamp = DateTime.now().microsecondsSinceEpoch;
  return (
    title: note.displayTitle.trim(),
    steps: [
      for (var i = 0; i < lines.length && i < maxSteps; i++)
        RoutineStep(id: 's$stamp$i', text: lines[i]),
    ],
  );
}
