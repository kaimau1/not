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
  String get voiceCaptureAi => 'Sesli yakala (yapay zekâ)';

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
  String get newPdfNote => 'PDF\'ten not';

  @override
  String get imageNotePreparing =>
      'Afbeeldingen worden tot een document samengevoegd…';

  @override
  String get newImageNote => 'Afbeelding toevoegen en notities maken';

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
  String get newSlidesNote => 'Sunumdan not';

  @override
  String get slidesNoDocument => 'Bu notta henüz sunum yok';

  @override
  String get slidesChooseDocument => 'Sunum seç';

  @override
  String get pdfEditPages => 'Sayfaları düzenle';

  @override
  String get pdfDeletePages => 'Seçili sayfaları sil';

  @override
  String get pdfAddBlankPage => 'Lege pagina toevoegen';

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
  String get formatHeading => 'Başlık';

  @override
  String get formatHeading1 => 'Büyük başlık';

  @override
  String get formatHeading2 => 'Alt başlık';

  @override
  String get formatNormalText => 'Normal metin';

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
      'De AI-stem vereist je eigen Gemini-sleutel. Tot die tijd leest de apparaatstem voor.';

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
  String get collaborators => 'Medewerkers';

  @override
  String get collaboratorsInfo =>
      'Mensen die je toevoegt zien deze notitie op hun startscherm en bewerken hem tegelijk met jou.';

  @override
  String get collaboratorsOwner => 'Eigenaar';

  @override
  String get collaboratorsFriendsTitle => 'JE VRIENDEN';

  @override
  String get collaboratorsLeave => 'Gedeelde notitie verlaten';

  @override
  String get collaboratorsLeaveConfirm =>
      'Deze notitie verschijnt niet meer op je startscherm. Verlaten?';

  @override
  String get collaboratorsSaved => 'Delen bijgewerkt';

  @override
  String collaboratorsCount(int count) {
    return 'Gedeeld met $count personen';
  }

  @override
  String get collaboratorsOnlyOwner =>
      'Alleen de eigenaar van de notitie kan medewerkers wijzigen.';

  @override
  String get sharedWithMe => 'Met mij gedeeld';

  @override
  String get sharedWithMeEmpty =>
      'Er zijn nog geen notities met je gedeeld. Ze verschijnen hier zodra iemand je aan een notitie toevoegt.';

  @override
  String sharedByName(Object name) {
    return 'Gedeeld door $name';
  }

  @override
  String get navNotes => 'Notities';

  @override
  String get railExpand => 'Menu uitvouwen';

  @override
  String get railCollapse => 'Menu samenvouwen';

  @override
  String get newNoteShort => 'Nieuwe notitie';

  @override
  String get newChecklistShort => 'Nieuwe lijst';

  @override
  String get listPaneHide => 'Notitielijst verbergen';

  @override
  String get listPaneShow => 'Notitielijst tonen';

  @override
  String get keyboardShortcuts => 'Sneltoetsen';

  @override
  String get shortcutSearch => 'Notities doorzoeken';

  @override
  String get shortcutToggleList => 'Notitielijst verbergen / tonen';

  @override
  String get shortcutSections => 'Wisselen tussen onderdelen';

  @override
  String get shortcutHelp => 'Sneltoetsen tonen';

  @override
  String get noNoteSelectedHint => 'of begin een nieuwe notitie';

  @override
  String get loginFeatureSyncTitle => 'Dezelfde notities op elk apparaat';

  @override
  String get loginFeatureSyncBody =>
      'Direct gesynchroniseerd tussen telefoon, tablet, computer en web.';

  @override
  String get loginFeatureAiTitle => 'AI aan je zijde';

  @override
  String get loginFeatureAiBody =>
      'Samenvatten, vragen, dicteren; chat met je documenten.';

  @override
  String get loginFeatureShareTitle => 'Samen schrijven';

  @override
  String get loginFeatureShareBody =>
      'Deel notities en mappen live met vrienden.';

  @override
  String get loginFeatureInkTitle => 'Pen en PDF';

  @override
  String get loginFeatureInkBody =>
      'Maak handgeschreven notities, schrijf op PDF\'s en dia\'s.';

  @override
  String get foldersTitle => 'Mappen';

  @override
  String get foldersEmpty =>
      'Nog geen mappen. Maak er een om je notities te ordenen.';

  @override
  String get folderColor => 'Kleur';

  @override
  String get folderColorAuto => 'Automatisch';

  @override
  String get foldersMine => 'Mijn mappen';

  @override
  String get foldersSharedSection => 'Met mij gedeelde mappen';

  @override
  String trashDaysShort(int count) {
    return '$count d';
  }

  @override
  String get trashTodayShort => 'Vandaag';

  @override
  String get trashSoonSection => 'Binnenkort definitief verwijderd';

  @override
  String get trashRestSection => 'Andere verwijderde notities';

  @override
  String get aiHubTagline => 'Vraag, vat samen en ruim je notities op.';

  @override
  String get aiToolsSection => 'Hulpmiddelen';

  @override
  String get folderOrderTitle => 'Mapvolgorde';

  @override
  String get folderReorder => 'Mappen herschikken';

  @override
  String get folderOrderManual => 'Eigen';

  @override
  String get folderOrderName => 'Op naam';

  @override
  String get folderOrderNewest => 'Nieuwste eerst';

  @override
  String get folderOrderNoteCount => 'Op aantal notities';

  @override
  String get folderOrderHint =>
      'Sleep aan de grepen om te herschikken. Dezelfde volgorde geldt in de mappenbalk en bij vegen.';

  @override
  String get swipeModeTitle => 'Vegen op het startscherm';

  @override
  String get swipeModeFolders => 'Wisselen tussen mappen';

  @override
  String get swipeModeFilters => 'Wisselen tussen filters en labels';

  @override
  String get swipeModeBoth => 'Mappen, filters en labels';

  @override
  String get swipeModeOff => 'Uit';

  @override
  String get shareIncludeTitle => 'Titel';

  @override
  String get shareIncludeChecked => 'Afgevinkt';

  @override
  String get shareIncludeTags => 'Labels';

  @override
  String get shareTextAction => 'Tekst delen';

  @override
  String get shareAsFileSection => 'Als bestand';

  @override
  String get shareInAppSection => 'In de app';

  @override
  String get shareSendFriendInfo =>
      'Zet een kopie van de notitie in de inbox van een vriend.';

  @override
  String get shareCollaborateInfo =>
      'Bewerk dezelfde notitie samen met vrienden; wijzigingen verschijnen direct.';

  @override
  String get findPrevious => 'Vorige treffer';

  @override
  String get findNext => 'Volgende treffer';

  @override
  String get findShowAll => 'Alle treffers';

  @override
  String findMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count treffers',
      one: '1 treffer',
      zero: 'Geen treffers',
    );
    return '$_temp0';
  }

  @override
  String get findDeepSearch => 'Zoeken in bijlagen en met AI';

  @override
  String get notesSettingsTitle => 'Notities en mappen';

  @override
  String get noteViewSetting => 'Weergave startscherm';

  @override
  String get noteViewGrid => 'Raster';

  @override
  String get noteViewList => 'Lijst';

  @override
  String get gridColumnsSetting => 'Kolommen';

  @override
  String get gridColumnsInfo =>
      'Je kunt het ook wijzigen door te knijpen op het startscherm.';

  @override
  String get gridColumnsAuto => 'Automatisch';

  @override
  String get folderShelfSetting => 'Mappen op het startscherm';

  @override
  String get folderShelfStrip => 'Eén rij';

  @override
  String get folderShelfTiles => 'Tegels';

  @override
  String get deviceStorageTitle => 'Op dit apparaat';

  @override
  String get deviceStorageAttachments => 'Bijlagen';

  @override
  String get deviceStorageDatabase => 'Lokale kopie van notities';

  @override
  String get deviceStorageCache => 'Cache en tijdelijke bestanden';

  @override
  String get deviceStorageAi => 'AI-cache';

  @override
  String get deviceStorageTotal => 'Totaal (zonder de app zelf)';

  @override
  String get deviceStorageInfo =>
      'Cache legen verwijdert geen notities of bijlagen; afbeeldingen worden opnieuw geladen wanneer nodig. Oude tijdelijke bestanden worden bij elke start opgeruimd.';

  @override
  String get deviceStorageClear => 'Cache legen';

  @override
  String deviceStorageCleared(String size) {
    return '$size vrijgemaakt';
  }

  @override
  String get deviceStorageUnavailable =>
      'Kon op dit apparaat niet worden gemeten.';

  @override
  String get localOnlyTurnOn => 'Synchronisatie uit';

  @override
  String get localOnlyTurnOff => 'Deze notitie synchroniseren';

  @override
  String get localOnlyBadge => 'Alleen op dit apparaat';

  @override
  String get localOnlyConfirmTitle =>
      'Deze notitie alleen op dit apparaat houden?';

  @override
  String get localOnlyConfirmBody =>
      'De notitie en bijlagen worden uit de cloud verwijderd en verschijnen niet op je andere apparaten. Als je de app verwijdert of van telefoon wisselt, is deze notitie ook weg. Je kunt synchronisatie altijd weer aanzetten.';

  @override
  String get localOnlyConfirm => 'Synchronisatie uit';

  @override
  String get localOnlyOnDone => 'De notitie staat nu alleen op dit apparaat';

  @override
  String get localOnlyOffDone => 'De notitie synchroniseert weer';

  @override
  String get localOnlySharedBlocked =>
      'Synchronisatie van een gedeelde notitie kan niet uit';

  @override
  String get localOnlyDownloadFailed =>
      'Sommige bijlagen konden niet worden gedownload. Controleer je verbinding en probeer opnieuw; de notitie is niet gewijzigd.';

  @override
  String get templatesTitle => 'Sjablonen';

  @override
  String get templatesSubtitle =>
      'Begin met een kant-en-klare opzet; alles is later aan te passen.';

  @override
  String get fromTemplate => 'Van sjabloon';

  @override
  String get tplShoppingName => 'Boodschappenlijst';

  @override
  String get tplShoppingItems => 'Brood, Melk, Eieren, Fruit, Groente';

  @override
  String get tplShoppingDesc => 'Vink af wat je kocht; het zakt naar onder';

  @override
  String get tplTodoDesc => 'Lege lijst met de datum van vandaag';

  @override
  String get tplTravelName => 'Paklijst';

  @override
  String get tplTravelItems =>
      'ID / paspoort, Oplader, Medicijnen, Tandenborstel, Kleding, Koptelefoon';

  @override
  String get tplTravelDesc => 'Kant-en-klare checklist';

  @override
  String get tplMeetingDesc => 'Deelnemers, agenda, besluiten';

  @override
  String get tplJournalDesc => 'Hoe was vandaag, dankbaarheid, morgen';

  @override
  String get tplRecipeName => 'Recept';

  @override
  String get tplRecipeMeta => 'Porties: · Tijd:';

  @override
  String get tplRecipeIngredients => 'Ingrediënten';

  @override
  String get tplRecipeSteps => 'Bereiding';

  @override
  String get tplRecipeNotes => 'Notities';

  @override
  String get tplRecipeDesc => 'Ingrediënten en stappen';

  @override
  String get tplWeeklyName => 'Weekplanning';

  @override
  String get tplWeeklyDesc => 'De dagen van deze week als kopjes';

  @override
  String get tplExpenseDesc => 'Datum, omschrijving, bedrag';

  @override
  String get tplReadingDesc => 'Bron, samenvatting, citaten';

  @override
  String get settingsThemeHeader => 'Thema';

  @override
  String get settingsCardsHeader => 'Kaarten en lijsten';

  @override
  String get shareTargetTitle => 'Toevoegen aan Notities';

  @override
  String get shareTargetNew => 'Nieuwe notitie';

  @override
  String get shareTargetExisting => 'Bestaande notitie';

  @override
  String get shareTargetCreate => 'Notitie maken';

  @override
  String get shareTargetSearch => 'Notities zoeken';

  @override
  String get shareTargetNoNotes => 'Geen notities beschikbaar';

  @override
  String get shareTargetNoMatch => 'Geen overeenkomende notities';

  @override
  String shareTargetMore(int count) {
    return '+$count bestanden';
  }

  @override
  String get sharePreviewExpand => 'Voorbeeld vergroten';

  @override
  String get sharePreviewCollapse => 'Voorbeeld verkleinen';

  @override
  String get templatesSearch => 'Sjablonen zoeken';

  @override
  String get templatesAll => 'Alle';

  @override
  String get templatesLists => 'Lijsten';

  @override
  String get templatesPlanning => 'Planning';

  @override
  String get templatesWriting => 'Schrijven';

  @override
  String get templatesMine => 'Mijn sjablonen';

  @override
  String get templatesRecent => 'Recent gebruikt';

  @override
  String get templatesNoMatch => 'Geen overeenkomende sjablonen';

  @override
  String get templatesMineEmpty =>
      'Je hebt nog geen eigen sjablonen. Kies ‘Opslaan als sjabloon’ in het menu van een notitie en het verschijnt hier.';

  @override
  String get templatesMineInfo => 'Je eigen sjabloon';

  @override
  String get templateRename => 'Naam wijzigen';

  @override
  String get templateDelete => 'Sjabloon verwijderen';

  @override
  String get templateNameTitle => 'Naam van sjabloon';

  @override
  String get templateNameHint => 'bijv. Wekelijkse boodschappen';

  @override
  String get templateSave => 'Opslaan';

  @override
  String templateSaved(String name) {
    return '‘$name’ toegevoegd aan je sjablonen';
  }

  @override
  String get saveAsTemplate => 'Opslaan als sjabloon';

  @override
  String get templateCreate => 'Maken';

  @override
  String templateCreateWithCount(int count) {
    return 'Maken · $count items';
  }

  @override
  String get templateListChecks => 'Selectievakjes';

  @override
  String get templateListNumbers => 'Genummerd';

  @override
  String get templateItems => 'Items';

  @override
  String get templateAddItem => 'Item toevoegen';

  @override
  String get templateSuggestionsInfo =>
      'Tik op een suggestie om die toe te voegen; tik nogmaals om te verwijderen.';

  @override
  String get tplShopProduce => 'Groente en fruit';

  @override
  String get tplShopProduceItems =>
      'Tomaten, Komkommers, Uien, Aardappelen, Citroenen, Bananen, Appels, Peterselie';

  @override
  String get tplShopBreakfast => 'Ontbijt';

  @override
  String get tplShopBreakfastItems =>
      'Kaas, Olijven, Boter, Honing, Jam, Yoghurt';

  @override
  String get tplShopPantry => 'Voorraad';

  @override
  String get tplShopPantryItems =>
      'Rijst, Pasta, Bloem, Suiker, Olijfolie, Linzen, Thee, Koffie';

  @override
  String get tplShopCleaning => 'Schoonmaak';

  @override
  String get tplShopCleaningItems =>
      'Afwasmiddel, Wasmiddel, Wc-papier, Keukenpapier, Vuilniszakken';

  @override
  String get tplShopPersonal => 'Verzorging';

  @override
  String get tplShopPersonalItems => 'Shampoo, Tandpasta, Zeep, Deodorant';

  @override
  String get tplTravelDocs => 'Documenten';

  @override
  String get tplTravelDocsItems =>
      'Tickets, Hotelboeking, Rijbewijs, Reisverzekering, Contant / kaarten';

  @override
  String get tplTravelClothes => 'Kleding';

  @override
  String get tplTravelClothesItems =>
      'T-shirts, Broeken, Ondergoed, Sokken, Pyjama, Jas, Schoenen';

  @override
  String get tplTravelCare => 'Toiletartikelen';

  @override
  String get tplTravelCareItems =>
      'Tandpasta, Shampoo, Zonnebrand, Scheerset, Deodorant';

  @override
  String get tplTravelTech => 'Elektronica';

  @override
  String get tplTravelTechItems =>
      'Powerbank, Stekkeradapter, Koptelefoon, Kabels';

  @override
  String get tplHabitsName => 'Gewoontetracker';

  @override
  String get tplHabitsDesc => 'Elke dag afvinken, verbreek de ketting niet';

  @override
  String get tplHabitsItems =>
      '8 glazen water, 30 minuten wandelen, 20 bladzijden lezen, Vroeg naar bed, Eén uur zonder scherm';

  @override
  String get tplCleaningName => 'Huis schoonmaken';

  @override
  String get tplCleaningDesc => 'Wekelijkse schoonmaaklijst';

  @override
  String get tplCleaningItems =>
      'Afstoffen, Stofzuigen, Dweilen, Badkamer schoonmaken, Aanrecht, Was, Vuilnis buiten zetten, Bed verschonen';

  @override
  String get tplMovingName => 'Verhuislijst';

  @override
  String get tplMovingDesc => 'Taken voor en na de verhuizing';

  @override
  String get tplMovingItems =>
      'Verhuizers boeken, Dozen en tape kopen, Adres wijzigen, Stroom / water / gas, Internet verhuizen, Sleuteloverdracht';

  @override
  String get tplGiftsName => 'Cadeaulijst';

  @override
  String get tplGiftsDesc => 'Wie krijgt wat, ideeën';

  @override
  String get tplGiftsItems => 'Mama, Papa, Broer of zus, Vriend';

  @override
  String get tplWatchlistName => 'Kijklijst';

  @override
  String get tplWatchlistDesc => 'Films, series en boeken';

  @override
  String get tplWorkoutName => 'Training';

  @override
  String get tplWorkoutDesc => 'Van warming-up tot stretchen';

  @override
  String get tplWorkoutItems =>
      'Warming-up 5 min, Squats 3×12, Opdrukken 3×10, Buikspieren 3×15, Plank 3×45 s, Stretchen 5 min';

  @override
  String get tplGoalsName => 'Doelen';

  @override
  String get tplGoalsDesc => 'Doelen voor jaar, maand en week';

  @override
  String get tplGoalsYear => 'Dit jaar';

  @override
  String get tplGoalsMonth => 'Deze maand';

  @override
  String get tplGoalsWeek => 'Deze week';

  @override
  String get tplGoalsWhy => 'Waarom is het belangrijk?';

  @override
  String get templateNew => 'Nieuwe sjabloon';

  @override
  String get templateEdit => 'Sjabloon bewerken';

  @override
  String get templateDuplicate => 'Dupliceren';

  @override
  String get templateSaveAsMine => 'Opslaan in mijn sjablonen';

  @override
  String get templateUntitled => 'Naamloze sjabloon';

  @override
  String get templateTypeText => 'Tekst';

  @override
  String get templateTitleHelp =>
      'Titel van notities uit deze sjabloon (optioneel)';

  @override
  String get templateBody => 'Tekst';

  @override
  String get templateHeadingHelp =>
      'Regels die beginnen met “# ” worden koppen, met “## ” subkoppen.';

  @override
  String get templateDiscardTitle => 'Wijzigingen negeren?';

  @override
  String get templateDiscard => 'Negeren';

  @override
  String templateDeleted(String name) {
    return '“$name” verwijderd';
  }

  @override
  String get addVideoFromGallery => 'Video uit galerij';

  @override
  String get addYouTubeVideo => 'YouTube-video';

  @override
  String get addYouTubeVideoSubtitle =>
      'Speelt in de notitie, bekijk in een klein venster';

  @override
  String get youTubeLinkHelp =>
      'Plak een YouTube-videolink (youtube.com of youtu.be).';

  @override
  String get youTubeInvalidLink => 'Dit is geen YouTube-videolink';

  @override
  String get youTubeOpenInBrowserInfo =>
      'De video kan op dit apparaat niet in de app worden afgespeeld; hij kan in de browser worden geopend.';

  @override
  String get youTubeOpenExternal => 'Openen in YouTube';

  @override
  String get pictureInPicture => 'Beeld-in-beeld';

  @override
  String get pinMediaTop => 'Bovenaan vastzetten';

  @override
  String get pinMediaRelease =>
      'Loslaten: bovenaan vastzetten (notitie eronder)';

  @override
  String get unpinMedia => 'Terugzetten op de pagina';

  @override
  String get unpinMediaRelease => 'Loslaten: terugzetten op de pagina';

  @override
  String get pinnedMediaResize => 'Paneelhoogte — sleep om te wijzigen';

  @override
  String get addPageSubtitle =>
      'Voegt een nieuwe lege pagina aan de notitie toe';

  @override
  String pageOf(int current, int total) {
    return 'Pagina $current / $total';
  }

  @override
  String pageAdded(int page) {
    return 'Pagina $page toegevoegd';
  }

  @override
  String get deletePageConfirm =>
      'Tekst van deze pagina verwijderen? De afbeeldingen gaan naar de buurpagina. Met Ongedaan maken haal je hem terug.';

  @override
  String get embedNewPdf => 'PDF';

  @override
  String get embedNewImage => 'Afbeelding';

  @override
  String get embedNewVideo => 'Video';

  @override
  String get embedNewYouTube => 'YouTube';

  @override
  String get embedPickTitle => 'Wat insluiten?';

  @override
  String embedPickTitleFor(String label) {
    return 'Insluiten in ‘$label’';
  }

  @override
  String get embedPickInfo =>
      'Tik op de tekst om het ingesloten item ter plekke te openen.';

  @override
  String get embedSectionNew => 'Nieuw toevoegen';

  @override
  String get embedSectionExisting => 'Bijlagen van deze notitie';

  @override
  String get embedReplace => 'Vervangen';

  @override
  String get embedRemove => 'Insluiting verwijderen';

  @override
  String get embedRemoved => 'Insluiting verwijderd';

  @override
  String get guideTitle => 'Handleiding';

  @override
  String get guideMenuInfo => 'Alle functies, stap voor stap';

  @override
  String get guideSearchHint =>
      'Zoeken in de handleiding — ‘pagina’, ‘YouTube’';

  @override
  String get guideContents => 'Inhoud';

  @override
  String get guideOpenScreen => 'Scherm openen';

  @override
  String guideNoResults(String query) {
    return 'Geen resultaten voor ‘$query’';
  }

  @override
  String get copyVideoLink => 'Link kopiëren';

  @override
  String get videoLinkCopied => 'Link gekopieerd';

  @override
  String get attachSectionVisual => 'Afbeeldingen en tekening';

  @override
  String get menuSectionOrganize => 'Ordenen';

  @override
  String get menuSectionCopy => 'Kopiëren en exporteren';

  @override
  String get menuSectionTools => 'Hulpmiddelen';

  @override
  String get menuSectionProtect => 'Beveiliging en opslag';

  @override
  String get menuSectionContent => 'Inhoud';

  @override
  String get menuSectionPeople => 'Account en contacten';

  @override
  String get menuSectionHome => 'Startscherm';

  @override
  String get menuSectionApp => 'App';

  @override
  String cardMoreFiles(int count) {
    return '+$count dosya daha';
  }

  @override
  String cardAudioCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ses kaydı',
      one: 'Ses kaydı',
    );
    return '$_temp0';
  }

  @override
  String get cardBubbleDocument => 'BALONLU PDF';

  @override
  String get cardBubbleSlides => 'BALONLU SUNUM';

  @override
  String get cardKindPdf => 'PDF';

  @override
  String get cardKindSlides => 'SUNUM';

  @override
  String cardBubbleCount(int count) {
    return '$count balon';
  }

  @override
  String get quickAddImport => 'DOSYADAN';

  @override
  String get quickAddImage => 'Görsel';

  @override
  String get quickAddPdf => 'PDF';

  @override
  String get quickAddSlides => 'Sunum';

  @override
  String get quickAddGalleryVideo => 'Galeriden video';

  @override
  String get quickAddYouTube => 'YouTube videosu';

  @override
  String get docViewBubbles => 'Balonlu';

  @override
  String get docViewClassic => 'Klasik';

  @override
  String get docViewToBubbles => 'Balonlu görünüme geç';

  @override
  String get docViewToClassic => 'Klasik görünüme geç';

  @override
  String get docViewSwitchedBubbles =>
      'Balonlu görünüm: belge üstte, sayfa notu altta. Klasik yerleşim saklandı.';

  @override
  String get docViewSwitchedClassic =>
      'Klasik görünüm: belge sayfada bir ek. Balonlar ve sayfa notları saklandı.';

  @override
  String get docViewTextKept => 'Notun yazısı klasik görünümde duruyor.';

  @override
  String get docViewDropBubbles =>
      'Bırak: balonlu görünüm (üstte belge, altta not)';

  @override
  String get captureModeLast => 'Son seçimin';

  @override
  String get captureModeChangeLater =>
      'Sonradan nottaki Balonlu / Klasik çipiyle değiştirebilirsin.';

  @override
  String get attachmentSyncTitle => 'Ek senkronu';

  @override
  String get driveSectionTitle => 'Ekler Google Drive\'ında';

  @override
  String get driveConnectTitle => 'Ekleri Google Drive\'ında sakla';

  @override
  String get driveConnectInfo =>
      'Görseller, PDF\'ler, sunumlar ve ses kayıtları kendi Drive kotanda, uygulamaya özel gizli klasörde saklanır ve öbür cihazlarına iner. Videolar cihazda kalır.';

  @override
  String get driveConnect => 'Bağla';

  @override
  String get driveDisconnect => 'Bağlantıyı kes';

  @override
  String get driveConnected => 'Google Drive bağlandı — ekler yedekleniyor.';

  @override
  String get driveConnectedInfo =>
      'Bağlı · ekler Drive\'ının uygulama klasöründe';

  @override
  String driveUsage(String used, String limit) {
    return 'Drive: $used / $limit kullanıldı';
  }

  @override
  String driveConnectFailed(String error) {
    return 'Google Drive bağlanamadı. $error';
  }

  @override
  String get driveApiDisabled =>
      'Google Cloud projesinde Drive API kapalı: konsolda \"Google Drive API\"yi etkinleştirip yeniden dene.';

  @override
  String get driveDisconnected =>
      'Drive bağlantısı kesildi. Yeni ekler bağlanana dek cihazda bekler.';

  @override
  String get textOnlyTitle => 'Yalnız metin senkronu';

  @override
  String get textOnlyInfo =>
      'Misafir hesapta yalnız yazılar senkronlanır; ekler bu cihazda kalır. Google hesabı bağlarsan ekler Google Drive\'ında saklanır.';

  @override
  String get storageModeInfo => 'Web\'de ekler uygulama bulutuna yüklenir.';

  @override
  String driveWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ek Google Drive bağlantısını bekliyor — dokun, bağla',
      one: '1 ek Google Drive bağlantısını bekliyor — dokun, bağla',
    );
    return '$_temp0';
  }

  @override
  String get driveDownloading => 'Ek Google Drive\'dan indiriliyor…';

  @override
  String get driveNeededForFile =>
      'Bu ek Google Drive\'ında. Görmek için Ayarlar → Senkron\'dan Drive\'ı bağla.';
}
