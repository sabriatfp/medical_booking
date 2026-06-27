// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'Medical Booking';

  @override
  String get failedToLoadUserData => 'تعذر تحميل بيانات المستخدم';

  @override
  String get invalidUserRole => 'حساب غير صالح، يرجى تسجيل الدخول من جديد';

  @override
  String get scheduleSettings => 'إعدادات التوقيت';

  @override
  String get slotDurationTitle => 'مدة الفحص الطبي';

  @override
  String get slotDurationNotSet => 'لم يتم تحديد مدة الفحص بعد';

  @override
  String minutesLabel(Object minutes) {
    return '$minutes دقيقة';
  }

  @override
  String get enable => 'تفعيل';

  @override
  String get enableFailed => 'تعذر التفعيل';

  @override
  String slotEnabled(Object minutes) {
    return 'تم تفعيل مدة الفحص: $minutes دقيقة';
  }

  @override
  String get weeklyTemplateTitle => 'النموذج الأسبوعي الأساسي';

  @override
  String get startLabel => 'بداية';

  @override
  String get endLabel => 'نهاية';

  @override
  String get customizeUpcomingWeeks => 'تخصيص الأسابيع القادمة (21 يومًا)';

  @override
  String weekLabel(Object index) {
    return 'الأسبوع $index';
  }

  @override
  String get saveSettings => 'حفظ الإعدادات';

  @override
  String get settingsSaved => 'تم حفظ الإعدادات بنجاح';

  @override
  String get userNotFound => 'لا يوجد حساب بهذا البريد الإلكتروني';

  @override
  String get wrongPassword => 'كلمة المرور غير صحيحة';

  @override
  String get userDisabled => 'هذا الحساب معطّل';

  @override
  String get tooManyRequests => 'محاولات كثيرة، حاول لاحقًا';

  @override
  String get from => 'من';

  @override
  String get to => 'إلى';

  @override
  String get selectTime => 'اختيار الوقت';

  @override
  String get doctorSettings => 'إعدادات الطبيب';

  @override
  String get doctorFileNotFound => 'ملف الطبيب غير موجود';

  @override
  String get loadSettingsFailed => 'تعذر تحميل الإعدادات';

  @override
  String get saveChanges => 'حفظ التغييرات';

  @override
  String get subscriptionExpiredMessage =>
      'لقد انتهت مدة اشتراكك. لا يمكنك استخدام خدمات التطبيق حتى يتم تجديد الاشتراك.';

  @override
  String get subscriptionEndedAt => 'تاريخ انتهاء الاشتراك';

  @override
  String get contactAdministration => 'التواصل مع الإدارة';

  @override
  String get contactAdminHint =>
      'يرجى التواصل مع إدارة التطبيق لتجديد الاشتراك';

  @override
  String get resetFilters => 'إعادة تحيين الفلاتر';

  @override
  String get doctorCalendar => 'تقويم الطبيب';

  @override
  String get appointments => 'المواعيد';

  @override
  String get confirmedAppointments => 'المؤكدة';

  @override
  String get cancelledAppointments => 'الملغاة';

  @override
  String get revenue => 'الدخل';

  @override
  String get dayDetails => 'تفاصيل اليوم';

  @override
  String get dayNotes => 'ملاحظات اليوم';

  @override
  String get dayAppointments => 'مواعيد اليوم';

  @override
  String get noAppointments => 'لا توجد مواعيد';

  @override
  String get close => 'إغلاق';

  @override
  String get prevMonth => 'الشهر السابق';

  @override
  String get nextMonth => 'الشهر التالي';

  @override
  String get doctorIdNotFound => 'لم يتم العثور على معرف الطبيب';

  @override
  String get errorFindingDoctor => 'حدث خطأ أثناء تحديد الطبيب';

  @override
  String get errorFindingDoctorId => 'تعذر العثور على معرف الطبيب';

  @override
  String get financeDashboard => 'اللوحة المالية';

  @override
  String get revenueSummary => 'ملخص الأرباح';

  @override
  String get todayRevenue => 'دخل اليوم';

  @override
  String get monthRevenue => 'دخل الشهر';

  @override
  String get totalRevenue => 'إجمالي الأرباح';

  @override
  String get appointmentPerformance => 'أداء المواعيد';

  @override
  String get successRate => 'نسبة النجاح';

  @override
  String get subscription => 'الاشتراك';

  @override
  String get subscriptionStatus => 'حالة الاشتراك';

  @override
  String get subscriptionActive => 'نشط';

  @override
  String get subscriptionTrial => 'تجريبي';

  @override
  String get subscriptionExpired => 'منتهي';

  @override
  String get subscriptionEndsAt => 'ينتهي في';

  @override
  String get subscriptionExpiringSoon =>
      'سينتهي الاشتراك قريبًا — يُنصح بالتجديد.';

  @override
  String get renewSubscription => 'تجديد الاشتراك';

  @override
  String get lastUpdate => 'آخر تحديث';

  @override
  String get comingSoon => 'سيتم إضافة بوابة الدفع قريبًا';

  @override
  String get daysOff => 'أيام الغياب';

  @override
  String get pickDaysOffRange => 'اختيار فترة الغياب';

  @override
  String get reasonOptional => 'سبب الغياب (اختياري)';

  @override
  String get savedDaysOff => 'أيام الغياب المسجلة:';

  @override
  String get daysOffSaved => 'تم تسجيل أيام الغياب';

  @override
  String get dayOffDeleted => 'تم حذف يوم الغياب';

  @override
  String get errorLoadingData => 'خطأ في تحميل البيانات';

  @override
  String get noDaysOff => 'لا توجد أيام غياب';

  @override
  String get deleteDayOff => 'حذف يوم الغياب';

  @override
  String get tapToChoose => 'اضغط للاختيار';

  @override
  String get doctorDashboard => 'لوحة الطبيب';

  @override
  String get doctorNotLinked => 'لم يتم ربط الحساب بطبيب';

  @override
  String get errorResolvingDoctor => 'تعذر استرجاع بيانات الطبيب';

  @override
  String get phoneUnavailable => 'رقم الهاتف غير متوفر';

  @override
  String get callFailed => 'تعذر إجراء المكالمة';

  @override
  String get directRead => 'قراءة مباشرة';

  @override
  String get errorLoadingAppointments => 'خطأ في تحميل المواعيد';

  @override
  String get patient => 'مريض';

  @override
  String get phone => 'الهاتف';

  @override
  String get time => 'الوقت';

  @override
  String get notAvailable => 'غير متاح';

  @override
  String get statusPending => 'قيد الانتظار';

  @override
  String get statusConfirmed => 'مؤكد';

  @override
  String get statusCanceled => 'ملغى';

  @override
  String get confirmAppointment => 'تأكيد الموعد';

  @override
  String get cancelAppointment => 'إلغاء الموعد';

  @override
  String get appointmentConfirmed => 'تم تأكيد الموعد';

  @override
  String get appointmentCanceled => 'تم إلغاء الموعد';

  @override
  String get unexpectedError => 'خطأ غير متوقع';

  @override
  String get tryDirectRead => 'تجربة القراءة المباشرة';

  @override
  String get refreshTryDirect => 'تحديث / قراءة مباشرة';

  @override
  String get all => 'الكل';

  @override
  String get doctorTerms => 'تعهد الطبيب';

  @override
  String get doctorAgreementTitle => 'تعهد الطبيب';

  @override
  String get doctorAgreementDetails =>
      'إقرار وتعهد خاص بحسابات الأطباء\n\nباستخدامك للتطبيق بصفتك طبيبًا، فإنك تقر وتتعهد بما يلي:\n\n1) أنك طبيب مرخّص لك بمزاولة المهنة، وجميع المعلومات التي تدخلها صحيحة ومحدّثة.\n2) تتحمّل كامل المسؤولية القانونية والمهنية عن بياناتك.\n3) التطبيق لا يتحمّل مسؤولية صحة المعلومات التي يضيفها الأطباء.\n4) التطبيق مخصّص لتنظيم المواعيد الطبية فقط.\n5) انتحال صفة طبيب أو إدخال معلومات مضللة قد يعرّض الحساب للحذف والمساءلة القانونية.\n6) يحق لإدارة التطبيق طلب وثائق تثبت الصفة المهنية متى رأت ذلك ضروريًا.\n\nبمتابعتك، فإنك توافق على جميع الشروط أعلاه.';

  @override
  String get doctorAgreementConfirm =>
      'أقرّ بأنني طبيب مرخّص وأتحمّل المسؤولية الكاملة عن صحة المعلومات التي أدخلها.';

  @override
  String get mustAcceptTerms => 'يرجى الموافقة على الشروط أولًا';

  @override
  String get acceptAndContinue => 'أوافق وأواصل';

  @override
  String get back => 'رجوع';

  @override
  String get todayAppointments => 'مواعيد اليوم';

  @override
  String get loadTodayError => 'تعذر تحميل مواعيد اليوم';

  @override
  String get noAppointmentsToday => 'لا توجد مواعيد اليوم';

  @override
  String get checkedInShort => 'حاضر';

  @override
  String get checkIn => 'تسجيل حضور';

  @override
  String get checkedIn => 'تم تسجيل الحضور';

  @override
  String get noShow => 'لم يحضر';

  @override
  String get noShowSet => 'تم تسجيل الحالة: لم يحضر';

  @override
  String get newPasswordOptional => 'كلمة المرور الجديدة (اختياري)';

  @override
  String get mustLogin => 'يجب تسجيل الدخول';

  @override
  String get mustLoginFirst => 'يجب تسجيل الدخول أولًا';

  @override
  String get cannotBookThisDay => 'لا يمكن الحجز في هذا اليوم';

  @override
  String get doctorDayOff => 'الطبيب في عطلة';

  @override
  String get dayNotAvailable => 'اليوم غير متاح';

  @override
  String get dayIsFull => 'اليوم ممتلئ';

  @override
  String get timeNotAvailable => 'الوقت غير متاح';

  @override
  String get cannotBookPastTime => 'لا يمكن الحجز في وقت سابق';

  @override
  String get bookingSent => 'تم إرسال طلب الحجز';

  @override
  String get invalidSlot => 'الوقت المختار غير صالح';

  @override
  String get deleteAppointment => 'حذف الموعد';

  @override
  String get appointmentDeleted => 'تم حذف الموعد نهائيًا';

  @override
  String get emailInUse => 'البريد الإلكتروني مستخدم بالفعل';

  @override
  String get weakPassword => 'كلمة المرور ضعيفة جدًا';

  @override
  String get registerPatient => 'تسجيل مريض';

  @override
  String get register => 'تسجيل';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get enterValidName => 'أدخل اسمًا صحيحًا';

  @override
  String get enterValidPassword => 'أدخل كلمة مرور صحيحة';

  @override
  String get phoneNumber => 'رقم الهاتف';

  @override
  String get enterValidPhone => 'أدخل رقم هاتف صحيح';

  @override
  String get phoneUpdated => 'تم تحديث رقم الهاتف بنجاح';

  @override
  String get createAccount => 'إنشاء حساب';

  @override
  String get appBarCreateAccount => 'إنشاء حساب';

  @override
  String get chooseAccountType => 'اختر نوع الحساب';

  @override
  String get patientOrDoctor => 'هل أنت مريض أم طبيب؟';

  @override
  String get registerDoctor => 'تسجيل طبيب';

  @override
  String get dataLoadError => 'تعذر تحميل البيانات';

  @override
  String get wrongCurrentPassword => 'كلمة المرور الحالية غير صحيحة';

  @override
  String get reauthFailed => 'فشل إعادة المصادقة';

  @override
  String get noChangesToSave => 'لا توجد تغييرات';

  @override
  String get savedSuccessfully => 'تم الحفظ بنجاح';

  @override
  String get saveFailed => 'تعذر الحفظ';

  @override
  String get patientSettings => 'إعدادات المريض';

  @override
  String get emailExample => 'example@mail.com';

  @override
  String get verifyBySMS => 'التحقق عبر SMS';

  @override
  String get notificationSettings => 'إعدادات الإشعارات';

  @override
  String get notificationSettingsDesc => 'إدارة إعدادات الإشعارات';

  @override
  String get securityNote => 'ملاحظة: يتم استخدام رقم الهاتف لأغراض الأمان';

  @override
  String get enterPhoneFirst => 'أدخل رقم الهاتف أولًا';

  @override
  String get autoVerifyFailed => 'فشل التحقق التلقائي';

  @override
  String get codeSendFailed => 'فشل إرسال الكود';

  @override
  String get codeSentSuccessfully => 'تم إرسال الكود';

  @override
  String get enterSMSCode => 'أدخل رمز التحقق';

  @override
  String get verifyFailed => 'فشل التحقق';

  @override
  String get phoneVerification => 'التحقق عبر الهاتف';

  @override
  String get sending => 'جاري الإرسال...';

  @override
  String get sendSMSCode => 'إرسال رمز SMS';

  @override
  String get smsCode => 'رمز SMS';

  @override
  String get verifying => 'جاري التحقق...';

  @override
  String get confirmCode => 'تأكيد الرمز';

  @override
  String get notificationsEnabled => 'الإشعارات مفعلة';

  @override
  String get notificationsEnabledMessage => 'سيتم إرسال الإشعارات';

  @override
  String get notificationsDisabled => 'الإشعارات معطلة';

  @override
  String get testNotificationTitle => 'إشعار تجريبي';

  @override
  String get testNotificationMessage => 'هذا إشعار للتجربة';

  @override
  String get allowNotifications => 'السماح بالإشعارات';

  @override
  String get allowNotificationsDescription => 'تفعيل الإشعارات لهذا الجهاز';

  @override
  String get sendTestNotification => 'إرسال إشعار تجريبي';

  @override
  String get fcmDisabledNote => 'خدمة FCM غير مفعلة';

  @override
  String get notLoggedIn => 'غير مسجل الدخول';

  @override
  String get failedToLoadAppointments => 'فشل تحميل المواعيد';

  @override
  String get noAppointmentsYet => 'لا توجد مواعيد بعد';

  @override
  String get userDataNotFound => 'بيانات المستخدم غير موجودة';

  @override
  String get loginError => 'خطأ في تسجيل الدخول';

  @override
  String get language => 'اللغة';

  @override
  String get secretaryHint => 'هذه الصفحة مخصصة للسكرتير';

  @override
  String get welcomeDoctor => 'مرحبًا دكتور';

  @override
  String get defaultDoctor => 'الطبيب';

  @override
  String get welcomeUser => 'مرحبًا';

  @override
  String get defaultUser => 'المستخدم';

  @override
  String get home => 'الرئيسية';

  @override
  String get changeLanguage => 'تغيير اللغة';

  @override
  String get patientServices => 'خدمات المرضى';

  @override
  String get doctorsList => 'قائمة الأطباء';

  @override
  String get dashboard => 'لوحة التحكم';

  @override
  String get calendar => 'التقويم';

  @override
  String get finance => 'المالية';

  @override
  String get failedToLoadDoctors => 'فشل تحميل قائمة الأطباء';

  @override
  String get noDoctorsAvailable => 'لا يوجد أطباء متاحون';

  @override
  String get chooseDay => 'اختر يومًا';

  @override
  String get noAvailableAppointments => 'لا توجد مواعيد متاحة';

  @override
  String get available => 'متاح';

  @override
  String get full => 'مكتمل';

  @override
  String get address => 'العنوان';

  @override
  String get sessionPrice => 'سعر الجلسة';

  @override
  String get requested => 'تم الطلب';

  @override
  String get slotAlreadyTaken => 'الموعد محجوز بالفعل';

  @override
  String get codeInactive => 'الكود غير مفعّل';

  @override
  String get codeExpired => 'الكود منتهي';

  @override
  String get codeIncomplete => 'الكود غير مكتمل';

  @override
  String get codeNotFound => 'الكود غير موجود';

  @override
  String get connectionError => 'خطأ في الاتصال';

  @override
  String get filter => 'تصفية';

  @override
  String get syncFailed => 'فشل المزامنة';

  @override
  String get active => 'نشط';

  @override
  String get inactive => 'غير نشط';

  @override
  String get expired => 'منتهي';

  @override
  String get expiringSoon => 'سينتهي قريبًا';

  @override
  String get noDoctorId => 'لا يوجد معرف طبيب';

  @override
  String get activatedUntil => 'مفعل حتى';

  @override
  String get refresh => 'تحديث';

  @override
  String get noResults => 'لا توجد نتائج';

  @override
  String get cannotConfirmPastAppointment => 'لا يمكن تأكيد موعد في تاريخ سابق';

  @override
  String get reportMarkedProcessed => 'تم تعليم البلاغ كمُعالج';

  @override
  String get reportMarkedNew => 'تم تعليم البلاغ كجديد';

  @override
  String get type => 'النوع';

  @override
  String get status => 'الحالة';

  @override
  String get date => 'التاريخ';

  @override
  String get text => 'النص';

  @override
  String get delete => 'حذف';

  @override
  String get cancel => 'إلغاء';

  @override
  String get confirm => 'تأكيد';

  @override
  String get deleteAccountWarning =>
      'هل أنت متأكد من حذف الحساب؟ لا يمكن التراجع عن هذه العملية.';

  @override
  String get deleteAccount => 'حذف الحساب';

  @override
  String get chooseAppointment => 'اختيار الموعد';

  @override
  String get loadingAppointments => 'جاري تحميل المواعيد...';

  @override
  String get loadingTakingLong => 'التحميل يستغرق وقتاً...';

  @override
  String get save => 'حفظ';

  @override
  String get enterCode => 'أدخل الكود';

  @override
  String get noLoggedUser => 'لا يوجد مستخدم مسجل دخول';

  @override
  String get insufficientPermissions => 'صلاحيات غير كافية';

  @override
  String get adminCheckFailed => 'فشل التحقق من صلاحيات المدير';

  @override
  String syncCompleted(Object processed, Object updated) {
    return '$processed تمت معالجتها، $updated تم تحديثها';
  }

  @override
  String get manageSubscriptions => 'إدارة الاشتراكات';

  @override
  String get manageSubscriptionsSubtitle => 'مراجعة وتجديد الاشتراكات';

  @override
  String get reports => 'التقارير';

  @override
  String get reportsSubtitle => 'تقارير النظام والبلاغات';

  @override
  String get adminDashboard => 'لوحة المدير';

  @override
  String get tools => 'الأدوات';

  @override
  String get syncDoctorSubscriptions => 'مزامنة اشتراكات الأطباء';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get customActivation => 'تفعيل مخصص';

  @override
  String get daysCount => 'عدد الأيام';

  @override
  String get invalidDays => 'عدد الأيام غير صالح';

  @override
  String get daysTooLarge => 'الرقم كبير جدًا';

  @override
  String get activate => 'تفعيل';

  @override
  String get deactivateSubscription => 'إلغاء التفعيل';

  @override
  String get confirmDeactivate => 'هل تريد إلغاء التفعيل؟';

  @override
  String get deactivate => 'إلغاء';

  @override
  String get deactivated => 'تم إلغاء التفعيل';

  @override
  String get activate7 => 'تفعيل 7 أيام';

  @override
  String get activate30 => 'تفعيل 30 يوم';

  @override
  String get activate90 => 'تفعيل 90 يوم';

  @override
  String get actionFailed => 'فشلت العملية';

  @override
  String get adminSubscriptions => 'اشتراكات الإدارة';

  @override
  String get searchByNameEmail => 'بحث بالاسم أو البريد';

  @override
  String get errorLoading => 'خطأ في التحميل';

  @override
  String get noName => 'بدون اسم';

  @override
  String get deleteReport => 'حذف البلاغ';

  @override
  String get deleteReportConfirm => 'هل تريد حذف البلاغ؟';

  @override
  String get deletedSuccessfully => 'تم الحذف بنجاح';

  @override
  String get pickDateRange => 'اختر المدة الزمنية';

  @override
  String get unknown => 'غير معروف';

  @override
  String get processed => 'معالج';

  @override
  String get newReport => 'جديد';

  @override
  String get reportDetails => 'تفاصيل البلاغ';

  @override
  String get senderEmail => 'البريد المرسل';

  @override
  String get noteStatusChangeHint => 'يمكنك تغيير حالة البلاغ من القائمة';

  @override
  String get markProcessed => 'وضع كمعالج';

  @override
  String get markNew => 'وضع كجديد';

  @override
  String get report => 'بلاغ';

  @override
  String get sender => 'المرسل';

  @override
  String get clearDateRange => 'حذف المدة';

  @override
  String get invalidEmail => 'البريد الإلكتروني غير صالح';

  @override
  String get error => 'خطأ';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get enterEmail => 'أدخل البريد الإلكتروني';

  @override
  String get password6Chars => 'كلمة المرور يجب أن تحتوي 6 أحرف على الأقل';

  @override
  String get myAppointments => 'مواعيدي';

  @override
  String get doctor => 'الطبيب';

  @override
  String get specialty => 'التخصص';

  @override
  String get password => 'كلمة المرور';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get createNewAccount => 'إنشاء حساب جديد';

  @override
  String get chooseLanguage => 'اختر اللغة';

  @override
  String get arabic => 'العربية';

  @override
  String get french => 'الفرنسية';

  @override
  String get secretarySpace => 'مساحة السكرتير';

  @override
  String get appointmentsToday => 'مواعيد اليوم';

  @override
  String get createSecretaryCode => 'إنشاء رمز سكرتير';

  @override
  String get optionalExpiry => 'تاريخ انتهاء (اختياري)';

  @override
  String get noExpiry => 'بدون انتهاء';

  @override
  String get expiresAt => 'انتهاء في';

  @override
  String get pickDate => 'اختر التاريخ';

  @override
  String get create => 'إنشاء';

  @override
  String get userNotLogged => 'المستخدم غير مسجل الدخول';

  @override
  String get noPermissionForThisDoctor => 'ليست لديك صلاحية لهذا الطبيب';

  @override
  String get expiryMustBeFuture => 'يجب أن يكون تاريخ الانتهاء مستقبليًا';

  @override
  String get codeCreated => 'تم إنشاء الكود';

  @override
  String get generalFailure => 'حدث خطأ';

  @override
  String get permissionDenied => 'تم رفض الإذن';

  @override
  String get networkError => 'خطأ في الشبكة';

  @override
  String get codeAlreadyExists => 'الكود موجود مسبقًا';

  @override
  String get updateFailed => 'فشل التحديث';

  @override
  String get expiryUpdated => 'تم تحديث تاريخ الانتهاء';

  @override
  String get expiryRemoved => 'تم حذف تاريخ الانتهاء';

  @override
  String get deleteCode => 'حذف الكود';

  @override
  String get deleteCodeConfirm => 'هل تريد حذف الكود؟';

  @override
  String get codeDeleted => 'تم حذف الكود';

  @override
  String get statusInactive => 'غير نشط';

  @override
  String get statusExpired => 'منتهي';

  @override
  String get statusActive => 'نشط';

  @override
  String get secretaryCodes => 'أكواد السكرتارية';

  @override
  String get createNewCode => 'إنشاء كود جديد';

  @override
  String get createCode => 'إنشاء الكود';

  @override
  String get loadingFailed => 'فشل التحميل';

  @override
  String get copyCode => 'نسخ الكود';

  @override
  String get copied => 'تم النسخ';

  @override
  String get createdAt => 'تم الإنشاء في';

  @override
  String get editExpiry => 'تعديل تاريخ الانتهاء';

  @override
  String get removeExpiry => 'حذف تاريخ الانتهاء';

  @override
  String get disable => 'تعطيل';

  @override
  String get noSecretaryCodes => 'لا توجد أكواد سكرتير';

  @override
  String get secretaryQrCode => 'رمز QR للسكرتير';

  @override
  String get qrGenerationFailed => 'فشل إنشاء رمز QR';

  @override
  String get done => 'تم';

  @override
  String get doctorAccountCreated => 'تم إنشاء حساب الطبيب';

  @override
  String get doctorRegisterTitle => 'تسجيل طبيب';

  @override
  String get enterSpecialty => 'أدخل التخصص';

  @override
  String get consultationPrice => 'سعر الفحص';

  @override
  String get createDoctorAccount => 'إنشاء حساب طبيب';

  @override
  String get operationFailed => 'فشلت العملية';

  @override
  String get codeVerificationFailed => 'فشل التحقق من الكود';

  @override
  String get authFailed => 'فشل المصادقة';

  @override
  String get anonymousAuthNotEnabled => 'تسجيل الدخول المجهول غير مفعل';

  @override
  String get permissionDeniedSessions => 'ليس لديك إذن للوصول إلى الجلسات';

  @override
  String get secretaryEnterCodeText => 'أدخل رمز السكرتير';

  @override
  String get secretaryCode => 'رمز السكرتير';

  @override
  String get secretaryCodeExample => 'مثال: ABC123';

  @override
  String get searchReports => 'بحث في البلاغات';

  @override
  String get uidUnavailable => 'المعرف غير متاح';

  @override
  String get noAccess => 'لا تملك صلاحية الدخول';

  @override
  String get notAdminAccount => 'هذا الحساب ليس مديرًا';

  @override
  String get accountDisabled => 'الحساب معطّل';

  @override
  String get loginFailed => 'فشل تسجيل الدخول';

  @override
  String get emailOrPasswordWrong => 'البريد أو كلمة المرور غير صحيحة';

  @override
  String get enterEmailFirst => 'أدخل البريد أولاً';

  @override
  String get resetLinkSent => 'تم إرسال رابط الاستعادة';

  @override
  String get resetFailed => 'فشل إرسال رابط الاستعادة';

  @override
  String get adminLogin => 'تسجيل دخول المدير';

  @override
  String get adminEntry => 'دخول المدير';

  @override
  String get invalidEmailFormat => 'صيغة البريد الإلكتروني غير صحيحة';

  @override
  String get show => 'إظهار';

  @override
  String get hide => 'إخفاء';

  @override
  String get noPermission => 'ليست لديك صلاحية الدخول';

  @override
  String get enterPassword => 'أدخل كلمة المرور';

  @override
  String get passwordShort => 'كلمة المرور قصيرة جدًا';

  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get adminScreenHint => 'هذه الشاشة مخصصة للمدير';

  @override
  String get deleteFailed => 'فشل الحذف';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get manageProfile => 'إدارة الملف الشخصي';

  @override
  String get changePassword => 'تغيير كلمة المرور';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get secretaryManagement => 'إدارة السكرتارية';

  @override
  String get manageSecretary => 'إدارة السكرتير';

  @override
  String get aboutApp => 'حول التطبيق';

  @override
  String get emailUpdated => 'تم تحديث البريد الإلكتروني بنجاح';

  @override
  String get passwordUpdated => 'تم تحديث كلمة المرور بنجاح';

  @override
  String get showPrice => 'إظهار السعر';

  @override
  String get updateEmail => 'تحديث البريد';

  @override
  String get updatePassword => 'تحديث كلمة المرور';

  @override
  String get governorate => 'الولاية';

  @override
  String get chooseGovernorate => 'الرجاء اختيار الولاية';

  @override
  String get chooseSpecialty => 'الرجاء اختيار الاختصاص';

  @override
  String get searchDoctors => 'البحث عن طبيب';

  @override
  String get search => 'بحث';

  @override
  String get noResultsFound => 'لا توجد نتائج';

  @override
  String get enterAddress => 'الرجاء إدخال العنوان';

  @override
  String get passwordsNotMatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get doctorPrefix => 'د.';

  @override
  String get bookAppointment => 'احجز موعد';

  @override
  String get doctorNotAvailable => 'الطبيب غير متاح حاليًا';

  @override
  String get currentPasswordRequired =>
      'يرجى إدخال كلمة المرور الحالية لتأكيد تغيير البريد الإلكتروني';

  @override
  String get currentPassword => 'كلمة المرور الحالية';

  @override
  String get newPassword => 'كلمة المرور الجديدة';

  @override
  String get confirmNewPassword => 'تأكيد كلمة المرور الجديدة';

  @override
  String get passwordsDoNotMatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get passwordTooShort => 'كلمة المرور ضعيفة جدًا';

  @override
  String get currentPasswordIncorrect => 'كلمة المرور الحالية غير صحيحة';

  @override
  String get subscriptionRequests => 'طلبات تجديد الاشتراك';

  @override
  String get noSubscriptionRequests => 'لا توجد طلبات حالياً';

  @override
  String get requestDate => 'تاريخ الطلب';

  @override
  String get unknownDoctor => 'طبيب غير معروف';

  @override
  String get reject => 'رفض';

  @override
  String get subscriptionRequestsSubtitle =>
      'طلبات تجديد الاشتراك المرسلة من الأطباء';

  @override
  String get requestSubscriptionRenewal => 'طلب تجديد الاشتراك';

  @override
  String get subscriptionRequestSent =>
      'تم إرسال طلب تجديد الاشتراك، سيتم التواصل معك قريبًا';

  @override
  String get subscriptionRequestAlreadySent =>
      'لقد أرسلت طلب تجديد من قبل، يرجى انتظار رد الإدارة';

  @override
  String get noCodes => 'لا توجد أكواد';

  @override
  String get optionalExpiryDate => 'إضافة تاريخ انتهاء (اختياري)';

  @override
  String get chooseDate => 'اختيار تاريخ';

  @override
  String get expiresOn => 'ينتهي في';

  @override
  String get codeNotValid => 'الكود غير صحيح';

  @override
  String get confirmDelete => 'هل أنت متأكد من الحذف؟';

  @override
  String get invalidCodeFormat => 'صيغة الكود غير صحيحة';

  @override
  String get copy => 'نسخ';

  @override
  String get enterSecretaryCode => 'أدخل كود السكرتير الذي زوّدك به الطبيب';

  @override
  String get usedBy => 'استُعمل من قبل';

  @override
  String get monday => 'الإثنين';

  @override
  String get tuesday => 'الثلاثاء';

  @override
  String get wednesday => 'الأربعاء';

  @override
  String get thursday => 'الخميس';

  @override
  String get friday => 'الجمعة';

  @override
  String get saturday => 'السبت';

  @override
  String get sunday => 'الأحد';

  @override
  String get acceptBookings => 'استقبال الحجوزات';

  @override
  String get acceptBookingsOn => 'الطبيب ظاهر ويقبل حجوزات جديدة';

  @override
  String get acceptBookingsOff => 'الطبيب غير متاح حاليًا';

  @override
  String get bookingsEnabled => 'تم تفعيل استقبال الحجوزات';

  @override
  String get bookingsDisabled => 'تم إيقاف استقبال الحجوزات';

  @override
  String get savePrice => 'حفظ السعر';

  @override
  String get saving => 'جاري الحفظ...';

  @override
  String get priceSavedSuccessfully => 'تم حفظ السعر بنجاح';

  @override
  String get invalidPrice => 'الرجاء إدخال سعر صحيح';

  @override
  String get confirmCancelAppointment => 'هل أنت متأكد من إلغاء هذا الموعد؟';

  @override
  String get yesCancel => 'نعم، إلغاء';

  @override
  String get no => 'تراجع';

  @override
  String get enterPaidAmount => 'إدخال المبلغ المدفوع';

  @override
  String get amountHint => 'المبلغ';

  @override
  String get currency => 'دت';

  @override
  String get subscriptionExpiredDoctor =>
      'هذا الطبيب غير متاح مؤقتًا لانتهاء الاشتراك';

  @override
  String remainingDays(Object days) {
    return 'متبقي $days يوم';
  }

  @override
  String get appointmentDetails => 'تفاصيل الموعد ';

  @override
  String get callPatient => 'اتصال بالمريض';

  @override
  String get doctorNotes => 'ملاحظات الطبيب';

  @override
  String get visitType => 'نوع الموعد';

  @override
  String get consultation => 'استشارة';

  @override
  String get review => 'مراجعة';

  @override
  String get checkup => 'فحص';

  @override
  String get enterData => 'الرجاء إدخال بيانات';

  @override
  String get hasReport => 'يوجد تقرير';

  @override
  String get myReports => 'تقاريري';

  @override
  String get openReports => 'التقارير المفتوحة';

  @override
  String get sendReport => 'إرسال تقرير';

  @override
  String get bug => 'خلل';

  @override
  String get complaint => 'شكوى';

  @override
  String get suggestion => 'اقتراح';

  @override
  String get describeProblem => 'صف المشكلة...';

  @override
  String get send => 'إرسال';

  @override
  String get noReports => 'لا توجد تقارير بعد';

  @override
  String get invalidInput => 'يرجى إدخال رسالة';

  @override
  String get reportSentSuccessfully => 'تم إرسال التقرير بنجاح';

  @override
  String get payment => 'الدفع';

  @override
  String get contactUs => 'اتصل بنا';

  @override
  String get replyAdded => 'تمت إضافة الرد';

  @override
  String get adminReply => 'رد الإدارة:';

  @override
  String get english => 'الإنجليزية';

  @override
  String get appDescription => 'تطبيق لحجز المواعيد الطبية.';

  @override
  String get adminMaintenance => 'صيانة الإدارة';

  @override
  String get resetAppointments => 'حذف المواعيد';

  @override
  String get resetSlots => 'حذف الأوقات';

  @override
  String get resetTransactions => 'حذف المعاملات';

  @override
  String get dangerZone => 'منطقة خطرة';

  @override
  String get fullReset => 'إعادة ضبط كاملة';

  @override
  String get warningTitle => 'تحذير';

  @override
  String get warningMessage => 'سيتم حذف جميع البيانات. هل أنت متأكد؟';

  @override
  String get continueBtn => 'متابعة';

  @override
  String get finalConfirm => 'تأكيد نهائي';

  @override
  String get finalMessage => 'آخر فرصة! سيتم حذف كل المواعيد والتاريخ.';

  @override
  String get resetDone => 'تمت إعادة الضبط';

  @override
  String get appointmentsCleared => 'تم حذف المواعيد';

  @override
  String get slotsCleared => 'تم حذف الأوقات';

  @override
  String get transactionsCleared => 'تم حذف المعاملات';

  @override
  String get secretMode => 'الوضع السري...';

  @override
  String get systemTools => 'أدوات النظام';

  @override
  String get systemToolsSubtitle => 'أدوات الصيانة والتشخيص';
}
