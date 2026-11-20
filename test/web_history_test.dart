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

/// Kullanıcı isteği 2026-11-20: tarayıcının geri tuşu uygulamanın geri
/// tuşu gibi — önce açık menü/panel, sonra ekran, en son siteden çıkış.
void main() {
  late FakeBrowser browser;
  late HomeFirstHistory history;

  /// Uygulamada kapatılacak şeyler (menü, panel…) — geri önce bunları kapatır.
  late int closables;

  /// Uygulamanın ekran yığını (en üstteki konum bildirilir).
  late List<String> screens;
  late int goHomeCalls;

  /// Uygulamanın yönlendiricisi konumu bildirir.
  void app(String path) => history.report(Uri.parse(path), null);

  void open(String path) {
    screens.add(path);
    app(path);
  }

  HomeFirstHistory make(String initial) {
    browser = FakeBrowser(initial);
    final h = HomeFirstHistory(
      browser,
      onBack: () async {
        if (closables > 0) {
          closables--;
          return true;
        }
        if (screens.length > 1) {
          screens.removeLast();
          app(screens.last);
          return true;
        }
        return false;
      },
      goHome: () {
        goHomeCalls++;
        screens = ['/'];
        app('/');
      },
    );
    browser.onPop = (path) {
      // Olayı geçmiş işlemezse go_router adrese giderdi.
      if (!h.browserNavigated(Uri.parse(path))) app(path);
    };
    return h;
  }

  Future<void> back() async {
    browser.userBack();
    await pumpEventQueue();
  }

  setUp(() {
    closables = 0;
    goHomeCalls = 0;
    screens = ['/'];
    history = make('/');
  });

  test('ana sayfada menü açıkken geri menüyü kapatır, siteden çıkmaz', () async {
    app('/');
    closables = 1;
    await back();
    expect(browser.exited, isFalse);
    expect(closables, 0);
    // Bekçi geri kondu: sonraki geri siteden çıkar.
    await back();
    expect(browser.exited, isTrue);
  });

  test('notta menü açıkken geri önce menüyü, sonra notu kapatır', () async {
    app('/');
    open('/note/a');
    closables = 1;
    await back();
    expect(closables, 0);
    expect(screens.last, '/note/a');
    expect(browser.currentPath(), '/note/a');
    await back();
    expect(screens.last, '/');
    expect(browser.currentPath(), '/');
    expect(browser.exited, isFalse);
    await back();
    expect(browser.exited, isTrue);
  });

  test('çok ekran gezmek geçmişi büyütmez', () async {
    app('/');
    open('/note/a');
    screens.removeLast();
    app('/');
    open('/settings');
    open('/note/c');
    expect(browser.entries.length, 2);
    expect(browser.currentPath(), '/note/c');
  });

  test('site doğrudan bir notla açılırsa ilk geri ana sayfaya gelir', () async {
    screens = ['/note/x'];
    history = make('/note/x');
    app('/note/x');
    await back();
    expect(goHomeCalls, 1);
    expect(browser.currentPath(), '/');
    expect(browser.exited, isFalse);
    await back();
    expect(browser.exited, isTrue);
  });

  test('geri işlenirken gelen ikinci hareket ikinci kez kapatmaz', () async {
    app('/');
    open('/note/a');
    open('/note/b');
    browser.userBack();
    // Bekçi henüz geri konmadı (ileri tuşu ya da hızlı ikinci olay).
    expect(history.browserNavigated(Uri.parse('/note/b')), isTrue);
    await pumpEventQueue();
    expect(screens.last, '/note/a');
    expect(browser.exited, isFalse);
  });

  test('sorgu parametreleri adrese yazılır', () {
    app('/');
    app('/note/a?owner=u1');
    expect(browser.currentPath(), '/note/a?owner=u1');
  });
}
