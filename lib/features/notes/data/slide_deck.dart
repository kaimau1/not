import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart';

import 'pptx_render.dart';
import 'zip_guard.dart';

/// Bir .pptx dosyasını, gerçek tasarımıyla çizilebilir slayt modellerine
/// (`SlideVM`) çevirir — salt görüntüleme için. Düzenleme yok; çizim/animasyon
/// "dosya okuyucu" uygulamasındaki [PptxRender] motoruyla aynı.
abstract final class SlideDeck {
  /// Baytlardan slayt listesi üretir. Ayrıştırma ağır olabildiğinden (unzip +
  /// XML) [compute] ile arka planda yapılır; UI kilitlenmez.
  ///
  /// SlideVM ve içindekiler (görsel baytları vb.) izolattan güvenle taşınır.
  static Future<List<SlideVM>> fromBytes(Uint8List bytes) =>
      compute(_render, bytes);
}

const _kSlideZipMaxFiles = 2000;
const _kSlideZipMaxBytes = 120 * 1024 * 1024;

List<SlideVM> _render(Uint8List bytes) {
  final Archive archive;
  try {
    archive = ZipGuard.decodeBytes(
      bytes,
      maxFileCount: _kSlideZipMaxFiles,
      maxBytes: _kSlideZipMaxBytes,
    );
  } on ArchiveException {
    return const [];
  } on FormatException {
    return const [];
  }
  final budget = ZipByteBudget(maxBytes: _kSlideZipMaxBytes);
  final render = PptxRender(archive);
  final presentation = _tryParse(archive, 'ppt/presentation.xml', budget);
  final presRels = _tryParse(archive, 'ppt/_rels/presentation.xml.rels', budget);

  final out = <SlideVM>[];
  for (final name in _orderedSlideFiles(archive, presentation, presRels)) {
    final Uint8List? content;
    try {
      content = _fileByName(archive, name, budget);
    } on FormatException {
      return const [];
    }
    if (content == null) continue;
    try {
      final doc = XmlDocument.parse(utf8.decode(content, allowMalformed: true));
      out.add(render.slide(name, doc));
    } catch (_) {
      // Bozuk/desteklenmeyen slayt atlanır; kalanlar yine gösterilir.
    }
  }
  return out;
}

/// Slaytları sunumdaki gerçek sıraya (`p:sldIdLst`) göre, yoksa dosya
/// numarasına göre sıralar.
List<String> _orderedSlideFiles(
  Archive archive,
  XmlDocument? presentation,
  XmlDocument? presRels,
) {
  final globbed =
      archive.files
          .map((f) => f.name)
          .where(
            (n) => n.startsWith('ppt/slides/slide') && n.endsWith('.xml'),
          )
          .toList()
        ..sort((a, b) => _idx(a).compareTo(_idx(b)));

  if (presentation == null || presRels == null) return globbed;
  final lst = presentation.findAllElements('p:sldIdLst').firstOrNull;
  if (lst == null) return globbed;

  final relMap = _relTargets(presRels);
  final ordered = <String>[];
  for (final sldId in lst.findElements('p:sldId')) {
    final rid = sldId.getAttribute('r:id');
    final target = rid == null ? null : relMap[rid];
    if (target != null && globbed.contains(target) && !ordered.contains(target)) {
      ordered.add(target);
    }
  }
  for (final g in globbed) {
    if (!ordered.contains(g)) ordered.add(g);
  }
  return ordered.isEmpty ? globbed : ordered;
}

Map<String, String> _relTargets(XmlDocument presRels) {
  final out = <String, String>{};
  for (final r in presRels.findAllElements('Relationship')) {
    final id = r.getAttribute('Id');
    final target = r.getAttribute('Target');
    if (id == null || target == null) continue;
    if (r.getAttribute('TargetMode') == 'External') continue;
    out[id] = _normTarget(target);
  }
  return out;
}

String _normTarget(String t) {
  if (t.startsWith('/')) return t.substring(1);
  var s = t;
  var base = 'ppt/';
  while (s.startsWith('../')) {
    s = s.substring(3);
    base = '';
  }
  return '$base$s';
}

XmlDocument? _tryParse(Archive archive, String name, ZipByteBudget budget) {
  final Uint8List? content;
  try {
    content = _fileByName(archive, name, budget);
  } on FormatException {
    return null;
  }
  if (content == null) return null;
  try {
    return XmlDocument.parse(utf8.decode(content, allowMalformed: true));
  } catch (_) {
    return null;
  }
}

Uint8List? _fileByName(Archive archive, String name, ZipByteBudget budget) {
  for (final f in archive.files) {
    if (f.name == name) return ZipGuard.readEntryBytes(f, budget);
  }
  return null;
}

int _idx(String name) {
  final m = RegExp(r'slide(\d+)\.xml').firstMatch(name);
  return m == null ? 0 : int.parse(m.group(1)!);
}
