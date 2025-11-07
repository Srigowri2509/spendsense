import 'package:flutter/material.dart';
import '../app_state.dart';

enum TransactionSortType { date, amount, merchant }

class TransactionFilter {
  final Set<CategoryType>? categories;
  final DateTimeRange? dateRange;
  final double? minAmount;
  final double? maxAmount;
  final String? merchantSearch;
  final TransactionSortType sortBy;
  final bool sortDescending;

  const TransactionFilter({
    this.categories,
    this.dateRange,
    this.minAmount,
    this.maxAmount,
    this.merchantSearch,
    this.sortBy = TransactionSortType.date,
    this.sortDescending = true,
  });

  bool get hasActiveFilters =>
      (categories != null && categories!.isNotEmpty) ||
      dateRange != null ||
      minAmount != null ||
      maxAmount != null ||
      (merchantSearch != null && merchantSearch!.isNotEmpty);

  TransactionFilter copyWith({
    Set<CategoryType>? categories,
    DateTimeRange? dateRange,
    double? minAmount,
    double? maxAmount,
    String? merchantSearch,
    TransactionSortType? sortBy,
    bool? sortDescending,
    bool clearCategories = false,
    bool clearDateRange = false,
    bool clearMinAmount = false,
    bool clearMaxAmount = false,
    bool clearMerchantSearch = false,
  }) {
    return TransactionFilter(
      categories: clearCategories ? null : (categories ?? this.categories),
      dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
      minAmount: clearMinAmount ? null : (minAmount ?? this.minAmount),
      maxAmount: clearMaxAmount ? null : (maxAmount ?? this.maxAmount),
      merchantSearch: clearMerchantSearch ? null : (merchantSearch ?? this.merchantSearch),
      sortBy: sortBy ?? this.sortBy,
      sortDescending: sortDescending ?? this.sortDescending,
    );
  }

  List<TransactionItem> apply(List<TransactionItem> transactions) {
    var filtered = List<TransactionItem>.from(transactions);

    // Apply category filter
    if (categories != null && categories!.isNotEmpty) {
      filtered = filtered.where((t) => categories!.contains(t.category)).toList();
    }

    // Apply date range filter
    if (dateRange != null) {
      filtered = filtered.where((t) {
        final date = DateTime(t.time.year, t.time.month, t.time.day);
        final start = DateTime(dateRange!.start.year, dateRange!.start.month, dateRange!.start.day);
        final end = DateTime(dateRange!.end.year, dateRange!.end.month, dateRange!.end.day);
        return (date.isAtSameMomentAs(start) || date.isAfter(start)) &&
               (date.isAtSameMomentAs(end) || date.isBefore(end));
      }).toList();
    }

    // Apply amount range filter
    if (minAmount != null) {
      filtered = filtered.where((t) => t.amount >= minAmount!).toList();
    }
    if (maxAmount != null) {
      filtered = filtered.where((t) => t.amount <= maxAmount!).toList();
    }

    // Apply merchant search
    if (merchantSearch != null && merchantSearch!.isNotEmpty) {
      final searchLower = merchantSearch!.toLowerCase();
      filtered = filtered.where((t) =>
        t.merchant.toLowerCase().contains(searchLower)
      ).toList();
    }

    // Apply sorting
    filtered.sort((a, b) {
      int comparison;
      switch (sortBy) {
        case TransactionSortType.date:
          comparison = a.time.compareTo(b.time);
          break;
        case TransactionSortType.amount:
          comparison = a.amount.compareTo(b.amount);
          break;
        case TransactionSortType.merchant:
          comparison = a.merchant.compareTo(b.merchant);
          break;
      }
      return sortDescending ? -comparison : comparison;
    });

    return filtered;
  }

  TransactionFilter clear() {
    return const TransactionFilter();
  }
}
