part of 'note_card.dart';

/// Kartın YAKLAŞIK yüksekliği (dp), [width] genişliğinde çizildiğinde.
///
/// NEDEN TAHMİN: ana ekran ızgarası kartları sütunlara ÇİZMEDEN ÖNCE dağıtır
/// (bkz. `dashboard_screen.dart` → `_balancedColumns`). Gerçek yükseklikler
/// ancak yerleşimden sonra bilinir; onlara göre dağıtmak — masonry ızgaranın
/// yaptığı buydu — kartın hangi sütuna düşeceğini her yerleşimde yeniden
/// hesaplatıyor, kart yükseklikleri kıpırdadıkça (seçim, küçük resim yüklenmesi,
/// not güncellemesi) kartlar sütun değiştiriyor ve kullanıcının gördüğü
/// "kaymalar / sağ sütunda kalan boşluklar" oluşuyordu.
///
/// Tahmin YALNIZ DENGEYİ etkiler: sıra ve yerleşim her zaman deterministiktir
/// (n. kart hangi sütuna atandıysa orada, bir öncekinin hemen altında durur),
/// tahmin şaşarsa yalnız en alttaki sütun boşluğu bir miktar büyür.
double estimateNoteCardHeight(Note note, double width) {
  // Kart gövde yazısı ~12 dp; ortalama karakter genişliği yazı boyunun ~0.52'si
  // (kartta not kendi ölçeğini kullanıyor, bkz. [_NotePreview]).
  final charWidth = 12 * note.fontScale.clamp(0.8, 1.4) * 0.52;
  final textWidth = math.max(40.0, width - 24);
  final perLine = math.max(8, textWidth ~/ charWidth);
  int lines(String text, int maxLines) =>
      math.max(1, math.min(maxLines, (text.trim().length / perLine).ceil()));

  var height = 20.0; // dikey dolgu (10 + 10)
  if (note.title.trim().isNotEmpty) {
    height += lines(note.title, 2) * 21.0 + 6;
  }
  if (note.locked) {
    height += 18;
    return height + 24; // kilit satırı + alt meta bandı
  }

  const itemHeight = 19.0;
  switch (note.type) {
    // Arşiv defteri kartta metin notu gibi ölçülür: kartta gösterdiği şey
    // açıklaması + metin girdileri (ekler zaten ek rozetiyle sayılıyor).
    case NoteType.archive:
    case NoteType.text:
      final hasBody = note.body.trim().isNotEmpty;
      final items = [
        for (final i in note.items)
          if (i.text.trim().isNotEmpty) i,
      ];
      if (hasBody) height += lines(note.body, items.isEmpty ? 4 : 2) * 16.0;
      if (items.isNotEmpty) {
        if (hasBody) height += 6;
        final maxItems = hasBody ? 3 : 5;
        height += math.min(items.length, maxItems) * itemHeight;
        if (items.length > maxItems) height += 16;
      }
    case NoteType.checklist:
    case NoteType.ordered:
      // Ayrı ad: `switch` gövdesi TEK kapsam — `items` yukarıda tanımlı.
      final listItems = [
        for (final i in note.items)
          if (i.text.trim().isNotEmpty) i,
      ];
      height += math.min(listItems.length, 6) * itemHeight;
      if (listItems.length > 6) height += 16;
    case NoteType.pdf:
    case NoteType.slides:
      final pages = note.pageNotes.length;
      height += math.min(pages, 5) * itemHeight;
      if (pages > 5) height += 16;
  }

  // Ek önizlemesi (kapak, belge kartı, karolar, dosya satırları): çizimle
  // AYNI plandan ölçülür (bkz. CardMediaPlan).
  // Not başına gizlenen önizleme (`cardMediaHidden`) yer de kaplamaz.
  if (!note.cardMediaHidden) {
    final media = CardMediaPlan.of(note);
    if (!media.isEmpty) height += media.estimateHeight(width) + 8;
  } else if (!note.locked) {
    final hidden = CardHiddenMedia.of(
      note,
      showVisuals: false,
      showFiles: false,
    );
    // Gizli eklerin özet satırı (F60.S8); tek ekin adı ikinci satırda.
    if (!hidden.isEmpty) height += hidden.name == null ? 22 : 38;
  }

  // Alt meta satırı (rozet · etiket · tarih) neredeyse her kartta var.
  height += 24;
  return height;
}

/// Tarih biçimlendiricileri (desen + DİL) başına BİR kez kurulur.
///
/// KÖK NEDEN (perf): [formatNoteDate] her çağrısında yeni bir [DateFormat]
/// kuruyordu ve bu çağrı KART BAŞINA yapılır. Ana ekranın önbellek payında
/// ~130 kart canlı duruyor (bkz. dashboard `_kGridCacheExtent`), yani her
/// yeniden çizimde yüzden fazla biçimlendirici kuruluyor ve her biri yerel
/// ayarın tarih sembollerini arıyordu.
///
/// Anahtara DİL de giriyor: `static final` bir biçimlendirici ilk açılıştaki
/// dili ömür boyu taşırdı, kullanıcı Ayarlar'dan dili değiştirince kart
/// tarihleri eski dilde kalırdı.
final Map<String, DateFormat> _dateFormatCache = {};

DateFormat _dateFormat(String pattern) => _dateFormatCache.putIfAbsent(
  '$pattern|${Intl.defaultLocale ?? ''}',
  () => DateFormat(pattern),
);

/// Not tarihini kısa gösterir: bugünse saat, aynı yılsa "5 Tem",
/// eski yıllarsa "5 Tem 2025".
String formatNoteDate(DateTime date) {
  final now = DateTime.now();
  if (date.year == now.year && date.month == now.month && date.day == now.day) {
    return _dateFormat('HH:mm').format(date);
  }
  if (date.year == now.year) return _dateFormat('d MMM').format(date);
  return _dateFormat('d MMM y').format(date);
}

/// Kart durum simgesi boyu (komşu simgelerle aynı 13; belirteç basamağı yok).
const double _kExpiryIcon = 13;

/// Karttaki yakın hatırlatıcı (F37.2): önümüzdeki 48 saat içindeyse "yarın
/// 15:17", yoksa null (yalnız simge). Kart yeniden kurulurken hesaplanır
/// ([formatNoteDate] gibi).
// ponytail: saat geçince kart yeniden kurulana dek etiket bayat kalır; dakikalık
// zamanlayıcı kart başına abonelik demek (F21.4 bütçesi).
String? cardReminderLabel(AppLocalizations l10n, DateTime at, DateTime now) {
  if (at.isBefore(now) || at.difference(now) > const Duration(hours: 48)) {
    return null;
  }
  final clock = _dateFormat('HH:mm').format(at);
  // UTC gün farkı: yaz saati geçişinde 23 saatlik gün 0 sayılmasın.
  final days = DateTime.utc(
    at.year,
    at.month,
    at.day,
  ).difference(DateTime.utc(now.year, now.month, now.day)).inDays;
  return switch (days) {
    0 => '${l10n.dateToday.toLowerCase()} $clock',
    1 => '${l10n.dateTomorrow.toLowerCase()} $clock',
    _ => '${_dateFormat('E').format(at)} $clock',
  };
}

/// Testlerin (ve dil kataloğu değişirse çalışma anının) önbelleği
/// boşaltabilmesi için.
@visibleForTesting
void clearNoteDateFormatCache() => _dateFormatCache.clear();

/// Notu açar; kilitliyse önce kimlik doğrulaması ister.
///
/// Hem ızgara kartı hem liste satırı buradan geçer — kilit kontrolünü iki
/// yerde tekrarlamak, birinde unutulduğunda sessiz bir veri sızıntısı olurdu.
///
/// [_openingNoteId]: aynı karta art arda iki dokunuş (özellikle geniş
/// ekranda liste hep görünürken) aynı notun İKİ editörünü üst üste
/// açabiliyordu; açılış sürerken gelen ikinci dokunuş yutulur.
String? _openingNoteId;

/// [ownerId] verilirse not BAŞKASININ koleksiyonundadır (paylaşılan klasör);
/// editör onu sahibinin altından açar (bkz. `NoteEditorScreen.ownerId`).
/// [readOnly] yalnız okuma yetkisi verilmiş paylaşımlarda alanları kilitler.
Future<void> openNoteRoute(
  BuildContext context,
  Note note, {
  String? ownerId,
  bool readOnly = false,
  String find = '',
}) async {
  if (_openingNoteId == note.id) return;
  _openingNoteId = note.id;
  try {
    if (note.locked) {
      final ok = await authenticateForNote(context.l10n.unlockAuthReason);
      if (!ok || !context.mounted) return;
    }
    if (context.mounted) {
      final params = [
        if (ownerId != null) 'owner=$ownerId',
        if (readOnly) 'ro=1',
        // F56.1: aramadan açılan not o kelimeye kaydırılır ve vurgulanır.
        if (find.isNotEmpty) 'find=${Uri.encodeQueryComponent(find)}',
      ];
      // Not KARTIN YERİNDEN genişleyerek açılır (bkz. NoteOpenOrigin).
      NoteOpenOrigin.register(
        context,
        note.id,
        radius: AppTokens.of(context).cardRadius,
        color: NoteColors.noteSurface(context, note),
      );
      // Arşiv/çöp gibi kabuk dışı ekranlardan da doğru yol (bkz.
      // notePushPath — "arşivdeki not siyah ekran" kök nedeni).
      final push = context.pushNote(
        noteRoutePath(
          note.id,
          query: params.isEmpty ? '' : '?${params.join('&')}',
        ),
      );
      // Rota yığına girdikten hemen sonra kilit açılır (push editör
      // KAPANANA dek tamamlanmaz; onu bekleseydik editör açıkken karttan
      // ikinci kez açmak da engellenirdi — o ayrı bir tercih).
      await Future<void>.delayed(const Duration(milliseconds: 400));
      unawaited(push);
    }
  } finally {
    _openingNoteId = null;
  }
}

/// Kart önizlemesinde notun SATIR İÇİ biçimi (renk, vurgu, kalın, italik,
/// altı çizili, boyut) çizilsin mi? Ayarlar → Görünüm'den kapatılabilir.
///
/// Arama sürerken biçim ÇİZİLMEZ: eşleşmenin sarı vurgusu ile notun kendi
/// renk/vurgu biçimi üst üste binince hangisinin arama sonucu olduğu
/// okunmuyordu. Sorgu boşalınca biçimli görünüm geri gelir.
Widget noteBodyText(
  BuildContext context,
  String text,
  ValueListenable<String> query, {
  required bool rich,
  TextStyle? style,
  int? maxLines,
  Color? background,
}) {
  // Renkli yazı kartın zeminine göre okunur hâle getirilir (verilmediyse
  // kartın içindeyiz: zemin [NoteAccent]'ten).
  final ground = background ?? NoteAccent.maybeOf(context)?.background;
  // Arama sürüyor mu: boş ↔ dolu geçişinde kart yeniden kurulur (bkz.
  // `NoteCard.liveQuery`); sorgunun KENDİSİ değişince yalnız vurgu
  // katmanı yeniden boyanır (F21.6).
  if (!rich || query.value.trim().isNotEmpty) {
    // Biçim işaretleri (**kalın**, %%2:renk%%) ham hâlleriyle GÖSTERİLMEZ.
    return highlightedText(
      context,
      stripRichMarkers(text),
      query,
      style: style,
      maxLines: maxLines,
    );
  }
  return Text.rich(
    TextSpan(
      style: style,
      children: richSpans(
        text,
        style,
        // Kart bir editör değil: bağlantılar tıklanamadığı için ayrıca
        // renklendirilmez (linkColor null = ölçüm yolundaki davranış).
        palette: NoteColors.richPalette,
        markerColor: const Color(0x00000000),
        background: ground,
      ),
    ),
    maxLines: maxLines,
    overflow: maxLines != null ? TextOverflow.ellipsis : TextOverflow.clip,
  );
}

/// Aranan kelimeyi vurgulayan metin: metin sorgudan BAĞIMSIZ çizilir,
/// eşleşmeler üstteki katmanda boyanır ([SearchHighlight], F21.6) — sorgu
/// değişince metin yeniden şekillendirilmez.
Widget highlightedText(
  BuildContext context,
  String text,
  ValueListenable<String> query, {
  TextStyle? style,
  int? maxLines,
}) {
  final plain = Text(
    text,
    style: style,
    maxLines: maxLines,
    overflow: maxLines != null ? TextOverflow.ellipsis : null,
  );
  if (identical(query, FixedQuery.empty)) return plain;
  final scheme = _cardThemeOf(context).colorScheme;
  return SearchHighlight(
    query: query,
    fill: scheme.primaryContainer.withValues(alpha: 0.7),
    underline: scheme.primary,
    child: plain,
  );
}

/// Kartın izlediği HER ŞEY tek sağlayıcıda (F21.4).
///
/// KÖK NEDEN (telefonda ölçüldü 2026-11-03): her kart sekiz-dokuz ayrı
/// `ref.watch` ile kuruluyordu — kaydırmada `ConsumerStatefulElement.mount`
/// %7; pano örtülünce Riverpod her aboneliği tek tek duraklatıp sürdürüyor
/// (K5). Kart buradan `select` ile YALNIZ kendi değerini çeker: kart başına
/// tek abonelik; kayıt `==` ile karşılaştırıldığından yalnız değeri değişen
/// kart yeniden kurulur (seçim, silinme, paylaşım hâlâ nota özgü).
typedef _CardEnv = ({
  CardDisplay display,
  bool rich,
  bool hideSensitive,
  int filesRevision,
  Set<String> selected,
  Set<String> leaving,
  Map<String, NoteShare>? shares,
  bool allView,
  String? focused,
  String? open,
  DashboardBackground dashBg,
});

final _cardEnvProvider = Provider<_CardEnv>(
  (ref) => (
    display: ref.watch(cardDisplayProvider),
    rich: ref.watch(cardRichPreviewProvider),
    hideSensitive: ref.watch(cardHideSensitiveProvider),
    // Drive'dan bir ek inince kart küçük resmini yerel kopyadan çizsin.
    filesRevision: ref.watch(localFilesRevisionProvider),
    selected: ref.watch(selectedNoteIdsProvider),
    leaving: ref.watch(leavingNotesProvider),
    shares: ref.watch(myNoteSharesProvider).value,
    allView:
        ref.watch(showAllNotesProvider) &&
        ref.watch(selectedFolderProvider) == null,
    // Ana ekran hücresinin halesi (bkz. [NoteCard.frame]).
    focused: ref.watch(focusedNoteProvider),
    open: ref.watch(
      openNoteIdsProvider.select((ids) => ids.isEmpty ? null : ids.last),
    ),
    dashBg: ref.watch(dashboardBackgroundProvider),
  ),
);

/// Kartın üstünde fare var mı (F44.5): ⋮ fareyle yalnız üstüne gelince. Durum
/// burada, kart yeniden kurulmaz; dokunmatikte ⋮ hep görünür, davranış aynı.
class _CardHover extends StatefulWidget {
  const _CardHover({required this.child});

  final Widget child;

  @override
  State<_CardHover> createState() => _CardHoverState();
}

class _CardHoverState extends State<_CardHover> {
  final _hovered = ValueNotifier(false);

  @override
  void dispose() {
    _hovered.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => _hovered.value = true,
    onExit: (_) => _hovered.value = false,
    child: _CardHoverScope(hovered: _hovered, child: widget.child),
  );
}

class _CardHoverScope extends InheritedWidget {
  const _CardHoverScope({required this.hovered, required super.child});

  final ValueNotifier<bool> hovered;

  @override
  bool updateShouldNotify(_CardHoverScope oldWidget) =>
      hovered != oldWidget.hovered;
}

class _RevealOnCardHover extends StatelessWidget {
  const _RevealOnCardHover({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final hovered = context
        .dependOnInheritedWidgetOfExactType<_CardHoverScope>()
        ?.hovered;
    if (hovered == null) return child;
    return ListenableBuilder(
      // Fare bağlanınca bir kez (dokunmatik cihazda hiç) tetiklenir.
      listenable: Listenable.merge([
        hovered,
        RendererBinding.instance.mouseTracker,
      ]),
      // Yer ve ekran okuyucu düğümü kalır, yalnız çizilmez.
      builder: (context, shown) => Visibility.maintain(
        visible:
            hovered.value ||
            !RendererBinding.instance.mouseTracker.mouseIsConnected,
        child: shown!,
      ),
      child: child,
    );
  }
}

/// Arama sonucundaki kartta notun klasörü (bkz. NoteCard.build).
class _FolderBadge extends StatelessWidget {
  const _FolderBadge({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final scheme = _cardThemeOf(context).colorScheme;
    // Renkli kartta kartın koyu tonu (TEMA_PLANI F31.3).
    final accent = NoteAccent.maybeOf(context)?.accent;
    final ink = accent ?? scheme.onSecondaryContainer;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:
            accent?.withValues(alpha: AppAlpha.pressed) ??
            scheme.secondaryContainer.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(AppRadius.s),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_outlined, size: 13, color: ink),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: AppWeight.strong,
                color: ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Parola notunun kartında içerik yerine duran satır (B1). [onLock] null
/// değilse yanında "Kilitle" önerisi.
class _SensitiveHidden extends StatelessWidget {
  const _SensitiveHidden({this.onLock});

  final VoidCallback? onLock;

  @override
  Widget build(BuildContext context) {
    final scheme = _cardThemeOf(context).colorScheme;
    final l10n = context.l10n;
    return Row(
      children: [
        Icon(Icons.shield_outlined, size: 14, color: scheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            l10n.sensitiveHiddenOnCard,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: _cardThemeOf(context).textTheme.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        if (onLock != null)
          TextButton.icon(
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: AppWeight.strong,
              ),
            ),
            onPressed: onLock,
            icon: const Icon(Icons.lock_outline, size: 14),
            label: Text(l10n.lockNote),
          ),
      ],
    );
  }
}

/// Kartın madde satırı — metin notunun maddeleri, yapılacaklar ve sıralı
/// liste TEK yoldan çizilir (C3; eskiden üç kopyaydı ve biri biçim
/// işaretlerini sökmeyi unutmuştu). Satırın solunda kutucuk ([checkbox])
/// ya da sıra numarası ([number]); işaretli kutucuklu madde üstü çizili ve
/// soluk. Maddenin altında ayırıcı varsa ([NoteItem.divider]) o da burada.
class _CardItemRow extends StatelessWidget {
  const _CardItemRow({
    required this.item,
    required this.text,
    required this.style,
    required this.query,
    required this.rich,
    this.checkbox = false,
    this.number,
    this.numbered = false,
  });

  final NoteItem item;

  /// Maddenin kartta çizilen metni: dilimlenmiş, gerekirse örtülmüş
  /// (bkz. [CardPreview.item]).
  final String text;
  final TextStyle style;
  final ValueListenable<String> query;
  final bool rich;
  final bool checkbox;
  final int? number;

  /// Numaralı liste satırı mı (işaretliye numara yerine ✓).
  final bool numbered;

  @override
  Widget build(BuildContext context) {
    final scheme = _cardThemeOf(context).colorScheme;
    // Numaralı listede de işaretli madde üstü çizili, numara yerine ✓
    // (bkz. [itemOrderNumber]).
    final struck = (checkbox || numbered) && item.checked && !item.header;
    Widget? leading;
    if (item.header) {
      // Ara başlık: kutucuk/numara yok, kalın (bkz. [NoteItem.header]).
    } else if (checkbox || (numbered && item.checked)) {
      // Kutucuk EDİTÖRLE AYNI kural (bkz. [NoteCheckColors]): işaretli kutu
      // notun vurgusuyla dolu ve soluk, boş kutu çerçeve — renkli kartta
      // notun koyu tonu, renksizde temanın vurgusu. Numaralı listede
      // işaretli madde numara yerine ✓ (bkz. [itemOrderNumber]).
      final accent = NoteAccent.maybeOf(context)?.accent;
      final icon = Icon(
        _cardCheckGlyph(item.checked, numbered: !checkbox),
        size: 14,
        color: item.checked
            ? NoteCheckColors.checked(scheme, accent)
            : NoteCheckColors.unchecked(scheme, accent),
      );
      // SALT GÖRÜNÜM (kullanıcı bulgusu 2026-11-16: "dashboard'da iken madde
      // tiklenebiliyor, bu olmamalı"; eski D6 karttan işaretleme kalktı):
      // kutucuğa dokunuş kartın dokunuşudur, notu açar. İşaret editörde.
      leading = Padding(
        padding: const EdgeInsetsDirectional.only(end: 6, top: 1),
        child: icon,
      );
    } else if (number != null) {
      leading = Padding(
        padding: const EdgeInsetsDirectional.only(end: 6),
        child: Text('$number.', style: style),
      );
    }
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ?leading,
        Expanded(
          // Ara başlık hizası kartta da (bkz. [NoteItem.align]).
          child: Align(
            alignment: !item.header
                ? AlignmentDirectional.centerStart
                : switch (item.align) {
                    NoteItem.alignCenter => AlignmentDirectional.center,
                    NoteItem.alignEnd => AlignmentDirectional.centerEnd,
                    _ => AlignmentDirectional.centerStart,
                  },
            child: noteBodyText(
              context,
              // Ham biçim işaretleri (**kalın**, %%2:renk%%) HİÇBİR durumda
              // görünmez: ayar kapalıyken sökülür, açıkken görünmez çizilip
              // yerine biçim uygulanır.
              text,
              query,
              // Üstü çizili stil satır içi biçimin üstünde kalmalı: biçimli
              // çizim yalnız işaretsiz maddede.
              rich: rich && !struck,
              maxLines: 1,
              style: item.header
                  ? style.copyWith(fontWeight: FontWeight.w700)
                  : struck
                  ? style.copyWith(
                      decoration: TextDecoration.lineThrough,
                      color: scheme.onSurfaceVariant.withValues(
                        alpha: AppAlpha.muted,
                      ),
                    )
                  : style,
            ),
          ),
        ),
      ],
    );
    if (item.divider.isEmpty) {
      return Padding(padding: const EdgeInsets.only(bottom: 2), child: row);
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: CustomPaint(
        foregroundPainter: _CardDividerPainter(
          item.divider,
          scheme.primary.withValues(alpha: AppAlpha.muted),
        ),
        child: Padding(padding: const EdgeInsets.only(bottom: 3), child: row),
      ),
    );
  }
}

class _CardDividerPainter extends CustomPainter {
  _CardDividerPainter(this.raw, this.color)
    : style = ItemDivider.parse(raw) ?? const ItemDivider('');

  final String raw;
  final ItemDivider style;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) => paintItemDivider(
    canvas,
    style: style,
    fallbackColor: color,
    left: 0,
    right: size.width,
    y: size.height - 0.5,
    baseWidth: 1.2,
  );

  @override
  bool shouldRepaint(_CardDividerPainter old) =>
      old.raw != raw || old.color != color;
}

/// İşaretlilerin kartta tek satır özeti (F74.4, K-D5): "✓ N tamamlandı" ya da
/// hepsi bitmişse "✓ Hepsi tamam (N)". `meta` rolü, notun vurgu tonunda.
class _CardDoneLine extends StatelessWidget {
  const _CardDoneLine({required this.done, required this.allDone});

  final int done;
  final bool allDone;

  @override
  Widget build(BuildContext context) {
    final theme = _cardThemeOf(context);
    final accent = NoteAccent.maybeOf(context)?.accent;
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        allDone ? l10n.cardItemsAllDone(done) : l10n.cardItemsDone(done),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppText.of(theme).meta
            .copyWith(color: accent ?? theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}

/// Uzun yapılacaklar listesinin kartta İLERLEMESİ (2026-10-20 iyileştirme
/// turu): "+40 öğe daha" kaç tanesinin bittiğini söylemiyordu. Yalnız en az
/// 4 maddeli ve en az biri işaretli listede çizilir.
class _ChecklistProgress extends StatelessWidget {
  const _ChecklistProgress({required this.items});

  final List<NoteItem> items;

  @override
  Widget build(BuildContext context) {
    final total = items.where((i) => !i.header).length;
    final done = items.where((i) => i.checked && !i.header).length;
    if (total < 4 || done == 0) return const SizedBox.shrink();
    final scheme = _cardThemeOf(context).colorScheme;
    final accent = NoteAccent.maybeOf(context)?.accent;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.hair),
              child: LinearProgressIndicator(
                value: done / total,
                minHeight: 3,
                backgroundColor: (accent ?? scheme.outlineVariant).withValues(
                  alpha: 0.18,
                ),
                color: (accent ?? scheme.primary).withValues(
                  alpha: AppAlpha.strong,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$done/$total',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: AppWeight.strong,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// _MiniBadge (etiket/alarm için küçük hap rozeti) kaldırıldı: kart meta
// satırı artık düz simge + metin, ayrı bir zemin kutusu taşımıyor.

/// Metin notunun kart gövdesi; aramada eşleşme görünen başta değilse
/// eşleşmenin çevresindeki kesit (F21.3). Kesit sorgunun KENDİSİNE bağlı
/// olduğu için yalnız bu parça sorguyu dinler ve yalnız kesit DEĞİŞİNCE
/// yeniden kurulur (F21.6) — harf eklemek çoğu kartta hiçbir şey kurmaz.
class _SearchExcerptBody extends StatefulWidget {
  const _SearchExcerptBody({
    required this.preview,
    required this.query,
    required this.rich,
    required this.maxLines,
    required this.style,
  });

  final CardPreview preview;
  final ValueListenable<String> query;
  final bool rich;
  final int maxLines;
  final TextStyle style;

  @override
  State<_SearchExcerptBody> createState() => _SearchExcerptBodyState();
}

class _SearchExcerptBodyState extends State<_SearchExcerptBody> {
  String? _excerpt;

  String? _compute() {
    final q = widget.query.value.trim();
    return q.isEmpty ? null : widget.preview.excerpt(q, widget.maxLines);
  }

  void _onQuery() {
    final next = _compute();
    if (next != _excerpt) setState(() => _excerpt = next);
  }

  @override
  void initState() {
    super.initState();
    _excerpt = _compute();
    widget.query.addListener(_onQuery);
  }

  @override
  void didUpdateWidget(_SearchExcerptBody old) {
    super.didUpdateWidget(old);
    if (!identical(old.query, widget.query)) {
      old.query.removeListener(_onQuery);
      widget.query.addListener(_onQuery);
    }
    _excerpt = _compute();
  }

  @override
  void dispose() {
    widget.query.removeListener(_onQuery);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final excerpt = _excerpt;
    if (excerpt != null) {
      return highlightedText(
        context,
        excerpt,
        widget.query,
        style: widget.style,
        maxLines: widget.maxLines,
      );
    }
    return noteBodyText(
      context,
      widget.preview.body,
      widget.query,
      rich: widget.rich,
      maxLines: widget.maxLines,
      style: widget.style,
    );
  }
}

/// Liste görünümündeki not satırı.
///
/// Izgaradaki [NoteCard]'ın "tek sütuna sıkıştırılmış" hâli DEĞİL: kart
/// yüksekliği içeriğe göre değişir, satır sabittir. Tarama için tasarlandı —
/// çok notu olan kullanıcı kartlarda ikinci ekrana taşan bir listeyi
/// kaydırmak yerine tek bakışta on beş başlık görsün.
class NoteListRow extends ConsumerWidget {
  const NoteListRow({
    super.key,
    required this.note,
    required this.selected,
    required this.selectionActive,
  });

  final Note note;
  final bool selected;
  final bool selectionActive;

  /// Satırın türünü anlatan simge. Kilitli not içeriğini göstermediği için
  /// kilit simgesi tür simgesinin önüne geçer.
  IconData get _icon {
    if (note.locked) return Icons.lock_outline;
    return switch (note.type) {
      NoteType.checklist => Icons.checklist,
      NoteType.ordered => Icons.format_list_numbered,
      NoteType.pdf => Icons.picture_as_pdf_outlined,
      NoteType.slides => Icons.slideshow_outlined,
      NoteType.archive => Icons.book_outlined,
      NoteType.text => Icons.notes,
    };
  }

  /// Satırın solu: notun görseli/videosu varsa küçük resmi (video oynat
  /// işaretiyle), yoksa tür simgesi. Kilitli notta hep simge.
  Widget _rowLeading(
    ColorScheme scheme,
    Color? accent, {
    required bool showMedia,
  }) {
    final media = note.locked || note.cardMediaHidden || !showMedia
        ? null
        : CardMediaPlan.of(note, showFiles: false);
    final visual = media?.hero ?? media?.strip.firstOrNull;
    if (visual == null) {
      return Icon(
        _icon,
        size: AppIconSize.m,
        color: accent ?? scheme.onSurfaceVariant,
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: 40,
        height: 40,
        child: CardMediaTile(attachment: visual),
      ),
    );
  }

  /// Tek satırlık önizleme. Kilitli notta içerik SIZDIRILMAZ.
  String _preview(BuildContext context, {required bool hideSensitive}) {
    if (note.locked) return context.l10n.lockedNote;
    if (hideSensitive &&
        CardPreview.of(note, hideSensitive: hideSensitive).credential) {
      return context.l10n.sensitiveHiddenOnCard;
    }
    // Biçim işaretleri BURADA da sökülür: satır önizlemesi tek satırda 46
    // karakterde kesiliyor, işaretli metin hem ham `**` gösteriyor hem de
    // kesme işaretin ortasına düşebiliyordu (kart önizlemesi bunu çoktan
    // yapıyordu, satır dalı atlanmıştı). Yalnız baştaki dilim işlenir
    // (F21.1, kartla aynı kök neden): 46 karakter için uzun notun tamamı
    // ayrıştırılıyordu. 16 madde boş olsa da ayırıcılarla 46'yı aşar.
    final source = note.body.trim().isNotEmpty
        ? stripRichMarkers(previewSlice(note.body, maxChars: kPreviewItemChars))
        : [
            for (final i in note.items.take(16))
              stripRichMarkers(previewSlice(i.text, maxChars: 60)),
          ].join(' · ');
    var flat = source.replaceAll('\n', ' ').trim();
    if (hideSensitive) flat = maskSensitiveNumbers(flat);
    // 46 karakter: iki satırlık bir cümlenin başı. Daha uzunu zaten
    // ellipsize edilirdi, kısaltmak ölçümü ucuzlatıyor.
    return flat.length > 46 ? '${flat.substring(0, 46)}…' : flat;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shared = ref.watch(
      _cardEnvProvider.select((e) => e.shares?.containsKey(note.id) ?? false),
    );
    // Satır notun küçük kopyası (F37.3): zemin, okunurluk teması ve vurgu kartla
    // aynı kaynaktan. Seçiliyken zemin seçim rengi, içerik temanın.
    final outer = Theme.of(context);
    final background = selected
        ? outer.colorScheme.secondaryContainer
        : NoteColors.noteSurface(context, note);
    final inkTheme = NoteColors.inkThemeFor(outer, background);
    _cardInk[context] = inkTheme;
    final theme = _cardThemeOf(context);
    final scheme = theme.colorScheme;
    final accent = selected ? null : NoteColors.noteInk(context, note);
    final preview = _preview(
      context,
      hideSensitive: ref.watch(cardHideSensitiveProvider),
    );
    final display = ref.watch(cardDisplayProvider);
    final reminderLabel = display.statusIcons && note.reminderAt != null
        ? cardReminderLabel(context.l10n, note.reminderAt!, DateTime.now())
        : null;
    final row = Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _rowLeading(scheme, accent, showMedia: display.media),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  note.displayTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: noteTitleStyle(
                    theme,
                    note,
                    fontSize: 15 * note.titleFontScale.clamp(0.8, 1.2),
                  ),
                ),
                if (preview.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (display.date && note.updatedAt != null)
                Text(
                  formatNoteDate(note.updatedAt!),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: AppWeight.strong,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (display.tag && note.tags.isNotEmpty)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 4),
                      child: TagPill(
                        tag: note.tags.first,
                        accent: accent,
                        maxWidth: 72,
                      ),
                    ),
                  if (note.urgent)
                    Icon(
                      Icons.priority_high_rounded,
                      size: _statusIconSize,
                      color: scheme.error,
                    ),
                  if (display.statusIcons) ...[
                    if (note.pinned)
                      Icon(
                        Icons.push_pin,
                        size: 13,
                        color: accent ?? scheme.secondary,
                      ),
                    if (note.starred)
                      Icon(
                        Icons.star,
                        size: 13,
                        color: accent ?? scheme.secondary,
                      ),
                    if (shared)
                      Icon(
                        AppIcons.shared,
                        size: 13,
                        color: accent ?? scheme.primary,
                      ),
                    if (note.reminderAt != null)
                      Icon(
                        note.reminderRepeat.isEmpty
                            ? Icons.alarm
                            : Icons.repeat,
                        size: 13,
                        color: accent ?? scheme.onSurfaceVariant,
                      ),
                    if (note.expiresAt != null)
                      Icon(
                        Icons.hourglass_bottom,
                        size: _kExpiryIcon,
                        color: accent ?? scheme.onSurfaceVariant,
                      ),
                    if (reminderLabel != null)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(start: 3),
                        child: Text(
                          reminderLabel,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: AppWeight.strong,
                            color: accent ?? scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: selectionActive
            ? () => ref.read(selectedNoteIdsProvider.notifier).toggle(note.id)
            : () => openNoteRoute(context, note),
        child: inkTheme == null ? row : Theme(data: inkTheme, child: row),
      ),
    );
  }
}

/// Silinen kartın çıkışı: küçülerek solar (bkz. [leavingNotesProvider]).
/// Çıkarken dokunuş almaz — ikinci bir dokunuş silinmekte olan notu açmasın.
class _Leaving extends StatelessWidget {
  const _Leaving({required this.leaving, required this.child});

  final bool leaving;
  final Widget child;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    ignoring: leaving,
    child: AnimatedScale(
      scale: leaving ? 0.82 : 1,
      duration: LeavingNotesNotifier.exit,
      curve: Curves.easeInCubic,
      child: AnimatedOpacity(
        opacity: leaving ? 0 : 1,
        duration: LeavingNotesNotifier.exit,
        curve: Curves.easeIn,
        child: child,
      ),
    ),
  );
}

/// Kart maddesinin işaret simgesi: kutucuklu listede kutu, numaralı listede
/// (işaretliye numara yerine) ✓.
IconData _cardCheckGlyph(bool checked, {required bool numbered}) => numbered
    ? Icons.check_rounded
    : (checked ? Icons.check_box : Icons.check_box_outline_blank);

/// Kartta takvim hapı: "📅 27 Kas" — notun takvimdeki gününe bağlı olduğunu
/// gösterir (bkz. [NoteCard.calendarDay]).
class CardCalendarPill extends StatelessWidget {
  const CardCalendarPill({super.key, required this.day, this.accent});

  final DateTime day;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final scheme = _cardThemeOf(context).colorScheme;
    final fg = accent ?? scheme.primary;
    return DecoratedBox(
      key: const ValueKey('card-calendar-pill'),
      decoration: ShapeDecoration(
        color: fg.withValues(alpha: AppAlpha.pressed),
        shape: const StadiumBorder(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_outlined, size: _kExpiryIcon, color: fg),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                formatCalendarPillDate(day),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.of(_cardThemeOf(context)).badge
                    .copyWith(color: fg),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Takvim hapının tarihi: bu yıl "27 Kas", başka yıl "27 Kas 2025".
String formatCalendarPillDate(DateTime day) => day.year == DateTime.now().year
    ? _dateFormat('d MMM').format(day)
    : _dateFormat('d MMM y').format(day);
