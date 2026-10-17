import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../notes/data/note_shares_repository.dart';
import '../../notes/data/notes_repository.dart';
import '../../notes/data/reminder_service.dart';
import '../../notes/data/shared_note_activity.dart';
import '../../settings/settings_providers.dart';
import 'folder_activity.dart';

/// **PAYLAŞILAN KLASÖR BİLDİRİMİ** (kullanıcı isteği 2026-09-04: "karşı
/// taraf yeni bir not eklediğinde veya bir notta değişiklik yaptığında veya
/// sohbet kısmında bir mesaj attığında … telefona bildirim gelmeli").
///
/// İzlenen klasörlerin okunmamış sayacı ([folderUnreadProvider]) ARTTIĞINDA
/// yerel bir bildirim gösterir. Klasör başına TEK bildirim (aynı kimlik):
/// on mesaj on bildirim değil, "Ortak notlar · 10 yeni hareket" — bildirim
/// gölü kullanıcıyı uygulamayı susturmaya iter.
///
/// **SINIR (bilinçli):** bu YEREL bir bildirimdir, sunucu itmesi (FCM)
/// değil. Uygulama tümden kapalıyken Firestore dinleyicisi de kapalıdır ve
/// bildirim ancak uygulama bir daha açıldığında düşer. Gerçek arka plan
/// itmesi Cloud Functions + firebase_messaging ister — bkz. KALANLAR.md.
final sharedActivityServiceProvider = Provider<SharedActivityService>((ref) {
  final service = SharedActivityService(ref);
  ref.onDispose(service.dispose);
  service.start();
  return service;
});

class SharedActivityService {
  SharedActivityService(this._ref);

  final Ref _ref;
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// folderId → en son BİLDİRİLEN sayaç. Sayaç artmadıkça yeniden
  /// bildirilmez; okununca (sayaç 0) kayıt düşer.
  final _notified = <String, int>{};

  /// İzlenen klasör listesinin aboneliği — klasör aboneliklerinden AYRI
  /// tutuluyor: tek listede olsalardı "kökü koru, kalanını yenile" işlemi
  /// bir dizin varsayımına dayanırdı ve ilk `fireImmediately` turunda
  /// (liste henüz boşken) o varsayım tutmuyordu.
  ProviderSubscription<dynamic>? _rootSub;
  final _folderSubs = <ProviderSubscription<dynamic>>[];

  /// BENİMLE PAYLAŞILAN NOTLAR (ortak not, kullanıcı bulgusu 2026-10-17:
  /// "yeni bir şey geldiğinde anlaşılmıyor"): liste aboneliği ilk görüşte
  /// mevcut paylaşımları "görülmüş" sayar (bkz. [SharedNoteSeenNotifier.adopt]),
  /// okunmamış kümesi büyüdükçe not başına tek bildirim düşer.
  ProviderSubscription<dynamic>? _sharesSub;
  ProviderSubscription<Set<String>>? _noteUnreadSub;

  /// Bildirilmiş paylaşım → o anki notun `updatedAt`'i (ms). Not yeniden
  /// değişmedikçe ikinci bildirim düşmez.
  final _notifiedNotes = <String, int>{};

  /// Bildirim kimliği klasör kimliğinden türetilir: aynı klasörün ikinci
  /// bildirimi birincinin ÜSTÜNE yazar.
  static int notificationId(String folderId) =>
      0x5000000 | (folderId.hashCode & 0xFFFFFF);

  void start() {
    // İzlenen klasör listesi değiştikçe abonelikler yenilenir: yeni
    // paylaşılan klasör kendiliğinden izlemeye girer.
    _rootSub = _ref.listen(
      watchedSharedFoldersProvider,
      (_, _) => _resubscribe(),
      fireImmediately: true,
    );
    _sharesSub = _ref.listen<AsyncValue<List<NoteShare>>>(
      sharedNotesWithMeProvider,
      (_, next) {
        final shares = next.value;
        if (shares == null) return;
        final ids = {for (final s in shares) s.id};
        final seen = _ref.read(sharedNoteSeenProvider.notifier);
        seen.adopt(ids);
        seen.retain(ids);
      },
      fireImmediately: true,
    );
    _noteUnreadSub = _ref.listen<Set<String>>(
      sharedNoteUnreadProvider,
      (_, next) => unawaited(_onNoteUnread(next)),
      fireImmediately: true,
    );
  }

  Future<void> _onNoteUnread(Set<String> unread) async {
    // Okunanların bildirimi kalkar (rozet söndü, bildirim durmasın).
    for (final id in [..._notifiedNotes.keys]) {
      if (unread.contains(id)) continue;
      _notifiedNotes.remove(id);
      if (_initialized) {
        try {
          await _plugin.cancel(id: notificationId('note:$id'));
        } catch (_) {}
      }
    }
    if (unread.isEmpty) return;
    final shares = {
      for (final s
          in _ref.read(sharedNotesWithMeProvider).value ?? const <NoteShare>[])
        s.id: s,
    };
    for (final id in unread) {
      final share = shares[id];
      if (share == null) continue;
      final note = _ref
          .read(
            ownedNoteStreamProvider((
              ownerId: share.ownerId,
              noteId: share.noteId,
            )),
          )
          .value;
      if (note == null) continue;
      // Not şu an editörde açık: bakıyorum zaten (editör birazdan "görüldü"
      // damgasını basar), bildirim gürültü olurdu.
      if (openEditorNoteIds.contains(note.id)) continue;
      final at = note.updatedAt?.millisecondsSinceEpoch ?? 0;
      if ((_notifiedNotes[id] ?? -1) >= at) continue;
      final fresh = !_notifiedNotes.containsKey(id) &&
          !_ref.read(sharedNoteSeenProvider).containsKey(id);
      _notifiedNotes[id] = at;
      if (!_ref.read(sharedNotificationsProvider)) continue;
      // Kim yaptı: sahip ya da öbür ortak çalışanlardan biri.
      final who = note.updatedBy == share.ownerId
          ? share.ownerName
          : (share.names[note.updatedBy] ?? share.ownerName);
      final title = note.displayTitle.trim();
      await _showRaw(
        id: notificationId('note:$id'),
        title: title.isEmpty ? 'Ortak not' : title,
        body: fresh
            ? (who.isEmpty
                  ? 'Seninle bir not paylaşıldı'
                  : '$who seninle bir not paylaştı')
            : (who.isEmpty ? 'Not güncellendi' : '$who notu güncelledi'),
        payload: 'shared:${share.ownerId}/${share.noteId}',
      );
    }
  }

  void _resubscribe() {
    for (final sub in _folderSubs) {
      sub.close();
    }
    _folderSubs.clear();
    for (final folder in _ref.read(watchedSharedFoldersProvider)) {
      final key = (ownerId: folder.ownerId, folderId: folder.folderId);
      _folderSubs.add(
        _ref.listen<int>(folderUnreadProvider(key), (previous, next) {
          unawaited(_onUnread(folder.folderId, folder.name, next));
        }, fireImmediately: true),
      );
    }
  }

  Future<void> _onUnread(String folderId, String name, int count) async {
    if (count <= 0) {
      _notified.remove(folderId);
      // Okunmuşsa duran bildirimi de kaldır: rozet söndü, bildirim durmasın.
      if (_initialized) {
        try {
          await _plugin.cancel(id: notificationId(folderId));
        } catch (_) {}
      }
      return;
    }
    // Yalnız ARTIŞTA bildir: aynı sayaç yeniden yayınlandığında (başka bir
    // sağlayıcı değişince Riverpod yeniden hesaplar) ikinci bildirim düşmesin.
    if ((_notified[folderId] ?? 0) >= count) return;
    _notified[folderId] = count;
    if (!_ref.read(sharedNotificationsProvider)) return;
    await _show(folderId, name, count);
  }

  Future<void> _show(String folderId, String name, int count) => _showRaw(
    id: notificationId(folderId),
    title: name.trim().isEmpty ? 'Paylaşılan klasör' : name.trim(),
    body: count == 1 ? '1 yeni hareket' : '$count yeni hareket',
    payload: 'folder:$folderId',
  );

  Future<void> _showRaw({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) async {
    try {
      await _ensureInitialized();
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'shared_folders',
            'Paylaşılan klasörler',
            channelDescription:
                'Paylaşılan klasörlerdeki not ve mesaj hareketleri',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          windows: WindowsNotificationDetails(),
        ),
        payload: payload,
      );
    } catch (e) {
      // Bildirim altyapısı olmayan ortamlarda (test, masaüstü kurulumu
      // eksik) uygulamayı düşürme — rozet zaten çalışıyor.
      debugPrint('Paylaşım bildirimi gösterilemedi: $e');
    }
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    // Bildirim küçük simgesi tek renk siluet olmalı (bkz. ic_stat_notlar.xml).
    const androidInit = AndroidInitializationSettings(
      '@drawable/ic_stat_notlar',
    );
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
      // Klasör bildirimine dokunmak uygulamayı öne getirir (klasörün kendi
      // rotası yok, rozet onu gösterir); ortak not bildirimi notu açar.
      // İşleyici TEK ve ortak (bkz. handleNotificationResponse): eklentinin
      // `initialize`'ı öncekinin işleyicisini değiştirir.
      onDidReceiveNotificationResponse: (response) =>
          handleNotificationResponse(_ref, response),
    );
    _initialized = true;
  }

  void dispose() {
    _rootSub?.close();
    _rootSub = null;
    _sharesSub?.close();
    _noteUnreadSub?.close();
    for (final sub in _folderSubs) {
      sub.close();
    }
    _folderSubs.clear();
  }
}
