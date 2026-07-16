import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../../app/router.dart';
import '../../settings/settings_providers.dart';
import '../domain/note.dart';
import 'notes_repository.dart';

/// Not hatırlatıcılarını yerel bildirime çeviren servis. Not akışını izler;
/// gelecekteki her hatırlatıcı için bildirim planlar, kaldırılanları iptal
/// eder. Firestore senkronu sayesinde bir cihazda kurulan hatırlatıcı diğer
/// cihazlarda da (uygulama açıldığında) planlanır.
final reminderServiceProvider = Provider<ReminderService>((ref) {
  final service = ReminderService(ref);
  ref.onDispose(service.dispose);
  service.start();
  return service;
});

class ReminderService {
  ReminderService(this._ref);

  final Ref _ref;
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  ProviderSubscription<AsyncValue<List<Note>>>? _sub;

  /// Planlanan bildirimlerin not bazında takibi (id → zaman).
  final Map<String, DateTime> _scheduled = {};

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    try {
      final localTz = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTz.identifier));
    } catch (_) {
      // Bilinmeyen dilim: UTC ile devam et.
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const windowsInit = WindowsInitializationSettings(
      appName: 'Notlar',
      appUserModelId: 'dev.kaimau.notlar',
      guid: 'a9c8f3d2-4b1e-4f6a-9d3c-2e8b7a6c5d4e',
    );
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidInit,
        windows: windowsInit,
      ),
      onDidReceiveNotificationResponse: (response) {
        // Brifing bildirimine dokununca ilgili ekranı aç.
        if (response.payload == 'briefing') {
          try {
            _ref.read(routerProvider).push('/briefing');
          } catch (_) {}
        }
      },
    );

    if (!kIsWeb && Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
    _initialized = true;
  }

  static const _briefingNotificationId = 999001;

  void start() {
    _sub = _ref.listen(notesStreamProvider, (previous, next) {
      final notes = next.value;
      if (notes != null) _syncReminders(notes);
    }, fireImmediately: true);

    // Günlük brifing ayarını izle ve bildirimi buna göre planla/iptal et.
    _briefingSub = _ref.listen(briefingSettingsProvider, (previous, next) {
      _syncBriefing(next);
    }, fireImmediately: true);
  }

  ProviderSubscription<BriefingSettings>? _briefingSub;

  Future<void> _syncBriefing(BriefingSettings settings) async {
    try {
      await _ensureInitialized();
      await _plugin.cancel(id: _briefingNotificationId);
      if (!settings.enabled) return;

      final now = tz.TZDateTime.now(tz.local);
      var next = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        settings.minutes ~/ 60,
        settings.minutes % 60,
      );
      if (!next.isAfter(now)) next = next.add(const Duration(days: 1));

      await _plugin.zonedSchedule(
        id: _briefingNotificationId,
        title: 'Günaydın! ☀️',
        body: 'Bugünün brifingi hazır — hatırlatıcıların, notların ve '
            'önemli e-postaların özeti için dokun.',
        scheduledDate: next,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'briefing',
            'Günlük Brifing',
            channelDescription: 'Günlük brifing bildirimi',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          windows: WindowsNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'briefing',
      );
    } catch (e) {
      debugPrint('Brifing bildirimi planlanamadı: $e');
    }
  }

  static int _notificationId(String noteId) => noteId.hashCode & 0x7fffffff;

  Future<void> _syncReminders(List<Note> notes) async {
    try {
      await _ensureInitialized();
      final now = DateTime.now();
      final wanted = <String, Note>{
        for (final note in notes)
          if (note.reminderAt != null && note.reminderAt!.isAfter(now))
            note.id: note,
      };

      // Kaldırılan veya geçmişte kalanları iptal et.
      for (final id in _scheduled.keys.toList()) {
        if (!wanted.containsKey(id)) {
          await _plugin.cancel(id: _notificationId(id));
          _scheduled.remove(id);
        }
      }

      // Yeni veya zamanı değişenleri planla.
      for (final entry in wanted.entries) {
        final note = entry.value;
        if (_scheduled[entry.key] == note.reminderAt) continue;
        final title =
            note.title.trim().isEmpty ? 'Not hatırlatıcısı' : note.title.trim();
        final preview = note.toPlainText();
        await _plugin.zonedSchedule(
          id: _notificationId(entry.key),
          title: title,
          body: preview.length > 120 ? '${preview.substring(0, 120)}…' : preview,
          scheduledDate: tz.TZDateTime.from(note.reminderAt!, tz.local),
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'reminders',
              'Hatırlatıcılar',
              channelDescription: 'Not hatırlatıcı bildirimleri',
              importance: Importance.high,
              priority: Priority.high,
            ),
            windows: WindowsNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
        _scheduled[entry.key] = note.reminderAt!;
      }
    } catch (e) {
      // Bildirim altyapısı olmayan ortamlarda uygulamayı düşürme.
      debugPrint('Hatırlatıcı planlanamadı: $e');
    }
  }

  void dispose() {
    _sub?.close();
    _briefingSub?.close();
  }
}
