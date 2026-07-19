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
    this.createdAt,
  });

  final String id;
  final String name;

  /// [iconChoices] içindeki simge kimliği; bilinmeyen değerler varsayılan
  /// sade klasör simgesine düşer.
  final String icon;
  final DateTime? createdAt;

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

  NoteFolder copyWith({String? name, String? icon}) => NoteFolder(
    id: id,
    name: name ?? this.name,
    icon: icon ?? this.icon,
    createdAt: createdAt,
  );

  factory NoteFolder.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data() ?? const <String, dynamic>{};
    return NoteFolder(
      id: doc.id,
      name: map['name'] as String? ?? '',
      icon: map['icon'] as String? ?? defaultIcon,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'icon': icon,
    'createdAt': createdAt != null
        ? Timestamp.fromDate(createdAt!)
        : FieldValue.serverTimestamp(),
  };
}
