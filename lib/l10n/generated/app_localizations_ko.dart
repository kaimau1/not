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
  String get attachmentUploading => '업로드 중...';

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
    return 'Asistan \"$title\" notunu çöp kutusuna taşımak istiyor. Onaylıyor musun?';
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
  String get aiModelDocument => '팟캐스트와 문서 대화';

  @override
  String get aiModelTranslate => '번역';

  @override
  String get aiModelVoice => '음성 메모';

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
    return 'Sayfa $current / $total';
  }

  @override
  String get scanRotatePage => 'Sayfayı döndür';

  @override
  String get scanDeletePage => 'Sayfayı sil';

  @override
  String get scanLastPage => 'Son sayfa silinemez';

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
}
