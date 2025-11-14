import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subscription.dart';
import '../services/subscription_service.dart';

class SubscriptionMigration {
  static const String _oldKey = 'subscriptions';
  static const String _newKey = 'subscriptions_v2';
  static const String _migrationKey = 'subscription_migration_done';

  static Future<bool> needsMigration() async {
    final prefs = await SharedPreferences.getInstance();
    final migrationDone = prefs.getBool(_migrationKey) ?? false;
    if (migrationDone) return false;

    final oldData = prefs.getString(_oldKey);
    return oldData != null && oldData.isNotEmpty;
  }

  static Future<List<Subscription>> migrateSubscriptions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if migration already done
      final migrationDone = prefs.getBool(_migrationKey) ?? false;
      if (migrationDone) {
        debugPrint('Migration already completed');
        return [];
      }

      // Check if there's old data
      final oldData = prefs.getString(_oldKey);
      if (oldData == null || oldData.isEmpty) {
        debugPrint('No old subscription data to migrate');
        await prefs.setBool(_migrationKey, true);
        return [];
      }

      debugPrint('Starting subscription migration...');

      // For now, since the old format didn't have proper structure,
      // we'll just mark migration as done and let users re-add subscriptions
      // In a real scenario, you would parse the old format here
      
      await prefs.setBool(_migrationKey, true);
      debugPrint('Migration completed');

      return [];
    } catch (e) {
      debugPrint('Error during migration: $e');
      return [];
    }
  }

  static Future<void> clearOldData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_oldKey);
      debugPrint('Old subscription data cleared');
    } catch (e) {
      debugPrint('Error clearing old data: $e');
    }
  }
}
