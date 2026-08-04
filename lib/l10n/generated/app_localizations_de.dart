// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appName => 'Notizen';

  @override
  String get loginTagline => 'Deine Notizen auf jedem Gerät';

  @override
  String get signInWithGoogle => 'Mit Google anmelden';

  @override
  String loginError(String error) {
    return 'Anmeldung fehlgeschlagen: $error';
  }

  @override
  String get searchHint => 'Notizen durchsuchen ...';

  @override
  String get filterAll => 'Alle';

  @override
  String get filterText => 'Text';

  @override
  String get filterChecklist => 'Liste';

  @override
  String get filterOrdered => 'Nummeriert';

  @override
  String get filterPinned => 'Angeheftet';

  @override
  String get filterStarred => 'Markiert';

  @override
  String get star => 'Markieren';

  @override
  String get unstar => 'Markierung entfernen';

  @override
  String editedAt(String date) {
    return 'Bearbeitet: $date';
  }

  @override
  String get sectionPinned => 'Angeheftet';

  @override
  String get sectionOthers => 'Weitere';

  @override
  String get emptyNotes => 'Noch keine Notizen';

  @override
  String get emptyNotesHint => 'Tippe auf +, um deine erste Notiz anzulegen';

  @override
  String get emptySearch => 'Keine Ergebnisse gefunden';

  @override
  String get newTextNote => 'Textnotiz';

  @override
  String get newChecklist => 'Liste';

  @override
  String get newOrderedList => 'Nummerierte Liste';

  @override
  String get noteDeleted => 'Notiz gelöscht';

  @override
  String notesDeletedCount(int count) {
    return '$count Notizen gelöscht';
  }

  @override
  String selectedCount(int count) {
    return '$count ausgewählt';
  }

  @override
  String get deleteSelected => 'Auswahl löschen';

  @override
  String get undo => 'Rückgängig';

  @override
  String get titleHint => 'Titel';

  @override
  String get bodyHint => 'Notiz ...';

  @override
  String get newItemHint => 'Neuer Eintrag';

  @override
  String moreItemsCount(int count) {
    return '+$count weitere Einträge';
  }

  @override
  String get addAttachment => 'Hinzufügen';

  @override
  String get addImage => 'Bild hinzufügen';

  @override
  String get addPdf => 'PDF hinzufügen';

  @override
  String get addSlide => 'Folien hinzufügen';

  @override
  String get pasteImage => 'Bild aus der Zwischenablage einfügen';

  @override
  String get clipboardEmpty => 'Kein Bild in der Zwischenablage';

  @override
  String get noNoteSelected => 'Wähle links eine Notiz aus';

  @override
  String attachmentFailed(String error) {
    return 'Anhang konnte nicht hinzugefügt werden: $error';
  }

  @override
  String get attachmentUploading => 'Wird hochgeladen ...';

  @override
  String get attachmentNotSynced =>
      'Diese Datei wurde noch nicht auf dieses Gerät synchronisiert';

  @override
  String attachmentTooLarge(int limit) {
    return 'Datei ist zu groß (höchstens $limit MB)';
  }

  @override
  String get removeAttachment => 'Anhang entfernen';

  @override
  String get pin => 'Anheften';

  @override
  String get unpin => 'Lösen';

  @override
  String get delete => 'Löschen';

  @override
  String get color => 'Farbe';

  @override
  String get aiTitle => 'KI';

  @override
  String get aiSummarize => 'Notiz zusammenfassen';

  @override
  String get aiAnalyze => 'Analysieren';

  @override
  String get aiSectionNote => 'Diese Notiz';

  @override
  String get aiSectionAttachments => 'Anhänge';

  @override
  String get summarize => 'Zusammenfassen';

  @override
  String get summaryDetailTitle => 'Art der Zusammenfassung';

  @override
  String get summaryShort => 'Kurze Zusammenfassung';

  @override
  String get summaryShortInfo =>
      'Ein paar Sätze Überblick plus die wichtigsten Punkte';

  @override
  String get summaryDetailed => 'Ausführliche Zusammenfassung';

  @override
  String get summaryDetailedInfo =>
      'So gründlich, dass du das Original nicht mehr öffnen musst';

  @override
  String get listen => 'Anhören';

  @override
  String get ask => 'Frage stellen';

  @override
  String get extractText => 'Text extrahieren';

  @override
  String get transcribe => 'Transkribieren';

  @override
  String get listenToNote => 'Vorlesen';

  @override
  String get aiNoApiKey =>
      'Gib zuerst in den Einstellungen deinen Gemini-API-Schlüssel ein';

  @override
  String aiError(String error) {
    return 'KI-Anfrage fehlgeschlagen: $error';
  }

  @override
  String get aiSummaryTitle => 'KI-Zusammenfassung';

  @override
  String get aiThinking => 'Denkt nach ...';

  @override
  String get copy => 'Kopieren';

  @override
  String get copied => 'Kopiert';

  @override
  String get settingsSearchHint =>
      'Einstellungen durchsuchen – „Briefing“, „Mikrofon“';

  @override
  String settingsSearchEmpty(String query) {
    return 'Keine Einstellung entspricht „$query“';
  }

  @override
  String get settings => 'Einstellungen';

  @override
  String get settingsAppearance => 'Darstellung';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get settingsAi => 'KI';

  @override
  String get geminiApiKey => 'Gemini-API-Schlüssel';

  @override
  String get geminiApiKeyHint =>
      'Füge den Schlüssel ein, der mit AIza ... beginnt';

  @override
  String get geminiApiKeyInfo =>
      'Ein Schlüssel ist optional: ohne ihn laufen KI-Anfragen über den eingebauten Dienst der App (ein kostenloses Tageskontingent, mit Premium höher). Für unbegrenzte Nutzung mit eigenem Schlüssel bekommst du unter aistudio.google.com kostenlos einen; der Schlüssel wird nur auf diesem Gerät im sicheren Speicher abgelegt.';

  @override
  String aiBuiltInPremium(int count) {
    return 'Eingebaute KI: Premium — heute noch $count Punkte';
  }

  @override
  String aiBuiltInRemaining(int count) {
    return 'Eingebaute KI: heute noch $count kostenlose Punkte';
  }

  @override
  String get aiBuiltInByok =>
      'Dein eigener Schlüssel wird verwendet — unbegrenzt';

  @override
  String get aiReport => 'Diese Antwort melden';

  @override
  String get aiReportThanks => 'Meldung erhalten, danke';

  @override
  String get privacyPolicyTitle => 'Datenschutzerklärung';

  @override
  String get lockNote => 'Sperren';

  @override
  String get unlockNote => 'Entsperren';

  @override
  String get lockedNote => 'Gesperrte Notiz';

  @override
  String get unlockAuthReason =>
      'Bestätige deine Identität, um die gesperrte Notiz zu öffnen';

  @override
  String get exportBackup => 'Sicherung exportieren (JSON)';

  @override
  String get expandListItems => 'Listenzeilen vollständig anzeigen';

  @override
  String get expandListItemsInfo =>
      'Lange Listeneinträge brechen über mehrere Zeilen um und bleiben ganz sichtbar. Ist die Option aus, bleibt eine Zeile einzeilig und klappt beim Antippen auf.';

  @override
  String get emptyTrash => 'Papierkorb leeren';

  @override
  String emptyTrashConfirm(int count) {
    return '$count Notizen werden endgültig gelöscht. Das lässt sich nicht rückgängig machen. Bist du sicher?';
  }

  @override
  String get trashEmptied => 'Papierkorb geleert';

  @override
  String get validateAndSave => 'Prüfen und speichern';

  @override
  String get clear => 'Leeren';

  @override
  String get aiDiagnostics => 'KI-Diagnose';

  @override
  String get aiDiagnosticsEmpty => 'Keine Fehler aufgezeichnet';

  @override
  String aiDiagnosticsCount(int count) {
    return 'Letzte $count Fehlereinträge';
  }

  @override
  String get apiKeyValid => 'API-Schlüssel geprüft und gespeichert';

  @override
  String get apiKeyInvalid => 'API-Schlüssel ist ungültig';

  @override
  String get apiKeySavedBadge => 'Gespeichert';

  @override
  String get removeApiKey => 'Schlüssel löschen';

  @override
  String get refresh => 'Aktualisieren';

  @override
  String get account => 'Konto';

  @override
  String get signOut => 'Abmelden';

  @override
  String get signOutConfirm => 'Möchtest du dich wirklich abmelden?';

  @override
  String get deleteAccount => 'Mein Konto und meine Daten löschen';

  @override
  String get deleteAccountWarning =>
      'Das lässt sich nicht rückgängig machen: alle deine Notizen, Anhänge und dein Konto werden endgültig gelöscht. Möchtest du wirklich fortfahren?';

  @override
  String get deleteAccountConfirm => 'Endgültig löschen';

  @override
  String get licensesTitle => 'Open-Source-Lizenzen';

  @override
  String get generating => 'Wird erstellt ...';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get close => 'Schließen';

  @override
  String get ok => 'OK';

  @override
  String get syncPending => 'Warten auf Synchronisierung';

  @override
  String get synced => 'Synchronisiert';

  @override
  String genericError(String error) {
    return 'Etwas ist schiefgelaufen: $error';
  }

  @override
  String get addTag => 'Schlagwort';

  @override
  String get tagHint => 'z. B. Arbeit, Zuhause, Schule';

  @override
  String get addReminder => 'Erinnern';

  @override
  String get share => 'Teilen';

  @override
  String get archive => 'Archivieren';

  @override
  String get unarchive => 'Aus dem Archiv holen';

  @override
  String get archiveTitle => 'Archiv';

  @override
  String get archiveEmpty => 'Keine Notizen im Archiv';

  @override
  String get trashTitle => 'Papierkorb';

  @override
  String get trashEmpty => 'Der Papierkorb ist leer';

  @override
  String get trashInfo =>
      'Gelöschte Notizen bleiben hier; du kannst sie wiederherstellen oder endgültig löschen.';

  @override
  String get restore => 'Wiederherstellen';

  @override
  String get deleteForever => 'Endgültig löschen';

  @override
  String get deleteForeverConfirm =>
      'Diese Notiz wird endgültig gelöscht. Bist du sicher?';

  @override
  String get recordAudio => 'Sprachaufnahme';

  @override
  String get recording => 'Nimmt auf ...';

  @override
  String get stopAndSave => 'Beenden und hinzufügen';

  @override
  String get micPermissionDenied => 'Mikrofonberechtigung wurde verweigert';

  @override
  String get speechRecognitionFailed =>
      'Die Spracherkennung hat nicht funktioniert. Prüfe, ob die Mikrofonberechtigung erteilt und die Google-App aktuell ist.';

  @override
  String get addDrawing => 'Zeichnung hinzufügen';

  @override
  String get drawingTitle => 'Zeichnung';

  @override
  String get addToNote => 'Zur Notiz hinzufügen';

  @override
  String get chatTitle => 'Mit deinen Notizen chatten';

  @override
  String get chatHint =>
      'Frag nach deinen Notizen: „Wie ging das Rezept, das ich letzte Woche aufgeschrieben habe?“, „Was fehlt auf meiner Einkaufsliste?“';

  @override
  String get chatInputHint => 'Schreib eine Frage ...';

  @override
  String get fontSize => 'Schriftgröße';

  @override
  String get fontSizePreview => 'So werden deine Notizen aussehen';

  @override
  String get darkSchedule => 'Zeitplan für dunkles Design';

  @override
  String get darkScheduleInfo =>
      'Wechselt zwischen den von dir gewählten Uhrzeiten zum dunklen Design';

  @override
  String get aiTranslate => 'Übersetzen';

  @override
  String get voiceCommand => 'Sprachbefehl';

  @override
  String get semanticSearchToggle => 'Semantische Suche mit KI';

  @override
  String get semanticSearchHint => 'Nach Bedeutung suchen: „Autokosten“ ...';

  @override
  String get briefingTitle => 'Tagesbriefing';

  @override
  String get briefingLoading => 'Dein Briefing wird vorbereitet ...';

  @override
  String get briefingEmpty => 'Nichts für heute';

  @override
  String get briefingSetting => 'Benachrichtigung zum Tagesbriefing';

  @override
  String get briefingSettingInfo =>
      'Erhalte jeden Morgen zur gewählten Zeit eine Benachrichtigung mit der Zusammenfassung des Tages';

  @override
  String get autoTagSetting => 'Automatisch verschlagworten';

  @override
  String get autoTagSettingInfo =>
      'Wird eine Notiz ohne Schlagwort geschlossen, ergänzt die KI ein passendes';

  @override
  String get suggestTags => 'Schlagwörter vorschlagen';

  @override
  String get aiFixNote => 'Notiz überarbeiten';

  @override
  String get fixLevelTitle => 'Wie viel soll überarbeitet werden?';

  @override
  String get fixSimple => 'Leicht';

  @override
  String get fixSimpleInfo => 'Nur Rechtschreibung und Tippfehler';

  @override
  String get fixBalanced => 'Ausgewogen';

  @override
  String get fixBalancedInfo =>
      'Auch der Satzbau, für sauberere Formulierungen';

  @override
  String get fixDetailed => 'Gründlich';

  @override
  String get fixDetailedInfo => 'Schreibt den ganzen Text von Grund auf neu';

  @override
  String get existingTagsLabel => 'Frühere Schlagwörter';

  @override
  String get aiSkipCheckedSetting =>
      'Erledigte Einträge von KI-Änderungen ausnehmen';

  @override
  String get aiSkipCheckedInfo =>
      'Wenn die KI eine Liste überarbeitet oder übersetzt, bleiben erledigte (abgehakte) Einträge genau so, wie sie sind; nur offene Einträge werden bearbeitet.';

  @override
  String get noteUpdatedUndo => 'Notiz aktualisiert';

  @override
  String get aiImprove => 'Notiz verbessern';

  @override
  String get improveFormal => 'Förmlicher formulieren';

  @override
  String get improveShorten => 'Kürzen';

  @override
  String get improveBullets => 'In eine Aufzählung umwandeln';

  @override
  String get improveNumbered => 'In eine nummerierte Liste umwandeln';

  @override
  String get replaceNote => 'Notiz ersetzen';

  @override
  String get openAsNewNote => 'Als neue Notiz';

  @override
  String get pdfChatHint =>
      'Frag zu diesem PDF: „Fass es zusammen“, „Gibt es eine Vertragsstrafe?“, „Wann ist die Frist?“';

  @override
  String get pdfChatInputHint => 'Schreib eine Frage zum PDF ...';

  @override
  String get voiceCaptureHint =>
      'Sprich einfach: „Milch und Brot kaufen“ oder „Morgen um 9 Besprechung, erinnere mich“ — die KI baut deine Notiz, wenn du fertig bist.';

  @override
  String get voiceFinish => 'Fertig';

  @override
  String get voiceProcessing => 'Das Gesagte wird übernommen ...';

  @override
  String get voiceNothingHeard => 'In der Aufnahme wurde keine Sprache erkannt';

  @override
  String get voiceNoteSaved => 'Deine Sprachnotiz wurde gespeichert';

  @override
  String get openNote => 'Notiz öffnen';

  @override
  String get remindersTitle => 'Erinnerungen';

  @override
  String get remindersEmpty => 'Keine Erinnerungen';

  @override
  String get remindersEmptyHint =>
      'Füge einer Notiz eine Erinnerung hinzu oder erstelle mit + eine neue Notiz mit Erinnerung';

  @override
  String get remindersUpcoming => 'Anstehend';

  @override
  String get remindersPast => 'Vergangen';

  @override
  String get newReminder => 'Neue Erinnerung';

  @override
  String get remindersUntitled => 'Notiz ohne Titel';

  @override
  String get remindersEdit => 'Zeit ändern';

  @override
  String get remindersRemove => 'Erinnerung entfernen';

  @override
  String get aiModelChat => 'Zusammenfassungen, Titel, Schlagwörter und Chat';

  @override
  String get aiModelDocument => 'Podcasts und Dokumenten-Chat';

  @override
  String get aiModelTranslate => 'Übersetzung';

  @override
  String get aiModelVoice => 'Sprachnotizen';

  @override
  String get aiModelAuto => 'Automatisch (empfohlen)';

  @override
  String get aiModelsInfo =>
      'Du kannst pro Aufgabe ein eigenes Modell wählen: kurze Textarbeit läuft gut auf einem schnellen Modell, lange Dokumente brauchen ein leistungsfähiges. Ist das gewählte Modell am Kontingentende oder wird es eingestellt, wird automatisch das nächste versucht.';

  @override
  String get clearNote => 'Leeren';

  @override
  String get clearNoteConfirm =>
      'Der Inhalt der Notiz (Text und Listeneinträge) wird gelöscht. Bist du sicher?';

  @override
  String get themePaper => 'Papier';

  @override
  String get calculatorTitle => 'Rechner';

  @override
  String get calcExpressionHint => 'z. B. 12,5×3+40';

  @override
  String get calcInvalid => 'Ungültiger Ausdruck';

  @override
  String get liveDictation => 'Diktieren';

  @override
  String get dictationListening =>
      'Hört zu ... der Text erscheint, während du sprichst';

  @override
  String get dictationNoKeyInfo =>
      'Live-Diktat ist auf diesem Gerät nicht verfügbar; die Aufnahme wird beim Stoppen in einem Zug transkribiert.';

  @override
  String get dictationHoldHint =>
      'Halte das Mikrofon gedrückt und sprich; beim Loslassen wird der Text geschrieben';

  @override
  String itemsSelected(int count) {
    return '$count Einträge ausgewählt';
  }

  @override
  String get noteChatTitle => 'Mit dieser Notiz chatten';

  @override
  String get noteChatHint => 'Frag etwas zu dieser Notiz';

  @override
  String get noteChatIntro =>
      'Der Inhalt der Notiz und ihre Anhänge (PDF/Bild) werden gelesen und deine Frage daraus beantwortet.';

  @override
  String get dictationProcessing => 'Wird transkribiert ...';

  @override
  String get aiDailyManualInfo =>
      'Im kostenlosen Tarif wird das nicht automatisch erstellt, damit dein Tageskontingent nicht aufgebraucht wird. Mit der Schaltfläche unten kannst du es einmal am Tag erzeugen.';

  @override
  String get aiGenerate => 'Erstellen';

  @override
  String get aiGeneratedTodayInfo =>
      'Das wurde heute erstellt. Im kostenlosen Tarif erneuert es sich einmal täglich; morgen kannst du es wieder erzeugen.';

  @override
  String get voiceAssistantTitle => 'Sprachnotiz-Assistent';

  @override
  String get voiceListening => 'Hört zu ...';

  @override
  String get voiceHoldHint =>
      'Gedrückt halten und sprechen; beim Loslassen entsteht deine Notiz';

  @override
  String get voiceTapHint =>
      'Antippen und sprechen; zum Beenden erneut antippen';

  @override
  String get voiceTooShort =>
      'Diese Aufnahme war zu kurz, versuch es noch einmal';

  @override
  String get voiceModeSetting => 'So funktioniert es';

  @override
  String get voiceModeHold => 'Zum Sprechen gedrückt halten';

  @override
  String get voiceModeTap => 'Antippen zum Starten / Antippen zum Stoppen';

  @override
  String get voiceModeInfo =>
      'Zum Sprechen gedrückt halten: die App hört zu, solange du die Taste hältst, und legt beim Loslassen die Notiz an. Antippen zum Starten: ein Tippen startet die Aufnahme, ein zweites beendet sie.';

  @override
  String get voiceHeardLive => 'Sprache erkannt';

  @override
  String get voiceCaptureReady => 'Sprachaufnahme bereit';

  @override
  String get voiceCaptureEditHint => 'Zum Bearbeiten auf den Text tippen';

  @override
  String voiceCapturePunctuation(String language) {
    return '$language · Automatische Zeichensetzung';
  }

  @override
  String get voiceCaptureAddToNote => 'Zu Notiz hinzufügen';

  @override
  String get voiceCaptureCreateNote => 'Neue Notiz erstellen';

  @override
  String get voiceCaptureRestart => 'Erneut aufnehmen';

  @override
  String get voiceChipSummarizeAdd => 'Als Zusammenfassung hinzufügen';

  @override
  String get voiceChipSummarizeSave => 'Als Zusammenfassung speichern';

  @override
  String get voiceChipToItems => 'In Punkte aufteilen';

  @override
  String get voiceChipAsList => 'Checkliste erstellen';

  @override
  String get voiceChipFix => 'Bereinigen';

  @override
  String get voiceChipCompose => 'Vom Assistenten schreiben lassen';

  @override
  String get editorToolList => 'Liste';

  @override
  String get permissionsTitle => 'Berechtigungen';

  @override
  String get permMic => 'Mikrofon';

  @override
  String get permMicInfo => 'Wird für Sprachnotizen und Diktat benötigt';

  @override
  String get permNotifications => 'Benachrichtigungen';

  @override
  String get permNotificationsInfo =>
      'Wird für Erinnerungen und das Tagesbriefing benötigt';

  @override
  String get permBattery => 'Akku-Optimierung';

  @override
  String get permBatteryInfo =>
      'Nimm die App von Akku-Beschränkungen aus, damit Erinnerungen pünktlich ankommen';

  @override
  String get showTagChips => 'Schlagwort-Chips anzeigen';

  @override
  String get showFolderChips => 'Ordner-Chips anzeigen';

  @override
  String videoTooBigForAi(int mb) {
    return 'Das Video ist zu groß für die KI ($mb MB). Nimm ein kürzeres auf.';
  }

  @override
  String get permCamera => 'Kamera';

  @override
  String get permCameraInfo => 'Wird für Videonotizen und Fotos benötigt';

  @override
  String get permOnboardTitle => 'Bevor du loslegst';

  @override
  String get permOnboardInfo =>
      'Notizen fragt diese Berechtigungen erst ab, wenn du die passende Funktion nutzt. Du kannst sie unten gleich erteilen oder später unter Einstellungen > Berechtigungen ändern.';

  @override
  String get permOnboardGrantAll => 'Berechtigungen erteilen';

  @override
  String get permOnboardSkip => 'Jetzt nicht';

  @override
  String get newVideoNote => 'Videonotiz';

  @override
  String get videoLocalOnly =>
      'Dieses Video liegt nur auf diesem Gerät (es wird nicht in die Cloud geladen)';

  @override
  String get videoToNote => 'Aus dem Video eine Notiz machen';

  @override
  String get videoToNoteRunning => 'Das Video wird ausgewertet …';

  @override
  String get permGranted => 'Erteilt';

  @override
  String get permGrant => 'Erteilen';

  @override
  String get permOpenSettings => 'Einstellungen öffnen';

  @override
  String get newHandwriting => 'Handschrift';

  @override
  String get newVoiceCapture => 'Sprachnotiz';

  @override
  String get suggestTitle => 'Titel vorschlagen';

  @override
  String get noteMetaMenu => 'Schlagwort · Titel · Erinnerung';

  @override
  String get folder => 'Ordner';

  @override
  String get noFolder => 'Kein Ordner';

  @override
  String get newFolder => 'Neuer Ordner';

  @override
  String get editFolder => 'Ordner bearbeiten';

  @override
  String get deleteFolder => 'Ordner löschen';

  @override
  String deleteFolderConfirm(String name) {
    return 'Der Ordner „$name“ wird gelöscht. Die Notizen darin werden nicht gelöscht — sie haben dann einfach keinen Ordner mehr.';
  }

  @override
  String get folderNameHint => 'Ordnername';

  @override
  String get folderIcon => 'Symbol';

  @override
  String get editFilters => 'Filter bearbeiten';

  @override
  String get editFiltersInfo =>
      'Wähle, welche Filter auf dem Startbildschirm erscheinen. Ausgeblendete Filter halten die Seite aufgeräumt.';

  @override
  String get select => 'Auswählen';

  @override
  String get noteArchived => 'Notiz archiviert';

  @override
  String deleteChecked(int count) {
    return 'Erledigte löschen ($count)';
  }

  @override
  String get removeItem => 'Eintrag löschen';

  @override
  String get copyWholeNote => 'Ganze Notiz kopieren';

  @override
  String get allCopied => 'Die ganze Notiz wurde in die Zwischenablage kopiert';

  @override
  String get speechPlay => 'Vorlesen';

  @override
  String get speechPause => 'Pause';

  @override
  String get speechResume => 'Fortsetzen';

  @override
  String get speechStop => 'Stopp';

  @override
  String get speechRate => 'Lesegeschwindigkeit';

  @override
  String get speechSystemDefault => 'Systemstandard';

  @override
  String get speechNoVoices =>
      'Auf diesem Gerät sind keine Stimmen installiert';

  @override
  String speechVoiceLanguage(String language) {
    return 'Stimme für $language';
  }

  @override
  String get speechVoiceAutoInfo =>
      'Andere Sprachen werden automatisch mit einer männlichen Stimme gelesen';

  @override
  String get listening => 'Hört zu ...';

  @override
  String get listenPlay => 'Anhören';

  @override
  String get listenReadingPdf => 'Das Dokument wird gelesen ...';

  @override
  String get listenConvertWithAi => 'Mit KI umwandeln';

  @override
  String get listenMakePodcast => 'Vollständiger Podcast';

  @override
  String get listenMakePodcastSummary => 'Podcast der Zusammenfassung';

  @override
  String get listenOriginalText => 'Originaltext';

  @override
  String get listenPodcastReady => 'Die Podcast-Sprachausgabe ist fertig';

  @override
  String get listenPodcastCached =>
      'Bereits früher erstellt — keine Token verbraucht';

  @override
  String get listenRegenerate => 'Erneut erstellen';

  @override
  String get listenNoText =>
      'Aus diesem Dokument kam kein lesbarer Text heraus. Ein gescanntes PDF hat keine Textebene, und eine Präsentation kann nur Bilder enthalten.';

  @override
  String get readDocument => 'Dokument vorlesen (Word, PDF, Folien)';

  @override
  String get readDocUnsupported => 'Dieser Dateityp kann nicht gelesen werden.';

  @override
  String get exportPdf => 'Als PDF exportieren';

  @override
  String get pdfTitleField => 'Titel';

  @override
  String get pdfContentField => 'Inhalt';

  @override
  String get pdfMarkupHint =>
      'Zeichen am Zeilenanfang werden zu Formatierung: [x] und [ ] für Kästchen, 1. für eine nummerierte Liste, - für einen Aufzählungspunkt.';

  @override
  String get pdfIncludeDate => 'Datum einfügen';

  @override
  String get exportIncludeImages => 'Bilder einfügen';

  @override
  String get exportWord => 'Als Word (.docx) teilen';

  @override
  String get pdfPreview => 'Vorschau';

  @override
  String get largeAttachmentTitle => 'Große Datei';

  @override
  String largeAttachmentBody(String size) {
    return 'Diese Datei ist $size MB groß. PDFs lassen sich nicht komprimieren; sie wird unverändert hochgeladen und zählt zu deinem Speicher. Fortfahren?';
  }

  @override
  String get speechRateForeign => 'Geschwindigkeit für Fremdsprachen';

  @override
  String notesArchivedCount(int count) {
    return '$count Notizen archiviert';
  }

  @override
  String get backgroundColor => 'Hintergrundfarbe';

  @override
  String get backgroundColorInfo => 'Die Hintergrundfarbe der Notiz';

  @override
  String get frameColor => 'Rahmen';

  @override
  String get frameColorInfo =>
      'Zeichnet einen Rahmen in der gewählten Farbe um die Notiz';

  @override
  String get sortBy => 'Sortieren';

  @override
  String get reorderNotes => 'Notizen umsortieren';

  @override
  String get reorderModeActive => 'Zieh die Karten, um sie umzusortieren';

  @override
  String get reorderDone => 'Fertig';

  @override
  String get sortManual => 'Manuell (Ziehreihenfolge)';

  @override
  String get sortUpdated => 'Zuletzt bearbeitet';

  @override
  String get sortCreated => 'Erstellungsdatum';

  @override
  String get sortTitle => 'Nach Titel (A–Z)';

  @override
  String get foldersSection => 'Ordner';

  @override
  String get tagsSection => 'Schlagwörter';

  @override
  String get expandFilters => 'Filter aufklappen';

  @override
  String get collapseFilters => 'Filter zuklappen';

  @override
  String get settingsLanguage => 'Sprache';

  @override
  String get languageSystem => 'Systemsprache';

  @override
  String get settingsSpeech => 'Vorlesen';

  @override
  String get aiAdvanced => 'Erweitert: Modell und API-Schlüssel';

  @override
  String get aiAdvancedInfo =>
      'Modellwahl und dein eigener Gemini-Schlüssel. Die meisten brauchen das nicht.';

  @override
  String get openBriefing => 'Briefing öffnen';

  @override
  String get syncTitle => 'Synchronisierung';

  @override
  String get syncLimitTitle => 'Grenze für automatischen Upload';

  @override
  String get syncLimitInfo =>
      'Größere Anhänge bleiben auf dem Gerät und werden nicht hochgeladen. Der Notiztext wird immer synchronisiert.';

  @override
  String get syncLimitUnlimited => 'Keine Grenze';

  @override
  String get backupTitle => 'Sicherung';

  @override
  String get importBackup => 'Aus Sicherung wiederherstellen (JSON)';

  @override
  String importBackupDone(int count) {
    return '$count Notizen wiederhergestellt';
  }

  @override
  String get importBackupInvalid => 'Ungültige Sicherungsdatei';

  @override
  String get aiHubTitle => 'KI';

  @override
  String get aiSummarizeInfo => 'Erstellt eine kurze Zusammenfassung';

  @override
  String get aiAnalyzeInfo => 'Listet die wichtigsten Punkte und Aufgaben auf';

  @override
  String get moveToFolder => 'In Ordner verschieben';

  @override
  String get voiceAssistantBadge => 'Assistent';

  @override
  String get assistantGenericError =>
      'Etwas ist schiefgelaufen — versuchst du es noch einmal?';

  @override
  String get quickAddTooltip => 'Neue Notiz — wähle einen Typ';

  @override
  String get autoTitleSetting => 'Beim Schließen einen Titel vorschlagen';

  @override
  String get autoTitleSettingInfo =>
      'Wenn du den Editor verlässt, bekommt eine Notiz ohne Titel einen kurzen, aus ihrem Inhalt geschriebenen Titel.';

  @override
  String get hubChatInfo => 'Fragen, beantwortet aus deinen Notizen';

  @override
  String get hubBriefingInfo =>
      'Dein Tag auf einen Blick: Erinnerungen und aktuelle Notizen';

  @override
  String get hubReadInfo => 'Ein PDF- oder Word-Dokument anhören';

  @override
  String get annotate => 'Beschriften';

  @override
  String get annotateDone => 'Beschriften beenden';

  @override
  String get crop => 'Zuschneiden';

  @override
  String get cropApply => 'Zuschnitt anwenden';

  @override
  String get cropReset => 'Auswahl zurücksetzen';

  @override
  String get cropHint =>
      'Zieh an den Ecken, um einen Bereich zu wählen. Zuschneiden lässt sich nicht rückgängig machen.';

  @override
  String get cropFailed => 'Das Bild konnte nicht zugeschnitten werden.';

  @override
  String get penBallpoint => 'Kugelschreiber';

  @override
  String get penMarker => 'Filzstift';

  @override
  String get penHighlighter => 'Textmarker';

  @override
  String get eraser => 'Radiergummi';

  @override
  String get clearInk => 'Beschriftungen löschen';

  @override
  String get inkTwoFingerHint =>
      'Ein Finger zeichnet · zwei Finger verschieben und zoomen';

  @override
  String get slideOpenFailed => 'Die Präsentation konnte nicht geöffnet werden';

  @override
  String get newPhotoNote => 'Fotonotiz';

  @override
  String get newScanNote => 'Dokument scannen';

  @override
  String get scanDocument => 'Dokument scannen';

  @override
  String get scanDocumentSubtitle =>
      'Findet die Ränder, entzerrt die Seite und fügt sie ein';

  @override
  String get scanUnsupported =>
      'Dokumentenscan wird auf diesem Gerät nicht unterstützt';

  @override
  String scanFailed(String error) {
    return 'Das Dokument konnte nicht gescannt werden: $error';
  }

  @override
  String scanPagesAdded(int count) {
    return '$count Seite(n) zur Notiz hinzugefügt';
  }

  @override
  String get scanTextTitle => 'Soll auch der Text erkannt werden?';

  @override
  String get scanTextBody =>
      'Der Text auf den Seiten wird erkannt und in die Notiz geschrieben. Das Bild bleibt, wie es ist. Dauert ein paar Sekunden pro Seite.';

  @override
  String get scanImageOnly => 'Nur Bild';

  @override
  String get scanRecognizeText => 'Text erkennen';

  @override
  String get scanRecognizing => 'Text wird erkannt …';

  @override
  String get takePhoto => 'Foto aufnehmen';

  @override
  String get qrScanTitle => 'QR-Code scannen';

  @override
  String get qrScanSubtitle => 'Mit der Kamera oder aus einem Foto lesen';

  @override
  String get qrScanHint => 'Richte den Code im Rahmen aus';

  @override
  String get qrFromPhoto => 'Aus einem Foto lesen';

  @override
  String get qrNotFound => 'In diesem Bild wurde kein Code gefunden';

  @override
  String get qrLinkFound => 'Dieser Code ist ein Link';

  @override
  String get qrOpenLink => 'Zum Link gehen';

  @override
  String get qrSaveToNote => 'In einer Notiz speichern';

  @override
  String get openLink => 'Link öffnen';

  @override
  String get linkOpenFailed => 'Der Link konnte nicht geöffnet werden';

  @override
  String qrScanFailed(String error) {
    return 'Der Code konnte nicht gelesen werden: $error';
  }

  @override
  String get qrTorch => 'Taschenlampe';

  @override
  String attachmentsCount(int count) {
    return 'Anhänge ($count)';
  }

  @override
  String get hideAttachments => 'Ausblenden';

  @override
  String get showAttachments => 'Anzeigen';

  @override
  String get videoBack10 => '10 Sek. zurück';

  @override
  String get videoForward10 => '10 Sek. vor';

  @override
  String get selectAllItems => 'Alle auswählen';

  @override
  String get showAllChips => 'Alle anzeigen';

  @override
  String get hideAllChips => 'Alle ausblenden';

  @override
  String get chipPickInfo =>
      'Welche Ordner- und Schlagwort-Chips sollen auf dem Startbildschirm erscheinen?';

  @override
  String get hiddenFolder => 'Versteckter Ordner';

  @override
  String get hiddenFolderInfo =>
      'Ein versteckter Ordner und die Notizen darin erscheinen nicht auf dem Startbildschirm. Um sie anzuzeigen, wähle im ⋮-Menü „Versteckte Ordner“ und bestätige deine Identität.';

  @override
  String get hiddenFoldersMenu => 'Versteckte Ordner';

  @override
  String get hiddenFolderAuthReason =>
      'Bestätige deine Identität, um versteckte Ordner anzuzeigen';

  @override
  String get hiddenFoldersShown => 'Versteckte Ordner werden angezeigt';

  @override
  String get hiddenFoldersHiddenAgain =>
      'Versteckte Ordner sind wieder verborgen';

  @override
  String get makeFolderHidden => 'Verstecken';

  @override
  String get makeFolderVisible => 'Nicht mehr verstecken';

  @override
  String gridColumnsCount(int count) {
    return '$count Spalten';
  }

  @override
  String get addImageOnPageSubtitle =>
      'Liegt auf der Seite, der Text fließt darum herum';

  @override
  String get addImageAsFile => 'Bild als Datei anhängen';

  @override
  String get addImageAsFileSubtitle =>
      'Bleibt außerhalb der Seite, in der Anhangsleiste';

  @override
  String get moveImageToAttachments => 'Zu den Anhängen verschieben';

  @override
  String get moveImageToPage => 'Auf die Seite legen';

  @override
  String get attachmentCopied => 'Anhang kopiert';

  @override
  String get pasteAttachment => 'Kopierten Anhang einfügen';

  @override
  String get fullscreen => 'Vollbild';

  @override
  String get more => 'Mehr';

  @override
  String get undone => 'Rückgängig gemacht';

  @override
  String get filterOthers => 'Sonstige';

  @override
  String get chatSuggestion1 => 'Was fehlt auf meiner Einkaufsliste?';

  @override
  String get chatSuggestion2 =>
      'Fasse meine Arbeitsnotizen dieser Woche zusammen';

  @override
  String get chatSuggestion3 => 'Habe ich eine Erinnerung für morgen?';

  @override
  String get aiPointsToday => 'Punkte von heute';

  @override
  String aiPointsOf(int used, int total) {
    return '$used / $total';
  }

  @override
  String get aiPointsRenew => 'wird um Mitternacht erneuert';

  @override
  String get aiChatWithNotes => 'Mit deinen Notizen chatten';

  @override
  String get aiChatInputHint => 'Frage etwas zu deinen Notizen…';

  @override
  String get aiChatLooking => 'durchsuche deine Notizen…';

  @override
  String get aiChatFullScreen => 'Vollbild';

  @override
  String get aiOnYourNotes => 'ZU DEINEN NOTIZEN';

  @override
  String get aiRecentOps => 'KÜRZLICH';

  @override
  String get aiTaskWeekSummary => 'Wochenzusammenfassung';

  @override
  String get aiTaskWeekSummaryInfo => 'Eine Zusammenfassung der letzten 7 Tage';

  @override
  String get aiTaskTagUntagged => 'Nicht markierte taggen';

  @override
  String aiTaskTagUntaggedInfo(int count) {
    return '$count Notizen warten auf Tags';
  }

  @override
  String get aiTaskSuggestTitles => 'Titel vorschlagen';

  @override
  String aiTaskSuggestTitlesInfo(int count) {
    return '$count Notizen haben keinen Titel';
  }

  @override
  String get sectionPinnedShort => 'ANGEPINNT';

  @override
  String get sectionToday => 'HEUTE';

  @override
  String get sectionThisWeek => 'DIESE WOCHE';

  @override
  String get sectionEarlier => 'FRÜHER';

  @override
  String sectionNoteCount(int count) {
    return '$count Notizen';
  }

  @override
  String get emptySearchSemanticHint => 'Versuche es im Tab „Bedeutung“';

  @override
  String get quickCaptureHint => 'Neue Notiz…';

  @override
  String get quickCaptureSave => 'Speichern';

  @override
  String get quickAddWrite => 'SCHREIBEN';

  @override
  String get quickAddCapture => 'ERFASSEN – ERSTELLT EINE NOTIZ AUS DEM INHALT';

  @override
  String get viewToggle => 'Ansicht';

  @override
  String get searchModeText => 'Text';

  @override
  String get searchModeMeaning => 'Bedeutung';

  @override
  String get filterReminded => 'Mit Erinnerung';

  @override
  String get filterLocked => 'Gesperrt';

  @override
  String get sortColor => 'Farbe';

  @override
  String get filterSheetTitle => 'Filter';

  @override
  String get filterReset => 'Zurücksetzen';

  @override
  String get filterSectionStatus => 'STATUS';

  @override
  String get filterSectionFolder => 'ORDNER';

  @override
  String get filterSectionTag => 'TAG';

  @override
  String get filterSectionSort => 'SORTIEREN';

  @override
  String get filterSheetSortHint =>
      'Datumsgruppen (HEUTE, DIESE WOCHE…) werden nur beim Sortieren nach dem letzten Bearbeitungsdatum angezeigt.';

  @override
  String get formatTitle => 'Format';

  @override
  String get formatBold => 'Fett';

  @override
  String get formatItalic => 'Kursiv';

  @override
  String get formatUnderline => 'Unterstrichen';

  @override
  String get formatTextColor => 'Textfarbe';

  @override
  String get formatHighlight => 'Hervorhebung';

  @override
  String get formatInfo =>
      'Formatierung steckt als Marker im Text (etwa **fett**); beim Export und Vorlesen bleiben die Marker unsichtbar.';

  @override
  String get formatMenu => 'Format…';

  @override
  String get noteFont => 'Schriftart';

  @override
  String get noteFontDefault => 'Standard';

  @override
  String get noteFontSerif => 'Buch (Serif)';

  @override
  String get noteFontMono => 'Schreibmaschine';

  @override
  String get noteTextSize => 'Schriftgröße';

  @override
  String get formatClear => 'Formatierung entfernen';

  @override
  String get noteTextOpacity => 'Transparenz';

  @override
  String get assistantVoiceSetting => 'Assistent antwortet laut';

  @override
  String get assistantVoiceSettingInfo =>
      'Der Sprachassistent liest seine Antwort vor (nur am Telefon).';

  @override
  String get assistantMute => 'Ton aus';

  @override
  String get assistantUnmute => 'Ton an';

  @override
  String get assistantMakeNote => 'Trotzdem in Notiz umwandeln';

  @override
  String get assistantNoteCreated => 'Notiz erstellt';

  @override
  String get noteNotFound =>
      'Notiz nicht gefunden. Sie wurde vielleicht gelöscht.';

  @override
  String get back => 'Zurück';

  @override
  String get addTextBlock => 'Text hinzufügen';

  @override
  String get noteBackgroundImage => 'Hintergrundbild';

  @override
  String get chooseBackgroundImage => 'Bild wählen';

  @override
  String get changeBackgroundImage => 'Bild ändern';

  @override
  String get removeBackgroundImage => 'Hintergrund entfernen';

  @override
  String get dashboardBackground => 'Startbildschirm-Hintergrund';

  @override
  String get dashboardBackgroundInfo =>
      'Bild hinter dem Notizraster (nur auf diesem Gerät).';

  @override
  String get aiProvider => 'KI-Anbieter';

  @override
  String get aiProviderInfo =>
      'Wähle den Anbieter, zu dem dein Schlüssel gehört. Der Schlüssel jedes Anbieters wird separat gespeichert, ein Wechsel erfordert also keine erneute Eingabe.';

  @override
  String get apiKeyFieldLabel => 'API-Schlüssel';

  @override
  String get getApiKey => 'Wo bekomme ich einen Schlüssel?';

  @override
  String get recommendedModel => 'Empfohlen';

  @override
  String get freeTierBadge => 'Mit kostenlosem Kontingent';

  @override
  String get continueWithoutAccount => 'Ohne Konto fortfahren';

  @override
  String get localAccountInfo =>
      'Deine Notizen bleiben nur auf diesem Gerät: kein Zugriff von anderen Geräten, weg beim Deinstallieren, und die interne KI ist aus. Du kannst jederzeit ein Google-Konto verknüpfen — deine Notizen bleiben erhalten.';

  @override
  String get localAccountBadge => 'Lokales Konto';

  @override
  String get linkGoogleAccount => 'Google-Konto verknüpfen';

  @override
  String get accountLinked =>
      'Dein Google-Konto ist verknüpft. Deine Notizen werden jetzt gesichert.';
}
