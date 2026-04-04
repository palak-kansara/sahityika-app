import 'package:flutter/material.dart';

import '../models/reading_entry.dart';
import '../services/reading_service.dart';
import 'book_detail_screen.dart';

class ReadingScreen extends StatefulWidget {
  const ReadingScreen({super.key});

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  late Future<List<ReadingEntry>> _future;

  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = ReadingService.fetchReadingList();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = ReadingService.fetchReadingList(search: _query);
    });
    await _future;
  }

  void _onSearchChanged(String value) {
    _query = value.trim();

    setState(() {
      _future = ReadingService.fetchReadingList(search: _query);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _query = '';

    setState(() {
      _future = ReadingService.fetchReadingList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// TITLE
            Text(
              'Reading',
              style: Theme.of(context).textTheme.headlineMedium,
            ),

            const SizedBox(height: 20),

            /// SEARCH BOX
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search in reading list',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: _clearSearch,
                      )
                    : null,
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: FutureBuilder<List<ReadingEntry>>(
                future: _future,
                builder: (context, snapshot) {

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Failed to load reading list'),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _refresh,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  final items = snapshot.data ?? <ReadingEntry>[];

                  if (items.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView(
                        children: const [
                          SizedBox(height: 120),
                          Center(
                            child: Text(
                              'No books in your reading list yet.\nOpen a book and tap the reading icon.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final entry = items[index];
                        final percent = (entry.progress * 100).round();

                        return InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    BookDetailScreen(bookId: entry.book.id),
                              ),
                            ).then((_) => _refresh());
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: entry.book.thumbnail.isNotEmpty
                                      ? Image.network(
                                          entry.book.thumbnail,
                                          width: 64,
                                          height: 92,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Image.asset(
                                              'assets/icon/app_icon.jpeg',
                                              width: 64,
                                              height: 92,
                                              fit: BoxFit.cover,
                                            );
                                          },
                                        )
                                      : Image.asset(
                                          'assets/icon/app_icon.jpeg',
                                          width: 64,
                                          height: 92,
                                          fit: BoxFit.cover,
                                        ),
                                ),
                                const SizedBox(width: 12),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry.book.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),

                                      const SizedBox(height: 8),

                                      Row(
                                        children: [
                                          Text(
                                            '$percent%',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall,
                                          ),

                                          const SizedBox(width: 10),

                                          Expanded(
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                              child: LinearProgressIndicator(
                                                value: entry.progress,
                                                minHeight: 8,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 6),

                                      Text(
                                        entry.totalPages != null &&
                                                entry.totalPages! > 0
                                            ? 'Page ${entry.pageRead} of ${entry.totalPages}'
                                            : 'Page read: ${entry.pageRead}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}