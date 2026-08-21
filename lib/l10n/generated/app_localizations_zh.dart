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
  String get attachmentCopying => '正在复制...';

  @override
  String get attachmentUploading => '正在上传...';

  @override
  String get attachmentUploadFailed =>
      '上传失败 — 点按重试';

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
    return '助手想把笔记「${title}」移到回收站。同意吗？';
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
  String get aiModelDocument => '文档对话与 PDF 摘要';

  @override
  String get aiModelTranslate => '翻译';

  @override
  String get aiModelVoice => '语音笔记助手';

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
  String get newPdfNote => '添加 PDF 并记笔记';

  @override
  String get imageNotePreparing => '正在把图片整理成文档…';

  @override
  String get newImageNote => '添加图片并记笔记';

  @override
  String get pdfPageNoteHint => '本页的笔记…';

  @override
  String pdfPage(int page) {
    return '第 ${page} 页';
  }

  @override
  String pdfPageOf(int page, int total) {
    return '第 ${page} / ${total} 页';
  }

  @override
  String get pdfPreviousPage => '上一页';

  @override
  String get pdfNextPage => '下一页';

  @override
  String get pdfFullScreen => '全屏打开';

  @override
  String get pdfNoDocument => '这条笔记还没有 PDF';

  @override
  String get pdfChooseDocument => '选择 PDF';

  @override
  String get newSlidesNote => '添加幻灯片并记笔记';

  @override
  String get slidesNoDocument => '这条笔记还没有演示文稿';

  @override
  String get slidesChooseDocument => '选择演示文稿';

  @override
  String get pdfEditPages => '编辑页面';

  @override
  String get pdfDeletePages => '删除所选页面';

  @override
  String get pdfAddBlankPage => '添加空白页';

  @override
  String get pdfRotatePages => '旋转';

  @override
  String get pdfBurnInk => '把手写内容烙进文档';

  @override
  String get pdfApplyChanges => '应用更改';

  @override
  String get pdfCannotDeleteAllPages => '不能删除全部页面';

  @override
  String get pdfPagesHint =>
      '点按页面即可选中。页面笔记会跟随所在页面；被删除页面的笔记会隐藏，但仍保留在你的数据中。';

  @override
  String pdfEditFailed(String error) {
    return '无法编辑 PDF：${error}';
  }

  @override
  String get pdfInkBurned => '手写内容已烙进文档';

  @override
  String get pdfAllPageNotes => '所有页面笔记';

  @override
  String get pdfNoPageNotes =>
      '还没有页面笔记。翻到某一页，在下面的输入框里写吧。';

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
  String get inkArrow => '箭头';

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
  String get sortActive => '最常使用';

  @override
  String get voicePreview => '试听语音';

  @override
  String get voicePreviewCached => '示例只生成一次，之后从本地播放';

  @override
  String get reorderHint => '长按卡片，拖到想要的位置';

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
  String get attachNoteContent => '笔记内容';

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
    return '第 ${current} / ${total} 页';
  }

  @override
  String get scanRotatePage => '旋转页面';

  @override
  String get scanDeletePage => '删除页面';

  @override
  String get scanLastPage => '最后一页无法删除';

  @override
  String get scanDiscardTitle => '放弃已扫描的页面吗？';

  @override
  String get scanDiscardConfirm => '放弃';

  @override
  String get scanAdjustCorners => '调整四角';

  @override
  String get scanFilterOriginal => '原图';

  @override
  String get scanFilterAuto => '增强';

  @override
  String get scanFilterGray => '灰度';

  @override
  String get scanFilterBw => '黑白';

  @override
  String get scanApplyAll => '应用到全部';

  @override
  String get scanPageFailed => '无法显示该页面';

  @override
  String get scanCropHint =>
      '页面歪斜时用「调整四角」来纠正';

  @override
  String get scanAddAsPdf => '作为 PDF 添加';

  @override
  String get scanAddAsImages => '作为图片添加';

  @override
  String get scanBuildingPdf => '正在准备 PDF…';

  @override
  String scanOcrProgress(int done, int total) {
    return '正在识别文字… ${done}/${total}';
  }

  @override
  String get scanAutoDetect => '自动识别边缘';

  @override
  String get scanReset => '重置';

  @override
  String get scanDetecting => '正在寻找边缘…';

  @override
  String get scanAutoFound =>
      '已自动找到边缘；如有需要可用控制点微调';

  @override
  String get scanDragHint => '把四角拖到纸张边缘';

  @override
  String get scanApplyCorners => '校正并应用';

  @override
  String get scanWorking => '正在校正…';

  @override
  String get scanPdfAdded => '扫描件已作为 PDF 附件添加到笔记';

  @override
  String get premiumTitle => '高级版';

  @override
  String premiumStatusActive(String date) {
    return '高级版已启用 — 至 ${date}';
  }

  @override
  String get premiumStatusFree => '你正在使用免费版';

  @override
  String get premiumPerksTitle => '高级版有什么不同？';

  @override
  String get premiumPerkAi => '每日 AI 点数';

  @override
  String get premiumPerkAttach => '附件大小';

  @override
  String get premiumPerkStorage => '云端存储空间';

  @override
  String get premiumPerkAuto => '自动的每日内容';

  @override
  String get premiumPerkAutoBody =>
      '每日简报和建议会每天自动生成；免费版只有在你主动请求时才运行。';

  @override
  String get premiumHowTitle => '如何获得？';

  @override
  String get premiumHowBody =>
      '高级版很快会在 Play 商店提供。目前我们处于早期使用阶段。';

  @override
  String get premiumByokHint =>
      '如果填入你自己的 Gemini API 密钥，AI 功能就不受配额限制，与高级版无关（设置 → AI）。';

  @override
  String get premiumDiscoverTitle => '你可能错过的功能';

  @override
  String get discoverScanBody =>
      '扫描的页面会被自动校正、增强，一键变成可搜索的 PDF —— 文字层在设备上生成，完全免费。';

  @override
  String get discoverSemanticBody =>
      '搜索框里的「智能」标签按意思搜索，而不是按词：输入「航班时间」，你的旅行笔记就会出现。';

  @override
  String get discoverAssistantBody =>
      '主屏幕上的麦克风会自动把你说的话变成笔记、清单和提醒 —— 只要说「明天九点看牙医」。';

  @override
  String get discoverLockBody =>
      '你可以用指纹或人脸锁定笔记：内容绝不会出现在搜索、小组件或 AI 中。';

  @override
  String get discoverHiddenBody =>
      '隐藏文件夹里的笔记不会出现在主屏幕或搜索中；显示该文件夹需要验证身份。';

  @override
  String get discoverExportBody =>
      '每条笔记都能连同图片导出为 PDF 或 Word（在分享菜单里）。';

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
  String get pdfSelectOcrRunning => '正在识别文字…';

  @override
  String get pdfSelectOcrNone => '本页没有找到文字';

  @override
  String pdfSelectCopied(int n) {
    return '已复制 ${n} 个字符';
  }

  @override
  String get bubbleAdd => '放一个笔记气泡';

  @override
  String get bubbleAddDone => '气泡添加完毕';

  @override
  String get bubbleCollapse => '收起气泡';

  @override
  String get bubbleHint => '在这里写你的笔记…';

  @override
  String get bubbleTapToPlace => '点按页面上想放气泡的位置';

  @override
  String get aiModelPodcast => '播客朗读';

  @override
  String get listenAiVoice => '用 AI 语音收听';

  @override
  String get listenAiVoiceInfo =>
      '由 Gemini 代替设备语音朗读：更自然，但每个段落都会消耗一次模型调用。';

  @override
  String listenAiVoiceFailed(String error) {
    return 'AI 朗读失败（${error}）。改用设备语音朗读。';
  }

  @override
  String get ttsSectionTitle => '朗读';

  @override
  String get ttsEngineDevice => '设备语音';

  @override
  String get ttsEngineAi => 'AI';

  @override
  String get ttsEngineDeviceInfo =>
      '由设备内置语音朗读：免费、离线、长度不限。';

  @override
  String get ttsEngineAiInfo =>
      '由 Gemini 的语音模型朗读：明显更自然，但每个段落都是一次模型调用，并且需要你自己的 Gemini 密钥。';

  @override
  String get ttsEngineAiUnavailable => 'AI 语音需要你自己的 Gemini 密钥。在此之前将使用设备语音朗读。';

  @override
  String get ttsModel => '语音模型';

  @override
  String get ttsVoice => 'AI 声音';

  @override
  String get shareAsNote => '作为笔记分享';

  @override
  String get shareAsNoteInfo =>
      '连同附件、页面笔记、手写和气泡一起发送；对方在 Not 应用里打开时完全一样。';

  @override
  String get shareAsNotePreparing => '正在准备笔记包…';

  @override
  String get shareAsText => '以纯文本形式';

  @override
  String get shareAsTextInfo => '把笔记正文和页面笔记发送到任意应用。';

  @override
  String get shareAsTextEmpty => '这条笔记没有可分享的文字。';

  @override
  String get sharePdfWithBubbles => '以带气泡的 PDF 形式';

  @override
  String get sharePdfWithBubblesInfo =>
      '气泡、高亮和手写会印进 PDF；任何人都能打开，在 Not 中则以可编辑状态打开。';

  @override
  String get sharePdfWithBubblesNone => '这条笔记中没有带气泡或手写的 PDF。';

  @override
  String get sharePdfWithBubblesPreparing => '正在准备带气泡的 PDF…';

  @override
  String get sharePdfWithBubblesSuffix => '（带气泡）';

  @override
  String get bubbleStar => '加星标';

  @override
  String get bubbleEdit => '编辑气泡';

  @override
  String get bubbleStarredOnly => '仅星标';

  @override
  String get bubbleSearchHint => '搜索气泡…';

  @override
  String get bubblesOverviewTitle => '气泡';

  @override
  String get bubblesEmpty =>
      '还没有气泡。在文档中选中文字并高亮，或者在页面上放一个气泡。';

  @override
  String get bubblesNoMatch => '没有符合搜索条件的气泡。';

  @override
  String get bubbleNoText => '（空气泡）';

  @override
  String get pdfHighlight => '高亮';

  @override
  String get pdfHighlightWithNote => '高亮 + 笔记';

  @override
  String get pageNotesShow => '显示页面笔记';

  @override
  String get pageNotesHide => '隐藏页面笔记';

  @override
  String get bubbleSave => '保存';

  @override
  String get bubbleTitleHint => '标题';

  @override
  String get bubbleUrgent => '紧急（闪烁）';

  @override
  String get captureModeQuestion => '笔记要以哪种方式打开？';

  @override
  String get captureModeBubbles => '气泡';

  @override
  String get captureModeBubblesInfo =>
      '内容会变成文档页面：可用气泡、高亮和笔。';

  @override
  String get captureModeClassic => '经典';

  @override
  String get captureModeClassicInfo =>
      '普通文字笔记；内容以附件形式加入。';

  @override
  String get captureModeNew => '新';

  @override
  String get imagePrepareTitle => '调整图片';

  @override
  String get imagePrepareDone => '继续';

  @override
  String get imageRotateLeft => '向左旋转';

  @override
  String get imageRotateRight => '向右旋转';

  @override
  String get videoFrameFailed =>
      '无法从视频中截取画面；将打开经典笔记。';

  @override
  String get bubbleArrowHide => '隐藏箭头';

  @override
  String get bubbleArrowShow => '显示箭头';

  @override
  String get speechPitch => '语音音调';

  @override
  String get speechVoicePickerTitle => '选择声音';

  @override
  String get formatRemove => '移除';

  @override
  String get exportTitle => '导出';

  @override
  String get exportNotesOption => '笔记文本（PDF / Word）';

  @override
  String get exportNotesOptionInfo => '笔记的文字与图片；不含气泡批注。';

  @override
  String get captureNoteTitle => '笔记标题（可选）';

  @override
  String get captureNoteTitleHint => '新建的文档也会使用此名称';

  @override
  String get imageOcrTitle => '识别图片中的文字';

  @override
  String get imageOcrNone => '未在此图片中找到文字。';

  @override
  String imageOcrHint(int count) {
    return '识别到 $count 行 · 点按选择';
  }

  @override
  String imageOcrSelected(int count) {
    return '已选择 $count 行';
  }

  @override
  String get imageOcrShort => '识别文字';

  @override
  String get imageOcrWorking => '正在识别文字…';

  @override
  String get imageOcrSelectHint => '点按：单词 · 长按拖动：逐字';

  @override
  String get imageOcrInsert => '添加到笔记';

  @override
  String get imageOcrZoomIn => '放大';

  @override
  String get imageOcrZoomOut => '缩小';

  @override
  String get selectImages => '选择图片';

  @override
  String get exportImages => '图片';

  @override
  String get exportImagesInfo => '靠左或靠右的窄图片旁会有文字环绕；居中的图片占满整行。';

  @override
  String get exportAlignLeft => '左';

  @override
  String get exportAlignCenter => '居中';

  @override
  String get exportAlignRight => '右';

  @override
  String get exportImageWidth => '宽度';

  @override
  String get exportImageLine => '位置';

  @override
  String get aiModelSearch => '搜索模型';

  @override
  String get aiModelOthers => '其他模型';

  @override
  String get aiModelNoMatch => '没有匹配的模型。';

  @override
  String get aiModelAutoInfo => '应用会按顺序尝试最合适的模型。';

  @override
  String imageOcrCharsSelected(int count) {
    return '已选择 $count 个字符';
  }

  @override
  String imagesSelectedCount(int count) {
    return '已选择 $count 张图片';
  }

  @override
  String attachmentsCopiedCount(int count) {
    return '$count 个附件';
  }

  @override
  String exportImageLineOf(int count) {
    return '/ 共 $count 行';
  }

  @override
  String get aiModelShowAll => '显示全部';

  @override
  String get aiModelShowAllInfo => '同时列出应用未使用的模型。';

  @override
  String get rotateFailed => '无法旋转图片。';

  @override
  String get dashboardBackgroundPick => '选择背景图片';

  @override
  String get dashboardBackgroundChange => '更换背景图片';

  @override
  String podcastRenderingAudio(int done, int total) {
    return '正在准备音频：${done}/${total} 段';
  }

  @override
  String get podcastExportAudio => '导出为音频文件';

  @override
  String get podcastExportAudioCost =>
      '整篇稿子会用 AI 语音重新合成，并保存为一个 WAV 文件。这会消耗你的 Gemini 配额，长文本可能需要几分钟。';

  @override
  String get podcastShareText => '分享稿子';

  @override
  String get podcastSaveAsNote => '保存为新笔记';

  @override
  String get podcastSavedAsNote => '播客稿已保存为笔记。';

  @override
  String get listenPreparingVoice => '正在准备音频…';

  @override
  String get appearancePreviewTitle => '示例文字';

  @override
  String get appearancePreviewNoteTitle => '示例笔记标题';

  @override
  String get appearancePreviewBody =>
      '你的笔记会是这个样子。文中的 **粗体**、~下划线~ 和 ==2:高亮== 显示成这样。';

  @override
  String get appearancePreviewItem => '清单条目看起来是这样';

  @override
  String get convertToText => '转换为文本';

  @override
  String get convertToList => '转换为清单';

  @override
  String get convertedToText => '清单已转换为普通文本。';

  @override
  String get convertedToList => '文本已转换为清单。';

  @override
  String get convertToListEmpty => '没有可以转换成清单的行。';

  @override
  String get listTwoColumns => '两栏';

  @override
  String get listOneColumn => '单栏';

  @override
  String get sortItems => '排序条目';

  @override
  String get sortStarredFirst => '星标优先';

  @override
  String get sortUncheckedFirst => '已完成放最后';

  @override
  String get sortAlphabetical => 'A → Z';

  @override
  String get sortAlphabeticalDesc => 'Z → A';

  @override
  String get imagesToAttachments => '把图片移到附件';

  @override
  String imagesToAttachmentsDone(int count) {
    return '已把 ${count} 张图片移到附件。';
  }

  @override
  String get imageOcrShowRecognized => '高亮识别出的文字';

  @override
  String get imageOcrHideRecognized => '隐藏高亮';

  @override
  String get bubblePlainMode => '开放文本框';

  @override
  String get bubblePlainModeOn => '开放文本框已开启';

  @override
  String get bubblePlainTapToPlace => '点按文字要放置的位置';

  @override
  String get bubblePlainHint => '点按即可书写';

  @override
  String get noteSearchTitle => '在笔记中搜索';

  @override
  String get noteSearchHint => '搜索这条笔记…';

  @override
  String get noteSearchEmptyHint =>
      '立即搜索笔记正文、条目和页面笔记。想在图片和 PDF 附件里查找，请启动下面的扫描。';

  @override
  String get noteSearchNoHit => '没有找到匹配项。';

  @override
  String get noteSearchScanAttachments => '扫描附件';

  @override
  String get noteSearchAskAi => '问一问 AI';

  @override
  String get noteTitleLabel => '标题';

  @override
  String get noteBodyLabel => '笔记正文';

  @override
  String get itemLabel => '条目';

  @override
  String noteSearchAttachmentsInfo(int count) {
    return '可扫描 ${count} 个附件（图片/PDF）。';
  }

  @override
  String noteSearchAttachmentsReady(int count) {
    return '也会在 ${count} 个附件中搜索。';
  }

  @override
  String pageLabel(int page) {
    return '第 ${page} 页';
  }

  @override
  String get archiveNotebook => '归档笔记本';

  @override
  String get archiveNotebookInfo =>
      '一本有自己页面的笔记本，用来保存重要文件和图片的副本。';

  @override
  String get archivePageImages => '图片';

  @override
  String get archivePageVideos => '视频';

  @override
  String get archivePageDocuments => '文档';

  @override
  String get archivePageTexts => '文本';

  @override
  String get archiveNewPage => '新建页面';

  @override
  String get archivePageName => '页面名称（例如：发票）';

  @override
  String get archivePageEmpty => '这一页是空的。';

  @override
  String get archiveSearchHint => '搜索笔记本…';

  @override
  String get archiveAddText => '添加文本';

  @override
  String get archiveAddFile => '添加文件';

  @override
  String get archiveCopyHere => '复制到归档笔记本';

  @override
  String get archiveNoNotebook =>
      '还没有归档笔记本。请先创建一个。';

  @override
  String get archiveNothingToCopy => '这条笔记没有可复制的附件。';

  @override
  String archiveDeleteEntry(String name) {
    return '要从笔记本删除「${name}」吗？该副本将永久消失。';
  }

  @override
  String archiveCopied(int count) {
    return '已把 ${count} 个文件复制到归档笔记本。';
  }

  @override
  String get archiveCaptureTitle => '从图片中提取';

  @override
  String get archiveCapturePage => '页面';

  @override
  String get archiveCapturePageInfo =>
      'AI 建议的类型。留空则放入「文本」页面。';

  @override
  String get archiveCaptureText => '识别出的文字';

  @override
  String get attachmentTagInsert => '插入到正文';

  @override
  String get attachmentTagInserted => '已插入附件标记。';

  @override
  String get attachmentTagPreview => '预览附件';

  @override
  String get attachmentTagEdit => '编辑附件';

  @override
  String archiveCardSummary(int files, int texts) {
    return '${files} 个文件 · ${texts} 段文本';
  }

  @override
  String get archiveEntryTitle => '标题';

  @override
  String get archiveLinkedFile => '关联的文件';

  @override
  String get archiveNoLink => '没有关联文件';

  @override
  String get attachmentTagEmbed => '把附件嵌入所选文字';

  @override
  String get attachmentTagNoAttachment =>
      '请先给笔记添加一个文件，然后才能把它嵌入正文。';

  @override
  String get bubbleModeBubble => '气泡';

  @override
  String get attachmentTagEmbedInfo =>
      '链接到你选中的文字；若未选中任何内容，则链接到光标处';

  @override
  String get attachmentTagPickText =>
      '现在选中要链接的文字，然后点按「链接到这里」。';

  @override
  String get attachmentTagLinkHere => '链接到这里';

  @override
  String attachmentTagPendingBanner(String name) {
    return '${name} 将被链接 —— 请选中文字';
  }

  @override
  String get docNameNotesSuffix => '笔记';

  @override
  String get docNamePhoto => '照片笔记';

  @override
  String get docNameScan => '扫描笔记';

  @override
  String get docNameImage => '图片笔记';

  @override
  String get docNameVideo => '视频笔记';

  @override
  String get folderManage => '管理文件夹';

  @override
  String get folderEmpty => '这个文件夹是空的';

  @override
  String get folderEmptyHint =>
      '用下面的 + 添加笔记，或在编辑笔记时把它移到这里。';

  @override
  String get brainstormTitle => '和 AI 一起头脑风暴';

  @override
  String get brainstormRowInfo =>
      'AI 先起草一个提纲，然后你们一起完善';

  @override
  String get brainstormIntro =>
      '点按上面的某个标题，或者直接开始写 —— 我们一起想。';

  @override
  String get brainstormOutlineTitle => '提纲';

  @override
  String get brainstormInputHint => '写下一个想法或提出问题…';

  @override
  String get brainstormAddIdea => '添加到笔记';

  @override
  String get brainstormAdded => '已添加到笔记';

  @override
  String get folderShared => '这个文件夹已与好友共享';

  @override
  String get friendsTitle => '联系人';

  @override
  String get friendsAdd => '添加好友';

  @override
  String get friendsEmpty =>
      '还没有人。用邮箱添加好友，就能和对方共享文件夹。';

  @override
  String get friendsRequestsTitle => '请求';

  @override
  String get friendsListTitle => '我的好友';

  @override
  String get friendsAddEmailHint => 'friend@email.com';

  @override
  String get friendsSendRequest => '发送请求';

  @override
  String get friendsRequestSent => '请求已发送';

  @override
  String get friendsNotFound =>
      '没有用这个邮箱注册的用户。对方至少要用 Google 账号打开过一次应用。';

  @override
  String get friendsSelf => '不能把自己添加为好友';

  @override
  String get friendsAlready => '你们已经是好友了';

  @override
  String get friendsDecline => '拒绝';

  @override
  String get friendsAccept => '接受';

  @override
  String get friendsRemove => '移除';

  @override
  String get friendsRemoveConfirmTitle => '移除好友';

  @override
  String friendsRemoveConfirmBody(Object name) {
    return '要把 ${name} 从好友中移除吗？你与对方共享的文件夹将不再可见。';
  }

  @override
  String get friendsNeedsAccount =>
      '联系人和文件夹共享需要已关联的 Google 账号。';

  @override
  String get friendsSearchHint => '按名称或邮箱搜索';

  @override
  String get friendsSearchTab => '搜索';

  @override
  String get friendsSearchEmailTab => '按邮箱';

  @override
  String get friendsSearchEmpty => '没有结果';

  @override
  String get friendsSearchTooShort => '请至少输入 2 个字符再搜索';

  @override
  String get friendsSearchAdd => '添加';

  @override
  String get folderShare => '共享';

  @override
  String folderShareCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已与 ${count} 人共享',
      one: '已与 1 人共享',
    );
    return '$_temp0';
  }

  @override
  String folderShareTitle(Object name) {
    return '共享「${name}」';
  }

  @override
  String get folderShareInfo =>
      '邀请会发给你选择的好友；对方接受后即可看到文件夹。权限（只读 / 写入 / 两者）由你决定。';

  @override
  String get friendsRowInfo => '添加好友，与他们共享文件夹';

  @override
  String get accountRecoverConflictTitle =>
      '此设备上有尚未保存的笔记';

  @override
  String accountRecoverConflictBody(Object count) {
    return '这个 Google 账号已关联到另一个会话；切换过去会隐藏本设备上的 ${count} 条笔记（不会删除，只是从这里无法再访问）。仍要继续吗？';
  }

  @override
  String get accountRecoverConflictProceed => '仍要切换';
  @override
  String get folderRoleRead => '只读';

  @override
  String get folderRoleWrite => '写入';

  @override
  String get folderRoleBoth => '只读 + 写入';

  @override
  String get folderInvitePending => '邀请已发送，等待回复';

  @override
  String get folderWriteOnlyTitle => '你只有写入权限';

  @override
  String get folderWriteOnlyHint => '你可以往这个文件夹里添加新笔记，但看不到里面的笔记。';

  @override
  String get folderChatTitle => '聊天';

  @override
  String get folderChatHint => '写一条消息…';

  @override
  String get folderChatSend => '发送';

  @override
  String get folderChatEmptyTitle => '还没有消息';

  @override
  String get folderChatEmptyHint => '在这里和共享了此文件夹的人聊天。';

  @override
  String get folderInviteTitle => '文件夹邀请';

  @override
  String folderInviteBody(Object name) {
    return '文件夹「${name}」已共享给你。';
  }

  @override
  String get folderInviteAccepted => '已添加文件夹';

  @override
  String get folderInviteDeclined => '已拒绝邀请';

  @override
  String friendRequestBanner(Object name) {
    return '${name} 向你发来好友请求';
  }

  @override
  String get friendRequestAccepted => '已添加好友';

  @override
  String get sendNoteAction => '发送给好友';

  @override
  String get sendNoteTitle => '把笔记发送给好友';

  @override
  String get sendNoteInfo => '笔记副本会送到对方的「收到的笔记」中。附件（图片、文档、音频）不会一起发送。';

  @override
  String sendNoteSent(Object name) {
    return '笔记已发送给 ${name}';
  }

  @override
  String get inboxTitle => '收到的笔记';

  @override
  String get inboxEmpty => '没有收到的笔记';

  @override
  String get inboxEmptyHint => '好友发给你的笔记会汇集到这里。';

  @override
  String inboxFrom(Object name) {
    return '来自 ${name}';
  }

  @override
  String get inboxAccept => '添加到我的笔记';

  @override
  String get inboxAccepted => '笔记已添加到你的笔记中';

  @override
  String get folderShelfExpand => '展开文件夹';

  @override
  String get folderShelfCollapse => '收起文件夹';

  @override
  String get accountSheetLocalInfo => '你的笔记只保存在本设备。关联 Google 账号即可备份并添加好友。';

  @override
  String get accountSettings => '账号设置';
}
