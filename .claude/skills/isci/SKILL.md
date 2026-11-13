---
name: isci
description: Gözetimsiz zincirde paket işleyen alt ajanın (işçi) kuralları — dal, DEVIR.md, kanıt→düzelt→kanıt, doğrulama, dokunulmayacaklar, bitiş ve rapor. Kuyruk paketi verilen her alt ajan önce bunu uygular.
---

# İşçi kuralları

OTOMASYON.md "İşçi kuralları" + KUYRUK_AYRINTI.md protokolleri + CLAUDE.md gece kuralı buraya
taşındı (2026-11-14), AYNEN. Kullanıcı izni (2026-11-09): işi bitir, token israf etme ama bitmiş
iş ver. Yürütücü ince kalır (kullanıcı kararı 2026-11-12: "alt ajanlar daha çok işi
yapabilir") — CI izleme, kırmızı CI düzeltme, DEVIR, plan `[x]`, Kuyruk satırı ve sürüm notu
taslağı İŞÇİNİN işidir.

## Başlangıç

- Depo: Flutter not uygulaması, `C:\Users\sena\Desktop\not`. Önce `CLAUDE.md`, sonra
  `OTURTMA_PLANI.md`'de (hız paketleri: `HIZ_PLANI.md`; görünüş: `DENEYIM_PLANI.md`) ve
  `KUYRUK_AYRINTI.md`'de paketin maddeleri. `HAFIZA.md`'yi BAŞTAN SONA OKUMA: konunu `Grep` ile
  ara. Dal yarımsa ÖNCE dalın `DEVIR.md`'sini oku, baştan keşfetme.
- Dal: `oto/<no>-<kısa-ad>`. Yeni çalışma ağacında önce `flutter pub get`; Flutter yolu
  `C:/src/flutter/bin/flutter.bat` (PATH'te değil; "command not found" SDK yok demek değil).
- Küçük adımlarla commit + **her commit'ten sonra push** (limit oturumu her an kesebilir; yarım
  iş dalda kalsın). **main'e push YOK.**

## DEVIR.md (devir notu)

Dalın kökünde, HER push'tan önce güncel, en çok 25 satır: yapılanlar (madde + commit) · şu anki
adım · kök neden/kanıt (dosya:satır) · işe yaramayanlar · sıradaki adım · test/ölçüm komutu.
Ölçüm ham sayıları buraya (sohbette kalmaz). Yürütücü birleştirmeden önce daldan SİLER.

## Yöntem

- **Protokol (a)–(e): önce kanıtı üret → düzelt → aynı kanıt yeşil.** Kanıt üretilemiyorsa
  düzeltme yazma: maddeye "üretilemedi: <ne denendi>" yaz, bitir.
- Kök neden, yama değil (kullanıcı 2026-11-09: "basite kaçma, artık yoruldum hata düzeltmekten").
- **Hız hissi işi** (kullanıcı 2026-11-12): kötüleşme yok; her değişiklik ölçülebilir iyileşir
  (önce/sonra DEVIR'e); kanıtsız değişiklik yapılmaz. Her madde AYRI commit (geri alınabilsin).
- Dokunduğun yüzeyin cihazsız bütçe senaryosu `test/perf_budget_test.dart`'ta yoksa yaz
  (HIZ SÖZLEŞMESİ, ayrıntı `ab-olcum`). Editör/ızgaraya görünür alan/kip/sarmalayıcı → push'tan
  önce `kasma-kontrol` skill'i.
- Görünüş/yer değiştirmeden önce `python tool/design/istek_tara.py <dosya>`; çelişen iş yapılmaz.
  DENEYIM paketlerinde (P33–P42) K-D kararları VERİLMİŞTİR, kapsam çiti plan Ek D.
- **KARAR** çıkarsa (KARAR (kullanıcı, 2026-11-03)): plandaki **"En güvenli"** seçenek + maddeye
  "sabah bakılacak". Kullanıcıya soru sorma. Madde kapsamı dışına çıkma, yeni özellik ekleme.
- **Dokunma:** `config/app` bayrakları (`inkV2Write`, `minClient`), veri silen/taşıyan göç,
  erişimi GEVŞETEN kural, imza anahtarı, kişisel dosyalar, telefondaki varsayılan kimlikli
  uygulama (`flutter run/drive` varsayılan kimlikle ASLA — veri gider; ölçüm uygulaması
  `dev.kaimau.notlar.olcum`).
- Veri göçü / kayıt sıfırlama (F22.4, F28.2): önce yerel tam yedek, göç geri alınabilir, kural
  testleri (`rules-test`) yeşil.
- Telefon: yalnız işin gerektirdiği an, tek seferde bir iş; kurallar `ab-olcum` skill'inde.
  Telefon gerektiren ölçüm yapılamazsa "yazıldı, cihazda doğrulanmadı" + `KALANLAR.md` §2'ye adım.
  Misafir hesap: Google/Drive/Gmail "denenmedi".

## Doğrulama (DOĞRULAMA = CI, kullanıcı kararı 2026-11-05)

- Değişenin testi `flutter test test/<ilgili>_test.dart --reporter failures-only`; push'tan önce
  tam `flutter analyze` (CI info düzeyini de hata sayar). Tam test takımını yerelde KOŞMA.
- `dart format lib` YOK (yalnız kendi eklediğin dosya).
- Arka planda başlattığın her komut (`flutter`, `gh run watch`, `adb`, betik) `timeout` ile
  (ör. `timeout 2700 gh run watch <id> --exit-status`); raporu yazmadan önce hepsini bitir/öldür.
- **CI izleme işçinin:** push sonrası `gh run list -b <dal> -L 1`; kırmızıysa YALNIZ başarısız
  işin kayıt kuyruğunu oku, düzelt, push — en çok 2 tur, sonra `takıldı`. CI yeşil olmadan
  "bitti" denmez.

## Bitiş (dalda, birleştirmeden önce hazır olmalı)

- Kuyruk satırı (`OTOMASYON.md`) `bitti` + tek satır sonuç (yalnız KENDİ satırın; SIRA satırına
  dokunma); plan maddesi `[x]` + tarih + sonuç; `docs/regresyon_listesi.md` satırı; HAFIZA ilgili
  `docs/hafiza/*.md` (kök neden / kalıcı karar / yanlış yol varsa); APK = evet ise sürüm notu
  taslağı `assets/guide/release_notes_tr.md` + `_en.md` (kullanıcı diliyle, iki dosyada aynı
  tarih kimliği).
- Yarıda kalırsan: Kuyruk satırı `sürüyor — dal <ad> (<commit>): bitti <x>, kalan <y>; DEVIR.md'den
  sür`, `git log origin/<dal>..HEAD` boş.
- **Rapor ≤ 15 satır:** ne değişti (dosyalar), hangi test/ölçüm kırmızıdan yeşile döndü,
  doğrulanamayan ne kaldı, dal adı ve son commit.
