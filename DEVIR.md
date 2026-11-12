# DEVIR — P48 (dal `oto/P48-web-takvim`)

## Yapılanlar
- (b) takvim: KÖK NEDEN `event_editor.dart` `_toGoogle` varsayılanı — Google Takvim
  bağlantısı CİHAZA özgü (`google_calendar_sync.dart` `_load`, SharedPreferences
  `gcal_cache_<uid>`); bağlı telefonda yeni etkinlik varsayılan Google'a gidiyor,
  Google'ı bağlamamış tablet/web onu hiç çekmiyor. Tablet/web yazdıkları Firestore'a
  gider → telefon görür (asimetri birebir). "Bu cihaz" etiketi de yanlıştı (Firestore
  bütün cihazlarda). Düzeltme: varsayılan her zaman Firestore, etiket "Tüm cihazlar".
  KARAR K2 sapması → sabah bakılacak. Kanıt: `test/calendar_screen_test.dart`
  "Google bağlıyken de yeni etkinlik bütün cihazlara yazılır" kırmızı→yeşil.
- (a) web seçim: KÖK NEDEN `lib/core/utils/sentence_select.dart` genişletici fare/klavye
  seçimini de büyütüyordu (çift tık → cümle, shift+ok 3 harf → kelime). Webde üretildi ve
  düzeltmeden sonra webde yeşil; `test/sentence_select_test.dart` kırmızı→yeşil. Yazı tipi değil.
- (c) web ek: üretilemedi (kullanıcı hesabıyla web oturumu yok). Firestore salt okuma: video
  ekleri hiç yüklenmez (tasarım), Drive'daki önizlemesiz PDF'ler web'de Drive bağlanmadan görünmez.
## Sürüm notu taslağı
- Webde fareyle çift tıklama artık yalnız kelimeyi seçer; shift+ok ile seçim harf harf ilerler.
- Yeni takvim etkinlikleri varsayılan olarak bütün cihazlarında görünür ("Tüm cihazlar");
  Google Takvim'e kaydetmek için düzenleyicide Google'ı seç.
## Cihazda yapılacak
- Telefon: Takvim → Google Takvim bağlı mı? Daha önce eklenen etkinlikler Google'da
  mı (tablet/webde görmek için orada Google Takvim'i bağla ya da etkinliği yeniden kaydet).
- Test: `flutter test test/calendar_screen_test.dart test/sentence_select_test.dart`
