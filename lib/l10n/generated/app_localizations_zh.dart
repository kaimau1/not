// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => '笔记';

  @override
  String get loginTagline => '你的笔记，随身跨设备';

  @override
  String get signInWithGoogle => '使用 Google 登录';

  @override
  String loginError(String error) {
    return '登录失败：$error';
  }

  @override
  String get searchHint => '搜索笔记...';

  @override
  String get filterAll => '全部';

  @override
  String get filterText => '文本';

  @override
  String get filterChecklist => '清单';

  @override
  String get filterOrdered => '编号';

  @override
  String get filterPinned => '已置顶';

  @override
  String get filterStarred => '已加星标';

  @override
  String get star => '加星标';

  @override
  String get unstar => '取消星标';

  @override
  String editedAt(String date) {
    return '编辑于：$date';
  }

  @override
  String get sectionPinned => '已置顶';

  @override
  String get sectionOthers => '其他';

  @override
  String get emptyNotes => '还没有笔记';

  @override
  String get emptyNotesHint => '点按 + 创建第一条笔记';

  @override
  String get emptySearch => '没有找到结果';

  @override
  String get newTextNote => '文本笔记';

  @override
  String get newChecklist => '清单';

  @override
  String get newOrderedList => '编号清单';

  @override
  String get noteDeleted => '已删除笔记';

  @override
  String notesDeletedCount(int count) {
    return '已删除 $count 条笔记';
  }

  @override
  String selectedCount(int count) {
    return '已选择 $count 条';
  }

  @override
  String get deleteSelected => '删除所选';

  @override
  String get undo => '撤销';

  @override
  String get redo => '重做';

  @override
  String get titleHint => '标题';

  @override
  String get bodyHint => '笔记...';

  @override
  String get newItemHint => '新条目';

  @override
  String moreItemsCount(int count) {
    return '还有 $count 个条目';
  }

  @override
  String get addAttachment => '添加';

  @override
  String get addAttachmentMore => '更多附件类型…';

  @override
  String get addImage => '添加图片';

  @override
  String get addPdf => '添加 PDF';

  @override
  String get addSlide => '添加幻灯片';

  @override
  String get pasteImage => '从剪贴板粘贴图片';

  @override
  String get clipboardEmpty => '剪贴板里没有图片';

  @override
  String get noNoteSelected => '请从左侧选择一条笔记';

  @override
  String attachmentFailed(String error) {
    return '无法添加附件：$error';
  }

  @override
  String get attachmentUploading => '正在上传...';

  @override
  String get attachmentUploadFailed =>
      'Yüklenemedi — yeniden denemek için dokun';

  @override
  String get attachmentNotSynced => '该文件尚未同步到此设备';

  @override
  String attachmentTooLarge(int limit) {
    return '文件太大（最多 $limit MB）';
  }

  @override
  String storageFull(String limit) {
    return '存储空间已满（$limit）。请删除旧附件以释放空间。';
  }

  @override
  String get storageUsage => '存储空间';

  @override
  String storageUsageValue(String used, String limit) {
    return '已使用 $used/$limit';
  }

  @override
  String get removeAttachment => '删除附件';

  @override
  String get pin => '置顶';

  @override
  String get unpin => '取消置顶';

  @override
  String get delete => '删除';

  @override
  String get color => '颜色';

  @override
  String get aiTitle => 'AI';

  @override
  String get aiSummarize => '总结笔记';

  @override
  String get aiAnalyze => '分析';

  @override
  String get aiSectionNote => '这条笔记';

  @override
  String get aiSectionAttachments => '附件';

  @override
  String get summarize => '生成摘要';

  @override
  String get summaryDetailTitle => '摘要类型';

  @override
  String get summaryShort => '简短摘要';

  @override
  String get summaryShortInfo => '几句话的概览加上要点';

  @override
  String get summaryDetailed => '详细摘要';

  @override
  String get summaryDetailedInfo => '足够完整，不必再打开原文';

  @override
  String get listen => '收听';

  @override
  String get ask => '提问';

  @override
  String get extractText => '提取文字';

  @override
  String get transcribe => '转成文字';

  @override
  String get listenToNote => '朗读';

  @override
  String get aiNoApiKey => '请先在设置中输入你的 Gemini API 密钥';

  @override
  String aiError(String error) {
    return 'AI 请求失败：$error';
  }

  @override
  String get aiSummaryTitle => 'AI 摘要';

  @override
  String get aiThinking => '思考中...';

  @override
  String get copy => '复制';

  @override
  String get copied => '已复制';

  @override
  String get settingsSearchHint => '搜索设置 — “简报”, “麦克风”';

  @override
  String settingsSearchEmpty(String query) {
    return '没有匹配“$query”的设置';
  }

  @override
  String get settings => '设置';

  @override
  String get settingsAppearance => '外观';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get settingsAi => 'AI';

  @override
  String get geminiApiKey => 'Gemini API 密钥';

  @override
  String get geminiApiKeyHint => '粘贴以 AIza... 开头的密钥';

  @override
  String get geminiApiKeyInfo =>
      '密钥是可选的：没有密钥时，AI 请求会走应用内置的服务（每天有免费额度，Premium 更多）。若想用自己的密钥无限使用，可在 aistudio.google.com 免费获取；密钥只保存在本设备的安全存储中。';

  @override
  String aiBuiltInPremium(int count) {
    return '内置 AI：Premium — 今日剩余 $count 点';
  }

  @override
  String aiBuiltInRemaining(int count) {
    return '内置 AI：今日剩余 $count 点免费额度';
  }

  @override
  String get aiBuiltInByok => '使用你自己的密钥 — 无限制';

  @override
  String get aiReport => '举报这条回答';

  @override
  String get aiReportThanks => '已收到反馈，谢谢';

  @override
  String get privacyPolicyTitle => '隐私政策';

  @override
  String get lockNote => '锁定';

  @override
  String get unlockNote => '解锁';

  @override
  String get lockedNote => '已锁定的笔记';

  @override
  String get unlockAuthReason => '请验证身份以打开已锁定的笔记';

  @override
  String get exportBackup => '导出备份 (JSON)';

  @override
  String get expandListItems => '完整显示清单行';

  @override
  String get expandListItemsInfo => '较长的条目会折行显示并始终完整可见。关闭后，每行只占一行，点按才展开。';

  @override
  String get quickCaptureRowSetting => '快速笔记栏';

  @override
  String get quickCaptureRowInfo => '在主屏幕顶部显示单行\"新建笔记...\"输入框。关闭时请使用 + 按钮。';

  @override
  String get emptyTrash => '清空回收站';

  @override
  String emptyTrashConfirm(int count) {
    return '$count 条笔记将被永久删除，且无法撤销。确定吗？';
  }

  @override
  String get trashEmptied => '已清空回收站';

  @override
  String get validateAndSave => '验证并保存';

  @override
  String get clear => '清除';

  @override
  String get aiDiagnostics => 'AI 诊断';

  @override
  String get aiDiagnosticsEmpty => '没有记录到错误';

  @override
  String aiDiagnosticsCount(int count) {
    return '最近 $count 条错误记录';
  }

  @override
  String get apiKeyValid => 'API 密钥已验证并保存';

  @override
  String get apiKeyInvalid => 'API 密钥无效';

  @override
  String get apiKeySavedBadge => '已保存';

  @override
  String get removeApiKey => '删除密钥';

  @override
  String get refresh => '刷新';

  @override
  String get account => '账号';

  @override
  String get signOut => '退出登录';

  @override
  String get signOutConfirm => '确定要退出登录吗？';

  @override
  String get signOutAnonymousWarning =>
      '你正在使用本地账号：退出后此账号及其全部笔记将永久无法访问——没有备份就无法恢复。请先绑定 Google 账号。仍要退出吗？';

  @override
  String get deleteAccount => '删除我的账号和数据';

  @override
  String get deleteAccountWarning => '此操作无法撤销：你的所有笔记、附件和账号都将被永久删除。要继续吗？';

  @override
  String get deleteAccountConfirm => '永久删除';

  @override
  String get licensesTitle => '开源许可';

  @override
  String get generating => '生成中...';

  @override
  String get retry => '重试';

  @override
  String get cancel => '取消';

  @override
  String get close => '关闭';

  @override
  String get ok => '确定';

  @override
  String get syncPending => '等待同步';

  @override
  String get synced => '已同步';

  @override
  String genericError(String error) {
    return '出了点问题：$error';
  }

  @override
  String get addTag => '标签';

  @override
  String get tagHint => '例如：工作、家里、学校';

  @override
  String get addReminder => '提醒我';

  @override
  String get share => '分享';

  @override
  String get archive => '归档';

  @override
  String get unarchive => '取消归档';

  @override
  String get archiveTitle => '归档';

  @override
  String get archiveEmpty => '归档里没有笔记';

  @override
  String get trashTitle => '回收站';

  @override
  String get trashEmpty => '回收站是空的';

  @override
  String get trashInfo => '删除的笔记会留在这里，你可以恢复它们，也可以彻底删除。';

  @override
  String get restore => '恢复';

  @override
  String get deleteForever => '永久删除';

  @override
  String get deleteForeverConfirm => '这条笔记将被永久删除。确定吗？';

  @override
  String assistantDeleteConfirm(String title) {
    return 'Asistan \"$title\" notunu çöp kutusuna taşımak istiyor. Onaylıyor musun?';
  }

  @override
  String get recordAudio => '语音录制';

  @override
  String get recording => '录音中...';

  @override
  String get stopAndSave => '完成并添加';

  @override
  String get micPermissionDenied => '麦克风权限被拒绝';

  @override
  String get speechRecognitionFailed =>
      '语音识别没有成功。请检查是否已授予麦克风权限，以及 Google 应用是否为最新版本。';

  @override
  String get addDrawing => '添加手绘';

  @override
  String get drawingTitle => '手绘';

  @override
  String get addToNote => '添加到笔记';

  @override
  String get chatTitle => '笔记助手';

  @override
  String get chatHint => '问问你的笔记：「上周写的那个菜谱是什么？」「购物清单里还缺什么？」';

  @override
  String get chatInputHint => '输入问题...';

  @override
  String get fontSize => '文字大小';

  @override
  String get fontSizePreview => '你的笔记会是这个样子';

  @override
  String get darkSchedule => '深色主题时间表';

  @override
  String get darkScheduleInfo => '在你设定的时间段内切换到深色主题';

  @override
  String get aiTranslate => '翻译';

  @override
  String get voiceCommand => '语音指令';

  @override
  String get semanticSearchToggle => '用 AI 按语义搜索';

  @override
  String get semanticSearchHint => '按含义搜索：「养车开销」...';

  @override
  String get briefingTitle => '每日简报';

  @override
  String get briefingLoading => '正在准备你的简报...';

  @override
  String get briefingEmpty => '今天没有内容';

  @override
  String get briefingSetting => '每日简报通知';

  @override
  String get briefingSettingInfo => '每天早上在你选定的时间收到当天摘要的通知';

  @override
  String get autoTagSetting => '自动添加标签';

  @override
  String get autoTagSettingInfo => '笔记未加标签就关闭时，AI 会补上一个合适的标签';

  @override
  String get suggestTags => '推荐标签';

  @override
  String get aiFixNote => '整理笔记';

  @override
  String get fixLevelTitle => '整理到什么程度？';

  @override
  String get fixSimple => '轻度';

  @override
  String get fixSimpleInfo => '只改错别字和输入错误';

  @override
  String get fixBalanced => '适中';

  @override
  String get fixBalancedInfo => '连句子结构一起调整，让行文更干净';

  @override
  String get fixDetailed => '彻底';

  @override
  String get fixDetailedInfo => '从头到尾重写整篇文字';

  @override
  String get existingTagsLabel => '以前用过的标签';

  @override
  String get aiSkipCheckedSetting => 'AI 编辑时跳过已勾选的条目';

  @override
  String get aiSkipCheckedInfo => 'AI 整理或翻译清单时，已完成（已勾选）的条目原样保留，只修改未勾选的条目。';

  @override
  String get noteUpdatedUndo => '笔记已更新';

  @override
  String get aiImprove => '改进笔记';

  @override
  String get improveFormal => '改得更正式';

  @override
  String get improveShorten => '缩短';

  @override
  String get improveBullets => '改成要点清单';

  @override
  String get improveNumbered => '改成编号清单';

  @override
  String get replaceNote => '替换笔记';

  @override
  String get openAsNewNote => '作为新笔记';

  @override
  String get pdfChatHint => '问问这份 PDF：「帮我总结」「有违约金条款吗？」「截止日期是什么时候？」';

  @override
  String get pdfChatInputHint => '输入关于这份 PDF 的问题...';

  @override
  String get voiceCaptureHint => '说出来：「买牛奶和面包」或「明天九点开会，提醒我」— 你说完后 AI 会写好笔记。';

  @override
  String get voiceFinish => '完成';

  @override
  String get voiceProcessing => '正在处理你说的内容...';

  @override
  String get voiceNothingHeard => '录音里没有检测到说话声';

  @override
  String get voiceNoteSaved => '已保存你的语音笔记';

  @override
  String get openNote => '打开笔记';

  @override
  String get remindersTitle => '提醒';

  @override
  String get remindersEmpty => '没有提醒';

  @override
  String get remindersEmptyHint => '给某条笔记添加提醒，或用 + 按钮新建一条带提醒的笔记';

  @override
  String get remindersUpcoming => '即将到来';

  @override
  String get remindersPast => '已过去';

  @override
  String get reminderInPast => '所选时间已过去——请选择未来的时间。';

  @override
  String get newReminder => '新建提醒';

  @override
  String get remindersUntitled => '无标题笔记';

  @override
  String get remindersEdit => '更改时间';

  @override
  String get remindersRemove => '删除提醒';

  @override
  String get aiModelChat => '摘要、标题、标签和对话';

  @override
  String get aiModelDocument => '播客与文档对话';

  @override
  String get aiModelTranslate => '翻译';

  @override
  String get aiModelVoice => '语音笔记';

  @override
  String get aiModelAuto => '自动（推荐）';

  @override
  String get aiModelsInfo =>
      '你可以为每类任务分别选择模型：短文本用快速模型就够了，长文档则需要更强的模型。如果所选模型用完额度或被下线，会自动尝试下一个。';

  @override
  String get clearNote => '清空';

  @override
  String get clearNoteConfirm => '笔记的内容（文字和清单条目）将被删除。确定吗？';

  @override
  String get themePaper => '纸张';

  @override
  String get calculatorTitle => '计算器';

  @override
  String get calcExpressionHint => '例如 12.5×3+40';

  @override
  String get calcInvalid => '表达式无效';

  @override
  String get liveDictation => '语音输入';

  @override
  String get dictationListening => '正在聆听... 边说边出字';

  @override
  String get dictationNoKeyInfo => '此设备不支持实时语音输入；停止后会把录音一次性转成文字。';

  @override
  String get dictationHoldHint => '按住麦克风说话，松手后写入文字';

  @override
  String itemsSelected(int count) {
    return '已选择 $count 个条目';
  }

  @override
  String get noteChatTitle => '与这条笔记对话';

  @override
  String get noteChatHint => '问问关于这条笔记的事';

  @override
  String get noteChatIntro => '系统会读取笔记内容及其附件（PDF/图片），并据此回答你的问题。';

  @override
  String get dictationProcessing => '正在转写...';

  @override
  String get aiDailyManualInfo => '免费方案下不会自动生成，因此不会消耗你的每日额度。你可以用下面的按钮每天生成一次。';

  @override
  String get aiGenerate => '生成';

  @override
  String get aiGeneratedTodayInfo => '这是今天生成的。免费方案下每天更新一次，明天可以再生成。';

  @override
  String get voiceAssistantTitle => '语音笔记助手';

  @override
  String get voiceListening => '正在聆听...';

  @override
  String get voiceHoldHint => '按住说话，松手后生成笔记';

  @override
  String get voiceTapHint => '点一下开始说，再点一下结束';

  @override
  String get voiceTooShort => '这段录音太短了，请再试一次';

  @override
  String get voiceModeSetting => '工作方式';

  @override
  String get voiceModeHold => '按住说话';

  @override
  String get voiceModeTap => '点按开始 / 点按停止';

  @override
  String get voiceModeInfo => '按住说话：按住按钮期间持续聆听，松手后生成笔记。点按开始：点一下开始录音，再点一下结束。';

  @override
  String get voiceHeardLive => '检测到说话声';

  @override
  String get voiceCaptureReady => '语音已就绪';

  @override
  String get voiceCaptureEditHint => '点击文本进行编辑';

  @override
  String voiceCapturePunctuation(String language) {
    return '$language · 自动标点';
  }

  @override
  String get voiceCaptureAddToNote => '添加到笔记';

  @override
  String get voiceCaptureCreateNote => '创建新笔记';

  @override
  String get voiceCaptureAiNote => 'AI 笔记';

  @override
  String get voiceCapturePlainNote => '普通笔记';

  @override
  String get voiceCloseTitle => '你的口述内容还在';

  @override
  String get voiceCloseKeepTalking => '继续说';

  @override
  String get voiceCaptureRestart => '重新录音';

  @override
  String get voiceChipSummarizeAdd => '添加为摘要';

  @override
  String get voiceChipSummarizeSave => '保存为摘要';

  @override
  String get voiceChipToItems => '拆分为条目';

  @override
  String get voiceChipAsList => '转为清单';

  @override
  String get voiceChipFix => '整理内容';

  @override
  String get voiceChipCompose => '让助手来写';

  @override
  String get editorToolList => '列表';

  @override
  String get permissionsTitle => '权限';

  @override
  String get permMic => '麦克风';

  @override
  String get permMicInfo => '语音笔记和语音输入需要';

  @override
  String get permNotifications => '通知';

  @override
  String get permNotificationsInfo => '提醒和每日简报需要';

  @override
  String get permBattery => '电池优化';

  @override
  String get permBatteryInfo => '把应用排除在电池限制之外，让提醒准时送达';

  @override
  String get showTagChips => '显示标签标记';

  @override
  String get showFolderChips => '显示文件夹标记';

  @override
  String videoTooBigForAi(int mb) {
    return '视频太大，无法发送给 AI（$mb MB）。请录制更短的视频。';
  }

  @override
  String get permCamera => '相机';

  @override
  String get permCameraInfo => '视频笔记和拍照需要';

  @override
  String get permOnboardTitle => '开始之前';

  @override
  String get permOnboardInfo =>
      '只有在你使用对应功能时，笔记才会申请这些权限。你可以现在在下面授予，也可以稍后在「设置 > 权限」中更改。';

  @override
  String get permOnboardGrantAll => '授予权限';

  @override
  String get permOnboardSkip => '暂时不用';

  @override
  String get newVideoNote => '视频笔记';

  @override
  String get videoLocalOnly => '此视频只保存在本设备上（不会上传到云端）';

  @override
  String get videoToNote => '根据视频生成笔记';

  @override
  String get videoToNoteRunning => '正在查看视频…';

  @override
  String get permGranted => '已授予';

  @override
  String get permGrant => '授予';

  @override
  String get permOpenSettings => '打开设置';

  @override
  String get newHandwriting => '手写';

  @override
  String get newVoiceCapture => '语音笔记';

  @override
  String get suggestTitle => '推荐标题';

  @override
  String get noteMetaMenu => '标签 · 标题 · 提醒';

  @override
  String get folder => '文件夹';

  @override
  String get noFolder => '没有文件夹';

  @override
  String get newFolder => '新建文件夹';

  @override
  String get editFolder => '编辑文件夹';

  @override
  String get deleteFolder => '删除文件夹';

  @override
  String deleteFolderConfirm(String name) {
    return '文件夹「$name」将被删除。里面的笔记不会被删除，只是不再属于任何文件夹。';
  }

  @override
  String get folderNameHint => '文件夹名称';

  @override
  String get folderIcon => '图标';

  @override
  String get editFilters => '编辑筛选项';

  @override
  String get editFiltersInfo => '选择主屏幕上显示哪些筛选项。隐藏一些可以让页面更清爽。';

  @override
  String get select => '选择';

  @override
  String get noteArchived => '笔记已归档';

  @override
  String deleteChecked(int count) {
    return '删除已勾选 ($count)';
  }

  @override
  String get removeItem => '删除条目';

  @override
  String get copyWholeNote => '复制整条笔记';

  @override
  String get allCopied => '整条笔记已复制到剪贴板';

  @override
  String get speechPlay => '朗读';

  @override
  String get speechPause => '暂停';

  @override
  String get speechResume => '继续';

  @override
  String get speechStop => '停止';

  @override
  String get speechRate => '朗读速度';

  @override
  String get speechSystemDefault => '系统默认';

  @override
  String get speechNoVoices => '此设备上没有安装任何语音';

  @override
  String speechVoiceLanguage(String language) {
    return '$language 语音';
  }

  @override
  String get speechVoiceAutoInfo => '其他语言会自动用男声朗读';

  @override
  String get listening => '正在聆听...';

  @override
  String get listenPlay => '收听';

  @override
  String get listenReadingPdf => '正在读取文档...';

  @override
  String get listenConvertWithAi => '用 AI 转换';

  @override
  String get listenMakePodcast => '完整播客';

  @override
  String get listenMakePodcastSummary => '摘要播客';

  @override
  String get listenOriginalText => '原文';

  @override
  String get listenPodcastReady => '播客旁白已准备好';

  @override
  String get listenPodcastCached => '此前已生成 — 未消耗令牌';

  @override
  String get listenRegenerate => '重新生成';

  @override
  String get listenNoText => '这份文档没有提取到可读文字。扫描版 PDF 没有文字层，演示文稿也可能只包含图片。';

  @override
  String get readDocument => '朗读文档（Word、PDF、幻灯片）';

  @override
  String get readDocUnsupported => '无法读取这种文件类型。';

  @override
  String get exportPdf => '导出为 PDF';

  @override
  String get pdfTitleField => '标题';

  @override
  String get pdfContentField => '内容';

  @override
  String get pdfMarkupHint => '行首的记号会变成格式：[x] 和 [ ] 是复选框，1. 是编号清单，- 是项目符号。';

  @override
  String get pdfIncludeDate => '包含日期';

  @override
  String get exportIncludeImages => '包含图片';

  @override
  String get exportWord => '分享为 Word (.docx)';

  @override
  String get pdfPreview => '预览';

  @override
  String get largeAttachmentTitle => '大文件';

  @override
  String largeAttachmentBody(String size) {
    return '该文件为 $size MB。PDF 无法压缩，将按原样上传并计入你的存储空间。要继续吗？';
  }

  @override
  String get speechRateForeign => '外语朗读速度';

  @override
  String notesArchivedCount(int count) {
    return '已归档 $count 条笔记';
  }

  @override
  String get backgroundColor => '背景色';

  @override
  String get backgroundColorInfo => '笔记的背景颜色';

  @override
  String get frameColor => '边框';

  @override
  String get frameColorInfo => '用你选择的颜色在笔记周围画一圈边框';

  @override
  String get sortBy => '排序';

  @override
  String get reorderNotes => '重新排列笔记';

  @override
  String get reorderModeActive => '拖动卡片来调整顺序';

  @override
  String get reorderDone => '完成';

  @override
  String get sortManual => '手动（拖动的顺序）';

  @override
  String get sortUpdated => '最近更新';

  @override
  String get sortCreated => '创建日期';

  @override
  String get sortTitle => '按标题 (A–Z)';

  @override
  String get foldersSection => '文件夹';

  @override
  String get tagsSection => '标签';

  @override
  String get expandFilters => '展开筛选项';

  @override
  String get collapseFilters => '收起筛选项';

  @override
  String get settingsLanguage => '语言';

  @override
  String get languageSystem => '系统语言';

  @override
  String get settingsSpeech => '朗读';

  @override
  String get aiAdvanced => '高级：模型与 API 密钥';

  @override
  String get aiAdvancedInfo => '模型选择和你自己的 Gemini 密钥。大多数人用不到。';

  @override
  String get openBriefing => '打开简报';

  @override
  String get syncTitle => '同步';

  @override
  String get syncLimitTitle => '自动上传上限';

  @override
  String get syncLimitInfo => '超过此上限的附件会留在设备上，不会上传。笔记正文始终会同步。';

  @override
  String get syncLimitUnlimited => '不限制';

  @override
  String get backupTitle => '备份';

  @override
  String get importBackup => '从备份恢复 (JSON)';

  @override
  String importBackupDone(int count) {
    return '已恢复 $count 条笔记';
  }

  @override
  String get importBackupInvalid => '备份文件无效';

  @override
  String get aiHubTitle => 'AI';

  @override
  String get aiSummarizeInfo => '生成一段简短摘要';

  @override
  String get aiAnalyzeInfo => '列出要点和待办事项';

  @override
  String get aiImproveInfo => '改变语气：正式、更短或列表';

  @override
  String get aiTranslateInfo => '将笔记翻译成所选语言';

  @override
  String get aiFixNoteInfo => '修正拼写和标点';

  @override
  String get moveToFolder => '移动到文件夹';

  @override
  String get voiceAssistantBadge => '助手';

  @override
  String get assistantGenericError => '出了点问题 — 能再试一次吗？';

  @override
  String get quickAddTooltip => '新建笔记 — 选择类型';

  @override
  String get autoTitleSetting => '关闭时推荐标题';

  @override
  String get autoTitleSettingInfo => '离开编辑器时，没有标题的笔记会根据内容自动获得一个简短标题。';

  @override
  String get hubChatInfo => '从你的笔记里找答案';

  @override
  String get hubBriefingInfo => '一眼看完这一天：提醒和最近的笔记';

  @override
  String get hubReadInfo => '听 PDF 或 Word 文档';

  @override
  String get annotate => '批注';

  @override
  String get annotateDone => '结束批注';

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
  String get crop => '裁剪';

  @override
  String get cropApply => '应用裁剪';

  @override
  String get cropReset => '重置选区';

  @override
  String get cropHint => '拖动四角选择区域。裁剪无法撤销。';

  @override
  String get cropFailed => '无法裁剪该图片。';

  @override
  String get penBallpoint => '圆珠笔';

  @override
  String get penMarker => '马克笔';

  @override
  String get penHighlighter => '荧光笔';

  @override
  String get eraser => '橡皮擦';

  @override
  String get clearInk => '清除批注';

  @override
  String get inkTwoFingerHint => '单指绘制 · 双指平移和缩放';

  @override
  String get slideOpenFailed => '无法打开该演示文稿';

  @override
  String get newPhotoNote => '照片笔记';

  @override
  String get newScanNote => '扫描文档';

  @override
  String get scanDocument => '扫描文档';

  @override
  String get scanDocumentSubtitle => '自动找到边缘、拉正页面并添加进来';

  @override
  String get scanUnsupported => '此设备不支持文档扫描';

  @override
  String scanFailed(String error) {
    return '无法扫描文档：$error';
  }

  @override
  String scanPagesAdded(int count) {
    return '已向笔记添加 $count 页';
  }

  @override
  String get scanTextTitle => '是否也识别文字？';

  @override
  String get scanTextBody => '页面上的文字会被识别并写入笔记，图片保持原样。每页需要几秒钟。';

  @override
  String get scanImageOnly => '仅图片';

  @override
  String get scanRecognizeText => '识别文字';

  @override
  String get scanRecognizing => '正在识别文字…';

  @override
  String get takePhoto => '拍照';

  @override
  String get qrScanTitle => '扫描二维码';

  @override
  String get qrScanSubtitle => '用相机扫描，或从照片中识别';

  @override
  String get qrScanHint => '把二维码对准取景框';

  @override
  String get qrFromPhoto => '从照片识别';

  @override
  String get qrNotFound => '在这张图片里没有找到二维码';

  @override
  String get qrLinkFound => '这个二维码是一个链接';

  @override
  String get qrOpenLink => '前往链接';

  @override
  String get qrSaveToNote => '保存到笔记';

  @override
  String get openLink => '打开链接';

  @override
  String get linkOpenFailed => '无法打开该链接';

  @override
  String qrScanFailed(String error) {
    return '无法识别二维码：$error';
  }

  @override
  String get qrTorch => '手电筒';

  @override
  String attachmentsCount(int count) {
    return '附件 ($count)';
  }

  @override
  String get hideAttachments => '隐藏';

  @override
  String get showAttachments => '显示';

  @override
  String get videoBack10 => '后退 10 秒';

  @override
  String get videoForward10 => '前进 10 秒';

  @override
  String get selectAllItems => '全选';

  @override
  String get showAllChips => '全部显示';

  @override
  String get hideAllChips => '全部隐藏';

  @override
  String get chipPickInfo => '主屏幕上要显示哪些文件夹和标签标记？';

  @override
  String get hiddenFolder => '隐藏文件夹';

  @override
  String get hiddenFolderInfo =>
      '隐藏文件夹及其中的笔记不会出现在主屏幕上。要显示它们，请从 ⋮ 菜单中选择「隐藏文件夹」并验证身份。';

  @override
  String get hiddenFoldersMenu => '隐藏文件夹';

  @override
  String get hiddenFolderAuthReason => '请验证身份以显示隐藏文件夹';

  @override
  String get hiddenFoldersShown => '隐藏文件夹正在显示';

  @override
  String get hiddenFoldersHiddenAgain => '隐藏文件夹已重新藏起';

  @override
  String get makeFolderHidden => '隐藏';

  @override
  String get makeFolderVisible => '取消隐藏';

  @override
  String gridColumnsCount(int count) {
    return '$count 列';
  }

  @override
  String get addImageOnPageSubtitle => '放在页面上，文字环绕它排布';

  @override
  String get addImageAsFile => '以文件形式添加图片';

  @override
  String get addImageAsFileSubtitle => '不进入页面，留在附件栏中';

  @override
  String get moveImageToAttachments => '移到附件';

  @override
  String get moveImageToPage => '放到页面上';

  @override
  String get attachmentCopied => '已复制附件';

  @override
  String get pasteAttachment => '粘贴已复制的附件';

  @override
  String get fullscreen => '全屏';

  @override
  String get more => '更多';

  @override
  String get undone => '已撤销';

  @override
  String get filterOthers => '其他';

  @override
  String get chatSuggestion1 => '我的购物清单还缺什么？';

  @override
  String get chatSuggestion2 => '总结本周的工作笔记';

  @override
  String get chatSuggestion3 => '我明天有提醒吗？';

  @override
  String get aiPointsToday => '今日积分';

  @override
  String aiPointsOf(int used, int total) {
    return '$used / $total';
  }

  @override
  String get aiPointsRenew => '午夜重置';

  @override
  String get aiChatWithNotes => '笔记助手';

  @override
  String get aiChatInputHint => '询问关于笔记的内容…';

  @override
  String get aiChatLooking => '正在查找笔记…';

  @override
  String get aiChatFullScreen => '全屏';

  @override
  String get aiOnYourNotes => '基于笔记';

  @override
  String get aiTaskDuplicates => '清理重复项';

  @override
  String aiTaskDuplicatesInfo(int count) {
    return '有 $count 条重复笔记';
  }

  @override
  String get duplicatesTitle => '重复笔记';

  @override
  String get duplicatesHint => '每组中最早的笔记会保留，其余移入回收站。';

  @override
  String get duplicatesKeepBadge => '保留';

  @override
  String get duplicatesDeleteAll => '将重复项移入回收站';

  @override
  String duplicatesDone(int count) {
    return '已将 $count 条重复项移入回收站';
  }

  @override
  String get aiRecentActions => '最近操作';

  @override
  String get aiHistoryClear => '清除';

  @override
  String get aiHistoryQuestion => '提问';

  @override
  String get aiHistoryNoteAction => '笔记操作';

  @override
  String get aiHistoryVoiceNote => '语音笔记';

  @override
  String get aiRecentOps => '最近操作';

  @override
  String get aiTaskWeekSummary => '总结本周';

  @override
  String get aiTaskWeekSummaryInfo => '过去7天的总结';

  @override
  String get aiTaskTagUntagged => '为未分类笔记添加标签';

  @override
  String aiTaskTagUntaggedInfo(int count) {
    return '$count 条笔记等待标记';
  }

  @override
  String get aiTaskSuggestTitles => '建议标题';

  @override
  String aiTaskSuggestTitlesInfo(int count) {
    return '$count 条笔记没有标题';
  }

  @override
  String get sectionPinnedShort => '已置顶';

  @override
  String get sectionToday => '今天';

  @override
  String get sectionThisWeek => '本周';

  @override
  String get sectionEarlier => '更早';

  @override
  String sectionNoteCount(int count) {
    return '$count 条笔记';
  }

  @override
  String get emptySearchSemanticHint => '尝试“含义”选项卡';

  @override
  String get quickCaptureHint => '新笔记…';

  @override
  String get quickCaptureSave => '保存';

  @override
  String get quickAddWrite => '书写';

  @override
  String get quickAddCapture => '捕捉 — 从内容创建笔记';

  @override
  String get viewToggle => '视图';

  @override
  String get searchModeText => '文本';

  @override
  String get searchModeMeaning => '含义';

  @override
  String get filterReminded => '带提醒';

  @override
  String get filterLocked => '已锁定';

  @override
  String get sortColor => '颜色';

  @override
  String get filterSheetTitle => '筛选';

  @override
  String get filterReset => '重置';

  @override
  String get filterSectionStatus => '状态';

  @override
  String get filterSectionFolder => '文件夹';

  @override
  String get filterSectionTag => '标签';

  @override
  String get filterSectionSort => '排序';

  @override
  String get filterFavoriteHint => '点击星标可将该选项固定在主屏幕';

  @override
  String get filterSheetSortHint => '仅在按最后编辑时间排序时显示日期分组（今天、本周……）。';

  @override
  String get formatTitle => '格式';

  @override
  String get formatBold => '加粗';

  @override
  String get formatItalic => '斜体';

  @override
  String get formatUnderline => '下划线';

  @override
  String get formatTextColor => '文字颜色';

  @override
  String get formatHighlight => '高亮';

  @override
  String get formatInfo => '格式以记号的形式保存在正文里（例如 **加粗**）；导出和朗读时这些记号不会显示。';

  @override
  String get formatMenu => '格式…';

  @override
  String get noteFont => '字体';

  @override
  String get noteFontDefault => '默认';

  @override
  String get noteFontSerif => '书籍（衬线）';

  @override
  String get noteFontMono => '打字机';

  @override
  String get noteTextSize => '文字大小';

  @override
  String get formatClear => '清除格式';

  @override
  String get noteTextOpacity => '不透明度';

  @override
  String get assistantVoiceSetting => '助手朗读回复';

  @override
  String get assistantVoiceSettingInfo => '语音助手会把回复念出来（仅限手机）。';

  @override
  String get assistantMute => '静音';

  @override
  String get assistantUnmute => '取消静音';

  @override
  String get assistantMakeNote => '仍然生成笔记';

  @override
  String get assistantNoteCreated => '已创建笔记';

  @override
  String get noteNotFound => '找不到该笔记，它可能已被删除。';

  @override
  String get back => '返回';

  @override
  String get addTextBlock => '添加文字';

  @override
  String get attachNoteContent => 'Not içeriği';

  @override
  String get noteBackgroundImage => '背景图片';

  @override
  String get chooseBackgroundImage => '选择图片';

  @override
  String get changeBackgroundImage => '更换图片';

  @override
  String get removeBackgroundImage => '移除背景';

  @override
  String get dashboardBackground => '主屏幕背景';

  @override
  String get dashboardBackgroundInfo => '显示在笔记网格后面的图片（仅限本设备）。';

  @override
  String get aiProvider => 'AI 服务商';

  @override
  String get aiProviderInfo => '选择你的密钥所属的服务商。每个服务商的密钥分开保存，切回来时无需重新输入。';

  @override
  String get apiKeyFieldLabel => 'API 密钥';

  @override
  String get getApiKey => '在哪里获取密钥？';

  @override
  String get recommendedModel => '推荐';

  @override
  String get freeTierBadge => '有免费额度';

  @override
  String get continueWithoutAccount => '不登录账号继续';

  @override
  String get localAccountInfo =>
      '你的笔记只保存在本设备上：无法在别处打开，卸载应用后会丢失，内置 AI 也处于关闭状态。你随时可以关联 Google 账号 — 笔记会一并带过去。';

  @override
  String get localAccountBadge => '本地账号';

  @override
  String get linkGoogleAccount => '关联 Google 账号';

  @override
  String get accountLinked => '已关联你的 Google 账号，笔记现在会备份。';

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
      '当前无法在不使用 Google 的情况下登录：Firebase 控制台中未启用匿名登录。请使用 Google 登录，或在管理员启用后重试。';

  @override
  String get googleSignInUnavailable =>
      '当前无法使用 Google 登录：Firebase 控制台中未启用 Google 登录方式。';

  @override
  String get signInNetworkError => '无法连接到网络。请检查网络后重试。';

  @override
  String get signInCanceled => '已取消登录。';

  @override
  String get cardRichPreview => '卡片显示格式化文本';

  @override
  String get cardRichPreviewInfo => '笔记中的颜色、高亮、加粗和下划线也会显示在主屏幕卡片上。关闭后，卡片只显示纯文本。';

  @override
  String get fontSizeSmall => '小';

  @override
  String get fontSizeMedium => '中';

  @override
  String get fontSizeLarge => '大';

  @override
  String get fontSizeXLarge => '超大';

  @override
  String get appFontSetting => '字体';

  @override
  String get appFontInfo => '应用中各处使用的字体。笔记自身的字体设置优先。所有字体都随应用内置，无需联网。';

  @override
  String get fontGroupSans => '无衬线';

  @override
  String get fontGroupSerif => '衬线';

  @override
  String get fontGroupMono => '等宽';

  @override
  String get fontGroupHand => '手写';

  @override
  String get appFontDefaultSuffix => '默认';

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
}
