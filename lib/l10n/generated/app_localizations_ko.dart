// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appName => '메모';

  @override
  String get loginTagline => '모든 기기에서 보는 내 메모';

  @override
  String get signInWithGoogle => 'Google로 로그인';

  @override
  String loginError(String error) {
    return '로그인 실패: $error';
  }

  @override
  String get searchHint => '메모 검색...';

  @override
  String get filterAll => '전체';

  @override
  String get filterText => '텍스트';

  @override
  String get filterChecklist => '목록';

  @override
  String get filterOrdered => '번호 매김';

  @override
  String get filterPinned => '고정됨';

  @override
  String get filterStarred => '별표';

  @override
  String get star => '별표 추가';

  @override
  String get unstar => '별표 해제';

  @override
  String editedAt(String date) {
    return '수정: $date';
  }

  @override
  String get sectionPinned => '고정됨';

  @override
  String get sectionOthers => '기타';

  @override
  String get emptyNotes => '아직 메모가 없습니다';

  @override
  String get emptyNotesHint => '+ 를 눌러 첫 메모를 만들어 보세요';

  @override
  String get emptySearch => '결과가 없습니다';

  @override
  String get newTextNote => '텍스트 메모';

  @override
  String get newChecklist => '목록';

  @override
  String get newOrderedList => '번호 목록';

  @override
  String get noteDeleted => '메모를 삭제했습니다';

  @override
  String notesDeletedCount(int count) {
    return '메모 $count개를 삭제했습니다';
  }

  @override
  String selectedCount(int count) {
    return '$count개 선택됨';
  }

  @override
  String get deleteSelected => '선택 항목 삭제';

  @override
  String get undo => '실행 취소';

  @override
  String get redo => '다시 실행';

  @override
  String get titleHint => '제목';

  @override
  String get bodyHint => '메모...';

  @override
  String get newItemHint => '새 항목';

  @override
  String moreItemsCount(int count) {
    return '+$count개 항목 더';
  }

  @override
  String get addAttachment => '추가';

  @override
  String get addAttachmentMore => '다른 첨부 형식…';

  @override
  String get addImage => '이미지 추가';

  @override
  String get addPdf => 'PDF 추가';

  @override
  String get addSlide => '슬라이드 추가';

  @override
  String get pasteImage => '클립보드에서 이미지 붙여넣기';

  @override
  String get clipboardEmpty => '클립보드에 이미지가 없습니다';

  @override
  String get noNoteSelected => '왼쪽에서 메모를 선택하세요';

  @override
  String attachmentFailed(String error) {
    return '첨부파일을 추가하지 못했습니다: $error';
  }

  @override
  String get attachmentCopying => '복사 중...';

  @override
  String get attachmentUploading => '업로드 중...';

  @override
  String get attachmentUploadFailed =>
      '업로드 실패 — 다시 시도하려면 누르세요';

  @override
  String get attachmentNotSynced => '이 파일은 아직 이 기기에 동기화되지 않았습니다';

  @override
  String attachmentTooLarge(int limit) {
    return '파일이 너무 큽니다(최대 $limit MB)';
  }

  @override
  String storageFull(String limit) {
    return '저장 공간이 가득 찼습니다($limit). 오래된 첨부 파일을 삭제해 공간을 확보하세요.';
  }

  @override
  String get storageUsage => '저장 공간';

  @override
  String storageUsageValue(String used, String limit) {
    return '$limit 중 $used 사용';
  }

  @override
  String get removeAttachment => '첨부파일 삭제';

  @override
  String get pin => '고정';

  @override
  String get unpin => '고정 해제';

  @override
  String get delete => '삭제';

  @override
  String get color => '색상';

  @override
  String get aiTitle => 'AI';

  @override
  String get aiSummarize => '메모 요약';

  @override
  String get aiAnalyze => '분석';

  @override
  String get aiSectionNote => '이 메모';

  @override
  String get aiSectionAttachments => '첨부파일';

  @override
  String get summarize => '요약하기';

  @override
  String get summaryDetailTitle => '요약 유형';

  @override
  String get summaryShort => '짧은 요약';

  @override
  String get summaryShortInfo => '몇 문장의 개요와 핵심 내용';

  @override
  String get summaryDetailed => '자세한 요약';

  @override
  String get summaryDetailedInfo => '원본을 열어 보지 않아도 될 만큼 충실하게';

  @override
  String get listen => '듣기';

  @override
  String get ask => '질문하기';

  @override
  String get extractText => '텍스트 추출';

  @override
  String get transcribe => '받아쓰기';

  @override
  String get listenToNote => '소리내어 읽기';

  @override
  String get aiNoApiKey => '먼저 설정에서 Gemini API 키를 입력하세요';

  @override
  String aiError(String error) {
    return 'AI 요청 실패: $error';
  }

  @override
  String get aiSummaryTitle => 'AI 요약';

  @override
  String get aiThinking => '생각 중...';

  @override
  String get copy => '복사';

  @override
  String get copied => '복사됨';

  @override
  String get settingsSearchHint => '설정 검색 — “브리핑”, “마이크”';

  @override
  String settingsSearchEmpty(String query) {
    return '«$query»에 일치하는 설정이 없습니다';
  }

  @override
  String get settings => '설정';

  @override
  String get settingsAppearance => '화면';

  @override
  String get themeSystem => '시스템';

  @override
  String get themeLight => '밝게';

  @override
  String get themeDark => '어둡게';

  @override
  String get settingsAi => 'AI';

  @override
  String get geminiApiKey => 'Gemini API 키';

  @override
  String get geminiApiKeyHint => 'AIza... 로 시작하는 키를 붙여넣으세요';

  @override
  String get geminiApiKeyInfo =>
      '키는 선택 사항입니다. 키가 없어도 AI 요청은 앱 내장 서비스를 거칩니다(매일 무료 사용량이 있으며 Premium이면 더 많습니다). 자신의 키로 제한 없이 쓰려면 aistudio.google.com에서 무료로 받으세요. 키는 이 기기의 안전한 저장소에만 보관됩니다.';

  @override
  String aiBuiltInPremium(int count) {
    return '내장 AI: Premium — 오늘 남은 포인트 $count';
  }

  @override
  String aiBuiltInRemaining(int count) {
    return '내장 AI: 오늘 남은 무료 포인트 $count';
  }

  @override
  String get aiBuiltInByok => '내 키 사용 중 — 무제한';

  @override
  String get aiReport => '이 답변 신고';

  @override
  String get aiReportThanks => '신고를 접수했습니다. 감사합니다';

  @override
  String get privacyPolicyTitle => '개인정보 처리방침';

  @override
  String get lockNote => '잠금';

  @override
  String get unlockNote => '잠금 해제';

  @override
  String get lockedNote => '잠긴 메모';

  @override
  String get unlockAuthReason => '잠긴 메모를 열려면 본인 확인이 필요합니다';

  @override
  String get exportBackup => '백업 내보내기 (JSON)';

  @override
  String get expandListItems => '목록 줄을 전부 표시';

  @override
  String get expandListItemsInfo =>
      '긴 항목은 여러 줄로 넘어가며 전체가 계속 보입니다. 끄면 한 줄로 유지되고 누르면 펼쳐집니다.';

  @override
  String get quickCaptureRowSetting => '빠른 메모 줄';

  @override
  String get quickCaptureRowInfo =>
      '홈 화면 상단에 한 줄 \"새 메모...\" 입력란을 표시합니다. 꺼져 있으면 + 버튼을 사용하세요.';

  @override
  String get emptyTrash => '휴지통 비우기';

  @override
  String emptyTrashConfirm(int count) {
    return '메모 $count개가 영구히 삭제됩니다. 되돌릴 수 없습니다. 계속할까요?';
  }

  @override
  String get trashEmptied => '휴지통을 비웠습니다';

  @override
  String get validateAndSave => '확인 후 저장';

  @override
  String get clear => '지우기';

  @override
  String get aiDiagnostics => 'AI 진단';

  @override
  String get aiDiagnosticsEmpty => '기록된 오류가 없습니다';

  @override
  String aiDiagnosticsCount(int count) {
    return '최근 오류 기록 $count건';
  }

  @override
  String get apiKeyValid => 'API 키를 확인하고 저장했습니다';

  @override
  String get apiKeyInvalid => 'API 키가 올바르지 않습니다';

  @override
  String get apiKeySavedBadge => '저장됨';

  @override
  String get removeApiKey => '키 삭제';

  @override
  String get refresh => '새로고침';

  @override
  String get account => '계정';

  @override
  String get signOut => '로그아웃';

  @override
  String get signOutConfirm => '정말 로그아웃할까요?';

  @override
  String get signOutAnonymousWarning =>
      '로컬 계정을 사용 중입니다. 로그아웃하면 이 계정과 모든 메모에 다시는 접근할 수 없습니다(백업이 없으면 복구 불가). 먼저 Google 계정을 연결하세요. 그래도 로그아웃할까요?';

  @override
  String get deleteAccount => '내 계정과 데이터 삭제';

  @override
  String get deleteAccountWarning =>
      '되돌릴 수 없습니다. 모든 메모와 첨부파일, 계정이 영구히 삭제됩니다. 계속할까요?';

  @override
  String get deleteAccountConfirm => '영구 삭제';

  @override
  String get licensesTitle => '오픈소스 라이선스';

  @override
  String get generating => '생성 중...';

  @override
  String get retry => '다시 시도';

  @override
  String get cancel => '취소';

  @override
  String get close => '닫기';

  @override
  String get ok => '확인';

  @override
  String get syncPending => '동기화 대기 중';

  @override
  String get synced => '동기화됨';

  @override
  String genericError(String error) {
    return '문제가 발생했습니다: $error';
  }

  @override
  String get addTag => '태그';

  @override
  String get tagHint => '예: 업무, 집, 학교';

  @override
  String get addReminder => '알림 설정';

  @override
  String get share => '공유';

  @override
  String get archive => '보관';

  @override
  String get unarchive => '보관 해제';

  @override
  String get archiveTitle => '보관함';

  @override
  String get archiveEmpty => '보관함에 메모가 없습니다';

  @override
  String get trashTitle => '휴지통';

  @override
  String get trashEmpty => '휴지통이 비어 있습니다';

  @override
  String get trashInfo => '삭제한 메모는 여기에 남습니다. 복원하거나 완전히 삭제할 수 있습니다.';

  @override
  String get restore => '복원';

  @override
  String get deleteForever => '영구 삭제';

  @override
  String get deleteForeverConfirm => '이 메모가 영구히 삭제됩니다. 계속할까요?';

  @override
  String assistantDeleteConfirm(String title) {
    return '어시스턴트가 "${title}" 메모를 휴지통으로 옮기려고 합니다. 승인할까요?';
  }

  @override
  String get recordAudio => '음성 녹음';

  @override
  String get recording => '녹음 중...';

  @override
  String get stopAndSave => '마치고 추가';

  @override
  String get micPermissionDenied => '마이크 권한이 거부되었습니다';

  @override
  String get speechRecognitionFailed =>
      '음성 인식이 작동하지 않았습니다. 마이크 권한이 허용되어 있는지, Google 앱이 최신인지 확인하세요.';

  @override
  String get addDrawing => '그림 추가';

  @override
  String get drawingTitle => '그림';

  @override
  String get addToNote => '메모에 추가';

  @override
  String get chatTitle => '노트 어시스턴트';

  @override
  String get chatHint =>
      '메모에 대해 물어보세요: 「지난주에 적어둔 그 요리법이 뭐였지?」, 「장보기 목록에서 빠진 게 뭐야?」';

  @override
  String get chatInputHint => '질문을 입력하세요...';

  @override
  String get fontSize => '글자 크기';

  @override
  String get fontSizePreview => '메모가 이렇게 보입니다';

  @override
  String get darkSchedule => '어두운 테마 예약';

  @override
  String get darkScheduleInfo => '지정한 시간 사이에 어두운 테마로 바뀝니다';

  @override
  String get aiTranslate => '번역';

  @override
  String get voiceCommand => '음성 명령';

  @override
  String get semanticSearchToggle => 'AI 의미 검색';

  @override
  String get semanticSearchHint => '의미로 검색: 「자동차 비용」...';

  @override
  String get briefingTitle => '오늘의 브리핑';

  @override
  String get briefingLoading => '브리핑을 준비하고 있습니다...';

  @override
  String get briefingEmpty => '오늘은 아무것도 없습니다';

  @override
  String get briefingSetting => '매일 브리핑 알림';

  @override
  String get briefingSettingInfo => '원하는 시각에 매일 아침 하루 요약 알림을 받습니다';

  @override
  String get autoTagSetting => '태그 자동 지정';

  @override
  String get autoTagSettingInfo => '태그 없이 메모를 닫으면 AI가 알맞은 태그를 붙입니다';

  @override
  String get suggestTags => '태그 제안';

  @override
  String get aiFixNote => '메모 다듬기';

  @override
  String get fixLevelTitle => '어디까지 다듬을까요?';

  @override
  String get fixSimple => '가볍게';

  @override
  String get fixSimpleInfo => '맞춤법과 오타만';

  @override
  String get fixBalanced => '적당히';

  @override
  String get fixBalancedInfo => '문장 구조까지 손봐 글을 깔끔하게';

  @override
  String get fixDetailed => '꼼꼼히';

  @override
  String get fixDetailedInfo => '글 전체를 처음부터 끝까지 다시 씁니다';

  @override
  String get existingTagsLabel => '이전 태그';

  @override
  String get aiSkipCheckedSetting => '체크한 항목은 AI 편집에서 제외';

  @override
  String get aiSkipCheckedInfo =>
      'AI가 목록을 다듬거나 번역할 때 완료된(체크된) 항목은 그대로 두고, 체크하지 않은 항목만 수정합니다.';

  @override
  String get noteUpdatedUndo => '메모를 업데이트했습니다';

  @override
  String get aiImprove => '메모 개선';

  @override
  String get improveFormal => '더 격식 있게';

  @override
  String get improveShorten => '짧게 줄이기';

  @override
  String get improveBullets => '글머리 기호 목록으로';

  @override
  String get improveNumbered => '번호 목록으로';

  @override
  String get replaceNote => '메모 바꾸기';

  @override
  String get openAsNewNote => '새 메모로';

  @override
  String get pdfChatHint =>
      '이 PDF에 대해 물어보세요: 「요약해줘」, 「위약금 조항이 있어?」, 「기한이 언제야?」';

  @override
  String get pdfChatInputHint => 'PDF에 대한 질문을 입력하세요...';

  @override
  String get voiceCaptureHint =>
      '말해 보세요: 「우유랑 빵 사기」 또는 「내일 9시 회의, 알려줘」 — 말이 끝나면 AI가 메모를 만들어 줍니다.';

  @override
  String get voiceFinish => '완료';

  @override
  String get voiceProcessing => '말한 내용을 처리하고 있습니다...';

  @override
  String get voiceNothingHeard => '녹음에서 말소리를 찾지 못했습니다';

  @override
  String get voiceNoteSaved => '음성 메모를 저장했습니다';

  @override
  String get openNote => '메모 열기';

  @override
  String get remindersTitle => '알림';

  @override
  String get remindersEmpty => '알림이 없습니다';

  @override
  String get remindersEmptyHint => '메모에 알림을 추가하거나, + 버튼으로 알림이 있는 새 메모를 만드세요';

  @override
  String get remindersUpcoming => '예정';

  @override
  String get remindersPast => '지난 알림';

  @override
  String get reminderInPast => '선택한 시간이 이미 지났습니다. 미래 시간을 선택하세요.';

  @override
  String get newReminder => '새 알림';

  @override
  String get remindersUntitled => '제목 없는 메모';

  @override
  String get remindersEdit => '시간 변경';

  @override
  String get remindersRemove => '알림 삭제';

  @override
  String get aiModelChat => '요약, 제목, 태그, 대화';

  @override
  String get aiModelDocument => '문서 대화와 PDF 요약';

  @override
  String get aiModelTranslate => '번역';

  @override
  String get aiModelVoice => '음성 메모 도우미';

  @override
  String get aiModelAuto => '자동(권장)';

  @override
  String get aiModelsInfo =>
      '작업마다 다른 모델을 고를 수 있습니다. 짧은 글에는 빠른 모델이면 충분하고, 긴 문서에는 성능이 좋은 모델이 적합합니다. 고른 모델이 사용량을 다 쓰거나 제공이 중단되면 다음 모델이 자동으로 시도됩니다.';

  @override
  String get clearNote => '내용 비우기';

  @override
  String get clearNoteConfirm => '메모의 내용(텍스트와 목록 항목)이 삭제됩니다. 계속할까요?';

  @override
  String get themePaper => '종이';

  @override
  String get calculatorTitle => '계산기';

  @override
  String get calcExpressionHint => '예: 12.5×3+40';

  @override
  String get calcInvalid => '올바르지 않은 식입니다';

  @override
  String get liveDictation => '받아쓰기';

  @override
  String get dictationListening => '듣고 있습니다... 말하는 대로 글이 적힙니다';

  @override
  String get dictationNoKeyInfo =>
      '이 기기에서는 실시간 받아쓰기를 쓸 수 없습니다. 멈추면 녹음을 한 번에 받아씁니다.';

  @override
  String get dictationHoldHint => '마이크를 누른 채 말하세요. 손을 떼면 글이 적힙니다';

  @override
  String itemsSelected(int count) {
    return '항목 $count개 선택됨';
  }

  @override
  String get noteChatTitle => '이 메모와 대화하기';

  @override
  String get noteChatHint => '이 메모에 대해 물어보세요';

  @override
  String get noteChatIntro => '메모의 내용과 첨부파일(PDF·이미지)을 읽고, 그 내용을 바탕으로 질문에 답합니다.';

  @override
  String get dictationProcessing => '받아쓰는 중...';

  @override
  String get aiDailyManualInfo =>
      '무료 요금제에서는 자동으로 만들어지지 않아 하루 사용량을 쓰지 않습니다. 아래 버튼으로 하루에 한 번 만들 수 있습니다.';

  @override
  String get aiGenerate => '생성';

  @override
  String get aiGeneratedTodayInfo =>
      '오늘 만들어진 내용입니다. 무료 요금제에서는 하루에 한 번 갱신되며, 내일 다시 만들 수 있습니다.';

  @override
  String get voiceAssistantTitle => '음성 메모 어시스턴트';

  @override
  String get voiceListening => '듣고 있습니다...';

  @override
  String get voiceHoldHint => '누른 채 말하세요. 손을 떼면 메모가 만들어집니다';

  @override
  String get voiceTapHint => '눌러서 말하고, 다시 누르면 끝납니다';

  @override
  String get voiceTooShort => '녹음이 너무 짧습니다. 다시 시도하세요';

  @override
  String get voiceModeSetting => '작동 방식';

  @override
  String get voiceModeHold => '누른 채 말하기';

  @override
  String get voiceModeTap => '눌러서 시작 / 눌러서 정지';

  @override
  String get voiceModeInfo =>
      '누른 채 말하기: 버튼을 누르고 있는 동안 듣고, 손을 떼면 메모를 만듭니다. 눌러서 시작: 한 번 누르면 녹음이 시작되고, 다시 누르면 끝납니다.';

  @override
  String get voiceHeardLive => '말소리 감지됨';

  @override
  String get voiceCaptureReady => '음성 인식 준비 완료';

  @override
  String get voiceCaptureEditHint => '텍스트를 눌러 수정하세요';

  @override
  String voiceCapturePunctuation(String language) {
    return '$language · 자동 구두점';
  }

  @override
  String get voiceCaptureAddToNote => '노트에 추가';

  @override
  String get voiceCaptureCreateNote => '새 노트 생성';

  @override
  String get voiceCaptureAiNote => 'AI 노트';

  @override
  String get voiceCapturePlainNote => '일반 메모';

  @override
  String get voiceCloseTitle => '받아쓴 내용이 남아 있습니다';

  @override
  String get voiceCloseKeepTalking => '계속 말하기';

  @override
  String get voiceCaptureRestart => '다시 녹음';

  @override
  String get voiceChipSummarizeAdd => '요약으로 추가';

  @override
  String get voiceChipSummarizeSave => '요약으로 저장';

  @override
  String get voiceChipToItems => '항목별 분리';

  @override
  String get voiceChipAsList => '체크리스트로 변환';

  @override
  String get voiceChipFix => '다듬기';

  @override
  String get voiceChipCompose => '어시스턴트에게 작성 요청';

  @override
  String get editorToolList => '목록';

  @override
  String get permissionsTitle => '권한';

  @override
  String get permMic => '마이크';

  @override
  String get permMicInfo => '음성 메모와 받아쓰기에 필요합니다';

  @override
  String get permNotifications => '알림';

  @override
  String get permNotificationsInfo => '알림과 매일 브리핑에 필요합니다';

  @override
  String get permBattery => '배터리 최적화';

  @override
  String get permBatteryInfo => '알림이 제때 도착하도록 앱을 배터리 제한에서 제외합니다';

  @override
  String get showTagChips => '태그 칩 표시';

  @override
  String get showFolderChips => '폴더 칩 표시';

  @override
  String videoTooBigForAi(int mb) {
    return '동영상이 너무 커서 AI로 보낼 수 없습니다($mb MB). 더 짧게 녹화하세요.';
  }

  @override
  String get permCamera => '카메라';

  @override
  String get permCameraInfo => '동영상 메모와 사진 촬영에 필요합니다';

  @override
  String get permOnboardTitle => '시작하기 전에';

  @override
  String get permOnboardInfo =>
      '메모는 해당 기능을 사용할 때만 이 권한들을 요청합니다. 아래에서 지금 허용하거나, 나중에 설정 > 권한에서 바꿀 수 있습니다.';

  @override
  String get permOnboardGrantAll => '권한 허용';

  @override
  String get permOnboardSkip => '나중에';

  @override
  String get newVideoNote => '동영상 메모';

  @override
  String get videoLocalOnly => '이 동영상은 이 기기에만 저장됩니다(클라우드에 올라가지 않습니다)';

  @override
  String get videoToNote => '동영상으로 메모 만들기';

  @override
  String get videoToNoteRunning => '동영상을 살펴보는 중…';

  @override
  String get permGranted => '허용됨';

  @override
  String get permGrant => '허용';

  @override
  String get permOpenSettings => '설정 열기';

  @override
  String get newHandwriting => '손글씨';

  @override
  String get newVoiceCapture => '음성 메모';

  @override
  String get suggestTitle => '제목 제안';

  @override
  String get noteMetaMenu => '태그 · 제목 · 알림';

  @override
  String get folder => '폴더';

  @override
  String get noFolder => '폴더 없음';

  @override
  String get newFolder => '새 폴더';

  @override
  String get editFolder => '폴더 편집';

  @override
  String get deleteFolder => '폴더 삭제';

  @override
  String deleteFolderConfirm(String name) {
    return '「$name」 폴더가 삭제됩니다. 안에 있는 메모는 삭제되지 않고 폴더만 없어집니다.';
  }

  @override
  String get folderNameHint => '폴더 이름';

  @override
  String get folderIcon => '아이콘';

  @override
  String get editFilters => '필터 편집';

  @override
  String get editFiltersInfo => '홈 화면에 표시할 필터를 고르세요. 일부를 숨기면 화면이 깔끔해집니다.';

  @override
  String get select => '선택';

  @override
  String get noteArchived => '메모를 보관했습니다';

  @override
  String deleteChecked(int count) {
    return '체크한 항목 삭제 ($count)';
  }

  @override
  String get removeItem => '항목 삭제';

  @override
  String get copyWholeNote => '메모 전체 복사';

  @override
  String get allCopied => '메모 전체를 클립보드에 복사했습니다';

  @override
  String get speechPlay => '소리내어 읽기';

  @override
  String get speechPause => '일시정지';

  @override
  String get speechResume => '이어서 재생';

  @override
  String get speechStop => '정지';

  @override
  String get speechRate => '읽기 속도';

  @override
  String get speechSystemDefault => '시스템 기본값';

  @override
  String get speechNoVoices => '이 기기에 설치된 음성이 없습니다';

  @override
  String speechVoiceLanguage(String language) {
    return '$language 음성';
  }

  @override
  String get speechVoiceAutoInfo => '다른 언어는 자동으로 남성 음성으로 읽습니다';

  @override
  String get listening => '듣고 있습니다...';

  @override
  String get listenPlay => '듣기';

  @override
  String get listenReadingPdf => '문서를 읽는 중...';

  @override
  String get listenConvertWithAi => 'AI로 변환';

  @override
  String get listenMakePodcast => '전체 팟캐스트';

  @override
  String get listenMakePodcastSummary => '요약 팟캐스트';

  @override
  String get listenOriginalText => '원본 텍스트';

  @override
  String get listenPodcastReady => '팟캐스트 낭독이 준비되었습니다';

  @override
  String get listenPodcastCached => '이전에 생성됨 — 토큰이 들지 않았습니다';

  @override
  String get listenRegenerate => '다시 생성';

  @override
  String get listenNoText =>
      '이 문서에서 읽을 수 있는 텍스트가 나오지 않았습니다. 스캔한 PDF에는 텍스트 층이 없고, 프레젠테이션은 이미지만 담고 있을 수 있습니다.';

  @override
  String get readDocument => '문서 읽기 (Word, PDF, 슬라이드)';

  @override
  String get readDocUnsupported => '이 파일 형식은 읽을 수 없습니다.';

  @override
  String get exportPdf => 'PDF로 내보내기';

  @override
  String get pdfTitleField => '제목';

  @override
  String get pdfContentField => '내용';

  @override
  String get pdfMarkupHint =>
      '줄 앞의 기호는 서식이 됩니다: [x] 와 [ ] 는 체크박스, 1. 은 번호 목록, - 은 글머리 기호입니다.';

  @override
  String get pdfIncludeDate => '날짜 포함';

  @override
  String get exportIncludeImages => '이미지 포함';

  @override
  String get exportWord => 'Word (.docx)로 공유';

  @override
  String get pdfPreview => '미리보기';

  @override
  String get largeAttachmentTitle => '큰 파일';

  @override
  String largeAttachmentBody(String size) {
    return '이 파일은 $size MB입니다. PDF는 압축할 수 없어 그대로 업로드되며 저장 용량에 포함됩니다. 계속할까요?';
  }

  @override
  String get speechRateForeign => '외국어 속도';

  @override
  String notesArchivedCount(int count) {
    return '메모 $count개를 보관했습니다';
  }

  @override
  String get backgroundColor => '배경색';

  @override
  String get backgroundColorInfo => '메모의 배경색';

  @override
  String get frameColor => '테두리';

  @override
  String get frameColorInfo => '고른 색으로 메모 둘레에 테두리를 그립니다';

  @override
  String get sortBy => '정렬';

  @override
  String get reorderNotes => '메모 순서 바꾸기';

  @override
  String get reorderModeActive => '카드를 끌어서 순서를 바꾸세요';

  @override
  String get reorderDone => '완료';

  @override
  String get sortManual => '직접 정렬(끌어놓은 순서)';

  @override
  String get sortUpdated => '최근 수정순';

  @override
  String get sortCreated => '만든 날짜';

  @override
  String get sortTitle => '제목순 (A–Z)';

  @override
  String get foldersSection => '폴더';

  @override
  String get tagsSection => '태그';

  @override
  String get expandFilters => '필터 펼치기';

  @override
  String get collapseFilters => '필터 접기';

  @override
  String get settingsLanguage => '언어';

  @override
  String get languageSystem => '시스템 언어';

  @override
  String get settingsSpeech => '소리내어 읽기';

  @override
  String get aiAdvanced => '고급: 모델과 API 키';

  @override
  String get aiAdvancedInfo => '모델 선택과 내 Gemini 키. 대부분은 필요하지 않습니다.';

  @override
  String get openBriefing => '브리핑 열기';

  @override
  String get syncTitle => '동기화';

  @override
  String get syncLimitTitle => '자동 업로드 한도';

  @override
  String get syncLimitInfo =>
      '이 한도보다 큰 첨부파일은 기기에 남고 업로드되지 않습니다. 메모 본문은 항상 동기화됩니다.';

  @override
  String get syncLimitUnlimited => '한도 없음';

  @override
  String get backupTitle => '백업';

  @override
  String get importBackup => '백업에서 복원 (JSON)';

  @override
  String importBackupDone(int count) {
    return '메모 $count개를 복원했습니다';
  }

  @override
  String get importBackupInvalid => '올바르지 않은 백업 파일입니다';

  @override
  String get aiHubTitle => 'AI';

  @override
  String get aiSummarizeInfo => '짧은 요약을 만듭니다';

  @override
  String get aiAnalyzeInfo => '핵심 내용과 할 일을 정리합니다';

  @override
  String get aiImproveInfo => '문체를 바꿉니다: 격식, 축약 또는 목록';

  @override
  String get aiTranslateInfo => '선택한 언어로 노트를 번역합니다';

  @override
  String get aiFixNoteInfo => '맞춤법과 문장부호를 고칩니다';

  @override
  String get moveToFolder => '폴더로 이동';

  @override
  String get voiceAssistantBadge => '어시스턴트';

  @override
  String get assistantGenericError => '문제가 발생했습니다 — 다시 시도해 주시겠어요?';

  @override
  String get quickAddTooltip => '새 메모 — 종류를 고르세요';

  @override
  String get autoTitleSetting => '닫을 때 제목 제안';

  @override
  String get autoTitleSettingInfo =>
      '편집기를 나갈 때 제목이 없는 메모에는 내용을 바탕으로 만든 짧은 제목이 붙습니다.';

  @override
  String get hubChatInfo => '내 메모에서 찾아 답합니다';

  @override
  String get hubBriefingInfo => '한눈에 보는 하루: 알림과 최근 메모';

  @override
  String get hubReadInfo => 'PDF나 Word 문서를 들어 보세요';

  @override
  String get annotate => '주석 달기';

  @override
  String get annotateDone => '주석 마치기';

  @override
  String get newPdfNote => 'PDF 추가하고 메모하기';

  @override
  String get imageNotePreparing => '이미지를 문서로 정리하는 중…';

  @override
  String get newImageNote => '이미지 추가 후 메모';

  @override
  String get pdfPageNoteHint => '이 페이지의 메모…';

  @override
  String pdfPage(int page) {
    return '${page}쪽';
  }

  @override
  String pdfPageOf(int page, int total) {
    return '${page} / ${total}쪽';
  }

  @override
  String get pdfPreviousPage => '이전 페이지';

  @override
  String get pdfNextPage => '다음 페이지';

  @override
  String get pdfFullScreen => '전체 화면으로 열기';

  @override
  String get pdfNoDocument => '이 메모에는 아직 PDF가 없습니다';

  @override
  String get pdfChooseDocument => 'PDF 선택';

  @override
  String get newSlidesNote => '슬라이드 추가하고 메모하기';

  @override
  String get slidesNoDocument => '이 메모에는 아직 프레젠테이션이 없습니다';

  @override
  String get slidesChooseDocument => '프레젠테이션 선택';

  @override
  String get pdfEditPages => '페이지 편집';

  @override
  String get pdfDeletePages => '선택한 페이지 삭제';

  @override
  String get pdfAddBlankPage => '빈 페이지 추가';

  @override
  String get pdfRotatePages => '회전';

  @override
  String get pdfBurnInk => '손글씨를 문서에 새기기';

  @override
  String get pdfApplyChanges => '변경사항 적용';

  @override
  String get pdfCannotDeleteAllPages => '모든 페이지를 삭제할 수는 없습니다';

  @override
  String get pdfPagesHint =>
      '페이지를 눌러 선택하세요. 페이지 메모는 해당 페이지를 따라다니며, 삭제된 페이지의 메모는 숨겨지지만 데이터에는 남습니다.';

  @override
  String pdfEditFailed(String error) {
    return 'PDF를 편집할 수 없습니다: ${error}';
  }

  @override
  String get pdfInkBurned => '손글씨를 문서에 새겼습니다';

  @override
  String get pdfAllPageNotes => '모든 페이지 메모';

  @override
  String get pdfNoPageNotes =>
      '아직 페이지 메모가 없습니다. 페이지를 연 뒤 아래 칸에 적어 보세요.';

  @override
  String get crop => '자르기';

  @override
  String get cropApply => '자르기 적용';

  @override
  String get cropReset => '선택 초기화';

  @override
  String get cropHint => '모서리를 끌어 영역을 고르세요. 자르기는 되돌릴 수 없습니다.';

  @override
  String get cropFailed => '이미지를 자르지 못했습니다.';

  @override
  String get penBallpoint => '볼펜';

  @override
  String get penMarker => '마커';

  @override
  String get penHighlighter => '형광펜';

  @override
  String get eraser => '지우개';

  @override
  String get inkArrow => '화살표';

  @override
  String get clearInk => '주석 지우기';

  @override
  String get inkTwoFingerHint => '한 손가락은 그리기 · 두 손가락은 이동과 확대';

  @override
  String get slideOpenFailed => '프레젠테이션을 열지 못했습니다';

  @override
  String get newPhotoNote => '사진 메모';

  @override
  String get newScanNote => '문서 스캔';

  @override
  String get scanDocument => '문서 스캔';

  @override
  String get scanDocumentSubtitle => '가장자리를 찾아 페이지를 반듯하게 펴서 추가합니다';

  @override
  String get scanUnsupported => '이 기기에서는 문서 스캔을 지원하지 않습니다';

  @override
  String scanFailed(String error) {
    return '문서를 스캔하지 못했습니다: $error';
  }

  @override
  String scanPagesAdded(int count) {
    return '메모에 $count페이지를 추가했습니다';
  }

  @override
  String get scanTextTitle => '텍스트도 인식할까요?';

  @override
  String get scanTextBody =>
      '페이지의 텍스트를 인식해 메모에 적습니다. 이미지는 그대로 남습니다. 페이지마다 몇 초가 걸립니다.';

  @override
  String get scanImageOnly => '이미지만';

  @override
  String get scanRecognizeText => '텍스트 인식';

  @override
  String get scanRecognizing => '텍스트를 인식하는 중…';

  @override
  String get takePhoto => '사진 찍기';

  @override
  String get qrScanTitle => 'QR 코드 스캔';

  @override
  String get qrScanSubtitle => '카메라로 읽거나 사진에서 읽습니다';

  @override
  String get qrScanHint => '코드를 테두리 안에 맞추세요';

  @override
  String get qrFromPhoto => '사진에서 읽기';

  @override
  String get qrNotFound => '이 이미지에서 코드를 찾지 못했습니다';

  @override
  String get qrLinkFound => '이 코드는 링크입니다';

  @override
  String get qrOpenLink => '링크로 이동';

  @override
  String get qrSaveToNote => '메모에 저장';

  @override
  String get openLink => '링크 열기';

  @override
  String get linkOpenFailed => '링크를 열지 못했습니다';

  @override
  String qrScanFailed(String error) {
    return '코드를 읽지 못했습니다: $error';
  }

  @override
  String get qrTorch => '손전등';

  @override
  String attachmentsCount(int count) {
    return '첨부파일 ($count)';
  }

  @override
  String get hideAttachments => '숨기기';

  @override
  String get showAttachments => '표시';

  @override
  String get videoBack10 => '10초 뒤로';

  @override
  String get videoForward10 => '10초 앞으로';

  @override
  String get selectAllItems => '전체 선택';

  @override
  String get showAllChips => '전체 표시';

  @override
  String get hideAllChips => '전체 숨기기';

  @override
  String get chipPickInfo => '홈 화면에 어떤 폴더와 태그 칩을 표시할까요?';

  @override
  String get hiddenFolder => '숨긴 폴더';

  @override
  String get hiddenFolderInfo =>
      '숨긴 폴더와 그 안의 메모는 홈 화면에 나타나지 않습니다. 보려면 ⋮ 메뉴에서 「숨긴 폴더」를 고르고 본인 확인을 하세요.';

  @override
  String get hiddenFoldersMenu => '숨긴 폴더';

  @override
  String get hiddenFolderAuthReason => '숨긴 폴더를 보려면 본인 확인이 필요합니다';

  @override
  String get hiddenFoldersShown => '숨긴 폴더가 표시되고 있습니다';

  @override
  String get hiddenFoldersHiddenAgain => '숨긴 폴더를 다시 감췄습니다';

  @override
  String get makeFolderHidden => '숨기기';

  @override
  String get makeFolderVisible => '표시하기';

  @override
  String gridColumnsCount(int count) {
    return '$count열';
  }

  @override
  String get addImageOnPageSubtitle => '페이지 안에 놓이고 글이 주위로 흐릅니다';

  @override
  String get addImageAsFile => '이미지를 파일로 추가';

  @override
  String get addImageAsFileSubtitle => '페이지 밖 첨부파일 줄에 남습니다';

  @override
  String get moveImageToAttachments => '첨부파일로 옮기기';

  @override
  String get moveImageToPage => '페이지에 놓기';

  @override
  String get attachmentCopied => '첨부파일을 복사했습니다';

  @override
  String get pasteAttachment => '복사한 첨부파일 붙여넣기';

  @override
  String get fullscreen => '전체 화면';

  @override
  String get more => '더보기';

  @override
  String get undone => '실행을 취소했습니다';

  @override
  String get filterOthers => '기타';

  @override
  String get chatSuggestion1 => '쇼핑 목록에서 빠진 게 뭐야?';

  @override
  String get chatSuggestion2 => '이번 주 업무 노트 요약해 줘';

  @override
  String get chatSuggestion3 => '내일 알림이 있나?';

  @override
  String get aiPointsToday => '오늘의 포인트';

  @override
  String aiPointsOf(int used, int total) {
    return '$used / $total';
  }

  @override
  String get aiPointsRenew => '자정에 갱신됨';

  @override
  String get aiChatWithNotes => '노트 어시스턴트';

  @override
  String get aiChatInputHint => '노트에 대해 물어보세요…';

  @override
  String get aiChatLooking => '노트를 살펴보는 중…';

  @override
  String get aiChatFullScreen => '전체 화면';

  @override
  String get aiOnYourNotes => '노트 기반';

  @override
  String get aiTaskDuplicates => '중복 정리';

  @override
  String aiTaskDuplicatesInfo(int count) {
    return '중복 메모 $count개';
  }

  @override
  String get duplicatesTitle => '중복 메모';

  @override
  String get duplicatesHint => '각 그룹에서 가장 오래된 메모는 남고 나머지는 휴지통으로 이동합니다.';

  @override
  String get duplicatesKeepBadge => '유지';

  @override
  String get duplicatesDeleteAll => '중복을 휴지통으로 이동';

  @override
  String duplicatesDone(int count) {
    return '중복 $count개를 휴지통으로 옮겼습니다';
  }

  @override
  String get aiRecentActions => '최근 작업';

  @override
  String get aiHistoryClear => '지우기';

  @override
  String get aiHistoryQuestion => '질문';

  @override
  String get aiHistoryNoteAction => '메모 작업';

  @override
  String get aiHistoryVoiceNote => '음성 메모';

  @override
  String get aiRecentOps => '최근 작업';

  @override
  String get aiTaskWeekSummary => '이번 주 요약';

  @override
  String get aiTaskWeekSummaryInfo => '지난 7일간의 요약';

  @override
  String get aiTaskTagUntagged => '태그 없는 항목 태그하기';

  @override
  String aiTaskTagUntaggedInfo(int count) {
    return '태그 대기 중인 노트 $count개';
  }

  @override
  String get aiTaskSuggestTitles => '제목 제안';

  @override
  String aiTaskSuggestTitlesInfo(int count) {
    return '제목 없는 노트 $count개';
  }

  @override
  String get sectionPinnedShort => '고정됨';

  @override
  String get sectionToday => '오늘';

  @override
  String get sectionThisWeek => '이번 주';

  @override
  String get sectionEarlier => '이전';

  @override
  String sectionNoteCount(int count) {
    return '노트 $count개';
  }

  @override
  String get emptySearchSemanticHint => '의미 탭을 시도해 보세요';

  @override
  String get quickCaptureHint => '새 노트…';

  @override
  String get quickCaptureSave => '저장';

  @override
  String get quickAddWrite => '작성';

  @override
  String get quickAddCapture => '캡처 — 콘텐츠로 노트 생성';

  @override
  String get viewToggle => '보기';

  @override
  String get searchModeText => '텍스트';

  @override
  String get searchModeMeaning => '의미';

  @override
  String get filterReminded => '알림 있음';

  @override
  String get filterLocked => '잠김';

  @override
  String get sortColor => '색상';

  @override
  String get sortActive => '가장 많이 작업한';

  @override
  String get voicePreview => '음성 미리 듣기';

  @override
  String get voicePreviewCached => '샘플은 한 번만 생성되고 이후에는 저장된 파일을 재생합니다';

  @override
  String get reorderHint => '카드를 길게 눌러 원하는 위치로 끌어 놓으세요';

  @override
  String get filterSheetTitle => '필터';

  @override
  String get filterReset => '초기화';

  @override
  String get filterSectionStatus => '상태';

  @override
  String get filterSectionFolder => '폴더';

  @override
  String get filterSectionTag => '태그';

  @override
  String get filterSectionSort => '정렬';

  @override
  String get filterFavoriteHint => '별표를 누르면 홈 화면에 유지됩니다';

  @override
  String get filterSheetSortHint =>
      '날짜별 정렬(오늘, 이번 주 등)은 마지막 수정일 기준 정렬 시에만 표시됩니다.';

  @override
  String get formatTitle => '서식';

  @override
  String get formatBold => '굵게';

  @override
  String get formatItalic => '기울임';

  @override
  String get formatUnderline => '밑줄';

  @override
  String get formatTextColor => '글자 색';

  @override
  String get formatHighlight => '형광펜';

  @override
  String get formatInfo =>
      '서식은 본문 안에 기호로 저장됩니다(예: **굵게**). 내보내기와 읽어주기에서는 기호가 보이지 않습니다.';

  @override
  String get formatMenu => '서식…';

  @override
  String get noteFont => '글꼴';

  @override
  String get noteFontDefault => '기본';

  @override
  String get noteFontSerif => '명조(세리프)';

  @override
  String get noteFontMono => '타자기';

  @override
  String get noteTextSize => '글자 크기';

  @override
  String get formatClear => '서식 지우기';

  @override
  String get noteTextOpacity => '불투명도';

  @override
  String get assistantVoiceSetting => '어시스턴트가 답변을 읽어줍니다';

  @override
  String get assistantVoiceSettingInfo => '음성 어시스턴트가 답변을 소리내어 읽습니다(휴대폰만).';

  @override
  String get assistantMute => '소리 끄기';

  @override
  String get assistantUnmute => '소리 켜기';

  @override
  String get assistantMakeNote => '그래도 메모로 만들기';

  @override
  String get assistantNoteCreated => '메모를 만들었습니다';

  @override
  String get noteNotFound => '메모를 찾을 수 없습니다. 삭제되었을 수 있습니다.';

  @override
  String get back => '뒤로';

  @override
  String get addTextBlock => '텍스트 추가';

  @override
  String get attachNoteContent => '메모 내용';

  @override
  String get noteBackgroundImage => '배경 이미지';

  @override
  String get chooseBackgroundImage => '이미지 고르기';

  @override
  String get changeBackgroundImage => '이미지 변경';

  @override
  String get removeBackgroundImage => '배경 삭제';

  @override
  String get dashboardBackground => '홈 화면 배경';

  @override
  String get dashboardBackgroundInfo => '메모 격자 뒤에 보이는 이미지입니다(이 기기에만 적용).';

  @override
  String get aiProvider => 'AI 제공업체';

  @override
  String get aiProviderInfo =>
      '내 키가 어느 제공업체의 것인지 고르세요. 제공업체별로 키가 따로 저장되므로 다시 돌아와도 입력할 필요가 없습니다.';

  @override
  String get apiKeyFieldLabel => 'API 키';

  @override
  String get getApiKey => '키는 어디서 받나요?';

  @override
  String get recommendedModel => '추천';

  @override
  String get freeTierBadge => '무료 사용량 있음';

  @override
  String get continueWithoutAccount => '계정 없이 계속하기';

  @override
  String get localAccountInfo =>
      '메모가 이 기기에만 남습니다. 다른 곳에서는 열 수 없고, 앱을 지우면 사라지며, 내장 AI는 꺼집니다. 언제든 Google 계정을 연결할 수 있고 메모는 그대로 넘어갑니다.';

  @override
  String get localAccountBadge => '로컬 계정';

  @override
  String get linkGoogleAccount => 'Google 계정 연결';

  @override
  String get accountLinked => 'Google 계정이 연결되었습니다. 이제 메모가 백업됩니다.';

  @override
  String scanReviewPage(int current, int total) {
    return '${current} / ${total}쪽';
  }

  @override
  String get scanRotatePage => '페이지 회전';

  @override
  String get scanDeletePage => '페이지 삭제';

  @override
  String get scanLastPage => '마지막 페이지는 삭제할 수 없습니다';

  @override
  String get scanDiscardTitle => '스캔한 페이지를 버릴까요?';

  @override
  String get scanDiscardConfirm => '버리기';

  @override
  String get scanAdjustCorners => '모서리 조정';

  @override
  String get scanFilterOriginal => '원본';

  @override
  String get scanFilterAuto => '보정';

  @override
  String get scanFilterGray => '회색조';

  @override
  String get scanFilterBw => '흑백';

  @override
  String get scanApplyAll => '전체에 적용';

  @override
  String get scanPageFailed => '페이지를 표시할 수 없습니다';

  @override
  String get scanCropHint =>
      '비뚤어진 페이지는 "모서리 조정"으로 바로잡으세요';

  @override
  String get scanAddAsPdf => 'PDF로 추가';

  @override
  String get scanAddAsImages => '이미지로 추가';

  @override
  String get scanBuildingPdf => 'PDF 준비 중…';

  @override
  String scanOcrProgress(int done, int total) {
    return '텍스트 인식 중… ${done}/${total}';
  }

  @override
  String get scanAutoDetect => '가장자리 자동 인식';

  @override
  String get scanReset => '초기화';

  @override
  String get scanDetecting => '가장자리를 찾는 중…';

  @override
  String get scanAutoFound =>
      '가장자리를 자동으로 찾았습니다. 필요하면 핸들로 미세 조정하세요';

  @override
  String get scanDragHint => '모서리를 종이 가장자리로 끌어다 놓으세요';

  @override
  String get scanApplyCorners => '펴서 적용';

  @override
  String get scanWorking => '펴는 중…';

  @override
  String get scanPdfAdded => '스캔을 PDF 첨부로 메모에 추가했습니다';

  @override
  String get premiumTitle => '프리미엄';

  @override
  String premiumStatusActive(String date) {
    return '프리미엄 사용 중 — ${date}까지';
  }

  @override
  String get premiumStatusFree => '무료 버전을 사용 중입니다';

  @override
  String get premiumPerksTitle => '프리미엄이 되면 무엇이 달라지나요?';

  @override
  String get premiumPerkAi => '하루 AI 포인트';

  @override
  String get premiumPerkAttach => '첨부 파일 크기';

  @override
  String get premiumPerkStorage => '클라우드 저장 공간';

  @override
  String get premiumPerkAuto => '자동 일일 콘텐츠';

  @override
  String get premiumPerkAutoBody =>
      '일일 브리핑과 제안이 매일 자동으로 준비됩니다. 무료 버전에서는 요청할 때만 실행됩니다.';

  @override
  String get premiumHowTitle => '어떻게 이용하나요?';

  @override
  String get premiumHowBody =>
      '프리미엄은 곧 Play 스토어에서 제공될 예정입니다. 현재는 얼리 액세스 단계입니다.';

  @override
  String get premiumByokHint =>
      '자신의 Gemini API 키를 입력하면 AI 기능이 할당량 없이 동작합니다 — 프리미엄과는 무관합니다 (설정 → AI).';

  @override
  String get premiumDiscoverTitle => '놓쳤을지도 모르는 기능';

  @override
  String get discoverScanBody =>
      '스캔한 페이지는 자동으로 펴지고 선명해지며, 한 번만 누르면 검색 가능한 PDF가 됩니다. 텍스트 층은 기기에서 무료로 만들어집니다.';

  @override
  String get discoverSemanticBody =>
      '검색창의 "스마트" 탭은 단어가 아니라 의미로 찾습니다. "항공 시간"이라고 입력하면 여행 메모가 나옵니다.';

  @override
  String get discoverAssistantBody =>
      '홈 화면의 마이크가 말한 내용을 알아서 메모, 목록, 알림으로 바꿔 줍니다. "내일 9시 치과"라고만 말하세요.';

  @override
  String get discoverLockBody =>
      '지문이나 얼굴로 메모를 잠글 수 있습니다. 잠근 메모의 내용은 검색, 위젯, AI로 절대 새어 나가지 않습니다.';

  @override
  String get discoverHiddenBody =>
      '숨긴 폴더의 메모는 홈 화면이나 검색에 전혀 나타나지 않으며, 폴더를 보려면 인증이 필요합니다.';

  @override
  String get discoverExportBody =>
      '모든 메모는 이미지까지 포함해 PDF나 Word로 내보낼 수 있습니다(공유 메뉴).';

  @override
  String get guestSignInUnavailable =>
      'Google 없이 로그인이 현재 꺼져 있습니다: Firebase 콘솔에서 익명 로그인이 사용 설정되지 않았습니다. Google로 로그인하거나 관리자가 사용 설정한 뒤 다시 시도하세요.';

  @override
  String get googleSignInUnavailable =>
      'Google 로그인이 현재 꺼져 있습니다: Firebase 콘솔에서 Google 제공업체가 사용 설정되지 않았습니다.';

  @override
  String get signInNetworkError => '인터넷에 연결할 수 없습니다. 연결을 확인한 뒤 다시 시도하세요.';

  @override
  String get signInCanceled => '로그인이 취소되었습니다.';

  @override
  String get cardRichPreview => '카드에 서식 있는 텍스트 표시';

  @override
  String get cardRichPreviewInfo =>
      '메모의 색상, 형광펜, 굵게, 밑줄이 홈 화면 카드에도 표시됩니다. 끄면 카드에 일반 텍스트만 나옵니다.';

  @override
  String get fontSizeSmall => '작게';

  @override
  String get fontSizeMedium => '보통';

  @override
  String get fontSizeLarge => '크게';

  @override
  String get fontSizeXLarge => '아주 크게';

  @override
  String get appFontSetting => '글꼴';

  @override
  String get appFontInfo =>
      '앱 전체에서 사용하는 글꼴입니다. 메모에 지정한 글꼴이 우선합니다. 모든 글꼴은 앱에 포함되어 있어 인터넷이 필요 없습니다.';

  @override
  String get fontGroupSans => '고딕';

  @override
  String get fontGroupSerif => '명조';

  @override
  String get fontGroupMono => '고정폭';

  @override
  String get fontGroupHand => '손글씨';

  @override
  String get appFontDefaultSuffix => '기본';

  @override
  String get pdfSelectOcrRunning => '텍스트 인식 중…';

  @override
  String get pdfSelectOcrNone => '이 페이지에서 텍스트를 찾지 못했습니다';

  @override
  String pdfSelectCopied(int n) {
    return '${n}자를 복사했습니다';
  }

  @override
  String get bubbleAdd => '메모 말풍선 놓기';

  @override
  String get bubbleAddDone => '말풍선 추가 완료';

  @override
  String get bubbleCollapse => '말풍선 접기';

  @override
  String get bubbleHint => '여기에 메모를 적으세요…';

  @override
  String get bubbleTapToPlace => '말풍선을 놓을 페이지 위치를 누르세요';

  @override
  String get aiModelPodcast => '팟캐스트 낭독';

  @override
  String get listenAiVoice => 'AI 음성으로 듣기';

  @override
  String get listenAiVoiceInfo =>
      '기기 음성 대신 Gemini가 읽어 줍니다. 더 자연스럽지만 문단마다 모델 호출이 필요합니다.';

  @override
  String listenAiVoiceFailed(String error) {
    return 'AI 낭독에 실패했습니다(${error}). 기기 음성으로 읽습니다.';
  }

  @override
  String get ttsSectionTitle => '낭독';

  @override
  String get ttsEngineDevice => '기기 음성';

  @override
  String get ttsEngineAi => 'AI';

  @override
  String get ttsEngineDeviceInfo =>
      '기기에 내장된 음성이 읽어 줍니다. 무료이고 오프라인이며 길이 제한도 없습니다.';

  @override
  String get ttsEngineAiInfo =>
      'Gemini 음성 모델이 읽어 줍니다. 훨씬 자연스럽지만 문단마다 모델 호출이 필요하고 자신의 Gemini 키가 있어야 합니다.';

  @override
  String get ttsEngineAiUnavailable =>
      'AI 음성에는 본인의 Gemini 키가 필요합니다. 추가하기 전까지는 기기 음성으로 읽습니다.';

  @override
  String get ttsModel => '음성 모델';

  @override
  String get ttsVoice => 'AI 목소리';

  @override
  String get shareAsNote => '메모로 공유';

  @override
  String get shareAsNoteInfo =>
      '첨부, 페이지 메모, 그림, 말풍선까지 함께 보냅니다. 상대방도 Not 앱에서 똑같이 엽니다.';

  @override
  String get shareAsNotePreparing => '메모 꾸러미를 준비하는 중…';

  @override
  String get shareAsText => '일반 텍스트로';

  @override
  String get shareAsTextInfo => '메모의 글과 페이지 메모를 다른 앱으로 보냅니다.';

  @override
  String get shareAsTextEmpty => '이 메모에는 공유할 글이 없습니다.';

  @override
  String get sharePdfWithBubbles => '말풍선 포함 PDF로';

  @override
  String get sharePdfWithBubblesInfo =>
      '말풍선, 형광펜, 필기가 PDF 안에 새겨집니다. 누구나 열 수 있고 Not에서는 편집 가능한 상태로 열립니다.';

  @override
  String get sharePdfWithBubblesNone => '이 메모에는 말풍선이나 필기가 있는 PDF가 없습니다.';

  @override
  String get sharePdfWithBubblesPreparing => '말풍선 포함 PDF를 준비하는 중…';

  @override
  String get sharePdfWithBubblesSuffix => ' (말풍선 포함)';

  @override
  String get bubbleStar => '별표';

  @override
  String get bubbleEdit => '말풍선 편집';

  @override
  String get bubbleStarredOnly => '별표만';

  @override
  String get bubbleSearchHint => '말풍선 검색…';

  @override
  String get bubblesOverviewTitle => '말풍선';

  @override
  String get bubblesEmpty =>
      '아직 말풍선이 없습니다. 문서에서 텍스트를 선택해 강조하거나 페이지에 말풍선을 놓아 보세요.';

  @override
  String get bubblesNoMatch => '검색과 일치하는 말풍선이 없습니다.';

  @override
  String get bubbleNoText => '(빈 말풍선)';

  @override
  String get pdfHighlight => '강조';

  @override
  String get pdfHighlightWithNote => '강조 + 메모';

  @override
  String get pageNotesShow => '페이지 메모 보기';

  @override
  String get pageNotesHide => '페이지 메모 숨기기';

  @override
  String get bubbleSave => '저장';

  @override
  String get bubbleTitleHint => '제목';

  @override
  String get bubbleUrgent => '긴급(깜빡임)';

  @override
  String get captureModeQuestion => '메모를 어떻게 열까요?';

  @override
  String get captureModeBubbles => '말풍선';

  @override
  String get captureModeBubblesInfo =>
      '내용이 문서 페이지가 됩니다. 말풍선, 강조, 펜을 쓸 수 있습니다.';

  @override
  String get captureModeClassic => '기본';

  @override
  String get captureModeClassicInfo =>
      '일반 텍스트 메모이며, 내용은 첨부로 들어갑니다.';

  @override
  String get captureModeNew => '새 기능';

  @override
  String get imagePrepareTitle => '이미지 조정';

  @override
  String get imagePrepareDone => '계속';

  @override
  String get imageRotateLeft => '왼쪽으로 회전';

  @override
  String get imageRotateRight => '오른쪽으로 회전';

  @override
  String get videoFrameFailed =>
      '동영상에서 프레임을 가져오지 못했습니다. 기본 메모를 엽니다.';

  @override
  String get bubbleArrowHide => '화살표 숨기기';

  @override
  String get bubbleArrowShow => '화살표 표시';

  @override
  String get speechPitch => '목소리 높낮이';

  @override
  String get speechVoicePickerTitle => '목소리 선택';

  @override
  String get formatRemove => '제거';

  @override
  String get exportTitle => '내보내기';

  @override
  String get exportNotesOption => '메모 텍스트(PDF / Word)';

  @override
  String get exportNotesOptionInfo => '메모의 글과 이미지. 말풍선은 포함되지 않습니다.';

  @override
  String get captureNoteTitle => '메모 제목(선택)';

  @override
  String get captureNoteTitleHint => '새로 만들어지는 문서에도 같은 이름이 붙습니다';

  @override
  String get imageOcrTitle => '이미지 속 문자 인식';

  @override
  String get imageOcrNone => '이 이미지에서 문자를 찾지 못했습니다.';

  @override
  String imageOcrHint(int count) {
    return '$count줄 인식됨 · 탭하여 선택';
  }

  @override
  String imageOcrSelected(int count) {
    return '$count줄 선택됨';
  }

  @override
  String get imageOcrShort => '문자 인식';

  @override
  String get imageOcrWorking => '문자를 인식하는 중…';

  @override
  String get imageOcrSelectHint => '탭: 단어 · 길게 눌러 드래그: 글자 단위';

  @override
  String get imageOcrInsert => '메모에 추가';

  @override
  String get imageOcrZoomIn => '확대';

  @override
  String get imageOcrZoomOut => '축소';

  @override
  String get selectImages => '이미지 선택';

  @override
  String get exportImages => '이미지';

  @override
  String get exportImagesInfo =>
      '왼쪽이나 오른쪽으로 정렬한 좁은 이미지 옆으로 글이 흐릅니다. 가운데 정렬은 전체 너비를 씁니다.';

  @override
  String get exportAlignLeft => '왼쪽';

  @override
  String get exportAlignCenter => '가운데';

  @override
  String get exportAlignRight => '오른쪽';

  @override
  String get exportImageWidth => '너비';

  @override
  String get exportImageLine => '위치';

  @override
  String get aiModelSearch => '모델 검색';

  @override
  String get aiModelOthers => '다른 모델';

  @override
  String get aiModelNoMatch => '일치하는 모델이 없습니다.';

  @override
  String get aiModelAutoInfo => '앱이 가장 알맞은 모델을 순서대로 시도합니다.';

  @override
  String imageOcrCharsSelected(int count) {
    return '$count자 선택됨';
  }

  @override
  String imagesSelectedCount(int count) {
    return '이미지 $count개 선택됨';
  }

  @override
  String attachmentsCopiedCount(int count) {
    return '첨부 $count개';
  }

  @override
  String exportImageLineOf(int count) {
    return '/ $count줄';
  }

  @override
  String get aiModelShowAll => '전체 보기';

  @override
  String get aiModelShowAllInfo => '앱이 사용하지 않는 모델도 함께 보여줍니다.';

  @override
  String get rotateFailed => '이미지를 회전할 수 없습니다.';

  @override
  String get dashboardBackgroundPick => '배경 이미지 선택';

  @override
  String get dashboardBackgroundChange => '배경 이미지 변경';

  @override
  String podcastRenderingAudio(int done, int total) {
    return '오디오 준비 중: ${done}/${total}개';
  }

  @override
  String get podcastExportAudio => '오디오 파일로 내보내기';

  @override
  String get podcastExportAudioCost =>
      '대본 전체를 AI 음성으로 다시 만들어 하나의 WAV 파일로 저장합니다. Gemini 할당량을 사용하며 긴 글에서는 몇 분 걸릴 수 있습니다.';

  @override
  String get podcastShareText => '대본 공유';

  @override
  String get podcastSaveAsNote => '새 메모로 저장';

  @override
  String get podcastSavedAsNote => '팟캐스트 대본을 메모로 저장했습니다.';

  @override
  String get listenPreparingVoice => '오디오 준비 중…';

  @override
  String get appearancePreviewTitle => '예시 텍스트';

  @override
  String get appearancePreviewNoteTitle => '예시 메모 제목';

  @override
  String get appearancePreviewBody =>
      '메모는 이렇게 보입니다. **굵게**, ~밑줄~, ==2:강조== 표시는 이런 모습입니다.';

  @override
  String get appearancePreviewItem => '목록 항목은 이렇게 보입니다';

  @override
  String get convertToText => '텍스트로 변환';

  @override
  String get convertToList => '목록으로 변환';

  @override
  String get convertedToText => '목록을 일반 텍스트로 변환했습니다.';

  @override
  String get convertedToList => '텍스트를 목록으로 변환했습니다.';

  @override
  String get convertToListEmpty => '목록으로 만들 줄이 없습니다.';

  @override
  String get listTwoColumns => '2열';

  @override
  String get listOneColumn => '1열';

  @override
  String get sortItems => '항목 정렬';

  @override
  String get sortStarredFirst => '별표 먼저';

  @override
  String get sortUncheckedFirst => '완료 항목은 마지막에';

  @override
  String get sortAlphabetical => 'A → Z';

  @override
  String get sortAlphabeticalDesc => 'Z → A';

  @override
  String get imagesToAttachments => '이미지를 첨부로 옮기기';

  @override
  String imagesToAttachmentsDone(int count) {
    return '이미지 ${count}개를 첨부로 옮겼습니다.';
  }

  @override
  String get imageOcrShowRecognized => '인식된 텍스트 강조';

  @override
  String get imageOcrHideRecognized => '강조 숨기기';

  @override
  String get bubblePlainMode => '열린 텍스트 상자';

  @override
  String get bubblePlainModeOn => '열린 텍스트 상자가 켜졌습니다';

  @override
  String get bubblePlainTapToPlace => '텍스트를 놓을 위치를 누르세요';

  @override
  String get bubblePlainHint => '눌러서 입력';

  @override
  String get noteSearchTitle => '메모에서 검색';

  @override
  String get noteSearchHint => '이 메모에서 검색…';

  @override
  String get noteSearchEmptyHint =>
      '메모 본문, 항목, 페이지 메모를 즉시 검색합니다. 이미지와 PDF 첨부 안까지 찾으려면 아래 스캔을 시작하세요.';

  @override
  String get noteSearchNoHit => '일치하는 결과가 없습니다.';

  @override
  String get noteSearchScanAttachments => '첨부 스캔';

  @override
  String get noteSearchAskAi => 'AI에게 묻기';

  @override
  String get noteTitleLabel => '제목';

  @override
  String get noteBodyLabel => '메모 본문';

  @override
  String get itemLabel => '항목';

  @override
  String noteSearchAttachmentsInfo(int count) {
    return '첨부 ${count}개를 스캔할 수 있습니다(이미지/PDF).';
  }

  @override
  String noteSearchAttachmentsReady(int count) {
    return '첨부 ${count}개 안에서도 검색합니다.';
  }

  @override
  String pageLabel(int page) {
    return '${page}쪽';
  }

  @override
  String get archiveNotebook => '보관 노트';

  @override
  String get archiveNotebookInfo =>
      '자체 페이지를 갖고 중요한 문서와 이미지의 사본을 보관하는 노트입니다.';

  @override
  String get archivePageImages => '이미지';

  @override
  String get archivePageVideos => '동영상';

  @override
  String get archivePageDocuments => '문서';

  @override
  String get archivePageTexts => '텍스트';

  @override
  String get archiveNewPage => '새 페이지';

  @override
  String get archivePageName => '페이지 이름 (예: 청구서)';

  @override
  String get archivePageEmpty => '이 페이지는 비어 있습니다.';

  @override
  String get archiveSearchHint => '노트에서 검색…';

  @override
  String get archiveAddText => '텍스트 추가';

  @override
  String get archiveAddFile => '파일 추가';

  @override
  String get archiveCopyHere => '보관 노트로 복사';

  @override
  String get archiveNoNotebook =>
      '아직 보관 노트가 없습니다. 먼저 하나 만드세요.';

  @override
  String get archiveNothingToCopy => '이 메모에는 복사할 첨부가 없습니다.';

  @override
  String archiveDeleteEntry(String name) {
    return '노트에서 "${name}"을(를) 삭제할까요? 이 사본은 영원히 사라집니다.';
  }

  @override
  String archiveCopied(int count) {
    return '파일 ${count}개를 보관 노트로 복사했습니다.';
  }

  @override
  String get archiveCaptureTitle => '이미지에서 가져오기';

  @override
  String get archiveCapturePage => '페이지';

  @override
  String get archiveCapturePageInfo =>
      'AI가 제안한 유형입니다. 비워 두면 텍스트 페이지로 들어갑니다.';

  @override
  String get archiveCaptureText => '인식된 텍스트';

  @override
  String get attachmentTagInsert => '본문에 삽입';

  @override
  String get attachmentTagInserted => '첨부 태그를 삽입했습니다.';

  @override
  String get attachmentTagPreview => '첨부 미리보기';

  @override
  String get attachmentTagEdit => '첨부 편집';

  @override
  String archiveCardSummary(int files, int texts) {
    return '파일 ${files}개 · 텍스트 ${texts}개';
  }

  @override
  String get archiveEntryTitle => '제목';

  @override
  String get archiveLinkedFile => '연결된 파일';

  @override
  String get archiveNoLink => '연결된 파일 없음';

  @override
  String get attachmentTagEmbed => '선택 영역에 첨부 삽입';

  @override
  String get attachmentTagNoAttachment =>
      '먼저 메모에 파일을 추가하면 본문에 삽입할 수 있습니다.';

  @override
  String get bubbleModeBubble => '말풍선';

  @override
  String get attachmentTagEmbedInfo =>
      '선택한 텍스트에, 선택한 것이 없으면 커서 위치에 연결됩니다';

  @override
  String get attachmentTagPickText =>
      '이제 연결할 텍스트를 선택한 뒤 "여기에 연결"을 누르세요.';

  @override
  String get attachmentTagLinkHere => '여기에 연결';

  @override
  String attachmentTagPendingBanner(String name) {
    return '${name}이(가) 연결됩니다 — 텍스트를 선택하세요';
  }

  @override
  String get docNameNotesSuffix => '메모';

  @override
  String get docNamePhoto => '사진 메모';

  @override
  String get docNameScan => '스캔 메모';

  @override
  String get docNameImage => '이미지 메모';

  @override
  String get docNameVideo => '동영상 메모';

  @override
  String get folderManage => '폴더 관리';

  @override
  String get folderEmpty => '이 폴더는 비어 있습니다';

  @override
  String get folderEmptyHint =>
      '아래 +로 메모를 추가하거나, 메모를 편집하는 중에 여기로 옮기세요.';

  @override
  String get brainstormTitle => 'AI와 브레인스토밍';

  @override
  String get brainstormRowInfo =>
      'AI가 먼저 개요를 잡고, 그다음 함께 발전시킵니다';

  @override
  String get brainstormIntro =>
      '위의 제목 중 하나를 누르거나 그냥 입력하세요 — 함께 생각해 봅시다.';

  @override
  String get brainstormOutlineTitle => '개요';

  @override
  String get brainstormInputHint => '아이디어를 적거나 질문하세요…';

  @override
  String get brainstormAddIdea => '메모에 추가';

  @override
  String get brainstormAdded => '메모에 추가했습니다';

  @override
  String get folderShared => '이 폴더는 친구와 공유 중입니다';

  @override
  String get friendsTitle => '연락처';

  @override
  String get friendsAdd => '친구 추가';

  @override
  String get friendsEmpty =>
      '아직 아무도 없습니다. 이메일로 친구를 추가하면 폴더를 공유할 수 있습니다.';

  @override
  String get friendsRequestsTitle => '요청';

  @override
  String get friendsListTitle => '내 친구';

  @override
  String get friendsAddEmailHint => 'friend@email.com';

  @override
  String get friendsSendRequest => '요청 보내기';

  @override
  String get friendsRequestSent => '요청을 보냈습니다';

  @override
  String get friendsNotFound =>
      '이 이메일로 등록된 사용자가 없습니다. 상대방이 Google 계정으로 앱을 최소 한 번은 열어야 합니다.';

  @override
  String get friendsSelf => '자신을 친구로 추가할 수 없습니다';

  @override
  String get friendsAlready => '이미 친구입니다';

  @override
  String get friendsDecline => '거절';

  @override
  String get friendsAccept => '수락';

  @override
  String get friendsRemove => '삭제';

  @override
  String get friendsRemoveConfirmTitle => '친구 삭제';

  @override
  String friendsRemoveConfirmBody(Object name) {
    return '${name}을(를) 친구에서 삭제할까요? 공유했던 폴더는 더 이상 보이지 않습니다.';
  }

  @override
  String get friendsNeedsAccount =>
      '연락처와 폴더 공유에는 연결된 Google 계정이 필요합니다.';

  @override
  String get friendsSearchHint => '이름이나 이메일로 검색';

  @override
  String get friendsSearchTab => '검색';

  @override
  String get friendsSearchEmailTab => '이메일로';

  @override
  String get friendsSearchEmpty => '결과 없음';

  @override
  String get friendsSearchTooShort => '검색하려면 2자 이상 입력하세요';

  @override
  String get friendsSearchAdd => '추가';

  @override
  String get folderShare => '공유';

  @override
  String folderShareCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '${count}명과 공유 중',
      one: '1명과 공유 중',
    );
    return '$_temp0';
  }

  @override
  String folderShareTitle(Object name) {
    return '"${name}" 공유';
  }

  @override
  String get folderShareInfo =>
      '선택한 친구에게 초대가 가고, 수락하면 폴더가 보입니다. 권한(읽기 / 쓰기 / 둘 다)은 직접 고릅니다.';

  @override
  String get friendsRowInfo => '친구를 추가하고 폴더를 공유하세요';

  @override
  String get accountRecoverConflictTitle =>
      '이 기기에 저장되지 않은 메모가 있습니다';

  @override
  String accountRecoverConflictBody(Object count) {
    return '이 Google 계정은 이미 다른 세션에 연결되어 있습니다. 전환하면 이 기기의 메모 ${count}개가 숨겨집니다(삭제되지는 않지만 여기서는 볼 수 없습니다). 그래도 계속할까요?';
  }

  @override
  String get accountRecoverConflictProceed => '그래도 전환';
  @override
  String get folderRoleRead => '읽기';

  @override
  String get folderRoleWrite => '쓰기';

  @override
  String get folderRoleBoth => '읽기 + 쓰기';

  @override
  String get folderInvitePending => '초대를 보냈고 답변을 기다리는 중입니다';

  @override
  String get folderWriteOnlyTitle => '쓰기 권한만 있습니다';

  @override
  String get folderWriteOnlyHint => '이 폴더에 새 메모를 넣을 수는 있지만 안에 있는 메모는 볼 수 없습니다.';

  @override
  String get folderChatTitle => '채팅';

  @override
  String get folderChatHint => '메시지를 입력하세요…';

  @override
  String get folderChatSend => '보내기';

  @override
  String get folderChatEmptyTitle => '아직 메시지가 없습니다';

  @override
  String get folderChatEmptyHint => '이 폴더를 공유한 사람들과 여기서 이야기하세요.';

  @override
  String get folderInviteTitle => '폴더 초대';

  @override
  String folderInviteBody(Object name) {
    return '"${name}" 폴더가 공유되었습니다.';
  }

  @override
  String get folderInviteAccepted => '폴더를 추가했습니다';

  @override
  String get folderInviteDeclined => '초대를 거절했습니다';

  @override
  String friendRequestBanner(Object name) {
    return '${name}님이 친구 요청을 보냈습니다';
  }

  @override
  String get friendRequestAccepted => '친구를 추가했습니다';

  @override
  String get sendNoteAction => '친구에게 보내기';

  @override
  String get sendNoteTitle => '친구에게 메모 보내기';

  @override
  String get sendNoteInfo => '메모 사본이 상대방의 "받은 메모" 보관함에 도착합니다. 첨부(이미지, 문서, 오디오)는 전송되지 않습니다.';

  @override
  String sendNoteSent(Object name) {
    return '${name}에게 메모를 보냈습니다';
  }

  @override
  String get inboxTitle => '받은 메모';

  @override
  String get inboxEmpty => '받은 메모가 없습니다';

  @override
  String get inboxEmptyHint => '친구가 보낸 메모가 여기에 모입니다.';

  @override
  String inboxFrom(Object name) {
    return '보낸 사람: ${name}';
  }

  @override
  String get inboxAccept => '내 메모에 추가';

  @override
  String get inboxAccepted => '메모를 내 메모에 추가했습니다';

  @override
  String get folderShelfExpand => '폴더 펼치기';

  @override
  String get folderShelfCollapse => '폴더 접기';

  @override
  String get accountSheetLocalInfo => '메모가 이 기기에만 있습니다. Google 계정을 연결하면 백업하고 친구도 추가할 수 있습니다.';

  @override
  String get accountSettings => '계정 설정';
}
