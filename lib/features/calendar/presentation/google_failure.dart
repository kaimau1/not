import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/widgets/undo_snackbar.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/google_api_problem.dart';
import '../data/google_calendar_api.dart';
import '../data/google_tasks_api.dart';

/// Google API hatasının durum kodu ve gövdesi (Takvim ya da Görevler).
(int, String)? _statusOf(Object? error) => switch (error) {
  GoogleCalendarException(:final status, :final body) => (status, body),
  GoogleTasksException(:final status, :final body) => (status, body),
  _ => null,
};

/// Bağlanamama nedeni kullanıcı diliyle (kullanıcı bulgusu 2026-11-06:
/// "Google takvimi bağlanamadı uyarısı geliyor" — neden söylenmiyordu).
/// API projede kapalıysa "Etkinleştir" eylemi konsol sayfasını açar.
void showGoogleConnectFailure(
  ScaffoldMessengerState messenger,
  AppLocalizations l10n,
  Object? error, {
  required String fallback,
  required String apiName,
  required String apiHost,
}) {
  final s = _statusOf(error);
  if (s != null && googleServiceDisabled(s.$1, s.$2)) {
    final url = googleActivationUrl(s.$2, apiHost);
    messenger.showMessage(
      l10n.googleApiDisabled(apiName),
      duration: const Duration(seconds: 10),
      action: SnackBarAction(
        label: l10n.googleApiEnable,
        onPressed: () =>
            launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      ),
    );
    return;
  }
  if (s != null && googleScopeInsufficient(s.$1, s.$2)) {
    messenger.showMessage(l10n.googleScopeMissing(apiName));
    return;
  }
  messenger.showMessage(s == null ? fallback : '$fallback (HTTP ${s.$1})');
}

/// Kalıcı uyarı satırı için: hata "API kapalı" mı.
bool googleErrorIsServiceDisabled(Object? error) {
  final s = _statusOf(error);
  return s != null && googleServiceDisabled(s.$1, s.$2);
}
