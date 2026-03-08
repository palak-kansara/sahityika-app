import 'dart:convert';
import 'package:http/http.dart' as http;
import 'storage_service.dart';
import 'session_manager.dart';

class ApiClient {

  static Future<http.Response> get(String url) async {

    // Check token expiry
    if (await StorageService.isTokenExpired()) {
      await SessionManager.logout();
      throw Exception("SESSION_EXPIRED");
    }

    final token = await StorageService.getToken();

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Token $token',
      },
    );

    if (response.statusCode == 401) {
      await SessionManager.logout();
      throw Exception("SESSION_EXPIRED");
    }

    return response;
  }

  static Future<http.Response> post(
      String url,
      Map<String, dynamic> body,
  ) async {

    if (await StorageService.isTokenExpired()) {
      await SessionManager.logout();
      throw Exception("SESSION_EXPIRED");
    }

    final token = await StorageService.getToken();

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 401) {
      await SessionManager.logout();
      throw Exception("SESSION_EXPIRED");
    }

    return response;
  }

  static Future<http.Response> patch(
      String url,
      Map<String, dynamic> body,
  ) async {

        if (await StorageService.isTokenExpired()) {
            await SessionManager.logout();
            throw Exception("SESSION_EXPIRED");
        }

        final token = await StorageService.getToken();

        final response = await http.patch(
        Uri.parse(url),
        headers: {
            'Authorization': 'Token $token',
            'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
        );

        if (response.statusCode == 401) {
            await SessionManager.logout();
            throw Exception("SESSION_EXPIRED");
        }

        return response;
  
    }

    static Future<http.Response> delete(
      String url,
  ) async {

        if (await StorageService.isTokenExpired()) {
            await SessionManager.logout();
            throw Exception("SESSION_EXPIRED");
        }

        final token = await StorageService.getToken();

        final response = await http.delete(
        Uri.parse(url),
        headers: {
            'Authorization': 'Token $token',
            'Content-Type': 'application/json',
        },
        );

        if (response.statusCode == 401) {
            await SessionManager.logout();
            throw Exception("SESSION_EXPIRED");
        }

        return response;
    }

}