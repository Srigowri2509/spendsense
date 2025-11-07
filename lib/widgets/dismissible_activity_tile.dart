import 'dart:async';
import 'package:flutter/material.dart';
import '../app_state.dart';
import 'activity_tile.dart';

class DismissibleActivityTile extends StatelessWidget {
  final TransactionItem item;
  final VoidCallback? onTap;

  const DismissibleActivityTile({
    super.key,
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white, size: 32),
      ),
      confirmDismiss: (direction) async {
        // Don't actually dismiss - we'll handle it with undo
        _scheduleDelete(context, item, app);
        return false;
      },
      child: InkWell(
        onTap: onTap,
        child: ActivityTile(item: item),
      ),
    );
  }

  void _scheduleDelete(BuildContext context, TransactionItem item, AppState app) {
    // Store the item for potential restoration
    final deletedItem = item;
    final deletedIndex = app.transactions.indexOf(item);
    
    // Remove from UI immediately
    app.transactions.remove(item);
    app.notifyListeners();

    // Show snackbar with undo
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text('Deleted ${item.merchant}'),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            // Restore the item
            if (deletedIndex >= 0 && deletedIndex <= app.transactions.length) {
              app.transactions.insert(deletedIndex, deletedItem);
            } else {
              app.transactions.add(deletedItem);
            }
            app.notifyListeners();
          },
        ),
      ),
    ).closed.then((reason) {
      // If snackbar closed without undo, commit deletion to backend
      if (reason != SnackBarClosedReason.action) {
        _commitDeletion(app, deletedItem);
      }
    });
  }

  Future<void> _commitDeletion(AppState app, TransactionItem item) async {
    try {
      await app.removeTransaction(item.id);
    } catch (e) {
      // If backend fails, restore the item
      app.transactions.add(item);
      app.notifyListeners();
      debugPrint('Failed to delete transaction: $e');
    }
  }
}
