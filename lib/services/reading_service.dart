import 'dart:convert';
import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import 'storage_service.dart';
import '../models/reading_entry.dart';
import 'api_client.dart';


class ReadingService {
  static Map<String, String> _authHeaders(String token) => <String, String>{
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      };

  /// Get reading list
  static Future<List<ReadingEntry>> fetchReadingList({int page = 1}) async {
    final token = await StorageService.getToken();

    final response = await ApiClient.get('${ApiConstants.reading}?page=$page');

    if (response.statusCode != 200) {
      throw Exception('Failed to load reading list');
    }

    final decoded = jsonDecode(response.body);
    final dynamic rawList =
        (decoded is Map<String, dynamic> && decoded['results'] is List)
            ? decoded['results']
            : decoded;

    if (rawList is! List) return <ReadingEntry>[];

    return rawList
        .whereType<Map<String, dynamic>>()
        .map(ReadingEntry.fromJson)
        .toList();
  }

  /// Get single reading entry
  static Future<ReadingEntry> fetchReadingEntry(int readingId) async {
    final token = await StorageService.getToken();

    final response = await ApiClient.get('${ApiConstants.reading}$readingId/');

    if (response.statusCode != 200) {
      throw Exception('Failed to load reading progress');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return ReadingEntry.fromJson(decoded);
  }

  /// Update progress (PATCH pages_read)
  static Future<ReadingEntry> updatePageRead({
    required int readingId,
    required int pageRead,
  }) async {
    final token = await StorageService.getToken();

    final response = await ApiClient.patch('${ApiConstants.reading}$readingId/', {
        "pages_read": pageRead,
      });

    if (response.statusCode != 200) {
      throw Exception('Failed to update reading progress');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return ReadingEntry.fromJson(decoded);
  }

  /// Add a book to the reading list (closed → open book)
  static Future<Map<String, dynamic>> addToReading(int bookId) async {
    final token = await StorageService.getToken();

    final response = await ApiClient.post(ApiConstants.reading, {
        "book_id": bookId,
      });

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

    final response = await ApiClient.delete('${ApiConstants.reading}$readingId/');

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