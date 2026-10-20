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
import '../../../core/error_log.dart';
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

/// Uygulamanın BÜTÜN yerel bildirimlerine dokunuşun tek işleyicisi.
///
/// TUZAK: `FlutterLocalNotificationsPlugin` tekil; her `initialize` çağrısı
/// dokunuş işleyicisini DEĞİŞTİRİR. Paylaşım bildirimi servisi kendi
/// `initialize`'ını işleyicisiz çağırıyordu → ilk paylaşım bildiriminden
/// sonra hatırlatıcının "Tamam/1 saat ertele" düğmeleri ve dokunuşu
/// sessizce ölüyordu. İki servis de bu işlevi verir.
void handleNotificationResponse(Ref ref, NotificationResponse response) {
  final payload = response.payload ?? '';
  // Brifing bildirimine dokununca ilgili ekranı aç.
  if (payload == 'briefing') {
    try {
      ref.read(routerProvider).push('/briefing');
    } catch (e) {
      ErrorLog.record('notification-tap', e);
    }
    return;
  }
  // Arkadaştan gelen not (itme bildirimi, F4.6): gelen kutusu.
  if (payload == 'inbox') {
    try {
      ref.read(routerProvider).push('/inbox');
    } catch (e) {
      ErrorLog.record('notification-tap', e);
    }
    return;
  }
  // Paylaşılan klasör (sohbet / davet): klasörler ekranı.
  if (payload.startsWith('folder:')) {
    try {
      ref.read(routerProvider).push('/folders');
    } catch (e) {
      ErrorLog.record('notification-tap', e);
    }
    return;
  }
  // Benimle paylaşılan notta hareket: notu SAHİBİNİN altından aç.
  if (payload.startsWith('shared:')) {
    final rest = payload.substring('shared:'.length);
    final slash = rest.indexOf('/');
    if (slash <= 0) return;
    final ownerId = rest.substring(0, slash);
    final noteId = rest.substring(slash + 1);
    try {
      ref
          .read(routerProvider)
          .pushNote(noteRoutePath(noteId, query: '?owner=$ownerId'));
    } catch (e) {
      ErrorLog.record('notification-tap', e);
    }
    return;
  }
  // Hatırlatıcı bildirimi: aksiyon düğmeleri uygulamayı açmadan
  // önce burada işlenir; düz dokunuş ilgili notu açar.
  if (payload.startsWith('note:')) {
    final noteId = payload.substring('note:'.length);
    final repo = ref.read(notesRepositoryProvider);
    switch (response.actionId) {
      case 'done':
        repo?.setReminder(noteId, null);
      case 'snooze1h':
        repo?.setReminder(noteId, DateTime.now().add(const Duration(hours: 1)));
      default:
        try {
          ref.read(routerProvider).pushNote(noteRoutePath(noteId));
        } catch (e) {
          ErrorLog.record('notification-tap', e);
        }
    }
  }
}

/// Planlı bildirimlerden İPTAL edilmesi gereken not hatırlatıcıları (F5.3).
///
/// KÖK NEDEN: [ReminderService] planladıklarını yalnız bellekte tutuyor;
/// uygulama kapalıyken hatırlatıcı başka cihazdan kaldırılır ya da not
/// silinir/arşivlenirse AlarmManager'daki eski bildirim (yeniden başlatmada
/// da korunur) iptal edilmiyor ve ÇALIYORDU. Hesap değişince öbür hesabın
/// hatırlatıcıları da kalıyordu.
///
/// [pending]: cihazdaki planlı bildirimler; yalnız `note:` önekli olanlara
/// bakılır (brifing `briefing`). [wanted]: hâlâ istenen not → beklenen
/// bildirim kimliği. Kimliği beklenenden farklı olan da yetimdir
/// (`String.hashCode` Dart sürümleri arasında kararlı değil) — yenisi
/// zaten planlanır.
List<int> orphanReminderIds(
  Iterable<({int id, String? payload})> pending,
  Map<String, int> wanted,
) {
  const prefix = 'note:';
  return [
    for (final r in pending)
      if (r.payload != null &&
          r.payload!.startsWith(prefix) &&
          wanted[r.payload!.substring(prefix.length)] != r.id)
        r.id,
  ];
}

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

    // Bildirim küçük simgesi tek renk siluet olmalı (bkz. ic_stat_notlar.xml).
    const androidInit = AndroidInitializationSettings(
      '@drawable/ic_stat_notlar',
    );
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidInit,
      ),
      onDidReceiveNotificationResponse: (response) =>
          handleNotificationResponse(_ref, response),
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
          ),
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

  /// Bu süreçte AlarmManager'daki planlı bildirimlerle mutabakat yapıldı mı
  /// (F5.3, bkz. [orphanReminderIds]).
  bool _reconciled = false;

  Future<void> _reconcilePending(Set<String> wanted) async {
    if (_reconciled) return;
    _reconciled = true;
    try {
      final pending = await _plugin.pendingNotificationRequests();
      final orphans = orphanReminderIds(
        [for (final r in pending) (id: r.id, payload: r.payload)],
        {for (final id in wanted) id: _notificationId(id)},
      );
      for (final id in orphans) {
        await _plugin.cancel(id: id);
      }
    } catch (e) {
      debugPrint('Planlı hatırlatıcılar okunamadı: $e');
    }
  }

  Future<void> _syncReminders(List<Note> notes) async {
    try {
      await _ensureInitialized();
      final now = DateTime.now();
      final wanted = <String, Note>{
        for (final note in notes)
          if (note.reminderAt != null && note.reminderAt!.isAfter(now))
            note.id: note,
      };

      // Uygulama kapalıyken (başka cihazda) kaldırılan/silinen notların
      // eski bildirimleri: `_scheduled` yalnız bellekte, onları bilmez.
      await _reconcilePending(wanted.keys.toSet());

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
