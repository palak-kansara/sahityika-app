import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import 'login_landing.dart';
import 'home_screen.dart';
import 'main_navigation_screen.dart';

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  Future<bool> _isLoggedIn() async {
    final token = await StorageService.getToken();
    final expired = await StorageService.isTokenExpired();

    if (token != null && !expired) {
      return true;
    }

    await StorageService.clear();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == true) {
          return const MainNavigationScreen();
        }

        return const LoginLandingScreen();
      },
    );
  }
}