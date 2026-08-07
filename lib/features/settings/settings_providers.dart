import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/language_names.dart';
import '../../core/utils/note_fonts.dart';
import '../../l10n/generated/app_localizations.dart';

/// main() içinde gerçek örnekle override edilir.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('main() içinde override edilmeli'),
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
    final stored = ref.watch(sharedPreferencesProvider).getString(_key);
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
    final code = ref.watch(sharedPreferencesProvider).getString(_key);
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

/// Yazı boyutu çarpanı. Sistem ayarının YERİNE geçer (bkz. `fixedTypography`).
final fontScaleProvider = NotifierProvider<FontScaleNotifier, double>(
  FontScaleNotifier.new,
);

class FontScaleNotifier extends Notifier<double> {
  static const _key = 'font_scale';

  @override
  double build() => ref.watch(sharedPreferencesProvider).getDouble(_key) ?? 1.0;

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
    final stored = ref.watch(sharedPreferencesProvider).getString(_key);
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
    final prefs = ref.watch(sharedPreferencesProvider);
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

  /// Podcast metni, PDF/not sohbeti — uzun bağlam.
  document('model_document'),

  /// Metin ve konuşma çevirisi.
  translate('model_translate'),

  /// Sesli not asistanı (araç çağrılı).
  voice('model_voice');

  const AiTask(this.prefsKey);

  /// SharedPreferences anahtarı. `general` ve `voice` eski tekil ayarların
  /// anahtarlarını KORUYOR — güncelleyen kullanıcının seçimi kaybolmasın.
  final String prefsKey;
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
    final prefs = ref.watch(sharedPreferencesProvider);
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
final autoTitleProvider = NotifierProvider<AutoTitleNotifier, bool>(
  AutoTitleNotifier.new,
);

class AutoTitleNotifier extends Notifier<bool> {
  static const _key = 'auto_title';

  @override
  bool build() => ref.watch(sharedPreferencesProvider).getBool(_key) ?? true;

  void set(bool value) {
    state = value;
    ref.read(sharedPreferencesProvider).setBool(_key, value);
  }
}

/// Notlar kaydedilirken AI otomatik etiket atasın mı?
final autoTagProvider = NotifierProvider<AutoTagNotifier, bool>(
  AutoTagNotifier.new,
);

class AutoTagNotifier extends Notifier<bool> {
  static const _key = 'auto_tag';

  @override
  bool build() => ref.watch(sharedPreferencesProvider).getBool(_key) ?? false;

  void set(bool value) {
    state = value;
    ref.read(sharedPreferencesProvider).setBool(_key, value);
  }
}

/// Checklist notu AI ile düzeltilirken/çevrilirken işaretli (tamamlanmış)
/// maddeler düzenleme dışında mı tutulsun? Varsayılan AÇIK: tamamlanan
/// maddeler AI'a hiç gönderilmez, olduğu gibi korunur — hem işaretleri
/// kaybolmaz hem de kapsamı yalnız yapılacaklar (işaretsizler) olur.
final aiSkipCheckedProvider = NotifierProvider<AiSkipCheckedNotifier, bool>(
  AiSkipCheckedNotifier.new,
);

class AiSkipCheckedNotifier extends Notifier<bool> {
  static const _key = 'ai_skip_checked';

  @override
  bool build() => ref.watch(sharedPreferencesProvider).getBool(_key) ?? true;

  void set(bool value) {
    state = value;
    ref.read(sharedPreferencesProvider).setBool(_key, value);
  }
}

/// Liste/checklist öğelerindeki uzun satırlar tam mı gösterilsin?
/// true (varsayılan): satır kaç satıra gerekirse sarılır, hepsi görünür.
/// false: satır tek satırda kalır, dokununca (odaklanınca) açılır.
final expandListItemsProvider = NotifierProvider<ExpandListItemsNotifier, bool>(
  ExpandListItemsNotifier.new,
);

class ExpandListItemsNotifier extends Notifier<bool> {
  static const _key = 'expand_list_items';

  @override
  bool build() => ref.watch(sharedPreferencesProvider).getBool(_key) ?? true;

  void set(bool value) {
    state = value;
    ref.read(sharedPreferencesProvider).setBool(_key, value);
  }
}

/// Ana ekranın üstündeki tek satırlık "Yeni not..." hızlı yakalama alanı
/// görünsün mü? Varsayılan GİZLİ (kullanıcı isteği 2026-08-06): satır dikey
/// yer kaplıyor ve "+" menüsü aynı işi görüyor; isteyen Ayarlar'dan açar.
final quickCaptureRowProvider = NotifierProvider<QuickCaptureRowNotifier, bool>(
  QuickCaptureRowNotifier.new,
);

class QuickCaptureRowNotifier extends Notifier<bool> {
  static const _key = 'quick_capture_row';

  @override
  bool build() => ref.watch(sharedPreferencesProvider).getBool(_key) ?? false;

  void set(bool value) {
    state = value;
    ref.read(sharedPreferencesProvider).setBool(_key, value);
  }
}

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
final cardRichPreviewProvider = NotifierProvider<CardRichPreviewNotifier, bool>(
  CardRichPreviewNotifier.new,
);

class CardRichPreviewNotifier extends Notifier<bool> {
  static const _key = 'card_rich_preview';

  @override
  bool build() => ref.watch(sharedPreferencesProvider).getBool(_key) ?? true;

  void set(bool value) {
    state = value;
    ref.read(sharedPreferencesProvider).setBool(_key, value);
  }
}

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
  int build() => ref.watch(sharedPreferencesProvider).getInt(_key) ?? 25;

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
    final stored = ref.watch(sharedPreferencesProvider).getString(_key);
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
    final prefs = ref.watch(sharedPreferencesProvider);
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
final assistantVoiceProvider = NotifierProvider<AssistantVoiceNotifier, bool>(
  AssistantVoiceNotifier.new,
);

class AssistantVoiceNotifier extends Notifier<bool> {
  static const _key = 'assistant_voice';

  @override
  bool build() => ref.watch(sharedPreferencesProvider).getBool(_key) ?? true;

  void set(bool value) {
    state = value;
    ref.read(sharedPreferencesProvider).setBool(_key, value);
  }

  void toggle() => set(!state);
}

/// Ana ekranın (dashboard) ZEMİN görseli.
///
/// Nota özel zeminden farkı: bu ayar cihaza aittir, buluta yazılmaz. Seçilen
/// görsel uygulamanın kendi klasörüne KOPYALANIR — galerideki dosya silinse
/// ya da geçici paylaşım yolu geçersizleşse bile zemin kaybolmasın.
@immutable
class DashboardBackground {
  const DashboardBackground({this.path, this.opacity = 0.25});

  /// Cihazdaki kopyanın yolu; null = zemin yok.
  final String? path;

  /// Görünürlük (0.05–1). Varsayılan düşük: kart ızgarası okunur kalmalı.
  final double opacity;
}

final dashboardBackgroundProvider =
    NotifierProvider<DashboardBackgroundNotifier, DashboardBackground>(
      DashboardBackgroundNotifier.new,
    );

class DashboardBackgroundNotifier extends Notifier<DashboardBackground> {
  static const _pathKey = 'dashboard_bg_path';
  static const _opacityKey = 'dashboard_bg_opacity';

  @override
  DashboardBackground build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return DashboardBackground(
      path: prefs.getString(_pathKey),
      opacity: prefs.getDouble(_opacityKey) ?? 0.25,
    );
  }

  void setPath(String? path) {
    state = DashboardBackground(path: path, opacity: state.opacity);
    final prefs = ref.read(sharedPreferencesProvider);
    if (path == null) {
      prefs.remove(_pathKey);
    } else {
      prefs.setString(_pathKey, path);
    }
  }

  void setOpacity(double value) {
    state = DashboardBackground(path: state.path, opacity: value);
    ref.read(sharedPreferencesProvider).setDouble(_opacityKey, value);
  }
}
