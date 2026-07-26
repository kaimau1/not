import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../../../core/utils/debouncer.dart';
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

  /// Yazarken her tuş vuruşu bir snapshot üretir; widget'ı her seferinde
  /// yenilemek boşuna işlem (ve pil) harcar. Art arda değişiklikler
  /// toplanıp tek güncellemeye iner.
  final _debouncer = Debouncer(delay: const Duration(seconds: 2));

  /// Son yazılan içerik; aynıysa widget hiç uyandırılmaz (pil tasarrufu).
  String? _lastPayload;

  void start() {
    if (kIsWeb || !Platform.isAndroid) return;
    _sub = _ref.listen(notesStreamProvider, (previous, next) {
      final notes = next.value;
      if (notes != null) _debouncer(() => _update(notes));
    }, fireImmediately: true);
  }

  Future<void> _update(List<Note> notes) async {
    try {
      final active = [
        for (final n in notes)
          if (n.archivedAt == null) n,
      ];
      // Başlıklar SADE gönderilir: madde imi ("• ") ve "not yok" metni artık
      // Android tarafının işi — her başlık kendi kart görünümüne düşüyor
      // (bkz. NotlarWidgetProvider). Widget dört satır gösteriyor.
      final lines = <String>[];
      for (final note in active.take(4)) {
        final title = note.title.trim().isNotEmpty
            ? note.title.trim()
            : note.toPlainText().split('\n').first;
        if (title.trim().isEmpty) continue;
        lines.add(title.length > 40 ? '${title.substring(0, 40)}…' : title);
      }
      final text = lines.join('\n');
      final count = '${active.length} not';
      final payload = '$count\n$text';
      if (payload == _lastPayload) return;
      _lastPayload = payload;
      await HomeWidget.saveWidgetData<String>('widget_notes', text);
      await HomeWidget.saveWidgetData<String>('widget_count', count);
      await HomeWidget.updateWidget(androidName: 'NotlarWidgetProvider');
    } catch (e) {
      debugPrint('Widget güncellenemedi: $e');
    }
  }

  void dispose() {
    _debouncer.dispose();
    _sub?.close();
  }
}
