import 'dart:async';

import 'package:flutter/material.dart';

import '../models/author.dart';
import '../services/author_service.dart';

/// Dialog that owns its [TextEditingController] so it is not disposed while
/// the route is still animating (avoids framework assertions).
class _NewAuthorNameDialog extends StatefulWidget {
  const _NewAuthorNameDialog();

  @override
  State<_NewAuthorNameDialog> createState() => _NewAuthorNameDialogState();
}

class _NewAuthorNameDialogState extends State<_NewAuthorNameDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final t = _controller.text.trim();
    Navigator.of(context).pop<String>(t.isEmpty ? null : t);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New author'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          hintText: 'Author name',
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop<String>(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Add'),
        ),
      ],
    );
  }
}

/// Bottom sheet: browse paginated authors, search, pick, or add a new name.
///
/// Uses [DraggableScrollableSheet] + one [CustomScrollView] so the same
/// [ScrollController] handles sheet resize and list scrolling (avoids gesture
/// conflicts with [showModalBottomSheet]).
class AuthorPickerSheet extends StatefulWidget {
  const AuthorPickerSheet({
    super.key,
    required this.alreadySelected,
    required this.onPick,
  });

  final Set<String> alreadySelected;
  final void Function(String name) onPick;

  @override
  State<AuthorPickerSheet> createState() => _AuthorPickerSheetState();
}

class _AuthorPickerSheetState extends State<AuthorPickerSheet> {
  final _searchController = TextEditingController();

  /// Provided by [DraggableScrollableSheet] — do not dispose.
  ScrollController? _sheetScrollController;

  late Set<String> _sessionSelected;

  final List<Author> _authors = [];
  int _page = 1;
  bool _hasNext = true;
  bool _loading = false;
  bool _initialError = false;
  String? _errorMessage;
  Timer? _searchDebounce;

  static const int _maxAutoChainLoads = 12;

  @override
  void initState() {
    super.initState();
    _sessionSelected = Set<String>.from(widget.alreadySelected);
    _loadFirstPage();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onScrollNearEnd() {
    if (!_hasNext || _loading) return;
    final c = _sheetScrollController;
    if (c == null || !c.hasClients) return;
    final m = c.position;
    if (!m.hasContentDimensions) return;
    if (m.extentAfter < 320) {
      _loadNextPage();
    }
  }

  String get _searchQuery => _searchController.text.trim();

  Future<void> _loadFirstPage() async {
    setState(() {
      _page = 1;
      _authors.clear();
      _hasNext = true;
      _initialError = false;
      _errorMessage = null;
    });
    await _fetchPage(1, append: false);
  }

  Future<void> _loadNextPage() async {
    if (!_hasNext || _loading) return;
    await _fetchPage(_page + 1, append: true);
  }

  void _scheduleAutoChainLoads({int remaining = _maxAutoChainLoads}) {
    if (remaining <= 0 || !_hasNext || _loading) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !_hasNext || _loading) return;
      final c = _sheetScrollController;
      if (c == null || !c.hasClients) return;
      final m = c.position;
      if (!m.hasContentDimensions) return;
      // Short content: no real scroll range — fetch another page until list grows or API ends.
      if (m.maxScrollExtent < 72) {
        await _loadNextPage();
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
      final result = await AuthorService.fetchAuthors(
        page: page,
        search: _searchQuery,
      );
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
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (!append) {
          _initialError = true;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        }
      });
    }
  }

  void _onSearchChanged(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      _loadFirstPage();
    });
  }

  Future<void> _showAddNewDialog() async {
    final name = await showDialog<String>(
      context: context,
      useRootNavigator: true,
      builder: (_) => const _NewAuthorNameDialog(),
    );
    if (name == null || name.isEmpty || !mounted) return;
    _handlePick(name);
  }

  void _handlePick(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return;
    if (_sessionSelected.contains(t)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Author already added')),
      );
      return;
    }
    widget.onPick(t);
    setState(() => _sessionSelected.add(t));
  }

  bool _isSelected(String name) => _sessionSelected.contains(name);

  List<Widget> _buildSlivers(BuildContext context) {
    final header = SliverToBoxAdapter(
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
                  color: Theme.of(context).colorScheme.outlineVariant,
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
                      'Choose author',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
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
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _showAddNewDialog,
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: const Text('Author not listed? Add new'),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );

    if (_initialError) {
      return [
        header,
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  _errorMessage ?? 'Could not load authors',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _loadFirstPage,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    if (_authors.isEmpty && _loading) {
      return [
        header,
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (_authors.isEmpty) {
      return [
        header,
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: Text('No authors found')),
        ),
      ];
    }

    return [
      header,
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index < _authors.length) {
              final a = _authors[index];
              final picked = _isSelected(a.name);
              return ListTile(
                title: Text(a.name),
                trailing: picked
                    ? Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () => _handlePick(a.name),
              );
            }
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          },
          childCount: _authors.length + (_loading && _hasNext ? 1 : 0),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
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
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            clipBehavior: Clip.antiAlias,
            child: NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification n) {
                if (n is! ScrollUpdateNotification &&
                    n is! OverscrollNotification) {
                  return false;
                }
                if (n.metrics.axis == Axis.vertical) {
                  _onScrollNearEnd();
                }
                return false;
              },
              child: CustomScrollView(
                controller: scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: ClampingScrollPhysics(),
                ),
                slivers: _buildSlivers(context),
              ),
            ),
          );
        },
      ),
    );
  }
}
