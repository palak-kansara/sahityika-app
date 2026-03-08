import '../main.dart';
import '../screens/login_landing.dart';
import 'storage_service.dart';
import 'package:flutter/material.dart';

class SessionManager {

  static Future<void> logout() async {

    await StorageService.clear();

    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginLandingScreen()),
      (route) => false,
    );
  }
}