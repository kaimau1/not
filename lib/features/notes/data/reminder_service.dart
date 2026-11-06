import '../domain/reminder_repeat.dart';

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
import '../../../core/utils/run_heavy.dart';
import '../domain/trash_analysis.dart' show trashReminderPlan;
import 'notes_repository.dart';
import '../../calendar/data/calendar_repository.dart';
import '../../calendar/domain/calendar_alarms.dart';
import '../../calendar/domain/calendar_event.dart';
import '../../calendar/domain/task_item.dart';

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
String reminderTimePrefix(
  DateTime when, {
  DateTime? now,
  AppLocalizations? l10n,
}) {
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
  // Çöp hatırlatması (D3): çöp kutusu.
  if (payload == 'trash') {
    try {
      ref.read(routerProvider).push('/trash');
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
  // Takvim etkinliği / görev (TAKVIM_PLANI F47.6): takvimi aç.
  if (payload.startsWith(kCalendarPayloadPrefix)) {
    try {
      ref.read(routerProvider).push('/calendar');
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
    // Tekrarlayan hatırlatıcı (F18.14): "Tamam" sonraki çalmaya kaydırır;
    // "Ertele" tek seferlik ayrı bir bildirim kurar — reminderAt'i bir saat
    // kaydırmak tekrarın SAATİNİ de kaydırırdı.
    final note = (ref.read(notesStreamProvider).value ?? const <Note>[])
        .where((n) => n.id == noteId)
        .firstOrNull;
    final repeat = ReminderRepeat.parse(note?.reminderRepeat);
    final now = DateTime.now();
    switch (response.actionId) {
      case 'done':
        if (note?.reminderAt != null && !repeat.isNone) {
          repo?.setReminder(noteId, repeat.next(note!.reminderAt!, now));
        } else {
          repo?.setReminder(noteId, null);
        }
      case 'snooze1h':
        final later = now.add(const Duration(hours: 1));
        if (note != null && !repeat.isNone) {
          unawaited(ref.read(reminderServiceProvider).snooze(note, later));
        } else {
          repo?.setReminder(noteId, later);
        }
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
  Map<String, Set<int>> wanted,
) {
  const prefix = 'note:';
  return [
    for (final r in pending)
      if (r.payload != null &&
          r.payload!.startsWith(prefix) &&
          !(wanted[r.payload!.substring(prefix.length)]?.contains(r.id) ??
              false))
        r.id,
  ];
}

/// Notun planlanacak çalma anları (F18.14): tek seferlikte yalnız gelecekteki
/// [Note.reminderAt]; tekrarlıda sonraki [count] çalma — uygulama günlerce
/// açılmasa da her gün/hafta çalsın diye birkaç tanesi ÖNCEDEN kurulur.
/// Geçmişte kalmış tekrarlı hatırlatıcı bir sonrakine ilerler.
List<DateTime> reminderFireTimes(Note note, DateTime now, {int count = 7}) {
  final at = note.reminderAt;
  if (at == null) return const [];
  final repeat = ReminderRepeat.parse(note.reminderRepeat);
  if (repeat.isNone) return at.isAfter(now) ? [at] : const [];
  final first = at.isAfter(now) ? at : repeat.next(at, now);
  if (first == null) return const [];
  return [first, ...repeat.upcoming(at, first, count - 1)];
}

class ReminderService {
  ReminderService(this._ref);

  final Ref _ref;
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  ProviderSubscription<AsyncValue<List<Note>>>? _sub;

  /// Planlanan bildirimlerin not bazında takibi (id → zaman|tekrar imzası).
  final Map<String, String> _scheduled = {};

  /// Tekrarlı notta önceden kurulan çalma sayısı (F18.14).
  static const _repeatAhead = 7;

  static int _occurrenceId(String noteId, int k) =>
      k == 0 ? _notificationId(noteId) : '$noteId#$k'.hashCode & 0x7fffffff;

  static int _snoozeId(String noteId) => '$noteId#snooze'.hashCode & 0x7fffffff;

  static Set<int> _idsFor(String noteId) => {
    for (var k = 0; k < _repeatAhead; k++) _occurrenceId(noteId, k),
    _snoozeId(noteId),
  };

  static String _signature(Note n) =>
      '${n.reminderAt?.millisecondsSinceEpoch}|${n.reminderRepeat}';

  Future<void> _cancelAll(String noteId) async {
    for (var k = 0; k < _repeatAhead; k++) {
      await _plugin.cancel(id: _occurrenceId(noteId, k));
    }
  }

  /// Tekrarlı hatırlatıcıyı bir saat ertele: tek seferlik ayrı bildirim
  /// (sıradaki düzenli çalmalar yerinde kalır).
  Future<void> snooze(Note note, DateTime at) async {
    try {
      await _ensureInitialized();
      await _scheduleOne(_snoozeId(note.id), note.id, note, at);
    } catch (e) {
      debugPrint('Erteleme kurulamadı: $e');
    }
  }

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
      settings: const InitializationSettings(android: androidInit),
      onDidReceiveNotificationResponse: (response) =>
          handleNotificationResponse(_ref, response),
    );

    _initialized = true;
  }

  bool _permissionAsked = false;

  /// BİLDİRİM İZNİ BAĞLAMDA (F11.9, 2026-10-31): eskiden kurulumda — yani
  /// uygulamanın ilk açılışında, hiç hatırlatıcı yokken — soruluyordu. Artık
  /// ilk kez planlanacak bir bildirim (hatırlatıcı, brifing, çöp
  /// hatırlatması) olduğunda, oturumda bir kez. İzin zaten verildiyse sistem
  /// kutu açmaz.
  Future<void> _askPermissionOnce() async {
    if (_permissionAsked || kIsWeb || !Platform.isAndroid) return;
    _permissionAsked = true;
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  static const _briefingNotificationId = 999001;

  /// Çöp hatırlatması (D3) — yükü `note:` ile BAŞLAMAZ (mutabakat onu
  /// yetim sanıp iptal ederdi, bkz. [orphanReminderIds]).
  static const _trashNotificationId = 999002;
  ProviderSubscription<AsyncValue<List<Note>>>? _trashSub;
  Timer? _trashDebounce;
  DateTime? _trashPlanned;

  /// Çöpte not varken parmak izi hesabı not sayısıyla büyür: ana iş
  /// parçacığından uzakta (F25.3). Kapanış örnek alanı yakalamaz (`runHeavy`).
  static Future<({DateTime at, int count})?> _trashPlan(
    List<Note> trash,
    List<Note> active,
  ) {
    if (trash.isEmpty) return Future.value();
    return runHeavy(
      () => trashReminderPlan(
        trash,
        active: active,
        retention: NotesRepository.trashRetention,
      ),
    );
  }

  Future<void> _syncTrash(List<Note> trash) async {
    try {
      await _ensureInitialized();
      final active = [
        for (final n in _ref.read(notesStreamProvider).value ?? const <Note>[])
          if (n.deletedAt == null) n,
      ];
      final plan = await _trashPlan(trash, active);
      if (plan?.at == _trashPlanned) return;
      await _plugin.cancel(id: _trashNotificationId);
      _trashPlanned = plan?.at;
      if (plan == null) return;
      await _askPermissionOnce();
      final l10n = await loadNotificationL10n(_ref.read(localeProvider));
      await _plugin.zonedSchedule(
        id: _trashNotificationId,
        title: l10n.trashReminderTitle,
        body: l10n.trashReminderBody(plan.count),
        scheduledDate: tz.TZDateTime.from(plan.at, tz.local),
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'trash',
            l10n.trashTitle,
            channelDescription: l10n.trashReminderTitle,
          ),
        ),
        // Bir gün önceden haber: dakikası önemli değil (brifing gibi).
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'trash',
      );
    } catch (e) {
      debugPrint('Çöp hatırlatması planlanamadı: $e');
    }
  }

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

    // Çöpte "geri yüklemeyi düşün" notu kalıcı silinmeden bir gün önce (D3).
    _trashSub = _ref.listen(trashStreamProvider, (previous, next) {
      final trash = next.value;
      if (trash == null) return;
      _trashDebounce?.cancel();
      _trashDebounce = Timer(
        const Duration(seconds: 5),
        () => _syncTrash(trash),
      );
    }, fireImmediately: true);

    // Takvim etkinlikleri ve görevler (F47.6) — yalnız cihazda (web'de
    // yerel bildirim yok; dinleyici açılışta boşuna Firestore okumasın).
    if (!kIsWeb) {
      _calEventsSub = _ref.listen(
        eventsStreamProvider,
        (_, _) => _scheduleCalendarSync(),
        fireImmediately: true,
      );
      _calTasksSub = _ref.listen(
        tasksStreamProvider,
        (_, _) => _scheduleCalendarSync(),
        fireImmediately: true,
      );
    }

    // Günlük brifing ayarını izle ve bildirimi buna göre planla/iptal et.
    _briefingSub = _ref.listen(briefingSettingsProvider, (previous, next) {
      _syncBriefing(next);
    }, fireImmediately: true);
  }

  ProviderSubscription<BriefingSettings>? _briefingSub;

  ProviderSubscription<AsyncValue<List<CalendarEvent>>>? _calEventsSub;
  ProviderSubscription<AsyncValue<List<TaskItem>>>? _calTasksSub;
  Timer? _calDebounce;

  /// Kurulu takvim bildirimleri: kimlik → imza.
  final Map<int, String> _calScheduled = {};
  bool _calReconciled = false;

  void _scheduleCalendarSync() {
    _calDebounce?.cancel();
    _calDebounce = Timer(const Duration(seconds: 3), () {
      final events = _ref.read(eventsStreamProvider).value;
      final tasks = _ref.read(tasksStreamProvider).value;
      if (events == null || tasks == null) return;
      unawaited(_syncCalendar(events, tasks));
    });
  }

  Future<void> _syncCalendar(
    List<CalendarEvent> events,
    List<TaskItem> tasks,
  ) async {
    try {
      await _ensureInitialized();
      final alarms = calendarAlarms(
        events: events,
        tasks: tasks,
        now: DateTime.now(),
      );
      final wanted = {for (final a in alarms) a.notificationId: a};
      if (wanted.isNotEmpty) await _askPermissionOnce();
      // Uygulama kapalıyken silinen/değişen kayıtların eski bildirimleri.
      if (!_calReconciled) {
        _calReconciled = true;
        final pending = await _plugin.pendingNotificationRequests();
        for (final r in pending) {
          if ((r.payload ?? '').startsWith(kCalendarPayloadPrefix) &&
              !wanted.containsKey(r.id)) {
            await _plugin.cancel(id: r.id);
          }
        }
      }
      for (final id in _calScheduled.keys.toList()) {
        if (!wanted.containsKey(id)) {
          await _plugin.cancel(id: id);
          _calScheduled.remove(id);
        }
      }
      if (wanted.isEmpty) return;
      final l10n = await loadNotificationL10n(_ref.read(localeProvider));
      for (final a in wanted.values) {
        if (_calScheduled[a.notificationId] == a.signature) continue;
        try {
          await _scheduleCalendarAlarm(a, l10n);
          _calScheduled[a.notificationId] = a.signature;
        } catch (e) {
          debugPrint('Takvim bildirimi kurulamadı: $e');
        }
      }
    } catch (e) {
      debugPrint('Takvim bildirimleri planlanamadı: $e');
    }
  }

  Future<void> _scheduleCalendarAlarm(
    CalendarAlarm a,
    AppLocalizations l10n,
  ) async {
    final title = a.title.trim().isEmpty ? l10n.eventUntitled : a.title.trim();
    // intl tarih biçimi YOK: arka planda yerel ayar verisi yüklü olmayabilir
    // (bkz. [reminderTimePrefix]).
    final dayDiff = DateTime(a.start.year, a.start.month, a.start.day)
        .difference(DateTime(a.at.year, a.at.month, a.at.day))
        .inDays;
    final body = !a.allDay
        ? reminderTimePrefix(a.start, now: a.at, l10n: l10n)
        : dayDiff == 0
        ? l10n.eventNotificationAllDay
        : dayDiff == 1
        ? '${l10n.dateTomorrow} · ${l10n.eventAllDay}'
        : l10n.eventAllDay;
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'calendar',
        l10n.calendarTitle,
        channelDescription: l10n.calendarTitle,
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
    final when = tz.TZDateTime.from(a.at, tz.local);
    try {
      await _plugin.zonedSchedule(
        id: a.notificationId,
        title: title,
        body: body,
        scheduledDate: when,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: a.payload,
      );
    } on PlatformException catch (e) {
      if (e.code != 'exact_alarms_not_permitted') rethrow;
      await _plugin.zonedSchedule(
        id: a.notificationId,
        title: title,
        body: body,
        scheduledDate: when,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: a.payload,
      );
    }
  }

  Future<void> _syncBriefing(BriefingSettings settings) async {
    try {
      await _ensureInitialized();
      await _plugin.cancel(id: _briefingNotificationId);
      if (!settings.enabled) return;
      await _askPermissionOnce();

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
        {for (final id in wanted) id: _idsFor(id)},
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
          if (reminderFireTimes(note, now, count: 1).isNotEmpty) note.id: note,
      };
      // Geçmişte kalmış TEKRARLI hatırlatıcı notta da ilerletilir (F18.14):
      // kartlar ve Hatırlatıcılar ekranı sonraki çalmayı göstersin.
      final repo = _ref.read(notesRepositoryProvider);
      for (final note in wanted.values) {
        final at = note.reminderAt!;
        if (at.isAfter(now)) continue;
        final next = reminderFireTimes(note, now, count: 1).first;
        repo?.setReminder(note.id, next);
      }

      if (wanted.isNotEmpty) await _askPermissionOnce();

      // Uygulama kapalıyken (başka cihazda) kaldırılan/silinen notların
      // eski bildirimleri: `_scheduled` yalnız bellekte, onları bilmez.
      await _reconcilePending(wanted.keys.toSet());

      // Kaldırılan veya geçmişte kalanları iptal et.
      for (final id in _scheduled.keys.toList()) {
        if (!wanted.containsKey(id)) {
          await _cancelAll(id);
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
        if (_scheduled[entry.key] == _signature(note)) continue;
        try {
          await _cancelAll(entry.key);
          final times = reminderFireTimes(note, now);
          for (var k = 0; k < times.length; k++) {
            await _scheduleOne(
              _occurrenceId(entry.key, k),
              entry.key,
              note,
              times[k],
            );
          }
          _scheduled[entry.key] = _signature(note);
        } catch (e) {
          debugPrint('Hatırlatıcı planlanamadı (${entry.key}): $e');
        }
      }
    } catch (e) {
      // Bildirim altyapısı olmayan ortamlarda uygulamayı düşürme.
      debugPrint('Hatırlatıcı planlanamadı: $e');
    }
  }

  Future<void> _scheduleOne(
    int id,
    String noteId,
    Note note,
    DateTime when,
  ) async {
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
    final prefix = reminderTimePrefix(when, now: when, l10n: l10n);
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
    final scheduledDate = tz.TZDateTime.from(when, tz.local);
    try {
      await _plugin.zonedSchedule(
        id: id,
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
        id: id,
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
    _trashDebounce?.cancel();
    _sub?.close();
    _trashSub?.close();
    _briefingSub?.close();
    _calDebounce?.cancel();
    _calEventsSub?.close();
    _calTasksSub?.close();
  }
}
