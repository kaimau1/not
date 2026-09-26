import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Paylaşılan bir klasörde bir kişinin YETKİSİ (kullanıcı isteği 2026-08-18:
/// "klasör sahibi paylaşılan klasörde yetki belirleyebilsin yazma, okuma veya
/// her ikisi şeklinde").
///
/// [write] tek başına "öneri kutusu"dur: kişi klasöre kendi notunu bırakır
/// ama içerideki notları GÖREMEZ. Tuhaf görünse de kuralın doğal ikinci
/// yarısı bu (okuma ve yazma Firestore'da ayrı izinler) ve kullanıcı üç
/// seçeneği açıkça istedi.
enum FolderRole {
  read('read'),
  write('write'),
  both('both');

  const FolderRole(this.id);

  final String id;

  bool get canRead => this != FolderRole.write;
  bool get canWrite => this != FolderRole.read;

  /// Bilinmeyen/eksik değer [both]'a düşer: rol alanı eklenmeden ÖNCE
  /// paylaşılmış klasörlerde herkes okuyup yazıyordu ve güncelleme onların
  /// erişimini sessizce kesmemeli (kural tarafı da aynı varsayılanı kullanır,
  /// bkz. firestore.rules → folderRole).
  static FolderRole fromId(String? id) =>
      FolderRole.values.firstWhere((r) => r.id == id, orElse: () => both);
}

/// Notları kategorilere ayıran klasör (gelişmiş etiket). Firestore'da
/// users/{uid}/folders/{id} altında tutulur; notlar klasöre `folderId`
/// alanıyla bağlanır.
class NoteFolder {
  const NoteFolder({
    required this.id,
    required this.name,
    this.icon = defaultIcon,
    this.hidden = false,
    this.color,
    this.order,
    this.createdAt,
    required this.ownerId,
    this.sharedWith = const [],
    this.pending = const [],
    this.roles = const {},
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

  /// [accentPalette] dizini; null = kimlikten türetilen OTOMATİK renk
  /// (bkz. [folderAccent]). Kullanıcı isteği 2026-09-23 ("klasörlerin
  /// görünümünden memnun değilim"): altı klasör aynı bej blokla yan yana
  /// duruyor, hiçbiri bakışta ayırt edilmiyordu. Renk klasörü tanıtır.
  final int? color;

  /// ELLE SIRALAMADAKİ yeri (küçük önce). null = hiç elle sıralanmamış;
  /// böyle klasörler elle sıralı listenin SONUNA ada göre dizilir (bkz.
  /// `sortFolders`). Kullanıcı isteği 2026-09-26: "klasör sıralaması
  /// ayarlama". Firestore'da durur ki sıra her cihazda aynı olsun.
  final int? order;
  final DateTime? createdAt;

  /// Klasörün GERÇEK sahibi — belge her zaman `users/{ownerId}/folders/{id}`
  /// altında yaşar. Kendi klasörlerimde bu her zaman benim uid'im; PAYLAŞILAN
  /// bir klasörde (bkz. [sharedWith]) beni davet eden kişinin uid'i. Notların
  /// hangi koleksiyondan okunacağını/yazılacağını bu alan belirler — klasör
  /// paylaşılsa da notlar SAHİBİNİN altında kalır, kopyalanmaz.
  final String ownerId;

  /// Kullanıcı isteği 2026-08-18: "ortak notlar klasörü — kişiler bağlanır,
  /// notları ortak görür." Bu klasöre erişimi olan (sahip DIŞINDAKİ)
  /// arkadaşların uid listesi; boşsa klasör özeldir. Her kişinin erişimi
  /// [roles] ile belirlenir (okuma / yazma / her ikisi — bkz. [FolderRole] ve
  /// firestore.rules). Buradaki kişiler daveti KABUL ETMİŞ olanlardır;
  /// yanıtlamayanlar [pending]'de bekler.
  final List<String> sharedWith;

  /// DAVET EDİLMİŞ ama henüz yanıt vermemiş kişiler (kullanıcı isteği
  /// 2026-08-18: "klasör paylaşıldığında kabul et veya reddet seçeneği
  /// olsun"). Davetli kabul edene kadar klasöre HİÇBİR erişimi yoktur;
  /// kabul edince kendini buradan düşürüp [sharedWith]'e ekler.
  final List<String> pending;

  /// uid → yetki. Listede olmayan kişi [FolderRole.both] sayılır (bkz.
  /// [FolderRole.fromId]).
  final Map<String, FolderRole> roles;

  bool get isShared => sharedWith.isNotEmpty || pending.isNotEmpty;

  FolderRole roleOf(String uid) => roles[uid] ?? FolderRole.both;

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

  /// Klasör vurgu renkleri — açık ve koyu temada okunur orta tonlar; simge
  /// kutusu, kart şeridi ve çip bu renkten türetilir. Dizin Firestore'da
  /// saklandığı için SIRA DEĞİŞTİRİLMEZ, yalnız sona eklenir.
  static const List<Color> accentPalette = [
    Color(0xFFD9982B), // kehribar
    Color(0xFFE0685C), // mercan
    Color(0xFFD06A95), // gül
    Color(0xFF8E74D0), // mor
    Color(0xFF4F8FD6), // mavi
    Color(0xFF2FA392), // camgöbeği
    Color(0xFF6DA84C), // yeşil
    Color(0xFF7D8799), // arduvaz
  ];

  Color get accent => folderAccent(id, color);

  NoteFolder copyWith({
    String? name,
    String? icon,
    bool? hidden,
    int? color,
    int? order,
    List<String>? sharedWith,
    List<String>? pending,
    Map<String, FolderRole>? roles,
  }) => NoteFolder(
    id: id,
    name: name ?? this.name,
    icon: icon ?? this.icon,
    hidden: hidden ?? this.hidden,
    color: color ?? this.color,
    order: order ?? this.order,
    createdAt: createdAt,
    ownerId: ownerId,
    sharedWith: sharedWith ?? this.sharedWith,
    pending: pending ?? this.pending,
    roles: roles ?? this.roles,
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
      color: (map['color'] as num?)?.toInt(),
      order: (map['order'] as num?)?.toInt(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      ownerId: ownerId ?? doc.reference.parent.parent?.id ?? '',
      sharedWith: [
        for (final uid in (map['sharedWith'] as List<dynamic>? ?? const []))
          uid.toString(),
      ],
      pending: [
        for (final uid in (map['pending'] as List<dynamic>? ?? const []))
          uid.toString(),
      ],
      roles: parseFolderRoles(map['roles']),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'icon': icon,
    'hidden': hidden,
    'color': ?color,
    'order': ?order,
    'ownerId': ownerId,
    'sharedWith': sharedWith,
    'pending': pending,
    'roles': {for (final e in roles.entries) e.key: e.value.id},
    'createdAt': createdAt != null
        ? Timestamp.fromDate(createdAt!)
        : FieldValue.serverTimestamp(),
  };
}

/// Firestore'daki `roles` haritasını çözer. Klasör dokümanı ve paylaşım
/// aynası aynı biçimi taşıdığından ikisi de bunu kullanır.
Map<String, FolderRole> parseFolderRoles(Object? raw) {
  if (raw is! Map) return const {};
  return {
    for (final entry in raw.entries)
      entry.key.toString(): FolderRole.fromId(entry.value?.toString()),
  };
}

/// Klasörün vurgu rengi: seçilmişse [NoteFolder.accentPalette]'teki renk,
/// değilse KİMLİKTEN türetilen sabit bir renk — aynı klasör her cihazda ve
/// her açılışta aynı renkte görünür. Paylaşılan klasörün aynası renk
/// taşımadığı için onlarda da bu türetme kullanılır.
Color folderAccent(String id, [int? color]) {
  const palette = NoteFolder.accentPalette;
  if (color != null && color >= 0 && color < palette.length) {
    return palette[color];
  }
  // String.hashCode oturumdan oturuma değişebilir (Dart garanti vermez);
  // basit ve kararlı bir karakter toplamı.
  var h = 0;
  for (final c in id.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return palette[h % palette.length];
}
