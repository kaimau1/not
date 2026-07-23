import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart';

import 'pptx_render.dart';

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

List<SlideVM> _render(Uint8List bytes) {
  final archive = ZipDecoder().decodeBytes(bytes);
  final render = PptxRender(archive);
  final presentation = _tryParse(archive, 'ppt/presentation.xml');
  final presRels = _tryParse(archive, 'ppt/_rels/presentation.xml.rels');

  final out = <SlideVM>[];
  for (final name in _orderedSlideFiles(archive, presentation, presRels)) {
    final content = _fileByName(archive, name);
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

XmlDocument? _tryParse(Archive archive, String name) {
  final content = _fileByName(archive, name);
  if (content == null) return null;
  try {
    return XmlDocument.parse(utf8.decode(content, allowMalformed: true));
  } catch (_) {
    return null;
  }
}

List<int>? _fileByName(Archive archive, String name) {
  for (final f in archive.files) {
    if (f.name == name) return f.readBytes();
  }
  return null;
}

int _idx(String name) {
  final m = RegExp(r'slide(\d+)\.xml').firstMatch(name);
  return m == null ? 0 : int.parse(m.group(1)!);
}
