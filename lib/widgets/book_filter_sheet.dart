import 'dart:async';

import 'package:flutter/material.dart';

import '../models/author.dart';
import '../models/book_filters.dart';
import '../services/author_service.dart';
import '../services/book_option_lists_service.dart';
import '../widgets/string_list_picker_sheet.dart';

/// Presents filter options and returns a [BookFilters] when the user taps Apply.
///
/// Usage:
/// ```dart
/// final result = await showModalBottomSheet<BookFilters>(
///   context: context,
///   isScrollControlled: true,
///   builder: (_) => BookFilterSheet(current: _filters),
/// );
/// if (result != null) setState(() => _filters = result);
/// ```
class BookFilterSheet extends StatefulWidget {
  const BookFilterSheet({super.key, required this.current});

  final BookFilters current;

  @override
  State<BookFilterSheet> createState() => _BookFilterSheetState();
}

class _BookFilterSheetState extends State<BookFilterSheet> {
  late String? _category;
  late String? _publisher;
  late String? _author;
  late String? _language;

  static const _languages = <({String label, String code})>[
    (label: 'English', code: 'en'),
    (label: 'Gujarati', code: 'gu'),
    (label: 'Hindi', code: 'hi'),
  ];

  @override
  void initState() {
    super.initState();
    _category = widget.current.category;
    _publisher = widget.current.publisher;
    _author = widget.current.author;
    _language = widget.current.language;
  }

  Future<void> _pickCategory() async {
    final topGap = MediaQuery.paddingOf(context).top + 8.0;
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      builder: (_) => Padding(
        padding: EdgeInsets.only(top: topGap),
        child: StringListPickerSheet(
          title: 'Filter by Category',
          loadItems: BookOptionListsService.fetchCategories,
          showCustomEntry: false,
        ),
      ),
    );
    if (picked != null && mounted) setState(() => _category = picked);
  }

  Future<void> _pickPublisher() async {
    final topGap = MediaQuery.paddingOf(context).top + 8.0;
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      builder: (_) => Padding(
        padding: EdgeInsets.only(top: topGap),
        child: StringListPickerSheet(
          title: 'Filter by Publisher',
          loadItems: BookOptionListsService.fetchPublishers,
          showCustomEntry: false,
        ),
      ),
    );
    if (picked != null && mounted) setState(() => _publisher = picked);
  }

  Future<void> _pickAuthor() async {
    final topGap = MediaQuery.paddingOf(context).top + 8.0;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      builder: (_) => Padding(
        padding: EdgeInsets.only(top: topGap),
        child: _SingleAuthorPickerSheet(
          current: _author,
          onPicked: (name) {
            if (mounted) setState(() => _author = name);
          },
        ),
      ),
    );
  }

  void _apply() {
    Navigator.of(context).pop(BookFilters(
      category: _category,
      publisher: _publisher,
      author: _author,
      language: _language,
    ));
  }

  void _clearAll() {
    setState(() {
      _category = null;
      _publisher = null;
      _author = null;
      _language = null;
    });
  }

  int get _activeCount => [_category, _publisher, _author, _language]
      .where((e) => e != null && e.isNotEmpty)
      .length;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Material(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Filters',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  if (_activeCount > 0)
                    TextButton(
                      onPressed: _clearAll,
                      child: const Text('Clear all'),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),

              // Category
              _FilterTile(
                label: 'Category',
                value: _category,
                icon: Icons.category_outlined,
                onTap: _pickCategory,
                onClear: () => setState(() => _category = null),
              ),
              const SizedBox(height: 8),

              // Publisher
              _FilterTile(
                label: 'Publication',
                value: _publisher,
                icon: Icons.business_outlined,
                onTap: _pickPublisher,
                onClear: () => setState(() => _publisher = null),
              ),
              const SizedBox(height: 8),

              // Author
              _FilterTile(
                label: 'Author',
                value: _author,
                icon: Icons.person_outline,
                onTap: _pickAuthor,
                onClear: () => setState(() => _author = null),
              ),

              const SizedBox(height: 16),

              // Language
              Text('Language', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // "All" option
                    _LanguageChip(
                      label: 'All',
                      selected: _language == null || _language!.isEmpty,
                      onTap: () => setState(() => _language = null),
                    ),
                    const SizedBox(width: 8),
                    for (final lang in _languages) ...[
                      _LanguageChip(
                        label: lang.label,
                        selected: _language == lang.code,
                        onTap: () => setState(() => _language = lang.code),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              FilledButton(
                onPressed: _apply,
                child: Text(
                  _activeCount > 0
                      ? 'Apply ($_activeCount filter${_activeCount > 1 ? 's' : ''})'
                      : 'Apply',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterTile extends StatelessWidget {
  const _FilterTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    required this.onClear,
  });

  final String label;
  final String? value;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasValue = value != null && value!.isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: hasValue
              ? scheme.primaryContainer.withValues(alpha: 0.4)
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: hasValue
              ? Border.all(color: scheme.primary.withValues(alpha: 0.4))
              : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: hasValue ? scheme.primary : null),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: hasValue ? scheme.primary : null,
                        ),
                  ),
                  if (hasValue)
                    Text(
                      value!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (hasValue)
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                visualDensity: VisualDensity.compact,
                onPressed: onClear,
              )
            else
              const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _LanguageChip extends StatelessWidget {
  const _LanguageChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
    );
  }
}

/// A simplified author picker for single-selection filtering.
class _SingleAuthorPickerSheet extends StatefulWidget {
  const _SingleAuthorPickerSheet({
    required this.current,
    required this.onPicked,
  });

  final String? current;
  final void Function(String name) onPicked;

  @override
  State<_SingleAuthorPickerSheet> createState() =>
      _SingleAuthorPickerSheetState();
}

class _SingleAuthorPickerSheetState extends State<_SingleAuthorPickerSheet> {
  final _searchController = TextEditingController();
  ScrollController? _sheetScrollController;

  final List<Author> _authors = [];
  int _page = 1;
  bool _hasNext = true;
  bool _loading = false;
  bool _initialError = false;
  Timer? _debounce;

  static const int _maxAutoChainLoads = 12;

  String get _query => _searchController.text.trim();

  @override
  void initState() {
    super.initState();
    _fetchPage(1, append: false);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onScrollNearEnd() {
    if (!_hasNext || _loading) return;
    final c = _sheetScrollController;
    if (c == null || !c.hasClients) return;
    final m = c.position;
    if (!m.hasContentDimensions) return;
    if (m.extentAfter < 320) _fetchPage(_page + 1, append: true);
  }

  void _scheduleAutoChainLoads({int remaining = _maxAutoChainLoads}) {
    if (remaining <= 0 || !_hasNext || _loading) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !_hasNext || _loading) return;
      final c = _sheetScrollController;
      if (c == null || !c.hasClients) return;
      final m = c.position;
      if (!m.hasContentDimensions) return;
      if (m.maxScrollExtent < 72) {
        await _fetchPage(_page + 1, append: true);
        if (!mounted || remaining <= 1) return;
        _scheduleAutoChainLoads(remaining: remaining - 1);
      }
    });
  }

  Future<void> _fetchPage(int page, {required bool append}) async {
    setState(() {
      _loading = true;
      if (!append) _initialError = false;
    });
    try {
      final result =
          await AuthorService.fetchAuthors(page: page, search: _query);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _page = page;
        _hasNext = result.hasNext;
        if (append) {
          _authors.addAll(result.authors);
        } else {
          _authors
            ..clear()
            ..addAll(result.authors);
        }
      });
      _scheduleAutoChainLoads();
    } on Exception {
      if (mounted) {
        setState(() {
          _loading = false;
          if (!append) _initialError = true;
        });
      }
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      _fetchPage(1, append: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final viewBottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: viewBottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        minChildSize: 0.38,
        maxChildSize: 0.94,
        builder: (context, scrollController) {
          _sheetScrollController = scrollController;

          return Material(
            color: scheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
            clipBehavior: Clip.antiAlias,
            child: NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n is! ScrollUpdateNotification &&
                    n is! OverscrollNotification) {
                  return false;
                }
                if (n.metrics.axis == Axis.vertical) _onScrollNearEnd();
                return false;
              },
              child: CustomScrollView(
                controller: scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: ClampingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 8),
                          Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: scheme.outlineVariant,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Filter by Author',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(),
                                  icon: const Icon(Icons.close),
                                ),
                              ],
                            ),
                          ),
                          TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: 'Search authors',
                              prefixIcon: Icon(Icons.search),
                            ),
                            onChanged: _onSearchChanged,
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                  if (_initialError)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Could not load authors'),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: () => _fetchPage(1, append: false),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (_authors.isEmpty && _loading)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_authors.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: Text('No authors found')),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index < _authors.length) {
                            final a = _authors[index];
                            final isSelected = widget.current == a.name;
                            return ListTile(
                              title: Text(a.name),
                              trailing: isSelected
                                  ? Icon(Icons.check_circle,
                                      color: scheme.primary)
                                  : null,
                              onTap: () {
                                widget.onPicked(a.name);
                                Navigator.of(context).pop();
                              },
                            );
                          }
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              ),
                            ),
                          );
                        },
                        childCount:
                            _authors.length + (_loading && _hasNext ? 1 : 0),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
