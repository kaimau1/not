import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../domain/note.dart';
import 'notes_repository.dart';

/// Android ana ekran widget'ını son notlarla besler.
final widgetServiceProvider = Provider<WidgetService>((ref) {
  final service = WidgetService(ref);
  ref.onDispose(service.dispose);
  service.start();
  return service;
});

class WidgetService {
  WidgetService(this._ref);

  final Ref _ref;
  ProviderSubscription<AsyncValue<List<Note>>>? _sub;

  void start() {
    if (kIsWeb || !Platform.isAndroid) return;
    _sub = _ref.listen(notesStreamProvider, (previous, next) {
      final notes = next.value;
      if (notes != null) _update(notes);
    }, fireImmediately: true);
  }

  Future<void> _update(List<Note> notes) async {
    try {
      final active = [for (final n in notes) if (n.archivedAt == null) n];
      final lines = <String>[];
      for (final note in active.take(5)) {
        final title = note.title.trim().isNotEmpty
            ? note.title.trim()
            : note.toPlainText().split('\n').first;
        if (title.trim().isEmpty) continue;
        lines.add('• ${title.length > 40 ? '${title.substring(0, 40)}…' : title}');
      }
      await HomeWidget.saveWidgetData<String>(
        'widget_notes',
        lines.isEmpty ? 'Henüz not yok' : lines.join('\n'),
      );
      await HomeWidget.saveWidgetData<String>(
        'widget_count',
        '${active.length} not',
      );
      await HomeWidget.updateWidget(androidName: 'NotlarWidgetProvider');
    } catch (e) {
      debugPrint('Widget güncellenemedi: $e');
    }
  }

  void dispose() {
    _sub?.close();
  }
}
