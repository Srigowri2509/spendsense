import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models/transaction_filter.dart';

class FilterBottomSheet extends StatefulWidget {
  final TransactionFilter currentFilter;
  final List<Category> categories;

  const FilterBottomSheet({
    super.key,
    required this.currentFilter,
    required this.categories,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late Set<CategoryType> _selectedCategories;
  DateTimeRange? _dateRange;
  double? _minAmount;
  double? _maxAmount;
  String? _merchantSearch;
  TransactionSortType _sortBy = TransactionSortType.date;
  bool _sortDescending = true;

  final _minAmountCtrl = TextEditingController();
  final _maxAmountCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedCategories = widget.currentFilter.categories?.toSet() ?? {};
    _dateRange = widget.currentFilter.dateRange;
    _minAmount = widget.currentFilter.minAmount;
    _maxAmount = widget.currentFilter.maxAmount;
    _merchantSearch = widget.currentFilter.merchantSearch;
    _sortBy = widget.currentFilter.sortBy;
    _sortDescending = widget.currentFilter.sortDescending;

    if (_minAmount != null) _minAmountCtrl.text = _minAmount.toString();
    if (_maxAmount != null) _maxAmountCtrl.text = _maxAmount.toString();
    if (_merchantSearch != null) _searchCtrl.text = _merchantSearch!;
  }

  @override
  void dispose() {
    _minAmountCtrl.dispose();
    _maxAmountCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      'Filter & Sort',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _clearAll,
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Categories
                    Text(
                      'Categories',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.categories.map((c) {
                        final isSelected = _selectedCategories.contains(c.type);
                        return FilterChip(
                          avatar: Icon(c.icon, size: 18),
                          label: Text(c.name),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedCategories.add(c.type);
                              } else {
                                _selectedCategories.remove(c.type);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // Date Range
                    Text(
                      'Date Range',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _DatePresetChip(
                          label: 'Today',
                          onTap: () => _setDateRange(_getToday()),
                          isSelected: _isDateRangeEqual(_dateRange, _getToday()),
                        ),
                        _DatePresetChip(
                          label: 'This Week',
                          onTap: () => _setDateRange(_getThisWeek()),
                          isSelected: _isDateRangeEqual(_dateRange, _getThisWeek()),
                        ),
                        _DatePresetChip(
                          label: 'This Month',
                          onTap: () => _setDateRange(_getThisMonth()),
                          isSelected: _isDateRangeEqual(_dateRange, _getThisMonth()),
                        ),
                        _DatePresetChip(
                          label: 'Custom',
                          onTap: _pickCustomDateRange,
                          isSelected: _dateRange != null && !_isPresetRange(_dateRange!),
                        ),
                      ],
                    ),
                    if (_dateRange != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '${_dateRange!.start.day}/${_dateRange!.start.month}/${_dateRange!.start.year} - ${_dateRange!.end.day}/${_dateRange!.end.month}/${_dateRange!.end.year}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => setState(() => _dateRange = null),
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Amount Range
                    Text(
                      'Amount Range',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _minAmountCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Min',
                              border: OutlineInputBorder(),
                              prefixText: '₹ ',
                            ),
                            onChanged: (v) {
                              _minAmount = double.tryParse(v);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _maxAmountCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Max',
                              border: OutlineInputBorder(),
                              prefixText: '₹ ',
                            ),
                            onChanged: (v) {
                              _maxAmount = double.tryParse(v);
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Merchant Search
                    Text(
                      'Merchant Search',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _searchCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Search merchant',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (v) {
                        _merchantSearch = v.isEmpty ? null : v;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Sort Options
                    Text(
                      'Sort By',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<TransactionSortType>(
                      segments: const [
                        ButtonSegment(
                          value: TransactionSortType.date,
                          label: Text('Date'),
                          icon: Icon(Icons.calendar_today, size: 16),
                        ),
                        ButtonSegment(
                          value: TransactionSortType.amount,
                          label: Text('Amount'),
                          icon: Icon(Icons.attach_money, size: 16),
                        ),
                        ButtonSegment(
                          value: TransactionSortType.merchant,
                          label: Text('Merchant'),
                          icon: Icon(Icons.store, size: 16),
                        ),
                      ],
                      selected: {_sortBy},
                      onSelectionChanged: (Set<TransactionSortType> newSelection) {
                        setState(() => _sortBy = newSelection.first);
                      },
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Descending Order'),
                      value: _sortDescending,
                      onChanged: (v) => setState(() => _sortDescending = v),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),

              // Apply Button
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                ),
                child: FilledButton(
                  onPressed: _applyFilters,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _clearAll() {
    setState(() {
      _selectedCategories.clear();
      _dateRange = null;
      _minAmount = null;
      _maxAmount = null;
      _merchantSearch = null;
      _minAmountCtrl.clear();
      _maxAmountCtrl.clear();
      _searchCtrl.clear();
      _sortBy = TransactionSortType.date;
      _sortDescending = true;
    });
  }

  void _applyFilters() {
    final filter = TransactionFilter(
      categories: _selectedCategories.isEmpty ? null : _selectedCategories,
      dateRange: _dateRange,
      minAmount: _minAmount,
      maxAmount: _maxAmount,
      merchantSearch: _merchantSearch,
      sortBy: _sortBy,
      sortDescending: _sortDescending,
    );
    Navigator.pop(context, filter);
  }

  void _setDateRange(DateTimeRange range) {
    setState(() => _dateRange = range);
  }

  Future<void> _pickCustomDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  DateTimeRange _getToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return DateTimeRange(start: today, end: today);
  }

  DateTimeRange _getThisWeek() {
    final now = DateTime.now();
    final weekday = now.weekday;
    final start = now.subtract(Duration(days: weekday - 1));
    final startDate = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(now.year, now.month, now.day);
    return DateTimeRange(start: startDate, end: endDate);
  }

  DateTimeRange _getThisMonth() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month, now.day);
    return DateTimeRange(start: start, end: end);
  }

  bool _isDateRangeEqual(DateTimeRange? a, DateTimeRange b) {
    if (a == null) return false;
    return a.start.year == b.start.year &&
           a.start.month == b.start.month &&
           a.start.day == b.start.day &&
           a.end.year == b.end.year &&
           a.end.month == b.end.month &&
           a.end.day == b.end.day;
  }

  bool _isPresetRange(DateTimeRange range) {
    return _isDateRangeEqual(range, _getToday()) ||
           _isDateRangeEqual(range, _getThisWeek()) ||
           _isDateRangeEqual(range, _getThisMonth());
  }
}

class _DatePresetChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isSelected;

  const _DatePresetChip({
    required this.label,
    required this.onTap,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
    );
  }
}
