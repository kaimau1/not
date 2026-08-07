// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appName => 'Notatki';

  @override
  String get loginTagline => 'Twoje notatki na każdym urządzeniu';

  @override
  String get signInWithGoogle => 'Zaloguj się przez Google';

  @override
  String loginError(String error) {
    return 'Logowanie nie powiodło się: $error';
  }

  @override
  String get searchHint => 'Szukaj w notatkach...';

  @override
  String get filterAll => 'Wszystkie';

  @override
  String get filterText => 'Tekst';

  @override
  String get filterChecklist => 'Lista';

  @override
  String get filterOrdered => 'Numerowana';

  @override
  String get filterPinned => 'Przypięte';

  @override
  String get filterStarred => 'Oznaczone gwiazdką';

  @override
  String get star => 'Dodaj gwiazdkę';

  @override
  String get unstar => 'Usuń gwiazdkę';

  @override
  String editedAt(String date) {
    return 'Edytowano: $date';
  }

  @override
  String get sectionPinned => 'Przypięte';

  @override
  String get sectionOthers => 'Pozostałe';

  @override
  String get emptyNotes => 'Nie ma jeszcze notatek';

  @override
  String get emptyNotesHint => 'Naciśnij +, aby utworzyć pierwszą notatkę';

  @override
  String get emptySearch => 'Brak wyników';

  @override
  String get newTextNote => 'Notatka tekstowa';

  @override
  String get newChecklist => 'Lista';

  @override
  String get newOrderedList => 'Lista numerowana';

  @override
  String get noteDeleted => 'Notatka usunięta';

  @override
  String notesDeletedCount(int count) {
    return 'Usunięto notatki: $count';
  }

  @override
  String selectedCount(int count) {
    return 'Zaznaczono: $count';
  }

  @override
  String get deleteSelected => 'Usuń zaznaczone';

  @override
  String get undo => 'Cofnij';

  @override
  String get redo => 'Ponów';

  @override
  String get titleHint => 'Tytuł';

  @override
  String get bodyHint => 'Notatka...';

  @override
  String get newItemHint => 'Nowa pozycja';

  @override
  String moreItemsCount(int count) {
    return '+$count innych pozycji';
  }

  @override
  String get addAttachment => 'Dodaj';

  @override
  String get addAttachmentMore => 'Więcej typów załączników…';

  @override
  String get addImage => 'Dodaj obraz';

  @override
  String get addPdf => 'Dodaj PDF';

  @override
  String get addSlide => 'Dodaj slajdy';

  @override
  String get pasteImage => 'Wklej obraz ze schowka';

  @override
  String get clipboardEmpty => 'W schowku nie ma obrazu';

  @override
  String get noNoteSelected => 'Wybierz notatkę po lewej';

  @override
  String attachmentFailed(String error) {
    return 'Nie udało się dodać załącznika: $error';
  }

  @override
  String get attachmentUploading => 'Przesyłanie...';

  @override
  String get attachmentUploadFailed =>
      'Yüklenemedi — yeniden denemek için dokun';

  @override
  String get attachmentNotSynced =>
      'Ten plik nie został jeszcze zsynchronizowany na tym urządzeniu';

  @override
  String attachmentTooLarge(int limit) {
    return 'Plik jest za duży (maksymalnie $limit MB)';
  }

  @override
  String storageFull(String limit) {
    return 'Brak miejsca w pamięci ($limit). Usuń stare załączniki, aby zwolnić miejsce.';
  }

  @override
  String get storageUsage => 'Pamięć';

  @override
  String storageUsageValue(String used, String limit) {
    return 'Użyto $used z $limit';
  }

  @override
  String get removeAttachment => 'Usuń załącznik';

  @override
  String get pin => 'Przypnij';

  @override
  String get unpin => 'Odepnij';

  @override
  String get delete => 'Usuń';

  @override
  String get color => 'Kolor';

  @override
  String get aiTitle => 'AI';

  @override
  String get aiSummarize => 'Podsumuj notatkę';

  @override
  String get aiAnalyze => 'Analizuj';

  @override
  String get aiSectionNote => 'Ta notatka';

  @override
  String get aiSectionAttachments => 'Załączniki';

  @override
  String get summarize => 'Podsumuj';

  @override
  String get summaryDetailTitle => 'Rodzaj podsumowania';

  @override
  String get summaryShort => 'Krótkie podsumowanie';

  @override
  String get summaryShortInfo =>
      'Kilka zdań przeglądu oraz najważniejsze punkty';

  @override
  String get summaryDetailed => 'Szczegółowe podsumowanie';

  @override
  String get summaryDetailedInfo =>
      'Na tyle pełne, że nie trzeba otwierać oryginału';

  @override
  String get listen => 'Słuchaj';

  @override
  String get ask => 'Zadaj pytanie';

  @override
  String get extractText => 'Wyodrębnij tekst';

  @override
  String get transcribe => 'Zapisz mowę';

  @override
  String get listenToNote => 'Przeczytaj na głos';

  @override
  String get aiNoApiKey =>
      'Najpierw wprowadź swój klucz API Gemini w ustawieniach';

  @override
  String aiError(String error) {
    return 'Żądanie do AI nie powiodło się: $error';
  }

  @override
  String get aiSummaryTitle => 'Podsumowanie AI';

  @override
  String get aiThinking => 'Myślę...';

  @override
  String get copy => 'Kopiuj';

  @override
  String get copied => 'Skopiowano';

  @override
  String get settingsSearchHint =>
      'Przeszukaj ustawienia — „briefing”, „mikrofon”';

  @override
  String settingsSearchEmpty(String query) {
    return 'Brak ustawień pasujących do „$query”';
  }

  @override
  String get settings => 'Ustawienia';

  @override
  String get settingsAppearance => 'Wygląd';

  @override
  String get themeSystem => 'Systemowy';

  @override
  String get themeLight => 'Jasny';

  @override
  String get themeDark => 'Ciemny';

  @override
  String get settingsAi => 'AI';

  @override
  String get geminiApiKey => 'Klucz API Gemini';

  @override
  String get geminiApiKeyHint => 'Wklej klucz zaczynający się od AIza...';

  @override
  String get geminiApiKeyInfo =>
      'Klucz jest opcjonalny: bez niego żądania AI przechodzą przez wbudowaną usługę aplikacji (darmowy dzienny limit, większy w wersji Premium). Aby korzystać bez ograniczeń z własnym kluczem, odbierz darmowy klucz na aistudio.google.com; klucz jest przechowywany wyłącznie na tym urządzeniu, w bezpiecznym magazynie.';

  @override
  String aiBuiltInPremium(int count) {
    return 'Wbudowane AI: Premium — pozostało dziś punktów: $count';
  }

  @override
  String aiBuiltInRemaining(int count) {
    return 'Wbudowane AI: pozostało dziś darmowych punktów: $count';
  }

  @override
  String get aiBuiltInByok => 'Z własnym kluczem — bez ograniczeń';

  @override
  String get aiReport => 'Zgłoś tę odpowiedź';

  @override
  String get aiReportThanks => 'Zgłoszenie przyjęte, dziękujemy';

  @override
  String get privacyPolicyTitle => 'Polityka prywatności';

  @override
  String get lockNote => 'Zablokuj';

  @override
  String get unlockNote => 'Odblokuj';

  @override
  String get lockedNote => 'Zablokowana notatka';

  @override
  String get unlockAuthReason =>
      'Potwierdź tożsamość, aby otworzyć zablokowaną notatkę';

  @override
  String get exportBackup => 'Eksportuj kopię zapasową (JSON)';

  @override
  String get expandListItems => 'Pokazuj wiersze listy w całości';

  @override
  String get expandListItemsInfo =>
      'Długie pozycje zawijają się na kilka wierszy i pozostają w całości widoczne. Po wyłączeniu wiersz mieści się w jednej linii i rozwija po dotknięciu.';

  @override
  String get quickCaptureRowSetting => 'Pasek szybkiej notatki';

  @override
  String get quickCaptureRowInfo =>
      'Pokazuje jednowierszowe pole „Nowa notatka...\" u góry. Gdy wyłączone, użyj przycisku +.';

  @override
  String get emptyTrash => 'Opróżnij kosz';

  @override
  String emptyTrashConfirm(int count) {
    return 'Notatki zostaną trwale usunięte: $count. Tej operacji nie można cofnąć. Na pewno?';
  }

  @override
  String get trashEmptied => 'Kosz opróżniony';

  @override
  String get validateAndSave => 'Sprawdź i zapisz';

  @override
  String get clear => 'Wyczyść';

  @override
  String get aiDiagnostics => 'Diagnostyka AI';

  @override
  String get aiDiagnosticsEmpty => 'Nie zarejestrowano żadnych błędów';

  @override
  String aiDiagnosticsCount(int count) {
    return 'Ostatnie wpisy o błędach: $count';
  }

  @override
  String get apiKeyValid => 'Klucz API sprawdzony i zapisany';

  @override
  String get apiKeyInvalid => 'Klucz API jest nieprawidłowy';

  @override
  String get apiKeySavedBadge => 'Zapisany';

  @override
  String get removeApiKey => 'Usuń klucz';

  @override
  String get refresh => 'Odśwież';

  @override
  String get account => 'Konto';

  @override
  String get signOut => 'Wyloguj się';

  @override
  String get signOutConfirm => 'Czy na pewno chcesz się wylogować?';

  @override
  String get signOutAnonymousWarning =>
      'Używasz konta lokalnego: po wylogowaniu to konto i WSZYSTKIE notatki będą trwale niedostępne — bez kopii zapasowej nie da się ich odzyskać. Najpierw połącz konto Google. Wylogować mimo to?';

  @override
  String get deleteAccount => 'Usuń moje konto i dane';

  @override
  String get deleteAccountWarning =>
      'Tej operacji nie można cofnąć: wszystkie notatki, załączniki i konto zostaną trwale usunięte. Kontynuować?';

  @override
  String get deleteAccountConfirm => 'Usuń trwale';

  @override
  String get licensesTitle => 'Licencje open source';

  @override
  String get generating => 'Generowanie...';

  @override
  String get retry => 'Spróbuj ponownie';

  @override
  String get cancel => 'Anuluj';

  @override
  String get close => 'Zamknij';

  @override
  String get ok => 'OK';

  @override
  String get syncPending => 'Oczekiwanie na synchronizację';

  @override
  String get synced => 'Zsynchronizowano';

  @override
  String genericError(String error) {
    return 'Coś poszło nie tak: $error';
  }

  @override
  String get addTag => 'Etykieta';

  @override
  String get tagHint => 'np. praca, dom, szkoła';

  @override
  String get addReminder => 'Przypomnij mi';

  @override
  String get share => 'Udostępnij';

  @override
  String get archive => 'Archiwizuj';

  @override
  String get unarchive => 'Przywróć z archiwum';

  @override
  String get archiveTitle => 'Archiwum';

  @override
  String get archiveEmpty => 'W archiwum nie ma notatek';

  @override
  String get trashTitle => 'Kosz';

  @override
  String get trashEmpty => 'Kosz jest pusty';

  @override
  String get trashInfo =>
      'Usunięte notatki pozostają tutaj; możesz je przywrócić albo usunąć na dobre.';

  @override
  String get restore => 'Przywróć';

  @override
  String get deleteForever => 'Usuń trwale';

  @override
  String get deleteForeverConfirm =>
      'Ta notatka zostanie trwale usunięta. Na pewno?';

  @override
  String assistantDeleteConfirm(String title) {
    return 'Asistan \"$title\" notunu çöp kutusuna taşımak istiyor. Onaylıyor musun?';
  }

  @override
  String get recordAudio => 'Nagranie głosowe';

  @override
  String get recording => 'Nagrywanie...';

  @override
  String get stopAndSave => 'Zakończ i dodaj';

  @override
  String get micPermissionDenied => 'Odmówiono dostępu do mikrofonu';

  @override
  String get speechRecognitionFailed =>
      'Rozpoznawanie mowy nie zadziałało. Sprawdź, czy przyznano dostęp do mikrofonu i czy aplikacja Google jest aktualna.';

  @override
  String get addDrawing => 'Dodaj rysunek';

  @override
  String get drawingTitle => 'Rysunek';

  @override
  String get addToNote => 'Dodaj do notatki';

  @override
  String get chatTitle => 'Asystent notatek';

  @override
  String get chatHint =>
      'Zapytaj o swoje notatki: «co to był za przepis, który zapisałem w zeszłym tygodniu?», «czego brakuje na liście zakupów?»';

  @override
  String get chatInputHint => 'Wpisz pytanie...';

  @override
  String get fontSize => 'Rozmiar tekstu';

  @override
  String get fontSizePreview => 'Tak będą wyglądać Twoje notatki';

  @override
  String get darkSchedule => 'Harmonogram ciemnego motywu';

  @override
  String get darkScheduleInfo =>
      'Przełącza na ciemny motyw między wskazanymi godzinami';

  @override
  String get aiTranslate => 'Przetłumacz';

  @override
  String get voiceCommand => 'Polecenie głosowe';

  @override
  String get semanticSearchToggle => 'Wyszukiwanie znaczeniowe z AI';

  @override
  String get semanticSearchHint => 'Szukaj po znaczeniu: «koszty samochodu»...';

  @override
  String get briefingTitle => 'Podsumowanie dnia';

  @override
  String get briefingLoading => 'Przygotowuję podsumowanie...';

  @override
  String get briefingEmpty => 'Nic na dzisiaj';

  @override
  String get briefingSetting => 'Powiadomienie z podsumowaniem dnia';

  @override
  String get briefingSettingInfo =>
      'Otrzymuj każdego ranka o wybranej godzinie powiadomienie z podsumowaniem dnia';

  @override
  String get autoTagSetting => 'Etykietuj automatycznie';

  @override
  String get autoTagSettingInfo =>
      'Gdy notatka zostanie zamknięta bez etykiet, AI dopisze pasującą';

  @override
  String get suggestTags => 'Zaproponuj etykiety';

  @override
  String get aiFixNote => 'Popraw notatkę';

  @override
  String get fixLevelTitle => 'Jak mocno poprawiać?';

  @override
  String get fixSimple => 'Lekko';

  @override
  String get fixSimpleInfo => 'Tylko pisownia i literówki';

  @override
  String get fixBalanced => 'Umiarkowanie';

  @override
  String get fixBalancedInfo =>
      'Także budowa zdań, żeby tekst był czytelniejszy';

  @override
  String get fixDetailed => 'Dogłębnie';

  @override
  String get fixDetailedInfo => 'Przepisuje cały tekst od początku do końca';

  @override
  String get existingTagsLabel => 'Wcześniejsze etykiety';

  @override
  String get aiSkipCheckedSetting =>
      'Pomijaj zaznaczone pozycje przy zmianach AI';

  @override
  String get aiSkipCheckedInfo =>
      'Gdy AI poprawia lub tłumaczy listę, ukończone (zaznaczone) pozycje pozostają dokładnie takie, jakie są; zmieniane są tylko niezaznaczone.';

  @override
  String get noteUpdatedUndo => 'Notatka zaktualizowana';

  @override
  String get aiImprove => 'Ulepsz notatkę';

  @override
  String get improveFormal => 'Nadaj bardziej formalny ton';

  @override
  String get improveShorten => 'Skróć';

  @override
  String get improveBullets => 'Zamień na listę punktowaną';

  @override
  String get improveNumbered => 'Zamień na listę numerowaną';

  @override
  String get replaceNote => 'Zastąp notatkę';

  @override
  String get openAsNewNote => 'Jako nowa notatka';

  @override
  String get pdfChatHint =>
      'Zapytaj o ten PDF: «streść go», «czy jest klauzula o karze umownej?», «jaki jest termin?»';

  @override
  String get pdfChatInputHint => 'Wpisz pytanie o ten PDF...';

  @override
  String get voiceCaptureHint =>
      'Mów: «kupić mleko i chleb» albo «jutro o 9 spotkanie, przypomnij mi» — gdy skończysz, AI napisze notatkę.';

  @override
  String get voiceFinish => 'Zakończ';

  @override
  String get voiceProcessing => 'Przetwarzam to, co powiedziałeś...';

  @override
  String get voiceNothingHeard => 'W nagraniu nie wykryto mowy';

  @override
  String get voiceNoteSaved => 'Notatka głosowa została zapisana';

  @override
  String get openNote => 'Otwórz notatkę';

  @override
  String get remindersTitle => 'Przypomnienia';

  @override
  String get remindersEmpty => 'Brak przypomnień';

  @override
  String get remindersEmptyHint =>
      'Dodaj przypomnienie do notatki albo utwórz nową notatkę z przypomnieniem przyciskiem +';

  @override
  String get remindersUpcoming => 'Nadchodzące';

  @override
  String get remindersPast => 'Minione';

  @override
  String get reminderInPast =>
      'Wybrany czas już minął — wybierz czas w przyszłości.';

  @override
  String get newReminder => 'Nowe przypomnienie';

  @override
  String get remindersUntitled => 'Notatka bez tytułu';

  @override
  String get remindersEdit => 'Zmień godzinę';

  @override
  String get remindersRemove => 'Usuń przypomnienie';

  @override
  String get aiModelChat => 'Podsumowania, tytuły, etykiety i rozmowa';

  @override
  String get aiModelDocument => 'Podcasty i rozmowa o dokumentach';

  @override
  String get aiModelTranslate => 'Tłumaczenie';

  @override
  String get aiModelVoice => 'Notatki głosowe';

  @override
  String get aiModelAuto => 'Automatycznie (zalecane)';

  @override
  String get aiModelsInfo =>
      'Do każdego zadania możesz wybrać inny model: krótkie teksty spokojnie obsłuży szybki model, a długie dokumenty wymagają mocniejszego. Jeśli wybrany model wyczerpie limit albo zostanie wycofany, automatycznie próbowany jest kolejny.';

  @override
  String get clearNote => 'Opróżnij';

  @override
  String get clearNoteConfirm =>
      'Zawartość notatki (tekst i pozycje listy) zostanie usunięta. Na pewno?';

  @override
  String get themePaper => 'Papier';

  @override
  String get calculatorTitle => 'Kalkulator';

  @override
  String get calcExpressionHint => 'np. 12,5×3+40';

  @override
  String get calcInvalid => 'Nieprawidłowe wyrażenie';

  @override
  String get liveDictation => 'Dyktuj';

  @override
  String get dictationListening =>
      'Słucham... tekst pojawia się w trakcie mówienia';

  @override
  String get dictationNoKeyInfo =>
      'Dyktowanie na żywo nie jest dostępne na tym urządzeniu; nagranie zostanie zapisane w całości po zatrzymaniu.';

  @override
  String get dictationHoldHint =>
      'Przytrzymaj mikrofon i mów; tekst zostanie zapisany po puszczeniu';

  @override
  String itemsSelected(int count) {
    return 'Zaznaczonych pozycji: $count';
  }

  @override
  String get noteChatTitle => 'Rozmowa z tą notatką';

  @override
  String get noteChatHint => 'Zapytaj o coś z tej notatki';

  @override
  String get noteChatIntro =>
      'Odczytywana jest treść notatki i jej załączniki (PDF/obraz), a odpowiedź na Twoje pytanie powstaje na ich podstawie.';

  @override
  String get dictationProcessing => 'Zapisywanie mowy...';

  @override
  String get aiDailyManualInfo =>
      'W planie darmowym nie powstaje to automatycznie, więc nie zużywa Twojego dziennego limitu. Możesz to wygenerować raz dziennie przyciskiem poniżej.';

  @override
  String get aiGenerate => 'Generuj';

  @override
  String get aiGeneratedTodayInfo =>
      'To zostało wygenerowane dzisiaj. W planie darmowym odświeża się raz dziennie; jutro będzie można wygenerować ponownie.';

  @override
  String get voiceAssistantTitle => 'Asystent notatek głosowych';

  @override
  String get voiceListening => 'Słucham...';

  @override
  String get voiceHoldHint =>
      'Przytrzymaj i mów; notatka powstanie po puszczeniu';

  @override
  String get voiceTapHint => 'Dotknij i mów; dotknij ponownie, aby zakończyć';

  @override
  String get voiceTooShort =>
      'To nagranie było za krótkie, spróbuj jeszcze raz';

  @override
  String get voiceModeSetting => 'Jak to działa';

  @override
  String get voiceModeHold => 'Przytrzymaj, aby mówić';

  @override
  String get voiceModeTap => 'Dotknij, aby zacząć / dotknij, aby zatrzymać';

  @override
  String get voiceModeInfo =>
      'Przytrzymaj, aby mówić: nasłuchuje, dopóki trzymasz przycisk, i tworzy notatkę po puszczeniu. Dotknij, aby zacząć: jedno dotknięcie rozpoczyna nagrywanie, drugie je kończy.';

  @override
  String get voiceHeardLive => 'Wykryto mowę';

  @override
  String get voiceCaptureReady => 'Gotowy do nagrywania';

  @override
  String get voiceCaptureEditHint => 'Dotknij tekstu, aby edytować';

  @override
  String voiceCapturePunctuation(String language) {
    return '$language · automatyczna interpunkcja';
  }

  @override
  String get voiceCaptureAddToNote => 'Dodaj do notatki';

  @override
  String get voiceCaptureCreateNote => 'Utwórz nową notatkę';

  @override
  String get voiceCaptureAiNote => 'Notatka AI';

  @override
  String get voiceCapturePlainNote => 'Zwykła notatka';

  @override
  String get voiceCloseTitle => 'Twoje dyktowanie jest zapisane';

  @override
  String get voiceCloseKeepTalking => 'Mów dalej';

  @override
  String get voiceCaptureRestart => 'Nagrywaj ponownie';

  @override
  String get voiceChipSummarizeAdd => 'Dodaj jako podsumowanie';

  @override
  String get voiceChipSummarizeSave => 'Zapisz jako podsumowanie';

  @override
  String get voiceChipToItems => 'Podziel na elementy';

  @override
  String get voiceChipAsList => 'Utwórz listę';

  @override
  String get voiceChipFix => 'Popraw';

  @override
  String get voiceChipCompose => 'Niech asystent to napisze';

  @override
  String get editorToolList => 'Lista';

  @override
  String get permissionsTitle => 'Uprawnienia';

  @override
  String get permMic => 'Mikrofon';

  @override
  String get permMicInfo => 'Potrzebny do notatek głosowych i dyktowania';

  @override
  String get permNotifications => 'Powiadomienia';

  @override
  String get permNotificationsInfo =>
      'Potrzebne do przypomnień i podsumowania dnia';

  @override
  String get permBattery => 'Optymalizacja baterii';

  @override
  String get permBatteryInfo =>
      'Zwolnij aplikację z ograniczeń baterii, aby przypomnienia docierały na czas';

  @override
  String get showTagChips => 'Pokaż plakietki etykiet';

  @override
  String get showFolderChips => 'Pokaż plakietki folderów';

  @override
  String videoTooBigForAi(int mb) {
    return 'Wideo jest za duże, by wysłać je do AI ($mb MB). Nagraj krótsze.';
  }

  @override
  String get permCamera => 'Aparat';

  @override
  String get permCameraInfo => 'Potrzebny do notatek wideo i robienia zdjęć';

  @override
  String get permOnboardTitle => 'Zanim zaczniesz';

  @override
  String get permOnboardInfo =>
      'Notatki proszą o te uprawnienia dopiero wtedy, gdy korzystasz z odpowiedniej funkcji. Możesz przyznać je teraz poniżej albo zmienić później w Ustawienia > Uprawnienia.';

  @override
  String get permOnboardGrantAll => 'Przyznaj uprawnienia';

  @override
  String get permOnboardSkip => 'Nie teraz';

  @override
  String get newVideoNote => 'Notatka wideo';

  @override
  String get videoLocalOnly =>
      'To wideo jest przechowywane tylko na tym urządzeniu (nie trafia do chmury)';

  @override
  String get videoToNote => 'Zrób notatkę z wideo';

  @override
  String get videoToNoteRunning => 'Przeglądam wideo…';

  @override
  String get permGranted => 'Przyznane';

  @override
  String get permGrant => 'Przyznaj';

  @override
  String get permOpenSettings => 'Otwórz ustawienia';

  @override
  String get newHandwriting => 'Pismo odręczne';

  @override
  String get newVoiceCapture => 'Notatka głosowa';

  @override
  String get suggestTitle => 'Zaproponuj tytuł';

  @override
  String get noteMetaMenu => 'Etykieta · Tytuł · Przypomnienie';

  @override
  String get folder => 'Folder';

  @override
  String get noFolder => 'Bez folderu';

  @override
  String get newFolder => 'Nowy folder';

  @override
  String get editFolder => 'Edytuj folder';

  @override
  String get deleteFolder => 'Usuń folder';

  @override
  String deleteFolderConfirm(String name) {
    return 'Folder «$name» zostanie usunięty. Notatki w środku nie zostaną usunięte — po prostu nie będą miały folderu.';
  }

  @override
  String get folderNameHint => 'Nazwa folderu';

  @override
  String get folderIcon => 'Ikona';

  @override
  String get editFilters => 'Edytuj filtry';

  @override
  String get editFiltersInfo =>
      'Wybierz, które filtry mają być na ekranie głównym. Ukrycie części utrzymuje porządek na stronie.';

  @override
  String get select => 'Zaznacz';

  @override
  String get noteArchived => 'Notatka zarchiwizowana';

  @override
  String deleteChecked(int count) {
    return 'Usuń zaznaczone ($count)';
  }

  @override
  String get removeItem => 'Usuń pozycję';

  @override
  String get copyWholeNote => 'Kopiuj całą notatkę';

  @override
  String get allCopied => 'Cała notatka została skopiowana do schowka';

  @override
  String get speechPlay => 'Przeczytaj na głos';

  @override
  String get speechPause => 'Wstrzymaj';

  @override
  String get speechResume => 'Wznów';

  @override
  String get speechStop => 'Zatrzymaj';

  @override
  String get speechRate => 'Szybkość czytania';

  @override
  String get speechSystemDefault => 'Domyślne systemu';

  @override
  String get speechNoVoices =>
      'Na tym urządzeniu nie zainstalowano żadnych głosów';

  @override
  String speechVoiceLanguage(String language) {
    return 'Głos: $language';
  }

  @override
  String get speechVoiceAutoInfo =>
      'Pozostałe języki są czytane automatycznie głosem męskim';

  @override
  String get listening => 'Słucham...';

  @override
  String get listenPlay => 'Słuchaj';

  @override
  String get listenReadingPdf => 'Czytam dokument...';

  @override
  String get listenConvertWithAi => 'Przekształć z AI';

  @override
  String get listenMakePodcast => 'Pełny podcast';

  @override
  String get listenMakePodcastSummary => 'Podcast ze streszczeniem';

  @override
  String get listenOriginalText => 'Tekst oryginalny';

  @override
  String get listenPodcastReady => 'Narracja podcastu jest gotowa';

  @override
  String get listenPodcastCached =>
      'Wygenerowano wcześniej — bez zużycia tokenów';

  @override
  String get listenRegenerate => 'Wygeneruj ponownie';

  @override
  String get listenNoText =>
      'Z tego dokumentu nie udało się odczytać tekstu. Zeskanowany PDF nie ma warstwy tekstowej, a prezentacja może zawierać wyłącznie obrazy.';

  @override
  String get readDocument => 'Przeczytaj dokument (Word, PDF, slajdy)';

  @override
  String get readDocUnsupported => 'Tego typu pliku nie da się odczytać.';

  @override
  String get exportPdf => 'Eksportuj do PDF';

  @override
  String get pdfTitleField => 'Tytuł';

  @override
  String get pdfContentField => 'Treść';

  @override
  String get pdfMarkupHint =>
      'Znaki na początku wiersza stają się formatowaniem: [x] i [ ] to pola wyboru, 1. to lista numerowana, - to punktor.';

  @override
  String get pdfIncludeDate => 'Dołącz datę';

  @override
  String get exportIncludeImages => 'Dołącz obrazy';

  @override
  String get exportWord => 'Udostępnij jako Word (.docx)';

  @override
  String get pdfPreview => 'Podgląd';

  @override
  String get largeAttachmentTitle => 'Duży plik';

  @override
  String largeAttachmentBody(String size) {
    return 'Ten plik ma $size MB. Plików PDF nie da się skompresować; zostanie przesłany bez zmian i wliczy się do Twojego miejsca. Kontynuować?';
  }

  @override
  String get speechRateForeign => 'Szybkość dla języków obcych';

  @override
  String notesArchivedCount(int count) {
    return 'Zarchiwizowano notatki: $count';
  }

  @override
  String get backgroundColor => 'Kolor tła';

  @override
  String get backgroundColorInfo => 'Kolor tła notatki';

  @override
  String get frameColor => 'Ramka';

  @override
  String get frameColorInfo => 'Rysuje wokół notatki ramkę w wybranym kolorze';

  @override
  String get sortBy => 'Sortuj';

  @override
  String get reorderNotes => 'Zmień kolejność notatek';

  @override
  String get reorderModeActive => 'Przeciągaj karty, aby zmienić kolejność';

  @override
  String get reorderDone => 'Gotowe';

  @override
  String get sortManual => 'Ręcznie (kolejność z przeciągania)';

  @override
  String get sortUpdated => 'Ostatnio zmienione';

  @override
  String get sortCreated => 'Data utworzenia';

  @override
  String get sortTitle => 'Według tytułu (A–Z)';

  @override
  String get foldersSection => 'Foldery';

  @override
  String get tagsSection => 'Etykiety';

  @override
  String get expandFilters => 'Rozwiń filtry';

  @override
  String get collapseFilters => 'Zwiń filtry';

  @override
  String get settingsLanguage => 'Język';

  @override
  String get languageSystem => 'Język systemu';

  @override
  String get settingsSpeech => 'Czytanie na głos';

  @override
  String get aiAdvanced => 'Zaawansowane: model i klucz API';

  @override
  String get aiAdvancedInfo =>
      'Wybór modelu i Twój własny klucz Gemini. Większości osób to niepotrzebne.';

  @override
  String get openBriefing => 'Otwórz podsumowanie';

  @override
  String get syncTitle => 'Synchronizacja';

  @override
  String get syncLimitTitle => 'Limit automatycznego przesyłania';

  @override
  String get syncLimitInfo =>
      'Załączniki większe niż ten limit zostają na urządzeniu i nie są przesyłane. Tekst notatek synchronizuje się zawsze.';

  @override
  String get syncLimitUnlimited => 'Bez limitu';

  @override
  String get backupTitle => 'Kopia zapasowa';

  @override
  String get importBackup => 'Przywróć z kopii zapasowej (JSON)';

  @override
  String importBackupDone(int count) {
    return 'Przywrócono notatki: $count';
  }

  @override
  String get importBackupInvalid => 'Nieprawidłowy plik kopii zapasowej';

  @override
  String get aiHubTitle => 'AI';

  @override
  String get aiSummarizeInfo => 'Tworzy krótkie podsumowanie';

  @override
  String get aiAnalyzeInfo =>
      'Wypisuje najważniejsze punkty i zadania do zrobienia';

  @override
  String get aiImproveInfo => 'Zmienia ton: formalny, krótszy lub lista';

  @override
  String get aiTranslateInfo => 'Tłumaczy notatkę na wybrany język';

  @override
  String get aiFixNoteInfo => 'Poprawia pisownię i interpunkcję';

  @override
  String get moveToFolder => 'Przenieś do folderu';

  @override
  String get voiceAssistantBadge => 'Asystent';

  @override
  String get assistantGenericError =>
      'Coś poszło nie tak — spróbujesz jeszcze raz?';

  @override
  String get quickAddTooltip => 'Nowa notatka — wybierz rodzaj';

  @override
  String get autoTitleSetting => 'Proponuj tytuł przy zamykaniu';

  @override
  String get autoTitleSettingInfo =>
      'Gdy wychodzisz z edytora, notatka pozostawiona bez tytułu dostaje krótki tytuł ułożony na podstawie treści.';

  @override
  String get hubChatInfo => 'Odpowiedzi na podstawie Twoich notatek';

  @override
  String get hubBriefingInfo =>
      'Twój dzień w skrócie: przypomnienia i ostatnie notatki';

  @override
  String get hubReadInfo => 'Posłuchaj dokumentu PDF lub Word';

  @override
  String get annotate => 'Adnotacje';

  @override
  String get annotateDone => 'Zakończ adnotacje';

  @override
  String get crop => 'Przytnij';

  @override
  String get cropApply => 'Zastosuj przycięcie';

  @override
  String get cropReset => 'Zresetuj zaznaczenie';

  @override
  String get cropHint =>
      'Przeciągaj narożniki, aby wybrać obszar. Przycięcia nie można cofnąć.';

  @override
  String get cropFailed => 'Nie udało się przyciąć obrazu.';

  @override
  String get penBallpoint => 'Długopis';

  @override
  String get penMarker => 'Marker';

  @override
  String get penHighlighter => 'Zakreślacz';

  @override
  String get eraser => 'Gumka';

  @override
  String get clearInk => 'Wyczyść adnotacje';

  @override
  String get inkTwoFingerHint =>
      'Jeden palec rysuje · dwa palce przesuwają i powiększają';

  @override
  String get slideOpenFailed => 'Nie udało się otworzyć prezentacji';

  @override
  String get newPhotoNote => 'Notatka ze zdjęciem';

  @override
  String get newScanNote => 'Zeskanuj dokument';

  @override
  String get scanDocument => 'Skanuj dokument';

  @override
  String get scanDocumentSubtitle =>
      'Znajduje krawędzie, prostuje stronę i dodaje ją';

  @override
  String get scanUnsupported =>
      'Skanowanie dokumentów nie jest obsługiwane na tym urządzeniu';

  @override
  String scanFailed(String error) {
    return 'Nie udało się zeskanować dokumentu: $error';
  }

  @override
  String scanPagesAdded(int count) {
    return 'Dodano stron do notatki: $count';
  }

  @override
  String get scanTextTitle => 'Rozpoznać także tekst?';

  @override
  String get scanTextBody =>
      'Tekst ze stron zostaje rozpoznany i zapisany w notatce. Obraz pozostaje bez zmian. Zajmuje kilka sekund na stronę.';

  @override
  String get scanImageOnly => 'Tylko obraz';

  @override
  String get scanRecognizeText => 'Rozpoznaj tekst';

  @override
  String get scanRecognizing => 'Rozpoznaję tekst…';

  @override
  String get takePhoto => 'Zrób zdjęcie';

  @override
  String get qrScanTitle => 'Zeskanuj kod QR';

  @override
  String get qrScanSubtitle => 'Odczytaj aparatem albo ze zdjęcia';

  @override
  String get qrScanHint => 'Ustaw kod w obrębie ramki';

  @override
  String get qrFromPhoto => 'Odczytaj ze zdjęcia';

  @override
  String get qrNotFound => 'Na tym obrazie nie znaleziono kodu';

  @override
  String get qrLinkFound => 'Ten kod to odnośnik';

  @override
  String get qrOpenLink => 'Przejdź do odnośnika';

  @override
  String get qrSaveToNote => 'Zapisz w notatce';

  @override
  String get openLink => 'Otwórz odnośnik';

  @override
  String get linkOpenFailed => 'Nie udało się otworzyć odnośnika';

  @override
  String qrScanFailed(String error) {
    return 'Nie udało się odczytać kodu: $error';
  }

  @override
  String get qrTorch => 'Latarka';

  @override
  String attachmentsCount(int count) {
    return 'Załączniki ($count)';
  }

  @override
  String get hideAttachments => 'Ukryj';

  @override
  String get showAttachments => 'Pokaż';

  @override
  String get videoBack10 => '10 s wstecz';

  @override
  String get videoForward10 => '10 s do przodu';

  @override
  String get selectAllItems => 'Zaznacz wszystko';

  @override
  String get showAllChips => 'Pokaż wszystko';

  @override
  String get hideAllChips => 'Ukryj wszystko';

  @override
  String get chipPickInfo =>
      'Które plakietki folderów i etykiet mają być na ekranie głównym?';

  @override
  String get hiddenFolder => 'Ukryty folder';

  @override
  String get hiddenFolderInfo =>
      'Ukryty folder i notatki w nim nie pojawiają się na ekranie głównym. Aby je pokazać, wybierz «Ukryte foldery» z menu ⋮ i potwierdź tożsamość.';

  @override
  String get hiddenFoldersMenu => 'Ukryte foldery';

  @override
  String get hiddenFolderAuthReason =>
      'Potwierdź tożsamość, aby pokazać ukryte foldery';

  @override
  String get hiddenFoldersShown => 'Ukryte foldery są widoczne';

  @override
  String get hiddenFoldersHiddenAgain =>
      'Ukryte foldery zostały znowu schowane';

  @override
  String get makeFolderHidden => 'Ukryj';

  @override
  String get makeFolderVisible => 'Odkryj';

  @override
  String gridColumnsCount(int count) {
    return 'Kolumny: $count';
  }

  @override
  String get addImageOnPageSubtitle =>
      'Siedzi na stronie, tekst opływa go dookoła';

  @override
  String get addImageAsFile => 'Dodaj obraz jako plik';

  @override
  String get addImageAsFileSubtitle =>
      'Zostaje poza stroną, na pasku załączników';

  @override
  String get moveImageToAttachments => 'Przenieś do załączników';

  @override
  String get moveImageToPage => 'Umieść na stronie';

  @override
  String get attachmentCopied => 'Załącznik skopiowany';

  @override
  String get pasteAttachment => 'Wklej skopiowany załącznik';

  @override
  String get fullscreen => 'Pełny ekran';

  @override
  String get more => 'Więcej';

  @override
  String get undone => 'Cofnięto';

  @override
  String get filterOthers => 'Pozostałe';

  @override
  String get chatSuggestion1 => 'Czego brakuje na mojej liście zakupów?';

  @override
  String get chatSuggestion2 => 'Podsumuj notatki z tego tygodnia';

  @override
  String get chatSuggestion3 => 'Czy mam przypomnienie na jutro?';

  @override
  String get aiPointsToday => 'Dzisiejsze punkty';

  @override
  String aiPointsOf(int used, int total) {
    return '$used / $total';
  }

  @override
  String get aiPointsRenew => 'odnowienie o północy';

  @override
  String get aiChatWithNotes => 'Asystent notatek';

  @override
  String get aiChatInputHint => 'Zapytaj o coś w swoich notatkach…';

  @override
  String get aiChatLooking => 'przeszukuję notatki…';

  @override
  String get aiChatFullScreen => 'Pełny ekran';

  @override
  String get aiOnYourNotes => 'NA TWOICH NOTATKACH';

  @override
  String get aiTaskDuplicates => 'Usuń duplikaty';

  @override
  String aiTaskDuplicatesInfo(int count) {
    return 'Zduplikowane notatki: $count';
  }

  @override
  String get duplicatesTitle => 'Zduplikowane notatki';

  @override
  String get duplicatesHint =>
      'Najstarsza notatka w każdej grupie zostaje zachowana, reszta trafia do kosza.';

  @override
  String get duplicatesKeepBadge => 'zostaje';

  @override
  String get duplicatesDeleteAll => 'Przenieś duplikaty do kosza';

  @override
  String duplicatesDone(int count) {
    return 'Przeniesiono duplikaty do kosza: $count';
  }

  @override
  String get aiRecentActions => 'OSTATNIE DZIAŁANIA';

  @override
  String get aiHistoryClear => 'Wyczyść';

  @override
  String get aiHistoryQuestion => 'Pytanie';

  @override
  String get aiHistoryNoteAction => 'Działanie na notatce';

  @override
  String get aiHistoryVoiceNote => 'Notatka głosowa';

  @override
  String get aiRecentOps => 'OSTATNIE';

  @override
  String get aiTaskWeekSummary => 'Podsumuj tydzień';

  @override
  String get aiTaskWeekSummaryInfo => 'Jedno podsumowanie z ostatnich 7 dni';

  @override
  String get aiTaskTagUntagged => 'Dodaj etykiety';

  @override
  String aiTaskTagUntaggedInfo(int count) {
    return '$count notatek czeka na etykiety';
  }

  @override
  String get aiTaskSuggestTitles => 'Zaproponuj tytuły';

  @override
  String aiTaskSuggestTitlesInfo(int count) {
    return '$count notatek nie ma tytułu';
  }

  @override
  String get sectionPinnedShort => 'PRZYPIĘTE';

  @override
  String get sectionToday => 'DZISIAJ';

  @override
  String get sectionThisWeek => 'W TYM TYGODNIU';

  @override
  String get sectionEarlier => 'WCZEŚNIEJ';

  @override
  String sectionNoteCount(int count) {
    return '$count notatek';
  }

  @override
  String get emptySearchSemanticHint => 'Wypróbuj kartę Znaczenie';

  @override
  String get quickCaptureHint => 'Nowa notatka…';

  @override
  String get quickCaptureSave => 'Zapisz';

  @override
  String get quickAddWrite => 'NAPISZ';

  @override
  String get quickAddCapture => 'PRZECHWYĆ — TWORZY NOTATKĘ Z TREŚCI';

  @override
  String get viewToggle => 'Widok';

  @override
  String get searchModeText => 'Tekst';

  @override
  String get searchModeMeaning => 'Znaczenie';

  @override
  String get filterReminded => 'Z przypomnieniem';

  @override
  String get filterLocked => 'Zablokowane';

  @override
  String get sortColor => 'Kolor';

  @override
  String get filterSheetTitle => 'Filtruj';

  @override
  String get filterReset => 'Resetuj';

  @override
  String get filterSectionStatus => 'STATUS';

  @override
  String get filterSectionFolder => 'FOLDER';

  @override
  String get filterSectionTag => 'TAG';

  @override
  String get filterSectionSort => 'SORTIE';

  @override
  String get filterFavoriteHint =>
      'Dotknij gwiazdki, aby opcja została na ekranie głównym';

  @override
  String get filterSheetSortHint =>
      'Grupowania dat (DZIŚ, W TYM TYGODNIU…) są widoczne tylko przy sortowaniu według ostatniej edycji.';

  @override
  String get formatTitle => 'Formatowanie';

  @override
  String get formatBold => 'Pogrubienie';

  @override
  String get formatItalic => 'Kursywa';

  @override
  String get formatUnderline => 'Podkreślenie';

  @override
  String get formatTextColor => 'Kolor tekstu';

  @override
  String get formatHighlight => 'Wyróżnienie';

  @override
  String get formatInfo =>
      'Formatowanie wędruje wewnątrz tekstu jako znaczniki (na przykład **pogrubienie**); w eksportach i przy czytaniu na głos znaczniki pozostają ukryte.';

  @override
  String get formatMenu => 'Formatowanie…';

  @override
  String get noteFont => 'Czcionka';

  @override
  String get noteFontDefault => 'Domyślna';

  @override
  String get noteFontSerif => 'Książkowa (szeryfowa)';

  @override
  String get noteFontMono => 'Maszyna do pisania';

  @override
  String get noteTextSize => 'Rozmiar tekstu';

  @override
  String get formatClear => 'Wyczyść formatowanie';

  @override
  String get noteTextOpacity => 'Krycie';

  @override
  String get assistantVoiceSetting => 'Asystent czyta odpowiedzi';

  @override
  String get assistantVoiceSettingInfo =>
      'Asystent głosowy czyta swoją odpowiedź na głos (tylko na telefonie).';

  @override
  String get assistantMute => 'Wycisz';

  @override
  String get assistantUnmute => 'Włącz dźwięk';

  @override
  String get assistantMakeNote => 'Mimo to zrób notatkę';

  @override
  String get assistantNoteCreated => 'Notatka utworzona';

  @override
  String get noteNotFound => 'Nie znaleziono notatki. Mogła zostać usunięta.';

  @override
  String get back => 'Wstecz';

  @override
  String get addTextBlock => 'Dodaj tekst';

  @override
  String get attachNoteContent => 'Not içeriği';

  @override
  String get noteBackgroundImage => 'Obraz tła';

  @override
  String get chooseBackgroundImage => 'Wybierz obraz';

  @override
  String get changeBackgroundImage => 'Zmień obraz';

  @override
  String get removeBackgroundImage => 'Usuń tło';

  @override
  String get dashboardBackground => 'Tło ekranu głównego';

  @override
  String get dashboardBackgroundInfo =>
      'Obraz widoczny za siatką notatek (tylko na tym urządzeniu).';

  @override
  String get aiProvider => 'Dostawca AI';

  @override
  String get aiProviderInfo =>
      'Wybierz dostawcę, do którego należy Twój klucz. Klucz każdego dostawcy jest przechowywany osobno, więc powrót do poprzedniego nie wymaga ponownego wpisywania.';

  @override
  String get apiKeyFieldLabel => 'Klucz API';

  @override
  String get getApiKey => 'Skąd wziąć klucz?';

  @override
  String get recommendedModel => 'Zalecany';

  @override
  String get freeTierBadge => 'Ma darmowy pakiet';

  @override
  String get continueWithoutAccount => 'Kontynuuj bez konta';

  @override
  String get localAccountInfo =>
      'Twoje notatki pozostają wyłącznie na tym urządzeniu: nie otworzysz ich gdzie indziej, znikną po odinstalowaniu aplikacji, a wbudowane AI jest wyłączone. W każdej chwili możesz połączyć konto Google — notatki przejdą razem z Tobą.';

  @override
  String get localAccountBadge => 'Konto lokalne';

  @override
  String get linkGoogleAccount => 'Połącz konto Google';

  @override
  String get accountLinked =>
      'Konto Google jest połączone. Twoje notatki mają teraz kopię zapasową.';

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
      'Logowanie bez Google jest wyłączone: logowanie anonimowe nie jest włączone w konsoli Firebase. Zaloguj się przez Google lub spróbuj ponownie, gdy administrator je włączy.';

  @override
  String get googleSignInUnavailable =>
      'Logowanie Google jest wyłączone: dostawca Google nie jest włączony w konsoli Firebase.';

  @override
  String get signInNetworkError =>
      'Brak połączenia z internetem. Sprawdź połączenie i spróbuj ponownie.';

  @override
  String get signInCanceled => 'Logowanie anulowane.';

  @override
  String get cardRichPreview => 'Sformatowany tekst na kartach';

  @override
  String get cardRichPreviewInfo =>
      'Kolory, wyróżnienia, pogrubienia i podkreślenia z notatek widać też na kartach ekranu głównego. Po wyłączeniu karty pokazują zwykły tekst.';

  @override
  String get fontSizeSmall => 'Mała';

  @override
  String get fontSizeMedium => 'Średnia';

  @override
  String get fontSizeLarge => 'Duża';

  @override
  String get fontSizeXLarge => 'Bardzo duża';

  @override
  String get appFontSetting => 'Czcionka';

  @override
  String get appFontInfo =>
      'Czcionka używana w całej aplikacji. Własna czcionka notatki ma pierwszeństwo. Wszystkie czcionki są w aplikacji — internet nie jest potrzebny.';

  @override
  String get fontGroupSans => 'Bezszeryfowe';

  @override
  String get fontGroupSerif => 'Szeryfowe';

  @override
  String get fontGroupMono => 'Maszynowe';

  @override
  String get fontGroupHand => 'Odręczne';

  @override
  String get appFontDefaultSuffix => 'domyślna';
}
