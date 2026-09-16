import 'package:flutter/material.dart';
import 'screens/auth/auth_gate.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/dashboard/main_nav_screen.dart';
import 'screens/donors/donor_search_screen.dart';
import 'screens/donors/donor_profile_screen.dart';
import 'screens/requests/request_blood_screen.dart';
import 'screens/requests/confirmation_screen.dart';
import 'screens/profile/my_profile_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/profile/change_password_screen.dart';
import 'screens/profile/settings_screen.dart';
import 'screens/notifications/donor_notifications_screen.dart';

class AppRoutes {
  static const String initial = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String dashboard = '/dashboard';
  static const String donorSearch = '/donor-search';
  static const String donorProfile = '/donor-profile';
  static const String request = '/request';
  static const String confirmation = '/confirmation';
  static const String myProfile = '/my-profile';
  static const String editProfile = '/edit-profile';
  static const String changePassword = '/change-password';
  static const String settings = '/settings';
  static const String notifications = '/notifications';

  static Map<String, WidgetBuilder> get routes => {
        initial: (ctx) => const AuthGate(),
        onboarding: (ctx) => const OnboardingScreen(),
        login: (ctx) => const LoginScreen(),
        register: (ctx) => const RegisterScreen(),
        forgotPassword: (ctx) => const ForgotPasswordScreen(),
        dashboard: (ctx) => const MainNavScreen(),
        donorSearch: (ctx) => const DonorSearchScreen(),
        request: (ctx) => const RequestBloodScreen(),
        myProfile: (ctx) => const MyProfileScreen(),
        editProfile: (ctx) => const EditProfileScreen(),
        changePassword: (ctx) => const ChangePasswordScreen(),
        settings: (ctx) => const SettingsScreen(),
        notifications: (ctx) => const DonorNotificationsScreen(),
      };

  static Route<dynamic>? onGenerateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case donorProfile:
        final donorId = routeSettings.arguments is int
            ? routeSettings.arguments as int
            : int.tryParse('${routeSettings.arguments}') ?? 0;
        return MaterialPageRoute(
          builder: (_) => DonorProfileScreen(donorId: donorId),
          settings: routeSettings,
        );
      case confirmation:
        final requestData = routeSettings.arguments as Map<String, dynamic>? ?? {};
        return MaterialPageRoute(
          builder: (_) => ConfirmationScreen(requestData: requestData),
          settings: routeSettings,
        );
      default:
        final builder = routes[routeSettings.name];
        if (builder != null) {
          return MaterialPageRoute(
            builder: builder,
            settings: routeSettings,
          );
        }
        return MaterialPageRoute(
          builder: (_) => const AuthGate(),
          settings: routeSettings,
        );
    }
  }
}
