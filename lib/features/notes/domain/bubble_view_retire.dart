import '../../../core/utils/pdf_ref.dart';
import 'note.dart';
import 'page_notes.dart';

/// BALONLU GÖRÜNÜM KALKTI (kullanıcı isteği 2026-11-05: "sabitleme ile
/// balonlu modu birleştir, tek mod sabitleme olsun, orada balon ekleme
/// olabilir; özellikler oraya aktarılır, balonlu mod tamamen kaldır").
///
/// Balonlu notun (`NoteType.pdf/slides`) SAYFA NOTLARI yalnız balonlu
/// görünümde görünüyordu. Görünüm kalkınca kaybolmasınlar diye gövdeye
/// sayfa referanslı satırlar olarak taşınırlar: `📖 s.3 metin` — referans
/// sabit PDF'te dokununca o sayfaya döner (bkz. `pdf_ref.dart`). Sayfa
/// notları haritası BOŞ dizgiyle yazılır (anahtar silinmez — derin birleştirme
/// kuralı, bkz. [Note.withPageNote]); metin gövdede durduğu için hiçbir şey
/// kaybolmaz, oturumda "Geri al" eski hâle döner.
///
/// Balonlar ve vurgular ekte kaldığı için dokunulmaz: sabit PDF onları
/// kendisi çizer ve "Balon ekle" ile yenisi eklenir.
Note movePageNotesToBody(Note note, {required bool turkish}) {
  final lines = <String>[];
  for (final attachment in note.attachments) {
    for (final entry in orderedPageNotes(
      attachment: attachment,
      pageNotes: note.pageNotes,
    )) {
      final text = entry.text.trim();
      if (text.isEmpty) continue;
      lines.add('${formatPdfRef(page: entry.page, turkish: turkish)} $text');
    }
  }
  if (lines.isEmpty) return note;
  final body = note.body.trimRight();
  final added = lines.join('\n');
  return note.copyWith(
    body: body.isEmpty ? added : '$body\n\n$added',
    pageNotes: {for (final key in note.pageNotes.keys) key: ''},
  );
}
