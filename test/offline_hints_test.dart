import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/presentation/dashboard_screen.dart'
    show pendingUploadsBarLabel;
import 'package:notlar/l10n/generated/app_localizations.dart';

/// DENEYIM F79.6 (5): çevrimdışı hâller önceden söylenir.
void main() {
  final l10n = lookupAppLocalizations(const Locale('tr'));

  group('F79.6 (5) bekleyen ek şeridi', () {
    String label({
      int pending = 2,
      int failed = 0,
      bool needsDrive = false,
      bool offline = false,
    }) => pendingUploadsBarLabel(
      l10n,
      pending: pending,
      failed: failed,
      needsDrive: needsDrive,
      offline: offline,
    );

    test('bağlıyken "yükleniyor"', () {
      expect(label(), l10n.pendingUploads(2));
    });

    test('çevrimdışıyken "yükleniyor" demez', () {
      expect(label(offline: true), l10n.pendingUploadsOffline(2));
      expect(label(offline: true), isNot(l10n.pendingUploads(2)));
    });

    test('çevrimdışı hatadan önce gelir (deneme düşmesi beklenen şey)', () {
      expect(label(offline: true, failed: 1), l10n.pendingUploadsOffline(2));
    });

    test('Drive bağlantısı bekliyorsa o söylenir', () {
      expect(label(needsDrive: true, offline: true), l10n.driveWaiting(2));
    });
  });
}
