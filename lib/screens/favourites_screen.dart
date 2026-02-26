import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/book_list_service.dart';
import 'book_detail_screen.dart';

class FavouritesScreen extends StatefulWidget {
  const FavouritesScreen({super.key});

  @override
  State<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends State<FavouritesScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<Book> _books = [];
  List<Book> _filteredBooks = [];
  int _page = 1;
  bool _loading = false;
  bool _hasMore = true;
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadMore();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >
              _scrollController.position.maxScrollExtent - 200 &&
          !_loading &&
          _hasMore) {
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

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _isSearching = false;
      _filteredBooks = [];
    } else {
      _isSearching = true;
      final query = _searchQuery.toLowerCase();
      _filteredBooks = _books
          .where((b) => b.title.toLowerCase().contains(query))
          .toList();
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value.trim();
      _applyFilter();
    });
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;

    setState(() => _loading = true);

    try {
      final response = await BookService.fetchWishlist(_page);

      setState(() {
        _page++;
        _books.addAll(response.books);
        // Keep filter results in sync when paginating
        _applyFilter();
        _hasMore = response.hasNext;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load favourites')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Favourites',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),

            // Search box (same style as Home)
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search in favourites',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearching
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                            _applyFilter();
                          });
                        },
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: _books.isEmpty && !_loading
                  ? _buildEmptyState()
                  : GridView.builder(
                      controller: _scrollController,
                      itemCount:
                          _isSearching ? _filteredBooks.length : _books.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.65,
                      ),
                      itemBuilder: (context, index) {
                        final list = _isSearching ? _filteredBooks : _books;
                        final book = list[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    BookDetailScreen(bookId: book.id),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    book.thumbnail,
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
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        'No favourites yet ❤️\nAdd books to your wishlist',
        textAlign: TextAlign.center,
      ),
    );
  }
}
