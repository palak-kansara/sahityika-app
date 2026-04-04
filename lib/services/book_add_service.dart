import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import 'api_client.dart';

DateTime? _tryYmd(int year, int month, int day) {
  try {
    final dt = DateTime(year, month, day);
    if (dt.year != year || dt.month != month || dt.day != day) return null;
    return dt;
  } catch (_) {
    return null;
  }
}

String _toYmd(DateTime dt) {
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// Empty → `null` (JSON `null` / Python `None`). Otherwise returns `yyyy-mm-dd`, or `null` if the string cannot be parsed.
String? formatPublishedDateForApi(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return null;

  final iso = DateTime.tryParse(t);
  if (iso != null) {
    return _toYmd(iso);
  }

  final yFirst = RegExp(r'^(\d{4})[/-](\d{1,2})[/-](\d{1,2})$').firstMatch(t);
  if (yFirst != null) {
    final y = int.tryParse(yFirst.group(1)!);
    final mo = int.tryParse(yFirst.group(2)!);
    final d = int.tryParse(yFirst.group(3)!);
    if (y != null && mo != null && d != null) {
      final dt = _tryYmd(y, mo, d);
      if (dt != null) return _toYmd(dt);
    }
  }

  final dmy = RegExp(r'^(\d{1,2})[/-](\d{1,2})[/-](\d{4})$').firstMatch(t);
  if (dmy != null) {
    final d = int.tryParse(dmy.group(1)!);
    final mo = int.tryParse(dmy.group(2)!);
    final y = int.tryParse(dmy.group(3)!);
    if (y != null && mo != null && d != null) {
      final dt = _tryYmd(y, mo, d);
      if (dt != null) return _toYmd(dt);
    }
  }

  return null;
}

class ManualBookPayload {
  ManualBookPayload({
    required this.title,
    required this.isbn10,
    required this.isbn13,
    required this.subtitle,
    required this.authorNames,
    required this.categories,
    required this.description,
    required this.pageCount,
    required this.languageCode,
    required this.publisher,
    required this.publishedDate,
    required this.thumbnail,
    required this.previewLink,
    required this.infoLink,
  });

  final String title;
  final String isbn10;
  final String isbn13;
  final String subtitle;
  final List<String> authorNames;
  final String categories;
  final String description;
  final String pageCount;
  final String languageCode;
  final String publisher;
  final String publishedDate;
  final String thumbnail;
  final String previewLink;
  final String infoLink;

  Map<String, dynamic> toJson() => {
        'title': title,
        'isbn_10': isbn10.trim(),
        'isbn_13': isbn13.trim(),
        'subtitle': subtitle,
        'author_names': authorNames,
        'categories': categories,
        'description': description,
        'page_count': pageCount,
        'language': languageCode,
        'publisher': publisher,
        'published_date': formatPublishedDateForApi(publishedDate),
        'thumbnail': thumbnail,
        'preview_link': previewLink,
        'info_link': infoLink,
      };
}

class BookAddService {
  static Future<http.Response> addManualBook(ManualBookPayload payload) {
    return ApiClient.post(
      ApiConstants.books_add,
      payload.toJson(),
    );
  }
}
