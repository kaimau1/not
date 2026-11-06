import 'friend.dart';

/// Kişiler ekranı (baştan, 2026-11-06) için saf yardımcılar — testli.

/// Görünen ad: ad boşsa e-posta.
String friendLabel(String name, String email) =>
    name.trim().isEmpty ? email.trim() : name.trim();

/// Türkçe sıralama/baş harf için küçük harf (İ/I ayrımı).
String _trLower(String s) =>
    s.replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase();

String _trUpper(String c) => switch (c) {
  'i' => 'İ',
  'ı' => 'I',
  _ => c.toUpperCase(),
};

/// Avatar / küme harfi: ilk harf ya da rakam; yoksa '#'.
String personInitial(String label) {
  for (final r in label.trim().runes) {
    final c = String.fromCharCode(r);
    if (RegExp(r'[\p{L}]', unicode: true).hasMatch(c)) {
      return _trUpper(c);
    }
    if (RegExp(r'\d').hasMatch(c)) return '#';
  }
  return '#';
}

/// Türkçe alfabe sırası (ç, ğ, ı, ö, ş, ü doğru yerde).
const _alphabet = 'abcçdefgğhıijklmnoöprsştuüvyzqwx';

int _charRank(String c) {
  final i = _alphabet.indexOf(c);
  return i < 0 ? 1000 + c.codeUnitAt(0) : i;
}

int compareTr(String a, String b) {
  final x = _trLower(a), y = _trLower(b);
  final n = x.length < y.length ? x.length : y.length;
  for (var i = 0; i < n; i++) {
    final d = _charRank(x[i]) - _charRank(y[i]);
    if (d != 0) return d;
  }
  return x.length - y.length;
}

/// Ad / e-postada arama (büyük-küçük harf ve Türkçe İ/ı duyarsız).
List<Friend> filterFriends(List<Friend> friends, String query) {
  final q = _trLower(query.trim());
  if (q.isEmpty) return friends;
  return [
    for (final f in friends)
      if (_trLower(f.name).contains(q) || _trLower(f.email).contains(q)) f,
  ];
}

/// Alfabetik, baş harfe göre kümelenmiş liste.
List<({String letter, List<Friend> people})> groupFriends(
  List<Friend> friends,
) {
  final sorted = [...friends]
    ..sort(
      (a, b) =>
          compareTr(friendLabel(a.name, a.email), friendLabel(b.name, b.email)),
    );
  final out = <({String letter, List<Friend> people})>[];
  for (final f in sorted) {
    final l = personInitial(friendLabel(f.name, f.email));
    if (out.isEmpty || out.last.letter != l) {
      out.add((letter: l, people: [f]));
    } else {
      out.last.people.add(f);
    }
  }
  return out;
}

/// Arama kutusuna yazılan tam bir e-posta mı (doğrudan istek seçeneği).
bool looksLikeEmail(String s) =>
    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$').hasMatch(s.trim());
