import 'book.dart';

int? _asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

double? _asPercent(dynamic v) {
  if (v == null) return null;
  if (v is num) {
    final d = v.toDouble();
    // support 0-1 or 0-100
    if (d <= 1.0) return d;
    if (d <= 100.0) return d / 100.0;
  }
  if (v is String) {
    final s = v.trim().replaceAll('%', '');
    final n = double.tryParse(s);
    if (n == null) return null;
    if (n <= 1.0) return n;
    if (n <= 100.0) return n / 100.0;
  }
  return null;
}

class ReadingEntry {
  final int id; // reading entry id (read_id)
  final Book book;
  final int pageRead;
  final int? totalPages;
  final double progress; // 0..1

  ReadingEntry({
    required this.id,
    required this.book,
    required this.pageRead,
    required this.totalPages,
    required this.progress,
  });

  factory ReadingEntry.fromJson(Map<String, dynamic> json) {
    final int id = (json['id'] as num).toInt();

    final dynamic rawBook = json['book'] ?? json['book_detail'] ?? json['data'];
    final Map<String, dynamic> bookJson =
        (rawBook is Map<String, dynamic>) ? rawBook : <String, dynamic>{};

    // Ensure Book sees read_id for isRead=true
    final Map<String, dynamic> hydratedBookJson = <String, dynamic>{
      ...bookJson,
      'read_id': bookJson['read_id'] ?? id,
    };

    final int pageRead = _asInt(json['page_read'] ?? json['pages_read']) ??
        _asInt(bookJson['page_read']) ??
        0;
    final int? totalPages = _asInt(json['total_pages'] ?? json['page_count']) ??
        _asInt(bookJson['total_pages'] ?? bookJson['page_count']);

    final double progressFromApi = _asPercent(
          json['progress'] ??
              json['progress_percent'] ??
              json['percentage'] ??
              json['percent'],
        ) ??
        _asPercent(bookJson['progress'] ?? bookJson['progress_percent']) ??
        -1.0;

    final double progress = totalPages != null && totalPages > 0
        ? (pageRead / totalPages).clamp(0.0, 1.0)
        : (progressFromApi >= 0 ? progressFromApi.clamp(0.0, 1.0) : 0.0);

    return ReadingEntry(
      id: id,
      book: Book.fromJson(hydratedBookJson),
      pageRead: pageRead,
      totalPages: totalPages,
      progress: progress,
    );
  }
}

