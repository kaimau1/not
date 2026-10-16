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
  });

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
  }) => ShareTextOptions(
    title: title ?? this.title,
    checked: checked ?? this.checked,
    tags: tags ?? this.tags,
    links: links ?? this.links,
  );

  /// Tercihlerin saklanan biçimi (paylaşım levhası son seçimi hatırlar).
  String encode() =>
      '${title ? 1 : 0}${checked ? 1 : 0}${tags ? 1 : 0}${links ? 1 : 0}';

  static ShareTextOptions decode(String? raw) {
    if (raw == null || raw.length < 4) return const ShareTextOptions();
    bool at(int i) => raw[i] == '1';
    return ShareTextOptions(
      title: at(0),
      checked: at(1),
      tags: at(2),
      links: at(3),
    );
  }
}

/// Nottaki YouTube videoları (bağlantısı olanlar), sırasıyla.
List<Attachment> shareableVideoLinks(Note note) => [
  for (final a in note.attachments)
    if (a.isWebVideo && a.webUrl.trim().isNotEmpty) a,
];

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

  final body = _tidy(stripRichMarkers(note.body));
  if (body.isNotEmpty) blocks.add(body);

  final items = _itemLines(note, includeChecked: options.checked);
  if (items.isNotEmpty) blocks.add(items.join('\n'));

  if (note.type.isPageNoteType) {
    final label = pageLabel ?? (int page) => '#$page';
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
    blocks.add([for (final t in note.tags) '#${t.replaceAll(' ', '_')}'].join(' '));
  }
  return blocks.join('\n\n');
}

/// Birden çok notun metni tek parçada (ana ekranda seçili notlar): notlar
/// arasında boş satırlı ince bir ayraç.
String joinShareTexts(Iterable<String> texts) => texts
    .map((t) => t.trim())
    .where((t) => t.isNotEmpty)
    .join('\n\n—————\n\n');

List<String> _itemLines(Note note, {required bool includeChecked}) {
  String clean(NoteItem item) =>
      _tidy(stripRichMarkers(item.text)).replaceAll('\n', '\n   ');
  final items = [
    for (final i in note.items)
      if (clean(i).isNotEmpty) i,
  ];
  if (items.isEmpty) return const [];
  switch (note.type) {
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
