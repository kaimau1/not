// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get appName => 'Notities';

  @override
  String get loginTagline => 'Je notities, op elk apparaat';

  @override
  String get signInWithGoogle => 'Inloggen met Google';

  @override
  String loginError(String error) {
    return 'Inloggen mislukt: $error';
  }

  @override
  String get searchHint => 'Zoeken in notities...';

  @override
  String get filterAll => 'Alles';

  @override
  String get filterText => 'Tekst';

  @override
  String get filterChecklist => 'Lijst';

  @override
  String get filterOrdered => 'Genummerd';

  @override
  String get filterPinned => 'Vastgezet';

  @override
  String get filterStarred => 'Met ster';

  @override
  String get star => 'Ster toevoegen';

  @override
  String get unstar => 'Ster verwijderen';

  @override
  String editedAt(String date) {
    return 'Bewerkt: $date';
  }

  @override
  String get sectionPinned => 'Vastgezet';

  @override
  String get sectionOthers => 'Overige';

  @override
  String get emptyNotes => 'Nog geen notities';

  @override
  String get emptyNotesHint => 'Tik op + om je eerste notitie te maken';

  @override
  String get emptySearch => 'Geen resultaten gevonden';

  @override
  String get newTextNote => 'Tekstnotitie';

  @override
  String get newChecklist => 'Lijst';

  @override
  String get newOrderedList => 'Genummerde lijst';

  @override
  String get noteDeleted => 'Notitie verwijderd';

  @override
  String notesDeletedCount(int count) {
    return '$count notities verwijderd';
  }

  @override
  String selectedCount(int count) {
    return '$count geselecteerd';
  }

  @override
  String get deleteSelected => 'Selectie verwijderen';

  @override
  String get undo => 'Ongedaan maken';

  @override
  String get redo => 'Opnieuw';

  @override
  String get titleHint => 'Titel';

  @override
  String get bodyHint => 'Notitie...';

  @override
  String get newItemHint => 'Nieuw item';

  @override
  String moreItemsCount(int count) {
    return '+$count andere items';
  }

  @override
  String get addAttachment => 'Toevoegen';

  @override
  String get addAttachmentMore => 'Meer bijlagetypen…';

  @override
  String get addImage => 'Afbeelding toevoegen';

  @override
  String get addPdf => 'Pdf toevoegen';

  @override
  String get addSlide => 'Dia\'s toevoegen';

  @override
  String get pasteImage => 'Afbeelding uit klembord plakken';

  @override
  String get clipboardEmpty => 'Geen afbeelding op het klembord';

  @override
  String get noNoteSelected => 'Kies links een notitie';

  @override
  String attachmentFailed(String error) {
    return 'De bijlage kon niet worden toegevoegd: $error';
  }

  @override
  String get attachmentCopying => 'Kopiëren...';

  @override
  String get attachmentUploading => 'Uploaden...';

  @override
  String get attachmentUploadFailed =>
      'Uploaden mislukt — tik om opnieuw te proberen';

  @override
  String get attachmentNotSynced =>
      'Dit bestand is nog niet met dit apparaat gesynchroniseerd';

  @override
  String attachmentTooLarge(int limit) {
    return 'Bestand is te groot (maximaal $limit MB)';
  }

  @override
  String storageFull(String limit) {
    return 'Opslag is vol ($limit). Verwijder oude bijlagen om ruimte vrij te maken.';
  }

  @override
  String get storageUsage => 'Opslag';

  @override
  String storageUsageValue(String used, String limit) {
    return '$used van $limit gebruikt';
  }

  @override
  String get removeAttachment => 'Bijlage verwijderen';

  @override
  String get pin => 'Vastzetten';

  @override
  String get unpin => 'Losmaken';

  @override
  String get delete => 'Verwijderen';

  @override
  String get color => 'Kleur';

  @override
  String get aiTitle => 'AI';

  @override
  String get aiSummarize => 'Notitie samenvatten';

  @override
  String get aiAnalyze => 'Analyseren';

  @override
  String get aiSectionNote => 'Deze notitie';

  @override
  String get aiSectionAttachments => 'Bijlagen';

  @override
  String get summarize => 'Samenvatten';

  @override
  String get summaryDetailTitle => 'Type samenvatting';

  @override
  String get summaryShort => 'Korte samenvatting';

  @override
  String get summaryShortInfo => 'Een paar zinnen overzicht plus de kernpunten';

  @override
  String get summaryDetailed => 'Uitgebreide samenvatting';

  @override
  String get summaryDetailedInfo =>
      'Zo volledig dat je het origineel niet hoeft te openen';

  @override
  String get listen => 'Luisteren';

  @override
  String get ask => 'Een vraag stellen';

  @override
  String get extractText => 'Tekst eruit halen';

  @override
  String get transcribe => 'Uitschrijven';

  @override
  String get listenToNote => 'Hardop voorlezen';

  @override
  String get aiNoApiKey =>
      'Voer eerst je Gemini API-sleutel in bij de instellingen';

  @override
  String aiError(String error) {
    return 'AI-verzoek mislukt: $error';
  }

  @override
  String get aiSummaryTitle => 'AI-samenvatting';

  @override
  String get aiThinking => 'Aan het nadenken...';

  @override
  String get copy => 'Kopiëren';

  @override
  String get copied => 'Gekopieerd';

  @override
  String get settingsSearchHint =>
      'Instellingen doorzoeken — “briefing”, “microfoon”';

  @override
  String settingsSearchEmpty(String query) {
    return 'Geen instelling komt overeen met «$query»';
  }

  @override
  String get settings => 'Instellingen';

  @override
  String get settingsAppearance => 'Weergave';

  @override
  String get themeSystem => 'Systeem';

  @override
  String get themeLight => 'Licht';

  @override
  String get themeDark => 'Donker';

  @override
  String get settingsAi => 'AI';

  @override
  String get geminiApiKey => 'Gemini API-sleutel';

  @override
  String get geminiApiKeyHint => 'Plak de sleutel die met AIza... begint';

  @override
  String get geminiApiKeyInfo =>
      'Een sleutel is optioneel: zonder sleutel lopen AI-verzoeken via de ingebouwde dienst van de app (een gratis daglimiet, hoger met Premium). Wil je onbeperkt met je eigen sleutel werken, haal er dan gratis een op via aistudio.google.com; de sleutel wordt alleen op dit apparaat bewaard, in beveiligde opslag.';

  @override
  String aiBuiltInPremium(int count) {
    return 'Ingebouwde AI: Premium — nog $count punten vandaag';
  }

  @override
  String aiBuiltInRemaining(int count) {
    return 'Ingebouwde AI: nog $count gratis punten vandaag';
  }

  @override
  String get aiBuiltInByok => 'Met je eigen sleutel — onbeperkt';

  @override
  String get aiReport => 'Dit antwoord melden';

  @override
  String get aiReportThanks => 'Melding ontvangen, bedankt';

  @override
  String get privacyPolicyTitle => 'Privacybeleid';

  @override
  String get lockNote => 'Vergrendelen';

  @override
  String get unlockNote => 'Ontgrendelen';

  @override
  String get lockedNote => 'Vergrendelde notitie';

  @override
  String get unlockAuthReason =>
      'Bevestig je identiteit om de vergrendelde notitie te openen';

  @override
  String get exportBackup => 'Back-up exporteren (JSON)';

  @override
  String get expandListItems => 'Lijstregels volledig tonen';

  @override
  String get expandListItemsInfo =>
      'Lange items lopen door over meerdere regels en blijven volledig zichtbaar. Staat dit uit, dan blijft een regel op één regel en klapt hij open bij een tik.';

  @override
  String get quickCaptureRowSetting => 'Snelle-notitiebalk';

  @override
  String get quickCaptureRowInfo =>
      'Toont bovenaan een éénregelig \"Nieuwe notitie...\"-veld. Indien uit, gebruik de +-knop.';

  @override
  String get emptyTrash => 'Prullenbak legen';

  @override
  String emptyTrashConfirm(int count) {
    return '$count notities worden definitief verwijderd. Dit kan niet ongedaan worden gemaakt. Weet je het zeker?';
  }

  @override
  String get trashEmptied => 'Prullenbak geleegd';

  @override
  String get validateAndSave => 'Controleren en opslaan';

  @override
  String get clear => 'Wissen';

  @override
  String get aiDiagnostics => 'AI-diagnose';

  @override
  String get aiDiagnosticsEmpty => 'Geen fouten vastgelegd';

  @override
  String aiDiagnosticsCount(int count) {
    return 'Laatste $count foutmeldingen';
  }

  @override
  String get apiKeyValid => 'API-sleutel gecontroleerd en opgeslagen';

  @override
  String get apiKeyInvalid => 'De API-sleutel is niet geldig';

  @override
  String get apiKeySavedBadge => 'Opgeslagen';

  @override
  String get removeApiKey => 'Sleutel verwijderen';

  @override
  String get refresh => 'Vernieuwen';

  @override
  String get account => 'Account';

  @override
  String get signOut => 'Uitloggen';

  @override
  String get signOutConfirm => 'Weet je zeker dat je wilt uitloggen?';

  @override
  String get signOutAnonymousWarning =>
      'Je gebruikt een lokaal account: na uitloggen zijn dit account en ALLE notities permanent ontoegankelijk — zonder back-up niet te herstellen. Koppel eerst een Google-account. Toch uitloggen?';

  @override
  String get deleteAccount => 'Mijn account en gegevens verwijderen';

  @override
  String get deleteAccountWarning =>
      'Dit kan niet ongedaan worden gemaakt: al je notities, bijlagen en je account worden definitief verwijderd. Wil je doorgaan?';

  @override
  String get deleteAccountConfirm => 'Definitief verwijderen';

  @override
  String get licensesTitle => 'Opensourcelicenties';

  @override
  String get generating => 'Bezig met genereren...';

  @override
  String get retry => 'Opnieuw proberen';

  @override
  String get cancel => 'Annuleren';

  @override
  String get close => 'Sluiten';

  @override
  String get ok => 'Oké';

  @override
  String get syncPending => 'Wacht op synchronisatie';

  @override
  String get synced => 'Gesynchroniseerd';

  @override
  String genericError(String error) {
    return 'Er ging iets mis: $error';
  }

  @override
  String get addTag => 'Label';

  @override
  String get tagHint => 'bijv. werk, thuis, school';

  @override
  String get addReminder => 'Herinner mij';

  @override
  String get share => 'Delen';

  @override
  String get archive => 'Archiveren';

  @override
  String get unarchive => 'Uit archief halen';

  @override
  String get archiveTitle => 'Archief';

  @override
  String get archiveEmpty => 'Geen notities in het archief';

  @override
  String get trashTitle => 'Prullenbak';

  @override
  String get trashEmpty => 'De prullenbak is leeg';

  @override
  String get trashInfo =>
      'Verwijderde notities blijven hier staan; je kunt ze terugzetten of definitief verwijderen.';

  @override
  String get restore => 'Terugzetten';

  @override
  String get deleteForever => 'Definitief verwijderen';

  @override
  String get deleteForeverConfirm =>
      'Deze notitie wordt definitief verwijderd. Weet je het zeker?';

  @override
  String assistantDeleteConfirm(String title) {
    return 'De assistent wil de notitie "${title}" naar de prullenbak verplaatsen. Ga je akkoord?';
  }

  @override
  String get recordAudio => 'Spraakopname';

  @override
  String get recording => 'Bezig met opnemen...';

  @override
  String get stopAndSave => 'Afronden en toevoegen';

  @override
  String get micPermissionDenied =>
      'Toestemming voor de microfoon is geweigerd';

  @override
  String get speechRecognitionFailed =>
      'Spraakherkenning werkte niet. Controleer of toestemming voor de microfoon is gegeven en of de Google-app up-to-date is.';

  @override
  String get addDrawing => 'Tekening toevoegen';

  @override
  String get drawingTitle => 'Tekening';

  @override
  String get addToNote => 'Aan notitie toevoegen';

  @override
  String get chatTitle => 'Notitie-assistent';

  @override
  String get chatHint =>
      'Vraag iets over je notities: «wat was dat recept dat ik vorige week opschreef?», «wat mist er in mijn boodschappenlijst?»';

  @override
  String get chatInputHint => 'Typ een vraag...';

  @override
  String get fontSize => 'Tekstgrootte';

  @override
  String get fontSizePreview => 'Zo komen je notities eruit te zien';

  @override
  String get darkSchedule => 'Schema donker thema';

  @override
  String get darkScheduleInfo =>
      'Schakelt tussen de door jou ingestelde tijden over op het donkere thema';

  @override
  String get aiTranslate => 'Vertalen';

  @override
  String get voiceCommand => 'Spraakopdracht';

  @override
  String get semanticSearchToggle => 'Zoeken op betekenis met AI';

  @override
  String get semanticSearchHint => 'Zoek op betekenis: «autokosten»...';

  @override
  String get briefingTitle => 'Dagoverzicht';

  @override
  String get briefingLoading => 'Je overzicht wordt klaargezet...';

  @override
  String get briefingEmpty => 'Niets voor vandaag';

  @override
  String get briefingSetting => 'Melding met dagoverzicht';

  @override
  String get briefingSettingInfo =>
      'Ontvang elke ochtend op het door jou gekozen tijdstip een melding met de samenvatting van de dag';

  @override
  String get autoTagSetting => 'Automatisch labelen';

  @override
  String get autoTagSettingInfo =>
      'Wordt een notitie zonder labels gesloten, dan voegt AI een passend label toe';

  @override
  String get suggestTags => 'Labels voorstellen';

  @override
  String get aiFixNote => 'Notitie opknappen';

  @override
  String get fixLevelTitle => 'Hoe grondig opknappen?';

  @override
  String get fixSimple => 'Licht';

  @override
  String get fixSimpleInfo => 'Alleen spelling en typefouten';

  @override
  String get fixBalanced => 'Gebalanceerd';

  @override
  String get fixBalancedInfo => 'Ook de zinsbouw, voor een strakkere tekst';

  @override
  String get fixDetailed => 'Grondig';

  @override
  String get fixDetailedInfo => 'Herschrijft de hele tekst van begin tot eind';

  @override
  String get existingTagsLabel => 'Eerdere labels';

  @override
  String get aiSkipCheckedSetting =>
      'Afgevinkte items buiten AI-bewerkingen laten';

  @override
  String get aiSkipCheckedInfo =>
      'Wanneer AI een lijst opknapt of vertaalt, blijven afgeronde (afgevinkte) items precies zoals ze zijn; alleen niet-afgevinkte items worden bewerkt.';

  @override
  String get noteUpdatedUndo => 'Notitie bijgewerkt';

  @override
  String get aiImprove => 'Notitie verbeteren';

  @override
  String get improveFormal => 'Formeler maken';

  @override
  String get improveShorten => 'Inkorten';

  @override
  String get improveBullets => 'Omzetten naar opsomming';

  @override
  String get improveNumbered => 'Omzetten naar genummerde lijst';

  @override
  String get replaceNote => 'Notitie vervangen';

  @override
  String get openAsNewNote => 'Als nieuwe notitie';

  @override
  String get pdfChatHint =>
      'Vraag iets over deze pdf: «vat samen», «staat er een boetebeding in?», «wat is de deadline?»';

  @override
  String get pdfChatInputHint => 'Typ een vraag over de pdf...';

  @override
  String get voiceCaptureHint =>
      'Spreek in: «melk en brood kopen» of «morgen om 9 uur overleg, herinner me» — AI stelt je notitie op als je klaar bent.';

  @override
  String get voiceFinish => 'Afronden';

  @override
  String get voiceProcessing => 'Bezig met verwerken van wat je zei...';

  @override
  String get voiceNothingHeard => 'Geen spraak aangetroffen in de opname';

  @override
  String get voiceNoteSaved => 'Je spraaknotitie is opgeslagen';

  @override
  String get openNote => 'Notitie openen';

  @override
  String get remindersTitle => 'Herinneringen';

  @override
  String get remindersEmpty => 'Geen herinneringen';

  @override
  String get remindersEmptyHint =>
      'Voeg een herinnering toe aan een notitie, of maak met de +-knop een nieuwe notitie met herinnering';

  @override
  String get remindersUpcoming => 'Aankomend';

  @override
  String get remindersPast => 'Voorbij';

  @override
  String get reminderInPast =>
      'De gekozen tijd ligt in het verleden — kies een tijd in de toekomst.';

  @override
  String get newReminder => 'Nieuwe herinnering';

  @override
  String get remindersUntitled => 'Notitie zonder titel';

  @override
  String get remindersEdit => 'Tijd wijzigen';

  @override
  String get remindersRemove => 'Herinnering verwijderen';

  @override
  String get aiModelChat => 'Samenvattingen, titels, labels en chat';

  @override
  String get aiModelDocument => 'Documentchat en pdf-samenvatting';

  @override
  String get aiModelTranslate => 'Vertaling';

  @override
  String get aiModelVoice => 'Spraaknotitie-assistent';

  @override
  String get aiModelAuto => 'Automatisch (aanbevolen)';

  @override
  String get aiModelsInfo =>
      'Je kunt per taak een ander model kiezen: kort tekstwerk kan prima op een snel model, lange documenten vragen om een krachtiger model. Bereikt het gekozen model zijn limiet of wordt het ingetrokken, dan wordt automatisch het volgende geprobeerd.';

  @override
  String get clearNote => 'Leegmaken';

  @override
  String get clearNoteConfirm =>
      'De inhoud van de notitie (tekst en lijstitems) wordt verwijderd. Weet je het zeker?';

  @override
  String get themePaper => 'Papier';

  @override
  String get calculatorTitle => 'Rekenmachine';

  @override
  String get calcExpressionHint => 'bijv. 12,5×3+40';

  @override
  String get calcInvalid => 'Ongeldige uitdrukking';

  @override
  String get liveDictation => 'Dicteren';

  @override
  String get dictationListening =>
      'Luistert... de tekst verschijnt terwijl je spreekt';

  @override
  String get dictationNoKeyInfo =>
      'Live dicteren is niet beschikbaar op dit apparaat; de opname wordt in één keer uitgeschreven zodra je stopt.';

  @override
  String get dictationHoldHint =>
      'Houd de microfoon ingedrukt en spreek; de tekst wordt geschreven zodra je loslaat';

  @override
  String itemsSelected(int count) {
    return '$count items geselecteerd';
  }

  @override
  String get noteChatTitle => 'Chatten met deze notitie';

  @override
  String get noteChatHint => 'Vraag iets over deze notitie';

  @override
  String get noteChatIntro =>
      'De inhoud van de notitie en de bijlagen (pdf/afbeelding) worden gelezen, en je vraag wordt daaruit beantwoord.';

  @override
  String get dictationProcessing => 'Bezig met uitschrijven...';

  @override
  String get aiDailyManualInfo =>
      'In het gratis abonnement wordt dit niet automatisch gemaakt, dus het gaat niet van je daglimiet af. Met de knop hieronder kun je het één keer per dag maken.';

  @override
  String get aiGenerate => 'Genereren';

  @override
  String get aiGeneratedTodayInfo =>
      'Dit is vandaag gemaakt. In het gratis abonnement ververst het één keer per dag; morgen kun je het opnieuw maken.';

  @override
  String get voiceAssistantTitle => 'Assistent voor spraaknotities';

  @override
  String get voiceListening => 'Luistert...';

  @override
  String get voiceHoldHint =>
      'Houd ingedrukt en spreek; je notitie wordt gemaakt zodra je loslaat';

  @override
  String get voiceTapHint => 'Tik en spreek; tik nogmaals om af te ronden';

  @override
  String get voiceTooShort => 'Die opname was te kort, probeer het opnieuw';

  @override
  String get voiceModeSetting => 'Hoe het werkt';

  @override
  String get voiceModeHold => 'Ingedrukt houden om te praten';

  @override
  String get voiceModeTap => 'Tik om te starten / tik om te stoppen';

  @override
  String get voiceModeInfo =>
      'Ingedrukt houden om te praten: er wordt geluisterd zolang je de knop vasthoudt en de notitie wordt gemaakt zodra je loslaat. Tik om te starten: één tik begint de opname, een tweede tik beëindigt hem.';

  @override
  String get voiceHeardLive => 'Spraak gedetecteerd';

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
  String get voiceCaptureAiNote => 'AI-notitie';

  @override
  String get voiceCapturePlainNote => 'Gewone notitie';

  @override
  String get voiceCloseTitle => 'Je dictaat staat er nog';

  @override
  String get voiceCloseKeepTalking => 'Doorgaan met praten';

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
  String get voiceChipCompose => 'Laat de assistent dit schrijven';

  @override
  String get editorToolList => 'List';

  @override
  String get permissionsTitle => 'Toestemmingen';

  @override
  String get permMic => 'Microfoon';

  @override
  String get permMicInfo => 'Nodig voor spraaknotities en dicteren';

  @override
  String get permNotifications => 'Meldingen';

  @override
  String get permNotificationsInfo =>
      'Nodig voor herinneringen en het dagoverzicht';

  @override
  String get permBattery => 'Batterijoptimalisatie';

  @override
  String get permBatteryInfo =>
      'Stel de app vrij van batterijbeperkingen zodat herinneringen op tijd binnenkomen';

  @override
  String get showTagChips => 'Labelchips tonen';

  @override
  String get showFolderChips => 'Mapchips tonen';

  @override
  String videoTooBigForAi(int mb) {
    return 'De video is te groot om naar AI te sturen ($mb MB). Neem een kortere op.';
  }

  @override
  String get permCamera => 'Camera';

  @override
  String get permCameraInfo =>
      'Nodig voor videonotities en het maken van foto\'s';

  @override
  String get permOnboardTitle => 'Voordat je begint';

  @override
  String get permOnboardInfo =>
      'Notities vraagt deze toestemmingen pas wanneer je de bijbehorende functie gebruikt. Je kunt ze hieronder nu geven, of ze later aanpassen via Instellingen > Toestemmingen.';

  @override
  String get permOnboardGrantAll => 'Toestemmingen geven';

  @override
  String get permOnboardSkip => 'Nu niet';

  @override
  String get newVideoNote => 'Videonotitie';

  @override
  String get videoLocalOnly =>
      'Deze video staat alleen op dit apparaat (wordt niet naar de cloud geüpload)';

  @override
  String get videoToNote => 'Notitie maken van de video';

  @override
  String get videoToNoteRunning => 'De video wordt bekeken…';

  @override
  String get permGranted => 'Gegeven';

  @override
  String get permGrant => 'Geven';

  @override
  String get permOpenSettings => 'Instellingen openen';

  @override
  String get newHandwriting => 'Handschrift';

  @override
  String get newVoiceCapture => 'Spraaknotitie';

  @override
  String get suggestTitle => 'Titel voorstellen';

  @override
  String get noteMetaMenu => 'Label · Titel · Herinnering';

  @override
  String get folder => 'Map';

  @override
  String get noFolder => 'Geen map';

  @override
  String get newFolder => 'Nieuwe map';

  @override
  String get editFolder => 'Map bewerken';

  @override
  String get deleteFolder => 'Map verwijderen';

  @override
  String deleteFolderConfirm(String name) {
    return 'De map «$name» wordt verwijderd. De notities erin worden niet verwijderd — ze hebben dan simpelweg geen map meer.';
  }

  @override
  String get folderNameHint => 'Mapnaam';

  @override
  String get folderIcon => 'Pictogram';

  @override
  String get editFilters => 'Filters bewerken';

  @override
  String get editFiltersInfo =>
      'Kies welke filters op het startscherm verschijnen. Filters verbergen houdt de pagina overzichtelijk.';

  @override
  String get select => 'Selecteren';

  @override
  String get noteArchived => 'Notitie gearchiveerd';

  @override
  String deleteChecked(int count) {
    return 'Afgevinkte verwijderen ($count)';
  }

  @override
  String get removeItem => 'Item verwijderen';

  @override
  String get copyWholeNote => 'Hele notitie kopiëren';

  @override
  String get allCopied => 'De hele notitie is naar het klembord gekopieerd';

  @override
  String get speechPlay => 'Hardop voorlezen';

  @override
  String get speechPause => 'Pauzeren';

  @override
  String get speechResume => 'Hervatten';

  @override
  String get speechStop => 'Stoppen';

  @override
  String get speechRate => 'Leessnelheid';

  @override
  String get speechSystemDefault => 'Standaard van het systeem';

  @override
  String get speechNoVoices =>
      'Er zijn geen stemmen geïnstalleerd op dit apparaat';

  @override
  String speechVoiceLanguage(String language) {
    return 'Stem voor $language';
  }

  @override
  String get speechVoiceAutoInfo =>
      'Andere talen worden automatisch met een mannenstem voorgelezen';

  @override
  String get listening => 'Luistert...';

  @override
  String get listenPlay => 'Luisteren';

  @override
  String get listenReadingPdf => 'Het document wordt gelezen...';

  @override
  String get listenConvertWithAi => 'Omzetten met AI';

  @override
  String get listenMakePodcast => 'Volledige podcast';

  @override
  String get listenMakePodcastSummary => 'Samenvattingspodcast';

  @override
  String get listenOriginalText => 'Oorspronkelijke tekst';

  @override
  String get listenPodcastReady => 'De podcastvertelling staat klaar';

  @override
  String get listenPodcastCached => 'Eerder gemaakt — geen tokens verbruikt';

  @override
  String get listenRegenerate => 'Opnieuw genereren';

  @override
  String get listenNoText =>
      'Uit dit document kwam geen leesbare tekst. Een gescande pdf heeft geen tekstlaag, en een presentatie kan alleen afbeeldingen bevatten.';

  @override
  String get readDocument => 'Een document lezen (Word, pdf, dia\'s)';

  @override
  String get readDocUnsupported => 'Dit bestandstype kan niet worden gelezen.';

  @override
  String get exportPdf => 'Exporteren als pdf';

  @override
  String get pdfTitleField => 'Titel';

  @override
  String get pdfContentField => 'Inhoud';

  @override
  String get pdfMarkupHint =>
      'Tekens aan het begin van een regel worden opmaak: [x] en [ ] voor vinkvakjes, 1. voor een genummerde lijst, - voor een opsommingsteken.';

  @override
  String get pdfIncludeDate => 'Datum opnemen';

  @override
  String get exportIncludeImages => 'Afbeeldingen opnemen';

  @override
  String get exportWord => 'Delen als Word (.docx)';

  @override
  String get pdfPreview => 'Voorbeeld';

  @override
  String get largeAttachmentTitle => 'Groot bestand';

  @override
  String largeAttachmentBody(String size) {
    return 'Dit bestand is $size MB. Pdf\'s kunnen niet worden gecomprimeerd; het wordt ongewijzigd geüpload en telt mee voor je opslag. Doorgaan?';
  }

  @override
  String get speechRateForeign => 'Snelheid voor vreemde talen';

  @override
  String notesArchivedCount(int count) {
    return '$count notities gearchiveerd';
  }

  @override
  String get backgroundColor => 'Achtergrondkleur';

  @override
  String get backgroundColorInfo => 'De achtergrondkleur van de notitie';

  @override
  String get frameColor => 'Kader';

  @override
  String get frameColorInfo =>
      'Tekent een kader rond de notitie in de kleur die je kiest';

  @override
  String get sortBy => 'Sorteren';

  @override
  String get reorderNotes => 'Notities herschikken';

  @override
  String get reorderModeActive => 'Sleep de kaarten om de volgorde te wijzigen';

  @override
  String get reorderDone => 'Klaar';

  @override
  String get sortManual => 'Handmatig (gesleepte volgorde)';

  @override
  String get sortUpdated => 'Onlangs bijgewerkt';

  @override
  String get sortCreated => 'Aanmaakdatum';

  @override
  String get sortTitle => 'Op titel (A–Z)';

  @override
  String get foldersSection => 'Mappen';

  @override
  String get tagsSection => 'Labels';

  @override
  String get expandFilters => 'Filters uitklappen';

  @override
  String get collapseFilters => 'Filters inklappen';

  @override
  String get settingsLanguage => 'Taal';

  @override
  String get languageSystem => 'Taal van het systeem';

  @override
  String get settingsSpeech => 'Voorlezen';

  @override
  String get aiAdvanced => 'Geavanceerd: model en API-sleutel';

  @override
  String get aiAdvancedInfo =>
      'Modelkeuze en je eigen Gemini-sleutel. De meeste mensen hebben dit niet nodig.';

  @override
  String get openBriefing => 'Overzicht openen';

  @override
  String get syncTitle => 'Synchronisatie';

  @override
  String get syncLimitTitle => 'Limiet automatisch uploaden';

  @override
  String get syncLimitInfo =>
      'Bijlagen groter dan dit blijven op het apparaat staan en worden niet geüpload. De tekst van notities wordt altijd gesynchroniseerd.';

  @override
  String get syncLimitUnlimited => 'Geen limiet';

  @override
  String get backupTitle => 'Back-up';

  @override
  String get importBackup => 'Terugzetten uit back-up (JSON)';

  @override
  String importBackupDone(int count) {
    return '$count notities teruggezet';
  }

  @override
  String get importBackupInvalid => 'Ongeldig back-upbestand';

  @override
  String get aiHubTitle => 'AI';

  @override
  String get aiSummarizeInfo => 'Maakt een korte samenvatting';

  @override
  String get aiAnalyzeInfo => 'Zet de kernpunten en to-do\'s op een rij';

  @override
  String get aiImproveInfo => 'Verandert de toon: formeel, korter of lijst';

  @override
  String get aiTranslateInfo => 'Vertaalt de notitie naar een gekozen taal';

  @override
  String get aiFixNoteInfo => 'Corrigeert spelling en interpunctie';

  @override
  String get moveToFolder => 'Naar map verplaatsen';

  @override
  String get voiceAssistantBadge => 'Assistent';

  @override
  String get assistantGenericError =>
      'Er ging iets mis — wil je het nog eens proberen?';

  @override
  String get quickAddTooltip => 'Nieuwe notitie — kies een type';

  @override
  String get autoTitleSetting => 'Titel voorstellen bij sluiten';

  @override
  String get autoTitleSettingInfo =>
      'Wanneer je de editor verlaat, krijgt een notitie zonder titel een korte titel die uit de inhoud is opgesteld.';

  @override
  String get hubChatInfo => 'Antwoorden uit je eigen notities';

  @override
  String get hubBriefingInfo =>
      'Je dag in één oogopslag: herinneringen en recente notities';

  @override
  String get hubReadInfo => 'Luister naar een pdf- of Word-document';

  @override
  String get annotate => 'Aantekeningen maken';

  @override
  String get annotateDone => 'Aantekenen afronden';

  @override
  String get newPdfNote => 'Pdf toevoegen, notities maken';

  @override
  String get imageNotePreparing =>
      'Afbeeldingen worden tot een document samengevoegd…';

  @override
  String get newImageNote => 'Afbeelding toevoegen en notities maken';

  @override
  String get pdfPageNoteHint => 'Notitie bij deze pagina…';

  @override
  String pdfPage(int page) {
    return 'Pagina ${page}';
  }

  @override
  String pdfPageOf(int page, int total) {
    return 'Pagina ${page} / ${total}';
  }

  @override
  String get pdfPreviousPage => 'Vorige pagina';

  @override
  String get pdfNextPage => 'Volgende pagina';

  @override
  String get pdfFullScreen => 'Volledig scherm openen';

  @override
  String get pdfNoDocument => 'Deze notitie heeft nog geen pdf';

  @override
  String get pdfChooseDocument => 'Pdf kiezen';

  @override
  String get newSlidesNote => 'Dia\'s toevoegen, notities maken';

  @override
  String get slidesNoDocument => 'Deze notitie heeft nog geen presentatie';

  @override
  String get slidesChooseDocument => 'Presentatie kiezen';

  @override
  String get pdfEditPages => 'Pagina\'s bewerken';

  @override
  String get pdfDeletePages => 'Geselecteerde pagina\'s verwijderen';

  @override
  String get pdfAddBlankPage => 'Lege pagina toevoegen';

  @override
  String get pdfRotatePages => 'Draaien';

  @override
  String get pdfBurnInk => 'Handschrift in het document vastleggen';

  @override
  String get pdfApplyChanges => 'Wijzigingen toepassen';

  @override
  String get pdfCannotDeleteAllPages => 'Je kunt niet alle pagina\'s verwijderen';

  @override
  String get pdfPagesHint =>
      'Tik op een pagina om die te selecteren. Paginanotities blijven bij hun pagina; de notitie van een verwijderde pagina wordt verborgen, maar blijft in je gegevens bewaard.';

  @override
  String pdfEditFailed(String error) {
    return 'Kon de pdf niet bewerken: ${error}';
  }

  @override
  String get pdfInkBurned => 'Handschrift in het document vastgelegd';

  @override
  String get pdfAllPageNotes => 'Alle paginanotities';

  @override
  String get pdfNoPageNotes =>
      'Nog geen paginanotities. Ga naar een pagina en schrijf in het veld hieronder.';

  @override
  String get crop => 'Bijsnijden';

  @override
  String get cropApply => 'Bijsnijden toepassen';

  @override
  String get cropReset => 'Selectie herstellen';

  @override
  String get cropHint =>
      'Sleep de hoeken om een gebied te kiezen. Bijsnijden kan niet ongedaan worden gemaakt.';

  @override
  String get cropFailed => 'De afbeelding kon niet worden bijgesneden.';

  @override
  String get penBallpoint => 'Balpen';

  @override
  String get penMarker => 'Marker';

  @override
  String get penHighlighter => 'Markeerstift';

  @override
  String get eraser => 'Gum';

  @override
  String get inkArrow => 'Pijl';

  @override
  String get clearInk => 'Aantekeningen wissen';

  @override
  String get inkTwoFingerHint =>
      'Eén vinger tekent · twee vingers verschuiven en zoomen';

  @override
  String get slideOpenFailed => 'De presentatie kon niet worden geopend';

  @override
  String get newPhotoNote => 'Fotonotitie';

  @override
  String get newScanNote => 'Document scannen';

  @override
  String get scanDocument => 'Document scannen';

  @override
  String get scanDocumentSubtitle =>
      'Vindt de randen, trekt de pagina recht en voegt hem toe';

  @override
  String get scanUnsupported =>
      'Documenten scannen wordt niet ondersteund op dit apparaat';

  @override
  String scanFailed(String error) {
    return 'Het document kon niet worden gescand: $error';
  }

  @override
  String scanPagesAdded(int count) {
    return '$count pagina(\'s) aan de notitie toegevoegd';
  }

  @override
  String get scanTextTitle => 'Ook de tekst herkennen?';

  @override
  String get scanTextBody =>
      'De tekst op de pagina\'s wordt herkend en in de notitie geschreven. De afbeelding blijft zoals hij is. Duurt een paar seconden per pagina.';

  @override
  String get scanImageOnly => 'Alleen afbeelding';

  @override
  String get scanRecognizeText => 'Tekst herkennen';

  @override
  String get scanRecognizing => 'Tekst wordt herkend…';

  @override
  String get takePhoto => 'Foto maken';

  @override
  String get qrScanTitle => 'QR-code scannen';

  @override
  String get qrScanSubtitle => 'Lees hem met de camera of vanaf een foto';

  @override
  String get qrScanHint => 'Zet de code recht binnen het kader';

  @override
  String get qrFromPhoto => 'Vanaf een foto lezen';

  @override
  String get qrNotFound => 'Geen code gevonden in deze afbeelding';

  @override
  String get qrLinkFound => 'Deze code is een link';

  @override
  String get qrOpenLink => 'Naar de link';

  @override
  String get qrSaveToNote => 'Opslaan in een notitie';

  @override
  String get openLink => 'Link openen';

  @override
  String get linkOpenFailed => 'De link kon niet worden geopend';

  @override
  String qrScanFailed(String error) {
    return 'De code kon niet worden gelezen: $error';
  }

  @override
  String get qrTorch => 'Zaklamp';

  @override
  String attachmentsCount(int count) {
    return 'Bijlagen ($count)';
  }

  @override
  String get hideAttachments => 'Verbergen';

  @override
  String get showAttachments => 'Tonen';

  @override
  String get videoBack10 => '10 s terug';

  @override
  String get videoForward10 => '10 s vooruit';

  @override
  String get selectAllItems => 'Alles selecteren';

  @override
  String get showAllChips => 'Alles tonen';

  @override
  String get hideAllChips => 'Alles verbergen';

  @override
  String get chipPickInfo =>
      'Welke map- en labelchips moeten op het startscherm verschijnen?';

  @override
  String get hiddenFolder => 'Verborgen map';

  @override
  String get hiddenFolderInfo =>
      'Een verborgen map en de notities erin verschijnen niet op het startscherm. Kies «Verborgen mappen» in het ⋮-menu en bevestig je identiteit om ze te tonen.';

  @override
  String get hiddenFoldersMenu => 'Verborgen mappen';

  @override
  String get hiddenFolderAuthReason =>
      'Bevestig je identiteit om verborgen mappen te tonen';

  @override
  String get hiddenFoldersShown => 'Verborgen mappen worden getoond';

  @override
  String get hiddenFoldersHiddenAgain =>
      'Verborgen mappen zijn weer weggestopt';

  @override
  String get makeFolderHidden => 'Verbergen';

  @override
  String get makeFolderVisible => 'Zichtbaar maken';

  @override
  String gridColumnsCount(int count) {
    return '$count kolommen';
  }

  @override
  String get addImageOnPageSubtitle =>
      'Staat op de pagina, de tekst loopt eromheen';

  @override
  String get addImageAsFile => 'Afbeelding als bestand toevoegen';

  @override
  String get addImageAsFileSubtitle =>
      'Blijft buiten de pagina, in de bijlagenbalk';

  @override
  String get moveImageToAttachments => 'Naar bijlagen verplaatsen';

  @override
  String get moveImageToPage => 'Op de pagina plaatsen';

  @override
  String get attachmentCopied => 'Bijlage gekopieerd';

  @override
  String get pasteAttachment => 'Gekopieerde bijlage plakken';

  @override
  String get fullscreen => 'Volledig scherm';

  @override
  String get more => 'Meer';

  @override
  String get undone => 'Ongedaan gemaakt';

  @override
  String get filterOthers => 'Overige';

  @override
  String get chatSuggestion1 =>
      'Wat ontbreekt er aan mijn boodschappenlijstje?';

  @override
  String get chatSuggestion2 => 'Vat de werknotities van deze week samen';

  @override
  String get chatSuggestion3 => 'Heb ik een herinnering voor morgen?';

  @override
  String get aiPointsToday => 'Punten van vandaag';

  @override
  String aiPointsOf(int used, int total) {
    return '$used / $total';
  }

  @override
  String get aiPointsRenew => 'vernieuwt om middernacht';

  @override
  String get aiChatWithNotes => 'Notitie-assistent';

  @override
  String get aiChatInputHint => 'Vraag iets over je notities…';

  @override
  String get aiChatLooking => 'doorzoekt je notities…';

  @override
  String get aiChatFullScreen => 'Volledig scherm';

  @override
  String get aiOnYourNotes => 'OVER JE NOTITIES';

  @override
  String get aiTaskDuplicates => 'Duplicaten opruimen';

  @override
  String aiTaskDuplicatesInfo(int count) {
    return '$count dubbele notities';
  }

  @override
  String get duplicatesTitle => 'Dubbele notities';

  @override
  String get duplicatesHint =>
      'De oudste notitie van elke groep blijft bewaard, de rest gaat naar de prullenbak.';

  @override
  String get duplicatesKeepBadge => 'blijft';

  @override
  String get duplicatesDeleteAll => 'Duplicaten naar prullenbak';

  @override
  String duplicatesDone(int count) {
    return '$count duplicaten naar de prullenbak verplaatst';
  }

  @override
  String get aiRecentActions => 'RECENTE ACTIES';

  @override
  String get aiHistoryClear => 'Wissen';

  @override
  String get aiHistoryQuestion => 'Vraag';

  @override
  String get aiHistoryNoteAction => 'Notitieactie';

  @override
  String get aiHistoryVoiceNote => 'Spraaknotitie';

  @override
  String get aiRecentOps => 'RECENT';

  @override
  String get aiTaskWeekSummary => 'Vat de week samen';

  @override
  String get aiTaskWeekSummaryInfo =>
      'Eén samenvatting van de afgelopen 7 dagen';

  @override
  String get aiTaskTagUntagged => 'Label de notities zonder label';

  @override
  String aiTaskTagUntaggedInfo(int count) {
    return '$count notities wachten op labels';
  }

  @override
  String get aiTaskSuggestTitles => 'Titels voorstellen';

  @override
  String aiTaskSuggestTitlesInfo(int count) {
    return '$count notities hebben geen titel';
  }

  @override
  String get sectionPinnedShort => 'VASTGEZET';

  @override
  String get sectionToday => 'VANDAAG';

  @override
  String get sectionThisWeek => 'DEZE WEEK';

  @override
  String get sectionEarlier => 'EERDER';

  @override
  String sectionNoteCount(int count) {
    return '$count notities';
  }

  @override
  String get emptySearchSemanticHint => 'Probeer het tabblad Betekenis';

  @override
  String get quickCaptureHint => 'Nieuwe notitie…';

  @override
  String get quickCaptureSave => 'Opslaan';

  @override
  String get quickAddWrite => 'SCHRIJVEN';

  @override
  String get quickAddCapture => 'VASTLEGGEN — MAAKT EEN NOTITIE VAN INHOUD';

  @override
  String get viewToggle => 'Weergave';

  @override
  String get searchModeText => 'Tekst';

  @override
  String get searchModeMeaning => 'Betekenis';

  @override
  String get filterReminded => 'Met herinnering';

  @override
  String get filterLocked => 'Vergrendeld';

  @override
  String get sortColor => 'Kleur';

  @override
  String get sortActive => 'Meest bewerkt';

  @override
  String get voicePreview => 'Stem testen';

  @override
  String get voicePreviewCached =>
      'Het voorbeeld wordt één keer gemaakt en daarna lokaal afgespeeld';

  @override
  String get reorderHint =>
      'Houd een kaart ingedrukt en sleep hem naar de gewenste plek';

  @override
  String get filterSheetTitle => 'Filter';

  @override
  String get filterReset => 'Reset';

  @override
  String get filterSectionStatus => 'STATUS';

  @override
  String get filterSectionFolder => 'MAP';

  @override
  String get filterSectionTag => 'TAG';

  @override
  String get filterSectionSort => 'SORTEER';

  @override
  String get filterFavoriteHint =>
      'Tik op een ster om die optie op het startscherm te houden';

  @override
  String get filterSheetSortHint =>
      'Datumgroepen (VANDAAG, DEZE WEEK...) worden alleen getoond bij sortering op laatst bewerkt.';

  @override
  String get formatTitle => 'Opmaak';

  @override
  String get formatBold => 'Vet';

  @override
  String get formatItalic => 'Cursief';

  @override
  String get formatUnderline => 'Onderstreept';

  @override
  String get formatTextColor => 'Tekstkleur';

  @override
  String get formatHighlight => 'Markering';

  @override
  String get formatInfo =>
      'Opmaak reist mee in de tekst als tekens (zoals **vet**); die tekens blijven verborgen bij exporteren en voorlezen.';

  @override
  String get formatMenu => 'Opmaak…';

  @override
  String get noteFont => 'Lettertype';

  @override
  String get noteFontDefault => 'Standaard';

  @override
  String get noteFontSerif => 'Boek (schreef)';

  @override
  String get noteFontMono => 'Schrijfmachine';

  @override
  String get noteTextSize => 'Tekstgrootte';

  @override
  String get formatClear => 'Opmaak wissen';

  @override
  String get noteTextOpacity => 'Dekking';

  @override
  String get assistantVoiceSetting => 'Assistent spreekt antwoorden uit';

  @override
  String get assistantVoiceSettingInfo =>
      'De spraakassistent leest zijn antwoord hardop voor (alleen op de telefoon).';

  @override
  String get assistantMute => 'Geluid uit';

  @override
  String get assistantUnmute => 'Geluid aan';

  @override
  String get assistantMakeNote => 'Toch een notitie maken';

  @override
  String get assistantNoteCreated => 'Notitie gemaakt';

  @override
  String get noteNotFound =>
      'Notitie niet gevonden. Mogelijk is hij verwijderd.';

  @override
  String get back => 'Terug';

  @override
  String get addTextBlock => 'Tekst toevoegen';

  @override
  String get attachNoteContent => 'Notitie-inhoud';

  @override
  String get noteBackgroundImage => 'Achtergrondafbeelding';

  @override
  String get chooseBackgroundImage => 'Afbeelding kiezen';

  @override
  String get changeBackgroundImage => 'Andere afbeelding';

  @override
  String get removeBackgroundImage => 'Achtergrond verwijderen';

  @override
  String get dashboardBackground => 'Achtergrond startscherm';

  @override
  String get dashboardBackgroundInfo =>
      'Afbeelding achter het notitieraster (alleen op dit apparaat).';

  @override
  String get aiProvider => 'AI-aanbieder';

  @override
  String get aiProviderInfo =>
      'Kies de aanbieder waar je sleutel bij hoort. De sleutel van elke aanbieder wordt apart bewaard, dus terugschakelen betekent niet opnieuw typen.';

  @override
  String get apiKeyFieldLabel => 'API-sleutel';

  @override
  String get getApiKey => 'Waar haal ik een sleutel?';

  @override
  String get recommendedModel => 'Aanbevolen';

  @override
  String get freeTierBadge => 'Heeft een gratis pakket';

  @override
  String get continueWithoutAccount => 'Doorgaan zonder account';

  @override
  String get localAccountInfo =>
      'Je notities blijven alleen op dit apparaat: ze zijn nergens anders te openen, ze zijn weg als je de app verwijdert, en de ingebouwde AI staat uit. Je kunt op elk moment een Google-account koppelen — je notities gaan gewoon mee.';

  @override
  String get localAccountBadge => 'Lokaal account';

  @override
  String get linkGoogleAccount => 'Google-account koppelen';

  @override
  String get accountLinked =>
      'Je Google-account is gekoppeld. Je notities hebben nu een back-up.';

  @override
  String scanReviewPage(int current, int total) {
    return 'Pagina ${current} / ${total}';
  }

  @override
  String get scanRotatePage => 'Pagina draaien';

  @override
  String get scanDeletePage => 'Pagina verwijderen';

  @override
  String get scanLastPage => 'De laatste pagina kan niet worden verwijderd';

  @override
  String get scanDiscardTitle => 'Gescande pagina\'s weggooien?';

  @override
  String get scanDiscardConfirm => 'Weggooien';

  @override
  String get scanAdjustCorners => 'Hoeken bijstellen';

  @override
  String get scanFilterOriginal => 'Origineel';

  @override
  String get scanFilterAuto => 'Verbeteren';

  @override
  String get scanFilterGray => 'Grijstinten';

  @override
  String get scanFilterBw => 'Zwart-wit';

  @override
  String get scanApplyAll => 'Op alle toepassen';

  @override
  String get scanPageFailed => 'Kon de pagina niet tonen';

  @override
  String get scanCropHint =>
      'Corrigeer een scheve pagina met "Hoeken bijstellen"';

  @override
  String get scanAddAsPdf => 'Als pdf toevoegen';

  @override
  String get scanAddAsImages => 'Als afbeeldingen toevoegen';

  @override
  String get scanBuildingPdf => 'Pdf wordt voorbereid…';

  @override
  String scanOcrProgress(int done, int total) {
    return 'Tekst herkennen… ${done}/${total}';
  }

  @override
  String get scanAutoDetect => 'Randen automatisch herkennen';

  @override
  String get scanReset => 'Herstellen';

  @override
  String get scanDetecting => 'Randen zoeken…';

  @override
  String get scanAutoFound =>
      'Randen automatisch gevonden; stel ze zo nodig bij met de grepen';

  @override
  String get scanDragHint => 'Sleep de hoeken naar de randen van het papier';

  @override
  String get scanApplyCorners => 'Rechtzetten en toepassen';

  @override
  String get scanWorking => 'Rechtzetten…';

  @override
  String get scanPdfAdded => 'Scan als pdf-bijlage aan de notitie toegevoegd';

  @override
  String get premiumTitle => 'Premium';

  @override
  String premiumStatusActive(String date) {
    return 'Premium actief — tot ${date}';
  }

  @override
  String get premiumStatusFree => 'Je gebruikt de gratis versie';

  @override
  String get premiumPerksTitle => 'Wat verandert er met Premium?';

  @override
  String get premiumPerkAi => 'Dagelijkse AI-punten';

  @override
  String get premiumPerkAttach => 'Bijlagegrootte';

  @override
  String get premiumPerkStorage => 'Cloudopslag';

  @override
  String get premiumPerkAuto => 'Automatische dagelijkse inhoud';

  @override
  String get premiumPerkAutoBody =>
      'De dagelijkse briefing en suggesties worden elke dag automatisch klaargezet; in de gratis versie draaien ze alleen op verzoek.';

  @override
  String get premiumHowTitle => 'Hoe krijg ik het?';

  @override
  String get premiumHowBody =>
      'Premium komt binnenkort via de Play Store. Momenteel zitten we in vroege toegang.';

  @override
  String get premiumByokHint =>
      'Als je je eigen Gemini-API-sleutel invoert, werken de AI-functies zonder quotum — los van Premium (Instellingen → AI).';

  @override
  String get premiumDiscoverTitle => 'Functies die je misschien hebt gemist';

  @override
  String get discoverScanBody =>
      'Gescande pagina\'s worden rechtgezet en verbeterd en met één tik omgezet in een DOORZOEKBARE pdf — de tekstlaag wordt gratis op het toestel gemaakt.';

  @override
  String get discoverSemanticBody =>
      'Het tabblad "Slim" in de zoekbalk zoekt op BETEKENIS in plaats van woorden: typ "vluchttijden" en je reisnotitie verschijnt.';

  @override
  String get discoverAssistantBody =>
      'De microfoon op het startscherm maakt vanzelf notities, lijsten en herinneringen van je spraak — zeg gewoon "morgen om 9 uur naar de tandarts".';

  @override
  String get discoverLockBody =>
      'Je kunt een notitie vergrendelen met vingerafdruk of gezicht: de inhoud lekt nooit naar zoeken, widgets of AI.';

  @override
  String get discoverHiddenBody =>
      'Notities in een verborgen map verschijnen nooit op het startscherm of in zoeken; de map tonen vraagt om verificatie.';

  @override
  String get discoverExportBody =>
      'Elke notitie kun je exporteren als pdf of Word, inclusief afbeeldingen (in het deelmenu).';

  @override
  String get guestSignInUnavailable =>
      'Inloggen zonder Google staat uit: anoniem inloggen is niet ingeschakeld in de Firebase-console. Log in met Google of probeer het opnieuw zodra een beheerder het inschakelt.';

  @override
  String get googleSignInUnavailable =>
      'Inloggen met Google staat uit: de Google-provider is niet ingeschakeld in de Firebase-console.';

  @override
  String get signInNetworkError =>
      'Geen internetverbinding. Controleer je verbinding en probeer het opnieuw.';

  @override
  String get signInCanceled => 'Inloggen geannuleerd.';

  @override
  String get cardRichPreview => 'Opgemaakte tekst op kaarten';

  @override
  String get cardRichPreviewInfo =>
      'Kleuren, markeringen, vet en onderstrepingen uit je notities zijn ook op de kaarten op het startscherm te zien. Uit: kaarten tonen platte tekst.';

  @override
  String get fontSizeSmall => 'Klein';

  @override
  String get fontSizeMedium => 'Normaal';

  @override
  String get fontSizeLarge => 'Groot';

  @override
  String get fontSizeXLarge => 'Zeer groot';

  @override
  String get appFontSetting => 'Lettertype';

  @override
  String get appFontInfo =>
      'Het lettertype in de hele app. Het eigen lettertype van een notitie gaat voor. Alle lettertypen zitten in de app — geen internet nodig.';

  @override
  String get fontGroupSans => 'Schreefloos';

  @override
  String get fontGroupSerif => 'Schreef';

  @override
  String get fontGroupMono => 'Monospace';

  @override
  String get fontGroupHand => 'Handschrift';

  @override
  String get appFontDefaultSuffix => 'standaard';

  @override
  String get pdfSelectOcrRunning => 'Tekst herkennen…';

  @override
  String get pdfSelectOcrNone => 'Geen tekst gevonden op deze pagina';

  @override
  String pdfSelectCopied(int n) {
    return '${n} tekens gekopieerd';
  }

  @override
  String get bubbleAdd => 'Notitieballon plaatsen';

  @override
  String get bubbleAddDone => 'Klaar met ballonnen plaatsen';

  @override
  String get bubbleCollapse => 'Ballon inklappen';

  @override
  String get bubbleHint => 'Schrijf hier je notitie…';

  @override
  String get bubbleTapToPlace => 'Tik op de plek op de pagina waar de ballon moet komen';

  @override
  String get aiModelPodcast => 'Podcastvertelling';

  @override
  String get listenAiVoice => 'Beluisteren met AI-stem';

  @override
  String get listenAiVoiceInfo =>
      'Gemini leest voor in plaats van de stem van het toestel: natuurlijker, maar elke alinea kost een modelaanroep.';

  @override
  String listenAiVoiceFailed(String error) {
    return 'AI-vertelling mislukt (${error}). Er wordt voorgelezen met de stem van het toestel.';
  }

  @override
  String get ttsSectionTitle => 'Vertelling';

  @override
  String get ttsEngineDevice => 'Stem van het toestel';

  @override
  String get ttsEngineAi => 'AI';

  @override
  String get ttsEngineDeviceInfo =>
      'De ingebouwde stem van het toestel leest voor: gratis, offline en zonder lengtelimiet.';

  @override
  String get ttsEngineAiInfo =>
      'Het spraakmodel van Gemini leest voor: merkbaar natuurlijker, maar elke alinea is een modelaanroep en je hebt je eigen Gemini-sleutel nodig.';

  @override
  String get ttsEngineAiUnavailable =>
      'De AI-stem vereist je eigen Gemini-sleutel. Tot die tijd leest de apparaatstem voor.';

  @override
  String get ttsModel => 'Spraakmodel';

  @override
  String get ttsVoice => 'AI-stem';

  @override
  String get shareAsNote => 'Delen als notitie';

  @override
  String get shareAsNoteInfo =>
      'Verstuurt de notitie met bijlagen, paginanotities, tekeningen en ballonnen; aan de andere kant opent die precies hetzelfde in de Not-app.';

  @override
  String get shareAsNotePreparing => 'Notitiepakket wordt voorbereid…';

  @override
  String get shareAsText => 'Als platte tekst';

  @override
  String get shareAsTextInfo =>
      'Stuurt de tekst van de notitie en de paginanotities naar een willekeurige app.';

  @override
  String get shareAsTextEmpty => 'Deze notitie heeft geen tekst om te delen.';

  @override
  String get sharePdfWithBubbles => 'Als pdf met ballonnen';

  @override
  String get sharePdfWithBubblesInfo =>
      'Ballonnen, markeringen en tekeningen worden in de pdf gebrand; iedereen kan hem openen en in Not opent hij bewerkbaar.';

  @override
  String get sharePdfWithBubblesNone =>
      'Deze notitie heeft geen pdf met ballonnen of tekeningen.';

  @override
  String get sharePdfWithBubblesPreparing =>
      'Pdf met ballonnen wordt voorbereid…';

  @override
  String get sharePdfWithBubblesSuffix => ' (met ballonnen)';

  @override
  String get bubbleStar => 'Markeren';

  @override
  String get bubbleEdit => 'Ballon bewerken';

  @override
  String get bubbleStarredOnly => 'Alleen gemarkeerde';

  @override
  String get bubbleSearchHint => 'Ballonnen doorzoeken…';

  @override
  String get bubblesOverviewTitle => 'Ballonnen';

  @override
  String get bubblesEmpty =>
      'Nog geen ballonnen. Selecteer tekst in het document en markeer die, of plaats een ballon op de pagina.';

  @override
  String get bubblesNoMatch => 'Geen ballon komt overeen met je zoekopdracht.';

  @override
  String get bubbleNoText => '(lege ballon)';

  @override
  String get pdfHighlight => 'Markeren';

  @override
  String get pdfHighlightWithNote => 'Markeren + notitie';

  @override
  String get pageNotesShow => 'Paginanotitie tonen';

  @override
  String get pageNotesHide => 'Paginanotitie verbergen';

  @override
  String get bubbleSave => 'Opslaan';

  @override
  String get bubbleTitleHint => 'Titel';

  @override
  String get bubbleUrgent => 'Dringend (knippert)';

  @override
  String get captureModeQuestion => 'Hoe moet de notitie openen?';

  @override
  String get captureModeBubbles => 'Ballonnen';

  @override
  String get captureModeBubblesInfo =>
      'De inhoud wordt een documentpagina: ballonnen, markeringen en pen.';

  @override
  String get captureModeClassic => 'Klassiek';

  @override
  String get captureModeClassicInfo =>
      'Gewone tekstnotitie; de inhoud komt er als bijlage in.';

  @override
  String get captureModeNew => 'NIEUW';

  @override
  String get imagePrepareTitle => 'Afbeeldingen bijstellen';

  @override
  String get imagePrepareDone => 'Doorgaan';

  @override
  String get imageRotateLeft => 'Naar links draaien';

  @override
  String get imageRotateRight => 'Naar rechts draaien';

  @override
  String get videoFrameFailed =>
      'Kon geen beeld uit de video halen; er wordt een klassieke notitie geopend.';

  @override
  String get bubbleArrowHide => 'Pijl verbergen';

  @override
  String get bubbleArrowShow => 'Pijl tonen';

  @override
  String get speechPitch => 'Toonhoogte';

  @override
  String get speechVoicePickerTitle => 'Stemkeuze';

  @override
  String get formatRemove => 'Verwijderen';

  @override
  String get exportTitle => 'Exporteren';

  @override
  String get exportNotesOption => 'Notitietekst (PDF / Word)';

  @override
  String get exportNotesOptionInfo =>
      'Tekst en afbeeldingen van de notitie; ballonnen niet inbegrepen.';

  @override
  String get captureNoteTitle => 'Notitietitel (optioneel)';

  @override
  String get captureNoteTitleHint => 'Het nieuwe document krijgt deze naam ook';

  @override
  String get imageOcrTitle => 'Tekst in afbeelding herkennen';

  @override
  String get imageOcrNone => 'Geen tekst gevonden in deze afbeelding.';

  @override
  String imageOcrHint(int count) {
    return '$count regels herkend · tik om te selecteren';
  }

  @override
  String imageOcrSelected(int count) {
    return '$count regels geselecteerd';
  }

  @override
  String get imageOcrShort => 'Tekst herkennen';

  @override
  String get imageOcrWorking => 'Tekst herkennen…';

  @override
  String get imageOcrSelectHint =>
      'Tik: woord · Houd vast en sleep: letter voor letter';

  @override
  String get imageOcrInsert => 'Aan notitie toevoegen';

  @override
  String get imageOcrZoomIn => 'Inzoomen';

  @override
  String get imageOcrZoomOut => 'Uitzoomen';

  @override
  String get selectImages => 'Afbeeldingen selecteren';

  @override
  String get exportImages => 'Afbeeldingen';

  @override
  String get exportImagesInfo =>
      'Tekst loopt naast smalle afbeeldingen die links of rechts staan; gecentreerde afbeeldingen nemen de volle breedte.';

  @override
  String get exportAlignLeft => 'Links';

  @override
  String get exportAlignCenter => 'Midden';

  @override
  String get exportAlignRight => 'Rechts';

  @override
  String get exportImageWidth => 'Breedte';

  @override
  String get exportImageLine => 'Positie';

  @override
  String get aiModelSearch => 'Modellen zoeken';

  @override
  String get aiModelOthers => 'OVERIGE MODELLEN';

  @override
  String get aiModelNoMatch => 'Geen overeenkomend model.';

  @override
  String get aiModelAutoInfo =>
      'De app probeert de meest geschikte modellen op volgorde.';

  @override
  String imageOcrCharsSelected(int count) {
    return '$count tekens geselecteerd';
  }

  @override
  String imagesSelectedCount(int count) {
    return '$count afbeeldingen geselecteerd';
  }

  @override
  String attachmentsCopiedCount(int count) {
    return '$count bijlagen';
  }

  @override
  String exportImageLineOf(int count) {
    return '/ $count regels';
  }

  @override
  String get aiModelShowAll => 'Alles tonen';

  @override
  String get aiModelShowAllInfo =>
      'Toont ook modellen die de app niet gebruikt.';

  @override
  String get rotateFailed => 'Kon de afbeelding niet draaien.';

  @override
  String get dashboardBackgroundPick => 'Achtergrondafbeelding kiezen';

  @override
  String get dashboardBackgroundChange => 'Achtergrondafbeelding wijzigen';

  @override
  String podcastRenderingAudio(int done, int total) {
    return 'Audio wordt voorbereid: ${done}/${total} delen';
  }

  @override
  String get podcastExportAudio => 'Exporteren als audiobestand';

  @override
  String get podcastExportAudioCost =>
      'Het hele script wordt opnieuw ingesproken met de AI-stem en als één WAV-bestand opgeslagen. Dit verbruikt je Gemini-quotum en kan bij lange teksten enkele minuten duren.';

  @override
  String get podcastShareText => 'Script delen';

  @override
  String get podcastSaveAsNote => 'Opslaan als nieuwe notitie';

  @override
  String get podcastSavedAsNote => 'Het podcastscript is als notitie opgeslagen.';

  @override
  String get listenPreparingVoice => 'Audio wordt voorbereid…';

  @override
  String get appearancePreviewTitle => 'Voorbeeldtekst';

  @override
  String get appearancePreviewNoteTitle => 'Voorbeeld-notitietitel';

  @override
  String get appearancePreviewBody =>
      'Zo komen je notities eruit te zien. **Vet**, ~onderstreept~ en ==2:gemarkeerd== in de tekst ziet er zo uit.';

  @override
  String get appearancePreviewItem => 'Zo ziet een lijstitem eruit';

  @override
  String get convertToText => 'Omzetten naar tekst';

  @override
  String get convertToList => 'Omzetten naar lijst';

  @override
  String get convertedToText => 'De lijst is omgezet naar gewone tekst.';

  @override
  String get convertedToList => 'De tekst is omgezet naar een lijst.';

  @override
  String get convertToListEmpty => 'Er zijn geen regels om in een lijst om te zetten.';

  @override
  String get listTwoColumns => 'Twee kolommen';

  @override
  String get listOneColumn => 'Eén kolom';

  @override
  String get sortItems => 'Items sorteren';

  @override
  String get sortStarredFirst => 'Gemarkeerde eerst';

  @override
  String get sortUncheckedFirst => 'Afgeronde als laatste';

  @override
  String get sortAlphabetical => 'A → Z';

  @override
  String get sortAlphabeticalDesc => 'Z → A';

  @override
  String get imagesToAttachments => 'Afbeeldingen naar bijlagen verplaatsen';

  @override
  String imagesToAttachmentsDone(int count) {
    return '${count} afbeeldingen naar de bijlagen verplaatst.';
  }

  @override
  String get imageOcrShowRecognized => 'Herkende tekst markeren';

  @override
  String get imageOcrHideRecognized => 'Markering verbergen';

  @override
  String get bubblePlainMode => 'Open tekstvak';

  @override
  String get bubblePlainModeOn => 'Open tekstvak staat aan';

  @override
  String get bubblePlainTapToPlace => 'Tik waar de tekst moet komen';

  @override
  String get bubblePlainHint => 'Tik om te schrijven';

  @override
  String get noteSearchTitle => 'In de notitie zoeken';

  @override
  String get noteSearchHint => 'In deze notitie zoeken…';

  @override
  String get noteSearchEmptyHint =>
      'Doorzoekt direct de notitietekst, items en paginanotities. Start de scan hieronder om ook in afbeeldings- en pdf-bijlagen te zoeken.';

  @override
  String get noteSearchNoHit => 'Geen resultaten gevonden.';

  @override
  String get noteSearchScanAttachments => 'Bijlagen scannen';

  @override
  String get noteSearchAskAi => 'De AI vragen';

  @override
  String get noteTitleLabel => 'Titel';

  @override
  String get noteBodyLabel => 'Notitietekst';

  @override
  String get itemLabel => 'Item';

  @override
  String noteSearchAttachmentsInfo(int count) {
    return '${count} bijlagen kunnen worden gescand (afbeelding/pdf).';
  }

  @override
  String noteSearchAttachmentsReady(int count) {
    return 'Er wordt ook in ${count} bijlagen gezocht.';
  }

  @override
  String pageLabel(int page) {
    return 'Pagina ${page}';
  }

  @override
  String get archiveNotebook => 'Archiefschrift';

  @override
  String get archiveNotebookInfo =>
      'Een schrift met eigen pagina\'s dat kopieën van belangrijke documenten en afbeeldingen bewaart.';

  @override
  String get archivePageImages => 'Afbeeldingen';

  @override
  String get archivePageVideos => 'Video\'s';

  @override
  String get archivePageDocuments => 'Documenten';

  @override
  String get archivePageTexts => 'Teksten';

  @override
  String get archiveNewPage => 'Nieuwe pagina';

  @override
  String get archivePageName => 'Paginanaam (bijv. Facturen)';

  @override
  String get archivePageEmpty => 'Deze pagina is leeg.';

  @override
  String get archiveSearchHint => 'In het schrift zoeken…';

  @override
  String get archiveAddText => 'Tekst toevoegen';

  @override
  String get archiveAddFile => 'Bestand toevoegen';

  @override
  String get archiveCopyHere => 'Kopiëren naar een archiefschrift';

  @override
  String get archiveNoNotebook =>
      'Nog geen archiefschrift. Maak er eerst een aan.';

  @override
  String get archiveNothingToCopy => 'Deze notitie heeft geen bijlagen om te kopiëren.';

  @override
  String archiveDeleteEntry(String name) {
    return '"${name}" uit het schrift verwijderen? Deze kopie is definitief weg.';
  }

  @override
  String archiveCopied(int count) {
    return '${count} bestanden naar het archiefschrift gekopieerd.';
  }

  @override
  String get archiveCaptureTitle => 'Vastleggen vanaf afbeelding';

  @override
  String get archiveCapturePage => 'Pagina';

  @override
  String get archiveCapturePageInfo =>
      'Het type dat de AI voorstelde. Laat je het leeg, dan komt het op de pagina Teksten.';

  @override
  String get archiveCaptureText => 'Herkende tekst';

  @override
  String get attachmentTagInsert => 'In de tekst invoegen';

  @override
  String get attachmentTagInserted => 'Het bijlagelabel is ingevoegd.';

  @override
  String get attachmentTagPreview => 'Bijlage bekijken';

  @override
  String get attachmentTagEdit => 'Bijlage bewerken';

  @override
  String archiveCardSummary(int files, int texts) {
    return '${files} bestanden · ${texts} teksten';
  }

  @override
  String get archiveEntryTitle => 'Titel';

  @override
  String get archiveLinkedFile => 'Gekoppeld bestand';

  @override
  String get archiveNoLink => 'Geen gekoppeld bestand';

  @override
  String get attachmentTagEmbed => 'Bijlage in de selectie insluiten';

  @override
  String get attachmentTagNoAttachment =>
      'Voeg eerst een bestand aan de notitie toe, daarna kun je het in de tekst insluiten.';

  @override
  String get bubbleModeBubble => 'Ballon';

  @override
  String get attachmentTagEmbedInfo =>
      'Koppelt aan de geselecteerde tekst, of aan de cursor als er niets is geselecteerd';

  @override
  String get attachmentTagPickText =>
      'Selecteer nu de tekst om te koppelen en tik daarna op "Hier koppelen".';

  @override
  String get attachmentTagLinkHere => 'Hier koppelen';

  @override
  String attachmentTagPendingBanner(String name) {
    return '${name} wordt gekoppeld — selecteer de tekst';
  }

  @override
  String get docNameNotesSuffix => 'notities';

  @override
  String get docNamePhoto => 'Fotonotities';

  @override
  String get docNameScan => 'Scannotities';

  @override
  String get docNameImage => 'Afbeeldingsnotities';

  @override
  String get docNameVideo => 'Videonotities';

  @override
  String get folderManage => 'Map beheren';

  @override
  String get folderEmpty => 'Deze map is leeg';

  @override
  String get folderEmptyHint =>
      'Voeg hieronder met + een notitie toe, of verplaats een notitie hierheen tijdens het bewerken.';

  @override
  String get brainstormTitle => 'Brainstormen met AI';

  @override
  String get brainstormRowInfo =>
      'De AI schetst eerst een opzet, daarna bouwen jullie er samen op verder';

  @override
  String get brainstormIntro =>
      'Tik op een van de koppen hierboven of typ gewoon — laten we samen nadenken.';

  @override
  String get brainstormOutlineTitle => 'OPZET';

  @override
  String get brainstormInputHint => 'Schrijf een idee of stel een vraag…';

  @override
  String get brainstormAddIdea => 'Aan notitie toevoegen';

  @override
  String get brainstormAdded => 'Aan de notitie toegevoegd';

  @override
  String get folderShared => 'Deze map is gedeeld met een vriend';

  @override
  String get friendsTitle => 'Contacten';

  @override
  String get friendsAdd => 'Vriend toevoegen';

  @override
  String get friendsEmpty =>
      'Nog niemand. Voeg een vriend toe via e-mail om mappen met diegene te delen.';

  @override
  String get friendsRequestsTitle => 'VERZOEKEN';

  @override
  String get friendsListTitle => 'MIJN VRIENDEN';

  @override
  String get friendsAddEmailHint => 'vriend@email.com';

  @override
  String get friendsSendRequest => 'Verzoek versturen';

  @override
  String get friendsRequestSent => 'Verzoek verstuurd';

  @override
  String get friendsNotFound =>
      'Er is niemand geregistreerd met dit e-mailadres. Diegene moet de app minstens één keer met een Google-account hebben geopend.';

  @override
  String get friendsSelf => 'Je kunt jezelf niet als vriend toevoegen';

  @override
  String get friendsAlready => 'Jullie zijn al vrienden';

  @override
  String get friendsDecline => 'Weigeren';

  @override
  String get friendsAccept => 'Accepteren';

  @override
  String get friendsRemove => 'Verwijderen';

  @override
  String get friendsRemoveConfirmTitle => 'Vriend verwijderen';

  @override
  String friendsRemoveConfirmBody(Object name) {
    return '${name} uit je vrienden verwijderen? Mappen die je hebt gedeeld, zijn dan niet meer zichtbaar.';
  }

  @override
  String get friendsNeedsAccount =>
      'Contacten en het delen van mappen vragen om een gekoppeld Google-account.';

  @override
  String get friendsSearchHint => 'Zoeken op naam of e-mail';

  @override
  String get friendsSearchTab => 'Zoeken';

  @override
  String get friendsSearchEmailTab => 'Via e-mail';

  @override
  String get friendsSearchEmpty => 'Geen resultaten';

  @override
  String get friendsSearchTooShort => 'Typ minstens 2 tekens om te zoeken';

  @override
  String get friendsSearchAdd => 'Toevoegen';

  @override
  String get folderShare => 'Delen';

  @override
  String folderShareCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Gedeeld met ${count} personen',
      one: 'Gedeeld met 1 persoon',
    );
    return '$_temp0';
  }

  @override
  String folderShareTitle(Object name) {
    return '"${name}" delen';
  }

  @override
  String get folderShareInfo =>
      'Er gaat een uitnodiging naar de vriend die je kiest; die ziet de map zodra hij accepteert. Jij kiest de rechten (lezen / schrijven / beide).';

  @override
  String get friendsRowInfo => 'Vrienden toevoegen, mappen met ze delen';

  @override
  String get accountRecoverConflictTitle =>
      'Dit toestel heeft niet-opgeslagen notities';

  @override
  String accountRecoverConflictBody(Object count) {
    return 'Dit Google-account is al aan een andere sessie gekoppeld; overschakelen verbergt de ${count} notitie(s) op dit toestel (ze worden niet verwijderd, alleen niet meer bereikbaar vanaf hier). Toch doorgaan?';
  }

  @override
  String get accountRecoverConflictProceed => 'Toch overschakelen';
  @override
  String get folderRoleRead => 'Lezen';

  @override
  String get folderRoleWrite => 'Schrijven';

  @override
  String get folderRoleBoth => 'Lezen + schrijven';

  @override
  String get folderInvitePending => 'Uitnodiging verstuurd, wacht op antwoord';

  @override
  String get folderWriteOnlyTitle => 'Je hebt alleen schrijftoegang';

  @override
  String get folderWriteOnlyHint => 'Je kunt nieuwe notities in deze map zetten, maar de notities erin niet zien.';

  @override
  String get folderChatTitle => 'Chat';

  @override
  String get folderChatHint => 'Schrijf een bericht…';

  @override
  String get folderChatSend => 'Versturen';

  @override
  String get folderChatEmptyTitle => 'Nog geen berichten';

  @override
  String get folderChatEmptyHint => 'Praat hier met de mensen met wie je deze map hebt gedeeld.';

  @override
  String get folderInviteTitle => 'Mapuitnodiging';

  @override
  String folderInviteBody(Object name) {
    return 'De map "${name}" is met je gedeeld.';
  }

  @override
  String get folderInviteAccepted => 'Map toegevoegd';

  @override
  String get folderInviteDeclined => 'Uitnodiging geweigerd';

  @override
  String friendRequestBanner(Object name) {
    return '${name} heeft je een vriendschapsverzoek gestuurd';
  }

  @override
  String get friendRequestAccepted => 'Vriend toegevoegd';

  @override
  String get sendNoteAction => 'Naar een vriend sturen';

  @override
  String get sendNoteTitle => 'De notitie naar een vriend sturen';

  @override
  String get sendNoteInfo => 'Een kopie van de notitie komt in de map "Binnengekomen notities" van die persoon. Bijlagen (afbeeldingen, documenten, audio) worden niet meegestuurd.';

  @override
  String sendNoteSent(Object name) {
    return 'Notitie verstuurd naar ${name}';
  }

  @override
  String get inboxTitle => 'Binnengekomen notities';

  @override
  String get inboxEmpty => 'Geen binnengekomen notities';

  @override
  String get inboxEmptyHint => 'Notities die je vrienden je sturen, verzamelen zich hier.';

  @override
  String inboxFrom(Object name) {
    return 'Verstuurd door ${name}';
  }

  @override
  String get inboxAccept => 'Aan mijn notities toevoegen';

  @override
  String get inboxAccepted => 'Notitie aan je notities toegevoegd';

  @override
  String get folderShelfExpand => 'Mappen uitklappen';

  @override
  String get folderShelfCollapse => 'Mappen inklappen';

  @override
  String get accountSheetLocalInfo => 'Je notities staan alleen op dit toestel. Koppel een Google-account om er een back-up van te maken en vrienden toe te voegen.';

  @override
  String get accountSettings => 'Accountinstellingen';
}
