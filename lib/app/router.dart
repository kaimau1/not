import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/ai/presentation/briefing_screen.dart';
import '../features/ai/presentation/chat_screen.dart';
import '../features/ai/presentation/suggestions_screen.dart';
import '../features/auth/presentation/auth_providers.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/gmail/presentation/mail_summary_screen.dart';
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
import '../features/translate/presentation/translator_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RefreshNotifier(
    ref.watch(authRepositoryProvider).authStateChanges(),
  );
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      // İlk emisyon gelene kadar yönlendirme yapma (login ekranı flaşlamasın).
      if (authState.isLoading && !authState.hasValue) return null;
      final loggedIn = authState.value != null;
      final loggingIn = state.matchedLocation == '/login';
      if (!loggedIn && !loggingIn) return '/login';
      if (loggedIn && loggingIn) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/', builder: (context, state) => const DashboardScreen()),
      GoRoute(
        path: '/note/:id',
        builder: (context, state) => NoteEditorScreen(
          noteId: state.pathParameters['id']!,
          // ?draw=1: el yazısı modu — editör çizim tuvaliyle açılır.
          startDrawing: state.uri.queryParameters['draw'] == '1',
        ),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const PrivacyScreen(),
      ),
      GoRoute(
        path: '/mail',
        builder: (context, state) => const MailSummaryScreen(),
      ),
      GoRoute(
        path: '/suggestions',
        builder: (context, state) => const SuggestionsScreen(),
      ),
      GoRoute(path: '/chat', builder: (context, state) => const ChatScreen()),
      GoRoute(
        path: '/translate',
        builder: (context, state) => const TranslatorScreen(),
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
        final id =
            await repo.createNote(NoteType.fromId(uri.queryParameters['type']));
        router.push('/note/$id');
      });
    }
  }

  appLinks.getInitialLink().then((uri) {
    if (uri != null) handle(uri);
  }).catchError((_) {});
  final sub = appLinks.uriLinkStream.listen(handle, onError: (_) {});
  ref.onDispose(sub.cancel);
});

class _RefreshNotifier extends ChangeNotifier {
  _RefreshNotifier(Stream<dynamic> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
