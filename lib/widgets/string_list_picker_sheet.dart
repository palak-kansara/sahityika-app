import 'package:flutter/material.dart';

/// Picks one string from an API-backed list or a custom entry. Returns via
/// [Navigator.pop] with the chosen value.
class StringListPickerSheet extends StatefulWidget {
  const StringListPickerSheet({
    super.key,
    required this.title,
    required this.loadItems,
    this.customEntryLabel = 'Not listed? Enter custom',
    this.searchHint = 'Search',
    this.customDialogTitle = 'Enter name',
    this.showCustomEntry = true,
  });

  final String title;
  final Future<List<String>> Function() loadItems;
  final String customEntryLabel;
  final String searchHint;
  final String customDialogTitle;
  final bool showCustomEntry;

  @override
  State<StringListPickerSheet> createState() => _StringListPickerSheetState();
}

class _CustomStringDialog extends StatefulWidget {
  const _CustomStringDialog({required this.title});

  final String title;

  @override
  State<_CustomStringDialog> createState() => _CustomStringDialogState();
}

class _CustomStringDialogState extends State<_CustomStringDialog> {
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
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          hintText: 'Type here',
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
          child: const Text('Use this'),
        ),
      ],
    );
  }
}

class _StringListPickerSheetState extends State<StringListPickerSheet> {
  final _searchController = TextEditingController();

  List<String> _all = [];
  bool _loading = true;
  bool _error = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
      _errorMessage = null;
    });
    try {
      final items = await widget.loadItems();
      if (!mounted) return;
      setState(() {
        _all = items;
        _loading = false;
      });
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  List<String> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _all;
    return _all.where((s) => s.toLowerCase().contains(q)).toList();
  }

  void _select(String value) {
    final t = value.trim();
    if (t.isEmpty) return;
    Navigator.of(context).pop<String>(t);
  }

  Future<void> _showCustomDialog() async {
    final name = await showDialog<String>(
      context: context,
      useRootNavigator: true,
      builder: (_) => _CustomStringDialog(title: widget.customDialogTitle),
    );
    if (name == null || name.isEmpty || !mounted) return;
    _select(name);
  }

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
                      widget.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop<String>(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: widget.searchHint,
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (_) => setState(() {}),
            ),
            if (widget.showCustomEntry) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _showCustomDialog,
                icon: const Icon(Icons.edit_outlined),
                label: Text(widget.customEntryLabel),
              ),
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
    );

    if (_error) {
      return [
        header,
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  _errorMessage ?? 'Could not load list',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _load,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    if (_loading) {
      return [
        header,
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    final filtered = _filtered;
    if (filtered.isEmpty) {
      return [
        header,
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('No matches'),
            ),
          ),
        ),
      ];
    }

    return [
      header,
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = filtered[index];
            return ListTile(
              title: Text(item),
              onTap: () => _select(item),
            );
          },
          childCount: filtered.length,
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
          return Material(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            clipBehavior: Clip.antiAlias,
            child: CustomScrollView(
              controller: scrollController,
              physics: const AlwaysScrollableScrollPhysics(
                parent: ClampingScrollPhysics(),
              ),
              slivers: _buildSlivers(context),
            ),
          );
        },
      ),
    );
  }
}
