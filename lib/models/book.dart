class Author {
  final int id;
  final String name;

  Author({required this.id, required this.name});

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      id: json['id'],
      name: json['name'],
    );
  }
}

class Book {
  final int id;
  final String title;
  final String? subtitle;
  final String isbn10;
  final String isbn13;
  final String description;
  final String thumbnail;
  final String previewLink;
  final List<Author> authors;
  final bool isFav;
  final int? readId; // reading list entry id (null if not in list)
  final bool isRead;

  Book({
    required this.id,
    required this.title,
    this.subtitle,
    required this.isbn10,
    required this.isbn13,
    required this.description,
    required this.thumbnail,
    required this.previewLink,
    required this.authors,
    required this.isFav,
    required this.readId,
    required this.isRead,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    final dynamic rawReadId = json['read_id'];
    final int? readId =
        rawReadId == null ? null : (rawReadId as num).toInt();

    return Book(
      id: json['id'],
      title: json['title'],
      subtitle: json['subtitle'],
      isbn10: json['isbn_10'],
      isbn13: json['isbn_13'],
      description: json['description'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
      previewLink: json['preview_link'] ?? '',
      isFav: json['is_fav'] ?? false,
      readId: readId,
      // Backend: read_id has value if in list, None/absent if not
      isRead: readId != null,
      authors: (json['authors'] as List)
          .map((e) => Author.fromJson(e))
          .toList(),
    );
  }
}