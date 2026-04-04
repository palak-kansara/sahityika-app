import 'dart:convert';

import '../constants/api_constants.dart';
import 'api_client.dart';

List<String> _parseStringListBody(String body) {
  final dynamic decoded = jsonDecode(body);
  if (decoded is List) {
    return decoded
        .map((e) => e.toString().trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }
  if (decoded is Map<String, dynamic>) {
    final raw = decoded['results'] ?? decoded['data'];
    if (raw is List) {
      return raw
          .map((e) => e.toString().trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
  }
  return const [];
}

class BookOptionListsService {
  static Future<List<String>> fetchCategories() async {
    final response = await ApiClient.get(ApiConstants.books_categories);
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load categories (${response.statusCode})',
      );
    }
    return _parseStringListBody(response.body);
  }

  static Future<List<String>> fetchPublishers() async {
    final response = await ApiClient.get(ApiConstants.books_publishers);
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load publishers (${response.statusCode})',
      );
    }
    return _parseStringListBody(response.body);
  }
}
