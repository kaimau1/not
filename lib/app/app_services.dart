import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/presentation/auth_providers.dart';
import '../features/entitlement/data/billing_service.dart';
import '../features/folders/data/shared_activity_service.dart';
import '../features/notes/data/data_migrations.dart';
import '../features/notes/data/lite_sync.dart';
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
import '../features/settings/data/spell_sync.dart';
import 'router.dart';
import '../core/play_build.dart';
import '../core/save_cadence.dart';

/// Oturum açıkken ayakta durması gereken arka plan servisleri (F2.4).
///
/// Kökte `ref.listen` ile tutulur: yayınlar hiçbir şeyi yeniden kurmaz,
/// uygulama kökü hep görünür. Giriş ekranında (uid yok) hiçbiri başlamaz.
///
/// Ağaç yapısı uid'e göre DEĞİŞMEZ: [child] (gezgin) yeniden kurulmasın diye
/// koşul yalnız dinleyicilerdedir.
///
/// **KADEMELİ BAŞLANGIÇ (F25.3, AKICILIK_PLANI K8):** güvenlik ve gezinme
/// kapıları (not kilidi, derin bağlantı, paylaş menüsü) ilk karede kalır;
/// gerisi ilk kareden SONRA, boş bir olay döngüsü dilimi geldikçe (ya da en
/// geç [_kStageFallback]) kare başına BİR servis olarak başlar.
class AppServices extends ConsumerStatefulWidget {
  const AppServices({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppServices> createState() => _AppServicesState();
}

/// Kademeli başlangıcın test kapısı (bkz. [_AppServicesState.debugStaged]).
@visibleForTesting
set debugAppServicesStages(List<void Function(WidgetRef ref)>? value) =>
    _AppServicesState.debugStaged = value;

class _AppServicesState extends ConsumerState<AppServices> {
  /// İlk kareden sonra sırayla başlayan servisler (önemliden önemsize).
  static final List<void Function(WidgetRef ref)> _staged = [
    // Bir defalık veri göçleri (F3.5 defter).
    (ref) => ref.listen<void>(dataMigrationsProvider, _ignore),
    (ref) => ref.listen(uploadQueueProvider, _ignore),
    // Lite eşitleme: çöken oturumdan buluta ulaşmamış editör içeriği varsa
    // açılışta yazılır (günlük boşsa iş yok).
    (ref) => ref.listen<void>(liteJournalRecoveryProvider, _ignore),
    // Kişiye ait tercihler kullanıcı belgesine (F4.5).
    (ref) => ref.listen<void>(prefsSyncProvider, _ignore),
    // Kişisel yazım sözlüğü (Y-6): açılışta tek okuma, alta atılınca yazma.
    (ref) => ref.listen<void>(spellSyncProvider, _ignore),
    // Otomatik kaydın bulut sıklığı + uzaktan fren (config/app).
    (ref) => ref.listen<void>(saveCadenceSyncProvider, _ignore),
    (ref) => ref.listen(reminderServiceProvider, _ignore),
    // Silinen/arşivlenen notların konum hatırlatıcılarını kaldırır.
    (ref) => ref.listen<void>(placeReminderCleanupProvider, _ignore),
    // Paylaşılan klasörlerdeki hareket: rozet + telefon bildirimi.
    (ref) => ref.listen(sharedActivityServiceProvider, _ignore),
    // Uygulama kapalıyken paylaşım bildirimleri (FCM, F4.6).
    (ref) => ref.listen<void>(pushServiceProvider, _ignore),
    (ref) => ref.listen(widgetServiceProvider, _ignore),
    // Kanallarım/Harita video notlarının transkripti (arka planda).
    (ref) => ref.listen<void>(videoNoteTranscriptsProvider, _ignore),
    // PL6: yarıda kalmış satın alma doğrulamasını açılışta sessizce onarır
    // (20 sn gecikmeli). Yalnız Play; kişisel APK'da kademe yok.
    if (PlayBuild.enabled)
      (ref) => ref.listen<void>(billingRecoveryProvider, _ignore),
  ];

  /// Testler kademeleri buradan değiştirir.
  @visibleForTesting
  static List<void Function(WidgetRef ref)>? debugStaged;

  List<void Function(WidgetRef ref)> get _stages => debugStaged ?? _staged;

  /// Boş dilim gelmezse (sürekli animasyon) en geç bu kadar sonra.
  static const _kStageFallback = Duration(milliseconds: 400);

  int _stage = 0;
  bool _waiting = false;
  Timer? _fallback;

  void _advanceLater() {
    if (_waiting || _stage >= _stages.length || !mounted) return;
    _waiting = true;
    void go() {
      if (!_waiting || !mounted) return;
      _waiting = false;
      _fallback?.cancel();
      _fallback = null;
      setState(() => _stage++);
    }

    _fallback = Timer(_kStageFallback, go);
    SchedulerBinding.instance.scheduleTask(go, Priority.idle);
  }

  @override
  void dispose() {
    _waiting = false;
    _fallback?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Hesap değişince (çıkış dahil) önceki hesabın bellekteki verisi (F5.5).
    ref.listen<String?>(currentUidProvider, (previous, next) {
      if (previous == next) return;
      clearSearchBodyCache();
      unawaited(LocalNotesStore.releaseExcept(next));
    });
    if (ref.watch(currentUidProvider) != null) {
      // İLK KAREDE: güvenlik ve gezinme.
      // Not kilidi kapısı: yöntem + şifre/desen sorusu (F4.8).
      ref.listen<void>(noteLockBinderProvider, _ignore);
      ref.listen<void>(deepLinkHandlerProvider, _ignore);
      // Paylaş menüsünden gelen içerikler (Android).
      ref.listen<void>(shareIntakeProvider, _ignore);
      final stages = _stages;
      for (var i = 0; i < _stage && i < stages.length; i++) {
        stages[i](ref);
      }
      if (_stage < stages.length) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _advanceLater());
      }
    }
    return widget.child;
  }

  static void _ignore(Object? _, Object? _) {}
}
