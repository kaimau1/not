import 'dart:async';
import 'dart:io';

import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
// 10 yıllık pencere yeter: tam IANA veritabanının yarısından küçük ve
// initializeTimeZones ilk dashboard karesinde SENKRON ayrıştırılıyor —
// hatırlatıcılar zaten en fazla birkaç ay ileriye kurulur.
import 'package:timezone/data/latest_10y.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../../app/router.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../settings/settings_providers.dart';
import '../domain/note.dart';
import 'notes_repository.dart';

const _monthsTr = [
  'Oca',
  'Şub',
  'Mar',
  'Nis',
  'May',
  'Haz',
  'Tem',
  'Ağu',
  'Eyl',
  'Eki',
  'Kas',
  'Ara',
];

/// Bildirim gövdesinin başına konan mutlak zaman.
///
/// Not metni çoğu zaman ham konuşma dökümüdür ve içinde "yarın saat 9'da"
/// gibi GÖRELİ sözler donar: not yarın okununca "yarın" artık yanlıştır.
/// Önek her zaman gerçek zamanı söyler, not metnine dokunulmaz.
///
/// Ay adları elle yazılı: `intl`'in Türkçe adları için uygulama başında
/// `initializeDateFormatting` çağrılması gerekir, bildirim planlaması ise
/// arka planda da koşuyor — 12 sabit dizgi bu bağımlılıktan ucuz.
@visibleForTesting
String reminderTimePrefix(DateTime when, {DateTime? now, AppLocalizations? l10n}) {
  final reference = now ?? DateTime.now();
  final today = DateTime(reference.year, reference.month, reference.day);
  final day = DateTime(when.year, when.month, when.day);
  final clock =
      '${when.hour.toString().padLeft(2, '0')}:'
      '${when.minute.toString().padLeft(2, '0')}';
  switch (day.difference(today).inDays) {
    case 0:
      return '${l10n?.dateToday ?? 'Bugün'} $clock';
    case 1:
      return '${l10n?.dateTomorrow ?? 'Yarın'} $clock';
    default:
      return '${when.day} ${_monthsTr[when.month - 1]} $clock';
  }
}

/// Bildirim metinleri için uygulamanın SEÇİLİ dilini yükler.
///
/// KÖK NEDEN (2026-09-05 taraması): bildirim metinleri — "Günaydın!",
/// "1 saat ertele", "Bugün/Yarın" ve kanal adları — koda Türkçe gömülüydü.
/// Arayüzü Fransızca yapan bir kullanıcı her sabah Türkçe bir bildirim
/// alıyordu. Servisin `BuildContext`i yok; çeviriler doğrudan delegeden
/// yüklenir. Desteklenmeyen bir yerel ayarda şablon dile (Türkçe) düşülür —
/// eski davranış.
Future<AppLocalizations> loadNotificationL10n(Locale? preferred) {
  final locale = preferred ?? PlatformDispatcher.instance.locale;
  return AppLocalizations.delegate.isSupported(locale)
      ? AppLocalizations.delegate.load(locale)
      : AppLocalizations.delegate.load(const Locale('tr'));
}

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
        final payload = response.payload ?? '';
        // Brifing bildirimine dokununca ilgili ekranı aç.
        if (payload == 'briefing') {
          try {
            _ref.read(routerProvider).push('/briefing');
          } catch (_) {}
          return;
        }
        // Hatırlatıcı bildirimi: aksiyon düğmeleri uygulamayı açmadan
        // önce burada işlenir; düz dokunuş ilgili notu açar.
        if (payload.startsWith('note:')) {
          final noteId = payload.substring('note:'.length);
          final repo = _ref.read(notesRepositoryProvider);
          switch (response.actionId) {
            case 'done':
              repo?.setReminder(noteId, null);
            case 'snooze1h':
              repo?.setReminder(
                noteId,
                DateTime.now().add(const Duration(hours: 1)),
              );
            default:
              try {
                _ref.read(routerProvider).push(noteRoutePath(noteId));
              } catch (_) {}
          }
        }
      },
    );

    if (!kIsWeb && Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    }
    _initialized = true;
  }

  static const _briefingNotificationId = 999001;

  /// Hatırlatıcı eşitlemesi de geciktirilir (yükleme kuyruğuyla aynı gerekçe):
  /// not akışı her tuş vuruşunda yayın yapıyor ve `_syncReminders` her
  /// seferinde tüm notları gezip platform kanalına iptal/planlama çağrıları
  /// yapıyordu. Birkaç saniyelik gecikme kullanıcıya görünmez.
  Timer? _syncDebounce;

  void start() {
    _sub = _ref.listen(notesStreamProvider, (previous, next) {
      final notes = next.value;
      if (notes == null) return;
      _syncDebounce?.cancel();
      _syncDebounce = Timer(
        const Duration(seconds: 3),
        () => _syncReminders(notes),
      );
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

      final l10n = await loadNotificationL10n(_ref.read(localeProvider));
      await _plugin.zonedSchedule(
        id: _briefingNotificationId,
        title: l10n.briefingNotificationTitle,
        body: l10n.briefingNotificationBody,
        scheduledDate: next,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'briefing',
            l10n.briefingTitle,
            channelDescription: l10n.briefingSettingInfo,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          windows: const WindowsNotificationDetails(),
        ),
        // BİLEREK inexact (hatırlatıcılardan farklı): sabah brifingi birkaç
        // dakika kaysa kimse fark etmez; exact alarm hem her sabah Doze'u
        // kırıp pil yakıyor hem de USE_EXACT_ALARM'ın Play politikası
        // (yalnız alarm/takvim uygulamaları) riskini büyütüyordu. Dakikası
        // dakikasına çalması gereken NOT hatırlatıcıları exact kalır.
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

      // Yeni veya zamanı değişenleri planla. try/catch DÖNGÜNÜN İÇİNDE:
      // tek bir hatırlatıcının hatası (ör. Android 12'de kullanıcı
      // SCHEDULE_EXACT_ALARM iznini kapattıysa exact_alarms_not_permitted)
      // dıştaki catch'e taşınsaydı kalan hatırlatıcıların HİÇBİRİ
      // planlanmıyordu.
      for (final entry in wanted.entries) {
        final note = entry.value;
        if (_scheduled[entry.key] == note.reminderAt) continue;
        try {
          await _scheduleReminder(entry.key, note);
          _scheduled[entry.key] = note.reminderAt!;
        } catch (e) {
          debugPrint('Hatırlatıcı planlanamadı (${entry.key}): $e');
        }
      }
    } catch (e) {
      // Bildirim altyapısı olmayan ortamlarda uygulamayı düşürme.
      debugPrint('Hatırlatıcı planlanamadı: $e');
    }
  }

  Future<void> _scheduleReminder(String noteId, Note note) async {
    final l10n = await loadNotificationL10n(_ref.read(localeProvider));
    final title = note.displayTitle.trim().isEmpty
        ? l10n.remindersUntitled
        : note.displayTitle.trim();
    final preview = note.toPlainText();
    final trimmed = preview.length > 120
        ? '${preview.substring(0, 120)}…'
        : preview;
    // Önek ÇALMA anına göre: bildirim tam reminderAt'te görünür, yani o an
    // "bugün"dür. Planlama anına göre hesaplansaydı yarına kurulan
    // hatırlatıcı çaldığında hâlâ "Yarın 09:00" yazıyordu.
    final prefix = reminderTimePrefix(
      note.reminderAt!,
      now: note.reminderAt,
      l10n: l10n,
    );
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'reminders',
        l10n.remindersTitle,
        channelDescription: l10n.remindersTitle,
        importance: Importance.high,
        priority: Priority.high,
        // Uygulamayı açmadan hızlı işlem; showsUserInterface uygulamayı
        // öne getirir ki işlem güvenilir biçimde ana izolatta yapılsın.
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            'done',
            l10n.reminderDone,
            showsUserInterface: true,
          ),
          AndroidNotificationAction(
            'snooze1h',
            l10n.reminderSnooze,
            showsUserInterface: true,
          ),
        ],
      ),
      windows: WindowsNotificationDetails(),
    );
    final body = trimmed.trim().isEmpty ? prefix : '$prefix · $trimmed';
    final scheduledDate = tz.TZDateTime.from(note.reminderAt!, tz.local);
    try {
      await _plugin.zonedSchedule(
        id: _notificationId(noteId),
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'note:$noteId',
      );
    } on PlatformException catch (e) {
      // Kullanıcı kesin alarm iznini kapatmış olabilir: hatırlatıcı hiç
      // kurulmamaktansa birkaç dakika kayabilen inexact ile kurulur.
      if (e.code != 'exact_alarms_not_permitted') rethrow;
      await _plugin.zonedSchedule(
        id: _notificationId(noteId),
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'note:$noteId',
      );
    }
  }

  void dispose() {
    _syncDebounce?.cancel();
    _sub?.close();
    _briefingSub?.close();
  }
}
