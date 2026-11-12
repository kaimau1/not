import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../features/settings/settings_providers.dart';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';


import 'l10n_ext.dart';
import 'widgets/undo_snackbar.dart' show rootScaffoldMessengerKey;

/// **İSTEMCİ VERİ SÜRÜMÜ** (F1.5, 2026-10-19). Bu derlemenin güvenle
/// okuyup YAZABİLDİĞİ veri biçiminin numarası. Yeni bir sürüm, eski
/// istemcinin bozacağı bir biçim getirdiğinde (yeni ek türü, alanın anlamı
/// değişti) bu sayı artırılır; sonra Firestore konsolunda `config/app`
/// belgesinin `minClient` alanı aynı sayıya çekilir — eski istemciler
/// "Güncelle" şeridini görür, editör salt okunur açılır.
///
/// NEDEN derleme numarası (`package_info` build number) DEĞİL: web derlemesi
/// `--build-number` almıyor, hep 1. Sabit her platformda aynı anlamı taşır.
///
/// 2 (Faz 3): defter → sayfalı not (F3.5), büyük notların çizim/balon/PDF
/// işaretleri ayrı belgede (F3.13). Eski istemci bölünmüş notun çizimlerini
/// görmez; telefonlar güncellenince `minClient: 2` yazılmalı.
///
/// 3 (2026-10-20): yıldız ve çerçeve yeniden AYRI alanlar. 2'deki istemci
/// `starred`ı sabit sayar ve her yazımda `starred: false` yazar (yıldızları
/// siler), yalnız çerçeveli notu renkli zemin gösterir. Telefonlar bu
/// sürüme geçince `minClient: 3` yazılmalı.
const int kClientDataVersion = 3;

/// İndirme adresi: CI her `[apk]` derlemesini GitHub Releases'a koyar.
const String kReleasesUrl = 'https://github.com/kaimau1/not/releases/latest';

/// `config/app.minClient` — kural: herkes okur, istemci yazamaz.
/// Belge/alan yoksa ya da okunamazsa 0 (kapı kapalı).
final minClientVersionProvider = StreamProvider<int>((ref) {
  return FirebaseFirestore.instance
      .collection('config')
      .doc('app')
      .snapshots()
      .map((d) => (d.data()?['minClient'] as num?)?.toInt() ?? 0)
      .handleError((Object _) {});
});

/// Bu istemci güncellenmeden veri YAZMAMALI mı?
final updateRequiredProvider = Provider<bool>((ref) {
  final min = ref.watch(minClientVersionProvider).value ?? 0;
  return isUpdateRequired(min);
});

@visibleForTesting
bool isUpdateRequired(int minClient, {int current = kClientDataVersion}) =>
    current < minClient;

/// `1.2.33` > `1.2.31`? Hane hane sayısal karşılaştırma.
bool isNewerVersion(String latest, String installed) {
  List<int> parts(String v) =>
      v.split('.').map((p) => int.tryParse(p) ?? 0).toList();
  final a = parts(latest), b = parts(installed);
  for (var i = 0; i < a.length || i < b.length; i++) {
    final x = i < a.length ? a[i] : 0, y = i < b.length ? b[i] : 0;
    if (x != y) return x > y;
  }
  return false;
}

Future<void> openReleasesPage() =>
    launchUrl(Uri.parse(kReleasesUrl), mode: LaunchMode.externalApplication);

/// CI'ın Release'e koyduğu APK'nın adresi ([name] = `1.2.N`).
@visibleForTesting
String releaseApkUrl(String name) =>
    'https://github.com/kaimau1/not/releases/download/v$name/notlar-v$name.apk';

const _system = MethodChannel('dev.kaimau.notlar/system');

/// GitHub'daki en son sürüm (yalnız bizim APK'mız).
class AppUpdateInfo {
  const AppUpdateInfo({
    required this.version,
    required this.url,
    required this.size,
  });

  /// `1.2.N`
  final String version;
  final String url;

  /// Bayt; bilinmiyorsa 0.
  final int size;
}

/// **OTOMATİK GÜNCELLEME** (2026-11-10 yeniden yazım, kullanıcı: *"oto
/// güncelleme doğru çalışmıyor; dosya okuyucu uygulamamızda iyi çalışıyor,
/// onun gibi yapalım; ana ekranda kalıcı gösterge olsun"*).
///
/// ESKİ AKIŞIN KUSURLARI: (1) "yeni sürüm var" bilgisi Firestore
/// `config/app.latestBuild`'tan geliyordu — CI'ın yazma adımı
/// `continue-on-error` ve hizmet hesabına bağlı; yazılamazsa telefon hiç
/// duymuyordu. (2) Duyduğunda sürüm başına BİR KEZ 8 sn'lik bildirim; kaçırılınca
/// iz yoktu. (3) APK belleğe (~60 MB) indiriliyor, `ACTION_VIEW` ile veriliyor,
/// kurulum sonucu hiç dönmüyordu.
///
/// ŞİMDİ (dosya-okuyucu `AppUpdate` düzeni):
/// * Açılışta ve uygulama öne geldikçe (en çok [detectEvery]'de bir) doğrudan
///   GitHub `releases/latest` sorulur; `notlar-v<ANA.ARA.N>.apk` bu
///   kurulumdan yeniyse [available] dolar → ana ekranda KAPATILAMAYAN şerit
///   ([UpdateBanner]).
/// * Oto güncelleme açıksa APK arka planda önbelleğe İNER (dosyaya, boy
///   denetimli, `.part` ile); kurulum hemen DEĞİL — not yazarken süreç
///   kapanmasın diye bir sonraki açılışta ya da şeride dokununca.
/// * Kurulum PackageInstaller oturumuyla (bkz. `ApkGuncelleme.kt`): Android
///   12+'da uygulama kurulumun sahibiyse onaysız; değilse tek dokunuş.
/// * Kurulum izni (REQUEST_INSTALL_PACKAGES) yalnız kişisel derlemede; değilse
///   şerit GitHub sayfasını açar.
abstract final class AppUpdate {
  static const _api = 'https://api.github.com/repos/kaimau1/not/releases/latest';
  static const _prefDeclined = 'app_update_declined';

  /// GitHub kotası saatte 60 istek; açılış + öne geliş bunun çok altında.
  static const detectEvery = Duration(minutes: 30);
  static int _lastDetectMs = 0;
  static bool _detecting = false;
  static String? _installed;

  /// GitHub'da bulunan yeni sürüm (henüz inmemiş olabilir).
  static final available = ValueNotifier<AppUpdateInfo?>(null);

  /// İndirilmiş, kurulmayı bekleyen sürüm.
  static final ready = ValueNotifier<AppUpdateInfo?>(null);

  /// İndirme yüzdesi (0–100); indirme yoksa null.
  static final progress = ValueNotifier<int?>(null);

  static bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Bu kurulumun sürüm adı (`1.2.N`). Yerel derleme (`1.2.0`) da denetlenir:
  /// CI sürümü her zaman ondan yenidir.
  static Future<String?> installedVersion() async {
    if (_installed != null) return _installed;
    try {
      _installed = (await PackageInfo.fromPlatform()).version;
    } catch (_) {}
    return _installed;
  }

  /// Release JSON'undan bizim APK'yı seçer (`notlar-v1.2.3.apk`).
  @visibleForTesting
  static AppUpdateInfo? pickAsset(Object? release) {
    if (release is! Map || release['assets'] is! List) return null;
    final re = RegExp(r'^notlar-v(\d+\.\d+\.\d+)\.apk$');
    AppUpdateInfo? best;
    for (final a in release['assets'] as List) {
      if (a is! Map) continue;
      final m = re.firstMatch('${a['name'] ?? ''}');
      final url = a['browser_download_url'];
      if (m == null || url is! String) continue;
      final info = AppUpdateInfo(
        version: m.group(1)!,
        url: url,
        size: (a['size'] as num?)?.toInt() ?? 0,
      );
      if (best == null || isNewerVersion(info.version, best.version)) {
        best = info;
      }
    }
    if (best != null) return best;
    // Yedek: varlık listesi beklenmedikse etiketten adres kurulur.
    final tag = RegExp(
      r'^v?(\d+\.\d+\.\d+)$',
    ).firstMatch('${release['tag_name'] ?? ''}');
    if (tag == null) return null;
    final v = tag.group(1)!;
    return AppUpdateInfo(version: v, url: releaseApkUrl(v), size: 0);
  }

  /// En son Release'i sorar; bu kurulumdan yeni değilse ya da ağ yoksa null.
  static Future<AppUpdateInfo?> check() async {
    final installed = await installedVersion();
    if (installed == null) return null;
    final r = await http
        .get(
          Uri.parse(_api),
          headers: const {
            'Accept': 'application/vnd.github+json',
            'User-Agent': 'notlar-guncelleme',
          },
        )
        .timeout(const Duration(seconds: 15));
    if (r.statusCode != 200) return null;
    final info = pickAsset(jsonDecode(r.body));
    if (info == null || !isNewerVersion(info.version, installed)) return null;
    return info;
  }

  /// Sessiz algılama ([detectEvery] sıklığında, [force] hariç). Hata sessiz.
  static Future<AppUpdateInfo?> detect({bool force = false}) async {
    if (!supported || _detecting) return available.value;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (!force && now - _lastDetectMs < detectEvery.inMilliseconds) {
      return available.value;
    }
    _detecting = true;
    _lastDetectMs = now;
    try {
      final info = await check();
      if (info != null &&
          (available.value == null ||
              isNewerVersion(info.version, available.value!.version))) {
        available.value = info;
      }
    } catch (_) {
      // Ağ yok / GitHub yanıtsız: sonraki öne gelişte yeniden.
    } finally {
      _detecting = false;
    }
    return available.value;
  }

  static Future<Directory> _dir() async {
    final dir = Directory('${(await getTemporaryDirectory()).path}/guncelleme');
    await dir.create(recursive: true);
    return dir;
  }

  static Future<File> _fileFor(String version) async =>
      File('${(await _dir()).path}/notlar-v$version.apk');

  /// APK'yı dosyaya indirir (tam inmiş kopya varsa yeniden indirmez).
  static Future<File?> download(AppUpdateInfo info) async {
    final file = await _fileFor(info.version);
    if (await file.exists() &&
        info.size > 0 &&
        await file.length() == info.size) {
      return file;
    }
    final part = File('${file.path}.part');
    final client = http.Client();
    progress.value = 0;
    try {
      final res = await client
          .send(http.Request('GET', Uri.parse(info.url)))
          .timeout(const Duration(seconds: 30));
      if (res.statusCode != 200) return null;
      final total = info.size > 0 ? info.size : (res.contentLength ?? 0);
      final sink = part.openWrite();
      var got = 0;
      try {
        await for (final chunk in res.stream.timeout(
          const Duration(seconds: 60),
        )) {
          sink.add(chunk);
          got += chunk.length;
          if (total > 0) progress.value = (got * 100 ~/ total).clamp(0, 100);
        }
        await sink.flush();
      } finally {
        await sink.close();
      }
      if (total > 0 && got != total) {
        await part.delete().catchError((_) => part);
        return null;
      }
      if (await file.exists()) await file.delete();
      return await part.rename(file.path);
    } catch (_) {
      return null;
    } finally {
      progress.value = null;
      client.close();
    }
  }

  /// Bu derleme kendini kurabilir mi (kişisel derleme: kurulum izni var)?
  static Future<bool> canSelfInstall() async {
    if (!supported) return false;
    final can = await _system
        .invokeMethod<bool>('canSelfUpdate')
        .catchError((_) => false);
    return can == true;
  }

  /// "Diğer uygulamaların üzerinde göster" izni var mı? Güncellemeden sonra
  /// kendiliğinden açılma (GuncellemeSonrasiAc) Android 10+'da buna bağlı.
  static Future<bool> canDrawOverlays() async {
    if (!supported) return false;
    final can = await _system
        .invokeMethod<bool>('canDrawOverlays')
        .catchError((_) => false);
    return can == true;
  }

  /// Bu uygulamanın "üzerinde göster" izin sayfasını açar.
  static Future<void> openOverlaySettings() async {
    await _system
        .invokeMethod<bool>('openOverlaySettings')
        .catchError((_) => false);
  }

  /// İndirilmiş APK'yı kurar. `done` · `aborted` · `need_permission` ·
  /// `missing` · `unsupported` · `error:…`.
  static Future<String> install(AppUpdateInfo info) async {
    final file = await _fileFor(info.version);
    if (!await file.exists()) return 'missing';
    return await _system
            .invokeMethod<String>('installApkSession', {'path': file.path})
            .catchError((_) => 'error') ??
        'error';
  }

  /// Şeride/düğmeye dokununca: inmediyse indirir, sonra kurar. İndirme
  /// düşerse `download_failed`; kurulum izni yoksa GitHub sayfası açılır.
  static Future<String> downloadAndInstall(AppUpdateInfo info) async {
    if (progress.value != null) return 'busy';
    if (!await canSelfInstall()) {
      await openReleasesPage();
      return 'browser';
    }
    if (ready.value?.version != info.version) {
      final file = await download(info);
      if (file == null) return 'download_failed';
      ready.value = info;
    }
    return install(info);
  }

  /// Önbellekte bu kurulumdan yeni, tam inmiş APK; eskileri siler.
  static Future<AppUpdateInfo?> _pending(String installed) async {
    try {
      AppUpdateInfo? best;
      await for (final e in (await _dir()).list()) {
        final m = RegExp(r'notlar-v(\d+\.\d+\.\d+)\.apk$').firstMatch(e.path);
        if (e is! File || m == null) continue;
        final v = m.group(1)!;
        if (!isNewerVersion(v, installed)) {
          // Kurulmuş ya da eski: yer kaplamasın.
          await e.delete().catchError((_) => e);
          continue;
        }
        if (best == null || isNewerVersion(v, best.version)) {
          best = AppUpdateInfo(version: v, url: '', size: await e.length());
        }
      }
      return best;
    } catch (_) {
      return null;
    }
  }

  /// Açılış işi: bekleyen indirme varsa (ve bu sürüm reddedilmediyse) kurar;
  /// yoksa denetler, yeniyse arka planda indirir ve [onReady] ile söyler.
  static Future<void> runOnStartup({
    required SharedPreferences prefs,
    required bool auto,
    void Function(AppUpdateInfo info)? onReady,
  }) async {
    if (!supported) return;
    final installed = await installedVersion();
    if (installed == null) return;
    final pending = await _pending(installed);
    if (pending != null) {
      ready.value = pending;
      if (available.value == null ||
          isNewerVersion(pending.version, available.value!.version)) {
        available.value = pending;
      }
    }
    final self = await canSelfInstall();
    // Oto kapalıysa ya da kurulum izni yoksa yalnız DUYURU (şerit).
    if (!auto || !self) {
      await detect(force: true);
      return;
    }
    if (pending != null &&
        !isNewerVersion(available.value!.version, pending.version)) {
      if (prefs.getString(_prefDeclined) == pending.version) return;
      final result = await install(pending);
      if (result == 'aborted') {
        await prefs.setString(_prefDeclined, pending.version);
      }
      return;
    }
    final info = await detect(force: true);
    if (info == null) return;
    final file = await download(info);
    if (file == null) return;
    ready.value = info;
    onReady?.call(info);
  }
}

/// Oto güncelleme açık mı (Ayarlar → Hakkında). Varsayılan açık.
final autoUpdateProvider = boolPref('app_update_auto', defaultValue: true);

/// Uygulama kökünde: açılışta [AppUpdate.runOnStartup], öne gelişte
/// [AppUpdate.detect]. Ağaca hiçbir şey eklemez.
class AppUpdateRunner extends ConsumerStatefulWidget {
  const AppUpdateRunner({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<AppUpdateRunner> createState() => _AppUpdateRunnerState();
}

class _AppUpdateRunnerState extends ConsumerState<AppUpdateRunner>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    if (!AppUpdate.supported) return;
    WidgetsBinding.instance.addObserver(this);
    // Açılışın ilk karelerini yormasın: biraz sonra.
    Future<void>.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      unawaited(
        AppUpdate.runOnStartup(
          prefs: ref.read(sharedPreferencesProvider),
          auto: ref.read(autoUpdateProvider),
          onReady: _announceReady,
        ).catchError((Object _) {}),
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(AppUpdate.detect());
  }

  void _announceReady(AppUpdateInfo info) {
    final messenger = rootScaffoldMessengerKey.currentState;
    if (messenger == null || !mounted) return;
    final l10n = context.l10n;
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 8),
        content: Text(l10n.updateReadyToInstall(info.version)),
        action: SnackBarAction(
          label: l10n.updateInstallNow,
          onPressed: () => unawaited(AppUpdate.install(info)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// **ANA EKRANDAKİ KALICI "YENİ SÜRÜM VAR" ŞERİDİ** (2026-11-10). Kapatma
/// düğmesi YOK; sürüm kurulunca uygulama yeniden başlar ve şerit kalkar.
/// Yeni sürüm yokken ağaçta tek `SizedBox.shrink` — ana ekran listesine yük
/// getirmez (yalnız üç `ValueNotifier` dinler, sağlayıcı yok).
class UpdateBanner extends StatefulWidget {
  const UpdateBanner({super.key});

  @override
  State<UpdateBanner> createState() => _UpdateBannerState();
}

class _UpdateBannerState extends State<UpdateBanner> {
  bool _busy = false;

  Future<void> _tap(AppUpdateInfo info) async {
    if (_busy) return;
    setState(() => _busy = true);
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      final result = await AppUpdate.downloadAndInstall(info);
      final text = switch (result) {
        'download_failed' => l10n.updateDownloadFailed,
        'need_permission' => l10n.updateNeedsPermission,
        'aborted' || 'done' || 'busy' || 'browser' => null,
        _ => l10n.updateInstallFailed,
      };
      if (text != null) messenger?.showSnackBar(SnackBar(content: Text(text)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<AppUpdateInfo?>(
    valueListenable: AppUpdate.available,
    builder: (context, info, _) {
      if (info == null) return const SizedBox.shrink();
      return ValueListenableBuilder<AppUpdateInfo?>(
        valueListenable: AppUpdate.ready,
        builder: (context, ready, _) => ValueListenableBuilder<int?>(
          valueListenable: AppUpdate.progress,
          builder: (context, pct, _) =>
              _card(context, info, ready?.version == info.version, pct),
        ),
      );
    },
  );

  Widget _card(
    BuildContext context,
    AppUpdateInfo info,
    bool downloaded,
    int? pct,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final fg = scheme.onPrimaryContainer;
    final l10n = context.l10n;
    final text = pct != null
        ? l10n.updateBannerDownloading(info.version, pct)
        : downloaded
        ? l10n.updateBannerReady(info.version)
        : l10n.updateBanner(info.version);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 2),
      child: Material(
        key: const ValueKey('update-banner'),
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: (_busy || pct != null) ? null : () => _tap(info),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Icon(Icons.system_update, size: 20, color: fg),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        text,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: fg,
                        ),
                      ),
                    ),
                    if (_busy && pct == null)
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: fg,
                        ),
                      )
                    else if (pct == null)
                      Icon(Icons.chevron_right, size: 20, color: fg),
                  ],
                ),
              ),
              if (pct != null)
                LinearProgressIndicator(value: pct / 100, minHeight: 3),
            ],
          ),
        ),
      ),
    );
  }
}

/// Uygulamanın tepesindeki "güncelle" şeridi; kapı kapalıyken ağaca hiçbir
/// şey eklemez.
class UpdateRequiredBanner extends ConsumerWidget {
  const UpdateRequiredBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(updateRequiredProvider)) return child;
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Material(
          color: scheme.errorContainer,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                children: [
                  Icon(Icons.system_update, color: scheme.onErrorContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.updateRequiredBody,
                      style: TextStyle(color: scheme.onErrorContainer),
                    ),
                  ),
                  TextButton(
                    onPressed: openReleasesPage,
                    child: Text(l10n.updateAction),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: child,
          ),
        ),
      ],
    );
  }
}

/// Bu sürümün tanımadığı (daha yeni sürümde eklenmiş) eke dokunulunca:
/// açılmaz, düzenlenmez — yalnız neden açılmadığı söylenir.
Future<void> showUnsupportedAttachmentDialog(BuildContext context) {
  final l10n = context.l10n;
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.system_update),
      title: Text(l10n.attachmentUnsupportedTitle),
      content: Text(l10n.attachmentUnsupportedBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(MaterialLocalizations.of(ctx).okButtonLabel),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(ctx).pop();
            openReleasesPage();
          },
          child: Text(l10n.updateAction),
        ),
      ],
    ),
  );
}
