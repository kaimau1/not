// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appName => 'Note';

  @override
  String get loginTagline => 'Le tue note, su ogni dispositivo';

  @override
  String get signInWithGoogle => 'Accedi con Google';

  @override
  String loginError(String error) {
    return 'Accesso non riuscito: $error';
  }

  @override
  String get searchHint => 'Cerca nelle note...';

  @override
  String get filterAll => 'Tutte';

  @override
  String get filterText => 'Testo';

  @override
  String get filterChecklist => 'Elenco';

  @override
  String get filterOrdered => 'Numerato';

  @override
  String get filterPinned => 'In evidenza';

  @override
  String get filterStarred => 'Preferite';

  @override
  String get star => 'Aggiungi ai preferiti';

  @override
  String get unstar => 'Rimuovi dai preferiti';

  @override
  String editedAt(String date) {
    return 'Modificata: $date';
  }

  @override
  String get sectionPinned => 'In evidenza';

  @override
  String get sectionOthers => 'Altre';

  @override
  String get emptyNotes => 'Ancora nessuna nota';

  @override
  String get emptyNotesHint => 'Tocca + per creare la tua prima nota';

  @override
  String get emptySearch => 'Nessun risultato';

  @override
  String get newTextNote => 'Nota di testo';

  @override
  String get newChecklist => 'Elenco';

  @override
  String get newOrderedList => 'Elenco numerato';

  @override
  String get noteDeleted => 'Nota eliminata';

  @override
  String notesDeletedCount(int count) {
    return '$count note eliminate';
  }

  @override
  String selectedCount(int count) {
    return '$count selezionate';
  }

  @override
  String get deleteSelected => 'Elimina selezionate';

  @override
  String get undo => 'Annulla';

  @override
  String get redo => 'Ripristina';

  @override
  String get titleHint => 'Titolo';

  @override
  String get bodyHint => 'Nota...';

  @override
  String get newItemHint => 'Nuovo elemento';

  @override
  String moreItemsCount(int count) {
    return '+$count altri elementi';
  }

  @override
  String get addAttachment => 'Aggiungi';

  @override
  String get addAttachmentMore => 'Altri tipi di allegato…';

  @override
  String get addImage => 'Aggiungi immagine';

  @override
  String get addPdf => 'Aggiungi PDF';

  @override
  String get addSlide => 'Aggiungi diapositive';

  @override
  String get pasteImage => 'Incolla immagine dagli appunti';

  @override
  String get clipboardEmpty => 'Nessuna immagine negli appunti';

  @override
  String get noNoteSelected => 'Scegli una nota a sinistra';

  @override
  String attachmentFailed(String error) {
    return 'Impossibile aggiungere l\'allegato: $error';
  }

  @override
  String get attachmentCopying => 'Copia in corso...';

  @override
  String get attachmentUploading => 'Caricamento...';

  @override
  String get attachmentUploadFailed =>
      'Caricamento non riuscito — tocca per riprovare';

  @override
  String get attachmentNotSynced =>
      'Questo file non è ancora stato sincronizzato su questo dispositivo';

  @override
  String attachmentTooLarge(int limit) {
    return 'File troppo grande (massimo $limit MB)';
  }

  @override
  String storageFull(String limit) {
    return 'Spazio esaurito ($limit). Elimina i vecchi allegati per liberare spazio.';
  }

  @override
  String get storageUsage => 'Spazio di archiviazione';

  @override
  String storageUsageValue(String used, String limit) {
    return '$used di $limit utilizzati';
  }

  @override
  String get removeAttachment => 'Rimuovi allegato';

  @override
  String get pin => 'Fissa in alto';

  @override
  String get unpin => 'Togli dall\'alto';

  @override
  String get delete => 'Elimina';

  @override
  String get color => 'Colore';

  @override
  String get aiTitle => 'IA';

  @override
  String get aiSummarize => 'Riassumi la nota';

  @override
  String get aiAnalyze => 'Analizza';

  @override
  String get aiSectionNote => 'Questa nota';

  @override
  String get aiSectionAttachments => 'Allegati';

  @override
  String get summarize => 'Riassumi';

  @override
  String get summaryDetailTitle => 'Tipo di riassunto';

  @override
  String get summaryShort => 'Riassunto breve';

  @override
  String get summaryShortInfo => 'Poche frasi di sintesi più i punti chiave';

  @override
  String get summaryDetailed => 'Riassunto dettagliato';

  @override
  String get summaryDetailedInfo =>
      'Abbastanza completo da non dover aprire l\'originale';

  @override
  String get listen => 'Ascolta';

  @override
  String get ask => 'Fai una domanda';

  @override
  String get extractText => 'Estrai il testo';

  @override
  String get transcribe => 'Trascrivi';

  @override
  String get listenToNote => 'Leggi ad alta voce';

  @override
  String get aiNoApiKey =>
      'Inserisci prima la tua chiave API Gemini nelle impostazioni';

  @override
  String aiError(String error) {
    return 'Richiesta IA non riuscita: $error';
  }

  @override
  String get aiSummaryTitle => 'Riassunto IA';

  @override
  String get aiThinking => 'Sto pensando...';

  @override
  String get copy => 'Copia';

  @override
  String get copied => 'Copiato';

  @override
  String get settingsSearchHint =>
      'Cerca nelle impostazioni — “briefing”, “microfono”';

  @override
  String settingsSearchEmpty(String query) {
    return 'Nessuna impostazione corrisponde a «$query»';
  }

  @override
  String get settings => 'Impostazioni';

  @override
  String get settingsAppearance => 'Aspetto';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Chiaro';

  @override
  String get themeDark => 'Scuro';

  @override
  String get settingsAi => 'IA';

  @override
  String get geminiApiKey => 'Chiave API Gemini';

  @override
  String get geminiApiKeyHint => 'Incolla la chiave che inizia con AIza...';

  @override
  String get geminiApiKeyInfo =>
      'La chiave è facoltativa: senza, le richieste IA passano dal servizio integrato dell\'app (una quota gratuita giornaliera, più alta con Premium). Per un uso illimitato con la tua chiave, ottienine una gratis su aistudio.google.com; la chiave resta solo su questo dispositivo, in un archivio sicuro.';

  @override
  String aiBuiltInPremium(int count) {
    return 'IA integrata: Premium — $count punti rimasti oggi';
  }

  @override
  String aiBuiltInRemaining(int count) {
    return 'IA integrata: $count punti gratuiti rimasti oggi';
  }

  @override
  String get aiBuiltInByok => 'Con la tua chiave — illimitato';

  @override
  String get aiReport => 'Segnala questa risposta';

  @override
  String get aiReportThanks => 'Segnalazione ricevuta, grazie';

  @override
  String get privacyPolicyTitle => 'Informativa sulla privacy';

  @override
  String get lockNote => 'Blocca';

  @override
  String get unlockNote => 'Sblocca';

  @override
  String get lockedNote => 'Nota bloccata';

  @override
  String get unlockAuthReason =>
      'Verifica la tua identità per aprire la nota bloccata';

  @override
  String get exportBackup => 'Esporta backup (JSON)';

  @override
  String get expandListItems => 'Mostra le righe per intero';

  @override
  String get expandListItemsInfo =>
      'Gli elementi lunghi vanno a capo su più righe e restano interamente visibili. Se disattivato, una riga resta su un solo rigo e si espande al tocco.';

  @override
  String get quickCaptureRowSetting => 'Barra nota rapida';

  @override
  String get quickCaptureRowInfo =>
      'Mostra un campo \"Nuova nota...\" in alto. Se disattivato, usa il pulsante +.';

  @override
  String get emptyTrash => 'Svuota cestino';

  @override
  String emptyTrashConfirm(int count) {
    return '$count note verranno eliminate definitivamente. L\'operazione non può essere annullata. Confermi?';
  }

  @override
  String get trashEmptied => 'Cestino svuotato';

  @override
  String get validateAndSave => 'Verifica e salva';

  @override
  String get clear => 'Cancella';

  @override
  String get aiDiagnostics => 'Diagnostica IA';

  @override
  String get aiDiagnosticsEmpty => 'Nessun errore registrato';

  @override
  String aiDiagnosticsCount(int count) {
    return 'Ultimi $count errori registrati';
  }

  @override
  String get apiKeyValid => 'Chiave API verificata e salvata';

  @override
  String get apiKeyInvalid => 'La chiave API non è valida';

  @override
  String get apiKeySavedBadge => 'Salvata';

  @override
  String get removeApiKey => 'Elimina chiave';

  @override
  String get refresh => 'Aggiorna';

  @override
  String get account => 'Account';

  @override
  String get signOut => 'Esci';

  @override
  String get signOutConfirm => 'Vuoi davvero uscire?';

  @override
  String get signOutAnonymousWarning =>
      'Stai usando un account locale: uscendo, questo account e TUTTE le note diventeranno inaccessibili per sempre — senza backup non si possono recuperare. Collega prima un account Google. Uscire comunque?';

  @override
  String get deleteAccount => 'Elimina il mio account e i miei dati';

  @override
  String get deleteAccountWarning =>
      'L\'operazione non può essere annullata: tutte le tue note, gli allegati e il tuo account verranno eliminati definitivamente. Vuoi continuare?';

  @override
  String get deleteAccountConfirm => 'Elimina definitivamente';

  @override
  String get licensesTitle => 'Licenze open source';

  @override
  String get generating => 'Generazione...';

  @override
  String get retry => 'Riprova';

  @override
  String get cancel => 'Annulla';

  @override
  String get close => 'Chiudi';

  @override
  String get ok => 'OK';

  @override
  String get syncPending => 'In attesa di sincronizzazione';

  @override
  String get synced => 'Sincronizzata';

  @override
  String genericError(String error) {
    return 'Qualcosa è andato storto: $error';
  }

  @override
  String get addTag => 'Etichetta';

  @override
  String get tagHint => 'es. lavoro, casa, scuola';

  @override
  String get addReminder => 'Ricordamelo';

  @override
  String get share => 'Condividi';

  @override
  String get archive => 'Archivia';

  @override
  String get unarchive => 'Togli dall\'archivio';

  @override
  String get archiveTitle => 'Archivio';

  @override
  String get archiveEmpty => 'Nessuna nota nell\'archivio';

  @override
  String get trashTitle => 'Cestino';

  @override
  String get trashEmpty => 'Il cestino è vuoto';

  @override
  String get trashInfo =>
      'Le note eliminate restano qui; puoi ripristinarle o eliminarle definitivamente.';

  @override
  String get restore => 'Ripristina';

  @override
  String get deleteForever => 'Elimina definitivamente';

  @override
  String get deleteForeverConfirm =>
      'Questa nota verrà eliminata definitivamente. Confermi?';

  @override
  String assistantDeleteConfirm(String title) {
    return 'L\'assistente vuole spostare la nota "${title}" nel cestino. Confermi?';
  }

  @override
  String get recordAudio => 'Registrazione vocale';

  @override
  String get recording => 'Registrazione...';

  @override
  String get stopAndSave => 'Termina e aggiungi';

  @override
  String get micPermissionDenied =>
      'L\'autorizzazione al microfono è stata negata';

  @override
  String get speechRecognitionFailed =>
      'Il riconoscimento vocale non ha funzionato. Verifica che l\'autorizzazione al microfono sia concessa e che l\'app Google sia aggiornata.';

  @override
  String get addDrawing => 'Aggiungi disegno';

  @override
  String get drawingTitle => 'Disegno';

  @override
  String get addToNote => 'Aggiungi alla nota';

  @override
  String get chatTitle => 'Assistente note';

  @override
  String get chatHint =>
      'Chiedi qualcosa sulle tue note: «qual era quella ricetta che ho scritto la settimana scorsa?», «cosa manca nella lista della spesa?»';

  @override
  String get chatInputHint => 'Scrivi una domanda...';

  @override
  String get fontSize => 'Dimensione del testo';

  @override
  String get fontSizePreview => 'Le tue note appariranno così';

  @override
  String get darkSchedule => 'Programmazione tema scuro';

  @override
  String get darkScheduleInfo =>
      'Passa al tema scuro tra gli orari che imposti';

  @override
  String get aiTranslate => 'Traduci';

  @override
  String get voiceCommand => 'Comando vocale';

  @override
  String get semanticSearchToggle => 'Ricerca semantica con l\'IA';

  @override
  String get semanticSearchHint =>
      'Cerca per significato: «spese dell\'auto»...';

  @override
  String get briefingTitle => 'Riepilogo del giorno';

  @override
  String get briefingLoading => 'Preparazione del riepilogo...';

  @override
  String get briefingEmpty => 'Niente per oggi';

  @override
  String get briefingSetting => 'Notifica del riepilogo giornaliero';

  @override
  String get briefingSettingInfo =>
      'Ricevi ogni mattina una notifica con il riepilogo della giornata, all\'orario che preferisci';

  @override
  String get autoTagSetting => 'Etichetta automaticamente';

  @override
  String get autoTagSettingInfo =>
      'Quando una nota viene chiusa senza etichette, l\'IA ne aggiunge una adatta';

  @override
  String get suggestTags => 'Suggerisci etichette';

  @override
  String get aiFixNote => 'Sistema la nota';

  @override
  String get fixLevelTitle => 'Quanto va sistemata?';

  @override
  String get fixSimple => 'Leggero';

  @override
  String get fixSimpleInfo => 'Solo ortografia ed errori di battitura';

  @override
  String get fixBalanced => 'Equilibrato';

  @override
  String get fixBalancedInfo =>
      'Anche la struttura delle frasi, per una scrittura più pulita';

  @override
  String get fixDetailed => 'Approfondito';

  @override
  String get fixDetailedInfo => 'Riscrive l\'intero testo da cima a fondo';

  @override
  String get existingTagsLabel => 'Etichette precedenti';

  @override
  String get aiSkipCheckedSetting =>
      'Escludi gli elementi spuntati dalle modifiche IA';

  @override
  String get aiSkipCheckedInfo =>
      'Quando l\'IA sistema o traduce un elenco, gli elementi completati (spuntati) restano esattamente come sono; vengono modificati solo quelli non spuntati.';

  @override
  String get noteUpdatedUndo => 'Nota aggiornata';

  @override
  String get aiImprove => 'Migliora la nota';

  @override
  String get improveFormal => 'Rendila più formale';

  @override
  String get improveShorten => 'Accorcia';

  @override
  String get improveBullets => 'Trasforma in elenco puntato';

  @override
  String get improveNumbered => 'Trasforma in elenco numerato';

  @override
  String get replaceNote => 'Sostituisci la nota';

  @override
  String get openAsNewNote => 'Come nuova nota';

  @override
  String get pdfChatHint =>
      'Chiedi qualcosa su questo PDF: «riassumilo», «c\'è una clausola penale?», «qual è la scadenza?»';

  @override
  String get pdfChatInputHint => 'Scrivi una domanda sul PDF...';

  @override
  String get voiceCaptureHint =>
      'Parla: «comprare latte e pane» oppure «riunione domani alle 9, ricordamelo» — l\'IA scrive la tua nota quando hai finito.';

  @override
  String get voiceFinish => 'Termina';

  @override
  String get voiceProcessing => 'Elaborazione di quanto hai detto...';

  @override
  String get voiceNothingHeard => 'Nessun parlato rilevato nella registrazione';

  @override
  String get voiceNoteSaved => 'La tua nota vocale è stata salvata';

  @override
  String get openNote => 'Apri nota';

  @override
  String get remindersTitle => 'Promemoria';

  @override
  String get remindersEmpty => 'Nessun promemoria';

  @override
  String get remindersEmptyHint =>
      'Aggiungi un promemoria a una nota, oppure crea una nuova nota con promemoria dal pulsante +';

  @override
  String get remindersUpcoming => 'In arrivo';

  @override
  String get remindersPast => 'Passati';

  @override
  String get reminderInPast =>
      'L\'orario selezionato è passato — scegli un orario futuro.';

  @override
  String get newReminder => 'Nuovo promemoria';

  @override
  String get remindersUntitled => 'Nota senza titolo';

  @override
  String get remindersEdit => 'Cambia l\'orario';

  @override
  String get remindersRemove => 'Rimuovi promemoria';

  @override
  String get aiModelChat => 'Riassunti, titoli, etichette e chat';

  @override
  String get aiModelDocument => 'Chat documenti e riassunto PDF';

  @override
  String get aiModelTranslate => 'Traduzione';

  @override
  String get aiModelVoice => 'Assistente note vocali';

  @override
  String get aiModelAuto => 'Automatico (consigliato)';

  @override
  String get aiModelsInfo =>
      'Puoi scegliere un modello diverso per ogni compito: i testi brevi vanno bene con un modello veloce, i documenti lunghi richiedono un modello più capace. Se il modello scelto esaurisce la quota o viene ritirato, viene provato automaticamente il successivo.';

  @override
  String get clearNote => 'Svuota';

  @override
  String get clearNoteConfirm =>
      'Il contenuto della nota (testo ed elementi dell\'elenco) verrà eliminato. Confermi?';

  @override
  String get themePaper => 'Carta';

  @override
  String get calculatorTitle => 'Calcolatrice';

  @override
  String get calcExpressionHint => 'es. 12,5×3+40';

  @override
  String get calcInvalid => 'Espressione non valida';

  @override
  String get liveDictation => 'Detta';

  @override
  String get dictationListening =>
      'In ascolto... il testo compare mentre parli';

  @override
  String get dictationNoKeyInfo =>
      'La dettatura in tempo reale non è disponibile su questo dispositivo; la registrazione verrà trascritta tutta insieme quando ti fermi.';

  @override
  String get dictationHoldHint =>
      'Tieni premuto il microfono e parla; il testo viene scritto quando lasci';

  @override
  String itemsSelected(int count) {
    return '$count elementi selezionati';
  }

  @override
  String get noteChatTitle => 'Chatta con questa nota';

  @override
  String get noteChatHint => 'Chiedi qualcosa su questa nota';

  @override
  String get noteChatIntro =>
      'Vengono letti il contenuto della nota e i suoi allegati (PDF/immagine), e la tua domanda trova risposta a partire da questi.';

  @override
  String get dictationProcessing => 'Trascrizione...';

  @override
  String get aiDailyManualInfo =>
      'Con il piano gratuito non viene generato automaticamente, quindi non consuma la tua quota giornaliera. Puoi generarlo una volta al giorno con il pulsante qui sotto.';

  @override
  String get aiGenerate => 'Genera';

  @override
  String get aiGeneratedTodayInfo =>
      'È stato generato oggi. Con il piano gratuito si rinnova una volta al giorno; potrai generarlo di nuovo domani.';

  @override
  String get voiceAssistantTitle => 'Assistente per note vocali';

  @override
  String get voiceListening => 'In ascolto...';

  @override
  String get voiceHoldHint =>
      'Tieni premuto e parla; la nota viene creata quando lasci';

  @override
  String get voiceTapHint => 'Tocca e parla; tocca di nuovo per terminare';

  @override
  String get voiceTooShort => 'La registrazione era troppo breve, riprova';

  @override
  String get voiceModeSetting => 'Come funziona';

  @override
  String get voiceModeHold => 'Tieni premuto per parlare';

  @override
  String get voiceModeTap => 'Tocca per iniziare / tocca per fermare';

  @override
  String get voiceModeInfo =>
      'Tieni premuto per parlare: ascolta finché tieni premuto il pulsante e crea la nota quando lasci. Tocca per iniziare: un tocco avvia la registrazione, un secondo tocco la termina.';

  @override
  String get voiceHeardLive => 'Parlato rilevato';

  @override
  String get voiceCaptureReady => 'Pronto a parlare';

  @override
  String get voiceCaptureEditHint => 'Tocca il testo per modificarlo';

  @override
  String voiceCapturePunctuation(String language) {
    return '$language · punteggiatura automatica';
  }

  @override
  String get voiceCaptureAddToNote => 'Aggiungi alla nota';

  @override
  String get voiceCaptureCreateNote => 'Crea nuova nota';

  @override
  String get voiceCaptureAiNote => 'Nota IA';

  @override
  String get voiceCapturePlainNote => 'Nota semplice';

  @override
  String get voiceCloseTitle => 'La tua dettatura è ancora qui';

  @override
  String get voiceCloseKeepTalking => 'Continua a parlare';

  @override
  String get voiceCaptureRestart => 'Registra di nuovo';

  @override
  String get voiceChipSummarizeAdd => 'Aggiungi come riassunto';

  @override
  String get voiceChipSummarizeSave => 'Salva come riassunto';

  @override
  String get voiceChipToItems => 'Dividi in elementi';

  @override
  String get voiceChipAsList => 'Crea checklist';

  @override
  String get voiceChipFix => 'Sistema';

  @override
  String get voiceChipCompose => 'Lascia che l\'assistente lo scriva';

  @override
  String get editorToolList => 'Elenco';

  @override
  String get permissionsTitle => 'Autorizzazioni';

  @override
  String get permMic => 'Microfono';

  @override
  String get permMicInfo => 'Necessario per le note vocali e la dettatura';

  @override
  String get permNotifications => 'Notifiche';

  @override
  String get permNotificationsInfo =>
      'Necessarie per i promemoria e il riepilogo giornaliero';

  @override
  String get permBattery => 'Ottimizzazione della batteria';

  @override
  String get permBatteryInfo =>
      'Esenta l\'app dalle restrizioni della batteria perché i promemoria arrivino in orario';

  @override
  String get showTagChips => 'Mostra i chip delle etichette';

  @override
  String get showFolderChips => 'Mostra i chip delle cartelle';

  @override
  String videoTooBigForAi(int mb) {
    return 'Il video è troppo grande per essere inviato all\'IA ($mb MB). Registrane uno più breve.';
  }

  @override
  String get permCamera => 'Fotocamera';

  @override
  String get permCameraInfo =>
      'Necessaria per le note video e per scattare foto';

  @override
  String get permOnboardTitle => 'Prima di iniziare';

  @override
  String get permOnboardInfo =>
      'Note richiede queste autorizzazioni solo quando usi la funzione corrispondente. Puoi concederle ora qui sotto, oppure modificarle in seguito in Impostazioni > Autorizzazioni.';

  @override
  String get permOnboardGrantAll => 'Concedi le autorizzazioni';

  @override
  String get permOnboardSkip => 'Non ora';

  @override
  String get newVideoNote => 'Nota video';

  @override
  String get videoLocalOnly =>
      'Questo video è salvato solo su questo dispositivo (non caricato sul cloud)';

  @override
  String get videoToNote => 'Crea una nota dal video';

  @override
  String get videoToNoteRunning => 'Analisi del video…';

  @override
  String get permGranted => 'Concessa';

  @override
  String get permGrant => 'Concedi';

  @override
  String get permOpenSettings => 'Apri le impostazioni';

  @override
  String get newHandwriting => 'Scrittura a mano';

  @override
  String get newVoiceCapture => 'Nota vocale';

  @override
  String get suggestTitle => 'Suggerisci un titolo';

  @override
  String get noteMetaMenu => 'Etichetta · Titolo · Promemoria';

  @override
  String get folder => 'Cartella';

  @override
  String get noFolder => 'Nessuna cartella';

  @override
  String get newFolder => 'Nuova cartella';

  @override
  String get editFolder => 'Modifica cartella';

  @override
  String get deleteFolder => 'Elimina cartella';

  @override
  String deleteFolderConfirm(String name) {
    return 'La cartella «$name» verrà eliminata. Le note al suo interno non vengono eliminate — semplicemente non avranno più una cartella.';
  }

  @override
  String get folderNameHint => 'Nome della cartella';

  @override
  String get folderIcon => 'Icona';

  @override
  String get editFilters => 'Modifica i filtri';

  @override
  String get editFiltersInfo =>
      'Scegli quali filtri compaiono nella schermata principale. Nasconderne alcuni mantiene la pagina ordinata.';

  @override
  String get select => 'Seleziona';

  @override
  String get noteArchived => 'Nota archiviata';

  @override
  String deleteChecked(int count) {
    return 'Elimina gli spuntati ($count)';
  }

  @override
  String get removeItem => 'Elimina elemento';

  @override
  String get copyWholeNote => 'Copia tutta la nota';

  @override
  String get allCopied => 'L\'intera nota è stata copiata negli appunti';

  @override
  String get speechPlay => 'Leggi ad alta voce';

  @override
  String get speechPause => 'Pausa';

  @override
  String get speechResume => 'Riprendi';

  @override
  String get speechStop => 'Ferma';

  @override
  String get speechRate => 'Velocità di lettura';

  @override
  String get speechSystemDefault => 'Predefinito di sistema';

  @override
  String get speechNoVoices =>
      'Su questo dispositivo non è installata alcuna voce';

  @override
  String speechVoiceLanguage(String language) {
    return 'Voce $language';
  }

  @override
  String get speechVoiceAutoInfo =>
      'Le altre lingue vengono lette automaticamente con una voce maschile';

  @override
  String get listening => 'In ascolto...';

  @override
  String get listenPlay => 'Ascolta';

  @override
  String get listenReadingPdf => 'Lettura del documento...';

  @override
  String get listenConvertWithAi => 'Converti con l\'IA';

  @override
  String get listenMakePodcast => 'Podcast completo';

  @override
  String get listenMakePodcastSummary => 'Podcast riassuntivo';

  @override
  String get listenOriginalText => 'Testo originale';

  @override
  String get listenPodcastReady => 'La narrazione del podcast è pronta';

  @override
  String get listenPodcastCached =>
      'Generato in precedenza — nessun token speso';

  @override
  String get listenRegenerate => 'Genera di nuovo';

  @override
  String get listenNoText =>
      'Da questo documento non è emerso testo leggibile. Un PDF scansionato non ha uno strato di testo, e una presentazione può contenere solo immagini.';

  @override
  String get readDocument => 'Leggi un documento (Word, PDF, diapositive)';

  @override
  String get readDocUnsupported => 'Questo tipo di file non può essere letto.';

  @override
  String get exportPdf => 'Esporta in PDF';

  @override
  String get pdfTitleField => 'Titolo';

  @override
  String get pdfContentField => 'Contenuto';

  @override
  String get pdfMarkupHint =>
      'I segni a inizio riga diventano formattazione: [x] e [ ] per le caselle, 1. per un elenco numerato, - per un punto elenco.';

  @override
  String get pdfIncludeDate => 'Includi la data';

  @override
  String get exportIncludeImages => 'Includi le immagini';

  @override
  String get exportWord => 'Condividi come Word (.docx)';

  @override
  String get pdfPreview => 'Anteprima';

  @override
  String get largeAttachmentTitle => 'File di grandi dimensioni';

  @override
  String largeAttachmentBody(String size) {
    return 'Questo file è di $size MB. I PDF non possono essere compressi; verrà caricato così com\'è e occuperà spazio di archiviazione. Continuare?';
  }

  @override
  String get speechRateForeign => 'Velocità in lingua straniera';

  @override
  String notesArchivedCount(int count) {
    return '$count note archiviate';
  }

  @override
  String get backgroundColor => 'Colore di sfondo';

  @override
  String get backgroundColorInfo => 'Il colore di sfondo della nota';

  @override
  String get frameColor => 'Cornice';

  @override
  String get frameColorInfo =>
      'Disegna una cornice attorno alla nota nel colore che scegli';

  @override
  String get sortBy => 'Ordina';

  @override
  String get reorderNotes => 'Riordina le note';

  @override
  String get reorderModeActive => 'Trascina le schede per riordinarle';

  @override
  String get reorderDone => 'Fatto';

  @override
  String get sortManual => 'Manuale (ordine trascinato)';

  @override
  String get sortUpdated => 'Modificate di recente';

  @override
  String get sortCreated => 'Data di creazione';

  @override
  String get sortTitle => 'Per titolo (A–Z)';

  @override
  String get foldersSection => 'Cartelle';

  @override
  String get tagsSection => 'Etichette';

  @override
  String get expandFilters => 'Espandi i filtri';

  @override
  String get collapseFilters => 'Comprimi i filtri';

  @override
  String get settingsLanguage => 'Lingua';

  @override
  String get languageSystem => 'Lingua di sistema';

  @override
  String get settingsSpeech => 'Lettura ad alta voce';

  @override
  String get aiAdvanced => 'Avanzate: modello e chiave API';

  @override
  String get aiAdvancedInfo =>
      'Scelta del modello e la tua chiave Gemini. Alla maggior parte delle persone non serve.';

  @override
  String get openBriefing => 'Apri il riepilogo';

  @override
  String get syncTitle => 'Sincronizzazione';

  @override
  String get syncLimitTitle => 'Limite di caricamento automatico';

  @override
  String get syncLimitInfo =>
      'Gli allegati più grandi di questo limite restano sul dispositivo e non vengono caricati. Il testo delle note viene sempre sincronizzato.';

  @override
  String get syncLimitUnlimited => 'Nessun limite';

  @override
  String get backupTitle => 'Backup';

  @override
  String get importBackup => 'Ripristina da backup (JSON)';

  @override
  String importBackupDone(int count) {
    return '$count note ripristinate';
  }

  @override
  String get importBackupInvalid => 'File di backup non valido';

  @override
  String get aiHubTitle => 'IA';

  @override
  String get aiSummarizeInfo => 'Produce un breve riassunto';

  @override
  String get aiAnalyzeInfo => 'Elenca i punti chiave e le cose da fare';

  @override
  String get aiImproveInfo => 'Cambia il tono: formale, più breve o elenco';

  @override
  String get aiTranslateInfo => 'Traduce la nota nella lingua scelta';

  @override
  String get aiFixNoteInfo => 'Corregge ortografia e punteggiatura';

  @override
  String get moveToFolder => 'Sposta in una cartella';

  @override
  String get voiceAssistantBadge => 'Assistente';

  @override
  String get assistantGenericError =>
      'Qualcosa è andato storto — puoi riprovare?';

  @override
  String get quickAddTooltip => 'Nuova nota — scegli un tipo';

  @override
  String get autoTitleSetting => 'Suggerisci un titolo alla chiusura';

  @override
  String get autoTitleSettingInfo =>
      'Quando esci dall\'editor, una nota rimasta senza titolo ne riceve uno breve, scritto a partire dal suo contenuto.';

  @override
  String get hubChatInfo => 'Risposte tratte dalle tue note';

  @override
  String get hubBriefingInfo =>
      'La tua giornata a colpo d\'occhio: promemoria e note recenti';

  @override
  String get hubReadInfo => 'Ascolta un documento PDF o Word';

  @override
  String get annotate => 'Annota';

  @override
  String get annotateDone => 'Termina l\'annotazione';

  @override
  String get newPdfNote => 'Aggiungi un PDF e prendi appunti';

  @override
  String get imageNotePreparing =>
      'Composizione delle immagini in un documento…';

  @override
  String get newImageNote => 'Aggiungi immagine e prendi appunti';

  @override
  String get pdfPageNoteHint => 'Nota di questa pagina…';

  @override
  String pdfPage(int page) {
    return 'Pagina ${page}';
  }

  @override
  String pdfPageOf(int page, int total) {
    return 'Pagina ${page} / ${total}';
  }

  @override
  String get pdfPreviousPage => 'Pagina precedente';

  @override
  String get pdfNextPage => 'Pagina successiva';

  @override
  String get pdfFullScreen => 'Apri a schermo intero';

  @override
  String get pdfNoDocument => 'Questa nota non ha ancora un PDF';

  @override
  String get pdfChooseDocument => 'Scegli un PDF';

  @override
  String get newSlidesNote => 'Aggiungi diapositive e prendi appunti';

  @override
  String get slidesNoDocument => 'Questa nota non ha ancora una presentazione';

  @override
  String get slidesChooseDocument => 'Scegli una presentazione';

  @override
  String get pdfEditPages => 'Modifica le pagine';

  @override
  String get pdfDeletePages => 'Elimina le pagine selezionate';

  @override
  String get pdfAddBlankPage => 'Aggiungi pagina vuota';

  @override
  String get pdfRotatePages => 'Ruota';

  @override
  String get pdfBurnInk => 'Incidi la scrittura a mano nel documento';

  @override
  String get pdfApplyChanges => 'Applica le modifiche';

  @override
  String get pdfCannotDeleteAllPages => 'Non puoi eliminare tutte le pagine';

  @override
  String get pdfPagesHint =>
      'Tocca una pagina per selezionarla. Le note di pagina seguono la loro pagina; la nota di una pagina eliminata viene nascosta ma conservata nei tuoi dati.';

  @override
  String pdfEditFailed(String error) {
    return 'Impossibile modificare il PDF: ${error}';
  }

  @override
  String get pdfInkBurned => 'Scrittura a mano incisa nel documento';

  @override
  String get pdfAllPageNotes => 'Tutte le note di pagina';

  @override
  String get pdfNoPageNotes =>
      'Ancora nessuna nota di pagina. Vai su una pagina e scrivi nel campo qui sotto.';

  @override
  String get crop => 'Ritaglia';

  @override
  String get cropApply => 'Applica il ritaglio';

  @override
  String get cropReset => 'Reimposta la selezione';

  @override
  String get cropHint =>
      'Trascina gli angoli per scegliere un\'area. Il ritaglio non può essere annullato.';

  @override
  String get cropFailed => 'Impossibile ritagliare l\'immagine.';

  @override
  String get penBallpoint => 'Penna a sfera';

  @override
  String get penMarker => 'Pennarello';

  @override
  String get penHighlighter => 'Evidenziatore';

  @override
  String get eraser => 'Gomma';

  @override
  String get inkArrow => 'Freccia';

  @override
  String get clearInk => 'Cancella le annotazioni';

  @override
  String get inkTwoFingerHint =>
      'Un dito disegna · due dita spostano e ingrandiscono';

  @override
  String get slideOpenFailed => 'Non è stato possibile aprire la presentazione';

  @override
  String get newPhotoNote => 'Nota fotografica';

  @override
  String get newScanNote => 'Scansiona un documento';

  @override
  String get scanDocument => 'Scansiona il documento';

  @override
  String get scanDocumentSubtitle =>
      'Individua i bordi, raddrizza la pagina e la aggiunge';

  @override
  String get scanUnsupported =>
      'La scansione di documenti non è supportata su questo dispositivo';

  @override
  String scanFailed(String error) {
    return 'Impossibile scansionare il documento: $error';
  }

  @override
  String scanPagesAdded(int count) {
    return '$count pagina/e aggiunta/e alla nota';
  }

  @override
  String get scanTextTitle => 'Riconoscere anche il testo?';

  @override
  String get scanTextBody =>
      'Il testo delle pagine viene riconosciuto e scritto nella nota. L\'immagine resta com\'è. Richiede qualche secondo per pagina.';

  @override
  String get scanImageOnly => 'Solo immagine';

  @override
  String get scanRecognizeText => 'Riconosci il testo';

  @override
  String get scanRecognizing => 'Riconoscimento del testo…';

  @override
  String get takePhoto => 'Scatta una foto';

  @override
  String get qrScanTitle => 'Scansiona un codice QR';

  @override
  String get qrScanSubtitle => 'Leggilo con la fotocamera o da una foto';

  @override
  String get qrScanHint => 'Allinea il codice all\'interno della cornice';

  @override
  String get qrFromPhoto => 'Leggi da una foto';

  @override
  String get qrNotFound => 'Nessun codice trovato in questa immagine';

  @override
  String get qrLinkFound => 'Questo codice è un link';

  @override
  String get qrOpenLink => 'Vai al link';

  @override
  String get qrSaveToNote => 'Salva in una nota';

  @override
  String get openLink => 'Apri il link';

  @override
  String get linkOpenFailed => 'Non è stato possibile aprire il link';

  @override
  String qrScanFailed(String error) {
    return 'Impossibile leggere il codice: $error';
  }

  @override
  String get qrTorch => 'Torcia';

  @override
  String attachmentsCount(int count) {
    return 'Allegati ($count)';
  }

  @override
  String get hideAttachments => 'Nascondi';

  @override
  String get showAttachments => 'Mostra';

  @override
  String get videoBack10 => 'Indietro di 10 s';

  @override
  String get videoForward10 => 'Avanti di 10 s';

  @override
  String get selectAllItems => 'Seleziona tutto';

  @override
  String get showAllChips => 'Mostra tutto';

  @override
  String get hideAllChips => 'Nascondi tutto';

  @override
  String get chipPickInfo =>
      'Quali chip di cartella ed etichetta devono comparire nella schermata principale?';

  @override
  String get hiddenFolder => 'Cartella nascosta';

  @override
  String get hiddenFolderInfo =>
      'Una cartella nascosta e le note al suo interno non compaiono nella schermata principale. Per mostrarle, scegli «Cartelle nascoste» dal menu ⋮ e verifica la tua identità.';

  @override
  String get hiddenFoldersMenu => 'Cartelle nascoste';

  @override
  String get hiddenFolderAuthReason =>
      'Verifica la tua identità per mostrare le cartelle nascoste';

  @override
  String get hiddenFoldersShown => 'Le cartelle nascoste sono visibili';

  @override
  String get hiddenFoldersHiddenAgain =>
      'Le cartelle nascoste sono di nuovo celate';

  @override
  String get makeFolderHidden => 'Nascondi';

  @override
  String get makeFolderVisible => 'Mostra';

  @override
  String gridColumnsCount(int count) {
    return '$count colonne';
  }

  @override
  String get addImageOnPageSubtitle =>
      'Sta nella pagina, il testo le scorre attorno';

  @override
  String get addImageAsFile => 'Aggiungi l\'immagine come file';

  @override
  String get addImageAsFileSubtitle =>
      'Resta fuori dalla pagina, nella striscia degli allegati';

  @override
  String get moveImageToAttachments => 'Sposta negli allegati';

  @override
  String get moveImageToPage => 'Colloca nella pagina';

  @override
  String get attachmentCopied => 'Allegato copiato';

  @override
  String get pasteAttachment => 'Incolla l\'allegato copiato';

  @override
  String get fullscreen => 'Schermo intero';

  @override
  String get more => 'Altro';

  @override
  String get undone => 'Annullato';

  @override
  String get filterOthers => 'Altre';

  @override
  String get chatSuggestion1 => 'Cosa manca nella mia lista della spesa?';

  @override
  String get chatSuggestion2 =>
      'Riassumi le note di lavoro di questa settimana';

  @override
  String get chatSuggestion3 => 'Ho un promemoria per domani?';

  @override
  String get aiPointsToday => 'Punti di oggi';

  @override
  String aiPointsOf(int used, int total) {
    return '$used / $total';
  }

  @override
  String get aiPointsRenew => 'si rinnova a mezzanotte';

  @override
  String get aiChatWithNotes => 'Assistente note';

  @override
  String get aiChatInputHint => 'Chiedi qualcosa sulle tue note…';

  @override
  String get aiChatLooking => 'sto esaminando le tue note…';

  @override
  String get aiChatFullScreen => 'Schermo intero';

  @override
  String get aiOnYourNotes => 'SULLE TUE NOTE';

  @override
  String get aiTaskDuplicates => 'Pulisci i duplicati';

  @override
  String aiTaskDuplicatesInfo(int count) {
    return '$count note duplicate';
  }

  @override
  String get duplicatesTitle => 'Note duplicate';

  @override
  String get duplicatesHint =>
      'La nota più vecchia di ogni gruppo viene conservata, le altre vanno nel cestino.';

  @override
  String get duplicatesKeepBadge => 'conservata';

  @override
  String get duplicatesDeleteAll => 'Sposta i duplicati nel cestino';

  @override
  String duplicatesDone(int count) {
    return '$count duplicati spostati nel cestino';
  }

  @override
  String get aiRecentActions => 'AZIONI RECENTI';

  @override
  String get aiHistoryClear => 'Cancella';

  @override
  String get aiHistoryQuestion => 'Domanda';

  @override
  String get aiHistoryNoteAction => 'Azione sulla nota';

  @override
  String get aiHistoryVoiceNote => 'Nota vocale';

  @override
  String get aiRecentOps => 'RECENTI';

  @override
  String get aiTaskWeekSummary => 'Riassumi la settimana';

  @override
  String get aiTaskWeekSummaryInfo => 'Un riassunto degli ultimi 7 giorni';

  @override
  String get aiTaskTagUntagged => 'Aggiungi tag ai contenuti senza';

  @override
  String aiTaskTagUntaggedInfo(int count) {
    return '$count note in attesa di tag';
  }

  @override
  String get aiTaskSuggestTitles => 'Suggerisci titoli';

  @override
  String aiTaskSuggestTitlesInfo(int count) {
    return '$count note senza titolo';
  }

  @override
  String get sectionPinnedShort => 'PINNATI';

  @override
  String get sectionToday => 'OGGI';

  @override
  String get sectionThisWeek => 'QUESTA SETTIMANA';

  @override
  String get sectionEarlier => 'IN PRECEDENZA';

  @override
  String sectionNoteCount(int count) {
    return '$count note';
  }

  @override
  String get emptySearchSemanticHint => 'Prova la scheda Significato';

  @override
  String get quickCaptureHint => 'Nuova nota…';

  @override
  String get quickCaptureSave => 'Salva';

  @override
  String get quickAddWrite => 'SCRIVI';

  @override
  String get quickAddCapture => 'CATTURA — CREA UNA NOTA DAL CONTENUTO';

  @override
  String get viewToggle => 'Visualizza';

  @override
  String get searchModeText => 'Testo';

  @override
  String get searchModeMeaning => 'Significato';

  @override
  String get filterReminded => 'Con promemoria';

  @override
  String get filterLocked => 'Bloccato';

  @override
  String get sortColor => 'Colore';

  @override
  String get sortActive => 'Più lavorate';

  @override
  String get voicePreview => 'Prova la voce';

  @override
  String get voicePreviewCached =>
      'Il campione viene generato una volta, poi riprodotto dalla memoria';

  @override
  String get reorderHint => 'Tieni premuta una scheda e trascinala dove vuoi';

  @override
  String get filterSheetTitle => 'Filtra';

  @override
  String get filterReset => 'Reimposta';

  @override
  String get filterSectionStatus => 'STATO';

  @override
  String get filterSectionFolder => 'CARTELLA';

  @override
  String get filterSectionTag => 'TAG';

  @override
  String get filterSectionSort => 'ORDINA';

  @override
  String get filterFavoriteHint =>
      'Tocca una stella per tenere l\'opzione nella schermata principale';

  @override
  String get filterSheetSortHint =>
      'I gruppi di date (OGGI, QUESTA SETTIMANA...) vengono mostrati solo quando si ordina per ultima modifica.';

  @override
  String get formatTitle => 'Formattazione';

  @override
  String get formatBold => 'Grassetto';

  @override
  String get formatItalic => 'Corsivo';

  @override
  String get formatUnderline => 'Sottolineato';

  @override
  String get formatTextColor => 'Colore del testo';

  @override
  String get formatHighlight => 'Evidenziazione';

  @override
  String get formatInfo =>
      'La formattazione viaggia dentro il testo come marcatori (per esempio **grassetto**); i marcatori restano nascosti nelle esportazioni e nella lettura ad alta voce.';

  @override
  String get formatMenu => 'Formattazione…';

  @override
  String get noteFont => 'Carattere';

  @override
  String get noteFontDefault => 'Predefinito';

  @override
  String get noteFontSerif => 'Libro (serif)';

  @override
  String get noteFontMono => 'Macchina da scrivere';

  @override
  String get noteTextSize => 'Dimensione del testo';

  @override
  String get formatClear => 'Rimuovi la formattazione';

  @override
  String get noteTextOpacity => 'Opacità';

  @override
  String get assistantVoiceSetting => 'L\'assistente legge le risposte';

  @override
  String get assistantVoiceSettingInfo =>
      'L\'assistente vocale legge la sua risposta ad alta voce (solo su telefono).';

  @override
  String get assistantMute => 'Disattiva l\'audio';

  @override
  String get assistantUnmute => 'Riattiva l\'audio';

  @override
  String get assistantMakeNote => 'Trasformala comunque in una nota';

  @override
  String get assistantNoteCreated => 'Nota creata';

  @override
  String get noteNotFound =>
      'Nota non trovata. Potrebbe essere stata eliminata.';

  @override
  String get back => 'Indietro';

  @override
  String get addTextBlock => 'Aggiungi testo';

  @override
  String get attachNoteContent => 'Contenuto della nota';

  @override
  String get noteBackgroundImage => 'Immagine di sfondo';

  @override
  String get chooseBackgroundImage => 'Scegli un\'immagine';

  @override
  String get changeBackgroundImage => 'Cambia immagine';

  @override
  String get removeBackgroundImage => 'Rimuovi lo sfondo';

  @override
  String get dashboardBackground => 'Sfondo della schermata principale';

  @override
  String get dashboardBackgroundInfo =>
      'Immagine mostrata dietro la griglia delle note (solo su questo dispositivo).';

  @override
  String get aiProvider => 'Fornitore di IA';

  @override
  String get aiProviderInfo =>
      'Scegli il fornitore a cui appartiene la tua chiave. La chiave di ogni fornitore viene conservata separatamente, così tornare indietro non richiede di digitarla di nuovo.';

  @override
  String get apiKeyFieldLabel => 'Chiave API';

  @override
  String get getApiKey => 'Dove ottengo una chiave?';

  @override
  String get recommendedModel => 'Consigliato';

  @override
  String get freeTierBadge => 'Ha un piano gratuito';

  @override
  String get continueWithoutAccount => 'Continua senza account';

  @override
  String get localAccountInfo =>
      'Le tue note restano solo su questo dispositivo: non possono essere aperte altrove, spariscono se disinstalli l\'app e l\'IA integrata è disattivata. Puoi collegare un account Google in qualsiasi momento — le tue note verranno mantenute.';

  @override
  String get localAccountBadge => 'Account locale';

  @override
  String get linkGoogleAccount => 'Collega un account Google';

  @override
  String get accountLinked =>
      'Il tuo account Google è collegato. Ora le tue note sono salvate.';

  @override
  String scanReviewPage(int current, int total) {
    return 'Pagina ${current} / ${total}';
  }

  @override
  String get scanRotatePage => 'Ruota la pagina';

  @override
  String get scanDeletePage => 'Elimina la pagina';

  @override
  String get scanLastPage => 'L\'ultima pagina non può essere eliminata';

  @override
  String get scanDiscardTitle => 'Scartare le pagine scansionate?';

  @override
  String get scanDiscardConfirm => 'Scarta';

  @override
  String get scanAdjustCorners => 'Regola gli angoli';

  @override
  String get scanFilterOriginal => 'Originale';

  @override
  String get scanFilterAuto => 'Migliora';

  @override
  String get scanFilterGray => 'Scala di grigi';

  @override
  String get scanFilterBw => 'Bianco e nero';

  @override
  String get scanApplyAll => 'Applica a tutte';

  @override
  String get scanPageFailed => 'Impossibile mostrare la pagina';

  @override
  String get scanCropHint =>
      'Correggi una pagina storta con "Regola gli angoli"';

  @override
  String get scanAddAsPdf => 'Aggiungi come PDF';

  @override
  String get scanAddAsImages => 'Aggiungi come immagini';

  @override
  String get scanBuildingPdf => 'Preparazione del PDF…';

  @override
  String scanOcrProgress(int done, int total) {
    return 'Riconoscimento del testo… ${done}/${total}';
  }

  @override
  String get scanAutoDetect => 'Rileva i bordi automaticamente';

  @override
  String get scanReset => 'Reimposta';

  @override
  String get scanDetecting => 'Ricerca dei bordi…';

  @override
  String get scanAutoFound =>
      'Bordi trovati automaticamente; se serve, regolali con le maniglie';

  @override
  String get scanDragHint => 'Trascina gli angoli sui bordi del foglio';

  @override
  String get scanApplyCorners => 'Raddrizza e applica';

  @override
  String get scanWorking => 'Raddrizzamento…';

  @override
  String get scanPdfAdded => 'Scansione aggiunta alla nota come allegato PDF';

  @override
  String get premiumTitle => 'Premium';

  @override
  String premiumStatusActive(String date) {
    return 'Premium attivo — fino al ${date}';
  }

  @override
  String get premiumStatusFree => 'Stai usando la versione gratuita';

  @override
  String get premiumPerksTitle => 'Cosa cambia con Premium?';

  @override
  String get premiumPerkAi => 'Punti IA giornalieri';

  @override
  String get premiumPerkAttach => 'Dimensione degli allegati';

  @override
  String get premiumPerkStorage => 'Spazio nel cloud';

  @override
  String get premiumPerkAuto => 'Contenuti giornalieri automatici';

  @override
  String get premiumPerkAutoBody =>
      'Il briefing quotidiano e i suggerimenti vengono preparati automaticamente ogni giorno; nella versione gratuita partono solo su richiesta.';

  @override
  String get premiumHowTitle => 'Come si ottiene?';

  @override
  String get premiumHowBody =>
      'Premium arriverà presto sul Play Store. Al momento siamo in accesso anticipato.';

  @override
  String get premiumByokHint =>
      'Se inserisci la tua chiave API di Gemini, le funzioni IA funzionano senza quota — indipendentemente da Premium (Impostazioni → IA).';

  @override
  String get premiumDiscoverTitle => 'Funzioni che potresti esserti perso';

  @override
  String get discoverScanBody =>
      'Le pagine scansionate vengono raddrizzate e migliorate, poi trasformate in un PDF RICERCABILE con un tocco: il livello di testo viene creato sul dispositivo, gratis.';

  @override
  String get discoverSemanticBody =>
      'La scheda "Smart" nella barra di ricerca cerca per SIGNIFICATO, non per parole: scrivi "orari dei voli" e compare la tua nota di viaggio.';

  @override
  String get discoverAssistantBody =>
      'Il microfono nella schermata iniziale trasforma da solo la tua voce in note, elenchi e promemoria: basta dire "domani alle 9 dal dentista".';

  @override
  String get discoverLockBody =>
      'Puoi bloccare una nota con impronta o volto: il suo contenuto non finisce mai nella ricerca, nei widget o nell\'IA.';

  @override
  String get discoverHiddenBody =>
      'Le note in una cartella nascosta non compaiono mai nella schermata iniziale né nella ricerca; per mostrare la cartella serve l\'autenticazione.';

  @override
  String get discoverExportBody =>
      'Ogni nota può essere esportata in PDF o Word, immagini comprese (nel menu di condivisione).';

  @override
  String get guestSignInUnavailable =>
      'L\'accesso senza Google è disattivato: l\'accesso anonimo non è abilitato nella console Firebase. Accedi con Google o riprova quando un amministratore lo abiliterà.';

  @override
  String get googleSignInUnavailable =>
      'L\'accesso con Google è disattivato: il provider Google non è abilitato nella console Firebase.';

  @override
  String get signInNetworkError =>
      'Impossibile raggiungere internet. Controlla la connessione e riprova.';

  @override
  String get signInCanceled => 'Accesso annullato.';

  @override
  String get cardRichPreview => 'Testo formattato sulle schede';

  @override
  String get cardRichPreviewInfo =>
      'Colori, evidenziazioni, grassetto e sottolineature delle tue note appaiono anche sulle schede della schermata principale. Se disattivato, le schede mostrano testo semplice.';

  @override
  String get fontSizeSmall => 'Piccolo';

  @override
  String get fontSizeMedium => 'Medio';

  @override
  String get fontSizeLarge => 'Grande';

  @override
  String get fontSizeXLarge => 'Molto grande';

  @override
  String get appFontSetting => 'Carattere';

  @override
  String get appFontInfo =>
      'Il carattere usato in tutta l\'app. Il carattere scelto per una nota ha la precedenza. Tutti i caratteri sono inclusi nell\'app: non serve internet.';

  @override
  String get fontGroupSans => 'Senza grazie';

  @override
  String get fontGroupSerif => 'Serif';

  @override
  String get fontGroupMono => 'Monospazio';

  @override
  String get fontGroupHand => 'Corsivo';

  @override
  String get appFontDefaultSuffix => 'predefinito';

  @override
  String get pdfSelectOcrRunning => 'Riconoscimento del testo…';

  @override
  String get pdfSelectOcrNone => 'Nessun testo trovato in questa pagina';

  @override
  String pdfSelectCopied(int n) {
    return '${n} caratteri copiati';
  }

  @override
  String get bubbleAdd => 'Metti un fumetto';

  @override
  String get bubbleAddDone => 'Fine inserimento fumetti';

  @override
  String get bubbleCollapse => 'Comprimi il fumetto';

  @override
  String get bubbleHint => 'Scrivi qui la tua nota…';

  @override
  String get bubbleTapToPlace => 'Tocca il punto della pagina dove vuoi il fumetto';

  @override
  String get aiModelPodcast => 'Narrazione podcast';

  @override
  String get listenAiVoice => 'Ascolta con la voce IA';

  @override
  String get listenAiVoiceInfo =>
      'Legge Gemini al posto della voce del dispositivo: più naturale, ma ogni paragrafo costa una chiamata al modello.';

  @override
  String listenAiVoiceFailed(String error) {
    return 'Narrazione IA non riuscita (${error}). Lettura con la voce del dispositivo.';
  }

  @override
  String get ttsSectionTitle => 'Narrazione';

  @override
  String get ttsEngineDevice => 'Voce del dispositivo';

  @override
  String get ttsEngineAi => 'IA';

  @override
  String get ttsEngineDeviceInfo =>
      'Legge la voce integrata del dispositivo: gratis, offline e senza limiti di lunghezza.';

  @override
  String get ttsEngineAiInfo =>
      'Legge il modello vocale di Gemini: molto più naturale, ma ogni paragrafo è una chiamata al modello e serve la tua chiave Gemini.';

  @override
  String get ttsEngineAiUnavailable =>
      'La voce IA richiede la tua chiave Gemini. Fino ad allora la lettura usa la voce del dispositivo.';

  @override
  String get ttsModel => 'Modello vocale';

  @override
  String get ttsVoice => 'Voce IA';

  @override
  String get shareAsNote => 'Condividi come nota';

  @override
  String get shareAsNoteInfo =>
      'Invia la nota con allegati, note di pagina, disegni e fumetti; l\'altra persona la apre identica nell\'app Not.';

  @override
  String get shareAsNotePreparing => 'Preparazione del pacchetto della nota…';

  @override
  String get shareAsText => 'Come testo semplice';

  @override
  String get shareAsTextInfo =>
      'Invia il testo della nota e le note di pagina a qualsiasi app.';

  @override
  String get shareAsTextEmpty => 'Questa nota non ha testo da condividere.';

  @override
  String get sharePdfWithBubbles => 'Come PDF con fumetti';

  @override
  String get sharePdfWithBubblesInfo =>
      'Fumetti, evidenziazioni e disegni vengono impressi nel PDF; chiunque può aprirlo e in Not si apre modificabile.';

  @override
  String get sharePdfWithBubblesNone =>
      'Questa nota non ha PDF con fumetti o disegni.';

  @override
  String get sharePdfWithBubblesPreparing =>
      'Preparazione del PDF con fumetti…';

  @override
  String get sharePdfWithBubblesSuffix => ' (con fumetti)';

  @override
  String get bubbleStar => 'Segna';

  @override
  String get bubbleEdit => 'Modifica il fumetto';

  @override
  String get bubbleStarredOnly => 'Solo quelli segnati';

  @override
  String get bubbleSearchHint => 'Cerca nei fumetti…';

  @override
  String get bubblesOverviewTitle => 'Fumetti';

  @override
  String get bubblesEmpty =>
      'Ancora nessun fumetto. Seleziona del testo nel documento ed evidenzialo, oppure metti un fumetto sulla pagina.';

  @override
  String get bubblesNoMatch => 'Nessun fumetto corrisponde alla ricerca.';

  @override
  String get bubbleNoText => '(fumetto vuoto)';

  @override
  String get pdfHighlight => 'Evidenzia';

  @override
  String get pdfHighlightWithNote => 'Evidenzia + nota';

  @override
  String get pageNotesShow => 'Mostra la nota di pagina';

  @override
  String get pageNotesHide => 'Nascondi la nota di pagina';

  @override
  String get bubbleSave => 'Salva';

  @override
  String get bubbleTitleHint => 'Titolo';

  @override
  String get bubbleUrgent => 'Urgente (lampeggia)';

  @override
  String get captureModeQuestion => 'Come deve aprirsi la nota?';

  @override
  String get captureModeBubbles => 'Fumetti';

  @override
  String get captureModeBubblesInfo =>
      'Il contenuto diventa una pagina di documento: fumetti, evidenziazioni e penna.';

  @override
  String get captureModeClassic => 'Classica';

  @override
  String get captureModeClassicInfo =>
      'Nota di testo semplice; il contenuto entra come allegato.';

  @override
  String get captureModeNew => 'NUOVO';

  @override
  String get imagePrepareTitle => 'Regola le immagini';

  @override
  String get imagePrepareDone => 'Continua';

  @override
  String get imageRotateLeft => 'Ruota a sinistra';

  @override
  String get imageRotateRight => 'Ruota a destra';

  @override
  String get videoFrameFailed =>
      'Impossibile estrarre un fotogramma dal video; si apre una nota classica.';

  @override
  String get bubbleArrowHide => 'Nascondi la freccia';

  @override
  String get bubbleArrowShow => 'Mostra la freccia';

  @override
  String get speechPitch => 'Tono della voce';

  @override
  String get speechVoicePickerTitle => 'Scelta della voce';

  @override
  String get formatRemove => 'Rimuovi';

  @override
  String get exportTitle => 'Esporta';

  @override
  String get exportNotesOption => 'Testo della nota (PDF / Word)';

  @override
  String get exportNotesOptionInfo =>
      'Testo e immagini della nota; i fumetti non sono inclusi.';

  @override
  String get captureNoteTitle => 'Titolo della nota (facoltativo)';

  @override
  String get captureNoteTitleHint =>
      'Anche il nuovo documento avrà questo nome';

  @override
  String get imageOcrTitle => 'Riconosci il testo nell’immagine';

  @override
  String get imageOcrNone => 'Nessun testo trovato in questa immagine.';

  @override
  String imageOcrHint(int count) {
    return '$count righe riconosciute · tocca per selezionare';
  }

  @override
  String imageOcrSelected(int count) {
    return '$count righe selezionate';
  }

  @override
  String get imageOcrShort => 'Riconosci testo';

  @override
  String get imageOcrWorking => 'Riconoscimento del testo…';

  @override
  String get imageOcrSelectHint =>
      'Tocca: parola · Tieni premuto e trascina: lettera per lettera';

  @override
  String get imageOcrInsert => 'Aggiungi alla nota';

  @override
  String get imageOcrZoomIn => 'Ingrandisci';

  @override
  String get imageOcrZoomOut => 'Riduci';

  @override
  String get selectImages => 'Seleziona immagini';

  @override
  String get exportImages => 'Immagini';

  @override
  String get exportImagesInfo =>
      'Il testo scorre accanto alle immagini strette allineate a sinistra o a destra; quelle centrate occupano tutta la larghezza.';

  @override
  String get exportAlignLeft => 'Sinistra';

  @override
  String get exportAlignCenter => 'Centro';

  @override
  String get exportAlignRight => 'Destra';

  @override
  String get exportImageWidth => 'Larghezza';

  @override
  String get exportImageLine => 'Posizione';

  @override
  String get aiModelSearch => 'Cerca modelli';

  @override
  String get aiModelOthers => 'ALTRI MODELLI';

  @override
  String get aiModelNoMatch => 'Nessun modello corrispondente.';

  @override
  String get aiModelAutoInfo => 'L’app prova in ordine i modelli più adatti.';

  @override
  String imageOcrCharsSelected(int count) {
    return '$count caratteri selezionati';
  }

  @override
  String imagesSelectedCount(int count) {
    return '$count immagini selezionate';
  }

  @override
  String attachmentsCopiedCount(int count) {
    return '$count allegati';
  }

  @override
  String exportImageLineOf(int count) {
    return '/ $count righe';
  }

  @override
  String get aiModelShowAll => 'Mostra tutti';

  @override
  String get aiModelShowAllInfo => 'Elenca anche i modelli che l’app non usa.';

  @override
  String get rotateFailed => 'Impossibile ruotare l\'immagine.';

  @override
  String get dashboardBackgroundPick => 'Scegli l\'immagine di sfondo';

  @override
  String get dashboardBackgroundChange => 'Cambia l\'immagine di sfondo';

  @override
  String podcastRenderingAudio(int done, int total) {
    return 'Preparazione dell\'audio: ${done}/${total} parti';
  }

  @override
  String get podcastExportAudio => 'Esporta come file audio';

  @override
  String get podcastExportAudioCost =>
      'L\'intero copione viene risintetizzato con la voce IA e salvato in un unico file WAV. Consuma la tua quota Gemini e sui testi lunghi può richiedere qualche minuto.';

  @override
  String get podcastShareText => 'Condividi il copione';

  @override
  String get podcastSaveAsNote => 'Salva come nuova nota';

  @override
  String get podcastSavedAsNote => 'Il copione del podcast è stato salvato come nota.';

  @override
  String get listenPreparingVoice => 'Preparazione dell\'audio…';

  @override
  String get appearancePreviewTitle => 'Testo di esempio';

  @override
  String get appearancePreviewNoteTitle => 'Titolo di nota di esempio';

  @override
  String get appearancePreviewBody =>
      'Le tue note appariranno così. Il testo **in grassetto**, ~sottolineato~ ed ==2:evidenziato== si vede in questo modo.';

  @override
  String get appearancePreviewItem => 'Un elemento dell\'elenco appare così';

  @override
  String get convertToText => 'Converti in testo';

  @override
  String get convertToList => 'Converti in elenco';

  @override
  String get convertedToText => 'L\'elenco è stato convertito in testo semplice.';

  @override
  String get convertedToList => 'Il testo è stato convertito in elenco.';

  @override
  String get convertToListEmpty => 'Non ci sono righe da convertire in elenco.';

  @override
  String get listTwoColumns => 'Due colonne';

  @override
  String get listOneColumn => 'Una colonna';

  @override
  String get sortItems => 'Ordina gli elementi';

  @override
  String get sortStarredFirst => 'Prima quelli segnati';

  @override
  String get sortUncheckedFirst => 'Completati per ultimi';

  @override
  String get sortAlphabetical => 'A → Z';

  @override
  String get sortAlphabeticalDesc => 'Z → A';

  @override
  String get imagesToAttachments => 'Sposta le immagini negli allegati';

  @override
  String imagesToAttachmentsDone(int count) {
    return '${count} immagini spostate negli allegati.';
  }

  @override
  String get imageOcrShowRecognized => 'Evidenzia il testo riconosciuto';

  @override
  String get imageOcrHideRecognized => 'Nascondi l\'evidenziazione';

  @override
  String get bubblePlainMode => 'Casella di testo aperta';

  @override
  String get bubblePlainModeOn => 'La casella di testo aperta è attiva';

  @override
  String get bubblePlainTapToPlace => 'Tocca dove deve andare il testo';

  @override
  String get bubblePlainHint => 'Tocca per scrivere';

  @override
  String get noteSearchTitle => 'Cerca nella nota';

  @override
  String get noteSearchHint => 'Cerca in questa nota…';

  @override
  String get noteSearchEmptyHint =>
      'Cerca subito nel testo, negli elementi e nelle note di pagina. Avvia la scansione qui sotto per cercare dentro gli allegati immagine e PDF.';

  @override
  String get noteSearchNoHit => 'Nessun risultato trovato.';

  @override
  String get noteSearchScanAttachments => 'Scansiona gli allegati';

  @override
  String get noteSearchAskAi => 'Chiedi all\'IA';

  @override
  String get noteTitleLabel => 'Titolo';

  @override
  String get noteBodyLabel => 'Testo della nota';

  @override
  String get itemLabel => 'Elemento';

  @override
  String noteSearchAttachmentsInfo(int count) {
    return 'Si possono scansionare ${count} allegati (immagine/PDF).';
  }

  @override
  String noteSearchAttachmentsReady(int count) {
    return 'La ricerca copre anche ${count} allegati.';
  }

  @override
  String pageLabel(int page) {
    return 'Pagina ${page}';
  }

  @override
  String get archiveNotebook => 'Quaderno d\'archivio';

  @override
  String get archiveNotebookInfo =>
      'Un quaderno con pagine proprie che conserva copie di documenti e immagini importanti.';

  @override
  String get archivePageImages => 'Immagini';

  @override
  String get archivePageVideos => 'Video';

  @override
  String get archivePageDocuments => 'Documenti';

  @override
  String get archivePageTexts => 'Testi';

  @override
  String get archiveNewPage => 'Nuova pagina';

  @override
  String get archivePageName => 'Nome della pagina (es. Fatture)';

  @override
  String get archivePageEmpty => 'Questa pagina è vuota.';

  @override
  String get archiveSearchHint => 'Cerca nel quaderno…';

  @override
  String get archiveAddText => 'Aggiungi testo';

  @override
  String get archiveAddFile => 'Aggiungi file';

  @override
  String get archiveCopyHere => 'Copia in un quaderno d\'archivio';

  @override
  String get archiveNoNotebook =>
      'Ancora nessun quaderno d\'archivio. Creane uno prima.';

  @override
  String get archiveNothingToCopy => 'Questa nota non ha allegati da copiare.';

  @override
  String archiveDeleteEntry(String name) {
    return 'Eliminare "${name}" dal quaderno? Questa copia va persa per sempre.';
  }

  @override
  String archiveCopied(int count) {
    return '${count} file copiati nel quaderno d\'archivio.';
  }

  @override
  String get archiveCaptureTitle => 'Cattura da un\'immagine';

  @override
  String get archiveCapturePage => 'Pagina';

  @override
  String get archiveCapturePageInfo =>
      'Il tipo suggerito dall\'IA. Se lo lasci vuoto, finisce nella pagina Testi.';

  @override
  String get archiveCaptureText => 'Testo riconosciuto';

  @override
  String get attachmentTagInsert => 'Inserisci nel testo';

  @override
  String get attachmentTagInserted => 'L\'etichetta dell\'allegato è stata inserita.';

  @override
  String get attachmentTagPreview => 'Anteprima dell\'allegato';

  @override
  String get attachmentTagEdit => 'Modifica l\'allegato';

  @override
  String archiveCardSummary(int files, int texts) {
    return '${files} file · ${texts} testi';
  }

  @override
  String get archiveEntryTitle => 'Titolo';

  @override
  String get archiveLinkedFile => 'File collegato';

  @override
  String get archiveNoLink => 'Nessun file collegato';

  @override
  String get attachmentTagEmbed => 'Incorpora l\'allegato nella selezione';

  @override
  String get attachmentTagNoAttachment =>
      'Aggiungi prima un file alla nota, poi potrai incorporarlo nel testo.';

  @override
  String get bubbleModeBubble => 'Fumetto';

  @override
  String get attachmentTagEmbedInfo =>
      'Si collega al testo selezionato, o al cursore se non è selezionato nulla';

  @override
  String get attachmentTagPickText =>
      'Ora seleziona il testo da collegare, poi tocca "Collega qui".';

  @override
  String get attachmentTagLinkHere => 'Collega qui';

  @override
  String attachmentTagPendingBanner(String name) {
    return '${name} verrà collegato — seleziona il testo';
  }

  @override
  String get docNameNotesSuffix => 'note';

  @override
  String get docNamePhoto => 'Note della foto';

  @override
  String get docNameScan => 'Note della scansione';

  @override
  String get docNameImage => 'Note dell\'immagine';

  @override
  String get docNameVideo => 'Note del video';

  @override
  String get folderManage => 'Gestisci la cartella';

  @override
  String get folderEmpty => 'Questa cartella è vuota';

  @override
  String get folderEmptyHint =>
      'Aggiungi una nota con il + qui sotto, oppure spostane una qui mentre la modifichi.';

  @override
  String get brainstormTitle => 'Brainstorming con l\'IA';

  @override
  String get brainstormRowInfo =>
      'L\'IA prepara prima una scaletta, poi la sviluppate insieme';

  @override
  String get brainstormIntro =>
      'Tocca uno dei titoli qui sopra o scrivi e basta: ragioniamo insieme.';

  @override
  String get brainstormOutlineTitle => 'SCALETTA';

  @override
  String get brainstormInputHint => 'Scrivi un\'idea o fai una domanda…';

  @override
  String get brainstormAddIdea => 'Aggiungi alla nota';

  @override
  String get brainstormAdded => 'Aggiunto alla nota';

  @override
  String get folderShared => 'Questa cartella è condivisa con un amico';

  @override
  String get friendsTitle => 'Contatti';

  @override
  String get friendsAdd => 'Aggiungi un amico';

  @override
  String get friendsEmpty =>
      'Ancora nessuno. Aggiungi un amico tramite e-mail per condividere le cartelle con lui.';

  @override
  String get friendsRequestsTitle => 'RICHIESTE';

  @override
  String get friendsListTitle => 'I MIEI AMICI';

  @override
  String get friendsAddEmailHint => 'amico@email.com';

  @override
  String get friendsSendRequest => 'Invia la richiesta';

  @override
  String get friendsRequestSent => 'Richiesta inviata';

  @override
  String get friendsNotFound =>
      'Nessun utente è registrato con questa e-mail. Deve aver aperto l\'app almeno una volta con un account Google.';

  @override
  String get friendsSelf => 'Non puoi aggiungere te stesso come amico';

  @override
  String get friendsAlready => 'Siete già amici';

  @override
  String get friendsDecline => 'Rifiuta';

  @override
  String get friendsAccept => 'Accetta';

  @override
  String get friendsRemove => 'Rimuovi';

  @override
  String get friendsRemoveConfirmTitle => 'Rimuovi l\'amico';

  @override
  String friendsRemoveConfirmBody(Object name) {
    return 'Rimuovere ${name} dai tuoi amici? Le cartelle condivise con lui non saranno più visibili.';
  }

  @override
  String get friendsNeedsAccount =>
      'I contatti e la condivisione delle cartelle richiedono un account Google collegato.';

  @override
  String get friendsSearchHint => 'Cerca per nome o e-mail';

  @override
  String get friendsSearchTab => 'Cerca';

  @override
  String get friendsSearchEmailTab => 'Tramite e-mail';

  @override
  String get friendsSearchEmpty => 'Nessun risultato';

  @override
  String get friendsSearchTooShort => 'Scrivi almeno 2 caratteri per cercare';

  @override
  String get friendsSearchAdd => 'Aggiungi';

  @override
  String get folderShare => 'Condividi';

  @override
  String folderShareCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Condivisa con ${count} persone',
      one: 'Condivisa con 1 persona',
    );
    return '$_temp0';
  }

  @override
  String folderShareTitle(Object name) {
    return 'Condividi "${name}"';
  }

  @override
  String get folderShareInfo =>
      'Un invito parte verso l\'amico che scegli; vedrà la cartella quando accetta. Sei tu a scegliere il permesso (lettura / scrittura / entrambi).';

  @override
  String get friendsRowInfo => 'Aggiungi amici, condividi cartelle con loro';

  @override
  String get accountRecoverConflictTitle =>
      'Su questo dispositivo ci sono note non salvate';

  @override
  String accountRecoverConflictBody(Object count) {
    return 'Questo account Google è già collegato a un\'altra sessione; passando a esso le ${count} nota/e su questo dispositivo verranno nascoste (non vengono eliminate, semplicemente non saranno più raggiungibili da qui). Continuare comunque?';
  }

  @override
  String get accountRecoverConflictProceed => 'Passa comunque';
  @override
  String get folderRoleRead => 'Lettura';

  @override
  String get folderRoleWrite => 'Scrittura';

  @override
  String get folderRoleBoth => 'Lettura + scrittura';

  @override
  String get folderInvitePending => 'Invito inviato, in attesa di risposta';

  @override
  String get folderWriteOnlyTitle => 'Hai solo l\'accesso in scrittura';

  @override
  String get folderWriteOnlyHint => 'Puoi aggiungere nuove note a questa cartella ma non vedere quelle al suo interno.';

  @override
  String get folderChatTitle => 'Chat';

  @override
  String get folderChatHint => 'Scrivi un messaggio…';

  @override
  String get folderChatSend => 'Invia';

  @override
  String get folderChatEmptyTitle => 'Ancora nessun messaggio';

  @override
  String get folderChatEmptyHint => 'Parla qui con le persone con cui hai condiviso questa cartella.';

  @override
  String get folderInviteTitle => 'Invito a una cartella';

  @override
  String folderInviteBody(Object name) {
    return 'La cartella "${name}" è stata condivisa con te.';
  }

  @override
  String get folderInviteAccepted => 'Cartella aggiunta';

  @override
  String get folderInviteDeclined => 'Invito rifiutato';

  @override
  String friendRequestBanner(Object name) {
    return '${name} ti ha inviato una richiesta di amicizia';
  }

  @override
  String get friendRequestAccepted => 'Amico aggiunto';

  @override
  String get sendNoteAction => 'Invia a un amico';

  @override
  String get sendNoteTitle => 'Invia la nota a un amico';

  @override
  String get sendNoteInfo => 'Una copia della nota arriva nella casella "Note in arrivo" della persona. Gli allegati (immagini, documenti, audio) non vengono inviati.';

  @override
  String sendNoteSent(Object name) {
    return 'Nota inviata a ${name}';
  }

  @override
  String get inboxTitle => 'Note in arrivo';

  @override
  String get inboxEmpty => 'Nessuna nota in arrivo';

  @override
  String get inboxEmptyHint => 'Le note che ti mandano gli amici si raccolgono qui.';

  @override
  String inboxFrom(Object name) {
    return 'Inviata da ${name}';
  }

  @override
  String get inboxAccept => 'Aggiungi alle mie note';

  @override
  String get inboxAccepted => 'Nota aggiunta alle tue note';

  @override
  String get folderShelfExpand => 'Espandi le cartelle';

  @override
  String get folderShelfCollapse => 'Comprimi le cartelle';

  @override
  String get accountSheetLocalInfo => 'Le tue note sono solo su questo dispositivo. Collega un account Google per farne il backup e aggiungere amici.';

  @override
  String get accountSettings => 'Impostazioni dell\'account';
}
