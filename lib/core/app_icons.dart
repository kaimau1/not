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
}
