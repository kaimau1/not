# DEVIR — P59 (oto/P59-web-kalem-gecis)

Kullanıcı 2026-11-14, dört madde — hepsi dalda yazıldı, cihazda doğrulanmadı (KALANLAR L14):
1. Web seçim görünümü — KÖK: gizli DOM metin alanının yerel seçimi, genel `::selection !important`
   (eklenti) motorun !important'sız kuralını eziyordu. `web/index.html` koruma kuralı + `web_selection_css_test`.
   Kanıt: gerçek NoteEditorScreen'li oturumsuz web düzeneği (Chrome 157) + enjekte kural → belirti birebir; düzeltmeyle yok.
2. Silgiden kaleme — silgide basılı tut = "Kaleme dön" (`ink_eraser_offer_test`); öneriler tek dinleyici (S18 876).
3. Geniş düzende dönüş — KÖK: sağ bölme rota değişince 0 genişlik, çıkış geçişi görünmüyordu.
   `SplitShell._closing` 300 ms; `fullscreen_pull_test` + bütçe S26 (1/14, önce de 1/14).
4. Mini pano — `paneCardScaleProvider` (`pane_card_scale`), sütun genişlik/(220×ölçek) 1–4 (`grid_columns_test`).

CI yeşil (83aabd80). Kalan: [apk] öncesi cihazda A/B (kapanış evresi, editör); web'de gerçek tarayıcıda eklentiyle bak.
Belgeler: OTOMASYON P59, sürüm notu 14 Kasım, regresyon P59, hafıza web/arayuz/kalem.
