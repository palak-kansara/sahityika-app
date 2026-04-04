import '../config/environment.dart';

class ApiConstants {
  static String get baseUrl => Environment.baseUrl;

  static String get login => '$baseUrl/login/';

  static String get books => '$baseUrl/books/';
  static String get books_categories => '$baseUrl/books/categories/';
  static String get books_publishers => '$baseUrl/books/publishers/';

  static String get author => '$baseUrl/author/';

  static String get add_book => '$baseUrl/isbn/';

  static String get reading => '$baseUrl/reading/';
  static String get profile => '$baseUrl/profile/';
}
