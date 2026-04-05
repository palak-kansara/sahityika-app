import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/book.dart';
import '../screens/manual_add_book_screen.dart';
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
  int? _readId;
  bool _progressLoading = false;
  int _pageRead = 0;
  int? _totalPages;
  double _progress = 0.0;
  final TextEditingController _pageReadController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _bookFuture = BookService.fetchBookDetail(widget.bookId).then((book) {
      _isFav = book.isFav;
      _isRead = book.isRead;
      _readId = book.readId;
      if (_readId != null) {
        _loadReadingProgress(_readId!);
      }
      return book;
    });
  }

  @override
  void dispose() {
    _pageReadController.dispose();
    super.dispose();
  }

  Future<void> _loadReadingProgress(int readId) async {
    if (_progressLoading) return;

    setState(() => _progressLoading = true);
    try {
      final entry = await ReadingService.fetchReadingEntry(readId);
      if (!mounted) return;
      setState(() {
        _pageRead = entry.pageRead;
        _totalPages = entry.totalPages;
        _progress = entry.progress;
        _pageReadController.text = entry.pageRead.toString();
      });
    } catch (_) {
      // keep UI usable even if progress fetch fails
    } finally {
      if (mounted) setState(() => _progressLoading = false);
    }
  }

  Future<void> _savePageRead() async {
    if (_readId == null) return;

    final int? value = int.tryParse(_pageReadController.text.trim());
    if (value == null || value < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid page number')),
      );
      return;
    }

    setState(() => _progressLoading = true);
    try {
      final entry = await ReadingService.updatePageRead(
        readingId: _readId!,
        pageRead: value,
      );
      if (!mounted) return;
      setState(() {
        _pageRead = entry.pageRead;
        _totalPages = entry.totalPages;
        _progress = entry.progress;
        _pageReadController.text = entry.pageRead.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Progress updated')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update progress')),
      );
    } finally {
      if (mounted) setState(() => _progressLoading = false);
    }
  }

  Future<void> _handleReadingToggle(Book book) async {
    if (_readingLoading) return;

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
        if (_readId == null) throw Exception('Missing read_id for this book');
        response = await ReadingService.removeFromReading(_readId!);
        setState(() {
          _readId = null;
          _isRead = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Book removed from reading list')),
        );
      } else {
        response = await ReadingService.addToReading(book.id);
        final int? newReadId = (response['id'] as num?)?.toInt();
        setState(() {
          _readId = newReadId;
          _isRead = newReadId != null;
        });
        if (newReadId != null) {
          await _loadReadingProgress(newReadId);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Book added to reading list')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reading list update failed')),
      );
    } finally {
      if (mounted) setState(() => _readingLoading = false);
    }
  }

  Future<void> _openEditScreen(Book book) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ManualAddBookScreen(initialBook: book),
      ),
    );
    if (updated == true && mounted) {
      setState(() {
        _bookFuture = BookService.fetchBookDetail(widget.bookId).then((b) {
          _isFav = b.isFav;
          _isRead = b.isRead;
          _readId = b.readId;
          if (_readId != null) _loadReadingProgress(_readId!);
          return b;
        });
      });
    }
  }

  void _openPreview(String previewLink) async {
    if (previewLink.isEmpty) return;
    final uri = Uri.parse(previewLink);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _toggleWishlist(int bookId) async {
    if (_wishlistLoading) return;
    setState(() => _wishlistLoading = true);
    try {
      final response = await BookService.toggleWishlist(bookId);
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
      if (mounted) setState(() => _wishlistLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Book>(
        future: _bookFuture,
        builder: (context, snapshot) {
          final book = snapshot.data;
          return Scaffold(
            appBar: AppBar(
              title: const Text('Book Details'),
              actions: [
                if (book != null)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Edit book',
                    onPressed: () => _openEditScreen(book),
                  ),
              ],
            ),
            body: snapshot.connectionState == ConnectionState.waiting
                ? const Center(child: CircularProgressIndicator())
                : snapshot.hasError
                    ? const Center(child: Text('Failed to load book details'))
                    : book == null
                        ? const Center(child: Text('Book not found'))
                        : _buildContent(context, book),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, Book book) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Hero Header ──────────────────────────────────
          Container(
            width: double.infinity,
            color: colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: book.thumbnail.isNotEmpty
                      ? Image.network(
                          book.thumbnail,
                          height: 220,
                          width: 148,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Image.asset(
                            'assets/icon/app_icon.jpeg',
                            height: 220,
                            width: 148,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Image.asset(
                          'assets/icon/app_icon.jpeg',
                          height: 220,
                          width: 148,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Title + Subtitle + Authors ───────────
                Text(
                  book.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (book.subtitle != null && book.subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    book.subtitle!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  book.authors.map((a) => a.name).join(', '),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 16),

                // ── Metadata chips ───────────────────────
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (book.publishedDate != null &&
                        book.publishedDate!.isNotEmpty)
                      _InfoChip(
                        icon: Icons.calendar_today_outlined,
                        label: book.publishedDate!,
                      ),
                    if (book.pageCount != null && book.pageCount!.isNotEmpty)
                      _InfoChip(
                        icon: Icons.menu_book_outlined,
                        label: '${book.pageCount} pages',
                      ),
                    if (book.language != null && book.language!.isNotEmpty)
                      _InfoChip(
                        icon: Icons.language_outlined,
                        label: book.language!.toUpperCase(),
                      ),
                    if (book.publisher != null && book.publisher!.isNotEmpty)
                      _InfoChip(
                        icon: Icons.business_outlined,
                        label: book.publisher!,
                      ),
                  ],
                ),

                if (book.categories != null && book.categories!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: book.categories!
                        .split('/')
                        .map(
                          (c) => Chip(
                            label: Text(
                              c.trim(),
                              style: const TextStyle(fontSize: 12),
                            ),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            backgroundColor: colorScheme.secondaryContainer,
                          ),
                        )
                        .toList(),
                  ),
                ],

                const SizedBox(height: 20),

                // ── Action Buttons ───────────────────────
                Row(
                  children: [
                    _wishlistLoading
                        ? const SizedBox(
                            width: 48,
                            height: 48,
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          )
                        : _isFav
                            ? IconButton.filled(
                                icon: const Icon(Icons.favorite),
                                tooltip: 'Remove from Wishlist',
                                onPressed: () => _toggleWishlist(book.id),
                              )
                            : IconButton.outlined(
                                icon: const Icon(Icons.favorite_border),
                                tooltip: 'Add to Wishlist',
                                onPressed: () => _toggleWishlist(book.id),
                              ),
                    const SizedBox(width: 8),
                    _readingLoading
                        ? const SizedBox(
                            width: 48,
                            height: 48,
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          )
                        : _isRead
                            ? IconButton.filled(
                                icon: const Icon(Icons.menu_book),
                                tooltip: 'Remove from Reading List',
                                onPressed: () => _handleReadingToggle(book),
                              )
                            : IconButton.outlined(
                                icon: const Icon(Icons.book_outlined),
                                tooltip: 'Add to Reading List',
                                onPressed: () => _handleReadingToggle(book),
                              ),
                    const Spacer(),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('Preview'),
                      onPressed: book.previewLink.isNotEmpty
                          ? () => _openPreview(book.previewLink)
                          : null,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Reading Progress ─────────────────────
                if (_isRead) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Reading Progress',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${(_progress * 100).round()}%',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: _progress,
                            minHeight: 10,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Page counter
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _totalPages != null && _totalPages! > 0
                                  ? 'Page $_pageRead of $_totalPages'
                                  : 'Page $_pageRead read',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (_totalPages != null && _totalPages! > 0 && _pageRead < _totalPages!)
                              Text(
                                '${_totalPages! - _pageRead} pages left',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 14),
                        // Update row
                        Row(
                          children: [
                            // Decrement
                            IconButton.outlined(
                              icon: const Icon(Icons.remove, size: 18),
                              visualDensity: VisualDensity.compact,
                              onPressed: _progressLoading
                                  ? null
                                  : () {
                                      final cur = int.tryParse(
                                            _pageReadController.text,
                                          ) ??
                                          _pageRead;
                                      if (cur > 0) {
                                        _pageReadController.text =
                                            (cur - 1).toString();
                                      }
                                    },
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _pageReadController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: const InputDecoration(
                                  labelText: 'Pages read',
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Increment
                            IconButton.outlined(
                              icon: const Icon(Icons.add, size: 18),
                              visualDensity: VisualDensity.compact,
                              onPressed: _progressLoading
                                  ? null
                                  : () {
                                      final cur = int.tryParse(
                                            _pageReadController.text,
                                          ) ??
                                          _pageRead;
                                      _pageReadController.text =
                                          (cur + 1).toString();
                                    },
                            ),
                            const SizedBox(width: 10),
                            FilledButton(
                              onPressed:
                                  _progressLoading ? null : _savePageRead,
                              child: _progressLoading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Save'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // ── ISBN (subtle) ────────────────────────
                if (book.isbn10.isNotEmpty || book.isbn13.isNotEmpty) ...[
                  Text(
                    [
                      if (book.isbn10.isNotEmpty) 'ISBN-10: ${book.isbn10}',
                      if (book.isbn13.isNotEmpty) 'ISBN-13: ${book.isbn13}',
                    ].join('   '),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // ── Description ──────────────────────────
                if (book.description.isNotEmpty) ...[
                  Text(
                    'About',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    book.description,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

