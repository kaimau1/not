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
  String get loginTagline => 'Catatan Anda, di semua perangkat';

  @override
  String get signInWithGoogle => 'Masuk dengan Google';

  @override
  String loginError(String error) {
    return 'Gagal masuk: $error';
  }

  @override
  String get searchHint => 'Cari catatan...';

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
  String get filterStarred => 'Berbintang';

  @override
  String get star => 'Beri bintang';

  @override
  String get unstar => 'Hapus bintang';

  @override
  String editedAt(String date) {
    return 'Diubah: $date';
  }

  @override
  String get sectionPinned => 'Disematkan';

  @override
  String get sectionOthers => 'Lainnya';

  @override
  String get emptyNotes => 'Belum ada catatan';

  @override
  String get emptyNotesHint => 'Ketuk + untuk membuat catatan pertama Anda';

  @override
  String get emptySearch => 'Tidak ada hasil';

  @override
  String get newTextNote => 'Catatan teks';

  @override
  String get newChecklist => 'Daftar';

  @override
  String get newOrderedList => 'Daftar bernomor';

  @override
  String get noteDeleted => 'Catatan dihapus';

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
    return '+$count item lainnya';
  }

  @override
  String get addAttachment => 'Tambah';

  @override
  String get addAttachmentMore => 'Jenis lampiran lainnya…';

  @override
  String get addImage => 'Tambah gambar';

  @override
  String get addPdf => 'Tambah PDF';

  @override
  String get addSlide => 'Tambah slide';

  @override
  String get pasteImage => 'Tempel gambar dari papan klip';

  @override
  String get clipboardEmpty => 'Tidak ada gambar di papan klip';

  @override
  String get noNoteSelected => 'Pilih catatan di sebelah kiri';

  @override
  String attachmentFailed(String error) {
    return 'Lampiran tidak dapat ditambahkan: $error';
  }

  @override
  String get attachmentCopying => 'Menyalin...';

  @override
  String get attachmentUploading => 'Mengunggah...';

  @override
  String get attachmentUploadFailed =>
      'Yüklenemedi — yeniden denemek için dokun';

  @override
  String get attachmentNotSynced =>
      'Berkas ini belum tersinkron ke perangkat ini';

  @override
  String attachmentTooLarge(int limit) {
    return 'Berkas terlalu besar (maksimal $limit MB)';
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
  String get aiTitle => 'AI';

  @override
  String get aiSummarize => 'Ringkas catatan';

  @override
  String get aiAnalyze => 'Analisis';

  @override
  String get aiSectionNote => 'Catatan ini';

  @override
  String get aiSectionAttachments => 'Lampiran';

  @override
  String get summarize => 'Ringkas';

  @override
  String get summaryDetailTitle => 'Jenis ringkasan';

  @override
  String get summaryShort => 'Ringkasan singkat';

  @override
  String get summaryShortInfo =>
      'Beberapa kalimat gambaran umum ditambah poin-poin utama';

  @override
  String get summaryDetailed => 'Ringkasan terperinci';

  @override
  String get summaryDetailedInfo =>
      'Cukup lengkap sehingga Anda tidak perlu membuka aslinya';

  @override
  String get listen => 'Dengarkan';

  @override
  String get ask => 'Ajukan pertanyaan';

  @override
  String get extractText => 'Ambil teksnya';

  @override
  String get transcribe => 'Transkripsikan';

  @override
  String get listenToNote => 'Bacakan';

  @override
  String get aiNoApiKey => 'Masukkan dulu kunci API Gemini Anda di setelan';

  @override
  String aiError(String error) {
    return 'Permintaan AI gagal: $error';
  }

  @override
  String get aiSummaryTitle => 'Ringkasan AI';

  @override
  String get aiThinking => 'Sedang berpikir...';

  @override
  String get copy => 'Salin';

  @override
  String get copied => 'Tersalin';

  @override
  String get settingsSearchHint => 'Ayarları ara — “özet”, “mikrofon”';

  @override
  String settingsSearchEmpty(String query) {
    return '«$query» ile eşleşen ayar bulunamadı';
  }

  @override
  String get settings => 'Setelan';

  @override
  String get settingsAppearance => 'Tampilan';

  @override
  String get themeSystem => 'Sistem';

  @override
  String get themeLight => 'Terang';

  @override
  String get themeDark => 'Gelap';

  @override
  String get settingsAi => 'AI';

  @override
  String get geminiApiKey => 'Kunci API Gemini';

  @override
  String get geminiApiKeyHint => 'Tempel kunci yang diawali AIza...';

  @override
  String get geminiApiKeyInfo =>
      'Kunci bersifat opsional: tanpa kunci, permintaan AI melewati layanan bawaan aplikasi (ada jatah harian gratis, lebih besar dengan Premium). Untuk pemakaian tanpa batas dengan kunci sendiri, ambil kunci gratis di aistudio.google.com; kunci hanya disimpan di perangkat ini, dalam penyimpanan aman.';

  @override
  String aiBuiltInPremium(int count) {
    return 'AI bawaan: Premium — sisa $count poin hari ini';
  }

  @override
  String aiBuiltInRemaining(int count) {
    return 'AI bawaan: sisa $count poin gratis hari ini';
  }

  @override
  String get aiBuiltInByok => 'Memakai kunci Anda sendiri — tanpa batas';

  @override
  String get aiReport => 'Laporkan jawaban ini';

  @override
  String get aiReportThanks => 'Laporan diterima, terima kasih';

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
      'Verifikasi identitas Anda untuk membuka catatan terkunci';

  @override
  String get exportBackup => 'Ekspor cadangan (JSON)';

  @override
  String get expandListItems => 'Tampilkan baris daftar sepenuhnya';

  @override
  String get expandListItemsInfo =>
      'Item panjang dipenggal ke beberapa baris dan tetap terlihat seluruhnya. Bila dimatikan, satu baris tetap satu baris dan melebar saat diketuk.';

  @override
  String get quickCaptureRowSetting => 'Bilah catatan cepat';

  @override
  String get quickCaptureRowInfo =>
      'Menampilkan bidang \"Catatan baru...\" satu baris di atas. Jika mati, gunakan tombol +.';

  @override
  String get emptyTrash => 'Kosongkan sampah';

  @override
  String emptyTrashConfirm(int count) {
    return '$count catatan akan dihapus permanen. Tindakan ini tidak dapat dibatalkan. Anda yakin?';
  }

  @override
  String get trashEmptied => 'Sampah dikosongkan';

  @override
  String get validateAndSave => 'Periksa dan simpan';

  @override
  String get clear => 'Bersihkan';

  @override
  String get aiDiagnostics => 'Diagnostik AI';

  @override
  String get aiDiagnosticsEmpty => 'Tidak ada galat yang tercatat';

  @override
  String aiDiagnosticsCount(int count) {
    return '$count catatan galat terakhir';
  }

  @override
  String get apiKeyValid => 'Kunci API terverifikasi dan tersimpan';

  @override
  String get apiKeyInvalid => 'Kunci API tidak valid';

  @override
  String get apiKeySavedBadge => 'Tersimpan';

  @override
  String get removeApiKey => 'Hapus kunci';

  @override
  String get refresh => 'Segarkan';

  @override
  String get account => 'Akun';

  @override
  String get signOut => 'Keluar';

  @override
  String get signOutConfirm => 'Anda yakin ingin keluar?';

  @override
  String get signOutAnonymousWarning =>
      'Kamu memakai akun lokal: keluar akan membuat akun ini dan SEMUA catatan tidak dapat diakses selamanya — tanpa cadangan tidak bisa dipulihkan. Tautkan akun Google dulu. Tetap keluar?';

  @override
  String get deleteAccount => 'Hapus akun dan data saya';

  @override
  String get deleteAccountWarning =>
      'Tindakan ini tidak dapat dibatalkan: semua catatan, lampiran, dan akun Anda akan dihapus permanen. Ingin melanjutkan?';

  @override
  String get deleteAccountConfirm => 'Hapus permanen';

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
  String get ok => 'OKE';

  @override
  String get syncPending => 'Menunggu sinkronisasi';

  @override
  String get synced => 'Tersinkron';

  @override
  String genericError(String error) {
    return 'Ada yang tidak beres: $error';
  }

  @override
  String get addTag => 'Tag';

  @override
  String get tagHint => 'mis. kerja, rumah, sekolah';

  @override
  String get addReminder => 'Ingatkan saya';

  @override
  String get share => 'Bagikan';

  @override
  String get archive => 'Arsipkan';

  @override
  String get unarchive => 'Keluarkan dari arsip';

  @override
  String get archiveTitle => 'Arsip';

  @override
  String get archiveEmpty => 'Tidak ada catatan di arsip';

  @override
  String get trashTitle => 'Sampah';

  @override
  String get trashEmpty => 'Sampah kosong';

  @override
  String get trashInfo =>
      'Catatan yang dihapus tetap di sini; Anda dapat memulihkannya atau menghapusnya selamanya.';

  @override
  String get restore => 'Pulihkan';

  @override
  String get deleteForever => 'Hapus permanen';

  @override
  String get deleteForeverConfirm =>
      'Catatan ini akan dihapus permanen. Anda yakin?';

  @override
  String assistantDeleteConfirm(String title) {
    return 'Asistan \"$title\" notunu çöp kutusuna taşımak istiyor. Onaylıyor musun?';
  }

  @override
  String get recordAudio => 'Rekaman suara';

  @override
  String get recording => 'Merekam...';

  @override
  String get stopAndSave => 'Selesai dan tambahkan';

  @override
  String get micPermissionDenied => 'Izin mikrofon ditolak';

  @override
  String get speechRecognitionFailed =>
      'Pengenalan suara tidak berhasil. Pastikan izin mikrofon sudah diberikan dan aplikasi Google sudah diperbarui.';

  @override
  String get addDrawing => 'Tambah gambar tangan';

  @override
  String get drawingTitle => 'Gambar tangan';

  @override
  String get addToNote => 'Tambahkan ke catatan';

  @override
  String get chatTitle => 'Asisten Catatan';

  @override
  String get chatHint =>
      'Tanyakan tentang catatan Anda: «apa resep yang saya tulis minggu lalu?», «apa yang kurang di daftar belanja saya?»';

  @override
  String get chatInputHint => 'Ketik pertanyaan...';

  @override
  String get fontSize => 'Ukuran teks';

  @override
  String get fontSizePreview => 'Catatan Anda akan tampak seperti ini';

  @override
  String get darkSchedule => 'Jadwal tema gelap';

  @override
  String get darkScheduleInfo =>
      'Beralih ke tema gelap di antara jam yang Anda tentukan';

  @override
  String get aiTranslate => 'Terjemahkan';

  @override
  String get voiceCommand => 'Perintah suara';

  @override
  String get semanticSearchToggle => 'Pencarian makna dengan AI';

  @override
  String get semanticSearchHint => 'Cari berdasarkan makna: «biaya mobil»...';

  @override
  String get briefingTitle => 'Ringkasan harian';

  @override
  String get briefingLoading => 'Menyiapkan ringkasan Anda...';

  @override
  String get briefingEmpty => 'Tidak ada apa-apa untuk hari ini';

  @override
  String get briefingSetting => 'Notifikasi ringkasan harian';

  @override
  String get briefingSettingInfo =>
      'Terima notifikasi berisi ringkasan hari itu setiap pagi pada jam yang Anda pilih';

  @override
  String get autoTagSetting => 'Beri tag otomatis';

  @override
  String get autoTagSettingInfo =>
      'Saat catatan ditutup tanpa tag, AI menambahkan tag yang sesuai';

  @override
  String get suggestTags => 'Sarankan tag';

  @override
  String get aiFixNote => 'Rapikan catatan';

  @override
  String get fixLevelTitle => 'Seberapa jauh dirapikan?';

  @override
  String get fixSimple => 'Ringan';

  @override
  String get fixSimpleInfo => 'Hanya ejaan dan salah ketik';

  @override
  String get fixBalanced => 'Seimbang';

  @override
  String get fixBalancedInfo =>
      'Termasuk struktur kalimat, agar tulisan lebih rapi';

  @override
  String get fixDetailed => 'Menyeluruh';

  @override
  String get fixDetailedInfo =>
      'Menulis ulang seluruh teks dari awal sampai akhir';

  @override
  String get existingTagsLabel => 'Tag sebelumnya';

  @override
  String get aiSkipCheckedSetting =>
      'Kecualikan item tercentang dari suntingan AI';

  @override
  String get aiSkipCheckedInfo =>
      'Saat AI merapikan atau menerjemahkan daftar, item yang sudah selesai (tercentang) dibiarkan apa adanya; hanya item yang belum tercentang yang disunting.';

  @override
  String get noteUpdatedUndo => 'Catatan diperbarui';

  @override
  String get aiImprove => 'Perbaiki catatan';

  @override
  String get improveFormal => 'Buat lebih formal';

  @override
  String get improveShorten => 'Persingkat';

  @override
  String get improveBullets => 'Ubah jadi daftar berpoin';

  @override
  String get improveNumbered => 'Ubah jadi daftar bernomor';

  @override
  String get replaceNote => 'Ganti catatan';

  @override
  String get openAsNewNote => 'Sebagai catatan baru';

  @override
  String get pdfChatHint =>
      'Tanyakan tentang PDF ini: «ringkas dong», «ada klausul denda?», «kapan tenggatnya?»';

  @override
  String get pdfChatInputHint => 'Ketik pertanyaan tentang PDF...';

  @override
  String get voiceCaptureHint =>
      'Bicara saja: «beli susu dan roti» atau «rapat besok jam 9, ingatkan aku» — AI menyusun catatan Anda setelah selesai.';

  @override
  String get voiceFinish => 'Selesai';

  @override
  String get voiceProcessing => 'Memproses yang Anda ucapkan...';

  @override
  String get voiceNothingHeard =>
      'Tidak ada suara bicara yang terdeteksi dalam rekaman';

  @override
  String get voiceNoteSaved => 'Catatan suara Anda telah disimpan';

  @override
  String get openNote => 'Buka catatan';

  @override
  String get remindersTitle => 'Pengingat';

  @override
  String get remindersEmpty => 'Tidak ada pengingat';

  @override
  String get remindersEmptyHint =>
      'Tambahkan pengingat ke sebuah catatan, atau buat catatan baru berpengingat lewat tombol +';

  @override
  String get remindersUpcoming => 'Akan datang';

  @override
  String get remindersPast => 'Sudah lewat';

  @override
  String get reminderInPast =>
      'Waktu yang dipilih sudah lewat — pilih waktu di masa depan.';

  @override
  String get newReminder => 'Pengingat baru';

  @override
  String get remindersUntitled => 'Catatan tanpa judul';

  @override
  String get remindersEdit => 'Ubah waktunya';

  @override
  String get remindersRemove => 'Hapus pengingat';

  @override
  String get aiModelChat => 'Ringkasan, judul, tag, dan obrolan';

  @override
  String get aiModelDocument => 'Obrolan dokumen dan ringkasan PDF';

  @override
  String get aiModelTranslate => 'Terjemahan';

  @override
  String get aiModelVoice => 'Asisten catatan suara';

  @override
  String get aiModelAuto => 'Otomatis (disarankan)';

  @override
  String get aiModelsInfo =>
      'Anda dapat memilih model berbeda untuk tiap tugas: teks pendek cukup dengan model cepat, dokumen panjang butuh model yang lebih mumpuni. Jika model pilihan Anda kehabisan kuota atau ditarik, model berikutnya dicoba otomatis.';

  @override
  String get clearNote => 'Kosongkan';

  @override
  String get clearNoteConfirm =>
      'Isi catatan (teks dan item daftar) akan dihapus. Anda yakin?';

  @override
  String get themePaper => 'Kertas';

  @override
  String get calculatorTitle => 'Kalkulator';

  @override
  String get calcExpressionHint => 'mis. 12,5×3+40';

  @override
  String get calcInvalid => 'Ekspresi tidak valid';

  @override
  String get liveDictation => 'Dikte';

  @override
  String get dictationListening =>
      'Mendengarkan... teks muncul sambil Anda berbicara';

  @override
  String get dictationNoKeyInfo =>
      'Dikte langsung tidak tersedia di perangkat ini; rekaman akan ditranskripsikan sekaligus saat Anda berhenti.';

  @override
  String get dictationHoldHint =>
      'Tahan mikrofon lalu bicara; teks ditulis saat Anda melepasnya';

  @override
  String itemsSelected(int count) {
    return '$count item dipilih';
  }

  @override
  String get noteChatTitle => 'Mengobrol dengan catatan ini';

  @override
  String get noteChatHint => 'Tanyakan sesuatu tentang catatan ini';

  @override
  String get noteChatIntro =>
      'Isi catatan dan lampirannya (PDF/gambar) dibaca, lalu pertanyaan Anda dijawab berdasarkan itu.';

  @override
  String get dictationProcessing => 'Mentranskripsikan...';

  @override
  String get aiDailyManualInfo =>
      'Pada paket gratis ini tidak dibuat otomatis, jadi tidak memakan jatah harian Anda. Anda bisa membuatnya sekali sehari dengan tombol di bawah.';

  @override
  String get aiGenerate => 'Buat';

  @override
  String get aiGeneratedTodayInfo =>
      'Ini dibuat hari ini. Pada paket gratis, isinya diperbarui sekali sehari; Anda bisa membuatnya lagi besok.';

  @override
  String get voiceAssistantTitle => 'Asisten catatan suara';

  @override
  String get voiceListening => 'Mendengarkan...';

  @override
  String get voiceHoldHint =>
      'Tahan lalu bicara; catatan dibuat saat Anda melepasnya';

  @override
  String get voiceTapHint => 'Ketuk lalu bicara; ketuk lagi untuk selesai';

  @override
  String get voiceTooShort => 'Rekaman itu terlalu pendek, coba lagi';

  @override
  String get voiceModeSetting => 'Cara kerjanya';

  @override
  String get voiceModeHold => 'Tahan untuk bicara';

  @override
  String get voiceModeTap => 'Ketuk untuk mulai / ketuk untuk berhenti';

  @override
  String get voiceModeInfo =>
      'Tahan untuk bicara: mendengarkan selama Anda menahan tombol dan membuat catatan saat dilepas. Ketuk untuk mulai: satu ketukan memulai perekaman, ketukan kedua mengakhirinya.';

  @override
  String get voiceHeardLive => 'Suara bicara terdeteksi';

  @override
  String get voiceCaptureReady => 'Konuşmaya hazır';

  @override
  String get voiceCaptureEditHint => 'Düzenlemek için metne dokun';

  @override
  String voiceCapturePunctuation(String language) {
    return '$language · otomatik noktalama';
  }

  @override
  String get voiceCaptureAddToNote => 'Nota ekle';

  @override
  String get voiceCaptureCreateNote => 'Yeni not oluştur';

  @override
  String get voiceCaptureAiNote => 'Catatan AI';

  @override
  String get voiceCapturePlainNote => 'Catatan biasa';

  @override
  String get voiceCloseTitle => 'Hasil dikte masih ada';

  @override
  String get voiceCloseKeepTalking => 'Lanjut bicara';

  @override
  String get voiceCaptureRestart => 'Yeniden kaydet';

  @override
  String get voiceChipSummarizeAdd => 'Özet olarak ekle';

  @override
  String get voiceChipSummarizeSave => 'Özet olarak kaydet';

  @override
  String get voiceChipToItems => 'Maddelere ayır';

  @override
  String get voiceChipAsList => 'Kontrol listesi yap';

  @override
  String get voiceChipFix => 'Düzenle';

  @override
  String get voiceChipCompose => 'Asistan yazsın';

  @override
  String get editorToolList => 'Liste';

  @override
  String get permissionsTitle => 'Izin';

  @override
  String get permMic => 'Mikrofon';

  @override
  String get permMicInfo => 'Diperlukan untuk catatan suara dan dikte';

  @override
  String get permNotifications => 'Notifikasi';

  @override
  String get permNotificationsInfo =>
      'Diperlukan untuk pengingat dan ringkasan harian';

  @override
  String get permBattery => 'Optimalisasi baterai';

  @override
  String get permBatteryInfo =>
      'Bebaskan aplikasi dari pembatasan baterai agar pengingat datang tepat waktu';

  @override
  String get showTagChips => 'Tampilkan chip tag';

  @override
  String get showFolderChips => 'Tampilkan chip folder';

  @override
  String videoTooBigForAi(int mb) {
    return 'Video terlalu besar untuk dikirim ke AI ($mb MB). Rekam yang lebih pendek.';
  }

  @override
  String get permCamera => 'Kamera';

  @override
  String get permCameraInfo => 'Diperlukan untuk catatan video dan memotret';

  @override
  String get permOnboardTitle => 'Sebelum mulai';

  @override
  String get permOnboardInfo =>
      'Catatan hanya meminta izin ini saat Anda memakai fitur terkait. Anda bisa memberikannya sekarang di bawah, atau mengubahnya nanti di Setelan > Izin.';

  @override
  String get permOnboardGrantAll => 'Berikan izin';

  @override
  String get permOnboardSkip => 'Nanti saja';

  @override
  String get newVideoNote => 'Catatan video';

  @override
  String get videoLocalOnly =>
      'Video ini hanya tersimpan di perangkat ini (tidak diunggah ke awan)';

  @override
  String get videoToNote => 'Buat catatan dari video';

  @override
  String get videoToNoteRunning => 'Menelaah video…';

  @override
  String get permGranted => 'Diberikan';

  @override
  String get permGrant => 'Berikan';

  @override
  String get permOpenSettings => 'Buka setelan';

  @override
  String get newHandwriting => 'Tulisan tangan';

  @override
  String get newVoiceCapture => 'Catatan suara';

  @override
  String get suggestTitle => 'Sarankan judul';

  @override
  String get noteMetaMenu => 'Tag · Judul · Pengingat';

  @override
  String get folder => 'Folder';

  @override
  String get noFolder => 'Tanpa folder';

  @override
  String get newFolder => 'Folder baru';

  @override
  String get editFolder => 'Ubah folder';

  @override
  String get deleteFolder => 'Hapus folder';

  @override
  String deleteFolderConfirm(String name) {
    return 'Folder «$name» akan dihapus. Catatan di dalamnya tidak dihapus — hanya tidak lagi punya folder.';
  }

  @override
  String get folderNameHint => 'Nama folder';

  @override
  String get folderIcon => 'Ikon';

  @override
  String get editFilters => 'Ubah filter';

  @override
  String get editFiltersInfo =>
      'Pilih filter mana yang muncul di layar utama. Menyembunyikan sebagian membuat halaman lebih rapi.';

  @override
  String get select => 'Pilih';

  @override
  String get noteArchived => 'Catatan diarsipkan';

  @override
  String deleteChecked(int count) {
    return 'Hapus yang tercentang ($count)';
  }

  @override
  String get removeItem => 'Hapus item';

  @override
  String get copyWholeNote => 'Salin seluruh catatan';

  @override
  String get allCopied => 'Seluruh catatan disalin ke papan klip';

  @override
  String get speechPlay => 'Bacakan';

  @override
  String get speechPause => 'Jeda';

  @override
  String get speechResume => 'Lanjutkan';

  @override
  String get speechStop => 'Hentikan';

  @override
  String get speechRate => 'Kecepatan membaca';

  @override
  String get speechSystemDefault => 'Bawaan sistem';

  @override
  String get speechNoVoices =>
      'Tidak ada suara yang terpasang di perangkat ini';

  @override
  String speechVoiceLanguage(String language) {
    return 'Suara $language';
  }

  @override
  String get speechVoiceAutoInfo =>
      'Bahasa lain dibacakan otomatis dengan suara pria';

  @override
  String get listening => 'Mendengarkan...';

  @override
  String get listenPlay => 'Dengarkan';

  @override
  String get listenReadingPdf => 'Membaca dokumen...';

  @override
  String get listenConvertWithAi => 'Ubah dengan AI';

  @override
  String get listenMakePodcast => 'Podcast lengkap';

  @override
  String get listenMakePodcastSummary => 'Podcast ringkasan';

  @override
  String get listenOriginalText => 'Teks asli';

  @override
  String get listenPodcastReady => 'Narasi podcast sudah siap';

  @override
  String get listenPodcastCached => 'Dibuat sebelumnya — tidak memakai token';

  @override
  String get listenRegenerate => 'Buat lagi';

  @override
  String get listenNoText =>
      'Tidak ada teks terbaca yang keluar dari dokumen ini. PDF hasil pindaian tidak punya lapisan teks, dan presentasi bisa jadi hanya berisi gambar.';

  @override
  String get readDocument => 'Baca dokumen (Word, PDF, slide)';

  @override
  String get readDocUnsupported => 'Jenis berkas ini tidak dapat dibaca.';

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
  String get largeAttachmentTitle => 'Berkas besar';

  @override
  String largeAttachmentBody(String size) {
    return 'Berkas ini berukuran $size MB. PDF tidak dapat dimampatkan; berkas akan diunggah apa adanya dan diperhitungkan dalam penyimpanan Anda. Lanjutkan?';
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
  String get backgroundColorInfo => 'Warna latar catatan';

  @override
  String get frameColor => 'Bingkai';

  @override
  String get frameColorInfo =>
      'Menggambar bingkai di sekeliling catatan dengan warna pilihan Anda';

  @override
  String get sortBy => 'Urutkan';

  @override
  String get reorderNotes => 'Atur ulang urutan catatan';

  @override
  String get reorderModeActive => 'Seret kartu untuk mengubah urutannya';

  @override
  String get reorderDone => 'Selesai';

  @override
  String get sortManual => 'Manual (urutan seretan)';

  @override
  String get sortUpdated => 'Baru diperbarui';

  @override
  String get sortCreated => 'Tanggal dibuat';

  @override
  String get sortTitle => 'Menurut judul (A–Z)';

  @override
  String get foldersSection => 'Folder';

  @override
  String get tagsSection => 'Tag';

  @override
  String get expandFilters => 'Bentangkan filter';

  @override
  String get collapseFilters => 'Ciutkan filter';

  @override
  String get settingsLanguage => 'Bahasa';

  @override
  String get languageSystem => 'Bahasa sistem';

  @override
  String get settingsSpeech => 'Bacakan';

  @override
  String get aiAdvanced => 'Lanjutan: model dan kunci API';

  @override
  String get aiAdvancedInfo =>
      'Pilihan model dan kunci Gemini Anda sendiri. Kebanyakan orang tidak membutuhkannya.';

  @override
  String get openBriefing => 'Buka ringkasan';

  @override
  String get syncTitle => 'Sinkronisasi';

  @override
  String get syncLimitTitle => 'Batas unggah otomatis';

  @override
  String get syncLimitInfo =>
      'Lampiran yang lebih besar dari ini tetap di perangkat dan tidak diunggah. Teks catatan selalu tersinkron.';

  @override
  String get syncLimitUnlimited => 'Tanpa batas';

  @override
  String get backupTitle => 'Cadangan';

  @override
  String get importBackup => 'Pulihkan dari cadangan (JSON)';

  @override
  String importBackupDone(int count) {
    return '$count catatan dipulihkan';
  }

  @override
  String get importBackupInvalid => 'Berkas cadangan tidak valid';

  @override
  String get aiHubTitle => 'AI';

  @override
  String get aiSummarizeInfo => 'Menghasilkan ringkasan singkat';

  @override
  String get aiAnalyzeInfo =>
      'Mendaftar poin utama dan hal yang harus dikerjakan';

  @override
  String get aiImproveInfo =>
      'Mengubah gaya: formal, lebih singkat atau daftar';

  @override
  String get aiTranslateInfo => 'Menerjemahkan catatan ke bahasa pilihanmu';

  @override
  String get aiFixNoteInfo => 'Memperbaiki ejaan dan tanda baca';

  @override
  String get moveToFolder => 'Pindahkan ke folder';

  @override
  String get voiceAssistantBadge => 'Asisten';

  @override
  String get assistantGenericError => 'Ada yang tidak beres — bisa coba lagi?';

  @override
  String get quickAddTooltip => 'Catatan baru — pilih jenisnya';

  @override
  String get autoTitleSetting => 'Sarankan judul saat ditutup';

  @override
  String get autoTitleSettingInfo =>
      'Saat Anda meninggalkan editor, catatan yang dibiarkan tanpa judul mendapat judul singkat yang disusun dari isinya.';

  @override
  String get hubChatInfo => 'Jawaban yang diambil dari catatan Anda';

  @override
  String get hubBriefingInfo =>
      'Hari Anda sekilas: pengingat dan catatan terbaru';

  @override
  String get hubReadInfo => 'Dengarkan dokumen PDF atau Word';

  @override
  String get annotate => 'Beri catatan';

  @override
  String get annotateDone => 'Selesai memberi catatan';

  @override
  String get newPdfNote => 'PDF ekle not al';

  @override
  String get imageNotePreparing => 'Menyusun gambar menjadi dokumen…';

  @override
  String get newImageNote => 'Tambah gambar, buat catatan';

  @override
  String get pdfPageNoteHint => 'Bu sayfanın notu…';

  @override
  String pdfPage(int page) {
    return 'Sayfa $page';
  }

  @override
  String pdfPageOf(int page, int total) {
    return 'Sayfa $page / $total';
  }

  @override
  String get pdfPreviousPage => 'Önceki sayfa';

  @override
  String get pdfNextPage => 'Sonraki sayfa';

  @override
  String get pdfFullScreen => 'Tam ekran aç';

  @override
  String get pdfNoDocument => 'Bu notta henüz PDF yok';

  @override
  String get pdfChooseDocument => 'PDF seç';

  @override
  String get newSlidesNote => 'Sunum ekle not al';

  @override
  String get slidesNoDocument => 'Bu notta henüz sunum yok';

  @override
  String get slidesChooseDocument => 'Sunum seç';

  @override
  String get pdfEditPages => 'Sayfaları düzenle';

  @override
  String get pdfDeletePages => 'Seçili sayfaları sil';

  @override
  String get pdfAddBlankPage => 'Tambah halaman kosong';

  @override
  String get pdfRotatePages => 'Döndür';

  @override
  String get pdfBurnInk => 'El yazısını belgeye göm';

  @override
  String get pdfApplyChanges => 'Değişiklikleri uygula';

  @override
  String get pdfCannotDeleteAllPages => 'Tüm sayfalar silinemez';

  @override
  String get pdfPagesHint =>
      'Sayfaya dokunup seçin. Sayfa notları sayfalarıyla birlikte taşınır; silinen sayfanın notu listede görünmez ama kaydınızda kalır.';

  @override
  String pdfEditFailed(String error) {
    return 'PDF düzenlenemedi: $error';
  }

  @override
  String get pdfInkBurned => 'El yazısı belgeye gömüldü';

  @override
  String get pdfAllPageNotes => 'Tüm sayfa notları';

  @override
  String get pdfNoPageNotes =>
      'Henüz sayfa notu yok. Sayfayı çevirip alttaki alana yazın.';

  @override
  String get crop => 'Pangkas';

  @override
  String get cropApply => 'Terapkan pangkasan';

  @override
  String get cropReset => 'Atur ulang pilihan';

  @override
  String get cropHint =>
      'Seret sudut-sudutnya untuk memilih area. Pemangkasan tidak dapat dibatalkan.';

  @override
  String get cropFailed => 'Gambar tidak dapat dipangkas.';

  @override
  String get penBallpoint => 'Pulpen';

  @override
  String get penMarker => 'Spidol';

  @override
  String get penHighlighter => 'Stabilo';

  @override
  String get eraser => 'Penghapus';

  @override
  String get inkArrow => 'Panah';

  @override
  String get clearInk => 'Hapus semua coretan';

  @override
  String get inkTwoFingerHint =>
      'Satu jari menggambar · dua jari menggeser dan memperbesar';

  @override
  String get slideOpenFailed => 'Presentasi tidak dapat dibuka';

  @override
  String get newPhotoNote => 'Catatan foto';

  @override
  String get newScanNote => 'Pindai dokumen';

  @override
  String get scanDocument => 'Pindai dokumen';

  @override
  String get scanDocumentSubtitle =>
      'Menemukan tepinya, meratakan halaman, lalu menambahkannya';

  @override
  String get scanUnsupported =>
      'Pemindaian dokumen tidak didukung di perangkat ini';

  @override
  String scanFailed(String error) {
    return 'Dokumen tidak dapat dipindai: $error';
  }

  @override
  String scanPagesAdded(int count) {
    return '$count halaman ditambahkan ke catatan';
  }

  @override
  String get scanTextTitle => 'Kenali teksnya juga?';

  @override
  String get scanTextBody =>
      'Teks pada halaman dikenali dan dituliskan ke dalam catatan. Gambarnya tetap apa adanya. Perlu beberapa detik per halaman.';

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
  String get qrScanSubtitle => 'Baca dengan kamera atau dari sebuah foto';

  @override
  String get qrScanHint => 'Sejajarkan kode di dalam bingkai';

  @override
  String get qrFromPhoto => 'Baca dari foto';

  @override
  String get qrNotFound => 'Tidak ada kode yang ditemukan pada gambar ini';

  @override
  String get qrLinkFound => 'Kode ini berupa tautan';

  @override
  String get qrOpenLink => 'Buka tautannya';

  @override
  String get qrSaveToNote => 'Simpan ke catatan';

  @override
  String get openLink => 'Buka tautan';

  @override
  String get linkOpenFailed => 'Tautan tidak dapat dibuka';

  @override
  String qrScanFailed(String error) {
    return 'Kode tidak dapat dibaca: $error';
  }

  @override
  String get qrTorch => 'Senter';

  @override
  String attachmentsCount(int count) {
    return 'Lampiran ($count)';
  }

  @override
  String get hideAttachments => 'Sembunyikan';

  @override
  String get showAttachments => 'Tampilkan';

  @override
  String get videoBack10 => 'Mundur 10 dtk';

  @override
  String get videoForward10 => 'Maju 10 dtk';

  @override
  String get selectAllItems => 'Pilih semua';

  @override
  String get showAllChips => 'Tampilkan semua';

  @override
  String get hideAllChips => 'Sembunyikan semua';

  @override
  String get chipPickInfo =>
      'Chip folder dan tag mana yang harus muncul di layar utama?';

  @override
  String get hiddenFolder => 'Folder tersembunyi';

  @override
  String get hiddenFolderInfo =>
      'Folder tersembunyi dan catatan di dalamnya tidak muncul di layar utama. Untuk menampilkannya, pilih «Folder tersembunyi» dari menu ⋮ lalu verifikasi identitas Anda.';

  @override
  String get hiddenFoldersMenu => 'Folder tersembunyi';

  @override
  String get hiddenFolderAuthReason =>
      'Verifikasi identitas Anda untuk menampilkan folder tersembunyi';

  @override
  String get hiddenFoldersShown => 'Folder tersembunyi sedang ditampilkan';

  @override
  String get hiddenFoldersHiddenAgain =>
      'Folder tersembunyi disembunyikan kembali';

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
      'Duduk di halaman, teks mengalir di sekitarnya';

  @override
  String get addImageAsFile => 'Tambahkan gambar sebagai berkas';

  @override
  String get addImageAsFileSubtitle =>
      'Tetap di luar halaman, di baris lampiran';

  @override
  String get moveImageToAttachments => 'Pindahkan ke lampiran';

  @override
  String get moveImageToPage => 'Tempatkan di halaman';

  @override
  String get attachmentCopied => 'Lampiran disalin';

  @override
  String get pasteAttachment => 'Tempel lampiran yang disalin';

  @override
  String get fullscreen => 'Layar penuh';

  @override
  String get more => 'Lainnya';

  @override
  String get undone => 'Diurungkan';

  @override
  String get filterOthers => 'Lainnya';

  @override
  String get chatSuggestion1 => 'Alışveriş listemde ne eksik?';

  @override
  String get chatSuggestion2 => 'Bu haftaki iş notlarımı özetle';

  @override
  String get chatSuggestion3 => 'Yarın için bir hatırlatıcım var mı?';

  @override
  String get aiPointsToday => 'Bugünkü puanlar';

  @override
  String aiPointsOf(int used, int total) {
    return '$used / $total';
  }

  @override
  String get aiPointsRenew => 'gece yarısı yenilenir';

  @override
  String get aiChatWithNotes => 'Asisten Catatan';

  @override
  String get aiChatInputHint => 'Notların hakkında bir şey sor…';

  @override
  String get aiChatLooking => 'notlarına göz atılıyor…';

  @override
  String get aiChatFullScreen => 'Tam ekran';

  @override
  String get aiOnYourNotes => 'NOTLARIN ÜZERİNDE';

  @override
  String get aiTaskDuplicates => 'Bersihkan duplikat';

  @override
  String aiTaskDuplicatesInfo(int count) {
    return '$count catatan duplikat';
  }

  @override
  String get duplicatesTitle => 'Catatan duplikat';

  @override
  String get duplicatesHint =>
      'Catatan terlama di setiap grup dipertahankan, sisanya masuk ke sampah.';

  @override
  String get duplicatesKeepBadge => 'dipertahankan';

  @override
  String get duplicatesDeleteAll => 'Pindahkan duplikat ke sampah';

  @override
  String duplicatesDone(int count) {
    return '$count duplikat dipindahkan ke sampah';
  }

  @override
  String get aiRecentActions => 'TINDAKAN TERAKHIR';

  @override
  String get aiHistoryClear => 'Hapus';

  @override
  String get aiHistoryQuestion => 'Pertanyaan';

  @override
  String get aiHistoryNoteAction => 'Tindakan catatan';

  @override
  String get aiHistoryVoiceNote => 'Catatan suara';

  @override
  String get aiRecentOps => 'SON İŞLEMLER';

  @override
  String get aiTaskWeekSummary => 'Haftayı özetle';

  @override
  String get aiTaskWeekSummaryInfo => 'Son 7 günden bir özet';

  @override
  String get aiTaskTagUntagged => 'Etiketlenmemişleri etiketle';

  @override
  String aiTaskTagUntaggedInfo(int count) {
    return '$count not etiket bekliyor';
  }

  @override
  String get aiTaskSuggestTitles => 'Başlık öner';

  @override
  String aiTaskSuggestTitlesInfo(int count) {
    return '$count notun başlığı yok';
  }

  @override
  String get sectionPinnedShort => 'SABİTLENMİŞ';

  @override
  String get sectionToday => 'BUGÜN';

  @override
  String get sectionThisWeek => 'BU HAFTA';

  @override
  String get sectionEarlier => 'DAHA ÖNCE';

  @override
  String sectionNoteCount(int count) {
    return '$count not';
  }

  @override
  String get emptySearchSemanticHint => 'Anlam sekmesini dene';

  @override
  String get quickCaptureHint => 'Yeni not…';

  @override
  String get quickCaptureSave => 'Kaydet';

  @override
  String get quickAddWrite => 'YAZ';

  @override
  String get quickAddCapture => 'YAKALA — İÇERİKTEN NOT OLUŞTURUR';

  @override
  String get viewToggle => 'Görünüm';

  @override
  String get searchModeText => 'Metin';

  @override
  String get searchModeMeaning => 'Anlam';

  @override
  String get filterReminded => 'Hatırlatıcılı';

  @override
  String get filterLocked => 'Kilitli';

  @override
  String get sortColor => 'Renk';

  @override
  String get sortActive => 'Paling sering dikerjakan';

  @override
  String get voicePreview => 'Coba suara';

  @override
  String get voicePreviewCached =>
      'Sampel dibuat sekali, lalu diputar dari penyimpanan';

  @override
  String get reorderHint =>
      'Tekan dan tahan kartu, lalu seret ke tempat yang diinginkan';

  @override
  String get filterSheetTitle => 'Filtrele';

  @override
  String get filterReset => 'Sıfırla';

  @override
  String get filterSectionStatus => 'DURUM';

  @override
  String get filterSectionFolder => 'KLASÖR';

  @override
  String get filterSectionTag => 'ETİKET';

  @override
  String get filterSectionSort => 'SIRALA';

  @override
  String get filterFavoriteHint =>
      'Ketuk bintang agar opsi itu tetap di layar utama';

  @override
  String get filterSheetSortHint =>
      'Tarih grupları (BUGÜN, BU HAFTA…) yalnızca son düzenlemeye göre sıralandığında görünür.';

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
  String get formatHighlight => 'Sorotan';

  @override
  String get formatInfo =>
      'Format ikut tersimpan di dalam teks berupa penanda (misalnya **tebal**); penanda tetap tersembunyi saat diekspor dan dibacakan.';

  @override
  String get formatMenu => 'Format…';

  @override
  String get noteFont => 'Fon';

  @override
  String get noteFontDefault => 'Bawaan';

  @override
  String get noteFontSerif => 'Buku (serif)';

  @override
  String get noteFontMono => 'Mesin tik';

  @override
  String get noteTextSize => 'Ukuran teks';

  @override
  String get formatClear => 'Bersihkan format';

  @override
  String get noteTextOpacity => 'Keburaman';

  @override
  String get assistantVoiceSetting => 'Asisten membacakan jawaban';

  @override
  String get assistantVoiceSettingInfo =>
      'Asisten suara membacakan jawabannya dengan suara keras (hanya di ponsel).';

  @override
  String get assistantMute => 'Bisukan';

  @override
  String get assistantUnmute => 'Nyalakan suara';

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
  String get attachNoteContent => 'Not içeriği';

  @override
  String get noteBackgroundImage => 'Gambar latar';

  @override
  String get chooseBackgroundImage => 'Pilih gambar';

  @override
  String get changeBackgroundImage => 'Ganti gambar';

  @override
  String get removeBackgroundImage => 'Hapus latar';

  @override
  String get dashboardBackground => 'Latar layar utama';

  @override
  String get dashboardBackgroundInfo =>
      'Gambar yang tampil di belakang kisi catatan (hanya perangkat ini).';

  @override
  String get aiProvider => 'Penyedia AI';

  @override
  String get aiProviderInfo =>
      'Pilih penyedia tempat kunci Anda berasal. Kunci tiap penyedia disimpan terpisah, jadi kembali ke penyedia sebelumnya tidak perlu mengetik ulang.';

  @override
  String get apiKeyFieldLabel => 'Kunci API';

  @override
  String get getApiKey => 'Di mana saya bisa dapat kunci?';

  @override
  String get recommendedModel => 'Disarankan';

  @override
  String get freeTierBadge => 'Punya paket gratis';

  @override
  String get continueWithoutAccount => 'Lanjut tanpa akun';

  @override
  String get localAccountInfo =>
      'Catatan Anda hanya ada di perangkat ini: tidak bisa dibuka di tempat lain, hilang jika aplikasi dicopot, dan AI bawaan dimatikan. Anda bisa menautkan akun Google kapan saja — catatan Anda ikut terbawa.';

  @override
  String get localAccountBadge => 'Akun lokal';

  @override
  String get linkGoogleAccount => 'Tautkan akun Google';

  @override
  String get accountLinked =>
      'Akun Google Anda tertaut. Catatan Anda kini dicadangkan.';

  @override
  String scanReviewPage(int current, int total) {
    return 'Sayfa $current / $total';
  }

  @override
  String get scanRotatePage => 'Sayfayı döndür';

  @override
  String get scanDeletePage => 'Sayfayı sil';

  @override
  String get scanLastPage => 'Son sayfa silinemez';

  @override
  String get scanDiscardTitle => 'Taranan sayfalar atılsın mı?';

  @override
  String get scanDiscardConfirm => 'At';

  @override
  String get scanAdjustCorners => 'Köşeleri ayarla';

  @override
  String get scanFilterOriginal => 'Özgün';

  @override
  String get scanFilterAuto => 'Netleştir';

  @override
  String get scanFilterGray => 'Gri';

  @override
  String get scanFilterBw => 'Siyah-beyaz';

  @override
  String get scanApplyAll => 'Hepsine uygula';

  @override
  String get scanPageFailed => 'Sayfa görüntülenemedi';

  @override
  String get scanCropHint =>
      'Yamuk sayfayı \"Köşeleri ayarla\" ile düzeltebilirsin';

  @override
  String get scanAddAsPdf => 'PDF olarak ekle';

  @override
  String get scanAddAsImages => 'Görsel olarak ekle';

  @override
  String get scanBuildingPdf => 'PDF hazırlanıyor…';

  @override
  String scanOcrProgress(int done, int total) {
    return 'Metin tanınıyor… $done/$total';
  }

  @override
  String get scanAutoDetect => 'Kenarları otomatik bul';

  @override
  String get scanReset => 'Sıfırla';

  @override
  String get scanDetecting => 'Kenarlar aranıyor…';

  @override
  String get scanAutoFound =>
      'Kenarlar otomatik bulundu; gerekirse tutamaçlardan ince ayar yap';

  @override
  String get scanDragHint => 'Köşeleri kâğıdın kenarlarına sürükle';

  @override
  String get scanApplyCorners => 'Düzelt ve uygula';

  @override
  String get scanWorking => 'Düzeltiliyor…';

  @override
  String get scanPdfAdded => 'Tarama, PDF eki olarak nota eklendi';

  @override
  String get premiumTitle => 'Premium';

  @override
  String premiumStatusActive(String date) {
    return 'Premium etkin — $date tarihine kadar';
  }

  @override
  String get premiumStatusFree => 'Ücretsiz sürümü kullanıyorsun';

  @override
  String get premiumPerksTitle => 'Premium ile ne değişir?';

  @override
  String get premiumPerkAi => 'Günlük yapay zeka puanı';

  @override
  String get premiumPerkAttach => 'Ek dosya boyutu';

  @override
  String get premiumPerkStorage => 'Bulut depolama alanı';

  @override
  String get premiumPerkAuto => 'Otomatik günlük içerik';

  @override
  String get premiumPerkAutoBody =>
      'Günlük brifing ve öneriler her gün kendiliğinden hazırlanır; ücretsizde yalnız düğmeyle üretilir.';

  @override
  String get premiumHowTitle => 'Nasıl edinilir?';

  @override
  String get premiumHowBody =>
      'Premium yakında Play Store üzerinden satın alınabilecek. Şu an erken erişim dönemindeyiz.';

  @override
  String get premiumByokHint =>
      'Kendi Gemini API anahtarını girersen yapay zeka özellikleri kotasız çalışır — Premium\'dan bağımsız (Ayarlar → Yapay Zeka).';

  @override
  String get premiumDiscoverTitle => 'Gözden kaçan özellikler';

  @override
  String get discoverScanBody =>
      'Kamerayla taranan sayfalar kenar bulma ve netleştirmeyle düzelir, tek dokunuşla ARANABİLİR PDF olur — metin katmanı cihazda, ücretsiz üretilir.';

  @override
  String get discoverSemanticBody =>
      'Arama kutusundaki \"Akıllı\" sekmesi kelime değil ANLAM arar: \"uçak saatleri\" yazınca seyahat notun çıkar.';

  @override
  String get discoverAssistantBody =>
      'Ana ekrandaki mikrofon konuşmanı nota, listeye ve hatırlatıcıya kendisi çevirir — \"yarın 9\'da diş randevusu\" demen yeter.';

  @override
  String get discoverLockBody =>
      'Bir notu parmak izi/yüz kilidiyle kilitleyebilirsin: içeriği aramaya, widget\'a ve AI\'a hiç sızmaz.';

  @override
  String get discoverHiddenBody =>
      'Gizli klasördeki notlar ana ekranda ve aramada hiç görünmez; klasörü göstermek kimlik doğrulaması ister.';

  @override
  String get discoverExportBody =>
      'Her not görselleriyle birlikte PDF ya da Word olarak dışa aktarılabilir (paylaş menüsünde).';

  @override
  String get guestSignInUnavailable =>
      'Masuk tanpa Google sedang nonaktif: login anonim belum diaktifkan di konsol Firebase. Masuk dengan Google atau coba lagi setelah admin mengaktifkannya.';

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
      'Warna, sorotan, tebal, dan garis bawah dari catatanmu juga tampil di kartu layar utama. Jika nonaktif, kartu menampilkan teks polos.';

  @override
  String get fontSizeSmall => 'Kecil';

  @override
  String get fontSizeMedium => 'Sedang';

  @override
  String get fontSizeLarge => 'Besar';

  @override
  String get fontSizeXLarge => 'Sangat besar';

  @override
  String get appFontSetting => 'Font';

  @override
  String get appFontInfo =>
      'Font yang dipakai di seluruh aplikasi. Font milik catatan lebih diutamakan. Semua font sudah menyatu dengan aplikasi — tak perlu internet.';

  @override
  String get fontGroupSans => 'Sans';

  @override
  String get fontGroupSerif => 'Serif';

  @override
  String get fontGroupMono => 'Monospace';

  @override
  String get fontGroupHand => 'Tulisan tangan';

  @override
  String get appFontDefaultSuffix => 'bawaan';

  @override
  String get pdfSelectOcrRunning => 'Metin tanınıyor…';

  @override
  String get pdfSelectOcrNone => 'Bu sayfada metin bulunamadı';

  @override
  String pdfSelectCopied(int n) {
    return '$n karakter kopyalandı';
  }

  @override
  String get bubbleAdd => 'Not balonu bırak';

  @override
  String get bubbleAddDone => 'Balon bırakmayı bitir';

  @override
  String get bubbleCollapse => 'Balonu küçült';

  @override
  String get bubbleHint => 'Buraya notunu yaz…';

  @override
  String get bubbleTapToPlace => 'Sayfada balonu bırakmak istediğin yere dokun';

  @override
  String get aiModelPodcast => 'Podcast anlatısı';

  @override
  String get listenAiVoice => 'Yapay zekâ sesiyle dinle';

  @override
  String get listenAiVoiceInfo =>
      'Cihaz sesi yerine Gemini seslendirir: daha doğal, her paragraf bir model çağrısı harcar.';

  @override
  String listenAiVoiceFailed(String error) {
    return 'Yapay zekâ seslendirmesi başarısız oldu ($error). Cihaz sesiyle okunuyor.';
  }

  @override
  String get ttsSectionTitle => 'Seslendirme';

  @override
  String get ttsEngineDevice => 'Cihaz sesi';

  @override
  String get ttsEngineAi => 'Yapay zekâ';

  @override
  String get ttsEngineDeviceInfo =>
      'Cihazın yerleşik sesi okur: bedava, çevrimdışı ve sınırsız uzunlukta.';

  @override
  String get ttsEngineAiInfo =>
      'Gemini\'nin seslendirme modeli okur: belirgin daha doğal ama her paragraf bir model çağrısıdır ve kendi Gemini anahtarını ister.';

  @override
  String get ttsEngineAiUnavailable =>
      'Suara AI butuh kunci Gemini milikmu. Sampai itu ada, pembacaan memakai suara perangkat.';

  @override
  String get ttsModel => 'Seslendirme modeli';

  @override
  String get ttsVoice => 'Yapay zekâ sesi';

  @override
  String get shareAsNote => 'Not olarak paylaş';

  @override
  String get shareAsNoteInfo =>
      'Notu ekleri, sayfa notları, çizimleri ve balonlarıyla gönderir; karşı taraf Not uygulamasında aynı şekilde açar.';

  @override
  String get shareAsNotePreparing => 'Not paketi hazırlanıyor…';

  @override
  String get shareAsText => 'Sebagai teks biasa';

  @override
  String get shareAsTextInfo =>
      'Mengirim teks catatan dan catatan halaman ke aplikasi mana pun.';

  @override
  String get shareAsTextEmpty =>
      'Catatan ini tidak punya teks untuk dibagikan.';

  @override
  String get sharePdfWithBubbles => 'Sebagai PDF bergelembung';

  @override
  String get sharePdfWithBubblesInfo =>
      'Gelembung, sorotan, dan coretan dicetak ke dalam PDF; siapa pun bisa membukanya, dan di Not terbuka bisa diedit.';

  @override
  String get sharePdfWithBubblesNone =>
      'Catatan ini tidak punya PDF bergelembung atau bercoretan.';

  @override
  String get sharePdfWithBubblesPreparing => 'Menyiapkan PDF bergelembung…';

  @override
  String get sharePdfWithBubblesSuffix => ' (bergelembung)';

  @override
  String get bubbleStar => 'Yıldızla';

  @override
  String get bubbleEdit => 'Balonu düzenle';

  @override
  String get bubbleStarredOnly => 'Yalnız yıldızlılar';

  @override
  String get bubbleSearchHint => 'Balonlarda ara…';

  @override
  String get bubblesOverviewTitle => 'Balonlar';

  @override
  String get bubblesEmpty =>
      'Henüz balon yok. Belgede bir metni seçip vurgula ya da sayfaya balon bırak.';

  @override
  String get bubblesNoMatch => 'Aramaya uyan balon yok.';

  @override
  String get bubbleNoText => '(boş balon)';

  @override
  String get pdfHighlight => 'Vurgula';

  @override
  String get pdfHighlightWithNote => 'Vurgula + not';

  @override
  String get pageNotesShow => 'Sayfa notunu göster';

  @override
  String get pageNotesHide => 'Sayfa notunu gizle';

  @override
  String get bubbleSave => 'Kaydet';

  @override
  String get bubbleTitleHint => 'Başlık';

  @override
  String get bubbleUrgent => 'Acil (yanıp söner)';

  @override
  String get captureModeQuestion => 'Notu nasıl açalım?';

  @override
  String get captureModeBubbles => 'Balonlu';

  @override
  String get captureModeBubblesInfo =>
      'İçerik belge sayfası olur: üzerine balon, vurgu ve kalem.';

  @override
  String get captureModeClassic => 'Klasik';

  @override
  String get captureModeClassicInfo =>
      'Düz metin notu; içerik ek olarak girer.';

  @override
  String get captureModeNew => 'YENİ';

  @override
  String get imagePrepareTitle => 'Görselleri düzelt';

  @override
  String get imagePrepareDone => 'Devam';

  @override
  String get imageRotateLeft => 'Sola döndür';

  @override
  String get imageRotateRight => 'Sağa döndür';

  @override
  String get videoFrameFailed =>
      'Videodan kare alınamadı; not klasik açılıyor.';

  @override
  String get bubbleArrowHide => 'Oku gizle';

  @override
  String get bubbleArrowShow => 'Oku göster';

  @override
  String get speechPitch => 'Ses tonu';

  @override
  String get speechVoicePickerTitle => 'Ses seçimi';

  @override
  String get formatRemove => 'Hapus';

  @override
  String get exportTitle => 'Ekspor';

  @override
  String get exportNotesOption => 'Teks catatan (PDF / Word)';

  @override
  String get exportNotesOptionInfo =>
      'Teks dan gambar catatan; balon tidak disertakan.';

  @override
  String get captureNoteTitle => 'Judul catatan (opsional)';

  @override
  String get captureNoteTitleHint => 'Dokumen baru juga memakai nama ini';

  @override
  String get imageOcrTitle => 'Kenali teks pada gambar';

  @override
  String get imageOcrNone => 'Tidak ada teks pada gambar ini.';

  @override
  String imageOcrHint(int count) {
    return '$count baris dikenali · ketuk untuk memilih';
  }

  @override
  String imageOcrSelected(int count) {
    return '$count baris dipilih';
  }

  @override
  String get imageOcrShort => 'Kenali teks';

  @override
  String get imageOcrWorking => 'Mengenali teks…';

  @override
  String get imageOcrSelectHint =>
      'Ketuk: kata · Tahan dan seret: huruf per huruf';

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
      'Teks mengalir di samping gambar sempit yang rata kiri atau kanan; gambar tengah memakai lebar penuh.';

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
  String get aiModelSearch => 'Cari model';

  @override
  String get aiModelOthers => 'MODEL LAINNYA';

  @override
  String get aiModelNoMatch => 'Tidak ada model yang cocok.';

  @override
  String get aiModelAutoInfo =>
      'Aplikasi mencoba model paling sesuai secara berurutan.';

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
  String get aiModelShowAll => 'Tampilkan semua';

  @override
  String get aiModelShowAllInfo =>
      'Juga menampilkan model yang tidak dipakai aplikasi.';

  @override
  String get rotateFailed => 'Görsel döndürülemedi.';

  @override
  String get dashboardBackgroundPick => 'Zemin görseli seç';

  @override
  String get dashboardBackgroundChange => 'Zemin görselini değiştir';

  @override
  String podcastRenderingAudio(int done, int total) {
    return 'Ses hazırlanıyor: $done/$total parça';
  }

  @override
  String get podcastExportAudio => 'Ses dosyası olarak dışa aktar';

  @override
  String get podcastExportAudioCost =>
      'Metnin tamamı yapay zekâ sesiyle yeniden seslendirilip tek bir WAV dosyası olarak hazırlanır. Bu işlem Gemini kotandan düşer ve uzun metinlerde birkaç dakika sürebilir.';

  @override
  String get podcastShareText => 'Metni paylaş';

  @override
  String get podcastSaveAsNote => 'Yeni not olarak kaydet';

  @override
  String get podcastSavedAsNote => 'Podcast metni not olarak kaydedildi.';

  @override
  String get listenPreparingVoice => 'Ses hazırlanıyor…';

  @override
  String get appearancePreviewTitle => 'Örnek metin';

  @override
  String get appearancePreviewNoteTitle => 'Örnek not başlığı';

  @override
  String get appearancePreviewBody =>
      'Notların bu yazı tipi ve boyutta görünecek. Satır içi **kalın**, ~altı çizili~ ve ==2:vurgulu== metinler de böyle durur.';

  @override
  String get appearancePreviewItem => 'Liste maddesi böyle görünür';

  @override
  String get convertToText => 'Metne dönüştür';

  @override
  String get convertToList => 'Listeye dönüştür';

  @override
  String get convertedToText => 'Liste düz metne dönüştürüldü.';

  @override
  String get convertedToList => 'Metin listeye dönüştürüldü.';

  @override
  String get convertToListEmpty => 'Listeye dönüştürülecek satır yok.';

  @override
  String get listTwoColumns => '2 sütun';

  @override
  String get listOneColumn => 'Tek sütun';

  @override
  String get sortItems => 'Maddeleri sırala';

  @override
  String get sortStarredFirst => 'Önce yıldızlılar';

  @override
  String get sortUncheckedFirst => 'Tamamlananlar sona';

  @override
  String get sortAlphabetical => 'A → Z';

  @override
  String get sortAlphabeticalDesc => 'Z → A';

  @override
  String get imagesToAttachments => 'Görselleri eke dönüştür';

  @override
  String imagesToAttachmentsDone(int count) {
    return '$count görsel eke dönüştürüldü.';
  }

  @override
  String get imageOcrShowRecognized => 'Tanınan metni vurgula';

  @override
  String get imageOcrHideRecognized => 'Vurguyu kaldır';

  @override
  String get bubblePlainMode => 'Açık metin alanı';

  @override
  String get bubblePlainModeOn => 'Açık metin alanı açık';

  @override
  String get bubblePlainTapToPlace => 'Metnin geleceği yere dokun';

  @override
  String get bubblePlainHint => 'Yazmak için dokun';

  @override
  String get noteSearchTitle => 'Notta ara';

  @override
  String get noteSearchHint => 'Bu notta ara…';

  @override
  String get noteSearchEmptyHint =>
      'Notun metninde, maddelerinde ve sayfa notlarında anında arar. Ek görsellerin ve PDF\'lerin içi için aşağıdaki taramayı başlat.';

  @override
  String get noteSearchNoHit => 'Eşleşme bulunamadı.';

  @override
  String get noteSearchScanAttachments => 'Ekleri tara';

  @override
  String get noteSearchAskAi => 'Yapay zekâya sor';

  @override
  String get noteTitleLabel => 'Başlık';

  @override
  String get noteBodyLabel => 'Not metni';

  @override
  String get itemLabel => 'Madde';

  @override
  String noteSearchAttachmentsInfo(int count) {
    return '$count ek taranabilir (görsel/PDF).';
  }

  @override
  String noteSearchAttachmentsReady(int count) {
    return '$count ekin içi de aranıyor.';
  }

  @override
  String pageLabel(int page) {
    return 'Sayfa $page';
  }

  @override
  String get archiveNotebook => 'Arşiv defteri';

  @override
  String get archiveNotebookInfo =>
      'Önemli belgeleri ve görselleri kopyasıyla toplayan, kendi sayfaları olan defter.';

  @override
  String get archivePageImages => 'Görseller';

  @override
  String get archivePageVideos => 'Videolar';

  @override
  String get archivePageDocuments => 'Belgeler';

  @override
  String get archivePageTexts => 'Metinler';

  @override
  String get archiveNewPage => 'Yeni sayfa';

  @override
  String get archivePageName => 'Sayfa adı (ör. Faturalar)';

  @override
  String get archivePageEmpty => 'Bu sayfa henüz boş.';

  @override
  String get archiveSearchHint => 'Defterde ara…';

  @override
  String get archiveAddText => 'Metin ekle';

  @override
  String get archiveAddFile => 'Dosya ekle';

  @override
  String get archiveCopyHere => 'Arşiv defterine kopyala';

  @override
  String get archiveNoNotebook =>
      'Henüz arşiv defteri yok. Önce bir tane oluştur.';

  @override
  String get archiveNothingToCopy => 'Bu notta kopyalanacak ek yok.';

  @override
  String archiveDeleteEntry(String name) {
    return '\"$name\" defterden silinsin mi? Bu kopya kalıcı olarak gider.';
  }

  @override
  String archiveCopied(int count) {
    return '$count dosya arşiv defterine kopyalandı.';
  }

  @override
  String get archiveCaptureTitle => 'Görselden yakala';

  @override
  String get archiveCapturePage => 'Sayfa';

  @override
  String get archiveCapturePageInfo =>
      'Yapay zekânın önerdiği tür. Boş bırakılırsa Metinler sayfasına düşer.';

  @override
  String get archiveCaptureText => 'Tanınan metin';

  @override
  String get attachmentTagInsert => 'Metne ekle';

  @override
  String get attachmentTagInserted => 'Ek etiketi metne eklendi.';

  @override
  String get attachmentTagPreview => 'Eki önizle';

  @override
  String get attachmentTagEdit => 'Eki düzenle';

  @override
  String archiveCardSummary(int files, int texts) {
    return '$files dosya · $texts metin';
  }

  @override
  String get archiveEntryTitle => 'Başlık';

  @override
  String get archiveLinkedFile => 'Bağlı dosya';

  @override
  String get archiveNoLink => 'Bağlı dosya yok';

  @override
  String get attachmentTagEmbed => 'Seçili yazıya ek göm';

  @override
  String get attachmentTagNoAttachment =>
      'Önce nota bir dosya ekle; sonra yazıya gömebilirsin.';

  @override
  String get bubbleModeBubble => 'Balon';

  @override
  String get attachmentTagEmbedInfo =>
      'Yazıyı seçtiysen o yazıya, seçmediysen imlecin yerine bağlanır';

  @override
  String get attachmentTagPickText =>
      'Şimdi bağlanacak yazıyı seç, sonra \"Buraya bağla\"ya dokun.';

  @override
  String get attachmentTagLinkHere => 'Buraya bağla';

  @override
  String attachmentTagPendingBanner(String name) {
    return '$name bağlanacak — yazıyı seç';
  }

  @override
  String get docNameNotesSuffix => 'notlar';

  @override
  String get docNamePhoto => 'Fotoğraf notları';

  @override
  String get docNameScan => 'Tarama notları';

  @override
  String get docNameImage => 'Görsel notları';

  @override
  String get docNameVideo => 'Görüntü notları';

  @override
  String get folderManage => 'Klasörü yönet';

  @override
  String get folderEmpty => 'Bu klasör boş';

  @override
  String get folderEmptyHint =>
      'Aşağıdaki + ile buraya not ekle ya da bir notu düzenlerken bu klasöre taşı.';

  @override
  String get brainstormTitle => 'AI ile beraber düşün';

  @override
  String get brainstormRowInfo =>
      'AI önce bir ana hat çıkarır, sonra birlikte geliştirirsiniz';

  @override
  String get brainstormIntro =>
      'Yukarıdaki başlıklardan birine dokun ya da doğrudan yaz — birlikte düşünmeye başlayalım.';

  @override
  String get brainstormOutlineTitle => 'ANA HAT';

  @override
  String get brainstormInputHint => 'Bir fikir yaz ya da soru sor…';

  @override
  String get brainstormAddIdea => 'Nota ekle';

  @override
  String get brainstormAdded => 'Nota eklendi';

  @override
  String get folderShared => 'Bu klasör bir arkadaşınla ortak';

  @override
  String get friendsTitle => 'Kişiler';

  @override
  String get friendsAdd => 'Arkadaş ekle';

  @override
  String get friendsEmpty =>
      'Henüz kimse yok. E-postayla bir arkadaş ekle, klasörlerini onunla paylaş.';

  @override
  String get friendsRequestsTitle => 'İSTEKLER';

  @override
  String get friendsListTitle => 'ARKADAŞLARIM';

  @override
  String get friendsAddEmailHint => 'arkadas@eposta.com';

  @override
  String get friendsSendRequest => 'İstek gönder';

  @override
  String get friendsRequestSent => 'İstek gönderildi';

  @override
  String get friendsNotFound =>
      'Bu e-postayla kayıtlı bir kullanıcı bulunamadı. Kişinin uygulamayı Google hesabıyla en az bir kez açmış olması gerekir.';

  @override
  String get friendsSelf => 'Kendini arkadaş ekleyemezsin';

  @override
  String get friendsAlready => 'Zaten arkadaşsınız';

  @override
  String get friendsDecline => 'Reddet';

  @override
  String get friendsAccept => 'Kabul et';

  @override
  String get friendsRemove => 'Kaldır';

  @override
  String get friendsRemoveConfirmTitle => 'Arkadaşlıktan çıkar';

  @override
  String friendsRemoveConfirmBody(Object name) {
    return '$name arkadaş listenden kaldırılsın mı? Onunla paylaştığın klasörler artık görünmez.';
  }

  @override
  String get friendsNeedsAccount =>
      'Kişiler ve klasör paylaşımı Google hesabı bağlı kullanıcılarda çalışır.';

  @override
  String get friendsSearchHint => 'İsim veya e-posta ile ara';

  @override
  String get friendsSearchTab => 'Ara';

  @override
  String get friendsSearchEmailTab => 'E-posta ile';

  @override
  String get friendsSearchEmpty => 'Sonuç yok';

  @override
  String get friendsSearchTooShort => 'Aramak için en az 2 karakter yaz';

  @override
  String get friendsSearchAdd => 'Ekle';

  @override
  String get folderShare => 'Paylaş';

  @override
  String folderShareCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kişiyle paylaşıldı',
      one: '1 kişiyle paylaşıldı',
    );
    return '$_temp0';
  }

  @override
  String folderShareTitle(Object name) {
    return '\"$name\" klasörünü paylaş';
  }

  @override
  String get folderShareInfo =>
      'Seçtiğin arkadaşa davet gider; kabul edince klasörü görür. Yetkiyi (okuma / yazma / her ikisi) sen belirlersin.';

  @override
  String get friendsRowInfo => 'Arkadaş ekle, klasörlerini onlarla paylaş';

  @override
  String get accountRecoverConflictTitle =>
      'Bu cihazda kaydedilmemiş notlar var';

  @override
  String accountRecoverConflictBody(Object count) {
    return 'Bu Google hesabı zaten başka bir oturuma bağlı; ona geçersen bu cihazdaki $count not artık görünmeyecek (silinmezler ama bu ekrandan erişilemezler). Yine de geçmek istiyor musun?';
  }

  @override
  String get accountRecoverConflictProceed => 'Yine de geç';

  @override
  String get folderRoleRead => 'Okuma';

  @override
  String get folderRoleWrite => 'Yazma';

  @override
  String get folderRoleBoth => 'Okuma + yazma';

  @override
  String get folderInvitePending => 'Davet gönderildi, yanıt bekleniyor';

  @override
  String get folderWriteOnlyTitle => 'Yalnız yazma yetkin var';

  @override
  String get folderWriteOnlyHint =>
      'Bu klasöre yeni not ekleyebilirsin ama içindeki notları göremezsin.';

  @override
  String get folderChatTitle => 'Sohbet';

  @override
  String get folderChatHint => 'Mesaj yaz…';

  @override
  String get folderChatSend => 'Gönder';

  @override
  String get folderChatEmptyTitle => 'Henüz mesaj yok';

  @override
  String get folderChatEmptyHint =>
      'Bu klasörü paylaştığın kişilerle burada yazışabilirsin.';

  @override
  String get folderInviteTitle => 'Klasör daveti';

  @override
  String folderInviteBody(Object name) {
    return '\"$name\" klasörü seninle paylaşıldı.';
  }

  @override
  String get folderInviteAccepted => 'Klasör eklendi';

  @override
  String get folderInviteDeclined => 'Davet reddedildi';

  @override
  String friendRequestBanner(Object name) {
    return '$name sana arkadaşlık isteği gönderdi';
  }

  @override
  String get friendRequestAccepted => 'Arkadaş eklendi';

  @override
  String get sendNoteAction => 'Arkadaşa gönder';

  @override
  String get sendNoteTitle => 'Notu arkadaşına gönder';

  @override
  String get sendNoteInfo =>
      'Notun bir kopyası seçtiğin kişinin \"Gelen notlar\" kutusuna düşer. Ekler (görsel, belge, ses) gönderilmez.';

  @override
  String sendNoteSent(Object name) {
    return 'Not $name kişisine gönderildi';
  }

  @override
  String get inboxTitle => 'Gelen notlar';

  @override
  String get inboxEmpty => 'Gelen not yok';

  @override
  String get inboxEmptyHint =>
      'Arkadaşlarının sana gönderdiği notlar burada birikir.';

  @override
  String inboxFrom(Object name) {
    return '$name gönderdi';
  }

  @override
  String get inboxAccept => 'Notlarıma ekle';

  @override
  String get inboxAccepted => 'Not notlarına eklendi';

  @override
  String get folderShelfExpand => 'Klasörleri büyüt';

  @override
  String get folderShelfCollapse => 'Klasörleri daralt';

  @override
  String get accountSheetLocalInfo =>
      'Notların yalnız bu cihazda. Google hesabı bağlarsan yedeklenir ve arkadaş ekleyebilirsin.';

  @override
  String get accountSettings => 'Hesap ayarları';

  @override
  String get videoFramesExtracting => 'Videodan kareler alınıyor…';

  @override
  String get areaSelect => 'Alan seç';

  @override
  String get areaSelectOff => 'Alan seçimini kapat';

  @override
  String get areaSelectHint =>
      'Kopyalamak ya da yapay zekâya sormak istediğin alanı parmağınla çiz.';

  @override
  String get areaCopyImage => 'Görsel olarak kopyala';

  @override
  String get areaCopied => 'Seçilen alan panoya kopyalandı.';

  @override
  String get areaAskAi => 'Yapay zekâya sor';

  @override
  String get areaAskTitle => 'Seçilen alan';

  @override
  String get areaAskHint =>
      'İstersen bir soru yaz (boş bırakırsan formülü/metni çıkarıp açıklar).';

  @override
  String get areaAskRun => 'Sor';

  @override
  String get areaCaptureFailed => 'Seçilen alanın görüntüsü alınamadı.';

  @override
  String get areaTooSmall => 'Seçilen alan çok küçük.';

  @override
  String get areaAddToNote => 'Nota ekle';

  @override
  String get bubbleTextFill => 'Yazı zemini';

  @override
  String get bubbleTextFillNone => 'Zeminsiz';

  @override
  String get bubbleTextAlignLeft => 'Sola hizala';

  @override
  String get bubbleTextAlignCenter => 'Ortala';

  @override
  String get bubbleTextAlignRight => 'Sağa hizala';

  @override
  String get dashboardBackgroundPattern => 'Desen';

  @override
  String get dashboardBackgroundColor => 'Zemin rengi';

  @override
  String get dashboardBackgroundImageSection => 'Zemin görseli';

  @override
  String get dashboardBackgroundReset => 'Varsayılana dön';

  @override
  String get patternNone => 'Düz';

  @override
  String get patternDots => 'Noktalı';

  @override
  String get patternGrid => 'Kareli';

  @override
  String get patternLines => 'Çizgili';

  @override
  String get patternDiagonal => 'Çapraz';

  @override
  String get patternGraph => 'Milimetrik';
}
