import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error_log.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../settings/settings_providers.dart';
import 'notes_repository.dart';

/// Hesap başına BİR KEZ koşan veri göçleri (Faz 3). Bayrak cihazda tutulur:
/// her cihaz kendi açılışında dener; göç işlemleri tekrar koşmaya dayanıklı
/// (aynı sonucu yazar), iki cihazın ikisi de koşsa zarar yok.
///
/// Hata olursa bayrak YAZILMAZ — sonraki açılışta yeniden denenir. Okuma
/// tarafı (`Note.fromMap`) eski alanları zaten çevirdiği için göç
/// gecikse de ekranda fark görünmez.
final dataMigrationsProvider = Provider<void>((ref) {
  final uid = ref.watch(currentUidProvider);
  final repo = ref.watch(notesRepositoryProvider);
  if (uid == null || repo == null) return;
  final prefs = ref.read(sharedPreferencesProvider);
  Future<void> run(String name, Future<void> Function() migrate) async {
    final key = 'migration_${name}_$uid';
    if (prefs.getBool(key) ?? false) return;
    try {
      await migrate();
      await prefs.setBool(key, true);
    } catch (e, st) {
      ErrorLog.record('migration.$name', e, st);
    }
  }

  unawaited(() async {
    // Sıra önemli: defter göçü tam belge yazar; kavram göçü ondan sonra
    // eski alanları (yıldız, yalnız çerçeve) da temizler.
    await run('f35', repo.migrateNotebooks);
    await run('f36', repo.migrateConceptPairs);
  }());
});
