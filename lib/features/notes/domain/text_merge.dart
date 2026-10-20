import 'note_item.dart';

/// **ORTAK NOTTA EŞZAMANLI DÜZENLEME — ÜÇ YÖNLÜ BİRLEŞTİRME** (F4.1).
///
/// Editör notun TAMAMINI yazıyordu: iki kişi (ya da iki cihaz) aynı anda
/// yazınca son yazan öbürünün paragrafını siliyordu. Artık uzaktan gelen
/// değişiklik, yerelde henüz kaydedilmemiş yazıyla SATIR (paragraf)
/// düzeyinde birleştirilir; taban, iki tarafın en son ortak gördüğü hâldir.
///  * Yalnız bir tarafın değiştirdiği bölüm o tarafın hâliyle alınır.
///  * İki taraf AYNI bölümü aynı biçimde değiştirdiyse bir kez yazılır.
///  * İki taraf aynı bölümü FARKLI değiştirdiyse ([TextMerge.conflict])
///    ikisi de tutulur: önce yerel, hemen ardından uzaktaki — kimsenin
///    yazdığı kaybolmaz, kullanıcı fazlasını siler.
class TextMerge {
  const TextMerge(this.text, {this.conflict = false});

  final String text;
  final bool conflict;
}

/// Bu kadar satırı aşan metinde (O(n·m) eşleştirme) yerel kazanır ve
/// uzaktaki değişiklik çakışma olarak sona eklenir.
const _maxLines = 4000;

TextMerge mergeText3(String base, String local, String remote) {
  if (local == remote) return TextMerge(local);
  if (local == base) return TextMerge(remote);
  if (remote == base) return TextMerge(local);
  final b = base.split('\n');
  final l = local.split('\n');
  final r = remote.split('\n');
  if (b.length > _maxLines || l.length > _maxLines || r.length > _maxLines) {
    return TextMerge('$local\n$remote', conflict: true);
  }
  final ml = _lcsMatch(b, l);
  final mr = _lcsMatch(b, r);
  final out = <String>[];
  var conflict = false;
  var ib = 0, il = 0, ir = 0;
  void chunk(int jb, int jl, int jr) {
    final cb = b.sublist(ib, jb);
    final cl = l.sublist(il, jl);
    final cr = r.sublist(ir, jr);
    if (_eq(cl, cb)) {
      out.addAll(cr);
    } else if (_eq(cr, cb) || _eq(cl, cr)) {
      out.addAll(cl);
    } else {
      conflict = true;
      out
        ..addAll(cl)
        ..addAll(cr);
    }
  }

  for (var j = 0; j < b.length; j++) {
    final jl = ml[j];
    final jr = mr[j];
    // Kararlı satır: tabandaki satır iki tarafta da yerinde duruyor.
    if (jl == null || jr == null || jl < il || jr < ir) continue;
    chunk(j, jl, jr);
    out.add(b[j]);
    ib = j + 1;
    il = jl + 1;
    ir = jr + 1;
  }
  chunk(b.length, l.length, r.length);
  return TextMerge(out.join('\n'), conflict: conflict);
}

bool _eq(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// En uzun ortak alt dizi eşleşmesi: taban satırı → öbür taraftaki satır.
Map<int, int> _lcsMatch(List<String> a, List<String> b) {
  final n = a.length, m = b.length;
  final dp = List.generate(n + 1, (_) => List<int>.filled(m + 1, 0));
  for (var i = n - 1; i >= 0; i--) {
    for (var j = m - 1; j >= 0; j--) {
      dp[i][j] = a[i] == b[j]
          ? dp[i + 1][j + 1] + 1
          : (dp[i + 1][j] >= dp[i][j + 1] ? dp[i + 1][j] : dp[i][j + 1]);
    }
  }
  final match = <int, int>{};
  var i = 0, j = 0;
  while (i < n && j < m) {
    if (a[i] == b[j]) {
      match[i++] = j++;
    } else if (dp[i + 1][j] >= dp[i][j + 1]) {
      i++;
    } else {
      j++;
    }
  }
  return match;
}

/// Liste maddeleri: KİMLİKLE üç yönlü birleştirme. Yerel sıra esastır;
/// uzakta eklenenler sona eklenir, uzakta silinenler (yerelde
/// değiştirilmediyse) silinir, iki tarafta değişen madde için yerel kazanır
/// (madde tek satır — çakışmada ikisini birden yazmak listeyi bozar).
List<NoteItem> mergeItems3(
  List<NoteItem> base,
  List<NoteItem> local,
  List<NoteItem> remote,
) {
  final baseById = {for (final i in base) i.id: i};
  final remoteById = {for (final i in remote) i.id: i};
  final localIds = {for (final i in local) i.id};
  final out = <NoteItem>[];
  for (final item in local) {
    final b = baseById[item.id];
    final r = remoteById[item.id];
    final localChanged = b == null || !_sameItem(b, item);
    if (r == null) {
      // Uzakta silindi: yerelde de dokunulmadıysa sil; yerel yeni ya da
      // değişmişse kalır.
      if (b != null && !localChanged) continue;
      out.add(item);
    } else if (!localChanged) {
      out.add(r);
    } else {
      out.add(item);
    }
  }
  for (final r in remote) {
    if (!localIds.contains(r.id) && !baseById.containsKey(r.id)) out.add(r);
  }
  return out;
}

/// Madde listeleri içerikçe aynı mı (NoteItem `==` tanımlamaz).
bool sameItems(List<NoteItem> a, List<NoteItem> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i].id != b[i].id || !_sameItem(a[i], b[i])) return false;
  }
  return true;
}

bool _sameItem(NoteItem a, NoteItem b) =>
    a.text == b.text &&
    a.checked == b.checked &&
    a.title == b.title &&
    a.divider == b.divider;
