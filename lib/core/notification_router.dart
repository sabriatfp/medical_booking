import 'package:flutter/material.dart';

// استورد الشاشات التي ستنتقل إليها من الإشعار:
import '../screens/doctor/doctor_dashboard_screen.dart';
import '../screens/my_appointments_screen.dart';
import '../screens/doctor/doctor_calendar_screen.dart';
import '../screens/doctor/doctor_finance_screen.dart';

/// Router مخصص لسيناريوهات الضغط على الإشعار.
/// data هي الحقول القادمة من FCM (message.data).
class NotificationRouter {
  const NotificationRouter._();

  /// يبني Route حسب routeName القادم من الإشعار.
  /// أمثلة routeName:
  /// - 'doctor_dashboard'
  /// - 'my_appointments'
  /// - 'doctor_calendar'
  /// - 'doctor_finance'
  static Route<dynamic>? buildRoute(
    String routeName,
    Map<String, dynamic> data,
  ) {
    switch (routeName) {
      case 'doctor_dashboard':
        return MaterialPageRoute(
          builder: (_) => const DoctorDashboardScreen(),
          settings: RouteSettings(name: '/doctor_dashboard', arguments: data),
        );

      case 'my_appointments':
        return MaterialPageRoute(
          builder: (_) => const MyAppointmentsScreen(),
          settings: RouteSettings(name: '/my_appointments', arguments: data),
        );

      case 'doctor_calendar':
        return MaterialPageRoute(
          builder: (_) => const DoctorCalendarScreen(),
          settings: RouteSettings(name: '/doctor_calendar', arguments: data),
        );

      case 'doctor_finance':
        return MaterialPageRoute(
          builder: (_) => const DoctorFinanceScreen(),
          settings: RouteSettings(name: '/doctor_finance', arguments: data),
        );

      default:
        // route غير معروف → لا نفتح شيء (أو ارجع null)
        return null;
    }
  }
}
