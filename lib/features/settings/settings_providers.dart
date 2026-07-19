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

/// Kullanıcının seçtiği Gemini modelleri (null = otomatik zincir).
/// Seçilen model ilgili akışta ilk sırada denenir; 404/429'da zincir sürer.
final chatModelProvider = NotifierProvider<ChatModelNotifier, String?>(
  ChatModelNotifier.new,
);

class ChatModelNotifier extends Notifier<String?> {
  static const _key = 'model_chat';

  @override
  String? build() => ref.watch(sharedPreferencesProvider).getString(_key);

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

final voiceModelProvider = NotifierProvider<VoiceModelNotifier, String?>(
  VoiceModelNotifier.new,
);

class VoiceModelNotifier extends Notifier<String?> {
  static const _key = 'model_voice';

  @override
  String? build() => ref.watch(sharedPreferencesProvider).getString(_key);

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

/// Çeviri nerede yapılsın: cihazda (ML Kit, bedava/çevrimdışı) mi, Gemini'de
/// (daha iyi kalite, kota harcar) mi. Varsayılan cihaz — bas-konuş modu böylece
/// hiçbir kota yakmaz. ML Kit'in desteklemediği dillerde (ör. Azerbaycanca)
/// bu ayar ne olursa olsun Gemini'ye düşülür.
final preferGeminiTranslateProvider =
    NotifierProvider<PreferGeminiTranslateNotifier, bool>(
      PreferGeminiTranslateNotifier.new,
    );

class PreferGeminiTranslateNotifier extends Notifier<bool> {
  static const _key = 'prefer_gemini_translate';

  @override
  bool build() => ref.watch(sharedPreferencesProvider).getBool(_key) ?? false;

  void set(bool value) {
    state = value;
    ref.read(sharedPreferencesProvider).setBool(_key, value);
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
final _clockProvider = StreamProvider<DateTime>(
  (ref) => Stream.periodic(const Duration(minutes: 1), (_) => DateTime.now()),
);

/// Kullanıcı seçimi + zamanlama birleşimiyle geçerli tema modu.
/// "Kağıt" açık tema gibi davranır; hangi açık temanın kullanılacağına
/// app.dart, themeChoiceProvider'a bakarak karar verir.
final effectiveThemeModeProvider = Provider<ThemeMode>((ref) {
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
