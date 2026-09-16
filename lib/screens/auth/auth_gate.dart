import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../routes.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    _checkInitialRoute();
  }

  Future<void> _checkInitialRoute() async {
    // 1. Check if user has seen the onboarding screen
    final onboardingSeen = await ApiService.isOnboardingSeen();
    if (!mounted) return;

    if (!onboardingSeen) {
      Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
      return;
    }

    // 2. Check if user is logged in
    final loggedIn = await ApiService.isLoggedIn();
    if (!mounted) return;

    Navigator.pushReplacementNamed(
      context,
      loggedIn ? AppRoutes.dashboard : AppRoutes.login,
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.dark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🩸', style: TextStyle(fontSize: 48)),
            SizedBox(height: 24),
            CircularProgressIndicator(color: AppColors.red),
          ],
        ),
      ),
    );
  }
}
