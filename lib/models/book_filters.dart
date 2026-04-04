class BookFilters {
  final String? category;
  final String? publisher;
  final String? author;
  final String? language;

  const BookFilters({
    this.category,
    this.publisher,
    this.author,
    this.language,
  });

  bool get isEmpty =>
      (category == null || category!.isEmpty) &&
      (publisher == null || publisher!.isEmpty) &&
      (author == null || author!.isEmpty) &&
      (language == null || language!.isEmpty);

  int get activeCount => [category, publisher, author, language]
      .where((e) => e != null && e.isNotEmpty)
      .length;

  String toQueryString() {
    final parts = <String>[];
    if (category != null && category!.isNotEmpty) {
      parts.add('category=${Uri.encodeQueryComponent(category!)}');
    }
    if (publisher != null && publisher!.isNotEmpty) {
      parts.add('publisher=${Uri.encodeQueryComponent(publisher!)}');
    }
    if (author != null && author!.isNotEmpty) {
      parts.add('author=${Uri.encodeQueryComponent(author!)}');
    }
    if (language != null && language!.isNotEmpty) {
      parts.add('language=${Uri.encodeQueryComponent(language!)}');
    }
    return parts.isEmpty ? '' : '&${parts.join('&')}';
  }

  BookFilters copyWith({
    Object? category = _sentinel,
    Object? publisher = _sentinel,
    Object? author = _sentinel,
    Object? language = _sentinel,
  }) {
    return BookFilters(
      category: category == _sentinel ? this.category : category as String?,
      publisher: publisher == _sentinel ? this.publisher : publisher as String?,
      author: author == _sentinel ? this.author : author as String?,
      language: language == _sentinel ? this.language : language as String?,
    );
  }
}

const _sentinel = Object();
