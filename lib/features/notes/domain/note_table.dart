import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/rich_text.dart' show stripRichMarkers;
import 'attachment.dart';

/// **TABLO** (kullanıcı isteği 2026-11-23: "2, 3, 4 sütunluk tablolar
/// eklenebilsin; boyutu ayarlanabilsin; istediğimiz kadar satır eklenebilsin;
/// her karenin kendi yazısı olsun").
///
/// Tablo bir METİN EKİDİR ([AttachmentKind.text], `extras.table`): sayfada
/// metin kutusu gibi yüzer (basılı tut = taşı, köşe = boyutlandır, yazı
/// etrafından akar), notla birlikte senkronlanır, dosyası yoktur.
///
/// * Yapı `extras.table`'da: `{cols, cells, widths?, header}` — hücreler
///   satır satır DÜZ liste (Firestore iç içe dizi kabul etmez).
/// * [Attachment.text] tablonun Markdown hâli (`| a | b |`): arama, paylaşım,
///   dışa aktarma ve tabloyu tanımayan eski sürüm (metin kutusu olarak
///   okur) aynı metni görür. Kaynak her zaman `extras.table`'dır.
const kTableExtra = 'table';

/// İlk eklemede tablo 3 satır × 2 sütun (kullanıcı isteği 2026-11-23);
/// sayılar tablonun kendi ayarında değişir (sütun 1–6, satır 1–300).
const kTableDefaultRows = 3;
const kTableDefaultColumns = 2;
const kTableMaxColumns = 6;

/// Tablonun en çok satırı (not belgesi 1 MiB sınırının çok altında kalsın).
const kTableMaxRows = 300;

/// Sütun en az bu oranda kalır (sürükleyerek daraltırken).
const kTableMinColumnFrac = 0.12;

/// Hücre hizası (kullanıcı isteği 2026-11-23: "ortala, sağa yasla, sola
/// yasla seçenekleri olmalı" — her hücre TEK TEK). Kayıtta harf: `l` sola,
/// `c` orta, `r` sağa.
enum CellAlign {
  start('l'),
  center('c'),
  end('r');

  const CellAlign(this.code);
  final String code;

  static CellAlign of(String code) => switch (code) {
    'c' => CellAlign.center,
    'r' => CellAlign.end,
    _ => CellAlign.start,
  };
}

bool isNoteTable(Attachment a) =>
    a.kind == AttachmentKind.text && a.extras[kTableExtra] is Map;

@immutable
class NoteTable {
  NoteTable({
    required int columns,
    required List<String> cells,
    List<double>? widths,
    String? aligns,
    this.header = true,
    this.striped = false,
  }) : columns = columns.clamp(1, kTableMaxColumns),
       cells = List.unmodifiable(
         _fit(cells, columns.clamp(1, kTableMaxColumns)),
       ),
       widths = List.unmodifiable(
         _normalize(widths, columns.clamp(1, kTableMaxColumns)),
       ),
       aligns = _fitAligns(
         aligns,
         _fit(cells, columns.clamp(1, kTableMaxColumns)).length,
       );

  /// [columns] sütunlu, [rows] satırlı boş tablo.
  factory NoteTable.blank(int columns, {int rows = 3}) => NoteTable(
    columns: columns,
    cells: List.filled(columns.clamp(1, kTableMaxColumns) * rows, ''),
  );

  final int columns;

  /// Satır satır hücre yazıları; uzunluk her zaman `rows * columns`.
  final List<String> cells;

  /// Sütun genişlik oranları (toplamı 1).
  final List<double> widths;

  /// İlk satır başlık mı (kalın, tonlu zemin).
  final bool header;

  /// Veri satırlarında dönüşümlü zebra zemini çizilsin mi.
  final bool striped;

  /// Hücre hizaları, hücre başına bir harf ([CellAlign.code]); hepsi sola
  /// ise boş dize (kayda yazılmaz).
  final String aligns;

  int get rows => cells.length ~/ columns;

  String cell(int row, int column) => cells[row * columns + column];

  /// Hücrenin biçim işaretsiz yazısı (dışa aktarma, Markdown, paylaşım):
  /// hücreler biçim paneliyle kalın/renkli yazılabilir (2026-11-23).
  String plainCell(int row, int column) => stripRichMarkers(cell(row, column));

  CellAlign alignOf(int row, int column) {
    if (aligns.isEmpty) return CellAlign.start;
    return CellAlign.of(aligns[row * columns + column]);
  }

  NoteTable withAlign(int row, int column, CellAlign align) {
    final i = row * columns + column;
    if (i < 0 || i >= cells.length || alignOf(row, column) == align) {
      return this;
    }
    final chars = (aligns.isEmpty ? 'l' * cells.length : aligns).split('');
    chars[i] = align.code;
    return _with(aligns: chars.join());
  }

  /// Satır [at]'e [count] satırlık hiza harfi ekler/çıkarır (yapı işleri).
  String _alignsWithRows(int at, int count, {bool remove = false}) {
    if (aligns.isEmpty) return '';
    final i = at * columns;
    if (remove) {
      return aligns.replaceRange(i, i + count * columns, '');
    }
    return aligns.replaceRange(i, i, 'l' * (count * columns));
  }

  /// Sütunlar eşit genişlikte mi.
  bool get evenWidths => widths.every((w) => (w - 1 / columns).abs() < 0.005);

  /// Kayıttaki tablo; tablo değilse ya da kayıt bozuksa null.
  static NoteTable? of(Attachment a) {
    final raw = a.extras[kTableExtra];
    if (raw is! Map) return null;
    final cols = raw['cols'];
    if (cols is! num || cols < 1) return null;
    final cells = raw['cells'];
    final widths = raw['widths'];
    return NoteTable(
      columns: cols.toInt(),
      cells: [
        if (cells is List)
          for (final c in cells) c is String ? c : (c?.toString() ?? ''),
      ],
      widths: widths is List
          ? [for (final w in widths) w is num ? w.toDouble() : 0]
          : null,
      aligns: raw['align'] is String ? raw['align'] as String : null,
      header: raw['header'] is bool ? raw['header'] as bool : true,
      striped: raw['striped'] == true,
    );
  }

  Map<String, dynamic> toMap() => {
    'cols': columns,
    'cells': cells,
    if (!evenWidths) 'widths': [for (final w in widths) _round(w)],
    if (aligns.isNotEmpty) 'align': aligns,
    'header': header,
    if (striped) 'striped': true,
  };

  NoteTable _with({
    int? columns,
    List<String>? cells,
    List<double>? widths,
    bool clearWidths = false,
    bool? header,
    bool? striped,
    String? aligns,
  }) => NoteTable(
    columns: columns ?? this.columns,
    cells: cells ?? this.cells,
    widths: clearWidths ? null : (widths ?? this.widths),
    aligns: aligns ?? this.aligns,
    header: header ?? this.header,
    striped: striped ?? this.striped,
  );

  NoteTable withCell(int row, int column, String text) {
    final i = row * columns + column;
    if (i < 0 || i >= cells.length || cells[i] == text) return this;
    return _with(cells: [...cells]..[i] = text);
  }

  /// [at] konumuna boş satır (sona eklemek için `rows`).
  NoteTable insertRow(int at) {
    if (rows >= kTableMaxRows) return this;
    final row = at.clamp(0, rows);
    final i = row * columns;
    return _with(
      cells: [...cells]..insertAll(i, List.filled(columns, '')),
      aligns: _alignsWithRows(row, 1),
    );
  }

  /// [row]'u siler; tek satır kaldıysa yalnız yazıları temizlenir.
  NoteTable removeRow(int row) {
    if (row < 0 || row >= rows) return this;
    if (rows == 1) return _with(cells: List.filled(columns, ''));
    return _with(
      cells: [...cells]..removeRange(row * columns, (row + 1) * columns),
      aligns: _alignsWithRows(row, 1, remove: true),
    );
  }

  /// Sütun sayısını değiştirir: yeni sütunlar boş, fazla sütunlar düşer.
  /// Genişlikler eşitlenir.
  NoteTable withColumns(int count) {
    final n = count.clamp(1, kTableMaxColumns);
    if (n == columns) return this;
    return NoteTable(
      columns: n,
      cells: [
        for (var r = 0; r < rows; r++)
          for (var c = 0; c < n; c++) c < columns ? cell(r, c) : '',
      ],
      aligns: aligns.isEmpty
          ? null
          : [
              for (var r = 0; r < rows; r++)
                for (var c = 0; c < n; c++)
                  c < columns ? aligns[r * columns + c] : 'l',
            ].join(),
      header: header,
      striped: striped,
    );
  }

  /// [index] konumuna boş sütun ekler; mevcut sütun genişliklerini orantılı
  /// daraltır. En çok [kTableMaxColumns] sınırı korunur.
  NoteTable insertColAt(int index) {
    if (columns >= kTableMaxColumns) return this;
    final at = index.clamp(0, columns);
    final nextCols = columns + 1;
    final avg = 1 / nextCols;
    final nextWidths = [for (final w in widths) w * (1 - avg)]
      ..insert(at, avg);
    final nextCells = <String>[];
    final hasAligns = aligns.isNotEmpty;
    final nextAligns = hasAligns ? StringBuffer() : null;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < columns; c++) {
        if (c == at) {
          nextCells.add('');
          nextAligns?.write('l');
        }
        nextCells.add(cell(r, c));
        nextAligns?.write(alignOf(r, c).code);
      }
      if (at == columns) {
        nextCells.add('');
        nextAligns?.write('l');
      }
    }
    return NoteTable(
      columns: nextCols,
      cells: nextCells,
      widths: nextWidths,
      aligns: nextAligns?.toString(),
      header: header,
      striped: striped,
    );
  }

  /// [index] sütununu siler; en az 2 sütun kalır.
  NoteTable deleteColAt(int index) {
    if (columns <= 2 || index < 0 || index >= columns) return this;
    final nextCols = columns - 1;
    final nextWidths = <double>[
      for (var c = 0; c < columns; c++)
        if (c != index) widths[c],
    ];
    final nextCells = <String>[];
    final hasAligns = aligns.isNotEmpty;
    final nextAligns = hasAligns ? StringBuffer() : null;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < columns; c++) {
        if (c == index) continue;
        nextCells.add(cell(r, c));
        nextAligns?.write(alignOf(r, c).code);
      }
    }
    return NoteTable(
      columns: nextCols,
      cells: nextCells,
      widths: nextWidths,
      aligns: nextAligns?.toString(),
      header: header,
      striped: striped,
    );
  }

  /// Satırları [col] sütununa göre sıralar; [header] açıksa ilk satır sabit
  /// kalır. Sayısal değerler sayısal, metinler Türkçe katlamalı alfabetik
  /// sırayla karşılaştırılır; boş hücreler her zaman sona konur.
  NoteTable sortByColumn(int col, {bool ascending = true}) {
    if (col < 0 || col >= columns || rows < 2) return this;
    final startRow = header ? 1 : 0;
    if (rows - startRow < 2) return this;
    final fixedCells = cells.sublist(0, startRow * columns);
    final fixedAligns = aligns.isEmpty
        ? ''
        : aligns.substring(0, startRow * columns);
    final dataRows = <({List<String> cells, String aligns, String key})>[
      for (var r = startRow; r < rows; r++)
        (
          cells: cells.sublist(r * columns, (r + 1) * columns),
          aligns: aligns.isEmpty
              ? ''
              : aligns.substring(r * columns, (r + 1) * columns),
          key: plainCell(r, col).trim(),
        ),
    ];
    dataRows.sort((a, b) {
      if (a.key.isEmpty && b.key.isEmpty) return 0;
      if (a.key.isEmpty) return 1;
      if (b.key.isEmpty) return -1;
      final na = _parseSortNumber(a.key);
      final nb = _parseSortNumber(b.key);
      final cmp = na != null && nb != null
          ? na.compareTo(nb)
          : _foldTr(a.key).compareTo(_foldTr(b.key));
      return ascending ? cmp : -cmp;
    });
    return _with(
      cells: [...fixedCells, for (final r in dataRows) ...r.cells],
      aligns: aligns.isEmpty
          ? ''
          : '$fixedAligns${dataRows.map((r) => r.aligns).join()}',
    );
  }

  static double? _parseSortNumber(String raw) {
    final normalized = raw.replaceAll(' ', '').replaceAll(',', '.');
    if (!RegExp(r'^-?\d+(?:\.\d+)?$').hasMatch(normalized)) return null;
    return double.tryParse(normalized);
  }

  static String _foldTr(String s) {
    final out = StringBuffer();
    for (final r in s.runes) {
      final c = String.fromCharCode(r);
      out.write(switch (c) {
        'Ç' || 'ç' => 'c',
        'Ğ' || 'ğ' => 'g',
        'İ' || 'I' || 'ı' => 'i',
        'Ö' || 'ö' => 'o',
        'Ş' || 'ş' => 's',
        'Ü' || 'ü' => 'u',
        _ => c.toLowerCase(),
      });
    }
    return out.toString();
  }

  /// Satır sayısını değiştirir: yeni satırlar sonda boş, fazlası sondan düşer.
  NoteTable withRows(int count) {
    final n = count.clamp(1, kTableMaxRows);
    if (n == rows) return this;
    return _with(
      cells: n > rows
          ? [...cells, ...List.filled((n - rows) * columns, '')]
          : cells.sublist(0, n * columns),
      aligns: n > rows
          ? _alignsWithRows(rows, n - rows)
          : _alignsWithRows(n, rows - n, remove: true),
    );
  }

  /// [count] satıra inince silinecek dolu hücre var mı.
  bool dropsRowText(int count) =>
      cells.skip(count * columns).any((c) => c.trim().isNotEmpty);

  /// [count] sütuna inince silinecek dolu hücre var mı.
  bool dropsText(int count) {
    for (var r = 0; r < rows; r++) {
      for (var c = count; c < columns; c++) {
        if (cell(r, c).trim().isNotEmpty) return true;
      }
    }
    return false;
  }

  /// [border] (1…columns-1) sınırını [delta] oran kadar kaydırır: soldaki
  /// sütun büyür, sağdaki küçülür (ikisi de [kTableMinColumnFrac]'ın
  /// altına inmez).
  NoteTable moveBorder(int border, double delta) {
    if (border < 1 || border >= columns) return this;
    final w = [...widths];
    final pair = w[border - 1] + w[border];
    final left = (w[border - 1] + delta)
        .clamp(kTableMinColumnFrac, pair - kTableMinColumnFrac)
        .toDouble();
    w[border - 1] = left;
    w[border] = pair - left;
    return _with(widths: w);
  }

  NoteTable evenedWidths() => _with(clearWidths: true);

  NoteTable withHeader(bool value) => _with(header: value);

  NoteTable withStriped(bool value) => _with(striped: value);

  /// RFC-4180 CSV çıktısı (tırnaklı alanlar ve biçim işaretsiz düz metin).
  String toCsv() {
    String q(String v) {
      final cleaned = v.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
      if (cleaned.contains(',') ||
          cleaned.contains('"') ||
          cleaned.contains('\n')) {
        return '"${cleaned.replaceAll('"', '""')}"';
      }
      return cleaned;
    }

    return [
      for (var r = 0; r < rows; r++)
        [for (var c = 0; c < columns; c++) q(plainCell(r, c))].join(','),
    ].join('\n');
  }

  /// Panodan gelen CSV / TSV / noktalı virgül metnini tabloya çevirir.
  /// En az 2 sütunlu anlamlı içerik yoksa null döner.
  static NoteTable? fromDelimited(String raw) {
    final clean = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();
    if (clean.isEmpty) return null;
    final delimiter = clean.contains('\t')
        ? '\t'
        : (_countUnquoted(clean, ';') > _countUnquoted(clean, ',') ? ';' : ',');
    final parsed = _parseDelimited(clean, delimiter);
    if (parsed.isEmpty) return null;
    var maxCols = 0;
    for (final row in parsed) {
      if (row.length > maxCols) maxCols = row.length;
    }
    final cols = maxCols.clamp(1, kTableMaxColumns);
    final rows = parsed.length.clamp(1, kTableMaxRows);
    if (cols < 2) return null;
    final cells = <String>[
      for (var r = 0; r < rows; r++)
        for (var c = 0; c < cols; c++)
          c < parsed[r].length ? parsed[r][c].trim() : '',
    ];
    if (!cells.any((c) => c.isNotEmpty)) return null;
    return NoteTable(columns: cols, cells: cells);
  }

  static int _countUnquoted(String text, String ch) {
    var inQuotes = false;
    var count = 0;
    for (var i = 0; i < text.length; i++) {
      final cur = text[i];
      if (cur == '"') {
        inQuotes = !inQuotes;
      } else if (!inQuotes && cur == ch) {
        count++;
      }
    }
    return count;
  }

  static List<List<String>> _parseDelimited(String text, String delim) {
    final rows = <List<String>>[];
    var row = <String>[];
    final buf = StringBuffer();
    var inQuotes = false;
    var i = 0;
    while (i < text.length) {
      final ch = text[i];
      if (inQuotes) {
        if (ch == '"') {
          if (i + 1 < text.length && text[i + 1] == '"') {
            buf.write('"');
            i += 2;
            continue;
          }
          inQuotes = false;
          i++;
          continue;
        }
        buf.write(ch);
        i++;
        continue;
      }
      if (ch == '"') {
        inQuotes = true;
        i++;
        continue;
      }
      if (ch == delim) {
        row.add(buf.toString());
        buf.clear();
        i++;
        continue;
      }
      if (ch == '\n') {
        row.add(buf.toString());
        buf.clear();
        if (row.any((c) => c.isNotEmpty)) rows.add(row);
        row = <String>[];
        i++;
        continue;
      }
      buf.write(ch);
      i++;
    }
    row.add(buf.toString());
    if (row.any((c) => c.isNotEmpty)) rows.add(row);
    return rows;
  }

  /// Markdown tablo (`| a | b |`); başlık kapalıysa da ilk satırın altına
  /// ayraç yazılır (Markdown'da tablo ayraçsız tanınmaz).
  String toMarkdown() {
    String esc(String s) => s
        .replaceAll(r'\', r'\\')
        .replaceAll('|', r'\|')
        .replaceAll('\r', '')
        .replaceAll('\n', '<br>')
        .trim();
    final out = StringBuffer();
    for (var r = 0; r < rows; r++) {
      out.write('|');
      for (var c = 0; c < columns; c++) {
        final v = esc(plainCell(r, c));
        out.write(v.isEmpty ? '  |' : ' $v |');
      }
      out.write('\n');
      if (r == 0) {
        out.write('|');
        for (var c = 0; c < columns; c++) {
          out.write(' --- |');
        }
        out.write('\n');
      }
    }
    return out.toString().trimRight();
  }

  /// Paylaşım metni: satır başına `a | b | c`; tümüyle boş satırlar atlanır.
  String toShareText() => [
    for (var r = 0; r < rows; r++)
      if (cells
          .sublist(r * columns, (r + 1) * columns)
          .any((c) => c.trim().isNotEmpty))
        [
          for (var c = 0; c < columns; c++)
            plainCell(r, c).replaceAll('\n', ' ').trim(),
        ].join(' | '),
  ].join('\n');

  /// Tablonun ekteki hâli: yapı + Markdown metni.
  Attachment applyTo(Attachment a) {
    final md = toMarkdown();
    return a.copyWith(
      text: md,
      sizeBytes: md.length,
      extras: {...a.extras, kTableExtra: toMap()},
    );
  }

  /// Genişlikler kayıtta 4 haneye yuvarlanır: karşılaştırma ‰ duyarlı
  /// (kendi kaydının yankısı "değişti" sayılmasın).
  @override
  bool operator ==(Object other) =>
      other is NoteTable &&
      other.columns == columns &&
      other.header == header &&
      other.striped == striped &&
      other.aligns == aligns &&
      listEquals(other.cells, cells) &&
      _sameWidths(other.widths, widths);

  @override
  int get hashCode =>
      Object.hash(columns, header, striped, aligns, Object.hashAll(cells));

  static bool _sameWidths(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if ((a[i] - b[i]).abs() > 0.001) return false;
    }
    return true;
  }

  static List<String> _fit(List<String> cells, int columns) {
    final rows = cells.isEmpty ? 1 : (cells.length + columns - 1) ~/ columns;
    return [
      for (var i = 0; i < rows * columns; i++) i < cells.length ? cells[i] : '',
    ];
  }

  /// Hiza dizesi hücre sayısına uydurulur; hepsi sola ise boş dize.
  static String _fitAligns(String? aligns, int count) {
    if (aligns == null || aligns.isEmpty) return '';
    final out = StringBuffer();
    for (var i = 0; i < count; i++) {
      final ch = i < aligns.length ? aligns[i] : 'l';
      out.write(ch == 'c' || ch == 'r' ? ch : 'l');
    }
    final s = out.toString();
    return s.contains(RegExp('[cr]')) ? s : '';
  }

  static List<double> _normalize(List<double>? widths, int columns) {
    final even = List<double>.filled(columns, 1 / columns);
    if (widths == null || widths.length != columns) return even;
    if (widths.any((w) => !w.isFinite || w <= 0)) return even;
    final sum = widths.fold<double>(0, (a, b) => a + b);
    if (sum <= 0) return even;
    return [for (final w in widths) w / sum];
  }

  static double _round(double v) => (v * 10000).roundToDouble() / 10000;
}

/// Ad listesinde çakışmayan tablo adı: "Tablo", "Tablo 2"…
String tableName(String base, Set<String> taken) {
  var name = base;
  for (var n = 2; taken.contains(name); n++) {
    name = '$base $n';
  }
  return name;
}

/// Yeni (sayfaya henüz yerleşmemiş) tablo eki. [height]: kutunun oranı için
/// başlangıç tahmini (genişlik 1000 birim; kutu ilk çiziminde gerçeğini
/// yazar).
Attachment newNoteTable({
  required String name,
  required int height,
  int columns = kTableDefaultColumns,
  int rows = kTableDefaultRows,
}) {
  final table = NoteTable.blank(columns, rows: rows);
  final md = table.toMarkdown();
  return Attachment(
    id: const Uuid().v4(),
    kind: AttachmentKind.text,
    fileName: name,
    mimeType: 'text/plain',
    text: md,
    sizeBytes: md.length,
    width: 1000,
    height: height,
    onPage: true,
    createdAt: DateTime.now(),
    extras: {kTableExtra: table.toMap()},
  );
}
