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
  String get attachmentUploading => 'Envoi en cours...';

  @override
  String get attachmentNotSynced =>
      'Ce fichier n\'est pas encore synchronisé sur cet appareil';

  @override
  String attachmentTooLarge(int limit) {
    return 'Fichier trop volumineux ($limit Mo maximum)';
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
  String get chatTitle => 'Discuter avec vos notes';

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
  String get aiModelDocument => 'Podcasts et discussion sur documents';

  @override
  String get aiModelTranslate => 'Traduction';

  @override
  String get aiModelVoice => 'Notes vocales';

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
  String get aiChatWithNotes => 'Discuter avec vos notes';

  @override
  String get aiChatInputHint => 'Posez une question sur vos notes…';

  @override
  String get aiChatLooking => 'parcours de vos notes…';

  @override
  String get aiChatFullScreen => 'Plein écran';

  @override
  String get aiOnYourNotes => 'SUR VOS NOTES';

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
}
