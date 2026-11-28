// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appName => 'Catatan';

  @override
  String get loginTagline => 'Catatanmu di semua perangkat';

  @override
  String get signInWithGoogle => 'Masuk dengan Google';

  @override
  String loginError(String error) {
    return 'Gagal masuk: $error';
  }

  @override
  String get searchHint => 'Cari...';

  @override
  String get filterAll => 'Semua';

  @override
  String get filterText => 'Teks';

  @override
  String get filterChecklist => 'Daftar';

  @override
  String get filterOrdered => 'Bernomor';

  @override
  String get filterPinned => 'Disematkan';

  @override
  String get star => 'Beri bintang';

  @override
  String get unstar => 'Hapus bintang';

  @override
  String get sectionOthers => 'Lainnya';

  @override
  String get emptyNotes => 'Belum ada catatan di sini';

  @override
  String get emptyFilter => 'Tidak ada catatan yang cocok dengan filter ini';

  @override
  String get clearFilter => 'Hapus filter';

  @override
  String get emptyFolderTitle => 'Belum ada catatan di sini';

  @override
  String get newNoteAction => 'Tambah catatan';

  @override
  String get emptySearch => 'Tidak ada yang cocok dengan pencarianmu';

  @override
  String get newTextNote => 'Catatan teks';

  @override
  String get newChecklist => 'Daftar';

  @override
  String get newOrderedList => 'Daftar bernomor';

  @override
  String get noteDeleted => 'Catatan dihapus';

  @override
  String get dragTrashHint => 'Lepas di sini untuk menghapus';

  @override
  String get dragTrashReady => 'Lepas untuk menghapus';

  @override
  String notesDeletedCount(int count) {
    return '$count catatan dihapus';
  }

  @override
  String selectedCount(int count) {
    return '$count dipilih';
  }

  @override
  String get deleteSelected => 'Hapus yang dipilih';

  @override
  String get undo => 'Urungkan';

  @override
  String get redo => 'Ulangi';

  @override
  String get titleHint => 'Judul';

  @override
  String get bodyHint => 'Catatan...';

  @override
  String get newItemHint => 'Item baru';

  @override
  String moreItemsCount(int count) {
    return '+$count item lagi';
  }

  @override
  String get addAttachment => 'Tambah';

  @override
  String get addImage => 'Tambah gambar';

  @override
  String attachmentFailed(String error) {
    return 'Tidak dapat menambahkan lampiran: $error';
  }

  @override
  String get attachmentCopying => 'Menyalin...';

  @override
  String get attachmentUploading => 'Mengunggah...';

  @override
  String get attachmentUploadFailed =>
      'Unggahan gagal — ketuk untuk mencoba lagi';

  @override
  String get attachmentNotSynced =>
      'File ini belum disinkronkan ke perangkat ini';

  @override
  String get attachmentDeviceOnly =>
      'File besar: hanya disimpan di perangkat ini, tidak dicadangkan ke cloud';

  @override
  String get attachmentOtherDevice =>
      'File besar ini hanya ada di perangkat tempat ia ditambahkan; tidak diunduh di sini';

  @override
  String get attachmentDeviceFull =>
      'Ruang perangkat tidak cukup untuk menyalin file. Kosongkan sebagian ruang lalu coba lagi.';

  @override
  String get webDriveTapToOpen => 'Di Google Drive · ketuk untuk membuka';

  @override
  String get noteFullscreen => 'Layar penuh';

  @override
  String get noteFullscreenExit => 'Keluar dari layar penuh';

  @override
  String get penModeDone => 'Tutup pena';

  @override
  String get pageInkOnCard => 'Ada tulisan tangan';

  @override
  String attachmentTooLarge(int limit) {
    return 'File terlalu besar (maks. $limit MB)';
  }

  @override
  String storageFull(String limit) {
    return 'Penyimpanan penuh ($limit). Hapus lampiran lama untuk mengosongkan ruang.';
  }

  @override
  String get storageUsage => 'Penyimpanan';

  @override
  String storageUsageValue(String used, String limit) {
    return '$used dari $limit terpakai';
  }

  @override
  String get removeAttachment => 'Hapus lampiran';

  @override
  String get pin => 'Sematkan';

  @override
  String get unpin => 'Lepas sematan';

  @override
  String get delete => 'Hapus';

  @override
  String get color => 'Warna';

  @override
  String get summarize => 'Ringkas';

  @override
  String get listen => 'Dengarkan';

  @override
  String get ask => 'Ajukan pertanyaan';

  @override
  String get extractText => 'Ekstrak teks';

  @override
  String get transcribe => 'Transkripsi';

  @override
  String get listenToNote => 'Dengarkan';

  @override
  String aiError(String error) {
    return 'Permintaan AI gagal: $error';
  }

  @override
  String get aiThinking => 'Berpikir...';

  @override
  String get copy => 'Salin';

  @override
  String get copied => 'Disalin';

  @override
  String get settingsSearchHint => 'Cari pengaturan — “kunci”, “mikrofon”';

  @override
  String settingsSearchEmpty(String query) {
    return 'Tidak ada pengaturan yang cocok dengan «$query»';
  }

  @override
  String get settings => 'Pengaturan';

  @override
  String get settingsAppearance => 'Tampilan';

  @override
  String get themeSystem => 'Sistem';

  @override
  String get themeSage => 'Sage';

  @override
  String get themePorcelain => 'Porselen';

  @override
  String get themeClay => 'Tanah liat';

  @override
  String get themeDark => 'Gelap';

  @override
  String get privacyPolicyTitle => 'Kebijakan privasi';

  @override
  String get lockNote => 'Kunci';

  @override
  String get unlockNote => 'Buka kunci';

  @override
  String get lockedNote => 'Catatan terkunci';

  @override
  String get unlockAuthReason =>
      'Verifikasi identitasmu untuk membuka catatan terkunci';

  @override
  String get exportBackup => 'Cadangan lengkap';

  @override
  String get expandListItems => 'Tampilkan baris daftar sepenuhnya';

  @override
  String get expandListItemsInfo =>
      'Item panjang dibungkus dan tampil penuh; jika mati, satu baris.';

  @override
  String get quickCaptureRowSetting => 'Bilah catatan cepat';

  @override
  String get quickCaptureRowInfo =>
      'Kolom satu baris “Catatan baru…” di atas beranda.';

  @override
  String get emptyTrash => 'Kosongkan sampah';

  @override
  String emptyTrashConfirm(int count) {
    return '$count catatan akan dihapus permanen. Ini tidak dapat dibatalkan. Kamu yakin?';
  }

  @override
  String get trashEmptied => 'Sampah dikosongkan';

  @override
  String get validateAndSave => 'Verifikasi dan simpan';

  @override
  String get clear => 'Hapus';

  @override
  String get apiKeyValid => 'Kunci API terverifikasi dan disimpan';

  @override
  String get apiKeyInvalid => 'Kunci API tidak valid';

  @override
  String get apiKeySavedBadge => 'Tersimpan';

  @override
  String get removeApiKey => 'Hapus kunci';

  @override
  String get refresh => 'Muat ulang';

  @override
  String get account => 'Akun';

  @override
  String get signOut => 'Keluar';

  @override
  String get switchAccount => 'Ganti akun';

  @override
  String get switchAccountConfirm =>
      'Kamu akan keluar dari akun ini dan pemilih akun Google akan terbuka. Catatanmu tetap di akun ini dan akan ada saat kamu kembali.';

  @override
  String get switchAccountGuestWarning =>
      'Kamu memakai akun tamu: jika berganti, kamu kehilangan akses ke catatan di perangkat ini. Tautkan akun Google atau buat cadangan lengkap dulu.';

  @override
  String get penTrayShow => 'Tampilkan baki pena';

  @override
  String get addDrawingSubtitle =>
      'Gambar di kanvas terpisah, disematkan sebagai gambar';

  @override
  String get addGroupWrite => 'Tulis';

  @override
  String get addGroupPen => 'Pena';

  @override
  String get addGroupFiles => 'File dan tautan';

  @override
  String get addGroupSound => 'Suara';

  @override
  String get addGroupTemplate => 'Templat';

  @override
  String get addSeparateDrawing => 'Gambar terpisah (gambar)';

  @override
  String get addHandwriting => 'Tulis di halaman (pena)';

  @override
  String get addHandwritingSubtitle =>
      'Mode pena: tulis langsung di halaman catatan';

  @override
  String webDriveBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count lampiran ada di Google Drive-mu — izinkan akses untuk melihatnya',
      one: '1 lampiran ada di Google Drive-mu — izinkan akses untuk melihatnya',
    );
    return '$_temp0';
  }

  @override
  String get webDriveShow => 'Tampilkan';

  @override
  String webAttachmentsOnPhone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count lampiran belum keluar dari ponsel tempat ia ditambahkan. Di ponsel: Pengaturan → Sinkronisasi → hubungkan Drive.',
      one: '1 lampiran belum keluar dari ponsel tempat ia ditambahkan. Di ponsel: Pengaturan → Sinkronisasi → hubungkan Drive.',
    );
    return '$_temp0';
  }

  @override
  String get fullscreenPullHint => 'Tarik untuk layar penuh';

  @override
  String get fullscreenPullRelease => 'Lepas: layar penuh';

  @override
  String get signOutConfirm => 'Kamu yakin ingin keluar?';

  @override
  String get signOutAnonymousWarning =>
      'Kamu memakai akun lokal: keluar membuat akun ini dan semua catatannya tidak dapat diakses selamanya — tanpa cadangan tidak bisa dipulihkan. Tautkan akun Google dulu untuk menyimpan catatanmu. Tetap keluar?';

  @override
  String get deleteAccount => 'Hapus akun dan dataku';

  @override
  String get deleteAccountWarning =>
      'Ini tidak dapat dibatalkan: semua catatan, lampiran, dan akunmu akan dihapus permanen. Lanjutkan?';

  @override
  String get deleteAccountConfirm => 'Hapus permanen';

  @override
  String get deleteAccountPageInfo =>
      'Akun dan semua datamu dihapus permanen: catatan, folder, lampiran (cloud dan, jika ditautkan, Drive), kontak, catatan masuk, folder yang kamu bagikan, dan catatan akunmu. Salinan catatan yang kamu kirim ke orang lain tetap pada mereka. Ini tidak dapat dibatalkan; buat cadangan dari Pengaturan dulu jika mau.';

  @override
  String get licensesTitle => 'Lisensi sumber terbuka';

  @override
  String get generating => 'Membuat...';

  @override
  String get retry => 'Coba lagi';

  @override
  String get cancel => 'Batal';

  @override
  String get close => 'Tutup';

  @override
  String get ok => 'OK';

  @override
  String get syncPending => 'Menunggu sinkronisasi';

  @override
  String get synced => 'Tersinkron';

  @override
  String get liteSyncHeld =>
      'Perubahan dikirim ke cloud setiap beberapa menit — ketuk untuk sinkron sekarang';

  @override
  String get liteSyncSending => 'Mengirim perubahan ke cloud';

  @override
  String genericError(String error) {
    return 'Terjadi kesalahan: $error';
  }

  @override
  String get addTag => 'Tag';

  @override
  String get tagHint => 'mis. kerja, rumah, sekolah';

  @override
  String get addReminder => 'Ingatkan aku';

  @override
  String get placeReminder => 'Pengingat lokasi';

  @override
  String get placeReminderHint =>
      'Terima catatan ini sebagai notifikasi saat kamu tiba atau meninggalkan suatu tempat. Sistem memantau lokasi; tetap bekerja meski aplikasi ditutup.';

  @override
  String get placeCurrent => 'Lokasiku saat ini';

  @override
  String get placeSearchHint => 'Cari alamat atau tempat';

  @override
  String get placeSearchNone => 'Tidak ada hasil';

  @override
  String get placeArrive => 'Saat tiba';

  @override
  String get placeLeave => 'Saat pergi';

  @override
  String get placeRadius => 'Radius';

  @override
  String get placeSave => 'Atur pengingat';

  @override
  String get placeRemove => 'Hapus pengingat lokasi';

  @override
  String get placeSet => 'Pengingat lokasi diatur';

  @override
  String get placeRemoved => 'Pengingat lokasi dihapus';

  @override
  String get placeNeedPermission =>
      'Izin lokasi tidak diberikan. Kamu bisa mengizinkannya di pengaturan.';

  @override
  String get placeNeedBackground =>
      'Agar bekerja saat aplikasi ditutup, atur izin lokasi ke \"Izinkan sepanjang waktu\".';

  @override
  String get placeBackgroundTitle => 'Perlu izin \"Sepanjang waktu\"';

  @override
  String get placeOpenSettings => 'Izinkan';

  @override
  String get placeLocationOff =>
      'Lokasi perangkat mati. Nyalakan lalu coba lagi.';

  @override
  String get placeFailed => 'Tidak dapat mengatur pengingat lokasi.';

  @override
  String get placeNoLocation =>
      'Tidak dapat mengambil lokasimu. Pastikan lokasi menyala.';

  @override
  String placeArrivedBody(String place) {
    return 'Kamu tiba di $place';
  }

  @override
  String placeLeftBody(String place) {
    return 'Kamu meninggalkan $place';
  }

  @override
  String get share => 'Bagikan';

  @override
  String get archive => 'Arsipkan';

  @override
  String get unarchive => 'Keluarkan dari arsip';

  @override
  String get archiveTitle => 'Arsip';

  @override
  String get archiveEmpty => 'Tidak ada catatan yang diarsipkan di sini';

  @override
  String get trashTitle => 'Sampah';

  @override
  String get trashEmpty => 'Tidak ada catatan yang dihapus di sini';

  @override
  String get trashInfo =>
      'Catatan yang dihapus tetap di sini; kamu bisa memulihkan atau menghapusnya permanen.';

  @override
  String get restore => 'Pulihkan';

  @override
  String get deleteForever => 'Hapus permanen';

  @override
  String get deleteForeverConfirm =>
      'Catatan ini akan dihapus permanen. Kamu yakin?';

  @override
  String get recordAudio => 'Rekaman suara';

  @override
  String get recording => 'Merekam...';

  @override
  String get stopAndSave => 'Selesai dan tambahkan';

  @override
  String get micPermissionDenied => 'Izin mikrofon ditolak';

  @override
  String get addDrawing => 'Tambah gambar';

  @override
  String get addToNote => 'Tambahkan ke catatan';

  @override
  String get fontSize => 'Ukuran teks';

  @override
  String get fontSizePreview => 'Catatanmu akan terlihat seperti ini';

  @override
  String get darkSchedule => 'Jadwal tema gelap';

  @override
  String get darkScheduleInfo =>
      'Beralih ke tema gelap di antara jam yang kamu atur';

  @override
  String get voiceCommand => 'Perintah suara';

  @override
  String get suggestTags => 'Sarankan tag';

  @override
  String get existingTagsLabel => 'Tag sebelumnya';

  @override
  String get voiceFinish => 'Selesai';

  @override
  String get voiceProcessing => 'Menerapkan yang kamu ucapkan...';

  @override
  String get voiceNothingHeard => 'Tidak ada ucapan terdeteksi dalam rekaman';

  @override
  String get voiceNoteSaved => 'Catatan suaramu telah disimpan';

  @override
  String get openNote => 'Buka catatan';

  @override
  String get remindersTitle => 'Pengingat';

  @override
  String get remindersEmpty => 'Tidak ada pengingat di sini';

  @override
  String get remindersEmptyHint =>
      'Tambahkan pengingat ke catatan, atau tulis catatan baru dengan pengingat lewat +.';

  @override
  String get remindersUpcoming => 'Mendatang';

  @override
  String get remindersPast => 'Lewat';

  @override
  String get reminderInPast =>
      'Waktu yang dipilih sudah lewat — pilih waktu mendatang.';

  @override
  String get newReminder => 'Pengingat baru';

  @override
  String get remindersUntitled => 'Catatan tanpa judul';

  @override
  String get remindersEdit => 'Ubah waktu';

  @override
  String get remindersRemove => 'Hapus pengingat';

  @override
  String get clearNote => 'Hapus isi';

  @override
  String get clearNoteConfirm =>
      'Isi catatan (teks dan item daftar) akan dihapus. Kamu yakin?';

  @override
  String get calculatorTitle => 'Kalkulator';

  @override
  String get calcExpressionHint => 'mis. 12.5×3+40';

  @override
  String get calcInvalid => 'Ekspresi tidak valid';

  @override
  String get liveDictation => 'Dikte';

  @override
  String get dictationHoldHint =>
      'Tahan mikrofon dan bicara; teks ditulis saat kamu melepas';

  @override
  String itemsSelected(int count) {
    return '$count item dipilih';
  }

  @override
  String get dictationProcessing => 'Mentranskripsi...';

  @override
  String get voiceListening => 'Mendengarkan...';

  @override
  String get voiceTapHint => 'Ketuk dan bicara; ketuk lagi untuk selesai';

  @override
  String get voiceModeSetting => 'Cara kerja';

  @override
  String get voiceModeHold => 'Tahan untuk bicara';

  @override
  String get voiceModeTap => 'Ketuk untuk mulai';

  @override
  String get voiceModeInfo =>
      'Tahan: berhenti saat dilepas. Ketuk: ketukan kedua menghentikannya.';

  @override
  String get voiceCaptureReady => 'Ucapan siap';

  @override
  String get voiceCaptureEditHint => 'Ketuk teks untuk mengedit';

  @override
  String voiceCapturePunctuation(String language) {
    return '$language · tanda baca otomatis';
  }

  @override
  String get voiceCaptureAddToNote => 'Tambahkan ke catatan';

  @override
  String get voiceCaptureCreateNote => 'Buat catatan baru';

  @override
  String get voiceCaptureAiNote => 'Catatan AI';

  @override
  String get voiceCapturePlainNote => 'Catatan biasa';

  @override
  String get voiceCloseTitle => 'Diktemu masih ada di sini';

  @override
  String get voiceCloseKeepTalking => 'Lanjutkan bicara';

  @override
  String get voiceCaptureRestart => 'Rekam lagi';

  @override
  String get voiceChipSummarizeAdd => 'Tambahkan sebagai ringkasan';

  @override
  String get voiceChipSummarizeSave => 'Simpan sebagai ringkasan';

  @override
  String get voiceChipToItems => 'Pecah menjadi item';

  @override
  String get voiceChipAsList => 'Jadikan daftar centang';

  @override
  String get voiceChipFix => 'Rapikan';

  @override
  String get permissionsTitle => 'Izin';

  @override
  String get permMic => 'Mikrofon';

  @override
  String get permMicInfo =>
      'Diperlukan untuk catatan suara AI, dikte, dan rekaman suara';

  @override
  String get permNotifications => 'Notifikasi';

  @override
  String get permNotificationsInfo =>
      'Diperlukan untuk pengingat dan ringkasan harian';

  @override
  String get permExactAlarm => 'Alarm & pengingat';

  @override
  String get permExactAlarmInfo =>
      'Jika mati, pengingat bisa terlambat beberapa menit. Izinkan untuk Catatan';

  @override
  String get permBattery => 'Pengoptimalan baterai';

  @override
  String get permBatteryInfo =>
      'Kecualikan aplikasi dari batasan baterai agar pengingat tidak terlambat';

  @override
  String get permAutoStart => 'Mulai otomatis (Xiaomi)';

  @override
  String get permAutoStartInfo =>
      'Pulihkan pengingat setelah mulai ulang: nyalakan “Mulai otomatis”';

  @override
  String get autoStartHint =>
      'Xiaomi: izinkan “Mulai otomatis” untuk aplikasi agar pengingat tetap berbunyi setelah mulai ulang';

  @override
  String get autoStartHintAction => 'Buka';

  @override
  String get exactAlarmHint =>
      'Izin alarm mati: pengingat bisa terlambat beberapa menit';

  @override
  String get exactAlarmHintAction => 'Izinkan';

  @override
  String get permCamera => 'Kamera';

  @override
  String get permCameraInfo =>
      'Diperlukan untuk catatan video dan mengambil foto';

  @override
  String get newVideoNote => 'Rekam video';

  @override
  String get videoLocalOnly =>
      'Video ini hanya disimpan di perangkat ini (tidak diunggah ke cloud)';

  @override
  String get videoToNote => 'Buat catatan dari video';

  @override
  String get permGranted => 'Diberikan';

  @override
  String get permGrant => 'Berikan';

  @override
  String get permOpenSettings => 'Buka pengaturan';

  @override
  String get newVoiceCapture => 'Catatan suara AI';

  @override
  String get suggestTitle => 'Sarankan judul';

  @override
  String get noteMetaMenu => 'Tag · Pengingat · Folder';

  @override
  String get folder => 'Folder';

  @override
  String get noFolder => 'Tanpa folder';

  @override
  String get newFolder => 'Folder baru';

  @override
  String get editFolder => 'Edit folder';

  @override
  String get deleteFolder => 'Hapus folder';

  @override
  String deleteFolderConfirm(String name) {
    return 'Folder \"$name\" akan dihapus. Catatan di dalamnya tidak dihapus — hanya menjadi tanpa folder.';
  }

  @override
  String get folderNameHint => 'Nama folder';

  @override
  String get folderIcon => 'Ikon';

  @override
  String get select => 'Pilih';

  @override
  String get noteArchived => 'Catatan diarsipkan';

  @override
  String pendingUploads(int count) {
    return '$count lampiran sedang diunggah';
  }

  @override
  String pendingUploadsFailed(int count) {
    return '$count lampiran gagal, akan dicoba lagi';
  }

  @override
  String pendingUploadsOffline(int count) {
    return '$count lampiran menunggu — akan diunggah saat kamu online';
  }

  @override
  String get pendingUploadsInfo =>
      'Lampiran aman di perangkat ini. Diunggah otomatis saat kamu online; sampai saat itu tidak muncul di perangkatmu yang lain.';

  @override
  String checkedHeader(int count) {
    return 'Dicentang ($count)';
  }

  @override
  String deleteChecked(int count) {
    return 'Hapus yang dicentang ($count)';
  }

  @override
  String get removeItem => 'Hapus item';

  @override
  String get copyWholeNote => 'Salin seluruh catatan';

  @override
  String get allCopied => 'Seluruh catatan disalin ke papan klip';

  @override
  String get speechRate => 'Kecepatan membaca';

  @override
  String get speechNoVoices =>
      'Tidak ada suara yang terpasang di perangkat ini';

  @override
  String get speechVoiceAutoInfo =>
      'Bahasa lain dibaca otomatis dengan suara pria';

  @override
  String get listening => 'Mendengarkan...';

  @override
  String get exportPdf => 'Ekspor sebagai PDF';

  @override
  String get pdfTitleField => 'Judul';

  @override
  String get pdfContentField => 'Isi';

  @override
  String get pdfMarkupHint =>
      'Tanda di awal baris menjadi format: [x] dan [ ] untuk kotak centang, 1. untuk daftar bernomor, - untuk poin.';

  @override
  String get pdfIncludeDate => 'Sertakan tanggal';

  @override
  String get exportIncludeImages => 'Sertakan gambar';

  @override
  String get exportWord => 'Bagikan sebagai Word (.docx)';

  @override
  String get pdfPreview => 'Pratinjau';

  @override
  String get largeAttachmentTitle => 'File besar';

  @override
  String largeAttachmentBody(String size) {
    return 'File ini $size MB. PDF tidak bisa dikompres; akan diunggah apa adanya dan dihitung ke penyimpananmu. Lanjutkan?';
  }

  @override
  String get speechRateForeign => 'Kecepatan bahasa asing';

  @override
  String notesArchivedCount(int count) {
    return '$count catatan diarsipkan';
  }

  @override
  String get backgroundColor => 'Warna latar';

  @override
  String get backgroundColorInfo =>
      'Latar catatan — tampil di dalam catatan dan di beranda';

  @override
  String get frameColor => 'Bingkai';

  @override
  String get sortBy => 'Urutkan';

  @override
  String get reorderNotes => 'Atur ulang catatan';

  @override
  String get reorderModeActive => 'Seret kartu untuk mengatur ulang';

  @override
  String get reorderDone => 'Selesai';

  @override
  String get sortManual => 'Manual (urutan seret)';

  @override
  String get sortUpdated => 'Baru diperbarui';

  @override
  String get sortCreated => 'Tanggal dibuat';

  @override
  String get sortTitle => 'Menurut judul (A–Z)';

  @override
  String get settingsLanguage => 'Bahasa';

  @override
  String get languageSystem => 'Bahasa sistem';

  @override
  String get syncTitle => 'Sinkronisasi';

  @override
  String get syncLimitTitle => 'Batas unggah otomatis';

  @override
  String get syncLimitInfo =>
      'Lampiran yang lebih besar tetap di perangkat; teks catatan selalu disinkronkan.';

  @override
  String get syncLimitUnlimited => 'Tanpa batas';

  @override
  String get importBackup => 'Pulihkan dari cadangan';

  @override
  String get importBackupInvalid => 'File cadangan tidak valid';

  @override
  String get moveToFolder => 'Pindahkan ke folder';

  @override
  String get assistantGenericError =>
      'Terjadi kesalahan — bisakah kamu coba lagi?';

  @override
  String get quickAddTooltip => 'Catatan baru — pilih jenis';

  @override
  String get annotate => 'Anotasi';

  @override
  String get annotateDone => 'Selesai anotasi';

  @override
  String get newPdfNote => 'Catatan dari PDF';

  @override
  String get imageNotePreparing => 'Menyusun gambar menjadi dokumen…';

  @override
  String get newImageNote => 'Catatan dari gambar';

  @override
  String get pdfPageNoteHint => 'Catatan untuk halaman ini…';

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
  String get pdfNextPage => 'Halaman berikutnya';

  @override
  String get pdfFullScreen => 'Buka layar penuh';

  @override
  String get pdfNoDocument => 'Catatan ini belum punya PDF';

  @override
  String get pdfChooseDocument => 'Pilih PDF';

  @override
  String get newSlidesNote => 'Catatan dari slide';

  @override
  String get slidesNoDocument => 'Catatan ini belum punya presentasi';

  @override
  String get slidesChooseDocument => 'Pilih presentasi';

  @override
  String get pdfEditPages => 'Edit halaman';

  @override
  String get pdfDeletePages => 'Hapus halaman yang dipilih';

  @override
  String get pdfAddBlankPage => 'Tambah halaman kosong';

  @override
  String get pdfRotatePages => 'Putar';

  @override
  String get pdfBurnInk => 'Tanamkan tulisan tangan ke dokumen';

  @override
  String get pdfApplyChanges => 'Terapkan perubahan';

  @override
  String get pdfCannotDeleteAllPages =>
      'Kamu tidak bisa menghapus semua halaman';

  @override
  String get pdfPagesHint =>
      'Ketuk halaman untuk memilihnya. Catatan halaman ikut bersama halamannya; catatan halaman yang dihapus disembunyikan tetapi tetap ada di datamu.';

  @override
  String pdfEditFailed(String error) {
    return 'Tidak dapat mengedit PDF: $error';
  }

  @override
  String get pdfInkBurned => 'Tulisan tangan ditanamkan ke dokumen';

  @override
  String get pdfAllPageNotes => 'Semua catatan halaman';

  @override
  String get pdfNoPageNotes =>
      'Belum ada catatan halaman. Buka halaman dan tulis di kolom di bawah.';

  @override
  String get crop => 'Pangkas';

  @override
  String get cropApply => 'Terapkan pangkasan';

  @override
  String get cropReset => 'Atur ulang pilihan';

  @override
  String get cropHint =>
      'Seret sudut untuk memilih area. Pangkasan tidak dapat dibatalkan.';

  @override
  String get cropFailed => 'Tidak dapat memangkas gambar.';

  @override
  String get penBallpoint => 'Pena bolpoin';

  @override
  String get penFountain => 'Pena tinta';

  @override
  String get penMarker => 'Spidol';

  @override
  String get penHighlighter => 'Stabilo';

  @override
  String get eraser => 'Penghapus';

  @override
  String get inkArrow => 'Panah';

  @override
  String get clearInk => 'Hapus anotasi';

  @override
  String get inkCleared => 'Anotasi dihapus';

  @override
  String get inkEraserTooltip => 'Penghapus (tahan: hapus semua)';

  @override
  String get inkTwoFingerHint =>
      'Satu jari menggambar · dua jari menggeser dan memperbesar';

  @override
  String get slideOpenFailed => 'Presentasi tidak dapat dibuka';

  @override
  String get newPhotoNote => 'Ambil foto';

  @override
  String get newScanNote => 'Pindai dokumen';

  @override
  String get scanDocument => 'Pindai dokumen';

  @override
  String get scanDocumentSubtitle =>
      'Menemukan tepi, meratakan halaman, lalu menambahkannya';

  @override
  String get scanUnsupported =>
      'Pemindaian dokumen tidak didukung di perangkat ini';

  @override
  String scanFailed(String error) {
    return 'Tidak dapat memindai dokumen: $error';
  }

  @override
  String scanPagesAdded(int count) {
    return '$count halaman ditambahkan ke catatan';
  }

  @override
  String get scanTextTitle => 'Kenali teksnya juga?';

  @override
  String get scanTextBody =>
      'Teks di halaman dikenali dan ditulis ke catatan. Gambar tetap seperti semula. Butuh beberapa detik per halaman.';

  @override
  String get scanImageOnly => 'Hanya gambar';

  @override
  String get scanRecognizeText => 'Kenali teks';

  @override
  String get scanRecognizing => 'Mengenali teks…';

  @override
  String get takePhoto => 'Ambil foto';

  @override
  String get qrScanTitle => 'Pindai kode QR';

  @override
  String get qrScanSubtitle => 'Baca dengan kamera atau dari foto';

  @override
  String get qrScanHint => 'Posisikan kode di dalam bingkai';

  @override
  String get qrFromPhoto => 'Baca dari foto';

  @override
  String get qrNotFound => 'Tidak ada kode dalam gambar ini';

  @override
  String get qrLinkFound => 'Kode ini berupa tautan';

  @override
  String get qrOpenLink => 'Buka tautan';

  @override
  String get qrSaveToNote => 'Simpan ke catatan';

  @override
  String get openLink => 'Buka tautan';

  @override
  String get linkOpenFailed => 'Tautan tidak dapat dibuka';

  @override
  String qrScanFailed(String error) {
    return 'Tidak dapat membaca kode: $error';
  }

  @override
  String get qrTorch => 'Senter';

  @override
  String get hideAttachments => 'Sembunyikan';

  @override
  String get showAttachments => 'Tampilkan';

  @override
  String get selectAllItems => 'Pilih semua';

  @override
  String get checkSelectedItems => 'Centang yang dipilih';

  @override
  String get itemUncheck => 'Hapus centang';

  @override
  String get uncheckSelectedItems => 'Hapus centang yang dipilih';

  @override
  String get hiddenFolder => 'Folder tersembunyi';

  @override
  String get hiddenFolderInfo =>
      'Folder tersembunyi dan catatannya tidak muncul di beranda. Untuk menampilkannya, pilih \"Folder tersembunyi\" dari menu ⋮ dan verifikasi identitasmu.';

  @override
  String get hiddenFoldersMenu => 'Folder tersembunyi';

  @override
  String get hiddenFolderAuthReason =>
      'Verifikasi identitasmu untuk menampilkan folder tersembunyi';

  @override
  String get hiddenFoldersShown => 'Folder tersembunyi sedang ditampilkan';

  @override
  String get hiddenFoldersHiddenAgain =>
      'Folder tersembunyi disembunyikan lagi';

  @override
  String get makeFolderHidden => 'Sembunyikan';

  @override
  String get makeFolderVisible => 'Tampilkan';

  @override
  String gridColumnsCount(int count) {
    return '$count kolom';
  }

  @override
  String get addImageOnPageSubtitle =>
      'Berada di halaman, teks mengalir di sekitarnya';

  @override
  String get addImageAsFile => 'Tambah gambar sebagai file';

  @override
  String get addImageAsFileSubtitle =>
      'Tetap di luar halaman, di strip lampiran';

  @override
  String get attachmentCopied => 'Lampiran disalin';

  @override
  String get pasteAttachment => 'Tempel lampiran yang disalin';

  @override
  String get fullscreen => 'Layar penuh';

  @override
  String get more => 'Lainnya';

  @override
  String get undone => 'Dibatalkan';

  @override
  String get filterOthers => 'Tanpa folder atau tag';

  @override
  String get aiHistoryVoiceNote => 'Catatan suara AI';

  @override
  String get sectionPinnedShort => 'Disematkan';

  @override
  String get sectionUrgent => 'Mendesak';

  @override
  String get urgentMark => 'Tandai mendesak';

  @override
  String get urgentUnmark => 'Hapus tanda mendesak';

  @override
  String get urgentInfo => 'Tampil paling atas di beranda, dengan !';

  @override
  String get sectionToday => 'Hari ini';

  @override
  String get sectionThisWeek => 'Minggu ini';

  @override
  String get sectionEarlier => 'Sebelumnya';

  @override
  String sectionNoteCount(int count) {
    return '$count catatan';
  }

  @override
  String get quickCaptureHint => 'Catatan baru…';

  @override
  String get quickCaptureSave => 'Simpan';

  @override
  String get viewToggle => 'Tampilan';

  @override
  String get viewGrid => 'Kisi';

  @override
  String get viewList => 'Daftar';

  @override
  String get filterReminded => 'Dengan pengingat';

  @override
  String get filterLocked => 'Terkunci';

  @override
  String get sortColor => 'Warna';

  @override
  String get sortActive => 'Paling sering dikerjakan';

  @override
  String get voicePreview => 'Coba suaranya';

  @override
  String get reorderHint =>
      'Tekan lama kartu, lalu seret ke tempat yang kamu mau';

  @override
  String get filterSheetTitle => 'Filter';

  @override
  String get filterReset => 'Atur ulang';

  @override
  String get filterSectionStatus => 'Status';

  @override
  String get filterSectionFolder => 'Folder';

  @override
  String get filterSectionTag => 'Tag';

  @override
  String get filterSectionSort => 'Urutan';

  @override
  String get filterSheetSortHint =>
      'Grup tanggal (Hari ini, Minggu ini…) hanya tampil saat diurutkan menurut “Baru diperbarui”.';

  @override
  String get formatTitle => 'Format';

  @override
  String get formatBold => 'Tebal';

  @override
  String get formatItalic => 'Miring';

  @override
  String get formatUnderline => 'Garis bawah';

  @override
  String get formatTextColor => 'Warna teks';

  @override
  String get formatHighlight => 'Sorot';

  @override
  String get formatInfo =>
      'Format ikut di dalam teks sebagai penanda (seperti **tebal**); penanda tetap tersembunyi saat ekspor dan dibacakan.';

  @override
  String get formatMenu => 'Format…';

  @override
  String get noteFontDefault => 'Bawaan';

  @override
  String get noteFontSerif => 'Buku (serif)';

  @override
  String get noteFontMono => 'Mesin tik';

  @override
  String get noteTextSize => 'Ukuran teks';

  @override
  String get formatClear => 'Hapus format';

  @override
  String get formatHeading => 'Judul';

  @override
  String get noteTextOpacity => 'Opasitas';

  @override
  String get assistantMute => 'Bisukan';

  @override
  String get assistantUnmute => 'Bunyikan';

  @override
  String get assistantMakeNote => 'Tetap jadikan catatan';

  @override
  String get assistantNoteCreated => 'Catatan dibuat';

  @override
  String get noteNotFound => 'Catatan tidak ditemukan. Mungkin sudah dihapus.';

  @override
  String get back => 'Kembali';

  @override
  String get addTextBlock => 'Tambah teks';

  @override
  String get noteBackgroundImage => 'Gambar latar';

  @override
  String get changeBackgroundImage => 'Ganti gambar';

  @override
  String get removeBackgroundImage => 'Hapus latar';

  @override
  String get dashboardBackground => 'Latar beranda';

  @override
  String get dashboardBackgroundInfo =>
      'Gambar yang tampil di belakang kisi catatan (hanya perangkat ini).';

  @override
  String get apiKeyFieldLabel => 'Kunci API';

  @override
  String get getApiKey => 'Di mana mendapatkan kunci?';

  @override
  String get continueWithoutAccount => 'Lanjutkan tanpa akun';

  @override
  String get localAccountInfo =>
      'Catatanmu hanya tersimpan di perangkat ini: tidak bisa dibuka di tempat lain dan hilang jika aplikasi dihapus. AI bawaan, kontak, dan berbagi memerlukan akun Google; kamu tetap bisa memakai AI dengan kunci API sendiri. Kamu bisa menautkan akun Google kapan saja — catatanmu ikut pindah.';

  @override
  String get localAccountBadge => 'Akun lokal';

  @override
  String get profileGuestName => 'Tamu';

  @override
  String get profileGuestSignIn => 'Masuk';

  @override
  String get linkGoogleAccount => 'Tautkan akun Google';

  @override
  String get accountLinked =>
      'Akun Google tertaut. Catatanmu kini dicadangkan.';

  @override
  String scanReviewPage(int current, int total) {
    return 'Halaman $current / $total';
  }

  @override
  String get scanRotatePage => 'Putar halaman';

  @override
  String get scanDeletePage => 'Hapus halaman';

  @override
  String get scanLastPage => 'Halaman terakhir tidak dapat dihapus';

  @override
  String get scanDiscardTitle => 'Buang halaman hasil pindaian?';

  @override
  String get scanDiscardConfirm => 'Buang';

  @override
  String get scanAdjustCorners => 'Sesuaikan sudut';

  @override
  String get scanFilterOriginal => 'Asli';

  @override
  String get scanFilterAuto => 'Perjelas';

  @override
  String get scanFilterGray => 'Skala abu-abu';

  @override
  String get scanFilterBw => 'Hitam putih';

  @override
  String get scanApplyAll => 'Terapkan ke semua';

  @override
  String get scanPageFailed => 'Tidak dapat menampilkan halaman';

  @override
  String get scanCropHint =>
      'Perbaiki halaman miring dengan \"Sesuaikan sudut\"';

  @override
  String get scanAddAsPdf => 'Tambahkan sebagai PDF';

  @override
  String get scanAddAsImages => 'Tambahkan sebagai gambar';

  @override
  String get scanBuildingPdf => 'Menyiapkan PDF…';

  @override
  String scanOcrProgress(int done, int total) {
    return 'Mengenali teks… $done/$total';
  }

  @override
  String get scanAutoDetect => 'Deteksi tepi otomatis';

  @override
  String get scanReset => 'Atur ulang';

  @override
  String get scanDetecting => 'Mencari tepi…';

  @override
  String get scanAutoFound =>
      'Tepi ditemukan otomatis; sesuaikan dengan pegangan jika perlu';

  @override
  String get scanDragHint => 'Seret sudut ke tepi kertas';

  @override
  String get scanApplyCorners => 'Luruskan & terapkan';

  @override
  String get scanWorking => 'Meluruskan…';

  @override
  String get scanPdfAdded =>
      'Hasil pindaian ditambahkan ke catatan sebagai lampiran PDF';

  @override
  String get premiumTitle => 'Premium';

  @override
  String get premiumStatusFree => 'Kamu memakai versi gratis';

  @override
  String get guestSignInUnavailable =>
      'Masuk tanpa Google sedang nonaktif: login anonim belum diaktifkan di konsol Firebase (Authentication → Sign-in method). Masuk dengan Google, atau coba lagi setelah admin mengaktifkannya.';

  @override
  String get googleSignInUnavailable =>
      'Masuk dengan Google sedang nonaktif: penyedia Google belum diaktifkan di konsol Firebase.';

  @override
  String get signInNetworkError =>
      'Tidak dapat terhubung ke internet. Periksa koneksimu lalu coba lagi.';

  @override
  String get signInCanceled => 'Masuk dibatalkan.';

  @override
  String get cardRichPreview => 'Teks berformat di kartu';

  @override
  String get cardRichPreviewInfo =>
      'Kartu menampilkan warna, sorotan, tebal, dan garis bawah.';

  @override
  String get cardHideSensitive => 'Sembunyikan konten sensitif di kartu';

  @override
  String get cardHideSensitiveInfo =>
      'Catatan kata sandi dan nomor kartu/IBAN disembunyikan di kartu.';

  @override
  String get sensitiveHiddenOnCard =>
      'Konten sensitif — disembunyikan di kartu';

  @override
  String get paletteMore => 'Warna lainnya';

  @override
  String get paletteCustom => 'Warna kustom';

  @override
  String get paletteUse => 'Gunakan';

  @override
  String get paletteHue => 'Rona';

  @override
  String get paletteSaturation => 'Saturasi';

  @override
  String get paletteLightness => 'Kecerahan';

  @override
  String get itemMoveToPage => 'Pindahkan ke halaman lain';

  @override
  String itemMovedToPage(int page) {
    return 'Item dipindahkan ke halaman $page';
  }

  @override
  String get archiveInsights => 'Apa isi arsipku?';

  @override
  String archiveInsightsStats(int count, int files, int stale) {
    return '$count catatan · $files lampiran · $stale tak tersentuh setahun';
  }

  @override
  String get archiveByFolder => 'Menurut folder';

  @override
  String get archiveNoFolder => 'Tanpa folder';

  @override
  String get archiveStale => 'Tak tersentuh setahun';

  @override
  String get lineSpacing => 'Spasi baris';

  @override
  String get lineSpacingNormal => 'Normal';

  @override
  String get lineSpacingWide => 'Lebar';

  @override
  String get lineSpacingWider => 'Lebih lebar';

  @override
  String get trashReminderTitle =>
      'Ada sesuatu di sampah yang mungkin layak disimpan';

  @override
  String trashReminderBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count catatan akan dihapus permanen besok',
      one: 'Sebuah catatan akan dihapus permanen besok',
    );
    return '$_temp0 — sepertinya masih berisi tugas atau info penting. Coba lihat.';
  }

  @override
  String get groupByFolder => 'Kelompokkan menurut folder';

  @override
  String get fontSizeSmall => 'Kecil';

  @override
  String get fontSizeMedium => 'Sedang';

  @override
  String get fontSizeLarge => 'Besar';

  @override
  String get fontSizeXLarge => 'Sangat besar';

  @override
  String get appFontSetting => 'Fon';

  @override
  String get appFontInfo => 'Huruf aplikasi; sebagian diunduh saat dipilih.';

  @override
  String get fontNeedsDownload => 'Diunduh sekali saat dipilih';

  @override
  String get followSystemTextScale => 'Ikuti ukuran teks sistem';

  @override
  String get followSystemTextScaleInfo =>
      'Ukuran teks ponsel juga berlaku di aplikasi.';

  @override
  String get pdfSelectOcrRunning => 'Mengenali teks…';

  @override
  String get pdfSelectOcrNone => 'Tidak ada teks di halaman ini';

  @override
  String pdfSelectCopied(int n) {
    return '$n karakter disalin';
  }

  @override
  String get bubbleAdd => 'Taruh gelembung catatan';

  @override
  String get bubbleAddDone => 'Selesai menambah gelembung';

  @override
  String get bubbleCollapse => 'Ciutkan gelembung';

  @override
  String get bubbleHint => 'Tulis catatanmu di sini…';

  @override
  String get bubbleTapToPlace => 'Ketuk halaman di tempat kamu ingin gelembung';

  @override
  String get ttsSectionTitle => 'Narasi';

  @override
  String get ttsEngineDevice => 'Suara perangkat';

  @override
  String get ttsEngineDeviceInfo =>
      'Suara bawaan perangkat yang membaca: gratis, offline, dan tanpa batas panjang.';

  @override
  String get shareAsNotePreparing => 'Menyiapkan paket catatan…';

  @override
  String get shareAsTextEmpty =>
      'Catatan ini tidak punya teks untuk dibagikan.';

  @override
  String get sharePdfWithBubbles => 'Sebagai PDF dengan gelembung';

  @override
  String get sharePdfWithBubblesInfo =>
      'Gelembung, sorotan, dan gambar dicetak ke PDF; siapa pun bisa membukanya, dan di aplikasi ini terbuka bisa diedit.';

  @override
  String get sharePdfWithBubblesNone =>
      'Catatan ini tidak punya PDF yang membawa gelembung atau gambar.';

  @override
  String get sharePdfWithBubblesPreparing => 'Menyiapkan PDF dengan gelembung…';

  @override
  String get sharePdfWithBubblesSuffix => ' (dengan gelembung)';

  @override
  String get bubbleStar => 'Beri bintang';

  @override
  String get bubbleEdit => 'Edit gelembung';

  @override
  String get bubbleStarredOnly => 'Hanya berbintang';

  @override
  String get bubbleSearchHint => 'Cari gelembung…';

  @override
  String get bubblesListAll => 'Semua gelembung';

  @override
  String get bubblesOverviewTitle => 'Gelembung';

  @override
  String get bubblesEmpty =>
      'Belum ada gelembung. Pilih teks di dokumen lalu sorot, atau taruh gelembung di halaman.';

  @override
  String get bubblesNoMatch =>
      'Tidak ada gelembung yang cocok dengan pencarianmu.';

  @override
  String get bubbleNoText => '(gelembung kosong)';

  @override
  String get pdfHighlight => 'Sorot';

  @override
  String get pdfHighlightWithNote => 'Sorot + catatan';

  @override
  String get pageNotesShow => 'Tampilkan catatan halaman';

  @override
  String get pageNotesHide => 'Sembunyikan catatan halaman';

  @override
  String get bubbleSave => 'Simpan';

  @override
  String get bubbleTitleHint => 'Judul';

  @override
  String get bubbleUrgent => 'Mendesak (berkedip)';

  @override
  String get captureModeQuestion => 'Bagaimana catatan dibuka?';

  @override
  String get captureModeBubbles => 'Gelembung';

  @override
  String get captureModeBubblesInfo =>
      'Konten menjadi halaman dokumen: gelembung, sorotan, dan pena.';

  @override
  String get captureModeClassic => 'Klasik';

  @override
  String get captureModeClassicInfo =>
      'Catatan teks biasa; dokumen menjadi lampiran.';

  @override
  String get captureModeNew => 'BARU';

  @override
  String get imagePrepareTitle => 'Sesuaikan gambar';

  @override
  String get imagePrepareDone => 'Lanjutkan';

  @override
  String get imageRotateLeft => 'Putar ke kiri';

  @override
  String get imageRotateRight => 'Putar ke kanan';

  @override
  String get videoFrameFailed =>
      'Tidak dapat mengambil bingkai dari video; membuka catatan klasik.';

  @override
  String get bubbleArrowHide => 'Sembunyikan panah';

  @override
  String get bubbleArrowShow => 'Tampilkan panah';

  @override
  String get speechPitch => 'Nada suara';

  @override
  String get speechVoicePickerTitle => 'Pilihan suara';

  @override
  String get formatRemove => 'Hapus';

  @override
  String get exportNotesOption => 'PDF / Word kustom…';

  @override
  String get exportNotesOptionInfo =>
      'Teks dan gambar catatan sebagai PDF atau Word, tata letak bisa diatur; tanpa gelembung';

  @override
  String get captureNoteTitle => 'Judul catatan (opsional)';

  @override
  String get captureNoteTitleHint => 'Dokumen baru juga mendapat nama ini';

  @override
  String get imageOcrTitle => 'Kenali teks dalam gambar';

  @override
  String get imageOcrNone => 'Tidak ada teks dalam gambar ini.';

  @override
  String get imageOcrShort => 'Kenali teks';

  @override
  String get imageOcrWorking => 'Mengenali teks…';

  @override
  String get imageOcrSelectHint =>
      'Ketuk: kata · Tahan dan seret: huruf demi huruf';

  @override
  String get imageOcrInsert => 'Tambahkan ke catatan';

  @override
  String get imageOcrZoomIn => 'Perbesar';

  @override
  String get imageOcrZoomOut => 'Perkecil';

  @override
  String get selectImages => 'Pilih gambar';

  @override
  String get exportImages => 'Gambar';

  @override
  String get exportImagesInfo =>
      'Teks mengalir di samping gambar sempit yang rata kiri atau kanan; gambar di tengah mengambil lebar penuh.';

  @override
  String get exportAlignLeft => 'Kiri';

  @override
  String get exportAlignCenter => 'Tengah';

  @override
  String get exportAlignRight => 'Kanan';

  @override
  String get exportImageWidth => 'Lebar';

  @override
  String get exportImageLine => 'Posisi';

  @override
  String imageOcrCharsSelected(int count) {
    return '$count karakter dipilih';
  }

  @override
  String imagesSelectedCount(int count) {
    return '$count gambar dipilih';
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
  String get rotateFailed => 'Tidak dapat memutar gambar.';

  @override
  String get dashboardBackgroundChange => 'Ganti gambar latar';

  @override
  String get appearancePreviewTitle => 'Contoh teks';

  @override
  String get appearancePreviewNoteTitle => 'Contoh judul catatan';

  @override
  String get appearancePreviewBody =>
      'Catatanmu akan terlihat seperti ini. Teks **tebal**, ~bergaris bawah~, dan ==2:disorot== tampil begini.';

  @override
  String get appearancePreviewItem =>
      'Item daftar centang terlihat seperti ini';

  @override
  String get convertToText => 'Ubah menjadi teks';

  @override
  String get convertToList => 'Ubah menjadi daftar';

  @override
  String get convertedToText => 'Daftar diubah menjadi teks biasa.';

  @override
  String get convertedToList => 'Teks diubah menjadi daftar.';

  @override
  String get convertToListEmpty =>
      'Tidak ada baris untuk diubah menjadi daftar.';

  @override
  String get listTwoColumns => 'Dua kolom';

  @override
  String get listOneColumn => 'Satu kolom';

  @override
  String get sortItems => 'Urutkan item';

  @override
  String get sortStarredFirst => 'Berbintang lebih dulu';

  @override
  String get sortUncheckedFirst => 'Yang selesai terakhir';

  @override
  String get sortAlphabetical => 'A → Z';

  @override
  String get sortAlphabeticalDesc => 'Z → A';

  @override
  String get imagesToAttachments => 'Pindahkan gambar ke lampiran';

  @override
  String imagesToAttachmentsDone(int count) {
    return '$count gambar dipindahkan ke lampiran.';
  }

  @override
  String get imageOcrShowRecognized => 'Sorot teks yang dikenali';

  @override
  String get imageOcrHideRecognized => 'Sembunyikan sorotan';

  @override
  String get bubblePlainMode => 'Kotak teks terbuka';

  @override
  String get bubblePlainTapToPlace => 'Ketuk tempat teks akan diletakkan';

  @override
  String get bubblePlainHint => 'Ketuk untuk menulis';

  @override
  String get noteSearchTitle => 'Cari dalam catatan';

  @override
  String get noteSearchHint => 'Cari di catatan ini…';

  @override
  String get noteSearchEmptyHint =>
      'Mencari teks catatan, item, dan catatan halaman secara instan. Mulai pemindaian di bawah untuk mencari di dalam lampiran gambar dan PDF.';

  @override
  String get noteSearchNoHit => 'Tidak ada yang cocok.';

  @override
  String get noteSearchScanAttachments => 'Pindai lampiran';

  @override
  String get noteTitleLabel => 'Judul';

  @override
  String get noteBodyLabel => 'Teks catatan';

  @override
  String get itemLabel => 'Item';

  @override
  String noteSearchAttachmentsInfo(int count) {
    return '$count lampiran dapat dipindai (gambar/PDF).';
  }

  @override
  String noteSearchAttachmentsReady(int count) {
    return 'Juga mencari di dalam $count lampiran.';
  }

  @override
  String pageLabel(int page) {
    return 'Halaman $page';
  }

  @override
  String get archiveNotebook => 'Buku catatan';

  @override
  String get archiveNewPage => 'Halaman baru';

  @override
  String get archiveTemplateJournal => 'Jurnal';

  @override
  String get archiveTemplateMeeting => 'Rapat';

  @override
  String get archiveTemplateExpense => 'Pengeluaran';

  @override
  String get archiveTemplateTodo => 'Tugas';

  @override
  String get archiveTemplateReading => 'Catatan bacaan';

  @override
  String get tplJournalHow => 'Bagaimana hari ini?';

  @override
  String get tplJournalGrateful => 'Bersyukur atas';

  @override
  String get tplJournalTomorrow => 'Untuk besok';

  @override
  String get tplMeetingAttendees => 'Peserta';

  @override
  String get tplMeetingAgenda => 'Agenda';

  @override
  String get tplMeetingDecisions => 'Keputusan';

  @override
  String get tplMeetingActions => 'Siapa, apa, kapan';

  @override
  String get tplExpenseColumns => 'Tanggal · Keterangan · Jumlah';

  @override
  String get tplExpenseTotal => 'Total:';

  @override
  String get tplReadingSource => 'Sumber';

  @override
  String get tplReadingSummary => 'Ringkasan';

  @override
  String get tplReadingQuotes => 'Kutipan';

  @override
  String get tplReadingThoughts => 'Pendapatku';

  @override
  String get archiveDeletePage => 'Hapus halaman';

  @override
  String get archivePrevPage => 'Halaman sebelumnya';

  @override
  String get archiveNextPage => 'Halaman berikutnya';

  @override
  String get archiveCopyHere => 'Kumpulkan ke buku catatan';

  @override
  String get archiveNoNotebook => 'Belum ada buku catatan. Buat dulu.';

  @override
  String get archiveNothingToCopy =>
      'Catatan ini tidak punya lampiran untuk disalin.';

  @override
  String archiveCopied(int count) {
    return '$count file dikumpulkan ke buku catatan.';
  }

  @override
  String get attachmentTagInserted => 'Tag lampiran disisipkan.';

  @override
  String get attachmentTagPreview => 'Pratinjau lampiran';

  @override
  String get attachmentTagEdit => 'Edit lampiran';

  @override
  String archiveCardSummary(int files, int texts) {
    return '$files file · $texts teks';
  }

  @override
  String get archivePaper => 'Kertas';

  @override
  String get archivePaperLined => 'Bergaris';

  @override
  String get archivePaperGrid => 'Kotak-kotak';

  @override
  String get archivePaperDots => 'Bertitik';

  @override
  String get archivePaperPlain => 'Polos';

  @override
  String get archivePaperLegal => 'Legal pad';

  @override
  String get archivePaperEngineering => 'Teknik';

  @override
  String get archivePaperIsometric => 'Isometrik';

  @override
  String get attachmentTagEmbed => 'Sematkan dalam teks';

  @override
  String get bubbleModeBubble => 'Gelembung';

  @override
  String get attachmentTagEmbedInfo =>
      'Tautan ke teks yang kamu pilih, atau di kursor jika tidak ada yang dipilih';

  @override
  String get attachmentTagLinkHere => 'Tautkan di sini';

  @override
  String attachmentTagPendingBanner(String name) {
    return '$name akan ditautkan — pilih teksnya';
  }

  @override
  String get docNameNotesSuffix => 'catatan';

  @override
  String get docNamePhoto => 'Catatan foto';

  @override
  String get docNameScan => 'Catatan pindaian';

  @override
  String get docNameImage => 'Catatan gambar';

  @override
  String get docNameVideo => 'Catatan video';

  @override
  String get folderEmpty => 'Belum ada catatan di sini';

  @override
  String folderNoteCount(int count) {
    return '$count catatan';
  }

  @override
  String get folderCardEmpty => 'Kosong';

  @override
  String get folderEmptyHint =>
      'Tambahkan catatan lewat + di bawah, atau pindahkan catatan ke sini saat mengeditnya.';

  @override
  String get folderShared => 'Folder ini dibagikan dengan teman';

  @override
  String get friendsTitle => 'Kontak';

  @override
  String get friendsAdd => 'Tambah teman';

  @override
  String get friendsEmpty =>
      'Tambahkan teman lewat email untuk berbagi folder.';

  @override
  String get friendsRequestsTitle => 'Permintaan';

  @override
  String get friendsListTitle => 'Temanku';

  @override
  String get friendsSendRequest => 'Kirim permintaan';

  @override
  String get friendsRequestSent => 'Permintaan terkirim';

  @override
  String get friendsNotFound =>
      'Tidak ada pengguna terdaftar dengan email ini. Ia perlu pernah membuka aplikasi dengan akun Google setidaknya sekali.';

  @override
  String get friendsSelf => 'Kamu tidak bisa menambahkan dirimu sendiri';

  @override
  String get friendsAlready => 'Kalian sudah berteman';

  @override
  String get friendsDecline => 'Tolak';

  @override
  String get friendsAccept => 'Terima';

  @override
  String get friendsRemove => 'Hapus';

  @override
  String get friendsRemoveConfirmTitle => 'Hapus teman';

  @override
  String friendsRemoveConfirmBody(Object name) {
    return 'Hapus $name dari temanmu? Folder yang kamu bagikan dengannya tidak akan terlihat lagi.';
  }

  @override
  String get friendsSearchHint => 'Nama (3+ huruf) atau email lengkap';

  @override
  String get friendsSearchEmpty => 'Tidak ada hasil';

  @override
  String get friendsSearchTooShort =>
      'Ketik minimal 3 huruf atau email lengkap untuk mencari';

  @override
  String get friendsSearchAdd => 'Tambah';

  @override
  String get folderShare => 'Edit bersama';

  @override
  String folderShareCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dibagikan dengan $count orang',
      one: 'Dibagikan dengan 1 orang',
    );
    return '$_temp0';
  }

  @override
  String folderShareTitle(Object name) {
    return 'Bagikan \"$name\"';
  }

  @override
  String get folderShareInfo =>
      'Undangan dikirim ke teman yang kamu pilih; ia melihat folder setelah menerima. Kamu menentukan izinnya (baca / tulis / keduanya).';

  @override
  String get friendsRowInfo => 'Tambah teman, bagikan folder dengan mereka';

  @override
  String get accountRecoverConflictTitle =>
      'Perangkat ini punya catatan yang belum tersimpan';

  @override
  String accountRecoverConflictBody(Object count) {
    return 'Akun Google ini sudah tertaut ke sesi lain; beralih ke akun itu akan menyembunyikan $count catatan di perangkat ini (tidak dihapus, hanya tidak bisa dijangkau dari sini). Tetap lanjutkan?';
  }

  @override
  String get accountRecoverConflictProceed => 'Tetap beralih';

  @override
  String get folderRoleRead => 'Baca';

  @override
  String get folderRoleWrite => 'Tulis';

  @override
  String get folderRoleBoth => 'Baca + tulis';

  @override
  String get folderInvitePending => 'Undangan terkirim, menunggu jawaban';

  @override
  String get folderWriteOnlyTitle => 'Kamu hanya punya akses tulis';

  @override
  String get folderWriteOnlyHint =>
      'Kamu bisa menambahkan catatan baru ke folder ini tetapi tidak bisa melihat catatan di dalamnya.';

  @override
  String get folderChatTitle => 'Obrolan';

  @override
  String get folderChatHint => 'Tulis pesan…';

  @override
  String get folderChatSend => 'Kirim';

  @override
  String get folderChatEmptyTitle => 'Belum ada pesan di sini';

  @override
  String get folderChatEmptyHint =>
      'Mengobrol di sini dengan orang yang kamu ajak berbagi folder ini.';

  @override
  String get folderInviteTitle => 'Undangan folder';

  @override
  String folderInviteBody(Object name) {
    return 'Folder \"$name\" dibagikan denganmu.';
  }

  @override
  String get folderInviteAccepted => 'Folder ditambahkan';

  @override
  String get folderInviteDeclined => 'Undangan ditolak';

  @override
  String friendRequestBanner(Object name) {
    return '$name mengirimimu permintaan pertemanan';
  }

  @override
  String get friendRequestAccepted => 'Teman ditambahkan';

  @override
  String get sendNoteTitle => 'Kirim catatan ke teman';

  @override
  String get sendNoteInfo =>
      'Salinan catatan masuk ke kotak \"Catatan masuk\" milik orang itu. Lampiran (gambar, dokumen, audio) tidak dikirim.';

  @override
  String sendNoteSent(Object name) {
    return 'Catatan dikirim ke $name';
  }

  @override
  String get inboxTitle => 'Catatan masuk';

  @override
  String get inboxEmpty => 'Tidak ada catatan masuk di sini';

  @override
  String get inboxEmptyHint =>
      'Catatan yang dikirim temanmu terkumpul di sini.';

  @override
  String inboxFrom(Object name) {
    return 'Dikirim oleh $name';
  }

  @override
  String get inboxAccept => 'Tambahkan ke catatanku';

  @override
  String get inboxAccepted => 'Catatan ditambahkan ke catatanmu';

  @override
  String get folderShelfCollapse => 'Ciutkan folder';

  @override
  String get accountSheetLocalInfo =>
      'Catatanmu hanya ada di perangkat ini. Tautkan akun Google untuk mencadangkannya dan menambah teman.';

  @override
  String get accountSettings => 'Pengaturan akun';

  @override
  String get videoFramesExtracting => 'Mengambil bingkai dari video…';

  @override
  String get areaSelect => 'Pilih area';

  @override
  String get areaSelectOff => 'Matikan pilih area';

  @override
  String get areaSelectHint =>
      'Seret kotak di sekitar yang ingin kamu salin atau tanyakan ke AI.';

  @override
  String get areaCopyImage => 'Salin sebagai gambar';

  @override
  String get areaCopied => 'Area terpilih disalin ke papan klip.';

  @override
  String get areaAskTitle => 'Area terpilih';

  @override
  String get areaCaptureFailed => 'Tidak dapat menangkap area terpilih.';

  @override
  String get areaTooSmall => 'Area terpilih terlalu kecil.';

  @override
  String get bubbleTextFill => 'Latar teks';

  @override
  String get bubbleTextFillNone => 'Tanpa latar';

  @override
  String get bubbleTextAlignLeft => 'Rata kiri';

  @override
  String get bubbleTextAlignCenter => 'Rata tengah';

  @override
  String get bubbleTextAlignRight => 'Rata kanan';

  @override
  String get dashboardBackgroundPattern => 'Pola';

  @override
  String get dashboardBackgroundColor => 'Warna latar';

  @override
  String get dashboardBackgroundReset => 'Kembalikan ke bawaan';

  @override
  String get patternNone => 'Polos';

  @override
  String get patternDots => 'Titik';

  @override
  String get patternGrid => 'Kisi';

  @override
  String get patternLines => 'Garis';

  @override
  String get patternDiagonal => 'Diagonal';

  @override
  String get patternGraph => 'Kertas grafik';

  @override
  String get sharedNotifications => 'Notifikasi folder bersama';

  @override
  String get sharedNotificationsInfo =>
      'Dapat notifikasi saat catatan bersama ditambah, diubah, atau dikirimi pesan.';

  @override
  String get copyAsText => 'Salin teks';

  @override
  String get searchAttachments => 'Cari di dalam lampiran';

  @override
  String get searchAttachmentsInfo =>
      'Juga mencari teks PDF dan teks di dalam gambar.';

  @override
  String get selectAll => 'Pilih semua';

  @override
  String get selectNone => 'Hapus pilihan';

  @override
  String get duplicateNote => 'Duplikat catatan';

  @override
  String get noteDuplicated => 'Catatan diduplikat';

  @override
  String notesDuplicatedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count catatan diduplikat',
      one: '1 catatan diduplikat',
    );
    return '$_temp0';
  }

  @override
  String get noteStatsTitle => 'Statistik catatan';

  @override
  String noteStatsWords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kata',
      one: '1 kata',
    );
    return '$_temp0';
  }

  @override
  String noteStatsChars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count karakter',
      one: '1 karakter',
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
    return '~$count menit baca';
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
  String get clearSearch => 'Hapus pencarian';

  @override
  String trashDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dihapus permanen dalam $count hari',
      one: 'Dihapus permanen dalam 1 hari',
    );
    return '$_temp0';
  }

  @override
  String get trashLastDay => 'Akan dihapus permanen hari ini';

  @override
  String get noteRestored => 'Catatan dipulihkan';

  @override
  String get restoreAll => 'Pulihkan semua';

  @override
  String notesRestoredCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count catatan dipulihkan',
      one: '1 catatan dipulihkan',
    );
    return '$_temp0';
  }

  @override
  String get reminderRemoved => 'Pengingat dihapus';

  @override
  String get reminderOverdue => 'Terlewat';

  @override
  String get reminderQuickTonight => 'Malam ini 18.00';

  @override
  String get reminderQuickTomorrow => 'Besok 09.00';

  @override
  String get reminderQuickNextWeek => 'Minggu depan';

  @override
  String get reminderSnooze => 'Tunda 1 jam';

  @override
  String get reminderSnoozed => 'Pengingat ditunda';

  @override
  String reminderCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pengingat',
      one: '1 pengingat',
    );
    return '$_temp0';
  }

  @override
  String get relativeJustNow => 'baru saja';

  @override
  String relativeInMinutes(int count) {
    return 'dalam $count mnt';
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
    return '$count mnt lalu';
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
  String get inboxDeclined => 'Catatan masuk dihapus';

  @override
  String inboxCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count catatan masuk',
      one: '1 catatan masuk',
    );
    return '$_temp0';
  }

  @override
  String get appVersion => 'Versi aplikasi';

  @override
  String get appVersionCopied => 'Info versi disalin';

  @override
  String notesMovedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count catatan dipindahkan',
      one: '1 catatan dipindahkan',
    );
    return '$_temp0';
  }

  @override
  String get mediaPlay => 'Putar';

  @override
  String get mediaPause => 'Jeda';

  @override
  String get decrease => 'Kurangi';

  @override
  String get increase => 'Tambah';

  @override
  String get tagManageTitle => 'Kelola tag';

  @override
  String get tagRename => 'Ganti nama tag';

  @override
  String get tagRenameHint => 'Nama tag baru';

  @override
  String get tagDelete => 'Hapus tag';

  @override
  String tagDeleteConfirm(String tag) {
    return 'Hapus tag \"$tag\" dari semua catatan? Catatannya tetap ada.';
  }

  @override
  String get tagRenamed => 'Nama tag diganti';

  @override
  String get tagDeleted => 'Tag dihapus';

  @override
  String get tagLongPressHint =>
      'Tekan lama tag untuk mengganti nama atau menghapusnya.';

  @override
  String get recentSearches => 'Pencarian terbaru';

  @override
  String get clearRecentSearches => 'Hapus riwayat';

  @override
  String get imagesEqualizeSize => 'Samakan ukuran';

  @override
  String get imagesFitRow => 'Sesuaikan ke baris';

  @override
  String imagesFitColumns(int count) {
    return '$count kolom';
  }

  @override
  String get imagesFitSingleRow => 'Muat dalam satu baris';

  @override
  String get reminderDone => 'Selesai';

  @override
  String get dateToday => 'Hari ini';

  @override
  String get dateTomorrow => 'Besok';

  @override
  String get noteDuplicatedNoAttachments => 'Diduplikat — lampiran tidak ikut';

  @override
  String get pdfGoToPage => 'Buka halaman';

  @override
  String get pdfThumbnails => 'Telusuri halaman';

  @override
  String get pdfBookmarks => 'Penanda';

  @override
  String get pdfBookmarkAdd => 'Tambah penanda';

  @override
  String get pdfBookmarkRemove => 'Hapus penanda';

  @override
  String get pdfNoBookmarks =>
      'Belum ada penanda. Ketuk tombol penanda di bilah halaman.';

  @override
  String get pdfRotateView => 'Putar tampilan';

  @override
  String get pdfCopyPageText => 'Salin teks halaman';

  @override
  String get pdfCapturePage => 'Tangkap halaman (AI / salin)';

  @override
  String get pdfSlideshow => 'Maju otomatis';

  @override
  String get pdfSlideshowStop => 'Hentikan maju otomatis';

  @override
  String get pdfFirstPage => 'Halaman pertama';

  @override
  String get pdfLastPage => 'Halaman terakhir';

  @override
  String get collaborators => 'Kolaborator';

  @override
  String get collaboratorsInfo =>
      'Orang yang kamu tambahkan melihat catatan ini di beranda mereka dan mengeditnya bersamamu secara langsung.';

  @override
  String get collaboratorsOwner => 'Pemilik';

  @override
  String get collaboratorsFriendsTitle => 'Temanmu';

  @override
  String get collaboratorsLeave => 'Keluar dari catatan bersama';

  @override
  String get collaboratorsLeaveConfirm =>
      'Catatan ini tidak akan muncul lagi di berandamu. Keluar?';

  @override
  String get collaboratorsSaved => 'Berbagi diperbarui';

  @override
  String get collaboratorsOnlyOwner =>
      'Hanya pemilik catatan yang bisa mengubah kolaborator.';

  @override
  String sharedByName(Object name) {
    return 'Dibagikan oleh $name';
  }

  @override
  String get navNotes => 'Catatan';

  @override
  String get railExpand => 'Perluas menu';

  @override
  String get railCollapse => 'Ciutkan menu';

  @override
  String get newNoteShort => 'Catatan baru';

  @override
  String get listPaneHide => 'Sembunyikan daftar catatan';

  @override
  String get listPaneShow => 'Tampilkan daftar catatan';

  @override
  String get keyboardShortcuts => 'Pintasan keyboard';

  @override
  String get shortcutSearch => 'Cari catatan';

  @override
  String get shortcutToggleList => 'Sembunyikan / tampilkan daftar catatan';

  @override
  String get shortcutSections => 'Beralih antar bagian';

  @override
  String get shortcutHelp => 'Tampilkan pintasan';

  @override
  String get shortcutFullscreen => 'Alihkan layar penuh catatan';

  @override
  String get shortcutEscape => 'Keluar dari layar penuh, lalu tutup catatan';

  @override
  String get showNoteList => 'Tampilkan daftar catatan';

  @override
  String get shortcutSwitchFolder => 'Ganti folder';

  @override
  String get shortcutMouseWheel => 'roda';

  @override
  String get shortcutGridColumns => 'Jumlah kolom';

  @override
  String get shortcutSelectAll => 'Saat memilih: pilih semua';

  @override
  String get shortcutDeleteSelected => 'Pindahkan yang dipilih ke sampah';

  @override
  String get sharedFolderNoFileDrop =>
      'File tidak bisa dilepas ke folder bersama. Buka catatan dan lepaskan file di sana.';

  @override
  String get shortcutAdjacentNote =>
      'Catatan sebelumnya / berikutnya di daftar';

  @override
  String get shortcutCloseNote => 'Tutup catatan';

  @override
  String get softKeyboardShow =>
      'Tampilkan keyboard layar (keyboard fisik terhubung)';

  @override
  String get softKeyboardHide => 'Sembunyikan keyboard layar';

  @override
  String get goHome => 'Kembali ke beranda';

  @override
  String get loginFeatureSyncTitle => 'Catatan yang sama di semua perangkat';

  @override
  String get loginFeatureSyncBody =>
      'Sinkronisasi instan di ponsel, tablet, komputer, dan web.';

  @override
  String get loginFeatureAiTitle => 'Pengaturan cerdas';

  @override
  String get loginFeatureAiBody =>
      'Dikte suara cepat, pemeriksa ejaan offline, lorong belanja cerdas, dan tag.';

  @override
  String get loginFeatureShareTitle => 'Menulis bersama';

  @override
  String get loginFeatureShareBody =>
      'Bagikan catatan dan folder secara langsung dengan teman.';

  @override
  String get loginFeatureInkTitle => 'Pena dan PDF';

  @override
  String get loginFeatureInkBody =>
      'Buat catatan tulisan tangan, tulis di PDF dan slide.';

  @override
  String get foldersTitle => 'Folder';

  @override
  String get foldersEmpty =>
      'Belum ada folder. Buat satu untuk mengatur catatanmu.';

  @override
  String get foldersEmptyTitle => 'Belum ada folder di sini';

  @override
  String get foldersEmptyHint => 'Buat satu untuk mengatur catatanmu.';

  @override
  String get folderColor => 'Warna';

  @override
  String get folderColorAuto => 'Otomatis';

  @override
  String get foldersMine => 'Folderku';

  @override
  String get foldersSharedSection => 'Folder bersama';

  @override
  String trashDaysShort(int count) {
    return '$count h';
  }

  @override
  String get trashTodayShort => 'Hari ini';

  @override
  String get trashSoonSection => 'Segera dihapus permanen';

  @override
  String get trashRestSection => 'Catatan terhapus lainnya';

  @override
  String get folderOrderTitle => 'Urutan folder';

  @override
  String get folderReorder => 'Atur ulang folder';

  @override
  String get folderOrderManual => 'Kustom';

  @override
  String get folderOrderName => 'Menurut nama';

  @override
  String get folderOrderNewest => 'Terbaru dulu';

  @override
  String get folderOrderNoteCount => 'Menurut jumlah catatan';

  @override
  String get folderOrderHint =>
      'Seret pegangan untuk mengatur ulang (menyeret beralih ke \"Manual\"). Urutan ini juga dipakai di strip folder dan saat menggeser.';

  @override
  String get swipeModeTitle => 'Geser kiri/kanan di beranda';

  @override
  String get swipeModeFolders => 'Beralih antar folder';

  @override
  String get swipeModeFilters => 'Beralih antar filter dan tag';

  @override
  String get swipeModeBoth => 'Folder, filter, dan tag';

  @override
  String get swipeModeOff => 'Mati';

  @override
  String get shareIncludeTitle => 'Judul';

  @override
  String get shareIncludeChecked => 'Item selesai';

  @override
  String get shareIncludeTags => 'Tag';

  @override
  String get shareTextAction => 'Bagikan teks';

  @override
  String get findPrevious => 'Hasil sebelumnya';

  @override
  String get findNext => 'Hasil berikutnya';

  @override
  String get findShowAll => 'Semua hasil';

  @override
  String findMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hasil',
      one: '1 hasil',
      zero: 'Tidak ada hasil',
    );
    return '$_temp0';
  }

  @override
  String get findDeepSearch => 'Cari lampiran & AI';

  @override
  String get notesSettingsTitle => 'Catatan & folder';

  @override
  String get noteViewSetting => 'Tata letak beranda';

  @override
  String get noteViewGrid => 'Kisi';

  @override
  String get noteViewList => 'Daftar';

  @override
  String get gridColumnsSetting => 'Kolom';

  @override
  String get gridColumnsInfo =>
      'Kamu juga bisa mencubit di beranda untuk mengubahnya.';

  @override
  String get gridColumnsAuto => 'Otomatis';

  @override
  String get folderShelfSetting => 'Folder di beranda';

  @override
  String get folderShelfStrip => 'Satu baris';

  @override
  String get folderShelfTiles => 'Ubin';

  @override
  String get deviceStorageTitle => 'Di perangkat ini';

  @override
  String get deviceStorageAttachments => 'Lampiran';

  @override
  String get deviceStorageDatabase => 'Salinan lokal catatan';

  @override
  String get deviceStorageCache => 'Cache dan file sementara';

  @override
  String get deviceStorageAi => 'Cache AI';

  @override
  String get deviceStorageTotal => 'Total (tidak termasuk aplikasinya)';

  @override
  String get deviceStorageInfo =>
      'Menghapus cache tidak menghapus catatan atau lampiran.';

  @override
  String get deviceStorageClear => 'Hapus cache';

  @override
  String deviceStorageCleared(String size) {
    return '$size dikosongkan';
  }

  @override
  String get deviceStorageUnavailable => 'Tidak dapat diukur di perangkat ini.';

  @override
  String get localOnlyTurnOn => 'Hentikan sinkronisasi';

  @override
  String get localOnlyTurnOff => 'Sinkronkan catatan ini';

  @override
  String get localOnlyBadge => 'Hanya di perangkat ini';

  @override
  String get localOnlyConfirmTitle =>
      'Simpan catatan ini hanya di perangkat ini?';

  @override
  String get localOnlyConfirmBody =>
      'Catatan dan lampirannya dihapus dari cloud dan tidak akan muncul di perangkatmu yang lain. Jika aplikasi dihapus atau ganti ponsel, catatan ini ikut hilang. Kamu bisa menyalakan sinkronisasi lagi kapan saja.';

  @override
  String get localOnlyConfirm => 'Hentikan sinkronisasi';

  @override
  String get localOnlyOnDone => 'Catatan kini hanya di perangkat ini';

  @override
  String get localOnlyOffDone => 'Catatan disinkronkan lagi';

  @override
  String get localOnlySharedBlocked =>
      'Sinkronisasi tidak bisa dimatikan untuk catatan bersama';

  @override
  String get localOnlyDownloadFailed =>
      'Beberapa lampiran tidak dapat diunduh ke perangkat ini. Periksa koneksi lalu coba lagi; catatan tidak berubah.';

  @override
  String get templatesTitle => 'Templat';

  @override
  String get templatesSubtitle =>
      'Mulai dengan tata letak siap; kamu bisa mengubah semuanya nanti.';

  @override
  String get fromTemplate => 'Templat siap pakai';

  @override
  String get tplShoppingName => 'Daftar belanja';

  @override
  String get tplShoppingItems => 'Roti, Susu, Telur, Buah, Sayur';

  @override
  String get tplShoppingDesc =>
      'Centang yang sudah dibeli; akan pindah ke bawah';

  @override
  String get tplTodoDesc => 'Daftar kosong dengan tanggal hari ini';

  @override
  String get tplTravelName => 'Daftar bawaan';

  @override
  String get tplTravelItems =>
      'KTP / paspor, Pengisi daya ponsel, Obat-obatan, Sikat gigi, Pakaian, Headphone';

  @override
  String get tplTravelDesc => 'Daftar centang siap';

  @override
  String get tplMeetingDesc => 'Peserta, agenda, keputusan';

  @override
  String get tplJournalDesc => 'Bagaimana hari ini, syukur, besok';

  @override
  String get tplRecipeName => 'Resep';

  @override
  String get tplRecipeMeta => 'Porsi: · Waktu:';

  @override
  String get tplRecipeIngredients => 'Bahan';

  @override
  String get tplRecipeSteps => 'Langkah';

  @override
  String get tplRecipeNotes => 'Catatan';

  @override
  String get tplRecipeDesc => 'Bahan dan langkah';

  @override
  String get tplWeeklyName => 'Rencana mingguan';

  @override
  String get tplWeeklyDesc => 'Hari-hari minggu ini sebagai judul';

  @override
  String get tplExpenseDesc => 'Tanggal, keterangan, jumlah';

  @override
  String get tplReadingDesc => 'Sumber, ringkasan, kutipan';

  @override
  String get settingsThemeHeader => 'Tema';

  @override
  String get settingsGroupPrivacyNotify => 'Privasi dan notifikasi';

  @override
  String get settingsGroupText => 'Teks';

  @override
  String get settingsGroupDictation => 'Mengetik dengan suara';

  @override
  String get settingsGroupGestures => 'Gestur';

  @override
  String get settingsGroupSortView => 'Urutan dan tata letak';

  @override
  String get settingsGroupShared => 'Catatan bersama';

  @override
  String get settingsGroupAttachments => 'Lampiran';

  @override
  String get settingsGroupBackup => 'Cadangan';

  @override
  String get settingsGroupSession => 'Sesi';

  @override
  String get settingsSecurityTitle => 'Keamanan';

  @override
  String get settingsSecuritySummary => 'Kunci catatan, kunci aplikasi';

  @override
  String get settingsGroupAbout => 'Tentang';

  @override
  String get settingsGroupVersion => 'Versi';

  @override
  String get settingsCardsHeader => 'Kartu dan daftar';

  @override
  String get shareTargetTitle => 'Tambahkan ke Catatan';

  @override
  String get shareTargetNew => 'Catatan baru';

  @override
  String get shareTargetExisting => 'Catatan yang ada';

  @override
  String get shareTargetCreate => 'Buat catatan';

  @override
  String get shareTargetSearch => 'Cari catatan';

  @override
  String get shareTargetNoNotes => 'Tidak ada catatan untuk ditambahkan';

  @override
  String get shareTargetNoMatch => 'Tidak ada catatan yang cocok';

  @override
  String shareTargetMore(int count) {
    return '+$count file';
  }

  @override
  String get sharePreviewExpand => 'Perluas pratinjau';

  @override
  String get sharePreviewCollapse => 'Ciutkan pratinjau';

  @override
  String get templatesSearch => 'Cari templat';

  @override
  String get templatesAll => 'Semua';

  @override
  String get templatesLists => 'Daftar';

  @override
  String get templatesPlanning => 'Perencanaan';

  @override
  String get templatesWriting => 'Menulis';

  @override
  String get templatesMine => 'Templatku';

  @override
  String get templatesRecent => 'Baru dipakai';

  @override
  String get templatesNoMatch => 'Tidak ada templat yang cocok';

  @override
  String get templatesMineEmpty =>
      'Kamu belum punya templat. Pilih “Simpan sebagai templat” dari menu catatan dan akan muncul di sini.';

  @override
  String get templatesMineInfo => 'Templatmu';

  @override
  String get templateRename => 'Ganti nama';

  @override
  String get templateDelete => 'Hapus templat';

  @override
  String get templateNameTitle => 'Nama templat';

  @override
  String get templateNameHint => 'mis. Belanja mingguan';

  @override
  String get templateSave => 'Simpan';

  @override
  String templateSaved(String name) {
    return '“$name” ditambahkan ke templatmu';
  }

  @override
  String get saveAsTemplate => 'Simpan sebagai templat';

  @override
  String get templateCreate => 'Buat';

  @override
  String get templateListChecks => 'Kotak centang';

  @override
  String get templateListNumbers => 'Bernomor';

  @override
  String get templateAddItem => 'Tambah item';

  @override
  String get tplShopProduce => 'Buah dan sayur';

  @override
  String get tplShopProduceItems =>
      'Tomat, Mentimun, Bawang, Kentang, Lemon, Pisang, Apel, Peterseli';

  @override
  String get tplShopBreakfast => 'Sarapan';

  @override
  String get tplShopBreakfastItems =>
      'Keju, Zaitun, Mentega, Madu, Selai, Yoghurt';

  @override
  String get tplShopPantry => 'Bahan pokok';

  @override
  String get tplShopPantryItems =>
      'Beras, Pasta, Tepung, Gula, Minyak zaitun, Kacang lentil, Teh, Kopi';

  @override
  String get tplShopCleaning => 'Kebersihan';

  @override
  String get tplShopCleaningItems =>
      'Sabun cuci piring, Deterjen, Tisu toilet, Tisu dapur, Kantong sampah';

  @override
  String get tplShopPersonal => 'Perawatan pribadi';

  @override
  String get tplShopPersonalItems => 'Sampo, Pasta gigi, Sabun, Deodoran';

  @override
  String get tplTravelDocs => 'Dokumen';

  @override
  String get tplTravelDocsItems =>
      'Tiket, Pemesanan hotel, SIM, Asuransi perjalanan, Uang tunai / kartu';

  @override
  String get tplTravelClothes => 'Pakaian';

  @override
  String get tplTravelClothesItems =>
      'Kaus, Celana, Pakaian dalam, Kaus kaki, Piyama, Jaket, Sepatu';

  @override
  String get tplTravelCare => 'Perlengkapan mandi';

  @override
  String get tplTravelCareItems =>
      'Pasta gigi, Sampo, Tabir surya, Alat cukur, Deodoran';

  @override
  String get tplTravelTech => 'Elektronik';

  @override
  String get tplTravelTechItems =>
      'Power bank, Adaptor colokan, Headphone, Kabel';

  @override
  String get tplHabitsName => 'Pelacak kebiasaan';

  @override
  String get tplHabitsDesc => 'Centang setiap hari, jangan putuskan rantainya';

  @override
  String get tplHabitsItems =>
      '8 gelas air, Jalan 30 menit, Baca 20 halaman, Tidur lebih awal, Satu jam tanpa layar';

  @override
  String get tplCleaningName => 'Bersih-bersih rumah';

  @override
  String get tplCleaningDesc => 'Daftar centang bersih-bersih mingguan';

  @override
  String get tplCleaningItems =>
      'Bersihkan debu, Sedot debu, Pel lantai, Bersihkan kamar mandi, Meja dapur, Cucian, Buang sampah, Ganti seprai';

  @override
  String get tplMovingName => 'Daftar pindahan';

  @override
  String get tplMovingDesc => 'Hal yang dilakukan sebelum dan sesudah pindah';

  @override
  String get tplMovingItems =>
      'Pesan jasa pindahan, Beli kardus dan lakban, Perbarui alamat, Akun listrik / air / gas, Pindahkan internet, Serahkan kunci';

  @override
  String get tplGiftsName => 'Daftar hadiah';

  @override
  String get tplGiftsDesc => 'Siapa dapat apa, ide';

  @override
  String get tplGiftsItems => 'Ibu, Ayah, Saudara, Teman';

  @override
  String get tplWatchlistName => 'Daftar tontonan';

  @override
  String get tplWatchlistDesc => 'Film, serial, dan buku yang ingin dinikmati';

  @override
  String get tplWorkoutName => 'Latihan';

  @override
  String get tplWorkoutDesc =>
      'Daftar latihan dari pemanasan hingga peregangan';

  @override
  String get tplWorkoutItems =>
      'Pemanasan 5 menit, Squat 3×12, Push-up 3×10, Crunch 3×15, Plank 3×45 dtk, Peregangan 5 menit';

  @override
  String get tplGoalsName => 'Tujuan';

  @override
  String get tplGoalsDesc => 'Tujuan tahun, bulan, dan minggu';

  @override
  String get tplGoalsYear => 'Tahun ini';

  @override
  String get tplGoalsMonth => 'Bulan ini';

  @override
  String get tplGoalsWeek => 'Minggu ini';

  @override
  String get tplGoalsWhy => 'Mengapa penting?';

  @override
  String get templateNew => 'Templat baru';

  @override
  String get templateEdit => 'Edit templat';

  @override
  String get templateDuplicate => 'Duplikat';

  @override
  String get templateSaveAsMine => 'Simpan ke templatku';

  @override
  String get templateUntitled => 'Templat tanpa judul';

  @override
  String get templateTypeText => 'Teks';

  @override
  String get templateTitleHelp =>
      'Judul catatan yang dibuat dari templat ini (opsional)';

  @override
  String get templateBody => 'Teks';

  @override
  String get templateHeadingHelp =>
      'Baris yang diawali “# ” menjadi judul, “## ” subjudul.';

  @override
  String get templateDiscardTitle => 'Buang perubahan?';

  @override
  String get templateDiscard => 'Buang';

  @override
  String templateDeleted(String name) {
    return '“$name” dihapus';
  }

  @override
  String get addVideoFromGallery => 'Video dari galeri';

  @override
  String get addYouTubeVideo => 'Video YouTube';

  @override
  String get addYouTubeVideoSubtitle =>
      'Diputar di catatan, tonton di jendela kecil';

  @override
  String get youTubeLinkHelp =>
      'Tempel tautan video YouTube (youtube.com atau youtu.be).';

  @override
  String get youTubeInvalidLink => 'Ini bukan tautan video YouTube';

  @override
  String get youTubeOpenInBrowserInfo =>
      'Video tidak bisa diputar di aplikasi pada perangkat ini; bisa dibuka di browser.';

  @override
  String get youTubeOpenExternal => 'Buka di YouTube';

  @override
  String get pictureInPicture => 'Gambar-dalam-gambar';

  @override
  String get pinMediaRelease => 'Lepas: sematkan di atas (catatan di bawah)';

  @override
  String get unpinMediaRelease => 'Lepas: Mengambang';

  @override
  String get pinnedMediaResize => 'Tinggi panel — seret untuk mengubah';

  @override
  String pageOf(int current, int total) {
    return 'Halaman $current / $total';
  }

  @override
  String pageAdded(int page) {
    return 'Halaman $page ditambahkan';
  }

  @override
  String get deletePageConfirm =>
      'Hapus teks halaman ini? Gambarnya pindah ke halaman sebelah. Kamu bisa mengembalikannya dengan Urungkan.';

  @override
  String get embedNewPdf => 'PDF';

  @override
  String get embedNewImage => 'Gambar';

  @override
  String get embedNewVideo => 'Video';

  @override
  String get embedNewYouTube => 'YouTube';

  @override
  String get embedPickTitle => 'Apa yang ingin disematkan?';

  @override
  String get embedPickInfo =>
      'Ketuk teks untuk membuka item yang disematkan di tempat.';

  @override
  String get embedSectionNew => 'Tambah baru';

  @override
  String get embedSectionExisting => 'Lampiran di catatan ini';

  @override
  String get embedSectionLink => 'Tautan';

  @override
  String get embedLinkHint => 'Alamat web (mis. contoh.com)';

  @override
  String get embedLinkApply => 'Tautkan';

  @override
  String get embedReplace => 'Ganti';

  @override
  String get embedRemove => 'Hapus sematan';

  @override
  String get embedRemoved => 'Sematan dihapus';

  @override
  String get guideTitle => 'Panduan pengguna';

  @override
  String get guideMenuInfo => 'Setiap fitur, langkah demi langkah';

  @override
  String get guideSearchHint => 'Cari panduan — “halaman”, “YouTube”';

  @override
  String get guideOpenScreen => 'Tunjukkan';

  @override
  String guideNoResults(String query) {
    return 'Tidak ada hasil untuk “$query”';
  }

  @override
  String get copyVideoLink => 'Salin tautan';

  @override
  String get videoLinkCopied => 'Tautan disalin';

  @override
  String get menuSectionOrganize => 'Atur';

  @override
  String get menuSectionCopy => 'Salin';

  @override
  String get menuSectionTools => 'Alat';

  @override
  String get menuSectionProtect => 'Perlindungan dan penyimpanan';

  @override
  String get menuSectionApp => 'Aplikasi';

  @override
  String cardMoreFiles(int count) {
    return '+$count file lagi';
  }

  @override
  String cardAudioCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rekaman suara',
      one: 'Rekaman suara',
    );
    return '$_temp0';
  }

  @override
  String get cardBubbleDocument => 'PDF DENGAN GELEMBUNG';

  @override
  String get cardBubbleSlides => 'SLIDE DENGAN GELEMBUNG';

  @override
  String get cardKindPdf => 'PDF';

  @override
  String get cardKindSlides => 'SLIDE';

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
  String get docViewToBubbles => 'Beralih ke tampilan gelembung';

  @override
  String get docViewToClassic => 'Beralih ke tampilan klasik';

  @override
  String get docViewSwitchedBubbles =>
      'Tampilan gelembung: dokumen di atas, catatan halaman di bawah. Tata letak klasikmu tetap tersimpan.';

  @override
  String get docViewSwitchedClassic =>
      'Tampilan klasik: dokumen menjadi lampiran di halaman. Gelembung dan catatan halaman tetap tersimpan.';

  @override
  String get docViewTextKept => 'Teks catatan tetap di tampilan klasik.';

  @override
  String get captureModeChangeLater =>
      'Kamu bisa beralih nanti dengan chip Gelembung / Klasik di catatan.';

  @override
  String get attachmentSyncTitle => 'Sinkronisasi lampiran';

  @override
  String get driveSectionTitle => 'Lampiran di Google Drive-mu';

  @override
  String get driveConnectTitle => 'Simpan lampiran di Google Drive-mu';

  @override
  String get driveConnectInfo =>
      'Gambar, PDF, slide, dan rekaman suara disimpan di penyimpanan Drive-mu sendiri, di folder “Notlar”, dan diunduh ke perangkatmu yang lain. Video tetap di perangkat.';

  @override
  String get driveConnect => 'Hubungkan';

  @override
  String get driveDisconnect => 'Putuskan';

  @override
  String get driveConnected =>
      'Google Drive terhubung — lampiran sedang dicadangkan.';

  @override
  String get driveConnectedInfo =>
      'Terhubung · lampiran ada di folder “Notlar” di Drive-mu';

  @override
  String driveUsage(String used, String limit) {
    return 'Drive: $used dari $limit terpakai';
  }

  @override
  String driveConnectFailed(String error) {
    return 'Tidak dapat menghubungkan Google Drive. $error';
  }

  @override
  String get driveApiDisabled =>
      'Drive API dinonaktifkan di proyek Google Cloud: aktifkan \"Google Drive API\" di konsol lalu coba lagi.';

  @override
  String get driveDisconnected =>
      'Drive terputus. Lampiran baru menunggu di perangkat sampai kamu menghubungkan lagi.';

  @override
  String get textOnlyTitle => 'Sinkronisasi teks saja';

  @override
  String get textOnlyInfo =>
      'Akun tamu hanya menyinkronkan teks; lampiran tetap di perangkat ini. Tautkan akun Google untuk menyimpan lampiran di Google Drive-mu.';

  @override
  String get storageModeInfo => 'Di web, lampiran diunggah ke cloud aplikasi.';

  @override
  String driveWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count lampiran menunggu Google Drive — ketuk untuk menghubungkan',
      one: '1 lampiran menunggu Google Drive — ketuk untuk menghubungkan',
    );
    return '$_temp0';
  }

  @override
  String get driveDownloading => 'Mengunduh lampiran dari Google Drive…';

  @override
  String get driveNeededForFile =>
      'Lampiran ini ada di Google Drive-mu. Hubungkan Drive di Pengaturan → Sinkronisasi untuk melihatnya.';

  @override
  String get bubbleDone => 'Selesai';

  @override
  String get bubbleEditShort => 'Edit';

  @override
  String get bubblePlainModeShort => 'Teks';

  @override
  String get pageBarMore => 'Opsi halaman dan catatan';

  @override
  String viewModeChanged(String from, String to) {
    return '$from → $to';
  }

  @override
  String get videoRotate => 'Putar gambar';

  @override
  String get viewModeTitle => 'Tampilan';

  @override
  String get viewModeEmbed => 'Sematkan dalam teks';

  @override
  String get viewModeEmbedHint =>
      'Sematkan lampiran ini di sebuah kata dalam catatan — mengetuk kata itu membukanya';

  @override
  String get viewModePinned => 'Disematkan';

  @override
  String get viewModeFloating => 'Mengambang';

  @override
  String get viewModeBubbles => 'Gelembung';

  @override
  String get viewModePinnedHint =>
      'Sematkan di atas — tetap di atas, catatan bergulir di bawah';

  @override
  String get viewModeFloatingHint =>
      'Mengambang di halaman — teks mengalir di sekitarnya';

  @override
  String get viewModeBubblesHint =>
      'Tampilan gelembung — gelembung, sorotan, dan pena di halaman';

  @override
  String get videoNoteAtTime => 'Catatan di momen ini';

  @override
  String get videoNoteAtTimeShort => 'Catatan';

  @override
  String get videoTimeUnknown =>
      'Tidak dapat membaca waktu video — putar videonya dulu.';

  @override
  String get videoSpeed => 'Kecepatan putar';

  @override
  String get videoLoop => 'Ulang';

  @override
  String get bubbleSmaller => 'Gelembung lebih kecil';

  @override
  String get bubbleLarger => 'Gelembung lebih besar';

  @override
  String get bubbleAllSmaller => 'Perkecil semua gelembung';

  @override
  String get bubbleAllLarger => 'Perbesar semua gelembung';

  @override
  String get bubblesShow => 'Tampilkan gelembung';

  @override
  String get bubblesHide => 'Sembunyikan gelembung';

  @override
  String get shareIncludeVideoLinks => 'Tautan video';

  @override
  String get shareQuickPdf => 'PDF';

  @override
  String get shareAsImage => 'Gambar';

  @override
  String shareAttachmentFiles(int count) {
    return 'File ($count)';
  }

  @override
  String get shareToFriendShort => 'Kirim ke teman';

  @override
  String get shareCollaborateShort => 'Edit bersama';

  @override
  String get shareAsNoteShort => 'Paket catatan';

  @override
  String get shareQuickPreparing => 'Menyiapkan…';

  @override
  String get shareAttachmentFilesNone =>
      'Tidak ada file lampiran di perangkat ini untuk dibagikan.';

  @override
  String get attachmentRemoved => 'Lampiran dihapus';

  @override
  String get customizeHideItem => 'Sembunyikan';

  @override
  String get customizeShowItem => 'Tampilkan';

  @override
  String get customizeModeTitle => 'Mode edit';

  @override
  String get customizeModeTitleShort => 'Edit';

  @override
  String customizeHiddenCount(int count) {
    return '$count tersembunyi · ketuk untuk mengubah';
  }

  @override
  String get customizeDone => 'Selesai';

  @override
  String videoBackSeconds(int seconds) {
    return 'Mundur $seconds dtk';
  }

  @override
  String videoForwardSeconds(int seconds) {
    return 'Maju $seconds dtk';
  }

  @override
  String get personalizeTitle => 'Tata letak antarmuka';

  @override
  String get personalizeInfo => 'Pilih area dan tombol yang terlihat, plugin';

  @override
  String get customizeStartTitle => 'Edit di layar';

  @override
  String get customizeStartInfo =>
      'Ketuk tombol dan area untuk menyembunyikan atau menampilkannya; ketuk Selesai bila sudah.';

  @override
  String get customizeStart => 'Mulai mode edit';

  @override
  String get customizeActive => 'Mode edit aktif';

  @override
  String get customizeHint =>
      'Ketuk: sembunyikan/tampilkan · Atur ulang: pindahkan';

  @override
  String get customizeShown => 'Ditampilkan';

  @override
  String get customizeSurfaceBottomBar => 'Bilah bawah';

  @override
  String get customizeSurfaceTopBar => 'Bilah atas';

  @override
  String get customizeSurfaceQuickRow => 'Baris cepat';

  @override
  String get customizeSurfaceAddPanel => 'Panel \"+\"';

  @override
  String get customizeSurfacePinned => 'Lampiran tersemat';

  @override
  String get customizeSurfacePen => 'Pena';

  @override
  String get personalizeModules => 'Plugin';

  @override
  String get moduleAi => 'AI';

  @override
  String get moduleAiInfo => 'Tombol AI di beranda dan layar catatan';

  @override
  String get moduleVoice => 'Suara';

  @override
  String get moduleVoiceInfo => 'Catatan suara AI, dikte, rekaman suara';

  @override
  String get moduleVideo => 'Video';

  @override
  String get moduleVideoInfo => 'Rekam, video galeri, YouTube';

  @override
  String get moduleDocuments => 'Dokumen';

  @override
  String get moduleScan => 'Pemindaian';

  @override
  String get moduleScanInfo => 'Pindai dokumen dan kode QR';

  @override
  String get moduleDrawing => 'Menggambar';

  @override
  String get moduleDrawingInfo => 'Tulisan tangan dan menggambar';

  @override
  String get moduleTemplates => 'Templat';

  @override
  String get moduleTemplatesInfo =>
      'Catatan dari templat, daftar belanja, buku catatan';

  @override
  String get moduleTags => 'Chip catatan';

  @override
  String get moduleTagsInfo => 'Chip tag, folder, dan pengingat di bawah judul';

  @override
  String get moduleCollaboration => 'Kolaborasi';

  @override
  String get moduleCollaborationInfo => 'Tombol tambah orang di layar catatan';

  @override
  String get moduleMixed => 'sebagian aktif';

  @override
  String get personalizeBarLeft => 'Kapsul kiri · alat';

  @override
  String get personalizeBarRight => 'Kapsul kanan · AI dan suara';

  @override
  String get personalizeBarReset => 'Atur ulang bilah bawah';

  @override
  String get personalizeBarTop => 'Bilah atas · urutan tombol';

  @override
  String get personalizeBarMoveRight => 'Pindahkan ke kapsul kanan';

  @override
  String get personalizeBarMoveLeft => 'Pindahkan ke kapsul kiri';

  @override
  String get reorderHandle => 'Atur ulang';

  @override
  String get personalizeVideo => 'Video';

  @override
  String get personalizeHome => 'Beranda';

  @override
  String get personalizeBubbles => 'Gelembung';

  @override
  String get personalizeReset => 'Kembalikan ke bawaan';

  @override
  String get personalizeResetConfirm =>
      'Kembalikan semua pengaturan tampilan dan lompat ke bawaan?';

  @override
  String get personalizeResetDone => 'Bawaan dipulihkan';

  @override
  String get uiItemAttachments => 'Lampiran';

  @override
  String get uiItemDate => 'Edit tanggal';

  @override
  String get uiItemSync => 'Ikon sinkron';

  @override
  String get uiItemVideoTime => 'Label waktu';

  @override
  String get videoSeekBack => 'Mundur';

  @override
  String get videoSeekForward => 'Maju cepat';

  @override
  String get bubbleSizeSetting => 'Ukuran gelembung';

  @override
  String get noteMenuCustomize => 'Sesuaikan layar';

  @override
  String secondsShort(int seconds) {
    return '$seconds dtk';
  }

  @override
  String get uiItemVideoBadge => 'VIDEO';

  @override
  String get listPartRemoved => 'Daftar dihapus';

  @override
  String get textPartRemoved => 'Teks dihapus';

  @override
  String get notePartsMenu => 'Bagian';

  @override
  String get removeListPart => 'Hapus daftar';

  @override
  String get removeTextPart => 'Hapus teks';

  @override
  String get transcriptTitle => 'Transkrip';

  @override
  String get transcriptAction => 'Transkripsikan';

  @override
  String get transcriptFileSuffix => 'transkrip';

  @override
  String get transcriptWorkingAudio => 'Mentranskripsi audio…';

  @override
  String get transcriptWorkingVideo => 'Mentranskripsi video…';

  @override
  String get transcriptWorkingImage => 'Membaca teks dalam gambar…';

  @override
  String get transcriptLongHint =>
      'Rekaman panjang bisa butuh beberapa menit; biarkan layar ini terbuka.';

  @override
  String get transcriptSaved => 'Disimpan ke catatan sebagai lampiran teks';

  @override
  String get transcriptInsertSelection => 'Tambahkan pilihan ke catatan';

  @override
  String get transcriptInsertAll => 'Tambahkan semua ke catatan';

  @override
  String get transcriptInserted => 'Ditambahkan ke catatan';

  @override
  String get transcriptNewNote => 'Catatan baru';

  @override
  String get transcriptShowTimes => 'Stempel waktu';

  @override
  String get transcriptDelete => 'Hapus transkrip';

  @override
  String get transcriptDeleteConfirm =>
      'Hapus transkrip? File sumber tetap ada di catatan.';

  @override
  String get transcriptEmpty => 'Tidak ada teks.';

  @override
  String transcriptUnsupported(String format) {
    return 'Format rekaman ini ($format) tidak bisa ditranskripsi.';
  }

  @override
  String get transcriptEdit => 'Edit';

  @override
  String get transcriptSave => 'Simpan';

  @override
  String transcriptWords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kata',
      one: '1 kata',
    );
    return '$_temp0';
  }

  @override
  String transcriptNoteTitle(String name) {
    return 'Transkrip: $name';
  }

  @override
  String get transcriptOnDevice =>
      'Dibaca di perangkat · tanpa internet atau poin AI';

  @override
  String get addAudioFile => 'Tambah file audio';

  @override
  String get transcribeFile => 'Transkripsikan file';

  @override
  String get transcribeFileSubtitle =>
      'Pilih audio, video, atau gambar; teksnya masuk ke catatan';

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
  String get transcriptPickTitle => 'File untuk ditranskripsi';

  @override
  String get transcriptUnsupportedFile =>
      'Jenis file ini tidak bisa ditranskripsi (pilih audio, video, atau gambar).';

  @override
  String get pickPdfTitle => 'Pilih PDF';

  @override
  String get pickSlidesTitle => 'Pilih presentasi';

  @override
  String get pickImagesTitle => 'Pilih gambar';

  @override
  String get fileAppPickerTitle => 'Pilih file dengan Dosya Okuyucu';

  @override
  String get fileAppPickerInfo =>
      'Menambah file langsung membuka pembaca file; jika mati, kamu memilih aplikasi.';

  @override
  String get viewModeAttached => 'Terlampir';

  @override
  String get viewModeAttachedHint => 'Sebagai lampiran — tetap di strip bawah';

  @override
  String get textToBubblesPreparing => 'Menata teks sebagai dokumen…';

  @override
  String get attachmentActions => 'Tindakan lampiran';

  @override
  String get attachmentUploadQueued => 'Menunggu diunggah';

  @override
  String get attachmentWaitingOwner =>
      'Menunggu orang yang menambahkannya untuk mengunggah';

  @override
  String attachmentsUploadingCount(int count) {
    return 'Mengunggah $count lampiran';
  }

  @override
  String get sharedNoteNew => 'Baru';

  @override
  String sharedNoteUpdatedBy(String name) {
    return 'Diperbarui oleh $name';
  }

  @override
  String get sharedMarkAllRead => 'Tandai semua sudah dibaca';

  @override
  String get attachmentSaveAs => 'Simpan sebagai';

  @override
  String attachmentSavedAs(String name) {
    return '$name disimpan';
  }

  @override
  String get attachmentSaveAsFailed => 'Tidak dapat menyimpan file';

  @override
  String get sharedHubTitle => 'Kotak masuk & bersama';

  @override
  String get voiceAutoStop => 'Berhenti saat hening';

  @override
  String get voiceAutoStopInfo =>
      'Mendengarkan berhenti setelah hening sejenak saat kamu selesai.';

  @override
  String get voiceSmartCommands => 'Perintah cerdas';

  @override
  String get voiceSmartCommandsInfo =>
      'Memahami perintah seperti “hapus kata terakhir”, “ganti X dengan Y”, “baris baru”, “urungkan”; daftar lengkap di Panduan pengguna.';

  @override
  String get voiceAutoStopSoon => 'Hening — segera berhenti';

  @override
  String get dictationPause => 'Jeda';

  @override
  String get dictationResume => 'Lanjutkan';

  @override
  String get dictationPaused => 'Dijeda';

  @override
  String get dictationUndoChunk => 'Urungkan frasa terakhir';

  @override
  String dictationLocaleTooltip(String lang) {
    return 'Bahasa ucapan: $lang';
  }

  @override
  String get voiceCmdDeleted => 'Dihapus';

  @override
  String get voiceCmdReplaced => 'Diganti';

  @override
  String get voiceCmdNewLine => 'Baris baru';

  @override
  String get voiceCmdUndone => 'Diurungkan';

  @override
  String get voiceCmdCleared => 'Dihapus semua';

  @override
  String get fullscreenExit => 'Keluar dari layar penuh';

  @override
  String get voiceCaptureContinue => 'Lanjutkan bicara';

  @override
  String get voiceCmdPunctuation => 'Tanda baca ditambahkan';

  @override
  String get voiceCmdTitle => 'Judul diatur';

  @override
  String get voiceSilenceLabel => 'Waktu tunggu';

  @override
  String get voiceSilenceShort => 'Singkat';

  @override
  String get voiceSilenceNormal => 'Normal';

  @override
  String get voiceSilenceLong => 'Lama';

  @override
  String get voiceOffline => 'Pengenalan offline';

  @override
  String get voiceOfflineInfo =>
      'Dengan paket bahasa, ucapan ditranskripsi tanpa internet.';

  @override
  String get discoverable => 'Izinkan orang menemukanku lewat nama';

  @override
  String get discoverableInfo =>
      'Jika aktif, orang lain bisa menemukanmu di \"Cari orang\" dengan 3 huruf pertama namamu atau email lengkapmu. Jika mati, hanya yang tahu emailmu yang bisa mengirim permintaan.';

  @override
  String get friendsSearchNeedsGoogle =>
      'Masuk dengan akun Google untuk mencari orang.';

  @override
  String get friendsSearchRateLimited =>
      'Terlalu banyak pencarian. Coba lagi dalam semenit.';

  @override
  String get updateRequiredBody =>
      'Versi ini sudah usang: catatan dibuka hanya-baca. Perbarui aplikasi agar datamu tetap utuh.';

  @override
  String get updateAction => 'Perbarui';

  @override
  String get attachmentUnsupportedTitle =>
      'Perbarui aplikasi untuk membuka lampiran ini';

  @override
  String get attachmentUnsupportedBody =>
      'Lampiran ini ditambahkan di versi aplikasi yang lebih baru. Versi ini tidak bisa menampilkannya; tetap disimpan apa adanya.';

  @override
  String noteTooLarge(String size, String part) {
    return 'Catatan ini terlalu besar ($size / 1024 KB) — bagian terbesar: $part. Pindahkan sebagian ke catatan lain atau bisa gagal disimpan.';
  }

  @override
  String get noteSizeBody => 'teks';

  @override
  String get noteSizeItems => 'item daftar';

  @override
  String get noteSizePageNotes => 'catatan halaman';

  @override
  String noteSaveRejected(String reason) {
    return 'Catatan tidak dapat disimpan ke server: $reason';
  }

  @override
  String get errorLogShare => 'Bagikan log kesalahan';

  @override
  String get errorLogInfo =>
      'Kesalahan terbaru hanya disimpan di perangkat ini; tidak dikirim ke mana pun kecuali kamu membagikannya.';

  @override
  String get feedbackSend => 'Kirim masukan';

  @override
  String get feedbackInfo =>
      'Saran atau masalah: aplikasi email terbuka; versi aplikasi dan jenis perangkat ditambahkan, catatanmu tidak.';

  @override
  String get feedbackNoMailApp =>
      'Tidak dapat membuka aplikasi email; alamat disalin ke papan klip.';

  @override
  String get feedbackBodyPrompt => 'Pesanmu:';

  @override
  String get errorLogEmpty => 'Tidak ada kesalahan tercatat.';

  @override
  String get crashReports => 'Kirim laporan crash';

  @override
  String get crashReportsInfo =>
      'Saat aplikasi crash, laporan teknis tanpa isi catatanmu dikirim ke Firebase Crashlytics (hanya Android).';

  @override
  String get noteTooLargeShort => 'catatan melebihi batas 1 MiB';

  @override
  String get crashTestTitle => 'Kirim crash uji?';

  @override
  String get crashTestBody =>
      'Untuk memverifikasi pengaturan Crashlytics, aplikasi langsung ditutup. Saat dibuka lagi, laporan dikirim ke konsol Firebase (bisa butuh beberapa menit).';

  @override
  String get crashTestAction => 'Crash';

  @override
  String get captureModeSetting => 'Catatan dari konten';

  @override
  String get captureModeSettingInfo =>
      'Saat membuat catatan dari foto, pindaian, PDF, dan gambar; pilihan pertamamu dipakai.';

  @override
  String get captureModeAsk => 'Tanya setiap kali';

  @override
  String get voiceMicTooltipDictate => 'Dikte — tekan lama: catatan suara AI';

  @override
  String get quickAddCamera => 'Kamera';

  @override
  String get quickAddFile => 'Tambah file';

  @override
  String get quickAddFromDevice => 'Pilih file';

  @override
  String get quickAddFileWhat => 'Mau diapakan file ini?';

  @override
  String get quickAddFileUnsupported => 'Jenis file ini tidak didukung';

  @override
  String get shareFolderTogether => 'Edit folder bersama';

  @override
  String get shareTogetherInfo =>
      'Kalian berdua melihat dan mengubah catatan atau folder yang sama';

  @override
  String get shareCopyInfo => 'Salinan terpisah masuk ke kotak masuk temanmu';

  @override
  String get notebookViewOn => 'Tampilan buku catatan';

  @override
  String get notebookViewOff => 'Matikan tampilan buku catatan';

  @override
  String inkSemantics(int count) {
    return 'Tulisan tangan, $count goresan';
  }

  @override
  String get guestReminderTitle => 'Catatanmu belum dicadangkan';

  @override
  String get guestReminderBody =>
      'Kamu memakai aplikasi tanpa akun: catatanmu hanya ada di perangkat ini, dan AI bawaan serta berbagi nonaktif. Jika data aplikasi atau browser dihapus atau ganti perangkat, catatan tidak bisa dipulihkan. Tautkan akun Google — catatanmu tetap seperti semula.';

  @override
  String get guestReminderLater => 'Nanti';

  @override
  String get driveWebConnectTitle => 'Lampiran ini ada di Google Drive-mu';

  @override
  String get driveWebConnectBody =>
      'Lampiranmu disimpan di folder “Notlar” di Google Drive. Hubungkan Google Drive untuk mengunduh, menyimpan offline, dan mengunggah lampiran dari browser.';

  @override
  String get driveWebConnectButton => 'Hubungkan Drive';

  @override
  String get lockPatternSemantics =>
      'Pola kunci: hubungkan titik dengan jarimu';

  @override
  String get lockDrawPattern => 'Gambar polamu';

  @override
  String get lockDrawAgain => 'Gambar pola lagi untuk konfirmasi';

  @override
  String get lockEnterPassword => 'Masukkan kata sandi';

  @override
  String get lockPassword => 'Kata sandi';

  @override
  String get lockPasswordAgain => 'Kata sandi (lagi)';

  @override
  String get lockWrong => 'Salah, coba lagi';

  @override
  String lockTooManyAttempts(int count) {
    return 'Terlalu banyak percobaan salah. Tunggu $count dtk.';
  }

  @override
  String get lockUseFingerprint => 'Buka dengan sidik jari';

  @override
  String get lockForgot => 'Lupa';

  @override
  String get lockForgotFailed =>
      'Tidak dapat memverifikasi dengan akun Google. Akun tamu tidak bisa mengatur ulang kata sandi.';

  @override
  String get lockNewPassword => 'Kata sandi kunci baru';

  @override
  String get lockNewPattern => 'Pola kunci baru';

  @override
  String lockPasswordTooShort(int count) {
    return 'Kata sandi minimal $count karakter';
  }

  @override
  String lockPatternTooShort(int count) {
    return 'Pola harus menghubungkan minimal $count titik';
  }

  @override
  String get lockMismatch => 'Tidak cocok, coba lagi';

  @override
  String get lockChangeAuthReason =>
      'Verifikasi untuk mengubah pengaturan kunci';

  @override
  String get lockMethodTitle => 'Kunci catatan';

  @override
  String get lockMethodInfo => 'Bagaimana catatan terkunci dibuka?';

  @override
  String get lockMethodDevice => 'Sidik jari';

  @override
  String get lockMethodPassword => 'Kata sandi';

  @override
  String get lockMethodPattern => 'Pola';

  @override
  String get lockAlsoFingerprint => 'Izinkan juga sidik jari';

  @override
  String get lockChangePassword => 'Ubah kata sandi';

  @override
  String get lockChangePattern => 'Ubah pola';

  @override
  String get lockWebDeviceInfo =>
      'Browser tidak punya sidik jari: pilih kata sandi atau pola untuk melindungi catatan terkunci di web juga.';

  @override
  String get lockNotEncryption =>
      'Isi catatan terkunci, item daftar, dan catatan halaman dienkripsi di perangkat dengan AES-256-GCM sebelum disinkronkan. Kunci sidik jari menyimpan kuncinya di keystore aman perangkat ini; kunci kata sandi atau pola menurunkannya dari rahasiamu — jika lupa, konten yang telah dikunci tidak bisa didekripsi.';

  @override
  String get versionHistory => 'Riwayat versi';

  @override
  String get versionHistoryInfo =>
      'Teks catatan disimpan saat dibuka, setiap setengah jam selama pengeditan panjang, dan sebelum AI mengubahnya. Lampiran tidak diberi versi.';

  @override
  String get versionHistoryEmpty =>
      'Belum ada versi. Akan terkumpul di sini saat kamu mengedit catatan.';

  @override
  String get versionRestore => 'Pulihkan versi ini';

  @override
  String get versionRestored => 'Catatan dipulihkan ke versi sebelumnya';

  @override
  String get versionReasonAi => 'Sebelum perubahan AI';

  @override
  String get versionReasonRestore => 'Sebelum pemulihan';

  @override
  String get versionReasonOpen => 'Saat dibuka';

  @override
  String get versionReasonAuto => 'Otomatis';

  @override
  String get mergeConflictKept =>
      'Orang lain mengedit bagian yang sama — kedua versi disimpan, hapus yang berlebih.';

  @override
  String presenceEditing(String name) {
    return '$name sedang mengedit';
  }

  @override
  String get presenceSomeone => 'Seseorang';

  @override
  String get frameColorInfo =>
      'Hanya digambar di sekitar kartu di beranda, bukan di dalam catatan';

  @override
  String get filterStarred => 'Berbintang';

  @override
  String get fileUseBubbles => 'Gelembung: dokumen menjadi catatan';

  @override
  String get fileUseClassic => 'Klasik: dokumen menjadi lampiran';

  @override
  String get fileUseClassicImageInfo =>
      'Catatan biasa terbuka; gambar berada di halaman dan teks mengalir di sekitarnya.';

  @override
  String get fileUseVideo => 'Buat catatan pada video';

  @override
  String get fileUseVideoInfo =>
      'Video diputar di atas, kamu menulis catatan di bawah.';

  @override
  String get fileUseAudio => 'Tambahkan sebagai lampiran audio';

  @override
  String get fileUseAudioInfo =>
      'Rekaman tetap bisa diputar di catatan; transkripsikan nanti jika mau.';

  @override
  String get fileUseTranscribeInfo =>
      'Ucapan ditranskripsi dan ditulis ke isi catatan.';

  @override
  String get fileUseTranscribeImageInfo =>
      'Teks di gambar dibaca dan ditulis ke isi catatan.';

  @override
  String get fileUseDefault => 'Bawaan';

  @override
  String fileUseMore(int count) {
    return '+$count file lagi';
  }

  @override
  String get attachAnyFileInfo =>
      'File apa pun: gambar, PDF, slide, audio, video — jenisnya dikenali, kamu ditanya bila perlu';

  @override
  String get listeningModeAi => 'AI';

  @override
  String get listeningModeDictation => 'Ketik langsung';

  @override
  String get dictationPanelHint => 'Teks muncul di kursor saat kamu bicara';

  @override
  String get voiceStartShort => 'Mulai';

  @override
  String get archivePaperDashed => 'Garis putus-putus';

  @override
  String get itemDividerRemove => 'Hapus garis';

  @override
  String get fileUseAttachInfo =>
      'Ditambahkan ke catatan sebagai lampiran yang bisa diputar';

  @override
  String get allNotesChip => 'Semua';

  @override
  String get untitledNote => 'Catatan tanpa judul';

  @override
  String get trashAnalysis => 'Analisis sampah';

  @override
  String get trashAnalyze => 'Analisis cerdas';

  @override
  String get trashSuggestRestore => 'Pertimbangkan dipulihkan';

  @override
  String get trashSuggestDelete => 'Aman dihapus';

  @override
  String get trashSuggestNone => 'Tidak ada saran';

  @override
  String trashRestoreAllSuggested(int count) {
    return 'Pulihkan semua ($count)';
  }

  @override
  String trashDeleteAllSuggested(int count) {
    return 'Hapus semua ($count)';
  }

  @override
  String trashStatNotes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count catatan',
      one: '1 catatan',
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
    return '$count terhapus dalam 3 hari';
  }

  @override
  String trashStatLocked(int count) {
    return '$count terkunci (tidak diperiksa)';
  }

  @override
  String get trashReasonEmpty => 'Kosong — tidak ada yang hilang';

  @override
  String get trashReasonDuplicate => 'Catatan identik sudah ada';

  @override
  String trashReasonDuplicateOf(String title) {
    return 'Identik dengan: $title';
  }

  @override
  String get trashReasonDuplicateInTrash =>
      'Salinan yang lebih baru juga ada di sampah';

  @override
  String trashReasonOpenTasks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tugas terbuka',
      one: '1 tugas terbuka',
    );
    return '$_temp0';
  }

  @override
  String get trashReasonReminder => 'Punya pengingat mendatang';

  @override
  String get trashReasonSensitive =>
      'Berisi info seperti kata sandi, IBAN, nomor telepon';

  @override
  String trashReasonAttachments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Punya $count lampiran',
      one: 'Punya 1 lampiran',
    );
    return '$_temp0';
  }

  @override
  String get trashReasonSubstantial => 'Teks panjang dan berisi';

  @override
  String get cardElementsHeader => 'Tampil di kartu';

  @override
  String get cardShowProgress => 'Penghitung kemajuan (mis. 3/10)';

  @override
  String get cardShowProgressInfo =>
      'Menampilkan item yang dicentang dengan bilah dan angka.';

  @override
  String get cardShowChecked => 'Item selesai';

  @override
  String get cardShowCheckedInfo =>
      'Jika mati, item yang dicentang diringkas: ✓ 3 selesai.';

  @override
  String cardItemsDone(int count) {
    return '✓ $count selesai';
  }

  @override
  String cardItemsAllDone(int count) {
    return '✓ Semua selesai ($count)';
  }

  @override
  String get emptyNotesFirstAction => 'Tulis catatan pertamamu';

  @override
  String get emptyNotesHint =>
      'Catatan yang kamu tulis muncul di sini sebagai kartu.';

  @override
  String get emptyFolderHint =>
      'Catatan yang kamu tambahkan ke folder ini terkumpul di sini.';

  @override
  String get emptyFilterHint =>
      'Hapus filter untuk melihat semua catatanmu lagi.';

  @override
  String get emptySearchHint => 'Coba kata lain.';

  @override
  String get archiveEmptyHint =>
      'Catatan yang diarsipkan keluar dari beranda dan disimpan di sini.';

  @override
  String get trashEmptyHint =>
      'Catatan yang dihapus tetap di sini selama 30 hari; kamu bisa memulihkannya sampai saat itu.';

  @override
  String get cardShowMoreCount => 'Baris “+N item lagi”';

  @override
  String get cardShowStatusIcons => 'Ikon status';

  @override
  String get cardShowStatusIconsInfo =>
      'Disematkan, berbintang, pengingat, bersama, hanya perangkat ini…';

  @override
  String get cardShowTag => 'Tag';

  @override
  String get cardShowDate => 'Tanggal dan waktu';

  @override
  String get cardShowMedia => 'Gambar dan video';

  @override
  String get cardShowFolder => 'Nama folder';

  @override
  String get cardShowFolderInfo =>
      'Folder catatan di hasil pencarian dan tampilan Semua.';

  @override
  String get cardShowPaper => 'Pola kertas buku catatan';

  @override
  String get formatFontPanel => 'Fon dan ukuran';

  @override
  String get inkShapes => 'Bentuk';

  @override
  String get inkShapeLine => 'Garis lurus';

  @override
  String get inkShapeRectangle => 'Persegi panjang';

  @override
  String get inkShapeEllipse => 'Lingkaran / elips';

  @override
  String get inkPenOnlyOn => 'Hanya pena (jari menggulir) — matikan';

  @override
  String get inkPenOnlyOff => 'Jari juga menggambar — beralih ke hanya pena';

  @override
  String get inkPenOnlyHint =>
      'Tulis dengan pena · seret dengan jari, cubit untuk perbesar';

  @override
  String get inkSettings => 'Pengaturan pena';

  @override
  String get inkWidth => 'Ketebalan';

  @override
  String get inkOpacity => 'Opasitas';

  @override
  String get inkRecentColors => 'Warna terbaru';

  @override
  String get inkPenOnlyTitle => 'Gambar hanya dengan pena';

  @override
  String get inkFingerToolTitle => 'Jari';

  @override
  String get inkFingerToolInfo =>
      'Otomatis: jari menggulir setelah pena terdeteksi, jika tidak menggambar. Menggulir: hanya pena yang menulis, jari menggulir. Menggambar: jari juga menulis dengan alat pena. Menghapus: jari menghapus, dua jari memperbesar.';

  @override
  String get inkFingerScroll => 'Menggulir';

  @override
  String get inkFingerDraw => 'Menggambar';

  @override
  String get inkFingerErase => 'Menghapus';

  @override
  String get inkFingerEraseOn => 'Jari menghapus — beralih ke hanya pena';

  @override
  String get inkPressureTitle => 'Sensitivitas tekanan';

  @override
  String get inkPressureInfo =>
      'Tekanan ringan menulis tipis, tekanan kuat menulis tebal.';

  @override
  String get inkStylusTipsTitle => 'Pintasan pena';

  @override
  String get inkStylusTips =>
      'Tahan tombol samping pena atau sentuh dengan ujung penghapus untuk menghapus.';

  @override
  String get inkZoomReset => 'Sesuaikan ke layar';

  @override
  String get cardShowFiles => 'Lampiran file';

  @override
  String get cardShowFilesInfo =>
      'Tampilkan lampiran PDF, slide, audio, dan teks di kartu';

  @override
  String get cardShowMediaShort => 'Gambar di kartu';

  @override
  String get cardShowFilesShort => 'Lampiran di kartu';

  @override
  String get homeShowShared => 'Catatan bersama di beranda';

  @override
  String get homeShowSharedInfo =>
      'Catatan bersama juga muncul di bagian tersendiri di beranda.';

  @override
  String get homeShowSharedShort => 'Tampilkan catatan bersama';

  @override
  String get homeSharedAtBottom => 'Catatan bersama di bawah milikku';

  @override
  String get homeSharedAtBottomInfo =>
      'Jika aktif, catatan bersama berada di bawah catatanmu.';

  @override
  String get homeSharedAtBottomShort => 'Catatan bersama di bawah';

  @override
  String get homeSharedSection => 'Bersama';

  @override
  String get copyAttachment => 'Salin lampiran';

  @override
  String get attachmentCopiedPasteHint =>
      'Lampiran disalin — tempel ke catatan lain dari menu +';

  @override
  String get dividerSettings => 'Pengaturan garis';

  @override
  String get dividerPreviewText => 'Contoh item';

  @override
  String get dividerKind => 'Gaya';

  @override
  String get dividerColor => 'Warna';

  @override
  String get dividerWeight => 'Ketebalan';

  @override
  String get dividerApplyAll => 'Terapkan ke semua';

  @override
  String get dividerKindSolid => 'Utuh';

  @override
  String get dividerKindDashed => 'Putus-putus';

  @override
  String get dividerKindDotted => 'Titik-titik';

  @override
  String get dividerKindDouble => 'Ganda';

  @override
  String get dividerKindWavy => 'Bergelombang';

  @override
  String get itemMenuUnstar => 'Hapus bintang';

  @override
  String get itemMenuMove => 'Pindahkan';

  @override
  String get itemMenuDelete => 'Hapus';

  @override
  String get itemMenuLine => 'Garis di bawah';

  @override
  String get formatStyleText => 'Teks';

  @override
  String get formatStyleH1 => 'Judul';

  @override
  String get formatStyleH2 => 'Subjudul';

  @override
  String get formatSizeDown => 'Lebih kecil';

  @override
  String get formatSizeUp => 'Lebih besar';

  @override
  String get imageCaptionHint => 'Keterangan gambar';

  @override
  String get imageCaptionAdd => 'Tambah keterangan';

  @override
  String get imageCaptionEdit => 'Edit keterangan';

  @override
  String get voiceRecordResume => 'Lanjutkan rekaman';

  @override
  String get voiceRecordDiscard => 'Buang rekaman';

  @override
  String get checkboxToggle => 'Kotak centang';

  @override
  String get noteAppearance => 'Tampilan';

  @override
  String get noteThemeNone => 'Polos';

  @override
  String get noteThemePalm => 'Palem';

  @override
  String get noteThemeLagoon => 'Laguna';

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
  String get pinToHomeScreen => 'Tambahkan ke layar utama';

  @override
  String get pinToHomeSent =>
      'Konfirmasi di layar utama — catatan akan terbuka dari pintasannya';

  @override
  String get pinToHomeUnsupported =>
      'Layar utamamu tidak mendukung pintasan ini';

  @override
  String get inkColor => 'Warna pena';

  @override
  String get cardMediaHide => 'Sembunyikan pratinjau gambar';

  @override
  String get cardMediaShow => 'Tampilkan pratinjau gambar';

  @override
  String get youTubeEmbedInNote => 'Sematkan di catatan';

  @override
  String get goToLink => 'Buka tautan';

  @override
  String get noteFlatColors => 'Warna polos';

  @override
  String get youTubeEmbedded => 'Video disematkan di catatan';

  @override
  String get inkLasso => 'Laso (pilih dan pindahkan)';

  @override
  String get inkLassoHint =>
      'Gambar di sekitar goresan: seret untuk memindahkan, pilih warna untuk mewarnai ulang.';

  @override
  String get inkDeleteSelection => 'Hapus pilihan';

  @override
  String get inkClearSelection => 'Batalkan pilihan';

  @override
  String get inkShapeSnapTitle => 'Tahan untuk jadi bentuk';

  @override
  String get inkShapeSnapInfo =>
      'Tahan pena diam di akhir goresan untuk mendapat garis, lingkaran, atau kotak.';

  @override
  String get inkQuickSwapTitle => 'Tombol cepat pena ↔ penghapus';

  @override
  String get inkQuickSwapInfo =>
      'Setelah goresan, muncul tombol untuk beralih antara pena dan penghapus.';

  @override
  String get inkQuickSwapToEraser => 'Beralih ke penghapus';

  @override
  String get inkQuickSwapToPen => 'Kembali ke pena';

  @override
  String get inkPartialEraserTitle => 'Penghapus sebagian';

  @override
  String get inkPartialEraserInfo =>
      'Penghapus hanya menghapus yang disentuh; jika mati, menghapus seluruh goresan.';

  @override
  String get inkAutoStylusTitle => 'Deteksi pena otomatis';

  @override
  String get inkAutoStylusInfo =>
      'Mode menulis aktif saat pena menyentuh catatan.';

  @override
  String get inkStylusDetected => 'Pena terdeteksi — mode menulis aktif';

  @override
  String get copyAndCheckSelectedItems => 'Salin dan centang';

  @override
  String get copiedAndChecked => 'Disalin dan dicentang';

  @override
  String get formatScopeCaret => 'Kursor';

  @override
  String get formatScopeWord => 'Kata';

  @override
  String get formatScopeLine => 'Baris';

  @override
  String get formatScopeAll => 'Semua';

  @override
  String get formatScopeSelection => 'Pilihan';

  @override
  String get formatScopeHint =>
      'Format diterapkan ke: kursor, kata, baris, atau semua';

  @override
  String get formatStyleMenu => 'Gaya paragraf';

  @override
  String get colorNameCoral => 'Koral';

  @override
  String get colorNamePeach => 'Persik';

  @override
  String get colorNameHoney => 'Madu';

  @override
  String get colorNameSage => 'Sage';

  @override
  String get colorNameStorm => 'Badai';

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
  String get colorNameNone => 'Tanpa warna';

  @override
  String get colorNameOrange => 'Oranye';

  @override
  String get colorNamePink => 'Merah muda';

  @override
  String get colorNameGray => 'Abu-abu';

  @override
  String get colorNameCyan => 'Sian';

  @override
  String get colorNameWhite => 'Putih';

  @override
  String get colorNameBlack => 'Hitam';

  @override
  String get colorToneLight => 'muda';

  @override
  String get colorToneVivid => 'cerah';

  @override
  String get colorToneDark => 'tua';

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
  String get formatSizeLabel => 'Ukuran';

  @override
  String formatSizeValue(int percent) {
    return 'Ukuran $percent%';
  }

  @override
  String get customColor => 'Warna kustom…';

  @override
  String get embedLasso => 'Pilih dengan melingkari';

  @override
  String embedLassoHint(String name) {
    return '$name akan ditautkan — lingkari teks atau ketuk kata · gulir dengan dua jari';
  }

  @override
  String get embedSelectMode => 'Tautkan dengan memilih';

  @override
  String get embedLassoMissed =>
      'Tidak ada teks di dalam lingkaran — gambar di sekitar teks';

  @override
  String get gestureItemDeleted => 'Item dihapus';

  @override
  String get itemGesturesSetting => 'Gestur item';

  @override
  String get itemGesturesSettingInfo =>
      'Gambar di item: coret atau centang; mencoret-coret menghapus.';

  @override
  String get pdfEditWorking => 'Memproses PDF…';

  @override
  String get noteMenu => 'Menu catatan';

  @override
  String get moreActions => 'Tindakan lain';

  @override
  String get errorOffline =>
      'Tidak ada atau internet lemah. Coba lagi saat online.';

  @override
  String get errorTimeout => 'Terlalu lama. Coba lagi sebentar lagi.';

  @override
  String get errorQuota => 'Batas pemakaian tercapai. Coba lagi nanti.';

  @override
  String get errorPermission =>
      'Tidak diizinkan. Periksa akunmu atau izin aplikasi.';

  @override
  String get errorTooLarge => 'File terlalu besar.';

  @override
  String get errorUnsupported => 'Ini tidak didukung di sini.';

  @override
  String get errorUnknown =>
      'Terjadi hal tak terduga. Rinciannya ada di log kesalahan.';

  @override
  String get errorStateTitle => 'Tidak dapat dimuat';

  @override
  String get errorStateOfflineTitle => 'Kamu sedang offline';

  @override
  String get copyErrorDetail => 'Salin rincian';

  @override
  String get accountRequiredTitle => 'Perlu akun Google';

  @override
  String get accountRequiredBody =>
      'Kontak, kolaborasi, dan kirim salinan bekerja lewat alamat emailmu; tanpa akun tidak ada yang bisa menemukanmu. Tautkan akun Google — catatanmu tetap seperti semula.';

  @override
  String get accountRequiredBadge => 'Perlu akun Google';

  @override
  String get deletingAccount => 'Menghapus akun dan datamu…';

  @override
  String get sharedHubShort => 'Masuk';

  @override
  String get itemEmptyHint => 'Tulis item';

  @override
  String get allFolders => 'Semua folder';

  @override
  String get guestReminderConnect => 'Hubungkan';

  @override
  String get filterSectionType => 'Jenis';

  @override
  String get reorderNotesManually => 'Atur manual';

  @override
  String get shareIncludeBubbles => 'Gelembung';

  @override
  String sharedFolderBar(String role) {
    return 'Folder bersama · $role';
  }

  @override
  String get shareSendSection => 'Kirim keluar';

  @override
  String get shareInAppSection => 'Dengan orang';

  @override
  String get shareTextHint =>
      'Mengirim teks catatan ke aplikasi (WhatsApp, email…)';

  @override
  String get shareCopyHint => 'Menyalin teks catatan ke papan klip';

  @override
  String get shareQuickPdfHint =>
      'Mengirim catatan sebagai file PDF dengan sekali ketuk';

  @override
  String get shareAsImageHint => 'Mengirim catatan sebagai gambar, per halaman';

  @override
  String get shareAttachmentFilesHint =>
      'Mengirim foto, PDF, audio, dan video catatan itu sendiri';

  @override
  String get shareAsNoteInfo =>
      'Satu file dengan lampiran, halaman, gambar, dan gelembung; terbuka persis di aplikasi ini';

  @override
  String get bubbleCopy => 'Salin';

  @override
  String get bubblesCopyAll => 'Salin semua';

  @override
  String get bubblesToNote => 'Tambahkan ke catatan';

  @override
  String get bubblesToNoteDone => 'Gelembung ditambahkan di akhir catatan';

  @override
  String get bubbleMark => 'Tandai';

  @override
  String get bubbleFormat => 'Format';

  @override
  String get sharedHubTagInbox => 'Masuk';

  @override
  String get sharedHubTagShared => 'Bersama';

  @override
  String get sharedHubEmpty => 'Belum ada yang diterima atau dibagikan di sini';

  @override
  String get sharedHubEmptyHint =>
      'Salinan yang dikirim temanmu dan catatan bersama yang mengikutsertakanmu muncul bersama di sini.';

  @override
  String get settingsModulesTitle => 'Modul & catatan cepat';

  @override
  String settingsModulesSummary(int on, int total) {
    return '$on/$total modul aktif';
  }

  @override
  String get settingsSoundTitle => 'Dengarkan & dikte';

  @override
  String cardElementsSummary(int on, int total) {
    return '$on/$total aktif · lihat contoh';
  }

  @override
  String get cardElementsSampleTitle => 'Belanja akhir pekan';

  @override
  String cardElementsSampleItem(int n) {
    return 'Item $n';
  }

  @override
  String get cardElementsSampleTag => 'rumah';

  @override
  String get tipListGestures =>
      'Tips: coret item dengan jari → item dicentang.';

  @override
  String get tipMediaPin =>
      'Tips: tekan lama gambar dan seret ke atas → disematkan di atas catatan.';

  @override
  String get tipGridSwipeFolders =>
      'Tips: geser layar ke samping → pindah antar folder.';

  @override
  String get tipGridSwipeFilters =>
      'Tips: geser layar ke samping → pindah antar filter.';

  @override
  String get tipsResetTitle => 'Tampilkan tips lagi';

  @override
  String get tipsResetInfo =>
      'Tips kecil sekali tampil (gestur, pencarian Makna) muncul lagi.';

  @override
  String get tipsResetDone => 'Tips akan ditampilkan lagi';

  @override
  String get tipsEnabledTitle => 'Tampilkan tips berguna';

  @override
  String get tipsEnabledInfo =>
      'Tampilkan petunjuk singkat dan tenang saat pertama memakai fitur.';

  @override
  String get tipFormatScope =>
      'Tips: ganti cakupan antara kursor, kata, baris, atau semua; ketuk persentase untuk mengembalikan ukuran ke 100%.';

  @override
  String get tipTableGestures =>
      'Tips: seret batas kolom untuk mengubah ukuran, atau tekan Tab untuk pindah ke sel berikutnya.';

  @override
  String get tipItemHoldSelect =>
      'Tips: tahan item untuk pilih banyak; gunakan rentang, balik, dan format massal dari bilah bawah.';

  @override
  String get tipVoiceCommands =>
      'Tips: ucapkan \"baris baru\", \"item baru\", \"titik\", atau \"hapus kata terakhir\" saat dikte.';

  @override
  String get tipFolderGestures =>
      'Tips: tahan folder untuk opsi cepat, atau seret catatan ke folder untuk memindahkannya.';

  @override
  String get tipPinnedSplitResize =>
      'Tips: seret pegangan pemisah untuk mengubah ukuran, atau tukar sisi dari bilah tersemat.';

  @override
  String get tipPinnedSmartActions =>
      'Tips: buka tindakan cerdas dari bilah tersemat untuk meringkas halaman, mengekstrak teks, atau bertanya ke AI.';

  @override
  String get tipCrossAppDosyalarim =>
      'Tips: buka PDF dan file terlampir di Dosyalarım; Kolam AI Bersama berlaku di kedua aplikasi.';

  @override
  String get swipeModeInfo =>
      'Fungsi geser ke samping di tampilan kisi; di tampilan daftar, menggeser baris menyematkan atau mengarsipkan.';

  @override
  String get backupInfo =>
      'Semua catatan beserta lampiran dan folder dalam satu file; impor dua kali tidak menggandakan.';

  @override
  String get backupInProgress => 'Menyiapkan cadangan';

  @override
  String get restoreInProgress => 'Memulihkan';

  @override
  String get backupShareSubject => 'Cadangan catatan';

  @override
  String get backupCancelled => 'Dibatalkan';

  @override
  String backupProgressCount(int done, int total) {
    return '$done / $total catatan';
  }

  @override
  String restoreBackupResult(int restored, int skipped) {
    return '$restored catatan dipulihkan, $skipped dilewati (sudah ada)';
  }

  @override
  String get accountRecoverBringNotes => 'Bawa catatanku';

  @override
  String accountRecoverBringDone(int count) {
    return 'Akun diganti, $count catatan dipindahkan';
  }

  @override
  String get accountRecoverBringFailed =>
      'Akun diganti tapi catatan tidak bisa dipindahkan; catatan tamu tidak tersentuh';

  @override
  String get appLockTitle => 'Kunci aplikasi';

  @override
  String get appLockInfo =>
      'Meminta saat dibuka dan kembali dari latar, memakai metode kunci catatan. Bukan enkripsi; hanya perangkat ini.';

  @override
  String get appLockWebNeedsSecret =>
      'Tidak ada kunci perangkat di web: pilih kata sandi atau pola di atas dulu.';

  @override
  String get appLockReason => 'Buka Catatan';

  @override
  String get appLockLockedTitle => 'Catatan terkunci';

  @override
  String get appLockUnlock => 'Buka kunci';

  @override
  String get appLockDelayTitle => 'Kunci:';

  @override
  String get appLockDelayNow => 'segera';

  @override
  String appLockDelayMinutes(int minutes) {
    return 'setelah $minutes mnt';
  }

  @override
  String get appLockHideRecents => 'Sembunyikan konten di aplikasi terbaru';

  @override
  String get repeatTitle => 'Ulangi';

  @override
  String get repeatNone => 'Jangan ulangi';

  @override
  String get repeatDaily => 'Setiap hari';

  @override
  String get repeatWeekdays => 'Setiap hari kerja';

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
  String get importOther => 'Impor dari aplikasi lain';

  @override
  String get importOtherInfo =>
      'Google Keep (Takeout zip), Markdown/txt (file atau zip), Evernote (.enex)';

  @override
  String get importInProgress => 'Mengimpor';

  @override
  String get importOtherNone => 'Tidak ada catatan untuk diimpor di file ini';

  @override
  String importOtherResult(int imported, int skipped, int failed) {
    return '$imported catatan diimpor, $skipped dilewati (sudah ada), $failed tidak terbaca';
  }

  @override
  String get noteLinkAction => 'Tautkan ke catatan';

  @override
  String get noteLinkOpen => 'Buka catatan';

  @override
  String get noteLinkPickTitle => 'Tautkan ke catatan mana?';

  @override
  String get noteLinkInserted => 'Ditautkan ke catatan';

  @override
  String get noteLinkMissing =>
      'Catatan tertaut tidak ditemukan (mungkin sudah dihapus)';

  @override
  String get backlinksTitle => 'Catatan yang menaut ke sini';

  @override
  String backlinksCount(int count) {
    return '$count tautan balik';
  }

  @override
  String get relatedNotesTitle => 'Catatan terkait';

  @override
  String get relatedNotesNone => 'Tidak ada catatan terkait';

  @override
  String get relatedNotesLink => 'Tautkan';

  @override
  String get studyCardsTitle => 'Kartu hari ini';

  @override
  String get studyCardsEmpty => 'Tidak ada kartu jatuh tempo hari ini';

  @override
  String get studyCardsDone => 'Semua selesai untuk hari ini!';

  @override
  String get studyCardsEmptyInfo =>
      'Gunakan \"Buat kartu\" di menu ⋮ catatan dan AI mengubah catatan menjadi kartu tanya–jawab.';

  @override
  String studyCardsLeft(int count) {
    return '$count kartu tersisa';
  }

  @override
  String get studyCardsReveal => 'Tampilkan jawaban';

  @override
  String get studyGradeAgain => 'Lagi';

  @override
  String get studyGradeHard => 'Sulit';

  @override
  String get studyGradeGood => 'Bagus';

  @override
  String get studyGradeEasy => 'Mudah';

  @override
  String updateAvailable(String name) {
    return 'Versi baru tersedia: $name';
  }

  @override
  String get pdfNoteFromSelection => 'Buat catatan';

  @override
  String get pdfNoteAtPage => 'Catat halaman ini';

  @override
  String get tipPdfReadNote =>
      'Tips: tekan lama teks, pilih → \"Buat catatan\": halaman dan baris masuk ke catatanmu, ketuk untuk kembali.';

  @override
  String showMoreChecked(int n) {
    return 'Tampilkan yang dicentang ($n tersembunyi)';
  }

  @override
  String get hideMoreChecked => 'Ciutkan yang dicentang';

  @override
  String get gmailGoogleOnly => 'Masuk dengan Google untuk memakai Gmail.';

  @override
  String get tipHomeMicHold =>
      'Tips: tekan lama mikrofon untuk catatan suara AI.';

  @override
  String get itemGesturesFingerAll =>
      'Gestur hapus dan perbaiki dengan jari juga';

  @override
  String get itemGesturesFingerAllInfo =>
      'Jika mati, jari hanya mencentang; coretan dan lingkaran perlu pena.';

  @override
  String get itemAddHeader => 'Subjudul';

  @override
  String get itemHeaderHint => 'Tulis subjudul';

  @override
  String get itemMenuToHeader => 'Jadikan judul';

  @override
  String get itemMenuToItem => 'Jadikan item';

  @override
  String get pinnedMediaFit => 'Pas';

  @override
  String get tagRemove => 'Hapus tag';

  @override
  String get itemAlignStart => 'Rata kiri';

  @override
  String get itemAlignCenter => 'Tengah';

  @override
  String get itemAlignEnd => 'Rata kanan';

  @override
  String get themeLavender => 'Lavender';

  @override
  String get themeOlive => 'Zaitun';

  @override
  String get tplShopMeat => 'Daging, unggas & ikan';

  @override
  String get tplShopMeatItems =>
      'Daging cincang, Dada ayam, Paha ayam, Daging sapi potong dadu, Ikan, Sosis, Kalkun asap, Bakso';

  @override
  String get tplShopDrinks => 'Minuman';

  @override
  String get tplShopDrinksItems =>
      'Air, Air soda, Jus, Susu fermentasi, Soda, Es teh, Susu';

  @override
  String get tplShopSnacks => 'Camilan';

  @override
  String get tplShopSnacksItems =>
      'Biskuit, Cokelat, Keripik, Kacang, Kraker, Wafer, Buah kering';

  @override
  String get tplShopFrozen => 'Beku';

  @override
  String get tplShopFrozenItems =>
      'Es krim, Kacang polong, Kentang goreng, Pangsit, Pizza, Kue pastry';

  @override
  String get tplShopBaby => 'Bayi';

  @override
  String get tplShopBabyItems =>
      'Popok, Tisu basah, Susu formula, Sampo bayi, Krim popok';

  @override
  String get tplShopPet => 'Hewan peliharaan';

  @override
  String get tplShopPetItems =>
      'Makanan kucing, Makanan anjing, Pasir kucing, Camilan, Roll pembersih bulu';

  @override
  String get tplTravelHealth => 'Kesehatan';

  @override
  String get tplTravelHealthItems =>
      'Obat pereda nyeri, Plester, Obat maag, Resep, Obat nyamuk, Masker';

  @override
  String get tplTravelBeforeGo => 'Sebelum berangkat';

  @override
  String get tplTravelBeforeGoItems =>
      'Cek kompor, Tutup jendela, Buang sampah, Siram tanaman, Cabut colokan perangkat, Bawa kunci';

  @override
  String get tplCleanKitchen => 'Dapur';

  @override
  String get tplCleanKitchenItems =>
      'Piring, Meja dapur, Kompor, Oven, Kulkas, Wastafel, Microwave';

  @override
  String get tplCleanBath => 'Kamar mandi';

  @override
  String get tplCleanBathItems =>
      'Toilet, Wastafel, Pancuran, Cermin, Nat ubin, Ganti handuk';

  @override
  String get tplCleanRooms => 'Kamar';

  @override
  String get tplCleanRoomsItems =>
      'Bersihkan debu, Sedot debu, Pel, Rapikan kasur, Bersihkan jendela, Kibas karpet';

  @override
  String get tplCleanMonthly => 'Bulanan';

  @override
  String get tplCleanMonthlyItems =>
      'Gorden, Filter AC, Dalam lemari, Perawatan mesin cuci, Filter penghisap asap';

  @override
  String get tplMoveBefore => 'Sebelum pindah';

  @override
  String get tplMoveBeforeItems =>
      'Pesan jasa pindahan, Beli kardus dan lakban, Singkirkan barang, Beri label kardus, Beri tahu penyedia layanan, Ganti alamat';

  @override
  String get tplMoveDay => 'Hari pindahan';

  @override
  String get tplMoveDayItems =>
      'Foto meteran, Serahkan kunci, Bawa barang berharga, Periksa terakhir, Tas malam pertama';

  @override
  String get tplMoveAfter => 'Setelah pindah';

  @override
  String get tplMoveAfterItems =>
      'Pasang internet, Daftarkan alamat, Ganti kunci, Perbarui alamat bank, Kenalan dengan tetangga';

  @override
  String get tplHabitHealth => 'Kesehatan';

  @override
  String get tplHabitHealthItems =>
      '8 gelas air, Jalan 30 menit, Tidur lebih awal, Hari tanpa gula, Minum vitamin, Peregangan';

  @override
  String get tplHabitMind => 'Pikiran';

  @override
  String get tplHabitMindItems =>
      'Baca 20 halaman, Meditasi, Menulis jurnal, Satu jam tanpa layar, Pelajari kata baru';

  @override
  String get tplHabitHome => 'Rumah';

  @override
  String get tplHabitHomeItems =>
      'Selesaikan cuci piring, Beres-beres 10 menit, Siram tanaman, Rencanakan besok';

  @override
  String get tplWorkoutUpper => 'Tubuh bagian atas';

  @override
  String get tplWorkoutUpperItems =>
      'Push-up 3×10, Pull-up 3×6, Shoulder press 3×10, Biceps curl 3×12, Triceps dip 3×10, Plank 3×45 dtk';

  @override
  String get tplWorkoutLower => 'Tubuh bagian bawah';

  @override
  String get tplWorkoutLowerItems =>
      'Squat 3×12, Lunge 3×10, Glute bridge 3×15, Calf raise 3×20, Wall sit 3×40 dtk';

  @override
  String get tplWorkoutCardio => 'Kardio';

  @override
  String get tplWorkoutCardioItems =>
      'Lari 20 menit, Lompat tali 5 menit, Bersepeda 30 menit, Jumping jack 3×30, Burpee 3×10';

  @override
  String get tplGiftPeople => 'Orang';

  @override
  String get tplGiftPeopleItems =>
      'Ibu, Ayah, Saudara, Pasangan, Teman, Guru, Rekan kerja, Anak';

  @override
  String get tplGiftIdeas => 'Ide';

  @override
  String get tplGiftIdeasItems =>
      'Buku, Bunga, Parfum, Jam tangan, Hadiah pengalaman, Buatan tangan, Mug, Kartu hadiah';

  @override
  String get tplTodoHome => 'Rumah';

  @override
  String get tplTodoHomeItems =>
      'Bayar tagihan, Cucian, Belanja, Perbaikan, Buat janji';

  @override
  String get tplTodoErrands => 'Urusan';

  @override
  String get tplTodoErrandsItems =>
      'Ke bank, Kirim paket, Apotek, Laundry kering, Kantor pos';

  @override
  String get templateFavorite => 'Tambahkan ke favorit';

  @override
  String get templateUnfavorite => 'Hapus dari favorit';

  @override
  String get templatesFavorites => 'Favorit';

  @override
  String get templateFavoritesFull => 'Maksimal 4 favorit — hapus satu dulu';

  @override
  String get calendarTitle => 'Kalender';

  @override
  String get calendarToday => 'Hari ini';

  @override
  String get calendarViewAgenda => 'Agenda';

  @override
  String get calendarViewMonth => 'Bulan';

  @override
  String get calendarNewEvent => 'Acara baru';

  @override
  String get calendarEmpty => 'Belum ada acara di sini';

  @override
  String get calendarEmptyHint =>
      'Tambahkan acara; catatan dengan pengingat juga muncul di sini.';

  @override
  String get calendarNothingThisDay => 'Tidak ada rencana hari ini';

  @override
  String get calendarReminderTag => 'Pengingat';

  @override
  String get calendarShowMonth => 'Tampilkan bulan';

  @override
  String get calendarHideMonth => 'Sembunyikan bulan';

  @override
  String get calendarPrevMonth => 'Bulan sebelumnya';

  @override
  String get calendarNextMonth => 'Bulan berikutnya';

  @override
  String get calendarMoreDays => 'Lebih jauh';

  @override
  String get eventEditTitle => 'Edit acara';

  @override
  String get eventTitleHint => 'Tambahkan judul';

  @override
  String get eventUntitled => '(Tanpa judul)';

  @override
  String get eventAllDay => 'Sepanjang hari';

  @override
  String get eventStarts => 'Mulai';

  @override
  String get eventEnds => 'Selesai';

  @override
  String get eventReminder => 'Pengingat';

  @override
  String get eventReminderNone => 'Tanpa pengingat';

  @override
  String get eventReminderAtStart => 'Saat waktu mulai';

  @override
  String get eventReminderAllDayMorning => 'Pada hari itu pukul 09.00';

  @override
  String eventReminderMinutes(int count) {
    return '$count menit sebelumnya';
  }

  @override
  String eventReminderHours(int count) {
    return '$count jam sebelumnya';
  }

  @override
  String eventReminderDays(int count) {
    return '$count hari sebelumnya';
  }

  @override
  String get eventLocation => 'Lokasi';

  @override
  String get eventDescription => 'Deskripsi';

  @override
  String get eventSave => 'Simpan';

  @override
  String get eventDelete => 'Hapus acara';

  @override
  String get eventDeleted => 'Acara dihapus';

  @override
  String get eventDeleteRepeatingTitle => 'Acara berulang';

  @override
  String get eventDeleteThis => 'Hanya acara ini';

  @override
  String get eventDeleteAll => 'Semua kejadian';

  @override
  String get eventNotificationAllDay => 'Hari ini · sepanjang hari';

  @override
  String get tasksTitle => 'Tugas';

  @override
  String get tasksDefaultList => 'Tugasku';

  @override
  String get tasksNewTask => 'Tugas baru';

  @override
  String get tasksNewList => 'Daftar baru';

  @override
  String get tasksListNameHint => 'Nama daftar';

  @override
  String get tasksRenameList => 'Ganti nama daftar';

  @override
  String get tasksDeleteList => 'Hapus daftar';

  @override
  String get tasksDeleteListConfirm => 'Hapus daftar beserta tugasnya?';

  @override
  String get tasksEmpty => 'Tidak ada tugas di sini';

  @override
  String get tasksEmptyHint =>
      'Tambahkan hal yang harus dilakukan; tugas dengan tenggat juga muncul di kalender.';

  @override
  String tasksCompleted(int count) {
    return 'Selesai ($count)';
  }

  @override
  String get tasksClearCompleted => 'Hapus yang selesai';

  @override
  String get taskEditTitle => 'Edit tugas';

  @override
  String get taskTitleHint => 'Apa yang perlu dilakukan?';

  @override
  String get taskNotesHint => 'Tambahkan detail';

  @override
  String get taskDue => 'Tenggat';

  @override
  String get taskNoDue => 'Tanpa tanggal';

  @override
  String get taskTime => 'Waktu';

  @override
  String get taskNoTime => 'Tanpa waktu';

  @override
  String get taskReminderAtDue => 'Ingatkan saat jatuh tempo';

  @override
  String get taskList => 'Daftar';

  @override
  String get taskStar => 'Beri bintang';

  @override
  String get taskDelete => 'Hapus tugas';

  @override
  String get taskDeleted => 'Tugas dihapus';

  @override
  String get taskAddSubtask => 'Tambah subtugas';

  @override
  String get taskOverdue => 'Terlewat';

  @override
  String get calendarViewYear => 'Tahun';

  @override
  String get calendarViewWeek => 'Minggu';

  @override
  String get calendarPinchHint =>
      'Cubit dengan dua jari untuk berpindah antara tahun, bulan, dan minggu';

  @override
  String get calendarPrevious => 'Sebelumnya';

  @override
  String get calendarNext => 'Berikutnya';

  @override
  String get themeWhite => 'Putih';

  @override
  String get themeStraw => 'Jerami';

  @override
  String get calendarSwipe => 'Geser untuk ganti minggu/hari di kalender';

  @override
  String get calendarSwipeInfo =>
      'Jika mati, hanya tombol panah yang mengganti bulan atau minggu.';

  @override
  String calendarMoved(String day) {
    return 'Dipindahkan ke $day';
  }

  @override
  String get gcalTitle => 'Google Kalender';

  @override
  String get gcalInfo =>
      'Acara dari Google Kalender muncul di sini (hanya-baca). Kamu bisa menautkan catatan; tidak ada yang ditulis ke Google.';

  @override
  String get gcalConnect => 'Hubungkan Google Kalender';

  @override
  String get gcalConnectFailed => 'Tidak dapat menghubungkan Google Kalender';

  @override
  String get gcalCalendars => 'Kalender yang ditampilkan';

  @override
  String get gcalRefresh => 'Muat ulang';

  @override
  String get gcalDisconnect => 'Putuskan';

  @override
  String get gcalError =>
      'Google Kalender tidak dapat dijangkau sekarang; menampilkan acara yang tersimpan.';

  @override
  String get gcalReadOnly =>
      'Acara Google Kalender · edit yang berulang di Google Kalender';

  @override
  String get gcalOpenInGoogle => 'Buka di Google Kalender';

  @override
  String get calendarMeetingNote => 'Catatan rapat';

  @override
  String get calendarLinkedNotes => 'Catatan tertaut';

  @override
  String get calendarUnlinkNote => 'Lepas tautan';

  @override
  String gcalSyncedAt(String time) {
    return 'Terakhir disinkron $time';
  }

  @override
  String get calendarLinked => 'Ditautkan ke kalender';

  @override
  String get calendarLinkNote => 'Tautkan ke kalender';

  @override
  String get calendarLinkToDay => 'Tautkan ke hari';

  @override
  String get calendarLinkNewEvent => 'Buat acara dan tautkan';

  @override
  String get calendarLinkToEvent => 'Tautkan ke acara';

  @override
  String get calendarHolidays => 'Hari libur nasional (Turki)';

  @override
  String get calendarHolidayEstimated => 'perkiraan';

  @override
  String get calendarDayNote => 'Catatan untuk hari ini';

  @override
  String calendarDayWrittenNotes(int count) {
    return 'Catatan yang ditulis hari itu ($count)';
  }

  @override
  String calendarMoreCount(int count) {
    return '+$count lagi';
  }

  @override
  String get calendarWeekSummaryTitle => 'Minggu ini';

  @override
  String calendarWeekSummaryPlans(int count) {
    return '$count rencana';
  }

  @override
  String calendarWeekSummaryNotes(int count) {
    return '$count catatan';
  }

  @override
  String get itemMenuTask => 'Jadikan tugas';

  @override
  String get gtasksTitle => 'Google Tasks';

  @override
  String get gtasksConnected => 'Google Tasks terhubung dan tersinkron';

  @override
  String get gtasksFailed => 'Tidak dapat sinkron dengan Google Tasks';

  @override
  String get gtasksSyncNow => 'Sinkronkan sekarang';

  @override
  String get gtasksSynced => 'Tugas tersinkron';

  @override
  String get eventSaveLocal => 'Semua perangkat';

  @override
  String get gcalWriteDenied =>
      'Izin menulis ke Google Kalender tidak diberikan';

  @override
  String get gcalDeleteConfirm =>
      'Hapus acara ini dari Google Kalender? Ini tidak dapat dibatalkan.';

  @override
  String get gcalEdit => 'Edit';

  @override
  String gcalPending(int count) {
    return '$count perubahan menunggu dikirim ke Google';
  }

  @override
  String get ocrToEvent => 'Tambahkan ke kalender sebagai acara';

  @override
  String get calendarSuggestAction => 'Tambahkan ke kalender';

  @override
  String calendarSuggest(String when) {
    return 'Catatanmu menyebut $when';
  }

  @override
  String get calendarIcsExport => 'Ekspor kalender (.ics)';

  @override
  String get calendarIcsImport => 'Impor file kalender (.ics)';

  @override
  String calendarIcsImported(int count, int skipped) {
    return '$count acara ditambahkan, $skipped sudah ada';
  }

  @override
  String get routinesTitle => 'Rutinitas';

  @override
  String get routineNew => 'Rutinitas baru';

  @override
  String get routineEdit => 'Edit rutinitas';

  @override
  String get routinesEmpty => 'Belum ada rutinitas di sini';

  @override
  String get routinesEmptyHint =>
      'Buat rencana berulang seperti rutinitas pagi: centang langkahnya dan pantau rentetanmu.';

  @override
  String get routineDoneToday => 'Selesai hari ini';

  @override
  String get routineStartToday => 'Centang hari ini';

  @override
  String get routineDone => 'Selesai';

  @override
  String get routineTitleHint => 'Nama rutinitas';

  @override
  String get routineTime => 'Waktu';

  @override
  String get routineRemind => 'Ingatkan saat waktunya';

  @override
  String get routineSteps => 'Langkah';

  @override
  String get routineStepHint => 'Langkah';

  @override
  String get routineAddStep => 'Tambah langkah';

  @override
  String get routineDeleted => 'Rutinitas dihapus';

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
      'Cari menurut nama atau fungsi (mis. jumlah, bagikan)';

  @override
  String get menuSearchEmpty => 'Tidak ada tindakan yang cocok';

  @override
  String get menuEdit => 'Edit menu';

  @override
  String get menuSectionOther => 'Lainnya';

  @override
  String get menuQuickRow => 'Taruh di baris cepat';

  @override
  String get menuReset => 'Bawaan';

  @override
  String get themeCream => 'Krem';

  @override
  String get themePeach => 'Persik';

  @override
  String get themeMint => 'Mint';

  @override
  String get themeOcean => 'Samudra';

  @override
  String get themeRose => 'Mawar';

  @override
  String get themeTangerine => 'Jeruk keprok';

  @override
  String get themeEmerald => 'Zamrud';

  @override
  String get themeAmethyst => 'Kecubung';

  @override
  String get themePickerTitle => 'Tema';

  @override
  String get reminderQuickInHour => 'Dalam 1 jam';

  @override
  String get reminderSheetTitle => 'Pengingat';

  @override
  String get reminderSheetRemove => 'Hapus';

  @override
  String get reminderSheetSave => 'Simpan';

  @override
  String get homeFolderStripHide => 'Sembunyikan baris folder';

  @override
  String get homeViewMenu => 'Tampilan & filter';

  @override
  String googleApiDisabled(String api) {
    return '$api dinonaktifkan di proyek Google Cloud aplikasi ini. Aktifkan di konsol lalu hubungkan lagi.';
  }

  @override
  String get googleApiEnable => 'Aktifkan';

  @override
  String googleScopeMissing(String api) {
    return 'Izin $api tidak diberikan. Centang kotak izin saat menghubungkan.';
  }

  @override
  String get friendsEmptyTitle => 'Belum ada kontak di sini';

  @override
  String get friendsFilterHint => 'Cari kontak';

  @override
  String get friendsNoName => 'Tanpa nama';

  @override
  String get friendsSharedFolders => 'Folder bersama';

  @override
  String get friendsNoSharedFolders =>
      'Kamu belum berbagi folder dengan orang ini.';

  @override
  String friendsSince(String date) {
    return 'Di kontakmu sejak $date';
  }

  @override
  String get friendsCopyEmail => 'Salin email';

  @override
  String get friendsEmailCopied => 'Email disalin';

  @override
  String get friendsWantsToConnect => 'Ingin menambahkanmu sebagai kontak';

  @override
  String get friendsSendToEmail => 'Kirim permintaan ke alamat ini';

  @override
  String get friendsSent => 'Terkirim';

  @override
  String get friendsAlreadyShort => 'Di kontak';

  @override
  String get settingsGroupAccount => 'Akun';

  @override
  String get settingsGroupApp => 'Aplikasi';

  @override
  String get settingsUpdatesTitle => 'Pembaruan dan versi';

  @override
  String get settingsGroupData => 'Data dan privasi';

  @override
  String get settingsGroupOther => 'Lainnya';

  @override
  String friendsCountSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kontak',
      one: '1 kontak',
      zero: 'Belum ada kontak',
    );
    return '$_temp0';
  }

  @override
  String friendsRequestsSummary(int count) {
    return '$count tertunda';
  }

  @override
  String get inkFixApply => 'Rapikan bentuk';

  @override
  String get inkShapeSuggestTitle => 'Kenali bentuk';

  @override
  String get inkShapeSuggestInfo =>
      'Gambar lingkaran, kotak, garis, atau panah kasar untuk mendapat tombol rapikan.';

  @override
  String get inkMarkFixTitle => 'Rapikan centang dan silang';

  @override
  String get inkMarkFixInfo =>
      'Menampilkan tombol rapikan untuk tanda ✓ dan ✗ tulisan tangan.';

  @override
  String get inkMarkFixAskTitle => 'Aktifkan perapian centang dan silang?';

  @override
  String get inkMarkFixAskBody =>
      'Centang dan silang tulisan tangan bisa dirapikan. Kamu mengonfirmasi masing-masing dengan tombol kecil di sebelahnya; bisa dimatikan di pengaturan pena.';

  @override
  String get inkMarkFixAskYes => 'Aktifkan';

  @override
  String get inkMarkFixAskNo => 'Tidak';

  @override
  String get inkPinPen => 'Sematkan pena ini';

  @override
  String get inkPinnedPen => 'Pena tersemat · tahan untuk menghapus';

  @override
  String get reminderLevelTitle => 'Notifikasi';

  @override
  String get reminderLevelLow => 'Rendah';

  @override
  String get reminderLevelNormal => 'Normal';

  @override
  String get reminderLevelHigh => 'Tinggi';

  @override
  String get reminderLevelUrgent => 'Mendesak';

  @override
  String get reminderLevelLowInfo => 'Senyap; hanya di panel notifikasi';

  @override
  String get reminderLevelNormalInfo => 'Suara normal, tanpa pop-up';

  @override
  String get reminderLevelHighInfo => 'Suara dan pop-up di atas layar';

  @override
  String get reminderLevelUrgentInfo =>
      'Layar penuh, prioritas tertinggi (seperti alarm)';

  @override
  String get itemMenuRemind => 'Ingatkan';

  @override
  String get taskContactHint => 'Orang (ke / dari)';

  @override
  String get taskGmailHint => 'Tautan Gmail';

  @override
  String dueBadgeTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pengingat/tugas menunggu',
      one: '1 pengingat/tugas menunggu',
    );
    return '$_temp0';
  }

  @override
  String get dueBadgeBody =>
      'Jatuh tempo sekarang dan tugas hari ini — di beranda';

  @override
  String get dueBadgeChannel => 'Menunggu (lencana ikon)';

  @override
  String get quickRowAttach => 'Tambah';

  @override
  String get quickRowColor => 'Warna teks (tahan: pilih favorit)';

  @override
  String get penModePenOnlyOn =>
      'Mode pena · Hanya stilus: aktif (jari menggulir)';

  @override
  String get penModePenOnlyOff =>
      'Mode pena · Hanya stilus: mati (jari juga menggambar)';

  @override
  String get penModeSettings => 'Pengaturan';

  @override
  String get quickRowBold => 'Tebal';

  @override
  String get quickRowBullet => 'Poin';

  @override
  String get quickRowHeading => 'Judul (bergiliran)';

  @override
  String get quickRowPhoto => 'Tambah foto';

  @override
  String get quickRowFile => 'Lampirkan file';

  @override
  String get quickRowPen => 'Tulis dengan pena · tahan: pengaturan pena';

  @override
  String get editorBarEraser =>
      'Penghapus · membuka mode pena dengan penghapus';

  @override
  String get quickRowReminder => 'Pengingat';

  @override
  String get hideBarWhileTyping => 'Sembunyikan bilah bawah saat mengetik';

  @override
  String get hideBarWhileTypingInfo =>
      'Bilah bawah turun saat kamu mengetik dan kembali saat berhenti.';

  @override
  String get typingBarHideDelay => 'Jeda sembunyi';

  @override
  String get typingBarHideDelayInfo =>
      'Berapa lama setelah mulai mengetik bilah disembunyikan';

  @override
  String get typingBarShowDelay => 'Jeda muncul kembali';

  @override
  String get typingBarShowDelayInfo =>
      'Berapa lama setelah berhenti mengetik bilah kembali';

  @override
  String secondsValue(String value) {
    return '$value dtk';
  }

  @override
  String get tipHideBarTyping =>
      'Bilah bawah tersembunyi saat mengetik dan kembali saat jeda. Kamu bisa mematikannya di Pengaturan.';

  @override
  String get addToNoteTitle => 'Tambahkan ke catatan';

  @override
  String get addToNewNote => 'Catatan baru';

  @override
  String get addToNoteEmpty => 'Belum ada catatan lain';

  @override
  String get calendarLinkExistingNote => 'Tautkan catatan yang ada';

  @override
  String get routineFromNote => 'Buat rutinitas dari catatan';

  @override
  String get quickRowSubheading => 'Subjudul';

  @override
  String get quickRowItalic => 'Miring';

  @override
  String get quickRowUnderline => 'Garis bawah';

  @override
  String get quickRowHighlight => 'Sorot';

  @override
  String get quickRowSpellOn =>
      'Perbaikan ejaan: aktif (setiap kata diperbaiki otomatis)';

  @override
  String get quickRowSpellOff => 'Perbaikan ejaan: mati';

  @override
  String get quickRowPackage => 'Kemas';

  @override
  String get notePackageHint => 'Teks panjang — kemas agar rapi';

  @override
  String get quickRowDictation => 'Dikte';

  @override
  String get notePackageSelectFirst =>
      'Pilih teks untuk dikemas (atau ketuk paragraf panjang)';

  @override
  String notePackageCount(int count) {
    return '$count item';
  }

  @override
  String get notePackageUnpack => 'Bongkar (kembalikan ke catatan)';

  @override
  String get pinnedPenWrite => 'Tulis di atasnya dengan pena';

  @override
  String get pinnedShrinkToFit => 'Perkecil saat dipersempit';

  @override
  String get quickRowCamera => 'Ambil foto';

  @override
  String get quickRowScan => 'Pindai dokumen';

  @override
  String get quickRowDate => 'Sisipkan tanggal dan waktu';

  @override
  String get spellAutoTitle => 'Koreksi otomatis';

  @override
  String get spellLearnTitle => 'Koreksi yang belajar';

  @override
  String get spellCheckDoneTitle => 'Periksa item yang dicentang juga';

  @override
  String get spellCheckDoneSubtitle =>
      'Jika mati, item yang dicentang tidak digarisbawahi';

  @override
  String get spellManualHint => 'Ketik kata yang benar';

  @override
  String get spellManualFix => 'Perbaiki manual';

  @override
  String get spellLearnSubtitle =>
      'Mempelajari kata yang kamu perbaiki sendiri atau pilih dari saran keyboard. Kamus pribadimu disinkronkan dengan akunmu.';

  @override
  String spellLearnedCount(int count) {
    return '$count koreksi dipelajari';
  }

  @override
  String get spellForget => 'Lupakan yang dipelajari';

  @override
  String get spellForgotten => 'Koreksi yang dipelajari dihapus';

  @override
  String get spellModeTitle => 'Pemeriksa ejaan';

  @override
  String get spellModeInfo =>
      'Hanya tampilkan: kesalahan digarisbawahi. Otomatis: memperbaiki jika yakin.';

  @override
  String get spellModeOff => 'Mati';

  @override
  String get spellModeShow => 'Hanya tampilkan';

  @override
  String get spellModeAuto => 'Otomatis';

  @override
  String get spellAddToDictionary => 'Tambahkan ke kamus';

  @override
  String spellAlwaysFix(String word) {
    return 'Selalu perbaiki: $word';
  }

  @override
  String get spellKeepInNote => 'Abaikan di catatan ini';

  @override
  String get spellReviewAction => 'Periksa ejaan';

  @override
  String get spellReviewNoteOption => 'Periksa catatan ini';

  @override
  String get spellReviewClean => 'Tidak ada masalah ejaan';

  @override
  String get spellReviewCleanHint =>
      'Semua kata di catatan ini terlihat benar.';

  @override
  String spellReviewFixAll(int count) {
    return 'Perbaiki semua ($count)';
  }

  @override
  String spellReviewApply(int count) {
    return 'Terapkan ($count)';
  }

  @override
  String get spellReviewSkip => 'Lewati';

  @override
  String get spellReviewHintBadge => 'Petunjuk konteks';

  @override
  String spellReviewFixed(int count) {
    return '$count perbaikan ejaan diterapkan';
  }

  @override
  String get lineTaskRetime => 'Ubah waktu';

  @override
  String get lineTaskDone => 'Selesai';

  @override
  String get lineTaskUndone => 'Tandai belum selesai';

  @override
  String get lineTaskDetails => 'Detail (tingkat, ulang, kontak)';

  @override
  String get lineTaskDelete => 'Hapus pengingat';

  @override
  String get inkShapeTriangle => 'Segitiga';

  @override
  String get inkShapeTable => 'Tabel';

  @override
  String get homeFolderStripShort => 'Baris folder';

  @override
  String get homeCalendarStripShort => 'Strip kalender';

  @override
  String get homeCalendarStrip => 'Strip kalender di atas';

  @override
  String get homeCalendarStripInfo =>
      'Kalender dengan acara, tugas, dan hari libur di atas beranda.';

  @override
  String get homeCalendarStripExpand => 'Perluas strip kalender';

  @override
  String get homeCalendarStripCollapse => 'Ciutkan strip kalender';

  @override
  String get folderMenuEdit => 'Atur ulang · hapus';

  @override
  String get themeClassic => 'Klasik';

  @override
  String get themeNewsprint => 'Kertas koran';

  @override
  String get themeNotebook => 'Buku catatan';

  @override
  String get themeGraphite => 'Grafit';

  @override
  String get themeLedger => 'Buku besar';

  @override
  String get themeGroupCalm => 'Tenang';

  @override
  String get themeGroupPaper => 'Kertas';

  @override
  String get themeGroupVivid => 'Cerah';

  @override
  String get spellLearnedTitle => 'Ejaan yang dipelajari';

  @override
  String get spellLearnedInfo =>
      'Kata yang kamu ketik lalu perbaiki sendiri, atau pilih dari saran keyboard. Kamu bisa menambah sendiri: salah → benar (langsung berlaku).';

  @override
  String get spellLearnedSettingInfo =>
      'Lihat koreksi yang dipelajari, tambah atau hapus';

  @override
  String get spellLearnedWrong => 'Salah';

  @override
  String get spellLearnedRight => 'Benar';

  @override
  String get spellLearnedAdd => 'Tambah';

  @override
  String get spellLearnedEmpty => 'Belum ada koreksi yang dipelajari.';

  @override
  String spellLearnedSeen(int count) {
    return '$count kali';
  }

  @override
  String get spellLearnedKept =>
      'Kata yang dibiarkan (kamu membatalkan koreksi)';

  @override
  String get spellRulesOnlyTitle => 'Hanya aturan';

  @override
  String get spellRulesOnlySubtitle =>
      'Hanya salah eja yang diketahui dan koreksi yang kamu ajarkan yang diperbaiki; tanpa tebakan.';

  @override
  String get spellRejectedTitle =>
      'Koreksi yang tidak akan dilakukan lagi (kamu membatalkan atau mengubahnya)';

  @override
  String get inkEraserOffer => 'Pilih penghapus';

  @override
  String get inkPenOffer => 'Kembali ke pena';

  @override
  String get tipPenShapeHold =>
      'Tahan diam di akhir goresan: garis, kotak, dan lingkaran menjadi bentuk rapi.';

  @override
  String get tipPenEraserHold =>
      'Untuk menghapus, tekan lama goresan → ketuk tombol penghapus. Dua jari = gulir/perbesar.';

  @override
  String backupStatusCloud(int count) {
    return 'Cloud: $count catatan di akun Google-mu, perubahan disinkronkan otomatis';
  }

  @override
  String get backupStatusGuest =>
      'Tanpa cadangan cloud: catatan hanya di perangkat ini. Tautkan akun Google atau buat cadangan lengkap.';

  @override
  String backupStatusLast(String date, int count) {
    return 'Cadangan lengkap terakhir: $date · $count catatan';
  }

  @override
  String get backupStatusNever => 'Belum ada cadangan lengkap di perangkat ini';

  @override
  String get attachmentAddText => 'Tulis di atasnya';

  @override
  String get stylusTogglesOn => 'Pena menulis';

  @override
  String get stylusTogglesOff => 'Pena mengetuk (tidak menulis)';

  @override
  String updateBanner(String version) {
    return 'Versi baru tersedia: v$version — ketuk untuk mengunduh dan memasang';
  }

  @override
  String updateBannerReady(String version) {
    return 'v$version sudah diunduh — ketuk untuk memasang sekarang';
  }

  @override
  String updateBannerDownloading(String version, int percent) {
    return 'Mengunduh v$version… $percent%';
  }

  @override
  String updateReadyToInstall(String version) {
    return 'v$version sudah diunduh; akan dipasang saat aplikasi dibuka berikutnya';
  }

  @override
  String get updateInstallNow => 'Pasang sekarang';

  @override
  String get updateDownloadFailed =>
      'Tidak dapat mengunduh versi baru — periksa koneksi lalu ketuk lagi';

  @override
  String get updateInstallFailed => 'Pemasangan tidak selesai — coba lagi';

  @override
  String get autoUpdateTitle => 'Perbarui otomatis';

  @override
  String get autoUpdateInfo =>
      'Versi baru diunduh di latar dan dipasang saat aplikasi dibuka berikutnya';

  @override
  String get updateInstall => 'Perbarui';

  @override
  String get updateNeedsPermission =>
      'Izinkan aplikasi ini memasang aplikasi tak dikenal, lalu ketuk Perbarui lagi';

  @override
  String get updateTapToCheck => 'Ketuk untuk memeriksa pembaruan';

  @override
  String get updateReopenOn => 'Terbuka sendiri setelah diperbarui';

  @override
  String get updateReopenOff => 'Buka ulang setelah pembaruan: izinkan';

  @override
  String get updateChecking => 'Memeriksa pembaruan…';

  @override
  String get updateUpToDate => 'Kamu memakai versi terbaru';

  @override
  String get releaseNotesTitle => 'Catatan rilis';

  @override
  String get settingsWritingTitle => 'Pena, menulis, dan layar';

  @override
  String get settingsWritingSummary => 'Pena · Perbaikan ejaan · Strip beranda';

  @override
  String get settingsPenSection => 'Pena';

  @override
  String get settingsSpellSection => 'Perbaikan ejaan';

  @override
  String get settingsScreenSection => 'Beranda dan layar catatan';

  @override
  String get settingsShowAllNotes => 'Catatan dalam folder juga di beranda';

  @override
  String get settingsShowAllNotesInfo =>
      'Catatan dalam folder juga tampil di beranda (kecuali arsip dan tersembunyi).';

  @override
  String get settingsAttachmentsExpanded => 'Strip lampiran terbuka di catatan';

  @override
  String get settingsListPaneCollapsed =>
      'Sembunyikan daftar catatan di layar lebar (fokus)';

  @override
  String get settingsListPaneCollapsedInfo =>
      'Di tablet dan web daftar dimulai tertutup saat catatan terbuka.';

  @override
  String get pinnedSideToggle => 'Penempatan: atas / kiri / kanan';

  @override
  String get pinnedSideTitle => 'Posisi panel';

  @override
  String get pinnedSideTop => 'Atas';

  @override
  String get pinnedSideLeft => 'Kiri';

  @override
  String get pinnedSideRight => 'Kanan';

  @override
  String releaseNotesToastTitle(String version) {
    return 'Yang baru · v$version';
  }

  @override
  String releaseNotesToastMore(int count) {
    return '+$count lagi';
  }

  @override
  String get releaseNotesToastAll => 'Lihat semua';

  @override
  String get updateInstalling =>
      'Diunduh — memasang; aplikasi akan ditutup dan dibuka lagi';

  @override
  String get updateAborted =>
      'Pemasangan dibatalkan — ketuk untuk mencoba lagi';

  @override
  String get updateOpenedBrowser => 'Halaman unduhan dibuka di browser';

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
      other: '$count gambar',
      one: 'Gambar',
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
      other: '$count rekaman suara',
      one: 'Rekaman suara',
    );
    return '$_temp0';
  }

  @override
  String get quickAddKeepOne => 'Setidaknya satu opsi harus tetap terlihat';

  @override
  String get attachmentUploadNow => 'Coba sekarang';

  @override
  String uploadPendingTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lampiran menunggu diunggah',
      one: '1 lampiran menunggu diunggah',
    );
    return '$_temp0';
  }

  @override
  String get uploadPendingBody => 'Diunggah saat kamu membuka aplikasi.';

  @override
  String get uploadPendingChannel => 'Unggahan lampiran tertunda';

  @override
  String placementHintShort(String view) {
    return 'Ditambahkan sebagai $view · ketuk sakelar untuk mengubah';
  }

  @override
  String get listPaneRight => 'Daftar catatan di kanan';

  @override
  String get listPaneRightInfo =>
      'Di tampilan terpisah (tablet, jendela lebar) daftar berada di kanan catatan';

  @override
  String get listPaneMoveRight => 'Pindahkan daftar ke kanan';

  @override
  String get noteOpenSide => 'Buka berdampingan';

  @override
  String get micBusySideNote => 'Mikrofon sedang dipakai di catatan lain';

  @override
  String get noteCloseSide => 'Tutup catatan samping';

  @override
  String get listPaneMoveLeft => 'Pindahkan daftar ke kiri';

  @override
  String get quickRowEditTitle => 'Menu cepat (atas, saat mengetik)';

  @override
  String get quickRowEditInfo =>
      'Ketuk untuk menambah atau menghapus dari menu. Perubahan langsung berlaku, tidak perlu disimpan.';

  @override
  String get quickRowEditShown => 'Di menu';

  @override
  String get quickRowEditAvailable => 'Tersedia';

  @override
  String get quickRowEditEmpty => 'Menu kosong — tambahkan tombol di bawah';

  @override
  String get quickRowEditReset => 'Kembalikan ke bawaan';

  @override
  String get quickRowShortPen => 'Pena';

  @override
  String get quickRowShortSpell => 'Ejaan';

  @override
  String get quickRowShortColor => 'Warna teks';

  @override
  String get quickRowShortHeading => 'Judul';

  @override
  String get quickEntryHint => 'Ketik atau ucapkan: pisang apel, 2 susu…';

  @override
  String get quickEntryListening => 'Mendengarkan…';

  @override
  String get quickEntryMic => 'Tambah dengan suara';

  @override
  String get quickEntryMicStop => 'Hentikan mendengarkan';

  @override
  String get quickListEmpty =>
      'Ketik di atas, bicara, atau ketuk di bawah; daftarmu terbentuk di sini.';

  @override
  String get smartListHint =>
      'Ketik atau ucapkan susu, roti…; untuk bawaan, ucapkan “daftar bawaan”.';

  @override
  String get quickListDone => 'Selesai';

  @override
  String get quickListAisleSort => 'Urutkan menurut lorong';

  @override
  String get quickListOpenInNote => 'Buka sebagai catatan';

  @override
  String get quickListDiscard => 'Buang';

  @override
  String get quickListFrequent => 'Yang biasa kamu beli';

  @override
  String get quickListLeftovers => 'Dari terakhir kali';

  @override
  String get quickListAddAll => 'Tambah semua';

  @override
  String quickListSaved(String title) {
    return '“$title” disimpan';
  }

  @override
  String get quickListOpen => 'Buka';

  @override
  String get quickListRemove => 'Hapus';

  @override
  String quickListCorrected(String typed) {
    return 'Kamu mengetik “$typed”; ketuk untuk urungkan';
  }

  @override
  String quickListRestored(String typed) {
    return 'Dibiarkan sebagai “$typed”; tidak akan dikoreksi lagi';
  }

  @override
  String get quickDropTitle => 'Tambah cepat';

  @override
  String get quickDropInfo =>
      'Ketik atau bicara; masuk ke catatan yang kamu pilih';

  @override
  String get quickDropHint =>
      'susu, roti… atau “tambah susu ke daftar belanja”';

  @override
  String get quickDropTarget => 'Tambahkan ke catatan mana?';

  @override
  String get quickDropNoNotesNew =>
      'Belum ada daftar atau catatan teks untuk ditambah: yang kamu tulis disimpan sebagai catatan baru.';

  @override
  String get quickDropSavingNew => 'Menyimpan sebagai catatan baru…';

  @override
  String get quickDropSavedNew => 'Disimpan sebagai catatan baru';

  @override
  String get quickDropAdd => 'Tambah';

  @override
  String quickDropAdded(int count, String title) {
    return '$count item ditambahkan ke “$title”';
  }

  @override
  String quickDropAddedText(String title) {
    return 'Ditambahkan ke “$title”';
  }

  @override
  String quickDropNothingNew(String title) {
    return 'Semuanya sudah ada di “$title”';
  }

  @override
  String get quickDropKeyboard => 'Keyboard saat dibuka';

  @override
  String get quickDropMicAuto => 'Dengarkan saat dibuka';

  @override
  String get noteExpiry => 'Arsipkan pada…';

  @override
  String get noteExpiryDay => '1 hari';

  @override
  String get noteExpiry3Days => '3 hari';

  @override
  String get noteExpiryWeek => '1 minggu';

  @override
  String get noteExpiryMonth => '1 bulan';

  @override
  String get noteExpiryPick => 'Pilih tanggal & waktu';

  @override
  String get noteExpiryRemove => 'Hapus pengatur waktu';

  @override
  String noteExpiryChip(String date) {
    return 'Diarsipkan $date';
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
  String get smartList => 'Daftar cerdas';

  @override
  String get smartListInfo =>
      'Ketik atau bicara; mengenali belanja atau bawaan dan mengelompokkan item';

  @override
  String get smartListGeneric => 'Daftar';

  @override
  String get smartListPacking => 'Daftar bawaan';

  @override
  String get smartListPharmacy => 'Daftar apotek';

  @override
  String get smartListStationery => 'Daftar alat tulis';

  @override
  String get smartListHardware => 'Daftar perkakas';

  @override
  String get smartListCamping => 'Daftar berkemah';

  @override
  String get smartListBaby => 'Tas bayi';

  @override
  String get smartListSport => 'Tas gym';

  @override
  String get sortByGroup => 'Menurut lorong / grup';

  @override
  String get finishShopping => 'Selesai belanja';

  @override
  String finishShoppingDone(int count) {
    return '$count item tercentang dibersihkan';
  }

  @override
  String get scanAny => 'Pindai';

  @override
  String get scanAnyInfo =>
      'Dokumen atau kode QR — kode QR terdeteksi otomatis';

  @override
  String get scanAnyHint =>
      'Kode QR terdeteksi otomatis. Untuk dokumen, ketuk “Pindai dokumen”.';

  @override
  String get scanQrFound => 'Kode QR ditemukan';

  @override
  String get scanUseQr => 'Gunakan kode QR';

  @override
  String get listToNumbered => 'Jadikan bernomor';

  @override
  String get listToChecklist => 'Jadikan daftar centang';

  @override
  String get quickDropWhich => 'Ini masuk ke catatan mana?';

  @override
  String get quickDropAsking => 'Mencari catatan yang tepat…';

  @override
  String quickDropAddingTo(String title) {
    return 'Menambahkan ke “$title”…';
  }

  @override
  String get quickDropWait => 'Tunggu';

  @override
  String get quickDropAiToggle => 'Tanya AI saat ragu';

  @override
  String get aiOffTitle => 'AI dimatikan';

  @override
  String get aiConsentTitle => 'Menggunakan AI';

  @override
  String get aiConsentWhat =>
      'Yang dikirim: hanya teks, catatan, atau lampiran (gambar, audio, PDF) yang kamu pilih untuk tugas itu.';

  @override
  String get aiConsentWhere =>
      'Ke mana: ke layanan Gemini Google (melalui Firebase); jika kamu memasukkan kunci sendiri, ke penyedia yang kamu pilih.';

  @override
  String get aiConsentMistakes =>
      'AI bisa keliru; periksa sendiri informasi penting.';

  @override
  String get aiConsentTurnOff =>
      'Kamu bisa mematikan AI sepenuhnya kapan saja di Pengaturan → AI.';

  @override
  String get aiConsentAccept => 'Saya setuju';

  @override
  String get aiConsentDecline => 'Nanti saja';

  @override
  String get aiPausedTitle => 'AI sementara tidak tersedia';

  @override
  String get homePullGestureTitle => 'Menarik ke bawah di atas daftar';

  @override
  String get homeSwipeRightGestureTitle => 'Geser ke kanan di Semua';

  @override
  String get homeGestureInfo =>
      'Pilih catatan atau folder dan gestur langsung membukanya';

  @override
  String get homeGestureFolders => 'Folder';

  @override
  String get homeGestureNote => 'Sebuah catatan';

  @override
  String get homeGestureFolder => 'Sebuah folder';

  @override
  String get homeGestureNone => 'Tidak ada';

  @override
  String get homeGestureMissing =>
      'Target gestur tidak ditemukan; pilih lagi di Pengaturan → Catatan';

  @override
  String get calendarExpiryTag => 'Diarsipkan';

  @override
  String get calendarExpiryRemoved => 'Waktu arsip dihapus';

  @override
  String get inkFingerAuto => 'Otomatis';

  @override
  String get inkFingerAutoNowScroll =>
      'Otomatis: pena sudah terdeteksi di perangkat ini, jadi jari menggulir.';

  @override
  String get inkFingerAutoNowDraw =>
      'Otomatis: belum ada pena terdeteksi, jadi jari menggambar; beralih ke menggulir saat pena pertama kali menyentuh.';

  @override
  String get barMoreLeftGroup => 'Grup kiri';

  @override
  String get barMoreRightGroup => 'Grup kanan (berwarna)';

  @override
  String get barMoreToRight => 'Pindahkan ke grup kanan';

  @override
  String get barMoreToLeft => 'Pindahkan ke grup kiri';

  @override
  String get layoutScopeAll => 'Terapkan ke semua';

  @override
  String get layoutScopeNote => 'Hanya catatan ini';

  @override
  String get layoutScopeInfoAll => 'Perubahan berlaku untuk semua catatan.';

  @override
  String get layoutScopeInfoNote =>
      'Catatan ini punya tata letak sendiri; perubahan hanya berlaku di sini.';

  @override
  String get layoutScopeReset => 'Atur ulang tata letak catatan ini';

  @override
  String quickRowEditNotHere(String names) {
    return 'Tidak ditampilkan di catatan ini: $names';
  }

  @override
  String get barMoreEdit => 'Edit bilah bawah';

  @override
  String get barMoreEditHint =>
      'Tombol tersemat (📌) tetap di bilah (3 pertama muat di ponsel); sisanya ada di menu ini. Tekan lama dan seret untuk mengatur ulang.';

  @override
  String get barMoreToBar => 'Pindahkan ke bilah';

  @override
  String get barMoreToMenu => 'Pindahkan ke menu';

  @override
  String menuEditInlineHint(int count) {
    return 'Tekan lama dan seret untuk mengatur ulang · ⊖ sembunyikan · ☆ baris cepat (maks. $count)';
  }

  @override
  String get menuHiddenGroup => 'Tersembunyi';

  @override
  String get quickDropSettings => 'Pengaturan tambah cepat';

  @override
  String quickDropPreviewText(String title, String text) {
    return '→ $title · $text';
  }

  @override
  String quickDropPreviewItems(String title, String items, int count) {
    return '→ $title · $items ($count baru)';
  }

  @override
  String get quickDropPickMyself => 'Aku yang pilih';

  @override
  String get quickDropFindNote => 'Cari catatan';

  @override
  String quickDropPreviewReminder(String when, String text) {
    return '⏰ $when · $text';
  }

  @override
  String get quickDropSavedReminder =>
      'Disimpan sebagai catatan dengan pengingat';

  @override
  String quickDropPreviewCalendar(String day, String text) {
    return '📅 $day · $text';
  }

  @override
  String quickDropSavedCalendar(String day) {
    return 'Catatan ditambahkan ke kalender · $day';
  }

  @override
  String quickDropPreviewMulti(String summary, int count) {
    return '→ $summary ($count catatan)';
  }

  @override
  String quickDropAddedMulti(int count) {
    return 'Ditambahkan ke $count catatan';
  }

  @override
  String get aiNeedsProTitle => 'AI bagian dari Pro';

  @override
  String get proTitle => 'Versi Lengkap';

  @override
  String get proSettingsSubtitle =>
      'Lite vs Versi Lengkap, kredit keputusan, pembelian';

  @override
  String get proStatusFree => 'Paketmu: Lite (Gratis · Tanpa iklan)';

  @override
  String get proStatusLifetime => 'Paketmu: Versi Lengkap (Seumur hidup)';

  @override
  String get proTiersTitle => 'Paket';

  @override
  String get proTierFree => 'Lite';

  @override
  String get proTierLifetime => 'Versi Lengkap';

  @override
  String get proRowBasics =>
      'Catatan, daftar, pena, PDF, pengingat, kalender; pemeriksa ejaan, dikte, OCR, barcode di perangkat, Mode Toko';

  @override
  String get proRowUnlimited =>
      'Catatan, folder, lampiran, dan perangkat tanpa batas';

  @override
  String get proRowSync => 'Sinkronisasi cloud';

  @override
  String get proSyncPeriodic => 'Berkala (5 mnt)';

  @override
  String get proSyncInstant => 'Instan';

  @override
  String get proRowAttachments => 'Lampiran disimpan di';

  @override
  String get proAttachDrive => 'Drive-mu';

  @override
  String get proAttachCloud => 'Drive + Bersama';

  @override
  String get proRowHistory => 'Riwayat 30 versi, cadangan berkata sandi';

  @override
  String get proRowLooks => 'Semua tema, 19 fon, gaya kertas';

  @override
  String get proRowAi => 'Keputusan Cerdas (lorong, rute, tag)';

  @override
  String get proDecisionsIncluded => '750 panggilan';

  @override
  String get proRowOwnKey => 'Kunci Gemini milikmu';

  @override
  String get proLockedBadge => 'Di Versi Lengkap';

  @override
  String get proBuyTitle => 'Beli';

  @override
  String get proPlanLifetime => 'Versi Lengkap · Sekali bayar (Seumur hidup)';

  @override
  String get proPlanDecisionPack => 'Paket +1.000 Keputusan Cerdas';

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
      'Tanpa langganan, tanpa iklan. Versi Lengkap adalah pembelian sekali seumur hidup termasuk 750 Keputusan Cerdas. Saat kredit habis, aplikasi dan semua fitur di perangkat tetap berjalan tanpa batas; kamu bisa menambah Paket +1.000 Keputusan atau memakai kunci Gemini sendiri.';

  @override
  String get proLoading => 'Mengambil harga dari Google Play…';

  @override
  String get proUnavailable => 'Tidak dapat menjangkau Google Play.';

  @override
  String get proElsewhere =>
      'Pembelian dilakukan di ponselmu: di aplikasi Android, Pengaturan → Versi Lengkap. Yang kamu beli juga terbuka di sini pada akun ini.';

  @override
  String get proGuest =>
      'Masuk dengan Google untuk membeli: akun tamu hanya ada di perangkat ini, jadi pembelian bisa hilang bersamanya.';

  @override
  String get proNoticePending =>
      'Pembayaran tertunda; paketmu terbuka otomatis setelah dikonfirmasi.';

  @override
  String get proNoticeCanceled => 'Pembelian dibatalkan.';

  @override
  String get proNoticeFailed =>
      'Pembelian tidak dapat diselesaikan. Coba lagi sebentar lagi.';

  @override
  String get proNoticeVerifyFailed =>
      'Tidak dapat memverifikasi pembelian; aplikasi mencoba lagi saat dibuka berikutnya. Google Play mengembalikan pembayaran yang tidak terverifikasi.';

  @override
  String get proNoticeOtherAccount =>
      'Pembelian ini milik akun lain. Masuk dengan akun itu untuk memakainya.';

  @override
  String get proNoticeDone => 'Terima kasih! Paketmu sudah terbuka.';

  @override
  String get proNoticeRestored => 'Pembelianmu dipulihkan.';

  @override
  String get proNoticeNothing =>
      'Tidak ada pembelian untuk dipulihkan di akun Google Play ini.';

  @override
  String get proIncluded => 'Termasuk';

  @override
  String get proNotIncluded => 'Tidak termasuk';

  @override
  String get decisionsSectionTitle => 'Keputusan Cerdas';

  @override
  String get decisionsSectionSubtitle =>
      'Lorong belanja tak dikenal, target tambah cepat, dan saran tag';

  @override
  String get decisionsQuotaByok =>
      'Kunci Gemini sendiri aktif · Keputusan cerdas tanpa batas';

  @override
  String decisionsQuotaSummary(int calls, String tokens) {
    return 'Sisa keputusan cerdas: $calls · anggaran $tokens token';
  }

  @override
  String get decisionsQuotaFreeHint =>
      'Aturan cerdas di perangkat gratis · 750 keputusan termasuk di Versi Lengkap';

  @override
  String get decisionsTurnOffTitle => 'Matikan keputusan cerdas';

  @override
  String get decisionsTurnOffBody =>
      'Jika mati, semua kamus di perangkat, pemeriksa ejaan, dan aturan belanja tetap bekerja gratis.';

  @override
  String get decisionsByokTitle => 'Kunci Gemini API sendiri (Lanjutan)';

  @override
  String get decisionsByokInfo =>
      'Saat keputusan habis, lanjutkan dengan kunci Gemini-mu; kunci tetap di perangkat ini.';

  @override
  String get calendarDayLinkRemoved => 'Catatan dihapus dari hari ini';

  @override
  String get calendarLinkTime => 'Waktu';

  @override
  String get calendarLinkAllDay => 'Sepanjang hari';

  @override
  String get driveOnboardTitle => 'Simpan lampiran di semua perangkat';

  @override
  String get driveOnboardBody =>
      'Lampiran foto, PDF, dan audio dicadangkan ke folder \"Notlar\" di Google Drive-mu, jadi kamu melihat lampiran yang sama di ponsel, tablet, dan web.';

  @override
  String get driveOnboardConnect => 'Hubungkan Drive';

  @override
  String get driveOnboardLater => 'Nanti';

  @override
  String get exportMarkdownZip => 'Ekspor Markdown (.zip)';

  @override
  String get exportMarkdownZipInfo =>
      'Mengekspor catatan sebagai file .md portabel menurut folder';

  @override
  String get exportMarkdownZipEmpty => 'Tidak ada catatan untuk diekspor';

  @override
  String exportMarkdownZipDone(int count) {
    return '$count catatan diekspor sebagai Markdown (.zip)';
  }

  @override
  String get storeMode => 'Mode toko';

  @override
  String get storeModeHideChecked => 'Sembunyikan yang dicentang';

  @override
  String get storeModeShowChecked => 'Tampilkan yang dicentang';

  @override
  String storeModeRemaining(int remaining, int total) {
    return 'Sisa $remaining dari $total';
  }

  @override
  String get storeModeAllDone => 'Semua selesai!';

  @override
  String get storeModeAddHint => 'Tambah item dengan cepat…';

  @override
  String get backupPasswordTitle => 'Kata sandi cadangan (opsional)';

  @override
  String get backupPasswordInfo =>
      'Mengatur kata sandi melindungi cadangan dengan enkripsi kuat. Kata sandi yang terlupa tidak dapat dipulihkan.';

  @override
  String get backupPasswordHint => 'Kata sandi';

  @override
  String get backupPasswordConfirmHint => 'Konfirmasi kata sandi';

  @override
  String get backupPasswordMismatch => 'Kata sandi tidak cocok';

  @override
  String get backupWithoutPassword => 'Cadangkan tanpa kata sandi';

  @override
  String get backupWithPassword => 'Enkripsi & cadangkan';

  @override
  String get backupPasswordProLocked =>
      'Cadangan berkata sandi tersedia di paket Seumur hidup dan Pro. Cadangan tanpa kata sandi gratis; memulihkan cadangan terenkripsi selalu gratis.';

  @override
  String get backupSeeTiers => 'Lihat paket';

  @override
  String get backupEnterPasswordTitle => 'Cadangan terenkripsi';

  @override
  String get backupEnterPasswordBody =>
      'Cadangan ini dilindungi kata sandi. Masukkan kata sandi untuk memulihkan.';

  @override
  String get backupWrongPassword =>
      'Kata sandi salah atau cadangan tidak bisa didekripsi';

  @override
  String get calendarAddActionTitle => 'Apa yang ditambahkan + di kalender';

  @override
  String get calendarAddActionInfo =>
      'Ditambahkan ke hari terpilih (atau hari ini); bisa diubah di jendela.';

  @override
  String get calendarAddNote => 'Catatan';

  @override
  String get calendarAddEvent => 'Acara';

  @override
  String get calendarAddTask => 'Tugas';

  @override
  String get calendarFullPage => 'Kalender layar penuh';

  @override
  String get calendarNewDayNoteTitle => 'Catatan baru';

  @override
  String get calendarNewDayNoteOpen => 'Tulis catatan';

  @override
  String calendarSlotAddTitle(String time) {
    return 'Tambah pada $time';
  }

  @override
  String get eraserOn => 'Penghapus aktif';

  @override
  String get calendarRelToday => 'Hari ini';

  @override
  String get calendarRelTomorrow => 'Besok';

  @override
  String get calendarRelYesterday => 'Kemarin';

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
    return '$count tugas';
  }

  @override
  String calendarDayReminders(int count) {
    return '$count pengingat';
  }

  @override
  String calendarDayNotesCount(int count) {
    return '$count catatan';
  }

  @override
  String get calendarDayFree => 'Hari kosong';

  @override
  String get webWorkspaceSection => 'Ruang kerja';

  @override
  String get webOrganizeSection => 'Atur';

  @override
  String get webViewGrid => 'Tampilan kisi';

  @override
  String get webViewList => 'Tampilan daftar';

  @override
  String get webColumnsMenu => 'Kepadatan kolom';

  @override
  String get webColumnsAuto => 'Otomatis';

  @override
  String webColumnsCount(int count) {
    return '$count kolom';
  }

  @override
  String webNoteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count catatan',
      one: '1 catatan',
    );
    return '$_temp0';
  }

  @override
  String get webDriveStatusConnected => 'Drive terhubung';

  @override
  String webDriveStatusSyncing(int count) {
    return '$count sedang sinkron';
  }

  @override
  String webDriveStatusAttention(int count) {
    return '$count tertunda';
  }

  @override
  String get webSyncCloudReady => 'Sinkronisasi cloud aktif';

  @override
  String get webCacheTitle => 'Cache lampiran browser';

  @override
  String webCacheInfo(int count, String size) {
    return '$count file · $size (siap offline)';
  }

  @override
  String get webCacheEmpty => 'Belum ada lampiran di cache';

  @override
  String get webCacheClear => 'Hapus';

  @override
  String get webCacheCleared => 'Cache lampiran browser dihapus';

  @override
  String get quickRowMoreEdit => 'Edit menu cepat';

  @override
  String get quickRowDay => 'Sisipkan tanggal hari ini';

  @override
  String get tableInsert => 'Tabel';

  @override
  String get tableInsertInfo => '3 baris · 2 kolom, ubah nanti';

  @override
  String get tableName => 'Tabel';

  @override
  String get tableAddRow => 'Tambah baris';

  @override
  String get tableAddRowBelow => 'Tambah baris di bawah';

  @override
  String get tableDeleteRow => 'Hapus baris';

  @override
  String get tableColumnCount => 'Kolom';

  @override
  String get tableHeaderRow => 'Baris pertama sebagai judul';

  @override
  String get tableEqualWidths => 'Lebar kolom sama';

  @override
  String get tableDelete => 'Hapus tabel';

  @override
  String get tableOptions => 'Pengaturan tabel';

  @override
  String get tableColumnsWillDrop =>
      'Teks di kolom terakhir akan dihapus. Lanjutkan?';

  @override
  String get tableMoveHint =>
      'Tekan lama untuk memindahkan, seret sudut untuk mengubah ukuran';

  @override
  String get tableRowCount => 'Baris';

  @override
  String get tableRowsWillDrop =>
      'Teks di baris terakhir akan dihapus. Lanjutkan?';

  @override
  String get tableEditSection => 'Edit';

  @override
  String get tableShareImage => 'Gambar';

  @override
  String get tableSharePdf => 'PDF';

  @override
  String get tableShareWord => 'Word';

  @override
  String get tableShareFailed => 'Tidak dapat membagikan tabel';

  @override
  String get tableAddRowAbove => 'Tambah baris di atas';

  @override
  String get tableInsertColumn => 'Tambah kolom di kanan';

  @override
  String get tableDeleteColumn => 'Hapus kolom';

  @override
  String get tableColumnsOneWillDrop =>
      'Teks di kolom terpilih akan dihapus. Lanjutkan?';

  @override
  String get tableSortAsc => 'Urutkan A→Z';

  @override
  String get tableSortDesc => 'Urutkan Z→A';

  @override
  String get tableStripedRows => 'Baris berselang warna';

  @override
  String get tableDataSection => 'Data';

  @override
  String get tableCopyMarkdown => 'Salin Markdown';

  @override
  String get tableCopyCsv => 'Salin CSV';

  @override
  String get tablePasteData => 'Tempel CSV / TSV';

  @override
  String get tablePasteWillReplace =>
      'Isi tabel saat ini akan diganti dengan data yang ditempel. Lanjutkan?';

  @override
  String get tablePasteInvalid => 'Tidak ada data tabel valid di papan klip';

  @override
  String get tablePasted => 'Data tabel ditempel';

  @override
  String get tableSorted => 'Tabel diurutkan';

  @override
  String folderHeaderPinnedCount(int count) {
    return '$count disematkan';
  }

  @override
  String get folderNewNote => 'Catatan baru';

  @override
  String get folderFilterSort => 'Filter & urutan';

  @override
  String get folderLivePreview => 'Pratinjau';

  @override
  String get pinnedSmartActions => 'Tindakan cerdas';

  @override
  String get pinnedSmartOcr => 'Ekstrak teks';

  @override
  String get pinnedSmartSummarize => 'Ringkas & tambahkan';

  @override
  String get pinnedSmartTasks => 'Jadikan tugas';

  @override
  String get pinnedSmartAreaAsk => 'Pilih area & tanya';

  @override
  String get dashboardBackgroundGallery => 'Wallpaper pilihan';

  @override
  String get dashboardBackgroundFromDevice => 'Dari galeri';

  @override
  String get dashboardBackgroundOpacity => 'Visibilitas';

  @override
  String get wallpaperAuroraBloom => 'Mekar aurora';

  @override
  String get wallpaperCitrusSun => 'Matahari jeruk';

  @override
  String get wallpaperCoralLagoon => 'Laguna koral';

  @override
  String get wallpaperBotanicalGarden => 'Kebun botani';

  @override
  String get wallpaperLavenderDream => 'Mimpi lavender';

  @override
  String get wallpaperTerracottaStudio => 'Studio terakota';

  @override
  String get wallpaperPastelConfetti => 'Konfeti pastel';

  @override
  String get wallpaperGoldenMeadow => 'Padang keemasan';

  @override
  String get wallpaperMidnightAurora => 'Aurora tengah malam';

  @override
  String get wallpaperVelvetCosmos => 'Kosmos beludru';

  @override
  String get noteThemeAurora => 'Aurora';

  @override
  String get noteThemeCitrus => 'Jeruk';

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
  String get itemRangeSelect => 'Pilih rentang';

  @override
  String get itemInvertSelection => 'Balik pilihan';

  @override
  String get itemMoveUp => 'Pindah ke atas';

  @override
  String get itemMoveDown => 'Pindah ke bawah';

  @override
  String get itemDivider => 'Pemisah';

  @override
  String get selectionToolbarMore => 'Tindakan lain';

  @override
  String get selectionMenuEdit => 'Edit';

  @override
  String get selectionMenuEditDone => 'Selesai';

  @override
  String get selectionMenuEditHint =>
      'Ketuk untuk menambah ke atau menghapus dari baris utama';

  @override
  String get itemsBatchFormat => 'Format massal';

  @override
  String itemsDeletedUndo(int count) {
    return '$count item dihapus';
  }

  @override
  String itemsFormattedCount(int count) {
    return '$count item diformat';
  }

  @override
  String get ecosystemDosyalarimTitle => 'Kelola semua file dengan Dosyalarım';

  @override
  String get ecosystemDosyalarimSubtitle =>
      'Tanda tangani PDF, edit file Word dan Excel, dan bagikan dengan mudah bersama catatanmu.';

  @override
  String get ecosystemGetApp => 'Jelajahi Dosyalarım';

  @override
  String get ecosystemDismiss => 'Tutup';

  @override
  String shopBudgetCart(String amount) {
    return 'Keranjang: Rp $amount';
  }

  @override
  String shopBudgetEstimated(String amount) {
    return 'Perkiraan: Rp $amount';
  }

  @override
  String shopBudgetLimit(String amount) {
    return 'Anggaran: Rp $amount';
  }

  @override
  String get shopBudgetSet => 'Atur anggaran';

  @override
  String get shopBudgetHint => 'mis. 150000';

  @override
  String get shopAllStores => 'Semua';

  @override
  String shopPriceTitle(String item) {
    return 'Harga & Lorong · $item';
  }

  @override
  String get shopUnitPriceLabel => 'Harga (Rp)';

  @override
  String get shopStoreLabel => 'Toko';

  @override
  String get shopAisleLabel => 'Lorong';

  @override
  String get shopPriceCompareHeader => 'Riwayat harga toko';

  @override
  String get shopClearPrice => 'Hapus harga';

  @override
  String get shopRecipesTitle => 'Paket Menu & Resep';

  @override
  String get shopRecipesSearchHint => 'Cari resep…';

  @override
  String shopServingsCount(int count) {
    return '$count porsi';
  }

  @override
  String get shopAddToList => 'Tambahkan ke daftar';

  @override
  String get shopNewCustomRecipe => 'Simpan resep kustom';

  @override
  String get shopRecipeNameHint => 'Nama resep';

  @override
  String get shopIngredientsHint =>
      'Bahan (pisahkan dengan koma: 500 g daging, 2 tomat)';

  @override
  String get shopCustomBadge => 'Kustom';

  @override
  String shopAisleOrderTitle(String store) {
    return 'Urutan Lorong · $store';
  }

  @override
  String get shopResetOrder => 'Kembalikan bawaan';

  @override
  String get shopReceiptTitle => 'Perbarui Harga dari Struk';

  @override
  String get shopReceiptCamera => 'Foto struk';

  @override
  String get shopReceiptGallery => 'Pilih struk dari galeri';

  @override
  String shopReceiptMatched(int count) {
    return '$count item cocok';
  }

  @override
  String get shopReceiptNoMatches =>
      'Tidak ada item daftar yang cocok di struk.';

  @override
  String get shopReceiptApply => 'Terapkan harga';

  @override
  String get shopDueHeader => 'Hampir habis';

  @override
  String shopDueEveryDays(int days) {
    return '${days}h';
  }

  @override
  String get shopStatusUnavailable => 'Stok habis';

  @override
  String get shopStatusUnavailableBadge => 'Tidak tersedia';

  @override
  String get shopBarcodeTitle => 'Pindai Barcode';

  @override
  String shopBarcodeUnknownPrompt(String ean) {
    return 'Barcode baru ($ean)';
  }

  @override
  String get shopBarcodeNameHint => 'Nama produk (mis. kopi bubuk 100 g)';

  @override
  String get shopKeepScreenOn => 'Biarkan layar menyala';

  @override
  String get shopAtStoreButton => 'Aku di toko';

  @override
  String shopAtStoreMessage(String name) {
    return '🛒 $name sedang di toko — tambahkan yang kurang!';
  }

  @override
  String get shopAtStoreSent => 'Kolaborator diberi tahu';

  @override
  String get shopScanReceiptTooltip => 'Pindai struk (OCR)';

  @override
  String get shopRecipesTooltip => 'Paket resep';

  @override
  String get shopAisleOrderTooltip => 'Sesuaikan urutan lorong';

  @override
  String shopTakenBy(String name) {
    return 'Diambil oleh $name';
  }

  @override
  String shopEstimatedPrefix(String amount) {
    return '~Rp $amount';
  }

  @override
  String shopActualPrice(String amount) {
    return 'Rp $amount';
  }

  @override
  String shopOpenStoreModeCount(int remaining) {
    return 'Mode Toko ($remaining)';
  }

  @override
  String get shopOpenStoreMode => 'Mode Toko';

  @override
  String get shopDictationTooltip => 'Tambah dengan suara';

  @override
  String get spellManualLearn => 'Pelajari koreksi ini';

  @override
  String get spellManualLearnHint =>
      'Disarankan dan dikoreksi otomatis lain kali.';

  @override
  String get spellNoSuggestions => 'Tidak ada saran';

  @override
  String get spellHintBadge => 'Petunjuk';

  @override
  String get spellErrorBadge => 'Ejaan';

  @override
  String get wallpaperSakuraBreeze => 'Angin sakura';

  @override
  String get wallpaperOceanMist => 'Kabut samudra';

  @override
  String get wallpaperAutumnMaple => 'Daun musim gugur';

  @override
  String get wallpaperSageLinen => 'Linen sage';

  @override
  String get wallpaperPeachHorizon => 'Cakrawala persik';

  @override
  String get wallpaperNordicPaper => 'Kertas Nordik';

  @override
  String get wallpaperStarryPine => 'Pinus berbintang';

  @override
  String get wallpaperObsidianGold => 'Obsidian emas';

  @override
  String get uiProfileSectionTitle => 'Profil antarmuka siap';

  @override
  String get uiProfileSimple => 'Sederhana';

  @override
  String get uiProfileSimpleDesc =>
      'Tata letak bersih untuk catatan cepat dan belanja';

  @override
  String get uiProfileStandard => 'Standar';

  @override
  String get uiProfileStandardDesc => 'Semua alat seimbang';

  @override
  String get uiProfileTabletPen => 'Tablet & pena';

  @override
  String get uiProfileTabletPenDesc =>
      'Tampilan terpisah, alat pena dan PDF di depan';

  @override
  String uiProfileApplied(String name) {
    return 'Profil $name diterapkan';
  }

  @override
  String get lockNeedSecretOnce =>
      'Masukkan kata sandi atau pola kunci sekali untuk mengaktifkan buka dengan sidik jari di perangkat ini.';

  @override
  String get lockForgotConfirmTitle => 'Atur ulang kunci catatan?';

  @override
  String get lockForgotConfirmBody =>
      'Catatan terkunci yang dienkripsi dengan rahasiamu saat ini tidak bisa didekripsi lagi tanpa rahasia itu. Tetap atur ulang kunci?';

  @override
  String get lockForgotConfirmAction => 'Atur ulang';

  @override
  String get starterShoppingTitle => '🛒 Contoh daftar belanja';

  @override
  String get starterWelcomeTitle => '⚡ Mulai cepat';

  @override
  String get smartListMoving => 'Perencana pindahan';

  @override
  String get smartListCleaning => 'Bersih-bersih rumah';

  @override
  String get smartListHabits => 'Pelacak kebiasaan';

  @override
  String get smartListWorkout => 'Perencana latihan';

  @override
  String get smartListGifts => 'Perencana hadiah';

  @override
  String get smartListWatchlist => 'Daftar tontonan';

  @override
  String get smartListEvent => 'Acara & pesta';

  @override
  String get smartListExpense => 'Anggaran & pengeluaran';

  @override
  String get smartListKindSelect => 'Pilih jenis daftar';

  @override
  String get smartListCatalog => 'Paket & katalog';

  @override
  String get smartListSearchCatalog => 'Cari item atau grup…';

  @override
  String get smartListStarterPacks => 'Paket awal';

  @override
  String get smartListOpenWorkspace => 'Buka di ruang kerja';

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
  String get smartListWeatherMild => 'Sejuk';

  @override
  String get smartListWeatherCold => 'Dingin';

  @override
  String get smartListWeatherRainy => 'Hujan';

  @override
  String get smartListWizardStyle => 'Gaya perjalanan';

  @override
  String get smartListStyleBeach => 'Pantai';

  @override
  String get smartListStyleCity => 'Kota';

  @override
  String get smartListStyleBusiness => 'Bisnis';

  @override
  String get smartListStyleIntl => 'Internasional';

  @override
  String get smartListStyleCamp => 'Berkemah';

  @override
  String get smartListWizardGuests => 'Berapa tamu?';

  @override
  String get smartListEventStyle => 'Jenis acara';

  @override
  String get smartListEventBirthday => 'Ulang tahun';

  @override
  String get smartListEventDinner => 'Makan malam';

  @override
  String get smartListEventPicnic => 'Piknik';

  @override
  String smartListApplyPlan(int count) {
    return 'Tambahkan ke daftar ($count item)';
  }

  @override
  String smartListPackAdded(String name) {
    return 'Paket “$name” ditambahkan';
  }

  @override
  String get smartListEditItem => 'Edit item';

  @override
  String get smartListItemNameHint => 'Nama item';

  @override
  String get smartListItemQty => 'Jumlah';

  @override
  String get smartListItemUnit => 'Satuan';

  @override
  String get smartListAll => 'Semua';

  @override
  String get smartListResetDone => 'Daftar diatur ulang';

  @override
  String get smartListWorkspaceEmpty =>
      'Belum ada item; tambahkan di bawah atau pilih paket awal.';

  @override
  String get smartWorkspaceOpen => 'Buka ruang kerja';

  @override
  String smartPillHabit(int done, int total) {
    return 'Kebiasaan · $done/$total hari ini';
  }

  @override
  String smartPillMoving(int done, int total) {
    return 'Pindahan · $done/$total siap';
  }

  @override
  String smartPillPacking(int done, int total) {
    return 'Bawaan · $done/$total dikemas';
  }

  @override
  String smartPillWorkout(int done, int total) {
    return 'Latihan · $done/$total selesai';
  }

  @override
  String smartPillCleaning(int done, int total) {
    return 'Bersih-bersih · $done/$total selesai';
  }

  @override
  String smartPillGifts(int done, int total) {
    return 'Hadiah · $done/$total siap';
  }

  @override
  String smartPillWatchlist(int count) {
    return 'Daftar tontonan · $count antre';
  }

  @override
  String smartPillExpense(String total) {
    return 'Anggaran · Rp $total';
  }

  @override
  String smartPillDefault(int count) {
    return 'Ruang kerja cerdas ($count tersisa)';
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
  String get habitWeeklyGoal => 'Target mingguan';

  @override
  String habitWeeklyProgress(int done, int goal) {
    return '$done/$goal minggu ini';
  }

  @override
  String get habitTimeMorning => 'Pagi';

  @override
  String get habitTimeAfternoon => 'Siang';

  @override
  String get habitTimeEvening => 'Malam';

  @override
  String get habitFilterRemaining => 'Jatuh tempo hari ini';

  @override
  String get habitLast30Days => '30 hari terakhir';

  @override
  String get habitAddHint => 'Tambah kebiasaan baru…';

  @override
  String get habitPrevWeek => 'Minggu sebelumnya';

  @override
  String get habitNextWeek => 'Minggu berikutnya';

  @override
  String get movingViewTimeline => 'Linimasa';

  @override
  String get movingViewRooms => 'Ruang & kardus';

  @override
  String get movingPhaseMonth => '1 bulan sebelumnya';

  @override
  String get movingPhaseWeek => '1 minggu sebelumnya';

  @override
  String get movingPhaseDay => 'Hari pindahan';

  @override
  String get movingPhaseNewHome => 'Rumah baru';

  @override
  String get movingRoomKitchen => 'Dapur';

  @override
  String get movingRoomLiving => 'Ruang tamu';

  @override
  String get movingRoomBedroom => 'Kamar tidur';

  @override
  String get movingRoomBath => 'Kamar mandi';

  @override
  String get movingRoomStudy => 'Ruang kerja';

  @override
  String get movingRoomGeneral => 'Umum';

  @override
  String movingBoxesCount(int count) {
    return '$count kardus';
  }

  @override
  String movingFragileCount(int count) {
    return '$count mudah pecah';
  }

  @override
  String get movingFragile => 'Mudah pecah';

  @override
  String get movingOpenFirst => 'Buka duluan';

  @override
  String get movingBoxNumber => 'No. kardus (mis. #1)';

  @override
  String get movingAddHint => 'Tambah tugas pindahan atau kardus…';

  @override
  String get packingBagChecked => 'Bagasi';

  @override
  String get packingBagCabin => 'Kabin';

  @override
  String get packingBagWear => 'Dipakai';

  @override
  String get packingReset => 'Atur ulang bawaan';

  @override
  String get packingAddHint => 'Tambah item (mis. 3 kaus)…';

  @override
  String workoutSetsCount(int done, int total) {
    return '$done/$total set';
  }

  @override
  String get workoutRestTimer => 'Pengatur waktu istirahat';

  @override
  String workoutRestSeconds(int sec) {
    return '$sec dtk';
  }

  @override
  String get workoutAutoTimer => 'Mulai otomatis setelah set';

  @override
  String get workoutSetsLabel => 'Set';

  @override
  String get workoutRepsLabel => 'Repetisi / waktu';

  @override
  String get workoutWeightLabel => 'Beban (mis. 20 kg)';

  @override
  String get workoutZoneWarmup => 'Pemanasan';

  @override
  String get workoutZoneUpper => 'Atas';

  @override
  String get workoutZoneLower => 'Bawah';

  @override
  String get workoutZoneCore => 'Inti';

  @override
  String get workoutZoneCardio => 'Kardio';

  @override
  String get workoutZoneStretch => 'Peregangan';

  @override
  String get workoutReset => 'Atur ulang latihan';

  @override
  String get workoutAddHint => 'Tambah latihan…';

  @override
  String get cleaningFreqDaily => 'Harian';

  @override
  String get cleaningFreqWeekly => 'Mingguan';

  @override
  String get cleaningFreqMonthly => 'Bulanan';

  @override
  String get cleaningReset => 'Atur ulang siklus';

  @override
  String get cleaningAddHint => 'Tambah tugas bersih-bersih…';

  @override
  String get giftStageIdea => 'Ide';

  @override
  String get giftStageBought => 'Dibeli';

  @override
  String get giftStageWrapped => 'Dibungkus';

  @override
  String get giftStageGiven => 'Diberikan';

  @override
  String get giftRecipient => 'Penerima';

  @override
  String get giftPrice => 'Anggaran (Rp)';

  @override
  String giftSummaryPlanned(String total, String bought) {
    return 'Total: Rp $total · Dibeli: Rp $bought';
  }

  @override
  String get giftAddHint => 'Tambah hadiah atau penerima…';

  @override
  String get watchTypeMovie => 'Film';

  @override
  String get watchTypeSeries => 'Serial';

  @override
  String get watchTypeBook => 'Buku';

  @override
  String get watchTypeDoc => 'Dokumenter';

  @override
  String get watchTypePodcast => 'Podcast';

  @override
  String get watchStatusQueued => 'Antre';

  @override
  String get watchStatusWatching => 'Sedang berjalan';

  @override
  String get watchStatusDone => 'Selesai';

  @override
  String get watchPlatform => 'Platform atau penulis';

  @override
  String get watchRating => 'Penilaianmu';

  @override
  String get watchAddHint => 'Tambah film, serial, atau buku…';

  @override
  String get expenseCatMarket => 'Belanja dapur';

  @override
  String get expenseCatBills => 'Tagihan';

  @override
  String get expenseCatTransport => 'Transportasi';

  @override
  String get expenseCatFood => 'Makan di luar';

  @override
  String get expenseCatHome => 'Rumah';

  @override
  String get expenseCatHealth => 'Kesehatan';

  @override
  String get expenseCatFun => 'Hiburan';

  @override
  String get expenseCatOther => 'Lainnya';

  @override
  String expenseSummaryBar(String total, String paid, String left) {
    return 'Total: Rp $total · Dibayar: Rp $paid · Sisa: Rp $left';
  }

  @override
  String get expenseAmountHint => 'Jumlah (Rp)';

  @override
  String get expenseAddHint => 'Tambah item (mis. Listrik 850000)…';

  @override
  String get domainGearReset => 'Atur ulang daftar';

  @override
  String get domainAddHint => 'Tambah item baru…';

  @override
  String get quickDropKeepOpen => 'Tetap terbuka (input beruntun)';

  @override
  String get quickDropSmartListChip => 'Daftar cerdas';

  @override
  String quickDropPreviewSmartList(String kind, String items) {
    return '✨ $kind baru: $items';
  }

  @override
  String quickDropSavedSmartList(String title) {
    return 'Daftar cerdas “$title” dibuat';
  }

  @override
  String quickDropAddedSerial(String title) {
    return 'Ditambahkan ke “$title”';
  }

  @override
  String get quickDropUrgentBadge => 'Mendesak';

  @override
  String get tplBadgeShopping => 'Lorong · 2 kolom';

  @override
  String get tplBadgeHabits => '7 hari · beruntun';

  @override
  String get tplBadgeMoving => 'Tahap · kardus';

  @override
  String get tplBadgeTravel => 'Kabin · koper · asisten';

  @override
  String get tplBadgeWorkout => 'Set · pengatur jeda';

  @override
  String get tplBadgeCleaning => 'Ruang · jadwal';

  @override
  String get tplBadgeGifts => 'Ide · anggaran';

  @override
  String get tplBadgeWatchlist => '5 bintang · jenis';

  @override
  String get tplBadgeExpense => 'Anggaran · total';

  @override
  String get templatesMoreSmartLists => 'Daftar cerdas lainnya';

  @override
  String get smartListEntryHint => 'Ketik atau ucapkan: paspor, 2 susu…';

  @override
  String get quickListGenericHint => 'Ketik atau ucapkan item…';

  @override
  String get quickDropKeepOpenShort => 'Tetap buka';

  @override
  String get quickDropTagHint => '#tag';

  @override
  String get quickDropUrgentHint => '!mendesak';

  @override
  String get brightnessModeAuto => 'Otomatis';

  @override
  String get brightnessModeLight => 'Terang';

  @override
  String get brightnessModeDark => 'Gelap';

  @override
  String brightnessModeToggleTooltip(String mode) {
    return 'Mode tampilan: $mode';
  }

  @override
  String get appearanceTabTheme => 'Tema';

  @override
  String get appearanceTabBackground => 'Latar';

  @override
  String get appearanceTabLayout => 'Tata letak';

  @override
  String get appearanceOpenStudio => 'Latar & tampilan';

  @override
  String get applyHomeBackgroundToNotes => 'Terapkan ke catatan juga';

  @override
  String get applyHomeBackgroundToNotesInfo =>
      'Catatan tanpa latar khusus akan memakai latar ini.';

  @override
  String get noteUseHomeBackground => 'Latar beranda';

  @override
  String get bgSubTabWallpapers => 'Gambar';

  @override
  String get bgSubTabIllustrated => 'Ilustrasi';

  @override
  String get bgSubTabColors => 'Warna';

  @override
  String get bgSubTabPatterns => 'Pola';

  @override
  String get bgSubTabFrame => 'Bingkai';

  @override
  String get bgSubTabPaper => 'Kertas';

  @override
  String get personalizeGroupEditor => 'Bilah editor catatan';

  @override
  String get personalizeGroupAddAttach => 'Tambah & lampiran';

  @override
  String get personalizeEditBars => 'Sesuaikan bilah editor';

  @override
  String get attachmentRename => 'Ubah nama';

  @override
  String get attachmentRenameHint => 'Nama lampiran';

  @override
  String attachmentsAllTitle(int count) {
    return 'Semua lampiran ($count)';
  }

  @override
  String get attachmentsAllButton => 'Semua';

  @override
  String get attachmentRetryUpload => 'Coba lagi';

  @override
  String get pinnedCollapse => 'Perkecil';

  @override
  String get pinnedExpand => 'Perluas';

  @override
  String get pinnedHideKeyboard => 'Sembunyikan papan ketik';

  @override
  String get floatingSizeSmall => 'Kecil';

  @override
  String get floatingSizeMedium => 'Sedang';

  @override
  String get floatingSizeLarge => 'Penuh';

  @override
  String get floatingAlignCycle => 'Perataan horizontal';

  @override
  String get quickInboxFolderName => 'Catatan Cepat';

  @override
  String get quickInboxSubtitle => 'Tambahan yang belum pasti masuk ke sini';

  @override
  String get quickDropAddedQuickInbox => 'Ditambahkan ke Catatan Cepat';

  @override
  String get quickDropOpen => 'Buka';

  @override
  String quickDropTargetLabel(String target) {
    return 'Tujuan: $target';
  }

  @override
  String get quickDropMergeSingle => 'Gabung ke satu catatan';

  @override
  String get quickDropPriorityUrgent => 'Mendesak';

  @override
  String get quickDropPriorityHigh => 'Tinggi';

  @override
  String get quickDropPriorityMedium => 'Sedang';

  @override
  String get quickDropPriorityLow => 'Rendah';

  @override
  String quickDropContextNow(String title) {
    return 'Disarankan sekarang: $title';
  }

  @override
  String get listModeLabel => 'Mode daftar';

  @override
  String get listModeGeneral => 'Umum';

  @override
  String get listModeShopping => 'Belanja';

  @override
  String get listModeRoutine => 'Rutinitas';

  @override
  String get listModeTemplate => 'Templat';

  @override
  String get listModeProject => 'Proyek';

  @override
  String get listModeResetSchedule => 'Atur ulang';

  @override
  String get listModeResetNone => 'Nonaktif';

  @override
  String get listModeResetDaily => 'Setiap malam';

  @override
  String get listModeResetWeekly => 'Setiap minggu';

  @override
  String get listModeResetCustom => 'Hari khusus';

  @override
  String get listModeTimeSlot => 'Waktu';

  @override
  String get listModeSlotAny => 'Kapan saja';

  @override
  String get listModeSlotMorning => 'Pagi';

  @override
  String get listModeSlotEvening => 'Malam';

  @override
  String get listModeSlotWeekend => 'Akhir pekan';

  @override
  String get shoppingGroupToggle => 'Lorong';

  @override
  String shoppingBoughtCount(int done, int total) {
    return '$done/$total dibeli';
  }

  @override
  String shoppingTotalAmount(String amount) {
    return 'Total: $amount';
  }

  @override
  String shoppingSummaryRemaining(int count) {
    return 'Tersisa $count';
  }

  @override
  String routineTodayProgress(int done, int total) {
    return 'Hari ini $done/$total';
  }

  @override
  String routineStreakDays(int count) {
    return '$count hr';
  }

  @override
  String routineBestStreak(int count) {
    return 'Rekor terbaik: $count hari';
  }

  @override
  String get routineLast30Days => '30 hari terakhir';

  @override
  String get templateResetReuse => 'Atur ulang semua dan gunakan lagi';

  @override
  String get templateResetDone => 'Semua item diatur ulang';

  @override
  String get templateCopyNew => 'Salin sebagai daftar baru';

  @override
  String get projectFocusToggle => 'Fokus (3)';

  @override
  String get projectFocusExit => 'Tutup fokus';

  @override
  String get projectFocusPick => 'Pilih fokus';

  @override
  String projectFocusActive(int shown, int total) {
    return 'Mode fokus: $shown/$total';
  }

  @override
  String projectProgressLabel(int percent, int done, int total) {
    return '$percent% · $done/$total';
  }

  @override
  String get itemQuickPostponeTomorrow => 'Tunda ke besok';

  @override
  String get itemQuickPriority => 'Prioritas';

  @override
  String get itemQuickDueDate => 'Tanggal';

  @override
  String get itemQuickPrice => 'Harga';

  @override
  String get itemQuickFocus => 'Tandai fokus';

  @override
  String get itemQuickUnfocus => 'Hapus dari fokus';

  @override
  String get itemQuickMeta => 'Detail';

  @override
  String get itemDueToday => 'Hari ini';

  @override
  String get itemDueTomorrow => 'Besok';

  @override
  String get itemDueNextWeek => 'Minggu depan';

  @override
  String get itemDueClear => 'Hapus tanggal';

  @override
  String get itemPriorityNone => 'Tidak ada';

  @override
  String get listModeNudgeShopping => 'Pindah ke mode Belanja?';

  @override
  String get listModeNudgeRoutine => 'Pindah ke mode Rutinitas?';

  @override
  String get listModeQuickAddHint => 'Mis. 2 kg tomat, kopi 25000 rp…';

  @override
  String get ghostSuggestionsTitle => 'Item disarankan';

  @override
  String get ghostReasonDue => 'Rutin dibeli';

  @override
  String get ghostReasonPair => 'Cocok bersama';

  @override
  String get ghostReasonFrequent => 'Sering ditambahkan';

  @override
  String get ghostReasonTemplate => 'Mungkin terlewat';

  @override
  String get ghostReasonRoutine => 'Saran harian';

  @override
  String get itemBreakdownAction => 'Bagi jadi sublangkah';

  @override
  String get itemBreakdownTitle => 'Sublangkah';

  @override
  String get itemBreakdownApply => 'Tambah sublangkah';

  @override
  String get itemBreakdownEmpty => 'Tidak dapat menyarankan sublangkah';

  @override
  String get textExtractAction => 'Ekstrak dari teks';

  @override
  String get textExtractTitle => 'Ekstrak item dari teks';

  @override
  String get textExtractHint => 'Tempel pesan, resep, atau daftar di sini…';

  @override
  String get textExtractRefineAi => 'Rapikan dengan AI';

  @override
  String textExtractAddSelected(int count) {
    return 'Tambah terpilih ($count)';
  }

  @override
  String textExtractPasteBanner(int count) {
    return 'Ekstrak $count item dari teks';
  }

  @override
  String get listAiQuotaReached =>
      'Kuota AI harian tercapai; memakai saran lokal.';

  @override
  String carryOverBanner(int count) {
    return '$count tugas kemarin belum selesai';
  }

  @override
  String get carryOverAction => 'Pindah ke hari ini';

  @override
  String carryOverDone(int count) {
    return '$count tugas dipindah ke hari ini';
  }

  @override
  String get contextNowBadge => 'Sekarang';
}
