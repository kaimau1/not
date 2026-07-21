import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n_ext.dart';
import '../features/notes/presentation/dashboard_screen.dart';
import '../features/settings/settings_providers.dart';

/// Ana-detay düzenine geçiş genişliği. 900 px: altında tablet dikey ve telefon
/// kalır (liste + editör yan yana sıkışırdı), üstünde masaüstü tarayıcı ve
/// Windows penceresi gelir.
const double kSplitBreakpoint = 900;

const double _defaultListPaneWidth = 380;
const double _minListPaneWidth = 260;

/// Sağ panele de en az bu kadar yer kalsın; ayraç sona kadar itilip editör
/// görünmez hâle gelmesin.
const double _minDetailWidth = 360;

/// Sol panel genişliği (kullanıcı ayraçla değiştirir, kalıcı saklanır).
final listPaneWidthProvider =
    NotifierProvider<ListPaneWidthNotifier, double>(ListPaneWidthNotifier.new);

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

    return Scaffold(
      body: Row(
        children: [
          // ShellRoute sol paneli rota değişse de aynı konumda tuttuğu için
          // DashboardScreen'in State'i korunur — not değiştirince liste
          // başa sarmaz.
          SizedBox(width: paneWidth, child: const DashboardScreen()),
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
class NoNoteSelected extends StatelessWidget {
  const NoNoteSelected({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sticky_note_2_outlined,
              size: 48,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              context.l10n.noNoteSelected,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
