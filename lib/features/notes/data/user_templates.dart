import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/rich_text.dart';
import '../../settings/settings_providers.dart';
import '../domain/archive_template.dart';
import '../domain/note.dart';
import '../domain/note_type.dart';

/// **KENDİ ŞABLONUM** (kullanıcı isteği 2026-09-29: "listeler şablonlar
/// olmamış, daha gelişmiş özellikler olmalı").
///
/// Hazır şablonlar herkes için aynı; oysa en sık kullanılan "şablon"
/// kullanıcının kendi haftalık listesi, kendi toplantı düzeni. Bunun tek yolu
/// notu ÇOĞALTMAKTI — çoğaltılan not işaretli maddeleriyle, eski tarihiyle,
/// eski yerinde doğuyordu. Artık bir not "Şablon olarak kaydet" ile saklanır;
/// şablondan doğan not TERTEMİZ başlar (maddeler işaretsiz).
///
/// Neler saklanır: tip, başlık, gövde ve madde METİNLERİ. Ekler, renk,
/// etiket, hatırlatıcı SAKLANMAZ — şablon içeriğin iskeletidir; ek
/// dosyaları kopyalamak her kullanımda yükleme demekti.
///
/// Cihaz yerel (SharedPreferences), çoğaltmayla aynı gerekçe: şablon bir
/// çalışma alışkanlığıdır, buluta yeni bir koleksiyon + kural açmak
/// (firebase deploy) bu iş için fazla.
@immutable
class UserTemplate {
  const UserTemplate({
    required this.id,
    required this.name,
    required this.type,
    this.title = '',
    this.body = '',
    this.items = const [],
  });

  final String id;

  /// Galeride görünen ad (varsayılan: notun başlığı).
  final String name;
  final NoteType type;
  final String title;
  final String body;
  final List<String> items;

  bool get isList => type == NoteType.checklist || type == NoteType.ordered;

  UserTemplate copyWith({
    String? id,
    String? name,
    NoteType? type,
    String? title,
    String? body,
    List<String>? items,
  }) => UserTemplate(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    title: title ?? this.title,
    body: body ?? this.body,
    items: items ?? this.items,
  );

  /// Nottan şablon: boş maddeler atılır, işaretler sıfırlanır.
  factory UserTemplate.fromNote(Note note, {required String id, String? name}) {
    final title = note.displayTitle.trim();
    return UserTemplate(
      id: id,
      name: (name ?? '').trim().isNotEmpty ? name!.trim() : title,
      type: note.type,
      title: note.title,
      body: note.body,
      items: [
        for (final i in note.items)
          if (i.text.trim().isNotEmpty) i.text,
      ],
    );
  }

  factory UserTemplate.fromMap(Map<String, dynamic> map) => UserTemplate(
    id: map['id'] as String? ?? '',
    name: map['name'] as String? ?? '',
    type: NoteType.fromId(map['type'] as String?),
    title: map['title'] as String? ?? '',
    body: map['body'] as String? ?? '',
    items: [for (final e in (map['items'] as List?) ?? const []) '$e'],
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'type': type.id,
    if (title.isNotEmpty) 'title': title,
    if (body.isNotEmpty) 'body': body,
    if (items.isNotEmpty) 'items': items,
  };
}

/// Bir notun şablon olarak saklanabilir tipi var mı? Belge (PDF/sunum) ve
/// arşiv defteri notlarının içeriği EKLERDE — iskeleti anlamsız kalır.
bool canSaveAsTemplate(Note note) =>
    note.type == NoteType.text ||
    note.type == NoteType.checklist ||
    note.type == NoteType.ordered;

final userTemplatesProvider =
    NotifierProvider<UserTemplatesNotifier, List<UserTemplate>>(
      UserTemplatesNotifier.new,
    );

class UserTemplatesNotifier extends Notifier<List<UserTemplate>> {
  static const _key = 'user_templates_v1';

  /// Galeri bir levha; sınırsız şablon hem yavaşlatır hem aranmaz olur.
  static const maxTemplates = 60;

  @override
  List<UserTemplate> build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(_key);
    return decodeUserTemplates(raw);
  }

  void _save(List<UserTemplate> next) {
    state = next;
    ref
        .read(sharedPreferencesProvider)
        .setString(_key, encodeUserTemplates(next));
  }

  /// En yeni başta; aynı kimlik varsa yerini alır.
  void add(UserTemplate template) => _save(
    [
      template,
      for (final t in state)
        if (t.id != template.id) t,
    ].take(maxTemplates).toList(),
  );

  /// Düzenlenen şablon YERİNDE güncellenir (sırası değişmez); yoksa başa
  /// eklenir.
  void update(UserTemplate template) {
    if (!state.any((t) => t.id == template.id)) return add(template);
    _save([for (final t in state) t.id == template.id ? template : t]);
  }

  /// Kopya hemen aslının ARKASINA girer ("Haftalık market (2)").
  UserTemplate duplicate(String id, {required String newId}) {
    final source = state.firstWhere((t) => t.id == id);
    final copy = source.copyWith(id: newId, name: '${source.name} (2)');
    final next = <UserTemplate>[];
    for (final t in state) {
      next.add(t);
      if (t.id == id) next.add(copy);
    }
    _save(next.take(maxTemplates).toList());
    return copy;
  }

  void rename(String id, String name) {
    final clean = name.trim();
    if (clean.isEmpty) return;
    _save([for (final t in state) t.id == id ? t.copyWith(name: clean) : t]);
  }

  void remove(String id) => _save([
    for (final t in state)
      if (t.id != id) t,
  ]);
}

/// Kayıt biçimi (saf, testli). Bozuk kayıt sessizce BOŞ liste olur: tek bir
/// bozuk satır şablon galerisini hiç açılmaz hâle getirmemeli.
List<UserTemplate> decodeUserTemplates(String? raw) {
  if (raw == null || raw.isEmpty) return const [];
  try {
    final list = jsonDecode(raw) as List;
    return [
      for (final e in list)
        if (e is Map) UserTemplate.fromMap(Map<String, dynamic>.from(e)),
    ].where((t) => t.id.isNotEmpty).toList();
  } catch (_) {
    return const [];
  }
}

String encodeUserTemplates(List<UserTemplate> templates) =>
    jsonEncode([for (final t in templates) t.toMap()]);

/// Yeni şablon kimliği (zaman damgası, 36 tabanında).
String newUserTemplateId() =>
    DateTime.now().microsecondsSinceEpoch.toRadixString(36);

/// **ŞABLON DÜZENLEYİCİSİNİN YAZI BİÇİMİ** (saf, testli).
///
/// Şablon gövdesi notun biçim işaretlerini taşır (başlık = satırın tamamına
/// boy + kalın, bkz. [setLineHeading]). Düzenleyici bunları ham göstermez:
/// büyük başlık satırı `# `, alt başlık `## ` ile başlar — yazması da
/// okuması da kolay, klavyede özel düğme gerekmez. Diğer satırların satır
/// içi biçimi düzenleyicide görünmez (yalnız düz metin); düzenleyici gövdeyi
/// DEĞİŞTİRMEDEN kaydederse asıl biçimli gövde korunur.
String templateBodyToEditable(String body) {
  if (body.isEmpty) return '';
  return [
    for (final line in body.split('\n'))
      switch (lineHeadingAt(line, 0)) {
        RichHeading.h1 => '# ${stripRichMarkers(line)}',
        RichHeading.h2 => '## ${stripRichMarkers(line)}',
        RichHeading.normal => stripRichMarkers(line),
      },
  ].join('\n');
}

/// [templateBodyToEditable]'ın tersi: `# ` / `## ` satırları başlık olur.
String editableToTemplateBody(String text) {
  if (text.isEmpty) return '';
  return buildTemplateText([
    for (final line in text.split('\n'))
      if (line.startsWith('## '))
        (text: line.substring(3).trim(), heading: RichHeading.h2)
      else if (line.startsWith('# '))
        (text: line.substring(2).trim(), heading: RichHeading.h1)
      else
        (text: line, heading: RichHeading.normal),
  ]);
}

/// Liste ↔ yazı geçişinde içerik kaybolmasın: maddeler yazıda "• madde"
/// satırı olur, yazının dolu satırları listede madde olur (işaretler ve
/// başlık önekleri düşer).
String itemsToEditableText(List<String> items) =>
    [for (final i in items) '• $i'].join('\n');

List<String> editableTextToItems(String text) => [
  for (final raw in text.split('\n'))
    if (_stripLinePrefix(raw).isNotEmpty) _stripLinePrefix(raw),
];

final _linePrefix = RegExp(r'^\s*(#{1,2} |[•☐] ?|[-*] |\d+[.)] )');

String _stripLinePrefix(String line) =>
    stripRichMarkers(line).replaceFirst(_linePrefix, '').trim();

/// **SON KULLANILAN ŞABLONLAR** — galerinin tepesinde. Hazır şablon için
/// `b:<ad>`, kendi şablonum için `u:<kimlik>`.
final recentTemplatesProvider =
    NotifierProvider<RecentTemplatesNotifier, List<String>>(
      RecentTemplatesNotifier.new,
    );

class RecentTemplatesNotifier extends Notifier<List<String>> {
  static const _key = 'recent_templates';
  static const maxEntries = 4;

  @override
  List<String> build() =>
      ref.watch(sharedPreferencesProvider).getStringList(_key) ?? const [];

  void remember(String key) {
    final next = [
      key,
      for (final k in state)
        if (k != key) k,
    ].take(maxEntries).toList();
    state = next;
    ref.read(sharedPreferencesProvider).setStringList(_key, next);
  }

  void forget(String key) {
    if (!state.contains(key)) return;
    final next = [
      for (final k in state)
        if (k != key) k,
    ];
    state = next;
    ref.read(sharedPreferencesProvider).setStringList(_key, next);
  }
}
