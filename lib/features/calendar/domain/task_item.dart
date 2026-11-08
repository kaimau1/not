import 'package:cloud_firestore/cloud_firestore.dart';

import 'calendar_event.dart' show GoogleLink;
import 'day_key.dart';
import 'recurrence.dart';

/// **GÖREV** — `users/{uid}/tasks/{id}` (TAKVIM_PLANI §3, K1: Firestore'da,
/// Google bağlıysa Google Görevler ile iki yönlü). Alanlar Google Tasks
/// API'siyle birebir; [dueTime], [repeat], [reminders], [starred] ve not
/// bağları yalnız bizde (Google Tasks saat ve tekrar TUTMAZ).
class TaskItem {
  const TaskItem({
    required this.id,
    this.title = '',
    this.notes = '',
    this.listId = '',
    this.parentId = '',
    this.position = '',
    this.due = '',
    this.dueTime = '',
    this.completed = false,
    this.completedAt,
    this.starred = false,
    this.repeat = '',
    this.reminders = const [],
    this.noteId = '',
    this.noteItemId = '',
    this.level = '',
    this.contact = '',
    this.gmailLink = '',
    this.google,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.extras = const {},
  });

  final String id;
  final String title;

  /// Ayrıntı (Google Tasks `notes` — kısa düz metin).
  final String notes;

  /// '' = varsayılan liste ("Görevlerim", [TaskList.defaultId]).
  final String listId;

  /// Alt görevse üst görevin kimliği (tek seviye).
  final String parentId;

  /// Sıra dizesi (küçükten büyüğe); '' en sona.
  final String position;

  /// Son gün `YYYY-MM-DD`; '' = tarihsiz.
  final String due;

  /// `HH:mm`; '' = gün boyu.
  final String dueTime;

  final bool completed;
  final DateTime? completedAt;
  final bool starred;

  /// [Recurrence] dizesi; tamamlanınca [completeTask] sonrakine ilerletir.
  final String repeat;

  /// Son andan ([dueAt]) kaç dakika önce hatırlatılsın.
  final List<int> reminders;

  /// Bağlı not (plan §4).
  final String noteId;

  /// Liste notundaki maddeden üretildiyse maddenin kimliği (K6: tamamlanma
  /// iki yönlü eşlenir; not [noteId]).
  final String noteItemId;

  /// Bildirim önem düzeyi ([ReminderLevel.id]; '' = sık, eski davranış).
  final String level;

  /// Kişi / alıcı (ad ya da e-posta; not içi görev satırı, 2026-11-08).
  final String contact;

  /// Gmail bağlantısı (ileti/konu adresi) — görevden e-postaya dönüş.
  final String gmailLink;

  final GoogleLink? google;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final Map<String, dynamic> extras;

  static const knownKeys = <String>{
    'title',
    'notes',
    'listId',
    'parentId',
    'position',
    'due',
    'dueTime',
    'completed',
    'completedAt',
    'starred',
    'repeat',
    'reminders',
    'noteId',
    'noteItemId',
    'level',
    'contact',
    'gmailLink',
    'google',
    'createdAt',
    'updatedAt',
    'deletedAt',
  };

  /// Saatsiz görevin hatırlatma/sıralama saati.
  static const defaultDueHour = 9;

  DateTime? get dueDay => parseDayKey(due);

  /// Son an: gün + saat (saatsizse [defaultDueHour]).
  DateTime? get dueAt {
    final d = dueDay;
    if (d == null) return null;
    final hm = parseHm(dueTime);
    return DateTime(
      d.year,
      d.month,
      d.day,
      hm?.hour ?? defaultDueHour,
      hm?.minute ?? 0,
    );
  }

  bool get hasTime => parseHm(dueTime) != null;
  bool get repeats => !Recurrence.parse(repeat).isNone && dueDay != null;

  /// Bugünden önceki gün ve tamamlanmamış.
  bool isOverdue(DateTime now) {
    final d = dueDay;
    if (d == null || completed) return false;
    if (hasTime) return dueAt!.isBefore(now);
    return d.isBefore(startOfDay(now));
  }

  TaskItem copyWith({
    String? id,
    String? title,
    String? notes,
    String? listId,
    String? parentId,
    String? position,
    String? due,
    String? dueTime,
    bool? completed,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    bool? starred,
    String? repeat,
    List<int>? reminders,
    String? noteId,
    String? noteItemId,
    String? level,
    String? contact,
    String? gmailLink,
    GoogleLink? google,
    bool clearGoogle = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) => TaskItem(
    id: id ?? this.id,
    title: title ?? this.title,
    notes: notes ?? this.notes,
    listId: listId ?? this.listId,
    parentId: parentId ?? this.parentId,
    position: position ?? this.position,
    due: due ?? this.due,
    dueTime: dueTime ?? this.dueTime,
    completed: completed ?? this.completed,
    completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
    starred: starred ?? this.starred,
    repeat: repeat ?? this.repeat,
    reminders: reminders ?? this.reminders,
    noteId: noteId ?? this.noteId,
    noteItemId: noteItemId ?? this.noteItemId,
    level: level ?? this.level,
    contact: contact ?? this.contact,
    gmailLink: gmailLink ?? this.gmailLink,
    google: clearGoogle ? null : (google ?? this.google),
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    extras: extras,
  );

  factory TaskItem.fromMap(String id, Map<String, dynamic> map) {
    DateTime? ts(String k) => (map[k] as Timestamp?)?.toDate();
    final due = map['due'] as String? ?? '';
    final dueTime = map['dueTime'] as String? ?? '';
    return TaskItem(
      id: id,
      title: map['title'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      listId: map['listId'] as String? ?? '',
      parentId: map['parentId'] as String? ?? '',
      position: map['position'] as String? ?? '',
      due: parseDayKey(due) == null ? '' : due,
      dueTime: parseHm(dueTime) == null ? '' : dueTime,
      completed: map['completed'] == true,
      completedAt: ts('completedAt'),
      starred: map['starred'] == true,
      repeat: map['repeat'] as String? ?? '',
      reminders: [
        for (final r in map['reminders'] as List? ?? const [])
          if (r is num && r >= 0) r.toInt(),
      ],
      noteId: map['noteId'] as String? ?? '',
      noteItemId: map['noteItemId'] as String? ?? '',
      level: map['level'] as String? ?? '',
      contact: map['contact'] as String? ?? '',
      gmailLink: map['gmailLink'] as String? ?? '',
      google: GoogleLink.fromMap(map['google']),
      createdAt: ts('createdAt'),
      updatedAt: ts('updatedAt'),
      deletedAt: ts('deletedAt'),
      extras: unknownKeys(map, knownKeys),
    );
  }

  Map<String, dynamic> toMap() {
    Timestamp? ts(DateTime? d) => d == null ? null : Timestamp.fromDate(d);
    return {
      ...extras,
      'title': title,
      'notes': notes,
      'listId': listId,
      'parentId': parentId,
      'position': position,
      'due': due,
      'dueTime': dueTime,
      'completed': completed,
      'completedAt': ts(completedAt),
      'starred': starred,
      'repeat': repeat,
      'reminders': reminders,
      'noteId': noteId,
      'noteItemId': noteItemId,
      // Boşsa yazılmaz: eski kayıtlar ve yedekler şişmesin.
      if (level.isNotEmpty) 'level': level,
      if (contact.isNotEmpty) 'contact': contact,
      if (gmailLink.isNotEmpty) 'gmailLink': gmailLink,
      if (google != null) 'google': google!.toMap(),
      'createdAt': ts(createdAt),
      'updatedAt': ts(updatedAt),
      'deletedAt': ts(deletedAt),
    };
  }
}

/// Görevi tamamlar. Tekrarlıysa ([TaskItem.repeats]) görev AÇIK kalır ve son
/// günü sonraki oluşa ilerler; tamamlanan oluş [historyId] kimlikli, tekrarsız
/// bir kopya olarak döner (geçmiş — rutin serisi de bundan sayılır, Faz 53).
/// Sonraki oluş bugünden önceyse bugüne/sonrasına atlanır (haftalarca
/// gecikmiş günlük görev tek tikle bugüne gelir, birikmez).
({TaskItem task, TaskItem? history}) completeTask(
  TaskItem task,
  DateTime now, {
  required String historyId,
}) {
  if (!task.repeats) {
    return (
      task: task.copyWith(completed: true, completedAt: now, updatedAt: now),
      history: null,
    );
  }
  final rule = Recurrence.parse(task.repeat);
  final start = task.dueAt!;
  final today = startOfDay(now);
  var after = start;
  if (after.isBefore(today)) {
    after = today.subtract(const Duration(microseconds: 1));
  }
  final next = rule.nextAfter(start, after);
  final history = task.copyWith(
    id: historyId,
    completed: true,
    completedAt: now,
    repeat: '',
    reminders: const [],
    clearGoogle: true,
    createdAt: now,
    updatedAt: now,
  );
  if (next == null) {
    // Dizi bitti (until/count): son oluş tamamlandı, görev kapanır.
    return (
      task: task.copyWith(completed: true, completedAt: now, updatedAt: now),
      history: null,
    );
  }
  // Kalan sayı: count sınırı ilerletilen başlangıçtan yeniden sayılmasın.
  var rest = rule;
  if (rule.count > 0) rest = rule.copyWith(count: rule.count - 1);
  return (
    task: task.copyWith(
      due: dayKey(next),
      repeat: rest.encode(),
      updatedAt: now,
    ),
    history: history,
  );
}

/// **GÖREV LİSTESİ** — `users/{uid}/taskLists/{id}`. Varsayılan liste
/// ([defaultId]) belge olarak var olmak zorunda değil; adı yerelleştirilir.
class TaskList {
  const TaskList({
    required this.id,
    this.title = '',
    this.position = 0,
    this.google,
    this.createdAt,
    this.extras = const {},
  });

  static const defaultId = '';

  final String id;
  final String title;
  final int position;
  final GoogleLink? google;
  final DateTime? createdAt;
  final Map<String, dynamic> extras;

  static const knownKeys = <String>{'title', 'position', 'google', 'createdAt'};

  bool get isDefault => id == defaultId;

  factory TaskList.fromMap(String id, Map<String, dynamic> map) => TaskList(
    id: id,
    title: map['title'] as String? ?? '',
    position: (map['position'] as num?)?.toInt() ?? 0,
    google: GoogleLink.fromMap(map['google']),
    createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    extras: unknownKeys(map, knownKeys),
  );

  Map<String, dynamic> toMap() => {
    ...extras,
    'title': title,
    'position': position,
    if (google != null) 'google': google!.toMap(),
    'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
  };
}

/// Görev sıralaması: tamamlanmamışlar önce; son günü olan önce (erken
/// önce), sonra [TaskItem.position], sonra oluşturma.
int compareTasks(TaskItem a, TaskItem b) {
  if (a.completed != b.completed) return a.completed ? 1 : -1;
  final ad = a.dueAt;
  final bd = b.dueAt;
  if (ad != null && bd != null) {
    final c = ad.compareTo(bd);
    if (c != 0) return c;
  } else if (ad != null || bd != null) {
    return ad != null ? -1 : 1;
  }
  if (a.position != b.position) {
    if (a.position.isEmpty) return 1;
    if (b.position.isEmpty) return -1;
    return a.position.compareTo(b.position);
  }
  final ac = a.createdAt;
  final bc = b.createdAt;
  if (ac != null && bc != null) return ac.compareTo(bc);
  return a.id.compareTo(b.id);
}
