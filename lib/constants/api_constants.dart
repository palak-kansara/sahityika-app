class ApiConstants {
  // For Android Emulator use 10.0.2.2
  // For Web use localhost
  // For real device use your machine IP

  // static const String baseUrl = 'http://192.168.1.11:8000/api';
  static const String baseUrl = 'https://unmirthful-alla-lyrate.ngrok-free.dev/api';

  // Auth
  static const String login = '$baseUrl/login/';

  // Books
  static const String books = '$baseUrl/books/';

  // Reading progress
  static const String add_book = '$baseUrl/isbn/';
}
