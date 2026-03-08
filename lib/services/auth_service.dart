import 'dart:convert';
import 'package:http/http.dart' as http;
import 'storage_service.dart';
import '../constants/api_constants.dart';

class AuthService {
  static Future<bool> login(String username, String password) async {
    try {
      print("LOGIN API CALLED");
      print("Username: $username");

      final response = await http.post(
        Uri.parse(ApiConstants.login), // UPDATE THIS
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      print("STATUS CODE: ${response.statusCode}");
      print("RESPONSE BODY: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await StorageService.saveLoginData(
        	token: data['token'],
          expiry: data['expiry'],
        	name: data['user']['first_name'],
		);
        return true;
      }
    } catch (e) {
      print("LOGIN ERROR: $e");
    }

    return false;
  }
}
