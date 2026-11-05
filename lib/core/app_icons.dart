import 'package:flutter/material.dart';

/// Simge sözlüğü (F16.1, 2026-10-31): TEK SİMGE = TEK ANLAM.
///
/// Aynı işi gösteren her düğme buradan alır; bir simge başka bir iş için
/// kullanılmaz. Sözlüğün okunur hâli `TERIMLER.md` → "Simgeler".
/// `icon_dictionary_test` aşağıdaki çakışmaların geri gelmesini yakalar.
abstract final class AppIcons {
  /// Arşiv (arşivle, Arşiv ekranı). Arşiv kutusu YALNIZ arşiv içindir.
  static const archive = Icons.archive_outlined;
  static const archiveSelected = Icons.archive;
  static const unarchive = Icons.unarchive_outlined;

  /// Gelen ve paylaşılanlar: zarf. `move_to_inbox` arşiv kutusuna çok
  /// benziyordu (Q4).
  static const inbox = Icons.mail_outline;
  static const inboxSelected = Icons.mail;

  /// Defter (sayfalı görünüm, defter kâğıdı).
  static const notebook = Icons.menu_book_outlined;

  /// Kullanım kılavuzu — Defter ile karışmasın diye açık kitap değil.
  static const guide = Icons.help_outline;

  /// Not paketi (.notlar dosyası): sıkıştırılmış dosya.
  static const notePackage = Icons.folder_zip_outlined;

  /// Kopyala (pano). Çoğalt ile karıştırılmaz.
  static const copy = Icons.content_copy_outlined;

  /// Çoğalt (aynı notun ikinci kopyası).
  static const duplicate = Icons.library_add_outlined;

  /// Görünüm (tema, notun görünümü). Palet YALNIZ görünüm içindir.
  static const appearance = Icons.palette_outlined;

  /// Klasöre taşı. Düz klasör simgesi "Klasörler" bölümünündür.
  static const moveToFolder = Icons.drive_file_move_outline;

  /// Ara (ekranda / notta) — "Notta ara" menüde ve çubukta aynı.
  static const search = Icons.search;

  /// Tam ekran (PDF, sunum, sayfa notu, video aynı simge).
  static const fullscreen = Icons.fullscreen;

  /// Çöpten geri yükle.
  static const restore = Icons.restore_from_trash_outlined;

  /// Kişiler (arkadaşlar).
  static const friends = Icons.people_outline;

  /// Renk seçimi (zemin rengi, sayfa rengi, özel renk, renge göre sırala).
  static const color = Icons.format_color_fill;

  // SES KAPILARI (TUTARLILIK F42.1, K7): her kapı aynı ad + aynı simge.

  /// Dikte: konuştukça yazar, AI'sız. Ana ekran mikrofonu bu (rozetsiz).
  static const dictation = Icons.mic;

  /// AI sesli not: ✨ mikrofon. Bileşik simge, [glyph] ile çizilir.
  static const aiVoiceNote = Icons.mic_none_rounded;

  /// Ses kaydı ve ses eki: dalga.
  static const voiceRecord = Icons.graphic_eq;

  /// Sesli dinle (notu, belgeyi okutma): kulaklık.
  static const listen = Icons.headphones_outlined;

  /// Sesli komut (sohbette konuşarak sor).
  static const voiceCommand = Icons.settings_voice_outlined;

  /// `IconData` alan satırların tek çizimi: [aiVoiceNote] köşesinde ✨ taşır,
  /// gerisi düz [Icon]. Satır API'leri bu yüzden `IconData` kalabildi.
  static Widget glyph(IconData icon, {double? size, Color? color}) {
    if (icon != aiVoiceNote) return Icon(icon, size: size, color: color);
    final side = size ?? 24;
    return SizedBox.square(
      dimension: side,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(dictation, size: side, color: color),
          Positioned(
            top: -side * 0.12,
            right: -side * 0.2,
            child: Icon(Icons.auto_awesome, size: side * 0.5, color: color),
          ),
        ],
      ),
    );
  }
}
