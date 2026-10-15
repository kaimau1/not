// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Notes';

  @override
  String get loginTagline => 'Vos notes, sur tous vos appareils';

  @override
  String get signInWithGoogle => 'Se connecter avec Google';

  @override
  String loginError(String error) {
    return 'Échec de la connexion : $error';
  }

  @override
  String get searchHint => 'Rechercher dans les notes...';

  @override
  String get filterAll => 'Tout';

  @override
  String get filterText => 'Texte';

  @override
  String get filterChecklist => 'Liste';

  @override
  String get filterOrdered => 'Numérotée';

  @override
  String get filterPinned => 'Épinglées';

  @override
  String get filterStarred => 'Favorites';

  @override
  String get star => 'Ajouter aux favoris';

  @override
  String get unstar => 'Retirer des favoris';

  @override
  String editedAt(String date) {
    return 'Modifiée : $date';
  }

  @override
  String get sectionPinned => 'Épinglées';

  @override
  String get sectionOthers => 'Autres';

  @override
  String get emptyNotes => 'Aucune note pour l\'instant';

  @override
  String get emptyNotesHint => 'Appuyez sur + pour créer votre première note';

  @override
  String get emptySearch => 'Aucun résultat';

  @override
  String get newTextNote => 'Note texte';

  @override
  String get newChecklist => 'Liste';

  @override
  String get newOrderedList => 'Liste numérotée';

  @override
  String get noteDeleted => 'Note supprimée';

  @override
  String notesDeletedCount(int count) {
    return '$count notes supprimées';
  }

  @override
  String selectedCount(int count) {
    return '$count sélectionnées';
  }

  @override
  String get deleteSelected => 'Supprimer la sélection';

  @override
  String get undo => 'Annuler';

  @override
  String get redo => 'Rétablir';

  @override
  String get titleHint => 'Titre';

  @override
  String get bodyHint => 'Note...';

  @override
  String get newItemHint => 'Nouvel élément';

  @override
  String moreItemsCount(int count) {
    return '+$count autres éléments';
  }

  @override
  String get addAttachment => 'Ajouter';

  @override
  String get addAttachmentMore => 'Autres types de pièces jointes…';

  @override
  String get addImage => 'Ajouter une image';

  @override
  String get addPdf => 'Ajouter un PDF';

  @override
  String get addSlide => 'Ajouter des diapositives';

  @override
  String get pasteImage => 'Coller l\'image du presse-papiers';

  @override
  String get clipboardEmpty => 'Aucune image dans le presse-papiers';

  @override
  String get noNoteSelected => 'Choisissez une note à gauche';

  @override
  String attachmentFailed(String error) {
    return 'Impossible d\'ajouter la pièce jointe : $error';
  }

  @override
  String get attachmentCopying => 'Copie en cours...';

  @override
  String get attachmentUploading => 'Envoi en cours...';

  @override
  String get attachmentUploadFailed =>
      'Yüklenemedi — yeniden denemek için dokun';

  @override
  String get attachmentNotSynced =>
      'Ce fichier n\'est pas encore synchronisé sur cet appareil';

  @override
  String attachmentTooLarge(int limit) {
    return 'Fichier trop volumineux ($limit Mo maximum)';
  }

  @override
  String storageFull(String limit) {
    return 'Stockage plein ($limit). Supprimez d\'anciennes pièces jointes pour libérer de l\'espace.';
  }

  @override
  String get storageUsage => 'Stockage';

  @override
  String storageUsageValue(String used, String limit) {
    return '$used sur $limit utilisés';
  }

  @override
  String get removeAttachment => 'Supprimer la pièce jointe';

  @override
  String get pin => 'Épingler';

  @override
  String get unpin => 'Désépingler';

  @override
  String get delete => 'Supprimer';

  @override
  String get color => 'Couleur';

  @override
  String get aiTitle => 'IA';

  @override
  String get aiSummarize => 'Résumer la note';

  @override
  String get aiAnalyze => 'Analyser';

  @override
  String get aiSectionNote => 'Cette note';

  @override
  String get aiSectionAttachments => 'Pièces jointes';

  @override
  String get summarize => 'Résumer';

  @override
  String get summaryDetailTitle => 'Type de résumé';

  @override
  String get summaryShort => 'Résumé court';

  @override
  String get summaryShortInfo =>
      'Quelques phrases de synthèse et les points clés';

  @override
  String get summaryDetailed => 'Résumé détaillé';

  @override
  String get summaryDetailedInfo =>
      'Assez complet pour ne pas avoir à ouvrir l\'original';

  @override
  String get listen => 'Écouter';

  @override
  String get ask => 'Poser une question';

  @override
  String get extractText => 'Extraire le texte';

  @override
  String get transcribe => 'Transcrire';

  @override
  String get listenToNote => 'Lire à voix haute';

  @override
  String get aiNoApiKey =>
      'Saisissez d\'abord votre clé API Gemini dans les réglages';

  @override
  String aiError(String error) {
    return 'Échec de la requête IA : $error';
  }

  @override
  String get aiSummaryTitle => 'Résumé IA';

  @override
  String get aiThinking => 'Réflexion...';

  @override
  String get copy => 'Copier';

  @override
  String get copied => 'Copié';

  @override
  String get settingsSearchHint =>
      'Rechercher des paramètres — « briefing », « microphone »';

  @override
  String settingsSearchEmpty(String query) {
    return 'Aucun paramètre ne correspond à « $query »';
  }

  @override
  String get settings => 'Réglages';

  @override
  String get settingsAppearance => 'Apparence';

  @override
  String get themeSystem => 'Système';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get settingsAi => 'IA';

  @override
  String get geminiApiKey => 'Clé API Gemini';

  @override
  String get geminiApiKeyHint => 'Collez la clé commençant par AIza...';

  @override
  String get geminiApiKeyInfo =>
      'La clé est facultative : sans elle, les requêtes IA passent par le service intégré de l\'application (quota quotidien gratuit, plus élevé avec Premium). Pour un usage illimité avec votre propre clé, obtenez-en une gratuitement sur aistudio.google.com ; la clé est conservée uniquement sur cet appareil, dans un stockage sécurisé.';

  @override
  String aiBuiltInPremium(int count) {
    return 'IA intégrée : Premium — $count points restants aujourd\'hui';
  }

  @override
  String aiBuiltInRemaining(int count) {
    return 'IA intégrée : $count points gratuits restants aujourd\'hui';
  }

  @override
  String get aiBuiltInByok => 'Votre propre clé — illimité';

  @override
  String get aiReport => 'Signaler cette réponse';

  @override
  String get aiReportThanks => 'Signalement reçu, merci';

  @override
  String get privacyPolicyTitle => 'Politique de confidentialité';

  @override
  String get lockNote => 'Verrouiller';

  @override
  String get unlockNote => 'Déverrouiller';

  @override
  String get lockedNote => 'Note verrouillée';

  @override
  String get unlockAuthReason =>
      'Confirmez votre identité pour ouvrir la note verrouillée';

  @override
  String get exportBackup => 'Exporter la sauvegarde (JSON)';

  @override
  String get expandListItems => 'Afficher les lignes en entier';

  @override
  String get expandListItemsInfo =>
      'Les éléments longs passent à la ligne et restent entièrement visibles. Désactivé, une ligne tient sur un seul niveau et se déploie au toucher.';

  @override
  String get quickCaptureRowSetting => 'Barre de note rapide';

  @override
  String get quickCaptureRowInfo =>
      'Affiche un champ \"Nouvelle note...\" en haut de l\'écran. Sinon, utilise le bouton +.';

  @override
  String get emptyTrash => 'Vider la corbeille';

  @override
  String emptyTrashConfirm(int count) {
    return '$count notes seront définitivement supprimées. Cette action est irréversible. Confirmer ?';
  }

  @override
  String get trashEmptied => 'Corbeille vidée';

  @override
  String get validateAndSave => 'Vérifier et enregistrer';

  @override
  String get clear => 'Effacer';

  @override
  String get aiDiagnostics => 'Diagnostic IA';

  @override
  String get aiDiagnosticsEmpty => 'Aucune erreur enregistrée';

  @override
  String aiDiagnosticsCount(int count) {
    return '$count derniers enregistrements d\'erreur';
  }

  @override
  String get apiKeyValid => 'Clé API vérifiée et enregistrée';

  @override
  String get apiKeyInvalid => 'Clé API non valide';

  @override
  String get apiKeySavedBadge => 'Enregistrée';

  @override
  String get removeApiKey => 'Supprimer la clé';

  @override
  String get refresh => 'Actualiser';

  @override
  String get account => 'Compte';

  @override
  String get signOut => 'Se déconnecter';

  @override
  String get signOutConfirm => 'Voulez-vous vraiment vous déconnecter ?';

  @override
  String get signOutAnonymousWarning =>
      'Tu utilises un compte local : la déconnexion rendra ce compte et TOUTES ses notes définitivement inaccessibles — sans sauvegarde, impossible de les récupérer. Associe d\'abord un compte Google. Se déconnecter quand même ?';

  @override
  String get deleteAccount => 'Supprimer mon compte et mes données';

  @override
  String get deleteAccountWarning =>
      'Cette action est irréversible : toutes vos notes, vos pièces jointes et votre compte seront définitivement supprimés. Voulez-vous continuer ?';

  @override
  String get deleteAccountConfirm => 'Supprimer définitivement';

  @override
  String get licensesTitle => 'Licences open source';

  @override
  String get generating => 'Génération...';

  @override
  String get retry => 'Réessayer';

  @override
  String get cancel => 'Annuler';

  @override
  String get close => 'Fermer';

  @override
  String get ok => 'OK';

  @override
  String get syncPending => 'En attente de synchronisation';

  @override
  String get synced => 'Synchronisé';

  @override
  String genericError(String error) {
    return 'Une erreur est survenue : $error';
  }

  @override
  String get addTag => 'Étiquette';

  @override
  String get tagHint => 'ex. travail, maison, école';

  @override
  String get addReminder => 'Me le rappeler';

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
  String get share => 'Partager';

  @override
  String get archive => 'Archiver';

  @override
  String get unarchive => 'Désarchiver';

  @override
  String get archiveTitle => 'Archives';

  @override
  String get archiveEmpty => 'Aucune note archivée';

  @override
  String get trashTitle => 'Corbeille';

  @override
  String get trashEmpty => 'La corbeille est vide';

  @override
  String get trashInfo =>
      'Les notes supprimées restent ici ; vous pouvez les restaurer ou les supprimer définitivement.';

  @override
  String get restore => 'Restaurer';

  @override
  String get deleteForever => 'Supprimer définitivement';

  @override
  String get deleteForeverConfirm =>
      'Cette note sera définitivement supprimée. Confirmer ?';

  @override
  String assistantDeleteConfirm(String title) {
    return 'Asistan \"$title\" notunu çöp kutusuna taşımak istiyor. Onaylıyor musun?';
  }

  @override
  String get recordAudio => 'Enregistrement vocal';

  @override
  String get recording => 'Enregistrement...';

  @override
  String get stopAndSave => 'Terminer et ajouter';

  @override
  String get micPermissionDenied =>
      'L\'autorisation du microphone a été refusée';

  @override
  String get speechRecognitionFailed =>
      'La reconnaissance vocale n\'a pas fonctionné. Vérifiez que l\'autorisation du microphone est accordée et que l\'application Google est à jour.';

  @override
  String get addDrawing => 'Ajouter un dessin';

  @override
  String get drawingTitle => 'Dessin';

  @override
  String get addToNote => 'Ajouter à la note';

  @override
  String get chatTitle => 'Assistant de notes';

  @override
  String get chatHint =>
      'Posez une question sur vos notes : « quelle était cette recette notée la semaine dernière ? », « que manque-t-il à ma liste de courses ? »';

  @override
  String get chatInputHint => 'Saisissez une question...';

  @override
  String get fontSize => 'Taille du texte';

  @override
  String get fontSizePreview => 'Vos notes ressembleront à ceci';

  @override
  String get darkSchedule => 'Programmation du thème sombre';

  @override
  String get darkScheduleInfo =>
      'Bascule vers le thème sombre entre les heures que vous définissez';

  @override
  String get aiTranslate => 'Traduire';

  @override
  String get voiceCommand => 'Commande vocale';

  @override
  String get semanticSearchToggle => 'Recherche sémantique avec l\'IA';

  @override
  String get semanticSearchHint =>
      'Rechercher par sens : « frais de voiture »...';

  @override
  String get briefingTitle => 'Point du jour';

  @override
  String get briefingLoading => 'Préparation de votre point du jour...';

  @override
  String get briefingEmpty => 'Rien pour aujourd\'hui';

  @override
  String get briefingSetting => 'Notification du point du jour';

  @override
  String get briefingSettingInfo =>
      'Recevez chaque matin une notification avec le résumé de la journée, à l\'heure de votre choix';

  @override
  String get autoTagSetting => 'Étiqueter automatiquement';

  @override
  String get autoTagSettingInfo =>
      'Quand une note est fermée sans étiquette, l\'IA en ajoute une adaptée';

  @override
  String get suggestTags => 'Suggérer des étiquettes';

  @override
  String get aiFixNote => 'Corriger la note';

  @override
  String get fixLevelTitle => 'Jusqu\'où corriger ?';

  @override
  String get fixSimple => 'Léger';

  @override
  String get fixSimpleInfo => 'Orthographe et fautes de frappe uniquement';

  @override
  String get fixBalanced => 'Équilibré';

  @override
  String get fixBalancedInfo =>
      'Également la structure des phrases, pour un texte plus net';

  @override
  String get fixDetailed => 'Approfondi';

  @override
  String get fixDetailedInfo => 'Réécrit l\'ensemble du texte de bout en bout';

  @override
  String get existingTagsLabel => 'Étiquettes précédentes';

  @override
  String get aiSkipCheckedSetting =>
      'Exclure les éléments cochés des modifications IA';

  @override
  String get aiSkipCheckedInfo =>
      'Quand l\'IA corrige ou traduit une liste, les éléments terminés (cochés) restent exactement tels quels ; seuls les éléments non cochés sont modifiés.';

  @override
  String get noteUpdatedUndo => 'Note mise à jour';

  @override
  String get aiImprove => 'Améliorer la note';

  @override
  String get improveFormal => 'Rendre plus formel';

  @override
  String get improveShorten => 'Raccourcir';

  @override
  String get improveBullets => 'Convertir en liste à puces';

  @override
  String get improveNumbered => 'Convertir en liste numérotée';

  @override
  String get replaceNote => 'Remplacer la note';

  @override
  String get openAsNewNote => 'En nouvelle note';

  @override
  String get pdfChatHint =>
      'Posez une question sur ce PDF : « résume-le », « y a-t-il une clause pénale ? », « quelle est la date limite ? »';

  @override
  String get pdfChatInputHint => 'Saisissez une question sur le PDF...';

  @override
  String get voiceCaptureHint =>
      'Parlez : « acheter du lait et du pain » ou « réunion demain à 9 h, rappelle-le-moi » — l\'IA rédige votre note quand vous avez fini.';

  @override
  String get voiceFinish => 'Terminer';

  @override
  String get voiceProcessing => 'Traitement de ce que vous avez dit...';

  @override
  String get voiceNothingHeard =>
      'Aucune parole détectée dans l\'enregistrement';

  @override
  String get voiceNoteSaved => 'Votre note vocale a été enregistrée';

  @override
  String get openNote => 'Ouvrir la note';

  @override
  String get remindersTitle => 'Rappels';

  @override
  String get remindersEmpty => 'Aucun rappel';

  @override
  String get remindersEmptyHint =>
      'Ajoutez un rappel à une note, ou créez une note avec un rappel via le bouton +';

  @override
  String get remindersUpcoming => 'À venir';

  @override
  String get remindersPast => 'Passés';

  @override
  String get reminderInPast =>
      'L\'heure choisie est passée — choisis une heure future.';

  @override
  String get newReminder => 'Nouveau rappel';

  @override
  String get remindersUntitled => 'Note sans titre';

  @override
  String get remindersEdit => 'Modifier l\'heure';

  @override
  String get remindersRemove => 'Supprimer le rappel';

  @override
  String get aiModelChat => 'Résumés, titres, étiquettes et discussion';

  @override
  String get aiModelDocument => 'Chat document et résumé PDF';

  @override
  String get aiModelTranslate => 'Traduction';

  @override
  String get aiModelVoice => 'Assistant de note vocale';

  @override
  String get aiModelAuto => 'Automatique (recommandé)';

  @override
  String get aiModelsInfo =>
      'Vous pouvez choisir un modèle distinct par tâche : les textes courts se contentent d\'un modèle rapide, les longs documents demandent un modèle plus puissant. Si le modèle choisi atteint son quota ou est retiré, le suivant est essayé automatiquement.';

  @override
  String get clearNote => 'Vider';

  @override
  String get clearNoteConfirm =>
      'Le contenu de la note (texte et éléments de liste) sera supprimé. Confirmer ?';

  @override
  String get themePaper => 'Papier';

  @override
  String get calculatorTitle => 'Calculatrice';

  @override
  String get calcExpressionHint => 'ex. 12,5×3+40';

  @override
  String get calcInvalid => 'Expression non valide';

  @override
  String get liveDictation => 'Dicter';

  @override
  String get voiceCaptureAi => 'Sesli yakala (yapay zekâ)';

  @override
  String get dictationListening =>
      'Écoute... le texte s\'écrit à mesure que vous parlez';

  @override
  String get dictationNoKeyInfo =>
      'La dictée en direct n\'est pas disponible sur cet appareil ; l\'enregistrement sera transcrit en une fois à l\'arrêt.';

  @override
  String get dictationHoldHint =>
      'Maintenez le microphone et parlez ; le texte s\'écrit quand vous relâchez';

  @override
  String itemsSelected(int count) {
    return '$count éléments sélectionnés';
  }

  @override
  String get noteChatTitle => 'Discuter avec cette note';

  @override
  String get noteChatHint => 'Posez une question sur cette note';

  @override
  String get noteChatIntro =>
      'Le contenu de la note et ses pièces jointes (PDF/image) sont lus, et votre question trouve sa réponse à partir d\'eux.';

  @override
  String get dictationProcessing => 'Transcription...';

  @override
  String get aiDailyManualInfo =>
      'Avec la formule gratuite, ce contenu n\'est pas généré automatiquement et n\'entame donc pas votre quota quotidien. Vous pouvez le générer une fois par jour avec le bouton ci-dessous.';

  @override
  String get aiGenerate => 'Générer';

  @override
  String get aiGeneratedTodayInfo =>
      'Ce contenu a été généré aujourd\'hui. Avec la formule gratuite, il se renouvelle une fois par jour ; vous pourrez le générer à nouveau demain.';

  @override
  String get voiceAssistantTitle => 'Assistant de note vocale';

  @override
  String get voiceListening => 'Écoute...';

  @override
  String get voiceHoldHint =>
      'Maintenez et parlez ; votre note est créée quand vous relâchez';

  @override
  String get voiceTapHint =>
      'Appuyez et parlez ; appuyez à nouveau pour terminer';

  @override
  String get voiceTooShort => 'Cet enregistrement était trop court, réessayez';

  @override
  String get voiceModeSetting => 'Fonctionnement';

  @override
  String get voiceModeHold => 'Maintenir pour parler';

  @override
  String get voiceModeTap => 'Appuyer pour démarrer / appuyer pour arrêter';

  @override
  String get voiceModeInfo =>
      'Maintenir pour parler : l\'écoute dure tant que vous maintenez le bouton et la note est créée au relâchement. Appuyer pour démarrer : une pression lance l\'enregistrement, une seconde y met fin.';

  @override
  String get voiceHeardLive => 'Parole détectée';

  @override
  String get voiceCaptureReady => 'Dictée prête';

  @override
  String get voiceCaptureEditHint => 'Appuyez sur le texte pour le modifier';

  @override
  String voiceCapturePunctuation(String language) {
    return '$language · ponctuation automatique';
  }

  @override
  String get voiceCaptureAddToNote => 'Ajouter à la note';

  @override
  String get voiceCaptureCreateNote => 'Créer une note';

  @override
  String get voiceCaptureAiNote => 'Note IA';

  @override
  String get voiceCapturePlainNote => 'Note simple';

  @override
  String get voiceCloseTitle => 'Ta dictée est toujours là';

  @override
  String get voiceCloseKeepTalking => 'Continuer à parler';

  @override
  String get voiceCaptureRestart => 'Réenregistrer';

  @override
  String get voiceChipSummarizeAdd => 'Ajouter comme résumé';

  @override
  String get voiceChipSummarizeSave => 'Enregistrer comme résumé';

  @override
  String get voiceChipToItems => 'Diviser en éléments';

  @override
  String get voiceChipAsList => 'Créer une liste';

  @override
  String get voiceChipFix => 'Corriger';

  @override
  String get voiceChipCompose => 'Laisser l\'assistant rédiger';

  @override
  String get editorToolList => 'Liste';

  @override
  String get permissionsTitle => 'Autorisations';

  @override
  String get permMic => 'Microphone';

  @override
  String get permMicInfo => 'Nécessaire pour les notes vocales et la dictée';

  @override
  String get permNotifications => 'Notifications';

  @override
  String get permNotificationsInfo =>
      'Nécessaires pour les rappels et le point du jour';

  @override
  String get permBattery => 'Optimisation de la batterie';

  @override
  String get permBatteryInfo =>
      'Exemptez l\'application des restrictions de batterie pour que les rappels arrivent à l\'heure';

  @override
  String get showTagChips => 'Afficher les puces d\'étiquette';

  @override
  String get showFolderChips => 'Afficher les puces de dossier';

  @override
  String videoTooBigForAi(int mb) {
    return 'La vidéo est trop volumineuse pour être envoyée à l\'IA ($mb Mo). Enregistrez-en une plus courte.';
  }

  @override
  String get permCamera => 'Appareil photo';

  @override
  String get permCameraInfo => 'Nécessaire pour les notes vidéo et les photos';

  @override
  String get permOnboardTitle => 'Avant de commencer';

  @override
  String get permOnboardInfo =>
      'Notes ne demande ces autorisations qu\'au moment où vous utilisez la fonction correspondante. Vous pouvez les accorder maintenant ci-dessous, ou les modifier plus tard dans Réglages > Autorisations.';

  @override
  String get permOnboardGrantAll => 'Accorder les autorisations';

  @override
  String get permOnboardSkip => 'Pas maintenant';

  @override
  String get newVideoNote => 'Note vidéo';

  @override
  String get videoLocalOnly =>
      'Cette vidéo est stockée uniquement sur cet appareil (non envoyée vers le cloud)';

  @override
  String get videoToNote => 'Créer une note à partir de la vidéo';

  @override
  String get videoToNoteRunning => 'Analyse de la vidéo…';

  @override
  String get permGranted => 'Accordée';

  @override
  String get permGrant => 'Accorder';

  @override
  String get permOpenSettings => 'Ouvrir les réglages';

  @override
  String get newHandwriting => 'Écriture manuscrite';

  @override
  String get newVoiceCapture => 'Note vocale';

  @override
  String get suggestTitle => 'Suggérer un titre';

  @override
  String get noteMetaMenu => 'Étiquette · Titre · Rappel';

  @override
  String get folder => 'Dossier';

  @override
  String get noFolder => 'Aucun dossier';

  @override
  String get newFolder => 'Nouveau dossier';

  @override
  String get editFolder => 'Modifier le dossier';

  @override
  String get deleteFolder => 'Supprimer le dossier';

  @override
  String deleteFolderConfirm(String name) {
    return 'Le dossier « $name » sera supprimé. Les notes qu\'il contient ne sont pas supprimées — elles n\'auront simplement plus de dossier.';
  }

  @override
  String get folderNameHint => 'Nom du dossier';

  @override
  String get folderIcon => 'Icône';

  @override
  String get editFilters => 'Modifier les filtres';

  @override
  String get editFiltersInfo =>
      'Choisissez les filtres affichés sur l\'écran d\'accueil. En masquer garde la page épurée.';

  @override
  String get select => 'Sélectionner';

  @override
  String get noteArchived => 'Note archivée';

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
    return 'Supprimer les éléments cochés ($count)';
  }

  @override
  String get removeItem => 'Supprimer l\'élément';

  @override
  String get copyWholeNote => 'Copier toute la note';

  @override
  String get allCopied => 'Toute la note a été copiée dans le presse-papiers';

  @override
  String get speechPlay => 'Lire à voix haute';

  @override
  String get speechPause => 'Pause';

  @override
  String get speechResume => 'Reprendre';

  @override
  String get speechStop => 'Arrêter';

  @override
  String get speechRate => 'Vitesse de lecture';

  @override
  String get speechSystemDefault => 'Valeur par défaut du système';

  @override
  String get speechNoVoices => 'Aucune voix n\'est installée sur cet appareil';

  @override
  String speechVoiceLanguage(String language) {
    return 'Voix $language';
  }

  @override
  String get speechVoiceAutoInfo =>
      'Les autres langues sont lues automatiquement avec une voix masculine';

  @override
  String get listening => 'Écoute...';

  @override
  String get listenPlay => 'Écouter';

  @override
  String get listenReadingPdf => 'Lecture du document...';

  @override
  String get listenConvertWithAi => 'Convertir avec l\'IA';

  @override
  String get listenMakePodcast => 'Podcast complet';

  @override
  String get listenMakePodcastSummary => 'Podcast résumé';

  @override
  String get listenOriginalText => 'Texte original';

  @override
  String get listenPodcastReady => 'La narration du podcast est prête';

  @override
  String get listenPodcastCached => 'Généré précédemment — aucun jeton dépensé';

  @override
  String get listenRegenerate => 'Générer à nouveau';

  @override
  String get listenNoText =>
      'Aucun texte lisible n\'a pu être extrait de ce document. Un PDF numérisé n\'a pas de couche de texte, et une présentation peut ne contenir que des images.';

  @override
  String get readDocument => 'Lire un document (Word, PDF, diapositives)';

  @override
  String get readDocUnsupported => 'Ce type de fichier ne peut pas être lu.';

  @override
  String get exportPdf => 'Exporter en PDF';

  @override
  String get pdfTitleField => 'Titre';

  @override
  String get pdfContentField => 'Contenu';

  @override
  String get pdfMarkupHint =>
      'Les marques en début de ligne deviennent de la mise en forme : [x] et [ ] pour les cases à cocher, 1. pour une liste numérotée, - pour une puce.';

  @override
  String get pdfIncludeDate => 'Inclure la date';

  @override
  String get exportIncludeImages => 'Inclure les images';

  @override
  String get exportWord => 'Partager en Word (.docx)';

  @override
  String get pdfPreview => 'Aperçu';

  @override
  String get largeAttachmentTitle => 'Fichier volumineux';

  @override
  String largeAttachmentBody(String size) {
    return 'Ce fichier fait $size Mo. Les PDF ne peuvent pas être compressés ; il sera envoyé tel quel et comptera dans votre espace de stockage. Continuer ?';
  }

  @override
  String get speechRateForeign => 'Vitesse en langue étrangère';

  @override
  String notesArchivedCount(int count) {
    return '$count notes archivées';
  }

  @override
  String get backgroundColor => 'Couleur de fond';

  @override
  String get backgroundColorInfo => 'La couleur de fond de la note';

  @override
  String get frameColor => 'Cadre';

  @override
  String get frameColorInfo =>
      'Trace un cadre autour de la note dans la couleur choisie';

  @override
  String get sortBy => 'Trier';

  @override
  String get reorderNotes => 'Réorganiser les notes';

  @override
  String get reorderModeActive =>
      'Faites glisser les cartes pour les réorganiser';

  @override
  String get reorderDone => 'Terminé';

  @override
  String get sortManual => 'Manuel (ordre défini)';

  @override
  String get sortUpdated => 'Modifiées récemment';

  @override
  String get sortCreated => 'Date de création';

  @override
  String get sortTitle => 'Par titre (A–Z)';

  @override
  String get foldersSection => 'Dossiers';

  @override
  String get tagsSection => 'Étiquettes';

  @override
  String get expandFilters => 'Déployer les filtres';

  @override
  String get collapseFilters => 'Replier les filtres';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get languageSystem => 'Langue du système';

  @override
  String get settingsSpeech => 'Lecture à voix haute';

  @override
  String get aiAdvanced => 'Avancé : modèle et clé API';

  @override
  String get aiAdvancedInfo =>
      'Choix du modèle et votre propre clé Gemini. La plupart des gens n\'en ont pas besoin.';

  @override
  String get openBriefing => 'Ouvrir le point du jour';

  @override
  String get syncTitle => 'Synchronisation';

  @override
  String get syncLimitTitle => 'Limite d\'envoi automatique';

  @override
  String get syncLimitInfo =>
      'Les pièces jointes plus volumineuses que cette limite restent sur l\'appareil et ne sont pas envoyées. Le texte des notes est toujours synchronisé.';

  @override
  String get syncLimitUnlimited => 'Sans limite';

  @override
  String get backupTitle => 'Sauvegarde';

  @override
  String get importBackup => 'Restaurer depuis une sauvegarde (JSON)';

  @override
  String importBackupDone(int count) {
    return '$count notes restaurées';
  }

  @override
  String get importBackupInvalid => 'Fichier de sauvegarde non valide';

  @override
  String get aiHubTitle => 'IA';

  @override
  String get aiSummarizeInfo => 'Produit un résumé court';

  @override
  String get aiAnalyzeInfo => 'Liste les points clés et les tâches à faire';

  @override
  String get aiImproveInfo => 'Change le ton : formel, plus court ou liste';

  @override
  String get aiTranslateInfo => 'Traduit la note dans la langue choisie';

  @override
  String get aiFixNoteInfo => 'Corrige l\'orthographe et la ponctuation';

  @override
  String get moveToFolder => 'Déplacer vers un dossier';

  @override
  String get voiceAssistantBadge => 'Assistant';

  @override
  String get assistantGenericError =>
      'Une erreur est survenue — pouvez-vous réessayer ?';

  @override
  String get quickAddTooltip => 'Nouvelle note — choisissez un type';

  @override
  String get autoTitleSetting => 'Suggérer un titre à la fermeture';

  @override
  String get autoTitleSettingInfo =>
      'Quand vous quittez l\'éditeur, une note laissée sans titre en reçoit un court, rédigé à partir de son contenu.';

  @override
  String get hubChatInfo => 'Des réponses tirées de vos notes';

  @override
  String get hubBriefingInfo =>
      'Votre journée en un coup d\'œil : rappels et notes récentes';

  @override
  String get hubReadInfo => 'Écoutez un document PDF ou Word';

  @override
  String get annotate => 'Annoter';

  @override
  String get annotateDone => 'Terminer l\'annotation';

  @override
  String get newPdfNote => 'PDF\'ten not';

  @override
  String get imageNotePreparing => 'Assemblage des images en un document…';

  @override
  String get newImageNote => 'Ajouter une image et prendre des notes';

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
  String get pdfAddBlankPage => 'Ajouter une page vierge';

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
  String get crop => 'Rogner';

  @override
  String get cropApply => 'Appliquer le rognage';

  @override
  String get cropReset => 'Réinitialiser la sélection';

  @override
  String get cropHint =>
      'Faites glisser les coins pour choisir une zone. Le rognage est irréversible.';

  @override
  String get cropFailed => 'Impossible de rogner l\'image.';

  @override
  String get penBallpoint => 'Stylo à bille';

  @override
  String get penMarker => 'Marqueur';

  @override
  String get penHighlighter => 'Surligneur';

  @override
  String get eraser => 'Gomme';

  @override
  String get inkArrow => 'Flèche';

  @override
  String get clearInk => 'Effacer les annotations';

  @override
  String get inkTwoFingerHint =>
      'Un doigt dessine · deux doigts déplacent et zooment';

  @override
  String get slideOpenFailed => 'La présentation n\'a pas pu être ouverte';

  @override
  String get newPhotoNote => 'Note photo';

  @override
  String get newScanNote => 'Numériser un document';

  @override
  String get scanDocument => 'Numériser le document';

  @override
  String get scanDocumentSubtitle =>
      'Détecte les bords, redresse la page et l\'ajoute';

  @override
  String get scanUnsupported =>
      'La numérisation de documents n\'est pas prise en charge sur cet appareil';

  @override
  String scanFailed(String error) {
    return 'Impossible de numériser le document : $error';
  }

  @override
  String scanPagesAdded(int count) {
    return '$count page(s) ajoutée(s) à la note';
  }

  @override
  String get scanTextTitle => 'Reconnaître aussi le texte ?';

  @override
  String get scanTextBody =>
      'Le texte des pages est reconnu et écrit dans la note. L\'image reste telle quelle. Cela prend quelques secondes par page.';

  @override
  String get scanImageOnly => 'Image seulement';

  @override
  String get scanRecognizeText => 'Reconnaître le texte';

  @override
  String get scanRecognizing => 'Reconnaissance du texte…';

  @override
  String get takePhoto => 'Prendre une photo';

  @override
  String get qrScanTitle => 'Scanner un code QR';

  @override
  String get qrScanSubtitle =>
      'Lisez-le avec l\'appareil photo ou depuis une photo';

  @override
  String get qrScanHint => 'Alignez le code à l\'intérieur du cadre';

  @override
  String get qrFromPhoto => 'Lire depuis une photo';

  @override
  String get qrNotFound => 'Aucun code trouvé dans cette image';

  @override
  String get qrLinkFound => 'Ce code est un lien';

  @override
  String get qrOpenLink => 'Ouvrir le lien';

  @override
  String get qrSaveToNote => 'Enregistrer dans une note';

  @override
  String get openLink => 'Ouvrir le lien';

  @override
  String get linkOpenFailed => 'Le lien n\'a pas pu être ouvert';

  @override
  String qrScanFailed(String error) {
    return 'Impossible de lire le code : $error';
  }

  @override
  String get qrTorch => 'Lampe';

  @override
  String attachmentsCount(int count) {
    return 'Pièces jointes ($count)';
  }

  @override
  String get hideAttachments => 'Masquer';

  @override
  String get showAttachments => 'Afficher';

  @override
  String get videoBack10 => 'Reculer de 10 s';

  @override
  String get videoForward10 => 'Avancer de 10 s';

  @override
  String get selectAllItems => 'Tout sélectionner';

  @override
  String get showAllChips => 'Tout afficher';

  @override
  String get hideAllChips => 'Tout masquer';

  @override
  String get chipPickInfo =>
      'Quelles puces de dossier et d\'étiquette afficher sur l\'écran d\'accueil ?';

  @override
  String get hiddenFolder => 'Dossier masqué';

  @override
  String get hiddenFolderInfo =>
      'Un dossier masqué et les notes qu\'il contient n\'apparaissent pas sur l\'écran d\'accueil. Pour les afficher, choisissez « Dossiers masqués » dans le menu ⋮ et confirmez votre identité.';

  @override
  String get hiddenFoldersMenu => 'Dossiers masqués';

  @override
  String get hiddenFolderAuthReason =>
      'Confirmez votre identité pour afficher les dossiers masqués';

  @override
  String get hiddenFoldersShown => 'Les dossiers masqués sont affichés';

  @override
  String get hiddenFoldersHiddenAgain =>
      'Les dossiers masqués sont de nouveau cachés';

  @override
  String get makeFolderHidden => 'Masquer';

  @override
  String get makeFolderVisible => 'Afficher';

  @override
  String gridColumnsCount(int count) {
    return '$count colonnes';
  }

  @override
  String get addImageOnPageSubtitle =>
      'Placée dans la page, le texte s\'écoule autour';

  @override
  String get addImageAsFile => 'Ajouter l\'image en fichier';

  @override
  String get addImageAsFileSubtitle =>
      'Reste hors de la page, dans la bande des pièces jointes';

  @override
  String get moveImageToAttachments => 'Déplacer vers les pièces jointes';

  @override
  String get moveImageToPage => 'Placer dans la page';

  @override
  String get attachmentCopied => 'Pièce jointe copiée';

  @override
  String get pasteAttachment => 'Coller la pièce jointe copiée';

  @override
  String get fullscreen => 'Plein écran';

  @override
  String get more => 'Plus';

  @override
  String get undone => 'Annulé';

  @override
  String get filterOthers => 'Autres';

  @override
  String get chatSuggestion1 => 'Que manque-t-il sur ma liste de courses ?';

  @override
  String get chatSuggestion2 => 'Résume mes notes de travail de la semaine';

  @override
  String get chatSuggestion3 => 'Ai-je un rappel pour demain ?';

  @override
  String get aiPointsToday => 'Points du jour';

  @override
  String aiPointsOf(int used, int total) {
    return '$used / $total';
  }

  @override
  String get aiPointsRenew => 'renouvellement à minuit';

  @override
  String get aiChatWithNotes => 'Assistant de notes';

  @override
  String get aiChatInputHint => 'Posez une question sur vos notes…';

  @override
  String get aiChatLooking => 'parcours de vos notes…';

  @override
  String get aiChatFullScreen => 'Plein écran';

  @override
  String get aiOnYourNotes => 'SUR VOS NOTES';

  @override
  String get aiTaskDuplicates => 'Nettoyer les doublons';

  @override
  String aiTaskDuplicatesInfo(int count) {
    return '$count notes en double';
  }

  @override
  String get duplicatesTitle => 'Notes en double';

  @override
  String get duplicatesHint =>
      'La note la plus ancienne de chaque groupe est conservée, les autres vont à la corbeille.';

  @override
  String get duplicatesKeepBadge => 'conservée';

  @override
  String get duplicatesDeleteAll => 'Mettre les doublons à la corbeille';

  @override
  String duplicatesDone(int count) {
    return '$count doublons mis à la corbeille';
  }

  @override
  String get aiRecentActions => 'ACTIONS RÉCENTES';

  @override
  String get aiHistoryClear => 'Effacer';

  @override
  String get aiHistoryQuestion => 'Question';

  @override
  String get aiHistoryNoteAction => 'Action sur la note';

  @override
  String get aiHistoryVoiceNote => 'Note vocale';

  @override
  String get aiRecentOps => 'RÉCENT';

  @override
  String get aiTaskWeekSummary => 'Résumer la semaine';

  @override
  String get aiTaskWeekSummaryInfo => 'Un résumé des 7 derniers jours';

  @override
  String get aiTaskTagUntagged => 'Étiqueter les notes';

  @override
  String aiTaskTagUntaggedInfo(int count) {
    return '$count notes en attente d\'étiquettes';
  }

  @override
  String get aiTaskSuggestTitles => 'Suggérer des titres';

  @override
  String aiTaskSuggestTitlesInfo(int count) {
    return '$count notes sans titre';
  }

  @override
  String get sectionPinnedShort => 'ÉPINGLÉES';

  @override
  String get sectionToday => 'AUJOURD\'HUI';

  @override
  String get sectionThisWeek => 'CETTE SEMAINE';

  @override
  String get sectionEarlier => 'PLUS TÔT';

  @override
  String sectionNoteCount(int count) {
    return '$count notes';
  }

  @override
  String get emptySearchSemanticHint => 'Essayez l\'onglet Sens';

  @override
  String get quickCaptureHint => 'Nouvelle note…';

  @override
  String get quickCaptureSave => 'Enregistrer';

  @override
  String get quickAddWrite => 'ÉCRIRE';

  @override
  String get quickAddCapture => 'CAPTURER — CRÉE UNE NOTE À PARTIR DU CONTENU';

  @override
  String get viewToggle => 'Affichage';

  @override
  String get searchModeText => 'Texte';

  @override
  String get searchModeMeaning => 'Sens';

  @override
  String get filterReminded => 'Avec rappel';

  @override
  String get filterLocked => 'Verrouillé';

  @override
  String get sortColor => 'Couleur';

  @override
  String get sortActive => 'Les plus travaillées';

  @override
  String get voicePreview => 'Tester la voix';

  @override
  String get voicePreviewCached =>
      'L’échantillon est généré une fois, puis lu depuis le stockage';

  @override
  String get reorderHint =>
      'Maintenez une carte et faites-la glisser où vous voulez';

  @override
  String get filterSheetTitle => 'Filtrer';

  @override
  String get filterReset => 'Réinitialiser';

  @override
  String get filterSectionStatus => 'STATUT';

  @override
  String get filterSectionFolder => 'DOSSIER';

  @override
  String get filterSectionTag => 'ÉTIQUETTE';

  @override
  String get filterSectionSort => 'TRI';

  @override
  String get filterFavoriteHint =>
      'Touche une étoile pour garder l\'option sur l\'écran d\'accueil';

  @override
  String get filterSheetSortHint =>
      'Les groupes de dates (AUJOURD\'HUI, CETTE SEMAINE...) ne s\'affichent que lors d\'un tri par dernière modification.';

  @override
  String get formatTitle => 'Mise en forme';

  @override
  String get formatBold => 'Gras';

  @override
  String get formatItalic => 'Italique';

  @override
  String get formatUnderline => 'Souligné';

  @override
  String get formatTextColor => 'Couleur du texte';

  @override
  String get formatHighlight => 'Surlignage';

  @override
  String get formatInfo =>
      'La mise en forme voyage dans le texte sous forme de marques (comme **gras**) ; les marques restent masquées dans les exports et la lecture à voix haute.';

  @override
  String get formatMenu => 'Mise en forme…';

  @override
  String get noteFont => 'Police';

  @override
  String get noteFontDefault => 'Par défaut';

  @override
  String get noteFontSerif => 'Livre (serif)';

  @override
  String get noteFontMono => 'Machine à écrire';

  @override
  String get noteTextSize => 'Taille du texte';

  @override
  String get formatClear => 'Effacer la mise en forme';

  @override
  String get formatHeading => 'Başlık';

  @override
  String get formatHeading1 => 'Büyük başlık';

  @override
  String get formatHeading2 => 'Alt başlık';

  @override
  String get formatNormalText => 'Normal metin';

  @override
  String get noteTextOpacity => 'Opacité';

  @override
  String get assistantVoiceSetting => 'L\'assistant lit ses réponses';

  @override
  String get assistantVoiceSettingInfo =>
      'L\'assistant vocal lit sa réponse à voix haute (téléphone uniquement).';

  @override
  String get assistantMute => 'Couper le son';

  @override
  String get assistantUnmute => 'Réactiver le son';

  @override
  String get assistantMakeNote => 'En faire quand même une note';

  @override
  String get assistantNoteCreated => 'Note créée';

  @override
  String get noteNotFound =>
      'Note introuvable. Elle a peut-être été supprimée.';

  @override
  String get back => 'Retour';

  @override
  String get addTextBlock => 'Ajouter du texte';

  @override
  String get attachNoteContent => 'Not içeriği';

  @override
  String get noteBackgroundImage => 'Image de fond';

  @override
  String get chooseBackgroundImage => 'Choisir une image';

  @override
  String get changeBackgroundImage => 'Changer d\'image';

  @override
  String get removeBackgroundImage => 'Supprimer le fond';

  @override
  String get dashboardBackground => 'Fond de l\'écran d\'accueil';

  @override
  String get dashboardBackgroundInfo =>
      'Image affichée derrière la grille de notes (cet appareil uniquement).';

  @override
  String get aiProvider => 'Fournisseur d\'IA';

  @override
  String get aiProviderInfo =>
      'Choisissez le fournisseur auquel appartient votre clé. La clé de chaque fournisseur est conservée séparément : revenir en arrière ne demande pas de la ressaisir.';

  @override
  String get apiKeyFieldLabel => 'Clé API';

  @override
  String get getApiKey => 'Où obtenir une clé ?';

  @override
  String get recommendedModel => 'Recommandé';

  @override
  String get freeTierBadge => 'Offre gratuite disponible';

  @override
  String get continueWithoutAccount => 'Continuer sans compte';

  @override
  String get localAccountInfo =>
      'Vos notes restent uniquement sur cet appareil : elles ne peuvent pas être ouvertes ailleurs, elles disparaissent si vous désinstallez l\'application, et l\'IA intégrée est désactivée. Vous pouvez associer un compte Google à tout moment — vos notes seront conservées.';

  @override
  String get localAccountBadge => 'Compte local';

  @override
  String get linkGoogleAccount => 'Associer un compte Google';

  @override
  String get accountLinked =>
      'Votre compte Google est associé. Vos notes sont désormais sauvegardées.';

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
      'La connexion sans Google est désactivée : la connexion anonyme n\'est pas activée dans la console Firebase. Connecte-toi avec Google ou réessaie une fois qu\'un administrateur l\'aura activée.';

  @override
  String get googleSignInUnavailable =>
      'La connexion Google est désactivée : le fournisseur Google n\'est pas activé dans la console Firebase.';

  @override
  String get signInNetworkError =>
      'Internet est injoignable. Vérifie ta connexion et réessaie.';

  @override
  String get signInCanceled => 'Connexion annulée.';

  @override
  String get cardRichPreview => 'Texte mis en forme sur les cartes';

  @override
  String get cardRichPreviewInfo =>
      'Les couleurs, surlignages, gras et soulignements de tes notes apparaissent aussi sur les cartes de l\'écran d\'accueil. Désactivé, les cartes affichent du texte brut.';

  @override
  String get fontSizeSmall => 'Petit';

  @override
  String get fontSizeMedium => 'Moyen';

  @override
  String get fontSizeLarge => 'Grand';

  @override
  String get fontSizeXLarge => 'Très grand';

  @override
  String get appFontSetting => 'Police';

  @override
  String get appFontInfo =>
      'La police utilisée partout dans l\'application. La police propre à une note a la priorité. Toutes les polices sont incluses — aucune connexion requise.';

  @override
  String get fontGroupSans => 'Sans empattement';

  @override
  String get fontGroupSerif => 'Serif';

  @override
  String get fontGroupMono => 'Monospace';

  @override
  String get fontGroupHand => 'Manuscrite';

  @override
  String get appFontDefaultSuffix => 'par défaut';

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
      'La voix IA nécessite votre propre clé Gemini. En attendant, la lecture utilise la voix de l\'appareil.';

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
  String get shareAsText => 'En texte brut';

  @override
  String get shareAsTextInfo =>
      'Envoie le texte de la note et les notes de page vers n\'importe quelle application.';

  @override
  String get shareAsTextEmpty => 'Cette note n\'a aucun texte à partager.';

  @override
  String get sharePdfWithBubbles => 'En PDF avec bulles';

  @override
  String get sharePdfWithBubblesInfo =>
      'Les bulles, surlignages et dessins sont imprimés dans le PDF ; tout le monde peut l\'ouvrir, et dans Not il s\'ouvre modifiable.';

  @override
  String get sharePdfWithBubblesNone =>
      'Cette note ne contient aucun PDF avec bulles ou dessins.';

  @override
  String get sharePdfWithBubblesPreparing => 'Préparation du PDF avec bulles…';

  @override
  String get sharePdfWithBubblesSuffix => ' (avec bulles)';

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
  String get formatRemove => 'Supprimer';

  @override
  String get exportTitle => 'Exporter';

  @override
  String get exportNotesOption => 'Texte de la note (PDF / Word)';

  @override
  String get exportNotesOptionInfo =>
      'Texte et images de la note ; bulles non incluses.';

  @override
  String get captureNoteTitle => 'Titre de la note (facultatif)';

  @override
  String get captureNoteTitleHint => 'Le nouveau document portera ce nom';

  @override
  String get imageOcrTitle => 'Reconnaître le texte de l’image';

  @override
  String get imageOcrNone => 'Aucun texte trouvé dans cette image.';

  @override
  String imageOcrHint(int count) {
    return '$count lignes reconnues · appuyez pour sélectionner';
  }

  @override
  String imageOcrSelected(int count) {
    return '$count lignes sélectionnées';
  }

  @override
  String get imageOcrShort => 'Reconnaître';

  @override
  String get imageOcrWorking => 'Reconnaissance du texte…';

  @override
  String get imageOcrSelectHint =>
      'Toucher : mot · Maintenir et glisser : lettre par lettre';

  @override
  String get imageOcrInsert => 'Ajouter à la note';

  @override
  String get imageOcrZoomIn => 'Zoom avant';

  @override
  String get imageOcrZoomOut => 'Zoom arrière';

  @override
  String get selectImages => 'Sélectionner des images';

  @override
  String get exportImages => 'Images';

  @override
  String get exportImagesInfo =>
      'Le texte s’écoule à côté des images étroites alignées à gauche ou à droite ; les images centrées occupent toute la largeur.';

  @override
  String get exportAlignLeft => 'Gauche';

  @override
  String get exportAlignCenter => 'Centre';

  @override
  String get exportAlignRight => 'Droite';

  @override
  String get exportImageWidth => 'Largeur';

  @override
  String get exportImageLine => 'Position';

  @override
  String get aiModelSearch => 'Rechercher un modèle';

  @override
  String get aiModelOthers => 'AUTRES MODÈLES';

  @override
  String get aiModelNoMatch => 'Aucun modèle correspondant.';

  @override
  String get aiModelAutoInfo =>
      'L’application essaie les modèles les plus adaptés dans l’ordre.';

  @override
  String imageOcrCharsSelected(int count) {
    return '$count caractères sélectionnés';
  }

  @override
  String imagesSelectedCount(int count) {
    return '$count images sélectionnées';
  }

  @override
  String attachmentsCopiedCount(int count) {
    return '$count pièces jointes';
  }

  @override
  String exportImageLineOf(int count) {
    return '/ $count lignes';
  }

  @override
  String get aiModelShowAll => 'Tout afficher';

  @override
  String get aiModelShowAllInfo =>
      'Affiche aussi les modèles que l’application n’utilise pas.';

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
  String get collaborators => 'Collaborateurs';

  @override
  String get collaboratorsInfo =>
      'Les personnes ajoutées voient cette note sur leur écran d\'accueil et la modifient avec vous en temps réel.';

  @override
  String get collaboratorsOwner => 'Propriétaire';

  @override
  String get collaboratorsFriendsTitle => 'VOS AMIS';

  @override
  String get collaboratorsLeave => 'Quitter la note partagée';

  @override
  String get collaboratorsLeaveConfirm =>
      'Cette note n\'apparaîtra plus sur votre écran d\'accueil. Quitter ?';

  @override
  String get collaboratorsSaved => 'Partage mis à jour';

  @override
  String collaboratorsCount(int count) {
    return 'Partagée avec $count personnes';
  }

  @override
  String get collaboratorsOnlyOwner =>
      'Seul le propriétaire de la note peut modifier les collaborateurs.';

  @override
  String get sharedWithMe => 'Partagées avec moi';

  @override
  String get sharedWithMeEmpty =>
      'Aucune note partagée avec vous pour l\'instant. Elles apparaissent ici quand quelqu\'un vous ajoute à une note.';

  @override
  String sharedByName(Object name) {
    return 'Partagée par $name';
  }

  @override
  String get navNotes => 'Notes';

  @override
  String get railExpand => 'Déplier le menu';

  @override
  String get railCollapse => 'Replier le menu';

  @override
  String get newNoteShort => 'Nouvelle note';

  @override
  String get newChecklistShort => 'Nouvelle liste';

  @override
  String get listPaneHide => 'Masquer la liste des notes';

  @override
  String get listPaneShow => 'Afficher la liste des notes';

  @override
  String get keyboardShortcuts => 'Raccourcis clavier';

  @override
  String get shortcutSearch => 'Rechercher des notes';

  @override
  String get shortcutToggleList => 'Masquer / afficher la liste des notes';

  @override
  String get shortcutSections => 'Passer d\'une section à l\'autre';

  @override
  String get shortcutHelp => 'Afficher les raccourcis';

  @override
  String get noNoteSelectedHint => 'ou commencez une nouvelle note';

  @override
  String get loginFeatureSyncTitle => 'Les mêmes notes partout';

  @override
  String get loginFeatureSyncBody =>
      'Synchronisation instantanée entre téléphone, tablette, ordinateur et web.';

  @override
  String get loginFeatureAiTitle => 'L\'IA à vos côtés';

  @override
  String get loginFeatureAiBody =>
      'Résumez, demandez, dictez ; discutez avec vos documents.';

  @override
  String get loginFeatureShareTitle => 'Écrire ensemble';

  @override
  String get loginFeatureShareBody =>
      'Partagez notes et dossiers en direct avec vos amis.';

  @override
  String get loginFeatureInkTitle => 'Stylet et PDF';

  @override
  String get loginFeatureInkBody =>
      'Prenez des notes manuscrites, écrivez sur les PDF et diapositives.';

  @override
  String get foldersTitle => 'Dossiers';

  @override
  String get foldersEmpty =>
      'Aucun dossier pour l\'instant. Créez-en un pour organiser vos notes.';

  @override
  String get folderColor => 'Couleur';

  @override
  String get folderColorAuto => 'Automatique';

  @override
  String get foldersMine => 'Mes dossiers';

  @override
  String get foldersSharedSection => 'Dossiers partagés avec moi';

  @override
  String trashDaysShort(int count) {
    return '$count j';
  }

  @override
  String get trashTodayShort => 'Aujourd\'hui';

  @override
  String get trashSoonSection => 'Bientôt supprimées définitivement';

  @override
  String get trashRestSection => 'Autres notes supprimées';

  @override
  String get aiHubTagline => 'Interrogez, résumez et rangez vos notes.';

  @override
  String get aiToolsSection => 'Outils';

  @override
  String get folderOrderTitle => 'Ordre des dossiers';

  @override
  String get folderReorder => 'Réorganiser les dossiers';

  @override
  String get folderOrderManual => 'Personnalisé';

  @override
  String get folderOrderName => 'Par nom';

  @override
  String get folderOrderNewest => 'Plus récents d’abord';

  @override
  String get folderOrderNoteCount => 'Par nombre de notes';

  @override
  String get folderOrderHint =>
      'Faites glisser les poignées pour réorganiser. Le même ordre est utilisé dans la barre de dossiers et en balayant.';

  @override
  String get swipeModeTitle => 'Balayage sur l’écran d’accueil';

  @override
  String get swipeModeFolders => 'Passer d’un dossier à l’autre';

  @override
  String get swipeModeFilters => 'Passer entre filtres et étiquettes';

  @override
  String get swipeModeBoth => 'Dossiers, filtres et étiquettes';

  @override
  String get swipeModeOff => 'Désactivé';

  @override
  String get shareIncludeTitle => 'Titre';

  @override
  String get shareIncludeChecked => 'Éléments terminés';

  @override
  String get shareIncludeTags => 'Étiquettes';

  @override
  String get shareTextAction => 'Partager le texte';

  @override
  String get shareAsFileSection => 'En tant que fichier';

  @override
  String get shareInAppSection => 'Dans l’application';

  @override
  String get shareSendFriendInfo =>
      'Dépose une copie de la note dans la boîte de réception d’un ami.';

  @override
  String get shareCollaborateInfo =>
      'Modifiez la même note avec des amis ; les changements apparaissent aussitôt.';

  @override
  String get findPrevious => 'Résultat précédent';

  @override
  String get findNext => 'Résultat suivant';

  @override
  String get findShowAll => 'Tous les résultats';

  @override
  String findMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count résultats',
      one: '1 résultat',
      zero: 'Aucun résultat',
    );
    return '$_temp0';
  }

  @override
  String get findDeepSearch => 'Chercher dans les pièces jointes et avec l’IA';

  @override
  String get notesSettingsTitle => 'Notes et dossiers';

  @override
  String get noteViewSetting => 'Affichage de l’écran d’accueil';

  @override
  String get noteViewGrid => 'Grille';

  @override
  String get noteViewList => 'Liste';

  @override
  String get gridColumnsSetting => 'Colonnes';

  @override
  String get gridColumnsInfo =>
      'Vous pouvez aussi pincer l’écran d’accueil pour le changer.';

  @override
  String get gridColumnsAuto => 'Auto';

  @override
  String get folderShelfSetting => 'Dossiers sur l’écran d’accueil';

  @override
  String get folderShelfStrip => 'Une ligne';

  @override
  String get folderShelfTiles => 'Tuiles';

  @override
  String get deviceStorageTitle => 'Sur cet appareil';

  @override
  String get deviceStorageAttachments => 'Pièces jointes';

  @override
  String get deviceStorageDatabase => 'Copie locale des notes';

  @override
  String get deviceStorageCache => 'Cache et fichiers temporaires';

  @override
  String get deviceStorageAi => 'Cache IA';

  @override
  String get deviceStorageTotal => 'Total (hors application)';

  @override
  String get deviceStorageInfo =>
      'Vider le cache ne supprime ni notes ni pièces jointes ; les images sont retéléchargées au besoin. Les anciens fichiers temporaires sont nettoyés à chaque lancement.';

  @override
  String get deviceStorageClear => 'Vider le cache';

  @override
  String deviceStorageCleared(String size) {
    return '$size libérés';
  }

  @override
  String get deviceStorageUnavailable =>
      'Impossible à mesurer sur cet appareil.';

  @override
  String get localOnlyTurnOn => 'Arrêter la synchro';

  @override
  String get localOnlyTurnOff => 'Synchroniser cette note';

  @override
  String get localOnlyBadge => 'Uniquement sur cet appareil';

  @override
  String get localOnlyConfirmTitle =>
      'Garder cette note uniquement sur cet appareil ?';

  @override
  String get localOnlyConfirmBody =>
      'La note et ses pièces jointes sont retirées du cloud et n’apparaîtront pas sur vos autres appareils. Si vous désinstallez l’app ou changez de téléphone, cette note disparaît aussi. Vous pouvez réactiver la synchro à tout moment.';

  @override
  String get localOnlyConfirm => 'Arrêter la synchro';

  @override
  String get localOnlyOnDone =>
      'La note est désormais uniquement sur cet appareil';

  @override
  String get localOnlyOffDone => 'La note se synchronise à nouveau';

  @override
  String get localOnlySharedBlocked =>
      'Impossible de désactiver la synchro d’une note partagée';

  @override
  String get localOnlyDownloadFailed =>
      'Certaines pièces jointes n’ont pas pu être téléchargées. Vérifiez la connexion et réessayez ; la note n’a pas changé.';

  @override
  String get templatesTitle => 'Modèles';

  @override
  String get templatesSubtitle =>
      'Commencez avec une mise en page prête ; tout reste modifiable.';

  @override
  String get fromTemplate => 'Depuis un modèle';

  @override
  String get tplShoppingName => 'Liste de courses';

  @override
  String get tplShoppingItems => 'Pain, Lait, Œufs, Fruits, Légumes';

  @override
  String get tplShoppingDesc => 'Cochez vos achats ; ils descendent';

  @override
  String get tplTodoDesc => 'Liste vide datée d’aujourd’hui';

  @override
  String get tplTravelName => 'Liste de bagages';

  @override
  String get tplTravelItems =>
      'Pièce d’identité / passeport, Chargeur, Médicaments, Brosse à dents, Vêtements, Écouteurs';

  @override
  String get tplTravelDesc => 'Liste de contrôle prête';

  @override
  String get tplMeetingDesc => 'Participants, ordre du jour, décisions';

  @override
  String get tplJournalDesc => 'Ma journée, gratitude, demain';

  @override
  String get tplRecipeName => 'Recette';

  @override
  String get tplRecipeMeta => 'Portions : · Temps :';

  @override
  String get tplRecipeIngredients => 'Ingrédients';

  @override
  String get tplRecipeSteps => 'Préparation';

  @override
  String get tplRecipeNotes => 'Notes';

  @override
  String get tplRecipeDesc => 'Ingrédients et étapes';

  @override
  String get tplWeeklyName => 'Plan de la semaine';

  @override
  String get tplWeeklyDesc => 'Les jours de la semaine en titres';

  @override
  String get tplExpenseDesc => 'Date, description, montant';

  @override
  String get tplReadingDesc => 'Source, résumé, citations';

  @override
  String get settingsThemeHeader => 'Thème';

  @override
  String get settingsCardsHeader => 'Cartes et listes';

  @override
  String get shareTargetTitle => 'Ajouter à Notes';

  @override
  String get shareTargetNew => 'Nouvelle note';

  @override
  String get shareTargetExisting => 'Note existante';

  @override
  String get shareTargetCreate => 'Créer la note';

  @override
  String get shareTargetSearch => 'Rechercher des notes';

  @override
  String get shareTargetNoNotes => 'Aucune note disponible';

  @override
  String get shareTargetNoMatch => 'Aucune note correspondante';

  @override
  String shareTargetMore(int count) {
    return '+$count fichiers';
  }

  @override
  String get sharePreviewExpand => 'Agrandir l\'aperçu';

  @override
  String get sharePreviewCollapse => 'Réduire l\'aperçu';

  @override
  String get templatesSearch => 'Rechercher un modèle';

  @override
  String get templatesAll => 'Tous';

  @override
  String get templatesLists => 'Listes';

  @override
  String get templatesPlanning => 'Planification';

  @override
  String get templatesWriting => 'Écriture';

  @override
  String get templatesMine => 'Mes modèles';

  @override
  String get templatesRecent => 'Utilisés récemment';

  @override
  String get templatesNoMatch => 'Aucun modèle correspondant';

  @override
  String get templatesMineEmpty =>
      'Vous n\'avez pas encore de modèle. Choisissez « Enregistrer comme modèle » dans le menu d\'une note pour le retrouver ici.';

  @override
  String get templatesMineInfo => 'Votre modèle';

  @override
  String get templateRename => 'Renommer';

  @override
  String get templateDelete => 'Supprimer le modèle';

  @override
  String get templateNameTitle => 'Nom du modèle';

  @override
  String get templateNameHint => 'ex. Courses de la semaine';

  @override
  String get templateSave => 'Enregistrer';

  @override
  String templateSaved(String name) {
    return '« $name » ajouté à vos modèles';
  }

  @override
  String get saveAsTemplate => 'Enregistrer comme modèle';

  @override
  String get templateCreate => 'Créer';

  @override
  String templateCreateWithCount(int count) {
    return 'Créer · $count éléments';
  }

  @override
  String get templateListChecks => 'Cases à cocher';

  @override
  String get templateListNumbers => 'Numérotée';

  @override
  String get templateItems => 'Éléments';

  @override
  String get templateAddItem => 'Ajouter un élément';

  @override
  String get templateSuggestionsInfo =>
      'Touchez une suggestion pour l\'ajouter ; touchez à nouveau pour la retirer.';

  @override
  String get tplShopProduce => 'Fruits et légumes';

  @override
  String get tplShopProduceItems =>
      'Tomates, Concombres, Oignons, Pommes de terre, Citrons, Bananes, Pommes, Persil';

  @override
  String get tplShopBreakfast => 'Petit-déjeuner';

  @override
  String get tplShopBreakfastItems =>
      'Fromage, Olives, Beurre, Miel, Confiture, Yaourt';

  @override
  String get tplShopPantry => 'Épicerie';

  @override
  String get tplShopPantryItems =>
      'Riz, Pâtes, Farine, Sucre, Huile d\'olive, Lentilles, Thé, Café';

  @override
  String get tplShopCleaning => 'Entretien';

  @override
  String get tplShopCleaningItems =>
      'Liquide vaisselle, Lessive, Papier toilette, Essuie-tout, Sacs poubelle';

  @override
  String get tplShopPersonal => 'Hygiène';

  @override
  String get tplShopPersonalItems => 'Shampooing, Dentifrice, Savon, Déodorant';

  @override
  String get tplTravelDocs => 'Documents';

  @override
  String get tplTravelDocsItems =>
      'Billets, Réservation d\'hôtel, Permis de conduire, Assurance voyage, Espèces / cartes';

  @override
  String get tplTravelClothes => 'Vêtements';

  @override
  String get tplTravelClothesItems =>
      'T-shirts, Pantalons, Sous-vêtements, Chaussettes, Pyjama, Veste, Chaussures';

  @override
  String get tplTravelCare => 'Toilette';

  @override
  String get tplTravelCareItems =>
      'Dentifrice, Shampooing, Crème solaire, Rasoir, Déodorant';

  @override
  String get tplTravelTech => 'Électronique';

  @override
  String get tplTravelTechItems =>
      'Batterie externe, Adaptateur de prise, Écouteurs, Câbles';

  @override
  String get tplHabitsName => 'Suivi des habitudes';

  @override
  String get tplHabitsDesc => 'Cochez chaque jour, ne brisez pas la chaîne';

  @override
  String get tplHabitsItems =>
      '8 verres d\'eau, 30 minutes de marche, Lire 20 pages, Se coucher tôt, Une heure sans écran';

  @override
  String get tplCleaningName => 'Ménage';

  @override
  String get tplCleaningDesc => 'Liste de ménage hebdomadaire';

  @override
  String get tplCleaningItems =>
      'Dépoussiérer, Aspirer, Passer la serpillière, Nettoyer la salle de bain, Plan de travail, Lessive, Sortir les poubelles, Changer les draps';

  @override
  String get tplMovingName => 'Liste de déménagement';

  @override
  String get tplMovingDesc => 'À faire avant et après le déménagement';

  @override
  String get tplMovingItems =>
      'Réserver les déménageurs, Acheter cartons et scotch, Changer d\'adresse, Électricité / eau / gaz, Transférer internet, Remise des clés';

  @override
  String get tplGiftsName => 'Liste de cadeaux';

  @override
  String get tplGiftsDesc => 'Qui reçoit quoi, idées';

  @override
  String get tplGiftsItems => 'Maman, Papa, Frère ou sœur, Ami';

  @override
  String get tplWatchlistName => 'À voir';

  @override
  String get tplWatchlistDesc => 'Films, séries et livres';

  @override
  String get tplWorkoutName => 'Entraînement';

  @override
  String get tplWorkoutDesc => 'De l\'échauffement aux étirements';

  @override
  String get tplWorkoutItems =>
      'Échauffement 5 min, Squats 3×12, Pompes 3×10, Abdos 3×15, Gainage 3×45 s, Étirements 5 min';

  @override
  String get tplGoalsName => 'Objectifs';

  @override
  String get tplGoalsDesc => 'Objectifs de l\'année, du mois et de la semaine';

  @override
  String get tplGoalsYear => 'Cette année';

  @override
  String get tplGoalsMonth => 'Ce mois-ci';

  @override
  String get tplGoalsWeek => 'Cette semaine';

  @override
  String get tplGoalsWhy => 'Pourquoi c\'est important ?';

  @override
  String get templateNew => 'Nouveau modèle';

  @override
  String get templateEdit => 'Modifier le modèle';

  @override
  String get templateDuplicate => 'Dupliquer';

  @override
  String get templateSaveAsMine => 'Enregistrer dans mes modèles';

  @override
  String get templateUntitled => 'Modèle sans titre';

  @override
  String get templateTypeText => 'Texte';

  @override
  String get templateTitleHelp =>
      'Titre des notes créées avec ce modèle (facultatif)';

  @override
  String get templateBody => 'Texte';

  @override
  String get templateHeadingHelp =>
      'Les lignes commençant par « # » deviennent des titres, par « ## » des sous-titres.';

  @override
  String get templateDiscardTitle => 'Abandonner les modifications ?';

  @override
  String get templateDiscard => 'Abandonner';

  @override
  String templateDeleted(String name) {
    return '« $name » supprimé';
  }

  @override
  String get addVideoFromGallery => 'Vidéo de la galerie';

  @override
  String get addYouTubeVideo => 'Vidéo YouTube';

  @override
  String get addYouTubeVideoSubtitle =>
      'Se lit dans la note, à regarder dans une petite fenêtre';

  @override
  String get youTubeLinkHelp =>
      'Collez un lien de vidéo YouTube (youtube.com ou youtu.be).';

  @override
  String get youTubeInvalidLink => 'Ce n\'est pas un lien de vidéo YouTube';

  @override
  String get youTubeOpenInBrowserInfo =>
      'La vidéo ne peut pas être lue dans l\'app sur cet appareil ; elle peut être ouverte dans le navigateur.';

  @override
  String get youTubeOpenExternal => 'Ouvrir dans YouTube';

  @override
  String get pictureInPicture => 'Image dans l\'image';

  @override
  String get pinMediaTop => 'Épingler en haut';

  @override
  String get pinMediaRelease => 'Relâchez : épingler en haut (note en dessous)';

  @override
  String get unpinMedia => 'Remettre sur la page';

  @override
  String get unpinMediaRelease => 'Relâchez : remettre sur la page';

  @override
  String get pinnedMediaResize =>
      'Hauteur du volet — faites glisser pour la modifier';

  @override
  String get addPageSubtitle => 'Ajoute une nouvelle page vierge à la note';

  @override
  String pageOf(int current, int total) {
    return 'Page $current / $total';
  }

  @override
  String pageAdded(int page) {
    return 'Page $page ajoutée';
  }

  @override
  String get deletePageConfirm =>
      'Supprimer le texte de cette page ? Ses images passent sur la page voisine. Annuler permet de le récupérer.';

  @override
  String get embedNewPdf => 'PDF';

  @override
  String get embedNewImage => 'Image';

  @override
  String get embedNewVideo => 'Vidéo';

  @override
  String get embedNewYouTube => 'YouTube';

  @override
  String get embedPickTitle => 'Que intégrer ?';

  @override
  String embedPickTitleFor(String label) {
    return 'Intégrer dans « $label »';
  }

  @override
  String get embedPickInfo =>
      'Touchez le texte pour ouvrir l\'élément intégré sur place.';

  @override
  String get embedSectionNew => 'Ajouter';

  @override
  String get embedSectionExisting => 'Pièces jointes de cette note';

  @override
  String get embedReplace => 'Remplacer';

  @override
  String get embedRemove => 'Retirer l\'intégration';

  @override
  String get embedRemoved => 'Intégration retirée';

  @override
  String get guideTitle => 'Guide d\'utilisation';

  @override
  String get guideMenuInfo => 'Toutes les fonctions, pas à pas';

  @override
  String get guideSearchHint =>
      'Chercher dans le guide — « page », « YouTube »';

  @override
  String get guideContents => 'Sommaire';

  @override
  String get guideOpenScreen => 'Ouvrir l\'écran';

  @override
  String guideNoResults(String query) {
    return 'Aucun résultat pour « $query »';
  }

  @override
  String get copyVideoLink => 'Copier le lien';

  @override
  String get videoLinkCopied => 'Lien copié';

  @override
  String get attachSectionVisual => 'Images et dessin';

  @override
  String get menuSectionOrganize => 'Organiser';

  @override
  String get menuSectionCopy => 'Copier et exporter';

  @override
  String get menuSectionTools => 'Outils';

  @override
  String get menuSectionProtect => 'Protection et stockage';

  @override
  String get menuSectionContent => 'Contenu';

  @override
  String get menuSectionPeople => 'Compte et contacts';

  @override
  String get menuSectionHome => 'Écran d\'accueil';

  @override
  String get menuSectionApp => 'Application';

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
