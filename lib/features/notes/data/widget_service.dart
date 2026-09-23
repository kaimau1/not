import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../../../core/utils/debouncer.dart';
import '../../settings/settings_providers.dart';
import '../domain/note.dart';
import '../presentation/notes_providers.dart';
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

  /// Tema değişimini izleyen abonelikler. Kullanıcı temayı değiştirir
  /// değiştirmez widget da dönmeli; not değişikliğini beklemek "widget eski
  /// temada kaldı" demek olurdu.
  final _themeSubs = <ProviderSubscription<Object?>>[];

  /// Son yazılan tema; aynıysa widget uyandırılmaz.
  String? _lastTheme;

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
    // Temayı ETKİLEYEN iki ayar. `effectiveThemeModeProvider` autoDispose
    // olduğundan buradan izlenemez (autoDispose olmayan sağlayıcı onu
    // dinleyemez); kaynaklarını dinleyip değeri okuma anında hesaplıyoruz.
    for (final provider in [themeChoiceProvider, darkScheduleProvider]) {
      _themeSubs.add(
        _ref.listen<Object?>(provider, (_, _) => _pushTheme()),
      );
    }
    _pushTheme();
  }

  /// Geçerli temayı widget'a yazar.
  ///
  /// Üç değer: `light`, `dark`, `system`. Sistem seçiliyken Android tarafı
  /// hiçbir şeye dokunmaz — kaynak niteleyicileri (values-night/) zaten doğru
  /// olanı seçiyor (bkz. WidgetTheme.kt).
  ///
  /// BİLİNEN SINIR: gece zamanlaması AÇIKKEN mod saat başına dakikada bir
  /// tiklerle döner ve o anki dönüşü buraya itmiyoruz; widget bir sonraki not
  /// ya da ayar değişiminde yakalar. Dakikada bir widget uyandırmak pil
  /// açısından bu kadar küçük bir kazanca değmiyor.
  Future<void> _pushTheme() async {
    try {
      final theme = switch (_ref.read(effectiveThemeModeProvider)) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };
      if (theme == _lastTheme) return;
      _lastTheme = theme;
      await HomeWidget.saveWidgetData<String>('widget_theme', theme);
      await _updateAllWidgets();
    } catch (e) {
      debugPrint('Widget teması yazılamadı: $e');
    }
  }

  /// Dört widget sağlayıcısının hepsi yenilenir: tema hepsini ilgilendiriyor
  /// (not listesi yalnız NotlarWidgetProvider'ı).
  Future<void> _updateAllWidgets() async {
    for (final name in const [
      'NotlarWidgetProvider',
      'QuickActionsWidgetProvider',
      'QuickNoteWidgetProvider',
      'VoiceWidgetProvider',
      'TodayWidgetProvider',
    ]) {
      await HomeWidget.updateWidget(androidName: name);
    }
  }

  Future<void> _update(List<Note> notes) async {
    try {
      // Kilitli notlar widget'a HİÇ çıkmaz: biyometrik kilitli notun ilk
      // satırı, telefon kilitliyken bile ana ekranda okunabiliyordu (uygulama
      // içinde kilitliyi ayıklayan diğer yüzeylerle aynı kural).
      // GİZLİ klasördeki notlar da çıkmaz: uygulama içinde doğrulamasız
      // görünmeyen notun başlığı ana ekranda okunuyordu.
      final hidden = _ref.read(hiddenFolderIdsProvider);
      final active = [
        for (final n in notes)
          if (n.archivedAt == null &&
              !n.locked &&
              !hidden.contains(n.folderId))
            n,
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
      final today = todayWidgetPayload(
        notes,
        DateTime.now(),
        hiddenFolders: hidden,
      );
      final payload = '$count\n$text\n\u0000$today';
      if (payload == _lastPayload) return;
      _lastPayload = payload;
      await HomeWidget.saveWidgetData<String>('widget_today', today);
      await HomeWidget.updateWidget(androidName: 'TodayWidgetProvider');
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
    for (final sub in _themeSubs) {
      sub.close();
    }
    _themeSubs.clear();
  }
}

/// "Bugün" widget'ının verisi: ŞİMDİDEN (bugünün başından) itibaren 7 gün
/// içindeki hatırlatıcılar, `epochMillis<TAB>başlık` satırları.
///
/// Bugüne AİT olanları Android tarafı çizim anında süzer (bkz.
/// TodayWidgetProvider.kt): böylece gece yarısı geçince uygulama açılmasa da
/// widget ertesi günün listesini gösterir — bir haftalık pay bunun için.
///
/// Arşivdeki notlar çıkmaz; KİLİTLİ notun ve GİZLİ klasördeki notun başlığı
/// ana ekrana sızmasın diye yerine [lockedLabel] yazılır (hatırlatıcının
/// saati yine görünür).
@visibleForTesting
String todayWidgetPayload(
  List<Note> notes,
  DateTime now, {
  String lockedLabel = '🔒',
  Set<String> hiddenFolders = const {},
}) {
  final from = DateTime(now.year, now.month, now.day);
  final to = from.add(const Duration(days: 7));
  final items = <({DateTime at, String title})>[];
  for (final n in notes) {
    final at = n.reminderAt;
    if (at == null || n.archivedAt != null) continue;
    if (at.isBefore(from) || !at.isBefore(to)) continue;
    var title = n.locked || hiddenFolders.contains(n.folderId)
        ? lockedLabel
        : (n.title.trim().isNotEmpty
              ? n.title.trim()
              : n.toPlainText().split('\n').first.trim());
    if (title.isEmpty) title = '…';
    // Satır ayırıcıları başlığın içinde olamaz (Android tarafı böler).
    title = title.replaceAll(RegExp(r'[\t\n\r]'), ' ');
    if (title.length > 48) title = '${title.substring(0, 48)}…';
    items.add((at: at, title: title));
  }
  items.sort((a, b) => a.at.compareTo(b.at));
  return [
    for (final i in items) '${i.at.millisecondsSinceEpoch}\t${i.title}',
  ].join('\n');
}
