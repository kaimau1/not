import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/link_text.dart';
import 'package:notlar/features/ai/data/assistant_service.dart';
import 'package:notlar/features/notes/data/reminder_service.dart';
import 'package:notlar/features/notes/domain/due_items.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/notes_providers.dart';

/// GÜVENLİK BEKÇİLERİ (Faz 71, `docs/guvenlik_denetimi.md`). Saldırı yüzeyini
/// büyüten bir değişiklik (yeni dışa açık bileşen, koşulsuz kural, gevşek CI
/// yetkisi, kilitli notu sızdıran yol) burada KIRMIZI olur — bilerek
/// yapıldıysa liste/test aynı commit'te güncellenir ve denetim dosyasına
/// gerekçesi yazılır.
String _oku(String yol) => File(yol).readAsStringSync();

/// Manifestteki `android:exported="true"` bileşen adları.
Set<String> _disaAcik(String yol) {
  final etiket = RegExp(
    r'<(activity|activity-alias|service|receiver|provider)\b[^>]*>',
  );
  final ad = RegExp(r'android:name="([^"]+)"');
  return {
    for (final m in etiket.allMatches(_oku(yol)))
      if (m.group(0)!.contains('android:exported="true"'))
        ad.firstMatch(m.group(0)!)!.group(1)!,
  };
}

Note _kilitli({DateTime? reminderAt}) => Note(
  id: 'k',
  type: NoteType.text,
  title: 'Banka',
  body: 'gizlimetin 1234',
  locked: true,
  reminderAt: reminderAt,
  updatedAt: DateTime(2026, 11, 11),
);

void main() {
  group('Android yüzeyi', () {
    test('dışa açık bileşen listesi sabit (F71.4)', () {
      expect(_disaAcik('android/app/src/main/AndroidManifest.xml'), {
        '.MainActivity',
        // Ana ekran widget'ları: sistem yayınını almak için açık olmak zorunda.
        '.NotlarWidgetProvider',
        '.VoiceWidgetProvider',
        '.QuickActionsWidgetProvider',
        '.TodayWidgetProvider',
        '.QuickNoteWidgetProvider',
        // AppFunctions: BIND_APP_FUNCTION_SERVICE (yalnız sistem bağlanır).
        '.AjanServisi',
      });
      // Kişisel köprü: imza|knownSigner izniyle korunur.
      expect(_disaAcik('android/app/src/kisisel/AndroidManifest.xml'), {
        '.HaritaNotAlici',
      });
    });

    test('açık servis ve köprü alıcısı izinle korunur; yedekleme kapalı', () {
      final main = _oku('android/app/src/main/AndroidManifest.xml');
      expect(main, contains('android.permission.BIND_APP_FUNCTION_SERVICE'));
      expect(main, contains('android:allowBackup="false"'));
      final kisisel = _oku('android/app/src/kisisel/AndroidManifest.xml');
      expect(
        kisisel,
        contains('android:permission="dev.kaimau.notlar.izin.ASISTAN"'),
      );
      expect(kisisel, contains('signature|knownSigner'));
    });

    test('FileProvider yalnız önbelleği sunar', () {
      final yollar = RegExp(
        r'<([a-z-]+-path)\b',
      ).allMatches(_oku('android/app/src/main/res/xml/provider_paths.xml'));
      expect({for (final m in yollar) m.group(1)}, {'cache-path'});
    });
  });

  group('Kurallar', () {
    test('koşulsuz izin yalnız config okumasında (F71.8)', () {
      for (final dosya in ['firestore.rules', 'storage.rules']) {
        final kosulsuz = [
          for (final satir in _oku(dosya).split('\n'))
            if (RegExp(r'allow\b[^;]*:\s*if\s+true\s*;').hasMatch(satir))
              satir.trim(),
        ];
        expect(
          kosulsuz,
          dosya == 'firestore.rules' ? ['allow read: if true;'] : isEmpty,
          reason: dosya,
        );
      }
      // O tek satır `config` eşleşmesinin içinde ve yazma kapalı.
      expect(
        _oku('firestore.rules'),
        matches(
          RegExp(
            r'match /config/\{docId\} \{\s*allow read: if true;\s*allow write: if false;',
          ),
        ),
      );
    });
  });

  group('CI', () {
    final akis = _oku('.github/workflows/build.yml');

    test('pull_request_target yok, varsayılan yetki salt okunur (F71.3)', () {
      expect(akis, isNot(contains('pull_request_target')));
      expect(akis, contains('\npermissions:\n  contents: read\n'));
    });

    test('üçüncü taraf action commit SHA\'sına sabit', () {
      final kullanim = RegExp(r'uses:\s*(\S+)@(\S+)').allMatches(akis);
      expect(kullanim, isNotEmpty);
      for (final m in kullanim) {
        if (m.group(1)!.startsWith('actions/')) continue; // GitHub'ın kendisi
        expect(
          m.group(2),
          matches(RegExp(r'^[0-9a-f]{40}$')),
          reason: '${m.group(1)} etikete değil commit SHA\'sına sabitlenmeli',
        );
      }
    });

    test('sır günlüğe basılmaz (echo/printf ile stdout\'a)', () {
      for (final satir in akis.split('\n')) {
        if (!satir.contains(r'${{ secrets.')) continue;
        final basar =
            RegExp(r'^\s*(echo|printf)\b').hasMatch(satir) &&
            !satir.contains('>');
        expect(basar, isFalse, reason: satir.trim());
      }
    });
  });

  test('web: uygulama başka sitenin çerçevesine alınamaz (F71.5)', () {
    final basliklar = _oku('web/_headers');
    expect(basliklar, contains('X-Frame-Options: DENY'));
    expect(basliklar, contains("frame-ancestors 'none'"));
  });

  test('bağlantı açıcı yalnız http, https ve mailto açar (F71.4)', () {
    expect(linkUri('ornek.com/a').toString(), 'https://ornek.com/a');
    expect(linkUri('http://ornek.com')?.scheme, 'http');
    expect(linkUri('ali@ornek.com')?.scheme, 'mailto');
    expect(linkUri('mailto:ali@ornek.com')?.scheme, 'mailto');
    for (final kotu in [
      'intent://x#Intent;scheme=http;package=com.kotu;end',
      'file:///data/data/dev.kaimau.notlar/shared_prefs/x.xml',
      'content://com.android.contacts/contacts/1',
      'javascript://%0aalert(1)',
      'notlar://new?type=text',
      'baskauygulama://odeme?tutar=1',
      '',
    ]) {
      expect(linkUri(kotu), isNull, reason: kotu);
    }
  });

  // Diğer yolların bekçileri kendi testlerinde: kart (card_preview_test),
  // açılış anlık görüntüsü (home_snapshot_test), widget
  // (today_widget_payload_test), AI getirme (notes_chat_retrieval_test,
  // related_notes_test, note_similarity_test), paylaşım (share_target_test),
  // çalışma kartları (study_cards_test), çöp analizi (trash_analysis_test).
  group('kilitli not görünmez (F71.6)', () {
    test('arama: gövdeden bulunmaz, kesit vermez', () {
      expect(noteMatchesQuery(_kilitli(), 'gizlimetin'), isFalse);
      expect(bodySearchMatch(_kilitli(), 'gizlimetin'), isNull);
    });

    test('zamanı geçmiş hatırlatıcı şeridi: başlık yerine genel ad', () {
      final liste = dueItems(
        notes: [_kilitli(reminderAt: DateTime(2026, 11, 10))],
        tasks: const [],
        now: DateTime(2026, 11, 11),
        lockedTitle: 'Kilitli not',
      );
      expect(liste.single.title, 'Kilitli not');
    });

    test('hatırlatıcı bildirimi: başlık ve gövde kilit ekranına çıkmaz', () {
      final (baslik, onizleme) = reminderNotificationText(
        _kilitli(),
        untitled: 'Başlıksız',
        locked: 'Kilitli not',
      );
      expect(baslik, 'Kilitli not');
      expect(onizleme, isEmpty);
      // Kilit açılıp kapanınca bildirim yeniden planlanır (imza değişir).
      expect(
        ReminderService.signatureForTest(_kilitli()),
        isNot(ReminderService.signatureForTest(_kilitli().copyWith(locked: false))),
      );
    });

    test('AI bağlamı: ne "tüm notlar"da ne "alakalı"da', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final baglam = c
          .read(assistantServiceProvider)
          .buildNotesContext([_kilitli()], relevant: [_kilitli()]);
      expect(baglam, isNot(contains('gizlimetin')));
      expect(baglam, isNot(contains('Banka')));
    });
  });
}
