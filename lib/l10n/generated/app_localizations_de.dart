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
  String get redo => 'Wiederholen';

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
  String get addAttachmentMore => 'Weitere Anhangtypen …';

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
  String get attachmentCopying => 'Wird kopiert...';

  @override
  String get attachmentUploading => 'Wird hochgeladen ...';

  @override
  String get attachmentUploadFailed =>
      'Upload fehlgeschlagen — zum Wiederholen tippen';

  @override
  String get attachmentNotSynced =>
      'Diese Datei wurde noch nicht auf dieses Gerät synchronisiert';

  @override
  String attachmentTooLarge(int limit) {
    return 'Datei ist zu groß (höchstens $limit MB)';
  }

  @override
  String storageFull(String limit) {
    return 'Speicher ist voll ($limit). Lösche alte Anhänge, um Platz zu schaffen.';
  }

  @override
  String get storageUsage => 'Speicher';

  @override
  String storageUsageValue(String used, String limit) {
    return '$used von $limit belegt';
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
  String get quickCaptureRowSetting => 'Schnellnotiz-Leiste';

  @override
  String get quickCaptureRowInfo =>
      'Zeigt oben ein einzeiliges \"Neue Notiz...\"-Feld. Wenn aus, nutze die +-Taste.';

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
  String get signOutAnonymousWarning =>
      'Du nutzt ein lokales Konto: Nach dem Abmelden sind dieses Konto und ALLE Notizen dauerhaft unzugänglich — ohne Backup nicht wiederherstellbar. Verknüpfe zuerst ein Google-Konto. Trotzdem abmelden?';

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
  String assistantDeleteConfirm(String title) {
    return 'Der Assistent möchte die Notiz "${title}" in den Papierkorb verschieben. Einverstanden?';
  }

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
  String get chatTitle => 'Notiz-Assistent';

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
  String get reminderInPast =>
      'Die gewählte Zeit liegt in der Vergangenheit — wähle eine zukünftige Zeit.';

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
  String get aiModelDocument => 'Dokument-Chat und PDF-Zusammenfassung';

  @override
  String get aiModelTranslate => 'Übersetzung';

  @override
  String get aiModelVoice => 'Sprachnotiz-Assistent';

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
  String get voiceCaptureAiNote => 'KI-Notiz';

  @override
  String get voiceCapturePlainNote => 'Einfache Notiz';

  @override
  String get voiceCloseTitle => 'Dein Diktat ist noch da';

  @override
  String get voiceCloseKeepTalking => 'Weiter sprechen';

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
  String get aiImproveInfo => 'Ändert den Ton: förmlich, kürzer oder Liste';

  @override
  String get aiTranslateInfo => 'Übersetzt die Notiz in eine gewählte Sprache';

  @override
  String get aiFixNoteInfo => 'Korrigiert Rechtschreibung und Zeichensetzung';

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
  String get newPdfNote => 'PDF hinzufügen, Notizen machen';

  @override
  String get imageNotePreparing =>
      'Bilder werden zu einem Dokument zusammengefügt…';

  @override
  String get newImageNote => 'Bild hinzufügen, Notizen machen';

  @override
  String get pdfPageNoteHint => 'Notiz zu dieser Seite …';

  @override
  String pdfPage(int page) {
    return 'Seite ${page}';
  }

  @override
  String pdfPageOf(int page, int total) {
    return 'Seite ${page} / ${total}';
  }

  @override
  String get pdfPreviousPage => 'Vorherige Seite';

  @override
  String get pdfNextPage => 'Nächste Seite';

  @override
  String get pdfFullScreen => 'Vollbild öffnen';

  @override
  String get pdfNoDocument => 'Diese Notiz hat noch kein PDF';

  @override
  String get pdfChooseDocument => 'PDF auswählen';

  @override
  String get newSlidesNote => 'Folien hinzufügen, Notizen machen';

  @override
  String get slidesNoDocument => 'Diese Notiz hat noch keine Präsentation';

  @override
  String get slidesChooseDocument => 'Präsentation auswählen';

  @override
  String get pdfEditPages => 'Seiten bearbeiten';

  @override
  String get pdfDeletePages => 'Ausgewählte Seiten löschen';

  @override
  String get pdfAddBlankPage => 'Leere Seite hinzufügen';

  @override
  String get pdfRotatePages => 'Drehen';

  @override
  String get pdfBurnInk => 'Handschrift ins Dokument einbrennen';

  @override
  String get pdfApplyChanges => 'Änderungen übernehmen';

  @override
  String get pdfCannotDeleteAllPages => 'Du kannst nicht alle Seiten löschen';

  @override
  String get pdfPagesHint =>
      'Tippe auf eine Seite, um sie auszuwählen. Seitennotizen bleiben bei ihrer Seite; die Notiz einer gelöschten Seite wird ausgeblendet, aber in deinen Daten behalten.';

  @override
  String pdfEditFailed(String error) {
    return 'PDF konnte nicht bearbeitet werden: ${error}';
  }

  @override
  String get pdfInkBurned => 'Handschrift ins Dokument eingebrannt';

  @override
  String get pdfAllPageNotes => 'Alle Seitennotizen';

  @override
  String get pdfNoPageNotes =>
      'Noch keine Seitennotizen. Blättere zu einer Seite und schreibe unten ins Feld.';

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
  String get inkArrow => 'Pfeil';

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
  String get aiChatWithNotes => 'Notiz-Assistent';

  @override
  String get aiChatInputHint => 'Frage etwas zu deinen Notizen…';

  @override
  String get aiChatLooking => 'durchsuche deine Notizen…';

  @override
  String get aiChatFullScreen => 'Vollbild';

  @override
  String get aiOnYourNotes => 'ZU DEINEN NOTIZEN';

  @override
  String get aiTaskDuplicates => 'Duplikate bereinigen';

  @override
  String aiTaskDuplicatesInfo(int count) {
    return '$count doppelte Notizen';
  }

  @override
  String get duplicatesTitle => 'Doppelte Notizen';

  @override
  String get duplicatesHint =>
      'Die älteste Notiz jeder Gruppe bleibt erhalten, der Rest wandert in den Papierkorb.';

  @override
  String get duplicatesKeepBadge => 'bleibt';

  @override
  String get duplicatesDeleteAll => 'Duplikate in den Papierkorb';

  @override
  String duplicatesDone(int count) {
    return '$count Duplikate in den Papierkorb verschoben';
  }

  @override
  String get aiRecentActions => 'LETZTE AKTIONEN';

  @override
  String get aiHistoryClear => 'Leeren';

  @override
  String get aiHistoryQuestion => 'Frage';

  @override
  String get aiHistoryNoteAction => 'Notizaktion';

  @override
  String get aiHistoryVoiceNote => 'Sprachnotiz';

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
  String get sortActive => 'Am meisten bearbeitet';

  @override
  String get voicePreview => 'Stimme testen';

  @override
  String get voicePreviewCached =>
      'Das Beispiel wird einmal erzeugt und danach lokal abgespielt';

  @override
  String get reorderHint =>
      'Karte gedrückt halten und an die gewünschte Stelle ziehen';

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
  String get filterFavoriteHint =>
      'Tippe auf einen Stern, um die Option auf dem Startbildschirm zu behalten';

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
  String get attachNoteContent => 'Notizinhalt';

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

  @override
  String scanReviewPage(int current, int total) {
    return 'Seite ${current} / ${total}';
  }

  @override
  String get scanRotatePage => 'Seite drehen';

  @override
  String get scanDeletePage => 'Seite löschen';

  @override
  String get scanLastPage => 'Die letzte Seite kann nicht gelöscht werden';

  @override
  String get scanDiscardTitle => 'Gescannte Seiten verwerfen?';

  @override
  String get scanDiscardConfirm => 'Verwerfen';

  @override
  String get scanAdjustCorners => 'Ecken anpassen';

  @override
  String get scanFilterOriginal => 'Original';

  @override
  String get scanFilterAuto => 'Verbessern';

  @override
  String get scanFilterGray => 'Graustufen';

  @override
  String get scanFilterBw => 'Schwarz-Weiß';

  @override
  String get scanApplyAll => 'Auf alle anwenden';

  @override
  String get scanPageFailed => 'Die Seite konnte nicht angezeigt werden';

  @override
  String get scanCropHint =>
      'Eine schiefe Seite mit "Ecken anpassen" korrigieren';

  @override
  String get scanAddAsPdf => 'Als PDF hinzufügen';

  @override
  String get scanAddAsImages => 'Als Bilder hinzufügen';

  @override
  String get scanBuildingPdf => 'PDF wird vorbereitet …';

  @override
  String scanOcrProgress(int done, int total) {
    return 'Text wird erkannt … ${done}/${total}';
  }

  @override
  String get scanAutoDetect => 'Kanten automatisch erkennen';

  @override
  String get scanReset => 'Zurücksetzen';

  @override
  String get scanDetecting => 'Kanten werden gesucht …';

  @override
  String get scanAutoFound =>
      'Kanten automatisch gefunden; bei Bedarf mit den Griffen feinjustieren';

  @override
  String get scanDragHint => 'Zieh die Ecken an die Ränder des Blattes';

  @override
  String get scanApplyCorners => 'Ausrichten & übernehmen';

  @override
  String get scanWorking => 'Wird ausgerichtet …';

  @override
  String get scanPdfAdded => 'Scan als PDF-Anhang zur Notiz hinzugefügt';

  @override
  String get premiumTitle => 'Premium';

  @override
  String premiumStatusActive(String date) {
    return 'Premium aktiv — bis ${date}';
  }

  @override
  String get premiumStatusFree => 'Du nutzt die kostenlose Version';

  @override
  String get premiumPerksTitle => 'Was ändert sich mit Premium?';

  @override
  String get premiumPerkAi => 'Tägliche KI-Punkte';

  @override
  String get premiumPerkAttach => 'Anhanggröße';

  @override
  String get premiumPerkStorage => 'Cloud-Speicher';

  @override
  String get premiumPerkAuto => 'Automatische Tagesinhalte';

  @override
  String get premiumPerkAutoBody =>
      'Das tägliche Briefing und die Vorschläge werden jeden Tag automatisch erstellt; in der kostenlosen Version laufen sie nur auf Anfrage.';

  @override
  String get premiumHowTitle => 'Wie bekomme ich es?';

  @override
  String get premiumHowBody =>
      'Premium gibt es bald über den Play Store. Zurzeit sind wir im frühen Zugang.';

  @override
  String get premiumByokHint =>
      'Wenn du deinen eigenen Gemini-API-Schlüssel einträgst, laufen die KI-Funktionen ohne Kontingent — unabhängig von Premium (Einstellungen → KI).';

  @override
  String get premiumDiscoverTitle => 'Funktionen, die du vielleicht übersehen hast';

  @override
  String get discoverScanBody =>
      'Gescannte Seiten werden ausgerichtet und verbessert und mit einem Tippen in ein DURCHSUCHBARES PDF verwandelt — die Textebene entsteht auf dem Gerät, kostenlos.';

  @override
  String get discoverSemanticBody =>
      'Der Tab "Smart" im Suchfeld sucht nach BEDEUTUNG statt nach Wörtern: Tippe "Flugzeiten" und deine Reisenotiz taucht auf.';

  @override
  String get discoverAssistantBody =>
      'Das Mikrofon auf dem Startbildschirm macht aus deiner Sprache von selbst Notizen, Listen und Erinnerungen — sag einfach "morgen um 9 zum Zahnarzt".';

  @override
  String get discoverLockBody =>
      'Du kannst eine Notiz mit Fingerabdruck/Gesicht sperren: Ihr Inhalt taucht nie in Suche, Widgets oder KI auf.';

  @override
  String get discoverHiddenBody =>
      'Notizen in einem versteckten Ordner erscheinen nie auf dem Startbildschirm oder in der Suche; den Ordner sichtbar zu machen erfordert eine Authentifizierung.';

  @override
  String get discoverExportBody =>
      'Jede Notiz lässt sich als PDF oder Word exportieren, Bilder inklusive (im Teilen-Menü).';

  @override
  String get guestSignInUnavailable =>
      'Anmeldung ohne Google ist derzeit deaktiviert: In der Firebase-Konsole ist die anonyme Anmeldung nicht aktiviert. Melde dich mit Google an oder versuche es erneut, sobald ein Administrator sie aktiviert.';

  @override
  String get googleSignInUnavailable =>
      'Google-Anmeldung ist derzeit deaktiviert: Der Google-Anbieter ist in der Firebase-Konsole nicht aktiviert.';

  @override
  String get signInNetworkError =>
      'Kein Internet erreichbar. Prüfe deine Verbindung und versuche es erneut.';

  @override
  String get signInCanceled => 'Anmeldung abgebrochen.';

  @override
  String get cardRichPreview => 'Formatierter Text auf Karten';

  @override
  String get cardRichPreviewInfo =>
      'Farben, Hervorhebungen, Fett und Unterstreichungen deiner Notizen erscheinen auch auf den Karten der Startseite. Aus: Karten zeigen einfachen Text.';

  @override
  String get fontSizeSmall => 'Klein';

  @override
  String get fontSizeMedium => 'Mittel';

  @override
  String get fontSizeLarge => 'Groß';

  @override
  String get fontSizeXLarge => 'Sehr groß';

  @override
  String get appFontSetting => 'Schriftart';

  @override
  String get appFontInfo =>
      'Die Schriftart der ganzen App. Die eigene Schriftart einer Notiz hat Vorrang. Alle Schriftarten sind in der App enthalten — kein Internet nötig.';

  @override
  String get fontGroupSans => 'Serifenlos';

  @override
  String get fontGroupSerif => 'Serif';

  @override
  String get fontGroupMono => 'Monospace';

  @override
  String get fontGroupHand => 'Handschrift';

  @override
  String get appFontDefaultSuffix => 'Standard';

  @override
  String get pdfSelectOcrRunning => 'Text wird erkannt …';

  @override
  String get pdfSelectOcrNone => 'Auf dieser Seite wurde kein Text gefunden';

  @override
  String pdfSelectCopied(int n) {
    return '${n} Zeichen kopiert';
  }

  @override
  String get bubbleAdd => 'Notizblase setzen';

  @override
  String get bubbleAddDone => 'Blasen fertig gesetzt';

  @override
  String get bubbleCollapse => 'Blase einklappen';

  @override
  String get bubbleHint => 'Schreib deine Notiz hier …';

  @override
  String get bubbleTapToPlace => 'Tippe auf die Stelle der Seite, wo die Blase hin soll';

  @override
  String get aiModelPodcast => 'Podcast-Erzählung';

  @override
  String get listenAiVoice => 'Mit KI-Stimme anhören';

  @override
  String get listenAiVoiceInfo =>
      'Gemini liest statt der Gerätestimme: natürlicher, aber jeder Absatz kostet einen Modellaufruf.';

  @override
  String listenAiVoiceFailed(String error) {
    return 'KI-Erzählung fehlgeschlagen (${error}). Es wird mit der Gerätestimme gelesen.';
  }

  @override
  String get ttsSectionTitle => 'Erzählung';

  @override
  String get ttsEngineDevice => 'Gerätestimme';

  @override
  String get ttsEngineAi => 'KI';

  @override
  String get ttsEngineDeviceInfo =>
      'Die eingebaute Gerätestimme liest vor: kostenlos, offline und ohne Längenbegrenzung.';

  @override
  String get ttsEngineAiInfo =>
      'Das Sprachmodell von Gemini liest vor: deutlich natürlicher, aber jeder Absatz ist ein Modellaufruf und es braucht deinen eigenen Gemini-Schlüssel.';

  @override
  String get ttsEngineAiUnavailable =>
      'Die KI-Stimme braucht deinen eigenen Gemini-Schlüssel. Bis dahin liest die Gerätestimme vor.';

  @override
  String get ttsModel => 'Sprachmodell';

  @override
  String get ttsVoice => 'KI-Stimme';

  @override
  String get shareAsNote => 'Als Notiz teilen';

  @override
  String get shareAsNoteInfo =>
      'Sendet die Notiz mit Anhängen, Seitennotizen, Zeichnungen und Blasen; die andere Seite öffnet sie in der Not-App genau gleich.';

  @override
  String get shareAsNotePreparing => 'Notizpaket wird vorbereitet …';

  @override
  String get shareAsText => 'Als reiner Text';

  @override
  String get shareAsTextInfo =>
      'Sendet den Text der Notiz und die Seitennotizen an eine beliebige App.';

  @override
  String get shareAsTextEmpty => 'Diese Notiz enthält keinen Text zum Teilen.';

  @override
  String get sharePdfWithBubbles => 'Als PDF mit Sprechblasen';

  @override
  String get sharePdfWithBubblesInfo =>
      'Sprechblasen, Markierungen und Zeichnungen werden in die PDF eingebrannt; jeder kann sie öffnen, in Not öffnet sie sich bearbeitbar.';

  @override
  String get sharePdfWithBubblesNone =>
      'In dieser Notiz gibt es keine PDF mit Sprechblasen oder Zeichnungen.';

  @override
  String get sharePdfWithBubblesPreparing =>
      'PDF mit Sprechblasen wird vorbereitet…';

  @override
  String get sharePdfWithBubblesSuffix => ' (mit Sprechblasen)';

  @override
  String get bubbleStar => 'Markieren';

  @override
  String get bubbleEdit => 'Blase bearbeiten';

  @override
  String get bubbleStarredOnly => 'Nur markierte';

  @override
  String get bubbleSearchHint => 'Blasen durchsuchen …';

  @override
  String get bubblesOverviewTitle => 'Blasen';

  @override
  String get bubblesEmpty =>
      'Noch keine Blasen. Markiere Text im Dokument oder setze eine Blase auf die Seite.';

  @override
  String get bubblesNoMatch => 'Keine Blase passt zu deiner Suche.';

  @override
  String get bubbleNoText => '(leere Blase)';

  @override
  String get pdfHighlight => 'Hervorheben';

  @override
  String get pdfHighlightWithNote => 'Hervorheben + Notiz';

  @override
  String get pageNotesShow => 'Seitennotiz zeigen';

  @override
  String get pageNotesHide => 'Seitennotiz ausblenden';

  @override
  String get bubbleSave => 'Speichern';

  @override
  String get bubbleTitleHint => 'Titel';

  @override
  String get bubbleUrgent => 'Dringend (blinkt)';

  @override
  String get captureModeQuestion => 'Wie soll die Notiz geöffnet werden?';

  @override
  String get captureModeBubbles => 'Blasen';

  @override
  String get captureModeBubblesInfo =>
      'Der Inhalt wird zu einer Dokumentseite: Blasen, Hervorhebungen und Stift.';

  @override
  String get captureModeClassic => 'Klassisch';

  @override
  String get captureModeClassicInfo =>
      'Einfache Textnotiz; der Inhalt kommt als Anhang hinein.';

  @override
  String get captureModeNew => 'NEU';

  @override
  String get imagePrepareTitle => 'Bilder anpassen';

  @override
  String get imagePrepareDone => 'Weiter';

  @override
  String get imageRotateLeft => 'Nach links drehen';

  @override
  String get imageRotateRight => 'Nach rechts drehen';

  @override
  String get videoFrameFailed =>
      'Aus dem Video konnte kein Bild geholt werden; es wird eine klassische Notiz geöffnet.';

  @override
  String get bubbleArrowHide => 'Pfeil ausblenden';

  @override
  String get bubbleArrowShow => 'Pfeil zeigen';

  @override
  String get speechPitch => 'Stimmhöhe';

  @override
  String get speechVoicePickerTitle => 'Stimmenauswahl';

  @override
  String get formatRemove => 'Entfernen';

  @override
  String get exportTitle => 'Exportieren';

  @override
  String get exportNotesOption => 'Notiztext (PDF / Word)';

  @override
  String get exportNotesOptionInfo =>
      'Text und Bilder der Notiz; Sprechblasen nicht enthalten.';

  @override
  String get captureNoteTitle => 'Notiztitel (optional)';

  @override
  String get captureNoteTitleHint => 'Das neue Dokument erhält denselben Namen';

  @override
  String get imageOcrTitle => 'Text im Bild erkennen';

  @override
  String get imageOcrNone => 'In diesem Bild wurde kein Text gefunden.';

  @override
  String imageOcrHint(int count) {
    return '$count Zeilen erkannt · zum Auswählen tippen';
  }

  @override
  String imageOcrSelected(int count) {
    return '$count Zeilen ausgewählt';
  }

  @override
  String get imageOcrShort => 'Text erkennen';

  @override
  String get imageOcrWorking => 'Text wird erkannt…';

  @override
  String get imageOcrSelectHint =>
      'Tippen: Wort · Halten und ziehen: Buchstabe für Buchstabe';

  @override
  String get imageOcrInsert => 'Zur Notiz hinzufügen';

  @override
  String get imageOcrZoomIn => 'Vergrößern';

  @override
  String get imageOcrZoomOut => 'Verkleinern';

  @override
  String get selectImages => 'Bilder auswählen';

  @override
  String get exportImages => 'Bilder';

  @override
  String get exportImagesInfo =>
      'Neben schmalen, links oder rechts ausgerichteten Bildern fließt Text; zentrierte Bilder nehmen die volle Breite ein.';

  @override
  String get exportAlignLeft => 'Links';

  @override
  String get exportAlignCenter => 'Mitte';

  @override
  String get exportAlignRight => 'Rechts';

  @override
  String get exportImageWidth => 'Breite';

  @override
  String get exportImageLine => 'Position';

  @override
  String get aiModelSearch => 'Modelle suchen';

  @override
  String get aiModelOthers => 'WEITERE MODELLE';

  @override
  String get aiModelNoMatch => 'Kein passendes Modell.';

  @override
  String get aiModelAutoInfo =>
      'Die App probiert der Reihe nach die passendsten Modelle.';

  @override
  String imageOcrCharsSelected(int count) {
    return '$count Zeichen ausgewählt';
  }

  @override
  String imagesSelectedCount(int count) {
    return '$count Bilder ausgewählt';
  }

  @override
  String attachmentsCopiedCount(int count) {
    return '$count Anhänge';
  }

  @override
  String exportImageLineOf(int count) {
    return '/ $count Zeilen';
  }

  @override
  String get aiModelShowAll => 'Alle anzeigen';

  @override
  String get aiModelShowAllInfo =>
      'Listet auch Modelle auf, die die App nicht verwendet.';

  @override
  String get rotateFailed => 'Das Bild konnte nicht gedreht werden.';

  @override
  String get dashboardBackgroundPick => 'Hintergrundbild wählen';

  @override
  String get dashboardBackgroundChange => 'Hintergrundbild ändern';

  @override
  String podcastRenderingAudio(int done, int total) {
    return 'Audio wird vorbereitet: ${done}/${total} Teile';
  }

  @override
  String get podcastExportAudio => 'Als Audiodatei exportieren';

  @override
  String get podcastExportAudioCost =>
      'Das ganze Skript wird mit der KI-Stimme neu vertont und als einzelne WAV-Datei gespeichert. Das verbraucht dein Gemini-Kontingent und kann bei langen Texten einige Minuten dauern.';

  @override
  String get podcastShareText => 'Skript teilen';

  @override
  String get podcastSaveAsNote => 'Als neue Notiz speichern';

  @override
  String get podcastSavedAsNote => 'Das Podcast-Skript wurde als Notiz gespeichert.';

  @override
  String get listenPreparingVoice => 'Audio wird vorbereitet …';

  @override
  String get appearancePreviewTitle => 'Beispieltext';

  @override
  String get appearancePreviewNoteTitle => 'Beispiel-Notiztitel';

  @override
  String get appearancePreviewBody =>
      'So werden deine Notizen aussehen. **Fett**, ~unterstrichen~ und ==2:hervorgehoben== im Text sieht so aus.';

  @override
  String get appearancePreviewItem => 'So sieht ein Checklisten-Eintrag aus';

  @override
  String get convertToText => 'In Text umwandeln';

  @override
  String get convertToList => 'In Liste umwandeln';

  @override
  String get convertedToText => 'Die Liste wurde in einfachen Text umgewandelt.';

  @override
  String get convertedToList => 'Der Text wurde in eine Liste umgewandelt.';

  @override
  String get convertToListEmpty => 'Es gibt keine Zeilen, die sich in eine Liste umwandeln lassen.';

  @override
  String get listTwoColumns => 'Zwei Spalten';

  @override
  String get listOneColumn => 'Eine Spalte';

  @override
  String get sortItems => 'Einträge sortieren';

  @override
  String get sortStarredFirst => 'Markierte zuerst';

  @override
  String get sortUncheckedFirst => 'Erledigte zuletzt';

  @override
  String get sortAlphabetical => 'A → Z';

  @override
  String get sortAlphabeticalDesc => 'Z → A';

  @override
  String get imagesToAttachments => 'Bilder zu Anhängen verschieben';

  @override
  String imagesToAttachmentsDone(int count) {
    return '${count} Bilder zu den Anhängen verschoben.';
  }

  @override
  String get imageOcrShowRecognized => 'Erkannten Text hervorheben';

  @override
  String get imageOcrHideRecognized => 'Hervorhebung ausblenden';

  @override
  String get bubblePlainMode => 'Offenes Textfeld';

  @override
  String get bubblePlainModeOn => 'Offenes Textfeld ist an';

  @override
  String get bubblePlainTapToPlace => 'Tippe dahin, wo der Text stehen soll';

  @override
  String get bubblePlainHint => 'Zum Schreiben tippen';

  @override
  String get noteSearchTitle => 'In der Notiz suchen';

  @override
  String get noteSearchHint => 'Diese Notiz durchsuchen …';

  @override
  String get noteSearchEmptyHint =>
      'Durchsucht sofort Notiztext, Einträge und Seitennotizen. Starte unten den Scan, um auch in Bild- und PDF-Anhängen zu suchen.';

  @override
  String get noteSearchNoHit => 'Keine Treffer gefunden.';

  @override
  String get noteSearchScanAttachments => 'Anhänge scannen';

  @override
  String get noteSearchAskAi => 'Die KI fragen';

  @override
  String get noteTitleLabel => 'Titel';

  @override
  String get noteBodyLabel => 'Notiztext';

  @override
  String get itemLabel => 'Eintrag';

  @override
  String noteSearchAttachmentsInfo(int count) {
    return '${count} Anhänge können gescannt werden (Bild/PDF).';
  }

  @override
  String noteSearchAttachmentsReady(int count) {
    return 'Es wird auch in ${count} Anhängen gesucht.';
  }

  @override
  String pageLabel(int page) {
    return 'Seite ${page}';
  }

  @override
  String get archiveNotebook => 'Archiv-Notizbuch';

  @override
  String get archiveNotebookInfo =>
      'Ein Notizbuch mit eigenen Seiten, das Kopien wichtiger Dokumente und Bilder aufbewahrt.';

  @override
  String get archivePageImages => 'Bilder';

  @override
  String get archivePageVideos => 'Videos';

  @override
  String get archivePageDocuments => 'Dokumente';

  @override
  String get archivePageTexts => 'Texte';

  @override
  String get archiveNewPage => 'Neue Seite';

  @override
  String get archivePageName => 'Seitenname (z. B. Rechnungen)';

  @override
  String get archivePageEmpty => 'Diese Seite ist leer.';

  @override
  String get archiveSearchHint => 'Notizbuch durchsuchen …';

  @override
  String get archiveAddText => 'Text hinzufügen';

  @override
  String get archiveAddFile => 'Datei hinzufügen';

  @override
  String get archiveCopyHere => 'In ein Archiv-Notizbuch kopieren';

  @override
  String get archiveNoNotebook =>
      'Noch kein Archiv-Notizbuch. Lege zuerst eines an.';

  @override
  String get archiveNothingToCopy => 'Diese Notiz hat keine Anhänge zum Kopieren.';

  @override
  String archiveDeleteEntry(String name) {
    return '"${name}" aus dem Notizbuch löschen? Diese Kopie ist endgültig weg.';
  }

  @override
  String archiveCopied(int count) {
    return '${count} Dateien ins Archiv-Notizbuch kopiert.';
  }

  @override
  String get archiveCaptureTitle => 'Aus Bild erfassen';

  @override
  String get archiveCapturePage => 'Seite';

  @override
  String get archiveCapturePageInfo =>
      'Der von der KI vorgeschlagene Typ. Leer gelassen landet es auf der Seite Texte.';

  @override
  String get archiveCaptureText => 'Erkannter Text';

  @override
  String get attachmentTagInsert => 'In den Text einfügen';

  @override
  String get attachmentTagInserted => 'Die Anhang-Markierung wurde eingefügt.';

  @override
  String get attachmentTagPreview => 'Anhang ansehen';

  @override
  String get attachmentTagEdit => 'Anhang bearbeiten';

  @override
  String archiveCardSummary(int files, int texts) {
    return '${files} Dateien · ${texts} Texte';
  }

  @override
  String get archiveEntryTitle => 'Titel';

  @override
  String get archiveLinkedFile => 'Verknüpfte Datei';

  @override
  String get archiveNoLink => 'Keine verknüpfte Datei';

  @override
  String get attachmentTagEmbed => 'Anhang in die Auswahl einbetten';

  @override
  String get attachmentTagNoAttachment =>
      'Füge der Notiz zuerst eine Datei hinzu, dann kannst du sie in den Text einbetten.';

  @override
  String get bubbleModeBubble => 'Blase';

  @override
  String get attachmentTagEmbedInfo =>
      'Verknüpft mit dem ausgewählten Text, oder an der Einfügemarke, wenn nichts ausgewählt ist';

  @override
  String get attachmentTagPickText =>
      'Wähle jetzt den Text zum Verknüpfen aus und tippe dann auf "Hier verknüpfen".';

  @override
  String get attachmentTagLinkHere => 'Hier verknüpfen';

  @override
  String attachmentTagPendingBanner(String name) {
    return '${name} wird verknüpft — wähle den Text aus';
  }

  @override
  String get docNameNotesSuffix => 'Notizen';

  @override
  String get docNamePhoto => 'Fotonotizen';

  @override
  String get docNameScan => 'Scan-Notizen';

  @override
  String get docNameImage => 'Bildnotizen';

  @override
  String get docNameVideo => 'Videonotizen';

  @override
  String get folderManage => 'Ordner verwalten';

  @override
  String get folderEmpty => 'Dieser Ordner ist leer';

  @override
  String get folderEmptyHint =>
      'Füge unten mit + eine Notiz hinzu oder verschiebe eine Notiz beim Bearbeiten hierher.';

  @override
  String get brainstormTitle => 'Mit KI brainstormen';

  @override
  String get brainstormRowInfo =>
      'Die KI entwirft zuerst eine Gliederung, dann baut ihr gemeinsam darauf auf';

  @override
  String get brainstormIntro =>
      'Tippe oben auf eine Überschrift oder schreib einfach los — denken wir gemeinsam.';

  @override
  String get brainstormOutlineTitle => 'GLIEDERUNG';

  @override
  String get brainstormInputHint => 'Schreib eine Idee oder stell eine Frage …';

  @override
  String get brainstormAddIdea => 'Zur Notiz hinzufügen';

  @override
  String get brainstormAdded => 'Zur Notiz hinzugefügt';

  @override
  String get folderShared => 'Dieser Ordner ist mit einer Freundin/einem Freund geteilt';

  @override
  String get friendsTitle => 'Kontakte';

  @override
  String get friendsAdd => 'Freund hinzufügen';

  @override
  String get friendsEmpty =>
      'Noch niemand. Füge jemanden per E-Mail hinzu, um Ordner zu teilen.';

  @override
  String get friendsRequestsTitle => 'ANFRAGEN';

  @override
  String get friendsListTitle => 'MEINE FREUNDE';

  @override
  String get friendsAddEmailHint => 'freund@email.com';

  @override
  String get friendsSendRequest => 'Anfrage senden';

  @override
  String get friendsRequestSent => 'Anfrage gesendet';

  @override
  String get friendsNotFound =>
      'Mit dieser E-Mail ist niemand registriert. Die Person muss die App mindestens einmal mit einem Google-Konto geöffnet haben.';

  @override
  String get friendsSelf => 'Du kannst dich nicht selbst als Freund hinzufügen';

  @override
  String get friendsAlready => 'Ihr seid bereits Freunde';

  @override
  String get friendsDecline => 'Ablehnen';

  @override
  String get friendsAccept => 'Annehmen';

  @override
  String get friendsRemove => 'Entfernen';

  @override
  String get friendsRemoveConfirmTitle => 'Freund entfernen';

  @override
  String friendsRemoveConfirmBody(Object name) {
    return '${name} aus deinen Freunden entfernen? Ordner, die du geteilt hast, sind dann nicht mehr sichtbar.';
  }

  @override
  String get friendsNeedsAccount =>
      'Kontakte und Ordnerfreigabe brauchen ein verknüpftes Google-Konto.';

  @override
  String get friendsSearchHint => 'Nach Name oder E-Mail suchen';

  @override
  String get friendsSearchTab => 'Suche';

  @override
  String get friendsSearchEmailTab => 'Per E-Mail';

  @override
  String get friendsSearchEmpty => 'Keine Ergebnisse';

  @override
  String get friendsSearchTooShort => 'Gib mindestens 2 Zeichen für die Suche ein';

  @override
  String get friendsSearchAdd => 'Hinzufügen';

  @override
  String get folderShare => 'Teilen';

  @override
  String folderShareCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Mit ${count} Personen geteilt',
      one: 'Mit 1 Person geteilt',
    );
    return '$_temp0';
  }

  @override
  String folderShareTitle(Object name) {
    return '"${name}" teilen';
  }

  @override
  String get folderShareInfo =>
      'Eine Einladung geht an die gewählte Person; sie sieht den Ordner, sobald sie annimmt. Du legst die Berechtigung fest (lesen / schreiben / beides).';

  @override
  String get friendsRowInfo => 'Freunde hinzufügen, Ordner mit ihnen teilen';

  @override
  String get accountRecoverConflictTitle =>
      'Auf diesem Gerät liegen ungesicherte Notizen';

  @override
  String accountRecoverConflictBody(Object count) {
    return 'Dieses Google-Konto ist bereits mit einer anderen Sitzung verknüpft; ein Wechsel blendet die ${count} Notiz(en) auf diesem Gerät aus (sie werden nicht gelöscht, sind von hier aber nicht mehr erreichbar). Trotzdem fortfahren?';
  }

  @override
  String get accountRecoverConflictProceed => 'Trotzdem wechseln';
  @override
  String get folderRoleRead => 'Lesen';

  @override
  String get folderRoleWrite => 'Schreiben';

  @override
  String get folderRoleBoth => 'Lesen + schreiben';

  @override
  String get folderInvitePending => 'Einladung gesendet, Antwort steht aus';

  @override
  String get folderWriteOnlyTitle => 'Du hast nur Schreibzugriff';

  @override
  String get folderWriteOnlyHint => 'Du kannst neue Notizen in diesen Ordner legen, die Notizen darin aber nicht sehen.';

  @override
  String get folderChatTitle => 'Chat';

  @override
  String get folderChatHint => 'Schreib eine Nachricht …';

  @override
  String get folderChatSend => 'Senden';

  @override
  String get folderChatEmptyTitle => 'Noch keine Nachrichten';

  @override
  String get folderChatEmptyHint => 'Sprich hier mit den Personen, mit denen du diesen Ordner geteilt hast.';

  @override
  String get folderInviteTitle => 'Ordnereinladung';

  @override
  String folderInviteBody(Object name) {
    return 'Der Ordner "${name}" wurde mit dir geteilt.';
  }

  @override
  String get folderInviteAccepted => 'Ordner hinzugefügt';

  @override
  String get folderInviteDeclined => 'Einladung abgelehnt';

  @override
  String friendRequestBanner(Object name) {
    return '${name} hat dir eine Freundschaftsanfrage geschickt';
  }

  @override
  String get friendRequestAccepted => 'Freund hinzugefügt';

  @override
  String get sendNoteAction => 'An einen Freund senden';

  @override
  String get sendNoteTitle => 'Notiz an einen Freund senden';

  @override
  String get sendNoteInfo => 'Eine Kopie der Notiz landet im Postfach "Eingehende Notizen" der Person. Anhänge (Bilder, Dokumente, Audio) werden nicht mitgesendet.';

  @override
  String sendNoteSent(Object name) {
    return 'Notiz an ${name} gesendet';
  }

  @override
  String get inboxTitle => 'Eingehende Notizen';

  @override
  String get inboxEmpty => 'Keine eingehenden Notizen';

  @override
  String get inboxEmptyHint => 'Notizen, die dir deine Freunde schicken, sammeln sich hier.';

  @override
  String inboxFrom(Object name) {
    return 'Gesendet von ${name}';
  }

  @override
  String get inboxAccept => 'Zu meinen Notizen hinzufügen';

  @override
  String get inboxAccepted => 'Notiz zu deinen Notizen hinzugefügt';

  @override
  String get folderShelfExpand => 'Ordner ausklappen';

  @override
  String get folderShelfCollapse => 'Ordner einklappen';

  @override
  String get accountSheetLocalInfo => 'Deine Notizen liegen nur auf diesem Gerät. Verknüpfe ein Google-Konto, um sie zu sichern und Freunde hinzuzufügen.';

  @override
  String get accountSettings => 'Kontoeinstellungen';
}
