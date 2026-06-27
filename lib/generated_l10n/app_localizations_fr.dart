// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Medical Booking';

  @override
  String get failedToLoadUserData => 'Échec de chargement des données';

  @override
  String get invalidUserRole => 'Compte non valide, veuillez vous reconnecter';

  @override
  String get scheduleSettings => 'Paramètres d\'horaire';

  @override
  String get slotDurationTitle => 'Durée de consultation';

  @override
  String get slotDurationNotSet => 'Durée non définie';

  @override
  String minutesLabel(Object minutes) {
    return '$minutes minutes';
  }

  @override
  String get enable => 'Activer';

  @override
  String get enableFailed => 'Échec d\'activation';

  @override
  String slotEnabled(Object minutes) {
    return 'Durée activée : $minutes minutes';
  }

  @override
  String get weeklyTemplateTitle => 'Modèle hebdomadaire';

  @override
  String get startLabel => 'Début';

  @override
  String get endLabel => 'Fin';

  @override
  String get customizeUpcomingWeeks =>
      'Personnaliser les prochaines semaines (21 jours)';

  @override
  String weekLabel(Object index) {
    return 'Semaine $index';
  }

  @override
  String get saveSettings => 'Enregistrer les paramètres';

  @override
  String get settingsSaved => 'Paramètres enregistrés avec succès';

  @override
  String get userNotFound =>
      'Aucun compte n’est associé à cette adresse e-mail';

  @override
  String get wrongPassword => 'Mot de passe incorrect';

  @override
  String get userDisabled => 'Ce compte a été désactivé';

  @override
  String get tooManyRequests =>
      'Trop de tentatives. Veuillez réessayer plus tard';

  @override
  String get from => 'De';

  @override
  String get to => 'À';

  @override
  String get selectTime => 'Sélectionner l\'heure';

  @override
  String get doctorSettings => 'Paramètres du médecin';

  @override
  String get doctorFileNotFound => 'Fichier du médecin introuvable';

  @override
  String get loadSettingsFailed => 'Échec de chargement des paramètres';

  @override
  String get saveChanges => 'Enregistrer les modifications';

  @override
  String get subscriptionExpiredMessage =>
      'Votre abonnement est expiré. Vous ne pouvez plus utiliser les services de l’application.';

  @override
  String get subscriptionEndedAt => 'Date de fin de l’abonnement';

  @override
  String get contactAdministration => 'Contacter l’administration';

  @override
  String get contactAdminHint =>
      'Veuillez contacter l’administration pour renouveler votre abonnement';

  @override
  String get resetFilters => 'Réinitialiser les filtres';

  @override
  String get doctorCalendar => 'Calendrier du médecin';

  @override
  String get appointments => 'Rendez-vous';

  @override
  String get confirmedAppointments => 'Confirmés';

  @override
  String get cancelledAppointments => 'Annulés';

  @override
  String get revenue => 'Revenu';

  @override
  String get dayDetails => 'Détails du jour';

  @override
  String get dayNotes => 'Notes du jour';

  @override
  String get dayAppointments => 'Rendez-vous du jour';

  @override
  String get noAppointments => 'Aucun rendez-vous';

  @override
  String get close => 'Fermer';

  @override
  String get prevMonth => 'Mois précédent';

  @override
  String get nextMonth => 'Mois suivant';

  @override
  String get doctorIdNotFound => 'ID du médecin introuvable';

  @override
  String get errorFindingDoctor => 'Erreur lors de la récupération du médecin';

  @override
  String get errorFindingDoctorId => 'Impossible de trouver l\'ID du médecin';

  @override
  String get financeDashboard => 'Tableau financier';

  @override
  String get revenueSummary => 'Résumé des revenus';

  @override
  String get todayRevenue => 'Revenu du jour';

  @override
  String get monthRevenue => 'Revenu du mois';

  @override
  String get totalRevenue => 'Revenu total';

  @override
  String get appointmentPerformance => 'Performance des rendez-vous';

  @override
  String get successRate => 'Taux de réussite';

  @override
  String get subscription => 'Abonnement';

  @override
  String get subscriptionStatus => 'Statut de l\'abonnement';

  @override
  String get subscriptionActive => 'Actif';

  @override
  String get subscriptionTrial => 'Essai';

  @override
  String get subscriptionExpired => 'L\'abonnement du médecin est expiré';

  @override
  String get subscriptionEndsAt => 'Expire le';

  @override
  String get subscriptionExpiringSoon =>
      'Expire bientôt — renouvellement conseillé.';

  @override
  String get renewSubscription => 'Renouveler l\'abonnement';

  @override
  String get lastUpdate => 'Dernière mise à jour';

  @override
  String get comingSoon => 'Bientôt disponible';

  @override
  String get daysOff => 'Jours d\'absence';

  @override
  String get pickDaysOffRange => 'Choisir une période d’absence';

  @override
  String get reasonOptional => 'Raison (optionnel)';

  @override
  String get savedDaysOff => 'Jours d’absence enregistrés :';

  @override
  String get daysOffSaved =>
      'Jours d’absence enregistrés et rendez-vous annulés';

  @override
  String get dayOffDeleted => 'Jour d’absence supprimé';

  @override
  String get errorLoadingData => 'Erreur de chargement';

  @override
  String get noDaysOff => 'Aucun jour d’absence';

  @override
  String get deleteDayOff => 'Supprimer ce jour';

  @override
  String get tapToChoose => 'Appuyez pour choisir';

  @override
  String get doctorDashboard => 'Tableau du médecin';

  @override
  String get doctorNotLinked => 'Compte non lié à un médecin';

  @override
  String get errorResolvingDoctor => 'Erreur lors du chargement du médecin';

  @override
  String get phoneUnavailable => 'Numéro de téléphone non disponible';

  @override
  String get callFailed => 'Impossible d’ouvrir le composeur d\'appel';

  @override
  String get directRead => 'Lecture directe';

  @override
  String get errorLoadingAppointments => 'Erreur de chargement des rendez-vous';

  @override
  String get patient => 'Patient';

  @override
  String get phone => 'Téléphone';

  @override
  String get time => 'Heure';

  @override
  String get notAvailable => 'Indisponible';

  @override
  String get statusPending => 'En attente';

  @override
  String get statusConfirmed => 'Confirmé';

  @override
  String get statusCanceled => 'Annulé';

  @override
  String get confirmAppointment => 'Confirmer le rendez-vous';

  @override
  String get cancelAppointment => 'Annuler le rendez-vous';

  @override
  String get appointmentConfirmed => 'Rendez-vous confirmé';

  @override
  String get appointmentCanceled => 'Rendez-vous annulé';

  @override
  String get unexpectedError => 'Erreur inattendue';

  @override
  String get tryDirectRead => 'Essayer lecture directe';

  @override
  String get refreshTryDirect => 'Actualiser / lecture directe';

  @override
  String get all => 'Tous';

  @override
  String get doctorTerms => 'Engagement du médecin';

  @override
  String get doctorAgreementTitle => 'Engagement du médecin';

  @override
  String get doctorAgreementDetails =>
      'Déclaration et engagement relatifs au compte médecin\n\nEn utilisant cette application en tant que médecin, vous déclarez et acceptez ce qui suit :\n\n1) Vous êtes un médecin dûment autorisé à exercer et toutes les informations fournies sont exactes et à jour.\n2) Vous assumez l\'entière responsabilité légale et professionnelle des informations que vous fournissez.\n3) L\'application n\'est pas responsable de l\'exactitude des informations saisies par les médecins.\n4) L\'application est destinée uniquement à la gestion des rendez-vous médicaux.\n5) Toute usurpation d\'identité ou information trompeuse peut entraîner la suppression du compte et des poursuites légales.\n6) L\'administration de l\'application se réserve le droit de demander des documents prouvant les qualifications professionnelles si nécessaire.\n\nEn continuant, vous acceptez l\'ensemble des conditions ci-dessus.';

  @override
  String get doctorAgreementConfirm =>
      'Je confirme être un médecin autorisé et assumer l\'entière responsabilité de l\'exactitude de mes informations.';

  @override
  String get mustAcceptTerms =>
      'Veuillez accepter les conditions avant de continuer';

  @override
  String get acceptAndContinue => 'Continuer la création du compte';

  @override
  String get back => 'Retour';

  @override
  String get todayAppointments => 'Rendez-vous du jour';

  @override
  String get loadTodayError =>
      'Erreur lors du chargement des rendez-vous du jour';

  @override
  String get noAppointmentsToday => 'Aucun rendez-vous aujourd\'hui';

  @override
  String get checkedInShort => 'Arrivé';

  @override
  String get checkIn => 'Présence';

  @override
  String get checkedIn => 'Présence enregistrée';

  @override
  String get noShow => 'Absent';

  @override
  String get noShowSet => 'Statut marqué : absent';

  @override
  String get newPasswordOptional => 'Nouveau mot de passe (optionnel)';

  @override
  String get mustLogin => 'Veuillez vous connecter';

  @override
  String get mustLoginFirst => 'Veuillez vous connecter d\'abord';

  @override
  String get cannotBookThisDay => 'Impossible de réserver ce jour';

  @override
  String get doctorDayOff => 'Le médecin est en congé';

  @override
  String get dayNotAvailable => 'Jour indisponible';

  @override
  String get dayIsFull => 'Journée complète';

  @override
  String get timeNotAvailable => 'Horaire indisponible';

  @override
  String get cannotBookPastTime => 'Impossible de réserver un horaire passé';

  @override
  String get bookingSent => 'Demande de réservation envoyée';

  @override
  String get invalidSlot => 'Créneau invalide';

  @override
  String get deleteAppointment => 'Supprimer le rendez-vous';

  @override
  String get appointmentDeleted => 'Le rendez-vous a été supprimé';

  @override
  String get emailInUse => 'Cet email est déjà utilisé';

  @override
  String get weakPassword => 'Mot de passe trop faible';

  @override
  String get registerPatient => 'Inscription patient';

  @override
  String get register => 'S\'inscrire';

  @override
  String get fullName => 'Nom complet';

  @override
  String get enterValidName => 'Veuillez entrer un nom valide';

  @override
  String get enterValidPassword => 'Veuillez entrer un mot de passe valide';

  @override
  String get phoneNumber => 'Numéro de téléphone';

  @override
  String get enterValidPhone => 'Veuillez entrer un numéro valide';

  @override
  String get phoneUpdated =>
      'Le numéro de téléphone a été mis à jour avec succès';

  @override
  String get createAccount => 'Créer un compte';

  @override
  String get appBarCreateAccount => 'Créer un compte';

  @override
  String get chooseAccountType => 'Choisissez le type de compte';

  @override
  String get patientOrDoctor => 'Êtes-vous patient ou médecin ?';

  @override
  String get registerDoctor => 'Inscription médecin';

  @override
  String get dataLoadError => 'Erreur de chargement';

  @override
  String get wrongCurrentPassword => 'Mot de passe actuel incorrect';

  @override
  String get reauthFailed => 'Échec de réauthentification';

  @override
  String get noChangesToSave => 'Aucune modification à enregistrer';

  @override
  String get savedSuccessfully => 'Enregistré avec succès';

  @override
  String get saveFailed => 'Échec de l\'enregistrement';

  @override
  String get patientSettings => 'Paramètres du patient';

  @override
  String get emailExample => 'exemple@mail.com';

  @override
  String get verifyBySMS => 'Vérifier par SMS';

  @override
  String get notificationSettings => 'Paramètres de notification';

  @override
  String get notificationSettingsDesc => 'Gérer vos notifications';

  @override
  String get securityNote => 'Note : le numéro est utilisé pour la sécurité';

  @override
  String get enterPhoneFirst => 'Veuillez entrer un numéro';

  @override
  String get autoVerifyFailed => 'Échec de vérification automatique';

  @override
  String get codeSendFailed => 'Échec d’envoi du code';

  @override
  String get codeSentSuccessfully => 'Code envoyé avec succès';

  @override
  String get enterSMSCode => 'Entrez le code SMS';

  @override
  String get verifyFailed => 'Échec de vérification';

  @override
  String get phoneVerification => 'Vérification du téléphone';

  @override
  String get sending => 'Envoi...';

  @override
  String get sendSMSCode => 'Envoyer code SMS';

  @override
  String get smsCode => 'Code SMS';

  @override
  String get verifying => 'Vérification...';

  @override
  String get confirmCode => 'Confirmer le code';

  @override
  String get notificationsEnabled => 'Notifications activées';

  @override
  String get notificationsEnabledMessage => 'Vous recevrez les notifications';

  @override
  String get notificationsDisabled => 'Notifications désactivées';

  @override
  String get testNotificationTitle => 'Notification test';

  @override
  String get testNotificationMessage => 'Ceci est une notification test';

  @override
  String get allowNotifications => 'Autoriser les notifications';

  @override
  String get allowNotificationsDescription => 'Activer les notifications';

  @override
  String get sendTestNotification => 'Envoyer une notification test';

  @override
  String get fcmDisabledNote => 'FCM désactivé sur cet appareil';

  @override
  String get notLoggedIn => 'Vous n\'êtes pas connecté';

  @override
  String get failedToLoadAppointments => 'Échec du chargement des rendez-vous';

  @override
  String get noAppointmentsYet => 'Aucun rendez-vous pour le moment';

  @override
  String get userDataNotFound => 'Données utilisateur introuvables';

  @override
  String get loginError => 'Erreur de connexion';

  @override
  String get language => 'Langue';

  @override
  String get secretaryHint => 'Espace réservé au secrétaire';

  @override
  String get welcomeDoctor => 'Bienvenue Dr';

  @override
  String get defaultDoctor => 'Médecin';

  @override
  String get welcomeUser => 'Bienvenue';

  @override
  String get defaultUser => 'Utilisateur';

  @override
  String get home => 'Accueil';

  @override
  String get changeLanguage => 'Changer la langue';

  @override
  String get patientServices => 'Services aux patients';

  @override
  String get doctorsList => 'Liste des médecins';

  @override
  String get dashboard => 'Tableau de bord';

  @override
  String get calendar => 'Calendrier';

  @override
  String get finance => 'Finances';

  @override
  String get failedToLoadDoctors => 'Échec du chargement des médecins';

  @override
  String get noDoctorsAvailable => 'Aucun médecin disponible';

  @override
  String get chooseDay => 'Choisir un jour';

  @override
  String get noAvailableAppointments => 'Aucun créneau disponible';

  @override
  String get available => 'Disponible';

  @override
  String get full => 'Complet';

  @override
  String get address => 'Adresse';

  @override
  String get sessionPrice => 'Prix de la séance';

  @override
  String get requested => 'Demandé';

  @override
  String get slotAlreadyTaken => 'Créneau déjà réservé';

  @override
  String get codeInactive => 'Code inactif';

  @override
  String get codeExpired => 'Code expiré';

  @override
  String get codeIncomplete => 'Code incomplet';

  @override
  String get codeNotFound => 'Code introuvable';

  @override
  String get connectionError => 'Erreur de connexion';

  @override
  String get filter => 'تصفية';

  @override
  String get syncFailed => 'Échec de synchronisation';

  @override
  String get active => 'Actif';

  @override
  String get inactive => 'Inactif';

  @override
  String get expired => 'Expiré';

  @override
  String get expiringSoon => 'Expire bientôt';

  @override
  String get noDoctorId => 'Aucun ID médecin';

  @override
  String get activatedUntil => 'Activé jusqu\'au';

  @override
  String get refresh => 'Actualiser';

  @override
  String get noResults => 'Aucun résultat';

  @override
  String get cannotConfirmPastAppointment =>
      'Impossible de confirmer un rendez-vous à une date passée';

  @override
  String get reportMarkedProcessed => 'Signalement marqué comme traité';

  @override
  String get reportMarkedNew => 'Signalement marqué comme nouveau';

  @override
  String get type => 'Type';

  @override
  String get status => 'Statut';

  @override
  String get date => 'Date';

  @override
  String get text => 'Texte';

  @override
  String get delete => 'Supprimer';

  @override
  String get cancel => 'Annuler';

  @override
  String get confirm => 'Confirmer';

  @override
  String get deleteAccountWarning =>
      'Êtes-vous sûr de vouloir supprimer le compte ? Cette action est irréversible.';

  @override
  String get deleteAccount => 'Supprimer le compte';

  @override
  String get chooseAppointment => 'Choisir le rendez-vous';

  @override
  String get loadingAppointments => 'Chargement des rendez-vous...';

  @override
  String get loadingTakingLong => 'Le chargement prend du temps...';

  @override
  String get save => 'Enregistrer';

  @override
  String get enterCode => 'Entrez le code';

  @override
  String get noLoggedUser => 'Aucun utilisateur connecté';

  @override
  String get insufficientPermissions => 'Permissions insuffisantes';

  @override
  String get adminCheckFailed => 'Échec de vérification d\'administrateur';

  @override
  String syncCompleted(Object processed, Object updated) {
    return '$processed traités, $updated mis à jour';
  }

  @override
  String get manageSubscriptions => 'Gérer les abonnements';

  @override
  String get manageSubscriptionsSubtitle =>
      'Réviser et renouveler les abonnements';

  @override
  String get reports => 'Rapports';

  @override
  String get reportsSubtitle => 'Rapports et signalements';

  @override
  String get adminDashboard => 'Tableau Admin';

  @override
  String get tools => 'Outils';

  @override
  String get syncDoctorSubscriptions => 'Synchroniser abonnements médecins';

  @override
  String get logout => 'Déconnexion';

  @override
  String get customActivation => 'Activation personnalisée';

  @override
  String get daysCount => 'Nombre de jours';

  @override
  String get invalidDays => 'Nombre invalide';

  @override
  String get daysTooLarge => 'Nombre trop élevé';

  @override
  String get activate => 'Activer';

  @override
  String get deactivateSubscription => 'Désactiver l\'abonnement';

  @override
  String get confirmDeactivate => 'Voulez-vous désactiver ?';

  @override
  String get deactivate => 'Désactiver';

  @override
  String get deactivated => 'Désactivé';

  @override
  String get activate7 => 'Activer 7 jours';

  @override
  String get activate30 => 'Activer 30 jours';

  @override
  String get activate90 => 'Activer 90 jours';

  @override
  String get actionFailed => 'Échec de l\'action';

  @override
  String get adminSubscriptions => 'Abonnements Admin';

  @override
  String get searchByNameEmail => 'Recherche par nom ou email';

  @override
  String get errorLoading => 'Erreur de chargement';

  @override
  String get noName => 'Sans nom';

  @override
  String get deleteReport => 'Supprimer le rapport';

  @override
  String get deleteReportConfirm => 'Supprimer ce rapport ?';

  @override
  String get deletedSuccessfully => 'Supprimé avec succès';

  @override
  String get pickDateRange => 'Choisir la période';

  @override
  String get unknown => 'Inconnu';

  @override
  String get processed => 'Traité';

  @override
  String get newReport => 'Nouveau';

  @override
  String get reportDetails => 'Détails du rapport';

  @override
  String get senderEmail => 'Email de l\'expéditeur';

  @override
  String get noteStatusChangeHint => 'Vous pouvez changer le statut';

  @override
  String get markProcessed => 'Marquer traité';

  @override
  String get markNew => 'Marquer nouveau';

  @override
  String get report => 'Rapport';

  @override
  String get sender => 'Expéditeur';

  @override
  String get clearDateRange => 'Effacer période';

  @override
  String get invalidEmail => 'Email invalide';

  @override
  String get error => 'Erreur';

  @override
  String get email => 'Email';

  @override
  String get enterEmail => 'Entrez l\'email';

  @override
  String get password6Chars =>
      'Le mot de passe doit contenir au moins 6 caractères';

  @override
  String get myAppointments => 'Mes rendez-vous';

  @override
  String get doctor => 'Docteur';

  @override
  String get specialty => 'Spécialité';

  @override
  String get password => 'Mot de passe';

  @override
  String get login => 'Connexion';

  @override
  String get createNewAccount => 'Créer un nouveau compte';

  @override
  String get chooseLanguage => 'Choisissez la langue';

  @override
  String get arabic => 'Arabe';

  @override
  String get french => 'Français';

  @override
  String get secretarySpace => 'Espace secrétaire';

  @override
  String get appointmentsToday => 'Rendez-vous d\'aujourd\'hui';

  @override
  String get createSecretaryCode => 'Créer un code secrétaire';

  @override
  String get optionalExpiry => 'Expiration (optionnel)';

  @override
  String get noExpiry => 'Sans expiration';

  @override
  String get expiresAt => 'Expire le';

  @override
  String get pickDate => 'Choisir la date';

  @override
  String get create => 'Créer';

  @override
  String get userNotLogged => 'Utilisateur non connecté';

  @override
  String get noPermissionForThisDoctor => 'Aucune permission pour ce docteur';

  @override
  String get expiryMustBeFuture => 'La date doit être dans le futur';

  @override
  String get codeCreated => 'Code créé';

  @override
  String get generalFailure => 'Une erreur s\'est produite';

  @override
  String get permissionDenied => 'Permission refusée';

  @override
  String get networkError => 'Erreur réseau';

  @override
  String get codeAlreadyExists => 'Le code existe déjà';

  @override
  String get updateFailed => 'Échec de mise à jour';

  @override
  String get expiryUpdated => 'Expiration mise à jour';

  @override
  String get expiryRemoved => 'Expiration supprimée';

  @override
  String get deleteCode => 'Supprimer le code';

  @override
  String get deleteCodeConfirm => 'Voulez-vous supprimer ce code ?';

  @override
  String get codeDeleted => 'Code supprimé';

  @override
  String get statusInactive => 'Inactif';

  @override
  String get statusExpired => 'Expiré';

  @override
  String get statusActive => 'Actif';

  @override
  String get secretaryCodes => 'Codes secrétaires';

  @override
  String get createNewCode => 'Créer nouveau code';

  @override
  String get createCode => 'Créer code';

  @override
  String get loadingFailed => 'Échec de chargement';

  @override
  String get copyCode => 'Copier le code';

  @override
  String get copied => 'Copié';

  @override
  String get createdAt => 'Créé le';

  @override
  String get editExpiry => 'Modifier l\'expiration';

  @override
  String get removeExpiry => 'Supprimer l\'expiration';

  @override
  String get disable => 'Désactiver';

  @override
  String get noSecretaryCodes => 'Aucun code secrétaire';

  @override
  String get secretaryQrCode => 'QR code secrétaire';

  @override
  String get qrGenerationFailed => 'Échec de génération du QR';

  @override
  String get done => 'Terminé';

  @override
  String get doctorAccountCreated => 'Compte médecin créé';

  @override
  String get doctorRegisterTitle => 'Inscription médecin';

  @override
  String get enterSpecialty => 'Entrez la spécialité';

  @override
  String get consultationPrice => 'Prix de consultation';

  @override
  String get createDoctorAccount => 'Créer un compte médecin';

  @override
  String get operationFailed => 'Échec de l\'opération';

  @override
  String get codeVerificationFailed => 'Échec de vérification du code';

  @override
  String get authFailed => 'Échec d\'authentification';

  @override
  String get anonymousAuthNotEnabled => 'Authentification anonyme désactivée';

  @override
  String get permissionDeniedSessions => 'Accès refusé aux sessions';

  @override
  String get secretaryEnterCodeText => 'Entrez le code secrétaire';

  @override
  String get secretaryCode => 'Code secrétaire';

  @override
  String get secretaryCodeExample => 'Ex : ABC123';

  @override
  String get searchReports => 'Recherche dans les rapports';

  @override
  String get uidUnavailable => 'Identifiant indisponible';

  @override
  String get noAccess => 'Accès refusé';

  @override
  String get notAdminAccount => 'Ce compte n\'est pas administrateur';

  @override
  String get accountDisabled => 'Compte désactivé';

  @override
  String get loginFailed => 'Échec de connexion';

  @override
  String get emailOrPasswordWrong => 'Email ou mot de passe incorrect';

  @override
  String get enterEmailFirst => 'Entrez l\'email d\'abord';

  @override
  String get resetLinkSent => 'Lien de réinitialisation envoyé';

  @override
  String get resetFailed => 'Échec de réinitialisation';

  @override
  String get adminLogin => 'Connexion admin';

  @override
  String get adminEntry => 'Entrée admin';

  @override
  String get invalidEmailFormat => 'Format d\'email invalide';

  @override
  String get show => 'Afficher';

  @override
  String get hide => 'Masquer';

  @override
  String get noPermission => 'Vous n\'avez pas la permission d\'accéder';

  @override
  String get enterPassword => 'Entrez le mot de passe';

  @override
  String get passwordShort => 'Mot de passe trop court';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get adminScreenHint => 'Cet écran est réservé à l\'administrateur';

  @override
  String get deleteFailed => 'Échec de la suppression';

  @override
  String get profile => 'Profil';

  @override
  String get manageProfile => 'Gérer le profil';

  @override
  String get changePassword => 'Changer le mot de passe';

  @override
  String get notifications => 'Notifications';

  @override
  String get secretaryManagement => 'Gestion des secrétaires';

  @override
  String get manageSecretary => 'Gérer le secrétaire';

  @override
  String get aboutApp => 'À propos de l\'application';

  @override
  String get emailUpdated => 'E-mail mis à jour avec succès';

  @override
  String get passwordUpdated => 'Mot de passe mis à jour avec succès';

  @override
  String get showPrice => 'Afficher le prix';

  @override
  String get updateEmail => 'Mettre à jour l\'e-mail';

  @override
  String get updatePassword => 'Mettre à jour le mot de passe';

  @override
  String get governorate => 'Gouvernorat';

  @override
  String get chooseGovernorate => 'Veuillez choisir le gouvernorat';

  @override
  String get chooseSpecialty => 'Veuillez choisir la spécialité';

  @override
  String get searchDoctors => 'Rechercher un médecin';

  @override
  String get search => 'Rechercher';

  @override
  String get noResultsFound => 'Aucun résultat trouvé';

  @override
  String get enterAddress => 'Veuillez saisir l\'adresse';

  @override
  String get passwordsNotMatch => 'Les mots de passe ne correspondent pas';

  @override
  String get confirmPassword => 'Confirmer le mot de passe';

  @override
  String get doctorPrefix => 'Dr';

  @override
  String get bookAppointment => 'Prendre rendez-vous';

  @override
  String get doctorNotAvailable =>
      'Le médecin n\'est pas disponible actuellement';

  @override
  String get currentPasswordRequired =>
      'Veuillez saisir votre mot de passe actuel pour confirmer le changement d’email';

  @override
  String get currentPassword => 'Mot de passe actuel';

  @override
  String get newPassword => 'Nouveau mot de passe';

  @override
  String get confirmNewPassword => 'Confirmer le nouveau mot de passe';

  @override
  String get passwordsDoNotMatch => 'Les mots de passe ne correspondent pas';

  @override
  String get passwordTooShort => 'Mot de passe trop court';

  @override
  String get currentPasswordIncorrect => 'Le mot de passe actuel est incorrect';

  @override
  String get subscriptionRequests => 'Demandes de renouvellement';

  @override
  String get noSubscriptionRequests => 'Aucune demande pour le moment';

  @override
  String get requestDate => 'Date de la demande';

  @override
  String get unknownDoctor => 'Médecin inconnu';

  @override
  String get reject => 'Refuser';

  @override
  String get subscriptionRequestsSubtitle =>
      'Demandes de renouvellement envoyées par les médecins';

  @override
  String get requestSubscriptionRenewal => 'Demander le renouvellement';

  @override
  String get subscriptionRequestSent =>
      'La demande de renouvellement a été envoyée';

  @override
  String get subscriptionRequestAlreadySent =>
      'Une demande de renouvellement a déjà été envoyée';

  @override
  String get noCodes => 'Aucun code disponible';

  @override
  String get optionalExpiryDate => 'Ajouter une date d’expiration (optionnel)';

  @override
  String get chooseDate => 'Choisir une date';

  @override
  String get expiresOn => 'Expire le';

  @override
  String get codeNotValid => 'Code incorrect';

  @override
  String get confirmDelete => 'Confirmer la suppression ?';

  @override
  String get invalidCodeFormat => 'Format du code invalide';

  @override
  String get copy => 'Copier';

  @override
  String get enterSecretaryCode =>
      'Entrez le code du secrétaire fourni par le médecin';

  @override
  String get usedBy => 'Utilisé par';

  @override
  String get monday => 'Lundi';

  @override
  String get tuesday => 'Mardi';

  @override
  String get wednesday => 'Mercredi';

  @override
  String get thursday => 'Jeudi';

  @override
  String get friday => 'Vendredi';

  @override
  String get saturday => 'Samedi';

  @override
  String get sunday => 'Dimanche';

  @override
  String get acceptBookings => 'Accepter les réservations';

  @override
  String get acceptBookingsOn =>
      'Le médecin est visible et accepte de nouvelles réservations';

  @override
  String get acceptBookingsOff =>
      'Le médecin n\'est pas disponible actuellement';

  @override
  String get bookingsEnabled => 'La réception des réservations a été activée';

  @override
  String get bookingsDisabled =>
      'La réception des réservations a été désactivée';

  @override
  String get savePrice => 'Enregistrer le prix';

  @override
  String get saving => 'Enregistrement en cours...';

  @override
  String get priceSavedSuccessfully => 'Le prix a été enregistré avec succès';

  @override
  String get invalidPrice => 'Veuillez entrer un prix valide';

  @override
  String get confirmCancelAppointment =>
      'Êtes-vous sûr de vouloir annuler ce rendez-vous ?';

  @override
  String get yesCancel => 'Oui, annuler';

  @override
  String get no => 'Retour';

  @override
  String get enterPaidAmount => 'Saisir le montant payé';

  @override
  String get amountHint => 'Montant';

  @override
  String get currency => 'DT';

  @override
  String get subscriptionExpiredDoctor =>
      'Ce médecin n\'est pas disponible momentanément (abonnement expiré)';

  @override
  String remainingDays(Object days) {
    return 'Il reste $days jours';
  }

  @override
  String get appointmentDetails => 'Détails du rendez-vous';

  @override
  String get callPatient => 'Appeler le patient';

  @override
  String get doctorNotes => 'Notes du médecin';

  @override
  String get visitType => 'Type de visite';

  @override
  String get consultation => 'Consultation';

  @override
  String get review => 'Contrôle';

  @override
  String get checkup => 'Examen';

  @override
  String get enterData => 'Veuillez saisir des données';

  @override
  String get hasReport => 'Rapport موجود';

  @override
  String get myReports => 'Mes signalements';

  @override
  String get openReports => 'Signalements ouverts';

  @override
  String get sendReport => 'Envoyer un signalement';

  @override
  String get bug => 'Bug';

  @override
  String get complaint => 'Réclamation';

  @override
  String get suggestion => 'Suggestion';

  @override
  String get describeProblem => 'Décrivez le problème...';

  @override
  String get send => 'Envoyer';

  @override
  String get noReports => 'Aucun signalement pour le moment';

  @override
  String get invalidInput => 'Veuillez saisir un message';

  @override
  String get reportSentSuccessfully => 'Signalement envoyé avec succès';

  @override
  String get payment => 'Paiement';

  @override
  String get contactUs => 'Contactez-nous';

  @override
  String get replyAdded => 'Réponse ajoutée';

  @override
  String get adminReply => 'Réponse de l\'administration :';

  @override
  String get english => 'Anglais';

  @override
  String get appDescription => 'Application de prise de rendez-vous médicaux.';

  @override
  String get adminMaintenance => 'Maintenance Admin';

  @override
  String get resetAppointments => 'Réinitialiser les rendez-vous';

  @override
  String get resetSlots => 'Réinitialiser les créneaux';

  @override
  String get resetTransactions => 'Réinitialiser les transactions';

  @override
  String get dangerZone => 'Zone dangereuse';

  @override
  String get fullReset => 'RÉINITIALISATION TOTALE';

  @override
  String get warningTitle => 'ATTENTION';

  @override
  String get warningMessage =>
      'Toutes les données seront supprimées. Êtes-vous sûr ?';

  @override
  String get continueBtn => 'Continuer';

  @override
  String get finalConfirm => 'CONFIRMATION FINALE';

  @override
  String get finalMessage =>
      'Dernière chance ! Toutes les données seront perdues.';

  @override
  String get resetDone => 'Réinitialisation terminée';

  @override
  String get appointmentsCleared => 'Rendez-vous supprimés';

  @override
  String get slotsCleared => 'Créneaux supprimés';

  @override
  String get transactionsCleared => 'Transactions supprimées';

  @override
  String get secretMode => 'Mode secret...';

  @override
  String get systemTools => 'Outils système';

  @override
  String get systemToolsSubtitle => 'Outils de maintenance et de débogage';
}
