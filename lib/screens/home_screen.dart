import 'package:flutter/material.dart';
import '../services/book_list_service.dart';
import '../services/storage_service.dart';
import '../models/book.dart';
import 'login_landing.dart';
import '../services/storage_service.dart';
import 'book_detail_screen.dart';


enum HomeMode {
  listing,
  searching,
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

	List<Book> _books = [];
	//   int _page = 1;
	bool _loading = false;
	//   bool _hasMore = true;
	String _userName = '';
	HomeMode _mode = HomeMode.listing;

	int _listPage = 1;
	int _searchPage = 1;

	bool _hasMoreList = true;
	bool _hasMoreSearch = true;

	String _searchQuery = '';

	@override
	void initState() {
		super.initState();
		_loadUser();
		_loadMore();

		_scrollController.addListener(() {
		if (_scrollController.position.pixels >
				_scrollController.position.maxScrollExtent - 200 &&
			!_loading) {
			_loadMore();
		}
		});
	}

	@override
	void dispose() {
		_scrollController.dispose();
		_searchController.dispose();
		super.dispose();
	}

	Future<void> _loadUser() async {
		final name = await StorageService.getUserName();
		setState(() => _userName = name ?? '');
	}

	Future<void> _loadMore() async {
		if (_loading) return;

		setState(() => _loading = true);

		try {
			if (_mode == HomeMode.listing) {
			if (!_hasMoreList) return;

			final response = await BookService.fetchBooks(_listPage);

			setState(() {
				_listPage++;
				_books.addAll(response.books);
				_hasMoreList = response.hasNext;
			});
			} else {
			if (!_hasMoreSearch) return;

			final response = await BookService.searchBooks(
				query: _searchQuery,
				page: _searchPage,
			);

			setState(() {
				_searchPage++;
				_books.addAll(response.books);
				_hasMoreSearch = response.hasNext;
			});
			}
		} catch (e) {
			print('LOAD ERROR: $e');
		} finally {
			if (mounted) {
			setState(() => _loading = false);
			}
		}
	}

	Future<void> _startSearch(String query) async {
		if (query.trim().isEmpty) return;

		setState(() {
			_mode = HomeMode.searching;
			_searchQuery = query.trim();

			_books.clear();
			_searchPage = 1;
			_hasMoreSearch = true;
		});

		await _loadMore();
	}
	Future<void> _clearSearch() async {
		setState(() {
			_mode = HomeMode.listing;
			_searchQuery = '';

			_books.clear();
			_listPage = 1;
			_hasMoreList = true;

			_searchController.clear();
		});

		await _loadMore();
	}
	
	Future<void> _logout() async {
		await StorageService.clear();

		if (!mounted) return;

		Navigator.pushAndRemoveUntil(
			context,
			MaterialPageRoute(builder: (_) => const LoginLandingScreen()),
			(route) => false,
		);
		}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
		body: SafeArea(
			child: Padding(
			padding: const EdgeInsets.all(20),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
				// Welcome
				Row(
					mainAxisAlignment: MainAxisAlignment.spaceBetween,
					children: [
						Text(
						'Welcome $_userName',
						style: Theme.of(context).textTheme.headlineMedium,
						),

						IconButton(
						onPressed: _logout,
						icon: const Icon(Icons.logout),
						tooltip: 'Logout',
						color: Theme.of(context).colorScheme.primary,
						),
					],
					),
				const SizedBox(height: 20),

				// Search box
				TextField(
					controller: _searchController,
					onChanged: _startSearch,
					decoration: InputDecoration(
						hintText: 'Search for a book',
						prefixIcon: const Icon(Icons.search),
						suffixIcon: _mode == HomeMode.searching
							? IconButton(
								icon: const Icon(Icons.close),
								onPressed: _clearSearch,
							)
							: null,
					),
				),

				const SizedBox(height: 20),

				// Book grid
				Expanded(
					child: GridView.builder(
					controller: _scrollController,
					itemCount: _books.length,
					gridDelegate:
						const SliverGridDelegateWithFixedCrossAxisCount(
						crossAxisCount: 2,
						mainAxisSpacing: 16,
						crossAxisSpacing: 16,
						childAspectRatio: 0.65,
					),
					itemBuilder: (context, index) {
						final book = _books[index];
						return GestureDetector(
							onTap: () {
								Navigator.push(
								context,
								MaterialPageRoute(
									builder: (_) => BookDetailScreen(bookId: book.id),
								),
								);
							},
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
								Expanded(
									child: ClipRRect(
									borderRadius: BorderRadius.circular(12),
									child: book.thumbnail.isNotEmpty
										? Image.network(
											book.thumbnail,
											fit: BoxFit.cover,
											width: double.infinity,
											errorBuilder: (context, error, stackTrace) {
												return Image.asset(
												'assets/icon/app_icon.jpeg',
												fit: BoxFit.cover,
												width: double.infinity,
												);
											},
											)
										: Image.asset(
											'assets/icon/app_icon.jpeg',
											fit: BoxFit.cover,
											width: double.infinity,
											),
									),
								),
								const SizedBox(height: 6),
								Text(
									book.title,
									maxLines: 2,
									overflow: TextOverflow.ellipsis,
								),
								],
							),
						);
					},
					),
				),

				if (_loading)
					const Padding(
					padding: EdgeInsets.symmetric(vertical: 10),
					child: Center(child: CircularProgressIndicator()),
					),
				],
			),
			),
		),
		);
	}
}

