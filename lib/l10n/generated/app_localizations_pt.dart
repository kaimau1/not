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
  String get aiModelDocument => 'Podcasts e conversa sobre documentos';

  @override
  String get aiModelTranslate => 'Tradução';

  @override
  String get aiModelVoice => 'Notas de voz';

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
  String get appFontDefaultSuffix => 'padrão';
}
