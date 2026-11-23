import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

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

/// Seçilebilen sütun sayıları (ayrıca model 1–6 arasını kabul eder).
const kTableColumnChoices = [2, 3, 4];
const kTableMaxColumns = 6;

/// Tablonun en çok satırı (not belgesi 1 MiB sınırının çok altında kalsın).
const kTableMaxRows = 300;

/// Sütun en az bu oranda kalır (sürükleyerek daraltırken).
const kTableMinColumnFrac = 0.12;

bool isNoteTable(Attachment a) =>
    a.kind == AttachmentKind.text && a.extras[kTableExtra] is Map;

@immutable
class NoteTable {
  NoteTable({
    required int columns,
    required List<String> cells,
    List<double>? widths,
    this.header = true,
  }) : columns = columns.clamp(1, kTableMaxColumns),
       cells = List.unmodifiable(
         _fit(cells, columns.clamp(1, kTableMaxColumns)),
       ),
       widths = List.unmodifiable(
         _normalize(widths, columns.clamp(1, kTableMaxColumns)),
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

  int get rows => cells.length ~/ columns;

  String cell(int row, int column) => cells[row * columns + column];

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
      header: raw['header'] is bool ? raw['header'] as bool : true,
    );
  }

  Map<String, dynamic> toMap() => {
    'cols': columns,
    'cells': cells,
    if (!evenWidths) 'widths': [for (final w in widths) _round(w)],
    'header': header,
  };

  NoteTable _with({
    int? columns,
    List<String>? cells,
    List<double>? widths,
    bool clearWidths = false,
    bool? header,
  }) => NoteTable(
    columns: columns ?? this.columns,
    cells: cells ?? this.cells,
    widths: clearWidths ? null : (widths ?? this.widths),
    header: header ?? this.header,
  );

  NoteTable withCell(int row, int column, String text) {
    final i = row * columns + column;
    if (i < 0 || i >= cells.length || cells[i] == text) return this;
    return _with(cells: [...cells]..[i] = text);
  }

  /// [at] konumuna boş satır (sona eklemek için `rows`).
  NoteTable insertRow(int at) {
    if (rows >= kTableMaxRows) return this;
    final i = at.clamp(0, rows) * columns;
    return _with(cells: [...cells]..insertAll(i, List.filled(columns, '')));
  }

  /// [row]'u siler; tek satır kaldıysa yalnız yazıları temizlenir.
  NoteTable removeRow(int row) {
    if (row < 0 || row >= rows) return this;
    if (rows == 1) return _with(cells: List.filled(columns, ''));
    return _with(
      cells: [...cells]..removeRange(row * columns, (row + 1) * columns),
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
      header: header,
    );
  }

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
        final v = esc(cell(r, c));
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
            cell(r, c).replaceAll('\n', ' ').trim(),
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
      listEquals(other.cells, cells) &&
      _sameWidths(other.widths, widths);

  @override
  int get hashCode => Object.hash(columns, header, Object.hashAll(cells));

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
  required int columns,
  required String name,
  required int height,
  int rows = 3,
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
