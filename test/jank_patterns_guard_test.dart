import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// **KASMA KALIPLARI BEKÇİSİ** (HIZ_PLANI F82.2; CLAUDE.md kasma listesi
/// md. 3–4, 6–7). Kaynak taraması: kurulumu sayan bütçe testlerinin (S1–S25)
/// göremediği kalıpları yazıldığı anda yakalar. Her kural saf bir işlevdir;
/// "bozma denemesi" testleri onu kötü örnekle besleyip kırmızı olduğunu sınar.
///
/// Sayılar MANDAL (yalnız DÜŞER): sayı mandaldan büyükse yeni kalıp
/// eklenmiş demektir — kasma listesine bak. Küçükse biri düzeltmiş:
/// mandalı yeni sayıya indir.

/// Editör ve pano kökü: kök durum sınıfı + `on <kök>` uzantıları (parçalar).
const _roots = {
  '_NoteEditorScreenState': 'lib/features/notes/presentation/editor/',
  '_DashboardScreenState': 'lib/features/notes/presentation/',
};

/// md. 3 — kök durumda `setState(` / `_update(` (editörün sarmalayıcısı).
/// 2026-11-12 ölçüldü.
const _rootSetStateLatch = {
  '_NoteEditorScreenState': 53,
  '_DashboardScreenState': 4,
};

/// md. 7 — kabuk/kök dosyalarda `MediaQuery.of(` / `maybeOf(` (klavyenin
/// her karesinde bağımlıyı yeniden kurar; `sizeOf`/`viewInsetsOf` kullan).
/// Kalanlar MediaQuery'yi KOPYALAYIP yeniden veren sarmalayıcılar (bütün
/// veriyi ister). Yeni kabuk/kök dosyası buraya 0 ile eklenir.
const _mediaQueryLatch = {
  'lib/app/app.dart': 1,
  'lib/app/app_frame.dart': 1,
  'lib/app/note_open_route.dart': 2,
  'lib/app/split_shell.dart': 0,
  'lib/app/router.dart': 0,
  '@_NoteEditorScreenState': 0,
  '@_DashboardScreenState': 0,
};

/// md. 6 — editör kökünde `AnimatedSize` / `AnimatedContainer` (gövdeyle aynı
/// Column'da boy animasyonu gövdeyi her karede dizer). Bugünkü 2: ses kaydı
/// hapı (cihazsız kanıt üretilemedi — testte kayıt eklentisi yok; dokunulmadı),
/// sabitleme bırakma şeridi (Stack'te, zararsız). Biçim paneli ↔ alt çubuk
/// takasındaki ikisi P46'da kalktı (2026-11-13; bütçe S9 `govde_boy_karesi`).
const _animatedSizeLatch = 2;

/// md. 6 — ana ekran / takvim şeritlerinde `AnimatedSize(` (P62 plan_tasarim_A
/// §7.5). Bugün 2 (2026-11-14, PA0): bekleyen ek şeridi
/// (`dashboard_widgets.dart` `_PendingUploadsBar`) ve takvim mini ayı
/// (`calendar_screen.dart`); PA6 sonrası 1, PA8 sonrası 0.
const _homeSizeFiles = [
  'lib/features/notes/presentation/dashboard_widgets.dart',
  'lib/features/notes/presentation/dashboard_screen.dart',
  'lib/features/notes/presentation/due_banner.dart',
  'lib/core/app_update.dart',
  'lib/features/notes/presentation/drive_ui.dart',
  'lib/core/widgets/app_banner.dart',
  'lib/core/widgets/app_notice.dart',
  'lib/features/calendar/presentation/calendar_screen.dart',
  'lib/features/calendar/presentation/month_grid.dart',
];
const _homeSizeLatch = 2;

int countAnimatedSize(String src) =>
    RegExp(r'\bAnimatedSize\(').allMatches(src).length;

String _stripComments(String src) => src
    .replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '')
    .split('\n')
    .map((l) {
      final i = l.indexOf('//');
      return i < 0 ? l : l.substring(0, i);
    })
    .join('\n');

final _topLevel = RegExp(
  r'^(?:abstract |final |sealed |base )*(?:class|extension|mixin|enum|typedef)\b',
  multiLine: true,
);

/// [src] içinde [root] sınıfına ya da `on [root]` uzantısına ait gövdeler.
String rootSegments(String src, String root) {
  final starts = [
    for (final m in _topLevel.allMatches(src)) m.start,
    src.length,
  ];
  final out = StringBuffer();
  for (var i = 0; i < starts.length - 1; i++) {
    final seg = src.substring(starts[i], starts[i + 1]);
    final head = seg.split('{').first;
    if (RegExp('\\b(?:class|on) $root\\b').hasMatch(head)) out.writeln(seg);
  }
  return out.toString();
}

int countRootSetState(String segments) =>
    RegExp(r'\b(?:setState|_update)\(').allMatches(segments).length;

int countMediaQueryOf(String src) =>
    RegExp(r'\bMediaQuery\.(?:of|maybeOf)\(').allMatches(src).length;

int countSizeAnimations(String src) =>
    RegExp(r'\b(?:AnimatedSize|AnimatedContainer)\(').allMatches(src).length;

/// md. 4 — `_syncRowCache` env kaydının üst düzey öğelerinden her kurulumda
/// YENİ nesne olanlar (liste/harita/küme değişmezi, kapanış): kayıt eşitliği
/// onları kimlikle karşılaştırır → önbellek her karede boşalır. İçerikten
/// türetilen değer (`Object.hashAll([...])`) serbest.
List<String> freshEnvFields(String src) {
  final fn = src.indexOf('void _syncRowCache(');
  if (fn < 0) return ['_syncRowCache bulunamadı'];
  final open = src.indexOf('final env = (', fn);
  if (open < 0) return ['env kaydı bulunamadı'];
  final fields = <String>[];
  var depth = 0;
  var cur = StringBuffer();
  for (var i = open + 'final env = ('.length; i < src.length; i++) {
    final ch = src[i];
    if ('([{'.contains(ch)) depth++;
    if (')]}'.contains(ch)) {
      if (depth == 0) {
        fields.add(cur.toString());
        break;
      }
      depth--;
    }
    if (ch == ',' && depth == 0) {
      fields.add(cur.toString());
      cur = StringBuffer();
    } else {
      cur.write(ch);
    }
  }
  final fresh = RegExp(
    r'^(?:const\s+)?(?:<[^>]*>\s*)?[\[{]|^\([^)]*\)\s*(?:=>|\{)|^(?:\w+\s*)?\{',
  );
  return [
    for (final f in fields.map((f) => f.trim()))
      if (f.isNotEmpty && fresh.hasMatch(f)) f,
  ];
}

String _read(String p) => _stripComments(File(p).readAsStringSync());

/// [root]'un kütüphanesindeki bütün dosyaların kök parçaları.
String _rootSource(String root) {
  final dir = _roots[root]!;
  return [
    for (final f in Directory(dir).listSync())
      if (f is File && f.path.endsWith('.dart'))
        rootSegments(_read(f.path), root),
  ].join('\n');
}

void main() {
  group('md. 3 — kök setState mandalı', () {
    for (final root in _roots.keys) {
      test(root, () {
        final n = countRootSetState(_rootSource(root));
        // ignore: avoid_print
        print('$root setState/_update: $n');
        expect(
          n,
          lessThanOrEqualTo(_rootSetStateLatch[root]!),
          reason:
              'Kökte yeni setState: yerel UI durumu için alt widget ya da '
              'ValueNotifier + dar ListenableBuilder (kasma listesi md. 3)',
        );
      });
    }
    test('bozma denemesi: kök uzantısındaki yeni setState sayılır', () {
      const src = '''
class _NoteEditorScreenState extends State<X> {
  void a() => setState(() {});
}
class _Other extends State<Y> {
  void b() => setState(() {});
}
extension _E on _NoteEditorScreenState {
  void c() => _update(() {});
}
''';
      expect(countRootSetState(rootSegments(src, '_NoteEditorScreenState')), 2);
    });
  });

  group('md. 4 — satır önbelleği env\'inde her kurulumda yeni nesne yok', () {
    test('items_editor _syncRowCache', () {
      final fresh = freshEnvFields(
        _read('lib/features/notes/presentation/editor/items_editor.dart'),
      );
      expect(fresh, isEmpty, reason: 'env öğesi kimlikle karşılaştırılır');
    });
    test('bozma denemesi: liste, harita, kapanış yakalanır', () {
      String env(String field) =>
          'void _syncRowCache(T t) {\n final env = (\n a,\n $field,\n '
          'Object.hashAll([for (final x in y) x]),\n );\n}';
      expect(freshEnvFields(env('a')), isEmpty);
      expect(freshEnvFields(env('[b, c]')), hasLength(1));
      expect(freshEnvFields(env('const [b]')), hasLength(1));
      expect(freshEnvFields(env('{b: c}')), hasLength(1));
      expect(freshEnvFields(env('<String>{b}')), hasLength(1));
      expect(freshEnvFields(env('() => b')), hasLength(1));
      expect(freshEnvFields(env('(x) { return x; }')), hasLength(1));
    });
  });

  group('md. 7 — kabuk/kökte MediaQuery.of yok', () {
    for (final e in _mediaQueryLatch.entries) {
      test(e.key, () {
        final src = e.key.startsWith('@')
            ? _rootSource(e.key.substring(1))
            : _read(e.key);
        expect(
          countMediaQueryOf(src),
          lessThanOrEqualTo(e.value),
          reason: 'MediaQuery.sizeOf / viewInsetsOf / paddingOf kullan',
        );
      });
    }
    test('bozma denemesi', () {
      expect(countMediaQueryOf('final m = MediaQuery.of(context);'), 1);
      expect(countMediaQueryOf('MediaQuery.maybeOf(c)'), 1);
      expect(countMediaQueryOf('MediaQuery.sizeOf(context)'), 0);
      expect(countMediaQueryOf(_stripComments('// MediaQuery.of(c)')), 0);
    });
  });

  group('md. 6 — editör kökünde boy animasyonu mandalı', () {
    test('_NoteEditorScreenState', () {
      final n = countSizeAnimations(_rootSource('_NoteEditorScreenState'));
      // ignore: avoid_print
      print('editör kökü AnimatedSize/AnimatedContainer: $n');
      expect(
        n,
        lessThanOrEqualTo(_animatedSizeLatch),
        reason:
            'Boy TEK ADIMDA değişsin, hareket yalnız boyamada '
            '(Transform/FractionalTranslation/Opacity) — kasma listesi md. 6',
      );
    });
    test('bozma denemesi', () {
      expect(countSizeAnimations('AnimatedSize(child: x)'), 1);
      expect(countSizeAnimations('AnimatedContainer(height: h)'), 1);
      expect(countSizeAnimations('AnimatedOpacity(opacity: 1)'), 0);
    });
  });

  group('md. 6 — ana ekran / takvim boy animasyonu mandalı', () {
    test('şerit ve takvim dosyaları', () {
      final per = {
        for (final f in _homeSizeFiles) f: countAnimatedSize(_read(f)),
      };
      final n = per.values.fold(0, (a, b) => a + b);
      // ignore: avoid_print
      print('ana ekran / takvim AnimatedSize: $n $per');
      expect(
        n,
        lessThanOrEqualTo(_homeSizeLatch),
        reason:
            'Şerit/mini ay boyu TEK ADIMDA, hareket boyamada '
            '(plan_tasarim_A §6.2 R1/R2) — kasma listesi md. 6',
      );
    });
    test('bozma denemesi', () {
      expect(countAnimatedSize('AnimatedSize(child: x)'), 1);
      expect(countAnimatedSize('AnimatedContainer(height: h)'), 0);
      expect(countAnimatedSize(_stripComments('// AnimatedSize(')), 0);
    });
  });
}
