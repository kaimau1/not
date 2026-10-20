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

/// Akordeon alan: kapaliyken baslik + DURUM OZETI, acikken icerik.
///
/// Ozet satiri tasarimin asil fikri: kullanici alani acmadan "tema kagit,
/// yazi %100" gibi guncel durumu okuyabiliyor.
class _SettingsArea extends StatelessWidget {
  const _SettingsArea({
    required this.area,
    required this.rows,
    required this.open,
    required this.onTap,
  });

  final _Area area;

  /// Cizilecek satirlar — aramada suzulmus olabilir (bkz. [_Area.visibleRows]).
  final List<Widget> rows;

  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: open ? scheme.surfaceContainerLow : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    // Alan simgesi renkli karede (2026-10-16 görsel
                    // yenileme): başlıklar göz ucuyla ayırt edilsin.
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: (open ? scheme.primary : scheme.onSurfaceVariant)
                            .withValues(alpha: open ? 0.16 : 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        area.icon,
                        size: 19,
                        color: open ? scheme.primary : scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            area.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (area.summary.isNotEmpty)
                            Text(
                              area.summary,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: open ? 0.5 : 0,
                      duration: const Duration(milliseconds: 160),
                      child: Icon(
                        Icons.expand_more,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // AÇILIŞ/KAPANIŞ YUMUŞAK ve HER ALANDA AYNI (kullanıcı bulgusu
            // 2026-10-20: "bazı menüler aşağı doğru animasyonla açılırken
            // bazılarında yok gibi"): ağır alanın ilk karesi animasyonu
            // yutuyordu — bkz. [ExpandReveal] kök neden notu. Kapalıyken
            // içerik ağaçta YOK (ayar satırlarının hepsini boşuna kurmasın).
            ExpandReveal(
              open: open,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                // DERLİ TOPLU SATIRLAR (kullanıcı isteği 2026-09-26: ekran
                // görüntüsündeki alanlar "görsel ve işlevsel olarak
                // geliştirilsin"). Anahtar satırlarının başlığı gövde
                // metninden BÜYÜK, açıklaması başlık kadar iriydi; uzun
                // açıklamalı beş satır ekranı dolduruyordu. Başlık 14/w600,
                // açıklama küçük ve soluk — göz önce başlığı tarar.
                child: ListTileTheme.merge(
                  dense: true,
                  titleTextStyle: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                  subtitleTextStyle: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: rows,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
      scale: 0.97,
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
                          fontSize: 11.5,
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

// _SettingsGroup (basliksiz kart grubu) kaldirildi: yerini akordeon
// _SettingsArea aldi, dokuz grup alti alana indi.
