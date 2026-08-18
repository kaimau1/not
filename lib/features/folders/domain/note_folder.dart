import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Notları kategorilere ayıran klasör (gelişmiş etiket). Firestore'da
/// users/{uid}/folders/{id} altında tutulur; notlar klasöre `folderId`
/// alanıyla bağlanır.
class NoteFolder {
  const NoteFolder({
    required this.id,
    required this.name,
    this.icon = defaultIcon,
    this.hidden = false,
    this.createdAt,
    required this.ownerId,
    this.sharedWith = const [],
  });

  final String id;
  final String name;

  /// [iconChoices] içindeki simge kimliği; bilinmeyen değerler varsayılan
  /// sade klasör simgesine düşer.
  final String icon;

  /// Gizli klasör: çipi ana ekranda görünmez ve içindeki notlar not
  /// duvarına/aramaya girmez. Kullanıcı ⋮ → "Gizli klasörler" ile kimlik
  /// doğrulayarak o oturum boyunca görünür kılar (kalıcı bir "açık" hâli
  /// tutulmaz — uygulama yeniden açıldığında yine gizlidir).
  ///
  /// Bu bir ŞİFRELEME değildir: not içeriği Firestore'da düz durur, amaç
  /// omuz üstünden bakan birinin notu görmemesi. Gerçek koruma isteyen not
  /// başına "Kilitle" (biyometrik) seçeneğini kullanır.
  final bool hidden;
  final DateTime? createdAt;

  /// Klasörün GERÇEK sahibi — belge her zaman `users/{ownerId}/folders/{id}`
  /// altında yaşar. Kendi klasörlerimde bu her zaman benim uid'im; PAYLAŞILAN
  /// bir klasörde (bkz. [sharedWith]) beni davet eden kişinin uid'i. Notların
  /// hangi koleksiyondan okunacağını/yazılacağını bu alan belirler — klasör
  /// paylaşılsa da notlar SAHİBİNİN altında kalır, kopyalanmaz.
  final String ownerId;

  /// Kullanıcı isteği 2026-08-18: "ortak notlar klasörü — kişiler bağlanır,
  /// notları ortak görür." Bu klasöre erişimi olan (sahip DIŞINDAKİ)
  /// arkadaşların uid listesi; boşsa klasör özeldir. Erişim OKUMA+YAZMA'dır
  /// (bkz. firestore.rules) — rol ayrımı (yalnız okuyan/yazan) bu turun
  /// kapsamı dışında bırakıldı.
  final List<String> sharedWith;

  bool get isShared => sharedWith.isNotEmpty;

  /// Varsayılan sade simge.
  static const String defaultIcon = 'folder';

  /// Kullanıcının seçebileceği simgeler. Kimlikler Firestore'da saklandığı
  /// için değiştirilmemeli; yeni simge eklemek serbesttir.
  static const Map<String, IconData> iconChoices = {
    'folder': Icons.folder_outlined,
    'work': Icons.work_outline,
    'home': Icons.home_outlined,
    'school': Icons.school_outlined,
    'shopping': Icons.shopping_cart_outlined,
    'health': Icons.favorite_outline,
    'money': Icons.payments_outlined,
    'idea': Icons.lightbulb_outline,
    'book': Icons.menu_book_outlined,
    'travel': Icons.flight_outlined,
    'food': Icons.restaurant_outlined,
    'music': Icons.music_note_outlined,
    'fitness': Icons.fitness_center_outlined,
    'pets': Icons.pets_outlined,
    'star': Icons.star_outline,
    'lock': Icons.lock_outline,
  };

  IconData get iconData => iconChoices[icon] ?? Icons.folder_outlined;

  NoteFolder copyWith({
    String? name,
    String? icon,
    bool? hidden,
    List<String>? sharedWith,
  }) => NoteFolder(
    id: id,
    name: name ?? this.name,
    icon: icon ?? this.icon,
    hidden: hidden ?? this.hidden,
    createdAt: createdAt,
    ownerId: ownerId,
    sharedWith: sharedWith ?? this.sharedWith,
  );

  /// [ownerId] verilmezse dokümanın YOLUNDAN çıkarılır
  /// (`users/{ownerId}/folders/{id}`) — kendi klasörlerimde bu zaten benim
  /// uid'im olur; paylaşılan bir klasörü sahibinin koleksiyonundan okurken de
  /// (bkz. `sharedFolderRefsProvider`) doğru sahip otomatik çözülür.
  factory NoteFolder.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    String? ownerId,
  }) {
    final map = doc.data() ?? const <String, dynamic>{};
    return NoteFolder(
      id: doc.id,
      name: map['name'] as String? ?? '',
      icon: map['icon'] as String? ?? defaultIcon,
      hidden: map['hidden'] as bool? ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      ownerId: ownerId ?? doc.reference.parent.parent?.id ?? '',
      sharedWith: [
        for (final uid in (map['sharedWith'] as List<dynamic>? ?? const []))
          uid.toString(),
      ],
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'icon': icon,
    'hidden': hidden,
    'ownerId': ownerId,
    'sharedWith': sharedWith,
    'createdAt': createdAt != null
        ? Timestamp.fromDate(createdAt!)
        : FieldValue.serverTimestamp(),
  };
}
