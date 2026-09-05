import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  Future<void> _show(String folderId, String name, int count) async {
    try {
      await _ensureInitialized();
      await _plugin.show(
        id: notificationId(folderId),
        title: name.trim().isEmpty ? 'Paylaşılan klasör' : name.trim(),
        body: count == 1 ? '1 yeni hareket' : '$count yeni hareket',
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
        payload: 'folder:$folderId',
      );
    } catch (e) {
      // Bildirim altyapısı olmayan ortamlarda (test, masaüstü kurulumu
      // eksik) uygulamayı düşürme — rozet zaten çalışıyor.
      debugPrint('Paylaşım bildirimi gösterilemedi: $e');
    }
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
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
      // Dokunma AYRI bir ekrana götürmez: klasörün kendi rotası yok
      // (Navigator ile açılıyor, bkz. `FolderScreen.open`). Bildirime
      // dokunmak uygulamayı öne getirir, rozet zaten klasörü gösterir.
    );
    _initialized = true;
  }

  void dispose() {
    _rootSub?.close();
    _rootSub = null;
    for (final sub in _folderSubs) {
      sub.close();
    }
    _folderSubs.clear();
  }
}
