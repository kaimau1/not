import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/utils/web_ready.dart';
import '../../settings/settings_providers.dart';
import '../data/auth_repository.dart';
import 'auth_errors.dart';
import 'auth_providers.dart';

/// İLK AÇILIŞTA giriş ekranı GÖSTERİLMEZ (kullanıcı isteği 2026-08-07:
/// "uygulama ilk açılışında ilk giriş itiyor onu kaldıralım").
///
/// Uygulama daha ilk karede sessizce yerel (anonim) oturum açar ve doğrudan
/// notlara girer; Google hesabı isteyen sonradan Ayarlar → Hesap'tan bağlar
/// (uid aynı kaldığı için notlar olduğu yerde kalır, bkz.
/// [AuthRepository.linkWithGoogle]).
///
/// Bayrak prefs'te: sessiz giriş YALNIZ BİR KEZ denenir. Denemesi
/// kaydedilmeseydi, hesabından çıkan kullanıcı giriş ekranına döner dönmez
/// yeniden anonim oturuma sokulur, Google ile giremezdi.
const _autoGuestTriedKey = 'auto_guest_signin_tried';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _busy = false;

  /// Sessiz ilk giriş sürüyor: ekranda düğme yerine yalnız açılış göstergesi
  /// durur. Başarılıysa bu ekran zaten bir sonraki karede kapanır.
  bool _autoSigningIn = false;

  /// Sessiz girişin (ya da elle denemenin) hatası; düğmelerin altında kalıcı
  /// olarak yazar. SnackBar yetmiyordu: sessiz giriş başarısız olduğunda
  /// kullanıcı ekrana yeni gelmiş oluyor ve mesaj o gelmeden kayboluyordu.
  String? _error;

  @override
  void initState() {
    super.initState();
    // İLK karede bilinsin: yoksa ilk kare düğmeleri çizip web açılış
    // katmanını erken kaldırıyordu (F10.6).
    _autoSigningIn = !(ref.read(sharedPreferencesProvider).getBool(
          _autoGuestTriedKey,
        ) ??
        false);
    _maybeAutoGuestSignIn();
  }

  Future<void> _maybeAutoGuestSignIn() async {
    final prefs = ref.read(sharedPreferencesProvider);
    if (prefs.getBool(_autoGuestTriedKey) ?? false) return;
    // Deneme, SONUCUNDAN bağımsız olarak işaretlenir: anonim giriş kapalıysa
    // her açılışta yeniden denemek açılışı gereksiz yere geciktirirdi.
    await prefs.setBool(_autoGuestTriedKey, true);
    if (!mounted) return;
    setState(() => _autoSigningIn = true);
    try {
      await ref.read(authRepositoryProvider).signInAnonymously();
    } catch (e) {
      // Sessiz giriş tutmadı (en sık: Firebase konsolunda "Anonymous"
      // sağlayıcısı kapalı → admin-restricted-operation). Ekran normal giriş
      // ekranı olarak açılır, sebep de altında yazar.
      if (mounted) {
        setState(() => _error = authErrorText(context.l10n, e, guest: true));
      }
    } finally {
      if (mounted) setState(() => _autoSigningIn = false);
    }
  }

  Future<void> _signIn() => _run((auth) => auth.signInWithGoogle());

  /// "Hesapsız devam et": Firebase anonim girişi. Google hesabı istemeden
  /// anında not almaya başlanır; kısıtlar [localAccountInfo]'da yazılı.
  ///
  /// Neden bu var: Play'de ilk açılışta hesap zorunluluğu en büyük kurulum
  /// kaybı sebeplerinden biri. Anonim giriş uid ürettiği için veri katmanı
  /// (tamamı uid'e bağlı) olduğu gibi çalışır, sonradan `linkWithGoogle` ile
  /// aynı uid gerçek hesaba yükseltilir ve notlar taşınmaya gerek kalmadan
  /// yerinde kalır.
  Future<void> _continueLocal() =>
      _run((auth) => auth.signInAnonymously(), guest: true);

  Future<void> _run(
    Future<void> Function(AuthRepository) action, {
    bool guest = false,
  }) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action(ref.read(authRepositoryProvider));
    } catch (e) {
      // Hesap seçiciyi kapatmak hata değildir; sessizce geçilir.
      if (mounted && !isSignInCancel(e)) {
        setState(() => _error = authErrorText(context.l10n, e, guest: guest));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // **WEB SİTESİNİN VİTRİNİ** (kullanıcı isteği 2026-09-22: "web
    // sitemizi … baştan tasarlamalıyız"). hekimasistani.com'a gelen ziyaretçi
    // ilk bu ekranı görüyor; dar sütunlu telefon ekranı geniş tarayıcıda
    // boşlukta yüzen küçük bir kutuydu. Geniş ekranda solda uygulamayı
    // anlatan bir vitrin, sağda giriş kartı. Telefonda eski görünüm aynen.
    // Sessiz giriş sürerken HTML açılışı kalır (tek katman, F10.6); düğmeler
    // çizilince kalkar. Giriş başarılıysa ilk anlamlı ekran notlardır.
    if (!_autoSigningIn) signalWebReady();
    final wide = MediaQuery.sizeOf(context).width >= 840;
    if (!wide) {
      return Scaffold(
        // Kaydırılabilir: hata satırı eklenince (ve küçük/yatay ekranlarda)
        // sütun ekrana sığmıyor, taşma çizgileri çıkıyordu.
        body: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: _form(context, showBrand: true),
              ),
            ),
          ),
        ),
      );
    }
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Row(
        children: [
          Expanded(flex: 11, child: _Showcase(scheme: scheme)),
          Expanded(
            flex: 9,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(40),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Card(
                    elevation: 0,
                    color: scheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(color: scheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                      child: _form(context, showBrand: false),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Giriş düğmeleri + açıklama + hata satırı. Dar ekranda marka başlığıyla
  /// birlikte tek sütun; geniş ekranda marka vitrinde olduğu için yalnız
  /// kart içeriği.
  Widget _form(BuildContext context, {required bool showBrand}) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showBrand) ...[
          Icon(Icons.sticky_note_2_rounded, size: 64, color: scheme.primary),
          const SizedBox(height: 20),
          Text(
            l10n.appName,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.loginTagline,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 40),
        ] else ...[
          Text(
            l10n.appName,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 24),
        ],
        // Sessiz ilk giriş sürerken hiçbir düğme çizilmez: kullanıcı
        // bir an için görüp dokunamadığı bir giriş ekranı görmesin.
        if (_autoSigningIn)
          const Center(child: CircularProgressIndicator())
        else ...[
          FilledButton.icon(
            onPressed: _busy ? null : _signIn,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.login_rounded),
            label: Text(l10n.signInWithGoogle),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _busy ? null : _continueLocal,
            child: Text(l10n.continueWithoutAccount),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.localAccountInfo,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.error),
            ),
          ],
        ],
      ],
    );
  }
}

/// Geniş giriş ekranının sol yarısı: marka, slogan ve dört öne çıkan
/// özellik. Metinler çeviri dosyalarından — 16 dilde aynı vitrin.
class _Showcase extends StatelessWidget {
  const _Showcase({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final features = [
      (
        Icons.devices_outlined,
        l10n.loginFeatureSyncTitle,
        l10n.loginFeatureSyncBody,
      ),
      (
        Icons.auto_awesome_outlined,
        l10n.loginFeatureAiTitle,
        l10n.loginFeatureAiBody,
      ),
      (
        Icons.people_alt_outlined,
        l10n.loginFeatureShareTitle,
        l10n.loginFeatureShareBody,
      ),
      (
        Icons.draw_outlined,
        l10n.loginFeatureInkTitle,
        l10n.loginFeatureInkBody,
      ),
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primaryContainer,
            Color.alphaBlend(
              scheme.tertiaryContainer.withValues(alpha: 0.6),
              scheme.surface,
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.sticky_note_2_rounded,
                      size: 42,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    l10n.appName,
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.loginTagline,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: scheme.onPrimaryContainer.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 40),
                  for (final (icon, title, body) in features)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: scheme.surface.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(icon, color: scheme.primary),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: scheme.onPrimaryContainer,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  body,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: scheme.onPrimaryContainer.withValues(
                                      alpha: 0.75,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
