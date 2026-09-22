import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/l10n_ext.dart';
import '../features/notes/domain/note_type.dart';
import '../features/notes/presentation/dashboard_screen.dart';
import '../features/settings/settings_providers.dart';
import 'app_commands.dart';

/// Ana-detay düzenine geçiş genişliği — İÇERİK alanının genişliği (geniş
/// ekranda gezinme rayı düşülmüş hâli, bkz. AppFrame).
///
/// 900 → 840 (2026-09-22, geniş ekran tasarımı): Material 3'ün "geniş"
/// pencere sınıfı. Ray eklenince 1024 dp'lik yatay tabletin içerik alanı
/// ~940'a iniyor; 900 sınırı küçük tabletleri tek panele düşürme riskine
/// çok yakındı. 840'ta liste (260–380) + editör (≥ 360) hâlâ sığıyor. Dikey
/// tablet (~800) ve telefon tek panelde kalır.
const double kSplitBreakpoint = 840;

const double _defaultListPaneWidth = 380;
const double _minListPaneWidth = 260;

/// Sağ panele de en az bu kadar yer kalsın; ayraç sona kadar itilip editör
/// görünmez hâle gelmesin.
const double _minDetailWidth = 360;

/// Sol panel genişliği (kullanıcı ayraçla değiştirir, kalıcı saklanır).
final listPaneWidthProvider = NotifierProvider<ListPaneWidthNotifier, double>(
  ListPaneWidthNotifier.new,
);

class ListPaneWidthNotifier extends Notifier<double> {
  static const _key = 'list_pane_width';

  @override
  double build() =>
      ref.watch(sharedPreferencesProvider).getDouble(_key) ??
      _defaultListPaneWidth;

  void set(double value) {
    state = value;
    ref.read(sharedPreferencesProvider).setDouble(_key, value);
  }
}

/// **ODAK MODU** — liste paneli gizli mi (kullanıcı isteği 2026-09-22,
/// geniş ekran tasarımı). Uzun bir notu yazarken ya da PDF'in yanında not
/// alırken listenin kapladığı üçte bir ekran geri kazanılır. Ray'daki
/// düğme ve Ctrl+\ ile açılıp kapanır; tercih kalıcıdır.
final listPaneCollapsedProvider =
    NotifierProvider<ListPaneCollapsedNotifier, bool>(
      ListPaneCollapsedNotifier.new,
    );

class ListPaneCollapsedNotifier extends Notifier<bool> {
  static const _key = 'list_pane_collapsed';

  @override
  bool build() => ref.watch(sharedPreferencesProvider).getBool(_key) ?? false;

  void toggle() {
    state = !state;
    ref.read(sharedPreferencesProvider).setBool(_key, state);
  }
}

/// Geniş ekranda solda not listesi, sağda açık not gösterir.
///
/// **Dar ekranda hiçbir şey değişmez** — [child] tek başına döner, yani telefon
/// davranışı birebir korunur. Bu, düzenin tüm riskini geniş ekrana hapseder.
///
/// URL'ler olduğu gibi kalır (`/` ve `/note/:id`), böylece derin bağlantılar ve
/// tarayıcı geri tuşu bozulmaz.
///
/// Sağ panel HER ZAMAN [child]'ı çizer. Önceki sürüm burada
/// `state.matchedLocation.startsWith('/note/')` ile karar veriyordu ama
/// ShellRoute builder'ına KABUK rotasının eşleşmesi geliyor, alt rotanın tam
/// yolu değil — koşul hiç tutmuyor, not açılsa da sağ panel yer tutucuda
/// kalıyordu. Yer tutucuyu artık `/` rotasının kendisi üretiyor (bkz. router).
class SplitShell extends ConsumerStatefulWidget {
  const SplitShell({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<SplitShell> createState() => _SplitShellState();
}

class _SplitShellState extends ConsumerState<SplitShell> {
  /// Sürükleme sürerken kullanılan geçici genişlik.
  ///
  /// Sürüklemenin her karesinde provider'ı güncelleyip SharedPreferences'a
  /// yazmak diske I/O bindiriyordu; ayraç parmağın/farenin gerisinde
  /// kalıyordu ("çok zor ve yavaş"). Artık sürükleme yerel setState ile akar,
  /// kalıcı kayıt yalnızca BIRAKINCA bir kez yapılır.
  double? _dragWidth;

  @override
  Widget build(BuildContext context) {
    final total = MediaQuery.sizeOf(context).width;
    if (total < kSplitBreakpoint) return widget.child;

    // Pencere daralınca saklanan genişlik sağ panele yer bırakmayabilir.
    final maxPane = (total - _minDetailWidth).clamp(
      _minListPaneWidth,
      double.infinity,
    );
    final stored = ref.watch(listPaneWidthProvider);
    final paneWidth = (_dragWidth ?? stored).clamp(_minListPaneWidth, maxPane);
    final router = GoRouter.of(context);

    return ListenableBuilder(
      listenable: router.routerDelegate,
      builder: (context, _) {
        // Açık not yokken (yalnız yer tutucu) liste gizlenmez: gizli liste +
        // boş sağ panel, kullanıcıya hiçbir şey göstermeyen bir ekran olurdu.
        final collapsed =
            ref.watch(listPaneCollapsedProvider) &&
            currentLocation(router) != '/';
        return _split(context, paneWidth, maxPane, collapsed);
      },
    );
  }

  Widget _split(
    BuildContext context,
    double paneWidth,
    double maxPane,
    bool collapsed,
  ) {
    return Scaffold(
      body: Row(
        children: [
          // ShellRoute sol paneli rota değişse de aynı konumda tuttuğu için
          // DashboardScreen'in State'i korunur — not değiştirince liste
          // başa sarmaz.
          //
          // ODAK MODUNDA liste ağaçtan ÇIKARILMAZ, yalnız genişliği sıfıra
          // akar: ağaçtan çıksaydı kaydırma konumu ve arama kutusu sıfırlanırdı.
          // Liste hep kendi genişliğinde ölçülür (SizedBox), yalnız
          // görünen kısmı daralır — ızgara her karede yeniden dizilmez.
          TweenAnimationBuilder<double>(
            tween: Tween<double>(end: collapsed ? 0 : 1),
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeInOutCubic,
            child: SizedBox(width: paneWidth, child: const DashboardScreen()),
            builder: (context, open, pane) => ClipRect(
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                widthFactor: open,
                // Ağaç şekli sabit (Offstage hep var): State korunur.
                child: Offstage(offstage: open == 0, child: pane),
              ),
            ),
          ),
          if (!collapsed)
            _PaneDivider(
              // Delta DEĞİL mutlak konum: fare bir karede birden çok sürükleme
              // olayı üretebiliyor ve hepsi build'de yakalanmış aynı eski
              // genişliğe eklendiğinden yalnız sonuncusu işe yarıyordu — panel
              // farenin gerisinde kalıyordu. İmlecin x'ini doğrudan kullanmak
              // kare zamanlamasından tamamen bağımsız.
              onDrag: (globalX) => setState(
                () => _dragWidth = (globalX - _dividerWidth / 2).clamp(
                  _minListPaneWidth,
                  maxPane,
                ),
              ),
              onDragEnd: () {
                final width = _dragWidth;
                if (width != null) {
                  ref.read(listPaneWidthProvider.notifier).set(width);
                }
                setState(() => _dragWidth = null);
              },
            ),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}

/// Ayracın tutma genişliği. Çizgi ince görünür ama 16 px'lik alandan
/// yakalanır — 1 px'lik çizgiyi fareyle tutmak zor olurdu.
const double _dividerWidth = 16;

/// Sürüklenebilir ayraç. [onDrag] imlecin MUTLAK x konumunu verir (delta
/// değil); nedeni SplitShell'deki nota bakılabilir.
class _PaneDivider extends StatefulWidget {
  const _PaneDivider({required this.onDrag, required this.onDragEnd});

  final void Function(double globalX) onDrag;
  final VoidCallback onDragEnd;

  @override
  State<_PaneDivider> createState() => _PaneDividerState();
}

class _PaneDividerState extends State<_PaneDivider> {
  bool _hovering = false;
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = _hovering || _dragging;
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        // Fare imleci pikselden piksele atlar; `pan` yerine yatay sürükleme
        // kullanmak dikey kaydırmayı ayraca kaptırmamak için.
        onHorizontalDragStart: (_) => setState(() => _dragging = true),
        onHorizontalDragUpdate: (d) => widget.onDrag(d.globalPosition.dx),
        onHorizontalDragEnd: (_) {
          setState(() => _dragging = false);
          widget.onDragEnd();
        },
        child: SizedBox(
          width: _dividerWidth,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: active ? 4 : 1,
              color: active ? scheme.primary : scheme.outlineVariant,
            ),
          ),
        ),
      ),
    );
  }
}

/// Geniş ekranda `/` rotasının sağ panelde gösterdiği yer tutucu.
///
/// Eskiden yalnız "soldan bir not seç" yazıyordu; ekranın yarısı boş bir
/// davetti. Artık aynı alan bir BAŞLANGIÇ noktası: yeni not / yeni liste
/// düğmeleri ve klavye kısayollarının kısa bir hatırlatması (bkz.
/// [shortcutHelpRows]).
class NoNoteSelected extends ConsumerWidget {
  const NoNoteSelected({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final router = GoRouter.of(context);
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.sticky_note_2_outlined,
                    size: 44,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.noNoteSelected,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.noNoteSelectedHint,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: () => createAndOpenNote(ref, router),
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(l10n.newNoteShort),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => createAndOpenNote(
                        ref,
                        router,
                        type: NoteType.checklist,
                      ),
                      icon: const Icon(Icons.checklist),
                      label: Text(l10n.newChecklistShort),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                // Kısayol hatırlatması: fareli/klavyeli kullanıcı için;
                // dokunmatikte de zararsız, küçük ve soluk.
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 14,
                  runSpacing: 6,
                  children: [
                    for (final row in shortcutHelpRows(context).take(3))
                      Text(
                        '${row.keys}  ${row.label}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
