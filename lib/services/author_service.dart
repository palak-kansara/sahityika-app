import 'dart:convert';

import '../constants/api_constants.dart';
import '../models/author.dart';
import 'api_client.dart';

class PaginatedAuthors {
  const PaginatedAuthors({
    required this.authors,
    required this.hasNext,
  });

  final List<Author> authors;
  final bool hasNext;
}

bool _hasNextPage(Map<String, dynamic> decoded) {
  final next = decoded['next'];
  if (next is String && next.trim().isNotEmpty) return true;
  if (next == true) return true;

  final hn = decoded['has_next'] ?? decoded['hasNext'];
  if (hn == true) return true;

  final page = decoded['page'];
  final totalPages = decoded['total_pages'] ?? decoded['total_pages_count'];
  final totalPagesAlt = decoded['totalPages'];
  final tp = totalPages ?? totalPagesAlt;
  if (page is int && tp is int && tp > 0) {
    return page < tp;
  }

  final count = decoded['count'];
  final pageSize = decoded['page_size'] ?? decoded['pageSize'];
  if (count is int && pageSize is int && pageSize > 0) {
    final currentPage = decoded['page'];
    final p = currentPage is int ? currentPage : 1;
    return p * pageSize < count;
  }

  return false;
}

class AuthorService {
  static Future<PaginatedAuthors> fetchAuthors({
    int page = 1,
    String search = '',
  }) async {
    final uri = Uri.parse(ApiConstants.author).replace(
      queryParameters: {
        'page': '$page',
        if (search.trim().isNotEmpty) 'search': search.trim(),
      },
    );

    final response = await ApiClient.get(uri.toString());

    if (response.statusCode != 200) {
      throw Exception('Failed to load authors (${response.statusCode})');
    }

    final dynamic decoded = jsonDecode(response.body);

    if (decoded is List) {
      final authors = decoded
          .whereType<Map<String, dynamic>>()
          .map(Author.fromJson)
          .where((a) => a.name.isNotEmpty)
          .toList();
      return PaginatedAuthors(authors: authors, hasNext: false);
    }

    if (decoded is! Map<String, dynamic>) {
      return const PaginatedAuthors(authors: [], hasNext: false);
    }

    final rawList = decoded['results'] ?? decoded['data'] ?? decoded['authors'];
    final List<dynamic> list = rawList is List ? rawList : const [];
    final authors = list
        .whereType<Map<String, dynamic>>()
        .map(Author.fromJson)
        .where((a) => a.name.isNotEmpty)
        .toList();

    var hasNext = _hasNextPage(decoded);

    // If API omits next flags but returns a full page, assume more may exist.
    const defaultPageSize = 20;
    if (!hasNext &&
        authors.length >= defaultPageSize &&
        decoded['next'] == null &&
        decoded['has_next'] == null) {
      hasNext = true;
    }

    return PaginatedAuthors(authors: authors, hasNext: hasNext);
  }
}
