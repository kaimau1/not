import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../settings/settings_providers.dart';
import 'reminder_service.dart';

/// **ARKA PLAN İTME BİLDİRİMLERİ — İSTEMCİ** (F4.6, 2026-10-19).
///
/// Cihazın FCM jetonu `users/{uid}/fcmTokens/{jeton}` belgesine yazılır;
/// Cloud Functions (functions/push.js) paylaşım olaylarında bu jetonlara
/// bildirim gönderir — uygulama KAPALIYKEN de düşer. Uygulama açıkken
/// sistem FCM bildirimini göstermez; o sırada yerel servis
/// (SharedActivityService) zaten bildiriyor — çift bildirim olmaz.
///
/// Hesap değişince eski jeton SİLİNİR (`deleteToken`): çıkış yapılan
/// hesabın bildirimleri bu cihaza düşmeye devam etmesin; sunucu geçersiz
/// jetonu bir sonraki gönderimde temizler.
///
/// Yalnız Android (web itmesi VAPID anahtarı + hizmet çalışanı ister).
final pushServiceProvider = Provider<void>((ref) {
  if (kIsWeb || !Platform.isAndroid) return;
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return;
  final service = _PushService(ref, uid);
  ref.onDispose(service.dispose);
  unawaited(service.start());
});

const _lastUidKey = 'fcm_token_uid';

class _PushService {
  _PushService(this._ref, this._uid);

  final Ref _ref;
  final String _uid;
  final _subs = <StreamSubscription<Object?>>[];

  DocumentReference<Map<String, dynamic>> _doc(String token) =>
      FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(_uid)
          .collection('fcmTokens')
          .doc(token);

  Future<void> start() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final prefs = _ref.read(sharedPreferencesProvider);
      final last = prefs.getString(_lastUidKey);
      if (last != null && last != _uid) await messaging.deleteToken();
      await prefs.setString(_lastUidKey, _uid);
      final token = await messaging.getToken();
      if (token != null) await _save(token);
      _subs.add(messaging.onTokenRefresh.listen((t) => unawaited(_save(t))));
      // Bildirime dokunarak açılış: yerel bildirimlerle AYNI yük biçimi
      // ('shared:…', 'folder:…') — tek işleyici.
      _subs.add(FirebaseMessaging.onMessageOpenedApp.listen(_open));
      final initial = await messaging.getInitialMessage();
      if (initial != null) _open(initial);
    } catch (e) {
      debugPrint('FCM başlatılamadı: $e');
    }
  }

  Future<void> _save(String token) => _doc(token)
      .set({'platform': 'android', 'updatedAt': FieldValue.serverTimestamp()});

  void _open(RemoteMessage message) {
    final payload = message.data['payload'] as String?;
    if (payload == null) return;
    handleNotificationResponse(
      _ref,
      NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: payload,
      ),
    );
  }

  void dispose() {
    for (final sub in _subs) {
      sub.cancel();
    }
  }
}
