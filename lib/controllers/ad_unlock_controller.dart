import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ad_unlock_state.dart';

class AdUnlockController extends StateNotifier<Map<String, AdUnlockState>> {
  static const String _storageKey = 'ad_unlock_states';

  AdUnlockController() : super({}) {
    _init();
  }

  Future<void> _init() async {
    await _loadState();
    _cleanupExpiredStates();
  }

  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);
      if (jsonStr != null) {
        final Map<String, dynamic> decoded = json.decode(jsonStr);
        final Map<String, AdUnlockState> loadedState = {};
        
        decoded.forEach((key, value) {
          try {
            loadedState[key] = AdUnlockState.fromJson(value);
          } catch (e) {
            // Skip corrupted entries
          }
        });
        
        state = loadedState;
      }
    } catch (e) {
      // If loading fails, start with empty state
      state = {};
    }
  }

  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> toSave = {};
      
      state.forEach((key, value) {
        toSave[key] = value.toJson();
      });
      
      await prefs.setString(_storageKey, json.encode(toSave));
    } catch (e) {
      // Log error but don't crash
      print('Failed to save ad unlock state: $e');
    }
  }

  void _cleanupExpiredStates() {
    final now = DateTime.now();
    final cleaned = Map<String, AdUnlockState>.from(state);
    
    cleaned.removeWhere((key, value) {
      return value.unlockExpiresAt != null && 
             value.unlockExpiresAt!.isBefore(now);
    });
    
    if (cleaned.length != state.length) {
      state = cleaned;
      _saveState();
    }
  }

  String generateSessionId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${state.length}';
  }

  AdUnlockState? getStateForPackage(String packageName) {
    return state[packageName];
  }

  Future<bool> watchAdToUnlock(
    String packageName,
    Future<bool> Function() showAdCallback,
  ) async {
    try {
      // Get or create state for this package
      final currentState = state[packageName];
      final sessionId = currentState?.lockSessionId ?? generateSessionId();
      
      // Show the ad
      final earned = await showAdCallback();
      
      if (!earned) {
        return false;
      }
      
      // Increment ads watched count
      final newAdsWatched = (currentState?.adsWatched ?? 0) + 1;
      
      // Calculate new unlock duration (10 minutes per ad)
      final unlockDuration = Duration(minutes: 10 * newAdsWatched);
      final newExpiresAt = DateTime.now().add(unlockDuration);
      
      // Update state
      final newState = AdUnlockState(
        adsWatched: newAdsWatched,
        unlockExpiresAt: newExpiresAt,
        lockSessionId: sessionId,
      );
      
      state = {...state, packageName: newState};
      await _saveState();
      
      return true;
    } catch (e) {
      print('Error watching ad to unlock: $e');
      return false;
    }
  }

  int getAdsWatchedForPackage(String packageName) {
    return state[packageName]?.adsWatched ?? 0;
  }

  Duration getTotalUnlockDuration(String packageName) {
    return state[packageName]?.totalUnlockDuration ?? Duration.zero;
  }

  DateTime? getUnlockExpiresAt(String packageName) {
    return state[packageName]?.unlockExpiresAt;
  }

  void resetAdCountForPackage(String packageName) {
    final updated = Map<String, AdUnlockState>.from(state);
    updated.remove(packageName);
    state = updated;
    _saveState();
  }

  void cleanupExpiredStates() {
    _cleanupExpiredStates();
  }
}

final adUnlockProvider =
    StateNotifierProvider<AdUnlockController, Map<String, AdUnlockState>>(
  (ref) => AdUnlockController(),
);
