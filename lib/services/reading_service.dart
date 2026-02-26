import 'dart:convert';
import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import 'storage_service.dart';

class ReadingService {
  /// Add a book to the reading list (closed → open book)
  static Future<Map<String, dynamic>> addToReading(int bookId) async {
    final token = await StorageService.getToken();

    final response = await http.post(
      Uri.parse(ApiConstants.reading),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'book_id': bookId}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to add to reading list');
    }
    print("RESPONSE: ${response.body}");

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Remove a book from the reading list (open → closed book)
  /// Expects the reading list entry id (`read_id` from backend).
  static Future<Map<String, dynamic>> removeFromReading(int readingId) async {
    final token = await StorageService.getToken();

    final response = await http.delete(
      Uri.parse('${ApiConstants.reading}$readingId/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to remove from reading list');
    }

    // Many DELETE endpoints return an empty body (204).
    if (response.body.isEmpty) {
      return <String, dynamic>{};
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}