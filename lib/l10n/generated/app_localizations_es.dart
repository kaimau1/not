// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Notas';

  @override
  String get loginTagline => 'Tus notas, en todos tus dispositivos';

  @override
  String get signInWithGoogle => 'Iniciar sesión con Google';

  @override
  String loginError(String error) {
    return 'No se pudo iniciar sesión: $error';
  }

  @override
  String get searchHint => 'Buscar en las notas...';

  @override
  String get filterAll => 'Todas';

  @override
  String get filterText => 'Texto';

  @override
  String get filterChecklist => 'Lista';

  @override
  String get filterOrdered => 'Numerada';

  @override
  String get filterPinned => 'Fijadas';

  @override
  String get filterStarred => 'Destacadas';

  @override
  String get star => 'Destacar';

  @override
  String get unstar => 'Quitar destacado';

  @override
  String editedAt(String date) {
    return 'Editada: $date';
  }

  @override
  String get sectionPinned => 'Fijadas';

  @override
  String get sectionOthers => 'Otras';

  @override
  String get emptyNotes => 'Aún no hay notas';

  @override
  String get emptyNotesHint => 'Toca + para crear tu primera nota';

  @override
  String get emptySearch => 'No se encontraron resultados';

  @override
  String get newTextNote => 'Nota de texto';

  @override
  String get newChecklist => 'Lista';

  @override
  String get newOrderedList => 'Lista numerada';

  @override
  String get noteDeleted => 'Nota eliminada';

  @override
  String notesDeletedCount(int count) {
    return '$count notas eliminadas';
  }

  @override
  String selectedCount(int count) {
    return '$count seleccionadas';
  }

  @override
  String get deleteSelected => 'Eliminar la selección';

  @override
  String get undo => 'Deshacer';

  @override
  String get redo => 'Rehacer';

  @override
  String get titleHint => 'Título';

  @override
  String get bodyHint => 'Nota...';

  @override
  String get newItemHint => 'Nuevo elemento';

  @override
  String moreItemsCount(int count) {
    return '+$count elementos más';
  }

  @override
  String get addAttachment => 'Añadir';

  @override
  String get addAttachmentMore => 'Más tipos de adjuntos…';

  @override
  String get addImage => 'Añadir imagen';

  @override
  String get addPdf => 'Añadir PDF';

  @override
  String get addSlide => 'Añadir diapositivas';

  @override
  String get pasteImage => 'Pegar imagen del portapapeles';

  @override
  String get clipboardEmpty => 'No hay ninguna imagen en el portapapeles';

  @override
  String get noNoteSelected => 'Elige una nota de la izquierda';

  @override
  String attachmentFailed(String error) {
    return 'No se pudo añadir el archivo adjunto: $error';
  }

  @override
  String get attachmentCopying => 'Copiando...';

  @override
  String get attachmentUploading => 'Subiendo...';

  @override
  String get attachmentUploadFailed =>
      'Yüklenemedi — yeniden denemek için dokun';

  @override
  String get attachmentNotSynced =>
      'Este archivo todavía no se ha sincronizado en este dispositivo';

  @override
  String attachmentTooLarge(int limit) {
    return 'El archivo es demasiado grande (máximo $limit MB)';
  }

  @override
  String storageFull(String limit) {
    return 'Almacenamiento lleno ($limit). Elimina archivos adjuntos antiguos para liberar espacio.';
  }

  @override
  String get storageUsage => 'Almacenamiento';

  @override
  String storageUsageValue(String used, String limit) {
    return '$used de $limit usado';
  }

  @override
  String get removeAttachment => 'Quitar el adjunto';

  @override
  String get pin => 'Fijar';

  @override
  String get unpin => 'Dejar de fijar';

  @override
  String get delete => 'Eliminar';

  @override
  String get color => 'Color';

  @override
  String get aiTitle => 'IA';

  @override
  String get aiSummarize => 'Resumir la nota';

  @override
  String get aiAnalyze => 'Analizar';

  @override
  String get aiSectionNote => 'Esta nota';

  @override
  String get aiSectionAttachments => 'Adjuntos';

  @override
  String get summarize => 'Resumir';

  @override
  String get summaryDetailTitle => 'Tipo de resumen';

  @override
  String get summaryShort => 'Resumen breve';

  @override
  String get summaryShortInfo => 'Unas frases de contexto y los puntos clave';

  @override
  String get summaryDetailed => 'Resumen detallado';

  @override
  String get summaryDetailedInfo =>
      'Tan completo que no hace falta abrir el original';

  @override
  String get listen => 'Escuchar';

  @override
  String get ask => 'Hacer una pregunta';

  @override
  String get extractText => 'Extraer el texto';

  @override
  String get transcribe => 'Transcribir';

  @override
  String get listenToNote => 'Leer en voz alta';

  @override
  String get aiNoApiKey =>
      'Primero introduce tu clave de API de Gemini en Ajustes';

  @override
  String aiError(String error) {
    return 'La petición a la IA ha fallado: $error';
  }

  @override
  String get aiSummaryTitle => 'Resumen de IA';

  @override
  String get aiThinking => 'Pensando...';

  @override
  String get copy => 'Copiar';

  @override
  String get copied => 'Copiado';

  @override
  String get settingsSearchHint => 'Buscar ajustes: “resumen”, “micrófono”';

  @override
  String settingsSearchEmpty(String query) {
    return 'No hay ajustes que coincidan con «$query»';
  }

  @override
  String get settings => 'Ajustes';

  @override
  String get settingsAppearance => 'Apariencia';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get settingsAi => 'IA';

  @override
  String get geminiApiKey => 'Clave de API de Gemini';

  @override
  String get geminiApiKeyHint => 'Pega la clave que empieza por AIza...';

  @override
  String get geminiApiKeyInfo =>
      'La clave es opcional: sin ella, las peticiones de IA pasan por el servicio integrado de la app (con una cuota diaria gratuita, mayor con Premium). Para uso ilimitado con tu propia clave, consigue una gratis en aistudio.google.com; la clave se guarda solo en este dispositivo, en el almacén seguro.';

  @override
  String aiBuiltInPremium(int count) {
    return 'IA integrada: Premium — te quedan $count puntos hoy';
  }

  @override
  String aiBuiltInRemaining(int count) {
    return 'IA integrada: te quedan $count puntos gratuitos hoy';
  }

  @override
  String get aiBuiltInByok => 'Se está usando tu propia clave: sin límite';

  @override
  String get aiReport => 'Informar sobre esta respuesta';

  @override
  String get aiReportThanks => 'Informe recibido, gracias';

  @override
  String get privacyPolicyTitle => 'Política de privacidad';

  @override
  String get lockNote => 'Bloquear';

  @override
  String get unlockNote => 'Desbloquear';

  @override
  String get lockedNote => 'Nota bloqueada';

  @override
  String get unlockAuthReason =>
      'Verifica tu identidad para abrir la nota bloqueada';

  @override
  String get exportBackup => 'Exportar copia de seguridad (JSON)';

  @override
  String get expandListItems => 'Mostrar las filas de lista completas';

  @override
  String get expandListItemsInfo =>
      'Los elementos largos se reparten en varias líneas y quedan totalmente visibles. Si está desactivado, la fila se queda en una línea y se despliega al tocarla.';

  @override
  String get quickCaptureRowSetting => 'Barra de nota rápida';

  @override
  String get quickCaptureRowInfo =>
      'Muestra un campo \"Nota nueva...\" de una línea arriba. Si está desactivado, usa el botón +.';

  @override
  String get emptyTrash => 'Vaciar la papelera';

  @override
  String emptyTrashConfirm(int count) {
    return 'Se eliminarán $count notas de forma permanente. Esto no se puede deshacer. ¿Seguro?';
  }

  @override
  String get trashEmptied => 'Papelera vaciada';

  @override
  String get validateAndSave => 'Verificar y guardar';

  @override
  String get clear => 'Vaciar';

  @override
  String get aiDiagnostics => 'Diagnóstico de IA';

  @override
  String get aiDiagnosticsEmpty => 'No hay errores registrados';

  @override
  String aiDiagnosticsCount(int count) {
    return 'Últimos $count registros de error';
  }

  @override
  String get apiKeyValid => 'Clave de API verificada y guardada';

  @override
  String get apiKeyInvalid => 'La clave de API no es válida';

  @override
  String get apiKeySavedBadge => 'Guardada';

  @override
  String get removeApiKey => 'Eliminar la clave';

  @override
  String get refresh => 'Actualizar';

  @override
  String get account => 'Cuenta';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get signOutConfirm => '¿Seguro que quieres cerrar sesión?';

  @override
  String get signOutAnonymousWarning =>
      'Usas una cuenta local: al cerrar sesión, esta cuenta y TODAS sus notas quedarán inaccesibles para siempre — sin copia de seguridad no se pueden recuperar. Vincula antes una cuenta de Google. ¿Cerrar sesión igualmente?';

  @override
  String get deleteAccount => 'Eliminar mi cuenta y mis datos';

  @override
  String get deleteAccountWarning =>
      'Esto no se puede deshacer: se eliminarán de forma permanente todas tus notas, tus adjuntos y tu cuenta. ¿Seguro que quieres continuar?';

  @override
  String get deleteAccountConfirm => 'Eliminar permanentemente';

  @override
  String get licensesTitle => 'Licencias de código abierto';

  @override
  String get generating => 'Generando...';

  @override
  String get retry => 'Reintentar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get close => 'Cerrar';

  @override
  String get ok => 'Aceptar';

  @override
  String get syncPending => 'Esperando a sincronizar';

  @override
  String get synced => 'Sincronizada';

  @override
  String genericError(String error) {
    return 'Algo ha ido mal: $error';
  }

  @override
  String get addTag => 'Etiqueta';

  @override
  String get tagHint => 'p. ej. trabajo, casa, clase';

  @override
  String get addReminder => 'Recordar';

  @override
  String get share => 'Compartir';

  @override
  String get archive => 'Archivar';

  @override
  String get unarchive => 'Sacar del archivo';

  @override
  String get archiveTitle => 'Archivo';

  @override
  String get archiveEmpty => 'No hay notas en el archivo';

  @override
  String get trashTitle => 'Papelera';

  @override
  String get trashEmpty => 'La papelera está vacía';

  @override
  String get trashInfo =>
      'Las notas eliminadas se quedan aquí; puedes restaurarlas o borrarlas del todo.';

  @override
  String get restore => 'Restaurar';

  @override
  String get deleteForever => 'Eliminar permanentemente';

  @override
  String get deleteForeverConfirm =>
      'Esta nota se eliminará de forma permanente. ¿Seguro?';

  @override
  String assistantDeleteConfirm(String title) {
    return 'Asistan \"$title\" notunu çöp kutusuna taşımak istiyor. Onaylıyor musun?';
  }

  @override
  String get recordAudio => 'Grabación de voz';

  @override
  String get recording => 'Grabando...';

  @override
  String get stopAndSave => 'Terminar y añadir';

  @override
  String get micPermissionDenied =>
      'No se ha concedido el permiso de micrófono';

  @override
  String get speechRecognitionFailed =>
      'El reconocimiento de voz no ha funcionado. Comprueba que el permiso de micrófono esté concedido y que la app de Google esté actualizada.';

  @override
  String get addDrawing => 'Añadir dibujo';

  @override
  String get drawingTitle => 'Dibujo';

  @override
  String get addToNote => 'Añadir a la nota';

  @override
  String get chatTitle => 'Asistente de notas';

  @override
  String get chatHint =>
      'Pregunta sobre tus notas: «¿cuál era la receta que apunté la semana pasada?», «¿qué falta en mi lista de la compra?»';

  @override
  String get chatInputHint => 'Escribe una pregunta...';

  @override
  String get fontSize => 'Tamaño del texto';

  @override
  String get fontSizePreview => 'Tus notas se verán así';

  @override
  String get darkSchedule => 'Horario del tema oscuro';

  @override
  String get darkScheduleInfo =>
      'Cambia al tema oscuro entre las horas que elijas';

  @override
  String get aiTranslate => 'Traducir';

  @override
  String get voiceCommand => 'Comando de voz';

  @override
  String get semanticSearchToggle => 'Búsqueda semántica con IA';

  @override
  String get semanticSearchHint =>
      'Busca por significado: «gastos del coche»...';

  @override
  String get briefingTitle => 'Resumen del día';

  @override
  String get briefingLoading => 'Preparando tu resumen...';

  @override
  String get briefingEmpty => 'Nada para hoy';

  @override
  String get briefingSetting => 'Notificación del resumen diario';

  @override
  String get briefingSettingInfo =>
      'Recibe cada mañana, a la hora que elijas, una notificación con el resumen del día';

  @override
  String get autoTagSetting => 'Etiquetar automáticamente';

  @override
  String get autoTagSettingInfo =>
      'Cuando se cierra una nota sin etiquetas, la IA le añade una que encaje';

  @override
  String get suggestTags => 'Sugerir etiquetas';

  @override
  String get aiFixNote => 'Corregir la nota';

  @override
  String get fixLevelTitle => '¿Cuánto hay que corregir?';

  @override
  String get fixSimple => 'Ligera';

  @override
  String get fixSimpleInfo => 'Solo ortografía y erratas';

  @override
  String get fixBalanced => 'Equilibrada';

  @override
  String get fixBalancedInfo =>
      'También la estructura de las frases, para que quede más limpio';

  @override
  String get fixDetailed => 'A fondo';

  @override
  String get fixDetailedInfo => 'Reescribe todo el texto de arriba abajo';

  @override
  String get existingTagsLabel => 'Etiquetas anteriores';

  @override
  String get aiSkipCheckedSetting =>
      'Dejar los elementos marcados fuera de los cambios de la IA';

  @override
  String get aiSkipCheckedInfo =>
      'Cuando la IA corrige o traduce una lista, los elementos ya completados (marcados) se mantienen tal cual; solo se editan los que están sin marcar.';

  @override
  String get noteUpdatedUndo => 'Nota actualizada';

  @override
  String get aiImprove => 'Mejorar la nota';

  @override
  String get improveFormal => 'Hacerla más formal';

  @override
  String get improveShorten => 'Acortar';

  @override
  String get improveBullets => 'Convertir en lista de viñetas';

  @override
  String get improveNumbered => 'Convertir en lista numerada';

  @override
  String get replaceNote => 'Sustituir la nota';

  @override
  String get openAsNewNote => 'Como nota nueva';

  @override
  String get pdfChatHint =>
      'Pregunta sobre este PDF: «resúmelo», «¿hay una cláusula de penalización?», «¿cuál es el plazo?»';

  @override
  String get pdfChatInputHint => 'Escribe una pregunta sobre el PDF...';

  @override
  String get voiceCaptureHint =>
      'Habla: «comprar leche y pan» o «reunión mañana a las 9, recuérdamelo» — la IA crea tu nota cuando termines.';

  @override
  String get voiceFinish => 'Terminar';

  @override
  String get voiceProcessing => 'Aplicando lo que has dicho...';

  @override
  String get voiceNothingHeard => 'No se ha detectado voz en la grabación';

  @override
  String get voiceNoteSaved => 'Tu nota de voz se ha guardado';

  @override
  String get openNote => 'Abrir la nota';

  @override
  String get remindersTitle => 'Recordatorios';

  @override
  String get remindersEmpty => 'No hay recordatorios';

  @override
  String get remindersEmptyHint =>
      'Añade un recordatorio a una nota, o crea una nota nueva con recordatorio desde el botón +';

  @override
  String get remindersUpcoming => 'Próximos';

  @override
  String get remindersPast => 'Pasados';

  @override
  String get reminderInPast =>
      'La hora seleccionada ya pasó — elige una hora futura.';

  @override
  String get newReminder => 'Nuevo recordatorio';

  @override
  String get remindersUntitled => 'Nota sin título';

  @override
  String get remindersEdit => 'Cambiar la hora';

  @override
  String get remindersRemove => 'Quitar el recordatorio';

  @override
  String get aiModelChat => 'Resúmenes, títulos, etiquetas y chat';

  @override
  String get aiModelDocument => 'Chat de documentos y resumen de PDF';

  @override
  String get aiModelTranslate => 'Traducción';

  @override
  String get aiModelVoice => 'Asistente de nota de voz';

  @override
  String get aiModelAuto => 'Automático (recomendado)';

  @override
  String get aiModelsInfo =>
      'Puedes elegir un modelo distinto para cada tarea: los textos cortos van bien con un modelo rápido, y los documentos largos piden uno más capaz. Si el modelo elegido agota su cuota o se retira, se prueba el siguiente automáticamente.';

  @override
  String get clearNote => 'Vaciar';

  @override
  String get clearNoteConfirm =>
      'Se eliminará el contenido de la nota (texto y elementos de lista). ¿Seguro?';

  @override
  String get themePaper => 'Papel';

  @override
  String get calculatorTitle => 'Calculadora';

  @override
  String get calcExpressionHint => 'p. ej. 12,5×3+40';

  @override
  String get calcInvalid => 'Expresión no válida';

  @override
  String get liveDictation => 'Dictar';

  @override
  String get voiceCaptureAi => 'Sesli yakala (yapay zekâ)';

  @override
  String get dictationListening =>
      'Escuchando... el texto aparece mientras hablas';

  @override
  String get dictationNoKeyInfo =>
      'El dictado en directo no está disponible en este dispositivo; la grabación se transcribirá de una vez cuando pares.';

  @override
  String get dictationHoldHint =>
      'Mantén pulsado el micrófono y habla; el texto se escribe al soltar';

  @override
  String itemsSelected(int count) {
    return '$count elementos seleccionados';
  }

  @override
  String get noteChatTitle => 'Chatea con esta nota';

  @override
  String get noteChatHint => 'Pregunta algo sobre esta nota';

  @override
  String get noteChatIntro =>
      'Se lee el contenido de la nota y sus adjuntos (PDF/imagen), y se responde a tu pregunta a partir de ellos.';

  @override
  String get dictationProcessing => 'Transcribiendo...';

  @override
  String get aiDailyManualInfo =>
      'En el plan gratuito esto no se genera automáticamente, para no consumir tu cuota diaria. Puedes generarlo una vez al día con el botón de abajo.';

  @override
  String get aiGenerate => 'Generar';

  @override
  String get aiGeneratedTodayInfo =>
      'Esto se ha generado hoy. En el plan gratuito se renueva una vez al día; mañana podrás generarlo otra vez.';

  @override
  String get voiceAssistantTitle => 'Asistente de notas de voz';

  @override
  String get voiceListening => 'Escuchando...';

  @override
  String get voiceHoldHint =>
      'Mantén pulsado y habla; tu nota se crea al soltar';

  @override
  String get voiceTapHint => 'Toca y habla; toca otra vez para terminar';

  @override
  String get voiceTooShort =>
      'Esa grabación ha sido demasiado corta, inténtalo otra vez';

  @override
  String get voiceModeSetting => 'Cómo funciona';

  @override
  String get voiceModeHold => 'Mantener pulsado para hablar';

  @override
  String get voiceModeTap => 'Tocar para empezar / tocar para parar';

  @override
  String get voiceModeInfo =>
      'Mantener pulsado para hablar: escucha mientras mantienes el botón y crea la nota al soltar. Tocar para empezar: un toque inicia la grabación y un segundo toque la termina.';

  @override
  String get voiceHeardLive => 'Voz detectada';

  @override
  String get voiceCaptureReady => 'Listo para hablar';

  @override
  String get voiceCaptureEditHint => 'Toca el texto para editarlo';

  @override
  String voiceCapturePunctuation(String language) {
    return '$language · puntuación automática';
  }

  @override
  String get voiceCaptureAddToNote => 'Añadir a la nota';

  @override
  String get voiceCaptureCreateNote => 'Crear nota nueva';

  @override
  String get voiceCaptureAiNote => 'Nota IA';

  @override
  String get voiceCapturePlainNote => 'Nota simple';

  @override
  String get voiceCloseTitle => 'Tu dictado sigue aquí';

  @override
  String get voiceCloseKeepTalking => 'Seguir hablando';

  @override
  String get voiceCaptureRestart => 'Volver a grabar';

  @override
  String get voiceChipSummarizeAdd => 'Añadir como resumen';

  @override
  String get voiceChipSummarizeSave => 'Guardar como resumen';

  @override
  String get voiceChipToItems => 'Dividir en elementos';

  @override
  String get voiceChipAsList => 'Convertir en lista';

  @override
  String get voiceChipFix => 'Corregir';

  @override
  String get voiceChipCompose => 'Deja que el asistente escriba';

  @override
  String get editorToolList => 'Lista';

  @override
  String get permissionsTitle => 'Permisos';

  @override
  String get permMic => 'Micrófono';

  @override
  String get permMicInfo => 'Necesario para las notas de voz y el dictado';

  @override
  String get permNotifications => 'Notificaciones';

  @override
  String get permNotificationsInfo =>
      'Necesario para los recordatorios y el resumen diario';

  @override
  String get permBattery => 'Optimización de batería';

  @override
  String get permBatteryInfo =>
      'Excluye la app de las restricciones de batería para que los recordatorios lleguen a tiempo';

  @override
  String get showTagChips => 'Mostrar los chips de etiqueta';

  @override
  String get showFolderChips => 'Mostrar los chips de carpeta';

  @override
  String videoTooBigForAi(int mb) {
    return 'El vídeo es demasiado grande para enviarlo a la IA ($mb MB). Graba uno más corto.';
  }

  @override
  String get permCamera => 'Cámara';

  @override
  String get permCameraInfo =>
      'Necesario para las notas de vídeo y para hacer fotos';

  @override
  String get permOnboardTitle => 'Antes de empezar';

  @override
  String get permOnboardInfo =>
      'Notas solo pide estos permisos cuando usas la función correspondiente. Puedes concederlos ahora aquí abajo, o cambiarlos más tarde en Ajustes > Permisos.';

  @override
  String get permOnboardGrantAll => 'Conceder permisos';

  @override
  String get permOnboardSkip => 'Ahora no';

  @override
  String get newVideoNote => 'Nota de vídeo';

  @override
  String get videoLocalOnly =>
      'Este vídeo se guarda solo en este dispositivo (no se sube a la nube)';

  @override
  String get videoToNote => 'Crear una nota a partir del vídeo';

  @override
  String get videoToNoteRunning => 'Revisando el vídeo…';

  @override
  String get permGranted => 'Concedido';

  @override
  String get permGrant => 'Conceder';

  @override
  String get permOpenSettings => 'Abrir los ajustes';

  @override
  String get newHandwriting => 'Escritura a mano';

  @override
  String get newVoiceCapture => 'Nota de voz';

  @override
  String get suggestTitle => 'Sugerir un título';

  @override
  String get noteMetaMenu => 'Etiqueta · Título · Recordatorio';

  @override
  String get folder => 'Carpeta';

  @override
  String get noFolder => 'Sin carpeta';

  @override
  String get newFolder => 'Nueva carpeta';

  @override
  String get editFolder => 'Editar la carpeta';

  @override
  String get deleteFolder => 'Eliminar la carpeta';

  @override
  String deleteFolderConfirm(String name) {
    return 'Se eliminará la carpeta «$name». Las notas que contiene no se eliminan: simplemente se quedarán sin carpeta.';
  }

  @override
  String get folderNameHint => 'Nombre de la carpeta';

  @override
  String get folderIcon => 'Icono';

  @override
  String get editFilters => 'Editar los filtros';

  @override
  String get editFiltersInfo =>
      'Elige qué filtros aparecen en la pantalla de inicio. Ocultar filtros mantiene la página despejada.';

  @override
  String get select => 'Seleccionar';

  @override
  String get noteArchived => 'Nota archivada';

  @override
  String deleteChecked(int count) {
    return 'Eliminar los marcados ($count)';
  }

  @override
  String get removeItem => 'Eliminar el elemento';

  @override
  String get copyWholeNote => 'Copiar la nota entera';

  @override
  String get allCopied => 'Se ha copiado la nota entera al portapapeles';

  @override
  String get speechPlay => 'Leer en voz alta';

  @override
  String get speechPause => 'Pausar';

  @override
  String get speechResume => 'Reanudar';

  @override
  String get speechStop => 'Parar';

  @override
  String get speechRate => 'Velocidad de lectura';

  @override
  String get speechSystemDefault => 'Predeterminado del sistema';

  @override
  String get speechNoVoices =>
      'No hay ninguna voz instalada en este dispositivo';

  @override
  String speechVoiceLanguage(String language) {
    return 'Voz en $language';
  }

  @override
  String get speechVoiceAutoInfo =>
      'Los demás idiomas se leen automáticamente con voz masculina';

  @override
  String get listening => 'Escuchando...';

  @override
  String get listenPlay => 'Escuchar';

  @override
  String get listenReadingPdf => 'Leyendo el documento...';

  @override
  String get listenConvertWithAi => 'Convertir con IA';

  @override
  String get listenMakePodcast => 'Pódcast completo';

  @override
  String get listenMakePodcastSummary => 'Pódcast del resumen';

  @override
  String get listenOriginalText => 'Texto original';

  @override
  String get listenPodcastReady => 'La narración del pódcast está lista';

  @override
  String get listenPodcastCached => 'Generado antes: no se han gastado tokens';

  @override
  String get listenRegenerate => 'Generar otra vez';

  @override
  String get listenNoText =>
      'De este documento no ha salido texto legible. Un PDF escaneado no tiene capa de texto, y una presentación puede contener solo imágenes.';

  @override
  String get readDocument => 'Leer un documento (Word, PDF, diapositivas)';

  @override
  String get readDocUnsupported => 'Este tipo de archivo no se puede leer.';

  @override
  String get exportPdf => 'Exportar como PDF';

  @override
  String get pdfTitleField => 'Título';

  @override
  String get pdfContentField => 'Contenido';

  @override
  String get pdfMarkupHint =>
      'Los signos al principio de una línea se convierten en formato: [x] y [ ] para casillas, 1. para lista numerada y - para una viñeta.';

  @override
  String get pdfIncludeDate => 'Incluir la fecha';

  @override
  String get exportIncludeImages => 'Incluir las imágenes';

  @override
  String get exportWord => 'Compartir como Word (.docx)';

  @override
  String get pdfPreview => 'Vista previa';

  @override
  String get largeAttachmentTitle => 'Archivo grande';

  @override
  String largeAttachmentBody(String size) {
    return 'Este archivo ocupa $size MB. Los PDF no se pueden comprimir; se subirá tal cual y contará en tu almacenamiento. ¿Continuar?';
  }

  @override
  String get speechRateForeign => 'Velocidad en otros idiomas';

  @override
  String notesArchivedCount(int count) {
    return '$count notas archivadas';
  }

  @override
  String get backgroundColor => 'Color de fondo';

  @override
  String get backgroundColorInfo => 'El color de fondo de la nota';

  @override
  String get frameColor => 'Marco';

  @override
  String get frameColorInfo =>
      'Dibuja un marco alrededor de la nota en el color que elijas';

  @override
  String get sortBy => 'Ordenar';

  @override
  String get reorderNotes => 'Reordenar las notas';

  @override
  String get reorderModeActive => 'Arrastra las tarjetas para reordenarlas';

  @override
  String get reorderDone => 'Listo';

  @override
  String get sortManual => 'Manual (orden arrastrado)';

  @override
  String get sortUpdated => 'Editadas recientemente';

  @override
  String get sortCreated => 'Fecha de creación';

  @override
  String get sortTitle => 'Por título (A–Z)';

  @override
  String get foldersSection => 'Carpetas';

  @override
  String get tagsSection => 'Etiquetas';

  @override
  String get expandFilters => 'Desplegar los filtros';

  @override
  String get collapseFilters => 'Plegar los filtros';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get languageSystem => 'Idioma del sistema';

  @override
  String get settingsSpeech => 'Lectura en voz alta';

  @override
  String get aiAdvanced => 'Avanzado: modelo y clave de API';

  @override
  String get aiAdvancedInfo =>
      'Elección de modelo y tu propia clave de Gemini. La mayoría no lo necesita.';

  @override
  String get openBriefing => 'Abrir el resumen';

  @override
  String get syncTitle => 'Sincronización';

  @override
  String get syncLimitTitle => 'Límite de subida automática';

  @override
  String get syncLimitInfo =>
      'Los adjuntos más grandes se quedan en el dispositivo y no se suben. El texto de la nota siempre se sincroniza.';

  @override
  String get syncLimitUnlimited => 'Sin límite';

  @override
  String get backupTitle => 'Copia de seguridad';

  @override
  String get importBackup => 'Restaurar desde una copia (JSON)';

  @override
  String importBackupDone(int count) {
    return '$count notas restauradas';
  }

  @override
  String get importBackupInvalid => 'Archivo de copia no válido';

  @override
  String get aiHubTitle => 'IA';

  @override
  String get aiSummarizeInfo => 'Genera un resumen breve';

  @override
  String get aiAnalyzeInfo => 'Enumera los puntos clave y las tareas';

  @override
  String get aiImproveInfo => 'Cambia el tono: formal, más corto o lista';

  @override
  String get aiTranslateInfo => 'Traduce la nota al idioma que elijas';

  @override
  String get aiFixNoteInfo => 'Corrige ortografía y puntuación';

  @override
  String get moveToFolder => 'Mover a una carpeta';

  @override
  String get voiceAssistantBadge => 'Asistente';

  @override
  String get assistantGenericError => 'Algo ha ido mal. ¿Lo intentas otra vez?';

  @override
  String get quickAddTooltip => 'Nota nueva: elige un tipo';

  @override
  String get autoTitleSetting => 'Sugerir un título al cerrar';

  @override
  String get autoTitleSettingInfo =>
      'Al salir del editor, una nota que se quede sin título recibe uno corto escrito a partir de su contenido.';

  @override
  String get hubChatInfo => 'Preguntas respondidas a partir de tus notas';

  @override
  String get hubBriefingInfo =>
      'Tu día de un vistazo: recordatorios y notas recientes';

  @override
  String get hubReadInfo => 'Escucha un documento PDF o Word';

  @override
  String get annotate => 'Anotar';

  @override
  String get annotateDone => 'Terminar de anotar';

  @override
  String get newPdfNote => 'PDF ekle not al';

  @override
  String get imageNotePreparing => 'Colocando las imágenes en un documento…';

  @override
  String get newImageNote => 'Añadir imagen y tomar notas';

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
  String get pdfAddBlankPage => 'Añadir página en blanco';

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
  String get crop => 'Recortar';

  @override
  String get cropApply => 'Aplicar el recorte';

  @override
  String get cropReset => 'Restablecer la selección';

  @override
  String get cropHint =>
      'Arrastra las esquinas para elegir un área. El recorte no se puede deshacer.';

  @override
  String get cropFailed => 'No se ha podido recortar la imagen.';

  @override
  String get penBallpoint => 'Bolígrafo';

  @override
  String get penMarker => 'Rotulador';

  @override
  String get penHighlighter => 'Marcador fluorescente';

  @override
  String get eraser => 'Goma de borrar';

  @override
  String get inkArrow => 'Flecha';

  @override
  String get clearInk => 'Borrar las anotaciones';

  @override
  String get inkTwoFingerHint =>
      'Un dedo dibuja · dos dedos desplazan y hacen zoom';

  @override
  String get slideOpenFailed => 'No se ha podido abrir la presentación';

  @override
  String get newPhotoNote => 'Nota con foto';

  @override
  String get newScanNote => 'Escanear un documento';

  @override
  String get scanDocument => 'Escanear documento';

  @override
  String get scanDocumentSubtitle =>
      'Encuentra los bordes, endereza la página y la añade';

  @override
  String get scanUnsupported =>
      'Este dispositivo no admite el escaneo de documentos';

  @override
  String scanFailed(String error) {
    return 'No se ha podido escanear el documento: $error';
  }

  @override
  String scanPagesAdded(int count) {
    return '$count página(s) añadida(s) a la nota';
  }

  @override
  String get scanTextTitle => '¿Reconocer también el texto?';

  @override
  String get scanTextBody =>
      'Se reconoce el texto de las páginas y se escribe en la nota. La imagen se queda tal cual. Tarda unos segundos por página.';

  @override
  String get scanImageOnly => 'Solo la imagen';

  @override
  String get scanRecognizeText => 'Reconocer el texto';

  @override
  String get scanRecognizing => 'Reconociendo el texto…';

  @override
  String get takePhoto => 'Hacer una foto';

  @override
  String get qrScanTitle => 'Escanear un código QR';

  @override
  String get qrScanSubtitle => 'Léelo con la cámara o desde una foto';

  @override
  String get qrScanHint => 'Encuadra el código dentro del marco';

  @override
  String get qrFromPhoto => 'Leer desde una foto';

  @override
  String get qrNotFound => 'No se ha encontrado ningún código en esta imagen';

  @override
  String get qrLinkFound => 'Este código es un enlace';

  @override
  String get qrOpenLink => 'Ir al enlace';

  @override
  String get qrSaveToNote => 'Guardar en una nota';

  @override
  String get openLink => 'Abrir el enlace';

  @override
  String get linkOpenFailed => 'No se ha podido abrir el enlace';

  @override
  String qrScanFailed(String error) {
    return 'No se ha podido leer el código: $error';
  }

  @override
  String get qrTorch => 'Linterna';

  @override
  String attachmentsCount(int count) {
    return 'Adjuntos ($count)';
  }

  @override
  String get hideAttachments => 'Ocultar';

  @override
  String get showAttachments => 'Mostrar';

  @override
  String get videoBack10 => '10 s atrás';

  @override
  String get videoForward10 => '10 s adelante';

  @override
  String get selectAllItems => 'Seleccionar todo';

  @override
  String get showAllChips => 'Mostrar todo';

  @override
  String get hideAllChips => 'Ocultar todo';

  @override
  String get chipPickInfo =>
      '¿Qué chips de carpeta y etiqueta deben aparecer en la pantalla de inicio?';

  @override
  String get hiddenFolder => 'Carpeta oculta';

  @override
  String get hiddenFolderInfo =>
      'Una carpeta oculta y las notas que contiene no aparecen en la pantalla de inicio. Para mostrarlas, elige «Carpetas ocultas» en el menú ⋮ y verifica tu identidad.';

  @override
  String get hiddenFoldersMenu => 'Carpetas ocultas';

  @override
  String get hiddenFolderAuthReason =>
      'Verifica tu identidad para mostrar las carpetas ocultas';

  @override
  String get hiddenFoldersShown => 'Se están mostrando las carpetas ocultas';

  @override
  String get hiddenFoldersHiddenAgain =>
      'Las carpetas ocultas vuelven a estar escondidas';

  @override
  String get makeFolderHidden => 'Ocultar';

  @override
  String get makeFolderVisible => 'Dejar de ocultar';

  @override
  String gridColumnsCount(int count) {
    return '$count columnas';
  }

  @override
  String get addImageOnPageSubtitle =>
      'Se coloca en la página y el texto la rodea';

  @override
  String get addImageAsFile => 'Añadir imagen como archivo';

  @override
  String get addImageAsFileSubtitle =>
      'No entra en la página, queda en la barra de adjuntos';

  @override
  String get moveImageToAttachments => 'Mover a los adjuntos';

  @override
  String get moveImageToPage => 'Colocar en la página';

  @override
  String get attachmentCopied => 'Adjunto copiado';

  @override
  String get pasteAttachment => 'Pegar el adjunto copiado';

  @override
  String get fullscreen => 'Pantalla completa';

  @override
  String get more => 'Más';

  @override
  String get undone => 'Deshecho';

  @override
  String get filterOthers => 'Otros';

  @override
  String get chatSuggestion1 => '¿Qué falta en mi lista de la compra?';

  @override
  String get chatSuggestion2 => 'Resume las notas de trabajo de esta semana';

  @override
  String get chatSuggestion3 => '¿Tengo algún recordatorio para mañana?';

  @override
  String get aiPointsToday => 'Puntos de hoy';

  @override
  String aiPointsOf(int used, int total) {
    return '$used / $total';
  }

  @override
  String get aiPointsRenew => 'se renuevan a medianoche';

  @override
  String get aiChatWithNotes => 'Asistente de notas';

  @override
  String get aiChatInputHint => 'Pregunta algo sobre tus notas…';

  @override
  String get aiChatLooking => 'buscando en tus notas…';

  @override
  String get aiChatFullScreen => 'Pantalla completa';

  @override
  String get aiOnYourNotes => 'EN TUS NOTAS';

  @override
  String get aiTaskDuplicates => 'Limpiar duplicados';

  @override
  String aiTaskDuplicatesInfo(int count) {
    return '$count notas duplicadas';
  }

  @override
  String get duplicatesTitle => 'Notas duplicadas';

  @override
  String get duplicatesHint =>
      'Se conserva la nota más antigua de cada grupo, el resto va a la papelera.';

  @override
  String get duplicatesKeepBadge => 'se conserva';

  @override
  String get duplicatesDeleteAll => 'Mover duplicados a la papelera';

  @override
  String duplicatesDone(int count) {
    return '$count duplicados movidos a la papelera';
  }

  @override
  String get aiRecentActions => 'ACCIONES RECIENTES';

  @override
  String get aiHistoryClear => 'Borrar';

  @override
  String get aiHistoryQuestion => 'Pregunta';

  @override
  String get aiHistoryNoteAction => 'Acción de nota';

  @override
  String get aiHistoryVoiceNote => 'Nota de voz';

  @override
  String get aiRecentOps => 'RECIENTE';

  @override
  String get aiTaskWeekSummary => 'Resumir la semana';

  @override
  String get aiTaskWeekSummaryInfo => 'Un resumen de los últimos 7 días';

  @override
  String get aiTaskTagUntagged => 'Etiquetar sin etiqueta';

  @override
  String aiTaskTagUntaggedInfo(int count) {
    return '$count notas esperando etiquetas';
  }

  @override
  String get aiTaskSuggestTitles => 'Sugerir títulos';

  @override
  String aiTaskSuggestTitlesInfo(int count) {
    return '$count notas no tienen título';
  }

  @override
  String get sectionPinnedShort => 'FIJADO';

  @override
  String get sectionToday => 'HOY';

  @override
  String get sectionThisWeek => 'ESTA SEMANA';

  @override
  String get sectionEarlier => 'ANTERIOR';

  @override
  String sectionNoteCount(int count) {
    return '$count notas';
  }

  @override
  String get emptySearchSemanticHint => 'Prueba la pestaña Significado';

  @override
  String get quickCaptureHint => 'Nota nueva…';

  @override
  String get quickCaptureSave => 'Guardar';

  @override
  String get quickAddWrite => 'ESCRIBIR';

  @override
  String get quickAddCapture =>
      'CAPTURAR — CREA UNA NOTA A PARTIR DEL CONTENIDO';

  @override
  String get viewToggle => 'Vista';

  @override
  String get searchModeText => 'Texto';

  @override
  String get searchModeMeaning => 'Significado';

  @override
  String get filterReminded => 'Con recordatorio';

  @override
  String get filterLocked => 'Bloqueado';

  @override
  String get sortColor => 'Color';

  @override
  String get sortActive => 'Más trabajadas';

  @override
  String get voicePreview => 'Probar la voz';

  @override
  String get voicePreviewCached =>
      'La muestra se genera una vez y luego se reproduce desde el almacenamiento';

  @override
  String get reorderHint =>
      'Mantén pulsada una tarjeta y arrástrala donde quieras';

  @override
  String get filterSheetTitle => 'Filtrar';

  @override
  String get filterReset => 'Restablecer';

  @override
  String get filterSectionStatus => 'ESTADO';

  @override
  String get filterSectionFolder => 'CARPETA';

  @override
  String get filterSectionTag => 'ETIQUETA';

  @override
  String get filterSectionSort => 'ORDENAR';

  @override
  String get filterFavoriteHint =>
      'Toca una estrella para tener esa opción en la pantalla principal';

  @override
  String get filterSheetSortHint =>
      'Los grupos de fechas (HOY, ESTA SEMANA…) solo se muestran al ordenar por última edición.';

  @override
  String get formatTitle => 'Formato';

  @override
  String get formatBold => 'Negrita';

  @override
  String get formatItalic => 'Cursiva';

  @override
  String get formatUnderline => 'Subrayado';

  @override
  String get formatTextColor => 'Color del texto';

  @override
  String get formatHighlight => 'Resaltado';

  @override
  String get formatInfo =>
      'El formato viaja dentro del texto como marcas (por ejemplo **negrita**); las marcas no aparecen al exportar ni al leer en voz alta.';

  @override
  String get formatMenu => 'Formato…';

  @override
  String get noteFont => 'Fuente';

  @override
  String get noteFontDefault => 'Predeterminada';

  @override
  String get noteFontSerif => 'Libro (serif)';

  @override
  String get noteFontMono => 'Máquina de escribir';

  @override
  String get noteTextSize => 'Tamaño del texto';

  @override
  String get formatClear => 'Borrar formato';

  @override
  String get noteTextOpacity => 'Transparencia';

  @override
  String get assistantVoiceSetting => 'El asistente responde en voz alta';

  @override
  String get assistantVoiceSettingInfo =>
      'El asistente de voz lee su respuesta en voz alta (solo en el teléfono).';

  @override
  String get assistantMute => 'Silenciar';

  @override
  String get assistantUnmute => 'Activar sonido';

  @override
  String get assistantMakeNote => 'Convertir en nota igualmente';

  @override
  String get assistantNoteCreated => 'Nota creada';

  @override
  String get noteNotFound => 'Nota no encontrada. Puede que se haya eliminado.';

  @override
  String get back => 'Atrás';

  @override
  String get addTextBlock => 'Añadir texto';

  @override
  String get attachNoteContent => 'Not içeriği';

  @override
  String get noteBackgroundImage => 'Imagen de fondo';

  @override
  String get chooseBackgroundImage => 'Elegir imagen';

  @override
  String get changeBackgroundImage => 'Cambiar imagen';

  @override
  String get removeBackgroundImage => 'Quitar fondo';

  @override
  String get dashboardBackground => 'Fondo de la pantalla principal';

  @override
  String get dashboardBackgroundInfo =>
      'Imagen detrás de la cuadrícula de notas (solo en este dispositivo).';

  @override
  String get aiProvider => 'Proveedor de IA';

  @override
  String get aiProviderInfo =>
      'Elige el proveedor al que pertenece tu clave. La clave de cada proveedor se guarda por separado, así que cambiar no exige volver a introducirla.';

  @override
  String get apiKeyFieldLabel => 'Clave de API';

  @override
  String get getApiKey => '¿Dónde consigo una clave?';

  @override
  String get recommendedModel => 'Recomendado';

  @override
  String get freeTierBadge => 'Tiene nivel gratuito';

  @override
  String get continueWithoutAccount => 'Continuar sin cuenta';

  @override
  String get localAccountInfo =>
      'Tus notas se quedan solo en este dispositivo: no se abren en otro, se pierden si desinstalas la app y la IA integrada está desactivada. Puedes vincular una cuenta de Google cuando quieras; tus notas se conservan.';

  @override
  String get localAccountBadge => 'Cuenta local';

  @override
  String get linkGoogleAccount => 'Vincular cuenta de Google';

  @override
  String get accountLinked =>
      'Tu cuenta de Google está vinculada. Tus notas ya se respaldan.';

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
      'El acceso sin Google está desactivado: el inicio de sesión anónimo no está habilitado en la consola de Firebase. Inicia sesión con Google o inténtalo cuando un administrador lo habilite.';

  @override
  String get googleSignInUnavailable =>
      'El acceso con Google está desactivado: el proveedor de Google no está habilitado en la consola de Firebase.';

  @override
  String get signInNetworkError =>
      'No se pudo conectar a internet. Comprueba tu conexión e inténtalo de nuevo.';

  @override
  String get signInCanceled => 'Inicio de sesión cancelado.';

  @override
  String get cardRichPreview => 'Texto con formato en las tarjetas';

  @override
  String get cardRichPreviewInfo =>
      'Los colores, resaltados, negritas y subrayados de tus notas también se ven en las tarjetas de la pantalla principal. Si se desactiva, las tarjetas muestran texto sin formato.';

  @override
  String get fontSizeSmall => 'Pequeño';

  @override
  String get fontSizeMedium => 'Mediano';

  @override
  String get fontSizeLarge => 'Grande';

  @override
  String get fontSizeXLarge => 'Muy grande';

  @override
  String get appFontSetting => 'Fuente';

  @override
  String get appFontInfo =>
      'La fuente usada en toda la app. La fuente propia de una nota tiene prioridad. Todas las fuentes vienen con la app: no hace falta internet.';

  @override
  String get fontGroupSans => 'Palo seco';

  @override
  String get fontGroupSerif => 'Serif';

  @override
  String get fontGroupMono => 'Monoespaciada';

  @override
  String get fontGroupHand => 'Manuscrita';

  @override
  String get appFontDefaultSuffix => 'predeterminada';

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
      'La voz de IA necesita tu propia clave de Gemini. Hasta entonces se lee con la voz del dispositivo.';

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
  String get shareAsText => 'Como texto sin formato';

  @override
  String get shareAsTextInfo =>
      'Envía el texto de la nota y las notas de página a cualquier aplicación.';

  @override
  String get shareAsTextEmpty => 'Esta nota no tiene texto para compartir.';

  @override
  String get sharePdfWithBubbles => 'Como PDF con globos';

  @override
  String get sharePdfWithBubblesInfo =>
      'Los globos, resaltados y dibujos se estampan dentro del PDF; cualquiera puede abrirlo y en Not se abre editable.';

  @override
  String get sharePdfWithBubblesNone =>
      'Esta nota no tiene ningún PDF con globos o dibujos.';

  @override
  String get sharePdfWithBubblesPreparing => 'Preparando el PDF con globos…';

  @override
  String get sharePdfWithBubblesSuffix => ' (con globos)';

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
  String get formatRemove => 'Quitar';

  @override
  String get exportTitle => 'Exportar';

  @override
  String get exportNotesOption => 'Texto de la nota (PDF / Word)';

  @override
  String get exportNotesOptionInfo =>
      'Texto e imágenes de la nota; los globos no se incluyen.';

  @override
  String get captureNoteTitle => 'Título de la nota (opcional)';

  @override
  String get captureNoteTitleHint => 'El nuevo documento recibirá este nombre';

  @override
  String get imageOcrTitle => 'Reconocer el texto de la imagen';

  @override
  String get imageOcrNone => 'No se encontró texto en esta imagen.';

  @override
  String imageOcrHint(int count) {
    return '$count líneas reconocidas · toca para seleccionar';
  }

  @override
  String imageOcrSelected(int count) {
    return '$count líneas seleccionadas';
  }

  @override
  String get imageOcrShort => 'Reconocer texto';

  @override
  String get imageOcrWorking => 'Reconociendo texto…';

  @override
  String get imageOcrSelectHint =>
      'Toca: palabra · Mantén y arrastra: letra a letra';

  @override
  String get imageOcrInsert => 'Añadir a la nota';

  @override
  String get imageOcrZoomIn => 'Acercar';

  @override
  String get imageOcrZoomOut => 'Alejar';

  @override
  String get selectImages => 'Seleccionar imágenes';

  @override
  String get exportImages => 'Imágenes';

  @override
  String get exportImagesInfo =>
      'El texto fluye junto a las imágenes estrechas alineadas a la izquierda o derecha; las centradas ocupan todo el ancho.';

  @override
  String get exportAlignLeft => 'Izq.';

  @override
  String get exportAlignCenter => 'Centro';

  @override
  String get exportAlignRight => 'Der.';

  @override
  String get exportImageWidth => 'Ancho';

  @override
  String get exportImageLine => 'Posición';

  @override
  String get aiModelSearch => 'Buscar modelos';

  @override
  String get aiModelOthers => 'OTROS MODELOS';

  @override
  String get aiModelNoMatch => 'Ningún modelo coincide.';

  @override
  String get aiModelAutoInfo =>
      'La app prueba en orden los modelos más adecuados.';

  @override
  String imageOcrCharsSelected(int count) {
    return '$count caracteres seleccionados';
  }

  @override
  String imagesSelectedCount(int count) {
    return '$count imágenes seleccionadas';
  }

  @override
  String attachmentsCopiedCount(int count) {
    return '$count adjuntos';
  }

  @override
  String exportImageLineOf(int count) {
    return '/ $count líneas';
  }

  @override
  String get aiModelShowAll => 'Mostrar todos';

  @override
  String get aiModelShowAllInfo => 'También muestra modelos que la app no usa.';

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
  String get archiveGeneralPage => 'Genel';

  @override
  String get archiveRenamePage => 'Sayfayı yeniden adlandır';

  @override
  String get archiveDeletePage => 'Sayfayı sil';

  @override
  String archiveDeletePageInfo(String name) {
    return '\"$name\" sayfası silinsin mi? İçindeki girdiler silinmez, Genel sayfasına taşınır.';
  }

  @override
  String get archivePrevPage => 'Önceki sayfa';

  @override
  String get archiveNextPage => 'Sonraki sayfa';

  @override
  String get archiveAddEntry => 'Sayfaya ekle';

  @override
  String get archiveMoveEntry => 'Başka sayfaya taşı';

  @override
  String archiveEntryCount(int count) {
    return '$count girdi';
  }

  @override
  String get archivePageName => 'Sayfa adı (ör. Faturalar)';

  @override
  String get archivePageEmpty => 'Boş sayfa';

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
      'Yapay zekânın önerdiği sayfa. Boş bırakılırsa Genel sayfasına düşer.';

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
  String get archivePlaceOnPage => 'Sayfaya yerleştir';

  @override
  String get archivePaper => 'Kâğıt';

  @override
  String get archivePaperLined => 'Çizgili';

  @override
  String get archivePaperGrid => 'Kareli';

  @override
  String get archivePaperDots => 'Noktalı';

  @override
  String get archivePaperPlain => 'Düz';

  @override
  String get archiveWriteHint => 'Bu sayfaya yaz…';

  @override
  String get archivePageTitleHint => 'Sayfa adı';

  @override
  String archiveAutoPageName(int number) {
    return 'Sayfa $number';
  }

  @override
  String get archiveNewPageHint =>
      'Yazmaya başla ya da bir şey ekle — sayfa kendiliğinden açılır.';

  @override
  String get archiveNewPageLabel => 'Yeni sayfa';

  @override
  String get archiveAttachmentsHeading => 'Bu sayfadaki dosyalar';

  @override
  String get archiveNotesHeading => 'Notlar';

  @override
  String get archiveOpenPage => 'Sayfaya git';

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
  String folderNoteCount(int count) {
    return '$count not';
  }

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

  @override
  String get archivePagesOverview => 'Sayfalar';

  @override
  String get archiveSemanticHint => 'Defterde anlamıyla ara…';

  @override
  String get semanticUnavailable =>
      'Anlamsal arama şu an kullanılamıyor; metin araması gösteriliyor.';

  @override
  String get sharedNotifications => 'Paylaşılan klasör bildirimleri';

  @override
  String get sharedNotificationsInfo =>
      'Karşı taraf not eklediğinde/değiştirdiğinde ya da sohbete yazdığında telefona bildirim gelsin. Kapalıyken ana ekrandaki sayaç yine çalışır.';

  @override
  String get copyAsText => 'Metni kopyala';

  @override
  String get searchAttachments => 'Ek içeriğinde de ara';

  @override
  String get searchAttachmentsInfo =>
      'PDF\'lerin metnini ve görsellerdeki yazıyı (OCR) da tarar. Açıldığında cihazdaki ekler bir kez taranır; sonrası önbellekten gelir.';

  @override
  String get selectAll => 'Tümünü seç';

  @override
  String get selectNone => 'Seçimi kaldır';

  @override
  String get duplicateNote => 'Notu çoğalt';

  @override
  String get noteDuplicated => 'Not çoğaltıldı';

  @override
  String notesDuplicatedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count not çoğaltıldı',
      one: '1 not çoğaltıldı',
    );
    return '$_temp0';
  }

  @override
  String get noteStatsTitle => 'Not istatistikleri';

  @override
  String noteStatsWords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kelime',
      one: '1 kelime',
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
      other: '$count madde',
      one: '1 madde',
    );
    return '$_temp0';
  }

  @override
  String noteStatsAttachments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ek',
      one: '1 ek',
    );
    return '$_temp0';
  }

  @override
  String noteStatsReadTime(int count) {
    return '~$count dk okuma';
  }

  @override
  String get scrollToTop => 'Başa dön';

  @override
  String searchResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sonuç',
      one: '1 sonuç',
    );
    return '$_temp0';
  }

  @override
  String get clearSearch => 'Aramayı temizle';

  @override
  String trashDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gün sonra kalıcı silinir',
      one: '1 gün sonra kalıcı silinir',
    );
    return '$_temp0';
  }

  @override
  String get trashLastDay => 'Bugün kalıcı silinecek';

  @override
  String get noteRestored => 'Not geri yüklendi';

  @override
  String get restoreAll => 'Hepsini geri yükle';

  @override
  String notesRestoredCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count not geri yüklendi',
      one: '1 not geri yüklendi',
    );
    return '$_temp0';
  }

  @override
  String get emptyingTrash => 'Çöp boşaltılıyor…';

  @override
  String get reminderRemoved => 'Hatırlatıcı kaldırıldı';

  @override
  String get reminderOverdue => 'Gecikti';

  @override
  String get reminderQuickTonight => 'Bu akşam 18:00';

  @override
  String get reminderQuickTomorrow => 'Yarın 09:00';

  @override
  String get reminderQuickNextWeek => 'Gelecek hafta';

  @override
  String get reminderQuickCustom => 'Tarih seç…';

  @override
  String get reminderQuickTitle => 'Ne zaman hatırlatılsın?';

  @override
  String get reminderSnooze => '1 saat ertele';

  @override
  String get reminderSnoozed => 'Hatırlatıcı ertelendi';

  @override
  String reminderCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hatırlatıcı',
      one: '1 hatırlatıcı',
    );
    return '$_temp0';
  }

  @override
  String get relativeJustNow => 'az önce';

  @override
  String relativeInMinutes(int count) {
    return '$count dk sonra';
  }

  @override
  String relativeInHours(int count) {
    return '$count sa sonra';
  }

  @override
  String relativeInDays(int count) {
    return '$count gün sonra';
  }

  @override
  String relativeAgoMinutes(int count) {
    return '$count dk önce';
  }

  @override
  String relativeAgoHours(int count) {
    return '$count sa önce';
  }

  @override
  String relativeAgoDays(int count) {
    return '$count gün önce';
  }

  @override
  String get inboxDeclined => 'Gelen not silindi';

  @override
  String inboxCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gelen not',
      one: '1 gelen not',
    );
    return '$_temp0';
  }

  @override
  String get appVersion => 'Uygulama sürümü';

  @override
  String get appVersionCopied => 'Sürüm bilgisi kopyalandı';

  @override
  String notesMovedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count not taşındı',
      one: '1 not taşındı',
    );
    return '$_temp0';
  }

  @override
  String get mediaPlay => 'Oynat';

  @override
  String get mediaPause => 'Duraklat';

  @override
  String get decrease => 'Azalt';

  @override
  String get increase => 'Artır';

  @override
  String get tagManageTitle => 'Etiketi yönet';

  @override
  String get tagRename => 'Etiketi yeniden adlandır';

  @override
  String get tagRenameHint => 'Yeni etiket adı';

  @override
  String get tagDelete => 'Etiketi sil';

  @override
  String tagDeleteConfirm(String tag) {
    return '\"$tag\" etiketi tüm notlardan kaldırılsın mı? Notlar silinmez.';
  }

  @override
  String get tagRenamed => 'Etiket yeniden adlandırıldı';

  @override
  String get tagDeleted => 'Etiket kaldırıldı';

  @override
  String get tagLongPressHint =>
      'Etikete uzun bas: yeniden adlandır ya da sil.';

  @override
  String get recentSearches => 'Son aramalar';

  @override
  String get clearRecentSearches => 'Geçmişi temizle';

  @override
  String get imagesEqualizeSize => 'Boyutları eşitle';

  @override
  String get imagesFitRow => 'Satıra sığdır';
}
