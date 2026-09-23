import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/note.dart';
import 'notes_repository.dart';

/// Konuma bağlı hatırlatıcının kaydı (cihaza özel — bkz. PlaceReminders.kt).
@immutable
class PlaceReminder {
  const PlaceReminder({
    required this.id,
    required this.lat,
    required this.lng,
    required this.radius,
    required this.exit,
    required this.title,
    required this.body,
    required this.place,
  });

  /// Notun kimliği: not başına bir konum hatırlatıcısı.
  final String id;
  final double lat;
  final double lng;

  /// Metre.
  final double radius;

  /// true = ayrılınca, false = varınca.
  final bool exit;

  /// Bildirimin başlığı (notun adı) ve gövdesi — kurulurken UYGULAMANIN
  /// dilinde yazılır; bildirim uygulama kapalıyken Android'den çıkıyor.
  final String title;
  final String body;

  /// Yerin kullanıcıya görünen adı.
  final String place;

  Map<String, Object> toMap() => {
    'id': id,
    'lat': lat,
    'lng': lng,
    'radius': radius,
    'exit': exit,
    'title': title,
    'body': body,
    'place': place,
  };

  static PlaceReminder fromMap(Map<Object?, Object?> m) => PlaceReminder(
    id: m['id']! as String,
    lat: (m['lat']! as num).toDouble(),
    lng: (m['lng']! as num).toDouble(),
    radius: (m['radius']! as num).toDouble(),
    exit: m['exit'] as bool? ?? false,
    title: m['title'] as String? ?? '',
    body: m['body'] as String? ?? '',
    place: m['place'] as String? ?? '',
  );
}

/// Konum izninin durumu.
enum PlacePermission { none, foreground, background }

/// Yerel köprü (MainActivity) üzerinden geofence işleri. Yalnız Android.
class PlaceReminderService {
  static const _channel = MethodChannel('dev.kaimau.notlar/system');

  static bool get supported => !kIsWeb && Platform.isAndroid;

  static PlacePermission _parse(Object? value) => switch (value) {
    'background' => PlacePermission.background,
    'foreground' => PlacePermission.foreground,
    _ => PlacePermission.none,
  };

  Future<PlacePermission> permission() async =>
      _parse(await _channel.invokeMethod<String>('placePermission'));

  Future<PlacePermission> request({required bool background}) async => _parse(
    await _channel.invokeMethod<String>('requestPlacePermission', {
      'background': background,
    }),
  );

  Future<({double lat, double lng})?> currentLocation() async {
    final m = await _channel.invokeMapMethod<String, Object?>(
      'placeCurrentLocation',
    );
    if (m == null) return null;
    return (
      lat: (m['lat']! as num).toDouble(),
      lng: (m['lng']! as num).toDouble(),
    );
  }

  Future<List<({String name, double lat, double lng})>> geocode(
    String query,
  ) async {
    final list = await _channel.invokeListMethod<Object?>('placeGeocode', {
      'query': query,
    });
    return [
      for (final raw in list ?? const <Object?>[])
        if (raw is Map)
          (
            name: raw['name'] as String? ?? query,
            lat: (raw['lat']! as num).toDouble(),
            lng: (raw['lng']! as num).toDouble(),
          ),
    ];
  }

  Future<List<PlaceReminder>> list() async {
    final list = await _channel.invokeListMethod<Object?>('placeList');
    return [
      for (final raw in list ?? const <Object?>[])
        if (raw is Map) PlaceReminder.fromMap(raw),
    ];
  }

  /// Kurar; hata kodu (`no_background`, `location_off`, …) ya da null döner.
  Future<String?> add(PlaceReminder reminder) =>
      _channel.invokeMethod<String>('placeAdd', reminder.toMap());

  Future<void> remove(String id) =>
      _channel.invokeMethod<void>('placeRemove', {'id': id});
}

final placeReminderServiceProvider = Provider<PlaceReminderService>(
  (ref) => PlaceReminderService(),
);

/// Bu cihazda kurulu konum hatırlatıcıları (not kimliği → kayıt). Kurulup
/// kaldırıldıkça [PlaceRemindersNotifier.refresh] ile tazelenir; tetiklenen
/// (tek seferlik) hatırlatıcılar uygulama bir sonraki okuyuşta düşer.
final placeRemindersProvider =
    AsyncNotifierProvider<PlaceRemindersNotifier, Map<String, PlaceReminder>>(
      PlaceRemindersNotifier.new,
    );

class PlaceRemindersNotifier extends AsyncNotifier<Map<String, PlaceReminder>> {
  @override
  Future<Map<String, PlaceReminder>> build() => _load();

  Future<Map<String, PlaceReminder>> _load() async {
    if (!PlaceReminderService.supported) return const {};
    try {
      final items = await ref.read(placeReminderServiceProvider).list();
      return {for (final r in items) r.id: r};
    } catch (_) {
      return const {};
    }
  }

  Future<void> refresh() async => state = AsyncData(await _load());
}

/// Notu SİLİNEN ya da ARŞİVLENEN konum hatırlatıcılarını sistemden kaldırır:
/// geofence notun kendisinden bağımsız yaşıyor, silinmiş bir not için
/// markete her girişte bildirim gelmesin. Ana ekran ayakta tutar.
final placeReminderCleanupProvider = Provider<void>((ref) {
  if (!PlaceReminderService.supported) return;
  ref.listen<AsyncValue<List<Note>>>(notesStreamProvider, (_, next) async {
    final notes = next.value;
    if (notes == null) return;
    final places = ref.read(placeRemindersProvider).value;
    if (places == null || places.isEmpty) return;
    final alive = {
      for (final n in notes)
        if (n.archivedAt == null && n.deletedAt == null) n.id,
    };
    var changed = false;
    for (final id in places.keys) {
      if (alive.contains(id)) continue;
      await ref.read(placeReminderServiceProvider).remove(id);
      changed = true;
    }
    if (changed) await ref.read(placeRemindersProvider.notifier).refresh();
  }, fireImmediately: true);
});
