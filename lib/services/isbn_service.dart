import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import 'storage_service.dart';


class IsbnService {
  // static const String apiUrl = "http://192.168.1.13:8000/api/isbn/";

  static Future<Map<String, dynamic>> checkIsbn(String isbn) async {
		final token = await StorageService.getToken();

    final response = await http.post(
      Uri.parse(ApiConstants.add_book),
      headers: {
        "Content-Type": "application/json",
			  'Authorization': 'Token $token',

      },
      body: jsonEncode({
        "isbn": isbn,
      }),
    );

    return jsonDecode(response.body);
  }
}