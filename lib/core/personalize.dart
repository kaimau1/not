import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'error_log.dart';

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
///  * DÜZENLEME MODU ANINDA uygular (P50, kullanıcı isteği 2026-11-13: "aç,
///    düzenle, kaydet değil"): ekranlardaki öğelere dokununca gizle/göster
///    hemen kaydedilir; tepedeki şeritte "Geri al" modun açıldığı ana döner,
///    "Bitti" modu kapatır. [draft] yalnız "mod açık" işaretidir (kayıtla
///    aynı değeri taşır).
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
    this.barOrder = const <String>[],
    this.aiOrder = const <String>[],
  });

  /// Not alt çubuğunun SOL kapsülündeki düğmelerin kullanıcı sırası
  /// (kullanıcı isteği 2026-11-13: "alt paneldeki tüm butonlar
  /// değiştirilebilsin, kişi istediğini koyabilsin, istediğini çıkarabilsin;
  /// ayarlarda seçenekler geniş olsun"). Boş = varsayılan sıra; listede
  /// olmayan (yeni) düğme varsayılan yerine göre sona eklenir — bkz.
  /// [orderOf].
  final List<String> barOrder;

  /// Sağdaki AI/ses kapsülünün sırası (aynı kurallar).
  final List<String> aiOrder;

  /// [defaults] sırasını kullanıcı sırasıyla ([saved]) birleştirir: kayıtlı
  /// ve hâlâ var olan kimlikler kayıtlı sırada, kalanlar varsayılan sırada
  /// arkada. Bilinmeyen (eski sürümden kalan) kimlik atlanır.
  static List<String> orderOf(List<String> defaults, List<String> saved) {
    final known = defaults.toSet();
    final seen = <String>{};
    final out = <String>[
      // Yinelenen kimlik (bozuk kayıt) düğmeyi iki kez çizmesin.
      for (final id in saved)
        if (known.contains(id) && seen.add(id)) id,
    ];
    for (final id in defaults) {
      if (seen.add(id)) out.add(id);
    }
    return out;
  }

  /// İKİ KAPSÜLÜN düğmeleri, kullanıcı sırasıyla (P50, P57'den devir:
  /// "düğmeyi iki kapsül arasında taşıma"). Düğmenin tarafı: [aiOrder]'da
  /// kayıtlıysa SAĞ, [barOrder]'da kayıtlıysa SOL, hiçbirinde yoksa
  /// varsayılan tarafı. Eski kayıtlar (yalnız kendi tarafının kimlikleri)
  /// aynen okunur; eski sürüm yabancı kimliği atlar.
  ({List<String> left, List<String> right}) get barSides {
    final right = {
      ...aiOrder,
      for (final id in UiItem.barRightDefault)
        if (!barOrder.contains(id)) id,
    };
    const l = UiItem.barLeftDefault, r = UiItem.barRightDefault;
    return (
      left: orderOf([...l, ...r], barOrder)
          .where((id) => !right.contains(id))
          .toList(),
      right: orderOf([...r, ...l], aiOrder).where(right.contains).toList(),
    );
  }

  /// [id] düğmesini öbür kapsülün SONUNA taşır (ya da yerinde bırakır).
  UiPrefs withBarSide(String id, {required bool right}) {
    final s = barSides;
    if (s.right.contains(id) == right) return this;
    final l = [...s.left]..remove(id), r = [...s.right]..remove(id);
    (right ? r : l).add(id);
    return copyWith(barOrder: l, aiOrder: r);
  }

  /// Gizlenen öğelerin kimlikleri (bkz. [UiItem]).
  final Set<String> hidden;

  /// Videonun ⏪ düğmesinin geri sardığı saniye.
  final int seekBack;

  /// Videonun ⏩ düğmesinin ileri sardığı saniye.
  final int seekForward;

  /// Ayarda seçilebilen sarma süreleri (sn).
  static const seekChoices = <int>[3, 5, 10, 15, 20, 30, 60];

  /// [UiItem.optIn] öğeleri varsayılan GİZLİ: açılınca kümede `+kimlik`
  /// tutulur (kayıt biçimi aynı kalsın diye tek küme).
  bool shows(String id) => UiItem.optIn.contains(id)
      ? hidden.contains('+$id')
      : !hidden.contains(id);

  UiPrefs withVisible(String id, bool visible) {
    if (shows(id) == visible) return this;
    final next = {...hidden};
    if (UiItem.optIn.contains(id)) {
      visible ? next.add('+$id') : next.remove('+$id');
    } else {
      visible ? next.remove(id) : next.add(id);
    }
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

  UiPrefs copyWith({
    Set<String>? hidden,
    int? seekBack,
    int? seekForward,
    List<String>? barOrder,
    List<String>? aiOrder,
  }) => UiPrefs(
    hidden: hidden ?? this.hidden,
    seekBack: seekBack ?? this.seekBack,
    seekForward: seekForward ?? this.seekForward,
    barOrder: barOrder ?? this.barOrder,
    aiOrder: aiOrder ?? this.aiOrder,
  );

  Map<String, Object?> toJson() => {
    'hidden': (hidden.toList()..sort()),
    'seekBack': seekBack,
    'seekForward': seekForward,
    if (barOrder.isNotEmpty) 'barOrder': barOrder,
    if (aiOrder.isNotEmpty) 'aiOrder': aiOrder,
  };

  /// Bozuk/eksik kayıt varsayılana düşer; sarma süresi 1–600 sn arasında.
  factory UiPrefs.fromJson(Object? json) {
    if (json is! Map) return const UiPrefs();
    int seconds(Object? v) => v is num ? v.toInt().clamp(1, 600) : 10;
    final hidden = json['hidden'];
    List<String> ids(Object? v) =>
        v is List ? [for (final x in v) '$x'] : const <String>[];
    return UiPrefs(
      hidden: hidden is List ? {for (final h in hidden) '$h'} : const {},
      seekBack: seconds(json['seekBack']),
      seekForward: seconds(json['seekForward']),
      barOrder: ids(json['barOrder']),
      aiOrder: ids(json['aiOrder']),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is UiPrefs &&
      other.seekBack == seekBack &&
      other.seekForward == seekForward &&
      setEquals(other.hidden, hidden) &&
      listEquals(other.barOrder, barOrder) &&
      listEquals(other.aiOrder, aiOrder);

  @override
  int get hashCode => Object.hash(
    seekBack,
    seekForward,
    Object.hashAllUnordered(hidden),
    Object.hashAll(barOrder),
    Object.hashAll(aiOrder),
  );
}

/// Gizlenebilir öğelerin kalıcı kimlikleri. Kimlik DEĞİŞTİRİLMEZ (kayıtlı
/// tercihler onunla eşleşir); yeni öğe yeni kimlik alır.
abstract final class UiItem {
  // ── Not ekranının alt çubuğu ──
  static const barFormat = 'editor.bar.format';
  static const barAdd = 'editor.bar.add';
  static const barSelect = 'editor.bar.select';
  static const barSearch = 'editor.bar.search';
  /// ESKİ Paylaş segmenti — 2026-11-12'de (K-D6) yerini Kalem aldı; kimlik
  /// eski tercihler için duruyor.
  static const barShare = 'editor.bar.share';
  static const barPen = 'editor.bar.pen';
  static const barAttachments = 'editor.bar.attachments';
  static const barAi = 'editor.bar.ai';
  /// ESKİ "AI ile sesli not" çubuk düğmesi — 2026-10-20'de yapay zekâ
  /// levhasının en üst satırına taşındı; kimlik eski tercihler için duruyor.
  static const barVoiceAi = 'editor.bar.voiceAi';
  static const barDictation = 'editor.bar.dictation';
  /// Notun içinde SESLİ NOT kaydı (2026-10-28, dalgalı hap).
  static const barVoiceRecord = 'editor.bar.voiceRecord';
  /// ☑ satırı onay kutulu maddeye çevir / kutuyu kaldır (2026-10-28).
  static const barCheckbox = 'editor.bar.checkbox';

  // SONRADAN EKLENEBİLEN alt çubuk düğmeleri (kullanıcı isteği 2026-11-13):
  // varsayılan GİZLİ ([optIn]); Ayarlar → Kişiselleştir → Alt çubuk'tan
  // eklenir, sırası orada sürüklenerek değişir.
  static const barUndo = 'editor.bar.undo';
  static const barRedo = 'editor.bar.redo';
  static const barReminder = 'editor.bar.reminder';
  static const barPhoto = 'editor.bar.photo';
  static const barCamera = 'editor.bar.camera';
  static const barScan = 'editor.bar.scan';
  static const barColor = 'editor.bar.color';

  /// Sol kapsülün VARSAYILAN sırası (Biçim · Ekle · Kalem · Ara · Ekler ·
  /// ☑/Seç — türe özgü düğme en sonda, F12.3) + eklenebilenler.
  static const barLeftDefault = <String>[
    barFormat,
    barAdd,
    barPen,
    barSearch,
    barAttachments,
    barCheckbox,
    barSelect,
    barUndo,
    barRedo,
    barReminder,
    barPhoto,
    barCamera,
    barScan,
    barColor,
    barShare,
  ];

  /// Sağ (AI/ses) kapsülün varsayılan sırası.
  static const barRightDefault = <String>[barAi, barVoiceRecord, barDictation];

  // ── Not ekranının üst çubuğu ──
  static const topSync = 'editor.top.sync';
  static const topUndo = 'editor.top.undo';
  static const topCollab = 'editor.top.collab';
  static const topPin = 'editor.top.pin';
  /// Görünüm (tema şeridi) düğmesi (2026-10-28).
  static const topTheme = 'editor.top.theme';
  /// Geniş ekranda Ana sayfa ve tablette Tam ekran düğmeleri (P50: "her şey
  /// düzenlenebilsin" — sarmasız kalmışlardı).
  static const topHome = 'editor.top.home';
  static const topFullscreen = 'editor.top.fullscreen';

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

  /// Yazarken üstteki hızlı erişim satırının düğmesi ([key] =
  /// `EditorQuickRow` düğme kimliği; 2026-11-08 — düzenleme modunda
  /// gizlenip gösterilir).
  static String quickRow(String key) => 'editor.quick.$key';

  /// HIZLI SATIRA SONRADAN EKLENEBİLEN düğmeler (kullanıcı isteği
  /// 2026-11-08: "hızlı menüye istediğimizi ekleyebilelim") — varsayılan
  /// gizli; düzenleme modunda (satırın sonundaki ⚙) dokununca eklenir.
  static final optIn = <String>{
    barUndo,
    barRedo,
    barReminder,
    barPhoto,
    barCamera,
    barScan,
    barColor,
    barShare,
    // SADE VARSAYILAN (kullanıcı isteği 2026-11-09: "hızlı panelin varsayılan
    // hali sadeleşmeli — kalem kipi, yazım düzeltici, paket, ek ekle, kalın +
    // favori renk; telefona sığsın, fazlasını kişiler düzenleme alanından
    // ekler"). Görünenler: pen, spell, package, attach, bold, color.
    for (final k in const [
      'bullet',
      'checkbox',
      'heading',
      'subheading',
      'photo',
      'camera',
      'file',
      'reminder',
      'date',
      'italic',
      'underline',
      'highlight',
      'dictation',
      'scan',
    ])
      quickRow(k),
  };

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
    UiItem.barVoiceRecord,
    UiItem.homeMic,
    'quickadd.voice',
    'attach.audio',
  ]);

  static const video = UiModule('video', [
    'quickadd.video',
    'quickadd.youtube',
    'attach.video',
    'attach.youtube',
  ]);

  // "Belgeler" eklentisi KALKTI (2026-10-20): Ekle levhasındaki PDF/Slayt
  // düğmeleri tek "Dosya ekle"de birleşti; eklentinin gizleyeceği bir şey
  // kalmadı. Kayıtlı 'documents' tercihi zararsızca yok sayılır.

  static const scan = UiModule('scan', [
    'quickadd.scan',
    'quickadd.qr',
    'attach.scan',
    'attach.qr',
  ]);

  static const drawing = UiModule('drawing', [
    'quickadd.draw',
    'quickadd.drawing',
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

  /// Düzenleme modu açıkken geçerli tercihler (kayıtla aynı); kapalıyken
  /// null.
  static final draft = ValueNotifier<UiPrefs?>(null);

  /// Mod açıldığı andaki kayıt — "Geri al" buna döner.
  static UiPrefs _before = const UiPrefs();

  /// İkisinden biri değişince haber veren birleşik dinlenebilir.
  static final Listenable listenable = Listenable.merge([prefs, draft]);

  static SharedPreferences? _store;

  /// Ekranda geçerli olan: düzenlenirken taslak, değilse kayıt.
  static UiPrefs get current => draft.value ?? prefs.value;

  static bool get editing => draft.value != null;

  /// Bu oturumda bir şey değişti mi (şeritteki "Geri al" etkin mi).
  static bool get dirty => draft.value != null && prefs.value != _before;

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
    } catch (e) {
      ErrorLog.record('personalize-write', e);
    }
  }

  static void startEditing() {
    if (draft.value != null) return;
    _before = prefs.value;
    draft.value = prefs.value;
  }

  /// Düzenleme modunda bir öğeye dokunuldu: gizle/göster, HEMEN kaydedilir.
  static void toggle(String id) {
    if (draft.value == null) return;
    update((p) => p.withVisible(id, !p.shows(id)));
  }

  /// "Bitti": mod kapanır (değişiklikler zaten kayıtlı).
  static void done() => draft.value = null;

  /// "Geri al": modun açıldığı andaki düzene döner; mod açık kalır.
  static void revert() {
    if (draft.value == null) return;
    draft.value = _before;
    _write(_before);
  }

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
