import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated_l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ar, this message translates to:
  /// **'Medical Booking'**
  String get appTitle;

  /// No description provided for @failedToLoadUserData.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل بيانات المستخدم'**
  String get failedToLoadUserData;

  /// No description provided for @invalidUserRole.
  ///
  /// In ar, this message translates to:
  /// **'حساب غير صالح، يرجى تسجيل الدخول من جديد'**
  String get invalidUserRole;

  /// No description provided for @scheduleSettings.
  ///
  /// In ar, this message translates to:
  /// **'إعدادات التوقيت'**
  String get scheduleSettings;

  /// No description provided for @slotDurationTitle.
  ///
  /// In ar, this message translates to:
  /// **'مدة الفحص الطبي'**
  String get slotDurationTitle;

  /// No description provided for @slotDurationNotSet.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم تحديد مدة الفحص بعد'**
  String get slotDurationNotSet;

  /// No description provided for @minutesLabel.
  ///
  /// In ar, this message translates to:
  /// **'{minutes} دقيقة'**
  String minutesLabel(Object minutes);

  /// No description provided for @enable.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل'**
  String get enable;

  /// No description provided for @enableFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر التفعيل'**
  String get enableFailed;

  /// No description provided for @slotEnabled.
  ///
  /// In ar, this message translates to:
  /// **'تم تفعيل مدة الفحص: {minutes} دقيقة'**
  String slotEnabled(Object minutes);

  /// No description provided for @weeklyTemplateTitle.
  ///
  /// In ar, this message translates to:
  /// **'النموذج الأسبوعي الأساسي'**
  String get weeklyTemplateTitle;

  /// No description provided for @startLabel.
  ///
  /// In ar, this message translates to:
  /// **'بداية'**
  String get startLabel;

  /// No description provided for @endLabel.
  ///
  /// In ar, this message translates to:
  /// **'نهاية'**
  String get endLabel;

  /// No description provided for @customizeUpcomingWeeks.
  ///
  /// In ar, this message translates to:
  /// **'تخصيص الأسابيع القادمة (21 يومًا)'**
  String get customizeUpcomingWeeks;

  /// No description provided for @weekLabel.
  ///
  /// In ar, this message translates to:
  /// **'الأسبوع {index}'**
  String weekLabel(Object index);

  /// No description provided for @saveSettings.
  ///
  /// In ar, this message translates to:
  /// **'حفظ الإعدادات'**
  String get saveSettings;

  /// No description provided for @settingsSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ الإعدادات بنجاح'**
  String get settingsSaved;

  /// No description provided for @userNotFound.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد حساب بهذا البريد الإلكتروني'**
  String get userNotFound;

  /// No description provided for @wrongPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور غير صحيحة'**
  String get wrongPassword;

  /// No description provided for @userDisabled.
  ///
  /// In ar, this message translates to:
  /// **'هذا الحساب معطّل'**
  String get userDisabled;

  /// No description provided for @tooManyRequests.
  ///
  /// In ar, this message translates to:
  /// **'محاولات كثيرة، حاول لاحقًا'**
  String get tooManyRequests;

  /// No description provided for @from.
  ///
  /// In ar, this message translates to:
  /// **'من'**
  String get from;

  /// No description provided for @to.
  ///
  /// In ar, this message translates to:
  /// **'إلى'**
  String get to;

  /// No description provided for @selectTime.
  ///
  /// In ar, this message translates to:
  /// **'اختيار الوقت'**
  String get selectTime;

  /// No description provided for @doctorSettings.
  ///
  /// In ar, this message translates to:
  /// **'إعدادات الطبيب'**
  String get doctorSettings;

  /// No description provided for @doctorFileNotFound.
  ///
  /// In ar, this message translates to:
  /// **'ملف الطبيب غير موجود'**
  String get doctorFileNotFound;

  /// No description provided for @loadSettingsFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل الإعدادات'**
  String get loadSettingsFailed;

  /// No description provided for @saveChanges.
  ///
  /// In ar, this message translates to:
  /// **'حفظ التغييرات'**
  String get saveChanges;

  /// No description provided for @subscriptionExpiredMessage.
  ///
  /// In ar, this message translates to:
  /// **'لقد انتهت مدة اشتراكك. لا يمكنك استخدام خدمات التطبيق حتى يتم تجديد الاشتراك.'**
  String get subscriptionExpiredMessage;

  /// No description provided for @subscriptionEndedAt.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ انتهاء الاشتراك'**
  String get subscriptionEndedAt;

  /// No description provided for @contactAdministration.
  ///
  /// In ar, this message translates to:
  /// **'التواصل مع الإدارة'**
  String get contactAdministration;

  /// No description provided for @contactAdminHint.
  ///
  /// In ar, this message translates to:
  /// **'يرجى التواصل مع إدارة التطبيق لتجديد الاشتراك'**
  String get contactAdminHint;

  /// No description provided for @resetFilters.
  ///
  /// In ar, this message translates to:
  /// **'إعادة تحيين الفلاتر'**
  String get resetFilters;

  /// No description provided for @doctorCalendar.
  ///
  /// In ar, this message translates to:
  /// **'تقويم الطبيب'**
  String get doctorCalendar;

  /// No description provided for @appointments.
  ///
  /// In ar, this message translates to:
  /// **'المواعيد'**
  String get appointments;

  /// No description provided for @confirmedAppointments.
  ///
  /// In ar, this message translates to:
  /// **'المؤكدة'**
  String get confirmedAppointments;

  /// No description provided for @cancelledAppointments.
  ///
  /// In ar, this message translates to:
  /// **'الملغاة'**
  String get cancelledAppointments;

  /// No description provided for @revenue.
  ///
  /// In ar, this message translates to:
  /// **'الدخل'**
  String get revenue;

  /// No description provided for @dayDetails.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل اليوم'**
  String get dayDetails;

  /// No description provided for @dayNotes.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات اليوم'**
  String get dayNotes;

  /// No description provided for @dayAppointments.
  ///
  /// In ar, this message translates to:
  /// **'مواعيد اليوم'**
  String get dayAppointments;

  /// No description provided for @noAppointments.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مواعيد'**
  String get noAppointments;

  /// No description provided for @close.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get close;

  /// No description provided for @prevMonth.
  ///
  /// In ar, this message translates to:
  /// **'الشهر السابق'**
  String get prevMonth;

  /// No description provided for @nextMonth.
  ///
  /// In ar, this message translates to:
  /// **'الشهر التالي'**
  String get nextMonth;

  /// No description provided for @doctorIdNotFound.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم العثور على معرف الطبيب'**
  String get doctorIdNotFound;

  /// No description provided for @errorFindingDoctor.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ أثناء تحديد الطبيب'**
  String get errorFindingDoctor;

  /// No description provided for @errorFindingDoctorId.
  ///
  /// In ar, this message translates to:
  /// **'تعذر العثور على معرف الطبيب'**
  String get errorFindingDoctorId;

  /// No description provided for @financeDashboard.
  ///
  /// In ar, this message translates to:
  /// **'اللوحة المالية'**
  String get financeDashboard;

  /// No description provided for @revenueSummary.
  ///
  /// In ar, this message translates to:
  /// **'ملخص الأرباح'**
  String get revenueSummary;

  /// No description provided for @todayRevenue.
  ///
  /// In ar, this message translates to:
  /// **'دخل اليوم'**
  String get todayRevenue;

  /// No description provided for @monthRevenue.
  ///
  /// In ar, this message translates to:
  /// **'دخل الشهر'**
  String get monthRevenue;

  /// No description provided for @totalRevenue.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي الأرباح'**
  String get totalRevenue;

  /// No description provided for @appointmentPerformance.
  ///
  /// In ar, this message translates to:
  /// **'أداء المواعيد'**
  String get appointmentPerformance;

  /// No description provided for @successRate.
  ///
  /// In ar, this message translates to:
  /// **'نسبة النجاح'**
  String get successRate;

  /// No description provided for @subscription.
  ///
  /// In ar, this message translates to:
  /// **'الاشتراك'**
  String get subscription;

  /// No description provided for @subscriptionStatus.
  ///
  /// In ar, this message translates to:
  /// **'حالة الاشتراك'**
  String get subscriptionStatus;

  /// No description provided for @subscriptionActive.
  ///
  /// In ar, this message translates to:
  /// **'نشط'**
  String get subscriptionActive;

  /// No description provided for @subscriptionTrial.
  ///
  /// In ar, this message translates to:
  /// **'تجريبي'**
  String get subscriptionTrial;

  /// No description provided for @subscriptionExpired.
  ///
  /// In ar, this message translates to:
  /// **'منتهي'**
  String get subscriptionExpired;

  /// No description provided for @subscriptionEndsAt.
  ///
  /// In ar, this message translates to:
  /// **'ينتهي في'**
  String get subscriptionEndsAt;

  /// No description provided for @subscriptionExpiringSoon.
  ///
  /// In ar, this message translates to:
  /// **'سينتهي الاشتراك قريبًا — يُنصح بالتجديد.'**
  String get subscriptionExpiringSoon;

  /// No description provided for @renewSubscription.
  ///
  /// In ar, this message translates to:
  /// **'تجديد الاشتراك'**
  String get renewSubscription;

  /// No description provided for @lastUpdate.
  ///
  /// In ar, this message translates to:
  /// **'آخر تحديث'**
  String get lastUpdate;

  /// No description provided for @comingSoon.
  ///
  /// In ar, this message translates to:
  /// **'سيتم إضافة بوابة الدفع قريبًا'**
  String get comingSoon;

  /// No description provided for @daysOff.
  ///
  /// In ar, this message translates to:
  /// **'أيام الغياب'**
  String get daysOff;

  /// No description provided for @pickDaysOffRange.
  ///
  /// In ar, this message translates to:
  /// **'اختيار فترة الغياب'**
  String get pickDaysOffRange;

  /// No description provided for @reasonOptional.
  ///
  /// In ar, this message translates to:
  /// **'سبب الغياب (اختياري)'**
  String get reasonOptional;

  /// No description provided for @savedDaysOff.
  ///
  /// In ar, this message translates to:
  /// **'أيام الغياب المسجلة:'**
  String get savedDaysOff;

  /// No description provided for @daysOffSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل أيام الغياب'**
  String get daysOffSaved;

  /// No description provided for @dayOffDeleted.
  ///
  /// In ar, this message translates to:
  /// **'تم حذف يوم الغياب'**
  String get dayOffDeleted;

  /// No description provided for @errorLoadingData.
  ///
  /// In ar, this message translates to:
  /// **'خطأ في تحميل البيانات'**
  String get errorLoadingData;

  /// No description provided for @noDaysOff.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد أيام غياب'**
  String get noDaysOff;

  /// No description provided for @deleteDayOff.
  ///
  /// In ar, this message translates to:
  /// **'حذف يوم الغياب'**
  String get deleteDayOff;

  /// No description provided for @tapToChoose.
  ///
  /// In ar, this message translates to:
  /// **'اضغط للاختيار'**
  String get tapToChoose;

  /// No description provided for @doctorDashboard.
  ///
  /// In ar, this message translates to:
  /// **'لوحة الطبيب'**
  String get doctorDashboard;

  /// No description provided for @doctorNotLinked.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم ربط الحساب بطبيب'**
  String get doctorNotLinked;

  /// No description provided for @errorResolvingDoctor.
  ///
  /// In ar, this message translates to:
  /// **'تعذر استرجاع بيانات الطبيب'**
  String get errorResolvingDoctor;

  /// No description provided for @phoneUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف غير متوفر'**
  String get phoneUnavailable;

  /// No description provided for @callFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر إجراء المكالمة'**
  String get callFailed;

  /// No description provided for @directRead.
  ///
  /// In ar, this message translates to:
  /// **'قراءة مباشرة'**
  String get directRead;

  /// No description provided for @errorLoadingAppointments.
  ///
  /// In ar, this message translates to:
  /// **'خطأ في تحميل المواعيد'**
  String get errorLoadingAppointments;

  /// No description provided for @patient.
  ///
  /// In ar, this message translates to:
  /// **'مريض'**
  String get patient;

  /// No description provided for @phone.
  ///
  /// In ar, this message translates to:
  /// **'الهاتف'**
  String get phone;

  /// No description provided for @time.
  ///
  /// In ar, this message translates to:
  /// **'الوقت'**
  String get time;

  /// No description provided for @notAvailable.
  ///
  /// In ar, this message translates to:
  /// **'غير متاح'**
  String get notAvailable;

  /// No description provided for @statusPending.
  ///
  /// In ar, this message translates to:
  /// **'قيد الانتظار'**
  String get statusPending;

  /// No description provided for @statusConfirmed.
  ///
  /// In ar, this message translates to:
  /// **'مؤكد'**
  String get statusConfirmed;

  /// No description provided for @statusCanceled.
  ///
  /// In ar, this message translates to:
  /// **'ملغى'**
  String get statusCanceled;

  /// No description provided for @confirmAppointment.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الموعد'**
  String get confirmAppointment;

  /// No description provided for @cancelAppointment.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الموعد'**
  String get cancelAppointment;

  /// No description provided for @appointmentConfirmed.
  ///
  /// In ar, this message translates to:
  /// **'تم تأكيد الموعد'**
  String get appointmentConfirmed;

  /// No description provided for @appointmentCanceled.
  ///
  /// In ar, this message translates to:
  /// **'تم إلغاء الموعد'**
  String get appointmentCanceled;

  /// No description provided for @unexpectedError.
  ///
  /// In ar, this message translates to:
  /// **'خطأ غير متوقع'**
  String get unexpectedError;

  /// No description provided for @tryDirectRead.
  ///
  /// In ar, this message translates to:
  /// **'تجربة القراءة المباشرة'**
  String get tryDirectRead;

  /// No description provided for @refreshTryDirect.
  ///
  /// In ar, this message translates to:
  /// **'تحديث / قراءة مباشرة'**
  String get refreshTryDirect;

  /// No description provided for @all.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get all;

  /// No description provided for @doctorTerms.
  ///
  /// In ar, this message translates to:
  /// **'تعهد الطبيب'**
  String get doctorTerms;

  /// No description provided for @doctorAgreementTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعهد الطبيب'**
  String get doctorAgreementTitle;

  /// No description provided for @doctorAgreementDetails.
  ///
  /// In ar, this message translates to:
  /// **'إقرار وتعهد خاص بحسابات الأطباء\n\nباستخدامك للتطبيق بصفتك طبيبًا، فإنك تقر وتتعهد بما يلي:\n\n1) أنك طبيب مرخّص لك بمزاولة المهنة، وجميع المعلومات التي تدخلها صحيحة ومحدّثة.\n2) تتحمّل كامل المسؤولية القانونية والمهنية عن بياناتك.\n3) التطبيق لا يتحمّل مسؤولية صحة المعلومات التي يضيفها الأطباء.\n4) التطبيق مخصّص لتنظيم المواعيد الطبية فقط.\n5) انتحال صفة طبيب أو إدخال معلومات مضللة قد يعرّض الحساب للحذف والمساءلة القانونية.\n6) يحق لإدارة التطبيق طلب وثائق تثبت الصفة المهنية متى رأت ذلك ضروريًا.\n\nبمتابعتك، فإنك توافق على جميع الشروط أعلاه.'**
  String get doctorAgreementDetails;

  /// No description provided for @doctorAgreementConfirm.
  ///
  /// In ar, this message translates to:
  /// **'أقرّ بأنني طبيب مرخّص وأتحمّل المسؤولية الكاملة عن صحة المعلومات التي أدخلها.'**
  String get doctorAgreementConfirm;

  /// No description provided for @mustAcceptTerms.
  ///
  /// In ar, this message translates to:
  /// **'يرجى الموافقة على الشروط أولًا'**
  String get mustAcceptTerms;

  /// No description provided for @acceptAndContinue.
  ///
  /// In ar, this message translates to:
  /// **'أوافق وأواصل'**
  String get acceptAndContinue;

  /// No description provided for @back.
  ///
  /// In ar, this message translates to:
  /// **'رجوع'**
  String get back;

  /// No description provided for @todayAppointments.
  ///
  /// In ar, this message translates to:
  /// **'مواعيد اليوم'**
  String get todayAppointments;

  /// No description provided for @loadTodayError.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل مواعيد اليوم'**
  String get loadTodayError;

  /// No description provided for @noAppointmentsToday.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مواعيد اليوم'**
  String get noAppointmentsToday;

  /// No description provided for @checkedInShort.
  ///
  /// In ar, this message translates to:
  /// **'حاضر'**
  String get checkedInShort;

  /// No description provided for @checkIn.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل حضور'**
  String get checkIn;

  /// No description provided for @checkedIn.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل الحضور'**
  String get checkedIn;

  /// No description provided for @noShow.
  ///
  /// In ar, this message translates to:
  /// **'لم يحضر'**
  String get noShow;

  /// No description provided for @noShowSet.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل الحالة: لم يحضر'**
  String get noShowSet;

  /// No description provided for @newPasswordOptional.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور الجديدة (اختياري)'**
  String get newPasswordOptional;

  /// No description provided for @mustLogin.
  ///
  /// In ar, this message translates to:
  /// **'يجب تسجيل الدخول'**
  String get mustLogin;

  /// No description provided for @mustLoginFirst.
  ///
  /// In ar, this message translates to:
  /// **'يجب تسجيل الدخول أولًا'**
  String get mustLoginFirst;

  /// No description provided for @cannotBookThisDay.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن الحجز في هذا اليوم'**
  String get cannotBookThisDay;

  /// No description provided for @doctorDayOff.
  ///
  /// In ar, this message translates to:
  /// **'الطبيب في عطلة'**
  String get doctorDayOff;

  /// No description provided for @dayNotAvailable.
  ///
  /// In ar, this message translates to:
  /// **'اليوم غير متاح'**
  String get dayNotAvailable;

  /// No description provided for @dayIsFull.
  ///
  /// In ar, this message translates to:
  /// **'اليوم ممتلئ'**
  String get dayIsFull;

  /// No description provided for @timeNotAvailable.
  ///
  /// In ar, this message translates to:
  /// **'الوقت غير متاح'**
  String get timeNotAvailable;

  /// No description provided for @cannotBookPastTime.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن الحجز في وقت سابق'**
  String get cannotBookPastTime;

  /// No description provided for @bookingSent.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال طلب الحجز'**
  String get bookingSent;

  /// No description provided for @invalidSlot.
  ///
  /// In ar, this message translates to:
  /// **'الوقت المختار غير صالح'**
  String get invalidSlot;

  /// No description provided for @deleteAppointment.
  ///
  /// In ar, this message translates to:
  /// **'حذف الموعد'**
  String get deleteAppointment;

  /// No description provided for @appointmentDeleted.
  ///
  /// In ar, this message translates to:
  /// **'تم حذف الموعد نهائيًا'**
  String get appointmentDeleted;

  /// No description provided for @emailInUse.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني مستخدم بالفعل'**
  String get emailInUse;

  /// No description provided for @weakPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور ضعيفة جدًا'**
  String get weakPassword;

  /// No description provided for @registerPatient.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل مريض'**
  String get registerPatient;

  /// No description provided for @register.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل'**
  String get register;

  /// No description provided for @fullName.
  ///
  /// In ar, this message translates to:
  /// **'الاسم الكامل'**
  String get fullName;

  /// No description provided for @enterValidName.
  ///
  /// In ar, this message translates to:
  /// **'أدخل اسمًا صحيحًا'**
  String get enterValidName;

  /// No description provided for @enterValidPassword.
  ///
  /// In ar, this message translates to:
  /// **'أدخل كلمة مرور صحيحة'**
  String get enterValidPassword;

  /// No description provided for @phoneNumber.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف'**
  String get phoneNumber;

  /// No description provided for @enterValidPhone.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رقم هاتف صحيح'**
  String get enterValidPhone;

  /// No description provided for @phoneUpdated.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث رقم الهاتف بنجاح'**
  String get phoneUpdated;

  /// No description provided for @createAccount.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء حساب'**
  String get createAccount;

  /// No description provided for @appBarCreateAccount.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء حساب'**
  String get appBarCreateAccount;

  /// No description provided for @chooseAccountType.
  ///
  /// In ar, this message translates to:
  /// **'اختر نوع الحساب'**
  String get chooseAccountType;

  /// No description provided for @patientOrDoctor.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت مريض أم طبيب؟'**
  String get patientOrDoctor;

  /// No description provided for @registerDoctor.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل طبيب'**
  String get registerDoctor;

  /// No description provided for @dataLoadError.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل البيانات'**
  String get dataLoadError;

  /// No description provided for @wrongCurrentPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور الحالية غير صحيحة'**
  String get wrongCurrentPassword;

  /// No description provided for @reauthFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل إعادة المصادقة'**
  String get reauthFailed;

  /// No description provided for @noChangesToSave.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد تغييرات'**
  String get noChangesToSave;

  /// No description provided for @savedSuccessfully.
  ///
  /// In ar, this message translates to:
  /// **'تم الحفظ بنجاح'**
  String get savedSuccessfully;

  /// No description provided for @saveFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر الحفظ'**
  String get saveFailed;

  /// No description provided for @patientSettings.
  ///
  /// In ar, this message translates to:
  /// **'إعدادات المريض'**
  String get patientSettings;

  /// No description provided for @emailExample.
  ///
  /// In ar, this message translates to:
  /// **'example@mail.com'**
  String get emailExample;

  /// No description provided for @verifyBySMS.
  ///
  /// In ar, this message translates to:
  /// **'التحقق عبر SMS'**
  String get verifyBySMS;

  /// No description provided for @notificationSettings.
  ///
  /// In ar, this message translates to:
  /// **'إعدادات الإشعارات'**
  String get notificationSettings;

  /// No description provided for @notificationSettingsDesc.
  ///
  /// In ar, this message translates to:
  /// **'إدارة إعدادات الإشعارات'**
  String get notificationSettingsDesc;

  /// No description provided for @securityNote.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة: يتم استخدام رقم الهاتف لأغراض الأمان'**
  String get securityNote;

  /// No description provided for @enterPhoneFirst.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رقم الهاتف أولًا'**
  String get enterPhoneFirst;

  /// No description provided for @autoVerifyFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل التحقق التلقائي'**
  String get autoVerifyFailed;

  /// No description provided for @codeSendFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل إرسال الكود'**
  String get codeSendFailed;

  /// No description provided for @codeSentSuccessfully.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال الكود'**
  String get codeSentSuccessfully;

  /// No description provided for @enterSMSCode.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رمز التحقق'**
  String get enterSMSCode;

  /// No description provided for @verifyFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل التحقق'**
  String get verifyFailed;

  /// No description provided for @phoneVerification.
  ///
  /// In ar, this message translates to:
  /// **'التحقق عبر الهاتف'**
  String get phoneVerification;

  /// No description provided for @sending.
  ///
  /// In ar, this message translates to:
  /// **'جاري الإرسال...'**
  String get sending;

  /// No description provided for @sendSMSCode.
  ///
  /// In ar, this message translates to:
  /// **'إرسال رمز SMS'**
  String get sendSMSCode;

  /// No description provided for @smsCode.
  ///
  /// In ar, this message translates to:
  /// **'رمز SMS'**
  String get smsCode;

  /// No description provided for @verifying.
  ///
  /// In ar, this message translates to:
  /// **'جاري التحقق...'**
  String get verifying;

  /// No description provided for @confirmCode.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الرمز'**
  String get confirmCode;

  /// No description provided for @notificationsEnabled.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات مفعلة'**
  String get notificationsEnabled;

  /// No description provided for @notificationsEnabledMessage.
  ///
  /// In ar, this message translates to:
  /// **'سيتم إرسال الإشعارات'**
  String get notificationsEnabledMessage;

  /// No description provided for @notificationsDisabled.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات معطلة'**
  String get notificationsDisabled;

  /// No description provided for @testNotificationTitle.
  ///
  /// In ar, this message translates to:
  /// **'إشعار تجريبي'**
  String get testNotificationTitle;

  /// No description provided for @testNotificationMessage.
  ///
  /// In ar, this message translates to:
  /// **'هذا إشعار للتجربة'**
  String get testNotificationMessage;

  /// No description provided for @allowNotifications.
  ///
  /// In ar, this message translates to:
  /// **'السماح بالإشعارات'**
  String get allowNotifications;

  /// No description provided for @allowNotificationsDescription.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل الإشعارات لهذا الجهاز'**
  String get allowNotificationsDescription;

  /// No description provided for @sendTestNotification.
  ///
  /// In ar, this message translates to:
  /// **'إرسال إشعار تجريبي'**
  String get sendTestNotification;

  /// No description provided for @fcmDisabledNote.
  ///
  /// In ar, this message translates to:
  /// **'خدمة FCM غير مفعلة'**
  String get fcmDisabledNote;

  /// No description provided for @notLoggedIn.
  ///
  /// In ar, this message translates to:
  /// **'غير مسجل الدخول'**
  String get notLoggedIn;

  /// No description provided for @failedToLoadAppointments.
  ///
  /// In ar, this message translates to:
  /// **'فشل تحميل المواعيد'**
  String get failedToLoadAppointments;

  /// No description provided for @noAppointmentsYet.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مواعيد بعد'**
  String get noAppointmentsYet;

  /// No description provided for @userDataNotFound.
  ///
  /// In ar, this message translates to:
  /// **'بيانات المستخدم غير موجودة'**
  String get userDataNotFound;

  /// No description provided for @loginError.
  ///
  /// In ar, this message translates to:
  /// **'خطأ في تسجيل الدخول'**
  String get loginError;

  /// No description provided for @language.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get language;

  /// No description provided for @secretaryHint.
  ///
  /// In ar, this message translates to:
  /// **'هذه الصفحة مخصصة للسكرتير'**
  String get secretaryHint;

  /// No description provided for @welcomeDoctor.
  ///
  /// In ar, this message translates to:
  /// **'مرحبًا دكتور'**
  String get welcomeDoctor;

  /// No description provided for @defaultDoctor.
  ///
  /// In ar, this message translates to:
  /// **'الطبيب'**
  String get defaultDoctor;

  /// No description provided for @welcomeUser.
  ///
  /// In ar, this message translates to:
  /// **'مرحبًا'**
  String get welcomeUser;

  /// No description provided for @defaultUser.
  ///
  /// In ar, this message translates to:
  /// **'المستخدم'**
  String get defaultUser;

  /// No description provided for @home.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get home;

  /// No description provided for @changeLanguage.
  ///
  /// In ar, this message translates to:
  /// **'تغيير اللغة'**
  String get changeLanguage;

  /// No description provided for @patientServices.
  ///
  /// In ar, this message translates to:
  /// **'خدمات المرضى'**
  String get patientServices;

  /// No description provided for @doctorsList.
  ///
  /// In ar, this message translates to:
  /// **'قائمة الأطباء'**
  String get doctorsList;

  /// No description provided for @dashboard.
  ///
  /// In ar, this message translates to:
  /// **'لوحة التحكم'**
  String get dashboard;

  /// No description provided for @calendar.
  ///
  /// In ar, this message translates to:
  /// **'التقويم'**
  String get calendar;

  /// No description provided for @finance.
  ///
  /// In ar, this message translates to:
  /// **'المالية'**
  String get finance;

  /// No description provided for @failedToLoadDoctors.
  ///
  /// In ar, this message translates to:
  /// **'فشل تحميل قائمة الأطباء'**
  String get failedToLoadDoctors;

  /// No description provided for @noDoctorsAvailable.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد أطباء متاحون'**
  String get noDoctorsAvailable;

  /// No description provided for @chooseDay.
  ///
  /// In ar, this message translates to:
  /// **'اختر يومًا'**
  String get chooseDay;

  /// No description provided for @noAvailableAppointments.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مواعيد متاحة'**
  String get noAvailableAppointments;

  /// No description provided for @available.
  ///
  /// In ar, this message translates to:
  /// **'متاح'**
  String get available;

  /// No description provided for @full.
  ///
  /// In ar, this message translates to:
  /// **'مكتمل'**
  String get full;

  /// No description provided for @address.
  ///
  /// In ar, this message translates to:
  /// **'العنوان'**
  String get address;

  /// No description provided for @sessionPrice.
  ///
  /// In ar, this message translates to:
  /// **'سعر الجلسة'**
  String get sessionPrice;

  /// No description provided for @requested.
  ///
  /// In ar, this message translates to:
  /// **'تم الطلب'**
  String get requested;

  /// No description provided for @slotAlreadyTaken.
  ///
  /// In ar, this message translates to:
  /// **'الموعد محجوز بالفعل'**
  String get slotAlreadyTaken;

  /// No description provided for @codeInactive.
  ///
  /// In ar, this message translates to:
  /// **'الكود غير مفعّل'**
  String get codeInactive;

  /// No description provided for @codeExpired.
  ///
  /// In ar, this message translates to:
  /// **'الكود منتهي'**
  String get codeExpired;

  /// No description provided for @codeIncomplete.
  ///
  /// In ar, this message translates to:
  /// **'الكود غير مكتمل'**
  String get codeIncomplete;

  /// No description provided for @codeNotFound.
  ///
  /// In ar, this message translates to:
  /// **'الكود غير موجود'**
  String get codeNotFound;

  /// No description provided for @connectionError.
  ///
  /// In ar, this message translates to:
  /// **'خطأ في الاتصال'**
  String get connectionError;

  /// No description provided for @filter.
  ///
  /// In ar, this message translates to:
  /// **'تصفية'**
  String get filter;

  /// No description provided for @syncFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل المزامنة'**
  String get syncFailed;

  /// No description provided for @active.
  ///
  /// In ar, this message translates to:
  /// **'نشط'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In ar, this message translates to:
  /// **'غير نشط'**
  String get inactive;

  /// No description provided for @expired.
  ///
  /// In ar, this message translates to:
  /// **'منتهي'**
  String get expired;

  /// No description provided for @expiringSoon.
  ///
  /// In ar, this message translates to:
  /// **'سينتهي قريبًا'**
  String get expiringSoon;

  /// No description provided for @noDoctorId.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد معرف طبيب'**
  String get noDoctorId;

  /// No description provided for @activatedUntil.
  ///
  /// In ar, this message translates to:
  /// **'مفعل حتى'**
  String get activatedUntil;

  /// No description provided for @refresh.
  ///
  /// In ar, this message translates to:
  /// **'تحديث'**
  String get refresh;

  /// No description provided for @noResults.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد نتائج'**
  String get noResults;

  /// No description provided for @cannotConfirmPastAppointment.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن تأكيد موعد في تاريخ سابق'**
  String get cannotConfirmPastAppointment;

  /// No description provided for @reportMarkedProcessed.
  ///
  /// In ar, this message translates to:
  /// **'تم تعليم البلاغ كمُعالج'**
  String get reportMarkedProcessed;

  /// No description provided for @reportMarkedNew.
  ///
  /// In ar, this message translates to:
  /// **'تم تعليم البلاغ كجديد'**
  String get reportMarkedNew;

  /// No description provided for @type.
  ///
  /// In ar, this message translates to:
  /// **'النوع'**
  String get type;

  /// No description provided for @status.
  ///
  /// In ar, this message translates to:
  /// **'الحالة'**
  String get status;

  /// No description provided for @date.
  ///
  /// In ar, this message translates to:
  /// **'التاريخ'**
  String get date;

  /// No description provided for @text.
  ///
  /// In ar, this message translates to:
  /// **'النص'**
  String get text;

  /// No description provided for @delete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد'**
  String get confirm;

  /// No description provided for @deleteAccountWarning.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من حذف الحساب؟ لا يمكن التراجع عن هذه العملية.'**
  String get deleteAccountWarning;

  /// No description provided for @deleteAccount.
  ///
  /// In ar, this message translates to:
  /// **'حذف الحساب'**
  String get deleteAccount;

  /// No description provided for @chooseAppointment.
  ///
  /// In ar, this message translates to:
  /// **'اختيار الموعد'**
  String get chooseAppointment;

  /// No description provided for @loadingAppointments.
  ///
  /// In ar, this message translates to:
  /// **'جاري تحميل المواعيد...'**
  String get loadingAppointments;

  /// No description provided for @loadingTakingLong.
  ///
  /// In ar, this message translates to:
  /// **'التحميل يستغرق وقتاً...'**
  String get loadingTakingLong;

  /// No description provided for @save.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get save;

  /// No description provided for @enterCode.
  ///
  /// In ar, this message translates to:
  /// **'أدخل الكود'**
  String get enterCode;

  /// No description provided for @noLoggedUser.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد مستخدم مسجل دخول'**
  String get noLoggedUser;

  /// No description provided for @insufficientPermissions.
  ///
  /// In ar, this message translates to:
  /// **'صلاحيات غير كافية'**
  String get insufficientPermissions;

  /// No description provided for @adminCheckFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل التحقق من صلاحيات المدير'**
  String get adminCheckFailed;

  /// No description provided for @syncCompleted.
  ///
  /// In ar, this message translates to:
  /// **'{processed} تمت معالجتها، {updated} تم تحديثها'**
  String syncCompleted(Object processed, Object updated);

  /// No description provided for @manageSubscriptions.
  ///
  /// In ar, this message translates to:
  /// **'إدارة الاشتراكات'**
  String get manageSubscriptions;

  /// No description provided for @manageSubscriptionsSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة وتجديد الاشتراكات'**
  String get manageSubscriptionsSubtitle;

  /// No description provided for @reports.
  ///
  /// In ar, this message translates to:
  /// **'التقارير'**
  String get reports;

  /// No description provided for @reportsSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'تقارير النظام والبلاغات'**
  String get reportsSubtitle;

  /// No description provided for @adminDashboard.
  ///
  /// In ar, this message translates to:
  /// **'لوحة المدير'**
  String get adminDashboard;

  /// No description provided for @tools.
  ///
  /// In ar, this message translates to:
  /// **'الأدوات'**
  String get tools;

  /// No description provided for @syncDoctorSubscriptions.
  ///
  /// In ar, this message translates to:
  /// **'مزامنة اشتراكات الأطباء'**
  String get syncDoctorSubscriptions;

  /// No description provided for @logout.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get logout;

  /// No description provided for @customActivation.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل مخصص'**
  String get customActivation;

  /// No description provided for @daysCount.
  ///
  /// In ar, this message translates to:
  /// **'عدد الأيام'**
  String get daysCount;

  /// No description provided for @invalidDays.
  ///
  /// In ar, this message translates to:
  /// **'عدد الأيام غير صالح'**
  String get invalidDays;

  /// No description provided for @daysTooLarge.
  ///
  /// In ar, this message translates to:
  /// **'الرقم كبير جدًا'**
  String get daysTooLarge;

  /// No description provided for @activate.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل'**
  String get activate;

  /// No description provided for @deactivateSubscription.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء التفعيل'**
  String get deactivateSubscription;

  /// No description provided for @confirmDeactivate.
  ///
  /// In ar, this message translates to:
  /// **'هل تريد إلغاء التفعيل؟'**
  String get confirmDeactivate;

  /// No description provided for @deactivate.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get deactivate;

  /// No description provided for @deactivated.
  ///
  /// In ar, this message translates to:
  /// **'تم إلغاء التفعيل'**
  String get deactivated;

  /// No description provided for @activate7.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل 7 أيام'**
  String get activate7;

  /// No description provided for @activate30.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل 30 يوم'**
  String get activate30;

  /// No description provided for @activate90.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل 90 يوم'**
  String get activate90;

  /// No description provided for @actionFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشلت العملية'**
  String get actionFailed;

  /// No description provided for @adminSubscriptions.
  ///
  /// In ar, this message translates to:
  /// **'اشتراكات الإدارة'**
  String get adminSubscriptions;

  /// No description provided for @searchByNameEmail.
  ///
  /// In ar, this message translates to:
  /// **'بحث بالاسم أو البريد'**
  String get searchByNameEmail;

  /// No description provided for @errorLoading.
  ///
  /// In ar, this message translates to:
  /// **'خطأ في التحميل'**
  String get errorLoading;

  /// No description provided for @noName.
  ///
  /// In ar, this message translates to:
  /// **'بدون اسم'**
  String get noName;

  /// No description provided for @deleteReport.
  ///
  /// In ar, this message translates to:
  /// **'حذف البلاغ'**
  String get deleteReport;

  /// No description provided for @deleteReportConfirm.
  ///
  /// In ar, this message translates to:
  /// **'هل تريد حذف البلاغ؟'**
  String get deleteReportConfirm;

  /// No description provided for @deletedSuccessfully.
  ///
  /// In ar, this message translates to:
  /// **'تم الحذف بنجاح'**
  String get deletedSuccessfully;

  /// No description provided for @pickDateRange.
  ///
  /// In ar, this message translates to:
  /// **'اختر المدة الزمنية'**
  String get pickDateRange;

  /// No description provided for @unknown.
  ///
  /// In ar, this message translates to:
  /// **'غير معروف'**
  String get unknown;

  /// No description provided for @processed.
  ///
  /// In ar, this message translates to:
  /// **'معالج'**
  String get processed;

  /// No description provided for @newReport.
  ///
  /// In ar, this message translates to:
  /// **'جديد'**
  String get newReport;

  /// No description provided for @reportDetails.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل البلاغ'**
  String get reportDetails;

  /// No description provided for @senderEmail.
  ///
  /// In ar, this message translates to:
  /// **'البريد المرسل'**
  String get senderEmail;

  /// No description provided for @noteStatusChangeHint.
  ///
  /// In ar, this message translates to:
  /// **'يمكنك تغيير حالة البلاغ من القائمة'**
  String get noteStatusChangeHint;

  /// No description provided for @markProcessed.
  ///
  /// In ar, this message translates to:
  /// **'وضع كمعالج'**
  String get markProcessed;

  /// No description provided for @markNew.
  ///
  /// In ar, this message translates to:
  /// **'وضع كجديد'**
  String get markNew;

  /// No description provided for @report.
  ///
  /// In ar, this message translates to:
  /// **'بلاغ'**
  String get report;

  /// No description provided for @sender.
  ///
  /// In ar, this message translates to:
  /// **'المرسل'**
  String get sender;

  /// No description provided for @clearDateRange.
  ///
  /// In ar, this message translates to:
  /// **'حذف المدة'**
  String get clearDateRange;

  /// No description provided for @invalidEmail.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني غير صالح'**
  String get invalidEmail;

  /// No description provided for @error.
  ///
  /// In ar, this message translates to:
  /// **'خطأ'**
  String get error;

  /// No description provided for @email.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get email;

  /// No description provided for @enterEmail.
  ///
  /// In ar, this message translates to:
  /// **'أدخل البريد الإلكتروني'**
  String get enterEmail;

  /// No description provided for @password6Chars.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور يجب أن تحتوي 6 أحرف على الأقل'**
  String get password6Chars;

  /// No description provided for @myAppointments.
  ///
  /// In ar, this message translates to:
  /// **'مواعيدي'**
  String get myAppointments;

  /// No description provided for @doctor.
  ///
  /// In ar, this message translates to:
  /// **'الطبيب'**
  String get doctor;

  /// No description provided for @specialty.
  ///
  /// In ar, this message translates to:
  /// **'التخصص'**
  String get specialty;

  /// No description provided for @password.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get password;

  /// No description provided for @login.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get login;

  /// No description provided for @createNewAccount.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء حساب جديد'**
  String get createNewAccount;

  /// No description provided for @chooseLanguage.
  ///
  /// In ar, this message translates to:
  /// **'اختر اللغة'**
  String get chooseLanguage;

  /// No description provided for @arabic.
  ///
  /// In ar, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @french.
  ///
  /// In ar, this message translates to:
  /// **'الفرنسية'**
  String get french;

  /// No description provided for @secretarySpace.
  ///
  /// In ar, this message translates to:
  /// **'مساحة السكرتير'**
  String get secretarySpace;

  /// No description provided for @appointmentsToday.
  ///
  /// In ar, this message translates to:
  /// **'مواعيد اليوم'**
  String get appointmentsToday;

  /// No description provided for @createSecretaryCode.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء رمز سكرتير'**
  String get createSecretaryCode;

  /// No description provided for @optionalExpiry.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ انتهاء (اختياري)'**
  String get optionalExpiry;

  /// No description provided for @noExpiry.
  ///
  /// In ar, this message translates to:
  /// **'بدون انتهاء'**
  String get noExpiry;

  /// No description provided for @expiresAt.
  ///
  /// In ar, this message translates to:
  /// **'انتهاء في'**
  String get expiresAt;

  /// No description provided for @pickDate.
  ///
  /// In ar, this message translates to:
  /// **'اختر التاريخ'**
  String get pickDate;

  /// No description provided for @create.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء'**
  String get create;

  /// No description provided for @userNotLogged.
  ///
  /// In ar, this message translates to:
  /// **'المستخدم غير مسجل الدخول'**
  String get userNotLogged;

  /// No description provided for @noPermissionForThisDoctor.
  ///
  /// In ar, this message translates to:
  /// **'ليست لديك صلاحية لهذا الطبيب'**
  String get noPermissionForThisDoctor;

  /// No description provided for @expiryMustBeFuture.
  ///
  /// In ar, this message translates to:
  /// **'يجب أن يكون تاريخ الانتهاء مستقبليًا'**
  String get expiryMustBeFuture;

  /// No description provided for @codeCreated.
  ///
  /// In ar, this message translates to:
  /// **'تم إنشاء الكود'**
  String get codeCreated;

  /// No description provided for @generalFailure.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ'**
  String get generalFailure;

  /// No description provided for @permissionDenied.
  ///
  /// In ar, this message translates to:
  /// **'تم رفض الإذن'**
  String get permissionDenied;

  /// No description provided for @networkError.
  ///
  /// In ar, this message translates to:
  /// **'خطأ في الشبكة'**
  String get networkError;

  /// No description provided for @codeAlreadyExists.
  ///
  /// In ar, this message translates to:
  /// **'الكود موجود مسبقًا'**
  String get codeAlreadyExists;

  /// No description provided for @updateFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل التحديث'**
  String get updateFailed;

  /// No description provided for @expiryUpdated.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث تاريخ الانتهاء'**
  String get expiryUpdated;

  /// No description provided for @expiryRemoved.
  ///
  /// In ar, this message translates to:
  /// **'تم حذف تاريخ الانتهاء'**
  String get expiryRemoved;

  /// No description provided for @deleteCode.
  ///
  /// In ar, this message translates to:
  /// **'حذف الكود'**
  String get deleteCode;

  /// No description provided for @deleteCodeConfirm.
  ///
  /// In ar, this message translates to:
  /// **'هل تريد حذف الكود؟'**
  String get deleteCodeConfirm;

  /// No description provided for @codeDeleted.
  ///
  /// In ar, this message translates to:
  /// **'تم حذف الكود'**
  String get codeDeleted;

  /// No description provided for @statusInactive.
  ///
  /// In ar, this message translates to:
  /// **'غير نشط'**
  String get statusInactive;

  /// No description provided for @statusExpired.
  ///
  /// In ar, this message translates to:
  /// **'منتهي'**
  String get statusExpired;

  /// No description provided for @statusActive.
  ///
  /// In ar, this message translates to:
  /// **'نشط'**
  String get statusActive;

  /// No description provided for @secretaryCodes.
  ///
  /// In ar, this message translates to:
  /// **'أكواد السكرتارية'**
  String get secretaryCodes;

  /// No description provided for @createNewCode.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء كود جديد'**
  String get createNewCode;

  /// No description provided for @createCode.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء الكود'**
  String get createCode;

  /// No description provided for @loadingFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل التحميل'**
  String get loadingFailed;

  /// No description provided for @copyCode.
  ///
  /// In ar, this message translates to:
  /// **'نسخ الكود'**
  String get copyCode;

  /// No description provided for @copied.
  ///
  /// In ar, this message translates to:
  /// **'تم النسخ'**
  String get copied;

  /// No description provided for @createdAt.
  ///
  /// In ar, this message translates to:
  /// **'تم الإنشاء في'**
  String get createdAt;

  /// No description provided for @editExpiry.
  ///
  /// In ar, this message translates to:
  /// **'تعديل تاريخ الانتهاء'**
  String get editExpiry;

  /// No description provided for @removeExpiry.
  ///
  /// In ar, this message translates to:
  /// **'حذف تاريخ الانتهاء'**
  String get removeExpiry;

  /// No description provided for @disable.
  ///
  /// In ar, this message translates to:
  /// **'تعطيل'**
  String get disable;

  /// No description provided for @noSecretaryCodes.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد أكواد سكرتير'**
  String get noSecretaryCodes;

  /// No description provided for @secretaryQrCode.
  ///
  /// In ar, this message translates to:
  /// **'رمز QR للسكرتير'**
  String get secretaryQrCode;

  /// No description provided for @qrGenerationFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل إنشاء رمز QR'**
  String get qrGenerationFailed;

  /// No description provided for @done.
  ///
  /// In ar, this message translates to:
  /// **'تم'**
  String get done;

  /// No description provided for @doctorAccountCreated.
  ///
  /// In ar, this message translates to:
  /// **'تم إنشاء حساب الطبيب'**
  String get doctorAccountCreated;

  /// No description provided for @doctorRegisterTitle.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل طبيب'**
  String get doctorRegisterTitle;

  /// No description provided for @enterSpecialty.
  ///
  /// In ar, this message translates to:
  /// **'أدخل التخصص'**
  String get enterSpecialty;

  /// No description provided for @consultationPrice.
  ///
  /// In ar, this message translates to:
  /// **'سعر الفحص'**
  String get consultationPrice;

  /// No description provided for @createDoctorAccount.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء حساب طبيب'**
  String get createDoctorAccount;

  /// No description provided for @operationFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشلت العملية'**
  String get operationFailed;

  /// No description provided for @codeVerificationFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل التحقق من الكود'**
  String get codeVerificationFailed;

  /// No description provided for @authFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل المصادقة'**
  String get authFailed;

  /// No description provided for @anonymousAuthNotEnabled.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول المجهول غير مفعل'**
  String get anonymousAuthNotEnabled;

  /// No description provided for @permissionDeniedSessions.
  ///
  /// In ar, this message translates to:
  /// **'ليس لديك إذن للوصول إلى الجلسات'**
  String get permissionDeniedSessions;

  /// No description provided for @secretaryEnterCodeText.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رمز السكرتير'**
  String get secretaryEnterCodeText;

  /// No description provided for @secretaryCode.
  ///
  /// In ar, this message translates to:
  /// **'رمز السكرتير'**
  String get secretaryCode;

  /// No description provided for @secretaryCodeExample.
  ///
  /// In ar, this message translates to:
  /// **'مثال: ABC123'**
  String get secretaryCodeExample;

  /// No description provided for @searchReports.
  ///
  /// In ar, this message translates to:
  /// **'بحث في البلاغات'**
  String get searchReports;

  /// No description provided for @uidUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'المعرف غير متاح'**
  String get uidUnavailable;

  /// No description provided for @noAccess.
  ///
  /// In ar, this message translates to:
  /// **'لا تملك صلاحية الدخول'**
  String get noAccess;

  /// No description provided for @notAdminAccount.
  ///
  /// In ar, this message translates to:
  /// **'هذا الحساب ليس مديرًا'**
  String get notAdminAccount;

  /// No description provided for @accountDisabled.
  ///
  /// In ar, this message translates to:
  /// **'الحساب معطّل'**
  String get accountDisabled;

  /// No description provided for @loginFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل تسجيل الدخول'**
  String get loginFailed;

  /// No description provided for @emailOrPasswordWrong.
  ///
  /// In ar, this message translates to:
  /// **'البريد أو كلمة المرور غير صحيحة'**
  String get emailOrPasswordWrong;

  /// No description provided for @enterEmailFirst.
  ///
  /// In ar, this message translates to:
  /// **'أدخل البريد أولاً'**
  String get enterEmailFirst;

  /// No description provided for @resetLinkSent.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال رابط الاستعادة'**
  String get resetLinkSent;

  /// No description provided for @resetFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل إرسال رابط الاستعادة'**
  String get resetFailed;

  /// No description provided for @adminLogin.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل دخول المدير'**
  String get adminLogin;

  /// No description provided for @adminEntry.
  ///
  /// In ar, this message translates to:
  /// **'دخول المدير'**
  String get adminEntry;

  /// No description provided for @invalidEmailFormat.
  ///
  /// In ar, this message translates to:
  /// **'صيغة البريد الإلكتروني غير صحيحة'**
  String get invalidEmailFormat;

  /// No description provided for @show.
  ///
  /// In ar, this message translates to:
  /// **'إظهار'**
  String get show;

  /// No description provided for @hide.
  ///
  /// In ar, this message translates to:
  /// **'إخفاء'**
  String get hide;

  /// No description provided for @noPermission.
  ///
  /// In ar, this message translates to:
  /// **'ليست لديك صلاحية الدخول'**
  String get noPermission;

  /// No description provided for @enterPassword.
  ///
  /// In ar, this message translates to:
  /// **'أدخل كلمة المرور'**
  String get enterPassword;

  /// No description provided for @passwordShort.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور قصيرة جدًا'**
  String get passwordShort;

  /// No description provided for @forgotPassword.
  ///
  /// In ar, this message translates to:
  /// **'نسيت كلمة المرور؟'**
  String get forgotPassword;

  /// No description provided for @adminScreenHint.
  ///
  /// In ar, this message translates to:
  /// **'هذه الشاشة مخصصة للمدير'**
  String get adminScreenHint;

  /// No description provided for @deleteFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل الحذف'**
  String get deleteFailed;

  /// No description provided for @profile.
  ///
  /// In ar, this message translates to:
  /// **'الملف الشخصي'**
  String get profile;

  /// No description provided for @manageProfile.
  ///
  /// In ar, this message translates to:
  /// **'إدارة الملف الشخصي'**
  String get manageProfile;

  /// No description provided for @changePassword.
  ///
  /// In ar, this message translates to:
  /// **'تغيير كلمة المرور'**
  String get changePassword;

  /// No description provided for @notifications.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات'**
  String get notifications;

  /// No description provided for @secretaryManagement.
  ///
  /// In ar, this message translates to:
  /// **'إدارة السكرتارية'**
  String get secretaryManagement;

  /// No description provided for @manageSecretary.
  ///
  /// In ar, this message translates to:
  /// **'إدارة السكرتير'**
  String get manageSecretary;

  /// No description provided for @aboutApp.
  ///
  /// In ar, this message translates to:
  /// **'حول التطبيق'**
  String get aboutApp;

  /// No description provided for @emailUpdated.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث البريد الإلكتروني بنجاح'**
  String get emailUpdated;

  /// No description provided for @passwordUpdated.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث كلمة المرور بنجاح'**
  String get passwordUpdated;

  /// No description provided for @showPrice.
  ///
  /// In ar, this message translates to:
  /// **'إظهار السعر'**
  String get showPrice;

  /// No description provided for @updateEmail.
  ///
  /// In ar, this message translates to:
  /// **'تحديث البريد'**
  String get updateEmail;

  /// No description provided for @updatePassword.
  ///
  /// In ar, this message translates to:
  /// **'تحديث كلمة المرور'**
  String get updatePassword;

  /// No description provided for @governorate.
  ///
  /// In ar, this message translates to:
  /// **'الولاية'**
  String get governorate;

  /// No description provided for @chooseGovernorate.
  ///
  /// In ar, this message translates to:
  /// **'الرجاء اختيار الولاية'**
  String get chooseGovernorate;

  /// No description provided for @chooseSpecialty.
  ///
  /// In ar, this message translates to:
  /// **'الرجاء اختيار الاختصاص'**
  String get chooseSpecialty;

  /// No description provided for @searchDoctors.
  ///
  /// In ar, this message translates to:
  /// **'البحث عن طبيب'**
  String get searchDoctors;

  /// No description provided for @search.
  ///
  /// In ar, this message translates to:
  /// **'بحث'**
  String get search;

  /// No description provided for @noResultsFound.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد نتائج'**
  String get noResultsFound;

  /// No description provided for @enterAddress.
  ///
  /// In ar, this message translates to:
  /// **'الرجاء إدخال العنوان'**
  String get enterAddress;

  /// No description provided for @passwordsNotMatch.
  ///
  /// In ar, this message translates to:
  /// **'كلمتا المرور غير متطابقتين'**
  String get passwordsNotMatch;

  /// No description provided for @confirmPassword.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد كلمة المرور'**
  String get confirmPassword;

  /// No description provided for @doctorPrefix.
  ///
  /// In ar, this message translates to:
  /// **'د.'**
  String get doctorPrefix;

  /// No description provided for @bookAppointment.
  ///
  /// In ar, this message translates to:
  /// **'احجز موعد'**
  String get bookAppointment;

  /// No description provided for @doctorNotAvailable.
  ///
  /// In ar, this message translates to:
  /// **'الطبيب غير متاح حاليًا'**
  String get doctorNotAvailable;

  /// No description provided for @currentPasswordRequired.
  ///
  /// In ar, this message translates to:
  /// **'يرجى إدخال كلمة المرور الحالية لتأكيد تغيير البريد الإلكتروني'**
  String get currentPasswordRequired;

  /// No description provided for @currentPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور الحالية'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور الجديدة'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد كلمة المرور الجديدة'**
  String get confirmNewPassword;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In ar, this message translates to:
  /// **'كلمتا المرور غير متطابقتين'**
  String get passwordsDoNotMatch;

  /// No description provided for @passwordTooShort.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور ضعيفة جدًا'**
  String get passwordTooShort;

  /// No description provided for @currentPasswordIncorrect.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور الحالية غير صحيحة'**
  String get currentPasswordIncorrect;

  /// No description provided for @subscriptionRequests.
  ///
  /// In ar, this message translates to:
  /// **'طلبات تجديد الاشتراك'**
  String get subscriptionRequests;

  /// No description provided for @noSubscriptionRequests.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد طلبات حالياً'**
  String get noSubscriptionRequests;

  /// No description provided for @requestDate.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الطلب'**
  String get requestDate;

  /// No description provided for @unknownDoctor.
  ///
  /// In ar, this message translates to:
  /// **'طبيب غير معروف'**
  String get unknownDoctor;

  /// No description provided for @reject.
  ///
  /// In ar, this message translates to:
  /// **'رفض'**
  String get reject;

  /// No description provided for @subscriptionRequestsSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'طلبات تجديد الاشتراك المرسلة من الأطباء'**
  String get subscriptionRequestsSubtitle;

  /// No description provided for @requestSubscriptionRenewal.
  ///
  /// In ar, this message translates to:
  /// **'طلب تجديد الاشتراك'**
  String get requestSubscriptionRenewal;

  /// No description provided for @subscriptionRequestSent.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال طلب تجديد الاشتراك، سيتم التواصل معك قريبًا'**
  String get subscriptionRequestSent;

  /// No description provided for @subscriptionRequestAlreadySent.
  ///
  /// In ar, this message translates to:
  /// **'لقد أرسلت طلب تجديد من قبل، يرجى انتظار رد الإدارة'**
  String get subscriptionRequestAlreadySent;

  /// No description provided for @noCodes.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد أكواد'**
  String get noCodes;

  /// No description provided for @optionalExpiryDate.
  ///
  /// In ar, this message translates to:
  /// **'إضافة تاريخ انتهاء (اختياري)'**
  String get optionalExpiryDate;

  /// No description provided for @chooseDate.
  ///
  /// In ar, this message translates to:
  /// **'اختيار تاريخ'**
  String get chooseDate;

  /// No description provided for @expiresOn.
  ///
  /// In ar, this message translates to:
  /// **'ينتهي في'**
  String get expiresOn;

  /// No description provided for @codeNotValid.
  ///
  /// In ar, this message translates to:
  /// **'الكود غير صحيح'**
  String get codeNotValid;

  /// No description provided for @confirmDelete.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من الحذف؟'**
  String get confirmDelete;

  /// No description provided for @invalidCodeFormat.
  ///
  /// In ar, this message translates to:
  /// **'صيغة الكود غير صحيحة'**
  String get invalidCodeFormat;

  /// No description provided for @copy.
  ///
  /// In ar, this message translates to:
  /// **'نسخ'**
  String get copy;

  /// No description provided for @enterSecretaryCode.
  ///
  /// In ar, this message translates to:
  /// **'أدخل كود السكرتير الذي زوّدك به الطبيب'**
  String get enterSecretaryCode;

  /// No description provided for @usedBy.
  ///
  /// In ar, this message translates to:
  /// **'استُعمل من قبل'**
  String get usedBy;

  /// No description provided for @monday.
  ///
  /// In ar, this message translates to:
  /// **'الإثنين'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In ar, this message translates to:
  /// **'الثلاثاء'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In ar, this message translates to:
  /// **'الأربعاء'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In ar, this message translates to:
  /// **'الخميس'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In ar, this message translates to:
  /// **'الجمعة'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In ar, this message translates to:
  /// **'السبت'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In ar, this message translates to:
  /// **'الأحد'**
  String get sunday;

  /// No description provided for @acceptBookings.
  ///
  /// In ar, this message translates to:
  /// **'استقبال الحجوزات'**
  String get acceptBookings;

  /// No description provided for @acceptBookingsOn.
  ///
  /// In ar, this message translates to:
  /// **'الطبيب ظاهر ويقبل حجوزات جديدة'**
  String get acceptBookingsOn;

  /// No description provided for @acceptBookingsOff.
  ///
  /// In ar, this message translates to:
  /// **'الطبيب غير متاح حاليًا'**
  String get acceptBookingsOff;

  /// No description provided for @bookingsEnabled.
  ///
  /// In ar, this message translates to:
  /// **'تم تفعيل استقبال الحجوزات'**
  String get bookingsEnabled;

  /// No description provided for @bookingsDisabled.
  ///
  /// In ar, this message translates to:
  /// **'تم إيقاف استقبال الحجوزات'**
  String get bookingsDisabled;

  /// No description provided for @savePrice.
  ///
  /// In ar, this message translates to:
  /// **'حفظ السعر'**
  String get savePrice;

  /// No description provided for @saving.
  ///
  /// In ar, this message translates to:
  /// **'جاري الحفظ...'**
  String get saving;

  /// No description provided for @priceSavedSuccessfully.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ السعر بنجاح'**
  String get priceSavedSuccessfully;

  /// No description provided for @invalidPrice.
  ///
  /// In ar, this message translates to:
  /// **'الرجاء إدخال سعر صحيح'**
  String get invalidPrice;

  /// No description provided for @confirmCancelAppointment.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من إلغاء هذا الموعد؟'**
  String get confirmCancelAppointment;

  /// No description provided for @yesCancel.
  ///
  /// In ar, this message translates to:
  /// **'نعم، إلغاء'**
  String get yesCancel;

  /// No description provided for @no.
  ///
  /// In ar, this message translates to:
  /// **'تراجع'**
  String get no;

  /// No description provided for @enterPaidAmount.
  ///
  /// In ar, this message translates to:
  /// **'إدخال المبلغ المدفوع'**
  String get enterPaidAmount;

  /// No description provided for @amountHint.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ'**
  String get amountHint;

  /// No description provided for @currency.
  ///
  /// In ar, this message translates to:
  /// **'دت'**
  String get currency;

  /// No description provided for @subscriptionExpiredDoctor.
  ///
  /// In ar, this message translates to:
  /// **'هذا الطبيب غير متاح مؤقتًا لانتهاء الاشتراك'**
  String get subscriptionExpiredDoctor;

  /// No description provided for @remainingDays.
  ///
  /// In ar, this message translates to:
  /// **'متبقي {days} يوم'**
  String remainingDays(Object days);

  /// No description provided for @appointmentDetails.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل الموعد '**
  String get appointmentDetails;

  /// No description provided for @callPatient.
  ///
  /// In ar, this message translates to:
  /// **'اتصال بالمريض'**
  String get callPatient;

  /// No description provided for @doctorNotes.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات الطبيب'**
  String get doctorNotes;

  /// No description provided for @visitType.
  ///
  /// In ar, this message translates to:
  /// **'نوع الموعد'**
  String get visitType;

  /// No description provided for @consultation.
  ///
  /// In ar, this message translates to:
  /// **'استشارة'**
  String get consultation;

  /// No description provided for @review.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة'**
  String get review;

  /// No description provided for @checkup.
  ///
  /// In ar, this message translates to:
  /// **'فحص'**
  String get checkup;

  /// No description provided for @enterData.
  ///
  /// In ar, this message translates to:
  /// **'الرجاء إدخال بيانات'**
  String get enterData;

  /// No description provided for @hasReport.
  ///
  /// In ar, this message translates to:
  /// **'يوجد تقرير'**
  String get hasReport;

  /// No description provided for @myReports.
  ///
  /// In ar, this message translates to:
  /// **'تقاريري'**
  String get myReports;

  /// No description provided for @openReports.
  ///
  /// In ar, this message translates to:
  /// **'التقارير المفتوحة'**
  String get openReports;

  /// No description provided for @sendReport.
  ///
  /// In ar, this message translates to:
  /// **'إرسال تقرير'**
  String get sendReport;

  /// No description provided for @bug.
  ///
  /// In ar, this message translates to:
  /// **'خلل'**
  String get bug;

  /// No description provided for @complaint.
  ///
  /// In ar, this message translates to:
  /// **'شكوى'**
  String get complaint;

  /// No description provided for @suggestion.
  ///
  /// In ar, this message translates to:
  /// **'اقتراح'**
  String get suggestion;

  /// No description provided for @describeProblem.
  ///
  /// In ar, this message translates to:
  /// **'صف المشكلة...'**
  String get describeProblem;

  /// No description provided for @send.
  ///
  /// In ar, this message translates to:
  /// **'إرسال'**
  String get send;

  /// No description provided for @noReports.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد تقارير بعد'**
  String get noReports;

  /// No description provided for @invalidInput.
  ///
  /// In ar, this message translates to:
  /// **'يرجى إدخال رسالة'**
  String get invalidInput;

  /// No description provided for @reportSentSuccessfully.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال التقرير بنجاح'**
  String get reportSentSuccessfully;

  /// No description provided for @payment.
  ///
  /// In ar, this message translates to:
  /// **'الدفع'**
  String get payment;

  /// No description provided for @contactUs.
  ///
  /// In ar, this message translates to:
  /// **'اتصل بنا'**
  String get contactUs;

  /// No description provided for @replyAdded.
  ///
  /// In ar, this message translates to:
  /// **'تمت إضافة الرد'**
  String get replyAdded;

  /// No description provided for @adminReply.
  ///
  /// In ar, this message translates to:
  /// **'رد الإدارة:'**
  String get adminReply;

  /// No description provided for @english.
  ///
  /// In ar, this message translates to:
  /// **'الإنجليزية'**
  String get english;

  /// No description provided for @appDescription.
  ///
  /// In ar, this message translates to:
  /// **'تطبيق لحجز المواعيد الطبية.'**
  String get appDescription;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
