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
      'Yüklenemedi — yeniden denemek için dokun';

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
    return 'Asistan \"$title\" notunu çöp kutusuna taşımak istiyor. Onaylıyor musun?';
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
  String get newPdfNote => 'PDF ekle not al';

  @override
  String get imageNotePreparing => 'Изображения собираются в документ…';

  @override
  String get newImageNote => 'Добавить изображение и делать заметки';

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
  String get pdfAddBlankPage => 'Добавить пустую страницу';

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
  String get attachNoteContent => 'Not içeriği';

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
      'Голосу ИИ нужен ваш собственный ключ Gemini. До этого чтение идёт голосом устройства.';

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
      'Seçtiğin arkadaş bu klasörü ve içindeki notları görür, düzenleyebilir.';

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
}
