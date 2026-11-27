// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Malay (`ms`).
class AppLocalizationsMs extends AppLocalizations {
  AppLocalizationsMs([String locale = 'ms']) : super(locale);

  @override
  String get appName => 'Nota';

  @override
  String get loginTagline => 'Nota anda pada setiap peranti';

  @override
  String get signInWithGoogle => 'Log masuk dengan Google';

  @override
  String loginError(String error) {
    return 'Log masuk gagal: $error';
  }

  @override
  String get searchHint => 'Cari...';

  @override
  String get filterAll => 'Semua';

  @override
  String get filterText => 'Teks';

  @override
  String get filterChecklist => 'Senarai';

  @override
  String get filterOrdered => 'Bernombor';

  @override
  String get filterPinned => 'Disemat';

  @override
  String get star => 'Bintangkan';

  @override
  String get unstar => 'Buang bintang';

  @override
  String get sectionOthers => 'Lain-lain';

  @override
  String get emptyNotes => 'Belum ada nota di sini';

  @override
  String get emptyFilter => 'Tiada nota yang sepadan dengan penapis ini';

  @override
  String get clearFilter => 'Kosongkan penapis';

  @override
  String get emptyFolderTitle => 'Belum ada nota di sini';

  @override
  String get newNoteAction => 'Tambah nota';

  @override
  String get emptySearch => 'Tiada yang sepadan dengan carian anda';

  @override
  String get newTextNote => 'Nota teks';

  @override
  String get newChecklist => 'Senarai';

  @override
  String get newOrderedList => 'Senarai bernombor';

  @override
  String get noteDeleted => 'Nota dipadam';

  @override
  String get dragTrashHint => 'Lepaskan di sini untuk memadam';

  @override
  String get dragTrashReady => 'Lepaskan untuk memadam';

  @override
  String notesDeletedCount(int count) {
    return '$count nota dipadam';
  }

  @override
  String selectedCount(int count) {
    return '$count dipilih';
  }

  @override
  String get deleteSelected => 'Padam yang dipilih';

  @override
  String get undo => 'Buat asal';

  @override
  String get redo => 'Buat semula';

  @override
  String get titleHint => 'Tajuk';

  @override
  String get bodyHint => 'Nota...';

  @override
  String get newItemHint => 'Item baharu';

  @override
  String moreItemsCount(int count) {
    return '+$count item lagi';
  }

  @override
  String get addAttachment => 'Tambah';

  @override
  String get addImage => 'Tambah imej';

  @override
  String attachmentFailed(String error) {
    return 'Tidak dapat menambah lampiran: $error';
  }

  @override
  String get attachmentCopying => 'Menyalin...';

  @override
  String get attachmentUploading => 'Memuat naik...';

  @override
  String get attachmentUploadFailed =>
      'Muat naik gagal — ketik untuk cuba lagi';

  @override
  String get attachmentNotSynced =>
      'Fail ini belum disegerakkan ke peranti ini';

  @override
  String get attachmentDeviceOnly =>
      'Fail besar: disimpan pada peranti ini sahaja, tidak disandarkan ke awan';

  @override
  String get attachmentOtherDevice =>
      'Fail besar ini hanya ada pada peranti ia ditambah; ia tidak dimuat turun di sini';

  @override
  String get attachmentDeviceFull =>
      'Ruang peranti tidak mencukupi untuk menyalin fail. Kosongkan sedikit ruang dan cuba lagi.';

  @override
  String get webDriveTapToOpen => 'Dalam Google Drive · ketik untuk membuka';

  @override
  String get noteFullscreen => 'Skrin penuh';

  @override
  String get noteFullscreenExit => 'Keluar dari skrin penuh';

  @override
  String get penModeDone => 'Tutup pen';

  @override
  String get pageInkOnCard => 'Ada tulisan tangan';

  @override
  String attachmentTooLarge(int limit) {
    return 'Fail terlalu besar (maks. $limit MB)';
  }

  @override
  String storageFull(String limit) {
    return 'Storan penuh ($limit). Padam lampiran lama untuk mengosongkan ruang.';
  }

  @override
  String get storageUsage => 'Storan';

  @override
  String storageUsageValue(String used, String limit) {
    return '$used daripada $limit digunakan';
  }

  @override
  String get removeAttachment => 'Buang lampiran';

  @override
  String get pin => 'Semat';

  @override
  String get unpin => 'Nyahsemat';

  @override
  String get delete => 'Padam';

  @override
  String get color => 'Warna';

  @override
  String get summarize => 'Ringkaskan';

  @override
  String get listen => 'Dengar';

  @override
  String get ask => 'Tanya soalan';

  @override
  String get extractText => 'Ekstrak teks';

  @override
  String get transcribe => 'Transkripsi';

  @override
  String get listenToNote => 'Dengar';

  @override
  String aiError(String error) {
    return 'Permintaan AI gagal: $error';
  }

  @override
  String get aiThinking => 'Sedang berfikir...';

  @override
  String get copy => 'Salin';

  @override
  String get copied => 'Disalin';

  @override
  String get settingsSearchHint => 'Cari tetapan — “kunci”, “mikrofon”';

  @override
  String settingsSearchEmpty(String query) {
    return 'Tiada tetapan yang sepadan dengan «$query»';
  }

  @override
  String get settings => 'Tetapan';

  @override
  String get settingsAppearance => 'Penampilan';

  @override
  String get themeSystem => 'Sistem';

  @override
  String get themeSage => 'Sage';

  @override
  String get themePorcelain => 'Porselin';

  @override
  String get themeClay => 'Tanah liat';

  @override
  String get themeDark => 'Gelap';

  @override
  String get privacyPolicyTitle => 'Dasar privasi';

  @override
  String get lockNote => 'Kunci';

  @override
  String get unlockNote => 'Buka kunci';

  @override
  String get lockedNote => 'Nota berkunci';

  @override
  String get unlockAuthReason =>
      'Sahkan identiti anda untuk membuka nota berkunci';

  @override
  String get exportBackup => 'Sandaran penuh';

  @override
  String get expandListItems => 'Tunjukkan baris senarai sepenuhnya';

  @override
  String get expandListItemsInfo =>
      'Item panjang dibalut dan dipaparkan penuh; jika dimatikan, satu baris.';

  @override
  String get quickCaptureRowSetting => 'Bar nota pantas';

  @override
  String get quickCaptureRowInfo =>
      'Medan satu baris “Nota baharu…” di bahagian atas laman utama.';

  @override
  String get emptyTrash => 'Kosongkan tong sampah';

  @override
  String emptyTrashConfirm(int count) {
    return '$count nota akan dipadam secara kekal. Ini tidak boleh dibuat asal. Anda pasti?';
  }

  @override
  String get trashEmptied => 'Tong sampah dikosongkan';

  @override
  String get validateAndSave => 'Sahkan dan simpan';

  @override
  String get clear => 'Kosongkan';

  @override
  String get apiKeyValid => 'Kunci API disahkan dan disimpan';

  @override
  String get apiKeyInvalid => 'Kunci API tidak sah';

  @override
  String get apiKeySavedBadge => 'Disimpan';

  @override
  String get removeApiKey => 'Padam kunci';

  @override
  String get refresh => 'Muat semula';

  @override
  String get account => 'Akaun';

  @override
  String get signOut => 'Log keluar';

  @override
  String get switchAccount => 'Tukar akaun';

  @override
  String get switchAccountConfirm =>
      'Anda akan dilog keluar daripada akaun ini dan pemilih akaun Google akan dibuka. Nota anda kekal dalam akaun ini dan akan ada apabila anda kembali.';

  @override
  String get switchAccountGuestWarning =>
      'Anda menggunakan akaun tetamu: jika anda bertukar, anda akan kehilangan akses kepada nota pada peranti ini. Pautkan akaun Google atau buat sandaran penuh dahulu.';

  @override
  String get penTrayShow => 'Tunjukkan dulang pen';

  @override
  String get addDrawingSubtitle =>
      'Lukis pada kanvas berasingan, dibenamkan sebagai imej';

  @override
  String get addGroupWrite => 'Tulis';

  @override
  String get addGroupPen => 'Pen';

  @override
  String get addGroupFiles => 'Fail dan pautan';

  @override
  String get addGroupSound => 'Bunyi';

  @override
  String get addGroupTemplate => 'Templat';

  @override
  String get addSeparateDrawing => 'Lukisan berasingan (imej)';

  @override
  String get addHandwriting => 'Tulis pada halaman (pen)';

  @override
  String get addHandwritingSubtitle => 'Mod pen: tulis terus pada halaman nota';

  @override
  String webDriveBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count lampiran berada dalam Google Drive anda — benarkan akses untuk melihatnya',
      one: '1 lampiran berada dalam Google Drive anda — benarkan akses untuk melihatnya',
    );
    return '$_temp0';
  }

  @override
  String get webDriveShow => 'Tunjukkan';

  @override
  String webAttachmentsOnPhone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count lampiran belum keluar dari telefon ia ditambah. Pada telefon: Tetapan → Segerak → sambungkan Drive.',
      one: '1 lampiran belum keluar dari telefon ia ditambah. Pada telefon: Tetapan → Segerak → sambungkan Drive.',
    );
    return '$_temp0';
  }

  @override
  String get fullscreenPullHint => 'Tarik untuk skrin penuh';

  @override
  String get fullscreenPullRelease => 'Lepaskan: skrin penuh';

  @override
  String get signOutConfirm => 'Anda pasti mahu log keluar?';

  @override
  String get signOutAnonymousWarning =>
      'Anda menggunakan akaun setempat: log keluar menjadikan akaun ini dan semua notanya tidak boleh diakses secara kekal — tanpa sandaran ia tidak boleh dipulihkan. Pautkan akaun Google dahulu untuk menyimpan nota anda. Log keluar juga?';

  @override
  String get deleteAccount => 'Padam akaun dan data saya';

  @override
  String get deleteAccountWarning =>
      'Ini tidak boleh dibuat asal: semua nota, lampiran dan akaun anda akan dipadam secara kekal. Teruskan?';

  @override
  String get deleteAccountConfirm => 'Padam secara kekal';

  @override
  String get deleteAccountPageInfo =>
      'Akaun dan semua data anda dipadam secara kekal: nota, folder, lampiran (awan dan, jika dipautkan, Drive), kenalan, nota diterima, folder yang anda kongsi dan rekod akaun anda. Salinan nota yang anda hantar kepada orang lain kekal pada mereka. Ini tidak boleh dibuat asal; buat sandaran dari Tetapan dahulu jika mahu.';

  @override
  String get licensesTitle => 'Lesen sumber terbuka';

  @override
  String get generating => 'Sedang menjana...';

  @override
  String get retry => 'Cuba lagi';

  @override
  String get cancel => 'Batal';

  @override
  String get close => 'Tutup';

  @override
  String get ok => 'OK';

  @override
  String get syncPending => 'Menunggu penyegerakan';

  @override
  String get synced => 'Disegerakkan';

  @override
  String get liteSyncHeld =>
      'Perubahan dihantar ke awan setiap beberapa minit — ketik untuk segerak sekarang';

  @override
  String get liteSyncSending => 'Menghantar perubahan ke awan';

  @override
  String genericError(String error) {
    return 'Berlaku ralat: $error';
  }

  @override
  String get addTag => 'Tag';

  @override
  String get tagHint => 'cth. kerja, rumah, sekolah';

  @override
  String get addReminder => 'Ingatkan saya';

  @override
  String get placeReminder => 'Peringatan lokasi';

  @override
  String get placeReminderHint =>
      'Terima nota ini sebagai pemberitahuan apabila anda tiba atau meninggalkan sesuatu tempat. Sistem memantau lokasi; ia berfungsi walaupun aplikasi ditutup.';

  @override
  String get placeCurrent => 'Lokasi semasa saya';

  @override
  String get placeSearchHint => 'Cari alamat atau tempat';

  @override
  String get placeSearchNone => 'Tiada hasil';

  @override
  String get placeArrive => 'Semasa tiba';

  @override
  String get placeLeave => 'Semasa pergi';

  @override
  String get placeRadius => 'Jejari';

  @override
  String get placeSave => 'Tetapkan peringatan';

  @override
  String get placeRemove => 'Buang peringatan lokasi';

  @override
  String get placeSet => 'Peringatan lokasi ditetapkan';

  @override
  String get placeRemoved => 'Peringatan lokasi dibuang';

  @override
  String get placeNeedPermission =>
      'Kebenaran lokasi tidak diberikan. Anda boleh membenarkannya dalam tetapan.';

  @override
  String get placeNeedBackground =>
      'Untuk berfungsi semasa aplikasi ditutup, tetapkan kebenaran lokasi kepada \"Benarkan sepanjang masa\".';

  @override
  String get placeBackgroundTitle => 'Kebenaran \"Sepanjang masa\" diperlukan';

  @override
  String get placeOpenSettings => 'Benarkan';

  @override
  String get placeLocationOff =>
      'Lokasi peranti dimatikan. Hidupkan dan cuba lagi.';

  @override
  String get placeFailed => 'Tidak dapat menetapkan peringatan lokasi.';

  @override
  String get placeNoLocation =>
      'Tidak dapat mendapatkan lokasi anda. Pastikan lokasi dihidupkan.';

  @override
  String placeArrivedBody(String place) {
    return 'Anda tiba di $place';
  }

  @override
  String placeLeftBody(String place) {
    return 'Anda meninggalkan $place';
  }

  @override
  String get share => 'Kongsi';

  @override
  String get archive => 'Arkibkan';

  @override
  String get unarchive => 'Nyaharkib';

  @override
  String get archiveTitle => 'Arkib';

  @override
  String get archiveEmpty => 'Tiada nota diarkibkan di sini';

  @override
  String get trashTitle => 'Tong sampah';

  @override
  String get trashEmpty => 'Tiada nota dipadam di sini';

  @override
  String get trashInfo =>
      'Nota yang dipadam kekal di sini; anda boleh memulihkan atau memadamnya secara kekal.';

  @override
  String get restore => 'Pulihkan';

  @override
  String get deleteForever => 'Padam secara kekal';

  @override
  String get deleteForeverConfirm =>
      'Nota ini akan dipadam secara kekal. Anda pasti?';

  @override
  String get recordAudio => 'Rakaman suara';

  @override
  String get recording => 'Merakam...';

  @override
  String get stopAndSave => 'Selesai dan tambah';

  @override
  String get micPermissionDenied => 'Kebenaran mikrofon ditolak';

  @override
  String get addDrawing => 'Tambah lukisan';

  @override
  String get addToNote => 'Tambah ke nota';

  @override
  String get fontSize => 'Saiz teks';

  @override
  String get fontSizePreview => 'Nota anda akan kelihatan seperti ini';

  @override
  String get darkSchedule => 'Jadual tema gelap';

  @override
  String get darkScheduleInfo =>
      'Bertukar kepada tema gelap antara waktu yang anda tetapkan';

  @override
  String get voiceCommand => 'Arahan suara';

  @override
  String get suggestTags => 'Cadangkan tag';

  @override
  String get existingTagsLabel => 'Tag terdahulu';

  @override
  String get voiceFinish => 'Selesai';

  @override
  String get voiceProcessing => 'Menggunakan apa yang anda sebut...';

  @override
  String get voiceNothingHeard => 'Tiada pertuturan dikesan dalam rakaman';

  @override
  String get voiceNoteSaved => 'Nota suara anda telah disimpan';

  @override
  String get openNote => 'Buka nota';

  @override
  String get remindersTitle => 'Peringatan';

  @override
  String get remindersEmpty => 'Tiada peringatan di sini';

  @override
  String get remindersEmptyHint =>
      'Tambah peringatan pada nota, atau tulis nota baharu dengan peringatan melalui +.';

  @override
  String get remindersUpcoming => 'Akan datang';

  @override
  String get remindersPast => 'Lepas';

  @override
  String get reminderInPast =>
      'Masa yang dipilih telah berlalu — pilih masa akan datang.';

  @override
  String get newReminder => 'Peringatan baharu';

  @override
  String get remindersUntitled => 'Nota tanpa tajuk';

  @override
  String get remindersEdit => 'Tukar masa';

  @override
  String get remindersRemove => 'Buang peringatan';

  @override
  String get clearNote => 'Kosongkan kandungan';

  @override
  String get clearNoteConfirm =>
      'Kandungan nota (teks dan item senarai) akan dipadam. Anda pasti?';

  @override
  String get calculatorTitle => 'Kalkulator';

  @override
  String get calcExpressionHint => 'cth. 12.5×3+40';

  @override
  String get calcInvalid => 'Ungkapan tidak sah';

  @override
  String get liveDictation => 'Imlak';

  @override
  String get dictationHoldHint =>
      'Tahan mikrofon dan bercakap; teks ditulis apabila anda lepaskan';

  @override
  String itemsSelected(int count) {
    return '$count item dipilih';
  }

  @override
  String get dictationProcessing => 'Mentranskripsi...';

  @override
  String get voiceListening => 'Sedang mendengar...';

  @override
  String get voiceTapHint => 'Ketik dan bercakap; ketik lagi untuk selesai';

  @override
  String get voiceModeSetting => 'Cara ia berfungsi';

  @override
  String get voiceModeHold => 'Tahan untuk bercakap';

  @override
  String get voiceModeTap => 'Ketik untuk mula';

  @override
  String get voiceModeInfo =>
      'Tahan: berhenti apabila dilepaskan. Ketik: ketikan kedua menghentikannya.';

  @override
  String get voiceCaptureReady => 'Pertuturan sedia';

  @override
  String get voiceCaptureEditHint => 'Ketik teks untuk menyunting';

  @override
  String voiceCapturePunctuation(String language) {
    return '$language · tanda baca automatik';
  }

  @override
  String get voiceCaptureAddToNote => 'Tambah ke nota';

  @override
  String get voiceCaptureCreateNote => 'Cipta nota baharu';

  @override
  String get voiceCaptureAiNote => 'Nota AI';

  @override
  String get voiceCapturePlainNote => 'Nota biasa';

  @override
  String get voiceCloseTitle => 'Imlak anda masih di sini';

  @override
  String get voiceCloseKeepTalking => 'Teruskan bercakap';

  @override
  String get voiceCaptureRestart => 'Rakam semula';

  @override
  String get voiceChipSummarizeAdd => 'Tambah sebagai ringkasan';

  @override
  String get voiceChipSummarizeSave => 'Simpan sebagai ringkasan';

  @override
  String get voiceChipToItems => 'Pecahkan kepada item';

  @override
  String get voiceChipAsList => 'Jadikan senarai semak';

  @override
  String get voiceChipFix => 'Kemaskan';

  @override
  String get permissionsTitle => 'Kebenaran';

  @override
  String get permMic => 'Mikrofon';

  @override
  String get permMicInfo =>
      'Diperlukan untuk nota suara AI, imlak dan rakaman audio';

  @override
  String get permNotifications => 'Pemberitahuan';

  @override
  String get permNotificationsInfo =>
      'Diperlukan untuk peringatan dan taklimat harian';

  @override
  String get permExactAlarm => 'Penggera & peringatan';

  @override
  String get permExactAlarmInfo =>
      'Jika dimatikan, peringatan boleh lewat beberapa minit. Benarkan untuk Nota';

  @override
  String get permBattery => 'Pengoptimuman bateri';

  @override
  String get permBatteryInfo =>
      'Kecualikan aplikasi daripada had bateri supaya peringatan tidak lewat';

  @override
  String get permAutoStart => 'Mula automatik (Xiaomi)';

  @override
  String get permAutoStartInfo =>
      'Pulihkan peringatan selepas dimulakan semula: hidupkan “Mula automatik”';

  @override
  String get autoStartHint =>
      'Xiaomi: benarkan “Mula automatik” untuk aplikasi supaya peringatan tetap berbunyi selepas but semula';

  @override
  String get autoStartHintAction => 'Buka';

  @override
  String get exactAlarmHint =>
      'Kebenaran penggera dimatikan: peringatan mungkin lewat beberapa minit';

  @override
  String get exactAlarmHintAction => 'Benarkan';

  @override
  String get permCamera => 'Kamera';

  @override
  String get permCameraInfo => 'Diperlukan untuk nota video dan mengambil foto';

  @override
  String get newVideoNote => 'Rakam video';

  @override
  String get videoLocalOnly =>
      'Video ini disimpan pada peranti ini sahaja (tidak dimuat naik ke awan)';

  @override
  String get videoToNote => 'Buat nota daripada video';

  @override
  String get permGranted => 'Diberikan';

  @override
  String get permGrant => 'Berikan';

  @override
  String get permOpenSettings => 'Buka tetapan';

  @override
  String get newVoiceCapture => 'Nota suara AI';

  @override
  String get suggestTitle => 'Cadangkan tajuk';

  @override
  String get noteMetaMenu => 'Tag · Peringatan · Folder';

  @override
  String get folder => 'Folder';

  @override
  String get noFolder => 'Tiada folder';

  @override
  String get newFolder => 'Folder baharu';

  @override
  String get editFolder => 'Sunting folder';

  @override
  String get deleteFolder => 'Padam folder';

  @override
  String deleteFolderConfirm(String name) {
    return 'Folder \"$name\" akan dipadam. Nota di dalamnya tidak dipadam — ia hanya tiada folder.';
  }

  @override
  String get folderNameHint => 'Nama folder';

  @override
  String get folderIcon => 'Ikon';

  @override
  String get select => 'Pilih';

  @override
  String get noteArchived => 'Nota diarkibkan';

  @override
  String pendingUploads(int count) {
    return '$count lampiran sedang dimuat naik';
  }

  @override
  String pendingUploadsFailed(int count) {
    return '$count lampiran gagal, akan dicuba semula';
  }

  @override
  String pendingUploadsOffline(int count) {
    return '$count lampiran menunggu — akan dimuat naik apabila anda dalam talian';
  }

  @override
  String get pendingUploadsInfo =>
      'Lampiran selamat pada peranti ini. Ia dimuat naik secara automatik apabila anda dalam talian; sehingga itu ia tidak muncul pada peranti anda yang lain.';

  @override
  String checkedHeader(int count) {
    return 'Ditanda ($count)';
  }

  @override
  String deleteChecked(int count) {
    return 'Padam yang ditanda ($count)';
  }

  @override
  String get removeItem => 'Padam item';

  @override
  String get copyWholeNote => 'Salin seluruh nota';

  @override
  String get allCopied => 'Seluruh nota disalin ke papan keratan';

  @override
  String get speechRate => 'Kelajuan membaca';

  @override
  String get speechNoVoices => 'Tiada suara dipasang pada peranti ini';

  @override
  String get speechVoiceAutoInfo =>
      'Bahasa lain dibaca secara automatik dengan suara lelaki';

  @override
  String get listening => 'Sedang mendengar...';

  @override
  String get exportPdf => 'Eksport sebagai PDF';

  @override
  String get pdfTitleField => 'Tajuk';

  @override
  String get pdfContentField => 'Kandungan';

  @override
  String get pdfMarkupHint =>
      'Tanda di awal baris menjadi format: [x] dan [ ] untuk kotak semak, 1. untuk senarai bernombor, - untuk titik.';

  @override
  String get pdfIncludeDate => 'Sertakan tarikh';

  @override
  String get exportIncludeImages => 'Sertakan imej';

  @override
  String get exportWord => 'Kongsi sebagai Word (.docx)';

  @override
  String get pdfPreview => 'Pratonton';

  @override
  String get largeAttachmentTitle => 'Fail besar';

  @override
  String largeAttachmentBody(String size) {
    return 'Fail ini $size MB. PDF tidak boleh dimampatkan; ia akan dimuat naik seadanya dan dikira dalam storan anda. Teruskan?';
  }

  @override
  String get speechRateForeign => 'Kelajuan bahasa asing';

  @override
  String notesArchivedCount(int count) {
    return '$count nota diarkibkan';
  }

  @override
  String get backgroundColor => 'Warna latar';

  @override
  String get backgroundColorInfo =>
      'Latar nota — dipaparkan dalam nota dan di laman utama';

  @override
  String get frameColor => 'Bingkai';

  @override
  String get sortBy => 'Isih';

  @override
  String get reorderNotes => 'Susun semula nota';

  @override
  String get reorderModeActive => 'Seret kad untuk menyusun semula';

  @override
  String get reorderDone => 'Selesai';

  @override
  String get sortManual => 'Manual (susunan seret)';

  @override
  String get sortUpdated => 'Dikemas kini baru-baru ini';

  @override
  String get sortCreated => 'Tarikh dicipta';

  @override
  String get sortTitle => 'Mengikut tajuk (A–Z)';

  @override
  String get settingsLanguage => 'Bahasa';

  @override
  String get languageSystem => 'Bahasa sistem';

  @override
  String get syncTitle => 'Penyegerakan';

  @override
  String get syncLimitTitle => 'Had muat naik automatik';

  @override
  String get syncLimitInfo =>
      'Lampiran lebih besar kekal pada peranti; teks nota sentiasa disegerakkan.';

  @override
  String get syncLimitUnlimited => 'Tiada had';

  @override
  String get importBackup => 'Pulihkan daripada sandaran';

  @override
  String get importBackupInvalid => 'Fail sandaran tidak sah';

  @override
  String get moveToFolder => 'Alih ke folder';

  @override
  String get assistantGenericError => 'Berlaku ralat — boleh anda cuba lagi?';

  @override
  String get quickAddTooltip => 'Nota baharu — pilih jenis';

  @override
  String get annotate => 'Anotasi';

  @override
  String get annotateDone => 'Selesai anotasi';

  @override
  String get newPdfNote => 'Nota daripada PDF';

  @override
  String get imageNotePreparing => 'Menyusun imej menjadi dokumen…';

  @override
  String get newImageNote => 'Nota daripada imej';

  @override
  String get pdfPageNoteHint => 'Nota untuk halaman ini…';

  @override
  String pdfPage(int page) {
    return 'Halaman $page';
  }

  @override
  String pdfPageOf(int page, int total) {
    return 'Halaman $page / $total';
  }

  @override
  String get pdfPreviousPage => 'Halaman sebelumnya';

  @override
  String get pdfNextPage => 'Halaman seterusnya';

  @override
  String get pdfFullScreen => 'Buka skrin penuh';

  @override
  String get pdfNoDocument => 'Nota ini belum ada PDF';

  @override
  String get pdfChooseDocument => 'Pilih PDF';

  @override
  String get newSlidesNote => 'Nota daripada slaid';

  @override
  String get slidesNoDocument => 'Nota ini belum ada persembahan';

  @override
  String get slidesChooseDocument => 'Pilih persembahan';

  @override
  String get pdfEditPages => 'Sunting halaman';

  @override
  String get pdfDeletePages => 'Padam halaman yang dipilih';

  @override
  String get pdfAddBlankPage => 'Tambah halaman kosong';

  @override
  String get pdfRotatePages => 'Putar';

  @override
  String get pdfBurnInk => 'Benamkan tulisan tangan ke dalam dokumen';

  @override
  String get pdfApplyChanges => 'Gunakan perubahan';

  @override
  String get pdfCannotDeleteAllPages =>
      'Anda tidak boleh memadam semua halaman';

  @override
  String get pdfPagesHint =>
      'Ketik halaman untuk memilihnya. Nota halaman bergerak bersama halamannya; nota halaman yang dipadam disembunyikan tetapi kekal dalam data anda.';

  @override
  String pdfEditFailed(String error) {
    return 'Tidak dapat menyunting PDF: $error';
  }

  @override
  String get pdfInkBurned => 'Tulisan tangan dibenamkan ke dalam dokumen';

  @override
  String get pdfAllPageNotes => 'Semua nota halaman';

  @override
  String get pdfNoPageNotes =>
      'Belum ada nota halaman. Pergi ke halaman dan tulis dalam medan di bawah.';

  @override
  String get crop => 'Pangkas';

  @override
  String get cropApply => 'Gunakan pangkasan';

  @override
  String get cropReset => 'Set semula pilihan';

  @override
  String get cropHint =>
      'Seret sudut untuk memilih kawasan. Pangkasan tidak boleh dibuat asal.';

  @override
  String get cropFailed => 'Tidak dapat memangkas imej.';

  @override
  String get penBallpoint => 'Pen mata bola';

  @override
  String get penFountain => 'Pen dakwat';

  @override
  String get penMarker => 'Penanda';

  @override
  String get penHighlighter => 'Penyerlah';

  @override
  String get eraser => 'Pemadam';

  @override
  String get inkArrow => 'Anak panah';

  @override
  String get clearInk => 'Kosongkan anotasi';

  @override
  String get inkCleared => 'Anotasi dikosongkan';

  @override
  String get inkEraserTooltip => 'Pemadam (tahan: kosongkan semua)';

  @override
  String get inkTwoFingerHint =>
      'Satu jari melukis · dua jari menggerak dan zum';

  @override
  String get slideOpenFailed => 'Persembahan tidak dapat dibuka';

  @override
  String get newPhotoNote => 'Ambil foto';

  @override
  String get newScanNote => 'Imbas dokumen';

  @override
  String get scanDocument => 'Imbas dokumen';

  @override
  String get scanDocumentSubtitle =>
      'Mencari tepi, meratakan halaman dan menambahnya';

  @override
  String get scanUnsupported =>
      'Pengimbasan dokumen tidak disokong pada peranti ini';

  @override
  String scanFailed(String error) {
    return 'Tidak dapat mengimbas dokumen: $error';
  }

  @override
  String scanPagesAdded(int count) {
    return '$count halaman ditambah ke nota';
  }

  @override
  String get scanTextTitle => 'Kenal pasti teks juga?';

  @override
  String get scanTextBody =>
      'Teks pada halaman dikenal pasti dan ditulis ke dalam nota. Imej kekal seperti asal. Mengambil beberapa saat setiap halaman.';

  @override
  String get scanImageOnly => 'Imej sahaja';

  @override
  String get scanRecognizeText => 'Kenal pasti teks';

  @override
  String get scanRecognizing => 'Mengenal pasti teks…';

  @override
  String get takePhoto => 'Ambil foto';

  @override
  String get qrScanTitle => 'Imbas kod QR';

  @override
  String get qrScanSubtitle => 'Baca dengan kamera atau daripada foto';

  @override
  String get qrScanHint => 'Letakkan kod di dalam bingkai';

  @override
  String get qrFromPhoto => 'Baca daripada foto';

  @override
  String get qrNotFound => 'Tiada kod ditemui dalam imej ini';

  @override
  String get qrLinkFound => 'Kod ini ialah pautan';

  @override
  String get qrOpenLink => 'Pergi ke pautan';

  @override
  String get qrSaveToNote => 'Simpan ke nota';

  @override
  String get openLink => 'Buka pautan';

  @override
  String get linkOpenFailed => 'Pautan tidak dapat dibuka';

  @override
  String qrScanFailed(String error) {
    return 'Tidak dapat membaca kod: $error';
  }

  @override
  String get qrTorch => 'Lampu suluh';

  @override
  String get hideAttachments => 'Sembunyikan';

  @override
  String get showAttachments => 'Tunjukkan';

  @override
  String get selectAllItems => 'Pilih semua';

  @override
  String get checkSelectedItems => 'Tanda yang dipilih';

  @override
  String get itemUncheck => 'Nyahtanda';

  @override
  String get uncheckSelectedItems => 'Nyahtanda yang dipilih';

  @override
  String get hiddenFolder => 'Folder tersembunyi';

  @override
  String get hiddenFolderInfo =>
      'Folder tersembunyi dan notanya tidak muncul di laman utama. Untuk menunjukkannya, pilih \"Folder tersembunyi\" daripada menu ⋮ dan sahkan identiti anda.';

  @override
  String get hiddenFoldersMenu => 'Folder tersembunyi';

  @override
  String get hiddenFolderAuthReason =>
      'Sahkan identiti anda untuk menunjukkan folder tersembunyi';

  @override
  String get hiddenFoldersShown => 'Folder tersembunyi sedang ditunjukkan';

  @override
  String get hiddenFoldersHiddenAgain =>
      'Folder tersembunyi disembunyikan semula';

  @override
  String get makeFolderHidden => 'Sembunyikan';

  @override
  String get makeFolderVisible => 'Tunjukkan';

  @override
  String gridColumnsCount(int count) {
    return '$count lajur';
  }

  @override
  String get addImageOnPageSubtitle =>
      'Berada pada halaman, teks mengalir di sekelilingnya';

  @override
  String get addImageAsFile => 'Tambah imej sebagai fail';

  @override
  String get addImageAsFileSubtitle =>
      'Kekal di luar halaman, dalam jalur lampiran';

  @override
  String get attachmentCopied => 'Lampiran disalin';

  @override
  String get pasteAttachment => 'Tampal lampiran yang disalin';

  @override
  String get fullscreen => 'Skrin penuh';

  @override
  String get more => 'Lagi';

  @override
  String get undone => 'Dibuat asal';

  @override
  String get filterOthers => 'Tiada folder atau tag';

  @override
  String get aiHistoryVoiceNote => 'Nota suara AI';

  @override
  String get sectionPinnedShort => 'Disemat';

  @override
  String get sectionUrgent => 'Segera';

  @override
  String get urgentMark => 'Tanda segera';

  @override
  String get urgentUnmark => 'Buang tanda segera';

  @override
  String get urgentInfo => 'Dipaparkan pertama di laman utama, dengan !';

  @override
  String get sectionToday => 'Hari ini';

  @override
  String get sectionThisWeek => 'Minggu ini';

  @override
  String get sectionEarlier => 'Terdahulu';

  @override
  String sectionNoteCount(int count) {
    return '$count nota';
  }

  @override
  String get quickCaptureHint => 'Nota baharu…';

  @override
  String get quickCaptureSave => 'Simpan';

  @override
  String get viewToggle => 'Paparan';

  @override
  String get viewGrid => 'Grid';

  @override
  String get viewList => 'Senarai';

  @override
  String get filterReminded => 'Dengan peringatan';

  @override
  String get filterLocked => 'Berkunci';

  @override
  String get sortColor => 'Warna';

  @override
  String get sortActive => 'Paling banyak diusahakan';

  @override
  String get voicePreview => 'Cuba suara';

  @override
  String get reorderHint =>
      'Tekan lama kad, kemudian seret ke tempat yang anda mahu';

  @override
  String get filterSheetTitle => 'Tapis';

  @override
  String get filterReset => 'Set semula';

  @override
  String get filterSectionStatus => 'Status';

  @override
  String get filterSectionFolder => 'Folder';

  @override
  String get filterSectionTag => 'Tag';

  @override
  String get filterSectionSort => 'Isihan';

  @override
  String get filterSheetSortHint =>
      'Kumpulan tarikh (Hari ini, Minggu ini…) hanya dipaparkan apabila diisih mengikut “Dikemas kini baru-baru ini”.';

  @override
  String get formatTitle => 'Format';

  @override
  String get formatBold => 'Tebal';

  @override
  String get formatItalic => 'Condong';

  @override
  String get formatUnderline => 'Garis bawah';

  @override
  String get formatTextColor => 'Warna teks';

  @override
  String get formatHighlight => 'Serlah';

  @override
  String get formatInfo =>
      'Format dibawa dalam teks sebagai penanda (seperti **tebal**); penanda kekal tersembunyi dalam eksport dan bacaan suara.';

  @override
  String get formatMenu => 'Format…';

  @override
  String get noteFontDefault => 'Lalai';

  @override
  String get noteFontSerif => 'Buku (serif)';

  @override
  String get noteFontMono => 'Mesin taip';

  @override
  String get noteTextSize => 'Saiz teks';

  @override
  String get formatClear => 'Kosongkan format';

  @override
  String get formatHeading => 'Tajuk';

  @override
  String get noteTextOpacity => 'Kelegapan';

  @override
  String get assistantMute => 'Senyapkan';

  @override
  String get assistantUnmute => 'Nyahsenyap';

  @override
  String get assistantMakeNote => 'Jadikan nota juga';

  @override
  String get assistantNoteCreated => 'Nota dicipta';

  @override
  String get noteNotFound => 'Nota tidak ditemui. Ia mungkin telah dipadam.';

  @override
  String get back => 'Kembali';

  @override
  String get addTextBlock => 'Tambah teks';

  @override
  String get noteBackgroundImage => 'Imej latar';

  @override
  String get changeBackgroundImage => 'Tukar imej';

  @override
  String get removeBackgroundImage => 'Buang latar';

  @override
  String get dashboardBackground => 'Latar laman utama';

  @override
  String get dashboardBackgroundInfo =>
      'Imej yang dipaparkan di belakang grid nota (peranti ini sahaja).';

  @override
  String get apiKeyFieldLabel => 'Kunci API';

  @override
  String get getApiKey => 'Di mana mendapatkan kunci?';

  @override
  String get continueWithoutAccount => 'Teruskan tanpa akaun';

  @override
  String get localAccountInfo =>
      'Nota anda kekal pada peranti ini sahaja: ia tidak boleh dibuka di tempat lain dan hilang jika aplikasi dinyahpasang. AI terbina dalam, kenalan dan perkongsian memerlukan akaun Google; anda masih boleh menggunakan AI dengan kunci API sendiri. Anda boleh memautkan akaun Google bila-bila masa — nota anda turut dibawa.';

  @override
  String get localAccountBadge => 'Akaun setempat';

  @override
  String get profileGuestName => 'Tetamu';

  @override
  String get profileGuestSignIn => 'Log masuk';

  @override
  String get linkGoogleAccount => 'Pautkan akaun Google';

  @override
  String get accountLinked =>
      'Akaun Google anda dipautkan. Nota anda kini disandarkan.';

  @override
  String scanReviewPage(int current, int total) {
    return 'Halaman $current / $total';
  }

  @override
  String get scanRotatePage => 'Putar halaman';

  @override
  String get scanDeletePage => 'Padam halaman';

  @override
  String get scanLastPage => 'Halaman terakhir tidak boleh dipadam';

  @override
  String get scanDiscardTitle => 'Buang halaman yang diimbas?';

  @override
  String get scanDiscardConfirm => 'Buang';

  @override
  String get scanAdjustCorners => 'Laraskan sudut';

  @override
  String get scanFilterOriginal => 'Asal';

  @override
  String get scanFilterAuto => 'Pertingkat';

  @override
  String get scanFilterGray => 'Skala kelabu';

  @override
  String get scanFilterBw => 'Hitam putih';

  @override
  String get scanApplyAll => 'Gunakan pada semua';

  @override
  String get scanPageFailed => 'Tidak dapat memaparkan halaman';

  @override
  String get scanCropHint =>
      'Betulkan halaman senget dengan \"Laraskan sudut\"';

  @override
  String get scanAddAsPdf => 'Tambah sebagai PDF';

  @override
  String get scanAddAsImages => 'Tambah sebagai imej';

  @override
  String get scanBuildingPdf => 'Menyediakan PDF…';

  @override
  String scanOcrProgress(int done, int total) {
    return 'Mengenal pasti teks… $done/$total';
  }

  @override
  String get scanAutoDetect => 'Kesan tepi secara automatik';

  @override
  String get scanReset => 'Set semula';

  @override
  String get scanDetecting => 'Mencari tepi…';

  @override
  String get scanAutoFound =>
      'Tepi ditemui secara automatik; halusi dengan pemegang jika perlu';

  @override
  String get scanDragHint => 'Seret sudut ke tepi kertas';

  @override
  String get scanApplyCorners => 'Luruskan & gunakan';

  @override
  String get scanWorking => 'Meluruskan…';

  @override
  String get scanPdfAdded => 'Imbasan ditambah ke nota sebagai lampiran PDF';

  @override
  String get premiumTitle => 'Premium';

  @override
  String get premiumStatusFree => 'Anda menggunakan versi percuma';

  @override
  String get guestSignInUnavailable =>
      'Log masuk tanpa Google sedang dimatikan: log masuk tanpa nama tidak didayakan dalam konsol Firebase (Authentication → Sign-in method). Log masuk dengan Google, atau cuba lagi selepas pentadbir mendayakannya.';

  @override
  String get googleSignInUnavailable =>
      'Log masuk Google sedang dimatikan: penyedia Google tidak didayakan dalam konsol Firebase.';

  @override
  String get signInNetworkError =>
      'Tidak dapat mencapai internet. Semak sambungan anda dan cuba lagi.';

  @override
  String get signInCanceled => 'Log masuk dibatalkan.';

  @override
  String get cardRichPreview => 'Teks berformat pada kad';

  @override
  String get cardRichPreviewInfo =>
      'Kad memaparkan warna, serlahan, tebal dan garis bawah.';

  @override
  String get cardHideSensitive => 'Sembunyikan kandungan sensitif pada kad';

  @override
  String get cardHideSensitiveInfo =>
      'Nota kata laluan dan nombor kad/IBAN disembunyikan pada kad.';

  @override
  String get sensitiveHiddenOnCard =>
      'Kandungan sensitif — disembunyikan pada kad';

  @override
  String get paletteMore => 'Lebih banyak warna';

  @override
  String get paletteCustom => 'Warna tersuai';

  @override
  String get paletteUse => 'Guna';

  @override
  String get paletteHue => 'Rona';

  @override
  String get paletteSaturation => 'Ketepuan';

  @override
  String get paletteLightness => 'Kecerahan';

  @override
  String get itemMoveToPage => 'Alih ke halaman lain';

  @override
  String itemMovedToPage(int page) {
    return 'Item dialihkan ke halaman $page';
  }

  @override
  String get archiveInsights => 'Apa dalam arkib saya?';

  @override
  String archiveInsightsStats(int count, int files, int stale) {
    return '$count nota · $files lampiran · $stale tidak disentuh setahun';
  }

  @override
  String get archiveByFolder => 'Mengikut folder';

  @override
  String get archiveNoFolder => 'Tiada folder';

  @override
  String get archiveStale => 'Tidak disentuh setahun';

  @override
  String get lineSpacing => 'Jarak baris';

  @override
  String get lineSpacingNormal => 'Biasa';

  @override
  String get lineSpacingWide => 'Lebar';

  @override
  String get lineSpacingWider => 'Lebih lebar';

  @override
  String get trashReminderTitle =>
      'Ada sesuatu dalam tong sampah yang mungkin patut disimpan';

  @override
  String trashReminderBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nota akan dipadam secara kekal esok',
      one: 'Sebuah nota akan dipadam secara kekal esok',
    );
    return '$_temp0 — nampaknya ia masih mengandungi tugasan atau maklumat penting. Lihatlah.';
  }

  @override
  String get groupByFolder => 'Kumpulkan mengikut folder';

  @override
  String get fontSizeSmall => 'Kecil';

  @override
  String get fontSizeMedium => 'Sederhana';

  @override
  String get fontSizeLarge => 'Besar';

  @override
  String get fontSizeXLarge => 'Sangat besar';

  @override
  String get appFontSetting => 'Fon';

  @override
  String get appFontInfo =>
      'Muka taip aplikasi; sesetengahnya dimuat turun apabila dipilih.';

  @override
  String get fontNeedsDownload => 'Dimuat turun sekali apabila dipilih';

  @override
  String get followSystemTextScale => 'Ikut saiz teks sistem';

  @override
  String get followSystemTextScaleInfo =>
      'Saiz teks telefon turut digunakan pada aplikasi.';

  @override
  String get pdfSelectOcrRunning => 'Mengenal pasti teks…';

  @override
  String get pdfSelectOcrNone => 'Tiada teks ditemui pada halaman ini';

  @override
  String pdfSelectCopied(int n) {
    return '$n aksara disalin';
  }

  @override
  String get bubbleAdd => 'Letak gelembung nota';

  @override
  String get bubbleAddDone => 'Selesai menambah gelembung';

  @override
  String get bubbleCollapse => 'Kuncupkan gelembung';

  @override
  String get bubbleHint => 'Tulis nota anda di sini…';

  @override
  String get bubbleTapToPlace => 'Ketik halaman di tempat anda mahu gelembung';

  @override
  String get ttsSectionTitle => 'Narasi';

  @override
  String get ttsEngineDevice => 'Suara peranti';

  @override
  String get ttsEngineDeviceInfo =>
      'Suara terbina dalam peranti yang membaca: percuma, luar talian dan tanpa had panjang.';

  @override
  String get shareAsNotePreparing => 'Menyediakan pakej nota…';

  @override
  String get shareAsTextEmpty => 'Nota ini tiada teks untuk dikongsi.';

  @override
  String get sharePdfWithBubbles => 'Sebagai PDF dengan gelembung';

  @override
  String get sharePdfWithBubblesInfo =>
      'Gelembung, serlahan dan lukisan dicop ke dalam PDF; sesiapa boleh membukanya, dan dalam aplikasi ia dibuka boleh disunting.';

  @override
  String get sharePdfWithBubblesNone =>
      'Nota ini tiada PDF yang membawa gelembung atau lukisan.';

  @override
  String get sharePdfWithBubblesPreparing =>
      'Menyediakan PDF dengan gelembung…';

  @override
  String get sharePdfWithBubblesSuffix => ' (dengan gelembung)';

  @override
  String get bubbleStar => 'Bintangkan';

  @override
  String get bubbleEdit => 'Sunting gelembung';

  @override
  String get bubbleStarredOnly => 'Berbintang sahaja';

  @override
  String get bubbleSearchHint => 'Cari gelembung…';

  @override
  String get bubblesListAll => 'Semua gelembung';

  @override
  String get bubblesOverviewTitle => 'Gelembung';

  @override
  String get bubblesEmpty =>
      'Belum ada gelembung. Pilih teks dalam dokumen dan serlahkan, atau letak gelembung pada halaman.';

  @override
  String get bubblesNoMatch =>
      'Tiada gelembung yang sepadan dengan carian anda.';

  @override
  String get bubbleNoText => '(gelembung kosong)';

  @override
  String get pdfHighlight => 'Serlah';

  @override
  String get pdfHighlightWithNote => 'Serlah + nota';

  @override
  String get pageNotesShow => 'Tunjukkan nota halaman';

  @override
  String get pageNotesHide => 'Sembunyikan nota halaman';

  @override
  String get bubbleSave => 'Simpan';

  @override
  String get bubbleTitleHint => 'Tajuk';

  @override
  String get bubbleUrgent => 'Segera (berkelip)';

  @override
  String get captureModeQuestion => 'Bagaimana nota harus dibuka?';

  @override
  String get captureModeBubbles => 'Gelembung';

  @override
  String get captureModeBubblesInfo =>
      'Kandungan menjadi halaman dokumen: gelembung, serlahan dan pen.';

  @override
  String get captureModeClassic => 'Klasik';

  @override
  String get captureModeClassicInfo =>
      'Nota teks biasa; dokumen menjadi lampiran.';

  @override
  String get captureModeNew => 'BAHARU';

  @override
  String get imagePrepareTitle => 'Laraskan imej';

  @override
  String get imagePrepareDone => 'Teruskan';

  @override
  String get imageRotateLeft => 'Putar ke kiri';

  @override
  String get imageRotateRight => 'Putar ke kanan';

  @override
  String get videoFrameFailed =>
      'Tidak dapat mengambil bingkai daripada video; membuka nota klasik.';

  @override
  String get bubbleArrowHide => 'Sembunyikan anak panah';

  @override
  String get bubbleArrowShow => 'Tunjukkan anak panah';

  @override
  String get speechPitch => 'Nada suara';

  @override
  String get speechVoicePickerTitle => 'Pilihan suara';

  @override
  String get formatRemove => 'Buang';

  @override
  String get exportNotesOption => 'PDF / Word tersuai…';

  @override
  String get exportNotesOptionInfo =>
      'Teks dan imej nota sebagai PDF atau Word, susun atur boleh dilaras; tanpa gelembung';

  @override
  String get captureNoteTitle => 'Tajuk nota (pilihan)';

  @override
  String get captureNoteTitleHint => 'Dokumen baharu turut mendapat nama ini';

  @override
  String get imageOcrTitle => 'Kenal pasti teks dalam imej';

  @override
  String get imageOcrNone => 'Tiada teks ditemui dalam imej ini.';

  @override
  String get imageOcrShort => 'Kenal pasti teks';

  @override
  String get imageOcrWorking => 'Mengenal pasti teks…';

  @override
  String get imageOcrSelectHint =>
      'Ketik: perkataan · Tahan dan seret: huruf demi huruf';

  @override
  String get imageOcrInsert => 'Tambah ke nota';

  @override
  String get imageOcrZoomIn => 'Zum masuk';

  @override
  String get imageOcrZoomOut => 'Zum keluar';

  @override
  String get selectImages => 'Pilih imej';

  @override
  String get exportImages => 'Imej';

  @override
  String get exportImagesInfo =>
      'Teks mengalir di sebelah imej sempit yang dijajar kiri atau kanan; imej di tengah mengambil lebar penuh.';

  @override
  String get exportAlignLeft => 'Kiri';

  @override
  String get exportAlignCenter => 'Tengah';

  @override
  String get exportAlignRight => 'Kanan';

  @override
  String get exportImageWidth => 'Lebar';

  @override
  String get exportImageLine => 'Kedudukan';

  @override
  String imageOcrCharsSelected(int count) {
    return '$count aksara dipilih';
  }

  @override
  String imagesSelectedCount(int count) {
    return '$count imej dipilih';
  }

  @override
  String attachmentsCopiedCount(int count) {
    return '$count lampiran';
  }

  @override
  String exportImageLineOf(int count) {
    return '/ $count baris';
  }

  @override
  String get rotateFailed => 'Tidak dapat memutar imej.';

  @override
  String get dashboardBackgroundChange => 'Tukar imej latar';

  @override
  String get appearancePreviewTitle => 'Contoh teks';

  @override
  String get appearancePreviewNoteTitle => 'Contoh tajuk nota';

  @override
  String get appearancePreviewBody =>
      'Nota anda akan kelihatan seperti ini. Teks **tebal**, ~bergaris bawah~ dan ==2:diserlahkan== dipaparkan begini.';

  @override
  String get appearancePreviewItem =>
      'Item senarai semak kelihatan seperti ini';

  @override
  String get convertToText => 'Tukar kepada teks';

  @override
  String get convertToList => 'Tukar kepada senarai';

  @override
  String get convertedToText => 'Senarai ditukar kepada teks biasa.';

  @override
  String get convertedToList => 'Teks ditukar kepada senarai.';

  @override
  String get convertToListEmpty => 'Tiada baris untuk ditukar kepada senarai.';

  @override
  String get listTwoColumns => 'Dua lajur';

  @override
  String get listOneColumn => 'Satu lajur';

  @override
  String get sortItems => 'Isih item';

  @override
  String get sortStarredFirst => 'Berbintang dahulu';

  @override
  String get sortUncheckedFirst => 'Yang selesai terakhir';

  @override
  String get sortAlphabetical => 'A → Z';

  @override
  String get sortAlphabeticalDesc => 'Z → A';

  @override
  String get imagesToAttachments => 'Alih imej ke lampiran';

  @override
  String imagesToAttachmentsDone(int count) {
    return '$count imej dialihkan ke lampiran.';
  }

  @override
  String get imageOcrShowRecognized => 'Serlahkan teks yang dikenal pasti';

  @override
  String get imageOcrHideRecognized => 'Sembunyikan serlahan';

  @override
  String get bubblePlainMode => 'Kotak teks terbuka';

  @override
  String get bubblePlainTapToPlace => 'Ketik tempat teks harus diletakkan';

  @override
  String get bubblePlainHint => 'Ketik untuk menulis';

  @override
  String get noteSearchTitle => 'Cari dalam nota';

  @override
  String get noteSearchHint => 'Cari dalam nota ini…';

  @override
  String get noteSearchEmptyHint =>
      'Mencari teks nota, item dan nota halaman serta-merta. Mulakan imbasan di bawah untuk mencari dalam lampiran imej dan PDF.';

  @override
  String get noteSearchNoHit => 'Tiada padanan ditemui.';

  @override
  String get noteSearchScanAttachments => 'Imbas lampiran';

  @override
  String get noteTitleLabel => 'Tajuk';

  @override
  String get noteBodyLabel => 'Teks nota';

  @override
  String get itemLabel => 'Item';

  @override
  String noteSearchAttachmentsInfo(int count) {
    return '$count lampiran boleh diimbas (imej/PDF).';
  }

  @override
  String noteSearchAttachmentsReady(int count) {
    return 'Turut mencari dalam $count lampiran.';
  }

  @override
  String pageLabel(int page) {
    return 'Halaman $page';
  }

  @override
  String get archiveNotebook => 'Buku nota';

  @override
  String get archiveNewPage => 'Halaman baharu';

  @override
  String get archiveTemplateJournal => 'Jurnal';

  @override
  String get archiveTemplateMeeting => 'Mesyuarat';

  @override
  String get archiveTemplateExpense => 'Perbelanjaan';

  @override
  String get archiveTemplateTodo => 'Tugasan';

  @override
  String get archiveTemplateReading => 'Nota bacaan';

  @override
  String get tplJournalHow => 'Bagaimana hari ini?';

  @override
  String get tplJournalGrateful => 'Bersyukur untuk';

  @override
  String get tplJournalTomorrow => 'Untuk esok';

  @override
  String get tplMeetingAttendees => 'Peserta';

  @override
  String get tplMeetingAgenda => 'Agenda';

  @override
  String get tplMeetingDecisions => 'Keputusan';

  @override
  String get tplMeetingActions => 'Siapa, apa, bila';

  @override
  String get tplExpenseColumns => 'Tarikh · Keterangan · Jumlah';

  @override
  String get tplExpenseTotal => 'Jumlah:';

  @override
  String get tplReadingSource => 'Sumber';

  @override
  String get tplReadingSummary => 'Ringkasan';

  @override
  String get tplReadingQuotes => 'Petikan';

  @override
  String get tplReadingThoughts => 'Fikiran saya';

  @override
  String get archiveDeletePage => 'Padam halaman';

  @override
  String get archivePrevPage => 'Halaman sebelumnya';

  @override
  String get archiveNextPage => 'Halaman seterusnya';

  @override
  String get archiveCopyHere => 'Kumpul ke dalam buku nota';

  @override
  String get archiveNoNotebook => 'Belum ada buku nota. Cipta satu dahulu.';

  @override
  String get archiveNothingToCopy => 'Nota ini tiada lampiran untuk disalin.';

  @override
  String archiveCopied(int count) {
    return '$count fail dikumpul ke dalam buku nota.';
  }

  @override
  String get attachmentTagInserted => 'Tag lampiran disisipkan.';

  @override
  String get attachmentTagPreview => 'Pratonton lampiran';

  @override
  String get attachmentTagEdit => 'Sunting lampiran';

  @override
  String archiveCardSummary(int files, int texts) {
    return '$files fail · $texts teks';
  }

  @override
  String get archivePaper => 'Kertas';

  @override
  String get archivePaperLined => 'Bergaris';

  @override
  String get archivePaperGrid => 'Grid';

  @override
  String get archivePaperDots => 'Bertitik';

  @override
  String get archivePaperPlain => 'Kosong';

  @override
  String get archivePaperLegal => 'Pad legal';

  @override
  String get archivePaperEngineering => 'Kejuruteraan';

  @override
  String get archivePaperIsometric => 'Isometrik';

  @override
  String get attachmentTagEmbed => 'Benamkan dalam teks';

  @override
  String get bubbleModeBubble => 'Gelembung';

  @override
  String get attachmentTagEmbedInfo =>
      'Dipautkan ke teks yang dipilih, atau di kursor jika tiada yang dipilih';

  @override
  String get attachmentTagLinkHere => 'Pautkan di sini';

  @override
  String attachmentTagPendingBanner(String name) {
    return '$name akan dipautkan — pilih teksnya';
  }

  @override
  String get docNameNotesSuffix => 'nota';

  @override
  String get docNamePhoto => 'Nota foto';

  @override
  String get docNameScan => 'Nota imbasan';

  @override
  String get docNameImage => 'Nota imej';

  @override
  String get docNameVideo => 'Nota video';

  @override
  String get folderEmpty => 'Belum ada nota di sini';

  @override
  String folderNoteCount(int count) {
    return '$count nota';
  }

  @override
  String get folderCardEmpty => 'Kosong';

  @override
  String get folderEmptyHint =>
      'Tambah nota melalui + di bawah, atau alih nota ke sini semasa menyuntingnya.';

  @override
  String get folderShared => 'Folder ini dikongsi dengan rakan';

  @override
  String get friendsTitle => 'Kenalan';

  @override
  String get friendsAdd => 'Tambah rakan';

  @override
  String get friendsEmpty =>
      'Tambah rakan melalui e-mel untuk berkongsi folder dengan mereka.';

  @override
  String get friendsRequestsTitle => 'Permintaan';

  @override
  String get friendsListTitle => 'Rakan saya';

  @override
  String get friendsSendRequest => 'Hantar permintaan';

  @override
  String get friendsRequestSent => 'Permintaan dihantar';

  @override
  String get friendsNotFound =>
      'Tiada pengguna berdaftar dengan e-mel ini. Mereka perlu pernah membuka aplikasi dengan akaun Google sekurang-kurangnya sekali.';

  @override
  String get friendsSelf =>
      'Anda tidak boleh menambah diri sendiri sebagai rakan';

  @override
  String get friendsAlready => 'Anda sudah berkawan';

  @override
  String get friendsDecline => 'Tolak';

  @override
  String get friendsAccept => 'Terima';

  @override
  String get friendsRemove => 'Buang';

  @override
  String get friendsRemoveConfirmTitle => 'Buang rakan';

  @override
  String friendsRemoveConfirmBody(Object name) {
    return 'Buang $name daripada rakan anda? Folder yang anda kongsi dengan mereka tidak akan kelihatan lagi.';
  }

  @override
  String get friendsSearchHint => 'Nama (3+ huruf) atau e-mel penuh';

  @override
  String get friendsSearchEmpty => 'Tiada hasil';

  @override
  String get friendsSearchTooShort =>
      'Taip sekurang-kurangnya 3 huruf atau e-mel penuh untuk mencari';

  @override
  String get friendsSearchAdd => 'Tambah';

  @override
  String get folderShare => 'Sunting bersama';

  @override
  String folderShareCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dikongsi dengan $count orang',
      one: 'Dikongsi dengan 1 orang',
    );
    return '$_temp0';
  }

  @override
  String folderShareTitle(Object name) {
    return 'Kongsi \"$name\"';
  }

  @override
  String get folderShareInfo =>
      'Jemputan dihantar kepada rakan yang anda pilih; mereka melihat folder selepas menerimanya. Anda memilih kebenaran mereka (baca / tulis / kedua-duanya).';

  @override
  String get friendsRowInfo => 'Tambah rakan, kongsi folder dengan mereka';

  @override
  String get accountRecoverConflictTitle =>
      'Peranti ini ada nota yang belum disimpan';

  @override
  String accountRecoverConflictBody(Object count) {
    return 'Akaun Google ini sudah dipautkan ke sesi lain; bertukar kepadanya akan menyembunyikan $count nota pada peranti ini (ia tidak dipadam, cuma tidak dapat dicapai dari sini). Teruskan juga?';
  }

  @override
  String get accountRecoverConflictProceed => 'Tukar juga';

  @override
  String get folderRoleRead => 'Baca';

  @override
  String get folderRoleWrite => 'Tulis';

  @override
  String get folderRoleBoth => 'Baca + tulis';

  @override
  String get folderInvitePending => 'Jemputan dihantar, menunggu jawapan';

  @override
  String get folderWriteOnlyTitle => 'Anda hanya ada akses tulis';

  @override
  String get folderWriteOnlyHint =>
      'Anda boleh menambah nota baharu ke folder ini tetapi tidak dapat melihat nota di dalamnya.';

  @override
  String get folderChatTitle => 'Sembang';

  @override
  String get folderChatHint => 'Tulis mesej…';

  @override
  String get folderChatSend => 'Hantar';

  @override
  String get folderChatEmptyTitle => 'Belum ada mesej di sini';

  @override
  String get folderChatEmptyHint =>
      'Bersembang di sini dengan orang yang anda kongsi folder ini.';

  @override
  String get folderInviteTitle => 'Jemputan folder';

  @override
  String folderInviteBody(Object name) {
    return 'Folder \"$name\" telah dikongsi dengan anda.';
  }

  @override
  String get folderInviteAccepted => 'Folder ditambah';

  @override
  String get folderInviteDeclined => 'Jemputan ditolak';

  @override
  String friendRequestBanner(Object name) {
    return '$name menghantar permintaan rakan kepada anda';
  }

  @override
  String get friendRequestAccepted => 'Rakan ditambah';

  @override
  String get sendNoteTitle => 'Hantar nota kepada rakan';

  @override
  String get sendNoteInfo =>
      'Salinan nota masuk ke kotak \"Nota masuk\" orang itu. Lampiran (imej, dokumen, audio) tidak dihantar.';

  @override
  String sendNoteSent(Object name) {
    return 'Nota dihantar kepada $name';
  }

  @override
  String get inboxTitle => 'Nota masuk';

  @override
  String get inboxEmpty => 'Tiada nota masuk di sini';

  @override
  String get inboxEmptyHint =>
      'Nota yang dihantar oleh rakan anda terkumpul di sini.';

  @override
  String inboxFrom(Object name) {
    return 'Dihantar oleh $name';
  }

  @override
  String get inboxAccept => 'Tambah ke nota saya';

  @override
  String get inboxAccepted => 'Nota ditambah ke nota anda';

  @override
  String get folderShelfCollapse => 'Kuncupkan folder';

  @override
  String get accountSheetLocalInfo =>
      'Nota anda hanya ada pada peranti ini. Pautkan akaun Google untuk menyandarkannya dan menambah rakan.';

  @override
  String get accountSettings => 'Tetapan akaun';

  @override
  String get videoFramesExtracting => 'Mengambil bingkai daripada video…';

  @override
  String get areaSelect => 'Pilih kawasan';

  @override
  String get areaSelectOff => 'Matikan pilih kawasan';

  @override
  String get areaSelectHint =>
      'Seret kotak di sekeliling apa yang anda mahu salin atau tanya AI.';

  @override
  String get areaCopyImage => 'Salin sebagai imej';

  @override
  String get areaCopied => 'Kawasan terpilih disalin ke papan keratan.';

  @override
  String get areaAskTitle => 'Kawasan terpilih';

  @override
  String get areaCaptureFailed => 'Tidak dapat menangkap kawasan terpilih.';

  @override
  String get areaTooSmall => 'Kawasan terpilih terlalu kecil.';

  @override
  String get bubbleTextFill => 'Latar teks';

  @override
  String get bubbleTextFillNone => 'Tiada latar';

  @override
  String get bubbleTextAlignLeft => 'Jajar kiri';

  @override
  String get bubbleTextAlignCenter => 'Jajar tengah';

  @override
  String get bubbleTextAlignRight => 'Jajar kanan';

  @override
  String get dashboardBackgroundPattern => 'Corak';

  @override
  String get dashboardBackgroundColor => 'Warna latar';

  @override
  String get dashboardBackgroundReset => 'Set semula ke lalai';

  @override
  String get patternNone => 'Kosong';

  @override
  String get patternDots => 'Titik';

  @override
  String get patternGrid => 'Grid';

  @override
  String get patternLines => 'Garisan';

  @override
  String get patternDiagonal => 'Pepenjuru';

  @override
  String get patternGraph => 'Kertas graf';

  @override
  String get sharedNotifications => 'Pemberitahuan folder dikongsi';

  @override
  String get sharedNotificationsInfo =>
      'Terima pemberitahuan apabila nota dikongsi ditambah, diubah atau dihantar mesej.';

  @override
  String get copyAsText => 'Salin teks';

  @override
  String get searchAttachments => 'Cari dalam lampiran';

  @override
  String get searchAttachmentsInfo =>
      'Turut mencari teks PDF dan teks dalam imej.';

  @override
  String get selectAll => 'Pilih semua';

  @override
  String get selectNone => 'Kosongkan pilihan';

  @override
  String get duplicateNote => 'Pendua nota';

  @override
  String get noteDuplicated => 'Nota diduakan';

  @override
  String notesDuplicatedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nota diduakan',
      one: '1 nota diduakan',
    );
    return '$_temp0';
  }

  @override
  String get noteStatsTitle => 'Statistik nota';

  @override
  String noteStatsWords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count perkataan',
      one: '1 perkataan',
    );
    return '$_temp0';
  }

  @override
  String noteStatsChars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count aksara',
      one: '1 aksara',
    );
    return '$_temp0';
  }

  @override
  String noteStatsItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count item',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String noteStatsAttachments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lampiran',
      one: '1 lampiran',
    );
    return '$_temp0';
  }

  @override
  String noteStatsReadTime(int count) {
    return '~$count minit bacaan';
  }

  @override
  String get scrollToTop => 'Kembali ke atas';

  @override
  String searchResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hasil',
      one: '1 hasil',
    );
    return '$_temp0';
  }

  @override
  String get clearSearch => 'Kosongkan carian';

  @override
  String trashDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dipadam secara kekal dalam $count hari',
      one: 'Dipadam secara kekal dalam 1 hari',
    );
    return '$_temp0';
  }

  @override
  String get trashLastDay => 'Akan dipadam secara kekal hari ini';

  @override
  String get noteRestored => 'Nota dipulihkan';

  @override
  String get restoreAll => 'Pulihkan semua';

  @override
  String notesRestoredCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nota dipulihkan',
      one: '1 nota dipulihkan',
    );
    return '$_temp0';
  }

  @override
  String get reminderRemoved => 'Peringatan dibuang';

  @override
  String get reminderOverdue => 'Tertunggak';

  @override
  String get reminderQuickTonight => 'Malam ini 6:00 PTG';

  @override
  String get reminderQuickTomorrow => 'Esok 9:00 PG';

  @override
  String get reminderQuickNextWeek => 'Minggu depan';

  @override
  String get reminderSnooze => 'Tunda 1 jam';

  @override
  String get reminderSnoozed => 'Peringatan ditunda';

  @override
  String reminderCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count peringatan',
      one: '1 peringatan',
    );
    return '$_temp0';
  }

  @override
  String get relativeJustNow => 'baru sahaja';

  @override
  String relativeInMinutes(int count) {
    return 'dalam $count min';
  }

  @override
  String relativeInHours(int count) {
    return 'dalam $count jam';
  }

  @override
  String relativeInDays(int count) {
    return 'dalam $count hari';
  }

  @override
  String relativeAgoMinutes(int count) {
    return '$count min lalu';
  }

  @override
  String relativeAgoHours(int count) {
    return '$count jam lalu';
  }

  @override
  String relativeAgoDays(int count) {
    return '$count hari lalu';
  }

  @override
  String get inboxDeclined => 'Nota masuk dipadam';

  @override
  String inboxCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nota masuk',
      one: '1 nota masuk',
    );
    return '$_temp0';
  }

  @override
  String get appVersion => 'Versi aplikasi';

  @override
  String get appVersionCopied => 'Maklumat versi disalin';

  @override
  String notesMovedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nota dialihkan',
      one: '1 nota dialihkan',
    );
    return '$_temp0';
  }

  @override
  String get mediaPlay => 'Main';

  @override
  String get mediaPause => 'Jeda';

  @override
  String get decrease => 'Kurangkan';

  @override
  String get increase => 'Tambah';

  @override
  String get tagManageTitle => 'Urus tag';

  @override
  String get tagRename => 'Namakan semula tag';

  @override
  String get tagRenameHint => 'Nama tag baharu';

  @override
  String get tagDelete => 'Padam tag';

  @override
  String tagDeleteConfirm(String tag) {
    return 'Buang tag \"$tag\" daripada semua nota? Nota-nota itu kekal.';
  }

  @override
  String get tagRenamed => 'Tag dinamakan semula';

  @override
  String get tagDeleted => 'Tag dibuang';

  @override
  String get tagLongPressHint =>
      'Tekan lama tag untuk menamakan semula atau memadamnya.';

  @override
  String get recentSearches => 'Carian terkini';

  @override
  String get clearRecentSearches => 'Kosongkan sejarah';

  @override
  String get imagesEqualizeSize => 'Samakan saiz';

  @override
  String get imagesFitRow => 'Muatkan ke baris';

  @override
  String imagesFitColumns(int count) {
    return '$count lajur';
  }

  @override
  String get imagesFitSingleRow => 'Muat dalam satu baris';

  @override
  String get reminderDone => 'Selesai';

  @override
  String get dateToday => 'Hari ini';

  @override
  String get dateTomorrow => 'Esok';

  @override
  String get noteDuplicatedNoAttachments => 'Diduakan — lampiran tidak dibawa';

  @override
  String get pdfGoToPage => 'Pergi ke halaman';

  @override
  String get pdfThumbnails => 'Layari halaman';

  @override
  String get pdfBookmarks => 'Penanda halaman';

  @override
  String get pdfBookmarkAdd => 'Tambah penanda halaman';

  @override
  String get pdfBookmarkRemove => 'Buang penanda halaman';

  @override
  String get pdfNoBookmarks =>
      'Belum ada penanda halaman. Ketik butang penanda pada bar halaman.';

  @override
  String get pdfRotateView => 'Putar paparan';

  @override
  String get pdfCopyPageText => 'Salin teks halaman';

  @override
  String get pdfCapturePage => 'Tangkap halaman (AI / salin)';

  @override
  String get pdfSlideshow => 'Maju automatik';

  @override
  String get pdfSlideshowStop => 'Hentikan maju automatik';

  @override
  String get pdfFirstPage => 'Halaman pertama';

  @override
  String get pdfLastPage => 'Halaman terakhir';

  @override
  String get collaborators => 'Rakan kerjasama';

  @override
  String get collaboratorsInfo =>
      'Orang yang anda tambah melihat nota ini di laman utama mereka dan menyuntingnya bersama anda secara langsung.';

  @override
  String get collaboratorsOwner => 'Pemilik';

  @override
  String get collaboratorsFriendsTitle => 'Rakan anda';

  @override
  String get collaboratorsLeave => 'Tinggalkan nota dikongsi';

  @override
  String get collaboratorsLeaveConfirm =>
      'Nota ini tidak akan muncul lagi di laman utama anda. Tinggalkan?';

  @override
  String get collaboratorsSaved => 'Perkongsian dikemas kini';

  @override
  String get collaboratorsOnlyOwner =>
      'Hanya pemilik nota boleh menukar rakan kerjasama.';

  @override
  String sharedByName(Object name) {
    return 'Dikongsi oleh $name';
  }

  @override
  String get navNotes => 'Nota';

  @override
  String get railExpand => 'Kembangkan menu';

  @override
  String get railCollapse => 'Kuncupkan menu';

  @override
  String get newNoteShort => 'Nota baharu';

  @override
  String get listPaneHide => 'Sembunyikan senarai nota';

  @override
  String get listPaneShow => 'Tunjukkan senarai nota';

  @override
  String get keyboardShortcuts => 'Pintasan papan kekunci';

  @override
  String get shortcutSearch => 'Cari nota';

  @override
  String get shortcutToggleList => 'Sembunyikan / tunjukkan senarai nota';

  @override
  String get shortcutSections => 'Bertukar antara bahagian';

  @override
  String get shortcutHelp => 'Tunjukkan pintasan';

  @override
  String get shortcutFullscreen => 'Togol skrin penuh nota';

  @override
  String get shortcutEscape => 'Keluar dari skrin penuh, kemudian tutup nota';

  @override
  String get showNoteList => 'Tunjukkan senarai nota';

  @override
  String get shortcutSwitchFolder => 'Tukar folder';

  @override
  String get shortcutMouseWheel => 'roda';

  @override
  String get shortcutGridColumns => 'Bilangan lajur';

  @override
  String get shortcutSelectAll => 'Semasa memilih: pilih semua';

  @override
  String get shortcutDeleteSelected => 'Alih yang dipilih ke tong sampah';

  @override
  String get sharedFolderNoFileDrop =>
      'Fail tidak boleh dilepaskan ke folder dikongsi. Buka nota dan lepaskan fail di sana.';

  @override
  String get shortcutAdjacentNote =>
      'Nota sebelumnya / seterusnya dalam senarai';

  @override
  String get shortcutCloseNote => 'Tutup nota';

  @override
  String get softKeyboardShow =>
      'Tunjukkan papan kekunci skrin (papan kekunci fizikal disambung)';

  @override
  String get softKeyboardHide => 'Sembunyikan papan kekunci skrin';

  @override
  String get goHome => 'Kembali ke laman utama';

  @override
  String get loginFeatureSyncTitle => 'Nota yang sama pada setiap peranti';

  @override
  String get loginFeatureSyncBody =>
      'Penyegerakan segera merentasi telefon, tablet, komputer dan web.';

  @override
  String get loginFeatureAiTitle => 'Penyusunan pintar';

  @override
  String get loginFeatureAiBody =>
      'Imlak suara pantas, semakan ejaan luar talian, lorong runcit pintar dan tag.';

  @override
  String get loginFeatureShareTitle => 'Menulis bersama';

  @override
  String get loginFeatureShareBody =>
      'Kongsi nota dan folder secara langsung dengan rakan.';

  @override
  String get loginFeatureInkTitle => 'Pen dan PDF';

  @override
  String get loginFeatureInkBody =>
      'Ambil nota tulisan tangan, tulis pada PDF dan slaid.';

  @override
  String get foldersTitle => 'Folder';

  @override
  String get foldersEmpty =>
      'Belum ada folder. Cipta satu untuk menyusun nota anda.';

  @override
  String get foldersEmptyTitle => 'Belum ada folder di sini';

  @override
  String get foldersEmptyHint => 'Cipta satu untuk menyusun nota anda.';

  @override
  String get folderColor => 'Warna';

  @override
  String get folderColorAuto => 'Automatik';

  @override
  String get foldersMine => 'Folder saya';

  @override
  String get foldersSharedSection => 'Folder dikongsi';

  @override
  String trashDaysShort(int count) {
    return '$count h';
  }

  @override
  String get trashTodayShort => 'Hari ini';

  @override
  String get trashSoonSection => 'Akan dipadam secara kekal tidak lama lagi';

  @override
  String get trashRestSection => 'Nota dipadam yang lain';

  @override
  String get folderOrderTitle => 'Susunan folder';

  @override
  String get folderReorder => 'Susun semula folder';

  @override
  String get folderOrderManual => 'Tersuai';

  @override
  String get folderOrderName => 'Mengikut nama';

  @override
  String get folderOrderNewest => 'Terbaharu dahulu';

  @override
  String get folderOrderNoteCount => 'Mengikut bilangan nota';

  @override
  String get folderOrderHint =>
      'Seret pemegang untuk menyusun semula (menyeret bertukar ke \"Manual\"). Susunan ini juga digunakan dalam jalur folder dan semasa leret.';

  @override
  String get swipeModeTitle => 'Leret kiri/kanan di laman utama';

  @override
  String get swipeModeFolders => 'Bertukar antara folder';

  @override
  String get swipeModeFilters => 'Bertukar antara penapis dan tag';

  @override
  String get swipeModeBoth => 'Folder, penapis dan tag';

  @override
  String get swipeModeOff => 'Mati';

  @override
  String get shareIncludeTitle => 'Tajuk';

  @override
  String get shareIncludeChecked => 'Item selesai';

  @override
  String get shareIncludeTags => 'Tag';

  @override
  String get shareTextAction => 'Kongsi teks';

  @override
  String get findPrevious => 'Padanan sebelumnya';

  @override
  String get findNext => 'Padanan seterusnya';

  @override
  String get findShowAll => 'Semua padanan';

  @override
  String findMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count padanan',
      one: '1 padanan',
      zero: 'Tiada padanan',
    );
    return '$_temp0';
  }

  @override
  String get findDeepSearch => 'Cari lampiran & AI';

  @override
  String get notesSettingsTitle => 'Nota & folder';

  @override
  String get noteViewSetting => 'Susun atur laman utama';

  @override
  String get noteViewGrid => 'Grid';

  @override
  String get noteViewList => 'Senarai';

  @override
  String get gridColumnsSetting => 'Lajur';

  @override
  String get gridColumnsInfo =>
      'Anda juga boleh mencubit di laman utama untuk mengubahnya.';

  @override
  String get gridColumnsAuto => 'Automatik';

  @override
  String get folderShelfSetting => 'Folder di laman utama';

  @override
  String get folderShelfStrip => 'Satu baris';

  @override
  String get folderShelfTiles => 'Jubin';

  @override
  String get deviceStorageTitle => 'Pada peranti ini';

  @override
  String get deviceStorageAttachments => 'Lampiran';

  @override
  String get deviceStorageDatabase => 'Salinan setempat nota';

  @override
  String get deviceStorageCache => 'Cache dan fail sementara';

  @override
  String get deviceStorageAi => 'Cache AI';

  @override
  String get deviceStorageTotal =>
      'Jumlah (tidak termasuk aplikasi itu sendiri)';

  @override
  String get deviceStorageInfo =>
      'Mengosongkan cache tidak memadam nota atau lampiran.';

  @override
  String get deviceStorageClear => 'Kosongkan cache';

  @override
  String deviceStorageCleared(String size) {
    return '$size dibebaskan';
  }

  @override
  String get deviceStorageUnavailable => 'Tidak dapat diukur pada peranti ini.';

  @override
  String get localOnlyTurnOn => 'Hentikan penyegerakan';

  @override
  String get localOnlyTurnOff => 'Segerakkan nota ini';

  @override
  String get localOnlyBadge => 'Pada peranti ini sahaja';

  @override
  String get localOnlyConfirmTitle =>
      'Simpan nota ini pada peranti ini sahaja?';

  @override
  String get localOnlyConfirmBody =>
      'Nota dan lampirannya dibuang dari awan dan tidak akan muncul pada peranti anda yang lain. Jika anda menyahpasang aplikasi atau menukar telefon, nota ini turut hilang. Anda boleh menghidupkan penyegerakan semula bila-bila masa.';

  @override
  String get localOnlyConfirm => 'Hentikan penyegerakan';

  @override
  String get localOnlyOnDone => 'Nota kini pada peranti ini sahaja';

  @override
  String get localOnlyOffDone => 'Nota disegerakkan semula';

  @override
  String get localOnlySharedBlocked =>
      'Penyegerakan tidak boleh dimatikan untuk nota dikongsi';

  @override
  String get localOnlyDownloadFailed =>
      'Sesetengah lampiran tidak dapat dimuat turun ke peranti ini. Semak sambungan dan cuba lagi; nota tidak diubah.';

  @override
  String get templatesTitle => 'Templat';

  @override
  String get templatesSubtitle =>
      'Mulakan dengan susun atur sedia; anda boleh mengubah semuanya kemudian.';

  @override
  String get fromTemplate => 'Templat sedia ada';

  @override
  String get tplShoppingName => 'Senarai beli-belah';

  @override
  String get tplShoppingItems => 'Roti, Susu, Telur, Buah, Sayur';

  @override
  String get tplShoppingDesc => 'Tanda apa yang dibeli; ia akan turun ke bawah';

  @override
  String get tplTodoDesc => 'Senarai kosong dengan tarikh hari ini';

  @override
  String get tplTravelName => 'Senarai barang bawaan';

  @override
  String get tplTravelItems =>
      'Kad pengenalan / pasport, Pengecas telefon, Ubat-ubatan, Berus gigi, Pakaian, Fon kepala';

  @override
  String get tplTravelDesc => 'Senarai semak sedia';

  @override
  String get tplMeetingDesc => 'Peserta, agenda, keputusan';

  @override
  String get tplJournalDesc => 'Bagaimana hari ini, kesyukuran, esok';

  @override
  String get tplRecipeName => 'Resipi';

  @override
  String get tplRecipeMeta => 'Hidangan: · Masa:';

  @override
  String get tplRecipeIngredients => 'Bahan-bahan';

  @override
  String get tplRecipeSteps => 'Langkah';

  @override
  String get tplRecipeNotes => 'Nota';

  @override
  String get tplRecipeDesc => 'Bahan dan langkah';

  @override
  String get tplWeeklyName => 'Pelan mingguan';

  @override
  String get tplWeeklyDesc => 'Hari-hari minggu ini sebagai tajuk';

  @override
  String get tplExpenseDesc => 'Tarikh, keterangan, jumlah';

  @override
  String get tplReadingDesc => 'Sumber, ringkasan, petikan';

  @override
  String get settingsThemeHeader => 'Tema';

  @override
  String get settingsGroupPrivacyNotify => 'Privasi dan pemberitahuan';

  @override
  String get settingsGroupText => 'Teks';

  @override
  String get settingsGroupDictation => 'Menaip dengan suara';

  @override
  String get settingsGroupGestures => 'Gerak isyarat';

  @override
  String get settingsGroupSortView => 'Isihan dan susun atur';

  @override
  String get settingsGroupShared => 'Nota dikongsi';

  @override
  String get settingsGroupAttachments => 'Lampiran';

  @override
  String get settingsGroupBackup => 'Sandaran';

  @override
  String get settingsGroupSession => 'Sesi';

  @override
  String get settingsSecurityTitle => 'Keselamatan';

  @override
  String get settingsSecuritySummary => 'Kunci nota, kunci aplikasi';

  @override
  String get settingsGroupAbout => 'Perihal';

  @override
  String get settingsGroupVersion => 'Versi';

  @override
  String get settingsCardsHeader => 'Kad dan senarai';

  @override
  String get shareTargetTitle => 'Tambah ke Nota';

  @override
  String get shareTargetNew => 'Nota baharu';

  @override
  String get shareTargetExisting => 'Nota sedia ada';

  @override
  String get shareTargetCreate => 'Cipta nota';

  @override
  String get shareTargetSearch => 'Cari nota';

  @override
  String get shareTargetNoNotes => 'Tiada nota untuk ditambah';

  @override
  String get shareTargetNoMatch => 'Tiada nota yang sepadan';

  @override
  String shareTargetMore(int count) {
    return '+$count fail';
  }

  @override
  String get sharePreviewExpand => 'Kembangkan pratonton';

  @override
  String get sharePreviewCollapse => 'Kuncupkan pratonton';

  @override
  String get templatesSearch => 'Cari templat';

  @override
  String get templatesAll => 'Semua';

  @override
  String get templatesLists => 'Senarai';

  @override
  String get templatesPlanning => 'Perancangan';

  @override
  String get templatesWriting => 'Penulisan';

  @override
  String get templatesMine => 'Templat saya';

  @override
  String get templatesRecent => 'Baru digunakan';

  @override
  String get templatesNoMatch => 'Tiada templat yang sepadan';

  @override
  String get templatesMineEmpty =>
      'Anda belum ada templat. Pilih “Simpan sebagai templat” daripada menu nota dan ia akan muncul di sini.';

  @override
  String get templatesMineInfo => 'Templat anda';

  @override
  String get templateRename => 'Namakan semula';

  @override
  String get templateDelete => 'Padam templat';

  @override
  String get templateNameTitle => 'Nama templat';

  @override
  String get templateNameHint => 'cth. Barang dapur mingguan';

  @override
  String get templateSave => 'Simpan';

  @override
  String templateSaved(String name) {
    return '“$name” ditambah ke templat anda';
  }

  @override
  String get saveAsTemplate => 'Simpan sebagai templat';

  @override
  String get templateCreate => 'Cipta';

  @override
  String get templateListChecks => 'Kotak semak';

  @override
  String get templateListNumbers => 'Bernombor';

  @override
  String get templateAddItem => 'Tambah item';

  @override
  String get tplShopProduce => 'Buah dan sayur';

  @override
  String get tplShopProduceItems =>
      'Tomato, Timun, Bawang, Kentang, Lemon, Pisang, Epal, Pasli';

  @override
  String get tplShopBreakfast => 'Sarapan';

  @override
  String get tplShopBreakfastItems =>
      'Keju, Zaitun, Mentega, Madu, Jem, Yogurt';

  @override
  String get tplShopPantry => 'Barang dapur';

  @override
  String get tplShopPantryItems =>
      'Beras, Pasta, Tepung, Gula, Minyak zaitun, Kacang dal, Teh, Kopi';

  @override
  String get tplShopCleaning => 'Pembersihan';

  @override
  String get tplShopCleaningItems =>
      'Sabun pinggan, Detergen, Tisu tandas, Tuala kertas, Beg sampah';

  @override
  String get tplShopPersonal => 'Penjagaan diri';

  @override
  String get tplShopPersonalItems => 'Syampu, Ubat gigi, Sabun, Deodoran';

  @override
  String get tplTravelDocs => 'Dokumen';

  @override
  String get tplTravelDocsItems =>
      'Tiket, Tempahan hotel, Lesen memandu, Insurans perjalanan, Tunai / kad';

  @override
  String get tplTravelClothes => 'Pakaian';

  @override
  String get tplTravelClothesItems =>
      'Baju-T, Seluar, Pakaian dalam, Stoking, Pijama, Jaket, Kasut';

  @override
  String get tplTravelCare => 'Kelengkapan mandi';

  @override
  String get tplTravelCareItems =>
      'Ubat gigi, Syampu, Pelindung matahari, Alat cukur, Deodoran';

  @override
  String get tplTravelTech => 'Elektronik';

  @override
  String get tplTravelTechItems =>
      'Power bank, Penyesuai palam, Fon kepala, Kabel';

  @override
  String get tplHabitsName => 'Penjejak tabiat';

  @override
  String get tplHabitsDesc => 'Tanda setiap hari, jangan putuskan rantai';

  @override
  String get tplHabitsItems =>
      '8 gelas air, Berjalan 30 minit, Baca 20 halaman, Tidur awal, Satu jam tanpa skrin';

  @override
  String get tplCleaningName => 'Pembersihan rumah';

  @override
  String get tplCleaningDesc => 'Senarai semak pembersihan mingguan';

  @override
  String get tplCleaningItems =>
      'Buang habuk, Vakum, Mop, Bersihkan bilik air, Kaunter dapur, Basuh pakaian, Buang sampah, Tukar cadar';

  @override
  String get tplMovingName => 'Senarai semak berpindah';

  @override
  String get tplMovingDesc => 'Perkara sebelum dan selepas berpindah';

  @override
  String get tplMovingItems =>
      'Tempah syarikat pindah, Beli kotak dan pita, Kemas kini alamat, Akaun elektrik / air / gas, Pindahkan internet, Serahkan kunci';

  @override
  String get tplGiftsName => 'Senarai hadiah';

  @override
  String get tplGiftsDesc => 'Siapa dapat apa, idea';

  @override
  String get tplGiftsItems => 'Ibu, Ayah, Adik-beradik, Rakan';

  @override
  String get tplWatchlistName => 'Senarai tontonan';

  @override
  String get tplWatchlistDesc => 'Filem, siri dan buku untuk dinikmati';

  @override
  String get tplWorkoutName => 'Senaman';

  @override
  String get tplWorkoutDesc =>
      'Senarai senaman dari memanaskan badan hingga regangan';

  @override
  String get tplWorkoutItems =>
      'Memanaskan badan 5 min, Cangkung 3×12, Tekan tubi 3×10, Ringkuk tubi 3×15, Plank 3×45 s, Regangan 5 min';

  @override
  String get tplGoalsName => 'Matlamat';

  @override
  String get tplGoalsDesc => 'Matlamat tahun, bulan dan minggu';

  @override
  String get tplGoalsYear => 'Tahun ini';

  @override
  String get tplGoalsMonth => 'Bulan ini';

  @override
  String get tplGoalsWeek => 'Minggu ini';

  @override
  String get tplGoalsWhy => 'Mengapa ia penting?';

  @override
  String get templateNew => 'Templat baharu';

  @override
  String get templateEdit => 'Sunting templat';

  @override
  String get templateDuplicate => 'Pendua';

  @override
  String get templateSaveAsMine => 'Simpan ke templat saya';

  @override
  String get templateUntitled => 'Templat tanpa tajuk';

  @override
  String get templateTypeText => 'Teks';

  @override
  String get templateTitleHelp =>
      'Tajuk nota yang dicipta daripada templat ini (pilihan)';

  @override
  String get templateBody => 'Teks';

  @override
  String get templateHeadingHelp =>
      'Baris yang bermula dengan “# ” menjadi tajuk, “## ” subtajuk.';

  @override
  String get templateDiscardTitle => 'Buang perubahan?';

  @override
  String get templateDiscard => 'Buang';

  @override
  String templateDeleted(String name) {
    return '“$name” dipadam';
  }

  @override
  String get addVideoFromGallery => 'Video daripada galeri';

  @override
  String get addYouTubeVideo => 'Video YouTube';

  @override
  String get addYouTubeVideoSubtitle =>
      'Dimainkan dalam nota, tonton dalam tetingkap kecil';

  @override
  String get youTubeLinkHelp =>
      'Tampal pautan video YouTube (youtube.com atau youtu.be).';

  @override
  String get youTubeInvalidLink => 'Ini bukan pautan video YouTube';

  @override
  String get youTubeOpenInBrowserInfo =>
      'Video tidak boleh dimainkan dalam aplikasi pada peranti ini; ia boleh dibuka dalam pelayar.';

  @override
  String get youTubeOpenExternal => 'Buka dalam YouTube';

  @override
  String get pictureInPicture => 'Gambar dalam gambar';

  @override
  String get pinMediaRelease => 'Lepaskan: semat di atas (nota di bawah)';

  @override
  String get unpinMediaRelease => 'Lepaskan: Terapung';

  @override
  String get pinnedMediaResize =>
      'Tinggi anak tetingkap — seret untuk mengubah';

  @override
  String pageOf(int current, int total) {
    return 'Halaman $current / $total';
  }

  @override
  String pageAdded(int page) {
    return 'Halaman $page ditambah';
  }

  @override
  String get deletePageConfirm =>
      'Padam teks halaman ini? Imejnya beralih ke halaman bersebelahan. Anda boleh mengembalikannya dengan Buat asal.';

  @override
  String get embedNewPdf => 'PDF';

  @override
  String get embedNewImage => 'Imej';

  @override
  String get embedNewVideo => 'Video';

  @override
  String get embedNewYouTube => 'YouTube';

  @override
  String get embedPickTitle => 'Apa yang hendak dibenamkan?';

  @override
  String get embedPickInfo =>
      'Ketik teks untuk membuka item terbenam di tempatnya.';

  @override
  String get embedSectionNew => 'Tambah baharu';

  @override
  String get embedSectionExisting => 'Lampiran dalam nota ini';

  @override
  String get embedSectionLink => 'Pautan';

  @override
  String get embedLinkHint => 'Alamat web (cth. contoh.com)';

  @override
  String get embedLinkApply => 'Pautkan';

  @override
  String get embedReplace => 'Ganti';

  @override
  String get embedRemove => 'Buang benaman';

  @override
  String get embedRemoved => 'Benaman dibuang';

  @override
  String get guideTitle => 'Panduan pengguna';

  @override
  String get guideMenuInfo => 'Setiap ciri, langkah demi langkah';

  @override
  String get guideSearchHint => 'Cari panduan — “halaman”, “YouTube”';

  @override
  String get guideOpenScreen => 'Tunjukkan';

  @override
  String guideNoResults(String query) {
    return 'Tiada hasil untuk “$query”';
  }

  @override
  String get copyVideoLink => 'Salin pautan';

  @override
  String get videoLinkCopied => 'Pautan disalin';

  @override
  String get menuSectionOrganize => 'Susun';

  @override
  String get menuSectionCopy => 'Salin';

  @override
  String get menuSectionTools => 'Alatan';

  @override
  String get menuSectionProtect => 'Perlindungan dan storan';

  @override
  String get menuSectionApp => 'Aplikasi';

  @override
  String cardMoreFiles(int count) {
    return '+$count fail lagi';
  }

  @override
  String cardAudioCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rakaman suara',
      one: 'Rakaman suara',
    );
    return '$_temp0';
  }

  @override
  String get cardBubbleDocument => 'PDF DENGAN GELEMBUNG';

  @override
  String get cardBubbleSlides => 'SLAID DENGAN GELEMBUNG';

  @override
  String get cardKindPdf => 'PDF';

  @override
  String get cardKindSlides => 'SLAID';

  @override
  String cardBubbleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gelembung',
      one: '1 gelembung',
    );
    return '$_temp0';
  }

  @override
  String get quickAddYouTube => 'Video YouTube';

  @override
  String get docViewToBubbles => 'Tukar ke paparan gelembung';

  @override
  String get docViewToClassic => 'Tukar ke paparan klasik';

  @override
  String get docViewSwitchedBubbles =>
      'Paparan gelembung: dokumen di atas, nota halaman di bawah. Susun atur klasik anda disimpan.';

  @override
  String get docViewSwitchedClassic =>
      'Paparan klasik: dokumen ialah lampiran pada halaman. Gelembung dan nota halaman disimpan.';

  @override
  String get docViewTextKept => 'Teks nota kekal dalam paparan klasik.';

  @override
  String get captureModeChangeLater =>
      'Anda boleh bertukar kemudian dengan cip Gelembung / Klasik dalam nota.';

  @override
  String get attachmentSyncTitle => 'Penyegerakan lampiran';

  @override
  String get driveSectionTitle => 'Lampiran dalam Google Drive anda';

  @override
  String get driveConnectTitle => 'Simpan lampiran dalam Google Drive anda';

  @override
  String get driveConnectInfo =>
      'Imej, PDF, slaid dan rakaman suara disimpan dalam storan Drive anda sendiri, dalam folder “Notlar”, dan dimuat turun ke peranti anda yang lain. Video kekal pada peranti.';

  @override
  String get driveConnect => 'Sambung';

  @override
  String get driveDisconnect => 'Putuskan';

  @override
  String get driveConnected =>
      'Google Drive disambungkan — lampiran sedang disandarkan.';

  @override
  String get driveConnectedInfo =>
      'Disambungkan · lampiran berada dalam folder “Notlar” di Drive anda';

  @override
  String driveUsage(String used, String limit) {
    return 'Drive: $used daripada $limit digunakan';
  }

  @override
  String driveConnectFailed(String error) {
    return 'Tidak dapat menyambung Google Drive. $error';
  }

  @override
  String get driveApiDisabled =>
      'Drive API dilumpuhkan dalam projek Google Cloud: dayakan \"Google Drive API\" dalam konsol dan cuba lagi.';

  @override
  String get driveDisconnected =>
      'Drive diputuskan. Lampiran baharu menunggu pada peranti sehingga anda menyambung semula.';

  @override
  String get textOnlyTitle => 'Segerak teks sahaja';

  @override
  String get textOnlyInfo =>
      'Akaun tetamu hanya menyegerakkan teks; lampiran kekal pada peranti ini. Pautkan akaun Google untuk menyimpan lampiran dalam Google Drive anda.';

  @override
  String get storageModeInfo =>
      'Di web, lampiran dimuat naik ke awan aplikasi.';

  @override
  String driveWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lampiran menunggu Google Drive — ketik untuk menyambung',
      one: '1 lampiran menunggu Google Drive — ketik untuk menyambung',
    );
    return '$_temp0';
  }

  @override
  String get driveDownloading => 'Memuat turun lampiran daripada Google Drive…';

  @override
  String get driveNeededForFile =>
      'Lampiran ini berada dalam Google Drive anda. Sambungkan Drive dalam Tetapan → Segerak untuk melihatnya.';

  @override
  String get bubbleDone => 'Selesai';

  @override
  String get bubbleEditShort => 'Sunting';

  @override
  String get bubblePlainModeShort => 'Teks';

  @override
  String get pageBarMore => 'Pilihan halaman dan nota';

  @override
  String viewModeChanged(String from, String to) {
    return '$from → $to';
  }

  @override
  String get videoRotate => 'Putar gambar';

  @override
  String get viewModeTitle => 'Paparan';

  @override
  String get viewModeEmbed => 'Benamkan dalam teks';

  @override
  String get viewModeEmbedHint =>
      'Benamkan lampiran ini dalam satu perkataan nota — mengetik perkataan itu membukanya';

  @override
  String get viewModePinned => 'Disemat';

  @override
  String get viewModeFloating => 'Terapung';

  @override
  String get viewModeBubbles => 'Gelembung';

  @override
  String get viewModePinnedHint =>
      'Semat di atas — kekal di atas, nota menatal di bawah';

  @override
  String get viewModeFloatingHint =>
      'Terapung pada halaman — teks mengalir di sekelilingnya';

  @override
  String get viewModeBubblesHint =>
      'Paparan gelembung — gelembung, serlahan dan pen pada halaman';

  @override
  String get videoNoteAtTime => 'Nota pada saat ini';

  @override
  String get videoNoteAtTimeShort => 'Nota';

  @override
  String get videoTimeUnknown =>
      'Tidak dapat membaca masa video — mainkan video dahulu.';

  @override
  String get videoSpeed => 'Kelajuan main';

  @override
  String get videoLoop => 'Ulang';

  @override
  String get bubbleSmaller => 'Gelembung lebih kecil';

  @override
  String get bubbleLarger => 'Gelembung lebih besar';

  @override
  String get bubbleAllSmaller => 'Kecilkan semua gelembung';

  @override
  String get bubbleAllLarger => 'Besarkan semua gelembung';

  @override
  String get bubblesShow => 'Tunjukkan gelembung';

  @override
  String get bubblesHide => 'Sembunyikan gelembung';

  @override
  String get shareIncludeVideoLinks => 'Pautan video';

  @override
  String get shareQuickPdf => 'PDF';

  @override
  String get shareAsImage => 'Imej';

  @override
  String shareAttachmentFiles(int count) {
    return 'Fail ($count)';
  }

  @override
  String get shareToFriendShort => 'Hantar kepada rakan';

  @override
  String get shareCollaborateShort => 'Sunting bersama';

  @override
  String get shareAsNoteShort => 'Pakej nota';

  @override
  String get shareQuickPreparing => 'Menyediakan…';

  @override
  String get shareAttachmentFilesNone =>
      'Tiada fail lampiran pada peranti ini untuk dikongsi.';

  @override
  String get attachmentRemoved => 'Lampiran dibuang';

  @override
  String get customizeHideItem => 'Sembunyikan';

  @override
  String get customizeShowItem => 'Tunjukkan';

  @override
  String get customizeModeTitle => 'Mod sunting';

  @override
  String get customizeModeTitleShort => 'Sunting';

  @override
  String customizeHiddenCount(int count) {
    return '$count tersembunyi · ketik untuk mengubah';
  }

  @override
  String get customizeDone => 'Selesai';

  @override
  String videoBackSeconds(int seconds) {
    return 'Undur $seconds s';
  }

  @override
  String videoForwardSeconds(int seconds) {
    return 'Maju $seconds s';
  }

  @override
  String get personalizeTitle => 'Susun atur antara muka';

  @override
  String get personalizeInfo =>
      'Pilih kawasan dan butang yang kelihatan, pemalam';

  @override
  String get customizeStartTitle => 'Sunting pada skrin';

  @override
  String get customizeStartInfo =>
      'Ketik butang dan kawasan untuk menyembunyikan atau menunjukkannya; ketik Selesai apabila siap.';

  @override
  String get customizeStart => 'Mula mod sunting';

  @override
  String get customizeActive => 'Mod sunting aktif';

  @override
  String get customizeHint => 'Ketik: sembunyi/tunjuk · Susun semula: alihkan';

  @override
  String get customizeShown => 'Ditunjukkan';

  @override
  String get customizeSurfaceBottomBar => 'Bar bawah';

  @override
  String get customizeSurfaceTopBar => 'Bar atas';

  @override
  String get customizeSurfaceQuickRow => 'Baris pantas';

  @override
  String get customizeSurfaceAddPanel => 'Panel \"+\"';

  @override
  String get customizeSurfacePinned => 'Lampiran disemat';

  @override
  String get customizeSurfacePen => 'Pen';

  @override
  String get personalizeModules => 'Pemalam';

  @override
  String get moduleAi => 'AI';

  @override
  String get moduleAiInfo => 'Butang AI di laman utama dan skrin nota';

  @override
  String get moduleVoice => 'Suara';

  @override
  String get moduleVoiceInfo => 'Nota suara AI, imlak, rakaman audio';

  @override
  String get moduleVideo => 'Video';

  @override
  String get moduleVideoInfo => 'Rakaman, video galeri, YouTube';

  @override
  String get moduleDocuments => 'Dokumen';

  @override
  String get moduleScan => 'Pengimbasan';

  @override
  String get moduleScanInfo => 'Imbasan dokumen dan kod QR';

  @override
  String get moduleDrawing => 'Melukis';

  @override
  String get moduleDrawingInfo => 'Tulisan tangan dan lukisan';

  @override
  String get moduleTemplates => 'Templat';

  @override
  String get moduleTemplatesInfo =>
      'Nota daripada templat, senarai beli-belah, buku nota';

  @override
  String get moduleTags => 'Cip nota';

  @override
  String get moduleTagsInfo => 'Cip tag, folder dan peringatan di bawah tajuk';

  @override
  String get moduleCollaboration => 'Kerjasama';

  @override
  String get moduleCollaborationInfo => 'Butang tambah orang dalam skrin nota';

  @override
  String get moduleMixed => 'sebahagian aktif';

  @override
  String get personalizeBarLeft => 'Kapsul kiri · alatan';

  @override
  String get personalizeBarRight => 'Kapsul kanan · AI dan suara';

  @override
  String get personalizeBarReset => 'Set semula bar bawah';

  @override
  String get personalizeBarTop => 'Bar atas · susunan butang';

  @override
  String get personalizeBarMoveRight => 'Alih ke kapsul kanan';

  @override
  String get personalizeBarMoveLeft => 'Alih ke kapsul kiri';

  @override
  String get reorderHandle => 'Susun semula';

  @override
  String get personalizeVideo => 'Video';

  @override
  String get personalizeHome => 'Laman utama';

  @override
  String get personalizeBubbles => 'Gelembung';

  @override
  String get personalizeReset => 'Set semula ke lalai';

  @override
  String get personalizeResetConfirm =>
      'Set semula semua tetapan keterlihatan dan lompatan ke lalai?';

  @override
  String get personalizeResetDone => 'Lalai dipulihkan';

  @override
  String get uiItemAttachments => 'Lampiran';

  @override
  String get uiItemDate => 'Sunting tarikh';

  @override
  String get uiItemSync => 'Ikon segerak';

  @override
  String get uiItemVideoTime => 'Label masa';

  @override
  String get videoSeekBack => 'Undur';

  @override
  String get videoSeekForward => 'Maju laju';

  @override
  String get bubbleSizeSetting => 'Saiz gelembung';

  @override
  String get noteMenuCustomize => 'Sesuaikan skrin';

  @override
  String secondsShort(int seconds) {
    return '$seconds s';
  }

  @override
  String get uiItemVideoBadge => 'VIDEO';

  @override
  String get listPartRemoved => 'Senarai dibuang';

  @override
  String get textPartRemoved => 'Teks dibuang';

  @override
  String get notePartsMenu => 'Bahagian';

  @override
  String get removeListPart => 'Buang senarai';

  @override
  String get removeTextPart => 'Buang teks';

  @override
  String get transcriptTitle => 'Transkrip';

  @override
  String get transcriptAction => 'Transkripsi';

  @override
  String get transcriptFileSuffix => 'transkrip';

  @override
  String get transcriptWorkingAudio => 'Mentranskripsi audio…';

  @override
  String get transcriptWorkingVideo => 'Mentranskripsi video…';

  @override
  String get transcriptWorkingImage => 'Membaca teks dalam imej…';

  @override
  String get transcriptLongHint =>
      'Rakaman panjang boleh mengambil beberapa minit; biarkan skrin ini terbuka.';

  @override
  String get transcriptSaved => 'Disimpan ke nota sebagai lampiran teks';

  @override
  String get transcriptInsertSelection => 'Tambah pilihan ke nota';

  @override
  String get transcriptInsertAll => 'Tambah semua ke nota';

  @override
  String get transcriptInserted => 'Ditambah ke nota';

  @override
  String get transcriptNewNote => 'Nota baharu';

  @override
  String get transcriptShowTimes => 'Cap masa';

  @override
  String get transcriptDelete => 'Padam transkrip';

  @override
  String get transcriptDeleteConfirm =>
      'Padam transkrip? Fail sumber kekal dalam nota.';

  @override
  String get transcriptEmpty => 'Tiada teks ditemui.';

  @override
  String transcriptUnsupported(String format) {
    return 'Format rakaman ini ($format) tidak boleh ditranskripsi.';
  }

  @override
  String get transcriptEdit => 'Sunting';

  @override
  String get transcriptSave => 'Simpan';

  @override
  String transcriptWords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count perkataan',
      one: '1 perkataan',
    );
    return '$_temp0';
  }

  @override
  String transcriptNoteTitle(String name) {
    return 'Transkrip: $name';
  }

  @override
  String get transcriptOnDevice =>
      'Dibaca pada peranti · tanpa internet atau mata AI';

  @override
  String get addAudioFile => 'Tambah fail audio';

  @override
  String get transcribeFile => 'Transkripsi fail';

  @override
  String get transcribeFileSubtitle =>
      'Pilih audio, video atau imej; teksnya masuk ke nota';

  @override
  String cardTranscriptCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transkrip',
      one: 'Transkrip',
    );
    return '$_temp0';
  }

  @override
  String get transcriptPickTitle => 'Fail untuk ditranskripsi';

  @override
  String get transcriptUnsupportedFile =>
      'Jenis fail ini tidak boleh ditranskripsi (pilih audio, video atau imej).';

  @override
  String get pickPdfTitle => 'Pilih PDF';

  @override
  String get pickSlidesTitle => 'Pilih persembahan';

  @override
  String get pickImagesTitle => 'Pilih imej';

  @override
  String get fileAppPickerTitle => 'Pilih fail dengan Dosya Okuyucu';

  @override
  String get fileAppPickerInfo =>
      'Menambah fail membuka pembaca fail terus; jika dimatikan, anda memilih aplikasi.';

  @override
  String get viewModeAttached => 'Dilampirkan';

  @override
  String get viewModeAttachedHint =>
      'Sebagai lampiran — kekal dalam jalur di bawah';

  @override
  String get textToBubblesPreparing => 'Menyusun teks sebagai dokumen…';

  @override
  String get attachmentActions => 'Tindakan lampiran';

  @override
  String get attachmentUploadQueued => 'Menunggu dimuat naik';

  @override
  String get attachmentWaitingOwner =>
      'Menunggu orang yang menambahnya untuk memuat naik';

  @override
  String attachmentsUploadingCount(int count) {
    return 'Memuat naik $count lampiran';
  }

  @override
  String get sharedNoteNew => 'Baharu';

  @override
  String sharedNoteUpdatedBy(String name) {
    return 'Dikemas kini oleh $name';
  }

  @override
  String get sharedMarkAllRead => 'Tanda semua sebagai dibaca';

  @override
  String get attachmentSaveAs => 'Simpan sebagai';

  @override
  String attachmentSavedAs(String name) {
    return '$name disimpan';
  }

  @override
  String get attachmentSaveAsFailed => 'Tidak dapat menyimpan fail';

  @override
  String get sharedHubTitle => 'Peti masuk & dikongsi';

  @override
  String get voiceAutoStop => 'Berhenti apabila senyap';

  @override
  String get voiceAutoStopInfo =>
      'Pendengaran berhenti selepas senyap seketika apabila anda selesai.';

  @override
  String get voiceSmartCommands => 'Arahan pintar';

  @override
  String get voiceSmartCommandsInfo =>
      'Memahami arahan seperti “padam perkataan terakhir”, “ganti X dengan Y”, “baris baharu”, “buat asal”; senarai penuh dalam Panduan pengguna.';

  @override
  String get voiceAutoStopSoon => 'Senyap — akan berhenti';

  @override
  String get dictationPause => 'Jeda';

  @override
  String get dictationResume => 'Sambung';

  @override
  String get dictationPaused => 'Dijeda';

  @override
  String get dictationUndoChunk => 'Buat asal frasa terakhir';

  @override
  String dictationLocaleTooltip(String lang) {
    return 'Bahasa pertuturan: $lang';
  }

  @override
  String get voiceCmdDeleted => 'Dipadam';

  @override
  String get voiceCmdReplaced => 'Diganti';

  @override
  String get voiceCmdNewLine => 'Baris baharu';

  @override
  String get voiceCmdUndone => 'Dibuat asal';

  @override
  String get voiceCmdCleared => 'Dikosongkan';

  @override
  String get fullscreenExit => 'Keluar dari skrin penuh';

  @override
  String get voiceCaptureContinue => 'Teruskan bercakap';

  @override
  String get voiceCmdPunctuation => 'Tanda baca ditambah';

  @override
  String get voiceCmdTitle => 'Tajuk ditetapkan';

  @override
  String get voiceSilenceLabel => 'Masa menunggu';

  @override
  String get voiceSilenceShort => 'Pendek';

  @override
  String get voiceSilenceNormal => 'Biasa';

  @override
  String get voiceSilenceLong => 'Panjang';

  @override
  String get voiceOffline => 'Pengecaman luar talian';

  @override
  String get voiceOfflineInfo =>
      'Dengan pakej bahasa, pertuturan ditranskripsi tanpa internet.';

  @override
  String get discoverable => 'Benarkan orang mencari saya melalui nama';

  @override
  String get discoverableInfo =>
      'Jika dihidupkan, orang lain boleh mencari anda dalam \"Cari orang\" melalui 3 huruf pertama nama anda atau e-mel penuh. Jika dimatikan, hanya yang mengetahui e-mel anda boleh menghantar permintaan.';

  @override
  String get friendsSearchNeedsGoogle =>
      'Log masuk dengan akaun Google untuk mencari orang.';

  @override
  String get friendsSearchRateLimited =>
      'Terlalu banyak carian. Cuba lagi dalam seminit.';

  @override
  String get updateRequiredBody =>
      'Versi ini sudah lapuk: nota dibuka baca sahaja. Kemas kini aplikasi supaya data anda kekal utuh.';

  @override
  String get updateAction => 'Kemas kini';

  @override
  String get attachmentUnsupportedTitle =>
      'Kemas kini aplikasi untuk membuka lampiran ini';

  @override
  String get attachmentUnsupportedBody =>
      'Lampiran ini ditambah dalam versi aplikasi yang lebih baharu. Versi ini tidak dapat memaparkannya; ia disimpan seadanya.';

  @override
  String noteTooLarge(String size, String part) {
    return 'Nota ini semakin besar ($size / 1024 KB) — bahagian terbesar: $part. Alihkan sebahagiannya ke nota berasingan atau ia mungkin gagal disimpan.';
  }

  @override
  String get noteSizeBody => 'teks';

  @override
  String get noteSizeItems => 'item senarai';

  @override
  String get noteSizePageNotes => 'nota halaman';

  @override
  String noteSaveRejected(String reason) {
    return 'Nota tidak dapat disimpan ke pelayan: $reason';
  }

  @override
  String get errorLogShare => 'Kongsi log ralat';

  @override
  String get errorLogInfo =>
      'Ralat terkini disimpan pada peranti ini sahaja; ia tidak dihantar ke mana-mana kecuali anda berkongsi.';

  @override
  String get feedbackSend => 'Hantar maklum balas';

  @override
  String get feedbackInfo =>
      'Cadangan atau masalah: aplikasi e-mel dibuka; versi aplikasi dan jenis peranti ditambah, nota anda tidak.';

  @override
  String get feedbackNoMailApp =>
      'Tidak dapat membuka aplikasi e-mel; alamat disalin ke papan keratan.';

  @override
  String get feedbackBodyPrompt => 'Mesej anda:';

  @override
  String get errorLogEmpty => 'Tiada ralat direkodkan.';

  @override
  String get crashReports => 'Hantar laporan ranap';

  @override
  String get crashReportsInfo =>
      'Apabila aplikasi ranap, laporan teknikal tanpa kandungan nota anda dihantar ke Firebase Crashlytics (Android sahaja).';

  @override
  String get noteTooLargeShort => 'nota melebihi had 1 MiB';

  @override
  String get crashTestTitle => 'Hantar ranap ujian?';

  @override
  String get crashTestBody =>
      'Untuk mengesahkan tetapan Crashlytics, aplikasi ditutup serta-merta. Apabila dibuka semula, laporan dihantar ke konsol Firebase (mungkin mengambil beberapa minit).';

  @override
  String get crashTestAction => 'Ranap';

  @override
  String get captureModeSetting => 'Nota daripada kandungan';

  @override
  String get captureModeSettingInfo =>
      'Semasa mengambil nota daripada foto, imbasan, PDF dan imej; pilihan pertama anda kekal.';

  @override
  String get captureModeAsk => 'Tanya setiap kali';

  @override
  String get voiceMicTooltipDictate => 'Imlak — tekan lama: nota suara AI';

  @override
  String get quickAddCamera => 'Kamera';

  @override
  String get quickAddFile => 'Tambah fail';

  @override
  String get quickAddFromDevice => 'Pilih fail';

  @override
  String get quickAddFileWhat => 'Apa yang perlu dibuat dengan fail ini?';

  @override
  String get quickAddFileUnsupported => 'Jenis fail ini tidak disokong';

  @override
  String get shareFolderTogether => 'Sunting folder bersama';

  @override
  String get shareTogetherInfo =>
      'Anda berdua melihat dan mengubah nota atau folder yang sama';

  @override
  String get shareCopyInfo =>
      'Salinan berasingan pergi ke peti masuk rakan anda';

  @override
  String get notebookViewOn => 'Paparan buku nota';

  @override
  String get notebookViewOff => 'Matikan paparan buku nota';

  @override
  String inkSemantics(int count) {
    return 'Tulisan tangan, $count lakaran';
  }

  @override
  String get guestReminderTitle => 'Nota anda tidak disandarkan';

  @override
  String get guestReminderBody =>
      'Anda menggunakan aplikasi tanpa akaun: nota anda hanya ada pada peranti ini, dan AI terbina dalam serta perkongsian dimatikan. Jika data aplikasi atau pelayar dikosongkan atau anda menukar peranti, ia tidak boleh dipulihkan. Pautkan akaun Google — nota anda kekal seperti sedia ada.';

  @override
  String get guestReminderLater => 'Kemudian';

  @override
  String get driveWebConnectTitle =>
      'Lampiran ini berada dalam Google Drive anda';

  @override
  String get driveWebConnectBody =>
      'Lampiran anda disimpan dalam folder “Notlar” pada Google Drive. Sambungkan Google Drive untuk memuat turun, menyimpan luar talian dan memuat naik lampiran daripada pelayar.';

  @override
  String get driveWebConnectButton => 'Sambung Drive';

  @override
  String get lockPatternSemantics =>
      'Corak kunci: sambungkan titik dengan jari anda';

  @override
  String get lockDrawPattern => 'Lukis corak anda';

  @override
  String get lockDrawAgain => 'Lukis corak sekali lagi untuk mengesahkan';

  @override
  String get lockEnterPassword => 'Masukkan kata laluan';

  @override
  String get lockPassword => 'Kata laluan';

  @override
  String get lockPasswordAgain => 'Kata laluan (sekali lagi)';

  @override
  String get lockWrong => 'Salah, cuba lagi';

  @override
  String lockTooManyAttempts(int count) {
    return 'Terlalu banyak cubaan salah. Tunggu $count s.';
  }

  @override
  String get lockUseFingerprint => 'Buka dengan cap jari';

  @override
  String get lockForgot => 'Lupa';

  @override
  String get lockForgotFailed =>
      'Tidak dapat mengesahkan dengan akaun Google. Akaun tetamu tidak boleh menetapkan semula kata laluan.';

  @override
  String get lockNewPassword => 'Kata laluan kunci baharu';

  @override
  String get lockNewPattern => 'Corak kunci baharu';

  @override
  String lockPasswordTooShort(int count) {
    return 'Kata laluan mesti sekurang-kurangnya $count aksara';
  }

  @override
  String lockPatternTooShort(int count) {
    return 'Corak mesti menyambungkan sekurang-kurangnya $count titik';
  }

  @override
  String get lockMismatch => 'Tidak sepadan, cuba lagi';

  @override
  String get lockChangeAuthReason => 'Sahkan untuk menukar tetapan kunci';

  @override
  String get lockMethodTitle => 'Kunci nota';

  @override
  String get lockMethodInfo => 'Bagaimana nota berkunci dibuka?';

  @override
  String get lockMethodDevice => 'Cap jari';

  @override
  String get lockMethodPassword => 'Kata laluan';

  @override
  String get lockMethodPattern => 'Corak';

  @override
  String get lockAlsoFingerprint => 'Benarkan cap jari juga';

  @override
  String get lockChangePassword => 'Tukar kata laluan';

  @override
  String get lockChangePattern => 'Tukar corak';

  @override
  String get lockWebDeviceInfo =>
      'Pelayar tiada cap jari: pilih kata laluan atau corak untuk melindungi nota berkunci di web juga.';

  @override
  String get lockNotEncryption =>
      'Kandungan nota berkunci, item senarai dan nota halaman disulitkan pada peranti dengan AES-256-GCM sebelum disegerakkan. Kunci cap jari menyimpan kuncinya dalam stor kunci selamat peranti ini; kunci kata laluan atau corak menerbitkannya daripada rahsia anda — jika terlupa, kandungan yang telah dikunci tidak boleh dinyahsulit.';

  @override
  String get versionHistory => 'Sejarah versi';

  @override
  String get versionHistoryInfo =>
      'Teks nota disimpan apabila dibuka, setiap setengah jam semasa suntingan panjang dan sebelum AI mengubahnya. Lampiran tidak diberi versi.';

  @override
  String get versionHistoryEmpty =>
      'Belum ada versi. Ia terkumpul di sini semasa anda menyunting nota.';

  @override
  String get versionRestore => 'Pulihkan versi ini';

  @override
  String get versionRestored => 'Nota dipulihkan ke versi terdahulu';

  @override
  String get versionReasonAi => 'Sebelum perubahan AI';

  @override
  String get versionReasonRestore => 'Sebelum pemulihan';

  @override
  String get versionReasonOpen => 'Semasa dibuka';

  @override
  String get versionReasonAuto => 'Automatik';

  @override
  String get mergeConflictKept =>
      'Orang lain menyunting tempat yang sama — kedua-dua versi disimpan, padam yang berlebihan.';

  @override
  String presenceEditing(String name) {
    return '$name sedang menyunting';
  }

  @override
  String get presenceSomeone => 'Seseorang';

  @override
  String get frameColorInfo =>
      'Hanya dilukis di sekeliling kad di laman utama, bukan dalam nota';

  @override
  String get filterStarred => 'Berbintang';

  @override
  String get fileUseBubbles => 'Gelembung: dokumen menjadi nota';

  @override
  String get fileUseClassic => 'Klasik: dokumen menjadi lampiran';

  @override
  String get fileUseClassicImageInfo =>
      'Nota biasa dibuka; imej berada pada halaman dan teks mengalir di sekelilingnya.';

  @override
  String get fileUseVideo => 'Ambil nota pada video';

  @override
  String get fileUseVideoInfo =>
      'Video dimainkan di atas, anda menulis nota di bawah.';

  @override
  String get fileUseAudio => 'Tambah sebagai lampiran audio';

  @override
  String get fileUseAudioInfo =>
      'Rakaman kekal boleh dimainkan dalam nota; transkripsikan kemudian jika mahu.';

  @override
  String get fileUseTranscribeInfo =>
      'Pertuturan ditranskripsi dan ditulis ke dalam kandungan nota.';

  @override
  String get fileUseTranscribeImageInfo =>
      'Teks dalam imej dibaca dan ditulis ke dalam kandungan nota.';

  @override
  String get fileUseDefault => 'Lalai';

  @override
  String fileUseMore(int count) {
    return '+$count fail lagi';
  }

  @override
  String get attachAnyFileInfo =>
      'Sebarang fail: imej, PDF, slaid, audio, video — jenisnya dikesan, anda ditanya apabila perlu';

  @override
  String get listeningModeAi => 'AI';

  @override
  String get listeningModeDictation => 'Taip langsung';

  @override
  String get dictationPanelHint => 'Teks muncul di kursor semasa anda bercakap';

  @override
  String get voiceStartShort => 'Mula';

  @override
  String get archivePaperDashed => 'Garis putus-putus';

  @override
  String get itemDividerRemove => 'Buang garisan';

  @override
  String get fileUseAttachInfo =>
      'Ditambah ke nota sebagai lampiran yang boleh dimainkan';

  @override
  String get allNotesChip => 'Semua';

  @override
  String get untitledNote => 'Nota tanpa tajuk';

  @override
  String get trashAnalysis => 'Analisis tong sampah';

  @override
  String get trashAnalyze => 'Analisis pintar';

  @override
  String get trashSuggestRestore => 'Pertimbangkan untuk memulihkan';

  @override
  String get trashSuggestDelete => 'Selamat dipadam';

  @override
  String get trashSuggestNone => 'Tiada cadangan';

  @override
  String trashRestoreAllSuggested(int count) {
    return 'Pulihkan semua ($count)';
  }

  @override
  String trashDeleteAllSuggested(int count) {
    return 'Padam semua ($count)';
  }

  @override
  String trashStatNotes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nota',
      one: '1 nota',
    );
    return '$_temp0';
  }

  @override
  String trashStatAttachments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lampiran',
      one: '1 lampiran',
    );
    return '$_temp0';
  }

  @override
  String trashStatSoon(int count) {
    return '$count akan dipadam dalam 3 hari';
  }

  @override
  String trashStatLocked(int count) {
    return '$count berkunci (tidak diperiksa)';
  }

  @override
  String get trashReasonEmpty => 'Kosong — tiada yang hilang';

  @override
  String get trashReasonDuplicate => 'Nota yang sama sudah wujud';

  @override
  String trashReasonDuplicateOf(String title) {
    return 'Sama dengan: $title';
  }

  @override
  String get trashReasonDuplicateInTrash =>
      'Salinan lebih baharu juga ada dalam tong sampah';

  @override
  String trashReasonOpenTasks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tugasan terbuka',
      one: '1 tugasan terbuka',
    );
    return '$_temp0';
  }

  @override
  String get trashReasonReminder => 'Ada peringatan akan datang';

  @override
  String get trashReasonSensitive =>
      'Mengandungi maklumat seperti kata laluan, IBAN, nombor telefon';

  @override
  String trashReasonAttachments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ada $count lampiran',
      one: 'Ada 1 lampiran',
    );
    return '$_temp0';
  }

  @override
  String get trashReasonSubstantial => 'Teks panjang dan bermakna';

  @override
  String get cardElementsHeader => 'Dipaparkan pada kad';

  @override
  String get cardShowProgress => 'Pembilang kemajuan (cth. 3/10)';

  @override
  String get cardShowProgressInfo =>
      'Memaparkan item yang ditanda dengan bar dan kiraan.';

  @override
  String get cardShowChecked => 'Item selesai';

  @override
  String get cardShowCheckedInfo =>
      'Jika dimatikan, item yang ditanda diringkaskan: ✓ 3 selesai.';

  @override
  String cardItemsDone(int count) {
    return '✓ $count selesai';
  }

  @override
  String cardItemsAllDone(int count) {
    return '✓ Semua selesai ($count)';
  }

  @override
  String get emptyNotesFirstAction => 'Tulis nota pertama anda';

  @override
  String get emptyNotesHint =>
      'Nota yang anda tulis muncul di sini sebagai kad.';

  @override
  String get emptyFolderHint =>
      'Nota yang anda tambah ke folder ini terkumpul di sini.';

  @override
  String get emptyFilterHint =>
      'Kosongkan penapis untuk melihat semua nota anda semula.';

  @override
  String get emptySearchHint => 'Cuba perkataan lain.';

  @override
  String get archiveEmptyHint =>
      'Nota yang diarkibkan meninggalkan laman utama dan disimpan di sini.';

  @override
  String get trashEmptyHint =>
      'Nota yang dipadam kekal di sini selama 30 hari; anda boleh memulihkannya sehingga itu.';

  @override
  String get cardShowMoreCount => 'Baris “+N item lagi”';

  @override
  String get cardShowStatusIcons => 'Ikon status';

  @override
  String get cardShowStatusIconsInfo =>
      'Disemat, berbintang, peringatan, dikongsi, peranti ini sahaja…';

  @override
  String get cardShowTag => 'Tag';

  @override
  String get cardShowDate => 'Tarikh dan masa';

  @override
  String get cardShowMedia => 'Imej dan video';

  @override
  String get cardShowFolder => 'Nama folder';

  @override
  String get cardShowFolderInfo =>
      'Folder nota dalam hasil carian dan paparan Semua.';

  @override
  String get cardShowPaper => 'Corak kertas buku nota';

  @override
  String get formatFontPanel => 'Fon dan saiz';

  @override
  String get inkShapes => 'Bentuk';

  @override
  String get inkShapeLine => 'Garis lurus';

  @override
  String get inkShapeRectangle => 'Segi empat tepat';

  @override
  String get inkShapeEllipse => 'Bulatan / elips';

  @override
  String get inkPenOnlyOn => 'Pen sahaja (jari menatal) — matikan';

  @override
  String get inkPenOnlyOff => 'Jari juga melukis — tukar ke pen sahaja';

  @override
  String get inkPenOnlyHint =>
      'Tulis dengan pen · seret dengan jari, cubit untuk zum';

  @override
  String get inkSettings => 'Tetapan pen';

  @override
  String get inkWidth => 'Ketebalan';

  @override
  String get inkOpacity => 'Kelegapan';

  @override
  String get inkRecentColors => 'Warna terkini';

  @override
  String get inkPenOnlyTitle => 'Lukis dengan pen sahaja';

  @override
  String get inkFingerToolTitle => 'Jari';

  @override
  String get inkFingerToolInfo =>
      'Automatik: jari menatal selepas pen dikesan, jika tidak ia melukis. Menatal: hanya pen menulis, jari menatal. Melukis: jari turut menulis dengan alat pen. Memadam: jari memadam, dua jari zum.';

  @override
  String get inkFingerScroll => 'Menatal';

  @override
  String get inkFingerDraw => 'Melukis';

  @override
  String get inkFingerErase => 'Memadam';

  @override
  String get inkFingerEraseOn => 'Jari memadam — tukar ke pen sahaja';

  @override
  String get inkPressureTitle => 'Kepekaan tekanan';

  @override
  String get inkPressureInfo =>
      'Tekanan ringan menulis nipis, tekanan kuat menulis tebal.';

  @override
  String get inkStylusTipsTitle => 'Pintasan pen';

  @override
  String get inkStylusTips =>
      'Tahan butang sisi pen atau sentuh dengan hujung pemadam untuk memadam.';

  @override
  String get inkZoomReset => 'Muat ke skrin';

  @override
  String get cardShowFiles => 'Lampiran fail';

  @override
  String get cardShowFilesInfo =>
      'Tunjukkan lampiran PDF, slaid, audio dan teks pada kad';

  @override
  String get cardShowMediaShort => 'Imej pada kad';

  @override
  String get cardShowFilesShort => 'Lampiran pada kad';

  @override
  String get homeShowShared => 'Nota dikongsi di laman utama';

  @override
  String get homeShowSharedInfo =>
      'Nota dikongsi turut muncul dalam bahagian sendiri di laman utama.';

  @override
  String get homeShowSharedShort => 'Tunjukkan nota dikongsi';

  @override
  String get homeSharedAtBottom => 'Nota dikongsi di bawah nota saya';

  @override
  String get homeSharedAtBottomInfo =>
      'Jika dihidupkan, nota dikongsi berada di bawah nota anda.';

  @override
  String get homeSharedAtBottomShort => 'Nota dikongsi di bawah';

  @override
  String get homeSharedSection => 'Dikongsi';

  @override
  String get copyAttachment => 'Salin lampiran';

  @override
  String get attachmentCopiedPasteHint =>
      'Lampiran disalin — tampal ke nota lain daripada menu +';

  @override
  String get dividerSettings => 'Tetapan garisan';

  @override
  String get dividerPreviewText => 'Contoh item';

  @override
  String get dividerKind => 'Gaya';

  @override
  String get dividerColor => 'Warna';

  @override
  String get dividerWeight => 'Ketebalan';

  @override
  String get dividerApplyAll => 'Gunakan pada semua';

  @override
  String get dividerKindSolid => 'Padu';

  @override
  String get dividerKindDashed => 'Putus-putus';

  @override
  String get dividerKindDotted => 'Bertitik';

  @override
  String get dividerKindDouble => 'Berganda';

  @override
  String get dividerKindWavy => 'Beralun';

  @override
  String get itemMenuUnstar => 'Buang bintang';

  @override
  String get itemMenuMove => 'Alih';

  @override
  String get itemMenuDelete => 'Padam';

  @override
  String get itemMenuLine => 'Garisan di bawah';

  @override
  String get formatStyleText => 'Teks';

  @override
  String get formatStyleH1 => 'Tajuk';

  @override
  String get formatStyleH2 => 'Subtajuk';

  @override
  String get formatSizeDown => 'Lebih kecil';

  @override
  String get formatSizeUp => 'Lebih besar';

  @override
  String get imageCaptionHint => 'Kapsyen imej';

  @override
  String get imageCaptionAdd => 'Tambah kapsyen';

  @override
  String get imageCaptionEdit => 'Sunting kapsyen';

  @override
  String get voiceRecordResume => 'Sambung rakaman';

  @override
  String get voiceRecordDiscard => 'Buang rakaman';

  @override
  String get checkboxToggle => 'Kotak semak';

  @override
  String get noteAppearance => 'Penampilan';

  @override
  String get noteThemeNone => 'Kosong';

  @override
  String get noteThemePalm => 'Palma';

  @override
  String get noteThemeLagoon => 'Lagun';

  @override
  String get noteThemeNight => 'Malam';

  @override
  String get noteThemeSunset => 'Senja';

  @override
  String get noteThemeSakura => 'Sakura';

  @override
  String get noteThemeWaves => 'Laut';

  @override
  String get noteThemeMeadow => 'Padang rumput';

  @override
  String get noteThemePaper => 'Kertas';

  @override
  String get pinToHomeScreen => 'Tambah ke skrin utama';

  @override
  String get pinToHomeSent =>
      'Sahkan pada skrin utama anda — nota akan dibuka daripada pintasannya';

  @override
  String get pinToHomeUnsupported =>
      'Skrin utama anda tidak menyokong pintasan ini';

  @override
  String get inkColor => 'Warna pen';

  @override
  String get cardMediaHide => 'Sembunyikan pratonton imej';

  @override
  String get cardMediaShow => 'Tunjukkan pratonton imej';

  @override
  String get youTubeEmbedInNote => 'Benamkan dalam nota';

  @override
  String get goToLink => 'Pergi ke pautan';

  @override
  String get noteFlatColors => 'Warna biasa';

  @override
  String get youTubeEmbedded => 'Video dibenamkan dalam nota';

  @override
  String get inkLasso => 'Laso (pilih dan alih)';

  @override
  String get inkLassoHint =>
      'Lukis di sekeliling lakaran: seret untuk mengalihkan, pilih warna untuk mewarna semula.';

  @override
  String get inkDeleteSelection => 'Padam pilihan';

  @override
  String get inkClearSelection => 'Nyahpilih';

  @override
  String get inkShapeSnapTitle => 'Tahan untuk jadi bentuk';

  @override
  String get inkShapeSnapInfo =>
      'Tahan pen tanpa bergerak di hujung lakaran untuk mendapat garisan, bulatan atau kotak.';

  @override
  String get inkQuickSwapTitle => 'Butang pantas pen ↔ pemadam';

  @override
  String get inkQuickSwapInfo =>
      'Selepas lakaran, butang muncul untuk bertukar antara pen dan pemadam.';

  @override
  String get inkQuickSwapToEraser => 'Tukar ke pemadam';

  @override
  String get inkQuickSwapToPen => 'Kembali ke pen';

  @override
  String get inkPartialEraserTitle => 'Pemadam separa';

  @override
  String get inkPartialEraserInfo =>
      'Pemadam hanya memadam apa yang disentuh; jika dimatikan ia memadam keseluruhan lakaran.';

  @override
  String get inkAutoStylusTitle => 'Kesan pen secara automatik';

  @override
  String get inkAutoStylusInfo =>
      'Mod menulis dihidupkan apabila pen menyentuh nota.';

  @override
  String get inkStylusDetected => 'Pen dikesan — mod menulis aktif';

  @override
  String get copyAndCheckSelectedItems => 'Salin dan tanda';

  @override
  String get copiedAndChecked => 'Disalin dan ditanda';

  @override
  String get formatScopeCaret => 'Kursor';

  @override
  String get formatScopeWord => 'Perkataan';

  @override
  String get formatScopeLine => 'Baris';

  @override
  String get formatScopeAll => 'Semua';

  @override
  String get formatScopeSelection => 'Pilihan';

  @override
  String get formatScopeHint =>
      'Format digunakan pada: kursor, perkataan, baris atau semua';

  @override
  String get formatStyleMenu => 'Gaya perenggan';

  @override
  String get colorNameCoral => 'Karang';

  @override
  String get colorNamePeach => 'Pic';

  @override
  String get colorNameHoney => 'Madu';

  @override
  String get colorNameSage => 'Sage';

  @override
  String get colorNameStorm => 'Ribut';

  @override
  String get colorNameLavender => 'Lavender';

  @override
  String get colorNameClay => 'Tanah liat';

  @override
  String get colorNameChalk => 'Kapur';

  @override
  String get colorNameRed => 'Merah';

  @override
  String get colorNameYellow => 'Kuning';

  @override
  String get colorNameGreen => 'Hijau';

  @override
  String get colorNameBlue => 'Biru';

  @override
  String get colorNamePurple => 'Ungu';

  @override
  String get colorNameNone => 'Tiada warna';

  @override
  String get colorNameOrange => 'Oren';

  @override
  String get colorNamePink => 'Merah jambu';

  @override
  String get colorNameGray => 'Kelabu';

  @override
  String get colorNameCyan => 'Sian';

  @override
  String get colorNameWhite => 'Putih';

  @override
  String get colorNameBlack => 'Hitam';

  @override
  String get colorToneLight => 'cerah';

  @override
  String get colorToneVivid => 'terang';

  @override
  String get colorToneDark => 'gelap';

  @override
  String colorShade(String color, String tone) {
    return '$color, $tone';
  }

  @override
  String get itemEmptyLabel => 'Item kosong';

  @override
  String bubbleSemantic(int page, String text) {
    return 'Gelembung, halaman $page: $text';
  }

  @override
  String bubbleSemanticEmpty(int page) {
    return 'Gelembung kosong, halaman $page';
  }

  @override
  String mediaBoxSemantic(String kind, String name) {
    return '$kind: $name';
  }

  @override
  String get formatSizeLabel => 'Saiz';

  @override
  String formatSizeValue(int percent) {
    return 'Saiz $percent%';
  }

  @override
  String get customColor => 'Warna tersuai…';

  @override
  String get embedLasso => 'Pilih dengan membulatkan';

  @override
  String embedLassoHint(String name) {
    return '$name akan dipautkan — bulatkan teks atau ketik perkataan · tatal dengan dua jari';
  }

  @override
  String get embedSelectMode => 'Pautkan dengan memilih';

  @override
  String get embedLassoMissed =>
      'Tiada teks dalam bulatan — lukis di sekeliling teks';

  @override
  String get gestureItemDeleted => 'Item dipadam';

  @override
  String get itemGesturesSetting => 'Gerak isyarat item';

  @override
  String get itemGesturesSettingInfo =>
      'Lukis pada item: garis potong atau tanda; contengan memadam.';

  @override
  String get pdfEditWorking => 'Memproses PDF…';

  @override
  String get noteMenu => 'Menu nota';

  @override
  String get moreActions => 'Tindakan lain';

  @override
  String get errorOffline =>
      'Tiada atau sambungan internet lemah. Cuba lagi apabila dalam talian.';

  @override
  String get errorTimeout =>
      'Ia mengambil masa terlalu lama. Cuba lagi sebentar nanti.';

  @override
  String get errorQuota =>
      'Had penggunaan dicapai. Cuba lagi sedikit masa lagi.';

  @override
  String get errorPermission =>
      'Tidak dibenarkan. Semak akaun anda atau kebenaran aplikasi.';

  @override
  String get errorTooLarge => 'Fail terlalu besar.';

  @override
  String get errorUnsupported => 'Ini tidak disokong di sini.';

  @override
  String get errorUnknown =>
      'Sesuatu yang tidak dijangka berlaku. Butirannya dalam log ralat.';

  @override
  String get errorStateTitle => 'Tidak dapat dimuatkan';

  @override
  String get errorStateOfflineTitle => 'Anda di luar talian';

  @override
  String get copyErrorDetail => 'Salin butiran';

  @override
  String get accountRequiredTitle => 'Akaun Google diperlukan';

  @override
  String get accountRequiredBody =>
      'Kenalan, kerjasama dan penghantaran salinan berfungsi melalui alamat e-mel anda; tanpa akaun tiada sesiapa boleh mencari anda. Pautkan akaun Google — nota anda kekal seperti sedia ada.';

  @override
  String get accountRequiredBadge => 'Perlu akaun Google';

  @override
  String get deletingAccount => 'Memadam akaun dan data anda…';

  @override
  String get sharedHubShort => 'Masuk';

  @override
  String get itemEmptyHint => 'Tulis item';

  @override
  String get allFolders => 'Semua folder';

  @override
  String get guestReminderConnect => 'Sambung';

  @override
  String get filterSectionType => 'Jenis';

  @override
  String get reorderNotesManually => 'Susun secara manual';

  @override
  String get shareIncludeBubbles => 'Gelembung';

  @override
  String sharedFolderBar(String role) {
    return 'Folder dikongsi · $role';
  }

  @override
  String get shareSendSection => 'Hantar keluar';

  @override
  String get shareInAppSection => 'Dengan orang';

  @override
  String get shareTextHint =>
      'Menghantar teks nota ke aplikasi (WhatsApp, e-mel…)';

  @override
  String get shareCopyHint => 'Menyalin teks nota ke papan keratan';

  @override
  String get shareQuickPdfHint =>
      'Menghantar nota sebagai fail PDF dengan satu ketikan';

  @override
  String get shareAsImageHint =>
      'Menghantar nota sebagai imej, halaman demi halaman';

  @override
  String get shareAttachmentFilesHint =>
      'Menghantar foto, PDF, audio dan video nota itu sendiri';

  @override
  String get shareAsNoteInfo =>
      'Satu fail dengan lampiran, halaman, lukisan dan gelembung; dibuka tepat dalam aplikasi ini';

  @override
  String get bubbleCopy => 'Salin';

  @override
  String get bubblesCopyAll => 'Salin semua';

  @override
  String get bubblesToNote => 'Tambah ke nota';

  @override
  String get bubblesToNoteDone => 'Gelembung ditambah di hujung nota';

  @override
  String get bubbleMark => 'Tanda';

  @override
  String get bubbleFormat => 'Format';

  @override
  String get sharedHubTagInbox => 'Masuk';

  @override
  String get sharedHubTagShared => 'Dikongsi';

  @override
  String get sharedHubEmpty => 'Belum ada yang diterima atau dikongsi di sini';

  @override
  String get sharedHubEmptyHint =>
      'Salinan yang dihantar rakan anda dan nota dikongsi yang mereka tambah anda muncul bersama di sini.';

  @override
  String get settingsModulesTitle => 'Modul & nota pantas';

  @override
  String settingsModulesSummary(int on, int total) {
    return '$on/$total modul aktif';
  }

  @override
  String get settingsSoundTitle => 'Dengar & imlak';

  @override
  String cardElementsSummary(int on, int total) {
    return '$on/$total aktif · lihat contoh';
  }

  @override
  String get cardElementsSampleTitle => 'Beli-belah hujung minggu';

  @override
  String cardElementsSampleItem(int n) {
    return 'Item $n';
  }

  @override
  String get cardElementsSampleTag => 'rumah';

  @override
  String get tipListGestures =>
      'Petua: garis potong item dengan jari → ia ditanda.';

  @override
  String get tipMediaPin =>
      'Petua: tekan lama imej dan seret ke atas → ia disemat di atas nota.';

  @override
  String get tipGridSwipeFolders =>
      'Petua: leret skrin ke tepi → bergerak antara folder.';

  @override
  String get tipGridSwipeFilters =>
      'Petua: leret skrin ke tepi → bergerak antara penapis.';

  @override
  String get tipsResetTitle => 'Tunjukkan petua semula';

  @override
  String get tipsResetInfo =>
      'Petua kecil sekali sahaja (gerak isyarat, carian Makna) muncul semula.';

  @override
  String get tipsResetDone => 'Petua akan ditunjukkan semula';

  @override
  String get tipsEnabledTitle => 'Tunjukkan petua berguna';

  @override
  String get tipsEnabledInfo =>
      'Tunjukkan petunjuk ringkas dan tenang kali pertama anda menggunakan ciri.';

  @override
  String get tipFormatScope =>
      'Petua: tukar skop antara kursor, perkataan, baris atau semua; ketik peratus untuk set semula saiz ke 100%.';

  @override
  String get tipTableGestures =>
      'Petua: seret sempadan lajur untuk mengubah saiz, atau tekan Tab untuk ke sel seterusnya.';

  @override
  String get tipItemHoldSelect =>
      'Petua: tahan item untuk pilih berbilang; gunakan julat, songsang dan format pukal dari bar bawah.';

  @override
  String get tipVoiceCommands =>
      'Petua: sebut \"baris baharu\", \"item baharu\", \"noktah\" atau \"padam perkataan terakhir\" semasa imlak.';

  @override
  String get tipFolderGestures =>
      'Petua: tahan folder untuk pilihan pantas, atau seret nota ke folder untuk mengalihkannya.';

  @override
  String get tipPinnedSplitResize =>
      'Petua: seret pemegang pemisah untuk mengubah saiz, atau tukar sisi dari bar disemat.';

  @override
  String get tipPinnedSmartActions =>
      'Petua: buka tindakan pintar dari bar disemat untuk meringkaskan halaman, mengekstrak teks atau bertanya AI.';

  @override
  String get tipCrossAppDosyalarim =>
      'Petua: buka PDF dan fail dilampirkan dalam Dosyalarım; Kolam AI Dikongsi berfungsi merentasi kedua-dua aplikasi.';

  @override
  String get swipeModeInfo =>
      'Apa yang dilakukan leretan ke tepi dalam paparan grid; dalam paparan senarai, meleret baris menyemat atau mengarkibkan.';

  @override
  String get backupInfo =>
      'Semua nota dengan lampiran dan folder dalam satu fail; mengimport dua kali tidak menduakan.';

  @override
  String get backupInProgress => 'Menyediakan sandaran';

  @override
  String get restoreInProgress => 'Memulihkan';

  @override
  String get backupShareSubject => 'Sandaran nota';

  @override
  String get backupCancelled => 'Dibatalkan';

  @override
  String backupProgressCount(int done, int total) {
    return '$done / $total nota';
  }

  @override
  String restoreBackupResult(int restored, int skipped) {
    return '$restored nota dipulihkan, $skipped dilangkau (sudah ada)';
  }

  @override
  String get accountRecoverBringNotes => 'Bawa nota saya';

  @override
  String accountRecoverBringDone(int count) {
    return 'Akaun ditukar, $count nota dialihkan';
  }

  @override
  String get accountRecoverBringFailed =>
      'Akaun ditukar tetapi nota tidak dapat dialihkan; nota tetamu tidak disentuh';

  @override
  String get appLockTitle => 'Kunci aplikasi';

  @override
  String get appLockInfo =>
      'Meminta semasa dilancarkan dan kembali dari latar belakang, menggunakan kaedah kunci nota. Bukan penyulitan; peranti ini sahaja.';

  @override
  String get appLockWebNeedsSecret =>
      'Tiada kunci peranti di web: pilih kata laluan atau corak di atas dahulu.';

  @override
  String get appLockReason => 'Buka Nota';

  @override
  String get appLockLockedTitle => 'Nota berkunci';

  @override
  String get appLockUnlock => 'Buka kunci';

  @override
  String get appLockDelayTitle => 'Kunci:';

  @override
  String get appLockDelayNow => 'serta-merta';

  @override
  String appLockDelayMinutes(int minutes) {
    return 'selepas $minutes min';
  }

  @override
  String get appLockHideRecents =>
      'Sembunyikan kandungan dalam aplikasi terkini';

  @override
  String get repeatTitle => 'Ulang';

  @override
  String get repeatNone => 'Jangan ulang';

  @override
  String get repeatDaily => 'Setiap hari';

  @override
  String get repeatWeekdays => 'Setiap hari bekerja';

  @override
  String get repeatWeekly => 'Setiap minggu';

  @override
  String repeatWeeklyOn(String days) {
    return 'Mingguan: $days';
  }

  @override
  String get repeatMonthly => 'Setiap bulan';

  @override
  String get repeatYearly => 'Setiap tahun';

  @override
  String get importOther => 'Import daripada aplikasi lain';

  @override
  String get importOtherInfo =>
      'Google Keep (Takeout zip), Markdown/txt (fail atau zip), Evernote (.enex)';

  @override
  String get importInProgress => 'Mengimport';

  @override
  String get importOtherNone => 'Tiada nota untuk diimport dalam fail ini';

  @override
  String importOtherResult(int imported, int skipped, int failed) {
    return '$imported nota diimport, $skipped dilangkau (sudah ada), $failed tidak boleh dibaca';
  }

  @override
  String get noteLinkAction => 'Pautkan ke nota';

  @override
  String get noteLinkOpen => 'Buka nota';

  @override
  String get noteLinkPickTitle => 'Pautkan ke nota mana?';

  @override
  String get noteLinkInserted => 'Dipautkan ke nota';

  @override
  String get noteLinkMissing =>
      'Nota terpaut tidak ditemui (mungkin telah dipadam)';

  @override
  String get backlinksTitle => 'Nota yang memaut ke sini';

  @override
  String backlinksCount(int count) {
    return '$count pautan balik';
  }

  @override
  String get relatedNotesTitle => 'Nota berkaitan';

  @override
  String get relatedNotesNone => 'Tiada nota berkaitan ditemui';

  @override
  String get relatedNotesLink => 'Pautkan';

  @override
  String get studyCardsTitle => 'Kad hari ini';

  @override
  String get studyCardsEmpty => 'Tiada kad perlu diulang hari ini';

  @override
  String get studyCardsDone => 'Semua selesai untuk hari ini!';

  @override
  String get studyCardsEmptyInfo =>
      'Gunakan \"Buat kad\" dalam menu ⋮ nota dan AI menukar nota kepada kad soal–jawab.';

  @override
  String studyCardsLeft(int count) {
    return '$count kad lagi';
  }

  @override
  String get studyCardsReveal => 'Tunjukkan jawapan';

  @override
  String get studyGradeAgain => 'Lagi';

  @override
  String get studyGradeHard => 'Sukar';

  @override
  String get studyGradeGood => 'Baik';

  @override
  String get studyGradeEasy => 'Mudah';

  @override
  String updateAvailable(String name) {
    return 'Versi baharu tersedia: $name';
  }

  @override
  String get pdfNoteFromSelection => 'Ambil nota';

  @override
  String get pdfNoteAtPage => 'Nota halaman ini';

  @override
  String get tipPdfReadNote =>
      'Petua: tekan lama teks, pilih → \"Ambil nota\": halaman dan baris masuk ke nota anda, ketik untuk kembali.';

  @override
  String showMoreChecked(int n) {
    return 'Tunjukkan yang ditanda ($n tersembunyi)';
  }

  @override
  String get hideMoreChecked => 'Kuncupkan yang ditanda';

  @override
  String get gmailGoogleOnly =>
      'Log masuk dengan Google untuk menggunakan Gmail.';

  @override
  String get tipHomeMicHold =>
      'Petua: tekan lama mikrofon untuk nota suara AI.';

  @override
  String get itemGesturesFingerAll =>
      'Gerak isyarat padam dan betulkan dengan jari juga';

  @override
  String get itemGesturesFingerAllInfo =>
      'Jika dimatikan, jari hanya menanda; contengan dan bulatan memerlukan pen.';

  @override
  String get itemAddHeader => 'Subtajuk';

  @override
  String get itemHeaderHint => 'Tulis subtajuk';

  @override
  String get itemMenuToHeader => 'Jadikan tajuk';

  @override
  String get itemMenuToItem => 'Jadikan item';

  @override
  String get pinnedMediaFit => 'Muat';

  @override
  String get tagRemove => 'Buang tag';

  @override
  String get itemAlignStart => 'Jajar kiri';

  @override
  String get itemAlignCenter => 'Tengah';

  @override
  String get itemAlignEnd => 'Jajar kanan';

  @override
  String get themeLavender => 'Lavender';

  @override
  String get themeOlive => 'Zaitun';

  @override
  String get tplShopMeat => 'Daging, ayam & ikan';

  @override
  String get tplShopMeatItems =>
      'Daging cincang, Dada ayam, Peha ayam, Daging lembu kiub, Ikan, Sosej, Ayam belanda salai, Bebola daging';

  @override
  String get tplShopDrinks => 'Minuman';

  @override
  String get tplShopDrinksItems =>
      'Air, Air berkarbonat, Jus, Susu masam, Soda, Teh ais, Susu';

  @override
  String get tplShopSnacks => 'Snek';

  @override
  String get tplShopSnacksItems =>
      'Biskut, Coklat, Kerepek, Kacang, Keropok, Wafer, Buah kering';

  @override
  String get tplShopFrozen => 'Sejuk beku';

  @override
  String get tplShopFrozenItems =>
      'Aiskrim, Kacang pis, Kentang goreng, Ladu, Piza, Pastri';

  @override
  String get tplShopBaby => 'Bayi';

  @override
  String get tplShopBabyItems =>
      'Lampin, Tisu basah, Susu formula, Syampu bayi, Krim lampin';

  @override
  String get tplShopPet => 'Haiwan peliharaan';

  @override
  String get tplShopPetItems =>
      'Makanan kucing, Makanan anjing, Pasir kucing, Snek, Penggelek bulu';

  @override
  String get tplTravelHealth => 'Kesihatan';

  @override
  String get tplTravelHealthItems =>
      'Ubat tahan sakit, Plaster, Ubat perut, Preskripsi, Penghalau nyamuk, Pelitup muka';

  @override
  String get tplTravelBeforeGo => 'Sebelum bertolak';

  @override
  String get tplTravelBeforeGoItems =>
      'Periksa dapur, Tutup tingkap, Buang sampah, Siram pokok, Cabut palam peranti, Bawa kunci';

  @override
  String get tplCleanKitchen => 'Dapur';

  @override
  String get tplCleanKitchenItems =>
      'Pinggan, Kaunter, Dapur, Ketuhar, Peti sejuk, Sinki, Gelombang mikro';

  @override
  String get tplCleanBath => 'Bilik air';

  @override
  String get tplCleanBathItems =>
      'Tandas, Sinki, Pancuran, Cermin, Celah jubin, Tukar tuala';

  @override
  String get tplCleanRooms => 'Bilik';

  @override
  String get tplCleanRoomsItems =>
      'Buang habuk, Vakum, Mop, Kemas katil, Bersihkan tingkap, Kibas permaidani';

  @override
  String get tplCleanMonthly => 'Bulanan';

  @override
  String get tplCleanMonthlyItems =>
      'Langsir, Penapis penghawa dingin, Dalam almari, Penjagaan mesin basuh, Penapis hud';

  @override
  String get tplMoveBefore => 'Sebelum berpindah';

  @override
  String get tplMoveBeforeItems =>
      'Tempah syarikat pindah, Beli kotak dan pita, Buang barang tidak perlu, Labelkan kotak, Maklumkan penyedia utiliti, Tukar alamat';

  @override
  String get tplMoveDay => 'Hari berpindah';

  @override
  String get tplMoveDayItems =>
      'Ambil gambar meter, Serahkan kunci, Simpan barang berharga bersama anda, Pemeriksaan akhir, Beg malam pertama';

  @override
  String get tplMoveAfter => 'Selepas berpindah';

  @override
  String get tplMoveAfterItems =>
      'Pasang internet, Daftar alamat, Tukar kunci, Kemas kini alamat bank, Berkenalan dengan jiran';

  @override
  String get tplHabitHealth => 'Kesihatan';

  @override
  String get tplHabitHealthItems =>
      '8 gelas air, Berjalan 30 minit, Tidur awal, Hari tanpa gula, Ambil vitamin, Regangan';

  @override
  String get tplHabitMind => 'Minda';

  @override
  String get tplHabitMindItems =>
      'Baca 20 halaman, Meditasi, Tulis jurnal, Satu jam tanpa skrin, Belajar perkataan baharu';

  @override
  String get tplHabitHome => 'Rumah';

  @override
  String get tplHabitHomeItems =>
      'Selesaikan basuh pinggan, Kemas 10 minit, Siram pokok, Rancang esok';

  @override
  String get tplWorkoutUpper => 'Bahagian atas badan';

  @override
  String get tplWorkoutUpperItems =>
      'Tekan tubi 3×10, Tarik naik 3×6, Tekan bahu 3×10, Bisep curl 3×12, Celup trisep 3×10, Plank 3×45 s';

  @override
  String get tplWorkoutLower => 'Bahagian bawah badan';

  @override
  String get tplWorkoutLowerItems =>
      'Cangkung 3×12, Terjah 3×10, Jambatan glut 3×15, Angkat betis 3×20, Duduk dinding 3×40 s';

  @override
  String get tplWorkoutCardio => 'Kardio';

  @override
  String get tplWorkoutCardioItems =>
      'Lari 20 min, Lompat tali 5 min, Berbasikal 30 min, Lompat bintang 3×30, Burpee 3×10';

  @override
  String get tplGiftPeople => 'Orang';

  @override
  String get tplGiftPeopleItems =>
      'Ibu, Ayah, Adik-beradik, Pasangan, Rakan, Guru, Rakan sekerja, Anak';

  @override
  String get tplGiftIdeas => 'Idea';

  @override
  String get tplGiftIdeasItems =>
      'Buku, Bunga, Minyak wangi, Jam tangan, Hadiah pengalaman, Buatan tangan, Mug, Kad hadiah';

  @override
  String get tplTodoHome => 'Rumah';

  @override
  String get tplTodoHomeItems =>
      'Bayar bil, Basuh pakaian, Barang dapur, Pembaikan, Buat temu janji';

  @override
  String get tplTodoErrands => 'Urusan';

  @override
  String get tplTodoErrandsItems =>
      'Ke bank, Hantar bungkusan, Farmasi, Cucian kering, Pejabat pos';

  @override
  String get templateFavorite => 'Tambah ke kegemaran';

  @override
  String get templateUnfavorite => 'Buang daripada kegemaran';

  @override
  String get templatesFavorites => 'Kegemaran';

  @override
  String get templateFavoritesFull =>
      'Maksimum 4 kegemaran — buang satu dahulu';

  @override
  String get calendarTitle => 'Kalendar';

  @override
  String get calendarToday => 'Hari ini';

  @override
  String get calendarViewAgenda => 'Agenda';

  @override
  String get calendarViewMonth => 'Bulan';

  @override
  String get calendarNewEvent => 'Acara baharu';

  @override
  String get calendarEmpty => 'Belum ada acara di sini';

  @override
  String get calendarEmptyHint =>
      'Tambah acara; nota dengan peringatan juga muncul di sini.';

  @override
  String get calendarNothingThisDay => 'Tiada rancangan untuk hari ini';

  @override
  String get calendarReminderTag => 'Peringatan';

  @override
  String get calendarShowMonth => 'Tunjukkan bulan';

  @override
  String get calendarHideMonth => 'Sembunyikan bulan';

  @override
  String get calendarPrevMonth => 'Bulan sebelumnya';

  @override
  String get calendarNextMonth => 'Bulan seterusnya';

  @override
  String get calendarMoreDays => 'Lebih jauh';

  @override
  String get eventEditTitle => 'Sunting acara';

  @override
  String get eventTitleHint => 'Tambah tajuk';

  @override
  String get eventUntitled => '(Tiada tajuk)';

  @override
  String get eventAllDay => 'Sepanjang hari';

  @override
  String get eventStarts => 'Bermula';

  @override
  String get eventEnds => 'Berakhir';

  @override
  String get eventReminder => 'Peringatan';

  @override
  String get eventReminderNone => 'Tiada peringatan';

  @override
  String get eventReminderAtStart => 'Pada masa mula';

  @override
  String get eventReminderAllDayMorning => 'Pada hari itu jam 09:00';

  @override
  String eventReminderMinutes(int count) {
    return '$count minit sebelum';
  }

  @override
  String eventReminderHours(int count) {
    return '$count jam sebelum';
  }

  @override
  String eventReminderDays(int count) {
    return '$count hari sebelum';
  }

  @override
  String get eventLocation => 'Lokasi';

  @override
  String get eventDescription => 'Penerangan';

  @override
  String get eventSave => 'Simpan';

  @override
  String get eventDelete => 'Padam acara';

  @override
  String get eventDeleted => 'Acara dipadam';

  @override
  String get eventDeleteRepeatingTitle => 'Acara berulang';

  @override
  String get eventDeleteThis => 'Acara ini sahaja';

  @override
  String get eventDeleteAll => 'Semua kejadian';

  @override
  String get eventNotificationAllDay => 'Hari ini · sepanjang hari';

  @override
  String get tasksTitle => 'Tugasan';

  @override
  String get tasksDefaultList => 'Tugasan saya';

  @override
  String get tasksNewTask => 'Tugasan baharu';

  @override
  String get tasksNewList => 'Senarai baharu';

  @override
  String get tasksListNameHint => 'Nama senarai';

  @override
  String get tasksRenameList => 'Namakan semula senarai';

  @override
  String get tasksDeleteList => 'Padam senarai';

  @override
  String get tasksDeleteListConfirm => 'Padam senarai dan tugasannya?';

  @override
  String get tasksEmpty => 'Tiada tugasan di sini';

  @override
  String get tasksEmptyHint =>
      'Tambah perkara yang perlu dibuat; tugasan bertarikh akhir juga muncul dalam kalendar.';

  @override
  String tasksCompleted(int count) {
    return 'Selesai ($count)';
  }

  @override
  String get tasksClearCompleted => 'Padam yang selesai';

  @override
  String get taskEditTitle => 'Sunting tugasan';

  @override
  String get taskTitleHint => 'Apa yang perlu dibuat?';

  @override
  String get taskNotesHint => 'Tambah butiran';

  @override
  String get taskDue => 'Tarikh akhir';

  @override
  String get taskNoDue => 'Tiada tarikh';

  @override
  String get taskTime => 'Masa';

  @override
  String get taskNoTime => 'Tiada masa';

  @override
  String get taskReminderAtDue => 'Ingatkan saya apabila tiba masanya';

  @override
  String get taskList => 'Senarai';

  @override
  String get taskStar => 'Bintangkan';

  @override
  String get taskDelete => 'Padam tugasan';

  @override
  String get taskDeleted => 'Tugasan dipadam';

  @override
  String get taskAddSubtask => 'Tambah subtugasan';

  @override
  String get taskOverdue => 'Tertunggak';

  @override
  String get calendarViewYear => 'Tahun';

  @override
  String get calendarViewWeek => 'Minggu';

  @override
  String get calendarPinchHint =>
      'Cubit dengan dua jari untuk bergerak antara tahun, bulan dan minggu';

  @override
  String get calendarPrevious => 'Sebelumnya';

  @override
  String get calendarNext => 'Seterusnya';

  @override
  String get themeWhite => 'Putih';

  @override
  String get themeStraw => 'Jerami';

  @override
  String get calendarSwipe => 'Leret untuk tukar minggu/hari dalam kalendar';

  @override
  String get calendarSwipeInfo =>
      'Jika dimatikan, hanya butang anak panah menukar bulan atau minggu.';

  @override
  String calendarMoved(String day) {
    return 'Dialihkan ke $day';
  }

  @override
  String get gcalTitle => 'Google Calendar';

  @override
  String get gcalInfo =>
      'Acara daripada Google Calendar anda muncul di sini (baca sahaja). Anda boleh memautkan nota; tiada apa ditulis ke Google.';

  @override
  String get gcalConnect => 'Sambungkan Google Calendar';

  @override
  String get gcalConnectFailed => 'Tidak dapat menyambung Google Calendar';

  @override
  String get gcalCalendars => 'Kalendar yang dipaparkan';

  @override
  String get gcalRefresh => 'Muat semula';

  @override
  String get gcalDisconnect => 'Putuskan';

  @override
  String get gcalError =>
      'Google Calendar tidak dapat dicapai sekarang; memaparkan acara yang dicache.';

  @override
  String get gcalReadOnly =>
      'Acara Google Calendar · sunting yang berulang dalam Google Calendar';

  @override
  String get gcalOpenInGoogle => 'Buka dalam Google Calendar';

  @override
  String get calendarMeetingNote => 'Nota mesyuarat';

  @override
  String get calendarLinkedNotes => 'Nota terpaut';

  @override
  String get calendarUnlinkNote => 'Nyahpaut';

  @override
  String gcalSyncedAt(String time) {
    return 'Terakhir disegerakkan $time';
  }

  @override
  String get calendarLinked => 'Dipautkan ke kalendar';

  @override
  String get calendarLinkNote => 'Pautkan ke kalendar';

  @override
  String get calendarLinkToDay => 'Pautkan ke hari';

  @override
  String get calendarLinkNewEvent => 'Cipta acara dan pautkan';

  @override
  String get calendarLinkToEvent => 'Pautkan ke acara';

  @override
  String get calendarHolidays => 'Cuti umum (Turkiye)';

  @override
  String get calendarHolidayEstimated => 'anggaran';

  @override
  String get calendarDayNote => 'Nota untuk hari ini';

  @override
  String calendarDayWrittenNotes(int count) {
    return 'Nota yang ditulis pada hari itu ($count)';
  }

  @override
  String calendarMoreCount(int count) {
    return '+$count lagi';
  }

  @override
  String get calendarWeekSummaryTitle => 'Minggu ini';

  @override
  String calendarWeekSummaryPlans(int count) {
    return '$count rancangan';
  }

  @override
  String calendarWeekSummaryNotes(int count) {
    return '$count nota';
  }

  @override
  String get itemMenuTask => 'Jadikan tugasan';

  @override
  String get gtasksTitle => 'Google Tasks';

  @override
  String get gtasksConnected => 'Google Tasks disambung dan disegerakkan';

  @override
  String get gtasksFailed => 'Tidak dapat menyegerak dengan Google Tasks';

  @override
  String get gtasksSyncNow => 'Segerak sekarang';

  @override
  String get gtasksSynced => 'Tugasan disegerakkan';

  @override
  String get eventSaveLocal => 'Semua peranti';

  @override
  String get gcalWriteDenied =>
      'Kebenaran menulis ke Google Calendar tidak diberikan';

  @override
  String get gcalDeleteConfirm =>
      'Padam acara ini daripada Google Calendar? Ini tidak boleh dibuat asal.';

  @override
  String get gcalEdit => 'Sunting';

  @override
  String gcalPending(int count) {
    return '$count perubahan menunggu dihantar ke Google';
  }

  @override
  String get ocrToEvent => 'Tambah ke kalendar sebagai acara';

  @override
  String get calendarSuggestAction => 'Tambah ke kalendar';

  @override
  String calendarSuggest(String when) {
    return 'Nota anda menyebut $when';
  }

  @override
  String get calendarIcsExport => 'Eksport kalendar (.ics)';

  @override
  String get calendarIcsImport => 'Import fail kalendar (.ics)';

  @override
  String calendarIcsImported(int count, int skipped) {
    return '$count acara ditambah, $skipped sudah wujud';
  }

  @override
  String get routinesTitle => 'Rutin';

  @override
  String get routineNew => 'Rutin baharu';

  @override
  String get routineEdit => 'Sunting rutin';

  @override
  String get routinesEmpty => 'Belum ada rutin di sini';

  @override
  String get routinesEmptyHint =>
      'Sediakan rancangan berulang seperti rutin pagi: tanda langkahnya dan lihat rentetan anda.';

  @override
  String get routineDoneToday => 'Selesai hari ini';

  @override
  String get routineStartToday => 'Tanda hari ini';

  @override
  String get routineDone => 'Selesai';

  @override
  String get routineTitleHint => 'Nama rutin';

  @override
  String get routineTime => 'Masa';

  @override
  String get routineRemind => 'Ingatkan saya apabila tiba masanya';

  @override
  String get routineSteps => 'Langkah';

  @override
  String get routineStepHint => 'Langkah';

  @override
  String get routineAddStep => 'Tambah langkah';

  @override
  String get routineDeleted => 'Rutin dipadam';

  @override
  String routineStreak(int count) {
    return '🔥 $count hari';
  }

  @override
  String routineStepCount(int count) {
    return '$count langkah';
  }

  @override
  String routineProgress(int done, int total) {
    return '$done/$total langkah';
  }

  @override
  String get menuSearchHint =>
      'Cari mengikut nama atau fungsi (cth. jumlah, kongsi)';

  @override
  String get menuSearchEmpty => 'Tiada tindakan yang sepadan';

  @override
  String get menuEdit => 'Sunting menu';

  @override
  String get menuSectionOther => 'Lain-lain';

  @override
  String get menuQuickRow => 'Letak dalam baris pantas';

  @override
  String get menuReset => 'Lalai';

  @override
  String get themeCream => 'Krim';

  @override
  String get themePeach => 'Pic';

  @override
  String get themeMint => 'Pudina';

  @override
  String get themeOcean => 'Lautan';

  @override
  String get themeRose => 'Mawar';

  @override
  String get themeTangerine => 'Limau tangerin';

  @override
  String get themeEmerald => 'Zamrud';

  @override
  String get themeAmethyst => 'Kecubung';

  @override
  String get themePickerTitle => 'Tema';

  @override
  String get reminderQuickInHour => 'Dalam 1 jam';

  @override
  String get reminderSheetTitle => 'Peringatan';

  @override
  String get reminderSheetRemove => 'Buang';

  @override
  String get reminderSheetSave => 'Simpan';

  @override
  String get homeFolderStripHide => 'Sembunyikan baris folder';

  @override
  String get homeViewMenu => 'Paparan & tapis';

  @override
  String googleApiDisabled(String api) {
    return '$api dilumpuhkan dalam projek Google Cloud aplikasi ini. Dayakan dalam konsol dan sambung semula.';
  }

  @override
  String get googleApiEnable => 'Dayakan';

  @override
  String googleScopeMissing(String api) {
    return 'Kebenaran $api tidak diberikan. Tandakan kotak kebenaran semasa menyambung.';
  }

  @override
  String get friendsEmptyTitle => 'Belum ada kenalan di sini';

  @override
  String get friendsFilterHint => 'Cari kenalan';

  @override
  String get friendsNoName => 'Tiada nama';

  @override
  String get friendsSharedFolders => 'Folder dikongsi';

  @override
  String get friendsNoSharedFolders =>
      'Anda belum berkongsi folder dengan orang ini.';

  @override
  String friendsSince(String date) {
    return 'Dalam kenalan anda sejak $date';
  }

  @override
  String get friendsCopyEmail => 'Salin e-mel';

  @override
  String get friendsEmailCopied => 'E-mel disalin';

  @override
  String get friendsWantsToConnect => 'Mahu menambah anda sebagai kenalan';

  @override
  String get friendsSendToEmail => 'Hantar permintaan ke alamat ini';

  @override
  String get friendsSent => 'Dihantar';

  @override
  String get friendsAlreadyShort => 'Dalam kenalan';

  @override
  String get settingsGroupAccount => 'Akaun';

  @override
  String get settingsGroupApp => 'Aplikasi';

  @override
  String get settingsUpdatesTitle => 'Kemas kini dan versi';

  @override
  String get settingsGroupData => 'Data dan privasi';

  @override
  String get settingsGroupOther => 'Lain-lain';

  @override
  String friendsCountSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kenalan',
      one: '1 kenalan',
      zero: 'Belum ada kenalan',
    );
    return '$_temp0';
  }

  @override
  String friendsRequestsSummary(int count) {
    return '$count belum selesai';
  }

  @override
  String get inkFixApply => 'Kemaskan bentuk';

  @override
  String get inkShapeSuggestTitle => 'Kenal pasti bentuk';

  @override
  String get inkShapeSuggestInfo =>
      'Lukis bulatan, kotak, garis atau anak panah kasar untuk mendapat butang kemaskan.';

  @override
  String get inkMarkFixTitle => 'Kemaskan tanda semak dan pangkah';

  @override
  String get inkMarkFixInfo =>
      'Menunjukkan butang kemaskan untuk tanda ✓ dan ✗ lukisan tangan.';

  @override
  String get inkMarkFixAskTitle => 'Hidupkan kemasan tanda semak dan pangkah?';

  @override
  String get inkMarkFixAskBody =>
      'Tanda semak dan pangkah lukisan tangan boleh dikemaskan. Anda mengesahkan setiap satu dengan butang kecil di sebelahnya; anda boleh mematikannya dalam tetapan pen.';

  @override
  String get inkMarkFixAskYes => 'Hidupkan';

  @override
  String get inkMarkFixAskNo => 'Tidak';

  @override
  String get inkPinPen => 'Semat pen ini';

  @override
  String get inkPinnedPen => 'Pen disemat · tahan untuk membuang';

  @override
  String get reminderLevelTitle => 'Pemberitahuan';

  @override
  String get reminderLevelLow => 'Rendah';

  @override
  String get reminderLevelNormal => 'Biasa';

  @override
  String get reminderLevelHigh => 'Tinggi';

  @override
  String get reminderLevelUrgent => 'Segera';

  @override
  String get reminderLevelLowInfo => 'Senyap; hanya dalam laci pemberitahuan';

  @override
  String get reminderLevelNormalInfo => 'Bunyi biasa, tanpa timbul';

  @override
  String get reminderLevelHighInfo => 'Bunyi dan timbul di atas skrin';

  @override
  String get reminderLevelUrgentInfo =>
      'Skrin penuh, keutamaan tertinggi (seperti penggera)';

  @override
  String get itemMenuRemind => 'Ingatkan';

  @override
  String get taskContactHint => 'Orang (kepada / daripada)';

  @override
  String get taskGmailHint => 'Pautan Gmail';

  @override
  String dueBadgeTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count peringatan/tugasan menunggu',
      one: '1 peringatan/tugasan menunggu',
    );
    return '$_temp0';
  }

  @override
  String get dueBadgeBody =>
      'Perlu sekarang dan tugasan hari ini — di laman utama';

  @override
  String get dueBadgeChannel => 'Menunggu (lencana ikon)';

  @override
  String get quickRowAttach => 'Tambah';

  @override
  String get quickRowColor => 'Warna teks (tahan: pilih kegemaran)';

  @override
  String get penModePenOnlyOn =>
      'Mod pen · Stilus sahaja: hidup (jari menatal)';

  @override
  String get penModePenOnlyOff =>
      'Mod pen · Stilus sahaja: mati (jari juga melukis)';

  @override
  String get penModeSettings => 'Tetapan';

  @override
  String get quickRowBold => 'Tebal';

  @override
  String get quickRowBullet => 'Titik';

  @override
  String get quickRowHeading => 'Tajuk (berkitar)';

  @override
  String get quickRowPhoto => 'Tambah foto';

  @override
  String get quickRowFile => 'Lampirkan fail';

  @override
  String get quickRowPen => 'Tulis dengan pen · tahan: tetapan pen';

  @override
  String get editorBarEraser => 'Pemadam · membuka mod pen dengan pemadam';

  @override
  String get quickRowReminder => 'Peringatan';

  @override
  String get hideBarWhileTyping => 'Sembunyikan bar bawah semasa menaip';

  @override
  String get hideBarWhileTypingInfo =>
      'Bar bawah turun semasa anda menaip dan kembali apabila berhenti.';

  @override
  String get typingBarHideDelay => 'Lengah sembunyi';

  @override
  String get typingBarHideDelayInfo =>
      'Berapa lama selepas mula menaip bar disembunyikan';

  @override
  String get typingBarShowDelay => 'Lengah muncul semula';

  @override
  String get typingBarShowDelayInfo =>
      'Berapa lama selepas berhenti menaip bar kembali';

  @override
  String secondsValue(String value) {
    return '$value s';
  }

  @override
  String get tipHideBarTyping =>
      'Bar bawah tersembunyi semasa menaip dan kembali apabila berhenti seketika. Anda boleh mematikannya dalam Tetapan.';

  @override
  String get addToNoteTitle => 'Tambah ke nota';

  @override
  String get addToNewNote => 'Nota baharu';

  @override
  String get addToNoteEmpty => 'Belum ada nota lain';

  @override
  String get calendarLinkExistingNote => 'Pautkan nota sedia ada';

  @override
  String get routineFromNote => 'Cipta rutin daripada nota';

  @override
  String get quickRowSubheading => 'Subtajuk';

  @override
  String get quickRowItalic => 'Condong';

  @override
  String get quickRowUnderline => 'Garis bawah';

  @override
  String get quickRowHighlight => 'Serlah';

  @override
  String get quickRowSpellOn =>
      'Pembetulan ejaan: hidup (setiap perkataan dibetulkan secara automatik)';

  @override
  String get quickRowSpellOff => 'Pembetulan ejaan: mati';

  @override
  String get quickRowPackage => 'Bungkus';

  @override
  String get notePackageHint => 'Teks panjang — bungkus untuk kemaskan';

  @override
  String get quickRowDictation => 'Imlak';

  @override
  String get notePackageSelectFirst =>
      'Pilih teks untuk dibungkus (atau ketik perenggan panjang)';

  @override
  String notePackageCount(int count) {
    return '$count item';
  }

  @override
  String get notePackageUnpack => 'Buka bungkusan (kembalikan ke nota)';

  @override
  String get pinnedPenWrite => 'Tulis di atasnya dengan pen';

  @override
  String get pinnedShrinkToFit => 'Kecilkan apabila disempitkan';

  @override
  String get quickRowCamera => 'Ambil foto';

  @override
  String get quickRowScan => 'Imbas dokumen';

  @override
  String get quickRowDate => 'Sisipkan tarikh dan masa';

  @override
  String get spellAutoTitle => 'Autobetul';

  @override
  String get spellLearnTitle => 'Pembetulan yang belajar';

  @override
  String get spellCheckDoneTitle => 'Semak item yang ditanda juga';

  @override
  String get spellCheckDoneSubtitle =>
      'Jika dimatikan, item yang ditanda tidak digariskan';

  @override
  String get spellManualHint => 'Taip perkataan yang betul';

  @override
  String get spellManualFix => 'Betulkan secara manual';

  @override
  String get spellLearnSubtitle =>
      'Mempelajari perkataan yang anda betulkan sendiri atau pilih daripada cadangan papan kekunci. Kamus peribadi anda disegerakkan dengan akaun anda.';

  @override
  String spellLearnedCount(int count) {
    return '$count pembetulan dipelajari';
  }

  @override
  String get spellForget => 'Lupakan yang dipelajari';

  @override
  String get spellForgotten => 'Pembetulan yang dipelajari dibuang';

  @override
  String get spellModeTitle => 'Semakan ejaan';

  @override
  String get spellModeInfo =>
      'Tunjuk sahaja: kesilapan digariskan. Automatik: membetulkan apabila pasti.';

  @override
  String get spellModeOff => 'Mati';

  @override
  String get spellModeShow => 'Tunjuk sahaja';

  @override
  String get spellModeAuto => 'Automatik';

  @override
  String get spellAddToDictionary => 'Tambah ke kamus';

  @override
  String spellAlwaysFix(String word) {
    return 'Sentiasa betulkan: $word';
  }

  @override
  String get spellKeepInNote => 'Abaikan dalam nota ini';

  @override
  String get spellReviewAction => 'Semak ejaan';

  @override
  String get spellReviewNoteOption => 'Semak nota ini';

  @override
  String get spellReviewClean => 'Tiada masalah ejaan ditemui';

  @override
  String get spellReviewCleanHint =>
      'Semua perkataan dalam nota ini kelihatan baik.';

  @override
  String spellReviewFixAll(int count) {
    return 'Betulkan semua ($count)';
  }

  @override
  String spellReviewApply(int count) {
    return 'Gunakan ($count)';
  }

  @override
  String get spellReviewSkip => 'Langkau';

  @override
  String get spellReviewHintBadge => 'Petunjuk konteks';

  @override
  String spellReviewFixed(int count) {
    return '$count pembetulan ejaan digunakan';
  }

  @override
  String get lineTaskRetime => 'Tukar masa';

  @override
  String get lineTaskDone => 'Selesai';

  @override
  String get lineTaskUndone => 'Tanda belum selesai';

  @override
  String get lineTaskDetails => 'Butiran (tahap, ulang, kenalan)';

  @override
  String get lineTaskDelete => 'Padam peringatan';

  @override
  String get inkShapeTriangle => 'Segi tiga';

  @override
  String get inkShapeTable => 'Jadual';

  @override
  String get homeFolderStripShort => 'Baris folder';

  @override
  String get homeCalendarStripShort => 'Jalur kalendar';

  @override
  String get homeCalendarStrip => 'Jalur kalendar di atas';

  @override
  String get homeCalendarStripInfo =>
      'Kalendar dengan acara, tugasan dan cuti di bahagian atas laman utama.';

  @override
  String get homeCalendarStripExpand => 'Kembangkan jalur kalendar';

  @override
  String get homeCalendarStripCollapse => 'Kuncupkan jalur kalendar';

  @override
  String get folderMenuEdit => 'Susun semula · padam';

  @override
  String get themeClassic => 'Klasik';

  @override
  String get themeNewsprint => 'Kertas akhbar';

  @override
  String get themeNotebook => 'Buku nota';

  @override
  String get themeGraphite => 'Grafit';

  @override
  String get themeLedger => 'Lejar';

  @override
  String get themeGroupCalm => 'Tenang';

  @override
  String get themeGroupPaper => 'Kertas';

  @override
  String get themeGroupVivid => 'Terang';

  @override
  String get spellLearnedTitle => 'Ejaan yang dipelajari';

  @override
  String get spellLearnedInfo =>
      'Perkataan yang anda taip kemudian betulkan sendiri, atau pilih daripada cadangan papan kekunci. Anda boleh tambah sendiri: salah → betul (digunakan serta-merta).';

  @override
  String get spellLearnedSettingInfo =>
      'Lihat pembetulan yang dipelajari, tambah atau padam';

  @override
  String get spellLearnedWrong => 'Salah';

  @override
  String get spellLearnedRight => 'Betul';

  @override
  String get spellLearnedAdd => 'Tambah';

  @override
  String get spellLearnedEmpty => 'Belum ada pembetulan yang dipelajari.';

  @override
  String spellLearnedSeen(int count) {
    return '$count kali';
  }

  @override
  String get spellLearnedKept =>
      'Perkataan yang dibiarkan (anda membuat asal pembetulan)';

  @override
  String get spellRulesOnlyTitle => 'Peraturan sahaja';

  @override
  String get spellRulesOnlySubtitle =>
      'Hanya salah ejaan yang diketahui dan pembetulan yang anda ajar dibetulkan; tiada tekaan.';

  @override
  String get spellRejectedTitle =>
      'Pembetulan yang tidak akan dibuat lagi (anda membuat asal atau mengubahnya)';

  @override
  String get inkEraserOffer => 'Pilih pemadam';

  @override
  String get inkPenOffer => 'Kembali ke pen';

  @override
  String get tipPenShapeHold =>
      'Tahan tanpa bergerak di hujung lakaran: garisan, segi empat dan bulatan menjadi bentuk kemas.';

  @override
  String get tipPenEraserHold =>
      'Untuk memadam, tekan lama lakaran → ketik butang pemadam. Dua jari = tatal/zum.';

  @override
  String backupStatusCloud(int count) {
    return 'Awan: $count nota dalam akaun Google anda, perubahan disegerakkan secara automatik';
  }

  @override
  String get backupStatusGuest =>
      'Tiada sandaran awan: nota hanya pada peranti ini. Pautkan akaun Google atau buat sandaran penuh.';

  @override
  String backupStatusLast(String date, int count) {
    return 'Sandaran penuh terakhir: $date · $count nota';
  }

  @override
  String get backupStatusNever =>
      'Belum ada sandaran penuh dibuat pada peranti ini';

  @override
  String get attachmentAddText => 'Tulis di atasnya';

  @override
  String get stylusTogglesOn => 'Pen menulis';

  @override
  String get stylusTogglesOff => 'Pen mengetik (tidak menulis)';

  @override
  String updateBanner(String version) {
    return 'Versi baharu tersedia: v$version — ketik untuk muat turun dan pasang';
  }

  @override
  String updateBannerReady(String version) {
    return 'v$version dimuat turun — ketik untuk pasang sekarang';
  }

  @override
  String updateBannerDownloading(String version, int percent) {
    return 'Memuat turun v$version… $percent%';
  }

  @override
  String updateReadyToInstall(String version) {
    return 'v$version dimuat turun; ia akan dipasang apabila aplikasi dibuka seterusnya';
  }

  @override
  String get updateInstallNow => 'Pasang sekarang';

  @override
  String get updateDownloadFailed =>
      'Tidak dapat memuat turun versi baharu — semak sambungan dan ketik lagi';

  @override
  String get updateInstallFailed => 'Pemasangan tidak selesai — cuba lagi';

  @override
  String get autoUpdateTitle => 'Kemas kini secara automatik';

  @override
  String get autoUpdateInfo =>
      'Versi baharu dimuat turun di latar belakang dan dipasang apabila aplikasi dibuka seterusnya';

  @override
  String get updateInstall => 'Kemas kini';

  @override
  String get updateNeedsPermission =>
      'Benarkan aplikasi ini memasang aplikasi tidak diketahui, kemudian ketik Kemas kini lagi';

  @override
  String get updateTapToCheck => 'Ketik untuk menyemak kemas kini';

  @override
  String get updateReopenOn => 'Dibuka semula sendiri selepas kemas kini';

  @override
  String get updateReopenOff => 'Buka semula selepas kemas kini: benarkan';

  @override
  String get updateChecking => 'Menyemak kemas kini…';

  @override
  String get updateUpToDate => 'Anda menggunakan versi terkini';

  @override
  String get releaseNotesTitle => 'Nota keluaran';

  @override
  String get settingsWritingTitle => 'Pen, penulisan dan skrin';

  @override
  String get settingsWritingSummary =>
      'Pen · Pembetulan ejaan · Jalur laman utama';

  @override
  String get settingsPenSection => 'Pen';

  @override
  String get settingsSpellSection => 'Pembetulan ejaan';

  @override
  String get settingsScreenSection => 'Laman utama dan skrin nota';

  @override
  String get settingsShowAllNotes => 'Nota dalam folder juga di laman utama';

  @override
  String get settingsShowAllNotesInfo =>
      'Nota dalam folder juga dipaparkan di laman utama (kecuali arkib dan tersembunyi).';

  @override
  String get settingsAttachmentsExpanded => 'Jalur lampiran terbuka dalam nota';

  @override
  String get settingsListPaneCollapsed =>
      'Sembunyikan senarai nota pada skrin lebar (fokus)';

  @override
  String get settingsListPaneCollapsedInfo =>
      'Pada tablet dan web senarai bermula tertutup semasa nota dibuka.';

  @override
  String get pinnedSideToggle => 'Kedudukan: atas / kiri / kanan';

  @override
  String get pinnedSideTitle => 'Kedudukan anak tetingkap';

  @override
  String get pinnedSideTop => 'Atas';

  @override
  String get pinnedSideLeft => 'Kiri';

  @override
  String get pinnedSideRight => 'Kanan';

  @override
  String releaseNotesToastTitle(String version) {
    return 'Apa yang baharu · v$version';
  }

  @override
  String releaseNotesToastMore(int count) {
    return '+$count lagi';
  }

  @override
  String get releaseNotesToastAll => 'Lihat semua';

  @override
  String get updateInstalling =>
      'Dimuat turun — sedang memasang; aplikasi akan ditutup dan dibuka semula';

  @override
  String get updateAborted => 'Pemasangan dibatalkan — ketik untuk cuba lagi';

  @override
  String get updateOpenedBrowser => 'Halaman muat turun dibuka dalam pelayar';

  @override
  String cardHiddenYoutube(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count video YouTube',
      one: 'Video YouTube',
    );
    return '$_temp0';
  }

  @override
  String cardHiddenVideo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count video',
      one: 'Video',
    );
    return '$_temp0';
  }

  @override
  String cardHiddenImage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count imej',
      one: 'Imej',
    );
    return '$_temp0';
  }

  @override
  String cardHiddenDoc(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dokumen',
      one: 'PDF',
    );
    return '$_temp0';
  }

  @override
  String cardHiddenAudio(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rakaman suara',
      one: 'Rakaman suara',
    );
    return '$_temp0';
  }

  @override
  String get quickAddKeepOne =>
      'Sekurang-kurangnya satu pilihan mesti kekal kelihatan';

  @override
  String get attachmentUploadNow => 'Cuba sekarang';

  @override
  String uploadPendingTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lampiran menunggu dimuat naik',
      one: '1 lampiran menunggu dimuat naik',
    );
    return '$_temp0';
  }

  @override
  String get uploadPendingBody =>
      'Ia dimuat naik apabila anda membuka aplikasi.';

  @override
  String get uploadPendingChannel => 'Muat naik lampiran tertunda';

  @override
  String placementHintShort(String view) {
    return 'Ditambah sebagai $view · ketik suis untuk mengubah';
  }

  @override
  String get listPaneRight => 'Senarai nota di kanan';

  @override
  String get listPaneRightInfo =>
      'Dalam paparan terpisah (tablet, tetingkap lebar) senarai berada di kanan nota';

  @override
  String get listPaneMoveRight => 'Alih senarai ke kanan';

  @override
  String get noteOpenSide => 'Buka bersebelahan';

  @override
  String get micBusySideNote => 'Mikrofon sedang digunakan dalam nota lain';

  @override
  String get noteCloseSide => 'Tutup nota sisi';

  @override
  String get listPaneMoveLeft => 'Alih senarai ke kiri';

  @override
  String get quickRowEditTitle => 'Menu pantas (atas, semasa menaip)';

  @override
  String get quickRowEditInfo =>
      'Ketik untuk menambah atau membuang daripada menu. Perubahan digunakan serta-merta, tidak perlu disimpan.';

  @override
  String get quickRowEditShown => 'Dalam menu';

  @override
  String get quickRowEditAvailable => 'Tersedia';

  @override
  String get quickRowEditEmpty => 'Menu kosong — tambah butang di bawah';

  @override
  String get quickRowEditReset => 'Set semula ke lalai';

  @override
  String get quickRowShortPen => 'Pen';

  @override
  String get quickRowShortSpell => 'Semakan ejaan';

  @override
  String get quickRowShortColor => 'Warna teks';

  @override
  String get quickRowShortHeading => 'Tajuk';

  @override
  String get quickEntryHint => 'Taip atau sebut: pisang epal, 2 susu…';

  @override
  String get quickEntryListening => 'Sedang mendengar…';

  @override
  String get quickEntryMic => 'Tambah dengan suara';

  @override
  String get quickEntryMicStop => 'Hentikan mendengar';

  @override
  String get quickListEmpty =>
      'Taip di atas, bercakap atau ketik di bawah; senarai anda terbina di sini.';

  @override
  String get smartListHint =>
      'Taip atau sebut susu, roti…; untuk barang bawaan, sebut “senarai barang bawaan”.';

  @override
  String get quickListDone => 'Selesai';

  @override
  String get quickListAisleSort => 'Isih mengikut lorong';

  @override
  String get quickListOpenInNote => 'Buka sebagai nota';

  @override
  String get quickListDiscard => 'Buang';

  @override
  String get quickListFrequent => 'Kebiasaan anda';

  @override
  String get quickListLeftovers => 'Dari kali lepas';

  @override
  String get quickListAddAll => 'Tambah semua';

  @override
  String quickListSaved(String title) {
    return '“$title” disimpan';
  }

  @override
  String get quickListOpen => 'Buka';

  @override
  String get quickListRemove => 'Buang';

  @override
  String quickListCorrected(String typed) {
    return 'Anda menaip “$typed”; ketik untuk buat asal';
  }

  @override
  String quickListRestored(String typed) {
    return 'Dikekalkan sebagai “$typed”; ia tidak akan dibetulkan lagi';
  }

  @override
  String get quickDropTitle => 'Tambah pantas';

  @override
  String get quickDropInfo =>
      'Taip atau bercakap; ia masuk ke nota yang anda pilih';

  @override
  String get quickDropHint =>
      'susu, roti… atau “tambah susu ke senarai beli-belah”';

  @override
  String get quickDropTarget => 'Tambah ke nota mana?';

  @override
  String get quickDropNoNotesNew =>
      'Belum ada senarai atau nota teks untuk ditambah: apa yang anda tulis disimpan sebagai nota baharu.';

  @override
  String get quickDropSavingNew => 'Menyimpan sebagai nota baharu…';

  @override
  String get quickDropSavedNew => 'Disimpan sebagai nota baharu';

  @override
  String get quickDropAdd => 'Tambah';

  @override
  String quickDropAdded(int count, String title) {
    return '$count item ditambah ke “$title”';
  }

  @override
  String quickDropAddedText(String title) {
    return 'Ditambah ke “$title”';
  }

  @override
  String quickDropNothingNew(String title) {
    return 'Semuanya sudah ada dalam “$title”';
  }

  @override
  String get quickDropKeyboard => 'Papan kekunci semasa dibuka';

  @override
  String get quickDropMicAuto => 'Dengar semasa dibuka';

  @override
  String get noteExpiry => 'Arkibkan pada…';

  @override
  String get noteExpiryDay => '1 hari';

  @override
  String get noteExpiry3Days => '3 hari';

  @override
  String get noteExpiryWeek => '1 minggu';

  @override
  String get noteExpiryMonth => '1 bulan';

  @override
  String get noteExpiryPick => 'Pilih tarikh & masa';

  @override
  String get noteExpiryRemove => 'Buang pemasa';

  @override
  String noteExpiryChip(String date) {
    return 'Diarkibkan $date';
  }

  @override
  String noteExpiryLeftDays(int n) {
    return '${n}h';
  }

  @override
  String noteExpiryLeftHours(int n) {
    return '${n}j';
  }

  @override
  String noteExpiryLeftMinutes(int n) {
    return '${n}m';
  }

  @override
  String get smartList => 'Senarai pintar';

  @override
  String get smartListInfo =>
      'Taip atau bercakap; ia mengenal pasti beli-belah atau barang bawaan dan mengumpulkan item';

  @override
  String get smartListGeneric => 'Senarai';

  @override
  String get smartListPacking => 'Senarai barang bawaan';

  @override
  String get smartListPharmacy => 'Senarai farmasi';

  @override
  String get smartListStationery => 'Senarai alat tulis';

  @override
  String get smartListHardware => 'Senarai perkakasan';

  @override
  String get smartListCamping => 'Senarai perkhemahan';

  @override
  String get smartListBaby => 'Beg bayi';

  @override
  String get smartListSport => 'Beg gim';

  @override
  String get sortByGroup => 'Mengikut lorong / kumpulan';

  @override
  String get finishShopping => 'Selesai membeli-belah';

  @override
  String finishShoppingDone(int count) {
    return '$count item ditanda dikosongkan';
  }

  @override
  String get scanAny => 'Imbas';

  @override
  String get scanAnyInfo =>
      'Dokumen atau kod QR — kod QR dikesan secara automatik';

  @override
  String get scanAnyHint =>
      'Kod QR dikesan secara automatik. Untuk dokumen, ketik “Imbas dokumen”.';

  @override
  String get scanQrFound => 'Kod QR ditemui';

  @override
  String get scanUseQr => 'Guna kod QR';

  @override
  String get listToNumbered => 'Jadikan bernombor';

  @override
  String get listToChecklist => 'Jadikan senarai semak';

  @override
  String get quickDropWhich => 'Ini masuk ke nota mana?';

  @override
  String get quickDropAsking => 'Menentukan nota…';

  @override
  String quickDropAddingTo(String title) {
    return 'Menambah ke “$title”…';
  }

  @override
  String get quickDropWait => 'Tunggu';

  @override
  String get quickDropAiToggle => 'Tanya AI apabila tidak pasti';

  @override
  String get aiOffTitle => 'AI dimatikan';

  @override
  String get aiConsentTitle => 'Menggunakan AI';

  @override
  String get aiConsentWhat =>
      'Apa yang dihantar: hanya teks, nota atau lampiran (imej, audio, PDF) yang anda pilih untuk tugasan itu.';

  @override
  String get aiConsentWhere =>
      'Ke mana: ke perkhidmatan Gemini Google (melalui Firebase); jika anda memasukkan kunci sendiri, ke penyedia yang anda pilih.';

  @override
  String get aiConsentMistakes =>
      'AI boleh tersilap; semak sendiri maklumat penting.';

  @override
  String get aiConsentTurnOff =>
      'Anda boleh mematikan AI sepenuhnya bila-bila masa dalam Tetapan → AI.';

  @override
  String get aiConsentAccept => 'Saya bersetuju';

  @override
  String get aiConsentDecline => 'Bukan sekarang';

  @override
  String get aiPausedTitle => 'AI tidak tersedia buat sementara';

  @override
  String get homePullGestureTitle =>
      'Menarik ke bawah di bahagian atas senarai';

  @override
  String get homeSwipeRightGestureTitle => 'Leret ke kanan dalam Semua';

  @override
  String get homeGestureInfo =>
      'Pilih nota atau folder dan gerak isyarat terus membukanya';

  @override
  String get homeGestureFolders => 'Folder';

  @override
  String get homeGestureNote => 'Sebuah nota';

  @override
  String get homeGestureFolder => 'Sebuah folder';

  @override
  String get homeGestureNone => 'Tiada';

  @override
  String get homeGestureMissing =>
      'Sasaran gerak isyarat tidak ditemui; pilih semula dalam Tetapan → Nota';

  @override
  String get calendarExpiryTag => 'Diarkibkan';

  @override
  String get calendarExpiryRemoved => 'Masa arkib dibuang';

  @override
  String get inkFingerAuto => 'Automatik';

  @override
  String get inkFingerAutoNowScroll =>
      'Automatik: pen telah dikesan pada peranti ini, jadi jari menatal.';

  @override
  String get inkFingerAutoNowDraw =>
      'Automatik: belum ada pen dikesan, jadi jari melukis; ia bertukar ke menatal kali pertama pen menyentuh.';

  @override
  String get barMoreLeftGroup => 'Kumpulan kiri';

  @override
  String get barMoreRightGroup => 'Kumpulan kanan (berwarna)';

  @override
  String get barMoreToRight => 'Alih ke kumpulan kanan';

  @override
  String get barMoreToLeft => 'Alih ke kumpulan kiri';

  @override
  String get layoutScopeAll => 'Gunakan pada semua';

  @override
  String get layoutScopeNote => 'Nota ini sahaja';

  @override
  String get layoutScopeInfoAll => 'Perubahan digunakan pada setiap nota.';

  @override
  String get layoutScopeInfoNote =>
      'Nota ini mempunyai susun atur sendiri; perubahan digunakan di sini sahaja.';

  @override
  String get layoutScopeReset => 'Set semula susun atur nota ini';

  @override
  String quickRowEditNotHere(String names) {
    return 'Tidak dipaparkan dalam nota ini: $names';
  }

  @override
  String get barMoreEdit => 'Sunting bar bawah';

  @override
  String get barMoreEditHint =>
      'Butang disemat (📌) kekal pada bar (3 pertama muat pada telefon); selebihnya dalam menu ini. Tekan lama dan seret untuk menyusun semula.';

  @override
  String get barMoreToBar => 'Alih ke bar';

  @override
  String get barMoreToMenu => 'Alih ke menu';

  @override
  String menuEditInlineHint(int count) {
    return 'Tekan lama dan seret untuk menyusun semula · ⊖ sembunyikan · ☆ baris pantas (hingga $count)';
  }

  @override
  String get menuHiddenGroup => 'Tersembunyi';

  @override
  String get quickDropSettings => 'Tetapan tambah pantas';

  @override
  String quickDropPreviewText(String title, String text) {
    return '→ $title · $text';
  }

  @override
  String quickDropPreviewItems(String title, String items, int count) {
    return '→ $title · $items ($count baharu)';
  }

  @override
  String get quickDropPickMyself => 'Saya pilih sendiri';

  @override
  String get quickDropFindNote => 'Cari nota';

  @override
  String quickDropPreviewReminder(String when, String text) {
    return '⏰ $when · $text';
  }

  @override
  String get quickDropSavedReminder =>
      'Disimpan sebagai nota dengan peringatan';

  @override
  String quickDropPreviewCalendar(String day, String text) {
    return '📅 $day · $text';
  }

  @override
  String quickDropSavedCalendar(String day) {
    return 'Nota ditambah ke kalendar · $day';
  }

  @override
  String quickDropPreviewMulti(String summary, int count) {
    return '→ $summary ($count nota)';
  }

  @override
  String quickDropAddedMulti(int count) {
    return 'Ditambah ke $count nota';
  }

  @override
  String get aiNeedsProTitle => 'AI ialah sebahagian daripada Pro';

  @override
  String get proTitle => 'Versi Penuh';

  @override
  String get proSettingsSubtitle =>
      'Lite lwn Versi Penuh, kredit keputusan, pembelian';

  @override
  String get proStatusFree => 'Pelan anda: Lite (Percuma · Tanpa iklan)';

  @override
  String get proStatusLifetime => 'Pelan anda: Versi Penuh (Seumur hidup)';

  @override
  String get proTiersTitle => 'Pelan';

  @override
  String get proTierFree => 'Lite';

  @override
  String get proTierLifetime => 'Versi Penuh';

  @override
  String get proRowBasics =>
      'Nota, senarai, pen, PDF, peringatan, kalendar; semakan ejaan, imlak, OCR, kod bar pada peranti, Mod Kedai';

  @override
  String get proRowUnlimited => 'Nota, folder, lampiran dan peranti tanpa had';

  @override
  String get proRowSync => 'Penyegerakan awan';

  @override
  String get proSyncPeriodic => 'Berkala (5 min)';

  @override
  String get proSyncInstant => 'Segera';

  @override
  String get proRowAttachments => 'Lampiran disimpan dalam';

  @override
  String get proAttachDrive => 'Drive anda';

  @override
  String get proAttachCloud => 'Drive + Dikongsi';

  @override
  String get proRowHistory =>
      'Sejarah 30 versi, sandaran dilindungi kata laluan';

  @override
  String get proRowLooks => 'Semua tema, 19 fon, gaya kertas';

  @override
  String get proRowAi => 'Keputusan Pintar (lorong, penghalaan, tag)';

  @override
  String get proDecisionsIncluded => '750 panggilan';

  @override
  String get proRowOwnKey => 'Kunci Gemini anda sendiri';

  @override
  String get proLockedBadge => 'Dalam Versi Penuh';

  @override
  String get proBuyTitle => 'Beli';

  @override
  String get proPlanLifetime => 'Versi Penuh · Sekali bayar (Seumur hidup)';

  @override
  String get proPlanDecisionPack => 'Pakej +1,000 Keputusan Pintar';

  @override
  String proPriceOnce(String price) {
    return '$price · bayar sekali, tanpa langganan';
  }

  @override
  String get proBuy => 'Beli';

  @override
  String get proOwned => 'Dimiliki';

  @override
  String get proRestore => 'Pulihkan pembelian';

  @override
  String get proTerms =>
      'Tiada langganan, tiada iklan. Versi Penuh ialah pembelian sekali seumur hidup termasuk 750 Keputusan Pintar. Apabila kredit habis, aplikasi dan semua ciri pada peranti terus berfungsi tanpa had; anda boleh menambah Pakej +1,000 Keputusan atau menggunakan kunci Gemini sendiri.';

  @override
  String get proLoading => 'Mendapatkan harga daripada Google Play…';

  @override
  String get proUnavailable => 'Tidak dapat mencapai Google Play.';

  @override
  String get proElsewhere =>
      'Pembelian dibuat pada telefon anda: dalam aplikasi Android, Tetapan → Versi Penuh. Apa yang anda beli turut dibuka di sini pada akaun ini.';

  @override
  String get proGuest =>
      'Log masuk dengan Google untuk membeli: akaun tetamu hanya wujud pada peranti ini, jadi pembelian boleh hilang bersamanya.';

  @override
  String get proNoticePending =>
      'Pembayaran tertunda; pelan anda dibuka secara automatik setelah disahkan.';

  @override
  String get proNoticeCanceled => 'Pembelian dibatalkan.';

  @override
  String get proNoticeFailed =>
      'Pembelian tidak dapat diselesaikan. Cuba lagi sebentar nanti.';

  @override
  String get proNoticeVerifyFailed =>
      'Tidak dapat mengesahkan pembelian; aplikasi mencuba semula apabila dibuka seterusnya. Google Play memulangkan bayaran yang tidak disahkan.';

  @override
  String get proNoticeOtherAccount =>
      'Pembelian ini milik akaun lain. Log masuk dengan akaun itu untuk menggunakannya.';

  @override
  String get proNoticeDone => 'Terima kasih! Pelan anda telah dibuka.';

  @override
  String get proNoticeRestored => 'Pembelian anda dipulihkan.';

  @override
  String get proNoticeNothing =>
      'Tiada pembelian untuk dipulihkan dalam akaun Google Play ini.';

  @override
  String get proIncluded => 'Termasuk';

  @override
  String get proNotIncluded => 'Tidak termasuk';

  @override
  String get decisionsSectionTitle => 'Keputusan Pintar';

  @override
  String get decisionsSectionSubtitle =>
      'Lorong runcit tidak diketahui, sasaran tambah pantas dan cadangan tag';

  @override
  String get decisionsQuotaByok =>
      'Kunci Gemini sendiri aktif · Keputusan pintar tanpa had';

  @override
  String decisionsQuotaSummary(int calls, String tokens) {
    return 'Baki keputusan pintar: $calls · bajet $tokens token';
  }

  @override
  String get decisionsQuotaFreeHint =>
      'Peraturan pintar pada peranti adalah percuma · 750 keputusan termasuk dalam Versi Penuh';

  @override
  String get decisionsTurnOffTitle => 'Matikan keputusan pintar';

  @override
  String get decisionsTurnOffBody =>
      'Jika dimatikan, semua kamus pada peranti, semakan ejaan dan peraturan beli-belah terus berfungsi secara percuma.';

  @override
  String get decisionsByokTitle => 'Kunci Gemini API sendiri (Lanjutan)';

  @override
  String get decisionsByokInfo =>
      'Apabila keputusan habis, teruskan dengan kunci Gemini anda; ia kekal pada peranti ini.';

  @override
  String get calendarDayLinkRemoved => 'Nota dibuang dari hari ini';

  @override
  String get calendarLinkTime => 'Masa';

  @override
  String get calendarLinkAllDay => 'Sepanjang hari';

  @override
  String get driveOnboardTitle => 'Simpan lampiran pada setiap peranti';

  @override
  String get driveOnboardBody =>
      'Lampiran foto, PDF dan audio anda disandarkan ke folder \"Notlar\" dalam Google Drive, jadi anda melihat lampiran yang sama pada telefon, tablet dan web.';

  @override
  String get driveOnboardConnect => 'Sambung Drive';

  @override
  String get driveOnboardLater => 'Kemudian';

  @override
  String get exportMarkdownZip => 'Eksport Markdown (.zip)';

  @override
  String get exportMarkdownZipInfo =>
      'Mengeksport nota sebagai fail .md mudah alih mengikut folder';

  @override
  String get exportMarkdownZipEmpty => 'Tiada nota untuk dieksport';

  @override
  String exportMarkdownZipDone(int count) {
    return '$count nota dieksport sebagai Markdown (.zip)';
  }

  @override
  String get storeMode => 'Mod kedai';

  @override
  String get storeModeHideChecked => 'Sembunyikan yang ditanda';

  @override
  String get storeModeShowChecked => 'Tunjukkan yang ditanda';

  @override
  String storeModeRemaining(int remaining, int total) {
    return 'Baki $remaining daripada $total';
  }

  @override
  String get storeModeAllDone => 'Semua selesai!';

  @override
  String get storeModeAddHint => 'Tambah item dengan pantas…';

  @override
  String get backupPasswordTitle => 'Kata laluan sandaran (pilihan)';

  @override
  String get backupPasswordInfo =>
      'Menetapkan kata laluan melindungi sandaran dengan penyulitan kukuh. Kata laluan yang terlupa tidak boleh dipulihkan.';

  @override
  String get backupPasswordHint => 'Kata laluan';

  @override
  String get backupPasswordConfirmHint => 'Sahkan kata laluan';

  @override
  String get backupPasswordMismatch => 'Kata laluan tidak sepadan';

  @override
  String get backupWithoutPassword => 'Sandarkan tanpa kata laluan';

  @override
  String get backupWithPassword => 'Sulitkan & sandarkan';

  @override
  String get backupPasswordProLocked =>
      'Sandaran dilindungi kata laluan ada dalam pelan Seumur hidup dan Pro. Sandaran tanpa kata laluan adalah percuma; memulihkan sandaran disulitkan sentiasa percuma.';

  @override
  String get backupSeeTiers => 'Lihat pelan';

  @override
  String get backupEnterPasswordTitle => 'Sandaran disulitkan';

  @override
  String get backupEnterPasswordBody =>
      'Sandaran ini dilindungi kata laluan. Masukkan kata laluan untuk memulihkan.';

  @override
  String get backupWrongPassword =>
      'Kata laluan salah atau sandaran tidak dapat dinyahsulit';

  @override
  String get calendarAddActionTitle =>
      'Apa yang ditambah oleh + dalam kalendar';

  @override
  String get calendarAddActionInfo =>
      'Ditambah ke hari yang dipilih (atau hari ini); anda boleh mengubahnya dalam dialog.';

  @override
  String get calendarAddNote => 'Nota';

  @override
  String get calendarAddEvent => 'Acara';

  @override
  String get calendarAddTask => 'Tugasan';

  @override
  String get calendarFullPage => 'Kalendar halaman penuh';

  @override
  String get calendarNewDayNoteTitle => 'Nota baharu';

  @override
  String get calendarNewDayNoteOpen => 'Tulis nota';

  @override
  String calendarSlotAddTitle(String time) {
    return 'Tambah pada $time';
  }

  @override
  String get eraserOn => 'Pemadam aktif';

  @override
  String get calendarRelToday => 'Hari ini';

  @override
  String get calendarRelTomorrow => 'Esok';

  @override
  String get calendarRelYesterday => 'Semalam';

  @override
  String calendarRelInDays(int count) {
    return 'dalam $count hari';
  }

  @override
  String calendarRelDaysAgo(int count) {
    return '$count hari lalu';
  }

  @override
  String calendarWeekNumber(int count) {
    return 'minggu $count';
  }

  @override
  String calendarDayEvents(int count) {
    return '$count acara';
  }

  @override
  String calendarDayTasks(int count) {
    return '$count tugasan';
  }

  @override
  String calendarDayReminders(int count) {
    return '$count peringatan';
  }

  @override
  String calendarDayNotesCount(int count) {
    return '$count nota';
  }

  @override
  String get calendarDayFree => 'Hari lapang';

  @override
  String get webWorkspaceSection => 'Ruang kerja';

  @override
  String get webOrganizeSection => 'Susun';

  @override
  String get webViewGrid => 'Paparan grid';

  @override
  String get webViewList => 'Paparan senarai';

  @override
  String get webColumnsMenu => 'Ketumpatan lajur';

  @override
  String get webColumnsAuto => 'Automatik';

  @override
  String webColumnsCount(int count) {
    return '$count lajur';
  }

  @override
  String webNoteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nota',
      one: '1 nota',
    );
    return '$_temp0';
  }

  @override
  String get webDriveStatusConnected => 'Drive disambung';

  @override
  String webDriveStatusSyncing(int count) {
    return '$count sedang disegerakkan';
  }

  @override
  String webDriveStatusAttention(int count) {
    return '$count tertunda';
  }

  @override
  String get webSyncCloudReady => 'Penyegerakan awan aktif';

  @override
  String get webCacheTitle => 'Cache lampiran pelayar';

  @override
  String webCacheInfo(int count, String size) {
    return '$count fail · $size (sedia luar talian)';
  }

  @override
  String get webCacheEmpty => 'Belum ada lampiran dalam cache';

  @override
  String get webCacheClear => 'Kosongkan';

  @override
  String get webCacheCleared => 'Cache lampiran pelayar dikosongkan';

  @override
  String get quickRowMoreEdit => 'Sunting menu pantas';

  @override
  String get quickRowDay => 'Sisipkan tarikh hari ini';

  @override
  String get tableInsert => 'Jadual';

  @override
  String get tableInsertInfo => '3 baris · 2 lajur, ubah kemudian';

  @override
  String get tableName => 'Jadual';

  @override
  String get tableAddRow => 'Tambah baris';

  @override
  String get tableAddRowBelow => 'Tambah baris di bawah';

  @override
  String get tableDeleteRow => 'Padam baris';

  @override
  String get tableColumnCount => 'Lajur';

  @override
  String get tableHeaderRow => 'Baris pertama sebagai pengepala';

  @override
  String get tableEqualWidths => 'Lebar lajur sama';

  @override
  String get tableDelete => 'Padam jadual';

  @override
  String get tableOptions => 'Tetapan jadual';

  @override
  String get tableColumnsWillDrop =>
      'Teks dalam lajur terakhir akan dipadam. Teruskan?';

  @override
  String get tableMoveHint =>
      'Tekan lama untuk mengalih, seret sudut untuk mengubah saiz';

  @override
  String get tableRowCount => 'Baris';

  @override
  String get tableRowsWillDrop =>
      'Teks dalam baris terakhir akan dipadam. Teruskan?';

  @override
  String get tableEditSection => 'Sunting';

  @override
  String get tableShareImage => 'Imej';

  @override
  String get tableSharePdf => 'PDF';

  @override
  String get tableShareWord => 'Word';

  @override
  String get tableShareFailed => 'Tidak dapat berkongsi jadual';

  @override
  String get tableAddRowAbove => 'Tambah baris di atas';

  @override
  String get tableInsertColumn => 'Tambah lajur di kanan';

  @override
  String get tableDeleteColumn => 'Padam lajur';

  @override
  String get tableColumnsOneWillDrop =>
      'Teks dalam lajur dipilih akan dipadam. Teruskan?';

  @override
  String get tableSortAsc => 'Isih A→Z';

  @override
  String get tableSortDesc => 'Isih Z→A';

  @override
  String get tableStripedRows => 'Baris berjalur';

  @override
  String get tableDataSection => 'Data';

  @override
  String get tableCopyMarkdown => 'Salin Markdown';

  @override
  String get tableCopyCsv => 'Salin CSV';

  @override
  String get tablePasteData => 'Tampal CSV / TSV';

  @override
  String get tablePasteWillReplace =>
      'Kandungan jadual sedia ada akan diganti dengan data yang ditampal. Teruskan?';

  @override
  String get tablePasteInvalid => 'Tiada data jadual sah dalam papan keratan';

  @override
  String get tablePasted => 'Data jadual ditampal';

  @override
  String get tableSorted => 'Jadual diisih';

  @override
  String folderHeaderPinnedCount(int count) {
    return '$count disemat';
  }

  @override
  String get folderNewNote => 'Nota baharu';

  @override
  String get folderFilterSort => 'Tapis & isih';

  @override
  String get folderLivePreview => 'Pratonton';

  @override
  String get pinnedSmartActions => 'Tindakan pintar';

  @override
  String get pinnedSmartOcr => 'Ekstrak teks';

  @override
  String get pinnedSmartSummarize => 'Ringkaskan & tambah';

  @override
  String get pinnedSmartTasks => 'Jadikan tugasan';

  @override
  String get pinnedSmartAreaAsk => 'Pilih kawasan & tanya';

  @override
  String get dashboardBackgroundGallery => 'Kertas dinding pilihan';

  @override
  String get dashboardBackgroundFromDevice => 'Daripada galeri';

  @override
  String get dashboardBackgroundOpacity => 'Keterlihatan';

  @override
  String get wallpaperAuroraBloom => 'Mekar aurora';

  @override
  String get wallpaperCitrusSun => 'Mentari sitrus';

  @override
  String get wallpaperCoralLagoon => 'Lagun karang';

  @override
  String get wallpaperBotanicalGarden => 'Taman botani';

  @override
  String get wallpaperLavenderDream => 'Impian lavender';

  @override
  String get wallpaperTerracottaStudio => 'Studio terakota';

  @override
  String get wallpaperPastelConfetti => 'Konfeti pastel';

  @override
  String get wallpaperGoldenMeadow => 'Padang keemasan';

  @override
  String get wallpaperMidnightAurora => 'Aurora tengah malam';

  @override
  String get wallpaperVelvetCosmos => 'Kosmos baldu';

  @override
  String get noteThemeAurora => 'Aurora';

  @override
  String get noteThemeCitrus => 'Sitrus';

  @override
  String get noteThemeBotanical => 'Botani';

  @override
  String get noteThemeTerracotta => 'Terakota';

  @override
  String get noteThemeConfetti => 'Konfeti';

  @override
  String get noteThemeCobalt => 'Kobalt';

  @override
  String get themeActiveLabel => 'Tema aktif';

  @override
  String get themeGroupAll => 'Semua';

  @override
  String get itemRangeSelect => 'Pilih julat';

  @override
  String get itemInvertSelection => 'Songsangkan pilihan';

  @override
  String get itemMoveUp => 'Alih ke atas';

  @override
  String get itemMoveDown => 'Alih ke bawah';

  @override
  String get itemDivider => 'Pemisah';

  @override
  String get selectionToolbarMore => 'Tindakan lain';

  @override
  String get selectionMenuEdit => 'Sunting';

  @override
  String get selectionMenuEditDone => 'Selesai';

  @override
  String get selectionMenuEditHint =>
      'Ketik untuk menambah atau membuang daripada baris utama';

  @override
  String get itemsBatchFormat => 'Format pukal';

  @override
  String itemsDeletedUndo(int count) {
    return '$count item dipadam';
  }

  @override
  String itemsFormattedCount(int count) {
    return '$count item diformat';
  }

  @override
  String get ecosystemDosyalarimTitle => 'Urus setiap fail dengan Dosyalarım';

  @override
  String get ecosystemDosyalarimSubtitle =>
      'Tandatangan PDF, sunting fail Word dan Excel, dan kongsi dengan mudah bersama nota anda.';

  @override
  String get ecosystemGetApp => 'Terokai Dosyalarım';

  @override
  String get ecosystemDismiss => 'Tolak';

  @override
  String shopBudgetCart(String amount) {
    return 'Troli: RM $amount';
  }

  @override
  String shopBudgetEstimated(String amount) {
    return 'Anggaran: RM $amount';
  }

  @override
  String shopBudgetLimit(String amount) {
    return 'Bajet: RM $amount';
  }

  @override
  String get shopBudgetSet => 'Tetapkan bajet';

  @override
  String get shopBudgetHint => 'cth. 150';

  @override
  String get shopAllStores => 'Semua';

  @override
  String shopPriceTitle(String item) {
    return 'Harga & Lorong · $item';
  }

  @override
  String get shopUnitPriceLabel => 'Harga (RM)';

  @override
  String get shopStoreLabel => 'Kedai';

  @override
  String get shopAisleLabel => 'Lorong';

  @override
  String get shopPriceCompareHeader => 'Sejarah harga kedai';

  @override
  String get shopClearPrice => 'Kosongkan harga';

  @override
  String get shopRecipesTitle => 'Pakej Hidangan & Resipi';

  @override
  String get shopRecipesSearchHint => 'Cari resipi…';

  @override
  String shopServingsCount(int count) {
    return '$count hidangan';
  }

  @override
  String get shopAddToList => 'Tambah ke senarai';

  @override
  String get shopNewCustomRecipe => 'Simpan resipi tersuai';

  @override
  String get shopRecipeNameHint => 'Nama resipi';

  @override
  String get shopIngredientsHint =>
      'Bahan (dipisahkan koma: 500 g daging, 2 tomato)';

  @override
  String get shopCustomBadge => 'Tersuai';

  @override
  String shopAisleOrderTitle(String store) {
    return 'Susunan Lorong · $store';
  }

  @override
  String get shopResetOrder => 'Set semula lalai';

  @override
  String get shopReceiptTitle => 'Kemas Kini Harga daripada Resit';

  @override
  String get shopReceiptCamera => 'Ambil foto resit';

  @override
  String get shopReceiptGallery => 'Pilih resit daripada galeri';

  @override
  String shopReceiptMatched(int count) {
    return '$count item sepadan';
  }

  @override
  String get shopReceiptNoMatches =>
      'Tiada item senarai yang sepadan ditemui pada resit.';

  @override
  String get shopReceiptApply => 'Gunakan harga';

  @override
  String get shopDueHeader => 'Hampir habis';

  @override
  String shopDueEveryDays(int days) {
    return '${days}h';
  }

  @override
  String get shopStatusUnavailable => 'Kehabisan stok';

  @override
  String get shopStatusUnavailableBadge => 'Tidak tersedia';

  @override
  String get shopBarcodeTitle => 'Imbas Kod Bar';

  @override
  String shopBarcodeUnknownPrompt(String ean) {
    return 'Kod bar baharu ($ean)';
  }

  @override
  String get shopBarcodeNameHint => 'Nama produk (cth. kopi serbuk 100 g)';

  @override
  String get shopKeepScreenOn => 'Kekalkan skrin menyala';

  @override
  String get shopAtStoreButton => 'Saya di kedai';

  @override
  String shopAtStoreMessage(String name) {
    return '🛒 $name di kedai sekarang — tambah apa yang kurang!';
  }

  @override
  String get shopAtStoreSent => 'Rakan kerjasama dimaklumkan';

  @override
  String get shopScanReceiptTooltip => 'Imbas resit (OCR)';

  @override
  String get shopRecipesTooltip => 'Pakej resipi';

  @override
  String get shopAisleOrderTooltip => 'Sesuaikan susunan lorong';

  @override
  String shopTakenBy(String name) {
    return 'Diambil oleh $name';
  }

  @override
  String shopEstimatedPrefix(String amount) {
    return '~RM $amount';
  }

  @override
  String shopActualPrice(String amount) {
    return 'RM $amount';
  }

  @override
  String shopOpenStoreModeCount(int remaining) {
    return 'Mod Kedai ($remaining)';
  }

  @override
  String get shopOpenStoreMode => 'Mod Kedai';

  @override
  String get shopDictationTooltip => 'Tambah dengan suara';

  @override
  String get spellManualLearn => 'Pelajari pembetulan ini';

  @override
  String get spellManualLearnHint =>
      'Dicadangkan dan dibetulkan secara automatik pada masa akan datang.';

  @override
  String get spellNoSuggestions => 'Tiada cadangan';

  @override
  String get spellHintBadge => 'Petunjuk';

  @override
  String get spellErrorBadge => 'Ejaan';

  @override
  String get wallpaperSakuraBreeze => 'Bayu sakura';

  @override
  String get wallpaperOceanMist => 'Kabus lautan';

  @override
  String get wallpaperAutumnMaple => 'Daun musim luruh';

  @override
  String get wallpaperSageLinen => 'Linen sage';

  @override
  String get wallpaperPeachHorizon => 'Ufuk pic';

  @override
  String get wallpaperNordicPaper => 'Kertas Nordik';

  @override
  String get wallpaperStarryPine => 'Pain berbintang';

  @override
  String get wallpaperObsidianGold => 'Obsidian emas';

  @override
  String get uiProfileSectionTitle => 'Profil antara muka sedia';

  @override
  String get uiProfileSimple => 'Ringkas';

  @override
  String get uiProfileSimpleDesc =>
      'Susun atur bersih untuk nota pantas dan beli-belah';

  @override
  String get uiProfileStandard => 'Standard';

  @override
  String get uiProfileStandardDesc => 'Semua alatan seimbang';

  @override
  String get uiProfileTabletPen => 'Tablet & pen';

  @override
  String get uiProfileTabletPenDesc =>
      'Paparan terpisah, alatan pen dan PDF di hadapan';

  @override
  String uiProfileApplied(String name) {
    return 'Profil $name digunakan';
  }

  @override
  String get lockNeedSecretOnce =>
      'Masukkan kata laluan atau corak kunci sekali untuk mendayakan buka kunci cap jari pada peranti ini.';

  @override
  String get lockForgotConfirmTitle => 'Set semula kunci nota?';

  @override
  String get lockForgotConfirmBody =>
      'Nota berkunci yang disulitkan dengan rahsia semasa anda tidak boleh dinyahsulit lagi tanpa rahsia itu. Set semula kunci juga?';

  @override
  String get lockForgotConfirmAction => 'Set semula';

  @override
  String get starterShoppingTitle => '🛒 Contoh senarai barang dapur';

  @override
  String get starterWelcomeTitle => '⚡ Mula pantas';

  @override
  String get smartListMoving => 'Perancang berpindah';

  @override
  String get smartListCleaning => 'Pembersihan rumah';

  @override
  String get smartListHabits => 'Penjejak tabiat';

  @override
  String get smartListWorkout => 'Perancang senaman';

  @override
  String get smartListGifts => 'Perancang hadiah';

  @override
  String get smartListWatchlist => 'Senarai tontonan';

  @override
  String get smartListEvent => 'Acara & parti';

  @override
  String get smartListExpense => 'Bajet & perbelanjaan';

  @override
  String get smartListKindSelect => 'Pilih jenis senarai';

  @override
  String get smartListCatalog => 'Pakej & katalog';

  @override
  String get smartListSearchCatalog => 'Cari item atau kumpulan…';

  @override
  String get smartListStarterPacks => 'Pakej permulaan';

  @override
  String get smartListOpenWorkspace => 'Buka dalam ruang kerja';

  @override
  String get smartListTripWizard => 'Wizard perjalanan';

  @override
  String get smartListEventWizard => 'Wizard acara';

  @override
  String get smartListWizardDays => 'Berapa hari?';

  @override
  String get smartListWizardWeather => 'Cuaca';

  @override
  String get smartListWeatherHot => 'Panas';

  @override
  String get smartListWeatherMild => 'Sederhana';

  @override
  String get smartListWeatherCold => 'Sejuk';

  @override
  String get smartListWeatherRainy => 'Hujan';

  @override
  String get smartListWizardStyle => 'Gaya perjalanan';

  @override
  String get smartListStyleBeach => 'Pantai';

  @override
  String get smartListStyleCity => 'Bandar';

  @override
  String get smartListStyleBusiness => 'Perniagaan';

  @override
  String get smartListStyleIntl => 'Antarabangsa';

  @override
  String get smartListStyleCamp => 'Berkhemah';

  @override
  String get smartListWizardGuests => 'Berapa ramai tetamu?';

  @override
  String get smartListEventStyle => 'Jenis acara';

  @override
  String get smartListEventBirthday => 'Hari jadi';

  @override
  String get smartListEventDinner => 'Majlis makan malam';

  @override
  String get smartListEventPicnic => 'Berkelah';

  @override
  String smartListApplyPlan(int count) {
    return 'Tambah ke senarai ($count item)';
  }

  @override
  String smartListPackAdded(String name) {
    return 'Pakej “$name” ditambah';
  }

  @override
  String get smartListEditItem => 'Sunting item';

  @override
  String get smartListItemNameHint => 'Nama item';

  @override
  String get smartListItemQty => 'Kuantiti';

  @override
  String get smartListItemUnit => 'Unit';

  @override
  String get smartListAll => 'Semua';

  @override
  String get smartListResetDone => 'Senarai diset semula';

  @override
  String get smartListWorkspaceEmpty =>
      'Belum ada item; tambah di bawah atau pilih pakej permulaan.';

  @override
  String get smartWorkspaceOpen => 'Buka ruang kerja';

  @override
  String smartPillHabit(int done, int total) {
    return 'Tabiat · $done/$total hari ini';
  }

  @override
  String smartPillMoving(int done, int total) {
    return 'Berpindah · $done/$total sedia';
  }

  @override
  String smartPillPacking(int done, int total) {
    return 'Barang bawaan · $done/$total dikemas';
  }

  @override
  String smartPillWorkout(int done, int total) {
    return 'Senaman · $done/$total selesai';
  }

  @override
  String smartPillCleaning(int done, int total) {
    return 'Pembersihan · $done/$total selesai';
  }

  @override
  String smartPillGifts(int done, int total) {
    return 'Hadiah · $done/$total sedia';
  }

  @override
  String smartPillWatchlist(int count) {
    return 'Senarai tontonan · $count menunggu';
  }

  @override
  String smartPillExpense(String total) {
    return 'Bajet · RM $total';
  }

  @override
  String smartPillDefault(int count) {
    return 'Ruang kerja pintar ($count lagi)';
  }

  @override
  String habitDoneToday(int done, int total) {
    return '$done/$total hari ini';
  }

  @override
  String habitBestStreak(int days) {
    return 'Rentetan terbaik: $days hari';
  }

  @override
  String habitStreakDays(int days) {
    return 'Rentetan $days h';
  }

  @override
  String get habitWeeklyGoal => 'Sasaran mingguan';

  @override
  String habitWeeklyProgress(int done, int goal) {
    return '$done/$goal minggu ini';
  }

  @override
  String get habitTimeMorning => 'Pagi';

  @override
  String get habitTimeAfternoon => 'Petang';

  @override
  String get habitTimeEvening => 'Malam';

  @override
  String get habitFilterRemaining => 'Perlu hari ini';

  @override
  String get habitLast30Days => '30 hari lepas';

  @override
  String get habitAddHint => 'Tambah tabiat baharu…';

  @override
  String get habitPrevWeek => 'Minggu sebelumnya';

  @override
  String get habitNextWeek => 'Minggu seterusnya';

  @override
  String get movingViewTimeline => 'Garis masa';

  @override
  String get movingViewRooms => 'Bilik & kotak';

  @override
  String get movingPhaseMonth => '1 bulan sebelum';

  @override
  String get movingPhaseWeek => '1 minggu sebelum';

  @override
  String get movingPhaseDay => 'Hari berpindah';

  @override
  String get movingPhaseNewHome => 'Rumah baharu';

  @override
  String get movingRoomKitchen => 'Dapur';

  @override
  String get movingRoomLiving => 'Ruang tamu';

  @override
  String get movingRoomBedroom => 'Bilik tidur';

  @override
  String get movingRoomBath => 'Bilik air';

  @override
  String get movingRoomStudy => 'Bilik belajar';

  @override
  String get movingRoomGeneral => 'Umum';

  @override
  String movingBoxesCount(int count) {
    return '$count kotak';
  }

  @override
  String movingFragileCount(int count) {
    return '$count mudah pecah';
  }

  @override
  String get movingFragile => 'Mudah pecah';

  @override
  String get movingOpenFirst => 'Buka dahulu';

  @override
  String get movingBoxNumber => 'No. kotak (cth. #1)';

  @override
  String get movingAddHint => 'Tambah tugasan berpindah atau kotak…';

  @override
  String get packingBagChecked => 'Bagasi daftar masuk';

  @override
  String get packingBagCabin => 'Kabin';

  @override
  String get packingBagWear => 'Dipakai';

  @override
  String get packingReset => 'Set semula kemasan';

  @override
  String get packingAddHint => 'Tambah item (cth. 3 baju-T)…';

  @override
  String workoutSetsCount(int done, int total) {
    return '$done/$total set';
  }

  @override
  String get workoutRestTimer => 'Pemasa rehat';

  @override
  String workoutRestSeconds(int sec) {
    return '$sec s';
  }

  @override
  String get workoutAutoTimer => 'Mula automatik selepas set';

  @override
  String get workoutSetsLabel => 'Set';

  @override
  String get workoutRepsLabel => 'Ulangan / masa';

  @override
  String get workoutWeightLabel => 'Berat (cth. 20 kg)';

  @override
  String get workoutZoneWarmup => 'Memanaskan badan';

  @override
  String get workoutZoneUpper => 'Atas';

  @override
  String get workoutZoneLower => 'Bawah';

  @override
  String get workoutZoneCore => 'Teras';

  @override
  String get workoutZoneCardio => 'Kardio';

  @override
  String get workoutZoneStretch => 'Regangan';

  @override
  String get workoutReset => 'Set semula senaman';

  @override
  String get workoutAddHint => 'Tambah senaman…';

  @override
  String get cleaningFreqDaily => 'Harian';

  @override
  String get cleaningFreqWeekly => 'Mingguan';

  @override
  String get cleaningFreqMonthly => 'Bulanan';

  @override
  String get cleaningReset => 'Set semula kitaran';

  @override
  String get cleaningAddHint => 'Tambah tugasan pembersihan…';

  @override
  String get giftStageIdea => 'Idea';

  @override
  String get giftStageBought => 'Dibeli';

  @override
  String get giftStageWrapped => 'Dibalut';

  @override
  String get giftStageGiven => 'Diberikan';

  @override
  String get giftRecipient => 'Penerima';

  @override
  String get giftPrice => 'Bajet (RM)';

  @override
  String giftSummaryPlanned(String total, String bought) {
    return 'Jumlah: RM $total · Dibeli: RM $bought';
  }

  @override
  String get giftAddHint => 'Tambah hadiah atau penerima…';

  @override
  String get watchTypeMovie => 'Filem';

  @override
  String get watchTypeSeries => 'Siri';

  @override
  String get watchTypeBook => 'Buku';

  @override
  String get watchTypeDoc => 'Dokumentari';

  @override
  String get watchTypePodcast => 'Podcast';

  @override
  String get watchStatusQueued => 'Menunggu';

  @override
  String get watchStatusWatching => 'Sedang berjalan';

  @override
  String get watchStatusDone => 'Selesai';

  @override
  String get watchPlatform => 'Platform atau pengarang';

  @override
  String get watchRating => 'Penilaian anda';

  @override
  String get watchAddHint => 'Tambah filem, siri atau buku…';

  @override
  String get expenseCatMarket => 'Barang dapur';

  @override
  String get expenseCatBills => 'Bil';

  @override
  String get expenseCatTransport => 'Pengangkutan';

  @override
  String get expenseCatFood => 'Makan di luar';

  @override
  String get expenseCatHome => 'Rumah';

  @override
  String get expenseCatHealth => 'Kesihatan';

  @override
  String get expenseCatFun => 'Hiburan';

  @override
  String get expenseCatOther => 'Lain-lain';

  @override
  String expenseSummaryBar(String total, String paid, String left) {
    return 'Jumlah: RM $total · Dibayar: RM $paid · Baki: RM $left';
  }

  @override
  String get expenseAmountHint => 'Jumlah (RM)';

  @override
  String get expenseAddHint => 'Tambah item (cth. Elektrik 85)…';

  @override
  String get domainGearReset => 'Set semula senarai';

  @override
  String get domainAddHint => 'Tambah item baharu…';

  @override
  String get quickDropKeepOpen => 'Kekal terbuka (input berturut-turut)';

  @override
  String get quickDropSmartListChip => 'Senarai pintar';

  @override
  String quickDropPreviewSmartList(String kind, String items) {
    return '✨ $kind baharu: $items';
  }

  @override
  String quickDropSavedSmartList(String title) {
    return 'Senarai pintar “$title” dicipta';
  }

  @override
  String quickDropAddedSerial(String title) {
    return 'Ditambah ke “$title”';
  }

  @override
  String get quickDropUrgentBadge => 'Segera';

  @override
  String get tplBadgeShopping => 'Lorong · 2 lajur';

  @override
  String get tplBadgeHabits => '7 hari · berturut';

  @override
  String get tplBadgeMoving => 'Fasa · kotak';

  @override
  String get tplBadgeTravel => 'Kabin · bagasi · bestari';

  @override
  String get tplBadgeWorkout => 'Set · pemasa rehat';

  @override
  String get tplBadgeCleaning => 'Bilik · kekerapan';

  @override
  String get tplBadgeGifts => 'Idea · bajet';

  @override
  String get tplBadgeWatchlist => '5 bintang · jenis';

  @override
  String get tplBadgeExpense => 'Bajet · jumlah';

  @override
  String get templatesMoreSmartLists => 'Senarai pintar lain';

  @override
  String get smartListEntryHint => 'Taip atau sebut: pasport, 2 susu…';

  @override
  String get quickListGenericHint => 'Taip atau sebut item…';

  @override
  String get quickDropKeepOpenShort => 'Kekal buka';

  @override
  String get quickDropTagHint => '#tag';

  @override
  String get quickDropUrgentHint => '!segera';

  @override
  String get brightnessModeAuto => 'Automatik';

  @override
  String get brightnessModeLight => 'Cerah';

  @override
  String get brightnessModeDark => 'Gelap';

  @override
  String brightnessModeToggleTooltip(String mode) {
    return 'Mod penampilan: $mode';
  }

  @override
  String get appearanceTabTheme => 'Tema';

  @override
  String get appearanceTabBackground => 'Latar';

  @override
  String get appearanceTabLayout => 'Susun atur';

  @override
  String get appearanceOpenStudio => 'Latar & penampilan';

  @override
  String get applyHomeBackgroundToNotes => 'Guna pada nota juga';

  @override
  String get applyHomeBackgroundToNotesInfo =>
      'Nota tanpa latar tersuai akan menggunakan latar ini.';

  @override
  String get noteUseHomeBackground => 'Latar utama';

  @override
  String get bgSubTabWallpapers => 'Gambar';

  @override
  String get bgSubTabIllustrated => 'Ilustrasi';

  @override
  String get bgSubTabColors => 'Warna';

  @override
  String get bgSubTabPatterns => 'Corak';

  @override
  String get bgSubTabFrame => 'Bingkai';

  @override
  String get bgSubTabPaper => 'Kertas';

  @override
  String get personalizeGroupEditor => 'Bar editor nota';

  @override
  String get personalizeGroupAddAttach => 'Tambah & lampiran';

  @override
  String get personalizeEditBars => 'Sesuaikan bar editor';

  @override
  String get attachmentRename => 'Namakan semula';

  @override
  String get attachmentRenameHint => 'Nama lampiran';

  @override
  String attachmentsAllTitle(int count) {
    return 'Semua lampiran ($count)';
  }

  @override
  String get attachmentsAllButton => 'Semua';

  @override
  String get attachmentRetryUpload => 'Cuba lagi';

  @override
  String get pinnedCollapse => 'Kecilkan';

  @override
  String get pinnedExpand => 'Besarkan';

  @override
  String get pinnedHideKeyboard => 'Sembunyikan papan kekunci';

  @override
  String get floatingSizeSmall => 'Kecil';

  @override
  String get floatingSizeMedium => 'Sederhana';

  @override
  String get floatingSizeLarge => 'Penuh';

  @override
  String get floatingAlignCycle => 'Penjajaran mendatar';
}
