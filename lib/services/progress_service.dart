import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'api_client.dart';

class ProgressService {
  static Future<void> updateProgress(int bookId, int progress) async {
    final response = await ApiClient.post("${ApiConstants.books}$bookId/favourite/", {
        "book": bookId,
        "progress_percent": progress,
      });

    print("PROGRESS STATUS: ${response.statusCode}");
    print("PROGRESS BODY: ${response.body}");

    if (response.statusCode != 200) {
      throw Exception("Failed to update progress");
    }
  }
}
