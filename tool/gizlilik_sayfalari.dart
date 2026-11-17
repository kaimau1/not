// GİZLİLİK METNİ TEK KAYNAK (PLAN §1.5 PL4, 16K rapor E5/E6).
//
// `PRIVACY_POLICY.md` (uygulama içindeki Gizlilik ekranı bu dosyayı okur)
// tek kaynaktır; web'deki iki herkese açık sayfa ondan ÜRETİLİR:
//   web/gizlilik.html    — politikanın tamamı (Play + OAuth incelemesi adresi)
//   web/hesap-silme.html — Play'in "web'den hesap silme" adresi: adımlar +
//                          politikanın "Veri saklama ve silme" bölümü +
//                          uygulamadaki silme akışına götüren düğme
// Metni değiştirince: `dart run tool/gizlilik_sayfalari.dart`.
// Bekçi: `test/gizlilik_tek_kaynak_test.dart` (üretilen ≠ dosya → kırmızı).
//
// Dönüştürücü bilerek küçük: yalnız bu dosyanın kullandığı Markdown
// (#/## başlık, paragraf, `1.` ve `-` liste, 3 boşluk girintili iç liste).
import 'dart:io';

/// Web'deki silme rotası (uygulama, hash adresleri). Oturum yoksa giriş
/// ekranı açılır, girişten sonra buraya döner (bkz. router `/delete-account`).
const deleteAccountAppPath = '/#/delete-account';

const _deletionSection = 'Veri saklama ve silme';
const _contactSection = 'İletişim';

void main() {
  final md = File('PRIVACY_POLICY.md').readAsStringSync();
  File('web/gizlilik.html').writeAsStringSync(privacyHtml(md));
  File('web/hesap-silme.html').writeAsStringSync(deletionHtml(md));
  stdout.writeln('web/gizlilik.html + web/hesap-silme.html üretildi');
}

String privacyHtml(String md) {
  final doc = _parse(md);
  return _page(
    title: doc.title,
    body: StringBuffer()
      ..writeln('<h1>${_esc(doc.title)}</h1>')
      ..write(doc.blocks.map((b) => b.html).join()),
  );
}

String deletionHtml(String md) {
  final doc = _parse(md);
  final appName = doc.title.split(' — ').first;
  final title = '$appName — Hesap ve veri silme';
  final body = StringBuffer()
    ..writeln('<h1>${_esc(title)}</h1>')
    ..writeln(
      '<p>Bu sayfa, $appName uygulamasındaki hesabınızı ve bütün '
      'verilerinizi nasıl sileceğinizi anlatır. Uygulamanın cihazınızda '
      'kurulu olması gerekmez.</p>',
    )
    ..writeln('<h2>Nasıl silinir</h2>')
    ..writeln('<ol>')
    ..writeln(
      '<li>Aşağıdaki düğmeyle web uygulamasını açın ve hesabınızla '
      '(Google) giriş yapın.</li>',
    )
    ..writeln(
      '<li>Açılan "Hesabımı ve verilerimi sil" sayfasında ne silineceğini '
      'okuyun, "Kalıcı olarak sil" ile onaylayın.</li>',
    )
    ..writeln(
      '<li>Android uygulamasında aynı işlem: Ayarlar → Hesap → '
      '"Hesabımı ve verilerimi sil".</li>',
    )
    ..writeln('</ol>')
    ..writeln(
      '<p><a class="btn" href="$deleteAccountAppPath">Giriş yap ve hesabımı '
      'sil</a></p>',
    );
  for (final name in [_deletionSection, _contactSection]) {
    final i = doc.blocks.indexWhere((b) => b.heading == name);
    if (i < 0) throw StateError('PRIVACY_POLICY.md: "## $name" bölümü yok');
    var j = i + 1;
    while (j < doc.blocks.length && doc.blocks[j].heading == null) {
      j++;
    }
    body.write(doc.blocks.sublist(i, j).map((b) => b.html).join());
  }
  body.writeln(
    '<p>Politikanın tamamı: <a href="gizlilik.html">Gizlilik '
    'Politikası</a>.</p>',
  );
  return _page(title: title, body: body);
}

// ---------------------------------------------------------------------------

class _Doc {
  _Doc(this.title, this.blocks);
  final String title;
  final List<_Block> blocks;
}

class _Block {
  _Block(this.html, {this.heading});
  final String html;
  final String? heading;
}

class _Item {
  final lines = <String>[];
  final sub = <List<String>>[];
  final after = <String>[];
}

_Doc _parse(String md) {
  final lines = md.replaceAll('\r\n', '\n').split('\n');
  var title = '';
  final blocks = <_Block>[];
  var i = 0;
  while (i < lines.length) {
    final line = lines[i];
    if (line.trim().isEmpty) {
      i++;
      continue;
    }
    if (line.startsWith('# ')) {
      title = line.substring(2).trim();
      i++;
      continue;
    }
    if (line.startsWith('## ')) {
      final h = line.substring(3).trim();
      blocks.add(_Block('<h2>${_inline(h)}</h2>\n', heading: h));
      i++;
      continue;
    }
    final ordered = RegExp(r'^\d+\. ').hasMatch(line);
    if (ordered || line.startsWith('- ')) {
      final items = <_Item>[];
      while (i < lines.length && lines[i].trim().isNotEmpty) {
        final l = lines[i];
        final m = RegExp(r'^(\d+\. |- )').firstMatch(l);
        if (m != null) {
          items.add(_Item()..lines.add(l.substring(m.end)));
        } else if (l.startsWith('   - ')) {
          items.last.sub.add([l.substring(5)]);
        } else if (l.startsWith('     ') && items.last.sub.isNotEmpty) {
          items.last.sub.last.add(l.trim());
        } else if (items.last.sub.isNotEmpty) {
          items.last.after.add(l.trim());
        } else {
          items.last.lines.add(l.trim());
        }
        i++;
      }
      final tag = ordered ? 'ol' : 'ul';
      // Boş satırla ayrılmış `2.`, `3.` maddeleri ayrı blok olur;
      // numara kaybolmasın diye liste kendi numarasından başlar.
      final start = ordered ? int.parse(line.split('.').first) : 1;
      final b = StringBuffer(start > 1 ? '<ol start="$start">\n' : '<$tag>\n');
      for (final it in items) {
        b.write('<li>${_inline(it.lines.join(' '))}');
        if (it.sub.isNotEmpty) {
          b.write('\n<ul>\n');
          for (final s in it.sub) {
            b.write('<li>${_inline(s.join(' '))}</li>\n');
          }
          b.write('</ul>\n');
        }
        if (it.after.isNotEmpty) {
          b.write('<p>${_inline(it.after.join(' '))}</p>');
        }
        b.write('</li>\n');
      }
      b.write('</$tag>\n');
      blocks.add(_Block(b.toString()));
      continue;
    }
    final para = <String>[];
    while (i < lines.length &&
        lines[i].trim().isNotEmpty &&
        !lines[i].startsWith('#')) {
      para.add(lines[i].trim());
      i++;
    }
    blocks.add(_Block('<p>${_inline(para.join(' '))}</p>\n'));
  }
  return _Doc(title, blocks);
}

String _esc(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

String _inline(String s) => _esc(s)
    .replaceAllMapped(
      RegExp(r'https?://[^\s<)]+[^\s<).,]'),
      (m) => '<a href="${m[0]}">${m[0]}</a>',
    )
    .replaceAllMapped(
      RegExp(r'(?<![\w.])[\w.+-]+@[\w-]+\.[\w.]+[\w]'),
      (m) => '<a href="mailto:${m[0]}">${m[0]}</a>',
    );

String _page({required String title, required StringBuffer body}) =>
    '''<!doctype html>
<!-- ÜRETİLDİ: PRIVACY_POLICY.md → dart run tool/gizlilik_sayfalari.dart. ELLE DÜZENLEME. -->
<html lang="tr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${_esc(title)}</title>
<style>
  body { font: 16px/1.6 system-ui, sans-serif; max-width: 720px; margin: 0 auto; padding: 24px 16px; color: #222; background: #fff; }
  h1 { font-size: 1.6em; } h2 { font-size: 1.15em; margin-top: 1.6em; }
  a { color: #1a56c4; overflow-wrap: anywhere; }
  .btn { display: inline-block; padding: 10px 18px; border-radius: 8px; background: #b3261e; color: #fff; text-decoration: none; font-weight: 600; }
  @media (prefers-color-scheme: dark) { body { color: #e6e6e6; background: #161616; } a { color: #9ab8ff; } .btn { background: #f2b8b5; color: #601410; } }
</style>
</head>
<body>
$body</body>
</html>
''';
