import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// **KİŞİSELLEŞTİRME** — hangi alan/düğme görünür, sayısal küçük tercihler.
///
/// Kullanıcı isteği 2026-10-16: "bütün alanlar bir eklenti gibi açılıp
/// kapatılabilsin, kişisel bir çok özelleştirmeye izin verilsin; not ekleme
/// alanı da özelleştirilebilsin, hangilerinin görüneceği seçilsin. Bu
/// düzenlemeler bir menü üzerinden yapılmalı — ekranlarda ayar düğmesi olarak
/// yer kaplamasın; ayarlarda DÜZENLEME MODU olsun, o açılınca yapılsın ve
/// kaydedilsin."
///
/// Tasarım:
///  * Her gizlenebilir öğenin KALICI bir kimliği var ([UiItem]); gizlenenler
///    tek kümede ([UiPrefs.hidden]) tutulur. Varsayılan: hepsi görünür —
///    yeni eklenen öğe güncellemeden sonra kendiliğinden görünür gelir.
///  * "Eklenti" ([UiModule]) birden çok öğenin adlı grubudur: modülü kapatmak
///    öğelerinin hepsini gizler. Modülün ayrı bir kaydı YOK (durum öğelerden
///    türer) — öğe tek tek açılınca modül "kısmen açık" görünür, iki kayıt
///    birbirini ezmez.
///  * DÜZENLEME MODU bir TASLAK üzerinde çalışır ([draft]): ekranlardaki
///    öğelere dokununca gizle/göster taslağa yazılır, uygulamanın tepesindeki
///    şeritte "Kaydet" ile kalıcı olur, "Vazgeç" ile atılır.
///  * Riverpod DEĞİL, statik dinlenebilir (bkz. `BubbleLook`): alt çubuğun
///    düğmeleri, video denetimi, + menüsü gibi sağlayıcı kapsamı dışındaki
///    (Overlay, levha) yerlerden de okunur; testte bağlanmadan varsayılanla
///    çalışır.
///
/// Cihaz tercihidir (SharedPreferences) — senkronlanmaz: telefonla tablette
/// farklı düzen istenebilir.
@immutable
class UiPrefs {
  const UiPrefs({
    this.hidden = const <String>{},
    this.seekBack = 10,
    this.seekForward = 10,
  });

  /// Gizlenen öğelerin kimlikleri (bkz. [UiItem]).
  final Set<String> hidden;

  /// Videonun ⏪ düğmesinin geri sardığı saniye.
  final int seekBack;

  /// Videonun ⏩ düğmesinin ileri sardığı saniye.
  final int seekForward;

  /// Ayarda seçilebilen sarma süreleri (sn).
  static const seekChoices = <int>[3, 5, 10, 15, 20, 30, 60];

  bool shows(String id) => !hidden.contains(id);

  UiPrefs withVisible(String id, bool visible) {
    if (shows(id) == visible) return this;
    final next = {...hidden};
    visible ? next.remove(id) : next.add(id);
    return copyWith(hidden: next);
  }

  UiPrefs withModule(UiModule module, bool on) {
    final next = {...hidden};
    for (final id in module.items) {
      on ? next.remove(id) : next.add(id);
    }
    return copyWith(hidden: next);
  }

  /// Modülün durumu: true hepsi açık, false hepsi kapalı, null karışık.
  bool? moduleState(UiModule module) {
    final shown = module.items.where(shows).length;
    if (shown == module.items.length) return true;
    if (shown == 0) return false;
    return null;
  }

  UiPrefs copyWith({Set<String>? hidden, int? seekBack, int? seekForward}) =>
      UiPrefs(
        hidden: hidden ?? this.hidden,
        seekBack: seekBack ?? this.seekBack,
        seekForward: seekForward ?? this.seekForward,
      );

  Map<String, Object?> toJson() => {
    'hidden': (hidden.toList()..sort()),
    'seekBack': seekBack,
    'seekForward': seekForward,
  };

  /// Bozuk/eksik kayıt varsayılana düşer; sarma süresi 1–600 sn arasında.
  factory UiPrefs.fromJson(Object? json) {
    if (json is! Map) return const UiPrefs();
    int seconds(Object? v) => v is num ? v.toInt().clamp(1, 600) : 10;
    final hidden = json['hidden'];
    return UiPrefs(
      hidden: hidden is List ? {for (final h in hidden) '$h'} : const {},
      seekBack: seconds(json['seekBack']),
      seekForward: seconds(json['seekForward']),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is UiPrefs &&
      other.seekBack == seekBack &&
      other.seekForward == seekForward &&
      setEquals(other.hidden, hidden);

  @override
  int get hashCode =>
      Object.hash(seekBack, seekForward, Object.hashAllUnordered(hidden));
}

/// Gizlenebilir öğelerin kalıcı kimlikleri. Kimlik DEĞİŞTİRİLMEZ (kayıtlı
/// tercihler onunla eşleşir); yeni öğe yeni kimlik alır.
abstract final class UiItem {
  // ── Not ekranının alt çubuğu ──
  static const barFormat = 'editor.bar.format';
  static const barAdd = 'editor.bar.add';
  static const barSelect = 'editor.bar.select';
  static const barSearch = 'editor.bar.search';
  static const barShare = 'editor.bar.share';
  static const barAttachments = 'editor.bar.attachments';
  static const barAi = 'editor.bar.ai';
  /// ESKİ "AI ile sesli not" çubuk düğmesi — 2026-10-20'de yapay zekâ
  /// levhasının en üst satırına taşındı; kimlik eski tercihler için duruyor.
  static const barVoiceAi = 'editor.bar.voiceAi';
  static const barDictation = 'editor.bar.dictation';

  // ── Not ekranının üst çubuğu ──
  static const topSync = 'editor.top.sync';
  static const topUndo = 'editor.top.undo';
  static const topCollab = 'editor.top.collab';
  static const topPin = 'editor.top.pin';

  // ── Not ekranının alanları ──
  static const editorTags = 'editor.tags';
  static const editorDate = 'editor.date';

  // ── Ana ekran ──
  // (kullanıcı bulgusu 2026-10-16: "ana ekran kişiselleştirilemiyor").
  static const homeAccount = 'home.account';
  static const homeAi = 'home.ai';
  static const homeFilter = 'home.filter';
  /// ESKİ ana ekran görünüm düğmesi — 2026-10-20'de Süz levhasına taşındı;
  /// kimlik eski gizleme tercihleri için duruyor, ekranda kullanılmıyor.
  static const homeViewToggle = 'home.viewToggle';
  /// Ana ekranın TEK mikrofonu (F3.1). Kimlik eski "AI ile sesli not"
  /// düğmesininki — gizleme tercihi korunur.
  static const homeMic = 'home.voiceAi';

  // ── Video denetimi ──
  static const videoSpeed = 'video.speed';
  static const videoTime = 'video.time';
  static const videoNoteAt = 'video.noteAt';

  /// Ana ekrandaki "+" menüsünün seçeneği ([key] = `QuickAddOption.key`).
  static String quickAdd(String key) => 'quickadd.$key';

  /// Not ekranındaki "Ekle" levhasının seçeneği ([key] = levhanın kimliği).
  static String attach(String key) => 'attach.$key';
}

/// "Eklenti": aynı işe ait öğelerin adlı grubu (bkz. [UiPrefs.withModule]).
/// Adı ve simgesi arayüzde (ayarlar) çözülür; burada yalnız kimlik + öğeler.
@immutable
class UiModule {
  const UiModule(this.id, this.items);

  final String id;
  final List<String> items;

  // Eklentiler AYRIK: bir öğe tek eklentide durur. "AI ile sesli not"
  // eskiden hem Yapay zekâ'da hem Ses'te vardı; Ses'i kapatmak Yapay zekâ'yı
  // da "kısmen açık"a düşürüyor, kullanıcı "başka şeyler de kapanmış"
  // görüyordu (kullanıcı bulgusu 2026-10-16).
  static const ai = UiModule('ai', [UiItem.barAi, UiItem.homeAi]);

  static const voice = UiModule('voice', [
    UiItem.barDictation,
    UiItem.homeMic,
    'quickadd.voice',
    'attach.audio',
  ]);

  static const video = UiModule('video', [
    'quickadd.video',
    'quickadd.youtube',
    'attach.video',
    'attach.video-gallery',
    'attach.youtube',
  ]);

  static const documents = UiModule('documents', [
    'attach.pdf',
    'attach.slide',
  ]);

  static const scan = UiModule('scan', [
    'quickadd.scan',
    'quickadd.qr',
    'attach.scan',
    'attach.qr',
  ]);

  static const drawing = UiModule('drawing', [
    'quickadd.draw',
    'attach.drawing',
  ]);

  static const templates = UiModule('templates', [
    'quickadd.template',
    'quickadd.shopping',
    'quickadd.archive',
  ]);

  static const tags = UiModule('tags', [UiItem.editorTags]);

  static const collaboration = UiModule('collaboration', [UiItem.topCollab]);

  static const all = <UiModule>[
    ai,
    voice,
    video,
    documents,
    scan,
    drawing,
    templates,
    tags,
    collaboration,
  ];
}

/// Kayıt + düzenleme modu.
abstract final class Personalize {
  static const _key = 'ui_prefs_v1';

  /// KAYITLI tercihler.
  static final prefs = ValueNotifier<UiPrefs>(const UiPrefs());

  /// Düzenleme modundaki taslak; mod kapalıyken null.
  static final draft = ValueNotifier<UiPrefs?>(null);

  /// İkisinden biri değişince haber veren birleşik dinlenebilir.
  static final Listenable listenable = Listenable.merge([prefs, draft]);

  static SharedPreferences? _store;

  /// Ekranda geçerli olan: düzenlenirken taslak, değilse kayıt.
  static UiPrefs get current => draft.value ?? prefs.value;

  static bool get editing => draft.value != null;

  /// Taslak kayıttan farklı mı (şeritteki "Kaydet" vurgusu).
  static bool get dirty => draft.value != null && draft.value != prefs.value;

  /// Uygulama açılışında (main) bir kez.
  static void attach(SharedPreferences store) {
    _store = store;
    final raw = store.getString(_key);
    if (raw == null) return;
    try {
      prefs.value = UiPrefs.fromJson(jsonDecode(raw));
    } catch (_) {
      // Bozuk kayıt: varsayılan (hepsi görünür) — uygulama açılmaya devam.
    }
  }

  /// Menüden (ayarlar) doğrudan değişiklik: hemen kaydedilir. Düzenleme modu
  /// açıksa taslak da aynı değişikliği alır (iki kaynak ayrışmasın).
  static void update(UiPrefs Function(UiPrefs) change) {
    final next = change(prefs.value);
    final d = draft.value;
    if (d != null) draft.value = change(d);
    _write(next);
  }

  static void _write(UiPrefs next) {
    if (next == prefs.value) return;
    prefs.value = next;
    try {
      _store?.setString(_key, jsonEncode(next.toJson()));
    } catch (_) {}
  }

  static void startEditing() => draft.value ??= prefs.value;

  /// Düzenleme modunda bir öğeye dokunuldu: taslakta gizle/göster.
  static void toggle(String id) {
    final d = draft.value;
    if (d == null) return;
    draft.value = d.withVisible(id, !d.shows(id));
  }

  static void save() {
    final d = draft.value;
    if (d != null) _write(d);
    draft.value = null;
  }

  static void cancel() => draft.value = null;

  /// Varsayılana dön (hepsi görünür, sarma 10/10 sn).
  static void reset() {
    if (draft.value != null) draft.value = const UiPrefs();
    _write(const UiPrefs());
  }

  /// Testler için: kayıtsız varsayılana döner.
  @visibleForTesting
  static void debugReset() {
    _store = null;
    prefs.value = const UiPrefs();
    draft.value = null;
  }
}
