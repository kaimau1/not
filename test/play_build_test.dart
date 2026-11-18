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
import 'package:notlar/features/ai/data/antalia/antalia_engine.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/presentation/editor/attachment_actions.dart';
import 'package:notlar/firebase_options.dart';

void main() {
  const on = !PlayBuild.enabled;

  test('bayrak kapalıyken (kişisel APK) bütün özellikler açık', () {
    expect(PlayBuild.selfUpdate, on);
    expect(PlayBuild.gmail, on);
    expect(PlayBuild.placeReminders, on);
    expect(PlayBuild.antaliaVoice, on);
    expect(PlayBuild.youtubeAutoPip, on);
    // AI-S1 (PLAN §1.6): Play'den kalkan AI yetenekleri kişisel APK'da AYNEN.
    expect(PlayBuild.aiPodcast, on);
    expect(PlayBuild.aiVoice, on);
    expect(PlayBuild.videoNote, on);
    // PL3: rıza ekranı yalnız Play'de (kişisel APK'da sorulmaz).
    expect(PlayBuild.aiConsent, !on);
  });

  test('video → not ek menüsünde yalnız kişisel APK\'da (AI-S1)', () {
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
    expect(actions.contains(AttachmentAction.videoToNote), on);
  });

  // AI-S1 "Play'den kalkanlar": her giriş noktası kendi kapısını okur.
  // E-postadan not (`fromEmail`) Gmail ekranında — [PlayBuild.gmail] kapısı.
  test('AI-S1 kapıları giriş noktalarına bağlı', () {
    const wiring = [
      ('lib/features/ai/presentation/listen_screen.dart', 'PlayBuild.aiPodcast'),
      ('lib/features/ai/data/speech_service.dart', 'PlayBuild.aiVoice'),
      ('lib/features/settings/settings_providers.dart', 'PlayBuild.aiVoice'),
      (
        'lib/features/settings/presentation/settings_sections/settings_voice.dart',
        'PlayBuild.aiVoice',
      ),
      (
        'lib/features/notes/presentation/editor/attachment_actions.dart',
        'PlayBuild.videoNote',
      ),
      (
        'lib/features/notes/data/video_note_transcripts.dart',
        'PlayBuild.videoNote',
      ),
    ];
    for (final (file, gate) in wiring) {
      expect(File(file).readAsStringSync(), contains(gate), reason: file);
    }
  });

  test('Android derlemesinde güncelleyici ve Antalia kapıya bağlı', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    expect(AppUpdate.supported, on);
    expect(AntaliaModelFiles.supported, on);
  });

  // Kapı bir dosyadan kaldırılırsa Play derlemesine o özellik sızar: her
  // özelliğin giriş noktası kendi sabitini okumalı.
  test('her kapı giriş noktasına bağlı', () {
    const wiring = {
      'lib/core/app_update.dart': 'PlayBuild.selfUpdate',
      'lib/features/gmail/data/gmail_auth.dart': 'PlayBuild.gmail',
      'lib/app/router.dart': 'PlayBuild.gmail',
      'lib/features/notes/data/place_reminders.dart':
          'PlayBuild.placeReminders',
      'lib/features/ai/data/antalia/antalia_engine.dart':
          'PlayBuild.antaliaVoice',
      'lib/features/settings/presentation/settings_sections/settings_voice.dart':
          'PlayBuild.antaliaVoice',
      'lib/features/settings/settings_providers.dart': 'PlayBuild.antaliaVoice',
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
    expect(gradle, contains('applicationId = playAppId ?: "dev.kaimau.notlar"'));
    expect(gradle, contains('NOTLAR_PLAY_APP_ID'));
    expect(gradle, contains('src/release/google-services.json'));
    expect(gradle, contains('if (play) manifest.srcFile("src/play/AndroidManifest.xml")'));
    final playManifest =
        File('android/app/src/play/AndroidManifest.xml').readAsStringSync();
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
