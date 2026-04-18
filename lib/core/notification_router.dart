// lib/core/notifications/notification_router.dart

import 'package:flutter/material.dart';

// Screens to open from notifications
import '../screens/doctor/doctor_dashboard_screen.dart';
import '../screens/my_appointments_screen.dart';
import '../screens/doctor/doctor_calendar_screen.dart';
import '../screens/doctor/doctor_finance_screen.dart';

/// Notification Router – decides which screen to navigate to
/// based on the routeName received from an FCM notification.
///
/// Example routeName values:
/// - 'doctor_dashboard'
/// - 'my_appointments'
/// - 'doctor_calendar'
/// - 'doctor_finance'
class NotificationRouter {
  const NotificationRouter._(); // prevent instantiation

  /// Builds and returns the appropriate Route based on routeName.
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
        // Unknown route → return null (do nothing)
        return null;
    }
  }
}
