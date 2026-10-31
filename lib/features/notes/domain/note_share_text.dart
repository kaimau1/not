import '../../../core/utils/rich_text.dart';
import 'attachment.dart';
import 'note.dart';
import 'note_item.dart';
import 'note_type.dart';
import 'page_notes.dart';

/// Paylaşılan/kopyalanan metnin seçenekleri (paylaş levhasındaki çipler).
class ShareTextOptions {
  const ShareTextOptions({
    this.title = true,
    this.checked = true,
    this.tags = false,
    this.links = true,
    this.bubbles = true,
  });

  /// Balonların yazısı sonda, sayfa sırasıyla ("Sayfa 3 — Fatura: …").
  /// F13.1 (2026-10-31): balonlu notun paylaşımı/kopyası balonları HİÇ
  /// içermiyordu — PDF'in üstüne yazılan her şey dışarı çıkamıyordu.
  /// Varsayılan AÇIK; çip yalnız yazılı balonu olan notta görünür.
  final bool bubbles;

  /// Nottaki YouTube videolarının bağlantıları sonda ("▶ Başlık" + adres).
  /// Kullanıcı isteği 2026-10-16 ("paylaşım seçenekleri geliştirilmeli"):
  /// videolu not paylaşılınca karşı taraf yalnız "1:23" damgalarını
  /// görüyordu — hangi videonun damgaları olduğu metinde yoktu.
  final bool links;

  /// Başlık ilk satırda.
  final bool title;

  /// Tamamlanmış (işaretli) maddeler dahil.
  final bool checked;

  /// Etiketler sonda `#etiket` satırı olarak.
  final bool tags;

  ShareTextOptions copyWith({
    bool? title,
    bool? checked,
    bool? tags,
    bool? links,
    bool? bubbles,
  }) => ShareTextOptions(
    title: title ?? this.title,
    checked: checked ?? this.checked,
    tags: tags ?? this.tags,
    links: links ?? this.links,
    bubbles: bubbles ?? this.bubbles,
  );

  /// Tercihlerin saklanan biçimi (paylaşım levhası son seçimi hatırlar).
  String encode() =>
      '${title ? 1 : 0}${checked ? 1 : 0}${tags ? 1 : 0}${links ? 1 : 0}'
      '${bubbles ? 1 : 0}';

  static ShareTextOptions decode(String? raw) {
    if (raw == null || raw.length < 4) return const ShareTextOptions();
    bool at(int i) => raw[i] == '1';
    return ShareTextOptions(
      title: at(0),
      checked: at(1),
      tags: at(2),
      links: at(3),
      // Eski kayıtta 5. hane yok → varsayılan (açık).
      bubbles: raw.length < 5 || at(4),
    );
  }
}

/// Nottaki YouTube videoları (bağlantısı olanlar), sırasıyla.
List<Attachment> shareableVideoLinks(Note note) => [
  for (final a in note.attachments)
    if (a.isWebVideo && a.webUrl.trim().isNotEmpty) a,
];

/// Balonun DIŞARI giden yazısı: başlık varsa "Başlık: metin", yoksa metin;
/// biçim işaretleri sökülmüş. Boş balon → boş metin.
String bubbleShareLine(PageBubble b) {
  final title = b.title.trim();
  final text = _tidy(stripRichMarkers(b.text));
  if (title.isEmpty) return text;
  if (text.isEmpty) return title;
  return '$title: $text';
}

/// Yazısı olan balonlar okuma sırasıyla: sayfa, sonra yukarıdan aşağı,
/// soldan sağa (balonun ucunun konumu).
List<PageBubble> orderedTextBubbles(Iterable<PageBubble> bubbles) {
  final list = [
    for (final b in bubbles)
      if (bubbleShareLine(b).isNotEmpty) b,
  ];
  list.sort((a, b) {
    final p = a.page.compareTo(b.page);
    if (p != 0) return p;
    final y = a.y.compareTo(b.y);
    return y != 0 ? y : a.x.compareTo(b.x);
  });
  return list;
}

/// Bir ekin balonlarının metni: her balon "Sayfa N — yazı" satırı. Sayfası
/// tek olan ekte (görsel) sayfa adı yazılmaz. Balon listesindeki "Tümünü
/// kopyala" ve paylaşım metni aynı biçimi kullanır.
String bubblesShareText(
  Iterable<PageBubble> bubbles, {
  required String Function(int page) pageLabel,
  bool withPages = true,
}) => [
  for (final b in orderedTextBubbles(bubbles))
    withPages
        ? '${pageLabel(b.page)} — ${bubbleShareLine(b).replaceAll('\n', '\n   ')}'
        : bubbleShareLine(b),
].join('\n');

/// Notta yazısı olan balon var mı (paylaşım çipi bunu sorar).
bool noteHasTextBubbles(Note note) => note.attachments.any(
  (a) => a.bubbles.any((b) => bubbleShareLine(b).isNotEmpty),
);

/// Onay kutusu işaretleri. WhatsApp, Telegram, e-posta ve not
/// uygulamalarının hepsinde tek karakter olarak çizilen iki simge.
const String kShareUnchecked = '☐';
const String kShareChecked = '☑';

/// Notun PAYLAŞIM / KOPYALAMA metni.
///
/// KÖK NEDEN (kullanıcı isteği 2026-09-26: "not paylaşım seçenekleri ve
/// paylaşım içeriğinin düzeni iyileştirilmeli", "kopyalama vb. şeylerin
/// düzeni"): paylaşım ve kopyalama [Note.toPlainText]'i kullanıyordu. O
/// metin YAPAY ZEKÂ ve dışa aktarma için kurulmuş bir döküm: maddeler
/// Markdown'ın `- [ ]` / `- [x]` işaretleriyle, sayfa notları `#3` gibi
/// çıplak başlıklarla yazılıyordu ve başlık gövdeye yapışıktı. WhatsApp'a
/// giden bir alışveriş listesi "- [ ] Süt" diye okunuyordu.
///
/// Bu metin İNSAN için:
/// * başlık tek başına ilk satırda, altında bir boş satır;
/// * maddeler `☐ Süt` / `☑ Ekmek`, sıralı liste `1. …`; tamamlananlar
///   işaretsizlerin ARDINDA (uygulamadaki düzen) ve istenirse hiç yok;
/// * sayfa notları "Sayfa 3" gibi okunur başlıkla ([pageLabel]);
/// * biçim işaretleri (`**`, `==2:`) sökülür, üçten fazla boş satır ikiye
///   iner, boş maddeler atlanır.
///
/// [toPlainText] DEĞİŞMEDİ: yapay zekâ bağlamı, dışa aktarma ve testleri
/// o biçime dayanıyor.
String noteShareText(
  Note note, {
  ShareTextOptions options = const ShareTextOptions(),
  String Function(int page)? pageLabel,
}) {
  final blocks = <String>[];
  final title = note.displayTitle.trim();
  if (options.title && title.isNotEmpty) blocks.add(title);

  final label = pageLabel ?? (int page) => '#$page';

  // SAYFALI NOT (F10.2, 2026-10-31): yalnız ETKİN sayfa yazılıyordu — iki
  // sayfalı not WhatsApp'a yarım gidiyordu. Etkin sayfanın içeriği
  // `body/items`te, diğerleri [Note.textPages]te (bkz. [Note.toPlainText]).
  // Tek sayfada başlık yok; birden çokta her dolu sayfa "Sayfa N" altında.
  final pages = note.textPages.isEmpty
      ? [(note.body, note.items)]
      : [
          for (final p in note.textPages)
            p.id == note.activePage
                ? (note.body, note.items)
                : (p.body, p.items),
        ];
  for (var i = 0; i < pages.length; i++) {
    final (rawBody, rawItems) = pages[i];
    final parts = <String>[];
    final body = _tidy(stripRichMarkers(rawBody));
    if (body.isNotEmpty) parts.add(body);
    final items = _itemLines(
      note.type,
      rawItems,
      includeChecked: options.checked,
    );
    if (items.isNotEmpty) parts.add(items.join('\n'));
    if (parts.isEmpty) continue;
    if (pages.length == 1) {
      blocks.addAll(parts);
    } else {
      blocks.add('${label(i + 1)}\n${parts.join('\n\n')}');
    }
  }

  if (note.type.isPageNoteType) {
    for (final attachment in note.attachments) {
      for (final entry in orderedPageNotes(
        attachment: attachment,
        pageNotes: note.pageNotes,
      )) {
        final text = _tidy(stripRichMarkers(entry.text));
        if (text.isEmpty) continue;
        blocks.add('${label(entry.page)}\n$text');
      }
    }
  }

  if (options.bubbles) {
    final withBubbles = [
      for (final a in note.attachments)
        if (a.bubbles.any((b) => bubbleShareLine(b).isNotEmpty)) a,
    ];
    for (final a in withBubbles) {
      final multiPage =
          a.kind == AttachmentKind.pdf ||
          a.kind == AttachmentKind.slide ||
          a.bubbles.any((b) => b.page != 1);
      final text = bubblesShareText(
        a.bubbles,
        pageLabel: label,
        withPages: multiPage,
      );
      // Birden çok balonlu ek varsa hangi belgenin balonları olduğu adla.
      final name = a.fileName.trim();
      blocks.add(
        withBubbles.length > 1 && name.isNotEmpty ? '💬 $name\n$text' : text,
      );
    }
  }

  if (options.links) {
    final videos = shareableVideoLinks(note);
    if (videos.isNotEmpty) {
      blocks.add(
        [
          for (final v in videos)
            v.fileName.trim().isEmpty || v.fileName == 'YouTube'
                ? '▶ ${v.webUrl.trim()}'
                : '▶ ${v.fileName.trim()}\n${v.webUrl.trim()}',
        ].join('\n'),
      );
    }
  }

  if (options.tags && note.tags.isNotEmpty) {
    blocks.add(
      [for (final t in note.tags) '#${t.replaceAll(' ', '_')}'].join(' '),
    );
  }
  return blocks.join('\n\n');
}

/// Birden çok notun metni tek parçada (ana ekranda seçili notlar): notlar
/// arasında boş satırlı ince bir ayraç.
String joinShareTexts(Iterable<String> texts) =>
    texts.map((t) => t.trim()).where((t) => t.isNotEmpty).join('\n\n—————\n\n');

List<String> _itemLines(
  NoteType type,
  List<NoteItem> all, {
  required bool includeChecked,
}) {
  String clean(NoteItem item) =>
      _tidy(stripRichMarkers(item.text)).replaceAll('\n', '\n   ');
  final items = [
    for (final i in all)
      if (clean(i).isNotEmpty) i,
  ];
  if (items.isEmpty) return const [];
  switch (type) {
    case NoteType.ordered:
      var n = 0;
      return [for (final i in items) '${++n}. ${clean(i)}'];
    case NoteType.archive:
      return [
        for (final i in items)
          if (i.title.trim().isEmpty)
            clean(i)
          else
            '${stripRichMarkers(i.title).trim()}\n${clean(i)}',
      ];
    case NoteType.text:
    case NoteType.checklist:
    case NoteType.pdf:
    case NoteType.slides:
      return [
        for (final i in items)
          if (!i.checked) '$kShareUnchecked ${clean(i)}',
        if (includeChecked)
          for (final i in items)
            if (i.checked) '$kShareChecked ${clean(i)}',
      ];
  }
}

/// Satır sonu boşluklarını atar, üç ve daha çok ardışık boş satırı bire
/// indirir, baştaki/sondaki boşluğu kırpar.
String _tidy(String text) => text
    .split('\n')
    .map((l) => l.trimRight())
    .join('\n')
    .replaceAll(RegExp(r'\n{3,}'), '\n\n')
    .trim();

/// Seçili maddelerin PANO metni (liste editöründeki seçim çubuğu "Kopyala").
///
/// KÖK NEDEN (kullanıcı 2026-09-26: "kopyalarken `[ ] …` gibi kopyalanıyor,
/// daha iyi olabilir"): seçimle kopyalama Markdown'ın `[ ]` / `[x]`
/// işaretlerini yazıyordu; mesaja yapıştırılan liste köşeli parantezlerle
/// doluyordu. Artık paylaşım metniyle AYNI dil ([noteShareText]):
/// * TEK madde → yalnız metni (işaret yok) — tek bir satırı başka yere
///   yapıştırmak için kopyalayan kutucuk istemez;
/// * birden çok madde → `☐ Süt` / `☑ Ekmek`, sıralı listede `1. …`;
/// * boş maddeler atlanır, biçim işaretleri sökülür.
String itemsCopyText(List<NoteItem> items, {required bool checkboxes}) {
  final clean = [
    for (final i in items)
      if (stripRichMarkers(i.text).trim().isNotEmpty) i,
  ];
  if (clean.isEmpty) return '';
  String text(NoteItem i) => _tidy(stripRichMarkers(i.text));
  if (clean.length == 1) return text(clean.single);
  var n = 0;
  return [
    for (final i in clean)
      checkboxes
          ? '${i.checked ? kShareChecked : kShareUnchecked} ${text(i)}'
          : '${++n}. ${text(i)}',
  ].join('\n');
}

/// Balon listesindeki "Nota aktar" (F13.1): her balonun yazısı KENDİ
/// sayfasının sayfa notunun sonuna, satır satır. Sayfa notunda zaten olan
/// satır yeniden eklenmez (iki kez dokunmak notu çoğaltmasın). Dönen: yalnız
/// DEĞİŞEN sayfaların yeni metni (sayfa → metin).
Map<int, String> pageNotesWithBubbles(
  Note note,
  Attachment attachment,
  Iterable<PageBubble> bubbles,
) {
  final byPage = <int, List<String>>{};
  for (final b in orderedTextBubbles(bubbles)) {
    byPage.putIfAbsent(b.page, () => []).add(bubbleShareLine(b));
  }
  final out = <int, String>{};
  byPage.forEach((page, lines) {
    final existing = note.pageNote(attachment, page);
    final have = stripRichMarkers(existing);
    final fresh = [
      for (final l in lines)
        if (!have.contains(l)) l,
    ];
    if (fresh.isEmpty) return;
    final base = existing.trimRight();
    out[page] = base.isEmpty ? fresh.join('\n') : '$base\n${fresh.join('\n')}';
  });
  return out;
}
