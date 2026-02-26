import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class ProgressService {
  static Future<void> updateProgress(int bookId, int progress) async {
    final response = await http.post(
      Uri.parse("$API_BASE_URL/api/update-progress/"),
      headers: {
        "Authorization": "Bearer $ACCESS_TOKEN",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "book": bookId,
        "progress_percent": progress,
      }),
    );

    print("PROGRESS STATUS: ${response.statusCode}");
    print("PROGRESS BODY: ${response.body}");

    if (response.statusCode != 200) {
      throw Exception("Failed to update progress");
    }
  }
}
