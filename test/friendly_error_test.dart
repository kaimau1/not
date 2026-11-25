import 'dart:async';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/error_log.dart';
import 'package:notlar/core/friendly_error.dart';
import 'package:notlar/features/ai/data/ai_policy.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// F10.4: kullanıcı ham istisna metni görmez ("Unsupported operation:
/// RawReceivePort", "[cloud_firestore/permission-denied] …").
void main() {
  final l10n = lookupAppLocalizations(const Locale('tr'));

  test('türler', () {
    expect(
      classifyError(Exception('SocketException: Failed host lookup')),
      ErrorKind.offline,
    );
    expect(
      classifyError(Exception('ClientException: Failed to fetch')),
      ErrorKind.offline,
    );
    expect(classifyError(TimeoutException('x')), ErrorKind.timeout);
    expect(
      classifyError(
        FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
      ),
      ErrorKind.permission,
    );
    expect(
      classifyError(
        FirebaseException(plugin: 'firebase_storage', code: 'unavailable'),
      ),
      ErrorKind.offline,
    );
    expect(classifyError(Exception('429 Too Many Requests')), ErrorKind.quota);
    expect(
      classifyError(UnsupportedError('RawReceivePort')),
      ErrorKind.unsupported,
    );
    expect(
      classifyError(MissingPluginException('getTemporaryDirectory')),
      ErrorKind.unsupported,
    );
    expect(classifyError(Exception('File too large')), ErrorKind.tooLarge);
    expect(
      classifyError(StateError('Bad state: no element')),
      ErrorKind.unknown,
    );
  });

  test('metin: ham ileti görünmez, günlüğe yazılır', () {
    final before = ErrorLog.entries.length;
    final text = friendlyError(l10n, UnsupportedError('RawReceivePort'));
    expect(text, l10n.errorUnsupported);
    expect(text, isNot(contains('RawReceivePort')));
    expect(ErrorLog.entries.length, before + 1);
    expect(ErrorLog.entries.last.message, contains('RawReceivePort'));
  });

  test('bilinmeyen hata genel metin; uygulamanın kendi iletisi korunur', () {
    expect(friendlyError(l10n, StateError('x')), l10n.errorUnknown);
    expect(
      friendlyError(l10n, const AiPolicyException(AiPolicyErrorKind.aiTurnedOff)),
      l10n.aiOffTitle,
    );
  });

  test('bildirim ayrıntısı: yalnız az önceki hatanın bildirimine', () {
    final text = friendlyError(l10n, StateError('iç ayrıntı'));
    final detail = errorDetailFor(l10n.genericError(text));
    expect(detail, isNotNull);
    expect(detail!.raw, contains('iç ayrıntı'));
    expect(detail.label, l10n.copyErrorDetail);
    expect(errorDetailFor('Kopyalandı'), isNull);
  });

  test('F42.3 politika hata türü metni arayüz dilinde, ham ayrıntı yok', () {
    final en = lookupAppLocalizations(const Locale('en'));
    final turkish = RegExp('[çğıöşüÇĞİÖŞÜ]');
    for (final kind in AiPolicyErrorKind.values) {
      final e = AiPolicyException(kind, detail: 'ham-ayrinti');
      final tr = aiErrorText(l10n, e);
      final english = aiErrorText(en, e);
      expect(tr, isNotEmpty);
      expect(tr, isNot(contains('ham-ayrinti')), reason: kind.name);
      expect(english, isNot(contains(turkish)), reason: kind.name);
    }
  });

  test('F36.5 yapay zekâ hatası: kendi iletisi ÖNEKSİZ, ham hata kalıplı', () {
    const own = AiPolicyException(AiPolicyErrorKind.aiTurnedOff);
    expect(aiErrorText(l10n, own), l10n.aiOffTitle);
    expect(
      aiErrorText(l10n, Exception('SocketException: Failed host lookup')),
      l10n.aiError(l10n.errorOffline),
    );
  });
}
