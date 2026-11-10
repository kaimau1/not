part of '../settings_screen.dart';

/// Ayarlar alaninin tanimi. Arama hem baslikta hem [keywords] icinde arar:
/// kullanici "mikrofon" yazinca hem Izinler hem Ses alani cikmali.
/// Alanin icindeki TEK bir ayar satiri.
///
/// Eskiden alanlar duz `List<Widget>` tasiyordu ve arama yalnizca ALAN
/// basligina bakiyordu: "hiz" arayan kullaniciya Ses alaninin tamami aciliyor,
/// aradigi satiri yine gozle bulmasi gerekiyordu. Satirin aranabilir bir
/// tanimi olunca suzme satir satir yapilabiliyor.
class _SettingRow {
  const _SettingRow(this.child, {this.title = '', this.keywords = ''});

  final Widget child;

  /// Satirin ekranda gorunen basligi (l10n'dan) — ayni metin arandiginda
  /// eslessin diye burada tekrarlanir.
  final String title;

  /// Baslikta gecmeyen ama kullanicinin arayabilecegi kelimeler.
  final String keywords;

  // Sorgu burada da katlanır (idempotent): çağıran ham metin verse de
  // Türkçe ı/I/aksan farkı yok sayılsın (F1.8).
  bool matches(String query) {
    final q = foldForSearch(query);
    return foldForSearch(title).contains(q) ||
        foldForSearch(keywords).contains(q);
  }
}

class _Area {
  const _Area({
    required this.id,
    required this.icon,
    required this.title,
    required this.summary,
    required this.keywords,
    required this.rows,
  });

  final String id;
  final IconData icon;
  final String title;
  final String summary;
  final String keywords;
  final List<_SettingRow> rows;

  bool matches(String query) {
    final q = foldForSearch(query);
    return foldForSearch(title).contains(q) ||
        foldForSearch(summary).contains(q) ||
        foldForSearch(keywords).contains(q);
  }

  /// Sorguda gorunecek satirlar.
  ///
  /// ALANIN KENDISI eslesiyorsa (kullanici "ses" yazdi) alanin TUM satirlari
  /// gosterilir — bolumun adini arayan kisi bolumun tamamini ister. Alan
  /// eslesmiyorsa yalnizca eslesen satirlar kalir.
  List<Widget> visibleRows(String query) {
    if (query.isEmpty || matches(query)) return [for (final r in rows) r.child];
    return [
      for (final r in rows)
        if (r.matches(query)) r.child,
    ];
  }

  /// Alan listede hic gorunmeli mi: kendisi ya da bir satiri eslesiyorsa.
  bool visible(String query) =>
      query.isEmpty || matches(query) || rows.any((r) => r.matches(query));
}

/// Bu genişlikten itibaren ayarlar iki bölmeli: solda kategoriler, sağda
/// seçili alan (tablet / web).
const double _kSettingsWide = 900;

/// Alanın simge rengi (tema rolünden; sabit renk yok). Kategoriler göz
/// ucuyla ayırt edilsin diye her alan kendi rengini taşır.
({Color bg, Color fg}) _areaColors(ColorScheme s, String id) => switch (id) {
  'account' || 'sync' => (bg: s.primaryContainer, fg: s.onPrimaryContainer),
  'friends' || 'notes' => (bg: s.tertiaryContainer, fg: s.onTertiaryContainer),
  'ai' => (bg: s.primary, fg: s.onPrimary),
  'appearance' ||
  'permissions' => (bg: s.secondaryContainer, fg: s.onSecondaryContainer),
  _ => (bg: s.surfaceContainerHighest, fg: s.onSurfaceVariant),
};

class _AreaIcon extends StatelessWidget {
  const _AreaIcon({required this.area, this.size = 40});
  final _Area area;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = _areaColors(Theme.of(context).colorScheme, area.id);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(area.icon, size: size * 0.52, color: c.fg),
    );
  }
}

/// Kök sayfadaki tek kart içinde ayraçlı kategori satırları.
class _CategoryGroup extends StatelessWidget {
  const _CategoryGroup({
    required this.areas,
    required this.onTap,
    this.selectedId,
  });

  final List<_Area> areas;
  final ValueChanged<String> onTap;

  /// İki bölmeli düzende seçili alan (vurgulu); dar ekranda null.
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < areas.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: 68,
                color: scheme.outlineVariant.withValues(alpha: 0.6),
              ),
            _CategoryTile(
              area: areas[i],
              selected: areas[i].id == selectedId,
              onTap: () => onTap(areas[i].id),
            ),
          ],
        ],
      ),
    );
  }
}

/// Kategori satırı: renkli simge, ad, DURUM ÖZETİ (alanı açmadan "Adaçayı ·
/// Orta · Inter" gibi güncel durum okunur), ok.
class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.area,
    required this.onTap,
    this.selected = false,
    this.compact = false,
  });

  final _Area area;
  final VoidCallback onTap;
  final bool selected;

  /// Arama sonuçlarındaki küçük başlık hâli.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: selected ? scheme.secondaryContainer : Colors.transparent,
      child: InkWell(
        key: ValueKey('settings-cat-${area.id}'),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 4 : 14,
            vertical: compact ? 8 : 12,
          ),
          child: Row(
            children: [
              _AreaIcon(area: area, size: compact ? 30 : 40),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      area.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          (compact
                                  ? theme.textTheme.titleSmall
                                  : theme.textTheme.titleMedium)
                              ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (area.summary.isNotEmpty && !compact)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          area.summary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ayar satırlarını tek kart içinde, derli toplu (başlık 14/w600, açıklama
/// küçük ve soluk) çizer.
class _RowsCard extends StatelessWidget {
  const _RowsCard({required this.rows, this.stagger = false});

  final List<Widget> rows;

  /// İlk açılışta satırları karelere yay (bkz. [_StaggeredRows]).
  final bool stagger;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
        child: ListTileTheme.merge(
          dense: true,
          titleTextStyle: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          subtitleTextStyle: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.3,
          ),
          child: stagger
              ? _StaggeredRows(rows: rows)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: rows,
                ),
        ),
      ),
    );
  }
}

/// Bir alanın kendi sayfası: (iki bölmeli düzende) büyük başlık + özet,
/// altında satırlar tek kartta.
class _AreaPage extends StatelessWidget {
  const _AreaPage({
    super.key,
    required this.area,
    required this.rows,
    required this.showHeader,
  });

  final _Area area;
  final List<Widget> rows;

  /// Dar ekranda başlık zaten üst çubukta; geniş ekranda sayfanın tepesinde.
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      key: PageStorageKey('settings-page-${area.id}'),
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        if (showHeader || area.summary.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 16),
            child: Row(
              children: [
                _AreaIcon(area: area, size: showHeader ? 48 : 36),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showHeader)
                        Text(area.title, style: theme.textTheme.headlineSmall),
                      if (area.summary.isNotEmpty)
                        Text(
                          area.summary,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        _RowsCard(rows: rows, stagger: true),
      ],
    );
  }
}

/// Kök sayfanın dibinde YALNIZ uygulama adı ve sürümü (2026-11-10: güncelleme,
/// sürüm notları ve oto güncelleme dağınıktı → "Güncelleme ve sürüm" alanında
/// toplandı; sürüm bilgisi yine doğrudan görünür, dokununca o alan açılır).
class _VersionLine extends StatefulWidget {
  const _VersionLine({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_VersionLine> createState() => _VersionLineState();
}

class _VersionLineState extends State<_VersionLine> {
  String? _version;

  @override
  void initState() {
    super.initState();
    unawaited(
      PackageInfo.fromPlatform()
          .then((i) {
            if (mounted) setState(() => _version = i.version);
          })
          .catchError((Object _) {}),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Center(
        child: InkWell(
          key: const ValueKey('settings-version-line'),
          borderRadius: BorderRadius.circular(12),
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(
              _version == null
                  ? l10n.appName
                  : '${l10n.appName} · v$_version',
              key: const ValueKey('settings-version-footer'),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Güncelleme ve sürüm" alanının içeriği: sürüm (dokun: denetle), sürüm
/// notları, oto güncelleme, yeniden açılma izni.
class _VersionFooter extends StatefulWidget {
  const _VersionFooter();

  @override
  State<_VersionFooter> createState() => _VersionFooterState();
}

class _VersionFooterState extends State<_VersionFooter>
    with WidgetsBindingObserver {
  String? _version;

  /// Güncellemeden sonra kendiliğinden açılma izni (null = bilinmiyor ya da
  /// bu derleme kendini güncelleyemiyor → satır yok). 2026-11-10.
  bool? _overlay;

  Future<void> _readOverlay() async {
    if (!await AppUpdate.canSelfInstall()) return;
    final v = await AppUpdate.canDrawOverlays();
    if (mounted) setState(() => _overlay = v);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // İzin sayfasından dönünce durum tazelensin.
    if (state == AppLifecycleState.resumed) unawaited(_readOverlay());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_readOverlay());
    unawaited(
      PackageInfo.fromPlatform()
          .then((i) {
            if (mounted) setState(() => _version = i.version);
          })
          .catchError((Object _) {}),
    );
  }

  /// Sürüm satırının altındaki durum bilgisi (null = "dokun: denetle").
  String? _status;
  bool _checking = false;

  /// **SÜRÜME DOKUN → GÜNCELLE** (kullanıcı isteği 2026-11-09): GitHub'ın son
  /// Release'i bu kurulumdan yeniyse doğrudan indirip kurulum penceresini açar
  /// ([installAppUpdate]); değilse "en son sürüm". Web hep son sürümdür.
  Future<void> _check() async {
    final l10n = context.l10n;
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      setState(() => _status = l10n.updateUpToDate);
      return;
    }
    if (_checking) return;
    setState(() {
      _checking = true;
      _status = l10n.updateChecking;
    });
    final info = await AppUpdate.detect(force: true);
    if (!mounted) return;
    setState(() {
      _checking = false;
      _status = info == null
          ? l10n.updateUpToDate
          : l10n.updateAvailable(info.version);
    });
    if (info == null) return;
    // İNDİRME/KURULUM GÖRÜNSÜN (kullanıcı 2026-11-10: "ayarlardan denetleyince
    // iniyor ama kişi anlamıyor"): indirme sürerken yüzde ve çubuk
    // [AppUpdate.progress]'ten çizilir; bittiğinde bu satır "kuruluyor" der.
    setState(() {
      _installing = true;
      _status = l10n.updateInstalling;
    });
    final result = await AppUpdate.downloadAndInstall(info);
    if (!mounted) return;
    setState(() {
      _installing = false;
      _status = switch (result) {
        'download_failed' => l10n.updateDownloadFailed,
        'need_permission' => l10n.updateNeedsPermission,
        'aborted' => l10n.updateAborted,
        'browser' => l10n.updateOpenedBrowser,
        'done' || 'busy' => _status,
        _ => l10n.updateInstallFailed,
      };
    });
  }

  bool _installing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final muted = theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        children: [
          // SÜRÜM NOTLARI (2026-11-10): sürümün hemen üstünde.
          TextButton.icon(
            key: const ValueKey('settings-release-notes'),
            onPressed: () => context.push('/guide?doc=notes'),
            icon: const Icon(Icons.new_releases_outlined, size: 18),
            label: Text(l10n.releaseNotesTitle),
          ),
          _versionTap(context, theme, l10n, muted),
          if (_overlay != null)
            TextButton.icon(
              key: const ValueKey('settings-update-reopen'),
              onPressed: _overlay! ? null : AppUpdate.openOverlaySettings,
              icon: Icon(
                _overlay! ? Icons.check_circle_outline : Icons.open_in_new,
                size: 18,
              ),
              label: Text(
                _overlay! ? l10n.updateReopenOn : l10n.updateReopenOff,
              ),
            ),
          // OTO GÜNCELLEME (2026-11-10): açıkken yeni sürüm arka planda iner,
          // bir sonraki açılışta kurulur. Kapalıyken yalnız ana ekran şeridi.
          if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
            Consumer(
              builder: (context, ref, _) => SwitchListTile(
                key: const ValueKey('settings-auto-update'),
                dense: true,
                secondary: const Icon(Icons.system_update_alt, size: 20),
                title: Text(l10n.autoUpdateTitle),
                subtitle: Text(l10n.autoUpdateInfo),
                value: ref.watch(autoUpdateProvider),
                onChanged: (v) =>
                    ref.read(autoUpdateProvider.notifier).set(v),
              ),
            ),
        ],
      ),
    );
  }

  Widget _versionTap(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    Color muted,
  ) {
    return Center(
        child: InkWell(
          key: const ValueKey('settings-version-footer-tap'),
          borderRadius: BorderRadius.circular(12),
          onTap: _installing ? null : _check,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _version == null
                      ? l10n.appName
                      : '${l10n.appName} · v$_version',
                  key: const ValueKey('settings-version-footer'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium?.copyWith(color: muted),
                ),
                const SizedBox(height: 2),
                // Ana ekran şeridiyle AYNI kaynak: indirme nereden başlarsa
                // başlasın (şerit, oto güncelleme, bu satır) burada görünür.
                ValueListenableBuilder<int?>(
                  valueListenable: AppUpdate.progress,
                  builder: (context, pct, _) {
                    final version = AppUpdate.available.value?.version;
                    final downloading = pct != null && version != null;
                    final status = downloading
                        ? l10n.updateBannerDownloading(version, pct)
                        : _status;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          status ?? l10n.updateTapToCheck,
                          key: const ValueKey('settings-update-status'),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: status == null
                                ? muted
                                : theme.colorScheme.primary,
                          ),
                        ),
                        if (downloading)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: SizedBox(
                              width: 180,
                              child: LinearProgressIndicator(
                                value: pct / 100,
                                minHeight: 3,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
    );
  }
}

/// Alanın satırlarını KARELERE YAYARAK kurar.
///
/// KÖK NEDEN (kullanıcı bulgusu 2026-10-20: "ayarlar ekranı kasıyor menüler
/// arası gezerken"): bir alan açılınca bütün satırları (sağlayıcı okumaları,
/// ses listeleri, model seçicileri, örnek metin) TEK karede kuruluyordu;
/// ağır alanlarda o kare yüzlerce milisaniye sürüyor, açılış animasyonu
/// donup "pat" diye bitiyordu (bkz. [ExpandReveal]). Şimdi ilk karede
/// yalnız ilk iki satır, sonraki her karede bir satır daha eklenir: iş
/// kareler arasına dağılır, animasyon akarken alan aşağı doğru dolar.
/// Arama süzmesi gibi sonraki değişimlerde yayma yok — satırlar hemen gelir.
class _StaggeredRows extends StatefulWidget {
  const _StaggeredRows({required this.rows});

  final List<Widget> rows;

  @override
  State<_StaggeredRows> createState() => _StaggeredRowsState();
}

class _StaggeredRowsState extends State<_StaggeredRows> {
  static const _first = 2;

  late int _count = widget.rows.length <= _first ? widget.rows.length : _first;

  @override
  void initState() {
    super.initState();
    _scheduleNext();
  }

  void _scheduleNext() {
    if (_count >= widget.rows.length) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _count >= widget.rows.length) return;
      setState(() => _count++);
      _scheduleNext();
    });
  }

  @override
  void didUpdateWidget(_StaggeredRows old) {
    super.didUpdateWidget(old);
    // Yayma yalnız İLK açılışta; sonrasında (arama, özet değişimi) satır
    // sayısı neyse o.
    if (_count >= old.rows.length) _count = widget.rows.length;
    if (_count > widget.rows.length) _count = widget.rows.length;
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (var i = 0; i < _count && i < widget.rows.length; i++) widget.rows[i],
    ],
  );
}

/// Alanın İÇİNDEKİ katlanır bölüm ("Gelişmiş", "AI tanılama"): başlık
/// satırı + [ExpandReveal]. Eskiden `ExpansionTile`dı; açılışı alanlarınkinden
/// farklıydı ve ağır içerikte (model seçicileri) o da ilk karede yutuluyordu
/// (bkz. [ExpandReveal]). Artık alanlarla AYNI aşağı kayan açılış.
class _ExpandTile extends StatefulWidget {
  const _ExpandTile({
    required this.title,
    required this.children,
    this.subtitle,
    this.leading,
    this.childrenPadding = EdgeInsets.zero,
    this.onExpansionChanged,
  });

  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final List<Widget> children;
  final EdgeInsetsGeometry childrenPadding;
  final ValueChanged<bool>? onExpansionChanged;

  @override
  State<_ExpandTile> createState() => _ExpandTileState();
}

class _ExpandTileState extends State<_ExpandTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: widget.leading,
          title: widget.title,
          subtitle: widget.subtitle,
          trailing: AnimatedRotation(
            turns: _open ? 0.5 : 0,
            duration: const Duration(milliseconds: 200),
            child: Icon(Icons.expand_more, color: scheme.onSurfaceVariant),
          ),
          onTap: () {
            setState(() => _open = !_open);
            widget.onExpansionChanged?.call(_open);
          },
        ),
        ExpandReveal(
          open: _open,
          child: Padding(
            padding: widget.childrenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.children,
            ),
          ),
        ),
      ],
    );
  }
}

/// Ayarların tepesindeki kısayol kartları: genişte yan yana, dar telefonda
/// (< 520 dp) alt alta ince satırlar.
class _ShortcutTiles extends StatelessWidget {
  const _ShortcutTiles({required this.tiles});

  final List<_ShortcutTile> tiles;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          return Column(
            children: [
              for (var i = 0; i < tiles.length; i++) ...[
                if (i > 0) const SizedBox(height: 6),
                tiles[i],
              ],
            ],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < tiles.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: tiles[i]),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ShortcutTile extends StatelessWidget {
  const _ShortcutTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Basınca hafifçe çöker (bkz. PressScale).
    return PressScale(
      child: Material(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
