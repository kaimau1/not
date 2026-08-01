import '../../domain/note.dart';

/// Not editörünün "Geri al" yığını.
///
/// NOTUN TAMAMI saklanır, tek tek işlemler değil: her düzenleme yolunun
/// (yazma, madde ekleme/işaretleme/sıralama, görsel taşıma, AI ile değiştirme,
/// renk, etiket) kendi tersini yazması gerekseydi biri unutulduğunda "Geri al"
/// sessizce yanlış iş yapardı. Bir not birkaç KB'dır; tavan da var.
class NoteUndoStack {
  NoteUndoStack({this.limit = 40, this.coalesceWindow = _defaultCoalesce});

  static const _defaultCoalesce = Duration(milliseconds: 900);

  /// Yığın tavanı: bundan eskisi düşer (bellek + "nereye döneceğim" belirsizliği).
  final int limit;

  /// Art arda yazılan harflerin TEK adım sayıldığı süre. Her tuş vuruşu ayrı
  /// adım olsaydı "Geri al" harf harf geri giderdi.
  final Duration coalesceWindow;

  final _entries = <Note>[];
  DateTime? _lastPushAt;

  bool get canUndo => _entries.isNotEmpty;
  int get length => _entries.length;

  /// Notun YAPI parmak izi. Değiştiyse değişiklik yazı değildir (madde
  /// eklendi/işaretlendi, ek geldi/taşındı, renk/etiket değişti) ve zaman
  /// penceresine bakılmadan ayrı bir geri alma adımı hak eder.
  ///
  /// SIRA bilerek dışarıda: öğeler kimliğe göre sıralanıp yazılır. Sebebi
  /// işaretleme akışı — işaretlenen öğe önce yerinde değişir, animasyon
  /// bitince (220 ms) listenin başka bir yerine taşınır. Sıra da parmak izinde
  /// olsaydı bu TEK kullanıcı hareketi iki geri alma adımı üretir ve ilk
  /// "Geri al" öğeyi işaretli hâlde eski yerine koyup durur, kullanıcı ikinci
  /// kez basmak zorunda kalırdı. Elle sıralama ise zaman penceresiyle ayrılır
  /// (sürükleme, bir önceki değişiklikten saniyeler sonra biter).
  static String structureKey(Note n) {
    final items = [for (final i in n.items) '${i.id}:${i.checked}']..sort();
    final attachments = [
      for (final a in n.attachments)
        '${a.id}:${a.displayWidth}:${a.x}:${a.pageY}:${a.asFile}',
    ]..sort();
    return [
      n.type.id,
      n.color.id,
      n.frameColor.id,
      n.tags.join(','),
      n.folderId ?? '',
      ...items,
      ...attachments,
    ].join('|');
  }

  /// [before] durumunu yığına koyar. Süren bir YAZMA dizisiyse (yapı aynı ve
  /// son kayıt [coalesceWindow] içinde) yeni bir adım açılmaz: dizinin
  /// başlangıcı zaten yığındadır.
  void push(Note before, Note after, {required DateTime now}) {
    final structural = structureKey(before) != structureKey(after);
    final last = _lastPushAt;
    if (!structural &&
        _entries.isNotEmpty &&
        last != null &&
        now.difference(last) < coalesceWindow) {
      _lastPushAt = now;
      return;
    }
    _entries.add(before);
    if (_entries.length > limit) _entries.removeAt(0);
    _lastPushAt = now;
  }

  /// Son durumu çıkarır (yığın boşsa null).
  ///
  /// Yazma dizisi penceresi de kapanır: geri almadan hemen sonra yazılan harf
  /// geri alınan duruma eklenmez, yeni bir adım açar.
  Note? pop() {
    _lastPushAt = null;
    return _entries.isEmpty ? null : _entries.removeLast();
  }

  void clear() {
    _entries.clear();
    _lastPushAt = null;
  }
}
