import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/settings_providers.dart';
import '../domain/holidays.dart';

/// Takvimde resmî ve dinî tatiller görünsün mü (varsayılan açık).
final showHolidaysProvider = boolPref('calendar_holidays', defaultValue: true);

/// **TATİL DÜZELTMELERİ** (kullanıcı isteği 2026-11-07: "dinî tatiller bazen
/// uzatılıyor, genelde yakın zamanda açıklanıyor — güncel tutmalıyız"):
/// `config/holidays` (herkes okur, istemci yazamaz). Kaynak depoda
/// `tool/tatiller.json`; CI `deploy` işi main'e her push'ta yazar
/// (`tool/set_holidays.js`). APK yeniden derlenmeden uzatma/idari izin
/// telefona gelir; Firestore çevrimdışı önbelleği son listeyi tutar.
final holidayOverridesProvider = StreamProvider<HolidayOverrides>((ref) {
  // Testte / Firebase'siz web önizlemesinde yerleşik tablo yeter.
  if (Firebase.apps.isEmpty) return Stream.value(HolidayOverrides.none);
  return FirebaseFirestore.instance
      .collection('config')
      .doc('holidays')
      .snapshots()
      .map((d) => HolidayOverrides.fromMap(d.data()))
      .handleError((Object _) {});
});

final holidayCalendarProvider = Provider<HolidayCalendar>((ref) {
  if (!ref.watch(showHolidaysProvider)) return const HolidayCalendar.off();
  return HolidayCalendar(
    ref.watch(holidayOverridesProvider).value ?? HolidayOverrides.none,
  );
});
