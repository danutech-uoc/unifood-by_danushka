import 'package:firebase_database/firebase_database.dart';
import 'database_service.dart';

class CleanupService {
  final DatabaseService _databaseService;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  CleanupService(this._databaseService);

  // Initialize cleanup service
  Future<void> initialize() async {
    // Run cleanup every hour
    _scheduleCleanup();
    
    // Run initial cleanup
    await _runCleanup();
  }

  // Schedule periodic cleanup
  void _scheduleCleanup() {
    // Run cleanup every hour
    Future.delayed(const Duration(hours: 1), () {
      _runCleanup();
      _scheduleCleanup(); // Schedule next cleanup
    });
  }

  // Run cleanup process
  Future<void> _runCleanup() async {
    try {
      await _cleanupOldOrders();
      await _cleanupExpiredOrders();
      await _updateDailyAnalytics();
    } catch (e) {
      print('Error during cleanup: $e');
    }
  }

  // Clean up orders older than 7 days
  Future<void> _cleanupOldOrders() async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 7));
      final cutoffDateString = _formatDate(cutoffDate);

      final snapshot = await _database.child('preorders').once();
      if (snapshot.snapshot.exists) {
        final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
        final List<String> keysToDelete = [];

        data.forEach((key, value) {
          final order = value as Map<dynamic, dynamic>;
          final orderDate = order['orderDate'] as String?;
          
          if (orderDate != null && orderDate.compareTo(cutoffDateString) < 0) {
            keysToDelete.add(key);
          }
        });

        // Delete old orders
        for (final key in keysToDelete) {
          await _database.child('preorders').child(key).remove();
        }

        if (keysToDelete.isNotEmpty) {
          print('Cleaned up ${keysToDelete.length} old orders');
        }
      }
    } catch (e) {
      print('Error cleaning up old orders: $e');
    }
  }

  // Clean up expired orders (past deadline)
  Future<void> _cleanupExpiredOrders() async {
    try {
      final now = DateTime.now();
      final snapshot = await _database.child('preorders').once();
      
      if (snapshot.snapshot.exists) {
        final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
        final List<String> keysToDelete = [];

        data.forEach((key, value) {
          final order = value as Map<dynamic, dynamic>;
          final deadline = order['deadline'] as int?;
          
          if (deadline != null && deadline < now.millisecondsSinceEpoch) {
            keysToDelete.add(key);
          }
        });

        // Delete expired orders
        for (final key in keysToDelete) {
          await _database.child('preorders').child(key).remove();
        }

        if (keysToDelete.isNotEmpty) {
          print('Cleaned up ${keysToDelete.length} expired orders');
        }
      }
    } catch (e) {
      print('Error cleaning up expired orders: $e');
    }
  }

  // Update daily analytics
  Future<void> _updateDailyAnalytics() async {
    try {
      final today = _formatDate(DateTime.now());
      final mealCounts = await _databaseService.getMealCounts(today);
      
      // Update analytics with today's data
      await _database.child('canteen_analytics').update({
        'todayOrders': mealCounts.values.fold<int>(0, (sum, count) => sum + (count as int)),
        'breakfastRiceCurry': mealCounts['breakfastRiceCurry'] ?? 0,
        'breakfastStringHoppers': mealCounts['breakfastStringHoppers'] ?? 0,
        'lunchRiceCurry': mealCounts['lunchRiceCurry'] ?? 0,
        'lunchBiryani': mealCounts['lunchBiryani'] ?? 0,
        'lunchKottu': mealCounts['lunchKottu'] ?? 0,
      });

      print('Updated daily analytics');
    } catch (e) {
      print('Error updating daily analytics: $e');
    }
  }

  // Format date as string (YYYY-MM-DD)
  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Manual cleanup method for testing
  Future<void> runManualCleanup() async {
    await _runCleanup();
  }

  // Get cleanup statistics
  Future<Map<String, int>> getCleanupStats() async {
    try {
      final snapshot = await _database.child('preorders').once();
      int totalOrders = 0;
      int expiredOrders = 0;
      int oldOrders = 0;

      if (snapshot.snapshot.exists) {
        final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
        final now = DateTime.now();
        final cutoffDate = now.subtract(const Duration(days: 7));

        data.forEach((key, value) {
          final order = value as Map<dynamic, dynamic>;
          totalOrders++;

          final deadline = order['deadline'] as int?;
          if (deadline != null && deadline < now.millisecondsSinceEpoch) {
            expiredOrders++;
          }

          final orderDate = order['orderDate'] as String?;
          if (orderDate != null) {
            final orderDateTime = DateTime.parse(orderDate);
            if (orderDateTime.isBefore(cutoffDate)) {
              oldOrders++;
            }
          }
        });
      }

      return {
        'totalOrders': totalOrders,
        'expiredOrders': expiredOrders,
        'oldOrders': oldOrders,
      };
    } catch (e) {
      print('Error getting cleanup stats: $e');
      return {
        'totalOrders': 0,
        'expiredOrders': 0,
        'oldOrders': 0,
      };
    }
  }
}