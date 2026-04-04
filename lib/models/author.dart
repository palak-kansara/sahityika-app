class Author {
  const Author({this.id, required this.name});

  final int? id;
  final String name;

  factory Author.fromJson(Map<String, dynamic> json) {
    final raw = json['name'] ??
        json['author_name'] ??
        json['full_name'] ??
        json['title'];
    final name = raw?.toString().trim() ?? '';
    int? id;
    final idVal = json['id'];
    if (idVal is int) {
      id = idVal;
    } else if (idVal != null) {
      id = int.tryParse(idVal.toString());
    }
    return Author(id: id, name: name);
  }
}
