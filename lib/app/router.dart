import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/ai/presentation/ai_hub_screen.dart';
import '../features/ai/presentation/briefing_screen.dart';
import '../features/ai/presentation/chat_screen.dart';
import '../features/auth/presentation/auth_providers.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/folders/presentation/folders_screen.dart';
import '../features/inbox/presentation/inbox_screen.dart';
import '../features/notes/data/notes_repository.dart';
import '../features/notes/domain/note_type.dart';
import '../features/notes/presentation/archive_note_screen.dart';
import '../features/notes/presentation/archive_screen.dart';
import '../features/notes/presentation/dashboard_screen.dart';
import '../features/notes/presentation/notes_providers.dart';
import '../features/notes/presentation/editor/note_editor_screen.dart';
import '../features/notes/presentation/reminders_screen.dart';
import '../features/notes/presentation/trash_screen.dart';
import '../features/settings/presentation/premium_screen.dart';
import '../features/settings/presentation/privacy_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import 'app_frame.dart';
import 'split_shell.dart';

/// Editör rotasının yolu.
///
/// TUZAK — bu yol ELLE kurulmamalı. v1.0.181'de rota metnindeki `$id`
/// kaçırılmış bir ters bölü yüzünden düz metin olarak gitti; uygulama
/// olmayan bir notu beklediği için YENİ NOT AÇAN BÜTÜN MODLAR "yükleniyor"
/// ekranında kaldı ve derleyici/test bunu göremedi (geçerli bir dizeydi).
/// Tek yer, tek test: `test/note_route_test.dart`.
String noteRoutePath(String id, {String query = ''}) => '/note/$id$query';

/// Adres uygulamanın bir SAYFASI değil de dışarıdan gelen bir kaynak mı
/// (content://, file://, notlar://…)? Web'in http(s) adresleri sayfadır.
bool isExternalLocation(Uri uri) =>
    uri.hasScheme && uri.scheme != 'http' && uri.scheme != 'https';

/// ARŞİV DEFTERİ rotası. Ayrı bir yol, çünkü defter not editöründe değil
/// kendi ekranında açılıyor (bkz. [ArchiveNoteScreen] — gerekçe orada).
/// Kart/liste yollarının hangisini kullanacağı `openNoteRoute`'ta notun
/// tipine bakılarak seçilir.
String archiveNoteRoutePath(String id) => '/notebook/$id';

final routerProvider = Provider<GoRouter>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  final refresh = _RefreshNotifier(repo.authStateChanges());
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    // **DIŞ ADRESLER SAYFA DEĞİLDİR** (kullanıcı bulgusu 2026-09-29:
    // "GoException: no routes for location: content://…whatsapp…"). Asıl
    // düzeltme manifestte (flutter_deeplinking_enabled=false); bu, adres
    // yine de yönlendiriciye ulaşırsa diye ikinci kilit: content://, file://
    // ya da notlar:// gibi şemalı bir adres yönlendirmeyi DURDURUR — ekran
    // olduğu yerde kalır (soğuk açılışta başlangıç sayfası), içeriği ilgili
    // eklenti (paylaşım / derin bağlantı) işler.
    onEnter: (context, current, next, router) =>
        isExternalLocation(next.uri) ? const Block.stop() : const Allow(),
    // Bilinmeyen bir sayfa adresi "Page Not Found" yerine ana sayfaya döner.
    onException: (context, state, router) => router.go('/'),
    redirect: (context, state) {
      // Oturum durumunu, yönlendirmeyi TETİKLEYEN aynı stream üzerinden
      // (repo.currentUser) oku. Eskiden redirect ayrı bir StreamProvider'ı
      // (authStateProvider) okuyordu; o Riverpod tarafından ASENKRON
      // güncellendiğinden, ilk girişte senkron çalışan refresh olayı redirect'i
      // henüz null olan değerle tetikliyordu → yönlendirme olmuyor, kullanıcı
      // uygulamayı yeniden başlatana dek login ekranında kalıyordu.
      // currentUser, authStateChanges emit'inden ÖNCE güncellendiği için
      // burada her zaman tazedir; yarış ortadan kalkar.
      // İlk emisyon (oturum geri yükleme) beklenir.
      if (!refresh.ready) return null;
      final loggedIn = repo.currentUser != null;
      final loggingIn = state.matchedLocation == '/login';
      if (!loggedIn && !loggingIn) return '/login';
      if (loggedIn && loggingIn) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      // **GENİŞ EKRAN ÇERÇEVESİ** (bkz. AppFrame): oturum açıkken bütün
      // ekranlar tek dış kabuğun içinde — geniş ekranda gezinme rayı ve her
      // genişlikte klavye kısayolları buradan gelir. Giriş ekranı dışarıda:
      // oturum yokken gidilecek bölüm yok.
      ShellRoute(
        builder: (context, state, child) => AppFrame(child: child),
        routes: [
          // Liste ve not tek kabuk altında: geniş ekranda yan yana (SplitShell),
          // dar ekranda eskisi gibi ayrı ayrı. ShellRoute, rota değişirken sol
          // paneli yeniden kurmadığından listenin kaydırma konumu korunur.
          ShellRoute(
            builder: (context, state, child) => SplitShell(child: child),
            routes: [
              GoRoute(
                path: '/',
                // Geniş ekranda liste zaten SOL panelde; burada onu bir daha
                // çizmek yerine sağ panele yer tutucu koyulur.
                builder: (context, state) =>
                    MediaQuery.sizeOf(context).width < kSplitBreakpoint
                    ? const DashboardScreen()
                    : const NoNoteSelected(),
              ),
              GoRoute(
                path: '/notebook/:id',
                builder: (context, state) => ArchiveNoteScreen(
                  key: ValueKey('notebook-${state.pathParameters['id']}'),
                  noteId: state.pathParameters['id']!,
                ),
              ),
              GoRoute(
                path: '/note/:id',
                // ValueKey(noteId): editör State'i tüm kurulumunu initState'te
                // noteId ile yapıyor; go/pushReplacement aynı GoRoute'un Element'ini
                // geri dönüştürürse key olmadan ekranda ÖNCEKİ notun içeriği kalırdı.
                builder: (context, state) => NoteEditorScreen(
                  key: ValueKey('note-${state.pathParameters['id']}'),
                  noteId: state.pathParameters['id']!,
                  // ?owner=<uid>: PAYLAŞILAN klasördeki not — sahibinin
                  // koleksiyonundan okunur/yazılır (bkz. NoteEditorScreen.ownerId).
                  ownerId: state.uri.queryParameters['owner'],
                  // ?ro=1: yalnız OKUMA yetkisi verilmiş paylaşılan not — alanlar
                  // kilitli açılır (bkz. NoteEditorScreen.readOnly).
                  readOnly: state.uri.queryParameters['ro'] == '1',
                  // ?draw=1: el yazısı modu — editör çizim tuvaliyle açılır.
                  startDrawing: state.uri.queryParameters['draw'] == '1',
                  // ?voice=1: sesli not modu — kayıt + canlı döküm başlar.
                  startVoiceCapture: state.uri.queryParameters['voice'] == '1',
                  // ?dictate=1: SESLE YAZ — mikrofon açılır, konuşulan söz
                  // imlecin olduğu yere anında yazılır (yapay zekâ yok).
                  startDictation: state.uri.queryParameters['dictate'] == '1',
                  // ?video=1: görüntülü not — kamera açılır, video cihazda kalır.
                  startVideo: state.uri.queryParameters['video'] == '1',
                  // ?photo=1: foto çek not al — fotoğraf makinesi açılır.
                  startPhoto: state.uri.queryParameters['photo'] == '1',
                  // ?scan=1: belge tara not al — belge tarayıcı açılır.
                  startScan: state.uri.queryParameters['scan'] == '1',
                  // ?pdf=1: PDF ekle not al — dosya seçici açılır, seçilen belge
                  // notun içine gömülür (iki bölmeli sayfa-notu ekranı).
                  startPdf: state.uri.queryParameters['pdf'] == '1',
                  // ?slides=1: sunum ekle not al — PDF yolunun slayt eşi.
                  startSlides: state.uri.queryParameters['slides'] == '1',
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) =>
                SettingsScreen(initialArea: state.uri.queryParameters['area']),
          ),
          GoRoute(
            path: '/privacy',
            builder: (context, state) => const PrivacyScreen(),
          ),
          GoRoute(
            path: '/premium',
            builder: (context, state) => const PremiumScreen(),
          ),
          GoRoute(
            path: '/ai',
            builder: (context, state) => const AiHubScreen(),
          ),
          GoRoute(
            path: '/chat',
            builder: (context, state) => const ChatScreen(),
          ),
          GoRoute(
            path: '/briefing',
            builder: (context, state) => const BriefingScreen(),
          ),
          GoRoute(
            path: '/reminders',
            builder: (context, state) => const RemindersScreen(),
          ),
          GoRoute(
            path: '/archive',
            builder: (context, state) => const ArchiveScreen(),
          ),
          GoRoute(
            path: '/trash',
            builder: (context, state) => const TrashScreen(),
          ),
          // Geniş ekran rayının iki bölümü (bkz. AppSection); telefonda
          // eskisi gibi ⋮ menüsünden/raftan açılırlar.
          GoRoute(
            path: '/folders',
            builder: (context, state) => const FoldersScreen(),
          ),
          GoRoute(
            path: '/inbox',
            builder: (context, state) => const InboxScreen(),
          ),
        ],
      ),
    ],
  );
});

/// notlar:// derin bağlantılarını dinler (widget'taki mikrofon, uygulama
/// kısayolu, "Hey Google" ile açılış). Dashboard bunu ayakta tutar.
final deepLinkHandlerProvider = Provider<void>((ref) {
  final router = ref.watch(routerProvider);
  final appLinks = AppLinks();

  void handle(Uri uri) {
    if (uri.host == 'voice' || uri.path.contains('voice')) {
      // Ayrı /voice ekranını açmak yerine ana sayfadaki YENİ Sesli Not
      // Asistanı'nı (canlı dökümlü panel) bas-başlat modunda tetikle — tek,
      // tutarlı sistem. Dashboard voiceAutostartProvider'ı dinleyip başlatır.
      router.go('/');
      ref.read(voiceAutostartProvider.notifier).request();
      return;
    }
    // notlar://note/<id> — konum hatırlatıcısı bildirimi notu açar (saat
    // hatırlatıcısının dokunuşuyla aynı yol: kilitli not kilitli kalır).
    if (uri.host == 'note' && uri.pathSegments.isNotEmpty) {
      router.go('/');
      router.push(noteRoutePath(uri.pathSegments.first));
      return;
    }
    // notlar://reminders — "Bugün" widget'ı Hatırlatıcılar ekranını açar.
    if (uri.host == 'reminders') {
      router.go('/');
      router.push('/reminders');
      return;
    }
    // notlar://new?type=text|checklist|ordered — Hızlı Eylemler widget'ı
    // ana ekrandan doğrudan yeni not editörü açar.
    if (uri.host == 'new') {
      final repo = ref.read(notesRepositoryProvider);
      if (repo == null) return; // Oturum yoksa sessizce geç.
      Future(() async {
        final id = await repo.createNote(
          NoteType.fromId(uri.queryParameters['type']),
        );
        router.push(noteRoutePath(id));
      });
    }
  }

  // TUZAK — getInitialLink AYRICA ÇAĞRILMAZ: Android eklentisi başlangıç
  // bağlantısını stream'in ilk dinleyicisine de gönderiyor (onListen →
  // initialLinkSent), getInitialLink ise o bayrağı İŞARETLEMEDEN aynı URI'yi
  // döndürüyor. İkisi birden dinlenince soğuk açılışta handle() iki kez
  // çalışıyor ve widget'ın "Yeni not" kısayolu ÇİFT not açıyordu.
  final sub = appLinks.uriLinkStream.listen(handle, onError: (_) {});
  ref.onDispose(sub.cancel);
});

class _RefreshNotifier extends ChangeNotifier {
  _RefreshNotifier(Stream<dynamic> stream) {
    _sub = stream.listen((_) {
      // İlk emisyon geldiğinde oturum durumu artık bellidir (oturum geri
      // yüklendi ya da oturum yok). Bundan önce redirect bekletilir ki
      // login ekranı flaşlamasın.
      _ready = true;
      notifyListeners();
    });
  }

  bool _ready = false;

  /// authStateChanges en az bir kez emit etti mi? (başlangıç guard'ı)
  bool get ready => _ready;

  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
