import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants.dart';
import '../../core/crash_reporting.dart';
import '../../core/utils/language_names.dart';
import '../../core/utils/note_fonts.dart';
import '../../l10n/generated/app_localizations.dart';

/// main() içinde gerçek örnekle override edilir.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('main() içinde override edilmeli'),
);

/// Tercihlerin dışarıdan (ayar senkronu, F4.5) değiştiğini bildiren sayaç:
/// tercih sağlayıcıları [watchPrefs] ile buna da abonedir, artınca
/// SharedPreferences'tan yeniden okunur.
final prefsRevisionProvider = NotifierProvider<PrefsRevision, int>(
  PrefsRevision.new,
);

class PrefsRevision extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

/// Tercih sağlayıcılarının `build`'inde kullanılır (bkz. [prefsRevisionProvider]).
SharedPreferences watchPrefs(Ref ref) {
  ref.watch(prefsRevisionProvider);
  return ref.watch(sharedPreferencesProvider);
}

/// Açık/kapalı cihaz tercihi: SharedPreferences'ta [key] anahtarıyla
/// saklanır (anahtar adları eski sınıflarla AYNI — tercih kaybolmaz).
class BoolPrefNotifier extends Notifier<bool> {
  BoolPrefNotifier(this.key, this.defaultValue);

  final String key;
  final bool defaultValue;

  @override
  bool build() =>
      watchPrefs(ref).getBool(key) ?? defaultValue;

  void set(bool value) {
    state = value;
    ref.read(sharedPreferencesProvider).setBool(key, value);
  }

  void toggle() => set(!state);
}

NotifierProvider<BoolPrefNotifier, bool> boolPref(
  String key, {
  required bool defaultValue,
}) => NotifierProvider<BoolPrefNotifier, bool>(
  () => BoolPrefNotifier(key, defaultValue),
);

/// Tema seçimi: sistem/açık/koyu artı "kağıt" (hafif saman kağıdı renkli
/// açık tema). ThemeMode'da karşılığı olmadığından kendi enum'ımız var;
/// aynı prefs anahtarını kullandığı için eski kayıtlar geriye uyumludur.
///
/// VARSAYILAN kağıt: i1 simge çalışmasıyla marka kağıt paletine geçti
/// (simge, uygulama ve ana ekran widget'ları aynı palet). Ayarı hiç
/// ellememiş kullanıcı güncellemede kağıda geçer; kayıtlı seçimi olan
/// kendi temasında kalır — bunu bozmamak için orElse dışına dokunulmadı.
enum AppThemeChoice { system, light, dark, paper }

final themeChoiceProvider =
    NotifierProvider<ThemeChoiceNotifier, AppThemeChoice>(
      ThemeChoiceNotifier.new,
    );

class ThemeChoiceNotifier extends Notifier<AppThemeChoice> {
  static const _key = 'theme_mode';

  @override
  AppThemeChoice build() {
    final stored = watchPrefs(ref).getString(_key);
    return AppThemeChoice.values.firstWhere(
      (m) => m.name == stored,
      orElse: () => AppThemeChoice.paper,
    );
  }

  void set(AppThemeChoice choice) {
    state = choice;
    ref.read(sharedPreferencesProvider).setString(_key, choice.name);
  }
}

/// Uygulama dili. null = sistem dili (varsayılan).
///
/// Dil adları bilerek yerelleştirilmez: "English" satırını İngilizce'ye
/// geçmek isteyen bir kullanıcı okuyabilmeli, kendi dilinde yazılırsa
/// bulamaz. Yalnız "Sistem dili" satırı çevrilir.
///
/// KÖK NEDEN (elle tutulan liste): burası eskiden elle yazılmış dört
/// girdilik sabit bir haritaydı ve `.arb` dosyalarıyla senkron kalması
/// kullanıcıya bırakılmıştı — dil eklenip buraya yazılmayınca seçenek hiç
/// görünmüyor, tersi olunca çevirisi olmayan bir dil seçilebiliyordu.
/// Liste artık TEK KAYNAKtan, üretilen çevirilerden türetiliyor: yeni bir
/// `app_xx.arb` eklemek dili seçilebilir yapmaya yeter, ikinci bir yeri
/// güncellemek gerekmez. Ad kataloğu ayrıdır (bkz. language_names.dart) ve
/// desteklenen kümeyi BELİRLEMEZ, yalnız adlandırır.
Map<String, String> get supportedLanguages => {
  for (final locale in AppLocalizations.supportedLocales)
    locale.toLanguageTag(): languageLabel(locale.toLanguageTag()),
};

final localeProvider = NotifierProvider<LocaleNotifier, Locale?>(
  LocaleNotifier.new,
);

class LocaleNotifier extends Notifier<Locale?> {
  static const _key = 'app_locale';

  @override
  Locale? build() {
    final code = watchPrefs(ref).getString(_key);
    // Çevirisi ARTIK üretilmeyen bir dil kayıtlıysa (dil listeden çıkarıldı)
    // sistem diline düşülür; aksi hâlde uygulama yüklenemeyen bir yerel
    // ayarla açılmaya çalışırdı.
    if (code == null || !supportedLanguages.containsKey(code)) return null;
    return _parse(code);
  }

  /// 'pt-BR' gibi bölgeli etiketleri doğru [Locale]'e çevirir. Düz
  /// `Locale('pt-BR')` dil kodunu 'pt-BR' sanır ve hiçbir çeviriyle eşleşmez.
  static Locale _parse(String tag) {
    final parts = tag.split(RegExp('[-_]'));
    return parts.length > 1
        ? Locale(parts.first, parts[1])
        : Locale(parts.first);
  }

  /// [code] null ise sistem diline dönülür.
  void set(String? code) {
    state = code == null ? null : _parse(code);
    final prefs = ref.read(sharedPreferencesProvider);
    if (code == null) {
      prefs.remove(_key);
    } else {
      prefs.setString(_key, code);
    }
  }
}

/// Yazı boyutu kademeleri: Küçük · Orta · Büyük · Çok büyük.
///
/// KARAR (kullanıcı, 2026-08-07: "yazı boyutu ekmolarak küçük orta büyük çok
/// büyük seçeneklerinde olsun"): eskiden 0.85–1.4 arası sürekli bir kaydırıcı
/// vardı ve "%107" gibi değerler seçilebiliyordu — ne anlamı olan ne de
/// hatırlanabilen bir sayı. Dört kademe hem tek dokunuşla seçiliyor hem de
/// her cihazda AYNI dört görünümü veriyor.
///
/// Değerler eski aralığın içinde kalıyor: kaydırıcıdan gelen kayıtlı bir
/// değer en yakın kademeye oturur ([nearestFontScaleStep]), kimse
/// güncellemede boyut değişimi yaşamaz.
enum FontScaleStep {
  small(0.85),
  medium(1),
  large(1.15),
  xlarge(1.35);

  const FontScaleStep(this.scale);

  final double scale;
}

/// [value]'ya en yakın kademe. Eski (kaydırıcı dönemi) değerler ve elle
/// bozulmuş kayıtlar için tek giriş noktası.
FontScaleStep nearestFontScaleStep(double value) {
  var best = FontScaleStep.medium;
  for (final step in FontScaleStep.values) {
    if ((step.scale - value).abs() < (best.scale - value).abs()) best = step;
  }
  return best;
}

/// Sistem yazı ölçeğine en yakın kademe (ilk açılışın başlangıç değeri).
double initialFontScale(double system) => nearestFontScaleStep(system).scale;

/// Yazı boyutu çarpanı. Sistem ayarının YERİNE geçer (bkz. `fixedTypography`).
final fontScaleProvider = NotifierProvider<FontScaleNotifier, double>(
  FontScaleNotifier.new,
);

class FontScaleNotifier extends Notifier<double> {
  static const _key = 'font_scale';

  @override
  double build() {
    final prefs = watchPrefs(ref);
    final stored = prefs.getDouble(_key);
    if (stored != null) return stored;
    // İLK AÇILIŞ (F4.7): sistemin yazı ölçeğinden başlanır (en yakın
    // kademe) ve kaydedilir; bundan sonra uygulama ayarı tek söz sahibi.
    final initial = initialFontScale(
      WidgetsBinding.instance.platformDispatcher.textScaleFactor,
    );
    prefs.setDouble(_key, initial);
    return initial;
  }

  void set(double value) {
    state = value;
    ref.read(sharedPreferencesProvider).setDouble(_key, value);
  }

  void setStep(FontScaleStep step) => set(step.scale);
}

/// Uygulamanın genel yazı tipi (Ayarlar → Görünüm → Yazı tipi).
///
/// Notun KENDİ yazı tipinden bağımsızdır: bu ayar arayüzü ve yazı tipi
/// seçilmemiş notları etkiler, not başına seçim onun üstüne biner.
/// Katalogdaki bütün yazı tipleri APK'ya gömülü olduğu için seçim
/// çevrimdışı da anında uygulanır.
final appFontProvider = NotifierProvider<AppFontNotifier, String>(
  AppFontNotifier.new,
);

class AppFontNotifier extends Notifier<String> {
  static const _key = 'app_font';

  @override
  String build() {
    final stored = watchPrefs(ref).getString(_key);
    // Kayıtta katalogdan çıkmış bir ad varsa varsayılana dönülür.
    return stored != null && appFontIds.contains(stored)
        ? stored
        : kAppDefaultFont;
  }

  void set(String family) {
    state = family;
    ref.read(sharedPreferencesProvider).setString(_key, family);
  }
}

/// Koyu tema zamanlaması: etkinse [startMinutes]–[endMinutes] (gün içi
/// dakika) aralığında koyu, dışında açık tema kullanılır.
class DarkSchedule {
  const DarkSchedule({
    required this.enabled,
    required this.startMinutes,
    required this.endMinutes,
  });

  final bool enabled;
  final int startMinutes;
  final int endMinutes;

  bool isDarkAt(DateTime time) {
    final minutes = time.hour * 60 + time.minute;
    if (startMinutes <= endMinutes) {
      return minutes >= startMinutes && minutes < endMinutes;
    }
    // Gece yarısını aşan aralık (ör. 21:00 → 07:00).
    return minutes >= startMinutes || minutes < endMinutes;
  }
}

final darkScheduleProvider =
    NotifierProvider<DarkScheduleNotifier, DarkSchedule>(
      DarkScheduleNotifier.new,
    );

class DarkScheduleNotifier extends Notifier<DarkSchedule> {
  static const _enabledKey = 'dark_schedule_enabled';
  static const _startKey = 'dark_schedule_start';
  static const _endKey = 'dark_schedule_end';

  @override
  DarkSchedule build() {
    final prefs = watchPrefs(ref);
    return DarkSchedule(
      enabled: prefs.getBool(_enabledKey) ?? false,
      startMinutes: prefs.getInt(_startKey) ?? 21 * 60,
      endMinutes: prefs.getInt(_endKey) ?? 7 * 60,
    );
  }

  void update({bool? enabled, int? startMinutes, int? endMinutes}) {
    final next = DarkSchedule(
      enabled: enabled ?? state.enabled,
      startMinutes: startMinutes ?? state.startMinutes,
      endMinutes: endMinutes ?? state.endMinutes,
    );
    state = next;
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setBool(_enabledKey, next.enabled);
    prefs.setInt(_startKey, next.startMinutes);
    prefs.setInt(_endKey, next.endMinutes);
  }
}

/// Ayarlarda ayrı model seçilebilen iş grupları.
///
/// Hepsi tek dropdown'a bağlıyken "özetleme hızlı model, podcast güçlü model"
/// gibi bir tercih kurulamıyordu. Gruplar görev tipine göre ayrıldı: kısa
/// metin işleri ucuz modelle yeter, uzun belge işi yetenekli model ister.
enum AiTask {
  /// Özet, başlık, etiket, iyileştirme, brifing, sohbet.
  general('model_chat'),

  /// PDF/not sohbeti — uzun bağlam.
  document('model_document'),

  /// Podcast anlatısı. Belge sohbetinden AYRI: podcast tek seferde uzun ve
  /// akıcı bir anlatı üretir (kullanıcı isteği — "podcast kısmında Gemini
  /// modelini seçme ayarı ayrı olsun"), sohbet ise kısa turlarla ilerler;
  /// biri için doğru olan model öbürü için pahalı ya da yetersiz kalıyor.
  podcast('model_podcast'),

  /// Metin ve konuşma çevirisi.
  translate('model_translate'),

  /// Sesli not asistanı (araç çağrılı).
  voice('model_voice');

  const AiTask(this.prefsKey);

  /// SharedPreferences anahtarı. `general` ve `voice` eski tekil ayarların
  /// anahtarlarını KORUYOR — güncelleyen kullanıcının seçimi kaybolmasın.
  final String prefsKey;
}

/// Podcast/belge okuma SESLENDİRMESİNİ kim yapacak?
enum TtsEngine {
  /// Cihazın yerleşik TTS'i: bedava, çevrimdışı, anında, sınırsız uzunlukta.
  device('device'),

  /// Gemini'nin seslendirme modeli: belirgin daha doğal ama her paragraf bir
  /// model çağrısıdır (kota harcar) ve kullanıcının KENDİ Gemini anahtarını
  /// ister — dahili (Firebase) yol ses döndürmüyor.
  gemini('gemini');

  const TtsEngine(this.id);

  final String id;

  static TtsEngine fromId(String? id) =>
      TtsEngine.values.firstWhere((e) => e.id == id, orElse: () => device);
}

/// Seslendirmeyi cihaz mı Gemini mi yapsın (varsayılan: cihaz — bedava).
final ttsEngineProvider = NotifierProvider<TtsEngineNotifier, TtsEngine>(
  TtsEngineNotifier.new,
);

class TtsEngineNotifier extends Notifier<TtsEngine> {
  static const _key = 'tts_engine';

  @override
  TtsEngine build() =>
      TtsEngine.fromId(watchPrefs(ref).getString(_key));

  void set(TtsEngine value) {
    state = value;
    ref.read(sharedPreferencesProvider).setString(_key, value.id);
  }
}

/// Kullanıcının seçtiği Gemini TTS modeli (null = uygulamanın yerleşik
/// tercihi). Metin modellerinden AYRI tutulur: TTS ayrı bir model ailesi.
final ttsModelProvider = NotifierProvider<TtsModelNotifier, String?>(
  TtsModelNotifier.new,
);

class TtsModelNotifier extends Notifier<String?> {
  static const _key = 'model_tts';

  @override
  String? build() => watchPrefs(ref).getString(_key);

  void set(String? value) {
    state = value;
    final prefs = ref.read(sharedPreferencesProvider);
    if (value == null) {
      prefs.remove(_key);
    } else {
      prefs.setString(_key, value);
    }
  }
}

/// Gemini TTS'in hazır ses adı (ör. "Kore"). Cihaz TTS'inin ses seçimi ayrı
/// tutulur (o dil başına saklanıyor, bkz. SpeechOutputController).
final ttsVoiceProvider = NotifierProvider<TtsVoiceNotifier, String>(
  TtsVoiceNotifier.new,
);

class TtsVoiceNotifier extends Notifier<String> {
  static const _key = 'tts_gemini_voice';

  @override
  String build() =>
      watchPrefs(ref).getString(_key) ??
      AppConstants.geminiTtsVoices.first;

  void set(String value) {
    state = value;
    ref.read(sharedPreferencesProvider).setString(_key, value);
  }
}

/// Kullanıcının seçtiği Gemini modelleri (null = otomatik zincir).
/// Seçilen model ilgili akışta ilk sırada denenir; 404/429'da zincir sürer.
final aiTaskModelsProvider =
    NotifierProvider<AiTaskModelsNotifier, Map<AiTask, String?>>(
      AiTaskModelsNotifier.new,
    );

class AiTaskModelsNotifier extends Notifier<Map<AiTask, String?>> {
  @override
  Map<AiTask, String?> build() {
    final prefs = watchPrefs(ref);
    return {
      for (final task in AiTask.values) task: prefs.getString(task.prefsKey),
    };
  }

  void set(AiTask task, String? value) {
    state = {...state, task: value};
    final prefs = ref.read(sharedPreferencesProvider);
    if (value == null) {
      prefs.remove(task.prefsKey);
    } else {
      prefs.setString(task.prefsKey, value);
    }
  }
}

/// Editör kapanırken başlıksız kalan nota AI otomatik başlık yazsın mı?
/// Eski 'auto_title' anahtarı korunur — önceki sürümde açık bırakan
/// kullanıcının tercihi geri gelir.
final autoTitleProvider = boolPref('auto_title', defaultValue: true);

/// Notlar kaydedilirken AI otomatik etiket atasın mı?
/// **PAYLAŞILAN KLASÖR BİLDİRİMLERİ** (kullanıcı isteği 2026-09-04:
/// "bildirim hem telefona bildirim gelmeli ayarlardan kapatılabilir olarak
/// hem de ana sayfada basit bir işaretçi olmalı").
///
/// Kapalıyken YALNIZ telefon bildirimi susar; ana ekrandaki rozet
/// (okunmamış sayısı) durur — o, bildirimden ayrı bir şey: uygulamanın
/// içinde "bir şey oldu" demenin sessiz yolu.
///
/// Varsayılan AÇIK: paylaşılan klasör zaten "haberim olsun" diye kurulan
/// bir şey.
final sharedNotificationsProvider = boolPref('shared_notifications', defaultValue: true);

/// **ADIMLA/E-POSTAMLA BULUNABİLİRİM** (F1.1, 2026-10-19). Açıkken
/// `userSearch/{uid}` yazılır ve başkaları beni ad önekiyle ya da tam
/// e-postayla "Kişi ara"da bulur. Kapalıyken belge silinir; yalnız tam
/// e-postamı bilen kişi "E-postayla ekle" yoluyla istek gönderebilir.
/// Varsayılan AÇIK (kullanıcı kararı).
final discoverableProvider = boolPref('discoverable', defaultValue: true);

/// **ÇÖKME RAPORLARI** (F1.9, 2026-10-19): Android'de yakalanmayan hatalar
/// Firebase Crashlytics'e gitsin mi. Varsayılan AÇIK (kullanıcı kararı);
/// cihazdaki hata günlüğü bundan bağımsız hep tutulur.
final crashReportsProvider = NotifierProvider<CrashReportsNotifier, bool>(
  CrashReportsNotifier.new,
);

class CrashReportsNotifier extends Notifier<bool> {
  static const _key = 'crash_reports';

  /// `main` sağlayıcılar kurulmadan önce okur.
  static bool read(SharedPreferences prefs) => prefs.getBool(_key) ?? true;

  @override
  bool build() => read(watchPrefs(ref));

  void set(bool value) {
    state = value;
    ref.read(sharedPreferencesProvider).setBool(_key, value);
    unawaited(CrashReporting.setEnabled(value));
  }
}

final autoTagProvider = boolPref('auto_tag', defaultValue: false);

/// Checklist notu AI ile düzeltilirken/çevrilirken işaretli (tamamlanmış)
/// maddeler düzenleme dışında mı tutulsun? Varsayılan AÇIK: tamamlanan
/// maddeler AI'a hiç gönderilmez, olduğu gibi korunur — hem işaretleri
/// kaybolmaz hem de kapsamı yalnız yapılacaklar (işaretsizler) olur.
final aiSkipCheckedProvider = boolPref('ai_skip_checked', defaultValue: true);

/// Liste/checklist öğelerindeki uzun satırlar tam mı gösterilsin?
/// true (varsayılan): satır kaç satıra gerekirse sarılır, hepsi görünür.
/// false: satır tek satırda kalır, dokununca (odaklanınca) açılır.
final expandListItemsProvider = boolPref('expand_list_items', defaultValue: true);

/// Ana ekranın üstündeki tek satırlık "Yeni not..." hızlı yakalama alanı
/// görünsün mü? Varsayılan GİZLİ (kullanıcı isteği 2026-08-06): satır dikey
/// yer kaplıyor ve "+" menüsü aynı işi görüyor; isteyen Ayarlar'dan açar.
final quickCaptureRowProvider = boolPref('quick_capture_row', defaultValue: false);

/// Ana ekrandaki kartlarda satır içi biçimlendirme (renk, vurgu, kalın,
/// altı çizili, boyut) ÇİZİLSİN Mİ?
///
/// Varsayılan AÇIK (kullanıcı isteği 2026-08-07): kart önizlemesi eskiden
/// biçimi [stripRichMarkers] ile söküyordu, yani editörde renklendirilen bir
/// not ana ekranda düz metin görünüyordu. Kapatan kullanıcı eski, tamamen
/// tek renk okunan önizlemeye döner (yoğun renkli notlarda ızgara alacalı
/// görünebiliyor).
///
/// Ayar yalnız GÖSTERİMİ etkiler: metin her iki durumda da aynı, işaretli
/// hâliyle saklanır.
final cardRichPreviewProvider = boolPref('card_rich_preview', defaultValue: true);

/// Eklerin buluta otomatik senkronu (Storage'a yükleme) için boyut sınırı, MB.
/// 0 = sınırsız. Sınırı aşan ek cihazda kalır; not metni yine senkronlanır,
/// yalnız dosyanın kendisi yüklenmez (kota/veri tasarrufu).
final syncLimitMbProvider = NotifierProvider<SyncLimitMbNotifier, int>(
  SyncLimitMbNotifier.new,
);

class SyncLimitMbNotifier extends Notifier<int> {
  static const _key = 'sync_limit_mb';

  /// Seçilebilir sınırlar (MB); 0 = sınırsız.
  static const options = [5, 10, 25, 50, 0];

  @override
  int build() => watchPrefs(ref).getInt(_key) ?? 25;

  void set(int value) {
    state = value;
    ref.read(sharedPreferencesProvider).setInt(_key, value);
  }
}

/// Sesli Not Asistanı düğmesinin kullanım şekli.
/// tap (VARSAYILAN): bir dokunuşla kayıt başlar, ikinci dokunuşla biter.
/// hold: basılı tutarak konuş, bırakınca not oluşur.
///
/// Varsayılan bas-başlat/bas-bitir: basılı tutmak uzun konuşmalarda yorucu ve
/// parmağın kayması kaydı kesiyor; kullanıcı isteği de bu yönde.
enum VoiceButtonMode { hold, tap }

final voiceButtonModeProvider =
    NotifierProvider<VoiceButtonModeNotifier, VoiceButtonMode>(
      VoiceButtonModeNotifier.new,
    );

class VoiceButtonModeNotifier extends Notifier<VoiceButtonMode> {
  static const _key = 'voice_button_mode';

  @override
  VoiceButtonMode build() {
    final stored = watchPrefs(ref).getString(_key);
    return VoiceButtonMode.values.firstWhere(
      (m) => m.name == stored,
      orElse: () => VoiceButtonMode.tap,
    );
  }

  void set(VoiceButtonMode mode) {
    state = mode;
    ref.read(sharedPreferencesProvider).setString(_key, mode.name);
  }
}

/// AKILLI DİNLEME: sesli not sessizlikte kendiliğinden bitsin mi
/// (bkz. `SilenceGate`). Varsayılan AÇIK — kullanıcı bulgusu 2026-10-19:
/// "sesli not oto sonlanmıyor, sürekli dinlemeye devam ediyor".
final voiceAutoStopProvider = boolPref('voice_auto_stop', defaultValue: true);

/// Sessizlikte bitişin ne kadar bekleyeceği. Kullanıcı isteği 2026-10-19:
/// düşünerek konuşan için sabit 4 sn kısa kalabilir, hızlı not alan için
/// uzun. Normal, ilk sürümün değeridir.
enum VoiceSilence {
  short(Duration(milliseconds: 2500)),
  normal(Duration(seconds: 4)),
  long(Duration(seconds: 7));

  const VoiceSilence(this.duration);

  final Duration duration;
}

final voiceSilenceProvider = NotifierProvider<VoiceSilenceNotifier, VoiceSilence>(
  VoiceSilenceNotifier.new,
);

class VoiceSilenceNotifier extends Notifier<VoiceSilence> {
  static const _key = 'voice_silence';

  @override
  VoiceSilence build() {
    final stored = watchPrefs(ref).getString(_key);
    return VoiceSilence.values.firstWhere(
      (v) => v.name == stored,
      orElse: () => VoiceSilence.normal,
    );
  }

  void set(VoiceSilence value) {
    state = value;
    ref.read(sharedPreferencesProvider).setString(_key, value.name);
  }
}

/// İNTERNETSİZ TANIMA: telefonda dil paketi indirilmişse sesli not ağa
/// gitmeden tanınır (gizlilik, uçak modu, zayıf bağlantı). Varsayılan
/// KAPALI: paket yoksa yerli taraf çevrimiçine düşse de ilk denemede kısa bir
/// gecikme olur; bilerek açan kullanıcı içindir.
final voiceOfflineProvider = boolPref('voice_offline', defaultValue: false);

/// AKILLI KOMUTLAR: dikte sırasında "son kelimeyi sil", "X yerine Y yaz"
/// gibi düzeltmeler uygulansın mı (bkz. `applyVoiceCommands`). Varsayılan
/// AÇIK; bu sözleri gerçekten not olarak yazdırmak isteyen kapatabilir.
final voiceSmartCommandsProvider = boolPref('voice_smart_commands', defaultValue: true);

/// Ana ekranın TEK mikrofonu (F3.1) dokununca hangi kipte açılsın: true =
/// doğrudan yazdır (boş not, söz nota), false = sesli not levhası (AI
/// düzenlesin). Son kullanılan kip hatırlanır; basılı tutmak öbürünü açar.
final homeMicDictateProvider = boolPref('home_mic_dictate', defaultValue: false);

/// Günlük brifing bildirimi ayarları.
class BriefingSettings {
  const BriefingSettings({required this.enabled, required this.minutes});

  final bool enabled;

  /// Gün içi dakika (ör. 08:30 → 510).
  final int minutes;
}

final briefingSettingsProvider =
    NotifierProvider<BriefingSettingsNotifier, BriefingSettings>(
      BriefingSettingsNotifier.new,
    );

class BriefingSettingsNotifier extends Notifier<BriefingSettings> {
  static const _enabledKey = 'briefing_enabled';
  static const _minutesKey = 'briefing_minutes';

  @override
  BriefingSettings build() {
    final prefs = watchPrefs(ref);
    return BriefingSettings(
      enabled: prefs.getBool(_enabledKey) ?? false,
      minutes: prefs.getInt(_minutesKey) ?? 8 * 60 + 30,
    );
  }

  void update({bool? enabled, int? minutes}) {
    final next = BriefingSettings(
      enabled: enabled ?? state.enabled,
      minutes: minutes ?? state.minutes,
    );
    state = next;
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setBool(_enabledKey, next.enabled);
    prefs.setInt(_minutesKey, next.minutes);
  }
}

/// Zamanlamalı tema geçişi için "şimdi" akışı.
/// autoDispose: zamanlama KAPALIYKEN kimse izlemez ve zamanlayıcı tümüyle
/// durur — sürekli çalışan gereksiz bir uyandırma kaynağıydı (pil).
///
/// Dakikalık tik DEĞİL: tema günde iki kez değişiyor ama dakikalık tik,
/// [effectiveThemeModeProvider] kök widget'ta izlendiği için TÜM MaterialApp
/// alt ağacını günde 1440 kez yeniden kuruyordu. Tek Timer bir SONRAKİ geçiş
/// anına (start/end) kurulur, tetiklenince yeniden kurulur: günde 2 uyandırma.
final _clockProvider = StreamProvider.autoDispose<DateTime>((ref) {
  final schedule = ref.watch(darkScheduleProvider);
  final controller = StreamController<DateTime>();
  Timer? timer;
  void arm() {
    final now = DateTime.now();
    // +1 sn tampon: tetik tam sınırda düşerse isDarkAt doğru tarafta kalsın.
    timer = Timer(
      _nextBoundary(now, schedule).difference(now) + const Duration(seconds: 1),
      () {
        controller.add(DateTime.now());
        arm();
      },
    );
  }

  arm();
  ref.onDispose(() {
    timer?.cancel();
    controller.close();
  });
  return controller.stream;
});

/// [now]'dan sonraki ilk tema geçiş anı (bugünkü ya da yarınki start/end).
DateTime _nextBoundary(DateTime now, DarkSchedule schedule) {
  DateTime? best;
  for (final minutes in [schedule.startMinutes, schedule.endMinutes]) {
    for (final dayOffset in [0, 1]) {
      // Gün aritmetiği DateTime kurucusunda: DST günlerinde Duration eklemek
      // saat kaydırabiliyor.
      final t = DateTime(now.year, now.month, now.day + dayOffset, 0, minutes);
      if (t.isAfter(now) && (best == null || t.isBefore(best))) best = t;
    }
  }
  return best ?? now.add(const Duration(days: 1));
}

/// Kullanıcı seçimi + zamanlama birleşimiyle geçerli tema modu.
/// "Kağıt" açık tema gibi davranır; hangi açık temanın kullanılacağına
/// app.dart, themeChoiceProvider'a bakarak karar verir.
/// autoDispose: _clockProvider'ı izleyebilmek için zorunlu (autoDispose
/// olmayan sağlayıcı autoDispose'u izleyemez); kök widget sürekli izlediği
/// için pratikte hep canlı kalır.
final effectiveThemeModeProvider = Provider.autoDispose<ThemeMode>((ref) {
  final schedule = ref.watch(darkScheduleProvider);
  if (schedule.enabled) {
    final now = ref.watch(_clockProvider).value ?? DateTime.now();
    return schedule.isDarkAt(now) ? ThemeMode.dark : ThemeMode.light;
  }
  return switch (ref.watch(themeChoiceProvider)) {
    AppThemeChoice.system => ThemeMode.system,
    AppThemeChoice.light || AppThemeChoice.paper => ThemeMode.light,
    AppThemeChoice.dark => ThemeMode.dark,
  };
});

/// Sesli asistan yanıtını yüksek sesle okusun mu?
///
/// Varsayılan AÇIK: asistanın bütün anlamı eller meşgulken cevabı duymak.
/// Ayar hem Ayarlar ekranından hem asistan panelindeki "sustur" düğmesinden
/// değişir — ikisi AYNI değeri okur, biri açıkken diğeri kapalı görünmez.
final assistantVoiceProvider = boolPref('assistant_voice', defaultValue: true);

/// Ana ekranın (dashboard) ZEMİNİ: **renk + desen + görsel**.
///
/// Nota özel zeminden farkı: bu ayar cihaza aittir, buluta yazılmaz. Seçilen
/// görsel uygulamanın kendi klasörüne KOPYALANIR — galerideki dosya silinse
/// ya da geçici paylaşım yolu geçersizleşse bile zemin kaybolmasın.
///
/// **RENK VE DESEN** (kullanıcı isteği: "ana ekran zemini kısmına renk ve
/// model seçenekleri"): zemin şimdiye dek yalnız GALERİDEN bir fotoğraf
/// seçtiriyordu. Fotoğraf koymak istemeyen ama ana ekranını kişiselleştirmek
/// isteyen kullanıcı için hiçbir şey yoktu; üstelik fotoğraflı zemin kart
/// ızgarasının okunurluğunu her zaman düşürüyor. Renk + desen bu boşluğu
/// dolduruyor ve desenler ÇİZİLİYOR (varlık dosyası yok): temaya uyum
/// sağlıyorlar ve APK'yı büyütmüyorlar.
///
/// Üçü ÜST ÜSTE binebilir — sıra: renk (en altta), desen, görsel.
enum DashboardPattern {
  none('none'),
  dots('dots'),
  grid('grid'),
  lines('lines'),
  diagonal('diagonal'),
  graph('graph');

  const DashboardPattern(this.id);

  final String id;

  static DashboardPattern fromId(String? id) => DashboardPattern.values
      .firstWhere((p) => p.id == id, orElse: () => DashboardPattern.none);
}

@immutable
class DashboardBackground {
  const DashboardBackground({
    this.path,
    this.opacity = 0.25,
    this.color,
    this.pattern = DashboardPattern.none,
  });

  /// Cihazdaki kopyanın yolu; null = zemin görseli yok.
  final String? path;

  /// Görünürlük (0.05–1). Varsayılan düşük: kart ızgarası okunur kalmalı.
  /// Hem görselin hem desenin görünürlüğünü ayarlar.
  final double opacity;

  /// Düz zemin rengi (ARGB); null = temanın kendi yüzey rengi.
  final int? color;

  /// Zemin deseni; [DashboardPattern.none] = desen yok.
  final DashboardPattern pattern;

  DashboardBackground copyWith({
    String? path,
    bool clearPath = false,
    double? opacity,
    int? color,
    bool clearColor = false,
    DashboardPattern? pattern,
  }) => DashboardBackground(
    path: clearPath ? null : (path ?? this.path),
    opacity: opacity ?? this.opacity,
    color: clearColor ? null : (color ?? this.color),
    pattern: pattern ?? this.pattern,
  );
}

final dashboardBackgroundProvider =
    NotifierProvider<DashboardBackgroundNotifier, DashboardBackground>(
      DashboardBackgroundNotifier.new,
    );

class DashboardBackgroundNotifier extends Notifier<DashboardBackground> {
  static const _pathKey = 'dashboard_bg_path';
  static const _opacityKey = 'dashboard_bg_opacity';
  static const _colorKey = 'dashboard_bg_color';
  static const _patternKey = 'dashboard_bg_pattern';

  @override
  DashboardBackground build() {
    final prefs = watchPrefs(ref);
    return DashboardBackground(
      path: prefs.getString(_pathKey),
      opacity: prefs.getDouble(_opacityKey) ?? 0.25,
      color: prefs.getInt(_colorKey),
      pattern: DashboardPattern.fromId(prefs.getString(_patternKey)),
    );
  }

  void setPath(String? path) {
    state = state.copyWith(path: path, clearPath: path == null);
    final prefs = ref.read(sharedPreferencesProvider);
    if (path == null) {
      prefs.remove(_pathKey);
    } else {
      prefs.setString(_pathKey, path);
    }
  }

  void setOpacity(double value) {
    state = state.copyWith(opacity: value);
    ref.read(sharedPreferencesProvider).setDouble(_opacityKey, value);
  }

  void setColor(int? argb) {
    state = state.copyWith(color: argb, clearColor: argb == null);
    final prefs = ref.read(sharedPreferencesProvider);
    if (argb == null) {
      prefs.remove(_colorKey);
    } else {
      prefs.setInt(_colorKey, argb);
    }
  }

  void setPattern(DashboardPattern pattern) {
    state = state.copyWith(pattern: pattern);
    ref.read(sharedPreferencesProvider).setString(_patternKey, pattern.id);
  }

  /// Renk + desen + görseli birlikte varsayılana döndürür.
  void reset() {
    state = const DashboardBackground();
    ref.read(sharedPreferencesProvider)
      ..remove(_pathKey)
      ..remove(_opacityKey)
      ..remove(_colorKey)
      ..remove(_patternKey);
  }
}
