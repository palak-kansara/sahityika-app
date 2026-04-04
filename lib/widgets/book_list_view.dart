import 'package:flutter/material.dart';

import '../models/book.dart';
import '../models/book_filters.dart';
import '../models/reading_entry.dart';

import '../services/book_list_service.dart';
import '../services/reading_service.dart';

import '../screens/book_detail_screen.dart';
import '../enums/book_list_mode.dart';
import 'book_filter_sheet.dart';

class BookListView extends StatefulWidget {
  final BookListMode mode;

  const BookListView({super.key, required this.mode});

  @override
  State<BookListView> createState() => _BookListViewState();
}

class _BookListViewState extends State<BookListView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<Book> _books = [];

  bool _loading = false;
  bool _hasMore = true;

  int _page = 1;
  String _query = '';
  BookFilters _filters = const BookFilters();

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

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;

    setState(() => _loading = true);

    try {
      /// HOME LIST
      if (widget.mode == BookListMode.listing) {
        PaginatedBooks response;

        if (_query.isEmpty) {
          response = await BookService.fetchBooks(_page, filters: _filters);
        } else {
          response = await BookService.searchBooks(
            query: _query,
            page: _page,
            filters: _filters,
          );
        }

        setState(() {
          _page++;
          _books.addAll(response.books);
          _hasMore = response.hasNext;
        });
      }

      /// FAVOURITES
      else if (widget.mode == BookListMode.favourites) {
        PaginatedBooks response;

        if (_query.isEmpty) {
          response = await BookService.fetchWishlist(page: _page, filters: _filters);
        } else {
          response = await BookService.fetchWishlist(
            page: _page,
            query: _query,
            filters: _filters,
          );
        }

        setState(() {
          _page++;
          _books.addAll(response.books);
          _hasMore = response.hasNext;
        });
      }

      /// READING LIST
      else if (widget.mode == BookListMode.reading) {
        final List<ReadingEntry> entries =
            await ReadingService.fetchReadingList(
          page: _page,
          search: _query,
          filters: _filters,
        );

        setState(() {
          _page++;
          _books.addAll(entries.map((e) => e.book).toList());
          _hasMore = entries.isNotEmpty;
        });
      }
    } catch (e) {
      print("BOOK LIST ERROR: $e");
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _startSearch(String query) async {
    setState(() {
      _query = query.trim();
      _books.clear();
      _page = 1;
      _hasMore = true;
    });

    await _loadMore();
  }

  void _clearSearch() {
    setState(() {
      _query = '';
      _books.clear();
      _page = 1;
      _hasMore = true;
      _searchController.clear();
    });

    _loadMore();
  }

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<BookFilters>(
      context: context,
      isScrollControlled: true,
      builder: (_) => BookFilterSheet(current: _filters),
    );
    if (result == null || !mounted) return;
    setState(() {
      _filters = result;
      _books.clear();
      _page = 1;
      _hasMore = true;
    });
    await _loadMore();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        /// SEARCH + FILTER ROW
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: _startSearch,
                decoration: InputDecoration(
                  hintText: 'Search books',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: _clearSearch,
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Badge(
              isLabelVisible: _filters.activeCount > 0,
              label: Text('${_filters.activeCount}'),
              child: IconButton.outlined(
                icon: const Icon(Icons.tune),
                tooltip: 'Filters',
                onPressed: _openFilters,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        /// GRID VIEW
        Expanded(
            child: _books.isEmpty && !_loading
                ? _buildEmptyState()
                : GridView.builder(
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
                                child: book.thumbnail.isNotEmpty
                                    ? Image.network(
                                        book.thumbnail,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                            return Image.asset(
                                            'assets/icon/app_icon.jpeg',
                                            fit: BoxFit.cover,
                                            );
                                        },
                                        )
                                    : Image.asset(
                                        'assets/icon/app_icon.jpeg',
                                        fit: BoxFit.cover,
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
    );
  }

  Widget _buildEmptyState() {

    String message;

    if (_query.isNotEmpty) {
        message = "No books found for \"$_query\"";
    } else if (widget.mode == BookListMode.favourites) {
        message = "No favourites yet ❤️\nAdd books to your wishlist";
    } else {
        message = "No books available";
    }

    return Center(
        child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
        ),
    );
    }
}