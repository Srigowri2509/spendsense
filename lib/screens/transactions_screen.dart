// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models/transaction_filter.dart';
import '../widgets/empty_state.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../widgets/dismissible_activity_tile.dart';
import 'expense_detail_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  TransactionFilter _filter = const TransactionFilter();
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final filteredTransactions = _filter.apply(app.transactions);

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Transactions'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search merchant...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: _showFilterSheet,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              onChanged: (value) {
                setState(() {
                  _filter = _filter.copyWith(
                    merchantSearch: value.isEmpty ? null : value,
                    clearMerchantSearch: value.isEmpty,
                  );
                });
              },
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Active filters chips
          if (_filter.hasActiveFilters)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (_filter.categories != null && _filter.categories!.isNotEmpty)
                      ..._filter.categories!.map((cat) {
                        final category = app.categories.firstWhere((c) => c.type == cat);
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Chip(
                            avatar: Icon(category.icon, size: 16),
                            label: Text(category.name),
                            onDeleted: () {
                              setState(() {
                                final newCats = Set<CategoryType>.from(_filter.categories!);
                                newCats.remove(cat);
                                _filter = _filter.copyWith(
                                  categories: newCats.isEmpty ? null : newCats,
                                  clearCategories: newCats.isEmpty,
                                );
                              });
                            },
                          ),
                        );
                      }),
                    if (_filter.dateRange != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Chip(
                          avatar: const Icon(Icons.calendar_today, size: 16),
                          label: Text(
                            '${_filter.dateRange!.start.day}/${_filter.dateRange!.start.month} - ${_filter.dateRange!.end.day}/${_filter.dateRange!.end.month}',
                          ),
                          onDeleted: () {
                            setState(() {
                              _filter = _filter.copyWith(clearDateRange: true);
                            });
                          },
                        ),
                      ),
                    if (_filter.minAmount != null || _filter.maxAmount != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Chip(
                          avatar: const Icon(Icons.attach_money, size: 16),
                          label: Text(
                            '${_filter.minAmount?.toStringAsFixed(0) ?? '0'} - ${_filter.maxAmount?.toStringAsFixed(0) ?? '∞'}',
                          ),
                          onDeleted: () {
                            setState(() {
                              _filter = _filter.copyWith(
                                clearMinAmount: true,
                                clearMaxAmount: true,
                              );
                            });
                          },
                        ),
                      ),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _filter = const TransactionFilter();
                          _searchController.clear();
                        });
                      },
                      icon: const Icon(Icons.clear_all, size: 16),
                      label: const Text('Clear All'),
                    ),
                  ],
                ),
              ),
            ),

          // Transactions list
          Expanded(
            child: filteredTransactions.isEmpty
                ? app.transactions.isEmpty
                    ? EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'No expenses yet',
                        message: 'Start tracking your spending by adding your first expense',
                        actionLabel: 'Add Expense',
                        onAction: () => Navigator.pop(context),
                      )
                    : EmptyState(
                        icon: Icons.search_off,
                        title: 'No matching expenses',
                        message: 'Try adjusting your filters to see more results',
                        actionLabel: 'Clear Filters',
                        onAction: () {
                          setState(() {
                            _filter = const TransactionFilter();
                            _searchController.clear();
                          });
                        },
                      )
                : ListView.builder(
                    itemCount: filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final transaction = filteredTransactions[index];
                      return DismissibleActivityTile(
                        item: transaction,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ExpenseDetailScreen(transaction: transaction),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _showFilterSheet() async {
    final result = await showModalBottomSheet<TransactionFilter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        currentFilter: _filter,
        categories: AppScope.of(context).categories,
      ),
    );

    if (result != null) {
      setState(() {
        _filter = result;
        // Update search controller if merchant search changed
        if (result.merchantSearch != null) {
          _searchController.text = result.merchantSearch!;
        } else {
          _searchController.clear();
        }
      });
    }
  }
}
