import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/book.dart';
import 'storage_service.dart';
import '../constants/api_constants.dart';
import 'api_client.dart';

class PaginatedBooks {
  final List<Book> books;
  final bool hasNext;

  PaginatedBooks({
    required this.books,
    required this.hasNext,
  });
}


class BookService {
  // static const String baseUrl = 'http://192.168.1.13:8000';

  	static Future<PaginatedBooks> fetchBooks(int page) async {

		if (await StorageService.isTokenExpired()) {
			await StorageService.clear();
			throw Exception("SESSION_EXPIRED");
		}

		final token = await StorageService.getToken();

		final response = await ApiClient.get('${ApiConstants.books}?page=$page');

		final decoded = jsonDecode(response.body);

		final List results = decoded['results'];
		final bool hasNext = decoded['next'] != null;

		final books = results
			.map((e) => Book.fromJson(e))
			.toList();

		return PaginatedBooks(
		books: books,
		hasNext: hasNext,
		);
    }

	static Future<PaginatedBooks> searchBooks({required String query, required int page,}) async {
    	final token = await StorageService.getToken();

		final response = await ApiClient.get('${ApiConstants.books}?search=$query&page=$page');
		final decoded = jsonDecode(response.body);

		final List results = decoded['results'];
		final bool hasNext = decoded['next'] != null;

		final books = results
			.map((e) => Book.fromJson(e))
			.toList();

		return PaginatedBooks(
			books: books,
			hasNext: hasNext,
		);
	}

   	static Future<Book> fetchBookDetail(int id) async {
		final token = await StorageService.getToken();

		final response = await ApiClient.get('${ApiConstants.books}$id');

		if (response.statusCode != 200) {
			throw Exception('Failed to load book details');
		}

		final decoded = jsonDecode(response.body);
		return Book.fromJson(decoded);
    }

	static Future<Map<String, dynamic>> toggleWishlist(int bookId) async {
		final token = await StorageService.getToken();

		final response = await ApiClient.post('${ApiConstants.books}$bookId/favourite/', {});

		if (response.statusCode == 200) {
			final data = jsonDecode(response.body);
			return data;
		}

		throw Exception('Failed to toggle wishlist');
	}

	static Future<PaginatedBooks> fetchWishlist({int page=1, String query = ''}) async {
		final token = await StorageService.getToken();
		final url = query.isEmpty
			? '${ApiConstants.books}favourite?page=$page'
			: '${ApiConstants.books}favourite?search=$query&page=$page';

		final response = await ApiClient.get(url);

		if (response.statusCode != 200) {
			throw Exception('Failed to load wishlist');
		}

		final decoded = jsonDecode(response.body);

		final List results = decoded['results'];
		final bool hasNext = decoded['next'] != null;

		final books = results
			.map((e) => Book.fromJson(e))
			.toList();

		return PaginatedBooks(
			books: books,
			hasNext: hasNext,
		);
	}

}
