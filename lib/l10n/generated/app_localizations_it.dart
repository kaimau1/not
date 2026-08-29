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
      'Yüklenemedi — yeniden denemek için dokun';

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
    return 'Asistan \"$title\" notunu çöp kutusuna taşımak istiyor. Onaylıyor musun?';
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
  String get newPdfNote => 'PDF ekle not al';

  @override
  String get imageNotePreparing =>
      'Composizione delle immagini in un documento…';

  @override
  String get newImageNote => 'Aggiungi immagine e prendi appunti';

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
  String get pdfAddBlankPage => 'Aggiungi pagina vuota';

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
  String get attachNoteContent => 'Not içeriği';

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
      'La voce IA richiede la tua chiave Gemini. Fino ad allora la lettura usa la voce del dispositivo.';

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
}
