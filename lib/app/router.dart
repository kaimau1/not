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
import '../features/notes/data/notes_repository.dart';
import '../features/notes/domain/note_type.dart';
import '../features/notes/presentation/archive_screen.dart';
import '../features/notes/presentation/dashboard_screen.dart';
import '../features/notes/presentation/notes_providers.dart';
import '../features/notes/presentation/editor/note_editor_screen.dart';
import '../features/notes/presentation/reminders_screen.dart';
import '../features/notes/presentation/trash_screen.dart';
import '../features/settings/presentation/privacy_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import 'split_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  final refresh = _RefreshNotifier(repo.authStateChanges());
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      // Oturum durumunu, yönlendirmeyi TETİKLEYEN aynı stream üzerinden
      // (repo.currentUser) oku. Eskiden redirect ayrı bir StreamProvider'ı
      // (authStateProvider) okuyordu; o Riverpod tarafından ASENKRON
      // güncellendiğinden, ilk girişte senkron çalışan refresh olayı redirect'i
      // henüz null olan değerle tetikliyordu → yönlendirme olmuyor, kullanıcı
      // uygulamayı yeniden başlatana dek login ekranında kalıyordu.
      // currentUser, authStateChanges emit'inden ÖNCE güncellendiği için
      // burada her zaman tazedir; yarış ortadan kalkar.
      if (!refresh.ready) return null; // İlk emisyon (oturum geri yükleme) beklenir.
      final loggedIn = repo.currentUser != null;
      final loggingIn = state.matchedLocation == '/login';
      if (!loggedIn && !loggingIn) return '/login';
      if (loggedIn && loggingIn) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
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
            path: '/note/:id',
            builder: (context, state) => NoteEditorScreen(
              noteId: state.pathParameters['id']!,
              // ?draw=1: el yazısı modu — editör çizim tuvaliyle açılır.
              startDrawing: state.uri.queryParameters['draw'] == '1',
              // ?voice=1: sesli not modu — kayıt + canlı döküm başlar.
              startVoiceCapture: state.uri.queryParameters['voice'] == '1',
              // ?video=1: görüntülü not — kamera açılır, video cihazda kalır.
              startVideo: state.uri.queryParameters['video'] == '1',
              // ?photo=1: foto çek not al — fotoğraf makinesi açılır.
              startPhoto: state.uri.queryParameters['photo'] == '1',
              // ?scan=1: belge tara not al — belge tarayıcı açılır.
              startScan: state.uri.queryParameters['scan'] == '1',
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const PrivacyScreen(),
      ),
      GoRoute(path: '/ai', builder: (context, state) => const AiHubScreen()),
      GoRoute(path: '/chat', builder: (context, state) => const ChatScreen()),
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
      GoRoute(path: '/trash', builder: (context, state) => const TrashScreen()),
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
    // notlar://new?type=text|checklist|ordered — Hızlı Eylemler widget'ı
    // ana ekrandan doğrudan yeni not editörü açar.
    if (uri.host == 'new') {
      final repo = ref.read(notesRepositoryProvider);
      if (repo == null) return; // Oturum yoksa sessizce geç.
      Future(() async {
        final id = await repo.createNote(
          NoteType.fromId(uri.queryParameters['type']),
        );
        router.push('/note/$id');
      });
    }
  }

  appLinks
      .getInitialLink()
      .then((uri) {
        if (uri != null) handle(uri);
      })
      .catchError((_) {});
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
