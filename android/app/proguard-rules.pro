# google_mlkit_text_recognition: eklentinin Java tarafı TÜM dillerin
# (Çince/Japonca/Korece/Devanagari) tanıyıcı seçeneklerine başvuruyor ama
# uygulama yalnız LATİN modelini kullanıyor (bkz. ScanOcr) — diğer modellerin
# bağımlılıkları pakete hiç girmiyor. R8 bu başvuruları "missing class" sayıp
# release derlemesini KIRIYORDU (main, 2026-08-06). Sınıflar çalışma anında da
# yüklenmez: eklenti dile göre dallanıyor, biz o dallara hiç girmiyoruz —
# dontwarn güvenli.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
