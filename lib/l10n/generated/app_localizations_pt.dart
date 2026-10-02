// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appName => 'Notas';

  @override
  String get loginTagline => 'As suas notas, em todos os dispositivos';

  @override
  String get signInWithGoogle => 'Iniciar sessão com o Google';

  @override
  String loginError(String error) {
    return 'Falha ao iniciar sessão: $error';
  }

  @override
  String get searchHint => 'Pesquisar nas notas...';

  @override
  String get filterAll => 'Todas';

  @override
  String get filterText => 'Texto';

  @override
  String get filterChecklist => 'Lista';

  @override
  String get filterOrdered => 'Numerada';

  @override
  String get filterPinned => 'Fixadas';

  @override
  String get filterStarred => 'Favoritas';

  @override
  String get star => 'Adicionar aos favoritos';

  @override
  String get unstar => 'Remover dos favoritos';

  @override
  String editedAt(String date) {
    return 'Editada: $date';
  }

  @override
  String get sectionPinned => 'Fixadas';

  @override
  String get sectionOthers => 'Outras';

  @override
  String get emptyNotes => 'Ainda não há notas';

  @override
  String get emptyNotesHint => 'Toque em + para criar a sua primeira nota';

  @override
  String get emptySearch => 'Sem resultados';

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
    return '$count selecionadas';
  }

  @override
  String get deleteSelected => 'Eliminar selecionadas';

  @override
  String get undo => 'Anular';

  @override
  String get redo => 'Refazer';

  @override
  String get titleHint => 'Título';

  @override
  String get bodyHint => 'Nota...';

  @override
  String get newItemHint => 'Novo item';

  @override
  String moreItemsCount(int count) {
    return '+$count outros itens';
  }

  @override
  String get addAttachment => 'Adicionar';

  @override
  String get addAttachmentMore => 'Mais tipos de anexo…';

  @override
  String get addImage => 'Adicionar imagem';

  @override
  String get addPdf => 'Adicionar PDF';

  @override
  String get addSlide => 'Adicionar diapositivos';

  @override
  String get pasteImage => 'Colar imagem da área de transferência';

  @override
  String get clipboardEmpty => 'Não há imagens na área de transferência';

  @override
  String get noNoteSelected => 'Escolha uma nota à esquerda';

  @override
  String attachmentFailed(String error) {
    return 'Não foi possível adicionar o anexo: $error';
  }

  @override
  String get attachmentCopying => 'Copiando...';

  @override
  String get attachmentUploading => 'A carregar...';

  @override
  String get attachmentUploadFailed =>
      'Yüklenemedi — yeniden denemek için dokun';

  @override
  String get attachmentNotSynced =>
      'Este ficheiro ainda não foi sincronizado neste dispositivo';

  @override
  String attachmentTooLarge(int limit) {
    return 'Ficheiro demasiado grande (máximo $limit MB)';
  }

  @override
  String storageFull(String limit) {
    return 'Armazenamento cheio ($limit). Exclua anexos antigos para liberar espaço.';
  }

  @override
  String get storageUsage => 'Armazenamento';

  @override
  String storageUsageValue(String used, String limit) {
    return '$used de $limit usados';
  }

  @override
  String get removeAttachment => 'Remover anexo';

  @override
  String get pin => 'Fixar';

  @override
  String get unpin => 'Desafixar';

  @override
  String get delete => 'Eliminar';

  @override
  String get color => 'Cor';

  @override
  String get aiTitle => 'IA';

  @override
  String get aiSummarize => 'Resumir a nota';

  @override
  String get aiAnalyze => 'Analisar';

  @override
  String get aiSectionNote => 'Esta nota';

  @override
  String get aiSectionAttachments => 'Anexos';

  @override
  String get summarize => 'Resumir';

  @override
  String get summaryDetailTitle => 'Tipo de resumo';

  @override
  String get summaryShort => 'Resumo curto';

  @override
  String get summaryShortInfo =>
      'Algumas frases de síntese mais os pontos principais';

  @override
  String get summaryDetailed => 'Resumo detalhado';

  @override
  String get summaryDetailedInfo =>
      'Suficientemente completo para não ter de abrir o original';

  @override
  String get listen => 'Ouvir';

  @override
  String get ask => 'Fazer uma pergunta';

  @override
  String get extractText => 'Extrair o texto';

  @override
  String get transcribe => 'Transcrever';

  @override
  String get listenToNote => 'Ler em voz alta';

  @override
  String get aiNoApiKey =>
      'Introduza primeiro a sua chave da API Gemini nas definições';

  @override
  String aiError(String error) {
    return 'O pedido à IA falhou: $error';
  }

  @override
  String get aiSummaryTitle => 'Resumo da IA';

  @override
  String get aiThinking => 'A pensar...';

  @override
  String get copy => 'Copiar';

  @override
  String get copied => 'Copiado';

  @override
  String get settingsSearchHint =>
      'Pesquisar definições — “resumo”, “microfone”';

  @override
  String settingsSearchEmpty(String query) {
    return 'Nenhuma definição corresponde a «$query»';
  }

  @override
  String get settings => 'Definições';

  @override
  String get settingsAppearance => 'Aspeto';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Escuro';

  @override
  String get settingsAi => 'IA';

  @override
  String get geminiApiKey => 'Chave da API Gemini';

  @override
  String get geminiApiKeyHint => 'Cole a chave que começa por AIza...';

  @override
  String get geminiApiKeyInfo =>
      'A chave é opcional: sem ela, os pedidos à IA passam pelo serviço integrado da aplicação (um limite diário gratuito, maior com o Premium). Para utilização ilimitada com a sua própria chave, obtenha uma gratuitamente em aistudio.google.com; a chave fica guardada apenas neste dispositivo, num armazenamento seguro.';

  @override
  String aiBuiltInPremium(int count) {
    return 'IA integrada: Premium — $count pontos restantes hoje';
  }

  @override
  String aiBuiltInRemaining(int count) {
    return 'IA integrada: $count pontos gratuitos restantes hoje';
  }

  @override
  String get aiBuiltInByok => 'Com a sua própria chave — ilimitado';

  @override
  String get aiReport => 'Comunicar esta resposta';

  @override
  String get aiReportThanks => 'Comunicação recebida, obrigado';

  @override
  String get privacyPolicyTitle => 'Política de privacidade';

  @override
  String get lockNote => 'Bloquear';

  @override
  String get unlockNote => 'Desbloquear';

  @override
  String get lockedNote => 'Nota bloqueada';

  @override
  String get unlockAuthReason =>
      'Confirme a sua identidade para abrir a nota bloqueada';

  @override
  String get exportBackup => 'Exportar cópia de segurança (JSON)';

  @override
  String get expandListItems => 'Mostrar as linhas por inteiro';

  @override
  String get expandListItemsInfo =>
      'Os itens longos passam para várias linhas e ficam totalmente visíveis. Se estiver desativado, a linha fica numa só e expande-se ao ser tocada.';

  @override
  String get quickCaptureRowSetting => 'Barra de nota rápida';

  @override
  String get quickCaptureRowInfo =>
      'Mostra um campo \"Nova nota...\" no topo. Quando desligado, use o botão +.';

  @override
  String get emptyTrash => 'Esvaziar o lixo';

  @override
  String emptyTrashConfirm(int count) {
    return '$count notas serão eliminadas permanentemente. Esta ação não pode ser anulada. Tem a certeza?';
  }

  @override
  String get trashEmptied => 'Lixo esvaziado';

  @override
  String get validateAndSave => 'Verificar e guardar';

  @override
  String get clear => 'Limpar';

  @override
  String get aiDiagnostics => 'Diagnóstico da IA';

  @override
  String get aiDiagnosticsEmpty => 'Não há erros registados';

  @override
  String aiDiagnosticsCount(int count) {
    return 'Últimos $count registos de erro';
  }

  @override
  String get apiKeyValid => 'Chave da API verificada e guardada';

  @override
  String get apiKeyInvalid => 'A chave da API não é válida';

  @override
  String get apiKeySavedBadge => 'Guardada';

  @override
  String get removeApiKey => 'Eliminar chave';

  @override
  String get refresh => 'Atualizar';

  @override
  String get account => 'Conta';

  @override
  String get signOut => 'Terminar sessão';

  @override
  String get signOutConfirm => 'Tem a certeza de que quer terminar sessão?';

  @override
  String get signOutAnonymousWarning =>
      'Você está numa conta local: ao sair, esta conta e TODAS as notas ficarão inacessíveis para sempre — sem backup não podem ser recuperadas. Vincule antes uma conta Google. Sair mesmo assim?';

  @override
  String get deleteAccount => 'Eliminar a minha conta e os meus dados';

  @override
  String get deleteAccountWarning =>
      'Esta ação não pode ser anulada: todas as suas notas, anexos e a sua conta serão eliminados permanentemente. Quer continuar?';

  @override
  String get deleteAccountConfirm => 'Eliminar permanentemente';

  @override
  String get licensesTitle => 'Licenças de código aberto';

  @override
  String get generating => 'A gerar...';

  @override
  String get retry => 'Tentar novamente';

  @override
  String get cancel => 'Cancelar';

  @override
  String get close => 'Fechar';

  @override
  String get ok => 'OK';

  @override
  String get syncPending => 'A aguardar sincronização';

  @override
  String get synced => 'Sincronizada';

  @override
  String genericError(String error) {
    return 'Algo correu mal: $error';
  }

  @override
  String get addTag => 'Etiqueta';

  @override
  String get tagHint => 'ex.: trabalho, casa, escola';

  @override
  String get addReminder => 'Lembrar-me';

  @override
  String get placeReminder => 'Konum hatırlatıcısı';

  @override
  String get placeReminderHint =>
      'Bir yere varınca ya da oradan ayrılınca bu not bildirim olarak gelsin. Konumu sistem izler; uygulama açık olmasa da çalışır.';

  @override
  String get placeCurrent => 'Şu anki konumum';

  @override
  String get placeSearchHint => 'Adres ya da yer ara';

  @override
  String get placeSearchNone => 'Sonuç bulunamadı';

  @override
  String get placeArrive => 'Varınca';

  @override
  String get placeLeave => 'Ayrılınca';

  @override
  String get placeRadius => 'Yarıçap';

  @override
  String get placeSave => 'Hatırlatıcıyı kur';

  @override
  String get placeRemove => 'Konum hatırlatıcısını kaldır';

  @override
  String get placeSet => 'Konum hatırlatıcısı kuruldu';

  @override
  String get placeRemoved => 'Konum hatırlatıcısı kaldırıldı';

  @override
  String get placeNeedPermission =>
      'Konum izni verilmedi. Ayarlardan izin verebilirsin.';

  @override
  String get placeNeedBackground =>
      'Uygulama kapalıyken de çalışması için konum iznini \"Her zaman izin ver\" yapman gerekiyor.';

  @override
  String get placeBackgroundTitle => '\"Her zaman\" izni gerekli';

  @override
  String get placeOpenSettings => 'İzin ver';

  @override
  String get placeLocationOff =>
      'Cihazın konum hizmeti kapalı. Açıp yeniden dene.';

  @override
  String get placeFailed => 'Konum hatırlatıcısı kurulamadı.';

  @override
  String get placeNoLocation =>
      'Konum alınamadı. Konumun açık olduğundan emin ol.';

  @override
  String placeArrivedBody(String place) {
    return '$place konumuna vardın';
  }

  @override
  String placeLeftBody(String place) {
    return '$place konumundan ayrıldın';
  }

  @override
  String placeActive(String place, String trigger) {
    return '$place · $trigger';
  }

  @override
  String get placeSection => 'Konum';

  @override
  String get share => 'Partilhar';

  @override
  String get archive => 'Arquivar';

  @override
  String get unarchive => 'Desarquivar';

  @override
  String get archiveTitle => 'Arquivo';

  @override
  String get archiveEmpty => 'Não há notas no arquivo';

  @override
  String get trashTitle => 'Lixo';

  @override
  String get trashEmpty => 'O lixo está vazio';

  @override
  String get trashInfo =>
      'As notas eliminadas ficam aqui; pode restaurá-las ou eliminá-las definitivamente.';

  @override
  String get restore => 'Restaurar';

  @override
  String get deleteForever => 'Eliminar permanentemente';

  @override
  String get deleteForeverConfirm =>
      'Esta nota será eliminada permanentemente. Tem a certeza?';

  @override
  String assistantDeleteConfirm(String title) {
    return 'Asistan \"$title\" notunu çöp kutusuna taşımak istiyor. Onaylıyor musun?';
  }

  @override
  String get recordAudio => 'Gravação de voz';

  @override
  String get recording => 'A gravar...';

  @override
  String get stopAndSave => 'Terminar e adicionar';

  @override
  String get micPermissionDenied => 'A permissão do microfone foi recusada';

  @override
  String get speechRecognitionFailed =>
      'O reconhecimento de voz não funcionou. Verifique se a permissão do microfone está concedida e se a aplicação Google está atualizada.';

  @override
  String get addDrawing => 'Adicionar desenho';

  @override
  String get drawingTitle => 'Desenho';

  @override
  String get addToNote => 'Adicionar à nota';

  @override
  String get chatTitle => 'Assistente de notas';

  @override
  String get chatHint =>
      'Pergunte sobre as suas notas: «qual era aquela receita que escrevi a semana passada?», «o que falta na minha lista de compras?»';

  @override
  String get chatInputHint => 'Escreva uma pergunta...';

  @override
  String get fontSize => 'Tamanho do texto';

  @override
  String get fontSizePreview => 'As suas notas ficarão assim';

  @override
  String get darkSchedule => 'Agendamento do tema escuro';

  @override
  String get darkScheduleInfo =>
      'Muda para o tema escuro entre as horas que definir';

  @override
  String get aiTranslate => 'Traduzir';

  @override
  String get voiceCommand => 'Comando de voz';

  @override
  String get semanticSearchToggle => 'Pesquisa semântica com IA';

  @override
  String get semanticSearchHint =>
      'Pesquise por significado: «despesas do carro»...';

  @override
  String get briefingTitle => 'Resumo do dia';

  @override
  String get briefingLoading => 'A preparar o seu resumo...';

  @override
  String get briefingEmpty => 'Nada para hoje';

  @override
  String get briefingSetting => 'Notificação do resumo diário';

  @override
  String get briefingSettingInfo =>
      'Receba todas as manhãs uma notificação com o resumo do dia, à hora que escolher';

  @override
  String get autoTagSetting => 'Etiquetar automaticamente';

  @override
  String get autoTagSettingInfo =>
      'Quando uma nota é fechada sem etiquetas, a IA acrescenta uma adequada';

  @override
  String get suggestTags => 'Sugerir etiquetas';

  @override
  String get aiFixNote => 'Corrigir a nota';

  @override
  String get fixLevelTitle => 'Até que ponto corrigir?';

  @override
  String get fixSimple => 'Ligeiro';

  @override
  String get fixSimpleInfo => 'Apenas ortografia e gralhas';

  @override
  String get fixBalanced => 'Equilibrado';

  @override
  String get fixBalancedInfo =>
      'Também a estrutura das frases, para uma escrita mais limpa';

  @override
  String get fixDetailed => 'Aprofundado';

  @override
  String get fixDetailedInfo => 'Reescreve o texto todo de uma ponta à outra';

  @override
  String get existingTagsLabel => 'Etiquetas anteriores';

  @override
  String get aiSkipCheckedSetting =>
      'Deixar os itens assinalados de fora das edições da IA';

  @override
  String get aiSkipCheckedInfo =>
      'Quando a IA corrige ou traduz uma lista, os itens concluídos (assinalados) ficam exatamente como estão; só os não assinalados são editados.';

  @override
  String get noteUpdatedUndo => 'Nota atualizada';

  @override
  String get aiImprove => 'Melhorar a nota';

  @override
  String get improveFormal => 'Tornar mais formal';

  @override
  String get improveShorten => 'Encurtar';

  @override
  String get improveBullets => 'Transformar em lista de tópicos';

  @override
  String get improveNumbered => 'Transformar em lista numerada';

  @override
  String get replaceNote => 'Substituir a nota';

  @override
  String get openAsNewNote => 'Como nova nota';

  @override
  String get pdfChatHint =>
      'Pergunte sobre este PDF: «resume-o», «há alguma cláusula penal?», «qual é o prazo?»';

  @override
  String get pdfChatInputHint => 'Escreva uma pergunta sobre o PDF...';

  @override
  String get voiceCaptureHint =>
      'Fale: «comprar leite e pão» ou «reunião amanhã às 9, lembra-me» — a IA escreve a sua nota quando terminar.';

  @override
  String get voiceFinish => 'Terminar';

  @override
  String get voiceProcessing => 'A processar o que disse...';

  @override
  String get voiceNothingHeard => 'Não foi detetada fala na gravação';

  @override
  String get voiceNoteSaved => 'A sua nota de voz foi guardada';

  @override
  String get openNote => 'Abrir nota';

  @override
  String get remindersTitle => 'Lembretes';

  @override
  String get remindersEmpty => 'Não há lembretes';

  @override
  String get remindersEmptyHint =>
      'Adicione um lembrete a uma nota, ou crie uma nova nota com lembrete através do botão +';

  @override
  String get remindersUpcoming => 'A seguir';

  @override
  String get remindersPast => 'Passados';

  @override
  String get reminderInPast =>
      'O horário selecionado já passou — escolha um horário futuro.';

  @override
  String get newReminder => 'Novo lembrete';

  @override
  String get remindersUntitled => 'Nota sem título';

  @override
  String get remindersEdit => 'Alterar a hora';

  @override
  String get remindersRemove => 'Remover lembrete';

  @override
  String get aiModelChat => 'Resumos, títulos, etiquetas e conversa';

  @override
  String get aiModelDocument => 'Chat de documentos e resumo de PDF';

  @override
  String get aiModelTranslate => 'Tradução';

  @override
  String get aiModelVoice => 'Assistente de nota de voz';

  @override
  String get aiModelAuto => 'Automático (recomendado)';

  @override
  String get aiModelsInfo =>
      'Pode escolher um modelo diferente para cada tarefa: textos curtos ficam bem num modelo rápido, documentos longos pedem um modelo mais capaz. Se o modelo escolhido atingir o limite ou for retirado, o seguinte é tentado automaticamente.';

  @override
  String get clearNote => 'Limpar';

  @override
  String get clearNoteConfirm =>
      'O conteúdo da nota (texto e itens da lista) será eliminado. Tem a certeza?';

  @override
  String get themePaper => 'Papel';

  @override
  String get calculatorTitle => 'Calculadora';

  @override
  String get calcExpressionHint => 'ex.: 12,5×3+40';

  @override
  String get calcInvalid => 'Expressão inválida';

  @override
  String get liveDictation => 'Ditar';

  @override
  String get voiceCaptureAi => 'Sesli yakala (yapay zekâ)';

  @override
  String get dictationListening =>
      'A ouvir... o texto aparece à medida que fala';

  @override
  String get dictationNoKeyInfo =>
      'O ditado em direto não está disponível neste dispositivo; a gravação será transcrita de uma só vez quando parar.';

  @override
  String get dictationHoldHint =>
      'Mantenha o microfone premido e fale; o texto é escrito quando soltar';

  @override
  String itemsSelected(int count) {
    return '$count itens selecionados';
  }

  @override
  String get noteChatTitle => 'Conversar com esta nota';

  @override
  String get noteChatHint => 'Pergunte algo sobre esta nota';

  @override
  String get noteChatIntro =>
      'O conteúdo da nota e os seus anexos (PDF/imagem) são lidos, e a sua pergunta é respondida a partir deles.';

  @override
  String get dictationProcessing => 'A transcrever...';

  @override
  String get aiDailyManualInfo =>
      'No plano gratuito isto não é gerado automaticamente, por isso não consome o seu limite diário. Pode gerá-lo uma vez por dia com o botão abaixo.';

  @override
  String get aiGenerate => 'Gerar';

  @override
  String get aiGeneratedTodayInfo =>
      'Isto foi gerado hoje. No plano gratuito renova-se uma vez por dia; pode gerá-lo novamente amanhã.';

  @override
  String get voiceAssistantTitle => 'Assistente de notas de voz';

  @override
  String get voiceListening => 'A ouvir...';

  @override
  String get voiceHoldHint =>
      'Mantenha premido e fale; a nota é criada quando soltar';

  @override
  String get voiceTapHint => 'Toque e fale; toque novamente para terminar';

  @override
  String get voiceTooShort =>
      'Essa gravação foi demasiado curta, tente novamente';

  @override
  String get voiceModeSetting => 'Como funciona';

  @override
  String get voiceModeHold => 'Manter premido para falar';

  @override
  String get voiceModeTap => 'Tocar para começar / tocar para parar';

  @override
  String get voiceModeInfo =>
      'Manter premido para falar: ouve enquanto mantém o botão premido e cria a nota quando solta. Tocar para começar: um toque inicia a gravação, um segundo toque termina-a.';

  @override
  String get voiceHeardLive => 'Fala detetada';

  @override
  String get voiceCaptureReady => 'Speech ready';

  @override
  String get voiceCaptureEditHint => 'Tap the text to edit';

  @override
  String voiceCapturePunctuation(String language) {
    return '$language · automatic punctuation';
  }

  @override
  String get voiceCaptureAddToNote => 'Add to note';

  @override
  String get voiceCaptureCreateNote => 'Create new note';

  @override
  String get voiceCaptureAiNote => 'Nota IA';

  @override
  String get voiceCapturePlainNote => 'Nota simples';

  @override
  String get voiceCloseTitle => 'O seu ditado continua aqui';

  @override
  String get voiceCloseKeepTalking => 'Continuar a falar';

  @override
  String get voiceCaptureRestart => 'Record again';

  @override
  String get voiceChipSummarizeAdd => 'Add as summary';

  @override
  String get voiceChipSummarizeSave => 'Save as summary';

  @override
  String get voiceChipToItems => 'Split into items';

  @override
  String get voiceChipAsList => 'Make a checklist';

  @override
  String get voiceChipFix => 'Clean up';

  @override
  String get voiceChipCompose => 'Deixar o assistente escrever';

  @override
  String get editorToolList => 'List';

  @override
  String get permissionsTitle => 'Permissões';

  @override
  String get permMic => 'Microfone';

  @override
  String get permMicInfo => 'Necessário para notas de voz e ditado';

  @override
  String get permNotifications => 'Notificações';

  @override
  String get permNotificationsInfo =>
      'Necessárias para os lembretes e o resumo diário';

  @override
  String get permBattery => 'Otimização da bateria';

  @override
  String get permBatteryInfo =>
      'Isente a aplicação das restrições de bateria para que os lembretes cheguem a horas';

  @override
  String get showTagChips => 'Mostrar os chips de etiqueta';

  @override
  String get showFolderChips => 'Mostrar os chips de pasta';

  @override
  String videoTooBigForAi(int mb) {
    return 'O vídeo é demasiado grande para ser enviado à IA ($mb MB). Grave um mais curto.';
  }

  @override
  String get permCamera => 'Câmara';

  @override
  String get permCameraInfo =>
      'Necessária para notas de vídeo e para tirar fotografias';

  @override
  String get permOnboardTitle => 'Antes de começar';

  @override
  String get permOnboardInfo =>
      'A aplicação Notas só pede estas permissões quando utiliza a funcionalidade correspondente. Pode concedê-las agora abaixo, ou alterá-las mais tarde em Definições > Permissões.';

  @override
  String get permOnboardGrantAll => 'Conceder permissões';

  @override
  String get permOnboardSkip => 'Agora não';

  @override
  String get newVideoNote => 'Nota de vídeo';

  @override
  String get videoLocalOnly =>
      'Este vídeo está guardado apenas neste dispositivo (não é carregado para a nuvem)';

  @override
  String get videoToNote => 'Criar uma nota a partir do vídeo';

  @override
  String get videoToNoteRunning => 'A analisar o vídeo…';

  @override
  String get permGranted => 'Concedida';

  @override
  String get permGrant => 'Conceder';

  @override
  String get permOpenSettings => 'Abrir as definições';

  @override
  String get newHandwriting => 'Escrita manual';

  @override
  String get newVoiceCapture => 'Nota de voz';

  @override
  String get suggestTitle => 'Sugerir um título';

  @override
  String get noteMetaMenu => 'Etiqueta · Título · Lembrete';

  @override
  String get folder => 'Pasta';

  @override
  String get noFolder => 'Sem pasta';

  @override
  String get newFolder => 'Nova pasta';

  @override
  String get editFolder => 'Editar pasta';

  @override
  String get deleteFolder => 'Eliminar pasta';

  @override
  String deleteFolderConfirm(String name) {
    return 'A pasta «$name» será eliminada. As notas que estão lá dentro não são eliminadas — apenas deixam de ter pasta.';
  }

  @override
  String get folderNameHint => 'Nome da pasta';

  @override
  String get folderIcon => 'Ícone';

  @override
  String get editFilters => 'Editar os filtros';

  @override
  String get editFiltersInfo =>
      'Escolha que filtros aparecem no ecrã principal. Esconder alguns mantém a página arrumada.';

  @override
  String get select => 'Selecionar';

  @override
  String get noteArchived => 'Nota arquivada';

  @override
  String pendingUploads(int count) {
    return '$count ek buluta yükleniyor';
  }

  @override
  String pendingUploadsFailed(int count) {
    return '$count ek yüklenemedi, yeniden denenecek';
  }

  @override
  String get pendingUploadsInfo =>
      'Ekler bu cihazda güvende. Bağlantı olduğunda kendiliğinden yüklenir; o zamana kadar öbür cihazlarınızda görünmez.';

  @override
  String deleteChecked(int count) {
    return 'Eliminar os assinalados ($count)';
  }

  @override
  String get removeItem => 'Eliminar item';

  @override
  String get copyWholeNote => 'Copiar a nota inteira';

  @override
  String get allCopied =>
      'A nota inteira foi copiada para a área de transferência';

  @override
  String get speechPlay => 'Ler em voz alta';

  @override
  String get speechPause => 'Pausa';

  @override
  String get speechResume => 'Retomar';

  @override
  String get speechStop => 'Parar';

  @override
  String get speechRate => 'Velocidade de leitura';

  @override
  String get speechSystemDefault => 'Predefinição do sistema';

  @override
  String get speechNoVoices => 'Não há vozes instaladas neste dispositivo';

  @override
  String speechVoiceLanguage(String language) {
    return 'Voz $language';
  }

  @override
  String get speechVoiceAutoInfo =>
      'As outras línguas são lidas automaticamente com uma voz masculina';

  @override
  String get listening => 'A ouvir...';

  @override
  String get listenPlay => 'Ouvir';

  @override
  String get listenReadingPdf => 'A ler o documento...';

  @override
  String get listenConvertWithAi => 'Converter com IA';

  @override
  String get listenMakePodcast => 'Podcast completo';

  @override
  String get listenMakePodcastSummary => 'Podcast de resumo';

  @override
  String get listenOriginalText => 'Texto original';

  @override
  String get listenPodcastReady => 'A narração do podcast está pronta';

  @override
  String get listenPodcastCached =>
      'Gerado anteriormente — sem gasto de tokens';

  @override
  String get listenRegenerate => 'Gerar novamente';

  @override
  String get listenNoText =>
      'Não saiu texto legível deste documento. Um PDF digitalizado não tem camada de texto, e uma apresentação pode conter apenas imagens.';

  @override
  String get readDocument => 'Ler um documento (Word, PDF, diapositivos)';

  @override
  String get readDocUnsupported => 'Este tipo de ficheiro não pode ser lido.';

  @override
  String get exportPdf => 'Exportar como PDF';

  @override
  String get pdfTitleField => 'Título';

  @override
  String get pdfContentField => 'Conteúdo';

  @override
  String get pdfMarkupHint =>
      'As marcas no início da linha tornam-se formatação: [x] e [ ] para caixas de seleção, 1. para uma lista numerada, - para um tópico.';

  @override
  String get pdfIncludeDate => 'Incluir a data';

  @override
  String get exportIncludeImages => 'Incluir as imagens';

  @override
  String get exportWord => 'Partilhar como Word (.docx)';

  @override
  String get pdfPreview => 'Pré-visualização';

  @override
  String get largeAttachmentTitle => 'Ficheiro grande';

  @override
  String largeAttachmentBody(String size) {
    return 'Este ficheiro tem $size MB. Os PDF não podem ser comprimidos; será carregado tal como está e contará para o seu armazenamento. Continuar?';
  }

  @override
  String get speechRateForeign => 'Velocidade em língua estrangeira';

  @override
  String notesArchivedCount(int count) {
    return '$count notas arquivadas';
  }

  @override
  String get backgroundColor => 'Cor de fundo';

  @override
  String get backgroundColorInfo => 'A cor de fundo da nota';

  @override
  String get frameColor => 'Moldura';

  @override
  String get frameColorInfo =>
      'Desenha uma moldura à volta da nota na cor que escolher';

  @override
  String get sortBy => 'Ordenar';

  @override
  String get reorderNotes => 'Reordenar as notas';

  @override
  String get reorderModeActive => 'Arraste os cartões para os reordenar';

  @override
  String get reorderDone => 'Concluído';

  @override
  String get sortManual => 'Manual (ordem arrastada)';

  @override
  String get sortUpdated => 'Atualizadas recentemente';

  @override
  String get sortCreated => 'Data de criação';

  @override
  String get sortTitle => 'Por título (A–Z)';

  @override
  String get foldersSection => 'Pastas';

  @override
  String get tagsSection => 'Etiquetas';

  @override
  String get expandFilters => 'Expandir os filtros';

  @override
  String get collapseFilters => 'Recolher os filtros';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get languageSystem => 'Idioma do sistema';

  @override
  String get settingsSpeech => 'Leitura em voz alta';

  @override
  String get aiAdvanced => 'Avançado: modelo e chave da API';

  @override
  String get aiAdvancedInfo =>
      'Escolha do modelo e a sua própria chave Gemini. A maioria das pessoas não precisa disto.';

  @override
  String get openBriefing => 'Abrir o resumo';

  @override
  String get syncTitle => 'Sincronização';

  @override
  String get syncLimitTitle => 'Limite de carregamento automático';

  @override
  String get syncLimitInfo =>
      'Os anexos maiores do que isto ficam no dispositivo e não são carregados. O texto das notas é sempre sincronizado.';

  @override
  String get syncLimitUnlimited => 'Sem limite';

  @override
  String get backupTitle => 'Cópia de segurança';

  @override
  String get importBackup => 'Restaurar a partir de cópia de segurança (JSON)';

  @override
  String importBackupDone(int count) {
    return '$count notas restauradas';
  }

  @override
  String get importBackupInvalid => 'Ficheiro de cópia de segurança inválido';

  @override
  String get aiHubTitle => 'IA';

  @override
  String get aiSummarizeInfo => 'Produz um resumo curto';

  @override
  String get aiAnalyzeInfo => 'Lista os pontos principais e as tarefas';

  @override
  String get aiImproveInfo => 'Muda o tom: formal, mais curto ou lista';

  @override
  String get aiTranslateInfo => 'Traduz a nota para o idioma escolhido';

  @override
  String get aiFixNoteInfo => 'Corrige ortografia e pontuação';

  @override
  String get moveToFolder => 'Mover para uma pasta';

  @override
  String get voiceAssistantBadge => 'Assistente';

  @override
  String get assistantGenericError =>
      'Algo correu mal — pode tentar novamente?';

  @override
  String get quickAddTooltip => 'Nova nota — escolha um tipo';

  @override
  String get autoTitleSetting => 'Sugerir um título ao fechar';

  @override
  String get autoTitleSettingInfo =>
      'Quando sai do editor, uma nota deixada sem título recebe um título curto, escrito a partir do seu conteúdo.';

  @override
  String get hubChatInfo => 'Respostas tiradas das suas notas';

  @override
  String get hubBriefingInfo =>
      'O seu dia num relance: lembretes e notas recentes';

  @override
  String get hubReadInfo => 'Ouça um documento PDF ou Word';

  @override
  String get annotate => 'Anotar';

  @override
  String get annotateDone => 'Terminar a anotação';

  @override
  String get newPdfNote => 'PDF ekle not al';

  @override
  String get imageNotePreparing => 'Organizando as imagens em um documento…';

  @override
  String get newImageNote => 'Adicionar imagem e anotar';

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
  String get pdfAddBlankPage => 'Adicionar página em branco';

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
  String get cropApply => 'Aplicar o recorte';

  @override
  String get cropReset => 'Repor a seleção';

  @override
  String get cropHint =>
      'Arraste os cantos para escolher uma área. O recorte não pode ser anulado.';

  @override
  String get cropFailed => 'Não foi possível recortar a imagem.';

  @override
  String get penBallpoint => 'Esferográfica';

  @override
  String get penMarker => 'Marcador';

  @override
  String get penHighlighter => 'Marcador fluorescente';

  @override
  String get eraser => 'Borracha';

  @override
  String get inkArrow => 'Seta';

  @override
  String get clearInk => 'Limpar as anotações';

  @override
  String get inkTwoFingerHint =>
      'Um dedo desenha · dois dedos deslocam e ampliam';

  @override
  String get slideOpenFailed => 'Não foi possível abrir a apresentação';

  @override
  String get newPhotoNote => 'Nota de fotografia';

  @override
  String get newScanNote => 'Digitalizar um documento';

  @override
  String get scanDocument => 'Digitalizar documento';

  @override
  String get scanDocumentSubtitle =>
      'Encontra os limites, endireita a página e adiciona-a';

  @override
  String get scanUnsupported =>
      'A digitalização de documentos não é suportada neste dispositivo';

  @override
  String scanFailed(String error) {
    return 'Não foi possível digitalizar o documento: $error';
  }

  @override
  String scanPagesAdded(int count) {
    return '$count página(s) adicionada(s) à nota';
  }

  @override
  String get scanTextTitle => 'Reconhecer também o texto?';

  @override
  String get scanTextBody =>
      'O texto das páginas é reconhecido e escrito na nota. A imagem fica como está. Demora alguns segundos por página.';

  @override
  String get scanImageOnly => 'Apenas imagem';

  @override
  String get scanRecognizeText => 'Reconhecer o texto';

  @override
  String get scanRecognizing => 'A reconhecer o texto…';

  @override
  String get takePhoto => 'Tirar uma fotografia';

  @override
  String get qrScanTitle => 'Ler um código QR';

  @override
  String get qrScanSubtitle =>
      'Leia-o com a câmara ou a partir de uma fotografia';

  @override
  String get qrScanHint => 'Alinhe o código dentro da moldura';

  @override
  String get qrFromPhoto => 'Ler a partir de uma fotografia';

  @override
  String get qrNotFound => 'Não foi encontrado nenhum código nesta imagem';

  @override
  String get qrLinkFound => 'Este código é uma ligação';

  @override
  String get qrOpenLink => 'Ir para a ligação';

  @override
  String get qrSaveToNote => 'Guardar numa nota';

  @override
  String get openLink => 'Abrir ligação';

  @override
  String get linkOpenFailed => 'Não foi possível abrir a ligação';

  @override
  String qrScanFailed(String error) {
    return 'Não foi possível ler o código: $error';
  }

  @override
  String get qrTorch => 'Lanterna';

  @override
  String attachmentsCount(int count) {
    return 'Anexos ($count)';
  }

  @override
  String get hideAttachments => 'Ocultar';

  @override
  String get showAttachments => 'Mostrar';

  @override
  String get videoBack10 => 'Recuar 10 s';

  @override
  String get videoForward10 => 'Avançar 10 s';

  @override
  String get selectAllItems => 'Selecionar tudo';

  @override
  String get showAllChips => 'Mostrar tudo';

  @override
  String get hideAllChips => 'Ocultar tudo';

  @override
  String get chipPickInfo =>
      'Que chips de pasta e de etiqueta devem aparecer no ecrã principal?';

  @override
  String get hiddenFolder => 'Pasta oculta';

  @override
  String get hiddenFolderInfo =>
      'Uma pasta oculta e as notas que contém não aparecem no ecrã principal. Para as mostrar, escolha «Pastas ocultas» no menu ⋮ e confirme a sua identidade.';

  @override
  String get hiddenFoldersMenu => 'Pastas ocultas';

  @override
  String get hiddenFolderAuthReason =>
      'Confirme a sua identidade para mostrar as pastas ocultas';

  @override
  String get hiddenFoldersShown => 'As pastas ocultas estão visíveis';

  @override
  String get hiddenFoldersHiddenAgain =>
      'As pastas ocultas voltaram a ficar escondidas';

  @override
  String get makeFolderHidden => 'Ocultar';

  @override
  String get makeFolderVisible => 'Mostrar';

  @override
  String gridColumnsCount(int count) {
    return '$count colunas';
  }

  @override
  String get addImageOnPageSubtitle =>
      'Fica na página, o texto flui à volta dela';

  @override
  String get addImageAsFile => 'Adicionar a imagem como ficheiro';

  @override
  String get addImageAsFileSubtitle =>
      'Fica fora da página, na faixa de anexos';

  @override
  String get moveImageToAttachments => 'Mover para os anexos';

  @override
  String get moveImageToPage => 'Colocar na página';

  @override
  String get attachmentCopied => 'Anexo copiado';

  @override
  String get pasteAttachment => 'Colar o anexo copiado';

  @override
  String get fullscreen => 'Ecrã inteiro';

  @override
  String get more => 'Mais';

  @override
  String get undone => 'Anulado';

  @override
  String get filterOthers => 'Outras';

  @override
  String get chatSuggestion1 => 'O que falta na minha lista de compras?';

  @override
  String get chatSuggestion2 => 'Resumir as notas de trabalho desta semana';

  @override
  String get chatSuggestion3 => 'Tenho algum lembrete para amanhã?';

  @override
  String get aiPointsToday => 'Pontos de hoje';

  @override
  String aiPointsOf(int used, int total) {
    return '$used / $total';
  }

  @override
  String get aiPointsRenew => 'renova à meia-noite';

  @override
  String get aiChatWithNotes => 'Assistente de notas';

  @override
  String get aiChatInputHint => 'Pergunte algo sobre as suas notas…';

  @override
  String get aiChatLooking => 'a pesquisar nas suas notas…';

  @override
  String get aiChatFullScreen => 'Ecrã completo';

  @override
  String get aiOnYourNotes => 'NAS SUAS NOTAS';

  @override
  String get aiTaskDuplicates => 'Limpar duplicados';

  @override
  String aiTaskDuplicatesInfo(int count) {
    return '$count notas duplicadas';
  }

  @override
  String get duplicatesTitle => 'Notas duplicadas';

  @override
  String get duplicatesHint =>
      'A nota mais antiga de cada grupo é mantida, as restantes vão para o lixo.';

  @override
  String get duplicatesKeepBadge => 'mantida';

  @override
  String get duplicatesDeleteAll => 'Mover duplicados para o lixo';

  @override
  String duplicatesDone(int count) {
    return '$count duplicados movidos para o lixo';
  }

  @override
  String get aiRecentActions => 'AÇÕES RECENTES';

  @override
  String get aiHistoryClear => 'Limpar';

  @override
  String get aiHistoryQuestion => 'Pergunta';

  @override
  String get aiHistoryNoteAction => 'Ação na nota';

  @override
  String get aiHistoryVoiceNote => 'Nota de voz';

  @override
  String get aiRecentOps => 'RECENTE';

  @override
  String get aiTaskWeekSummary => 'Resumir a semana';

  @override
  String get aiTaskWeekSummaryInfo => 'Um resumo dos últimos 7 dias';

  @override
  String get aiTaskTagUntagged => 'Etiquetar as sem etiqueta';

  @override
  String aiTaskTagUntaggedInfo(int count) {
    return '$count notas à espera de etiquetas';
  }

  @override
  String get aiTaskSuggestTitles => 'Sugerir títulos';

  @override
  String aiTaskSuggestTitlesInfo(int count) {
    return '$count notas sem título';
  }

  @override
  String get sectionPinnedShort => 'FIXADO';

  @override
  String get sectionToday => 'HOJE';

  @override
  String get sectionThisWeek => 'ESTA SEMANA';

  @override
  String get sectionEarlier => 'ANTERIOR';

  @override
  String sectionNoteCount(int count) {
    return '$count notas';
  }

  @override
  String get emptySearchSemanticHint => 'Tente o separador Significado';

  @override
  String get quickCaptureHint => 'Nova nota…';

  @override
  String get quickCaptureSave => 'Guardar';

  @override
  String get quickAddWrite => 'ESCREVER';

  @override
  String get quickAddCapture => 'CAPTURAR — CRIA UMA NOTA A PARTIR DO CONTEÚDO';

  @override
  String get viewToggle => 'Visualizar';

  @override
  String get searchModeText => 'Texto';

  @override
  String get searchModeMeaning => 'Significado';

  @override
  String get filterReminded => 'Com lembrete';

  @override
  String get filterLocked => 'Bloqueado';

  @override
  String get sortColor => 'Cor';

  @override
  String get sortActive => 'Mais trabalhadas';

  @override
  String get voicePreview => 'Testar a voz';

  @override
  String get voicePreviewCached =>
      'A amostra é gerada uma vez e depois reproduzida do armazenamento';

  @override
  String get reorderHint =>
      'Toque e segure um cartão e arraste para onde quiser';

  @override
  String get filterSheetTitle => 'Filtrar';

  @override
  String get filterReset => 'Repor';

  @override
  String get filterSectionStatus => 'ESTADO';

  @override
  String get filterSectionFolder => 'PASTA';

  @override
  String get filterSectionTag => 'ETIQUETA';

  @override
  String get filterSectionSort => 'ORDENAR';

  @override
  String get filterFavoriteHint =>
      'Toca numa estrela para manter essa opção no ecrã principal';

  @override
  String get filterSheetSortHint =>
      'Os grupos de data (HOJE, ESTA SEMANA…) só são apresentados ao ordenar por última edição.';

  @override
  String get formatTitle => 'Formatação';

  @override
  String get formatBold => 'Negrito';

  @override
  String get formatItalic => 'Itálico';

  @override
  String get formatUnderline => 'Sublinhado';

  @override
  String get formatTextColor => 'Cor do texto';

  @override
  String get formatHighlight => 'Realce';

  @override
  String get formatInfo =>
      'A formatação viaja dentro do texto como marcas (por exemplo **negrito**); as marcas ficam ocultas nas exportações e na leitura em voz alta.';

  @override
  String get formatMenu => 'Formatação…';

  @override
  String get noteFont => 'Tipo de letra';

  @override
  String get noteFontDefault => 'Predefinido';

  @override
  String get noteFontSerif => 'Livro (serifado)';

  @override
  String get noteFontMono => 'Máquina de escrever';

  @override
  String get noteTextSize => 'Tamanho do texto';

  @override
  String get formatClear => 'Remover a formatação';

  @override
  String get formatHeading => 'Başlık';

  @override
  String get formatHeading1 => 'Büyük başlık';

  @override
  String get formatHeading2 => 'Alt başlık';

  @override
  String get formatNormalText => 'Normal metin';

  @override
  String get noteTextOpacity => 'Opacidade';

  @override
  String get assistantVoiceSetting => 'O assistente lê as respostas';

  @override
  String get assistantVoiceSettingInfo =>
      'O assistente de voz lê a sua resposta em voz alta (apenas no telemóvel).';

  @override
  String get assistantMute => 'Desativar o som';

  @override
  String get assistantUnmute => 'Ativar o som';

  @override
  String get assistantMakeNote => 'Transformar mesmo assim numa nota';

  @override
  String get assistantNoteCreated => 'Nota criada';

  @override
  String get noteNotFound => 'Nota não encontrada. Pode ter sido eliminada.';

  @override
  String get back => 'Voltar';

  @override
  String get addTextBlock => 'Adicionar texto';

  @override
  String get attachNoteContent => 'Not içeriği';

  @override
  String get noteBackgroundImage => 'Imagem de fundo';

  @override
  String get chooseBackgroundImage => 'Escolher imagem';

  @override
  String get changeBackgroundImage => 'Mudar de imagem';

  @override
  String get removeBackgroundImage => 'Remover o fundo';

  @override
  String get dashboardBackground => 'Fundo do ecrã principal';

  @override
  String get dashboardBackgroundInfo =>
      'Imagem mostrada por trás da grelha de notas (apenas neste dispositivo).';

  @override
  String get aiProvider => 'Fornecedor de IA';

  @override
  String get aiProviderInfo =>
      'Escolha o fornecedor a que pertence a sua chave. A chave de cada fornecedor é guardada em separado, por isso voltar atrás não obriga a escrevê-la de novo.';

  @override
  String get apiKeyFieldLabel => 'Chave da API';

  @override
  String get getApiKey => 'Onde obtenho uma chave?';

  @override
  String get recommendedModel => 'Recomendado';

  @override
  String get freeTierBadge => 'Tem um plano gratuito';

  @override
  String get continueWithoutAccount => 'Continuar sem conta';

  @override
  String get localAccountInfo =>
      'As suas notas ficam apenas neste dispositivo: não podem ser abertas noutro lado, desaparecem se desinstalar a aplicação, e a IA integrada está desligada. Pode associar uma conta Google a qualquer momento — as suas notas são mantidas.';

  @override
  String get localAccountBadge => 'Conta local';

  @override
  String get linkGoogleAccount => 'Associar uma conta Google';

  @override
  String get accountLinked =>
      'A sua conta Google está associada. As suas notas estão agora protegidas por cópia de segurança.';

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
      'O acesso sem Google está desativado: o login anônimo não está ativado no console do Firebase. Entre com o Google ou tente de novo quando um administrador ativar.';

  @override
  String get googleSignInUnavailable =>
      'O login com Google está desativado: o provedor Google não está ativado no console do Firebase.';

  @override
  String get signInNetworkError =>
      'Sem acesso à internet. Verifique sua conexão e tente novamente.';

  @override
  String get signInCanceled => 'Login cancelado.';

  @override
  String get cardRichPreview => 'Texto formatado nos cartões';

  @override
  String get cardRichPreviewInfo =>
      'As cores, marcações, negrito e sublinhado das suas notas também aparecem nos cartões da tela inicial. Desativado, os cartões mostram texto simples.';

  @override
  String get fontSizeSmall => 'Pequeno';

  @override
  String get fontSizeMedium => 'Médio';

  @override
  String get fontSizeLarge => 'Grande';

  @override
  String get fontSizeXLarge => 'Muito grande';

  @override
  String get appFontSetting => 'Fonte';

  @override
  String get appFontInfo =>
      'A fonte usada em todo o app. A fonte da própria nota tem prioridade. Todas as fontes vêm com o app — não precisa de internet.';

  @override
  String get fontGroupSans => 'Sem serifa';

  @override
  String get fontGroupSerif => 'Serifada';

  @override
  String get fontGroupMono => 'Monoespaçada';

  @override
  String get fontGroupHand => 'Manuscrita';

  @override
  String get appFontDefaultSuffix => 'padrão';

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
      'A voz de IA precisa da sua própria chave Gemini. Até lá, a leitura usa a voz do dispositivo.';

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
  String get shareAsText => 'Como texto simples';

  @override
  String get shareAsTextInfo =>
      'Envia o texto da nota e as notas de página para qualquer aplicativo.';

  @override
  String get shareAsTextEmpty => 'Esta nota não tem texto para compartilhar.';

  @override
  String get sharePdfWithBubbles => 'Como PDF com balões';

  @override
  String get sharePdfWithBubblesInfo =>
      'Balões, destaques e desenhos são gravados dentro do PDF; qualquer um pode abrir e no Not ele abre editável.';

  @override
  String get sharePdfWithBubblesNone =>
      'Esta nota não tem PDF com balões ou desenhos.';

  @override
  String get sharePdfWithBubblesPreparing => 'Preparando o PDF com balões…';

  @override
  String get sharePdfWithBubblesSuffix => ' (com balões)';

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
  String get formatRemove => 'Remover';

  @override
  String get exportTitle => 'Exportar';

  @override
  String get exportNotesOption => 'Texto da nota (PDF / Word)';

  @override
  String get exportNotesOptionInfo =>
      'Texto e imagens da nota; balões não incluídos.';

  @override
  String get captureNoteTitle => 'Título da nota (opcional)';

  @override
  String get captureNoteTitleHint => 'O novo documento também recebe este nome';

  @override
  String get imageOcrTitle => 'Reconhecer o texto da imagem';

  @override
  String get imageOcrNone => 'Nenhum texto encontrado nesta imagem.';

  @override
  String imageOcrHint(int count) {
    return '$count linhas reconhecidas · toque para selecionar';
  }

  @override
  String imageOcrSelected(int count) {
    return '$count linhas selecionadas';
  }

  @override
  String get imageOcrShort => 'Reconhecer texto';

  @override
  String get imageOcrWorking => 'Reconhecendo texto…';

  @override
  String get imageOcrSelectHint =>
      'Toque: palavra · Segure e arraste: letra a letra';

  @override
  String get imageOcrInsert => 'Adicionar à nota';

  @override
  String get imageOcrZoomIn => 'Ampliar';

  @override
  String get imageOcrZoomOut => 'Reduzir';

  @override
  String get selectImages => 'Selecionar imagens';

  @override
  String get exportImages => 'Imagens';

  @override
  String get exportImagesInfo =>
      'O texto flui ao lado de imagens estreitas alinhadas à esquerda ou à direita; as centralizadas ocupam a largura total.';

  @override
  String get exportAlignLeft => 'Esq.';

  @override
  String get exportAlignCenter => 'Centro';

  @override
  String get exportAlignRight => 'Dir.';

  @override
  String get exportImageWidth => 'Largura';

  @override
  String get exportImageLine => 'Posição';

  @override
  String get aiModelSearch => 'Pesquisar modelos';

  @override
  String get aiModelOthers => 'OUTROS MODELOS';

  @override
  String get aiModelNoMatch => 'Nenhum modelo correspondente.';

  @override
  String get aiModelAutoInfo =>
      'O app tenta os modelos mais adequados em ordem.';

  @override
  String imageOcrCharsSelected(int count) {
    return '$count caracteres selecionados';
  }

  @override
  String imagesSelectedCount(int count) {
    return '$count imagens selecionadas';
  }

  @override
  String attachmentsCopiedCount(int count) {
    return '$count anexos';
  }

  @override
  String exportImageLineOf(int count) {
    return '/ $count linhas';
  }

  @override
  String get aiModelShowAll => 'Mostrar todos';

  @override
  String get aiModelShowAllInfo => 'Também lista modelos que o app não usa.';

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
  String get archiveTemplateTitle => 'Sayfa şablonu';

  @override
  String get archiveTemplateBlank => 'Boş sayfa';

  @override
  String get archiveTemplateJournal => 'Günlük';

  @override
  String get archiveTemplateMeeting => 'Toplantı';

  @override
  String get archiveTemplateExpense => 'Harcamalar';

  @override
  String get archiveTemplateTodo => 'Yapılacaklar';

  @override
  String get archiveTemplateReading => 'Okuma notu';

  @override
  String get tplJournalHow => 'Bugün nasıldı?';

  @override
  String get tplJournalGrateful => 'Minnettar olduklarım';

  @override
  String get tplJournalTomorrow => 'Yarın için';

  @override
  String get tplMeetingAttendees => 'Katılımcılar';

  @override
  String get tplMeetingAgenda => 'Gündem';

  @override
  String get tplMeetingDecisions => 'Kararlar';

  @override
  String get tplMeetingActions => 'Kim, ne, ne zaman';

  @override
  String get tplExpenseColumns => 'Tarih · Açıklama · Tutar';

  @override
  String get tplExpenseTotal => 'Toplam:';

  @override
  String get tplReadingSource => 'Kaynak';

  @override
  String get tplReadingSummary => 'Özet';

  @override
  String get tplReadingQuotes => 'Alıntılar';

  @override
  String get tplReadingThoughts => 'Düşüncelerim';

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

  @override
  String imagesFitColumns(int count) {
    return '$count sütun';
  }

  @override
  String get imagesFitSingleRow => 'Tek satıra sığdır';

  @override
  String get briefingNotificationTitle => 'Günaydın! ☀️';

  @override
  String get briefingNotificationBody =>
      'Bugünün brifingi hazır — hatırlatıcıların, notların ve önemli e-postaların özeti için dokun.';

  @override
  String get reminderDone => 'Tamamlandı';

  @override
  String get dateToday => 'Bugün';

  @override
  String get dateTomorrow => 'Yarın';

  @override
  String get noteDuplicatedNoAttachments =>
      'Kopyalandı — ekler kopyaya taşınmadı';

  @override
  String get pdfGoToPage => 'Sayfaya git';

  @override
  String get pdfThumbnails => 'Sayfalara göz at';

  @override
  String get pdfBookmarks => 'Yer imleri';

  @override
  String get pdfBookmarkAdd => 'Yer imi koy';

  @override
  String get pdfBookmarkRemove => 'Yer imini kaldır';

  @override
  String get pdfNoBookmarks =>
      'Henüz yer imi yok. Sayfa çubuğundaki yer imi düğmesine dokunun.';

  @override
  String get pdfRotateView => 'Görünümü döndür';

  @override
  String get pdfCopyPageText => 'Sayfa metnini kopyala';

  @override
  String get pdfCapturePage => 'Sayfayı yakala (yapay zekâ / kopyala)';

  @override
  String get pdfSlideshow => 'Otomatik geçiş';

  @override
  String get pdfSlideshowStop => 'Otomatik geçişi durdur';

  @override
  String get pdfFirstPage => 'İlk sayfa';

  @override
  String get pdfLastPage => 'Son sayfa';

  @override
  String get pdfPlaceOnPage => 'PDF\'i sayfaya yerleştir';

  @override
  String get collaborators => 'Colaboradores';

  @override
  String get collaboratorsInfo =>
      'As pessoas que você adicionar verão esta nota na tela inicial e a editarão com você em tempo real.';

  @override
  String get collaboratorsOwner => 'Proprietário';

  @override
  String get collaboratorsFriendsTitle => 'SEUS AMIGOS';

  @override
  String get collaboratorsLeave => 'Sair da nota compartilhada';

  @override
  String get collaboratorsLeaveConfirm =>
      'Esta nota não aparecerá mais na sua tela inicial. Sair?';

  @override
  String get collaboratorsSaved => 'Compartilhamento atualizado';

  @override
  String collaboratorsCount(int count) {
    return 'Compartilhada com $count pessoas';
  }

  @override
  String get collaboratorsOnlyOwner =>
      'Somente o proprietário da nota pode alterar os colaboradores.';

  @override
  String get sharedWithMe => 'Compartilhadas comigo';

  @override
  String get sharedWithMeEmpty =>
      'Nenhuma nota foi compartilhada com você ainda. Elas aparecem aqui quando alguém adiciona você a uma nota.';

  @override
  String sharedByName(Object name) {
    return 'Compartilhada por $name';
  }

  @override
  String get navNotes => 'Notas';

  @override
  String get railExpand => 'Expandir menu';

  @override
  String get railCollapse => 'Recolher menu';

  @override
  String get newNoteShort => 'Nova nota';

  @override
  String get newChecklistShort => 'Nova lista';

  @override
  String get listPaneHide => 'Ocultar lista de notas';

  @override
  String get listPaneShow => 'Mostrar lista de notas';

  @override
  String get keyboardShortcuts => 'Atalhos de teclado';

  @override
  String get shortcutSearch => 'Pesquisar notas';

  @override
  String get shortcutToggleList => 'Ocultar / mostrar lista de notas';

  @override
  String get shortcutSections => 'Alternar entre seções';

  @override
  String get shortcutHelp => 'Mostrar atalhos';

  @override
  String get noNoteSelectedHint => 'ou comece uma nova nota';

  @override
  String get loginFeatureSyncTitle => 'As mesmas notas em todo dispositivo';

  @override
  String get loginFeatureSyncBody =>
      'Sincronização instantânea entre celular, tablet, computador e web.';

  @override
  String get loginFeatureAiTitle => 'IA ao seu lado';

  @override
  String get loginFeatureAiBody =>
      'Resuma, pergunte, dite; converse com seus documentos.';

  @override
  String get loginFeatureShareTitle => 'Escrevam juntos';

  @override
  String get loginFeatureShareBody =>
      'Compartilhe notas e pastas ao vivo com amigos.';

  @override
  String get loginFeatureInkTitle => 'Caneta e PDF';

  @override
  String get loginFeatureInkBody =>
      'Faça anotações à mão, escreva sobre PDFs e slides.';

  @override
  String get foldersTitle => 'Pastas';

  @override
  String get foldersEmpty =>
      'Nenhuma pasta ainda. Crie uma para organizar suas notas.';

  @override
  String get folderColor => 'Cor';

  @override
  String get folderColorAuto => 'Automática';

  @override
  String get foldersMine => 'Minhas pastas';

  @override
  String get foldersSharedSection => 'Pastas compartilhadas comigo';

  @override
  String trashDaysShort(int count) {
    return '$count d';
  }

  @override
  String get trashTodayShort => 'Hoje';

  @override
  String get trashSoonSection => 'Serão excluídas em breve';

  @override
  String get trashRestSection => 'Outras notas excluídas';

  @override
  String get aiHubTagline => 'Pergunte, resuma e organize suas notas.';

  @override
  String get aiToolsSection => 'Ferramentas';

  @override
  String get folderOrderTitle => 'Ordem das pastas';

  @override
  String get folderReorder => 'Reordenar pastas';

  @override
  String get folderOrderManual => 'Personalizado';

  @override
  String get folderOrderName => 'Por nome';

  @override
  String get folderOrderNewest => 'Mais recentes primeiro';

  @override
  String get folderOrderNoteCount => 'Por número de notas';

  @override
  String get folderOrderHint =>
      'Arraste as alças para reordenar. A mesma ordem é usada na barra de pastas e ao deslizar.';

  @override
  String get swipeModeTitle => 'Deslizar na tela inicial';

  @override
  String get swipeModeFolders => 'Alternar entre pastas';

  @override
  String get swipeModeFilters => 'Alternar entre filtros e etiquetas';

  @override
  String get swipeModeBoth => 'Pastas, filtros e etiquetas';

  @override
  String get swipeModeOff => 'Desativado';

  @override
  String get shareIncludeTitle => 'Título';

  @override
  String get shareIncludeChecked => 'Concluídos';

  @override
  String get shareIncludeTags => 'Etiquetas';

  @override
  String get shareTextAction => 'Compartilhar texto';

  @override
  String get shareAsFileSection => 'Como arquivo';

  @override
  String get shareInAppSection => 'No app';

  @override
  String get shareSendFriendInfo =>
      'Deixa uma cópia da nota na caixa de entrada de um amigo.';

  @override
  String get shareCollaborateInfo =>
      'Edite a mesma nota com amigos; as alterações aparecem na hora.';

  @override
  String get findPrevious => 'Resultado anterior';

  @override
  String get findNext => 'Próximo resultado';

  @override
  String get findShowAll => 'Todos os resultados';

  @override
  String findMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count resultados',
      one: '1 resultado',
      zero: 'Nenhum resultado',
    );
    return '$_temp0';
  }

  @override
  String get findDeepSearch => 'Buscar em anexos e com IA';

  @override
  String get notesSettingsTitle => 'Notas e pastas';

  @override
  String get noteViewSetting => 'Layout da tela inicial';

  @override
  String get noteViewGrid => 'Grade';

  @override
  String get noteViewList => 'Lista';

  @override
  String get gridColumnsSetting => 'Colunas';

  @override
  String get gridColumnsInfo =>
      'Você também pode mudar isso com gesto de pinça na tela inicial.';

  @override
  String get gridColumnsAuto => 'Automático';

  @override
  String get folderShelfSetting => 'Pastas na tela inicial';

  @override
  String get folderShelfStrip => 'Uma linha';

  @override
  String get folderShelfTiles => 'Blocos';

  @override
  String get deviceStorageTitle => 'Neste dispositivo';

  @override
  String get deviceStorageAttachments => 'Anexos';

  @override
  String get deviceStorageDatabase => 'Cópia local das notas';

  @override
  String get deviceStorageCache => 'Cache e arquivos temporários';

  @override
  String get deviceStorageAi => 'Cache de IA';

  @override
  String get deviceStorageTotal => 'Total (sem o app)';

  @override
  String get deviceStorageInfo =>
      'Limpar o cache não apaga notas nem anexos; as imagens são baixadas de novo quando necessário. Arquivos temporários antigos são limpos a cada abertura.';

  @override
  String get deviceStorageClear => 'Limpar cache';

  @override
  String deviceStorageCleared(String size) {
    return '$size liberados';
  }

  @override
  String get deviceStorageUnavailable =>
      'Não foi possível medir neste dispositivo.';

  @override
  String get localOnlyTurnOn => 'Parar de sincronizar';

  @override
  String get localOnlyTurnOff => 'Sincronizar esta nota';

  @override
  String get localOnlyBadge => 'Só neste dispositivo';

  @override
  String get localOnlyConfirmTitle => 'Manter esta nota só neste dispositivo?';

  @override
  String get localOnlyConfirmBody =>
      'A nota e seus anexos são removidos da nuvem e não aparecerão nos seus outros dispositivos. Se você desinstalar o app ou trocar de celular, esta nota também se perde. Você pode reativar a sincronização quando quiser.';

  @override
  String get localOnlyConfirm => 'Parar';

  @override
  String get localOnlyOnDone => 'A nota agora está só neste dispositivo';

  @override
  String get localOnlyOffDone => 'A nota voltou a sincronizar';

  @override
  String get localOnlySharedBlocked =>
      'Não é possível parar a sincronização de uma nota compartilhada';

  @override
  String get localOnlyDownloadFailed =>
      'Alguns anexos não puderam ser baixados. Verifique a conexão e tente de novo; a nota não mudou.';

  @override
  String get templatesTitle => 'Modelos';

  @override
  String get templatesSubtitle =>
      'Comece com um layout pronto; tudo pode ser mudado depois.';

  @override
  String get fromTemplate => 'De um modelo';

  @override
  String get tplShoppingName => 'Lista de compras';

  @override
  String get tplShoppingItems => 'Pão, Leite, Ovos, Frutas, Legumes';

  @override
  String get tplShoppingDesc => 'Marque o que comprou; vai para baixo';

  @override
  String get tplTodoDesc => 'Lista vazia com a data de hoje';

  @override
  String get tplTravelName => 'Lista de bagagem';

  @override
  String get tplTravelItems =>
      'Documento / passaporte, Carregador, Remédios, Escova de dentes, Roupas, Fones';

  @override
  String get tplTravelDesc => 'Checklist pronta';

  @override
  String get tplMeetingDesc => 'Participantes, pauta, decisões';

  @override
  String get tplJournalDesc => 'Como foi hoje, gratidão, amanhã';

  @override
  String get tplRecipeName => 'Receita';

  @override
  String get tplRecipeMeta => 'Porções: · Tempo:';

  @override
  String get tplRecipeIngredients => 'Ingredientes';

  @override
  String get tplRecipeSteps => 'Modo de preparo';

  @override
  String get tplRecipeNotes => 'Notas';

  @override
  String get tplRecipeDesc => 'Ingredientes e passos';

  @override
  String get tplWeeklyName => 'Plano semanal';

  @override
  String get tplWeeklyDesc => 'Os dias desta semana como títulos';

  @override
  String get tplExpenseDesc => 'Data, descrição, valor';

  @override
  String get tplReadingDesc => 'Fonte, resumo, citações';

  @override
  String get settingsThemeHeader => 'Tema';

  @override
  String get settingsCardsHeader => 'Cartões e listas';

  @override
  String get shareTargetTitle => 'Adicionar às Notas';

  @override
  String get shareTargetNew => 'Nova nota';

  @override
  String get shareTargetExisting => 'Nota existente';

  @override
  String get shareTargetCreate => 'Criar nota';

  @override
  String get shareTargetSearch => 'Pesquisar notas';

  @override
  String get shareTargetNoNotes => 'Nenhuma nota disponível';

  @override
  String get shareTargetNoMatch => 'Nenhuma nota corresponde';

  @override
  String shareTargetMore(int count) {
    return '+$count arquivos';
  }

  @override
  String get sharePreviewExpand => 'Ampliar pré-visualização';

  @override
  String get sharePreviewCollapse => 'Reduzir pré-visualização';

  @override
  String get templatesSearch => 'Pesquisar modelos';

  @override
  String get templatesAll => 'Todos';

  @override
  String get templatesLists => 'Listas';

  @override
  String get templatesPlanning => 'Planejamento';

  @override
  String get templatesWriting => 'Escrita';

  @override
  String get templatesMine => 'Meus modelos';

  @override
  String get templatesRecent => 'Usados recentemente';

  @override
  String get templatesNoMatch => 'Nenhum modelo corresponde';

  @override
  String get templatesMineEmpty =>
      'Você ainda não tem modelos próprios. Escolha “Salvar como modelo” no menu de uma nota e ele aparecerá aqui.';

  @override
  String get templatesMineInfo => 'Seu modelo';

  @override
  String get templateRename => 'Renomear';

  @override
  String get templateDelete => 'Excluir modelo';

  @override
  String get templateNameTitle => 'Nome do modelo';

  @override
  String get templateNameHint => 'ex. Compras da semana';

  @override
  String get templateSave => 'Salvar';

  @override
  String templateSaved(String name) {
    return '“$name” adicionado aos seus modelos';
  }

  @override
  String get saveAsTemplate => 'Salvar como modelo';

  @override
  String get templateCreate => 'Criar';

  @override
  String templateCreateWithCount(int count) {
    return 'Criar · $count itens';
  }

  @override
  String get templateListChecks => 'Caixas de seleção';

  @override
  String get templateListNumbers => 'Numerada';

  @override
  String get templateItems => 'Itens';

  @override
  String get templateAddItem => 'Adicionar item';

  @override
  String get templateSuggestionsInfo =>
      'Toque numa sugestão para adicioná-la; toque de novo para removê-la.';

  @override
  String get tplShopProduce => 'Frutas e legumes';

  @override
  String get tplShopProduceItems =>
      'Tomates, Pepinos, Cebolas, Batatas, Limões, Bananas, Maçãs, Salsa';

  @override
  String get tplShopBreakfast => 'Café da manhã';

  @override
  String get tplShopBreakfastItems =>
      'Queijo, Azeitonas, Manteiga, Mel, Geleia, Iogurte';

  @override
  String get tplShopPantry => 'Despensa';

  @override
  String get tplShopPantryItems =>
      'Arroz, Macarrão, Farinha, Açúcar, Azeite, Lentilhas, Chá, Café';

  @override
  String get tplShopCleaning => 'Limpeza';

  @override
  String get tplShopCleaningItems =>
      'Detergente de louça, Sabão em pó, Papel higiênico, Papel toalha, Sacos de lixo';

  @override
  String get tplShopPersonal => 'Higiene pessoal';

  @override
  String get tplShopPersonalItems =>
      'Xampu, Pasta de dente, Sabonete, Desodorante';

  @override
  String get tplTravelDocs => 'Documentos';

  @override
  String get tplTravelDocsItems =>
      'Passagens, Reserva de hotel, Carteira de motorista, Seguro-viagem, Dinheiro / cartões';

  @override
  String get tplTravelClothes => 'Roupas';

  @override
  String get tplTravelClothesItems =>
      'Camisetas, Calças, Roupa íntima, Meias, Pijama, Jaqueta, Sapatos';

  @override
  String get tplTravelCare => 'Higiene';

  @override
  String get tplTravelCareItems =>
      'Pasta de dente, Xampu, Protetor solar, Kit de barbear, Desodorante';

  @override
  String get tplTravelTech => 'Eletrônicos';

  @override
  String get tplTravelTechItems =>
      'Carregador portátil, Adaptador de tomada, Fones de ouvido, Cabos';

  @override
  String get tplHabitsName => 'Rastreador de hábitos';

  @override
  String get tplHabitsDesc => 'Marque todo dia, não quebre a corrente';

  @override
  String get tplHabitsItems =>
      '8 copos de água, Caminhada de 30 minutos, Ler 20 páginas, Dormir cedo, Uma hora sem telas';

  @override
  String get tplCleaningName => 'Limpeza da casa';

  @override
  String get tplCleaningDesc => 'Lista semanal de limpeza';

  @override
  String get tplCleaningItems =>
      'Tirar o pó, Aspirar, Passar pano, Limpar o banheiro, Bancada da cozinha, Lavar roupa, Levar o lixo, Trocar a roupa de cama';

  @override
  String get tplMovingName => 'Lista de mudança';

  @override
  String get tplMovingDesc => 'O que fazer antes e depois da mudança';

  @override
  String get tplMovingItems =>
      'Contratar a mudança, Comprar caixas e fita, Atualizar o endereço, Luz / água / gás, Transferir a internet, Entregar as chaves';

  @override
  String get tplGiftsName => 'Lista de presentes';

  @override
  String get tplGiftsDesc => 'Quem ganha o quê, ideias';

  @override
  String get tplGiftsItems => 'Mãe, Pai, Irmão, Amigo';

  @override
  String get tplWatchlistName => 'Para assistir';

  @override
  String get tplWatchlistDesc => 'Filmes, séries e livros';

  @override
  String get tplWorkoutName => 'Treino';

  @override
  String get tplWorkoutDesc => 'Do aquecimento ao alongamento';

  @override
  String get tplWorkoutItems =>
      'Aquecimento 5 min, Agachamento 3×12, Flexões 3×10, Abdominais 3×15, Prancha 3×45 s, Alongamento 5 min';

  @override
  String get tplGoalsName => 'Metas';

  @override
  String get tplGoalsDesc => 'Metas do ano, do mês e da semana';

  @override
  String get tplGoalsYear => 'Este ano';

  @override
  String get tplGoalsMonth => 'Este mês';

  @override
  String get tplGoalsWeek => 'Esta semana';

  @override
  String get tplGoalsWhy => 'Por que é importante?';

  @override
  String get templateNew => 'Novo modelo';

  @override
  String get templateEdit => 'Editar modelo';

  @override
  String get templateDuplicate => 'Duplicar';

  @override
  String get templateSaveAsMine => 'Salvar nos meus modelos';

  @override
  String get templateUntitled => 'Modelo sem título';

  @override
  String get templateTypeText => 'Texto';

  @override
  String get templateTitleHelp =>
      'Título das notas criadas com este modelo (opcional)';

  @override
  String get templateBody => 'Texto';

  @override
  String get templateHeadingHelp =>
      'Linhas que começam com “# ” viram títulos; com “## ”, subtítulos.';

  @override
  String get templateDiscardTitle => 'Descartar alterações?';

  @override
  String get templateDiscard => 'Descartar';

  @override
  String templateDeleted(String name) {
    return '“$name” excluído';
  }
}
