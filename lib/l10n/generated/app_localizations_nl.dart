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
  String get attachmentUploading => 'Uploaden...';

  @override
  String get attachmentUploadFailed =>
      'Yüklenemedi — yeniden denemek için dokun';

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
    return 'Asistan \"$title\" notunu çöp kutusuna taşımak istiyor. Onaylıyor musun?';
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
  String get aiModelDocument => 'Podcasts en documentchat';

  @override
  String get aiModelTranslate => 'Vertaling';

  @override
  String get aiModelVoice => 'Spraaknotities';

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
  String get attachNoteContent => 'Not içeriği';

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
}
