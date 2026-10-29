import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/ai/data/ai_gate.dart';
import '../features/auth/presentation/auth_providers.dart';
import '../features/folders/data/shared_activity_service.dart';
import '../features/notes/data/data_migrations.dart';
import '../features/notes/data/local_notes_store.dart';
import '../features/notes/data/place_reminders.dart';
import '../features/notes/data/push_service.dart';
import '../features/notes/data/reminder_service.dart';
import '../features/notes/data/share_intake.dart';
import '../features/notes/data/upload_queue.dart';
import '../features/notes/data/video_note_transcripts.dart';
import '../features/notes/data/widget_service.dart';
import '../features/notes/presentation/lock/note_lock_ui.dart';
import '../features/notes/presentation/notes_providers.dart';
import '../features/settings/data/prefs_sync.dart';
import 'router.dart';

/// Oturum açıkken ayakta durması gereken arka plan servisleri (F2.4).
///
/// Eskiden ana ekranın `build`'i bunları `ref.watch` ile tutuyordu: (a)
/// `premiumProvider`'ın her yayını BÜTÜN ana ekranı yeniden kuruyordu; (b)
/// Riverpod 3 görünmeyen ekranın aboneliklerini DURAKLATIR (`TickerMode`) —
/// editör ana ekranı örttüğü sürece yükleme kuyruğu, hatırlatıcılar ve
/// premium akışı da duraklıyordu. Kökte `ref.listen` ile tutulur: yayınlar
/// hiçbir şeyi yeniden kurmaz, uygulama kökü hep görünür. Giriş ekranında
/// (uid yok) hiçbiri başlamaz.
///
/// Ağaç yapısı uid'e göre DEĞİŞMEZ: [child] (gezgin) yeniden kurulmasın diye
/// koşul yalnız dinleyicilerdedir.
class AppServices extends ConsumerWidget {
  const AppServices({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Hesap değişince (çıkış dahil) önceki hesabın bellekteki verisi (F5.5).
    ref.listen<String?>(currentUidProvider, (previous, next) {
      if (previous == next) return;
      clearSearchBodyCache();
      unawaited(LocalNotesStore.releaseExcept(next));
    });
    if (ref.watch(currentUidProvider) != null) {
      ref.listen(uploadQueueProvider, _ignore);
      ref.listen(reminderServiceProvider, _ignore);
      // Silinen/arşivlenen notların konum hatırlatıcılarını kaldırır.
      ref.listen<void>(placeReminderCleanupProvider, _ignore);
      // Paylaşılan klasörlerdeki hareket: rozet + telefon bildirimi.
      ref.listen(sharedActivityServiceProvider, _ignore);
      ref.listen(widgetServiceProvider, _ignore);
      ref.listen<void>(deepLinkHandlerProvider, _ignore);
      // AI kapısı (AiGate.consume) premium durumunu senkron okur.
      ref.listen(premiumProvider, _ignore);
      // Paylaş menüsünden gelen içerikler (Android).
      ref.listen<void>(shareIntakeProvider, _ignore);
      // Bir defalık veri göçleri (F3.5 defter).
      ref.listen<void>(dataMigrationsProvider, _ignore);
      // Kişiye ait tercihler kullanıcı belgesine (F4.5).
      ref.listen<void>(prefsSyncProvider, _ignore);
      // Not kilidi kapısı: yöntem + şifre/desen sorusu (F4.8).
      ref.listen<void>(noteLockBinderProvider, _ignore);
      // Uygulama kapalıyken paylaşım bildirimleri (FCM, F4.6).
      ref.listen<void>(pushServiceProvider, _ignore);
      // Kanallarım/Harita video notlarının transkripti (arka planda).
      ref.listen<void>(videoNoteTranscriptsProvider, _ignore);
    }
    return child;
  }

  static void _ignore(Object? _, Object? _) {}
}
