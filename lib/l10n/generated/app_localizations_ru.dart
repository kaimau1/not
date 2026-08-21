// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'Заметки';

  @override
  String get loginTagline => 'Ваши заметки на всех устройствах';

  @override
  String get signInWithGoogle => 'Войти через Google';

  @override
  String loginError(String error) {
    return 'Не удалось войти: $error';
  }

  @override
  String get searchHint => 'Поиск по заметкам...';

  @override
  String get filterAll => 'Все';

  @override
  String get filterText => 'Текст';

  @override
  String get filterChecklist => 'Список';

  @override
  String get filterOrdered => 'Нумерованный';

  @override
  String get filterPinned => 'Закреплённые';

  @override
  String get filterStarred => 'Избранные';

  @override
  String get star => 'В избранное';

  @override
  String get unstar => 'Убрать из избранного';

  @override
  String editedAt(String date) {
    return 'Изменено: $date';
  }

  @override
  String get sectionPinned => 'Закреплённые';

  @override
  String get sectionOthers => 'Остальные';

  @override
  String get emptyNotes => 'Заметок пока нет';

  @override
  String get emptyNotesHint => 'Нажмите +, чтобы создать первую заметку';

  @override
  String get emptySearch => 'Ничего не найдено';

  @override
  String get newTextNote => 'Текстовая заметка';

  @override
  String get newChecklist => 'Список';

  @override
  String get newOrderedList => 'Нумерованный список';

  @override
  String get noteDeleted => 'Заметка удалена';

  @override
  String notesDeletedCount(int count) {
    return 'Удалено заметок: $count';
  }

  @override
  String selectedCount(int count) {
    return 'Выбрано: $count';
  }

  @override
  String get deleteSelected => 'Удалить выбранные';

  @override
  String get undo => 'Отменить';

  @override
  String get redo => 'Повторить';

  @override
  String get titleHint => 'Заголовок';

  @override
  String get bodyHint => 'Заметка...';

  @override
  String get newItemHint => 'Новый пункт';

  @override
  String moreItemsCount(int count) {
    return '+$count других пунктов';
  }

  @override
  String get addAttachment => 'Добавить';

  @override
  String get addAttachmentMore => 'Другие типы вложений…';

  @override
  String get addImage => 'Добавить изображение';

  @override
  String get addPdf => 'Добавить PDF';

  @override
  String get addSlide => 'Добавить слайды';

  @override
  String get pasteImage => 'Вставить изображение из буфера обмена';

  @override
  String get clipboardEmpty => 'В буфере обмена нет изображения';

  @override
  String get noNoteSelected => 'Выберите заметку слева';

  @override
  String attachmentFailed(String error) {
    return 'Не удалось добавить вложение: $error';
  }

  @override
  String get attachmentCopying => 'Копирование...';

  @override
  String get attachmentUploading => 'Загрузка...';

  @override
  String get attachmentUploadFailed =>
      'Не удалось загрузить — нажмите, чтобы повторить';

  @override
  String get attachmentNotSynced =>
      'Этот файл ещё не синхронизирован на этом устройстве';

  @override
  String attachmentTooLarge(int limit) {
    return 'Файл слишком большой (не больше $limit МБ)';
  }

  @override
  String storageFull(String limit) {
    return 'Хранилище заполнено ($limit). Удалите старые вложения, чтобы освободить место.';
  }

  @override
  String get storageUsage => 'Хранилище';

  @override
  String storageUsageValue(String used, String limit) {
    return 'Использовано $used из $limit';
  }

  @override
  String get removeAttachment => 'Удалить вложение';

  @override
  String get pin => 'Закрепить';

  @override
  String get unpin => 'Открепить';

  @override
  String get delete => 'Удалить';

  @override
  String get color => 'Цвет';

  @override
  String get aiTitle => 'ИИ';

  @override
  String get aiSummarize => 'Кратко изложить заметку';

  @override
  String get aiAnalyze => 'Проанализировать';

  @override
  String get aiSectionNote => 'Эта заметка';

  @override
  String get aiSectionAttachments => 'Вложения';

  @override
  String get summarize => 'Кратко изложить';

  @override
  String get summaryDetailTitle => 'Тип пересказа';

  @override
  String get summaryShort => 'Краткий пересказ';

  @override
  String get summaryShortInfo =>
      'Несколько предложений обзора плюс ключевые пункты';

  @override
  String get summaryDetailed => 'Подробный пересказ';

  @override
  String get summaryDetailedInfo =>
      'Достаточно полный, чтобы не открывать оригинал';

  @override
  String get listen => 'Слушать';

  @override
  String get ask => 'Задать вопрос';

  @override
  String get extractText => 'Извлечь текст';

  @override
  String get transcribe => 'Расшифровать';

  @override
  String get listenToNote => 'Прочитать вслух';

  @override
  String get aiNoApiKey => 'Сначала введите ключ API Gemini в настройках';

  @override
  String aiError(String error) {
    return 'Запрос к ИИ не удался: $error';
  }

  @override
  String get aiSummaryTitle => 'Пересказ от ИИ';

  @override
  String get aiThinking => 'Думаю...';

  @override
  String get copy => 'Копировать';

  @override
  String get copied => 'Скопировано';

  @override
  String get settingsSearchHint => 'Поиск настроек — «брифинг», «микрофон»';

  @override
  String settingsSearchEmpty(String query) {
    return 'Настройки по запросу «$query» не найдены';
  }

  @override
  String get settings => 'Настройки';

  @override
  String get settingsAppearance => 'Внешний вид';

  @override
  String get themeSystem => 'Системная';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get settingsAi => 'ИИ';

  @override
  String get geminiApiKey => 'Ключ API Gemini';

  @override
  String get geminiApiKeyHint => 'Вставьте ключ, начинающийся с AIza...';

  @override
  String get geminiApiKeyInfo =>
      'Ключ необязателен: без него запросы к ИИ идут через встроенный сервис приложения (бесплатный дневной лимит, больше с Premium). Для неограниченного использования со своим ключом получите его бесплатно на aistudio.google.com; ключ хранится только на этом устройстве, в защищённом хранилище.';

  @override
  String aiBuiltInPremium(int count) {
    return 'Встроенный ИИ: Premium — осталось баллов сегодня: $count';
  }

  @override
  String aiBuiltInRemaining(int count) {
    return 'Встроенный ИИ: осталось бесплатных баллов сегодня: $count';
  }

  @override
  String get aiBuiltInByok => 'Со своим ключом — без ограничений';

  @override
  String get aiReport => 'Пожаловаться на этот ответ';

  @override
  String get aiReportThanks => 'Жалоба получена, спасибо';

  @override
  String get privacyPolicyTitle => 'Политика конфиденциальности';

  @override
  String get lockNote => 'Заблокировать';

  @override
  String get unlockNote => 'Разблокировать';

  @override
  String get lockedNote => 'Заблокированная заметка';

  @override
  String get unlockAuthReason =>
      'Подтвердите личность, чтобы открыть заблокированную заметку';

  @override
  String get exportBackup => 'Экспортировать резервную копию (JSON)';

  @override
  String get expandListItems => 'Показывать строки целиком';

  @override
  String get expandListItemsInfo =>
      'Длинные пункты переносятся на несколько строк и остаются полностью видимыми. Если выключено, пункт занимает одну строку и разворачивается по нажатию.';

  @override
  String get quickCaptureRowSetting => 'Строка быстрой заметки';

  @override
  String get quickCaptureRowInfo =>
      'Показывает строку «Новая заметка...» вверху экрана. Если выключено, используйте кнопку +.';

  @override
  String get emptyTrash => 'Очистить корзину';

  @override
  String emptyTrashConfirm(int count) {
    return 'Заметок будет удалено безвозвратно: $count. Это действие нельзя отменить. Вы уверены?';
  }

  @override
  String get trashEmptied => 'Корзина очищена';

  @override
  String get validateAndSave => 'Проверить и сохранить';

  @override
  String get clear => 'Очистить';

  @override
  String get aiDiagnostics => 'Диагностика ИИ';

  @override
  String get aiDiagnosticsEmpty => 'Ошибок не зафиксировано';

  @override
  String aiDiagnosticsCount(int count) {
    return 'Последние записи об ошибках: $count';
  }

  @override
  String get apiKeyValid => 'Ключ API проверен и сохранён';

  @override
  String get apiKeyInvalid => 'Ключ API недействителен';

  @override
  String get apiKeySavedBadge => 'Сохранён';

  @override
  String get removeApiKey => 'Удалить ключ';

  @override
  String get refresh => 'Обновить';

  @override
  String get account => 'Аккаунт';

  @override
  String get signOut => 'Выйти';

  @override
  String get signOutConfirm => 'Вы действительно хотите выйти?';

  @override
  String get signOutAnonymousWarning =>
      'Вы используете локальный аккаунт: после выхода этот аккаунт и ВСЕ заметки станут навсегда недоступны — без резервной копии их не вернуть. Сначала привяжите аккаунт Google. Всё равно выйти?';

  @override
  String get deleteAccount => 'Удалить мой аккаунт и данные';

  @override
  String get deleteAccountWarning =>
      'Это нельзя отменить: все ваши заметки, вложения и аккаунт будут удалены безвозвратно. Продолжить?';

  @override
  String get deleteAccountConfirm => 'Удалить безвозвратно';

  @override
  String get licensesTitle => 'Лицензии открытого кода';

  @override
  String get generating => 'Создание...';

  @override
  String get retry => 'Повторить';

  @override
  String get cancel => 'Отмена';

  @override
  String get close => 'Закрыть';

  @override
  String get ok => 'ОК';

  @override
  String get syncPending => 'Ожидание синхронизации';

  @override
  String get synced => 'Синхронизировано';

  @override
  String genericError(String error) {
    return 'Что-то пошло не так: $error';
  }

  @override
  String get addTag => 'Метка';

  @override
  String get tagHint => 'например: работа, дом, учёба';

  @override
  String get addReminder => 'Напомнить';

  @override
  String get share => 'Поделиться';

  @override
  String get archive => 'В архив';

  @override
  String get unarchive => 'Из архива';

  @override
  String get archiveTitle => 'Архив';

  @override
  String get archiveEmpty => 'В архиве нет заметок';

  @override
  String get trashTitle => 'Корзина';

  @override
  String get trashEmpty => 'Корзина пуста';

  @override
  String get trashInfo =>
      'Удалённые заметки остаются здесь; их можно восстановить или удалить окончательно.';

  @override
  String get restore => 'Восстановить';

  @override
  String get deleteForever => 'Удалить безвозвратно';

  @override
  String get deleteForeverConfirm =>
      'Эта заметка будет удалена безвозвратно. Вы уверены?';

  @override
  String assistantDeleteConfirm(String title) {
    return 'Ассистент хочет переместить заметку «${title}» в корзину. Подтверждаете?';
  }

  @override
  String get recordAudio => 'Голосовая запись';

  @override
  String get recording => 'Идёт запись...';

  @override
  String get stopAndSave => 'Завершить и добавить';

  @override
  String get micPermissionDenied => 'В доступе к микрофону отказано';

  @override
  String get speechRecognitionFailed =>
      'Распознавание речи не сработало. Проверьте, выдано ли разрешение на микрофон и обновлено ли приложение Google.';

  @override
  String get addDrawing => 'Добавить рисунок';

  @override
  String get drawingTitle => 'Рисунок';

  @override
  String get addToNote => 'Добавить в заметку';

  @override
  String get chatTitle => 'Ассистент заметок';

  @override
  String get chatHint =>
      'Спросите о своих заметках: «что за рецепт я записал на прошлой неделе?», «чего не хватает в списке покупок?»';

  @override
  String get chatInputHint => 'Введите вопрос...';

  @override
  String get fontSize => 'Размер текста';

  @override
  String get fontSizePreview => 'Ваши заметки будут выглядеть так';

  @override
  String get darkSchedule => 'Расписание тёмной темы';

  @override
  String get darkScheduleInfo =>
      'Переключается на тёмную тему между заданными часами';

  @override
  String get aiTranslate => 'Перевести';

  @override
  String get voiceCommand => 'Голосовая команда';

  @override
  String get semanticSearchToggle => 'Смысловой поиск с ИИ';

  @override
  String get semanticSearchHint => 'Поиск по смыслу: «расходы на машину»...';

  @override
  String get briefingTitle => 'Сводка дня';

  @override
  String get briefingLoading => 'Готовим вашу сводку...';

  @override
  String get briefingEmpty => 'На сегодня ничего нет';

  @override
  String get briefingSetting => 'Уведомление со сводкой дня';

  @override
  String get briefingSettingInfo =>
      'Каждое утро получайте уведомление со сводкой дня в выбранное вами время';

  @override
  String get autoTagSetting => 'Ставить метки автоматически';

  @override
  String get autoTagSettingInfo =>
      'Когда заметка закрывается без меток, ИИ добавляет подходящую';

  @override
  String get suggestTags => 'Предложить метки';

  @override
  String get aiFixNote => 'Привести заметку в порядок';

  @override
  String get fixLevelTitle => 'Насколько править?';

  @override
  String get fixSimple => 'Слегка';

  @override
  String get fixSimpleInfo => 'Только орфография и опечатки';

  @override
  String get fixBalanced => 'Умеренно';

  @override
  String get fixBalancedInfo =>
      'Ещё и структура предложений, чтобы текст стал чище';

  @override
  String get fixDetailed => 'Основательно';

  @override
  String get fixDetailedInfo => 'Переписывает весь текст от начала до конца';

  @override
  String get existingTagsLabel => 'Прежние метки';

  @override
  String get aiSkipCheckedSetting =>
      'Не трогать отмеченные пункты при правках ИИ';

  @override
  String get aiSkipCheckedInfo =>
      'Когда ИИ правит или переводит список, выполненные (отмеченные) пункты остаются ровно такими, как есть; изменяются только неотмеченные.';

  @override
  String get noteUpdatedUndo => 'Заметка обновлена';

  @override
  String get aiImprove => 'Улучшить заметку';

  @override
  String get improveFormal => 'Сделать официальнее';

  @override
  String get improveShorten => 'Сократить';

  @override
  String get improveBullets => 'Превратить в маркированный список';

  @override
  String get improveNumbered => 'Превратить в нумерованный список';

  @override
  String get replaceNote => 'Заменить заметку';

  @override
  String get openAsNewNote => 'Как новую заметку';

  @override
  String get pdfChatHint =>
      'Спросите об этом PDF: «перескажи», «есть ли штрафная оговорка?», «какой срок?»';

  @override
  String get pdfChatInputHint => 'Введите вопрос о PDF...';

  @override
  String get voiceCaptureHint =>
      'Говорите: «купить молоко и хлеб» или «завтра встреча в 9, напомни» — ИИ составит заметку, когда вы закончите.';

  @override
  String get voiceFinish => 'Готово';

  @override
  String get voiceProcessing => 'Обрабатываем сказанное...';

  @override
  String get voiceNothingHeard => 'В записи не обнаружено речи';

  @override
  String get voiceNoteSaved => 'Ваша голосовая заметка сохранена';

  @override
  String get openNote => 'Открыть заметку';

  @override
  String get remindersTitle => 'Напоминания';

  @override
  String get remindersEmpty => 'Напоминаний нет';

  @override
  String get remindersEmptyHint =>
      'Добавьте напоминание к заметке или создайте новую заметку с напоминанием через кнопку +';

  @override
  String get remindersUpcoming => 'Предстоящие';

  @override
  String get remindersPast => 'Прошедшие';

  @override
  String get reminderInPast =>
      'Выбранное время уже прошло — выберите время в будущем.';

  @override
  String get newReminder => 'Новое напоминание';

  @override
  String get remindersUntitled => 'Заметка без заголовка';

  @override
  String get remindersEdit => 'Изменить время';

  @override
  String get remindersRemove => 'Удалить напоминание';

  @override
  String get aiModelChat => 'Пересказы, заголовки, метки и чат';

  @override
  String get aiModelDocument => 'Чат по документу и конспект PDF';

  @override
  String get aiModelTranslate => 'Перевод';

  @override
  String get aiModelVoice => 'Голосовой ассистент заметок';

  @override
  String get aiModelAuto => 'Автоматически (рекомендуется)';

  @override
  String get aiModelsInfo =>
      'Для каждой задачи можно выбрать свою модель: с короткими текстами справится быстрая, для длинных документов нужна помощнее. Если выбранная модель исчерпает лимит или будет отключена, автоматически пробуется следующая.';

  @override
  String get clearNote => 'Очистить';

  @override
  String get clearNoteConfirm =>
      'Содержимое заметки (текст и пункты списка) будет удалено. Вы уверены?';

  @override
  String get themePaper => 'Бумага';

  @override
  String get calculatorTitle => 'Калькулятор';

  @override
  String get calcExpressionHint => 'например: 12,5×3+40';

  @override
  String get calcInvalid => 'Некорректное выражение';

  @override
  String get liveDictation => 'Диктовать';

  @override
  String get dictationListening => 'Слушаю... текст появляется по мере речи';

  @override
  String get dictationNoKeyInfo =>
      'Диктовка в реальном времени на этом устройстве недоступна; запись будет расшифрована целиком, когда вы остановитесь.';

  @override
  String get dictationHoldHint =>
      'Удерживайте микрофон и говорите; текст запишется, когда отпустите';

  @override
  String itemsSelected(int count) {
    return 'Выбрано пунктов: $count';
  }

  @override
  String get noteChatTitle => 'Чат с этой заметкой';

  @override
  String get noteChatHint => 'Спросите что-нибудь об этой заметке';

  @override
  String get noteChatIntro =>
      'Читается содержимое заметки и её вложения (PDF/изображение), и ответ на ваш вопрос берётся из них.';

  @override
  String get dictationProcessing => 'Расшифровка...';

  @override
  String get aiDailyManualInfo =>
      'На бесплатном тарифе это не создаётся автоматически и не расходует ваш дневной лимит. Вы можете создать это раз в день кнопкой ниже.';

  @override
  String get aiGenerate => 'Создать';

  @override
  String get aiGeneratedTodayInfo =>
      'Это создано сегодня. На бесплатном тарифе обновляется раз в день; создать заново можно будет завтра.';

  @override
  String get voiceAssistantTitle => 'Ассистент голосовых заметок';

  @override
  String get voiceListening => 'Слушаю...';

  @override
  String get voiceHoldHint =>
      'Удерживайте и говорите; заметка создастся, когда отпустите';

  @override
  String get voiceTapHint =>
      'Нажмите и говорите; нажмите ещё раз, чтобы закончить';

  @override
  String get voiceTooShort => 'Запись слишком короткая, попробуйте ещё раз';

  @override
  String get voiceModeSetting => 'Как это работает';

  @override
  String get voiceModeHold => 'Удерживать для речи';

  @override
  String get voiceModeTap => 'Нажать для старта / нажать для остановки';

  @override
  String get voiceModeInfo =>
      'Удерживать для речи: слушает, пока вы держите кнопку, и создаёт заметку, когда отпускаете. Нажать для старта: одно нажатие начинает запись, второе её завершает.';

  @override
  String get voiceHeardLive => 'Речь обнаружена';

  @override
  String get voiceCaptureReady => 'Голос готов';

  @override
  String get voiceCaptureEditHint => 'Нажмите на текст, чтобы изменить';

  @override
  String voiceCapturePunctuation(String language) {
    return '$language · автопунктуация';
  }

  @override
  String get voiceCaptureAddToNote => 'Добавить в заметку';

  @override
  String get voiceCaptureCreateNote => 'Создать новую заметку';

  @override
  String get voiceCaptureAiNote => 'ИИ-заметка';

  @override
  String get voiceCapturePlainNote => 'Обычная заметка';

  @override
  String get voiceCloseTitle => 'Ваша запись сохранена';

  @override
  String get voiceCloseKeepTalking => 'Продолжить говорить';

  @override
  String get voiceCaptureRestart => 'Записать снова';

  @override
  String get voiceChipSummarizeAdd => 'Добавить как резюме';

  @override
  String get voiceChipSummarizeSave => 'Сохранить как резюме';

  @override
  String get voiceChipToItems => 'Разбить на пункты';

  @override
  String get voiceChipAsList => 'Преобразовать в список';

  @override
  String get voiceChipFix => 'Исправить';

  @override
  String get voiceChipCompose => 'Пусть напишет ассистент';

  @override
  String get editorToolList => 'Список';

  @override
  String get permissionsTitle => 'Разрешения';

  @override
  String get permMic => 'Микрофон';

  @override
  String get permMicInfo => 'Нужен для голосовых заметок и диктовки';

  @override
  String get permNotifications => 'Уведомления';

  @override
  String get permNotificationsInfo => 'Нужны для напоминаний и сводки дня';

  @override
  String get permBattery => 'Оптимизация батареи';

  @override
  String get permBatteryInfo =>
      'Освободите приложение от ограничений батареи, чтобы напоминания приходили вовремя';

  @override
  String get showTagChips => 'Показывать чипсы меток';

  @override
  String get showFolderChips => 'Показывать чипсы папок';

  @override
  String videoTooBigForAi(int mb) {
    return 'Видео слишком большое для отправки в ИИ ($mb МБ). Запишите покороче.';
  }

  @override
  String get permCamera => 'Камера';

  @override
  String get permCameraInfo => 'Нужна для видеозаметок и съёмки фото';

  @override
  String get permOnboardTitle => 'Прежде чем начать';

  @override
  String get permOnboardInfo =>
      'Заметки запрашивают эти разрешения только тогда, когда вы пользуетесь соответствующей функцией. Их можно выдать сейчас ниже или изменить позже в разделе «Настройки > Разрешения».';

  @override
  String get permOnboardGrantAll => 'Выдать разрешения';

  @override
  String get permOnboardSkip => 'Не сейчас';

  @override
  String get newVideoNote => 'Видеозаметка';

  @override
  String get videoLocalOnly =>
      'Это видео хранится только на этом устройстве (в облако не загружается)';

  @override
  String get videoToNote => 'Сделать заметку из видео';

  @override
  String get videoToNoteRunning => 'Просматриваем видео…';

  @override
  String get permGranted => 'Выдано';

  @override
  String get permGrant => 'Выдать';

  @override
  String get permOpenSettings => 'Открыть настройки';

  @override
  String get newHandwriting => 'Рукописный ввод';

  @override
  String get newVoiceCapture => 'Голосовая заметка';

  @override
  String get suggestTitle => 'Предложить заголовок';

  @override
  String get noteMetaMenu => 'Метка · Заголовок · Напоминание';

  @override
  String get folder => 'Папка';

  @override
  String get noFolder => 'Без папки';

  @override
  String get newFolder => 'Новая папка';

  @override
  String get editFolder => 'Изменить папку';

  @override
  String get deleteFolder => 'Удалить папку';

  @override
  String deleteFolderConfirm(String name) {
    return 'Папка «$name» будет удалена. Заметки внутри не удаляются — они просто останутся без папки.';
  }

  @override
  String get folderNameHint => 'Название папки';

  @override
  String get folderIcon => 'Значок';

  @override
  String get editFilters => 'Изменить фильтры';

  @override
  String get editFiltersInfo =>
      'Выберите, какие фильтры показывать на главном экране. Скрытые фильтры делают страницу опрятнее.';

  @override
  String get select => 'Выбрать';

  @override
  String get noteArchived => 'Заметка в архиве';

  @override
  String deleteChecked(int count) {
    return 'Удалить отмеченные ($count)';
  }

  @override
  String get removeItem => 'Удалить пункт';

  @override
  String get copyWholeNote => 'Скопировать заметку целиком';

  @override
  String get allCopied => 'Вся заметка скопирована в буфер обмена';

  @override
  String get speechPlay => 'Прочитать вслух';

  @override
  String get speechPause => 'Пауза';

  @override
  String get speechResume => 'Продолжить';

  @override
  String get speechStop => 'Стоп';

  @override
  String get speechRate => 'Скорость чтения';

  @override
  String get speechSystemDefault => 'Системное значение';

  @override
  String get speechNoVoices =>
      'На этом устройстве не установлено ни одного голоса';

  @override
  String speechVoiceLanguage(String language) {
    return 'Голос: $language';
  }

  @override
  String get speechVoiceAutoInfo =>
      'Другие языки автоматически читаются мужским голосом';

  @override
  String get listening => 'Слушаю...';

  @override
  String get listenPlay => 'Слушать';

  @override
  String get listenReadingPdf => 'Читаем документ...';

  @override
  String get listenConvertWithAi => 'Преобразовать с ИИ';

  @override
  String get listenMakePodcast => 'Полный подкаст';

  @override
  String get listenMakePodcastSummary => 'Подкаст-пересказ';

  @override
  String get listenOriginalText => 'Исходный текст';

  @override
  String get listenPodcastReady => 'Озвучка подкаста готова';

  @override
  String get listenPodcastCached => 'Создано ранее — токены не потрачены';

  @override
  String get listenRegenerate => 'Создать заново';

  @override
  String get listenNoText =>
      'Из этого документа не удалось получить читаемый текст. У отсканированного PDF нет текстового слоя, а презентация может содержать только изображения.';

  @override
  String get readDocument => 'Прочитать документ (Word, PDF, слайды)';

  @override
  String get readDocUnsupported => 'Этот тип файла прочитать нельзя.';

  @override
  String get exportPdf => 'Экспортировать в PDF';

  @override
  String get pdfTitleField => 'Заголовок';

  @override
  String get pdfContentField => 'Содержимое';

  @override
  String get pdfMarkupHint =>
      'Знаки в начале строки превращаются в форматирование: [x] и [ ] — флажки, 1. — нумерованный список, - — маркер.';

  @override
  String get pdfIncludeDate => 'Включить дату';

  @override
  String get exportIncludeImages => 'Включить изображения';

  @override
  String get exportWord => 'Поделиться как Word (.docx)';

  @override
  String get pdfPreview => 'Предпросмотр';

  @override
  String get largeAttachmentTitle => 'Большой файл';

  @override
  String largeAttachmentBody(String size) {
    return 'Размер файла — $size МБ. PDF нельзя сжать; он будет загружен как есть и займёт место в вашем хранилище. Продолжить?';
  }

  @override
  String get speechRateForeign => 'Скорость для иностранного языка';

  @override
  String notesArchivedCount(int count) {
    return 'Заметок отправлено в архив: $count';
  }

  @override
  String get backgroundColor => 'Цвет фона';

  @override
  String get backgroundColorInfo => 'Цвет фона заметки';

  @override
  String get frameColor => 'Рамка';

  @override
  String get frameColorInfo => 'Рисует вокруг заметки рамку выбранного цвета';

  @override
  String get sortBy => 'Сортировка';

  @override
  String get reorderNotes => 'Изменить порядок заметок';

  @override
  String get reorderModeActive =>
      'Перетаскивайте карточки, чтобы изменить порядок';

  @override
  String get reorderDone => 'Готово';

  @override
  String get sortManual => 'Вручную (перетаскиванием)';

  @override
  String get sortUpdated => 'Недавно изменённые';

  @override
  String get sortCreated => 'Дата создания';

  @override
  String get sortTitle => 'По заголовку (А–Я)';

  @override
  String get foldersSection => 'Папки';

  @override
  String get tagsSection => 'Метки';

  @override
  String get expandFilters => 'Развернуть фильтры';

  @override
  String get collapseFilters => 'Свернуть фильтры';

  @override
  String get settingsLanguage => 'Язык';

  @override
  String get languageSystem => 'Язык системы';

  @override
  String get settingsSpeech => 'Чтение вслух';

  @override
  String get aiAdvanced => 'Дополнительно: модель и ключ API';

  @override
  String get aiAdvancedInfo =>
      'Выбор модели и ваш собственный ключ Gemini. Большинству это не нужно.';

  @override
  String get openBriefing => 'Открыть сводку';

  @override
  String get syncTitle => 'Синхронизация';

  @override
  String get syncLimitTitle => 'Предел автозагрузки';

  @override
  String get syncLimitInfo =>
      'Вложения больше этого размера остаются на устройстве и не загружаются. Текст заметок синхронизируется всегда.';

  @override
  String get syncLimitUnlimited => 'Без предела';

  @override
  String get backupTitle => 'Резервная копия';

  @override
  String get importBackup => 'Восстановить из резервной копии (JSON)';

  @override
  String importBackupDone(int count) {
    return 'Восстановлено заметок: $count';
  }

  @override
  String get importBackupInvalid => 'Некорректный файл резервной копии';

  @override
  String get aiHubTitle => 'ИИ';

  @override
  String get aiSummarizeInfo => 'Даёт краткий пересказ';

  @override
  String get aiAnalyzeInfo => 'Перечисляет ключевые пункты и задачи';

  @override
  String get aiImproveInfo => 'Меняет стиль: официально, короче или списком';

  @override
  String get aiTranslateInfo => 'Переводит заметку на выбранный язык';

  @override
  String get aiFixNoteInfo => 'Исправляет орфографию и пунктуацию';

  @override
  String get moveToFolder => 'Переместить в папку';

  @override
  String get voiceAssistantBadge => 'Ассистент';

  @override
  String get assistantGenericError =>
      'Что-то пошло не так — попробуете ещё раз?';

  @override
  String get quickAddTooltip => 'Новая заметка — выберите тип';

  @override
  String get autoTitleSetting => 'Предлагать заголовок при закрытии';

  @override
  String get autoTitleSettingInfo =>
      'Когда вы выходите из редактора, заметка, оставшаяся без заголовка, получает короткий заголовок, составленный по её содержимому.';

  @override
  String get hubChatInfo => 'Ответы на основе ваших заметок';

  @override
  String get hubBriefingInfo =>
      'Ваш день с одного взгляда: напоминания и недавние заметки';

  @override
  String get hubReadInfo => 'Послушайте документ PDF или Word';

  @override
  String get annotate => 'Пометки';

  @override
  String get annotateDone => 'Завершить пометки';

  @override
  String get newPdfNote => 'Добавить PDF и делать заметки';

  @override
  String get imageNotePreparing => 'Изображения собираются в документ…';

  @override
  String get newImageNote => 'Добавить изображение и делать заметки';

  @override
  String get pdfPageNoteHint => 'Заметка к этой странице…';

  @override
  String pdfPage(int page) {
    return 'Страница ${page}';
  }

  @override
  String pdfPageOf(int page, int total) {
    return 'Страница ${page} / ${total}';
  }

  @override
  String get pdfPreviousPage => 'Предыдущая страница';

  @override
  String get pdfNextPage => 'Следующая страница';

  @override
  String get pdfFullScreen => 'Открыть во весь экран';

  @override
  String get pdfNoDocument => 'В этой заметке пока нет PDF';

  @override
  String get pdfChooseDocument => 'Выбрать PDF';

  @override
  String get newSlidesNote => 'Добавить слайды и делать заметки';

  @override
  String get slidesNoDocument => 'В этой заметке пока нет презентации';

  @override
  String get slidesChooseDocument => 'Выбрать презентацию';

  @override
  String get pdfEditPages => 'Редактировать страницы';

  @override
  String get pdfDeletePages => 'Удалить выбранные страницы';

  @override
  String get pdfAddBlankPage => 'Добавить пустую страницу';

  @override
  String get pdfRotatePages => 'Повернуть';

  @override
  String get pdfBurnInk => 'Впечатать рукописные пометки в документ';

  @override
  String get pdfApplyChanges => 'Применить изменения';

  @override
  String get pdfCannotDeleteAllPages => 'Нельзя удалить все страницы';

  @override
  String get pdfPagesHint =>
      'Нажмите на страницу, чтобы выбрать её. Заметки к страницам следуют за своей страницей; заметка удалённой страницы скрывается, но сохраняется в ваших данных.';

  @override
  String pdfEditFailed(String error) {
    return 'Не удалось изменить PDF: ${error}';
  }

  @override
  String get pdfInkBurned => 'Рукописные пометки впечатаны в документ';

  @override
  String get pdfAllPageNotes => 'Все заметки к страницам';

  @override
  String get pdfNoPageNotes =>
      'Заметок к страницам пока нет. Перейдите на страницу и напишите в поле ниже.';

  @override
  String get crop => 'Обрезать';

  @override
  String get cropApply => 'Применить обрезку';

  @override
  String get cropReset => 'Сбросить выделение';

  @override
  String get cropHint =>
      'Перетаскивайте углы, чтобы выбрать область. Обрезку нельзя отменить.';

  @override
  String get cropFailed => 'Не удалось обрезать изображение.';

  @override
  String get penBallpoint => 'Шариковая ручка';

  @override
  String get penMarker => 'Маркер';

  @override
  String get penHighlighter => 'Текстовыделитель';

  @override
  String get eraser => 'Ластик';

  @override
  String get inkArrow => 'Стрелка';

  @override
  String get clearInk => 'Стереть пометки';

  @override
  String get inkTwoFingerHint =>
      'Один палец рисует · два пальца двигают и масштабируют';

  @override
  String get slideOpenFailed => 'Не удалось открыть презентацию';

  @override
  String get newPhotoNote => 'Фотозаметка';

  @override
  String get newScanNote => 'Отсканировать документ';

  @override
  String get scanDocument => 'Сканировать документ';

  @override
  String get scanDocumentSubtitle =>
      'Находит края, выравнивает страницу и добавляет её';

  @override
  String get scanUnsupported =>
      'Сканирование документов на этом устройстве не поддерживается';

  @override
  String scanFailed(String error) {
    return 'Не удалось отсканировать документ: $error';
  }

  @override
  String scanPagesAdded(int count) {
    return 'Добавлено страниц в заметку: $count';
  }

  @override
  String get scanTextTitle => 'Распознать ещё и текст?';

  @override
  String get scanTextBody =>
      'Текст со страниц распознаётся и записывается в заметку. Изображение остаётся как есть. Занимает несколько секунд на страницу.';

  @override
  String get scanImageOnly => 'Только изображение';

  @override
  String get scanRecognizeText => 'Распознать текст';

  @override
  String get scanRecognizing => 'Распознаём текст…';

  @override
  String get takePhoto => 'Сделать фото';

  @override
  String get qrScanTitle => 'Сканировать QR-код';

  @override
  String get qrScanSubtitle => 'Считайте камерой или с фотографии';

  @override
  String get qrScanHint => 'Совместите код с рамкой';

  @override
  String get qrFromPhoto => 'Считать с фотографии';

  @override
  String get qrNotFound => 'На этом изображении код не найден';

  @override
  String get qrLinkFound => 'Этот код — ссылка';

  @override
  String get qrOpenLink => 'Перейти по ссылке';

  @override
  String get qrSaveToNote => 'Сохранить в заметку';

  @override
  String get openLink => 'Открыть ссылку';

  @override
  String get linkOpenFailed => 'Не удалось открыть ссылку';

  @override
  String qrScanFailed(String error) {
    return 'Не удалось считать код: $error';
  }

  @override
  String get qrTorch => 'Фонарик';

  @override
  String attachmentsCount(int count) {
    return 'Вложения ($count)';
  }

  @override
  String get hideAttachments => 'Скрыть';

  @override
  String get showAttachments => 'Показать';

  @override
  String get videoBack10 => 'Назад на 10 с';

  @override
  String get videoForward10 => 'Вперёд на 10 с';

  @override
  String get selectAllItems => 'Выбрать все';

  @override
  String get showAllChips => 'Показать все';

  @override
  String get hideAllChips => 'Скрыть все';

  @override
  String get chipPickInfo =>
      'Какие чипсы папок и меток показывать на главном экране?';

  @override
  String get hiddenFolder => 'Скрытая папка';

  @override
  String get hiddenFolderInfo =>
      'Скрытая папка и заметки в ней не появляются на главном экране. Чтобы показать их, выберите «Скрытые папки» в меню ⋮ и подтвердите личность.';

  @override
  String get hiddenFoldersMenu => 'Скрытые папки';

  @override
  String get hiddenFolderAuthReason =>
      'Подтвердите личность, чтобы показать скрытые папки';

  @override
  String get hiddenFoldersShown => 'Скрытые папки показаны';

  @override
  String get hiddenFoldersHiddenAgain => 'Скрытые папки снова спрятаны';

  @override
  String get makeFolderHidden => 'Скрыть';

  @override
  String get makeFolderVisible => 'Показать';

  @override
  String gridColumnsCount(int count) {
    return 'Столбцов: $count';
  }

  @override
  String get addImageOnPageSubtitle => 'Стоит на странице, текст обтекает его';

  @override
  String get addImageAsFile => 'Добавить изображение файлом';

  @override
  String get addImageAsFileSubtitle =>
      'Остаётся вне страницы, в полосе вложений';

  @override
  String get moveImageToAttachments => 'Переместить во вложения';

  @override
  String get moveImageToPage => 'Разместить на странице';

  @override
  String get attachmentCopied => 'Вложение скопировано';

  @override
  String get pasteAttachment => 'Вставить скопированное вложение';

  @override
  String get fullscreen => 'Полный экран';

  @override
  String get more => 'Ещё';

  @override
  String get undone => 'Отменено';

  @override
  String get filterOthers => 'Остальные';

  @override
  String get chatSuggestion1 => 'Чего не хватает в моем списке покупок?';

  @override
  String get chatSuggestion2 =>
      'Сделай краткий обзор рабочих заметок за неделю';

  @override
  String get chatSuggestion3 => 'Есть ли у меня напоминания на завтра?';

  @override
  String get aiPointsToday => 'Лимиты на сегодня';

  @override
  String aiPointsOf(int used, int total) {
    return '$used / $total';
  }

  @override
  String get aiPointsRenew => 'обновление в полночь';

  @override
  String get aiChatWithNotes => 'Ассистент заметок';

  @override
  String get aiChatInputHint => 'Спросите что-нибудь о ваших заметках…';

  @override
  String get aiChatLooking => 'изучаю ваши заметки…';

  @override
  String get aiChatFullScreen => 'Во весь экран';

  @override
  String get aiOnYourNotes => 'ПО ВАШИМ ЗАМЕТКАМ';

  @override
  String get aiTaskDuplicates => 'Удалить дубликаты';

  @override
  String aiTaskDuplicatesInfo(int count) {
    return 'Дубликатов заметок: $count';
  }

  @override
  String get duplicatesTitle => 'Дубликаты заметок';

  @override
  String get duplicatesHint =>
      'Самая старая заметка в каждой группе сохраняется, остальные отправляются в корзину.';

  @override
  String get duplicatesKeepBadge => 'сохранится';

  @override
  String get duplicatesDeleteAll => 'Переместить дубликаты в корзину';

  @override
  String duplicatesDone(int count) {
    return 'Дубликатов перемещено в корзину: $count';
  }

  @override
  String get aiRecentActions => 'ПОСЛЕДНИЕ ДЕЙСТВИЯ';

  @override
  String get aiHistoryClear => 'Очистить';

  @override
  String get aiHistoryQuestion => 'Вопрос';

  @override
  String get aiHistoryNoteAction => 'Действие с заметкой';

  @override
  String get aiHistoryVoiceNote => 'Голосовая заметка';

  @override
  String get aiRecentOps => 'НЕДАВНЕЕ';

  @override
  String get aiTaskWeekSummary => 'Итоги недели';

  @override
  String get aiTaskWeekSummaryInfo => 'Сводка за последние 7 дней';

  @override
  String get aiTaskTagUntagged => 'Добавить теги';

  @override
  String aiTaskTagUntaggedInfo(int count) {
    return '$count заметок без тегов';
  }

  @override
  String get aiTaskSuggestTitles => 'Придумать заголовки';

  @override
  String aiTaskSuggestTitlesInfo(int count) {
    return '$count заметок без заголовков';
  }

  @override
  String get sectionPinnedShort => 'ЗАКРЕПЛЕННЫЕ';

  @override
  String get sectionToday => 'СЕГОДНЯ';

  @override
  String get sectionThisWeek => 'НА ЭТОЙ НЕДЕЛЕ';

  @override
  String get sectionEarlier => 'РАНЕЕ';

  @override
  String sectionNoteCount(int count) {
    return '$count заметок';
  }

  @override
  String get emptySearchSemanticHint => 'Попробуйте вкладку «Смысл»';

  @override
  String get quickCaptureHint => 'Новая заметка…';

  @override
  String get quickCaptureSave => 'Сохранить';

  @override
  String get quickAddWrite => 'ЗАПИСАТЬ';

  @override
  String get quickAddCapture => 'ЗАХВАТ — СОЗДАТЬ ЗАМЕТКУ ИЗ КОНТЕНТА';

  @override
  String get viewToggle => 'Вид';

  @override
  String get searchModeText => 'Текст';

  @override
  String get searchModeMeaning => 'Смысл';

  @override
  String get filterReminded => 'С напоминанием';

  @override
  String get filterLocked => 'Заблокированные';

  @override
  String get sortColor => 'Цвет';

  @override
  String get sortActive => 'Самые используемые';

  @override
  String get voicePreview => 'Проверить голос';

  @override
  String get voicePreviewCached =>
      'Образец создаётся один раз, затем воспроизводится из памяти';

  @override
  String get reorderHint =>
      'Нажмите и удерживайте карточку, затем перетащите её';

  @override
  String get filterSheetTitle => 'Фильтр';

  @override
  String get filterReset => 'Сбросить';

  @override
  String get filterSectionStatus => 'СТАТУС';

  @override
  String get filterSectionFolder => 'ПАПКА';

  @override
  String get filterSectionTag => 'ТЕГ';

  @override
  String get filterSectionSort => 'СОРТИРОВКА';

  @override
  String get filterFavoriteHint =>
      'Нажмите звёздочку, чтобы закрепить фильтр на главном экране';

  @override
  String get filterSheetSortHint =>
      'Группы по датам (СЕГОДНЯ, НА ЭТОЙ НЕДЕЛЕ…) отображаются только при сортировке по дате изменения.';

  @override
  String get formatTitle => 'Форматирование';

  @override
  String get formatBold => 'Полужирный';

  @override
  String get formatItalic => 'Курсив';

  @override
  String get formatUnderline => 'Подчёркнутый';

  @override
  String get formatTextColor => 'Цвет текста';

  @override
  String get formatHighlight => 'Выделение';

  @override
  String get formatInfo =>
      'Форматирование путешествует внутри текста в виде меток (например **полужирный**); в экспорте и при чтении вслух метки остаются скрытыми.';

  @override
  String get formatMenu => 'Форматирование…';

  @override
  String get noteFont => 'Шрифт';

  @override
  String get noteFontDefault => 'По умолчанию';

  @override
  String get noteFontSerif => 'Книжный (с засечками)';

  @override
  String get noteFontMono => 'Пишущая машинка';

  @override
  String get noteTextSize => 'Размер текста';

  @override
  String get formatClear => 'Убрать форматирование';

  @override
  String get noteTextOpacity => 'Непрозрачность';

  @override
  String get assistantVoiceSetting => 'Ассистент озвучивает ответы';

  @override
  String get assistantVoiceSettingInfo =>
      'Голосовой ассистент читает свой ответ вслух (только на телефоне).';

  @override
  String get assistantMute => 'Выключить звук';

  @override
  String get assistantUnmute => 'Включить звук';

  @override
  String get assistantMakeNote => 'Всё равно сделать заметкой';

  @override
  String get assistantNoteCreated => 'Заметка создана';

  @override
  String get noteNotFound => 'Заметка не найдена. Возможно, она была удалена.';

  @override
  String get back => 'Назад';

  @override
  String get addTextBlock => 'Добавить текст';

  @override
  String get attachNoteContent => 'Содержимое заметки';

  @override
  String get noteBackgroundImage => 'Фоновое изображение';

  @override
  String get chooseBackgroundImage => 'Выбрать изображение';

  @override
  String get changeBackgroundImage => 'Сменить изображение';

  @override
  String get removeBackgroundImage => 'Убрать фон';

  @override
  String get dashboardBackground => 'Фон главного экрана';

  @override
  String get dashboardBackgroundInfo =>
      'Изображение за сеткой заметок (только на этом устройстве).';

  @override
  String get aiProvider => 'Поставщик ИИ';

  @override
  String get aiProviderInfo =>
      'Выберите поставщика, которому принадлежит ваш ключ. Ключ каждого поставщика хранится отдельно, поэтому при возврате назад вводить его заново не придётся.';

  @override
  String get apiKeyFieldLabel => 'Ключ API';

  @override
  String get getApiKey => 'Где взять ключ?';

  @override
  String get recommendedModel => 'Рекомендуется';

  @override
  String get freeTierBadge => 'Есть бесплатный тариф';

  @override
  String get continueWithoutAccount => 'Продолжить без аккаунта';

  @override
  String get localAccountInfo =>
      'Ваши заметки остаются только на этом устройстве: их нельзя открыть в другом месте, они пропадут, если удалить приложение, и встроенный ИИ выключен. Привязать аккаунт Google можно в любой момент — заметки при этом сохранятся.';

  @override
  String get localAccountBadge => 'Локальный аккаунт';

  @override
  String get linkGoogleAccount => 'Привязать аккаунт Google';

  @override
  String get accountLinked =>
      'Ваш аккаунт Google привязан. Теперь заметки сохраняются в резервной копии.';

  @override
  String scanReviewPage(int current, int total) {
    return 'Страница ${current} / ${total}';
  }

  @override
  String get scanRotatePage => 'Повернуть страницу';

  @override
  String get scanDeletePage => 'Удалить страницу';

  @override
  String get scanLastPage => 'Последнюю страницу удалить нельзя';

  @override
  String get scanDiscardTitle => 'Отменить отсканированные страницы?';

  @override
  String get scanDiscardConfirm => 'Отменить';

  @override
  String get scanAdjustCorners => 'Настроить углы';

  @override
  String get scanFilterOriginal => 'Оригинал';

  @override
  String get scanFilterAuto => 'Улучшить';

  @override
  String get scanFilterGray => 'Оттенки серого';

  @override
  String get scanFilterBw => 'Чёрно-белое';

  @override
  String get scanApplyAll => 'Применить ко всем';

  @override
  String get scanPageFailed => 'Не удалось показать страницу';

  @override
  String get scanCropHint =>
      'Исправьте перекошенную страницу с помощью «Настроить углы»';

  @override
  String get scanAddAsPdf => 'Добавить как PDF';

  @override
  String get scanAddAsImages => 'Добавить как изображения';

  @override
  String get scanBuildingPdf => 'Готовим PDF…';

  @override
  String scanOcrProgress(int done, int total) {
    return 'Распознаём текст… ${done}/${total}';
  }

  @override
  String get scanAutoDetect => 'Определить края автоматически';

  @override
  String get scanReset => 'Сбросить';

  @override
  String get scanDetecting => 'Ищем края…';

  @override
  String get scanAutoFound =>
      'Края найдены автоматически; при необходимости поправьте маркерами';

  @override
  String get scanDragHint => 'Перетащите углы к краям листа';

  @override
  String get scanApplyCorners => 'Выровнять и применить';

  @override
  String get scanWorking => 'Выравниваем…';

  @override
  String get scanPdfAdded => 'Скан добавлен к заметке как вложение PDF';

  @override
  String get premiumTitle => 'Премиум';

  @override
  String premiumStatusActive(String date) {
    return 'Премиум активен — до ${date}';
  }

  @override
  String get premiumStatusFree => 'Вы пользуетесь бесплатной версией';

  @override
  String get premiumPerksTitle => 'Что меняется с Премиумом?';

  @override
  String get premiumPerkAi => 'Ежедневные ИИ-баллы';

  @override
  String get premiumPerkAttach => 'Размер вложений';

  @override
  String get premiumPerkStorage => 'Облачное хранилище';

  @override
  String get premiumPerkAuto => 'Автоматический ежедневный контент';

  @override
  String get premiumPerkAutoBody =>
      'Ежедневная сводка и подсказки готовятся автоматически каждый день; в бесплатной версии они запускаются только по запросу.';

  @override
  String get premiumHowTitle => 'Как получить?';

  @override
  String get premiumHowBody =>
      'Премиум скоро появится в Play Store. Сейчас мы в раннем доступе.';

  @override
  String get premiumByokHint =>
      'Если вы введёте собственный ключ API Gemini, функции ИИ работают без квоты — независимо от Премиума (Настройки → ИИ).';

  @override
  String get premiumDiscoverTitle => 'Возможности, которые вы могли пропустить';

  @override
  String get discoverScanBody =>
      'Отсканированные страницы выравниваются и улучшаются, а затем одним касанием превращаются в PDF С ПОИСКОМ — текстовый слой создаётся на устройстве и бесплатно.';

  @override
  String get discoverSemanticBody =>
      'Вкладка «Умный» в строке поиска ищет по СМЫСЛУ, а не по словам: введите «время вылета» — и найдётся ваша заметка о поездке.';

  @override
  String get discoverAssistantBody =>
      'Микрофон на главном экране сам превращает вашу речь в заметки, списки и напоминания — просто скажите «завтра в 9 к стоматологу».';

  @override
  String get discoverLockBody =>
      'Заметку можно заблокировать отпечатком или лицом: её содержимое никогда не попадёт в поиск, виджеты или ИИ.';

  @override
  String get discoverHiddenBody =>
      'Заметки в скрытой папке никогда не появляются на главном экране и в поиске; чтобы показать папку, нужна аутентификация.';

  @override
  String get discoverExportBody =>
      'Любую заметку можно экспортировать в PDF или Word вместе с изображениями (в меню «Поделиться»).';

  @override
  String get guestSignInUnavailable =>
      'Вход без Google отключён: анонимный вход не включён в консоли Firebase. Войдите через Google или повторите попытку, когда администратор его включит.';

  @override
  String get googleSignInUnavailable =>
      'Вход через Google отключён: провайдер Google не включён в консоли Firebase.';

  @override
  String get signInNetworkError =>
      'Нет доступа к интернету. Проверьте соединение и повторите попытку.';

  @override
  String get signInCanceled => 'Вход отменён.';

  @override
  String get cardRichPreview => 'Форматированный текст на карточках';

  @override
  String get cardRichPreviewInfo =>
      'Цвета, выделения, полужирный и подчёркивание из заметок видны и на карточках главного экрана. Если выключить, карточки показывают обычный текст.';

  @override
  String get fontSizeSmall => 'Мелкий';

  @override
  String get fontSizeMedium => 'Средний';

  @override
  String get fontSizeLarge => 'Крупный';

  @override
  String get fontSizeXLarge => 'Очень крупный';

  @override
  String get appFontSetting => 'Шрифт';

  @override
  String get appFontInfo =>
      'Шрифт всего приложения. Собственный шрифт заметки имеет приоритет. Все шрифты входят в приложение — интернет не нужен.';

  @override
  String get fontGroupSans => 'Без засечек';

  @override
  String get fontGroupSerif => 'С засечками';

  @override
  String get fontGroupMono => 'Моноширинный';

  @override
  String get fontGroupHand => 'Рукописный';

  @override
  String get appFontDefaultSuffix => 'по умолчанию';

  @override
  String get pdfSelectOcrRunning => 'Распознаём текст…';

  @override
  String get pdfSelectOcrNone => 'На этой странице текст не найден';

  @override
  String pdfSelectCopied(int n) {
    return 'Скопировано символов: ${n}';
  }

  @override
  String get bubbleAdd => 'Поставить выноску';

  @override
  String get bubbleAddDone => 'Готово, выноски добавлены';

  @override
  String get bubbleCollapse => 'Свернуть выноску';

  @override
  String get bubbleHint => 'Напишите здесь свою заметку…';

  @override
  String get bubbleTapToPlace => 'Нажмите на то место страницы, где нужна выноска';

  @override
  String get aiModelPodcast => 'Озвучка подкаста';

  @override
  String get listenAiVoice => 'Слушать голосом ИИ';

  @override
  String get listenAiVoiceInfo =>
      'Читает Gemini вместо голоса устройства: естественнее, но каждый абзац — это вызов модели.';

  @override
  String listenAiVoiceFailed(String error) {
    return 'Озвучка ИИ не удалась (${error}). Читаем голосом устройства.';
  }

  @override
  String get ttsSectionTitle => 'Озвучка';

  @override
  String get ttsEngineDevice => 'Голос устройства';

  @override
  String get ttsEngineAi => 'ИИ';

  @override
  String get ttsEngineDeviceInfo =>
      'Читает встроенный голос устройства: бесплатно, офлайн и без ограничения длины.';

  @override
  String get ttsEngineAiInfo =>
      'Читает речевая модель Gemini: заметно естественнее, но каждый абзац — это вызов модели, и нужен ваш собственный ключ Gemini.';

  @override
  String get ttsEngineAiUnavailable =>
      'Голосу ИИ нужен ваш собственный ключ Gemini. До этого чтение идёт голосом устройства.';

  @override
  String get ttsModel => 'Речевая модель';

  @override
  String get ttsVoice => 'Голос ИИ';

  @override
  String get shareAsNote => 'Поделиться как заметкой';

  @override
  String get shareAsNoteInfo =>
      'Отправляет заметку с вложениями, заметками к страницам, рисунками и выносками; на другой стороне она откроется точно так же в приложении Not.';

  @override
  String get shareAsNotePreparing => 'Готовим пакет заметки…';

  @override
  String get shareAsText => 'Обычным текстом';

  @override
  String get shareAsTextInfo =>
      'Отправляет текст заметки и заметки к страницам в любое приложение.';

  @override
  String get shareAsTextEmpty => 'В этой заметке нет текста для отправки.';

  @override
  String get sharePdfWithBubbles => 'PDF с выносками';

  @override
  String get sharePdfWithBubblesInfo =>
      'Выноски, выделения и рисунки впечатываются в PDF; открыть может любой, а в Not файл открывается редактируемым.';

  @override
  String get sharePdfWithBubblesNone =>
      'В этой заметке нет PDF с выносками или рисунками.';

  @override
  String get sharePdfWithBubblesPreparing => 'Готовится PDF с выносками…';

  @override
  String get sharePdfWithBubblesSuffix => ' (с выносками)';

  @override
  String get bubbleStar => 'Отметить';

  @override
  String get bubbleEdit => 'Изменить выноску';

  @override
  String get bubbleStarredOnly => 'Только отмеченные';

  @override
  String get bubbleSearchHint => 'Поиск по выноскам…';

  @override
  String get bubblesOverviewTitle => 'Выноски';

  @override
  String get bubblesEmpty =>
      'Выносок пока нет. Выделите текст в документе и подсветите его либо поставьте выноску на страницу.';

  @override
  String get bubblesNoMatch => 'Ни одна выноска не подходит под ваш запрос.';

  @override
  String get bubbleNoText => '(пустая выноска)';

  @override
  String get pdfHighlight => 'Подсветить';

  @override
  String get pdfHighlightWithNote => 'Подсветить + заметка';

  @override
  String get pageNotesShow => 'Показать заметку к странице';

  @override
  String get pageNotesHide => 'Скрыть заметку к странице';

  @override
  String get bubbleSave => 'Сохранить';

  @override
  String get bubbleTitleHint => 'Заголовок';

  @override
  String get bubbleUrgent => 'Срочно (мигает)';

  @override
  String get captureModeQuestion => 'Как открыть заметку?';

  @override
  String get captureModeBubbles => 'Выноски';

  @override
  String get captureModeBubblesInfo =>
      'Содержимое становится страницей документа: выноски, подсветка и перо.';

  @override
  String get captureModeClassic => 'Классическая';

  @override
  String get captureModeClassicInfo =>
      'Обычная текстовая заметка; содержимое добавляется как вложение.';

  @override
  String get captureModeNew => 'НОВОЕ';

  @override
  String get imagePrepareTitle => 'Настроить изображения';

  @override
  String get imagePrepareDone => 'Продолжить';

  @override
  String get imageRotateLeft => 'Повернуть влево';

  @override
  String get imageRotateRight => 'Повернуть вправо';

  @override
  String get videoFrameFailed =>
      'Не удалось взять кадр из видео; открываем классическую заметку.';

  @override
  String get bubbleArrowHide => 'Скрыть стрелку';

  @override
  String get bubbleArrowShow => 'Показать стрелку';

  @override
  String get speechPitch => 'Высота голоса';

  @override
  String get speechVoicePickerTitle => 'Выбор голоса';

  @override
  String get formatRemove => 'Убрать';

  @override
  String get exportTitle => 'Экспорт';

  @override
  String get exportNotesOption => 'Текст заметки (PDF / Word)';

  @override
  String get exportNotesOptionInfo =>
      'Текст и изображения заметки; выноски не включены.';

  @override
  String get captureNoteTitle => 'Заголовок заметки (необязательно)';

  @override
  String get captureNoteTitleHint => 'Новый документ получит это же имя';

  @override
  String get imageOcrTitle => 'Распознать текст на изображении';

  @override
  String get imageOcrNone => 'На этом изображении текст не найден.';

  @override
  String imageOcrHint(int count) {
    return 'Распознано строк: $count · нажмите, чтобы выбрать';
  }

  @override
  String imageOcrSelected(int count) {
    return 'Выбрано строк: $count';
  }

  @override
  String get imageOcrShort => 'Распознать текст';

  @override
  String get imageOcrWorking => 'Распознавание текста…';

  @override
  String get imageOcrSelectHint =>
      'Нажатие — слово · Удержание и перетаскивание — по буквам';

  @override
  String get imageOcrInsert => 'Добавить в заметку';

  @override
  String get imageOcrZoomIn => 'Приблизить';

  @override
  String get imageOcrZoomOut => 'Отдалить';

  @override
  String get selectImages => 'Выбрать изображения';

  @override
  String get exportImages => 'Изображения';

  @override
  String get exportImagesInfo =>
      'Текст обтекает узкие изображения, выровненные влево или вправо; центрированные занимают всю ширину.';

  @override
  String get exportAlignLeft => 'Слева';

  @override
  String get exportAlignCenter => 'По центру';

  @override
  String get exportAlignRight => 'Справа';

  @override
  String get exportImageWidth => 'Ширина';

  @override
  String get exportImageLine => 'Положение';

  @override
  String get aiModelSearch => 'Поиск моделей';

  @override
  String get aiModelOthers => 'ДРУГИЕ МОДЕЛИ';

  @override
  String get aiModelNoMatch => 'Подходящих моделей нет.';

  @override
  String get aiModelAutoInfo =>
      'Приложение по очереди пробует наиболее подходящие модели.';

  @override
  String imageOcrCharsSelected(int count) {
    return 'Выбрано символов: $count';
  }

  @override
  String imagesSelectedCount(int count) {
    return 'Выбрано изображений: $count';
  }

  @override
  String attachmentsCopiedCount(int count) {
    return 'Вложений: $count';
  }

  @override
  String exportImageLineOf(int count) {
    return '/ $count строк';
  }

  @override
  String get aiModelShowAll => 'Показать все';

  @override
  String get aiModelShowAllInfo =>
      'Показывает и модели, которые приложение не использует.';

  @override
  String get rotateFailed => 'Не удалось повернуть изображение.';

  @override
  String get dashboardBackgroundPick => 'Выбрать фоновое изображение';

  @override
  String get dashboardBackgroundChange => 'Сменить фоновое изображение';

  @override
  String podcastRenderingAudio(int done, int total) {
    return 'Готовим аудио: ${done}/${total} частей';
  }

  @override
  String get podcastExportAudio => 'Экспортировать как аудиофайл';

  @override
  String get podcastExportAudioCost =>
      'Весь сценарий заново озвучивается голосом ИИ и сохраняется одним файлом WAV. Это расходует вашу квоту Gemini и на длинных текстах может занять несколько минут.';

  @override
  String get podcastShareText => 'Поделиться сценарием';

  @override
  String get podcastSaveAsNote => 'Сохранить как новую заметку';

  @override
  String get podcastSavedAsNote => 'Сценарий подкаста сохранён как заметка.';

  @override
  String get listenPreparingVoice => 'Готовим аудио…';

  @override
  String get appearancePreviewTitle => 'Пример текста';

  @override
  String get appearancePreviewNoteTitle => 'Пример заголовка заметки';

  @override
  String get appearancePreviewBody =>
      'Ваши заметки будут выглядеть так. Текст **полужирный**, ~подчёркнутый~ и ==2:выделенный== выглядит вот так.';

  @override
  String get appearancePreviewItem => 'Так выглядит пункт списка';

  @override
  String get convertToText => 'Преобразовать в текст';

  @override
  String get convertToList => 'Преобразовать в список';

  @override
  String get convertedToText => 'Список преобразован в обычный текст.';

  @override
  String get convertedToList => 'Текст преобразован в список.';

  @override
  String get convertToListEmpty => 'Нет строк, которые можно превратить в список.';

  @override
  String get listTwoColumns => 'Две колонки';

  @override
  String get listOneColumn => 'Одна колонка';

  @override
  String get sortItems => 'Сортировать пункты';

  @override
  String get sortStarredFirst => 'Сначала отмеченные';

  @override
  String get sortUncheckedFirst => 'Выполненные в конце';

  @override
  String get sortAlphabetical => 'А → Я';

  @override
  String get sortAlphabeticalDesc => 'Я → А';

  @override
  String get imagesToAttachments => 'Переместить изображения во вложения';

  @override
  String imagesToAttachmentsDone(int count) {
    return 'Изображений перемещено во вложения: ${count}.';
  }

  @override
  String get imageOcrShowRecognized => 'Подсветить распознанный текст';

  @override
  String get imageOcrHideRecognized => 'Скрыть подсветку';

  @override
  String get bubblePlainMode => 'Открытое текстовое поле';

  @override
  String get bubblePlainModeOn => 'Открытое текстовое поле включено';

  @override
  String get bubblePlainTapToPlace => 'Нажмите там, где должен быть текст';

  @override
  String get bubblePlainHint => 'Нажмите, чтобы написать';

  @override
  String get noteSearchTitle => 'Поиск в заметке';

  @override
  String get noteSearchHint => 'Искать в этой заметке…';

  @override
  String get noteSearchEmptyHint =>
      'Мгновенно ищет по тексту заметки, пунктам и заметкам к страницам. Запустите сканирование ниже, чтобы искать внутри вложений-изображений и PDF.';

  @override
  String get noteSearchNoHit => 'Совпадений не найдено.';

  @override
  String get noteSearchScanAttachments => 'Сканировать вложения';

  @override
  String get noteSearchAskAi => 'Спросить ИИ';

  @override
  String get noteTitleLabel => 'Заголовок';

  @override
  String get noteBodyLabel => 'Текст заметки';

  @override
  String get itemLabel => 'Пункт';

  @override
  String noteSearchAttachmentsInfo(int count) {
    return 'Можно просканировать вложений: ${count} (изображение/PDF).';
  }

  @override
  String noteSearchAttachmentsReady(int count) {
    return 'Поиск идёт и по ${count} вложениям.';
  }

  @override
  String pageLabel(int page) {
    return 'Страница ${page}';
  }

  @override
  String get archiveNotebook => 'Архивная тетрадь';

  @override
  String get archiveNotebookInfo =>
      'Тетрадь с собственными страницами, в которой хранятся копии важных документов и изображений.';

  @override
  String get archivePageImages => 'Изображения';

  @override
  String get archivePageVideos => 'Видео';

  @override
  String get archivePageDocuments => 'Документы';

  @override
  String get archivePageTexts => 'Тексты';

  @override
  String get archiveNewPage => 'Новая страница';

  @override
  String get archivePageName => 'Название страницы (напр. Счета)';

  @override
  String get archivePageEmpty => 'Эта страница пуста.';

  @override
  String get archiveSearchHint => 'Поиск по тетради…';

  @override
  String get archiveAddText => 'Добавить текст';

  @override
  String get archiveAddFile => 'Добавить файл';

  @override
  String get archiveCopyHere => 'Скопировать в архивную тетрадь';

  @override
  String get archiveNoNotebook =>
      'Архивной тетради пока нет. Сначала создайте её.';

  @override
  String get archiveNothingToCopy => 'В этой заметке нет вложений для копирования.';

  @override
  String archiveDeleteEntry(String name) {
    return 'Удалить «${name}» из тетради? Эта копия пропадёт навсегда.';
  }

  @override
  String archiveCopied(int count) {
    return 'Файлов скопировано в архивную тетрадь: ${count}.';
  }

  @override
  String get archiveCaptureTitle => 'Снять с изображения';

  @override
  String get archiveCapturePage => 'Страница';

  @override
  String get archiveCapturePageInfo =>
      'Тип, предложенный ИИ. Если оставить пустым, попадёт на страницу «Тексты».';

  @override
  String get archiveCaptureText => 'Распознанный текст';

  @override
  String get attachmentTagInsert => 'Вставить в текст';

  @override
  String get attachmentTagInserted => 'Метка вложения вставлена.';

  @override
  String get attachmentTagPreview => 'Просмотреть вложение';

  @override
  String get attachmentTagEdit => 'Изменить вложение';

  @override
  String archiveCardSummary(int files, int texts) {
    return 'Файлов: ${files} · текстов: ${texts}';
  }

  @override
  String get archiveEntryTitle => 'Заголовок';

  @override
  String get archiveLinkedFile => 'Связанный файл';

  @override
  String get archiveNoLink => 'Связанного файла нет';

  @override
  String get attachmentTagEmbed => 'Встроить вложение в выделение';

  @override
  String get attachmentTagNoAttachment =>
      'Сначала добавьте файл к заметке, потом сможете встроить его в текст.';

  @override
  String get bubbleModeBubble => 'Выноска';

  @override
  String get attachmentTagEmbedInfo =>
      'Связывается с выделенным текстом или с курсором, если ничего не выделено';

  @override
  String get attachmentTagPickText =>
      'Теперь выделите текст для связи и нажмите «Связать здесь».';

  @override
  String get attachmentTagLinkHere => 'Связать здесь';

  @override
  String attachmentTagPendingBanner(String name) {
    return '${name} будет связан — выделите текст';
  }

  @override
  String get docNameNotesSuffix => 'заметки';

  @override
  String get docNamePhoto => 'Заметки к фото';

  @override
  String get docNameScan => 'Заметки к скану';

  @override
  String get docNameImage => 'Заметки к изображению';

  @override
  String get docNameVideo => 'Заметки к видео';

  @override
  String get folderManage => 'Управление папкой';

  @override
  String get folderEmpty => 'Эта папка пуста';

  @override
  String get folderEmptyHint =>
      'Добавьте заметку кнопкой + внизу или переместите заметку сюда при редактировании.';

  @override
  String get brainstormTitle => 'Мозговой штурм с ИИ';

  @override
  String get brainstormRowInfo =>
      'Сначала ИИ набрасывает план, затем вы развиваете его вместе';

  @override
  String get brainstormIntro =>
      'Нажмите на один из заголовков выше или просто пишите — подумаем вместе.';

  @override
  String get brainstormOutlineTitle => 'ПЛАН';

  @override
  String get brainstormInputHint => 'Напишите идею или задайте вопрос…';

  @override
  String get brainstormAddIdea => 'Добавить в заметку';

  @override
  String get brainstormAdded => 'Добавлено в заметку';

  @override
  String get folderShared => 'Эта папка открыта другу';

  @override
  String get friendsTitle => 'Контакты';

  @override
  String get friendsAdd => 'Добавить друга';

  @override
  String get friendsEmpty =>
      'Пока никого. Добавьте друга по адресу эл. почты, чтобы делиться с ним папками.';

  @override
  String get friendsRequestsTitle => 'ЗАПРОСЫ';

  @override
  String get friendsListTitle => 'МОИ ДРУЗЬЯ';

  @override
  String get friendsAddEmailHint => 'friend@email.com';

  @override
  String get friendsSendRequest => 'Отправить запрос';

  @override
  String get friendsRequestSent => 'Запрос отправлен';

  @override
  String get friendsNotFound =>
      'С этим адресом никто не зарегистрирован. Человек должен хотя бы раз открыть приложение с аккаунтом Google.';

  @override
  String get friendsSelf => 'Нельзя добавить в друзья самого себя';

  @override
  String get friendsAlready => 'Вы уже друзья';

  @override
  String get friendsDecline => 'Отклонить';

  @override
  String get friendsAccept => 'Принять';

  @override
  String get friendsRemove => 'Удалить';

  @override
  String get friendsRemoveConfirmTitle => 'Удалить друга';

  @override
  String friendsRemoveConfirmBody(Object name) {
    return 'Удалить ${name} из друзей? Папки, которыми вы делились, перестанут быть видимыми.';
  }

  @override
  String get friendsNeedsAccount =>
      'Контакты и общий доступ к папкам работают только с привязанным аккаунтом Google.';

  @override
  String get friendsSearchHint => 'Поиск по имени или эл. почте';

  @override
  String get friendsSearchTab => 'Поиск';

  @override
  String get friendsSearchEmailTab => 'По эл. почте';

  @override
  String get friendsSearchEmpty => 'Ничего не найдено';

  @override
  String get friendsSearchTooShort => 'Введите хотя бы 2 символа для поиска';

  @override
  String get friendsSearchAdd => 'Добавить';

  @override
  String get folderShare => 'Поделиться';

  @override
  String folderShareCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Открыта ${count} людям',
      one: 'Открыта 1 человеку',
    );
    return '$_temp0';
  }

  @override
  String folderShareTitle(Object name) {
    return 'Поделиться папкой «${name}»';
  }

  @override
  String get folderShareInfo =>
      'Приглашение уйдёт выбранному другу; он увидит папку, как только примет его. Права выбираете вы (чтение / запись / оба).';

  @override
  String get friendsRowInfo => 'Добавляйте друзей, делитесь с ними папками';

  @override
  String get accountRecoverConflictTitle =>
      'На этом устройстве есть несохранённые заметки';

  @override
  String accountRecoverConflictBody(Object count) {
    return 'Этот аккаунт Google уже связан с другой сессией; переход на него скроет заметки на этом устройстве (${count} шт.) — они не удаляются, просто станут недоступны отсюда. Всё равно продолжить?';
  }

  @override
  String get accountRecoverConflictProceed => 'Всё равно перейти';
  @override
  String get folderRoleRead => 'Чтение';

  @override
  String get folderRoleWrite => 'Запись';

  @override
  String get folderRoleBoth => 'Чтение + запись';

  @override
  String get folderInvitePending => 'Приглашение отправлено, ждём ответа';

  @override
  String get folderWriteOnlyTitle => 'У вас только доступ на запись';

  @override
  String get folderWriteOnlyHint => 'Вы можете добавлять новые заметки в эту папку, но не видите те, что внутри.';

  @override
  String get folderChatTitle => 'Чат';

  @override
  String get folderChatHint => 'Напишите сообщение…';

  @override
  String get folderChatSend => 'Отправить';

  @override
  String get folderChatEmptyTitle => 'Сообщений пока нет';

  @override
  String get folderChatEmptyHint => 'Общайтесь здесь с теми, кому вы открыли эту папку.';

  @override
  String get folderInviteTitle => 'Приглашение в папку';

  @override
  String folderInviteBody(Object name) {
    return 'Вам открыли папку «${name}».';
  }

  @override
  String get folderInviteAccepted => 'Папка добавлена';

  @override
  String get folderInviteDeclined => 'Приглашение отклонено';

  @override
  String friendRequestBanner(Object name) {
    return '${name} отправил вам запрос в друзья';
  }

  @override
  String get friendRequestAccepted => 'Друг добавлен';

  @override
  String get sendNoteAction => 'Отправить другу';

  @override
  String get sendNoteTitle => 'Отправить заметку другу';

  @override
  String get sendNoteInfo => 'Копия заметки попадёт в ящик «Входящие заметки» этого человека. Вложения (изображения, документы, аудио) не отправляются.';

  @override
  String sendNoteSent(Object name) {
    return 'Заметка отправлена: ${name}';
  }

  @override
  String get inboxTitle => 'Входящие заметки';

  @override
  String get inboxEmpty => 'Входящих заметок нет';

  @override
  String get inboxEmptyHint => 'Здесь собираются заметки, которые присылают друзья.';

  @override
  String inboxFrom(Object name) {
    return 'Отправитель: ${name}';
  }

  @override
  String get inboxAccept => 'Добавить к моим заметкам';

  @override
  String get inboxAccepted => 'Заметка добавлена к вашим заметкам';

  @override
  String get folderShelfExpand => 'Развернуть папки';

  @override
  String get folderShelfCollapse => 'Свернуть папки';

  @override
  String get accountSheetLocalInfo => 'Ваши заметки есть только на этом устройстве. Привяжите аккаунт Google, чтобы сделать резервную копию и добавлять друзей.';

  @override
  String get accountSettings => 'Настройки аккаунта';
}
