// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Medical Booking';

  @override
  String get failedToLoadUserData => 'Failed to load user data';

  @override
  String get invalidUserRole => 'Invalid account, please sign in again';

  @override
  String get scheduleSettings => 'Schedule Settings';

  @override
  String get slotDurationTitle => 'Consultation Duration';

  @override
  String get slotDurationNotSet => 'Duration not set';

  @override
  String minutesLabel(Object minutes) {
    return '$minutes minutes';
  }

  @override
  String get enable => 'Enable';

  @override
  String get enableFailed => 'Activation failed';

  @override
  String slotEnabled(Object minutes) {
    return 'Duration enabled: $minutes minutes';
  }

  @override
  String get weeklyTemplateTitle => 'Weekly Template';

  @override
  String get startLabel => 'Start';

  @override
  String get endLabel => 'End';

  @override
  String get customizeUpcomingWeeks => 'Customize upcoming 21 days';

  @override
  String weekLabel(Object index) {
    return 'Week $index';
  }

  @override
  String get saveSettings => 'Save Settings';

  @override
  String get settingsSaved => 'Settings saved successfully';

  @override
  String get userNotFound => 'No account found with this email address';

  @override
  String get wrongPassword => 'Incorrect password';

  @override
  String get userDisabled => 'This account has been disabled';

  @override
  String get tooManyRequests => 'Too many attempts. Please try again later';

  @override
  String get from => 'From';

  @override
  String get to => 'To';

  @override
  String get selectTime => 'Select Time';

  @override
  String get doctorSettings => 'Doctor Settings';

  @override
  String get doctorFileNotFound => 'Doctor file not found';

  @override
  String get loadSettingsFailed => 'Failed to load settings';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get subscriptionExpiredMessage =>
      'Your subscription has expired. You cannot use the application services until it is renewed.';

  @override
  String get subscriptionEndedAt => 'Subscription end date';

  @override
  String get contactAdministration => 'Contact administration';

  @override
  String get contactAdminHint =>
      'Please contact the administration to renew your subscription';

  @override
  String get resetFilters => 'Reset filters';

  @override
  String get doctorCalendar => 'Doctor Calendar';

  @override
  String get appointments => 'Appointments';

  @override
  String get confirmedAppointments => 'Confirmed';

  @override
  String get cancelledAppointments => 'Cancelled';

  @override
  String get revenue => 'Revenue';

  @override
  String get dayDetails => 'Day Details';

  @override
  String get dayNotes => 'Day Notes';

  @override
  String get dayAppointments => 'Appointments of the Day';

  @override
  String get noAppointments => 'No appointments';

  @override
  String get close => 'Close';

  @override
  String get prevMonth => 'Previous Month';

  @override
  String get nextMonth => 'Next Month';

  @override
  String get doctorIdNotFound => 'Doctor ID not found';

  @override
  String get errorFindingDoctor => 'Error finding doctor';

  @override
  String get errorFindingDoctorId => 'Unable to locate doctor ID';

  @override
  String get financeDashboard => 'Finance Dashboard';

  @override
  String get revenueSummary => 'Revenue Summary';

  @override
  String get todayRevenue => 'Today\'s Revenue';

  @override
  String get monthRevenue => 'Monthly Revenue';

  @override
  String get totalRevenue => 'Total Revenue';

  @override
  String get appointmentPerformance => 'Appointment Performance';

  @override
  String get successRate => 'Success Rate';

  @override
  String get subscription => 'Subscription';

  @override
  String get subscriptionStatus => 'Subscription Status';

  @override
  String get subscriptionActive => 'Active';

  @override
  String get subscriptionTrial => 'Trial';

  @override
  String get subscriptionExpired => 'Doctor subscription has expired';

  @override
  String get subscriptionEndsAt => 'Ends At';

  @override
  String get subscriptionExpiringSoon =>
      'Subscription expiring soon — renewal recommended.';

  @override
  String get renewSubscription => 'Renew Subscription';

  @override
  String remainingDays(Object days) {
    return '$days days remaining';
  }

  @override
  String get lastUpdate => 'Last Update';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get daysOff => 'Days Off';

  @override
  String get pickDaysOffRange => 'Select absence period';

  @override
  String get reasonOptional => 'Reason (optional)';

  @override
  String get savedDaysOff => 'Recorded days:';

  @override
  String get daysOffSaved =>
      'Days off saved and conflicting appointments cancelled';

  @override
  String get dayOffDeleted => 'Day off removed';

  @override
  String get errorLoadingData => 'Error loading data';

  @override
  String get noDaysOff => 'No absence days';

  @override
  String get deleteDayOff => 'Delete Day Off';

  @override
  String get tapToChoose => 'Tap to choose';

  @override
  String get doctorDashboard => 'Doctor Dashboard';

  @override
  String get doctorNotLinked => 'Account not linked to a doctor';

  @override
  String get errorResolvingDoctor => 'Error loading doctor';

  @override
  String get phoneUnavailable => 'Phone number unavailable';

  @override
  String get callFailed => 'Unable to launch call app';

  @override
  String get directRead => 'Direct Read';

  @override
  String get errorLoadingAppointments => 'Error loading appointments';

  @override
  String get patient => 'Patient';

  @override
  String get phone => 'Phone';

  @override
  String get time => 'Time';

  @override
  String get notAvailable => 'Not Available';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusConfirmed => 'Confirmed';

  @override
  String get statusCanceled => 'Cancelled';

  @override
  String get confirmAppointment => 'Confirm Appointment';

  @override
  String get cancelAppointment => 'Cancel Appointment';

  @override
  String get appointmentConfirmed => 'Appointment confirmed';

  @override
  String get appointmentCanceled => 'Appointment cancelled';

  @override
  String get unexpectedError => 'Unexpected error';

  @override
  String get tryDirectRead => 'Try Direct Read';

  @override
  String get refreshTryDirect => 'Refresh / Direct Read';

  @override
  String get all => 'All';

  @override
  String get doctorTerms => 'Doctor Agreement';

  @override
  String get doctorAgreementTitle => 'Doctor Commitment';

  @override
  String get doctorAgreementDetails =>
      'Doctor Account Declaration and Commitment\n\nBy using this application as a doctor, you hereby declare and agree to the following:\n\n1) You are a licensed medical doctor, and all information you provide is accurate and up to date.\n2) You bear full legal and professional responsibility for the information you submit.\n3) The application is not responsible for the accuracy of the information provided by doctors.\n4) The application is intended solely for managing medical appointments.\n5) Impersonation or submission of false information may result in account suspension or legal action.\n6) The application administration reserves the right to request documents proving professional credentials when necessary.\n\nBy continuing, you agree to all the above terms.';

  @override
  String get doctorAgreementConfirm =>
      'I confirm that I am a licensed doctor and take full responsibility for the accuracy of my information.';

  @override
  String get mustAcceptTerms => 'You must accept the terms before continuing';

  @override
  String get acceptAndContinue => 'Continue account creation';

  @override
  String get back => 'Back';

  @override
  String get todayAppointments => 'Today\'s Appointments';

  @override
  String get loadTodayError => 'Failed to load today’s appointments';

  @override
  String get noAppointmentsToday => 'No appointments today';

  @override
  String get checkedInShort => 'Checked in';

  @override
  String get checkIn => 'Check In';

  @override
  String get checkedIn => 'Checked In';

  @override
  String get noShow => 'No Show';

  @override
  String get noShowSet => 'Marked as No Show';

  @override
  String get newPasswordOptional => 'New password (optional)';

  @override
  String get mustLogin => 'You must log in';

  @override
  String get mustLoginFirst => 'Please log in first';

  @override
  String get cannotBookThisDay => 'Cannot book on this day';

  @override
  String get doctorDayOff => 'Doctor is off today';

  @override
  String get dayNotAvailable => 'Day not available';

  @override
  String get dayIsFull => 'Day fully booked';

  @override
  String get timeNotAvailable => 'Time not available';

  @override
  String get cannotBookPastTime => 'Cannot book past time';

  @override
  String get bookingSent => 'Booking request sent';

  @override
  String get invalidSlot => 'Invalid slot';

  @override
  String get deleteAppointment => 'Delete appointment';

  @override
  String get appointmentDeleted => 'Appointment deleted successfully';

  @override
  String get emailInUse => 'Email already in use';

  @override
  String get weakPassword => 'Password too weak';

  @override
  String get registerPatient => 'Register Patient';

  @override
  String get register => 'Register';

  @override
  String get fullName => 'Full Name';

  @override
  String get enterValidName => 'Enter a valid name';

  @override
  String get enterValidPassword => 'Enter a valid password';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get enterValidPhone => 'Enter a valid phone number';

  @override
  String get phoneUpdated => 'Phone number updated successfully';

  @override
  String get createAccount => 'Create Account';

  @override
  String get appBarCreateAccount => 'Create Account';

  @override
  String get chooseAccountType => 'Choose account type';

  @override
  String get patientOrDoctor => 'Are you a patient or a doctor?';

  @override
  String get registerDoctor => 'Register Doctor';

  @override
  String get dataLoadError => 'Failed to load data';

  @override
  String get wrongCurrentPassword => 'Wrong current password';

  @override
  String get reauthFailed => 'Reauthentication failed';

  @override
  String get noChangesToSave => 'No changes to save';

  @override
  String get savedSuccessfully => 'Saved successfully';

  @override
  String get saveFailed => 'Saving failed';

  @override
  String get patientSettings => 'Patient Settings';

  @override
  String get emailExample => 'example@mail.com';

  @override
  String get verifyBySMS => 'Verify by SMS';

  @override
  String get notificationSettings => 'Notification Settings';

  @override
  String get notificationSettingsDesc => 'Manage your notifications';

  @override
  String get securityNote =>
      'Note: your phone number is used for secure verification';

  @override
  String get enterPhoneFirst => 'Enter phone number first';

  @override
  String get autoVerifyFailed => 'Auto verification failed';

  @override
  String get codeSendFailed => 'Failed to send code';

  @override
  String get codeSentSuccessfully => 'Code sent successfully';

  @override
  String get enterSMSCode => 'Enter SMS code';

  @override
  String get verifyFailed => 'Verification failed';

  @override
  String get phoneVerification => 'Phone Verification';

  @override
  String get sending => 'Sending...';

  @override
  String get sendSMSCode => 'Send SMS Code';

  @override
  String get smsCode => 'SMS Code';

  @override
  String get verifying => 'Verifying...';

  @override
  String get confirmCode => 'Confirm Code';

  @override
  String get notificationsEnabled => 'Notifications enabled';

  @override
  String get notificationsEnabledMessage => 'Notifications will be delivered';

  @override
  String get notificationsDisabled => 'Notifications disabled';

  @override
  String get testNotificationTitle => 'Test Notification';

  @override
  String get testNotificationMessage => 'This is a test notification';

  @override
  String get allowNotifications => 'Allow Notifications';

  @override
  String get allowNotificationsDescription =>
      'Enable notifications on this device';

  @override
  String get sendTestNotification => 'Send Test Notification';

  @override
  String get fcmDisabledNote => 'FCM is disabled on this device';

  @override
  String get notLoggedIn => 'Not logged in';

  @override
  String get failedToLoadAppointments => 'Failed to load appointments';

  @override
  String get noAppointmentsYet => 'No appointments yet';

  @override
  String get userDataNotFound => 'User data not found';

  @override
  String get loginError => 'Login error';

  @override
  String get language => 'Language';

  @override
  String get secretaryHint => 'This screen is for secretaries';

  @override
  String get welcomeDoctor => 'Welcome Dr';

  @override
  String get defaultDoctor => 'Doctor';

  @override
  String get welcomeUser => 'Welcome';

  @override
  String get defaultUser => 'User';

  @override
  String get home => 'Home';

  @override
  String get changeLanguage => 'Change Language';

  @override
  String get patientServices => 'Patient Services';

  @override
  String get doctorsList => 'Doctors List';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get calendar => 'Calendar';

  @override
  String get finance => 'Finance';

  @override
  String get failedToLoadDoctors => 'Failed to load doctors';

  @override
  String get noDoctorsAvailable => 'No doctors available';

  @override
  String get chooseDay => 'Choose a day';

  @override
  String get noAvailableAppointments => 'No available appointments';

  @override
  String get available => 'Available';

  @override
  String get full => 'Full';

  @override
  String get address => 'Address';

  @override
  String get sessionPrice => 'Session Price';

  @override
  String get requested => 'Requested';

  @override
  String get slotAlreadyTaken => 'Slot already taken';

  @override
  String get codeInactive => 'Code inactive';

  @override
  String get codeExpired => 'Code expired';

  @override
  String get codeIncomplete => 'Incomplete code';

  @override
  String get codeNotFound => 'Code not found';

  @override
  String get connectionError => 'Connection error';

  @override
  String get filter => 'Filter';

  @override
  String get syncFailed => 'Sync failed';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get expired => 'Expired';

  @override
  String get expiringSoon => 'Expiring soon';

  @override
  String get noDoctorId => 'No doctor ID';

  @override
  String get activatedUntil => 'Activated until';

  @override
  String get refresh => 'Refresh';

  @override
  String get noResults => 'No results';

  @override
  String get cannotConfirmPastAppointment =>
      'Cannot confirm an appointment on a past date';

  @override
  String get reportMarkedProcessed => 'Report marked as processed';

  @override
  String get reportMarkedNew => 'Report marked as new';

  @override
  String get type => 'Type';

  @override
  String get status => 'Status';

  @override
  String get date => 'Date';

  @override
  String get text => 'Text';

  @override
  String get delete => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get chooseAppointment => 'Choose appointment';

  @override
  String get loadingAppointments => 'Loading appointments...';

  @override
  String get loadingTakingLong => 'Loading is taking long...';

  @override
  String get save => 'Save';

  @override
  String get enterCode => 'Enter code';

  @override
  String get noLoggedUser => 'No logged user';

  @override
  String get insufficientPermissions => 'Insufficient permissions';

  @override
  String get adminCheckFailed => 'Admin verification failed';

  @override
  String syncCompleted(Object processed, Object updated) {
    return '$processed processed, $updated updated';
  }

  @override
  String get manageSubscriptions => 'Manage Subscriptions';

  @override
  String get manageSubscriptionsSubtitle => 'Review and renew subscriptions';

  @override
  String get reports => 'Reports';

  @override
  String get reportsSubtitle => 'System reports and complaints';

  @override
  String get adminDashboard => 'Admin Dashboard';

  @override
  String get tools => 'Tools';

  @override
  String get syncDoctorSubscriptions => 'Sync doctor subscriptions';

  @override
  String get logout => 'Logout';

  @override
  String get customActivation => 'Custom Activation';

  @override
  String get daysCount => 'Days count';

  @override
  String get invalidDays => 'Invalid number of days';

  @override
  String get daysTooLarge => 'Number too large';

  @override
  String get activate => 'Activate';

  @override
  String get deactivateSubscription => 'Deactivate subscription';

  @override
  String get confirmDeactivate => 'Do you want to deactivate?';

  @override
  String get deactivate => 'Deactivate';

  @override
  String get deactivated => 'Deactivated';

  @override
  String get activate7 => 'Activate 7 days';

  @override
  String get activate30 => 'Activate 30 days';

  @override
  String get activate90 => 'Activate 90 days';

  @override
  String get actionFailed => 'Action failed';

  @override
  String get adminSubscriptions => 'Admin Subscriptions';

  @override
  String get searchByNameEmail => 'Search by name or email';

  @override
  String get errorLoading => 'Loading error';

  @override
  String get noName => 'No name';

  @override
  String get deleteReport => 'Delete report';

  @override
  String get deleteReportConfirm => 'Delete this report?';

  @override
  String get deletedSuccessfully => 'Deleted successfully';

  @override
  String get pickDateRange => 'Pick date range';

  @override
  String get unknown => 'Unknown';

  @override
  String get processed => 'Processed';

  @override
  String get newReport => 'New';

  @override
  String get reportDetails => 'Report details';

  @override
  String get senderEmail => 'Sender email';

  @override
  String get noteStatusChangeHint => 'You can change the report status';

  @override
  String get markProcessed => 'Mark processed';

  @override
  String get markNew => 'Mark new';

  @override
  String get report => 'Report';

  @override
  String get sender => 'Sender';

  @override
  String get clearDateRange => 'Clear range';

  @override
  String get invalidEmail => 'Invalid email';

  @override
  String get error => 'Error';

  @override
  String get email => 'Email';

  @override
  String get enterEmail => 'Enter email';

  @override
  String get password6Chars => 'Password must be at least 6 characters';

  @override
  String get myAppointments => 'My Appointments';

  @override
  String get doctor => 'Doctor';

  @override
  String get specialty => 'Specialty';

  @override
  String get password => 'Password';

  @override
  String get login => 'Login';

  @override
  String get createNewAccount => 'Create new account';

  @override
  String get chooseLanguage => 'Choose language';

  @override
  String get arabic => 'Arabic';

  @override
  String get french => 'French';

  @override
  String get secretarySpace => 'Secretary Space';

  @override
  String get appointmentsToday => 'Today\'s Appointments';

  @override
  String get createSecretaryCode => 'Create Secretary Code';

  @override
  String get optionalExpiry => 'Expiry (optional)';

  @override
  String get noExpiry => 'No expiry';

  @override
  String get expiresAt => 'Expires at';

  @override
  String get pickDate => 'Pick date';

  @override
  String get create => 'Create';

  @override
  String get userNotLogged => 'User not logged in';

  @override
  String get noPermissionForThisDoctor => 'No permission for this doctor';

  @override
  String get expiryMustBeFuture => 'Expiry must be in the future';

  @override
  String get codeCreated => 'Code created';

  @override
  String get generalFailure => 'An error occurred';

  @override
  String get permissionDenied => 'Permission denied';

  @override
  String get networkError => 'Network error';

  @override
  String get codeAlreadyExists => 'Code already exists';

  @override
  String get updateFailed => 'Update failed';

  @override
  String get expiryUpdated => 'Expiry updated';

  @override
  String get expiryRemoved => 'Expiry removed';

  @override
  String get deleteCode => 'Delete code';

  @override
  String get deleteCodeConfirm => 'Delete this code?';

  @override
  String get codeDeleted => 'Code deleted';

  @override
  String get statusInactive => 'Inactive';

  @override
  String get statusExpired => 'Expired';

  @override
  String get statusActive => 'Active';

  @override
  String get secretaryCodes => 'Secretary Codes';

  @override
  String get createNewCode => 'Create new code';

  @override
  String get createCode => 'Create code';

  @override
  String get loadingFailed => 'Loading failed';

  @override
  String get copyCode => 'Copy code';

  @override
  String get copied => 'Copied';

  @override
  String get createdAt => 'Created at';

  @override
  String get editExpiry => 'Edit expiry';

  @override
  String get removeExpiry => 'Remove expiry';

  @override
  String get disable => 'Disable';

  @override
  String get noSecretaryCodes => 'No secretary codes';

  @override
  String get secretaryQrCode => 'Secretary QR Code';

  @override
  String get qrGenerationFailed => 'QR generation failed';

  @override
  String get done => 'Done';

  @override
  String get doctorAccountCreated => 'Doctor account created';

  @override
  String get doctorRegisterTitle => 'Doctor Registration';

  @override
  String get enterSpecialty => 'Enter specialty';

  @override
  String get consultationPrice => 'Consultation price';

  @override
  String get createDoctorAccount => 'Create doctor account';

  @override
  String get operationFailed => 'Operation failed';

  @override
  String get codeVerificationFailed => 'Code verification failed';

  @override
  String get authFailed => 'Authentication failed';

  @override
  String get anonymousAuthNotEnabled => 'Anonymous auth is not enabled';

  @override
  String get permissionDeniedSessions => 'Permission denied for sessions';

  @override
  String get secretaryEnterCodeText => 'Enter secretary code';

  @override
  String get secretaryCode => 'Secretary code';

  @override
  String get secretaryCodeExample => 'Example: ABC123';

  @override
  String get searchReports => 'Search reports';

  @override
  String get uidUnavailable => 'UID unavailable';

  @override
  String get noAccess => 'No access';

  @override
  String get notAdminAccount => 'Not an admin account';

  @override
  String get accountDisabled => 'Account disabled';

  @override
  String get loginFailed => 'Login failed';

  @override
  String get emailOrPasswordWrong => 'Email or password incorrect';

  @override
  String get enterEmailFirst => 'Enter email first';

  @override
  String get resetLinkSent => 'Reset link sent';

  @override
  String get resetFailed => 'Reset failed';

  @override
  String get adminLogin => 'Admin Login';

  @override
  String get adminEntry => 'Admin Entry';

  @override
  String get invalidEmailFormat => 'Invalid email format';

  @override
  String get show => 'Show';

  @override
  String get hide => 'Hide';

  @override
  String get noPermission => 'You do not have permission to access this page';

  @override
  String get enterPassword => 'Enter password';

  @override
  String get passwordShort => 'Password too short';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get adminScreenHint => 'This screen is reserved for the admin';

  @override
  String get deleteFailed => 'Delete failed';

  @override
  String get profile => 'Profile';

  @override
  String get manageProfile => 'Manage Profile';

  @override
  String get changePassword => 'Change Password';

  @override
  String get notifications => 'Notifications';

  @override
  String get secretaryManagement => 'Secretary Management';

  @override
  String get manageSecretary => 'Manage Secretary';

  @override
  String get aboutApp => 'About the App';

  @override
  String get emailUpdated => 'Email updated successfully';

  @override
  String get passwordUpdated => 'Password updated successfully';

  @override
  String get showPrice => 'Show price';

  @override
  String get updateEmail => 'Update email';

  @override
  String get updatePassword => 'Update password';

  @override
  String get governorate => 'Governorate';

  @override
  String get chooseGovernorate => 'Please choose a governorate';

  @override
  String get chooseSpecialty => 'Please choose a specialty';

  @override
  String get searchDoctors => 'Search for a doctor';

  @override
  String get search => 'Search';

  @override
  String get noResultsFound => 'No results found';

  @override
  String get enterAddress => 'Please enter the address';

  @override
  String get passwordsNotMatch => 'Passwords do not match';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get doctorPrefix => 'Dr';

  @override
  String get bookAppointment => 'Book appointment';

  @override
  String get doctorNotAvailable => 'Doctor is currently unavailable';

  @override
  String get currentPasswordRequired =>
      'Please enter your current password to confirm email change';

  @override
  String get currentPassword => 'Current Password';

  @override
  String get newPassword => 'New Password';

  @override
  String get confirmNewPassword => 'Confirm new password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get passwordTooShort => 'Password too short';

  @override
  String get currentPasswordIncorrect => 'Current password is incorrect';

  @override
  String get subscriptionRequests => 'Subscription requests';

  @override
  String get noSubscriptionRequests => 'No requests at the moment';

  @override
  String get requestDate => 'Request date';

  @override
  String get unknownDoctor => 'Unknown doctor';

  @override
  String get reject => 'Reject';

  @override
  String get subscriptionRequestsSubtitle =>
      'Subscription renewal requests from doctors';

  @override
  String get requestSubscriptionRenewal => 'Request subscription renewal';

  @override
  String get subscriptionRequestSent => 'Subscription renewal request sent';

  @override
  String get subscriptionRequestAlreadySent =>
      'A renewal request has already been sent';

  @override
  String get noCodes => 'No codes available';

  @override
  String get optionalExpiryDate => 'Add expiry date (optional)';

  @override
  String get chooseDate => 'Choose date';

  @override
  String get expiresOn => 'Expires on';

  @override
  String get codeNotValid => 'Invalid code';

  @override
  String get confirmDelete => 'Confirm deletion?';

  @override
  String get invalidCodeFormat => 'Invalid code format';

  @override
  String get copy => 'Copy';

  @override
  String get enterSecretaryCode =>
      'Enter the secretary code provided by the doctor';

  @override
  String get usedBy => 'Used by';

  @override
  String get monday => 'Monday';

  @override
  String get tuesday => 'Tuesday';

  @override
  String get wednesday => 'Wednesday';

  @override
  String get thursday => 'Thursday';

  @override
  String get friday => 'Friday';

  @override
  String get saturday => 'Saturday';

  @override
  String get sunday => 'Sunday';

  @override
  String get acceptBookings => 'Accept bookings';

  @override
  String get acceptBookingsOn =>
      'The doctor is visible and accepting new bookings';

  @override
  String get acceptBookingsOff => 'The doctor is currently unavailable';

  @override
  String get bookingsEnabled => 'Bookings have been enabled';

  @override
  String get bookingsDisabled => 'Bookings have been disabled';

  @override
  String get savePrice => 'Save price';

  @override
  String get saving => 'Saving...';

  @override
  String get priceSavedSuccessfully => 'Price saved successfully';

  @override
  String get invalidPrice => 'Please enter a valid price';

  @override
  String get confirmCancelAppointment =>
      'Are you sure you want to cancel this appointment?';

  @override
  String get yesCancel => 'Yes, cancel';

  @override
  String get no => 'Back';

  @override
  String get enterPaidAmount => 'Enter paid amount';

  @override
  String get amountHint => 'Amount';

  @override
  String get currency => 'TND';
}
