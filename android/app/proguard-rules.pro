# R8 KÜÇÜLTME KURALLARI
#
# minifyEnabled + shrinkResources 2026-08-16'da AÇILDI (APK boyutu isteği).
# Buradaki her kural, küçültmenin çalışma anında bir şeyi kırdığı ya da
# kıracağı için var. Kural silmeden önce release APK'yı CİHAZDA denemek şart:
# R8 hatası derlemede değil, o kod yolu ilk kez çalıştığında patlar.

# --- ML Kit: kullanılmayan dil modelleri --------------------------------
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

# --- Flutter motoru -----------------------------------------------------
# Eklenti kaydı (GeneratedPluginRegistrant) ve platform kanalları JNI ile,
# yani Java tarafından GÖRÜNMEYEN çağrılarla kurulur; R8 bunları "kullanılmıyor"
# sanıp atarsa uygulama açılışta boş ekranda kalır.
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# --- Ertelenmiş bileşenler (Play Core) ----------------------------------
# Flutter'ın deferred-components desteği Play Core sınıflarına başvurur;
# uygulama bu özelliği KULLANMIYOR ve kitaplık pakete girmiyor.
-dontwarn com.google.android.play.core.**

# --- flutter_local_notifications: Gson ile serileştirme -----------------
# Zamanlanmış hatırlatıcılar cihazda JSON olarak saklanıyor ve Gson bunları
# YANSIMA ile okuyor. Alan adları karıştırılırsa (obfuscation) yeniden
# başlatmadan sonra hatırlatıcılar sessizce kaybolur — bilinen ve sık
# rastlanan bir R8 tuzağı.
-keep class com.dexterous.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}
-keep class * extends com.google.gson.TypeAdapter
-dontwarn com.google.gson.**

# --- home_widget: sağlayıcılar ADA GÖRE bulunuyor -----------------------
# Dart tarafı widget'ı `HomeWidget.updateWidget(name: 'NotlarWidgetProvider')`
# ile güncelliyor; sınıf adı METİN olarak taşındığı için yeniden adlandırılırsa
# ana ekran widget'ları güncellenmez. Manifest'teki alıcılar zaten korunur ama
# kural burada AÇIKÇA duruyor ki widget eklenince unutulmasın.
-keep class dev.kaimau.notlar.** { *; }

# --- Firebase / Google Play Services ------------------------------------
# Firestore'un model dönüşümü ve App Check'in sağlayıcı seçimi yansıma
# kullanıyor. Kitaplıklar kendi consumer kurallarını getiriyor; buradakiler
# yalnız uyarı gürültüsünü kesiyor.
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# --- javax / annotation uyarıları ---------------------------------------
# Derleme zamanı açıklamaları (Error Prone, JSR-305) çalışma anında yok.
-dontwarn javax.annotation.**
-dontwarn javax.lang.model.**
-dontwarn org.checkerframework.**
-dontwarn com.google.errorprone.annotations.**
