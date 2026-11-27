// PLAY DERLEMESİ BEKÇİSİ (PLAN §1.5 PL1).
//
// Bayraksız (`flutter test`) koşu: kişisel APK bugünkü gibi — bütün kapılar
// açık. `--dart-define=NOTLAR_PLAY=true` ile koşulunca aynı test kapıların
// kapandığını doğrular (beklentiler `PlayBuild.enabled`'a göre).
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/app_links.dart';
import 'package:notlar/core/app_update.dart';
import 'package:notlar/core/play_build.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/presentation/editor/attachment_actions.dart';
import 'package:notlar/firebase_options.dart';

void main() {
  const on = !PlayBuild.enabled;

  test('bayrak kapalıyken (kişisel APK) bütün özellikler açık', () {
    expect(PlayBuild.selfUpdate, on);
    expect(PlayBuild.placeReminders, on);
    expect(PlayBuild.youtubeAutoPip, on);
    // PL3: rıza ekranı yalnız Play'de (kişisel APK'da sorulmaz).
    expect(PlayBuild.aiConsent, !on);
  });

  test('video → not Faz 1 ile her iki derlemede de menüden kalktı', () {
    const video = Attachment(
      id: 'v',
      kind: AttachmentKind.video,
      fileName: 'v.mp4',
      mimeType: 'video/mp4',
    );
    final actions = attachmentActionsFor(
      video,
      AttachmentSurface.strip,
      const AttachmentCaps(videoToNote: true),
    );
    expect(actions.contains(AttachmentAction.videoToNote), isFalse);
  });

  test('Android derlemesinde güncelleyici kapıya bağlı', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    expect(AppUpdate.supported, on);
  });

  // Kapı bir dosyadan kaldırılırsa Play derlemesine o özellik sızar: her
  // özelliğin giriş noktası kendi sabitini okumalı.
  test('her kapı giriş noktasına bağlı', () {
    const wiring = {
      'lib/core/app_update.dart': 'PlayBuild.selfUpdate',
      'lib/features/notes/data/place_reminders.dart':
          'PlayBuild.placeReminders',
      'lib/features/notes/presentation/viewers/youtube_viewer.dart':
          'PlayBuild.youtubeAutoPip',
    };
    for (final e in wiring.entries) {
      expect(File(e.key).readAsStringSync(), contains(e.value), reason: e.key);
    }
  });

  // PL1 yerel yarısı + PL13 çeşit: Play paketi kişisel kimliğe/projeye
  // bağlanamaz, konum izni pakette yok; kişisel kimlik değişmez.
  test('Gradle Play çeşidi: ayrı kimlik, ayrı Firebase, konum izni yok', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    expect(
      gradle,
      contains('applicationId = playAppId ?: "dev.kaimau.notlar"'),
    );
    expect(gradle, contains('NOTLAR_PLAY_APP_ID'));
    expect(gradle, contains('src/release/google-services.json'));
    expect(
      gradle,
      contains('if (play) manifest.srcFile("src/play/AndroidManifest.xml")'),
    );
    final playManifest = File('android/app/src/play/AndroidManifest.xml')
        .readAsStringSync();
    for (final p in [
      'ACCESS_FINE_LOCATION',
      'ACCESS_COARSE_LOCATION',
      'ACCESS_BACKGROUND_LOCATION',
      '.PlaceReminderReceiver',
      '.PlaceBootReceiver',
    ]) {
      expect(
        RegExp('"[^"]*${RegExp.escape(p)}" tools:node="remove"')
            .hasMatch(playManifest),
        isTrue,
        reason: p,
      );
    }
  });

  // Antalia (ONNX) 2026-11-27'de kalktı: Play kuklası ve ses motoru
  // seçicisi de gitti. Eklenti bir daha sızmasın.
  test('ONNX eklentisi bağımlılıklarda yok', () {
    expect(File('pubspec.yaml').readAsStringSync(), isNot(contains('onnx')));
    expect(Directory('lib/features/ai/data/antalia').existsSync(), isFalse);
  });

  test('Play derlemesi kişisel Firebase projesine bağlanmaz (PL13)', () {
    if (PlayBuild.enabled) {
      expect(DefaultFirebaseOptions.play.projectId, isNot('notlar-kaimau'));
    } else {
      expect(DefaultFirebaseOptions.android.projectId, 'notlar-kaimau');
      // Bayraksız koşuda Play değerleri tanımsız → kurulum ekranı.
      expect(DefaultFirebaseOptions.play.apiKey, isEmpty);
    }
    expect(AppLinks.privacy, endsWith('/gizlilik.html'));
    expect(AppLinks.deleteAccount, endsWith('/hesap-silme.html'));
  });
}
