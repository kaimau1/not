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
  const _SettingRow(
    this.child, {
    this.title = '',
    this.keywords = '',
    this.group,
  });

  final Widget child;

  /// Bu satır yeni bir GRUP kartı başlatır (P62 PA1, plan_tasarim_A §2.2):
  /// null = önceki satırın grubunda kalır; '' = etiketsiz yeni kart; metin =
  /// `SectionLabel`lı yeni kart. Yalnız grubun İLK satırı verir.
  final String? group;

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
        foldForSearch(keywords).contains(q) ||
        foldForSearch(group ?? '').contains(q);
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

/// Alanın simge rengi: hepsi nötr (DENEYIM §2.2 K-D1 — renk yalnız durum
/// ya da tek birincil eylem; eskiden her alan ayrı rol rengi taşıyordu).
({Color bg, Color fg}) _areaColors(ColorScheme s, String id) =>
    (bg: s.surfaceContainerHigh, fg: s.onSurfaceVariant);

class _AreaIcon extends StatelessWidget {
  const _AreaIcon({required this.area, this.size = 40});
  final _Area area;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = _areaColors(Theme.of(context).colorScheme, area.id);
    // F79.2 (D18): nötr kutu, 40 dp, köşe `m` (arama sonucundaki küçük
    // başlıkta 30 dp, köşe `s`).
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(
          size >= 40 ? AppRadius.m : AppRadius.s,
        ),
      ),
      child: Icon(
        area.icon,
        size: size >= 40 ? AppIconSize.m : AppIconSize.xs,
        color: c.fg,
      ),
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
      borderRadius: BorderRadius.circular(AppRadius.l),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < areas.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                // Simge kutusunun sağından başlar (dolgu + kutu + ara).
                indent: AppSpace.m + _kAreaIconBox + AppSpace.m,
                color: scheme.outlineVariant.withValues(alpha: AppAlpha.muted),
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

/// Kategori satırının nötr simge kutusu (dp).
const double _kAreaIconBox = 40;

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
    final text = AppText.of(theme);
    // P62 PA1 (A5): seçim = `primary` rolü (secondary zaman/dikkat). Geçiş
    // YALNIZ renk (boy/dolgu sabit — kasma listesi md. 6, R7). Mürekkep
    // rengin ÜSTÜNDE görünsün diye saydam Material kabın içinde.
    final fg = selected ? scheme.onPrimaryContainer : null;
    return AnimatedContainer(
      duration: AppMotion.of(context, AppMotion.selection),
      curve: AppMotion.standard,
      color: selected ? scheme.primaryContainer : Colors.transparent,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: ValueKey('settings-cat-${area.id}'),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? AppSpace.xs : AppSpace.m,
              vertical: compact ? AppSpace.s : AppSpace.m,
            ),
            child: Row(
              children: [
                _AreaIcon(area: area, size: compact ? 30 : _kAreaIconBox),
                const SizedBox(width: AppSpace.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Satır başlığı `rowTitle`, özet `meta` (F79.2, §2.1).
                      Text(
                        area.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: (compact ? text.label : text.rowTitle).copyWith(
                          color: fg,
                        ),
                      ),
                      if (area.summary.isNotEmpty && !compact)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpace.xxs),
                          child: Text(
                            area.summary,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.meta.copyWith(color: fg),
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: fg ?? scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// [_GroupColumn] çocuğunun türü.
enum _GroupSlot {
  /// Bölüm etiketi (zeminsiz, kartın üstünde).
  label,

  /// Yeni grup kartını başlatan satır.
  start,

  /// Önceki satırın kartında devam eden satır.
  row,
}

/// Ayar satırlarını GRUP KARTLARI hâlinde dizen tek düzen nesnesi (P62 PA1
/// satır dili, plan §2.2): kart zemini (`AppSurface.group` rengi, köşe
/// [AppRadius.l]), kart içi dolgu, satırlar arası 1 dp ayraç, gruplar arası
/// boşluk ve etiketler TEK render nesnesinde çizilir.
///
/// NEDEN SARMALAYICI DEĞİL (R3, S29): satırlar karelere yayılarak kuruluyor
/// (bkz. [_StaggeredRows]); her satırı bir kart / dolgu / ayraç widget'ıyla
/// sarmak, her yayma karesine satır başına fazladan kurulum ekliyordu (S29
/// en ağır kare 37 → 55 ölçüldü). Burada satır başına SIFIR ek widget:
/// kare başına kurulan iş eskisi kadar.
class _GroupColumn extends MultiChildRenderObjectWidget {
  const _GroupColumn({
    required this.slots,
    required this.color,
    required this.line,
    required super.children,
  });

  /// [children] ile aynı uzunlukta.
  final List<_GroupSlot> slots;
  final Color color;
  final Color line;

  @override
  _RenderGroupColumn createRenderObject(BuildContext context) =>
      _RenderGroupColumn(slots, color, line);

  @override
  void updateRenderObject(BuildContext context, _RenderGroupColumn r) => r
    ..slots = slots
    ..color = color
    ..line = line;
}

class _GroupParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderGroupColumn extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _GroupParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _GroupParentData> {
  _RenderGroupColumn(this._slots, this._color, this._line);

  // Ölçüler (plan §2.2): kart içi yatay dolgu `l`, dikey `xs`; gruplar arası
  // `m`; etiketin üstü `xl` (sayfanın başında `xs`), altı `s`.
  static const _padH = AppSpace.l;
  static const _padV = AppSpace.xs;
  static const _gap = AppSpace.m;
  static const _labelTop = AppSpace.xl;
  static const _labelBottom = AppSpace.s;

  List<_GroupSlot> _slots;
  set slots(List<_GroupSlot> v) {
    if (listEquals(v, _slots)) return;
    _slots = v;
    markNeedsLayout();
  }

  Color _color;
  set color(Color v) {
    if (v == _color) return;
    _color = v;
    markNeedsPaint();
  }

  Color _line;
  set line(Color v) {
    if (v == _line) return;
    _line = v;
    markNeedsPaint();
  }

  /// Son düzendeki kart dikdörtgenleri (boyama için).
  final List<Rect> _cards = [];

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _GroupParentData) {
      child.parentData = _GroupParentData();
    }
  }

  _GroupSlot _slotAt(int i) =>
      i < _slots.length ? _slots[i] : _GroupSlot.row;

  @override
  void performLayout() {
    final w = constraints.maxWidth;
    final rowC = BoxConstraints(maxWidth: math.max(0, w - 2 * _padH));
    final labelC = BoxConstraints(maxWidth: w);
    _cards.clear();
    var y = 0.0;
    double? cardTop;
    void closeCard() {
      if (cardTop == null) return;
      y += _padV;
      _cards.add(Rect.fromLTRB(0, cardTop!, w, y));
      cardTop = null;
    }

    var i = 0;
    var afterLabel = false;
    var child = firstChild;
    while (child != null) {
      final pd = child.parentData! as _GroupParentData;
      final slot = _slotAt(i);
      if (slot == _GroupSlot.label) {
        closeCard();
        y += i == 0 ? AppSpace.xs : _labelTop;
        child.layout(labelC, parentUsesSize: true);
        pd.offset = Offset(0, y);
        y += child.size.height + _labelBottom;
        afterLabel = true;
      } else {
        if (slot == _GroupSlot.start || cardTop == null) {
          final hadCard = cardTop != null || _cards.isNotEmpty;
          closeCard();
          if (hadCard && !afterLabel) y += _gap;
          cardTop = y;
          y += _padV;
        }
        afterLabel = false;
        child.layout(rowC, parentUsesSize: true);
        pd.offset = Offset(_padH, y);
        y += child.size.height;
      }
      i++;
      child = pd.nextSibling;
    }
    closeCard();
    size = constraints.constrain(Size(w, y));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    final bg = Paint()..color = _color;
    for (final r in _cards) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          r.shift(offset),
          const Radius.circular(AppRadius.l),
        ),
        bg,
      );
    }
    // Ayraç: kartta önünde satır olan, görünür (boyu > 0) satırın üstünde.
    final ink = Paint()
      ..color = _line
      ..strokeWidth = 1;
    var i = 0;
    var child = firstChild;
    while (child != null) {
      final pd = child.parentData! as _GroupParentData;
      if (_slotAt(i) == _GroupSlot.row && i > 0 && child.size.height > 0) {
        final top = offset + pd.offset;
        canvas.drawLine(top, top + Offset(child.size.width, 0), ink);
      }
      i++;
      child = pd.nextSibling;
    }
    defaultPaint(context, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}

/// Ayar satırlarının kılığı TEK yerden (`ListTileTheme.merge` — 60+ satır
/// widget'ına tek tek dokunmadan, plan §2.3): başlık `rowTitle`, açıklama
/// `meta`, simge nötr, satır en az 56 dp.
Widget _rowsTheme(BuildContext context, Widget child) {
  final theme = Theme.of(context);
  final text = AppText.of(theme);
  return ListTileTheme.merge(
    titleTextStyle: text.rowTitle,
    subtitleTextStyle: text.meta,
    iconColor: theme.colorScheme.onSurfaceVariant,
    minTileHeight: 56,
    horizontalTitleGap: AppSpace.m,
    child: child,
  );
}

/// [_GroupColumn]'un renkleri temadan.
_GroupColumn _groupColumn(
  ThemeData theme,
  List<_GroupSlot> slots,
  List<Widget> children,
) => _GroupColumn(
  slots: slots,
  color: AppSurface.group(theme).color!,
  line: theme.colorScheme.outlineVariant.withValues(alpha: AppAlpha.muted),
  children: children,
);

/// Arama sonuçlarında bir alanın eşleşen satırları: düz TEK kart (grup
/// etiketi gösterilmez, plan §2.3).
class _RowsCard extends StatelessWidget {
  const _RowsCard({required this.rows});

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) => _rowsTheme(
    context,
    _groupColumn(Theme.of(context), [
      for (var i = 0; i < rows.length; i++)
        i == 0 ? _GroupSlot.start : _GroupSlot.row,
    ], rows),
  );
}

/// Bir alanın kendi sayfası: dikey GRUPLAR (P62 PA1, §2.2). Geniş ekranda
/// tepede büyük başlık + özet; dar ekranda başlık üst çubukta, özet kök
/// sayfada görünüyor → başlık satırı yok (A8).
class _AreaPage extends StatelessWidget {
  const _AreaPage({
    super.key,
    required this.area,
    required this.showHeader,
  });

  final _Area area;

  /// Dar ekranda başlık zaten üst çubukta; geniş ekranda sayfanın tepesinde.
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = AppText.of(theme);
    return ListView(
      key: PageStorageKey('settings-page-${area.id}'),
      padding: EdgeInsets.fromLTRB(
        AppSpace.l,
        AppSpace.m,
        AppSpace.l,
        AppSpace.xxl + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        if (showHeader)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.xs,
              AppSpace.xs,
              AppSpace.xs,
              AppSpace.s,
            ),
            child: Row(
              children: [
                _AreaIcon(area: area),
                const SizedBox(width: AppSpace.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(area.title, style: text.screenTitle),
                      if (area.summary.isNotEmpty)
                        Text(
                          area.summary,
                          style: text.body.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        _rowsTheme(context, _StaggeredRows(rows: area.rows)),
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
          borderRadius: BorderRadius.circular(AppRadius.m),
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
          borderRadius: BorderRadius.circular(AppRadius.m),
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

  final List<_SettingRow> rows;

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
    _labels.clear();
    // Yayma yalnız İLK açılışta; sonrasında (arama, özet değişimi) satır
    // sayısı neyse o.
    if (_count >= old.rows.length) _count = widget.rows.length;
    if (_count > widget.rows.length) _count = widget.rows.length;
  }

  /// GRUP DÜZENİ YAYMAYI BOZMAZ (P62 PA1, plan §2.3 / R3): sayılan şey yine
  /// SATIR; kurulan ilk [_count] satır [_GroupColumn]'da gruplara bölünür,
  /// grup kartı içindeki ilk satır kurulunca belirir. Satırlar sarılmaz;
  /// etiketler bir kez kurulup saklanır (her karede yeniden kurulmasın).
  final Map<int, Widget> _labels = {};

  Widget _label(int i, String text) => _labels[i] ??= Padding(
    key: ValueKey('settings-group-label-$i'),
    padding: const EdgeInsets.symmetric(horizontal: AppSpace.s),
    child: SectionLabel(text),
  );

  @override
  Widget build(BuildContext context) {
    final n = math.min(_count, widget.rows.length);
    final slots = <_GroupSlot>[];
    final children = <Widget>[];
    for (var i = 0; i < n; i++) {
      final r = widget.rows[i];
      final label = r.group ?? '';
      if (label.isNotEmpty) {
        slots.add(_GroupSlot.label);
        children.add(_label(i, label));
      }
      slots.add(r.group != null ? _GroupSlot.start : _GroupSlot.row);
      children.add(r.child);
    }
    return _groupColumn(Theme.of(context), slots, children);
  }
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
            duration: AppMotion.of(context, AppMotion.quick),
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

/// Kısayol kartı (Kullanım kılavuzu, Kişiselleştir). F79.2 (D18): iki kart
/// da AYNI nötr tonda — kategori kartlarıyla aynı zemin, aynı 40 dp nötr
/// simge kutusu, başlık `rowTitle`, alt yazı `meta`.
class _ShortcutTile extends StatelessWidget {
  const _ShortcutTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = AppText.of(theme);
    // Basınca hafifçe çöker (bkz. PressScale).
    return PressScale(
      child: Material(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.l),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.m,
              vertical: AppSpace.s,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(AppRadius.m),
                  ),
                  child: Icon(
                    icon,
                    size: AppIconSize.m,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: AppSpace.m),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.rowTitle,
                      ),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.meta,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: AppIconSize.m,
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
