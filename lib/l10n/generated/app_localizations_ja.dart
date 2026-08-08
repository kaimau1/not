// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appName => 'メモ';

  @override
  String get loginTagline => 'あなたのメモを、どの端末でも';

  @override
  String get signInWithGoogle => 'Google でログイン';

  @override
  String loginError(String error) {
    return 'ログインに失敗しました: $error';
  }

  @override
  String get searchHint => 'メモを検索...';

  @override
  String get filterAll => 'すべて';

  @override
  String get filterText => 'テキスト';

  @override
  String get filterChecklist => 'リスト';

  @override
  String get filterOrdered => '番号付き';

  @override
  String get filterPinned => '固定';

  @override
  String get filterStarred => 'スター付き';

  @override
  String get star => 'スターを付ける';

  @override
  String get unstar => 'スターを外す';

  @override
  String editedAt(String date) {
    return '編集: $date';
  }

  @override
  String get sectionPinned => '固定';

  @override
  String get sectionOthers => 'その他';

  @override
  String get emptyNotes => 'メモはまだありません';

  @override
  String get emptyNotesHint => '+ をタップして最初のメモを作成しましょう';

  @override
  String get emptySearch => '結果が見つかりません';

  @override
  String get newTextNote => 'テキストメモ';

  @override
  String get newChecklist => 'リスト';

  @override
  String get newOrderedList => '番号付きリスト';

  @override
  String get noteDeleted => 'メモを削除しました';

  @override
  String notesDeletedCount(int count) {
    return '$count 件のメモを削除しました';
  }

  @override
  String selectedCount(int count) {
    return '$count 件選択中';
  }

  @override
  String get deleteSelected => '選択したものを削除';

  @override
  String get undo => '元に戻す';

  @override
  String get redo => 'やり直す';

  @override
  String get titleHint => 'タイトル';

  @override
  String get bodyHint => 'メモ...';

  @override
  String get newItemHint => '新しい項目';

  @override
  String moreItemsCount(int count) {
    return '他 $count 件の項目';
  }

  @override
  String get addAttachment => '追加';

  @override
  String get addAttachmentMore => 'その他の添付ファイル…';

  @override
  String get addImage => '画像を追加';

  @override
  String get addPdf => 'PDF を追加';

  @override
  String get addSlide => 'スライドを追加';

  @override
  String get pasteImage => 'クリップボードから画像を貼り付け';

  @override
  String get clipboardEmpty => 'クリップボードに画像がありません';

  @override
  String get noNoteSelected => '左からメモを選んでください';

  @override
  String attachmentFailed(String error) {
    return '添付ファイルを追加できませんでした: $error';
  }

  @override
  String get attachmentUploading => 'アップロード中...';

  @override
  String get attachmentUploadFailed =>
      'Yüklenemedi — yeniden denemek için dokun';

  @override
  String get attachmentNotSynced => 'このファイルはまだこの端末に同期されていません';

  @override
  String attachmentTooLarge(int limit) {
    return 'ファイルが大きすぎます（最大 $limit MB）';
  }

  @override
  String storageFull(String limit) {
    return '保存容量がいっぱいです（$limit）。古い添付ファイルを削除して空き容量を作ってください。';
  }

  @override
  String get storageUsage => 'ストレージ';

  @override
  String storageUsageValue(String used, String limit) {
    return '$limit 中 $used 使用';
  }

  @override
  String get removeAttachment => '添付ファイルを削除';

  @override
  String get pin => '固定';

  @override
  String get unpin => '固定を解除';

  @override
  String get delete => '削除';

  @override
  String get color => '色';

  @override
  String get aiTitle => 'AI';

  @override
  String get aiSummarize => 'メモを要約';

  @override
  String get aiAnalyze => '分析';

  @override
  String get aiSectionNote => 'このメモ';

  @override
  String get aiSectionAttachments => '添付ファイル';

  @override
  String get summarize => '要約する';

  @override
  String get summaryDetailTitle => '要約の種類';

  @override
  String get summaryShort => '短い要約';

  @override
  String get summaryShortInfo => '数文の概要と要点';

  @override
  String get summaryDetailed => '詳しい要約';

  @override
  String get summaryDetailedInfo => '原文を開かなくて済むほど詳しく';

  @override
  String get listen => '聞く';

  @override
  String get ask => '質問する';

  @override
  String get extractText => 'テキストを抽出';

  @override
  String get transcribe => '文字起こし';

  @override
  String get listenToNote => '読み上げる';

  @override
  String get aiNoApiKey => '先に設定で Gemini API キーを入力してください';

  @override
  String aiError(String error) {
    return 'AI リクエストに失敗しました: $error';
  }

  @override
  String get aiSummaryTitle => 'AI 要約';

  @override
  String get aiThinking => '考え中...';

  @override
  String get copy => 'コピー';

  @override
  String get copied => 'コピーしました';

  @override
  String get settingsSearchHint => '設定を検索 — 「ブリーフィング」、「マイク」';

  @override
  String settingsSearchEmpty(String query) {
    return '「$query」に一致する設定はありません';
  }

  @override
  String get settings => '設定';

  @override
  String get settingsAppearance => '外観';

  @override
  String get themeSystem => 'システム';

  @override
  String get themeLight => 'ライト';

  @override
  String get themeDark => 'ダーク';

  @override
  String get settingsAi => 'AI';

  @override
  String get geminiApiKey => 'Gemini API キー';

  @override
  String get geminiApiKeyHint => 'AIza... で始まるキーを貼り付け';

  @override
  String get geminiApiKeyInfo =>
      'キーは任意です。キーがなくても AI リクエストはアプリ内蔵のサービスを通ります（毎日の無料枠があり、Premium ならさらに多くなります）。自分のキーで無制限に使うには aistudio.google.com で無料のキーを取得してください。キーはこの端末の安全な保管領域にのみ保存されます。';

  @override
  String aiBuiltInPremium(int count) {
    return '内蔵 AI: Premium — 本日の残りポイント $count';
  }

  @override
  String aiBuiltInRemaining(int count) {
    return '内蔵 AI: 本日の残り無料ポイント $count';
  }

  @override
  String get aiBuiltInByok => '自分のキーを使用中 — 無制限';

  @override
  String get aiReport => 'この回答を報告';

  @override
  String get aiReportThanks => '報告を受け付けました。ありがとうございます';

  @override
  String get privacyPolicyTitle => 'プライバシーポリシー';

  @override
  String get lockNote => 'ロック';

  @override
  String get unlockNote => 'ロックを解除';

  @override
  String get lockedNote => 'ロックされたメモ';

  @override
  String get unlockAuthReason => 'ロックされたメモを開くには本人確認をしてください';

  @override
  String get exportBackup => 'バックアップを書き出す (JSON)';

  @override
  String get expandListItems => 'リストの行を全文表示';

  @override
  String get expandListItemsInfo =>
      '長い項目は複数行に折り返され、全体が見えたままになります。オフの場合、行は 1 行に収まり、タップすると展開します。';

  @override
  String get quickCaptureRowSetting => 'クイックメモバー';

  @override
  String get quickCaptureRowInfo =>
      'ホーム画面上部に1行の「新しいメモ...」欄を表示します。オフの場合は+ボタンを使います。';

  @override
  String get emptyTrash => 'ゴミ箱を空にする';

  @override
  String emptyTrashConfirm(int count) {
    return '$count 件のメモが完全に削除されます。この操作は取り消せません。よろしいですか？';
  }

  @override
  String get trashEmptied => 'ゴミ箱を空にしました';

  @override
  String get validateAndSave => '確認して保存';

  @override
  String get clear => 'クリア';

  @override
  String get aiDiagnostics => 'AI 診断';

  @override
  String get aiDiagnosticsEmpty => '記録されたエラーはありません';

  @override
  String aiDiagnosticsCount(int count) {
    return '直近 $count 件のエラー記録';
  }

  @override
  String get apiKeyValid => 'API キーを確認して保存しました';

  @override
  String get apiKeyInvalid => 'API キーが正しくありません';

  @override
  String get apiKeySavedBadge => '保存済み';

  @override
  String get removeApiKey => 'キーを削除';

  @override
  String get refresh => '更新';

  @override
  String get account => 'アカウント';

  @override
  String get signOut => 'ログアウト';

  @override
  String get signOutConfirm => 'ログアウトしてもよろしいですか？';

  @override
  String get signOutAnonymousWarning =>
      'ローカルアカウントを使用中です。サインアウトすると、このアカウントとすべてのメモに二度とアクセスできなくなります（バックアップがなければ復元不可）。先にGoogleアカウントを連携してください。それでもサインアウトしますか？';

  @override
  String get deleteAccount => 'アカウントとデータを削除';

  @override
  String get deleteAccountWarning =>
      'この操作は取り消せません。すべてのメモ、添付ファイル、アカウントが完全に削除されます。続行しますか？';

  @override
  String get deleteAccountConfirm => '完全に削除';

  @override
  String get licensesTitle => 'オープンソースライセンス';

  @override
  String get generating => '生成中...';

  @override
  String get retry => '再試行';

  @override
  String get cancel => 'キャンセル';

  @override
  String get close => '閉じる';

  @override
  String get ok => 'OK';

  @override
  String get syncPending => '同期待ち';

  @override
  String get synced => '同期済み';

  @override
  String genericError(String error) {
    return '問題が発生しました: $error';
  }

  @override
  String get addTag => 'タグ';

  @override
  String get tagHint => '例: 仕事、家、学校';

  @override
  String get addReminder => 'リマインダー';

  @override
  String get share => '共有';

  @override
  String get archive => 'アーカイブ';

  @override
  String get unarchive => 'アーカイブを解除';

  @override
  String get archiveTitle => 'アーカイブ';

  @override
  String get archiveEmpty => 'アーカイブにメモはありません';

  @override
  String get trashTitle => 'ゴミ箱';

  @override
  String get trashEmpty => 'ゴミ箱は空です';

  @override
  String get trashInfo => '削除したメモはここに残ります。元に戻すことも、完全に削除することもできます。';

  @override
  String get restore => '元に戻す';

  @override
  String get deleteForever => '完全に削除';

  @override
  String get deleteForeverConfirm => 'このメモは完全に削除されます。よろしいですか？';

  @override
  String assistantDeleteConfirm(String title) {
    return 'Asistan \"$title\" notunu çöp kutusuna taşımak istiyor. Onaylıyor musun?';
  }

  @override
  String get recordAudio => '音声録音';

  @override
  String get recording => '録音中...';

  @override
  String get stopAndSave => '終了して追加';

  @override
  String get micPermissionDenied => 'マイクの権限が拒否されました';

  @override
  String get speechRecognitionFailed =>
      '音声認識が機能しませんでした。マイクの権限が許可されているか、Google アプリが最新かを確認してください。';

  @override
  String get addDrawing => '手書きを追加';

  @override
  String get drawingTitle => '手書き';

  @override
  String get addToNote => 'メモに追加';

  @override
  String get chatTitle => 'ノートアシスタント';

  @override
  String get chatHint => 'メモについて質問しましょう:「先週書いたあのレシピは何だった？」「買い物リストに足りないものは？」';

  @override
  String get chatInputHint => '質問を入力...';

  @override
  String get fontSize => '文字サイズ';

  @override
  String get fontSizePreview => 'メモはこのように表示されます';

  @override
  String get darkSchedule => 'ダークテーマのスケジュール';

  @override
  String get darkScheduleInfo => '指定した時間帯にダークテーマへ切り替わります';

  @override
  String get aiTranslate => '翻訳';

  @override
  String get voiceCommand => '音声コマンド';

  @override
  String get semanticSearchToggle => 'AI による意味検索';

  @override
  String get semanticSearchHint => '意味で検索:「車の費用」...';

  @override
  String get briefingTitle => '今日のまとめ';

  @override
  String get briefingLoading => 'まとめを準備しています...';

  @override
  String get briefingEmpty => '今日は何もありません';

  @override
  String get briefingSetting => '毎日のまとめ通知';

  @override
  String get briefingSettingInfo => '指定した時刻に、毎朝その日のまとめを通知で受け取ります';

  @override
  String get autoTagSetting => '自動でタグを付ける';

  @override
  String get autoTagSettingInfo => 'タグのないままメモを閉じると、AI が適したタグを追加します';

  @override
  String get suggestTags => 'タグを提案';

  @override
  String get aiFixNote => 'メモを整える';

  @override
  String get fixLevelTitle => 'どこまで整えますか？';

  @override
  String get fixSimple => '軽め';

  @override
  String get fixSimpleInfo => '誤字と入力ミスのみ';

  @override
  String get fixBalanced => 'ほどよく';

  @override
  String get fixBalancedInfo => '文の構成も整えて、読みやすい文章に';

  @override
  String get fixDetailed => 'しっかり';

  @override
  String get fixDetailedInfo => '文章全体を最初から最後まで書き直します';

  @override
  String get existingTagsLabel => 'これまでのタグ';

  @override
  String get aiSkipCheckedSetting => 'チェック済みの項目を AI の編集対象から外す';

  @override
  String get aiSkipCheckedInfo =>
      'AI がリストを整えたり翻訳したりするとき、完了した（チェック済みの）項目はそのまま残ります。編集されるのは未チェックの項目だけです。';

  @override
  String get noteUpdatedUndo => 'メモを更新しました';

  @override
  String get aiImprove => 'メモを改善';

  @override
  String get improveFormal => 'もっと丁寧な文体に';

  @override
  String get improveShorten => '短くする';

  @override
  String get improveBullets => '箇条書きにする';

  @override
  String get improveNumbered => '番号付きリストにする';

  @override
  String get replaceNote => 'メモを置き換える';

  @override
  String get openAsNewNote => '新しいメモとして';

  @override
  String get pdfChatHint => 'この PDF について質問:「要約して」「違約金の条項はある？」「期限はいつ？」';

  @override
  String get pdfChatInputHint => 'PDF についての質問を入力...';

  @override
  String get voiceCaptureHint =>
      '話しかけてください:「牛乳とパンを買う」「明日9時に会議、リマインドして」— 話し終わると AI がメモを作ります。';

  @override
  String get voiceFinish => '完了';

  @override
  String get voiceProcessing => '話した内容を処理しています...';

  @override
  String get voiceNothingHeard => '録音に音声が見つかりませんでした';

  @override
  String get voiceNoteSaved => '音声メモを保存しました';

  @override
  String get openNote => 'メモを開く';

  @override
  String get remindersTitle => 'リマインダー';

  @override
  String get remindersEmpty => 'リマインダーはありません';

  @override
  String get remindersEmptyHint =>
      'メモにリマインダーを追加するか、+ ボタンからリマインダー付きの新しいメモを作成してください';

  @override
  String get remindersUpcoming => 'これから';

  @override
  String get remindersPast => '過去';

  @override
  String get reminderInPast => '選択した時刻は過去です。未来の時刻を選んでください。';

  @override
  String get newReminder => '新しいリマインダー';

  @override
  String get remindersUntitled => '無題のメモ';

  @override
  String get remindersEdit => '時刻を変更';

  @override
  String get remindersRemove => 'リマインダーを削除';

  @override
  String get aiModelChat => '要約・タイトル・タグ・チャット';

  @override
  String get aiModelDocument => 'ポッドキャストと文書チャット';

  @override
  String get aiModelTranslate => '翻訳';

  @override
  String get aiModelVoice => '音声メモ';

  @override
  String get aiModelAuto => '自動（推奨）';

  @override
  String get aiModelsInfo =>
      '用途ごとに別のモデルを選べます。短い文章なら高速なモデルで十分ですが、長い文書には性能の高いモデルが向いています。選んだモデルが上限に達したり提供終了になった場合は、自動的に次のモデルが試されます。';

  @override
  String get clearNote => '内容を消去';

  @override
  String get clearNoteConfirm => 'メモの内容（テキストとリスト項目）が削除されます。よろしいですか？';

  @override
  String get themePaper => '紙';

  @override
  String get calculatorTitle => '電卓';

  @override
  String get calcExpressionHint => '例: 12.5×3+40';

  @override
  String get calcInvalid => '式が正しくありません';

  @override
  String get liveDictation => '音声入力';

  @override
  String get dictationListening => '聞いています... 話すとテキストが表示されます';

  @override
  String get dictationNoKeyInfo =>
      'この端末ではリアルタイムの音声入力を利用できません。停止したときに録音をまとめて文字起こしします。';

  @override
  String get dictationHoldHint => 'マイクを押しながら話してください。離すとテキストが書き込まれます';

  @override
  String itemsSelected(int count) {
    return '$count 件の項目を選択中';
  }

  @override
  String get noteChatTitle => 'このメモとチャット';

  @override
  String get noteChatHint => 'このメモについて質問してください';

  @override
  String get noteChatIntro => 'メモの内容と添付ファイル（PDF・画像）を読み取り、そこからあなたの質問に答えます。';

  @override
  String get dictationProcessing => '文字起こし中...';

  @override
  String get aiDailyManualInfo =>
      '無料プランでは自動生成されないため、毎日の利用枠を消費しません。下のボタンで 1 日 1 回生成できます。';

  @override
  String get aiGenerate => '生成';

  @override
  String get aiGeneratedTodayInfo =>
      'これは今日生成されたものです。無料プランでは 1 日 1 回更新され、明日また生成できます。';

  @override
  String get voiceAssistantTitle => '音声メモアシスタント';

  @override
  String get voiceListening => '聞いています...';

  @override
  String get voiceHoldHint => '押しながら話してください。離すとメモが作成されます';

  @override
  String get voiceTapHint => 'タップして話し、もう一度タップで終了します';

  @override
  String get voiceTooShort => '録音が短すぎました。もう一度お試しください';

  @override
  String get voiceModeSetting => '動作方式';

  @override
  String get voiceModeHold => '押している間だけ話す';

  @override
  String get voiceModeTap => 'タップで開始／タップで停止';

  @override
  String get voiceModeInfo =>
      '押している間だけ話す: ボタンを押している間は聞き取り、離すとメモを作成します。タップで開始: 1 回目のタップで録音を始め、2 回目のタップで終了します。';

  @override
  String get voiceHeardLive => '音声を検出しました';

  @override
  String get voiceCaptureReady => '録音準備完了';

  @override
  String get voiceCaptureEditHint => 'テキストをタップして編集';

  @override
  String voiceCapturePunctuation(String language) {
    return '$language · 自動句読点';
  }

  @override
  String get voiceCaptureAddToNote => 'ノートに追加';

  @override
  String get voiceCaptureCreateNote => '新規ノートを作成';

  @override
  String get voiceCaptureAiNote => 'AIノート';

  @override
  String get voiceCapturePlainNote => 'そのままメモ';

  @override
  String get voiceCloseTitle => '入力した内容は残っています';

  @override
  String get voiceCloseKeepTalking => '話し続ける';

  @override
  String get voiceCaptureRestart => '再録音';

  @override
  String get voiceChipSummarizeAdd => '要約として追加';

  @override
  String get voiceChipSummarizeSave => '要約として保存';

  @override
  String get voiceChipToItems => '項目に分割';

  @override
  String get voiceChipAsList => 'チェックリストにする';

  @override
  String get voiceChipFix => '整える';

  @override
  String get voiceChipCompose => 'アシスタントに書かせる';

  @override
  String get editorToolList => 'リスト';

  @override
  String get permissionsTitle => '権限';

  @override
  String get permMic => 'マイク';

  @override
  String get permMicInfo => '音声メモと音声入力に必要です';

  @override
  String get permNotifications => '通知';

  @override
  String get permNotificationsInfo => 'リマインダーと今日のまとめに必要です';

  @override
  String get permBattery => 'バッテリー最適化';

  @override
  String get permBatteryInfo => 'リマインダーが時間どおりに届くよう、アプリをバッテリー制限の対象外にします';

  @override
  String get showTagChips => 'タグチップを表示';

  @override
  String get showFolderChips => 'フォルダチップを表示';

  @override
  String videoTooBigForAi(int mb) {
    return '動画が大きすぎて AI に送信できません（$mb MB）。もっと短く録画してください。';
  }

  @override
  String get permCamera => 'カメラ';

  @override
  String get permCameraInfo => '動画メモと写真の撮影に必要です';

  @override
  String get permOnboardTitle => 'はじめる前に';

  @override
  String get permOnboardInfo =>
      'メモは、対応する機能を使うときにだけこれらの権限を求めます。今すぐ下で許可することも、あとで「設定 > 権限」から変更することもできます。';

  @override
  String get permOnboardGrantAll => '権限を許可';

  @override
  String get permOnboardSkip => '今はしない';

  @override
  String get newVideoNote => '動画メモ';

  @override
  String get videoLocalOnly => 'この動画はこの端末にのみ保存されます（クラウドにはアップロードされません）';

  @override
  String get videoToNote => '動画からメモを作る';

  @override
  String get videoToNoteRunning => '動画を確認しています…';

  @override
  String get permGranted => '許可済み';

  @override
  String get permGrant => '許可する';

  @override
  String get permOpenSettings => '設定を開く';

  @override
  String get newHandwriting => '手書き';

  @override
  String get newVoiceCapture => '音声メモ';

  @override
  String get suggestTitle => 'タイトルを提案';

  @override
  String get noteMetaMenu => 'タグ・タイトル・リマインダー';

  @override
  String get folder => 'フォルダ';

  @override
  String get noFolder => 'フォルダなし';

  @override
  String get newFolder => '新しいフォルダ';

  @override
  String get editFolder => 'フォルダを編集';

  @override
  String get deleteFolder => 'フォルダを削除';

  @override
  String deleteFolderConfirm(String name) {
    return 'フォルダ「$name」が削除されます。中のメモは削除されず、フォルダなしになるだけです。';
  }

  @override
  String get folderNameHint => 'フォルダ名';

  @override
  String get folderIcon => 'アイコン';

  @override
  String get editFilters => 'フィルタを編集';

  @override
  String get editFiltersInfo => 'ホーム画面に表示するフィルタを選びます。隠すと画面がすっきりします。';

  @override
  String get select => '選択';

  @override
  String get noteArchived => 'メモをアーカイブしました';

  @override
  String deleteChecked(int count) {
    return 'チェック済みを削除 ($count)';
  }

  @override
  String get removeItem => '項目を削除';

  @override
  String get copyWholeNote => 'メモ全体をコピー';

  @override
  String get allCopied => 'メモ全体をクリップボードにコピーしました';

  @override
  String get speechPlay => '読み上げる';

  @override
  String get speechPause => '一時停止';

  @override
  String get speechResume => '再開';

  @override
  String get speechStop => '停止';

  @override
  String get speechRate => '読み上げ速度';

  @override
  String get speechSystemDefault => 'システムの既定';

  @override
  String get speechNoVoices => 'この端末には音声がインストールされていません';

  @override
  String speechVoiceLanguage(String language) {
    return '$language の音声';
  }

  @override
  String get speechVoiceAutoInfo => '他の言語は自動的に男性の声で読み上げられます';

  @override
  String get listening => '聞いています...';

  @override
  String get listenPlay => '聞く';

  @override
  String get listenReadingPdf => '文書を読み込んでいます...';

  @override
  String get listenConvertWithAi => 'AI で変換';

  @override
  String get listenMakePodcast => 'フルポッドキャスト';

  @override
  String get listenMakePodcastSummary => '要約ポッドキャスト';

  @override
  String get listenOriginalText => '元のテキスト';

  @override
  String get listenPodcastReady => 'ポッドキャストの音声が準備できました';

  @override
  String get listenPodcastCached => '以前に生成済み — トークンは消費していません';

  @override
  String get listenRegenerate => 'もう一度生成';

  @override
  String get listenNoText =>
      'この文書から読み取れるテキストはありませんでした。スキャンした PDF にはテキスト層がなく、プレゼンテーションは画像だけの場合があります。';

  @override
  String get readDocument => '文書を読む（Word・PDF・スライド）';

  @override
  String get readDocUnsupported => 'この種類のファイルは読み取れません。';

  @override
  String get exportPdf => 'PDF として書き出す';

  @override
  String get pdfTitleField => 'タイトル';

  @override
  String get pdfContentField => '内容';

  @override
  String get pdfMarkupHint =>
      '行頭の記号は書式になります: [x] と [ ] はチェックボックス、1. は番号付きリスト、- は箇条書きです。';

  @override
  String get pdfIncludeDate => '日付を含める';

  @override
  String get exportIncludeImages => '画像を含める';

  @override
  String get exportWord => 'Word (.docx) として共有';

  @override
  String get pdfPreview => 'プレビュー';

  @override
  String get largeAttachmentTitle => '大きなファイル';

  @override
  String largeAttachmentBody(String size) {
    return 'このファイルは $size MB です。PDF は圧縮できないため、そのままアップロードされ、保存容量に加算されます。続行しますか？';
  }

  @override
  String get speechRateForeign => '外国語の速度';

  @override
  String notesArchivedCount(int count) {
    return '$count 件のメモをアーカイブしました';
  }

  @override
  String get backgroundColor => '背景色';

  @override
  String get backgroundColorInfo => 'メモの背景色';

  @override
  String get frameColor => '枠';

  @override
  String get frameColorInfo => '選んだ色でメモのまわりに枠を描きます';

  @override
  String get sortBy => '並べ替え';

  @override
  String get reorderNotes => 'メモを並べ替える';

  @override
  String get reorderModeActive => 'カードをドラッグして並べ替えてください';

  @override
  String get reorderDone => '完了';

  @override
  String get sortManual => '手動（ドラッグした順）';

  @override
  String get sortUpdated => '最近更新した順';

  @override
  String get sortCreated => '作成日';

  @override
  String get sortTitle => 'タイトル順 (A–Z)';

  @override
  String get foldersSection => 'フォルダ';

  @override
  String get tagsSection => 'タグ';

  @override
  String get expandFilters => 'フィルタを広げる';

  @override
  String get collapseFilters => 'フィルタを畳む';

  @override
  String get settingsLanguage => '言語';

  @override
  String get languageSystem => 'システムの言語';

  @override
  String get settingsSpeech => '読み上げ';

  @override
  String get aiAdvanced => '詳細設定: モデルと API キー';

  @override
  String get aiAdvancedInfo => 'モデルの選択と、自分の Gemini キー。ほとんどの方には必要ありません。';

  @override
  String get openBriefing => 'まとめを開く';

  @override
  String get syncTitle => '同期';

  @override
  String get syncLimitTitle => '自動アップロードの上限';

  @override
  String get syncLimitInfo =>
      'この上限より大きい添付ファイルは端末に残り、アップロードされません。メモの本文は常に同期されます。';

  @override
  String get syncLimitUnlimited => '上限なし';

  @override
  String get backupTitle => 'バックアップ';

  @override
  String get importBackup => 'バックアップから復元 (JSON)';

  @override
  String importBackupDone(int count) {
    return '$count 件のメモを復元しました';
  }

  @override
  String get importBackupInvalid => 'バックアップファイルが正しくありません';

  @override
  String get aiHubTitle => 'AI';

  @override
  String get aiSummarizeInfo => '短い要約を作ります';

  @override
  String get aiAnalyzeInfo => '要点とやることを一覧にします';

  @override
  String get aiImproveInfo => '文体を変えます: 硬め・短め・リスト';

  @override
  String get aiTranslateInfo => '選んだ言語にノートを翻訳します';

  @override
  String get aiFixNoteInfo => 'つづりと句読点を直します';

  @override
  String get moveToFolder => 'フォルダへ移動';

  @override
  String get voiceAssistantBadge => 'アシスタント';

  @override
  String get assistantGenericError => '問題が発生しました。もう一度お試しいただけますか？';

  @override
  String get quickAddTooltip => '新しいメモ — 種類を選択';

  @override
  String get autoTitleSetting => '閉じるときにタイトルを提案';

  @override
  String get autoTitleSettingInfo =>
      'エディタを離れるとき、タイトルのないメモには内容から書き起こした短いタイトルが付きます。';

  @override
  String get hubChatInfo => 'あなたのメモから答えます';

  @override
  String get hubBriefingInfo => '今日をひと目で: リマインダーと最近のメモ';

  @override
  String get hubReadInfo => 'PDF や Word 文書を聞く';

  @override
  String get annotate => '書き込む';

  @override
  String get annotateDone => '書き込みを終了';

  @override
  String get newPdfNote => 'PDF ekle not al';

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
  String get crop => '切り抜き';

  @override
  String get cropApply => '切り抜きを適用';

  @override
  String get cropReset => '選択をリセット';

  @override
  String get cropHint => '角をドラッグして範囲を選んでください。切り抜きは元に戻せません。';

  @override
  String get cropFailed => '画像を切り抜けませんでした。';

  @override
  String get penBallpoint => 'ボールペン';

  @override
  String get penMarker => 'マーカー';

  @override
  String get penHighlighter => '蛍光ペン';

  @override
  String get eraser => '消しゴム';

  @override
  String get clearInk => '書き込みを消去';

  @override
  String get inkTwoFingerHint => '1 本指で描く・2 本指で移動と拡大縮小';

  @override
  String get slideOpenFailed => 'プレゼンテーションを開けませんでした';

  @override
  String get newPhotoNote => '写真メモ';

  @override
  String get newScanNote => '書類をスキャン';

  @override
  String get scanDocument => '書類をスキャン';

  @override
  String get scanDocumentSubtitle => '端を検出してページを平らに補正し、追加します';

  @override
  String get scanUnsupported => 'この端末では書類のスキャンに対応していません';

  @override
  String scanFailed(String error) {
    return '書類をスキャンできませんでした: $error';
  }

  @override
  String scanPagesAdded(int count) {
    return '$count ページをメモに追加しました';
  }

  @override
  String get scanTextTitle => 'テキストも認識しますか？';

  @override
  String get scanTextBody =>
      'ページ上のテキストを認識してメモに書き込みます。画像はそのまま残ります。1 ページあたり数秒かかります。';

  @override
  String get scanImageOnly => '画像のみ';

  @override
  String get scanRecognizeText => 'テキストを認識';

  @override
  String get scanRecognizing => 'テキストを認識しています…';

  @override
  String get takePhoto => '写真を撮る';

  @override
  String get qrScanTitle => 'QR コードをスキャン';

  @override
  String get qrScanSubtitle => 'カメラで読み取るか、写真から読み取ります';

  @override
  String get qrScanHint => 'コードを枠の中に合わせてください';

  @override
  String get qrFromPhoto => '写真から読み取る';

  @override
  String get qrNotFound => 'この画像にコードは見つかりませんでした';

  @override
  String get qrLinkFound => 'このコードはリンクです';

  @override
  String get qrOpenLink => 'リンクを開く';

  @override
  String get qrSaveToNote => 'メモに保存';

  @override
  String get openLink => 'リンクを開く';

  @override
  String get linkOpenFailed => 'リンクを開けませんでした';

  @override
  String qrScanFailed(String error) {
    return 'コードを読み取れませんでした: $error';
  }

  @override
  String get qrTorch => 'ライト';

  @override
  String attachmentsCount(int count) {
    return '添付ファイル ($count)';
  }

  @override
  String get hideAttachments => '隠す';

  @override
  String get showAttachments => '表示';

  @override
  String get videoBack10 => '10 秒戻る';

  @override
  String get videoForward10 => '10 秒進む';

  @override
  String get selectAllItems => 'すべて選択';

  @override
  String get showAllChips => 'すべて表示';

  @override
  String get hideAllChips => 'すべて隠す';

  @override
  String get chipPickInfo => 'ホーム画面にどのフォルダとタグのチップを表示しますか？';

  @override
  String get hiddenFolder => '非表示フォルダ';

  @override
  String get hiddenFolderInfo =>
      '非表示フォルダとその中のメモはホーム画面に表示されません。表示するには ⋮ メニューから「非表示フォルダ」を選び、本人確認をしてください。';

  @override
  String get hiddenFoldersMenu => '非表示フォルダ';

  @override
  String get hiddenFolderAuthReason => '非表示フォルダを表示するには本人確認をしてください';

  @override
  String get hiddenFoldersShown => '非表示フォルダを表示しています';

  @override
  String get hiddenFoldersHiddenAgain => '非表示フォルダを再び隠しました';

  @override
  String get makeFolderHidden => '隠す';

  @override
  String get makeFolderVisible => '表示する';

  @override
  String gridColumnsCount(int count) {
    return '$count 列';
  }

  @override
  String get addImageOnPageSubtitle => 'ページ上に配置され、テキストが回り込みます';

  @override
  String get addImageAsFile => '画像をファイルとして追加';

  @override
  String get addImageAsFileSubtitle => 'ページの外、添付ファイル欄に残ります';

  @override
  String get moveImageToAttachments => '添付ファイルへ移動';

  @override
  String get moveImageToPage => 'ページ上に配置';

  @override
  String get attachmentCopied => '添付ファイルをコピーしました';

  @override
  String get pasteAttachment => 'コピーした添付ファイルを貼り付け';

  @override
  String get fullscreen => '全画面';

  @override
  String get more => 'その他';

  @override
  String get undone => '元に戻しました';

  @override
  String get filterOthers => 'その他';

  @override
  String get chatSuggestion1 => '買い物リストに何が足りない？';

  @override
  String get chatSuggestion2 => '今週の作業メモを要約して';

  @override
  String get chatSuggestion3 => '明日リマインダーはある？';

  @override
  String get aiPointsToday => '今日のポイント';

  @override
  String aiPointsOf(int used, int total) {
    return '$used / $total';
  }

  @override
  String get aiPointsRenew => '深夜に更新';

  @override
  String get aiChatWithNotes => 'ノートアシスタント';

  @override
  String get aiChatInputHint => 'ノートについて聞く…';

  @override
  String get aiChatLooking => 'ノートを確認中…';

  @override
  String get aiChatFullScreen => '全画面表示';

  @override
  String get aiOnYourNotes => 'ノートを活用';

  @override
  String get aiTaskDuplicates => '重複を整理';

  @override
  String aiTaskDuplicatesInfo(int count) {
    return '重複したメモが $count 件';
  }

  @override
  String get duplicatesTitle => '重複したメモ';

  @override
  String get duplicatesHint => '各グループで最も古いメモが残り、ほかはゴミ箱に移動します。';

  @override
  String get duplicatesKeepBadge => '残す';

  @override
  String get duplicatesDeleteAll => '重複をゴミ箱へ移動';

  @override
  String duplicatesDone(int count) {
    return '$count 件の重複をゴミ箱に移動しました';
  }

  @override
  String get aiRecentActions => '最近の操作';

  @override
  String get aiHistoryClear => '消去';

  @override
  String get aiHistoryQuestion => '質問';

  @override
  String get aiHistoryNoteAction => 'メモの操作';

  @override
  String get aiHistoryVoiceNote => '音声メモ';

  @override
  String get aiRecentOps => '最近の操作';

  @override
  String get aiTaskWeekSummary => '今週を要約';

  @override
  String get aiTaskWeekSummaryInfo => '過去7日間の要約を作成';

  @override
  String get aiTaskTagUntagged => 'タグ付け';

  @override
  String aiTaskTagUntaggedInfo(int count) {
    return '$count 件のノートがタグ待ち';
  }

  @override
  String get aiTaskSuggestTitles => 'タイトルを提案';

  @override
  String aiTaskSuggestTitlesInfo(int count) {
    return '$count 件のノートにタイトルがありません';
  }

  @override
  String get sectionPinnedShort => 'ピン留め';

  @override
  String get sectionToday => '今日';

  @override
  String get sectionThisWeek => '今週';

  @override
  String get sectionEarlier => '過去';

  @override
  String sectionNoteCount(int count) {
    return '$count 件のノート';
  }

  @override
  String get emptySearchSemanticHint => '「意味」タブを試す';

  @override
  String get quickCaptureHint => '新しいノート…';

  @override
  String get quickCaptureSave => '保存';

  @override
  String get quickAddWrite => '書く';

  @override
  String get quickAddCapture => 'キャプチャ — コンテンツからノートを作成';

  @override
  String get viewToggle => '表示';

  @override
  String get searchModeText => 'テキスト';

  @override
  String get searchModeMeaning => '意味';

  @override
  String get filterReminded => 'リマインダー付き';

  @override
  String get filterLocked => 'ロック済み';

  @override
  String get sortColor => '色';

  @override
  String get filterSheetTitle => 'フィルタ';

  @override
  String get filterReset => 'リセット';

  @override
  String get filterSectionStatus => 'ステータス';

  @override
  String get filterSectionFolder => 'フォルダー';

  @override
  String get filterSectionTag => 'タグ';

  @override
  String get filterSectionSort => '並び替え';

  @override
  String get filterFavoriteHint => '星をタップするとホーム画面に残ります';

  @override
  String get filterSheetSortHint => '日付順で並び替えるときのみ、日付グループ（今日、今週…）が表示されます。';

  @override
  String get formatTitle => '書式';

  @override
  String get formatBold => '太字';

  @override
  String get formatItalic => '斜体';

  @override
  String get formatUnderline => '下線';

  @override
  String get formatTextColor => '文字色';

  @override
  String get formatHighlight => 'ハイライト';

  @override
  String get formatInfo =>
      '書式は本文の中に記号として保存されます（**太字** など）。書き出しや読み上げでは記号は表示されません。';

  @override
  String get formatMenu => '書式…';

  @override
  String get noteFont => 'フォント';

  @override
  String get noteFontDefault => '既定';

  @override
  String get noteFontSerif => '明朝（セリフ）';

  @override
  String get noteFontMono => 'タイプライター';

  @override
  String get noteTextSize => '文字サイズ';

  @override
  String get formatClear => '書式を消去';

  @override
  String get noteTextOpacity => '不透明度';

  @override
  String get assistantVoiceSetting => 'アシスタントが返答を読み上げる';

  @override
  String get assistantVoiceSettingInfo => '音声アシスタントが返答を声に出して読み上げます（スマートフォンのみ）。';

  @override
  String get assistantMute => 'ミュート';

  @override
  String get assistantUnmute => 'ミュート解除';

  @override
  String get assistantMakeNote => 'それでもメモにする';

  @override
  String get assistantNoteCreated => 'メモを作成しました';

  @override
  String get noteNotFound => 'メモが見つかりません。削除された可能性があります。';

  @override
  String get back => '戻る';

  @override
  String get addTextBlock => 'テキストを追加';

  @override
  String get attachNoteContent => 'Not içeriği';

  @override
  String get noteBackgroundImage => '背景画像';

  @override
  String get chooseBackgroundImage => '画像を選ぶ';

  @override
  String get changeBackgroundImage => '画像を変更';

  @override
  String get removeBackgroundImage => '背景を削除';

  @override
  String get dashboardBackground => 'ホーム画面の背景';

  @override
  String get dashboardBackgroundInfo => 'メモの一覧の背後に表示される画像です（この端末のみ）。';

  @override
  String get aiProvider => 'AI プロバイダ';

  @override
  String get aiProviderInfo =>
      'お持ちのキーが属するプロバイダを選んでください。プロバイダごとにキーは個別に保存されるため、元に戻しても入力し直す必要はありません。';

  @override
  String get apiKeyFieldLabel => 'API キー';

  @override
  String get getApiKey => 'キーはどこで入手できますか？';

  @override
  String get recommendedModel => 'おすすめ';

  @override
  String get freeTierBadge => '無料枠あり';

  @override
  String get continueWithoutAccount => 'アカウントなしで続ける';

  @override
  String get localAccountInfo =>
      'メモはこの端末にのみ保存されます。他の端末では開けず、アプリを削除すると失われ、内蔵 AI は無効です。Google アカウントはいつでも連携でき、その際メモはそのまま引き継がれます。';

  @override
  String get localAccountBadge => 'ローカルアカウント';

  @override
  String get linkGoogleAccount => 'Google アカウントを連携';

  @override
  String get accountLinked => 'Google アカウントを連携しました。これでメモはバックアップされます。';

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
      'Google なしのログインは現在オフです: Firebase コンソールで匿名ログインが有効になっていません。Google でログインするか、管理者が有効にしてからもう一度お試しください。';

  @override
  String get googleSignInUnavailable =>
      'Google ログインは現在オフです: Firebase コンソールで Google プロバイダが有効になっていません。';

  @override
  String get signInNetworkError => 'インターネットに接続できませんでした。接続を確認してもう一度お試しください。';

  @override
  String get signInCanceled => 'ログインをキャンセルしました。';

  @override
  String get cardRichPreview => 'カードに書式付きテキストを表示';

  @override
  String get cardRichPreviewInfo =>
      'メモの色・ハイライト・太字・下線がホーム画面のカードにも表示されます。オフにするとカードはプレーンテキストになります。';

  @override
  String get fontSizeSmall => '小';

  @override
  String get fontSizeMedium => '中';

  @override
  String get fontSizeLarge => '大';

  @override
  String get fontSizeXLarge => '特大';

  @override
  String get appFontSetting => 'フォント';

  @override
  String get appFontInfo =>
      'アプリ全体で使うフォントです。メモごとのフォント指定が優先されます。すべてのフォントはアプリに同梱されており、インターネットは不要です。';

  @override
  String get fontGroupSans => 'ゴシック体';

  @override
  String get fontGroupSerif => '明朝体';

  @override
  String get fontGroupMono => '等幅';

  @override
  String get fontGroupHand => '手書き風';

  @override
  String get appFontDefaultSuffix => '既定';

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
  String get shareAsText => 'プレーンテキストとして';

  @override
  String get shareAsTextInfo => 'メモの本文とページメモを任意のアプリへ送ります。';

  @override
  String get shareAsTextEmpty => 'このメモには共有できるテキストがありません。';

  @override
  String get sharePdfWithBubbles => '吹き出し入りPDFとして';

  @override
  String get sharePdfWithBubblesInfo => '吹き出し・ハイライト・手書きがPDFに焼き込まれます。相手にNotアプリは不要です。';

  @override
  String get sharePdfWithBubblesNone => 'このメモには吹き出しや手書きのあるPDFがありません。';

  @override
  String get sharePdfWithBubblesPreparing => '吹き出し入りPDFを準備しています…';

  @override
  String get sharePdfWithBubblesSuffix => '（吹き出し入り）';

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
}
