import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/app/web_history.dart';

/// Tarayıcı geçmişini taklit eder: kayıt listesi + imleç. `back()`
/// tarayıcıdaki gibi imleci bir geri alır ve uygulamaya "adres değişti"
/// haberini ([onPop]) verir.
class FakeBrowser implements HistoryDriver {
  FakeBrowser(String initial) : entries = [initial];

  final List<String> entries;
  int index = 0;
  bool exited = false;
  void Function(String path)? onPop;

  @override
  String? currentPath() => entries[index];

  @override
  void update(Uri uri, Object? state, {required bool replace}) {
    final path = uri.toString();
    if (replace) {
      entries[index] = path;
    } else {
      entries
        ..removeRange(index + 1, entries.length)
        ..add(path);
      index++;
    }
  }

  @override
  void back() => userBack();

  /// Tarayıcının geri düğmesi.
  void userBack() {
    if (index == 0) {
      exited = true;
      return;
    }
    index--;
    onPop?.call(entries[index]);
  }
}

/// Kullanıcı isteği 2026-09-26: "sitede geri ana sayfaya dönmeli, 2. geri
/// siteden çıkmalı".
void main() {
  late FakeBrowser browser;
  late HomeFirstHistory history;

  /// Uygulamanın yönlendiricisi: tarayıcı geri gidince go_router o adrese
  /// gider ve konumu yeniden bildirir.
  void app(String path) => history.report(Uri.parse(path), null);

  setUp(() {
    browser = FakeBrowser('/');
    history = HomeFirstHistory(browser);
    browser.onPop = app;
  });

  test('çok ekran gezdikten sonra: geri → ana sayfa, geri → çıkış', () {
    app('/');
    app('/note/a');
    app('/note/b');
    app('/settings');
    app('/note/c');
    expect(browser.entries, ['/', '/note/c']);

    browser.userBack();
    expect(browser.currentPath(), '/');
    expect(browser.exited, isFalse);

    browser.userBack();
    expect(browser.exited, isTrue);
  });

  test('uygulama içinden ana sayfaya dönüş üstteki kaydı düşürür', () {
    app('/');
    app('/note/a');
    // Editördeki geri oku: yönlendirici '/'a döner.
    app('/');
    expect(browser.currentPath(), '/');
    expect(browser.index, 0);
    // Tek geri siteden çıkarır — ikinci bir "boş" geri yok.
    browser.userBack();
    expect(browser.exited, isTrue);
  });

  test('site doğrudan bir notla açılırsa altına ana sayfa eklenir', () {
    browser = FakeBrowser('/note/x');
    history = HomeFirstHistory(browser);
    browser.onPop = app;
    app('/note/x');
    expect(browser.entries, ['/', '/note/x']);
    browser.userBack();
    expect(browser.currentPath(), '/');
    browser.userBack();
    expect(browser.exited, isTrue);
  });

  test('ana sayfaya geri dönüp yeniden not açmak geçmişi büyütmez', () {
    app('/');
    app('/note/a');
    browser.userBack();
    app('/note/b');
    expect(browser.entries, ['/', '/note/b']);
    browser.userBack();
    browser.userBack();
    expect(browser.exited, isTrue);
  });

  test('sorgu parametreleri adrese yazılır', () {
    app('/');
    app('/note/a?owner=u1');
    expect(browser.currentPath(), '/note/a?owner=u1');
  });
}
