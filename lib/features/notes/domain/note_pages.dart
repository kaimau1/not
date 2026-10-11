/// NOTUN SAYFALARI — saf işlemler (testlerde doğrudan sınanır).
///
/// Model [Note.textPages]'te anlatıldı: ETKİN sayfanın içeriği notun kendi
/// `body`/`items` alanlarında yaşar, listedeki girdisi boştur. Sayfa geçişi
/// içerikleri yer değiştirir; sayfaya ait görseller `Attachment.section` ile
/// sayfaya bağlıdır (ilk sayfa = '').
library;

import 'note.dart';
import 'note_item.dart';

/// Bir sayfanın GERÇEK içeriği (etkin sayfa için notun gövdesi).
typedef ResolvedTextPage = ({String id, String body, List<NoteItem> items});

/// Sayfası olmayan (tek sayfalı) not için de tek girdi döner — çağıranlar
/// ayrım yapmadan dolaşabilsin.
List<ResolvedTextPage> resolvedTextPages(Note note) {
  final pages = _normalized(note);
  if (pages.isEmpty) {
    return [(id: '', body: note.body, items: note.items)];
  }
  return [
    for (final p in pages)
      p.id == note.activePage
          ? (id: p.id, body: note.body, items: note.items)
          : (id: p.id, body: p.body, items: p.items),
  ];
}

/// Etkin sayfanın sırası (0 tabanlı) ve toplam sayfa sayısı.
({int index, int count}) textPagePosition(Note note) {
  final pages = _normalized(note);
  if (pages.isEmpty) return (index: 0, count: 1);
  final i = pages.indexWhere((p) => p.id == note.activePage);
  return (index: i < 0 ? 0 : i, count: pages.length);
}

/// Etkin sayfanın ARKASINA boş bir sayfa ekler ve ona geçer. Tek sayfalı
/// notta önce mevcut içerik ilk sayfa ('') olur.
Note addTextPage(Note note, String newId) {
  final pages = [..._normalized(note)];
  if (pages.isEmpty) pages.add(const NoteTextPage(id: ''));
  final at = pages.indexWhere((p) => p.id == note.activePage);
  pages.insert(at < 0 ? pages.length : at + 1, NoteTextPage(id: newId));
  return switchTextPage(note.copyWith(textPages: pages), newId);
}

/// [targetId] sayfasına geçer: etkin sayfanın içeriği listeye yazılır,
/// hedefinki gövdeye taşınır.
Note switchTextPage(Note note, String targetId) {
  final pages = _normalized(note);
  if (targetId == note.activePage) return note;
  final target = pages.where((p) => p.id == targetId).firstOrNull;
  if (target == null) return note;
  return note.copyWith(
    body: target.body,
    items: target.items,
    activePage: targetId,
    textPages: [
      for (final p in pages)
        if (p.id == note.activePage)
          p.copyWith(body: note.body, items: note.items)
        else if (p.id == targetId)
          p.copyWith(body: '', items: const [])
        else
          p,
    ],
  );
}

/// [id] sayfasını siler. Yazısı gider (geri al ile döner); görselleri
/// KAYBOLMAZ, komşu sayfaya (öncekine, ilk sayfaysa sonrakine) taşınır.
/// Tek sayfa kalırsa not yeniden tek sayfalı olur.
Note deleteTextPage(Note note, String id) {
  var n = note.copyWith(textPages: _normalized(note));
  final pages = n.textPages;
  if (pages.length <= 1) return note;
  final idx = pages.indexWhere((p) => p.id == id);
  if (idx < 0) return note;
  final neighbor = pages[idx > 0 ? idx - 1 : idx + 1].id;
  if (n.activePage == id) n = switchTextPage(n, neighbor);

  // İlk sayfa siliniyorsa komşu İLK sayfa olur: kimliği '' alır (bölümsüz
  // görseller ilk sayfaya aittir — bkz. [Note.textPages]).
  final newNeighborId = id == '' ? '' : neighbor;
  String moveSection(String section) {
    if (section == id || section == neighbor) return newNeighborId;
    return section;
  }

  final remaining = [
    for (final p in n.textPages)
      if (p.id != id) p.id == neighbor ? p.copyWith(id: newNeighborId) : p,
  ];
  return n.copyWith(
    textPages: remaining.length <= 1 ? const [] : remaining,
    activePage: remaining.length <= 1
        ? ''
        : (n.activePage == neighbor ? newNeighborId : n.activePage),
    attachments: [
      for (final a in n.attachments)
        a.section == id || a.section == neighbor
            ? a.copyWith(section: moveSection(a.section))
            : a,
    ],
  );
}

/// Bozuk/yarım kayda karşı: etkin sayfanın listede girdisi YOKSA başa
/// eklenir (içeriği gövdede olduğu için kaybolmaz).
List<NoteTextPage> _normalized(Note note) {
  final pages = note.textPages;
  if (pages.isEmpty) return pages;
  if (pages.any((p) => p.id == note.activePage)) return pages;
  return [NoteTextPage(id: note.activePage), ...pages];
}
