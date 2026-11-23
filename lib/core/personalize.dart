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
    this.topOrder = const <String>[],
    this.quickOrder = const <String>[],
    this.attachOrder = const <String>[],
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

  /// Not ÜST çubuğundaki sıralanabilir düğmelerin sırası (P20 M8; aynı
  /// kurallar, varsayılan [UiItem.topDefault]). Kapsül yok, taraf yok.
  final List<String> topOrder;

  /// Yazarken üstteki hızlı satırın kullanıcı sırası ([UiItem.quickRow]
  /// anahtarları değil, satırın düğme anahtarları; P63 PBT — PB7 bağlar,
  /// bugün hiçbir ekran okumaz). Boş = varsayılan; [orderOf] kuralları.
  final List<String> quickOrder;

  /// "Ekle" levhasının seçenek sırası (aynı kurallar; P63 PBT).
  final List<String> attachOrder;

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
  ///
  /// "Yapay zekâyı tümden kapat" (PL3, [Personalize.aiOff]) açıkken Yapay
  /// zekâ eklentisinin öğeleri kayıttan bağımsız GİZLİ; kayıt değişmez,
  /// anahtar kapanınca kullanıcının kendi seçimi geri gelir.
  bool shows(String id) =>
      !(Personalize.aiOff.value && UiModule.ai.items.contains(id)) &&
      storedShows(id);

  /// Kayıttaki seçim ([Personalize.aiOff] hesaba katılmadan).
  bool storedShows(String id) => UiItem.isOptIn(id)
      ? hidden.contains('+$id')
      : !hidden.contains(id);

  UiPrefs withVisible(String id, bool visible) {
    if (storedShows(id) == visible) return this;
    final next = {...hidden};
    if (UiItem.isOptIn(id)) {
      visible ? next.add('+$id') : next.remove('+$id');
    } else {
      visible ? next.remove(id) : next.add(id);
    }
    return copyWith(hidden: next);
  }

  /// Eklentiyi açar/kapatır. Kapatmak HEPSİNİ gizler; açmak varsayılanına
  /// döndürür — sonradan eklenebilen ([UiItem.isOptIn]) öğe kendiliğinden
  /// açılmaz (2026-11-16: "+" menüsünde YouTube varsayılan gizli).
  UiPrefs withModule(UiModule module, bool on) {
    var next = this;
    for (final id in module.items) {
      if (on && UiItem.isOptIn(id)) continue;
      next = next.withVisible(id, on);
    }
    return next;
  }

  /// Modülün durumu: true hepsi açık, false hepsi kapalı, null karışık.
  /// Varsayılan gizli öğe, açılmadıkça sayılmaz.
  bool? moduleState(UiModule module) {
    final counted = [
      for (final id in module.items)
        if (!UiItem.isOptIn(id) || storedShows(id)) id,
    ];
    if (counted.isEmpty) return false;
    final shown = counted.where(storedShows).length;
    if (shown == counted.length) return true;
    if (shown == 0) return false;
    return null;
  }

  UiPrefs copyWith({
    Set<String>? hidden,
    int? seekBack,
    int? seekForward,
    List<String>? barOrder,
    List<String>? aiOrder,
    List<String>? topOrder,
    List<String>? quickOrder,
    List<String>? attachOrder,
  }) => UiPrefs(
    hidden: hidden ?? this.hidden,
    seekBack: seekBack ?? this.seekBack,
    seekForward: seekForward ?? this.seekForward,
    barOrder: barOrder ?? this.barOrder,
    aiOrder: aiOrder ?? this.aiOrder,
    topOrder: topOrder ?? this.topOrder,
    quickOrder: quickOrder ?? this.quickOrder,
    attachOrder: attachOrder ?? this.attachOrder,
  );

  Map<String, Object?> toJson() => {
    'hidden': (hidden.toList()..sort()),
    'seekBack': seekBack,
    'seekForward': seekForward,
    if (barOrder.isNotEmpty) 'barOrder': barOrder,
    if (aiOrder.isNotEmpty) 'aiOrder': aiOrder,
    if (topOrder.isNotEmpty) 'topOrder': topOrder,
    if (quickOrder.isNotEmpty) 'quickOrder': quickOrder,
    if (attachOrder.isNotEmpty) 'attachOrder': attachOrder,
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
      topOrder: ids(json['topOrder']),
      quickOrder: ids(json['quickOrder']),
      attachOrder: ids(json['attachOrder']),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is UiPrefs &&
      other.seekBack == seekBack &&
      other.seekForward == seekForward &&
      setEquals(other.hidden, hidden) &&
      listEquals(other.barOrder, barOrder) &&
      listEquals(other.aiOrder, aiOrder) &&
      listEquals(other.topOrder, topOrder) &&
      listEquals(other.quickOrder, quickOrder) &&
      listEquals(other.attachOrder, attachOrder);

  @override
  int get hashCode => Object.hash(
    seekBack,
    seekForward,
    Object.hashAllUnordered(hidden),
    Object.hashAll(barOrder),
    Object.hashAll(aiOrder),
    Object.hashAll(topOrder),
    Object.hashAll(quickOrder),
    Object.hashAll(attachOrder),
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
  /// SİLGİ (K-S1, kullanıcı kararı 2026-11-15): metin/liste notunda mürekkep
  /// varken görünür; dokunmak kalem kipini silgi seçili açar.
  static const barEraser = 'editor.bar.eraser';
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

  /// GÜN EKLE (kullanıcı isteği 2026-11-23: "otomatik bugünün tarihini
  /// ekler, 22/11/2026 şeklinde") ve TABLO (2–4 sütun) — varsayılan gizli,
  /// ⋯ menüsünde durur.
  static const barDay = 'editor.bar.day';
  static const barTable = 'editor.bar.table';

  /// Sol kapsülün VARSAYILAN sırası (Biçim · Ekle · Kalem · Ara · Ekler ·
  /// ☑/Seç — türe özgü düğme en sonda, F12.3) + eklenebilenler.
  static const barLeftDefault = <String>[
    barFormat,
    barAdd,
    barPen,
    barEraser,
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
    barDay,
    barTable,
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

  /// Üst çubuğun sıralanabilir düğmeleri, BUGÜNKÜ ekran sırasıyla (P20 M8).
  /// Yazılım klavyesi düğmesi ve ⋮ sıralamaya girmez.
  static const topDefault = <String>[
    topHome,
    topSync,
    topUndo,
    topPin,
    topFullscreen,
  ];

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

  /// Ana ekranın ⚡ HIZLI EKLE yüzen düğmesi (kullanıcı isteği 2026-11-16:
  /// "hızlı ekleyi yüzen buton yap").
  static const homeQuickDrop = 'home.quickDrop';

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
    barDay,
    barTable,
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
      // Gün ekle + Tablo ⋯ ızgarasının başında (2026-11-23; telefonda satır
      // dolu — düzenleyiciden satıra alınır).
      'day',
      'table',
    ])
      quickRow(k),
    // SADE "+" MENÜSÜ (kullanıcı isteği 2026-11-16: ekran görüntüsünde
    // çarpılanlar): dosya, YouTube, kalem, ayrı çizim, defter ve Hızlı ekle
    // karosu (artık ana ekranda kendi yüzen düğmesi var) varsayılan gizli;
    // "Menüyü düzenle"den geri eklenir. QR, "Tara" karosunda belgeyle
    // birleşti (bkz. `addCatalog`).
    for (final k in const [
      'file',
      'youtube',
      'shopping',
      'draw',
      'drawing',
      'archive',
      'quickdrop',
      'qr',
    ])
      quickAdd(k),
  };

  /// Varsayılan gizli mi: [optIn] kümesi + favori şablon karoları
  /// (`quickadd.fav-…`, kimlikleri kullanıcıya göre değişir; 2026-11-16'dan
  /// beri "+" menüsünde varsayılan gizli — yerlerini "Akıllı liste" aldı).
  static bool isOptIn(String id) =>
      optIn.contains(id) || id.startsWith('quickadd.fav-');

  /// Not ekranındaki "Ekle" levhasının seçeneği ([key] = levhanın kimliği).
  static String attach(String key) => 'attach.$key';

  /// Sabit ek çubuğunun düğmesi (P63 PBT; PB7 bağlar).
  static String pinned(String key) => 'pinned.$key';

  /// Kalem tepsisindeki araç (P63 PBT; PB3 bağlar).
  static String penTool(String key) => 'pen.tool.$key';
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

  /// "Yapay zekâyı tümden kapat" (PL3): açıkken Yapay zekâ eklentisinin
  /// girişleri ([UiModule.ai]) her yerde gizli. Kayıt [aiOffKey]; yazan
  /// `aiTurnedOffProvider` (features/ai/data/ai_policy.dart).
  static final aiOff = ValueNotifier<bool>(false);

  static const aiOffKey = 'ai_user_off';

  /// **NOT BAŞINA DÜZEN** (kullanıcı isteği 2026-11-19: "menü düzenlerken
  /// tümüne uygula / yalnız bu nota uygula"). Açık notun KENDİ alt çubuk +
  /// hızlı satır düzeni; yoksa null (genel düzen geçerli). Yalnız düzen
  /// alanları ([isLayoutId] gizlemeleri, `barOrder`, `aiOrder`,
  /// `quickOrder`) taşınır. Cihaz tercihi (SharedPreferences, not kimliği
  /// anahtarlı) — Firestore'a/nota yazılmaz, göç yok; silinince genel düzene
  /// dönülür. Değer yalnız GERÇEKTEN değişince bildirir: nottan nota geçiş
  /// (ikisinde de özel düzen yoksa) dinleyicileri uyandırmaz.
  static final noteOverride = ValueNotifier<UiPrefs?>(null);

  static const _noteKey = 'note_ui_layout_v1';
  static Map<String, UiPrefs> _noteLayouts = const {};
  static String? _activeNote;

  /// Düzeni düzenlenebilen açık not (editör kurulunca), yoksa null.
  static String? get activeNote => _activeNote;

  /// Açık notun kendi düzeni var mı.
  static bool get noteHasOwnLayout =>
      _activeNote != null && _noteLayouts.containsKey(_activeNote);

  /// Not başına taşınan kimlik mi (alt çubuk ve hızlı satır düğmeleri).
  static bool isLayoutId(String id) {
    final bare = id.startsWith('+') ? id.substring(1) : id;
    return bare.startsWith('editor.bar.') || bare.startsWith('editor.quick.');
  }

  /// Biri değişince haber veren birleşik dinlenebilir.
  static final Listenable listenable = Listenable.merge([
    prefs,
    draft,
    aiOff,
    noteOverride,
  ]);

  static SharedPreferences? _store;

  static UiPrefs? _effBase;
  static UiPrefs? _effOver;
  static UiPrefs? _eff;

  /// Ekranda geçerli olan: düzenlenirken taslak, değilse kayıt; açık notun
  /// kendi düzeni varsa düzen alanları ondan. Sonuç önbellekte (kurulumda
  /// sık okunur, her okuyuşta yeni küme kurulmasın).
  static UiPrefs get current {
    final base = draft.value ?? prefs.value;
    final over = noteOverride.value;
    if (over == null) return base;
    if (identical(base, _effBase) && identical(over, _effOver)) return _eff!;
    _effBase = base;
    _effOver = over;
    return _eff = _overlay(base, over);
  }

  static UiPrefs _overlay(UiPrefs base, UiPrefs over) => base.copyWith(
    hidden: {
      for (final h in base.hidden)
        if (!isLayoutId(h)) h,
      ...over.hidden,
    },
    barOrder: over.barOrder,
    aiOrder: over.aiOrder,
    quickOrder: over.quickOrder,
  );

  /// [p]'nin yalnız düzen alanları (not başına kayıt biçimi).
  static UiPrefs _layoutOf(UiPrefs p) => UiPrefs(
    hidden: {
      for (final h in p.hidden)
        if (isLayoutId(h)) h,
    },
    barOrder: p.barOrder,
    aiOrder: p.aiOrder,
    quickOrder: p.quickOrder,
  );

  /// Editör açıldı: [noteId]'nin düzeni (varsa) geçerli olur.
  /// [owner] editörün kendisi: aynı not yeniden açılırken eskisinin geç
  /// gelen kapanışı yenisini silmesin.
  static void enterNote(String noteId, Object owner) {
    _activeNote = noteId;
    _activeOwner = owner;
    noteOverride.value = _noteLayouts[noteId];
  }

  static Object? _activeOwner;

  /// Editör kapandı (yalnız hâlâ geçerli editör oysa).
  static void leaveNote(Object owner) {
    if (!identical(_activeOwner, owner)) return;
    _activeOwner = null;
    _activeNote = null;
    noteOverride.value = null;
  }

  /// "Yalnız bu nota" ([own] true): açık not genel düzenin bugünkü
  /// kopyasıyla kendi düzenini alır; false = notun düzeni silinir, genel
  /// düzene döner ("Bu notun özelleştirmesini sıfırla").
  static void setNoteOwnLayout(bool own) {
    final id = _activeNote;
    if (id == null || own == _noteLayouts.containsKey(id)) return;
    _writeNote(id, own ? _layoutOf(draft.value ?? prefs.value) : null);
  }

  /// Not kalıcı silindi: yerel düzen kaydı da gider (sabah bakılacak,
  /// 2026-11-19: silinen notun kaydı sonsuza dek kalıyordu).
  static void forgetNote(String noteId) {
    if (_noteLayouts.containsKey(noteId)) _writeNote(noteId, null);
  }

  /// Menü DÜZENİ değişikliği (hızlı satır, alt çubuk): açık notun kendi
  /// düzeni varsa ona, yoksa genel düzene ([update]) yazılır.
  static void updateLayout(UiPrefs Function(UiPrefs) change) {
    final id = _activeNote;
    final own = id == null ? null : _noteLayouts[id];
    if (id == null || own == null) {
      update(change);
      return;
    }
    _writeNote(id, _layoutOf(change(current)));
  }

  static void _writeNote(String id, UiPrefs? layout) {
    final next = {..._noteLayouts};
    layout == null ? next.remove(id) : next[id] = layout;
    _noteLayouts = next;
    if (_activeNote == id) noteOverride.value = layout;
    try {
      _store?.setString(
        _noteKey,
        jsonEncode({for (final e in next.entries) e.key: e.value.toJson()}),
      );
    } catch (e) {
      ErrorLog.record('personalize-note-write', e);
    }
  }

  static bool get editing => draft.value != null;

  /// Bu oturumda bir şey değişti mi (şeritteki "Geri al" etkin mi).
  static bool get dirty => draft.value != null && prefs.value != _before;

  /// Uygulama açılışında (main) bir kez.
  static void attach(SharedPreferences store) {
    _store = store;
    aiOff.value = store.getBool(aiOffKey) ?? false;
    final notes = store.getString(_noteKey);
    if (notes != null) {
      try {
        final j = jsonDecode(notes) as Map<String, dynamic>;
        _noteLayouts = {
          for (final e in j.entries) e.key: UiPrefs.fromJson(e.value),
        };
      } catch (_) {
        // Bozuk kayıt: not başına düzen yok, genel düzen geçerli.
      }
    }
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
    // Alt çubuk / hızlı satır düğmesi: açık notun kendi düzeni varsa ona.
    if (isLayoutId(id) && noteHasOwnLayout) {
      updateLayout((p) => p.withVisible(id, !p.storedShows(id)));
      return;
    }
    update((p) => p.withVisible(id, !p.storedShows(id)));
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
    _noteLayouts = const {};
    _activeNote = null;
    _activeOwner = null;
    noteOverride.value = null;
    aiOff.value = false;
    prefs.value = const UiPrefs();
    draft.value = null;
  }
}
