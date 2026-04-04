import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/book_add_service.dart';
import '../services/book_option_lists_service.dart';
import '../widgets/author_picker_sheet.dart';
import '../widgets/string_list_picker_sheet.dart';

class ManualAddBookScreen extends StatefulWidget {
  const ManualAddBookScreen({super.key, this.prefilledIsbn});

  /// ISBN from scanner when the backend did not return a book.
  final String? prefilledIsbn;

  @override
  State<ManualAddBookScreen> createState() => _ManualAddBookScreenState();
}

class _ManualAddBookScreenState extends State<ManualAddBookScreen> {
  final _formKey = GlobalKey<FormState>();

  final _title = TextEditingController();
  final _isbn10 = TextEditingController();
  final _isbn13 = TextEditingController();
  final _subtitle = TextEditingController();
  final _categories = TextEditingController();
  final _description = TextEditingController();
  final _pageCount = TextEditingController();
  final _publisher = TextEditingController();
  final _publishedDate = TextEditingController();
  final _thumbnail = TextEditingController();
  final _previewLink = TextEditingController();
  final _infoLink = TextEditingController();

  final List<String> _selectedAuthors = [];

  static const _languages = <({String label, String code})>[
    (label: 'English', code: 'en'),
    (label: 'Gujarati', code: 'gu'),
    (label: 'Hindi', code: 'hi'),
  ];

  String _languageCode = 'en';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.prefilledIsbn != null && widget.prefilledIsbn!.isNotEmpty) {
      _applyPrefilledIsbn(widget.prefilledIsbn!);
    }
    _publishedDate.addListener(_onPublishedDateChanged);
  }

  void _onPublishedDateChanged() => setState(() {});

  void _applyPrefilledIsbn(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[\s-]'), '');
    if (cleaned.length == 10) {
      _isbn10.text = cleaned;
    } else if (cleaned.length == 13) {
      _isbn13.text = cleaned;
    } else {
      _isbn10.text = raw.trim();
    }
  }

  static String _formatDateYmd(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  DateTime _publishedDateInitialForPicker() {
    final now = DateTime.now();
    final last = DateTime(now.year + 2);
    final first = DateTime(1900);
    final parsed = DateTime.tryParse(_publishedDate.text.trim());
    if (parsed == null) return now;
    if (parsed.isBefore(first)) return first;
    if (parsed.isAfter(last)) return last;
    return parsed;
  }

  Future<void> _openPublishedDateCalendar() async {
    if (_submitting) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: _publishedDateInitialForPicker(),
      firstDate: DateTime(1900),
      lastDate: DateTime(DateTime.now().year + 2),
      helpText: 'Published date',
    );
    if (picked != null && mounted) {
      setState(() {
        _publishedDate.text = _formatDateYmd(picked);
      });
    }
  }

  void _clearPublishedDate() {
    if (_submitting) return;
    setState(() => _publishedDate.clear());
  }

  @override
  void dispose() {
    _publishedDate.removeListener(_onPublishedDateChanged);
    _title.dispose();
    _isbn10.dispose();
    _isbn13.dispose();
    _subtitle.dispose();
    _categories.dispose();
    _description.dispose();
    _pageCount.dispose();
    _publisher.dispose();
    _publishedDate.dispose();
    _thumbnail.dispose();
    _previewLink.dispose();
    _infoLink.dispose();
    super.dispose();
  }

  void _openAuthorPicker() {
    final topGap = MediaQuery.paddingOf(context).top + 8.0;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(top: topGap),
        child: AuthorPickerSheet(
          alreadySelected: _selectedAuthors.toSet(),
          onPick: (name) {
            final t = name.trim();
            if (t.isEmpty) return;
            if (_selectedAuthors.contains(t)) return;
            setState(() => _selectedAuthors.add(t));
          },
        ),
      ),
    );
  }

  Future<void> _openCategoryPicker() async {
    final topGap = MediaQuery.paddingOf(context).top + 8.0;
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(top: topGap),
        child: StringListPickerSheet(
          title: 'Category',
          loadItems: BookOptionListsService.fetchCategories,
          customEntryLabel: 'Category not listed? Enter custom',
          customDialogTitle: 'Custom category',
        ),
      ),
    );
    if (picked != null && picked.isNotEmpty && mounted) {
      setState(() => _categories.text = picked);
    }
  }

  Future<void> _openPublisherPicker() async {
    final topGap = MediaQuery.paddingOf(context).top + 8.0;
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(top: topGap),
        child: StringListPickerSheet(
          title: 'Publisher',
          loadItems: BookOptionListsService.fetchPublishers,
          customEntryLabel: 'Publisher not listed? Enter custom',
          customDialogTitle: 'Custom publisher',
        ),
      ),
    );
    if (picked != null && picked.isNotEmpty && mounted) {
      setState(() => _publisher.text = picked);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final payload = ManualBookPayload(
      title: _title.text.trim(),
      isbn10: _isbn10.text.trim(),
      isbn13: _isbn13.text.trim(),
      subtitle: _subtitle.text.trim(),
      authorNames: List<String>.from(_selectedAuthors),
      categories: _categories.text.trim(),
      description: _description.text.trim(),
      pageCount: _pageCount.text.trim(),
      languageCode: _languageCode,
      publisher: _publisher.text.trim(),
      publishedDate: _publishedDate.text.trim(),
      thumbnail: _thumbnail.text.trim(),
      previewLink: _previewLink.text.trim(),
      infoLink: _infoLink.text.trim(),
    );

    setState(() => _submitting = true);
    try {
      final response = await BookAddService.addManualBook(payload);
      if (!mounted) return;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Book added successfully')),
        );
        Navigator.of(context).pop(true);
        return;
      }

      String err = 'Could not add book';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['detail'] != null) {
          err = decoded['detail'].toString();
        } else if (decoded is Map && decoded['message'] != null) {
          err = decoded['message'].toString();
        } else {
          err = response.body.isNotEmpty ? response.body : err;
        }
      } catch (_) {
        err = response.body.isNotEmpty ? response.body : err;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err)),
      );
    } on Exception catch (e) {
      if (!mounted) return;
      if (e.toString().contains('SESSION_EXPIRED')) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _labeledField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          alignLabelWithHint: maxLines > 1,
        ),
      ),
    );
  }

  Widget _pickableStringField({
    required String label,
    required TextEditingController controller,
    required VoidCallback onPickFromList,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'Choose from list',
            onPressed: _submitting ? null : onPickFromList,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add book manually'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Fill in the details below. Add authors from the directory or enter a new name if needed.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            _labeledField(
              label: 'Title *',
              controller: _title,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Title is required';
                return null;
              },
            ),
            _labeledField(
              label: 'ISBN-10',
              controller: _isbn10,
              keyboardType: TextInputType.text,
            ),
            _labeledField(
              label: 'ISBN-13',
              controller: _isbn13,
              keyboardType: TextInputType.text,
            ),
            _labeledField(label: 'Subtitle', controller: _subtitle),
            Text(
              'Authors',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            if (_selectedAuthors.isEmpty)
              Text(
                'No authors selected yet.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < _selectedAuthors.length; i++)
                    InputChip(
                      label: Text(_selectedAuthors[i]),
                      onDeleted: _submitting
                          ? null
                          : () => setState(() => _selectedAuthors.removeAt(i)),
                    ),
                ],
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _submitting ? null : _openAuthorPicker,
              icon: const Icon(Icons.person_search_outlined),
              label: const Text('Add author'),
            ),
            _pickableStringField(
              label: 'Category',
              controller: _categories,
              onPickFromList: _openCategoryPicker,
            ),
            _labeledField(
              label: 'Description',
              controller: _description,
              maxLines: 4,
            ),
            _labeledField(
              label: 'Page count',
              controller: _pageCount,
              keyboardType: TextInputType.number,
            ),
            Text('Language', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: [
                for (final e in _languages)
                  ButtonSegment<String>(
                    value: e.code,
                    label: Text(e.label),
                  ),
              ],
              selected: {_languageCode},
              emptySelectionAllowed: false,
              showSelectedIcon: false,
              onSelectionChanged: (Set<String> next) {
                if (_submitting || next.isEmpty) return;
                setState(() => _languageCode = next.first);
              },
            ),
            const SizedBox(height: 14),
            _pickableStringField(
              label: 'Publisher',
              controller: _publisher,
              onPickFromList: _openPublisherPicker,
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Published date (optional)',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Pick from calendar, type a date, or clear.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _publishedDate,
                    keyboardType: TextInputType.datetime,
                    decoration: InputDecoration(
                      hintText: 'yyyy-mm-dd',
                      suffixIconConstraints: const BoxConstraints(
                        minWidth: 108,
                        minHeight: 48,
                      ),
                      suffixIcon: _submitting
                          ? null
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.calendar_today_outlined,
                                  ),
                                  tooltip: 'Pick date',
                                  visualDensity: VisualDensity.compact,
                                  onPressed: _openPublishedDateCalendar,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.clear),
                                  tooltip: 'Remove date',
                                  visualDensity: VisualDensity.compact,
                                  onPressed:
                                      _publishedDate.text.trim().isEmpty
                                          ? null
                                          : _clearPublishedDate,
                                ),
                              ],
                            ),
                    ),
                    validator: (v) {
                      final t = v?.trim() ?? '';
                      if (t.isEmpty) return null;
                      if (formatPublishedDateForApi(t) == null) {
                        return 'Use yyyy-mm-dd or dd/mm/yyyy';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            _labeledField(label: 'Thumbnail URL', controller: _thumbnail),
            _labeledField(label: 'Preview link', controller: _previewLink),
            _labeledField(label: 'Info link', controller: _infoLink),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit book'),
            ),
          ],
        ),
      ),
    );
  }
}
