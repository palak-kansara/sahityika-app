import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import 'login_landing.dart';
import 'home_screen.dart';
import 'main_navigation_screen.dart';

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: StorageService.getToken(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data != null) {
          return const MainNavigationScreen();
        }

        return const LoginLandingScreen();
      },
    );
  }
}
