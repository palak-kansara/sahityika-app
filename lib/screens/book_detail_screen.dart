import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/book.dart';
import '../services/book_list_service.dart';
import '../services/reading_service.dart';

class BookDetailScreen extends StatefulWidget {
  final int bookId;

  const BookDetailScreen({
    super.key,
    required this.bookId,
  });

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
    late Future<Book> _bookFuture;
    bool _isFav = false;
    bool _wishlistLoading = false;
    bool _isRead = false;
    bool _readingLoading = false;
    bool _hasSyncedRead = false;
    int? _readId;

  @override
  void initState() {
    super.initState();
    _bookFuture = BookService.fetchBookDetail(widget.bookId).then((book) {
    // _isFav = book.isFav;
    _isRead = book.isRead;
    _readId = book.readId;
    return book;
  });
  }

  Future<void> _handleReadingToggle(Book book) async {
    if (_readingLoading) return;

    // If already in reading list, confirm removal & progress reset
    if (_isRead) {
      final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Remove from reading list?'),
              content: const Text(
                'All reading progress for this book will be deleted. '
                'Do you want to continue?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Yes, remove'),
                ),
              ],
            ),
          ) ??
          false;

      if (!confirmed) return;
    }

    setState(() => _readingLoading = true);

    try {
      Map<String, dynamic> response;
      if (_isRead) {
        // DELETE: remove from reading list using read_id
        if (_readId == null) {
          throw Exception('Missing read_id for this book');
        }
        response = await ReadingService.removeFromReading(_readId!);
        setState(() {
          _readId = null;
          _isRead = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Book removed from reading list")),
        );
      } else {
        // POST: add to reading list using book id
        response = await ReadingService.addToReading(book.id);
        // Response example: {"id":15,"book":{...}}
        final int? newReadId = (response['id'] as num?)?.toInt();
        setState(() {
          _readId = newReadId;
          _isRead = newReadId != null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Book added to reading list")),
        );
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reading list update failed')),
      );
    } finally {
      if (mounted) {
        setState(() => _readingLoading = false);
      }
    }
  }

  void _openPreview(String previewLink) async {
    if (previewLink.isEmpty) return;

    final uri = Uri.parse(previewLink);
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    }
  }

    Future<void> _toggleWishlist(int bookId) async {
        if (_wishlistLoading) return;

        setState(() => _wishlistLoading = true);

        try {
            final response = await BookService.toggleWishlist(bookId);
            // response is Map<String, dynamic>

            setState(() {
            _isFav = response['data']['is_fav'] ?? false;
            });

            final message = response['message'];
            if (message != null && message.toString().isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(message)),
            );
            }
        } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Wishlist update failed')),
            );
        } finally {
            if (mounted) {
            setState(() => _wishlistLoading = false);
            }
        }
    }

 @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Book Details'),
    ),
    body: FutureBuilder<Book>(
      future: _bookFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Failed to load book details'));
        }

        if (!snapshot.hasData) {
          return const Center(child: Text('Book not found'));
        }

        final book = snapshot.data!;

        // ✅ SAFE PLACE FOR STATE SYNC
        if (!_isFav) {
          _isFav = book.isFav;
        }


        return _buildContent(context, book);
      },
    ),
  );
}


  Widget _buildContent(BuildContext context, Book book) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover Image
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: book.thumbnail.isNotEmpty
                  ? Image.network(
                      book.thumbnail,
                      height: 220,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'assets/icon/app_icon.jpeg',
                          height: 220,
                          fit: BoxFit.cover,
                        );
                      },
                    )
                  : Image.asset(
                      'assets/icon/app_icon.jpeg',
                      height: 220,
                      fit: BoxFit.cover,
                    ),
            ),
          ),

          const SizedBox(height: 24),

          // Title
          Text(
            book.title,
            style: Theme.of(context).textTheme.headlineMedium,
          ),

          if (book.subtitle != null && book.subtitle!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                book.subtitle!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),

          const SizedBox(height: 12),

          // Authors
          Text(
            'Author(s): ${book.authors.map((a) => a.name).join(', ')}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),

          const SizedBox(height: 12),

          // ISBN
          Text('ISBN-10: ${book.isbn10}'),
          Text('ISBN-13: ${book.isbn13}'),

          const SizedBox(height: 20),

          // Description
          Text(
            'Description',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),

          Text(
            book.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),

          const SizedBox(height: 24),

          // Actions
          Row(
            children: [
              Expanded(
                child: IconButton(
                    onPressed: _wishlistLoading
                        ? null
                        : () => _toggleWishlist(book.id),
                    icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                        _isFav ? Icons.favorite : Icons.favorite_border,
                        key: ValueKey(_isFav),
                        color: _isFav
                            ? Theme.of(context).colorScheme.primary // Gold
                            : Theme.of(context).iconTheme.color,
                        size: 26,
                        ),
                    ),
                    tooltip: _isFav ? 'Remove from Wishlist' : 'Add to Wishlist',
)
              ),
              const SizedBox(width: 12),
              Expanded(
                child: IconButton(
                  onPressed: _readingLoading
                      ? null
                      : () => _handleReadingToggle(book),
                  icon: Icon(
                    _isRead ? Icons.menu_book : Icons.book_outlined,
                    color: _isRead
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).iconTheme.color,
                    size: 26,
                  ),
                  tooltip:
                      _isRead ? 'Open (in reading list)' : 'Add to Reading List',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Preview'),
                  onPressed: () => _openPreview(book.previewLink),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
