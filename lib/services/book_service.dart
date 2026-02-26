import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class BookService {
  static Future<List<dynamic>> fetchBooks() async {
    final response = await http.get(
      Uri.parse("$API_BASE_URL/api/books/"),
      headers: {
        "Authorization": "Bearer $ACCESS_TOKEN",
        "Content-Type": "application/json",
      },
    );

    print("BOOKS STATUS: ${response.statusCode}");
    print("BOOKS BODY: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load books");
    }
  }
}
