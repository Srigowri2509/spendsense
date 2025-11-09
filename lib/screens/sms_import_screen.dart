// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models/parsed_transaction.dart';
import '../services/sms_service.dart';
import '../services/sms_parser.dart';
import '../services/transaction_import_service.dart';
import '../widgets/transaction_preview_tile.dart';
import '../widgets/empty_state.dart';

class SmsImportScreen extends StatefulWidget {
  final int daysBack;

  const SmsImportScreen({super.key, this.daysBack = 90});

  @override
  State<SmsImportScreen> createState() => _SmsImportScreenState();
}

class _SmsImportScreenState extends State<SmsImportScreen> {
  bool _isLoading = true;
  bool _isImporting = false;
  List<ParsedTransaction> _transactions = [];
  final Set<int> _selectedIndices = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _scanTransactions();
  }

  Future<void> _scanTransactions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final app = AppScope.of(context);
      final smsService = SmsService();
      final parser = SmsParser();
      final importService = TransactionImportService(smsService, parser, app);

      await importService.loadImportHistory();
      final transactions = await importService.scanTransactions(daysBack: widget.daysBack);

      setState(() {
        _transactions = transactions;
        // Select all by default
        _selectedIndices.addAll(List.generate(transactions.length, (i) => i));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _importSelected() async {
    if (_selectedIndices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one transaction')),
      );
      return;
    }

    setState(() => _isImporting = true);

    try {
      final app = AppScope.of(context);
      final smsService = SmsService();
      final parser = SmsParser();
      final importService = TransactionImportService(smsService, parser, app);

      await importService.loadImportHistory();

      final selectedTransactions = _selectedIndices
          .map((i) => _transactions[i])
          .toList();

      final result = await importService.importTransactions(selectedTransactions);

      if (!mounted) return;

      // Show result dialog
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Import Complete'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('✅ Imported: ${result.successful}'),
              if (result.skipped > 0) Text('⏭️ Skipped (duplicates): ${result.skipped}'),
              if (result.failed > 0) Text('❌ Failed: ${result.failed}'),
              if (result.errors.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Errors:', style: TextStyle(fontWeight: FontWeight.w600)),
                ...result.errors.take(3).map((e) => Text('• $e', style: TextStyle(fontSize: 12))),
              ],
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Import failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import from SMS'),
        actions: [
          if (_transactions.isNotEmpty && !_isLoading)
            TextButton(
              onPressed: () {
                setState(() {
                  if (_selectedIndices.length == _transactions.length) {
                    _selectedIndices.clear();
                  } else {
                    _selectedIndices.addAll(List.generate(_transactions.length, (i) => i));
                  }
                });
              },
              child: Text(_selectedIndices.length == _transactions.length ? 'Deselect All' : 'Select All'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Error',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: _scanTransactions,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _transactions.isEmpty
                  ? EmptyState(
                      icon: Icons.inbox_outlined,
                      title: 'No transactions found',
                      message: 'No transaction SMS found in the last ${widget.daysBack} days',
                      actionLabel: 'Go Back',
                      onAction: () => Navigator.pop(context),
                    )
                  : Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Found ${_transactions.length} transactions. Select the ones you want to import.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _transactions.length,
                            itemBuilder: (context, index) {
                              return TransactionPreviewTile(
                                transaction: _transactions[index],
                                isSelected: _selectedIndices.contains(index),
                                onChanged: (selected) {
                                  setState(() {
                                    if (selected == true) {
                                      _selectedIndices.add(index);
                                    } else {
                                      _selectedIndices.remove(index);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, -2),
                              ),
                            ],
                          ),
                          child: SafeArea(
                            child: FilledButton(
                              onPressed: _isImporting ? null : _importSelected,
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(50),
                              ),
                              child: _isImporting
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : Text('Import ${_selectedIndices.length} Selected'),
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }
}
