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
      'Falha no envio — toque para tentar de novo';

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
    return 'O assistente quer mover a nota "${title}" para a lixeira. Você aprova?';
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
  String get newPdfNote => 'Adicionar PDF e fazer anotações';

  @override
  String get imageNotePreparing => 'Organizando as imagens em um documento…';

  @override
  String get newImageNote => 'Adicionar imagem e anotar';

  @override
  String get pdfPageNoteHint => 'Nota desta página…';

  @override
  String pdfPage(int page) {
    return 'Página ${page}';
  }

  @override
  String pdfPageOf(int page, int total) {
    return 'Página ${page} / ${total}';
  }

  @override
  String get pdfPreviousPage => 'Página anterior';

  @override
  String get pdfNextPage => 'Próxima página';

  @override
  String get pdfFullScreen => 'Abrir em tela cheia';

  @override
  String get pdfNoDocument => 'Esta nota ainda não tem PDF';

  @override
  String get pdfChooseDocument => 'Escolher PDF';

  @override
  String get newSlidesNote => 'Adicionar slides e fazer anotações';

  @override
  String get slidesNoDocument => 'Esta nota ainda não tem apresentação';

  @override
  String get slidesChooseDocument => 'Escolher apresentação';

  @override
  String get pdfEditPages => 'Editar páginas';

  @override
  String get pdfDeletePages => 'Excluir as páginas selecionadas';

  @override
  String get pdfAddBlankPage => 'Adicionar página em branco';

  @override
  String get pdfRotatePages => 'Girar';

  @override
  String get pdfBurnInk => 'Gravar a escrita à mão no documento';

  @override
  String get pdfApplyChanges => 'Aplicar alterações';

  @override
  String get pdfCannotDeleteAllPages => 'Você não pode excluir todas as páginas';

  @override
  String get pdfPagesHint =>
      'Toque em uma página para selecioná-la. As notas de página acompanham a página; a nota de uma página excluída fica oculta, mas é mantida nos seus dados.';

  @override
  String pdfEditFailed(String error) {
    return 'Não foi possível editar o PDF: ${error}';
  }

  @override
  String get pdfInkBurned => 'Escrita à mão gravada no documento';

  @override
  String get pdfAllPageNotes => 'Todas as notas de página';

  @override
  String get pdfNoPageNotes =>
      'Ainda não há notas de página. Vá até uma página e escreva no campo abaixo.';

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
  String get attachNoteContent => 'Conteúdo da nota';

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
    return 'Página ${current} / ${total}';
  }

  @override
  String get scanRotatePage => 'Girar a página';

  @override
  String get scanDeletePage => 'Excluir a página';

  @override
  String get scanLastPage => 'A última página não pode ser excluída';

  @override
  String get scanDiscardTitle => 'Descartar as páginas digitalizadas?';

  @override
  String get scanDiscardConfirm => 'Descartar';

  @override
  String get scanAdjustCorners => 'Ajustar os cantos';

  @override
  String get scanFilterOriginal => 'Original';

  @override
  String get scanFilterAuto => 'Melhorar';

  @override
  String get scanFilterGray => 'Tons de cinza';

  @override
  String get scanFilterBw => 'Preto e branco';

  @override
  String get scanApplyAll => 'Aplicar a todas';

  @override
  String get scanPageFailed => 'Não foi possível exibir a página';

  @override
  String get scanCropHint =>
      'Corrija uma página torta com "Ajustar os cantos"';

  @override
  String get scanAddAsPdf => 'Adicionar como PDF';

  @override
  String get scanAddAsImages => 'Adicionar como imagens';

  @override
  String get scanBuildingPdf => 'Preparando o PDF…';

  @override
  String scanOcrProgress(int done, int total) {
    return 'Reconhecendo o texto… ${done}/${total}';
  }

  @override
  String get scanAutoDetect => 'Detectar bordas automaticamente';

  @override
  String get scanReset => 'Redefinir';

  @override
  String get scanDetecting => 'Procurando as bordas…';

  @override
  String get scanAutoFound =>
      'Bordas encontradas automaticamente; ajuste com as alças se precisar';

  @override
  String get scanDragHint => 'Arraste os cantos até as bordas do papel';

  @override
  String get scanApplyCorners => 'Endireitar e aplicar';

  @override
  String get scanWorking => 'Endireitando…';

  @override
  String get scanPdfAdded => 'Digitalização adicionada à nota como anexo PDF';

  @override
  String get premiumTitle => 'Premium';

  @override
  String premiumStatusActive(String date) {
    return 'Premium ativo — até ${date}';
  }

  @override
  String get premiumStatusFree => 'Você está usando a versão gratuita';

  @override
  String get premiumPerksTitle => 'O que muda com o Premium?';

  @override
  String get premiumPerkAi => 'Pontos de IA diários';

  @override
  String get premiumPerkAttach => 'Tamanho dos anexos';

  @override
  String get premiumPerkStorage => 'Armazenamento na nuvem';

  @override
  String get premiumPerkAuto => 'Conteúdo diário automático';

  @override
  String get premiumPerkAutoBody =>
      'O resumo diário e as sugestões são preparados automaticamente todos os dias; na versão gratuita eles só rodam quando você pede.';

  @override
  String get premiumHowTitle => 'Como conseguir?';

  @override
  String get premiumHowBody =>
      'O Premium chegará em breve pela Play Store. No momento estamos em acesso antecipado.';

  @override
  String get premiumByokHint =>
      'Se você inserir sua própria chave da API do Gemini, os recursos de IA funcionam sem cota — independentemente do Premium (Configurações → IA).';

  @override
  String get premiumDiscoverTitle => 'Recursos que você talvez tenha perdido';

  @override
  String get discoverScanBody =>
      'As páginas digitalizadas são endireitadas e melhoradas e viram um PDF PESQUISÁVEL com um toque — a camada de texto é criada no aparelho, de graça.';

  @override
  String get discoverSemanticBody =>
      'A aba "Inteligente" na busca procura por SIGNIFICADO, não por palavras: digite "horários de voo" e sua nota de viagem aparece.';

  @override
  String get discoverAssistantBody =>
      'O microfone da tela inicial transforma sua fala em notas, listas e lembretes sozinho — é só dizer "amanhã às 9 no dentista".';

  @override
  String get discoverLockBody =>
      'Você pode bloquear uma nota com digital ou rosto: o conteúdo dela nunca vaza para a busca, os widgets ou a IA.';

  @override
  String get discoverHiddenBody =>
      'As notas de uma pasta oculta nunca aparecem na tela inicial nem na busca; revelar a pasta exige autenticação.';

  @override
  String get discoverExportBody =>
      'Toda nota pode ser exportada como PDF ou Word, com imagens incluídas (no menu de compartilhar).';

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
  String get pdfSelectOcrRunning => 'Reconhecendo o texto…';

  @override
  String get pdfSelectOcrNone => 'Nenhum texto encontrado nesta página';

  @override
  String pdfSelectCopied(int n) {
    return '${n} caracteres copiados';
  }

  @override
  String get bubbleAdd => 'Colocar um balão de nota';

  @override
  String get bubbleAddDone => 'Terminei de adicionar balões';

  @override
  String get bubbleCollapse => 'Recolher o balão';

  @override
  String get bubbleHint => 'Escreva sua nota aqui…';

  @override
  String get bubbleTapToPlace => 'Toque no ponto da página onde quer o balão';

  @override
  String get aiModelPodcast => 'Narração de podcast';

  @override
  String get listenAiVoice => 'Ouvir com voz de IA';

  @override
  String get listenAiVoiceInfo =>
      'O Gemini narra no lugar da voz do aparelho: mais natural, mas cada parágrafo custa uma chamada ao modelo.';

  @override
  String listenAiVoiceFailed(String error) {
    return 'A narração por IA falhou (${error}). Lendo com a voz do aparelho.';
  }

  @override
  String get ttsSectionTitle => 'Narração';

  @override
  String get ttsEngineDevice => 'Voz do aparelho';

  @override
  String get ttsEngineAi => 'IA';

  @override
  String get ttsEngineDeviceInfo =>
      'A voz integrada do aparelho lê: grátis, offline e sem limite de tamanho.';

  @override
  String get ttsEngineAiInfo =>
      'O modelo de fala do Gemini lê: bem mais natural, mas cada parágrafo é uma chamada ao modelo e é preciso ter sua própria chave do Gemini.';

  @override
  String get ttsEngineAiUnavailable =>
      'A voz de IA precisa da sua própria chave Gemini. Até lá, a leitura usa a voz do dispositivo.';

  @override
  String get ttsModel => 'Modelo de fala';

  @override
  String get ttsVoice => 'Voz de IA';

  @override
  String get shareAsNote => 'Compartilhar como nota';

  @override
  String get shareAsNoteInfo =>
      'Envia a nota com anexos, notas de página, desenhos e balões; do outro lado ela abre igualzinha no app Not.';

  @override
  String get shareAsNotePreparing => 'Preparando o pacote da nota…';

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
  String get bubbleStar => 'Destacar';

  @override
  String get bubbleEdit => 'Editar o balão';

  @override
  String get bubbleStarredOnly => 'Somente os destacados';

  @override
  String get bubbleSearchHint => 'Buscar nos balões…';

  @override
  String get bubblesOverviewTitle => 'Balões';

  @override
  String get bubblesEmpty =>
      'Ainda não há balões. Selecione um texto no documento e destaque-o, ou coloque um balão na página.';

  @override
  String get bubblesNoMatch => 'Nenhum balão corresponde à sua busca.';

  @override
  String get bubbleNoText => '(balão vazio)';

  @override
  String get pdfHighlight => 'Destacar';

  @override
  String get pdfHighlightWithNote => 'Destacar + nota';

  @override
  String get pageNotesShow => 'Mostrar a nota de página';

  @override
  String get pageNotesHide => 'Ocultar a nota de página';

  @override
  String get bubbleSave => 'Salvar';

  @override
  String get bubbleTitleHint => 'Título';

  @override
  String get bubbleUrgent => 'Urgente (pisca)';

  @override
  String get captureModeQuestion => 'Como a nota deve abrir?';

  @override
  String get captureModeBubbles => 'Balões';

  @override
  String get captureModeBubblesInfo =>
      'O conteúdo vira uma página de documento: balões, destaques e caneta.';

  @override
  String get captureModeClassic => 'Clássica';

  @override
  String get captureModeClassicInfo =>
      'Nota de texto simples; o conteúdo entra como anexo.';

  @override
  String get captureModeNew => 'NOVO';

  @override
  String get imagePrepareTitle => 'Ajustar as imagens';

  @override
  String get imagePrepareDone => 'Continuar';

  @override
  String get imageRotateLeft => 'Girar para a esquerda';

  @override
  String get imageRotateRight => 'Girar para a direita';

  @override
  String get videoFrameFailed =>
      'Não foi possível capturar um quadro do vídeo; abrindo uma nota clássica.';

  @override
  String get bubbleArrowHide => 'Ocultar a seta';

  @override
  String get bubbleArrowShow => 'Mostrar a seta';

  @override
  String get speechPitch => 'Tom da voz';

  @override
  String get speechVoicePickerTitle => 'Seleção de voz';

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
  String get rotateFailed => 'Não foi possível girar a imagem.';

  @override
  String get dashboardBackgroundPick => 'Escolher imagem de fundo';

  @override
  String get dashboardBackgroundChange => 'Trocar a imagem de fundo';

  @override
  String podcastRenderingAudio(int done, int total) {
    return 'Preparando o áudio: ${done}/${total} partes';
  }

  @override
  String get podcastExportAudio => 'Exportar como arquivo de áudio';

  @override
  String get podcastExportAudioCost =>
      'Todo o roteiro é sintetizado de novo com a voz de IA e salvo em um único arquivo WAV. Isso consome sua cota do Gemini e pode levar alguns minutos em textos longos.';

  @override
  String get podcastShareText => 'Compartilhar o roteiro';

  @override
  String get podcastSaveAsNote => 'Salvar como nova nota';

  @override
  String get podcastSavedAsNote => 'O roteiro do podcast foi salvo como nota.';

  @override
  String get listenPreparingVoice => 'Preparando o áudio…';

  @override
  String get appearancePreviewTitle => 'Texto de exemplo';

  @override
  String get appearancePreviewNoteTitle => 'Título de nota de exemplo';

  @override
  String get appearancePreviewBody =>
      'Suas notas vão ficar assim. Texto **em negrito**, ~sublinhado~ e ==2:destacado== aparece deste jeito.';

  @override
  String get appearancePreviewItem => 'Um item de lista fica assim';

  @override
  String get convertToText => 'Converter em texto';

  @override
  String get convertToList => 'Converter em lista';

  @override
  String get convertedToText => 'A lista foi convertida em texto simples.';

  @override
  String get convertedToList => 'O texto foi convertido em lista.';

  @override
  String get convertToListEmpty => 'Não há linhas para converter em lista.';

  @override
  String get listTwoColumns => 'Duas colunas';

  @override
  String get listOneColumn => 'Uma coluna';

  @override
  String get sortItems => 'Ordenar os itens';

  @override
  String get sortStarredFirst => 'Destacados primeiro';

  @override
  String get sortUncheckedFirst => 'Concluídos por último';

  @override
  String get sortAlphabetical => 'A → Z';

  @override
  String get sortAlphabeticalDesc => 'Z → A';

  @override
  String get imagesToAttachments => 'Mover as imagens para os anexos';

  @override
  String imagesToAttachmentsDone(int count) {
    return '${count} imagens movidas para os anexos.';
  }

  @override
  String get imageOcrShowRecognized => 'Destacar o texto reconhecido';

  @override
  String get imageOcrHideRecognized => 'Ocultar o destaque';

  @override
  String get bubblePlainMode => 'Caixa de texto aberta';

  @override
  String get bubblePlainModeOn => 'A caixa de texto aberta está ativada';

  @override
  String get bubblePlainTapToPlace => 'Toque onde o texto deve ficar';

  @override
  String get bubblePlainHint => 'Toque para escrever';

  @override
  String get noteSearchTitle => 'Buscar na nota';

  @override
  String get noteSearchHint => 'Buscar nesta nota…';

  @override
  String get noteSearchEmptyHint =>
      'Busca na hora no texto da nota, nos itens e nas notas de página. Inicie a varredura abaixo para procurar dentro dos anexos de imagem e PDF.';

  @override
  String get noteSearchNoHit => 'Nenhum resultado encontrado.';

  @override
  String get noteSearchScanAttachments => 'Varrer os anexos';

  @override
  String get noteSearchAskAi => 'Perguntar à IA';

  @override
  String get noteTitleLabel => 'Título';

  @override
  String get noteBodyLabel => 'Texto da nota';

  @override
  String get itemLabel => 'Item';

  @override
  String noteSearchAttachmentsInfo(int count) {
    return '${count} anexos podem ser varridos (imagem/PDF).';
  }

  @override
  String noteSearchAttachmentsReady(int count) {
    return 'A busca também cobre ${count} anexos.';
  }

  @override
  String pageLabel(int page) {
    return 'Página ${page}';
  }

  @override
  String get archiveNotebook => 'Caderno de arquivo';

  @override
  String get archiveNotebookInfo =>
      'Um caderno com páginas próprias que guarda cópias de documentos e imagens importantes.';

  @override
  String get archivePageImages => 'Imagens';

  @override
  String get archivePageVideos => 'Vídeos';

  @override
  String get archivePageDocuments => 'Documentos';

  @override
  String get archivePageTexts => 'Textos';

  @override
  String get archiveNewPage => 'Nova página';

  @override
  String get archivePageName => 'Nome da página (ex.: Faturas)';

  @override
  String get archivePageEmpty => 'Esta página está vazia.';

  @override
  String get archiveSearchHint => 'Buscar no caderno…';

  @override
  String get archiveAddText => 'Adicionar texto';

  @override
  String get archiveAddFile => 'Adicionar arquivo';

  @override
  String get archiveCopyHere => 'Copiar para um caderno de arquivo';

  @override
  String get archiveNoNotebook =>
      'Ainda não há caderno de arquivo. Crie um primeiro.';

  @override
  String get archiveNothingToCopy => 'Esta nota não tem anexos para copiar.';

  @override
  String archiveDeleteEntry(String name) {
    return 'Excluir "${name}" do caderno? Esta cópia se perde para sempre.';
  }

  @override
  String archiveCopied(int count) {
    return '${count} arquivos copiados para o caderno de arquivo.';
  }

  @override
  String get archiveCaptureTitle => 'Capturar de uma imagem';

  @override
  String get archiveCapturePage => 'Página';

  @override
  String get archiveCapturePageInfo =>
      'O tipo sugerido pela IA. Se ficar vazio, vai para a página Textos.';

  @override
  String get archiveCaptureText => 'Texto reconhecido';

  @override
  String get attachmentTagInsert => 'Inserir no texto';

  @override
  String get attachmentTagInserted => 'A etiqueta do anexo foi inserida.';

  @override
  String get attachmentTagPreview => 'Ver o anexo';

  @override
  String get attachmentTagEdit => 'Editar o anexo';

  @override
  String archiveCardSummary(int files, int texts) {
    return '${files} arquivos · ${texts} textos';
  }

  @override
  String get archiveEntryTitle => 'Título';

  @override
  String get archiveLinkedFile => 'Arquivo vinculado';

  @override
  String get archiveNoLink => 'Sem arquivo vinculado';

  @override
  String get attachmentTagEmbed => 'Embutir o anexo na seleção';

  @override
  String get attachmentTagNoAttachment =>
      'Adicione primeiro um arquivo à nota; depois você pode embuti-lo no texto.';

  @override
  String get bubbleModeBubble => 'Balão';

  @override
  String get attachmentTagEmbedInfo =>
      'Vincula ao texto selecionado, ou ao cursor se nada estiver selecionado';

  @override
  String get attachmentTagPickText =>
      'Agora selecione o texto a vincular e toque em "Vincular aqui".';

  @override
  String get attachmentTagLinkHere => 'Vincular aqui';

  @override
  String attachmentTagPendingBanner(String name) {
    return '${name} será vinculado — selecione o texto';
  }

  @override
  String get docNameNotesSuffix => 'notas';

  @override
  String get docNamePhoto => 'Notas da foto';

  @override
  String get docNameScan => 'Notas da digitalização';

  @override
  String get docNameImage => 'Notas da imagem';

  @override
  String get docNameVideo => 'Notas do vídeo';

  @override
  String get folderManage => 'Gerenciar a pasta';

  @override
  String get folderEmpty => 'Esta pasta está vazia';

  @override
  String get folderEmptyHint =>
      'Adicione uma nota com o + abaixo, ou mova uma nota para cá enquanto a edita.';

  @override
  String get brainstormTitle => 'Brainstorm com IA';

  @override
  String get brainstormRowInfo =>
      'A IA rascunha um roteiro primeiro e depois vocês constroem juntos';

  @override
  String get brainstormIntro =>
      'Toque em um dos títulos acima ou apenas escreva — vamos pensar juntos.';

  @override
  String get brainstormOutlineTitle => 'ROTEIRO';

  @override
  String get brainstormInputHint => 'Escreva uma ideia ou faça uma pergunta…';

  @override
  String get brainstormAddIdea => 'Adicionar à nota';

  @override
  String get brainstormAdded => 'Adicionado à nota';

  @override
  String get folderShared => 'Esta pasta está compartilhada com um amigo';

  @override
  String get friendsTitle => 'Contatos';

  @override
  String get friendsAdd => 'Adicionar amigo';

  @override
  String get friendsEmpty =>
      'Ainda ninguém. Adicione um amigo por e-mail para compartilhar pastas com ele.';

  @override
  String get friendsRequestsTitle => 'SOLICITAÇÕES';

  @override
  String get friendsListTitle => 'MEUS AMIGOS';

  @override
  String get friendsAddEmailHint => 'amigo@email.com';

  @override
  String get friendsSendRequest => 'Enviar solicitação';

  @override
  String get friendsRequestSent => 'Solicitação enviada';

  @override
  String get friendsNotFound =>
      'Nenhum usuário está registrado com este e-mail. Ele precisa ter aberto o app pelo menos uma vez com uma conta Google.';

  @override
  String get friendsSelf => 'Você não pode adicionar a si mesmo como amigo';

  @override
  String get friendsAlready => 'Vocês já são amigos';

  @override
  String get friendsDecline => 'Recusar';

  @override
  String get friendsAccept => 'Aceitar';

  @override
  String get friendsRemove => 'Remover';

  @override
  String get friendsRemoveConfirmTitle => 'Remover amigo';

  @override
  String friendsRemoveConfirmBody(Object name) {
    return 'Remover ${name} dos seus amigos? As pastas que você compartilhou com ele deixarão de ficar visíveis.';
  }

  @override
  String get friendsNeedsAccount =>
      'Contatos e compartilhamento de pastas exigem uma conta Google vinculada.';

  @override
  String get friendsSearchHint => 'Buscar por nome ou e-mail';

  @override
  String get friendsSearchTab => 'Buscar';

  @override
  String get friendsSearchEmailTab => 'Por e-mail';

  @override
  String get friendsSearchEmpty => 'Sem resultados';

  @override
  String get friendsSearchTooShort => 'Digite pelo menos 2 caracteres para buscar';

  @override
  String get friendsSearchAdd => 'Adicionar';

  @override
  String get folderShare => 'Compartilhar';

  @override
  String folderShareCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Compartilhada com ${count} pessoas',
      one: 'Compartilhada com 1 pessoa',
    );
    return '$_temp0';
  }

  @override
  String folderShareTitle(Object name) {
    return 'Compartilhar "${name}"';
  }

  @override
  String get folderShareInfo =>
      'Um convite vai para o amigo que você escolher; ele vê a pasta assim que aceitar. Você escolhe a permissão dele (leitura / escrita / ambas).';

  @override
  String get friendsRowInfo => 'Adicione amigos e compartilhe pastas com eles';

  @override
  String get accountRecoverConflictTitle =>
      'Este aparelho tem notas não salvas';

  @override
  String accountRecoverConflictBody(Object count) {
    return 'Esta conta Google já está vinculada a outra sessão; mudar para ela vai ocultar as ${count} nota(s) deste aparelho (elas não são excluídas, apenas deixam de ser acessíveis daqui). Continuar mesmo assim?';
  }

  @override
  String get accountRecoverConflictProceed => 'Mudar mesmo assim';
  @override
  String get folderRoleRead => 'Leitura';

  @override
  String get folderRoleWrite => 'Escrita';

  @override
  String get folderRoleBoth => 'Leitura + escrita';

  @override
  String get folderInvitePending => 'Convite enviado, aguardando resposta';

  @override
  String get folderWriteOnlyTitle => 'Você só tem acesso de escrita';

  @override
  String get folderWriteOnlyHint => 'Você pode adicionar novas notas a esta pasta, mas não ver as que estão dentro.';

  @override
  String get folderChatTitle => 'Conversa';

  @override
  String get folderChatHint => 'Escreva uma mensagem…';

  @override
  String get folderChatSend => 'Enviar';

  @override
  String get folderChatEmptyTitle => 'Ainda não há mensagens';

  @override
  String get folderChatEmptyHint => 'Converse aqui com as pessoas com quem você compartilhou esta pasta.';

  @override
  String get folderInviteTitle => 'Convite de pasta';

  @override
  String folderInviteBody(Object name) {
    return 'A pasta "${name}" foi compartilhada com você.';
  }

  @override
  String get folderInviteAccepted => 'Pasta adicionada';

  @override
  String get folderInviteDeclined => 'Convite recusado';

  @override
  String friendRequestBanner(Object name) {
    return '${name} enviou um pedido de amizade';
  }

  @override
  String get friendRequestAccepted => 'Amigo adicionado';

  @override
  String get sendNoteAction => 'Enviar para um amigo';

  @override
  String get sendNoteTitle => 'Enviar a nota para um amigo';

  @override
  String get sendNoteInfo => 'Uma cópia da nota chega à caixa "Notas recebidas" da pessoa. Os anexos (imagens, documentos, áudio) não são enviados.';

  @override
  String sendNoteSent(Object name) {
    return 'Nota enviada para ${name}';
  }

  @override
  String get inboxTitle => 'Notas recebidas';

  @override
  String get inboxEmpty => 'Nenhuma nota recebida';

  @override
  String get inboxEmptyHint => 'As notas que seus amigos enviam se acumulam aqui.';

  @override
  String inboxFrom(Object name) {
    return 'Enviada por ${name}';
  }

  @override
  String get inboxAccept => 'Adicionar às minhas notas';

  @override
  String get inboxAccepted => 'Nota adicionada às suas notas';

  @override
  String get folderShelfExpand => 'Expandir as pastas';

  @override
  String get folderShelfCollapse => 'Recolher as pastas';

  @override
  String get accountSheetLocalInfo => 'Suas notas estão apenas neste aparelho. Vincule uma conta Google para fazer backup e adicionar amigos.';

  @override
  String get accountSettings => 'Configurações da conta';
}
