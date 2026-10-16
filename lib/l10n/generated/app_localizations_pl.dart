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
  String get attachmentCopying => 'Kopiowanie...';

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
  String get aiModelDocument => 'Czat o dokumencie i streszczenie PDF';

  @override
  String get aiModelTranslate => 'Tłumaczenie';

  @override
  String get aiModelVoice => 'Asystent notatek głosowych';

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
  String get voiceCaptureAi => 'Sesli yakala (yapay zekâ)';

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
  String get newPdfNote => 'PDF\'ten not';

  @override
  String get imageNotePreparing => 'Układanie obrazów w dokument…';

  @override
  String get newImageNote => 'Dodaj obraz i rób notatki';

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
  String get pdfAddBlankPage => 'Dodaj pustą stronę';

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
  String get inkArrow => 'Strzałka';

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
  String get sortActive => 'Najczęściej używane';

  @override
  String get voicePreview => 'Wypróbuj głos';

  @override
  String get voicePreviewCached =>
      'Próbka powstaje raz, potem odtwarzana jest z pamięci';

  @override
  String get reorderHint =>
      'Przytrzymaj kartę i przeciągnij ją w wybrane miejsce';

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
  String get formatHeading => 'Başlık';

  @override
  String get formatHeading1 => 'Büyük başlık';

  @override
  String get formatHeading2 => 'Alt başlık';

  @override
  String get formatNormalText => 'Normal metin';

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
      'Głos AI wymaga własnego klucza Gemini. Do tego czasu czyta głos urządzenia.';

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
  String get shareAsText => 'Jako zwykły tekst';

  @override
  String get shareAsTextInfo =>
      'Wysyła tekst notatki i notatki stron do dowolnej aplikacji.';

  @override
  String get shareAsTextEmpty => 'Ta notatka nie ma tekstu do udostępnienia.';

  @override
  String get sharePdfWithBubbles => 'Jako PDF z dymkami';

  @override
  String get sharePdfWithBubblesInfo =>
      'Dymki, zakreślenia i rysunki są wypalane w pliku PDF; każdy może go otworzyć, a w Not otwiera się z możliwością edycji.';

  @override
  String get sharePdfWithBubblesNone =>
      'Ta notatka nie zawiera pliku PDF z dymkami ani rysunkami.';

  @override
  String get sharePdfWithBubblesPreparing =>
      'Przygotowywanie pliku PDF z dymkami…';

  @override
  String get sharePdfWithBubblesSuffix => ' (z dymkami)';

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
  String get formatRemove => 'Usuń';

  @override
  String get exportTitle => 'Eksportuj';

  @override
  String get exportNotesOption => 'Tekst notatki (PDF / Word)';

  @override
  String get exportNotesOptionInfo =>
      'Tekst i obrazy notatki; dymki nie są uwzględnione.';

  @override
  String get captureNoteTitle => 'Tytuł notatki (opcjonalnie)';

  @override
  String get captureNoteTitleHint => 'Nowy dokument otrzyma tę samą nazwę';

  @override
  String get imageOcrTitle => 'Rozpoznaj tekst na obrazie';

  @override
  String get imageOcrNone => 'Nie znaleziono tekstu na tym obrazie.';

  @override
  String imageOcrHint(int count) {
    return 'Rozpoznano $count wierszy · dotknij, aby zaznaczyć';
  }

  @override
  String imageOcrSelected(int count) {
    return 'Zaznaczono $count wierszy';
  }

  @override
  String get imageOcrShort => 'Rozpoznaj tekst';

  @override
  String get imageOcrWorking => 'Rozpoznawanie tekstu…';

  @override
  String get imageOcrSelectHint =>
      'Dotknij: słowo · Przytrzymaj i przeciągnij: litera po literze';

  @override
  String get imageOcrInsert => 'Dodaj do notatki';

  @override
  String get imageOcrZoomIn => 'Powiększ';

  @override
  String get imageOcrZoomOut => 'Pomniejsz';

  @override
  String get selectImages => 'Wybierz obrazy';

  @override
  String get exportImages => 'Obrazy';

  @override
  String get exportImagesInfo =>
      'Tekst opływa wąskie obrazy wyrównane do lewej lub prawej; wyśrodkowane zajmują całą szerokość.';

  @override
  String get exportAlignLeft => 'Lewo';

  @override
  String get exportAlignCenter => 'Środek';

  @override
  String get exportAlignRight => 'Prawo';

  @override
  String get exportImageWidth => 'Szerokość';

  @override
  String get exportImageLine => 'Pozycja';

  @override
  String get aiModelSearch => 'Szukaj modeli';

  @override
  String get aiModelOthers => 'POZOSTAŁE MODELE';

  @override
  String get aiModelNoMatch => 'Brak pasującego modelu.';

  @override
  String get aiModelAutoInfo =>
      'Aplikacja po kolei próbuje najodpowiedniejszych modeli.';

  @override
  String imageOcrCharsSelected(int count) {
    return 'Zaznaczono $count znaków';
  }

  @override
  String imagesSelectedCount(int count) {
    return 'Zaznaczono $count obrazów';
  }

  @override
  String attachmentsCopiedCount(int count) {
    return 'Załączniki: $count';
  }

  @override
  String exportImageLineOf(int count) {
    return '/ $count wierszy';
  }

  @override
  String get aiModelShowAll => 'Pokaż wszystkie';

  @override
  String get aiModelShowAllInfo =>
      'Pokazuje też modele, których aplikacja nie używa.';

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
  String get attachmentTagEmbed => 'Ek göm';

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
  String get collaborators => 'Współpracownicy';

  @override
  String get collaboratorsInfo =>
      'Dodane osoby widzą tę notatkę na swoim ekranie głównym i edytują ją razem z tobą na żywo.';

  @override
  String get collaboratorsOwner => 'Właściciel';

  @override
  String get collaboratorsFriendsTitle => 'TWOI ZNAJOMI';

  @override
  String get collaboratorsLeave => 'Opuść udostępnioną notatkę';

  @override
  String get collaboratorsLeaveConfirm =>
      'Ta notatka nie będzie już widoczna na twoim ekranie głównym. Opuścić?';

  @override
  String get collaboratorsSaved => 'Udostępnianie zaktualizowane';

  @override
  String collaboratorsCount(int count) {
    return 'Udostępniono $count osobom';
  }

  @override
  String get collaboratorsOnlyOwner =>
      'Tylko właściciel notatki może zmieniać współpracowników.';

  @override
  String get sharedWithMe => 'Udostępnione mi';

  @override
  String get sharedWithMeEmpty =>
      'Nikt jeszcze nie udostępnił ci notatki. Pojawią się tutaj, gdy ktoś doda cię do notatki.';

  @override
  String sharedByName(Object name) {
    return 'Udostępnia: $name';
  }

  @override
  String get navNotes => 'Notatki';

  @override
  String get railExpand => 'Rozwiń menu';

  @override
  String get railCollapse => 'Zwiń menu';

  @override
  String get newNoteShort => 'Nowa notatka';

  @override
  String get newChecklistShort => 'Nowa lista';

  @override
  String get listPaneHide => 'Ukryj listę notatek';

  @override
  String get listPaneShow => 'Pokaż listę notatek';

  @override
  String get keyboardShortcuts => 'Skróty klawiszowe';

  @override
  String get shortcutSearch => 'Szukaj w notatkach';

  @override
  String get shortcutToggleList => 'Ukryj / pokaż listę notatek';

  @override
  String get shortcutSections => 'Przełączaj sekcje';

  @override
  String get shortcutHelp => 'Pokaż skróty';

  @override
  String get noNoteSelectedHint => 'lub zacznij nową notatkę';

  @override
  String get loginFeatureSyncTitle => 'Te same notatki na każdym urządzeniu';

  @override
  String get loginFeatureSyncBody =>
      'Natychmiastowa synchronizacja między telefonem, tabletem, komputerem i siecią.';

  @override
  String get loginFeatureAiTitle => 'AI u twojego boku';

  @override
  String get loginFeatureAiBody =>
      'Streszczaj, pytaj, dyktuj; rozmawiaj z dokumentami.';

  @override
  String get loginFeatureShareTitle => 'Piszcie razem';

  @override
  String get loginFeatureShareBody =>
      'Udostępniaj notatki i foldery znajomym na żywo.';

  @override
  String get loginFeatureInkTitle => 'Pióro i PDF';

  @override
  String get loginFeatureInkBody =>
      'Notuj odręcznie, pisz na PDF-ach i slajdach.';

  @override
  String get foldersTitle => 'Foldery';

  @override
  String get foldersEmpty =>
      'Brak folderów. Utwórz folder, aby uporządkować notatki.';

  @override
  String get folderColor => 'Kolor';

  @override
  String get folderColorAuto => 'Automatyczny';

  @override
  String get foldersMine => 'Moje foldery';

  @override
  String get foldersSharedSection => 'Foldery udostępnione mi';

  @override
  String trashDaysShort(int count) {
    return '$count dni';
  }

  @override
  String get trashTodayShort => 'Dziś';

  @override
  String get trashSoonSection => 'Wkrótce trwale usunięte';

  @override
  String get trashRestSection => 'Inne usunięte notatki';

  @override
  String get aiHubTagline => 'Pytaj, streszczaj i porządkuj notatki.';

  @override
  String get aiToolsSection => 'Narzędzia';

  @override
  String get folderOrderTitle => 'Kolejność folderów';

  @override
  String get folderReorder => 'Zmień kolejność folderów';

  @override
  String get folderOrderManual => 'Własna';

  @override
  String get folderOrderName => 'Według nazwy';

  @override
  String get folderOrderNewest => 'Najnowsze najpierw';

  @override
  String get folderOrderNoteCount => 'Według liczby notatek';

  @override
  String get folderOrderHint =>
      'Przeciągnij uchwyty, aby zmienić kolejność. Ta sama kolejność obowiązuje na pasku folderów i przy przesuwaniu.';

  @override
  String get swipeModeTitle => 'Przesuwanie na ekranie głównym';

  @override
  String get swipeModeFolders => 'Przełączaj foldery';

  @override
  String get swipeModeFilters => 'Przełączaj filtry i tagi';

  @override
  String get swipeModeBoth => 'Foldery, filtry i tagi';

  @override
  String get swipeModeOff => 'Wyłączone';

  @override
  String get shareIncludeTitle => 'Tytuł';

  @override
  String get shareIncludeChecked => 'Ukończone';

  @override
  String get shareIncludeTags => 'Tagi';

  @override
  String get shareTextAction => 'Udostępnij tekst';

  @override
  String get shareAsFileSection => 'Jako plik';

  @override
  String get shareInAppSection => 'W aplikacji';

  @override
  String get shareSendFriendInfo =>
      'Umieszcza kopię notatki w skrzynce znajomego.';

  @override
  String get shareCollaborateInfo =>
      'Edytuj tę samą notatkę z przyjaciółmi; zmiany widać od razu.';

  @override
  String get findPrevious => 'Poprzednie trafienie';

  @override
  String get findNext => 'Następne trafienie';

  @override
  String get findShowAll => 'Wszystkie trafienia';

  @override
  String findMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count trafienia',
      many: '$count trafień',
      few: '$count trafienia',
      one: '1 trafienie',
      zero: 'Brak trafień',
    );
    return '$_temp0';
  }

  @override
  String get findDeepSearch => 'Szukaj w załącznikach i z AI';

  @override
  String get notesSettingsTitle => 'Notatki i foldery';

  @override
  String get noteViewSetting => 'Układ ekranu głównego';

  @override
  String get noteViewGrid => 'Siatka';

  @override
  String get noteViewList => 'Lista';

  @override
  String get gridColumnsSetting => 'Kolumny';

  @override
  String get gridColumnsInfo =>
      'Możesz też zmienić to gestem szczypania na ekranie głównym.';

  @override
  String get gridColumnsAuto => 'Automatycznie';

  @override
  String get folderShelfSetting => 'Foldery na ekranie głównym';

  @override
  String get folderShelfStrip => 'Jeden wiersz';

  @override
  String get folderShelfTiles => 'Kafelki';

  @override
  String get deviceStorageTitle => 'Na tym urządzeniu';

  @override
  String get deviceStorageAttachments => 'Załączniki';

  @override
  String get deviceStorageDatabase => 'Lokalna kopia notatek';

  @override
  String get deviceStorageCache => 'Pamięć podręczna i pliki tymczasowe';

  @override
  String get deviceStorageAi => 'Pamięć podręczna AI';

  @override
  String get deviceStorageTotal => 'Razem (bez samej aplikacji)';

  @override
  String get deviceStorageInfo =>
      'Wyczyszczenie pamięci nie usuwa notatek ani załączników; obrazy pobiorą się ponownie w razie potrzeby. Stare pliki tymczasowe są usuwane przy każdym uruchomieniu.';

  @override
  String get deviceStorageClear => 'Wyczyść pamięć podręczną';

  @override
  String deviceStorageCleared(String size) {
    return 'Zwolniono $size';
  }

  @override
  String get deviceStorageUnavailable =>
      'Nie można zmierzyć na tym urządzeniu.';

  @override
  String get localOnlyTurnOn => 'Wyłącz synchronizację';

  @override
  String get localOnlyTurnOff => 'Synchronizuj notatkę';

  @override
  String get localOnlyBadge => 'Tylko na tym urządzeniu';

  @override
  String get localOnlyConfirmTitle =>
      'Zachować tę notatkę tylko na tym urządzeniu?';

  @override
  String get localOnlyConfirmBody =>
      'Notatka i jej załączniki zostaną usunięte z chmury i nie pojawią się na innych urządzeniach. Jeśli odinstalujesz aplikację lub zmienisz telefon, ta notatka też zniknie. Synchronizację możesz włączyć ponownie w dowolnej chwili.';

  @override
  String get localOnlyConfirm => 'Wyłącz';

  @override
  String get localOnlyOnDone => 'Notatka jest teraz tylko na tym urządzeniu';

  @override
  String get localOnlyOffDone => 'Notatka znów się synchronizuje';

  @override
  String get localOnlySharedBlocked =>
      'Nie można wyłączyć synchronizacji udostępnionej notatki';

  @override
  String get localOnlyDownloadFailed =>
      'Nie udało się pobrać niektórych załączników. Sprawdź połączenie i spróbuj ponownie; notatka nie została zmieniona.';

  @override
  String get templatesTitle => 'Szablony';

  @override
  String get templatesSubtitle =>
      'Zacznij od gotowego układu; wszystko zmienisz później.';

  @override
  String get fromTemplate => 'Z szablonu';

  @override
  String get tplShoppingName => 'Lista zakupów';

  @override
  String get tplShoppingItems => 'Chleb, Mleko, Jajka, Owoce, Warzywa';

  @override
  String get tplShoppingDesc => 'Odhacz kupione; spada na dół';

  @override
  String get tplTodoDesc => 'Pusta lista z dzisiejszą datą';

  @override
  String get tplTravelName => 'Lista do spakowania';

  @override
  String get tplTravelItems =>
      'Dowód / paszport, Ładowarka, Leki, Szczoteczka do zębów, Ubrania, Słuchawki';

  @override
  String get tplTravelDesc => 'Gotowa lista kontrolna';

  @override
  String get tplMeetingDesc => 'Uczestnicy, agenda, decyzje';

  @override
  String get tplJournalDesc => 'Jak minął dzień, wdzięczność, jutro';

  @override
  String get tplRecipeName => 'Przepis';

  @override
  String get tplRecipeMeta => 'Porcje: · Czas:';

  @override
  String get tplRecipeIngredients => 'Składniki';

  @override
  String get tplRecipeSteps => 'Przygotowanie';

  @override
  String get tplRecipeNotes => 'Notatki';

  @override
  String get tplRecipeDesc => 'Składniki i kroki';

  @override
  String get tplWeeklyName => 'Plan tygodnia';

  @override
  String get tplWeeklyDesc => 'Dni tego tygodnia jako nagłówki';

  @override
  String get tplExpenseDesc => 'Data, opis, kwota';

  @override
  String get tplReadingDesc => 'Źródło, streszczenie, cytaty';

  @override
  String get settingsThemeHeader => 'Motyw';

  @override
  String get settingsCardsHeader => 'Karty i listy';

  @override
  String get shareTargetTitle => 'Dodaj do Notatek';

  @override
  String get shareTargetNew => 'Nowa notatka';

  @override
  String get shareTargetExisting => 'Istniejąca notatka';

  @override
  String get shareTargetCreate => 'Utwórz notatkę';

  @override
  String get shareTargetSearch => 'Szukaj w notatkach';

  @override
  String get shareTargetNoNotes => 'Brak dostępnych notatek';

  @override
  String get shareTargetNoMatch => 'Brak pasujących notatek';

  @override
  String shareTargetMore(int count) {
    return '+$count pliki';
  }

  @override
  String get sharePreviewExpand => 'Powiększ podgląd';

  @override
  String get sharePreviewCollapse => 'Zmniejsz podgląd';

  @override
  String get templatesSearch => 'Szukaj szablonów';

  @override
  String get templatesAll => 'Wszystkie';

  @override
  String get templatesLists => 'Listy';

  @override
  String get templatesPlanning => 'Planowanie';

  @override
  String get templatesWriting => 'Pisanie';

  @override
  String get templatesMine => 'Moje szablony';

  @override
  String get templatesRecent => 'Ostatnio używane';

  @override
  String get templatesNoMatch => 'Brak pasujących szablonów';

  @override
  String get templatesMineEmpty =>
      'Nie masz jeszcze własnych szablonów. Wybierz „Zapisz jako szablon” w menu notatki, a pojawi się tutaj.';

  @override
  String get templatesMineInfo => 'Twój szablon';

  @override
  String get templateRename => 'Zmień nazwę';

  @override
  String get templateDelete => 'Usuń szablon';

  @override
  String get templateNameTitle => 'Nazwa szablonu';

  @override
  String get templateNameHint => 'np. Cotygodniowe zakupy';

  @override
  String get templateSave => 'Zapisz';

  @override
  String templateSaved(String name) {
    return '„$name” dodano do szablonów';
  }

  @override
  String get saveAsTemplate => 'Zapisz jako szablon';

  @override
  String get templateCreate => 'Utwórz';

  @override
  String templateCreateWithCount(int count) {
    return 'Utwórz · $count pozycji';
  }

  @override
  String get templateListChecks => 'Pola wyboru';

  @override
  String get templateListNumbers => 'Numerowana';

  @override
  String get templateItems => 'Pozycje';

  @override
  String get templateAddItem => 'Dodaj pozycję';

  @override
  String get templateSuggestionsInfo =>
      'Dotknij sugestii, aby ją dodać; dotknij ponownie, aby usunąć.';

  @override
  String get tplShopProduce => 'Owoce i warzywa';

  @override
  String get tplShopProduceItems =>
      'Pomidory, Ogórki, Cebula, Ziemniaki, Cytryny, Banany, Jabłka, Pietruszka';

  @override
  String get tplShopBreakfast => 'Śniadanie';

  @override
  String get tplShopBreakfastItems => 'Ser, Oliwki, Masło, Miód, Dżem, Jogurt';

  @override
  String get tplShopPantry => 'Spiżarnia';

  @override
  String get tplShopPantryItems =>
      'Ryż, Makaron, Mąka, Cukier, Oliwa, Soczewica, Herbata, Kawa';

  @override
  String get tplShopCleaning => 'Środki czystości';

  @override
  String get tplShopCleaningItems =>
      'Płyn do naczyń, Proszek do prania, Papier toaletowy, Ręczniki papierowe, Worki na śmieci';

  @override
  String get tplShopPersonal => 'Higiena';

  @override
  String get tplShopPersonalItems =>
      'Szampon, Pasta do zębów, Mydło, Dezodorant';

  @override
  String get tplTravelDocs => 'Dokumenty';

  @override
  String get tplTravelDocsItems =>
      'Bilety, Rezerwacja hotelu, Prawo jazdy, Ubezpieczenie podróżne, Gotówka / karty';

  @override
  String get tplTravelClothes => 'Ubrania';

  @override
  String get tplTravelClothesItems =>
      'Koszulki, Spodnie, Bielizna, Skarpetki, Piżama, Kurtka, Buty';

  @override
  String get tplTravelCare => 'Kosmetyki';

  @override
  String get tplTravelCareItems =>
      'Pasta do zębów, Szampon, Krem z filtrem, Maszynka do golenia, Dezodorant';

  @override
  String get tplTravelTech => 'Elektronika';

  @override
  String get tplTravelTechItems =>
      'Powerbank, Przejściówka do gniazdka, Słuchawki, Kable';

  @override
  String get tplHabitsName => 'Śledzenie nawyków';

  @override
  String get tplHabitsDesc => 'Odhaczaj codziennie, nie przerywaj łańcucha';

  @override
  String get tplHabitsItems =>
      '8 szklanek wody, 30 minut spaceru, 20 stron książki, Wcześnie spać, Godzina bez ekranu';

  @override
  String get tplCleaningName => 'Sprzątanie domu';

  @override
  String get tplCleaningDesc => 'Cotygodniowa lista sprzątania';

  @override
  String get tplCleaningItems =>
      'Odkurzyć meble, Odkurzyć podłogi, Umyć podłogi, Wyczyścić łazienkę, Blat kuchenny, Pranie, Wynieść śmieci, Zmienić pościel';

  @override
  String get tplMovingName => 'Lista przeprowadzki';

  @override
  String get tplMovingDesc => 'Zadania przed i po przeprowadzce';

  @override
  String get tplMovingItems =>
      'Zamówić przeprowadzkę, Kupić kartony i taśmę, Zmienić adres, Prąd / woda / gaz, Przenieść internet, Przekazać klucze';

  @override
  String get tplGiftsName => 'Lista prezentów';

  @override
  String get tplGiftsDesc => 'Kto dostaje co, pomysły';

  @override
  String get tplGiftsItems => 'Mama, Tata, Rodzeństwo, Przyjaciel';

  @override
  String get tplWatchlistName => 'Do obejrzenia';

  @override
  String get tplWatchlistDesc => 'Filmy, seriale i książki';

  @override
  String get tplWorkoutName => 'Trening';

  @override
  String get tplWorkoutDesc => 'Od rozgrzewki po rozciąganie';

  @override
  String get tplWorkoutItems =>
      'Rozgrzewka 5 min, Przysiady 3×12, Pompki 3×10, Brzuszki 3×15, Deska 3×45 s, Rozciąganie 5 min';

  @override
  String get tplGoalsName => 'Cele';

  @override
  String get tplGoalsDesc => 'Cele na rok, miesiąc i tydzień';

  @override
  String get tplGoalsYear => 'W tym roku';

  @override
  String get tplGoalsMonth => 'W tym miesiącu';

  @override
  String get tplGoalsWeek => 'W tym tygodniu';

  @override
  String get tplGoalsWhy => 'Dlaczego to ważne?';

  @override
  String get templateNew => 'Nowy szablon';

  @override
  String get templateEdit => 'Edytuj szablon';

  @override
  String get templateDuplicate => 'Duplikuj';

  @override
  String get templateSaveAsMine => 'Zapisz w moich szablonach';

  @override
  String get templateUntitled => 'Szablon bez nazwy';

  @override
  String get templateTypeText => 'Tekst';

  @override
  String get templateTitleHelp =>
      'Tytuł notatek tworzonych z tego szablonu (opcjonalnie)';

  @override
  String get templateBody => 'Tekst';

  @override
  String get templateHeadingHelp =>
      'Wiersze zaczynające się od „# ” to nagłówki, od „## ” podtytuły.';

  @override
  String get templateDiscardTitle => 'Odrzucić zmiany?';

  @override
  String get templateDiscard => 'Odrzuć';

  @override
  String templateDeleted(String name) {
    return 'Usunięto „$name”';
  }

  @override
  String get addVideoFromGallery => 'Film z galerii';

  @override
  String get addYouTubeVideo => 'Film z YouTube';

  @override
  String get addYouTubeVideoSubtitle =>
      'Odtwarza się w notatce, oglądaj w małym oknie';

  @override
  String get youTubeLinkHelp =>
      'Wklej link do filmu z YouTube (youtube.com lub youtu.be).';

  @override
  String get youTubeInvalidLink => 'To nie jest link do filmu z YouTube';

  @override
  String get youTubeOpenInBrowserInfo =>
      'Na tym urządzeniu nie można odtworzyć filmu w aplikacji; można go otworzyć w przeglądarce.';

  @override
  String get youTubeOpenExternal => 'Otwórz w YouTube';

  @override
  String get pictureInPicture => 'Obraz w obrazie';

  @override
  String get pinMediaTop => 'Przypnij u góry';

  @override
  String get pinMediaRelease => 'Puść: przypnij u góry (notatka poniżej)';

  @override
  String get unpinMedia => 'Odłóż na stronę';

  @override
  String get unpinMediaRelease => 'Puść: odłóż na stronę';

  @override
  String get pinnedMediaResize => 'Wysokość panelu — przeciągnij, aby zmienić';

  @override
  String get addPageSubtitle => 'Dodaje do notatki nową pustą stronę';

  @override
  String pageOf(int current, int total) {
    return 'Strona $current / $total';
  }

  @override
  String pageAdded(int page) {
    return 'Dodano stronę $page';
  }

  @override
  String get deletePageConfirm =>
      'Usunąć tekst tej strony? Jej obrazy przejdą na sąsiednią stronę. Możesz go przywrócić przyciskiem Cofnij.';

  @override
  String get embedNewPdf => 'PDF';

  @override
  String get embedNewImage => 'Obraz';

  @override
  String get embedNewVideo => 'Wideo';

  @override
  String get embedNewYouTube => 'YouTube';

  @override
  String get embedPickTitle => 'Co osadzić?';

  @override
  String embedPickTitleFor(String label) {
    return 'Osadź w „$label”';
  }

  @override
  String get embedPickInfo =>
      'Dotknij tekstu, aby otworzyć osadzony element na miejscu.';

  @override
  String get embedSectionNew => 'Dodaj nowe';

  @override
  String get embedSectionExisting => 'Załączniki tej notatki';

  @override
  String get embedReplace => 'Zamień';

  @override
  String get embedRemove => 'Usuń osadzenie';

  @override
  String get embedRemoved => 'Usunięto osadzenie';

  @override
  String get guideTitle => 'Instrukcja obsługi';

  @override
  String get guideMenuInfo => 'Wszystkie funkcje krok po kroku';

  @override
  String get guideSearchHint => 'Szukaj w instrukcji — „strona”, „YouTube”';

  @override
  String get guideContents => 'Spis treści';

  @override
  String get guideOpenScreen => 'Otwórz ekran';

  @override
  String guideNoResults(String query) {
    return 'Brak wyników dla „$query”';
  }

  @override
  String get copyVideoLink => 'Kopiuj link';

  @override
  String get videoLinkCopied => 'Link skopiowany';

  @override
  String get attachSectionVisual => 'Obrazy i rysunek';

  @override
  String get menuSectionOrganize => 'Porządkuj';

  @override
  String get menuSectionCopy => 'Kopiuj i eksportuj';

  @override
  String get menuSectionTools => 'Narzędzia';

  @override
  String get menuSectionProtect => 'Ochrona i przechowywanie';

  @override
  String get menuSectionContent => 'Treść';

  @override
  String get menuSectionPeople => 'Konto i kontakty';

  @override
  String get menuSectionHome => 'Ekran główny';

  @override
  String get menuSectionApp => 'Aplikacja';

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

  @override
  String get quickAddMore => 'ŞABLON VE DEFTER';

  @override
  String get quickAddFrequent => 'SIK KULLANDIKLARIN';

  @override
  String get quickAddAll => 'Tümü';

  @override
  String get quickAddLess => 'Daha az';

  @override
  String get bubbleDone => 'Bitti';

  @override
  String get bubbleEditShort => 'Düzenle';

  @override
  String get bubblePlainModeShort => 'Metin';

  @override
  String get pageBarMore => 'Sayfa ve not seçenekleri';

  @override
  String get viewModeTitle => 'Widok';

  @override
  String get viewModePinned => 'Przypięty';

  @override
  String get viewModeFloating => 'Pływający';

  @override
  String get viewModeBubbles => 'Dymki';

  @override
  String get viewModePinnedHint =>
      'Przypnij na górze — zostaje u góry, notatka przewija się pod nim';

  @override
  String get viewModeFloatingHint => 'Pływa na stronie — tekst go opływa';

  @override
  String get viewModeBubblesHint =>
      'Widok dymków — dymki, wyróżnienia i pióro na stronie';

  @override
  String get viewModeSwitchedFloating => 'Z powrotem na stronie';

  @override
  String get videoNoteAtTime => 'Notatka w tym momencie';

  @override
  String get videoNoteAtTimeShort => 'Notatka';

  @override
  String get videoTimeUnknown =>
      'Nie udało się odczytać czasu wideo — najpierw je odtwórz.';

  @override
  String get videoSpeed => 'Szybkość odtwarzania';

  @override
  String get videoLoop => 'Powtarzaj';

  @override
  String get bubbleSmaller => 'Zmniejsz dymek';

  @override
  String get bubbleLarger => 'Powiększ dymek';

  @override
  String get bubbleAllSmaller => 'Zmniejsz wszystkie dymki';

  @override
  String get bubbleAllLarger => 'Powiększ wszystkie dymki';

  @override
  String get bubblesShow => 'Pokaż dymki';

  @override
  String get bubblesHide => 'Ukryj dymki';

  @override
  String get shareIncludeVideoLinks => 'Linki do filmów';

  @override
  String get shareQuickPdf => 'PDF';

  @override
  String get shareAsImage => 'Obraz';

  @override
  String shareAttachmentFiles(int count) {
    return 'Załączniki ($count)';
  }

  @override
  String get shareToFriendShort => 'Do znajomego';

  @override
  String get shareCollaborateShort => 'Współpraca';

  @override
  String get shareAsNoteShort => 'Pakiet notatki';

  @override
  String get shareMoreSection => 'WIĘCEJ';

  @override
  String get shareQuickPreparing => 'Przygotowywanie…';

  @override
  String get shareAttachmentFilesNone =>
      'Brak załączników do udostępnienia na tym urządzeniu.';

  @override
  String get attachmentRemoved => 'Załącznik usunięty';

  @override
  String get pinnedEmbedOnPage => 'Osadź na stronie (pływający)';

  @override
  String get customizeHideItem => 'Ukryj';

  @override
  String get customizeShowItem => 'Pokaż';

  @override
  String get customizeModeTitle => 'Tryb edycji';

  @override
  String get customizeModeHint => 'Dotknij elementów, aby je ukryć lub pokazać';

  @override
  String customizeHiddenCount(int count) {
    return 'Ukryte: $count · dotknij, aby zmienić';
  }

  @override
  String get customizeSave => 'Zapisz';

  @override
  String get customizeSaved => 'Układ zapisany';

  @override
  String videoBackSeconds(int seconds) {
    return 'Wstecz o $seconds s';
  }

  @override
  String videoForwardSeconds(int seconds) {
    return 'Naprzód o $seconds s';
  }

  @override
  String get personalizeTitle => 'Personalizuj';

  @override
  String get personalizeInfo => 'Widoczne obszary i przyciski, wtyczki';

  @override
  String get personalizeOpen => 'Otwórz personalizację';

  @override
  String get customizeStartTitle => 'Edytuj na ekranie';

  @override
  String get customizeStartInfo =>
      'Włącz tryb edycji, a potem dotykaj przycisków i obszarów na dowolnym ekranie, aby je ukryć lub pokazać. Na koniec dotknij Zapisz na pasku u góry.';

  @override
  String get customizeStart => 'Uruchom tryb edycji';

  @override
  String get customizeActive => 'Tryb edycji jest włączony';

  @override
  String get customizeModeShort => 'Ukrywaj lub pokazuj, dotykając ekranów';

  @override
  String get personalizeModules => 'WTYCZKI';

  @override
  String get personalizeModulesInfo =>
      'Wyłączenie wtyczki usuwa jej przyciski wszędzie.';

  @override
  String get moduleAi => 'AI';

  @override
  String get moduleAiInfo =>
      'Przyciski AI na ekranie głównym i ekranie notatki';

  @override
  String get moduleVoice => 'Głos';

  @override
  String get moduleVoiceInfo =>
      'Notatki głosowe, dyktowanie, nagrywanie dźwięku';

  @override
  String get moduleVideo => 'Wideo';

  @override
  String get moduleVideoInfo => 'Nagrywanie, filmy z galerii, YouTube';

  @override
  String get moduleDocuments => 'Dokumenty';

  @override
  String get moduleDocumentsInfo => 'Dodawanie PDF i slajdów';

  @override
  String get moduleScan => 'Skanowanie';

  @override
  String get moduleScanInfo => 'Skanowanie dokumentów i kody QR';

  @override
  String get moduleDrawing => 'Rysowanie';

  @override
  String get moduleDrawingInfo => 'Pismo odręczne i rysunki';

  @override
  String get moduleTemplates => 'Szablony';

  @override
  String get moduleTemplatesInfo =>
      'Notatki z szablonów, lista zakupów, zeszyt archiwum';

  @override
  String get moduleTags => 'Etykiety notatki';

  @override
  String get moduleTagsInfo =>
      'Etykiety tagów, folderów i przypomnień pod tytułem';

  @override
  String get moduleCollaboration => 'Współpraca';

  @override
  String get moduleCollaborationInfo =>
      'Przycisk dodawania osoby na ekranie notatki';

  @override
  String get moduleMixed => 'częściowo włączone';

  @override
  String get personalizeEditorBar => 'EKRAN NOTATKI · DOLNY PASEK';

  @override
  String get personalizeEditorTop => 'EKRAN NOTATKI · GÓRNY PASEK I OBSZARY';

  @override
  String get personalizeQuickAdd => 'MENU NOWEJ NOTATKI (+)';

  @override
  String get personalizeAttachSheet => 'ARKUSZ DODAWANIA (+ W NOTATCE)';

  @override
  String get personalizeVideo => 'WIDEO';

  @override
  String get personalizeHome => 'EKRAN GŁÓWNY';

  @override
  String get personalizeHomeItemsInfo =>
      'Zaznaczone elementy są widoczne na ekranie głównym; w trybie edycji możesz też je tam dotknąć, aby ukryć.';

  @override
  String get personalizeBubbles => 'DYMKI';

  @override
  String get personalizeChipsInfo =>
      'Zaznaczone elementy są widoczne; dotknij, aby przełączyć.';

  @override
  String get personalizeReset => 'Przywróć domyślne';

  @override
  String get personalizeResetConfirm =>
      'Przywrócić domyślne wszystkie ustawienia widoczności i przewijania?';

  @override
  String get personalizeResetDone => 'Przywrócono ustawienia domyślne';

  @override
  String get uiItemAttachments => 'Załączniki';

  @override
  String get uiItemDate => 'Data edycji';

  @override
  String get uiItemSync => 'Ikona synchronizacji';

  @override
  String get uiItemFrequent => 'Często używane';

  @override
  String get uiItemVideoTime => 'Wskaźnik czasu';

  @override
  String get videoSeekBack => 'Przewijanie wstecz';

  @override
  String get videoSeekForward => 'Przewijanie naprzód';

  @override
  String get bubbleSizeSetting => 'Rozmiar dymków';

  @override
  String get noteMenuCustomize => 'Dostosuj ekran';

  @override
  String secondsShort(int seconds) {
    return '$seconds s';
  }

  @override
  String personalizeHiddenSummary(int count) {
    return 'Ukryte: $count';
  }

  @override
  String get uiItemVideoBadge => 'WIDEO';

  @override
  String get listPartRemoved => 'Lista usunięta';

  @override
  String get textPartRemoved => 'Tekst usunięty';

  @override
  String get notePartsMenu => 'Sekcje';

  @override
  String get removeListPart => 'Usuń listę';

  @override
  String get removeTextPart => 'Usuń tekst';
}
