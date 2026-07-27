import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// main() içinde gerçek örnekle override edilir.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('main() içinde override edilmeli'),
);

/// Tema seçimi: sistem/açık/koyu artı "kağıt" (hafif saman kağıdı renkli
/// açık tema). ThemeMode'da karşılığı olmadığından kendi enum'ımız var;
/// aynı prefs anahtarını kullandığı için eski kayıtlar geriye uyumludur.
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
      orElse: () => AppThemeChoice.system,
    );
  }

  void set(AppThemeChoice choice) {
    state = choice;
    ref.read(sharedPreferencesProvider).setString(_key, choice.name);
  }
}

/// Yazı boyutu çarpanı (0.85–1.4).
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
/// hold (varsayılan): basılı tutarak konuş, bırakınca not oluşur.
/// tap: bir dokunuşla kayıt başlar, ikinci dokunuşla biter.
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
      orElse: () => VoiceButtonMode.hold,
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

/// Dakikada bir güncellenen saat (zamanlamalı tema geçişi için).
/// autoDispose: zamanlama KAPALIYKEN kimse izlemez ve dakikalık zamanlayıcı
/// tümüyle durur — sürekli çalışan gereksiz bir uyandırma kaynağıydı (pil).
final _clockProvider = StreamProvider.autoDispose<DateTime>(
  (ref) => Stream.periodic(const Duration(minutes: 1), (_) => DateTime.now()),
);

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
